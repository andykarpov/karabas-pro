# Wiring picture of the USB -> PS/2 bridge (Fritzing-like). Run: python3 wiring.py wiring.svg && rsvg-convert -b "#fbfaf6" wiring.svg -o wiring.png
import sys
W,H=1380,1050
o=[]
def a(s): o.append(s)
def esc(t): return t.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
def text(x,y,t,size=13,fill='#222',anchor='start',weight='normal',rot=None,family='DejaVu Sans, Arial, sans-serif'):
    tr=f' transform="rotate({rot} {x} {y})"' if rot is not None else ''
    a(f'<text x="{x}" y="{y}" font-family="{family}" font-size="{size}" fill="{fill}" text-anchor="{anchor}" font-weight="{weight}"{tr}>{esc(t)}</text>')
def rect(x,y,w,h,fill,stroke='none',rx=0,sw=1): a(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>')
def circ(x,y,r,fill,stroke='none',sw=1): a(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>')
WIRES=[]
def wire(pts,color,out='#2b2b2b'):
    WIRES.append((pts,color,out))
def draw_wires():
    for pts,color,out in WIRES:
        d='M'+' L'.join(f'{x},{y}' for x,y in pts)
        a(f'<path d="{d}" fill="none" stroke="{out}" stroke-width="7" stroke-linejoin="round" stroke-linecap="round"/>')
        a(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="4.2" stroke-linejoin="round" stroke-linecap="round"/>')
        for x,y in (pts[0],pts[-1]): circ(x,y,3.2,color,out,1.2)
def junction(x,y,color): circ(x,y,5,color,'#2b2b2b',1.5)
def pad(x,y): circ(x,y,6,'#d4a537','#8a6a1c',1.2); circ(x,y,2.6,'#5a4512')

C=dict(v5='#e53935',gnd='#263238',v33='#fb8c00',vsys='#d81b60',dp='#43a047',dm='#f5f5f5',
       tx='#fdd835',rx='#26c6da',kc='#1e88e5',kd='#7e57c2',mc='#8bc34a',md='#a1887f')

a(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
rect(0,0,W,H,'#fbfaf6')
text(24,36,'Переходник USB → PS/2 + UART для Karabas-Pro: монтаж',20,weight='bold')
text(24,58,'Схема: pcb/usb-ps2-bridge/usb-ps2-bridge.kicad_sch · прошивка: tools/usb-ps2-bridge',12,fill='#555')

# ---------------- Pico (USB on the left, pins 1..20 bottom row, 40..21 top row)
px0,py0,pw,ph=470,150,504,206
def pb(k): return (488+24*(k-1), py0+ph-12)   # bottom pins 1..20
def pt(m): return (488+24*(40-m), py0+12)      # top pins 21..40
rect(px0,py0,pw,ph,'#1b7f3b','#0f4f24',8,2)
rect(px0-14,py0+ph/2-20,26,40,'#b0b6bb','#6d7378',3,1.5)   # micro-USB
rect(px0+150,py0+70,62,62,'#1d1d1d','#000',3)               # RP2040
text(px0+181,py0+106,'RP2040',10,'#ddd','middle')
rect(px0+240,py0+80,34,26,'#cfcfcf','#888',2)             # flash
circ(px0+70,py0+96,11,'#f2f2f2','#999',1.5); text(px0+70,py0+124,'BOOTSEL',9,'#e8f5e9','middle')
text(px0+380,py0+98,'Raspberry Pi Pico',16,'#ffffff','middle','bold')
text(px0+380,py0+118,'U1',12,'#e8f5e9','middle')
names_b={1:'GP0',2:'GP1',3:'GND',4:'GP2',5:'GP3',6:'GP4',7:'GP5',8:'GND',9:'GP6',10:'GP7',11:'GP8',12:'GP9',13:'GND',14:'GP10',15:'GP11',16:'GP12',17:'GP13',18:'GND',19:'GP14',20:'GP15'}
names_t={40:'VBUS',39:'VSYS',38:'GND',37:'3V3_EN',36:'3V3',35:'VREF',34:'GP28',33:'AGND',32:'GP27',31:'GP26',30:'RUN',29:'GP22',28:'GND',27:'GP21',26:'GP20',25:'GP19',24:'GP18',23:'GND',22:'GP17',21:'GP16'}
used={1,2,3,4,5,6,7,10,9,18,39,38,36}
for k,n in names_b.items():
    x,y=pb(k); pad(x,y)
    text(x+4,y-12,n,9,'#ffffff' if k in used else '#a5d6a7',rot=-90,weight='bold' if k in used else 'normal')
    text(x,y+22,str(k),9,'#555','middle')
for m,n in names_t.items():
    x,y=pt(m); pad(x,y)
    text(x+4,y+12,n,9,'#ffffff' if m in used else '#a5d6a7','end',rot=-90,weight='bold' if m in used else 'normal')
    text(x,y-14,str(m),9,'#555','middle')
# USB cable to the PC
a(f'<path d="M{px0-14},{py0+ph/2} L{px0-90},{py0+ph/2}" fill="none" stroke="#4a4a4a" stroke-width="9" stroke-linecap="round"/>')
rect(px0-118,py0+ph/2-9,30,18,'#9e9e9e','#555',2)
text(px0-124,py0+ph/2-4,'к компьютеру:',12,'#333','end')
text(px0-124,py0+ph/2+12,'USB serial + питание',12,'#333','end')

# ---------------- level shifter module (8 ch, BSS138)
mx0,my0,mw,mh=742,482,256,156
def ml(i): return (760+24*i, my0+18)    # i=0..9: L1..L8, GND, LV
def mh_(i): return (760+24*i, my0+mh-18)
rect(mx0,my0,mw,mh,'#1f3f99','#132a66',6,2)
for i in range(8):
    rect(754+24*i+1,my0+62,14,10,'#111'); rect(754+24*i+3,my0+84,10,5,'#e0c9a6')
lv=['L1','L2','L3','L4','L5','L6','L7','L8','GND','LV']; hv=['H1','H2','H3','H4','H5','H6','H7','H8','GND','HV']
for i in range(10):
    x,y=ml(i); pad(x,y); text(x,y+20,lv[i],9,'#fff','middle')
    x,y=mh_(i); pad(x,y); text(x,y-12,hv[i],9,'#fff','middle')
text(mx0+mw/2,my0+mh/2+30,'преобразователь уровней BSS138',10,'#e3e8ff','middle')
text(mx0+mw+8,my0+22,'3,3 В (LV)',11,'#333'); text(mx0+mw+8,my0+mh-14,'5 В (HV)',11,'#333')

# ---------------- USB-A receptacle (pins on its right side)
ux0,uy0=150,372
rect(ux0,uy0,110,100,'#c7ccd1','#7a8086',4,2)
rect(ux0+12,uy0+30,70,40,'#2a2a2a',rx=2); rect(ux0+18,uy0+44,58,12,'#1565c0',rx=1)
text(ux0+55,uy0+92,'USB-A',11,'#333','middle')
upins=[('GND',392),('D+',412),('D−',432),('VBUS',452)]
for n,y in upins:
    a(f'<line x1="{ux0+110}" y1="{y}" x2="{ux0+124}" y2="{y}" stroke="#8a6a1c" stroke-width="3"/>')
    text(ux0+104,y+4,n,9,'#222','end')
text(ux0-6,uy0-34,'J1: гнездо USB-A',12,'#222',weight='bold')
text(ux0-6,uy0-18,'приёмник клавиатуры и мыши',11,'#444')

# ---------------- D1
dx,dy=330,120
a(f'<line x1="{dx-10}" y1="{dy}" x2="{dx+78}" y2="{dy}" stroke="#9e9e9e" stroke-width="2.5"/>')
rect(dx+12,dy-9,44,18,'#222',rx=3); rect(dx+46,dy-9,7,18,'#cfd8dc')
text(dx+34,dy-16,'D1 1N5819 (SS14)',11,'#222','middle',weight='bold')
text(dx+34,dy+28,'анод ← 5 В   катод → VSYS',10,'#555','middle')

# ---------------- bottom connectors
def housing(x0,y0,pins,title,sub,cable,plug=None,cap=''):
    n=len(pins); w=24*n+12
    rect(x0,y0,w,26,'#2b2b2b',rx=3)
    for i,(lab,_) in enumerate(pins):
        x=x0+18+24*i; rect(x-5,y0-6,10,10,'#d4a537','#8a6a1c'); text(x,y0+19,lab.split()[0],11,'#fff','middle','bold')
    a(f'<path d="M{x0+w/2},{y0+26} L{x0+w/2},{y0+110}" stroke="{cable}" stroke-width="10" stroke-linecap="round"/>')
    if plug:
        circ(x0+w/2,y0+130,22,plug,'#333',2)
        for dx_,dy_ in [(-9,-7),(9,-7),(-12,4),(12,4),(-7,13),(7,13)]: circ(x0+w/2+dx_,y0+130+dy_,2.4,'#e0e0e0')
        rect(x0+w/2-4,y0+110,8,6,'#333')
    text(x0+w+6,y0+18,cap,10,'#444')
    text(x0+w/2,y0+(170 if plug else 128),title,12,'#222','middle','bold')
    text(x0+w/2,y0+(186 if plug else 144),sub,11,'#444','middle')
    return [x0+18+24*i for i in range(n)]
J6=housing(572,800,[('1',0),('2',0),('3',0),('4',0)],'→ J6 «AVR UART»','разъём на плате (rev.E)','#555')
KB=housing(742,800,[('5',0),('1',0),('3',0)],'→ CON5','PS/2 клавиатура','#6a1b9a','#8e24aa')
MS=housing(838,800,[('5',0),('1',0),('3',0)],'→ CON6','PS/2 мышь','#2e7d32','#43a047')
# housing pin x: J6 560,584,608,632 ; KB 760,784,808 ; MS 856,880,904

# ---------------- wires
Y=lambda p:p
b=pb; t=pt
# Pico -> LV side
wire([b(1),(488,470),(760,470),ml(0)],C['tx'])
wire([b(2),(512,458),(784,458),ml(1)],C['rx'])
wire([b(6),(608,446),(808,446),ml(2)],C['kc'])
wire([b(7),(632,434),(832,434),ml(3)],C['kd'])
wire([b(9),(680,422),(856,422),ml(4)],C['mc'])
wire([b(10),(704,410),(880,410),ml(5)],C['md'])
wire([b(18),(896,390),(952,390),ml(8)],C['gnd'])
wire([t(36),(584,96),(1040,96),(1040,476),(976,476),ml(9)],C['v33'])
# USB
wire([b(3),(536,392),(ux0+124,392)],C['gnd'])
wire([b(4),(560,412),(ux0+124,412)],C['dp'])
wire([b(5),(584,432),(ux0+124,432)],C['dm'],'#555')
# VSYS: D1 cathode -> Pico 39 ; -> USB VBUS
wire([(dx+78,dy),(512,dy),t(39)],C['vsys'])
wire([(450,dy),(450,80),(110,80),(110,500),(300,500),(300,452),(ux0+124,452)],C['vsys'])
junction(450,dy,C['vsys'])
# HV side -> connectors
wire([mh_(0),(760,652),(662,652),(662,800)],C['tx'])
wire([mh_(1),(784,666),(638,666),(638,800)],C['rx'])
wire([mh_(2),(808,690),(760,690),(760,800)],C['kc'])
wire([mh_(3),(832,704),(784,704),(784,800)],C['kd'])
wire([mh_(4),(856,800)],C['mc'])
wire([mh_(5),(880,800)],C['md'])
# GND (HV) -> J6.2, KB.3, MS.3
wire([mh_(8),(952,1005),(550,1005),(550,770),(614,770),(614,800)],C['gnd'])
wire([(952,742),(808,742),(808,800)],C['gnd'])
wire([(904,742),(904,800)],C['gnd'])
# +5V (HV) -> J6.1, D1 anode
wire([mh_(9),(976,1022),(530,1022),(530,756),(590,756),(590,800)],C['v5'])
wire([(530,1022),(130,1022),(130,dy),(dx-10,dy)],C['v5'])
# resistors on D+/D-
draw_wires()
junction(952,742,C['gnd']); junction(904,742,C['gnd']); junction(530,1022,C['v5'])
for y,lab in [(412,'R1 27'),(432,'R2 27')]:
    rect(352,y-5,36,10,'#e8d3a8','#8d6e63',4,1)
    for i,c in enumerate(['#d32f2f','#6a1b9a','#111']): rect(358+8*i,y-5,3,10,c)
    text(392,y-6,lab,9,'#333')

# legend
lx,ly=1080,160
text(lx,ly,'Цвета проводов',13,'#222',weight='bold')
leg=[('v5','+5 В платы (J6.1)'),('vsys','VSYS (после D1)'),('v33','3,3 В Pico'),('gnd','GND (общий)'),('dp','USB D+ (GP2)'),('dm','USB D− (GP3)'),
     ('tx','GP0 TX → AVR_RX'),('rx','GP1 RX ← AVR_TX'),('kc','клавиатура CLK (GP4)'),('kd','клавиатура DATA (GP5)'),('mc','мышь CLK (GP6)'),('md','мышь DATA (GP7)')]
for i,(k,t_) in enumerate(leg):
    y=ly+22+i*19
    a(f'<line x1="{lx}" y1="{y-4}" x2="{lx+30}" y2="{y-4}" stroke="#2b2b2b" stroke-width="7" stroke-linecap="round"/>')
    a(f'<line x1="{lx}" y1="{y-4}" x2="{lx+30}" y2="{y-4}" stroke="{C[k]}" stroke-width="4.2" stroke-linecap="round"/>')
    text(lx+40,y,t_,11,'#333')
notes=['Модули BSS138 бывают с другими подписями',
       'и порядком выводов: ищите LV / HV, GND',
       'и номера каналов. Подтяжки PS/2 4k7 к 5 В',
       'уже стоят на плате (R21–R24).']
for i,n in enumerate(notes): text(lx,ly+270+i*16,n,11,'#555')
caps=[('J6 платы:','1 +5 В, 2 GND, 3 AVR_TX, 4 AVR_RX'),('CON5 / CON6:','5 CLK, 1 DATA, 3 GND')]
for i,(h_,t_) in enumerate(caps): text(lx,ly+350+i*34,h_,11,'#222',weight='bold'); text(lx,ly+366+i*34,t_,11,'#444')
a('</svg>')
open(sys.argv[1],'w').write('\n'.join(o))
