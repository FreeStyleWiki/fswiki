############################################################
#
# ログイン機能、管理画面を提供します。
#
############################################################
package plugin::admin::Install;
use strict;

sub install {
	my $wiki = shift;
	
	$wiki->add_menu("ログイン",$wiki->create_url({action=>"LOGIN"}),0);
	$wiki->add_handler("LOGIN","plugin::admin::Login");
	
	$wiki->add_admin_menu("環境設定"         ,$wiki->create_url({action=>"ADMINCONFIG"}),999,
						  "FSWiki全体の動作に関する設定を行います。");
	
	$wiki->add_admin_menu("スタイル設定"     ,$wiki->create_url({action=>"ADMINSTYLE"}) ,998,
						  "見栄えに関する設定を行います。");
	
	$wiki->add_admin_menu("ユーザ管理"       ,$wiki->create_url({action=>"ADMINUSER"})  ,997,
						  "ユーザの追加、変更、削除を行います。");

	$wiki->add_admin_menu("ページ管理"       ,$wiki->create_url({action=>"ADMINPAGE"})  ,996,
						  "ページの凍結、アクセス権限、一括削除を行います。");
	
	$wiki->add_admin_menu("削除されたページ" ,$wiki->create_url({action=>"ADMINDELETED"})  ,995,
						  "削除されたページの確認と復元を行います。");
	
	$wiki->add_admin_menu("プラグイン設定"   ,$wiki->create_url({action=>"ADMINPLUGIN"}),994,
						  "プラグインの有効化、無効化を行います。");

	$wiki->add_admin_menu("ログ・キャッシュ" ,$wiki->create_url({ action=>"ADMINLOG"})   ,992,
						  "ログファイル、キャッシュファイルのダウンロードを削除を行います。");

	$wiki->add_admin_menu("スパム対策" ,$wiki->create_url({ action=>"ADMINSPAM" })   ,991,
						  "スパム対策用の設定を行います。");

	$wiki->add_user_menu("パスワードの変更",$wiki->create_url({ action=>"ACCOUNT" }),500,
						 "自分のパスワードを変更します。");
	
	$wiki->add_admin_handler("ADMINPAGE"   ,"plugin::admin::AdminPageHandler");
	$wiki->add_admin_handler("ADMINDELETED","plugin::admin::AdminDeletedPageHandler");
	$wiki->add_admin_handler("ADMINLOG"    ,"plugin::admin::AdminLogHandler");
	$wiki->add_admin_handler("ADMINCONFIG" ,"plugin::admin::AdminConfigHandler");
	$wiki->add_admin_handler("ADMINUSER"   ,"plugin::admin::AdminUserHandler");
	$wiki->add_admin_handler("ADMINPLUGIN" ,"plugin::admin::AdminPluginHandler");
	$wiki->add_admin_handler("ADMINSTYLE"  ,"plugin::admin::AdminStyleHandler");
	$wiki->add_admin_handler("ADMINSPAM"   ,"plugin::admin::AdminSpamHandler");
	
	$wiki->add_user_handler("ACCOUNT","plugin::admin::AccountHandler");
	
	$wiki->add_editform_plugin("plugin::admin::PermissionForm",101);
	$wiki->add_admin_handler("CHANGE_PAGE_PERMISSION","plugin::admin::PermissionForm");
	
	if($wiki->config("accept_user_register")){
		$wiki->add_handler("USERREGISTER","plugin::admin::UserRegisterHandler");
	}
	
	$wiki->add_hook("delete","plugin::admin::AdminDeletedPageHandler");
}

1;
