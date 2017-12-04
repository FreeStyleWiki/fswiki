# PDFJ.pm
# PDF for Japanese
# 2001-2014 Sey <nakajima@netstock.co.jp>
package PDFJ;
use PDFJ::Object;
use Carp;
use strict;
use vars qw($VERSION @EXFUNC %Default);

$VERSION = "0.91RC1";

# no I18N::Japanese; for jperl
BEGIN {
	eval { require I18N::Japanese; };
	I18N::Japanese->unimport() unless($@);
}

# use bytes for Perl5.8
BEGIN {
	eval { require bytes; };
	bytes->import unless $@;
}

@EXFUNC = qw(
	PDFJ::Doc::Doc
	PDFJ::TextStyle::TStyle PDFJ::Text::Text 
	PDFJ::NewLine::NewLine PDFJ::Outline::Outline PDFJ::Dest::Dest 
	PDFJ::Null::Null PDFJ::Space::Space
	PDFJ::ParagraphStyle::PStyle PDFJ::Paragraph::Paragraph 
	PDFJ::BlockStyle::BStyle PDFJ::Block::Block PDFJ::NewBlock::NewBlock
	PDFJ::BlockSkip::BlockSkip PDFJ::Shape::Shape
	PDFJ::ShapeStyle::SStyle PDFJ::Color::Color
);

sub import {
	my($pkg, $code, $prefix) = @_;
	if( $code ) {
		croak "code argument '$code' must be 'SJIS','EUC','UTF8' or 'UNICODE'" 
			unless $code =~ /^(SJIS|EUC|UTF8|UNICODE)$/i;
		$Default{Jcode} = uc($code);
	}
	$prefix ||= "";
	for my $exfunc(@EXFUNC) {
		my $to = caller;
		my($from, $name) = $exfunc =~ /^(.+)::([^:]+)$/;
		no strict 'refs';
		*{"${to}::$prefix$name"} = \&{"${from}::$name"};
	}
}

# BlockSkip() deprecated and PDFJ::BlockSkip class obsoleted
# Below for backward compatibility
sub PDFJ::BlockSkip::BlockSkip {
	my $skip = (@_ == 1 && ref($_[0]) eq 'HASH') ? $_[0]{skip}: $_[0];
	PDFJ::Space->new($skip);
}

$Default{Jcode} = 'SJIS';

$Default{AFontEncoding} = 'WinAnsiEncoding';
$Default{BaseAFont} = 'Times-Roman';
$Default{JFontEncoding} = 
	$Default{Jcode} eq 'SJIS' ? '90ms-RKSJ-H' :
	$Default{Jcode} eq 'EUC' ? 'EUC-H' :
	'UniJIS-UCS2-HW-H';
$Default{BaseJFont} = 'Ryumin-Light';
$Default{CIDSystemInfo}{j} = 'Adobe-Japan1-4';
$Default{CIDSystemInfo}{g} = 'Adobe-GB1-4';
$Default{CIDSystemInfo}{c} = 'Adobe-CNS1-3';
$Default{CIDSystemInfo}{k} = 'Adobe-Korea1-1';

# additional 13,89-92 ku CMap for EUC-(H|V)
$Default{CMapCIDRange}{'EUC-NEC'} = <<END;
<ada1> <adbe> 7555
<adc0> <adc1> 7585
<adc2> <adc2> 8038
<adc3> <adc3> 7588
<adc4> <adc4> 8040
<adc5> <adc5> 7590
<adc6> <adc6> 8042
<adc7> <adc8> 7592
<adc9> <adc9> 8044
<adca> <adcb> 7595
<adcc> <adcc> 8043
<adcd> <adce> 7598
<adcf> <adcf> 8047
<add0> <add6> 7601
<addf> <addf> 8323
<ade0> <ade3> 7608
<ade4> <ade4> 8055
<ade5> <adef> 7613
<adf0> <adf0> 762
<adf1> <adf1> 761
<adf2> <adf2> 769
<adf3> <adf4> 7624
<adf5> <adf5> 765
<adf6> <adf6> 757
<adf7> <adf7> 756
<adf8> <adf9> 7629
<adfa> <adfa> 768
<adfb> <adfb> 748
<adfc> <adfc> 747
<f9a1> <f9fe> 8359
<faa1> <fab5> 8453
<fab6> <fab6> 7680
<fab7> <fafe> 8474
<fba1> <fbfe> 8546
<fca1> <fcee> 8640
<fcf1> <fcfa> 8092
<fcfb> <fcfb> 751
<fcfc> <fcfe> 8005
END

$Default{CMap}{'EUC-NEC-H'} = {
	CMapName => 'EUC-NEC-H',
	UseCMap => 'EUC-H',
	CIDSystemInfo => 'Adobe-Japan1-4',
	CIDRange => $Default{CMapCIDRange}{'EUC-NEC'},
};

$Default{CMap}{'EUC-NEC-V'} = {
	CMapName => 'EUC-NEC-V',
	UseCMap => 'EUC-V',
	CIDSystemInfo => 'Adobe-Japan1-4',
	CIDRange => $Default{CMapCIDRange}{'EUC-NEC'},
};

# $Default{BBox} = [-200,-331,1116,962];
$Default{BBox} = [-150,-331,1143,962];

$Default{SBoxH} = [0,-125,1000,875];
$Default{SBoxV} = [-500,-1000,500,0];

$Default{ULine} = -200;
$Default{OLine} = 900;
$Default{LLine} = -550;
$Default{RLine} = 550;

$Default{ORuby} = 950;
$Default{RRuby} = 750;

$Default{HBaseShift} = 0.125;
$Default{HBaseHeight} = 0.875;

$Default{ParaPreSkipRatio} = 0.5;
$Default{ParaPostSkipRatio} = 0.5;

$Default{SlantRatio} = 0.2;

$Default{HDotXShift} = 0;
$Default{HDotYShift} = 0.7;
$Default{HDot}{SJIS} = "\x81\x45";
$Default{HDot}{EUC} = "\xa1\xa6";
$Default{HDot}{UNICODE} = "\x30\xfb";
$Default{HDot}{UTF8} = "\x30\xfb";

$Default{VDotXShift} = 0.5;
$Default{VDotYShift} = -0.3;
$Default{VDot}{SJIS} = "\x81\x41";
$Default{VDot}{EUC} = "\xa1\xa2";
$Default{VDot}{UNICODE} = "\x30\x01";
$Default{VDot}{UTF8} = "\x30\x01";

$Default{VHShift} = 0.8;
$Default{VAShift} = -0.33;

$Default{SuffixSize} = 0.6;
$Default{USuffixRise} = 0.5;
$Default{LSuffixRise} = -0.15;

$Default{HNote} = 990;
$Default{VNote} = 750;

$Default{Fonts} = {qw(
	Courier               a
	Courier-Bold          a
	Courier-BoldOblique   a
	Courier-Oblique       a
	Helvetica             a
	Helvetica-Bold        a
	Helvetica-BoldOblique a
	Helvetica-Oblique     a
	Times-Bold            a
	Times-BoldItalic      a
	Times-Italic          a
	Times-Roman           a
	Ryumin-Light          j
	GothicBBB-Medium      j
)};

$Default{Encodings} = {qw(
	WinAnsiEncoding       a
	MacRomanEncoding      a
	83pv-RKSJ-H           js
	90pv-RKSJ-H           js
	90ms-RKSJ-H           js
	90ms-RKSJ-V           js
	Add-RKSJ-H            js
	Add-RKSJ-V            js
	Ext-RKSJ-H            js
	Ext-RKSJ-V            js
	EUC-H                 je
	EUC-NEC-H             je
	EUC-V                 je
	EUC-NEC-V             je
	UniJIS-UCS2-HW-H      ju
	UniJIS-UCS2-HW-V      ju
	UniGB-UCS2-H          gu
	UniGB-UCS2-V          gu
	UniCNS-UCS2-H         cu
	UniCNS-UCS2-V         cu
	UniKS-UCS2-H          ku
	UniKS-UCS2-V          ku
)};

$Default{FD}{'Ryumin-Light'} = 
	{
		Type => name('FontDescriptor'),
		Ascent => 723,
		CapHeight => 709,
		Descent => -241,
		Flags => 6,
		FontBBox => [-170,-331,1024,903],
		FontName => name('Ryumin-Light'),
		ItalicAngle => 0,
		StemV => 69,
		XHeight => 450,
		Style => {
			Panose => string(
				value => '010502020300000000000000',
				outputtype => 'hexliteral')
		},
	};

$Default{FD}{'GothicBBB-Medium'} =
	{
		Type => name('FontDescriptor'),
		Ascent => 752,
		CapHeight => 737,
		Descent => -271,
		Flags => 4,
		FontBBox => [-174,-268,1001,944],
		FontName => name('GothicBBB-Medium'),
		ItalicAngle => 0,
		StemV => 99,
		XHeight => 553,
		Style => {
			Panose => string(
				value => '0801020b0500000000000000',
				outputtype => 'hexliteral')
		}
	};

# character class (based on JIS X 4051)
# 0: begin paren
# 1: end paren
# 2: not at top of line
# 3: ?!
# 4: dot
# 5: punc
# 6: leader
# 7: pre unit
# 8: post unit
# 9: zenkaku space
# 10: hirakana
# 11: japanese
# 12: suffixed
# 13: rubied
# 14: number
# 15: unit
# 16: space
# 17: ascii
# 18: special
$Default{Class}{SJIS} = {
	# begin paren
	"\x81\x65" => 0, "\x81\x67" => 0, "\x81\x69" => 0, "\x81\x6b" => 0, 
	"\x81\x6d" => 0, "\x81\x6f" => 0, "\x81\x71" => 0, "\x81\x73" => 0, 
	"\x81\x75" => 0, "\x81\x77" => 0, "\x81\x79" => 0,
	# end paren
	"\x81\x41" => 1, "\x81\x43" => 1,
	"\x81\x66" => 1, "\x81\x68" => 1, "\x81\x6a" => 1, "\x81\x6c" => 1, 
	"\x81\x6e" => 1, "\x81\x70" => 1, "\x81\x72" => 1, "\x81\x74" => 1, 
	"\x81\x76" => 1, "\x81\x78" => 1, "\x81\x7a" => 1,
	# not at top of line
	"\x81\x52" => 2, "\x81\x53" => 2, "\x81\x54" => 2, "\x81\x55" => 2, 
	"\x81\x58" => 2, "\x81\x5b" => 2,
	"\x82\x9f" => 2, "\x82\xa1" => 2, "\x82\xa3" => 2, "\x82\xa5" => 2, 
	"\x82\xa7" => 2, "\x82\xc1" => 2, "\x82\xe1" => 2, "\x82\xe3" => 2, 
	"\x82\xe5" => 2, "\x82\xec" => 2, 
	"\x83\x40" => 2, "\x83\x42" => 2, "\x83\x44" => 2, "\x83\x46" => 2, 
	"\x83\x48" => 2, "\x83\x62" => 2, "\x83\x83" => 2, "\x83\x85" => 2, 
	"\x83\x87" => 2, "\x83\x8e" => 2, "\x83\x95" => 2, "\x83\x96" => 2, 
	# ?!
	"\x81\x48" => 3, "\x81\x49" => 3,
	# dot
	"\x81\x45" => 4, "\x81\x46" => 4, "\x81\x47" => 4, 
	# punc
	"\x81\x42" => 5, "\x81\x44" => 5,
	# leader
	"\x81\x5c" => 6, "\x81\x63" => 6, "\x81\x64" => 6, 
	# pre unit
	"\x81\x8f" => 7, "\x81\x90" => 7, "\x81\x92" => 7, 
	# post unit
	"\x81\x8b" => 8, "\x81\x8c" => 8, "\x81\x8d" => 8, 
	"\x81\x91" => 8, "\x81\x93" => 8, "\x81\xf1" => 8, 
	# zenkaku space
	"\x81\x40" => 9,
};

$Default{PreShift}{SJIS} = {
	# begin paren
	"\x81\x65" => 500, "\x81\x67" => 500, "\x81\x69" => 500, "\x81\x6b" => 500, 
	"\x81\x6d" => 500, "\x81\x6f" => 500, "\x81\x71" => 500, "\x81\x73" => 500, 
	"\x81\x75" => 500, "\x81\x77" => 500, "\x81\x79" => 500,
	# dot
	"\x81\x45" => 250, "\x81\x46" => 250, "\x81\x47" => 250, 
};

$Default{PostShift}{SJIS} = {
	# end paren
	"\x81\x41" => 500, "\x81\x43" => 500,
	"\x81\x66" => 500, "\x81\x68" => 500, "\x81\x6a" => 500, "\x81\x6c" => 500, 
	"\x81\x6e" => 500, "\x81\x70" => 500, "\x81\x72" => 500, "\x81\x74" => 500, 
	"\x81\x76" => 500, "\x81\x78" => 500, "\x81\x7a" => 500,
	# dot
	"\x81\x45" => 250, "\x81\x46" => 250, "\x81\x47" => 250, 
	# punc
	"\x81\x42" => 500, "\x81\x44" => 500,
	# post unit
	"\x81\x8b" => 500, "\x81\x8c" => 500, "\x81\x8d" => 500, 
};

$Default{Class}{EUC} = {
	# begin paren
	"\xa1\xc6" => 0, "\xa1\xc8" => 0, "\xa1\xca" => 0, "\xa1\xcc" => 0, 
	"\xa1\xce" => 0, "\xa1\xd0" => 0, "\xa1\xd2" => 0, "\xa1\xd4" => 0, 
	"\xa1\xd6" => 0, "\xa1\xd8" => 0, "\xa1\xda" => 0, 
	# end paren
	"\xa1\xa2" => 1, "\xa1\xa4" => 1, 
	"\xa1\xc7" => 1, "\xa1\xc9" => 1, "\xa1\xcb" => 1, "\xa1\xcd" => 1, 
	"\xa1\xcf" => 1, "\xa1\xd1" => 1, "\xa1\xd3" => 1, "\xa1\xd5" => 1, 
	"\xa1\xd7" => 1, "\xa1\xd9" => 1, "\xa1\xdb" => 1, 
	# not at top of line
	"\xa1\xb3" => 2, "\xa1\xb4" => 2, "\xa1\xb5" => 2, "\xa1\xb6" => 2, 
	"\xa1\xb9" => 2, "\xa1\xbc" => 2, 
	"\xa4\xa1" => 2, "\xa4\xa3" => 2, "\xa4\xa5" => 2, "\xa4\xa7" => 2, 
	"\xa4\xa9" => 2, "\xa4\xc3" => 2, "\xa4\xe3" => 2, "\xa4\xe5" => 2, 
	"\xa4\xe7" => 2, "\xa4\xee" => 2, 
	"\xa5\xa1" => 2, "\xa5\xa3" => 2, "\xa5\xa5" => 2, "\xa5\xa7" => 2, 
	"\xa5\xa9" => 2, "\xa5\xc3" => 2, "\xa5\xe3" => 2, "\xa5\xe5" => 2, 
	"\xa5\xe7" => 2, "\xa5\xee" => 2, "\xa5\xf5" => 2, "\xa5\xf6" => 2, 
	# ?!
	"\xa1\xa9" => 3, "\xa1\xaa" => 3, 
	# dot
	"\xa1\xa6" => 4, "\xa1\xa7" => 4, "\xa1\xa8" => 4, 
	# punc
	"\xa1\xa3" => 5, "\xa1\xa5" => 5, 
	# leader
	"\xa1\xbd" => 6, "\xa1\xc4" => 6, "\xa1\xc5" => 6, 
	# pre unit
	"\xa1\xef" => 7, "\xa1\xf0" => 7, "\xa1\xf2" => 7, 
	# post unit
	"\xa1\xeb" => 8, "\xa1\xec" => 8, "\xa1\xed" => 8, "\xa1\xf1" => 8, 
	"\xa1\xf3" => 8, "\xa2\xf3" => 8, 
	# zenkaku space
	"\xa1\xa1" => 9, 
};

$Default{PreShift}{EUC} = {
	# begin paren
	"\xa1\xc6" => 500, "\xa1\xc8" => 500, "\xa1\xca" => 500, "\xa1\xcc" => 500, 
	"\xa1\xce" => 500, "\xa1\xd0" => 500, "\xa1\xd2" => 500, "\xa1\xd4" => 500, 
	"\xa1\xd6" => 500, "\xa1\xd8" => 500, "\xa1\xda" => 500, 
	# dot
	"\xa1\xa6" => 250, "\xa1\xa7" => 250, "\xa1\xa8" => 250, 
};

$Default{PostShift}{EUC} = {
	# end paren
	"\xa1\xa2" => 500, "\xa1\xa4" => 500, 
	"\xa1\xc7" => 500, "\xa1\xc9" => 500, "\xa1\xcb" => 500, "\xa1\xcd" => 500, 
	"\xa1\xcf" => 500, "\xa1\xd1" => 500, "\xa1\xd3" => 500, "\xa1\xd5" => 500, 
	"\xa1\xd7" => 500, "\xa1\xd9" => 500, "\xa1\xdb" => 500, 
	# dot
	"\xa1\xa6" => 250, "\xa1\xa7" => 250, "\xa1\xa8" => 250, 
	# punc
	"\xa1\xa3" => 500, "\xa1\xa5" => 500, 
	# post unit
	"\xa1\xeb" => 500, "\xa1\xec" => 500, "\xa1\xed" => 500, 
};

$Default{Class}{UNICODE} = {
	# begin paren
	"\x20\x18" => 0, "\x20\x1c" => 0, "\xff\x08" => 0, "\x30\x14" => 0, 
	"\xff\x3b" => 0, "\xff\x5b" => 0, "\x30\x08" => 0, "\x30\x0a" => 0, 
	"\x30\x0c" => 0, "\x30\x0e" => 0, "\x30\x10" => 0, 
	# end paren
	"\x30\x01" => 1, "\xff\x0c" => 1, 
	"\x20\x19" => 1, "\x20\x1d" => 1, "\xff\x09" => 1, "\x30\x15" => 1, 
	"\xff\x3d" => 1, "\xff\x5d" => 1, "\x30\x09" => 1, "\x30\x0b" => 1, 
	"\x30\x0d" => 1, "\x30\x0f" => 1, "\x30\x11" => 1, 
	# not at top of line
	"\x30\xfd" => 2, "\x30\xfe" => 2, "\x30\x9d" => 2, "\x30\x9e" => 2, 
	"\x30\x05" => 2, "\x30\xfc" => 2, 
	"\x30\x41" => 2, "\x30\x43" => 2, "\x30\x45" => 2, "\x30\x47" => 2, 
	"\x30\x49" => 2, "\x30\x63" => 2, "\x30\x83" => 2, "\x30\x85" => 2, 
	"\x30\x87" => 2, "\x30\x8e" => 2, 
	"\x30\xa1" => 2, "\x30\xa3" => 2, "\x30\xa5" => 2, "\x30\xa7" => 2, 
	"\x30\xa9" => 2, "\x30\xc3" => 2, "\x30\xe3" => 2, "\x30\xe5" => 2, 
	"\x30\xe7" => 2, "\x30\xee" => 2, "\x30\xf5" => 2, "\x30\xf6" => 2, 
	# ?!
	"\xff\x1f" => 3, "\xff\x01" => 3, 
	# dot
	"\x30\xfb" => 4, "\xff\x1a" => 4, "\xff\x1b" => 4, 
	# punc
	"\x30\x02" => 5, "\xff\x0e" => 5, 
	# leader
	"\x20\x15" => 6, "\x20\x26" => 6, "\x20\x25" => 6, 
	# pre unit
	"\xff\xe5" => 7, "\xff\x04" => 7, "\xff\xe1" => 7, 
	# post unit
	"\x00\xb0" => 8, "\x20\x32" => 8, "\x20\x33" => 8, "\xff\xe0" => 8, 
	"\xff\x05" => 8, "\x20\x30" => 8, 
	# zenkaku space
	"\x30\x00" => 9, 
};

$Default{PreShift}{UNICODE} = {
	# begin paren
	"\x20\x18" => 500, "\x20\x1c" => 500, "\xff\x08" => 500, "\x30\x14" => 500, 
	"\xff\x3b" => 500, "\xff\x5b" => 500, "\x30\x08" => 500, "\x30\x0a" => 500, 
	"\x30\x0c" => 500, "\x30\x0e" => 500, "\x30\x10" => 500, 
	# dot
	"\x30\xfb" => 250, "\xff\x1a" => 250, "\xff\x1b" => 250, 
};

$Default{PostShift}{UNICODE} = {
	# end paren
	"\x30\x01" => 500, "\xff\x0c" => 500, 
	"\x20\x19" => 500, "\x20\x1d" => 500, "\xff\x09" => 500, "\x30\x15" => 500, 
	"\xff\x3d" => 500, "\xff\x5d" => 500, "\x30\x09" => 500, "\x30\x0b" => 500, 
	"\x30\x0d" => 500, "\x30\x0f" => 500, "\x30\x11" => 500, 
	# dot
	"\x30\xfb" => 250, "\xff\x1a" => 250, "\xff\x1b" => 250, 
	# punc
	"\x30\x02" => 500, "\xff\x0e" => 500, 
	# post unit
	"\x00\xb0" => 500, "\x20\x32" => 500, "\x20\x33" => 500, 
};

$Default{NoRubyOverlap} = 0;
$Default{RubyPreOverlap} = { map {$_ => 1} (0, 2, 6, 9, 10) };
$Default{RubyPostOverlap} = { map {$_ => 1} (1, 5, 6, 9, 10) };

# glue width
# each element means [min, normal, max, preference]
sub GlueNon { [0, 0, 0] }
sub Glue004 { [0, 0, 250] }
sub Glue0443 { [0, 250, 250, 3] }
sub Glue0223 { [0, 500, 500, 3] }
sub Glue0222 { [0, 500, 500, 2] }
sub Glue222 { [500, 500, 500] }
sub Glue844 { [125, 250, 250] }
sub Glue8421 { [125, 250, 500, 1] }
sub Glue266 { [500, 750, 750] }

$Default{Glue} = [
	# 0: begin paren
	[
		GlueNon,      # 0: begin paren
		GlueNon,      # 1: end paren
		GlueNon,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		GlueNon,      # 6: leader
		GlueNon,      # 7: pre unit
		GlueNon,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		GlueNon,      # 10: hirakana
		GlueNon,      # 11: japanese
		GlueNon,      # 12: suffixed
		GlueNon,      # 13: rubied
		GlueNon,      # 14: number
		GlueNon,      # 15: unit
		Glue004,      # 16: space
		GlueNon,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 1: end paren
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		Glue0222,      # 2: not at top of line
		Glue0222,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		Glue0222,      # 6: leader
		Glue0222,      # 7: pre unit
		Glue0222,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		Glue0222,      # 10: hirakana
		Glue0222,      # 11: japanese
		Glue0222,      # 12: suffixed
		Glue0222,      # 13: rubied
		Glue0222,      # 14: number
		Glue0222,      # 15: unit
		Glue0222,      # 16: space
		Glue0222,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 2: not at top of line
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		Glue004,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		Glue004,      # 6: leader
		Glue004,      # 7: pre unit
		Glue004,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		Glue004,      # 10: hirakana
		Glue004,      # 11: japanese
		Glue8421,      # 12: suffixed
		Glue004,      # 13: rubied
		Glue8421,      # 14: number
		Glue8421,      # 15: unit
		Glue004,      # 16: space
		Glue8421,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 3: ?!
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		GlueNon,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		GlueNon,      # 6: leader
		GlueNon,      # 7: pre unit
		GlueNon,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		GlueNon,      # 10: hirakana
		GlueNon,      # 11: japanese
		Glue8421,      # 12: suffixed
		GlueNon,      # 13: rubied
		Glue8421,      # 14: number
		Glue8421,      # 15: unit
		Glue004,      # 16: space
		Glue8421,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 4: dot
	[
		Glue0443,      # 0: begin paren
		Glue0443,      # 1: end paren
		Glue0443,      # 2: not at top of line
		Glue0443,      # 3: ?!
		Glue0223,      # 4: dot
		Glue0443,      # 5: punc
		Glue0443,      # 6: leader
		Glue0443,      # 7: pre unit
		Glue0443,      # 8: post unit
		Glue0443,      # 9: zenkaku space
		Glue0443,      # 10: hirakana
		Glue0443,      # 11: japanese
		Glue0443,      # 12: suffixed
		Glue0443,      # 13: rubied
		Glue0443,      # 14: number
		Glue0443,      # 15: unit
		Glue0443,      # 16: space
		Glue0443,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 5: punc
	[
		Glue222,      # 0: begin paren
		GlueNon,      # 1: end paren
		Glue222,      # 2: not at top of line
		Glue222,      # 3: ?!
		Glue266,      # 4: dot
		GlueNon,      # 5: punc
		Glue222,      # 6: leader
		Glue222,      # 7: pre unit
		Glue222,      # 8: post unit
		Glue222,      # 9: zenkaku space
		Glue222,      # 10: hirakana
		Glue222,      # 11: japanese
		Glue222,      # 12: suffixed
		Glue222,      # 13: rubied
		Glue222,      # 14: number
		Glue222,      # 15: unit
		Glue222,      # 16: space
		Glue222,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 6: leader
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		Glue004,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		GlueNon,      # 6: leader
		Glue004,      # 7: pre unit
		Glue004,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		Glue004,      # 10: hirakana
		Glue004,      # 11: japanese
		Glue004,      # 12: suffixed
		Glue004,      # 13: rubied
		Glue004,      # 14: number
		Glue004,      # 15: unit
		Glue004,      # 16: space
		Glue004,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 7: pre unit
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		Glue004,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		Glue004,      # 6: leader
		Glue004,      # 7: pre unit
		Glue004,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		Glue004,      # 10: hirakana
		Glue004,      # 11: japanese
		Glue004,      # 12: suffixed
		Glue004,      # 13: rubied
		GlueNon,      # 14: number
		Glue004,      # 15: unit
		Glue004,      # 16: space
		Glue004,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 8: post unit
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		Glue004,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		Glue004,      # 6: leader
		Glue004,      # 7: pre unit
		Glue004,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		Glue004,      # 10: hirakana
		Glue004,      # 11: japanese
		Glue004,      # 12: suffixed
		Glue004,      # 13: rubied
		Glue004,      # 14: number
		Glue004,      # 15: unit
		Glue004,      # 16: space
		Glue004,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 9: zenkaku space
	[
		GlueNon,      # 0: begin paren
		GlueNon,      # 1: end paren
		GlueNon,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		GlueNon,      # 6: leader
		GlueNon,      # 7: pre unit
		GlueNon,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		GlueNon,      # 10: hirakana
		GlueNon,      # 11: japanese
		GlueNon,      # 12: suffixed
		GlueNon,      # 13: rubied
		GlueNon,      # 14: number
		GlueNon,      # 15: unit
		Glue004,      # 16: space
		GlueNon,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 10: hirakana
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		Glue004,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		Glue004,      # 6: leader
		Glue004,      # 7: pre unit
		Glue004,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		Glue004,      # 10: hirakana
		Glue004,      # 11: japanese
		Glue8421,      # 12: suffixed
		Glue004,      # 13: rubied
		Glue8421,      # 14: number
		Glue8421,      # 15: unit
		Glue004,      # 16: space
		Glue8421,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 11: japanese
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		Glue004,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		Glue004,      # 6: leader
		Glue004,      # 7: pre unit
		Glue004,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		Glue004,      # 10: hirakana
		Glue004,      # 11: japanese
		Glue8421,      # 12: suffixed
		Glue004,      # 13: rubied
		Glue8421,      # 14: number
		Glue8421,      # 15: unit
		Glue004,      # 16: space
		Glue8421,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 12: suffixed
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		Glue004,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		Glue004,      # 6: leader
		Glue004,      # 7: pre unit
		Glue004,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		Glue8421,      # 10: hirakana
		Glue8421,      # 11: japanese
		GlueNon,      # 12: suffixed
		Glue8421,      # 13: rubied
		Glue004,      # 14: number
		Glue004,      # 15: unit
		Glue004,      # 16: space
		Glue844,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 13: rubied
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		Glue004,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		Glue004,      # 6: leader
		Glue004,      # 7: pre unit
		Glue004,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		Glue004,      # 10: hirakana
		Glue004,      # 11: japanese
		Glue8421,      # 12: suffixed
		GlueNon,      # 13: rubied
		Glue8421,      # 14: number
		Glue8421,      # 15: unit
		Glue004,      # 16: space
		Glue8421,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 14: number
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		GlueNon,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		Glue004,      # 6: leader
		Glue004,      # 7: pre unit
		GlueNon,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		Glue8421,      # 10: hirakana
		Glue8421,      # 11: japanese
		Glue004,      # 12: suffixed
		Glue8421,      # 13: rubied
		GlueNon,      # 14: number
		Glue8421,      # 15: unit
		Glue004,      # 16: space
		GlueNon,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 15: unit
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		GlueNon,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		Glue004,      # 6: leader
		Glue004,      # 7: pre unit
		Glue004,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		Glue8421,      # 10: hirakana
		Glue8421,      # 11: japanese
		Glue004,      # 12: suffixed
		Glue8421,      # 13: rubied
		Glue8421,      # 14: number
		GlueNon,      # 15: unit
		Glue004,      # 16: space
		GlueNon,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 16: space
	[
		Glue0222,      # 0: begin paren
		Glue004,      # 1: end paren
		Glue004,      # 2: not at top of line
		Glue004,      # 3: ?!
		Glue0443,      # 4: dot
		Glue004,      # 5: punc
		Glue004,      # 6: leader
		Glue004,      # 7: pre unit
		Glue004,      # 8: post unit
		Glue004,      # 9: zenkaku space
		Glue004,      # 10: hirakana
		Glue004,      # 11: japanese
		Glue004,      # 12: suffixed
		Glue004,      # 13: rubied
		Glue004,      # 14: number
		Glue004,      # 15: unit
		Glue004,      # 16: space
		Glue004,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 17: ascii
	[
		Glue0222,      # 0: begin paren
		GlueNon,      # 1: end paren
		GlueNon,      # 2: not at top of line
		GlueNon,      # 3: ?!
		Glue0443,      # 4: dot
		GlueNon,      # 5: punc
		Glue004,      # 6: leader
		Glue004,      # 7: pre unit
		Glue004,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		Glue8421,      # 10: hirakana
		Glue8421,      # 11: japanese
		Glue844,      # 12: suffixed
		Glue8421,      # 13: rubied
		GlueNon,      # 14: number
		GlueNon,      # 15: unit
		Glue004,      # 16: space
		GlueNon,      # 17: ascii
		GlueNon,      # 18: special
	],
	# 18: special
	[
		GlueNon,      # 0: begin paren
		GlueNon,      # 1: end paren
		GlueNon,      # 2: not at top of line
		GlueNon,      # 3: ?!
		GlueNon,      # 4: dot
		GlueNon,      # 5: punc
		GlueNon,      # 6: leader
		GlueNon,      # 7: pre unit
		GlueNon,      # 8: post unit
		GlueNon,      # 9: zenkaku space
		GlueNon,      # 10: hirakana
		GlueNon,      # 11: japanese
		GlueNon,      # 12: suffixed
		GlueNon,      # 13: rubied
		GlueNon,      # 14: number
		GlueNon,      # 15: unit
		GlueNon,      # 16: space
		GlueNon,      # 17: ascii
		GlueNon,      # 18: special
	],
];

$Default{Splittable} = [
	#0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], # 0
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # 1
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # 2
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # 3
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # 4
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # 5
	[1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # 6
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1], # 7
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # 8
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # 9
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # 10
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # 11
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1], # 12
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # 13
	[1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1], # 14
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1], # 15
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], # 16
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 1], # 17
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], # 18
];

# 1 if not at begin of line
$Default{NoBOL} = 
	[0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

# 1 if not at end of line
$Default{NoEOL} = 
	[1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

#--------------------------------------------------------------------------
package PDFJ::Util;
use Carp;
use FileHandle;
use strict;

my $TeXHyphenObj;

sub hyphenate {
	my($word) = @_;
	require TeX::Hyphen;
	$TeXHyphenObj = TeX::Hyphen->new unless $TeXHyphenObj;
	$TeXHyphenObj->hyphenate($word);
}

sub objisa {
	my($target, $class) = @_;
	ref($target) && UNIVERSAL::isa($target, $class);
}

sub uriencode {
	my($str) = @_;
	$str =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/sprintf("%%%02X",ord($1))/ge
		unless $str =~ /%[0-9a-fA-F]{2}/;
	$str;
}

sub transmatrix {
	my($x, $y, $transtype, @args) = @_;
	if( ref($args[0]) eq 'ARRAY' ) {
		@args = @{$args[0]};
	}
	my @result;
	if( $transtype ) {
		if( $transtype eq 'magnify' ) {
			my($xmag, $ymag) = @args;
			@result = ($xmag, 0, 0, $ymag, $x, $y);
		} elsif( $transtype eq 'rotate' ) {
			my($rad) = @args;
			my $sin = sin($rad);
			my $msin = -$sin;
			my $cos = cos($rad);
			@result = ($cos, $sin, $msin, $cos, $x, $y);
		} elsif( $transtype eq 'distort' ) {
			my($xtan, $ytan) = @args;
			@result = (1, $xtan, $ytan, 1, $x, $y);
		} else {
			croak "unknown transformation type";
		}
	}
	@result;
}

my $SubsetTag;
sub subsettag {
	unless( $SubsetTag ) {
		for(1..6) {
			$SubsetTag .= chr(ord('A') + int(rand(26)));
		}
	}
	$SubsetTag++;
}

sub ttfopen {
	my($ttffile) = @_;
	require PDFJ::TTF;
	my $ttf;
	if( $ttffile =~ /(\.ttc):(\d)$/i ) {
		my $ttcfile = $`.$1;
		my $num = $2;
		my $ttc = new PDFJ::TTC $ttcfile;
		$ttf = $ttc->select($num);
	} else {
		$ttf = new PDFJ::TTF $ttffile;
	}
	croak "cannot open $ttffile" unless $ttf;
	$ttf->read_table(':all');
	$ttf;
}

sub otfopen {
	my($otffile) = @_;
	require PDFJ::OTF;
	my $otf = new PDFJ::OTF $otffile;
	croak "cannot open $otffile" unless $otf;
	$otf->read_table(':all');
	$otf;
}

sub deflate {
	my($src) = @_;
	my $reader = reader($src) or return;
	eval { require Compress::Zlib; };
	#return if $@;
	croak $@ if $@;
	my $OK = Compress::Zlib::Z_OK();
	my $d = Compress::Zlib::deflateInit() or return;
	my($len, $data, $result);
	while( $len = &$reader($data, 1024) ) {
		my($deflated, $status) = $d->deflate($data);
		return unless $status == $OK;
		$result .= $deflated;
	}
	my($deflated, $status) = $d->flush();
	return unless $status == $OK;
	$result .= $deflated;
	$result;
}

sub deflate_ascii85encode {
	my($src) = @_;
	my($result, $deflated);
	my $temp = deflate($src);
	if( $temp ) {
		$result = ascii85encode(\$temp);
		$deflated = 1;
	} else {
		$result = ascii85encode($src);
	}
	($result, $deflated);
}

sub ascii85encode {
	my($src) = @_;
	my $reader = reader($src) or return;
	my($len, $data, $result);
	while( $len = &$reader($data, 4) ) {
		if( $len == 4 ) {
			my $resultchunk = ascii85chunk($data);
			$resultchunk = 'z' if $resultchunk eq '!!!!!';
			$result .= $resultchunk;
		} else {
			for( my $j = 4; $j > $len; $j-- ) {
				$data .= "\000";
			}
			$result .= substr ascii85chunk($data), 0, $len + 1;
			last;
		}
	}
	$result .= '~>';
	$result;
}

sub ascii85chunk {
	my($chunk) = @_;
	$chunk = unpack("N", $chunk);
	my $resultchunk;
	$resultchunk .= chr(int($chunk / (85 ** 4)) + 33);
	$chunk = $chunk % (85 ** 4);
	$resultchunk .= chr(int($chunk / (85 ** 3)) + 33);
	$chunk = $chunk % (85 ** 3);
	$resultchunk .= chr(int($chunk / (85 ** 2)) + 33);
	$chunk = $chunk % (85 ** 2);
	$resultchunk .= chr(int($chunk / 85) + 33);
	$chunk = $chunk % 85;
	$resultchunk .= chr($chunk + 33);
	$resultchunk;
}

sub makestream {
	my($filter, $src, @addfilters) = @_;
	my($encoded, $deflated, @filters);
	if( $filter =~ /af/ ) {
		($encoded, $deflated) = deflate_ascii85encode($src);
		return unless $encoded;
		@filters = $deflated ? qw(ASCII85Decode FlateDecode) :
			qw(ASCII85Decode);
	} elsif( $filter =~ /f/ ) {
	 	$encoded = deflate($src) or return;
		@filters = qw(FlateDecode);
	} elsif( $filter =~ /a/ ) {
	 	$encoded = ascii85encode($src) or return;
		@filters = qw(ASCII85Decode);
	} else {
		return;
	}
	push @filters, @addfilters if @addfilters;
	$filter = @filters > 1 ? [map {PDFJ::Object::name($_)} @filters] : 
		PDFJ::Object::name($filters[0]);
	($encoded, $filter);
}

# make random ID string for ID entry
sub makerandid {
	my $id;
	for(1..16) {
		$id .= chr(rand(255));
	}
	$id;
}

# make (encryptionkey, O entry, U entry, P entry)
# see makeEncryptP about $allowspec 
sub makecryptkey {
	require Digest::MD5;
	my($ownerpass, $userpass, $allowspec, $fileid) = @_;
	my $Pentry = makeEncryptP($allowspec);
	$ownerpass ||= $userpass;
	$ownerpass = trimpass($ownerpass);
	$userpass = trimpass($userpass);
	my $md5obj = Digest::MD5->new;
	$md5obj->add($ownerpass);
	my $rc4key = substr($md5obj->digest, 0, 5);
	my $Oentry = RC4($userpass, $rc4key);
	$md5obj->reset;
	$md5obj->add($userpass);
	$md5obj->add($Oentry);
	$md5obj->add(pack("V", $Pentry));
	$md5obj->add($fileid);
	$rc4key = substr($md5obj->digest, 0, 5);
	my $Uentry = RC4(passpadding(), $rc4key);
	($rc4key, $Oentry, $Uentry, $Pentry);
}

sub passpadding {
	"\x28\xbf\x4e\x5e\x4e\x75\x8a\x41\x64\x00\x4e\x56\xff\xfa\x01\x08\x2e\x2e\x00\xb6\xd0\x68\x3e\x80\x2f\x0c\xa9\xfe\x64\x53\x69\x7a";
}

sub trimpass {
	my($pass) = @_;
	substr($pass . passpadding(), 0, 32);
}

# RC4 encrypting
# based on Crypt::RC4 by Kurt Kincaid 
my @RC4state;
my $RC4x = 0;
my $RC4y = 0;
sub RC4 {
	my($message, $pass) = @_;
	my(@state, $x, $y);
	if( defined $pass ) {
		my @k = unpack( 'C*', $pass );
		@state = 0..255;
		my $y = 0;
		for my $x (0..255) {
			$y = ( $k[$x % @k] + $state[$x] + $y ) % 256;
			@state[$x, $y] = @state[$y, $x];
		}
		@RC4state = @state;
		$RC4x = 0;
		$RC4y = 0;
	} else {
		@state = @RC4state;
	}
	$x = $RC4x;
	$y = $RC4y;
	my $num_pieces = do {
		my $num = length($message) / 1024;
		my $int = int $num;
		$int == $num ? $int : $int+1;
	};
	for my $piece ( 0..$num_pieces - 1 ) {
		my @message = unpack "C*", substr($message, $piece * 1024, 1024);
		for ( @message ) {
			$x = 0 if ++$x > 255;
			$y -= 256 if ($y += $state[$x]) > 255;
			@state[$x, $y] = @state[$y, $x];
			$_ ^= $state[( $state[$x] + $state[$y] ) % 256];
		}
		substr($message, $piece * 1024, 1024) = pack "C*", @message;
	}
	$message;
}

# make integer value of P entry of Encrypt entry
# $allowspec: P:rint, M:odify, C:opy, N:ote
sub makeEncryptP {
	my($allowspec) = @_;
	my $value = 0xffffffc0;
	if( $allowspec =~ /P/ ) {
		$value |= 1 << 2;
	}
	if( $allowspec =~ /M/ ) {
		$value |= 1 << 3;
	}
	if( $allowspec =~ /C/ ) {
		$value |= 1 << 4;
	}
	if( $allowspec =~ /N/ ) {
		$value |= 1 << 5;
	}
	$value;
}

sub u32toi32 {
	my($value) = @_;
	if( $value & 0x80000000 ) {
		$value ^= 0xffffffff;
		-($value + 1);
	} else {
		$value;
	}
}

sub tounicode {
	my($str, $init) = @_;
	require PDFJ::Unicode;
	my $result = $init ? "\xfe\xff" : "";
	if( $PDFJ::Default{Jcode} eq 'SJIS' ) {
		$result .= PDFJ::Unicode::sjistounicode($str);
	} elsif( $PDFJ::Default{Jcode} eq 'EUC' ) {
		$result .= PDFJ::Unicode::euctounicode($str);
	} elsif( $PDFJ::Default{Jcode} eq 'UTF8' ) {
		$result .= PDFJ::Unicode::utf8tounicode($str);
	} elsif( $PDFJ::Default{Jcode} eq 'UNICODE' ) {
		$result .= $str;
	}
	$result;
}

sub reader {
	my($src) = @_;
	if( ref($src) eq 'SCALAR' ) {
		my $pos = 0;
		return sub { 
			$_[0] = substr $$src, $pos, $_[1];
			my $len = length $_[0];
			$pos += $len;
			$len;
		};
	} else {
		my $handle = FileHandle->new($src) or return;
		binmode $handle;
		return sub {
			read $handle, $_[0], $_[1];
		};
	}
}

sub methodargs {
	my $names = shift;
	if( @_ == 2 && ref($_[1]) eq 'HASH' ) {
		($_[0], @{$_[1]}{@$names});
	} else {
		@_;
	}
}

sub listargs2ref {
	my($pre, $post) = (shift, shift);
	return @_ if @_ < $pre + $post;
	my @list = $post ? splice(@_, $pre, -$post) : splice(@_, $pre);
	my $list = (@list == 1 && ref($list[0]) eq 'ARRAY') ? $list[0] : \@list;
	splice @_, $pre, 0, $list;
	@_;
}

sub strstyle2hashref {
	my($style) = @_;
	my($result) = _strstyle2hashref($style);
	$result;
}

sub _strstyle2hashref {
	my($style, $brace) = @_;
	return ($style) if ref($style);
	my %result;
	while( $style =~ /(\S+?)\s*:\s*/ ) {
		my($name, $rest) = ($1, $');
		my($value, $delim);
		if( $rest =~ s/^\{// ) {
			($value, $style) = _strstyle2hashref($rest, 1);
		} elsif( $brace ) {
			($value, $delim) = $rest =~ /(.*?)(;|\}|$)/;
			$style = $';
			$value =~ s/\s+$//;
		} elsif( $rest =~ /^\[(.*?)\]\s*(;|$)/ ) {
			($value, $delim) = ($1, $2);
			$style = $';
			my @tmp = split /\s*,\s*/, $value;
			$value = \@tmp;
		} else {
			($value, $delim) = $rest =~ /(.*?)(;|$)/;
			$style = $';
			$value =~ s/\s+$//;
		}
		$result{$name} = $value;
		last if $delim && $delim eq '}';
	}
	(\%result, $style);
}

#--------------------------------------------------------------------------
package PDFJ::Doc;
use strict;
use Carp;
use FileHandle;
use PDFJ::Object;

sub Doc { PDFJ::Doc->new(@_) }

sub new {
	my($class, $version, $pagewidth, $pageheight) = 
		PDFJ::Util::methodargs([qw(version pagewidth pageheight)], @_);
	my $objtable = PDFJ::ObjTable->new;
	my $self = bless {
		version => $version,
		objtable => $objtable, 
		pagewidth => $pagewidth,
		pageheight => $pageheight,
		pagelist => [],
		pageobjlist => [],
		fontlist => {},
		imagelist => {},
		jcidsysteminfo => undef,
		jfontdescriptor => {},
		filter => 'f', # a:ascii85, f:flate, af:both 
		subsettag => PDFJ::Util::subsettag(),
		}, $class;
	$self->{pagetree} = $self->indirect(dictionary({
		Type => name('Pages'),
		Kids => [],
		Count => 0,
		}));
	$self->{catalog} = $self->indirect(dictionary({
		Type => name('Catalog'),
		Pages => $self->{pagetree},
		}));
	my $cdate = datestring();
	$self->{info} = $self->indirect(dictionary({
		Producer => textstring("PDFJ $PDFJ::VERSION"),
		CreationDate => $cdate,
		ModDate => $cdate,
		}));
	my $id = PDFJ::Util::makerandid();
	$self->{idstring} = $id;
	$self->{id} = array([string($id), string($id)]);
	$self;
}

sub pagewidth {
	my($self) = @_;
	$self->{pagewidth};
}

sub pageheight {
	my($self) = @_;
	$self->{pageheight};
}

sub filter {
	my($self, $filter) = PDFJ::Util::methodargs([qw(filter)], @_);
	if( defined $filter ) {
		$self->{filter} = $filter; # a:ascii85, f:flate, af:both 
	}
	$self->{filter};
}

sub setoption {
	my($self, $name, $value) = PDFJ::Util::methodargs([qw(name value)], @_);
	$self->{option}{$name} = $value;
}

sub getoption {
	my($self, $name) = PDFJ::Util::methodargs([qw(name)], @_);
	$self->{option}{$name};
}

sub add_info {
	my($self, @args) = @_;
	my %args;
	if( @args == 1 && ref($args[0]) eq 'HASH' ) {
		%args = %{$args[0]};
	} else {
		%args = @args;
	}
	for my $key(keys %args) {
		$self->{info}->set($key => textstring($args{$key}));
	}
}

sub encrypt {
	my($self, $ownerpass, $userpass, $allow) = 
		PDFJ::Util::methodargs([qw(ownerpass userpass allow)], @_);
	my $id = $self->{idstring};
	my($encryptkey, $Oentry, $Uentry, $Pentry) = 
		PDFJ::Util::makecryptkey($ownerpass, $userpass, $allow, $id);
	$self->{encryptkey} = $encryptkey;
	$self->{encrypt} = $self->indirect(dictionary({
		Filter => name('Standard'),
		V => 1,
		R => 2,
		O => string($Oentry),
		U => string($Uentry),
		P => PDFJ::Util::u32toi32($Pentry),
		}));
	$self->{encrypt}->nocrypt;
}

sub cmap {
	my($self, $encoding) = @_;
	if( $PDFJ::Default{CMap}{$encoding} ) {
		$self->makecmap($PDFJ::Default{CMap}{$encoding});
	} else {
		name($encoding);
	}
}

sub makecmap {
	my($self, $cmapdata) = @_;
	my $name = $cmapdata->{CMapName};
	unless( $self->{cmap}{$name} ) {
		my($r, $o, $s) = split /-/, $cmapdata->{CIDSystemInfo};
		my $usecmap = $cmapdata->{UseCMap};
		my $cidrange = $cmapdata->{CIDRange};
		my $wmode = $name =~ /-H$/ ? 0 : 1;
		$self->{cmap}{$name} = $self->indirect(stream(dictionary => {
			Type => name('CMap'),
			CMapName => name($name),
			CIDSystemInfo => {
				Registry => $r,
				Ordering => $o,
				Supplement => $s
			},
			WMode => $wmode,
			UseCMap => name($usecmap),
	}, stream => _cmap($name, $usecmap, $wmode, $r, $o, $s, $cidrange)));
	}
	$self->{cmap}{$name};
}

# NOT method
sub _cmap {
	my($name, $usecmap, $wmode, $r, $o, $s, $cidrange) = @_;
	my $result = <<END;
%!PS-Adobe-3.0 Resource-CMap
%%DocumentNeededResources: ProcSet (CIDInit)
%%DocumentNeededResources: CMap ($usecmap)
%%IncludeResource: ProcSet (CIDInit)
%%IncludeResource: CMap ($usecmap)
%%BeginResource: CMap ($name)
%%Title: ($name $r $o $s)
%%Version: 1
%%Copyright: Copyright 2004 Sey Nakajima
%%EndComments
/CIDInit /ProcSet findresource begin
12 dict begin
begincmap
/$usecmap usecmap
/CIDSystemInfo 3 dict dup begin
  /Registry ($r) def
  /Ordering ($o) def
  /Supplement $s def
end def
/CMapName /$name def
/CMapVersion 1 def
/CMapType 1 def
/WMode $wmode def
END
	my $rangecount = $cidrange =~ s/\n/\n/g;
	$result .= "$rangecount begincidrange\n";
	$result .= $cidrange;
	$result .= <<END;
endcidrange
endcmap
CMapName currentdict /CMap defineresource pop
end
end
%%EndResource
%%EOF
END
	$result;
}

sub _add_outline {
	my($self, $title, $dest, $parent) = @_;
	# $title = PDFJ::Util::tounicode($title, 1) if $title =~ /[\x80-\xff]/;
	my $lastitem = $parent->get('Last');
	my $newitem;
	if( $lastitem ) {
		$newitem = $self->indirect(dictionary({
			Title => textstring($title), 
			Parent => $parent,
			Prev => $lastitem,
			Count => 0,
			}));
		$newitem->set('Dest', $dest) if $dest;
		$lastitem->set('Next', $newitem);
		$parent->set('Last', $newitem);
	} else {
		$newitem = $self->indirect(dictionary({
			Title => textstring($title), 
			Parent => $parent,
			Count => 0,
			}));
		$newitem->set('Dest', $dest) if $dest;
		$parent->set('First', $newitem);
		$parent->set('Last', $newitem);
	}
	while( $parent ) {
		$parent->get('Count')->add(1);
		$parent = $parent->get('Parent');
	}
	$newitem;
}

sub add_outline {
	my($self, $title, $page, $x, $y, $level) = @_;
	return unless UNIVERSAL::isa($page, 'PDFJ::Page');
	# add to outline
	my $dest = $page->dest('XYZ', $x, $y, 0);
	unless( $self->{outline} ) {
		$self->{outline} = $self->indirect(dictionary({
			Type => name('Outlines'),
			Count => 0,
			}));
		$self->{catalog}->set('Outlines', $self->{outline});
		$self->{catalog}->set('PageMode', name('UseOutlines'));
	}
	my $parent = $self->{outline};
	for( my $j = 0; $j < $level; $j++ ) {
		$parent = $parent->get('Last') ?
			$parent->get('Last') :
			$self->_add_outline('', undef, $parent);
	}
	$self->_add_outline($title, $dest, $parent);
	# add to outlinetree
	unless( $self->{outlinetree} ) {
		$self->{outlinetree} = [];
	}
	$parent = $self->{outlinetree};
	for( my $j = 0; $j < $level; $j++ ) {
		push @$parent, ['', undef, undef, undef, []] unless @$parent;
		$parent = $$parent[$#$parent][4];
	}
	push @$parent, [$title, $page, $x, $y, []];
}

sub outlinetree {
	my($self) = @_;
	$self->{outlinetree};
}

sub add_dest {
	my($self, $name, $page, $x, $y) = @_;
	return unless UNIVERSAL::isa($page, 'PDFJ::Page');
	my $dest = $page->dest('XYZ', $x, $y, 0);
	push @{$self->{dest}{$name}}, $dest;
	push @{$self->{destpage}{$name}}, [$page, $x, $y];
}

sub destnames {
	my($self) = @_;
	keys %{$self->{dest}};
}

sub dest {
	my($self, $name) = @_;
	$self->{dest}{$name};
}

sub destpage {
	my($self, $name) = 
		PDFJ::Util::methodargs([qw(name)], @_);
	$self->{destpage}{$name};
}

sub indirect {
	my($self, $obj) = @_;
	$obj->indirect($self->{objtable});
}

sub print {
	my($self, $file) = PDFJ::Util::methodargs([qw(file)], @_);
	$self->_solve_link;
	$self->_setunusedfont;
	$self->_complete_subsetfont;
	my($handle, $needclose);
	if( ref($file) eq 'GLOB' || PDFJ::Util::objisa($file, 'IO::Handle') ) {
		$handle = $file;
		$needclose = 0;
	} else {
		$handle = FileHandle->new(">$file");
		$needclose = 1;
	}
	return unless $handle;
	my $fobj = PDFJ::File->new($self->{version}, $handle, $self->{objtable}, 
		$self->{catalog}, $self->{id}, $self->{info}, $self->{encrypt}, 
		$self->{encryptkey}, $self->{filter});
	$fobj->print;
	close $handle if $needclose;
}

sub new_page {
	my($self, $pagewidth, $pageheight, $dur, $trans)
		= PDFJ::Util::methodargs([qw(pagewidth pageheight dur trans)], @_);
	PDFJ::Page->new($self, -1, $pagewidth, $pageheight, $dur, $trans);
}

sub insert_page {
	my($self, $idx, $pagewidth, $pageheight, $dur, $trans)
		= PDFJ::Util::methodargs([qw(number pagewidth pageheight dur trans)], @_);
	PDFJ::Page->new($self, $idx, $pagewidth, $pageheight, $dur, $trans);
}

sub get_page {
	my($self, $idx) = PDFJ::Util::methodargs([qw(number)], @_);
	$self->{pageobjlist}->[$idx];
}

sub lastpagenum {
	my $self = shift;
	scalar @{$self->{pagelist}};
}

# for backward conpatible
sub get_lastpagenum {
	&lastpagenum;
}

sub new_font {
	my($self, $basefont, $encoding, $abasefont, $aencoding, $asize) = 
		PDFJ::Util::methodargs([qw(basefont encoding abasefont aencoding asize)], @_);
	if( $abasefont ) {
		$self->new_combofont($basefont, $encoding, $abasefont, $aencoding, $asize);
	} else {
		$self->new_singlefont($basefont, $encoding);
	}
}

sub new_singlefont {
	my($self, $basefont, $encoding) = @_;
	$basefont ||= $PDFJ::Default{BaseAFont};
	my $type = $PDFJ::Default{Fonts}{$basefont};
	if( $type eq 'a' ) {
		new_afont($self, $basefont, $encoding);
	} elsif( $type eq 'j' ) {
		new_cidfont($self, $basefont, $encoding);
	} elsif( $basefont =~ /\.ttf$/i || $basefont =~ /\.ttc:\d$/i || 
		$basefont =~ /\.otf$/i ) {
		if( $PDFJ::Default{Encodings}{$encoding} eq 'a' ) {
			new_afont($self, $basefont, $encoding);
		} else {
			new_cidfont($self, $basefont, $encoding);
		}
	} else {
		croak "unknown font: $basefont";
	}
}

sub new_combofont {
	my($self, $zbase, $zenc, $hbase, $henc, $hsize) = @_;
	my $hfont = PDFJ::Util::objisa($hbase, "PDFJ::AFont") ? $hbase :
		new_afont($self, $hbase, $henc);
	new_cidfont($self, $zbase, $zenc, $hfont, $hsize);
}

sub new_afont {
	my($self, $basefont, $encoding) = @_;
	$basefont ||= $PDFJ::Default{BaseAFont};
	$encoding ||= $PDFJ::Default{AFontEncoding};
	croak "encoding type mismatch" 
		unless $PDFJ::Default{Encodings}{$encoding} eq 'a';
	if( $basefont =~ /\.ttf$/i || $basefont =~ /\.ttc:\d$/i ) {
		PDFJ::AFont->new_ttf($self, $basefont, $encoding);
	} elsif( $basefont =~ /\.otf$/i ) {
		PDFJ::AFont->new_otf($self, $basefont, $encoding);
	} else {
		PDFJ::AFont->new_std($self, $basefont, $encoding);
	}
}

sub new_cidfont {
	my($self, $basefont, $encoding, $hfont, $hsize) = @_;
	$basefont ||= $PDFJ::Default{BaseJFont};
	$encoding ||= $PDFJ::Default{JFontEncoding};
	my $enctype = $PDFJ::Default{Encodings}{$encoding};
	my $codetype = $PDFJ::Default{Jcode} eq 'SJIS' ? 's' : 
		$PDFJ::Default{Jcode} eq 'EUC' ? 'e' : 'u';
	croak "encoding type mismatch" unless $enctype =~ /$codetype/;
	if( $basefont =~ /\.ttf$/i || $basefont =~ /\.ttc:\d$/i ) {
		PDFJ::CIDFont->new_ttf($self, $basefont, $encoding, $hfont, $hsize);
	} elsif( $basefont =~ /\.otf$/i ) {
		PDFJ::CIDFont->new_otf($self, $basefont, $encoding, $hfont, $hsize);
	} else {
		PDFJ::CIDFont->new_std($self, $basefont, $encoding, $hfont, $hsize);
	}
}

sub new_image {
	my($self, $src, $pxwidth, $pxheight, $width, $height, $padding, 
		$colorspace, $type)
		= PDFJ::Util::methodargs([qw(src pxwidth pxheight width height padding 
		colorspace type)], @_);
	PDFJ::Image->new($self, $src, $pxwidth, $pxheight, $width, $height, 
		$padding, $colorspace, $type);
}

sub italic {
	my($self, @args) = PDFJ::Util::methodargs([qw(base decorated)], @_);
	$self->_deco('italic', @args);
}

sub bold {
	my($self, @args) = PDFJ::Util::methodargs([qw(base decorated)], @_);
	$self->_deco('bold', @args);
}

# internal methods
sub _deco {
	my($self, $style, @args) = @_; # $style: italic, bold
	croak "arguments must be even" if @args % 2;
	while( @args ) {
		my $base = shift @args;
		my $deco = shift @args;
		if( $base->isa("PDFJ::AFont") ) {
			croak "font type mismatch" unless $deco->isa("PDFJ::AFont");
			$self->{$style}{$base->{name}} = $deco->{name};
		} elsif( $base->isa("PDFJ::CIDFont") ) {
			croak "font type mismatch" unless $deco->isa("PDFJ::CIDFont");
			if( $base->{combo} ) {
				croak "font combo type mismatch" unless $deco->{combo};
				$self->{$style}{$base->{zname}, $base->{hname}, $base->{hsize}}
					= join($;, $deco->{zname}, $deco->{hname}, $deco->{hsize});
			} else {
				croak "font combo type mismatch" if $deco->{combo};
				$self->{$style}{$base->{zname}} = $deco->{zname};
			}
		}
	}
}

sub _bolditalicname {
	my($self, $name, $style) = @_; # $style: PDFJ::TStyle object
	my $dname = $name;
	$dname = $self->{italic}{$dname} if $style->{italic};
	$dname = $self->{bold}{$dname} if $style->{bold};
	$dname;
}

sub _bolditalicfont {
	my($self, $font, $style) = @_; # $style: PDFJ::TStyle object
	my $name = $font->fname;
	my $docobj = $font->{docobj};
	my $dname = $name;
	if( $style->{italic} ) {
		$dname = $self->{italic}{$dname} 
			or croak "missing italic font";
	}
	if( $style->{bold} ) {
		$dname = $self->{bold}{$dname} 
			or croak "missing bold font";
	}
	$dname eq $name ? $font : $docobj->_fontobj($dname);
}

sub _solve_link {
	my $self = shift;
	for my $pageobj(@{$self->{pageobjlist}}) {
		$pageobj->solve_link;
	}
}

sub _usefonts {
	my($self, @names) = @_;
	for my $name(@names) {
		$self->{usedfont}{$name} = 1;
	}
}

sub _setunusedfont {
	my $self = shift;
	for my $name(keys %{$self->{fontlist}}) {
		unless( $self->{usedfont}{$name} ) {
			$self->{fontlist}{$name}->unused(1);
		}
	}
}

sub _complete_subsetfont {
	my $self = shift;
	for my $name(keys %{$self->{subsetttf}}) {
		my $sttf = $self->{subsetttf}{$name};
		my $ttf = $sttf->{ttf};
		my $direction = $sttf->{direction};
		my $encoding = $sttf->{encoding};
		my @unicodes = sort keys %{$sttf->{subset_unicodes}};
		if( $self->{fontlist}{$name}->unused ) {
			carp "a font which is used in Text but not used in Page exists"
				if @unicodes;
			next;
		}
		my $font = $self->{fontlist}{$name};
		my($subset, $c2g, $cidset) = $ttf->subset($encoding, @unicodes);
		my $size = length $subset;
		my($encoded, $filter) = $self->_makestream(\$subset);
		croak "cannot encode ttf subset data" unless $encoded;
		$font->get('DescendantFonts')->get(0)->get('FontDescriptor')->set(
			FontFile2 => $self->indirect(stream(dictionary => {
				Filter  => $filter,
				Length  => length($encoded),
				Length1 => $size,
			}, stream => $encoded)));
		($encoded, $filter) = $self->_makestream(\$c2g);
		croak "cannot encode ttf subset cidtogidmap" unless $encoded;
		$font->get('DescendantFonts')->get(0)->set(
			CIDToGIDMap => $self->indirect(stream(dictionary => {
				Filter  => $filter,
				Length  => length($encoded),
			}, stream => $encoded)));
if(0) {
		($encoded, $filter) = $self->_makestream(\$cidset);
		croak "cannot encode ttf subset cidset" unless $encoded;
		$font->get('DescendantFonts')->get(0)->get('FontDescriptor')->set(
			CIDSet => $self->indirect(stream(dictionary => {
				Filter  => $filter,
				Length  => length($encoded),
			}, stream => $encoded)));
}
	}
	for my $name(keys %{$self->{subsetotf}}) {
		my $sotf = $self->{subsetotf}{$name};
		my $otf = $sotf->{otf};
		my $direction = $sotf->{direction};
		my $encoding = $sotf->{encoding};
		my @unicodes = sort keys %{$sotf->{subset_unicodes}};
		if( $self->{fontlist}{$name}->unused ) {
			carp "a font which is used in Text but not used in Page exists"
				if @unicodes;
			next;
		}
		my $font = $self->{fontlist}{$name};
		my($subset) = $otf->subset($encoding, @unicodes);
		my $size = length $subset;
		my($encoded, $filter) = $self->_makestream(\$subset);
		croak "cannot encode otf subset data" unless $encoded;
		$font->get('DescendantFonts')->get(0)->get('FontDescriptor')->set(
			FontFile3 => $self->indirect(stream(dictionary => {
				Subtype => name('OpenType'),
				Filter  => $filter,
				Length  => length($encoded),
				Length1 => $size,
			}, stream => $encoded)));
	}
}

sub _makestream {
	my($self, $src, @addfilters) = @_;
	PDFJ::Util::makestream($self->filter, $src, @addfilters);
}

sub _nextsubsettag {
	my $self = shift;
	$self->{subsettag}++;
}

sub _nextfontnum {
	my $self = shift;
	1 + scalar keys %{$self->{fontlist}};
}

sub _registfont {
	my($self, $fontobj) = @_;
	my $baseorttf = 
		$fontobj->{ttffile} || $fontobj->{otffile} || $fontobj->{basefont};
	my $encoding = $fontobj->{encoding};
	my $name = $fontobj->{name} || $fontobj->{zname};
	my $font = $fontobj->{font} || $fontobj->{zfont};
	$self->{fontname}{$baseorttf, $encoding} = $name;
	$self->{fontlist}{$name} = $font;
	if( $fontobj->{combo} ) {
		$self->{fontobjlist}{$name, $fontobj->{hname}, $fontobj->{hsize}} = 
			$fontobj;
	} else {
		$self->{fontobjlist}{$name} = $fontobj;
	}
}

sub _registsubset_ttf {
	my($self, %args) = @_;
	$args{subset_unicodes} = {};
	$self->{subsetttf}{$args{name}} = \%args;
}

sub _registsubset_otf {
	my($self, %args) = @_;
	$args{subset_unicodes} = {};
	$self->{subsetotf}{$args{name}} = \%args;
}

sub _subsetttf {
	my($self, $name) = @_;
	$self->{subsetttf}{$name};
}

sub _subsetotf {
	my($self, $name) = @_;
	$self->{subsetotf}{$name};
}

sub _fontname {
	my($self, $baseorttf, $encoding) = @_;
	$self->{fontname}{$baseorttf, $encoding};
}

sub _font {
	my($self, $name) = @_;
	$self->{fontlist}{$name};
}

sub _fontobj {
	my($self, $name, $hname, $hsize) = @_;
	$hsize ||= 1;
	$hname ? 
		$self->{fontobjlist}{$name, $hname, $hsize} :
		$self->{fontobjlist}{$name};
}

sub _jcidsysteminfo {
	my $self = shift;
	$self->_cidsysteminfo('j');
}

sub _cidsysteminfo {
	my($self, $ename) = @_;
	my $name = $ename . 'cidsysteminfo';
	unless( $self->{$name} ) {
		my($r, $o, $s) = split /-/, $PDFJ::Default{CIDSystemInfo}{$ename};
		$self->{$name} = $self->indirect(dictionary({
			Registry => $r,
			Ordering => $o,
			Supplement => $s,
		}));
	}
	$self->{$name};
}

sub _fontdescriptor {
	my($self, $basefont) = @_;
	unless( $self->{fontdescriptor}->{$basefont} ) {
		$self->{fontdescriptor}->{$basefont} = 
			$self->indirect(dictionary($PDFJ::Default{FD}{$basefont}));
	}
	$self->{fontdescriptor}->{$basefont};
}

sub _nextimagenum {
	my $self = shift;
	1 + scalar keys %{$self->{imagelist}};
}

sub _registimage {
	my($self, $name, $image) = @_;
	$self->{imagelist}->{$name} = $image;
}

sub new_minipage {
	my($self, $width, $height, $padding, $opacity) 
		= PDFJ::Util::methodargs([qw(width height padding opacity)], @_);
	PDFJ::MiniPage->new($self, $width, $height, $padding, $opacity);
}

sub _nextxobjnum {
	my $self = shift;
	if( $self->{xobjlist} ) {
		1 + scalar keys %{$self->{xobjlist}};
	} else {
		1;
	}
}

sub _registxobj {
	my($self, $name, $xobj) = @_;
	$self->{xobjlist}->{$name} = $xobj;
}

#--------------------------------------------------------------------------
package PDFJ::Font;
use strict;

#--------------------------------------------------------------------------
package PDFJ::AFont;
use strict;
use Carp;
#use SelfLoader;
use PDFJ::Object;
use vars qw(@ISA);
@ISA = qw(PDFJ::Font);

sub new_std {
	my($class, $docobj, $basefont, $encoding) = @_;
	croak "illegal ascii font name: $basefont"
		unless $PDFJ::Default{Fonts}{$basefont} eq 'a';
	my $name = $docobj->_fontname($basefont, $encoding);
	return $docobj->_fontobj($name) if $name;
	$name = "F".$docobj->_nextfontnum;
	my $font = $docobj->indirect(dictionary({
		Type => name('Font'),
		Name => name($name),
		BaseFont => name($basefont),
		Subtype => name('Type1'),
		Encoding => $docobj->cmap($encoding),
	}));
	require PDFJ::Type1;
	#my $width = fontwidth($basefont);
	my $width = PDFJ::Type1::fontwidth($basefont, $encoding);
	my $self = bless {docobj => $docobj, basefont => $basefont, 
		encoding => $encoding, font => $font, name => $name, width => $width,
		direction => 'H'}, $class;
	$docobj->_registfont($self);
	$self;
}

sub new_ttf {
	my($class, $docobj, $ttffile, $encoding) = @_;
	my $name = $docobj->_fontname($ttffile, $encoding);
	return $docobj->_fontobj($name) if $name;
	$name = "F".$docobj->_nextfontnum;
	my $ttf = PDFJ::Util::ttfopen($ttffile);
	my $info = $ttf->pdf_info_ascii($encoding);
	croak "'$ttffile' embedding inhibited"
		if $info->{EmbedFlag} == 2 || $info->{EmbedFlag} & 0x200;
	my $size = -s $ttffile;
	my($encoded, $filter) = $docobj->_makestream($ttffile);
	my $basefont = $info->{BaseFont};
	my @widths = @{$info->{Widths}};
	my $font = $docobj->indirect(dictionary({
		Type => name('Font'),
		Name => name($name),
		BaseFont => name($basefont),
		Subtype => name('TrueType'),
		Encoding => name($info->{Encoding}),
		FirstChar => $info->{FirstChar},
		LastChar => $info->{LastChar},
		Widths => $docobj->indirect(array(\@widths)),
		FontDescriptor => $docobj->indirect(dictionary({
			Type => name('FontDescriptor'),
			Ascent => $info->{Ascent},
			CapHeight => $info->{CapHeight},
			Descent => $info->{Descent},
			Flags => $info->{Flags},
			FontBBox => $info->{FontBBox},
			FontName => name($info->{FontName}),
			ItalicAngle => $info->{ItalicAngle},
			StemV => 0, # OK?
			FontFile2 => $docobj->indirect(stream(dictionary => {
				Filter  => $filter,
				Length  => length($encoded),
				Length1 => $size,
			}, stream => $encoded)),
		})),
	}));
	my $self = bless {docobj => $docobj, # basefont => $basefont, 
		encoding => $encoding, ttffile => $ttffile,
		font => $font, name => $name, width => $info->{Widths}, 
		direction => 'H'}, $class;
	$docobj->_registfont($self);
	$self;
}

sub new_otf {
	my($class, $docobj, $otffile, $encoding) = @_;
	croak "OpenType embedding requires PDF version 1.6 or above"
		if $docobj->{version} < 1.6;
	my $name = $docobj->_fontname($otffile, $encoding);
	return $docobj->_fontobj($name) if $name;
	$name = "F".$docobj->_nextfontnum;
	my $otf = PDFJ::Util::otfopen($otffile);
	my $info = $otf->pdf_info_ascii($encoding);
	croak "'$otffile' embedding inhibited"
		if $info->{EmbedFlag} == 2 || $info->{EmbedFlag} & 0x200;
	my $size = -s $otffile;
	my($encoded, $filter) = $docobj->_makestream($otffile);
	my $basefont = $info->{BaseFont};
	my @widths = @{$info->{Widths}};
	my $font = $docobj->indirect(dictionary({
		Type => name('Font'),
		Name => name($name),
		BaseFont => name($basefont),
		Subtype => name('TrueType'), # OK?
		Encoding => name($info->{Encoding}),
		FirstChar => $info->{FirstChar},
		LastChar => $info->{LastChar},
		Widths => $docobj->indirect(array(\@widths)),
		FontDescriptor => $docobj->indirect(dictionary({
			Type => name('FontDescriptor'),
			Ascent => $info->{Ascent},
			CapHeight => $info->{CapHeight},
			Descent => $info->{Descent},
			Flags => $info->{Flags},
			FontBBox => $info->{FontBBox},
			FontName => name($info->{FontName}),
			ItalicAngle => $info->{ItalicAngle},
			StemV => 0, # OK?
			FontFile3 => $docobj->indirect(stream(dictionary => {
				Subtype => name('OpenType'),
				Filter  => $filter,
				Length  => length($encoded),
				Length1 => $size,
			}, stream => $encoded)),
		})),
	}));
	my $self = bless {docobj => $docobj, # basefont => $basefont, 
		encoding => $encoding, otffile => $otffile,
		font => $font, name => $name, width => $info->{Widths}, 
		direction => 'H'}, $class;
	$docobj->_registfont($self);
	$self;
}

sub fname {
	my($self) = @_;
	$self->{name};
}

sub selectname {
	my($self, $style) = @_;
	$self->{docobj}->_bolditalicname($self->fname, $style);
}

sub selectfont {
	my($self, $style) = @_;
	$self->{docobj}->_bolditalicfont($self, $style);
}

sub hash {
	my $self = shift;
	($self->{name}, $self->{font});
}

sub string_fontwidth {
	my($self, $string) = @_;
	my $fontwidth = $self->{width};
	my $width = 0;
	for my $c(split '', $string) {
		$width += $fontwidth->[ord $c];
	}
	$width / 1000;
}

sub astring_fontwidth {
	&string_fontwidth;
}

#--------------------------------------------------------------------------
package PDFJ::CIDFont;
use strict;
use Carp;
use PDFJ::Object;
use vars qw(@ISA);
@ISA = qw(PDFJ::Font);

sub new_std {
	my($class, $docobj, $basefont, $encoding, $hfontobj, $hsize) = @_;
	croak "illegal CID font name: $basefont"
		if $PDFJ::Default{Fonts}{$basefont} eq 'a';
	croak "ascii font type mismatch"
		if $hfontobj && !PDFJ::Util::objisa($hfontobj, "PDFJ::AFont");
	my $name = $docobj->_fontname($basefont, $encoding);
	my $hname = $hfontobj ? $hfontobj->{name} : undef;
	return $docobj->_fontobj($name, $hname, $hsize) 
		if $name && $docobj->_fontobj($name, $hname, $hsize);
	# Zenkaku font
	my $code = $PDFJ::Default{Jcode};
	my($direction) = $encoding =~ /-(\w+)$/;
	my($zname, $zfont);
	if( $name ) {
		$zname = $name;
		$zfont = $docobj->_font($name);
	} else {
		my $ename = substr($PDFJ::Default{Encodings}{$encoding}, 0, 1);
		my $cidsi = $docobj->_cidsysteminfo($ename);
		my $fd = $docobj->_fontdescriptor($basefont);
		my $w = $ename eq 'j' ? [231, 389, 500, 631, [500]] : [];
		$zname = "F".$docobj->_nextfontnum;
		$zfont = $docobj->indirect(dictionary({
			Name => name($zname),
			Type => name("Font"),
			Subtype => name('Type0'),
			Encoding => $docobj->cmap($encoding),
			BaseFont => name("$basefont-$encoding"),
			DescendantFonts => [{
				Type => name('Font'),
				Subtype => name('CIDFontType0'),
				BaseFont => name($basefont),
				CIDSystemInfo => $cidsi,
				DW => 1000,
				# W => [231, 389, 500, 631, [500]],
				W => $w,
				FontDescriptor => $fd,
			}],
		}));
	}
	# Hankaku font
	my($combo, $hfont);
	if( $hfontobj ) {
		$combo = 1;
		$hsize ||= 1;
		$hname = $hfontobj->{name};
		$hfont = $hfontobj->{font};
	} else {
		$combo = 0;
		$hsize = 0;
		$hname = $zname;
		$hfont = $zfont;
	}
	my $self = bless {
		docobj => $docobj, 
		basefont => $basefont, 
		encoding => $encoding, 
		zfont => $zfont, 
		hfont => $hfont, 
		zname => $zname, 
		hname => $hname,
		direction => $direction,
		code => $code,
		combo => $combo,
		hsize => $hsize,
		hfontobj => $hfontobj,
	}, $class;
	$docobj->_registfont($self);
	$self;
}

sub new_ttf {
	my($class, $docobj, $ttffile, $encoding, $hfontobj, $hsize) = @_;
	croak "TrueType subset embedding requires PDF version 1.3 or above"
		if $docobj->{version} < 1.3;
	croak "ascii font type mismatch"
		if $hfontobj && !PDFJ::Util::objisa($hfontobj, "PDFJ::AFont");
	my $name = $docobj->_fontname($ttffile, $encoding);
	my $hname = $hfontobj ? $hfontobj->{name} : undef;
	return $docobj->_fontobj($name, $hname, $hsize) 
		if $name && $docobj->_fontobj($name, $hname, $hsize);
	# Zenkaku font
	my $code = $PDFJ::Default{Jcode};
	my($direction) = $encoding =~ /-(\w+)$/;
	my($zname, $zfont);
	if( $name ) {
		$zname = $name;
		$zfont = $docobj->_font($name);
	} else {
		my $ttf = PDFJ::Util::ttfopen($ttffile);
		my $info = $ttf->pdf_info_cid($encoding);
		croak "'$ttffile' embedding inhibited ($info->{EmbedFlag})"
			if $info->{EmbedFlag} == 2 || $info->{EmbedFlag} & 0x100 ||
				$info->{EmbedFlag} & 0x200;
		my $subsetname = $docobj->_nextsubsettag . '+' . $info->{BaseFont};
		my $basefont = $info->{BaseFont};
		my $ename = substr($PDFJ::Default{Encodings}{$encoding}, 0, 1);
		my $cidsi = $docobj->_cidsysteminfo($ename);
		my $w = $ename eq 'j' ? [231, 389, 500, 631, [500]] : [];
		$zname = "F".$docobj->_nextfontnum;
		$zfont = $docobj->indirect(dictionary({
			Name => name($zname),
			Type => name("Font"),
			Subtype => name('Type0'),
			Encoding => $docobj->cmap($encoding),
			BaseFont => name($subsetname),
			DescendantFonts => [$docobj->indirect(dictionary({
				Type => name('Font'),
				Subtype => name('CIDFontType2'), # TrueType
				BaseFont => name($basefont),
				CIDSystemInfo => $cidsi,
				DW => 1000,
				# W => [231, 389, 500, 631, [500]],
				W => $w,
				FontDescriptor => $docobj->indirect(dictionary({
					Type => name('FontDescriptor'),
					Ascent => $info->{Ascent},
					CapHeight => $info->{CapHeight},
					Descent => $info->{Descent},
					Flags => $info->{Flags},
					FontBBox => $info->{FontBBox},
					FontName => name($subsetname),
					ItalicAngle => $info->{ItalicAngle},
					StemV => 0, # OK?
					# FontFile2 added later
				})),
				# CIDToGIDMap added later
			}))],
		}));
		$docobj->_registsubset_ttf(
			name => $zname, ttf => $ttf, encoding => $encoding, 
			direction => $direction);
	}
	my $subset_unicodes = $docobj->_subsetttf($zname)->{subset_unicodes};
	# Hankaku font
	my($combo, $hfont);
	if( $hfontobj ) {
		$combo = 1;
		$hsize ||= 1;
		$hname = $hfontobj->{name};
		$hfont = $hfontobj->{font};
	} else {
		$combo = 0;
		$hsize = 0;
		$hname = $zname;
		$hfont = $zfont;
	}
	my $self = bless {
		docobj => $docobj, 
		#basefont => $basefont, 
		encoding => $encoding, 
		ttffile => $ttffile,
		zfont => $zfont, 
		hfont => $hfont, 
		zname => $zname, 
		hname => $hname,
		direction => $direction,
		code => $code,
		combo => $combo,
		hsize => $hsize,
		hfontobj => $hfontobj,
		subset_unicodes => $subset_unicodes,
	}, $class;
	$docobj->_registfont($self);
	$self;
}

use Data::Dumper;

sub new_otf {
	my($class, $docobj, $otffile, $encoding, $hfontobj, $hsize) = @_;
	croak "OpenType embedding requires PDF version 1.6 or above"
		if $docobj->{version} < 1.6;
	croak "ascii font type mismatch"
		if $hfontobj && !PDFJ::Util::objisa($hfontobj, "PDFJ::AFont");
	my $name = $docobj->_fontname($otffile, $encoding);
	my $hname = $hfontobj ? $hfontobj->{name} : undef;
	return $docobj->_fontobj($name, $hname, $hsize) 
		if $name && $docobj->_fontobj($name, $hname, $hsize);
	# Zenkaku font
	my $code = $PDFJ::Default{Jcode};
	my($direction) = $encoding =~ /-(\w+)$/;
	my($zname, $zfont);
	if( $name ) {
		$zname = $name;
		$zfont = $docobj->_font($name);
	} else {
		my $otf = PDFJ::Util::otfopen($otffile);
		my $info = $otf->pdf_info_cid($encoding);
		croak "'$otffile' embedding inhibited ($info->{EmbedFlag})"
			if $info->{EmbedFlag} == 2 || $info->{EmbedFlag} & 0x100 ||
				$info->{EmbedFlag} & 0x200;
		my $subsetname = $docobj->_nextsubsettag . '+' . $info->{BaseFont};
		my $basefont = $info->{BaseFont};
		my $ename = substr($PDFJ::Default{Encodings}{$encoding}, 0, 1);
		my $cidsi = $docobj->_cidsysteminfo($ename);
		my $w = $ename eq 'j' ? [231, 389, 500, 631, [500]] : [];
		$zname = "F".$docobj->_nextfontnum;
		$zfont = $docobj->indirect(dictionary({
			Name => name($zname),
			Type => name("Font"),
			Subtype => name('Type0'),
			Encoding => $docobj->cmap($encoding),
			BaseFont => name($subsetname),
			DescendantFonts => [$docobj->indirect(dictionary({
				Type => name('Font'),
				Subtype => name('CIDFontType0'), # OpenType
				BaseFont => name($basefont),
				CIDSystemInfo => $cidsi,
				DW => 1000,
				# W => [231, 389, 500, 631, [500]],
				W => $w,
				FontDescriptor => $docobj->indirect(dictionary({
					Type => name('FontDescriptor'),
					Ascent => $info->{Ascent},
					CapHeight => $info->{CapHeight},
					Descent => $info->{Descent},
					Flags => $info->{Flags},
					FontBBox => $info->{FontBBox},
					FontName => name($subsetname),
					ItalicAngle => $info->{ItalicAngle},
					StemV => 0, # OK?
					# FontFile3 added later
				})),
			}))],
		}));
		$docobj->_registsubset_otf(
			name => $zname, otf => $otf, encoding => $encoding, 
			direction => $direction);
	}
	my $subset_unicodes = $docobj->_subsetotf($zname)->{subset_unicodes};
	# Hankaku font
	my($combo, $hfont);
	if( $hfontobj ) {
		$combo = 1;
		$hsize ||= 1;
		$hname = $hfontobj->{name};
		$hfont = $hfontobj->{font};
	} else {
		$combo = 0;
		$hsize = 0;
		$hname = $zname;
		$hfont = $zfont;
	}
	my $self = bless {
		docobj => $docobj, 
		#basefont => $basefont, 
		encoding => $encoding, 
		otffile => $otffile,
		zfont => $zfont, 
		hfont => $hfont, 
		zname => $zname, 
		hname => $hname,
		direction => $direction,
		code => $code,
		combo => $combo,
		hsize => $hsize,
		hfontobj => $hfontobj,
		subset_unicodes => $subset_unicodes,
	}, $class;
	$docobj->_registfont($self);
	$self;
}

sub fname {
	my($self) = @_;
	$self->{combo} ? join($;, $self->{zname}, $self->{hname}, $self->{hsize}) :
		$self->{zname};
}

sub selectname { 
	my($self, $style) = @_;
	my $docobj = $self->{docobj};
	split $;, $docobj->_bolditalicname($self->fname, $style);
}

sub selectfont {
	my($self, $style) = @_;
	$self->{docobj}->_bolditalicfont($self, $style);
}

sub hash {
	my $self = shift;
	($self->{zname}, $self->{zfont}, $self->{hname}, $self->{hfont});
}

sub astring_fontwidth {
	my($self, $string) = @_;
	my $combo = $self->{combo};
	my $hfont = $self->{hfontobj};
	if( $combo ) {
		$self->{hsize} * $hfont->string_fontwidth($string);
	} else {
		length($string) / 2;
	}
}

#--------------------------------------------------------------------------
package PDFJ::BlockElement;
use Carp;
use strict;

sub size { 0 }
sub preskip { 0 }
sub postskip { 0 }
sub postnobreak { 0 }
sub breakable { 0 }
sub float { "" }
sub colspan { 1 }
sub rowspan { 1 }
sub blockalign { "" }

#--------------------------------------------------------------------------
package PDFJ::Showable;
use Carp;
use strict;
use PDFJ::Object;
use vars qw(@ISA);
@ISA = qw(PDFJ::BlockElement);

sub typename {
	my($self, $name) = @_;
	if( defined $name ) {
		$self->{typename} = $name;
	} else {
		$self->{typename};
	}
}

sub show {
	my($self, $page, $x, $y, $align, $transtype, @args)
		= PDFJ::Util::methodargs([qw(page x y align transtype transargs)], @_);
	if( ref($args[0]) eq 'ARRAY' ) {
		@args = @{$args[0]};
	}
	if( $transtype ) {
		my @matrix = PDFJ::Util::transmatrix($x, $y, $transtype, @args);
		if( @matrix ) {
			$page->addcontents("q", numbers(@matrix), "cm");
		}
		($x, $y) = (0, 0);
	}
	if( $align ) {
		if( $align =~ /l/ ) {
			$x -= $self->left;
		} elsif( $align =~ /r/ ) {
			$x -= $self->right;
		} elsif( $align =~ /c/ ) {
			$x -= ($self->left + $self->right) / 2;
		}
		if( $align =~ /t/ ) {
			$y -= $self->top;
		} elsif( $align =~ /b/ ) {
			$y -= $self->bottom;
		} elsif( $align =~ /m/ ) {
			$y -= ($self->top + $self->bottom) / 2;
		}
	}
	$self->_show($page, $x, $y);
	if( $transtype ) {
		$page->addcontents("Q");
	}
	my $onshow = $self->onshow;
	if( ref($onshow) eq 'CODE' ) {
		&$onshow;
	}
	return;
}

#--------------------------------------------------------------------------
package PDFJ::Style;
use strict;
use Carp;

sub new {
	my($class, @args) = @_;
	if( ref($class) ) {
		$class = ref($class);
	}
	my $self;
	if( @args == 1 ) {
		if( $args[0] && !ref($args[0]) ) {
			$self = PDFJ::Util::strstyle2hashref($args[0]);
		} elsif( $args[0] && 
			(ref($args[0]) eq 'HASH' || ref($args[0]) eq $class) ) {
			%$self = %{$args[0]};
		} else {
			croak "illegal $class->new() argument";
		}
	} else {
		%$self = @args;
	}
	if( keys %$self == 1 && $self->{style} ) {
		$self = $class->new($self->{style});
	}
	for my $key(keys %$self) {
		if( $key =~ /(style|color)$/ && 
			(!ref($self->{$key}) || ref($self->{$key}) eq 'HASH') ) {
			$self->{$key} = 
				$key =~ /color$/ ? PDFJ::Color->new($self->{$key}) :
				$key eq 'withnotestyle' ? PDFJ::TextStyle->new($self->{$key}) :
				$key =~ /style$/ ? PDFJ::ShapeStyle->new($self->{$key}) :
				$self->{$key};
		}
	}
	bless $self, $class;
}

sub clone {
	my $self = shift;
	$self->_clone(0, @_);
}
sub linkedclone {
	my $self = shift;
	$self->_clone(1, @_);
}
sub _clone {
	my($self, $linked, @args) = @_;
	my $clone;
	if( @args ) {
		my %args;
		if( @args == 1 ) {
			if( !ref($args[0]) ) {
				%args = %{PDFJ::Util::strstyle2hashref($args[0])};
			} elsif( ref($args[0]) eq 'HASH' || ref($args[0]) eq ref($self) ) {
				%args = %{$args[0]};
			} else {
				croak "illegal clone() argument";
			}
		} else {
			%args = @args;
		}
		if( $args{style} ) {
			$clone = $self->clone($args{style});
			delete $args{style};
		} else {
			$clone = $self->new(%$self);
		}
		for my $key(keys %args) {
			$clone->{$key} = $args{$key};
		}
	} else {
		$clone = $self->new(%$self);
	}
	delete $clone->{_clone};
	if( $linked ) {
		push @{$self->{_clone}}, $clone;
	}
	$clone;
}

sub merge {
	my($self, $from, @nomerge) = @_;
	for my $key(keys %$from) {
		next if $key eq '_clone';
		next if grep {$_ eq $key} @nomerge;
		$self->{$key} = $from->{$key} unless exists $self->{$key};
	}
	$self;
}

#--------------------------------------------------------------------------
package PDFJ::TextStyle;
use strict;
use Carp;
use vars qw(@ISA);
@ISA = qw(PDFJ::Style);

sub TStyle { PDFJ::TextStyle->new(@_) }

sub merge {
	my($self, $from) = @_;
	if( $self->{suffix} ) {
		$self->{fontsize} = $from->{fontsize} * 
			$PDFJ::Default{SuffixSize};
		$self->{rise} = 
			$self->{suffix} eq 'u' ? $from->{fontsize} * 
				$PDFJ::Default{USuffixRise} :
			$self->{suffix} eq 'l' ? $from->{fontsize} * 
				$PDFJ::Default{LSuffixRise} : 
			0;
	}
	$self->SUPER::merge($from, 'ruby');
	if( $self->{_clone} ) {
		for my $cstyle(@{$self->{_clone}}) {
			$cstyle->merge($self);
		}
	}
	$self;
}

sub selectfontname {
	my($self) = @_;
	return unless $self->{font};
	$self->{font}->selectname($self);
}

sub selectfont {
	my($self) = @_;
	return unless $self->{font};
	$self->{font}->selectfont($self);
}

#--------------------------------------------------------------------------
package PDFJ::TextSpec;
use Carp;
use strict;
use PDFJ::Object;

sub new {
	my($class, @args) = @_;
	my $self = bless {}, $class;
	$self->set(@args) if @args;
	$self;
}

# for debug
sub print {
	my($self) = @_;
	for my $key(qw(fontsize render rise mode)) {
		print "$key => $self->{$key}, ";
	}
	print "\n";
}

sub set {
	my($self, $style, $fontname, $sizeratio) = @_;
	%$self = ();
	for my $key(qw(fontsize render rise shapestyle contentmark)) {
		if( exists $style->{$key} ) {
			$self->{$key} = $style->{$key};
		}
	}
	$self->{fontname} = $fontname;
	if( $self->{fontsize} && $sizeratio ) {
		$self->{fontsize} *= $sizeratio;
	}
}

sub copy {
	my($self, $from) = @_;
	%$self = %$from;
}

sub equal {
	my($self, $other) = @_;
	for my $key(qw(fontname fontsize render rise shapestyle contentmark)) {
		return 0 if ($self->{$key} || "") ne ($other->{$key} || "");
	}
	return 1;
}

sub pdf {
	my($self) = @_;
	croak "no fontsize specification" unless $self->{fontsize};
	my $fontname = $self->{fontname};
	my $fontsize = $self->{fontsize};
	my $rise = $self->{rise} || 0;
	my $render = $self->{render} || 0;
	my @shapepdf = $self->{shapestyle} ? $self->{shapestyle}->pdf : ();
	my $contentmark = $self->{contentmark};
	my @pdf = $contentmark ne '' ? ("/$contentmark BMC q") : ("q");
	push @pdf, @shapepdf if @shapepdf;
	push @pdf, "BT /$fontname", number($fontsize), "Tf", number($rise), "Ts $render Tr";
	@pdf;
}

sub endpdf {
	my($self) = @_;
	$self->{contentmark} ne '' ? "] TJ ET Q EMC " : "] TJ ET Q ";
}

#--------------------------------------------------------------------------
package PDFJ::NewLine;
use Carp;
use strict;

sub NewLine { PDFJ::NewLine->new(@_) }

sub new { 
	my($class, $level) = PDFJ::Util::methodargs([qw(level)], @_);
	$level ||= 0;
	bless \$level, $class;
}

sub level { ${$_[0]} }

#--------------------------------------------------------------------------
package PDFJ::Outline;
use Carp;
use strict;

sub Outline { PDFJ::Outline->new(@_) }

sub new { 
	my($class, $title, $level)
		= PDFJ::Util::methodargs([qw(title level)], @_);
	bless {outlinetitle => $title, outlinelevel => $level}, $class;
}

#--------------------------------------------------------------------------
package PDFJ::Dest;
use Carp;
use strict;

sub Dest { PDFJ::Dest->new(@_) }

sub new { 
	my($class, $name)
		= PDFJ::Util::methodargs([qw(name)], @_);
	bless {destname => $name}, $class;
}

#--------------------------------------------------------------------------
package PDFJ::Null;
use Carp;
use strict;

sub Null { PDFJ::Null->new(@_) }

sub new { 
	my($class, @args) = @_;
	my %args;
	if( @args > 1 ) {
		%args = @args;
	} elsif( @args == 1 && ref($args[0]) eq 'HASH' ) {
		%args = %{$args[0]};
	}
	bless \%args, $class;
}

#--------------------------------------------------------------------------
package PDFJ::Space;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Showable);

sub Space { PDFJ::Space->new(@_) }

# $glue : "min,normal,max,pref" unit is fontsize
sub new { 
	my($class, $size, $glue, $style) = 
		PDFJ::Util::methodargs([qw(size glue style)], @_);
	$size ||= 0;
	if( defined $glue ) {
		my($gmin, $gnormal, $gmax, $gpref) = 
			ref($glue) eq 'ARRAY' ? @$glue : split(/\s*,\s*/, $glue);
		my($gluedec, $glueinc) = (($gnormal - $gmin), ($gmax - $gnormal));
		$glue = [$gnormal, $gluedec, $glueinc, $gpref];
	}
	bless {size => $size, glue => $glue, style => $style}, $class;
}

sub textstyle { $_[0]->{style} }

sub _show {
	my($self, $page, $x, $y) = @_;
	my $style = $self->{style};
	if( $style && ref($style->{pageattr}) eq 'HASH' ) {
		for my $key(keys %{$style->{pageattr}}) {
			$page->setattr($key, $style->{pageattr}{$key});
		}
	}
}
sub onshow {}
sub size { $_[0]->{size} }
sub width { $_[0]->{size} }
sub height { $_[0]->{size} }
sub left { 0 }
sub right { $_[0]->{size} }
sub top { $_[0]->{size} }
sub bottom { 0 }
sub glue { 
	my($self) = @_;
	my $glue = $self->{glue};
	if( ref($glue) eq 'ARRAY' ) {
		@$glue;
	} else {
		(0,0,0,0);
	}
}

#--------------------------------------------------------------------------
package PDFJ::Text;
use Carp;
use strict;
use PDFJ::Object;
use vars qw(@ISA);
@ISA = qw(PDFJ::Showable);

sub Text { PDFJ::Text->new(@_) }

sub new {
	my($class, $texts, $style)
		= PDFJ::Util::listargs2ref(1, 1, 
			PDFJ::Util::methodargs([qw(texts style)], @_));
	if( PDFJ::Util::objisa($style, 'PDFJ::TextStyle') ) {
		$style = $style->clone;
	} elsif( $style && (!ref($style) || ref($style) eq 'HASH') ) {
		$style = PDFJ::TextStyle->new($style);
	} else {
		croak "style argument must be a PDFJ::TextStyle object or HASHref";
	}
	my $self = bless { texts => $texts, style => $style }, $class;
	$self->mergestyle;
	# $self->print;
	$self->makechunks;
	$self;
}

sub mergestyle {
	my($self, $indent) = @_;
	my $style = $self->style;
	return unless $style->{font};
	for my $text(@{$self->texts}) {
		if( PDFJ::Util::objisa($text, 'PDFJ::Text') ) {
			$text->style->merge($style);
			$text->mergestyle("$indent  ");
		}
	}
	for my $cstyle(@{$style->{_clone}}) {
		$cstyle->merge($style);
	}
}

# for debug
sub print {
	my($self, $indent) = @_;
	my $style = $self->style;
	print $indent,join(',',%$style),"\n";
	for my $text(@{$self->texts}) {
		if( PDFJ::Util::objisa($text, 'PDFJ::Text') ) {
			$text->print("$indent  ");
		} else {
			print "$indent\[$text]\n";
		}
	}
}

sub makechunks {
	my($self) = @_;
	my $style = $self->style;
	return unless $style->{font};
	my $noshift = $style->{noshift};
	$self->{chunks} = [];
	$self->{lines} = [];
	for my $text(@{$self->texts}) {
		if( !ref($text) ) {
			$self->catchunks($self->splittext($text, $noshift));
		} elsif( PDFJ::Util::objisa($text, 'PDFJ::Text') ) {
			$text->makechunks unless $text->chunks;
			if( exists $text->style->{ruby} ) {
				my($rubytext, $altobj, $rubyoverlap) =
					$self->makerubytext($text->style->{ruby}, $text, 
					$text->style);
				my $chunk = _rubychunk($altobj, $style, $rubyoverlap);
				$chunk->{RubyText} = $rubytext;
				$self->catchunks([$chunk]);
			} else {
				$self->catchunks($text->chunks);
			}
		} elsif( PDFJ::Util::objisa($text, 'PDFJ::Showable') ) {
			$self->catchunks([_objchunk($text, $style)]);
		} elsif( PDFJ::Util::objisa($text, 'PDFJ::NewLine') ) {
			$self->catchunks([_newlinechunk($style)]);
		} elsif( PDFJ::Util::objisa($text, 'PDFJ::Outline') ) {
			$self->catchunks([_outlinechunk($text, $style)]);
		} elsif( PDFJ::Util::objisa($text, 'PDFJ::Dest') ) {
			$self->catchunks([_destchunk($text, $style)]);
		} elsif( PDFJ::Util::objisa($text, 'PDFJ::Null') ) {
			$self->catchunks([_nullchunk($text, $style)]);
		} elsif( PDFJ::Util::objisa($text, 'PDFJ::TextChunk') ) {
			$self->catchunks([$text]);
		} else {
			croak "illegal texts element for Text: $text";
		}
	}
}

sub makerubytext {
	my($self, $ruby, $parent, $style) = @_;
	my $altparent = $parent;
	my $rubyoverlap = 0;
	my $rubystyle = $style->clone;
	delete $rubystyle->{ruby};
	delete $rubystyle->{withbox};
	delete $rubystyle->{withline};
	$rubystyle->{fontsize} /= 2;
	my $rubytext = PDFJ::Text->new($style->{ruby}, $rubystyle);
	my $rubysize = $rubytext->size;
	my $parentsize = $parent->size;
	if( $rubysize < $parentsize ) {
		my $alt = PDFJ::Paragraph->new($rubytext,
			PDFJ::ParagraphStyle->new(size => $parentsize, 
				align => 'ruby', linefeed => 0));
		$rubytext = $alt;
	} elsif( $rubysize > $parentsize ) {
		my $alt = PDFJ::Paragraph->new(
			$parent,
			PDFJ::ParagraphStyle->new(size => $rubysize, 
				align => 'ruby', linefeed => 0));
		$altparent = $alt;
		$rubyoverlap = $alt->line(0)->{Shift};
		$rubyoverlap = $rubystyle->{fontsize} 
			if $rubyoverlap > $rubystyle->{fontsize};
	}
	($rubytext, $altparent, $rubyoverlap);
}

sub texts { $_[0]->{texts} }
sub chunks { $_[0]->{chunks} }
sub chunksnum { scalar(@{$_[0]->{chunks}}) }
sub chunk { $_[0]->{chunks}[$_[1]] }
sub style { $_[0]->{style} }
sub direction { $_[0]->{style}{font}{direction} }
sub fontsize { $_[0]->{style}{fontsize} }

sub width {
	my($self) = @_;
	$self->direction eq 'H' ? 
		_chunkssize($self->{chunks}) :
		$self->fontsize;
}

sub height {
	my($self) = @_;
	$self->direction eq 'H' ? 
		$self->fontsize :
		_chunkssize($self->{chunks});
}

sub left {
	my($self) = @_;
	$self->direction eq 'H' ? 
		0 :
		- ($self->fontsize / 2);
}

sub right {
	my($self) = @_;
	$self->direction eq 'H' ? 
		_chunkssize($self->{chunks}) :
		$self->fontsize / 2;
}

sub top {
	my($self) = @_;
	$self->direction eq 'H' ? 
		$self->fontsize * (1 - $PDFJ::Default{HBaseShift}) :
		0;
}

sub bottom {
	my($self) = @_;
	$self->direction eq 'H' ? 
		$self->fontsize * (- $PDFJ::Default{HBaseShift}) :
		_chunkssize($self->{chunks});
}

sub size {
	my($self, $direction) = @_; # neglect $direction
	_chunkssize($self->{chunks});
}

sub blockalign {  
	my($self) = @_;
	$self->{style}{blockalign};
}

sub fixsize {
	my($self, $start, $count, $fixedglues) = @_;
	_chunksfixsize($self->{chunks}, $start, $count, $fixedglues);
}

sub count {
	my($self) = @_;
	_chunkscount($self->{chunks});
}

sub dehyphen {
	my($self) = @_;
	return unless $self->{hyphened};
	my $chunks = $self->chunks;
	for( my $j = 0; $j < @$chunks; $j++ ) {
		my $chunk = $chunks->[$j];
		my $hyphened = $chunk->{Hyphened};
		if( $hyphened && $j < @$chunks - 1 ) {
			$chunk->{String} =~ s/-$// if $hyphened == 2;
			$chunk->{String} .= $chunks->[$j + 1]->{String};
			$chunk->{Count} = length $chunk->{String};
			$chunk->{Hyphened} = 0;
			splice @$chunks, $j + 1, 1;
		}
	}
	$self->{hyphened} = 0;
}

sub _fold {
	my($self, $paraobj) = @_;
	my $chunks = $self->chunks;
	return unless $chunks && @$chunks;
	$self->dehyphen;
	my @lines;
	my $rubyshift = 0;
	if( $paraobj->align(0) eq 'ruby' ) {
		$rubyshift = ($paraobj->linesize(0) - _chunkssize($chunks)) / 
			#$self->count;
			@$chunks;
		$rubyshift /= 2;
		$paraobj->align(0, 'W');
	}
	my $lineskipmin = $paraobj->{lineskipmin};
	my $lineskip = $paraobj->{lineskip};
	my $lastpostaols = 0;
	my $start = 0;
	my $lines = 0;
	while( $start < @$chunks ) {
		$lines = @lines;
		my $linesize = $paraobj->linesize($lines);
		croak "not enough paragraph size" if $linesize < 0;
		if( $lines == 0 ) {
			$linesize -= $rubyshift * 2;
		}
		my $align = $paraobj->align($lines);
		my $size = 0;
		my $decsize = 0;
		my $foldpos = $start;
		my $canpos = $start;
		my $forced;
		for( my $j = $start; $j < @$chunks; $j++ ) {
			my $chunk = $chunks->[$j];
			if( $chunk->{Style} ) {
				if( exists $chunk->{Style}{align} ) {
					$paraobj->align($lines, $chunk->{Style}{align});
					$align = $paraobj->align($lines);
				}
				if( exists $chunk->{Style}{beginindent} ) {
					$paraobj->beginindent($lines + 1, 
						$chunk->{Style}{beginindent});
				}
				if( exists $chunk->{Style}{endindent} ) {
					$paraobj->endindent($lines, $chunk->{Style}{endindent});
					$linesize = $paraobj->linesize($lines);
				}
			}
			if( $chunk->{Splittable} == 2 ) {
				$foldpos = $j + 1;
				$forced = 1;
				last;
			}
			my($chunksize, $decchunksize) = _chunksize($chunk, ($j == $start));
			$size += $chunksize;
			$decsize += $decchunksize unless $j == $start;
			my $k = $j + 1;
			if( $k == @$chunks || ($chunks->[$k]{Splittable} && 
				!_isnoeol($chunks, $k) && !_isnobol($chunks, $k)) ) {
				if( $size == $linesize ) {
					$foldpos = $k;
					last;
				} elsif( $size < $linesize ) {
					$canpos = $k;
				} else { # $size > $linesize
					my $hyphenpos = 0;
					if( $align =~ /w/i && 
						$size - $decsize <= $linesize ) {
						$foldpos = $k;
					} elsif( ($hyphenpos = 
						_hyphenpos($chunks->[$j], $size - $linesize)) ) {
						_inshyphen($chunks, $j, $hyphenpos);
						$self->{hyphened} = 1;
						$foldpos = $k;
					} elsif( $k == $start + 1 ) {
						$foldpos = $k;
					} elsif( $canpos == $start ) {
						if( $k < @$chunks && $chunks->[$k]{Splittable} == 2 ) {
							$foldpos = $k + 1;
							$forced = 1;
						} else {
							$foldpos = $k;
						}
					} else {
						$foldpos = $canpos;
					}
					last;
				}
			}
#print "$linesize [$j:$start]($chunk->{Splittable})[$chunk->{String}] $chunksize(-$decchunksize) $size(-$decsize) $canpos\n";
		}
		if( $foldpos == $start && $size > $linesize && 
				!($align =~ /w/i && $size - $decsize <= $linesize) ) {
			$foldpos =  $canpos;
		}
		$foldpos = @$chunks if $foldpos == $start;
		my $nextpos = $foldpos;
		unless( $forced ) {
			while( $nextpos < @$chunks && $chunks->[$nextpos]{Class} eq 16 ) {
				$nextpos++;
			}
		}
		while( $foldpos > 0 && ($chunks->[$foldpos - 1]{Class} eq 16 || 
				$chunks->[$foldpos - 1]{Splittable} == 2) ) {
			$foldpos--;
		}
		my $count = $foldpos - $start;
		$size = _chunkssize($chunks, $start, $count);
		my $shift = 0;
		my $fixedglues = [];
		if( $align eq 'e' ) {
			$shift = $linesize - $size;
		} elsif( $align eq 'm' ) {
			$shift = ($linesize - $size) / 2;
		} elsif( $align eq 'W' || ($align eq 'w' && $count && 
			(($nextpos < @$chunks && $chunks->[$foldpos]{Splittable} != 2)
			|| $size > $linesize)) ) {
			$fixedglues = $self->fixglue($start, $count, $linesize - $size);
			if( $rubyshift ) {
				$shift = $rubyshift + ($linesize - 
					$self->fixsize($start, $count, $fixedglues)) / 2;
			}
		}
		my $preskip;
		my($preaols, $postaols) = (0, 0);
		if( defined $lineskipmin ) {
			($preaols, $postaols) = $self->altobjlineskip($start, $count);
			$preskip = $lastpostaols + $preaols + $lineskipmin;
			$preskip = $lineskip if $preskip < $lineskip;
			$lastpostaols = $postaols;
		} else {
			$preskip = $lineskip;
		}
		my %hash =(
		    Start      => $start ,
		    Count      => $count ,
		    Shift      => $shift ,
		    FixedGlues => $fixedglues ,
		    PreAOLS    => $preaols ,
		    PostAOLS   => $postaols,
		    PreSkip    => $preskip ,
		    );
		push(@lines,\%hash);
		$start = $nextpos;
	}
	@lines;
}

sub _hyphenpos {
	my($chunk, $decsize) = @_;
	return unless $chunk->{Class} == 17 && !$chunk->{Style}{nohyphen} &&
		!$chunk->{Style}{ruby};
	my $string = $chunk->{String};
	my($can, $canleft, $pre, $word);
	if( $string =~ /([A-Za-z]-)([A-Za-z])/ ) {
		$can = $`.$1;
		$canleft = $2.$'; #'
	} elsif( $string =~ /[A-Za-z]{5,}/ ) {
		$pre = $`;
		$word = $&;
	}
	return unless $can || $word;
	my $fontobj = $chunk->{Style}{font};
	my $fontsize = $chunk->{Style}{fontsize};
	$decsize /= $fontsize;
	if( $can ) {
		if( $fontobj->astring_fontwidth($canleft) >= $decsize ) {
			return length($can);
		} else {
			return;
		}
	}
	my $size = $fontobj->astring_fontwidth($word);
	return if $size <= $decsize;
	my $maxsize = $size - $decsize;
	for my $pos(reverse PDFJ::Util::hyphenate($word)) {
		return length($pre) + $pos 
			if $fontobj->astring_fontwidth($pre.substr($word, 0, $pos).'-')
				<= $maxsize;
	}
	return;
}

sub _inshyphen {
	my($chunks, $idx, $hyphenpos) = @_;
	my $chunk = $chunks->[$idx];
	my $string = $chunk->{String};
	my $inschunk;
	@$inschunk = @$chunk;
	my $work = substr $string, 0, $hyphenpos;
	if( $work =~ /-$/ ) {
		$chunk->{Hyphened} = 1;
	} else {
		$chunk->{Hyphened} = 2;
		$work .= '-';
	}
	$chunk->{String} = $work;
	$chunk->{Count} = length $chunk->{String};
	$inschunk->{String} = substr $string, $hyphenpos;
	$inschunk->{Count} = length $inschunk->{String};
	splice @$chunks, $idx + 1, 0, $inschunk;
}

sub _chunkssize {
	my($chunks, $start, $count) = @_;
	die "cannot calc size of Text, may be missing font in TextStyle"
		unless $chunks;
	$start += 0;
	$start = 0 if $start < 0;
	$count ||= @$chunks - $start;
	my $result;
	for(my $j = 0; $j < $count && $start + $j < @$chunks; $j++ ) {
		$result += _chunksize($chunks->[$start + $j], ($j == 0));
	}
	$result;
}

sub _chunksfixsize {
	my($chunks, $start, $count, $fixedglues) = @_;
	$start += 0;
	$start = 0 if $start < 0;
	$count ||= @$chunks - $start;
	my $result;
	for(my $j = 0; $j < $count && $start + $j < @$chunks; $j++ ) {
		$result += _chunkfixsize($chunks->[$start + $j], $fixedglues->[$j]);
	}
	$result;
}

sub _chunkscount {
	my($chunks, $start, $count) = @_;
	$start += 0;
	$start = 0 if $start < 0;
	$count ||= @$chunks - $start;
	my $result;
	for(my $j = 0; $j < $count && $start + $j < @$chunks; $j++ ) {
		$result += _chunkcount($chunks->[$start + $j]);
	}
	$result;
}

# check if last chunk is NoEOL
sub _isnoeol {
	my($chunks, $pos) = @_;
	while( $pos > 0 && $chunks->[$pos - 1]{Class} == 16 ) {
		$pos--;
	}
	return unless $pos > 0;
	$PDFJ::Default{NoEOL}[$chunks->[$pos - 1]{Class}];
}

# check if next chunk is NoBOL
sub _isnobol {
	my($chunks, $pos) = @_;
	while( $pos < @$chunks && $chunks->[$pos]{Class} == 16 ) {
		$pos++;
	}
	return unless $pos < @$chunks;
	$PDFJ::Default{NoBOL}[$chunks->[$pos]{Class}];
}

sub _chunkcount {
	my($chunk) = @_;
	$chunk->{Count};
}

sub _chunksize {
	my($chunk, $noglue) = @_;
	#my $fontobj = $chunk->{Style}{font};
	my $fontobj = $chunk->{Style}->selectfont;
	unless( $fontobj ) {
		croak "internal error: missing font in style";
	}
	my $fontsize = $chunk->{Style}{fontsize};
	my $direction = $fontobj->{direction};
	my $size = $direction eq 'H' ? 
		_chunkfontsizeH($fontobj, $fontsize, $chunk) :
		_chunkfontsizeV($fontobj, $fontsize, $chunk);
	$size += $fontsize * (($noglue ? 0 : $chunk->{Glue}) - 
		$chunk->{PreShift} - $chunk->{PostShift});
	if( wantarray ) {
		my $decsize = $chunk->{GlueDec} * $fontsize;
		my $incsize = $chunk->{GlueInc} * $fontsize;
		($size, $decsize, $incsize);
	} else {
		$size;
	}
}

sub _chunkfixsize {
	my($chunk, $fixedglue) = @_;
	$fixedglue ||= 0;
	my $fontobj = $chunk->{Style}{font};
	unless( $fontobj ) {
		croak "internal error: missing font in style";
	}
	my $fontsize = $chunk->{Style}{fontsize};
	my $direction = $fontobj->{direction};
	my $size = $direction eq 'H' ? 
		_chunkfontsizeH($fontobj, $fontsize, $chunk) :
		_chunkfontsizeV($fontobj, $fontsize, $chunk);
	$size += $fontsize * ($chunk->{Glue} + $fixedglue - 
		$chunk->{PreShift} - $chunk->{PostShift});
	$size;
}

sub _chunkfontsizeH {
	my($fontobj, $fontsize, $chunk) = @_;
	return $chunk->{AltObj}->size('H') if $chunk->{AltObj};
	my $size = 0;
	if( PDFJ::Util::objisa($fontobj, "PDFJ::CIDFont") ) {
		my $combo = $fontobj->{combo};
		my $hfont = $fontobj->{hfontobj};
		my $mode = $chunk->{Mode};
		if( $mode eq 'z' ) {
			$size = $chunk->{Count};
		} elsif( $mode eq 'h' ) {
			$size = $chunk->{Count} / 2;
		} elsif( $combo ) {
			$size = $fontobj->{hsize} * 
				$hfont->string_fontwidth($chunk->{String});
		} else {
			$size = $chunk->{Count} / 2;
		}
	} elsif( PDFJ::Util::objisa($fontobj, "PDFJ::AFont") ) {
		$size = $fontobj->string_fontwidth($chunk->{String});
	} else { 
		croak "internal error: missing font object ($fontobj)";
	}
	$size *= $fontsize;
	$size;
}

sub _chunkfontsizeV {
	my($fontobj, $fontsize, $chunk) = @_;
	return $chunk->{AltObj}->size('V') if $chunk->{AltObj};
	my $size = 0;
	if( PDFJ::Util::objisa($fontobj, "PDFJ::CIDFont") ) {
		my $combo = $fontobj->{combo};
		my $hfont = $fontobj->{hfontobj};
		my $mode = $chunk->{Mode};
		if( $mode eq 'z' ) {
			$size = $chunk->{Count};
		} elsif( $mode eq 'h' ) {
			$size = $chunk->{Count};
		} elsif( $combo ) {
			$size = $chunk->{Class} == 11 ? 1 :
				$fontobj->{hsize} * $hfont->string_fontwidth($chunk->{String});
		} else {
			$size = $chunk->{Count};
		}
	} elsif( PDFJ::Util::objisa($fontobj, "PDFJ::AFont") ) {
		$size = $fontobj->string_fontwidth($chunk->{String});
	} else { 
		croak "internal error: missing font object ($fontobj)";
	}
	$size *= $fontsize;
	$size;
}


sub fixglue {
	my($self, $start, $count, $incsize) = @_;
	return unless $incsize;
	if( $incsize > 0 ) {
		&fixglueinc;
	} else {
		&fixgluedec;
	}
}

sub fixglueinc {
	my($self, $start, $count, $incsize) = @_;
	my @fixedglues;
	my %incgluesum;
	my $chunksnum = $self->chunksnum;
	# start counter is not 0 but 1 because first chunk glue is not used
	for( my $j = 1; $j < $count && $start + $j < $chunksnum; $j++ ) {
		my $chunk = $self->chunk($start + $j);
		if( $chunk->{GlueInc} ) {
			$incgluesum{$chunk->{GluePref} + 0} += 
				$chunk->{GlueInc} * $chunk->{Style}{fontsize};
		}
	}
	for my $pref(reverse sort keys %incgluesum) {
		last if $incsize <= 0;
		my $incgluesum = $incgluesum{$pref};
		my $ratio = $incgluesum > $incsize ? $incsize / $incgluesum : 1;
		for( my $j = 1; $j < $count && $start + $j < $chunksnum; $j++ ) {
			my $chunk = $self->chunk($start + $j);
			if( $chunk->{GlueInc} && $chunk->{GluePref} == $pref ) {
				#$chunk->{GlueFix} = $chunk->{GlueInc} * $ratio;
				$fixedglues[$j] = $chunk->{GlueInc} * $ratio;
			}
		}
		#$incsize -= $incgluesum * $ratio;
		$incsize -= $incgluesum;
	}
	if( $incsize > 0 ) {
		my $splittables = 0;
		for( my $j = 1; $j < $count && $start + $j < $chunksnum; $j++ ) {
			$splittables++ if $self->chunk($start + $j)->{Splittable};
		}
		if( $splittables ) {
			for( my $j = 1; $j < $count && $start + $j < $chunksnum; $j++ ) {
				my $chunk = $self->chunk($start + $j);
				if( $chunk->{Splittable} ) {
					#$chunk->{GlueFix} += $incsize / $chunk->{Style}{fontsize} / 
					#	$splittables;
					$fixedglues[$j] += $incsize / $chunk->{Style}{fontsize} / 
						$splittables;
				}
			}
		}
	}
	\@fixedglues;
}

sub fixgluedec {
	my($self, $start, $count, $incsize) = @_;
	my $decsize = -$incsize;
	my @fixedglues;
	my %decgluesum;
	my $chunksnum = $self->chunksnum;
	# start counter is not 0 but 1 because first chunk glue is not used
	for( my $j = 1; $j < $count && $start + $j < $chunksnum; $j++ ) {
		my $chunk = $self->chunk($start + $j);
		if( $chunk->{GlueDec} ) {
			$decgluesum{$chunk->{GluePref} + 0} += 
				$chunk->{GlueDec} * $chunk->{Style}{fontsize};
		}
	}
	for my $pref(reverse sort keys %decgluesum) {
		last if $decsize <= 0;
		my $decgluesum = $decgluesum{$pref};
		my $ratio = $decgluesum > $decsize ? $decsize / $decgluesum : 1;
		for( my $j = 1; $j < $count && $start + $j < $chunksnum; $j++ ) {
			my $chunk = $self->chunk($start + $j);
			if( $chunk->{GlueDec} && $chunk->{GluePref} == $pref ) {
				#$chunk->{GlueFix} = -$chunk->{GlueDec} * $ratio;
				$fixedglues[$j] = -$chunk->{GlueDec} * $ratio;
			}
		}
		#$decsize -= $decgluesum * $ratio;
		$decsize -= $decgluesum;
	}
	\@fixedglues;
}

sub onshow { $_[0]->{style}{onshow} }

sub _show {
	my($self, $page, $x, $y) = @_;
	$self->_showpart($page, $x, $y, 0, $self->chunksnum);
}

# This mega subroutine is too complex and patchy, needs refactering!
sub _showpart {
	my($self, $page, $x, $y, $start, $count, $fixedglues) = @_;
	my $docobj = $page->docobj;
	my $chunksnum = $self->chunksnum;
	my %usefontname;
	my(@tj, @dotpdf, @shapepdf);
	my $lasttextspec = PDFJ::TextSpec->new;
	my($ulx, $uly, $bxx, $bxy);
	my($lastfontsize, $postshift, $slant, $lastfrx, $lastfry, $va) = (0) x 6;
	my($lastfontname, $withlinestyle, $withbox, $withboxstyle) = ("") x 4;
	for( my $j = 0; $j < $count && $start + $j < $chunksnum; $j++ ) {
		my $chunk = $self->chunk($start + $j);
		my $mode = $chunk->{Mode};
		my $class = $chunk->{Class};
		# my $style = $chunk->{Style};
		my $style = $chunk->{Style}->clone;
		my $direction = $style->{font}->{direction};
		my($fontname, $hname, $hsize) = $style->selectfontname;
		my $fontobj = $style->{font} = 
			$docobj->_fontobj($fontname, $hname, $hsize);
		my $combo = $fontobj->{combo};
		my $usefname = $mode eq 'a' && $hname ? $hname : $fontname;
		$usefontname{$usefname}++;
		my $fontsize = $style->{fontsize};
		$postshift *= $lastfontsize / $fontsize;
		$style->{slant} = 1 if ($mode eq 'z' || !$combo) && $style->{italic};
		my $textspec = PDFJ::TextSpec->new($style, $usefname, 
			($mode eq 'a' ? $fontobj->{hsize} : 0));
#print "$j:$va:[$chunk->{String}] $mode, $class, {",join(",",%$style),"}\n";
		my $qclose = 0;
		if( $direction eq 'V' && $combo && $mode eq 'a' ) {
			if( $va != $class ) {
				$qclose = 1;
				$va = $class;
			}
		} elsif( $va ) {
			$qclose = 1;
			$va = 0;
		}
		if( $style->{slant} ) {
			#croak "slant style for ascii not allowed" 
			#	if $mode eq 'a';
			unless( $slant ) {
				$qclose = 1;
				$slant = 1;
			}
		} elsif( $slant ) {
			$qclose = 1;
			$slant = 0;
		}
		$qclose = 1 unless $lasttextspec->equal($textspec);
		if( $qclose ) {
			my @qopen;
			if( $direction eq 'V' && $combo && $mode eq 'a' ) {
				my($vax, $vay) = $class == 11 ? 
					($x - _chunkfontsizeH($fontobj, $fontsize, $chunk) / 2,
					$y - $fontsize * $PDFJ::Default{VHShift}) : 
					($x + $fontsize * $PDFJ::Default{VAShift}, $y);
				@qopen = ($class == 11 ? 
					($textspec->pdf, numbers($vax, $vay), "Td [") :
					$style->{slant} ? 
					($textspec->pdf, numbers(0, -1, 1, $PDFJ::Default{SlantRatio}, $vax, $vay), "Tm [") :
					($textspec->pdf, numbers(0, -1, 1, 0, $vax, $vay), "Tm ["));
			} elsif( $style->{slant} ) {
				my($sx, $sy) = $direction eq 'H' ? 
					(0, $PDFJ::Default{SlantRatio}) : 
					($PDFJ::Default{SlantRatio}, 0);
				@qopen = ($textspec->pdf, numbers(1, $sx, $sy, 1, $x, $y), 
					"Tm [");
			}
			push @tj, $lasttextspec->endpdf if @tj;
			push @tj, (@qopen ? @qopen : ($textspec->pdf, numbers($x, $y), 
				"Td ["));
			$lasttextspec->copy($textspec);
		}
		my $shift = $va == 11 ? 0 : $j == 0 ? $chunk->{PreShift} :
			$postshift + $chunk->{PreShift} -
			($fixedglues ? $chunk->{Glue} + ($fixedglues->[$j] || 0): 
			$chunk->{Glue});
		$shift = -$shift if $direction eq 'V';
		$shift *= 1000;
		if( $shift ) {
			my $vs = $va ? -$shift : $shift;
			push @tj, number($vs);
		}
		my($flx, $fly) = ($x, $y);
		my($frx, $fry) = ($x, $y);
		my($fcx, $fcy) = ($x, $y);
		if( $direction eq 'H' ) {
			#$flx -= ($postshift - ($j == 0 ? 0 : 
			#	($fixedglues ? $chunk->{Glue} + ($fixedglues->[$j] || 0): 
			#	$chunk->{Glue}))) * $fontsize;
			$flx -= ($j == 0 ? $chunk->{PreShift} : 
				$postshift + $chunk->{PreShift} - 
				($fixedglues ? $chunk->{Glue} + ($fixedglues->[$j] || 0): 
				$chunk->{Glue})) * $fontsize;
			$frx = $flx + (_chunkfontsizeH($fontobj, $fontsize, $chunk) -
				($chunk->{PreShift} + $chunk->{PostShift}) * $fontsize);
			$fcx = $flx + (_chunkfontsizeH($fontobj, $fontsize, $chunk) -
				($chunk->{PreShift} + $chunk->{PostShift}) * $fontsize) /
				 2;
		} else {
			#$fly += ($postshift - ($j == 0 ? 0 : 
			#	($fixedglues ? $chunk->{Glue} + ($fixedglues->[$j] || 0): 
			#	$chunk->{Glue}))) * $fontsize;
			$fly += ($j == 0 ? $chunk->{PreShift} : 
				$postshift + $chunk->{PreShift} - 
				($fixedglues ? $chunk->{Glue} + ($fixedglues->[$j] || 0): 
				$chunk->{Glue})) * $fontsize;
			$fry = $fly - (_chunkfontsizeV($fontobj, $fontsize, $chunk) -
				($chunk->{PreShift} + $chunk->{PostShift}) * $fontsize);
			$fcy = $fly - (_chunkfontsizeV($fontobj, $fontsize, $chunk) -
				($chunk->{PreShift} + $chunk->{PostShift}) * $fontsize) /
				 2;
		}
		if( $mode eq 'O' || $mode eq 'D' ) { # Outline or Dest
			my($ox, $oy) = ($flx, $fly);
			if( $direction eq 'H' ) {
				$oy += (1 - $PDFJ::Default{HBaseShift}) * $fontsize;
			} else {
				$ox -= $fontsize / 2;
			}
			if( $mode eq 'O' ) {
				my $title = $style->{outlinetitle};
				my $level = $style->{outlinelevel};
				$docobj->add_outline($title, $page, $ox, $oy, $level);
			} elsif( $mode eq 'D' ) {
				my $name = $style->{destname};
				$docobj->add_dest($name, $page, $ox, $oy);
			}
		}
		if( $chunk->{AltObj} ) {
			my $altobj = $chunk->{AltObj};
			my $altsize = $altobj->size($direction);
			my $objalign = $style->{objalign} || "";
			my $align;
			my($asx, $asy) = (0, 0);
			if( $direction eq 'H' ) {
				if( $objalign =~ /t/ ) {
					$align = 'tl';
					$asy += (1 - $PDFJ::Default{HBaseShift}) * $fontsize;
				} elsif( $objalign =~ /m/ ) {
					$align = 'ml';
					$asy += (0.5 - $PDFJ::Default{HBaseShift}) * $fontsize;
				} else { # /b/
					$align = 'bl';
					$asy += (- $PDFJ::Default{HBaseShift}) * $fontsize;
				}
			} else {
				if( $objalign =~ /l/ ) {
					$align = 'tl';
					$asx -= $fontsize / 2;
				} elsif( $objalign =~ /r/ ) {
					$align = 'tr';
					$asx += $fontsize / 2;
				} else { # /c/
					$align = 'tc';
				}
			}
			$altsize = $altsize * 1000 / $fontsize;
			$altsize = -$altsize if $direction eq 'H';
			push @tj, number($altsize);
			$altobj->show($page, $flx + $asx, $fly + $asy, $align);
		} else {
			my $ss = stringstring($chunk, $fontobj, $usefname);
			push @tj, $ss;
		}
		$postshift = $chunk->{PostShift};
		if( $style->{withline} ) {
			($ulx, $uly) = ($flx, $fly) unless defined $ulx;
			$withlinestyle = $style->{withlinestyle};
			if( $j == $count - 1 || $start + $j == $chunksnum - 1 ) {
				push @shapepdf, ($direction eq 'H' ? 
					_withlinepdf($direction, $ulx, $uly, $frx - $ulx, 
						$fontsize, $withlinestyle) :
					_withlinepdf($direction, $ulx, $uly, $fry - $uly, 
						$fontsize, $withlinestyle));
			}
		} elsif( defined $ulx ) {
			push @shapepdf, ($direction eq 'H' ? 
				_withlinepdf($direction, $ulx, $uly, $lastfrx - $ulx, 
					$lastfontsize, $withlinestyle) :
				_withlinepdf($direction, $ulx, $uly, $lastfry - $uly, 
					$lastfontsize, $withlinestyle));
			undef $ulx;
			undef $uly;
		}
		if( $style->{withbox} ) {
			($bxx, $bxy) = ($flx, $fly) unless defined $bxx;
			$withbox = $style->{withbox};
			$withboxstyle = $style->{withboxstyle};
			if( $j == $count - 1 || $start + $j == $chunksnum - 1 ) {
				push @shapepdf, ($direction eq 'H' ? 
					_withboxpdf($page, $direction, $bxx, $bxy, $frx - $bxx, 
						$fontsize, $withbox, $withboxstyle) :
					_withboxpdf($page, $direction, $bxx, $bxy, $fry - $bxy, 
						$fontsize, $withbox, $withboxstyle));
			}
		} elsif( defined $bxx ) {
			push @shapepdf, ($direction eq 'H' ? 
				_withboxpdf($page, $direction, $bxx, $bxy, $lastfrx - $bxx, 
					$lastfontsize, $withbox, $withboxstyle) :
				_withboxpdf($page, $direction, $bxx, $bxy, $lastfry - $bxy, 
					$lastfontsize, $withbox, $withboxstyle));
			undef $bxx;
			undef $bxy;
		}
		if( $style->{withdot} ) {
			croak "withdot style needs CIDFont"
				unless PDFJ::Util::objisa($fontobj, "PDFJ::CIDFont");
			my($dx, $dy, $ds, $dcode);
			if( $direction eq 'H' ) {
				($dx, $dy, $ds) = (
					$fcx - $fontsize / 2 + $fontsize * $PDFJ::Default{HDotXShift}, 
					$fcy + $fontsize * $PDFJ::Default{HDotYShift}, 
					$fontsize);
				$dcode = unpack('H*', $PDFJ::Default{HDot}{$PDFJ::Default{Jcode}})
			} else {
				($dx, $dy, $ds) = 
					($fcx + $fontsize * $PDFJ::Default{VDotXShift}, 
					$fcy + $fontsize / 2 + $fontsize * $PDFJ::Default{VDotYShift}, 
					$fontsize);
				$dcode = unpack('H*', $PDFJ::Default{VDot}{$PDFJ::Default{Jcode}})
			}
			my $fontname = $fontobj->{zname};
			push @dotpdf, "BT 0 Ts 0 Tr /$fontname", number($ds), "Tf", numbers($dx, $dy), "Td <$dcode> Tj ET";
		}
		if( $chunk->{RubyText} ) {
			my $rubytext = $chunk->{RubyText};
			if( $direction eq 'H' ) {
				$rubytext->show($page, $flx,
					$fly + $PDFJ::Default{ORuby} * $fontsize / 1000);
			} else {
				$rubytext->show($page, 
					$flx + $PDFJ::Default{RRuby} * $fontsize / 1000,
					$fly);
			}
		}
		if( $style->{withnote} ) {
			my $notetext = $style->{withnote};
			if( !ref($notetext) && $style->{withnotestyle} ) {
				$notetext = PDFJ::Text->new($notetext, $style->{withnotestyle});
			}
			my $notesize = $notetext->size;
			if( $direction eq 'H' ) {
				$notetext->show($page, $frx - $notesize, 
					$fry + $PDFJ::Default{HNote} * $fontsize / 1000);
			} else {
				$notetext->show($page, 
					$frx + $PDFJ::Default{VNote} * $fontsize / 1000,
					$fry + $notesize);
			}
		}
		if( $style->{filltext} ) {
			my $utext = PDFJ::Text->new($style->{filltext}, 
				{font => $style->{font}, fontsize => $style->{fontsize}});
			my $usize = $utext->size;
			my $fillspace = $direction eq 'V' ? $lastfry - $fly : 
				$lastfrx - $flx;
			$fillspace = -$fillspace if $fillspace < 0;
			my($x, $y) = ($lastfrx, $lastfry);
			my $count = int($fillspace / $usize);
			for( my $j = 0; $j < $count; $j++ ) {
				$utext->show($page, $x, $y);
				if( $direction eq 'H' ) {
					$x += $usize;
				} else {
					$y -= $usize;
				}
			}
		}
		if( ref($style->{pageattr}) eq 'HASH' ) {
			for my $key(keys %{$style->{pageattr}}) {
				$page->setattr($key, $style->{pageattr}{$key});
			}
		}
		($lastfrx, $lastfry) = ($frx, $fry);
		$lastfontsize = $fontsize;
		if( $direction eq 'H' ) {
			$x += _chunkfontsizeH($fontobj, $fontsize, $chunk) - 
				$shift * $fontsize / 1000;
		} else {
			$y -= _chunkfontsizeV($fontobj, $fontsize, $chunk) + 
				$shift * $fontsize / 1000;
		}
	}
	push @tj, $lasttextspec->endpdf if @tj;
	$page->addcontents(@shapepdf);
	$page->addcontents(@tj);
	$page->addcontents(@dotpdf);
	$page->usefonts(keys %usefontname);
}

sub altobjlineskip {
	my($self, $start, $count) = @_;
	my $chunksnum = $self->chunksnum;
	my $preaols = 0;
	my $postaols = 0;
	for( my $j = 0; $j < $count && $start + $j < $chunksnum; $j++ ) {
		my $chunk = $self->chunk($start + $j);
		my $style = $chunk->{Style};
		my $direction = $style->{font}->{direction};
		my $fontsize = $style->{fontsize};
		if( $chunk->{AltObj} ) {
			my $altobj = $chunk->{AltObj};
			my $objalign = $style->{objalign} || "";
			if( $direction eq 'H' ) {
				my $altsize = $altobj->size('V');
				if( $altsize > $fontsize ) {
					my $diff = $altsize - $fontsize;
					if( $objalign =~ /t/ ) {
						$postaols = $diff if $diff > $postaols;
					} elsif( $objalign =~ /m/ ) {
						$preaols = $diff / 2 if $diff / 2 > $preaols;
						$postaols = $diff / 2 if $diff / 2 > $postaols;
					} else { # /b/
						$preaols = $diff if $diff > $preaols;
					}
				}
			} else {
				my $altsize = $altobj->size('H');
				if( $altsize > $fontsize ) {
					my $diff = $altsize - $fontsize;
					if( $objalign =~ /l/ ) {
						$preaols = $diff if $diff > $preaols;
					} elsif( $objalign =~ /r/ ) {
						$preaols = $diff / 2 if $diff / 2 > $preaols;
						$postaols = $diff / 2 if $diff / 2 > $postaols;
					} else { # /c/
						$postaols = $diff if $diff > $postaols;
					}
				}
			}
		}
	}
	($preaols, $postaols);
}

sub stringstring {
	my($chunk, $fontobj, $usefname) = @_;
	my $str = $chunk->{String};
	if( $chunk->{Mode} eq 'a' &&
		$PDFJ::Default{Encodings}{$fontobj->{encoding}} eq 'ju' && 
		$usefname eq $fontobj->{zname} ) {
		$str =~ s/./\x00$&/g;
	}
	my $result;
	if( $str =~ /[^\x20-\x7e]/ ) {
		my $ss = unpack('H*', $str);
		$result = "<$ss>";
	} else {
		my $ss = $str;
		$ss =~ s/\\/\\\\/g;
		$ss =~ s/\(/\\\(/g;
		$ss =~ s/\)/\\\)/g;
		$result = "($ss)";
	}
	$result;
}

sub _withlinepdf {
	my($direction, $x, $y, $w, $fontsize, $style) = @_;
	my $shape = PDFJ::Shape->new;
	if( $direction eq 'H' ) {
		$shape->textuline($x, $y, $w, $fontsize, $style);
	} else {
		$shape->textrline($x, $y, $w, $fontsize, $style);
	}
	$shape->pdf;
}

sub _withboxpdf {
	my($page, $direction, $x, $y, $w, $fontsize, $spec, $style) = @_;
	my $shape = PDFJ::Shape->new;
	$shape->textbox($direction, $x, $y, $w, $fontsize, $spec, 
		$style);
	$shape->show_link($page);
	$shape->pdf;
}

# string splitting

# character classes are
# 0: begin paren
# 1: end paren
# 2: not at top of line
# 3: ?!
# 4: dot
# 5: punc
# 6: leader
# 7: pre unit
# 8: post unit
# 9: zenkaku space
# 10: hirakana
# 11: japanese
# 12: suffixed
# 13: rubied
# 14: number
# 15: unit
# 16: space
# 17: ascii
# 18: special

# modes are
# 'z': zenkaku Japanese
# 'h': hankaku Japanese
# 'a': ascii
# 'S': ShowableObj
# 'N': Newline
# 'O': Outline
# 'D': Destination
# 'U': Null

sub _specialchunk {
	my($style, $mode, $class, $splittable) = @_;
	PDFJ::TextChunk->new($style, $mode, $class, $splittable,
		0, 0, 0, 0, 0, "", 0, 0);
}

sub _newlinechunk {
	my($textstyle) = @_;
	_specialchunk($textstyle, 'N', 18, 2);
}

sub _outlinechunk {
	my($outlineobj, $textstyle) = @_;
	my $style = $textstyle->linkedclone(%$outlineobj);
	_specialchunk($style, 'O', 18, 1);
}

sub _destchunk {
	my($destobj, $textstyle) = @_;
	my $style = $textstyle->linkedclone(%$destobj);
	_specialchunk($style, 'D', 18, 1);
}

sub _nullchunk {
	my($nullobj, $textstyle) = @_;
	my $style = $textstyle->linkedclone(%$nullobj);
	_specialchunk($style, 'U', 18, 1);
}

sub _objchunk {
	my($obj, $textstyle, $class) = @_;
	$class ||= 18;
	my $chunk = _specialchunk(
		($obj->can('textstyle') ? $textstyle->linkedclone($obj->textstyle) : 
		$textstyle), 'S', $class, 1);
	$chunk->{AltObj} = $obj;
	if( $obj->can('glue') ) {
		@$chunk{qw(Glue GlueDec GlueInc GluePref)} = $obj->glue;
	}
	$chunk;
}

sub _rubychunk {
	my($obj, $textstyle, $rubyoverlap) = @_;
	my $chunk = _objchunk($obj, $textstyle, 13);
	$chunk->{RubyOverlap} = $rubyoverlap;
	$chunk;
}

sub catchunks {
	my($self, $src) = @_;
	my $noglue = $self->style->{noglue} || 0;
	my $fontsize = $self->style->{fontsize};
	my $dest = $self->chunks;
	if( @$dest && @$src ) {
		my($splittable, $glue, $gluedec, $glueinc, $gluepref);
		my $lastclass = _lastclass($dest);
		my $lastmode = _lastmode($dest);
		my $fchunk = $src->[0];
		my $class = $fchunk->{Class};
		my $mode = $fchunk->{Mode};
		my $style = $fchunk->{Style};
		if( $class != 18 ) { # NOT special
			$splittable = $fchunk->{Splittable} == 2 ? 2 : 
				$style->{suffix} ? 0 : 
				$PDFJ::Default{Splittable}->[$lastclass][$class];
			$fchunk->{Splittable} = $splittable;
			$glue = $noglue ? 
				PDFJ::GlueNon :
				$PDFJ::Default{Glue}->[$lastclass][$class];
			($glue, $gluedec, $glueinc, $gluepref) = _calcglue($glue);
			$fchunk->{Glue} = $glue;
			$fchunk->{GlueDec} = $gluedec;
			$fchunk->{GlueInc} = $glueinc;
			$fchunk->{GluePref} = $gluepref;
		}
		unless( $PDFJ::Default{NoRubyOverlap} ) {
			if( $lastclass == 13 && $PDFJ::Default{RubyPostOverlap}{$class} ) {
				my $lastchunk = _lastchunk($dest);
				my $overlap = $lastchunk->{RubyOverlap};
				$lastchunk->{PostShift} += $overlap / $fontsize;
			} elsif( $class == 13 && 
				$PDFJ::Default{RubyPreOverlap}{$lastclass} ) {
				my $overlap = $fchunk->{RubyOverlap};
				$fchunk->{PreShift} += $overlap / $fontsize;
			}
		}
	}
	push @$dest, @$src;
}

sub _appendchunks {
	my($chunks, $style, $mode, $class, $char, $preshift, $postshift) = @_;
	$preshift ||= 0;
	$postshift ||= 0;
	my($splittable, $glue, $gluedec, $glueinc, $gluepref) = (0) x 5;
	my $font = $style->selectfont;
	if( $font && exists $font->{subset_unicodes} ) {
		my $unicode = $PDFJ::Default{Jcode} eq 'SJIS' ? 
			PDFJ::Unicode::s2u($char) : 
			$PDFJ::Default{Jcode} eq 'EUC' ? 
			PDFJ::Unicode::e2u($char) :
			unpack("n", $char); # UNICODE or UTF8 (UTF8 already converted to UNICODE)
		$font->{subset_unicodes}{$unicode} = 1 if $unicode;
	}
	if( @$chunks ) {
		my $lastchunk = $chunks->[$#$chunks];
		my $lastmode = $lastchunk->{Mode};
		my $lastclass = $lastchunk->{Class};
		my $lastruby = $lastchunk->{Style}{ruby};
		$splittable = $style->{suffix} ? 0 : 
			# $lastmode eq 'O' ? 0 :
			$PDFJ::Default{Splittable}->[$lastclass][$class];
		#$glue = ($style->{noglue} || $lastmode =~ /^[ON]$/ || $mode =~ /^[ON]$/) ? 
		$glue = $style->{noglue} ? 
			PDFJ::GlueNon :
			$PDFJ::Default{Glue}->[$lastclass][$class];
		if( (
			$mode eq 'a' && 
			$lastmode eq 'a' && 
			$class == $lastclass && 
			($class == 11 || (!@$glue && !$splittable))
			) 
			#||
			#(
			#$style->{ruby} && $style->{ruby} eq $lastruby && 
			#($class == 11 || $class == 17) && $class == $lastclass
			#)
			 ) {
			$lastchunk->{Count}++;
			$lastchunk->{String} .= $char;
			return;
		}
		($glue, $gluedec, $glueinc, $gluepref) = _calcglue($glue);
	}
	push @$chunks, PDFJ::TextChunk->new($style, $mode, $class, $splittable, 
		$glue, $gluedec, $glueinc, $gluepref, 1, $char, 
		$preshift, $postshift);
}

sub _calcglue {
	my($glue) = @_;
	my($gluedec, $glueinc, $gluepref) = (0, 0, 0);
	if( ref($glue) && @$glue ) {
		my($gmin, $gnormal, $gmax, $gpref) = @$glue;
		($glue, $gluedec, $glueinc) = (
			$gnormal / 1000, 
			($gnormal - $gmin) / 1000, 
			($gmax - $gnormal) / 1000
		);
		$gluepref = $gpref || 0;
	} else {
		($glue, $gluedec, $glueinc, $gluepref) = (0, 0, 0, 0);
	}
	($glue, $gluedec, $glueinc, $gluepref);
}

sub _lastchunk {
	my($chunks) = @_;
	@$chunks ? $chunks->[$#$chunks] : undef;
}

sub _lastclass {
	my($chunks) = @_;
	@$chunks ? $chunks->[$#$chunks]{Class} : '';
}

sub _lastclasseq {
	my($chunks, $eqclass) = @_;
	@$chunks && $chunks->[$#$chunks]{Class} == $eqclass;
}

sub _lastmode {
	my($chunks) = @_;
	@$chunks ? $chunks->[$#$chunks]{Mode} : '';
}

sub splittext {
	my($self, $str, $noshift) = @_;
	return [] if $str eq '';
	if(  PDFJ::Util::objisa($self->style->{font}, "PDFJ::AFont") ) {
		&splittext_ASCII;
	} elsif( $self->style->{code} ) {
		no strict 'refs';
		my $func = "splittext_" . $self->style->{code};
		&$func;
	} elsif( $PDFJ::Default{Jcode} eq 'SJIS' ) {
		&splittext_SJIS;
	} elsif( $PDFJ::Default{Jcode} eq 'EUC' ) {
		&splittext_EUC;
	} elsif( $PDFJ::Default{Jcode} eq 'UTF8' ) {
		&splittext_UTF8;
	} elsif( $PDFJ::Default{Jcode} eq 'UNICODE' ) {
		&splittext_UNICODE;
	} else {
	}
}

sub splittext_ASCII {
	my($self, $str, $noshift) = @_;
	my $style = $self->style;
	my $result = [];
	my @c = split('', $str);
	for( my $j = 0; $j <= $#c; $j++ ) {
		my $c = $c[$j];
		next if $c eq "\x00";
		if( $c eq " " ) {
			_appendchunks($result, $style, 'a', 16, $c);
		} else {
			if( $style->{vh} ) {
				_appendchunks($result, $style, 'a', 11, $c);
			} elsif( $c =~ /[0-9]/ ) {
				_appendchunks($result, $style, 'a', 14, $c);
			} elsif( $c =~ /[,. ]/ && _lastclasseq($result, 14) &&
				$c[$j+1] =~ /[0-9]/ ) {
				_appendchunks($result, $style, 'a', 14, $c);
			} else {
				_appendchunks($result, $style, 'a', 17, $c);
			}
		}
	}
	$result;
}

sub splittext_UTF8 {
	my($self, $str, $noshift) = @_;
	require PDFJ::Unicode;
	$self->splittext_UNICODE(PDFJ::Unicode::utf8tounicode($str));
}

sub splittext_UNICODE {
	my($self, $str, $noshift) = @_;
	$str =~ s/^\xfe\xff//;
	my $style = $self->style;
	my $result = [];
	my @c = split('', $str);
	for( my $j = 0; $j <= $#c; $j += 2 ) {
		my $c = $c[$j].$c[$j+1];
		my $ca = $c[$j+1];
		if( $c ge "\xff\x61" && $c le "\xff\x9f" ) {
			_appendchunks($result, $style, 'h', 11, $c);
		} elsif( $c eq "\x00\x20" ) {
			_appendchunks($result, $style, 'a', 16, $ca);
		} elsif( $c le "\x00\xff" ) {
			if( $style->{vh} ) {
				_appendchunks($result, $style, 'a', 11, $ca);
			} elsif( $c ge "\x00\x30" && $c le "\x00\x39" ) { # /[0-9]/
				_appendchunks($result, $style, 'a', 14, $ca);
			} elsif( ($c eq "\x00\x2c" || $c eq "\x00\x2e") && # /[,.]/
				_lastclasseq($result, 14) &&
				$c[$j+2].$c[$j+3] ge "\x00\x30" && 
				$c[$j+2].$c[$j+3] le "\x00\x39" ) {
				_appendchunks($result, $style, 'a', 14, $ca);
			} else {
				_appendchunks($result, $style, 'a', 17, $ca);
			}
		} else {
			my $class = $PDFJ::Default{Class}{UNICODE}{$c};
			unless( defined $class ) {
				if( $c ge "\x30\x41" && $c le "\x30\x93" ) { # hirakana
					$class = 10;
				} else {
					$class = 11;
				}
			}
			my $preshift = $noshift ? 0 : 
				($PDFJ::Default{PreShift}{UNICODE}{$c} || 0) / 1000;
			my $postshift = $noshift ? 0 : 
				($PDFJ::Default{PostShift}{UNICODE}{$c} || 0) / 1000;
			_appendchunks($result, $style, 'z', $class, $c, $preshift, $postshift);
		}
	}
	$result;
}

sub splittext_EUC {
	my($self, $str, $noshift) = @_;
	my $style = $self->style;
	my $result = [];
	my @c = split('', $str);
	for( my $j = 0; $j <= $#c; $j++ ) {
		my $c = $c[$j];
		if( $c eq "\x8e" ) {
			_appendchunks($result, $style, 'h', 11, $c.$c[$j+1]);
			$j++;
		} elsif( $c eq "\x8f" ) {
			my $tmp = $c.$c[$j+1].$c[$j+2];
			my $utmp = PDFJ::Unicode::e2u($tmp);
			if( $utmp > 0 && $utmp <= 0xff ) {
				_appendchunks($result, $style, 'a', 17, chr($utmp));
			} else {
				_appendchunks($result, $style, 'z', 11, $tmp);
			}
			$j += 2;
		} elsif( $c eq " " ) {
			_appendchunks($result, $style, 'a', 16, $c);
		} elsif( $c lt "\xa0" ) {
			if( $style->{vh} ) {
				_appendchunks($result, $style, 'a', 11, $c);
			} elsif( $c =~ /[0-9]/ ) {
				_appendchunks($result, $style, 'a', 14, $c);
			} elsif( $c =~ /[,. ]/ && _lastclasseq($result, 14) && 
				$c[$j+1] =~ /[0-9]/ ) {
				_appendchunks($result, $style, 'a', 14, $c);
			} else {
				_appendchunks($result, $style, 'a', 17, $c);
			}
		} else {
			my $k = $c.$c[$j+1];
			$j++;
			my $class = $PDFJ::Default{Class}{EUC}{$k};
			unless( defined $class ) {
				if( $k ge "\xa4\xa1" && $k le "\xa4\xf3" ) {
					$class = 10;
				} else {
					$class = 11;
				}
			}
			my $preshift = $noshift ? 0 : 
				($PDFJ::Default{PreShift}{EUC}{$k} || 0) / 1000;
			my $postshift = $noshift ? 0 : 
				($PDFJ::Default{PostShift}{EUC}{$k} || 0) / 1000;
			_appendchunks($result, $style, 'z', $class, $k, $preshift, $postshift);
		}
	}
	$result;
}

sub splittext_SJIS {
	my($self, $str, $noshift) = @_;
	my $style = $self->style;
	my $result = [];
	my @c = split('', $str);
	for( my $j = 0; $j <= $#c; $j++ ) {
		my $c = $c[$j];
		if( $c ge "\x81" && $c le "\x9f" || $c ge "\xe0" && $c le "\xfc" ) {
			my $k = $c.$c[$j+1];
			$j++;
			my $class = $PDFJ::Default{Class}{SJIS}{$k};
			unless( defined $class ) {
				if( $k ge "\x82\x9f" && $k le "\x82\xf1" ) {
					$class = 10;
				} else {
					$class = 11;
				}
			}
			my $preshift = $noshift ? 0 : 
				($PDFJ::Default{PreShift}{SJIS}{$k} || 0) / 1000;
			my $postshift = $noshift ? 0 : 
				($PDFJ::Default{PostShift}{SJIS}{$k} || 0) / 1000;
			_appendchunks($result, $style, 'z', $class, $k, $preshift, $postshift);
		} elsif( $c eq " " ) {
			_appendchunks($result, $style, 'a', 16, $c);
		} elsif( $c ge "\xa1" && $c le "\xdf" ) {
			_appendchunks($result, $style, 'h', 11, $c);
		} else {
			if( $style->{vh} ) {
				_appendchunks($result, $style, 'a', 11, $c);
			} elsif( $c =~ /[0-9]/ ) {
				_appendchunks($result, $style, 'a', 14, $c);
			} elsif( $c =~ /[,. ]/ && _lastclasseq($result, 14) &&
				defined $c[$j+1] && $c[$j+1] =~ /[0-9]/ ) {
				_appendchunks($result, $style, 'a', 14, $c);
			} else {
				_appendchunks($result, $style, 'a', 17, $c);
			}
		}
	}
	$result;
}

#--------------------------------------------------------------------------
package PDFJ::TextChunk;
use strict;

# chunk array index
my %ChunkIndex = (
	Style       =>  0,	# PDFJ::TextStyle object
	Mode        =>  1,	# description as above
	Class       =>  2,	# description as above
	Splittable  =>  3,	# 1 for splittable at pre-postion
	Glue        =>  4,	# normal glue width
	GlueDec     =>  5,	# decrease adjustable glue width
	GlueInc     =>  6,	# increase adjustable glue width
	GluePref    =>  7,	# glue preference
	Count       =>  8,	# characters count
	String      =>  9,	# characters string
	PreShift    => 10,	# postion shift at pre-postion
	PostShift   => 11,	# postion shift at post-postion
	GlueFix     => 12,	# fixed glue (to be calculated)
	Hyphened    => 13,	# 1 for splitted, 2 for hyphened
	RubyText    => 14,	# ruby PDFJ::Text object
	AltObj      => 15,	# alternative object for String 
	RubyOverlap => 16,	# ruby overlap size
);

sub new {
	my($class, @args) = @_;
        my %hash  = map {  $_ => $args[ $ChunkIndex{ $_ } ] } keys(%ChunkIndex) ;

	bless \%hash, $class;
}

sub clone {
	my($self) = @_;
	my @clone = @$self;
	bless \@clone, ref($self);
}

sub print {
	my($self) = @_;
	print "TextChunk\n";
	for my $key(sort {$ChunkIndex{$a} <=> $ChunkIndex{$b}} keys %ChunkIndex) {
		print "  $key => $self->{$key}\n";
	}
}

#--------------------------------------------------------------------------
package PDFJ::ParagraphStyle;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Style);

sub PStyle { PDFJ::ParagraphStyle->new(@_) }

#--------------------------------------------------------------------------
package PDFJ::Paragraph;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Showable);

sub Paragraph { PDFJ::Paragraph->new(@_) }

sub new {
	my($class, $text, $style)
		= PDFJ::Util::methodargs([qw(text style)], @_);
	croak "paragraph text argument must be a PDFJ::Text object"
		unless PDFJ::Util::objisa($text, 'PDFJ::Text');
	$style = PDFJ::ParagraphStyle->new($style) 
		if $style && (!ref($style) || ref($style) eq 'HASH');
	croak "paragraph style argument must be a PDFJ::ParagraphStyle object"
		unless PDFJ::Util::objisa($style, 'PDFJ::ParagraphStyle');
	croak "size specification missing" unless $style->{size};
	croak "linefeed specification missing" unless exists $style->{linefeed};
	croak "align specification missing" unless $style->{align};
	my $self = bless { text => $text, style => $style }, $class;
	$self->typename($style->{typename}) if $style->{typename} ne '';
	$self->{linefeed} = $style->{linefeed};
	if( $self->{linefeed} =~ s/s(\d+%?)// ) {
		$self->{lineskipmin} = $1;
		if( $self->{lineskipmin} =~ /(\d+)%/ ) { 
			$self->{lineskipmin} = $text->fontsize * $1 / 100;
		}
	}
	if( defined $style->{objinbounds} ) {
		$self->{objinbounds} = $style->{objinbounds};
	} elsif( defined $self->{lineskipmin} ) {
		$self->{objinbounds} = 1;
	}
	if( $self->{linefeed} =~ /(\d+)%/ ) { 
		$self->{linefeed} = $text->fontsize * $1 / 100;
	}
	my $lineskip = $self->{linefeed} - $text->fontsize;
	$lineskip = 0 if $lineskip < 0;
	$self->{lineskip} = $lineskip;
	$self->{preskip} = exists $style->{preskip} ? 
		$style->{preskip} : $lineskip * $PDFJ::Default{ParaPreSkipRatio};
	if( ref($self->{preskip}) eq 'HASH' ) {
		for my $key(keys %{$self->{preskip}}) {
			if( $self->{preskip}{$key} =~ /(\d+)%/ ) {
				$self->{preskip}{$key} = $text->fontsize * $1 / 100;
			}
		}
	} elsif( $self->{preskip} =~ /(\d+)%/ ) {
		$self->{preskip} = $text->fontsize * $1 / 100;
	}
	$self->{postskip} = exists $style->{postskip} ? 
		$style->{postskip} : $lineskip * $PDFJ::Default{ParaPostSkipRatio};
	if( ref($self->{postskip}) eq 'HASH' ) {
		for my $key(keys %{$self->{postskip}}) {
			if( $self->{postskip}{$key} =~ /(\d+)%/ ) {
				$self->{postskip}{$key} = $text->fontsize * $1 / 100;
			}
		}
	} elsif( $self->{postskip} =~ /(\d+)%/ ) {
		$self->{postskip} = $text->fontsize * $1 / 100;
	}
	my $labeltext = $style->{labeltext};
	my $firstminindent = 0;
	if( $labeltext ) {
		if( PDFJ::Util::objisa($labeltext, 'PDFJ::Showable') ) {
			$self->{labelobj} = $labeltext;
		} elsif( ref($labeltext) eq 'CODE' ) {
			$self->{labelobj} = &$labeltext();
		} elsif( ref($labeltext) eq 'ARRAY' && 
			ref($labeltext->[0]) eq 'CODE' ) {
			my($func, @args) = @$labeltext;
			$self->{labelobj} = &$func(@args);
		} elsif( ref($labeltext) ) {
			croak "unknown labeltext type";
		} else {
			$self->{labelobj} = $labeltext;
		}
		$self->{labelobj} = PDFJ::Text->new($self->{labelobj}, $text->style)
			unless ref($self->{labelobj});
		my $labelobjsize = $self->{labelobj}->size($self->text->direction);
		$firstminindent = $labelobjsize + $self->labelskip - $self->labelsize;
		$firstminindent = 0 if $firstminindent < 0;
	}
	$self->{beginindent} = 
		exists $style->{beginindent} ?
			ref($style->{beginindent}) eq 'ARRAY' ?
				[@{$style->{beginindent}}] :
				[$style->{beginindent}] :
			[0];
	if( $self->{beginindent}[0] < $firstminindent ) {
		$self->{beginindent}[1] = $self->{beginindent}[0]
			if @{$self->{beginindent}} == 1;
		$self->{beginindent}[0] = $firstminindent;
	}
	$self->{endindent} = 
		exists $style->{endindent} ?
			ref($style->{endindent}) eq 'ARRAY' ?
				[@{$style->{endindent}}] :
				[$style->{endindent}] :
			[0];
	$self->{align} = 
		exists $style->{align} ?
			ref($style->{align}) eq 'ARRAY' ?
				[@{$style->{align}}] :
				[$style->{align}] :
			[0];
	my @lines = $text->_fold($self);
	$self->{lines} = \@lines;
	$self;
}

sub text { $_[0]->{text} }
sub linesnum { scalar(@{$_[0]->{lines}}) }
sub line { 
	my($self, $line) = @_;
	while( $line >= $self->linesnum ) {
		$line -= $self->linesnum;
	}
	while( $line < 0 ) {
		$line += $self->linesnum;
	}
	$self->{lines}->[$line];
}
sub fixedsize {
	my($self, $line) = @_;
	my(undef, $start, $count, $shift, $fixedglues) = @{$self->line($line)};
	($self->text->fixsize($start, $count, $fixedglues), $shift);
}
sub labelsize { $_[0]->{style}->{labelsize} || 0 }
sub labelskip { $_[0]->{style}->{labelskip} || 0 }
sub beginpadding { $_[0]->{style}->{beginpadding} || 0 }
sub _getsetarray { 
	my($self, $name, $idx, $value) = @_;
	my $count = @{$self->{$name}};
	if( defined $value ) {
		if( $idx > $count ) {
			my $lastvalue = $self->{$name}[$count - 1];
			for( my $j = $count; $j < $idx; $j++ ) {
				$self->{$name}[$j] = $lastvalue;
			}
		}
		my @values = ref($value) eq 'ARRAY' ? @$value : ($value);
		for( my $j = 0; $j < @values; $j++ ) {
			$self->{$name}[$idx + $j] = $values[$j];
		}
	} else {
		if( $idx < $count ) {
			$self->{$name}[$idx];
		} else {
			$self->{$name}[$count - 1];
		}
	}
}
sub beginindent { 
	my $self = shift;
	$self->_getsetarray('beginindent', @_);
}
sub endindent { 
	my $self = shift;
	$self->_getsetarray('endindent', @_);
}
sub align { 
	my $self = shift;
	$self->_getsetarray('align', @_);
}
sub _size { $_[0]->{style}{size} }
sub linesize {
	my($self, $idx) = @_;
	$self->_size - $self->beginpadding - $self->labelsize - 
			$self->beginindent($idx) - $self->endindent($idx);
}

sub linefeed { $_[0]->{linefeed} }
sub preskip { $_[0]->{preskip} || 0 }
sub postskip { $_[0]->{postskip} || 0 }
sub nobreak { $_[0]->{style}->{nobreak} }
sub postnobreak { $_[0]->{style}->{postnobreak} }
sub float { $_[0]->{style}->{float} || "" }
sub breakable {
	my($self, $blockdirection) = @_;
	return 0 if $self->nobreak;
	my $direction = $self->text->direction;
	if( $direction eq 'H' ) {
		$blockdirection eq 'V' ? 1 : 0;
	} else {
		$blockdirection eq 'V' ? 0 : 1;
	}
}

sub _linessize {
	my($self) = @_;
	if( $self->linesnum ) {
		if( defined $self->{lineskipmin} ) {
			my $size = $self->text->fontsize * $self->linesnum;
			if( $self->linesnum > 1 ) {
				for my $line(@{$self->{lines}}[1..($self->linesnum - 1)]) {
					$size += $line->{PreSkip};
				}
			}
			if( $self->{objinbounds} ) {
				$size += $self->{lines}[0]{PreAOLS};
				$size += $self->{lines}[$#{$self->{lines}}]{PostAOLS};
			}
			$size;
		} else {
			$self->text->fontsize + ($self->linesnum - 1) * $self->linefeed;
		}
	} else {
		0;
	}
}

sub break {
	my($self, $sizes)
		= PDFJ::Util::listargs2ref(1, 0, 
			PDFJ::Util::methodargs([qw(sizes)], @_));
	my @sizes = @$sizes;
	my $unbreakable = $self->nobreak;
	my $lastsize = $sizes[$#sizes];
	my @result;
	my @lines = @{$self->{lines}};
	my @beginindents = @{$self->{beginindent}};
	my @endindents = @{$self->{endindent}};
	my $fontsize = $self->text->fontsize;
	my $second;
	while( @lines ) {
		my $size = @sizes ? shift(@sizes) : $lastsize;
		my $firstsize = $fontsize;
		if( $self->{objinbounds} ) {
			$firstsize += $lines[0]{PreAOLS};
		}
		my $count;
		if( $unbreakable ) {
			$count = $size < $self->_linessize ? 0 : scalar(@lines);
		} elsif( $size < $firstsize ) {
			$count = 0;
		} elsif( defined $self->{lineskipmin} ) {
			$count = 1;
			my $tmpsize = $firstsize;
			while( $count < @lines ) {
				my $linefeed = $fontsize + $lines[$count]{PreSkip};
				my $postaols = $self->{objinbounds} ? 
					$lines[$count]{PostAOLS} : 0;
				if( $tmpsize + $linefeed + $postaols <= $size ) {
					$tmpsize += $linefeed;
					$count++;
				} else {
					last;
				}
			}
		} else { 
			$count = 
				int(($size - $self->text->fontsize) / $self->linefeed) + 1;
		}
		return if !$count && !@sizes;
		my @blines = splice @lines, 0, $count;
		my @bbi = splice @beginindents, 0, $count;
		@beginindents = ($bbi[$#bbi]) unless @beginindents;
		my @bei = splice @endindents, 0, $count;
		@endindents = ($bei[$#bei]) unless @endindents;
		my $bpara = bless {
				typename => $self->{typename},
				text => $self->{text}, 
				style => $self->{style},
				linefeed => $self->{linefeed}, 
				lineskip => $self->{lineskip},
				lineskipmin => $self->{lineskipmin},
				objinbounds => $self->{objinbounds},
				preskip => $self->{preskip},
				postskip => $self->{postskip},
				beginindent => \@bbi, endindent => \@bei,
				labelobj => ($second ? undef : $self->{labelobj}),
				lines => \@blines}, ref($self);
		$second = 1 if @blines;
		push @result, $bpara;
	}
	@result;
}

sub width {
	my($self) = @_;
	$self->text->direction eq 'H' ? 
		$self->_size :
		$self->_linessize;
}

sub height {
	my($self) = @_;
	$self->text->direction eq 'H' ? 
		$self->_linessize :
		$self->_size;
}

sub left {
	my($self) = @_;
	$self->text->direction eq 'H' ? 
		0 :
		- ($self->_linessize - $self->text->fontsize / 2);
}

sub right {
	my($self) = @_;
	$self->text->direction eq 'H' ? 
		$self->_size :
		$self->text->fontsize / 2;
}

sub top {
	my($self) = @_;
	$self->text->direction eq 'H' ? 
		$self->text->fontsize * $PDFJ::Default{HBaseHeight} :
		0;
}

sub bottom {
	my($self) = @_;
	$self->text->direction eq 'H' ? 
		- ($self->_linessize - 
		$self->text->fontsize * $PDFJ::Default{HBaseHeight}) :
		$self->_size;
}

sub size { 
	my($self, $direction) = @_; 
	if( $direction eq 'H' ) {
		$self->width;
	} elsif( $direction eq 'V' ) {
		$self->height;
	} else {
		$self->_size;
	}
}

sub blockalign {  
	my($self) = @_;
	$self->{style}{blockalign};
}

sub onshow { $_[0]->{style}{onshow} }

sub _show {
	my($self, $page, $x, $y) = @_;
	if( $self->{objinbounds} ) {
		my $preaols = $self->line(0)->{PreAOLS};
		if( $self->text->style->{font}{direction} eq 'H' ) {
			$y -= $preaols;
		} else {
			$x -= $preaols;
		}
	}
	for( my $j = 0; $j < $self->linesnum; $j++ ) {
		($x, $y) = $self->_showline($page, $x, $y, $j);
	}
}

sub _showline {
	my($self, $page, $x, $y, $line) = @_;
	return unless $line < $self->linesnum;
	my $style = $self->{style};
	my $start = $self->line($line)->{Start};
	my $count = $self->line($line)->{Count};
	my $fixedglues = $self->line($line)->{FixedGlues};
	my $shift = $self->line($line)->{Shift} + $self->beginpadding + 
		$self->labelsize + $self->beginindent($line);
	my $text = $self->text;
	my $tstyle = $text->style;
	croak "no font specification" unless exists $tstyle->{font};
	my $direction = $tstyle->{font}{direction};
	if( $line == 0 && $self->{labelobj} ) {
		my($lx, $ly) = $direction eq 'H' ? ($x + $self->beginpadding, $y) :
			($x, $y - $self->beginpadding);
		$self->{labelobj}->show($page, $lx, $ly);
	}
	my($nextx, $nexty, $linefeed);
	if( defined $self->{lineskipmin} && $line < $self->linesnum - 1 ) {
		$linefeed = $text->fontsize + $self->line($line + 1)->{PreSkip};
	} else {
		$linefeed = $self->linefeed;
	}
	if( $direction eq 'H' ) {
		($nextx, $nexty) = ($x, $y - $linefeed);
		$x += $shift;
	} else {
		($nextx, $nexty) = ($x - $linefeed, $y);
		$y -= $shift;
	}
	$text->_showpart($page, $x, $y, $start, $count, $fixedglues);
	($nextx, $nexty);
}

#--------------------------------------------------------------------------
package PDFJ::NewBlock;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::BlockElement);

sub NewBlock { PDFJ::NewBlock->new(@_) }

sub new {
	my($class) = @_;
	bless \$class, $class;
}

sub typename { 'newblock' }

#--------------------------------------------------------------------------
package PDFJ::BlockStyle;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Style);

sub BStyle { PDFJ::BlockStyle->new(@_) }

#--------------------------------------------------------------------------
package PDFJ::Block;
use Carp;
use strict;
use vars qw(@ISA %Dispatch %Require);
@ISA = qw(PDFJ::Showable);

%Dispatch = (
	H => 'PDFJ::Block::Vector',
	R => 'PDFJ::Block::Vector',
	V => 'PDFJ::Block::Vector',
	HV => 'PDFJ::Block::Matrix',
	RV => 'PDFJ::Block::Matrix',
	VH => 'PDFJ::Block::Matrix',
	VR => 'PDFJ::Block::Matrix',
	TV => 'PDFJ::Block::Tree',
	TU => 'PDFJ::Block::Tree',
	TH => 'PDFJ::Block::Tree',
	TR => 'PDFJ::Block::Tree',
);

%Require = (
	HV => 'PDFJ::Matrix',
	RV => 'PDFJ::Matrix',
	VH => 'PDFJ::Matrix',
	VR => 'PDFJ::Matrix',
	TV => 'PDFJ::Tree',
	TU => 'PDFJ::Tree',
	TH => 'PDFJ::Tree',
	TR => 'PDFJ::Tree',
);

sub Block { PDFJ::Block->new(@_); }

sub new {
	my($class, $direction, $objects, $style)
		= PDFJ::Util::listargs2ref(2, 1, 
			PDFJ::Util::methodargs([qw(direction objects style)], @_));
	my $dclass = $Dispatch{$direction}
		or croak "unknown Block direction: $direction";
	if( $Require{$direction} ) {
		eval "require $Require{$direction}";
	}
	$style = PDFJ::BlockStyle->new($style) 
		if $style && (!ref($style) || ref($style) eq 'HASH');
	croak "block style argument must be a PDFJ::BlockStyle object"
		unless PDFJ::Util::objisa($style, 'PDFJ::BlockStyle');
	my @objects = @$objects;
	my $self = bless { direction => $direction, objects => \@objects, 
		xpreshift => 0, xpostshift => 0, ypreshift => 0, ypostshift => 0, 
		style => $style }, $dclass;
	$self->typename($style->{typename}) if $style->{typename} ne '';
	$self->_checkobjects;
	$self->_calcsize;
	$self->adjustwidth($style->{width}) if $style->{width};
	$self->adjustheight($style->{height}) if $style->{height};
	$self;
}

sub _checkobjects {
	my($self) = @_;
	my $objects = $self->{objects};
	for( my $j = 0; $j < @$objects; $j++ ) {
		unless( PDFJ::Util::objisa($objects->[$j], 'PDFJ::BlockElement') ) {
			croak "illegal Block element: $objects->[$j]"
		}
	}
}

sub empty {
	my($self) = @_;
	!@{$self->{objects}};
}

sub padding { $_[0]->{style}{padding} || 0 }

sub width { 
	my($self) = @_;
	$self->{width} + $self->padding * 2 
		+ $self->{xpreshift} + $self->{xpostshift};
}
sub height {
	my($self) = @_;
	$self->{height} + $self->padding * 2 
		+ $self->{ypreshift} + $self->{ypostshift};
}

sub size {
	my($self, $direction) = @_; 
	if( $direction eq 'H' ) {
		$self->width;
	} else {
		$self->height;
	}
}
sub blockalign {  
	my($self) = @_;
	$self->{style}{blockalign};
}
sub left { 0 }
sub right { $_[0]->width }
sub top { 0 }
sub bottom { - $_[0]->height }
sub preskip { 
	my $self = shift;
	$self->{style}{preskip} || 0;
}
sub postskip { 
	my $self = shift;
	$self->{style}{postskip} || 0;
}

sub align { $_[0]->{style}{align} || "" }
sub nobreak { $_[0]->{style}{nobreak} }
sub postnobreak { $_[0]->{style}{postnobreak} }
sub repeatheader { $_[0]->{style}{repeatheader} || 0 }
sub float { $_[0]->{style}->{float} || "" }
sub nofirstfloat { $_[0]->{style}{nofirstfloat} }
#sub beginpadding { $_[0]->{style}{beginpadding} || 0 }
sub bfloatsep { 
	my $tmp = $_[0]->{style}{bfloatsep};
	if( defined $tmp ) {
		$tmp = [$tmp] if ref($tmp) ne 'ARRAY';
		for( my $j = ''; $j < @$tmp; $j++ ) {
			$tmp->[$j]{floatsep} = "b$j" if $tmp->[$j];
		}
	}
	$tmp;
}
sub efloatsep { 
	my $tmp = $_[0]->{style}{efloatsep}; 
	if( defined $tmp ) {
		$tmp = [$tmp] if ref($tmp) ne 'ARRAY';
		for( my $j = ''; $j < @$tmp; $j++ ) {
			$tmp->[$j]{floatsep} = "e$j" if $tmp->[$j];
		}
	}
	$tmp;
}
sub direction { $_[0]->{direction} }
sub breakable {
	my($self, $blockdirection) = @_;
	$self->nobreak ? 0 :
		$blockdirection eq $self->{direction} ? 1 :
		0;
}

sub adjustwidth {
	my($self, $size)
		= PDFJ::Util::methodargs([qw(size)], @_);
	return unless $size;
	my $align = $self->align;
	return $self if $self->width >= $size;
	$size -= $self->width;
	if( $align =~ /r/ ) {
		$self->{xpreshift} = $size;
	} elsif( $align =~ /c/ ) {
		$self->{xpreshift} = $size / 2;
		$self->{xpostshift} = $size / 2;
	} else { # l
		$self->{xpostshift} = $size;
	}
	$self;
}

sub adjustheight {
	my($self, $size)
		= PDFJ::Util::methodargs([qw(size)], @_);
	return unless $size;
	my $align = $self->align;
	return $self if $self->height >= $size;
	$size -= $self->height;
	if( $align =~ /b/ ) {
		$self->{ypreshift} = $size;
	} elsif( $align =~ /m/ ) {
		$self->{ypreshift} = $size / 2;
		$self->{ypostshift} = $size / 2;
	} else { # t
		$self->{ypostshift} = $size;
	}
	$self;
}

sub colspan { $_[0]->{style}{colspan} || 1 }
sub rowspan { $_[0]->{style}{rowspan} || 1 }

sub onshow { $_[0]->{style}{onshow} }

sub _showbox {
	my($self, $page, $x, $y) = @_;
	my $style = $self->{style};
	if( $style->{withbox} ) {
		my $withbox = $style->{withbox};
		my $withboxstyle = $style->{withboxstyle};
		my $shape = PDFJ::Shape->new;
		my($boxwidth, $boxheight) = ($self->width, $self->height);
		$shape->box(0, 0, $boxwidth, - $boxheight, $withbox, 
			$withboxstyle);
		$shape->show($page, $x, $y);
	}
}

#--------------------------------------------------------------------------
package PDFJ::Block::Vector;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Block);

sub _checkobjects {
	my($self) = @_;
	my $objects = $self->{objects};
	for( my $j = 0; $j < @$objects; $j++ ) {
		if( PDFJ::Util::objisa($objects->[$j], 'PDFJ::BlockElement') ) {
			# OK
		} elsif( $objects->[$j] =~ /^\d+$/ ) {
			$objects->[$j] = PDFJ::BlockSkip::BlockSkip($objects->[$j]);
		} else {
			croak "illegal Block element: $objects->[$j]"
		}
	}
}

# NOT method
sub skipsize {
	my($aobj, $bobj) = @_;
	my $apostskip = $aobj->postskip;
	my $postskip = ref($apostskip) eq 'HASH' ?
		$apostskip->{$bobj->typename || 'default'} : $apostskip;
	my $bpreskip = $bobj->preskip;
	my $preskip = ref($bpreskip) eq 'HASH' ?
		$bpreskip->{$aobj->typename || 'default'} : $bpreskip;
	$postskip + $preskip;
}

sub preskip { 
	my $self = shift;
	my $preskip = $self->{style}{preskip} || 0;
	$preskip = $self->{objects}[0]->preskip if $preskip eq 'c';
	$preskip;
}
sub postskip { 
	my $self = shift;
	my $postskip = $self->{style}{postskip} || 0;
	$postskip = $self->{objects}[$#{$self->{objects}}]->postskip 
		if $postskip eq 'c';
	$postskip;
}

sub break {
	my($self, $sizes)
		= PDFJ::Util::listargs2ref(1, 0, 
			PDFJ::Util::methodargs([qw(sizes)], @_));
	my @sizes = @$sizes;
	my $unbreakable = $self->nobreak;
	my $nofirstfloat = $self->nofirstfloat;
	my $repeatheader = $self->repeatheader;
	my $lastsize = $sizes[$#sizes];
	my $direction = $self->{direction} eq 'V' ? 'V' : 'H';
	my @result;
	my @objects = @{$self->{objects}};
	my $bfloatsep = $self->bfloatsep;
	my $efloatsep = $self->efloatsep;
	if( $bfloatsep && $efloatsep ) {
		my $match = 0;
		for my $obj(@$bfloatsep) {
			if( grep {$_ eq $obj} @$efloatsep ) {
				$match = 1;
				last;
			}
		}
		carp "bfloatsep and efloatsep must be different" if $match;
	}
	my @repeatheader = $repeatheader ? 
			@objects[0..($repeatheader - 1)] : ();
	my @reserve;
	while( @objects || @reserve ) {
		my $size = @sizes ? shift(@sizes) : $lastsize;
		unshift @objects, splice(@reserve);
		my @bobjects;
		if( $unbreakable ) {
			@bobjects = splice @objects if $size >= $self->size($direction);
		} else {
			my $bsize = $self->padding * 2;
			while( $bsize < $size && @objects ) {
				my $obj = $objects[0];
				my $issep = 0;
				my $float = $obj->float;
				if( $float && @reserve ) {
					push @reserve, shift(@objects);
					next;
				}
				if( $float =~ /b/ && $nofirstfloat && !@result ) {
					push @reserve, shift(@objects);
					next;
				}
				my($inspos, $seppos, $needsep) = _inspos(\@bobjects, $float);
				my $sepobj;
				if( $needsep ) {
					my($level) = $float =~ /(\d+)/;
					$sepobj = $bfloatsep->[$level] 
						if $bfloatsep && $float =~ /b/ && $level < @$bfloatsep;
					$sepobj = $efloatsep->[$level]
						if $efloatsep && $float =~ /e/ && $level < @$efloatsep;
				}
				if( $sepobj ) {
					unshift @objects, $sepobj;
					$obj = $sepobj;
					$inspos = $seppos;
					$issep = 1;
				}
				my $skipsize = 0;
				if( $inspos == 0 ) {
					$skipsize = skipsize($obj, $bobjects[$inspos])
						if @bobjects;
				} elsif( $inspos == @bobjects ) {
					$skipsize = skipsize($bobjects[$inspos - 1], $obj);
				} else {
					$skipsize = skipsize($bobjects[$inspos - 1], $obj) +
						skipsize($obj, $bobjects[$inspos]) - 
						skipsize($bobjects[$inspos - 1], $bobjects[$inspos]);
				}
				my $osize = $obj->size($direction);
				if( PDFJ::Util::objisa($obj, 'PDFJ::NewBlock') ) {
					shift(@objects);
					last if @bobjects;
				} elsif( $bsize + $skipsize + $osize <= $size ) {
					splice @bobjects, $inspos, 0, shift(@objects);
					$bsize += $skipsize + $osize;
				} elsif( $obj->breakable($self->{direction}) ) {
					my @bsizes = ($size - $bsize - $skipsize, 
						map {$_ - $self->padding * 2} 
						(@sizes ? (@sizes) : ($lastsize)));
					my @parts = $obj->break(@bsizes);
					if( @parts ) {
						$obj = $parts[0];
						my $osize = $obj->size($direction);
						my $empty = $obj->can('empty') && $obj->empty;
						if( $osize && !$empty ) {
							$bsize += $skipsize + $osize;
							shift @objects;
							unshift @objects, @parts;
							splice @bobjects, $inspos, 0, shift(@objects);
						} else {
							shift @parts;
							shift @objects;
							unshift @objects, @parts;
						}
						last;
					} else {
						carp "$obj->break(@bsizes) fails";
						return;
					}
				} else {
					if( $float && !$issep ) {
						push @reserve, shift(@objects);
					} else {
						last;
					}
				}
			}
		}
		while( @bobjects && $bobjects[$#bobjects] && 
			$bobjects[$#bobjects]->postnobreak && @objects ) {
			unshift @objects, pop(@bobjects);
		}
		if( !@bobjects && !@sizes ) {
			carp "break fails";
			return;
		}
		if( @bobjects && $bobjects[0]->{floatsep} eq 'b' ) {
			shift @bobjects;
		}
		if( @bobjects && $bobjects[$#bobjects]->{floatsep} eq 'e' ) {
			pop @bobjects;
		}
		if( $repeatheader && (@bobjects >= $repeatheader) && @objects ) {
			unshift @objects, @repeatheader;
		}
		my $bobj;
		%$bobj = %$self;
		$bobj->{objects} = \@bobjects;
		delete $bobj->{indents};
		bless $bobj, ref($self);
		$bobj->_calcsize;
		push @result, $bobj;
	}
	@result;
}

sub _inspos { # NOT method
	my($objects, $float) = @_;
	my($inspos, $seppos, $needsep);
	if( $float =~ /b/ ) {
		$inspos = 0;
		while( $inspos < @$objects && ($objects->[$inspos]->float ge $float ||
			$objects->[$inspos]->{floatsep} gt $float)) {
			$inspos++;
		}
		unless( $inspos < @$objects && 
			$objects->[$inspos]->{floatsep} eq $float ) {
			$seppos = $inspos;
			$needsep = 1;
		}
	} elsif( $float =~ /e/ ) {
		$inspos = @$objects;
		while( $inspos > 0 && ($objects->[$inspos - 1]->float ge $float ||
			$objects->[$inspos - 1]->{floatsep} gt $float)) {
			$inspos--;
		}
		unless( $inspos > 0 && $objects->[$inspos - 1]->{floatsep} eq $float ) {
			$seppos = $inspos;
			$needsep = 1;
		}
		$inspos = @$objects;
		while( $inspos > 0 && ($objects->[$inspos - 1]->float gt $float ||
			$objects->[$inspos - 1]->{floatsep} gt $float)) {
			$inspos--;
		}
	} elsif( $float eq '' || $float eq 'h' ) {
		$inspos = @$objects;
		while( $inspos > 0 && ($objects->[$inspos - 1]->float =~ /e/ ||
			$objects->[$inspos - 1]->{floatsep} =~ /e/)) {
			$inspos--;
		}
	} else {
		carp "unknown float spec '$float'";
	}
	($inspos, $seppos, $needsep);
}

sub _calcsize {
	my($self) = @_;
	my($width, $height) = (0, 0);
	my $objnum = @{$self->{objects}};
	my $adjust = $self->{style}{adjust};
	my $align = $self->align;
	if( $self->{direction} eq 'V' ) {
		for( my $j = 0; $j < $objnum; $j++ ) {
			my $obj = $self->{objects}->[$j];
			if( $j > 0 ) {
				$height += skipsize($self->{objects}->[$j-1], $obj);
			}
			if( PDFJ::Util::objisa($obj, 'PDFJ::Showable') ) {
				my $owidth = $obj->width + $obj->blockalign;
				$width = $width < $owidth ? $owidth : $width;
				$height += $obj->height;
			} elsif( PDFJ::Util::objisa($obj, 'PDFJ::BlockElement') ) {
				$height += $obj->size($self->{direction});
			} else {
				croak "illegal block element";
			}
		}
		if( $adjust ) {
			for my $obj(@{$self->{objects}}) {
				$obj->adjustwidth($width) if $obj->can('adjustwidth');
			}
		}
		my @indents;
		my $indentratio = ($align =~ /c/) ? 0.5 : ($align =~ /r/) ? 1 : 0;
		for( my $j = 0; $j < $objnum; $j++ ) {
			my $obj = $self->{objects}->[$j];
			if( PDFJ::Util::objisa($obj, 'PDFJ::Showable') ) {
				my $aib = $obj->blockalign;
				if( $aib eq '' ) {
					$indents[$j] = ($width - $obj->width) * $indentratio;
				} elsif( $aib eq 'b' ) {
					$indents[$j] = 0;
				} elsif( $aib eq 'm' ) {
					$indents[$j] = ($width - $obj->width) / 2;
				} elsif( $aib eq 'e' ) {
					$indents[$j] = $width - $obj->width;
				} elsif( $aib =~ /\d/ ) {
					$indents[$j] = $aib + 0;
				}
			}
		}
		$self->{indents} = \@indents;
	} else {
		for( my $j = 0; $j < $objnum; $j++ ) {
			my $obj = $self->{objects}->[$j];
			if( $j > 0 ) {
				$width += skipsize($self->{objects}->[$j-1], $obj);
			}
			if( PDFJ::Util::objisa($obj, 'PDFJ::Showable') ) {
				my $oheight = $obj->height + $obj->blockalign;
				$height = $height < $oheight ? $oheight : $height;
				$width += $obj->width;
			} elsif( PDFJ::Util::objisa($obj, 'PDFJ::BlockElement') ) {
				$width += $obj->size($self->{direction});
			} else {
				croak "illegal block element";
			}
		}
		if( $adjust ) {
			for my $obj(@{$self->{objects}}) {
				$obj->adjustheight($height) if $obj->can('adjustheight');
			}
		}
		my @indents;
		my $indentratio = ($align =~ /m/) ? 0.5 : ($align =~ /b/) ? 1 : 0;
		for( my $j = 0; $j < $objnum; $j++ ) {
			my $obj = $self->{objects}->[$j];
			if( PDFJ::Util::objisa($obj, 'PDFJ::Showable') ) {
				my $aib = $obj->blockalign;
				if( $aib eq '' ) {
					$indents[$j] = ($height - $obj->height) * $indentratio;
				} elsif( $aib eq 'b' ) {
					$indents[$j] = 0;
				} elsif( $aib eq 'm' ) {
					$indents[$j] = ($height - $obj->height) / 2;
				} elsif( $aib eq 'e' ) {
					$indents[$j] = $height - $obj->height;
				} elsif( $aib =~ /\d/ ) {
					$indents[$j] = $aib + 0;
				}
			}
		}
		$self->{indents} = \@indents;
	}
	$self->{width} = $width;
	$self->{height} = $height;
}

sub _show {
	my($self, $page, $x, $y) = @_;
	$self->_showbox($page, $x, $y);
	$x += $self->padding + $self->{xpreshift};
	$y -= $self->padding + $self->{ypreshift};
	my $objnum = @{$self->{objects}};
	if( $self->{direction} eq 'V' ) {
		for( my $j = 0; $j < $objnum; $j++ ) {
			my $obj = $self->{objects}->[$j];
			my $indent = $self->{indents}->[$j] || 0;
			if( $j > 0 ) {
				$y -= skipsize($self->{objects}->[$j-1], $obj);
			}
			if( PDFJ::Util::objisa($obj, 'PDFJ::Showable') ) {
				$obj->show($page, $x + $indent, $y, 'tl');
				$y -= $obj->height;
			} elsif( PDFJ::Util::objisa($obj, 'PDFJ::BlockElement') ) {
				$y -= $obj->size($self->{direction});
			} elsif( $obj =~ /^\d+$/ ) {
				$y -= $obj;
			} else {
				croak "illegal block element";
			}
		}
	} elsif( $self->{direction} eq 'H' ) {
		for( my $j = 0; $j < $objnum; $j++ ) {
			my $obj = $self->{objects}->[$j];
			my $indent = $self->{indents}->[$j] || 0;
			if( $j > 0 ) {
				$x += skipsize($self->{objects}->[$j-1], $obj);
			}
			if( PDFJ::Util::objisa($obj, 'PDFJ::Showable') ) {
				$obj->show($page, $x, $y - $indent, 'tl');
				$x += $obj->width;
			} elsif( PDFJ::Util::objisa($obj, 'PDFJ::BlockElement') ) {
				$x += $obj->size($self->{direction});
			} else {
				croak "illegal block element";
			}
		}
	} elsif( $self->{direction} eq 'R' ) {
		$x += $self->{width};
		for( my $j = 0; $j < $objnum; $j++ ) {
			my $obj = $self->{objects}->[$j];
			my $indent = $self->{indents}->[$j] || 0;
			if( $j > 0 ) {
				$x -= skipsize($self->{objects}->[$j-1], $obj);
			}
			if( PDFJ::Util::objisa($obj, 'PDFJ::Showable') ) {
				$obj->show($page, $x, $y - $indent, 'tr');
				$x -= $obj->width;
			} elsif( PDFJ::Util::objisa($obj, 'PDFJ::BlockElement') ) {
				$x -= $obj->size($self->{direction});
			} else {
				croak "illegal block element";
			}
		}
	}
}

#--------------------------------------------------------------------------
package PDFJ::Image;
use PDFJ::Object;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Showable);

sub new {
	my($class, $docobj, $src, $pxwidth, $pxheight, $width, $height, $padding,
		$colorspace, $type) = @_;
	my($ext) = $src =~ /([^\.]+)$/;
	$type ||= $ext;
	if( $src =~ /^http:/i ) {
		croak "unknown image file type: $type" 
			unless $type =~ /^jpe?g$/i;
		new_url_jpeg($class, $docobj, $src, $pxwidth, $pxheight, $width, 
			$height, $padding, $colorspace);
	} else {
		if( $type =~ /^jpe?g$/i ) {
			new_file_jpeg($class, $docobj, $src, $pxwidth, $pxheight, $width, 
				$height, $padding, $colorspace);
		} elsif( $type =~ /^png$/i ) {
			new_file_png($class, $docobj, $src, 0, 0, $width, 
				$height, $padding);
		} else {
			croak "unknown image file type: $type";
		}
	}
}

sub new_url_jpeg {
	my($class, $docobj, $url, $pxwidth, $pxheight, $width, $height, $padding,
		$colorspace) = @_;
	$width ||= $pxwidth;
	$height ||= $pxheight;
	$colorspace ||= 'DeviceRGB';
	$colorspace = $colorspace =~ /^rgb$/i ? 'DeviceRGB' :
		$colorspace =~ /^gray$/i ? 'DeviceGray' :
		$colorspace =~ /^cmyk$/i ? 'DeviceCMYK' :
		'DeviceRGB';
	my $num = $docobj->_nextimagenum;
	my $name = "I$num";
	my $image = $docobj->indirect(stream(dictionary => {
		Name     => name($name),
		Type     => name("XObject"),
		Subtype  => name("Image"),
		Width    => number($pxwidth),
		Height   => number($pxheight),
		BitsPerComponent => 8,
		ColorSpace => name($colorspace),
		FFilter  => name("DCTDecode"),
		F        => {
			FS => name("URL"),
			F  => string($url),
		},
		Length   => 0,
		# No Data
	}, stream => ''));
	$docobj->_registimage($name, $image);
	bless { name => $name, image => $image, width => $width,
		height => $height, padding => $padding }, $class;
}

sub new_file_jpeg {
	my($class, $docobj, $file, $pxwidth, $pxheight, $width, $height, $padding,
		$colorspace) = @_;
	$width ||= $pxwidth;
	$height ||= $pxheight;
	$colorspace ||= 'DeviceRGB';
	$colorspace = $colorspace =~ /^rgb$/i ? 'DeviceRGB' :
		$colorspace =~ /^gray$/i ? 'DeviceGray' :
		$colorspace =~ /^cmyk$/i ? 'DeviceCMYK' :
		'DeviceRGB';
	my $num = $docobj->_nextimagenum;
	my $name = "I$num";
	my($encoded, $filter) = $docobj->_makestream($file, "DCTDecode");
	my $image = $docobj->indirect(stream(dictionary => {
		Name     => name($name),
		Type     => name("XObject"),
		Subtype  => name("Image"),
		Width    => number($pxwidth),
		Height   => number($pxheight),
		BitsPerComponent => 8,
		ColorSpace => name($colorspace),
		Filter  => $filter,
		Length   => length($encoded),
	}, stream => $encoded));
	$docobj->_registimage($name, $image);
	bless { name => $name, image => $image, width => $width,
		height => $height, padding => $padding }, $class;
}

sub new_file_png {
	my($class, $docobj, $file, $pxwidth, $pxheight, $width, $height, $padding) 
		= @_;
	require PDFJ::PNG;
	my($name, $image) = PDFJ::PNG::imagestream($docobj, $file);
	$docobj->_registimage($name, $image);
	bless { name => $name, image => $image, width => $width,
		height => $height, padding => $padding }, $class;
}

sub image { $_[0]->{image} }
sub width { $_[0]->{width} + $_[0]->padding * 2 }
sub height { $_[0]->{height} + $_[0]->padding * 2 }
sub padding { $_[0]->{padding} || 0 }
sub left { 0 }
sub right { $_[0]->width }
sub top { $_[0]->height }
sub bottom { 0 }

sub size {
	my($self, $direction) = @_; 
	$direction eq 'H' ? $self->width : $self->height;
}

sub setsize {
	my($self, $width, $height) = @_;
	$self->{width} = $width;
	$self->{height} = $height;
	$self;
}

sub setpadding {
	my($self, $padding) = @_;
	$self->{padding} = $padding;
}

sub onshow {}

sub _show {
	my($self, $page, $x, $y) = @_;
	$x += $self->padding;
	$y += $self->padding;
	my $width = $self->{width};
	my $height = $self->{height};
	my $name = $self->{name};
	$page->addcontents("q", numbers($width, 0, 0, $height, $x, $y), 
		"cm /$name Do Q");
	$page->useimage($self);
}

#--------------------------------------------------------------------------
package PDFJ::Color;
use PDFJ::Object;
use Carp;
use strict;

sub Color { PDFJ::Color->new(@_) }

sub new {
	my $class = shift;
	if( @_ == 1 ) {
		new1($class, @_);
	} elsif( @_ == 3 ) {
		new3($class, @_);
	} else {
		croak "Color arguments must be one or three";
	}
}

sub new1 {
	my($class, $value)
		= PDFJ::Util::methodargs([qw(value)], @_);
	#my $class = shift;
	my $self;
	if( ref($value) eq 'ARRAY' ) {
		$self = bless { type => 'rgb', value => $value }, $class;
	} elsif( $value =~ /^#([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})$/ ) {
		my(@rgb) = map {oct("0x$_")/256} ($1,$2,$3);
		$self = bless { type => 'rgb', value => \@rgb }, $class;
	} else {
		$self = bless { type => 'gray', value => $value }, $class;
	}
	$self;
}

sub new3 {
	my($class, @rgb) = @_;
	bless { type => 'rgb', value => \@rgb }, $class;
}

sub fill {
	my($self) = @_;
	if( $self->{type} eq 'gray' ) {
		(number($self->{value}), "g");
	} else { # 'rgb'
		(numbers(@{$self->{value}}), "rg");
	}
}

sub stroke {
	my($self) = @_;
	if( $self->{type} eq 'gray' ) {
		(number($self->{value}), "G");
	} else { # 'rgb'
		(numbers(@{$self->{value}}), "RG");
	}
}

sub numarray {
	my($self) = @_;
	if( $self->{type} eq 'gray' ) {
		($self->{value});
	} else { # 'rgb'
		@{$self->{value}};
	}
}

#--------------------------------------------------------------------------
package PDFJ::ShapeStyle;
use Carp;
use strict;
use PDFJ::Object;
use vars qw(@ISA);
@ISA = qw(PDFJ::Style);

sub SStyle { PDFJ::ShapeStyle->new(@_) }

sub pdf {
	my($self) = @_;
	my @result;
	push @result, $self->{fillcolor}->fill if $self->{fillcolor};
	push @result, $self->{strokecolor}->stroke if $self->{strokecolor};
	push @result, number($self->{linewidth}), "w" if $self->{linewidth};
	if( $self->{linedash} ) {
		my($dash, $gap, $phase) = ref($self->{linedash}) eq 'ARRAY' ? 
			@{$self->{linedash}} : split(/\s*,\s*/, $self->{linedash});
		$phase ||= 0;
		push @result, array([numbers($dash, $gap)]), number($phase), "d";
	}
	@result;
}

#--------------------------------------------------------------------------
package PDFJ::Shape;
use PDFJ::Object;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Showable);

sub Shape { PDFJ::Shape->new(@_) }

sub new {
	my($class, $style)
		= PDFJ::Util::methodargs([qw(style)], @_);
	my $self = bless 
		{ left => 0, top => 0, right => 0, bottom => 0, pdf => [] }, $class;
	$self->style($style) if $style;
	$self;
}

sub padding { $_[0]->{style}{padding} || 0 }
sub left { $_[0]->{left} - $_[0]->padding }
sub right { $_[0]->{right} + $_[0]->padding }
sub top { $_[0]->{top} + $_[0]->padding }
sub bottom { $_[0]->{bottom} - $_[0]->padding }
sub width { $_[0]->{right} - $_[0]->{left} + $_[0]->padding * 2 }
sub height { $_[0]->{top} - $_[0]->{bottom} + $_[0]->padding * 2 }
sub preskip { $_[0]->{style}{preskip} || 0 }
sub postskip { $_[0]->{style}{postskip} || 0 }
sub postnobreak { $_[0]->{style}{postnobreak} }
sub float { $_[0]->{style}->{float} || "" }
sub pdf { @{$_[0]->{pdf}} }

sub size {
	my($self, $direction) = @_; 
	$direction eq 'H' ? $self->width : $self->height;
}

sub blockalign {  
	my($self) = @_;
	$self->{style}{blockalign};
}

sub setboundary {
	my($self, $x, $y)
		= PDFJ::Util::methodargs([qw(x y)], @_);
	if( $x < $self->{left} ) {
		$self->{left} = $x;
	} elsif( $x > $self->{right} ) {
		$self->{right} = $x;
	}
	if( $y < $self->{bottom} ) {
		$self->{bottom} = $y;
	} elsif( $y > $self->{top} ) {
		$self->{top} = $y;
	}
	$self;
}

sub appendpdf {
	my($self, @pdf) = @_;
	push @{$self->{pdf}}, @pdf;
	$self;
}

sub appendobj {
	my($self, $obj, @args) = @_;
	push @{$self->{objects}}, [$obj, @args];
	$self;
}

sub add_link {
	my($self, $rect, $name) = @_;
	$self->{link}{join(',', @$rect)} = $name;
}

sub show_link {
	my($self, $page, $x, $y) = @_;
	$x ||= 0;
	$y ||= 0;
	for my $rect(keys %{$self->{link}}) {
		my $name = $self->{link}{$rect};
		my @rect = split(',', $rect);
		$rect[0] += $x;
		$rect[1] += $y;
		$rect[2] += $x;
		$rect[3] += $y;
		$page->add_link(\@rect, $name);
	}
}

sub onshow { $_[0]->{style}{onshow} }

sub _show {
	my($self, $page, $x, $y) = @_;
	$x += $self->padding;
	$y += $self->padding;
	my @stylepdf;
	if( $self->{style} ) {
		@stylepdf = $self->{style}->pdf if UNIVERSAL::can($self->{style}, 'pdf');
	}
	$page->addcontents("q", numbers(1, 0, 0, 1, $x, $y), 
		"cm", @stylepdf, $self->pdf);
	if( $self->{objects} ) {
		for my $objspec(@{$self->{objects}}) {
			my($obj, @args) = @$objspec;
			$obj->show($page, @args);
		}
	}
	$page->addcontents("Q");
	$self->show_link($page, $x, $y);
}

sub style {
	my($self, $style) = @_;
	$style = PDFJ::ShapeStyle->new($style)
		if $style && (!ref($style) || ref($style) eq 'HASH');
	croak "shape style argument must be a PDFJ::ShapeStyle object"
		unless PDFJ::Util::objisa($style, 'PDFJ::ShapeStyle');
	$self->typename($style->{typename}) if $style->{typename} ne '';
	$self->{style} = $style;
	$self;
}

# General Graphic State operators

sub gstatepush {
	my($self) = @_;
	$self->appendpdf("q");
}

sub gstatepop {
	my($self) = @_;
	$self->appendpdf("Q");
}

sub linewidth {
	my($self, $w) = @_;
	$self->appendpdf(number($w), "w");
}

sub linedash {
	my($self, $dash, $gap, $phase) = @_;
	$phase ||= 0;
	$self->appendpdf(array([numbers($dash, $gap)]), number($phase), "d");
}

sub ctm {
	my($self, @array) = @_;
	croak "ctm array must have 6 elements" unless @array == 6;
	$self->appendpdf(numbers(@array), "cm");
}

# Color operators

sub fillcolor {
	my($self, $color) = @_;
	croak "color argument must be a PDFJ::Color object"
		unless PDFJ::Util::objisa($color, 'PDFJ::Color');
	$self->appendpdf($color->fill);
}

sub strokecolor {
	my($self, $color) = @_;
	croak "color argument must be a PDFJ::Color object"
		unless PDFJ::Util::objisa($color, 'PDFJ::Color');
	$self->appendpdf($color->stroke);
}

sub fillgray {
	my($self, $g) = @_;
	$self->appendpdf(number($g), "g");
}

sub strokegray {
	my($self, $g) = @_;
	$self->appendpdf(number($g), "G");
}

sub fillrgb {
	my($self, $r, $g, $b) = @_;
	$self->appendpdf(numbers($r, $g, $b), "rg");
}

sub strokergb {
	my($self, $r, $g, $b) = @_;
	$self->appendpdf(numbers($r, $g, $b), "RG");
}

# Path segment operators

# moves the current point to (x, y), omitting any connecting line segment
sub moveto {
	my($self, $x, $y) = @_;
	$self->setboundary($x, $y);
	$self->appendpdf(numbers($x, $y), "m");
}

# appends a straight line segment from the current point to (x, y).
# The current point becomes (x, y).
sub lineto {
	my($self, $x, $y) = @_;
	$self->setboundary($x, $y);
	$self->appendpdf(numbers($x, $y), "l");
}

# appends a Bezier curve to the path. The curve extends
# from the current point to (x3 ,y3) using (x1 ,y1) and (x2 ,y2)
# as the Bezier control points. 
# The current point becomes (x3 ,y3).
sub curveto {
	my($self, $x1, $y1, $x2, $y2, $x3, $y3) = @_;
	$self->setboundary($x1, $y1);
	$self->setboundary($x2, $y2);
	$self->setboundary($x3, $y3);
	$self->appendpdf(numbers($x1, $y1, $x2, $y2, $x3, $y3), "c");
}

# omit 'v' and 'y'

# adds a rectangle to the current path
sub rectangle {
	my($self, $x, $y, $w, $h) = @_;
	$self->setboundary($x, $y);
	$self->setboundary($x + $w, $y + $h);
	$self->appendpdf(numbers($x, $y, $w, $h), "re");
}

# closes the current subpath by appending a straight line segment
# from the current point to the starting point of the subpath.
sub closepath {
	my $self = shift;
	$self->appendpdf("h");
}

# ends the path without filling or stroking it
sub newpath {
	my $self = shift;
	$self->appendpdf("n");
}

# strokes the path
sub stroke {
	my $self = shift;
	$self->appendpdf("S");
}

# closes and strokes the path
sub closestroke {
	my $self = shift;
	$self->appendpdf("s");
}

# fills the path using the non-zero winding number rule
sub fill {
	my $self = shift;
	$self->appendpdf("f");
}

# fill and stroke
sub fillstroke {
	my $self = shift;
	$self->appendpdf("B");
}

# fills the path using the even-odd rule
sub fill2 {
	my $self = shift;
	$self->appendpdf("f*");
}

# Path macro

sub line {
	my($self, $x, $y, $w, $h, $style)
		= PDFJ::Util::methodargs([qw(x y w h style)], @_);
	$style = PDFJ::ShapeStyle->new($style)
		if $style && (!ref($style) || ref($style) eq 'HASH');
	my @stylepdf;
	@stylepdf = $style->pdf if $style;
	my($x1, $y1, $x2, $y2) = ($x, $y, $x + $w, $y + $h);
	$self->setboundary($x1, $y1);
	$self->setboundary($x2, $y2);
	$self->appendpdf("q", @stylepdf) if @stylepdf;
	$self->appendpdf(numbers($x1, $y1), "m", numbers($x2, $y2), "l S");
	$self->appendpdf("Q") if @stylepdf;
	$self;
}

sub textuline {
	my($self, $x, $y, $size, $fontsize, $style) = @_;
	my $yshift = $PDFJ::Default{ULine} * $fontsize / 1000;
	$self->line($x, $y + $yshift, $size, 0, $style);
}

sub textoline {
	my($self, $x, $y, $size, $fontsize, $style) = @_;
	my $yshift = $PDFJ::Default{OLine} * $fontsize / 1000;
	$self->line($x, $y + $yshift, $size, 0, $style);
}

sub textlline {
	my($self, $x, $y, $size, $fontsize, $style) = @_;
	my $xshift = $PDFJ::Default{LLine} * $fontsize / 1000;
	$self->line($x + $xshift, $y, 0, $size, $style);
}

sub textrline {
	my($self, $x, $y, $size, $fontsize, $style) = @_;
	my $xshift = $PDFJ::Default{RLine} * $fontsize / 1000;
	$self->line($x + $xshift, $y, 0, $size, $style);
}

sub box {
	my($self, $x, $y, $w, $h, $spec, $style)
		= PDFJ::Util::methodargs([qw(x y w h spec style)], @_);
	$spec = "s" unless $spec;
	$style = PDFJ::ShapeStyle->new($style)
		if $style && (!ref($style) || ref($style) eq 'HASH');
	my @stylepdf;
	@stylepdf = $style->pdf if $style;
	my($r);
	if( $spec =~ s/r(\d+)// ) {
		$r = $1;
		croak "too big radius for round box"
			if $r * 2 > abs($w) || $r * 2 > abs($h);
	}
	if( $w < 0 ) {
		$x += $w; $w = -$w;
	}
	if( $h < 0 ) {
		$y += $h; $h = -$h;
	}
	$self->setboundary($x, $y);
	$self->setboundary($x + $w, $y + $h);
	if( $spec ne 'n' ) {
		$self->appendpdf("q", @stylepdf) if @stylepdf;
		if( $r ) {
			my $bz = $r * 0.55228475;
			my @work = (
				numbers($x+$w,        $y+$h-$r),      'm',
				numbers($x+$w,        $y+$h-$r+$bz),
				numbers($x+$w-$r+$bz, $y+$h),
				numbers($x+$w-$r,     $y+$h),         'c',
				numbers($x+$r,        $y+$h),         'l',
				numbers($x+$r-$bz,    $y+$h),
				numbers($x,           $y+$h-$r+$bz),
				numbers($x,           $y+$h-$r),      'c',
				numbers($x,           $y+$r),         'l',
				numbers($x,           $y+$r-$bz),
				numbers($x+$r-$bz,    $y),
				numbers($x+$r,        $y),            'c',
				numbers($x+$w-$r,     $y),            'l',
				numbers($x+$w-$r+$bz, $y),
				numbers($x+$w,        $y+$r-$bz),
				numbers($x+$w,        $y+$r),         'c',
				numbers($x+$w,        $y+$h-$r),      'l'
			);
			$self->appendpdf(@work);
		} else {
			$self->appendpdf(numbers($x, $y), "m", numbers($x, $y, $w, $h), "re");
		}
		if( $spec eq 'sf' ) {
			$self->appendpdf("B");
		} elsif( $spec eq 's' ) {
			$self->appendpdf("S");
		} elsif( $spec eq 'f' ) {
			$self->appendpdf("f");
		} elsif( $spec =~ /^([lrtb]+)(f?)$/ ) {
			croak "'lrtb' is inconsistent with 'rX'" if $r;
			my($side, $fill) = ($1, $2);
			if( $fill eq 'f' ) {
				$self->appendpdf("f");
			} else {
				$self->appendpdf("n");
			}
			$self->line($x, $y, 0, $h) if $side =~ /l/;
			$self->line($x + $w, $y, 0, $h) if $side =~ /r/;
			$self->line($x, $y + $h, $w, 0) if $side =~ /t/;
			$self->line($x, $y, $w, 0) if $side =~ /b/;
		} elsif( $spec eq 'n' ) {
			$self->appendpdf("n");
		} else {
			croak "illegal strokefill argument: $spec";
		}
		$self->appendpdf("Q") if @stylepdf;
	}
	if( $style && $style->{link} ) {
		$self->add_link([$x, $y, $x + $w, $y + $h], $style->{link});
	}
	$self;
}

sub textbox {
	my($self, $direction, $x, $y, $size, $fontsize, $spec, 
		$style) = @_;
	my(@bbox) = @{$PDFJ::Default{"SBox$direction"}};
	grep {$_ = $_ * $fontsize / 1000} @bbox;
	if( $direction eq 'H' ) {
		$self->box(
			$x + $bbox[0], 
			$y + $bbox[1], 
			$size + $bbox[2] - $bbox[0] - $fontsize,
			$bbox[3] - $bbox[1], 
			$spec, $style
		);
	} else {
		$self->box(
			$x + $bbox[0], 
			$y, 
			$bbox[2] - $bbox[0] ,
			$size + $bbox[3] - $bbox[1] - $fontsize, 
			$spec, $style
		);
	}
}

sub circle {
	my($self, $x, $y, $r, $spec, $arcarea, $style)
		= PDFJ::Util::methodargs([qw(x y r spec arcarea style)], @_);
	$self->ellipse($x, $y, $r, $r, $spec, $arcarea, $style);
}

sub ellipse {
	my($self, $x, $y, $xr, $yr, $spec, $arcarea, $style)
		= PDFJ::Util::methodargs([qw(x y xr yr spec arcarea style)], @_);
	$spec = "s" unless $spec;
	$style = PDFJ::ShapeStyle->new($style)
		if $style && (!ref($style) || ref($style) eq 'HASH');
	my @stylepdf;
	@stylepdf = $style->pdf if $style;
	$self->appendpdf("q", @stylepdf) if @stylepdf;
	my $xbz = $xr * 0.55228475;
	my $ybz = $yr * 0.55228475;
	my @pt = (
		$x+$xr,  $y,    
		$x+$xr,  $y+$ybz, $x+$xbz, $y+$yr,  $x,     $y+$yr,
		$x-$xbz, $y+$yr,  $x-$xr,  $y+$ybz, $x-$xr, $y,
		$x-$xr,  $y-$ybz, $x-$xbz, $y-$yr,  $x,     $y-$yr,
		$x+$xbz, $y-$yr,  $x+$xr,  $y-$ybz, $x+$xr, $y,
	);
	if( $arcarea ) {
		$arcarea--;
		$arcarea %= 4;
		$self->setboundary(@pt[$arcarea * 6, $arcarea * 6 + 1]);
		$self->setboundary(@pt[$arcarea * 6 + 6, $arcarea * 6 + 7]);
		if( $spec =~ /f/ ) {
			$self->appendpdf(numbers($x, $y), "m");
			$self->appendpdf(numbers(splice(@pt, $arcarea * 6, 2)), "l");
		} else {
			$self->appendpdf(numbers(splice(@pt, $arcarea * 6, 2)), "m");
		}
		$self->appendpdf(numbers(splice(@pt, $arcarea * 6, 6)), "c");
	} else {
		$self->setboundary($x - $xr, $y - $yr);
		$self->setboundary($x + $xr, $y + $yr);
		$self->appendpdf(numbers(splice(@pt, 0, 2)), "m");
		$self->appendpdf(numbers(splice(@pt, 0, 6)), "c");
		$self->appendpdf(numbers(splice(@pt, 0, 6)), "c");
		$self->appendpdf(numbers(splice(@pt, 0, 6)), "c");
		$self->appendpdf(numbers(splice(@pt, 0, 6)), "c");
	}
	if( $spec eq 'sf' ) {
		$self->appendpdf("B");
	} elsif( $spec eq 's' ) {
		$self->appendpdf("S");
	} elsif( $spec eq 'f' ) {
		$self->appendpdf("f");
	}
	$self->appendpdf("Q") if @stylepdf;
	$self;
}

sub polygon {
	my($self, $coords, $spec, $style)
		= PDFJ::Util::methodargs([qw(coords spec style)], @_);
	croak "coords argument must be an array ref"
		unless ref($coords) eq 'ARRAY';
	croak "coords argument must have even elements"
		if @$coords % 2;
	my @work;
	for( my $j = 0; $j < @$coords; $j += 2 ) {
		push @work, numbers($coords->[$j], $coords->[$j + 1]);
		push @work, ($j == 0) ? 'm' : 'l';
		$self->setboundary($coords->[$j], $coords->[$j + 1]);
	}
	$style = PDFJ::ShapeStyle->new($style)
		if $style && (!ref($style) || ref($style) eq 'HASH');
	my @stylepdf;
	@stylepdf = $style->pdf if $style;
	$self->appendpdf("q", @stylepdf) if @stylepdf;
	$self->appendpdf(@work);
	if( $spec eq 'sf' ) {
		$self->appendpdf("B");
	} elsif( $spec eq 's' ) {
		$self->appendpdf("S");
	} elsif( $spec eq 'f' ) {
		$self->appendpdf("f");
	}
	$self->appendpdf("Q") if @stylepdf;
	$self;
}

sub arc {
	my($self, $x, $y, $r, $start, $end, $spec, $style)
		= PDFJ::Util::methodargs([qw(x y r start end spec style)], @_);
	croak "same start and end for arc" if $start == $end;
	$spec = "s" unless $spec;
	$style = PDFJ::ShapeStyle->new($style)
		if $style && (!ref($style) || ref($style) eq 'HASH');
	my @stylepdf;
	@stylepdf = $style->pdf if $style;
	$self->appendpdf("q", @stylepdf) if @stylepdf;
	($start, $end) = ($end, $start) if $start > $end;
	my($x0, $y0) = ($x + $r * cos($start), $y + $r * sin($start));
	my $ws = $start;
	my @coords;
	while( $ws < $end ) {
		my $we = $ws + 1 < $end ? $ws + 1 : $end;
		my $a = $we - $ws;
		my $as = atan2(4 - 4 * cos($a / 2), 3 * sin($a / 2));
		my $rs = $r / cos($as);
		my($x1, $y1) = ($x + $rs * cos($ws + $as), $y + $rs * sin($ws + $as));
		my($x2, $y2) = ($x + $rs * cos($we - $as), $y + $rs * sin($we - $as));
		my($x3, $y3) = ($x + $r * cos($we), $y + $r * sin($we));
		push @coords, [$x1, $y1, $x2, $y2, $x3, $y3];
		$ws = $we;
	}
	if( $spec ne 'a' ) {
		$self->moveto($x, $y);
		$self->lineto($x0, $y0);
	} else {
		$self->moveto($x0, $y0);
	}
	for my $coords(@coords) {
		$self->curveto(@$coords);
	}
	if( $spec ne 'a' ) {
		$self->lineto($x, $y);
	}
	if( $spec eq 'f' ) {
		$self->fill;
	} elsif( $spec eq 'a' || $spec eq 's' ) {
		$self->stroke;
	} elsif( $spec eq 'sf' ) {
		$self->fillstroke;
	}
	$self->appendpdf("Q") if @stylepdf;
	$self;
}

sub obj {
	my($self, $obj, $showargs)
		= PDFJ::Util::listargs2ref(2, 0, 
			PDFJ::Util::methodargs([qw(obj showargs)], @_));
	my($x, $y, $align, @trans) = @$showargs;
	my @m = PDFJ::Util::transmatrix($x, $y, @trans);
	if( $align ) {
		if( $align =~ /l/ ) {
			$x -= $obj->left;
		} elsif( $align =~ /r/ ) {
			$x -= $obj->right;
		} elsif( $align =~ /c/ ) {
			$x -= ($obj->left + $obj->right) / 2;
		}
		if( $align =~ /t/ ) {
			$y -= $obj->top;
		} elsif( $align =~ /b/ ) {
			$y -= $obj->bottom;
		} elsif( $align =~ /m/ ) {
			$y -= ($obj->top + $obj->bottom) / 2;
		}
	}
	my @pts = (
		[$x + $obj->left, $y + $obj->top],
		[$x + $obj->right, $y + $obj->bottom],
		);
	if( @m ) {
		@pts = map {[$m[0] * $_->[0] + $m[2] * $_->[1] + $m[4], 
			$m[1] * $_->[0] + $m[3] * $_->[1] + $m[5]]} @pts;
	}
	for(@pts) {
		$self->setboundary($_->[0], $_->[1]);
	}
	$self->appendobj($obj, @$showargs);
	$self;
}

#--------------------------------------------------------------------------
package PDFJ::MiniPage;
use PDFJ::Object;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Showable);

sub new {
	my($class, $docobj, $width, $height, $padding, $opacity) = @_;
	my $num = $docobj->_nextxobjnum;
	my $name = "X$num";
	my $xobject = $docobj->indirect(contents_stream(dictionary => {
		Type => name('XObject'),
		Subtype => name('Form'),
		FormType => 1,
		Name => name($name),
		BBox => [0, 0, $width, $height],
		Matrix => [1, 0, 0, 1, 0, 0],
		Resources => {ProcSet => [name('PDF'), name('Text')], Font => {}},
		}, stream => []));
	if( $opacity ne '' ) {
		$xobject->dictionary->get('Resources')->set(ExtGState => {R0 => 
			{Type => name('ExtGState'), CA => $opacity, ca => $opacity,
			AIS => bool(0)}});
		$xobject->append("/R0 gs ");
	}
	$docobj->_registxobj($name, $xobject);
	my $self = bless {
		name => $name, 
		xobject => $xobject, 
		width => $width,
		height => $height, 
		padding => $padding, 
		docobj => $docobj, 
		layer => 0,
		opacity => $opacity,
		}, $class;
	$self;
}

sub xobject { $_[0]->{xobject} }

sub width { $_[0]->{width} + $_[0]->padding * 2 }
sub height { $_[0]->{height} + $_[0]->padding * 2 }
sub padding { $_[0]->{padding} || 0 }
sub left { 0 }
sub right { $_[0]->width }
sub top { $_[0]->height }
sub bottom { 0 }

sub size {
	my($self, $direction) = @_; 
	$direction eq 'H' ? $self->width : $self->height;
}

sub setpadding {
	my($self, $padding) = @_;
	$self->{padding} = $padding;
}

sub onshow {}

sub _show {
	my($self, $page, $x, $y) = @_;
	$x += $self->padding;
	$y += $self->padding;
	my $width = $self->{width};
	my $height = $self->{height};
	my $name = $self->{name};
	$page->addcontents("q", numbers(1, 0, 0, 1, $x, $y), 
		"cm /$name Do Q");
	$page->usexobject($self);
}

sub docobj {
	my($self) = @_;
	$self->{docobj};
}

sub getlayer {
	my($self) = @_;
	$self->{layer};
}

sub addcontents {
	my($self, @str) = @_;
	#my @tmp = map {($_, " ")} @str;
	my @tmp;
	my $lasttype;
	for my $str(@str) {
		my $type = ref($str) ? '' :
			($str =~ /^\(/ && $str =~ /\)$/) ? 'l' :
			($str =~ /^</ && $str =~ />$/) ? 'h' : '';
		if( $type && $type eq $lasttype ) {
			$tmp[$#tmp] = substr($tmp[$#tmp], 0, length($tmp[$#tmp]) - 1) . 
				substr($str, 1);
		} else {
			push @tmp, " " if @tmp;
			push @tmp, $str;
		}
		$lasttype = $type;
	}
	push @tmp, " " if @tmp;
	$self->xobject->append(\@tmp, $self->getlayer);
}

sub layer {
	my($self, $layer)
		= PDFJ::Util::methodargs([qw(layer)], @_);
	$self->{layer} = $layer;
	$self;
}

sub setattr {}
sub dest {}
sub add_link {}

sub usefonts {
	my($self, @names) = @_;
	my $docobj = $self->docobj;
	$docobj->_usefonts(@names);
	my $resources = $self->xobject->dictionary->get('Resources');
	for my $name(@names) {
		$resources->get('Font')->set($name, $docobj->_font($name));
	}
}

sub useimage {
	my($self, $imageobj) = @_;
	my $resources = $self->xobject->dictionary->get('Resources');
	$resources->get('ProcSet')->add(name('ImageC'));
	$resources->set(XObject => {}) unless $resources->exists('XObject');
	$resources->get('XObject')->set($imageobj->{name}, $imageobj->{image});
}

sub usexobject {
	my($self, $xobj) = @_;
	my $resources = $self->xobject->dictionary->get('Resources');
	$resources->set(XObject => {}) unless $resources->exists('XObject');
	$resources->get('XObject')->set($xobj->{name}, $xobj->{xobject});
}

#--------------------------------------------------------------------------
package PDFJ::Page;
use Carp;
use strict;
use PDFJ::Object;

sub new {
	my($class, $docobj, $pos, $pagewidth, $pageheight, $dur, $trans) = @_;
	my $pagetree = $docobj->{pagetree};
	$pagewidth ||= $docobj->pagewidth;
	$pageheight ||= $docobj->pageheight;
	my $page = $docobj->indirect(dictionary({
		Type => name('Page'),
		Parent => $pagetree,
		Resources => {ProcSet => [name('PDF'), name('Text')], Font => {}},
		MediaBox => [0, 0, $pagewidth, $pageheight],
		Contents => $docobj->indirect(
			contents_stream(dictionary => {}, stream => [])),
		}));
	if( $dur ) {
		$page->set(Dur => $dur);
	}
	if( $trans ) {
		my($d, $s, @opts) = split /\s*,\s*/, $trans;
		my $transobj = dictionary({
			Type => name('Trans'),
			D => $d,
			S => name($s),
		});
		for my $opt(@opts) {
			if( $opt eq 'H' || $opt eq 'V' ) {
				$transobj->set(Dm => name($opt));
			} elsif( $opt eq 'I' || $opt eq 'O' ) {
				$transobj->set(M => name($opt));
			} elsif( $opt =~ /^\d+$/ ) {
				$transobj->set(Di => $opt);
			}
		}
		$page->set(Trans => $transobj);
	}
	my $pagenum;
	$pos = -1 if $pos >= @{$docobj->{pagelist}};
	if( $pos >= 0 ) {
		splice @{$docobj->{pagelist}}, $pos, 0, $page;
		$pagenum = $pos + 1;
		$pagetree->get('Kids')->insert($pos, $page);
	} else {
		push @{$docobj->{pagelist}}, $page;
		$pagenum = @{$docobj->{pagelist}};
		$pagetree->get('Kids')->push($page);
	}
	$pagetree->get('Count')->add(1);
	my $self = bless {
		page => $page, 
		pagenum => $pagenum,
		parent => $pagetree, 
		docobj => $docobj, 
		layer => 0,
	}, $class;
	if( $pos >= 0 ) {
		splice @{$docobj->{pageobjlist}}, $pos, 0, $self;
		for( my $j = $pos + 1; $j < @{$docobj->{pageobjlist}}; $j++ ) {
			$docobj->{pageobjlist}[$j]{pagenum}++;
		}
	} else {
		push @{$docobj->{pageobjlist}}, $self;
	}
	$self;
}

sub show {
	my($self, $obj, @args) = @_;
	$obj->show($self, @args);
}

sub docobj {
	my($self) = @_;
	$self->{docobj};
}

sub page {
	my($self) = @_;
	$self->{page};
}

sub pagenum {
	my($self) = @_;
	$self->{pagenum};
}

sub getlayer {
	my($self) = @_;
	$self->{layer};
}

sub addcontents {
	my($self, @str) = @_;
	#my @tmp = map {($_, " ")} @str;
	my @tmp;
	my $lasttype;
	for my $str(@str) {
		my $type = ref($str) ? '' :
			($str =~ /^\(/ && $str =~ /\)$/) ? 'l' :
			($str =~ /^</ && $str =~ />$/) ? 'h' : '';
		if( $type && $type eq $lasttype ) {
			$tmp[$#tmp] = substr($tmp[$#tmp], 0, length($tmp[$#tmp]) - 1) . 
				substr($str, 1);
		} else {
			push @tmp, " " if @tmp;
			push @tmp, $str;
		}
		$lasttype = $type;
	}
	push @tmp, " " if @tmp;
	$self->page->get('Contents')->append(\@tmp, $self->getlayer);
}

sub layer {
	my($self, $layer)
		= PDFJ::Util::methodargs([qw(layer)], @_);
	$self->{layer} = $layer;
	$self;
}

sub setattr {
	my($self, $name, $value)
		= PDFJ::Util::methodargs([qw(name value)], @_);
	$self->{attr}{$name} = $value;
}

sub getattr {
	my($self, $name)
		= PDFJ::Util::methodargs([qw(name)], @_);
	$self->{attr}{$name};
}

sub usefonts {
	my($self, @names) = @_;
	my $docobj = $self->docobj;
	$docobj->_usefonts(@names);
	my $resources = $self->page->get('Resources');
	for my $name(@names) {
		$resources->get('Font')->set($name, $docobj->_font($name));
	}
}

sub useimage {
	my($self, $imageobj) = @_;
	my $resources = $self->page->get('Resources');
	$resources->get('ProcSet')->add(name('ImageC'));
	$resources->set(XObject => {}) unless $resources->exists('XObject');
	$resources->get('XObject')->set($imageobj->{name}, $imageobj->{image});
}

sub usexobject {
	my($self, $xobj) = @_;
	my $resources = $self->page->get('Resources');
	$resources->set(XObject => {}) unless $resources->exists('XObject');
	$resources->get('XObject')->set($xobj->{name}, $xobj->{xobject});
}

sub dest {
	my($self, $argtype, @args) = @_;
	array([$self->page, name($argtype), map {$_ eq '' ? null : $_} @args]);
}

sub add_link {
	my($self, $rect, $name) = @_;
	$self->{link}{join(',', @$rect)} = $name;
}

sub add_annot {
	my $self = shift;
	my $hash;
	if( @_ == 1 && ref($_[0]) eq 'HASH' ) {
		$hash = $_[0];
	} else {
		%$hash = @_;
	}
	$hash->{Type} = name('Annot');
	my $docobj = $self->docobj;
	unless( $self->page->exists('Annots') ) {
		$self->page->set(Annots => []);
	}
	$self->page->get('Annots')->push($docobj->indirect(dictionary($hash)));
}

sub solve_link {
	my($self) = @_;
	my $docobj = $self->docobj;
	for my $rect(keys %{$self->{link}}) {
		my $name = $self->{link}{$rect};
		my @rect = split(',', $rect);
		if( ref($name) eq 'ARRAY' ) {
			my($page, $x, $y) = @$name;
			my $dest = $page->dest('XYZ', $x, $y, 0);
			$self->add_annot(
				Subtype => name('Link'),
				Rect => [@rect],
				Border => [0,0,0],
				Dest => $dest,
			);
		} elsif( $name =~ /^URI:(.+)/ ) {
			my $uri = $1;
			$self->add_annot(
				Subtype => name('Link'),
				Rect => [@rect],
				Border => [0,0,0],
				A => {
					Type => name('Action'),
					S => name('URI'),
					URI => string(PDFJ::Util::uriencode($uri))
				},
			);
		} elsif( $name =~ /^PAGE:\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/ ) {
			my($pagenum, $x, $y) = ($1, $2, $3);
			my $page = $docobj->get_page($pagenum - 1);
			my $dest = $page->dest('XYZ', $x, $y, 0);
			$self->add_annot(
				Subtype => name('Link'),
				Rect => [@rect],
				Border => [0,0,0],
				Dest => $dest,
			);
		} else {
			my $dest = $docobj->dest($name);
			if( $dest ) {
				if( ref($dest) eq 'ARRAY' ) {
					$dest = $$dest[$#$dest];
				}
				$self->add_annot(
					Subtype => name('Link'),
					Rect => [@rect],
					Border => [0,0,0],
					Dest => $dest,
				);
			} elsif( $docobj->getoption('missdest') eq 'neglect' ) {
				# do nothing
			} elsif( $docobj->getoption('missdest') eq 'carp' ) {
				carp "missing dest '$name'\n";
			} else {
				croak "missing dest '$name'\n";
			}
		}
	}
}

#--------------------------------------------------------------------------
package PDFJ::File;
use strict;
use PDFJ::Object;

sub new {
	my($class, $version, $handle, $objtable, $rootobj, $idobj, $infoobj, 
		$encryptobj, $encryptkey, $filter) = @_;
	binmode $handle unless PDFJ::Util::objisa($handle, 'IO::Scalar');
	bless {
		version => $version,  # PDF version
		handle => $handle,    # file handle
		objtable => $objtable,  # PDFJ::ObjTable object
		rootobj => $rootobj,  # document catalog object for Root entry
		idobj => $idobj,      # file ID array object for ID entry
		infoobj => $infoobj,  # document information object for Info entry
		encryptobj => $encryptobj, # encryption object for Encrypt entry
		encryptkey => $encryptkey,
		filter => $filter,
		objposlist => [], 
		xrefpos => 0,
		tell => 0
	}, $class;
}

sub print {
	my $self = shift;
	$self->print_header;
	$self->print_body;
	$self->print_xref;
	$self->print_trailer;
}

sub print_header {
	my $self = shift;
	my $handle = $self->{handle};
	my $version = $self->{version};
	#print $handle "%PDF-$version\n";
 	my $header = "%PDF-$version\n";
 	$self->{tell} += length($header);
 	print $handle $header;
}

sub print_body {
	my $self = shift;
	my $handle = $self->{handle};
	my $encryptkey = $self->{encryptkey};
	my $filter = $self->{filter};
	my $objtable = $self->{objtable};
	return unless $objtable->lastobjnum;
	for my $objnum(1 .. $objtable->lastobjnum) {
		next if $objtable->get($objnum)->unused;
#		$self->{objposlist}->[$objnum] = $handle->tell;
#		$objtable->get($objnum)->print($handle);
		$self->{objposlist}->[$objnum] = $self->{tell};
		$self->{tell} += $objtable->get($objnum)->
			print($handle, $encryptkey, $filter);
	}
}

sub print_xref {
	my $self = shift;
	my $handle = $self->{handle};
#	$self->{xrefpos} = $handle->tell;
	$self->{xrefpos} =  $self->{tell};
	print $handle "xref\n";
	my $objtable = $self->{objtable};
	my $lastobjnum = $objtable->lastobjnum;
	my $entries = $lastobjnum + 1;
	print $handle "0 $entries\n";
	print $handle "0000000000 65535 f \n";
	if( $lastobjnum ) {
		for my $objnum(1 .. $lastobjnum) {
			printf $handle "%010.10d %05.5d n \n", 
				$self->{objposlist}->[$objnum], 
				$objtable->get($objnum)->{gennum};
		}
	}
	print $handle "\n";
}

sub print_trailer {
	my $self = shift;
	my $handle = $self->{handle};
	my $xrefpos = $self->{xrefpos};
	my $objtable = $self->{objtable};
	my $traildic = dictionary({
		Size => $objtable->lastobjnum + 1, 
		Root => $self->{rootobj}
		});
	$traildic->set(Info => $self->{infoobj}) if $self->{infoobj};
	$traildic->set(Encrypt => $self->{encryptobj}) if $self->{encryptobj};
	$traildic->set(ID => $self->{idobj}) if $self->{idobj};
	print $handle "trailer\n", $traildic->output, 
		"\nstartxref\n$xrefpos\n%%EOF\n";
}

1;
