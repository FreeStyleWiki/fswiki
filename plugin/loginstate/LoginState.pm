############################################################
#
# <p>ログイン状態を表示します</p>
# <pre>
# {{loginstate}}
# {{loginstate 未ログイン,管理ユーザ,一般ユーザ}}
# </pre>
# <p>
# 引数は適当に省略できます. 
# </p>
# <p>
# 空欄としたいときには <code>&#61;</code> としてください. 
# 先頭の <code>&#61;</code> は常に除去されます.
# </p>
# <p>
# FSWikiコードとして出力されます.
# </p>
#
############################################################
package plugin::loginstate::LoginState;
#use strict;

sub new {
	my $class = shift;
	bless {}, $class;
}


sub inline {
	my $self = shift;
	my $wiki = shift;
	my $login_info = $wiki->get_login_info( $wiki->get_CGI() );
	my $val;

	if(!defined($login_info)){         # 未ログイン
		$val = "NOT LOGIN";
		$val = $_[0] if($_[0] ne '');
	} elsif($login_info->{type} == 0){ # 管理者
		$val = "ADMIN";
		$val = $_[1] if($_[1] ne '');
	} else {                           # 一般ユーザ
		$val = "USER";
		$val = $_[2] if($_[2] ne '');
	}

	$val =~ s/^=//;
	$val;
}

1;
__END__

# Original source
# Copyright YAMASHINA Hio
