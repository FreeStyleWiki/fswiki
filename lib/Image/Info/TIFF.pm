package Image::Info::TIFF;

=begin register

MAGIC: /^MM\x00\x2a/
MAGIC: /^II\x2a\x00/

The C<TIFF> spec can be found at:
http://partners.adobe.com/asn/developer/PDFS/TN/TIFF6.pdf

Also good writeup on exif spec at:
http://www.ba.wakwak.com/~tsuruzoh/Computer/Digicams/exif-e.html

=item TIFF

=end register

=cut

use strict;
use Config;
use Image::TIFF;

sub my_read
{
    my($source, $len) = @_;
    my $buf;
    my $n = read($source, $buf, $len);
    die "read failed: $!" unless defined $n;
    die "short read ($len/$n)" unless $n == $len;
    $buf;
}
sub my_readbytes
{
    my ($fh,$offset,$len) = @_;
    my $curoffset = tell($fh);
    my $buf;
    seek($fh,$offset,0);
    my $n = read($fh,$buf,$len);
    die "short read($len/$n)" unless $n == $len;
    # back to before.
    seek($fh,$curoffset,0);
    return $buf;
}

sub my_readrational
{
    my ($fh,$offset,$byteorder,$count,$ar,$signed) = @_;
    my $curoffset = tell($fh);
    my $buf;
    seek($fh,$offset,0);
    while ($count > 0) {
	my $num;
	my $denom;
	if ($signed) {
	    $num = unpack("l",my_read_order($fh,4,$byteorder));
	    $denom = unpack("l",my_read_order($fh,4,$byteorder));
	} else {
	    $num = unpack("L",my_read_order($fh,4,$byteorder));
	    $denom = unpack("L",my_read_order($fh,4,$byteorder));
	}
	push(@{$ar},new Image::TIFF::Rational($num,$denom));
	$count--;
    }
    # back to before.
    seek($fh,$curoffset,0);
}

sub my_read_order
{
    my($source, $len,$byteorder) = @_;
    my $buf;
    my $n = read($source, $buf, $len);
    # maybe reverse
    if ($byteorder ne $Config{byteorder}) {
	my @bytes = unpack("C$len",$buf);
	my @newbytes;
	# swap bytes
	for (my $i = $len-1; $i >= 0; $i--) {
	    push(@newbytes,$bytes[$i]);
	}
	$buf = pack("C$len",@newbytes);
    }
    die "read failed: $!" unless defined $n;
    die "short read ($len/$n)" unless $n == $len;
    $buf;
}

my %order = (
	     "MM\x00\x2a" => '4321',
	     "II\x2a\x00" => '1234',
	     );

sub process_file
{
    my($info, $fh) = @_;

    my $soi = my_read($fh, 4);
    die "SOI missing" unless (defined($order{$soi}));
    # XXX: should put this info in all pages?
    $info->push_info(0, "file_media_type" => "image/tiff");
    $info->push_info(0, "file_ext" => "tif");

    my $byteorder = $order{$soi};
    #print "TIFF byte order $byteorder, our byte order: $Config{byteorder}\n";
    my $ifdoff = unpack("L",my_read_order($fh,4,$byteorder));
    #print "first dir at $ifdoff\n";
    &process_ifds($info,$fh,0,0,$byteorder,$ifdoff);
}

sub process_ifds {
    my($info, $fh,$page, $tagsseen, $byteorder,$offset) = @_;
    my $curpos = tell($fh);
    seek($fh,$offset,0);

    my $n = unpack("S",my_read_order($fh, 2, $byteorder));
    my $i = 1;
    while ($n > 0) {
	# process one IFD entry
	my $tag = unpack("S",my_read_order($fh,2,$byteorder));
	my $fieldtype = unpack("S",my_read_order($fh,2,$byteorder));
	my $count = unpack("L",my_read_order($fh,4,$byteorder));
	my $offset;
	if ($fieldtype == 3 && $count <= 1) {
	    $offset = unpack("S",my_read_order($fh,2,$byteorder));
	    # skip rest
	    my_read_order($fh,2,$byteorder);
	} else {		# fieldtype == 4
	    $offset = unpack("L",my_read_order($fh,4,$byteorder));
	}
	my $val = "";
	if ($fieldtype == 2) {
	    $val = my_readbytes($fh,$offset,$count);
	} elsif (($fieldtype == 3 || $fieldtype == 4) &&
	    $count == 1) {
	    $val = $offset;
	} elsif ($fieldtype == 3 && $count == 2) {
	    # array
	    $val = [];
	    push(@$val,$offset & 0xffff);
	    push(@$val,$offset >> 16);
	} elsif ($fieldtype == 4 && $count > 1) {
	    $val = [];
	    my $n = $count;
	    my $curoffset = tell($fh);
	    seek($fh,$offset,0);
	    while ($n > 0) {
		$offset = unpack("L",my_read_order($fh,4,$byteorder));
		push(@$val,$offset);
		$n--;
	    }
	    seek($fh,$curoffset,0);
	} elsif ($fieldtype == 5 || $fieldtype == 10) {
	    # rational
	    my $num;
	    my $denom;
	    $val = [];
	    if ($fieldtype == 5) {
		my_readrational($fh,$offset,$byteorder,$count,$val,0);
	    } else {
		#signed rational
		my_readrational($fh,$offset,$byteorder,$count,$val,1);
	    }
	    # get rid of singleton array.
	    if ($#{$val} == 0) {
		$val = $$val[0];
	    }
	}
	#look up tag
	my $tn =  Image::TIFF->exif_tagname($tag);
	if (ref($tn)) {
	    $val = $$tn{$offset};
	    $tn = $$tn{__TAG__};
	}
	if ($tn eq "NewSubfileType") {
	    # start new page if necessary
	    if ($tagsseen) {
		$page++;
		$tagsseen = 0;
	    }
	} else {
	    $tagsseen = 1;
	}
	#print "$i/$page: tag: $tag ($tn), fieldtype: $fieldtype, count: $count, offset: $offset ($val)\n";
	if ($tn eq "ExifOffset") {
	    # parse ExifSubIFD
	    &process_ifds($info,$fh,$byteorder,$offset);
	}
	$info->push_info($page, $tn => $val);
	$n--;
	$i++;
    }
    my $ifdoff = unpack("L",my_read_order($fh,4,$byteorder));
    #print "next dir at $ifdoff\n";
    if ($ifdoff) {
	&process_ifds($info,$fh,$page, $tagsseen, $byteorder,$ifdoff);
    }
    # back to before
    seek($fh,$curpos,0);
}
1;
