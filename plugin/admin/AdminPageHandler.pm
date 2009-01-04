###############################################################################
#
# ページを管理するモジュール
#
###############################################################################
package plugin::admin::AdminPageHandler;
use strict;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	
	# フィルタ情報を保存するファイル
	$self->{filter_file} = "filter.dat";
	
	return bless $self,$class;
}

#==============================================================================
# アクションハンドラメソッド
#==============================================================================
sub do_action {
	my $self  = shift;
	my $wiki  = shift;
	my $cgi   = $wiki->get_CGI;
	my $login = $wiki->get_login_info();
	
	if($cgi->param("freeze") ne ""){
		$self->freeze_page($wiki);
		$self->reload($wiki);
		
	} elsif($cgi->param("unfreeze") ne ""){
		$self->unfreeze_page($wiki);
		$self->reload($wiki);
		
	} elsif($cgi->param("delete") ne ""){
		$self->delete_page($wiki);
		$self->reload($wiki);
		
	} elsif($cgi->param("delete_files") ne ""){
		$self->delete_page($wiki);
		$self->delete_files($wiki);
		$self->reload($wiki);
		
	} elsif($cgi->param("show_all") ne ""){
		$self->show_all($wiki);
		$self->reload($wiki);
		
	} elsif($cgi->param("show_user") ne ""){
		$self->show_user($wiki);
		$self->reload($wiki);
		
	} elsif($cgi->param("show_admin") ne ""){
		$self->show_admin($wiki);
		$self->reload($wiki);
		
	}
	return $self->page_list($wiki);
}

#==============================================================================
# ページの削除
#==============================================================================
sub delete_page {
	my $self = shift;
	my $wiki = shift;
	my @pages = $wiki->get_CGI->param("pages");
	foreach(@pages){
		$wiki->save_page($_,"");
	}
}

#==============================================================================
# 添付ファイルの削除
#==============================================================================
sub delete_files {
	my $self = shift;
	my $wiki = shift;
	my @pages = $wiki->get_CGI->param("pages");
	foreach my $pagename (@pages){
		my @files = glob($wiki->config('attach_dir')."/".&Util::url_encode($pagename).".*");
		foreach my $file (@files){
			unlink($file);
		}
	}
}

#==============================================================================
# 全員に公開
#==============================================================================
sub show_all {
	my $self = shift;
	my $wiki = shift;
	my @pages = $wiki->get_CGI->param("pages");
	foreach(@pages){
		$wiki->set_page_level($_,0);
	}
}

#==============================================================================
# ユーザのみ参照可能
#==============================================================================
sub show_user {
	my $self = shift;
	my $wiki = shift;
	my @pages = $wiki->get_CGI->param("pages");
	foreach(@pages){
		$wiki->set_page_level($_,1);
	}
}

#==============================================================================
# 管理者のみ参照可能
#==============================================================================
sub show_admin {
	my $self = shift;
	my $wiki = shift;
	my @pages = $wiki->get_CGI->param("pages");
	foreach(@pages){
		$wiki->set_page_level($_,2);
	}
}

#==============================================================================
# ページの凍結
#==============================================================================
sub freeze_page {
	my $self = shift;
	my $wiki = shift;
	my @freeze_list = $wiki->get_freeze_list;
	my @pages = $wiki->get_CGI->param("pages");
	foreach my $page (@pages){
		my $flag = 1;
		foreach(@freeze_list){
			if($_ eq $page){
				$flag = 0;
				last;
			}
		}
		if($flag){
			$wiki->freeze_page($page);
		}
	}
}

#==============================================================================
# ページの凍結解除
#==============================================================================
sub unfreeze_page {
	my $self = shift;
	my $wiki = shift;
	my @freeze_list = $wiki->get_freeze_list;
	my @pages = $wiki->get_CGI->param("pages");
	foreach my $page (@pages){
		my $flag = 0;
		foreach(@freeze_list){
			if($_ eq $page){
				$flag = 1;
				last;
			}
		}
		if($flag){
			$wiki->un_freeze_page($page);
		}
	}
}

#==============================================================================
# ページ一覧
#==============================================================================
sub page_list {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	
	my @freeze_list = $wiki->get_freeze_list();
	my @pages       = $wiki->get_page_list();
	my $level_list  = $wiki->get_page_level();
	my $filter = $cgi->param("filter");
	my $filterType = $cgi->param("filterType");
	
	if($filterType ne "AND" && $filterType ne "OR" && $filterType ne "NOT"){
		$filterType = "AND";
	}
	
	# フィルタを保存。パラメータで指定されていなければ読み込み。
	if(defined($filter)){
		&Util::save_config_text($wiki,$self->{filter_file},"$filterType:$filter");
	} else {
		$filter = &Util::load_config_text($wiki,$self->{filter_file});
		my $index = index($filter,":");
		if($index > 0){
			$filterType = substr($filter,0,$index);
			$filter = substr($filter,$index+1);
		}
	}
	
	my $buf = "<h2>ページ一覧</h2>\n".
	          "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	          "  <p>\n".
	          "    フィルタ\n".
	          "    <input type=\"text\" name=\"filter\" size=\"30\" value=\"".Util::escapeHTML($filter)."\">\n".
	          "    <input type=\"radio\" name=\"filterType\" value=\"AND\"".($filterType eq "AND" ? " checked" : "").">AND\n".
	          "    <input type=\"radio\" name=\"filterType\" value=\"OR\"".($filterType eq "OR" ? " checked" : "").">OR\n".
	          "    <input type=\"radio\" name=\"filterType\" value=\"NOT\"".($filterType eq "NOT" ? " checked" : "").">NOT\n".
	          "    <input type=\"submit\" value=\"再表示\">\n".
	          "  </p>\n".
	          "  <table>\n".
	          "  <tr>\n".
	          "    <th><br></th>\n".
	          "    <th>状態</th>\n".
	          "    <th>参照</th>\n".
	          "    <th width=\"200\">ページ名</th>\n".
	          "    <th>最終更新日時</th>\n".
	          "  </tr>\n";
	
	foreach my $page (@pages){
		if($filter ne ""){
			my @dim = split(/\s+/,$filter);
			my $flag = 0;
			foreach my $word (split(/\s+/,$filter)){
				if(index($page,$word) >= 0){
					if($filterType eq "NOT"){
						$flag = 0;
						last;
					}
					$flag = 1;
				} else {
					if($filterType eq "AND"){
						$flag = 0;
						last;
					} elsif($filterType eq "NOT"){
						$flag = 1;
					}
				}
			}
			if($flag==0){
				next;
			}
		}
		$buf .= "  <tr>\n".
		        "    <td><input type=\"checkbox\" name=\"pages\" value=\"".&Util::escapeHTML($page)."\"></td>\n";
		
		# 凍結されているか調べる
		my $is_freeze = 0;
		foreach(@freeze_list){
			if($_ eq $page){
				$is_freeze = 1;
				last;
			}
		}
		if($is_freeze){
			$buf .= "    <td align=\"center\">凍結</td>\n";
		} else {
			$buf .= "    <td><br></td>\n";
		}
		
		# 参照レベルを調べる
		if(!defined($level_list->{$page}) || $level_list->{$page}==0){
			$buf .= "    <td>公開</td>\n";
		} elsif($level_list->{$page}==1){
			$buf .= "    <td>ユーザ</td>\n";
		} elsif($level_list->{$page}==2){
			$buf .= "    <td>管理者</td>\n";
		}
		
		$buf .= "    <td><a href=\"".$wiki->create_page_url($page)."\">".&Util::escapeHTML($page)."</a></td>\n".
		        "    <td>".&Util::format_date($wiki->get_last_modified($page))."</td>\n".
		        "  </tr>\n";
	}
	
	$buf .= "  </table>\n".
	        "  <br>\n".
	        "  <input type=\"hidden\" name=\"action\" value=\"ADMINPAGE\">\n".
	        "  <h3>ページの凍結</h3>\n".
	        "  <p>チェックしたページを凍結します。凍結したページはログイン時のみ編集となります。</p>\n".
	        "  <input type=\"submit\" name=\"freeze\" value=\" 凍 結 \">\n".
	        "  <input type=\"submit\" name=\"unfreeze\" value=\"凍結解除\">\n".
	        "  <h3>ページの削除</h3>\n".
	        "  <p>チェックしたページを削除します。</p>\n".
	        "  <input type=\"submit\" name=\"delete\" value=\" 削 除 \">\n".
	        "  <input type=\"submit\" name=\"delete_files\" value=\"添付ファイルも削除\">\n".
	        "  <h3>参照権限の設定</h3>\n".
	        "  <p>チェックしたページの参照権限を設定します。</p>\n".
	        "  <input type=\"submit\" name=\"show_all\"   value=\" 公 開 \">\n".
	        "  <input type=\"submit\" name=\"show_user\"  value=\"ユーザのみ\">\n".
	        "  <input type=\"submit\" name=\"show_admin\" value=\"管理者のみ\">\n".
	        "</form>\n";
	
	$wiki->set_title("ページの管理");
	return $buf."</ul>\n";
}

#==============================================================================
# ページ一覧をリロード
#==============================================================================
sub reload {
	my $self = shift;
	my $wiki = shift;
	$wiki->redirectURL( $wiki->create_url({ action=>"ADMINPAGE" }) );
}

1;
