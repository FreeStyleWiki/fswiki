###############################################################################
#
# <p>ページのカテゴリを設定します。</p>
# <pre>
# {{category カテゴリ名１,カテゴリ名２,,}}
# </pre>
# <p>
#   １ページに複数のカテゴリを設定することもできます。
# </p>
# <pre>
# {{category カテゴリ名１}}
# {{category カテゴリ名２}}
# </pre>
# <p>
#   categoryプラグインを記述した位置にはカテゴリ[カテゴリ名]という形式の
#   アンカが出力され、押下するとそのカテゴリに属しているページの一覧が表示されます。
#   nolinkオプションを最後につけることでカテゴリ定義だけを行い、
#   アンカを出力しないようにすることもできます。
# </p>
# <pre>
# {{category カテゴリ名１,カテゴリ名２,,,nolink}}
# </pre>
#
###############################################################################
package plugin::category::Category;
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
# インラインメソッド
#==============================================================================
sub inline {
	my $self   = shift;
	my $wiki   = shift;
	my @option = @_;

	if($option[0] eq ""){
		return Util::inline_error("カテゴリが設定されていません。");
	}
	elsif(@option > 1 and $option[-1] eq 'nolink'){
		return "";
	}

	my $out = "";

	foreach my $category (@option) {
		if($out ne ""){ $out .= ","; }
		$out .= '<a href="'.$wiki->create_url({action=>'CATEGORY',category=>$category}).'">'
		     .  Util::escapeHTML($category) . '</a>';
	}

	return qq|<span class="category">[| . $out . qq|]</span>|;
}

1;
