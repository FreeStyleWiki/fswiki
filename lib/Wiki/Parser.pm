################################################################################
# <p>
#   Wikiフォーマットの文字列をパースし、書式に対応したフックメソッドの呼び出しを行います。
#   Wiki::Parserを継承し、これらのフックメソッドをオーバーライドすることで任意のフォーマットへの変換が可能です。
# </p>
################################################################################
package Wiki::Parser;
use strict;
use Wiki::Keyword;
use Wiki::InterWiki;

$Wiki::Parser::keyword   = undef;
$Wiki::Parser::interwiki = undef;

#===============================================================================
# <p>
# コンストラクタ。
# </p>
# <pre>
# my $parser = Wiki::HTMLParser-&gt;new($wiki);
# </pre>
#===============================================================================
sub new {
	my $class = shift;
	my $wiki  = shift;
	
	my $self = {};
	$self->{wiki} = $wiki;
	
	# KeywordとInterWikiは高速化のためモジュール変数として保持する
	#（ただしmod_perl+Farmの場合はダメなので毎回newする）
	if(exists $ENV{MOD_PERL}){
		$self->{interwiki} = Wiki::InterWiki->new($wiki);
		$self->{keyword}   = Wiki::Keyword->new($wiki,$self->{interwiki});
	} else {
		unless(defined($Wiki::Parser::keyword)){
			$Wiki::Parser::interwiki = Wiki::InterWiki->new($wiki);
			$Wiki::Parser::keyword   = Wiki::Keyword->new($wiki,$Wiki::Parser::interwiki);
		}
		$self->{interwiki} = $Wiki::Parser::interwiki;
		$self->{keyword}   = $Wiki::Parser::keyword;
	}
	
	$self->{dl_flag} = 0;
	$self->{dt} = "";
	$self->{dd} = "";
	
	return bless $self,$class;
}

#===============================================================================
# <p>
# パース処理を開始します。
# </p>
# <pre>
# $parser-&gt;parse($source);
# </pre>
#===============================================================================
sub parse {
	my $self   = shift;
	my $source = shift;
	
	$self->start_parse;
	$source =~ s/\r//g;
	
	my @lines = split(/\n/,$source);
	
	foreach my $line (@lines){
		chomp $line;
		
		# 複数行の説明
		$self->multi_explanation($line);
		
		my $word1 = substr($line,0,1);
		my $word2 = substr($line,0,2);
		my $word3 = substr($line,0,3);
		
		# 空行
		if($line eq "" && !$self->{block}){
			$self->l_paragraph();
			next;
		}
		
		# ブロック書式のエスケープ
		if($word2 eq "\\\\" || $word1 eq "\\"){
			my @obj = $self->parse_line(substr($line, 1));
			$self->l_text(\@obj);
			next;
		}
		
		# パラグラフプラグイン
		if($line =~ /^{{(.+}})$/){
			if(!$self->{block}){
				my $plugin = $self->{wiki}->parse_inline_plugin($1);
				my $info   = $self->{wiki}->get_plugin_info($plugin->{command});
				if($info->{TYPE} eq "paragraph"){
					$self->l_plugin($plugin);
				} else {
					my @obj = $self->parse_line($line);
					$self->l_text(\@obj);
				}
				next;
			}
		} elsif($line =~ /^{{(.+)$/){
			if ($self->{block}) {
				my $plugin = $self->{wiki}->parse_inline_plugin($1);
				my $info   = $self->{wiki}->get_plugin_info($plugin->{command});
				$self->{block}->{level}++ if($info->{TYPE} ne "inline");
				$self->{block}->{args}->[0] .= $line."\n";
				next;
			}
			my $plugin = $self->{wiki}->parse_inline_plugin($1);
			my $info   = $self->{wiki}->get_plugin_info($plugin->{command});
			if($info->{TYPE} eq "block"){
				unshift(@{$plugin->{args}}, "");
				$self->{block} = $plugin;
				$self->{block}->{level} = 0;
			} else {
				my @obj = $self->parse_line($line);
				$self->l_text(\@obj);
			}
			next;
		}
		if($self->{block}){
			if($line eq "}}"){
				if ($self->{block}->{level} > 0) {
					$self->{block}->{level}--;
					$self->{block}->{args}->[0] .= $line."\n";
					next;
				}
				my $plugin = $self->{block};
				delete($self->{block});
				$self->l_plugin($plugin);
			} else {
				$self->{block}->{args}->[0] .= $line."\n";
			}
			next;
		}
		
		# PRE
		if($word1 eq " " || $word1 eq "\t"){
			$self->l_verbatim($line);
			
		# 見出し
		} elsif($word3 eq "!!!"){
			my @obj = $self->parse_line(substr($line,3));
			$self->l_headline(1,\@obj);
			
		} elsif($word2 eq "!!"){
			my @obj = $self->parse_line(substr($line,2));
			$self->l_headline(2,\@obj);
			
		} elsif($word1 eq "!"){
			my @obj = $self->parse_line(substr($line,1));
			$self->l_headline(3,\@obj);

		# 項目
		} elsif($word3 eq "***"){
			my @obj = $self->parse_line(substr($line,3));
			$self->l_list(3,\@obj);
			
		} elsif($word2 eq "**"){
			my @obj = $self->parse_line(substr($line,2));
			$self->l_list(2,\@obj);
			
		} elsif($word1 eq "*"){
			my @obj = $self->parse_line(substr($line,1));
			$self->l_list(1,\@obj);
			
		# 番号付き項目
		} elsif($word3 eq "+++"){
			my @obj = $self->parse_line(substr($line,3));
			$self->l_numlist(3,\@obj);
			
		} elsif($word2 eq "++"){
			my @obj = $self->parse_line(substr($line,2));
			$self->l_numlist(2,\@obj);
			
		} elsif($word1 eq "+"){
			my @obj = $self->parse_line(substr($line,1));
			$self->l_numlist(1,\@obj);
			
		# 水平線
		} elsif($line eq "----"){
			$self->l_line();
		
		# 引用
		} elsif($word2 eq '""'){
			my @obj = $self->parse_line(substr($line,2));
			$self->l_quotation(\@obj);
			
		# 説明
		} elsif(index($line,":")==0 && index($line,":",1)!=-1){
			if(index($line,":::")==0){
				$self->{dd} .= substr($line,3);
				next;
			}
			if($self->{dt} ne "" || $self->{dd} ne ""){
				$self->multi_explanation;
			}
			if(index($line,"::")==0){
				$self->{dt} = substr($line,2);
				$self->{dl_flag} = 1;
				next;
			}
			my $dt = substr($line,1,index($line,":",1)-1);
			my $dd = substr($line,index($line,":",1)+1);
			my @obj1 = $self->parse_line($dt);
			my @obj2 = $self->parse_line($dd);
			$self->l_explanation(\@obj1,\@obj2);
			
		# テーブル
		} elsif($word1 eq ","){
			if($line =~ /,$/){
				$line .= " ";
			}
			my @spl = map {/^"(.*)"$/ ? scalar($_ = $1, s/\"\"/\"/g, $_) : $_}
						  ($line =~ /,\s*(\"[^\"]*(?:\"\"[^\"]*)*\"|[^,]*)/g);
			my @array;
			foreach my $value (@spl){
				my @cell = $self->parse_line($value);
				push @array,\@cell;
			}
			$self->l_table(\@array);
			
		# コメント
		} elsif($word2 eq "//"){
		
		# 何もない行
		} else {
			my @obj = $self->parse_line($line);
			$self->l_text(\@obj);
		}
	}
	
	# 複数行の説明
	$self->multi_explanation;
	
	# パース中のブロックプラグインがあった場合、とりあえず評価しておく？
	if($self->{block}){
		$self->l_plugin($self->{block});
		delete($self->{block});
	}
	
	$self->end_parse;
}

#===============================================================================
# <p>
# 複数行の説明文を処理します。
# </p>
#===============================================================================
sub multi_explanation {
	my $self = shift;
	my $line = shift;
	if($self->{dl_flag}==1 && (index($line,":")!=0 || !defined($line))){
		my @obj1 = $self->parse_line($self->{dt});
		my @obj2 = $self->parse_line($self->{dd});
		$self->l_explanation(\@obj1,\@obj2);
		$self->{dl_flag} = 0;
		$self->{dt} = "";
		$self->{dd} = "";
	}
}

#===============================================================================
# <p>
# １行分をパースします。parseメソッドの中から必要に応じて呼び出されます。
# </p>
#===============================================================================
sub parse_line {
	my ($self, $source) = @_;

	return () if (not defined $source);

	my @array = ();
	my $pre   = q{};
	my @parsed = ();

	# $source が空になるまで繰り返す。
	SOURCE:
	while ($source ne q{}) {

		# どのインライン Wiki 書式の先頭にも match しない場合
		if (!($source =~ /^(.*?)((?:{{|\[\[?|https?:|mailto:|f(?:tp:|ile:)|'''?|==|__|<<).*)$/)) {
			# キーワード検索・置換処理のみ実施して終了する
			push @array, $self->_parse_line_keyword($pre . $source);
			return @array;
		}

		$pre   .= $1;	# match しなかった先頭部分は溜めておいて後で処理する
		$source = $2;	# match 部分は後続処理にて詳細チェックを行う
		@parsed = ();

		# プラグイン
		if ($source =~ /^{{/) {
			$source = $';
			my $plugin = $self->{wiki}->parse_inline_plugin($source);
			unless($plugin){
				push @parsed, '{{';
				push @parsed, $self->parse_line($source);
			} else {
				my $info = $self->{wiki}->get_plugin_info($plugin->{command});
				if($info->{TYPE} eq "inline"){
					push @parsed, $self->plugin($plugin);
				} else {
					push @parsed, $self->parse_line("<<".$plugin->{command}."プラグインは存在しません。>>");
				}
				if ($source ne "") {
					$source = $plugin->{post};
				}
			}
		}

		# InterWikiName
		elsif ($self->{interwiki}->exists_interwiki($source)) {
			my $label = $self->{interwiki}->{g_label};
			my $url   = $self->{interwiki}->{g_url};
			$source = $self->{interwiki}->{g_post};
			push @parsed, $self->url_anchor($url, $label);
		}

		# ページ別名リンク
		elsif ($source =~ /^\[\[([^\[]+?)\|([^\|\[]+?)\]\]/) {
			my $label = $1;
			my $page  = $2;
			$source = $';
			push @parsed, $self->wiki_anchor($page, $label);
		}

		# URL別名リンク
		elsif ($source
			=~ /^\[([^\[]+?)\|((?:http|https|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*)\]/
			|| $source =~ /^\[([^\[]+?)\|(file:[^\[\]]*)\]/
			|| $source
			=~ /^\[([^\[]+?)\|((?:\/|\.\/|\.\.\/)+[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*)\]/
			)
		{
			my $label = $1;
			my $url   = $2;
			$source = $';
			if (   index($url, q{"}) >= 0
				|| index($url, '><') >= 0
				|| index($url, 'javascript:') >= 0)
			{
				push @parsed, $self->parse_line('<<不正なリンクです。>>');
			}
			else {
				push @parsed, $self->url_anchor($url, $label);
			}
		}

		# URLリンク
		elsif ($source
			=~ /^(?:https?|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*/
			|| $source =~ /^file:[^\[\]]*/)
		{
			my $url = $&;
			$source = $';
			if (   index($url, q{"}) >= 0
				|| index($url, '><') >= 0
				|| index($url, 'javascript:') >= 0)
			{
				push @parsed, $self->parse_line('<<不正なリンクです。>>');
			}
			else {
				push @parsed, $self->url_anchor($url);
			}
		}

		# ページリンク
		elsif ($source =~ /^\[\[([^\|]+?)\]\]/) {
			my $page = $1;
			$source = $';
			push @parsed, $self->wiki_anchor($page);
		}

		# 任意のURLリンク
		elsif ($source =~ /^\[([^\[]+?)\|(.+?)\]/) {
			my $label = $1;
			my $url   = $2;
			$source = $';
			if (   index($url, q{"}) >= 0
				|| index($url, '><') >= 0
				|| index($url, 'javascript:') >= 0)
			{
				push @parsed, $self->parse_line('<<不正なリンクです。>>');
			}
			else {

				# URIを作成
				my $wiki = $self->{wiki};
				my $uri  = $wiki->config('server_host');
				if ($uri eq q{}) {
					$uri = $wiki->get_CGI()->url(-path_info => 1);
				}
				else {
					$uri
						= $uri
						. $wiki->get_CGI->url(-absolute => 1)
						. $wiki->get_CGI()->path_info();
				}
				push @parsed, $self->url_anchor($uri . '/../' . $url, $label);
			}
		}

		# ボールド、イタリック、取り消し線、下線
		elsif ($source =~ /^('''?|==|__)(.+?)\1/) {
			my $type  = $1;
			my $label = $2;
			$source = $';
			if ($type eq q{'''}) {
				push @parsed, $self->bold($label);
			}
			elsif ($type eq q{__}) {
				push @parsed, $self->underline($label);
			}
			elsif ($type eq q{''}) {
				push @parsed, $self->italic($label);
			}
			else {							   ## elsif ($type eq q{==}) {
				push @parsed, $self->denialline($label);
			}
		}

		# エラーメッセージ
		elsif ($source =~ /^<<(.+?)>>/) {
			my $label = $1;
			$source = $';
			push @parsed, $self->error($label);
		}

		# インライン Wiki 書式全体には macth しなかったとき
		else {
			# 1 文字進む。
			if ($source =~ /^(.)/) {
				$pre .= $1;
				$source = $';
			}
			
			# parse 結果を @array に保存する処理を飛ばして繰り返し。
			next SOURCE;
		}

		# インライン Wiki 書式全体に macth した後の
		# parse 結果を @array に保存する処理。

		# もし $pre が溜まっているなら、キーワードの処理を実施。
		if ($pre ne q{}) {
			push @array, $self->_parse_line_keyword($pre);
			$pre = q{};
		}

		push @array, @parsed;
	}

	# もし $pre が溜まっているなら、キーワードの処理を実施。
	if ($pre ne q{}) {
		push @array, $self->_parse_line_keyword($pre);
	}

	return @array;
}

#========================================================================
# <p>
# parse_line() から呼び出され、キーワードの検索・置換処理を行います。
# </p>
#========================================================================
sub _parse_line_keyword {
	my $self   = shift;
	my $source = shift;

	return () if (not defined $source);

	my @array = ();

	# $source が空になるまで繰り返す。
	while ($source ne q{}) {

		# キーワード
		if ($self->{keyword}->exists_keyword($source)) {
			my $pre   = $self->{keyword}->{g_pre};
			my $label = $self->{keyword}->{g_label};
			my $url   = $self->{keyword}->{g_url};
			my $page  = $self->{keyword}->{g_page};
			$source = $self->{keyword}->{g_post};
			if ($pre ne q{}) {
				push @array, $self->_parse_line_keyword($pre);
			}
			if (defined($url) && $url ne q{}) {
				push @array, $self->url_anchor($url, $label);
			} else {
				push @array, $self->wiki_anchor($page, $label);
			}

		}

		# WikiName
		elsif ($self->{wiki}->config('wikiname') == 1 && $source =~ /[A-Z]+?[a-z]+?(?:[A-Z]+?[a-z]+)+/) {
			my $pre  = $`;
			my $page = $&;
			$source  = $';
			if ($pre ne q{}) {
				push @array, $self->_parse_line_keyword($pre);
			}
			push @array, $self->wiki_anchor($page);
		}

		# キーワードも WikiName も見つからなかったとき
		else {
			push @array, $self->text($source);
			return @array;
		}
	}
	return @array;
}

#===============================================================================
# <p>
# パースを開始前に呼び出されます。
# サブクラスで必要な処理がある場合はオーバーライドしてください。
# </p>
#===============================================================================
sub start_parse {}

#===============================================================================
# <p>
# パース終了後に呼び出されます。
# サブクラスで必要な処理がある場合はオーバーライドしてください。
# </p>
#===============================================================================
sub end_parse {}

#===============================================================================
# <p>
# URLアンカにマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub url_anchor {}

#===============================================================================
# <p>
# ページ名アンカにマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub wiki_anchor {}

#===============================================================================
# <p>
# イタリックにマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub italic {}

#===============================================================================
# <p>
# ボールドにマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub bold {}

#===============================================================================
# <p>
# 下線にマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub underline {}

#===============================================================================
# <p>
# 打ち消し線にマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub denialline {}

#===============================================================================
# <p>
# プラグインにマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub plugin {}

#===============================================================================
# <p>
# テキストにマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub text{}

#===============================================================================
# <p>
# 項目にマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub l_list {}

#===============================================================================
# <p>
# 番号付き項目にマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub l_numlist {}

#===============================================================================
# <p>
# 見出しにマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub l_headline {}

#===============================================================================
# <p>
# PREタグにマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub l_verbatim {}

#===============================================================================
# <p>
# 水平線にマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub l_line {}

#===============================================================================
# <p>
# 特になにもない行にマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub l_text {}

#===============================================================================
# <p>
# 説明にマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub l_explanation {}

#===============================================================================
# <p>
# 引用にマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub l_quotation {}

#===============================================================================
# <p>
# パラグラフの区切りにマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub l_paragraph {}

#===============================================================================
# <p>
# テーブルにマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub l_table {}

#===============================================================================
# <p>
# パラグラフプラグインにマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub l_plugin {}

#===============================================================================
# <p>
# 画像にマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub l_image {}

#===============================================================================
# <p>
# エラーメッセージにマッチした場合に呼び出されます。
# サブクラスにて処理を実装します。
# </p>
#===============================================================================
sub error {}

1;
