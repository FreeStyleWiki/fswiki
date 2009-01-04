#############################################################################
#
# <p>このWikiの子Wikiを一覧で表示します。</p>
# <pre>
# {{wiki_list}}
# </pre>
#
#############################################################################
package plugin::core::WikiList;
use strict;
#===========================================================================
# コンストラクタ
#===========================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================================
# パラグラフメソッド
#===========================================================================
sub paragraph {
	my $self = shift;
	my $farm = shift;
	
	my $can_remove = 1;
	my $login  = $farm->get_login_info();
	my $config = &Util::load_config_hash($farm,$farm->config('farmconf_file'));
	if($config->{remove}==1){
		if(!defined($login)){ $can_remove = 0; }
	} elsif($config->{remove}==2){
		if(!defined($login) || $login->{type}!=0){ $can_remove = 0; }
	}
	
	my @list = $farm->get_wiki_list();
	my $buf = $self->make_tree($farm,\@list,'',$can_remove,$config);
	return $buf;
}

#===========================================================================
# ツリーを生成
#===========================================================================
sub make_tree {
	my $self       = shift;
	my $farm       = shift;
	my $list       = shift;
	my $path       = shift;
	my $can_remove = shift;
	my $config     = shift;
	my $parent     = "";
	
	my $buf = "\n<ul>\n";
	my $appended = 0;
	
	foreach my $item (@$list){
		if(ref($item) eq "ARRAY"){
			$buf .= $self->make_tree($farm,$item,"$path/$parent",$can_remove,$config);
			$buf .= "</li>\n";
		} else {
			if($config->{'hide_template'}==1 && $item eq "template"){
				next;
			}
			$buf .= "</li>\n" unless($buf =~ /<(\/li|ul)>$/);
			$buf .= "<li><a href=\"".$farm->config('script_name')."$path/$item\">$item</a>";
			if($can_remove){
				$buf .= " [<a href=\"".$farm->create_url({ action=>"REMOVE_WIKI",path=>"$path/$item" })."\">削除</a>]";
			}
			$parent = $item;
			$appended++;
		}
	}
	return "" if $appended == 0;
	
	$buf .= "</li>\n" unless($buf =~ /<\/li>$/);
	return $buf."</ul>\n";
}

1;
