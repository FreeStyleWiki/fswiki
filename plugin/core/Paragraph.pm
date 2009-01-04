################################################################################
#
# <p>見出しを出力します。</p>
# <pre>
# {{paragraph レベル(1〜3),見出し}}
# </pre>
# <p>
#   このプラグインで出力した見出しにはパラグラフごとの編集アンカが表示されません。
#   プラグインから見出しを出力する必要がある場合に使用してください。
# </p>
#
################################################################################
package plugin::core::Paragraph;
use strict;
#===============================================================================
# コンストラクタ
#===============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===============================================================================
# パラグラフ
#===============================================================================
sub paragraph {
	my $self  = shift;
	my $wiki  = shift;
	my $level = shift;
	my $para  = shift;
	
	if($level eq ""){
		return &Util::paragraph_error("レベルが指定されていません。","WIKI");
	}
	if($level != 1 && $level != 2 && $level != 3){
		return &Util::paragraph_error("レベルは1〜3までの値しか指定できません。","WIKI");
	}
	if($para eq ""){
		return &Util::paragraph_error("パラグラフが指定されていません。","WIKI");
	}
	
	# ちょっと裏技
	my $parser = $wiki->get_current_parser();
	$parser->{no_partedit} = 1;
	if($level==1){
		$parser->parse("!$para\n");
	} elsif($level==2){
		$parser->parse("!!$para\n");
	} elsif($level==3){
		$parser->parse("!!!$para\n");
	}
	$parser->{no_partedit} = 0;
	
	return undef;
}

1;
