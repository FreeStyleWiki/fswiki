############################################################
#
# アクセス数の多い順にページの一覧を表示する
# インラインプラグインを提供します。
#
############################################################
package plugin::access::Install;
use strict;
sub install {
	my $wiki = shift;
	$wiki->add_paragraph_plugin("access"    ,"plugin::access::Access"    ,"WIKI");
	$wiki->add_paragraph_plugin("accessdays","plugin::access::AccessDays","WIKI");
}

1;
