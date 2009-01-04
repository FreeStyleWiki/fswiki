###############################################################################
#
# FSWiki以外のWikiの文法で編集を行うためのプラグインです。
#
###############################################################################
package plugin::format::Install;
use strict;
#==============================================================================
# formatプラグインをインストールします。
#==============================================================================
sub install {
	my $wiki = shift;
	
	# フォーマットセレクタを設定
	$wiki->add_paragraph_plugin("select_format","plugin::format::FormatSelector");
	$wiki->add_handler("CHANGE_FORMAT","plugin::format::FormatSelector");
	
	# フォーマットプラグインを設定

	# 自動設定の実験……あとで削除します
	#my $dir = $wiki->config('plugin_dir') . '/plugin/format';
	#opendir(DIR, $dir) or return;
	#while(my $file = readdir(DIR)){
	#	if(-f "$dir/$file" and $file =~ /Format\.pm$/){
	#		my ($name) = $file =~ /(.+)Format/;
	#		$file =~ s/\.pm$//;
	#		$wiki->add_format_plugin($name, 'plugin::format::' . $file);
	#	}
	#}

	$wiki->add_format_plugin("FSWiki"  ,"plugin::format::FSWikiFormat");
	$wiki->add_format_plugin("YukiWiki","plugin::format::YukiWikiFormat");
	$wiki->add_format_plugin("Hiki"    ,"plugin::format::HikiFormat");
	$wiki->add_format_plugin("WalWiki" ,"plugin::format::WalWikiFormat");

}

1;
