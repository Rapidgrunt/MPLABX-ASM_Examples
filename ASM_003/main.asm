;*******************************************************************************
;*
;*                ASM_003: Control de display de 7 segmentos
;*
;*******************************************************************************
;* FileName:        main.asm
;* Processor:       PIC16F84A
;* Complier:        MPASM v5.55
;* Author:          Pedro Sánchez (MrChunckuee)
;* Blog:            http://mrchunckuee.blogspot.com/
;* Email:           mrchunckuee.psr@gmail.com
;* Description:     Controlar un display de 7 segmetos conectado en PORTB
;*                  Conteo de + 1 cada que se pulsa el boton conectado en RA0
;*                  Oscilador XT=4MHz
;*******************************************************************************
;* Rev.         Date            Comment
;*   v1.00      12/06/2015      Creación del firmware
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
Boton               EQU     0       ; Definimos Led como RB0
ContadorDisplay     EQU     0x0C    ; Registro para almacenar conteo
RContadorA          EQU     0x0D    ; Registro utilizado para el retardo
RContadorB          EQU     0x0E    ; Registro utilizado para el retardo

;********** I N I C I O * D E * P R O G R A M A ********************************
RESET   org     0x00	; Aqui comienza el micro despues del reset
        goto	Inicio	; Salto a la etiqueta Inicio

;********** T A B L A * 7 S E G M E N T O S ************************************
; Tabla con valores para display de 7 segmentos
; Se coloca al inicio para asegurar ubicacion en Pagina
        org	0x05            ; Origen del codigo de la tabla
TABLA7SEG:                  ; retlw b'gfedcba'  para display catodo comun
    addwf	PCL,1           ; Se incrementa el contador del programa
	retlw	b'0111111'      ; 0
	retlw	b'0000110'      ; 1
	retlw	b'1011011'      ; 2
	retlw	b'1001111'      ; 3
	retlw	b'1100110'      ; 4
	retlw	b'1101101'      ; 5
	retlw	b'1111101'      ; 6
	retlw	b'0000111'      ; 7
	retlw	b'1111111'      ; 8
	retlw	b'1101111'      ; 9
	clrf	ContadorDisplay ; Si llega 10, se resetea contador
	retlw	b'0111111'      ; 0

;********** C O N F I G * P U E R T O S ****************************************
; Se configuran entradas y salidas, se inicializan variables y puertos
Inicio
    bsf     STATUS,RP0      ; Pasamos de Banco 0 a Banco 1
	movlw	b'00000000'     ; Cargamos b'00000000' en W
	movwf	TRISB           ; Cargamos W en TRISB, PORTB como salida
    movlw	b'00001'        ; Cargamos b'00001' en W
	movwf	TRISA           ; Cargamos W en TRISA, RA0 como entrada
	bcf     STATUS,RP0      ; Paso del Banco 1 al Banco 0
    movlw	b'0111111'      ; Cargamos b'0111111' en W
	movwf	PORTB           ; Cargamos W en PORTB, Comienza el display en 0
	clrf	ContadorDisplay ; Contador inicia en 0

;********** R U T I N A * T E S T E O ******************************************
Testeo
	btfss	PORTA,Boton         ; Esta pulsado el Boton (RA0=1??)
	goto	Testeo              ; No??, seguimos testeando
	call	Retardo_20ms        ; Si??, Eliminamos efecto rebote
	btfss	PORTA,Boton         ; Testeamos nuevamente
	goto	Testeo              ; Falsa Alarma, seguimos testeando
	incf	ContadorDisplay,1   ; Se ha pulsado, incrementamos ContadorDisplay
	movfw	ContadorDisplay     ; Pasamos ContadorDisplay a W
	call	TABLA7SEG           ; Llamamos tabla
	movwf	PORTB               ; Cargamos valor recibido en PORTB
	btfsc	PORTA,Boton         ; Boton se dejo de pulsar??
	goto	$-1                 ; No??, PCL - 1, --> btfsc PORTA,Boton
	call    Retardo_20ms		; Si??, Eliminamos efecto rebote
	btfsc	PORTA,Boton         ; Testeamos nuevamente si se dejo de pulsar
	goto	$-4                 ; No??, Falsa alarma, volvemos a checar
    goto	Testeo              ; Si??, Testeamos nuevamente si se ha pulsado

;********** C O D I G O * R E T A R D O S **************************************
; Considerando Fosc=4MHz, ciclo maquina (cm) = 1uS
; Se tiene que para Retardo_20ms = 2 + 1 + 2 + (2 + 4M + 4KM) donde K=249 y M=20
; Retardo = 20007 us = 20 ms

Retardo_20ms                        ; 2 ciclo máquina
	movlw	d'20'                   ; 1 ciclo máquina. Este es el valor de "M"
	goto    Retardo_ms              ; 2 ciclo máquina.

; Las siguientes lineas duran
; Retardo = 1 + M + M + KM + (K-1)M + 2M + (K-1)2M + (M-1) + 2 + 2(M-1) + 2
; Retardo = 2 + 4M + 4KM para K=249 y suponiendo M=1 tenemos
; Retardo = 1002 us = 1 ms
Retardo_ms
	movwf	RContadorB              ; 1 ciclos máquina.
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

	end ;Fin del codigo


