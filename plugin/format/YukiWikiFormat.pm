###############################################################################
#
# YukiWikiの書式をサポートするフォーマットプラグイン
#
###############################################################################
package plugin::format::YukiWikiFormat;
use base qw(plugin::format::FormatBase); 
use strict;
#==============================================================================
# FSWikiの書式に変換します。
#==============================================================================
sub convert_to_fswiki_paragraph {
	my $self = shift;
	my $line = shift;
	
	if($line =~ /^\*\*\*/){
		return "!".$self->_convert_line(substr($line,3))."\n";
	} elsif($line =~ /^\*\*/){
		return "!!".$self->_convert_line(substr($line,2))."\n";
	} elsif($line =~ /^\*/){
		return "!!!".$self->_convert_line(substr($line,1))."\n";
	} elsif($line =~ /^----/){
		return "----\n";
	} elsif($line =~ /^---/){
		return "***".$self->_convert_line(substr($line,3))."\n";
	} elsif($line =~ /^--/){
		return "**".$self->_convert_line(substr($line,2))."\n";
	} elsif($line =~ /^-/){
		return "*".$self->_convert_line(substr($line,1))."\n";
	} elsif($line =~ /^>/){
		return "\"\"".$self->_convert_line(substr($line,1))."\n";
	} elsif($line =~ /^[ \t]/){
		return $line."\n";
	} else {
		return $self->_convert_line($line)."\n";
	}
}

#==============================================================================
# インライン書式をFSWikiの書式に変換します。
#==============================================================================
sub convert_to_fswiki_line {
	my $self = shift;
	return $self->_convert_line(@_);
}

#==============================================================================
# インライン書式をYukiWikiの書式に変換します。
#==============================================================================
sub convert_from_fswiki_line {
	my $self = shift;
	return $self->_convert_line(@_);
}

#==============================================================================
# １行分のインライン書式を変換します。'''→''に、''→'''に変換にします。
#==============================================================================
sub _convert_line {
	my $self = shift;
	my $line = shift;
	my $buf  = "";
	
	if($line =~ /(''')(.+?)(''')/){
		my $pre   = $`;
		my $post  = $';
		my $label = $2;
		if($pre ne ""){ $buf .= $self->_convert_line($pre); }
		$buf .= "''$label''";
		if($post ne ""){ $buf .= $self->_convert_line($post); }
		
	} elsif($line =~ /('')(.+?)('')/){
		my $pre   = $`;
		my $post  = $';
		my $label = $2;
		if($pre ne ""){ $buf .= $self->_convert_line($pre); }
		$buf .= "'''$label'''";
		if($post ne ""){ $buf .= $self->_convert_line($post); }
	} else {
		$buf .= $line;
	}
	return $buf;
}

#==============================================================================
# FSWikiの書式から変換します。
#==============================================================================
sub convert_from_fswiki_paragraph {
	my $self = shift;
	my $line = shift;
	
	if($line =~ /^!!!/){
		return "*".$self->_convert_line(substr($line,3))."\n";
	} elsif($line =~ /^!!/){
		return "**".$self->_convert_line(substr($line,2))."\n";
	} elsif($line =~ /^!/){
		return "***".$self->_convert_line(substr($line,1))."\n";
	} elsif($line eq "----"){
		return "----\n";
	} elsif($line =~ /^\*\*\*/){
		return "---".$self->_convert_line(substr($line,3))."\n";
	} elsif($line =~ /^\*\*/){
		return "--".$self->_convert_line(substr($line,2))."\n";
	} elsif($line =~ /^\*/){
		return "-".$self->_convert_line(substr($line,1))."\n";
	} elsif($line =~ /^""/){
		return ">".$self->_convert_line(substr($line,2))."\n";
	} elsif($line =~ /^[ \t]/){
		return $line."\n";
	} else {
		return $self->_convert_line($line)."\n";
	}
}

1;
