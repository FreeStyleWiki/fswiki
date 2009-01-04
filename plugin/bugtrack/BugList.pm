###############################################################################
#
# <p>bugtrackプラグインで投稿されたバグの一覧を表示します。</p>
# <p>
#   第2引数にformを与えると状態変更用のフォームがあらわれます。
# </p>
# <pre>
# {{buglist プロジェクト名[,form]}}
# </pre>
#
###############################################################################
package plugin::bugtrack::BugList;
use strict;
use plugin::bugtrack::BugState;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
}

#==============================================================================
# インラインメソッド
#==============================================================================
sub paragraph {
	my $self    = shift;
	my $wiki    = shift;
	my $project = shift;
	my $form    = shift;

	if($project eq ""){
		return &Util::paragraph_error("プロジェクト名が指定されていません。");
	}

	# form以外の文字列は無視
	if($form ne "form"){
	    $form = 0;
	}
	
	my @pages = $wiki->get_page_list();
	my $bugs  = {};
	my $quote = quotemeta($project);
	foreach(@pages){
		if($_ =~ /^BugTrack-$quote\/([0-9]+)$/){
			my $pagename = $_;
			my $count    = $1;
			my $category = "";
			my $status   = "";
			my $priority = "";
			my $name     = "";
			my $subject  = "";
			my $date     = "";
			
			my $page = $wiki->get_page($pagename);
			my @lines = split(/\n/,$page);
			my $first = 0;
			foreach(@lines){
				$_ =~ s/\r//;
				if($first==0 && $_ =~ /^!!!(.*)/){
					$subject = $1;
					$first = 1;
				} elsif($_ =~ /^\*カテゴリ：\s*(.*)/){
					$category = $1;
				} elsif($_ =~ /^\*優先度：\s*(.*)/){
					$priority = $1;
				} elsif($_ =~ /^\*状態：\s*(.*)/){
					$status = $1;
				} elsif($_ =~ /^\*投稿者：\s*(.*)/){
					$name = $1;
				} elsif($_ =~ /^\*日時：\s*(.*)/){
					$date = $1;
				}
			}
			my $bug = {page     =>$pagename,
			           count    =>$count,
			           category =>$category,
			           status   =>$status,
			           priority =>$priority,
			           name     =>$name,
			           date     =>$date,
			           subject  =>$subject,
			           form     =>$form };
			
			push(@{$bugs->{$status}},$bug);
		}
	}
	
	my $buf = "";
	
	# サマリを作成
	my $bug_teian    = 0;
	my $bug_chakushu = 0;
	my $bug_kanryo   = 0;
	my $bug_released = 0;
	my $bug_horyu    = 0;
	my $bug_kyakka   = 0;
	
	$bug_teian    = @{$bugs->{"提案"}}       if(defined($bugs->{"提案"}));
	$bug_chakushu = @{$bugs->{"着手"}}       if(defined($bugs->{"着手"}));
	$bug_kanryo   = @{$bugs->{"完了"}}       if(defined($bugs->{"完了"}));
	$bug_released = @{$bugs->{"リリース済"}} if(defined($bugs->{"リリース済"}));
	$bug_horyu    = @{$bugs->{"保留"}}       if(defined($bugs->{"保留"}));
	$bug_kyakka   = @{$bugs->{"却下"}}       if(defined($bugs->{"却下"}));
	my $bug_count = $bug_teian + $bug_chakushu + $bug_kanryo + $bug_released + $bug_horyu + $bug_kyakka;
	
	$buf .= "<p>提案：$bug_teian / 着手：$bug_chakushu / 完了：$bug_kanryo / リリース済：$bug_released ".
	        "/ 保留：$bug_horyu / 却下：$bug_kyakka / 合計：$bug_count</p>\n";
	
	# 一覧を作成
	$buf .= "<table border>\n".
	        "  <tr>\n".
	        "    <th><br></th>\n".
	        "    <th>カテゴリ</th>\n".
	        "    <th>優先度</th>\n".
	        "    <th>状態</th>\n".
	        "    <th>投稿者</th>\n".
	        "    <th>サマリ</th>\n".
	        "  </tr>\n";
	
	my $tmp = $buf;
	
	$buf .= make_row(@{$bugs->{"提案"}}       ,"#FFDDDD",$wiki);
	$buf .= make_row(@{$bugs->{"着手"}}       ,"#FFFFDD",$wiki);
	$buf .= make_row(@{$bugs->{"完了"}}       ,"#DDFFDD",$wiki);
	$buf .= make_row(@{$bugs->{"リリース済"}} ,"#DDDDFF",$wiki);
	$buf .= make_row(@{$bugs->{"保留"}}       ,"#DDDDDD",$wiki);
	$buf .= make_row(@{$bugs->{"却下"}}       ,"#FFFFFF",$wiki);
	
	if($buf eq $tmp){
		$buf .= "  <tr><td colspan=\"6\" align=\"center\">バグレポートはありません</td></tr>\n";
	}
	
	return $buf .= "</table>\n";
}

#==============================================================================
# １行分のデータを出力する内部用関数
#==============================================================================
sub make_row {
	my $wiki  = pop;
	my $color = pop;
	my @row   = sort {$b->{count}<=>$a->{count}} @_;
	my $buf = "";
	
	foreach(@row){
		$buf .= "  <tr bgcolor=\"$color\">\n".
		        "    <td><a href=\"".$wiki->create_page_url($_->{page})."\">".&Util::escapeHTML($_->{page})."</a></td>\n".
		        "    <td>".&Util::escapeHTML($_->{category})."</td>\n".
		        "    <td>".&Util::escapeHTML($_->{priority})."</td>\n".
		        "    <td>".&Util::escapeHTML($_->{status})."</td>\n".
		        "    <td>".&Util::escapeHTML($_->{name})."</td>\n".
		        "    <td>".&Util::escapeHTML($_->{subject})."</td>\n".
		        "  </tr>\n";

		# フォームを表示する
		if($_->{form}){
		    my $page = $wiki->get_CGI->param("page");
		    my $source = $_->{page};
		    my $form = &plugin::bugtrack::BugState::make_form($wiki,$page,$source);
		    $buf .= "<tr bgcolor=\"$color\"><td colspan=\"6\">".$form."</td></tr>\n";
		}
	}
	return $buf;
}

#==============================================================================
# ソート関数
#==============================================================================
#sub by_count {
#	my $a_count = $a->{count};
#	my $b_count = $b->{count};
#	return $b_count <=> $a_count;
#}

1;
