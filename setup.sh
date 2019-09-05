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

readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname $0)" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_TITLE="RetroPie itch.io Godot Scraper"
readonly SCRIPT_DESCRIPTION="A tool for RetroPie to scrape Godot games hosted on https://itch.io/."

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
  "name $SCRIPT_TITLE"
  "desc $SCRIPT_DESCRIPTION"
)


# Flags ######################################################################

GUI_FLAG=0


# External resources #########################################################

source "$SCRIPT_DIR/utils/base.sh"
source "$SCRIPT_DIR/utils/dialogs.sh"


# Functions ##################################################################

function install_script_retropie_menu() {
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
  echo
  echo "> Installing '$(basename "$SCRIPTMODULE_FILE")' scriptmodule ..."
  cp "$SCRIPTMODULE_FILE" "$SCRIPTMODULES_DIR"
  local return_value="$?"
  if [[ "$return_value" -eq 0 ]]; then
    if [[ "$GUI_FLAG" -eq 1 ]]; then
      dialog_msgbox "Success!" "'$(basename "$SCRIPTMODULE_FILE")' scriptmodule installed in '$SCRIPTMODULES_DIR' successfully!"
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
      echo "'$(basename "$SCRIPTMODULE_FILE")' scriptmodule installed in '$SCRIPTMODULES_DIR' successfully!"
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
  echo
  echo "> Uninstalling '$(basename "$SCRIPTMODULE_FILE")' scriptmodule ..."
  rm "$SCRIPTMODULES_DIR/$(basename "$SCRIPTMODULE_FILE")"
  local return_value="$?"
  if [[ "$return_value" -eq 0 ]]; then
    if [[ "$GUI_FLAG" -eq 1 ]]; then
      dialog_msgbox "Success!" "'$(basename "$SCRIPTMODULE_FILE")' scriptmodule uninstalled from '$SCRIPTMODULES_DIR' successfully!"
      dialog_setup
    else
      echo "'$(basename "$SCRIPTMODULE_FILE")' scriptmodule uninstalled from '$SCRIPTMODULES_DIR' successfully!"
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

function main() {
  GUI_FLAG=1
  dialog_setup
}

main "$@"
