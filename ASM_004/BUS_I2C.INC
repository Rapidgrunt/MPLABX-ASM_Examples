;**************************** Librería "BUS_I2C.INC" ************************************
;
;	===================================================================
;	  Del libro "MICROCONTROLADOR PIC16F84. DESARROLLO DE PROYECTOS"
;	  E. Palacios, F. Remiro y L. López.		www.pic16f84a.com
; 	  Editorial Ra-Ma.  www.ra-ma.es
;	===================================================================
;
; Estas subrutinas permiten realizar las tareas básicas de control del bus serie I2C, 
; por parte de un solo microcontrolador maestro.
;
; ZONA DE DATOS **********************************************************************
;
	CBLOCK
	I2C_ContadorBits				; Cuenta los bits a transmitir o a recibir.
	I2C_Dato						; Dato a transmitir o recibido.
	I2C_Flags						; Guarda la información del estado del bus I2C.
	ENDC

#DEFINE I2C_UltimoByteLeer	I2C_Flags,0
;    -  (I2C_UltimoByteLeer)=0, NO es el último byte a leer por el maestro.
;    -  (I2C_UltimoByteLeer)=1, SÍ es el último byte a leer por el maestro.

; La definición de las líneas SCL y SDA del bus I2C se puede cambiar según las
; necesidades del hardware.

#DEFINE SCL	PORTA,3					; Línea SCL del bus I2C.
#DEFINE SDA	PORTA,4					; Línea SDA del bus I2C.
;
; Subrutina "SDA_Bajo" ------------------------------------------------------------------
;
SDA_Bajo
	bsf		STATUS,RP0				; Configura la línea SDA como salida.
	bcf		SDA
	bcf		STATUS,RP0
	bcf		SDA						; SDA en bajo.
	return
;
; Subrutina "SDA_AltaImpedancia" --------------------------------------------------------
;
SDA_AltaImpedancia
	bsf		STATUS,RP0				; Configura la línea SDA entrada.
	bsf		SDA						; Lo pone en alta impedancia y, gracias a la
	bcf		STATUS,RP0				; Rp de esta línea, se mantiene a nivel alto.
	return
;
; Subrutina "SCL_Bajo" ------------------------------------------------------------------
;
SCL_Bajo
	bsf		STATUS,RP0
	bcf		SCL						; Configura la línea SCL como salida.
	bcf		STATUS,RP0
	bcf		SCL						; La línea de reloj SCL en bajo.
	return
;
; Subrutina "SCL_AltaImpedancia" --------------------------------------------------------
;
SCL_AltaImpedancia
	bsf		STATUS,RP0				; Configura la línea SCL entrada.
	bsf		SCL						; Lo pone en alta impedancia y, gracias a la Rp
	bcf		STATUS,RP0				; de esta línea, se mantiene a nivel alto.
SCL_EsperaNivelAlto
	btfss	SCL						; Si algún esclavo mantiene esta línea en bajo
	goto	SCL_EsperaNivelAlto		; hay que esperar.
	return
;
; Subrutina "I2C_EnviaStart" ------------------------------------------------------------
;
; Esta subrutina envía una condición de Start o inicio.
;
I2C_EnviaStart
	call	SDA_AltaImpedancia		; Línea SDA en alto.
	call	SCL_AltaImpedancia		; Línea SCL en alto.
	call	Retardo_4micros			; Tiempo tBUF del protocolo.
	call	SDA_Bajo				; Flanco de bajada de SDA mientras SCL está alto.
	call	Retardo_4micros			; Tiempo tHD;STA del protocolo.
	call	SCL_Bajo				; Flanco de bajada del reloj SCL.
	call	Retardo_4micros	
	return
;
; Subrutina "I2C_EnviaStop" -------------------------------------------------------------
;
; Esta subrutina envía un condición de Stop o parada.
;
I2C_EnviaStop
	call	SDA_Bajo
	call	SCL_AltaImpedancia		; Flanco de subida de SCL.
	call	Retardo_4micros			; Tiempo tSU;STO del protocolo.
	call	SDA_AltaImpedancia		; Flanco de subida de SDA.
	call	Retardo_4micros			; Tiempo tBUF del protocolo.
	return
;
; Subrutina "I2C_EnviaByte" -------------------------------------------------------------
;
; El microcontrolador maestro transmite un byte por el bus I2C, comenzando por el bit
; MSB. El byte a transmitir debe estar cargado previamente en el registro de trabajo W.
; De la subrutina ejecutada anteriormente I2C_EnviaStart o esta misma I2C_EnviaByte, 
; la línea SCL se debe encontrar a nivel bajo al menos durante 5 µs.
;
I2C_EnviaByte
	movwf	I2C_Dato				; Almacena el byte a transmitir.
	movlw	0x08					; A transmitir 8 bits.
	movwf	I2C_ContadorBits
I2C_EnviaBit
	rlf		I2C_Dato,F				; Chequea el bit, llevándolo previamente al Carry.
	btfsc	STATUS,C
	goto	I2C_EnviaUno
I2C_EnviaCero
	call	SDA_Bajo				; Si es "0" envía un nivel bajo.
	goto	I2C_FlancoSCL
I2C_EnviaUno
	call	SDA_AltaImpedancia		; Si es "1" lo activará a alto.
I2C_FlancoSCL
	call	SCL_AltaImpedancia		; Flanco de subida del SCL.
	call	Retardo_4micros			; Tiempo tHIGH del protocolo.
	call	SCL_Bajo				; Termina el semiperiodo positivo del reloj.
	call	Retardo_4micros			; Tiempo tHD;DAT del protocolo.
	decfsz	I2C_ContadorBits,F		; Lazo para los ocho bits.
	goto	I2C_EnviaBit
;
	call	SDA_AltaImpedancia		; Libera la línea de datos.
	call	SCL_AltaImpedancia		; Pulso en alto de reloj para que el esclavo
	call	Retardo_4micros			; pueda enviar el bit ACK.
	call	SCL_Bajo
	call	Retardo_4micros
	return
;
; Subrutina "I2C_LeeByte" ---------------------------------------------------------------
;
; El microcontrolador maestro lee un byte desde el esclavo conectado al bus I2C. El dato
; recibido se carga en el registro I2C_Dato y lo envía a la subrutina superior a través
; del registro W. Se empieza a leer por el bit de mayor peso MSB.
; De alguna de las subrutinas ejecutadas anteriormente I2C_EnviaStart, I2C_EnviaByte
; o esta misma I2C_LeeByte, la línea SCL lleva en bajo al menos 5 µs.

I2C_LeeByte
	movlw	0x08					; A recibir 8 bits.
	movwf	I2C_ContadorBits
	call	SDA_AltaImpedancia		; Deja libre la línea de datos.
I2C_LeeBit
	call	SCL_AltaImpedancia		; Flanco de subida del reloj.
	bcf		STATUS,C				; En principio supone que es "0".
	btfsc	SDA						; Lee el bit
	bsf		STATUS,C				; Si es "1" carga 1 en el Carry.
	rlf		I2C_Dato,F				; Lo introduce en el registro.
	call	SCL_Bajo				; Termina el semiperiodo positivo del reloj.
	call	Retardo_4micros			; Tiempo tHD;DAT del protocolo.
	decfsz	I2C_ContadorBits,F		; Lazo para los 8 bits.
	goto	I2C_LeeBit
;
; Chequea si este es el último byte a leer para enviar o no el bit de reconocimiento
; ACK en consecuencia.
;
	btfss 	I2C_UltimoByteLeer		; Si es el último, no debe enviar
									; el bit de reconocimiento ACK.
	call	SDA_Bajo				; Envía el bit de reconocimiento ACK
									; porque todavía no es el último byte a leer.
	call	SCL_AltaImpedancia		; Pulso en alto del SCL para transmitir el
	call	Retardo_4micros			; bit ACK de reconocimiento. Este es tHIGH.
	call	SCL_Bajo				; Pulso de bajada del SCL.
	call	Retardo_4micros
	movf	I2C_Dato,W				; El resultado se manda en el registro de
	return							; de trabajo W.
	
;	===================================================================
;	  Del libro "MICROCONTROLADOR PIC16F84. DESARROLLO DE PROYECTOS"
;	  E. Palacios, F. Remiro y L. López.		www.pic16f84a.com
; 	  Editorial Ra-Ma.  www.ra-ma.es
;	===================================================================
