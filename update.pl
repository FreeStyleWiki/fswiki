#####################################################################
#
# 指定日以降に更新されたファイルを抽出するスクリプト
#
#####################################################################
use File::Path;
use File::Copy;

my $date = $ARGV[0];
my $dir  = $ARGV[1];

if($date eq "" || !($date =~ /^[1-2][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]$/)){
	&print_help();
	exit;
}

$date =~ s/-//g;
$date = int($date);

if($dir ne ""){
	if(-e $dir){
		print "$dirディレクトリを削除します。\n";
		rmtree($dir);
	}
	if(-e "$dir.zip"){
		print "$dir.zipを削除します。\n";
		unlink "$dir.zip";
	}
}

$find_flag = 0;
&search_dir($date,".",$dir);

if($dir ne ""){
	if($find_flag == 1){
		print "圧縮ファイルを作成します。\n";
		system("zip $dir.zip -r $dir");
	}

}

#====================================================================
# ヘルプを表示
#====================================================================
sub print_help {
	print "指定日付以降に更新されたファイルを抽出し、アーカイブを作成します。\n";
	print "\n";
	print "perl update.pl YYYY-MM-DD [出力先ディレクトリ名]\n";
	print "  ディレクトリ名を省略すると該当ファイル名を画面に表示して終了します。\n";
}

#====================================================================
# ディレクトリを検索
#====================================================================
sub search_dir {
	my $date = shift;
	my $dir  = shift;
	my $to   = shift;
	my @list = ();
	
	opendir(DIR,$dir);
	while(my $entry = readdir(DIR)){
		if(index($entry,".")!=0 && $entry ne "CVS"){
			if($dir eq "." && ($entry eq "log" || $entry eq "backup" || $entry eq "attach" || $entry eq "pdf")){
				
			} elsif($dir eq "./data" && $entry ne "FrontPage" && $entry ne "Help"){
				
				
			} else {
				push(@list,"$dir/$entry");
			}
		}
	}
	closedir(DIR);
	
	foreach my $entry (@list){
		if(-d $entry){
			&search_dir($date,$entry,$to);
		} else {
			# ファイルの更新時刻をチェック
			my @status = stat($entry);
			my ($sec,$min,$hour,$mday,$mon,$year)=localtime($status[9]);
			my $date_str = sprintf("%04d%02d%02d",$year+1900,$mon+1,$mday);
			
			if(int($date_str) >= $date){
				print $entry."\n";
				# ディレクトリが指定されていればディレクトリにコピー
				if($to ne ""){
					# ちょっとこのへんキタナイ・・・
					my $path = $dir;
					$path =~ s/^\.//;
					my $copydir = "$to$path";
					unless(-e $copydir){
						mkpath($copydir) or die "$copydirの作成に失敗しました。";
					}
					
					my $name = $entry;
					$name =~ s/^(.*?\/)*//g;
					copy($entry,"$copydir/$name") or die "$copydir/$nameのコピーに失敗しました。";
					
					$find_flag = 1;
				}
			}
		}
	}
}
