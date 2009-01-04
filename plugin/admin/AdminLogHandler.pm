###############################################################################
#
# ログファイルを管理するモジュール
#
###############################################################################
package plugin::admin::AdminLogHandler;
use strict;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# アクションハンドラメソッド
#==============================================================================
sub do_action {
	my $self  = shift;
	my $wiki  = shift;
	my $cgi   = $wiki->get_CGI;
	my $login = $wiki->get_login_info();
	
	if($cgi->param("delete")){
		return $self->delete_log($wiki);
		
	} elsif($cgi->param("download")){
		$self->download_log($wiki);
		
	} elsif($cgi->param("deletecache")){
		return $self->delete_cache($wiki);
		
	} else {
		return $self->log_info($wiki);
	}
}

#==============================================================================
# ログファイルの情報を表示
#==============================================================================
sub log_info {
	my $self = shift;
	my $wiki = shift;
	my $buf  = "";
	
	$wiki->set_title("ログファイルの管理");
	
	$buf .= $self->make_log_form($wiki,"アクセスログ","access");
	$buf .= $self->make_log_form($wiki,"添付ファイルのログ","attach");
	$buf .= $self->make_log_form($wiki,"添付ファイルダウンロード数のログ","download");
	$buf .= "<p>※このログファイルを削除すると添付ファイルのダウンロード数がクリアされます。</p>\n";
	$buf .= $self->make_log_form($wiki,"ページ凍結のログ","freeze");
	$buf .= "<p>※このログファイルを削除すると全てのページ凍結が解除されます。</p>\n";
	
	# キャッシュファイルの情報
	$buf .= "<h2>キャッシュファイル</h2>\n";
	my @cachefiles = ();
	if($wiki->config("log_dir") ne ""){
		opendir(DIR,$wiki->config("log_dir")) or die $wiki->config("log_dir")."のオープンに失敗しました。";
		while(my $entry = readdir(DIR)){
			if($entry =~ /\.cache$/){
				push(@cachefiles,$entry);
			}
		}
		closedir(DIR);
	}
	
	if($#cachefiles==-1){
		$buf .= "<p>キャッシュファイルはありません。</p>\n";
	} else {
		$buf .= "<ul>\n";
		@cachefiles = sort(@cachefiles);
		foreach(@cachefiles){
			my @status = stat($wiki->config("log_dir")."/".$_);
			my $size = @status[7] / 1024;
			$size = ($size==int($size) ? $size : int($size + 1));
			
			$buf .= "<li>".&Util::escapeHTML($_)."(".$size."KB)</li>\n";
		}
		$buf .= "</ul>\n";
		$buf .= "<form action=\"\" method=\"POST\">\n".
		        "  <input type=\"submit\" name=\"deletecache\" value=\"キャッシュを削除\">\n".
		        "  <input type=\"hidden\" name=\"action\" value=\"ADMINLOG\">\n".
		        "</form>\n";
	}
	
	return $buf;
}

#==============================================================================
# ログファイルの情報表示と操作を行うフォームを出力する関数
#==============================================================================
sub make_log_form {
	my $self   = shift;
	my $wiki   = shift;
	my $name   = shift;
	my $target = shift;
	my $file   = $self->get_filename_from_target($wiki,$target);
	
	my $buf .= "<h2>".&Util::escapeHTML($name)."</h2>\n";
	
	if(-e $wiki->config('log_dir')."/$file"){
		my @status = stat($wiki->config('log_dir')."/$file");
		my $size = @status[7] / 1024;
		# 整数に切り上げ
		$size = ($size==int($size) ? $size : int($size + 1));
		$buf .= "<p>".&Util::escapeHTML($file)."(".$size."KB)</p>\n".
		        "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
		        "  <input type=\"submit\" name=\"download\" value=\"ダウンロード\">\n".
		        "  <input type=\"submit\" name=\"delete\" value=\"ファイル削除\">\n".
		        "  <input type=\"hidden\" name=\"target\" value=\"$target\">\n".
		        "  <input type=\"hidden\" name=\"action\" value=\"ADMINLOG\">\n".
		        "</form>\n";
	} else {
		$buf .= "<p>ログファイルはありません。</p>\n";
	}
	
	return $buf;
}

#==============================================================================
# ログファイルを削除
#==============================================================================
sub delete_log {
	my $self = shift;
	my $wiki = shift;
	my $target = $wiki->get_CGI->param("target");
	my $file   = $self->get_filename_from_target($wiki,$target);
	
	if($file eq ""){
		return $wiki->error("パラメータが不正です。");
	}
	
	unlink($wiki->config('log_dir')."/$file") or die $file."の削除に失敗しました。";
	
	return $wiki->redirectURL( $wiki->create_url({ action=>"ADMINLOG"}) );
	
	#$wiki->set_title("ログファイルの管理");
	#return "<p>ログファイルを削除しました。</p>\n".
	#       "<p>[<a href=\"".$wiki->config('script_name')."?action=ADMINLOG\">戻る</a>]</p>\n";
}

#==============================================================================
# ログファイルをダウンロード
#==============================================================================
sub download_log {
	my $self = shift;
	my $wiki = shift;
	my $target = $wiki->get_CGI->param("target");
	my $file   = $self->get_filename_from_target($wiki,$target);
	
	if($file eq ""){
		return $wiki->error("パラメータが不正です。");
	}
	
	print "Content-Type: text/plain\n";
	print "Content-Disposition: inline;filename=\"".&Jcode::convert($file,"sjis")."\"\n\n";
	open(LOG,$wiki->config('log_dir')."/$file") or die $file."のオープンに失敗しました。";
	binmode(LOG);
	while(<LOG>){ print $_; }
	close(LOG);
	
	exit();
}

#==============================================================================
# ログファイルのファイル名を取得する関数
#==============================================================================
sub get_filename_from_target {
	my $self   = shift;
	my $wiki   = shift;
	my $target = shift;
	if($target eq "access"){
		return $wiki->config('access_log_file');
	} elsif($target eq "attach"){
		return $wiki->config('attach_log_file');
	} elsif($target eq "freeze"){
		return $wiki->config('freeze_file');
	} elsif($target eq "download"){
		return $wiki->config('download_count_file');
	} else {
		return "";
	}
}

#==============================================================================
# キャッシュファイルを削除
#==============================================================================
sub delete_cache {
	my $self = shift;
	my $wiki = shift;
	
	unlink glob($wiki->config("log_dir")."/*.cache") or die "キャッシュファイルの削除に失敗しました。";
	
	return $wiki->redirectURL( $wiki->create_url({ action=>"ADMINLOG"}) );
	
	#$wiki->set_title("ログファイルの管理");
	#return "<p>キャッシュファイルを削除しました。</p>\n".
	#       "<p>[<a href=\"".$wiki->config('script_name')."?action=ADMINLOG\">戻る</a>]</p>\n";
}

1;
