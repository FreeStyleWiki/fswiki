###############################################################################
#
# FSWikiのスタイル設定を行うアクションハンドラ
#
###############################################################################
package plugin::admin::AdminStyleHandler;
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
	
	$wiki->set_title("スタイル設定");
	
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
	
	my $config  = &Util::load_config_hash($wiki,$wiki->config('config_file'));
	my $usercss = &Util::load_config_text($wiki,$wiki->config('usercss_file'));
	
	# テーマの一覧を取得しテンプレート用に加工
	my @buf   = $self->list_theme($wiki);
	my @theme = $self->convert_template_list(\@buf, $config->{theme});
	
	# サイトテンプレートテーマの一覧を取得しテンプレート用に加工
	@buf = $self->list_site_tmpl_theme($wiki);
	my @site_tmpl_theme =  $self->convert_template_list(\@buf,$config->{site_tmpl_theme});
	
	my $no_theme = 0;
	if($config->{'theme'} eq ""){
		$no_theme = 1;
	}
	
	# テンプレートにパラメータをセット
	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/admin_style.tmpl",
	                               die_on_bad_params => 0);
	$tmpl->param(THEME           => \@theme,
	             USERCSS         => $usercss,
	             OUTER_CSS       => $config->{'outer_css'},
	             NO_THEME        => $no_theme,
	             SITE_TMPL_THEME => \@site_tmpl_theme);
	
	return "<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
	       $tmpl->output().
	       "<input type=\"hidden\" name=\"action\" value=\"ADMINSTYLE\">\n".
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
	
	$config->{theme}           = $cgi->param("theme");
	$config->{outer_css}       = $cgi->param("outer_css");
	$config->{site_tmpl_theme} = $cgi->param("site_tmpl_theme");
	
	&Util::save_config_hash($wiki,$wiki->config('config_file'),$config);
	
	my $usercss = $cgi->param("usercss");
	&Util::save_config_text($wiki,$wiki->config('usercss_file'),$usercss);
	
	return $wiki->redirectURL( $wiki->create_url({action=>"ADMINSTYLE"}) );
	#return "設定を保存しました。\n";

}

#==============================================================================
# ディレクトリの一覧を取得
#==============================================================================
sub list_dir {
	my $self = shift;
	my $dir  = shift;
	my @list = ();
	opendir(DIR, $dir) or die $!;
	while(my $entry = readdir(DIR)) {
		my $type = -d $dir."/$entry" ? "dir" : "file";
		if($type eq "dir" && $entry ne "." && $entry ne ".."){
			push(@list,$entry);
		}
	}
	closedir(DIR);
	
	return sort(@list);
}

#==============================================================================
# テーマの一覧を取得
#==============================================================================
sub list_theme {
	my $self = shift;
	my $wiki = shift;
	return $self->list_dir($wiki->config('theme_dir'));
}

#==============================================================================
# サイトテンプレートテーマの一覧を取得
#==============================================================================
sub list_site_tmpl_theme {
	my $self = shift;
	my $wiki = shift;
	return $self->list_dir($wiki->config('tmpl_dir').'/site');
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
