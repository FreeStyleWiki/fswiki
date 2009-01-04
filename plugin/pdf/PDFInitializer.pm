############################################################
#
# PDFプラグインの初期化およびWikiFarmによるWiki削除時の
# 処理を行うフックプラグイン
#
############################################################
package plugin::pdf::PDFInitializer;
use strict;
use File::Path;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
}

#===========================================================
# PDFプラグインの初期化
#===========================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $name = shift;
	
	# remove_wikiフック
	if($name eq "remove_wiki"){
		my $path = $wiki->get_CGI()->param("path");
		if(-e $wiki->config('pdf_dir').$path){
			rmtree($wiki->config('pdf_dir').$path) or die $!;
		}
	
	# initializeフック
	} elsif($name eq "initialize") {
		# Farmで動作している場合はグローバル変数を上書き
		my $path_info = $wiki->get_CGI()->path_info();
		$path_info =~ m<^((/[^/]+/)*)/([^/]+)$>;
		if(length($path_info)>0){
			$wiki->config('pdf_dir',$wiki->config('pdf_dir').$path_info);
		}
		
		unless(-e $wiki->config('pdf_dir')){
			mkpath($wiki->config('pdf_dir')) or die $!;
		}
	}
}

1;
