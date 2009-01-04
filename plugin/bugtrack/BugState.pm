#########################################################################
#
# <p>BugTrackの状態変更用プラグインです。</p>
# <p>
#   状態を変更する為のフォームを表示します。
# </p>
# <pre>
# {{bugstate 対象のページ(省略時は表示しているページ)}}
# </pre>
# <p>
#   フォームから状態を変更すると対象のページの以下の部分を
#   書き変えてもともと表示していたページを表示します。
# </p>
# <pre>
# *状態： ...
# </pre>
# 
#########################################################################
package plugin::bugtrack::BugState;
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
# パラグラフ
#========================================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $cgi    = $wiki->get_CGI;
	my $source = shift;
	my $page   = $cgi->param("page");

	if($source eq ""){
		$source = $page;
	}

	return make_form($wiki,$page,$source);
}
#======================================================================
# BugListでも使うので関数に
#======================================================================
sub make_form {
    my $wiki = shift;
    my $page = shift;
    my $source = shift;

    my $content = $wiki->get_page($source);
    $content =~ /\n\*状態：\s+(.*)/;
    my $state = $1;

    $page   = &Util::escapeHTML($page);
    $source = &Util::escapeHTML($source);

    my $buf = "<form action=\"".$wiki->create_url()."\" method=\"post\">\n".
              "  <input id=\"state_1\" name=\"state\" type=\"radio\" value=\"提案\"><label for=\"state_1\">提案</label>\n".
              "  <input id=\"state_2\" name=\"state\" type=\"radio\" value=\"着手\"><label for=\"state_2\">着手</label>\n".
              "  <input id=\"state_3\" name=\"state\" type=\"radio\" value=\"完了\"><label for=\"state_3\">完了</label>\n".
              "  <input id=\"state_4\" name=\"state\" type=\"radio\" value=\"リリース済\"><label for=\"state_4\">リリース済</label>\n".
              "  <input id=\"state_5\" name=\"state\" type=\"radio\" value=\"保留\"><label for=\"state_5\">保留</label>\n".
              "  <input id=\"state_6\" name=\"state\" type=\"radio\" value=\"却下\"><label for=\"state_6\">却下</label>\n".
              "  <input name=\"page\" type=\"hidden\" value=\"$page\">\n".
              "  <input name=\"source\" type=\"hidden\" value=\"$source\">\n".
              "  <input name=\"action\" type=\"hidden\" value=\"BUG_STATE\">\n".
              "  <input type=\"submit\" value=\"変更\">\n".
              "</form>";

    $buf =~ s/"$state"/$& checked="checked"/;
    return $buf;
}

1;
