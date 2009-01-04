############################################################
# 
# voteプラグインのアクションハンドラ。
# 
############################################################
package plugin::vote::VoteHandler;
use strict;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# 投票の反映
#===========================================================
sub do_action {
	my $self     = shift;
	my $wiki     = shift;
	my $cgi      = $wiki->get_CGI;
	my $item     = $cgi->param("item");
	my $votename = $cgi->param("vote");
	my $page     = $cgi->param("page");
	
	if($page ne "" && $votename ne "" && $item ne ""){
		my $filename = &Util::make_filename($wiki->config('log_dir'),
		                                    &Util::url_encode($votename),"vote");
		my $hash     = &Util::load_config_hash(undef,$filename);
		$hash->{$item}++;
		&Util::save_config_hash(undef,$filename,$hash);
	}
	$wiki->redirect($page);
}

1;
