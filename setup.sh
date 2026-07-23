#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

case "$(uname -s)" in
  Darwin) exec zsh "$repo_dir/setup_for_macos.sh" "$@" ;;
  Linux)  echo "Linux is not supported yet" >&2; exit 1 ;;
  *)      echo "Unsupported system: $(uname -s)" >&2; exit 1 ;;
esac
