###############################################################################
# 
# <p>アクセス数の多い順にページ名を一覧表示します。</p>
# <p>引数で表示件数を指定できます。</p>
# <pre>
# {{access 5}}
# </pre>
# <p>サイドバーに入れる場合など、縦に表示することもできます。</p>
# <pre>
# {{access 5,v}}
# </pre>
# 
###############################################################################
package plugin::access::Access;
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
	my $self   = shift;
	my $wiki   = shift;
	my $max    = shift;
	my $way    = shift;
	
	if($way eq ""){
		$way = "H";
	}
	
	if($max eq "V" || $max eq "v"){
		$way = "V";
		$max = "";
	} elsif($max eq "H" || $max eq "h"){
		$way = "H";
		$max = "";
	}
	
	my ($line,%count);
	
	open(LOG,$wiki->config('log_dir')."/".$wiki->config('access_log_file')) or return "";
	while(my $line=<LOG>){
		chomp $line;
		my ($page) = split(/ /,$line);
		$page = Util::url_decode($page);
		$count{$page}++;
	}
	close(LOG);
	
	my @keys;
	foreach(keys(%count)){
		push(@keys,$_);
	}
	@keys = sort {
		my $count1 = $count{$a};
		my $count2 = $count{$b};
		return $count2<=>$count1;
	} @keys;
	
	my $flag = 0;
	my $ret = "";
	
	foreach(@keys){
		if($max ne "" && $flag==$max){
			last;
		}
		if($wiki->page_exists($_) && $wiki->can_show($_)){
			if($way eq "H" || $way eq "h"){
				if($flag!=0){ $ret = $ret." / "; }
			} else {
				$ret = $ret."*";
			}
			$ret = $ret."[[$_]] (".$count{$_}.")";
			$flag++;
			
			if($way ne "H" && $way ne "h"){
				$ret .= "\n";
			}
		}
	}
	return $ret;
}

1;
