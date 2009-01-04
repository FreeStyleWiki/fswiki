###############################################################################
#
# MIMEタイプの設定を行うアクションハンドラ
#
###############################################################################
package plugin::attach::AdminMIMEHandler;
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
# アクションハンドラメソッド
#==============================================================================
sub do_action {
	my $self  = shift;
	my $wiki  = shift;
	my $cgi   = $wiki->get_CGI;
	
	$wiki->set_title("MIMEタイプの設定");
	
	if($cgi->param("ADD") ne ""){
		return $self->add($wiki);
		
	} elsif($cgi->param("DELETE") ne ""){
		return $self->delete($wiki);
		
	} else {
		return $self->form($wiki);
	}
}

#==============================================================================
# 一覧画面
#==============================================================================
sub form {
	my $self = shift;
	my $wiki = shift;
	my $buf = "<h2>MIMEタイプの登録</h2>\n".
	          "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	          "  拡張子（ドットは不要） <input type=\"text\" name=\"extention\" size=\"5\">\n".
	          "  MIMEタイプ <input type=\"text\" name=\"mimetype\" size=\"20\">\n".
	          "  <input type=\"submit\" name=\"ADD\" value=\"登録\">\n".
	          "  <input type=\"hidden\" name=\"action\" value=\"ADMINMIME\">\n".
	          "</form>\n".
	          "<h2>登録済のMIMEタイプ</h2>\n".
	          "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	          "<table>\n".
	          "<tr><th>&nbsp;</td><th>拡張子</th><th>MIMEタイプ</th></tr>\n";
	
	my $mime = &Util::load_config_hash($wiki,$wiki->config('mime_file'));
	
	foreach my $key (sort(keys(%$mime))){
		$buf .= "<tr>\n".
		        "  <td><input type=\"checkbox\" name=\"extention\" value=\"".&Util::escapeHTML($key)."\"></td>\n".
		        "  <td>".&Util::escapeHTML($key)."</td>\n".
		        "  <td>".&Util::escapeHTML($mime->{$key})."</td>\n".
		        "</tr>\n";
	}
	$buf .= "</table>\n".
	        "<input type=\"submit\" name=\"DELETE\" value=\"選択項目を削除\">\n".
	        "<input type=\"hidden\" name=\"action\" value=\"ADMINMIME\">\n".
	        "</form>\n";
	
	return $buf;
}

#==============================================================================
# 追加
#==============================================================================
sub add {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	
	my $ext  = $cgi->param("extention");
	my $mime = $cgi->param("mimetype");
	
	if($ext ne "" && $mime ne ""){
		my $hash = &Util::load_config_hash($wiki,$wiki->config('mime_file'));
		$hash->{$ext} = $mime;
		&Util::save_config_hash($wiki,$wiki->config('mime_file'),$hash);
		$wiki->redirectURL($wiki->create_url({ action=>"ADMINMIME"}) );
		#return $self->form($wiki);
		
	} else {
		return $wiki->error("拡張子とMIMEタイプを入力してください。");
	}
}

#==============================================================================
# 削除
#==============================================================================
sub delete {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI();
	
	my @ext_list = $cgi->param("extention");
	my $hash     = &Util::load_config_hash($wiki,$wiki->config('mime_file'));
	my $result   = {};
	
	foreach my $key (keys(%$hash)){
		my $flag = 0;
		foreach my $ext (@ext_list){
			if($ext eq $key){
				$flag = 1;
				last;
			}
		}
		if($flag==0){
			$result->{$key} = $hash->{$key};
		}
	}
	
	&Util::save_config_hash($wiki,$wiki->config('mime_file'),$result);
	$wiki->redirectURL($wiki->create_url({action=>"ADMINMIME"}) );
	
	#return $self->form($wiki);
}

1;
