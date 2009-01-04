############################################################
#
# ページが削除されたときのフック
#
############################################################
package plugin::attach::AttachDelete;
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
# ページ削除時に呼び出されるフック関数
#===========================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	my $pagename = $cgi->param("page");
	my $encode_page = &Util::url_encode($pagename);
	
	opendir(DIR,$wiki->config('attach_dir')) or die $!;
	while(my $entry = readdir(DIR)){
		if(index($entry,$encode_page.".")==0){
			unlink($wiki->config('attach_dir')."/$entry");
		}
	}
	closedir(DIR);
}

1;
