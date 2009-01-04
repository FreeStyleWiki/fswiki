###################################################################
#
# <p>calendarプラグインで作成したページのうち、当日以前の日付のページ内容を表示します。</p>
# <pre>
# {{recentcalendar カレンダ名}}
# </pre>
# <p>
#   デフォルトでは１件のみ表示しますが、表示件数を指定することもできます。
# </p>
# <pre>
# {{recentcalendar カレンダ名,表示件数}}
# </pre>
# <p>
#   表示件数の後ろに<code>+</code>記号を付け加えることで、
#   今日のページ内容を表示しないこともできます。
# </p>
# <pre>
# {{recentcalendar カレンダ名,表示件数+}}
# </pre>
# <p>
#   段落名を指定することで、各ページの一部分だけを表示することもできます。
#   各ページに「概要」という名前のセクションを用意しておき、
#   一覧では「概要」だけを表示するといったように使います。
# </p>
# <pre>
# {{recentcalendar カレンダ名, [表示件数[+]],段落名}}
# </pre>
#
###################################################################
package plugin::calendar::RecentCalendar;
use strict;
use plugin::calendar::CalendarHandler;
#==================================================================
# コンストラクタ
#==================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==================================================================
# パラグラフ
#==================================================================
sub paragraph {
	my $self    = shift;
	my $wiki    = shift;
	my $name    = shift;
	my $count   = shift;
	my $section = shift;
	
	if($name eq ""){
		return &Util::paragraph_error("カレンダ名が指定されていません。","WIKI");
	}
	if($count eq ''){
		$count = 1;
	}
	return plugin::calendar::CalendarHandler::make_recent_pages($wiki,$name,$count,$section);
}

1;
