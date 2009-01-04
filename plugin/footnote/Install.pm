########################################################################
#
# 脚注を書く為のプラグインです。
#
########################################################################
package plugin::footnote::Install;
use strict;
#=======================================================================
# インストールスクリプト
#=======================================================================
sub install{
    my $wiki = shift;
    $wiki->add_inline_plugin("fn","plugin::footnote::Footnote","HTML");
    $wiki->add_paragraph_plugin("footnote_list","plugin::footnote::FootnoteList","HTML");
    $wiki->add_hook("footnote","plugin::footnote::FootnoteList");
}
1;
