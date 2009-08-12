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
	my $old_config = &Util::load_config_hash($wiki,$wiki->config('config_file'));
	my $new_config = &Util::load_config_hash($wiki,$wiki->config('config_file'));
	
	$new_config->{site_title}           = $cgi->param("site_title");
	$new_config->{admin_name}           = $cgi->param("admin_name");
	$new_config->{admin_mail}           = $cgi->param("admin_mail");
	$new_config->{admin_mail_pub}       = $cgi->param("admin_mail_pub");
	$new_config->{mail_prefix}          = $cgi->param("mail_prefix");
	$new_config->{mail_id}              = $cgi->param("mail_id");
	$new_config->{mail_remote_addr}     = $cgi->param("mail_remote_addr");
	$new_config->{mail_user_agent}      = $cgi->param("mail_user_agent");
	$new_config->{mail_diff}            = $cgi->param("mail_diff");
	$new_config->{mail_backup_source}   = $cgi->param("mail_backup_source");
	$new_config->{mail_modified_source} = $cgi->param("mail_modified_source");
	$new_config->{pagelist}             = $cgi->param("pagelist");
	$new_config->{site_wiki_format}     = $cgi->param("site_wiki_format");
	$new_config->{br_mode}              = $cgi->param("br_mode");
	$new_config->{accept_edit}          = $cgi->param("accept_edit");
	$new_config->{accept_show}          = $cgi->param("accept_show");
	$new_config->{wikiname}             = $cgi->param("wikiname");
	$new_config->{auto_keyword_page}    = $cgi->param("auto_keyword_page");
	$new_config->{keyword_slash_page}   = $cgi->param("keyword_slash_page");
	$new_config->{accept_attach_delete} = $cgi->param("accept_attach_delete");
	$new_config->{accept_attach_update} = $cgi->param("accept_attach_update");
	$new_config->{session_limit}        = $cgi->param("session_limit");
	$new_config->{rss_version}          = $cgi->param("rss_version");
	$new_config->{open_new_window}      = $cgi->param("open_new_window");
	$new_config->{inside_same_window}   = $cgi->param("inside_same_window");
	$new_config->{partedit}             = $cgi->param("partedit");
	$new_config->{partlink}             = $cgi->param("partlink");
	$new_config->{redirect}             = $cgi->param("redirect");
	$new_config->{refer_level}          = $cgi->param("refer_level");
	$new_config->{accept_user_register} = $cgi->param("accept_user_register");
	$new_config->{display_image}        = $cgi->param("display_image");
	
	&Util::save_config_hash($wiki,$wiki->config('config_file'),$new_config);
	
	# config 情報ハッシュ内の全てのキーについて、
	foreach my $config_key (sort keys %$new_config) {
		my $old = $old_config->{$config_key};
		my $new = $new_config->{$config_key};
		# 値が更新されていたら、フック「change_config_キー名」を発行。
		if ($new ne $old) {
			$wiki->do_hook('change_config_' . $config_key, $new, $old);
		}
	}
	
	$wiki->redirectURL( $wiki->create_url({ action=>"ADMINCONFIG"}) );
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
