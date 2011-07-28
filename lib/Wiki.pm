###############################################################################
# <p>
# Wiki API
# </p>
###############################################################################
package Wiki;
use strict;
use CGI2;
use File::Copy;
use File::Path;
use Wiki::DefaultStorage;
use Wiki::HTMLParser;
use vars qw($VERSION $DEBUG);
$VERSION = '3.6.4';
$DEBUG   = 0;
#==============================================================================
# <p>
#   コンストラクタ
# </p>
#==============================================================================
sub new {
	my $class = shift;
	my $self  = {};
	
	# 設定を読み込み
	my $setupfile = shift || 'setup.dat';
	$self->{"config"} = &Util::load_config_hash(undef,$setupfile);
	die "setup file ${setupfile} not found" if (keys %{$self->{"config"}} == 0);
	$self->{"config"}->{"plugin_dir"} = "."         unless exists($self->{"config"}->{"plugin_dir"});
	$self->{"config"}->{"frontpage"}  = "FrontPage" unless exists($self->{"config"}->{"frontpage"});
	unshift(@INC, $self->{"config"}->{"plugin_dir"});
	$ENV{'TZ'} = $self->{"config"}->{"time_zone"};
	$CGI::POST_MAX = $self->{"config"}->{"post_max"} if $self->{"config"}->{"post_max"} ne '';
	
	# インスタンス変数を初期化
	$self->{"handler"}            = {};
	$self->{"handler_permission"} = {};
	$self->{"plugin"}             = {};
	$self->{"title"}              = "";
	$self->{"menu"}               = [];
	$self->{"CGI"}                = CGI2->new();
	$self->{"hook"}               = {};
	$self->{"user"}               = ();
	$self->{"admin_menu"}         = ();
	$self->{"editform"}           = ();
	$self->{"edit"}               = 0;
	$self->{"parse_times"}        = 0;
	$self->{"format"}             = {};
	$self->{"installed_plugin"}   = ();
	$self->{"head_info"}          = ();
	
	# ストレージのインスタンスを生成
	if($self->{config}->{"storage"} eq ""){
		$self->{"storage"} = Wiki::DefaultStorage->new($self);
	} else {
		eval ("use ".$self->{config}->{"storage"}.";");
		$self->{"storage"} = $self->{config}->{"storage"}->new($self);
	}
	
	return bless $self,$class;
}

###############################################################################
#
# ユーザ関係のメソッド群
#
###############################################################################
#==============================================================================
# <p>
#   ユーザを追加します
# </p>
# <pre>
# $wiki-&gt;add_user(ID,パスワード,ユーザタイプ);
# </pre>
# <p>
# ユーザタイプには管理者ユーザの場合0、一般ユーザの場合1を指定します。
# なお、このメソッドは実行時にWiki.pmにユーザを追加するためのもので、
# このメソッドに対してユーザを追加しても永続化は行われません。
# </p>
#==============================================================================
sub add_user {
	my $self = shift;
	my $id   = shift;
	my $pass = shift;
	my $type = shift;

	push(@{$self->{"user"}},{id=>$id,pass=>$pass,type=>$type});
}

#==============================================================================
# <p>
#   ユーザが存在するかどうかを確認します
# </p>
#==============================================================================
sub user_exists {
	my $self = shift;
	my $id   = shift;
	foreach my $user (@{$self->{"user"}}){
		if($user->{id} eq $id){
			return 1;
		}
	}
	return 0;
}

#==============================================================================
# <p>
#   ログイン情報を取得します。
#   ログインしている場合はログイン情報を含んだハッシュリファレンスを、
#   ログインしていない場合はundefを返します。
# </p>
# <pre>
# my $info = $wiki-&gt;get_login_info();
# if(defined($info)){          # ログインしていない場合はundef
#   my $id   = $info-&gt;{id};    # ログインユーザのID
#   my $type = $info-&gt;{type};  # ログインユーザの種別(0:管理者 1:一般)
# }
# </pre>
#==============================================================================
sub get_login_info {
	my $self = shift;
	if (exists($self->{'login_info'})){
		return $self->{'login_info'};
	}

	my $cgi = $self->get_CGI();
	return undef unless(defined($cgi));
	
	my $session = $cgi->get_session($self);
	unless(defined($session)){
		$self->{'login_info'} = undef;
		return undef;
	}
	my $id   = $session->param("wiki_id");
	my $type = $session->param("wiki_type");
	my $path = $session->param("wiki_path");

	# PATH_INFOを調べる
	my $path_info = $cgi->path_info();
	if(!defined($path_info)){ $path_info  = ""; }
	if(!defined($path     )){ $path       = ""; }
	if(!defined($id       )){ $id         = ""; }
	if(!defined($type     )){ $type       = ""; }
	
	if($path_info eq "" && $path ne ""){
		$self->{'login_info'} = undef;
		return undef;
	} elsif($path ne "" && !($path_info =~ /^$path($|\/)/)){
		$self->{'login_info'} = undef;
		return undef;
	}
	
	# クッキーがセットされていない
	if($id eq "" ||  $type eq ""){
		$self->{'login_info'} = undef;
		return undef;
	}
	
	# ユーザ情報を返却
	$self->{'login_info'} = {id=>$id,type=>$type,path=>$path};
	return $self->{'login_info'};
}

#==============================================================================
# <p>
#   ログインチェックを行います。
# </p>
#==============================================================================
sub login_check {
	my $self = shift;
	my $id   = shift;
	my $pass = shift;
	my $path = $self->get_CGI()->path_info();
	foreach(@{$self->{"user"}}){
		if($_->{id} eq $id && $_->{pass} eq $pass){
			return {id=>$id,pass=>$pass,type=>$_->{type},path=>$path};
		}
	}
	return undef;
}

###############################################################################
#
# プラグイン関係のメソッド群
#
###############################################################################
#==============================================================================
# <p>
#   エディットフォームプラグインを追加します
# </p>
# <pre>
# $wiki-&gt;add_editform_plugin(エディットフォームプラグインのクラス名,優先度);
# </pre>
# <p>
# 優先度が大きいほど上位に表示されます。
# </p>
#==============================================================================
sub add_editform_plugin {
	my $self   = shift;
	my $plugin = shift;
	my $weight = shift;
	push(@{$self->{"editform"}},{class=>$plugin,weight=>$weight});
}

#==============================================================================
# <p>
#   編集フォーム用のプラグインの出力を取得します
# </p>
#==============================================================================
sub get_editform_plugin {
	my $self = shift;
	my $buf = "";
	foreach my $plugin (sort { $b->{weight}<=>$a->{weight} } @{$self->{"editform"}}){
		my $obj = $self->get_plugin_instance($plugin->{class});
		$buf .= $obj->editform($self)."\n";
	}
	return $buf;
}

#==============================================================================
# <p>
# 管理者用のメニューを追加します。管理者ユーザがログインした場合に表示されます。
# 優先度が高いほど上のほうに表示されます。
# </p>
# <pre>
# $wiki-&gt;add_admin_menu(メニュー項目名,遷移するURL,優先度,詳細説明);
# </pre>
#==============================================================================
sub add_admin_menu {
	my $self   = shift;
	my $label  = shift;
	my $url    = shift;
	my $weight = shift;
	my $desc   = shift;
	
	push(@{$self->{"admin_menu"}},{label=>$label,url=>$url,weight=>$weight,desc=>$desc,type=>0});
}

#==============================================================================
# <p>
# ログインユーザ用のメニューを追加します。
# ユーザがログインした場合に表示されます。管理者ユーザの場合も表示されます。
# 優先度が高いほど上のほうに表示されます。
# </p>
# <pre>
# $wiki-&gt;add_admin_menu(メニュー項目名,遷移するURL,優先度,詳細説明);
# </pre>
#==============================================================================
sub add_user_menu {
	my $self   = shift;
	my $label  = shift;
	my $url    = shift;
	my $weight = shift;
	my $desc   = shift;
	
	push(@{$self->{"admin_menu"}},{label=>$label,url=>$url,weight=>$weight,desc=>$desc,type=>1});
}

#==============================================================================
# <p>
# 管理者用のメニューを取得します。
# </p>
#==============================================================================
sub get_admin_menu {
	my $self = shift;
	return sort { $b->{weight}<=>$a->{weight} } @{$self->{"admin_menu"}};
}

#==============================================================================
# <p>
# プラグインをインストールします。このメソッドはwiki.cgiによってcallされます。
# プラグイン開発において通常、このメソッドを使用することはありません。
# </p>
#==============================================================================
sub install_plugin {
	my $self   = shift;
	my $plugin = shift;
	
	if ($plugin =~ /\W/) {
		return "<div class=\"error\">".Util::escapeHTML("${plugin}プラグインは不正なプラグインです。")."</div>";
	}
		
	my $module = "plugin::${plugin}::Install";
	eval 'require &Util::get_module_file($module);'.$module.'::install($self);';
	
	if($@){
		return "<div class=\"error\">".Util::escapeHTML("${plugin}プラグインがインストールできません。$@")."</div>";
	} else {
		push(@{$self->{"installed_plugin"}},$plugin);
		return "";
	}
}

#==============================================================================
# <p>
# プラグインがインストールされているかどうかを調べます。
# </p>
#==============================================================================
sub is_installed {
	my $self   = shift;
	my $plugin = shift;
	
	foreach (@{$self->{"installed_plugin"}}){
		if($_ eq $plugin){
			return 1;
		}
	}
	return 0;
}

#==============================================================================
# <p>
# メニュー項目を追加します。既に同じ名前の項目が登録されている場合は上書きします。
# 優先度が高いほど左側に表示されます。
# </p>
# <pre>
# $wiki-&gt;add_menu(項目名,URL,優先度,クロールを拒否するかどうか);
# </pre>
# <p>
# 検索エンジンにクロールさせたくない場合は第4引数に1、許可する場合は0を指定します。
# 省略した場合はクロールを許可します。
# </p>
#==============================================================================
sub add_menu {
	my $self     = shift;
	my $name     = shift;
	my $href     = shift;
	my $weight   = shift;
	my $nofollow = shift;
	
	my $flag = 0;
	foreach(@{$self->{"menu"}}){
		if($_->{name} eq $name){
			$_->{href} = $href;
			$flag = 1;
			last;
		}
	}
	if($flag==0){
		push(@{$self->{"menu"}},{name=>$name,href=>$href,weight=>$weight,nofollow=>$nofollow});
	}
}

#===============================================================================
# <p>
# フックプラグインを登録します。登録したプラグインはdo_hookメソッドで呼び出します。
# </p>
# <pre>
# $wiki-&gt;add_hook(フック名,フックプラグインのクラス名);
# </pre>
#===============================================================================
sub add_hook {
	my $self = shift;
	my $name = shift;
	my $obj  = shift;
	
	push(@{$self->{"hook"}->{$name}},$obj);
}

#===============================================================================
# <p>
# add_hookメソッドで登録されたフックプラグインを実行します。
# 引数にはフックの名前に加えて任意のパラメータを渡すことができます。
# これらのパラメータは呼び出されるクラスのhookメソッドの引数として渡されます。
# </p>
# <pre>
# $wiki-&gt;do_hook(フック名[,引数1[,引数2...]]);
# </pre>
#===============================================================================
sub do_hook {
	my $self = shift;
	my $name = shift;
	
	foreach my $class (@{$self->{"hook"}->{$name}}){
		my $obj = $self->get_plugin_instance($class);
		$obj->hook($self,$name,@_);
	}
}

#==============================================================================
# <p>
# アクションハンドラプラグインを追加します。
# リクエスト時にactionというパラメータが一致するアクションが呼び出されます。
# </p>
# <pre>
# $wiki-&gt;add_handler(actionパラメータ,アクションハンドラのクラス名);
# </pre>
#==============================================================================
sub add_handler {
	my $self   = shift;
	my $action = shift;
	my $class  = shift;
	
	$self->{"handler"}->{$action}=$class;
	$self->{"handler_permission"}->{$action} = 1;
}

#==============================================================================
# <p>
# ログインユーザ用のアクションハンドラを追加します。
# このメソッドによって追加されたアクションハンドラはログインしている場合のみ実行可能です。
# それ以外の場合はエラーメッセージを表示します。
# </p>
# <pre>
# $wiki-&gt;add_user_handler(actionパラメータ,アクションハンドラのクラス名);
# </pre>
#==============================================================================
sub add_user_handler {
	my $self   = shift;
	my $action = shift;
	my $class  = shift;
	
	$self->{"handler"}->{$action}=$class;
	$self->{"handler_permission"}->{$action} = 2;
}

#==============================================================================
# <p>
# 管理者用のアクションハンドラを追加します。
# このメソッドによって追加されたアクションハンドラは管理者としてログインしている場合のみ実行可能です。
# それ以外の場合はエラーメッセージを表示します。
# </p>
# <pre>
# $wiki-&gt;add_admin_handler(actionパラメータ,アクションハンドラのクラス名);
# </pre>
#==============================================================================
sub add_admin_handler {
	my $self   = shift;
	my $action = shift;
	my $class  = shift;
	
	$self->{"handler"}->{$action}=$class;
	$self->{"handler_permission"}->{$action} = 0;
}
#==============================================================================
# <p>
# インラインプラグインを追加します。
# </p>
# <p>
# このメソッドは3.4系との互換性を維持するために残しました。3.6で廃止するものとします。
# </p>
#==============================================================================
sub add_plugin {
	my $self   = shift;
	my $name   = shift;
	my $class  = shift;
	
	$self->add_inline_plugin($name,$class,"HTML");
}
#==============================================================================
# <p>
# インラインプラグインを登録します。プラグインの出力タイプには"WIKI"または"HTML"を指定します。
# 省略した場合は"HTML"を指定したものとみなされます。
# </p>
# <pre>
# $wiki-&gt;add_inline_plugin(プラグイン名,プラグインのクラス名,プラグインの出力タイプ);
# </pre>
#==============================================================================
sub add_inline_plugin {
	my ($self, $name, $class, $format) = @_;
	
	if($format eq ""){
		$format = "HTML";
	} else {
		$format = uc($format);
	}
	
	$self->{"plugin"}->{$name} = {CLASS=>$class,TYPE=>'inline',FORMAT=>$format};
}

#==============================================================================
# <p>
# パラグラフプラグインを登録します。プラグインの出力タイプには"WIKI"または"HTML"を指定します。
# 省略した場合は"HTML"を指定したものとみなされます。
# </p>
# <pre>
# $wiki-&gt;add_inline_plugin(プラグイン名,プラグインのクラス名,プラグインの出力タイプ);
# </pre>
#==============================================================================
sub add_paragraph_plugin {
	my ($self, $name, $class, $format) = @_;
	
	if($format eq ""){
		$format = "HTML";
	} else {
		$format = uc($format);
	}
	
	$self->{"plugin"}->{$name} = {CLASS=>$class,TYPE=>'paragraph',FORMAT=>$format};
}

#==============================================================================
# <p>
# ブロックプラグインを登録します。プラグインの出力タイプには"WIKI"または"HTML"を指定します。
# 省略した場合は"HTML"を指定したものとみなされます。
# </p>
# <pre>
# $wiki-&gt;add_block_plugin(プラグイン名,プラグインのクラス名,プラグインの出力タイプ);
# </pre>
#==============================================================================
sub add_block_plugin {
	my ($self, $name, $class, $format) = @_;
	
	if($format eq ""){
		$format = "HTML";
	} else {
		$format = uc($format);
	}
	
	$self->{"plugin"}->{$name} = {CLASS=>$class,TYPE=>'block',FORMAT=>$format};
}

#==============================================================================
# <p>
# プラグインの情報を取得します
# </p>
# <pre>
# my $info = $wiki-&gt;get_plugin_info(&quot;include&quot;);
# my $class  = $info-&gt;{CLASS};  # プラグインのクラス名
# my $type   = $info-&gt;{TYPE};   # inline、paragraph、blockのいずれか
# my $format = $info-&gt;{FORMAT}; # HTMLまたはWIKI
# </pre>
#==============================================================================
sub get_plugin_info {
	my $self = shift;
	my $name = shift;
	
	return $self->{plugin}->{$name};
}

#==============================================================================
# <p>
# add_handlerメソッドで登録されたアクションハンドラを実行します。
# アクションハンドラのdo_actionメソッドの戻り値を返します。
# </p>
# <pre>
# my $content = $wiki-&gt;call_handler(actionパラメータ);
# </pre>
#==============================================================================
sub call_handler {
	my $self   = shift;
	my $action = shift;
	
	if(!defined($action)){
		$action = "";
	}
	
	my $obj = $self->get_plugin_instance($self->{"handler"}->{$action});
	
	unless(defined($obj)){
		return $self->error("不正なアクションです。");
	}
	
	# 管理者用のアクション
	if($self->{"handler_permission"}->{$action}==0){
		my $login = $self->get_login_info();
		if(!defined($login)){
			return $self->error("ログインしていません。");
			
		} elsif($login->{type}!=0){
			return $self->error("管理者権限が必要です。");
		}
		return $obj->do_action($self).
		       "<div class=\"comment\"><a href=\"".$self->create_url({action=>"LOGIN"})."\">メニューに戻る</a></div>";
	
	# ログインユーザ用のアクション
	} elsif($self->{"handler_permission"}->{$action}==2){
		my $login = $self->get_login_info();
		if(!defined($login)){
			return $self->error("ログインしていません。");
		}
		return $obj->do_action($self).
		       "<div class=\"comment\"><a href=\"".$self->create_url({action=>"LOGIN"})."\">メニューに戻る</a></div>";
		
	# 普通のアクション
	} else {
		return $obj->do_action($self);
	}
}

#===============================================================================
# <p>
# 引数で渡したWikiフォーマットの文字列をHTMLに変換して返します。
# </p>
# <pre>
# my $html = $wiki-&gt;process_wiki(文字列);
# </pre>
#===============================================================================
sub process_wiki {
	my $self    = shift;
	my $source  = shift;
	my $mainflg = shift;
	
	if($self->{parse_times} >= 50){
		return $self->error("Wiki::process_wikiの呼び出し回数が上限を越えました。");
	}
	
	$self->{parse_times}++;
	my $parser = Wiki::HTMLParser->new($self,$mainflg);
	$parser->parse($source);
	$self->{parse_times}--;
	
	return $parser->{html};
}

#===============================================================================
# <p>
# インラインプラグイン、パラグラフプラグインの呼び出し（内部処理用の関数）。
# 初期のメソッドのため命名規則（privateメソッドのメソッド名は_から始める）
# に従っていません。
# </p>
#===============================================================================
sub process_plugin {
	my $self   = shift;
	my $plugin = shift;
	my $parser = shift;
	
	if(defined($plugin->{error}) && $plugin->{error} ne ""){
		return "<font class=\"error\">".$plugin->{error}."</font>";
	}

	my $name = $plugin->{command};
	my @args = @{$plugin->{args}};
	my $info = $self->get_plugin_info($name);
	my $obj  = $self->get_plugin_instance($info->{CLASS});

	if(!defined($obj)){
		return "<font class=\"error\">".&Util::escapeHTML($name)."プラグインは存在しません。</font>";
		
	} else {
		if($info->{FORMAT} eq "WIKI"){
			# 裏技用(プラグイン内部からパーサを使う場合)
			push(@{$self->{'current_parser'}}, $parser);
			if($info->{TYPE} eq "inline"){
				my @result = $parser->parse_line($obj->inline($self,@args));
				pop(@{$self->{'current_parser'}});
				return @result;
			} elsif($info->{TYPE} eq "paragraph"){
				$parser->parse($obj->paragraph($self,@args));
			} else {
				$parser->parse($obj->block($self,@args));
			}
			# パーサの参照を解放
			pop(@{$self->{'current_parser'}});
			return undef;
		} else {
			if($info->{TYPE} eq "inline"){
				return $obj->inline($self,@args);
			} elsif($info->{TYPE} eq "paragraph"){
				return $obj->paragraph($self,@args);
			} else {
				return $obj->block($self,@args);
			}
		}
	}
}

#==============================================================================
# <p>
# パース中の場合、現在有効なWiki::Parserのインスタンスを返却します。
# パース中の内容をプラグインから変更したい場合に使用します。
# </p>
#==============================================================================
sub get_current_parser {
	my $self = shift;
	my @parsers = @{$self->{'current_parser'}};
	return $parsers[$#parsers];
}

#==============================================================================
# <p>
# エラーの場合、呼び出します。
# アクションハンドラからエラーを報告する際に使用してください。
# </p>
# <pre>
# sub do_action {
#   my $self = shift;
#   my $wiki = shift;
#   ...
#   return $wiki-&gt;error(エラーメッセージ);
# }
# </pre>
#==============================================================================
sub error {
	my $self    = shift;
	my $message = shift;
	
	$self->set_title("エラー");
	$self->get_CGI->param("action","ERROR");
	
	return "<div class=\"error\">".Util::escapeHTML($message)."</div>";
}

#===============================================================================
# <p>
# プラグインのインスタンスを取得します。Wiki.pmで内部的に使用されるメソッドです。
# プラグイン開発において通常、このメソッドを使用する必要はありません。
# </p>
#===============================================================================
sub get_plugin_instance {
	my $self  = shift;
	my $class = shift;
	
	if($class eq ""){
		return undef;
	}
	
	if(!defined($self->{instance}->{$class})){
		eval {
			require &Util::get_module_file($class);
		};
		return undef if $@;
		my $obj = $class->new();
		$self->{instance}->{$class} = $obj;
		
		return $obj;
	} else {
		return $self->{instance}->{$class};
	}
}

#===============================================================================
# <p>
# インラインプラグインをパースしてコマンドと引数に分割します。
# </p>
#===============================================================================
sub parse_inline_plugin {
	my $self = shift;
	my $text = shift;
	my ($cmd, @args_tmp) = split(/ /,$text);
	my $args_txt = &Util::trim(join(" ",@args_tmp));
	if($cmd =~ s/}}(.*?)$//){
		return { command=>$cmd, args=>[], post=>"$1 $args_txt"};
	}
	
	my @ret_args;
	my $tmp    = "";
	my $escape = 0;
	my $quote  = 0;
	my $i      = 0;
	
	for($i = 0; $i<length($args_txt); $i++){
		my $c = substr($args_txt,$i,1);
		if($quote!=1 && $c eq ","){
			if($quote==3){
				$tmp .= '}';
			}
			push(@ret_args,$tmp);
			$tmp = "";
			$quote = 0;
		} elsif($quote==1 && $c eq "\\"){
			if($escape==0){
				$escape = 1;
			} else {
				$tmp .= $c;
				$escape = 0;
			}
		} elsif($quote==0 && $c eq '"'){
			if($tmp eq ""){
				$quote = 1;
			} else {
				$tmp .= $c;
			}
		} elsif($quote==1 && $c eq '"'){
			if($escape==1){
				$tmp .= $c;
				$escape = 0;
			} else {
				$quote = 2;
			}
		} elsif(($quote==0 || $quote==2) && $c eq '}'){
			$quote = 3;
		} elsif($quote==3){
			if($c eq '}'){
				last;
			} else {
				$tmp .= '}'.$c;
				$quote = 0;
			}
		} elsif($quote==2){
			return {error=>"インラインプラグインの構文が不正です。"};
		} else {
			$tmp .= $c;
			$escape = 0;
		}
	}
	
	if($quote!=3){
		my $info = $self->get_plugin_info($cmd);
		return undef if (defined($info->{TYPE}) && $info->{TYPE} ne 'block');
	}
	
	if($tmp ne ""){
		push(@ret_args,$tmp);
	}
	
	return { command=>$cmd, args=>\@ret_args, 
		post=>substr($args_txt, $i + 1, length($args_txt) - $i)};
}

#==============================================================================
# <p>
# フォーマットプラグインを追加します。
# フォーマットプラグインはconvert_to_fswikiメソッドとconvert_from_fswikiメソッドを
# 実装したクラスでなくてはなりません。
# </p>
# <pre>
# $wiki-&gt;add_format_plugin(文法名,クラス名);
# </pre>
#==============================================================================
sub add_format_plugin {
	my $self  = shift;
	my $name  = shift;
	my $class = shift;
	
	$self->{'format'}->{$name} = $class;
}

#==============================================================================
# <p>
# インストールされているフォーマットプラグインの一覧を取得します。
# </p>
# <pre>
# my @formats = $wiki-&gt;get_format_names();
# </pre>
#==============================================================================
sub get_format_names {
	my $self = shift;
	my @list = keys(%{$self->{'format'}});
	if(!scalar(@list)){
		push(@list, "FSWiki");
	}
	return sort(@list);
}

#==============================================================================
# <p>
# 各Wiki書式で記述したソースをFSWikiの書式に変換します。
# </p>
# <pre>
# $source = $wiki-&gt;convert_to_fswiki($source,&quot;YukiWiki&quot;);
# </pre>
# <p>
# インライン書式のみ変換を行う場合は第三引数に1を渡します。
# </p>
# <pre>
# $source = $wiki-&gt;convert_to_fswiki($source,&quot;YukiWiki&quot;,1);
# </pre>
#==============================================================================
sub convert_to_fswiki {
	my $self   = shift;
	my $source = shift;
	my $type   = shift;
	my $inline = shift;
	
	my $obj = $self->get_plugin_instance($self->{'format'}->{$type});
	unless(defined($obj)){
		return $source;
	} else {
		$source =~ s/\r\n/\n/g;
		$source =~ s/\r/\n/g;
		if($inline){
			return $obj->convert_to_fswiki_line($source);
		} else {
			return $obj->convert_to_fswiki($source);
		}
	}
}

#==============================================================================
# <p>
# FSWikiの書式で記述したソースを各Wikiの書式に変換します。
# </p>
# <pre>
# $source = $wiki-&gt;convert_from_fswiki($source,&quot;YukiWiki&quot;);
# </pre>
# <p>
# インライン書式のみ変換を行う場合は第三引数に1を渡します。
# </p>
# <pre>
# $source = $wiki-&gt;convert_from_fswiki($source,&quot;YukiWiki&quot;,1);
# </pre>
#==============================================================================
sub convert_from_fswiki {
	my $self   = shift;
	my $source = shift;
	my $type   = shift;
	my $inline = shift;
	
	my $obj = $self->get_plugin_instance($self->{'format'}->{$type});
	unless(defined($obj)){
		return $source;
	} else {
		$source =~ s/\r\n/\n/g;
		$source =~ s/\r/\n/g;
		if($inline){
			return $obj->convert_from_fswiki_line($source);
		} else {
			return $obj->convert_from_fswiki($source);
		}
	}
}

#==============================================================================
# <p>
# 現在のユーザが編集に使用するフォーマットを取得します。
# formatプラグインがアクティベートされていない場合は常に"FSWiki"を返します。
# </p>
# <pre>
# my $format = $wiki-&gt;get_edit_format();
# </pre>
#==============================================================================
sub get_edit_format {
	my $self = shift;
	my $from = shift;
	
	# formatプラグインがアクティベートされていなければFSWikiフォーマットを返す
	unless($self->is_installed("format")){
		return "FSWiki";
	}

	#通常は環境設定画面で設定したWikiフォーマットを使用
	my $config = &Util::load_config_hash($self, $self->config('config_file'));
	my $format = $config->{site_wiki_format};

	# Cookieにフォーマットが指定されている場合はそちらを使用
	#(但し、config.datファイルからの取得指定時はCookieを無視)
	if($from ne "config"){
		my $cgi = $self->get_CGI();
		if($cgi->cookie(-name=>'edit_format') ne ""){
			$format = $cgi->cookie(-name=>'edit_format');
		}
	}

	if($format eq ""){
		return "FSWiki";
	} else {
		return $format;
	}
}

#==============================================================================
# <p>
# headタグ内に出力する情報を追加します。
# ただしサイトテンプレートが対応している必要があります。
# </p>
# <pre>
# $wiki-&gt;add_head_info(&quot;<link rel=\&quot;alternate\&quot; type=\&quot;application/rss+xml\&quot; title=\&quot;RSS\&quot; href=\&quot;?action=RSS\&quot;>&quot;);
# </pre>
#==============================================================================
sub add_head_info {
	my $self = shift;
	my $info = shift;
	
	push(@{$self->{'head_info'}},$info);
}

###############################################################################
#
# 凍結に関するメソッド群
#
###############################################################################
#==============================================================================
# <p>
# ページを凍結します
# </p>
# <pre>
# $wiki-&gt;freeze_page(ページ名);
# </pre>
#==============================================================================
sub freeze_page {
	my $self = shift;
	$self->{"storage"}->freeze_page(@_);
}

#==============================================================================
# <p>
# ページの凍結を解除します
# </p>
# <pre>
# $wiki-&gt;un_freeze_page(ページ名);
# </pre>
#==============================================================================
sub un_freeze_page {
	my $self = shift;
	$self->{"storage"}->un_freeze_page(@_);
}

#==============================================================================
# <p>
# 凍結されているページのリストを取得します。
# </p>
#==============================================================================
sub get_freeze_list {
	my $self = shift;
	return $self->{"storage"}->get_freeze_list();
}

#==============================================================================
# <p>
# 引数で渡したページが凍結中かどうかしらべます
# </p>
# <pre>
# if($wiki-&gt;is_freeze(ページ名)){
#   ...
# }
# </pre>
#==============================================================================
sub is_freeze {
	my $self = shift;
	my $page = shift;
	my $path = undef;
	
	if($page =~ /(^.*?[^:]):([^:].*?$)/){
		$path = $1;
		$page = $2;
	}
	
	return $self->{storage}->is_freeze($page,$path);
}

#==============================================================================
# <p>
# 引数で渡したページが編集可能かどうかを調べます。
# 編集不可モード（setup.plで$accept_editが0に設定されている場合）はログインしていれば編集可能、
# ページが凍結されている場合は管理者ユーザでログインしている場合に編集可能となります。
# </p>
# <pre>
# if($wiki-&gt;can_modify_page(ページ名)){
#   ...
# }
# </pre>
#==============================================================================
sub can_modify_page {
	my $self = shift;
	my $page = shift;
	my $login = $self->get_login_info();
	if($self->config('accept_edit')==0 && !defined($login)){
		return 0;
	}
	if($self->config('accept_edit')==2 && (!defined($login) || $login->{type}!=0)){
		return 0;
	}
	if($self->is_freeze($page) && (!defined($login) || $login->{type}!=0)){
		return 0;
	}
	unless($self->can_show($page)){
		return 0;
	}
	return 1;
}

###############################################################################
#
# 参照権限に関するメソッド群
#
###############################################################################
#==============================================================================
# <p>
# ページの参照レベルを設定します。
# <p>
# <ul>
#   <li>0 - 全員に公開</li>
#   <li>1 - ユーザに公開</li>
#   <li>2 - 管理者に公開</li>
# </ul>
# <pre>
# $wiki-&gt;set_page_level(ページ名,公開レベル);
# </pre>
#==============================================================================
sub set_page_level {
	my $self  = shift;
	my $page  = shift;
	my $level = shift;

	$self->{"storage"}->set_page_level($page,$level);

	# $level が未定義ならページデータ削除なので、フック関連処理不要。
	return if (not defined $level);

	# 処理の成否を検査。
	my $new_level = $self->get_page_level($page);
	if ($new_level != $level) {
		die "ページ '$page' の参照権限レベルを '$level' に変更しようとしましたが失敗しました。";
	}

	# ページレベルの変更に成功したので、フックを発行。
	$self->do_hook('change_page_level', $page, $new_level);
}

#==============================================================================
# <p>
# ページの参照レベルを取得します。
# ページ名が指定されていない場合、全てのページの参照レベルを
# ハッシュリファレンスで返します。
# </p>
# <ul>
#   <li>0 - 全員に公開</li>
#   <li>1 - ユーザに公開</li>
#   <li>2 - 管理者に公開</li>
# </ul>
# <pre>
# my $level = $get_page_level(ページ名);
# </pre>
#==============================================================================
sub get_page_level {
	my $self  = shift;
	my $page  = shift;
	my $path  = undef;
	
	if($page =~ /(^.*?[^:]):([^:].*?$)/){
		$path = $1;
		$page = $2;
	}
	
	$self->{"storage"}->get_page_level($page,$path);
}

#==============================================================================
# <p>
# 現在のユーザ権限で閲覧可能なページレベルの上限値を求めます。
# </p>
# <pre>
# my $can_show_max = $wiki-&gt;_get_can_show_max();
# </pre>
#==============================================================================
sub _get_can_show_max {
	my $self = shift;

	# 「閲覧可能な page level の上限値」が既知ならば、それを返却。
	if (exists $self->{'can_show_max'}) {
		return $self->{'can_show_max'};
	}

	# Wiki 全体の閲覧権限の設定値と、閲覧者のユーザ権限レベルを求める。
	my $accept_show = $self->config('accept_show'); # Wiki 全体の閲覧権限
	my $login_user  = $self->get_login_info();      # 現在の login 情報
	my $user_level                                  # ユーザ権限レベル
		= (not defined $login_user)  ? 0            #   非ログインユーザ
		: ($login_user->{type} != 0) ? 1            #   ログインユーザ
		:                              2;           #   管理者

	# Wiki 全体の閲覧権限に達しているユーザなら、
	if ($user_level >= $accept_show) {
		# 「閲覧可能な page level 上限値」は、ユーザ権限レベルに等しい。
		return $self->{'can_show_max'} = $user_level;
	}

	# Wiki 全体の閲覧権限に達していないユーザなので、
	# 「閲覧可能な page level 上限値」は -1。すなわち、全ページ閲覧不可。
	return $self->{'can_show_max'} = -1;
}

#==============================================================================
# <p>
# ページが参照可能かどうかを取得します。
# </p>
# <pre>
# if($wiki-&gt;can_show(ページ名)){
#   # 参照可能
# } else {
#   # 参照不可能
# }
# </pre>
#==============================================================================
sub can_show {
	my ($self, $page) = @_;

	#「閲覧可能 page level 上限」が未知ならば、求める。
	if (not exists $self->{'can_show_max'}) {
		$self->_get_can_show_max();
	}

	# page level が、閲覧可能 page level 上限以下なら真を返す。
	return ($self->get_page_level($page) <= $self->{'can_show_max'});
}

###############################################################################
#
# その他のメソッド群
#
###############################################################################
#==============================================================================
# <p>
# ページにジャンプするためのURLを生成するユーティリティメソッドです。
# 引数としてページ名を渡します。
# </p>
# <pre>
# $wiki-&gt;create_page_url(&quot;FrontPage&quot;);
# </pre>
# <p>
# 上記のコードは通常、以下のURLを生成します。
# </p>
# <pre>
# wiki.cgi?page=FrontPage
# </pre>
#==============================================================================
sub create_page_url {
	my $self = shift;
	my $page = shift;
	return $self->create_url({page=>$page});
}

#==============================================================================
# <p>
# 任意のURLを生成するためのユーティリティメソッドです。
# 引数としてパラメータのハッシュリファレンスを渡します。
# </p>
# <pre>
# $wiki-&gt;create_url({action=>HOGE,type=>1});
# </pre>
# <p>
# 上記のコードは通常、以下のURLを生成します。
# </p>
# <pre>
# wiki.cgi?action=HOGE&amp;type=1
# </pre>
#==============================================================================
sub create_url {
	my $self   = shift;
	my $params = shift;
	my $url    = $self->config('script_name');
	my $query  = '';
	foreach my $key (keys(%$params)){
		if($query ne ''){
			$query .= '&amp;';
		}
		$query .= Util::url_encode($key)."=".Util::url_encode($params->{$key});
	}
	if($query ne ''){
		$url .= '?'.$query; 
	}
	return $url;
}

#==============================================================================
# <p>
# アクションハンドラ中でタイトルを設定する場合に使用します。
# </p>
# <pre>
# $wiki-&gt;set_title(タイトル[,編集系のページがどうか]);
# </pre>
# <p>
# 編集系の画面の場合、第二引数に1を指定してください。
# ロボット対策用に以下のMETAタグが出力されます。
# </p>
# <pre>
# &lt;meta name=&quot;ROBOTS&quot; content=&quot;NOINDEX, NOFOLLOW&quot;&gt;
# </pre>
#==============================================================================
sub set_title {
	my $self  = shift;
	my $title = shift;
	my $edit  = shift;
	$self->{"title"} = $title;
	$self->{"edit"}  = 1 if $edit;
}

#==============================================================================
# <p>
# タイトルを取得します。
# </p>
#==============================================================================
sub get_title {
	my $self = shift;
	return $self->{"title"};
}

#==============================================================================
# <p>
# ページの一覧を取得します。
# 引数としてハッシュリファレンスを渡すことで取得内容を指定することが可能。
# デフォルトでは全てのページを名前でソートしたリストを返却する。
# </p>
# <p>
# 以下の例は参照権のあるページのみ取得し、更新日時でソートする。
# </p>
# <pre>
# my @list = $wiki-&gt;get_page_list({-sort   => 'last_modified',
#                                  -permit => 'show'});
# </pre>
# <p>
# 以下の例は全てのページを取得し、名前でソートする。
# </p>
# <pre>
# my @list = $wiki-&gt;get_page_list({-sort => 'name'});
# </pre>
# <p>
# 以下の例は最新の10件を取得する。
# </p>
# <pre>
# my @list = $wiki-&gt;get_page_list({-sort=>'last_modified',-max=>10});
# </pre>
#==============================================================================
sub get_page_list {
	my $self = shift;
	my $args = shift;
	
	return $self->{"storage"}->get_page_list($args);

}

#==============================================================================
# <p>
# ページの物理的な（データファイルの更新日時）最終更新時刻を取得します。
# </p>
# <pre>
# my $modified = $wiki-&gt;get_last_modified(ページ名);
# </pre>
#==============================================================================
sub get_last_modified {
	my $self = shift;
	return $self->{"storage"}->get_last_modified(@_);
}

#==============================================================================
# <p>
# ページ論理的な最終更新時刻を取得します。
# 「タイムスタンプを更新しない」にチェックを入れてページを保存した場合は
# このメソッドで返される日時は保存前のものになります。
# </p>
# <pre>
# my $modified = $wiki-&gt;get_last_modified2(ページ名);
# </pre>
#==============================================================================
sub get_last_modified2 {
	my $self = shift;
	return $self->{"storage"}->get_last_modified2(@_);
}

#==============================================================================
# <p>
# ページのソースを取得します。
# </p>
# <p>
# 第三引数にフォーマット名を渡した場合のみ、フォーマットプラグインによる
# ソースの変換を行います。それ以外の場合は必要に応じてプラグイン側で
# Wiki::convert_from_fswikiメソッドを呼んで変換を行います。
# </p>
#==============================================================================
sub get_page {
	my $self   = shift;
	my $page   = shift;
	my $format = shift;
	my $path   = undef;
	
	if($page =~ /(^.*?[^:]):([^:].*?$)/){
		$path = $1;
		$page = $2;
	}
	
	my $content = $self->{"storage"}->get_page($page,$path);
	
	if($format eq "" || $format eq "FSWiki"){
		return $content;
	} else {
		return $self->convert_from_fswiki($content,$format);
	}
}

#==============================================================================
# <p>
# バックアップされたソースを取得します。バックアップが存在しない場合は空文字列を返します。
# 世代バックアップに対応したストレージを使用している場合は第二引数に取得する世代を指定することができます。
# </p>
# <pre>
# # 世代バックアップを使用していない場合
# my $backup = $wiki-&gt;get_backup(ページ名);
#
# # 世代バックアップを使用している場合
# my $backup = $wiki-&gt;get_backup(ページ名,世代);
# </pre>
# <p>
# 世代は古いものから順に0〜の数値で指定します。
# </p>
#==============================================================================
sub get_backup {
	my $self = shift;
	return $self->{"storage"}->get_backup(@_);
}

#==============================================================================
# <p>
# ページを保存します。
# キャッシュモードONで利用している場合、ページのキャッシュも削除されます。
# </p>
# <pre>
# $wiki-&gt;save_page(ページ名,ページ内容);
# </pre>
# <p>
# フォーマットプラグインによるフォーマットの変換は行われません。
# つまり、フォーマットプラグインを使用している場合、このメソッドに渡す
# Wikiソースは事前にFSWiki形式に変換されたソースでなければなりません。
# </p>
# <p>
# 保存時にタイムスタンプを更新しない場合、第三引数に1を渡します。
# </p>
# <pre>
# $wiki-&gt;save_page(ページ名,ページ内容,1);
# </pre>
#
#==============================================================================
sub save_page {
	my $self     = shift;
	my $pagename = shift;
	my $content  = shift;
	my $sage     = shift;
	
	# ページ名をチェック
	if($pagename =~ /([\|\[\]])|^:|([^:]:[^:])/){
		die "ページ名に使用できない文字が含まれています。";
	}
	# いったんパラメータを上書き
	$self->get_CGI->param("page"   ,$pagename);
	$self->get_CGI->param("content",$content);
	$self->do_hook("save_before");
	# パラメータを読み込み直す
	$content = $self->get_CGI()->param("content");
	
	if($self->{"storage"}->save_page($pagename,$content,$sage)){
		if($content ne ""){
			$self->do_hook("save_after");
		} else {
			$self->do_hook("delete");
		}
	}
}

#===============================================================================
# <p>
# ページが存在するかどうか調べます。
# </p>
# <pre>
# if($wiki-&gt;page_exists(ページ名)){
#   # ページが存在する場合の処理
# } else {
#   # ページが存在しない場合の処理
# }
# </pre>
#===============================================================================
sub page_exists {
	my $self = shift;
	my $page = shift;
	my $path = undef;
	
	if($page =~ /(^.*?[^:]):([^:].*?$)/){
		$path = $1;
		$page = $2;
	}
	
	# InterWiki形式の指定でドットを含むことはできない
	if(defined($path) && index($path,".")!=-1){
		return 0;
	}
	
	return $self->{"storage"}->page_exists($page,$path);
}

#===============================================================================
# <p>
# CGIオブジェクトを取得
# </p>
# <pre>
# my $cgi = $wiki-&gt;get_CGI;
# </pre>
#===============================================================================
sub get_CGI {
	my $self = shift;
	return $self->{"CGI"};
}

#==============================================================================
# <p>
# 引数で渡したページにリダイレクトします。
# ページの保存後にページを再表示する場合はこのメソッドを使用して下さい。
# なお、このメソッドを呼び出すとそこでスクリプトの実行は終了し、呼び出し元に制御は戻りません。
# </p>
# <pre>
# $wiki-&gt;redirect(&quot;FrontPage&quot;);
# </pre>
# <p>
# 第二引数にパート番号を渡すとそのパートにリダイレクトします。
# </p>
# <pre>
# $wiki-&gt;redirect(&quot;FrontPage&quot;, 1);
# </pre>
#
#==============================================================================
sub redirect {
	my $self = shift;
	my $page = shift;
	my $part = shift;
	my $url = $self->create_page_url($page);
	if($part ne ""){
		$url .= "#p".Util::url_encode($part);
	}
	$self->redirectURL($url);
}

#==============================================================================
# <p>
# 指定のURLにリダイレクトします。
# このメソッドを呼び出すとそこでスクリプトの実行は終了し、呼び出し元に制御は戻りません。
# </p>
# <pre>
# $wiki-&gt;redirectURL(リダイレクトするURL);
# </pre>
#==============================================================================
sub redirectURL {
	my $self = shift;
	my $url  = shift;
	
	# Locationタグでリダイレクト
	if($self->config('redirect')==1){
		my ($hoge,$param) = split(/\?/,$url);
		$url = $self->get_CGI->url().$self->get_CGI()->path_info();
		if($param ne ''){
			$url = "$url?$param";
		}
		print "Location: $url\n\n";
		
	# METAタグでリダイレクト
	} else {
		my $tmpl = HTML::Template->new(filename=>$self->config('tmpl_dir')."/redirect.tmpl",
		                               die_on_bad_params => 0);
		
		$tmpl->param(URL=>$url);
		
		print "Content-Type: text/html\n\n";
		print $tmpl->output();
	}
	exit();
}

#==============================================================================
# <p>
# グローバル設定を取得もしくは変更します
# </p>
# <pre>
# # データファイルを格納するディレクトリ
# my $data_dir = $wiki-&gt;config('data_dir');
#
# # 設定を$data_dirで上書き
# $wiki-&gt;config('data_dir',$data_dir);
# </pre>
#==============================================================================
sub config {
	my $self  = shift;
	my $name  = shift;
	my $value = shift;
	if(defined($value)){
		$self->{config}->{$name} = $value;
	} else {
		return $self->{config}->{$name};
	}
}
###############################################################################
#
# Farm関係のメソッド群
#
###############################################################################
#==============================================================================
# <p>
# Farm機能が有効になっているかどうかを取得します
# </p>
# <pre>
# if($wiki-&gt;farm_is_enable()){
#   # Farmが有効になっているときの処理
# } else {
#   # Farmが無効になっているときの処理
# }
# </pre>
#==============================================================================
sub farm_is_enable {
	my $self = shift;
	my $farm_config = &Util::load_config_hash($self,$self->config('farmconf_file'));
	if(defined $farm_config->{usefarm} and $farm_config->{usefarm}==1){
		return 1;
	} else {
		return 0;
	}
}

#==============================================================================
# <p>
# 子Wikiを作成します。引数にはWikiの名前、作成するWikiサイトの管理者ID、パスワードを渡します。
# このメソッド内ではWikiサイト名のバリデーションや重複チェックは行われません。
# 事前に行う必要があります。このメソッドはfarmプラグインを使用している場合のみ使用可能です。
# </p>
# <pre>
# $wiki-&gt;create_wiki(Wikiサイト名,管理者ID,パスワード);
# </pre>
#==============================================================================
sub create_wiki{
	my $self  = shift;
	my $child = shift;
	my $id    = shift;
	my $pass  = shift;
	
	# data、backupディレクトリを掘る処理はStorageに任せたほうがいいかな？
	unless($self->wiki_exists($child)){
		eval {
			# コアでサポートするディレクトリを掘る
			mkpath($self->config('data_dir'  )."/$child") or die $!;
			mkpath($self->config('backup_dir')."/$child") or die $!;
			mkpath($self->config('config_dir')."/$child") or die $!;
			mkpath($self->config('log_dir'   )."/$child") or die $!;
			
			# 設定のコピー
			copy($self->config('config_dir')."/".$self->config('config_file'),
			     $self->config('config_dir')."/$child/".$self->config('config_file')) or die $!;
			copy($self->config('config_dir')."/".$self->config('usercss_file'),
			     $self->config('config_dir')."/$child/".$self->config('usercss_file')) or die $!;
			copy($self->config('config_dir')."/".$self->config('plugin_file'),
			     $self->config('config_dir')."/$child/".$self->config('plugin_file')) or die $!;
			copy($self->config('config_dir')."/".$self->config('mime_file'),
			     $self->config('config_dir')."/$child/".$self->config('mime_file')) or die $!;
			
			# 管理ユーザの作成（ここで作るのはちょっとアレかも・・・）
			open(USERDAT,">".$self->config('config_dir')."/$child/".$self->config('userdat_file')) or die $!;
			print USERDAT "$id=".&Util::md5($pass,$id)."\t0\n";
			close(USERDAT);
			
			# テンプレートからページのコピー
			my $farm_config = &Util::load_config_hash($self,$self->config('farmconf_file'));
			if($farm_config->{'use_template'}==1 && $child ne "template"){
				my $template = $self->config('data_dir')."/template";
				my $depth = $self->_get_wiki_depth();
				my $count = 0;
				while((!(-e $template) || !(-d $template)) && $count < $depth && $farm_config->{'search_parent'}==1){
					$template =~ s/\/template$//;
					$template = $template."/../template";
					$count++;
				}
				if(-e $template && -d $template){
					opendir(DIR,$template) or die $!;
					while(my $entry = readdir(DIR)){
						if($entry =~ /\.wiki$/){
							copy($template."/$entry",$self->config('data_dir')."/$child/$entry");
						}
					}
					closedir(DIR);
				}
			}
			# create_wikiフックの呼び出し
			$self->do_hook("create_wiki");
		};
		
		# エラーが発生した場合クリーンアップ処理
		if($@){
			my $error = $@;
			# ここはエラーが出ても続行
			eval {
				$self->remove_wiki("/$child");
			};
			die "$childの作成に失敗しました。発生したエラーは以下のとおりです。\n\n$error";
		}
	}
}

#==============================================================================
# <p>
# 現在のWikiの階層を返却します。ルートの場合は0、子Wikiの場合は1、
# 孫Wikiの場合は2…というようになります。
# </p>
#==============================================================================
sub _get_wiki_depth {
	my $self = shift;
	my $path_info = $self->get_CGI()->path_info();
	$path_info =~ s/^\///;
	my $depth = split(/\//,$path_info);
	return $depth;
}

#==============================================================================
# <p>
# 子Wikiを削除します。引数には削除するWikiサイトのパス（PATH_INFO部分）を渡します。
# このメソッドはfarmプラグインを使用している場合のみ使用可能です。
# </p>
# <pre>
# $wiki-&gt;remove_wiki(Wikiサイトのパス);
# </pre>
#==============================================================================
sub remove_wiki {
	my $self = shift;
	my $path = shift;
	
	# コアでサポートするディレクトリを削除
	rmtree($self->config('data_dir'  ).$path) or die $!;
	rmtree($self->config('backup_dir').$path) or die $!;
	rmtree($self->config('config_dir').$path) or die $!;
	rmtree($self->config('log_dir'   ).$path) or die $!;
	
	# remove_wikiフックの呼び出し
	$self->get_CGI()->param('path',$path);
	$self->do_hook("remove_wiki");
}

#==============================================================================
# <p>
# 引数で渡した名称の子Wikiが存在するかどうかを調べます。
# このメソッドはfarmプラグインを使用している場合のみ使用可能です。
# </p>
# <pre>
# $wiki-&gt;wiki_exists(Wikiサイト名);
# </pre>
#==============================================================================
sub wiki_exists{
	my $self  = shift;
	my $child = shift;
	return ($child =~ /[A-Za-z0-9]+(\/[A-Za-z0-9]+)*/
			and -d $self->config('data_dir')."/$child");
}

#==============================================================================
# <p>
# 子Wikiを配列で取得します。孫Wiki、曾孫Wikiは配列のリファレンスとして格納されています。
# </p>
#==============================================================================
sub get_wiki_list{
	my $self = shift;
	if($self->farm_is_enable){
		my @list = $self->search_child($self->config('config_dir'));
		return @list;
	} else {
		return ();
	}
}

#==============================================================================
# <p>
# 子Wikiのツリーを配列で取得します。
# ネストしたWikiは配列リファレンスで格納します。
# </p>
#==============================================================================
sub search_child {
	my $self = shift;
	my $dir  = shift;
	my @dirs = ();
	my @list = ();
	
	opendir(DIR,$dir) or die $!;
	while(my $entry = readdir(DIR)){
		if(-d "$dir/$entry" && $entry ne "." && $entry ne ".."){
			push(@dirs,$entry);
		}
	}
	closedir(DIR);
	@dirs = sort @dirs;
	
	foreach my $entry (@dirs){
		push(@list,$entry);
		my @child = $self->search_child("$dir/$entry");
		if($#child>-1){
			push(@list,\@child);
		}
	}
	
	return @list;
}

#==============================================================================
# <p>
# 終了前の処理。
# </p>
#==============================================================================
sub _process_before_exit {
	my $self = shift;
	# プラグイン用のフック
	$self->do_hook('finalize');
	# finalizeメソッドの呼び出し
	$self->get_CGI()->finalize();
	$self->{storage}->finalize();
}

1;
