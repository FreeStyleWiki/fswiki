############################################################
#
# attachプラグインの初期化およびWikiFarmによるWiki削除時
# の処理を行うフックプラグイン
#
############################################################
package plugin::attach::AttachInitializer;
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
# attachプラグインの初期化
#===========================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $name = shift;
	
	# remove_wikiフック
	if($name eq "remove_wiki"){
		my $path = $wiki->get_CGI()->param("path");
		if(-e $wiki->config('attach_dir').$path){
			rmtree($wiki->config('attach_dir').$path);
		}
		
	# initializeフック
	} elsif($name eq "initialize"){
		# Farmで動作している場合はグローバル変数を上書き
		my $path_info = $wiki->get_CGI()->path_info();
		if(length($path_info)>0){
			$wiki->config('attach_dir',$wiki->config('attach_dir').$path_info);
		}
		unless(-e $wiki->config('attach_dir')){
			mkpath($wiki->config('attach_dir'));
		}
	}
}

1;
