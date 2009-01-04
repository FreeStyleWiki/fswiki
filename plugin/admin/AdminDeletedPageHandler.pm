###############################################################################
#
# ページを管理するモジュール
#
###############################################################################
package plugin::admin::AdminDeletedPageHandler;
use strict;
use vars qw($DELETED_FILE);

$DELETED_FILE = "deleted.dat";

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# ページの削除時に呼び出される
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	open(FILE, ">>".$wiki->config('log_dir')."/".$DELETED_FILE);
	print FILE $wiki->get_CGI()->param("page")."\t".time()."\n";
	close(FILE);
}

#==============================================================================
# アクションハンドラメソッド
#==============================================================================
sub do_action {
	my $self  = shift;
	my $wiki  = shift;
	my $cgi   = $wiki->get_CGI;
	if($cgi->param('revert')){
		$self->revert($wiki);
	}
	return $self->deleted_page_list($wiki);
}

#==============================================================================
# 削除されたページの復元
#==============================================================================
sub revert {
	my $self  = shift;
	my $wiki  = shift;
	my @pages = $wiki->get_CGI()->param('pages');
	foreach my $page (@pages){
		$wiki->save_page($page, $wiki->get_backup($page, 0));
	}
}

#==============================================================================
# 削除されたページの一覧
#==============================================================================
sub deleted_page_list {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	
	my $buf = qq|
		<h2>削除されたページ</h2>
		<form action="@{[$wiki->create_url()]}" method="POST">
		<table>
		<tr>
			<th></th>
			<th>ページ名</th>
			<th>削除時刻</th>
		</tr>
	|;
	
	open(FILE, $wiki->config('log_dir')."/".$DELETED_FILE);
	my $pages = {};
	while(my $LINE = <FILE>){
		my ($page, $mod) = split(/\t/, $LINE);
		unless($wiki->page_exists($page)){
			$pages->{$page} = $mod;
		}
	}
	close(FILE);
	
	foreach my $page (sort { $pages->{$b} cmp $pages->{$a} } keys %$pages){
		my $mod = $pages->{$page};
		$buf .= qq|
		<tr>
			<td><input type="checkbox" name="pages" value="@{[&Util::escapeHTML($page)]}"></td>
			<td><a href="@{[$wiki->create_url({'action'=>'DIFF', 'page'=>$page})]}" target="_blank">@{[&Util::escapeHTML($page)]}</a></td>
			<td>@{[&Util::format_date($mod)]}</td>
		</tr>|;
	}
	
	$buf .= qq|</table>
		<input type="hidden" name="action" value="ADMINDELETED">
		<input type="submit" name="revert" value="チェックしたページを復元する">
	</form>|;
	
	$wiki->set_title("削除されたページ");
	return $buf;
}

1;
