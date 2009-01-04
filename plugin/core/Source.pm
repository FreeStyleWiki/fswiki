###############################################################################
# 
# ソースを表示するプラグイン
# 
###############################################################################
package plugin::core::Source;
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
# アクションの実行
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if($pagename eq ""){
		$pagename = $wiki->config("frontpage");
	}
	unless($wiki->can_show($pagename)){
		return $wiki->error("参照権限がありません。");
	}
	my $gen = $cgi->param("generation");
	my $source;
	if($gen eq ''){
		$source = $wiki->get_page($pagename);
	} else {
		$source = $wiki->get_backup($pagename,$gen);
	}
	my $format = $wiki->get_edit_format();
	$source = $wiki->convert_from_fswiki($source,$format);
	
	if(&Util::handyphone()){
		print "Content-Type: text/plain;charset=Shift_JIS\n\n";
		&Jcode::convert(\$source,"sjis");
	} else {
		print "Content-Type: text/plain;charset=EUC-JP\n";
		if($ENV{"HTTP_USER_AGENT"} =~ /MSIE/){
			print Util::make_content_disposition("source.txt", "attachment");
		} else {
			print "\n";
		}
	}
	print $source;
	exit();
}

#==============================================================================
# ページ表示時のフックメソッド
# 「ソース」メニューを有効にします
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if($pagename eq ""){
		$pagename = $wiki->config("frontpage");
	}
	
	$wiki->add_menu("ソース",$wiki->create_url({ action=>"SOURCE",page=>$pagename }));
}

1;
