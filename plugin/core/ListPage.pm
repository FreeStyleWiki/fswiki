############################################################
# 
# ページ一覧を表示するプラグイン
# 
############################################################
package plugin::core::ListPage;
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
# アクションの実行
#===========================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	$self->{once} = $wiki->config('pagelist');
	my $cgi = $wiki->get_CGI;
	
	$wiki->set_title("ページの一覧");
	my @list = $wiki->get_page_list({-sort=>'last_modified',-permit=>'show'});
	
	my $cnt = $cgi->param("cnt");
	if($cnt eq ""){ $cnt = 0; }
	my $row = $cnt * $self->{once};
	
	my $content;
	my $count = 0;
	
	foreach(@list){
		if($self->{once}==0 ||($count>=$row && $count<$row+$self->{once})){
			$content = $content.
				"<li>".
				"<a href=\"".$wiki->create_page_url($_)."\">".Util::escapeHTML($_)."</a>".
				" - ".
				Util::format_date($wiki->get_last_modified2($_)).
				"</li>\n";
		}
		$count++;
	}
	
	$content = "<ul>\n".$content."</ul>\n";
	
	# 次ページ処理用アンカ
	if($self->{once}!=0){
		$content .= "<p>[ ";
		my $pagecnt = 1;
		for(my $i=0;$i<$count;$i=$i+$self->{once}){
			if($cnt==$pagecnt-1){
				$content .= $pagecnt." ";
			} else {
				$content .= "<a href=\"".$wiki->create_url({ action=>"LIST",cnt=>($pagecnt-1)})."\">".$pagecnt."</a> ";
			}
			$pagecnt++;
		}
		$content .= "]</p>\n";
	}
	
	return $content;
}

1;
