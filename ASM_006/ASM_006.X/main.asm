;*******************************************************************************
;*
;*                ASM_006: Control basico del ADC
;*
;*******************************************************************************
;* FileName:        main.asm
;* Processor:       PIC16F887
;* Complier:        MPASM v5.77
;* Author:          Pedro Sánchez (MrChunckuee)
;* Blog:            http://mrchunckuee.blogspot.com/
;* Email:           mrchunckuee.psr@gmail.com
;* Description:     Controlar los 8 LEDs en el puerto D, dependiendo del nivel 
;*		    de voltaje en RA0.
;*******************************************************************************
;* Rev.         Date            Comment
;*  v1.00	15/06/2015      Creación del firmware
;*  v1.01	11/10/2019	Pruebas y revision del codigo, ademas se agrego 
;*				los comentario en las lineas.
;*******************************************************************************

;********** C A B E C E R A ****************************************************
list p=16f887		;Identifica el PIC a usar
#include <P16F887.INC>	;Cabecera que define los registros del MCU

;********** F U S E S **********************************************************
;   Bits de configuración del MCU
; CONFIG1
__CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_OFF
; CONFIG2
__CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
;********** V A R I A B L E S **************************************************
 ;Declaracion de constantes
RContadorA  EQU	    0x0D    ; Registro utilizado para el retardo
RContadorB  EQU     0x0E    ; Registro utilizado para el retardo
;Declaracion de datos en memoria
MisVariables UDATA
Valor_ADC   RES	    1   ; Guarda el resultado de la conversion
 
;********** I N I C I O * D E * P R O G R A M A ********************************
ORG     0x00	    ; Aqui comienza el micro despues del reset
GOTO	MCU_Init    ; Configuramos el ADC
ORG	0x04	    ; Origen del codigo de programa
RETURN
	
;********** C O N F I G U R A * M C U ******************************************
MCU_Init
    BANKSEL ANSEL 
    MOVLW   0x01  
    MOVWF   ANSEL   ; use AN0
    BANKSEL OSCCON
    movlw   0x71    ;Cargo valor a w 
    movwf   OSCCON  ;Oscilador interno 8MHz --> IRCF<2:0> = 1, CCS = 1
    BANKSEL TRISD        
    MOVLW   0x00  
    MOVWF   TRISD   ;all PORTD outputs
    BANKSEL PORTD 
    CLRF    PORTD   ;Clear PORTD

;********** C O N F I G U R A * A D C ******************************************
ADC_Init
    ;Se inicializa el registro ADCON1 del ADC
    BANKSEL ADCON1
    movlw   0x0E    ;Configura los canales para usar solo RA0/AN0 y
    movwf   ADCON1  ;selecciona la justificacion a la izquierda
    BANKSEL TRISA
    movlw   0x01 
    movwf   TRISA   ;Se coloca RA0 como entrada (analoga).
    BANKSEL PORTA   ;Selecciona el banco 0 nuevamente
    clrf    PORTA   ;Clear PORTA
    ;Se inicaliza ahora el registro ADCON0 del ADC. Notese que se usa
    ;el reloj interno del ADC debido a que la velocidad no es critica y
    ;la aplicacion no requiere exactitud en la velocidad de conversion.
    BANKSEL ADCON0
    movlw   0xC1	; Selecciona el reloj interno, selecciona tambien el
    movwf   ADCON0	; Canal cero del ADC (AN0) y activa el ADC.
    ;Nota: en caso de usar varios canales, puede modificarse este registro
    ;para intercambiarlos.
    clrf    Valor_ADC	;Limpia la variable

;********** L E C T U R A  *  A D C ********************************************
ADC_Read
    bsf	    ADCON0, GO_DONE	; Inicia la conversion del ADC
    movlw   d'1'		; Espera durante 1ms
    call    Retardo_ms
    btfsc   ADCON0, GO_DONE	; Espera a que la conversion termine por
    goto    $-1			; medio de verificar el mismo bit
    movf    ADRESH, W		; Toma el resultado del ADC y lo guarda
    movwf   Valor_ADC
    ;Nota: Dado que se utilizo la justificacion a la izquierda, se pueden
    ;tomar solo los 8 bits mas significativos y usarlos como resultado.
    ;Esto puede realizarse si solo se necesitan 8 bits de resolucion y no
    ;los 10 que provee el ADC.

;********** R U T I N A  *  L E D s ********************************************
; Cargamos un valor a W.
; Le restamos al ADC el valor de W.
; Comparamos si es <= ejecutamos siguiente linea, si > saltamos una linea.
; Actualizamos PORTD.
; REalizamos nuevamente una lectura.
    
Update_LED0
    movlw   d'28'
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,C
    GOTO    Update_LED1
    MOVLW   b'00000000'
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED1
    movlw   d'56'
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,C
    GOTO    Update_LED2
    MOVLW   b'00000001'
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED2
    movlw   d'84'
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,C
    GOTO    Update_LED3
    MOVLW   b'00000011'
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED3
    movlw   d'112'
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,C
    GOTO    Update_LED4
    MOVLW   b'00000111'
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED4
    movlw   d'140'
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,C
    GOTO    Update_LED5
    MOVLW   b'00001111'
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0
    
Update_LED5
    movlw   d'168'
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,C
    GOTO    Update_LED6
    MOVLW   b'00011111'
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED6
    movlw   d'196'
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,C
    GOTO    Update_LED7
    MOVLW   b'00111111'
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED7
    movlw   d'224'
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,C
    GOTO    Update_LED8
    MOVLW   b'01111111'
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

Update_LED8
    movlw   d'250'
    SUBWF   Valor_ADC,W
    BTFSC   STATUS,C
    GOTO    ADC_Read	; Volvemos a leer RA0
    MOVLW   b'11111111'
    MOVWF   PORTD
    GOTO    ADC_Read	; Volvemos a leer RA0

;********** C O D I G O * R E T A R D O S **************************************
; Las siguientes lineas duran
; Retardo = 1 + M + M + KM + (K-1)M + 2M + (K-1)2M + (M-1) + 2 + 2(M-1) + 2
; Retardo = 2 + 4M + 4KM para K=249 y suponiendo M=1 tenemos
; Retardo = 1002 us = 1 ms
Retardo_ms
	movwf	RContadorB		; 1 ciclos máquina.
Retardo_BucleExterno
	movlw	d'249'                  ; Mx1 ciclos máquina. Este es el valor de "K".
	movwf	RContadorA              ; Mx1 ciclos máquina.
Retardo_BucleInterno
	nop                             ; KxMx1 ciclos máquina.
	decfsz	RContadorA,F            ; (K-1)xMx1 cm (si no salta) + Mx2 cm (al saltar).
	goto	Retardo_BucleInterno    ; (K-1)xMx2 ciclos máquina.
	decfsz	RContadorB,F            ; (M-1)x1 cm (si no salta) + 2 cm (al saltar).
	goto	Retardo_BucleExterno	; (M-1)x2 ciclos máquina.
	return                          ; 2 ciclos máquina.
 
end ;Fin del programa
