# Quartus II 13.0sp1 build image

Command-line Quartus II 13.0 SP1 Web Edition in Docker, used by
`.github/workflows/build-fpga.yml` and usable locally. It builds every
Quartus project in this repo:

| Family | Devices |
|---|---|
| Cyclone III | EP3C10 |
| Cyclone IV E | EP4CE6, EP4CE10 |
| MAX3000A | EPM3128 (CPLD) |

13.0 SP1 is needed because EP3C10 (Cyclone III) is not supported by newer
Quartus Prime releases.

## Why the tarball is not downloaded from Altera

The old direct download links (`download.altera.com/akdlm/...`) no longer work
for scripts: Intel's mirror returns 404, and Altera's site returns 403 to
non-browser requests. So the image is built from
`quartus-13.0sp1-min-linux64.tar.xz`, a trimmed copy of an existing local
installation. To avoid redistributing Altera software publicly, the tarball is
a release asset of the **private** repository `andykarpov/quartus13-dist`.

CI reads it with the `QUARTUS_DIST_TOKEN` secret (a fine-grained token with
read-only *Contents* access to that repository only) and keeps it in the
Actions cache. The cache expires after 7 days without use, so the first build
after a pause downloads the tarball again (about 600 MB).

## What the tarball contains

`make-dist.sh` copies an installed `quartus/` directory, dropping everything
not needed for command-line builds of the families above:

- 32-bit binaries (`linux/`), JRE, Qt, Perl, EDA, IP, Nios, DSP Builder, SOPC Builder;
- device data for other families (only their small `*_hdr.ddb` headers are
  kept, because Quartus enumerates families at startup);
- programming files for other devices.

It also replaces the bundled `libtbb` with TBB 4.1 from CentOS 7. Without
this, `quartus_map` spins forever at 100% CPU on modern distros
([details](https://retroramblings.net/?p=2049)).

The result is about 1.6 GB unpacked, or 600 MB as `.tar.xz`.

## Producing a new tarball

```sh
docker/quartus13/make-dist.sh /opt/altera/quartus docker/quartus13
```

Then upload it as a release asset of `andykarpov/quartus13-dist` under a new
tag. Update `QUARTUS_DIST_TAG` and `QUARTUS_DIST_SHA256` in
`.github/workflows/build-fpga.yml` to match.

## Local use

```sh
# put quartus-13.0sp1-min-linux64.tar.xz into docker/quartus13/ first
docker build -t karabas-quartus:13.0sp1 docker/quartus13
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/work" \
  -w /work/firmware/src/fpga/profi/syn/ep4ce10 karabas-quartus:13.0sp1 make all jic
```

The wrappers in `bin/` need `QUARTUS_64BIT=1`, which the image sets. Without
it they pick the 32-bit binaries, which aren't shipped here, and recurse
forever.
