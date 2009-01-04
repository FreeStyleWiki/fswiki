###############################################################################
#
# <p>掲示版風の投稿フォームを出力します。１件の投稿が１ページとなり、ページ処理もサポートします。</p>
# <pre>
# {{bbs2 掲示板の名前,表示件数}}
# </pre>
# <p>
#   bbsプラグインとの違いは１件の投稿が１つのページとして作成され、
#   一覧表示されることです。一覧は指定件数ずつ表示されるため、
#   件数が増えた場合に過去ログを手動で編集する必要がありません。
#   表示件数を省略した場合は10件ずつ表示されます。
# </p>
# <p>
#   デフォルトでは各投稿記事に返信用のコメントフォームが出力されますが、
#   no_commentオプションをつけるとOFFにすることができます。
# </p>
# <pre>
# {{bbs2 掲示板の名前,表示件数,no_comment}}
# </pre>
# <p>
#   reverse_commentオプションをつけると各記事につくcommentプラグインに
#   reverseオプションをつけることができ、コメントが新着順表示されるようになります。
# </p>
# <pre>
# {{bbs2 掲示板の名前,表示件数,reverse_comment}}
# </pre>
# <p>
#   no_listオプションをつけると記事の一覧は表示せず、投稿フォームだけを表示します。
#   この場合はbbs2listプラグインを使って記事の一覧を表示することができます。
# </p>
# <pre>
# {{bbs2 掲示板の名前,no_list}}
# </pre>
#
###############################################################################
package plugin::bbs::BBS2;
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
	my $name   = shift;
	my $once   = shift;
	my $option = shift;
	
	if($name eq ""){
		return &Util::paragraph_error("掲示板の名前が指定されていません。");
	}
	if($once eq "" || !&Util::check_numeric($once)){
		$option = $once;
		$once   = 10;
	}
	
	my $cgi = $wiki->get_CGI;
	my $page = $cgi->param("page");
	
	# 入力フォーム
	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/bbs.tmpl",
	                               die_on_bad_params=>0);
	
	# 名前を取得
	my $postname = $cgi->cookie(-name=>'post_name');
	if($postname eq ''){
		my $login = $wiki->get_login_info();
		if(defined($login)){
			$postname = $login->{id};
		}
	}
	$tmpl->param(NAME=>$postname);
	
	my $buf = "<form method=\"post\" action=\"".$wiki->create_url()."\">\n".
	          $tmpl->output.
	          "<input type=\"hidden\" name=\"action\" value=\"BBS2\">\n".
	          "<input type=\"hidden\" name=\"bbsname\" value=\"".&Util::escapeHTML($name)."\">\n";
	
	if($option eq "no_comment"){
		$buf .="<input type=\"hidden\" name=\"option\" value=\"no_comment\">\n";
	} elsif($option eq "reverse_comment"){
		$buf .="<input type=\"hidden\" name=\"option\" value=\"reverse_comment\">\n";
	}
	
	$buf .= "</form>";
	
	# 記事の一覧を連結（no_listオプションがつけられた場合は表示しない）
	if($option ne "no_list"){
		$buf .= $wiki->process_wiki("{{bbs2list $name,$once}}");
	}
	
	return $buf;
}

1;
