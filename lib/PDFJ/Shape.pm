# Additional PDFJ::Shape methods
# 2004 nakajima@netstock.co.jp
package PDFJ::Shape;
use Carp;
use strict;

sub arrow {
	my($self, $x, $y, $w, $h, $headsize, $headangle, $style)
		= PDFJ::Util::methodargs([qw(x y w h headsize headangle style)], @_);
	my $xt = $x + $w;
	my $yt = $y + $h;
	my $axisangle = atan2(-$h, -$w);
	my $x1 = $xt + $headsize * cos($axisangle + $headangle);
	my $y1 = $yt + $headsize * sin($axisangle + $headangle);
	my $x2 = $xt + $headsize * cos($axisangle - $headangle);
	my $y2 = $yt + $headsize * sin($axisangle - $headangle);
	my $hlen = $headsize * cos($headangle);
	$w += $hlen * cos($axisangle);
	$h += $hlen * sin($axisangle);
	my $coords = [$xt, $yt, $x1, $y1, $x2, $y2, $xt, $yt];
	$self->line($x, $y, $w, $h, $style);
	$self->polygon($coords, 'f', $style);
}

sub brace {
	my($self, $x, $y, $w, $h, $style)
		= PDFJ::Util::methodargs([qw(x y w h style)], @_);
	$self->setboundary($x, $y);
	$self->setboundary($x + $w, $y + $h);
	($w, $h) = ($w / 2, $h / 2);
	my $ch = abs($w * 3 / 2);
	croak "too wide brace" if $ch > $h / 2;
	my $lw = ($style && $style->{linewidth}) ? $style->{linewidth} / 2 :
		($self->{style} && $self->{style}{linewidth}) ? 
			$self->{style}{linewidth} / 2 :
		1 / 2;
	$self->newpath;
	$self->moveto($x, $y + $h);
	$self->curveto(_bracecurve($x, $y + $h, $w + $lw, $ch));
	$self->lineto($x + $w + $lw, $y + $h * 2 - $ch);
	$self->curveto(_bracecurve2($x + $w + $lw, $y + $h * 2 - $ch, $w - $lw, $ch));
	$self->curveto(_bracecurve($x + $w * 2, $y + $h * 2, -$w - $lw, -$ch));
	$self->lineto($x + $w - $lw, $y + $h + $ch);
	$self->curveto(_bracecurve2($x + $w - $lw, $y + $h + $ch, -$w + $lw, -$ch));
	$self->fill;
	$self->newpath;
	$self->moveto($x, $y + $h);
	$self->curveto(_bracecurve($x, $y + $h, $w + $lw, -$ch));
	$self->lineto($x + $w + $lw, $y + $ch);
	$self->curveto(_bracecurve2($x + $w + $lw, $y + $ch, $w - $lw, -$ch));
	$self->curveto(_bracecurve($x + $w * 2, $y, -$w - $lw, $ch));
	$self->lineto($x + $w - $lw, $y + $h - $ch);
	$self->curveto(_bracecurve2($x + $w - $lw, $y + $h - $ch, -$w + $lw, +$ch));
	$self->fill;
	$self;
}

sub bracket {
	my($self, $x, $y, $w, $h, $style)
		= PDFJ::Util::methodargs([qw(x y w h style)], @_);
	my $coords = [$x + $w, $y, $x, $y, $x, $y + $h, $x + $w, $y + $h];
	$self->polygon($coords, 's', $style);
}

sub paren {
	my($self, $x, $y, $w, $h, $style)
		= PDFJ::Util::methodargs([qw(x y w h style)], @_);
	$self->setboundary($x, $y);
	$self->setboundary($x + $w, $y + $h);
	my $lw = ($style && $style->{linewidth}) ? $style->{linewidth}:
		($self->{style} && $self->{style}{linewidth}) ? 
			$self->{style}{linewidth} :
		1;
	$lw = -$lw if $w < 0;
	$h = $h / 2;
	$self->newpath;
	$self->moveto($x, $y + $h);
	$self->curveto(_bracecurve2($x, $y + $h, $w, $h));
	$self->curveto(_bracecurve($x + $w, $y + $h * 2, -$w + $lw, -$h));
	$self->curveto(_bracecurve2($x + $lw, $y + $h, $w - $lw, -$h));
	$self->curveto(_bracecurve($x + $w, $y, -$w, $h));
	$self->fill;
	$self;
}

sub _bracecurve {
	my($x, $y, $w, $h) = @_;
	my($x1, $y1) = ($x + $w * 2 / 3, $y + $h / 4);
	my($x2, $y2) = ($x + $w, $y + $h / 2);
	my($x3, $y3) = ($x + $w, $y + $h);
	($x1, $y1, $x2, $y2, $x3, $y3);
}
sub _bracecurve2 {
	my($x, $y, $w, $h) = @_;
	my($x1, $y1, $x2, $y2, $x3, $y3) = 
		_bracecurve($x + $w, $y + $h, -$w, -$h);
	($x2, $y2, $x1, $y1, $x + $w, $y + $h);
}

1;
