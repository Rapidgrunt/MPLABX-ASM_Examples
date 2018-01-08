;**************************** Librería "DS1624.INC" *************************************
;
;	===================================================================
;	  Del libro "MICROCONTROLADOR PIC16F84. DESARROLLO DE PROYECTOS"
;	  E. Palacios, F. Remiro y L. López.		www.pic16f84a.com
; 	  Editorial Ra-Ma.  www.ra-ma.es
;	===================================================================
;
; Estas subrutinas permiten realizar las tareas de manejo del sensor de temperatura 
; DS1624. Este sensor transmite la información vía serie a través de un bus I2C.
;
; ZONA DE DATOS **********************************************************************

	CBLOCK
	DS1624_Temperatura					; Parte entera de la temperatura medida.
	DS1624_Decimal						; Parte decimal de la temperatura medida.
	DS1624_Signo						; Signo de la temperatura medida.
	ENDC

DS1624_DIR_ESCRITURA	EQU	b'10010000'
DS1624_DIR_LECTURA		EQU	b'10010001'

COMANDO_ReadTemperature	EQU	0AAh	; Comandos del DS1624.
COMANDO_StartConvert_T	EQU	0EEh
COMANDO_AccessConfig	EQU	0ACh

; Subrutina "DS1624_RedondeaDecimal" ----------------------------------------------------
;
; Esta subrutina redondea el valor del contenido del registro de trabajo W al valor más cercano
; con un decimal indicado en una tabla.
;
DS1624_RedondeoDecimal
	addwf	PCL,F	
	retlw	d'0'	; (DS1624_Decimal)=b'0000'. Mide 0,0000ºC. Redondeado a 0,0ºC.
	retlw	d'1'	; (DS1624_Decimal)=b'0001'. Mide 0,0625ºC. Redondeado a 0,1ºC.
	retlw	d'1'	; (DS1624_Decimal)=b'0010'. Mide 0,1250ºC. Redondeado a 0,1ºC.
	retlw	d'2'	; (DS1624_Decimal)=b'0011'. Mide 0,1875ºC. Redondeado a 0,2ºC.
	retlw	d'3'	; (DS1624_Decimal)=b'0100'. Mide 0,2500ºC. Redondeado a 0,3ºC.
	retlw	d'3'	; (DS1624_Decimal)=b'0101'. Mide 0,3125ºC. Redondeado a 0,3ºC.	
	retlw	d'4'	; (DS1624_Decimal)=b'0110'. Mide 0,3750ºC. Redondeado a 0,4ºC.
	retlw	d'4'	; (DS1624_Decimal)=b'0111'. Mide 0,4375ºC. Redondeado a 0,4ºC.
	retlw	d'5'	; (DS1624_Decimal)=b'1000'. Mide 0,5000ºC. Redondeado a 0,5ºC.
	retlw	d'6'	; (DS1624_Decimal)=b'1001'. Mide 0,5625ºC. Redondeado a 0,6ºC.
	retlw	d'6'	; (DS1624_Decimal)=b'1010'. Mide 0,6250ºC. Redondeado a 0,6ºC.
	retlw	d'7'	; (DS1624_Decimal)=b'1011'. Mide 0,6875ºC. Redondeado a 0,7ºC.	
	retlw	d'8'	; (DS1624_Decimal)=b'1100'. Mide 0,7500ºC. Redondeado a 0,8ºC.
	retlw	d'8'	; (DS1624_Decimal)=b'1101'. Mide 0,8125ºC. Redondeado a 0,8ºC.
	retlw	d'9'	; (DS1624_Decimal)=b'1110'. Mide 0,8750ºC. Redondeado a 0,9ºC.
	retlw	d'9'	; (DS1624_Decimal)=b'1111'. Mide 0,9375ºC. Redondeado a 0,9ºC.
DS1624_FinTablaRedondeo

	IF (DS1624_FinTablaRedondeo > 0xFF)
		ERROR	"¡CUIDADO!: La tabla ha superado el tamaño de la página de los"
		MESSG	"primeros 256 bytes de memoria ROM. NO funcionará correctamente."
	ENDIF

; Subrutina "DS1624_Inicializa" ---------------------------------------------------------
;
; Configura el DS1624 para que trabaje en modo One-Shot.

DS1624_Inicializa
	call	I2C_EnviaStart
	movlw	DS1624_DIR_ESCRITURA		; Apunta al dispositivo.
	call	I2C_EnviaByte
	movlw	COMANDO_AccessConfig		; Comando indicando que el próximo byte es la
	call	I2C_EnviaByte				; palabra de control.
	movlw	b'01001011'					; Carga la palabra de control para modo One-Shot.
	call	I2C_EnviaByte
	call	I2C_EnviaStop
;	call	DS1624_IniciaConversion		; Inicia la conversión de temperatura.
;	return

; Subrutina "DS1624_IniciaConversion" ---------------------------------------------------------
;
; Inicializa el DS1624 para que comience la conversión de temperatura.
;
DS1624_IniciaConversion
	call	I2C_EnviaStart				; Configura el DS1624.
	movlw	DS1624_DIR_ESCRITURA		; Apunta al dispositivo.
	call	I2C_EnviaByte
	movlw	COMANDO_StartConvert_T		; Comando que ordena el comienzo de la conversión 
	call	I2C_EnviaByte				; de la temperatura.
	call	I2C_EnviaStop
	return

; Subrutina "DS1624_LeeTemperatura" -----------------------------------------------------
;
; El DS1624 lee la temperatura en un formato ejemplificado como sigue:
;
; +125.0000 ºC	01111101 00000000
; + 25.0625 ºC	00011001 00010000
; +  0.5000 ºC	00000000 10000000
; +  0.0000 ºC	00000000 00000000
; -  0.5000 ºC	11111111 10000000
; - 25.0625 ºC	11100110 11110000
; - 55.0000 ºC	11001001 00000000
;
; Se observa que:
;    -	El formato es de dos bytes. El primer byte es la parte entera y el segundo la 
;		parte decimal.
;    -	Las temperaturas vienen dadas en complemento a 2.
;    -	Las temperaturas positivas comienzan con el bit MSB a cero: b'0xxxxxxx xxxxxxxx'.
;    -	Las temperaturas negativas comienzan con e1 bit MSB a uno:  b'1xxxxxxx xxxxxxxx'.
;
; Esta subrutina lee la temperatura, proporcionando tres datos: 
; Salida:	- En (DS1624_Temperatura) la parte entera del valor de la temperatura medida.
;			- En (DS1624_Decimal) la parte decimal del valor de la temperatura.
;			- En (DS1624_Signo)=b'11111111' si la temperatura es negativa y 
;		  	  (DS1624_Signo)=b'00000000' si es positiva.
;
DS1624_LeeTemperatura
	bcf		I2C_UltimoByteLeer
	call	I2C_EnviaStart
	movlw	DS1624_DIR_ESCRITURA		; Apunta al dispositivo.
	call	I2C_EnviaByte
	movlw	COMANDO_ReadTemperature		; Comando de lectura de la temperatura.
	call	I2C_EnviaByte
	call	I2C_EnviaStart				; Comienza a leer.
	movlw	DS1624_DIR_LECTURA			; Apunta al dispositivo.
	call	I2C_EnviaByte
	call	I2C_LeeByte					; Lee el primer byte
	movwf	DS1624_Temperatura			; y lo guarda.
	bsf		I2C_UltimoByteLeer			; El próximo es el último byte a leer.
	call	I2C_LeeByte					; Lee el segundo byte
	movwf	DS1624_Decimal				; y lo guarda.
	call	I2C_EnviaStop
;
; Ahora deduce si la temperatura es positiva o negativa y halla su valor absoluto.
;
	clrf	DS1624_Signo				; Supone que la temperatura es positiva.
	btfss	DS1624_Temperatura,7		; Si el bit MSB es "1", la temperatura es negativa.
	goto	DS1624_FinLeeTemperatura	; La temperatura es positiva y salta.
DS1624_TemperaturaNegativa
	comf	DS1624_Signo,F				; Indica que la temperatura es negativa.
	comf	DS1624_Decimal,F			; Para hallar el valor absoluto de la
	comf	DS1624_Temperatura,F		; temperatura invierte los dos registros y le
	movlw	.1							; suma una unidad.
	addwf	DS1624_Decimal,F
	btfsc	STATUS,C					; Si hay acarreo tiene que llevarlo al byte superior.
	incf	DS1624_Temperatura,F		; Le suma 1.
DS1624_FinLeeTemperatura		
	swapf	DS1624_Decimal,W			; Para las temperaturas es suficiente trabajar
	andlw	b'00001111'					; con un solo digito decimal, por lo que
	call	DS1624_RedondeoDecimal		; primero se queda con los 4 bits menos 
	movwf	DS1624_Decimal				; significativo y pasa a redondear su valor.
	movf	DS1624_Temperatura,W		; En (W) la parte entera del valor absoluto de la
	return								; temperatura.
	
;	===================================================================
;	  Del libro "MICROCONTROLADOR PIC16F84. DESARROLLO DE PROYECTOS"
;	  E. Palacios, F. Remiro y L. López.		www.pic16f84a.com
; 	  Editorial Ra-Ma.  www.ra-ma.es
;	===================================================================
