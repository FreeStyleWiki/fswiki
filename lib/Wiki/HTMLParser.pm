###############################################################################
#
# HTMLパーサ
#
###############################################################################
package Wiki::HTMLParser;
use Wiki::Parser;
use vars qw(@ISA);
use strict;

@ISA = qw(Wiki::Parser);
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class   = shift;
	my $wiki    = shift;
	my $mainflg = shift;
	
	if(!defined($mainflg) || $mainflg eq ""){ $mainflg = 0; }
	
	my $self = Wiki::Parser->new($wiki);
	
	$self->{html}  = "";
	$self->{pre}   = "";
	$self->{quote} = "";
	$self->{table} = 0;
	$self->{level} = 0;
	$self->{para}  = 0;
	$self->{p_cnt} = 0;
	$self->{main}  = $mainflg;
	return bless $self,$class;
}

#==============================================================================
# リスト
#==============================================================================
sub l_list {
	my $self  = shift;
	my $level = shift;
	my $obj   = shift;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	my $html = join("",@$obj);

	if($level > $self->{level}){
		while($level != $self->{level}){
			$self->{html} .= "<ul>\n";
			push(@{$self->{close_list}},"</ul>\n");
			$self->{level}++;
		}
	} elsif($level <= $self->{level}){
		while($level-1 != $self->{level}){
			if($self->{'list_close_'.$self->{level}} == 1){
				$self->{html} .= "</li>\n";
				$self->{'list_close_'.$self->{level}} = 0;
			}
			if($level == $self->{level}){
				last;
			}
			$self->{html} .= pop(@{$self->{close_list}});
			$self->{level}--;
		}
	}
	
	$self->{html} .= "<li>".$html;
	$self->{'list_close_'.$level} = 1;
}

#==============================================================================
# 番号付きリスト
#==============================================================================
sub l_numlist {
	my $self  = shift;
	my $level = shift;
	my $obj   = shift;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	my $html = join("",@$obj);
	
	if($level > $self->{level}){
		while($level != $self->{level}){
			$self->{html} .= "<ol>\n";
			push(@{$self->{close_list}},"</ol>\n");
			$self->{level}++;
		}
	} elsif($level <= $self->{level}){
		while($level-1 != $self->{level}){
			if($self->{'list_close_'.$self->{level}} == 1){
				$self->{html} .= "</li>\n";
				$self->{'list_close_'.$self->{level}} = 0;
			}
			if($level == $self->{level}){
				last;
			}
			$self->{html} .= pop(@{$self->{close_list}});
			$self->{level}--;
		}
	}
	
	$self->{html} .= "<li>".$html;
	$self->{'list_close_'.$level} = 1;
}

#==============================================================================
# リストの終了
#==============================================================================
sub end_list {
	my $self  = shift;
	while($self->{level} != 0){
		if($self->{'list_close_'.($self->{level})} == 1){
			$self->{html} .= "</ll>\n";
		}
		$self->{html} .= pop(@{$self->{close_list}});
		$self->{level}--;
	}
}

#==============================================================================
# ヘッドライン
#==============================================================================
sub l_headline {
	my $self  = shift;
	my $level = shift;
	my $obj   = shift;
	my $wiki  = $self->{wiki};
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	my $html  = join("",@$obj);
	
	# メインの表示領域でないとき
	if(!$self->{main}){
		$self->{html} .= "<h".($level+1).">".$html."</h".($level+1).">\n";

	# メインの表示領域の場合はアンカを出力
	} else {
		if($level==2){
			$self->{html} .= "<h".($level+1)."><a name=\"p".$self->{p_cnt}."\"><span class=\"sanchor\">&nbsp;</span>".
			                 $html."</a></h".($level+1).">\n";
		} else {
			$self->{html} .= "<h".($level+1)."><a name=\"p".$self->{p_cnt}."\">".$html."</a></h".($level+1).">\n";
		}
		# パート編集がONかつ編集可能な場合は編集アンカを出力
		if($self->{no_partedit}!=1){
			my $page = $wiki->get_CGI()->param("page");
			my $part_edit = "";
			# パートリンクがONの場合は移動用のアンカを出力
			if ($wiki->config("partlink") == 1) {
				$part_edit .= "<a class=\"partedit\" href=\"#\">TOP</a> ";
				$part_edit .= "<a class=\"partedit\" href=\"#p".($self->{p_cnt} - 1)."\">↑</a> ";
				$part_edit .= "<a class=\"partedit\" href=\"#p".($self->{p_cnt} + 1)."\">↓</a> ";
			}
			# パート編集がONかつ編集可能な場合は編集アンカを出力
			if($wiki->config("partedit")==1 && $wiki->can_modify_page($page)){
				unless(defined($self->{partedit}->{$page})){
					$self->{partedit}->{$page} = 0;
				} else {
					$self->{partedit}->{$page}++;
				}
				# InterWiki形式の場合
				my $full = $page;
				my $path = $self->{wiki}->config('script_name');
				if(index($page,":")!=-1){
					($path,$page) = split(/:/,$page);
					$path = $self->{wiki}->config('script_name')."/$path";
				}
				$part_edit .= "<a class=\"partedit\" href=\"$path?action=EDIT".
				              "&amp;page=".&Util::url_encode($page).
				              "&amp;artno=".$self->{partedit}->{$full}."\" rel=\"nofollow\">編集</a>";
			}
			if($part_edit ne ""){
				$self->{html} .= "<div class=\"partedit\">$part_edit</div>\n";
			}
		}
		
	}
	$self->{p_cnt}++;
}

#==============================================================================
# 水平線
#==============================================================================
sub l_line {
	my $self = shift;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	$self->{html} .= "<hr>\n";
}

#==============================================================================
# 段落区切り
#==============================================================================
sub l_paragraph {
	my $self = shift;
	
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	} elsif($self->{wiki}->config('br_mode')==1){
		$self->{html} .= "<br>\n";
	}
}

#==============================================================================
# 整形済テキスト
#==============================================================================
sub l_verbatim {
	my $self  = shift;
	my $text  = shift;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_list;
	$self->end_table;
	$self->end_quote;
	
	$text =~ s/^\s//;
	$self->{pre} .= Util::escapeHTML($text)."\n";
}

sub end_verbatim {
	my $self  = shift;
	if($self->{pre} ne ""){
		$self->{html} .= "<pre>".$self->{pre}."</pre>\n";
		$self->{pre} = "";
	}
}

#==============================================================================
# テーブル
#==============================================================================
sub l_table {
	my $self = shift;
	my $row  = shift;
	$self->end_list;
	$self->end_verbatim;
	$self->end_quote;
	
	if($self->{table}==0){
		$self->{table}=1;
		$self->{html} .= "<table>\n";
		$self->{html} .= "<tr>\n";
		foreach(@$row){
			my $html = join("",@$_);
			$self->{html} .= "<th>".$html."</th>\n";
		}
		$self->{html} .= "</tr>\n";
	} else {
		$self->{table}=2;
		$self->{html} .= "<tr>\n";
		foreach(@$row){
			my $html = join("",@$_);
			$self->{html} .= "<td>".$html."</td>\n";
		}
		$self->{html} .= "</tr>\n";
	}
}

sub end_table {
	my $self = shift;
	if($self->{table}!=0){
		$self->{table} = 0;
		$self->{html} .= "</table>\n";
	}
}

#==============================================================================
# パース終了時の処理
#==============================================================================
sub end_parse {
	my $self = shift;
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
}

#==============================================================================
# 行書式に該当しない行
#==============================================================================
sub l_text {
	my $self = shift;
	my $obj  = shift;
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	my $html = join("",@$obj);
	
	if($self->{para}==0){
		$self->{html} .= "<p>";
		$self->{para} = 1;
	}
	$self->{html} .= $html;
	
	# brモードに設定されている場合は<br>を足す
	if($self->{wiki}->config('br_mode')==1){
		$self->{html} .= "<br>\n";
	}
}

#==============================================================================
# 引用
#==============================================================================
sub l_quotation {
	my $self = shift;
	my $obj  = shift;
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	my $html = join("",@$obj);
	$self->{quote} .= "<p>".$html."</p>\n";
}

sub end_quote {
	my $self = shift;
	if($self->{quote} ne ""){
		$self->{html} .= "<blockquote>".$self->{quote}."</blockquote>\n";
		$self->{quote} = "";
	}
}

#==============================================================================
# 説明
#==============================================================================
sub l_explanation {
	my $self = shift;
	my $obj1 = shift;
	my $obj2 = shift;
	
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	my $html1 = join("",@$obj1);
	my $html2 = join("",@$obj2);
	
	$self->{html} .= "<dl>\n<dt>".$html1."</dt>\n<dd>".$html2."</dd>\n</dl>\n";
}

#==============================================================================
# ボールド
#==============================================================================
sub bold {
	my $self = shift;
	my $text = shift;
	return "<strong>".join("",$self->parse_line($text))."</strong>";
}

#==============================================================================
# イタリック
#==============================================================================
sub italic {
	my $self = shift;
	my $text = shift;
	return "<em>".join("",$self->parse_line($text))."</em>";
}

#==============================================================================
# 下線
#==============================================================================
sub underline {
	my $self = shift;
	my $text = shift;
	return "<ins>".join("",$self->parse_line($text))."</ins>";
}

#==============================================================================
# 打ち消し線
#==============================================================================
sub denialline {
	my $self = shift;
	my $text = shift;
	return "<del>".join("",$self->parse_line($text))."</del>";
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
	
	if($url eq $name && $url=~/\.(gif|jpg|jpeg|bmp|png)$/i && $self->{'wiki'}->config('display_image')==1){
		return "<img src=\"".$url."\">";
	} else {
		if($self->{wiki}->config('open_new_window')==1 &&
			($self->{wiki}->config('inside_same_window')==0 ||
			($self->{wiki}->config('inside_same_window')==1 && index($url,'://') > 0))){
			return "<a href=\"$url\" target=\"_blank\">".Util::escapeHTML($name)."</a>";
		} else {
			return "<a href=\"$url\">".Util::escapeHTML($name)."</a>";
		}
	}
}

#==============================================================================
# Wikiページへのアンカ
#==============================================================================
sub wiki_anchor {
	my $self = shift;
	my $page = shift;
	my $name = shift;
	
	if(!defined($name) || $name eq ""){
		$name = $page;
	}
	if($self->{wiki}->page_exists($page)){
		return "<a href=\"".$self->{wiki}->create_page_url($page)."\" class=\"wikipage\">".
		       &Util::escapeHTML($name)."</a>";
	} else {
		return "<span class=\"nopage\">".&Util::escapeHTML($name)."</span>".
		       "<a href=\"".$self->{wiki}->create_page_url($page)."\">?</a>";
	}
}

#==============================================================================
# ただのテキスト
#==============================================================================
sub text {
	my $self = shift;
	my $text = shift;
	return &Util::escapeHTML($text);
}

#==============================================================================
# プラグイン
#==============================================================================
sub plugin {
	my $self   = shift;
	my $plugin = shift;
	
	my @result = $self->{wiki}->process_plugin($plugin,$self);
	return @result;
}

#==============================================================================
# パラグラフプラグイン
#==============================================================================
sub l_plugin {
	my $self   = shift;
	my $plugin = shift;
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	my $result = $self->{wiki}->process_plugin($plugin,$self);
	if(defined($result) && $result ne ""){
		$self->{html} .= $result;
	}
}

#==============================================================================
# イメージ
#==============================================================================
sub l_image {
	my $self = shift;
	my $page = shift;
	my $file = shift;
	my $wiki = $self->{wiki};
	
	if($self->{para}==1){
		$self->{html} .= "</p>\n";
		$self->{para} = 0;
	}
	
	$self->end_list;
	$self->end_verbatim;
	$self->end_table;
	$self->end_quote;
	
	$self->{html} .= "<div><img src=\"".$wiki->create_url({action=>"ATTACH",page=>$page,file=>$file})."\"></div>\n";
}

#==============================================================================
# エラーメッセージ
#==============================================================================
sub error {
	my $self  = shift;
	my $label = shift;
	
	return "<span class=\"error\">".Util::escapeHTML($label)."</span>";
}

1;
