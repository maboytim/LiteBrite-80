; Assemble with Matthew Reed's z80 assembler
; http://www.trs-80emulators.com/z80asm/
;
; z80asm.exe lb80txm1.asm


; Program to display text string in scrolling marquee style on LB-80 8x8 display.
; The code moves continuously through memory and runs in the region corresponding
; to the LED (dot) to be lit.  It copies itself to the region corresponding to
; then the next dot to be lit and then jumps there.  Then repeats for the next
; dot to be lit, and so on.  At the end of the string it loops back to the
; beginning and repeats indefinitely until reset.
;
; TRS-80 Model 1 and Model 3 version
;
; The TRS-80 M1 and M3 have display, keyboard, and ROM below 4000h so the
; operation described above doesn't actually work for dots corresponding to
; regions below 4000h (the bottom two rows of the 8x8 display).  In those cases
; the program actually performs a copy from the region to the region but doesn't
; actually jump there - this is called a 'gratuitous copy' since the purpose is
; simply to light the dot.  Instead it keeps running where it is and advances to
; the next dot.  This will repeat until it gets to a dot that corresponds to RAM
; and finally jumps.  As a result the brightness of the LEDs will be nonuniform
; but surprisingly it isn't really noticeable.  Actually for the M1 with the
; lowercase installed and for the M3 the Z80 can actually run from display RAM
; which is located at 3C00h-3FFFh so the actual threshold for the gratuitous
; copies is 3C00h not 4000h.  For a M1 without lowercase installed it needs to
; be 4000h (see comment in code below).  If the display memory is included then
; the program and data can be seen on the display.
;
; The program, data, and stack need to be less than 1k to fit completely within
; a region that corresponds to a single dot.  The copy is performed usin a LDIR
; block move instruction.  The rate at which the program steps through the dots
; will depend on the size of the block move.  The size could be as small as the
; program and data but the rate of stepping through the dots would depend on
; the size.  Instead a fixed LDIR size is used but of course need to be at least
; as big as the progam and data.
;
; The program first converts the display string to dot data and then iterates
; over the dot data.  The part of the program that does this isn't needed after
; conversion is done so isn't included in the portion that moves throughout
; memory.  The portion that moves throught memory starts at lb80txt.
;
; This LB-80 demo program turns out to be a pretty good memory stess test.  Any
; memory errors are likely to crash the program or at least have some visual
; effect on what is displayed.  To exercise memory even further the program moves
; itself within the 1k blocks.  It advances one byte with each copy until it
; would no longer fit and then jumps back.  If the display memory is incuded then
; this movement can be see on the display.

; iterations of the ldir
; This needs to be at least enough to contain the lb80txt code and data.
; The time this takes will affect the scroll rate - increase to slow down the
; scrolling, decrease to increase the scrolling.  The value here was determined
; empirically.
;
itern   equ     0180h


        org     5200h

entry   ld      a,(hl)          ;skip an opening " - this is so string can start with space
        cp      '"'
        jr      nz,noquot
        inc     hl
        ld      a,(hl)
noquot  cp      ' '             ;loop until ctrl char
        jr      nc,gotarg
        ld      hl,deftxt       ;if end of line then use default string
gotarg  ld      de,coldta
arglp   ld      a,(hl)
        sub     ' '             ;expand characte to 6 columns of dots
        jr      c,argend
        push    hl
        ld      l,a
        ld      h,0
        add     hl,hl   ;*2
        add     hl,hl   ;*4
        ld      c,a
        ld      b,0
        add     hl,bc   ;*5
        ld      bc,chrdta
        add     hl,bc
        ld      bc,5
        ldir
        xor     a
        ld      (de),a
        inc     de
        pop     hl
        inc     hl
        jr      arglp
argend
        ld      hl,-coldta      ;compute length
        add     hl,de
; the display routine will go 7 col's past its len so sub 7
; so the len must be at least 8 but if the string is only
; a single character the len would be only 6 so pad up for
; that case
        ld      bc,-8
        add     hl,bc
        jr      c,nopad
padlen  xor     a
        ld      (de),a
        inc     de
        inc     hl
        ld      a,h
        or      l
        jr      nz,padlen
nopad   inc     hl

        ld      (len+1),hl      ;save len

; fill remainder of data area with *'s
filldta ld      a,'*'
        ld      (de),a
        inc     de
        inc     hl
        ld      a,h
        cp      itern .shr. 8
        jr      c,filldta
        ld      a,l
        cp      itern .and. 0FFh
        jr      c,filldta

        di
        ld      sp,lb80txt+itern;put stack at end of block
        ld      ix,lb80txt      ;jump to actual code
        jp      (ix)

; default string to display
deftxt  defb    " Say hi to LB-80-M1/M3! ",0

; 5x8 character data as columns of dots
chrdta
        defb    000h,000h,000h,000h,000h ;  
        defb    000h,000h,0FAh,000h,000h ; !
        defb    000h,0E0h,000h,0E0h,000h ; "
        defb    028h,0FEh,028h,0FEh,028h ; #
        defb    024h,054h,0FEh,054h,048h ; $
        defb    0C4h,0C8h,010h,026h,046h ; %
        defb    06Ch,092h,06Ah,004h,00Ah ; &
        defb    010h,0E0h,0C0h,000h,000h ; '
        defb    000h,038h,044h,082h,000h ; (
        defb    000h,082h,044h,038h,000h ; )
        defb    054h,038h,0FEh,038h,054h ; *
        defb    010h,010h,07Ch,010h,010h ; +
        defb    001h,00Eh,00Ch,000h,000h ; ,
        defb    010h,010h,010h,010h,010h ; -
        defb    000h,006h,006h,000h,000h ; .
        defb    004h,008h,010h,020h,040h ; /
        defb    07Ch,08Ah,092h,0A2h,07Ch ; 0
        defb    000h,042h,0FEh,002h,000h ; 1
        defb    04Eh,092h,092h,092h,062h ; 2
        defb    044h,082h,092h,092h,06Ch ; 3
        defb    018h,028h,048h,0FEh,008h ; 4
        defb    0E4h,0A2h,0A2h,0A2h,09Ch ; 5
        defb    03Ch,052h,092h,092h,00Ch ; 6
        defb    086h,088h,090h,0A0h,0C0h ; 7
        defb    06Ch,092h,092h,092h,06Ch ; 8
        defb    060h,092h,092h,094h,078h ; 9
        defb    000h,06Ch,06Ch,000h,000h ; :
        defb    001h,06Eh,06Ch,000h,000h ; ;
        defb    010h,028h,044h,082h,000h ; <
        defb    028h,028h,028h,028h,028h ; =
        defb    000h,082h,044h,028h,010h ; >
        defb    040h,080h,08Ah,090h,060h ; ?
        defb    04Ch,092h,09Eh,082h,07Ch ; @
        defb    03Eh,048h,088h,048h,03Eh ; A
        defb    082h,0FEh,092h,092h,06Ch ; B
        defb    07Ch,082h,082h,082h,044h ; C
        defb    082h,0FEh,082h,082h,07Ch ; D
        defb    0FEh,092h,092h,082h,082h ; E
        defb    0FEh,090h,090h,080h,080h ; F
        defb    07Ch,082h,082h,092h,09Eh ; G
        defb    0FEh,010h,010h,010h,0FEh ; H
        defb    000h,082h,0FEh,082h,000h ; I
        defb    004h,002h,002h,002h,0FCh ; J
        defb    0FEh,010h,028h,044h,082h ; K
        defb    0FEh,002h,002h,002h,002h ; L
        defb    0FEh,040h,030h,040h,0FEh ; M
        defb    0FEh,040h,020h,010h,0FEh ; N
        defb    07Ch,082h,082h,082h,07Ch ; O
        defb    0FEh,090h,090h,090h,060h ; P
        defb    07Ch,082h,08Ah,084h,07Ah ; Q
        defb    0FEh,090h,098h,094h,062h ; R
        defb    064h,092h,092h,092h,04Ch ; S
        defb    080h,080h,0FEh,080h,080h ; T
        defb    0FCh,002h,002h,002h,0FCh ; U
        defb    0E0h,018h,006h,018h,0E0h ; V
        defb    0FEh,004h,008h,004h,0FEh ; W
        defb    0C6h,028h,010h,028h,0C6h ; X
        defb    0C0h,020h,01Eh,020h,0C0h ; Y
        defb    086h,08Ah,092h,0A2h,0C2h ; Z
        defb    020h,040h,0FEh,040h,020h ; [
        defb    008h,004h,0FEh,004h,008h ; \
        defb    010h,038h,054h,010h,010h ; ]
        defb    010h,010h,054h,038h,010h ; ^
        defb    002h,002h,002h,002h,002h ; _
        defb    000h,000h,0E0h,0D0h,000h ; `
        defb    004h,02Ah,02Ah,02Ah,01Eh ; a
        defb    0FEh,014h,022h,022h,01Ch ; b
        defb    01Ch,022h,022h,022h,014h ; c
        defb    01Ch,022h,022h,014h,0FEh ; d
        defb    01Ch,02Ah,02Ah,02Ah,018h ; e
        defb    000h,010h,07Eh,090h,040h ; f
        defb    018h,025h,025h,019h,03Eh ; g
        defb    0FEh,010h,020h,020h,01Eh ; h
        defb    000h,022h,0BEh,002h,000h ; i
        defb    002h,001h,001h,001h,0BEh ; j
        defb    0FEh,008h,014h,022h,000h ; k
        defb    000h,082h,0FEh,002h,000h ; l
        defb    03Eh,020h,01Eh,020h,01Eh ; m
        defb    03Eh,010h,020h,020h,01Eh ; n
        defb    01Ch,022h,022h,022h,01Ch ; o
        defb    03Fh,018h,024h,024h,018h ; p
        defb    018h,024h,024h,018h,03Fh ; q
        defb    03Eh,010h,020h,020h,010h ; r
        defb    012h,02Ah,02Ah,02Ah,024h ; s
        defb    020h,020h,0FCh,022h,024h ; t
        defb    03Ch,002h,002h,004h,03Eh ; u
        defb    038h,004h,002h,004h,038h ; v
        defb    03Ch,002h,00Ch,002h,03Ch ; w
        defb    022h,014h,008h,014h,022h ; x
        defb    038h,005h,005h,005h,03Eh ; y
        defb    022h,026h,02Ah,032h,022h ; z
        defb    000h,010h,06Ch,082h,000h ; {
        defb    000h,000h,0EEh,000h,000h ; |
        defb    000h,082h,06Ch,010h,000h ; }
        defb    040h,080h,040h,020h,040h ; ~
        defb    054h,0AAh,054h,0AAh,054h ; 


; actual display code
; this needs to be 1k aligned
; it wouldn't need to be but if it's in the destination region
; of a copy it will get clobbered

        org     5800h

lb80txt ld      hl,coldta-lb80txt ;get start of column data
len     ld      bc,$-$          ;get length

lp0     push    bc              ;save length
        defb    0DDh            ;ld e,ixl
        ld      e,l
        defb    0DDh            ;ld a,ixh
        ld      a,h
        and     3               ;get start address of first column
        ld      d,a
        ex      de,hl           ;de=column data index, hl=column address
        ld      c,8             ;get column count

lp1     push    ix              ;compute pointer to column data
        ex      (sp),hl
        add     hl,de
        ld      a,(hl)          ;get next column data
        pop     hl
        push    de              ;save column data index

        ld      b,8             ;get row count
lp2     push    bc              ;save row and column count
        ld      bc,itern
        rra
        jr      nc,pxoff        ;go if pixel off

; hl contains the computed base destination
; ix contains the current base
pxon    ld      e,a
        ld      a,h
        cp      3Ch             ;compare dest with display ram start
;        cp      40h             ;compare with ram start (m1 w/o lc)
        ld      a,e
        jr      c,gratu         ;do gratuitous move if not ram

        ld      a,h             ;check for copy to self
        and     0FCh
        ld      d,a
        defb    0DDh            ;ld a,ixh - get current base hi in a
        ld      a,h
        and     0FCh
        cp      d
        jr      z,nowrap

        inc     hl              ;bump dest and wrap back to 0
        ld      a,h
        and     400h-1 .shr. 8
        cp      400h-itern .shr. 8
        jr      c,nowrap
        ld      a,l
        cp      400h-itern .and. 0FFh
        jr      c,nowrap
        ld      a,h
        and     -400h .shr. 8
        ld      h,a
        ld      l,0
nowrap  ld      a,e

        defb    0DDh            ;ld e,ixl - get current base in de
        ld      e,l
        defb    0DDh            ;ld d,ixh
        ld      d,h
        ex      de,hl           ;swap so old base hl, new base in de
        defb    0DDh            ;ld ixl,e - copy new base to ix
        ld      l,e
        defb    0DDh            ;ld ixh,d
        ld      h,d
        ldir

        ld      hl,-6           ;compute new stack location
        add     hl,de
        ld      sp,hl           ;set new stack location
                                ;jump to the program at the new location
        ld      hl,pxmrg-lb80txt-itern ;jump to pxmrg at new location
        add     hl,de
        jp      (hl)

gratu   ld      e,l
        ld      d,h
        ldir

pxmrg   ld      l,e
        ld      h,d

pxoff   add     hl,bc           ;skip row if jr'ed to here
        ld      bc,2000h-itern  ;jump to next row
        add     hl,bc
        pop     bc              ;restore row and column count
        djnz    lp2             ;do all rows
        
        ld      de,0400h        ;jump to next column
        add     hl,de
        pop     de              ;restore column data pointer
        inc     de              ;bump
        dec     c               ;do all columns
        jr      nz,lp1 

        pop     bc              ;restore len
        ld      hl,-7           ;reset column data pointer to previous start plus 1
        add     hl,de
        dec     bc              ;do all data bytes
        ld      a,b
        or      c
        jr      nz,lp0
        jp      (ix)

coldta
        defb    0

        end     entry
