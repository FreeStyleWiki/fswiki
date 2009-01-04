############################################################
#
# 掲示版プラグインのアクションハンドラ。
#
############################################################
package plugin::bbs::BBS2Handler;
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
# 記事の書き込み
#===========================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $bbsname = $cgi->param("bbsname");
	my $name    = $cgi->param("name");
	my $subject = $cgi->param("subject");
	my $message = $cgi->param("message");
	my $page    = $cgi->param("page");
	my $option  = $cgi->param("option");
	
	if($name    eq ""){
		$name    = "名無しさん";
	} else {
		# post_nameというキーでクッキーをセットする
		my $path   = &Util::cookie_path($wiki);
		my $cookie = $cgi->cookie(-name=>'post_name',-value=>$name,-expires=>'+1M',-path=>$path);
		print "Set-Cookie: ",$cookie->as_string,"\n";
	}
	
	if($subject eq ""){
		$subject = "無題";
	}
	
	if($bbsname eq ""){
		return $wiki->error("パラメータが不正です。");
	}
	if($message eq ""){
		return $wiki->error("本文を入力してください。");
	}
	
	# フォーマットプラグインへの対応
	my $format = $wiki->get_edit_format();
	$name    = $wiki->convert_to_fswiki($name   ,$format,1);
	$subject = $wiki->convert_to_fswiki($subject,$format,1);
	$message = $wiki->convert_to_fswiki($message,$format);
	
	my $pagename = $self->get_page_name($wiki,$bbsname);
	my $content = "!![[$subject|$pagename]] - $name (".&Util::format_date(time()).")\n".
	              "$message\n";
	
	# no_commentオプション
	if($option eq "no_comment"){
		
	# reverse_commentオプション
	} elsif($option eq "reverse_comment"){
		$content .= "{{comment reverse}}\n";
	# デフォルト
	} else {
		$content .= "{{comment}}\n";
	}
	$wiki->save_page($pagename,$content);
	
	# 元のページにリダイレクト
	$wiki->redirect($pagename);
}

#===========================================================
# 作成するページ名を取得
#===========================================================
sub get_page_name {
	my $self  = shift;
	my $wiki  = shift;
	my $name  = shift;
	my $count = 0;
	my $qname = quotemeta($name);
	foreach my $pagename ($wiki->get_page_list()){
		if($pagename =~ /^BBS-$qname\/([0-9]+)$/){
			if($count < $1){
				$count = $1;
			}
		}
	}
	$count++;
	return "BBS-$name/$count";
}

1;
