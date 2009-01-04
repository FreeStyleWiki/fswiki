############################################################
#
# <p>ログイン名を表示します</p>
# <pre>
# {{loginname}}
# {{loginname 未ログイン,管理ユーザ,一般ユーザ}}
# </pre>
# <p>
# 引数は適当に省略できます. 
# <code>?</code> をおくと, ログイン名に置換されます.
# </p>
# <p>
# 省略時には名前がでます(未ログイン時は <code>-</code>
# になります).
# 空欄としたいときには <code>&#61;</code> としてください. 
# 先頭の <code>&#61;</code> は常に除去されます.
# </p>
# <p>
# FSWikiコードとして出力されます.
# </p>
#
############################################################
package plugin::loginstate::LoginName;
#use strict;


sub new {
	my $class = shift;
	bless {}, $class;
}


sub inline {
	my $self = shift;
	my $wiki = shift;
	my $login_info = $wiki->get_login_info( $wiki->get_CGI() );

	my $name = '-';
	my $val  = '?';

	if(!defined($login_info)){         # 未ログイン
		$val = $_[0] if($_[0] ne '');
	} elsif($login_info->{type} == 0){ # 管理者
		$name = $login_info->{id};
		$val = $_[1] if($_[1] ne '');
	} else {                           # 一般ユーザ
		$name = $login_info->{id};
		$val = $_[2] if($_[2] ne '');
	}

	$val =~ s/^=//;
	$val =~ s/\\(\\|\?)|(\\\@)|(\?)/$1 ? $1 : $2 ? "" : $name/ge;
	$val;
}

1;
__END__

# Original source
# Copyright YAMASHINA Hio
