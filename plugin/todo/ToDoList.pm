##############################################################
#
# <p>ToDoリストを表示します。</p>
# <p>
#   まず適当なページにToDoを記述します。ToDoの記述は以下のような感じです。
# </p>
# <pre>
# * 22(優先度) トイレットペーパーを買う(行動)
# </pre>
# <p>
#   優先度と行動の間は空白を一つ以上空けてください。
#   プラグインの使い方は以下のようになります。
# </p>
# <pre>
# {{todolist ToDo(ToDoを記述したページ),5(表示する件数、省略可)}}
# </pre>
# <p>
#   優先度の高い順に上から表示されます。
#   alwaysオプションをつけるとチェックボックスと完了ボタンが表示され、
#   ToDoが完了したらチェックボックスにチェックを入れて「完了」を押すと
#   ToDoを記述したページでは
# </p>
# <pre>
# * 済 22 トイレットペーパーを買う
# </pre>
# <p>
#   のように変更されtodolistから外されます。
#   なお、alwaysオプションをつけていない場合でも、
#   管理者としてログインすれば同様のフォームが表示されます。
# </p>
#
##############################################################
package plugin::todo::ToDoList;
use strict;
#=============================================================
# コンストラクタ
#=============================================================
sub new{
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#=============================================================
# パラグラフメソッド
#=============================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $source = shift;
	my $count  = shift;
	my $option = shift;
	if($count eq "always"){
		$option = "always";
	}
	my $cgi = $wiki->get_CGI;
	my $page = $cgi->param("page");
	my $buf = "";
	my @todolist=();
	
	if($source eq ""){
		return &Util::paragraph_error("ページを指定してください。");
	}
	unless($wiki->page_exists($source)){
		return &Util::paragraph_error("$sourceが存在しません。");
	}
	unless($wiki->can_show($source)){
		return &Util::paragraph_error("ページの参照権がありません。");
	}
	
	my $content = $wiki->get_page($source);
	my @lines = split(/\n/,$content);
	
	# 書式からtodoを抽出
	foreach(@lines){
		if($_ =~ /^\*\s*(\d+)\s+(.*)/){
			my $priority = $1;
			my $dothing  = $2;
			my $todo = {priority => $priority,dothing => $dothing};
			push(@todolist,$todo);
		}
	}
	
	# 優先順位でソート
	@todolist = sort {
		return $b->{priority} <=> $a->{priority};
	} @todolist;
	
	# リスト表示 + 完了フォーム
	my $login = $wiki->get_login_info();
	if($option eq "always" || defined($login)){
		$buf .= "<div class=\"todo\">"
		    ."<form action=\"".$wiki->create_url()."\" method=\"POST\">\n"
		    ."<input type=\"hidden\" name=\"source\" value=\"".Util::escapeHTML($source)."\">\n"
		    ."<input type=\"hidden\" name=\"page\" value=\"".Util::escapeHTML($page)."\">\n"
		    ."<input type=\"hidden\" name=\"action\" value=\"FINISH_TODO\">";
	}
	$buf .= "<ol>\n";
	my $i=0;
	foreach (@todolist){
		my $priority = $_->{priority};
		my $dothing  = $_->{dothing};
		my $value    = Util::escapeHTML($dothing);
		my $content  = $wiki->process_wiki($dothing);
		$content =~ s/<\/?p>//g;
		$buf .= "<li value=\"$priority\">";
		if($option eq "always" || defined($login)){
			$buf .= "<input name=\"todo.$i\" type=\"checkbox\" value=\"$value\">"
			        .$content."</input></li>\n";
		} else {
			$buf .= $content."</li>\n";
		}
		$i++;
		last if($i==$count);
	}
	
	$buf .= "</ol>";
	if($option eq "always" || defined($login)){
		$buf .= "<input type=\"submit\" value=\"完了\"></form></div>";
	}
	return $buf;
}

1;
