###############################################################################
# 
# 差分を表示するプラグイン
# 
###############################################################################
package plugin::core::Diff;
use Algorithm::Diff qw(traverse_sequences);
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
# アクションの実行
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if($pagename eq ""){
		$pagename = $wiki->config("frontpage");
	}
	unless($wiki->can_show($pagename)){
		return $wiki->error("参照権限がありません。");
	}
	if($cgi->param('rollback') ne ''){
		return $self->rollback($wiki, $pagename, $cgi->param('rollback'));
	} elsif($wiki->{storage}->backup_type eq "all"){
		if($cgi->param("generation") eq ""){
			return $self->show_history($wiki,$pagename);
		} else {
			return $self->show_diff($wiki,$pagename,$cgi->param("generation"));
		}
	} else {
		return $self->show_diff($wiki,$pagename,0);
	}
}

#==============================================================================
# 履歴からページを復元
#==============================================================================
sub rollback {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	my $gen  = shift;
	unless($wiki->can_modify_page($page)){
		return $wiki->error("更新権限がありません。");
	}
	my $source = $wiki->get_backup($page,$gen);
	$wiki->save_page($page, $source);
	return $wiki->redirect($page);
}

#==============================================================================
# 履歴の一覧を表示
# ストレージのbackup_type=allのとき
#==============================================================================
sub show_history {
	my $self = shift;
	my $wiki = shift;
	my $pagename = shift;
	
	$wiki->set_title($pagename."の変更履歴");
	my $buf   = "<ul>\n";
	my $count = 0;
	my @list  = $wiki->{storage}->get_backup_list($pagename);
	foreach my $time (@list){
		$buf .= "<li><a href=\"".$wiki->create_url({ action=>"DIFF",page=>$pagename,generation=>($#list-$count) })."\">".&Util::escapeHTML($time).
		        "</a>　<a href=\"".$wiki->create_url({ action=>"SOURCE",page=>$pagename,generation=>($#list-$count) })."\">ソース</a>".
		        "</li>\n";
		$count++;
	}
	return $buf."</ul>\n";
}

#==============================================================================
# 差分を表示
#==============================================================================
sub show_diff {
	my $self       = shift;
	my $wiki       = shift;
	my $pagename   = shift;
	my $generation = shift;
	
	$wiki->set_title($pagename."の変更点");
	my ($diff, $rollback) = $self->get_diff_html($wiki,$pagename,$generation);
	
	my $buf = qq|
		<ul>
		  <li>追加された行は<ins class="diff">このように</ins>表示されます。</li>
		  <li>削除された行は<del class="diff">このように</del>表示されます。</li>
		</ul>
		<pre>$diff</pre>
	|;
	
	if($wiki->can_modify_page($pagename) && $rollback){
		$buf .= qq|
			<form action="@{[$wiki->create_url()]}" method="POST">
				<input type="submit" value="このバージョンに戻す"/>
				<input type="hidden" name="action" value="DIFF"/>
				<input type="hidden" name="page" value="@{[Util::escapeHTML($pagename)]}"/>
				<input type="hidden" name="rollback" value="@{[Util::escapeHTML($generation)]}"/>
			</form>
		|;
	}
	
	return $buf;
}

#==============================================================================
# 差分文字列を取得
#==============================================================================
sub get_diff_text {
	my $self       = shift;
	my $wiki       = shift;
	my $pagename   = shift;
	my $generation = shift;
	
	my $source1 = $wiki->get_page($pagename);
	my $source2 = $wiki->get_backup($pagename,$generation);
	my $format  = $wiki->get_edit_format();
	
	$source1 = $wiki->convert_from_fswiki($source1,$format);
	$source2 = $wiki->convert_from_fswiki($source2,$format);
	
	my $diff_text = "";
	my @msg1 = split(/\n/,$source1);
	my @msg2 = split(/\n/,$source2);
	my $msgrefA = \@msg2;
	my $msgrefB = \@msg1;
	
	traverse_sequences($msgrefA, $msgrefB,
		{
			MATCH => sub {},
			DISCARD_A => sub {
				my ($a, $b) = @_;
				$diff_text .= "-".$msgrefA->[$a]."\n";
			},
			DISCARD_B => sub {
				my ($a, $b) = @_;
				$diff_text .= "+".$msgrefB->[$b]."\n";
			}
		});
	
	return $diff_text;
}

#==============================================================================
# 差分文字列を表示用HTMLとして取得
#==============================================================================
sub get_diff_html {
	my $self       = shift;
	my $wiki       = shift;
	my $pagename   = shift;
	my $generation = shift;
	
	my $source1 = $wiki->get_page($pagename);
	my $source2 = $wiki->get_backup($pagename,$generation);
	my $format  = $wiki->get_edit_format();
	
	$source1 = $wiki->convert_from_fswiki($source1,$format);
	$source2 = $wiki->convert_from_fswiki($source2,$format);
	
	my $diff_text = "";
	my @msg1 = split(/\n/,$source1);
	return "ページが大きすぎるため差分を表示できません。" if($#msg1 >= 999);
	my @msg2 = split(/\n/,$source2);
	return "ページが大きすぎるため差分を表示できません。" if($#msg2 >= 999);
	my $msgrefA = \@msg2;
	my $msgrefB = \@msg1;
	
	traverse_sequences($msgrefA, $msgrefB,
		{
			MATCH => sub {
				my ($a, $b) = @_;
				$diff_text .= Util::escapeHTML($msgrefA->[$a])."\n";
			},
			DISCARD_A => sub {
				my ($a, $b) = @_;
				$diff_text .= "<del class=\"diff\">".Util::escapeHTML($msgrefA->[$a])."</del>\n";
			},
			DISCARD_B => sub {
				my ($a, $b) = @_;
				$diff_text .= "<ins class=\"diff\">".Util::escapeHTML($msgrefB->[$b])."</ins>\n";
			}
		});
	
	return ($diff_text, $source2 ne "");
}

#==============================================================================
# ページ表示時のフックメソッド
# 「差分」メニューを有効にします
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	$wiki->add_menu("差分",$wiki->create_url({ action=>"DIFF",page=>$pagename }));
}

1;
