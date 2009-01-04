###############################################################################
#
# ページ削除時に作成済PDFを削除するフックプラグイン
#
###############################################################################
package plugin::pdf::PDFDelete;
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
# フックメソッド
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	my $pagename = $cgi->param("page");
	my $encode_page = &Util::url_encode($pagename);
	
	opendir(DIR,$wiki->config('pdf_dir')) or die $!;
	while(my $entry = readdir(DIR)){
		if(index($entry,$encode_page)==0){
			unlink($wiki->config('pdf_dir')."/$entry");
		}
	}
	closedir(DIR);
}

1;
