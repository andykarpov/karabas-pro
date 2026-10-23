#!/bin/sh

export PATH=$HOME/.platformio/penv/bin:$PATH

echo "Building universal AVR firmware"

cd avr

BUILD_VER=`date +%y%m%d%H`
echo "Build version: $BUILD_VER"

pio run -t clean
export PLATFORMIO_BUILD_FLAGS="-DBUILD_VER=$BUILD_VER -Wall"
pio run

# Generate revision-specific EEPROM Intel HEX files:
# Byte 0x12: LED override (10 = enabled, 20 = disabled)
# Byte 0x13: HW buttons   (10 = enabled, 20 = disabled)
python3 -c "
def make_hex(data):
    lines = []
    for addr in range(0, len(data), 16):
        chunk = data[addr:addr+16]
        raw = [len(chunk), (addr >> 8) & 0xFF, addr & 0xFF, 0] + list(chunk)
        csum = (-sum(raw)) & 0xFF
        lines.append(':' + ''.join(f'{b:02X}' for b in raw) + f'{csum:02X}')
    lines.append(':00000001FF\n')
    return '\n'.join(lines)

base = [0, 10, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 0, 0, 20, 20]

configs = {
    'karabas_pro_revA.eep': base + [10, 20],  # Rev.A/B: led_override=10, hw_buttons=20
    'karabas_pro_revC.eep': base + [10, 10],  # Rev.C:   led_override=10, hw_buttons=10
    'karabas_pro_revD.eep': base + [20, 10],  # Rev.D+:  led_override=20, hw_buttons=10
    'karabas_pro.eep':      base + [20, 10],  # Default (Rev.D+)
}

for filename, data in configs.items():
    with open(f'.pio/build/ATmega328/{filename}', 'w') as f:
        f.write(make_hex(data))
"

# Distribute universal firmware & revision EEPROMs to release folders
TARGET_DIRS="../../releases/profi/avr ../../releases/profi_plus3e/avr ../../releases/pong ../../releases/rk86"

for DIR in $TARGET_DIRS; do
  cp .pio/build/ATmega328/firmware.hex "$DIR/karabas_pro.hex"
  cp .pio/build/ATmega328/karabas_pro.eep "$DIR/karabas_pro.eep"
  cp .pio/build/ATmega328/karabas_pro_revA.eep "$DIR/karabas_pro_revA.eep"
  cp .pio/build/ATmega328/karabas_pro_revC.eep "$DIR/karabas_pro_revC.eep"
  cp .pio/build/ATmega328/karabas_pro_revD.eep "$DIR/karabas_pro_revD.eep"
done

pio run -t clean

echo "Done"

cd ..
