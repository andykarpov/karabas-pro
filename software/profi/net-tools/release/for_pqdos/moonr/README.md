# Moon Rabbit - gopher browser for PQ-DOS

Gopher browser for Karabas Pro with ESP-12 chip.

## Usage

Connect to AP via some software(for example NetMan).

Copy `moonr.com` and `index.gph` to any directory(but to the same) of your CF card, load PQ-DOS and start `moonr.com`.

THIS SOFTWARE NOT SUPPORT MICRODOS! It's important!

## Development

To compile project all you need is [sjasmplus](https://github.com/z00m128/sjasmplus).

You may use or not use GNU Make. But for just build enought only sjasmplus: `sjasmplus main.asm`.

To getting working distro you'll need:

 * Compiled binary

 * `index.gph` - starting page that's will be shown on start

Some parts based on my Internet NEXTplorer(for zx spectrum next) and MSX's version of Moon Rabbit. 

## Development plan

 - [X] Publish first version and get first happy users
 - [ ] Add support for some graphics format

## License

I've licensed project by [Nihirash's Coffeeware License](LICENSE).

Please respect it - it isn't hard.

