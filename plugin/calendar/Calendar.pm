################################################################################
#
# <p>カレンダを表示します。</p>
# <pre>
# {{calendar カレンダ名}}
# </pre>
# <p>
#   カレンダの「&lt;&lt;」をクリックすると前月、
#   「&gt;&gt;」をクリックすると翌月、
#   年月をクリックするとその月のカレンダとページ内容を一覧表示します。
#   また、カレンダの日付をクリックすると該当する日付のページを表示
#   （ページが存在しない場合は編集画面を表示）します。
# </p>
# <p>
#   オプションで編集画面に見本として表示されるテンプレートページを指定することができます。
# </p>
# <pre>
# {{calendar カレンダ名[,テンプレートとなるページ名[,表示月指定]]}}
# </pre>
# <p>
#   表示月指定に<code>[半角10進数]next</code>と書くと、[半角10進数]月後のカレンダーを表示します。
#   表示月指定に<code>[半角10進数]prev</code>と書くと、[半角10進数]月前のカレンダーを表示します。
#   表示月指定に<code>[半角で1〜12]</code>と書くと、[1〜12]月のカレンダーを表示します。
#   その他の表示月指定は無視されます。
# </p>
# <p>
#   以下にカレンダプラグインの使用例を示します。
# </p>
# <pre>
# {{calendar 予定表}}
# {{calendar 予定表,予定表テンプレート}}
# {{calendar 予定表,予定表テンプレート,6}} : 6月のカレンダー
# {{calendar 予定表, ,1next}} : 翌月のカレンダー
# {{calendar 予定表, ,2prev}} : 先々月のカレンダー
# </pre>
# <p>
#   CSSで表示形式を変更することも出来ます。使用しているクラス名は以下の通りです。
# </p>
# <ul>
#   <li>today - 今日の日付</li>
#   <li>have - 予定や日記のある日付</li>
#   <li>navi - ナビゲーションバー</li>
#   <li>week - 曜日</li>
#   <li>calendar - カレンダーのtable部分</li>
#   <li>plugin-calendar - calendarプラグインの出力全体</li>
# </ul>
# <p>
#   使用しているid名は以下の通りです。
# </p>
# <ul>
#   <li>calendar-[半角で1〜12] - [1〜12]月が指定された時</li>
#   <li>calendar-[半角10進数]next - [半角10進数]月後を指定した時</li>
#   <li>calendar-[半角10進数]prev - [半角10進数]月前を指定した時</li>
#   <li>calendar-sun - 日曜日</li>
#   <li>weekday - 平日</li>
#   <li>calendar-sat - 土曜日</li>
# </ul>
#
################################################################################
package plugin::calendar::Calendar;
use strict;
use plugin::calendar::CalendarHandler;
#===============================================================================
# コンストラクタ
#===============================================================================
sub new {
    my $class = shift;
    my $self = {};
    return bless $self,$class;
}

#===============================================================================
# パラグラフ
#===============================================================================
sub paragraph {
    my $self  = shift;
    my $wiki  = shift;
    my $name  = shift;
    my $template = shift;
    my $argmon = shift;
#	my $align = shift;
    
    my $error_message = "";

    # 存在しないテンプレートを指定された場合。
    undef $template if !$wiki->page_exists($template);

#	# 表示位置指定がない場合。
#	$align = "left" if $align eq "";


    # エラーチェック
    $error_message = "カレンダ名が指定されていません。" if($name eq "");
#    $error_message = "表示月が指定されていません。" if($argmon eq "");
#    $error_message = "位置指定が間違っています。[$align]" if !(($align eq "center") || ($align eq "right") || ($align eq "left"));
    return Util::paragraph_error($error_message) if !($error_message eq "");
    
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime(time());
    $year += 1900;
    $mon  += 1;

    my $id = "";
    # 表示月指定を解釈
    if ($argmon =~ /(\d*)next/i) { # 相対指定（次月）
	my $step = ($1 > 0) ? $1 : 1;
	$mon += $step;
	$id = "calendar-${step}next";
    } elsif ($argmon =~ /(\d*)prev/i) {	# 相対指定（前月）
	my $step = ($1 > 0) ? $1 : 1;
	$mon -= $step;
	$id = "calendar-${step}prev";
    } elsif ($argmon =~ /(\d+)/) { # 絶対指定
	if ($1>=1 and $1<=12) {
	    $year += (($1 - $mon) >  6) ? -1 : 0;
	    $year += (($1 - $mon) < -6) ?  1 : 0;
	    $mon = $1;
	    $id = "calendar-$1";
	}
    } else {			# 指定なし
    }
    # 年月の正規化
    if ($mon > 0) {
	$year += int (($mon - 1) / 12);
    } else {
	$year += int (($mon - 12) / 12);
    }
    $mon = ($mon - 1) % 12 + 1;

    return &plugin::calendar::CalendarHandler::make_calendar($wiki,$year,$mon,$name,$template,$id);
}

1;
