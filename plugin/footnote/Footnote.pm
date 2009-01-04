#========================================================================
#
# <p>脚注プラグインです。</p>
# <p>
#   使い方は以下のように脚注の文章を書きます。
# </p>
# <pre>
# {{fn この文章がfootnote_listで表示されます}}
# </pre>
# <p>
#   このプラグインの表示自体は[1]とかになります。
# </p>
#
#========================================================================
package plugin::footnote::Footnote;
use strict;
#========================================================================
# コンストラクタ
#========================================================================
sub new {
	my $class = shift;
	my $self = {};
	$self->{count} = 1;
	return bless $self,$class;
}

#========================================================================
# インラインメソッド
#========================================================================
sub inline {
	my $self = shift;
	my $wiki = shift;
	my $text = shift;


	my $index = $self->{count};
	my $note = {id => $index,text => $text};
	$wiki->do_hook("footnote",$note);
	$self->{count}++;
	
	return "<sup class=\"fn\">".
	       "[<a id=\"FNR_$index\" name=\"FNR_$index\" href=\"#FN_$index\" title=\"".&Util::escapeHTML($text)."\">".$index."</a>]".
	       "</sup>";
}
1;
