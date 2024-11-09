; Autor: Sofia Victoria Bispo da Silva
; Matricula : 202063542
; Materia : Eletronica Embarcada 

;  Sofia --- TEST POINT 2 --- PARTE 1 ----

CONFIG FOSC = INTRC_NOCLKOUT ; Configura o oscilador interno sem saída de clock

#include <xc.inc>

global opA      ; Variáveis globais (resultados da multiplicação)

PSECT udata_shr      ; Definindo a seção de dados para as variáveis
opA:
    DS 1              ; Reservar 1 byte para o valor de 'a' (PORTB)
	
global opB	
PSECT udata_shr
opB:
    DS 1              ; Reservar 1 byte para o valor de 'b' (PORTD)
	
global resultLSB
PSECT udata_shr
resultLSB:
    DS 1              ; Reservar 1 bytes para o resultado de 8 bits (PORTA e PORTC)
	
global resultMSB
PSECT udata_shr
resultMSB:
    DS 1              ; Reservar 1 bytes para o resultado de 8 bits (PORTA e PORTC)

    
psect resetVec,class=CODE,delta=2   ; Vetor de Reset definido em xc.inc para os PIC10/12/16
resetVec:
    PAGESEL start		    ; Seleciona página de código de programa onde está start
    goto start 

psect code,class=CODE,delta=2	    ; Define uma secção o de código de programa 

;inicialização do codigo
start:
;configura as portas 
    BANKSEL PORTA				;Seleção do banco de memória do registrador PORTA
    clrf PORTA					;Zera PORTA, para quando as saídas sejam configuradas os pinos fiquem em zero
    clrf PORTB					;Limpa PORTB
    clrf PORTC					;Limpa PORTC
    clrf PORTD					;Limpa PORTD
	
    BANKSEL ANSEL               ; Seleciona o banco de memória do registrador ANSEL
    clrf ANSELH                 ; Zera ANSELA para usar todas as portas como digitais
    clrf ANSEL                  ; Zera ANSELH para usar todas as portas como digitais

    BANKSEL TRISA               ; Seleção do banco de memória do registrador TRISA
    movlw 0x00	                ; Configura TRISA como saida para o byte menos significativo (LSB) (0x00 significa todos os bits como 0)
    movwf TRISA				;Escreve 0x00 em TRISA, configurando todos os pinos de PORTA como saídas
   
    
    BANKSEL TRISB               ; Seleciona o banco de memória do registrador TRISB
    movlw 0xFF					; Carrega 0xFF (11111111 em binário) no registrador W
    movwf TRISB      			; Configura todos os bits de PORTB como entrada

    BANKSEL TRISC               ; Seleciona o banco de memória do registrador TRISC
    movlw 0x00                  ; Configura TRISC como saida para o byte mais significativo (MSB) do resultado
    movwf TRISC				;Escreve 0x00 em TRISC, configurando todos os pinos de PORTA como saídas
	
    BANKSEL TRISD               ; Seleção do banco de memória do registrador TRISD 
    movlw 0xFF					; Carrega 0xFF (11111111 em binário) no registrador W
    movwf TRISD      			; Configura todos os bits de PORTD como entrada
    
   ;Leitura dos operandos
leitura_variaveis:
    BANKSEL PORTB
    movf PORTB, W          ; Move o valor de PORTB para W
    movwf opA              ; Armazena em opA (operando A)
    BANKSEL PORTD
    movf PORTD, W          ; Move o valor de PORTD para W	
    movwf opB              ; Armazena em opB (operando B)
	
;Inicializa o resultado como zero
    clrf resultLSB			;Limpa C (16bits) (PORTA e PORTC)
    clrf resultMSB
	
;Multiplicação por Somas Sucessivas
multipli:
    ;clrwdt  			;Zera Can de Guarda (Watchdog Timer)
    movf opB, W 		;
    btfsc STATUS, 0 	;se opB == 0, finaliza a multiplicação
    goto resultados		; vai para exibiçao de resultado
	
	
    movf opA, W 		;carrega opA em W 
    addwf resultLSB, F 	;soma opA ao acumulador LSB
    movf  resultLSB, W 
    btfsc STATUS, 0		;Verifica o carry
    incf  resultMSB, F  ; Incrementa o acumulador MSB se houver carry 

;carry 
    decf opB, F         ; Decrementa opB (número de somas restantes)
    goto multipli       ; Continua o loop de multiplicação
	

    
  
;Exibiçao dos resultados
resultados:
    movf resultLSB, W 	;Copia o LSB do resultado para W
    movwf PORTA			;Envia o LSB (byte menos significativo) para PORTA
    clrf resultLSB
	
    movf resultMSB, W 	; Copia o MSB do resultado para W
    movwf PORTC			;Envia o MSB (byte mais significativo) para PORTC
    clrf resultMSB
    
    goto leitura_variaveis
	

