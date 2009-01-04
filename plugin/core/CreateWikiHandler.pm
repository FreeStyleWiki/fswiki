###############################################################################
#
# 子Wikiを作成します。
# WikiFarmの設定でFarm機能を使用する設定になっている場合のみ有効になります。
#
###############################################################################
package plugin::core::CreateWikiHandler;
use strict;
use plugin::core::WikiList;
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
sub do_action{
	my $self  = shift;
	my $farm  = shift;
	my $cgi   = $farm->get_CGI;
	my $child = $cgi->param("child");
	my $admin_id   = $cgi->param("admin_id");
	my $admin_pass = $cgi->param("admin_pass");
	
	my $can_create = 1;
	
	my $config = &Util::load_config_hash($farm,$farm->config('farmconf_file'));
	my $login  = $farm->get_login_info();
	if($config->{create}==1){
		if(!defined($login)){
			$can_create = 0;
			#return $farm->error("Wikiの作成は許可されていません。");
		}
	} elsif($config->{create}==2){
		if(!defined($login) || $login->{type}!=0){
			$can_create = 0;
			#return $farm->error("Wikiの作成は許可されていません。");
		}
	}
	
	if($child eq ""){
		# 子Wikiの名前入力フォーム
		$farm->set_title("WikiFarm",1);
		my $buf = "";
		
		if($can_create==1){
			$buf = "<h2>新規Wikiの作成</h2>\n".
			       "<form method=\"post\" action=\"".$farm->create_url()."\">\n".
			       "  <h3>Wikiの名前</h3>\n".
			       "  <p>ここで設定したWiki名はURLに含まれますのでそのWikiの特徴を表した、".
			       "     できるだけ短い名前をつけることをオススメします。".
			       "     半角英数字しか使用できません。</p>\n".
			       "  <p>Wiki名：<input type=\"text\" name=\"child\" size=\"40\"></p>".
			       "  <h3>管理者の情報</h3>\n".
			       "  <p>作成するWikiの管理者IDとパスワードを設定してください。".
			       "     半角英数字しか使用できません。</p>\n".
			       "  <p>ID：<input type=\"text\" size=\"20\" name=\"admin_id\">\n".
			       "     Pass：<input type=\"password\" size=\"20\" name=\"admin_pass\">\n".
			       "  </p>\n".
			       "  <input type=\"submit\" value=\" 作成 \">".
			       "  <input type=\"hidden\" name=\"action\" value=\"CREATE_WIKI\">".
			       "</form>\n";
		}
		
		# 子Wikiの一覧
		my $wikilist = plugin::core::WikiList->new();
		my $listcnt  = $wikilist->paragraph($farm);
		
		$buf .= "<h2>Wikiサイトの一覧</h2>\n";
		
		if($listcnt eq "<ul>\n</ul>\n"){
			$buf .= "<p>現在このWiki配下にはWikiサイトはありません。</p>";
		} else {
			$buf .= "<p>現在このWikiの配下には以下のWikiサイトが存在します。</p>".$listcnt;
		}
		
		return $buf;
		
	}else{
		if($can_create==0){
			return $farm->error("Wikiの作成は許可されていません。");
		}
		
		# 入力チェック
		if(!($child =~ /^[A-Za-z0-9]+$/)){
			return $farm->error(&Util::escapeHTML($child)."は不正な名称です。");
		
		} elsif($admin_id eq ""){
			return $farm->error("管理者IDを入力してください。");
			
		} elsif($admin_pass eq ""){
			return $farm->error("管理者パスワードを入力してください。");
			
		} elsif(!($admin_id =~ /^[A-Za-z0-9]+$/)){
			return $farm->error("管理者IDが不正です。");
		
		} elsif(!($admin_pass =~ /^[A-Za-z0-9]+$/)){
			return $farm->error("管理者パスワードが不正です。");
		
		# 子Wikiの重複をチェック
		} elsif($farm->wiki_exists($child)){
			return $farm->error(&Util::escapeHTML($child)."は既に存在します。");
		
		# ユーザの重複をチェック
		#} elsif($farm->user_exists($admin_id)){
		#	return $farm->error("ID：".&Util::escapeHTML($admin_id)."のユーザは既に存在します。");
			
		# 子Wiki作成
		} else {
			$farm->create_wiki($child,$admin_id,$admin_pass);
			$farm->set_title(&Util::escapeHTML($child)."を作成しました");
			return "<a href=\"".$farm->config('script_name')."/".&Util::escapeHTML($child)."\">".
			       &Util::escapeHTML($child)."</a>を作成しました。";
		}
	}
}

1;
