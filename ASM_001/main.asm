;*******************************************************************************
;*
;*                ASM_001: Encender LED con boton
;*
;*******************************************************************************
;* FileName:        main.asm
;* Processor:       PIC16F84A
;* Complier:        MPASM v5.55
;* Author:          Pedro Sánchez (MrChunckuee)
;* Blog:            http://mrchunckuee.blogspot.com/
;* Email:           mrchunckuee.psr@gmail.com
;* Description:     Encender un LED conectado en RB0 al pulsar el boton en RA0
;*                  Oscilador XT=4MHz
;*******************************************************************************
;* Rev.         Date            Comment
;*   v1.00      27/05/2015      Creación del firmware
;*******************************************************************************

;********** C A B E C E R A ****************************************************
list p=16F84A           ;Identifica el PIC a usar
#include <P16F84A.INC>  ;Libreria del PIC

;********** F U S E S **********************************************************
;   _CP_OFF     Se desactiva proteccion de codigo
;   _WDT_OFF    Se desactiva el Watchdog Timer
;   _PWRTE_ON   Se activa el Power-Up Timer
;   _XT_OSC     Se usa oscilador externo XT
__CONFIG   _CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC

;********** V A R I A B L E S **************************************************
Led		EQU     0	; Definimos Led como el bit cero de un registro, en este caso PORTB
Boton	EQU     0	; Definimos Boton como el bit 0, en este caso para PORTA

;********** C O N F I G * P U E R T O S ****************************************
RESET   org     0x00	; Aqui comienza el micro despues del reset
        goto	Inicio	; Salto a la etiqueta Inicio
        org	    0x05    ; Origen del codigo de programa

Inicio	
    bsf     STATUS,RP0 	; Pasamos de Banco 0 a Banco 1
	movlw	b'11111'	; Cargamos 11111 a W
	movwf	TRISA		; Cargamos W en TRISA para ser entradas
	movlw	b'11111110' ; Cargamos 11111110 a W
	movwf	TRISB       ; Cargamos W en TRISB, RB0 como salida
	bcf     STATUS,RP0	; Paso del Banco 1 al Banco 0
	bcf     PORTB,Led	; Comienza con el LED apagado

;********** C O D I G O * P R I N C I P A L ************************************
Bucle
    btfss	PORTA,Boton	; Preguntamos si esta pulsado (1 Logico)
	goto	ApagarLED   ; Si esta en 0 logico, Apagamos Led
	bsf     PORTB,Led	; Si esta en 1 logico, Encendemos Led
	goto	Bucle		; Testeamos nuevamente la condicion del Boton

ApagarLED
    bcf     PORTB,Led	; Encendemos Led
	goto	Bucle		; Testeamos nuevamente la condicion del Boton

	end
