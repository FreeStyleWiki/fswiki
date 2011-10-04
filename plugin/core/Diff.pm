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
		
	} elsif($wiki->{storage}->backup_type eq 'all'){
		my $login = $wiki->get_login_info();
		if(defined($login) && $login->{'type'} == 0 && $cgi->param('clear') ne ''){
			# 履歴のクリア
			$self->clear_history($wiki, $pagename);
			return $self->show_history($wiki, $pagename);
			
		} elsif($cgi->param('generation') eq '' && $cgi->param('diff') eq ''){
			# 履歴を表示
			return $self->show_history($wiki, $pagename);
			
		} else {
			if($cgi->param('generation') ne ''){
				# 指定したリビジョンでの差分を表示
				return $self->show_diff($wiki, $pagename, '', $cgi->param('generation'));
			}
			# 指定したリビジョン間の差分を表示
			return $self->show_diff($wiki, $pagename, $cgi->param('from'), $cgi->param('to'));
		}
	} else {
		# 最後の更新の差分を表示
		return $self->show_diff($wiki, $pagename, '', 0);
	}
}

#==============================================================================
# 履歴のクリア
#==============================================================================
sub clear_history {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	$wiki->{storage}->delete_backup_files($wiki, $page);
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
	my $page = shift;
	
	$wiki->set_title("$pageの変更履歴");
	my $buf   = "<form><ul>\n";
	my $count = 0;
	my @list  = $wiki->{storage}->get_backup_list($page);
	
	if($#list == -1){
		return "履歴はありません。";
	}
	
	# editlogプラグインのログから編集者のユーザ名を取得
	# （editlogの日付がズレることがあったので1秒以内の更新は同じ履歴とみなすようにしてます）
	my $editlog = {};
	if($wiki->config('log_dir') ne "" && -e $wiki->config('log_dir')."/useredit.log"){
		open(DATA,$wiki->config('log_dir')."/useredit.log") or die $!;
		while(<DATA>){
			my($date, $time, $unixtime, $action, $subject, $id) = split(" ",$_);
			if($subject eq $page){
				if($id eq ''){
					$editlog->{substr($unixtime, 0, length($unixtime) - 4)} = 'anonymous';
				} else {
					$editlog->{substr($unixtime, 0, length($unixtime) - 4)} = $id;
				}
			}
		}
		close(DATA);
	}
	
	foreach my $time (@list){
		$buf .= "<li>";
		if($count == 0){
			$buf .= "<input type=\"radio\" name=\"from\" value=\"".($#list-$count)."\" checked>".
			        "<input type=\"radio\" name=\"to\" value=\"".($#list-$count)."\" checked>";
		} else {
			$buf .= "<input type=\"radio\" name=\"from\" value=\"".($#list-$count)."\">".
			        "<input type=\"radio\" name=\"to\" value=\"".($#list-$count)."\">";
		}
		$buf .= "<a href=\"".$wiki->create_url({ action=>"DIFF",page=>$page,generation=>($#list-$count) })."\">".&Util::format_date($time).
		        "</a> <a href=\"".$wiki->create_url({ action=>"SOURCE",page=>$page,generation=>($#list-$count) })."\">ソース</a>";
		        
		if(defined($editlog->{substr($time, 0, length($time) - 4)})){
			$buf .= " by ".$editlog->{substr($time, 0, length($time) - 4)};
		}
		
		$buf .=  "</li>\n";
		$count++;
	}
	
	$buf .= "</ul>".
		"<input type=\"hidden\" name=\"page\" value=\"".Util::escapeHTML($page)."\">".
		"<input type=\"hidden\" name=\"action\" value=\"DIFF\">".
		"<input type=\"submit\" name=\"diff\" value=\"選択したリビジョン間の差分を表示\">\n";
	
	my $login = $wiki->get_login_info();
	if(defined($login) && $login->{'type'} == 0){
		$buf .= "<input type=\"submit\" name=\"clear\" value=\"履歴をすべて削除\">\n";
	}
	return $buf."</form>\n";
}

#==============================================================================
# 差分を表示
#==============================================================================
sub show_diff {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	my $from = shift;
	my $to   = shift;
	
	$wiki->set_title("$pageの変更点");
	my ($diff, $rollback) = $self->get_diff_html($wiki,$page, $from, $to);
	
	$diff =~ s/\n/<br>/g;
	
	my $buf = qq|
		<ul>
		  <li>追加された部分は<ins class="diff">このように</ins>表示されます。</li>
		  <li>削除された部分は<del class="diff">このように</del>表示されます。</li>
		</ul>
		<div class="diff">$diff</div>
	|;
	
	if($wiki->can_modify_page($page) && $rollback && $wiki->get_CGI->param('diff') eq ''){
		$buf .= qq|
			<form action="@{[$wiki->create_url()]}" method="POST">
				<input type="submit" value="このバージョンに戻す"/>
				<input type="hidden" name="action" value="DIFF"/>
				<input type="hidden" name="page" value="@{[Util::escapeHTML($page)]}"/>
				<input type="hidden" name="rollback" value="@{[Util::escapeHTML($to)]}"/>
			</form>
		|;
	}
	
	return $buf;
}

#==============================================================================
# 差分文字列を取得
#==============================================================================
sub get_diff_text {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	my $gen  = shift;
	
	my $source1 = $wiki->get_page($page);
	my $source2 = $wiki->get_backup($page, $gen);
	my $format  = $wiki->get_edit_format();
	
	$source1 = $wiki->convert_from_fswiki($source1, $format);
	$source2 = $wiki->convert_from_fswiki($source2, $format);
	
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
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	my $from = shift;
	my $to   = shift;
	
	my $source1 = '';
	if($from ne ''){
		$source1 = $wiki->get_backup($page, $from);
	} else {
		$source1 = $wiki->get_page($page);
	}
	if($wiki->config('diff_max') ne '' && $wiki->config('diff_max') > 0){
		if(length($source1) > $wiki->config('diff_max')){
			return ('ページサイズが大きいため差分を表示できません。', 0);
		}
	}
	
	my $source2 = '';
	if($to ne ''){
		$source2 = $wiki->get_backup($page, $to);
	} else {
		$source2 = $wiki->get_page($page);
	}
	if($wiki->config('diff_max') ne '' && $wiki->config('diff_max') > 0){
		if(length($source2) > $wiki->config('diff_max')){
			return ('ページサイズが大きいため差分を表示できません。', 0);
		}
	}
	
	my $format  = $wiki->get_edit_format();
	
	$source1 = $wiki->convert_from_fswiki($source1, $format);
	$source2 = $wiki->convert_from_fswiki($source2, $format);
	
	return (&_get_diff_html($source1, $source2), $source2 ne "");
}

#==============================================================================
# 差分HTMLを生成する関数
#==============================================================================
sub _get_diff_html {
	my $source1 = shift;
	my $source2 = shift;
	
	my @lines1 = split(/\n/,$source1);
	my @lines2 = split(/\n/,$source2);
	my $linesrefA = \@lines2;
	my $linesrefB = \@lines1;
	
	my $diff_text = "";
	my $del_buffer = "";
	
	traverse_sequences($linesrefA, $linesrefB, {
		MATCH => sub {
			my ($a, $b) = @_;
			if($del_buffer ne ''){
				$diff_text .= "<del class=\"diff\">".Util::escapeHTML($del_buffer)."</del>\n";
				$del_buffer = '';
			}
			$diff_text .= Util::escapeHTML($linesrefA->[$a])."\n";
		},
		DISCARD_A => sub {
			my ($a, $b) = @_;
			$del_buffer .= $linesrefA->[$a]."\n";
		},
		DISCARD_B => sub {
			my ($a, $b) = @_;
			if($del_buffer eq ''){
				$diff_text .= "<ins class=\"diff\">".Util::escapeHTML($linesrefB->[$b])."</ins>\n";
				
			} else {
				my @msg1 = _str_jfold($linesrefB->[$b]."\n", 1);
				my @msg2 = _str_jfold($del_buffer, 1);
				my $msgrefA = \@msg2;
				my $msgrefB = \@msg1;
				
				traverse_sequences($msgrefA, $msgrefB, {
					MATCH => sub {
						my ($a, $b) = @_;
						$diff_text .= Util::escapeHTML($msgrefA->[$a]);
					},
					DISCARD_A => sub {
						my ($a, $b) = @_;
						$diff_text .= "<del class=\"diff\">".Util::escapeHTML($msgrefA->[$a])."</del><wbr>";
					},
					DISCARD_B => sub {
						my ($a, $b) = @_;
						$diff_text .= "<ins class=\"diff\">".Util::escapeHTML($msgrefB->[$b])."</ins><wbr>";
					}
				});
				
				$del_buffer = '';
			}
		}
	});
		
	if($del_buffer ne ''){
		$diff_text .= "<del class=\"diff\">".Util::escapeHTML($del_buffer)."</del>\n";
		$del_buffer = '';
	}
	
	return $diff_text;
}

#==============================================================================
# 文字列を指定文字数を分割
#==============================================================================
sub _str_jfold {
  my $str    = shift;       #指定文字列
  my $byte   = shift;       #指定バイト
  my $j      = new Jcode($str);
  my @result = ();

  foreach my $buff ( $j->jfold($byte) ){
    push(@result, $buff);
  }

  return(@result);
}

#==============================================================================
# ページ表示時のフックメソッド
# 「差分」メニューを有効にします
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $page = $cgi->param("page");
	if($wiki->{storage}->backup_type eq 'all'){
		$wiki->add_menu("履歴",$wiki->create_url({ action=>"DIFF",page=>$page }));
	} else {
		$wiki->add_menu("差分",$wiki->create_url({ action=>"DIFF",page=>$page }));
	}
}

1;
