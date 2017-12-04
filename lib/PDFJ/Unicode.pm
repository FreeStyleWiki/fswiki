package PDFJ::Unicode;
use PDFJ::U2C;
use strict;

BEGIN {
	eval { require bytes; };
	bytes->import unless $@;
}

my $euc2unihash;

sub e2u {
	unless( $euc2unihash ) {
		require PDFJ::E2U;
		$euc2unihash = euc2unihash();
	}
	unpack "n", $euc2unihash->{$_[0]};
}

sub euctounicode {
	unless( $euc2unihash ) {
		require PDFJ::E2U;
		$euc2unihash = euc2unihash();
	}
	my $str = shift;
	my $result;
	my @c = split('', $str);
	for( my $j = 0; $j <= $#c; $j++ ) {
		my $c = $c[$j];
		my $ecode;
		if( $c eq "\x8e" ) {
			$ecode = $c.$c[$j+1];
			$j++;
		} elsif( $c eq "\x8f" ) {
			$ecode = $c.$c[$j+1].$c[$j+2];
			$j += 2;
		} elsif( $c lt "\xa0" ) {
			$ecode = $c;
		} else {
			$ecode = $c.$c[$j+1];
			$j++;
		}
		$result .= $euc2unihash->{$ecode};
	}
	$result;
}

my $sjis2unihash;

sub s2u {
	unless( $sjis2unihash ) {
		require PDFJ::S2U;
		$sjis2unihash = sjis2unihash() 
	}
	unpack "n", $sjis2unihash->{$_[0]};
}

sub sjistounicode {
	unless( $sjis2unihash ) {
		require PDFJ::S2U;
		$sjis2unihash = sjis2unihash() 
	}
	my $str = shift;
	my $result;
	my @c = split('', $str);
	for( my $j = 0; $j <= $#c; $j++ ) {
		my $c = $c[$j];
		my $scode;
		if( $c ge "\x81" && $c le "\x9f" || $c ge "\xe0" && $c le "\xfc" ) {
			$scode = $c.$c[$j+1];
			$j++;
		} else {
			$scode = $c;
		}
		$result .= $sjis2unihash->{$scode};
	}
	$result;
}

sub utf8tounicode {
	my $str = shift;
	if( $] > 5.007 ) {
		utf8::downgrade($str, 1);
	}
	$str =~ s/^\xfe\xff//;
	my $result;
	while( $str =~ /([\x00-\x7F])|([\xC0-\xDF])([\x80-\xBF])|([\xE0-\xEF])([\x80-\xBF])([\x80-\xBF])/g ) {
		if( defined $1 ) {
			$result .= "\x00".$1;
		} elsif( $2 ) {
			$result .= pack("n",((ord($2) & 31) << 6)|(ord($3) & 63));
		} else {
			$result .= pack("n",((ord($4) & 15) << 12)|((ord($5) & 63) << 6)|
				(ord($6) & 63));
		}
	}
	$result;
}

my %u2chashes;
sub unicodetocid {
	my($uni, $encoding) = @_; 
	unless( exists $u2chashes{$encoding} ) {
		$u2chashes{$encoding} = PDFJ::U2C::hashes($encoding);
	}
	my $hashes = $u2chashes{$encoding};
	for my $hash(@$hashes) {
		return $hash->{$uni} if $hash->{$uni};
	}
	return '-';
}

1;
