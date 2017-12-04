# PDFJ::OTF - OpenType font support
# 2005 Sey <nakajima@netstock.co.jp>

package PDFJ::OTF;
use PDFJ::TTF;
use PDFJ::CFF;
use PDFJ::Unicode;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::TTF);

sub read_CFF {
	my($self) = @_;
	my $tag = 'CFF ';
	return if exists $self->{table}{$tag} && !$self->reload;
	my $handle = $self->open;
	$self->seek_table($tag);
	$self->{table}{$tag} = PDFJ::CFF->new($handle);
}

sub dump_CFF {
	my($self, $handle) = @_;
	print $handle "\ntable(CFF )\n";
	$self->{table}{'CFF '}->dump($handle);
}

sub subset {
	my($self, $encoding, @unicodes) = @_; 
	my $result;
	my @cids = map {PDFJ::Unicode::unicodetocid($_, $encoding)} @unicodes;
	my @tags = grep {exists $self->{tabledir}{$_}}
		('head','hhea','maxp','cvt ','prep','hmtx','fpgm','CFF ');
	my %tabledata;
	for my $tag(sort @tags) {
		my $data;
		if( $tag eq 'CFF ' ) {
			$data = $self->{table}{'CFF '}->subset(\@cids);
		} else {
			my $mname = "subset_$tag";
			$mname =~ s#/#_#g;
			$mname =~ s# #_#g;
			my $func = $self->can($mname);
			$data = $func ? $self->$func() : $self->whole_table($tag);
		}
		my $length = length($data);
		$data .= "\x00" x ((4 - $length % 4) % 4);
		$tabledata{$tag} = {
			data => $data,
			length => $length,
			checksum => PDFJ::TTutil::_checksum($data),
		};
	}
	# subtable
	my $tables = @tags;
	my($range, $sel);
	for( my $tmp = 1, my $j = 0; $tmp <= $tables; $tmp *= 2, $j++ ) {
		$range = $tmp;
		$sel = $j;
	}
	$range *= 16;
	$result = pack "Nnnnn", 
		$self->{subtable}{scaler_type}, 
		$tables,
		$range,
		$sel,
		($tables * 16 - $range);
	# tabledir
	for my $tag(sort @tags) {
		$tabledata{$tag}{diroff} = length($result) + 8;
		$result .= pack "A4NNN",
			$tag,
			$tabledata{$tag}{checksum},
			0, # set offset later
			$tabledata{$tag}{length};
	}
	# tables
	for my $tag(@tags) {
		$tabledata{$tag}{offset} = length $result;
		substr($result, $tabledata{$tag}{diroff}, 4) = 
			pack "N", $tabledata{$tag}{offset};
		$result .= $tabledata{$tag}{data};
	}
	# checkSumAdjustment
	my $csa = 0xb1b0afba - PDFJ::TTutil::_checksum($result);
	$csa += 4294967296 if $csa < 0;
	substr($result, $tabledata{head}{offset} + 8, 4) = pack "N", $csa;
	$result;
}

1;
