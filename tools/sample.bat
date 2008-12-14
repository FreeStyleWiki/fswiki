@echo off
echo FSWIKI_HOME=%FSWIKI_HOME%
echo HTML‚ğ¶¬‚µ‚Ü‚·B
wiki2html.pl readme.wiki -css=default.css -output=sjis > readme.html
echo PDF‚ğ¶¬‚µ‚Ü‚·B
wiki2pdf.pl readme.wiki readme.pdf
