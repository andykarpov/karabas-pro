
"../tools/iar/bin/iccz80" -v0 -ml -uua -b -q -x -K -gA -z9 -t4 -T -Llist/ -Alist/ -I"../tools/iar/inc/" ff.c
"../tools/iar/bin/az80" savelij.asm
"../tools/iar/bin/az80" Cstartup.asm
"../tools/iar/bin/xlink" -f Lnkz80.xcl Cstartup ff savelij -Fraw-binary -l list/map.html -o out.bin -xehinms -n 
del *.r01