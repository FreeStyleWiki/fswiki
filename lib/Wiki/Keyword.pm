###############################################################################
#
# キーワードパーサ
#
###############################################################################
package Wiki::Keyword;
use strict;

# 1 文字にマッチする正規表現
my $ascii	  = '[\x00-\x7F]';				  # ASCII	  の 1 文字
my $twoBytes   = '[\x8E\xA1-\xFE][\xA1-\xFE]';   # EUC 2 Byte の 1 文字
my $threeBytes = '\x8F[\xA1-\xFE][\xA1-\xFE]';   # EUC 3 Byte の 1 文字
my $AsciiOrEUC = "$ascii|$twoBytes|$threeBytes"; # ASCII/EUC  の 1 文字

my $keyword_cache  = 'keywords.cache';  # 古いキーワードキャッシュファイル
my $keyword_cache2 = 'keywords2.cache'; # 新しいキーワードキャッシュファイル

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class     = shift;
	my $wiki      = shift;
	my $interwiki = shift;
	my $self      = {};
	
	$self->{wiki}      = $wiki;
	$self->{keywords}  = [];
	$self->{interwiki} = $interwiki;
	
	$self = bless($self,$class);
	$self->load_keywords();
	
	return $self;
}

#==============================================================================
# キーワードが含まれるかどうかチェック
#==============================================================================
sub exists_keyword {
	my ($self, $str) = @_;

	my $regexp = $self->{'regexp'};
	return 0 if ($regexp eq q{});

	my $wiki   = $self->{wiki};
	$self->{g_pre} = q{};

	# $regexp は qr/^((?:$AsciiOrEUC)*?)($keywords_regexp)/ に等しい。
	# $str がキーワード正規表現にマッチしたら、
	while ($str =~ /$regexp/) {
		$self->{g_pre} .= $1;
		$self->{g_post} = $';
		my $label = $self->{g_label} = $2;

		# マッチしたキーワードに対応する url やページ名の定義が無ければ、
		if (not exists $self->{'keyword'}->{$label}) {

			# キーワードがページ名で閲覧可能なら、
			if ($wiki->page_exists($label) and $wiki->can_show($label)) {

				# ページ名オートリンク
				$self->{g_url}  = undef;
				$self->{g_page} = $label;
				return 1;
			}

			# キーワードがページ名でないか閲覧不可能なら、
			else {

				# 1 文字進めてキーワードを再検索。
				$label =~ /^($AsciiOrEUC)(.*)$/;
				$self->{g_pre} .= $1;
				$str = $2 . $self->{g_post};
			}
		}
		else {
			my $word = $self->{'keyword'}->{$label};

			# マッチしたキーワードに対応するのが url なら、
			if ($word->{'type'} eq 'u') {

				# url リンク
				$self->{g_url}  = $word->{'value'};
				$self->{g_page} = undef;
			}
			else {

				# wiki ページリンク
				$self->{g_url}  = undef;
				$self->{g_page} = $word->{'value'};
			}
			return 1;
		}
	}
	return 0;
}

#==============================================================================
# キーワードをキャッシュファイルから読み込み
#==============================================================================
sub load_keywords {
	my $self = shift;
	my $wiki = $self->{wiki};

	# 全ページ閲覧不可なら、何もせずに終了。
	my $can_show_max = $wiki->_get_can_show_max();
	return if ($can_show_max < 0);

	my $keyword = $self->{'keyword'} = {};
	my $log_dir = $wiki->config('log_dir');
	my $cachefile = $log_dir . '/' . $keyword_cache2;
	$self->{'regexp_list'} = [];

	READ_CACHE: # キャッシュの有効判定、及び読込み
	while (1) {

		# キャッシュが無ければ読込み処理を抜ける。
		last READ_CACHE if (not -e $cachefile);

		my $cache_time = (stat $cachefile)[9];
		my $pagelistfile = $log_dir . '/' . $Wiki::DefaultStorage::PAGE_LIST_FILE;

		# DefaultStorage のページ名一覧より古ければキャッシュを利用しない。
		last READ_CACHE if ($cache_time < (stat $pagelistfile)[9]);

		my $showlevel_file = $wiki->config('config_dir') . '/showlevel.log';

		# 閲覧権限データより古ければキャッシュを利用しない。
		last READ_CACHE if ($cache_time < (stat $showlevel_file)[9]);

		my $keyword_file = $wiki->config('data_dir') . '/Keyword.wiki';

		# キーワード定義ページより古ければキャッシュを利用しない。
		last READ_CACHE if ($cache_time < (stat $keyword_file)[9]);

		# キーワードキャッシュファイルから読込み。
		my $buf = Util::load_config_text(undef, $cachefile);
		my @list = split /\n/, $buf;
		my ($type, $label, $value);

		# 最初の 3 行：各ユーザ権限毎のキーワード正規表現
		foreach my $level (0 .. 2) {
			my $line = shift @list;
			($type, $label, $value) = split /\t/, $line;

			# ファイル形式が異常なら、読込みを終了。
			if ($type ne 'r' or $label + 0 != $level) {
				$self->{'regexp_list'} = [];
				last READ_CACHE;
			}
			push @{ $self->{'regexp_list'} }, $value;
		}

		# 4 行目以降：キーワードと url または ページ名の対応関係を読み込む。
		foreach my $line (@list) {
			($type, $label, $value) = split /\t/, $line;
			$keyword->{$label} = { 'type'  => $type, 'value' => $value, };
		}
		last READ_CACHE;
	}

	# この時点で、キーワード正規表現が定義されてなければ、
	if (not @{ $self->{'regexp_list'} }) {

		# キーワードデータを生成し、キーワードキャッシュファイルに保存。
		$self->parse();
		$self->save_keywords();
	}

	# 現在のユーザの権限に対応するキーワード正規表現をコンパイル。
	my $regexp = $self->{'regexp_list'}->[$can_show_max];
	$self->{'regexp'} = qr/^((?:$AsciiOrEUC)*?)($regexp)/;
}

#==============================================================================
# キーワードのキャッシュファイルを更新
#==============================================================================
sub save_keywords {
	my $self = shift;

	# FSWiki 標準のキーワードキャッシュもこのタイミングで削除。
	my $log_dir = $self->{wiki}->config('log_dir');
	my $cache   = "$log_dir/$keyword_cache";
	unlink $cache if (-e $cache);

	# 各ユーザ権限毎のキーワード正規表現をバッファに追加。
	my $buf = q{};
	foreach my $level (0 .. 2) {
		$buf .= "r\t$level\t" . $self->{'regexp_list'}->[$level] . "\n";
	}

	# キーワードと url またはページ名の対応関係をバッファに追加。
	my $keyword = $self->{'keyword'};
	my $word;
	foreach my $label (keys %$keyword){
		$word = $keyword->{$label};
		$buf .= $word->{'type'} . "\t$label\t" . $word->{'value'} . "\n";
	}

	# バッファの内容をキャッシュファイルに保存。
	Util::save_config_text(undef, "$log_dir/$keyword_cache2", $buf);
}

#==============================================================================
# パース（コンストラクタから呼ばれます）
#==============================================================================
sub parse {
	my $self = shift;
	my $wiki = $self->{wiki};
	$self->{'keyword'} = {};
	my @keywordlist = ([], [], []);

	require Regexp::Assemble;

	my $ra = Regexp::Assemble->new;

	# ページのオートリンクが有効な場合、ページ名もキーワードに含む。
	if ($wiki->config('auto_keyword_page') == 1) {
		my $no_slash_page = $wiki->config('keyword_slash_page') ne '1';
		my %hash = ();
		my ($page, $pat, $level, $label);

		# ページ名の数字部の \d\d* 化によるパターン共通化の確認
		foreach $page ($wiki->get_page_list()){
			next if ($no_slash_page and index($page, '/') != -1);
			$pat = quotemeta $page;
			$pat =~ s{\d+}{\\d\\d\*}g;	 # ページ名の数字部を \d\d* に置換。
			$hash{$pat}->{'count'}++;	  # $pat に共通化できるページの数
			$hash{$pat}->{'page'} = $page; # ページ名(count = 1 のとき)
		}

		# 共通化できそうな全てのパターンについて、
		foreach $pat (sort keys %hash) {

			# そのパターンに共通化できるページ数が 1 ページのみのとき、
			if ($hash{$pat}->{'count'} == 1) {
				$page = $hash{$pat}->{'page'}; # 元のページ名を取得。
				$level = $wiki->get_page_level($page);

				# ページ閲覧レベル毎のキーワードリストにページ名を追加。
				push @{ $keywordlist[$level] }, $page;
				next;
			}

			# そのパターンに共通化できるページ数が複数ページのとき、
			# 共通化パターンを正規表現に追加。
			# (キーワード先頭・末尾が半角英数なら、単語境界 \b も追加)。
			$pat  = "\\b$pat" if ($pat =~ /^(?:\w|\\d)/);
			$pat .= "\\b"	 if ($pat =~ /(?:\w|\\d\*)$/);
			$ra->add($pat);
		}
	}

	# ページ「Keyword」が存在すれば、その内容を読む。
	if ($wiki->page_exists('Keyword')) {

		# ページ「Keyword」の内容からキーワードデータを作成。
		my $source = $wiki->get_page('Keyword');
		$source =~ s/\r//g;
		my @lines = split /\n/, $source;
		foreach my $line (@lines) {
			if (index($line, '*') == 0) {
				$self->parse_line($line);
			}
		}

		# キーワードデータから、キーワード正規表現を作成。
		my $keyword = $self->{'keyword'};
		my ($level, $page, $word);
		foreach my $label (keys %$keyword) {
			$word = $keyword->{$label};

			# キーワードと対応するのが url なら、
			if ($word->{'type'} eq 'u') {

				# キーワード $label をキーワード正規表現に追加
				# (キーワード先頭・末尾が半角英数なら、単語境界 \b も追加)。
				$label  = quotemeta $label;
				$label  = "\\b$label" if ($label =~ /^\w/);
				$label .= "\\b"	   if ($label =~ /\w$/);
				$ra->add($label);
			}

			# キーワードと対応するのがページ名なら、
			else {
				$page = $word->{'value'};
				$level = $wiki->get_page_level($page);

				# ページ閲覧レベル毎のリストにキーワードを追加。
				push @{ $keywordlist[$level] }, $label;
			}
		}
	}

	$self->{'regexp_list'} = [];
	my $label;

	# ページ閲覧レベル毎のリスト内のキーワードを正規表現に追加。
	foreach my $level (0 .. 2) {
		foreach my $page (@{ $keywordlist[$level] }) {

			# ページ名 $page をキーワード正規表現に追加
			# (キーワード先頭・末尾が半角英数なら、単語境界 \b も追加)。
			$page  = quotemeta $page;
			$page  = "\\b$page" if ($page =~ /^\w/);
			$page .= "\\b"	  if ($page =~ /\w$/);
			$ra->add($page);
		}

		# 完成したキーワード正規表現をリストに保存。
		push @{ $self->{'regexp_list'} }, $ra->clone()->as_string();
	}
}

sub parse_line {
	my $self   = shift;
	my $source = shift;

	return if (not defined $source);

	# $source が空になるまで繰り返す。
	while ($source ne q{}) {

		# キーワードを定義する書式がなければ終了。
		return if (not $source =~ /^[^\[]*(\[.+)$/);

		$source = $1;

		# 別名リンク
		if ($source =~ /^\[([^\[]+?)\|((?:https?|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*)\]/
		 || $source =~ /^\[([^\[]+?)\|(file:[^\[\]]*)\]/
		 || $source =~ /^\[([^\[]+?)\|((?:\/|\.\/|\.\.\/)+[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*)\]/ ) {
			my $label = $1;
			my $url   = $2;
			$source = $';
			$self->url_anchor($url, $label);
		}

		# InterWiki
		elsif ($self->{interwiki}->exists_interwiki($source)) {
			my $label = $self->{interwiki}->{g_label};
			my $url   = $self->{interwiki}->{g_url};
			$source = $self->{interwiki}->{g_post};
			$self->url_anchor($url, $label);
		}

		# ページ別名リンク
		elsif ($source =~ /^\[\[([^\[]+?)\|(.+?)\]\]/) {
			my $label = $1;
			my $page  = $2;
			$source = $';
			$self->wiki_anchor($page, $label);
		}

		# 任意のURLリンク
		elsif ($source =~ /^\[([^\[]+?)\|(.+?)\]/) {
			my $label = $1;
			my $url   = $2;
			$source = $';
			$self->url_anchor($url, $label);
		}

		# 以上に macth しなかったなら、1 文字進める。
		else {
			$source =~ s/^.//;
		}
	}
}

#==============================================================================
# URLアンカ
#==============================================================================
sub url_anchor {
	my ($self, $url, $name) = @_;

	$self->{'keyword'}->{$name} = { 'type' => 'u', 'value' => $url };
}

#==============================================================================
# Wikiアンカ
#==============================================================================
sub wiki_anchor {
	my ($self, $page, $name) = @_;

	$self->{'keyword'}->{$name} = { 'type' => 'w', 'value' => $page };
}

1;
