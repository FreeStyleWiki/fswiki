# PDFJ/Form.pm - Form field support
# 2006 nakajima@netstock.co.jp
package PDFJ::Form;
use PDFJ::Object;
use Carp;
use strict;

# utility subroutines

my %FieldFlag = (
	ReadOnly =>       1,
	Required =>       2,
	NoExport =>       3,
	Multiline =>     13,
	Password =>      14,
	NoToggleToOff => 15,
	Radio =>         16,
	Pushbutton =>    17,
	Combo =>         18,
	Edit =>          19,
	Sort =>          20,
	FileSelect =>    21,	# PDF 1.4
	MultiSelect =>   22,	# PDF 1.4
	DoNotSpellCheck => 23,	# PDF 1.4
	DoNotScroll =>   24,	# PDF 1.4
	Comb =>          25,	# PDF 1.5
	RichText =>      26,	# PDF 1.5
	RadiosInUnison => 26,	# PDF 1.5
	CommitOnSelChange => 27,	# PDF 1.5
);

sub fieldflag {
	my(%hash) = @_;
	my $ff = 0;
	for my $name(keys %hash) {
		croak "unknown field flag: $name" unless $FieldFlag{$name};
		$ff |= 1 << ($FieldFlag{$name} - 1) if $hash{$name};
	}
	$ff;
}

sub setcommonflag {
	my($hash, $spec) = @_;
	$hash->{ReadOnly} = 1 if $spec->{readonly};
	$hash->{Required} = 1 if $spec->{required};
	$hash->{NoExport} = 1 if $spec->{noexport};
}

sub anotflag {
	my($spec) = @_;
	my $f = 0;
	$f |= 2 if $spec->{hidden};
	$f |= 4 unless $spec->{noprint};
	$f;
}

sub framespec {
	my($spec, $fillgrey) = @_;
	my $fwidth = $spec->{framewidth} || 1;
	my $c_light = PDFJ::Color->new($spec->{lightcolor} || 0.9);
	my $c_medium = PDFJ::Color->new($spec->{mediumcolor} || 0.75);
	my $c_dark = PDFJ::Color->new($spec->{darkcolor} || 0.6);
	my $c_fill = PDFJ::Color->new($spec->{fillcolor} || ($fillgrey ? 0.8 : 1));
	($fwidth, $c_light, $c_medium, $c_dark, $c_fill);
}

sub makeframe {
	my($shape, $left, $bottom, $width, $height, $framewidth, 
		$color_tl, $color_br, $color_fill) = @_;
	my $right = $left + $width;
	my $top = $bottom + $height;
	if( $framewidth ) {
		$shape
		->polygon([$left, $bottom, $left, $top, $right, $top, 
		$right - $framewidth, $top - $framewidth,
		$left + $framewidth, $top - $framewidth, 
		$left + $framewidth, $bottom + $framewidth], 'f', 
		PDFJ::ShapeStyle->new(fillcolor => $color_tl))
		->polygon([$left, $bottom, $right, $bottom, $right, $top, 
		$right - $framewidth, $top - $framewidth,
		$right - $framewidth, $bottom + $framewidth, 
		$left + $framewidth, $bottom + $framewidth], 'f', 
		PDFJ::ShapeStyle->new(fillcolor => $color_br));
	}
	$shape->box($left + $framewidth, $bottom + $framewidth, 
		$width - $framewidth * 2, $height - $framewidth * 2, 'f', 
		PDFJ::ShapeStyle->new(fillcolor => $color_fill));
}

sub makecircleframe {
	my($shape, $x, $y, $r, $framewidth, $color1, $color2, $color3, 
		$color_fill) = @_;
	if( $framewidth ) {
		$shape
		->circle($x, $y, $r, 'f', 2,
		PDFJ::ShapeStyle->new(fillcolor => $color1))
		->circle($x, $y, $r, 'f', 1,
		PDFJ::ShapeStyle->new(fillcolor => $color2))
		->circle($x, $y, $r, 'f', 3,
		PDFJ::ShapeStyle->new(fillcolor => $color2))
		->circle($x, $y, $r, 'f', 4,
		PDFJ::ShapeStyle->new(fillcolor => $color3));
	}
	$shape->circle($x, $y, $r - $framewidth, 'f', undef,
		PDFJ::ShapeStyle->new(fillcolor => $color_fill));
}

sub makefieldobj {
	my($docobj, %dict) = @_;
	$dict{Type} = name('Annot');
	$dict{Subtype} = name('Widget');
	$dict{TU} = $dict{T} if $dict{TU} eq '' && $dict{T} ne '';
	$dict{TM} = $dict{T} if $dict{TM} eq '' && $dict{T} ne '';
	$docobj->indirect(dictionary(\%dict));
}

#-------------------
package PDFJ::Doc;
use Carp;
use strict;
use PDFJ::Object;

sub new_field {
	my($self, @spec) = @_;
	my %spec;
	if( @spec == 1 && ref($spec[0]) eq 'HASH' ) {
		%spec = %{$spec[0]};
	} else {
		%spec = @spec;
	}
	my $type = $spec{type};
	croak "missing field type" if $type eq '';
	"PDFJ::Field::$type"->new($self, \%spec);
}

sub add_field {
	my($self, $fieldobj) = @_;
	croak "cannot add child field into AcroForm Fields"
		if $fieldobj->{Parent};
	$self->{catalog}->
		set(AcroForm => dictionary({Fields => [], DR => {Font => {}}}))
		unless $self->{catalog}->exists('AcroForm');
	$self->{catalog}->get('AcroForm')->get('Fields')->add($fieldobj);
	if( $fieldobj->exists('DR') && $fieldobj->get('DR')->exists('Font') ) {
		my $formfd = $self->{catalog}->get('AcroForm')->get('DR')->get('Font');
		my $fieldfd = $fieldobj->get('DR')->get('Font');
		for my $fn($fieldfd->keys) {
			$formfd->set($fn => $fieldfd->get($fn));
		}
	}
}

#-------------------
package PDFJ::Page;
use Carp;
use strict;

sub add_field {
	my($self, $fieldobj) = @_;
	unless( $self->page->exists('Annots') ) {
		$self->page->set(Annots => []);
	}
	$self->page->get('Annots')->push($fieldobj);
	$self->docobj->add_field($fieldobj) unless $fieldobj->{Parent};
}

#-------------------
package PDFJ::Field;
use Carp;
use strict;
use PDFJ::Object;
use vars qw(@ISA);
@ISA = qw(PDFJ::Showable);

sub width { $_[0]->{width} }
sub height { $_[0]->{height} }
sub left { 0 }
sub right { $_[0]->width }
sub top { $_[0]->height }
sub bottom { 0 }

sub size {
	my($self, $direction) = @_; 
	$direction eq 'H' ? $self->width : $self->height;
}

sub onshow {}

sub _show {
	my($self, $page, $x, $y) = @_;
	my $fieldobj = $self->{fieldobj};
	if( $fieldobj->exists('Rect') ) {
		my $rect = $fieldobj->get('Rect');
		$rect->set(0, $x);
		$rect->set(1, $y);
		$rect->set(2, $x + $self->{width});
		$rect->set(3, $y + $self->{height});
	}
	$page->add_field($fieldobj);
}

#-------------------
package PDFJ::Field::Text;
use Carp;
use strict;
use PDFJ::Object;
use vars qw(@ISA);
@ISA = qw(PDFJ::Field);

sub new {
	my($class, $docobj, $spec) = @_;
	my $type = $spec->{type};
	my($name, $width, $height, $font, $fontsize) = map 
		{$spec->{$_} or croak "missing $_ spec for $type field"}
		qw(name width height font fontsize);
	my $fname = $font->{name} || $font->{zname};
	my $f = PDFJ::Form::anotflag($spec);
	my %ff;
	PDFJ::Form::setcommonflag(\%ff, $spec);
	$ff{Multiline} = 1 if $spec->{multiline};
	$ff{Password} = 1 if $spec->{password};
	$ff{FileSelect} = $spec->{fileselect};
	$ff{DoNotSpellCheck} = $spec->{donotspellcheck};
	$ff{DoNotScroll} = $spec->{donotscroll};
	$ff{Comb} = $spec->{comb};
	my $ff = PDFJ::Form::fieldflag(%ff);
	my($fwidth, $c_light, $c_medium, $c_dark, $c_fill) = 
		PDFJ::Form::framespec($spec);
	my $mp = $docobj->new_minipage($width, $height);
	my $shape = PDFJ::Shape->new;
	PDFJ::Form::makeframe($shape, 0, 0, $width, $height, $fwidth, $c_dark, 
		$c_light, $c_fill);
	$shape->show($mp, 0, 0);
	my $value = $spec->{value};
	if( $value ne '' ) {
		$mp->addcontents("/Tx BMC ");
		my $text = PDFJ::Text->new($value, PDFJ::TextStyle->new(font => $font, 
		fontsize => $fontsize));
		$text->show($mp, 0, $height / 2, ($spec->{multiline} ? 'tl' : 'ml'));
		$mp->addcontents("EMC ");
	}
	my %dict = (
		FT => name('Tx'),
		T  => textstring($name),
		F  => $f,
		Ff => $ff,
		Rect => [0, 0, $width, $height],
		DA => string("/$fname $fontsize Tf 0 g"),
		DR => dictionary({Font => dictionary(
			{$fname => $docobj->_font($fname)})}),
		AP => dictionary({N => $mp->xobject}),
		V => textstring($value),
		DV => textstring($value),
		MK => dictionary({BC => [$c_light->numarray], 
			BG => [$c_fill->numarray]}),
		BS => dictionary({Type => name('Border'), W => $fwidth, 
			S => name('I')}),
		);
	$dict{MaxLen} = $spec->{maxlen} if $spec->{maxlen};
	my $self = 
		bless {name => $name, width => $width, height => $height}, $class;
	$self->{fieldobj} = PDFJ::Form::makefieldobj($docobj, %dict);
	$self;
}

#-------------------
package PDFJ::Field::Button;
use Carp;
use strict;
use PDFJ::Object;
use vars qw(@ISA);
@ISA = qw(PDFJ::Field);

my %ButtonFlag = (
	Include_Exclude => 1,
	IncludeNoValueFields => 2,
	ExportFormat => 3,
	GetMethod => 4,
	SubmitCoordinates => 5,
);

sub setbuttonflag {
	my($flag, $flagname) = @_;
	$flag |= 1 << ($ButtonFlag{$flagname} - 1);
	$flag;
}

sub new {
	my($class, $docobj, $spec) = @_;
	my $type = $spec->{type};
	my($buttontype, $name, $width, $height, $font, $fontsize, $caption) = map 
		{$spec->{$_} or croak "missing $_ spec for $type field"}
		qw(buttontype name width height font fontsize caption);
	my $fname = $font->{name} || $font->{zname};
	my $action;
	if( $buttontype eq 'Submit' ) {
		my $fields;
		my $flags = 0;
		if( $spec->{url} ) {
			$action = {S => name('SubmitForm'), F => string($spec->{url})};
		} else {
			croak "missing url spec for submit button field";
		}
		$fields = [map {string($_)} @{$spec->{fields}}]
			if $spec->{fields};
		$flags = setbuttonflag($flags, 'Include_Exclude')
			if $spec->{exclude};
		$flags = setbuttonflag($flags, 'IncludeNoValueFields')
			if $spec->{includenovaluefields};
		if( $spec->{format} =~ /^FDF$/i ) { 
			# default
		} elsif( $spec->{format} =~ /^POST$/i ) { 
			$flags = setbuttonflag($flags, 'ExportFormat');
		} elsif( $spec->{format} =~ /^GET$/i ) { 
			$flags = setbuttonflag($flags, 'ExportFormat');
			$flags = setbuttonflag($flags, 'GetMethod');
		}
		if( $spec->{submitcoordinates} ) {
			croak "cannot specify submitcoordinates for FDF"
				if $spec->{format} !~ /^POST$/i && 
				$spec->{format} !~ /^GET$/i;
			$flags = setbuttonflag($flags, 'SubmitCoordinates');
		}
		$action->{Fields} = $fields if $fields;
		$action->{Flags} = $flags if $flags;
	} elsif( $buttontype eq 'Reset' ) {
		my $fields;
		my $flags = 0;
		$action = {S => name('ResetForm')};
		$fields = [map {string($_)} @{$spec->{fields}}]
			if $spec->{fields};
		$flags = setbuttonflag($flags, 'Include_Exclude')
			if $spec->{exclude};
		$action->{Fields} = $fields if $fields;
		$action->{Flags} = $flags if $flags;
	} elsif( $buttontype eq 'Import' ) {
		if( $spec->{file} ) {
			$action = {S => name('ImportData'), F => string($spec->{file})};
		} else {
			croak "missing file spec for submit button field";
		}
	} elsif( $buttontype eq 'JavaScript' ) {
		if( $spec->{javascript} ) {
			$action = {S => name('JavaScript'), JS => string($spec->{javascript})};
		} else {
			croak "missing file spec for submit button field";
		}
	} else {
		croak "unknown buttontype: $buttontype";
	}
	my $f = PDFJ::Form::anotflag($spec);
	my %ff;
	PDFJ::Form::setcommonflag(\%ff, $spec);
	$ff{Pushbutton} = 1;
	my $ff = PDFJ::Form::fieldflag(%ff);
	my($fwidth, $c_light, $c_medium, $c_dark, $c_fill) = 
		PDFJ::Form::framespec($spec, 1);
	my $mp = $docobj->new_minipage($width, $height);
	my $shape = PDFJ::Shape->new;
	PDFJ::Form::makeframe($shape, 0, 0, $width, $height, $fwidth, $c_light, $c_dark, $c_fill);
	$shape->show($mp, 0, 0);
	PDFJ::Text->new($caption, PDFJ::TextStyle->new(font => $font, 
		fontsize => $fontsize))
		->show($mp, $width / 2, $height / 2, 'cm');
	my %dict = (
		FT => name('Btn'),
		T  => textstring($name),
		F  => $f,
		Ff => $ff,
		Rect => [0, 0, $width, $height],
		DA => string("/$fname $fontsize Tf 0 g"),
		DR => dictionary({Font => dictionary(
			{$fname => $docobj->_font($fname)})}),
		AP => dictionary({N => $mp->xobject}),
		A => dictionary($action),
		MK => dictionary({BC => [$c_light->numarray], 
			BG => [$c_fill->numarray], CA => textstring($caption)}),
		BS => dictionary({Type => name('Border'), W => $fwidth, 
			S => name('B')}),
		);
	my $self = 
		bless {name => $name, width => $width, height => $height}, $class;
	$self->{fieldobj} = PDFJ::Form::makefieldobj($docobj, %dict);
	$self;
}

#-------------------
package PDFJ::Field::CheckBox;
use Carp;
use strict;
use PDFJ::Object;
use vars qw(@ISA);
@ISA = qw(PDFJ::Field);

sub new {
	my($class, $docobj, $spec) = @_;
	my $type = $spec->{type};
	my($name, $width, $height, $size) = map 
		{$spec->{$_} or croak "missing $_ spec for $type field"}
		qw(name width height size);
	my $f = PDFJ::Form::anotflag($spec);
	my %ff;
	PDFJ::Form::setcommonflag(\%ff, $spec);
	my $ff = PDFJ::Form::fieldflag(%ff);

	my $left = $width/2 - $size/2;
	my $bottom = $height/2 - $size/2;

	my($fwidth, $c_light, $c_medium, $c_dark, $c_fill) = 
		PDFJ::Form::framespec($spec);
	my $mp_on = $docobj->new_minipage($width, $height);
	my $shape_on = PDFJ::Shape->new;
	PDFJ::Form::makeframe($shape_on, $left, $bottom, $size, $size, $fwidth, 
		$c_dark, $c_light, $c_fill);
	# check mark
	$shape_on->polygon([
		$left + $size * 0.1, $bottom + $size * 0.65,
		$left + $size * 0.3, $bottom + $size * 0.15,
		$left + $size * 0.9, $bottom + $size * 0.85,
		$left + $size * 0.33, $bottom + $size * 0.35,
		], 'f');
	$shape_on->show($mp_on, 0, 0);

	my $mp_off = $docobj->new_minipage($width, $height);
	my $shape_off = PDFJ::Shape->new;
	PDFJ::Form::makeframe($shape_off, $left, $bottom, $size, $size, $fwidth, 
		$c_dark, $c_light, $c_fill);
	$shape_off->show($mp_off, 0, 0);
	
	my $default = $spec->{on} ? 'On' : 'Off';
	
	my %dict = (
		FT => name('Btn'),
		T  => textstring($name),
		F  => $f,
		Ff => $ff,
		Rect => [0, 0, $width, $height],
		V  => name($default),
		DV => name($default),
		AS => name($default),
		AP => dictionary({N => dictionary({
			On => $mp_on->xobject, Off => $mp_off->xobject
			})}),
		);
	my $self = 
		bless {name => $name, width => $width, height => $height}, $class;
	$self->{fieldobj} = PDFJ::Form::makefieldobj($docobj, %dict);
	$self;
}


#-------------------
package PDFJ::Field::RadioButton;
use Carp;
use strict;
use PDFJ::Object;
use vars qw(@ISA);
@ISA = qw(PDFJ::Field);

sub new {
	my($class, $docobj, $spec) = @_;
	my $type = $spec->{type};
	my($name, $width, $height, $size, $values) = map 
		{$spec->{$_} or croak "missing $_ spec for $type field"}
		qw(name width height size values);
	my $f = PDFJ::Form::anotflag($spec);
	my %ff;
	PDFJ::Form::setcommonflag(\%ff, $spec);
	$ff{Radio} = 1;
	$ff{NoToggleToOff} = $spec->{toggletooff} ? 0 : 1;
	$ff{RadiosInUnison} = $spec->{radiosinunison};
	my $ff = PDFJ::Form::fieldflag(%ff);

	my($fwidth, $c_light, $c_medium, $c_dark, $c_fill) = 
		PDFJ::Form::framespec($spec);
	my $mp_on = $docobj->new_minipage($width, $height);
	my $shape_on = PDFJ::Shape->new;
	PDFJ::Form::makecircleframe($shape_on, $width / 2, $height / 2, $size / 2,
		$fwidth, $c_dark, $c_medium, $c_light, $c_fill);
	$shape_on->circle($width / 2, $height / 2, $size / 2 - 3, 'f', undef,
		PDFJ::ShapeStyle->new(fillcolor => PDFJ::Color->new(0)));
	$shape_on->show($mp_on, 0, 0);
	
	my $mp_off = $docobj->new_minipage($width, $height);
	my $shape_off = PDFJ::Shape->new;
	PDFJ::Form::makecircleframe($shape_off, $width / 2, $height / 2, $size / 2,
		$fwidth, $c_dark, $c_medium, $c_light, $c_fill);
	$shape_off->show($mp_off, 0, 0);

	my $groupobj = PDFJ::Form::makefieldobj($docobj,
		FT => name('Btn'),
		T  => textstring($name),
		F  => $f,
		Ff => $ff,
		Kids => [],
		);
	$docobj->add_field($groupobj);
	
	my @objects;
	for my $value(@$values) {
		my $fieldobj = PDFJ::Form::makefieldobj($docobj,
			Parent => $groupobj,
			Rect => [0, 0, $width, $height],
			F  => $f,
			Ff => $ff,
			AS => name('Off'),
			AP => dictionary({N => dictionary({
				$value => $mp_on->xobject, Off => $mp_off->xobject
				})}),
			);
		$groupobj->get('Kids')->push($fieldobj);
		my $obj = 
			bless {name => $name, width => $width, height => $height,
			fieldobj => $fieldobj, value => $value}, $class;
		push @objects, $obj;
	}
	@objects;
}

sub value { $_[0]->{value} }

#-------------------
package PDFJ::Field::ComboBox;
use Carp;
use strict;
use PDFJ::Object;
use vars qw(@ISA);
@ISA = qw(PDFJ::Field);

sub new {
	my($class, $docobj, $spec) = @_;
	my $type = $spec->{type};
	my($name, $width, $height, $values, $font, $fontsize) = map 
		{$spec->{$_} or croak "missing $_ spec for $type field"}
		qw(name width height values font fontsize);
	my $fname = $font->{name} || $font->{zname};
	my $f = PDFJ::Form::anotflag($spec);
	my %ff;
	PDFJ::Form::setcommonflag(\%ff, $spec);
	$ff{Combo} = $spec->{list} ? 0 : 1;
	$ff{Edit} = $spec->{edit};
	$ff{MultiSelect} = $spec->{multiselect};
	$ff{DoNotSpellCheck} = $spec->{donotspellcheck};
	$ff{CommitOnSelChange} = $spec->{commitonselchange};
	my $ff = PDFJ::Form::fieldflag(%ff);
	my $default = exists $spec->{default} ? $spec->{default} : $values->[0];
	my($fwidth, $c_light, $c_medium, $c_dark, $c_fill) = 
		PDFJ::Form::framespec($spec);
	my $mp = $docobj->new_minipage($width, $height);
	my $shape = PDFJ::Shape->new;
	PDFJ::Form::makeframe($shape, 0, 0, $width, $height, $fwidth, $c_dark, 
		$c_light, $c_fill);
	$shape->show($mp, 0, 0);
	if( $spec->{list} ) {
		$mp->addcontents("/Tx BMC ");
		my $ypos = $height;
		my $yadv = $fontsize * 1.2;
		for my $value(@$values) {
			last if $ypos <= 0;
			my $text = PDFJ::Text->new($value,
				PDFJ::TextStyle->new(font => $font, fontsize => $fontsize, 
				));
			$text->show($mp, 0, $ypos, 'tl');
			$ypos -= $yadv;
		}
		$mp->addcontents("EMC ");
	}

	my %dict = (
		FT => name('Ch'),
		T  => textstring($name),
		F  => $f,
		Ff => $ff,
		Rect => [0, 0, $width, $height],
		DA => string("/$fname $fontsize Tf 0 g"),
		DR => dictionary({Font => dictionary(
			{$fname => $docobj->_font($fname)})}),
		V  => textstring($default),
		DV => textstring($default),
		Opt => [map {textstring($_)} @$values],
		AP => dictionary({N => $mp->xobject}),
		MK => dictionary({BC => [$c_light->numarray], 
			BG => [$c_fill->numarray]}),
		);
	my $self = 
		bless {name => $name, width => $width, height => $height}, $class;
	$self->{fieldobj} = PDFJ::Form::makefieldobj($docobj, %dict);
	$self;
}

1;
