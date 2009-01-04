############################################################
#
# <p>ページのアウトラインを表示します。</p>
# <pre>
# {{outline}}
# </pre>
#
############################################################
package plugin::info::Outline;
use strict;
use plugin::info::OutlineParser;

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
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $p_cnt = 0;
	
	my $pagename = $cgi->param("page");
	# ページの参照権限があるかどうか調べる
	unless($wiki->can_show($pagename)){
		return undef;
	}
	my $parser = plugin::info::OutlineParser->new($wiki);
	return $parser->outline($wiki->get_page($pagename));
}

1;
