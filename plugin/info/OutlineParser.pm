###############################################################################
#
# アウトラインパーサ
#
###############################################################################
package plugin::info::OutlineParser;
use strict;
use vars qw(@ISA);
use Wiki::HTMLParser;

@ISA = qw(Wiki::HTMLParser);

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self  = Wiki::HTMLParser->new(shift);
	$self->{outline_html}  = "";
	$self->{outline_level} =  0;
	$self->{outline_cnt}   =  0;
	return bless $self,$class;
}

#==============================================================================
# ヘッドラインのみ抽出
#==============================================================================
sub l_headline {
	my $self  = shift;
	my $level = shift;
	my $obj   = shift;
	my $text  = &Util::delete_tag(join("",@$obj));
	
	if($level > $self->{outline_level}){
		while($level!=$self->{outline_level}){
			$self->{outline_html} .= "<ul>\n";
			$self->{outline_level}++;
		}
	} elsif($level < $self->{outline_level}){
		while($level!=$self->{outline_level}){
			$self->{outline_html} .= "</li></ul>\n";
			$self->{outline_level}--;
		}
	} else {
		$self->{outline_html} .= "</li>\n";
	}
	$self->{outline_html} .= "<li><a href=\"#p".$self->{outline_cnt}."\">$text</a>";
	$self->{outline_cnt}++;
}

#==============================================================================
# アウトライン表示用HTMLの取得
#==============================================================================
sub outline {
	my $self   = shift;
	my $source = shift;
	$self->parse($source);
	
	while($self->{outline_level}!=0){
		$self->{outline_html} .= "</li></ul>\n";
		$self->{outline_level}--;
	}
	
	return $self->{outline_html};
}

#==============================================================================
# プラグインの解析を行うと無限ループしてしまうため
#==============================================================================
sub plugin{}

#==============================================================================
# プラグインの解析を行うと無限ループしてしまうため
#==============================================================================
sub l_plugin{
	my $self   = shift;
	my $plugin = shift;
	
	# outline以外の場合のみ処理を行う
	if($plugin->{command} ne "outline"){
		my $info = $self->{wiki}->get_plugin_info($plugin->{command});
		if($info->{FORMAT} eq "WIKI"){
			return $self->SUPER::l_plugin($plugin);
		}
		
	} else {
		return undef;
	}
}

1;
