;*******************************************************************************
;    main.asm - projet janvier horloge - louis mingot
;    pic18f25k40 - assembleur
;*******************************************************************************

#include "p18f25k40.inc"

;*******************************************************************************
; CONFIGURATION BITS
;*******************************************************************************

; CONFIG1L :
CONFIG FEXTOSC = OFF ; pas d'oscillateur externe
CONFIG RSTOSC  = HFINTOSC_64MHZ

; CONFIG1H :
CONFIG CLKOUTEN = ON

; CONFIG3L :
CONFIG WDTE = OFF

; CONFIG4H :
CONFIG LVP = OFF

;*******************************************************************************
; VARIABLE DEFINITIONS
;*******************************************************************************

; variables générales
var	    UDATA_ACS
lastBtnPressed	    RES	    1 ; indique le dernier bouton pressé
ledvCounter         RES     1 ; compteur de leds (0 à 4) (= minutes modulo 5)
secondsCounter      RES     1 ; compteur de secondes (0 à 60)
minutesCounter      RES     1 ; compteur des minutes (0 à 60)
hoursCounter        RES     1 ; compteur des heures (1 à 13)

minutesIndex        RES     1 ; indice des minutes

; variables temporaires
temp		    RES     1 ; valeur temporaire pour stocker des données
temp2		    RES     1 ; mm chose...
tempIndex	    RES     1 ; valeur d'indice temporaire
	    
rgbColors   UDATA ; stocke un entier de 0 à 3 correspondant à la couleur de la LED RGB à afficher
rgb0    RES 1
rgb1    RES 1
rgb2    RES 1
rgb3    RES 1
rgb4    RES 1
rgb5    RES 1
rgb6    RES 1
rgb7    RES 1
rgb8    RES 1
rgb9    RES 1
rgb10   RES 1
rgb11   RES 1

;*******************************************************************************
; RESET VECTOR
;*******************************************************************************

RES_VECT CODE 0x0000
        GOTO    START

;*******************************************************************************
; INITIALISATION DES PORTS ET MODULES
;*******************************************************************************

ConfigOsc:
    ; --- OSCILLATEUR 64 MHz ---
    BANKSEL OSCCON1
    MOVLW   b'01100000'
    MOVWF   OSCCON1

    BANKSEL OSCFRQ
    MOVLW   b'00001000'    ; 64 MHz
    MOVWF   OSCFRQ
    RETURN
	
ConfigPorts:
    ; configuration port A - LEDs RA0-3
    BANKSEL ANSELA
    CLRF    ANSELA           ; tout port A en numérique

    BANKSEL TRISA
    BCF     TRISA, 0         ; RA0 sortie
    BCF     TRISA, 1         ; RA1 sortie
    BCF     TRISA, 2         ; RA2 sortie
    BCF     TRISA, 3         ; RA3 sortie

    BANKSEL LATA
    CLRF    LATA             ; LEDs éteintes au départ
    RETURN

ConfigRGB:
    ; s'assurer d'une horloge stable (optionnel ici)
    ; BANKSEL OSCFRQ
    ; BSF     OSCFRQ, 3
    ; BCF     OSCFRQ, 1
    
    ; RC1 en sortie
    BANKSEL TRISC
    BCF     TRISC, 1

    ; RC1 en numérique (obligatoire)
    BANKSEL ANSELC
    BCF     ANSELC, 1

    ; ligne data à 0 au repos
    BANKSEL LATC
    BCF     LATC, 1

    RETURN

ConfigButtons:
    ; RB1 (bouton minutes (-))
    BANKSEL TRISB
    BSF TRISB, 1               ; RB1 en entrée (bouton1)
    BANKSEL ANSELB
    BCF ANSELB, 1              ; RB1 en numérique
    BANKSEL INLVLB
    BSF     INLVLB, 1          ; active une entrée en TTL sur RB1 (important)
    
    ; RB2 (bouton heures (-))
    BANKSEL TRISB
    BSF TRISB, 2               ; RB2 en entrée (bouton2)
    BANKSEL ANSELB
    BCF ANSELB, 2              ; RB2 en numérique
    BANKSEL INLVLB
    BSF     INLVLB, 2          ; active une entrée en TTL sur RB2 (important)
    
    ; RB3 (bouton heures (+))
    BANKSEL TRISB
    BSF TRISB, 3               ; RB3 en entrée (bouton3)
    BANKSEL ANSELB
    BCF ANSELB, 3              ; RB3 en numérique
    BANKSEL INLVLB
    BSF     INLVLB, 3          ; active une entrée en TTL sur RB3 (important)
    
    ; RB4 (bouton minutes (+))
    BANKSEL TRISB
    BSF TRISB, 4               ; RB4 en entrée (bouton4)
    BANKSEL ANSELB
    BCF ANSELB, 4              ; RB4 en numérique
    BANKSEL INLVLB
    BSF     INLVLB, 4          ; active une entrée en TTL sur RB4 (important)
    RETURN	

; ConfigPWM:
    ; configuration du module CCP2 pour PWM
    ; MOVLW   b'00000100'        ; CCP2 utilise Timer2
    ; MOVWF   CCPTMRS

    ; configuration PPS pour associer RC1 à CCP2
    ; MOVLB   0x0D               ; sélection de la banque 13
    ; MOVLW   0x0B               ; code PPS pour CCP2
    ; MOVWF   RC1PPS, 1          ; associe CCP2 (PWM) à RC1

    ; configuration de la période PWM
    ; MOVLW   0xE7               ; T2PR = 231 (~100 Hz)
    ; MOVWF   T2PR

    ; configuration du rapport cyclique initial
    ; CLRF    CYCLE              ; initialise CYCLE à 0 %
    ; MOVLW   0x7F               ; duty cycle = 50 %
    ; MOVWF   CCPR2H
    ; CLRF    CCPR2L

    ; configuration de Timer2
    ; MOVLW   b'00000001'        ; source Timer2 = Fosc/4
    ; MOVWF   T2CLKCON
    ; MOVLW   b'00000100'        ; active Timer2, prescaler = 1:1
    ; MOVWF   T2CON

    ; activation du module PWM
    ; MOVLW   b'00111100'        ; CCP2 en mode PWM
    ; MOVWF   CCP2CON
    ; RETURN    
 
;*******************************************************************************
; TODO - INTERRUPT SERVICE ROUTINES (ISRs)
;
; there are a few different ways to structure interrupt routines in the 8
; bit device families.  on PIC18's the high priority and low priority
; interrupts are located at 0x0008 and 0x0018, respectively.  (on PIC16's and
; lower the interrupt is at 0x0004.  between device families there is subtle
; variation in the both the hardware supporting the ISR (for restoring
; interrupt context) as well as the software used to restore the context
; (without corrupting the STATUS bits)).
;
; general formats are shown below in relocatible format.
;
;----------------------------------PIC18's--------------------------------------
;
; ISRHV     CODE    0x0008
;     Goto    HIGH_ISR
; ISRLV     CODE    0x0018
;     Goto    LOW_ISR
;
; ISRH      CODE                     ; let linker place high ISR routine
; HIGH_ISR
;     <Insert High Priority ISR Here - no SW context saving>
;     RETFIE  FAST
;
; ISRL      CODE                     ; let linker place low ISR routine
; LOW_ISR
;       <Search the device datasheet for 'context' and copy interrupt
;       context saving code here>
;     RETFIE
;
;*******************************************************************************

; TODO INSERT ISR HERE
    
;*******************************************************************************
; MAIN PROGRAM
;*******************************************************************************	
	
MAIN_PROG CODE

START:
    
    ; on appelle les routines de CONFIG!
    CALL ConfigOsc
    CALL ConfigPorts
    CALL ConfigRGB
    CALL ConfigButtons
    ; CALL ConfigPWM
    ; CALL ConfigI2C
    
    ; on clear (presque) toutes les variables
    CLRF ledvCounter ; compteur = 0 au démarrage
    CLRF secondsCounter
    CLRF minutesCounter
    CLRF hoursCounter
    CLRF temp
    CLRF temp2
    CLRF tempIndex
    CLRF minutesIndex
    ; ... 
    CLRF rgb0
    CLRF rgb1
    CLRF rgb2
    CLRF rgb3
    CLRF rgb4
    CLRF rgb5
    CLRF rgb6
    CLRF rgb7
    CLRF rgb8
    CLRF rgb9
    CLRF rgb10
    CLRF rgb11

;*******************************************************************************
; BOUCLE PRINCIPALE (main loop)
;*******************************************************************************

CALL UpdateRGBDisplay    
    
MAIN_LOOP:
        ; CALL LEDv_blink
	; CALL FirstRGBLEDWhite
	; CALL AllRGBLEDsWhite
	
	CALL AwaitButton
	
	GOTO MAIN_LOOP ; boucle infinie
	
;*******************************************************************************
; FONCTIONS DE TEMPORISATION
;*******************************************************************************

; temporisation 1 seconde (LFINTOSC)
TEMPO_1S:
    
    MOVLW   B'10010000'		    
    MOVWF   T0CON0, ACCESS	    ; timer0 clock Sosc
    
    MOVLW   B'10010000'	
    MOVWF   T0CON1, ACCESS	    ; set les valeurs du registre T0CON1
				    ; (clock = SOSC / LFINTOSC)
    
    ; initialiser la valeur du timer à 33536
    MOVLW   0x86		    ; maj TMR0H
    MOVWF   TMR0H
    MOVLW   0xE8		    ; maj TMR0L
    MOVWF   TMR0L
    
TEMPO_1S_RUN:    
    BTFSS   T0CON0, 5, ACCESS	    ; tester l'overflow du timer
    GOTO    TEMPO_1S_RUN
    BCF	    T0CON0, 7, ACCESS	    ; reset bit de démarrage
    RETURN


TEMPO_0_5S:
    
    MOVLW   B'10010000'		    
    MOVWF   T0CON0, ACCESS	    ; timer0 clock Sosc
    
    MOVLW   B'10010000'	
    MOVWF   T0CON1, ACCESS	    ; set les valeurs du registre T0CON1
    
    ; initialiser la valeur du timer à 50036
    MOVLW   0xC3 		    ; maj TMR0H
    MOVWF   TMR0H
    MOVLW   0x74		    ; maj TMR0L
    MOVWF   TMR0L
    
TEMPO_0_5S_RUN:    
    BTFSS   T0CON0, 5, ACCESS	    ; tester l'overflow du timer
    GOTO    TEMPO_0_5S_RUN  
    BCF	    T0CON0, 7, ACCESS	    ; reset bit de démarrage
    RETURN
   
    
TEMPO_0_2S:
    
    MOVLW   B'10010000'		    
    MOVWF   T0CON0, ACCESS	    ; timer0 clock Sosc
    
    MOVLW   B'10010000'	
    MOVWF   T0CON1, ACCESS	    ; set les valeurs du registre T0CON1
    
    ; initialiser la valeur du timer à 58036
    MOVLW   0xE2 		    ; maj TMR0H
    MOVWF   TMR0H
    MOVLW   0xB4		    ; maj TMR0L
    MOVWF   TMR0L
    
TEMPO_0_2S_RUN:    
    BTFSS   T0CON0, 5, ACCESS	    ; tester l'overflow du timer
    GOTO    TEMPO_0_2S_RUN
    BCF	    T0CON0, 7, ACCESS	    ; reset bit de démarrage
    RETURN


TEMPO_0_1S:

    MOVLW   B'10010000'
    MOVWF   T0CON0, ACCESS	    ; timer0 clock Sosc

    MOVLW   B'10010000'
    MOVWF   T0CON1, ACCESS	    ; set les valeurs du registre T0CON1

    ; initialiser la valeur du timer à 61786
    MOVLW   0xF1
    MOVWF   TMR0H
    MOVLW   0x5A
    MOVWF   TMR0L

TEMPO_0_1S_RUN:
    BTFSS   T0CON0, 5, ACCESS	    ; tester l'overflow du timer
    GOTO    TEMPO_0_1S_RUN

    BCF     T0CON0, 7, ACCESS	    ; reset bit de démarrage
    RETURN  


TEMPO_10MS:
    
    MOVLW   B'10010000'		    
    MOVWF   T0CON0, ACCESS	    ; timer1 clock Sosc
    
    MOVLW   B'10010000'	
    MOVWF   T0CON1, ACCESS	    ; set les valeurs du registre T0CON1
    
    ; initialiser la valeur du timer à 65226
    MOVLW   0xFE 		    ; maj TMR0H
    MOVWF   TMR0H
    MOVLW   0xCA		    ; maj TMR0L
    MOVWF   TMR0L
    
TEMPO_10MS_RUN:    
    BTFSS   T0CON0, 5, ACCESS	    ; tester l'overflow du timer
    GOTO    TEMPO_10MS_RUN
    BCF	    T0CON0, 7, ACCESS	    ; reset bit de démarrage
    RETURN


;*******************************************************************************
; ROUTINES LEDs VERTES (RA0 à RA3)
;*******************************************************************************

TurnOffLD0: ; éteint la led0
        BANKSEL LATA
        BCF     LATA, 0
        RETURN

TurnOnLD0: ; allume la led0
        BANKSEL LATA
        BSF     LATA, 0
        RETURN

TurnOffLD1: ; éteint la led1
        BANKSEL LATA
        BCF     LATA, 1
        RETURN

TurnOnLD1:  ; allume la led1
        BANKSEL LATA
        BSF     LATA, 1
        RETURN

TurnOffLD2: ; éteint la led2
        BANKSEL LATA
        BCF     LATA, 2
        RETURN

TurnOnLD2:  ; allume la led2
        BANKSEL LATA
        BSF     LATA, 2
        RETURN

TurnOffLD3: ; éteint la led3
        BANKSEL LATA
        BCF     LATA, 3
        RETURN

TurnOnLD3:  ; allume la led3
        BANKSEL LATA
        BSF     LATA, 3
        RETURN

TurnOnAllLEDs: ; allume toutes les leds
        BANKSEL LATA
        BSF     LATA, 0
        BSF     LATA, 1
        BSF     LATA, 2
        BSF     LATA, 3
        RETURN

TurnOffAllLEDs: ; éteint toutes les leds
        BANKSEL LATA
        BCF     LATA, 0
        BCF     LATA, 1
        BCF     LATA, 2
        BCF     LATA, 3
        RETURN

LEDv_blink: ; fait blinker les 4 leds vertes en série (chenille)
        BANKSEL LATA

	; ledv0
        BSF     LATA, 0 ; allume la led 0
        CALL    TEMPO_0_2S ; temporisation 0.2s
        BCF     LATA, 0 ; éteint la led 0
	; même chose ensuite pour les autres leds...

	; ledv1
        BSF     LATA, 1
        CALL    TEMPO_0_2S
        BCF     LATA, 1

	; ledv2
        BSF     LATA, 2
        CALL    TEMPO_0_2S
        BCF     LATA, 2

	; ledv3
        BSF     LATA, 3
        CALL    TEMPO_0_2S
        BCF     LATA, 3

        RETURN

;*******************************************************************************
; ROUTINES LEDS RGB (G-->R-->B) (RC1)
;*******************************************************************************

; envoie un bit à 0 avec la bonne temporisation
Bit0:
    BANKSEL LATC
    BSF     LATC, 1        ; [1]
    
    NOP                    ; [2]
    NOP                    ; [3]
    NOP                    ; [4]
    
    BCF     LATC, 1        ; [5] fin HAUT
    
    ; partie BASSE (comblage pour ~1200ns)
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    
    RETURN

; envoie un bit à 1 avec la bonne temporisation
Bit1:
    BANKSEL LATC
    BSF     LATC, 1        ; [1]
    
    NOP                    ; [2]
    NOP                    ; [3]
    NOP                    ; [4]
    NOP                    ; [5]
    NOP                    ; [6]
    NOP                    ; [7]
    NOP                    ; [8]
    NOP                    ; [9]
    
    BCF     LATC, 1        ; [10] fin HAUT

    ; partie BASSE
    NOP
    NOP
    NOP
    NOP
    NOP
    
    RETURN

; envoie un byte (octet) valant b'00100000' = d'32'
; (on ne met pas la valeur max = 255 --> trop brillant) 
; --> "active" une couleur sur UNE rgb (r, g ou b 
; selon le placement dans la routine de send des 24 bits,
; 3 bytes (octets), 1 pour chaque couleur)
ColorOn:
    CALL Bit0
    CALL Bit0
    CALL Bit1
    CALL Bit0
    CALL Bit0
    CALL Bit0
    CALL Bit0
    CALL Bit0
    RETURN

; envoie un byte (octet) valant b'00000000' = d'0'
; --> désactive la couleur donnée sur CETTE rgb
ColorOff:
    CALL Bit0
    CALL Bit0
    CALL Bit0
    CALL Bit0
    CALL Bit0
    CALL Bit0
    CALL Bit0
    CALL Bit0
    RETURN

; rouge pour UNE rgb ...
Red:
    CALL ColorOff ; G
    CALL ColorOn ; R
    CALL ColorOff ; B
    RETURN

Green: ; ... vert ...
    CALL ColorOn
    CALL ColorOff
    CALL ColorOff
    RETURN

Blue: ; ... bleu ...
    CALL ColorOff
    CALL ColorOff
    CALL ColorOn
    RETURN

Yellow: ; ... jaune ...
    CALL ColorOn
    CALL ColorOn
    CALL ColorOff
    RETURN
    
Purple: ; ... violet ...
    CALL ColorOff
    CALL ColorOn
    CALL ColorOn
    RETURN

White: ; ... blanc ...
    CALL ColorOn
    CALL ColorOn
    CALL ColorOn
    RETURN    

RGBLEDOff: ; ... OFF (~noir)
    CALL ColorOff
    CALL ColorOff
    CALL ColorOff
    RETURN    

; allume les 12 rgb en blanc
AllRGBLEDsWhite:
    CALL White
    CALL White
    CALL White
    CALL White
    CALL White
    CALL White
    CALL White
    CALL White
    CALL White
    CALL White
    CALL White
    CALL White
    RETURN

FirstRGBLEDWhite:
    CALL White
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    RETURN
    
; éteint toutes les rgb (~noir PARTOUT)
AllRGBLEDsOff:
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    CALL RGBLEDOff
    RETURN
    
;*******************************************************************************
; ROUTINES BUTTON (RB1 à RB4)
;*******************************************************************************       
    
AwaitButton: ; test si un bouton est pressé
    CALL TEMPO_0_1S
    CALL TEMPO_10MS
    CALL TEMPO_10MS
    CALL TEMPO_10MS
    CALL TEMPO_10MS
    CALL TEMPO_10MS
    
    ButtonPress_4: ; RB4
	BANKSEL PORTB
	BTFSC   PORTB,  4
	GOTO ButtonPress_3
	MOVLW 0x04
	MOVWF lastBtnPressed
	CALL HandleButton_4
	RETURN
	
    ButtonPress_3: ; RB3
        BANKSEL PORTB
	BTFSC   PORTB, 3
	GOTO ButtonPress_2
	MOVLW 0x03
	MOVWF lastBtnPressed
	CALL HandleButton_3
	RETURN
	    
    ButtonPress_2: ; RB2
        BANKSEL PORTB
	BTFSC   PORTB, 2
	    GOTO ButtonPress_1
	    MOVLW 0x02
	    MOVWF lastBtnPressed
	    CALL HandleButton_2
	    RETURN
	    
    ButtonPress_1: ; RB1
        BANKSEL PORTB
	BTFSC   PORTB, 1
	    GOTO ButtonPress_NO
	    MOVLW 0x01
	    MOVWF lastBtnPressed
	    CALL HandleButton_1
	    RETURN    
	
    ButtonPress_NO:
	RETURN

; ----- HANDLE BUTTON 4 (RB4 : MINs (+)) -----
	
HandleButton_4:    
    CALL    IncLEDv
    RETURN

; ----- HANDLE BUTTON 3 (RB3 : Hs (+)) -----
    
HandleButton_3:
    INCF    hoursCounter, F

    MOVLW   d'12'
    CPFSEQ  hoursCounter
    GOTO    H3_OK

    CLRF    hoursCounter    ; 11 -> 0

H3_OK:
    CALL    UpdateRGBDisplay
    RETURN
 
; ----- HANDLE BUTTON 2 (RB2 : Hs (-)) -----   
    
HandleButton_2:
    DECF    hoursCounter, F

    MOVLW   0xFF            ; sous-dépassement ?
    CPFSEQ  hoursCounter
    GOTO    H2_OK

    MOVLW   d'11'           ; 0 -> 11
    MOVWF   hoursCounter

H2_OK:
    CALL    UpdateRGBDisplay
    RETURN
    
; ----- HANDLE BUTTON 1 (RB1 : MINs (-)) -----

HandleButton_1:
    CALL    DecLEDv
    RETURN
    
; ----- ROUTINES GENERALES BUTTONS -----
    
;----------------------------------------
; IncLEDv
; +1 minute
; met à jour :
; - minutesCounter (0..59)
; - hoursCounter   (1..11)
; - ledvCounter    (minutes % 5)
; - LEDs vertes
; - LEDs RGB
;----------------------------------------

IncLEDv:
    INCF    minutesCounter, F

    MOVLW   d'60'
    CPFSEQ  minutesCounter
    GOTO    IncLEDv_NoWrap

    ; wrap minutes
    CLRF    minutesCounter
    INCF    hoursCounter, F

    MOVLW   d'12'
    CPFSEQ  hoursCounter
    GOTO    IncLEDv_NoWrap

    CLRF    hoursCounter ; 11 -> 0

IncLEDv_NoWrap:
    CALL    ComputeLedvCounter
    CALL    UpdateGreenLEDs
    CALL    UpdateRGBDisplay
    RETURN

;----------------------------------------
; DecLEDv
; -1 minute
; met à jour :
; - minutesCounter
; - hoursCounter (optionnel si tu veux plus tard)
; - ledvCounter (minutes % 5)
; - LEDs vertes
; - LEDs RGB
;----------------------------------------

DecLEDv:
    DECF    minutesCounter, F

    MOVLW   0xFF
    CPFSEQ  minutesCounter
    GOTO    DecLEDv_OK

    MOVLW   d'59'
    MOVWF   minutesCounter

    DECF    hoursCounter, F
    MOVLW   0xFF
    CPFSEQ  hoursCounter
    GOTO    DecLEDv_OK

    MOVLW   d'11'
    MOVWF   hoursCounter

DecLEDv_OK:
    CALL    ComputeLedvCounter
    CALL    UpdateGreenLEDs
    CALL    UpdateRGBDisplay
    RETURN

; ----- ROUTINE UPDATE LEDv (RB1 et 4) -----
    
;----------------------------------------
; UpdateGreenLEDs
; affiche ledvCounter (0..4) sur RA0..RA3
;----------------------------------------

UpdateGreenLEDs:
    CALL    TurnOffAllLEDs

    MOVF    ledvCounter, W
    BZ      UGV_End ; 0 ? tout éteint

    ; >= 1
    CALL    TurnOnLD0
    MOVLW   d'1'
    CPFSEQ  ledvCounter
    GOTO    UGV_Chk2
    RETURN

UGV_Chk2:
    ; >= 2
    CALL    TurnOnLD1
    MOVLW   d'2'
    CPFSEQ  ledvCounter
    GOTO    UGV_Chk3
    RETURN

UGV_Chk3:
    ; >= 3
    CALL    TurnOnLD2
    MOVLW   d'3'
    CPFSEQ  ledvCounter
    GOTO    UGV_Chk4
    RETURN

UGV_Chk4:
    ; >= 4
    CALL    TurnOnLD3

UGV_End:
    RETURN   
    
; ----- ROUTINES DISPLAY RGB (RB2 et 3) -----    

;--------------------------------------------------
; UpdateRGBDisplay
; - Heures : rouge (1)
; - Minutes : bleu (2)
; - Heures + minutes : violet (3)
; - Index RGB : 0..11
;--------------------------------------------------

UpdateRGBDisplay:
    ;--------------------------------------------------
    ; clear rgb[0..11]
    ;--------------------------------------------------
    LFSR    0, rgb0
    MOVLW   d'12'
    MOVWF   tempIndex

UR_Clear:
    CLRF    POSTINC0
    DECF    tempIndex, F
    BNZ     UR_Clear

    ;--------------------------------------------------
    ; HEURES --> rouge
    ;--------------------------------------------------
    MOVF    hoursCounter, W
    MOVWF   tempIndex

    MOVLW   d'1'            ; rouge
    MOVWF   temp
    CALL    LoopSetColorIndex

    ;--------------------------------------------------
    ; MINUTES --> bleu / violet
    ;--------------------------------------------------
    CALL    ComputeMinutesIndex
    MOVF    minutesIndex, W
    MOVWF   tempIndex

    LFSR    0, rgb0
    MOVF    tempIndex, W
    ADDWF   FSR0L, F

    MOVF    INDF0, W
    BNZ     UR_Purple

    MOVLW   d'2'            ; bleu
    MOVWF   INDF0
    GOTO    UR_Send

UR_Purple:
    MOVLW   d'3'            ; violet
    MOVWF   INDF0

UR_Send:
    CALL    SendFullBusRGB
    RETURN

    
LoopSetColorIndex:
    ; écrit la couleur "temp" dans rgb[tempIndex]

    LFSR    0, rgb0         ; FSR0 = &rgb0
    MOVF    tempIndex, W    ; W = index
    ADDWF   FSR0L, F        ; FSR0 = &rgb0 + index

    MOVF    temp, W
    MOVWF   INDF0           ; rgb[tempIndex] = temp

    RETURN

    
SendColorForOneRGB:
    MOVF    temp2, W
    BZ      RGB_Off ; 0 -> off

    MOVLW   d'1'
    CPFSEQ  temp2
    GOTO    TestBlue
    CALL    Red
    RETURN

TestBlue:
    MOVLW   d'2'
    CPFSEQ  temp2
    GOTO    TestPurple
    CALL    Blue
    RETURN

TestPurple:
    MOVLW   d'3'
    CPFSEQ  temp2
    GOTO    RGB_Off
    CALL    Purple
    RETURN

RGB_Off:
    CALL    RGBLEDOff
    RETURN

    
SendFullBusRGB:
    LFSR    0, rgb0         ; FSR0 -> début du tableau
    MOVLW   d'12'
    MOVWF   tempIndex       ; compteur de leds

SendFullBusLoop:
    MOVF    POSTINC0, W	    ; W = *FSR0 ; FSR0++
    MOVWF   temp2
    CALL    SendColorForOneRGB

    DECF    tempIndex, F
    BNZ     SendFullBusLoop
    RETURN

;----------------------------------------
; calcule minutesIndex = minutesCounter / 5
; minutesCounter : 0..59
; minutesIndex   : 0..11
; utilise temp
;----------------------------------------

ComputeMinutesIndex:
    MOVF    minutesCounter, W
    MOVWF   temp

    CLRF    minutesIndex

Div5_Loop:
    MOVLW   d'5'
    SUBWF   temp, F
    BNC     Div5_End
    INCF    minutesIndex, F
    GOTO    Div5_Loop

Div5_End:
    RETURN

;----------------------------------------
; calcule ledvCounter = minutesCounter % 5
; résultat : 0..4
; utilise temp
;----------------------------------------

ComputeLedvCounter:
    MOVF    minutesCounter, W
    MOVWF   temp		; temp = minutesCounter

Div5_Loop2:
    MOVLW   d'5'
    SUBWF   temp, F             ; temp -= 5
    BNC     Div5_End2           ; si borrow ? temp < 0
    GOTO    Div5_Loop2

Div5_End2:
    ADDWF   temp, W             ; W = temp + 5 (annule dernier -5)
    MOVWF   ledvCounter         ; ledvCounter = 0..4
    RETURN
    
END