#!/bin/bash

USER_BUILD_NUMBER=""


while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--build-number)
      USER_BUILD_NUMBER="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Require build number
if [[ -z "$USER_BUILD_NUMBER" ]]; then
  echo "Error: --build-number is required."
  echo "Usage: $0 --build-number v<integer>"
  echo "Example: $0 --build-number v50"
  exit 1
fi


PATH_KEY="${USER_BUILD_NUMBER:-$(date +%s)}"

flutter build web --dart-define=VISUALIZE_MENU_AIM=true --dart-define=FONT_PACKAGE=base_menu_demo --wasm --release --tree-shake-icons -O4 -o "build/web/$PATH_KEY" --base-href "/$PATH_KEY/"

cp "build/web/$PATH_KEY/index.html" "build/web/index.html"

