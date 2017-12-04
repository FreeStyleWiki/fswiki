# PDFJ::PNG - png support
# 2006 nakajima@netstock.co.jp
package PDFJ::PNG;
use PDFJ::Object;
use FileHandle;
use Compress::Zlib;
use POSIX qw(floor);
use Carp;
use strict;

sub imagestream {
	my($docobj, $file) = @_;
	my($data, $palette, $transparent, $width, $height, $bpc, $colorspace);
	my $fh = new FileHandle $file or croak "cannot open $file";
	binmode($fh);
	seek($fh,8,0);
	while( !eof($fh) ) {
		my $len = readN($fh);
		my $mark = readstr($fh, 4);
#		print "$mark ($len)\n";
		if( $mark eq 'IHDR' ) {
			my($cm,$fm,$im);
			($width, $height, $bpc, $colorspace, $cm,$fm,$im) = 
				unpack('NNCCCCC', readstr($fh, $len));
#			print "$width, $height, $bpc, $colorspace\n";
			croak "PNG Compression ($cm) not supported" if $cm;
			croak "PNG Filter ($fm) not supported" if $fm;
			croak "PNG Interlace ($im) not supported" if $im;
		} elsif( $mark eq 'IDAT') {
			$data .= readstr($fh, $len);
		} elsif( $mark eq 'PLTE') {
			$palette = readstr($fh, $len);
		} elsif( $mark eq 'tRNS') {
			$transparent = readstr($fh, $len);
		} elsif( $mark eq 'IEND') {
			last;
		} else {
			seek($fh, $len, 1);
		}
		readstr($fh, 4); # CRC
	}
	close($fh);
	
	my $num = $docobj->_nextimagenum;
	my $name = "I$num";
	my $stream;
	if( $colorspace == 0 ){ # greyscale
		croak "PNG over 8 bit greyscale not supported" if $bpc > 8;
		$stream = $docobj->indirect(stream(dictionary => {
			Name     => name($name),
			Type     => name("XObject"),
			Subtype  => name("Image"),
			Width    => number($width),
			Height   => number($height),
			BitsPerComponent => number($bpc),
			ColorSpace => name('DeviceGray'),
			DecodeParms => [{
				Predictor => 15,
				BitsPerComponent => number($bpc),
				Colors => 1,
				Columns => number($width),
				}],
			Filter  => [name('FlateDecode')],
			Length   => length($data),
			}, stream => $data));
		if( $transparent ne '' ) {
			my($min, $max) = lminmax(unpack('n*', $transparent));
			$stream->dictionary->set(Mask => 
				[numbers(lminmax(unpack('n*', $transparent)))]);
		}
	} elsif( $colorspace == 2 ) { # RGB
		croak "PNG over 8 bit RGB not supported" if $bpc > 8;
		$stream = $docobj->indirect(stream(dictionary => {
			Name     => name($name),
			Type     => name("XObject"),
			Subtype  => name("Image"),
			Width    => number($width),
			Height   => number($height),
			BitsPerComponent => number($bpc),
			ColorSpace => name('DeviceRGB'),
			DecodeParms => [{
				Predictor => 15,
				BitsPerComponent => number($bpc),
				Colors => 3,
				Columns => number($width),
				}],
			Filter  => [name('FlateDecode')],
			Length   => length($data),
			}, stream => $data));
		if( $transparent ne '' ) {
			$stream->dictionary->set(Mask => 
				[numbers(lminmax3(unpack('n*', $transparent)))]);
		}
	} elsif( $colorspace == 3 ) { # palette
		croak "PNG over 8 bit palette not supported" if $bpc > 8;
		my($pencoded, $pfilter) = $docobj->_makestream(\$palette);
		$stream = $docobj->indirect(stream(dictionary => {
			Name     => name($name),
			Type     => name("XObject"),
			Subtype  => name("Image"),
			Width    => number($width),
			Height   => number($height),
			BitsPerComponent => number($bpc),
			ColorSpace => [name('Indexed'), name('DeviceRGB'), 
				number(int(length($palette) / 3) - 1), 
				$docobj->indirect(stream(dictionary => {
					Filter  => $pfilter,
					Length  => length($pencoded),
				}, stream => $pencoded))],
			DecodeParms => [{
				Predictor => 15,
				BitsPerComponent => number($bpc),
				Colors => 1,
				Columns => number($width),
				}],
			Filter  => [name('FlateDecode')],
			Length   => length($data),
			}, stream => $data));
		if( $transparent ne '' ) {
			$transparent .= "\xFF" x 256;
			my $maskdata;
			my $scanline = ceil($bpc * $width / 8) + 1;
			my $bpp = ceil($bpc / 8);
			my $clearstream = 
				unprocess($bpc, $bpp, 1, $width, $height, $scanline, \$data);
			foreach my $n (0 .. ($height * $width) - 1) {
				vec($maskdata, $n, 8) = 
					vec($transparent, vec($clearstream, $n, $bpc), 8);
			}
			my($sencoded, $sfilter) = $docobj->_makestream(\$maskdata);
			my $smask = $docobj->indirect(stream(dictionary => {
				Type     => name("XObject"),
				Subtype  => name("Image"),
				Width    => number($width),
				Height   => number($height),
				BitsPerComponent => number(8),
				ColorSpace => name('DeviceGray'),
				Filter  => $sfilter,
				Length  => length($sencoded),
				}, stream => $sencoded));
			$stream->dictionary->set(SMask => $smask);
		}
	} elsif( $colorspace == 4 ) { # greyscale+alpha
		croak "PNG over 8 bit greyscale+alpha not supported" if $bpc > 8;
		my $mdata;
		my $maskdata;
		my $scanline = ceil($bpc * 2 * $width / 8) + 1;
		my $bpp = ceil($bpc * 2 / 8);
		my $clearstream = 
			unprocess($bpc, $bpp, 2, $width, $height, $scanline, \$data);
		foreach my $n(0 .. ($height * $width) - 1) {
			vec($maskdata, $n, $bpc) = vec($clearstream, ($n * 2) + 1, $bpc);
			vec($mdata, $n, $bpc) = vec($clearstream, $n * 2, $bpc);
		}
		my($encoded, $filter) = $docobj->_makestream(\$mdata);
		my($sencoded, $sfilter) = $docobj->_makestream(\$maskdata);
		my $smask = $docobj->indirect(stream(dictionary => {
			Type     => name("XObject"),
			Subtype  => name("Image"),
			Width    => number($width),
			Height   => number($height),
			BitsPerComponent => number($bpc),
			ColorSpace => name('DeviceGray'),
			Filter  => $sfilter,
			Length  => length($sencoded),
			}, stream => $sencoded));
		$stream = $docobj->indirect(stream(dictionary => {
			Name     => name($name),
			Type     => name("XObject"),
			Subtype  => name("Image"),
			Width    => number($width),
			Height   => number($height),
			BitsPerComponent => number($bpc),
			ColorSpace => name('DeviceGray'),
			SMask => $smask,
			Filter  => $filter,
			Length   => length($encoded),
			}, stream => $encoded));
	} elsif( $colorspace == 6 ) { # RGB+alpha
		croak "PNG over 8 bit RGB+alpha not supported" if $bpc > 8;
		my $mdata;
		my $maskdata;
		my $scanline = ceil($bpc * 4 * $width / 8) + 1;
		my $bpp = ceil($bpc * 4 / 8);
		my $clearstream = 
			unprocess($bpc, $bpp, 4, $width, $height, $scanline, \$data);
		foreach my $n(0 .. ($height * $width) - 1) {
			vec($maskdata, $n, $bpc) = vec($clearstream, $n * 4 + 3, $bpc);
			vec($mdata, $n * 3, $bpc) = vec($clearstream, $n * 4, $bpc);
			vec($mdata, $n * 3 + 1, $bpc) = vec($clearstream, $n * 4 + 1, $bpc);
			vec($mdata, $n * 3 + 2, $bpc) = vec($clearstream, $n * 4 + 2, $bpc);
		}
		my($encoded, $filter) = $docobj->_makestream(\$mdata);
		my($sencoded, $sfilter) = $docobj->_makestream(\$maskdata);
		my $smask = $docobj->indirect(stream(dictionary => {
			Type     => name("XObject"),
			Subtype  => name("Image"),
			Width    => number($width),
			Height   => number($height),
			BitsPerComponent => number($bpc),
			ColorSpace => name('DeviceGray'),
			Filter  => $sfilter,
			Length  => length($sencoded),
			}, stream => $sencoded));
		$stream = $docobj->indirect(stream(dictionary => {
			Name     => name($name),
			Type     => name("XObject"),
			Subtype  => name("Image"),
			Width    => number($width),
			Height   => number($height),
			BitsPerComponent => number($bpc),
			ColorSpace => name('DeviceRGB'),
			SMask => $smask,
			Filter  => $filter,
			Length   => length($encoded),
			}, stream => $encoded));
	} else {
		croak "PNG color space type $colorspace not supported";
	}
	($name, $stream);
}

sub readN {
	my($fh) = @_;
	my $buf;
	read($fh, $buf, 4);
	unpack('N', $buf);
}

sub readstr {
	my($fh, $len) = @_;
	my $buf;
	read($fh, $buf, $len);
	$buf;
}

sub lminmax {
	my($min, $max);
	for(@_) {
		if( defined $max ) {
			$max = $_ if $max < $_;
		} else {
			$max = $_;
		}
		if( defined $min ) {
			$min = $_ if $min > $_;
		} else {
			$min = $_;
		}
	}
	($min, $max);
}

sub lminmax3 {
	my($min, $max);
	my $n = int(@_ / 3) - 1;
	my @result;
	push @result, lminmax(@_[map {$_ * 3} (0..$n)]);
	push @result, lminmax(@_[map {$_ * 3 + 1} (0..$n)]);
	push @result, lminmax(@_[map {$_ * 3 + 2} (0..$n)]);
	@result;
}

sub ceil {
	my($num) = @_;
	my $ceil = int($num);
	$ceil++ if $ceil != $num;
	$ceil;
}

# below subroutines from PDF::API2
sub PaethPredictor {
    my ($a, $b, $c)=@_;
    my $p = $a + $b - $c;
    my $pa = abs($p - $a);
    my $pb = abs($p - $b);
    my $pc = abs($p - $c);
    if(($pa <= $pb) && ($pa <= $pc)) {
        return $a;
    } elsif($pb <= $pc) {
        return $b;
    } else {
        return $c;
    }
}

sub unprocess {
	my ($bpc,$bpp,$comp,$width,$height,$scanline,$sstream)=@_;
	my $stream=uncompress($$sstream);
	my $prev='';
	my $clearstream='';
	foreach my $n (0..$height-1) {
		my $line=substr($stream,$n*$scanline,$scanline);
		my $filter=vec($line,0,8);
		my $clear='';
		$line=substr($line,1);
		if($filter==0) {
			$clear=$line;
		} elsif($filter==1) {
			foreach my $x (0..length($line)-1) {
				vec($clear,$x,8)=(vec($line,$x,8)+vec($clear,$x-$bpp,8))%256;
			}
		} elsif($filter==2) {
			foreach my $x (0..length($line)-1) {
				vec($clear,$x,8)=(vec($line,$x,8)+vec($prev,$x,8))%256;
			}
		} elsif($filter==3) {
			foreach my $x (0..length($line)-1) {
				vec($clear,$x,8)=(vec($line,$x,8)+floor((vec($clear,$x-$bpp,8)+vec($prev,$x,8))/2))%256;
			}
		} elsif($filter==4) {
			foreach my $x (0..length($line)-1) {
				vec($clear,$x,8)=(vec($line,$x,8)+PaethPredictor(vec($clear,$x-$bpp,8),vec($prev,$x,8),vec($prev,$x-$bpp,8)))%256;
			}
		}
		$prev=$clear;
		foreach my $x (0..($width*$comp)-1) {
			vec($clearstream,($n*$width*$comp)+$x,$bpc)=vec($clear,$x,$bpc);
		}
	}
	return($clearstream);
}

1;
