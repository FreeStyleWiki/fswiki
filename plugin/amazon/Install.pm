############################################################
#
# 指定した書籍の書影をamazonから取得して表示し、amazonの書評ページへリンクをはります。
#
############################################################
package plugin::amazon::Install;

sub install {
	my $wiki = shift;
	$wiki->add_paragraph_plugin("amazon","plugin::amazon::Amazon", "HTML");
}

1;
