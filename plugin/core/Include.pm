###############################################################################
#
# <p>指定したページ、もしくは指定ページの指定パラグラフをインクルードします。</p>
# <p>
#   ページ全体をインクルードする場合は引数にページ名を指定します。
# </p>
# <pre>
# {{include ページ名}}
# </pre>
# <p>
#   指定ページの特定のパラグラフをインクルードする場合は
#   ページ名に続けて第２引数にパラグラフ名を指定します。
# </p>
# <pre>
# {{include ページ名,パラグラフ名}}
# </pre>
#
###############################################################################
package plugin::core::Include;
use strict;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# パラグラフ関数
#==============================================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $page   = shift;
	my $para   = shift;
	my $cgi    = $wiki->get_CGI;
	
	# エラーチェック
	if($self->{count}++ > 50){
		return &Util::paragraph_error("includeプラグインが多すぎます。","WIKI");
	}
	if($page eq ""){
		return &Util::paragraph_error("ページが指定されていません。","WIKI");
	}
	if(!$wiki->page_exists($page)){
		return &Util::paragraph_error("ページが存在しません。","WIKI");
	}
	if(!$wiki->can_show($page)){
		return &Util::paragraph_error("ページの参照権限がありません。","WIKI");
	}
	if($page eq $cgi->param("page")){
		return &Util::paragraph_error("同一のページはincludeできません。","WIKI");
	}
	foreach my $incpage (@{$self->{stack}}){
		if($incpage eq $page){
			return &Util::paragraph_error("同一のページはincludeできません。","WIKI");
		}
	}
	
	# ソースを取得
	my $source = $wiki->get_page($page);
	
	# パラグラフが指定されていた場合はパラグラフを切り出す
	$para = quotemeta(Util::trim($para));
	if($para ne ""){
		if($source =~ /(\n|^)!!!\s*$para\s*(\n!!!|$)/){
			return &Util::paragraph_error("パラグラフの本文が存在しません。","WIKI");
		} elsif($source =~ /(\n|^)!!!\s*$para\s*\n((.|\s|\r|\n)*?)\s*(\n!!!|$)/){
			$source = $2;
		} elsif($source =~ /(\n|^)!!\s*$para\s*(\n!!|$)/){
			return &Util::paragraph_error("パラグラフの本文が存在しません。","WIKI");
		} elsif($source =~ /(\n|^)!!\s*$para\s*\n((.|\s|\r|\n)*?)\s*(\n!!|$)/){
			$source = $2;
		} elsif($source =~ /(\n|^)!\s*$para\s*(\n!|$)/){
			return &Util::paragraph_error("パラグラフの本文が存在しません。","WIKI");
		} elsif($source =~ /(\n|^)!\s*$para\s*\n((.|\s|\r|\n)*?)\s*(\n!|$)/){
			$source = $2;
		} else {
			return &Util::paragraph_error("ページが存在しません。","WIKI");
		}
	}
	
	# スタックにつむ（無限ループ防止用）
	push(@{$self->{stack}},$page);
	
	# ちょっと裏技
	my $pagetmp = $cgi->param("page");
	$cgi->param("page",$page);
	$wiki->get_current_parser()->parse($source);
	$cgi->param("page",$pagetmp);
	
	# スタックから削除
	pop(@{$self->{stack}});
	
	return undef;
}

1;
