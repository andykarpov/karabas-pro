import os

Import("env")

def make_hex(data):
    lines = []
    for addr in range(0, len(data), 16):
        chunk = data[addr:addr+16]
        raw = [len(chunk), (addr >> 8) & 0xFF, addr & 0xFF, 0] + list(chunk)
        csum = (-sum(raw)) & 0xFF
        lines.append(':' + ''.join(f'{b:02X}' for b in raw) + f'{csum:02X}')
    lines.append(':00000001FF')
    return '\n'.join(lines) + '\n'

def post_build_action(source, target, env):
    build_dir = env.subst("$BUILD_DIR")
    firmware_hex = str(target[0])
    karabas_pro_hex = os.path.join(build_dir, "karabas_pro.hex")

    print("[Post-Build] Generating revision-specific EEPROM HEX files...")

    # Normalize line endings to LF for git reproducibility across platforms
    with open(firmware_hex, "rb") as f:
        hex_data = f.read().replace(b"\r\n", b"\n")
    with open(karabas_pro_hex, "wb") as f:
        f.write(hex_data)

    # Base EEPROM configuration (0x00 to 0x11):
    base = [0, 10, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 0, 0, 20, 20]

    # Revision configurations (0x12: LED override, 0x13: HW buttons, 0x14: Language)
    configs = {
        'karabas_pro_revA.eep': base + [10, 20, 0],  # Rev.A/B: led_override=10, hw_buttons=20, lang=0
        'karabas_pro_revC.eep': base + [10, 10, 0],  # Rev.C:   led_override=10, hw_buttons=10, lang=0
        'karabas_pro_revD.eep': base + [20, 10, 0],  # Rev.D+:  led_override=20, hw_buttons=10, lang=0
        'karabas_pro.eep':      base + [20, 10, 0],  # Default (Rev.D+)
    }

    for filename, data in configs.items():
        filepath = os.path.join(build_dir, filename)
        with open(filepath, 'w') as f:
            f.write(make_hex(data))

    print("[Post-Build] Done.")

# Hook on firmware.hex generation
env.AddPostAction("$BUILD_DIR/${PROGNAME}.hex", post_build_action)
