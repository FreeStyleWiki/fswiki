# PDFJ::TTF - TrueType font support
# 2002 Sey <nakajima@netstock.co.jp>

package PDFJ::TTF;
use PDFJ::Unicode;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::TTfile);

sub new {
	my($class, $fontfile, $offset) = @_;
	$offset ||= 0;
	my $self = bless {fontfile => $fontfile, offset => $offset}, $class;
	$self->read_tabledirs;
	$self;
}

#-------------------------------------------------
# information for PDF
#-------------------------------------------------
sub pdf_info_common {
	my($self) = @_;
	my %info;
	$info{EmbedFlag} = $self->{table}{'OS/2'}{fsType};
	$info{BaseFont} = $self->find_name(1,0,6);
	$info{Ascent} = $self->toglyphunit(
		$self->{table}{'OS/2'}{sTypoAscender} ||
		$self->{table}{hhea}{ascent});
	$info{CapHeight} = $self->toglyphunit($self->{table}{'OS/2'}{sCapHeight}) ||
		$info{Ascent}; # OK?
	$info{Descent} = $self->toglyphunit(
		$self->{table}{'OS/2'}{sTypoDescender} ||
		$self->{table}{hhea}{descent});
	$info{Flags} = 
		($self->{table}{post}{isFixedPitch} ? 1 : 0) |
		($self->{table}{post}{italicAngle} ? 1 << 6 : 0);
	$info{FontBBox} = [$self->toglyphunit(
		@{$self->{table}{head}}{qw(xMin yMin xMax yMax)})];
	$info{FontName} = $info{BaseFont};
	$info{ItalicAngle} = $self->{table}{post}{italicAngle};
	\%info;
}

sub pdf_info_japan {
	my($self, $encoding) = @_;
	my $info = $self->pdf_info_common;
	$info->{Encoding} = $encoding;
	$info->{Flags} |= (1 << 2); # Symbolic
	
	my $upm = $self->{table}{head}{unitsPerEm};
	my @width = @{$self->{table}{hmtx}{hMetrics}{advanceWidth}};
	my $glphs = $self->{table}{maxp}{numGlyphs};
	while( $glphs > @width ) {
		push @width, $width[$#width];
	}
	$info;
}

sub pdf_info_ascii {
	my($self, $encoding) = @_;
	my $info = $self->pdf_info_common;
	$encoding ||= 'mac';
	if( $encoding =~ /^win/i ) {
		$encoding = 'WinAnsiEncoding';
	} elsif( $encoding =~ /^mac/i ) {
		$encoding = 'MacRomanEncoding';
	} else {
		croak "unknown encoding '$encoding'";
	}
	$info->{Encoding} = $encoding;
	$info->{Flags} |= (1 << 5); # Non Symbolic
	$info->{FirstChar} = 0;
	$info->{LastChar} = 255;
	my @gidxs;
	if( $encoding eq 'MacRomanEncoding' ) {
		my $cmap = $self->find_cmap(1,0,0);
		croak "missing cmap for MacRomanEncoding" unless $cmap;
		my $gidx = $cmap->{glyphIndexArray};
		@gidxs = map {$gidx->[$_]} (0..255);
	} else { # WinAnsiEncoding
		@gidxs = $self->unicode2gidx(map {_EncWin2Uni($_)} (0..255));
	}
	my @width = @{$self->{table}{hmtx}{hMetrics}{advanceWidth}};
	my $glphs = $self->{table}{maxp}{numGlyphs};
	while( $glphs > @width ) {
		push @width, $width[$#width];
	}
	$info->{Widths} = [$self->toglyphunit(map {$width[$_]} @gidxs)];
	$info;
}

sub toglyphunit {
	my($self, @values) = @_;
	my $upm = $self->{table}{head}{unitsPerEm} || 0;
	grep {$_ = int(($_ || 0) * 1000 / $upm + 0.5)} @values;
	wantarray ? @values : $values[0];
}

#-------------------------------------------------
# make subset for PDF
#-------------------------------------------------
sub subset {
	my($self, $encoding, @unicodes) = @_; 
		# $encoding: H V Hp Vp
		# @unicodes must be uniqed
	my $result;
	my @gidxs = (0, $self->unicode2gidx(@unicodes)); 
		# 0 for missing glyph required
	my %gidxs;
	@gidxs{@gidxs} = 1 x @gidxs;
	$self->{subset_gidxs} = \%gidxs;
	#my @tags = @{$self->{tags}};
	my @tags = grep {exists $self->{tabledir}{$_}}
		('head','hhea','loca','maxp','cvt ','prep','glyf','hmtx','fpgm');
	my %tabledata;
	for my $tag(sort @tags) {
		my $mname = "subset_$tag";
		$mname =~ s#/#_#g;
		$mname =~ s# #_#g;
		my $func = $self->can($mname);
		my $data = $func ? $self->$func() : $self->whole_table($tag);
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
	# make CIDToGIDMap
	my @cids = (0, map {PDFJ::Unicode::unicodetocid($_, $encoding)} @unicodes);
		# CID 0 -> GID 0 OK?
	my @c2g;
	@c2g[@cids] = @gidxs;
	my $cidtogidmap = pack "n*", map {$_ || 0} @c2g;
if(0) {
	# make CIDSet
	my $cidset;
	for my $cid(@cids) {
		vec($cidset, int($cid / 8) + 7 - ($cid % 8), 1) = 1;
	}
	($result, $cidtogidmap, $cidset);
}
	($result, $cidtogidmap);
}

sub subset_head {
	my($self) = @_;
	my $result = $self->whole_table('head');
	substr($result, 8, 4) = pack "N", 0; # checkSumAdjustment = 0
	$result;
}

sub subset_glyf {
	my($self) = @_;
	my $result = "";
	my $islong = $self->{table}{head}{indexToLocFormat};
	my $size = $islong ? 4 : 2;
	my $mag = $islong ? 1 : 2;
	my $template = $islong ? "NN" : "nn";
	my $loca_offset = $self->{tabledir}{loca}{offset};
	my(@off, @len, %len);
	for my $gidx(sort {$a <=> $b} keys %{$self->{subset_gidxs}}) {
		my($off, $next) = unpack $template, 
			$self->_seek_read($loca_offset + $size * $gidx, $size * 2);
		push @off, $off * $mag;
		my $len = ($next - $off) * $mag;
		push @len, $len;
		$len{$gidx} = $len;
	}
	$self->{subset_glyf_lengths} = \%len;
	my $glyf_offset = $self->{tabledir}{glyf}{offset} || 0;
	for( my $j = 0; $j < @off; $j++ ) {
		$result .= $self->_seek_read($glyf_offset + $off[$j], $len[$j]);
	}
	$result;
}

sub subset_loca {
	my($self) = @_;
	my $result;
	my $lengths = $self->{subset_glyf_lengths} 
		or croak "missing subset_glyf_lengths";
	my $glphs = $self->{table}{maxp}{numGlyphs};
	my $islong = $self->{table}{head}{indexToLocFormat};
	my $template = $islong ? "N" : "n";
	my $loca_offset = $self->{tabledir}{loca}{offset};
	my $last = 0;
	for( my $j = 0; $j < $glphs; $j++ ) {
		$result .= pack $template, $last;
		$last += $lengths->{$j} if $lengths->{$j};
	}
	$result .= pack $template, $last;
	$result;
}

sub Xsubset_loca {
	my($self) = @_;
	my $result;
	my $lengths = $self->{subset_glyf_lengths} 
		or croak "missing subset_glyf_lengths";
	my $islong = $self->{table}{head}{indexToLocFormat};
	my $mag = $islong ? 1 : 2;
	my $template = $islong ? "N" : "n";
	my $off = 0;
	for my $len(@$lengths) {
		$result .= pack $template, ($off / $mag);
		$off += $len;
	}
	$result .= pack $template, ($off / $mag);
	$result;
}

sub Xsubset_hmtx {
	my($self) = @_;
	my $result;
	my @width = @{$self->{table}{hmtx}{hMetrics}{advanceWidth}};
	my $glphs = $self->{table}{maxp}{numGlyphs};
	while( $glphs > @width ) {
		push @width, $width[$#width];
	}
	my @lsb = @{$self->{table}{hmtx}{hMetrics}{leftSideBearing}};
	push @lsb, @{$self->{table}{hmtx}{leftSideBearing}} 
		if $self->{table}{hmtx}{leftSideBearing};
	PDFJ::TTutil::_short2unsigned(\@lsb);
	for my $gidx(@{$self->{subset_gidxs}}) {
		$result .= pack "nn", $width[$gidx], $lsb[$gidx];
	}
	$result;
}

sub whole_table {
	my($self, $tag) = @_;
	return unless exists $self->{tabledir}{$tag};
	$self->seek_table($tag);
	$self->_read($self->table_length($tag));
}

#------------------------------------------------
# read TTF file tables
#------------------------------------------------

sub read_tabledirs {
	my($self) = @_;
	$self->seek($self->{offset});
	$self->_read_hash($self->{subtable}, qw(
		scaler_type:N
		numTables:n
		searchRange:n
		entrySelector:n
		rangeShift:n
		));
	my $type = $self->{subtable}{scaler_type};
	croak "unknown type: $type"
		unless $type == 0x10000 || $type == 0x74727565; # 1.0 or 'true';
	my $tables = $self->{subtable}{numTables};
	my $rby16;
	for( my $r = 1; $r <= $tables; $r *= 2 ) {
		$rby16 = $r;
	}
	croak "illegal searchRange" 
		unless $rby16 * 16 == $self->{subtable}{searchRange};
	my @tags;
	while( $tables-- ) {
		my $tag = $self->_read(4);
		$self->_read_hash($self->{tabledir}{$tag}, qw(
			checksum:N 
			offset:N 
			length:N
			));
		push @tags, $tag;
	}
	$self->{tags} = \@tags;
}

sub reload {
	my($self, $flag) = @_;
	$self->{reload} = $flag if defined $flag;
	$self->{reload};
}

sub table_length {
	my($self, $tag) = @_;
	$self->{tabledir}{$tag}{length};
}

sub checksum_table {
	my($self, $tag) = @_;
	my $length = $self->table_length($tag);
	$self->seek_table($tag);
	my $sum = 0;
	for( my $pos = 0; $pos < $length; $pos += 4 ) {
		$sum += unpack "N", $self->_read(4);
	}
	$sum &= 0xffffffff;
	$sum;
}

sub read_table {
	my($self, @tags) = @_;
	if( $tags[0] eq ':all' ) {
		@tags = keys %{$self->{tabledir}};
	}
	for my $tag(@tags) {
		my $mname = "read_$tag";
		$mname =~ s#/#_#g;
		my $func = $self->can($mname);
		$self->$func() if $func;
	}
}

sub read_head {
	my($self) = @_;
	my $tag = 'head';
	return if exists $self->{table}{$tag} && !$self->reload;
	$self->seek_table($tag);
	$self->_read_hash($self->{table}{$tag}, qw(
		version:N
		fontRevision:N
		checkSumAdjustment:N
		magicNumber:N
		flags:n
		unitsPerEm:n
		createdH:N
		createdL:N
		modifiedH:N
		modifiedL:N
		xMin:m
		yMin:m
		xMax:m
		yMax:m
		macStyle:n
		lowestRecPPEM:n
		fontDirectionHint:m
		indexToLocFormat:m
		glyphDataFormat:m
		));
}

sub read_hhea {
	my($self) = @_;
	my $tag = 'hhea';
	return if exists $self->{table}{$tag} && !$self->reload;
	$self->seek_table($tag);
	$self->_read_hash($self->{table}{$tag}, qw(
		version:N
		ascent:m
		descent:m
		lineGap:m
		advanceWidthMax:n
		minLeftSideBearing:m
		minRightSideBearing:m
		xMaxExtent:m
		caretSlopeRise:m
		caretSlopeRun:m
		caretOffset:m
		reserved:n
		reserved:n
		reserved:n
		reserved:n
		metricDataFormat:n
		numOfLongHorMetrics:n
		));
}

sub read_name {
	my($self) = @_;
	my $tag = 'name';
	return if exists $self->{table}{$tag} && !$self->reload;
	$self->seek_table($tag);
	$self->_read_hash($self->{table}{$tag}, qw(
		format:n
		count:n
		stringOffset:n
		));
	my $count = $self->{table}{$tag}{count};
	while( $count-- ) {
		my %rec;
		$self->_read_hash(\%rec, qw(
			platformID:n
			platformSpecificID:n
			languageID:n
			nameID:n
			length:n
			offset:n
			));
		push @{$self->{table}{$tag}{nameRecord}}, \%rec;
	}
	for my $rec(@{$self->{table}{$tag}{nameRecord}}) {
		$self->seek($self->{tabledir}{$tag}{offset} + 
			$self->{table}{$tag}{stringOffset} + 
			$rec->{offset});
		$rec->{name} = $self->_read($rec->{length});
	}
}

sub find_name {
	my($self, $pid, $psid, $nameid) = @_;
	for my $rec(@{$self->{table}{name}{nameRecord}}) {
		if( $rec->{platformID} == $pid && 
			$rec->{platformSpecificID} == $psid &&
			$rec->{nameID} == $nameid ) {
			return $rec->{name};
		}
	}
	return;
}

sub read_post {
	my($self) = @_;
	my $tag = 'post';
	return if exists $self->{table}{$tag} && !$self->reload;
	$self->seek_table($tag);
	$self->_read_hash($self->{table}{$tag}, qw(
		format:N
		italicAngle:N
		underlinePosition:m
		underlineThickness:m
		isFixedPitch:N
		minMemType42:N
		maxMemType42:N
		minMemType1:N
		maxMemType1:N
		));
}

sub read_maxp {
	my($self) = @_;
	my $tag = 'maxp';
	return if exists $self->{table}{$tag} && !$self->reload;
	$self->seek_table($tag);
	$self->_read_hash($self->{table}{$tag}, qw(
		version:N
		numGlyphs:n
		maxPoints:n
		maxContours:n
		maxComponentPoints:n
		maxComponentContours:n
		maxZones:n
		maxTwilightPoints:n
		maxStorage:n
		maxFunctionDefs:n
		maxInstructionDefs:n
		maxStackElements:n
		maxSizeOfInstructions:n
		maxComponentElements:n
		maxComponentDepth:n
		));
}

sub read_loca {
	my($self) = @_;
	my $tag = 'loca';
	return if exists $self->{table}{$tag} && !$self->reload;
	$self->read_head unless exists $self->{table}{head};
	$self->read_maxp unless exists $self->{table}{maxp};
	$self->seek_table($tag);
	my $glphs = $self->{table}{maxp}{numGlyphs};
	my $offsets = $glphs + 1;
	my $template = $self->{table}{head}{indexToLocFormat} ? 'N' : 'n';
	$self->_read_hash($self->{table}{$tag}, "offset:$template:$offsets");
}

sub read_hmtx {
	my($self) = @_;
	my $tag = 'hmtx';
	return if exists $self->{table}{$tag} && !$self->reload;
	$self->read_hhea unless exists $self->{table}{hhea};
	$self->read_maxp unless exists $self->{table}{maxp};
	croak "'numOfLongHorMetrics' in 'hhea' table required" 
		unless exists $self->{table}{hhea}{numOfLongHorMetrics};
	croak "'numGlyphs' in 'maxp' table required" 
		unless exists $self->{table}{maxp}{numGlyphs};
	my $mtxs = $self->{table}{hhea}{numOfLongHorMetrics};
	my $glphs = $self->{table}{maxp}{numGlyphs};
	my $lsbs = $glphs - $mtxs;
	$self->seek_table($tag);
	my %data;
	while( $mtxs-- ) {
		my($width, $lsb) = unpack "nn", $self->_read(4);
		$lsb = PDFJ::TTutil::_short2signed($lsb);
		push @{$data{hMetrics}{advanceWidth}}, $width;
		push @{$data{hMetrics}{leftSideBearing}}, $lsb;
	}
	$self->_read_hash(\%data, "leftSideBearing:m:$lsbs") if $lsbs;
	$self->{table}{$tag} = \%data;
}

sub read_cmap {
	my($self) = @_;
	my $tag = 'cmap';
	return if exists $self->{table}{$tag} && !$self->reload;
	$self->seek_table($tag);
	$self->_read_hash($self->{table}{$tag}, qw(
		version:n
		numberSubtables:n
		));
	my $count = $self->{table}{$tag}{numberSubtables};
	while( $count-- ) {
		my %st;
		$self->_read_hash(\%st, qw(
			platformID:n
			platformSpecificID:n
			offset:N
			));
		push @{$self->{table}{$tag}{subtable}}, \%st;
	}
	for my $st(@{$self->{table}{$tag}{subtable}}) {
		$self->seek($self->{tabledir}{$tag}{offset} + $st->{offset});
		$self->_read_hash($st, qw(
			format:n
			length:n
			language:n
			));
		if( $st->{format} == 0 ) {
			$self->_read_hash($st, "glyphIndexArray:C:256");
		} elsif( $st->{format} == 4 ) {
			$self->_read_hash($st, qw(
				segCountX2:n
				searchRange:n
				entrySelector:n
				rangeShift:n
				));
			my $segcount = $st->{segCountX2} / 2;
			$self->_read_hash($st, 
				"endCode:n:$segcount",
				"reservedPad:n",
				"startCode:n:$segcount",
				"idDelta:n:$segcount",
				);
			$st->{idRangeOffset_at} = $self->tell;
			$self->_read_hash($st, 
				"idRangeOffset:n:$segcount",
				);
		}
	}
}

sub find_cmap {
	my($self, $pid, $psid, $format) = @_;
	for my $st(@{$self->{table}{cmap}{subtable}}) {
		if( $st->{platformID} == $pid &&
			$st->{platformSpecificID} == $psid &&
			$st->{format} == $format ) {
			return $st;
		}
	}
	return;
}

sub unicode2gidx {
	my($self, @codes) = @_;
	unless( $self->{cmap314_count} ) {
		my $cmap = $self->find_cmap(3,1,4);
		croak "missing cmap for Unicode" unless $cmap;
		$self->{cmap314_count} = $cmap->{segCountX2} / 2;
		$self->{cmap314_start} = $cmap->{startCode};
		$self->{cmap314_end} = $cmap->{endCode};
		$self->{cmap314_offset} = $cmap->{idRangeOffset};
		$self->{cmap314_delta} = $cmap->{idDelta};
		$self->{cmap314_offset_at} = $cmap->{idRangeOffset_at};
	}
	my($count, $start, $end, $offset, $delta, $offset_at) = @$self{qw(
		cmap314_count
		cmap314_start
		cmap314_end
		cmap314_offset
		cmap314_delta
		cmap314_offset_at
		)};
	my @result;
	for my $code(@codes) {
		my $seg = -1;
		for( my $j = 0; $j < $count; $j++ ) {
			next if $end->[$j] < $code;
			$seg = $j if $code >= $start->[$j];
			last;
		}
		if( $seg == -1 ) {
			push @result, 0;
			next;
		}
		if( $offset->[$seg] ) {
			$self->seek($offset_at + $seg * 2 + $offset->[$seg] + 
				($code - $start->[$seg]) * 2);
			my($idx) = unpack "n", $self->_read(2);
			$idx = ($idx + $delta->[$seg]) % 65536 if $idx == 0;
			push @result, $idx;
		} else {
			push @result, ($code + $delta->[$seg]) % 65536;
		}
	}
	wantarray ? @result : $result[0];
}

sub read_OS_2 {
	my($self) = @_;
	my $tag = 'OS/2';
	return if exists $self->{table}{$tag} && !$self->reload;
	$self->seek_table($tag);
	$self->_read_hash($self->{table}{$tag}, qw(
		version:n
		xAvgCharWidth:m
		usWeightClass:n
		usWidthClass:n
		fsType:m
		ySubscriptXSize:m
		ySubscriptYSize:m
		ySubscriptXOffset:m
		ySubscriptYOffset:m
		ySuperscriptXSize:m
		ySuperscriptYSize:m
		ySuperscriptXOffset:m
		ySuperscriptYOffset:m
		yStrikeoutSize:m
		yStrikeoutPosition:m
		sFamilyClass:m
		panose:C:10
		ulCharRange:N:4
		hVendID:C:4
		fsSelection:n
		fsFirstCharIndex:n
		fsLastCharIndex:n
		sTypoAscender:m
		sTypoDescender:m
		sTypoLineGap:m
		usWinAscent:n
		usWinDescent:n
		ulCodePageRange:N:2
		sxHeight:m
		sCapHeight:m
		usDefaultChar:n
		usBreakChar:n
		usMaxContext:n
		), $self->{tabledir}{$tag}{length});
}

sub seek_table {
	my($self, $tag) = @_;
	croak "missing '$tag' table" unless $self->{tabledir}{$tag};
	$self->seek($self->{tabledir}{$tag}{offset});
}

sub dump {
	my($self, $handle, $verbose) = @_;
	$handle ||= \*STDOUT;
	print $handle $self->{fontfile},"\n";
	if( $verbose ) {
		for my $key(keys %{$self->{subtable}}) {
			print $handle "subtable:$key => $self->{subtable}{$key}\n";
		}
		for my $tag(@{$self->{tags}}) {
			my $dir = $self->{tabledir}{$tag};
			print $handle "tabledir($tag):@$dir{qw(checksum offset length)}\n";
		}
	}
	for my $tag(keys %{$self->{table}}) {
		print $handle "\ntable($tag)";
		PDFJ::TTutil::_dump($handle, "", $self->{table}{$tag});
	}
	print $handle "\n";
}

my @EncWin2Uni;
sub _EncWin2Uni {
	my($code) = @_;
	unless( @EncWin2Uni ) {
		while(<DATA>) {
			chomp;
			next if /^#/;
			my(undef, undef, undef, $win, undef, $uni) = split /,/;
			$win += 0;
			$uni = hex($uni);
			$EncWin2Uni[$win] = $uni if $win;
		}
	}
	$EncWin2Uni[$code];
}

#------------------------------------------------
package PDFJ::TTC;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::TTfile);

sub new {
	my($class, $fontfile) = @_;
	my $self = bless {fontfile => $fontfile}, $class;
	$self->read_header;
	$self;
}

sub read_header {
	my($self) = @_;
	$self->seek(0);
	my $tag = $self->_read(4);
	croak "NOT TTC file: $self->{fontfile}" unless $tag eq 'ttcf';
	my $version = unpack "N", $self->_read(4);
	my $fonts = unpack "N", $self->_read(4);
	$self->{fonts} = $fonts;
	$self->_read_hash($self, "diroff:N:$fonts");
}

sub fonts { $_[0]->{fonts} }

sub select {
	my($self, $num) = @_;
	croak "TTC font number out of range" if $num < 0 || $num >= $self->{fonts};
	unless( $self->{font}[$num] ) {
		$self->{font}[$num] = 
			PDFJ::TTF->new($self->{fontfile}, $self->{diroff}[$num]);
	}
	$self->{font}[$num];
}

#------------------------------------------------
package PDFJ::TTfile;
use FileHandle;
use Carp;

sub DESTROY {
	my($self) = @_;
	$self->close;
}

sub open {
	my($self) = @_;
	unless( $self->{handle} ) {
		my $fontfile = $self->{fontfile};
		$self->{handle} = new FileHandle $fontfile
			or croak "cannot open $fontfile";
		binmode $self->{handle};
	}
	$self->{handle};
}

sub close {
	my($self) = @_;
	if( $self->{handle} ) {
		close $self->{handle};
		$self->{handle} = undef;
	}
}

sub seek {
	my($self, $offset) = @_;
	my $handle = $self->open;
	seek $handle, $offset, 0;
}

sub tell {
	my($self) = @_;
	my $handle = $self->open;
	tell $handle;
}

sub _read {
	my($self, $length) = @_;
	return "" unless $length;
	my $handle = $self->open;
	my $buf = "";
	read $handle, $buf, $length or croak "read error";
	$buf;
}

sub _seek_read {
	my($self, $offset, $length) = @_;
	$self->seek($offset);
	$self->_read($length);
}

sub _read_hash {
	$_[1] = {} unless defined $_[1];
	my($self, $hashref, @specs) = @_;
	my($maxlen);
	if( $specs[$#specs] =~ /^\d+$/ ) {
		$maxlen = pop @specs;
	}
	my $handle = $self->open;
	my($length, @keys, %count, @shortsignedkeys, @longsignedkeys, $template, 
		$buf);
	for my $spec(@specs) {
		my($key, $type, $count) = split /:/, $spec;
		$count ||= "";
		push @keys, $key;
		$count{$key} = $count;
		if( $type eq 'C' ) {
			$template .= "C$count";
			$length += $count ? $count : 1;
		} elsif( $type eq 'n' || $type eq 'm' ) {
			$template .= "n$count";
			$length += $count ? 2 * $count : 2;
		} elsif( $type eq 'N' || $type eq 'M' ) {
			$template .= "N$count";
			$length += $count ? 4 * $count : 4;
		} else {
			croak "unknown type '$type'";
		}
		push @shortsignedkeys, $key if $type eq 'm';
		push @longsignedkeys, $key if $type eq 'M';
		last if $maxlen && $length >= $maxlen;
	}
	read $handle, $buf, $length or croak "read error";
	my @data = unpack $template, $buf;
	my $j = 0;
	for my $key(@keys) {
		if( $count{$key} ) {
			$hashref->{$key} = [@data[$j .. $j + $count{$key} - 1]];
			$j += $count{$key};
		} else {
			$hashref->{$key} = $data[$j++];
		}
	}
	for my $key(@shortsignedkeys) {
		$hashref->{$key} = PDFJ::TTutil::_short2signed($hashref->{$key});
	}
	for my $key(@longsignedkeys) {
		$hashref->{$key} = PDFJ::TTutil::_long2signed($hashref->{$key});
	}
}

sub _read_array {
	my($self, $type, $count) = @_;
	my $handle = $self->open;
	my($length, $buf);
	if( $type eq 'C' ) {
		$length = 1;
	} elsif( $type eq 'n' ) {
		$length = 2;
	} elsif( $type eq 'N' ) {
		$length = 4;
	} else {
		croak "unknown type '$type'";
	}
	$length *= $count;
	read $handle, $buf, $length or croak "read error";
	unpack "$type$count", $buf;
}

#------------------------------------------------
package PDFJ::TTutil;

sub _dump {
	my($handle, $indent, $data) = @_;
	if( ref($data) eq 'HASH' ) {
		for my $key(keys %$data) {
			print $handle "\n$indent  $key => ";
			_dump($handle, "$indent  ", $data->{$key});
		}
	} elsif( ref($data) eq 'ARRAY' ) {
		if( ref($data->[0]) ) {
			for( my $j = 0; $j < @$data; $j++ ) {
				print $handle "\n$indent  [$j] ";
				_dump($handle, "$indent  ", $data->[$j]);
			}
		} else {
			print $handle "[", join(',', @$data), "]";
		}
	} else {
		print $handle $data;
	}
}

sub _checksum {
	my($data) = @_;
	my $result = 0;
	for my $value(unpack "N*", $data) {
		$result += $value;
	}
	$result &= 0xffffffff;
	$result;
}

sub _short2signed {
	my($value) = @_;
	if( ref($value) eq 'ARRAY' ) {
		grep {$_ = unpack("s", pack("S", $_))} @$value;
		$value;
	} else {
		unpack("s", pack("S", $value));
	}
}

sub _short2unsigned {
	my($value) = @_;
	if( ref($value) eq 'ARRAY' ) {
		grep {$_ = unpack("S", pack("s", $_))} @$value;
		$value;
	} else {
		unpack("S", pack("s", $value));
	}
}

sub _long2signed {
	my($value) = @_;
	if( ref($value) eq 'ARRAY' ) {
		grep {$_ = unpack("l", pack("L", $_))} @$value;
		$value;
	} else {
		unpack("l", pack("L", $value));
	}
}

#------------------------------------------------
package PDFJ::TTF;  # for __DATA__

1;

__DATA__
# PDF predefined encoding table and Unicode 
# from 'PDF Reference Manual 1.3' and 'Adobe Glyph List 1.2'
# Unicode is hex, others are decimal
# name,Standard,MacRoman,WinAnsi,PDFDoc,Unicode
A,65,65,65,65,0041
AE,225,174,198,198,00C6
Aacute,*,231,193,193,00C1
Acircumflex,*,229,194,194,00C2
Adieresis,*,128,196,196,00C4
Agrave,*,203,192,192,00C0
Aring,*,129,197,197,00C5
Atilde,*,204,195,195,00C3
B,66,66,66,66,0042
C,67,67,67,67,0043
Ccedilla,*,130,199,199,00C7
D,68,68,68,68,0044
E,69,69,69,69,0045
Eacute,*,131,201,201,00C9
Ecircumflex,*,230,202,202,00CA
Edieresis,*,232,203,203,00CB
Egrave,*,233,200,200,00C8
Eth,*,*,208,208,00D0
Euro,*,*,128,160,20AC
F,70,70,70,70,0046
G,71,71,71,71,0047
H,72,72,72,72,0048
I,73,73,73,73,0049
Iacute,*,234,205,205,00CD
Icircumflex,*,235,206,206,00CE
Idieresis,*,236,207,207,00CF
Igrave,*,237,204,204,00CC
J,74,74,74,74,004A
K,75,75,75,75,004B
L,76,76,76,76,004C
Lslash,232,*,*,149,0141
M,77,77,77,77,004D
N,78,78,78,78,004E
Ntilde,*,132,209,209,00D1
O,79,79,79,79,004F
OE,234,206,140,150,0152
Oacute,*,238,211,211,00D3
Ocircumflex,*,239,212,212,00D4
Odieresis,*,133,214,214,00D6
Ograve,*,241,210,210,00D2
Oslash,233,175,216,216,00D8
Otilde,*,205,213,213,00D5
P,80,80,80,80,0050
Q,81,81,81,81,0051
R,82,82,82,82,0052
S,83,83,83,83,0053
Scaron,*,*,138,151,0160
T,84,84,84,84,0054
Thorn,*,*,222,222,00DE
U,85,85,85,85,0055
Uacute,*,242,218,218,00DA
Ucircumflex,*,243,219,219,00DB
Udieresis,*,134,220,220,00DC
Ugrave,*,244,217,217,00D9
V,86,86,86,86,0056
W,87,87,87,87,0057
X,88,88,88,88,0058
Y,89,89,89,89,0059
Yacute,*,*,221,221,00DD
Ydieresis,*,217,159,152,0178
Z,90,90,90,90,005A
Zcaron,*,*,142,153,017D
a,97,97,97,97,0061
aacute,*,135,225,225,00E1
acircumflex,*,137,226,226,00E2
acute,194,171,180,180,00B4
adieresis,*,138,228,228,00E4
ae,241,190,230,230,00E6
agrave,*,136,224,224,00E0
ampersand,38,38,38,38,0026
aring,*,140,229,229,00E5
asciicircum,94,94,94,94,005E
asciitilde,126,126,126,126,007E
asterisk,42,42,42,42,002A
at,64,64,64,64,0040
atilde,*,139,227,227,00E3
b,98,98,98,98,0062
backslash,92,92,92,92,005C
bar,124,124,124,124,007C
braceleft,123,123,123,123,007B
braceright,125,125,125,125,007D
bracketleft,91,91,91,91,005B
bracketright,93,93,93,93,005D
breve,198,249,*,24,02D8
brokenbar,*,*,166,166,00A6
bullet,183,165,149,128,2022
c,99,99,99,99,0063
caron,207,255,*,25,02C7
ccedilla,*,141,231,231,00E7
cedilla,203,252,184,184,00B8
cent,162,162,162,162,00A2
circumflex,195,246,136,26,02C6
colon,58,58,58,58,003A
comma,44,44,44,44,002C
copyright,*,169,169,169,00A9
currency,168,219,164,164,00A4
d,100,100,100,100,0064
dagger,178,160,134,129,2020
daggerdbl,179,224,135,130,2021
degree,*,161,176,176,00B0
dieresis,200,172,168,168,00A8
divide,*,214,247,247,00F7
dollar,36,36,36,36,0024
dotaccent,199,250,*,27,02D9
dotlessi,245,245,*,154,0131
e,101,101,101,101,0065
eacute,*,142,233,233,00E9
ecircumflex,*,144,234,234,00EA
edieresis,*,145,235,235,00EB
egrave,*,143,232,232,00E8
eight,56,56,56,56,0038
ellipsis,188,201,133,131,2026
emdash,208,209,151,132,2014
endash,177,208,150,133,2013
equal,61,61,61,61,003D
eth,*,*,240,240,00F0
exclam,33,33,33,33,0021
exclamdown,161,193,161,161,00A1
f,102,102,102,102,0066
fi,174,222,*,147,FB01
five,53,53,53,53,0035
fl,175,223,*,148,FB02
florin,166,196,131,134,0192
four,52,52,52,52,0034
fraction,164,218,*,135,2215
g,103,103,103,103,0067
germandbls,251,167,223,223,00DF
grave,193,96,96,96,0060
greater,62,62,62,62,003E
guillemotleft,171,199,171,171,00AB
guillemotright,187,200,187,187,00BB
guilsinglleft,172,220,139,136,2039
guilsinglright,173,221,155,137,203A
h,104,104,104,104,0068
hungarumlaut,205,253,*,28,02DD
hyphen,45,45,45,45,00AD
i,105,105,105,105,0069
iacute,*,146,237,237,00ED
icircumflex,*,148,238,238,00EE
idieresis,*,149,239,239,00EF
igrave,*,147,236,236,00EC
j,106,106,106,106,006A
k,107,107,107,107,006B
l,108,108,108,108,006C
less,60,60,60,60,003C
logicalnot,*,194,172,172,00AC
lslash,248,*,*,155,0142
m,109,109,109,109,006D
macron,197,248,175,175,02C9
minus,*,*,*,138,2212
mu,*,181,181,181,03BC
multiply,*,*,215,215,00D7
n,110,110,110,110,006E
nine,57,57,57,57,0039
ntilde,*,150,241,241,00F1
numbersign,35,35,35,35,0023
o,111,111,111,111,006F
oacute,*,151,243,243,00F3
ocircumflex,*,153,244,244,00F4
odieresis,*,154,246,246,00F6
oe,250,207,156,156,0153
ogonek,206,254,*,29,02DB
ograve,*,152,242,242,00F2
one,49,49,49,49,0031
onehalf,*,*,189,189,00BD
onequarter,*,*,188,188,00BC
onesuperior,*,*,185,185,00B9
ordfeminine,227,187,170,170,00AA
ordmasculine,235,188,186,186,00BA
oslash,249,191,248,248,00F8
otilde,*,155,245,245,00F5
p,112,112,112,112,0070
paragraph,182,166,182,182,00B6
parenleft,40,40,40,40,0028
parenright,41,41,41,41,0029
percent,37,37,37,37,0025
period,46,46,46,46,002E
periodcentered,180,225,183,183,2219
perthousand,189,228,137,139,2030
plus,43,43,43,43,002B
plusminus,*,177,177,177,00B1
q,113,113,113,113,0071
question,63,63,63,63,003F
questiondown,191,192,191,191,00BF
quotedbl,34,34,34,34,0022
quotedblbase,185,227,132,140,201E
quotedblleft,170,210,147,141,201C
quotedblright,186,211,148,142,201D
quoteleft,96,212,145,143,2018
quoteright,39,213,146,144,2019
quotesinglbase,184,226,130,145,201A
quotesingle,169,39,39,39,0027
r,114,114,114,114,0072
registered,*,168,174,174,00AE
ring,202,251,176,30,02DA
s,115,115,115,115,0073
scaron,*,*,154,157,0161
section,167,164,167,167,00A7
semicolon,59,59,59,59,003B
seven,55,55,55,55,0037
six,54,54,54,54,0036
slash,47,47,47,47,002F
space,32,32,32,32,0020
space,32,202,160,32,00A0
sterling,163,163,163,163,00A3
t,116,116,116,116,0074
thorn,*,*,254,254,00FE
three,51,51,51,51,0033
threequarters,*,*,190,190,00BE
threesuperior,*,*,179,179,00B3
tilde,196,247,152,31,02DC
trademark,*,170,153,146,2122
two,50,50,50,50,0032
twosuperior,*,*,178,178,00B2
u,117,117,117,117,0075
uacute,*,156,250,250,00FA
ucircumflex,*,158,251,251,00FB
udieresis,*,159,252,252,00FC
ugrave,*,157,249,249,00F9
underscore,95,95,95,95,005F
v,118,118,118,118,0076
w,119,119,119,119,0077
x,120,120,120,120,0078
y,121,121,121,121,0079
yacute,*,*,253,253,00FD
ydieresis,*,216,255,255,00FF
yen,165,180,165,165,00A5
z,122,122,122,122,007A
zcaron,*,*,158,158,017E
zero,48,48,48,48,0030
