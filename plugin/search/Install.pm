############################################################
#
# Wikiページの検索機能を提供します。
#
############################################################
package plugin::search::Install;
use strict;

sub install {
	my $wiki = shift;
	$wiki->add_menu("検索",$wiki->create_url({action=>"SEARCH"}),200,1);
	$wiki->add_handler("SEARCH","plugin::search::SearchHandler");
	$wiki->add_paragraph_plugin("search","plugin::search::SearchForm","HTML");
}

1;
