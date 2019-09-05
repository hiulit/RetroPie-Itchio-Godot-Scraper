#!/usr/bin/env bash
# base.sh

# RetroPie itch.io Godot Scraper.
# A tool for RetroPie to scrape Godot games hosted on https://itch.io/.
#
# Author: hiulit
# Repository: https://github.com/hiulit/RetroPie-Itchio-Godot-Scraper
# License: MIT https://github.com/hiulit/RetroPie-Itchio-Godot-Scraper/blob/master/LICENSE
#
# Requirements:
# - RetroPie 4.x.x
# - ffmpeg
# - jq

# Functions ##################################################################

function is_retropie() {
    [[ -d "$home/RetroPie" && -d "$home/.emulationstation" && -d "/opt/retropie" ]]
}


function check_dependencies() {
  local pkg
  for pkg in "${DEPENDENCIES[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$pkg" | awk '{print $3}' | grep -q "^installed$"; then
      echo
      echo "WHOOPS! The '$pkg' package is not installed!"
      echo
      echo "Would you like to install it now?"
      local options=("Yes" "No")
      local option
      select option in "${options[@]}"; do
        case "$option" in
          Yes)
            if ! which apt-get > /dev/null; then
              echo "ERROR: Can't install '$pkg' automatically. Try to install it manually."
              exit 1
            else
              if sudo apt-get install "$pkg"; then
                echo
                echo "YIPPEE! The '$pkg' package installation was successful!"
              fi
              break
            fi
            ;;
          No)
            echo "ERROR: Can't launch the script if the '$pkg' package is not installed."
            exit 1
            ;;
          *)
            echo "Invalid option. Choose a number between 1 and ${#options[@]}."
            ;;
        esac
      done
    fi
  done
}


function check_argument() {
  # This method doesn't accept arguments starting with '-'.
  if [[ -z "$2" || "$2" =~ ^- ]]; then
    echo >&2
    echo "ERROR: '$1' is missing an argument." >&2
    echo >&2
    echo "Try '$0 --help' for more info." >&2
    echo "Or read the documentation in the README." >&2
    echo >&2
    return 1
  fi
}


function usage() {
  echo
  echo "USAGE: $0 [OPTIONS]"
  echo
  echo "Use '$0 --help' to see all the options."
  echo
}


function underline() {
  local dashes
  local string="$1"
  if [[ -z "$string" ]]; then
      log "Missing a string as an argument."
      exit 1
  fi
  echo "$string"
  for ((i=1; i<="${#string}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done && echo "$dashes"
}


function log() {
  echo "$*" >> "$LOG_FILE"
  echo "$*"
}


function finish() {
  rm -rf "$TMP_DIR"
}
