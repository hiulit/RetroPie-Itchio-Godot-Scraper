# RetroPie itch.io Godot Scraper

A tool for RetroPie to scrape Godot games hosted on https://itch.io/.

This scraper uses the also open-source [itch.io-godot-scraper](https://github.com/hiulit/itchio-godot-scraper) project, which scrapes all the Godot games hosted on  https://itch.io/ and creates an API that can be consumed from the following URL https://itchio-godot-scraper.now.sh/api.

## Installation

```
cd /home/pi/
git clone https://github.com/hiulit/RetroPie-Itchio-Godot-Scraper.git
cd RetroPie-Itchio-Godot-Scraper/
sudo chmod +x retropie-itchio-godot-scraper.sh
```

## Updating

```
cd /home/pi/RetroPie-Itchio-Godot-Scraper/
git pull
```

## Usage

```
./retropie-itchio-godot-scraper.sh [OPTIONS]
```

If no options are passed, you will be prompted with a usage example:

```
USAGE: ./retropie-itchio-godot-scraper.sh [OPTIONS]

Use '--help' to see all the options.
```

## Options

* `--help`: Print help message and exit.
* `--single [OPTIONS]`: Scrape a single game.
* `--all`: Scrape all games.
* `--version`: Show script version.

## Examples

### `--help`

Print the help message and exit.

#### Example

`./retropie-itchio-godot-scraper.sh --help`

### `--single [NAME]`

Scrape a single game.

#### Options

* `name`: Name of the game (or the file name of the game).

#### Example

`./retropie-itchio-godot-scraper.sh --single "Guardian Sphere"`
`./retropie-itchio-godot-scraper.sh --single "Guardian Sphere Linux.pck"`

### `--aññ`

Scrape all games.

#### Example

`./retropie-itchio-godot-scraper.sh --all`

### `--version`

Show script version.

#### Example

`./retropie-itchio-godot-scraper.sh --version`

## Changelog

See [CHANGELOG](/CHANGELOG.md).

## Authors

Me 😛 [@hiulit](https://github.com/hiulit).

## License

[MIT License](/LICENSE).
