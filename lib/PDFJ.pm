# PDFJ.pm
# PDF for Japanese
# 2001-2 Sey <nakajima@netstock.co.jp>
package PDFJ;
use PDFJ::Object;
use PDFJ::Unicode;
use PDFJ::E2U;
use Carp;
use strict;
use vars qw($VERSION @EXFUNC %Default);

$VERSION = 0.7;

@EXFUNC = qw(
	PDFJ::TextStyle::TStyle PDFJ::Text::Text 
	PDFJ::NewLine::NewLine PDFJ::Outline::Outline PDFJ::Dest::Dest
	PDFJ::ParagraphStyle::PStyle PDFJ::Paragraph::Paragraph 
	PDFJ::BlockStyle::BStyle PDFJ::Block::Block PDFJ::NewBlock::NewBlock
	PDFJ::Shape::Shape
	PDFJ::ShapeStyle::SStyle PDFJ::Color::Color
);

sub import {
	my($pkg, $code, $prefix) = @_;
	if( $code ) {
		croak "code argument '$code' must be 'SJIS' or 'EUC'" 
			unless $code =~ /^(SJIS|EUC)$/;
		$Default{Jcode} = $code;
	}
	$prefix ||= "";
	for my $name(@EXFUNC) {
		my $to = caller;
		my $from = "";
		($from, $name) = $name =~ /^(.+)::([^:]+)$/;
		no strict 'refs';
		*{"${to}::$prefix$name"} = \&{"${from}::$name"};
	}
}

$Default{Jcode} = 'SJIS';

$Default{AFontEncoding} = 'WinAnsiEncoding';
$Default{BaseAFont} = 'Times-Roman';
$Default{JFontEncoding} = '90ms-RKSJ-H';
$Default{BaseJFont} = 'Ryumin-Light';

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

$Default{VDotXShift} = 0.5;
$Default{VDotYShift} = -0.3;
$Default{VDot}{SJIS} = "\x81\x41";
$Default{VDot}{EUC} = "\xa1\xa2";

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
	EUC-V                 je
)};

$Default{JFD}{'Ryumin-Light'} = 
	dictionary({
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
	});

$Default{JFD}{'GothicBBB-Medium'} =
	dictionary({
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
	});

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
	"\xa1\xeb" => 500, "\xa1\xec" => 500, "\xa1\xed" => 500, "\xa1\xf1" => 500, 
};

# glue width
# each element means [min, normal, max, preference]
# ruby overlap feature is omitted
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
	],
];

$Default{Splittable} = [
	[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0],
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

sub uriencode {
	my($str) = @_;
	$str =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/sprintf("%%%02X",ord($1))/ge
		unless $str =~ /%[0-9a-fA-F]{2}/;
	$str;
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
	my($ttffile, $encoding) = @_;
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

sub tounicode {
	my($str, $init) = @_;
	require PDFJ::Unicode;
	my $result = $init ? "\xfe\xff" : "";
	if( $PDFJ::Default{Jcode} eq 'SJIS' ) {
		$result .= PDFJ::Unicode::sjistounicode($str);
	} elsif( $PDFJ::Default{Jcode} eq 'EUC' ) {
		$result .= PDFJ::Unicode::euctounicode($str);
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

#--------------------------------------------------------------------------
package PDFJ::Doc;
use strict;
use Carp;
use FileHandle;
use PDFJ::Object;

sub new {
	my($class, $version, $pagewidth, $pageheight) = @_;
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
	$self;
}

sub filter {
	my($self, $flag) = @_;
	if( defined $flag ) {
		$self->{filter} = $flag; # a:ascii85, f:flate, af:both 
	}
	$self->{filter};
}

sub _add_outline {
	my($self, $title, $dest, $parent) = @_;
	$title = PDFJ::Util::tounicode($title, 1) if $title =~ /[\x80-\xff]/;
	my $lastitem = $parent->get('Last');
	my $newitem;
	if( $lastitem ) {
		$newitem = $self->indirect(dictionary({
			Title => string($title), 
			Parent => $parent,
			Prev => $lastitem,
			Count => 0,
			}));
		$newitem->set('Dest', $dest) if $dest;
		$lastitem->set('Next', $newitem);
		$parent->set('Last', $newitem);
	} else {
		$newitem = $self->indirect(dictionary({
			Title => string($title), 
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
	my($self, $title, $dest, $level) = @_;
	unless( $self->{outline} ) {
		$self->{outline} = $self->indirect(dictionary({
			Type => name('Outlines'),
			Count => 0,
			}));
		$self->{catalog}->set('Outlines', $self->{outline});
		$self->{catalog}->set('PageMode', name('UseOutlines'));
	}
	my $parent = $self->{outline};
	while( $level-- ) {
		$parent = $parent->get('Last') ?
			$parent->get('Last') :
			$self->_add_outline('', undef, $parent);
	}
	$self->_add_outline($title, $dest, $parent);
}

sub add_dest {
	my($self, $name, $dest) = @_;
	$self->{dest}{$name} = $dest;
}

sub dest {
	my($self, $name) = @_;
	$self->{dest}{$name};
}

sub indirect {
	my($self, $obj) = @_;
	$obj->indirect($self->{objtable});
}

sub print {
	my($self, $filename) = @_;
	$self->_solve_link;
	$self->_complete_subsetfont;
	my $handle = FileHandle->new(">$filename");
	return unless $handle;
	my $fobj = PDFJ::File->new($self->{version}, $handle, $self->{objtable}, 
		$self->{catalog});
	$fobj->print;
	close $handle;
}

sub new_page {
	my $self = shift;
	PDFJ::Page->new($self, @_);
}

sub get_page {
	my($self, $idx) = @_;
	$self->{pageobjlist}->[$idx];
}

sub get_lastpagenum {
	my $self = shift;
	scalar @{$self->{pagelist}};
}

sub new_font {
	if( @_ > 3 ) {
		&new_combofont;
	} else {
		&new_singlefont;
	}
}

sub new_singlefont {
	my($self, $basefont, $encoding) = @_;
	$basefont ||= $PDFJ::Default{BaseAFont};
	my $type = $PDFJ::Default{Fonts}{$basefont};
	if( $type eq 'a' ) {
		new_afont($self, $basefont, $encoding);
	} elsif( $type eq 'j' ) {
		new_jfont($self, $basefont, $encoding);
	} elsif( $basefont =~ /\.ttf$/i || $basefont =~ /\.ttc:\d$/i ) {
		if( $PDFJ::Default{Encodings}{$encoding} eq 'a' ) {
			new_afont($self, $basefont, $encoding);
		} else {
			new_jfont($self, $basefont, $encoding);
		}
	} else {
		croak "unknown font: $basefont";
	}
}

sub new_combofont {
	my($self, $zbase, $zenc, $hbase, $henc) = @_;
	my $hfont = UNIVERSAL::isa($hbase, "PDFJ::AFont") ? $hbase :
		new_afont($self, $hbase, $henc);
	new_jfont($self, $zbase, $zenc, $hfont);
}

sub new_afont {
	my($self, $basefont, $encoding) = @_;
	$basefont ||= $PDFJ::Default{BaseAFont};
	$encoding ||= $PDFJ::Default{AFontEncoding};
	croak "encoding type mismatch" 
		unless $PDFJ::Default{Encodings}{$encoding} eq 'a';
	if( $basefont =~ /\.ttf$/i || $basefont =~ /\.ttc:\d$/i ) {
		PDFJ::AFont->new_ttf($self, $basefont, $encoding);
	} else {
		PDFJ::AFont->new_std($self, $basefont, $encoding);
	}
}

sub new_jfont {
	my($self, $basefont, $encoding, $hfont) = @_;
	$basefont ||= $PDFJ::Default{BaseJFont};
	$encoding ||= $PDFJ::Default{JFontEncoding};
	croak "encoding type mismatch" 
		unless $PDFJ::Default{Encodings}{$encoding} eq 
			($PDFJ::Default{Jcode} eq 'SJIS' ? 'js' : 'je');
	if( $basefont =~ /\.ttf$/i || $basefont =~ /\.ttc:\d$/i ) {
		PDFJ::JFont->new_ttf($self, $basefont, $encoding, $hfont);
	} else {
		PDFJ::JFont->new_std($self, $basefont, $encoding, $hfont);
	}
}

sub new_image {
	my($self, $src, $pxwidth, $pxheight, $width, $height, $padding, $colorspace)
		= @_;
	PDFJ::Image->new($self, $src, $pxwidth, $pxheight, $width, $height, 
		$padding, $colorspace);
}

sub italic {
	my($self, @args) = @_;
	$self->_deco('italic', @args);
}

sub bold {
	my($self, @args) = @_;
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
		} elsif( $base->isa("PDFJ::JFont") ) {
			croak "font type mismatch" unless $deco->isa("PDFJ::JFont");
			if( $base->{combo} ) {
				croak "font combo type mismatch" unless $deco->{combo};
				$self->{$style}{$base->{zname}, $base->{hname}} = 
					join($;, $deco->{zname}, $deco->{hname});
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
	$dname = $self->{italic}{$dname} || $dname if $style->{italic};
	$dname = $self->{bold}{$dname} || $dname if $style->{bold};
	$dname;
}

sub _bold {
	my($self, $name) = @_;
	$self->{fontlist}{$self->{bold}{$name}}
}

sub _solve_link {
	my $self = shift;
	for my $pageobj(@{$self->{pageobjlist}}) {
		$pageobj->solve_link;
	}
}

sub _complete_subsetfont {
	my $self = shift;
	for my $name(keys %{$self->{subsetttf}}) {
		my $sttf = $self->{subsetttf}{$name};
		my $ttf = $sttf->{ttf};
		my $direction = $sttf->{direction};
		my @unicodes = sort keys %{$sttf->{subset_unicodes}};
		my $font = $self->{fontlist}{$name};
		my($subset, $c2g, $cidset) = $ttf->subset($direction, @unicodes);
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
}

sub _makestream {
	my($self, $src, @addfilters) = @_;
	my($encoded, $deflated, @filters);
	if( $self->filter =~ /af/ ) {
		($encoded, $deflated) = PDFJ::Util::deflate_ascii85encode($src);
		return unless $encoded;
		@filters = $deflated ? qw(ASCII85Decode FlateDecode) :
			qw(ASCII85Decode);
	} elsif( $self->filter =~ /f/ ) {
	 	$encoded = PDFJ::Util::deflate($src) or return;
		@filters = qw(FlateDecode);
	} elsif( $self->filter =~ /a/ ) {
	 	$encoded = PDFJ::Util::ascii85encode($src) or return;
		@filters = qw(ASCII85Decode);
	} else {
		return;
	}
	push @filters, @addfilters if @addfilters;
	my $filter = @filters > 1 ? [map {name($_)} @filters] : name($filters[0]);
	($encoded, $filter);
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
	my $baseorttf = $fontobj->{ttffile} || $fontobj->{basefont};
	my $encoding = $fontobj->{encoding};
	my $name = $fontobj->{name} || $fontobj->{zname};
	my $font = $fontobj->{font} || $fontobj->{zfont};
	$self->{fontname}{$baseorttf, $encoding} = $name;
	$self->{fontlist}{$name} = $font;
	if( $fontobj->{combo} ) {
		$self->{fontobjlist}{$name, $fontobj->{hname}} = $fontobj;
	} else {
		$self->{fontobjlist}{$name} = $fontobj;
	}
}

sub _registsubset {
	my($self, %args) = @_;
	$args{subset_unicodes} = {};
	$self->{subsetttf}{$args{name}} = \%args;
}

sub _subsetttf {
	my($self, $name) = @_;
	$self->{subsetttf}{$name};
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
	my($self, $name, $hname) = @_;
	$hname ? 
		$self->{fontobjlist}{$name, $hname} :
		$self->{fontobjlist}{$name};
}

sub _jcidsysteminfo {
	my $self = shift;
	unless( $self->{jcidsysteminfo} ) {
		$self->{jcidsysteminfo} = $self->indirect(dictionary({
			Registry => 'Adobe',
			Ordering => 'Japan1',
			Supplement => 2,
		}));
	}
	$self->{jcidsysteminfo};
}

sub _jfontdescriptor {
	my($self, $basefont) = @_;
	unless( $self->{jfontdescriptor}->{$basefont} ) {
		$self->{jfontdescriptor}->{$basefont} = 
			$self->indirect($PDFJ::Default{JFD}{$basefont});
	}
	$self->{jfontdescriptor}->{$basefont};
}

sub _nextimagenum {
	my $self = shift;
	1 + scalar keys %{$self->{imagelist}};
}

sub _registimage {
	my($self, $name, $image) = @_;
	$self->{imagelist}->{$name} = $image;
}

#--------------------------------------------------------------------------
package PDFJ::Font;
use strict;

#--------------------------------------------------------------------------
package PDFJ::AFont;
use strict;
use Carp;
use SelfLoader;
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
		Encoding => name($encoding),
	}));
	my $width = fontwidth($basefont);
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

sub selectname {
	my($self, $style) = @_;
	my $docobj = $self->{docobj};
	$docobj->_bolditalicname($self->{name}, $style);
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

# NOT method
my %FontWidth;
sub fontwidth {
	my($basefont) = @_;
	$basefont =~ s/-/_/g;
	return $FontWidth{$basefont} if $FontWidth{$basefont};
	my $func = "fontwidth_$basefont";
	my $result = eval { no strict 'refs'; &$func(); };
	croak $@ if $@;
	$FontWidth{$basefont} = $result if $result;
	$result;
}

#--------------------------------------------------------------------------
package PDFJ::JFont;
use strict;
use Carp;
use PDFJ::Object;
use vars qw(@ISA);
@ISA = qw(PDFJ::Font);

sub new_std {
	my($class, $docobj, $basefont, $encoding, $hfontobj) = @_;
	croak "illegal japanese font name: $basefont"
		unless $PDFJ::Default{Fonts}{$basefont} eq 'j';
	croak "ascii font type mismatch"
		if $hfontobj && !UNIVERSAL::isa($hfontobj, "PDFJ::AFont");
	my $name = $docobj->_fontname($basefont, $encoding);
	my $hname = $hfontobj ? $hfontobj->{name} : undef;
	return $docobj->_fontobj($name, $hname) 
		if $name && $docobj->_fontobj($name, $hname);
	# Zenkaku font
	my $code = $PDFJ::Default{Jcode};
	my($direction) = $encoding =~ /-(\w+)$/;
	my($zname, $zfont);
	if( $name ) {
		$zname = $name;
		$zfont = $docobj->_font($name);
	} else {
		my $jcidsi = $docobj->_jcidsysteminfo;
		my $jfd = $docobj->_jfontdescriptor($basefont);
		$zname = "F".$docobj->_nextfontnum;
		$zfont = $docobj->indirect(dictionary({
			Name => name($zname),
			Type => name("Font"),
			Subtype => name('Type0'),
			Encoding => name($encoding),
			BaseFont => name("$basefont-$encoding"),
			DescendantFonts => [{
				Type => name('Font'),
				Subtype => name('CIDFontType0'),
				BaseFont => name($basefont),
				CIDSystemInfo => $jcidsi,
				DW => 1000,
				W => [231, 389, 500, 631, [500]],
				FontDescriptor => $jfd,
			}],
		}));
	}
	# Hankaku font
	my($combo, $hfont);
	if( $hfontobj ) {
		$combo = 1;
		$hname = $hfontobj->{name};
		$hfont = $hfontobj->{font};
	} else {
		$combo = 0;
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
		hfontobj => $hfontobj,
	}, $class;
	$docobj->_registfont($self);
	$self;
}

sub new_ttf {
	my($class, $docobj, $ttffile, $encoding, $hfontobj) = @_;
	croak "TrueType subset embedding requires PDF version 1.3 or above"
		if $docobj->{version} < 1.3;
	croak "ascii font type mismatch"
		if $hfontobj && !UNIVERSAL::isa($hfontobj, "PDFJ::AFont");
	my $name = $docobj->_fontname($ttffile, $encoding);
	my $hname = $hfontobj ? $hfontobj->{name} : undef;
	return $docobj->_fontobj($name, $hname) 
		if $name && $docobj->_fontobj($name, $hname);
	# Zenkaku font
	my $code = $PDFJ::Default{Jcode};
	my($direction) = $encoding =~ /-(\w+)$/;
	my($zname, $zfont);
	if( $name ) {
		$zname = $name;
		$zfont = $docobj->_font($name);
	} else {
		my $ttf = PDFJ::Util::ttfopen($ttffile);
		my $info = $ttf->pdf_info_japan($encoding);
		croak "'$ttffile' embedding inhibited ($info->{EmbedFlag})"
			if $info->{EmbedFlag} == 2 || $info->{EmbedFlag} & 0x100 ||
				$info->{EmbedFlag} & 0x200;
		my $subsetname = $docobj->_nextsubsettag . '+' . $info->{BaseFont};
		my $basefont = $info->{BaseFont};
		my $jcidsi = $docobj->_jcidsysteminfo;
		$zname = "F".$docobj->_nextfontnum;
		$zfont = $docobj->indirect(dictionary({
			Name => name($zname),
			Type => name("Font"),
			Subtype => name('Type0'),
			Encoding => name($encoding),
			BaseFont => name($subsetname),
			DescendantFonts => [$docobj->indirect(dictionary({
				Type => name('Font'),
				Subtype => name('CIDFontType2'), # TrueType
				BaseFont => name($basefont),
				CIDSystemInfo => $jcidsi,
				DW => 1000,
				W => [231, 389, 500, 631, [500]],
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
		$docobj->_registsubset(
			name => $zname, ttf => $ttf, direction => $direction);
	}
	my $subset_unicodes = $docobj->_subsetttf($zname)->{subset_unicodes};
	# Hankaku font
	my($combo, $hfont);
	if( $hfontobj ) {
		$combo = 1;
		$hname = $hfontobj->{name};
		$hfont = $hfontobj->{font};
	} else {
		$combo = 0;
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
		hfontobj => $hfontobj,
		subset_unicodes => $subset_unicodes,
	}, $class;
	$docobj->_registfont($self);
	$self;
}

sub selectname { 
	my($self, $style, $mode) = @_;
	my $docobj = $self->{docobj};
	if( $self->{combo} ) {
		split $;, $docobj->_bolditalicname(
			join($;, $self->{zname}, $self->{hname}), $style);
	} else {
		$docobj->_bolditalicname($self->{zname}, $style);
	}
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
		$hfont->string_fontwidth($string);
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

#--------------------------------------------------------------------------
package PDFJ::Showable;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::BlockElement);

sub show {
	my($self, $page, $x, $y, $align, $transtype, @args) = @_;
	if( $transtype ) {
		if( $transtype eq 'magnify' ) {
			my($xmag, $ymag) = @args;
			$page->addcontents("q $xmag 0 0 $ymag $x $y cm");
		} elsif( $transtype eq 'rotate' ) {
			my($rad) = @args;
			my $sin = sin($rad);
			my $cos = cos($rad);
			my $msin = -$sin;
			$page->addcontents("q $cos $sin $msin $cos $x $y cm");
		} elsif( $transtype eq 'distort' ) {
			my($xtan, $ytan) = @args;
			$page->addcontents("q 1 $xtan $ytan 1 $x $y cm");
		} else {
			croak "unknown transformation type";
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
	if( @args == 1 && ref($args[0]) eq 'HASH' ) {
		%$self = %{$args[0]};
	} else {
		%$self = @args;
	}
	bless $self, $class;
}

sub clone {
	my($self, @args) = @_;
	my $clone = $self->new(%$self);
	if( @args ) {
		my %args;
		if( @args == 1 && ref($args[0]) eq 'HASH' ) {
			%args = %{$args[0]};
		} else {
			%args = @args;
		}
		for my $key(keys %args) {
			$clone->{$key} = $args{$key};
		}
	}
	$clone;
}

sub merge {
	my($self, $from) = @_;
	for my $key(keys %$from) {
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
	$self->SUPER::merge($from);
}

sub selectfontname {
	my($self, $mode) = @_;
	my $font = $self->{font} or return;
	$font->selectname($self, $mode);
}

#--------------------------------------------------------------------------
package PDFJ::TextSpec;
use strict;
use Carp;

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
	my($self, $style, $fontname) = @_;
	%$self = ();
	for my $key(qw(fontsize render rise shapestyle)) {
		if( exists $style->{$key} ) {
			$self->{$key} = $style->{$key};
		}
	}
	$self->{fontname} = $fontname;
}

sub copy {
	my($self, $from) = @_;
	%$self = %$from;
}

sub equal {
	my($self, $other) = @_;
	for my $key(qw(fontname fontsize render rise shapestyle)) {
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
	my $shapepdf = $self->{shapestyle} ? $self->{shapestyle}->pdf : "";
	my $pdf = "q ";
	$pdf .= "$shapepdf " if $shapepdf;
	$pdf .= "BT /$fontname $fontsize Tf $rise Ts $render Tr ";
	$pdf;
}

#--------------------------------------------------------------------------
package PDFJ::NewLine;
use Carp;
use strict;

sub NewLine { PDFJ::NewLine->new(@_) }

sub new { 
	my($class) = @_;
	bless \$class, $class;
}

#--------------------------------------------------------------------------
package PDFJ::Outline;
use Carp;
use strict;

sub Outline { PDFJ::Outline->new(@_) }

sub new { 
	my($class, $title, $level) = @_;
	bless {outlinetitle => $title, outlinelevel => $level}, $class;
}

#--------------------------------------------------------------------------
package PDFJ::Dest;
use Carp;
use strict;

sub Dest { PDFJ::Dest->new(@_) }

sub new { 
	my($class, $name) = @_;
	bless {destname => $name}, $class;
}

#--------------------------------------------------------------------------
package PDFJ::Text;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Showable);

sub Text { PDFJ::Text->new(@_) }

sub new {
	my $class = shift;
	my $style = pop; # not shift
	if( UNIVERSAL::isa($style, 'PDFJ::TextStyle') ) {
		$style = $style->clone;
	} elsif( ref($style) eq 'HASH' ) {
		$style = PDFJ::TextStyle->new($style);
	} else {
		croak "style argument must be a PDFJ::TextStyle object or HASHref";
	}
	my @texts = @_;
	my $texts = (@texts == 1 && ref($texts[0]) eq 'ARRAY') ? $texts[0] : \@texts;
	my $self = bless { texts => $texts, style => $style }, $class;
	$self->mergestyle;
	# $self->print;
	$self->makechunks;
	$self->makerubytext;
	$self;
}

sub mergestyle {
	my($self) = @_;
	my $style = $self->style;
	return unless $style->{font};
	for my $text(@{$self->texts}) {
		if( UNIVERSAL::isa($text, 'PDFJ::Text') ) {
			$text->style->merge($style);
			$text->mergestyle;
		}
	}
}

# for debug
sub print {
	my($self, $indent) = @_;
	my $style = $self->style;
	print $indent,join(',',%$style),"\n";
	for my $text(@{$self->texts}) {
		if( UNIVERSAL::isa($text, 'PDFJ::Text') ) {
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
	$self->{chunks} = [];
	$self->{lines} = [];
	for my $text(@{$self->texts}) {
		if( UNIVERSAL::isa($text, 'PDFJ::Text') ) {
			$text->makechunks unless $text->chunks;
			$self->catchunks($text->chunks);
		} elsif( UNIVERSAL::isa($text, 'PDFJ::Showable') ) {
			$self->catchunks([_objchunk($text, $self->style)]);
#		} elsif( UNIVERSAL::isa($text, 'PDFJ::Image') ) {
#			$self->catchunks([_imagechunk($text, $self->style)]);
#		} elsif( UNIVERSAL::isa($text, 'PDFJ::Shape') ) {
#			$self->catchunks([_shapechunk($text, $self->style)]);
		} elsif( UNIVERSAL::isa($text, 'PDFJ::NewLine') ) {
			$self->catchunks([_newlinechunk($self->style)]);
		} elsif( UNIVERSAL::isa($text, 'PDFJ::Outline') ) {
			$self->catchunks([_outlinechunk($text, $self->style)]);
		} elsif( UNIVERSAL::isa($text, 'PDFJ::Dest') ) {
			$self->catchunks([_destchunk($text, $self->style)]);
		} else {
			$self->catchunks($self->splittext($text));
		}
	}
}

sub makerubytext {
	my($self) = @_;
	return unless $self->style->{font};
	for my $chunk(@{$self->chunks}) {
		my $style = $chunk->{Style};
		if( $style->{ruby} ) {
			croak "ruby class mismatch" 
				unless $chunk->{Class} == 11 || $chunk->{Class} == 17;
			my $rubystyle = $style->clone;
			delete $rubystyle->{ruby};
			delete $rubystyle->{withbox};
			delete $rubystyle->{withline};
			$rubystyle->{fontsize} /= 2;
			my $rubytext = PDFJ::Text->new($style->{ruby}, $rubystyle);
			my $rubysize = $rubytext->size;
			my $chunksize = _chunksize($chunk, 1);
			if( $rubysize < $chunksize ) {
				my $alt = PDFJ::Paragraph->new($rubytext,
					PDFJ::ParagraphStyle->new(size => $chunksize, 
						align => 'ruby', linefeed => 0));
				$chunk->{RubyText} = $alt;
			} elsif( $rubysize > $chunksize ) {
				my $altstyle = $style->clone;
				delete $altstyle->{ruby};
				delete $altstyle->{withbox};
				delete $altstyle->{withline};
				my $alt = PDFJ::Paragraph->new(
					PDFJ::Text->new($chunk->{String}, $altstyle),
					PDFJ::ParagraphStyle->new(size => $rubysize, 
						align => 'ruby', linefeed => 0));
				$chunk->{AltObj} = $alt;
				$chunk->{RubyText} = $rubytext;
			} else {
				$chunk->{RubyText} = $rubytext;
			}
		}
	}
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

my %TextLineIndex = (
	Start => 1,
	Count => 2,
	Shift => 3,
	FixedGlues => 4,
);

sub _fold {
	my($self, $linesize, $align) = @_;
	my $chunks = $self->chunks;
	return unless @$chunks;
	$self->dehyphen;
	my @lines;
	my @linesizes = ref($linesize) eq 'ARRAY' ? @$linesize : ($linesize);
	my $lastlinesize = $linesizes[$#linesizes];
	my $rubyshift;
	if( $align eq 'ruby' ) {
		$rubyshift = ($linesizes[0] - _chunkssize($chunks)) / $self->count;
		$linesizes[0] -= $rubyshift;
		$rubyshift /= 2;
		$align = 'W';
	}
	my $start = 0;
	while( $start < @$chunks ) {
		$linesize = @linesizes ? shift(@linesizes) : $lastlinesize;
		croak "not enough paragraph size" if $linesize < 0;
		my $size = 0;
		my $decsize = 0;
		my $foldpos = $start;
		my $canpos = $start;
		my $forced;
		for( my $j = $start; $j < @$chunks; $j++ ) {
			my $chunk = $chunks->[$j];
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
					} else {
						$foldpos = $canpos;
					}
					last;
				}
			}
#print "$j:$start:($chunk->{Splittable})[$chunk->{String}] $chunksize(-$decchunksize) $size(-$decsize) $canpos\n";
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
		push @lines, [\%TextLineIndex, $start, $count, $shift, $fixedglues];
		$start = $nextpos;
	}
	@lines;
}

sub _hyphenpos {
	my($chunk, $decsize) = @_;
	return unless $chunk->{Class} == 17 && !$chunk->{Style}{nohyphen} &&
		!$chunk->{Style}{ruby};
	my $string = $chunk->{String};
#print "$string, $decsize\n";
	my($can, $canleft, $pre, $word);
	if( $string =~ /([A-Za-z]-)([A-Za-z])/ ) {
		$can = $`.$1;
		$canleft = $2.$';
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
	my $fontobj = $chunk->{Style}{font};
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
	my $fontsize = $chunk->{Style}{fontsize};
	my $direction = $fontobj->{direction};
	my $size = $direction eq 'H' ? 
		_chunkfontsizeH($fontobj, $fontsize, $chunk) :
		_chunkfontsizeV($fontobj, $fontsize, $chunk);
	$size += $fontsize * ($fixedglue - 
		$chunk->{PreShift} - $chunk->{PostShift});
	$size;
}

sub _chunkfontsizeH {
	my($fontobj, $fontsize, $chunk) = @_;
	return $chunk->{AltObj}->size('H') if $chunk->{AltObj};
	my $size = 0;
	if( UNIVERSAL::isa($fontobj, "PDFJ::JFont") ) {
		my $combo = $fontobj->{combo};
		my $hfont = $fontobj->{hfontobj};
		my $mode = $chunk->{Mode};
		if( $mode eq 'z' ) {
			$size = $chunk->{Count};
		} elsif( $mode eq 'h' ) {
			$size = $chunk->{Count} / 2;
		} elsif( $combo ) {
			$size = $hfont->string_fontwidth($chunk->{String});
		} else {
			$size = $chunk->{Count} / 2;
		}
	} elsif( UNIVERSAL::isa($fontobj, "PDFJ::AFont") ) {
		$size = $fontobj->string_fontwidth($chunk->{String});
	} else { 
		croak "internal error: missing font object";
	}
	$size *= $fontsize;
	$size;
}

sub _chunkfontsizeV {
	my($fontobj, $fontsize, $chunk) = @_;
	return $chunk->{AltObj}->size('V') if $chunk->{AltObj};
	my $size = 0;
	if( UNIVERSAL::isa($fontobj, "PDFJ::JFont") ) {
		my $combo = $fontobj->{combo};
		my $hfont = $fontobj->{hfontobj};
		my $mode = $chunk->{Mode};
		if( $mode eq 'z' ) {
			$size = $chunk->{Count};
		} elsif( $mode eq 'h' ) {
			$size = $chunk->{Count};
		} elsif( $combo ) {
			$size = $chunk->{Class} == 11 ? 1 :
				$hfont->string_fontwidth($chunk->{String});
		} else {
			$size = $chunk->{Count};
		}
	} elsif( UNIVERSAL::isa($fontobj, "PDFJ::AFont") ) {
		$size = $fontobj->string_fontwidth($chunk->{String});
	} else { 
		croak "internal error: missing font object";
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
	my($tj, $dotpdf, $shapepdf) = ("") x 3;
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
		my($fontname, $hname) = $style->selectfontname($mode);
		my $fontobj = $style->{font} = $docobj->_fontobj($fontname, $hname);
		my $combo = $fontobj->{combo};
		my $usefname = $mode eq 'a' && $hname ? $hname : $fontname;
		$usefontname{$usefname}++;
		my $fontsize = $style->{fontsize};
		$postshift *= $lastfontsize / $fontsize;
		$style->{slant} = 1 if $mode eq 'z' && $style->{italic};
		my $textspec = PDFJ::TextSpec->new($style, $usefname);
		if( $direction eq 'V' && $combo && $mode eq 'a' ) {
			if( $va != $class ) {
				my($vax, $vay) = $class == 11 ? 
					($x - _chunkfontsizeH($fontobj, $fontsize, $chunk) / 2,
					$y - $fontsize * $PDFJ::Default{VHShift}) : 
					($x + $fontsize * $PDFJ::Default{VAShift}, $y);
				$tj .= "] TJ ET Q " if $tj;
				$tj .= $class == 11 ? 
					$textspec->pdf."$vax $vay Td  [" :
					$textspec->pdf."0 -1 1 0 $vax $vay Tm [";
				$lasttextspec->copy($textspec);
				$va = $class;
			}
		} elsif( $va ) {
			$tj .= "] TJ ET Q " if $tj;
			$tj .= $textspec->pdf."$x $y Td [";
			$lasttextspec->copy($textspec);
			$va = 0;
		}
		if( $style->{slant} ) {
			#croak "slant style for ascii not allowed" 
			#	if $mode eq 'a';
			unless( $slant ) {
				my($sx, $sy) = $direction eq 'H' ? 
					(0, $PDFJ::Default{SlantRatio}) : 
					($PDFJ::Default{SlantRatio}, 0);
				$tj .= "] TJ ET Q " if $tj;
				$tj .= $textspec->pdf."1 $sx $sy 1 $x $y Tm [";
				$lasttextspec->copy($textspec);
				$slant = 1;
			}
		} elsif( $slant ) {
			$tj .= "] TJ ET Q " if $tj;
			$tj .= $textspec->pdf."$x $y Td [";
			$lasttextspec->copy($textspec);
			$slant = 0;
		}
		unless( $lasttextspec->equal($textspec) ) {
			$tj .= "] TJ ET Q " if $tj;
			$tj .= $textspec->pdf."$x $y Td [";
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
			$tj .= "$vs " 
		}
		my($flx, $fly) = ($x, $y);
		my($frx, $fry) = ($x, $y);
		my($fcx, $fcy) = ($x, $y);
		if( $direction eq 'H' ) {
			$flx -= ($postshift - ($j == 0 ? 0 : 
				($fixedglues ? $chunk->{Glue} + ($fixedglues->[$j] || 0): 
				$chunk->{Glue}))) * $fontsize;
			$frx = $flx + (_chunkfontsizeH($fontobj, $fontsize, $chunk) -
				($chunk->{PreShift} + $chunk->{PostShift}) * $fontsize);
			$fcx = $flx + (_chunkfontsizeH($fontobj, $fontsize, $chunk) -
				($chunk->{PreShift} + $chunk->{PostShift}) * $fontsize) /
				 2;
		} else {
			$fly += ($postshift - ($j == 0 ? 0 : 
				($fixedglues ? $chunk->{Glue} + ($fixedglues->[$j] || 0): 
				$chunk->{Glue}))) * $fontsize;
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
				$docobj->add_outline($title, $page->dest('XYZ', $ox, $oy, 0), 
					$level);
			} elsif( $mode eq 'D' ) {
				my $name = $style->{destname};
				$docobj->add_dest($name, $page->dest('XYZ', $ox, $oy, 0));
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
			$tj .= "$altsize ";
			$altobj->show($page, $flx + $asx, $fly + $asy, $align);
		} elsif( $chunk->{String} =~ /[^\x20-\x7e]/ ) {
			my $ss = unpack('H*', $chunk->{String});
			$tj .= "<$ss> ";
		} else {
			my $ss = $chunk->{String};
			$ss =~ s/\\/\\\\/g;
			$ss =~ s/\(/\\\(/g;
			$ss =~ s/\)/\\\)/g;
			$tj .= "($ss) ";
		}
		$postshift = $chunk->{PostShift};
		if( $style->{withline} ) {
			($ulx, $uly) = ($flx, $fly) unless defined $ulx;
			$withlinestyle = $style->{withlinestyle};
			if( $j == $count - 1 || $start + $j == $chunksnum - 1 ) {
				$shapepdf .= $direction eq 'H' ? 
					_withlinepdf($direction, $ulx, $uly, $frx - $ulx, 
						$fontsize, $withlinestyle) :
					_withlinepdf($direction, $ulx, $uly, $fry - $uly, 
						$fontsize, $withlinestyle);
			}
		} elsif( defined $ulx ) {
			$shapepdf .= $direction eq 'H' ? 
				_withlinepdf($direction, $ulx, $uly, $lastfrx - $ulx, 
					$lastfontsize, $withlinestyle) :
				_withlinepdf($direction, $ulx, $uly, $lastfry - $uly, 
					$lastfontsize, $withlinestyle);
			undef $ulx;
			undef $uly;
		}
		if( $style->{withbox} ) {
			($bxx, $bxy) = ($flx, $fly) unless defined $bxx;
			$withbox = $style->{withbox};
			$withboxstyle = $style->{withboxstyle};
			if( $j == $count - 1 || $start + $j == $chunksnum - 1 ) {
				$shapepdf .= $direction eq 'H' ? 
					_withboxpdf($page, $direction, $bxx, $bxy, $frx - $bxx, 
						$fontsize, $withbox, $withboxstyle) :
					_withboxpdf($page, $direction, $bxx, $bxy, $fry - $bxy, 
						$fontsize, $withbox, $withboxstyle);
			}
		} elsif( defined $bxx ) {
			$shapepdf .= $direction eq 'H' ? 
				_withboxpdf($page, $direction, $bxx, $bxy, $lastfrx - $bxx, 
					$lastfontsize, $withbox, $withboxstyle) :
				_withboxpdf($page, $direction, $bxx, $bxy, $lastfry - $bxy, 
					$lastfontsize, $withbox, $withboxstyle);
			undef $bxx;
			undef $bxy;
		}
		if( $style->{withdot} ) {
			croak "withdot style needs JFont"
				unless UNIVERSAL::isa($fontobj, "PDFJ::JFont");
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
			$dotpdf .= "BT 0 Ts 0 Tr /$fontname $ds Tf $dx $dy Td <$dcode> Tj ET ";
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
	$tj .= "] TJ ET Q " if $tj;
	$tj =~ s/> <//g;
	$tj =~ s/\) \(//g;
	$page->addcontents($shapepdf);
	$page->addcontents($tj);
	$page->addcontents($dotpdf);
	$page->usefonts(keys %usefontname);
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

# modes are
# 'z': zenkaku Japanese
# 'h': hankaku Japanese
# 'a': ascii
# 'S': ShowableObj
# 'N': Newline
# 'O': Outline
# 'D': Destination

# chunk array index
my %ChunkIndex = (
	Style => 1,			# PDFJ::TextStyle object
	Mode => 2,			# description as above
	Class => 3,			# description as above
	Splittable => 4,	# 1 for splittable at pre-postion
	Glue => 5,			# normal glue width
	GlueDec => 6,		# decrease adjustable glue width
	GlueInc => 7,		# increase adjustable glue width
	GluePref => 8,		# glue preference
	Count => 9,			# characters count
	String => 10,		# characters string
	PreShift => 11,		# postion shift at pre-postion
	PostShift => 12,	# postion shift at post-postion
	GlueFix => 13,		# fixed glue (to be calculated)
	Hyphened => 14,		# 1 for splitted, 2 for hyphened
	RubyText => 15,		# ruby PDFJ::Text object
	AltObj => 16,		# alternative object for String 
);

sub _specialchunk {
	my($style, $mode, $class, $splittable) = @_;
	[\%ChunkIndex, $style, $mode, $class, $splittable,
		0, 0, 0, 0, 0, "", 0, 0];
}

sub _newlinechunk {
	my($textstyle) = @_;
	_specialchunk($textstyle, 'N', 11, 2);
}

sub _outlinechunk {
	my($outlineobj, $textstyle) = @_;
	my $style = $textstyle->clone(%$outlineobj);
	_specialchunk($style, 'O', 11, 1);
}

sub _destchunk {
	my($destobj, $textstyle) = @_;
	my $style = $textstyle->clone(%$destobj);
	_specialchunk($style, 'D', 11, 1);
}

sub _objchunk {
	my($obj, $textstyle) = @_;
	my $chunk = _specialchunk($textstyle, 'S', 11, 1);
	$chunk->{AltObj} = $obj;
	$chunk;
}

# obsolete
sub _imagechunk {
	my($img, $textstyle) = @_;
	my $chunk = _specialchunk($textstyle, 'I', 11, 1);
	$chunk->{AltObj} = $img;
	$chunk;
}

# obsolete
sub _shapechunk {
	my($shape, $textstyle) = @_;
	my $chunk = _specialchunk($textstyle, 'S', 11, 1);
	$chunk->{AltObj} = $shape;
	my($left, $bottom) = ($shape->left, $shape->bottom);
	$chunk;
}

sub catchunks {
	my($self, $src) = @_;
	my $dest = $self->chunks;
	if( @$dest && @$src ) {
		my($splittable, $glue, $gluedec, $glueinc, $gluepref);
		my $lastclass = _lastclass($dest);
		my $lastmode = _lastmode($dest);
		my $fchunk = $src->[0];
		my $class = $fchunk->{Class};
		my $mode = $fchunk->{Mode};
		my $style = $fchunk->{Style};
		$splittable = $fchunk->{Splittable} == 2 ? 2 : 
			$style->{suffix} ? 0 : 
			$lastmode eq 'O' ? 0 :
			$PDFJ::Default{Splittable}->[$lastclass][$class];
		$glue = ($lastmode =~ /^[ON]$/ || $mode =~ /^[ON]$/) ? 
			PDFJ::GlueNon :
			$PDFJ::Default{Glue}->[$lastclass][$class];
		($glue, $gluedec, $glueinc, $gluepref) = _calcglue($glue);
		$fchunk->{Splittable} = $splittable;
		$fchunk->{Glue} = $glue;
		$fchunk->{GlueDec} = $gluedec;
		$fchunk->{GlueInc} = $glueinc;
		$fchunk->{GluePref} = $gluepref;
	}
	push @$dest, @$src;
}

sub _appendchunks {
	my($chunks, $style, $mode, $class, $char, $preshift, $postshift) = @_;
	$preshift ||= 0;
	$postshift ||= 0;
	my($splittable, $glue, $gluedec, $glueinc, $gluepref) = (0) x 5;
	if( exists $style->{font} && exists $style->{font}{subset_unicodes} ) {
		my $unicode = $PDFJ::Default{Jcode} eq 'SJIS' ? 
			PDFJ::Unicode::s2u($char) : PDFJ::Unicode::e2u($char);
		$style->{font}{subset_unicodes}{$unicode}++;
	}
	if( @$chunks ) {
		my $lastchunk = $chunks->[$#$chunks];
		my $lastmode = $lastchunk->{Mode};
		my $lastclass = $lastchunk->{Class};
		my $lastruby = $lastchunk->{Style}{ruby};
		$splittable = $style->{suffix} ? 0 : 
			$lastmode eq 'O' ? 0 :
			$PDFJ::Default{Splittable}->[$lastclass][$class];
		$glue = ($lastmode =~ /^[ON]$/ || $mode =~ /^[ON]$/) ? 
			PDFJ::GlueNon :
			$PDFJ::Default{Glue}->[$lastclass][$class];
		if( ($mode eq 'a' && $lastmode eq 'a' && $class == $lastclass && 
			($class == 11 || (!@$glue && !$splittable))) ||
			($style->{ruby} && $style->{ruby} eq $lastruby && 
			($class == 11 || $class == 17) && $class == $lastclass)
			 ) {
			$lastchunk->{Count}++;
			$lastchunk->{String} .= $char;
			return;
		}
		($glue, $gluedec, $glueinc, $gluepref) = _calcglue($glue);
	}
	push @$chunks, [\%ChunkIndex, $style, $mode, $class, $splittable, 
		$glue, $gluedec, $glueinc, $gluepref, 1, $char, 
		$preshift, $postshift];
}

sub _calcglue {
	my($glue) = @_;
	my($gluedec, $glueinc, $gluepref) = (0, 0, 0);
	if( @$glue ) {
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

sub _lastclass {
	my($chunks) = @_;
	@$chunks ? $chunks->[$#$chunks]{Class} : undef;
}

sub _lastmode {
	my($chunks) = @_;
	@$chunks ? $chunks->[$#$chunks]{Mode} : undef;
}

sub splittext {
	my($self, $str) = @_;
	if(  UNIVERSAL::isa($self->style->{font}, "PDFJ::AFont") ) {
		&splittext_ASCII;
	} elsif( $PDFJ::Default{Jcode} eq 'SJIS' ) {
		&splittext_SJIS;
	} else {
		&splittext_EUC;
	}
}

sub splittext_ASCII {
	my($self, $str) = @_;
	my $style = $self->style;
	my $result = [];
	my @c = split('', $str);
	for( my $j = 0; $j <= $#c; $j++ ) {
		my $c = $c[$j];
		if( $c eq " " ) {
			_appendchunks($result, $style, 'a', 16, $c);
		} else {
			if( $style->{vh} ) {
				_appendchunks($result, $style, 'a', 11, $c);
			} elsif( $c =~ /[0-9]/ ) {
				_appendchunks($result, $style, 'a', 14, $c);
			} elsif( $c =~ /[,. ]/ && _lastclass($result) == 14 &&
				$c[$j+1] =~ /[0-9]/ ) {
				_appendchunks($result, $style, 'a', 14, $c);
			} else {
				_appendchunks($result, $style, 'a', 17, $c);
			}
		}
	}
	$result;
}

sub splittext_EUC {
	my($self, $str) = @_;
	my $style = $self->style;
	my $result = [];
	my @c = split('', $str);
	for( my $j = 0; $j <= $#c; $j++ ) {
		my $c = $c[$j];
		if( $c eq "\x8e" ) {
			_appendchunks($result, $style, 'h', 11, $c.$c[$j+1]);
			$j++;
		} elsif( $c eq "\x8f" ) {
			_appendchunks($result, $style, 'z', 11, $c.$c[$j+1].$c[$j+2]);
			$j += 2;
		} elsif( $c eq " " ) {
			_appendchunks($result, $style, 'a', 16, $c);
		} elsif( $c lt "\xa0" ) {
			if( $style->{vh} ) {
				_appendchunks($result, $style, 'a', 11, $c);
			} elsif( $c =~ /[0-9]/ ) {
				_appendchunks($result, $style, 'a', 14, $c);
			} elsif( $c =~ /[,. ]/ && _lastclass($result) == 14 && 
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
			my $preshift = ($PDFJ::Default{PreShift}{EUC}{$k} || 0) / 1000;
			my $postshift = ($PDFJ::Default{PostShift}{EUC}{$k} || 0) / 1000;
			_appendchunks($result, $style, 'z', $class, $k, $preshift, $postshift);
		}
	}
	$result;
}

sub splittext_SJIS {
	my($self, $str) = @_;
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
			my $preshift = ($PDFJ::Default{PreShift}{SJIS}{$k} || 0) / 1000;
			my $postshift = ($PDFJ::Default{PostShift}{SJIS}{$k} || 0) / 1000;
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
			} elsif( $c =~ /[,. ]/ && _lastclass($result) == 14 &&
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
	my($class, $text, $style) = @_;
	croak "paragraph text argument must be a PDFJ::Text object"
		unless UNIVERSAL::isa($text, 'PDFJ::Text');
	croak "paragraph style argument must be a PDFJ::ParagraphStyle object"
		unless UNIVERSAL::isa($style, 'PDFJ::ParagraphStyle');
	croak "size specification missing" unless $style->{size};
	croak "linefeed specification missing" unless exists $style->{linefeed};
	croak "align specification missing" unless $style->{align};
	my $self = bless { text => $text, style => $style }, $class;
	$self->{linefeed} = $style->{linefeed} =~ /(\d+)%/ ? 
		$text->fontsize * $1 / 100 : $style->{linefeed};
	my $lineskip = $self->{linefeed} - $text->fontsize;
	$lineskip = 0 if $lineskip < 0;
	$self->{preskip} = exists $style->{preskip} ? 
		$style->{preskip} : $lineskip * $PDFJ::Default{ParaPreSkipRatio};
	$self->{postskip} = exists $style->{postskip} ? 
		$style->{postskip} : $lineskip * $PDFJ::Default{ParaPostSkipRatio};
	my $labeltext = $style->{labeltext};
	my $firstminindent = 0;
	if( $labeltext ) {
		if( UNIVERSAL::isa($labeltext, 'PDFJ::Showable') ) {
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
	my @lines = $text->_fold($self->linesizes, $style->{align});
	$self->{lines} = \@lines;
	$self;
}

sub text { $_[0]->{text} }
sub linesnum { scalar(@{$_[0]->{lines}}) }
sub line { $_[0]->{lines}->[$_[1]] }
sub labelsize { $_[0]->{style}->{labelsize} || 0 }
sub labelskip { $_[0]->{style}->{labelskip} || 0 }
sub beginpadding { $_[0]->{style}->{beginpadding} || 0 }
sub beginindents { scalar @{$_[0]->{beginindent}} }
sub beginindent { 
	my($self, $idx) = @_;
	my $count = @{$self->{beginindent}};
	if( $idx < $count ) {
		$self->{beginindent}[$idx];
	} else {
		$self->{beginindent}[$count - 1];
	}
}
sub endindents { scalar @{$_[0]->{endindent}} }
sub endindent { 
	my($self, $idx) = @_;
	my $count = @{$self->{endindent}};
	if( $idx < $count ) {
		$self->{endindent}[$idx];
	} else {
		$self->{endindent}[$count - 1];
	}
}
sub _size { $_[0]->{style}{size} }
sub linesizes { 
	my($self) = @_;
	my @linesizes;
	my $count = $self->beginindents > $self->endindents ? 
		$self->beginindents :
		$self->endindents;
	for( my $j = 0; $j < $count; $j++ ) {
		push @linesizes, $self->_size - $self->beginpadding - $self->labelsize - 
			$self->beginindent($j) - $self->endindent($j);
	}
	\@linesizes;
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
	$self->linesnum ? 
		$self->text->fontsize + ($self->linesnum - 1) * $self->linefeed : 0;
}

sub break {
	my($self, @sizes) = @_;
	my $unbreakable = $self->nobreak;
	my $lastsize = $sizes[$#sizes];
	my @result;
	my @lines = @{$self->{lines}};
	my @beginindents = @{$self->{beginindent}};
	my @endindents = @{$self->{endindent}};
	my $second;
	while( @lines ) {
		my $size = @sizes ? shift(@sizes) : $lastsize;
		my $count = $unbreakable ? 
			($size < $self->_linessize ? 0 : scalar(@lines)) :
			($size < $self->text->fontsize ? 0 : 
			int(($size - $self->text->fontsize) / $self->linefeed) + 1);
		return if !$count && !@sizes;
		my @blines = splice @lines, 0, $count;
		my @bbi = splice @beginindents, 0, $count;
		@beginindents = ($bbi[$#bbi]) unless @beginindents;
		my @bei = splice @endindents, 0, $count;
		@endindents = ($bei[$#bei]) unless @endindents;
		my $bpara = bless {text => $self->{text}, 
				style => $self->{style},
				linefeed => $self->{linefeed}, preskip => $self->{preskip},
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

sub _show {
	my($self, $page, $x, $y) = @_;
	for( my $j = 0; $j < $self->linesnum; $j++ ) {
		($x, $y) = $self->_showline($page, $x, $y, $j);
	}
	($x, $y);
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
	my $linefeed = $self->linefeed;
	my $text = $self->text;
	my $tstyle = $text->style;
	croak "no font specification" unless exists $tstyle->{font};
	my $direction = $tstyle->{font}{direction};
	if( $line == 0 && $self->{labelobj} ) {
		my($lx, $ly) = $direction eq 'H' ? ($x + $self->beginpadding, $y) :
			($x, $y - $self->beginpadding);
		$self->{labelobj}->show($page, $lx, $ly);
	}
	my($nextx, $nexty);
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

#--------------------------------------------------------------------------
package PDFJ::BlockSkip;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::BlockElement);

sub new {
	my($class, $skip) = @_;
	bless {skip => $skip}, $class;
}

sub size { $_[0]->{skip} || 0 }

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
use vars qw(@ISA);
@ISA = qw(PDFJ::Showable);

sub Block { PDFJ::Block->new(@_); }

sub new {
	my $class = shift;
	my $direction = shift;
	my $style = pop; # not shift
	croak "block direction argument must be H or V or R"
		unless $direction =~ /^H|V|R$/;
	croak "block style argument must be a PDFJ::BlockStyle object"
		unless UNIVERSAL::isa($style, 'PDFJ::BlockStyle');
	my @objects = (@_ == 1 && ref($_[0]) eq 'ARRAY') ? @{$_[0]} : @_;
	for( my $j = 0; $j < @objects; $j++ ) {
		if( UNIVERSAL::isa($objects[$j], 'PDFJ::BlockElement') ) {
			# OK
		} elsif( $objects[$j] =~ /^\d+$/ ) {
			$objects[$j] = PDFJ::BlockSkip->new($objects[$j]);
		} else {
			croak "illegal Block element: $objects[$j]"
		}
	}
	my $self = bless { direction => $direction, objects => \@objects, 
		xpreshift => 0, xpostshift => 0, ypreshift => 0, ypostshift => 0, 
		style => $style }, $class;
	$self->_calcsize;
	$self->adjustwidth($style->{width}) if $style->{width};
	$self->adjustheight($style->{height}) if $style->{height};
	$self;
}

sub break {
	my($self, @sizes) = @_;
	my $unbreakable = $self->nobreak;
	my $nofirstfloat = $self->nofirstfloat;
	my $repeatheader = $self->repeatheader;
	my $lastsize = $sizes[$#sizes];
	my $direction = $self->{direction} eq 'V' ? 'V' : 'H';
	my @result;
	my @objects = @{$self->{objects}};
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
				my $float = $obj->float;
				if( $float && @reserve ) {
					push @reserve, shift(@objects);
					next;
				}
				if( $float eq 'b' && $nofirstfloat && !@result ) {
					push @reserve, shift(@objects);
					next;
				}
				my $inspos = _inspos(\@bobjects, $float);
				my $skipsize = 0;
				if( $inspos == 0 ) {
					$skipsize = $obj->postskip + $bobjects[$inspos]->preskip 
						if @bobjects;
				} elsif( $inspos == @bobjects ) {
					$skipsize = $bobjects[$inspos - 1]->postskip + $obj->preskip;
				} else {
					$skipsize = $obj->preskip + $obj->postskip;
				}
				my $osize = $obj->size($direction);
				if( UNIVERSAL::isa($obj, 'PDFJ::NewBlock') ) {
					shift(@objects);
					last;
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
						if( $osize ) {
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
						return;
					}
				} else {
					if( $float ) {
						push @reserve, shift(@objects);
					} else {
						last;
					}
				}
			}
		}
		while( @bobjects && $bobjects[$#bobjects]->postnobreak && @objects ) {
			unshift @objects, pop(@bobjects);
		}
		return if !@bobjects && !@sizes;
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
	my $inspos;
	if( $float eq 'b' ) {
		$inspos = 0;
		while( $inspos < @$objects && $objects->[$inspos]->float eq 'b' ) {
			$inspos++;
		}
	} elsif( $float eq 'e' ) {
		$inspos = @$objects;
	} else {
		$inspos = @$objects;
		while( $inspos > 0 && $objects->[$inspos - 1]->float eq 'e' ) {
			$inspos--;
		}
	}
	$inspos;
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
				$height += $self->{objects}->[$j-1]->postskip + $obj->preskip;
			}
			if( UNIVERSAL::isa($obj, 'PDFJ::Showable') ) {
				$width = $width < $obj->width ? $obj->width : $width;
				$height += $obj->height;
			} elsif( UNIVERSAL::isa($obj, 'PDFJ::BlockElement') ) {
				$height += $obj->size($self->{direction});
			} else {
				croak "illegal block element";
			}
		}
		if( $adjust ) {
			for my $obj(@{$self->{objects}}) {
				$obj->adjustwidth($width) if UNIVERSAL::isa($obj, 'PDFJ::Block');
			}
		}
		my @indents;
		if( $align =~ /c/ ) {
			for( my $j = 0; $j < $objnum; $j++ ) {
				my $obj = $self->{objects}->[$j];
				if( UNIVERSAL::isa($obj, 'PDFJ::Showable') ) {
					$indents[$j] = ($width - $obj->width) / 2;
				}
			}
		} elsif( $align =~ /r/ ) {
			for( my $j = 0; $j < $objnum; $j++ ) {
				my $obj = $self->{objects}->[$j];
				if( UNIVERSAL::isa($obj, 'PDFJ::Showable') ) {
					$indents[$j] = $width - $obj->width;
				}
			}
		}
		$self->{indents} = \@indents;
	} else {
		for( my $j = 0; $j < $objnum; $j++ ) {
			my $obj = $self->{objects}->[$j];
			if( $j > 0 ) {
				$width += $self->{objects}->[$j-1]->postskip + $obj->preskip;
			}
			if( UNIVERSAL::isa($obj, 'PDFJ::Showable') ) {
				$height = $height < $obj->height ? $obj->height : $height;
				$width += $obj->width;
			} elsif( UNIVERSAL::isa($obj, 'PDFJ::BlockElement') ) {
				$width += $obj->size($self->{direction});
			} else {
				croak "illegal block element";
			}
		}
		if( $adjust ) {
			for my $obj(@{$self->{objects}}) {
				$obj->adjustheight($height) 
					if UNIVERSAL::isa($obj, 'PDFJ::Block');
			}
		}
		my @indents;
		if( $align =~ /m/ ) {
			for( my $j = 0; $j < $objnum; $j++ ) {
				my $obj = $self->{objects}->[$j];
				if( UNIVERSAL::isa($obj, 'PDFJ::Showable') ) {
					$indents[$j] = ($height - $obj->height) / 2;
				}
			}
		} elsif( $align =~ /b/ ) {
			for( my $j = 0; $j < $objnum; $j++ ) {
				my $obj = $self->{objects}->[$j];
				if( UNIVERSAL::isa($obj, 'PDFJ::Showable') ) {
					$indents[$j] = $height - $obj->height;
				}
			}
		}
		$self->{indents} = \@indents;
	}
	$self->{width} = $width;
	$self->{height} = $height;
}

sub padding { $_[0]->{style}{padding} || 0 }

sub width { 
	my($self) = @_;
	$self->{width} + $self->padding * 2 
		+ $self->{xpreshift} + $self->{xpostshift} 
		+ ($self->direction eq 'H' ? 0 : $self->beginpadding);
}
sub height {
	my($self) = @_;
	$self->{height} + $self->padding * 2 
		+ $self->{ypreshift} + $self->{ypostshift}
		+ ($self->direction eq 'H' ? $self->beginpadding : 0);
}
sub size {
	my($self, $direction) = @_; 
	if( $direction eq 'H' ) {
		$self->width;
	} else {
		$self->height;
	}
}
sub left { 0 }
sub right { $_[0]->width }
sub top { 0 }
sub bottom { - $_[0]->height }
sub preskip { $_[0]->{style}{preskip} || 0 }
sub postskip { $_[0]->{style}{postskip} || 0 }
sub align { $_[0]->{style}{align} || "" }
sub nobreak { $_[0]->{style}{nobreak} }
sub postnobreak { $_[0]->{style}{postnobreak} }
sub repeatheader { $_[0]->{style}{repeatheader} || 0 }
sub float { $_[0]->{style}->{float} || "" }
sub nofirstfloat { $_[0]->{style}{nofirstfloat} }
sub beginpadding { $_[0]->{style}{beginpadding} || 0 }
sub direction { $_[0]->{direction} }
sub breakable {
	my($self, $blockdirection) = @_;
	$self->nobreak ? 0 :
		$blockdirection eq $self->{direction} ? 1 :
		0;
}

sub adjustwidth {
	my($self, $size) = @_;
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
	my($self, $size) = @_;
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

sub _show {
	my($self, $page, $x, $y) = @_;
	if( $self->direction eq 'H' ) {
		$y -= $self->beginpadding;
	} else {
		$x += $self->beginpadding;
	}
	my $style = $self->{style};
	if( $style->{withbox} ) {
		my $withbox = $style->{withbox};
		my $withboxstyle = $style->{withboxstyle};
		my $shape = PDFJ::Shape->new;
		$shape->box(0, 0, $self->width, - $self->height, $withbox, 
			$withboxstyle);
		$shape->show($page, $x, $y);
	}
	$x += $self->padding + $self->{xpreshift};
	$y -= $self->padding + $self->{ypreshift};
	my $objnum = @{$self->{objects}};
	if( $self->{direction} eq 'V' ) {
		for( my $j = 0; $j < $objnum; $j++ ) {
			my $obj = $self->{objects}->[$j];
			my $indent = $self->{indents}->[$j] || 0;
			if( $j > 0 ) {
				$y -= $self->{objects}->[$j-1]->postskip + $obj->preskip;
			}
			if( UNIVERSAL::isa($obj, 'PDFJ::Showable') ) {
				$obj->show($page, $x + $indent, $y, 'tl');
				$y -= $obj->height;
			} elsif( UNIVERSAL::isa($obj, 'PDFJ::BlockElement') ) {
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
				$x += $self->{objects}->[$j-1]->postskip + $obj->preskip;
			}
			if( UNIVERSAL::isa($obj, 'PDFJ::Showable') ) {
				$obj->show($page, $x, $y - $indent, 'tl');
				$x += $obj->width;
			} elsif( UNIVERSAL::isa($obj, 'PDFJ::BlockElement') ) {
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
				$x -= $self->{objects}->[$j-1]->postskip + $obj->preskip;
			}
			if( UNIVERSAL::isa($obj, 'PDFJ::Showable') ) {
				$obj->show($page, $x, $y - $indent, 'tr');
				$x -= $obj->width;
			} elsif( UNIVERSAL::isa($obj, 'PDFJ::BlockElement') ) {
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
		$colorspace) = @_;
	my($ext) = $src =~ /([^\.]+)$/;
#	croak "unknown image file extention: $ext" 
#		unless $ext =~ /^jpe?g$/i;
	if( $src =~ /^http:/i ) {
		new_url($class, $docobj, $src, $pxwidth, $pxheight, $width, 
			$height, $padding, $colorspace);
	} else {
		new_file($class, $docobj, $src, $pxwidth, $pxheight, $width, 
			$height, $padding, $colorspace);
	}
}

sub new_url {
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

sub new_file {
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

sub _show {
	my($self, $page, $x, $y) = @_;
	$x += $self->padding;
	$y += $self->padding;
	my $width = $self->{width};
	my $height = $self->{height};
	my $name = $self->{name};
	$page->addcontents("q $width 0 0 $height $x $y cm /$name Do Q");
	$page->useimage($self);
}

#--------------------------------------------------------------------------
package PDFJ::Color;
use Carp;
use strict;

sub Color { PDFJ::Color->new(@_) }

sub new {
	my $class = shift;
	my $self;
	if( @_ == 1 ) {
		my $value = $_[0];
		if( $value =~ /^#([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})$/ ) {
			my(@rgb) = map {oct("0x$_")/256} ($1,$2,$3);
			$self = bless { type => 'rgb', value => \@rgb }, $class;
		} else {
			$self = bless { type => 'gray', value => $value }, $class;
		}
	} elsif( @_ == 3 ) {
		my @rgb = @_;
		$self = bless { type => 'rgb', value => \@rgb }, $class;
	} else {
		croak "Color arguments must be one or three";
	}
	$self;
}

sub fill {
	my($self) = @_;
	if( $self->{type} eq 'gray' ) {
		"$self->{value} g ";
	} else { # 'rgb'
		my @rgb = @{$self->{value}};
		"@rgb rg ";
	}
}

sub stroke {
	my($self) = @_;
	if( $self->{type} eq 'gray' ) {
		"$self->{value} G ";
	} else { # 'rgb'
		my @rgb = @{$self->{value}};
		"@rgb RG ";
	}
}

#--------------------------------------------------------------------------
package PDFJ::ShapeStyle;
use strict;
use Carp;
use vars qw(@ISA);
@ISA = qw(PDFJ::Style);

sub SStyle { PDFJ::ShapeStyle->new(@_) }

sub pdf {
	my($self) = @_;
	my $result = "";
	$result .= $self->{fillcolor}->fill if $self->{fillcolor};
	$result .= $self->{strokecolor}->stroke if $self->{strokecolor};
	$result .= "$self->{linewidth} w " if $self->{linewidth};
	if( $self->{linedash} ) {
		my($dash, $gap, $phase) = @{$self->{linedash}};
		$phase ||= 0;
		$result .= "[$dash $gap] $phase d ";
	}
	$result;
}

#--------------------------------------------------------------------------
package PDFJ::Shape;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Showable);

sub Shape { PDFJ::Shape->new(@_) }

sub new {
	my($class, $style) = @_;
	my $self = bless 
		{ left => 0, top => 0, right => 0, bottom => 0, pdf => "" }, $class;
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
sub pdf { $_[0]->{pdf} }

sub size {
	my($self, $direction) = @_; 
	$direction eq 'H' ? $self->width : $self->height;
}

sub setboundary {
	my($self, $x, $y) = @_;
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
}

sub appendpdf {
	my($self, $pdf) = @_;
	$pdf .= " " unless $pdf =~ / $/;
	$self->{pdf} .= $pdf;
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

sub _show {
	my($self, $page, $x, $y) = @_;
	$x += $self->padding;
	$y += $self->padding;
	my $stylepdf = "";
	if( $self->{style} ) {
		$stylepdf = $self->{style}->pdf if UNIVERSAL::can($self->{style}, 'pdf');
	}
	$page->addcontents("q 1 0 0 1 $x $y cm $stylepdf $self->{pdf}");
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
	croak "shape style argument must be a PDFJ::ShapeStyle object"
		unless UNIVERSAL::isa($style, 'PDFJ::ShapeStyle');
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
	$self->appendpdf("$w w");
}

sub linedash {
	my($self, $dash, $gap, $phase) = @_;
	$phase ||= 0;
	$self->appendpdf("[$dash $gap] $phase d");
}

sub ctm {
	my($self, @array) = @_;
	croak "ctm array must have 6 elements" unless @array == 6;
	$self->appendpdf("@array cm");
}

# Color operators

sub fillcolor {
	my($self, $color) = @_;
	croak "color argument must be a PDFJ::Color object"
		unless UNIVERSAL::isa($color, 'PDFJ::Color');
	$self->appendpdf($color->fill);
}

sub strokecolor {
	my($self, $color) = @_;
	croak "color argument must be a PDFJ::Color object"
		unless UNIVERSAL::isa($color, 'PDFJ::Color');
	$self->appendpdf($color->stroke);
}

sub fillgray {
	my($self, $g) = @_;
	$self->appendpdf("$g g");
}

sub strokegray {
	my($self, $g) = @_;
	$self->appendpdf("$g G");
}

sub fillrgb {
	my($self, $r, $g, $b) = @_;
	$self->appendpdf("$r $g $b rg");
}

sub strokergb {
	my($self, $r, $g, $b) = @_;
	$self->appendpdf("$r $g $b RG");
}

# Path segment operators

# moves the current point to (x, y), omitting any connecting line segment
sub moveto {
	my($self, $x, $y) = @_;
	$self->setboundary($x, $y);
	$self->appendpdf("$x $y m");
}

# appends a straight line segment from the current point to (x, y).
# The current point becomes (x, y).
sub lineto {
	my($self, $x, $y) = @_;
	$self->setboundary($x, $y);
	$self->appendpdf("$x $y l");
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
	$self->appendpdf("$x1 $y1 $x2 $y2 $x3 $y3 c");
}

# omit 'v' and 'y'

# adds a rectangle to the current path
sub rectangle {
	my($self, $x, $y, $w, $h) = @_;
	$self->setboundary($x, $y);
	$self->setboundary($x + $w, $y + $h);
	$self->appendpdf("$x $y $w $h re");
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

# fills the path using the even-odd rule
sub fill2 {
	my $self = shift;
	$self->appendpdf("f*");
}

# Path macro

sub line {
	my($self, $x, $y, $w, $h, $style) = @_;
	my $stylepdf;
	$stylepdf = $style->pdf if $style;
	my($x1, $y1, $x2, $y2) = ($x, $y, $x + $w, $y + $h);
	$self->setboundary($x1, $y1);
	$self->setboundary($x2, $y2);
	$self->appendpdf("q $stylepdf") if $stylepdf;
	$self->appendpdf("$x1 $y1 m $x2 $y2 l S");
	$self->appendpdf("Q") if $stylepdf;
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
	my($self, $x, $y, $w, $h, $spec, $style) = @_;
	$spec = "s" unless $spec;
	my $stylepdf;
	$stylepdf = $style->pdf if $style;
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
		$self->appendpdf("q $stylepdf") if $stylepdf;
		if( $r ) {
			my $bz = $r * 0.55228475;
			my @work = (
				$x+$w,        $y+$h-$r,      'm',
				$x+$w,        $y+$h-$r+$bz,
				$x+$w-$r+$bz, $y+$h,
				$x+$w-$r,     $y+$h,         'c',
				$x+$r,        $y+$h,         'l',
				$x+$r-$bz,    $y+$h,
				$x,           $y+$h-$r+$bz,
				$x,           $y+$h-$r,      'c',
				$x,           $y+$r,         'l',
				$x,           $y+$r-$bz,
				$x+$r-$bz,    $y,
				$x+$r,        $y,            'c',
				$x+$w-$r,     $y,            'l',
				$x+$w-$r+$bz, $y,
				$x+$w,        $y+$r-$bz,
				$x+$w,        $y+$r,         'c',
				$x+$w,        $y+$h-$r,      'l'
			);
			$self->appendpdf("@work ");
		} else {
			$self->appendpdf("$x $y m $x $y $w $h re ");
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
		$self->appendpdf("Q") if $stylepdf;
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
	my($self, $x, $y, $r, $spec, $arcarea, $style) = @_;
	$self->ellipse($x, $y, $r, $r, $spec, $arcarea, $style);
}

sub ellipse {
	my($self, $x, $y, $xr, $yr, $spec, $arcarea, $style) = @_;
	$spec = "s" unless $spec;
	my $stylepdf;
	$stylepdf = $style->pdf if $style;
	$self->appendpdf("q $stylepdf") if $stylepdf;
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
		$self->appendpdf(join(' ',splice(@pt, $arcarea * 6, 2))." m ");
		$self->appendpdf(join(' ',splice(@pt, $arcarea * 6, 6))." c ");
	} else {
		$self->setboundary($x - $xr, $y - $yr);
		$self->setboundary($x + $xr, $y + $yr);
		$self->appendpdf(join(' ',splice(@pt, 0, 2))." m ");
		$self->appendpdf(join(' ',splice(@pt, 0, 6))." c ");
		$self->appendpdf(join(' ',splice(@pt, 0, 6))." c ");
		$self->appendpdf(join(' ',splice(@pt, 0, 6))." c ");
		$self->appendpdf(join(' ',splice(@pt, 0, 6))." c ");
	}
	if( $spec eq 'sf' ) {
		$self->appendpdf("B");
	} elsif( $spec eq 's' ) {
		$self->appendpdf("S");
	} elsif( $spec eq 'f' ) {
		$self->appendpdf("f");
	}
	$self->appendpdf("Q") if $stylepdf;
	$self;
}

sub polygon {
	my($self, $coords, $spec, $style) = @_;
	croak "coords argument must be an array ref"
		unless ref($coords) eq 'ARRAY';
	croak "coords argument must have even elements"
		if @$coords % 2;
	my @work;
	for( my $j = 0; $j < @$coords; $j += 2 ) {
		push @work, $coords->[$j], $coords->[$j + 1];
		push @work, ($j == 0) ? 'm' : 'l';
	}
	my $stylepdf;
	$stylepdf = $style->pdf if $style;
	$self->appendpdf("q $stylepdf") if $stylepdf;
	$self->appendpdf("@work ");
	if( $spec eq 'sf' ) {
		$self->appendpdf("B");
	} elsif( $spec eq 's' ) {
		$self->appendpdf("S");
	} elsif( $spec eq 'f' ) {
		$self->appendpdf("f");
	}
	$self->appendpdf("Q") if $stylepdf;
	$self;
}

sub obj {
	my($self, $obj, @showargs) = @_;
	$self->appendobj($obj, @showargs);
	$self;
}

#--------------------------------------------------------------------------
package PDFJ::Page;
use Carp;
use strict;
use PDFJ::Object;

sub new {
	my($class, $docobj, $pagewidth, $pageheight) = @_;
	my $pagetree = $docobj->{pagetree};
	$pagewidth ||= $docobj->{pagewidth};
	$pageheight ||= $docobj->{pageheight};
	my $page = $docobj->indirect(dictionary({
		Type => name('Page'),
		Parent => $pagetree,
		Resources => {ProcSet => [name('PDF'), name('Text')], Font => {}},
		MediaBox => [0, 0, $pagewidth, $pageheight],
		Contents => $docobj->indirect(
			contents_stream(dictionary => {}, stream => [])),
		}));
	push @{$docobj->{pagelist}}, $page;
	my $pagenum = @{$docobj->{pagelist}};
	$pagetree->get('Kids')->push($page);
	$pagetree->get('Count')->add(1);
	my $self = bless {
		page => $page, 
		pagenum => $pagenum,
		parent => $pagetree, 
		docobj => $docobj, 
		layer => 0,
	}, $class;
	push @{$docobj->{pageobjlist}}, $self;
	$self;
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
	my($self, $str) = @_;
	$str .= " " unless $str =~ / $/;
	$self->page->get('Contents')->append($str, $self->getlayer);
}

sub layer {
	my($self, $layer) = @_;
	$self->{layer} = $layer;
	$self;
}

sub usefonts {
	my($self, @names) = @_;
	my $docobj = $self->docobj;
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

sub dest {
	my($self, $argtype, @args) = @_;
	array([$self->page, name($argtype), map {$_ eq '' ? null : $_} @args]);
}

sub add_link {
	my($self, $rect, $name) = @_;
	$self->{link}{join(',', @$rect)} = $name;
}

sub add_annot {
	my($self, %spec) = @_;
	$spec{Type} = name('Annot');
	my $docobj = $self->docobj;
	unless( $self->page->exists('Annots') ) {
		$self->page->set(Annots => []);
	}
	$self->page->get('Annots')->push($docobj->indirect(dictionary(\%spec)));
}

sub solve_link {
	my($self) = @_;
	my $docobj = $self->docobj;
	for my $rect(keys %{$self->{link}}) {
		my $name = $self->{link}{$rect};
		my @rect = split(',', $rect);
		if( $name =~ /^URI:(.+)/ ) {
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
		} else {
			my $dest = $docobj->dest($name)
				or croak "missing dest '$name'";
			$self->add_annot(
				Subtype => name('Link'),
				Rect => [@rect],
				Border => [0,0,0],
				Dest => $dest,
			);
		}
	}
}

#--------------------------------------------------------------------------
package PDFJ::File;
use strict;
use PDFJ::Object;

sub new {
	my($class, $version, $handle, $objtable, $rootobj) = @_;
	binmode $handle;
	bless {
		version => $version,  # PDF version
		handle => $handle,    # file handle
		objtable => $objtable,  # PDFJ::ObjTable object
		rootobj => $rootobj,  # document catalog object
		objposlist => [], 
		xrefpos => 0
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
	print $handle "%PDF-$version\n";
}

sub print_body {
	my $self = shift;
	my $handle = $self->{handle};
	my $objtable = $self->{objtable};
	return unless $objtable->lastobjnum;
	for my $objnum(1 .. $objtable->lastobjnum) {
		$self->{objposlist}->[$objnum] = $handle->tell;
		$objtable->get($objnum)->print($handle);
	}
}

sub print_xref {
	my $self = shift;
	my $handle = $self->{handle};
	$self->{xrefpos} = $handle->tell;
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
	print $handle "trailer\n", $traildic->output, 
		"\nstartxref\n$xrefpos\n%%EOF\n";
}

#--------------------------------------------------------------------------
package PDFJ::ObjTable;
use strict;

sub new {
	my($class) = @_;
	bless {objlist => [undef]}, $class;
}

sub lastobjnum {
	my $self = shift;
	$#{$self->{objlist}};
}

sub get {
	my($self, $idx) = @_;
	$self->{objlist}->[$idx];
}

sub set {
	my($self, $idx, $obj) = @_;
	$self->{objlist}->[$idx] = $obj;
}

1;
#--------------------------------------------------------------------------
# for SelfLoader in PDFJ::AFont
package PDFJ::AFont;
__DATA__
sub fontwidth_Courier { [
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600
] }
sub fontwidth_Courier_Bold { [
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600
] }
sub fontwidth_Courier_BoldOblique { [
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600
] }
sub fontwidth_Courier_Oblique { [
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600,  600,  600,  600,  600,  600,  600,  600,  600,
	600,  600,  600
] }
sub fontwidth_Helvetica { [
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  355,  556,  556,  889,  667,  221,  333,  333,  389,  584,
	278,  333,  278,  278,  556,  556,  556,  556,  556,  556,  556,
	556,  556,  556,  278,  278,  584,  584,  584,  556, 1015,  667,
	667,  722,  722,  667,  611,  778,  722,  278,  500,  667,  556,
	833,  722,  778,  667,  778,  722,  667,  611,  722,  667,  944,
	667,  667,  611,  278,  278,  278,  469,  556,  222,  556,  556,
	500,  556,  556,  278,  556,  556,  222,  222,  500,  222,  833,
	556,  556,  556,  556,  333,  500,  278,  556,  500,  722,  500,
	500,  500,  334,  260,  334,  584,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  333,  556,  556,  167,
	556,  556,  556,  556,  191,  333,  556,  333,  333,  500,  500,
	278,  556,  556,  556,  278,  278,  537,  350,  222,  333,  333,
	556, 1000, 1000,  278,  611,  278,  333,  333,  333,  333,  333,
	333,  333,  333,  278,  333,  333,  278,  333,  333,  333, 1000,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278, 1000,  278,  370,  278,  278,  278,
	278,  556,  778, 1000,  365,  278,  278,  278,  278,  278,  889,
	278,  278,  278,  278,  278,  278,  222,  611,  944,  611,  278,
	278,  278,  278
] }
sub fontwidth_Helvetica_Bold { [
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	333,  474,  556,  556,  889,  722,  278,  333,  333,  389,  584,
	278,  333,  278,  278,  556,  556,  556,  556,  556,  556,  556,
	556,  556,  556,  333,  333,  584,  584,  584,  611,  975,  722,
	722,  722,  722,  667,  611,  778,  722,  278,  556,  722,  611,
	833,  722,  778,  667,  778,  722,  667,  611,  722,  667,  944,
	667,  667,  611,  333,  278,  333,  584,  556,  278,  556,  611,
	556,  611,  556,  333,  611,  611,  278,  278,  556,  278,  889,
	611,  611,  611,  611,  389,  556,  333,  611,  556,  778,  556,
	556,  500,  389,  280,  389,  584,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  333,  556,  556,  167,
	556,  556,  556,  556,  238,  500,  556,  333,  333,  611,  611,
	278,  556,  556,  556,  278,  278,  556,  350,  278,  500,  500,
	556, 1000, 1000,  278,  611,  278,  333,  333,  333,  333,  333,
	333,  333,  333,  278,  333,  333,  278,  333,  333,  333, 1000,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278, 1000,  278,  370,  278,  278,  278,
	278,  611,  778, 1000,  365,  278,  278,  278,  278,  278,  889,
	278,  278,  278,  278,  278,  278,  278,  611,  944,  611,  278,
	278,  278,  278
] }
sub fontwidth_Helvetica_BoldOblique { [
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	333,  474,  556,  556,  889,  722,  278,  333,  333,  389,  584,
	278,  333,  278,  278,  556,  556,  556,  556,  556,  556,  556,
	556,  556,  556,  333,  333,  584,  584,  584,  611,  975,  722,
	722,  722,  722,  667,  611,  778,  722,  278,  556,  722,  611,
	833,  722,  778,  667,  778,  722,  667,  611,  722,  667,  944,
	667,  667,  611,  333,  278,  333,  584,  556,  278,  556,  611,
	556,  611,  556,  333,  611,  611,  278,  278,  556,  278,  889,
	611,  611,  611,  611,  389,  556,  333,  611,  556,  778,  556,
	556,  500,  389,  280,  389,  584,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  333,  556,  556,  167,
	556,  556,  556,  556,  238,  500,  556,  333,  333,  611,  611,
	278,  556,  556,  556,  278,  278,  556,  350,  278,  500,  500,
	556, 1000, 1000,  278,  611,  278,  333,  333,  333,  333,  333,
	333,  333,  333,  278,  333,  333,  278,  333,  333,  333, 1000,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278, 1000,  278,  370,  278,  278,  278,
	278,  611,  778, 1000,  365,  278,  278,  278,  278,  278,  889,
	278,  278,  278,  278,  278,  278,  278,  611,  944,  611,  278,
	278,  278,  278
] }
sub fontwidth_Helvetica_Oblique { [
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  355,  556,  556,  889,  667,  222,  333,  333,  389,  584,
	278,  333,  278,  278,  556,  556,  556,  556,  556,  556,  556,
	556,  556,  556,  278,  278,  584,  584,  584,  556, 1015,  667,
	667,  722,  722,  667,  611,  778,  722,  278,  500,  667,  556,
	833,  722,  778,  667,  778,  722,  667,  611,  722,  667,  944,
	667,  667,  611,  278,  278,  278,  469,  556,  222,  556,  556,
	500,  556,  556,  278,  556,  556,  222,  222,  500,  222,  833,
	556,  556,  556,  556,  333,  500,  278,  556,  500,  722,  500,
	500,  500,  334,  260,  334,  584,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278,  278,  278,  333,  556,  556,  167,
	556,  556,  556,  556,  191,  333,  556,  333,  333,  500,  500,
	278,  556,  556,  556,  278,  278,  537,  350,  222,  333,  333,
	556, 1000, 1000,  278,  611,  278,  333,  333,  333,  333,  333,
	333,  333,  333,  278,  333,  333,  278,  333,  333,  333, 1000,
	278,  278,  278,  278,  278,  278,  278,  278,  278,  278,  278,
	278,  278,  278,  278,  278, 1000,  278,  370,  278,  278,  278,
	278,  556,  778, 1000,  365,  278,  278,  278,  278,  278,  889,
	278,  278,  278,  278,  278,  278,  222,  611,  944,  611,  278,
	278,  278,  278
] }
# The chracter #39 (single quote) in Times-* fonts has 333 width
# in afm files. But Acrobat uses a width nallower than it. I use an 
# experimental value 222.
sub fontwidth_Times_Bold { [
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
#	333,  555,  500,  500, 1000,  833,  333,  333,  333,  500,  570,
	333,  555,  500,  500, 1000,  833,  222,  333,  333,  500,  570,
	250,  333,  250,  278,  500,  500,  500,  500,  500,  500,  500,
	500,  500,  500,  333,  333,  570,  570,  570,  500,  930,  722,
	667,  722,  722,  667,  611,  778,  778,  389,  500,  778,  667,
	944,  722,  778,  611,  778,  722,  556,  667,  722,  722, 1000,
	722,  722,  667,  333,  278,  333,  581,  500,  333,  500,  556,
	444,  556,  444,  333,  500,  556,  278,  333,  556,  278,  833,
	556,  500,  556,  556,  444,  389,  333,  556,  500,  722,  500,
	500,  444,  394,  220,  394,  520,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  333,  500,  500,  167,
	500,  500,  500,  500,  278,  500,  500,  333,  333,  556,  556,
	250,  500,  500,  500,  250,  250,  540,  350,  333,  500,  500,
	500, 1000, 1000,  250,  500,  250,  333,  333,  333,  333,  333,
	333,  333,  333,  250,  333,  333,  250,  333,  333,  333, 1000,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250, 1000,  250,  300,  250,  250,  250,
	250,  667,  778, 1000,  330,  250,  250,  250,  250,  250,  722,
	250,  250,  250,  278,  250,  250,  278,  500,  722,  556,  250,
	250,  250,  250
] }
sub fontwidth_Times_BoldItalic { [
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
#	389,  555,  500,  500,  833,  778,  333,  333,  333,  500,  570,
	389,  555,  500,  500,  833,  778,  222,  333,  333,  500,  570,
	250,  333,  250,  278,  500,  500,  500,  500,  500,  500,  500,
	500,  500,  500,  333,  333,  570,  570,  570,  500,  832,  667,
	667,  667,  722,  667,  667,  722,  778,  389,  500,  667,  611,
	889,  722,  722,  611,  722,  667,  556,  611,  722,  667,  889,
	667,  611,  611,  333,  278,  333,  570,  500,  333,  500,  500,
	444,  500,  444,  333,  500,  556,  278,  278,  500,  278,  778,
	556,  500,  500,  500,  389,  389,  278,  556,  444,  667,  500,
	444,  389,  348,  220,  348,  570,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  389,  500,  500,  167,
	500,  500,  500,  500,  278,  500,  500,  333,  333,  556,  556,
	250,  500,  500,  500,  250,  250,  500,  350,  333,  500,  500,
	500, 1000, 1000,  250,  500,  250,  333,  333,  333,  333,  333,
	333,  333,  333,  250,  333,  333,  250,  333,  333,  333, 1000,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  944,  250,  266,  250,  250,  250,
	250,  611,  722,  944,  300,  250,  250,  250,  250,  250,  722,
	250,  250,  250,  278,  250,  250,  278,  500,  722,  500,  250,
	250,  250,  250
] }
sub fontwidth_Times_Italic { [
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
#	333,  420,  500,  500,  833,  778,  333,  333,  333,  500,  675,
	333,  420,  500,  500,  833,  778,  222,  333,  333,  500,  675,
	250,  333,  250,  278,  500,  500,  500,  500,  500,  500,  500,
	500,  500,  500,  333,  333,  675,  675,  675,  500,  920,  611,
	611,  667,  722,  611,  611,  722,  722,  333,  444,  667,  556,
	833,  667,  722,  611,  722,  611,  500,  556,  722,  611,  833,
	611,  556,  556,  389,  278,  389,  422,  500,  333,  500,  500,
	444,  500,  444,  278,  500,  500,  278,  278,  444,  278,  722,
	500,  500,  500,  500,  389,  389,  278,  500,  444,  667,  444,
	444,  389,  400,  275,  400,  541,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  389,  500,  500,  167,
	500,  500,  500,  500,  214,  556,  500,  333,  333,  500,  500,
	250,  500,  500,  500,  250,  250,  523,  350,  333,  556,  556,
	500,  889, 1000,  250,  500,  250,  333,  333,  333,  333,  333,
	333,  333,  333,  250,  333,  333,  250,  333,  333,  333,  889,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  889,  250,  276,  250,  250,  250,
	250,  556,  722,  944,  310,  250,  250,  250,  250,  250,  667,
	250,  250,  250,  278,  250,  250,  278,  500,  667,  500,  250,
	250,  250,  250
] }
sub fontwidth_Times_Roman { [
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
#	333,  408,  500,  500,  833,  778,  333,  333,  333,  500,  564,
	333,  408,  500,  500,  833,  778,  222,  333,  333,  500,  564,
	250,  333,  250,  278,  500,  500,  500,  500,  500,  500,  500,
	500,  500,  500,  278,  278,  564,  564,  564,  444,  921,  722,
	667,  667,  722,  611,  556,  722,  722,  333,  389,  722,  611,
	889,  722,  722,  556,  722,  667,  556,  611,  722,  722,  944,
	722,  722,  611,  333,  278,  333,  469,  500,  333,  444,  500,
	444,  500,  444,  333,  500,  500,  278,  278,  500,  278,  778,
	500,  500,  500,  500,  333,  389,  278,  500,  500,  722,  500,
	500,  444,  480,  200,  480,  541,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  250,  250,  333,  500,  500,  167,
	500,  500,  500,  500,  180,  444,  500,  333,  333,  556,  556,
	250,  500,  500,  500,  250,  250,  453,  350,  333,  444,  444,
	500, 1000, 1000,  250,  444,  250,  333,  333,  333,  333,  333,
	333,  333,  333,  250,  333,  333,  250,  333,  333,  333, 1000,
	250,  250,  250,  250,  250,  250,  250,  250,  250,  250,  250,
	250,  250,  250,  250,  250,  889,  250,  276,  250,  250,  250,
	250,  611,  722,  889,  310,  250,  250,  250,  250,  250,  667,
	250,  250,  250,  278,  250,  250,  278,  500,  722,  500,  250,
	250,  250,  250
] }

