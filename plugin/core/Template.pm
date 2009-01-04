############################################################
#
# テンプレートを選択するコンボを表示するプラグイン
#
############################################################
package plugin::core::Template;
#use strict;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# ヘルプを表示します。
#===========================================================
sub editform {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $page = $cgi->param("page");
	
	# 表示するのは新規作成時のみ
	if($wiki->page_exists($page)){
		return "";
	}
	
	my $tmpl = $cgi->param("template");
	my $buf = "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	          "  テンプレート\n".
	          "  <select name=\"template\">\n";
	
	my $count = 0;
	
	foreach($wiki->get_page_list({-permit=>'show'})){
		if(index($_,"Template/")==0){
			$buf .= "    <option value=\"".&Util::escapeHTML($_)."\"";
			if($_ eq $tmpl){ $buf .= " selected"; }
			$buf .= ">".&Util::escapeHTML($_)."</option>\n";
			$count++;
		}
	}
	
	# テンプレートが存在しなかった場合
	if($count==0){
		return "";
	}
	
	$buf .= "  </select>\n".
	        "  <input type=\"submit\" name=\"\" value=\"読込み\">\n".
	        "  <input type=\"hidden\" name=\"action\" value=\"EDIT\">\n".
	        "  <input type=\"hidden\" name=\"page\" value=\"".&Util::escapeHTML($cgi->param("page"))."\">\n".
	        "</form>\n";
	
	return $buf;
}

1;
