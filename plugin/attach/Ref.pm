############################################################
#
# <p>添付ファイルへのアンカを表示します。</p>
# <pre>
# {{ref ファイル名}}
# </pre>
# <p>別のページに添付されたファイルを参照することもできます。</p>
# <pre>
# {{ref ファイル名,ページ名}}
# </pre>
# <p>
#   通常はアンカとしてファイル名が表示されますが、
#   別名として任意の文字列を表示することもできます。
# </p>
# <pre>
# {{ref ファイル名,ページ名,別名}}
# </pre>
#
############################################################
package plugin::attach::Ref;
use strict;
use plugin::attach::AttachHandler;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# インライン関数
#===========================================================
sub inline {
	my $self  = shift;
	my $wiki  = shift;
	my $file  = shift;
	my $page  = shift;
	my $alias = shift;
	
	if($file eq ""){
		return &Util::inline_error("ファイルが指定されていません。");
	}
	if($page eq ""){
		$page = $wiki->get_CGI()->param("page");
	}
	unless($wiki->can_show($page)){
		return &Util::paragraph_error("ページの参照権限がありません。","WIKI");
	}
	if($alias eq ""){
		$alias = $file;
	}

	my $filename = $wiki->config('attach_dir')."/".&Util::url_encode($page).".".&Util::url_encode($file);
	if(-e $filename){
		my $buf = "<a href=\"".$wiki->create_url({ action=>"ATTACH",page=>$page,,file=>$file })."\">".&Util::escapeHTML($alias)."</a>";
		
		# ダウンロード回数を取得
		my $count = Util::load_config_hash(undef,$wiki->config('log_dir')."/".$wiki->config('download_count_file'));
		if(defined($count->{$page."::".$file})){
			$buf .= "(".$count->{$page."::".$file}.")";
		} else {
			$buf .= "(0)";
		}
		return $buf;
		
	} else {
		return &Util::inline_error("ファイルが存在しません。");
	}
}

1;
