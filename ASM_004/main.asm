;*******************************************************************************
;*
;*	    ASM_004: Termometro con DS1624
;*
;*******************************************************************************
;* FileName:        main.asm
;* Processor:       PIC16F84A
;* Complier:        MPASM v5.73
;* Author:          Pedro Sánchez (MrChunckuee)
;* Blog:            http://mrchunckuee.blogspot.com/
;* Email:           mrchunckuee.psr@gmail.com
;* Description:     Programa de control para un termómetro digital con el sensor 
;* 		    de temperatura DS1624.
;*******************************************************************************
;* Rev.         Date            Comment
;*  v0.00	28/05/2010      Prueba del firmware
;*  v0.01	07/01/2018	Se compilo con MPLAB X y MPASM v5.73
;*******************************************************************************

	
;******************************* I2C_Termometro_01.asm *******************************
;
;	===================================================================
;	  Del libro "MICROCONTROLADOR PIC16F84. DESARROLLO DE PROYECTOS"
;	  E. Palacios, F. Remiro y L. López.		www.pic16f84a.com
; 	  Editorial Ra-Ma.  www.ra-ma.es
;	===================================================================
;
; Programa de control para un termómetro digital con el sensor de temperatura DS1624.
;
	
; ZONA DE DATOS **********************************************************************

	LIST		P=16F84A
	INCLUDE		<P16F84A.INC>
	__CONFIG	_CP_OFF &  _WDT_OFF & _PWRTE_ON & _XT_OSC

	CBLOCK   0x0C
	Registro50ms	; Guarda los incrementos cada 50 ms.
	ENDC

TMR0_Carga50ms	EQU	d'256'-d'195'	; Para conseguir interrupción cada 50 ms.
CARGA_2s		EQU	d'40'	; Leerá cada 2s = 40 x 50ms = 2000ms.

; ZONA DE CÓDIGOS ********************************************************************

	ORG 	0
	goto	Inicio
	ORG	4
	goto	ServicioInterrupcion

Mensajes
	addwf	PCL,F
MensajePublicitario
	DT "    Ing. Electronica", 0x00
MensajeGradoCentigrado
	DT "ºC TESCHA", 0x00	; En la pantalla: "ºC  "

Inicio
	call	DS1624_Inicializa	; Configura el DS1624 e inicia la conversión.
	call	LCD_Inicializa
	bsf		STATUS,RP0
	movlw	b'00000111'		; Preescaler de 256 para el TMR0.
	movwf	OPTION_REG
	bcf		STATUS,RP0
	movlw	MensajePublicitario	; Visualiza un mensaje publicitario en la primera
	call	LCD_Mensaje		; línea del LCD.
	movlw	TMR0_Carga50ms		; Carga el TMR0 en complemento a 2.
	movwf	TMR0
	movlw	CARGA_2s		; Y el registro cuyo decremento consigue los 2 s.
	movwf	Registro50ms
	movlw	b'10100000'		; Activa interrupción del TMR0 (T0IE)
	movwf	INTCON			; la general (GIE).
Principal
	goto	Principal

; Subrutina "ServicioInterrupcion" ------------------------------------------------------
;
; Detecta qué ha producido la interrupción y ejecuta la subrutina de atención correspondiente.

ServicioInterrupcion
	btfsc	INTCON,T0IF
	call	Termometro
	bcf		INTCON,T0IF
	retfie

; Subrutina "Termometro" ----------------------------------------------------------------
;
; Esta subrutina lee y visualiza el termómetro cada 2 segundos aproximadamente.
; Se ejecuta debido a la petición de interrupción del Timer 0, cada 50 ms.
; Para conseguir una temporización de 2 s habrá que repetir 40 veces el lazo de
; 50 ms (40x50ms = 2000ms = 2s).
;
Termometro
	movlw	TMR0_Carga50ms
	movwf	TMR0					; Recarga el TMR0.
	decfsz	Registro50ms,F			; Decrementa el contador.
	goto	Fin_Termometro			; No han pasado 2 segundos y por tanto sale.
	movlw	CARGA_2s				; Repone el contador nuevamente.
	movwf	Registro50ms
	call	DS1624_LeeTemperatura	; Lee la temperatura.
	call	DS1624_IniciaConversion	; Comienza conversión para la siguiente lectura.
	call	VisualizaTermometro
Fin_Termometro
	return

; Subrutina "VisualizaTermometro" -----------------------------------------------------------------
;
; Visualiza la temperatura en la segunda línea de la pantalla LCD.
;
; Entradas:
;		- (DS1624_Temperatura), temperatura medida en valor absoluto.
;		- (DS1624_Decimal), parte decimal de la temperatura medida.
;		- (DS1624_Signo), indica signo de la temperatura.

VisualizaTermometro
	movlw	.5						; Se coloca para centrar visualización en la
	call	LCD_PosicionLinea2		; segunda línea.
	btfss	DS1624_Signo,7			; ¿Temperatura negativa?.
	goto	TemperaturaPositiva		; No, la temperatura es positiva.
TemperaturaNegativa:
	movlw 	'-'						; Visualiza el signo "-" de temperatura negativa.
	call	LCD_Caracter
TemperaturaPositiva
	movf	DS1624_Temperatura,W	; Visualiza el valor absoluto de la temperatura,
	call	BIN_a_BCD				; pasándola previamente a BCD.
	call	LCD_Byte				; Visualiza apagando el cero no significativo.
	movlw	'.'						; Visualiza el punto decimal.
	call	LCD_Caracter
	movf	DS1624_Decimal,W		; Visualiza la parte decimal.
	call	LCD_Nibble
	movlw	MensajeGradoCentigrado	; En pantalla aparece "ºC  ".
	call	LCD_Mensaje
	return

	INCLUDE  <BUS_I2C.INC>
	INCLUDE  <DS1624.INC>	
	INCLUDE  <RETARDOS.INC>
	INCLUDE  <BIN_BCD.INC>
	INCLUDE  <LCD_4BIT.INC>
	INCLUDE  <LCD_MENS.INC>
	END
	
;	===================================================================
;	  Del libro "MICROCONTROLADOR PIC16F84. DESARROLLO DE PROYECTOS"
;	  E. Palacios, F. Remiro y L. López.		www.pic16f84a.com
; 	  Editorial Ra-Ma.  www.ra-ma.es
;	===================================================================
