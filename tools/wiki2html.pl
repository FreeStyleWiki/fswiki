#!/usr/local/bin/perl
############################################################
#
# WikiフォーマットからHTMLを生成するスクリプト
#
############################################################
use lib "$ENV{'FSWIKI_HOME'}/lib";
use Wiki;
use Util;
use Jcode;
use Cwd;

#===========================================================
# 引数が足りない
#===========================================================
if($#ARGV==-1){
	die "wiki2html.pl filename [-title=title] [-css=stylesheet] [-output=sjis|euc] [-farm=farmname]\n";
}

#===========================================================
# 変数の準備
#===========================================================
my $from    = "";
my $title   = "";
my $css     = "";
my $input   = "";
my $output  = "euc";
my $farm    = "";
my $count   = 0;
my $current = cwd();
chdir($ENV{'FSWIKI_HOME'});

#===========================================================
# コマンドラインオプションの解析
#===========================================================
foreach(@ARGV){
	if($count==0){
		$from = $_;
	} else {
		my ($key,$value)=split(/=/,$_);
		if($key eq "-title"){
			$title = $value;
		} elsif($key eq "-css"){
			$css = $value;
		} elsif($key eq "-input"){
			$input = $value;
		} elsif($key eq "-output"){
			$output = $value;
		} elsif($key eq "-farm"){
			$farm = $value;
		} else {
			die $key." is Unknown Option.\n";
		}
	}
	$count++;

}

if($title eq ""){
	$title = $from;
	$title =~ s/.*\///;
	$title =~ s/\.wiki//;
	#$title =~ s/%([0-9a-f]{2})/pack("C",$1)/ige;
}

my $url = $from;
$url =~ s/\?.*$//;
my $wiki = Wiki::Wiki2HTML->new('setup.dat', CGI->new($url));

if($farm ne ""){
	$farm =~ s|\/$||;
	$farm=~/^\// or $farm = "/$farm";
	$wiki->config('data_dir'   , $wiki->config('data_dir'  ).$farm);
	$wiki->config('config_dir' , $wiki->config('config_dir').$farm);
}

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
# HTML生成
#===========================================================
my $buf = "<html>\n".
          "<head>\n".
          "  <title>".Util::escapeHTML($title)."</title>\n";
if($output eq 'euc'){
	$buf .= "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=EUC-JP\">\n";
} else {
	$buf .= "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=Shift_JIS\">\n";
}

if($css ne ""){
	$buf .= "  <link rel=\"stylesheet\" type=\"text/css\" href=\"".$css."\">\n";
}
$buf .= "</head>\n".
        "<body>\n".
        "<h1>@{[Util::escapeHTML($title)]}</h1>\n".
        $wiki->process_wiki($source).
        "</body>\n".
        "</html>\n";

&Jcode::convert(\$buf,$output);
print $buf;

package Wiki::Wiki2HTML;
use base qw(Wiki);

sub process_wiki {
	my $self    = shift;
	my $source  = shift;
	my $mainflg = shift;
	
	if($self->{parse_times} >= 50){
		return $self->error("Wiki::process_wikiの呼び出し回数が上限を越えました。");
	}
	
	$self->{parse_times}++;
	my $parser = Wiki::Wiki2HTMLParser->new($self,$mainflg);
	$parser->parse($source);
	$self->{parse_times}--;
	
	return $parser->{html};
}

package Wiki::Wiki2HTMLParser;
use base qw(Wiki::HTMLParser);

sub wiki_anchor {
	my $self = shift;
	my $page = shift;
	my $name = shift;
	
	if(!defined($name) || $name eq ""){
		$name = $page;
	}
	if($self->{wiki}->page_exists($page)){
		my $link = "@{[Util::url_encode(Util::url_encode($page))]}.html";
		return qq|<a href="$link" class="wikipage">@{[Util::escapeHTML($name)]}</a>|;
	} else {
		return qq|<span class="nopage">@{[Util::escapeHTML($name)]}</span><a href="#">?</a>|;
	}
}

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
