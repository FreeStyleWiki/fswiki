###############################################################################
# 
# ページ名称の変更・ページのコピーをするハンドラ。
# 処理前にrenameフックを呼び出します。
# 
###############################################################################
package plugin::rename::RenameHandler;
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
# アクションの実行
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	
	return $self->do_rename($wiki);
}

#==============================================================================
# リネームを実行
#==============================================================================
sub do_rename {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;

	my $pagename    = $cgi->param("page");
	my $newpagename = $cgi->param("newpage");
	my $do          = $cgi->param("do");
	my $time        = $wiki->get_last_modified($pagename);
	my $buf         = "";
	my $login       = $wiki->get_login_info();

	# エラーチェック
	if($newpagename eq ""){
		return $wiki->error("ページが指定されていません!!");
	}
	if($newpagename =~ /[\|:\[\]]/){
		return $wiki->error("ページ名に使用できない文字が含まれています。");
	}
	if($wiki->page_exists($newpagename)){
		return $wiki->error("既にリネーム先のページが存在します!!");
	}
	if($newpagename eq $pagename){
		return $wiki->error("同一のページが指定されています!!");
	}
	if(!$wiki->can_modify_page($pagename) || !$wiki->can_modify_page($newpagename)){
		return $wiki->error("ページの編集は許可されていません。");
	}
	if($wiki->page_exists($pagename)){
		if($cgi->param("lastmodified") < $time){
			return $wiki->error("ページは既に別のユーザによって更新されています。");
		}
	}

	# FrontPageを移動しようとした場合にはエラー
	if($pagename eq $wiki->config("frontpage") && $do ne "copy"){
		return $wiki->error($wiki->config("frontpage")."を移動することはできません。");
	}

	# コピー処理
	$wiki->do_hook("rename");
	my $content = $wiki->get_page($pagename);
	$wiki->save_page($newpagename,$content);
	
	# 削除処理
	if($do eq "move"){
		$wiki->save_page($pagename,'');
	}elsif($do eq "movewm"){
		$wiki->save_page($pagename,'[['.$newpagename.']]に移動しました。');
	}

	# フックの起動と返却メッセージ
	if($do eq "copy"){
		$wiki->set_title($pagename."をコピーしました");
		return Util::escapeHTML($pagename)."をコピーしました。";
	} else {
		$wiki->set_title($pagename."をリネームしました");
		return Util::escapeHTML($pagename)."をリネームしました。";
	}
}

1;
