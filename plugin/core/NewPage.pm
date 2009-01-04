############################################################
# 
# ページ作成用フォームを表示するプラグイン
# 
############################################################
package plugin::core::NewPage;
#use strict;
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
	
	if($wiki->config('accept_edit')==0 && !defined($wiki->get_login_info())){
		return $wiki->error("ページの作成は許可されていません。");
	}
	
	$wiki->set_title("新規作成",1);
	
	return "<form method=\"post\" action=\"".$wiki->create_url()."\">\n".
	       "  <input type=\"text\" name=\"page\" size=\"40\">".
	       "  <input type=\"submit\" value=\" 作成 \">".
	       "  <input type=\"hidden\" name=\"action\" value=\"EDIT\">".
	       "</form>\n";
}

1;
