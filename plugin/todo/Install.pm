###############################################################################
#
# Wikiページ上でTODOの管理を行うためのプラグインを提供します。
#
##############################################################################
package plugin::todo::Install;
use strict;

sub install {
    my $wiki = shift;
    $wiki->add_paragraph_plugin("todolist","plugin::todo::ToDoList","HTML");
    $wiki->add_handler("FINISH_TODO","plugin::todo::ToDoHandler");
    $wiki->add_paragraph_plugin("todoadd","plugin::todo::ToDoAdd","HTML");
    $wiki->add_handler("ADD_TODO","plugin::todo::ToDoAddHandler");
}

1;
