package plugin::amazon::Amazon;
###############################################################################
#
# <p>指定した書籍の書影をamazonから取得して表示し、amazonの書評ページへリンクをはります。</p>
# <pre>
#   {{amazon aid}}
# </pre>
# <p>
#   setup.dat に amazon_aid という定数を設定すると amazon のアソシエトID つきでリンクがはられます。
# </p>
# <p>
#   イメージが存在しないかどうか確認するためにamazonのサーバに接続しているので、
#   プロキシ経由で外に出る必要がある場合は、プロキシの設定情報をsetup.datに設定しておく必要があります。
# </p>
#
###############################################################################
use LWP::UserAgent;
#use HTTP::Response;
#use HTTP::Request;

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}
#==============================================================================
# パラグラフメソッド
#==============================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $item = shift;
	$item = Util::escapeHTML($item);
	my $noimg = 'http://images-jp.amazon.com/images/G/09/icons/books/comingsoon_books.gif';
	my $aid = $wiki->config('amazon_aid');
	my $link = 'http://www.amazon.co.jp/exec/obidos/ASIN/' .  $item;
	$link .= '/' . $aid if $aid;
	my $image;
	if($item =~ /^4/){
		$image = "http://images-jp.amazon.com/images/P/$item.09.MZZZZZZZ.jpg";
	} else {
		$image = "http://images-jp.amazon.com/images/P/$item.01.MZZZZZZZ.jpg";
	}
	
	my $response = &Util::get_response($wiki,$image);
	$image = $noimg if (length($response) < 1024);
	
	my $buf = "<div class=\"amazon\"><a href='$link'><img src='$image'></a></div>";
	return $buf;
}

1;
