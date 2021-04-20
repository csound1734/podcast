<CsoundSynthesizer>
<CsOptions>
-odac -d -m195
</CsOptions>
<CsInstruments> 
; These must all match the host as printed when Csound starts.
sr          =           48000
ksmps       =           128
nchnls      =           2
nchnls_i    =           1

zakinit 32, 32

;-----------XANADUFM OPCODE---------------------------------
/* xanadufm - the stereo version
   xanadufmm - the mono version
   Based on the work of Joseph Kung. 
   The essential algorithm is copied directly from code for
   "Xanadu". See for more info. */
;-----------------------------------------------------------
 opcode xanadufm, aa, aaaa                ;A-RATE STEREO
acps, amodi, amodr, aspr xin		;INPUTS
a1 = amodi*(amodr-1/amodr)/2
a2 = amodi*(amodr+1/amodr)/2
a1ndx = abs(a1*2/20)
a3 tablei a1ndx, 3, 1			;AM COMP. LOG
ao1 poscil a1, acps, 2			;AM COMP. LOG
ao2 poscil a2*acps, acps, 2		;MODULATOR WAVE
a4 = exp(-0.5*a3+ao1)			;AM COMPENSATOR
aL poscil a4, ao2+acps+aspr, 1		;FM RESULT L
aR poscil a4, ao2+acps-aspr, 1		;FM RESULT R
xout aL, aR				;OUTPUTS
 endop

 opcode xanadufm, aa, kPPO		;K-RATE STEREO
/* Defaults: modi=1, modr=1, spr=0 */
kcps, kmodi, kmodr, kspr xin		;INPUTS
k1 = kmodi*(kmodr-1/kmodr)/2
k2 = kmodi*(kmodr+1/kmodr)/2
k1ndx = abs(k1*2/20)
k3 tablei k1ndx, 3, 1			;AM COMP. LOG
ao1 poscil k1, kcps, 2			;AM COMP. LOG
ao2 poscil k2*kcps, kcps, 2		;MODULATOR WAVE
a4 = exp(-0.5*k3+ao1)			;AM COMPENSATOR
aL poscil a4, ao2+kcps+kspr, 1		;FM RESULT L
aR poscil a4, ao2+kcps-kspr, 1		;FM RESULT R
xout aL, aR				;OUTPUTS
 endop

 opcode xanadufm, aa, ippo		;I-RATE STEREO
/* Defaults: modi=1, modr=1, spr=0 */
icps, imodi, imodr, ispr xin		;INPUTS
i1 = imodi*(imodr-1/imodr)/2
i2 = imodi*(imodr+1/imodr)/2
i1ndx = abs(i1*2/20)
i3 tablei i1ndx, 3, 1			;AM COMP. LOG
ao1 poscil i1, icps, 2			;AM COMP. LOG
ao2 poscil i2*icps, icps, 2		;MODULATOR WAVE
a4 = exp(-0.5*i3+ao1)			;AM COMPENSATOR
aL poscil a4, ao2+icps+ispr, 1		;FM RESULT L
aR poscil a4, ao2+icps-ispr, 1		;FM RESULT R
xout aL, aR				;OUTPUTS
 endop

 opcode xanadufmm, a, aaa		;A-RATE MONO
acps, amodi, amodr xin			;INPUTS
ares, axx xanadufm acps, amodi, amodr, a(0)
xout ares				;OUTPUTS
 endop

 opcode xanadufmm, a, kPP			;K-RATE MONO
kcps, kmodi, kmodr xin			;INPUTS
ares, axx xanadufm kcps, kmodi, kmodr
xout ares				;OUTPUTS
 endop

 opcode xanadufmm, a, ipp			;I-RATE UNISON
icps, imodi, imodr xin			;INPUTS
ares, axx xanadufm icps, imodi, imodr
xout ares				;OUTPUTS
 endop
;-----------------------------------------------------------

 opcode GetCpsI, i, ii
itr, iN     xin ;input: transposition, scale degree
icps        table       iN, 129, 0, 0, 0
icps        *=          itr
            xout        icps
 endop


;-----------------------------------------------------------
 instr 3142
ienv        =           p4    ;select f-table
icps        GetCpsI     0.5, p5 ;select an octave, and a scale number
kndx        line        0, 1, p6 
amono       xanadufmm   icps
aL, aR      xanadufm    icps 
outs aL, aR
 endin


 instr Mixer
ainL zar 1
ainR zar 2
outs ainL, ainR
zacl 0, 2
 endin

</CsInstruments>
<CsScore>
;   The Function Tables
;   -------------------
;   Include in score or FMpad opcode will not work
;All functions are post-normalized (max value is 1) if p4 is
;POSITIVE.
f1 0 65537  10 1      ;sine wave
f2 0 65537  11 1      ;cosine wave
f3 0 65537 -12 20.0  ;unscaled ln(I(x)) from 0 to 20.0
;-----------------------------------------------------------

#define EDO(a'b') #[2^[[$a]/[$b]]]#
             ;numgrades interval basefreq basekey tuningRatio1 tuningRatio2
f129 0 -19 -51 19        2.0      220      0      \
1 \                 ;iN = 0
[$EDO(1'19')] \     
[$EDO(2'19')] \     ;iN = 2
[$EDO(3'19')] \
[$EDO(4'19')] \   ;iN = 4
[$EDO(5'19')] \
[$EDO(6'19')] \   ;iN = 6
[$EDO(7'19')] \
[$EDO(8'19')] \   ;iN = 8
[$EDO(9'19')] \
[$EDO(10'19')] \
[$EDO(11'19')] \
[$EDO(12'19')] \
[$EDO(13'19')] \
[$EDO(14'19')] \
[$EDO(15'19')] \
[$EDO(16'19')] \
[$EDO(17'19')] \
[$EDO(18'19')] 

i 3142 0 2

i "Mixer" 0 z

</CsScore>
</CsoundSynthesizer>    
