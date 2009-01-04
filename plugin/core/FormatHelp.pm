###############################################################################
#
# <p>FSWiki以外の文法で編集を行う場合に各フォーマット用のHelpページを表示するためのプラグインです。</p>
#
###############################################################################
package plugin::core::FormatHelp;
use strict;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
}
#==============================================================================
# 編集フォーマットに応じたヘルプを出力します。
#==============================================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $cgi    = $wiki->get_CGI();
	my $format = $wiki->get_edit_format();

	# Farmの場合の階層を取得
	my $page  = "Help/$format";
	my $depth = split(/\//,$cgi->path_info());
	if($depth!=0){
		$page = ":$page";
		for(my $i=0;$i<$depth-1;$i++){
			if($i!=0){
				$page = "/$page";
			}
			$page = "..$page";
		}
	}

	# include同様の裏技で処理
	my $source = $wiki->get_page($page);
	if($source eq ""){
		return &Util::paragraph_error("ページが存在しません。","WIKI");
	} else {
		my $pagetmp = $cgi->param("page");
		$cgi->param("page",$page);
		$wiki->get_current_parser()->parse($source);
		$cgi->param("page",$pagetmp);
		return undef;
	}
}

1;
