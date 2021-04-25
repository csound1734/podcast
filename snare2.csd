<CsoundSynthesizer>
<CsOptions>
</CsOptions>
; ==============================================
<CsInstruments>

sr	=	48000
ksmps	=	1
;nchnls	=	2
;0dbfs	=	1
 zakinit 4, 4

opcode tap_tubewarmth,a,akk

setksmps 1

ain, kdrive, kblend xin

;ain1 limit ain1, -1, 1

kdrive limit kdrive, 0.1, 10
kblend limit kblend, -10, 10

kprevdrive init 0
kprevblend init 0

krdrive init 0
krbdr init 0
kkpa init 0
kkpb init 0
kkna init 0
kknb init 0
kap init 0
kan init 0
kimr init 0
kkc init 0
ksrct init 0
ksq init 0
kpwrq init 0

#define TAP_EPS # 0.000000001 #
#define TAP_M(X) # $X = (($X > $TAP_EPS || $X < -$TAP_EPS) ? $X : 0) #
#define TAP_D(A) #
if ($A > $TAP_EPS) then
        $A = sqrt($A)
elseif ($A < $TAP_EPS) then
        $A = sqrt(-$A)
else
        $A = 0
endif
#

if (kprevdrive != kdrive || kprevblend != kblend) then

krdrive = 12.0 / kdrive;
krbdr = krdrive / (10.5 - kblend) * 780.0 / 33.0;

kkpa = 2.0 * (krdrive*krdrive) - 1.0
$TAP_D(kkpa)
kkpa = kkpa + 1.0;

kkpb = (2.0 - kkpa) / 2.0;
kap = ((krdrive*krdrive) - kkpa + 1.0) / 2.0;

kkc = 2.0 * (krdrive*krdrive) - 1.0
$TAP_D(kkc)
kkc = 2.0 * kkc - 2.0 * krdrive * krdrive
$TAP_D(kkc)

kkc = kkpa / kkc

ksrct = (0.1 * sr) / (0.1 * sr + 1.0);
ksq = kkc*kkc + 1.0

kknb = ksq
$TAP_D(kknb)
kknb = -1.0 * krbdr / kknb

kkna = ksq
$TAP_D(kkna)
kkna = 2.0 * kkc * krbdr / kkna

kan = krbdr*krbdr / ksq

kimr = 2.0 * kkna + 4.0 * kan - 1.0
$TAP_D(kimr)
kimr = 2.0 * kknb + kimr


kpwrq = 2.0 / (kimr + 1.0)

kprevdrive = kdrive
kprevblend = kblend

endif

aprevmed init 0
amed init 0
aprevout init 0

kin downsamp ain

if (kin >= 0.0) then
        kmed = kap + kin * (kkpa - kin)
        $TAP_D(kmed)
        amed = (kmed + kkpb) * kpwrq
else
        kmed = kap - kin * (kkpa + kin)
        $TAP_D(kmed)
        amed = (kmed + kkpb) * kpwrq * -1
endif

aout = ksrct * (amed - aprevmed + aprevout)

kout downsamp aout
kmed downsamp amed


if (kout < -1.0) then
        aout = -1.0
        kout = -1.0
endif

$TAP_M(kout)
$TAP_M(kmed)

aprevmed = kmed
aprevout = kout

#undef TAP_D
#undef TAP_M
#undef TAP_EPS

xout aout

        endop

 instr Matrix
ilook    = .05 ;compressor attack
ainL zar 0
ainR zar 1
zacl 0,1
asum = ainL+ainR
asum /= 2
asum tap_tubewarmth asum, k(3.5), k(0)
asum *= db(-2)
acom compress2 asum, asum, -92, -37.2, -20, db(3), ilook, .12, ilook
out acom
 endin


instr 2
  icps0  = 147
  iamp   = p4*0.7

  icps1  =  2.0 * icps0
  
  kcps   port icps0, 0.007, icps1
  kcpsx  =  kcps * 1.5
  
  kfmd   port   0.0, 0.01, 0.7
  aenv1  expon  1.0, 0.03, 0.5
  kenv2  port 1.0, 0.008, 0.0
  aenv2  interp kenv2
  aenv3  expon  1.0, 0.025, 0.5
  
  a_     oscili 1.0, kcps, 1
  a1     oscili 1.0, kcps * (1.0 + a_*kfmd), 1
  a_     oscili 1.0, kcpsx, 1
  a2     oscili 1.0, kcpsx * (1.0 + a_*kfmd), 1
  
  a3     unirand 2.0
  a3     =  a3 - 1.0
  a3     butterbp a3, 5000, 7500
  a3     =  a3 * aenv2
  
  a0     =  a1 + a2*aenv3 + a3*1.0
  a0     =  a0 * aenv1

  zawm a0*iamp, 0
 zawm a0*iamp, 1
endin

instr 1	
p3 = 1
astrike trirand expon:k(1,0.01,0.37)
adl   line   1/kr, 1, 0.75
a1    delayr 3.0
a2    deltapx adl, 4
      delayw astrike
a2    diff a2
astrike = a2
asticks bamboo 0.05, p3/2, 32, -.05, 0
astrike += asticks*0.5
amod1 mode astrike, 179, 120
amod2 mode astrike*db(-2), 337, 120
amod3 mode astrike*db(-4), 400, 120
amod4 mode astrike*db(-6), 405, 120
amod5 mode astrike*db(-12), 868, 120
amod6 mode astrike*db(-18), 1011,120
astrike dam astrike, .0285, db(-52), 1, .03, .06
ares = amod1+amod2+amod3+amod4+amod5+amod6+astrike*4+asticks
;ares dam ares, .285, db(-12), 1, .02, .002
;ares = a2
 zawm ares*ampdbfs(-18), 0
 zawm ares*ampdbfs(-18), 1
endin

 instr 3
astrike trirand expon:k(1,0.01,0.37)
adl   line   1/kr, 1, 0.180
a1    delayr 3.0
a2    deltapx adl, 4
      delayw astrike
a2    diff a2
astrike = a2
 zawm astrike*ampdbfs(-17), 0
 zawm astrike*ampdbfs(-17), 1
 endin

instr 4	
p3 = 1
astrike oscil 0.02, expon:k(1,0.01,0.38)*1100
astrenv linseg 0, 0.001, 1, 0.018, 1, 0.01, 0, 10000, 0
astrike *= astrenv
astrike *= 1/0.02
astrike chebyshevpoly astrike, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1
astrike *= 0.04
adl   expon   1/kr, 1, 0.5
a1    delayr 3.0
a2    deltapx adl, 4
      delayw astrike
astrike = a2
amode2 mode a2, cpspch(7.02), 5
amode1 mode a2, cpspch(6.04), 5
;a2 += amode2*.25
asum = a2*ampdbfs(-14)+amode1*ampdbfs(-13)+amode2*ampdbfs(-15)
asum K35_lpf asum, 350, 2.0, 1
zawm asum, 0
zawm asum, 1
 endin
</CsInstruments>
; ==============================================
<CsScore>
f 1 0 16384 10 1
t 0 90
{64 x
i 3 [$x*.5] 0.15
}
{16 s
i 2 [$s*2+1] 2 16000
i 1 [$s*2+1] 2 
}
{4 k
i 4 [$k*8+0.00] 2
i 4 [$k*8+1.25] 2
i 4 [$k*8+1.75] 2
i 4 [$k*8+4.00] 2
i 4 [$k*8+4.50] 2
i 4 [$k*8+5.75] 2
}

i "Matrix" 0 z



</CsScore>
</CsoundSynthesizer>

