# PDFJ::CFF - CFF (Compact Font Format) support
# 2005 Sey <nakajima@netstock.co.jp>

package PDFJ::CFF;
use Carp;
use strict;

my @TopEntry = qw(Header Name TopDICT String GlobalSubr);

sub new {
	my($class, $filehandle) = @_;
	my $orgpos = tell $filehandle;
	my $self = bless {handle => $filehandle, orgpos => $orgpos}, $class;
	$self->read;
	$self;
}

sub read {
	my($self) = @_;
	for my $entryname(@TopEntry) {
		$self->{$entryname} = 
			PDFJ::CFF::Entry->new($entryname, $self->{handle}, $self->{orgpos});
	}
	for my $entryname(@TopEntry) {
		$self->{$entryname}->read_subentry;
	}
}

sub dump {
	my($self, $handle) = @_;
	$handle ||= \*STDOUT;
	for my $entryname(@TopEntry) {
		$self->{$entryname}->dump($handle, $self->{String}{data});
	}
}

# make subset CFF for CID font 
# (CIDCount entry exists and no Encoding entry)
# subset charset, CharStrings and FDSelect entries 
sub subset {
	my($self, $cids) = @_; 
	my @entry;
	# make subset entries
	for my $entryname(@TopEntry) {
		push @entry, $self->{$entryname}->subset($cids);
	}
	# construct CFF
	my $result;
	_subset(\$result, @entry);
	$result;
}

sub _subset {
	my($result, @entry) = @_;
	my @offset;
	for( my $j = 0; $j < @entry; $j++ ) {
		my $entry = $entry[$j];
		if( ref($entry) eq 'ARRAY' ) {
			my $offset = length($$result);
			$offset[$j] = $offset;
			for my $subentry(@{$entry->[1]}) {
				$subentry->[2] += $offset;
			}
			$$result .= $entry->[0];
		} else {
			$$result .= $entry;
		}
	}
	# sub entries
	for( my $j = 0; $j < @entry; $j++ ) {
		my $entry = $entry[$j];
		if( ref($entry) eq 'ARRAY' ) {
			for my $subentry(@{$entry->[1]}) {
				my $offset = $subentry->[1] eq 'O' ? length($$result) :
					length($$result) - $offset[$j];
				substr($$result, $subentry->[2], 5) = 
					PDFJ::CFF::Entry::packUINToperand($offset, 1);
				_subset($result, $subentry->[0]);
			}
		}
	}
}

#---------------------------------------
package PDFJ::CFF::Entry;
use SelfLoader;
use Carp;
use strict;

my @NibbleChar = qw(0 1 2 3 4 5 6 7 8 9 . E E- ? -);

my %DICTOpName = (
	# Top DICT
	'0' => 'version',
	'1' => 'Notice',
	'12 0' => 'Copyright',
	'2' => 'FullName',
	'3' => 'FamilyName',
	'4' => 'Weight',
	'12 1' => 'isFixedPitch',
	'12 2' => 'ItalicAngle',
	'12 3' => 'UnderlinePosition',
	'12 4' => 'UnderlineThickness',
	'12 5' => 'PaintType',
	'12 6' => 'CharstringType',
	'12 7' => 'FontMatrix',
	'13' => 'UniqueID',
	'5' => 'FontBBox',
	'12 8' => 'StrokeWidth',
	'14' => 'XUID',
	'15' => 'charset',
	'16' => 'Encoding',
	'17' => 'CharStrings',
	'18' => 'Private',
	'12 20' => 'SyntheticBase',
	'12 21' => 'PostScript',
	'12 22' => 'BaseFontName',
	'12 23' => 'BaseFontBlend',
	'12 30' => 'ROS',
	'12 31' => 'CIDFontVersion',
	'12 32' => 'CIDFontRevision',
	'12 33' => 'CIDFontType',
	'12 34' => 'CIDCount',
	'12 35' => 'UIDBase',
	'12 36' => 'FDArray',
	'12 37' => 'FDSelect',
	'12 38' => 'FontName',
	
	# Private DICT
	'6' => 'BlueValues',
	'7' => 'OtherBlues',
	'8' => 'FamilyBlues',
	'9' => 'FamilyOtherBlues',
	'12 9' => 'BlueScale',
	'12 10' => 'BlueShift',
	'12 11' => 'BlueFuzz',
	'10' => 'StdHW',
	'11' => 'StdVW',
	'12 12' => 'StemSnapH',
	'12 13' => 'StemSnapV',
	'12 14' => 'ForceBold',
	'12 17' => 'LanguageGroup',
	'12 18' => 'ExpansionFactor',
	'12 19' => 'InitialRandomSeed',
	'19' => 'Subrs',
	'20' => 'defaultWidthX',
	'21' => 'nominalWidthX',
);

my %RequireSID = qw(
	version 1
	Notice 1
	Copyright 1
	FullName 1
	FamilyName 1
	Weight 1
	PostScript 1
	BaseFontName 1
	FontName 1
);

# pre hyphen means no data read
my %EntryType = qw(
	Header      Header
	Name        INDEX
	TopDICT     DICT_INDEX
	String      INDEX
	GlobalSubr  -INDEX
	CharStrings -INDEX
	FDArray     DICT_INDEX
	FDSelect    FDSelect
	Encoding    Encoding
	charset     charset
	Private     DICT
	Subrs       -INDEX
);

# operands: O:offset(0) o:offset(self) SO:[size offset(0)]
# args: G:nGlyphs
my %EntryOperandArgs = qw(
	CharStrings O
	FDArray     O
	FDSelect    OG
	Encoding    O
	charset     OG
	Private     SO
	Subrs       o
);

sub new {
	my($class, $name, $handle, $orgpos, $offset, @args) = @_;
	$offset ||= $handle->tell;
	my $type = $EntryType{$name};
	my $nodataread = $type =~ s/^-//;
	my $self = bless {
		name => $name, 
		type => $type,
		nodataread => $nodataread,
		handle => $handle, 
		orgpos => $orgpos, 
		offset => $offset, 
		}, $class;
	$self->read(@args);
	$self;
}

sub read {
	my($self, @args) = @_;
	$self->rewind;
	my $func = "read_$self->{type}";
	$self->{data} = $self->$func(@args);
	$self->{length} = $self->tell - $self->{offset};
}

sub read_subentry {
	my($self) = @_;
	if( $self->{type} eq 'DICT' ) {
		$self->_read_subentry($self->{data});
	} elsif( $self->{type} eq 'DICT_INDEX' ) {
		for my $dict(@{$self->{data}}) {
			$self->_read_subentry($dict);
		}
	}
}

sub _read_subentry {
	my($self, $dict) = @_;
	my $nGlyphs;
	# sort CharStrings first for getting nGlyphs
	for my $name(sort {$a eq 'CharStrings' ? -1 : $b eq 'CharStrings' ? 1 : 0} 
		keys %$dict) {
		my $eoa = $EntryOperandArgs{$name};
		if( $eoa ) {
			my $value = $dict->{$name}[0];
			my($offset, $arg);
			if( $eoa =~ /o/ ) {
				$offset = $value + $self->{offset};
			} elsif( $eoa =~ /SO/ ) {
				($arg, $offset) = @$value;
				$offset += $self->{orgpos};
			} elsif( $eoa =~ /O/ ) {
				next if $value < 4; # predefined Encoding or charset
				$offset = $value + $self->{orgpos};
			}
			if( $eoa =~ /G/ ) {
				$arg = $nGlyphs;
			}
			my $subdata = PDFJ::CFF::Entry->new($name, 
					$self->{handle}, $self->{orgpos}, $offset, $arg);
			$dict->{entry}{$name} = $subdata;
			if( $name eq 'CharStrings' ) {
				$nGlyphs = $subdata->{INDEXcount};
			}
			$subdata->read_subentry;
		}
	}
}

sub read_Header {
	my($self) = @_;
	my %data;
	$data{major}   = $self->readCard8;
	$data{minor}   = $self->readCard8;
	$data{hdrSize} = $self->readCard8;
	$data{offSize} = $self->readOffSize;
	\%data;
}

sub read_FDSelect {
	my($self, $nGlyphs) = @_;
	my %data;
	$data{format} = $self->readCard8;
	if( $data{format} == 0 ) {
		$data{fds} = $self->_read($nGlyphs);
	} elsif( $data{format} == 3 ) {
		$data{nRanges} = $self->readCard16;
		$data{Range3} = $self->_read($data{nRanges} * 3 + 2); # 2 for sentinel
	} else {
		croak "unknown FDSelect format: $data{format}";
	}
	\%data;
}

sub read_charset {
	my($self, $nGlyphs) = @_;
	my %data;
	$data{format} = $self->readCard8;
	if( $data{format} == 0 ) {
		$data{glyph} = $self->_read(($nGlyphs - 1) * 2);
	} elsif( $data{format} == 1 || $data{format} == 2 ) {
		my $count = 0;
		my @ranges = ();
		my $readfunc = $data{format} == 1 ? \&readCard8 : \&readCard16;
		while(1) {
			my $first = $self->readSID;
			my $nLeft = $self->$readfunc();
			push @ranges, [$first, $nLeft];
			$count += $nLeft + 1;
			last if $count >= $nGlyphs - 1;
		}
		$data{Range} = \@ranges;
	} else {
		croak "unknown carset format: $data{format}";
	}
	\%data;
}

sub read_Encoding {
	my($self) = @_;
	my %data;
	$data{format} = $self->readCard8;
	if( $data{format} & 0x7F == 0 ) {
		$data{nCodes} = $self->readCard8;
		$data{code} = $self->_read($data{nCodes});
	} elsif( $data{format} & 0x7F == 1 ) {
		$data{nRanges} = $self->readCard8;
		$data{Range1} = $self->_read($data{nRanges} * 2);
	}
	if( $data{format} & 0x80 ) {
		$data{nSups} = $self->readCard8;
		$data{Supplement} = $self->_read($data{nSups} * 3);
	}
	\%data;
}

sub read_DICT {
	my($self, $len) = @_;
	return unless $len;
	my %dict;
	my $endpos = $self->tell + $len;
	my($b0, $b1, $b2, $b3, $b4, $rb0, $rb1, $rb2, $rb3, $rb4);
	my(@operands, $rawoperands);
	while($self->tell < $endpos) {
		($b0, $rb0) = $self->readCard8raw;
		if( $b0 >= 0 && $b0 <= 21 ) { # operator
			my($operator, $rawoperator);
			if( $b0 == 12 ) { # 2 bytes operator
				croak "unexpected data end for DICT operator '$b0'"
					unless $self->tell < $endpos;
				($b1, $rb1) = $self->readCard8raw;
				$operator = "$b0 $b1";
				$rawoperator = $rb0.$rb1;
			} else {
				$operator = "$b0";
				$rawoperator = $rb0;
			}
			my $opname = $DICTOpName{$operator} || $operator;
			carp "operator $opname already exists" if exists $dict{$opname};
			$dict{$opname} = (@operands > 1) ? 
				[[@operands], $rawoperands, $rawoperator] : 
				[$operands[0], $rawoperands, $rawoperator];
			@operands = ();
			$rawoperands = '';
		} elsif( ($b0 >= 22 && $b0 <= 27) || $b0 == 31 || $b0 == 255 ) {
			carp "unknown DICT byte: $b0";
		} else { # operand
			my $operand;
			$rawoperands .= $rb0;
			if( $b0 >= 32 && $b0 <= 246 ) {
				$operand = $b0 - 139;
			} elsif( $b0 >= 247 && $b0 <= 250 ) {
				croak "unexpected data end for DICT operand '$b0'"
					unless $self->tell < $endpos;
				($b1, $rb1) = $self->readCard8raw;
				$operand = ($b0 - 247) * 256 + $b1 + 108;
				$rawoperands .= $rb1;
			} elsif( $b0 >= 251 && $b0 <= 254 ) {
				croak "unexpected data end for DICT operand '$b0'"
					unless $self->tell < $endpos;
				($b1, $rb1) = $self->readCard8raw;
				$operand = - ($b0 - 251) * 256 - $b1 - 108;
				$rawoperands .= $rb1;
			} elsif( $b0 == 28 ) {
				croak "unexpected data end for DICT operand '$b0'"
					unless $self->tell < $endpos - 1;
				($b1, $rb1) = $self->readCard8raw;
				($b2, $rb2) = $self->readCard8raw;
				$operand = $b1 << 8 | $b2;
				$rawoperands .= $rb1.$rb2;
			} elsif( $b0 == 29 ) {
				croak "unexpected data end for DICT operand '$b0'"
					unless $self->tell < $endpos - 3;
				($b1, $rb1) = $self->readCard8raw;
				($b2, $rb2) = $self->readCard8raw;
				($b3, $rb3) = $self->readCard8raw;
				($b4, $rb4) = $self->readCard8raw;
				$operand = $b1 << 24 | $b2 << 16 | $b3 << 8 | $b4;
				$rawoperands .= $rb1.$rb2.$rb3.$rb4;
			} elsif( $b0 == 30 ) {
				$operand = '';
				RN:while($self->tell < $endpos) {
					($b1, $rb1) = $self->readCard8raw;
					$rawoperands .= $rb1;
					my $ln = $b1 & 0x0f;
					my $hn = $b1 >> 4;
					for my $n($hn, $ln) {
						last RN if $n == 15;
						$operand .= $NibbleChar[$n];
					}
				}
				$operand += 0;
			} else {
				carp "unknown DICT byte: $b0";
			}
			push @operands, $operand;
		}
	}
	if( @operands ) {
		croak "incomplete operand: @operands";
	}
	\%dict;
}

sub read_DICT_INDEX {
	my($self) = @_;
	$self->_read_INDEX(1);
}

sub read_INDEX {
	my($self) = @_;
	$self->_read_INDEX(0);
}

sub _read_INDEX {
	my($self, $dict) = @_;
	my $nodataread = $self->{nodataread};
	my @result;
	my($count, $offSize, @Offset, $datapos);
	$count = $self->readCard16;
	$self->{INDEXcount} = $count;
	if( $count ) {
		$offSize = $self->readCard8;
		croak "illegal offSize: $offSize" if $offSize > 4;
		for( my $j = 0; $j < $count + 1; $j++ ) {
			push @Offset, $self->readOffset($offSize);
		}
		$self->{INDEXoffSize} = $offSize;
		$self->{INDEXOffset} = \@Offset;
		$datapos = $self->tell - 1;
		$self->{INDEXdatapos} = $datapos;
		if( $nodataread ) {
			$self->seek($datapos + $Offset[$count]);
		} else {
			for( my $j = 0; $j < $count; $j++ ) {
				my $offset = $Offset[$j];
				my $length = $Offset[$j + 1] - $offset;
				$self->seek($datapos + $offset);
				push @result, ($dict ? $self->read_DICT($length) : 
					$self->_seek_read($datapos + $offset, $length));
			}
		}
	}
	\@result;
}

#---------------------------
sub subset {
	my($self, $cids) = @_;
	my $result;
	if( $self->{type} eq 'DICT_INDEX' ) {
		my(@elem, @subentry);
		for my $dict(@{$self->{data}}) {
			my($entry, $subentry) = @{_subset_DICT($dict, $cids)};
			push @elem, $entry;
			push @subentry, $subentry;
		}
		my($entry, $elementoffset) = makeINDEX(\@elem, 1);
		my @allsubentry;
		for( my $j = 0; $j < @subentry; $j++ ) {
			grep {$_->[2] += $elementoffset->[$j]} @{$subentry[$j]};
			push @allsubentry, @{$subentry[$j]};
		}
		$result = [$entry, \@allsubentry];
	} elsif( $self->{type} eq 'DICT' ) {
		$result = _subset_DICT($self->{data}, $cids);
	} else {
		$result = $self->whole;
	}
	$result;
}

sub whole {
	my($self) = @_;
	$self->_seek_read($self->{offset}, $self->{length});
}

sub _oporder {
	my($opname) = @_;
	if( $opname eq 'ROS' ) {
		'0ROS';
	} elsif( $opname eq 'charset' ) {
		'1charset';
	} else {
		$opname;
	}
}

sub _subset_DICT {
	my($dict, $cids) = @_;
	croak "cannot subset CFF which has Encoding entry" 
		if exists $dict->{Encoding};
	my($this, @subentry, $gids);
	for my $name(sort {_oporder($a) cmp _oporder($b)} keys %$dict) {
		next if $name eq 'entry';
		if( $dict->{entry}{$name} ) {
			my $subentry;
			if( $name eq 'charset' ) {
				$subentry = _subset_charset($cids);
				$gids = cids2gids($dict->{entry}{$name}{data}, $cids);
			} elsif( $name eq 'CharStrings' ) {
				$subentry = _subset_CharStrings($dict->{entry}{$name}, $gids);
			} elsif( $name eq 'FDSelect' ) {
				$subentry = 
					_subset_FDSelect($dict->{entry}{$name}{data}, $gids);
			} else {
				$subentry = $dict->{entry}{$name}->subset($cids);
			}
			my $eoa = $EntryOperandArgs{$name};
			my($offsettype, $offsetpos);
			if( $eoa =~ /SO/ ) {
				$offsettype = 'O';
				my $size = ref($subentry) eq 'ARRAY' ? length($subentry->[0]) :
					length($subentry);
				$this .= packUINToperand($size);
			} elsif( $eoa =~ /O/ ) {
				$offsettype = 'O';
			} elsif( $eoa =~ /o/ ) {
				$offsettype = 'o';
			}
			$offsetpos = length($this);
			$this .= packUINToperand(0, 1); # offset = 0 temporarily
			$this .= $dict->{$name}[2]; # operator
			push @subentry, [$subentry, $offsettype, $offsetpos];
		} else {
			# copy original raw operand and operator
			$this .= $dict->{$name}[1].$dict->{$name}[2]; 
		}
	}
	[$this, \@subentry];
}

sub _subset_charset {
	my($cids) = @_;
	my $result;
	$result .= pack('C', 0); # format = 0
	$result .= pack('n*', @$cids); # glyph
	$result;
}

sub _subset_CharStrings {
	my($charstrings, $gids) = @_;
	my $datapos = $charstrings->{INDEXdatapos};
	my $offsets = $charstrings->{INDEXOffset};
	my @css;
	for my $gid(0, @$gids) {
		my $offset = $offsets->[$gid];
		my $length = $offsets->[$gid + 1] - $offset;
		# read data now (no data read on read_CharStrings)
		push @css, $charstrings->_seek_read($datapos + $offset, $length);
	}
	makeINDEX(\@css);
}

sub _subset_FDSelect {
	my($fdselect, $gids) = @_;
	my @fds;
	if( $fdselect->{format} == 0 ) {
		my $fds = $fdselect->{fds};
		for my $gid(0, @$gids) {
			push @fds, substr($fds, $gid, 1);
		}
	} else { # format = 3
		my @gidfds;
		my $nRanges = $fdselect->{nRanges};
		my $Range3 = $fdselect->{Range3};
		for( my $j = 0; $j < $nRanges; $j++ ) {
			my $first = unpack('n', substr($Range3, $j * 3, 2));
			my $fd = unpack('C', substr($Range3, $j * 3 + 2, 1));
			my $next = unpack('n', substr($Range3, ($j + 1) * 3, 2));
			@gidfds[$first .. ($next - 1)] = ($fd) x ($next - $first);
		}
		@fds = map { $gidfds[$_] } (0, @$gids);
	}
	# make FDSelect entry
	my $result;
	$result .= pack('C', 0); # format = 0
	$result .= pack('C*', @fds); # fds
	$result;
}

sub makeINDEX {
	my($array, $needoffset) = @_;
	my $result;
	my @elementoffset;
	my $count = @$array;
	my $data = join '', @$array;
	my $datalen = length($data);
	my $offsize = $datalen < 256 ? 1 : $datalen < 65536 ? 2 : 
		$datalen < 16777216 ? 3 : 4;
	$result .= pack('n', $count);
	$result .= pack('C', $offsize);
	my $offset = 1;
	$result .= packoffset($offset, $offsize);
	for my $element(@$array) {
		push @elementoffset, ($offset - 1);
		$offset += length($element);
		$result .= packoffset($offset, $offsize);
	}
	my $datapos = length($result);
	$result .= $data;
	if( $needoffset ) {
		grep {$_ += $datapos} @elementoffset;
		($result, \@elementoffset);
	} else {
		$result;
	}
}

sub packoffset {
	my($offset, $size) = @_;
	my $result;
	while($size--) {
		$result = pack('C', $offset & 0xff) . $result;
		$offset >>= 8;
	}
	$result;
}

sub packUINToperand {
	my($uint, $f5) = @_; # $f5 forces use 5 bytes format
	my $result;
	if( $f5 || $uint > 32767 ) {
		for(1..4) {
			$result = pack('C', $uint & 0xff).$result;
			$uint >>= 8;
		}
		$result = pack('C', 29).$result;
	} elsif( $uint <= 107 ) {
		$result = pack('C', $uint + 139);
	} elsif( $uint <= 1131 ) {
		$uint -= 108;
		$result = pack('C', ($uint >> 8) + 247).pack('C', $uint & 0xff);
	} elsif( $uint <= 32767 ) {
		$result = pack('C', 28).pack('C', $uint >> 8).pack('C', $uint & 0xff);
	}
	$result;
}

sub cids2gids {
	my($charset, $cids) = @_;
	my(@gids, @glyphcids);
	if( $charset->{format} == 0 ) {
		@glyphcids = (0, unpack("n*", $charset->{glyph})); # 0 for .notdef
	} else { # format = 1 or 2
		if( @{$charset->{Range}} == 1 && $charset->{Range}[0][0] == 1 ) {
			# @gids = @$cids;
		} else {
			@glyphcids = (0);
			for my $range(@{$charset->{Range}}) {
				my($first, $nLeft) = @$range;
				push @glyphcids, $first;
				for( my $j = 1; $j <= $nLeft; $j++ ) {
					push @glyphcids, ($first + $j);
				}
			}
		}
	}
	if( @glyphcids ) {
		my %gids = map {$glyphcids[$_] => $_} (0..$#glyphcids);
		@gids = map {$gids{$_}} @$cids;
	} else {
		@gids = @$cids;
	}
	\@gids;
}

#----------------------------
sub seek {
	my($self, $offset) = @_;
	my $handle = $self->{handle};
	seek $handle, $offset, 0;
}

sub seek_relative {
	my($self, $offset) = @_;
	$self->seek($self->{offset} + $offset);
}

sub rewind {
	my($self) = @_;
	$self->seek($self->{offset});
}

sub tell {
	my($self) = @_;
	my $handle = $self->{handle};
	tell $handle;
}

sub readCard8 {
	my($self) = @_;
	unpack "C", $self->_read(1);
}

sub readCard8raw {
	my($self) = @_;
	my $raw = $self->_read(1);
	(unpack("C", $raw), $raw);
}

sub readCard16 {
	my($self) = @_;
	unpack "n", $self->_read(2);
}

sub readSID {
	my($self) = @_;
	unpack "n", $self->_read(2);
}

sub readOffSize {
	my($self) = @_;
	$self->readCard8;
}

sub readOffset {
	my($self, $size) = @_;
	my $result = 0;
	for( my $j = 0; $j < $size; $j++ ) {
		$result = ($result << 8) + $self->readCard8;
	}
	$result;
}

sub _read {
	my($self, $length) = @_;
	return "" unless $length;
	my $handle = $self->{handle};
	my $buf = "";
	read $handle, $buf, $length or croak "read error";
	$buf;
}

sub _seek_read {
	my($self, $offset, $length) = @_;
	$self->seek($offset);
	$self->_read($length);
}

#---------------------------
sub dump {
	my($self, $handle, $string, $indent) = @_;
	$handle ||= \*STDOUT;
	print $handle $self->_dump($string, $indent);
}

sub _dump {
	my($self, $string, $indent) = @_;
	my $dump;
	$dump .= "\n$indent** $self->{name} ($self->{length} bytes from $self->{offset}) **\n";
	my $func = "dump_$self->{type}";
	$dump .= $self->$func($string, $indent);
	$dump;
}

sub dump_Header {
	my($self) = @_;
	my $data = $self->{data};
	my $dump = <<END;
major: $data->{major}
minor: $data->{minor}
hdrSize: $data->{hdrSize}
offSize: $data->{offSize}
END
	$dump;
}

sub _dump_DICT {
	my($self, $string, $indent, $dict) = @_;
	my $dump;
	my $StandardString = StandardString();
	for my $key(sort keys %$dict) {
		next if $key eq 'entry';
		my $value = $dict->{$key}[0];
		if( ref($value) eq 'ARRAY' ) {
			$dump .= "$indent  $key => [@$value]\n";
		} else {
			if( $RequireSID{$key} ) {
				my $sid = $value;
				if( $value < @$StandardString ) {
					$value = $StandardString->[$sid];
				} elsif( $value < @$StandardString + @$string ) {
					$value = $string->[$sid - @$StandardString];
				} else {
					croak "unknown SID: $sid";
				}
				$dump .= "$indent  $key => $sid($value)\n";
			} else {
				$dump .= "$indent  $key => $value\n";
			}
		}
	}
	if( $dict->{entry} ) {
		for my $entry(keys %{$dict->{entry}}) {
			$dump .= $dict->{entry}{$entry}->_dump($string, "$indent  ");
		}
	}
	$dump;
}

sub dump_DICT {
	my($self, $string, $indent) = @_;
	$self->_dump_DICT($string, $indent, $self->{data});
}

sub dump_DICT_INDEX {
	my($self, $string, $indent) = @_;
	my $dump;
	my $count = $self->{INDEXcount};
	$dump .= "${indent}count: $count\n";
	my $array = $self->{data};
	for(my $j = 0; $j < @$array; $j++ ) { 
		$dump .= $indent."[$j]\n";
		$dump .= $self->_dump_DICT($string, $indent, $array->[$j]);
	}
	$dump;
}

sub dump_INDEX {
	my($self, $string, $indent) = @_;
	my $dump;
	my $count = $self->{INDEXcount};
	$dump .= "${indent}count: $count\n";
	my $array = $self->{data};
	for(my $j = 0; $j < @$array; $j++ ) { 
		my $data = $array->[$j];
		$dump .= $indent."[$j]'$data'\n"; 
	}
	$dump;
}

sub dump_FDSelect {
	my($self, $string, $indent) = @_;
	my $dump;
	my $data = $self->{data};
	$dump .= "${indent}format $data->{format} ";
	if( $data->{format} == 0 ) {
		$dump .= "(".length($data->{fds})." FD selectors)\n";
	} elsif( $data->{format} == 3 ) {
		$dump .= "($data->{nRanges} Range3's)\n";
	}
	$dump;
}

sub dump_charset {
	my($self, $string, $indent) = @_;
	my $dump;
	my $data = $self->{data};
	$dump .= "${indent}format: $data->{format}\n";
	if( $data->{format} == 0 ) {
	} else {
		$dump .= $indent;
		for my $range(@{$data->{Range}}) {
			$dump .= "[@$range] ";
		}
		$dump .= "\n";
	}
	$dump;
}

sub dump_Encoding {
	my($self, $string, $indent) = @_;
	my $dump;
	my $data = $self->{data};
	$dump .= "${indent}format: $data->{format}\n";
	if( $data->{format} & 0x7F == 0 ) {
		$dump .= "${indent}($data->{nCodes} codes)\n";
	} elsif( $data->{format} & 0x7F == 1 ) {
		$dump .= "${indent}($data->{nRanges} Range1's)\n";
	}
	if( $data->{format} & 0x80 ) {
		$dump .= "${indent}($data->{nSups} Supplements)\n";
	}
	$dump;
}

my $StandardString;

sub StandardString {
	$StandardString = _StandardString() unless $StandardString;
	$StandardString;
}

1;

# for SelfLoader;
__DATA__

sub _StandardString {
	return [qw(
	.notdef
	space
	exclam
	quotedbl
	numbersign
	dollar
	percent
	ampersand
	quoteright
	parenleft
	parenright
	asterisk
	plus
	comma
	hyphen
	period
	slash
	zero
	one
	two
	three
	four
	five
	six
	seven
	eight
	nine
	colon
	semicolon
	less
	equal
	greater
	question
	at
	A
	B
	C
	D
	E
	F
	G
	H
	I
	J
	K
	L
	M
	N
	O
	P
	Q
	R
	S
	T
	U
	V
	W
	X
	Y
	Z
	bracketleft
	backslash
	bracketright
	asciicircum
	underscore
	quoteleft
	a
	b
	c
	d
	e
	f
	g
	h
	i
	j
	k
	l
	m
	n
	o
	p
	q
	r
	s
	t
	u
	v
	w
	x
	y
	z
	braceleft
	bar
	braceright
	asciitilde
	exclamdown
	cent
	sterling
	fraction
	yen
	florin
	section
	currency
	quotesingle
	quotedblleft
	guillemotleft
	guilsinglleft
	guilsinglright
	fi
	fl
	endash
	dagger
	daggerdbl
	periodcentered
	paragraph
	bullet
	quotesinglbase
	quotedblbase
	quotedblright
	guillemotright
	ellipsis
	perthousand
	questiondown
	grave
	acute
	circumflex
	tilde
	macron
	breve
	dotaccent
	dieresis
	ring
	cedilla
	hungarumlaut
	ogonek
	caron
	emdash
	AE
	ordfeminine
	Lslash
	Oslash
	OE
	ordmasculine
	ae
	dotlessi
	lslash
	oslash
	oe
	germandbls
	onesuperior
	logicalnot
	mu
	trademark
	Eth
	onehalf
	plusminus
	Thorn
	onequarter
	divide
	brokenbar
	degree
	thorn
	threequarters
	twosuperior
	registered
	minus
	eth
	multiply
	threesuperior
	copyright
	Aacute
	Acircumflex
	Adieresis
	Agrave
	Aring
	Atilde
	Ccedilla
	Eacute
	Ecircumflex
	Edieresis
	Egrave
	Iacute
	Icircumflex
	Idieresis
	Igrave
	Ntilde
	Oacute
	Ocircumflex
	Odieresis
	Ograve
	Otilde
	Scaron
	Uacute
	Ucircumflex
	Udieresis
	Ugrave
	Yacute
	Ydieresis
	Zcaron
	aacute
	acircumflex
	adieresis
	agrave
	aring
	atilde
	ccedilla
	eacute
	ecircumflex
	edieresis
	egrave
	iacute
	icircumflex
	idieresis
	igrave
	ntilde
	oacute
	ocircumflex
	odieresis
	ograve
	otilde
	scaron
	uacute
	ucircumflex
	udieresis
	ugrave
	yacute
	ydieresis
	zcaron
	exclamsmall
	Hungarumlautsmall
	dollaroldstyle
	dollarsuperior
	ampersandsmall
	Acutesmall
	parenleftsuperior
	parenrightsuperior
	twodotenleader
	onedotenleader
	zerooldstyle
	oneoldstyle
	twooldstyle
	threeoldstyle
	fouroldstyle
	fiveoldstyle
	sixoldstyle
	sevenoldstyle
	eightoldstyle
	nineoldstyle
	commasuperior
	threequartersemdash
	periodsuperior
	questionsmall
	asuperior
	bsuperior
	centsuperior
	dsuperior
	esuperior
	isuperior
	lsuperior
	msuperior
	nsuperior
	osuperior
	rsuperior
	ssuperior
	tsuperior
	ff
	ffi
	ffl
	parenleftinferior
	parenrightinferior
	Circumflexsmall
	hyphensuperior
	Gravesmall
	Asmall
	Bsmall
	Csmall
	Dsmall
	Esmall
	Fsmall
	Gsmall
	Hsmall
	Ismall
	Jsmall
	Ksmall
	Lsmall
	Msmall
	Nsmall
	Osmall
	Psmall
	Qsmall
	Rsmall
	Ssmall
	Tsmall
	Usmall
	Vsmall
	Wsmall
	Xsmall
	Ysmall
	Zsmall
	colonmonetary
	onefitted
	rupiah
	Tildesmall
	exclamdownsmall
	centoldstyle
	Lslashsmall
	Scaronsmall
	Zcaronsmall
	Dieresissmall
	Brevesmall
	Caronsmall
	Dotaccentsmall
	Macronsmall
	figuredash
	hypheninferior
	Ogoneksmall
	Ringsmall
	Cedillasmall
	questiondownsmall
	oneeighth
	threeeighths
	fiveeighths
	seveneighths
	onethird
	twothirds
	zerosuperior
	foursuperior
	fivesuperior
	sixsuperior
	sevensuperior
	eightsuperior
	ninesuperior
	zeroinferior
	oneinferior
	twoinferior
	threeinferior
	fourinferior
	fiveinferior
	sixinferior
	seveninferior
	eightinferior
	nineinferior
	centinferior
	dollarinferior
	periodinferior
	commainferior
	Agravesmall
	Aacutesmall
	Acircumflexsmall
	Atildesmall
	Adieresissmall
	Aringsmall
	AEsmall
	Ccedillasmall
	Egravesmall
	Eacutesmall
	Ecircumflexsmall
	Edieresissmall
	Igravesmall
	Iacutesmall
	Icircumflexsmall
	Idieresissmall
	Ethsmall
	Ntildesmall
	Ogravesmall
	Oacutesmall
	Ocircumflexsmall
	Otildesmall
	Odieresissmall
	OEsmall
	Oslashsmall
	Ugravesmall
	Uacutesmall
	Ucircumflexsmall
	Udieresissmall
	Yacutesmall
	Thornsmall
	Ydieresissmall
	001.000
	001.001
	001.002
	001.003
	Black
	Bold
	Book
	Light
	Medium
	Regular
	Roman
	Semibold
)];
}
