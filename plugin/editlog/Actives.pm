############################################################
# 
# <p>アクティブなユーザを一覧表示します。<p>
# <p>
# 引数で表示件数を指定できます。(0で全員表示)
# </p>
# <pre>
# {{actives 5}}
# </pre>
# <p>
# n日前までの統計をとることもできます。
# </p>
# <pre>
# {{actives 5,7}}
# </pre>
# 
############################################################
package plugin::editlog::Actives;
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
# 最近のアクセス回数をリスト表示
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $max  = shift;
	my $days = shift;
	my %count;
	my $cgi  = $wiki->get_CGI;
	
	return "更新履歴はありません。" if $wiki->config('log_dir') eq "";
	return "更新履歴はありません。" if ! -e $wiki->config('log_dir')."/useredit.log";
	
	my $oldest = 0;
	if(! $days) {
		$days = 30;
	}
	$oldest = time() - $days * 24 * 3600;
	
	open(DATA,$wiki->config('log_dir')."/useredit.log") or die $!;
	while(<DATA>){
		my($date, $time, $unixtime, $action, $subject, $id) = split(" ",$_);
		if ($unixtime > $oldest){
			$count{$id}++;
		}
	}
	close(DATA);
	
	my $content = "";
	my @members = reverse sort {$count{$a} <=> $count{$b}} keys(%count);
	if($max && $#members>$max-1){
		@members = @members[0..$max-1];
	}
	
	if($#members==-1){
		return "更新履歴はありません。";
	}
	
	foreach my $key(@members){
		if($key eq ""){
			$content .= "*未ログイン($count{$key})\n";
		} else {
			$content .= "*$key($count{$key})\n";
		}
	}
	
	return $content;
}

1;
