############################################################
#
# <p>添付した画像ファイルを表示します。</p>
# <pre>
# {{ref_image ファイル名}}
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
	my $page = shift;
	
	if($file eq ""){
		return &Util::paragraph_error("ファイルが指定されていません。","WIKI");
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
	
	$wiki->get_current_parser()->l_image($page,$file);
	return undef;
}

1;