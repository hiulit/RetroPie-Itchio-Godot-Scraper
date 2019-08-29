#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="itchio-godot-scraper"
rp_module_desc="A tool for RetroPie to scrape Godot games hosted on https://itch.io/."
rp_module_help=""
rp_module_section="exp"
rp_module_flags=""
rp_module_licence="MIT https://github.com/hiulit/RetroPie-Itchio-Godot-Scraper/blob/master/LICENSE"

function depends_itchio-godot-scraper() {
  getDepends "ffmpeg" "jq"
}


function sources_itchio-godot-scraper() {
  gitPullOrClone "$md_build" "https://github.com/hiulit/RetroPie-Itchio-Godot-Scraper.git"
}


function install_itchio-godot-scraper() {
  md_ret_files=(
    "retropie-itchio-godot-scraper.sh"
  )
}


function gui_itchio-godot-scraper() {
  bash "$md_inst/retropie-itchio-godot-scraper.sh" --gui
}
