###############################################################################
# 
# <p>アクセス数の多い順にページ名を日毎x件表示します。</p>
# <p>引数で表示件数を指定できます。</p>
# <pre>
# {{accessdays 5(上位x件},5(y日分)}}
# </pre>
# <p>デフォルトは5件,5日です。</p>
# 
###############################################################################
package plugin::access::AccessDays;
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
# パラグラフ関数
#==============================================================================
sub paragraph {
	my $self    = shift;
	my $wiki    = shift;
	my $maxrank = shift;
	my $maxdays = shift;
	my $access  = {};
	my $buf     = "";

	if($maxrank eq ""){
	    $maxrank = 5;
	}

	if($maxdays eq ""){
	    $maxdays = 5;
	}

	open(LOG,$wiki->config('log_dir')."/".$wiki->config('access_log_file')) or return "";

	while(my $line=<LOG>){
		chomp $line;
		my ($page,$date) = split(/ /,$line);
		($date =~ m|\d{4}/\d{2}/\d{2}|o) or next;
		$access->{$date}={} unless defined($access->{$date});
		$page = Util::url_decode($page);
		$access->{$date}->{$page}++;
	}
	close(LOG);
	
	my @days = keys(%{$access});

	@days = sort {
	    return $b cmp $a;
	} @days;
	
	foreach my $day (@days){
		my $tmpday = $day;
		# recentdaysと同じ日付形式に
		$tmpday =~ s/\/0/\//g; 
		$buf .= "'''$tmpday'''\n";
		my @pages = keys(%{$access->{$day}});
		@pages = sort {
			my $count1=$access->{$day}->{$a};
			my $count2=$access->{$day}->{$b};
			return $count2 <=> $count1;
		}@pages;
		
		my $rank = $maxrank;
		foreach my $page (@pages){
			# 削除されたページと参照権限のないページを省く
			next if (!$wiki->page_exists($page) || !$wiki->can_show($page));
			my $pagecount = $access->{$day}->{$page};
			$buf .= "*[[$page]]($pagecount)\n";
			$rank--;
			last unless $rank;
		}
		
		$maxdays--;
		last unless $maxdays;
	}
	
	return $buf;
}

1;
