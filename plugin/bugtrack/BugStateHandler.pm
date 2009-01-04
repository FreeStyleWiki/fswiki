######################################################
#
# BugStateプラグイン用のアクションハンドラです。
#
######################################################
package plugin::bugtrack::BugStateHandler;
use strict;
#=====================================================
# コンストラクタ
#=====================================================
sub new {
    my $class = shift;
    my $self = {};
    return bless $self,$class;
}
#=====================================================
# アクションハンドラ
#=====================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi    = $wiki->get_CGI;
	my $source = $cgi->param("source");
	my $state  = $cgi->param("state");
	my $page   = $cgi->param("page");
	
	if($wiki->page_exists($source)){
		if(!$wiki->can_modify_page($source)){
			return $wiki->error("ページの編集は許可されていません。");
		}
		my $content = $wiki->get_page($source);
		$content =~ s/(\n\*状態：)\s+(.*)/$1 $state/;
		$wiki->save_page($source,$content);
	}
	
	$wiki->redirect($page);
}

1;
