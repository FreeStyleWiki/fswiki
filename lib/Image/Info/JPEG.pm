package Image::Info::JPEG;

# Copyright 1999-2000, Gisle Aas.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=begin register

MAGIC: /^\xFF\xD8/

For JPEG files we extract information both from C<JFIF> and C<Exif>
application chunks.

C<Exif> is the file format written by most digital cameras.  This
encode things like timestamp, camera model, focal length, exposure
time, aperture, flash usage, GPS position, etc.  The following web
page contain description of the fields that can be present:

 http://www.ba.wakwak.com/~tsuruzoh/Computer/Digicams/exif-e.html

The C<Exif> spec can be found at:

 http://www.pima.net/standards/it10/PIMA15740/exif.htm

=end register

=cut

use strict;

my %sof = (
   0xC0 => "Baseline",
   0xC1 => "Extended sequential",
   0xC2 => "Progressive",
   0xC3 => "Lossless",
   0xC5 => "Differential sequential",
   0xC6 => "Differential progressive",
   0xC7 => "Differential lossless",
   0xC9 => "Extended sequential, arithmetic coding",
   0xCA => "Progressive, arithmetic coding",
   0xCB => "Lossless, arithmetic coding",
   0xCD => "Differential sequential, arithmetic coding",
   0xCE => "Differential progressive, arithmetic coding",
   0xCF => "Differential lossless, arithmetic coding",
);

sub my_read
{
    my($source, $len) = @_;
    my $buf;
    my $n = read($source, $buf, $len);
    die "read failed: $!" unless defined $n;
    die "short read ($len/$n)" unless $n == $len;
    $buf;
}

BEGIN {
    my $f = ($] >= 5.008) ? <<'EOT' : <<'EOT';
        sub with_io_string (&$) {
	    open(my $fh, "<", \$_[1]);
	    local $_ = $fh;
	    &{$_[0]};
	}
EOT
	sub with_io_string (&$) {
	    require IO::String;
	    local $_ = IO::String->new($_[1]);
	    &{$_[0]};
	    $_->close;
	}
EOT

    #print $f;
    eval $f;
    die $@ if $@;
}

sub process_file
{
    my($info, $fh, $cnf) = @_;
    _process_file($info, $fh, 0);
}

sub _process_file
{
    my($info, $fh, $img_no) = @_;

    my $soi = my_read($fh, 2);
    die "SOI missing" unless $soi eq "\xFF\xD8";

    $info->push_info($img_no, "file_media_type" => "image/jpeg");
    $info->push_info($img_no, "file_ext" => "jpg");

    while (1) {
        my($ff, $mark, $len) = unpack("CCn", my_read($fh, 4));
        last if $ff != 0xFF;
        last if $mark == 0xDA || $mark == 0xD9;  # SOS/EOI
	last if $len < 2;
        process_chunk($info, $img_no, $mark, my_read($fh, $len - 2));
    }
}

sub process_chunk
{
    my($info, $img_no, $mark, $data) = @_;
    #printf "MARK 0x%02X, len=%d\n", $mark, length($data);

    if ($mark == 0xFE) {
        $info->push_info($img_no, Comment => $data);
    }
    elsif ($mark >= 0xE0 && $mark <= 0xEF) {
        process_app($info, $mark, $data) if $img_no == 0;
    }
    elsif ($sof{$mark}) {
        my($precision, $height, $width, $num_comp) =
            unpack("CnnC", substr($data, 0, 6, ""));
	$info->push_info($img_no, "JPEG_Type", $sof{$mark});
	$info->push_info($img_no, "width", $width);
	$info->push_info($img_no, "height", $height);

	for (1..$num_comp) {
	    $info->push_info($img_no, "BitsPerSample", $precision);
	}
	$info->push_info($img_no, "SamplesPerPixel" => $num_comp);

	# XXX need to consider JFIF/Adobe markers to determine this...
	if ($num_comp == 1) {
	    $info->push_info($img_no, "color_type" => "Gray");
	}
	elsif ($num_comp == 3) {
	    $info->push_info($img_no, "color_type" => "YCbCr");  # or RGB ?
	}
	elsif ($num_comp == 4) {
	    $info->push_info($img_no, "color_type" => "CMYK");  # or YCCK ?
	}

	if (1) {
	    my %comp_id_lookup = ( 1 => "Y",
				   2 => "Cb",
				   3 => "Cr",
				   82 => "R",
				   71 => "G",
				   66 => "B" );
	    while (length($data)) {
		my($comp_id, $hv, $qtable) =
		    unpack("CCC", substr($data, 0, 3, ""));
		my $horiz_sf = $hv >> 4 & 0x0f;
		my $vert_sf = $hv & 0x0f;
		$comp_id = $comp_id_lookup{$comp_id} || $comp_id;
		$info->push_info($img_no, "ColorComponents",  [$comp_id, $hv, $qtable]);
		$info->push_info($img_no, "ColorComponentsDecoded", 
				 { ComponentIdentifier => $comp_id, 
				   HorizontalSamplingFactor => $horiz_sf, 
				   VerticalSamplingFactor => $vert_sf, 
				   QuantizationTableDesignator => $qtable } );
	    }
	}
    }
}

sub process_app
{
    my($info, $mark, $data) = @_;
    my $app = $mark - 0xE0;
    my $id = substr($data, 0, 5, "");
    #$info->push_info(0, "Debug", "APP$app $id");
    $id = "$app-$id";
    if ($id eq "0-JFIF\0") {
	process_app0_jfif($info, $data);
    }
    elsif ($id eq "0-JFXX\0") {
	process_app0_jfxx($info, $data);
    }
    elsif ($id eq "1-Exif\0") {
	process_app1_exif($info, $data);
    }
    elsif ($id eq "14-Adobe") {
	process_app14_adobe($info, $data);
    }
    else {
	$info->push_info(0, "App$id", $data);
	#printf "  %s\n", Data::Dump::dump($data);
    }
}

sub process_app0_jfif
{
    my($info, $data) = @_;
    if (length $data < 9) {
	$info->push_info(0, "Debug", "Short JFIF chunk");
	return;
    }
    my($ver_hi, $ver_lo, $unit, $x_density, $y_density, $x_thumb, $y_thumb) =
	unpack("CC C nn CC", substr($data, 0, 9, ""));
    $info->push_info(0, "JFIF_Version", sprintf("%d.%02d", $ver_hi, $ver_lo));

    my $res = $x_density != $y_density || !$unit
	? "$x_density/$y_density" : $x_density;

    if ($unit) {
	$unit = { 0 => "pixels",
		  1 => "dpi",
		  2 => "dpcm"
		}->{$unit} || "jfif-unit-$unit";
	$res .= " $unit";
    }
    $info->push_info(0, "resolution", $res);

    if ($x_thumb || $y_thumb) {
	$info->push_info(1, "width", $x_thumb);
	$info->push_info(1, "height", $y_thumb);
	$info->push_info(1, "ByteCount", length($data));
    }
}

sub process_app0_jfxx
{
    my($info, $data) = @_;
    my($code) = ord(substr($data, 0, 1, ""));
    $info->push_info(1, "JFXX_ImageType",
		     { 0x10 => "JPEG thumbnail",
		       0x11 => "Bitmap thumbnail",
		       0x13 => "RGB thumbnail",
		     }->{$code} || "Unknown extention code $code");

    if ($code == 0x10) {
	eval {
	    with_io_string {
		_process_file($info, $_, 1);
	    } $data;
	};
	$info->push_info(1, "error" => $@) if $@;
    }
}

sub process_app1_exif
{
    my($info, $data) = @_;
    my $null = substr($data, 0, 1, "");
    if ($null ne "\0") {
	$info->push_info(0, "Debug", "Exif chunk does not start with \\0");
	return;
    }

    require Image::TIFF;
    my $t = Image::TIFF->new(\$data);

    for my $i (0 .. $t->num_ifds - 1) {
	my $ifd = $t->ifd($i);
	for (@$ifd) {
	    $info->push_info($i, $_->[0], $_->[3]);
	}

	# If we find JPEGInterchangeFormat/JPEGInterchangeFormatLngth,
	# then we should apply process_file kind of recusively to extract
	# information of this (thumbnail) image file...
	if (my($ipos) = $info->get_info($i, "JPEGInterchangeFormat", 1)) {
	    my($ilen) = $info->get_info($i, "JPEGInterchangeFormatLngth", 1);
	    die unless $ilen;
	    my $jdata = substr($data, $ipos, $ilen);
	    #$info->push_info($i, "JPEGImage" => $jdata);

	    with_io_string {
		_process_file($info, $_, $i);
	    } $jdata;
	}

	# Turn XResolution/YResolution into 'resolution'
	my($xres) = $info->get_info($i, "XResolution", 1);
	my($yres) = $info->get_info($i, "YResolution", 1);

	# Samsung Digimax 200 is a totally confused camera that
	# puts rational numbers with 0 as denominator and they
	# also seem to not understand what resolution means.
	for ($xres, $yres) {
	    $_ += 0 if ref($_) eq "Image::TIFF::Rational";
	}

	my($unit) = $info->get_info($i, "ResolutionUnit", 1);
	my $res = "1/1";  # default;
	if ($xres && $yres) {
	    $res = ($xres == $yres) ? $xres : "$xres/$yres";
	}
	$res .= " $unit" if $unit && $unit ne "pixels";
	$info->push_info($i, "resolution", $res);
    }
}

sub process_app14_adobe
{
    my($info, $data) = @_;
    my($version, $flags0, $flags1, $transform) = unpack("nnnC", $data);
    $info->push_info(0, "AdobeTransformVersion" => $version);
    $info->push_info(0, "AdobeTransformFlags" => [$flags0, $flags1]);
    $info->push_info(0, "AdobeTransform" => $transform);
}

1;
