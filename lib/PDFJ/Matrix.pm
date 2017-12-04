# PDFJ/Matrix.pm - PDFJ::Block::Matrix
# 2005 <nakajima@netstock.co.jp>
# automatically required by Block()

#--------------------------------------------------------------------------
package PDFJ::Block::Matrix;
use Carp;
use strict;
use vars qw(@ISA);
@ISA = qw(PDFJ::Block);

sub _checkobjects {
	my($self) = @_;
	my $objects = $self->{objects};
	if( ref($objects) ne 'ARRAY' ) {
		$self->{objects} = [[$objects]];
		$objects = $self->{objects};
	} elsif( !grep {ref($_) eq 'ARRAY'} @$objects ) {
		$self->{objects} = [$objects];
		$objects = $self->{objects};
	}
	for( my $j = 0; $j < @$objects; $j++ ) {
		my $obj = $objects->[$j];
		croak "Matrix objects must be array of array: $obj" 
			unless ref($obj) eq 'ARRAY';
		for( my $k = 0; $k < @$obj; $k++ ) {
			if( PDFJ::Util::objisa($obj->[$k], 'PDFJ::BlockElement') ) {
				# OK
			} elsif( $obj->[$k] =~ /^\d+$/ ) {
				$obj->[$k] = PDFJ::BlockSkip::BlockSkip($obj->[$k]);
			} else {
				croak "illegal Matrix element: $obj->[$k]"
			}
		}
	}
	#print "_checkobjects OK\n";
}

sub _calcsize {
	my($self) = @_;
	$self->_calccol;
	$self->_calcrow;
}

sub _contcell { my $tmp; bless \$tmp, 'PDFJ::Matrix::ContCell'; }
sub _iscontcell { ref($_[0]) eq 'PDFJ::Matrix::ContCell'; }

sub _trimobjects {
	my($self) = @_;
	return if $self->{objectstrimmed};
	$self->{postnobreak} = [];
	my $matrix = $self->{objects};
	my $trimed;
	my $maxrows;
	for( my $j = 0; $j < @$matrix; $j++ ) {
		my $row = $matrix->[$j];
		my $trow = [];
		push @$trimed, $trow;
		for( my $k = 0; $k < @$row; $k++ ) {
			my $cell = $row->[$k];
			push @$trow, $cell;
			my $colspan = $cell->colspan || 1;
			while( $colspan-- > 1 ) {
				push @$trow, _contcell;
			}
			if( $k == $#$row && $cell->postnobreak ) {
				$self->{postnobreak}[$j] = 1;
			}
		}
		$maxrows = @$trow if $maxrows < @$trow;
	}
	for( my $k = 0; $k < $maxrows; $k++ ) {
		for( my $j = 0; $j < @$trimed; $j++ ) {
			my $cell = $trimed->[$j][$k];
			if( $cell && !_iscontcell($cell) ) {
				my $rowspan = $cell->rowspan || 1;
				my $colspan = $cell->colspan || 1;
				for( my $r = 1; $r < $rowspan; $r++ ) {
					if( _iscontcell($trimed->[$j + $r][$k]) ) {
						push @{$self->{collisioncells}}, [$j + $r, $k];
					} else {
						for(1..$colspan) {
							if( $k < @{$trimed->[$j + $r]} ) {
								splice @{$trimed->[$j + $r]}, $k, 0, _contcell;
							} else {
								$trimed->[$j + $r][$k] = _contcell;
							}
						}
					}
				}
				for( my $r = 0; $r < $rowspan - 1; $r++ ) {
					$self->{postnobreak}[$j + $r] = 1;
				}
			}
		}
	}
	for( my $j = 0; $j < @$trimed; $j++ ) {
		my $row = $trimed->[$j];
		for( my $k = 0; $k < @$row; $k++ ) {
#print "[$j, $k] ", $row->[$k], "\n";
			push @{$self->{emptycells}}, [$j, $k] unless $row->[$k];
		}
	}
	$self->{objectstrimmed} = 1;
	$self->{objects} = $trimed;
}

sub _widths2width {
	my($self) = @_;
	my $widths = $self->{widths};
	$self->{width} = 0;
	grep {$self->{width} += $_} @$widths;
	if( @$widths > 1 ) {
		my $skip = $self->{direction} =~ /V$/ ? 
			$self->{style}{colskip} : $self->{style}{rowskip};
		$self->{width} += $skip * (@$widths - 1) 
	}
}

sub _heights2height {
	my($self) = @_;
	my $heights = $self->{heights};
	$self->{height} = 0;
	grep {$self->{height} += $_} @$heights;
	if( @$heights > 1 ) {
		my $skip = $self->{direction} =~ /^V/ ? 
			$self->{style}{colskip} : $self->{style}{rowskip};
		$self->{height} += $skip * (@$heights - 1) 
	}
}

sub _calccol {
	my($self) = @_;
	return unless @{$self->{objects}};
	$self->_trimobjects;
	my $matrix = $self->{objects};
	my $adjust = $self->{style}{adjust};
	my $direction = $self->{direction};
#print "_calccol\n";
	my $maxrows = 0;
	for( my $j = 0; $j < @$matrix; $j++ ) {
		my $row = $matrix->[$j];
		$maxrows = @$row if $maxrows < @$row;
	}
	my @maxsize;
	my $k = 0;
	my @row;
	for( my $j = 0; $j < @$matrix; $j++ ) {
		push @row, $matrix->[$j][$k];
	}
	while(@row) {
#print "----------\n";
		my $maxsize = 0;
		my @left;
		my $one = 0;
		for my $cell( @row ) {
			next if !$cell || _iscontcell($cell);
			my($span, $size);
			if( ref($cell) eq 'ARRAY' ) {
				($span, $size) = @$cell;
			} else {
				$span = $cell->colspan || 1;
				$size = $direction =~ /V$/ ? $cell->width : $cell->height;
			}
#print " [$span, $size]\n";
			if( $span > 1 ) {
				push @left, [$span, $size];
			} else {
				$maxsize = $size if $maxsize < $size;
				$one = 1;
			}
		}
		@row = ();
		for my $cell( @left ) {
			my($span, $size) = @$cell;
			push @row, [$span - 1, $size - $maxsize];
		}
		push @maxsize, $maxsize;
		if( $one ) {
			$k++;
			if( $k < $maxrows ) {
				for( my $j = 0; $j < @$matrix; $j++ ) {
					push @row, $matrix->[$j][$k];
				}
			}
		}
	}
	if( $direction =~ /V$/ ) {
#print "widths: @maxsize\n";
		$self->{widths} = \@maxsize;
		$self->_widths2width;
	} else {
#print "heights: @maxsize\n";
		$self->{heights} = \@maxsize;
		$self->_heights2height;
	}
	if( $adjust ) {
		my $skip = $self->{style}{colskip};
		for( my $j = 0; $j < @$matrix; $j++ ) {
			my $row = $matrix->[$j];
			for( my $k = 0; $k < @$row; $k++ ) {
				my $cell = $row->[$k];
				next if !$cell || _iscontcell($cell);
				my $span = $cell->colspan || 1;
				my $size = 0;
				for( my $m = 0; $m < $span; $m++ ) {
					$size += $skip if $m > 0;
					$size += $maxsize[$k + $m];
				}
				if( $direction =~ /V$/ ) {
					if( UNIVERSAL::can($cell, 'adjustwidth') ) {
#print "adjust [$j, $k] width to $size\n";
						$cell->adjustwidth($size);
					}
				} else {
					if( UNIVERSAL::can($cell, 'adjustheight') ) {
#print "adjust [$j, $k] height to $size\n";
						$cell->adjustheight($size);
					}
				}
			}
		}
	}
}

sub _calcrow {
	my($self) = @_;
	return unless @{$self->{objects}};
	$self->_trimobjects;
	my $matrix = $self->{objects};
	my $adjust = $self->{style}{adjust};
	my $direction = $self->{direction};
#print "_calcrow\n";
	my @maxsize;
	my $j = 0;
	my @row = @{$matrix->[$j]};
	while(@row) {
#print "----------\n";
		my $maxsize = 0;
		my @left;
		my $one = 0;
		for my $cell( @row ) {
			next if !$cell || _iscontcell($cell);
			my($span, $size);
			if( ref($cell) eq 'ARRAY' ) {
				($span, $size) = @$cell;
			} else {
				$span = $cell->rowspan || 1;
				$size = $direction =~ /^V/ ? $cell->width : $cell->height;
			}
#print " [$span, $size]\n";
			if( $span > 1 ) {
				push @left, [$span, $size];
			} else {
				$maxsize = $size if $maxsize < $size;
				$one = 1;
			}
		}
		@row = ();
		for my $cell( @left ) {
			my($span, $size) = @$cell;
			push @row, [$span - 1, $size - $maxsize];
		}
		push @maxsize, $maxsize;
		if( $one ) {
			$j++;
			if( $j < @$matrix ) {
				push @row, @{$matrix->[$j]};
			}
		}
	}
	if( $direction =~ /^V/ ) {
#print "widths: @maxsize\n";
		$self->{widths} = \@maxsize;
		$self->_widths2width;
	} else {
#print "heights: @maxsize\n";
		$self->{heights} = \@maxsize;
		$self->_heights2height;
	}
	if( $adjust ) {
		my $skip = $self->{style}{rowskip};
		for( my $j = 0; $j < @$matrix; $j++ ) {
			my $row = $matrix->[$j];
			for( my $k = 0; $k < @$row; $k++ ) {
				my $cell = $row->[$k];
				next if !$cell || _iscontcell($cell);
				my $span = $cell->rowspan || 1;
				my $size = 0;
				for( my $m = 0; $m < $span; $m++ ) {
					$size += $skip if $m > 0;
					$size += $maxsize[$j + $m];
				}
				if( $direction =~ /^V/ ) {
					if( UNIVERSAL::can($cell, 'adjustwidth') ) {
#print "adjust [$j, $k] width to $size\n";
						$cell->adjustwidth($size);
					}
				} else {
					if( UNIVERSAL::can($cell, 'adjustheight') ) {
#print "adjust [$j, $k] height to $size\n";
						$cell->adjustheight($size);
					}
				}
			}
		}
	}
}

sub widths { $_[0]->{widths} }
sub heights { $_[0]->{heights} }

sub breakable {
	my($self, $blockdirection) = @_;
	$self->nobreak ? 0 : 1;
}

sub _show {
	my($self, $page, $x, $y) = @_;
	my $direction = $self->{direction};
	my $colskip = $self->{style}{colskip};
	my $rowskip = $self->{style}{rowskip};
	$self->_showbox($page, $x, $y);
	$x += $self->padding + $self->{xpreshift};
	$y -= $self->padding + $self->{ypreshift};
	my($dx, $showalign) = (1, 'tl');
	if( $direction =~ /R/ ) {
		$x += $self->{width};
		($dx, $showalign) = (-1, 'tr');
	}
	my($ox, $oy) = ($x, $y);
	my $matrix = $self->{objects};
	if( $direction =~ /V$/ ) {
		for( $y = $oy, my $j = 0; 
			$j < @$matrix; 
			$y -= $self->{heights}[$j] + $rowskip, $j++ ) {
			my $row = $matrix->[$j];
			for( $x = $ox, my $k = 0; 
				$k < @$row; 
				$x += $dx * ($self->{widths}[$k] + $colskip), $k++ ) {
				my $cell = $row->[$k];
				if( PDFJ::Util::objisa($cell, 'PDFJ::Showable') ) {
					$cell->show($page, $x, $y, $showalign);
				}
			}
		}
	} else { # $direction =~ /^V/
		for( $x = $ox, my $j = 0; 
			$j < @$matrix; 
			$x += $dx * ($self->{widths}[$j] + $rowskip), $j++ ) {
			my $row = $matrix->[$j];
			for( $y = $oy, my $k = 0; 
				$k < @$row; 
				$y -= $self->{heights}[$k] + $colskip, $k++ ) {
				my $cell = $row->[$k];
				if( PDFJ::Util::objisa($cell, 'PDFJ::Showable') ) {
					$cell->show($page, $x, $y, $showalign);
				}
			}
		}
	}
}

sub break {
	my($self, $sizes)
		= PDFJ::Util::listargs2ref(1, 0, 
			PDFJ::Util::methodargs([qw(sizes)], @_));
	my @sizes = @$sizes;
	my $unbreakable = $self->nobreak;
	my $repeatheader = $self->repeatheader;
	my $lastsize = $sizes[$#sizes];
	my $skip = $self->{direction} =~ /^V/ ? 
		$self->{style}{colskip} : $self->{style}{rowskip};
	my $direction = $self->{direction} =~ /^V/ ? 'H' : 'V';
	my @result;
	my @objects = $direction eq 'H' ?
		map {[$self->{objects}[$_], $self->{widths}[$_], 
		$self->{postnobreak}[$_]]} (0..$#{$self->{objects}}) :
		map {[$self->{objects}[$_], $self->{heights}[$_], 
		$self->{postnobreak}[$_]]} (0..$#{$self->{objects}});
	my @repeatheader = $repeatheader ? 
			@objects[0..($repeatheader - 1)] : ();
	while( @objects ) {
		my $size = @sizes ? shift(@sizes) : $lastsize;
		my(@bobjects);
		if( $unbreakable ) {
			@bobjects = splice @objects if $size >= $self->size($direction);
		} else {
			my $bsize = $self->padding * 2;
			while( $bsize < $size && @objects ) {
				my $osize = $objects[0][1];
				my $skipsize = @bobjects ? $skip : 0;
				if( $bsize + $skipsize + $osize <= $size ) {
					push @bobjects, shift(@objects);
					$bsize += $skipsize + $osize;
				} else {
					last;
				}
			}
		}
		while( @bobjects && $bobjects[$#bobjects][2] && @objects ) {
			unshift @objects, pop(@bobjects);
		}
		if( !@bobjects && !@sizes ) {
			carp "break fails";
			return;
		}
		if( $repeatheader && (@bobjects >= $repeatheader) && @objects ) {
			unshift @objects, @repeatheader;
		}
		my $bobj;
		%$bobj = %$self;
		bless $bobj, ref($self);
		$bobj->{objects} = [map {$bobjects[$_][0]} (0..$#bobjects)];
		$bobj->{postnobreak} = [map {$bobjects[$_][2]} (0..$#bobjects)];
		if( $direction eq 'H' ) {
			$bobj->{widths} = [map {$bobjects[$_][1]} (0..$#bobjects)];
			$bobj->_widths2width;
		} else {
			$bobj->{heights} = [map {$bobjects[$_][1]} (0..$#bobjects)];
			$bobj->_heights2height;
		}
		push @result, $bobj;
	}
	@result;
}

1;
