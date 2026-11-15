# Minimal command-line Quartus II 13.0sp1 Web Edition for karabas-pro builds.
#
# The Quartus tree is not downloaded here: it is a trimmed copy of a local
# installation (linux64 tools only; Cyclone III, Cyclone IV E and MAX3000A
# device data; no GUI, JRE, Qt, EDA, IP or Nios), with the bundled libtbb
# replaced by TBB 4.1 from CentOS 7 to fix the quartus_map hang on modern
# distros. See docker/quartus13/README.md for how the tarball is produced.
#
# Build (the tarball must sit next to this Dockerfile):
#   docker build -t karabas-quartus:13.0sp1 docker/quartus13

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      make xz-utils ca-certificates libgomp1 locales procps \
 && sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen \
 && rm -rf /var/lib/apt/lists/*

ADD quartus-13.0sp1-min-linux64.tar.xz /opt/

# QUARTUS_64BIT: the wrappers in bin/ default to 32-bit binaries, which are
# not shipped in this image (and would recurse forever if missing).
ENV QUARTUS_ROOTDIR=/opt/altera/quartus \
    QUARTUS_64BIT=1 \
    PATH=/opt/altera/quartus/bin:$PATH \
    LANG=en_US.UTF-8

WORKDIR /work
