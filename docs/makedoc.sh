#!/bin/sh
# HTML�ե�������Ѵ�
perl ../tools/wiki2html.pl "http://fswiki.osdn.jp/cgi-bin/wiki.cgi/docs?action=SOURCE&page=readme" -css=default.css -title=README > readme.html
perl ../tools/wiki2html.pl "http://fswiki.osdn.jp/cgi-bin/wiki.cgi/docs?action=SOURCE&page=changes" -css=default.css -title=CHANGES > changes.html
