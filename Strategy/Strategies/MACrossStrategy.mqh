//+------------------------------------------------------------------+
//|                                             MACrossStrategy.mqh  |
//|                                         Copyright 2025, EP Filho |
//|                   Estratégia de Cruzamento de MAs - EPBot Matrix |
//|                                   Versão 2.21 - Claude Parte 022 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EP Filho"
#property version   "2.21"
#property strict

// ═══════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════
#include "../../Core/Logger.mqh"
#include "../Base/StrategyBase.mqh"

// ═══════════════════════════════════════════════════════════════
// NOVIDADES v2.21:
// + Fix: CopyBuffer validação alterada de <= 0 para < 3
//   (previne acesso fora dos limites se indicador retorna dados incompletos)
// ═══════════════════════════════════════════════════════════════
// NOVIDADES v2.20:
// + Migração para Logger v3.00 (5 níveis + throttle inteligente)
// + Todas as mensagens classificadas (ERROR/EVENT/SIGNAL/DEBUG)
// + Mantém correção E2C v2.11 (m_lastCheckBarTime)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Estratégia de Cruzamento de Médias Móveis                        |
//+------------------------------------------------------------------+
class CMACrossStrategy : public CStrategyBase
  {
private:
   // ═══════════════════════════════════════════════════════════
   // LOGGER
   // ═══════════════════════════════════════════════════════════
   CLogger*          m_logger;

   // ═══════════════════════════════════════════════════════════
   // HANDLES DOS INDICADORES
   // ═══════════════════════════════════════════════════════════
   int               m_handleMAFast;
   int               m_handleMASlow;

   // ═══════════════════════════════════════════════════════════
   // ARRAYS PARA VALORES
   // ═══════════════════════════════════════════════════════════
   double            m_maFast[];
   double            m_maSlow[];

   // ═══════════════════════════════════════════════════════════
   // INPUT PARAMETERS (imutáveis - valores originais)
   // ═══════════════════════════════════════════════════════════
   int               m_inputFastPeriod;
   ENUM_MA_METHOD    m_inputFastMethod;
   ENUM_APPLIED_PRICE m_inputFastApplied;
   ENUM_TIMEFRAMES   m_inputFastTimeframe;

   int               m_inputSlowPeriod;
   ENUM_MA_METHOD    m_inputSlowMethod;
   ENUM_APPLIED_PRICE m_inputSlowApplied;
   ENUM_TIMEFRAMES   m_inputSlowTimeframe;

   ENUM_ENTRY_MODE   m_inputEntryMode;
   ENUM_EXIT_MODE    m_inputExitMode;

   // ═══════════════════════════════════════════════════════════
   // WORKING PARAMETERS (mutáveis - valores em uso)
   // ═══════════════════════════════════════════════════════════
   int               m_fastPeriod;
   ENUM_MA_METHOD    m_fastMethod;
   ENUM_APPLIED_PRICE m_fastApplied;
   ENUM_TIMEFRAMES   m_fastTimeframe;

   int               m_slowPeriod;
   ENUM_MA_METHOD    m_slowMethod;
   ENUM_APPLIED_PRICE m_slowApplied;
   ENUM_TIMEFRAMES   m_slowTimeframe;

   ENUM_ENTRY_MODE   m_entryMode;
   ENUM_EXIT_MODE    m_exitMode;

   // ═══════════════════════════════════════════════════════════
   // CONTROLE DE CRUZAMENTO (estado interno - não duplica)
   // ═══════════════════════════════════════════════════════════
   datetime          m_lastCrossTime;
   ENUM_SIGNAL_TYPE  m_lastCrossSignal;
   int               m_candlesAfterCross;
   datetime          m_lastCheckBarTime;  // v2.11: Controle de candle para E2C

   // ═══════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS
   // ═══════════════════════════════════════════════════════════
   bool              UpdateIndicators();
   ENUM_SIGNAL_TYPE  DetectCross();
   ENUM_SIGNAL_TYPE  CheckExitSignal(ENUM_POSITION_TYPE currentPosition);

public:
   // ═══════════════════════════════════════════════════════════
   // CONSTRUTOR E DESTRUTOR
   // ═══════════════════════════════════════════════════════════
                     CMACrossStrategy(int priority = 0);
                    ~CMACrossStrategy();

   // ═══════════════════════════════════════════════════════════
   // CONFIGURAÇÃO INICIAL
   // ═══════════════════════════════════════════════════════════
   bool              Setup(
      CLogger* logger,
      int fastPeriod,
      ENUM_MA_METHOD fastMethod,
      ENUM_APPLIED_PRICE fastApplied,
      ENUM_TIMEFRAMES fastTimeframe,
      int slowPeriod,
      ENUM_MA_METHOD slowMethod,
      ENUM_APPLIED_PRICE slowApplied,
      ENUM_TIMEFRAMES slowTimeframe,
      ENUM_ENTRY_MODE entryMode,
      ENUM_EXIT_MODE exitMode
   );

   // ═══════════════════════════════════════════════════════════
   // IMPLEMENTAÇÃO DOS MÉTODOS VIRTUAIS (obrigatórios)
   // ═══════════════════════════════════════════════════════════
   virtual bool      Initialize() override;
   virtual void      Deinitialize() override;
   virtual ENUM_SIGNAL_TYPE GetSignal() override;

   //+------------------------------------------------------------------+
   //| Obter sinal de SAÍDA (v2.20)                                     |
   //+------------------------------------------------------------------+
   virtual ENUM_SIGNAL_TYPE GetExitSignal(ENUM_POSITION_TYPE currentPosition) override
     {
      if(!m_isInitialized)
         return SIGNAL_NONE;

      // EXIT_TP_SL: Strategy NÃO gerencia saída
      if(m_exitMode == EXIT_TP_SL)
         return SIGNAL_NONE;

      // EXIT_FCO ou EXIT_VM: Strategy gerencia saída
      return CheckExitSignal(currentPosition);
     }

   // ═══════════════════════════════════════════════════════════
   // HOT RELOAD - Parâmetros quentes (sem reiniciar indicadores)
   // ═══════════════════════════════════════════════════════════
   bool              SetEntryMode(ENUM_ENTRY_MODE mode);
   bool              SetExitMode(ENUM_EXIT_MODE mode);

   // ═══════════════════════════════════════════════════════════
   // COLD RELOAD - Parâmetros frios (reinicia indicadores)
   // ═══════════════════════════════════════════════════════════
   bool              SetMAPeriods(int fastPeriod, int slowPeriod);
   bool              SetMAMethods(ENUM_MA_METHOD fastMethod, ENUM_MA_METHOD slowMethod);
   bool              SetMATimeframes(ENUM_TIMEFRAMES fastTF, ENUM_TIMEFRAMES slowTF);

   // ═══════════════════════════════════════════════════════════
   // GETTERS - Working values (valores atuais em uso)
   // ═══════════════════════════════════════════════════════════
   double            GetMAFast(int shift = 0);
   double            GetMASlow(int shift = 0);
   ENUM_SIGNAL_TYPE  GetLastCross() const { return m_lastCrossSignal; }
   int               GetCandlesAfterCross() const { return m_candlesAfterCross; }

   int               GetFastPeriod() const { return m_fastPeriod; }
   int               GetSlowPeriod() const { return m_slowPeriod; }
   ENUM_MA_METHOD    GetFastMethod() const { return m_fastMethod; }
   ENUM_MA_METHOD    GetSlowMethod() const { return m_slowMethod; }
   ENUM_APPLIED_PRICE GetFastApplied() const { return m_fastApplied; }
   ENUM_APPLIED_PRICE GetSlowApplied() const { return m_slowApplied; }
   ENUM_TIMEFRAMES   GetFastTimeframe() const { return m_fastTimeframe; }
   ENUM_TIMEFRAMES   GetSlowTimeframe() const { return m_slowTimeframe; }
   ENUM_ENTRY_MODE   GetEntryMode() const { return m_entryMode; }
   ENUM_EXIT_MODE    GetExitMode() const { return m_exitMode; }

   // ═══════════════════════════════════════════════════════════
   // GETTERS - Input values (valores originais da configuração)
   // ═══════════════════════════════════════════════════════════
   int               GetInputFastPeriod() const { return m_inputFastPeriod; }
   int               GetInputSlowPeriod() const { return m_inputSlowPeriod; }
   ENUM_MA_METHOD    GetInputFastMethod() const { return m_inputFastMethod; }
   ENUM_MA_METHOD    GetInputSlowMethod() const { return m_inputSlowMethod; }
   ENUM_APPLIED_PRICE GetInputFastApplied() const { return m_inputFastApplied; }
   ENUM_APPLIED_PRICE GetInputSlowApplied() const { return m_inputSlowApplied; }
   ENUM_TIMEFRAMES   GetInputFastTimeframe() const { return m_inputFastTimeframe; }
   ENUM_TIMEFRAMES   GetInputSlowTimeframe() const { return m_inputSlowTimeframe; }
   ENUM_ENTRY_MODE   GetInputEntryMode() const { return m_inputEntryMode; }
   ENUM_EXIT_MODE    GetInputExitMode() const { return m_inputExitMode; }
  };

//+------------------------------------------------------------------+
//| Helper: Converter ENUM_MA_METHOD para string                     |
//+------------------------------------------------------------------+
string MAMethodToString(ENUM_MA_METHOD method)
  {
   switch(method)
     {
      case MODE_SMA:  return "SMA";
      case MODE_EMA:  return "EMA";
      case MODE_SMMA: return "SMMA";
      case MODE_LWMA: return "LWMA";
      default:        return "Unknown";
     }
  }

//+------------------------------------------------------------------+
//| Helper: Converter ENUM_APPLIED_PRICE para string                 |
//+------------------------------------------------------------------+
string AppliedPriceToString(ENUM_APPLIED_PRICE applied)
  {
   switch(applied)
     {
      case PRICE_CLOSE:     return "Close";
      case PRICE_OPEN:      return "Open";
      case PRICE_HIGH:      return "High";
      case PRICE_LOW:       return "Low";
      case PRICE_MEDIAN:    return "Median";
      case PRICE_TYPICAL:   return "Typical";
      case PRICE_WEIGHTED:  return "Weighted";
      default:              return "Unknown";
     }
  }

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CMACrossStrategy::CMACrossStrategy(int priority = 0) : CStrategyBase("MA Cross Strategy", priority)
  {
   m_logger = NULL;

   m_handleMAFast = INVALID_HANDLE;
   m_handleMASlow = INVALID_HANDLE;

   m_lastCrossTime = 0;
   m_lastCrossSignal = SIGNAL_NONE;
   m_candlesAfterCross = 0;
   m_lastCheckBarTime = 0;

   ArraySetAsSeries(m_maFast, true);
   ArraySetAsSeries(m_maSlow, true);
  }

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CMACrossStrategy::~CMACrossStrategy()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Configuração dos parâmetros (v2.20)                              |
//+------------------------------------------------------------------+
bool CMACrossStrategy::Setup(
   CLogger* logger,
   int fastPeriod,
   ENUM_MA_METHOD fastMethod,
   ENUM_APPLIED_PRICE fastApplied,
   ENUM_TIMEFRAMES fastTimeframe,
   int slowPeriod,
   ENUM_MA_METHOD slowMethod,
   ENUM_APPLIED_PRICE slowApplied,
   ENUM_TIMEFRAMES slowTimeframe,
   ENUM_ENTRY_MODE entryMode,
   ENUM_EXIT_MODE exitMode
)
  {
   m_logger = logger;

// ═══════════════════════════════════════════════════════════
// VALIDAÇÕES
// ═══════════════════════════════════════════════════════════
   if(fastPeriod <= 0 || slowPeriod <= 0)
     {
      string msg = "[MA Cross] Períodos inválidos: Fast=" + IntegerToString(fastPeriod) +
                   " Slow=" + IntegerToString(slowPeriod);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "SETUP", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   if(fastPeriod >= slowPeriod)
     {
      string msg = "[MA Cross] MA rápida deve ser menor que MA lenta: Fast=" +
                   IntegerToString(fastPeriod) + " Slow=" + IntegerToString(slowPeriod);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "SETUP", msg);
      else
         Print("❌ ", msg);
      return false;
     }

// ═══════════════════════════════════════════════════════════
// ARMAZENAR INPUTS (imutáveis - valores originais)
// ═══════════════════════════════════════════════════════════
   m_inputFastPeriod = fastPeriod;
   m_inputFastMethod = fastMethod;
   m_inputFastApplied = fastApplied;
   m_inputFastTimeframe = fastTimeframe;

   m_inputSlowPeriod = slowPeriod;
   m_inputSlowMethod = slowMethod;
   m_inputSlowApplied = slowApplied;
   m_inputSlowTimeframe = slowTimeframe;

   m_inputEntryMode = entryMode;
   m_inputExitMode = exitMode;

// ═══════════════════════════════════════════════════════════
// INICIALIZAR WORKING VARIABLES (mutáveis - começam iguais)
// ═══════════════════════════════════════════════════════════
   m_fastPeriod = fastPeriod;
   m_fastMethod = fastMethod;
   m_fastApplied = fastApplied;
   m_fastTimeframe = fastTimeframe;

   m_slowPeriod = slowPeriod;
   m_slowMethod = slowMethod;
   m_slowApplied = slowApplied;
   m_slowTimeframe = slowTimeframe;

   m_entryMode = entryMode;
   m_exitMode = exitMode;

   return true;
  }

//+------------------------------------------------------------------+
//| Inicialização (v2.20)                                            |
//+------------------------------------------------------------------+
bool CMACrossStrategy::Initialize()
  {
   if(m_isInitialized)
      return true;

// ═══════════════════════════════════════════════════════════
// CRIAR HANDLE DA MA RÁPIDA
// ═══════════════════════════════════════════════════════════
   m_handleMAFast = iMA(
                       _Symbol,
                       m_fastTimeframe,
                       m_fastPeriod,
                       0,
                       m_fastMethod,
                       m_fastApplied
                    );

   if(m_handleMAFast == INVALID_HANDLE)
     {
      int error = GetLastError();
      string msg = "[MA Cross] Falha ao criar handle MA rápida. Código: " + IntegerToString(error);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", msg);
      else
         Print("❌ ", msg);
      return false;
     }

// ═══════════════════════════════════════════════════════════
// CRIAR HANDLE DA MA LENTA
// ═══════════════════════════════════════════════════════════
   m_handleMASlow = iMA(
                       _Symbol,
                       m_slowTimeframe,
                       m_slowPeriod,
                       0,
                       m_slowMethod,
                       m_slowApplied
                    );

   if(m_handleMASlow == INVALID_HANDLE)
     {
      int error = GetLastError();
      string msg = "[MA Cross] Falha ao criar handle MA lenta. Código: " + IntegerToString(error);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", msg);
      else
         Print("❌ ", msg);
      IndicatorRelease(m_handleMAFast);
      m_handleMAFast = INVALID_HANDLE;
      return false;
     }

// ═══════════════════════════════════════════════════════════
// TESTAR SE CONSEGUE COPIAR DADOS
// ═══════════════════════════════════════════════════════════
   Sleep(100);

   if(!UpdateIndicators())
     {
      string msg = "[MA Cross] Falha no teste inicial de indicadores";
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", msg);
      else
         Print("❌ ", msg);
      Deinitialize();
      return false;
     }

   m_isInitialized = true;

   // ═══════════════════════════════════════════════════════════
   // LOG DETALHADO DE INICIALIZAÇÃO
   // ═══════════════════════════════════════════════════════════
   string fastInfo = MAMethodToString(m_fastMethod) + "(" + IntegerToString(m_fastPeriod) + ")";
   string slowInfo = MAMethodToString(m_slowMethod) + "(" + IntegerToString(m_slowPeriod) + ")";
   
   string msg = "✅ [MA Cross] Inicializada - Fast: " + fastInfo + " Slow: " + slowInfo;
   
   // Adicionar timeframes se diferentes
   if(m_fastTimeframe != m_slowTimeframe)
      msg += " | TF: " + EnumToString(m_fastTimeframe) + "/" + EnumToString(m_slowTimeframe);
   
   // Adicionar preço aplicado se diferentes
   if(m_fastApplied != m_slowApplied)
      msg += " | Price: " + AppliedPriceToString(m_fastApplied) + "/" + AppliedPriceToString(m_slowApplied);
   
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", msg);
   else
      Print(msg);

   return true;
  }

//+------------------------------------------------------------------+
//| Desinicialização                                                  |
//+------------------------------------------------------------------+
void CMACrossStrategy::Deinitialize()
  {
   if(m_handleMAFast != INVALID_HANDLE)
     {
      IndicatorRelease(m_handleMAFast);
      m_handleMAFast = INVALID_HANDLE;
     }

   if(m_handleMASlow != INVALID_HANDLE)
     {
      IndicatorRelease(m_handleMASlow);
      m_handleMASlow = INVALID_HANDLE;
     }

   m_isInitialized = false;
  }

//+------------------------------------------------------------------+
//| Atualizar valores dos indicadores (v2.20)                        |
//+------------------------------------------------------------------+
bool CMACrossStrategy::UpdateIndicators()
  {
   if(m_handleMAFast == INVALID_HANDLE || m_handleMASlow == INVALID_HANDLE)
     {
      string msg = "[MA Cross] Handles inválidos";
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "UPDATE", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   int copiedFast = CopyBuffer(m_handleMAFast, 0, 0, 3, m_maFast);
   if(copiedFast < 3)
     {
      int error = GetLastError();
      string msg = "[MA Cross] Erro ao copiar buffer MA rápida (copiados: " + IntegerToString(copiedFast) + "/3). Código: " + IntegerToString(error);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "UPDATE", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   int copiedSlow = CopyBuffer(m_handleMASlow, 0, 0, 3, m_maSlow);
   if(copiedSlow < 3)
     {
      int error = GetLastError();
      string msg = "[MA Cross] Erro ao copiar buffer MA lenta (copiados: " + IntegerToString(copiedSlow) + "/3). Código: " + IntegerToString(error);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "UPDATE", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Detectar cruzamento entre candles [2] e [1]                      |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CMACrossStrategy::DetectCross()
  {
// Cruzamento de alta (Golden Cross)
   if(m_maFast[2] < m_maSlow[2] && m_maFast[1] > m_maSlow[1])
     {
      return SIGNAL_BUY;
     }

// Cruzamento de baixa (Death Cross)
   if(m_maFast[2] > m_maSlow[2] && m_maFast[1] < m_maSlow[1])
     {
      return SIGNAL_SELL;
     }

   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| Obter sinal de entrada (v2.20)                                   |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CMACrossStrategy::GetSignal()
  {
   if(!m_isInitialized)
     {
      string msg = "[MA Cross] Tentativa de obter sinal sem estar inicializado";
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "SIGNAL", msg);
      else
         Print("❌ ", msg);
      return SIGNAL_NONE;
     }

   if(!UpdateIndicators())
     {
      string msg = "[MA Cross] Falha ao atualizar indicadores";
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "SIGNAL", msg);
      else
         Print("❌ ", msg);
      return SIGNAL_NONE;
     }

// Detectar cruzamento entre candles [2] e [1]
   ENUM_SIGNAL_TYPE crossSignal = DetectCross();
   datetime crossBarTime = iTime(_Symbol, m_fastTimeframe, 1);

// Novo cruzamento detectado?
   if(crossSignal != SIGNAL_NONE)
     {
      if(crossBarTime != m_lastCrossTime)
        {
         m_lastCrossTime = crossBarTime;
         m_lastCrossSignal = crossSignal;
         m_candlesAfterCross = 0;
         m_lastCheckBarTime = iTime(_Symbol, m_fastTimeframe, 0);

         // ENTRY_NEXT_CANDLE: Entra IMEDIATAMENTE
         if(m_entryMode == ENTRY_NEXT_CANDLE)
           {
            string msg = "🎯 [MA Cross] Cruzamento detectado - gerando sinal imediato (NEXT_CANDLE)";
            if(m_logger != NULL)
               m_logger.Log(LOG_SIGNAL, THROTTLE_NONE, "SIGNAL", msg);
            else
               Print(msg);
            return crossSignal;
           }
         // ENTRY_2ND_CANDLE: Espera mais 1 candle
         else
           {
            string msg = "⏳ [MA Cross] Cruzamento detectado - aguardando 2º candle (E2C)";
            if(m_logger != NULL)
               m_logger.Log(LOG_SIGNAL, THROTTLE_NONE, "SIGNAL", msg);
            else
               Print(msg);
            return SIGNAL_NONE;
           }
        }
     }

// ═══════════════════════════════════════════════════════════
// Modo E2C - Incrementar apenas 1x por candle
// ═══════════════════════════════════════════════════════════
   if(m_entryMode == ENTRY_2ND_CANDLE && m_lastCrossSignal != SIGNAL_NONE)
     {
      datetime currentBarTime = iTime(_Symbol, m_fastTimeframe, 0);
      
      // Só incrementa se for um NOVO candle
      if(currentBarTime != m_lastCheckBarTime)
        {
         m_lastCheckBarTime = currentBarTime;
         m_candlesAfterCross++;
         
         string msg = "⏳ [MA Cross] E2C: Candle " + IntegerToString(m_candlesAfterCross) + " após cruzamento";
         if(m_logger != NULL)
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "SIGNAL", msg);
         else
            Print(msg);
        }

      // Após 1 candle completo → gerar sinal
      if(m_candlesAfterCross >= 1)
        {
         string msg = "🎯 [MA Cross] 2º candle após cruzamento - gerando sinal (E2C)";
         if(m_logger != NULL)
            m_logger.Log(LOG_SIGNAL, THROTTLE_NONE, "SIGNAL", msg);
         else
            Print(msg);
         ENUM_SIGNAL_TYPE signal = m_lastCrossSignal;
         m_lastCrossSignal = SIGNAL_NONE;
         m_candlesAfterCross = 0;
         m_lastCheckBarTime = 0;
         return signal;
        }
     }

   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar modo de entrada (v2.20)                     |
//+------------------------------------------------------------------+
bool CMACrossStrategy::SetEntryMode(ENUM_ENTRY_MODE mode)
  {
   ENUM_ENTRY_MODE oldMode = m_entryMode;
   m_entryMode = mode;

   string oldStr = (oldMode == ENTRY_NEXT_CANDLE) ? "NEXT_CANDLE" : "E2C";
   string newStr = (mode == ENTRY_NEXT_CANDLE) ? "NEXT_CANDLE" : "E2C";

   string msg = "🔄 [MA Cross] Entry mode alterado: " + oldStr + " → " + newStr;
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", msg);
   else
      Print(msg);

// Resetar controle de cruzamento
   m_lastCrossSignal = SIGNAL_NONE;
   m_candlesAfterCross = 0;
   m_lastCheckBarTime = 0;

   return true;
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar modo de saída (v2.20)                       |
//+------------------------------------------------------------------+
bool CMACrossStrategy::SetExitMode(ENUM_EXIT_MODE mode)
  {
   ENUM_EXIT_MODE oldMode = m_exitMode;
   m_exitMode = mode;

   string oldStr, newStr;
   switch(oldMode)
     {
      case EXIT_FCO:
         oldStr = "FCO";
         break;
      case EXIT_VM:
         oldStr = "VM";
         break;
      case EXIT_TP_SL:
         oldStr = "TP/SL";
         break;
     }

   switch(mode)
     {
      case EXIT_FCO:
         newStr = "FCO";
         break;
      case EXIT_VM:
         newStr = "VM";
         break;
      case EXIT_TP_SL:
         newStr = "TP/SL";
         break;
     }

   string msg = "🔄 [MA Cross] Exit mode alterado: " + oldStr + " → " + newStr;
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", msg);
   else
      Print(msg);

   return true;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar períodos (v2.20)                           |
//+------------------------------------------------------------------+
bool CMACrossStrategy::SetMAPeriods(int fastPeriod, int slowPeriod)
  {
   if(fastPeriod <= 0 || slowPeriod <= 0 || fastPeriod >= slowPeriod)
     {
      string msg = "[MA Cross] Períodos inválidos: Fast=" + IntegerToString(fastPeriod) +
                   " Slow=" + IntegerToString(slowPeriod);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "COLD_RELOAD", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   int oldFast = m_fastPeriod;
   int oldSlow = m_slowPeriod;

   m_fastPeriod = fastPeriod;
   m_slowPeriod = slowPeriod;

   Deinitialize();
   bool success = Initialize();

   if(success)
     {
      string msg = "🔄 [MA Cross] Períodos alterados: Fast " + IntegerToString(oldFast) +
                   "→" + IntegerToString(fastPeriod) + ", Slow " + IntegerToString(oldSlow) +
                   "→" + IntegerToString(slowPeriod);
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD", msg);
      else
         Print(msg);
     }

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar métodos (v2.20)                            |
//+------------------------------------------------------------------+
bool CMACrossStrategy::SetMAMethods(ENUM_MA_METHOD fastMethod, ENUM_MA_METHOD slowMethod)
  {
   m_fastMethod = fastMethod;
   m_slowMethod = slowMethod;

   Deinitialize();
   bool success = Initialize();

   if(success)
     {
      string msg = "🔄 [MA Cross] Métodos alterados";
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD", msg);
      else
         Print(msg);
     }

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar timeframes (v2.20)                         |
//+------------------------------------------------------------------+
bool CMACrossStrategy::SetMATimeframes(ENUM_TIMEFRAMES fastTF, ENUM_TIMEFRAMES slowTF)
  {
   m_fastTimeframe = fastTF;
   m_slowTimeframe = slowTF;

   Deinitialize();
   bool success = Initialize();

   if(success)
     {
      string msg = "🔄 [MA Cross] Timeframes alterados";
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD", msg);
      else
         Print(msg);
     }

   return success;
  }

//+------------------------------------------------------------------+
//| Obter valor da MA rápida                                         |
//+------------------------------------------------------------------+
double CMACrossStrategy::GetMAFast(int shift = 0)
  {
   if(!m_isInitialized || shift >= ArraySize(m_maFast))
      return 0.0;

   return m_maFast[shift];
  }

//+------------------------------------------------------------------+
//| Obter valor da MA lenta                                          |
//+------------------------------------------------------------------+
double CMACrossStrategy::GetMASlow(int shift = 0)
  {
   if(!m_isInitialized || shift >= ArraySize(m_maSlow))
      return 0.0;

   return m_maSlow[shift];
  }
  
//+------------------------------------------------------------------+
//| Verificar sinal de saída (v2.20)                                 |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CMACrossStrategy::CheckExitSignal(ENUM_POSITION_TYPE currentPosition)
{
   if(!UpdateIndicators())
      return SIGNAL_NONE;
   
   // Detectar cruzamento ATUAL (sem filtros)
   ENUM_SIGNAL_TYPE crossSignal = DetectCross();
   
   if(crossSignal == SIGNAL_NONE)
      return SIGNAL_NONE;
   
   // Se posição é COMPRA e detectou VENDA → Sinal de saída
   if(currentPosition == POSITION_TYPE_BUY && crossSignal == SIGNAL_SELL)
   {
      string msg = "🔄 [MA Cross] EXIT detectado - Cruzamento de VENDA com posição de COMPRA";
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_NONE, "EXIT", msg);
      else
         Print(msg);
      
      return SIGNAL_SELL;
   }
   
   // Se posição é VENDA e detectou COMPRA → Sinal de saída
   if(currentPosition == POSITION_TYPE_SELL && crossSignal == SIGNAL_BUY)
   {
      string msg = "🔄 [MA Cross] EXIT detectado - Cruzamento de COMPRA com posição de VENDA";
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_NONE, "EXIT", msg);
      else
         Print(msg);
      
      return SIGNAL_BUY;
   }
   
   return SIGNAL_NONE;
}
//+------------------------------------------------------------------+
