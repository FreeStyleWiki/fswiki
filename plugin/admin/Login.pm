###############################################################################
#
# 管理者ログイン
#
###############################################################################
package plugin::admin::Login;
use strict;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
}

#==============================================================================
# アクションハンドラ
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	
	$wiki->set_title("管理");
	my $cgi = $wiki->get_CGI;
	
	if($cgi->param("logout") ne ""){
		return $self->logout($wiki);
	}
	
	if(defined($wiki->get_login_info())){
		return $self->admin_form($wiki,$wiki->get_login_info());
	} else {
		# ログインの判定
		my $id   = $cgi->param("id");
		my $pass = $cgi->param("pass");
		if($id ne "" && $pass ne ""){
			my $login = $wiki->login_check($id,&Util::md5($pass,$id));
			if(defined($login)){
				my $session = $cgi->get_session($wiki,1);
				$session->param("wiki_id"  ,$id);
				$session->param("wiki_type",$login->{type});
				$session->param("wiki_path",$login->{path});
				$session->flush();
				$wiki->redirectURL($wiki->create_url({action=>"LOGIN"}));
			} else {
				return $wiki->error("IDもしくはパスワードが違います。");
			}
		}
	}
	return $self->default($wiki);
}

#==============================================================================
# 管理画面フォーム
#==============================================================================
sub admin_form {
	my $self  = shift;
	my $wiki  = shift;
	my $login = shift;
	my $buf = "<h2>ログイン中</h2>\n";
	
	# 管理者ユーザの場合
	if($login->{type}==0){
		$buf .="<ul>\n";
		foreach($wiki->get_admin_menu){
			$buf .= "<li><a href=\"".$_->{url}."\">".$_->{label}."</a>";
			$buf .= " - ".&Util::escapeHTML($_->{desc});
			$buf .= "</li>\n";
		}
		$buf .= "</ul>\n";
		
	# 一般ユーザの場合
	} else {
		$buf .="<ul>\n";
		foreach($wiki->get_admin_menu){
			if($_->{type}==1){
				$buf .= "<li><a href=\"".$_->{url}."\">".$_->{label}."</a>";
				$buf .= " - ".&Util::escapeHTML($_->{desc});
				$buf .= "</li>\n";
			}
		}
		$buf .= "</ul>\n";
	}
	
	$buf .= "<form action=\"".$wiki->create_url()."\" method=\"POST\">".
	        "  <input type=\"submit\" name=\"logout\" value=\"ログアウト\">".
	        "  <input type=\"hidden\" name=\"action\" value=\"LOGIN\">".
	        "</form>\n";
	
	return $buf;
}

#==============================================================================
# ログアウト処理
#==============================================================================
sub logout {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	
	# CGI::Sessionの破棄
	my $session = $cgi->get_session($wiki);
	$session->delete();
	$session->flush();
	
	# Cookieの破棄
	my $path   = &Util::cookie_path($wiki);
	my $cookie = CGI::Cookie->new(-name=>'CGISESSID',-value=>'',-expires=>-1,-path=>$path);
	print "Set-Cookie: ".$cookie->as_string()."\n";
	
	return "ログアウトしました。";
}

#==============================================================================
# ログイン画面
#==============================================================================
sub default {
	my $self = shift;
	my $wiki = shift;
	
	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/login.tmpl",
	                               die_on_bad_params => 0);
	$tmpl->param(
		ACCEPT_USER_REGISTER => $wiki->config("accept_user_register"),
		URL => $wiki->create_url());
		
	return $tmpl->output();
}

1;
