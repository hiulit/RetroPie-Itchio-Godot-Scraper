#!/usr/bin/env bash
# dialogs.sh

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

# Variables ############################################

DIALOG_BACKTITLE="$SCRIPT_TITLE (v$SCRIPT_VERSION)"
readonly DIALOG_HEIGHT=20
readonly DIALOG_WIDTH=60
readonly DIALOG_OK=0
readonly DIALOG_CANCEL=1
readonly DIALOG_HELP=2
readonly DIALOG_EXTRA=3
readonly DIALOG_ESC=255


# Functions ###########################################

function dialog_msgbox() {
  local title="$1"
  local message="$2"
  local dialog_height="$3"
  local dialog_width="$4"
  [[ -z "$title" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a title as an argument!" && exit 1
  [[ -z "$message" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a message as an argument!" && exit 1
  [[ -z "$dialog_height" ]] && dialog_height=8
  [[ -z "$dialog_width" ]] && dialog_width="$DIALOG_WIDTH"
  dialog \
    --backtitle "$DIALOG_BACKTITLE" \
    --title "$1" \
    --ok-label "OK" \
    --msgbox "$2" "$dialog_height" "$dialog_width" 2>&1 >/dev/tty
}


function dialog_yesno() {
  local title="$1"
  local message="$2"
  local dialog_height="$3"
  local dialog_width="$4"
  [[ -z "$title" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a title as an argument!" && exit 1
  [[ -z "$message" ]] && echo "ERROR: '${FUNCNAME[0]}' needs a message as an argument!" && exit 1
  [[ -z "$dialog_height" ]] && dialog_height=8
  [[ -z "$dialog_width" ]] && dialog_width="$DIALOG_WIDTH"
  dialog \
    --backtitle "$DIALOG_BACKTITLE" \
    --title "$1" \
    --yesno "$2" "$dialog_height" "$dialog_width" 2>&1 >/dev/tty
}


function dialog_setup() {
  local options=()
  local menu_text
  local cmd
  local choice

  local retropie_menu_status
  local retropie_menu_status_string
  # Check if script is installed in EmulationStation's RetroPie menu.
  if [[ -f "$RP_MENU_DIR/$MAIN_SCRIPT_FILE" ]]; then
    retropie_menu_status=1
    retropie_menu_status_string="Uninstall script from"
  else
    retropie_menu_status=0
    retropie_menu_status_string="Install script in"
  fi

  local scriptmodule_status
  local scriptmodule_status_string
  # Check if scriptmodule is installed.
  if [[ -f "$RP_SETUP_DIR/scriptmodules/supplementary/$(basename "$SCRIPTMODULE_FILE")" ]]; then
    scriptmodule_status=1
    scriptmodule_status_string="Uninstall"
  else
    scriptmodule_status=0
    scriptmodule_status_string="Install"
  fi

  options=(
    1 "$retropie_menu_status_string EmulationStation's RetroPie menu"
    2 "$scriptmodule_status_string scriptmodule"
  )

  menu_text="Choose an option."

  cmd=(dialog \
    --backtitle "$DIALOG_BACKTITLE" \
    --title "$SCRIPT_TITLE" \
    --ok-label "OK" \
    --cancel-label "Exit" \
    --menu "$menu_text" 15 "$DIALOG_WIDTH" 15)

  choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
  local return_value="$?"

  if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
    if [[ -n "$choice" ]]; then
      case "$choice" in
        1)
          if [[ "$retropie_menu_status" -eq 1 ]]; then
            uninstall_script_retropie_menu
          else
            install_script_retropie_menu
          fi
          ;;
        2)
          if [[ "$scriptmodule_status" -eq 1 ]]; then
            uninstall_scriptmodule
          else
            install_scriptmodule
          fi
          ;;
      esac
    else
      dialog_msgbox "Error!" "Choose an option."
    fi
  elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
    exit 0
  elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
    exit 0
  elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
    exit 0
  fi
}


function dialog_main() {
  local options=()
  local menu_text
  local cmd
  local choice

  options=(
    1 "Select games to scrape"
    2 "Scrape all games"
  )

  menu_text="Choose an option."

  cmd=(dialog \
    --backtitle "$DIALOG_BACKTITLE" \
    --title "$SCRIPT_TITLE" \
    --ok-label "OK" \
    --cancel-label "Exit" \
    --menu "$menu_text" 15 "$DIALOG_WIDTH" 15)

  choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
  local return_value="$?"

  if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
    if [[ -n "$choice" ]]; then
      case "$choice" in
        1)
          dialog_choose_games
          ;;
        2)
          scrape_all
          ;;
      esac
    else
      dialog_msgbox "Error!" "Choose an option."
    fi
  elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
    exit 0
  elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
    exit 0
  elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
    exit 0
  fi
}


function dialog_choose_games() {
  local all_games
  local game
  local i=1
  local options=()
  local cmd
  local choices
  local choice
  local selected_games=()

  all_games="$(get_all_games)"
  # Parse the array by delimiting commas.
  IFS="," read -r -a all_games <<< "${all_games[@]}"
  for game in "${all_games[@]}"; do
    # Remove trailing and leadings white spaces because of the comma separated array.
    game="$(echo "$game" | awk '{$1=$1};1')"
    options+=("$i" "$game" off)
    ((i++))
  done

  cmd=(dialog \
    --backtitle "$DIALOG_BACKTITLE" \
    --title "$SCRIPT_TITLE" \
    --ok-label "OK" \
    --cancel-label "Exit" \
    --extra-button \
    --extra-label "Back" \
    --checklist "Select the game/s to scrape." \
    15 "$DIALOG_WIDTH" 15)

  choices="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
  local return_value="$?"

  if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
    if [[ -z "${choices[@]}" ]]; then
      dialog_msgbox "Error!" "You must select at least 1 game."
      dialog_choose_games
    fi

    IFS=" " read -r -a choices <<< "${choices[@]}"
    for choice in "${choices[@]}"; do
      # Add games ending with a comma to use for parsing them later on.
      selected_games+=("${options[choice*3-2]},")
    done

    scrape_all "${selected_games[@]}"
  elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
    exit 0
  elif [[ "$return_value" -eq "$DIALOG_EXTRA" ]]; then
    dialog_main
  fi
}
