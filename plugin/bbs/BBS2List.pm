###############################################################################
#
# <p>bbs2プラグインから投稿された記事の一覧を表示します。</p>
# <pre>
# {{bbs2list 掲示板の名前,表示件数}}
# </pre>
# <p>
#  表示件数を省略すると10件ずつ表示されます。
#  また、オプションで各記事のタイトルのみ表示することや、
#  更新順に表示することもできます。
# </p>
# <pre>
# {{bbs2list 掲示板の名前,表示件数,title}}
# </pre>
# <p>
#  この場合も表示件数を省略することができます。省略すると10件ずつ表示します。
# </p>
# <pre>
# {{bbs2list 掲示板の名前,title}}
# </pre>
# <p>
#  recentは、記事を更新順に表示します。（スレッド・フロート形式）
#  titleとrecentはどちらを先に指定しても良いです。
#  この2つのオプションはそれぞれ独立に作用します。
# </p>
# <pre>
# {{bbs2list 掲示板の名前,表示件数,recent,title}}
# {{bbs2list 掲示板の名前,title,recent}}
# </pre>
#
###############################################################################
package plugin::bbs::BBS2List;
use strict;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# 記事の一覧を作成
#==============================================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $cgi    = $wiki->get_CGI();
	my $name   = shift;
	
	# 引数のチェック
	if($name eq ""){
		return &Util::paragraph_error("掲示板の名前が指定されていません。");
	}
	
	# 2番目の引数が数字だった場合はそれを表示件数にする。
	my $once = &Util::trim($_[0]);
	$once = &Util::check_numeric($once) ? $once : 10;
	
	# 残りのオプションを解析
	my %option;
	undef %option;
	$option{lc &Util::trim($_)} = 1 foreach @_;
	my $title  = exists $option{'title'}  ? 1 : 0;
	my $recent = exists $option{'recent'} ? 1 : 0;

	
	# 一覧を取得してWiki形式の文字列を組み立てる
	my $i    = 0;
	my $buf  = "";
	my $page = $cgi->param("page");
	my $cnt  = $cgi->param("cnt");
	if($cnt eq ""){ $cnt = 0; };
	
	my $ref_list = $self->_get_content_list($wiki,$name,$title,$recent);
	foreach my $item (@$ref_list){
		if($i >= $cnt*$once){
			if($title){
				$buf .= "*".$item->{name}."\n";
			} else {
				$buf .= "{{include ".$item->{name}."}}\n";
			}
		}
		$i++;
		last if($i/$once == $cnt+1);
	}
	
	# ページ処理用のリンクを作成
	$buf .= "\n[ ";
	my $pagecnt = 1;
	for($i=0;$i<=$#$ref_list;$i=$i+$once){
		if($cnt==$pagecnt-1){
			$buf .= $pagecnt." ";
		} else {
			$buf .= "[$pagecnt|".$wiki->create_url({page=>$page,cnt=>($pagecnt-1) })."] ";
		}
		$pagecnt++;
	}
	$buf .= "]\n";
	
	return $buf;
}

#==============================================================================
# 記事の一覧を取得
#==============================================================================
sub _get_content_list {
	my $self   = shift;
	my $wiki   = shift;
	my $name   = shift;
	my $title  = shift;
	my $recent = shift;
	my @list  = ();
	my $qname = quotemeta($name);
	
	foreach my $pagename ($wiki->get_page_list({-permit=>'show'})){
		if($pagename =~ /^BBS-$qname\/([0-9]+)$/){
			my $id = $1;
			if($title){
				my $content = $wiki->get_page($pagename);
				if($content =~ /^!!(.*)$/m){
					push(@list,{name=>$1,id=>$id});
				}
			} else {
				push(@list,{name=>$pagename,id=>$id});
			}
		}
	}
	
	if($recent){
		# 各スレッドの更新日時を取得
		foreach (@list) {
			$_->{last_modified} = $wiki->get_last_modified2("BBS-$name/$_->{id}");
		}
		# 更新日時（新着順）にソート
		@list = sort { $b->{last_modified} <=> $a->{last_modified} } @list;
	} else {
		# recentの指定がないときはid（スレッド立てた順番）の降順
		@list = sort { $b->{id} <=> $a->{id} } @list;
	}
	
	return \@list;
}

1;
