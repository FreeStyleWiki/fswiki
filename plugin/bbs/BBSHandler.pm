############################################################
#
# 掲示版プラグインのアクションハンドラ。
#
############################################################
package plugin::bbs::BBSHandler;
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
# 記事の書き込み
#===========================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $name    = $cgi->param("name");
	my $subject = $cgi->param("subject");
	my $message = $cgi->param("message");
	my $count   = $cgi->param("count");
	my $page    = $cgi->param("page");
	my $option  = $cgi->param("option");
	
	if($name eq ""){
		$name = "名無しさん";
	} else {
		# post_nameというキーでクッキーをセットする
		my $path   = &Util::cookie_path($wiki);
		my $cookie = $cgi->cookie(-name=>'post_name',-value=>$name,-expires=>'+1M',-path=>$path);
		print "Set-Cookie: ",$cookie->as_string,"\n";
	}
	
	if($subject eq ""){
		$subject = "無題";
	}
	
	if($page eq "" || $count eq ""){
		return $wiki->error("パラメータが不正です");
	} elsif($message eq ""){
		return $wiki->error("本文を入力してください。");
	}
	
	# フォーマットプラグインへの対応
	my $format = $wiki->get_edit_format();
	$name    = $wiki->convert_to_fswiki($name   ,$format,1);
	$subject = $wiki->convert_to_fswiki($subject,$format,1);
	$message = $wiki->convert_to_fswiki($message,$format);
	
	my @lines = split(/\n/,$wiki->get_page($page));
	my $flag       = 0;
	my $form_count = 1;
	my $content    = "";
	
	foreach(@lines){
		$content = $content.$_."\n";
		if(/^{{bbs\s*.*}}$/ && $flag==0){
			if($form_count==$count){
				$content .= "!!$subject - $name (".&Util::format_date(time()).")\n".
				            "$message\n";
				
				# no_commentオプション
				if($option eq "no_comment"){
					
				# reverse_commentオプション
				} elsif($option eq "reverse_comment"){
					$content .= "{{comment reverse}}\n";
				# デフォルト
				} else {
					$content .= "{{comment}}\n";
				}
				$flag = 1;
				
			} else {
				$form_count++;
			}
		}
	}
	if($flag==1){
		$wiki->save_page($page,$content);
	}
	
	# 元のページにリダイレクトする
	$wiki->redirect($page);
}

1;
