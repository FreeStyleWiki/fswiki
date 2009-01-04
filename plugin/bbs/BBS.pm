###############################################################################
#
# <p>掲示版風の投稿フォームを出力します。</p>
# <pre>
# {{bbs}}
# </pre>
# <p>
#   プラグインを記述した場所に掲示版風の投稿フォームを表示します。
#   フォームからの投稿内容はそのページに追加されます。
# </p>
# <p>
#   デフォルトでは各投稿記事に返信用のコメントフォームが出力されますが、
#   no_commentオプションをつけるとOFFにすることができます。
# </p>
# <pre>
# {{bbs no_comment}}
# </pre>
# <p>
#   reverse_commentオプションをつけると各記事につくcommentプラグインに
#   reverseオプションをつけることができ、コメントが新着順表示されるようになります。
# </p>
# <pre>
# {{bbs reverse_comment}}
# </pre>
#
###############################################################################
package plugin::bbs::BBS;
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
# 掲示板入力フォーム
#==============================================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $option = shift;
	my $cgi    = $wiki->get_CGI;
	
	my $page = $cgi->param("page");
	if($page eq ""){
		return "";
	}
	
	if(!defined($self->{$page})){
		$self->{$page} = 1;
	} else {
		$self->{"count"}++;
	}
	
	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/bbs.tmpl",
	                               die_on_bad_params=>0);
	
	# 名前を取得
	my $name = $cgi->cookie(-name=>'post_name');
	if($name eq ''){
		my $login = $wiki->get_login_info();
		if(defined($login)){
			$name = $login->{id};
		}
	}
	$tmpl->param(NAME=>$name);
	
	my $buf = "<form method=\"post\" action=\"".$wiki->create_url()."\">\n".
	          $tmpl->output.
	          "<input type=\"hidden\" name=\"action\" value=\"BBS\">\n".
	          "<input type=\"hidden\" name=\"page\" value=\"".&Util::escapeHTML($page)."\">\n".
	          "<input type=\"hidden\" name=\"count\" value=\"".$self->{$page}."\">\n";
	
	if($option eq "no_comment"){
		$buf .="<input type=\"hidden\" name=\"option\" value=\"no_comment\">\n";
	} elsif($option eq "reverse_comment"){
		$buf .="<input type=\"hidden\" name=\"option\" value=\"reverse_comment\">\n";
	}
	return $buf."</form>";
}

1;
