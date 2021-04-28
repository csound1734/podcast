<CsoundSynthesizer>
<CsOptions>
-odac -m195
</CsOptions>
<CsInstruments> 
; These must all match the host as printed when Csound starts.
sr          =           48000
ksmps       =           128
nchnls      =           2
nchnls_i    =           1

zakinit 64, 64

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
icps        tab_i       iN, iscaleft, 0
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
isone       tablei      icps/16384, 2222, 1, 0, 1
ksone       init        isone
#

;-----------------------------------------------------------
 instr 3142
$CONTROLS
aL,aR       xanadufm   k(icps), iFM, 1.5^kenv2, 0
            zawm        (aL+aR)*.5*kenv*db(1-isone), iZa
            zawm        (aL+aR)*.5*kenv*db(1-isone), iZa+1
 endin


 instr 3146
$CONTROLS
icps2          GetCpsI    p5+.01
icps3          GetCpsI    p5+.02
icps4          GetCpsI    p5+.03
a1,a2          xanadufm   k(icps), iFM, 1.35^kenv2 , 	0
a3,a4          xanadufm   k(icps2), iFM, 1.35^(-kenv2), 	0
a5,a6          xanadufm   k(icps3), iFM, .5^kenv2, 	0
a7,a8          xanadufm   k(icps4), iFM, .5^(-kenv2), 	0
            zawm        (1/8)*a1*kenv*(1-isone), iZa
            zawm        (1/8)*a2*kenv*(1-isone), iZa+1
            zawm        (1/8)*a3*kenv*(1-isone), iZa+2
            zawm        (1/8)*a4*kenv*(1-isone), iZa+3
            zawm        (1/8)*a5*kenv*(1-isone), iZa+4
            zawm        (1/8)*a6*kenv*(1-isone), iZa+5
            zawm        (1/8)*a7*kenv*(1-isone), iZa+6
            zawm        (1/8)*a8*kenv*(1-isone), iZa+7
 endin

 instr 3150
$CONTROLS
print icps
ares         xanadufmm  icps, 1, 1
             zawm       ares*kenv*(1-isone), iZa
 endin

#define STEREOHISH(f'l') #
aL rbjeq aL, 6600+0*$f, 1/$l, 0, .08, 10 
aL *= $l/3
aR rbjeq aR, 6600+0*$f, 1/$l, 0, .08, 10
aR *= $l/3
#

#define STEREOCOMP #
kpeakL rms aL
kpeakR rms aR
;printk .1, (kpeakL/0dbfs), 10
;printk .1, (kpeakR/0dbfs)
aL dam aL, 0dbfs*.004, db(-7.6), 1, 0.008, 0.12
aR dam aL, 0dbfs*.004, db(-7.6), 1, 0.008, 0.12
aL *= db(6)
aR *= db(6)
#

 instr ZIW
ival = p4
indx = p5
ziw ival, indx
 endin

 instr Matrix
	ziw 0.92, 1
ainL zar 1
ainR zar 2
aL, aR  reverbsc ainR, ainL, port:k(zkr(1),.008), 14000, sr, 0.75, .1
aL      nreverb  aL, 4, .25, 0, 2, 7777, 2, 7776
aR      nreverb  aR, 4, .25, 0, 2, 7775, 2, 7774
zawm (aL+ainL)*db(-18), 17
zawm (aR+ainR)*db(-18), 18


aL, aR shimmer_reverb zar(3), zar(4), \
int(random:i(120,450)), \ ;random predelay
.90, 15000, .65, 100, 2^(11/19)
;$STEREOHISH(3000'db(8)')
$STEREOCOMP
$STEREOHISH(12000'db(24)')
zawm aL, 19
zawm aR, 20


aL, aR shimmer_reverb zar(6), zar(5), \
int(random:i(120,450)), \ ;random predelay
.30, 15000, .65, 30, 2^(8/19)
;$STEREOHISH(3000'db(8)')
$STEREOCOMP
$STEREOHISH(12000'db(24)')
zawm aL, 21
zawm aR, 22


aL, aR shimmer_reverb zar(7), zar(8), \
int(random:i(120,450)), \ ;random predelay
.50, 15000, .65, 10, 2^(3/19)
;$STEREOHISH(3000'db(8)')
$STEREOCOMP
$STEREOHISH(12000'db(24)')
zawm aL, 23
zawm aR, 24


aL, aR shimmer_reverb zar(10), zar(9), \
int(random:i(120,450)), \ ;random predelay
.60, 15000, .65, 10, 2^(5/19)
;$STEREOHISH(3000'db(8)')
$STEREOCOMP
$STEREOHISH(12000'db(24)')
zawm aL, 25
zawm aR, 26
zacl 0, 16

adryL zar 50
adryR zar 51
outs adryL, adryR
zacl 50,51
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




i "Matrix" 0 z ;route all the channels around. feeds to instr 8000

i 8000 0 z 17 ;make za-17 and za-18 into master outs
i 8000 0 z 19 ;ditto za-19 and za-20
i 8000 0 z 21
i 8000 0 z 23
i 8000 0 z 25

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
f 2222 0 16385 -16 0 16384 -20 1

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
{4 k
f [$k+3010] 0 2048 -7 -96 [$k*512] -11 [[4-$k]*512] -96
}
{4 k
f [$k+3020] 0 2048 -7 -96 256 -12 [$k*384] -12 256 -96 [[4-$k]*384] -96
}
f 3024 0 2048 -7 -96 256 -12 [512+1024] -12 256 -96
f 3025 0 2048 -7 -96 256 -12 [512+1024+128+64] -12 64 -96
f 3026 0 2048 -7 -96 64 -12 [512+1024+256+128] -12 64 -96
f 3027 0 2048 -7 -96 64 -12 [512+1024+128+64] -12 256 -96


#define EDO(a'b') #[2^[[$a]/[$b]]]#

;---------------------------------------------------------------------------------
;---------------------------------------------------------------------------------
/*		SCALES	AND	MOTIFS 						*/
;---------------------------------------------------------------------------------
;---------------------------------------------------------------------------------
             
             ;numgrades interval basefreq basekey tuningRatio1 tuningRatio2
f129 0 -32 -51 7        4.0      55      0      \  ;to use this scale feed "1.xx" into p5 for $CONTROL instruments
1 \                 ;A
[$EDO(6'19')] \     ;A+1(chrom semi)
[$EDO(11'19')] \     ;A+6(major third)
[$EDO(17'19')] \    ;A+11(p fifth)
[2*[$EDO(3'19')]] \   ;A+19(octave)
[2*[$EDO(8'19')]] \    ;A2+3(whole tone)
[2*[$EDO(14'19')]] \   ;A2+8(p fourth)
[2*[$EDO(19'19')]]      ;A2+14(maj sixth)

             ;numgrades interval basefreq basekey tuningRatio1 tuningRatio2
f130 0 -32 -51 7        4.0      220      9      \  ;to use this scale feed "2.xx" into p5 for $CONTROL instruments
1 \                 ;A
[$EDO(5'19')] \     ;A+1(chrom semi)
[$EDO(8'19')] \     ;A+6(major third)
[$EDO(13'19')] \    ;A+11(p fifth)
[2*[$EDO(2'19')]] \   ;A+19(octave)
[2*[$EDO(7'19')]] \    ;A2+3(whole tone)
[2*[$EDO(16'19')]] \   ;A2+8(p fourth)
[2*[$EDO(19'19')]]      ;A2+14(maj sixth)


             ;numgrades interval basefreq basekey tuningRatio1 tuningRatio2
f131 0 -32 -51 7        4.0      110      5      \  ;to use this scale feed "1.xx" into p5 for $CONTROL instruments
1 \                 ;A
[$EDO(4'19')] \     ;A+1(chrom semi)
[$EDO(7'19')] \     ;A+6(major third)
[$EDO(11'19')] \    ;A+11(p fifth)
[2*[$EDO(1'19')]] \   ;A+19(octave)
[2*[$EDO(8'19')]] \    ;A2+3(whole tone)
[2*[$EDO(14'19')]] \   ;A2+8(p fourth)
[2*[$EDO(19'19')]]      ;A2+14(maj sixth)

             ;numgrades interval basefreq basekey tuningRatio1 tuningRatio2
f132 0 -32 -51 7        4.0      55      0      \  ;to use this scale feed "1.xx" into p5 for $CONTROL instruments
1 \                 ;A
[$EDO(6'19')] \     ;A+1(chrom semi)
[$EDO(11'19')] \     ;A+6(major third)
[$EDO(17'19')] \    ;A+11(p fifth)
[2*[$EDO(3'19')]] \   ;A+19(octave)
[2*[$EDO(8'19')]] \    ;A2+3(whole tone)
[2*[$EDO(14'19')]] \   ;A2+8(p fourth)
[2*[$EDO(19'19')]]      ;A2+14(maj sixth)


             ;numgrades interval basefreq basekey tuningRatio1 tuningRatio2
f148 0 -96 -51 7        2.0      55      0      \  ;"20.xx"
1 \                 ;A
[$EDO(3'19')] \     ;A+1(chrom semi)
[$EDO(6'19')] \     ;A+6(major third)
[$EDO(8'19')] \    ;A+11(p fifth)
[$EDO(11'19')] \   ;A+19(octave)
[$EDO(14'19')] \    ;A2+3(whole tone)
[$EDO(17'19')] \   ;A2+8(p fourth)
[$EDO(19'19')]      ;A2+14(maj sixth)

;---------------------------------------------------------------------------
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
/*			PERFORMANCE			*/
;---------------------------------------------------------------------------

#define SWIRLa(a'm') #
i 3146 0 [8] [$m] [$a] [[1024]] [2] 3
#


#define SWELL(t'd'a'b'i') #
i 3142 [$t] [8] 3000 [$a] [[256*$d]] [$i] 1
i 3142 [$t] [8] 3000 [$b] [[256*$d]] [$i] 1
#

/*
{3 x
i 3150 [[$x]] 1 3026 [[$x*.01]+1.07] 2048 3 1
i 3150 [[$x+.5]] 1 3026 [[$x*.01]+1.09] 2048 3 .
}
b 5
{4 x
i 3150 [$x] 1 3026 [[$x*.01]+4.09] 2048 3 .
i 3150 [$x+.5] 1 3026 [[$x*.01]+4.11] 2048 3 .
}
*/
i "ZIW" 0.01 0 	0.910 1 ;turn down rev fbk on first Matrix chain

;i 3142 0 5 	3027 1.14 8 	2 1 ; anote
;i 3142 ^+1 5 	3027 1.08 11 	2 1
/*
b 0
i 3142 0 5   	3012 20.13 1024 	2.5 1
i 3142 ^+2 2   	3027 1.09 27 	2.5 1
i 3142 ^+2 5   	3012 20.12 1024 	2.5 1
i 3142 ^+2 3   	3027 1.10 27 	1.6 1
i 3142 ^+1 5   	3012 20.14 1024 	2.5 1
i 3142 ^+2 6   	3027 1.11 12	2.5 1
i 3142 ^+2 5   	3012 20.13 1024 	2.5 1
i 3142 ^+2 5   	3012 20.15 1024 	2.5 1
*/

/* special "tense" or "sad" chord"
i 3142 13 8 	3012 2.05 512 	3 1
i 3142 13 8 	3012 2.11 512 	3 1
*/
/* special "tense" or "sad" chord"
i 3142 0 8 	3012 1.05 512 	3 1
i 3142 0 8 	3012 2.10 512 	3 1
*/
/*
i 3142 0 8 	3012 1.05 1024 	3 1
i 3142 0 8 	3012 2.10 1024 	3 1
*/
/*
i 3142 0 4 	3026 1.07 12 	3 1
i 3142 0 4 	3026 1.09 12 	3 1
b 8
i 3142 0 4 	3026 1.09 12 	3 1
i 3142 0 4 	3026 2.10 12 	3 1
i 3142 7 4 	3026 1.07 12 	3 1
i 3142 7 4 	3026 1.09 12 	3 1

i 3142 10 4 	3026 1.08 12 	3 1
i 3142 10 4 	3026 1.10 12 	3 1
*/
i 3142 0 2 	3026 20.24 22 	3 1
i 3142 0 2 	3026 20.25 22 	3 1
i 3142 0 2 	3026 20.27 22 	3 1

/*
b 0
$SWIRLa(1.06'3026')
$SWIRLa(1.07'3026')
$SWIRLa(1.00'3026')
*/


</CsScore>
</CsoundSynthesizer>    

