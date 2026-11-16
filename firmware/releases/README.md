# Karabas-Pro firmware releases

Ready-to-flash firmware is published on the **[GitHub Releases page](https://github.com/andykarpov/karabas-pro/releases)**.
Download `karabas-pro-<version>.zip` from the latest release. Inside you will find:

| Folder | Contents |
|---|---|
| `ep4ce10/`, `ep4ce6/`, `ep3c10/` | FPGA configuration for your FPGA chip: `.jic` for the EPCS16 flash (one per PCB revision and DAC type), `.sof` / `.rbf`, and Quartus Programmer chains `.cdf` |
| `epm3128/` | CPLD firmware `karabas_pro_cpld.pof` |
| `avr/` | AVR firmware `karabas_pro.hex` and EEPROM images `.eep` for each PCB revision |
| `rom/` | ROM images (ROMain, PQ-DOS, FDImage, ...) |
| `software/` | Network tools for Wi-Fi and PQ-DOS |

`README.md` in the archive explains how to flash every chip.

The version number is the build number of the AVR firmware (`YYMMDDHH`, UTC),
the same number that is compiled into that firmware.

## What is in this folder

This folder does not contain binaries any more. It holds the files that go into
a release as they are:

- `profi/README.md`: flashing instructions;
- `profi/rom/`: ROM images;
- `profi/ep*/*.cdf`: Quartus Programmer chains.

The binaries are built by GitHub Actions from the sources when a release is
made (`.github/workflows/release.yml`). Older binaries, including the Pong,
RK86 and Profi +3e cores, are still available in the git history and in the
older releases. These cores were removed from the sources; the ZX Spectrum +3e
lives on as a ROM bank of the Profi core.
