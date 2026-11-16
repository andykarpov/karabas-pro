# CLAUDE.md

Karabas-Pro: клон ZX Spectrum «Профи» на ПЛИС Altera (EP4CE10 / EP4CE6 / EP3C10),
CPLD EPM3128 и супервизор на ATmega328P. Общение с владельцем — по-русски.

Прочитать перед работой:
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md): процесс (ветки, CI, проверки, релизы);
- [docs/PROJECT_MEMORY.md](docs/PROJECT_MEMORY.md): железо, ядра, карта портов, структура репозитория;
- [docs/BACKLOG.md](docs/BACKLOG.md): отложенные задачи. Новые находки, которые не
  делаются сейчас, записывать сюда.

## Жёсткие правила

- `master` меняется только через PR. Ветка от `origin/master`, при грязной основной
  копии — `git worktree`. Не пушить в `master`, даже если push проходит.
- Force push и переписывание опубликованной истории недоступны: коммитить аккуратно,
  проверять `git diff --cached --stat` перед коммитом, не делать `git add -A` в
  основной копии (там лежит чужая незакоммиченная работа).
- Ветку `fix/profi-timing-and-rtl-cleanup` (WIP Gemini) не трогать.
- Бинарники (`.jic .sof .rbf .pof .hex .eep`) в git не коммитить, релизы собирает CI
  (`release.yml`). В `firmware/releases/profi/` лежит только статика релиза: README,
  `rom/`, `ep*/*.cdf`.
- Архив Quartus (`quartus13-dist`) приватный, никуда публично не выкладывать.
- Секреты и токены не трогать и не выводить. `QUARTUS_DIST_TOKEN` владелец ставит сам.
- Файлы в `software/profi` с CRLF показываются изменёнными в любом checkout — не
  коммитить их вместе со своей правкой.

## Железо и проверки

- У владельца одна плата (EP4CE10), проверка на железе бывает редко. Поэтому каждое
  изменение RTL доказывается до PR:
  1. сборка всех трёх чипов (EP4CE6 заполнен на ~99%, правка должна влезть);
  2. тайминги по парам клоков против `master`: `scripts/timing/report.sh <чип> [worktree]`
     и `scripts/timing/compare.py base new`. Ни одного отрицательного slack ни в slow,
     ни в fast модели;
  3. для «переписывания без изменения поведения» — стенд эквивалентности в GHDL:
     старая и новая версия, одинаковые входы, сравнение по тактам, плюс мутации,
     показывающие, что стенд ловит ошибки;
  4. для видеотракта — `firmware/src/fpga/profi/sim/run_scandoubler.sh`.
- Что нельзя доказать без платы — писать в PR («Needs hardware») и в `BACKLOG.md`.
- Констрейнтами (`set_false_path`, `set_clock_groups`) прячут только невозможные пути.
  Реальный путь, который не проходит, чинят в RTL.
- Новых самодельных клоков не вводить: всё на `clk_bus` (28/24 МГц) с clock enable.
  Исключения, которые остались (стробы Z80, T80a), описаны в `BACKLOG.md`.

## Сборка

```sh
# Quartus только в Docker-образе (QUARTUS_64BIT и libtbb в нём уже решены)
docker run --rm --network none -u "$(id -u):$(id -g)" -v "$PWD:/work" \
  -w /work/firmware/src/fpga/profi/syn/ep4ce10 karabas-quartus:13.0sp1 make all jic
firmware/src/build.sh                            # AVR + FPGA + CPLD → firmware/build/
scripts/package_release.sh <name> firmware/build # zip как в релизе
cd firmware/src/avr && pio run                   # только AVR
```

- Образ `karabas-quartus:13.0sp1` собирается из `docker/quartus13/` (архив кладётся
  туда же, в `.gitignore`). Чистая сборка ep4ce10 — около 3 минут.
- `make clean` в `syn/<чип>` удаляет всё, включая `db/`: не запускать его там, где
  идёт другая сборка. Для параллельных сборок разных веток — отдельные worktree.
- В `syn/` после сборки остаются отчёты (`*.rpt`, `timing_*.txt`, `build.log`) —
  не коммитить.

## Особенности кода

- Режимы клоков: `ds80 = 0` → `clk_bus` 28 МГц, `clk_bus_port` 84, `clk_div2` 14;
  `ds80 = 1` → 24 / 72 / 12. Клоки разных режимов в SDC объявлены exclusive.
- `clk_cpu` — гейтированный клок от спада `clk_bus` (`clk_bus and clk_cpu_en`),
  закреплён за глобальной сетью в qsf.
- RTL и qsf ядра Profi — ASCII/UTF-8 с LF; CRLF встречается в `software/profi` и в
  текстах внутри `firmware/releases/profi/rom/` (там он сохраняется намеренно, `-text`).
  Править, не меняя кодировку и переводы строк файла.
- Номер сборки AVR `BUILD_VER` (`YYMMDDHH`, UTC) задаётся переменной окружения,
  иначе текущим временем. Он же — номер релиза.
- В этой системе нет `jq`: в скриптах использовать `gh ... --jq`.
