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
				$self->{block}->{level}++;
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
			if(index($line,"::")==0){
				if($self->{dt} ne "" || $self->{dd} ne ""){
					$self->multi_explanation;
				}
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
	my $self   = shift;
	my $source = shift;
	my @array  = ();
		
	# プラグイン
	if($source =~ /{{/){
		my $pre  = $`;
		my $post = $';
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		my $plugin = $self->{wiki}->parse_inline_plugin($post);
		unless($plugin){
			push @array,'{{';
			push @array,$self->parse_line($post);
		} else {
			my $info   = $self->{wiki}->get_plugin_info($plugin->{command});
			if($info->{TYPE} eq "inline"){
				push @array,$self->plugin($plugin);
			} else {
				push @array,$self->parse_line("<<".$plugin->{command}."プラグインは存在しません。>>");
			}
			if($post ne ""){ push(@array,$self->parse_line($plugin->{post})); }
		}
		
	# InterWikiName
	} elsif($self->{interwiki}->exists_interwiki($source)){
		my $pre   = $self->{interwiki}->{g_pre};
		my $post  = $self->{interwiki}->{g_post};
		my $label = $self->{interwiki}->{g_label};
		my $url   = $self->{interwiki}->{g_url};
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		push @array,$self->url_anchor($url,$label);
		if($post ne ""){ push(@array,$self->parse_line($post)); }
	
	# ページ別名リンク
	} elsif($source =~ /\[\[([^\[]+?)\|([^\|\[]+?)\]\]/){
		my $pre   = $`;
		my $post  = $';
		my $label = $1;
		my $page  = $2;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		push @array,$self->wiki_anchor($page,$label);
		if($post ne ""){ push(@array,$self->parse_line($post)); }

	# URL別名リンク
	} elsif($source =~ /\[([^\[]+?)\|((http|https|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*)\]/
	    ||  $source =~ /\[([^\[]+?)\|(file:[^\[\]]*)\]/
	    ||  $source =~ /\[([^\[]+?)\|((\/|\.\/|\.\.\/)+[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*)\]/){
		my $pre   = $`;
		my $post  = $';
		my $label = $1;
		my $url   = $2;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		if(index($url,'"') >= 0 || index($url,'><') >= 0 || index($url, 'javascript:') >= 0){
			push @array,$self->parse_line("<<不正なリンクです。>>");
		} else {
			push @array,$self->url_anchor($url,$label);
		}
		if($post ne ""){ push(@array,$self->parse_line($post)); }
		
	# URLリンク
	} elsif($source =~ /(http|https|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*/
	    ||  $source =~ /(file:[^\[\]]*)/){
		my $pre   = $`;
		my $post  = $';
		my $url = $&;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		if(index($url,'"') >= 0 || index($url,'><') >= 0 || index($url, 'javascript:') >= 0){
			push @array,$self->parse_line("<<不正なリンクです。>>");
		} else {
			push @array,$self->url_anchor($url);
		}
		if($post ne ""){ push(@array,$self->parse_line($post)); }
		
	# ページリンク
	} elsif($source =~ /\[\[([^\|]+?)\]\]/){
		my $pre   = $`;
		my $post  = $';
		my $page = $1;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		push @array,$self->wiki_anchor($page);
		if($post ne ""){ push(@array,$self->parse_line($post)); }
	
	# 任意のURLリンク
	} elsif($source =~ /\[([^\[]+?)\|(.+?)\]/){
		my $pre   = $`;
		my $post  = $';
		my $label = $1;
		my $url   = $2;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		if(index($url,'"') >= 0 || index($url,'><') >= 0 || index($url, 'javascript:') >= 0){
			push @array,$self->parse_line("<<不正なリンクです。>>");
		} else {
			# URIを作成
			my $wiki = $self->{wiki};
			my $uri = $wiki->config('server_host');
			if($uri eq ""){
				$uri = $wiki->get_CGI()->url(-path_info => 1);
			} else {
				$uri = $uri . $wiki->get_CGI->url(-absolute => 1) . $wiki->get_CGI()->path_info();
			}
			push @array,$self->url_anchor($uri."/../".$url, $label);
		}
		if($post ne ""){ push(@array,$self->parse_line($post)); }
	
	# ボールド、イタリック、取り消し線、下線
	} elsif($source =~ /((''')|('')|(==)|(__))(.+?)(\1)/){
		my $pre   = $`;
		my $post  = $';
		my $type  = $1;
		my $label = $6;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		if($type eq "'''"){
			push @array,$self->bold($label);
		} elsif($type eq "__"){
			push @array,$self->underline($label);
		} elsif($type eq "''"){
			push @array,$self->italic($label);
		} elsif($type eq "=="){
			push @array,$self->denialline($label);
		}
		if($post ne ""){ push(@array,$self->parse_line($post)); }
	
	# キーワード
	} elsif($self->{keyword}->exists_keyword($source)){
		my $pre   = $self->{keyword}->{g_pre};
		my $post  = $self->{keyword}->{g_post};
		my $label = $self->{keyword}->{g_label};
		my $url   = $self->{keyword}->{g_url};
		my $page  = $self->{keyword}->{g_page};
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		if(defined($url) && $url ne ""){
			push @array,$self->url_anchor($url,$label);
		} else {
			push @array,$self->wiki_anchor($page,$label);
		}
		if($post ne ""){ push(@array,$self->parse_line($post)); }
		
	# WikiName
	} elsif($self->{wiki}->config('wikiname')==1 && $source =~ /[A-Z]+?[a-z]+?([A-Z]+?[a-z]+)+/){
		my $pre   = $`;
		my $post  = $';
		my $page  = $&;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		push @array,$self->wiki_anchor($page);
		if($post ne ""){ push(@array,$self->parse_line($post)); }
		
	# エラーメッセージ
	} elsif($source =~ /(<<)(.+?)(>>)/){
		my $pre   = $`;
		my $post  = $';
		my $label = $2;
		if($pre ne ""){ push(@array,$self->parse_line($pre)); }
		push @array,$self->error($label);
		if($post ne ""){ push(@array,$self->parse_line($post)); }
		
	} else {
		push @array,$self->text($source);
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
