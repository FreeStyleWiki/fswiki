###############################################################################
#
# スパム投稿をフィルタリングするフックプラグイン。
#
###############################################################################
package plugin::core::SpamFilter;
use strict;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}
#==============================================================================
# フックメソッド
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	
	my $content = $cgi->param("content");
	return if($content eq '');
	
	my $rule = &Util::load_config_text($wiki,'spam_rules.dat');
	foreach my $line (split(/\n/, $rule)){
		chomp($line);
		my $result = 1;
		$result = RULE_MULTI_URL($content)    if($line eq 'RULE_MULTI_URL');
		$result = RULE_NO_USERAGENT($content) if($line eq 'RULE_NO_USERAGENT');
		$wiki->redirect($cgi->param("page")) unless $result;
	}
	
	my $spam = Util::load_config_text($wiki,"spam.dat");
	foreach my $spam_line (split(/\n/,$spam)){
		chomp($spam_line);
		if(index($content,$spam_line)!=-1){
			$wiki->redirect($cgi->param("page"));
		}
	}
	
	my $client = $ENV{'REMOTE_ADDR'};
	my $ip_list = &Util::load_config_text($wiki,'spam_ip.dat');
	foreach my $line (split(/\n/, $ip_list)){
		my ($from, $to) = split(/-/, $line);
		$to = $from if($to eq '');
		unless(&ip_check($client, Util::trim($from), Util::trim($to))){
			$wiki->redirect($cgi->param("page"));
		}
	}
	
}

#==============================================================================
# IPアドレスのチェック
#==============================================================================
sub ip_check {
	my $client = shift;
	my $from   = shift;
	my $to     = shift;
	
	my @client_dim = split(/\./, $client);
	my @from_dim   = split(/\./, $from);
	my @to_dim     = split(/\./, $to);
	
	foreach my $part (@client_dim){
		unless((shift @from_dim) <= $part && $part <= (shift @to_dim)){
			return 1;
		}
	}
	return 0;
}

#==============================================================================
# 1行に大量のURLが含まれている場合に保存を拒否するルール
#==============================================================================
sub RULE_MULTI_URL {
	my $source = shift;
	foreach my $line (split(/\n/, $source)){
		if($line =~ /(http:.*){5,}?/){
			return 0;
		}
	}
	return 1;
}
#==============================================================================
# USER-AGENTなしの場合に保存を拒否するルール
#==============================================================================
sub RULE_NO_USERAGENT {
	return unless($ENV{'HTTP_USER_AGENT'} eq '');
}

1;

