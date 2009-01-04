#########################################################################
#
# <p>脚注リストプラグインです。</p>
# <pre>
# {{footnote_list}}
# </pre>
# <p>脚注プラグインで蓄えられた脚注文書をリスト表示します。</p>
#
#########################################################################
package plugin::footnote::FootnoteList;
use strict;
#========================================================================
# コンストラクタ
#========================================================================
sub new {
	my $class = shift;
	my $self = {};
	$self->{notes} = [];

	return bless $self,$class;
}

#========================================================================
# パラグラフメソッド
#========================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $buf  = "";

    if(@{$self->{notes}} > 0 ){
		$buf .= "<ul class=\"fnlist\">";
		while(my $note = shift(@{$self->{notes}})){
			my $index = $note->{id};
			my $text = $note->{text};
			$buf .= "<li>[<a id=\"FN_$index\" name=\"FN_$index\" href=\"#FNR_$index\">$index</a>]".
			        &Util::escapeHTML($text)."</li>";
		}
		$buf .= "</ul>";
	}
	return $buf;
}
#========================================================================
# フック "footnote"から呼ばれます。
#========================================================================
sub hook{
	my $self = shift;
	my $wiki = shift;
	my $name = shift;
	my $note = shift;
	push(@{$self->{notes}},$note);
}
1;
