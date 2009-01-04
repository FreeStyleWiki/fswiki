############################################################
#
# Wikiページを掲示板として使用するためのプラグインを提供します。
#
############################################################
package plugin::bbs::Install;
use strict;
sub install {
	my $wiki = shift;
	
	$wiki->add_handler("BBS","plugin::bbs::BBSHandler");
	$wiki->add_paragraph_plugin("bbs","plugin::bbs::BBS","HTML");
	
	$wiki->add_handler("BBS2","plugin::bbs::BBS2Handler");
	$wiki->add_paragraph_plugin("bbs2"    ,"plugin::bbs::BBS2"    ,"HTML");
	$wiki->add_paragraph_plugin("bbs2list","plugin::bbs::BBS2List","WIKI");
}

1;
