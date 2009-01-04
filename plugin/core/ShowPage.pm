###############################################################################
# 
# ページを表示するプラグイン
# 
###############################################################################
package plugin::core::ShowPage;
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
# アクションの実行
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if(!defined($pagename) || $pagename eq ""){
		$pagename = $wiki->config("frontpage");
		$cgi->param("page",$pagename);
	}
	
	if($wiki->page_exists($pagename)){
		# アクセスログの記録
		if($wiki->config('log_dir') ne "" && $wiki->config('access_log_file') ne ""){
			&write_log($wiki,$pagename);
		}
		
		# 参照権限のチェック
		if(!$wiki->can_show($pagename)){
			$wiki->set_title("参照権限がありません");
			return $wiki->error("参照権限がありません。");
		}
		
		$wiki->set_title($pagename);
		$wiki->do_hook("show"); # 本当はWiki.pmの中から呼びたい...
		
		return $wiki->process_wiki($wiki->get_page($pagename),1,1);
		
	} else {
		return $wiki->call_handler("EDIT",$cgi);
	}
}

#==============================================================================
# アクセスログの記録
#==============================================================================
sub write_log {
	my $wiki = shift;
	my $page = shift;
	
	my $ip  = $ENV{"REMOTE_ADDR"};
	my $ref = $ENV{"HTTP_REFERER"};
	my $ua  = $ENV{"HTTP_USER_AGENT"};
	if(!defined($ip)  || $ip  eq ""){ $ip  = "-"; }
	if(!defined($ref) || $ref eq ""){ $ref = "-"; }
	if(!defined($ua)  || $ua  eq ""){ $ua  = "-"; }
	
	my $logfile = $wiki->config('log_dir')."/".$wiki->config('access_log_file');
	Util::file_lock($logfile);
	open(LOG,">>$logfile") or die $!;
	print LOG Util::url_encode($page)." ".&log_date()." $ip $ref $ua\n";
	close(LOG);
	Util::file_unlock($logfile);
}

#===============================================================================
# 日付をフォーマット（アクセスログ用）
#===============================================================================
sub log_date {
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time());
	return sprintf("%04d/%02d/%02d %02d:%02d:%02d",
	               $year+1900,$mon+1,$mday,$hour,$min,$sec);
}

1;
