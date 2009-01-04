############################################################
#
# ログイン状態を表示するinlineプラグイン
#
############################################################
package plugin::loginstate::Install;
#use strict;

sub install {
	my $wiki = shift;
	$wiki->add_inline_plugin("loginstate","plugin::loginstate::LoginState",'WIKI');
	$wiki->add_inline_plugin("loginname","plugin::loginstate::LoginName",'WIKI');
}

1;
__END__

# Original source
# Copyright YAMASHINA Hio
