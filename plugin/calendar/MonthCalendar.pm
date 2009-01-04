###################################################################
#
# <p>calendarプラグインで作成したページのうち、１ヶ月分のページ内容を一覧表示します。</p>
# <pre>
# {{monthcalendar カレンダ名}}
# </pre>
# <p>
#   デフォルトでは当月の一覧を表示しますが、年月を指定することもできます。
# </p>
# <pre>
# {{monthcalendar カレンダ名,年,月}}
# </pre>
#
###################################################################
package plugin::calendar::MonthCalendar;
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
	my $self  = shift;
	my $wiki  = shift;
	my $name  = shift;
	my $year  = shift;
	my $month = shift;
	
	if ($name eq "") {
		return &Util::paragraph_error("カレンダ名が指定されていません。","WIKI");
	}
	
	if(!defined($year) || !defined($month)){
		my ($sec, $min, $hour, $mday, $mon, $year2, $wday) = localtime(time());
		$year  = $year2 + 1900;
		$month = $mon + 1;
	}
	
	return plugin::calendar::CalendarHandler::make_month_pages($wiki,$year,$month,$name);
}

1;
