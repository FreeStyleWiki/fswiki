#########################################################################
#
# <p>本日のリンク元を表示します。</p>
# <pre>
# {{todayslink}}
# </pre>
# <p>オプションで表示件数を指定することもできます。</p>
# <pre>
# {{todayslink 10}}
# </pre>
# <p>また、vオプションをつけるとリンク元のURLを表示することもできます。</p>
# <pre>
# {{todayslink 10,v}}
# </pre>
#
#########################################################################
package plugin::info::TodaysLink;
use strict;
#========================================================================
# コンストラクタ
#========================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#========================================================================
# 本日のリンク元を表示します
#========================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $rank = shift;# 上位 $rank 位まで表示
	my $way = shift;
	my $buf = "";
	
	if($way eq ""){
		$way = "H";
	}
	
	if($rank eq "v" ||$rank eq "V"){
		$way = "V";
		$rank = "";
	} elsif($rank eq "H" || $rank eq "h") {
		$way = "H";
		$rank = "";
	}

	# 今日の日付をログと同じフォーマットで
	my $time = time();
	my ($sec,$min,$hour,$mday,$month,$year,$wday) = localtime($time);
	$year += 1900;
	$month += 1;
	my $today =sprintf("%04d/%02d/%02d",$year,$month,$mday);
	
	my $count={};
	#logを走査
	open(LOG,$wiki->config('log_dir')."/".$wiki->config('access_log_file')) or return "";
	while(my $line=<LOG>){
		chomp $line;
		my ($page,$date,$time,$ip,$ref,$ua) = split(/ /,$line);
		if($date =~ /$today/){
		    $count->{$ref}++;
		}
	}
	close(LOG);
	
	my @keys = sort {
		my $count1 = $count->{$a};
		my $count2 = $count->{$b};
		return $count2<=>$count1;
	} keys(%{$count});
	
	if ($way ne "H" && $way ne "h"){
		$buf .= "<ul>\n";
	}else{
		$buf .= "[";
	}
	
	my $url = $wiki->get_CGI->url; #wiki内のページは外す
	$url = substr($url,index($url,":")); #XREAだとinclude://になるので分解
	$url = quotemeta($url);
	my $i=0;
	
	foreach(@keys){
		next if($_ eq "-" ||
			/^(http|https|ftp)$url/ ||
			/^http:\/\/localhost:?/ ||
			/^http:\/\/10\./ ||
			/^http:\/\/192\.168\./ ||
			/^http:\/\/172\.((1[6-9])|(2\d)|(3[01]))\./ ||
			/^http:\/\/127\.0\.0\./  );
		
		my $ref=$_;
		my $refcount=$count->{$ref};
		
		if($way ne "H" && $way ne "h"){
			my $decodeurl = Util::url_decode($ref);
			if($decodeurl =~ /UTF-8/){
				&Jcode::convert(\$decodeurl,"euc","utf8");
			} else {
				&Jcode::convert(\$decodeurl,"euc");
			}
			$buf .= "<li><a href=\"".Util::escapeHTML($ref)."\">".Util::escapeHTML($decodeurl)."</a>($refcount)</li>\n";
		}else{
			$buf .= "|" unless ($i==0);
			$buf .= "<a href=\"$ref\">$refcount</a>";
			$i++;
		}
		$rank--;
		last unless $rank;
	}
	
	if($way ne "H" && $way ne "h"){
		$buf .= "</ul>\n" ;
	}else{
		$buf .="]";
	}
	return $buf;
}
1;
