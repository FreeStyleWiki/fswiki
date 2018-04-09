############################################################
#
# 検索を実行して結果を表示するアクションプラグイン
# BugTrack-plugin/396
# 2009-01-09 版
#
############################################################
package plugin::search::SearchHandler;
use strict;
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
	my $cgi = $wiki->get_CGI;
	my $word = Util::trim($cgi->param("word"));

	my $buf          = "";
	my $or_search    = $cgi->param('t') eq 'on';
	my $with_content = $cgi->param('c') eq 'true';

	$wiki->set_title("検索");
	$buf .= "<form method=\"GET\" action=\"".$wiki->create_url()."\">\n".
	        "キーワード <input type=\"text\" name=\"word\" size=\"20\" value=\"".&Util::escapeHTML($word)."\"> ";

	$buf .= "<input type=\"radio\" name=\"t\" id=\"and\" value=\"and\"";
	$buf .= " checked" if (not $or_search);
	$buf .= "><label for=\"and\">AND</label>\n";
	$buf .= "<input type=\"radio\" name=\"t\" id=\"or\" value=\"or\"";
	$buf .= " checked" if ($or_search);
	$buf .= "><label for=\"or\">OR</label>\n";
	$buf .= "<input type=\"checkbox\" id=\"contents\" name=\"c\" value=\"true\"";
	$buf .= " checked" if ($with_content);
	$buf .= "><label for=\"contents\">ページ内容も含める</label>\n";

	$buf .=  "<input type=\"submit\" value=\" 検 索 \">".
	         "<input type=\"hidden\" name=\"action\" value=\"SEARCH\">".
	         "</form>\n";

	my $ignore_case = 1;
	my $conv_upper_case = ($ignore_case and $word =~ /[A-Za-z]/);
	$word = uc $word if ($conv_upper_case);
	my @words = grep { $_ ne '' } split(/ +|　+/, $word);
	return $buf unless (@words);
	#---------------------------------------------------------------------------
	# 検索実行
	my @list = $wiki->get_page_list({-permit=>'show'});
	my $res = '';
	PAGE:
	foreach my $name (@list){
		# ページ名も検索対象にする
		my $page = $name;
		$page .= "\n".$wiki->get_page($name) if ($with_content);
		my $pageref = ($conv_upper_case) ? \(my $page2 = uc $page) : \$page;
		my $index;

		if ($or_search) {
			# OR検索 -------------------------------------------------------
			WORD:
			foreach(@words){
				next WORD if (($index = index $$pageref, $_) == -1);
				$res .= "<li>".
					    "<a href=\"".$wiki->create_page_url($name)."\">".Util::escapeHTML($name)."</a>".
						" - ".
						Util::escapeHTML(&get_match_content($wiki, $page, $index)).
						"</li>\n";
				next PAGE;
			}
		} else {
			# AND検索 ------------------------------------------------------
			WORD:
			foreach(@words){
				next PAGE if (($index = index $$pageref, $_) == -1);
			}
			$res .= "<li>".
					"<a href=\"".$wiki->create_page_url($name)."\">".Util::escapeHTML($name)."</a>".
					" - ".
					Util::escapeHTML(&get_match_content($wiki, $page, $index)).
					"</li>\n";
		}
	}
	return "$buf<ul>\n$res</ul>\n" if ($res ne '');
	return $buf;
}

#===========================================================
# 検索にマッチした行を取り出す関数
#===========================================================
sub get_match_content {
	my $wiki    = shift;
	my $content = shift;
	my $index   = shift;

	# 検索にマッチした行の先頭文字の位置を求める。
	# ・$content の $index 番目の文字から先頭方向に改行文字を探す。
	# ・$index の位置を含む行の先頭文字の位置は改行文字の次なので +1 する。
	# ・先頭方向に改行文字が無かったら最初の行なので、結果は 0(先頭)。
	#   (見つからないと rindex() = -1 になるので、+1 してちょうど 0)
	my $pre_index = rindex($content, "\n", $index) + 1;

	# 検索にマッチした行の末尾文字の位置を求める。
	# ・$content の $index 番目の文字から末尾方向に改行文字を探す。
	my $post_index = index($content, "\n", $index);

	# 末尾方向に改行文字がなかったら最終行なので $pre_index 以降全てを返却。
	return substr($content, $pre_index) if ($post_index == -1);

	# 見つかった改行文字に挟まれた文字列を返却。
	return substr($content, $pre_index, $post_index - $pre_index);
}

1;
