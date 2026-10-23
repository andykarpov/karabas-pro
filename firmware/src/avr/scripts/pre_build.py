import datetime
import os

Import("env")

# Generate BUILD_VER if not already defined via command line or environment
# Format: YYMMDDHH (e.g. 26102400)
build_ver = os.environ.get("BUILD_VER", datetime.datetime.now().strftime("%y%m%d%H"))

# Check if BUILD_VER already exists in CPPDEFINES
has_build_ver = False
for define in env.get("CPPDEFINES", []):
    if isinstance(define, tuple) and define[0] == "BUILD_VER":
        has_build_ver = True
        break
    elif isinstance(define, str) and define.startswith("BUILD_VER"):
        has_build_ver = True
        break

if not has_build_ver:
    env.Append(CPPDEFINES=[("BUILD_VER", build_ver)])
