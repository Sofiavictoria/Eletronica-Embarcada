; Autor: Sofia Victoria Bispo da Silva
; Matricula : 202063542
; Materia : Eletronica Embarcada 

;   --- TEST POINT 3 ---  Certo- 

CONFIG FOSC = INTRC_NOCLKOUT ; Configura o oscilador interno sem saída de clock

#include <xc.inc>
;--- DEFINIÇÃO DE VARIAVEIS ---
global numerador      ; Variáveis globais (resultados da multiplicação)

PSECT udata_shr      ; Definindo a seção de dados para as variáveis
numerador:
    DS 1              ; Reservar 1 byte para o valor de 'a' (PORTB)
	
global denominador	
PSECT udata_shr
denominador:
    DS 1              ; Reservar 1 byte para o valor de 'b' (PORTD)
	
global result_quociente
PSECT udata_shr
result_quociente:
    DS 1              ; Reservar 1 bytes para o resultado de 8 bits (PORTA)
	
global result_resto
PSECT udata_shr
result_resto:
    DS 1              ; Reservar 1 bytes para o resultado de 8 bits (PORTC)
	
global i
PSECT udata_shr
i:
    DS 1              ; Reservando 1 byte para o contador de iterações

;--- VETOR DE RESET ---
psect resetVec,class=CODE,delta=2   ; Vetor de Reset definido em xc.inc para os PIC10/12/16
resetVec:
    PAGESEL start		    ; Seleciona página de código de programa onde está start
    goto start 

psect code,class=CODE,delta=2	    ; Define uma secção o de código de programa 
 
;---INICIO DO PROGRAMA ---
start:
;--- CONFIGURAÇÃO DAS PORTAS --- 
    BANKSEL PORTA		;Seleção do banco de memória do registrador PORTA
    clrf PORTA			;Zera PORTA, para quando as saídas sejam configuradas os pinos fiquem em zero
    clrf PORTB			;Limpa PORTB
    clrf PORTC			;Limpa PORTC
    clrf PORTD			;Limpa PORTD
    clrf PORTE			;Limpa PORTE
	
    BANKSEL ANSEL               ; Seleciona o banco de memória do registrador ANSEL
    clrf ANSELH                 ; Zera ANSELA para usar todas as portas como digitais
    clrf ANSEL                  ; Zera ANSELH para usar todas as portas como digitais
	
    BANKSEL OPTION_REG		;Seleciona o OPTION_REG	
    BCF	OPTION_REG, 7		;Ativa os pull-ups de PORTB
	
 ;--- CONFIGURANDO PORTAS COMO ENTRADAS E SAÍDAS ---
    ;Configura PORTA e PORTC como saídas
    BANKSEL TRISA               ; Seleção do banco de memória do registrador TRISA
    movlw 0x00	                ; Configura TRISA como saida para o byte menos significativo (LSB) (0x00 significa todos os bits como 0)
    movwf TRISA			;Escreve 0x00 em TRISA, configurando todos os pinos de PORTA como saídas
    
    BANKSEL TRISC               ; Seleciona o banco de memória do registrador TRISC
    movlw 0x00                  ; Configura TRISC como saida para o byte mais significativo (MSB) do resultado
    movwf TRISC			;Escreve 0x00 em TRISC, configurando todos os pinos de PORTA como saídas
  
    ;configurando PORTB e PORTD como entradas   
    BANKSEL TRISB               ; Seleciona o banco de memória do registrador TRISB
    movlw 0xFF			; Carrega 0xFF (11111111 em binário) no registrador W
    movwf TRISB      		; Configura todos os bits de PORTB como entrada

    BANKSEL TRISD               ; Seleção do banco de memória do registrador TRISD 
    movlw 0xFF			; Carrega 0xFF (11111111 em binário) no registrador W
    movwf TRISD      		; Configura todos os bits de PORTD como entrada

    ;Configura RE0 como entrada para seleção de algoritmo
    BANKSEL TRISE
    bsf TRISE, 0            ; Configura RE0 como entrada 
    
;---LOOP PRINCIPAL ---	   
;Leitura dos operandos 
leitura_variaveis:

    clrwdt  			;Zera Can de Guarda (Watchdog Timer)
    clrf PORTA 
    clrf PORTC
    BANKSEL PORTB	    ;
    movf PORTB, W           ;Move o valor de PORTB para W
    movwf numerador         ;Armazena em numerador
    BANKSEL PORTD
    movf PORTD, W           ;Move o valor de PORTD para W	
    movwf denominador       ;Armazena em denominador

	
;Inicializa o resultado como zero
    clrf result_quociente		;Limpa o resultado quociente
    clrf result_resto			;Limpa o resultado resto
    

;--- VERIFICAÇÃO DO DENOMINADOR 
verifica_denominador: 
    movf denominador, W	    ;Carrega o denominador
    btfsc STATUS, 2	    ; verifica se o denominador é igual a Zero 
    goto zero_case	    ;caso o denominador seja zero, vai para o zero_case 


;--- SELEÇÃO DO MÉTODO DE DIVISÃO ---
escolhe_metodo:
    BANKSEL PORTE
    movf PORTE,W	    ; Lê o estado do pino RE0
    btfsc PORTE, 0	    ; Verifica se o pino RE0 = 1
    call divisao_deslocamento ; Se o pino RE0 for 1 (HIGH), vai para  divisao por deslocamento
    call divisao_sub_sucessivas	    ; Se o pino RE0 for 0(LOW), vai para  divisao por subtração sucessivas
	
; --- DIVISÃO POR SUBTRAÇÕES SUCESSIVAS ---
divisao_sub_sucessivas:
    movf numerador, W 
    movwf result_resto      ;Resto = numerador 	
divisao:
    movf denominador, W 
    subwf result_resto, W   ;result_resto = result_resto - W  ; Subtrai o denominador do resto
    btfss STATUS, 0	    ;Verifica se houve overflow (resto negativo)
    goto resultados
    movwf result_resto	    ; Atualiza o resto
    incf result_quociente, F ;Incrementa  quociente 
    goto divisao	    ;Repete o processo

; --- DIVISÃO POR DESLOCAMENTO ---
divisao_deslocamento:
    movlw 0x08		; Define o número de bits para deslocar
    movwf i		;Armazena o valor 0x08 no registrador i (contador de bits)
loop_deslocamento:
    BCF STATUS, 0	;C=0 Limpa o carry
    RLF numerador,F	;Desloca o conteúdo do registrador 'numerador' para a esquerda (rola o bit)
    RLF result_resto, F ;Desloca o conteúdo do registrador 'result_resto' para a esquerda (rola o bit)
    movf denominador, W ;Move o valor do 'denominador' para o registrador W
    subwf result_resto, W ;result_resto = result_resto - W  ; Subtrai o valor de 'result_resto' do valor de 'denominador'
    btfsc STATUS, 0 	; Verifica o carry (C=0 se den > resto)
    movwf result_resto  ; Atualiza o resto
    RLF result_quociente, F ; Desloca o quociente à esquerda
    decfsz i, F		    ;Decrementa o contador de bits 
    goto loop_deslocamento  ; Repete o loop se i ? 0
    goto resultados	    ; Exibe os resultados
	
; --- TRATAMENTO PARA DENOMINADOR ZERO ---	
zero_case:		    ; Quando Q=0 o valor do resto = Numerador. Ligando o LED RE1 
    clrf result_quociente   ; Quociente = 0
    movf numerador, W	    ; Numerador = W 
    movwf result_resto	    ; W = resto 
    bsf PORTE, 1	    ;acende o LED indicado erro
    goto leitura_variaveis

; --- EXIBIÇÃO DOS RESULTADOS ---
resultados:
    movf result_quociente, W 	
    movwf PORTA			; Exibe o quociente em PORTA
   ; clrf result_quociente
   
    movf result_resto, W 	
    movwf PORTC			; Exibe o resto em PORTC
    ;clrf result_resto
    
    goto tabela

; --- CONVERSÃO PARA ASCII ---
tabela:
    BCF	STATUS, 5
    BCF	STATUS, 6   ;Selecionando o banco 0 para armazenar resultados
    
    movlw   high(table)		    ; Atualiza PCLATH com a página de table, 
    movwf   PCLATH		    ; não pode usar PAGESEL porque muda apenas 2 bits do PCLATH
		
    swapf result_quociente, F	    ;Trocando Nibble 1 com Nibble 0 ; Troca os nibbles do quociente (MSB <-> LSB)
    movlw 0x0F			    ;Criando mascara para pegar Nible 1
    andwf result_quociente, W	    ; Aplica a máscara no nibble trocado
    call  table			    ; Chama a tabela para obter o caractere ASCII
    movwf 0x20			    ;Armazena o MSB do quociente em ASCII.
	
    swapf result_quociente, F	    ; Restaura os nibbles do quociente (LSB no lugar certo)
    movlw 0x0F			    ; Máscara para isolar o nibble menos significativo
    andwf result_quociente, W	    ; Aplica a máscara no LSB
    call  table			    ; Chama a tabela para obter o caractere ASCII
    movwf 0x21			    ;Armazena o LSB do quociente em ASCII.
	
    swapf result_resto, F	    ;Trocando Nibble 1 com Nibble 0
    movlw 0x0F			    ;Criando mascara para pegar Nible 1
    andwf result_resto, W
    call  table
    movwf 0x22			    ; Armazena o MSB do resto em ASCII.
	
    swapf result_resto, F	    ;Trocando Nibble 1 com Nibble 0
    movlw 0x0F			     ;Criando mascara para pegar Nible 0
    andwf result_resto, W
    call  table
    movwf 0x23			    ;Armazena o LSB do resto em ASCII.
	
    clrf  result_quociente
    clrf  result_resto
    goto  leitura_variaveis
; --- TABELA DE CONVERSÃO ASCII ---	
ORG 0x400			    ; Coloca no inicio (x00) porque a tabela não pode ficar fora das 256 localizações 
table:				    ; Codifica valor
    addwf   PCL,F	; Adiciona W ao contador de programa (PCL)				
    retlw   0x30	; 0	    ; Devolve em W o valor codificado	
    retlw   0x31	; 1
    retlw   0x32	; 2
    retlw   0x33	; 3
    retlw   0x34	; 4
    retlw   0x35	; 5
    retlw   0x36	; 6
    retlw   0x37	; 7
    retlw   0x38	; 8
    retlw   0x39	; 9
    retlw   0x41	; A
    retlw   0x42	; B 
    retlw   0x43	; C 
    retlw   0x44	; D 
    retlw   0x45	; E 
    retlw   0x46	; F 
 