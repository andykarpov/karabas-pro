## What and why

<!-- What changes and why. For RTL: what it was, what it is now. -->

## How it was checked

- [ ] CI builds pass (FPGA ep4ce10 / ep4ce6 / ep3c10, CPLD, AVR)
- [ ] Timing: no negative slack, compared with master per clock pair (`scripts/timing/report.sh` + `scripts/timing/compare.py`)
- [ ] Area: ep4ce6 still fits (it is ~99% full)
- [ ] Simulation, if the change can be checked without hardware (GHDL bench or old/new equivalence)
- [ ] Docs updated (`docs/PROJECT_MEMORY.md`, `docs/BACKLOG.md`, READMEs in all three languages)

## Needs hardware

<!-- What to check on a real board before or after release, or "nothing". -->
