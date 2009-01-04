############################################################
# 
# <p>簡易的な投票フォームと途中経過を表示します。</p>
# <pre>
# {{vote 投票名,項目1,項目2,}}
# </pre>
# <p>
#   例えば以下のように使用します。
#   第一引数にはその投票を示すわかりやすい名前をつけてください。
#   第二引数以降が実際に表示される選択項目になります。
# </p>
# <pre>
# {{vote FSWikiの感想,よい,普通,ダメ}}
# </pre>
#
############################################################
package plugin::vote::Vote;
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
# 投票フォーム
#===========================================================
sub paragraph {
	my $self     = shift;
	my $wiki     = shift;
	my $votename = shift;
	my @itemlist = @_;
	my $cgi      = $wiki->get_CGI;
	my $page     = $cgi->param("page");
	
	# 引数のエラーチェック
	if($votename eq ""){
		return &Util::paragraph_error("投票名が指定されていません。","Wiki");
	}
	if($#itemlist == -1){
		return &Util::paragraph_error("項目名が指定されていません。","Wiki");
	}
	
	# 読み込む
	my $filename = &Util::make_filename($wiki->config('log_dir'),
	                                    &Util::url_encode($votename),"vote");
	my $hash = &Util::load_config_hash(undef,$filename);
	
	# 表示用テキストを組み立てる
	my $buf = ",項目,得票数\n";
	
	foreach my $item (@itemlist) {
		my $count = $hash->{$item};
		unless(defined($count)){
			$count=0;
		}
		$buf .= ",$item,$count票 - [投票|".$wiki->create_url({
			page=>$page,
			vote=>$votename,
			item=>$item,
			action=>'VOTE'
		})."]\n";
	}
	return $buf;
}

1;
