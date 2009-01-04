package Image::Info::XPM;
$VERSION = '1.03';
#Path to X11 RGB database
$RGBLIB ||= "/usr/X11R6/lib/X11/rgb.txt";
use strict;
use Image::Xpm;


sub process_file{
    my($info, $source, $opts) = @_;
    my(@comments, @warnings, $i);

    *Image::Xpm::carp  = sub { push @warnings, @_; };
    *Image::Xpm::croak = sub { $info->push_info(0, "error", @_); };
    if( $Image::Xpm::Version cmp '1.08' < 1){
	push @warnings, "This version of Image::Xpm does not support filehandles or scalar references";
	$source = $info->get_info(0, "FileName");
    }
    if( $info->get_info(0, "error") ){
	return; }

    $i = Image::Xpm->new(-file, $source);
    $info->push_info(0, "color_type" => "Indexed-RGB");
    $info->push_info(0, "file_ext" => "xpm");
    $info->push_info(0, "file_media_type" => "image/x-xpixmap");
    $info->push_info(0, "height", $i->get(-height));
    $info->push_info(0, "resolution", "1/1");
    $info->push_info(0, "width", $i->get(-width));
    $info->push_info(0, "BitsPerSample" => 8);
    $info->push_info(0, "SamplesPerPixel", 1);

    $info->push_info(0, "XPM_CharactersPerPixel" => $i->get(-cpp) );
    # XXX is this always?
    $info->push_info(0, "ColorResolution", 8);
    $info->push_info(0, "ColorTableSize" => $i->get(-ncolours) );
    if( $opts->{ColorPalette} ){
	$info->push_info(0, "ColorPalette" => [keys %{$i->get(-cindex)}] );
    }
    if( $opts->{L1D_Histogram} ){
	#Do Histograms
	my(%RGB, @l1dhist, $R, $G, $B, $color);
	for(my $y=0; $y<$i->get(-height); $y++){
	    for(my $x=0; $x<$i->get(-width); $x++){
		$color = $i->xy($x, $y);
		if( $color !~ /^#/ ){
		    unless( exists($RGB{white}) ){
			local $_;
			if( open(RGB, $Image::Info::XPM::RGBLIB) ){
			    while(<RGB>){
				/(\d+)\s+(\d+)\s+(\d+)\s+(.*)/;
				$RGB{$4}=[$1,$2,$3];
			    }
			}
			else{
			    $RGB{white} = "0 but true";
			    push @warnings, "Unable to open RGB database, you may need to set \$Image::Info::XPM::RGBLIB or define \$RGBLIB in ". __FILE__;
			}
		    }
		    $R = $RGB{$color}->[0];
		    $G = $RGB{$color}->[1];
		    $B = $RGB{$color}->[2];
		}
		else{
		    $R = hex(substr($color,1,2));
		    $G = hex(substr($color,3,2));
		    $B = hex(substr($color,5,2));
		}
		if( $opts->{L1D_Histogram} ){
		    $l1dhist[(.3*$R + .59*$G + .11*$B)]++;
		}
	    }
	}
	if( $opts->{L1D_Histogram} ){
	    $info->push_info(0, "L1D_Histogram", [@l1dhist]);
	}
    }
    $info->push_info(0, "HotSpotX" => $i->get(-hotx) );
    $info->push_info(0, "HotSpotY" => $i->get(-hoty) );
    $info->push_info(0, 'XPM_Extension-'.ucfirst($i->get(-extname)) => $i->get(-extlines)) if
	$i->get(-extname);
    push @comments, @{$i->get(-comments)};

    for (@comments) {
	$info->push_info(0, "Comment", $_);
    }
    
    for (@warnings) {
	$info->push_info(0, "Warn", $_);
    }
}
1;
__END__
=pod

=head1 NAME

Image::Info::XPM - XPM support for Image::Info

=head1 SYNOPSIS

 use Image::Info qw(image_info dim);

 my $info = image_info("image.xpm");
 if (my $error = $info->{error}) {
     die "Can't parse image info: $error\n";
 }
 my $color = $info->{color_type};

 my($w, $h) = dim($info);

=head1 DESCRIPTION

This modules supplies the standard key names
except for Compression, Gamma, Interlace, LastModificationTime, as well as:

=over

=item ColorPalette

Reference to an array of all colors used.
This key is only present if C<image_info> is invoked
as C<image_info({ColorPaletteE<gt>=1})>.

=item ColorTableSize

The number of colors the image uses.

=item HotSpotX

The x-coord of the image's hotspot.
Set to -1 if there is no hotspot.

=item HotSpotY

The y-coord of the image's hotspot.
Set to -1 if there is no hotspot.

=item L1D_Histogram

Reference to an array representing a one dimensioanl luminance
histogram. This key is only present if C<image_info> is invoked
as C<image_info($file, L1D_Histogram=E<gt>1)>. The range is from 0 to 255,
however auto-vivification is used so a null field is also 0,
and the array may not actually contain 255 fields.

=item XPM_CharactersPerPixel

This is typically 1 or 2. See L<Image::Xpm>.

=item XPM_Extension-.*

XPM Extensions (the most common is XPMEXT) if present.

=back

=item FILES

This module requires L<Image::Xpm>

I<$Image::Info::XPM::RGBLIB> is set to F</usr/X11R6/lib/X11/rgb.txt>
by default, this is used to resolve textual color names to their RGB
counterparts.

=head1 SEE ALSO

L<Image::Info>, L<Image::Xpm>

=head1 NOTES

For more information about XPM see:

 ftp://ftp.x.org/contrib/libraries/xpm-README.html

=head1 CAVEATS

While the module attempts to be as robust as possible, it may not recognize
older XBMs (Versions 1-3), if this is the case try inserting S</* XPM */>
as the first line.

=head1 AUTHOR

Jerrad Pierce <belg4mit@mit.edu>/<webmaster@pthbb.org>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

=begin register

MAGIC: /(^\/\* XPM \*\/)|(static\s+char\s+\*\w+\[\]\s*=\s*{\s*"\d+)/

See L<Image::Info::XPM> for details.

=end register

=cut
