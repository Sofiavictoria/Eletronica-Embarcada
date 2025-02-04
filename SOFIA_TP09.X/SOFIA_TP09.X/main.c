/**
  Generated Main Source File

  Company:
    Microchip Technology Inc.

  File Name:
    main.c
*/

#include "mcc_generated_files/mcc.h"
#include <string.h>
// Definição de constantes para facilitar a leitura do código
#define FIM_MENSAGEM 0x0D // Define o caractere de fim de mensagem (Enter)
#define AGENDADO 1 // Estado de um cliente agendado
#define ATENDIDO 2  // Estado de um cliente atendido
#define VAZIO 0    // Estado vazio (sem agendamento)

// Definição dos comandos aceitos via UART
#define A 0x41 // 'A' - Agendar um cliente
#define L 0x4C // 'L' - Listar clientes
#define P 0x50 // 'P' - Chamar próximo cliente
#define R 0x52 // 'R' - Resetar lista de clientes
#define ESPACO 0x20 // Representação do espaço (' ')
#define X 0x58 // Representação do 'X' para marcar atendimento concluído

// Define o tamanho máximo do nome do cliente e o número máximo de clientes
#define TAM_MAX_NOME 21
#define MAX_CLIENTES 10

// Estrutura para armazenar os dados dos clientes
typedef struct {
    uint8_t estado;  // Indica se está agendado, atendido ou vazio
    char Nome[TAM_MAX_NOME]; // Nome do cliente (string)
} RegistroCliente;

// Lista de clientes armazenada na EEPROM
__eeprom RegistroCliente listaclientes[MAX_CLIENTES];

// Mensagens do sistema
const char mensagem0[] = "L-Exibe lista, A-Agenda, P-Proximo, R-Apaga lista";
const char mensagem1[] = "Lista de agendamentos";
const char mensagem2[] = "Lista de agendamentos vazia";
const char mensagem3[] = "Proximo:";
const char mensagem4[] = "Digite o nome:";
const char mensagem5[] = "Nao foi possivel agendar (nome vazio)";
const char mensagem6[] = "Todos os agendamentos foram atendidos";
const char mensagem7[] = "Nao dispomos de mais agendamentos";
const char mensagem8[] = "Agendamento realizado";

// Variáveis globais para armazenar estado e entrada do sistema
uint8_t comando = 0 ; // Armazena o comando recebido  //buferRx
uint8_t c_Rx;  // Contador de caracteres recebidos via UART //countRx
uint8_t countNome = 0;  // Índice para armazenar o nome do cliente na lista 
bool nome_nulo = false; // Indica se um nome recebido está vazio
uint8_t nomes; // Contador de nomes na lista de clientes
bool verificar = false; // Flag para verificar se há clientes na lista

// Enviar mensagem via UART
void envia_mensagem(const char *mensagem){
    uint8_t i = 0;
    while (mensagem[i] > 0) { // Envia caracteres da mensagem
        EUSART_Write(mensagem[i]);
        i++;
    }
    EUSART_Write(FIM_MENSAGEM);
}

// Exibe o menu de comandos
void exibirMenu() {
    envia_mensagem(mensagem0);
}

// Exibe a lista de clientes armazenados na EEPROM
void exibirLista(){
    for(int i = 0; i < TAM_MAX_NOME; i++){
        if(listaclientes[i].estado == ATENDIDO){
            EUSART_Write(X); // Marca os clientes atendidos com 'X'
            EUSART_Write(ESPACO);
            for(int j = 0; j < 20 && listaclientes[i].Nome[j] != 0; j++){
            EUSART_Write(listaclientes[i].Nome[j]); // Envia o nome do cliente
            }
            EUSART_Write(FIM_MENSAGEM);
        } else if(listaclientes[i].estado == AGENDADO) {
            EUSART_Write(ESPACO); // Apenas um espaço para agendados
            EUSART_Write(ESPACO);
            for(int j = 0; j < 20 && listaclientes[i].Nome[j] != 0; j++){
            EUSART_Write(listaclientes[i].Nome[j]); // Envia cada caractere do nome
            }
            EUSART_Write(FIM_MENSAGEM); // Envia fim de mensagem
        }
    }
}

// Armazena o nome de um cliente recebido via UART
void armazenarNome(){
    static char buffer_nome[TAM_MAX_NOME]; // Buffer temporário para armazenar o nome recebido
    uint8_t countByte = 0;
    c_Rx = 0;
    envia_mensagem(mensagem4);
    while (c_Rx < (TAM_MAX_NOME - 1)){ // Recebe os caracteres do nome
        if (EUSART_is_rx_ready()) { // Se chega um byte 
            uint8_t rxChar = EUSART_Read(); // Se guarda em rxChar
            if (rxChar == FIM_MENSAGEM){ // Se for o fim da mensagem, encerra a leitura
                break;
            }
            else { // e o buffer não está cheio
                buffer_nome[c_Rx] = rxChar; // Armazena o caractere no buffer
                c_Rx++;
            }
        }
    }
    buffer_nome[c_Rx] = 0; // Adiciona o terminador nulo no final do buffer
    
    if(buffer_nome[0] == 0){ // Se o nome estiver vazio
        nome_nulo = true;
        envia_mensagem(mensagem5);
        listaclientes[countNome].estado = VAZIO;
    }
    else { // Se o nome for válido, armazena na lista
        nome_nulo = false;
        envia_mensagem(mensagem8);
        while(countByte < TAM_MAX_NOME){
            listaclientes[countNome].Nome[countByte] = buffer_nome[countByte];
            countByte++;
        }
        listaclientes[countNome].estado = AGENDADO;
    }
}

// Apaga todos os agendamentos da lista
void apagarLista(){
    for(int i = 0; i < MAX_CLIENTES; i++){
        listaclientes[i].estado = VAZIO; // Reseta todos os estados
    }
    countNome = 0;  // Reseta o contador
    envia_mensagem(mensagem2); // Informa que a lista foi apagada
}



// Executa o comando recebido
void executarComando() {
      
    switch (comando) {
        case 'L': // Listar os agendamentos
            if (listaclientes[0].estado == VAZIO) {
                envia_mensagem(mensagem2);
            } else {
                
                envia_mensagem(mensagem1);
                exibirLista();;
            }
            break;
          case 'A': // Agendar um novo cliente
              if(nomes < MAX_CLIENTES){
                  armazenarNome();
                  if (!nome_nulo){
                      countNome++;
                  }
               }else { 
                  envia_mensagem(mensagem7);
              }
              
            break;
            case 'P': // Chamar o próximo cliente
            
             for (uint8_t  i = 0; i < 10; i++) {
                if (listaclientes[i].estado == AGENDADO) {
                    envia_mensagem(mensagem3);
                    EUSART_Write(ESPACO);
                    EUSART_Write(ESPACO);
                    for (int j = 0; j < 20  && listaclientes[i].Nome[j] != 0; j++) {
                        EUSART_Write(listaclientes[i].Nome[j]);
                    }
                    EUSART_Write(FIM_MENSAGEM);
                    listaclientes[i].estado = ATENDIDO;
                        verificar = true;
                    break;
               
                } else if (!verificar) {
                    envia_mensagem(mensagem6);
                    
                }
               }
            
             break;
          case 'R':
                apagarLista();
                break;
            default: // Se o comando for inválido, exibe o menu novamente
                exibirMenu();
                break;
    }
}


void main(void) {
    SYSTEM_Initialize();
    
    comando = 0;
    exibirMenu(); // Exibe o menu ao iniciar
   while(1){
    if (EUSART_is_rx_ready()) { // Se houver um dado recebido via UART
            uint8_t rxChar = EUSART_Read();
            if (rxChar == L || rxChar == A || rxChar == P || rxChar == R) {
                comando = rxChar;                
            } 
            else if (rxChar == FIM_MENSAGEM) {
                executarComando();
    }
    }
}
}
