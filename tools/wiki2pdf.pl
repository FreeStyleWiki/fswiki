#!/usr/local/bin/perl
############################################################
#
# WikiフォーマットからPDFを生成するスクリプト
#
############################################################
use lib "$ENV{'FSWIKI_HOME'}/lib","$ENV{'FSWIKI_HOME'}/";
use plugin::pdf::PDFParser;
use Wiki;
use Util;
use Jcode;
use Cwd;

#===========================================================
# 引数が足りない
#===========================================================
if($#ARGV < 1){
	die "wiki2pdf.pl sourcefile savefile\n";
}

#===========================================================
# 変数の準備
#===========================================================
my $from    = $ARGV[0];
my $to      = $ARGV[1];
my $current = cwd();
chdir($ENV{'FSWIKI_HOME'});

my $url = $from;
$url =~ s/\?.*$//;
my $wiki = Wiki->new(CGI->new($url));

#===========================================================
# Wikiソースを取得
#===========================================================
my $source = "";
if(index($from,"http://")==0 || index($from,"https://")==0){
	# HTTP経由でソースを取得
	$source = &Util::get_response($wiki,$from);
} else {
	# ローカルファイルからソースを取得
	chdir($current);
	open(DATA,$from) or die "File Open Error :$from\n";
	while(<DATA>){
		$source .= $_;
	}
	close(DATA);
	chdir($ENV{'FSWIKI_HOME'});
}
&Jcode::convert(\$source,"euc");

#===========================================================
# PDF生成
#===========================================================
my $parser = plugin::pdf::PDFParser->new($wiki,$from);
$parser->parse($source);

chdir($current);
$parser->save_file($to);

#===========================================================
# CGI.pmのモックオブジェクト
#===========================================================
package CGI;

sub new {
	my $class = shift;
	my $self  = {};
	$self->{url} = shift;
	return bless $self, $class;
}

sub url {
	my $self = shift;
	return $self;
}

sub get_session {
	return undef;
}
