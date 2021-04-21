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
aL,aR Baboon idur,ixstart,iystart,izstart,ixend,iyend,izend,ixsize,iysize,izsize,idiff,idecay,ihidecay,irx,iry,irz,irdist,idirect,iearly,ain

INITIALIZATION
none

PERFORMANCE
aL,aR = babo left and right audio outputs
See the Csound manual for the babo opcode for details of each i-rate variable.

CREDITS
by Brian Wong, 2010
*/

opcode Baboon,aa,iiiiiiiiiiiiiiiiiiia
idur,ixstart,iystart,izstart,ixend,iyend,izend,ixsize,iysize,izsize,idiff,idecay,ihidecay,irx,iry,irz,irdist,idirect,iearly,ain xin
ksource_x line    ixstart, idur, ixend
ksource_y line    iystart, idur, iyend
ksource_z line    izstart, idur, izend
iexpert ftgen 0, 0, 8, -2, idecay, ihidecay, irx, iry, irz, irdist, idirect, iearly
aL,aR     babo    ain, ksource_x, ksource_y, ksource_z, ixsize, iysize, izsize, idiff, iexpert
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
icps        table       iN%ftlen(129), 129, 0, 0, 0
            xout        icps
 endop


;-----------------------------------------------------------
 instr 3142
ienv        =           p4    ;select f-table
icps        GetCpsI     p5 ;select an octave, and a scale number
kndx        line        0, 1, p6 
kenv_       tablei      kndx, ienv, 0, 0, 1
kenv        =           ampdbfs(kenv_)-ampdbfs(-96)
aL, aR      xanadufm    icps, 4, .67, 2
            zawm        aL*kenv, 1
            zawm        aR*kenv, 2
 endin


 instr Mixer
ainL zar 1
ainR zar 2
ainL, ainR Baboon 1, 2, 3, 5, 2, 3, 5, 13, 17, 19, 0.5, 0.99, 0.3, 0, 0, 0, 0.3, .5, .5
outs ainL*db(-6), ainR*db(-6)
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

;------------------ENVELOPE FTABLES-------------------------
f 3000 0 2048 -7 -96 1024 -12 1024 -96

#define EDO(a'b') #[2^[[$a]/[$b]]]#
             ;numgrades interval basefreq basekey tuningRatio1 tuningRatio2
f129 0 -256 -51 19        2.0      220      38      \
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

i 3142 0 2 3000 19 1024

i "Mixer" 0 z

</CsScore>
</CsoundSynthesizer>    
