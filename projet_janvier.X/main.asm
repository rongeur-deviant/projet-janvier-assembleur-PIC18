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
  
var	UDATA_ACS
lastBtnPressed	    RES	    1 ; dernier bouton pressé
ledCounter          RES     1 ; compteur de leds (0 à 4)

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

ConfigPWM:
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
    
    CLRF ledCounter ; compteur = 0 au démarrage

;*******************************************************************************
; BOUCLE PRINCIPALE (main loop)
;*******************************************************************************
    
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
    MOVWF   T0CON0, ACCESS	    ; timer1 clock Sosc
    
    MOVLW   B'10010000'	
    MOVWF   T0CON1, ACCESS	    ; set les valeurs du registre T0CON1
    
    ; initialiser la valeur du timer à 33536
    MOVLW   0x86
    MOVWF   TMR0H		    ; maj TMR0H
    MOVLW   0xE8		    ; maj TMR0L
    MOVWF   TMR0L
    
TEMPO_1S_RUN:    
    BTFSS   T0CON0, 5, ACCESS	    ; tester l'overflow du timer
    GOTO    TEMPO_1S_RUN
    BCF	    T0CON0, 7, ACCESS	    ; reset bit de démarrage
    RETURN


TEMPO_0_5S:
    
    MOVLW   B'10010000'		    
    MOVWF   T0CON0, ACCESS	    ; timer1 clock Sosc
    
    MOVLW   B'10010000'	
    MOVWF   T0CON1, ACCESS	    ; set les valeurs du registre T0CON1
    
    ; initialiser la valeur du timer à 50036
    MOVLW   0xC3
    MOVWF   TMR0H		    ; maj TMR0H
    MOVLW   0x74		    ; maj TMR0L
    MOVWF   TMR0L
    
TEMPO_0_5S_RUN:    
    BTFSS   T0CON0, 5, ACCESS	    ; tester l'overflow du timer
    GOTO    TEMPO_0_5S_RUN  
    BCF	    T0CON0, 7, ACCESS	    ; reset bit de démarrage
    RETURN
   
    
TEMPO_0_2S:
    
    MOVLW   B'10010000'		    
    MOVWF   T0CON0, ACCESS	    ; timer1 clock Sosc
    
    MOVLW   B'10010000'	
    MOVWF   T0CON1, ACCESS	    ; set les valeurs du registre T0CON1
    
    ; initialiser la valeur du timer à 58036
    MOVLW   0xE2
    MOVWF   TMR0H		    ; maj TMR0H
    MOVLW   0xB4		    ; maj TMR0L
    MOVWF   TMR0L
    
TEMPO_0_2S_RUN:    
    BTFSS   T0CON0, 5, ACCESS	    ; tester l'overflow du timer
    GOTO    TEMPO_0_2S_RUN
    BCF	    T0CON0, 7, ACCESS	    ; reset bit de démarrage
    RETURN


TEMPO_100US:
    
    MOVLW   B'10010000'		    
    MOVWF   T0CON0, ACCESS	    ; timer1 clock Sosc
    
    MOVLW   B'10010000'	
    MOVWF   T0CON1, ACCESS	    ; set les valeurs du registre T0CON1
    
    ; initialiser la valeur du timer à 65532
    MOVLW   0xFF
    MOVWF   TMR0H		    ; maj TMR0H
    MOVLW   0xFC		    ; maj TMR0L
    MOVWF   TMR0L
    
TEMPO_100US_RUN:    
    BTFSS   T0CON0, 5, ACCESS	    ; tester l'overflow du timer
    GOTO    TEMPO_100US_RUN
    BCF	    T0CON0, 7, ACCESS	    ; reset bit de démarrage
    RETURN   


TEMPO_10MS:
    
    MOVLW   B'10010000'		    
    MOVWF   T0CON0, ACCESS	    ; timer1 clock Sosc
    
    MOVLW   B'10010000'	
    MOVWF   T0CON1, ACCESS	    ; set les valeurs du registre T0CON1
    
    ; initialiser la valeur du timer à 65226
    MOVLW   0xFE
    MOVWF   TMR0H		    ; maj TMR0H
    MOVLW   0xCA		    ; maj TMR0L
    MOVWF   TMR0L
    
TEMPO_10MS_RUN:    
    BTFSS   T0CON0, 5, ACCESS	    ; tester l'overflow du timer
    GOTO    TEMPO_10MS_RUN
    BCF	    T0CON0, 7, ACCESS	    ; reset bit de démarrage
    RETURN


TEMPO_20MS:
    
    MOVLW   B'10010000'		    
    MOVWF   T0CON0, ACCESS	    ; timer1 clock Sosc
    
    MOVLW   B'10010000'	
    MOVWF   T0CON1, ACCESS	    ; set les valeurs du registre T0CON1
    
    ; initialiser la valeur du timer à 64916
    MOVLW   0xFD
    MOVWF   TMR0H		    ; maj TMR0H
    MOVLW   0x94		    ; maj TMR0L
    MOVWF   TMR0L
    
TEMPO_20MS_RUN:    
    BTFSS   T0CON0, 5, ACCESS	    ; tester l'overflow du timer
    GOTO    TEMPO_20MS_RUN
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

LEDv_blink: ; fait blinker les 4 leds vertes en série (serpent)
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
    
AwaitButton:
    CALL TEMPO_0_2S
    BANKSEL PORTB
    BTFSC   PORTB,  4
	GOTO ButtonPress_3
	MOVLW 0x04
	MOVWF lastBtnPressed
	CALL HandleButton_4
	RETURN
	
    ButtonPress_3:
        BANKSEL PORTB
	BTFSC   PORTB, 3
	    GOTO ButtonPress_2
	    MOVLW 0x03
	    MOVWF lastBtnPressed
	    ; ajouter le call à l'handle BTN3
	    RETURN
	    
    ButtonPress_2:
        BANKSEL PORTB
	BTFSC   PORTB, 2
	    GOTO ButtonPress_1
	    MOVLW 0x02
	    MOVWF lastBtnPressed
	    ; ajouter le call à l'handle BTN2
	    RETURN
	    
    ButtonPress_1:
        BANKSEL PORTB
	BTFSC   PORTB, 1
	    GOTO ButtonPress_NO
	    MOVLW 0x01
	    MOVWF lastBtnPressed
	    ; ajouter le call à l'handle BTN1
	    RETURN    
	
    ButtonPress_NO:
	RETURN
    
HandleButton_4:    
    ; --- compteur == 0 ? ---
    MOVF    ledCounter, W
    BZ      Led0

    ; --- compteur == 1 ? ---
    MOVLW   1
    CPFSEQ  ledCounter
    GOTO    Test2
    CALL    TurnOnLD1
    CALL    IncCounter
    RETURN

Test2:
    ; --- compteur == 2 ? ---
    MOVLW   2
    CPFSEQ  ledCounter
    GOTO    Test3
    CALL    TurnOnLD2
    CALL    IncCounter
    RETURN

Test3:
    ; --- compteur == 3 ? ---
    MOVLW   3
    CPFSEQ  ledCounter
    GOTO    Test4
    CALL    TurnOnLD3
    CALL    IncCounter
    RETURN


Test4:
    ; --- compteur == 4 ? ---
    MOVLW   4
    CPFSLT  ledCounter
    GOTO    EndHandle ; sécurité
    RETURN

Led0:
    CALL    TurnOnLD0
    CALL    IncCounter
    RETURN
    
IncCounter:
    INCF    ledCounter, F
    RETURN 
    
EndHandle:
    CLRF    ledCounter ; sécurité
    CALL    TurnOffAllLEDs
    RETURN
    
END