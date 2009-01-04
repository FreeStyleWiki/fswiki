############################################################
# 
# <p>最近更新されたページを一覧表示します。</p>
# <p>引数で表示件数を指定できます。</p>
# <pre>
# {{recent 5}}
# </pre>
# <p>縦に表示することもできます。</p>
# <pre>
# {{recent 5,v}}
# </pre>
# <p>日付ごとに一覧表示するにはrecentdaysプラグインを使用します。</p>
# 
############################################################
package plugin::recent::Recent;
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
	my $way    = shift;
	my $cgi    = $wiki->get_CGI;
	
	# 表示方式を決定
	if($way eq ""){
		$way = "H";
	}
	
	if($max eq "V" || $max eq "v"){
		$way = "V";
		$max = 0;
		
	} elsif($max eq "H" || $max eq "h"){
		$way = "H";
		$max = 0;
		
	} elsif($max eq ""){
		$max = 0;
	}
	
	# 表示内容を作成
	my $content = "";
	my $count   = 0;
	foreach my $page ($wiki->get_page_list({-sort   =>'last_modified',
	                                        -permit =>'show',
	                                        -max    =>$max})){
		
		if($way eq "H" || $way eq "h"){
			if($count!=0){
				$content = $content." / ";
			}
		} else {
			$content = $content."*";
		}
		
		$content = $content."[[$page]]";
		
		if($way ne "H" && $way ne "h"){
			$content .= "\n";
		}
		
		$count++;
	}
	
	return $content;
}

1;
