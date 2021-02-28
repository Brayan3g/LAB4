; Documento:	LAB4
; Dispositivo: PIC16F887
; Autor: BRAYAN GABRIEL GIRON GARCIA
; Programa: Contadodor BINARIO UTILIZANDO INTERRUPCION
; Creado: 23 febrereo, 2021
;-------------------------------------------------------------------------------
PROCESSOR 16F887
#include <xc.inc>

; configuración word1
 CONFIG FOSC=INTRC_NOCLKOUT //Oscilador interno sin salidas
 CONFIG WDTE=OFF	    //WDT disabled (reinicio repetitivo del pic)
 CONFIG PWRTE=ON	    //PWRT enabled (espera de 72ms al iniciar
 CONFIG MCLRE=OFF	    //pin MCLR se utiliza como I/O
 CONFIG CP=OFF		    //sin protección de código
 CONFIG CPD=OFF		    //sin protección de datos
 
 CONFIG BOREN=OFF	    //sin reinicio cuando el voltaje baja de 4v
 CONFIG IESO=OFF	    //Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF	    //Cambio de reloj externo a interno en caso de falla
 CONFIG LVP=ON		    //Programación en bajo voltaje permitida
 
;configuración word2
 CONFIG WRT=OFF	//Protección de autoescritura 
 CONFIG BOR4V=BOR40V	//Reinicio abajo de 4V 
 UP	EQU 0           ; ASIGNAR EL VALOR DE "0" A LA VARIABLE UP 
 DOWN	EQU 1           ; ASIGNAR EL VALOR DE "1" A LA VARIABLE DOWN   

 REIN_Tmr0 macro    ; CREAR MACRO reiniciar_Tmr0 PARA IMPLEMENTARLO EN CUALQUIER PARTE DE NUESTRO CODIGO.
    
    banksel TMR0
    movlw   236        ; ASIGNAMOS EL VALOR DE 236 AL TMR0, EL CUAL OBTUBIMOS CON LA FORMULA.
    movwf   TMR0        
    bcf	    T0IF        ; LIMPIAMOS LA BANDERA DEL TMR0
    endm                ; FINALIZAMOS EL MACRO  
    
  PSECT udata_bank0     ; common memory
    cont:	DS  2   ; CREAMOS UNA VARIABLE DE 2 byte apartado
    Display2:	DS  1   ; CREAMOS UNA VARIABLE DE 1 byte apartado
    
  PSECT udata_shr       ; common memory
    w_temp:	DS  1   ; CREAMOS UNA VARIABLE PARA GUARDAR EL VALOR TEMPORAL DE "W",  1 byte apartado
    STATUS_TEMP:DS  1   ; CREAMOS UNA VARIABLE PARA GUARDAR EL VALOR TEMPORAL DEL "STATUS", 1 byte
  
  PSECT resVect, class=CODE, abs, delta=2
  ;----------------------vector reset------------------------
  ORG 00h	        ; posición 000h para el reset
  resetVec:
    PAGESEL main
    goto main
    
  PSECT intVect, class=CODE, abs, delta=2
  
  ;----------------------interripción reset------------------------
  ORG 04h	         ;posición 0004h para interr
  push:
    movf    w_temp       ; GUARDAMOS EL VALOR ACTUAL DE "W" EN LA VARIABLE TEMPORAL w_temp
    swapf   STATUS, W    ; INVERTIMOS EL VALOR DEL ESTATUS Y LO ASIGNAMOS A "W"
    movwf   STATUS_TEMP  ; GUARDAMOS EL VALOR ACTUAL DEL "STATUS INVERTIDO" EN LA VARIABLE TEMPORAL STATUS_TEMP
    
  isr:
    btfsc   T0IF         ; VERIFICAMOS SI LA BANDERA DEL TMR0 ESTA LEVANTADA.
    call    Interr_Tmr0  ; SI LA BANDERA DEL TMR0 ESTA LEVANTADA, LLAMAMOS A SUBRUTINA Interr_Tmr0 
    btfsc   RBIF         ; VERIFICAMOS SI LA BANDERA DE LA INTERUPCION DEL PUERTO ESTA LEVANTA
    call    int_ioCB     ; SI LA BANDERA ESTA LEVANTADA, LLAMAMOS A LA SUBRUTINA int_ioCB 
  
 pop:
    swapf   STATUS_TEMP, W ; INVERTIMOS EL VALOR DEL STATUS_TEMP Y LO ASIGNAMOS A "W" PARA REGRESAR AL VALOR ORIGINAL DEL ESTATUS DE LA INTERUPCION
    movwf   STATUS         ; ASIGNAMOS EL VALOR "W" AL ESTATUS, PARA TENRE EL MISMO VALOR QUE TENIAMOS ANTES DE LA INTERRUPCION 
    swapf   w_temp, F
    swapf   w_temp, W
    retfie

;---------SubrutinasInterrupción-----------
  Interr_Tmr0:
    REIN_Tmr0	       ; LLAMA AL MACRO REIN_Tmr0, 05 ms
    incf    cont        ; INCREMENTAMOS LA VARIABLE cont  
    movf    cont, W     ; ASIGNAMOS EL VALOR DE LA VARIABLE cont A "W"
    sublw   200         ; LE RESTAMOS EL VALOR ACTUAL DEL CONTADOR A 200, para repetir 200 veces los 05 ms y conseguir el tiempo de 1000ms 
    btfss   STATUS, 2	; Bit zero status -> VERIFICAMOS SI LA BANDERA "Z" DEL ESTATUS ESTA LEVANTA
    goto    return_T0	; SI NO ESTA LEVANTADA LLAMA A LA SUBRUTINA return_T0
    clrf    cont	; 500ms -> SI LA BANDERA ESTA LEVANTADA  LIMPIA EL VALOR DE LA VARIABLE cont
    incf    Display2    ; INCREMENTAMOS EL VALOR DE LA VARIABLE Display2 
 
 return_T0:             
    return
    
 int_ioCB:               ; VERIFICACION DE PULSADORES
    banksel PORTB        ; SELECCIONAR EL BANCO DONDE ESTA EL PORTB  
    btfss   PORTB, UP    ; VERIFICAMOS SI EL BOTON DE INCREMENTAR ESTA PRESIONADO
    incf    PORTA        ; SI EL BOTON DE INCREMENTAR ESTA PRESIONADO, INCREMENTA EL PORTA
    btfss   PORTB, DOWN  ; VERIFICAMOS SI EL BOTON DE DECREMENTAR ESTA PRESIONADO
    decf    PORTA        ; SI EL BOTON DE DECREMENTAR ESTA PRESIONADO, DECREMENTA EL PORTA
    bcf	    RBIF         ; LIMPIAMOS LA BANDREA DE LA INTERRUPCION DEL PORTB.    
    return               
    
  PSECT code, delta=2, abs
  ORG 100h	;Posición para el código
;-----------------Tabla-----------------------------
    
Tabla:                       ; TABLA PARA EL DISPLAY1 
    clrf  PCLATH
    bsf   PCLATH,0
    andlw 0x0F
    addwf PCL
    retlw 00111111B          ; 0
    retlw 00000110B          ; 1
    retlw 01011011B          ; 2
    retlw 01001111B          ; 3
    retlw 01100110B          ; 4
    retlw 01101101B          ; 5
    retlw 01111101B          ; 6
    retlw 00000111B          ; 7
    retlw 01111111B          ; 8
    retlw 01101111B          ; 9
    retlw 01110111B          ; A
    retlw 01111100B          ; b
    retlw 00111001B          ; C
    retlw 01011110B          ; d
    retlw 01111001B          ; E
    retlw 01110001B          ; F
  
  ;---------------configuración------------------------------
  main: 
    call    Config_io             ; LLAMAMOS A LA COMFIGURACION DE ENTRADAS Y SALIDAS.
    call    config_reloj          ; LLAMAMOS A LA COMFIGURACION DEL RELOJ INTERNO.
    call    config_tmr0           ; LLAMAMOS A LA COMFIGURACION DEL TMR0.
    call    config_IOChange       ; LLAMAMOS A LA COMFIGURACION config_IOChange.
    call    config_InterrupEnable ; LLAMAMOS A LA COMFIGURACION DE LAS INTERRUPCIONES.
    banksel PORTA                 ; IR AL BANCO 00 
    
;----------loop principal---------------------
 loop: 
    movf    Display2,w            ; ASIGNAR EL VALOR DEL DISPLAY2 A "W"
    call    Tabla                 ; LLAMAMOS LA TABLA DE VALORES DEL DISPLAY
    movwf   PORTD                 ; MOVEMOS EL VALOR QUE NOS REGRESA LA TABLA AL PORTA
    
    movf    PORTA,w               ; MOVEMOS EL VALORE DEL PORTA A "W" 
    call    Tabla                 ; LLAMAMOS LA TABLA DE VALORES DEL DISPLAY
    movwf   PORTC                 ; MOVEMOS EL VALOR QUE NOS REGRESA LA TABLA AL PORTC 
    
    goto    loop                  ; LOOP
    
;------------sub rutinas---------------------
config_IOChange:
    banksel TRISA                 ; NOS DIRIGIMOS AL BANCO 01
    bsf	    IOCB, UP              ; ACTIVAR EL PIN 0 DEL PORTB COMO PULL-UP
    bsf	    IOCB, DOWN            ; ACTIVAR EL PIN 1 DEL PORTB COMO PULL-UP
    
    banksel PORTA                 ; NOS DIRIGIMOS AL BANCO 00
    movf    PORTB, W	          ; MOVER EL VALOR DEL PORTB  "W"
    bcf	    RBIF                  ; LIMPIAMOS LA BANDERA DE LA INTERRUPCION DEL PORTB 
    return                        
    
Config_io:
    banksel ANSEL
    clrf    ANSEL	          ; pines digitales
    clrf    ANSELH
    
    banksel TRISA
    movlw   0xF0
    movwf   TRISA	          ;PORTA A salida
    clrf    TRISD
    clrf    TRISC
    bsf	    TRISB, UP
    bsf	    TRISB, DOWN
    
    bcf	    OPTION_REG,	7   ;RBPU Enable bit - Habilitar
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
    

    banksel PORTA
    clrf    PORTA	    ;Valor incial 0 en puerto A
    clrf    PORTD
    clrf    PORTC
    return
     
 config_tmr0:
    banksel OPTION_REG     ;Banco de registros asociadas al puerto A
    bcf	    T0CS           ; reloj interno clock selection
    bcf	    PSA	           ;Prescaler 
    bsf	    PS2
    bsf	    PS1
    bsf	    PS0	           ;PS = 111 Tiempo en ejecutar , 256
    
    REIN_Tmr0         ;Macro reiniciar tmr0
    return  
    
 config_reloj:
    banksel OSCCON	;Banco OSCCON 
    bsf	    IRCF2	;OSCCON configuración bit2 IRCF
    bsf	    IRCF1	;OSCCON configuracuón bit1 IRCF
    bcf	    IRCF0	;OSCCON configuración bit0 IRCF
    bsf	    SCS		;reloj interno , 4Mhz
    return

config_InterrupEnable:
    bsf	    GIE		;Habilitar en general las interrupciones
    bsf	    T0IE	;Se encuentran en INTCON
    bcf	    T0IF	;Limpiamos bandera
    return
 
end


