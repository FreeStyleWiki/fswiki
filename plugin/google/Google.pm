######################################################################
#
# <p>Googleの検索ボックスを表示します。</p>
# <pre>
# {{google}}
# </pre>
# <p>サイト検索機能を持たせることもできます。</p>
# <pre>
# {{google サーバ名}}
# </pre>
# <p>日本語のページから検索させるための選択を表示することができます。</p>
# <pre>
# {{google l}}
# </pre>
# <p>Menu向けにテキストボックスとボタンを縦に配置できます。</p>
# <pre>
# {{google v}}
# </pre>
# <p>検索結果を新しい窓で開くように出来ます。</p>
# <pre>
# {{google t}}
# </pre>
# <p>テキストボックスの幅が指定できます。</p>
# <pre>
# {{google s幅}}
# </pre>
# <p>幅は1〜255の間で指定してください。</p>
# <p>表示位置の指定が出来ます。</p>
# <pre>
# {{google (center|right|left)}}
# </pre>
# <p>
#   これらのオプションは併用することもできます。
#   カンマで区切って記述してください。順序は任意です。
# </p>
# <pre>
# {{google サーバ名,l,v,t,25wht,s幅,center}}
# </pre>
#
######################################################################
package plugin::google::Google;
use strict;

#=====================================================================
# コンストラクタ
#=====================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#=====================================================================
# パラグラフメソッド
#=====================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my @args = @_;

	my $error = undef;
	my $logo = '40wht';
	my $domain = undef;
	my $lang = undef;
	my $size = 31;
	my $align = "center";
	my $target = '';
	my $vertical_br = '';
	my $logolist = '|25wht|40wht|50wht|60wht|25gry|40gry|50gry|60gry|25blk|40blk|50blk|60blk|';

	foreach my $arg (@args) {
		$arg = Util::trim($arg);
		if (index($logolist, '|' . lc($arg) . '|') >= 0) {
			$logo = lc($arg);
		} elsif (lc($arg) eq 'v') {
			$vertical_br = '<br>';
		} elsif (lc($arg) eq 'l') {
			$lang = 1;
		} elsif (lc($arg) eq 't') {
			$target = 'target=blank';
		} elsif ($arg =~ /^s([0-9]+)/) {
			$size = $1;
			if (($size < 1) || ($size > 255)) {
				$error = 'サイズは1〜255で指定してください。';
			}
		} elsif ($arg =~ /(center|right|left)/) {
			$align = $1;
		} else {
			if (defined($domain)) {
				$error = 'ドメインが複数指定されています。';
			} elsif (($arg eq '') || ($arg =~ /[^-0-9A-Za-z.]/)) {
				$error = 'ドメイン名に使用できない文字があります。';
			} else {
				$domain = $arg;
			}
		}
	}
	return &Util::paragraph_error($error) if defined($error);

	if ($vertical_br ne '') {
		my $siteoption = '';

		$siteoption .= <<"EOD" if defined($domain);
<input type=hidden name=domains value="${domain}"><br><input type=radio name=sitesearch value="">WWW <input type=radio name=sitesearch value="${domain}" checked>${domain}
EOD

		$siteoption .= <<"EOD" if defined($lang);
<br><input type=radio name=lr value="" checked>ウェブ全体 <input type=radio name=lr value=lang_ja >日本語
EOD

		$siteoption = "<font size=-1>${siteoption}</font>" if $siteoption ne '';

		return <<"EOD";
<!-- Google  -->
<div class="plugin_google" align="$align">
  <form method="GET" action="https://www.google.co.jp/search" $target>
    <input type="text" name="q" size="${size}" maxlength="255" value="" placeholder="Google検索">${siteoption}<br>
    <input type="submit" name="btnG" value="Google検索">
    <input type="hidden" name="hl" value="ja">
    <input type="hidden" name="ie" value="EUC-JP">
  </form>
</div>
<!-- /Google -->
EOD
	} else {
		my $siteoption = '';

		$siteoption .= <<"EOD" if defined($domain);
<input type=hidden name=domains value="${domain}"><br><input type=radio name=sitesearch value=""> WWW を検索 <input type=radio name=sitesearch value="${domain}" checked> ${domain} を検索
EOD

		$siteoption .= <<"EOD" if defined($lang);
<br><input type=radio name=lr value="" checked>ウェブ全体から検索 <input type=radio name=lr value=lang_ja >日本語のページを検索
EOD

		$siteoption = "<font size=-1>${siteoption}</font>" if $siteoption ne '';

		return <<"EOD";
<!-- Google  -->
<div class="plugin_google" align="$align">
  <form method="GET" action="https://www.google.co.jp/search" $target>
    <table style="border: none"><tr><td style="border: none" align=center>
    <input type="text" name="q" size="${size}" maxlength="255" value="" placeholder="Google検索">
    <input type="submit" name="btnG" value="Google検索">${siteoption}
    </td></tr></table>
    <input type="hidden" name="hl" value="ja">
    <input type="hidden" name="ie" value="EUC-JP">
  </form>
</div>
<!-- /Google -->
EOD
	}
}

1;
