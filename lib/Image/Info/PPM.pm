package Image::Info::PPM;

# Copyright 2000, Gisle Aas.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=begin register

MAGIC: /^P[1-6]/;

=item PBM/PGM/PPM

All information available is extracted.

=end register

=cut

use strict;

sub process_file
{
    my($info, $fh) = @_;


    my @header;
    my $type;
    my $num_wanted = 3;
    my $binary;

    local($/, $_) = ("\n");
    while (<$fh>) {
	if (s/#\s*(.*)//) {
	    $info->push_info(0, "Comment", $1);
	}
	push(@header, split(' '));
	if (!$type && @header) {
	    $type = shift(@header);
	    $type =~ s/^P// || die;
	    $binary++ if $type > 3;
	    $type = "p" . qw/p b g/[$type % 3] . "m";
	    $num_wanted = 2 if $type eq "pbm";
	}

	for (@header) {
	    unless (/^\d+$/) {
		die "Badly formatted $type file";
	    }
	}

	next unless @header >= $num_wanted;

	# Now we know everything there is to know...
	$info->push_info(0, "file_media_type" => "image/$type");
	$info->push_info(0, "file_ext" => "$type");
	$info->push_info(0, "width", shift @header);
	$info->push_info(0, "height", shift @header);
	$info->push_info(0, "resolution", "1/1");
	if ($type eq "ppm") {
	    $info->push_info(0, "color_type", "RGB");
	    $info->push_info(0, "SamlesPerPixel", 3);
	    if ($binary) {
		for (1..3) {
		    $info->push_info(0, "BitsPerSample", 8);
		}
	    }
	}
	else {
	    $info->push_info(0, "color_type", "Gray");
	    $info->push_info(0, "SamlesPerPixel", 1);
	    $info->push_info(0, "BitsPerSample", ($type eq "pbm") ? 1 : 8)
		if $binary;
	}
	$info->push_info(0, "MaxSampleValue", shift @header) if $type ne "pbm";
	last;
    }
}

1;
