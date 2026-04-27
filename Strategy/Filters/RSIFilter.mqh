//+------------------------------------------------------------------+
//|                                                    RSIFilter.mqh |
//|                                         Copyright 2026, EP Filho |
//|                                        Filtro RSI - EPBot Matrix |
//|                                   Versão 1.14 - Claude Parte 035 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "1.14"
// Changelog: ver CHANGELOG.md
#property strict

// ═══════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════
#include "../../Core/Logger.mqh"
#include "../Base/FilterBase.mqh"

// (Histórico de versões em CHANGELOG.md)

//+------------------------------------------------------------------+
//| Enumeração de Modos de Filtro RSI                                |
//+------------------------------------------------------------------+
enum ENUM_RSI_FILTER_MODE
{
   RSI_FILTER_ZONE = 0,        // Zona: bloqueia em extremos
   RSI_FILTER_DIRECTION = 1,   // Direcional: permite apenas se RSI aponta na direção
   RSI_FILTER_NEUTRAL = 2      // Neutro: permite apenas se RSI está em zona neutra
};

//+------------------------------------------------------------------+
//| Classe RSI Filter                                                |
//+------------------------------------------------------------------+
class CRSIFilter : public CFilterBase
{
private:
   // ═══════════════════════════════════════════════════════════
   // LOGGER
   // ═══════════════════════════════════════════════════════════
   CLogger* m_logger;

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
   ENUM_RSI_FILTER_MODE m_inputFilterMode;
   double            m_inputOversold;
   double            m_inputOverbought;
   double            m_inputLowerNeutral;
   double            m_inputUpperNeutral;
   int               m_inputShift;
   
   // ═══════════════════════════════════════════════════════════
   // WORKING PARAMETERS - QUENTES (valores usados - não requerem reinit)
   // ═══════════════════════════════════════════════════════════
   ENUM_RSI_FILTER_MODE m_filter_mode;
   double            m_oversold;
   double            m_overbought;
   double            m_lower_neutral;
   double            m_upper_neutral;
   int               m_shift;
   
   // ═══════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS
   // ═══════════════════════════════════════════════════════════
   bool LoadRSIValues(int count);
   bool CheckZoneFilter(ENUM_SIGNAL_TYPE signal);
   bool CheckDirectionFilter(ENUM_SIGNAL_TYPE signal);
   bool CheckNeutralFilter(ENUM_SIGNAL_TYPE signal);

public:
   // ═══════════════════════════════════════════════════════════
   // CONSTRUTOR E DESTRUTOR
   // ═══════════════════════════════════════════════════════════
   CRSIFilter();
   ~CRSIFilter();
   
   // ═══════════════════════════════════════════════════════════
   // SETUP (chamado ANTES do Initialize)
   // ═══════════════════════════════════════════════════════════
   bool Setup(CLogger* logger, string symbol, ENUM_TIMEFRAMES timeframe, int period,
              ENUM_APPLIED_PRICE applied_price, ENUM_RSI_FILTER_MODE filter_mode,
              double oversold, double overbought, 
              double lower_neutral, double upper_neutral, int shift);
   
   // ═══════════════════════════════════════════════════════════
   // IMPLEMENTAÇÃO DOS MÉTODOS VIRTUAIS (obrigatórios)
   // ═══════════════════════════════════════════════════════════
   virtual bool Initialize() override;
   virtual void Deinitialize() override;
   virtual bool ValidateSignal(ENUM_SIGNAL_TYPE signal) override;
   virtual bool UpdateHotParameters() override;
   virtual bool UpdateColdParameters() override;
   
   // ═══════════════════════════════════════════════════════════
   // HOT RELOAD - Parâmetros quentes (sem reiniciar indicadores)
   // ═══════════════════════════════════════════════════════════
   virtual void SetEnabled(bool enabled) override; // v1.12 — log se mudar
   void SetFilterMode(ENUM_RSI_FILTER_MODE mode);
   void SetOversold(double value);
   void SetOverbought(double value);
   void SetLowerNeutral(double value);
   void SetUpperNeutral(double value);
   void SetShift(int value);
   
   // ═══════════════════════════════════════════════════════════
   // COLD RELOAD - Parâmetros frios (reinicia indicadores)
   // ═══════════════════════════════════════════════════════════
   bool SetPeriod(int value);
   bool SetTimeframe(ENUM_TIMEFRAMES tf);
   bool SetAppliedPrice(ENUM_APPLIED_PRICE price);
   
   // ═══════════════════════════════════════════════════════════
   // GETTERS - Working values (valores atuais em uso)
   // ═══════════════════════════════════════════════════════════
   double GetCurrentRSI();
   double GetRSI(int shift);
   string GetFilterModeText();
   string GetFilterStatus(ENUM_SIGNAL_TYPE signal);
   
   int GetPeriod() const { return m_period; }
   ENUM_TIMEFRAMES GetTimeframe() const { return m_timeframe; }
   ENUM_APPLIED_PRICE GetAppliedPrice() const { return m_applied_price; }
   ENUM_RSI_FILTER_MODE GetFilterMode() const { return m_filter_mode; }
   double GetOversold() const { return m_oversold; }
   double GetOverbought() const { return m_overbought; }
   double GetLowerNeutral() const { return m_lower_neutral; }
   double GetUpperNeutral() const { return m_upper_neutral; }
   int GetShift() const { return m_shift; }
   
   // ═══════════════════════════════════════════════════════════
   // GETTERS - Input values (valores originais da configuração)
   // ═══════════════════════════════════════════════════════════
   int GetInputPeriod() const { return m_inputPeriod; }
   ENUM_TIMEFRAMES GetInputTimeframe() const { return m_inputTimeframe; }
   ENUM_APPLIED_PRICE GetInputAppliedPrice() const { return m_inputAppliedPrice; }
   ENUM_RSI_FILTER_MODE GetInputFilterMode() const { return m_inputFilterMode; }
   double GetInputOversold() const { return m_inputOversold; }
   double GetInputOverbought() const { return m_inputOverbought; }
   double GetInputLowerNeutral() const { return m_inputLowerNeutral; }
   double GetInputUpperNeutral() const { return m_inputUpperNeutral; }
   int GetInputShift() const { return m_inputShift; }
};

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CRSIFilter::CRSIFilter() : CFilterBase("RSI Filter")
{
   m_logger = NULL;
   m_rsi_handle = INVALID_HANDLE;
   
   // ═══ INPUT PARAMETERS (valores padrão) ═══
   m_inputSymbol = "";
   m_inputTimeframe = PERIOD_CURRENT;
   m_inputPeriod = 14;
   m_inputAppliedPrice = PRICE_CLOSE;
   m_inputFilterMode = RSI_FILTER_ZONE;
   m_inputOversold = 30.0;
   m_inputOverbought = 70.0;
   m_inputLowerNeutral = 40.0;
   m_inputUpperNeutral = 60.0;
   m_inputShift = 0;
   
   // ═══ WORKING PARAMETERS (começam iguais aos inputs) ═══
   m_symbol = "";
   m_timeframe = PERIOD_CURRENT;
   m_period = 14;
   m_applied_price = PRICE_CLOSE;
   m_filter_mode = RSI_FILTER_ZONE;
   m_oversold = 30.0;
   m_overbought = 70.0;
   m_lower_neutral = 40.0;
   m_upper_neutral = 60.0;
   m_shift = 0;
   
   ArraySetAsSeries(m_rsi_buffer, true);
}

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CRSIFilter::~CRSIFilter()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Setup (configuração inicial)                                     |
//+------------------------------------------------------------------+
bool CRSIFilter::Setup(CLogger* logger, string symbol, ENUM_TIMEFRAMES timeframe, int period,
                       ENUM_APPLIED_PRICE applied_price, ENUM_RSI_FILTER_MODE filter_mode,
                       double oversold, double overbought,
                       double lower_neutral, double upper_neutral, int shift)
{
   m_logger = logger;
   
   // ═══════════════════════════════════════════════════════════
   // SALVAR INPUT PARAMETERS (valores originais)
   // ═══════════════════════════════════════════════════════════
   m_inputSymbol = symbol;
   m_inputTimeframe = timeframe;  // Parte 035 — preserva PERIOD_CURRENT
   m_inputPeriod = period;
   m_inputAppliedPrice = applied_price;
   m_inputFilterMode = filter_mode;
   m_inputOversold = oversold;
   m_inputOverbought = overbought;
   m_inputLowerNeutral = lower_neutral;
   m_inputUpperNeutral = upper_neutral;
   m_inputShift = shift;
   
   // ═══════════════════════════════════════════════════════════
   // INICIALIZAR WORKING PARAMETERS (começam iguais aos inputs)
   // ═══════════════════════════════════════════════════════════
   m_symbol = symbol;
   m_timeframe = timeframe;  // Parte 035 — preserva PERIOD_CURRENT
   m_period = period;
   m_applied_price = applied_price;
   m_filter_mode = filter_mode;
   m_oversold = oversold;
   m_overbought = overbought;
   m_lower_neutral = lower_neutral;
   m_upper_neutral = upper_neutral;
   m_shift = shift;
   
   return true;
}

//+------------------------------------------------------------------+
//| Initialize (criar handles) - v1.10                               |
//+------------------------------------------------------------------+
bool CRSIFilter::Initialize()
{
   if(m_isInitialized)
      return true;
   
   m_rsi_handle = iRSI(m_symbol, m_timeframe, m_period, m_applied_price);
   
   if(m_rsi_handle == INVALID_HANDLE)
   {
      m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT",
         "[" + m_filterName + "] Erro ao criar indicador RSI");
      return false;
   }

   m_isInitialized = true;

   m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
      "✅ [" + m_filterName + "] Inicializado [" + m_symbol + " | " +
      EnumToString(m_timeframe) + " | Período: " + IntegerToString(m_period) + " | Modo: " +
      GetFilterModeText() + "]");

   return true;
}

//+------------------------------------------------------------------+
//| Deinitialize (liberar handles)                                   |
//+------------------------------------------------------------------+
void CRSIFilter::Deinitialize()
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
bool CRSIFilter::UpdateHotParameters()
{
   // Parâmetros quentes já são atualizados via setters
   return true;
}

//+------------------------------------------------------------------+
//| UpdateColdParameters (params que precisam reinicializar)         |
//+------------------------------------------------------------------+
bool CRSIFilter::UpdateColdParameters()
{
   Deinitialize();
   return Initialize();
}

//+------------------------------------------------------------------+
//| Carregar valores do RSI - v1.10                                  |
//+------------------------------------------------------------------+
bool CRSIFilter::LoadRSIValues(int count)
{
   if(m_rsi_handle == INVALID_HANDLE)
      return false;
   
   if(CopyBuffer(m_rsi_handle, 0, 0, count, m_rsi_buffer) < count)
   {
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "BUFFER",
         "[" + m_filterName + "] Erro ao copiar buffer RSI (solicitados: " + IntegerToString(count) + ")");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| ValidateSignal (método principal - OBRIGATÓRIO)                  |
//+------------------------------------------------------------------+
bool CRSIFilter::ValidateSignal(ENUM_SIGNAL_TYPE signal)
{
   // Se filtro desabilitado, permite qualquer sinal
   if(!m_isEnabled || !m_isInitialized)
      return true;
   
   if(!LoadRSIValues(m_shift + 2))
      return false;
   
   switch(m_filter_mode)
   {
      case RSI_FILTER_ZONE:
         return CheckZoneFilter(signal);
         
      case RSI_FILTER_DIRECTION:
         return CheckDirectionFilter(signal);
         
      case RSI_FILTER_NEUTRAL:
         return CheckNeutralFilter(signal);
         
      default:
         return true;
   }
}

//+------------------------------------------------------------------+
//| Modo ZONE: Bloqueia trades em zonas extremas - v1.10             |
//+------------------------------------------------------------------+
bool CRSIFilter::CheckZoneFilter(ENUM_SIGNAL_TYPE signal)
{
   double rsi_current = m_rsi_buffer[m_shift];
   
   if(signal == SIGNAL_BUY)
   {
      if(rsi_current >= m_overbought)
      {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
            "🚫 [" + m_filterName + "] BUY bloqueado - RSI em sobrecompra: " +
            DoubleToString(rsi_current, 2));
         return false;
      }
      return true;
   }

   if(signal == SIGNAL_SELL)
   {
      if(rsi_current <= m_oversold)
      {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
            "🚫 [" + m_filterName + "] SELL bloqueado - RSI em sobrevenda: " +
            DoubleToString(rsi_current, 2));
         return false;
      }
      return true;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Modo DIRECTION: Permite trade apenas se RSI aponta na direção - v1.10 |
//+------------------------------------------------------------------+
bool CRSIFilter::CheckDirectionFilter(ENUM_SIGNAL_TYPE signal)
{
   double rsi_current = m_rsi_buffer[m_shift];
   
   if(signal == SIGNAL_BUY)
   {
      if(rsi_current < 50.0)
      {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
            "🚫 [" + m_filterName + "] BUY bloqueado - RSI não indica força compradora: " +
            DoubleToString(rsi_current, 2));
         return false;
      }
      return true;
   }

   if(signal == SIGNAL_SELL)
   {
      if(rsi_current > 50.0)
      {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
            "🚫 [" + m_filterName + "] SELL bloqueado - RSI não indica força vendedora: " +
            DoubleToString(rsi_current, 2));
         return false;
      }
      return true;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Modo NEUTRAL: Permite trade apenas em zona neutra - v1.10        |
//+------------------------------------------------------------------+
bool CRSIFilter::CheckNeutralFilter(ENUM_SIGNAL_TYPE signal)
{
   double rsi_current = m_rsi_buffer[m_shift];
   
   if(rsi_current >= m_lower_neutral && rsi_current <= m_upper_neutral)
   {
      return true;
   }
   
   m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
      "🚫 [" + m_filterName + "] Trade bloqueado - RSI fora da zona neutra: " +
      DoubleToString(rsi_current, 2) + " (zona: " + DoubleToString(m_lower_neutral, 0) +
      " a " + DoubleToString(m_upper_neutral, 0) + ")");
   return false;
}

// ═══════════════════════════════════════════════════════════════
// HOT RELOAD - MÉTODOS SET QUENTES (v1.10)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| HOT RELOAD - Ativar/desativar filtro (v1.12)                     |
//+------------------------------------------------------------------+
void CRSIFilter::SetEnabled(bool enabled)
{
   bool oldValue = m_isEnabled;
   m_isEnabled = enabled;

   if(oldValue != enabled)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "🔄 [RSI Filter] Filtro: " + (enabled ? "ATIVADO" : "DESATIVADO"));
}

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar modo de filtro - v1.10                      |
//+------------------------------------------------------------------+
void CRSIFilter::SetFilterMode(ENUM_RSI_FILTER_MODE mode)
{
   ENUM_RSI_FILTER_MODE oldMode = m_filter_mode;
   if(oldMode == mode) return;
   m_filter_mode = mode;

   string oldStr, newStr;
   switch(oldMode)
   {
      case RSI_FILTER_ZONE: oldStr = "Zone"; break;
      case RSI_FILTER_DIRECTION: oldStr = "Direction"; break;
      case RSI_FILTER_NEUTRAL: oldStr = "Neutral"; break;
   }
   switch(mode)
   {
      case RSI_FILTER_ZONE: newStr = "Zone"; break;
      case RSI_FILTER_DIRECTION: newStr = "Direction"; break;
      case RSI_FILTER_NEUTRAL: newStr = "Neutral"; break;
   }

   m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
      "🔄 [RSI Filter] Modo alterado: " + oldStr + " → " + newStr);
}

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar nível de sobrevenda - v1.10                 |
//+------------------------------------------------------------------+
void CRSIFilter::SetOversold(double value)
{
   if(value <= 0 || value >= 100)
     {
      m_logger.Log(LOG_ERROR, THROTTLE_NONE, "HOT_RELOAD",
         "[RSI Filter] Sobrevenda invalido: " + DoubleToString(value, 1));
      return;
     }
   double oldValue = m_oversold;
   m_oversold = value;

   if(oldValue != value)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         StringFormat("🔄 [RSI Filter] Sobrevenda alterado: %.1f → %.1f", oldValue, value));
}

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar nível de sobrecompra - v1.10                |
//+------------------------------------------------------------------+
void CRSIFilter::SetOverbought(double value)
{
   if(value <= 0 || value >= 100)
     {
      m_logger.Log(LOG_ERROR, THROTTLE_NONE, "HOT_RELOAD",
         "[RSI Filter] Sobrecompra invalido: " + DoubleToString(value, 1));
      return;
     }
   double oldValue = m_overbought;
   m_overbought = value;

   if(oldValue != value)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         StringFormat("🔄 [RSI Filter] Sobrecompra alterado: %.1f → %.1f", oldValue, value));
}

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar limite inferior da zona neutra - v1.10      |
//+------------------------------------------------------------------+
void CRSIFilter::SetLowerNeutral(double value)
{
   if(value <= 0 || value >= 100)
     {
      m_logger.Log(LOG_ERROR, THROTTLE_NONE, "HOT_RELOAD",
         "[RSI Filter] Lower neutral invalido: " + DoubleToString(value, 1));
      return;
     }
   double oldValue = m_lower_neutral;
   m_lower_neutral = value;

   if(oldValue != value)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         StringFormat("🔄 [RSI Filter] Lower neutral alterado: %.1f → %.1f", oldValue, value));
}

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar limite superior da zona neutra - v1.10      |
//+------------------------------------------------------------------+
void CRSIFilter::SetUpperNeutral(double value)
{
   if(value <= 0 || value >= 100)
     {
      m_logger.Log(LOG_ERROR, THROTTLE_NONE, "HOT_RELOAD",
         "[RSI Filter] Upper neutral invalido: " + DoubleToString(value, 1));
      return;
     }
   double oldValue = m_upper_neutral;
   m_upper_neutral = value;

   if(oldValue != value)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         StringFormat("🔄 [RSI Filter] Upper neutral alterado: %.1f → %.1f", oldValue, value));
}

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar shift - v1.10                               |
//+------------------------------------------------------------------+
void CRSIFilter::SetShift(int value)
{
   if(value < 0 || value > 100)
     {
      m_logger.Log(LOG_ERROR, THROTTLE_NONE, "HOT_RELOAD",
         "[RSI Filter] Shift invalido: " + IntegerToString(value));
      return;
     }
   int oldValue = m_shift;
   m_shift = value;

   if(oldValue != value)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         StringFormat("🔄 [RSI Filter] Shift alterado: %d → %d", oldValue, value));
}

// ═══════════════════════════════════════════════════════════════
// COLD RELOAD - MÉTODOS SET FRIOS (v1.10)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar período (reinicia indicador) - v1.10       |
//+------------------------------------------------------------------+
bool CRSIFilter::SetPeriod(int value)
{
   if(value <= 0)
   {
      m_logger.Log(LOG_ERROR, THROTTLE_NONE, "COLD_RELOAD",
         "[RSI Filter] Período inválido: " + IntegerToString(value));
      return false;
   }

   int oldValue = m_period;
   if(oldValue == value) return true;
   m_period = value;

   Deinitialize();
   bool success = Initialize();

   if(success)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         StringFormat("🔄 [RSI Filter] Período alterado: %d → %d (reiniciado)", oldValue, value));

   return success;
}

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar timeframe (reinicia indicador) - v1.10     |
//+------------------------------------------------------------------+
bool CRSIFilter::SetTimeframe(ENUM_TIMEFRAMES tf)
{
   ENUM_TIMEFRAMES oldTF = m_timeframe;
   if(oldTF == tf) return true;
   m_timeframe = tf;

   Deinitialize();
   bool success = Initialize();

   if(success)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         "🔄 [RSI Filter] Timeframe alterado: " + EnumToString(oldTF) + " → " + EnumToString(tf) + " (reiniciado)");

   return success;
}

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar applied price (reinicia indicador) - v1.10 |
//+------------------------------------------------------------------+
bool CRSIFilter::SetAppliedPrice(ENUM_APPLIED_PRICE price)
{
   if(m_applied_price == price) return true;
   m_applied_price = price;

   Deinitialize();
   bool success = Initialize();

   if(success)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         "🔄 [RSI Filter] Applied price alterado (reiniciado)");

   return success;
}

//+------------------------------------------------------------------+
//| Getters                                                           |
//+------------------------------------------------------------------+
double CRSIFilter::GetCurrentRSI()
{
   return GetRSI(m_shift);
}

double CRSIFilter::GetRSI(int shift)
{
   if(!LoadRSIValues(shift + 2))
      return 0.0;
   
   return m_rsi_buffer[shift];
}

string CRSIFilter::GetFilterModeText()
{
   switch(m_filter_mode)
   {
      case RSI_FILTER_ZONE:      return "Zona";
      case RSI_FILTER_DIRECTION: return "Direção";
      case RSI_FILTER_NEUTRAL:   return "Neutro";
      default:                   return "Desconhecido";
   }
}

string CRSIFilter::GetFilterStatus(ENUM_SIGNAL_TYPE signal)
{
   if(!m_isEnabled)
      return "DISABLED";
   
   double rsi = GetCurrentRSI();
   string signal_text = (signal == SIGNAL_BUY) ? "BUY" : "SELL";
   bool allowed = ValidateSignal(signal);
   
   return StringFormat("%s | RSI: %.2f | Mode: %s | Status: %s",
                       signal_text, rsi, GetFilterModeText(),
                       allowed ? "✅ ALLOWED" : "🚫 BLOCKED");
}
//+------------------------------------------------------------------+
