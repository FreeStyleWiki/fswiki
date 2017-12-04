# PDFJ/Tree.pm - PDFJ::Block::Tree
# 2005 <nakajima@netstock.co.jp>
# automatically required by Block()

#--------------------------------------------
package PDFJ::Block::Tree;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Block);

sub _rootnode { my $tmp; bless \$tmp, 'PDFJ::Block::Tree::Root'; }
sub _isrootnode { PDFJ::Util::objisa($_[0], 'PDFJ::Block::Tree::Root') }

# check structure of $self->{objects} and 
# convert from 'parent, [child,...]' to '[parent, child,...]'
sub _checkobjects {
	my($self) = @_;
	my $objects = $self->{objects};
	$self->{objects} = [$objects] if ref($objects) ne 'ARRAY';
	$self->{objects} = _checktree(_rootnode, $self->{objects});
	#print "_checkobjects OK\n";
}

# NOT method
sub _checktree {
	my($parent, $child) = @_;
	my @children = @$child;
	my @tree = ($parent);
	while(@children) {
		my $node = shift @children;
		croak "illegal Tree element: $node"
			unless PDFJ::Util::objisa($node, 'PDFJ::BlockElement');
		if( @children && ref($children[0]) eq 'ARRAY' ) {
			push @tree, _checktree($node, shift(@children));
		} else {
			push @tree, $node;
		}
	}
	\@tree;
}

sub _calcsize {
	my($self) = @_;
	my $leveldir = $self->{direction} =~ /[VU]/ ? 'V' : 'H';
	my $siblingdir = $self->{direction} =~ /[VU]/ ? 'H' : 'V';
	my $levelskip = $self->{style}{levelskip};
	my $siblingskip = $self->{style}{siblingskip};
	my $adjust = $self->{style}{adjust};
	my $sadjust = $adjust =~ /s/ ? $siblingdir : '';
	my $tree = $self->{objects};
	my ($siblingsize, $middlesize, @levelsizes) = 
		_calctreesize($tree, $sadjust, $leveldir, $siblingdir, $siblingskip);
	$self->{levelsizes} = \@levelsizes;
	my $levelsize = 0;
	grep {$levelsize += $_} @levelsizes;
	$levelsize += $levelskip * (@levelsizes - 1) if @levelsizes > 1;
	if( $leveldir eq 'H' ) {
		$self->{width} = $levelsize;
		$self->{height} = $siblingsize;
	} else {
		$self->{width} = $siblingsize;
		$self->{height} = $levelsize;
	}
	$self->_adjustlevelsize;
}

sub _calctreesize {
	my($tree, $sadjust, $leveldir, $siblingdir, $siblingskip, @levelsizes) = @_;
	my($siblingsize, $middlesize);
	if( ref($tree) eq 'ARRAY' ) {
		my($parent, @children) = @$tree;
		my $pssize = 0;
		unless( _isrootnode($parent) ) {
			push @levelsizes, $parent->size($leveldir);
			$pssize = $parent->size($siblingdir);
		}
		my @lastlevelsizes = @levelsizes;
		my $startlevel = @levelsizes;
		my $cssizesum = 0;
		my($cmmin, $cmmax) = (0, 0);
		for my $child(@children) {
			my($cssize, $cmsize, @clsizes) = 
				_calctreesize($child, $sadjust, $leveldir, $siblingdir, 
				$siblingskip, @lastlevelsizes);
			$cmmin = $cssizesum + $cmsize if $cmmin == 0;
			$cmmax = ($cssizesum ? $cssizesum + $siblingskip : $cssizesum) + 
				$cmsize;
			$cssizesum += $siblingskip if $cssizesum;
			$cssizesum += $cssize;
			for( my $j = $startlevel; $j < @clsizes; $j++ ) {
				$levelsizes[$j] = $clsizes[$j] if $levelsizes[$j] < $clsizes[$j];
			}
		}
		$middlesize = ($cmmin + $cmmax) / 2;
		$siblingsize = $pssize < $cssizesum ? $cssizesum : $pssize;
		splice @$tree, 1, 0, $siblingsize, $middlesize;
		if( $sadjust eq 'H' && $parent->can('adjustwidth') ) {
			$parent->adjustwidth($siblingsize);
		} elsif( $sadjust eq 'V' && $parent->can('adjustheight') ) {
			$parent->adjustheight($siblingsize);
		}
	} else {
		push @levelsizes, $tree->size($leveldir);
		$siblingsize = $tree->size($siblingdir);
		$middlesize = $siblingsize / 2;
	}
	return ($siblingsize, $middlesize, @levelsizes);
}

sub _adjustlevelsize {
	my($self) = @_;
	my $adjust = $self->{style}{adjust};
	return unless $adjust =~ /l/;
	
	my $leveldir = $self->{direction} =~ /[VU]/ ? 'V' : 'H';
	my $tree = $self->{objects};
	my @levelsizes = @{$self->{levelsizes}};
	_adjusttreelevelsize($tree, $leveldir, @levelsizes);
}

sub _adjusttreelevelsize {
	my($tree, $leveldir, @levelsizes) = @_;
	if( ref($tree) eq 'ARRAY' ) {
		my($parent, $ssize, $msize, @children) = @$tree;
		if( _isrootnode($parent) ) {
			for my $child(@children) {
				_adjusttreelevelsize($child, $leveldir, @levelsizes);
			}
			return;
		}
		my $levelsize = shift @levelsizes;
		if( $leveldir eq 'H' && $parent->can('adjustwidth') ) {
			$parent->adjustwidth($levelsize);
		} elsif( $leveldir eq 'V' && $parent->can('adjustheight') ) {
			$parent->adjustheight($levelsize);
		}
		for my $child(@children) {
			_adjusttreelevelsize($child, $leveldir, @levelsizes);
		}
	} else {
		my $levelsize = shift @levelsizes;
		if( $leveldir eq 'H' && $tree->can('adjustwidth') ) {
			$tree->adjustwidth($levelsize);
		} elsif( $leveldir eq 'V' && $tree->can('adjustheight') ) {
			$tree->adjustheight($levelsize);
		}
	}
}

sub _show {
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
	$x += $self->padding + $self->{xpreshift};
	$y -= $self->padding + $self->{ypreshift};
	my $direction = $self->{direction};
	$x += $self->{width} if $direction eq 'TR';
	$y -= $self->{height} if $direction eq 'TU';
	my $tree = $self->{objects};
	my $showalign = 
		$direction eq 'TV' ? 'tl' :
		$direction eq 'TU' ? 'bl' :
		$direction eq 'TH' ? 'tl' :
		$direction eq 'TR' ? 'tr' : 'tl';
	my @levelsizes = @{$self->{levelsizes}};
	$self->_showtree($tree, $page, $x, $y, $showalign, undef, undef, 
		@levelsizes);
}

sub _showtree {
	my($self, $tree, $page, $x, $y, $showalign, $pcx, $pcy, @levelsizes) = @_;
	my $direction = $self->{direction};
	my $siblingalign = $self->{style}{siblingalign};
	my $levelskip = $self->{style}{levelskip};
	my $siblingskip = $self->{style}{siblingskip};
	my $connectline = $self->{style}{connectline};
	my $clstyle = $self->{style}{connectlinestyle};
	my $hvdir = ($direction eq 'TV' || $direction eq 'TU') ? 'H' : 'V';
	if( $connectline eq 'c' ) {
		$connectline = $hvdir eq 'H' ? 'vh' : 'hv';
	}
	my($siblingsize, $middlesize);
	if( ref($tree) eq 'ARRAY' ) {
		my($parent, $ssize, $msize, @children) = @$tree;
		$siblingsize = $ssize;
		$middlesize = $msize;
		if( _isrootnode($parent) ) {
			if( $hvdir eq 'H' ) {
				for my $child(@children) {
					$x += $self->_showtree($child, $page, $x, $y, $showalign, 
						$pcx, $pcy, @levelsizes) + $siblingskip;
				}
			} else {
				for my $child(@children) {
					$y -= $self->_showtree($child, $page, $x, $y, $showalign, 
						$pcx, $pcy, @levelsizes) + $siblingskip;
				}
			}
			return $siblingsize;
		}
		my($px, $py) = ($x, $y);
		my $psize = $parent->size($hvdir);
		if( $siblingalign eq 'M' ) {
			if( $hvdir eq 'H' ) {
				$px += ($siblingsize - $psize) / 2;
			} else {
				$py -= ($siblingsize - $psize) / 2;
			}
		} elsif( $siblingalign eq 'e' ) {
			if( $hvdir eq 'H' ) {
				$px += $siblingsize - $psize;
			} else {
				$py -= $siblingsize - $psize;
			}
		} elsif( $siblingalign eq 'm' ) {
			if( $hvdir eq 'H' ) {
				$px += $middlesize - $psize / 2;
			} else {
				$py -= $middlesize - $psize / 2;
			}
		}
		$parent->show($page, $px, $py, $showalign);
		if( $connectline && defined $pcx ) {
			my $cpdir = 
				$direction eq 'TV' ? 't' : 
				$direction eq 'TU' ? 'b' : 
				$direction eq 'TH' ? 'l' : 
				$direction eq 'TR' ? 'r' : 'N/A';
			_showconnectline($page, $pcx, $pcy, 
				_connectpoint($parent, $px, $py, $showalign, $cpdir),
				$connectline, $clstyle);
		}
		($pcx, $pcy) = (undef, undef);
		if( $connectline ) {
			my $cpdir = 
				$direction eq 'TV' ? 'b' : 
				$direction eq 'TU' ? 't' : 
				$direction eq 'TH' ? 'r' : 
				$direction eq 'TR' ? 'l' : 'N/A';
			($pcx, $pcy) = 
				_connectpoint($parent, $px, $py, $showalign, $cpdir);
		}
		my $lsize = shift @levelsizes;
		if( $hvdir eq 'H' ) {
			my $dy = $lsize + $levelskip;
			$dy = -$dy if $direction eq 'TV';
			$y += $dy;
			for my $child(@children) {
				$x += $self->_showtree($child, $page, $x, $y, $showalign, 
					$pcx, $pcy, @levelsizes) + $siblingskip;
			}
		} else {
			my $dx = $lsize + $levelskip;
			$dx = -$dx if $direction eq 'TR';
			$x += $dx;
			for my $child(@children) {
				$y -= $self->_showtree($child, $page, $x, $y, $showalign, 
					$pcx, $pcy, @levelsizes) + $siblingskip;
			}
		}
	} else {
		$tree->show($page, $x, $y, $showalign);
		if( $connectline && defined $pcx ) {
			my $cpdir = $direction eq 'TV' ? 't' :
				$direction eq 'TU' ? 'b' :
				$direction eq 'TH' ? 'l' :
				$direction eq 'TR' ? 'r' : '';
			_showconnectline($page, $pcx, $pcy, 
				_connectpoint($tree, $x, $y, $showalign, $cpdir),
				$connectline, $clstyle);
		}
		$siblingsize = $tree->size($hvdir);
	}
	$siblingsize;
}

sub breakable { 0 }

sub break { ($_[0]) }

sub _connectpoint {
	my($obj, $x, $y, $showalign, $dir) = @_;
	my $width = $obj->width;
	my $height = $obj->height;
	my($cx, $cy) = ($x, $y);
	if( $showalign =~ /t/ ) {
		$cy -= $height / 2;
	} elsif( $showalign =~ /b/ ) {
		$cy += $height / 2;
	}
	if( $showalign =~ /l/ ) {
		$cx += $width / 2;
	} elsif( $showalign =~ /r/ ) {
		$cx -= $width / 2;
	}
	if( $dir eq 't' ) {
		$cy += $height / 2;
	} elsif( $dir eq 'b' ) {
		$cy -= $height / 2;
	} elsif( $dir eq 'l' ) {
		$cx -= $width / 2;
	} elsif( $dir eq 'r' ) {
		$cx += $width / 2;
	}
	($cx, $cy);
}

sub _showconnectline {
	my($page, $x1, $y1, $x2, $y2, $connectline, $clstyle) = @_;
	my $shape = PDFJ::Shape->new;
	if( $connectline eq 's' ) {
		$shape->line($x1, $y1, $x2 - $x1, $y2 - $y1, $clstyle);
	} elsif( $connectline eq 'hv' ) {
		$shape->line($x1, $y1, ($x2 - $x1) / 2, 0, $clstyle)
			->line($x1 + ($x2 - $x1) / 2, $y1, 0, $y2 - $y1, $clstyle)
			->line($x1 + ($x2 - $x1) / 2, $y2, ($x2 - $x1) / 2, 0, $clstyle);
	} elsif( $connectline eq 'vh' ) {
		$shape->line($x1, $y1, 0, ($y2 - $y1) / 2, $clstyle)
			->line($x1, $y1 + ($y2 - $y1) / 2, $x2 - $x1, 0, $clstyle)
			->line($x2, $y1 + ($y2 - $y1) / 2, 0, ($y2 - $y1) / 2, $clstyle);
	}
	$shape->show($page, 0, 0);
}

1;
