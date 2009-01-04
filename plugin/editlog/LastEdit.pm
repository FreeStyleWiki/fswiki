############################################################
#
# <p>ページの最終更新者と更新日時を表示します。</p>
# <pre>
# {{lastedit 表示件数,ページ名}}
# </pre>
# <p>
# 件数を省略すると最後の１件を表示します。
# ページ名を省略すると現在表示されているページの最終更新者と更新日時を表示します。
# </p>
#
############################################################
package plugin::editlog::LastEdit;
use strict;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# パラグラフメソッド
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $max  = shift;
	my $page = shift;
	my $cgi  = $wiki->get_CGI();
	
	return "更新履歴はありません。" if $wiki->config('log_dir') eq "";
	return "更新履歴はありません。" if ! -e $wiki->config('log_dir')."/useredit.log";
	
	if($page eq ""){ $page = $cgi->param("page"); }
	if($max  eq ""){ $max  = 1; }
	
	my @editlist;
	open(DATA,$wiki->config('log_dir')."/useredit.log") or die $!;
	while(<DATA>){
		my($date, $time, $unixtime, $action, $subject, $id) = split(" ",$_);
		if($subject eq Util::url_encode($page)){
			push(@editlist,{ACTION=>$action,DATE=>$date,TIME=>$time,ID=>$id,UNIXTIME=>$unixtime});
		}
	}
	close(DATA);
	
	if($#editlist==-1){
		return "更新履歴はありません。";
	}
	
	@editlist = sort { $b->{UNIXTIME}<=>$a->{UNIXTIME} } @editlist;
	my $content = "";
	my $count   = 0;
	foreach my $edit (@editlist){
		if($count >= $max){
			last;
		}
		if($edit->{ID} ne ""){
			$content .= "*[$edit->{ACTION}] $edit->{DATE} $edit->{TIME} by $edit->{ID}\n";
		} else {
			$content .= "*[$edit->{ACTION}] $edit->{DATE} $edit->{TIME}\n";
		}
		$count++;
	}
	
	return $content;
}

1;
