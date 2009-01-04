###############################################################################
# 
# renameプラグインによって呼び出されるrenameフック。
# 
###############################################################################
package plugin::attach::AttachRename;
use strict;
use File::Copy;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# フックメソッド（ページのリネーム時に添付ファイルをコピーする）
#==============================================================================
sub hook {
	my $self    = shift;
	my $wiki    = shift;
	my $page    = $wiki->get_CGI()->param("page");
	my $newpage = $wiki->get_CGI()->param("newpage");
	my $dir     = $wiki->config('attach_dir');
	
	foreach my $file (glob(sprintf("%s/%s.*",$dir,&Util::url_encode($page)))){
		if($file  =~ /^(.+)\.(.+)$/){
			my $enc_file = $2;
			copy(sprintf("%s/%s.%s",$dir,&Util::url_encode($page)   ,$enc_file),
				 sprintf("%s/%s.%s",$dir,&Util::url_encode($newpage),$enc_file))
			or die &Util::url_decode($enc_file)."のコピーに失敗しました。\n\n$!";
		}
	}
	
}

1;
