#!/usr/bin/env bash
# setup.sh

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

# Globals ####################################################################

user="$SUDO_USER"
[[ -z "$user" ]] && user="$(id -un)"

# home="$(eval echo ~$user)"

home="$(find /home -type d -name RetroPie -print -quit 2> /dev/null)"
home="${home%/RetroPie}"

readonly SCRIPT_VERSION="1.2.0"
readonly SCRIPT_DIR="$(cd "$(dirname $0)" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_TITLE="RetroPie itch.io Godot Scraper"
readonly SCRIPT_DESCRIPTION="Scrape Godot games hosted on https://itch.io/."
readonly SCRIPT_IMAGE="$SCRIPT_DIR/retropie-itchio-godot-scraper.png"

readonly RP_DIR="$home/RetroPie"
readonly RP_SETUP_DIR="$home/RetroPie-Setup"
readonly RP_ROMS_DIR="$RP_DIR/roms"
readonly RP_MENU_DIR="$RP_DIR/retropiemenu"
readonly RP_CONFIGS_DIR="/opt/retropie/configs"
readonly ES_GAMELISTS_DIR="$RP_CONFIGS_DIR/all/emulationstation/gamelists"
readonly RP_MENU_GAMELIST="$ES_GAMELISTS_DIR/retropie/gamelist.xml"

readonly SCRIPTMODULES_DIR="$RP_SETUP_DIR/scriptmodules/supplementary"
readonly SCRIPTMODULE_FILE="$SCRIPT_DIR/scriptmodules/supplementary/itchio-godot-scraper.sh"

readonly MAIN_SCRIPT_FILE="retropie-itchio-godot-scraper.sh"


# Variables ##################################################################

RP_MENU_PROPERTIES=(
  "path ./$MAIN_SCRIPT_FILE"
  "name itch.io Godot Scraper"
  "desc $SCRIPT_DESCRIPTION"
  "image $SCRIPT_IMAGE"
)


# Flags ######################################################################

GUI_FLAG=0


# External resources #########################################################

source "$SCRIPT_DIR/utils/base.sh"
source "$SCRIPT_DIR/utils/dialogs.sh"


# Functions ##################################################################

function usage() {
    echo
    echo "USAGE: $0 [OPTIONS]"
    echo
    echo "Use '$0 --help' to see all the options."
    echo
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


function install() {
  case "$1" in
    "retropie-menu")
      install_script_retropie_menu
    ;;
    "scriptmodule")
      install_scriptmodule
    ;;
    *)
      echo >&2
      echo "ERROR: Invalid option '$1'." >&2
      echo >&2
      exit 2
    ;;
  esac
}


function uninstall() {
  case "$1" in
    "retropie-menu")
      uninstall_script_retropie_menu
    ;;
    "scriptmodule")
      uninstall_scriptmodule
    ;;
    *)
      echo >&2
      echo "ERROR: Invalid option '$1'." >&2
      echo >&2
      exit 2
    ;;
  esac
}


function install_script_retropie_menu() {
  if [[ "$GUI_FLAG" -eq 0 ]]; then
    echo
    echo "> Installing script in EmulationStation's RetroPie menu ..."
  fi
  cat > "$RP_MENU_DIR/$MAIN_SCRIPT_FILE" << _EOF_
#!/usr/bin/env bash
# $MAIN_SCRIPT_FILE

"$SCRIPT_DIR/$MAIN_SCRIPT_FILE"

_EOF_

  if ! xmlstarlet sel -t -v "/gameList/game[path='./$MAIN_SCRIPT_FILE']" "$RP_MENU_GAMELIST" > /dev/null; then
    # Crete <newGame>
    xmlstarlet ed -L -s "/gameList" -t elem -n "newGame" -v "" "$RP_MENU_GAMELIST"
    for node in "${RP_MENU_PROPERTIES[@]}"; do
      local key
      local value
      key="$(echo $node | grep  -Eo "^[^ ]+")"
      value="$(echo $node | grep -Po "(?<= ).*")"
      if [[ -n "$value" ]]; then
        # Add nodes from $RP_MENU_PROPERTIES to <newGame>
        xmlstarlet ed -L -s "/gameList/newGame" -t elem -n "$key" -v "$value" "$RP_MENU_GAMELIST"
      fi
    done
    # Rename <newGame> to <game>
    xmlstarlet ed -L -r "/gameList/newGame" -v "game" "$RP_MENU_GAMELIST"
  fi
  if [[ "$GUI_FLAG" -eq 1 ]]; then
    dialog_msgbox "Success!" "Script installed in EmulationStation's RetroPie menu successfully!"
    dialog_setup
  else
    echo "Script installed in EmulationStation's RetroPie menu successfully!"
  fi
}


function uninstall_script_retropie_menu() {
  if [[ "$GUI_FLAG" -eq 0 ]]; then
    echo
    echo "> Uninstalling script in EmulationStation's RetroPie menu ..."
  fi
  rm "$RP_MENU_DIR/$MAIN_SCRIPT_FILE"
  xmlstarlet ed -L -d "//gameList/game[path='./$MAIN_SCRIPT_FILE']" "$RP_MENU_GAMELIST"
  if [[ "$GUI_FLAG" -eq 1 ]]; then
    dialog_msgbox "Success!" "Script uninstalled from EmulationStation's RetroPie menu successfully!"
    dialog_setup
  else
    echo "Script uninstalled from EmulationStation's RetroPie menu successfully!"
  fi
}


function install_scriptmodule() {
  if [[ "$GUI_FLAG" -eq 0 ]]; then
    echo
    echo "> Installing '$(basename "$SCRIPTMODULE_FILE")' scriptmodule ..."
  fi
  cp "$SCRIPTMODULE_FILE" "$SCRIPTMODULES_DIR"
  local return_value="$?"
  if [[ "$return_value" -eq 0 ]]; then
    if [[ "$GUI_FLAG" -eq 1 ]]; then
      dialog_msgbox "Success!" "'$(basename "$SCRIPTMODULE_FILE")' scriptmodule installed successfully!"
      local info_text=""
      info_text+="Installation\n"
      info_text+="------------\n"
      info_text+="To install '$(basename "$SCRIPTMODULE_FILE")' run:\n\n"
      info_text+="'sudo $RP_SETUP_DIR/retropie_setup.sh'.\n\n"
      info_text+="Go to:\n\n"
      info_text+="|- Manage packages\n"
      info_text+="  |- Manage optional packages\n"
      info_text+="    |- itchio-godot-scraper\n"
      info_text+="      |- Install from source"
      dialog_msgbox "Info" "$info_text" 16
      dialog_setup
    else
      echo "'$(basename "$SCRIPTMODULE_FILE")' scriptmodule installed successfully!"
    fi
  else
    if [[ "$GUI_FLAG" -eq 1 ]]; then
      dialog_msgbox "Error!" "Couldn't install '$(basename "$SCRIPTMODULE_FILE")' scriptmodule."
      dialog_setup
    else
      echo "ERROR: Couldn't install '$(basename "$SCRIPTMODULE_FILE")' scriptmodule." >&2
    fi
  fi
}


function uninstall_scriptmodule() {
  if [[ "$GUI_FLAG" -eq 0 ]]; then
    echo
    echo "> Uninstalling '$(basename "$SCRIPTMODULE_FILE")' scriptmodule ..."
  fi
  rm "$SCRIPTMODULES_DIR/$(basename "$SCRIPTMODULE_FILE")"
  local return_value="$?"
  if [[ "$return_value" -eq 0 ]]; then
    if [[ "$GUI_FLAG" -eq 1 ]]; then
      dialog_msgbox "Success!" "'$(basename "$SCRIPTMODULE_FILE")' scriptmodule uninstalled successfully!"
      dialog_setup
    else
      echo "'$(basename "$SCRIPTMODULE_FILE")' scriptmodule uninstalled successfully!"
    fi
  else
    if [[ "$GUI_FLAG" -eq 1 ]]; then
      dialog_msgbox "Error!" "Couldn't uninstall '$(basename "$SCRIPTMODULE_FILE")' scriptmodule."
      dialog_setup
    else
      echo "ERROR: Couldn't uninstall '$(basename "$SCRIPTMODULE_FILE")' scriptmodule." >&2
    fi
  fi
}


function get_options() {
  if [[ -z "$1" ]]; then
    usage
    exit 0
  else
    case "$1" in
#H -h, --help                 Prints the help message.
      -h|--help)
        echo
        echo "$SCRIPT_TITLE"
        for ((i=1; i<="${#SCRIPT_TITLE}"; i+=1)); do [[ -n "$dashes" ]] && dashes+="-" || dashes="-"; done && echo "$dashes"
        echo "$SCRIPT_DESCRIPTION"
        echo
        echo "USAGE: $0 [OPTIONS]"
        echo
        echo "OPTIONS:"
        echo
        sed '/^#H /!d; s/^#H //' "$0"
        echo
        exit 0
        ;;
#H -v, --version              Prints the script version.
      -v|--version)
        echo "$SCRIPT_VERSION"
        ;;
#H -i, --install [script]     Installs the given script.
#H                              Scripts: "retropie-menu" "scriptmodule"
      -i|--install)
        check_argument "$1" "$2" || exit 1
        shift
        install "$1"
        ;;
#H -u, --uninstall [script]   Uninstalls the given script.
#H                              Scripts: "retropie-menu" "scriptmodule"
      -u|--uninstall)
        check_argument "$1" "$2" || exit 1
        shift
        uninstall "$1"
        ;;
      *)
        echo >&2
        echo "ERROR: Invalid option '$1'." >&2
        exit 2
        ;;
    esac
  fi
}


function main() {
  if [[ -z "$@" ]]; then
    GUI_FLAG=1
  fi

  if [[ "$GUI_FLAG" -eq 1 ]]; then
    dialog_setup
  else
    get_options "$@"
  fi
}


main "$@"
