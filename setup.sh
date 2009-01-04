#!/bin/sh

PROGNAME=`basename $0`

case "$1" in
-h|--help)
  echo "usage: $PROGNAME [fswiki_home]"
  ;;
-v|--version)
  echo "$PROGNAME version 0.01"
  exit
  ;;
esac

echo "# fswiki setup (for 3.5.8)..."
echo "prepare..."

if test -z "$FSWIKI_HOME";
then
  FSWIKI_HOME=.
fi
if test -n "$1";
then
  FSWIKI_HOME="$1"
fi

echo "  FSWIKI_HOME=$FSWIKI_HOME"
PERM_DIR=707
PERM_FILE=606
PERM_EXE=705

echo "  check $FSWIKI_HOME/wiki.cgi..."
if test -e "$FSWIKI_HOME/wiki.cgi";
then
  echo "    ok"
else
  echo "  $FSWIKI_HOME/wiki.cgi not exists!!"
  exit 1
fi

echo "do..."

chmod $PERM_EXE $FSWIKI_HOME/wiki.cgi || exit 1
for dir in backup attach pdf log data config;
do
  echo "  check $FSWIKI_HOME/$dir..."
  test -d $FSWIKI_HOME/$dir || mkdir $FSWIKI_HOME/$dir || exit 1
  find "$FSWIKI_HOME/$dir" -type d -exec chmod $PERM_DIR {} \;
  find "$FSWIKI_HOME/$dir" -type f -exec chmod $PERM_FILE {} \;
done

echo "  check $FSWIKI_HOME/.htaccess..."
if test -e "$FSWIKI_HOME/.htaccess";
then
  echo "    already exists."
else
  cat > "$FSWIKI_HOME/.htaccess" << HTACCESS
<FilesMatch "\.(pm|dat|wiki|log)$">
  deny from all
</FilesMatch>
HTACCESS
  echo "    create."
fi

echo "done"

