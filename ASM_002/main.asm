;*******************************************************************************
;*
;*                ASM_002: LED Intermitente
;*
;*******************************************************************************
;* FileName:        main.asm
;* Processor:       PIC16F84A
;* Complier:        MPASM v5.55
;* Author:          Pedro Sánchez (MrChunckuee)
;* Blog:            http://mrchunckuee.blogspot.com/
;* Email:           mrchunckuee.psr@gmail.com
;* Description:     Cambiar el estado del LED conectado en RB0 cada 1 segundo
;*                  Oscilador XT=4MHz
;*******************************************************************************
;* Rev.         Date            Comment
;*   v1.00      08/06/2015      Creación del firmware
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
ContadorA   EQU     0x0C    ; Seleccionamos posicion de la RAM y guardamos
                            ; ContadorA usado para el retardo
                            ; 0x0C es donde inicia la SRAM del PIC
ContadorB   EQU     0x0D    ; Guardamos ContadorB usado para el retardo
ContadorC   EQU     0x0E    ; Guardamos ContadorC usado para el retardo
Led         EQU     0       ; Definimos Led como RB0

;********** C O N F I G * P U E R T O S ****************************************
RESET   org     0x00	; Aqui comienza el micro despues del reset
        goto	Inicio	; Salto a la etiqueta Inicio
        org	    0x05    ; Origen del codigo de programa
Inicio	
    bsf     STATUS,RP0 	; Pasamos de Banco 0 a Banco 1
	movlw	b'11111110' ; Cargamos 11111110 a W
	movwf	TRISB       ; Cargamos W en TRISB, RB0 como salida
	bcf     STATUS,RP0	; Paso del Banco 1 al Banco 0
	bcf     PORTB,Led	; Comienza con el LED apagado

;********** C O D I G O * P R I N C I P A L ************************************
Bucle
	bsf     PORTB,Led	; Encendemos Led
    call    Retardo_1s
    bcf     PORTB,Led	; Apagamos Led
    call    Retardo_1s
    goto    Bucle       ; Regresamos para repetir tareas

;********** C O D I G O * R E T A R D O S **************************************
; Considerando Fosc=4MHz, ciclo maquina (cm) = 1uS
; Time = 2 + 1 + 1 + N + N + MN + MN + KMN + (K-1)MN + 2MN + 2(K-1)MN + (M-1)N
;        + 2N + (M-1)2N + (N-1) + 2 + 2(N-1) + 2
; Time = (5 + 4M + 4MN + 4KM) ciclos máquina. Para K=249, M=100 y N=10
; Time = 5 + 40 + 4000 + 996000 ciclos maquina
; Time = 1000045 uS = 1 segundo

Retardo_1s                          ; 2 ciclo máquina
	movlw	d'10'                   ; 1 ciclo máquina. Este es el valor de "N"
	movwf	ContadorC               ; 1 ciclo máquina.
Retardo_BucleExterno2
	movlw	d'100'                  ; Nx1 ciclos máquina. Este es el valor de "M".
	movwf	ContadorB               ; Nx1 ciclos máquina.
Retardo_BucleExterno
	movlw	d'249'                  ; MxNx1 ciclos máquina. Este es el valor de "K".
	movwf	ContadorA               ; MxNx1 ciclos máquina.
Retardo_BucleInterno
	nop                             ; KxMxNx1 ciclos máquina.
	decfsz	ContadorA,F             ; (K-1)xMxNx1 cm (si no salta) + MxNx2 cm (al saltar).
	goto	Retardo_BucleInterno    ; (K-1)xMxNx2 ciclos máquina.
	decfsz	ContadorB,F             ; (M-1)xNx1 cm (si no salta) + Nx2 cm (al saltar).
	goto	Retardo_BucleExterno	; (M-1)xNx2 ciclos máquina.
	decfsz	ContadorC,F             ; (N-1)x1 cm (si no salta) + 2 cm (al saltar).
	goto	Retardo_BucleExterno2	; (N-1)x2 ciclos máquina.
	return                          ; 2 ciclos máquina.

	end //Fin del codigo
