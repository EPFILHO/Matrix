//+------------------------------------------------------------------+
//|                                                 StrategyBase.mqh |
//|                                         Copyright 2026, EP Filho |
//|                                Interface Base para Estratégias   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "2.00"
#property strict

//+------------------------------------------------------------------+
//| Enum para tipo de sinal                                          |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_TYPE
  {
   SIGNAL_NONE = 0,    // Nenhum sinal
   SIGNAL_BUY = 1,     // Sinal de compra
   SIGNAL_SELL = -1    // Sinal de venda
  };

//+------------------------------------------------------------------+
//| Enum para modo de entrada                                        |
//+------------------------------------------------------------------+
enum ENUM_ENTRY_MODE
  {
   ENTRY_NEXT_CANDLE = 0,     // Entra na abertura do candle seguinte
   ENTRY_2ND_CANDLE = 1       // Entra no segundo candle (E2C)
  };

//+------------------------------------------------------------------+
//| Enum para modo de saída                                          |
//+------------------------------------------------------------------+
enum ENUM_EXIT_MODE
  {
   EXIT_FCO = 0,              // First Cross Out - sai no cruzamento inverso
   EXIT_VM = 1,               // Virar a Mão - inverte posição
   EXIT_TP_SL = 2             // Usa TP/SL normais
  };

//+------------------------------------------------------------------+
//| Classe Base Abstrata para Estratégias                            |
//+------------------------------------------------------------------+
class CStrategyBase
  {
protected:
   string            m_strategyName;      // Nome da estratégia
   bool              m_isInitialized;     // Flag de inicialização
   int               m_priority;          // Prioridade da estratégia (maior = mais importante)

public:
   // Construtor
                     CStrategyBase(string name, int priority = 0) :
                     m_strategyName(name),
                     m_isInitialized(false),
                     m_priority(priority) {}

   // Destrutor virtual
   virtual          ~CStrategyBase() {}

   // ═══════════════════════════════════════════════════════════
   // MÉTODOS VIRTUAIS PUROS (obrigatórios em classes filhas)
   // ═══════════════════════════════════════════════════════════

   // Inicialização e finalização
   virtual bool      Initialize() = 0;
   virtual void      Deinitialize() = 0;

   // Obter sinal de entrada
   virtual ENUM_SIGNAL_TYPE GetSignal() = 0;

   // ═══════════════════════════════════════════════════════════
   // MÉTODO VIRTUAL PURO - EXIT SIGNAL (v2.00)
   // ═══════════════════════════════════════════════════════════

   // Obter sinal de SAÍDA quando há posição aberta
   // Retorna:
   //   SIGNAL_NONE = manter posição (usa TP/SL normal)
   //   SIGNAL_BUY/SELL = fechar posição (sinal oposto)
   virtual ENUM_SIGNAL_TYPE GetExitSignal(ENUM_POSITION_TYPE currentPosition) = 0;

   // ═══════════════════════════════════════════════════════════
   // ATUALIZAÇÃO DE PARÂMETROS EM RUNTIME
   // ═══════════════════════════════════════════════════════════

   // Parâmetros "quentes" - não requerem reinicializar indicadores
   // Exemplos: entry mode, exit mode, flags on/off
   virtual bool      UpdateHotParameters() { return true; }  // Implementação opcional

   // Parâmetros "frios" - requerem reinicializar indicadores
   // Exemplos: períodos, métodos, timeframes
   // Retorna: true se conseguiu atualizar, false se falhou
   virtual bool      UpdateColdParameters() { return true; }  // Implementação opcional

   // ═══════════════════════════════════════════════════════════
   // GETTERS E SETTERS
   // ═══════════════════════════════════════════════════════════

   string            GetName() const { return m_strategyName; }
   bool              IsInitialized() const { return m_isInitialized; }

   // Prioridade (usado no SignalManager para resolver conflitos)
   int               GetPriority() const { return m_priority; }
   void              SetPriority(int priority) { m_priority = priority; }
  };
