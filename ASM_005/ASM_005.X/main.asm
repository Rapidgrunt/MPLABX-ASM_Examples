;*******************************************************************************
;*
;*   ASM_005: Led intermitente - Uso del oscilador interno en el PIC16F887
;*
;*******************************************************************************
;* FileName:        main.asm
;* Processor:       PIC16F887
;* Complier:        MPASM v5.77
;* Author:          Pedro Sánchez (MrChunckuee)
;* Blog:            http://mrchunckuee.blogspot.com/
;* Email:           mrchunckuee.psr@gmail.com
;* Description:     LED intermitente en RD0 cada 0.5 segundos, se uso el 
;*		    oscilador interno a 8MHz 
;*******************************************************************************
;* Rev.         Date            Comment
;*  v0.0.0	15/03/2019      Creación del firmware
;*******************************************************************************

;********** C A B E C E R A ****************************************************
list p=16f887		;Identifica el PIC a usar
#include <P16F887.INC>	;Cabecera que define los registros del MCU

;********** F U S E S **********************************************************
;   Bits de configuración del MCU
; CONFIG1
__CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
; CONFIG2
__CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
 
;********** V A R I A B L E S **************************************************
 ;Declaracion de constantes
ContadorA   EQU     0x20    ; Seleccionamos posicion de la RAM y guardamos
                            ; ContadorA usado para el retardo
                            ; 0x20 es donde inicia la SRAM del PIC
ContadorB   EQU     0x21    ; Guardamos ContadorB usado para el retardo
ContadorC   EQU     0x22    ; Guardamos ContadorC usado para el retardo
Led         EQU     0       ; Definimos RD0 como Led

;********** I N I C I O * D E * P R O G R A M A ********************************
RESET   ORG     0x00	    ; Aqui comienza el micro despues del reset
        GOTO	MCU_Init    ; Configuramos el ADC
	ORG	0x05	    ; Origen del programa, para evita vector de interrupcion

;********** C O F I G U R A * M C U ********************************************
MCU_Init
    bsf	    STATUS, RP0	    ;Se selecciona el banco 1
    movlw   0x71	    ;Cargo valor a w 
    movwf   OSCCON	    ;Oscilador interno 8MHz --> IRCF<2:0> = 1, CCS = 1
    clrf    TRISD	    ;Todo el puerto D se establece como salidas
    bcf	    STATUS, RP0	    ;Selecciona el banco 0 nuevamente
    clrf    PORTD	    ;Se limpia el puerto D
    
;********** C O D I G O * P R I N C I P A L ************************************
Loop
    bsf     PORTD,Led	; Encendemos Led
    call    Retardo_500ms
    bcf     PORTD,Led	; Apagamos Led
    call    Retardo_500ms
    goto    Loop	; Regresamos para repetir tareas
   
;********** C O D I G O * R E T A R D O S **************************************
; Considerando Fosc=8MHz, ciclo maquina (cm) = 0.5uS
; Time = 2 + 1 + 1 + N + N + MN + MN + KMN + (K-1)MN + 2MN + 2(K-1)MN + (M-1)N
;        + 2N + (M-1)2N + (N-1) + 2 + 2(N-1) + 2
; Time = (5 + 4N + 4MN + 4KM) ciclos máquina. Para K=249, M=100 y N=10
; Time = 5 + 40 + 4000 + 996000 ciclos maquina
; Time = 1000045 * 0.5uS = 0.5 segundos

Retardo_500ms				; 2 ciclo máquina
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
 
end ;Fin del programa