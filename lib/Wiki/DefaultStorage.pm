###############################################################################
# <p>
# FSWikiデフォルトのストレージプラグイン。
# </p>
# <p>
# setup.datのbackup=1もしくはbackupディレクティブを省略した場合は１世代のみ、
# backup=2以上もしくは0を指定した場合は世代バックアップに対応します。
# backup=0を指定した場合は無制限にバックアップを行います。
# </p>
###############################################################################
package Wiki::DefaultStorage;
use File::Copy;
use strict;
use vars qw($MODTIME_FILE $PAGE_LIST_FILE);

# ページの最終更新日時を記録するファイル
$MODTIME_FILE = "modtime.dat";

# ページ一覧のインデックスを格納するファイル
$PAGE_LIST_FILE = "pagelist.cache";

#==============================================================================
# <p>
# コンストラクタ
# </p>
#==============================================================================
sub new {
	my $class  = shift;
	my $wiki   = shift;
	my $backup = $wiki->{config}->{'backup'};
	
	if(!defined($backup) || $backup eq ""){
		$backup = 1;
	}
	
	my $self = {};
	$self->{wiki}          = $wiki;
	$self->{backup}        = $backup;
	$self->{exists_cache}  = {};
	$self->{modtime_cache} = undef;
	return bless $self,$class;
}

#==============================================================================
# <p>
# ページを取得
# </p>
#==============================================================================
sub get_page {
	my $self = shift;
	my $page = shift;
	my $path = shift;
	
	my $dir = $self->{wiki}->config('data_dir');
	if($path ne ""){
		$dir = "$dir/$path";
	}
	
	my $content = "";
	my $filename = &Util::make_filename($dir,&Util::url_encode($page),"wiki");
	if(-e $filename){
		open(DATA,$filename) or die $!;
		binmode(DATA);
		while(<DATA>){
			$content = $content.$_;
		}
		close(DATA);
	}
	
	return $content;
}

#==============================================================================
# <p>
# ページを保存
# </p>
#==============================================================================
sub save_page {
	my $self    = shift;
	my $page    = shift;
	my $content = shift;
	my $sage    = shift;
	my $wiki    = $self->{wiki};
	
	$content = '' if($content =~ /^[\r\n]+$/s); # added for opera
	
	# ページ名とページ内容の補正
	$page = Util::trim($page);
	$content =~ s/\r\n/\n/g;
	$content =~ s/\r/\n/g;
	
	my $wikifile = &Util::make_filename($wiki->config('data_dir'),&Util::url_encode($page),"wiki");
	my $tmpfile  = "$wikifile.tmp";
	
	Util::file_lock($wikifile,1);
	
	# バックアップ
	my $BACKUP = $self->get_page($page);
	if($BACKUP ne '' && $BACKUP eq $content){
		Util::file_unlock($wikifile);
		return 0;
	}
	my $flag = '';
	if($BACKUP ne ""){
		$flag = 'update';
		my $backupfile = "";
		if($self->{backup}==1){
			$backupfile = &Util::make_filename($wiki->config('backup_dir'),&Util::url_encode($page),"bak");
		} else {
			$self->_rename_old_history($page);
			my $number = $self->_get_backup_number($page);
			$backupfile = &Util::make_filename($wiki->config('backup_dir'),&Util::url_encode($page),"$number.bak");
		}
		open(DATA,">$backupfile") or die $!;
		binmode(DATA);
		print DATA $BACKUP;
		close(DATA);
	} else {
		# backupがない場合は、page_levelをデフォルト値に設定する。
		$flag = 'create';
		my $login = $wiki->get_login_info();
		my $level = 0;
		if (defined($login)) {
			if ($login->{type} == 1) {
				$level = 1;
			} elsif ($login->{type} == 0) {
				$level = 2;
			}
		}
		if ($level > $wiki->config('refer_level')) {
			$level = $wiki->config('refer_level');
		}
		$wiki->set_page_level($page, $level);
	}

	# 更新日時記録ファイルがない場合は作成
	unless(-e $wiki->config('config_dir')."/".$MODTIME_FILE){
		my @list = $self->get_page_list();
		my $hash = {};
		foreach my $p (@list){
			$hash->{$p}=$self->get_last_modified($p);
		}
		&Util::save_config_hash($wiki,$MODTIME_FILE,$hash);
	}
	# 書き込む
	if($content eq ""){
		$self->_create_page_list_file($page, 'remove');
		unlink($wikifile);
		$wiki->set_page_level($page);
		# 更新日時を削除
		my $modtime = &Util::load_config_hash($wiki,$MODTIME_FILE);
		delete $modtime->{$page};
		&Util::save_config_hash($wiki,$MODTIME_FILE,$modtime);
		# 削除時はバックアップファイルを残す
		#unlink(&Util::make_filename($wiki->config('backup_dir'),&Util::url_encode($page),"bak"));
	} else {
		$self->_create_page_list_file($page, $flag);
		# 上書きする
		open(DATA,">$tmpfile") or die $!;
		binmode(DATA);
		print DATA $content;
		close(DATA);		
		# sageでない場合は更新日時を更新
		if($sage != 1){
			my $modtime = &Util::load_config_hash($wiki,$MODTIME_FILE);
			$modtime->{$page} = time();
			&Util::save_config_hash($wiki,$MODTIME_FILE,$modtime);
		}
	}
	
	rename($tmpfile, $wikifile);
	Util::file_unlock($wikifile);
	
	return 1;
}

#------------------------------------------------------------------------------
# <p>
# ページ一覧のインデックスファイルを作成、更新します。
# 第一引数にページ名、第二引数に'create'、'update'、'remove'のいずれかを指定します。
# インデックスファイルが存在しない場合は引数に関わらずインデックスファイルの作成を行います。
# </p>
#------------------------------------------------------------------------------
sub _create_page_list_file {
	my $self = shift;
	my $page = shift;
	my $flag = shift;
	my $wiki = $self->{'wiki'};
	my $file = $wiki->config('log_dir')."/".$PAGE_LIST_FILE;
	my $buf = "";
	
	unless(-e $file){
		opendir(DIR, $wiki->config('data_dir')) or die $!;
		my ($entry,@list);
		while($entry = readdir(DIR)){
			my $name = &Util::url_decode(substr($entry,0,rindex($entry,".")));
			my $type = substr($entry,rindex($entry,"."));
			my $flag = 0;
			if($type eq ".wiki"){
				$buf .= "$name\n";
			}
		}
		closedir(DIR);
		Util::save_config_text(undef, $file, $buf);
	} else {
		if($flag eq "remove"){
			my $names = Util::load_config_text(undef, $file);
			$names =~ s/(^|\n)\Q$page\E\n/\n/;
			Util::save_config_text(undef, $file, $names);
		} elsif($flag eq 'update'){
			# ページの更新時は何もしない
		} elsif($flag eq 'create') {
			open(DATA, ">>$file");
			print DATA "$page\n";
			close(DATA);
		}
	}
}

#------------------------------------------------------------------------------
# <p>
# バックアップファイルに付与する世代番号を取得するプライベートメソッド
# </p>
#------------------------------------------------------------------------------
sub _get_backup_number {
	my $self = shift;
	my $page = shift;
	my $wiki = $self->{wiki};
	my $num  = 0;
	my @backups = glob($wiki->config('backup_dir')."/".&Util::url_encode($page).".*.bak");
	foreach my $backup (@backups){
		if($backup =~ /^.+\.([0-9]+)\.bak$/){
			if($num < $1){
				$num = $1;
			}
		}
	}
	return $num + 1;
}

#------------------------------------------------------------------------------
# <p>
# 保存世代数を超えた分を削除するプライベートメソッド
# </p>
#------------------------------------------------------------------------------
sub _rename_old_history {
	my $self  = shift;
	my $page  = shift;
	my $wiki  = $self->{wiki};
	
	# 無制限の場合は何もしない
	if($self->{backup}==0){
		return;
	}
	
	my @files = glob($wiki->config('backup_dir')."/".&Util::url_encode($page).".*.bak");
	
	@files = sort {
		$a =~ /^.+\.([0-9]+)\.bak$/;
		my $num_a = $1;
		$b =~ /^.+\.([0-9]+)\.bak$/;
		my $num_b = $1;
		return $num_a <=> $num_b;
	} @files;
	
	my $count = 1;
	for(my $i=0;$i<=$#files;$i++){
		if($i > $#files - $self->{backup} + 1){
			my $newfile = &Util::make_filename($wiki->config('backup_dir'),&Util::url_encode($page),"$count.bak");
			move($files[$i],$newfile) or die $!;
			$count++;
		} else {
			unlink($files[$i]);
		}
	}
}

#==============================================================================
# <p>
# ページの一覧を取得。
# </p>
#==============================================================================
sub get_page_list {
	my $self   = shift;
	my $args   = shift;
	my $wiki   = $self->{wiki};
	my $sort   = "name";
	my $permit = "all";
	my $max    = 0;
	
	# 引数を解釈
	if(defined($args)){
		if(defined($args->{-sort})){
			$sort = $args->{-sort};
		}
		if(defined($args->{-permit})){
			$permit = $args->{-permit};
		}
		if(defined($args->{-max})){
			$max = $args->{-max};
		}
	}
	
	# ページの一覧を取得
	my $file  = $wiki->config('log_dir')."/".$PAGE_LIST_FILE;
	$self->_create_page_list_file(undef, 'update') unless(-e $file);
	my $names = Util::load_config_text(undef, $file);
	my @list  = ();
	foreach my $name (split(/\n/,$names)){
		my $flag = 0;
		# 参照権のあるページのみ
		if($permit eq "show"){
			if($wiki->can_show($name)){
				$flag = 1;
			}
			
		} elsif($permit eq "modify"){
			if($wiki->can_modify_page($name)){
				$flag = 1;
			}
			
		# 全てのページ
		} elsif($permit eq "all"){
			$flag = 1;
		
		# それ以外の場合はエラー
		} else {
			die "permitオプションの指定が不正です。";
		}
		if($flag == 1){
			push(@list,$name);
		}
	}
	
	# 名前でソート
	if($sort eq "name"){
		@list = sort { $a cmp $b } @list;
		
	# 更新日時（新着順）にソート
	} elsif($sort eq "last_modified"){
		@list =  map  { $_->[0] }
		         sort { $b->[1] <=> $a->[1] }
		         map  { [$_, $wiki->get_last_modified2($_)] } @list;
	
	# それ以外の場合はエラー
	} else {
		die "sortオプションの指定が不正です。";
	}
	
	return $max == 0 ? @list : splice(@list, 0, $max);
}

#==============================================================================
# <p>
# ページの最終更新時刻を取得（物理的）
# </p>
#==============================================================================
sub get_last_modified {
	my $self   = shift;
	my $page   = shift;
	my @status = stat(&Util::make_filename($self->{wiki}->config('data_dir'),&Util::url_encode($page),"wiki"));
	
	return $status[9];
}

#==============================================================================
# <p>
# ページの最終更新時刻を取得（論理的）
# </p>
#==============================================================================
sub get_last_modified2 {
	my $self    = shift;
	my $page    = shift;
	my $modtime = $self->{modtime_cache};
	
	unless(defined($modtime)){
		$modtime = &Util::load_config_hash($self->{wiki},$MODTIME_FILE);
		$self->{modtime_cache} = $modtime;
	}
	
	if(defined($modtime->{$page})){
		return $modtime->{$page};
	} else {
		return $self->get_last_modified($page);
	}
}

#===============================================================================
# <p>
# ページが存在するかどうか調べる
# </p>
#===============================================================================
sub page_exists {
	my $self = shift;
	my $page = shift;
	my $path = shift;
	
	if($self->{exists_cache} and defined($self->{exists_cache}->{"$path:$page"})){
		return $self->{exists_cache}->{"$path:$page"};
	}
	
	my $dir = $self->{wiki}->config('data_dir');
	if(defined $path and $path ne ""){
		$dir = "$dir/$path";
	}
	
	my $exists = (-e &Util::make_filename($dir,&Util::url_encode($page),"wiki"));
	$self->{exists_cache}->{"$path:$page"} = $exists;
	
	return $exists;
}

#==============================================================================
# <p>
# バックアップタイプを取得(single|all)。
# setup.datの設定内容によって、１世代のみの場合はsingle、
# 世代バックアップを行っている場合はallを返却します。
# </p>
#==============================================================================
sub backup_type {
	my $self = shift;
	
	if($self->{backup}==1){
		return "single";
	} else {
		return "all";
	}
}

#==============================================================================
# <p>
# 世代バックアップを行っている場合にバックアップ時刻の一覧を取得します。
# １世代のみバックアップの設定で動作している場合はundefを返します。
# </p>
#==============================================================================
sub get_backup_list {
	my $self = shift;
	my $page = shift;
	
	if($self->{backup}==1){
		return undef;
	} else {
		my $wiki = $self->{wiki};
		my @files = glob($wiki->config('backup_dir')."/".Util::url_encode($page).".*.bak");
		
		@files = sort {
			$a =~ /^.+\.([0-9]+)\.bak$/;
			my $num_a = $1;
			$b =~ /^.+\.([0-9]+)\.bak$/;
			my $num_b = $1;
			return $num_b <=> $num_a;
		} @files;
		
		my @datelist;
		
		foreach my $file (@files){
			my @status = stat($file);
			push(@datelist,Util::format_date($status[9]));
		}
		
		return @datelist;
	}
}

#==============================================================================
# <p>
# バックアップを取得します。
# backup_type=allの場合は第二引数で世代(0〜)を指定します。
# </p>
#==============================================================================
sub get_backup {
	my $self     = shift;
	my $page     = shift;
	my $gen      = shift;
	my $content  = "";
	my $filename = "";
	
	if($self->{backup}!=1){
		# 世代バックアップかつ世代指定がない場合は最新のバックアップを取得
		if(!defined($gen) || $gen eq ""){
			my @list = $self->get_backup_list($page);
			$gen = $#list;
		}
		$filename = &Util::make_filename($self->{wiki}->config('backup_dir'),&Util::url_encode($page),($gen+1).".bak");
		Util::debug("バックアップファイル名:$filename");
	} else {
		$filename = &Util::make_filename($self->{wiki}->config('backup_dir'),&Util::url_encode($page),"bak");
	}
	if(-e $filename){
		open(DATA,$filename) or die $!;
		binmode(DATA);
		while(<DATA>){
			$content = $content.$_;
		}
		close(DATA);
	}
	
	return $content;
}

#==============================================================================
# <p>
# ページを凍結します
# </p>
#==============================================================================
sub freeze_page {
	my $self     = shift;
	my $pagename = shift;
	
	if(!$self->is_freeze($pagename)){
		my $freeze_file = $self->{wiki}->config('log_dir')."/".$self->{wiki}->config('freeze_file');
		Util::file_lock($freeze_file);
		open(DATA,">>$freeze_file") or die $!;
		binmode(DATA);
		print DATA $pagename."\n";
		close(DATA);
		Util::file_unlock($freeze_file);
		
		# リダイレクトすれば不要だけど…
		push(@{$self->{freeze_list}},$pagename);
	}
}

#==============================================================================
# <p>
# ページの凍結を解除します
# </p>
#==============================================================================
sub un_freeze_page {
	my $self = shift;
	my $pagename = shift;
	
	if($self->is_freeze($pagename)){
		my $buf = "";
		open(DATA,$self->{wiki}->config('log_dir')."/".$self->{wiki}->config('freeze_file')) or die $!;
		while(<DATA>){
			chomp $_;
			if($pagename ne $_){
				$buf .= $_."\n";
			}
		}
		close(DATA);
		
		open(DATA,">".$self->{wiki}->config('log_dir')."/".$self->{wiki}->config('freeze_file')) or die $!;
		binmode(DATA);
		print DATA $buf;
		close(DATA);
		
		# リダイレクトすれば不要だけど…
		@{$self->{freeze_list}} = grep(!/^\Q$pagename\E$/,@{$self->{freeze_list}});
	}
}

#==============================================================================
# <p>
# 凍結リストを取得
# </p>
#==============================================================================
sub get_freeze_list {
	my $self = shift;
	my $path = shift;
	
	if(!defined($path)){
		$path = "";
	}
	
	if(defined($self->{"$path:freeze_list"})){
		return @{$self->{"$path:freeze_list"}};
	}
	
	my $logdir = $self->{wiki}->config('log_dir');
	if($path ne ""){
		$logdir .= "/$path";
	}
	
	my @list;
	if(!-e "$logdir/".$self->{wiki}->config('freeze_file')){
		return @list;
	}
	
	open(DATA,"$logdir/".$self->{wiki}->config('freeze_file')) or die $!;
	while(<DATA>){
		chomp $_;
		push @list,$_;
	}
	close(DATA);
	
	$self->{"$path:freeze_list"} = \@list;
	return @list;
}

#==============================================================================
# <p>
# 引数で渡したページが凍結中かどうかしらべます
# </p>
#==============================================================================
sub is_freeze {
	my $self     = shift;
	my $pagename = shift;
	my $path     = shift;
	
	foreach my $freeze_page ($self->get_freeze_list($path)){
		if($freeze_page eq $pagename){
			return 1;
		}
	}
	
	return 0;
}

#==============================================================================
# <p>
# ページの参照レベルを設定します。
# </p>
#==============================================================================
sub set_page_level {
	my $self  = shift;
	my $page  = shift;
	my $level = shift;
	
	my $all = &Util::load_config_hash($self->{wiki},"showlevel.log");
	if(defined($level)){
		$all->{$page} = $level;
	} else {
		delete($all->{$page});
	}
	&Util::save_config_hash($self->{wiki},"showlevel.log",$all);
	$self->{":show_level"} = $all;
}

#==============================================================================
# <p>
# ページの参照レベルを取得します。
# </p>
#==============================================================================
sub get_page_level {
	my $self = shift;
	my $page = shift;
	my $path = shift;
	
	if(!defined($path)){
		$path = "";
	}
	
	unless(defined($self->{"$path:show_level"})){
		# config_dirを差し替えて実行
		my $configdir = $self->{wiki}->config('config_dir');
		if($path ne ""){
			$self->{wiki}->config('config_dir',"$configdir/$path");
		}
		
		$self->{"$path:show_level"} = &Util::load_config_hash($self->{wiki},"showlevel.log");
		
		# config_dirを元に戻す
		$self->{wiki}->config('config_dir',$configdir);
	}
	
	if(defined($page)){
		if(defined($self->{"$path:show_level"}->{$page})){
			return $self->{"$path:show_level"}->{$page};
		} else {
			#return $self->{wiki}->config('refer_level');
			return 0;
		}
	} else {
		return $self->{"$path:show_level"};
	}
}

#==============================================================================
# <p>
# 終了時に呼び出されます。インスタンス変数の参照を解放します。
# </p>
#==============================================================================
sub finalize {
	my $self = shift;
	undef($self->{wiki});
}

1;
