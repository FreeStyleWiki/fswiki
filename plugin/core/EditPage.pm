###############################################################################
# 
# ページを編集するプラグイン
# 
###############################################################################
package plugin::core::EditPage;
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
	my $cgi = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	my $format   = $wiki->get_edit_format();
	my $content  = $cgi->param("content");
	my $sage     = $cgi->param("sage");
	my $template = $cgi->param("template");
	my $artno    = $cgi->param("artno");
	my $time     = $wiki->get_last_modified($pagename);
	
	my $buf = "";
	my $login = $wiki->get_login_info();

	if($pagename eq ""){
		return $wiki->error("ページが指定されていません。");
	}
	if($pagename =~ /([\|\[\]])|^:|([^:]:[^:])/){
		return $wiki->error("ページ名に使用できない文字が含まれています。");
	}
	if(!$wiki->can_modify_page($pagename)){
		return $wiki->error("ページの編集は許可されていません。");
	}
	
	#--------------------------------------------------------------------------
	# 保存処理
	if($cgi->param("save") ne ""){
		if($wiki->page_exists($pagename)){
			if($cgi->param("lastmodified") != $time){
				return $wiki->error("ページは既に別のユーザによって更新されています。");
			}
		}
		#my $save_content = $content;
		my $mode = $wiki->get_edit_format();
		my $save_content = $wiki->convert_to_fswiki($content,$mode);

		# パート編集の場合
		if($artno ne ""){
			$save_content = &make_save_source($wiki->get_page($pagename),$save_content,$artno,$wiki);
		}
		# FrontPageは削除不可
		if($pagename eq $wiki->config("frontpage") && $save_content eq ""){
			$buf = "<b>".&Util::escapeHTML($wiki->config("frontpage"))."は削除することはできません。</b>\n";

		# それ以外の場合は処理を実行してメッセージを返却
		} else {
			$wiki->save_page($pagename,$save_content,$sage);
			
			if($content ne ""){
				$wiki->redirect($pagename);
			} else {
				if($artno eq ""){
					$wiki->set_title($pagename."を削除しました");
					return Util::escapeHTML($pagename)."を削除しました。";
				} else {
					$wiki->set_title($pagename."のパートを削除しました");
					return Util::escapeHTML($pagename)."のパートを削除しました。";
				}
			}
		}
	#--------------------------------------------------------------------------
	# プレビュー処理
	} elsif($cgi->param("preview") ne ""){
		$time = $cgi->param("lastmodified");
		$buf = "以下のプレビューを確認してよろしければ「保存」ボタンを押してください。<br>";
		if($content eq ""){
			if($pagename eq $wiki->config("frontpage") && $artno eq ""){
				$buf = $buf."<b>（".&Util::escapeHTML($wiki->config("frontpage"))."は削除することはできません。）</b>";
			} else {
				if($artno eq ""){
					$buf = $buf."<b>（ページ内容は空です。更新するとこのページは削除されます。）</b>";
				} else {
					$buf = $buf."<b>（ページ内容は空です。更新するとこのパートは削除されます。）</b>";
				}
			}
		}
		$content = $wiki->convert_to_fswiki($content,$format);
		$buf = $buf."<br>".$wiki->process_wiki($content);

	} elsif($wiki->page_exists($pagename)) {
		#ページが存在する場合
		if($artno eq ""){
			$content = $wiki->get_page($pagename);
		} else {
			$content = &read_by_part($wiki->get_page($pagename),$artno);
		}
	} elsif($template ne ""){
		#テンプレートを指定された場合
		$content = $wiki->get_page($template);
	}
	
	#--------------------------------------------------------------------------
	# 入力フォーム
	$wiki->set_title($pagename."の編集",1);

	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/editform.tmpl",
                                   die_on_bad_params => 0);

	$tmpl->param({SCRIPT_NAME   => $wiki->create_url(),
				  PAGE_NAME     => $pagename,
				  CONTENT       => $wiki->convert_from_fswiki($content,$format),
				  LAST_MODIFIED => $time,
				  ACTION        => 'EDIT',
				  EXISTS_PAGE   => $wiki->page_exists($pagename),
				  SAGE          => $sage});
	
	if($artno ne ""){
		$tmpl->param(OPTIONAL_PARAMS=>[{NAME=>'artno',VALUE=>$artno}]);
	}

	$buf .= $tmpl->output();

	# プラグインを挿入
	$buf .= $wiki->get_editform_plugin();
	
	return $buf;
}

#==============================================================================
# パート編集の場合の編集部分の取り出し
#==============================================================================
sub read_by_part {
	my $page  = shift;
	my $num   = shift;
	my $count = 0;
	my $buf   = "";
	my $level = 0;
	my $flag  = 0;
	foreach my $line (split(/\n/,$page)){
		if($line=~/^(!{1,3})/){
			if($flag==1 && $level<=length($1)){
				last;
			}
			if($count==$num){
				$flag  = 1;
				$level = length($1);
			}
			$count++;
		}
		if($flag==1){
			$buf .= $line."\n";
		}
	}
	return $buf;
}

#==============================================================================
# パート編集の場合の保存用ソースの作成
#==============================================================================
sub make_save_source {
	my $org   = shift;
	my $edit  = shift;
	my $num   = shift;
	my $wiki  = shift;
	my $count = 0;
	my $buf   = "";
	my $level = "";
	my $flag  = "";
	foreach my $line (split(/\n/,$org)){
		if($line=~/^(!{1,3})/){
			if($flag==1 && $level<=length($1)){
				$flag = 0;
			}
			if($count==$num){
				$flag  = 1;
				$level = length($1);
				$buf .= $edit;
				# 最後が改行でない場合だけ改行を追加（次のセクションとくっついてしまうため）
				$buf .= "\n" unless($edit =~ /\n$/);
			}
			$count++;
		}
		if($flag==0){
			$buf .= "$line\n";
		}
	}
	return $buf;
}

#==============================================================================
# ページ表示時のフックメソッド
# 「編集」メニューを有効にします
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	my $login    = $wiki->get_login_info();
	
	# 編集メニューの制御
	if($wiki->can_modify_page($pagename)){
		$wiki->add_menu("編集",$wiki->create_url({ action=>"EDIT",page=>$pagename }));
	}
}

1;
