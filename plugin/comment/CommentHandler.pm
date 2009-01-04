############################################################
# 
# Commentプラグインのアクションハンドラ。
# 
############################################################
package plugin::comment::CommentHandler;
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
# コメントの書き込み
#===========================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $name    = $cgi->param("name");
	my $message = $cgi->param("message");
	my $count   = $cgi->param("count");
	my $page    = $cgi->param("page");
	my $option  = $cgi->param("option");
	
	if(!$wiki->can_show($page)){
		return $wiki->error("ページの参照権限がありません。");
	}
	if($name eq ""){
		$name = "名無しさん";
	} else {
		# post_nameというキーでクッキーをセットする
		my $path   = &Util::cookie_path($wiki);
		my $cookie = $cgi->cookie(-name=>'post_name',-value=>$name,-expires=>'+1M',-path=>$path);
		print "Set-Cookie: ",$cookie->as_string,"\n";
	}
	
	# フォーマットプラグインへの対応
	my $format = $wiki->get_edit_format();
	$name    = $wiki->convert_to_fswiki($name   ,$format,1);
	$message = $wiki->convert_to_fswiki($message,$format,1);
	
	if($page ne "" && $message ne "" && $count ne ""){
		
		my @lines = split(/\n/,$wiki->get_page($page));
		my $flag       = 0;
		my $form_count = 1;
		my $content    = "";
		
		foreach(@lines){
			# 新着順の場合
			if($option eq "reverse"){
				$content = $content.$_."\n";
				if(/^{{comment\s*.*}}$/ && $flag==0){
					if($form_count==$count){
						$content = $content."*$message - $name (".Util::format_date(time()).")\n";
						$flag = 1;
					} else {
						$form_count++;
					}
				}
			# ページ末尾に追加の場合
			} elsif($option eq "tail"){
				$content = $content.$_."\n";
				
			# 投稿順の場合
			} else {
				if(/^{{comment\s*.*}}$/ && $flag==0){
					if($form_count==$count){
						$content = $content."*$message - $name (".Util::format_date(time()).")\n";
						$flag = 1;
					} else {
						$form_count++;
					}
				}
				$content = $content.$_."\n";
			}
		}
		
		# ページ末尾に追加の場合は最後に追加
		if($option eq "tail" && check_comment($wiki, 'Footer')){
			$content = $content."*$message - $name (".Util::format_date(time()).")\n";
			$flag = 1;
		}
		
		if($flag==1){
			$wiki->save_page($page,$content);
		}
	}
	
	# 元のページにリダイレクト
	$wiki->redirect($page);
}

#==================================================================
# ページにcommentプラグインが含まれているかどうかをチェック
#==================================================================
sub check_comment {
	my $wiki = shift;
	my $page = shift;
	my @lines = split(/\n/,$wiki->get_page($page));
	foreach(@lines){
		if(/^{{comment\s*.*}}$/){
			return 1;
		}
	}
	return 0;
}

1;
