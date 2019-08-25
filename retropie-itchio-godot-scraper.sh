#!/usr/bin/env bash

# retropie-itchio-godot-scraper.sh
#
# RetroPie itch.io Godot scraper
# A Retropie scraper for Godot games hosted on https://itch.io/.
#
# Author: hiulit
# Repository: [REPO_URL] (e.g. https://github.com/hiulit/RetroPie-Shell-Script-Boilerplate)
# License: [LICENSE] [LICENSE_URL] (e.g. MIT https://github.com/hiulit/RetroPie-Shell-Script-Boilerplate/blob/master/LICENSE)
#
# Requirements:
# - RetroPie 4.x.x
# - ffmpeg
# - jq

# Globals ####################################################################

user="$SUDO_USER"
[[ -z "$user" ]] && user="$(id -un)"

home="$(eval echo ~$user)"

readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname $0)" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_FULL="$SCRIPT_DIR/$SCRIPT_NAME"
readonly SCRIPT_TITLE="RetroPie itch.io Godot scraper"
readonly SCRIPT_DESCRIPTION="A Retropie scraper for Godot games hosted on https://itch.io/."

readonly DEPENDENCIES=("ffmpeg" "jq")

readonly RP_DIR="$home/RetroPie"
readonly ROMS_DIR="$RP_DIR/roms"

readonly GODOT_ROMS_DIR="$ROMS_DIR/godot-engine"
readonly GODOT_VIDEOS_DIR="$GODOT_ROMS_DIR/videos"
readonly GODOT_IMAGES_DIR="$GODOT_ROMS_DIR/images"

readonly GODOT_GAMELIST_FILE="$GODOT_ROMS_DIR/gamelist.xml"
readonly GODOT_VIDEOS_HASHES_FILE="$GODOT_VIDEOS_DIR/.godot_video_hashes.txt"
readonly GODOT_IMAGES_HASHES_FILE="$GODOT_IMAGES_DIR/.godot_image_hashes.txt"
readonly IMAGES_ATTRIBUTIONS_FILE="$GODOT_IMAGES_DIR/IMAGES_ATTRIBUTIONS.txt"
readonly VIDEOS_ATTRIBUTIONS_FILE="$GODOT_VIDEOS_DIR/VIDEOS_ATTRIBUTIONS.txt"

readonly TMP_DIR="$SCRIPT_DIR/.tmp/"
readonly LOG_DIR="$SCRIPT_DIR/logs"
readonly LOG_FILE="$LOG_DIR/$(date +%F-%T).log"


# Variables ##################################################################

GAME_PROPERTIES=()

CURL_RESPONSE="$TMP_DIR/curl_response.txt"
CURL_STATUS=""


# External resources #########################################################

source "$SCRIPT_DIR/utils/base.sh"


# Functions ##################################################################

function get_hash() {
  local hash
  hash="$(grep -Po "(?<=^\"$1\" = ).*" "$2")"
  hash="${hash%\"}"
  hash="${hash#\"}"
  echo "$hash"
}


function set_hash() {
  sed -i "s|^\(\"$1\"\s*=\s*\).*|\1\"$2\"|" "$3"
}


function create_gamelist_file() {
  if [[ ! -f "$GODOT_GAMELIST_FILE" ]]; then
    touch "$GODOT_GAMELIST_FILE" && chown -R "$user":"$user" "$GODOT_GAMELIST_FILE"
    cat > "$GODOT_GAMELIST_FILE" << _EOF_
<?xml version="1.0"?>
<gameList>
</gameList>
_EOF_
  fi
}


function convert_gif_to_mp4() {
  log "> Converting gif to mp4 ..."
  # Convert gif to mp4 (-y option is to overwrite the exisiting video)
  ffmpeg -loglevel error -y -i "$GODOT_VIDEOS_DIR/$title.gif" -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "$GODOT_VIDEOS_DIR/$title.mp4" >/dev/null 2>&1
  rm "$GODOT_VIDEOS_DIR/$title.gif"
}


function get_all_games() {
  local all_games=()
  while IFS= read -r line; do
    # Add games ending with a comma to use for parsing them later on.
    all_games+=("$(basename "$line"),")
  done < <(find "$GODOT_ROMS_DIR" -name '*.pck' -o -name '*.zip')
  echo "${all_games[@]}"
}


function parse_game_title() {
  local game_title
  local parsed_game_title
  game_title="$1"
  IFS=" |_|-" read -r -a words <<< "$game_title"
  # Seaparate words by spaces, '_' and '-'.
  parsed_game_title="$(IFS=" |_|-"; echo "${words[@]}")"
  # Separate camelCase words.
  parsed_game_title="$(echo "$parsed_game_title" | sed 's/\([A-Z]\)/ \1/g')"
  # Trim leading and trailing white spaces.
  parsed_game_title="$(echo "$parsed_game_title" | awk '{$1=$1};1')"
  echo "$parsed_game_title"
}


function get_game_info() {
  local game_title
  local url
  local parsed_game_title

  local author
  local description
  local genre
  local id
  local link
  local platforms
  local publisher
  local rating
  local thumb
  local title
  local video

  game_title="$1"
  url="https://itchio-godot-scraper.now.sh/api/game/${game_title// /%20}" # Replace spaces with %20

  log "$(underline "URL: '$url'")"
  log "> Getting info for '$input_game' ..."

  # curl '-s' - be silent.
  # curl '-S' - still show errors.
  # curl '-w' - display value of specified variables.
  # curl '-o' - write response to file.

  CURL_STATUS="$(curl -sS -w %{http_code} "$url" -o "$CURL_RESPONSE")"

  if [[ "$CURL_STATUS" -eq 200 ]]; then
    if [[ "$(cat "$CURL_RESPONSE" | jq 'length')" -eq 0 ]]; then
      log "ERROR: Couldn't find a match for '$input_game'!" >&2
      log >&2
    else
      # jq '.[]' to iterate array
      for row in "$(cat "$CURL_RESPONSE" | jq -r '. | @base64')"; do
        _jq() {
          echo ${row} | base64 --decode | jq -r ${1}
        }

        author="$(_jq '.author')"
        description="$(_jq '.description')"
        genre="$(_jq '.genre')"
        id="$(_jq '.id')"
        link="$(_jq '.link')"
        platforms="$(_jq '.platforms')"
        publisher="$(_jq '.author')"
        rating="$(_jq '.rating')"
        thumb="$(_jq '.thumb')"
        title="$(_jq '.title')"
        video="$(_jq '.video')"

        GAME_PROPERTIES=(
          "developer $author"
          "desc $description"
          "id $id"
          "genre $genre"
          "image $thumb"
          "name $title"
          "publisher $publisher"
          "rating $rating"
          "video $video"
        )

        parsed_game_title="$(parse_game_title "$title")"

        # Uppercase the words to find a match.
        if [[ "${game_title^^}" == *"${parsed_game_title^^}"* || ${parsed_game_title^^} == *"${game_title^^}"* ]]; then
          log "HURRAY! Found a matching game! ----> '$title'."
          GAME_PROPERTIES+=("path ./$input_game")
          add_game_info
        else
          log "ERROR: Couldn't find a match for '$input_game'!" >&2
          log >&2
        fi
      done
    fi
  else
    log "ERROR: $CURL_STATUS!" >&2
    echo >&2
    log "$(cat "$CURL_RESPONSE")" >&2
    exit 1
  fi
}


function update_game_info() {
  log "> Updating '$title' info ..."
  for game_property in "${GAME_PROPERTIES[@]}"; do
    local key
    local value
    key="$(echo $game_property | grep -Eo "^[^ ]+")"
    value="$(echo $game_property | grep -Po "(?<= ).*")"
    if [[ -n "$value" && "$value" != null ]]; then
      # If the key doesn't exist, create it.
      if ! xmlstarlet sel -t -v "/gameList/game[@id='$id']/$key" "$GODOT_GAMELIST_FILE" > /dev/null; then
        # We don't want to add the 'id'.
        if [[ "$key" != "id" ]]; then
          xmlstarlet ed -L -s "/gameList/game[@id='$id']" -t elem -n "$key" -v "$value" "$GODOT_GAMELIST_FILE"
        fi
      fi
      if [[ "$key" == "video" ]]; then
        local hash
        hash="$(get_hash "$title" "$GODOT_VIDEOS_HASHES_FILE")"
        # If no matching hash in hashes file...
        if [[ -z "$hash" ]]; then
          # ... create a new empty hash.
          echo "\"$title\" = \"\"" >> "$GODOT_VIDEOS_HASHES_FILE"
        fi
        if [[ "$value" != "$hash" ]]; then
          set_hash "$title" "$value" "$GODOT_VIDEOS_HASHES_FILE"
          log "> Getting the video ..."
          CURL_STATUS="$(curl -sS -w %{http_code} "$value" -o "$GODOT_VIDEOS_DIR/$title.gif")"
          if [[ "$CURL_STATUS" -eq 200 ]]; then
            convert_gif_to_mp4
            xmlstarlet ed -L -u "/gameList/game[@id='$id']/$key" -v "./videos/$title.mp4" "$GODOT_GAMELIST_FILE"
          else
            log "ERROR: Something went wrong when dowloading the video!" >&2
          fi
        fi
      elif [[ "$key" == "image" ]]; then
        local hash
        hash="$(get_hash "$title" "$GODOT_IMAGES_HASHES_FILE")"
        # If no matching hash in hashes file...
        if [[ -z "$hash" ]]; then
          # ... create a new empty hash.
          echo "\"$title\" = \"\"" >> "$GODOT_IMAGES_HASHES_FILE"
        fi
        if [[ "$value" != "$hash" ]]; then
          set_hash "$title" "$value" "$GODOT_IMAGES_HASHES_FILE"
          log "> Getting the image ..."
          CURL_STATUS="$(curl -sS -w %{http_code} "$value" -o "$GODOT_IMAGES_DIR/$title.jpg")"
          if [[ "$CURL_STATUS" -eq 200 ]]; then
            xmlstarlet ed -L -u "/gameList/game[@id='$id']/$key" -v "./images/$title.jpg" "$GODOT_GAMELIST_FILE"
          else
            log "ERROR: Something went wrong when dowloading the image!" >&2
          fi
        fi
      else
        xmlstarlet ed -L -u "/gameList/game[@id='$id']/$key" -v "$value" "$GODOT_GAMELIST_FILE"
      fi
    else
      # If the 'value' doesn't exist or it's 'null', delete it
      if xmlstarlet sel -t -v "/gameList/game[@id='$id']/$key" "$GODOT_GAMELIST_FILE" > /dev/null; then
        echo "must delete '<$key>'!"
      fi
    fi
  done
  log "Scraped info for '$title' updated successfully!"
  log
}


function add_game_info() {
  # Check if the game already exists, either by checking the 'id' or the 'path'.
  if xmlstarlet sel -t -v "/gameList/game[@id='$id']" "$GODOT_GAMELIST_FILE" > /dev/null || xmlstarlet sel -t -v "/gameList/game[path='$game_input']" "$GODOT_GAMELIST_FILE" > /dev/null; then
    log "HEY! '$title' is already scraped."
    update_game_info
  else
    log "> Creating a new <game> node in '$GODOT_GAMELIST_FILE' ..."
    # Create a new <system> called "newGame"
    xmlstarlet ed -L -s "/gameList" -t elem -n "newGame" -v "" "$GODOT_GAMELIST_FILE"
    # Add attribute "id" to <newGame>
    xmlstarlet ed -L -s "/gameList/newGame" -t attr -n "id" -v "$id" "$GODOT_GAMELIST_FILE"
    # Add attribute "source" to <newGame>
    xmlstarlet ed -L -s "/gameList/newGame" -t attr -n "source" -v "https://itchio-godot-scraper.now.sh" "$GODOT_GAMELIST_FILE"
    # Add subnodes to <newGame>
    for game_property in "${GAME_PROPERTIES[@]}"; do
      local key
      local value
      key="$(echo $game_property | grep -Eo "^[^ ]+")"
      value="$(echo $game_property | grep -Po "(?<= ).*")"
      if [[ -n "$value" && "$value" != null ]]; then
        if [[ "$key" == "video" ]]; then
          local hash
          hash="$(get_hash "$title" "$GODOT_VIDEOS_HASHES_FILE")"
          # If no matching hash in hashes file...
          if [[ -z "$hash" ]]; then
            # ... create a new empty hash.
            echo "\"$title\" = \"\"" >> "$GODOT_VIDEOS_HASHES_FILE"
          fi
          if [[ "$value" != "$hash" ]]; then
            set_hash "$title" "$value" "$GODOT_VIDEOS_HASHES_FILE"
            # Create a new attribution
            echo "$(underline "GAME: \"$title\" (\"$input_game\")")" >> "$VIDEOS_ATTRIBUTIONS_FILE"
            echo "FILE: \"$title.mp4\"" >> "$VIDEOS_ATTRIBUTIONS_FILE"
            echo "ATTRIBUTIONS: \"$link\"" >> "$VIDEOS_ATTRIBUTIONS_FILE"
            echo "" >> "$VIDEOS_ATTRIBUTIONS_FILE"
            log "> Getting the video ..."
            CURL_STATUS="$(curl -sS -w %{http_code} "$value" -o "$GODOT_VIDEOS_DIR/$title.gif")"
            if [[ "$CURL_STATUS" -eq 200 ]]; then
              convert_gif_to_mp4
              xmlstarlet ed -L -s "/gameList/newGame" -t elem -n "$key" -v "./videos/$title.mp4" "$GODOT_GAMELIST_FILE"
            else
              log "ERROR: Something went wrong when dowloading the 'video!" >&2
            fi
          else
            xmlstarlet ed -L -s "/gameList/newGame" -t elem -n "$key" -v "./videos/$title.mp4" "$GODOT_GAMELIST_FILE"
          fi
        elif [[ "$key" == "image" ]]; then
          local hash
          hash="$(get_hash "$title" "$GODOT_IMAGES_HASHES_FILE")"
          # If no matching hash in hashes file...
          if [[ -z "$hash" ]]; then
            # ... create a new empty hash.
            echo "\"$title\" = \"\"" >> "$GODOT_IMAGES_HASHES_FILE"
          fi
          if [[ "$value" != "$hash" ]]; then
            set_hash "$title" "$value" "$GODOT_IMAGES_HASHES_FILE"
            # Create a new attribution
            echo "$(underline "GAME: \"$title\" (\"$input_game\")")" >> "$IMAGES_ATTRIBUTIONS_FILE"
            echo "FILE: \"$title.jpg\"" >> "$IMAGES_ATTRIBUTIONS_FILE"
            echo "ATTRIBUTIONS: \"$link\"" >> "$IMAGES_ATTRIBUTIONS_FILE"
            echo "" >> "$IMAGES_ATTRIBUTIONS_FILE"
            log "> Getting the image ..."
            CURL_STATUS="$(curl -sS -w %{http_code} "$value" -o "$GODOT_IMAGES_DIR/$title.jpg")"
            if [[ "$CURL_STATUS" -eq 200 ]]; then
              xmlstarlet ed -L -s "/gameList/newGame" -t elem -n "$key" -v "./images/$title.jpg" "$GODOT_GAMELIST_FILE"
            else
              log "ERROR: Something went wrong when dowloading the image!" >&2
            fi
          else
            xmlstarlet ed -L -s "/gameList/newGame" -t elem -n "$key" -v "./images/$title.jpg" "$GODOT_GAMELIST_FILE"
          fi
        else
          # We don't want to add the 'id'.
          if [[ "$key" != "id" ]]; then
            xmlstarlet ed -L -s "/gameList/newGame" -t elem -n "$key" -v "$value" "$GODOT_GAMELIST_FILE"
          fi
        fi
      fi
    done
    # Rename <newGame> to <game>
    xmlstarlet ed -L -r "/gameList/newGame" -v "game" "$GODOT_GAMELIST_FILE"
    log "'$title' scraped successfully!"
    log
  fi

}


function get_options() {
  if [[ -z "$1" ]]; then
    usage
    exit 0
  else
    case "$1" in
#H -h, --help             Print help message and exit.
      -h|--help)
        echo
        underline "$SCRIPT_TITLE"
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
#H -s, --single [NAME]    Scrape a single game.
      -s|--single)
        check_argument "$1" "$2" || exit 1
        shift

        local input_game
        local parsed_game_title

        log "Scraping started ..."
        log

        input_game="$1"
        # Get the parsed title without the extension.
        parsed_game_title="$(parse_game_title "${input_game%.*}")"
        get_game_info "$parsed_game_title"

        log "Scraping done!"
        ;;
#H -a, --all              Scrape all games.
      -a|--all)
        local all_games
        local input_game
        local parsed_game_title

        log "Scraping started ..."
        log

        all_games="$(get_all_games)"
        # Parse the array by delimiting commas.
        IFS="," read -r -a all_games <<< "${all_games[@]}"
        for game in "${all_games[@]}"; do
          # Remove trailing and leadings white spaces because of the comma separated array.
          input_game="$(echo "$game" | awk '{$1=$1};1')"
          # Get the parsed title without the extension.
          parsed_game_title="$(parse_game_title "${input_game%.*}")"
          get_game_info "$parsed_game_title"
        done

        log "Scraping done!"
        ;;
#H -v, --version          Show script version.
      -v|--version)
        echo "$SCRIPT_VERSION"
        exit 0
        ;;
      *)
        echo "ERROR: Invalid option '$1'." >&2
        exit 2
        ;;
    esac
  fi
}


function main() {
  if ! is_retropie; then
    echo "ERROR: RetroPie is not installed. Aborting ..." >&2
    exit 1
  fi

  mkdir -p "$TMP_DIR" && chown -R "$user":"$user" "$TMP_DIR"
  mkdir -p "$LOG_DIR" && chown -R "$user":"$user" "$LOG_DIR"

  mkdir -p "$GODOT_VIDEOS_DIR" && chown -R "$user":"$user" "$GODOT_VIDEOS_DIR"
  touch "$GODOT_VIDEOS_HASHES_FILE" && chown -R "$user":"$user" "$GODOT_VIDEOS_HASHES_FILE"
  touch "$VIDEOS_ATTRIBUTIONS_FILE" && chown -R "$user":"$user" "$VIDEOS_ATTRIBUTIONS_FILE"

  mkdir -p "$GODOT_IMAGES_DIR" && chown -R "$user":"$user" "$GODOT_IMAGES_DIR"
  touch "$GODOT_IMAGES_HASHES_FILE" && chown -R "$user":"$user" "$GODOT_IMAGES_HASHES_FILE"
  touch "$IMAGES_ATTRIBUTIONS_FILE" && chown -R "$user":"$user" "$IMAGES_ATTRIBUTIONS_FILE"

  find "$LOG_DIR" -type f | sort | head -n -9 | xargs -d '\n' --no-run-if-empty rm

  create_gamelist_file

  get_options "$@"

  rm -rf "$TMP_DIR"
}


main "$@"

# function get_date() {
#   local date
#   date="$1"
#   echo "$(date --date="$date" +"%Y%m%dT%H%M%S")"
# }


# get_date "15 February 2019"