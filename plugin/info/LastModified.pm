####################################################################
#
# <p>表示中のページの最終更新時間を表示します。</p>
# <p>引数にページ名を渡すこともできます。</p>
# <pre>
# {{lastmodified page(ページ名省略可)}}
# </pre>
#
####################################################################
package plugin::info::LastModified;
use strict;

#==================================================================
# コンストラクタ
#==================================================================
sub new {
    my $class = shift;
    my $self = {};
    return bless $self,$class;
}

#==================================================================
# インラインメソッド
#==================================================================
sub inline {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	my $cgi  = $wiki->get_CGI;
	my $buf  = "";
	
	if(!defined($page) || $page eq ""){
		$page = $cgi->param("page");
	}
	
	if($page ne "" && $wiki->page_exists($page)){
		$buf .= "最終更新時間：".&Util::format_date($wiki->get_last_modified2($page));
	}
	
	return $buf;
}

1;
