############################################################
#
# 更新日時順にページを一覧表示するためのインラインプラグインを提供します。
#
############################################################
package plugin::recent::Install;
use strict;

sub install {
	my $wiki = shift;
	$wiki->add_paragraph_plugin("recent"    ,"plugin::recent::Recent"    ,"WIKI");
	$wiki->add_paragraph_plugin("recentdays","plugin::recent::RecentDays","WIKI");
}

1;
