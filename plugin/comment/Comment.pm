############################################################
# 
# <p>１行コメントを書き込むためのフォームを出力します。</p>
# <pre>
# {{comment}}
# </pre>
# <p>
#   通常、コメントは投稿フォームの下に追加されていきますが、
#   オプションでフォームの上に新着順表示するようにできます。
# </p>
# <pre>
# {{comment reverse}}
# </pre>
# <p>
#   tailオプションをつけるとページの最後にコメントを追加します。
#   フッタなどにcommentプラグインを配置して全ページにコメントを
#   つけたい場合に有効です。
# </p>
# <pre>
# {{comment tail}}
# </pre>
# 
############################################################
package plugin::comment::Comment;
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
# コメントフォーム
#===========================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $opt  = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $page = $cgi->param("page");
	
	if(!defined($self->{$page})){
		$self->{$page} = 1;
	} else {
		$self->{$page}++;
	}
	
	# 名前を取得
	my $name = $cgi->cookie(-name=>'post_name');
	if($name eq ''){
		my $login = $wiki->get_login_info();
		if(defined($login)){
			$name = $login->{id};
		}
	}
	
	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/comment.tmpl",
	                               die_on_bad_params=>0);
	$tmpl->param(NAME=>$name);
	
	my $buf = "<form method=\"post\" action=\"".$wiki->create_url()."\">\n".
	          $tmpl->output().
	          "<input type=\"hidden\" name=\"action\" value=\"COMMENT\">\n".
	          "<input type=\"hidden\" name=\"page\" value=\"".&Util::escapeHTML($page)."\">\n".
	          "<input type=\"hidden\" name=\"count\" value=\"".$self->{$page}."\">\n".
	          "<input type=\"hidden\" name=\"option\" value=\"".&Util::escapeHTML($opt)."\">\n".
	          "</form>\n";
	
	return $buf;
}

1;
