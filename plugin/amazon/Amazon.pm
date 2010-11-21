package plugin::amazon::Amazon;
###############################################################################
#
# <p>指定した書籍の書影をamazonから取得して表示し、amazonの書評ページへリンクをはります。</p>
# <pre>
#   {{amazon asin[,comment]}}
# </pre>
# <p>
#   setup.dat に amazon_aid という定数を設定すると amazon のアソシエトID つきでリンクがはられます。
# </p>
# <p>
#   イメージが存在しないかどうか確認するためにamazonのサーバに接続しているので、
#   プロキシ経由で外に出る必要がある場合は、プロキシの設定情報をsetup.datに設定しておく必要があります。
# </p>
# <p>
#   comment 引数があたえられると、書影画像のかわりにその文字列からリンクをはります。
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
# インラインメソッド
#==============================================================================
sub inline {
	my $self    = shift;
	my $wiki    = shift;
	my $item    = shift;
	my $comment = shift;
	
	$item = Util::escapeHTML($item);
	my $buf;
	my $link;
	my $aid = $wiki->config('amazon_aid');

	if(Util::handyphone()){
		if ($aid != '' ){
			$link = 'http://www.amazon.co.jp/gp/aw/rd.html?uid=NULLGWDOCOMO&at='. $aid .'&a='. $item .'&dl=1&url=%2Fgp%2Faw%2Fd.html';
		} else {
			$link = 'http://www.amazon.co.jp/gp/aw/rd.html?uid=NULLGWDOCOMO&a='. $item .'&dl=1&url=%2Fgp%2Faw%2Fd.html';
		}
	} else {
		$link = 'http://www.amazon.co.jp/exec/obidos/ASIN/' .  $item;
		$link .= '/' . $aid . '/ref=nosim' if $aid;
	}

	if($comment eq ""){
		my $noimg = 'http://images-jp.amazon.com/images/G/09/icons/books/comingsoon_books.gif';
		my $image;
		my $response;
		for my $num ( '09','01' ) {
			$image = "http://images-jp.amazon.com/images/P/$item.$num.MZZZZZZZ.jpg";
			$response = &Util::get_response($wiki,$image);
			last unless (length($response) < 1024);
		}
		$image = $noimg if (length($response) < 1024);
		$buf = '<img src="'.$image.'">';
	} else{
		$buf = Util::escapeHTML($comment);
	}
	
	return '<span class="amazonb"><a href="'.$link.'">'.$buf.'</a></span>';
}

1;
