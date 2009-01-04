###############################################################################
#
# PDFパーサ
#
###############################################################################
package plugin::pdf::PDFParser;
use strict;
use vars qw(@ISA);
use Wiki::Parser;
use PDFJ 'EUC';
use Image::Info qw(image_info dim);

@ISA = qw(Wiki::Parser);

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self  = Wiki::Parser->new(shift);
	$self->{pagename} = shift;
	
	my @Pagesize = (595, 842); # A4 210mm x 297mm
	my @Margin   = (72, 72, 72, 72); # (left, right, top, bottom) 1inch
	my $Fontsize = 10.5;
	my $FontsizeHeader = 9;
	my $FontsizeFooter = 9;
	my $Font        = "Ryumin-Light";
	my $FontHeader  = "GothicBBB-Medium";
	my $FontFooter  = "GothicBBB-Medium";
	my $Encoding    = "EUC-H";
	my $HFont       = "Times-Roman";
	my $HFontHeader = "Helvetica";
	my $HFontFooter = "Helvetica";
	my $Linewidth   = $Pagesize[0] - $Margin[0] - $Margin[1];
	my $PageHeight  = $Pagesize[1] - $Margin[2] - $Margin[3];
	my @PosBody     = ($Margin[0], $Pagesize[1] - $Margin[3]);
	my @PosHeader   = ($Margin[0], $Pagesize[1] - $Margin[3] + $Margin[2] / 2);
	my @PosFooter   = ($Margin[0], $Margin[3] / 2);
	my $Tabwidth    = 4;
	
	$self->{footer_x} = $PosFooter[0];
	$self->{footer_y} = $PosFooter[1];
	$self->{height} = $PageHeight;
	$self->{width}  = $Linewidth;
	
	my $doc = PDFJ::Doc->new(1.2, @Pagesize);
	$doc->filter('a');
	my $font    = $doc->new_font($Font, $Encoding, $HFont);
	my $font_header = $doc->new_font($FontHeader, $Encoding, $HFontHeader);
	my $font_footer = $doc->new_font($FontFooter, $Encoding, $HFontHeader);
	my $font_pre    = $doc->new_font($FontFooter, $Encoding);
	
	$self->{tstyle} = {
		normal   => TStyle(font => $font, fontsize => $Fontsize),
		head1    => TStyle(font => $font_footer, fontsize => $Fontsize+5),
		head2    => TStyle(font => $font_footer, fontsize => $Fontsize+2),
		head3    => TStyle(font => $font_header, fontsize => $Fontsize+1),
		verbatim => TStyle(font => $font_pre   , fontsize => $Fontsize-2),
		footer   => TStyle(font => $font_footer, fontsize => $FontsizeFooter)
	};
	
	$self->{pstyle} = {
		head1    => PStyle(size => $Linewidth, linefeed => '100%', align => 'b', preskip =>  10, postskip =>   5),
		head2    => PStyle(size => $Linewidth, linefeed => '100%', align => 'b', preskip =>  10, postskip =>   5),
		head3    => PStyle(size => $Linewidth, linefeed => '100%', align => 'b', preskip =>  10, postskip =>   5),
		defitem  => PStyle(size => $Linewidth, linefeed => '100%', align => 'b', preskip =>   1, postskip =>   1),
		normal   => PStyle(size => $Linewidth, linefeed => '150%', align => 'w', preskip => 2.5, postskip => 2.5),
		verbatim => PStyle(size => $Linewidth, linefeed => '100%', align => 'w', preskip => 2.5, postskip => 2.5,beginindent => 20),
		footer   => PStyle(size => $Linewidth, linefeed => '100%', align => 'm'),
	};
	
	$self->{doc}    = $doc;
	$self->{indent} = 20;
	$self->{table}  = 1;
	$self->{style}  = $self->{tstyle}->{normal};
	$self->{last}   = "";
	
	return bless $self,$class;
}

#==============================================================================
# ファイルに保存します
#==============================================================================
sub save_file {
	my $self = shift;
	my $file = shift;
	
	my $block = Block('V', @{$self->{paras}}, BStyle());
	for my $part( $block->break($self->{height}) ) {
		my $page = $self->{doc}->new_page;
		$part->show($page, 72, 72 + $self->{height});
		my $footer = Paragraph(Text($page->pagenum, $self->{tstyle}->{footer}), $self->{pstyle}->{footer});
		$footer->show($page, $self->{footer_x},$self->{footer_y});
	}
	
	$self->{doc}->print($file);
}

#==============================================================================
# スタイルを上書き
#==============================================================================
sub update_style {
	my $self  = shift;
	my $obj   = shift;
	my $style = shift;
	my $array = [];
	foreach(@$obj){
		push @$array,Text($_->{texts},$style);
	}
	return $array;
}

#==============================================================================
# Textのテキストのみを取得
#==============================================================================
sub get_texts {
	my $self = shift;
	my $obj  = shift;
	my $texts = "";
	foreach my $textobj (@$obj){
		foreach(@{$textobj->{texts}}){
			$texts .= $_;
		}
	}
	return $texts;
}

sub end_parse {
	my $self = shift;
	$self->end_text;
	$self->end_verbatim;
	$self->end_numlist;
}

sub l_headline {
	my $self  = shift;
	my $level = shift;
	my $obj   = shift;
	my $texts = $self->get_texts($obj);
	
	$self->end_text;
	$self->end_verbatim;
	$self->end_numlist;
	$self->{table} = 1;
	
	if($level==1){
		my @outline;
		push @outline,Outline($texts, 0), Dest($texts), $texts;
		push(@{$self->{paras}},Paragraph(Text([@outline], $self->{tstyle}->{head1}),$self->{pstyle}->{head1}));

	} elsif($level==2){
		my @outline;
		push @outline,Outline($texts, 1), Dest($texts), $texts;
		push(@{$self->{paras}},Paragraph(Text([@outline], $self->{tstyle}->{head2}),$self->{pstyle}->{head2}));

	} elsif($level==3){
		my @outline;
		push @outline,Outline($texts, 2), Dest($texts), "■".$texts;
		push(@{$self->{paras}},Paragraph(Text([@outline], $self->{tstyle}->{head3}),$self->{pstyle}->{head3}));
	}
	$self->{last} = "headline";
}

sub l_list {
	my $self  = shift;
	my $level = shift;
	my $obj   = shift;
	
	$self->end_text;
	$self->end_verbatim;
#	$self->end_numlist;
	$self->{table} = 1;
	
	my $liststyle = $self->{pstyle}->{defitem}->clone(beginindent => [$level*$self->{indent},$level*$self->{indent}+8], align => 'b');
	
	if($self->{last} ne "list"){
		push(@{$self->{paras}},Paragraph(Text(" ",$self->{tstyle}->{normal}),$self->{pstyle}->{normal}));
	}
	
	push(@{$self->{paras}},Paragraph(Text("・",@{$obj},$self->{tstyle}->{normal}),$liststyle));
	$self->{last} = "list";
}

sub l_numlist {
	my $self  = shift;
	my $level = shift;
	my $obj   = shift;
	
	$self->end_text;
	$self->end_verbatim;
	$self->{table} = 1;
	if($self->{last_numlist} < $level){
		$self->{numlist}->{$level}=0;
	}
	$self->{numlist}->{$level}++;
	$self->{last_numlist}=$level;
	
	my $liststyle = $self->{pstyle}->{defitem}->clone(beginindent => [$level*$self->{indent},$level*$self->{indent}+8], align => 'b');
	
	if($self->{last} ne "list"){
		push(@{$self->{paras}},Paragraph(Text(" ",$self->{tstyle}->{normal}),$self->{pstyle}->{normal}));
		$self->{numlist}->{$level} = 1;
	}
	
	push(@{$self->{paras}},Paragraph(Text($self->{numlist}->{$level}.".",@{$obj},$self->{tstyle}->{normal}),$liststyle));
	$self->{last} = "list";
}

sub end_numlist {
	my $self = shift;
	$self->{numlist}->{1} = 0;
	$self->{numlist}->{2} = 0;
	$self->{numlist}->{3} = 0;
}

sub l_paragraph {
	my $self = shift;
	$self->end_text;
	$self->end_verbatim;
	$self->end_numlist;
	$self->{table} = 1;
	$self->{last}  = "para";
}

sub l_verbatim {
	my $self = shift;
	my $text = shift;
	
	$self->end_text;
	$self->end_numlist;
	$self->{table} = 1;
	
	# 行末の空白文字は除去する
	$text =~ s/(?:\s)+$//o;
	
	push(@{$self->{pre}},$text);
	push(@{$self->{pre}},NewLine());
	$self->{last} = "pre";
}

sub end_verbatim {
	my $self = shift;
	if($#{$self->{pre}}>=0){
		push(@{$self->{paras}},Paragraph(Text(" ",$self->{tstyle}->{normal}),$self->{pstyle}->{normal}));
		push(@{$self->{paras}},
			Paragraph(Text(@{$self->{pre}},$self->{tstyle}->{verbatim}),$self->{pstyle}->{verbatim}));
		$self->{pre} = [];
	}
}

sub l_text {
	my $self = shift;
	my $obj  = shift;
	
	$self->end_verbatim;
	$self->end_numlist;
	$self->{table} = 1;
	
	if($self->{last} ne "text" && $self->{last} ne "null" && $self->{last} ne "headline"){
		push(@{$self->{paras}},Paragraph(Text(" ",$self->{tstyle}->{normal}),$self->{pstyle}->{normal}));
	}
	foreach(@$obj){
		push(@{$self->{text}},$_);
	}
	if($self->{wiki}->config('br_mode')==1){
		push(@{$self->{text}},NewLine());
	}
	$self->{last} = "text";
}

sub end_text {
	my $self = shift;
	if($#{$self->{text}}>=0){
		push(@{$self->{paras}},Paragraph(Text(@{$self->{text}},$self->{tstyle}->{normal}),$self->{pstyle}->{normal}));
		$self->{text} = [];
	}
}

sub l_table {
	my $self = shift;
	my $row  = shift;
	
	$self->end_text;
	$self->end_verbatim;
	$self->end_numlist;
	
	my $align = "b";
	if($self->{table}==1){
		$align = "m";
		$self->{table} = 0;
	}
	my $width = $self->{width} / ($#{$row}+1);
	my $pstyle = $self->{pstyle}->{normal}->clone(size=>$width,align=>$align);
	my @blocks;
	
	foreach my $cell (@$row){
		if($#{@$cell}==-1){
			push(@$cell,Text("--",$self->{tstyle}->{normal}));
		}
		my $block = Block('V',Paragraph(Text($cell,$self->{tstyle}->{normal}),$pstyle),
		                  BStyle(withbox=>'s',padding=>5,align=>'m'));
		push @blocks,$block;
	}
	my $row_block = Block('H',@blocks,BStyle(adjust=>1,width=>$self->{width}));
	push @{$self->{paras}},$row_block;
	
	$self->{last} = "table";
}

sub l_explanation {
	my $self = shift;
	my $obj1 = shift;
	my $obj2 = shift;
	
	$self->end_text;
	$self->end_verbatim;
	$self->end_numlist;
	$self->{table} = 1;
	
	if($self->{last} ne "explanation" && $self->{last} ne "null"){
		push(@{$self->{paras}},Paragraph(Text(" ",$self->{tstyle}->{normal}),$self->{pstyle}->{normal}));
	}
	push(@{$self->{paras}},
		Paragraph(Text(@$obj1,$self->{tstyle}->{normal}),$self->{pstyle}->{normal}));
	push(@{$self->{paras}},
		Paragraph(Text(@$obj2,$self->{tstyle}->{normal}),$self->{pstyle}->{verbatim}));
	$self->{last} = "explanation";
}

sub l_quotation {
	my $self = shift;
	my $obj  = shift;
	$self->end_text;
	$self->end_verbatim;
	$self->end_numlist;
	$self->{table} = 1;
	
	if($self->{last} ne "quote" && $self->{last} ne "null"){
		push(@{$self->{paras}},Paragraph(Text(" ",$self->{tstyle}->{normal}),$self->{pstyle}->{normal}));
	}
	push(@{$self->{paras}},
			Paragraph(Text(@$obj,$self->{tstyle}->{verbatim}),$self->{pstyle}->{verbatim}));
	$self->{last} = "quote";
}

sub l_line {
	my $self = shift;
	$self->end_text;
	$self->end_verbatim;
	$self->end_numlist;
	$self->{table} = 1;
	push @{$self->{paras}},Paragraph(Text(Shape->line(0,0,$self->{width},0),$self->{tstyle}->{normal}),$self->{pstyle}->{normal});
	$self->{last} = "line";
}

sub bold {
	my $self = shift;
	my $text = shift;
	return Text($self->parse_line($text),$self->{style});
}

sub italic {
	my $self = shift;
	my $text = shift;
	return Text($self->parse_line($text),$self->{style});
}

sub underline {
	my $self = shift;
	my $text = shift;
	return Text($self->parse_line($text),$self->{style});
}

sub denialline {
	my $self = shift;
	my $text = shift;
	return Text($self->parse_line($text),$self->{style});
}

sub url_anchor {
	my $self = shift;
	my $url  = shift;
	my $name = shift;
	
	if($name eq ""){
		$name = $url;
	}
	my $style = $self->{style}->clone(withbox=>'b',withboxstyle=>SStyle(link=>"URI:$url"));
	return Text($name,$style);
}

sub wiki_anchor {
	my $self = shift;
	my $page = shift;
	my $name = shift;
	
	if($name eq ""){
		$name = $page;
	}
	
	my $uri = "URI:".$self->{wiki}->get_CGI->url().$self->{wiki}->get_CGI()->path_info();
	$uri .= "?page=".Util::url_encode($page);
	
	my $style = $self->{style}->clone(withbox=>'b',withboxstyle=>SStyle(link=>$uri));
	return Text($name,$style);
}

sub text {
	my $self = shift;
	my $text = shift;
	return Text($text,$self->{style});
}

#===============================================================================
# プラグインの処理。
#===============================================================================
sub plugin {
	my $self   = shift;
	my $plugin = shift;
	my $info   = $self->{wiki}->get_plugin_info($plugin->{command});
	
	# Wiki形式のプラグインのみ実行
	if($info->{FORMAT} eq "WIKI"){
		return $self->{wiki}->process_plugin($plugin,$self);
	} else {
		return undef;
	}
}

sub l_plugin {
	my $self   = shift;
	my $plugin = shift;
	my $info   = $self->{wiki}->get_plugin_info($plugin->{command});
	
	$self->end_text;
	$self->end_verbatim;
	
	# Wiki形式のプラグインのみ実行
	if($info->{FORMAT} eq "WIKI"){
		$self->{wiki}->process_plugin($plugin,$self);
	}
	return undef;
}

sub l_image {
	my $self = shift;
	my $page = shift;
	my $file = shift;
	
	$self->end_text;
	$self->end_verbatim;
	
	unless($file =~ /\.jpe?g$/i){
		return;
	}
	
	my $filename = $self->{wiki}->config('attach_dir')."/".&Util::url_encode($page).".".&Util::url_encode($file);
	my $info   = image_info($filename);
	my $width  = $info->{width};
	my $height = $info->{height};
	
	if($width > $self->{width}){
		$width  = $self->{width};
		$height = $height * ($width / $info->{width})
	}
	
	my $imgobj = $self->{doc}->new_image($filename,$info->{width},$info->{height},$width,$height,0,$info->{'color_type'});
	push @{$self->{paras}},$imgobj;
}

1;
