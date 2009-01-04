############################################################
#
# ページの名称を変更します。
#
############################################################
package plugin::rename::Install;
use strict;

sub install {
	my $wiki = shift;
	$wiki->add_editform_plugin("plugin::rename::RenameForm",10);
	$wiki->add_handler("RENAME","plugin::rename::RenameHandler");
}

1;
