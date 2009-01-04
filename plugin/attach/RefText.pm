############################################################
#
# <p>添付したテキストファイルを表示します。</p>
# <pre>
# {{ref_text ファイル名}}
# </pre>
# <p>別のページに添付されたファイルを参照することもできます。</p>
# <pre>
# {{ref_text ファイル名,ページ名}}
# </pre>
#
############################################################
package plugin::attach::RefText;
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
	
	open(FILE,$filename) or die $!;
	my $buf = "";
	while(my $line = <FILE>){
		$buf .= " $line";
	}
	close(FILE);
	return Jcode::convert($buf,'euc');
}

1;