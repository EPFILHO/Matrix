//+------------------------------------------------------------------+
//|                                         BollingerBandsFilter.mqh |
//|                                         Copyright 2026, EP Filho |
//|                          Filtro Bollinger Bands - EPBot Matrix   |
//|                                   Versão 1.03 - Claude Parte 037 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "1.03"
// CHANGELOG v1.03 (Parte 037):
// * Fix GUI: Setup() não converte mais PERIOD_CURRENT para Period().
//   Painel BB Filter agora mostra "ATUAL" quando input é PERIOD_CURRENT.
// CHANGELOG v1.02 (Parte 031):
// * Limpeza: removidos `if(m_logger != NULL)` e `else Print()` fallbacks
#property strict

// ═══════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════
#include "../../Core/Logger.mqh"
#include "../Base/FilterBase.mqh"

// ═══════════════════════════════════════════════════════════════
// CHANGELOG
// v1.01 (Parte 031):
// + SetEnabled override: loga "Filtro: ATIVADO/DESATIVADO" se mudar
// + SetSqueezeMetric, SetSqueezeThreshold, SetPercentilePeriod:
//   só logam se valor realmente mudar
// + SetPeriod, SetDeviation, SetTimeframe, SetAppliedPrice:
//   skip Deinitialize+Initialize se parâmetros forem idênticos
// + Removidos fallbacks else Print(...) — m_logger nunca é NULL
//
// v1.00 (Parte 026):
// + Filtro Anti-Squeeze para Bollinger Bands
//   Bloqueia trades quando bandas estão estreitas (mercado em range)
//   Ideal para proteger MACross de sinais falsos em consolidação
// + 3 métricas configuráveis pelo usuário:
//   - BB_SQUEEZE_ABSOLUTE: (upper - lower) em pontos
//   - BB_SQUEEZE_RELATIVE: (upper - lower) / middle * 100 (%)
//   - BB_SQUEEZE_PERCENTILE: compara com últimas N barras
// + Hot/Cold reload completo seguindo padrão Matrix
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Enumeração de Modos de Métrica do Squeeze                        |
//+------------------------------------------------------------------+
enum ENUM_BB_SQUEEZE_METRIC
  {
   BB_SQUEEZE_ABSOLUTE   = 0,   // Absoluto: largura em pontos
   BB_SQUEEZE_RELATIVE   = 1,   // Relativo: largura % da middle band
   BB_SQUEEZE_PERCENTILE = 2    // Percentil: compara com N barras anteriores
  };

//+------------------------------------------------------------------+
//| Classe Bollinger Bands Filter                                    |
//+------------------------------------------------------------------+
class CBollingerBandsFilter : public CFilterBase
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
   ENUM_BB_SQUEEZE_METRIC m_inputSqueezeMetric;
   double            m_inputSqueezeThreshold;
   int               m_inputPercentilePeriod;

   // ═══════════════════════════════════════════════════════════
   // WORKING PARAMETERS - QUENTES (valores usados - não requerem reinit)
   // ═══════════════════════════════════════════════════════════
   ENUM_BB_SQUEEZE_METRIC m_squeeze_metric;
   double            m_squeeze_threshold;
   int               m_percentile_period;

   // ═══════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS
   // ═══════════════════════════════════════════════════════════
   bool              LoadBandsValues(int count);
   bool              CheckSqueezeAbsolute();
   bool              CheckSqueezeRelative();
   bool              CheckSqueezePercentile();

public:
   // ═══════════════════════════════════════════════════════════
   // CONSTRUTOR E DESTRUTOR
   // ═══════════════════════════════════════════════════════════
                     CBollingerBandsFilter();
                    ~CBollingerBandsFilter();

   // ═══════════════════════════════════════════════════════════
   // SETUP (chamado ANTES do Initialize)
   // ═══════════════════════════════════════════════════════════
   bool              Setup(CLogger* logger, string symbol, ENUM_TIMEFRAMES timeframe,
                           int period, double deviation, ENUM_APPLIED_PRICE applied_price,
                           ENUM_BB_SQUEEZE_METRIC squeeze_metric, double squeeze_threshold,
                           int percentile_period);

   // ═══════════════════════════════════════════════════════════
   // IMPLEMENTAÇÃO DOS MÉTODOS VIRTUAIS (obrigatórios)
   // ═══════════════════════════════════════════════════════════
   virtual bool      Initialize() override;
   virtual void      Deinitialize() override;
   virtual bool      ValidateSignal(ENUM_SIGNAL_TYPE signal) override;
   virtual bool      UpdateHotParameters() override;
   virtual bool      UpdateColdParameters() override;

   // ═══════════════════════════════════════════════════════════
   // HOT RELOAD - Parâmetros quentes (sem reiniciar indicadores)
   // ═══════════════════════════════════════════════════════════
   virtual void      SetEnabled(bool enabled) override; // v1.01 — log se mudar
   void              SetSqueezeMetric(ENUM_BB_SQUEEZE_METRIC metric);
   void              SetSqueezeThreshold(double value);
   void              SetPercentilePeriod(int value);

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
   double            GetCurrentBandWidth();
   double            GetCurrentBandWidthRelative();
   string            GetSqueezeMetricText();
   string            GetFilterStatus();

   int               GetPeriod() const { return m_period; }
   double            GetDeviation() const { return m_deviation; }
   ENUM_TIMEFRAMES   GetTimeframe() const { return m_timeframe; }
   ENUM_APPLIED_PRICE GetAppliedPrice() const { return m_applied_price; }
   ENUM_BB_SQUEEZE_METRIC GetSqueezeMetric() const { return m_squeeze_metric; }
   double            GetSqueezeThreshold() const { return m_squeeze_threshold; }
   int               GetPercentilePeriod() const { return m_percentile_period; }

   // ═══════════════════════════════════════════════════════════
   // GETTERS - Input values (valores originais da configuração)
   // ═══════════════════════════════════════════════════════════
   int               GetInputPeriod() const { return m_inputPeriod; }
   double            GetInputDeviation() const { return m_inputDeviation; }
   ENUM_TIMEFRAMES   GetInputTimeframe() const { return m_inputTimeframe; }
   ENUM_APPLIED_PRICE GetInputAppliedPrice() const { return m_inputAppliedPrice; }
   ENUM_BB_SQUEEZE_METRIC GetInputSqueezeMetric() const { return m_inputSqueezeMetric; }
   double            GetInputSqueezeThreshold() const { return m_inputSqueezeThreshold; }
   int               GetInputPercentilePeriod() const { return m_inputPercentilePeriod; }
  };

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CBollingerBandsFilter::CBollingerBandsFilter() : CFilterBase("BB Filter")
  {
   m_logger = NULL;
   m_bands_handle = INVALID_HANDLE;

// ═══ INPUT PARAMETERS (valores padrão) ═══
   m_inputSymbol = "";
   m_inputTimeframe = PERIOD_CURRENT;
   m_inputPeriod = 20;
   m_inputDeviation = 2.0;
   m_inputAppliedPrice = PRICE_CLOSE;
   m_inputSqueezeMetric = BB_SQUEEZE_RELATIVE;
   m_inputSqueezeThreshold = 1.0;    // 1.0% para relativo, 50 pontos para absoluto, 20 para percentil
   m_inputPercentilePeriod = 50;

// ═══ WORKING PARAMETERS (começam iguais aos inputs) ═══
   m_symbol = "";
   m_timeframe = PERIOD_CURRENT;
   m_period = 20;
   m_deviation = 2.0;
   m_applied_price = PRICE_CLOSE;
   m_squeeze_metric = BB_SQUEEZE_RELATIVE;
   m_squeeze_threshold = 1.0;
   m_percentile_period = 50;

   ArraySetAsSeries(m_upper, true);
   ArraySetAsSeries(m_lower, true);
   ArraySetAsSeries(m_middle, true);
  }

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CBollingerBandsFilter::~CBollingerBandsFilter()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Setup (configuração inicial)                                     |
//+------------------------------------------------------------------+
bool CBollingerBandsFilter::Setup(CLogger* logger, string symbol, ENUM_TIMEFRAMES timeframe,
                                   int period, double deviation, ENUM_APPLIED_PRICE applied_price,
                                   ENUM_BB_SQUEEZE_METRIC squeeze_metric, double squeeze_threshold,
                                   int percentile_period)
  {
   m_logger = logger;

// ═══════════════════════════════════════════════════════════
// SALVAR INPUT PARAMETERS (valores originais)
// ═══════════════════════════════════════════════════════════
   m_inputSymbol = symbol;
   m_inputTimeframe = timeframe;  // Parte 037 — preserva PERIOD_CURRENT
   m_inputPeriod = period;
   m_inputDeviation = deviation;
   m_inputAppliedPrice = applied_price;
   m_inputSqueezeMetric = squeeze_metric;
   m_inputSqueezeThreshold = squeeze_threshold;
   m_inputPercentilePeriod = percentile_period;

// ═══════════════════════════════════════════════════════════
// INICIALIZAR WORKING PARAMETERS (começam iguais aos inputs)
// ═══════════════════════════════════════════════════════════
   m_symbol = symbol;
   m_timeframe = timeframe;  // Parte 037 — preserva PERIOD_CURRENT
   m_period = period;
   m_deviation = deviation;
   m_applied_price = applied_price;
   m_squeeze_metric = squeeze_metric;
   m_squeeze_threshold = squeeze_threshold;
   m_percentile_period = percentile_period;

   return true;
  }

//+------------------------------------------------------------------+
//| Initialize (criar handles)                                       |
//+------------------------------------------------------------------+
bool CBollingerBandsFilter::Initialize()
  {
   if(m_isInitialized)
      return true;

   m_bands_handle = iBands(m_symbol, m_timeframe, m_period, 0, m_deviation, m_applied_price);

   if(m_bands_handle == INVALID_HANDLE)
     {
      string msg = "[" + m_filterName + "] Erro ao criar indicador Bollinger Bands";
      m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", msg);
      return false;
     }

   m_isInitialized = true;

   string msg = "✅ [" + m_filterName + "] Inicializado [" + m_symbol + " | " +
                EnumToString(m_timeframe) + " | Período: " + IntegerToString(m_period) +
                " | Desvio: " + DoubleToString(m_deviation, 1) +
                " | Modo: " + GetSqueezeMetricText() + "]";
   m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", msg);

   return true;
  }

//+------------------------------------------------------------------+
//| Deinitialize (liberar handles)                                   |
//+------------------------------------------------------------------+
void CBollingerBandsFilter::Deinitialize()
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
bool CBollingerBandsFilter::UpdateHotParameters()
  {
   return true;
  }

//+------------------------------------------------------------------+
//| UpdateColdParameters (params que precisam reinicializar)         |
//+------------------------------------------------------------------+
bool CBollingerBandsFilter::UpdateColdParameters()
  {
   Deinitialize();
   return Initialize();
  }

//+------------------------------------------------------------------+
//| Carregar valores das Bandas de Bollinger                         |
//+------------------------------------------------------------------+
bool CBollingerBandsFilter::LoadBandsValues(int count)
  {
   if(m_bands_handle == INVALID_HANDLE)
      return false;

   if(CopyBuffer(m_bands_handle, 0, 0, count, m_middle) < count)
     {
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "BUFFER",
         "[" + m_filterName + "] Erro ao copiar buffer Middle BB");
      return false;
     }

   if(CopyBuffer(m_bands_handle, 1, 0, count, m_upper) < count)
     {
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "BUFFER",
         "[" + m_filterName + "] Erro ao copiar buffer Upper BB");
      return false;
     }

   if(CopyBuffer(m_bands_handle, 2, 0, count, m_lower) < count)
     {
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "BUFFER",
         "[" + m_filterName + "] Erro ao copiar buffer Lower BB");
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| ValidateSignal (método principal - OBRIGATÓRIO)                  |
//| Retorna true se NÃO está em squeeze (permite trade)              |
//| Retorna false se ESTÁ em squeeze (bloqueia trade)                |
//+------------------------------------------------------------------+
bool CBollingerBandsFilter::ValidateSignal(ENUM_SIGNAL_TYPE signal)
  {
   if(!m_isEnabled || !m_isInitialized)
      return true;

   switch(m_squeeze_metric)
     {
      case BB_SQUEEZE_ABSOLUTE:
         return CheckSqueezeAbsolute();

      case BB_SQUEEZE_RELATIVE:
         return CheckSqueezeRelative();

      case BB_SQUEEZE_PERCENTILE:
         return CheckSqueezePercentile();

      default:
         return true;
     }
  }

//+------------------------------------------------------------------+
//| Squeeze Absoluto: largura em pontos                              |
//+------------------------------------------------------------------+
bool CBollingerBandsFilter::CheckSqueezeAbsolute()
  {
   if(!LoadBandsValues(2))
      return false;

   double width = (m_upper[1] - m_lower[1]) / _Point;

   if(width < m_squeeze_threshold)
     {
      string msg = StringFormat("🚫 [%s] Trade bloqueado - Squeeze (Absoluto): %.1f pts < %.1f pts",
                                m_filterName, width, m_squeeze_threshold);
      m_logger.Log(LOG_EVENT, THROTTLE_CANDLE, "FILTER", msg);
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Squeeze Relativo: largura como % da banda central                |
//+------------------------------------------------------------------+
bool CBollingerBandsFilter::CheckSqueezeRelative()
  {
   if(!LoadBandsValues(2))
      return false;

   if(MathAbs(m_middle[1]) < 0.000001)
      return true;  // Evita divisão por zero

   double widthPct = (m_upper[1] - m_lower[1]) / m_middle[1] * 100.0;

   if(widthPct < m_squeeze_threshold)
     {
      string msg = StringFormat("🚫 [%s] Trade bloqueado - Squeeze (Relativo): %.2f%% < %.2f%%",
                                m_filterName, widthPct, m_squeeze_threshold);
      m_logger.Log(LOG_EVENT, THROTTLE_CANDLE, "FILTER", msg);
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Squeeze Percentil: compara largura atual com N barras            |
//| Bloqueia se a largura atual está abaixo do percentil X das       |
//| últimas N barras (threshold = percentil, ex: 20 = abaixo de 20%)|
//+------------------------------------------------------------------+
bool CBollingerBandsFilter::CheckSqueezePercentile()
  {
   int barsNeeded = m_percentile_period + 2;
   if(!LoadBandsValues(barsNeeded))
      return false;

   // Calcular largura atual (shift=1)
   double currentWidth = m_upper[1] - m_lower[1];

   // Contar quantas barras no período têm largura MENOR que a atual
   int countSmaller = 0;
   for(int i = 2; i < barsNeeded; i++)
     {
      double width_i = m_upper[i] - m_lower[i];
      if(width_i < currentWidth)
         countSmaller++;
     }

   // Percentil atual (0-100)
   double percentile = (double)countSmaller / (double)m_percentile_period * 100.0;

   if(percentile < m_squeeze_threshold)
     {
      string msg = StringFormat("🚫 [%s] Trade bloqueado - Squeeze (Percentil): %.1f%% < %.1f%% (últimas %d barras)",
                                m_filterName, percentile, m_squeeze_threshold, m_percentile_period);
      m_logger.Log(LOG_EVENT, THROTTLE_CANDLE, "FILTER", msg);
      return false;
     }

   return true;
  }

// ═══════════════════════════════════════════════════════════════
// HOT RELOAD - MÉTODOS SET QUENTES
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| HOT RELOAD - Ativar/desativar filtro (v1.01)                     |
//+------------------------------------------------------------------+
void CBollingerBandsFilter::SetEnabled(bool enabled)
  {
   bool oldValue = m_isEnabled;
   m_isEnabled = enabled;

   if(oldValue != enabled)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "🔄 [BB Filter] Filtro: " + (enabled ? "ATIVADO" : "DESATIVADO"));
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar métrica de squeeze                          |
//+------------------------------------------------------------------+
void CBollingerBandsFilter::SetSqueezeMetric(ENUM_BB_SQUEEZE_METRIC metric)
  {
   ENUM_BB_SQUEEZE_METRIC oldMetric = m_squeeze_metric;
   if(oldMetric == metric) return;
   m_squeeze_metric = metric;

   m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
      "🔄 [BB Filter] Modo alterado: " + GetSqueezeMetricText());
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar threshold do squeeze                        |
//+------------------------------------------------------------------+
void CBollingerBandsFilter::SetSqueezeThreshold(double value)
  {
   if(value <= 0)
     {
      m_logger.Log(LOG_ERROR, THROTTLE_NONE, "HOT_RELOAD",
         "[BB Filter] Threshold invalido: " + DoubleToString(value, 2));
      return;
     }
   double oldValue = m_squeeze_threshold;
   m_squeeze_threshold = value;

   if(oldValue != value)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         StringFormat("🔄 [BB Filter] Threshold alterado: %.2f → %.2f", oldValue, value));
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar período do percentil                        |
//+------------------------------------------------------------------+
void CBollingerBandsFilter::SetPercentilePeriod(int value)
  {
   if(value <= 0 || value > 500)
     {
      m_logger.Log(LOG_ERROR, THROTTLE_NONE, "HOT_RELOAD",
         "[BB Filter] Periodo percentil invalido: " + IntegerToString(value));
      return;
     }
   int oldValue = m_percentile_period;
   m_percentile_period = value;

   if(oldValue != value)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         StringFormat("🔄 [BB Filter] Período percentil alterado: %d → %d", oldValue, value));
  }

// ═══════════════════════════════════════════════════════════════
// COLD RELOAD - MÉTODOS SET FRIOS
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar período (reinicia indicador)               |
//+------------------------------------------------------------------+
bool CBollingerBandsFilter::SetPeriod(int value)
  {
   if(value <= 0)
     {
      string msg = "[BB Filter] Período inválido: " + IntegerToString(value);
      m_logger.Log(LOG_ERROR, THROTTLE_NONE, "COLD_RELOAD", msg);
      return false;
     }

   int oldValue = m_period;
   if(oldValue == value) return true;
   m_period = value;

   Deinitialize();
   bool success = Initialize();

   if(success)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         StringFormat("🔄 [BB Filter] Período alterado: %d → %d (reiniciado)", oldValue, value));

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar desvio padrão (reinicia indicador)         |
//+------------------------------------------------------------------+
bool CBollingerBandsFilter::SetDeviation(double value)
  {
   if(value <= 0)
     {
      m_logger.Log(LOG_ERROR, THROTTLE_NONE, "COLD_RELOAD",
         "[BB Filter] Desvio inválido: " + DoubleToString(value, 2));
      return false;
     }

   double oldValue = m_deviation;
   if(oldValue == value) return true;
   m_deviation = value;

   Deinitialize();
   bool success = Initialize();

   if(success)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         StringFormat("🔄 [BB Filter] Desvio alterado: %.1f → %.1f (reiniciado)", oldValue, value));

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar timeframe (reinicia indicador)             |
//+------------------------------------------------------------------+
bool CBollingerBandsFilter::SetTimeframe(ENUM_TIMEFRAMES tf)
  {
   ENUM_TIMEFRAMES oldTF = m_timeframe;
   if(oldTF == tf) return true;
   m_timeframe = tf;

   Deinitialize();
   bool success = Initialize();

   if(success)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         "🔄 [BB Filter] Timeframe alterado: " + EnumToString(oldTF) + " → " + EnumToString(tf) + " (reiniciado)");

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar applied price (reinicia indicador)         |
//+------------------------------------------------------------------+
bool CBollingerBandsFilter::SetAppliedPrice(ENUM_APPLIED_PRICE price)
  {
   if(m_applied_price == price) return true;
   m_applied_price = price;

   Deinitialize();
   bool success = Initialize();

   if(success)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         "🔄 [BB Filter] Applied price alterado (reiniciado)");

   return success;
  }

// ═══════════════════════════════════════════════════════════════
// GETTERS
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Largura atual das bandas em pontos                               |
//+------------------------------------------------------------------+
double CBollingerBandsFilter::GetCurrentBandWidth()
  {
   if(!LoadBandsValues(2))
      return 0.0;
   return (m_upper[1] - m_lower[1]) / _Point;
  }

//+------------------------------------------------------------------+
//| Largura atual relativa (%)                                       |
//+------------------------------------------------------------------+
double CBollingerBandsFilter::GetCurrentBandWidthRelative()
  {
   if(!LoadBandsValues(2))
      return 0.0;
   if(MathAbs(m_middle[1]) < 0.000001)
      return 0.0;
   return (m_upper[1] - m_lower[1]) / m_middle[1] * 100.0;
  }

//+------------------------------------------------------------------+
//| Texto da métrica de squeeze                                      |
//+------------------------------------------------------------------+
string CBollingerBandsFilter::GetSqueezeMetricText()
  {
   switch(m_squeeze_metric)
     {
      case BB_SQUEEZE_ABSOLUTE:
         return "Absoluto";
      case BB_SQUEEZE_RELATIVE:
         return "Relativo (%)";
      case BB_SQUEEZE_PERCENTILE:
         return "Percentil";
      default:
         return "Desconhecido";
     }
  }

//+------------------------------------------------------------------+
//| Status resumido do filtro                                        |
//+------------------------------------------------------------------+
string CBollingerBandsFilter::GetFilterStatus()
  {
   if(!m_isEnabled)
      return "DISABLED";

   double width = GetCurrentBandWidth();
   double widthPct = GetCurrentBandWidthRelative();

   return StringFormat("Largura: %.1f pts (%.2f%%) | Modo: %s | Limite: %.2f",
                       width, widthPct, GetSqueezeMetricText(), m_squeeze_threshold);
  }
//+------------------------------------------------------------------+
