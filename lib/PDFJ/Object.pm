# classes for PDF objects
# 2001-2002 Sey <nakajima@netstock.co.jp>
package PDFJ::Object;
use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw(Exporter);

$VERSION = 0.4;

@EXPORT = qw(
	null bool number numbers string textstring datestring name array 
	dictionary stream contents_stream
);

# functions to generate an object
sub null   {PDFJ::Obj::null->new(@_)}
sub bool   {PDFJ::Obj::bool->new(@_)}
sub number {PDFJ::Obj::number->new(@_)}
sub numbers {map {PDFJ::Obj::number->new($_)} @_}
sub string {PDFJ::Obj::string->new(@_)}
sub textstring {PDFJ::Obj::textstring->new(@_)}
sub datestring {PDFJ::Obj::datestring->new(@_)}
sub name   {PDFJ::Obj::name->new(@_)}
sub array  {PDFJ::Obj::array->new(@_)}
sub dictionary {PDFJ::Obj::dictionary->new(@_)}
sub stream {PDFJ::Obj::stream->new(@_)}
sub contents_stream {PDFJ::Obj::contents_stream->new(@_)}

#---------------------------------------
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

sub unused {
	my($self, $unused) = @_;
	if( defined $unused ) {
		$self->{unused} = $unused;
	}
	$self->{unused};
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
	my($self, $rc4key, $filter) = @_;
	my $inum = $self->indirectnum;
	if( $inum ) {
		"$inum R";
	} else {
		$self->{output} || $self->makeoutput($rc4key, $filter);
	}
}

sub print {
	my($self, $handle, $encryptkey, $filter) = @_;
	my $inum = $self->indirectnum;
	return 0 unless $inum;
	my $rc4key;
	if( $encryptkey ) {
		require Digest::MD5;
		my $md5obj = Digest::MD5->new;
		$md5obj->add($encryptkey . substr(pack("V", $inum + 0), 0, 3) . 
			"\x00\x00");
		$rc4key = substr($md5obj->digest, 0, 10);
	}
	my $output = $self->{output} || $self->makeoutput($rc4key, $filter);
#	print $handle "$inum obj\n$output\nendobj\n\n";
	my $str = "$inum obj\n$output\nendobj\n\n";
	print $handle $str;
	return length($str);
}

sub _toobj {
	my($self, $value) = @_;
	return $value if PDFJ::Util::objisa($value, 'PDFJ::Obj');
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
	my $num = $self->{value} + 0;
	$num = sprintf("%.14f", $num) if int($num) != $num;
	$self->{output} = $num;
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
	my($self, $rc4key, $filter) = @_;
	my $value = $self->{value};
	if( $rc4key ) {
		if( $self->{outputtype} eq 'hexliteral' ) {
			$value = pack('H*', $value);
		}
		$value = PDFJ::Util::RC4($value, $rc4key);
		$self->{outputtype} = 'hex';
	} elsif( !defined $self->{outputtype} || 
		$self->{outputtype} !~ /^(literal|hex|hexliteral)$/ ) {
		$self->{outputtype} = 
			$value =~ /[^\x00-\x7f]/ ? 'hex' : 'literal';
	}
	if( $self->{outputtype} eq 'literal' ) {
		$self->{output} = '(' . escape($value) . ')';
	} elsif( $self->{outputtype} eq 'hexliteral' ) {
		$self->{output} = '<' . $value . '>';
	} else {
		$self->{output} = '<' . tohex($value) . '>';
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

sub value2obj {
	my $self = shift;
	if( $self->{value} =~ /[^\x00-\x7f]/ ) {
		$self->{value} = PDFJ::Util::tounicode($self->{value}, 1);
	}
}

#---------------------------------------
package PDFJ::Obj::datestring;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Obj::string);

sub value2obj {
	my $self = shift;
	my @time = gmtime($self->{value} || time);
	$time[4]++;
	$time[5] += 1900;
	$self->{value} = sprintf("D:%04d%02d%02d%02d%02d%02dZ", @time[5,4,3,2,1,0]);
}

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
	my($self, $rc4key, $filter) = @_;
	$self->{output} = '[' . join(' ', map {$_->output($rc4key, $filter)} 
		@{$self->{value}}) . ']';
}

sub get {
	my($self, $idx) = @_;
	$self->{value}->[$idx];
}

sub set {
	my($self, $idx, $obj) = @_;
	$self->{value}->[$idx] = $self->_toobj($obj);
}

sub insert {
	my($self, $idx, $obj) = @_;
	splice @{$self->{value}}, $idx, 0, $self->_toobj($obj);
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

sub nocrypt {
	my $self = shift;
	$self->{nocrypt} = 1;
}

sub makeoutput {
	my($self, $rc4key, $filter) = @_;
	$rc4key = '' if $self->{nocrypt};
	my $href = $self->{value};
	$self->{output} = '<<' . 
		join(' ', map {(PDFJ::Obj::name->new($_)->output($rc4key, $filter),
			$href->{$_}->output($rc4key, $filter))} keys %$href) . '>>';
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

sub keys {
	my($self) = @_;
	keys %{$self->{value}};
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
	my($self, $rc4key, $filter) = @_;
	my $stream = ref($self->{stream}) eq 'ARRAY' ? 
		join('', @{$self->{stream}}) : $self->{stream};
	$self->{dictionary} = PDFJ::Obj::dictionary->new() 
		unless $self->{dictionary};
	$self->{dictionary}->set(
		Length => PDFJ::Obj::number->new(length($stream)) );
	$stream = PDFJ::Util::RC4($stream, $rc4key) if $rc4key;
	$self->{output} = $self->{dictionary}->output($rc4key, $filter) . 
		" stream\n" . $stream . "\nendstream";
}

sub dictionary {
	my $self = shift;
	$self->{dictionary};
}

sub append {
	my($self, $data, $index) = @_;
	if( ref($data) eq 'ARRAY' ) {
		for my $d(@$data) {
			append($self, $d, $index);
		}
	} else {
		$index += 0;
		$data = $data->output if PDFJ::Util::objisa($data, 'PDFJ::Obj');
		if( ref($self->{stream}) eq 'ARRAY' ) {
			$self->{stream}->[$index] .= $data;
		} else {
			$self->{stream} .= $data;
		}
	}
}

sub insert {
	my($self, $data, $index) = @_;
	if( ref($data) eq 'ARRAY' ) {
		for my $d(@$data) {
			insert($self, $d, $index);
		}
	} else {
		$index += 0;
		$data = $data->output if PDFJ::Util::objisa($data, 'PDFJ::Obj');
		if( ref($self->{stream}) eq 'ARRAY' ) {
			$self->{stream}->[$index] = $data . $self->{stream}->[$index];
		} else {
			$self->{stream} = $data . $self->{stream};
		}
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
	my($self, $rc4key, $filter) = @_;
	my $stream = ref($self->{stream}) eq 'ARRAY' ? 
		join('', map { $_ ne '' ? " q $_ Q " : '' } @{$self->{stream}}) : 
		$self->{stream};
	if( $filter =~ /f/ ) { # 'a' filter makes no effect
		($stream, $filter) = PDFJ::Util::makestream($filter, \$stream);
	}
	$self->{dictionary} = PDFJ::Obj::dictionary->new() 
		unless $self->{dictionary};
	$self->{dictionary}->set(
		Length => PDFJ::Obj::number->new(length($stream)) );
	$self->{dictionary}->set(Filter => $filter) if $filter;
	$stream = PDFJ::Util::RC4($stream, $rc4key) if $rc4key;
	$self->{output} = $self->{dictionary}->output($rc4key, $filter) . 
		" stream\n" . $stream . "\nendstream";
}

1;
