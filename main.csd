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

;-----------BABOON REVERB-----------------------------------
/*
Baboon - UDO wrapper for the babo opcode

DESCRIPTION
Baboon is a full expert mode wrapper for the babo opcode, a physical model reverberator based on the work of David Rochesso.

SYNTAX
aL,aR Baboon ixsize,idiff,idecay,ihidecay, ain

INITIALIZATION
none

PERFORMANCE
aL,aR = babo left and right audio outputs
See the Csound manual for the babo opcode for details of each i-rate variable.

CREDITS
by Brian Wong, 2010
*/

opcode Baboon,aa,iiiia
ixsize,idiff,idecay,ihidecay,ain xin
iysize     =      ixsize*(2^0.1)
izsize     =      ixsize*(3^0.1)
ksource_x jitter ixsize*0.5, 1, 2
ksource_y jitter ixsize*0.5, 1, 2
ksource_z jitter ixsize*0.5, 1, 2
iexpert ftgen 0, 0, 8, -2, idecay, ihidecay, ixsize*(13/14),iysize*(13/14),izsize*(13/14), 0.3, 0, db(-10)
aL,aR     babo    ain, ksource_x,ksource_y,ksource_z, ixsize, iysize, izsize, idiff, iexpert
xout    aL,aR
 endop


;-----------SHIMMER REVERB----------------------------------
/* Source: https://github.com/kunstmusik/libsyi/blob/master/shimmer_reverb.udo */
/* shimmer_reverb - stereo effect with reverb and spectrally processed pitch-shifted feedback
	Inputs:
		al - left input audio signal
		ar - right input audio signal 
		kpredelay - delay time in milliseconds for pre-delay of input signal before entering reverb 
		krvbfblvl - feedback setting for reverbsc (a large setting like 0.95 can be nice)
		krvbco - cutoff setting for reverbsc (affects brightness of effect)
		kfblvl - feedback amount for delayed signal that is fed back into reverb (0.45 is a good value to start with)
		kfbdeltime - delay time in milliseconds for delayed signal that is fed back into reverb (start with 100)
		kratio - amount to transpose feedback signal by. 2 transposes by octaves, 1.5 is up by fifths, etc.
			
*/
opcode shimmer_reverb, aa, aakkkkkk
	al, ar, kpredelay, krvbfblvl, krvbco, kfblvl, kfbdeltime, kratio  xin

  ; pre-delay
  al = vdelay3(al, kpredelay, 1000)
  ar = vdelay3(ar, kpredelay, 1000)
 
  afbl init 0
  afbr init 0

  al = al + (afbl * kfblvl)
  ar = ar + (afbr * kfblvl)

  ; important, or signal bias grows rapidly
  al = dcblock2(al)
  ar = dcblock2(ar)

	; tanh for limiting
  ;al = tanh(al)
  ;ar = tanh(ar)

  al, ar reverbsc al, ar, krvbfblvl, krvbco 

  ifftsize  = 2048 
  ioverlap  = ifftsize / 4 
  iwinsize  = ifftsize 
  iwinshape = 1; von-Hann window 

  fftin     pvsanal al, ifftsize, ioverlap, iwinsize, iwinshape 
  fftscale  pvscale fftin, kratio, 0, 1
  atransL   pvsynth fftscale

  fftin2    pvsanal ar, ifftsize, ioverlap, iwinsize, iwinshape 
  fftscale2 pvscale fftin2, kratio, 0, 1
  atransR   pvsynth fftscale2

  ;; delay the feedback to let it build up over time
  afbl = vdelay3(atransL, kfbdeltime, 4000)
  afbr = vdelay3(atransR, kfbdeltime, 4000)

  xout al, ar
endop

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

 opcode GetCpsI, i, i
iN     xin ;input: transposition, scale degree
iscaleft    =           128+int(iN)
iN          =           100*(iN%1)
icps        table       iN%ftlen(iscaleft), iscaleft, 0, 0, 0
            xout        icps
 endop

#define CONTROLS #
ienv        =           p4    ;select f-table
icps        GetCpsI     p5 ;select an scale, and a scale number
kndx        line        0, 1, p6 
iFM         =           p7 ;FM Index (amount of modulation)
iZa         =           p8 ;which za-index to send output
kenv_       table       kndx, ienv, 0, 0, 0 
kenv        =           ampdbfs(kenv_)-ampdbfs(-96) 
kenv2       linseg      1, p3, -1
kFM         =           iFM ;FM Index for xanadufm
ksone       tablei      k(icps)/32000, 2222, 1
#

;-----------------------------------------------------------
 instr 3142
$CONTROLS
aL          xanadufmm   k(icps), kFM, 1.5^kenv2
aR          xanadufmm   k(icps), kFM, 1.5^(-kenv2)
            zawm        aL*kenv*db(-ksone), iZa
            zawm        aR*kenv*db(-ksone), iZa+1
 endin

 instr 3146 
icps GetCpsI p5
ares marimba p4, icps, .5, .33, 4, 0, 0, -1, 0.1, 0, 0
outs ares, ares
 endin

 instr Matrix
ainL zar 1
ainR zar 2
aL, aR  reverbsc ainR, ainL, 0.92, 14000, sr, 0.75, .1
aL      nreverb  aL, 4, .25, 0, 2, 7777, 2, 7776
aR      nreverb  aR, 4, .25, 0, 2, 7775, 2, 7774
zawm (aL+ainL)*db(-18), 17
zawm (aR+ainR)*db(-18), 18

ainL zar 3
ainR zar 4
aL, aR shimmer_reverb ainL, ainR, 120, .95, 12000, .45, 100, 2^(11/19)
zawm aL, 19
zawm aR, 20
zacl 0, 4
 endin

 instr 8000 ;output a pair of za-signals
iZaL = p4
iZaR = p4+1
aL zar iZaL
aR zar iZaR
outs aL, aR
zacl iZaL, iZaR
 endin

</CsInstruments>

<CsScore>




i "Matrix" 0 z

i 8000 0 z 17
i 8000 0 z 19

;   The Function Tables
;   -------------------
;   Include in score or FMpad opcode will not work
;All functions are post-normalized (max value is 1) if p4 is
;POSITIVE.
f1 0 65537  10 1      ;sine wave
f2 0 65537  11 1      ;cosine wave
f3 0 65537 -12 20.0  ;unscaled ln(I(x)) from 0 to 20.0
f4 0 65537 -5  1 65537 0.1 ;strike impulse response for marimba
;-----------------------------------------------------------

/* SONE FUNCTION */
f 2222 0 16385 "sone" 0 32000 32000 0

;-----------------NREVERB FILTER TABLES---------------------
f 7777 0 4 -2 [8/13] [233/500] [.5] [.95] 
f 7776 0 4 -2 [1/21] [144/500] [.5] [.95] 
f 7775 0 4 -2 [5/8] [13/987] [.5] [.5] 
f 7774 0 4 -2 [1/5] [13/89] [.5] [.5] 

;------------------ENVELOPE FTABLES-------------------------
f 3000 0 2048 -7 -96 1024 -12 1024 -96
f 3001 0 2048 -7 -96 512 -10 512 -12 512 -17 256 -17 256 -96
f 3002 0 2048 -7 -96 128 -10 128 -12 256 -14 512 -13 1024 -96
f 3003 0 2048 -7 -96 126 -32 126 -48 256 -39 512 -36 512 -31 256 -37 256 -96
f 3004 0 2048 -7 -96 256 -24 256 -26 512 -26 512 -30 512 -96 

#define EDO(a'b') #[2^[[$a]/[$b]]]#
             ;numgrades interval basefreq basekey tuningRatio1 tuningRatio2
f129 0 -64 -51 8        4.0      55      0      \
1 \                 ;A
[$EDO(3'19')] \     ;A+1(chrom semi)
[$EDO(6'19')] \     ;A+6(major third)
[$EDO(11'19')] \    ;A+11(p fifth)
[$EDO(17'19')] \   ;A+17(maj seventh)
[$EDO(22'19')] \    ;A2+3(whole tone)
[$EDO(27'19')] \   ;A2+8(p fourth)
[$EDO(33'19')]      ;A2+14(maj sixth)

             ;numgrades interval basefreq basekey tuningRatio1 tuningRatio2
f130 0 -64 -51 8        4.0     110  4     \   ;starts on A+4

1                   ;A+4(septimal whole)
[$EDO(4'19')] \     ;A+8(p fourth)
[$EDO(7'19')] \     ;A+11(p fifth)
[$EDO(11'19')] \    ;A+14(p sixth)
[$EDO(15'19')] \   ;A
[$EDO(21'19')] \    ;A+6
[$EDO(30'19')] \   ;A+14
[$EDO(33'19')]      ;A+18

#define SWIRL(t') #
i 3142 [$t] [8] 3004 [1.08] [[1024]] [2] 3
#

#define SWELL(t'd'a'b'i') #
i 3142 [$t] [8] 3000 [$a] [[256*$d]] [$i] 1
i 3142 [$t] [8] 3000 [$b] [[256*$d]] [$i] 1
#

$SWIRL(0'8)

b 10 
$SWELL(0'1'1.08'1.09'8')
$SWELL(5'1'2.09'2.10'8.5')

$SWELL(13'1.5'1.10'1.11'8.5')
$SWELL(16'1'1.13'1.14'8')








</CsScore>
</CsoundSynthesizer>    

