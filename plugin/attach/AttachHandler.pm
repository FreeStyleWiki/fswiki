############################################################
#
# 添付ファイルのアクションハンドラ。
#
############################################################
package plugin::attach::AttachHandler;
use strict;
use plugin::attach::Files;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# アクションの実行
#===========================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if($pagename eq ""){
		$pagename = $wiki->config("frontpage");
	}
	
	$wiki->set_title("ファイルの添付",1);
	
	if($cgi->param("UPLOAD") ne "" || $cgi->param("CONFIRM") ne "" || $cgi->param("DELETE") ne ""){
		unless($wiki->can_modify_page($pagename)){
			return $wiki->error("編集は禁止されています。");
		}
	}
	
	if($cgi->param("DELETE") ne ""){
		unless(&plugin::attach::Files::can_attach_delete($wiki, $pagename)){
			return $wiki->error("ファイルの削除は許可されていません。");
		}
	}
	
	#-------------------------------------------------------
	# アップロード実行
	if($cgi->param("UPLOAD") ne ""){
		my $filename = $cgi->param("file");
		$filename =~ s/\\/\//g;
		$filename = substr($filename,rindex($filename,"/")+1);
		$filename =~ tr/";\x00-\x1f/': /;
		&Jcode::convert(\$filename,'euc');
		
		if($filename eq ""){
			return $wiki->error("ファイルが指定されていません。");
		}
		
		my $hundle = $cgi->upload("file");
		unless($hundle){
			return $wiki->error("ファイルが読み込めませんでした。");
		}
		
		my $uploadfile = $wiki->config('attach_dir')."/".&Util::url_encode($pagename).".".&Util::url_encode($filename);
		if(-e $uploadfile && !&plugin::attach::Files::can_attach_update($wiki, $pagename)){
			return $wiki->error("ファイルの上書きは許可されていません。");
		}
		
		open(DATA,">$uploadfile") or die $!;
		binmode(DATA);
		while(read($hundle,$_,16384)){ print DATA $_; }
		close(DATA);
				
		# attachプラグインから添付された場合
		if(defined($cgi->param("count"))){
			my @lines = split(/\n/,$wiki->get_page($pagename));
			my $flag = 0;
			my $form_count = 1;
			my $count=$cgi->param("count");
			my $content = "";
			foreach(@lines){
				if(index($_," ")==0||index($_,"\t")==0){
					$content .= $_."\n";
					next;
				}
				if(index($_,"{{attach}}")!=-1 && $flag==0){
					if($form_count==$count){
						$content = $content."{{ref ".$filename."}}\n";
						$flag = 1;
					} else {
						$form_count++;
					}
				}
				$content = $content.$_."\n";
			}
			if($flag==1){
				$wiki->save_page($pagename,$content);
			}
		}
		
		# ログの記録
		&write_log($wiki,"UPLOAD",$pagename,$filename);
		
		$wiki->redirect($pagename);
		
	#-------------------------------------------------------
	# 削除確認
	} elsif($cgi->param("CONFIRM") ne ""){
		my $file = $cgi->param("file");
		if($file eq ""){
			return $wiki->error("ファイルが指定されていません。");
		}
		
		my $buf = "";
		
		$buf .= "<a href=\"".$wiki->create_page_url($pagename)."\">".
		        Util::escapeHTML($pagename)."</a>から".Util::escapeHTML($file)."を削除してよろしいですか？\n".
		        "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
		        "  <input type=\"submit\" name=\"DELETE\" value=\"削 除\">".
		        "  <input type=\"hidden\" name=\"action\" value=\"ATTACH\">".
		        "  <input type=\"hidden\" name=\"page\" value=\"".Util::escapeHTML($pagename)."\">".
		        "  <input type=\"hidden\" name=\"file\" value=\"".Util::escapeHTML($file)."\">".
		        "</form>";
		return $buf;
	
	#-------------------------------------------------------
	# 削除実行
	} elsif($cgi->param("DELETE") ne ""){
		my $file = $cgi->param("file");
		if($file eq ""){
			return $wiki->error("ファイルが指定されていません。");
		}
		
		# ログの記録
		&write_log($wiki,"DELETE",$pagename,$file);

		unlink($wiki->config('attach_dir')."/".&Util::url_encode($pagename).".".&Util::url_encode($file));
		$wiki->redirect($pagename);
		
	#-------------------------------------------------------
	# ダウンロード
	} else {
		my $file = $cgi->param("file");
		if($file eq ""){
			return $wiki->error("ファイルが指定されていません。");
		}
		unless($wiki->page_exists($pagename)){
			return $wiki->error("ページが存在しません。");
		}
		unless($wiki->can_show($pagename)){
			return $wiki->error("ページの参照権限がありません。");
		}
		my $filepath = $wiki->config('attach_dir')."/".&Util::url_encode($pagename).".".&Util::url_encode($file);
		unless(-e $filepath){
			return $wiki->error("ファイルがみつかりません。");
		}
		
		my $contenttype = &get_mime_type($wiki,$file);
		my $ua = $ENV{"HTTP_USER_AGENT"};
		my $disposition = ($contenttype =~ /^image\// && $ua !~ /MSIE/ ? "inline" : "attachment");

		open(DATA, $filepath) or die $!;
		print "Content-Type: $contenttype\n";
		print Util::make_content_disposition($file, $disposition);
		binmode(DATA);
		while(read(DATA,$_,16384)){ print $_; }
		close(DATA);
				
		# ログの記録
		&write_log($wiki,"DOWNLOAD",$pagename,$file);
		&count_up($wiki,$pagename,$file);
		
		exit();
	}
}

#===========================================================
# ダウンロードカウントをインクリメント
#===========================================================
sub count_up {
	my $wiki = shift;
	my $page = shift;
	my $file = shift;
	
	Util::sync_update_config(undef,$wiki->config('log_dir')."/".$wiki->config('download_count_file'),
	sub {
		my $hash = shift;
		unless(defined($hash->{$page."::".$file})){
			$hash->{$page."::".$file} = 1;
		} else {
			$hash->{$page."::".$file}++;
		}
		return $hash;
	}
	);
}

#===========================================================
# 添付ファイルのログ
#===========================================================
sub write_log(){
	my $wiki = shift;
	my $mode = shift;
	my $page = shift;
	my $file = shift;
	if($wiki->config('log_dir') eq "" || $wiki->config('attach_log_file') eq ""){
		return;
	}
	my $ip  = $ENV{"REMOTE_ADDR"};
	my $ref = $ENV{"HTTP_REFERER"};
	my $ua  = $ENV{"HTTP_USER_AGENT"};
	if($ip  eq ""){ $ip  = "-"; }
	if($ref eq ""){ $ref = "-"; }
	if($ua  eq ""){ $ua  = "-"; }
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time());
	my $date = sprintf("%04d/%02d/%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	
	my $logfile = $wiki->config('log_dir')."/".$wiki->config('attach_log_file');
	Util::file_lock($logfile);
	open(LOG,">>$logfile") or die $!;
	binmode(LOG);
	print LOG $mode." ".&Util::url_encode($page)." ".&Util::url_encode($file)." ".
	          $date." ".$ip." ".$ref." ".$ua."\n";
	close(LOG);
	Util::file_unlock($logfile);
}

#===========================================================
# MIMEタイプを取得します
#===========================================================
sub get_mime_type {
	my $wiki = shift;
	my $file = shift;
	my $type = lc(substr($file,rindex($file,".")+1));
	
	my $hash  = &Util::load_config_hash($wiki,$wiki->config('mime_file'));
	my $ctype = $hash->{$type};
	
	if($ctype eq "" ){
		$ctype = "application/octet-stream";
	}
	
	return $ctype;
}

1;
