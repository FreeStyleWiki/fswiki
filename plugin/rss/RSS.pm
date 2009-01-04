###############################################################################
#
# <p>外部サーバにあるRSSを取得して一覧表示します。</p>
# <pre>
# {{rss RSSのURL}}
# </pre>
#
###############################################################################
package plugin::rss::RSS;
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
# パラグラフメソッド
#==============================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $url  = shift;
	
	if($url eq ""){
		return &Util::paragraph_error("RSSのURLが指定されていません。");
	}
	
	# キャッシュファイルの更新時刻をチェック
	my $filename = $url;
	my $cache = $wiki->config('log_dir')."/".&Util::url_encode($filename).".rss";
	my $readflag = 0;
	if(-e $cache){
		my @status = stat($cache);
		if($status[9]+(60*60) > time()){
			$readflag = 1;
		}
	}
	
	my $content = "";
	if($readflag==0){
		# URLからRSSを取得
		$content = &Util::get_response($wiki,$url) or return &Util::paragraph_error($!);
		
		# EUCに変換（出力するときに変換するのが吉）
		#&Jcode::convert(\$content, "euc");
		
		# キャッシュ
		open(RSS,">$cache") or return &Util::paragraph_error($!);
		print RSS $content;
		close(RSS);
		
	} else {
		# ローカルからRSSを取得
		open(RSS,$cache) or return &Util::paragraph_error($!);
		while(<RSS>){ $content .= $_; }
		close(RSS);
	}
	# XMLファイルかどうかチェック
	if($content !~ /<(\?xml|rss) version/i){
		return &Util::paragraph_error("XMLファイルではありません。");
	}
	my @status = stat($cache);
	
	# パースして表示
	return $self->parse_rss(\$content);
}

#==============================================================================
# RSSをパースしてHTMLを生成
#==============================================================================
sub parse_rss {
	my $self    = shift;
	my $content = shift;
	my $charset = $self->get_charset($content);
	my $buf     = "<ul>\n";
	
	my $version = "1.0";

	if($$content =~ /<rss .*?version=\"(.*?)\"/i){
	$version = $1;
	}

	if($version eq "1.0"){
		$$content =~ m#(/channel>|/language>)#gsi;
	}
	
	my $count=0;
	
	while ($$content =~ m|<item[ >](.+?)</item|gsi) {
		
		my $item = $1;
		
		my $link  = "";
		my $title = "";
		my $date  = "";
		
		$item =~ m#title>([^<]+)</#gsi;
		$title = $1;
		
		$item =~ m#link>([^<]+)</#gsi;
		$link = $1;
		$link =~ s/\s".*//g; # ダブルクォーテーション以降を切り落とす

		if ($version eq "2.0") {
			if ($item =~ m#pubDate>([^<]+)</#gsi) {
				$date = $1;
			}
		}
		if ($version eq "1.0") {
			#if ($item =~ m#(description|dc\:date)>([^<]+)</#gs) {
			if ($item =~ m#dc\:date>([^<]+)</#gsi) {
				$date = $1;
			}
		}
		if ($version eq "0.91") {
			if($item =~ m#description>([^<]+)</#gsi){
				$date = $1;
			}
		}
		
		# 文字コードの変換
		&Jcode::convert(\$title,'euc',$charset);
		&Jcode::convert(\$date ,'euc',$charset);
		
		$buf .= "<li><a href=\"$link\">$title</a>";
		if($date ne ""){
			$buf .= " - $date";

		}
		$buf .= "</li>\n";
		
		$count++;
		if($count>50){ last; }
	}
	
	return $buf."</ul>\n";
}

#==============================================================================
# XMLファイルからキャラクタセットを取得してJcode.pmで指定可能な文字列を返却。
# 指定されていなかった場合はundefが返ります。
#==============================================================================
sub get_charset {
	my $self    = shift;
	my $content = shift;
	my $charset = undef;
	
	# エンコーディングが指定されていた場合
	if($$content =~ /encoding="(.+?)"/){
		# とりあえず大文字に変換
		my $encode = uc($1);
		
		# Shift_JISの場合sjisに
		if($encode eq "SHIFT_JIS" || $encode eq "SJIS" ||
		   $encode eq "WINDOWS-31J" || $encode eq "MS932" || $encode eq "CP932"){
			$charset = "sjis";
			
		# EUC-JPの場合eucに
		} elsif($encode eq "EUC-JP"){
			$charset = "euc";
			
		# UTF-8の場合utf8に
		} elsif($encode eq "UTF-8"){
			$charset = "utf8";
			
		# JISの場合jisに
		} elsif($encode eq "ISO-2022-JP" || $encode eq "JIS"){
			$charset = "jis";
		}
	}
	
	return $charset;
}

1;
