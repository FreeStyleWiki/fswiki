############################################################
#
# ページ保存時or削除時にメール送信を行うフックプラグイン
#
############################################################
package plugin::core::SendMail;
use strict;
use plugin::core::Diff;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# ページ保存後or削除後のフックメソッド
#===========================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $login    = $wiki->get_login_info();
	my $pagename = $cgi->param("page");
	my $content  = $cgi->param("content");
	my $backup   = $wiki->get_backup($pagename);
	my $diff     = plugin::core::Diff->new();
	
	my $subject;
	my $tmpl;
	
	# タイトルとテンプレートを決定
	if($content eq ""){
		$subject = $wiki->config('mail_prefix')."$pagenameが削除されました";
		
	} elsif($backup eq "") {
		$subject = $wiki->config('mail_prefix')."$pagenameが作成されました";
		
	} else {
		$subject = $wiki->config('mail_prefix')."$pagenameが更新されました";
		
	}
	
	my $mail = "";
	
	if($wiki->config('mail_id')==1 && defined($login)){
		$mail .= "ID:".$login->{id}."\n";
	}
	if($wiki->config('mail_remote_addr')==1){
		$mail .= "IP:".$ENV{'REMOTE_ADDR'}."\n";
	}
	if($wiki->config('mail_user_agent')==1){
		$mail .= "UA:".$ENV{'HTTP_USER_AGENT'}."\n";
	}
	if($wiki->config('mail_diff')==1){
		my @list = $wiki->{storage}->get_backup_list($pagename);
		my $last_generation = @list - 1;
		$mail .= "----\n";
		$mail .= "以下は変更の差分です。\n";
		$mail .= "----\n";
		$mail .= $diff->get_diff_text($wiki,$pagename,$last_generation)."\n";
	}
	if($wiki->config('mail_backup_source')==1){
		$mail .= "----\n";
		$mail .= "以下は変更前のソースです。\n";
		$mail .= "----\n";
		$mail .= $backup."\n";
	}
	if($wiki->config('mail_modified_source')==1){
		$mail .= "----\n";
		$mail .= "以下は変更後のソースです。\n";
		$mail .= "----\n";
		$mail .= $content."\n";
	}
	
	&Util::send_mail($wiki,$subject,$mail);
}

1;
