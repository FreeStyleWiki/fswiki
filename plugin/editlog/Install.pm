###############################################################################
#
# ユーザごとに編集回数を記録し、表示するためのプラグインを提供します。
#
###############################################################################
package plugin::editlog::Install;
use strict;

sub install {
	my $wiki = shift;
	
	$wiki->add_hook("save_after","plugin::editlog::EditLog");
	$wiki->add_hook("delete"    ,"plugin::editlog::EditLog");
	$wiki->add_paragraph_plugin("actives" ,"plugin::editlog::Actives" ,"WIKI");
	$wiki->add_paragraph_plugin("lastedit","plugin::editlog::LastEdit","WIKI");
}

1;
