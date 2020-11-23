# RetroPie itch.io Godot Scraper

A tool for RetroPie to scrape Godot games hosted on https://itch.io/.

This scraper uses the also open-source [itchio-godot-scraper](https://github.com/hiulit/itchio-godot-scraper) project, which scrapes all the Godot games hosted on  https://itch.io/ and creates an API that can be consumed from the following URL https://itchio-godot-scraper.now.sh/api.

## Installation

```
cd /home/pi/
git clone https://github.com/hiulit/RetroPie-Itchio-Godot-Scraper.git
cd RetroPie-Itchio-Godot-Scraper/
sudo chmod +x setup.sh
sudo chmod +x retropie-itchio-godot-scraper.sh
```

## Updating

```
cd /home/pi/RetroPie-Itchio-Godot-Scraper/
git pull
```

## Setup

```
./setup.sh
```
You can install the script to be launched from:

* EmulationStation's RetroPie menu
* RetroPie Setup

![Setup](/examples/setup.jpg)

## Usage

If you installed in EmulationStation's RetroPie menu:

* Enter EmulationStation.
* Go to the RetroPie menu.
* Select **itch.io Godot Scraper** to launch the script.

![EmulationStation Retropie Menu](/examples/emulationstation-retropie-menu.png)


If you installed the scriptmodule, first you have to set it up:

* Run `sudo /home/pi/RetroPie-Setup/retropie_setup.sh`.
* Select **Manage packages**.
* Select **Manage optional packages**.
* Select **itchio-godot-scraper**.
* Select **Install from source**.

Now:

* Run `sudo /home/pi/RetroPie-Setup/retropie_setup.sh`.
* Select **Configuration / tools**.
* Select **itchio-godot-scraper** to launch the script.

In both cases you'll end up with a simple dialog, where you can:

* Select games to scrape.
* Scrape all games.

![Scrape games menu](/examples/scrape-games-menu.jpg)
![Select games to scrape](/examples/select-games-to-scrape.jpg)

If you don't want to install the script, you can just run it from the downloaded folder.

```
cd /home/pi/RetroPie-Itchio-Godot-Scraper/
./retropie-itchio-godot-scraper.sh
```

## Troubleshooting

### The scraper can't find a game

Most likely it's because the developer didn't *properly\** name the game build, but maybe it's because the scrapper does a bad job at finding the games.

See the [itchio-godot-scraper](https://github.com/hiulit/itchio-godot-scraper) project (which is the API where this scraper takes the data from) to better understand how the scraper works and maybe tell the developer to rename the game so it's scrapable by this script. Or even better, contribute to make it better 😉.

*\* It's actually not their fault, but the scraper needs a game to be named in some kind of convention to be able to scrape it.*

## Attributions to the games

This scraper takes all the data from https://itch.io/ and some games have assets (images/videos) that are licensed under various licenses. So, to be as fair as posible, the script adds some files linking to the game's source webpage. These can be located at:

* `/home/pi/RetroPie/roms/godot-engine`
* `/home/pi/RetroPie/roms/godot-engine/images`
* `/home/pi/RetroPie/roms/godot-engine/videos`

## Changelog

See [CHANGELOG](/CHANGELOG.md).

## Authors

Me 😛 [@hiulit](https://github.com/hiulit).

## License

[MIT License](/LICENSE).
