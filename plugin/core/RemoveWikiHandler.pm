###############################################################################
#
# WikiFarmの削除を行うアクションハンドラ。
# WikiFarmの設定でFarm機能を使用する設定になっている場合のみ有効になります。
#
###############################################################################
package plugin::core::RemoveWikiHandler;
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
# アクションハンドラメソッド
#==============================================================================
sub do_action {
	my $self = shift;
	my $farm = shift;
	$farm->set_title("Wikiの削除");
	
	# 権限のチェック
	my $login  = $farm->get_login_info();
	my $config = &Util::load_config_hash($farm,$farm->config('farmconf_file'));
	if($config->{remove}==1){
		if(!defined($login)){
			return $farm->error("Wikiの削除は許可されていません。");
		}
	} elsif($config->{remove}==2){
		if(!defined($login) || $login->{type}!=0){
			return $farm->error("Wikiの削除は許可されていません。");
		}
	}
	
	# Wikiの存在チェック
	my $path = $farm->get_CGI()->param("path");
	unless($path =~ s|^/|| and $farm->wiki_exists($path)) {
		return $farm->error("Wikiが存在しません。");
	}
	
	if($farm->get_CGI()->param("exec_delete") ne ""){
		return $self->exec_remove($farm);
	} else {
		return $self->conf_remove($farm);
	}
}
#==============================================================================
# 削除確認
#==============================================================================
sub conf_remove {
	my $self = shift;
	my $farm = shift;
	my $path = $farm->get_CGI()->param("path");
	
	return "<p><a href=\"".$farm->config('script_name')."$path\">$path</a>を削除してよろしいですか？</p>".
	       "<form action=\"".$farm->create_url()."\" method=\"POST\">\n".
	       "  <input type=\"submit\" name=\"exec_delete\" value=\"削除\">\n".
	       "  <input type=\"hidden\" name=\"action\" value=\"REMOVE_WIKI\">\n".
	       "  <input type=\"hidden\" name=\"path\" value=\"".&Util::escapeHTML($path)."\">\n".
	       "</form>\n";
}
#==============================================================================
# 削除実行
#==============================================================================
sub exec_remove {
	my $self = shift;
	my $farm = shift;
	my $path = $farm->get_CGI()->param("path");
	
	$farm->remove_wiki($path);
	return "<p>".&Util::escapeHTML($path)."を削除しました。</p>";
}

1;
