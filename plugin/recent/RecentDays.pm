############################################################
# 
# <p>最近更新されたページを日付ごとに一覧表示します。</p>
# <p>引数で表示日数を指定します。</p>
# <pre>
# {{recentdays 10}}
# </pre>
# <p>引数を省略した場合は5日分を出力します。</p>
# 
############################################################
package plugin::recent::RecentDays;
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
	my $self   = shift;
	my $wiki   = shift;
	my $max    = shift;
	my $cgi    = $wiki->get_CGI;
	
	# 表示形式を決定
	if($max eq ""){
		$max = 5;
	}
	
	# 表示内容を作成
	my $content = "";
	my $count   = 0;
	
	my $l_year = 0;
	my $l_mon  = 0;
	my $l_day  = 0;
	
	foreach my $page ($wiki->get_page_list({-sort=>'last_modified',-permit=>'show'})){
		
		my $modtime = $wiki->get_last_modified2($page);
		my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime($modtime);
		$year += 1900;
		$mon  += 1;
		if($l_year!=$year || $l_mon!=$mon || $l_day!=$mday){
			if($count==$max){
			    last;
			}
			$content .= "'''$year/$mon/$mday'''\n";
			$l_year = $year;
			$l_mon  = $mon;
			$l_day  = $mday;
			$count++;
		}
		$content .= "*[[$page]]\n";
	}
	
	return $content;
}

1;
