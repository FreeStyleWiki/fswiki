#!/usr/bin/perl
###############################################################################
#
# FreeStyleWiki フロントエンドCGIスクリプト
#
###############################################################################
BEGIN {
	if(exists $ENV{MOD_PERL}){
		# カレントディレクトリの変更
		chdir($ENV{FSWIKI_HOME});
	}
}
# ModPerl::Registry(Prefork)では実行時に変更されている可能性がある
if(exists $ENV{MOD_PERL}){
	chdir($ENV{FSWIKI_HOME});
}

#==============================================================================
# モジュールのインクルード
#==============================================================================
use Cwd;
use lib './lib';
# ModPerl::Registry(Prefork)では@INCが初期化されている場合がある
unshift @INC, './lib' if(exists $ENV{MOD_PERL});
use strict;
#use CGI::Carp qw(fatalsToBrowser);
#use CGI2;
use Wiki;
use Util;
use Jcode;
use HTML::Template;

# これをやらないとApache::Registoryで動かない
if(exists $ENV{MOD_PERL}){
	eval("use Digest::Perl::MD5;");
	eval("use plugin::core::Diff;");
	eval("use plugin::pdf::PDFMaker;");
	&Jcode::load_module("Jcode::Unicode") unless $Jcode::USE_ENCODE;
}

#==============================================================================
# CGIとWikiのインスタンス化
#==============================================================================
my $wiki = Wiki->new('setup.dat');
my $cgi = $wiki->get_CGI();

Util::override_die();
eval {
	# Session用ディレクトリはFarmでも共通に使用する
	$wiki->config('session_dir',$wiki->config('log_dir'));
	
	#==============================================================================
	# Farmとして動作する場合
	#==============================================================================
	my $path_info  = $cgi->path_info();
	my $path_count = 0;
	if(length($path_info) > 0){
		# Farmがあるか確認する
		unless($path_info =~ m<^(/[A-Za-z0-9]+)*/?$> and -d $wiki->config('data_dir').$path_info){
			CORE::die("Wikiが存在しません。");
		}
		
		# PATH_INFOの最後が/だったら/なしのURLに転送する
		if($path_info =~ m|/$|) {
			$path_info =~ s|/$||;
			$wiki->redirectURL($cgi->url().$path_info);
		}
		$path_info =~ m</([^/]+)$>;
		$wiki->config('script_name', $1);
		$wiki->config('data_dir'   , $wiki->config('data_dir'  ).$path_info);
		$wiki->config('config_dir' , $wiki->config('config_dir').$path_info);
		$wiki->config('backup_dir' , $wiki->config('backup_dir').$path_info);
		$wiki->config('log_dir'    , $wiki->config('log_dir'   ).$path_info);

		if(!($wiki->config('theme_uri') =~ /^(\/|http:|https:|ftp:)/)){
			my @paths = split(/\//,$path_info);
			$path_count = $#paths;
			for(my $i=0;$i<$path_count;$i++){
				$wiki->config('theme_uri','../'.$wiki->config('theme_uri'));
			}
		}
	}

	#==============================================================================
	# 設定を反映（もうちょっとスマートにやりたいね）
	#==============================================================================
	my $config = &Util::load_config_hash($wiki,$wiki->config('config_file'));
	foreach my $key (keys(%$config)){
		$wiki->config($key,$config->{$key});
	}
	# 個別に設定が必要なものだけ上書き
	$wiki->config('css',
		$wiki->config('theme_uri')."/".$config->{theme}."/".$config->{theme}.".css");
	$wiki->config('site_tmpl',
		$wiki->config('tmpl_dir')."/site/".$config->{site_tmpl_theme}."/".$config->{site_tmpl_theme}.".tmpl");
	$wiki->config('site_handyphone_tmpl',
		$wiki->config('tmpl_dir')."/site/".$config->{site_tmpl_theme}."/".$config->{site_tmpl_theme}."_handyphone.tmpl");

	#==============================================================================
	# タイムアウトしているセッションを破棄
	#==============================================================================
	$cgi->remove_session($wiki);

	#==============================================================================
	# ユーザ情報の読み込み
	#==============================================================================
	my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
	foreach my $id (keys(%$users)){
		my ($pass,$type) = split(/\t/,$users->{$id});
		$wiki->add_user($id,$pass,$type);
	}

	#==============================================================================
	# プラグインのインストールと初期化
	#==============================================================================
	my @plugins = split(/\n/,&Util::load_config_text($wiki,$wiki->config('plugin_file')));
	my $plugin_error = '';
	foreach(sort(@plugins)){
		$plugin_error .= $wiki->install_plugin($_);
	}
	# プラグインごとの初期化処理を起動
	$wiki->do_hook("initialize");

	#==============================================================================
	# アクションハンドラの呼び出し
	#==============================================================================
	my $action  = $cgi->param("action");
	my $content = $wiki->call_handler($action);

	# プラグインのインストールに失敗した場合
	$content = $plugin_error . $content if $plugin_error ne '';

	#==============================================================================
	# レスポンス
	#==============================================================================
	my $output        = "";
	my $is_handyphone = &Util::handyphone();
	my $template_name = "";

	if ($is_handyphone) {
		$template_name = 'site_handyphone_tmpl';
	} else {
		$template_name = 'site_tmpl';
	}

	# トップページかどうかを判定
	my $top  = 0;
	if($cgi->param("page") eq $wiki->config("frontpage")){
		$top = 1;
	}

	# ページのタイトルを決定
	my $title = "";
	if($cgi->param('action') eq "" && $wiki->page_exists($cgi->param('page')) && $wiki->is_installed('search')){
		$title = "<a href=\"".$wiki->create_url({action=>"SEARCH",word=>$wiki->get_title()})."\">".
		       &Util::escapeHTML($wiki->get_title())."</a>";
	} else {
		$title = &Util::escapeHTML($wiki->get_title());
	}

	#------------------------------------------------------------------------------
	# ヘッダの生成
	#------------------------------------------------------------------------------
	my $header_tmpl = HTML::Template->new(filename => $wiki->config('tmpl_dir')."/header.tmpl",
	                                      die_on_bad_params => 0,
	                                      case_sensitive    => 1);
	# メニューを取得
	my @menu = ();
	foreach(sort {$b->{weight}<=>$a->{weight}} @{$wiki->{menu}}){
		if($_->{href} ne ""){
			push(@menu,$_);
		}
	}
	$header_tmpl->param(MENU       => \@menu,
	                    FRONT_PAGE => $top);
	my $header = $header_tmpl->output();

	#------------------------------------------------------------------------------
	# フッタの生成
	#------------------------------------------------------------------------------
	my $footer_tmpl = HTML::Template->new(filename => $wiki->config('tmpl_dir')."/footer.tmpl",
	                                      die_on_bad_params => 0,
	                                      case_sensitive    => 1);

	# コピーライトを表示するかどうか
	my $admin_name = $wiki->config('admin_name');
	my $admin_mail = $wiki->config('admin_mail_pub');
	my $out_copyright  = 1;
	if($admin_name eq ""){ $admin_name = $admin_mail; }
	if($admin_name eq "" && $admin_mail eq ""){ $out_copyright = 0; }

	$footer_tmpl->param(ADMIN_NAME    => $admin_name,
	                    ADMIN_MAIL    => $admin_mail,
	                    OUT_COPYRIGHT => $out_copyright,
	                    FRONT_PAGE    => $top,
	                    VERSION       => Wiki->VERSION,
	                    PERL_VERSION  => $]);

	if(exists $ENV{MOD_PERL}){
		$footer_tmpl->param(MOD_PERL=>$ENV{MOD_PERL});
	}

	my $footer = $footer_tmpl->output();

	#------------------------------------------------------------------------------
	# サイトテンプレートの処理
	#------------------------------------------------------------------------------
	# テンプレートの読み込み
	my $template = HTML::Template->new(filename => $wiki->config($template_name),
	                                   die_on_bad_params => 0,
	                                   case_sensitive    => 1);

	# 参照権限があるかどうか
	my $can_show = 0;
	if($action ne '' || ($action eq '' && $wiki->can_show($cgi->param('page')))){
		$can_show = 1;
	}

	# headタグ内に表示する情報を作成
	my $head_info = "";
	foreach (@{$wiki->{'head_info'}}){
		$head_info .= $_."\n";
	}

	# テンプレートにパラメータをセット
	$template->param(SITE_TITLE  => &Util::escapeHTML($wiki->get_title()." - ".$wiki->config('site_title')),
	                 MENU        => $header,
	                 TITLE       => $title,
	                 CONTENT     => $content,
	                 FRONT_PAGE  => $top,
	                 FOOTER      => $footer,
	                 EDIT_MODE   => $action,
	                 CAN_SHOW    => $can_show,
	                 HEAD_INFO   => $head_info,
	                 SITE_NAME   => $wiki->config('site_title'));

	my $login = $wiki->get_login_info();
	$template->param(
		IS_ADMIN => defined($login) && $login->{type}==0,
		IS_LOGIN => defined($login)
	);

	if ($is_handyphone) {
		# 携帯電話用処理
		$output = $template->output;
		&Jcode::convert(\$output,"sjis");
	} else {
		# パソコン用処理
		my $usercss = &Util::load_config_text($wiki,$wiki->config('usercss_file'));
		
		if($config->{'theme'} eq ''){
			# テーマが使用されておらず、外部CSSが指定されている場合はそれを使用
			if($config->{'outer_css'} ne ''){
				$wiki->config('css',$config->{'outer_css'});
			# テーマも外部CSSも指定されていない場合はスタイルシートを使用しない
			} else {
				$wiki->config('css','');
			}
		}
		# パラメータをセット
		$template->param(HAVE_USER_CSS => $usercss ne "",
		                 THEME_CSS     => $wiki->config('css'),
		                 USER_CSS      => &Util::escapeHTML($usercss),
		                 THEME_URI     => $wiki->config('theme_uri'));
		
		# ページ名をEXIST_PAGE_ページ名というパラメータにセット
		# ただし、スラッシュを含むページ名はセットしない
		my @pagelist = $wiki->get_page_list();
		foreach my $page (@pagelist){
			if(index($page,"/")==-1 && $wiki->can_show($page)){
				$template->param("EXIST_PAGE_".$page=>1);
			}
		}
		
		$output = $template->output;
		
		# インクルード命令
		# <!--FSWIKI_INCLUDE PAGE="ページ名"-->
		# ページ名でWikiNameを指定する。
		my $fswiki_include_tag = '<!--\s*FSWIKI_INCLUDE\s+PAGE\s*=\s*"([^"]*)"\s*-->';
		while($output =~ /$fswiki_include_tag/o){
			if($wiki->page_exists($1) && $wiki->can_show($1)){
				$output =~ s/$fswiki_include_tag/$wiki->process_wiki($wiki->get_page($1))/oe;
			} else {
				$output =~ s/$fswiki_include_tag//o;
			}
		}
	}
	
	#------------------------------------------------------------------------------
	# 出力処理
	#------------------------------------------------------------------------------
	# ヘッダの出力
	if($is_handyphone){
		print "Content-Type: text/html;charset=Shift_JIS\n";
	} else {
		print "Content-Type: text/html;charset=EUC-JP\n";
	}
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n\n";
	 
	# HTMLの出力
	print $output;
};

my $msg = $@;
$ENV{'PATH_INFO'} = undef;
$wiki->_process_before_exit();

if($msg && index($msg, 'safe_die')<0){
	$msg = Util::escapeHTML($msg);
	print "Content-Type: text/html\n\n";
	print "<html><head><title>Software Error</title></head>";
	print "<body><h1>Software Error:</h1><p>$msg</p></body></html>";
}
Util::restore_die();
