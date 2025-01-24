; Autor: Sofia Victoria Bispo da Silva
; Matricula : 202063542
; Materia : Eletronica Embarcada 

;   --- TEST POINT 4 ---  1 PARTE- 
    ; Configura��o inicial do PIC
    CONFIG FOSC = INTRC_NOCLKOUT   ; Oscilador interno sem sa�da de clock
    CONFIG WDTE = ON              ; Watchdog habilitado
    CONFIG MCLRE = ON             ; Master Clear habilitado
    CONFIG LVP = OFF              ; Baixa tens�o de programa��o desabilitada
    
#include <xc.inc>             ; Arquivo com defini��es do microcontrolador

global i 		; Vari�vel para contagem de atrasos
psect udata_shr
i:
    DS 1


psect resetVec,class=CODE,delta=2   ; Vetor de Reset definido em xc.inc para os PIC10/12/16
resetVec:
    PAGESEL start		    ; Seleciona p�gina de c�digo de programa onde est� start
    goto start 

psect code,class=CODE,delta=2	    ; Define uma sec��o o de c�digo de programa 
;---------inicializa��o do codigo
start:

 ; -------- Configura��o do OSCCON --------
    BANKSEL OSCCON                ; Selecionar o banco do registrador OSCCON
    MOVLW 0b01110110              ; = 4 MHz
    MOVWF OSCCON                  ; Aplica configura��o no OSCCON
;--------configura as portas 
    BANKSEL ANSEL               ; Seleciona o banco de mem�ria do registrador ANSEL
    clrf ANSELH                 ; Zera ANSELH para usar todas as portas como digitais
    clrf ANSEL                  ; Zera ANSEL para usar todas as portas como digitais
	
    BANKSEL WDTCON
    movlw   0b00001111 		; Habilita WDT, Prescaler 1:128 (~500ms)
    movwf   WDTCON 
		
    BANKSEL TRISA
    BCF TRISA, 0 		; Configura RA0 como sa�da (LED vermelho)
    BCF TRISA, 1 		; Configura RA1 como sa�da (LED verde)
    ;BCF TRISA, 2
	
    BANKSEL OPTION_REG         ; Selecionar o registrador OPTION_REG
    movlw 0b00000110           ; PSA = 1, PS2:PS0 = 100 (Prescaler 1:128)
    movwf OPTION_REG           ; Configurar o OPTION_REG
    BANKSEL TMR0 
    clrf TMR0		    ; Zera o registrador TMR0
	
	
    BANKSEL PORTA               ; Seleciona o banco de mem�ria do registrador PORTA
    movlw 0xFF			; Carrega 0xFF (11111111 em bin�rio) no registrador W
    movwf PORTA      		; Configura todos os bits de PORTA como entrada
    bsf INTCON, 5		; Habilita interrup��es globais
   
loop:
    clrwdt				; Limpa o Watchdog Timer
    Bcf PORTA, 2			; Desliga LED
    ;piscar led vermelho 
    BSF PORTA, 0 			; Liga LED vermelho (RA0)
    call delay_500ms			; Chama a fun��o de delay de 500 ms
    bcf PORTA,0 			; Desliga LED vermelho
    call baixo_consumo			; Entra em modo de baixo consumo
	
	; Piscar LED verde
    BSF PORTA, 1               ; Liga LED verde (RA1)
    CALL delay_500ms           ; Atraso de 500ms
    BCF PORTA, 1               ; Desliga LED verde
    call baixo_consumo		; Entra em modo de baixo consumo

    goto loop 			; Repete o loop


;---- CONFIGURA�AO DELAY
delay_500ms:
    movlw 12 ;valor incial do contador 
    movlw i 
delay_loop:
    clrwdt
    movlw 193 ; Valor inicial do Timer0 (~4ms)
    movwf TMR0      ; Configura Timer0
    bcf INTCON, 2   ; Limpa a flag de estouro
	
timer_wait:
    btfss INTCON, 2 ;Verifica o TMR0 
    goto timer_wait		; Aguarda at� o Timer0 estourar
    bcf INTCON, 2 		;; Limpa a flag de overflow
	
    decfsz i, f 		; Decrementa 'i', se n�o zero repete o loop
    goto delay_loop 		; Repete o delay
	
    return

	
;-----MODO DE BAIXO CONSUMO 
baixo_consumo:
    clrwdt		; Limpa o Watchdog Timer para reiniciar a contagem
    bcf   INTCON, 5		; Desabilita as interrup��es globais
    sleep 		; Coloca o microcontrolador em modo de baixo consumo
    clrwdt 
    bsf INTCON, 5	; Desabilita as interrup��es globais
    RETURN 



