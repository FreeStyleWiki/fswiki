############################################################
#
# Wikiページにファイルを添付するためのプラグインを提供します。
#
############################################################
package plugin::attach::Install;
use strict;
sub install {
	my $wiki = shift;
	
	$wiki->add_hook("initialize","plugin::attach::AttachInitializer");
	$wiki->add_hook("remove_wiki","plugin::attach::AttachInitializer");
	$wiki->add_handler("ATTACH","plugin::attach::AttachHandler");
#	$wiki->add_hook("delete","plugin::attach::AttachDelete");
	$wiki->add_hook("rename","plugin::attach::AttachRename");
	
	$wiki->add_inline_plugin("ref","plugin::attach::Ref","HTML");
	$wiki->add_paragraph_plugin("ref_image","plugin::attach::RefImage","WIKI");
	$wiki->add_paragraph_plugin("ref_text" ,"plugin::attach::RefText" ,"WIKI");
	
	$wiki->add_paragraph_plugin("files","plugin::attach::Files","HTML");
	$wiki->add_paragraph_plugin("attach","plugin::attach::Attach","HTML");
	$wiki->add_editform_plugin("plugin::attach::AttachForm",50);
	
	$wiki->add_admin_menu("MIMEタイプ",$wiki->create_url({ action=>"ADMINMIME" }),990,
						  "MIMEタイプの追加、削除を行います。");
	
	$wiki->add_admin_handler("ADMINMIME","plugin::attach::AdminMIMEHandler");
}

1;
