//+------------------------------------------------------------------+
//|                                        BollingerBandsStrategy.mqh |
//|                                         Copyright 2026, EP Filho |
//|                            Estratégia Bollinger Bands - EPBot Matrix |
//|                                   Versão 1.00 - Claude Parte 026 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "1.01"
#property strict

// ═══════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════
#include "../../Core/Logger.mqh"
#include "../Base/StrategyBase.mqh"

// ═══════════════════════════════════════════════════════════════
// CHANGELOG
// v1.00 (Parte 026):
// + Estratégia Bollinger Bands com 3 modos de operação:
//   - BB_MODE_FFFD: Fechou Fora, Fechou Dentro (reversão confirmada)
//     Candle[2] fecha fora da banda, Candle[1] fecha de volta para dentro
//   - BB_MODE_REBOUND: Toque + reversão na banda (mais agressivo)
//     Candle[1] tocou a banda e reverteu (close dentro)
//   - BB_MODE_BREAKOUT: Rompimento da banda (trend-following)
//     Candle[1] fecha fora da banda → sinal na direção do rompimento
// + Indicador iBands() com período, desvio, applied price, timeframe
// + Suporte a entry mode (NEXT_CANDLE / E2C) e exit mode (FCO/VM/TP_SL)
// + FCO em BB: sai quando preço cruza a banda central (middle)
// + Hot/Cold reload completo seguindo padrão Matrix
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Enumeração de Modos de Sinal BB                                  |
//+------------------------------------------------------------------+
enum ENUM_BB_SIGNAL_MODE
  {
   BB_MODE_FFFD     = 0,    // FFFD: Fechou Fora, Fechou Dentro (reversão confirmada)
   BB_MODE_REBOUND  = 1,    // Rebound: Toque + reversão na banda
   BB_MODE_BREAKOUT = 2     // Breakout: Rompimento da banda
  };

//+------------------------------------------------------------------+
//| Classe Bollinger Bands Strategy                                  |
//+------------------------------------------------------------------+
class CBollingerBandsStrategy : public CStrategyBase
  {
private:
   // ═══════════════════════════════════════════════════════════
   // LOGGER
   // ═══════════════════════════════════════════════════════════
   CLogger*          m_logger;

   // ═══════════════════════════════════════════════════════════
   // HANDLES E BUFFERS (não duplica - são internos)
   // ═══════════════════════════════════════════════════════════
   int               m_bands_handle;
   double            m_upper[];    // Banda superior (buffer 1)
   double            m_lower[];    // Banda inferior (buffer 2)
   double            m_middle[];   // Banda central (buffer 0)

   // ═══════════════════════════════════════════════════════════
   // INPUT PARAMETERS - FRIOS (valores originais - requerem reinit)
   // ═══════════════════════════════════════════════════════════
   string            m_inputSymbol;
   ENUM_TIMEFRAMES   m_inputTimeframe;
   int               m_inputPeriod;
   double            m_inputDeviation;
   ENUM_APPLIED_PRICE m_inputAppliedPrice;

   // ═══════════════════════════════════════════════════════════
   // WORKING PARAMETERS - FRIOS (valores usados - requerem reinit)
   // ═══════════════════════════════════════════════════════════
   string            m_symbol;
   ENUM_TIMEFRAMES   m_timeframe;
   int               m_period;
   double            m_deviation;
   ENUM_APPLIED_PRICE m_applied_price;

   // ═══════════════════════════════════════════════════════════
   // INPUT PARAMETERS - QUENTES (valores originais - não requerem reinit)
   // ═══════════════════════════════════════════════════════════
   ENUM_BB_SIGNAL_MODE m_inputSignalMode;
   ENUM_ENTRY_MODE   m_inputEntryMode;
   ENUM_EXIT_MODE    m_inputExitMode;
   bool              m_inputEnabled;

   // ═══════════════════════════════════════════════════════════
   // WORKING PARAMETERS - QUENTES (valores usados - não requerem reinit)
   // ═══════════════════════════════════════════════════════════
   ENUM_BB_SIGNAL_MODE m_signal_mode;
   ENUM_ENTRY_MODE   m_entryMode;
   ENUM_EXIT_MODE    m_exitMode;
   // m_enabled: herdado de CStrategyBase

   // ═══════════════════════════════════════════════════════════
   // ESTADO INTERNO - E2C (controle de candle)
   // ═══════════════════════════════════════════════════════════
   ENUM_SIGNAL_TYPE  m_lastBBSignal;       // Último sinal BB detectado
   int               m_candlesAfterSignal; // Candles após detecção
   datetime          m_lastCheckBarTime;   // Controle de candle para E2C

   // ═══════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS
   // ═══════════════════════════════════════════════════════════
   bool              LoadBandsValues(int count);
   ENUM_SIGNAL_TYPE  CheckFFFDSignal();
   ENUM_SIGNAL_TYPE  CheckReboundSignal();
   ENUM_SIGNAL_TYPE  CheckBreakoutSignal();
   ENUM_SIGNAL_TYPE  CheckExitSignal(ENUM_POSITION_TYPE currentPosition);
   void              ResetSignalControl();

public:
   // ═══════════════════════════════════════════════════════════
   // CONSTRUTOR E DESTRUTOR
   // ═══════════════════════════════════════════════════════════
                     CBollingerBandsStrategy(int priority = 3);
                    ~CBollingerBandsStrategy();

   // ═══════════════════════════════════════════════════════════
   // SETUP (chamado ANTES do Initialize)
   // ═══════════════════════════════════════════════════════════
   bool              Setup(CLogger* logger, string symbol, ENUM_TIMEFRAMES timeframe,
                           int period, double deviation, ENUM_APPLIED_PRICE applied_price,
                           ENUM_BB_SIGNAL_MODE signal_mode,
                           ENUM_ENTRY_MODE entryMode, ENUM_EXIT_MODE exitMode);

   // ═══════════════════════════════════════════════════════════
   // IMPLEMENTAÇÃO DOS MÉTODOS VIRTUAIS (obrigatórios)
   // ═══════════════════════════════════════════════════════════
   virtual bool      Initialize() override;
   virtual void      Deinitialize() override;
   virtual ENUM_SIGNAL_TYPE GetSignal() override;

   //+------------------------------------------------------------------+
   //| Obter sinal de SAÍDA                                             |
   //+------------------------------------------------------------------+
   virtual ENUM_SIGNAL_TYPE GetExitSignal(ENUM_POSITION_TYPE currentPosition) override
     {
      if(!m_isInitialized || !m_enabled)
         return SIGNAL_NONE;

      // EXIT_TP_SL: Strategy NÃO gerencia saída
      if(m_exitMode == EXIT_TP_SL)
         return SIGNAL_NONE;

      // EXIT_FCO ou EXIT_VM: Strategy gerencia saída
      return CheckExitSignal(currentPosition);
     }

   virtual bool      UpdateHotParameters() override;
   virtual bool      UpdateColdParameters() override;

   // ═══════════════════════════════════════════════════════════
   // HOT RELOAD - Parâmetros quentes (sem reiniciar indicadores)
   // ═══════════════════════════════════════════════════════════
   void              SetSignalMode(ENUM_BB_SIGNAL_MODE mode);
   bool              SetEntryMode(ENUM_ENTRY_MODE mode);
   bool              SetExitMode(ENUM_EXIT_MODE mode);
   virtual void      SetEnabled(bool value) override;

   // ═══════════════════════════════════════════════════════════
   // COLD RELOAD - Parâmetros frios (reinicia indicadores)
   // ═══════════════════════════════════════════════════════════
   bool              SetPeriod(int value);
   bool              SetDeviation(double value);
   bool              SetTimeframe(ENUM_TIMEFRAMES tf);
   bool              SetAppliedPrice(ENUM_APPLIED_PRICE price);

   // ═══════════════════════════════════════════════════════════
   // GETTERS - Working values (valores atuais em uso)
   // ═══════════════════════════════════════════════════════════
   double            GetUpperBand(int shift = 1);
   double            GetLowerBand(int shift = 1);
   double            GetMiddleBand(int shift = 1);
   double            GetBandWidth();
   string            GetSignalModeText();

   int               GetPeriod() const { return m_period; }
   double            GetDeviation() const { return m_deviation; }
   ENUM_TIMEFRAMES   GetTimeframe() const { return m_timeframe; }
   ENUM_APPLIED_PRICE GetAppliedPrice() const { return m_applied_price; }
   ENUM_BB_SIGNAL_MODE GetSignalMode() const { return m_signal_mode; }
   ENUM_ENTRY_MODE   GetEntryMode() const { return m_entryMode; }
   ENUM_EXIT_MODE    GetExitMode() const { return m_exitMode; }
   // GetEnabled(): herdado de CStrategyBase

   // ═══════════════════════════════════════════════════════════
   // GETTERS - Input values (valores originais da configuração)
   // ═══════════════════════════════════════════════════════════
   int               GetInputPeriod() const { return m_inputPeriod; }
   double            GetInputDeviation() const { return m_inputDeviation; }
   ENUM_TIMEFRAMES   GetInputTimeframe() const { return m_inputTimeframe; }
   ENUM_APPLIED_PRICE GetInputAppliedPrice() const { return m_inputAppliedPrice; }
   ENUM_BB_SIGNAL_MODE GetInputSignalMode() const { return m_inputSignalMode; }
   ENUM_ENTRY_MODE   GetInputEntryMode() const { return m_inputEntryMode; }
   ENUM_EXIT_MODE    GetInputExitMode() const { return m_inputExitMode; }
   bool              GetInputEnabled() const { return m_inputEnabled; }
  };

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CBollingerBandsStrategy::CBollingerBandsStrategy(int priority = 3) : CStrategyBase("BB Strategy", priority)
  {
   m_logger = NULL;
   m_bands_handle = INVALID_HANDLE;

// ═══ INPUT PARAMETERS (valores padrão) ═══
   m_inputSymbol = "";
   m_inputTimeframe = PERIOD_CURRENT;
   m_inputPeriod = 20;
   m_inputDeviation = 2.0;
   m_inputAppliedPrice = PRICE_CLOSE;
   m_inputSignalMode = BB_MODE_FFFD;
   m_inputEntryMode = ENTRY_NEXT_CANDLE;
   m_inputExitMode = EXIT_TP_SL;
   m_inputEnabled = true;

// ═══ WORKING PARAMETERS (começam iguais aos inputs) ═══
   m_symbol = "";
   m_timeframe = PERIOD_CURRENT;
   m_period = 20;
   m_deviation = 2.0;
   m_applied_price = PRICE_CLOSE;
   m_signal_mode = BB_MODE_FFFD;
   m_entryMode = ENTRY_NEXT_CANDLE;
   m_exitMode = EXIT_TP_SL;

// ═══ ESTADO INTERNO ═══
   m_lastBBSignal = SIGNAL_NONE;
   m_candlesAfterSignal = 0;
   m_lastCheckBarTime = 0;

   ArraySetAsSeries(m_upper, true);
   ArraySetAsSeries(m_lower, true);
   ArraySetAsSeries(m_middle, true);
  }

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CBollingerBandsStrategy::~CBollingerBandsStrategy()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Setup (configuração inicial)                                     |
//+------------------------------------------------------------------+
bool CBollingerBandsStrategy::Setup(CLogger* logger, string symbol, ENUM_TIMEFRAMES timeframe,
                                     int period, double deviation, ENUM_APPLIED_PRICE applied_price,
                                     ENUM_BB_SIGNAL_MODE signal_mode,
                                     ENUM_ENTRY_MODE entryMode, ENUM_EXIT_MODE exitMode)
  {
   m_logger = logger;

// ═══════════════════════════════════════════════════════════
// SALVAR INPUT PARAMETERS (valores originais)
// ═══════════════════════════════════════════════════════════
   m_inputSymbol = symbol;
   m_inputTimeframe = (timeframe == PERIOD_CURRENT) ? Period() : timeframe;
   m_inputPeriod = period;
   m_inputDeviation = deviation;
   m_inputAppliedPrice = applied_price;
   m_inputSignalMode = signal_mode;
   m_inputEntryMode = entryMode;
   m_inputExitMode = exitMode;
   // m_inputEnabled: não forçado — preserva estado antes do Setup()

// ═══════════════════════════════════════════════════════════
// INICIALIZAR WORKING PARAMETERS (começam iguais aos inputs)
// ═══════════════════════════════════════════════════════════
   m_symbol = symbol;
   m_timeframe = (timeframe == PERIOD_CURRENT) ? Period() : timeframe;
   m_period = period;
   m_deviation = deviation;
   m_applied_price = applied_price;
   m_signal_mode = signal_mode;
   m_entryMode = entryMode;
   m_exitMode = exitMode;
   // m_enabled: não forçado — preserva estado do toggle

   return true;
  }

//+------------------------------------------------------------------+
//| Initialize (criar handles)                                       |
//+------------------------------------------------------------------+
bool CBollingerBandsStrategy::Initialize()
  {
   if(m_isInitialized)
      return true;

   m_bands_handle = iBands(m_symbol, m_timeframe, m_period, 0, m_deviation, m_applied_price);

   if(m_bands_handle == INVALID_HANDLE)
     {
      string msg = "[" + m_strategyName + "] Erro ao criar indicador Bollinger Bands";
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   m_isInitialized = true;
   ResetSignalControl();

   string msg = "✅ [" + m_strategyName + "] Inicializado [" + m_symbol + " | " +
                EnumToString(m_timeframe) + " | Período: " + IntegerToString(m_period) +
                " | Desvio: " + DoubleToString(m_deviation, 1) +
                " | Modo: " + GetSignalModeText() + "]";
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", msg);
   else
      Print(msg);

   return true;
  }

//+------------------------------------------------------------------+
//| Deinitialize (liberar handles)                                   |
//+------------------------------------------------------------------+
void CBollingerBandsStrategy::Deinitialize()
  {
   if(m_bands_handle != INVALID_HANDLE)
     {
      IndicatorRelease(m_bands_handle);
      m_bands_handle = INVALID_HANDLE;
     }

   m_isInitialized = false;
  }

//+------------------------------------------------------------------+
//| UpdateHotParameters (params sem reinicialização)                 |
//+------------------------------------------------------------------+
bool CBollingerBandsStrategy::UpdateHotParameters()
  {
// Parâmetros quentes já são atualizados via setters
   return true;
  }

//+------------------------------------------------------------------+
//| UpdateColdParameters (params que precisam reinicializar)         |
//+------------------------------------------------------------------+
bool CBollingerBandsStrategy::UpdateColdParameters()
  {
   Deinitialize();
   return Initialize();
  }

//+------------------------------------------------------------------+
//| Carregar valores das Bandas de Bollinger                         |
//+------------------------------------------------------------------+
bool CBollingerBandsStrategy::LoadBandsValues(int count)
  {
   if(m_bands_handle == INVALID_HANDLE)
      return false;

   // Buffer 0 = Middle, Buffer 1 = Upper, Buffer 2 = Lower
   if(CopyBuffer(m_bands_handle, 0, 0, count, m_middle) < count)
     {
      string msg = "[" + m_strategyName + "] Erro ao copiar buffer Middle BB";
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "BUFFER", msg);
      return false;
     }

   if(CopyBuffer(m_bands_handle, 1, 0, count, m_upper) < count)
     {
      string msg = "[" + m_strategyName + "] Erro ao copiar buffer Upper BB";
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "BUFFER", msg);
      return false;
     }

   if(CopyBuffer(m_bands_handle, 2, 0, count, m_lower) < count)
     {
      string msg = "[" + m_strategyName + "] Erro ao copiar buffer Lower BB";
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "BUFFER", msg);
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| ResetSignalControl - limpa estado E2C                            |
//+------------------------------------------------------------------+
void CBollingerBandsStrategy::ResetSignalControl()
  {
   m_lastBBSignal = SIGNAL_NONE;
   m_candlesAfterSignal = 0;
   m_lastCheckBarTime = 0;
  }

//+------------------------------------------------------------------+
//| GetSignal (método principal - OBRIGATÓRIO)                       |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CBollingerBandsStrategy::GetSignal()
  {
   if(!m_isInitialized || !m_enabled)
      return SIGNAL_NONE;

   if(!LoadBandsValues(4))
      return SIGNAL_NONE;

// ═══════════════════════════════════════════════════════════
// Modo E2C - Incrementar apenas 1x por candle
// ═══════════════════════════════════════════════════════════
   if(m_entryMode == ENTRY_2ND_CANDLE && m_lastBBSignal != SIGNAL_NONE)
     {
      datetime currentBarTime = iTime(m_symbol, m_timeframe, 0);
      if(currentBarTime != m_lastCheckBarTime)
        {
         m_lastCheckBarTime = currentBarTime;
         m_candlesAfterSignal++;

         if(m_candlesAfterSignal >= 2)
           {
            string msg = "🎯 [BB] 2º candle após sinal - gerando sinal (E2C)";
            if(m_logger != NULL)
               m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
            ENUM_SIGNAL_TYPE sig = m_lastBBSignal;
            ResetSignalControl();
            return sig;
           }
         else
           {
            string msg = "⏳ [BB] E2C: Candle " + IntegerToString(m_candlesAfterSignal) + " após sinal";
            if(m_logger != NULL)
               m_logger.Log(LOG_DEBUG, THROTTLE_CANDLE, "SIGNAL", msg);
           }
        }
      return SIGNAL_NONE;
     }

// ═══════════════════════════════════════════════════════════
// Detecção do sinal conforme modo
// ═══════════════════════════════════════════════════════════
   ENUM_SIGNAL_TYPE signal = SIGNAL_NONE;

   switch(m_signal_mode)
     {
      case BB_MODE_FFFD:
         signal = CheckFFFDSignal();
         break;

      case BB_MODE_REBOUND:
         signal = CheckReboundSignal();
         break;

      case BB_MODE_BREAKOUT:
         signal = CheckBreakoutSignal();
         break;

      default:
         return SIGNAL_NONE;
     }

// ═══════════════════════════════════════════════════════════
// Modo E2C - Armazenar sinal e aguardar
// ═══════════════════════════════════════════════════════════
   if(signal != SIGNAL_NONE && m_entryMode == ENTRY_2ND_CANDLE)
     {
      m_lastBBSignal = signal;
      m_candlesAfterSignal = 0;
      m_lastCheckBarTime = iTime(m_symbol, m_timeframe, 0);
      string msg = "⏳ [BB] Sinal detectado - aguardando 2º candle (E2C)";
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      return SIGNAL_NONE;
     }

   return signal;
  }

//+------------------------------------------------------------------+
//| Modo FFFD: Fechou Fora, Fechou Dentro                            |
//| Candle[2] fecha FORA da banda                                    |
//| Candle[1] fecha DE VOLTA para dentro                             |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CBollingerBandsStrategy::CheckFFFDSignal()
  {
   double close1 = iClose(m_symbol, m_timeframe, 1);  // Candle fechado (atual)
   double close2 = iClose(m_symbol, m_timeframe, 2);  // Candle anterior

// BUY: Candle[2] fechou ABAIXO da banda inferior, Candle[1] fechou ACIMA (voltou para dentro)
   if(close2 < m_lower[2] && close1 >= m_lower[1])
     {
      string msg = StringFormat("🎯 [BB] COMPRA (FFFD) - Close[2]: %.5f < Lower[2]: %.5f | Close[1]: %.5f >= Lower[1]: %.5f",
                                close2, m_lower[2], close1, m_lower[1]);
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      else
         Print(msg);
      return SIGNAL_BUY;
     }

// SELL: Candle[2] fechou ACIMA da banda superior, Candle[1] fechou ABAIXO (voltou para dentro)
   if(close2 > m_upper[2] && close1 <= m_upper[1])
     {
      string msg = StringFormat("🎯 [BB] VENDA (FFFD) - Close[2]: %.5f > Upper[2]: %.5f | Close[1]: %.5f <= Upper[1]: %.5f",
                                close2, m_upper[2], close1, m_upper[1]);
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      else
         Print(msg);
      return SIGNAL_SELL;
     }

   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| Modo REBOUND: Toque + reversão na banda                          |
//| Candle[1] tocou (low/high cruzou a banda) mas fechou dentro      |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CBollingerBandsStrategy::CheckReboundSignal()
  {
   double close1 = iClose(m_symbol, m_timeframe, 1);
   double low1   = iLow(m_symbol, m_timeframe, 1);
   double high1  = iHigh(m_symbol, m_timeframe, 1);

// BUY: Low tocou/cruzou banda inferior, mas close ficou dentro
   if(low1 <= m_lower[1] && close1 > m_lower[1])
     {
      string msg = StringFormat("🎯 [BB] COMPRA (Rebound) - Low: %.5f <= Lower: %.5f | Close: %.5f dentro",
                                low1, m_lower[1], close1);
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      else
         Print(msg);
      return SIGNAL_BUY;
     }

// SELL: High tocou/cruzou banda superior, mas close ficou dentro
   if(high1 >= m_upper[1] && close1 < m_upper[1])
     {
      string msg = StringFormat("🎯 [BB] VENDA (Rebound) - High: %.5f >= Upper: %.5f | Close: %.5f dentro",
                                high1, m_upper[1], close1);
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      else
         Print(msg);
      return SIGNAL_SELL;
     }

   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| Modo BREAKOUT: Rompimento da banda                               |
//| Candle[1] fecha FORA da banda → sinal na direção do rompimento   |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CBollingerBandsStrategy::CheckBreakoutSignal()
  {
   double close1 = iClose(m_symbol, m_timeframe, 1);

// BUY: Close acima da banda superior → breakout para cima
   if(close1 > m_upper[1])
     {
      string msg = StringFormat("🎯 [BB] COMPRA (Breakout) - Close: %.5f > Upper: %.5f",
                                close1, m_upper[1]);
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      else
         Print(msg);
      return SIGNAL_BUY;
     }

// SELL: Close abaixo da banda inferior → breakout para baixo
   if(close1 < m_lower[1])
     {
      string msg = StringFormat("🎯 [BB] VENDA (Breakout) - Close: %.5f < Lower: %.5f",
                                close1, m_lower[1]);
      if(m_logger != NULL)
         m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
      else
         Print(msg);
      return SIGNAL_SELL;
     }

   return SIGNAL_NONE;
  }

//+------------------------------------------------------------------+
//| CheckExitSignal - FCO (cruza middle) ou VM (sinal oposto)        |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CBollingerBandsStrategy::CheckExitSignal(ENUM_POSITION_TYPE currentPosition)
  {
   if(!LoadBandsValues(3))
      return SIGNAL_NONE;

   double close1 = iClose(m_symbol, m_timeframe, 1);
   double close2 = iClose(m_symbol, m_timeframe, 2);

   if(m_exitMode == EXIT_FCO)
     {
      // FCO para BB: sai quando preço cruza a banda central (middle)
      if(currentPosition == POSITION_TYPE_BUY)
        {
         // Posição BUY: sai se close cruza middle de cima para baixo
         if(close2 >= m_middle[2] && close1 < m_middle[1])
           {
            string msg = "🔄 [BB] EXIT (FCO) - Close cruzou middle para baixo";
            if(m_logger != NULL)
               m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
            return SIGNAL_SELL;
           }
        }
      else if(currentPosition == POSITION_TYPE_SELL)
        {
         // Posição SELL: sai se close cruza middle de baixo para cima
         if(close2 <= m_middle[2] && close1 > m_middle[1])
           {
            string msg = "🔄 [BB] EXIT (FCO) - Close cruzou middle para cima";
            if(m_logger != NULL)
               m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
            return SIGNAL_BUY;
           }
        }
     }
   else if(m_exitMode == EXIT_VM)
     {
      // VM: verifica se há sinal oposto (usa o mesmo modo de sinal)
      ENUM_SIGNAL_TYPE signal = SIGNAL_NONE;

      switch(m_signal_mode)
        {
         case BB_MODE_FFFD:
            signal = CheckFFFDSignal();
            break;
         case BB_MODE_REBOUND:
            signal = CheckReboundSignal();
            break;
         case BB_MODE_BREAKOUT:
            signal = CheckBreakoutSignal();
            break;
        }

      if(signal != SIGNAL_NONE)
        {
         if((currentPosition == POSITION_TYPE_BUY && signal == SIGNAL_SELL) ||
            (currentPosition == POSITION_TYPE_SELL && signal == SIGNAL_BUY))
           {
            string msg = "🔄 [BB] EXIT (VM) - Sinal oposto detectado";
            if(m_logger != NULL)
               m_logger.Log(LOG_SIGNAL, THROTTLE_CANDLE, "SIGNAL", msg);
            return signal;
           }
        }
     }

   return SIGNAL_NONE;
  }

// ═══════════════════════════════════════════════════════════════
// HOT RELOAD - MÉTODOS SET QUENTES
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar modo de sinal                               |
//+------------------------------------------------------------------+
void CBollingerBandsStrategy::SetSignalMode(ENUM_BB_SIGNAL_MODE mode)
  {
   ENUM_BB_SIGNAL_MODE oldMode = m_signal_mode;
   if(oldMode == mode) return;
   m_signal_mode = mode;
   ResetSignalControl();

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "🔄 [BB] Modo alterado: " + GetSignalModeText());
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar modo de entrada                             |
//+------------------------------------------------------------------+
bool CBollingerBandsStrategy::SetEntryMode(ENUM_ENTRY_MODE mode)
  {
   ENUM_ENTRY_MODE oldMode = m_entryMode;
   if(oldMode == mode) return true;
   m_entryMode = mode;
   ResetSignalControl();

   string oldStr = (oldMode == ENTRY_NEXT_CANDLE) ? "NEXT_CANDLE" : "E2C";
   string newStr = (mode == ENTRY_NEXT_CANDLE) ? "NEXT_CANDLE" : "E2C";

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "🔄 [BB] Entry mode alterado: " + oldStr + " → " + newStr);

   return true;
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar modo de saída                               |
//+------------------------------------------------------------------+
bool CBollingerBandsStrategy::SetExitMode(ENUM_EXIT_MODE mode)
  {
   ENUM_EXIT_MODE oldMode = m_exitMode;
   if(oldMode == mode) return true;
   m_exitMode = mode;

   string oldStr, newStr;
   switch(oldMode)
     { case EXIT_FCO: oldStr = "FCO"; break; case EXIT_VM: oldStr = "VM"; break; default: oldStr = "TP/SL"; break; }
   switch(mode)
     { case EXIT_FCO: newStr = "FCO"; break; case EXIT_VM: newStr = "VM"; break; default: newStr = "TP/SL"; break; }

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "🔄 [BB] Exit mode alterado: " + oldStr + " → " + newStr);

   return true;
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Ativar/desativar estratégia                         |
//+------------------------------------------------------------------+
void CBollingerBandsStrategy::SetEnabled(bool value)
  {
   bool oldValue = m_enabled;
   m_enabled = value;

   if(oldValue != value && m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "🔄 [BB] Estratégia: " + (value ? "ATIVADA" : "DESATIVADA"));
  }

// ═══════════════════════════════════════════════════════════════
// COLD RELOAD - MÉTODOS SET FRIOS
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar período (reinicia indicador)               |
//+------------------------------------------------------------------+
bool CBollingerBandsStrategy::SetPeriod(int value)
  {
   if(value <= 0)
     {
      string msg = "[BB] Período inválido: " + IntegerToString(value);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "COLD_RELOAD", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   int oldValue = m_period;
   if(oldValue == value) return true;
   m_period = value;

   Deinitialize();
   bool success = Initialize();

   if(success && m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         StringFormat("🔄 [BB] Período alterado: %d → %d (reiniciado)", oldValue, value));

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar desvio padrão (reinicia indicador)         |
//+------------------------------------------------------------------+
bool CBollingerBandsStrategy::SetDeviation(double value)
  {
   if(value <= 0)
     {
      string msg = "[BB] Desvio inválido: " + DoubleToString(value, 2);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "COLD_RELOAD", msg);
      return false;
     }

   double oldValue = m_deviation;
   if(oldValue == value) return true;
   m_deviation = value;

   Deinitialize();
   bool success = Initialize();

   if(success && m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         StringFormat("🔄 [BB] Desvio alterado: %.1f → %.1f (reiniciado)", oldValue, value));

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar timeframe (reinicia indicador)             |
//+------------------------------------------------------------------+
bool CBollingerBandsStrategy::SetTimeframe(ENUM_TIMEFRAMES tf)
  {
   ENUM_TIMEFRAMES oldTF = m_timeframe;
   if(oldTF == tf) return true;
   m_timeframe = tf;

   Deinitialize();
   bool success = Initialize();

   if(success && m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         "🔄 [BB] Timeframe alterado: " + EnumToString(oldTF) + " → " + EnumToString(tf) + " (reiniciado)");

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar applied price (reinicia indicador)         |
//+------------------------------------------------------------------+
bool CBollingerBandsStrategy::SetAppliedPrice(ENUM_APPLIED_PRICE price)
  {
   if(m_applied_price == price) return true;
   m_applied_price = price;

   Deinitialize();
   bool success = Initialize();

   if(success && m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         "🔄 [BB] Applied price alterado (reiniciado)");

   return success;
  }

// ═══════════════════════════════════════════════════════════════
// GETTERS
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Banda superior no shift especificado                             |
//+------------------------------------------------------------------+
double CBollingerBandsStrategy::GetUpperBand(int shift = 1)
  {
   if(!LoadBandsValues(shift + 2))
      return 0.0;
   return m_upper[shift];
  }

//+------------------------------------------------------------------+
//| Banda inferior no shift especificado                             |
//+------------------------------------------------------------------+
double CBollingerBandsStrategy::GetLowerBand(int shift = 1)
  {
   if(!LoadBandsValues(shift + 2))
      return 0.0;
   return m_lower[shift];
  }

//+------------------------------------------------------------------+
//| Banda central no shift especificado                              |
//+------------------------------------------------------------------+
double CBollingerBandsStrategy::GetMiddleBand(int shift = 1)
  {
   if(!LoadBandsValues(shift + 2))
      return 0.0;
   return m_middle[shift];
  }

//+------------------------------------------------------------------+
//| Largura das bandas (upper - lower) em shift=1                    |
//+------------------------------------------------------------------+
double CBollingerBandsStrategy::GetBandWidth()
  {
   if(!LoadBandsValues(3))
      return 0.0;
   return m_upper[1] - m_lower[1];
  }

//+------------------------------------------------------------------+
//| Texto do modo de sinal                                           |
//+------------------------------------------------------------------+
string CBollingerBandsStrategy::GetSignalModeText()
  {
   switch(m_signal_mode)
     {
      case BB_MODE_FFFD:
         return "FFFD";
      case BB_MODE_REBOUND:
         return "Rebound";
      case BB_MODE_BREAKOUT:
         return "Breakout";
      default:
         return "Unknown";
     }
  }
//+------------------------------------------------------------------+
