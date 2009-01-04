##############################################################
#
# PluginHelpのアクションハンドラ。
#
##############################################################
package plugin::info::PluginHelpHandler;
use strict;
#=============================================================
# コンストラクタ
#=============================================================
sub new {
    my $class = shift;
    my $self = {};
    return bless $self,$class;
}

#=============================================================
# アクションハンドラメソッド
#=============================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $name   = $cgi->param("name");
	my $plugin = $cgi->param("plugin");
	my $comment = &get_comment($wiki,$plugin);
	
	$wiki->set_title(&Util::escapeHTML($name)."プラグイン");
	return $comment;
}

#=============================================================
# コメントを取得するメソッド
#=============================================================
sub get_comment {
	my $wiki   = shift;
	my $plugin = shift;
	my $comment = "";
	my $fname = $wiki->config("plugin_dir").'/'.&Util::get_module_file($plugin);
	open(MODULE,$fname) || die "$fnameのオープンに失敗しました。";
	my $comment = "";
	my $flag = 0;
	while(<MODULE>){
		if(!/^#/ || /^##/){
			if($flag==0){ next; } else { last; }
		}
		$flag = 1;
		s/\#+//;
		s/\={2,}//;
		s/^\s+//; s/\s+$//;
		if($_ ne ""){
			$comment .= $_."\n";
		}
	}
	close(MODULE);
	return $comment;
}

1;
