###############################################################################
#
# ユーザの登録を行うアクションハンドラ
#
###############################################################################
package plugin::admin::UserRegisterHandler;
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
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	
	if($cgi->param("saveuser") ne ""){
		return $self->save_user($wiki);
		
	} else {
		return $self->user_form($wiki);
	}
}

#==============================================================================
# ユーザ追加・更新フォーム
#==============================================================================
sub user_form {
	my $self = shift;
	my $wiki = shift;
	
	$wiki->set_title("ユーザ情報の登録");
	
	my $buf = "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n";
	$buf .= "<h2>ユーザ情報の登録</h2>";
	$buf .= "<h3>ID</h3>\n";
	$buf .= "<p><input type=\"text\" name=\"id\" size=\"20\"></p>\n";
	$buf .= "<h3>パスワード</h3>\n";
	$buf .= "<p><input type=\"password\" name=\"pass\" size=\"20\"></p>\n";
	$buf .= "<input type=\"submit\" name=\"saveuser\" value=\"登録\">\n";
	$buf .= "<input type=\"hidden\" name=\"action\" value=\"USERREGISTER\">\n";
	$buf .= "</form>\n";
	
	return $buf;
}

#==============================================================================
# ユーザ情報の保存
#==============================================================================
sub save_user {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $id   = $cgi->param("id");
	my $pass = $cgi->param("pass");
	my $type = 1;
	
	if($wiki->user_exists($id)){
		return $wiki->error("入力されたIDはすでに使用されています。");
	}
	if($id eq "" || $pass eq ""){
		return $wiki->error("ID、パスワードを指定してください。");
	}
	unless($id =~ /^[a-zA-Z0-9\-_]+$/ && $pass =~ /^[a-zA-Z0-9\-_]+/){
		return $wiki->error("ID、パスワードには半角英数字しか使用できません。");
	}
	
	Util::sync_update_config($wiki,$wiki->config('userdat_file'),sub {
		my $hash = shift;
		unless(defined($hash->{$id})){
			$hash->{$id} = &Util::md5($pass,$id)."\t$type";
		}
		return $hash;
	});
	
	return qq|
	<h1>ユーザ情報の登録</h1>
	<p>
		ユーザ情報を登録しました。
		引き続き<a href="@{[$wiki->create_url({action=>'LOGIN'})]}">ログイン</a>してください。
	</p>
	|;
}

1;
