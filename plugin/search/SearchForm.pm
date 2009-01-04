############################################################
# 
# <p>検索フォームを表示します。</p>
# <pre>
# {{search}}
# </pre>
# <p>サイドバーに表示する場合はvオプションをつけてください。</p>
# <pre>
# {{search v}}
# </pre>
# 
############################################################
package plugin::search::SearchForm;
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
# 検索フォーム
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $way  = shift;
	
	if($way eq ""){
		$way = "h";
	}
	my $buf = "<form method=\"GET\" action=\"".$wiki->create_url()."\">\n".
	          "キーワード <input type=\"TEXT\" name=\"word\" size=\"20\">";
	
	if($way eq "v" || $way eq "V"){
		$buf .= "<br>";
	}
	
	$buf .= "<input type=\"RADIO\" name=\"t\" value=\"and\" id=\"and\" checked><label for=\"and\">AND</label> ".
	        "<input type=\"RADIO\" name=\"t\" value=\"or\" id=\"or\"><label for=\"or\">OR</label> ";
	
	if($way eq "v" || $way eq "V"){
		$buf .= "<br>";
	}
	
	$buf .= "<input type=\"checkbox\" id=\"contents\" name=\"c\" value=\"true\">";
	$buf .= "<label for=\"contents\">ページ内容も含める</label>\n";
	
	$buf .= "<input type=\"SUBMIT\" value=\" 検 索 \">".
	        "<input type=\"HIDDEN\" name=\"action\" value=\"SEARCH\">".
	        "</form>\n";
	
	return $buf;
}

1;
