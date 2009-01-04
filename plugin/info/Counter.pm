############################################################
# 
# <p>アクセス数を表示します。</p>
# <pre>
# {{counter カウンタ名}}
# </pre>
# <p>カウンタ名は省略できます。</p>
# 
############################################################
package plugin::info::Counter;
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
# インライン関数
#===========================================================
sub inline {
	my $self   = shift;
	my $wiki   = shift;
	my $name   = shift;
	
	my $count = 0;
	
	if($name eq ""){
		$name = "default";
	}
	
	my $file = $wiki->config('log_dir')."/count-".Util::url_encode($name).".txt";
	if (-e $file) {
		open(COUNT,$file) or return "";
		my $line=<COUNT>;
		$count = int($line) or $count = 0;
		close(COUNT);
	}
	$count ++;
	
	unless(-e "$file.tmp"){
		open(COUNT,">$file.tmp") or return $count;
		print COUNT $count;
		close(COUNT);
		rename("$file.tmp", $file);
	}
	
	return $count;
}

1;
