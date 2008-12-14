#!/bin/sh
# HTMLファイルに変換
perl ../tools/wiki2html.pl "http://fswiki.org/wiki.pl/docs?action=SOURCE&page=readme" -css=default.css -title=README > readme.html
perl ../tools/wiki2html.pl "http://fswiki.org/wiki.pl/docs?action=SOURCE&page=changes" -css=default.css -title=CHANGES > changes.html
