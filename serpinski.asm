// 
// Serpinsksi.asm - Renders a Serpinski triangle on 320x200 bitmapped mode 
// on the Commodore 64 using SID hardware generated random numbers 
// C. Millsap - July 2019 
// 

*=$0801
        .byte $0E, $08, $0A, $00, $9E, $20, $28, $32
        .byte $30, $36, $34, $29, $00, $00, $00     // sys (2064)

.label scratchPad = $fd
.label GFX_MEM = $2000 
.label borderColor = $D0
.label currXStart = 159 
.label currYStart = 99
.label DeltaX = $fb 
.label DeltaY = $fd
.label BorColor = $0d
.label memColor = $d0
.label VICII = $d000
.label borderReg = VICII + $20
.label bitmapLocReg = VICII + $18 
.label bitmapModeReg = VICII + $11

init:     getTime(time1)
          lda #BorColor
          sta borderReg
          lda #$00 
          sta CurrPoint
          sta CurrPoint+1 
          sta CurrentX+1 
          sta CurrentY+1  
          lda #currXStart
          sta CurrentX
          lda #currYStart
          sta CurrentY
initSID:  lda #$ff 
          sta $d40e
          sta $d40f 
          lda #$80 
          sta $d412
biton:    lda bitmapLocReg 
          ora #$08 
          sta bitmapLocReg // set bitmap location to $2000 
          lda bitmapModeReg 
          ora #$20 
          sta bitmapModeReg // turn on bitmap graphics mode 
          lda #>GFX_MEM
          tax
          sta scratchPad+1 
          lda #<GFX_MEM
          sta scratchPad 
 cls:     ldy #$ff 
 clinner:  sta (scratchPad),y // clear the bitmap 
           dey 
           bne clinner 
           sta (scratchPad),y // clear the zeroeth byte of the page. 
           inx 
           stx scratchPad+1 
           cpx #$40 
           bne cls
clcset:    lda #$04   //clear color RAM at $0400 - be careful near the end or BASIC memory will be corrupted
           sta scratchPad+1
           tax 
           lda #memColor
 clcolor:  ldy #$ff 
 clcinner: sta (scratchPad),y 
           dey
           bne clcinner 
           inx 
           sta (scratchPad),y  // for the zeroth byte 
           stx scratchPad+1 
           cpx #$07
           bne clcolor
           ldy #$e8 
clclast:   sta (scratchPad),y 
           dey 
           bne clclast
           sta (scratchPad),y // for the zeroth byte on page 7
           lda #$00 
           sta DeltaX
           sta DeltaX+1 
           sta DeltaY 
           sta DeltaY+1
mainLoop:  clc 
           lda $d41b  // load a value from the SID's RNG - skippping the subroutine saves some time. 
           ldx #$00 
           cmp #85  
           bcc cont
           inx
           inx 
           cmp #171 
           bcc cont 
           inx
           inx  
  cont:    sec
           lda VertexY,x
           sbc CurrentY
           sta DeltaY 
           lda VertexY+1,x 
           sbc CurrentY+1 
           sta DeltaY+1 
           sec 
           lda VertexX,x 
           sbc CurrentX 
           sta DeltaX 
           lda VertexX+1,x 
           sbc CurrentX+1 
           sta DeltaX+1 
           clc 
           lda DeltaX+1 
           asl 
           ror DeltaX+1 
           ror DeltaX 
           clc 
           lda DeltaY+1 
           asl  
           ror DeltaY+1 
           ror DeltaY 
           clc 
           lda CurrentX  
           adc DeltaX 
           sta CurrentX
           lda CurrentX+1
           adc DeltaX+1  
           sta CurrentX+1 
           clc 
           lda CurrentY
           adc DeltaY 
           sta CurrentY
           lda CurrentY+1 
           adc DeltaY+1 
           sta CurrentY+1
           jsr plot 
           clc 
           inc CurrPoint 
           beq currPntHi
           jmp mainLoop 
 currPntHi: inc CurrPoint+1 
           lda CurrPoint+1 
           cmp #$10
           beq endserp
           jmp mainLoop 
 endserp:  getTime(time2)
 waitSpace:lda #$7F   // found in lemon64 forums
           sta $DC00 
           lda $DC01 
           and #$10  
           bne waitSpace  
           jsr $FF5B   //CINT - set machine back to defaults.   
           rts 
      
plot: stx pllX+1 // Based on plot routine from Codebase64
      sty pllY+1  
      clc
      ldx CurrentX
      ldy CurrentY 
      lda CurrentX+1 
      beq noHY
      sec 
 noHY:lda YTableHi,y 
      bcc !+
      adc #$00      // Adds 1 (256 pixels) to HiByte
!:    sta $fc
      lda YTableLo,y
      sta $fb
      ldy XTable,x
      lda BitMask,x
      ora ($fb),y
      sta ($fb),y
pllX: ldx #$00 
pllY: ldy #$00 
      rts



RandHW: lda $d41b     //Get a random number from the SID HW Randon Number Generator 
        rts 

VertexX: .word 0
         .word 319
         .word 159
VertexY: .word 199
         .word 199
         .word 0
CurrentX: .word  currXStart
CurrentY: .word currYStart
seed:  .byte 78 
CurrPoint: .word 0 
errorPoint: .byte 0 
time1: .dword 0 
time2: .dword 0 
randomEor:  .byte $1d, $2b, $2d, $4d, $5f, $63, $65, $69
            .byte $71, $87, $8d, $a9, $c3, $cf, $e7, $f5         

 //generate tables for bitmap access x and y lookup 
     .align $100
BitMask:
    .fill 256, pow(2,7-i&7)
    .align $100
XTable:
    .fill 256, floor(i/8)*8
    .align $100
YTableHi:
    .fill 200, >GFX_MEM+[320*floor(i/8)]+[i&7]
    .align $100
YTableLo:
    .fill 200, <GFX_MEM+[320*floor(i/8)]+[i&7]
    .align $100 




.label swJiffyClock = $a0
.macro getTime(outputLocation) {     
       lda.zp swJiffyClock  
       sta outputLocation 
       lda.zp swJiffyClock+1
       sta outputLocation+1 
       lda.zp swJiffyClock+2 
       sta outputLocation+2 
}        