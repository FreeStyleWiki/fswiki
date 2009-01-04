############################################################
#
# <p>ファイルを添付するためのフォームを表示します。</p>
# <pre>
# {{attach}}
# </pre>
# <p>
#   添付したファイルはフォームの上に一覧表示されます。
#   同じファイルを添付すると複数表示されてしまうのはご愛嬌です。
#   nolistオプションをつけると一覧表示を行いません。
# </p>
# <pre>
# {{attach nolist}}
# </pre>
#
############################################################
package plugin::attach::Attach;
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
# プラグインの種別を返します
#===========================================================
sub type {
	return "html";
}

#===========================================================
# 添付フォームの表示
#===========================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $option = shift;
	my $cgi    = $wiki->get_CGI;
	my $page   = $cgi->param("page");
	
	if(!defined($option) || $option ne "nolist"){
		if(!defined($self->{$page})){
			$self->{$page} = 1;
		} else {
			$self->{$page}++;
		}
	} else {
		$self->{$page} = undef;
	}
	
	my $buf = "<form action=\"".$wiki->create_url()."\" method=\"post\" enctype=\"multipart/form-data\">\n".
	          "  <input type=\"file\" name=\"file\">\n".
	          "  <input type=\"submit\" name=\"UPLOAD\" value=\" 添 付 \">\n".
	          "  <input type=\"hidden\" name=\"page\" value=\"". Util::escapeHTML($page)."\">\n".
	          "  <input type=\"hidden\" name=\"action\" value=\"ATTACH\">\n";
	
	if(defined($self->{$page})){
		$buf .= "  <input type=\"hidden\" name=\"count\" value=\"".$self->{$page}."\">\n";
	}
	
	$buf .= "</form>\n";

	return $buf;
}

1;
