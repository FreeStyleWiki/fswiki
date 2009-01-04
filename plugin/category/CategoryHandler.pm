###############################################################################
#
# Categoryプラグインのアクションハンドラ
#
###############################################################################
package plugin::category::CategoryHandler;
use strict;
use plugin::category::CategoryCache;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# アクションハンドラメソッド
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	my $category  = $cgi->param("category");
	my $cachefile = $wiki->config('log_dir')."/category.cache";
	
	if(!(-e $cachefile)){
		&plugin::category::CategoryCache::create_cache($wiki);
	}
	my $result = &Util::load_config_hash(undef,$cachefile);
	
	if($category eq ""){
		$wiki->set_title("カテゴリの一覧");
		my $buf = "";
		foreach my $key (sort(keys(%$result))){
			$buf .= "<h2>".&Util::escapeHTML($key)."</h2>\n<ul>\n";
			my @pages = sort(split(/\t/,$result->{$key}));
			foreach my $pagename (@pages){
				if($wiki->can_show($pagename)){
					$buf .= "<li><a href=\"".$wiki->create_page_url($pagename)."\">".
					        &Util::escapeHTML($pagename)."</a></li>\n";
				}
			}
			$buf .= "</ul>\n";
		}
		return $buf;
		
	} else {
		$wiki->set_title("カテゴリ:".$category);
		my $buf = "<h2>".&Util::escapeHTML($category)."</h2>\n<ul>\n";
		foreach my $pagename (sort(split(/\t/,$result->{$category}))){
			if($wiki->can_show($pagename)){
				$buf .= "<li><a href=\"".$wiki->create_page_url($pagename)."\">".
			            &Util::escapeHTML($pagename)."</a></li>\n";
			}
		}
		return $buf."</ul>\n";
	}
}

1;
