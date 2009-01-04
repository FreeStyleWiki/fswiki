############################################################
#
# <p>そのページに添付されているファイルを一覧表示します。</p>
# <p>FooterやMenuに記述しておくと便利です。</p>
# <pre>
# {{files}}
# </pre>
# <p>Menuに記述する場合など、vオプションをつけると縦に表示することができます。</p>
# <pre>
# {{files v}}
# </pre>
#
############################################################
package plugin::attach::Files;
use strict;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# 添付ファイルの一覧を表示するインライン関数
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $way  = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if(!defined($way)){
		$way = "";
	}
	# 参照権があるかどうか調べる
	unless($wiki->can_show($pagename)){
		return undef;
	}
	
	my ($entry,$buf);
	
	my $editFlag = &can_attach_delete($wiki, $pagename);
#	my $login = $wiki->get_login_info();
#	if(!$wiki->can_modify_page($pagename)){
#		$editFlag = 0;
#	} elsif($wiki->config('accept_attach_delete')==0 && !defined($login)){
#		$editFlag = 0;
#	} elsif($wiki->config('accept_attach_delete')==2 && (!defined($login) || $login->{type}!=0)){
#		$editFlag = 0;
#	}
	
	if($way eq "V" || $way eq "v"){
		$buf = "<ul>\n";
	}
	
	foreach my $file (&get_file_list($wiki,$pagename)){
		if($way eq "V" || $way eq "v"){
			$buf = $buf."<li><a href=\"".$wiki->create_url({action=>"ATTACH",page=>$pagename,file=>$file})."\">".
			       Util::escapeHTML($file)."</a>";
		} else {
			$buf = $buf."<a href=\"".$wiki->create_url({action=>"ATTACH",page=>$pagename,file=>$file})."\">".
			       Util::escapeHTML($file)."</a>";
		}
		
		if($editFlag){
			$buf .= "[<a href=\"".$wiki->create_url({action=>"ATTACH",CONFIRM=>"yes",page=>$pagename,file=>$file})."\">削除</a>]";
		}
		
		if($way eq "V" || $way eq "v"){
			$buf .= "</li>\n";
		} else {
			$buf .= "\n";
		}
	}
	
	if($way eq "V" || $way eq "v"){
		$buf .= "</ul>\n";
	}
	
	return $buf;
}

#===========================================================
# ファイルの一覧を取得する関数
#===========================================================
sub get_file_list {
	my $wiki = shift;
	my $page = shift;
	my $encode_page = &Util::url_encode($page);
	my @list;
	if(-e $wiki->config('attach_dir')){
		opendir(DIR,$wiki->config('attach_dir')) or die $!;
		while(my $entry = readdir(DIR)){
			if(index($entry,$encode_page.".")==0){
				my $file = (split(/\./,$entry))[1];
				push(@list,&Util::url_decode($file));
			}
		}
		closedir(DIR);
	}
	@list = sort { $a cmp $b } @list;
	return @list;
}

#===========================================================
# 添付ファイルが削除可能かどうか判定する関数
#===========================================================
sub can_attach_delete {
	my $wiki  = shift;
	my $page  = shift;
	my $login = $wiki->get_login_info();
	
	my $config = $wiki->config('accept_attach_delete');
	$config = 0 if($config eq "");
	
	if(!$wiki->can_modify_page($page)){
		return 0;
	} elsif($config==0 && !defined($login)){
		return 0;
	} elsif($config==2 && (!defined($login) || $login->{type}!=0)){
		return 0;
	}
	
	return 1;
}

#===========================================================
# 添付ファイルが更新可能かどうか判定する関数
#===========================================================
sub can_attach_update {
	my $wiki  = shift;
	my $page  = shift;
	my $login = $wiki->get_login_info();
	
	my $config = $wiki->config('accept_attach_update');
	$config = 1 if($config eq "");
	
	if(!$wiki->can_modify_page($page)){
		return 0;
	} elsif($config==1 && !defined($login)){
		return 0;
	} elsif($config==2 && (!defined($login) || $login->{type}!=0)){
		return 0;
	}
	
	return 1;
}

1;
