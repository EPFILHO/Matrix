//+------------------------------------------------------------------+
//|                                                 RSIStrategy.mqh  |
//|                                         Copyright 2025, EP Filho |
//|                                    Estratégia RSI - EPBot Matrix |
//|                     Versão 2.11 - Claude Parte 022 (Claude Code) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EP Filho"
#property version   "2.11"
#property strict

// ═══════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════
#include "../../Core/Logger.mqh"
#include "../Base/StrategyBase.mqh"

// ═══════════════════════════════════════════════════════════════
// NOVIDADES v2.11:
// + CopyBuffer agora valida quantidade exata (!= count) em vez de <= 0
// + Garante que buffer RSI tem exatamente os dados solicitados
// ═══════════════════════════════════════════════════════════════
// NOVIDADES v2.10:
// + Migração para Logger v3.00 (5 níveis + throttle inteligente)
// + Todas as mensagens classificadas (ERROR/EVENT/SIGNAL/DEBUG)
// + Adicionado LOG_SIGNAL para detecção de sinais RSI
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Enumeração de Modos de Sinal RSI                                 |
//+------------------------------------------------------------------+
enum ENUM_RSI_SIGNAL_MODE
  {
   RSI_MODE_CROSSOVER = 0,    // Cruzamento de níveis (padrão)
   RSI_MODE_ZONE      = 1,    // Zona (sobrecompra/sobrevenda)
   RSI_MODE_MIDDLE    = 2     // Cruzamento da linha média (50)
  };

//+------------------------------------------------------------------+
//| Classe RSI Strategy                                              |
//+------------------------------------------------------------------+
class CRSIStrategy : public CStrategyBase
  {
private:
   // ═══════════════════════════════════════════════════════════
   // LOGGER
   // ═══════════════════════════════════════════════════════════
   CLogger*          m_logger;

   // ═══════════════════════════════════════════════════════════
   // HANDLES E BUFFERS (não duplica - são internos)
   // ═══════════════════════════════════════════════════════════
   int               m_rsi_handle;
   double            m_rsi_buffer[];

   // ═══════════════════════════════════════════════════════════
   // INPUT PARAMETERS - FRIOS (valores originais - requerem reinit)
   // ═══════════════════════════════════════════════════════════
   string            m_inputSymbol;
   ENUM_TIMEFRAMES   m_inputTimeframe;
   int               m_inputPeriod;
   ENUM_APPLIED_PRICE m_inputAppliedPrice;

   // ═══════════════════════════════════════════════════════════
   // WORKING PARAMETERS - FRIOS (valores usados - requerem reinit)
   // ═══════════════════════════════════════════════════════════
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   int               m_period;
   ENUM_APPLIED_PRICE m_applied_price;

   // ═══════════════════════════════════════════════════════════
   // INPUT PARAMETERS - QUENTES (valores originais - não requerem reinit)
   // ═══════════════════════════════════════════════════════════
   ENUM_RSI_SIGNAL_MODE m_inputSignalMode;
   double            m_inputOversold;
   double            m_inputOverbought;
   double            m_inputMiddle;
   int               m_inputSignalShift;
   bool              m_inputEnabled;

   // ═══════════════════════════════════════════════════════════
   // WORKING PARAMETERS - QUENTES (valores usados - não requerem reinit)
   // ═══════════════════════════════════════════════════════════
   ENUM_RSI_SIGNAL_MODE m_signal_mode;
   double            m_oversold;
   double            m_overbought;
   double            m_middle;
   int               m_signal_shift;
   bool              m_enabled;

   // ═══════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS
   // ═══════════════════════════════════════════════════════════
   bool              LoadRSIValues(int count);
   ENUM_SIGNAL_TYPE  CheckCrossoverSignal();
   ENUM_SIGNAL_TYPE  CheckZoneSignal();
   ENUM_SIGNAL_TYPE  CheckMiddleSignal();

public:
   // ═══════════════════════════════════════════════════════════
   // CONSTRUTOR E DESTRUTOR
   // ═══════════════════════════════════════════════════════════
                     CRSIStrategy(int priority = 5);
                    ~CRSIStrategy();

   // ═══════════════════════════════════════════════════════════
   // SETUP (chamado ANTES do Initialize)
   // ═══════════════════════════════════════════════════════════
   bool              Setup(CLogger* logger, string symbol, ENUM_TIMEFRAMES timeframe, int period,
              ENUM_APPLIED_PRICE applied_price, ENUM_RSI_SIGNAL_MODE signal_mode,
              double oversold, double overbought, double middle, int signal_shift);

   // ═══════════════════════════════════════════════════════════
   // IMPLEMENTAÇÃO DOS MÉTODOS VIRTUAIS (obrigatórios)
   // ═══════════════════════════════════════════════════════════
   virtual bool      Initialize() override;
   virtual void      Deinitialize() override;
   virtual ENUM_SIGNAL_TYPE GetSignal() override;

   //+------------------------------------------------------------------+
   //| Obter sinal de SAÍDA (v2.10)                                     |
   //+------------------------------------------------------------------+
   virtual ENUM_SIGNAL_TYPE GetExitSignal(ENUM_POSITION_TYPE currentPosition) override
     {
      // RSI Strategy: Sempre usa TP/SL normal (não gerencia exit)
      // No futuro pode implementar exit por reversão de RSI
      return SIGNAL_NONE;
     }

   virtual bool      UpdateHotParameters() override;
   virtual bool      UpdateColdParameters() override;

   // ═══════════════════════════════════════════════════════════
   // HOT RELOAD - Parâmetros quentes (sem reiniciar indicadores)
   // ═══════════════════════════════════════════════════════════
   void              SetSignalMode(ENUM_RSI_SIGNAL_MODE mode);
   void              SetOversold(double value);
   void              SetOverbought(double value);
   void              SetMiddle(double value);
   void              SetSignalShift(int value);
   void              SetEnabled(bool value);

   // ═══════════════════════════════════════════════════════════
   // COLD RELOAD - Parâmetros frios (reinicia indicadores)
   // ═══════════════════════════════════════════════════════════
   bool              SetPeriod(int value);
   bool              SetTimeframe(ENUM_TIMEFRAMES tf);
   bool              SetAppliedPrice(ENUM_APPLIED_PRICE price);

   // ═══════════════════════════════════════════════════════════
   // GETTERS - Working values (valores atuais em uso)
   // ═══════════════════════════════════════════════════════════
   double            GetCurrentRSI();
   double            GetRSI(int shift);
   string            GetSignalModeText();

   int               GetPeriod() const { return m_period; }
   ENUM_TIMEFRAMES   GetTimeframe() const { return m_timeframe; }
   ENUM_APPLIED_PRICE GetAppliedPrice() const { return m_applied_price; }
   ENUM_RSI_SIGNAL_MODE GetSignalMode() const { return m_signal_mode; }
   double            GetOversold() const { return m_oversold; }
   double            GetOverbought() const { return m_overbought; }
   double            GetMiddle() const { return m_middle; }
   int               GetSignalShift() const { return m_signal_shift; }
   bool              GetEnabled() const { return m_enabled; }

   // ═══════════════════════════════════════════════════════════
   // GETTERS - Input values (valores originais da configuração)
   // ═══════════════════════════════════════════════════════════
   int               GetInputPeriod() const { return m_inputPeriod; }
   ENUM_TIMEFRAMES   GetInputTimeframe() const { return m_inputTimeframe; }
   ENUM_APPLIED_PRICE GetInputAppliedPrice() const { return m_inputAppliedPrice; }
   ENUM_RSI_SIGNAL_MODE GetInputSignalMode() const { return m_inputSignalMode; }
   double            GetInputOversold() const { return m_inputOversold; }
   double            GetInputOverbought() const { return m_inputOverbought; }
   double            GetInputMiddle() const { return m_inputMiddle; }
   int               GetInputSignalShift() const { return m_inputSignalShift; }
   bool              GetInputEnabled() const { return m_inputEnabled; }
  };

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CRSIStrategy::CRSIStrategy(int priority = 5) : CStrategyBase("RSI Strategy", priority)
  {
   m_logger = NULL;
   m_rsi_handle = INVALID_HANDLE;

// ═══ INPUT PARAMETERS (valores padrão) ═══
   m_inputSymbol = "";
   m_inputTimeframe = PERIOD_CURRENT;
   m_inputPeriod = 14;
   m_inputAppliedPrice = PRICE_CLOSE;
   m_inputSignalMode = RSI_MODE_CROSSOVER;
   m_inputOversold = 30.0;
   m_inputOverbought = 70.0;
   m_inputMiddle = 50.0;
   m_inputSignalShift = 1;
   m_inputEnabled = true;

// ═══ WORKING PARAMETERS (começam iguais aos inputs) ═══
   m_symbol = "";
   m_timeframe = PERIOD_CURRENT;
   m_period = 14;
   m_applied_price = PRICE_CLOSE;
   m_signal_mode = RSI_MODE_CROSSOVER;
   m_oversold = 30.0;
   m_overbought = 70.0;
   m_middle = 50.0;
   m_signal_shift = 1;
   m_enabled = true;

   ArraySetAsSeries(m_rsi_buffer, true);
  }

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CRSIStrategy::~CRSIStrategy()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Setup (configuração inicial)                                     |
//+------------------------------------------------------------------+
bool CRSIStrategy::Setup(CLogger* logger, string symbol, ENUM_TIMEFRAMES timeframe, int period,
                         ENUM_APPLIED_PRICE applied_price, ENUM_RSI_SIGNAL_MODE signal_mode,
                         double oversold, double overbought, double middle, int signal_shift)
  {
   m_logger = logger;

// ═══════════════════════════════════════════════════════════
// SALVAR INPUT PARAMETERS (valores originais)
// ═══════════════════════════════════════════════════════════
   m_inputSymbol = symbol;
   m_inputTimeframe = (timeframe == PERIOD_CURRENT) ? Period() : timeframe;
   m_inputPeriod = period;
   m_inputAppliedPrice = applied_price;
   m_inputSignalMode = signal_mode;
   m_inputOversold = oversold;
   m_inputOverbought = overbought;
   m_inputMiddle = middle;
   m_inputSignalShift = signal_shift;
   m_inputEnabled = true;

// ═══════════════════════════════════════════════════════════
// INICIALIZAR WORKING PARAMETERS (começam iguais aos inputs)
// ═══════════════════════════════════════════════════════════
   m_symbol = symbol;
   m_timeframe = (timeframe == PERIOD_CURRENT) ? Period() : timeframe;
   m_period = period;
   m_applied_price = applied_price;
   m_signal_mode = signal_mode;
   m_oversold = oversold;
   m_overbought = overbought;
   m_middle = middle;
   m_signal_shift = signal_shift;
   m_enabled = true;

   return true;
  }

//+------------------------------------------------------------------+
//| Initialize (criar handles) - v2.10                               |
//+------------------------------------------------------------------+
bool CRSIStrategy::Initialize()
  {
   if(m_isInitialized)
      return true;

   m_rsi_handle = iRSI(m_symbol, m_timeframe, m_period, m_applied_price);

   if(m_rsi_handle == INVALID_HANDLE)
     {
      string msg = "[" + m_strategyName + "] Erro ao criar indicador RSI";
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   m_isInitialized = true;

   string msg = "✅ [" + m_strategyName + "] Inicializado [" + m_symbol + " | " +
                EnumToString(m_timeframe) + " | Período: " + IntegerToString(m_period) + " | Modo: " +
                GetSignalModeText() + "]";
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", msg);
   else
      Print(msg);

   return true;
  }

//+------------------------------------------------------------------+
//| Deinitialize (liberar handles)                                   |
//+------------------------------------------------------------------+
void CRSIStrategy::Deinitialize()
  {
   if(m_rsi_handle != INVALID_HANDLE)
     {
      IndicatorRelease(m_rsi_handle);
      m_rsi_handle = INVALID_HANDLE;
     }

   m_isInitialized = false;
  }

//+------------------------------------------------------------------+
//| UpdateHotParameters (params sem reinicialização)                 |
//+------------------------------------------------------------------+
bool CRSIStrategy::UpdateHotParameters()
  {
// Parâmetros quentes já são atualizados via setters
   return true;
  }

//+------------------------------------------------------------------+
//| UpdateColdParameters (params que precisam reinicializar)         |
//+------------------------------------------------------------------+
bool CRSIStrategy::UpdateColdParameters()
  {
   Deinitialize();
   return Initialize();
  }

//+------------------------------------------------------------------+
//| Carregar valores do RSI - v2.10                                  |
//+------------------------------------------------------------------+
bool CRSIStrategy::LoadRSIValues(int count)
  {
   if(m_rsi_handle == INVALID_HANDLE)
      return false;

   if(CopyBuffer(m_rsi_handle, 0, 0, count, m_rsi_buffer) != count)
     {
      string msg = "[" + m_strategyName + "] Erro ao copiar buffer RSI";
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "BUFFER", msg);
      else
         Print("⚠️ ", msg);
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| GetSignal (método principal - OBRIGATÓRIO)                       |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CRSIStrategy::GetSignal()
  {
   if(!m_isInitialized || !m_enabled)
      return SIGNAL_NONE;

   if(!LoadRSIValues(m_signal_shift + 3))
      return SIGNAL_NONE;

   switch(m_signal_mode)
     {
      case RSI_MODE_CROSSOVER:
         return CheckCrossoverSignal();

      case RSI_MODE_ZONE:
         return CheckZoneSignal();

      case RSI_MODE_MIDDLE:
         return CheckMiddleSignal();

      default:
         return SIGNAL_NONE;
     }
  }

//+------------------------------------------------------------------+
//| Modo CROSSOVER: Cruza níveis - v2.10                             |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CRSIStrategy::CheckCrossoverSignal()
  {
   double rsi_current = m_rsi_buffer[m_signal_shift];
   double rsi_previous = m_rsi_buffer[m_signal_shift + 1];

// BUY: RSI cruza DE BAIXO para CIMA o nível de sobrevenda
   if(rsi_previous <= m_oversold && rsi_current > m_oversold)
     {
      string msg = StringFormat("🎯 [RSI] COMPRA - Cruzou sobrevenda: %.1f → %.1f (limite: %.1f)", 
                                rsi_previous, rsi_current, m_oversold);
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      else
         Print(msg);
      return SIGNAL_BUY;
     }

// SELL: RSI cruza DE CIMA para BAIXO o nível de sobrecompra
   if(rsi_previous >= m_overbought && rsi_current < m_overbought)
     {
      string msg = StringFormat("🎯 [RSI] VENDA - Cruzou sobrecompra: %.1f → %.1f (limite: %.1f)", 
                                rsi_previous, rsi_current, m_overbought);
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      else
         Print(msg);
      return SIGNAL_SELL;
     }

   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| Modo ZONE: Permanência em zona - v2.10                           |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CRSIStrategy::CheckZoneSignal()
  {
   double rsi_current = m_rsi_buffer[m_signal_shift];

// BUY: RSI está em zona de sobrevenda
   if(rsi_current <= m_oversold)
     {
      string msg = StringFormat("🎯 [RSI] COMPRA - Em sobrevenda: %.1f (≤ %.1f)", 
                                rsi_current, m_oversold);
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      else
         Print(msg);
      return SIGNAL_BUY;
     }

// SELL: RSI está em zona de sobrecompra
   if(rsi_current >= m_overbought)
     {
      string msg = StringFormat("🎯 [RSI] VENDA - Em sobrecompra: %.1f (≥ %.1f)", 
                                rsi_current, m_overbought);
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      else
         Print(msg);
      return SIGNAL_SELL;
     }

   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| Modo MIDDLE: Cruzamento da linha 50 - v2.10                      |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CRSIStrategy::CheckMiddleSignal()
  {
   double rsi_current = m_rsi_buffer[m_signal_shift];
   double rsi_previous = m_rsi_buffer[m_signal_shift + 1];

// BUY: RSI cruza linha média de baixo para cima
   if(rsi_previous < m_middle && rsi_current >= m_middle)
     {
      string msg = StringFormat("🎯 [RSI] COMPRA - Cruzou linha média: %.1f → %.1f (linha: %.1f)", 
                                rsi_previous, rsi_current, m_middle);
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      else
         Print(msg);
      return SIGNAL_BUY;
     }

// SELL: RSI cruza linha média de cima para baixo
   if(rsi_previous > m_middle && rsi_current <= m_middle)
     {
      string msg = StringFormat("🎯 [RSI] VENDA - Cruzou linha média: %.1f → %.1f (linha: %.1f)", 
                                rsi_previous, rsi_current, m_middle);
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      else
         Print(msg);
      return SIGNAL_SELL;
     }

   return SIGNAL_NONE;
  }

// ═══════════════════════════════════════════════════════════════
// HOT RELOAD - MÉTODOS SET QUENTES (v2.10)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar modo de sinal - v2.10                       |
//+------------------------------------------------------------------+
void CRSIStrategy::SetSignalMode(ENUM_RSI_SIGNAL_MODE mode)
  {
   ENUM_RSI_SIGNAL_MODE oldMode = m_signal_mode;
   m_signal_mode = mode;

   string oldStr, newStr;
   switch(oldMode)
     {
      case RSI_MODE_CROSSOVER:
         oldStr = "Crossover";
         break;
      case RSI_MODE_ZONE:
         oldStr = "Zone";
         break;
      case RSI_MODE_MIDDLE:
         oldStr = "Middle";
         break;
     }

   switch(mode)
     {
      case RSI_MODE_CROSSOVER:
         newStr = "Crossover";
         break;
      case RSI_MODE_ZONE:
         newStr = "Zone";
         break;
      case RSI_MODE_MIDDLE:
         newStr = "Middle";
         break;
     }

   string msg = "🔄 [RSI] Modo alterado: " + oldStr + " → " + newStr;
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", msg);
   else
      Print(msg);
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar nível de sobrevenda - v2.10                 |
//+------------------------------------------------------------------+
void CRSIStrategy::SetOversold(double value)
  {
   double oldValue = m_oversold;
   m_oversold = value;

   string msg = StringFormat("🔄 [RSI] Sobrevenda alterado: %.1f → %.1f", oldValue, value);
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", msg);
   else
      Print(msg);
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar nível de sobrecompra - v2.10                |
//+------------------------------------------------------------------+
void CRSIStrategy::SetOverbought(double value)
  {
   double oldValue = m_overbought;
   m_overbought = value;

   string msg = StringFormat("🔄 [RSI] Sobrecompra alterado: %.1f → %.1f", oldValue, value);
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", msg);
   else
      Print(msg);
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar linha média - v2.10                         |
//+------------------------------------------------------------------+
void CRSIStrategy::SetMiddle(double value)
  {
   double oldValue = m_middle;
   m_middle = value;

   string msg = StringFormat("🔄 [RSI] Linha média alterada: %.1f → %.1f", oldValue, value);
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", msg);
   else
      Print(msg);
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar shift do sinal - v2.10                      |
//+------------------------------------------------------------------+
void CRSIStrategy::SetSignalShift(int value)
  {
   int oldValue = m_signal_shift;
   m_signal_shift = value;

   string msg = StringFormat("🔄 [RSI] Signal shift alterado: %d → %d", oldValue, value);
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", msg);
   else
      Print(msg);
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Ativar/desativar estratégia - v2.10                 |
//+------------------------------------------------------------------+
void CRSIStrategy::SetEnabled(bool value)
  {
   bool oldValue = m_enabled;
   m_enabled = value;

   string msg = "🔄 [RSI] Estratégia: " + (value ? "ATIVADA" : "DESATIVADA");
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", msg);
   else
      Print(msg);
  }

// ═══════════════════════════════════════════════════════════════
// COLD RELOAD - MÉTODOS SET FRIOS (v2.10)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar período (reinicia indicador) - v2.10       |
//+------------------------------------------------------------------+
bool CRSIStrategy::SetPeriod(int value)
  {
   if(value <= 0)
     {
      string msg = "[RSI] Período inválido: " + IntegerToString(value);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "COLD_RELOAD", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   int oldValue = m_period;
   m_period = value;

   Deinitialize();
   bool success = Initialize();

   if(success)
     {
      string msg = StringFormat("🔄 [RSI] Período alterado: %d → %d (reiniciado)", oldValue, value);
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD", msg);
      else
         Print(msg);
     }

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar timeframe (reinicia indicador) - v2.10     |
//+------------------------------------------------------------------+
bool CRSIStrategy::SetTimeframe(ENUM_TIMEFRAMES tf)
  {
   ENUM_TIMEFRAMES oldTF = m_timeframe;
   m_timeframe = tf;

   Deinitialize();
   bool success = Initialize();

   if(success)
     {
      string msg = "🔄 [RSI] Timeframe alterado: " + EnumToString(oldTF) + " → " + EnumToString(tf) + " (reiniciado)";
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD", msg);
      else
         Print(msg);
     }

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar applied price (reinicia indicador) - v2.10 |
//+------------------------------------------------------------------+
bool CRSIStrategy::SetAppliedPrice(ENUM_APPLIED_PRICE price)
  {
   ENUM_APPLIED_PRICE oldPrice = m_applied_price;
   m_applied_price = price;

   Deinitialize();
   bool success = Initialize();

   if(success)
     {
      string msg = "🔄 [RSI] Applied price alterado (reiniciado)";
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD", msg);
      else
         Print(msg);
     }

   return success;
  }

//+------------------------------------------------------------------+
//| Getters                                                           |
//+------------------------------------------------------------------+
double CRSIStrategy::GetCurrentRSI()
  {
   return GetRSI(m_signal_shift);
  }

double CRSIStrategy::GetRSI(int shift)
  {
   if(!LoadRSIValues(shift + 2))
      return 0.0;

   return m_rsi_buffer[shift];
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string CRSIStrategy::GetSignalModeText()
  {
   switch(m_signal_mode)
     {
      case RSI_MODE_CROSSOVER:
         return "Crossover";
      case RSI_MODE_ZONE:
         return "Zone";
      case RSI_MODE_MIDDLE:
         return "Middle";
      default:
         return "Unknown";
     }
  }
//+------------------------------------------------------------------+
