############################################################
#
# Googleの検索ボックスを表示する機能を提供します。
#
############################################################
package plugin::google::Install;
use strict;

sub install {
	my $wiki = shift;
	
	$wiki->add_paragraph_plugin("google","plugin::google::Google","HTML");
}

1;
