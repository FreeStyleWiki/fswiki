###############################################################################
#
# アカウント情報管理を行うアクションハンドラ
#
###############################################################################
package plugin::admin::AccountHandler;
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
	my $cgi = $wiki->get_CGI;
	
	$wiki->set_title("アカウント情報");
	
	if($cgi->param("changepass") ne ""){
		return $self->change_pass($wiki);
	}
	if(!defined($wiki->get_login_info)) {
		return $wiki->error("ログインしていません。");
	}
	my $id = $wiki->get_login_info()->{id};
	
	return $self->account_form($wiki,$id);
}

#==============================================================================
# アカウント情報フォーム
#==============================================================================
sub account_form {
	my $self = shift;
	my $wiki = shift;
	my $id   = shift;
	
	my $buf = "<h2>アカウント情報</h2>";
	$buf .= "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n";
	$buf .= "  <table>\n";
	$buf .= "  <tr>\n";
	$buf .= "  <th>ID</th>\n";
	$buf .= "  <td><b>".&Util::escapeHTML($id)."</b>（変更はできません）</td>\n";
	$buf .= "  </tr>\n";
	$buf .= "  <tr>\n";
	$buf .= "  <th>現在のパスワード</th>\n";
	$buf .= "  <td><input type=\"password\" name=\"pass_old\" size=\"30\"></td>\n";
	$buf .= "  </tr>\n";
	$buf .= "  <tr>\n";
	$buf .= "  <th>新しいパスワード</th>\n";
	$buf .= "  <td><input type=\"password\" name=\"pass1\" size=\"30\"></td>\n";
	$buf .= "  </tr>\n";
	$buf .= "  <tr>\n";
	$buf .= "  <th>新しいパスワード（確認）</th>\n";
	$buf .= "  <td><input type=\"password\" name=\"pass2\" size=\"30\"></td>\n";
	$buf .= "  </tr>\n";
	$buf .= "  </table>\n";
#	$buf .= "  <div style=\"margin-top:10pt;\">\n";
	$buf .= "    <input type=\"submit\" name=\"changepass\" value=\"変更\">\n";
	$buf .= "    <input type=\"hidden\" name=\"action\" value=\"ACCOUNT\">\n";
	$buf .= "    <input type=\"hidden\" name=\"id\" value=\"".&Util::escapeHTML($id)."\">\n";
#	$buf .= "  </div>\n";
	$buf .= "</form>\n";
	
	return $buf;
}

#==============================================================================
# パスワードの変更
#==============================================================================
sub change_pass {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	my $id   = $cgi->param("id");

	my $pass_old     = $cgi->param("pass_old");
	my $pass         = $cgi->param("pass1");
	my $pass_confirm = $cgi->param("pass2");


	# 現在のパスワードの照合

	# 他人がパスワードを変更してしまうことを防止するため、パスワードを変更
	# する際には現在のパスワードを照合する必要がある。
	my $login = $wiki->login_check($id,&Util::md5($pass_old,$id));
	if(defined($login)){
		my $min_length = 2;

		# 新しいパスワードの正当性の確認
		if ( length( $pass ) < $min_length ) {
			return $wiki->error("新しいパスワードが入力されていません。".
				"少なくとも $min_length 文字以上入力してください。");
		}
		elsif ( $pass ne $pass_confirm ) {
			return $wiki->error("入力された二つのパスワードが合致しません。");
		}

		my $session = $cgi->get_session($wiki);
		$session->param("wiki_id"  ,$id);
		$session->param("wiki_type",$login->{type});
		$session->param("wiki_path",$login->{path});
		$session->flush();

		my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
		my ($p,$type)  = split(/\t/,$users->{$id});
		$users->{$id} = &Util::md5($pass,$id)."\t$type";
		&Util::save_config_hash($wiki,$wiki->config('userdat_file'),$users);
	} else {
		return $wiki->error("現在のパスワードが違います。");
	}
	
	$wiki->redirectURL( $wiki->create_url({ action=>"LOGIN" }) );
	
	#return "<p>パスワードを変更しました。</p>".
	#       "[<a href=\"".$wiki->config('script_name')."?action=LOGIN\">メニューに戻る</a>]\n";
}

1;
