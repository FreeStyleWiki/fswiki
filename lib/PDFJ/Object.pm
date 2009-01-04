# classes for PDF objects
# 2001-2002 Sey <nakajima@netstock.co.jp>
package PDFJ::Object;
use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw(Exporter);

$VERSION = 0.2;

@EXPORT = qw(
	null bool number string textstring name array dictionary stream 
	contents_stream
);

# functions to generate an object
sub null   {PDFJ::Obj::null->new(@_)}
sub bool   {PDFJ::Obj::bool->new(@_)}
sub number {PDFJ::Obj::number->new(@_)}
sub string {PDFJ::Obj::string->new(@_)}
sub textstring {PDFJ::Obj::textstring->new(@_)}
sub name   {PDFJ::Obj::name->new(@_)}
sub array  {PDFJ::Obj::array->new(@_)}
sub dictionary {PDFJ::Obj::dictionary->new(@_)}
sub stream {PDFJ::Obj::stream->new(@_)}
sub contents_stream {PDFJ::Obj::contents_stream->new(@_)}

#---------------------------------------
# virtual base class 
package PDFJ::Obj;

sub new {
	my $class = shift;
	my %args = @_ == 1 ? ('value' => $_[0]) : @_;
	my $self = bless \%args, $class;
	$self->value2obj if $self->can('value2obj');
	$self;
}

sub indirect {
	my($self, $objtable) = @_;
	unless( $self->{objnum} ) {
		$self->{objnum} = $objtable->lastobjnum + 1;
		$self->{gennum} = 0;
		$objtable->set($self->{objnum}, $self);
	}
	$self;
}

sub indirectnum {
	my $self = shift;
	if( $self->{objnum} ) {
		"$self->{objnum} $self->{gennum}";
	}
}

sub output {
	my $self = shift;
	my $inum = $self->indirectnum;
	if( $inum ) {
		"$inum R";
	} else {
		$self->{output} || $self->makeoutput;
	}
}

sub print {
	my($self, $handle) = @_;
	my $inum = $self->indirectnum;
	return unless $inum;
	my $output = $self->{output} || $self->makeoutput;
	print $handle "$inum obj\n$output\nendobj\n\n";
}

sub _toobj {
	my($self, $value) = @_;
	return $value if UNIVERSAL::isa($value, 'PDFJ::Obj');
	if( ref($value) eq 'ARRAY' ) {
		$value = PDFJ::Obj::array->new($value);
	} elsif( ref($value) eq 'HASH' ) {
		$value = PDFJ::Obj::dictionary->new($value);
	} elsif( $value =~ /^[+-]?\d*(\.\d*)?$/ ) {
		$value = PDFJ::Obj::number->new($value);
	} else {
		$value = PDFJ::Obj::string->new($value);
	}
	$value;
}

#---------------------------------------
package PDFJ::Obj::null;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Obj);

sub makeoutput {
	my $self = shift;
	$self->{output} = 'null';
}

#---------------------------------------
package PDFJ::Obj::bool;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Obj);

sub makeoutput {
	my $self = shift;
	$self->{output} = $self->{value} ? 'true' : 'false';
}

#---------------------------------------
package PDFJ::Obj::number;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Obj);

sub makeoutput {
	my $self = shift;
	$self->{output} = $self->{value} + 0;
}

sub add {
	my($self, $value) = @_;
	$self->{value} += $value;
}

#---------------------------------------
package PDFJ::Obj::string;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Obj);

sub makeoutput {
	my $self = shift;
	if( !defined $self->{outputtype} || 
		$self->{outputtype} !~ /^(literal|hex|hexliteral)$/ ) {
		$self->{outputtype} = 
			$self->{value} =~ /[\x80-\xff]/ ? 'hex' : 'literal';
	}
	if( $self->{outputtype} eq 'literal' ) {
		$self->{output} = '(' . escape($self->{value}) . ')';
	} elsif( $self->{outputtype} eq 'hexliteral' ) {
		$self->{output} = '<' . $self->{value} . '>';
	} else {
		$self->{output} = '<' . tohex($self->{value}) . '>';
	}
}

sub escape {
	local($_) = @_;
	s/[()\\]/\\$&/g;
	s/\n/\\n/g;
	s/\r/\\r/g;
	s/\t/\\t/g;
	#s/\b/\\b/g;
	s/\f/\\f/g;
	s/[^\x20-\x7e]/sprintf("\\%03o",ord($&))/ge;
	$_;
}

sub tohex {
	my $str = shift;
	unpack("H*", $str);
}

#---------------------------------------
package PDFJ::Obj::textstring;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Obj::string);

#---------------------------------------
package PDFJ::Obj::name;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Obj);

sub makeoutput {
	my $self = shift;
	$self->{output} = '/' . escape($self->{value});
}

sub escape {
	local($_) = @_;
	s/[()<>\[\]{}\/%#\s]/sprintf("#%02x",ord($&))/ge;
	$_;
}

#---------------------------------------
package PDFJ::Obj::array;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Obj);

sub value2obj {
	my $self = shift;
	grep {$_ = $self->_toobj($_)} @{$self->{value}};
}

sub makeoutput {
	my $self = shift;
	$self->{output} = '[' . join(' ', map {$_->output} @{$self->{value}}) . ']';
}

sub get {
	my($self, $idx) = @_;
	$self->{value}->[$idx];
}

sub set {
	my($self, $idx, $obj) = @_;
	$self->{value}->[$idx] = $self->_toobj($obj);
}

sub push {
	my($self, $obj) = @_;
	push @{$self->{value}}, $self->_toobj($obj);
}

sub pop {
	my($self) = @_;
	pop @{$self->{value}};
}

sub unshift {
	my($self, $obj) = @_;
	unshift @{$self->{value}}, $self->_toobj($obj);
}

sub shift {
	my($self) = @_;
	shift @{$self->{value}};
}

sub add {
	my($self, $obj) = @_;
	my $objoutput = $self->_toobj($obj)->output;
	$self->push($obj)
		unless grep {$objoutput eq $_->output} @{$self->{value}}
}

#---------------------------------------
package PDFJ::Obj::dictionary;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Obj);

sub value2obj {
	my $self = shift;
	my $href = $self->{value};
	for my $key(keys %$href) {
		$href->{$key} = $self->_toobj($href->{$key});
	}
}

sub makeoutput {
	my $self = shift;
	my $href = $self->{value};
	$self->{output} = '<<' . 
		join(' ', map {(PDFJ::Obj::name->new($_)->output,
			$href->{$_}->output)} keys %$href) . '>>';
}

sub exists {
	my($self, $key) = @_;
	exists $self->{value}->{$key};
}

sub get {
	my($self, $key) = @_;
	$self->{value}->{$key};
}

sub set {
	my($self, $key, $obj) = @_;
	$self->{value}->{$key} = $self->_toobj($obj);
}

#---------------------------------------
package PDFJ::Obj::stream;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Obj);

sub value2obj {
	my $self = shift;
	$self->{dictionary} = PDFJ::Obj::dictionary->new($self->{dictionary})
		if exists $self->{dictionary};
}

sub makeoutput {
	my $self = shift;
	my $stream = ref($self->{stream}) eq 'ARRAY' ? 
		join('', @{$self->{stream}}) : $self->{stream};
	$self->{dictionary} = PDFJ::Obj::dictionary->new() 
		unless $self->{dictionary};
	$self->{dictionary}->set(
		Length => PDFJ::Obj::number->new(length($stream)) );
	$self->{output} = $self->{dictionary}->output . " stream\n" . 
		$stream . "\nendstream";
}

sub append {
	my($self, $data, $index) = @_;
	$index += 0;
	if( ref($self->{stream}) eq 'ARRAY' ) {
		$self->{stream}->[$index] .= $data;
	} else {
		$self->{stream} .= $data;
	}
}

sub insert {
	my($self, $data, $index) = @_;
	$index += 0;
	if( ref($self->{stream}) eq 'ARRAY' ) {
		$self->{stream}->[$index] = $data . $self->{stream}->[$index];
	} else {
		$self->{stream} = $data . $self->{stream};
	}
}

sub data {
	my($self, $data, $index) = @_;
	$index += 0;
	if( ref($self->{stream}) eq 'ARRAY' ) {
		$self->{stream}->[$index];
	} else {
		$self->{stream};
	}
}

#---------------------------------------
package PDFJ::Obj::contents_stream;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Obj::stream);

sub makeoutput {
	my $self = shift;
	my $stream = ref($self->{stream}) eq 'ARRAY' ? 
		join('', map { $_ ne '' ? " q $_ Q " : '' } @{$self->{stream}}) : 
		$self->{stream};
	$self->{dictionary} = PDFJ::Obj::dictionary->new() 
		unless $self->{dictionary};
	$self->{dictionary}->set(
		Length => PDFJ::Obj::number->new(length($stream)) );
	$self->{output} = $self->{dictionary}->output . " stream\n" . 
		$stream . "\nendstream";
}

1;
