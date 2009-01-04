############################################################
#
# 編集画面にヘルプを表示するプラグイン
#
############################################################
package plugin::core::EditHelper;
#use strict;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# ヘルプを表示します。
#===========================================================
sub editform {
	my $self = shift;
	my $wiki = shift;
	if(!Util::handyphone && $wiki->page_exists("EditHelper")){
	    return $wiki->process_wiki($wiki->get_page("EditHelper"));
	} else {
		return "<div>[<a href=\"".$wiki->create_page_url("Help")."\" target=\"_blank\">ヘルプ</a>]</div>";
	}
}

1;
