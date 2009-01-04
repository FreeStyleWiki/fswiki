###############################################################################
#
# ユーザ管理を行うアクションハンドラ
#
###############################################################################
package plugin::admin::AdminUserHandler;
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
	
	$wiki->set_title("ユーザ管理");
	
	if($cgi->param("delete") ne ""){
		return $self->delete_user($wiki);
		
	} elsif($cgi->param("regist") ne ""){
		return $self->user_form($wiki,{});
		
	} elsif($cgi->param("update") ne ""){
		my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
		my $id = $cgi->param("update");
		my ($pass,$type) = split(/\t/,$users->{$id});
		
		return $self->user_form($wiki,{id=>$id,pass=>$pass,type=>$type});
		
	} elsif($cgi->param("saveuser") ne ""){
		return $self->save_user($wiki);
	
	} elsif($cgi->param("changepass") ne ""){
		return $self->change_pass($wiki);
		
	} else {
		return $self->user_list($wiki);
	}
}

#==============================================================================
# ユーザ一覧
#==============================================================================
sub user_list {
	my $self = shift;
	my $wiki = shift;
	
	my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
	my $buf .= "<h2>ユーザ一覧</h2>\n".
	           "<table>\n".
	           "<tr><th>ID</th><th>種別</th><th>操作</th></tr>\n";
	
	foreach my $id (sort(keys(%$users))){
		my ($pass,$type) = split(/\t/,$users->{$id});
		
		$buf .= "<tr>\n";
		$buf .= "  <td>".&Util::escapeHTML($id)."</td>\n";
		if($type==0){
			$buf .= "  <td>管理者</td>\n";
		} else {
			$buf .= "  <td>一般</td>\n";
		}
		$buf .= "  <td><a href=\"".$wiki->create_url({action=>"ADMINUSER",update=>$id})."\">変更</a> ".
		              "<a href=\"".$wiki->create_url({action=>"ADMINUSER",delete=>$id})."\">削除</a></td>\n";
		$buf .= "</tr>\n";
	}
	$buf .= "</table>\n";
	$buf .= "<form action=\"".$wiki->create_url()."\" method=\"GET\">\n".
	        "  <input type=\"submit\" name=\"regist\" value=\"ユーザの追加\">\n".
	        "  <input type=\"hidden\" name=\"action\" value=\"ADMINUSER\">\n".
	        "</form>\n";
	return $buf;
}

#==============================================================================
# ユーザ追加・更新フォーム
#==============================================================================
sub user_form {
	my $self = shift;
	my $wiki = shift;
	my $data = shift;
	
	my $buf = "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n";
	if(defined($data->{id})){
		$buf .= "<h2>ユーザの変更</h2>";
	} else {
		$buf .= "<h2>ユーザの追加</h2>";
	}
	$buf .= "<h3>ID</h3>\n";
	if(defined($data->{id})){
		$buf .= "<p><b>".&Util::escapeHTML($data->{id})."</b>（変更はできません）</p>\n";
		$buf .= "<input type=\"hidden\" name=\"id\" value=\"".&Util::escapeHTML($data->{id})."\">\n";
	} else {
		$buf .= "<p><input type=\"text\" name=\"id\" size=\"20\"></p>\n";
	}
	if(!defined($data->{id})){
		$buf .= "<h3>パスワード</h3>\n";
		$buf .= "<p><input type=\"password\" name=\"pass\" size=\"20\"></p>\n";
	}
	$buf .= "<h3>種別</h3>\n";
	$buf .= "<p>\n";
	$buf .= "<input type=\"radio\" name=\"type\" value=\"0\" id=\"type_0\"";
	if($data->{type}!=1){ $buf .= " checked"; }
	$buf .= "><label for=\"type_0\">管理者</label>\n";
	$buf .= "<input type=\"radio\" name=\"type\" value=\"1\" id=\"type_1\"";
	if($data->{type}==1){ $buf .= " checked"; }
	$buf .= "><label for=\"type_1\">一般</label>\n";
	$buf .= "</p>\n";
	
	if(defined($data->{id})){
		$buf .= "<input type=\"submit\" name=\"saveuser\" value=\"変更\">\n";
	} else {
		$buf .= "<input type=\"submit\" name=\"saveuser\" value=\"追加\">\n";
	}
	$buf .= "<input type=\"hidden\" name=\"action\" value=\"ADMINUSER\">\n";
	$buf .= "</form>\n";
	
	if(defined($data->{id})){
		$buf .= "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n";
		$buf .= "  <h2>パスワードの変更</h2>\n";
		$buf .= "  <h3>新しいパスワード</h3>\n";
		$buf .= "  <p><input type=\"password\" name=\"pass\" size=\"30\"></p>\n";
		$buf .= "  <input type=\"submit\" name=\"changepass\" value=\"変更\">\n";
		$buf .= "  <input type=\"hidden\" name=\"action\" value=\"ADMINUSER\">\n";
		$buf .= "  <input type=\"hidden\" name=\"id\" value=\"".&Util::escapeHTML($data->{id})."\">\n";
		$buf .= "</form>\n";
	}
	
	$buf .= "[<a href=\"". $wiki->create_url({ action=>"ADMINUSER" }) . "\">戻る</a>]\n";
	
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
	my $type = $cgi->param("type");
	my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
	
	if(!defined($users->{$id})){
		if($id eq "" || $pass eq "" || $type eq ""){
			return $wiki->error("ID、パスワード、ユーザ種別を指定してください。");
		}
	} else {
		if($id eq "" || $type eq ""){
			return $wiki->error("ID、ユーザ種別を指定してください。");
		}
	}
	unless($id =~ /^[a-zA-Z0-9\-_]+$/ && (!defined($pass) || $pass =~ /^[a-zA-Z0-9\-_]+/)){
		return $wiki->error("ID、パスワードには半角英数字しか使用できません。");
	}
	
	if(defined($users->{$id})){
		($pass) = split(/\t/,$users->{$id});
		$users->{$id} = "$pass\t$type";
	} else {
		$users->{$id} = &Util::md5($pass,$id)."\t$type";
	}
	&Util::save_config_hash($wiki,$wiki->config('userdat_file'),$users);
	
	$wiki->redirectURL( $wiki->create_url({ action=>"ADMINUSER"}) );
}

#==============================================================================
# パスワードの変更
#==============================================================================
sub change_pass {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	my $id   = $cgi->param("id");
	my $pass = $cgi->param("pass");
	
	my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
	my ($p,$type)  = split(/\t/,$users->{$id});
	$users->{$id} = &Util::md5($pass,$id)."\t$type";
	&Util::save_config_hash($wiki,$wiki->config('userdat_file'),$users);
	
	$wiki->redirectURL( $wiki->create_url({ action=>"ADMINUSER"}) );
}

#==============================================================================
# ユーザの削除
#==============================================================================
sub delete_user {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $id   = $cgi->param("delete");
	
	my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
	my $saveusers = {};
	foreach(sort(keys(%$users))){
		if($_ ne $id){
			$saveusers->{$_} = $users->{$_};
		}
	}
	&Util::save_config_hash($wiki,$wiki->config('userdat_file'),$saveusers);
	
	$wiki->redirectURL( $wiki->create_url({ action=>"ADMINUSER"}) );
}

1;
