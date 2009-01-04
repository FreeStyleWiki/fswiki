################################################################################
#
# バグトラック機能を実現するプラグインを提供します。
#
################################################################################
package plugin::bugtrack::Install;
use strict;
sub install {
	my $wiki = shift;
	$wiki->add_paragraph_plugin("bugtrack","plugin::bugtrack::BugTrack","HTML");
	$wiki->add_paragraph_plugin("buglist","plugin::bugtrack::BugList","HTML");
	$wiki->add_handler("BUG_POST","plugin::bugtrack::BugTrackHandler");
	$wiki->add_paragraph_plugin("bugstate","plugin::bugtrack::BugState","HTML");
	$wiki->add_handler("BUG_STATE","plugin::bugtrack::BugStateHandler");
}

1;
