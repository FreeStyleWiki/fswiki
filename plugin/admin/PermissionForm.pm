###############################################################################
#
# 管理者ログイン時にページ編集画面に権限変更用のフォームを出力するプラグイン。
#
###############################################################################
package plugin::admin::PermissionForm;
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
# 編集フォームを出力するメソッド
#==============================================================================
sub editform {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $page = $cgi->param("page");
	
	unless($wiki->page_exists($page)){
		return "";
	}
	my $login = $wiki->get_login_info();
	unless(defined($login)){
		return "";
	}
	if($login->{type}!=0){
		return "";
	}
	
	my $show_level = $wiki->get_page_level($page);
	
	my $buf = "<h2>ページの参照・更新権限</h2>\n";
	
	$buf .= "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n";
	
	$buf .= "<input type=\"radio\" id=\"show_level_0\" name=\"show_level\" value=\"0\"";
	if($show_level==0){ $buf .= " checked"; }
	$buf .= "><label for=\"show_level_0\">全員に公開</label> ";
	$buf .= "<input type=\"radio\" id=\"show_level_1\" name=\"show_level\" value=\"1\"";
	if($show_level==1){ $buf .= " checked"; }
	$buf .= "><label for=\"show_level_1\">ユーザのみ</label> ";
	$buf .= "<input type=\"radio\" id=\"show_level_2\" name=\"show_level\" value=\"2\"";
	if($show_level==2){ $buf .= " checked"; }
	$buf .= "><label for=\"show_level_2\">管理者のみ</label> \n";
	
	$buf .= "<input type=\"submit\" name=\"change_show_level\" value=\"参照権限を変更\">\n";
	
	if($wiki->is_freeze($page)){
		$buf .= "<input type=\"submit\" name=\"unfreeze\" value=\"凍結を解除\">";
	} else {
		$buf .= "<input type=\"submit\" name=\"freeze\" value=\"ページを凍結\">";
	}
	$buf .= "<input type=\"hidden\" name=\"page\" value=\"".&Util::escapeHTML($page)."\">\n";
	$buf .= "<input type=\"hidden\" name=\"action\" value=\"CHANGE_PAGE_PERMISSION\">\n";
	$buf .= "</form>\n";
	
	return $buf;
}

#==============================================================================
# アクションハンドラメソッド
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $page = $cgi->param("page");
	
	if($cgi->param("change_show_level") ne ""){
		my $level = $cgi->param("show_level");
		$wiki->set_page_level($page,$level);
		
	} elsif($cgi->param("unfreeze") ne ""){
		$wiki->un_freeze_page($page);
		
	} elsif($cgi->param("freeze") ne ""){
		$wiki->freeze_page($page);
	}
	
	$wiki->redirect($page);
}

1;
