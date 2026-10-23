# База знаний и память проекта Karabas-Pro

## 1. Введение и концепция проекта

**Karabas-Pro** («Карабас-Про») — открытый аппаратно-программный проект компактного клона ретро-компьютера **ZX Spectrum / Profi (Профи 5.06)** на базе современной ПЛИС (FPGA Altera/Intel Cyclone IV), вспомогательной CPLD (Altera MAX 3000A) и микроконтроллера (AVR ATmega328P).

* **Авторы:** Энди Карпов (*Andy Karpov*, <andy.karpov@gmail.com>), Олег Стариченко (*Oleh Starychenko*, <solegstar@gmail.com>)
* **Лицензия:** [LICENSE](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/LICENSE) (Open Source Hardware / Software)
* **Главная идея:** Создать полнофункциональный клон «Профи» с **реальными контроллерами FDD и HDD (CompactFlash)**, уместив всю системную плату строго в габариты стандартного 3.5″ дисковода гибких магнитных дисков (с соответствующими посадочными отверстиями под корпус дисковода).
* **Базовые репозиторные файлы:**
  * Документация пользователя: [karabas-pro-user-manual-v1.odt](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/docs/karabas-pro-user-manual-v1.odt), [karabas-pro-user-manual-v1-en.pdf](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/docs/karabas-pro-user-manual-v1-en.pdf)
  * Руководство разработчика: [karabas-pro-dev-manual-v1_01.pdf](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/docs/karabas-pro-dev-manual-v1_01.pdf)
  * История изменений печатных плат: [CHANGELOG-PCB.md](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/CHANGELOG-PCB.md)
  * Журнал доработок (Errata / Hotfixes): [ERRATA-REVA.md](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/ERRATA-REVA.md), [ERRATA-REVB.md](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/ERRATA-REVB.md), [ERRATA-REVC.md](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/ERRATA-REVC.md), [ERRATA-REVDS.md](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/ERRATA-REVDS.md), [karabas-pro-hotfixes-v1.odt](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/docs/karabas-pro-hotfixes-v1.odt)

---

## 2. Аппаратная архитектура (Hardware Architecture)

Архитектура системы распределена между тремя вычислительными чипами (FPGA + CPLD + MCU), аналоговым трактом и физическими накопителями.

```mermaid
flowchart TD
    subgraph Host ["Вычислительное ядро"]
        FPGA["FPGA Altera Cyclone IV<br/>(EP4CE10 / EP4CE6 / EP3C10)<br/>• Z80 Core (T80se)<br/>• Видеоконтроллер VGA (ZX + Profi)<br/>• Звук (TurboSound, Soundrive, SAA1099)<br/>• Memory Mux, SD/SPI, OSD Engine"]
        SRAM["Быстродействующее ОЗУ<br/>CY62167 / BS62LV1600<br/>• Rev A-D: 2 MB<br/>• Rev E+: до 6 MB (4 MB RAM + 2 MB ROM)"]
        SPIFLASH["Dual SPI Flash (W25Q16 / M25P16)<br/>Конфигурация FPGA + Банки ROM"]
        FPGA <--> SRAM
        FPGA <--> SPIFLASH
    end

    subgraph Bridge ["Интерфейсный мост 5V"]
        CPLD["CPLD Altera MAX 3000A<br/>(EPM3128ATC100)<br/>Демультиплексирование шины,<br/>тайминги FDD и Nemo IDE"]
        FDC["FDC Чип MB8877A / КР1818ВГ93<br/>Контроллер НГМД 1793"]
        BUFF["74LS06 / 74LS38<br/>Буферы с открытым коллектором"]
        CF["Слот CompactFlash<br/>(Режим Nemo IDE / Profi IDE)"]
        FDD_PORT["34-pin FDD Header<br/>Подключение реального 3.5\" флоппи"]
        
        FPGA <-->|"16-bit Parallel Bus"| CPLD
        CPLD <--> FDC
        FDC <--> BUFF <--> FDD_PORT
        CPLD <--> CF
    end

    subgraph Controller ["Системный контроллер и ввод-вывод"]
        AVR["MCU Atmel ATmega328P-AU (16 МГц)<br/>• Опрос PS/2 клавиатуры (XT)<br/>• Опрос PS/2 мыши (Kempston/Serial)<br/>• Декодер SEGA / Atari джойстика<br/>• Управление OSD-меню и окнами<br/>• RTC мост"]
        RTC["RTC DS1307Z+ (I2C) + CR2032"]
        PS2_KB["PS/2 Клавиатура"]
        PS2_MS["PS/2 Мышь"]
        JOY["DB9 Джойстик (Kempston / Sega)"]
        
        AVR <-->|"I2C"| RTC
        AVR <-->|"SPI Master/Slave"| FPGA
        PS2_KB --> AVR
        PS2_MS --> AVR
        JOY --> AVR
    end

    subgraph Periph ["Внешние интерфейсы и звук"]
        ESP["Wi-Fi ESP8266 (ESP-12E/F)<br/>UART @ 115200 (ZiFi / ZX-UNO)"]
        DAC["Audio DAC TDA1543 / TDA1543A<br/>(16-bit I2S Stereo)"]
        TAPE["Tape In / Out (LM311 компаратор)"]
        VGA["VGA DB15 (RGB 3:3:3, 512 цветов, 50 Гц)"]
        SD["MicroSD Card (Z-Controller / DivMMC)"]
        BUZZER["Пьезодинамик (Buzzer)"]

        FPGA -->|"I2S"| DAC
        FPGA <--> ESP
        FPGA <--> TAPE
        FPGA --> VGA
        FPGA <--> SD
        FPGA --> BUZZER
    end
```

### Основная элементная база (BOM)
* **U1 (FPGA):** Altera Cyclone IV `EP4CE10E22C8N` (начиная с Rev.E обязателен EP4CE10 из-за объёма логических элементов; в ранних версиях допускался `EP4CE6E22C8N` или Cyclone III `EP3C10E144C8N`). Корпус QFP-144/145.
* **U4 (CPLD):** Altera MAX 3000A `EPM3128ATC100-10N` (128 макроячеек, LQFP-100, 3.3V с толерантностью к 5V входам).
* **U5 (MCU):** Atmel `ATMEGA328P-AU` (TQFP-32, 16 МГц от кварцевого резонатора).
* **U6 (FDC):** Fujitsu `MB8877A` (или советский аналог `КР1818ВГ93`) в DIP-40 панельке.
* **U2, U19, U20 (SRAM):** Быстродействующая статическая память `CY62167EV30LL` / `BS62LV1600` (16 Мбит = 2 МБ, 55 нс, TSOP-48). В Rev.E установлено 3 микросхемы (суммарно 6 МБ).
* **U3, U3''1 (SPI Flash):** Сдвоенная флеш-память `W25Q16` / `M25P16` (SOIC-8), выбор активной микросхемы джампером JP2 (`FLASH 1/2`).
* **U11 (DAC):** Philips `TDA1543` или `TDA1543A` (стерео ЦАП I2S, DIP-8).
* **U10 (Wi-Fi):** `ESP8266` (модуль ESP-12E/F).
* **U9 (RTC):** Maxim `DS1307Z+` (SOIC-8) с резервной батареей CR2032 или диодным питанием.
* **U16 (Tape):** Компаратор `LM311` (SOIC-8) для магнитофонного входа.
* **U17, U18 (FDD Buffers):** `74LS06` (инверторы ОК) и `74LS38` (2И-НЕ ОК) для согласования с 34-пиновым шлейфом дисковода.
* **Питание:**
  * Первичный стабилизатор: импульсный понижающий `LM2596S-5` (12V $\to$ 5V в ревизиях D+).
  * Линейные LDO: `AMS1117-3.3` (3.3V), `AMS1117-2.5` (2.5V для VCCIO/PLL FPGA), `AMS1117-1.2` (1.2V Core FPGA), отдельный LDO 3.3V для ESP8266 (Rev.ER/EU).

---

## 3. Хронология и отличия ревизий плат (Hardware Revisions)

| Ревизия | Ключевые изменения и особенности |
|---|---|
| **Rev.A** | Первая базовая версия платы. Питание строго 5V. 1x SRAM 2 МБ. EP4CE6. Выявлен ряд ошибок ([ERRATA-REVA.md](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/ERRATA-REVA.md)): отсутствие подтяжек FDC, тесное расположение аудио-разъема к VGA, смещение посадочных отверстий CF. |
| **Rev.B** | Исправлены подтяжки FDC (10к на RDATA, WPRT, TR00, INTRQ, DRQ), скорректированы номиналы фильтров (R25=820 Ом, R26/R27=750 Ом, C1/C2=10 мкФ), аудио-джек сдвинут, добавлена запретная зона под антенной ESP-12. |
| **Rev.C** | Добавлены подтяжки 10к на линии `/AVR_CS`, `BTN1`, `BTN2`. Обновлен футпринт DB9. Добавлены DIP-переключатели на свободные пины FPGA. |
| **Rev.C1** | Пин SD CMD переведён на выделенный PIN_115 FPGA. Слот CF переведён на питание 3.3V (вместо 5V), пин 44 CF (`/REG`) подтянут к 3.3V. |
| **Rev.D** | Поддержка питания 12V через импульсный преобразователь `LM2596S-5`. Тумблер включения питания. Защитные супрессоры и предохранители по шине 5V. Светодиоды активности CF и SD. Вторая микросхема Flash и джампер выбора. Поддержка TurboFDC. Диодная сборка для подпитки RTC без батарейки. |
| **Rev.DS / DS'** | Убраны DIP-переключатели. Добавлен разъём J10 для второго джойстика. Аппаратная поддержка 3-кнопочных геймпадов SEGA. Встроенный звуковой бузер с перемычкой отключения JP3. Интегрирована схема Tape In/Out (компаратор LM311). Увеличены контактные площадки SO-8 Flash под W25Q16 и M25P16. В Rev.DS' исправлен футпринт Q2 и номиналы обвязки магнитофона. |
| **Rev.E** | Установлены 3 микросхемы SRAM (суммарно до **6 МБ SRAM**: 4 МБ host RAM + 2 МБ host ROM). Разъём uBus переведён на 5-пиновый коннектор для вывода UART2. Минимальный чип FPGA — **EP4CE10**. |
| **Rev.Ё (ER)** | Шелкография на русском языке. Универсальный посадочный футпринт аудиогнезда TRRS (SMT/THT). Выделенный LDO 3.3V для ESP8266. Обновлённый футпринт слота MicroSD. |
| **Rev.Ї (EU)** | **Текущая стабильная релизная ревизия.** Вся шелкография переведена на украинский язык. Соответствует схемотехнике Rev.E/ER. |
| **Rev.F** | Экспериментальная ревизия (в разработке, архивные бэкапы в [pcb/revF](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/pcb/revF)). |

### Конфигурационный байт ревизий (Configuration Byte)
Конфигурация прошивки FPGA/ROM определяется байтом конфигурации в ПЗУ/Flash ([karabas_pro_cfg.txt](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/docs/karabas_pro_cfg.txt)):
* **Bit 0:** Модель ЦАП (`0` = TDA1543, `1` = TDA1543A)
* **Bit 2:** Магнитофонный тракт (`0` = без Tape, `1` = Tape In/Out активен)
* **Bit 4:** Языковой мод шелкографии (`0` = E/Ё, `1` = Ї mod при B5=1)
* **Bit 5:** Объем SRAM (`0` = 2 МБ, `1` = 6 МБ)
* Итоговые значения масок:
  * `0x00` / `0x01` — Rev.A (TDA1543 / TDA1543A)
  * `0x04` / `0x05` — Rev.DS (TDA1543 / TDA1543A)
  * `0x24` / `0x25` — Rev.E (TDA1543 / TDA1543A)
  * `0x34` / `0x35` — Rev.Ї (TDA1543 / TDA1543A)

---

## 4. Прошивки ПЛИС (FPGA Cores)

В каталоге [firmware/src/fpga](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/fpga) реализовано несколько независимых ядер:

### 1. Profi Core (Основное ядро)
Файлы ядра: [karabas_pro.vhd](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/fpga/profi/rtl/karabas_pro.vhd).
* **Процессор:** Софт-ядро Z80 (`T80se`) с поддержкой режимов:
  * Стандартный: 3.5 МГц
  * Turbo 7 МГц (без циклов WAIT)
  * Turbo 14 МГц (с циклами WAIT)
* **Видеоподсистема:**
  * Классический экран ZX Spectrum (256x192).
  * Расширенный графический экран Profi (512x240, монохром или цветной режим с палитрой).
  * Палитра: 16 цветов, выбираемых из палитры 512 цветов (RGB 3:3:3).
  * Выход VGA 30 кГц (частота кадров 50 Гц или 60 Гц через меню).
  * Аппаратный OSD оверлей для статусов и сервисного меню.
* **Звук:**
  * **TurboSound:** Два генератора AY-3-8910 / YM2149F с выбором режима микширования (ABC / ACB / Mono) и детекцией AY/YM.
  * **Soundrive / Covox:** 4 канала 8-битного стерео ЦАП (порты `#0F, #1F, #3F, #4F, #5F`, Covox `#FB`).
  * **Philips SAA1099:** 6-канальный стерео звуковой процессор (в конфигурации для EP4CE10).
  * Вывод звука формируется цифровым I2S потоком на внешний ЦАП TDA1543/A.
* **Накопители и периферия:**
  * Real FDC (через CPLD и MB8877A) с поддержкой ускоренного шага TurboFDC.
  * Real IDE (CompactFlash) в режимах Nemo IDE и Profi IDE.
  * SD-карта по стандартам Z-Controller и DivMMC.
  * Доступ к SPI Flash напрямую через системные порты.
  * Эмуляция Profi RTC + NVRAM (240 ячеек), синхронизированная с DS1307.
  * Сетевой интерфейс: ZX-UNO UART / ZiFi API (@115200) для ESP8266 + вторичный UART2.

### 2. Дополнительные конфигурации ядер
* **Profi Plus3e:** Модификация ядра Profi с интеграцией BIOS ZX Spectrum +3e и поддержкой ESXDOS через DivMMC.
* **Radio-86RK (РК86):** Полная реализация советского ПЭВМ «Радио-86РК» на том же железе Karabas-Pro ([firmware/releases/rk86](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/releases/rk86)).
* **Pong:** Аппаратная тестовая игра Pong для проверки видеовыхода и звукового тракта ([firmware/releases/pong](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/releases/pong)).
* **UART:** Специализированное ядро для тестирования и отладки последовательного канала.

---

## 5. Прошивка CPLD (EPM3128ATC100)

Исходный код: [karabas_pro_cpld.vhd](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/cpld/rtl/karabas_pro_cpld.vhd).

CPLD выполняет критическую связующую функцию между 3.3-вольтовой FPGA и 5-вольтовой ретро-периферией:
1. **Шина обмена с FPGA:** 16-битная двунаправленная параллельная шина `SD(15:0)`, адресные селекторы `SA(1:0)`, стробы тактирования и сигнал `SDIR` (направление Nemo IDE).
2. **Контроллер FDC (MB8877A):**
   * Формирование управляющих сигналов `/NWR`, `/NRD`, `/NCS`, адресных линий `FDC_A(1:0)`.
   * Синхронизация и деление тактовых частот (`FDC_CLK`, `FDC_RCLK`).
   * Логика выбора накопителей (`DS0`, `DS1`, `SIDE`) и формирование импульсов записи/чтения (`WDATA`, `RDATA`, `NRAWR`).
   * Обработка прерываний и запросов данных (`INTRQ`, `DRQ`).
3. **Контроллер Nemo IDE / CF Card:**
   * Мультиплексирование 16-битных и 8-битных обращений к шине IDE HDD.
   * Формирование сигналов `/CS0`, `/CS1`, `/RD`, `/WR`, `HDD_A(2:0)`.

---

## 6. Прошивка AVR микроконтроллера (ATmega328P)

Проект PlatformIO: [firmware/src/avr](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr).

Стек компиляции: **чистый bare-metal `avr-gcc` / `avr-libc`** (Arduino Framework полностью исключен, освобождено > 6.4 КБ Flash).

Микроконтроллер выступает в роли сервисного супервизора системы:
* **Аппаратный слой HAL ([include/hal.h](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/include/hal.h), [src/hal.cpp](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/src/hal.cpp)):**
  * Прямой 1-тактовый доступ к GPIO через регистры `PORTx`/`DDRx`/`PINx`.
  * Регистровый SPI-мастер на 1 МГц (Mode 0) с защитой от сброса master-режима при внешних манипуляциях на PB2/SS.
  * Аппаратный I2C/TWI мастер с таймаутами для работы с RTC DS1307 (~150 байт вместо 2 КБ библиотеки `SBWire`).
  * Системный таймер 1 мс на базе Timer0 CTC для отсчета `millis()` и точных микросекундных задержек.
  * Быстрый АЦП (prescaler 64) для аппаратных кнопок `BTN1` и `BTN2` (ADC6 / ADC7).
  * Прямые векторы прерываний `INT0_vect` (клавиатура, PD2) и `INT1_vect` (мышь, PD3) без оверхеда `WInterrupts.c`.
* **PS/2 Keyboard Subsystem ([ZXKeyboard](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/lib/ZXKeyboard)):** Приём XT/AT скан-кодов, трансляция в матрицу клавиатуры ZX Spectrum (5x8) + расширенные клавиши Profi. Хранение настроек в EEPROM через `<avr/eeprom.h>`.
* **PS/2 Mouse Subsystem ([ZXMouse](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/lib/ZXMouse), [PS2Mouse](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/lib/PS2Mouse)):** Поддержка Kempston Mouse (координаты X, Y, кнопки, колесо Z) и эмуляция Serial Microsoft Mouse (COM).
* **Джойстики ([ZXJoystick](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/lib/ZXJoystick), [SegaController](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/lib/SegaController)):** Поддержка стандартного Atari/Kempston джойстика и опрос 3-/6-кнопочных геймпадов SEGA Mega Drive (переключение мультиплексора Select).
* **RTC Subsystem ([ZXRTC](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/lib/ZXRTC), [RTC/DS1307](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/lib/RTC)):** Обмен по аппаратному TWI с микросхемой DS1307, хранение настроек в NVRAM, передача времени в FPGA через SPI.
* **OSD Engine ([ZXOSD](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/lib/ZXOSD), [OSD](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/lib/OSD)):**
  * Полноценная Data-driven архитектура меню: 16 дескрипторов пунктов главного меню и 7 полей RTC размещены в `PROGMEM`.
  * Драйвер OSD изолирован от C++ `Print`/`Stream`, использует прямой вывод символов.
  * Всплывающее меню настроек и инфо-строки (Popups).
  * Полноэкранный оверлей настройки часов, режимов видео и дисководов.
  * Мультиязычность: английский ([lang_en.h](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/lib/ZXOSD/lang_en.h)), русский ([lang_ru.h](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/lib/ZXOSD/lang_ru.h)), украинский ([lang_ua.h](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/avr/lib/ZXOSD/lang_ua.h)).

### Расход памяти прошивки ATmega328P:
* **Flash:** 26 084 – 26 238 байт (~79.6% – 80.1%) в зависимости от конфигурации (исходно было 32 512 байт / 99.2%). Высвобождено **> 6.4 КБ**.
* **SRAM:** 884 – 888 байт (43.2%) из 2048 байт. Свободно более 1.1 КБ оперативной памяти.

### Горячие клавиши OSD:
| Комбинация | Действие |
|---|---|
| **Menu + ESC** | Открыть / закрыть экранное меню OSD Setup |
| **Menu + F1..F4** | Выбор активного банка ПЗУ (ROM Bank) |
| **Menu + F5** | Включение / выключение режима Turbo FDC |
| **Menu + F6** | Включение / выключение Covox / Soundrive |
| **Menu + F7** | Переключение микширования PSG (ABC / ACB / Mono) |
| **Menu + F8** | Выбор типа звукового чипа (AY-3-8910 / YM2149F) |
| **Menu + F9** | Режим видеосигнала (RGB 15 кГц / VGA 30 кГц) |
| **Menu + F10** | Кадровая синхронизация (50 Гц / 60 Гц) |
| **Menu + F11** | Переключение тактовой частоты (3.5 / 7 / 14 МГц) |
| **Menu + Tab** | Смена букв физических дисководов (Swap FDD A $\leftrightarrow$ B) |
| **Menu + J** | Тип джойстика (Kempston / Sega) |
| **Menu + M** | Режим маппинга джойстика (Kempston / Sinclair 1-2 / Cursor / QAOP) |
| **Menu + D** | Включение / отключение контроллера DivMMC |
| **Menu + N** | Включение / отключение контроллера Nemo IDE |
| **Ctrl + Alt + Del** | Программный сброс (Reset) |

---

## 7. Карта системных портов (Developer Reference)

Сводные данные из [karabas-pro-dev-manual-v1_01.pdf](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/docs/karabas-pro-dev-manual-v1_01.pdf):

### 1. Системные порты и управление памятью
* **`#7FFD` (`#FD`):** Стандартный порт диспетчера памяти 128K (CMR0). Дешифрация: `A15=0, A1=0` или полный адрес `#7FFD`. Блокируется 5-м битом при `#DFFD.4 = 1`.
* **`#DFFD`:** Порт расширенной памяти Profi (CMR1). Управляет верхними страницами RAM/ROM (до 1024K в стандарте Profi) и доступом к расширенной периферии.
* **`#1FFD`:** Дополнительный порт конфигурации Profi.
* **`#FE`:** Бордюр, бипер, чтение магнитофона (EAR/MIC) и опрос полурядов клавиатуры.
* **`#7E`:** Регистр расширенной палитры Profi (9-битный цвет RGB 3:3:3, 16 цветов).
* **`#008B`:** Расширенный порт конфигурации PQ-DOS. Управляет страницами ROM (биты 0..5), принудительным сигналом DOS (`ONROM`, бит 6) и разблокировкой ПЗУ 128 (`UNLOCK_128`, бит 7).
* **`#018B`:** Расширенный порт конфигурации страниц RAM PQ-DOS (биты 0..7).
* **`#028B`:** Аппаратный регистр флагов (PQ-DOS):
  * Bit 0: `HDD_OFF` — отключение HDD
  * Bit 1: `HDD_TYPE` — переключение режима HDD (0 = Profi IDE, 1 = Nemo IDE)
  * Bit 2: `TURBOFDC_OFF` — выключение Turbo FDC
  * Bit 3: `FDC_SWAP` — виртуальная смена дисководов A/B
  * Bit 4: `SOUND_OFF` — глобальное глушение звука
  * Bits 5..6: `TURBO_MODE` — управление частотой (00 = 3.5, 01 = 7, 10 = 14 МГц)
  * Bit 7: `LOCK_DFFD` — блокировка записи в порт `#DFFD`

### 2. Накопители и внешняя память
* **SD Card (Z-Controller / DivMMC):**
  * `#57`: Порт данных SD SPI (чтение/запись байта).
  * `#77`: Порт управления SD (CS, тактирование).
* **SPI Flash (прямой доступ):**
  * `#C7`: Управление / команды SPI Flash.
  * `#87`: Младший байт адреса страницы Flash.
  * `#A7`: Старший байт адреса страницы Flash.
  * `#67`: Адрес байта внутри страницы (0..255).
  * `#E7`: Байт данных внутри страницы.
* **Контроллер FDD (КР1818ВГ93 / MB8877A):**
  * `#1F`: Регистр команд / состояния ВГ93.
  * `#3F`: Регистр дорожки.
  * `#5F`: Регистр сектора.
  * `#7F`: Регистр данных.
  * `#FF` (системный регистр RQ93): Выбор дисковода (DS0, DS1), стороны (SIDE), сброс.
* **IDE HDD (Nemo IDE / Profi IDE):**
  * Порты регистров ATA/IDE Task File (чтение/запись секторов по 16 бит).

### 3. Звуковая подсистема
* **TurboSound (2 x AY/YM):**
  * `#FFFD`: Выбор номера регистра и выбор активного чипа AY (чип 0 / чип 1).
  * `#BFFD`: Чтение / запись данных выбранного регистра.
* **Covox:** Порт `#FB` (8-битный ЦАП).
* **Soundrive:** Порты `#0F, #1F, #3F, #4F, #5F` (4 раздельных канала).
* **Philips SAA1099:** Порт `#FF` (регистр / данные).

### 4. Ввод-вывод и сеть
* **Kempston Joystick:** Порт `#1F` (при активном `joy_mode`).
* **Kempston Mouse:**
  * `#FADF`: Кнопки мыши и координата колеса Z.
  * `#FBDF`: Координата X.
  * `#FFDF`: Координата Y.
* **Serial Mouse (COM RS232):**
  * `#B3`: Регистр команд / статуса RS232.
  * `#93`: Регистр данных RS232.
* **RTC DS1307:**
  * `#FF` (`#BF`): Порт строба адреса ячейки RTC/NVRAM (AS).
  * `#DF` (`#9F`): Порт данных ячейки RTC/NVRAM (DS).
* **ZX UNO UART / ESP8266:**
  * `#FC3B`: Регистр адреса периферии ZX-UNO.
  * `#FD3B`: Регистр данных ZX-UNO.
  * Внутренний регистр `#C6`: Приём/передача данных UART1 (ESP8266).
  * Внутренний регистр `#C7`: Статус UART1 (TX ready, RX ready).
  * Внутренние регистры `#C8, #C9`: Данные и статус для UART2 (uBus).

---

## 8. Программное обеспечение и операционные системы

В каталоге [software/profi](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/software/profi) и наборе ПЗУ представлены:
1. **ROMain (ROM Selector):**
   * Универсальный менеджер и загрузчик ПЗУ в верхний мегабайт SRAM (актуальная версия в репозитории — **v2.92**).
   * Поддержка различных конфигураций RAM-дисков (A, B, C, D) и файлового менеджера Fatall.
2. **Profi CP/M 2.2:**
   * Полноценная ОС CP/M с поддержкой видеорежима 80 символов в строке, драйверов винчестера (Nemo/Profi IDE) и флоппи-дисководов.
3. **PQ-DOS (BIOS v0.41h1):**
   * Перспективная ОС для Profi/Karabas-Pro с поддержкой жесткого диска, часов и расширенной адресации памяти.
4. **Встроенные утилиты от Doctor Max:**
   * **Flash Tool:** Интегрированная в ПЗУ утилита обновления bitstream FPGA и образов ROM прямо из Karabas-Pro без применения внешнего программатора USB-Blaster.
   * **FDImage Tool:** Встроенная утилита посекторной записи образов дискет (`TRD`, `SCL`, `PRO`, `TD0`, `FDI`) на реальные гибкие магнитные диски 3.5″ через чип MB8877A.
5. **Сетевые утилиты (Net-Tools):**
   * Комплект ПО для работы в интернет через модуль ESP8266 и ZiFi API:
     * `netman` — менеджер сканирования и подключения к Wi-Fi сетям.
     * `uGophy` — Gopher-клиент и менеджер загрузки файлов.
     * `weather` / `alerts` — погодный информер и служба уведомлений.
     * Работают напрямую с SD-картой с использованием стека FatFS без зависимости от ОС.

---

## 9. Сборочный конвейер и инструментарий (Toolchain & Build System)

Для сборки всех компонентов Karabas-Pro используются стандартные скрипты в каталоге [firmware/src](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src):

* **Общий скрипт:** [build.sh](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/build.sh) — запускает последовательную сборку AVR, ядер FPGA, CPLD и альтернативных ядер.
* **Сборка микроконтроллера:** [build_avr.sh](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/build_avr.sh)
  * Использует PlatformIO CLI (`pio run`).
  * Генерирует варианты `.hex` для всех комбинаций: Rev.A/Rev.D, с/без аппаратных кнопок, языки интерфейса OSD (EN, RU, UA), эмуляция USB/Echo.
* **Сборка CPLD:** [build_cpld.sh](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/build_cpld.sh)
  * Использует Intel Quartus Prime (`quartus_map`, `quartus_fit`, `quartus_asm`).
  * Выходной файл: `karabas_pro_cpld.pof`.
* **Сборка FPGA ядер:** [build_profi.sh](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/build_profi.sh) и [rom_update.sh](file:///home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro-master/firmware/src/rom_update.sh)
  * Таргеты: `EP4CE10`, `EP4CE6`, `EP3C10`.
  * Генерирует `.sof` (JTAG RAM), `.rbf` (сырой бинарник), и `.jic` (Flash Configuration Image для TDA1543 / TDA1543A для всех ревизий плат).

---

## 10. Структура репозитория (Directory Map)

```
karabas-pro/
├── docs/                      # Документация, схемы в PDF, интерактивные BOM (iBOM), фото плат
│   ├── PROJECT_MEMORY.md      # Данная база знаний проекта
│   ├── karabas-pro-revER.pdf  # Принципиальная электрическая схема последней ревизии
│   ├── karabas-pro-dev-manual-v1_01.pdf # Руководство разработчика ПО
│   ├── karabas-pro-user-manual-v1.odt   # Руководство пользователя
│   └── photos/                # Рендеры и фотографии плат
├── pcb/                       # САПР-проекты KiCad
│   ├── revEU/                 # Текущая версия (Rev.Ї - шелкография UA)
│   ├── revER/                 # Версия Rev.Ё (шелкография RU)
│   ├── revE/, revD/, revDS/   # Предыдущие аппаратные ревизии
│   ├── tapeMod_revA/          # Дочерний модуль магнитофона
│   └── gerbers/               # Готовые архивы Gerber-файлов для заказа плат
├── firmware/                  # Исходные коды и релизы прошивок
│   ├── src/
│   │   ├── avr/               # Исходники C++ для ATmega328P (PlatformIO)
│   │   ├── cpld/              # VHDL проект CPLD EPM3128ATC100
│   │   └── fpga/              # VHDL проекты FPGA (profi, pong, rk86, profi_plus3e)
│   └── releases/              # Скомпилированные бинарники (.jic, .sof, .pof, .hex)
├── software/                  # Софт для ZX Spectrum / Profi
│   └── profi/
│       ├── net-tools/         # Сетевые утилиты под ESP8266 (uGophy, netman, weather)
│       ├── fatfs/             # Драйвер файловой системы FAT32
│       ├── pq-dos/            # Образы дискет и драйверы PQ-DOS
│       ├── rtc/               # Драйвер RTC для CP/M
│       └── tools/             # Утилиты копирования и распаковки (karabas_boot, unFDI)
└── cases/                     # 3D-модели корпусов (STL, SCAD) под габариты 3.5" FDD
```
