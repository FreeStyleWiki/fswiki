###############################################################################
#
# <p>RSS-JP.NETを利用してRSSを埋め込みます。</p>
# <pre>
# {{rss2 URL,表示行数}}
# </pre>
#
###############################################################################
package plugin::rss::RSS2;

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
}

#==============================================================================
# パラグラフメソッド
#==============================================================================
sub paragraph {
	my $self  = shift;
	my $wiki  = shift;
	my $url   = shift;
	my $count = shift;
	my $buf = "";
	
	$buf .= "<script type=\"text/javascript\" src=\"http://rss-jp.net/x/read_rss.cgi?url=$url&style=js&encode=euc&num=$count\"></script>";
	return $buf;
}

1;

