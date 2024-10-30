; Autor: Sofia Victoria Bispo da Silva
; Matricula : 202063542
; Materia : Eletronica Embarcada 

;  --- TEST POINT 1 ---

#include <xc.inc>

global count	                    ; Vari�vel global count
PSECT udata_shr			    ; localizada na zona espelhada da mem�ria de dados 
count:
    DS 1			    ; reserva uma localiza��o de mem�ria (1 byte) para count 
    
psect resetVec,class=CODE,delta=2   ; Vetor de Reset definido em xc.inc para os PIC10/12/16
resetVec:
    PAGESEL start		    ; Seleciona p�gina de c�digo de programa onde est� start
    goto start 

psect code,class=CODE,delta=2	    ; Define uma sec��o o de c�digo de programa 

;inicializa as portas
start:
    BANKSEL PORTA		;Sele��o do banco de mem�ria do registrador PORTA
    clrf PORTA			;Zera PORTA, para quando as sa�das sejam configuradas os pinos fiquem em zero
    clrf PORTB			;Limpa PORTB
    clrf PORTC			;Limpa PORTC

    BANKSEL TRISA               ; Sele��o do banco de mem�ria do registrador TRISA
    clrf    TRISA               ; Configura TRISA como saida
    bsf	    TRISA,5		;Configura o pino RA5 como entrada 
    
    BANKSEL TRISB               ; Seleciona o banco de mem�ria do registrador TRISB
    movlw 0xFF			; Carrega 0xFF (11111111 em bin�rio) no registrador W
    movwf TRISB      		; Configura todos os bits de PORTB como entrada

    BANKSEL TRISC               ; Seleciona o banco de mem�ria do registrador TRISC
    movlw 0xFF			; Carrega 0xFF (11111111 em bin�rio) no registrador W
    movwf TRISC      		; Configura todos os bits de PORTC como entrada
    
    BANKSEL ANSEL               ; Seleciona o banco de mem�ria do registrador ANSELA
    clrf ANSELH                 ; Zera ANSELA para usar todas as portas como digitais
    clrf ANSEL                  ; Zera ANSELH para usar todas as portas como digitais
    
    BANKSEL PORTA

verificaRA5:
    clrwdt  			;Zera Can de Guarda (Watchdog Timer)
    movf PORTA,w		;Move PORTA para W
    btfsc PORTA,5		; Verifica o valor do pino RA5
    goto soma    	 	;Se RA5=1, realiza soma
    goto subtracao		; Se RA5=0, realiza subtra��o
	
soma:
    movf PORTB, w		;Move PORTB para W
    addwf PORTC,w		; W= PORTB + PORTC  somo o valor de PORTC com o conte�do atual de W
    movwf PORTA			;armazena o resultado na PORTA	
    goto verificaRA5		;Volta para verificar RA5 novamente
	

subtracao:
    movf PORTC, w		;Move PORTC para W
    subwf PORTB, w		; W= PORTB - PORTC
    movwf PORTA			;movo o valor de W para PORTA para que o resultado da subtra��o seja exibido
    goto verificaRA5		;Volta para verificar RA5 novamente