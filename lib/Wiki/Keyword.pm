###############################################################################
#
# キーワードパーサ
#
###############################################################################
package Wiki::Keyword;
use strict;

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
	
#	$self->{eucpre}  = qr{(?<!\x8F)};
#	$self->{eucpost} = qr{(?=
#		(?:[\xA1-\xFE][\xA1-\xFE])* # JIS X 0208 が 0文字以上続いて
#		(?:[\x00-\x7F\x8E\x8F]|\z)  # ASCII, SS2, SS3 または終端
#	)}x;
	
	$self = bless($self,$class);
	$self->load_keywords();
	
	return $self;
}

#==============================================================================
# キーワードが含まれるかどうかチェック
#==============================================================================
sub exists_keyword {
	my $self  = shift;
	my $str   = shift;
	my $regex = $self->{regex};
	if($regex eq ""){
		return 0;
	}
	if($str =~ /$regex/){
		$self->{g_pre}   = $`;
		$self->{g_post}  = $';
		$self->{g_label} = $&;
		$self->{g_url}   = $self->{info_url}->{$&};
		$self->{g_page}  = $self->{info_page}->{$&};
		return 1;
	}
	return 0;
}

#==============================================================================
# キーワードをキャッシュファイルから読み込み
#==============================================================================
sub load_keywords {
	my $self = shift;
	my $wiki = $self->{wiki};
	$self->{keywords}  = [];

	my $cachefile = $wiki->config('log_dir')."/keywords.cache";

	if (-e $cachefile) {
		my $buf = &Util::load_config_text(undef, $cachefile);
		my @lines = split(/\n/,$buf);
		foreach my $line (@lines) {
			my @keys = split(/\t/,$line);
			if ($keys[0] eq "url") {
				$self->url_anchor($keys[2], $keys[1]);
			} elsif($wiki->can_show($keys[2])){
				$self->wiki_anchor($keys[2], $keys[1]);
			}
		}
	} else {
		$self->parse();
		$self->save_keywords();
	}

	# 高速化のためマッチ用の情報を予め作成しておく
	my $regex = '';
	my $url   = {};
	my $page  = {};
	foreach my $keyword (@{$self->{keywords}}){
		if($regex ne ''){
			$regex = $regex."|";
		}
		$regex = $regex.quotemeta($keyword->{word});
		$url->{$keyword->{word}}  = $keyword->{url};
		$page->{$keyword->{word}} = $keyword->{page};
	}
	$self->{regex}     = $regex;
	$self->{info_url}  = $url;
	$self->{info_page} = $page;
}

#==============================================================================
# キーワードのキャッシュファイルを更新
#==============================================================================
sub save_keywords {
	my $self = shift;
	my $wiki = $self->{wiki};

	my $cachefile = $wiki->config('log_dir')."/keywords.cache";
	my $buf = "";

	my @keywords = @{$self->{keywords}};

	foreach my $keyword (@keywords){
		my $label = $keyword->{word};
		my $url   = $keyword->{url};
		my $page  = $keyword->{page};
		if ($url eq "") {
			$buf .= "wiki\t$label\t$page\n";
		} else {
			$buf .= "url\t$label\t$url\n";
		}
	}
	&Util::save_config_text(undef, $cachefile, $buf);
}

#==============================================================================
# パース（コンストラクタから呼ばれます）
#==============================================================================
sub parse {
	my $self = shift;
	my $wiki = $self->{wiki};
	$self->{keywords}  = [];

	if($wiki->page_exists("Keyword")){
		my $source = $wiki->get_page("Keyword");
		$source =~ s/\r//g;
		my @lines = split(/\n/,$source);
		foreach my $line (@lines){
			if(index($line,"*")==0){
				$self->parse_line($line);
			}
		}
	}

	# ページのオートリンクが有効な場合、ページ名もキーワードに含む
	if($self->{wiki}->config('auto_keyword_page')==1){
		my @pages = $wiki->get_page_list();
		foreach my $page (@pages){
			if($self->{wiki}->config('keyword_slash_page') eq "1" || index($page,"/")==-1){
				$self->parse_line("[[$page|$page]]");
			}
		}
	}
	# 最長マッチになるようにソート
	@{$self->{keywords}} = sort {
		my $len_a = length($a->{word});
		my $len_b = length($b->{word});
		return $len_b <=> $len_a;
	} @{$self->{keywords}};
}

sub parse_line {
	my $self   = shift;
	my $source = shift;
	
	# 別名リンク
	if($source =~ /\[([^\[]+?)\|((http|https|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*)\]/
	|| $source =~ /\[([^\[]+?)\|(file:[^\[\]]*)\]/
	|| $source =~ /\[([^\[]+?)\|((\/|\.\/|\.\.\/)+[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!\$&=:;\*#\@']*)\]/){
	
		my $label = $1;
		my $url   = $2;
		$self->url_anchor($url,$label);
	
	# InterWiki
	} elsif($self->{interwiki}->exists_interwiki($source)){
		my $pre   = $self->{interwiki}->{g_pre};
		my $post  = $self->{interwiki}->{g_post};
		my $label = $self->{interwiki}->{g_label};
		my $url   = $self->{interwiki}->{g_url};
		$self->url_anchor($url,$label);
 
	# ページ別名リンク
	} elsif($source =~ /\[\[([^\[]+?)\|(.+?)\]\]/){
		my $label = $1;
		my $page  = $2;
		$self->wiki_anchor($page,$label);
		
	# 任意のURLリンク
	} elsif($source =~ /\[([^\[]+?)\|(.+?)\]/){
		my $label = $1;
		my $url   = $2;
		$self->url_anchor($url,$label);
	}
}

#==============================================================================
# URLアンカ
#==============================================================================
sub url_anchor {
	my $self = shift;
	my $url  = shift;
	my $name = shift;
	
	if($name eq ""){
		$name = $url;
	}
	my $keyword = {};
	$keyword->{word} = $name;
	$keyword->{url}  = $url;
	push(@{$self->{keywords}},$keyword);
}

#==============================================================================
# Wikiアンカ
#==============================================================================
sub wiki_anchor {
	my $self = shift;
	my $page = shift;
	my $name = shift;
	
	if($name eq ""){
		$name = $page;
	}
	my $keyword = {};
	$keyword->{word} = $name;
	$keyword->{page} = $page;
	push(@{$self->{keywords}},$keyword);
}

1;
