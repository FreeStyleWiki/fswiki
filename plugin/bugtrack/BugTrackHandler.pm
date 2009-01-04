################################################################################
#
# バグトラックプラグインのアクションハンドラ。
# 
################################################################################
package plugin::bugtrack::BugTrackHandler;
use strict;
#===============================================================================
# コンストラクタ
#===============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# アクションハンドラ
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	
	my $project  = $cgi->param("project");
	my $name     = $cgi->param("name");
	my $category = $cgi->param("category");
	my $priority = $cgi->param("priority");
	my $status   = $cgi->param("status");
	my $content  = $cgi->param("content");
	my $subject  = $cgi->param("subject");
	my $time     = time();
	
	if($name eq ""){
		return $wiki->error("名前が入力されていません。");
	} elsif($subject eq ""){
		return $wiki->error("サマリが入力されていません。");
	} elsif($content eq ""){
		return $wiki->error("バグ内容が入力されていません。");
	}
	
	# post_nameというキーでクッキーをセットする
	my $path   = &Util::cookie_path($wiki);
	my $cookie = $cgi->cookie(-name=>'post_name',-value=>$name,-expires=>'+1M',-path=>$path);
	print "Set-Cookie: ",$cookie->as_string,"\n";
	
	# フォーマットプラグインへの対応
	my $format = $wiki->get_edit_format();
	$name     = $wiki->convert_to_fswiki($name    ,$format,1);
	$category = $wiki->convert_to_fswiki($category,$format,1);
	$priority = $wiki->convert_to_fswiki($priority,$format,1);
	$status   = $wiki->convert_to_fswiki($status  ,$format,1);
	$content  = $wiki->convert_to_fswiki($content ,$format);
	
	my $page = $self->make_pagename($wiki,$project);
	
	$content = "!!!$subject\n".
	           "*投稿者： $name\n".
	           "*カテゴリ： $category\n".
	           "*優先度： $priority\n".
	           "*状態： $status\n".
	           "*日時： ".Util::format_date($time)."\n".
	           "{{bugstate}}\n".
	           "!!内容\n".$content."\n".
	           "!!コメント\n{{comment}}";
	
	$wiki->save_page($page,$content);
	$wiki->redirect($page);
}

#==============================================================================
# バグレポートのページ名を取得
#==============================================================================
sub make_pagename {
	my $self = shift;
	my $wiki = shift;
	my $project = shift;
	
	my @list = $wiki->get_page_list;
	my $count = 0;
	foreach(@list){
		if($_ =~ /^BugTrack-$project\/([0-9]+)$/){
			if($count < $1){
				$count = $1;
			}
		}
	}
	$count++;
	return "BugTrack-$project/$count";
}

1;
