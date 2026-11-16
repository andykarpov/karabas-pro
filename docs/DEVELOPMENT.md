# Разработка Karabas-Pro

Как вносить изменения, проверять их и выпускать прошивку. Обзор железа и ядер —
в [PROJECT_MEMORY.md](PROJECT_MEMORY.md), отложенные задачи — в [BACKLOG.md](BACKLOG.md).

## Коротко

```
ветка от master ──► правка ──► локальная проверка ──► PR ──► CI ──► merge ──► … ──► Release Firmware
                                (сборка, тайминги,           (сборки,          (Actions, вручную)
                                 симуляция)                   артефакты)
```

1. Любое изменение `master` идёт через pull request. Прямой push в `master` запрещён
   (ветка защищена).
2. CI собирает каждый PR и каждый merge: ядра Profi (EP4CE10, EP4CE6, EP3C10), CPLD,
   прошивку AVR. Результаты лежат в артефактах запуска.
3. Бинарники в репозитории не хранятся. Релиз собирает CI из одного коммита
   `master` и публикует на странице Releases.

## Инструменты

| Что | Чем | Где взять |
|---|---|---|
| FPGA (Cyclone III/IV E), CPLD (MAX3000A) | Quartus II 13.0sp1 в Docker-образе `karabas-quartus:13.0sp1` | [docker/quartus13/README.md](../docker/quartus13/README.md) |
| AVR (ATmega328P) | PlatformIO | `pip install platformio` |
| Симуляция VHDL | GHDL 4.x | `apt install ghdl` |
| GitHub из консоли | `gh` | — |

Quartus 13.0sp1 нужен из-за EP3C10: новые Quartus Prime не поддерживают Cyclone III.

**Образ Quartus.** Собирается из архива `quartus-13.0sp1-min-linux64.tar.xz`. Это урезанная
установка: только командная строка, только нужные семейства, исправленная libtbb.
Архив лежит в **приватном** репозитории `andykarpov/quartus13-dist`, публично его не
распространяем.

```sh
gh release download quartus-13.0sp1-min-1 -R andykarpov/quartus13-dist -D docker/quartus13
docker build -t karabas-quartus:13.0sp1 docker/quartus13
```

Если всё же собирать установленным Quartus (`/opt/altera`) напрямую, есть две ловушки:
- нужен `export QUARTUS_64BIT=1`, иначе скрипты-обёртки бесконечно вызывают сами себя;
- на современных дистрибутивах `quartus_map` зависает на 100% CPU из-за старой libtbb,
  лечится TBB 4.1 из CentOS 7 (`docker/quartus13/make-dist.sh` делает это для образа).

## Ветки и pull request'ы

- Ветка от свежего `master`. Имя по смыслу: `fix/…`, `feat/…`, `ci/…`, `docs/…`.
- Если в основной копии есть незакоммиченная работа, удобно завести рядом worktree:
  ```sh
  git fetch && git worktree add -b fix/something ../kp-fix origin/master
  ```
- **Один PR — одно изменение.** Когда железо проверяется редко, только так можно
  потом найти виновника: сборки до и после каждого merge сохраняются в CI.
- Если два PR правят одни и те же файлы, второй можно открыть поверх первого
  (base = ветка первого). После merge первого GitHub сам переключит base на `master`.
- При merge лучше выбирать **Squash and merge**: в `master` ложится один коммит на PR.
- Описание PR следует шаблону: что и зачем, как проверено, что нужно проверить на
  железе.

## Что делает CI

| Workflow | Когда | Что делает | Результат |
|---|---|---|---|
| `build-fpga.yml` | PR и push в `master`, если тронуты `firmware/src/fpga/profi`, `firmware/src/cpld`, `docker/quartus13` | Собирает ep4ce10/ep4ce6/ep3c10 (`make all jic`) и CPLD в Docker-образе | Артефакты `profi-<чип>` (jic, sof, rbf, отчёты) и `cpld-epm3128` (pof). В summary — занятость LE и таблицы setup/hold |
| `build-avr.yml` | PR и push в `master`, если тронут `firmware/src/avr` | `pio run` | Артефакт `karabas-pro-avr-firmware` (hex, eep, `build_ver.txt`), сводка по памяти |
| `sim.yml` («GHDL simulation») | только вручную: Actions → GHDL simulation → Run workflow | GHDL: развёртка скандаблера во всех 6 режимах, RTC в `avr.vhd`, микшер и ЦАП, карта памяти +3e | Результаты в summary |
| `release.yml` | Вручную или push тега `v*` | Собирает всё и публикует релиз | Релиз `karabas-pro-<tag>.zip` |

Артефакты хранятся 90 дней: Actions → нужный запуск → Artifacts. Это и есть тестовые
прошивки любого PR или merge.

Для сборки FPGA в CI нужен секрет `QUARTUS_DIST_TOKEN`: fine-grained токен с правом
Contents: Read-only на `andykarpov/quartus13-dist`. Если сборки падают на шаге
«Download Quartus tarball», первым делом проверить, не истёк ли токен.

## Как проверить изменение без железа

Плата одна (EP4CE10), стенд громоздкий, поэтому основная проверка — сборка, анализ
таймингов и симуляция. Перечисленное ниже нужно сделать до PR.

### Сборка и площадь

EP4CE6 заполнен на 99% (около 6230 из 6272 LE). Любая правка RTL должна влезть и в него.
CI покажет занятость в summary каждого проекта.

### Тайминги

Смотреть только на сводку `Slow 85C Setup Summary` недостаточно: худшая цифра
по клоку может прятать реальные проблемы. Сравнивайте худший slack **по каждой паре
клоков** со сборкой `master`:

```sh
git worktree add --detach ../kp-base origin/master       # база для сравнения
scripts/timing/report.sh ep4ce10 ../kp-base              # ~3.5 мин
scripts/timing/report.sh ep4ce10                         # текущая ветка
scripts/timing/compare.py ../kp-base/firmware/src/fpga/profi/syn/ep4ce10/timing_pairs.txt \
                          firmware/src/fpga/profi/syn/ep4ce10/timing_pairs.txt
```

`report.sh` делает чистую сборку в Docker и пишет `timing_pairs.txt` (худший slack
каждой пары, slow и fast модели, setup и hold) и `timing_failing.txt` (все
нарушающие пути). `compare.py` печатает худшее по углам и все пары с запасом меньше 1 нс.

Правила:
- **Ни одного отрицательного slack** ни в одной модели, на всех трёх чипах.
- Раскладка фиттера меняется от любой правки, и пути «на грани» могут гулять на
  ±1,5 нс между сборками. Если путь проходит впритык, это повод для правки RTL.
  Удачная раскладка проблему не решает.
- `set_false_path` / `set_clock_groups` — только для путей, которых в железе
  действительно нет. Пример: клоки двух режимов `ds80` (84/28/14 и 72/24/12 МГц)
  никогда не работают одновременно. Реальный путь констрейнтом не прячут.
- Новые самодельные клоки (счётчик, строб или защёлка вместо клока) не допускаются.
  Нужен clock enable от `clk_bus`. Список того, что осталось, есть в `BACKLOG.md`.

### Симуляция

Стенды лежат в [firmware/src/fpga/profi/sim](../firmware/src/fpga/profi/sim/README.md).

```sh
firmware/src/fpga/profi/sim/run_scandoubler.sh     # развёртка VGA во всех режимах, сравнение с эталоном
firmware/src/fpga/profi/sim/run_avr_audio.sh       # RTC в avr.vhd, микшер против модели, ЦАП (I2S / LSB-justified)
```

Если меняется развёртка намеренно, обновите `expected_scandoubler.txt` в том же PR.

Для переписывания RTL «без изменения поведения» лучший способ проверки —
**стенд эквивалентности**. Старую версию модуля (`git show master:путь`) и новую
кладут рядом, подают одинаковые входы (настоящий источник плюс случайные воздействия)
и сравнивают выходы на каждом такте. Потом нарочно портят новую версию и убеждаются,
что стенд это ловит. Так проверены #128 (`WAIT_C`, `fdd_cnt`) и #129 (OSD).

### Что оставить на железо

Всё, что нельзя доказать симуляцией: обмен с CPLD, SRAM, AVR и внешними устройствами,
точные моменты стробов Z80, поведение мониторов. В PR это пишется в разделе
«Needs hardware», а если проверка откладывается, задача заносится в `BACKLOG.md`.

## Обновление ROM (ROMain и др.)

1. Новые образы ROMain (`KarabasPRO_*.rom` из архива автора) положить поверх
   `firmware/src/fpga/profi/rom/ROMain_*.rom`.
2. Перегенерировать `.hex` рядом: `python3 -I ./bin2hex -o X.hex -b X.rom` (в каталоге
   `rom/`). Результат должен побайтно совпадать по формату с тем, что в git.
3. Заменить папку `firmware/releases/profi/rom/ROMain_<версия>/` (образы и
   `changelog.txt`). Она попадает в zip релиза.
4. PR → merge → релиз. Ничего перепаковывать вручную не нужно: CI соберёт jic с
   новыми ROM.

## Релиз

1. Убедиться, что в `master` есть всё нужное и CI последнего merge зелёный.
2. Actions → **Release Firmware** → **Run workflow** (ветка `master`).
   - `tag`: можно не заполнять, будет `v<BUILD_VER>`. `BUILD_VER` — время UTC
     `YYMMDDHH`, этот же номер вшивается в прошивку AVR.
   - `title`: можно не заполнять, будет `Build <BUILD_VER>`. Лучше написать, что
     главное в релизе.
   - `dry_run`: только собрать и упаковать, zip останется в артефактах запуска.
     Полезно, если менялся состав архива.
3. Workflow собирает FPGA, CPLD и AVR из одного коммита и пакует
   `karabas-pro-<tag>.zip` (`scripts/package_release.sh`). Потом ставит тег и
   публикует релиз. В описании будут номер сборки AVR, коммит и список PR.
4. При желании дописать описание релиза руками на GitHub.

Суффиксы в имени (`-romain…`) не используются. Если обновились только ROM, просто
выпускается новый релиз со следующим номером.

Состав архива определяет `scripts/package_release.sh`. Статическая часть
(инструкция, `rom/`, цепочки программатора `.cdf`) лежит в `firmware/releases/profi/`.
Сетевой софт берётся из `software/profi/net-tools/release/`.

## Локальная сборка без CI

```sh
firmware/src/build.sh                         # AVR + FPGA (Docker) + CPLD → firmware/build/
scripts/package_release.sh test firmware/build   # karabas-pro-test.zip, как в релизе
```

Отдельно: `build_avr.sh` (принимает `BUILD_VER=…`), `build_profi.sh`, `build_cpld.sh`.

## Инфраструктура

- **`andykarpov/quartus13-dist`** (приватный): релиз `quartus-13.0sp1-min-1` с архивом
  Quartus и его `.sha256`. Новый архив делается так: `docker/quartus13/make-dist.sh`,
  выложить под новым тегом, обновить `QUARTUS_DIST_TAG` и `QUARTUS_DIST_SHA256` в
  `.github/workflows/build-fpga.yml`.
- **Секрет `QUARTUS_DIST_TOKEN`** в этом репозитории, см. выше.
- **Кэш Actions** хранит архив Quartus. Если кэш не использовался 7 дней, он
  исчезает, и первая сборка после паузы скачивает архив заново (~600 МБ).

## Частые проблемы

| Симптом | Причина и что делать |
|---|---|
| `quartus_map` висит на 100% CPU | старая libtbb; собирать в Docker-образе |
| `Argument list too long` при запуске Quartus | нет `QUARTUS_64BIT=1` |
| После checkout файлы в `software/profi` сразу «изменены» | CRLF в git при `eol=lf` в `.gitattributes`, см. `BACKLOG.md`. Эти файлы не коммитить вместе со своей правкой |
| `make clean` в `syn/<чип>` «съел» результаты | он удаляет всё, включая `db/`; не запускать его в каталоге, где идёт сборка |
| Сборка FPGA в CI падает на скачивании Quartus | истёк или потерял доступ `QUARTUS_DIST_TOKEN` |
