############################################################
# 
# <p>ToDoリストに項目を追加するためのフォームを出力します。</p>
# <pre>
# {{todoadd ToDo(ToDoを記述したページ、省略可)}}
# </pre>
# <p>
#   フォームに記入して追加を押すと、ToDoリスト用の項目が追加されます。
#   ページ名を省略した場合は、この行の前に追加します。
#   ページ名を指定した場合は、指定したページの最後に追加します。
# </p>
# 
############################################################
package plugin::todo::ToDoAdd;
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
# ToDoリスト追加フォーム
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $dist = shift;
	my $cgi = $wiki->get_CGI;
	my $page = $cgi->param("page");
	
	if($page eq ""){
		return "";
	}
	
	if($dist eq ""){
		$dist = $page;
	} elsif(not $wiki->page_exists($dist)){
		return &Util::paragraph_error("$distが存在しません。");
	}
	
	return "<form method=\"post\" action=\"".$wiki->create_url()."\">\n".
	       "優先度：<input type=\"text\" name=\"priority\" size=\"3\"> ".
	       "行動：<input type=\"text\" name=\"dothing\" size=\"40\"> ".
	       "<input type=\"submit\" value=\"追加\">\n".
	       "<input type=\"hidden\" name=\"action\" value=\"ADD_TODO\">\n".
	       "<input type=\"hidden\" name=\"page\" value=\"".Util::escapeHTML($page)."\">\n".
	       "<input type=\"hidden\" name=\"dist\" value=\"".Util::escapeHTML($dist)."\">\n".
	       "</form>";
}

1;
