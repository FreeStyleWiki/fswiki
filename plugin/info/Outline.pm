############################################################
#
# <p>ページのアウトラインを表示します。</p>
# <pre>
# {{outline}}
# </pre>
# <p>
# デフォルトでは表示中のページのアウトラインを表示しますが、
# 指定したページのアウトラインを表示する事も出来ます。
# </p>
# <pre>
# {{outline ページ名}}
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
	my $page = shift;
	my $cgi  = $wiki->get_CGI;
	my $p_cnt = 0;
	
	my $pagename = $page;
	if (!defined($pagename)) {
		$pagename = $cgi->param("page");
	}
	# ページの参照権限があるかどうか調べる
	unless($wiki->can_show($pagename)){
		return undef;
	}
	my $parser = plugin::info::OutlineParser->new($wiki);
	return $parser->outline($wiki->get_page($pagename), $pagename);
}

1;
