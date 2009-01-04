################################################################################
#
# <p>バグレポートを投稿するためのフォームを表示します。</p>
# <p>
#   引数としてプロジェクト名およびバグのカテゴリを指定します。
# </p>
# <pre>
# {{bugtrack プロジェクト名,カテゴリ１,カテゴリ２...}}
# </pre>
# <p>
#   このフォームからバグレポートを投稿すると
# </p>
# <pre>
# BugTrack-プロジェクト名/番号
# </pre>
# <p>
#   という名前のページが作成されます。
#   登録済みのバグレポートの状態を変更する場合は、バグレポートを直接編集し、
#   状態を「提案」「着手」「完了」「リリース済」「保留」「却下」のいずれかに
#   書き換えてください。
# </p>
# 
################################################################################
package plugin::bugtrack::BugTrack;
use strict;
#===============================================================================
# コンストラクタ
#===============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===============================================================================
# パラグラフ
#===============================================================================
sub paragraph {
	my $self     = shift;
	my $wiki     = shift;
	my $project  = shift;
	my @category = @_;
	my $cgi      = $wiki->get_CGI();
	
	if($project eq ""){
		return &Util::paragraph_error("プロジェクト名が指定されていません。");
	}
	if($#category == -1){
		return &Util::paragraph_error("カテゴリが指定されていません。");
	}
	
	my $template = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/bugtrack.tmpl",
	                                   die_on_bad_params => 0);
	
	my @priority = ("緊急","重要","普通","低");
	my @status   = ("提案","着手","完了","リリース済","保留","却下");
	
	$template->param(PRIORITY => &make_array_ref(@priority));
	$template->param(STATUS   => &make_array_ref(@status));
	$template->param(CATEGORY => &make_array_ref(@category));
	
	# 名前を取得
	my $name = $cgi->cookie(-name=>'post_name');
	if($name eq ''){
		my $login = $wiki->get_login_info();
		if(defined($login)){
			$name = $login->{id};
		}
	}
	$template->param(NAME=>$name);
	
	my $buf = "<form action=\"".$wiki->create_url()."\" method=\"post\">\n".
	          $template->output().
	          "<input type=\"hidden\" name=\"action\" value=\"BUG_POST\">\n".
	          "<input type=\"hidden\" name=\"project\" value=\"".&Util::escapeHTML($project)."\">\n".
	          "</form>\n";
	
	return $buf;
}

#===============================================================================
# 選択項目の配列リファレンスを作成
#===============================================================================
sub make_array_ref {
	my @array    = @_;
	my $arrayref = [];
	foreach(@array){
		push(@$arrayref,{NAME=>$_,VALUE=>$_});
	}
	return $arrayref;
}


1;
