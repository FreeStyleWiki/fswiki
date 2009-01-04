###############################################################################
#
# RSS 1.0+Dublin Coreプラグイン
#
###############################################################################
package plugin::rss::RSSMaker10;
use strict;
use Jcode;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# 渡されたページの全イメージから最初の見出しをplain textで返す
#==============================================================================
sub get_headline {
	my ($page_body) = @_;
	
	if ($page_body =~ m/\!{1,3}\s*(.+)/mo) {
		return $1;
	}
	return undef;
}

#==============================================================================
# 渡されたページの全イメージからカテゴリ(複数)をplain textのリストで返す
#==============================================================================
sub get_category {
	my ($wiki,$page_body) = @_;
	my @category;

	while ($page_body =~ m/\{\{(category\s+.+?\}\})/gmo) {
		my $category = $wiki->parse_inline_plugin($1);
		push(@category, @{$category->{args}}[0]);
	}
	return @category;
}

#==============================================================================
# time()の値をW3CDTF形式の日付にして返す
#==============================================================================
sub W3CDTF {
	my ($time, $tz_str) = @_;

#	if ($time !~ m/\d+/o) {return error}
#	if ($tz_str !~ m/[+-]\d\d\:\d\d/o) {return error}
	my ($sec, $min, $hour, $mday, $mon, $year) = (localtime($time))[0..5];
	return sprintf('%04d-%02d-%02dT%02d:%02d:%02d%.6s',
	               $year+1900,$mon+1,$mday,$hour,$min,$sec,$tz_str);
}

#==============================================================================
# 渡された文字列をXMLのエンティティに変換して返す
#==============================================================================
sub escapeXML {
	my ($str) = @_;
	my %table = (
		'&' => '&amp;',
		'<' => '&lt;',
		'>' => '&gt;',
		"'" => '&apos;',
		'"' => '&quot;',
	);
	$str =~ s/([&<>\'\"])/$table{$1}/go;
	return $str;
}

#==============================================================================
# アクションハンドラメソッド
#==============================================================================
sub do_action {
	my ($self, $wiki) = @_;
	my $file = $wiki->config('log_dir')."/rss10.cache";
	
	# キャッシュファイルが存在しない場合は作成
	unless(-e $file){
		&make_rss($wiki,$file);
	}
	
	# RSSをレスポンス
	print "Content-Type: application/xml\n\n";
	open(RSS,$file);
	binmode(RSS);
	while(<RSS>){
		print $_;
	}
	close(RSS);
	
	exit();
}

#==============================================================================
# フックメソッド
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $hook = shift;
	
	if($hook eq "initialize"){
		$wiki->add_head_info("<link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" href=\"".$wiki->create_url({action=>"RSS"})."\">");
	} else {
		&make_rss($wiki,$wiki->config('log_dir')."/rss10.cache");
	}
}

#==============================================================================
# RSSファイルを作成する
#==============================================================================
sub make_rss {
	my $wiki = shift;
	my $file = shift;
	
	# URIを作成
	my $uri = $wiki->config('server_host');
	if($uri eq ""){
		$uri = $wiki->get_CGI()->url(-path_info => 1);
	} else {
		$uri = $uri . $wiki->get_CGI->url(-absolute => 1) . $wiki->get_CGI()->path_info();
	}

	my $items;
	my $links;
	my %ch;
	
	$ch{item_max} = 15;
	$ch{encoding} = 'UTF-8';
	$ch{lang}     = 'ja';
	$ch{TZ}       = '+09:00';
	$ch{title}    = escapeXML($wiki->config('site_title'));
	$ch{link}     = escapeXML($uri . '?action=LIST');
	$ch{desc}     = escapeXML(get_headline($wiki->get_page($wiki->config("frontpage"))));
	$ch{date}     = W3CDTF(time(), $ch{TZ});
	$ch{uri}      = escapeXML($uri);

	# 更新情報を収集
	my @list = $wiki->get_page_list;
	@list = sort {
		my $mod1 = $wiki->get_last_modified2($a);
		my $mod2 = $wiki->get_last_modified2($b);
		return $mod2 <=> $mod1;
	} @list;

	foreach my $page (@list) {
		# 公開されているページのみ
		next if($wiki->get_page_level($page)!=0);
		
		my $page_body = $wiki->get_page($page);
		my @subject = get_category($wiki,$wiki->get_page($page));
		my $subjects;
		my %item;
		$item{title} = escapeXML($page);
		$item{date} = W3CDTF($wiki->get_last_modified2($page), $ch{TZ});
		$item{desc} = escapeXML(get_headline($page_body));
		$item{link} = escapeXML($uri . '?page=' . Util::url_encode($page));

		if (defined($item{desc})) {
			$item{desc} = <<"EOD";
    <description>$item{desc}</description>
EOD
		$links = $links . <<"EOD";
   <rdf:li rdf:resource="$item{link}" />
EOD
		}
		foreach (@subject) {
			$_ = escapeXML($_);
			$subjects = $subjects . <<"EOD";
    <dc:subject>$_</dc:subject>
EOD
		}
		$items = $items . <<"EOD";
   <item rdf:about="$item{link}">
    <title>$item{title}</title>
    <link>$item{link}</link>
$item{desc}
    <dc:date>$item{date}</dc:date>
$subjects
   </item>
EOD
		$ch{item_max}--;
		if($ch{item_max} <= 0){ last; }
	}
	my $xml = <<"EOD";
<?xml version="1.0" encoding="$ch{encoding}" standalone="yes"?>
<rdf:RDF
 xmlns="http://purl.org/rss/1.0/"
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xml:lang="$ch{lang}"
>
<channel rdf:about="$ch{link}">
 <title>$ch{title}</title>
 <link>$uri</link>
 <description>$ch{desc}</description>
 <dc:language>$ch{lang}</dc:language>
 <dc:date>$ch{date}</dc:date>
 <items>
  <rdf:Seq>
$links
  </rdf:Seq>
 </items>
</channel>
$items
</rdf:RDF>
EOD

	# RSSをファイルに書き出す
	open(RSS,">$file") or die "RSSファイルの作成に失敗しました。";
	binmode(RSS);
	print RSS jcode($xml, 'euc')->utf8;
	close(RSS);
}

1;

