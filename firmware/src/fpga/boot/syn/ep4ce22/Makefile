##################################################################
# Karabas-Pro
##################################################################

PROJECT = karabas_pro_ep4ce22
TOP_LEVEL_ENTITY = karabas_pro
ASSIGNMENT_FILES = $(PROJECT).qpf $(PROJECT).qsf
OUTFILE = boot

all: smart.log $(PROJECT).asm.rpt $(PROJECT).sta.rpt

clean:
	rm -rf *.rpt *.chg smart.log *.htm *.eqn *.pin *.sof *.pof db incremental_db *.summary *.done *.smsg *.jdi *.jic *.map *.rbf greybox*

map: smart.log $(PROJECT).map.rpt
fit: smart.log $(PROJECT).fit.rpt
asm: smart.log $(PROJECT).asm.rpt
sta: smart.log $(PROJECT).sta.rpt
smart: smart.log

###################################################################
# Executable Configuration
###################################################################

MAP_ARGS = --read_settings_files=on
FIT_ARGS = --read_settings_files=on
ASM_ARGS =
STA_ARGS =

###################################################################
# Target implementations
###################################################################

STAMP = echo done >

$(PROJECT).map.rpt: map.chg $(SOURCE_FILES)
	quartus_map $(MAP_ARGS) $(PROJECT)
	$(STAMP) fit.chg

$(PROJECT).fit.rpt: fit.chg $(PROJECT).map.rpt
	quartus_fit $(FIT_ARGS) $(PROJECT)
	$(STAMP) asm.chg
	$(STAMP) sta.chg

$(PROJECT).asm.rpt: asm.chg $(PROJECT).fit.rpt
	quartus_asm $(ASM_ARGS) $(PROJECT)

$(PROJECT).sta.rpt: sta.chg $(PROJECT).fit.rpt
	quartus_sta $(STA_ARGS) $(PROJECT)

smart.log: $(ASSIGNMENT_FILES)
	quartus_sh --determine_smart_action $(PROJECT) > smart.log

###################################################################
# Project initialization
###################################################################

$(ASSIGNMENT_FILES):
	quartus_sh --prepare -t $(TOP_LEVEL_ENTITY) $(PROJECT)
map.chg:
	$(STAMP) map.chg
fit.chg:
	$(STAMP) fit.chg
sta.chg:
	$(STAMP) sta.chg
asm.chg:
	$(STAMP) asm.chg

###################################################################
# Programming the device
###################################################################

rbf: $(PROJECT).sof
	quartus_cpf -c $(PROJECT)_rbf.cof

program: $(PROJECT).sof
	quartus_pgm --no_banner --mode=jtag -o "P;$(PROJECT).sof"

release: $(PROJECT).rbf
	python3 make_core.py core.json $(OUTFILE).kp1

program-pof: $(PROJECT).pof
	quartus_pgm --no_banner --mode=jtag -o "BVP;$(PROJECT).pof"
