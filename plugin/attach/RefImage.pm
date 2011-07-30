############################################################
#
# <p>添付した画像ファイルを表示します。</p>
# <pre>
# {{ref_image ファイル名}}
# </pre>
# <p>
# オプションで画像のサイズを指定することができます。
# 以下の例では幅650ピクセル、高さ400ピクセルで画像を表示します。
# </p>
# <pre>
# {{ref_image ファイル名,w650,h400}}
# </pre>
# <p>別のページに添付されたファイルを参照することもできます。</p>
# <pre>
# {{ref_image ファイル名,ページ名}}
# </pre>
#
############################################################
package plugin::attach::RefImage;
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
# パラグラフメソッド
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $file = shift;
	my $page = "";
	
	my @options = @_;
	my $width  = "";
	my $height = "";
	
	if($file eq ""){
		return &Util::paragraph_error("ファイルが指定されていません。","WIKI");
	}
	foreach my $option (@options){
		if($option =~ /^w([0-9]+)$/){
			$width = $1;
		} elsif($option =~ /^h([0-9]+)$/){
			$height = $1;
		} else {
			$page = $option;
		}
	}
	if($page eq ""){
		$page = $wiki->get_CGI()->param("page");
	}
	unless($wiki->can_show($page)){
		return &Util::paragraph_error("ページの参照権限がありません。","WIKI");
	}
	
	my $filename = $wiki->config('attach_dir')."/".&Util::url_encode($page).".".&Util::url_encode($file);
	unless(-e $filename){
		return &Util::paragraph_error("ファイルが存在しません。","WIKI");
	}
	
	$wiki->get_current_parser()->l_image($page, $file, $width, $height);
	return undef;
}

1;