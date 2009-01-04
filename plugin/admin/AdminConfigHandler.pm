###############################################################################
#
# FSWikiの動作設定を行うアクションハンドラ
#
###############################################################################
package plugin::admin::AdminConfigHandler;
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
	my $cgi   = $wiki->get_CGI();
	
	$wiki->set_title("環境設定");
	
	if($cgi->param("SAVE") ne ""){
		return $self->save_config($wiki);
	} else {
		return $self->config_form($wiki);
	}
}

#==============================================================================
# 設定フォーム
#==============================================================================
sub config_form {
	my $self = shift;
	my $wiki = shift;
	
	my $config = &Util::load_config_hash($wiki,$wiki->config('config_file'));
	
	# 値が設定されていない場合の初期化
	if($config->{refer_level} eq ""){
		$config->{refer_level} = 0;
	}
	if($config->{accept_attach_delete} eq ""){
		$config->{accept_attach_delete} = 0;
	}
	if($config->{accept_attach_update} eq ""){
		$config->{accept_attach_update} = 1;
	}
	if($config->{accept_edit} eq ""){
		$config->{accept_edit} = 1;
	}
	$config->{accept_show} = 0 if($config->{accept_show} eq "");
	
	#Wikiフォーマットの一覧を取得
	my @buf = $wiki->get_format_names();

	my @site_wiki_format =  $self->convert_template_list(\@buf,$wiki->get_edit_format("config"));

	# テンプレートにパラメータをセット
	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/admin_config.tmpl",
	                               die_on_bad_params => 0);
	$tmpl->param(
		SITE_TITLE           => $config->{site_title},
		ADMIN_NAME           => $config->{admin_name},
		ADMIN_MAIL           => $config->{admin_mail},
		ADMIN_MAIL_PUB       => $config->{admin_mail_pub},
		MAIL_PREFIX          => $config->{mail_prefix},
		MAIL_ID              => $config->{mail_id},
		MAIL_REMOTE_ADDR     => $config->{mail_remote_addr},
		MAIL_USER_AGENT      => $config->{mail_user_agent},
		MAIL_DIFF            => $config->{mail_diff},
		MAIL_BACKUP_SOURCE   => $config->{mail_backup_source},
		MAIL_MODIFIED_SOURCE => $config->{mail_modified_source},
		PAGELIST             => $config->{pagelist},
		SITE_WIKI_FORMAT     => \@site_wiki_format,
		BR_MODE              => $config->{br_mode},
		AUTO_KEYWORD_PAGE    => $config->{auto_keyword_page},
		KEYWORD_SLASH_PAGE   => $config->{keyword_slash_page},
		WIKINAME             => $config->{wikiname},
		SESSION_LIMIT        => $config->{session_limit},
		RSS_VERSION          => $config->{rss_version},
		OPEN_NEW_WINDOW      => $config->{open_new_window},
		INSIDE_SAME_WINDOW   => $config->{inside_same_window},
		PART_EDIT            => $config->{partedit},
		PART_LINK            => $config->{partlink},
		REDIRECT             => $config->{redirect},
		"ACCEPT_EDIT_$config->{accept_edit}" => 1,
		"ACCEPT_SHOW_$config->{accept_show}" => 1,
		"ACCEPT_ATTACH_DELETE_$config->{accept_attach_delete}" => 1,
		"ACCEPT_ATTACH_UPDATE_$config->{accept_attach_update}" => 1,
		"REFER_MODE_$config->{refer_level}" => 1,
		ACCEPT_USER_REGISTER => $config->{accept_user_register},
		DISPLAY_IMAGE        => $config->{display_image}
	);
	
	return "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	       $tmpl->output().
	       "<input type=\"hidden\" name=\"action\" value=\"ADMINCONFIG\">\n".
	       "</form>\n";
}

#==============================================================================
# 設定を保存
#==============================================================================
sub save_config {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $config = &Util::load_config_hash($wiki,$wiki->config('config_file'));
	
	$config->{site_title}           = $cgi->param("site_title");
	$config->{admin_name}           = $cgi->param("admin_name");
	$config->{admin_mail}           = $cgi->param("admin_mail");
	$config->{admin_mail_pub}       = $cgi->param("admin_mail_pub");
	$config->{mail_prefix}          = $cgi->param("mail_prefix");
	$config->{mail_id}              = $cgi->param("mail_id");
	$config->{mail_remote_addr}     = $cgi->param("mail_remote_addr");
	$config->{mail_user_agent}      = $cgi->param("mail_user_agent");
	$config->{mail_diff}            = $cgi->param("mail_diff");
	$config->{mail_backup_source}   = $cgi->param("mail_backup_source");
	$config->{mail_modified_source} = $cgi->param("mail_modified_source");
	$config->{pagelist}             = $cgi->param("pagelist");
	$config->{site_wiki_format}     = $cgi->param("site_wiki_format");
	$config->{br_mode}              = $cgi->param("br_mode");
	$config->{accept_edit}          = $cgi->param("accept_edit");
	$config->{accept_show}          = $cgi->param("accept_show");
	$config->{wikiname}             = $cgi->param("wikiname");
	$config->{auto_keyword_page}    = $cgi->param("auto_keyword_page");
	$config->{keyword_slash_page}   = $cgi->param("keyword_slash_page");
	$config->{accept_attach_delete} = $cgi->param("accept_attach_delete");
	$config->{accept_attach_update} = $cgi->param("accept_attach_update");
	$config->{session_limit}        = $cgi->param("session_limit");
	$config->{rss_version}          = $cgi->param("rss_version");
	$config->{open_new_window}      = $cgi->param("open_new_window");
	$config->{inside_same_window}   = $cgi->param("inside_same_window");
	$config->{partedit}             = $cgi->param("partedit");
	$config->{partlink}             = $cgi->param("partlink");
	$config->{redirect}             = $cgi->param("redirect");
	$config->{refer_level}          = $cgi->param("refer_level");
	$config->{accept_user_register} = $cgi->param("accept_user_register");
	$config->{display_image}        = $cgi->param("display_image");
	
	&Util::save_config_hash($wiki,$wiki->config('config_file'),$config);
	
	$wiki->redirectURL( $wiki->create_url({ action=>"ADMINCONFIG"}) );
	#return "設定を保存しました。\n";

}

#==============================================================================
# HTML::Templateのセレクトタグ用にリストを変換し結果を取得
#==============================================================================
sub convert_template_list {
	my $self = shift;
	my $list = shift;
	my $selected_value = shift;

	my @ret = ();
	foreach my $value (@$list){
		my $selected = 0;
		if($value eq $selected_value){
			$selected = 1;
		}
		push(@ret,{VALUE=>$value,SELECT=>$selected});
	}

	return @ret;
}

1;
