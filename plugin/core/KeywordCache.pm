###############################################################################
#
# キーワードのキャッシュを作成・更新するためのフック
#
###############################################################################
package plugin::core::KeywordCache;
use strict;
use Wiki::Keyword;
use Wiki::InterWiki;

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
}

#===========================================================
# ページ保存後or削除後のフックメソッド
#===========================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	
	my $interwiki = Wiki::InterWiki->new($wiki);
	my $keyword   = Wiki::Keyword->new($wiki,$interwiki);
	
	$keyword->parse();
	$keyword->save_keywords();
}

1;