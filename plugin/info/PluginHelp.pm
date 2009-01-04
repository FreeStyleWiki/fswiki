##############################################################
#
# <p>プラグインの簡易ヘルプを表示します。</p>
# <pre>
# {{pluginhelp}}
# </pre>
# <p>
#   とするとインストールされているプラグインの一覧と簡単な
#   説明が一覧表示されます。プラグイン名をクリックすると
#   そのプラグインの詳細な説明が表示されます。
# </p>
# <p>
#   また、オプションでプラグイン名を指定すると、
#   そのプラグインのヘルプを表示することができます。
# </p>
# <pre>
# {{pluginhelp プラグイン名,プラグイン名,...}}
# </pre>
#
##############################################################
package plugin::info::PluginHelp;
use strict;
use plugin::info::PluginHelpHandler;
#=============================================================
# コンストラクタ
#=============================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#=============================================================
# パラグラフメソッド
#=============================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my @plugin = @_;
	my $buf    = "";
	
	# 指定したプラグインのみ表示
	if ( scalar(@plugin) > 0 ) {
		$buf .= "<dl>\n";
		for my $p ( @plugin ) {
			$buf .= "<dt>".Util::escapeHTML($p)."</dt>\n";
			if (my $plugin = $wiki->{"plugin"}->{$p}->{CLASS}) {
				my $comment = &plugin::info::PluginHelpHandler::get_comment($wiki,$plugin);
				$buf .= "<dd>$comment</dd>\n";
			} else {
				$buf .= "<dd><font class=\"error\">{{".Util::escapeHTML($p)."}}プラグインは存在しません。</font></dd>\n"
			}
		}
		$buf .= "</dl>\n";
		
	# 全てのプラグインを表示
	} else {
		my @plugins = sort { $a cmp $b } keys(%{$wiki->{"plugin"}});
		
		foreach my $p (@plugins){
			my $name   = $p;
			my $plugin = $wiki->{"plugin"}->{$p}->{CLASS};
			my $comment = &plugin::info::PluginHelpHandler::get_comment($wiki,$plugin);
			my $comment = (split(/\n/,$comment))[0];
			$comment = &Util::delete_tag($comment);
			
			$buf .= "<dl>".
			        "<dt><a href=\"".$wiki->create_url({ action=>"PLUGINHELP", name=>$name, plugin=>$plugin })."\">$name</a></dt>".
			        "<dd>$comment</dd></dl>\n";
		}
	}
	return $buf;
}

1;
