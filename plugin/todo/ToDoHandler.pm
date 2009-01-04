##############################################################
#
# ToDoプラグインのアクションハンドラ。
# チェックされたToDoを「済」に変更します。
#
##############################################################
package plugin::todo::ToDoHandler;
use strict;

#=============================================================
# コンストラクタ
#=============================================================
sub new{
    my $class = shift;
    my $self = {};
    return bless $self,$class;
}

#=============================================================
# アクションメソッド
# ToDoの完了処理
#=============================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;

	my $buf = "";
	my $source  = $cgi->param("source");
	my @params  = $cgi->all_parameters;
	my $content = $wiki->get_page($source);
	my $page    = $cgi->param("page");

	# todoを収集
	@params = grep(/^todo\.\d+/,@params);
	my ($param,$dothing);
	foreach $param (@params){
		#メタ文字をクウォート
		my $dothing = quotemeta($cgi->param($param));
		# 済マークを付ける
		$content =~ s/((^|\n)\*)\s*(\d+)\s+($dothing)(\n|$)/$1 済 $3 $4$5/;
	}
	$wiki->save_page($source,$content);

	# もともと表示していたページを表示
	$wiki->redirect($page);
}

1;
