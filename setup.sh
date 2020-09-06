case "$OSTYPE" in
  darwin*)  sh ./setup_for_macos.sh ;;
  linux*)   echo "setup shell does not support LINUX now" ;;
  msys*)    echo "Program does not support WINDOWS now" ;;
  *)        echo "unknown: $OSTYPE" ;;
esac
