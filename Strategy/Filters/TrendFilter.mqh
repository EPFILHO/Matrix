//+------------------------------------------------------------------+
//|                                                  TrendFilter.mqh |
//|                                         Copyright 2025, EP Filho |
//|                      Filtro de Tendência por MA - EPBot Matrix   |
//|                                                      Versão 2.01 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EP Filho"
#property version   "2.01"
#property strict

// ═══════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════
#include "../../Core/Logger.mqh"
#include "../Base/FilterBase.mqh"

//+------------------------------------------------------------------+
//| Filtro de Tendência                                              |
//+------------------------------------------------------------------+
class CTrendFilter : public CFilterBase
  {
private:
   // ═══════════════════════════════════════════════════════════
   // LOGGER
   // ═══════════════════════════════════════════════════════════
   CLogger* m_logger;

   // ═══════════════════════════════════════════════════════════
   // HANDLES DOS INDICADORES (não duplica - são internos)
   // ═══════════════════════════════════════════════════════════
   int               m_handleTrendMA;
   int               m_handleNeutralMA;

   // ═══════════════════════════════════════════════════════════
   // ARRAYS (não duplica - são buffers internos)
   // ═══════════════════════════════════════════════════════════
   double            m_trendMA[];
   double            m_neutralMA[];

   // ═══════════════════════════════════════════════════════════
   // INPUT PARAMETERS (imutáveis - valores originais)
   // ═══════════════════════════════════════════════════════════
   bool              m_inputUseTrendFilter;
   int               m_inputTrendPeriod;
   ENUM_MA_METHOD    m_inputTrendMethod;
   ENUM_APPLIED_PRICE m_inputTrendApplied;
   ENUM_TIMEFRAMES   m_inputTrendTimeframe;

   bool              m_inputUseNeutralZone;
   int               m_inputNeutralPeriod;
   ENUM_MA_METHOD    m_inputNeutralMethod;
   ENUM_APPLIED_PRICE m_inputNeutralApplied;
   ENUM_TIMEFRAMES   m_inputNeutralTimeframe;
   double            m_inputNeutralDistance;

   // ═══════════════════════════════════════════════════════════
   // WORKING PARAMETERS (mutáveis - valores em uso)
   // ═══════════════════════════════════════════════════════════
   bool              m_useTrendFilter;
   int               m_trendPeriod;
   ENUM_MA_METHOD    m_trendMethod;
   ENUM_APPLIED_PRICE m_trendApplied;
   ENUM_TIMEFRAMES   m_trendTimeframe;

   bool              m_useNeutralZone;
   int               m_neutralPeriod;
   ENUM_MA_METHOD    m_neutralMethod;
   ENUM_APPLIED_PRICE m_neutralApplied;
   ENUM_TIMEFRAMES   m_neutralTimeframe;
   double            m_neutralDistance;

   // ═══════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS
   // ═══════════════════════════════════════════════════════════
   bool              UpdateIndicators();
   bool              CheckTrendDirection(ENUM_SIGNAL_TYPE signal);
   bool              CheckNeutralZone();

public:
   // ═══════════════════════════════════════════════════════════
   // CONSTRUTOR E DESTRUTOR
   // ═══════════════════════════════════════════════════════════
                     CTrendFilter();
                    ~CTrendFilter();

   // ═══════════════════════════════════════════════════════════
   // CONFIGURAÇÃO INICIAL
   // ═══════════════════════════════════════════════════════════
   bool              Setup(
      CLogger* logger,
      // Filtro de tendência
      bool useTrendFilter,
      int trendPeriod,
      ENUM_MA_METHOD trendMethod,
      ENUM_APPLIED_PRICE trendApplied,
      ENUM_TIMEFRAMES trendTimeframe,
      // Zona neutra
      bool useNeutralZone,
      int neutralPeriod,
      ENUM_MA_METHOD neutralMethod,
      ENUM_APPLIED_PRICE neutralApplied,
      ENUM_TIMEFRAMES neutralTimeframe,
      double neutralDistancePoints
   );

   // ═══════════════════════════════════════════════════════════
   // IMPLEMENTAÇÃO DOS MÉTODOS VIRTUAIS (obrigatórios)
   // ═══════════════════════════════════════════════════════════
   virtual bool      Initialize() override;
   virtual void      Deinitialize() override;
   virtual bool      ValidateSignal(ENUM_SIGNAL_TYPE signal) override;

   // ═══════════════════════════════════════════════════════════
   // HOT RELOAD - Parâmetros quentes (sem reiniciar indicadores)
   // ═══════════════════════════════════════════════════════════
   bool              SetTrendFilterEnabled(bool enabled);
   bool              SetNeutralZoneEnabled(bool enabled);
   bool              SetNeutralDistance(double distancePoints);

   // ═══════════════════════════════════════════════════════════
   // COLD RELOAD - Parâmetros frios (reinicia indicadores)
   // ═══════════════════════════════════════════════════════════
   bool              SetTrendMAPeriod(int period);
   bool              SetNeutralMAPeriod(int period);
   bool              SetTrendMAMethod(ENUM_MA_METHOD method);
   bool              SetNeutralMAMethod(ENUM_MA_METHOD method);

   // ═══════════════════════════════════════════════════════════
   // GETTERS - Working values (valores atuais em uso)
   // ═══════════════════════════════════════════════════════════
   double            GetTrendMA(int shift = 0);
   double            GetNeutralMA(int shift = 0);
   double            GetDistanceFromTrend();
   double            GetDistanceFromNeutral();
   
   bool              IsTrendFilterActive() const { return m_useTrendFilter; }
   bool              IsNeutralZoneActive() const { return m_useNeutralZone; }
   int               GetTrendPeriod() const { return m_trendPeriod; }
   int               GetNeutralPeriod() const { return m_neutralPeriod; }
   ENUM_MA_METHOD    GetTrendMethod() const { return m_trendMethod; }
   ENUM_MA_METHOD    GetNeutralMethod() const { return m_neutralMethod; }
   ENUM_APPLIED_PRICE GetTrendApplied() const { return m_trendApplied; }
   ENUM_APPLIED_PRICE GetNeutralApplied() const { return m_neutralApplied; }
   ENUM_TIMEFRAMES   GetTrendTimeframe() const { return m_trendTimeframe; }
   ENUM_TIMEFRAMES   GetNeutralTimeframe() const { return m_neutralTimeframe; }
   double            GetNeutralDistance() const { return m_neutralDistance; }
   
   // ═══════════════════════════════════════════════════════════
   // GETTERS - Input values (valores originais da configuração)
   // ═══════════════════════════════════════════════════════════
   bool              GetInputUseTrendFilter() const { return m_inputUseTrendFilter; }
   bool              GetInputUseNeutralZone() const { return m_inputUseNeutralZone; }
   int               GetInputTrendPeriod() const { return m_inputTrendPeriod; }
   int               GetInputNeutralPeriod() const { return m_inputNeutralPeriod; }
   ENUM_MA_METHOD    GetInputTrendMethod() const { return m_inputTrendMethod; }
   ENUM_MA_METHOD    GetInputNeutralMethod() const { return m_inputNeutralMethod; }
   ENUM_APPLIED_PRICE GetInputTrendApplied() const { return m_inputTrendApplied; }
   ENUM_APPLIED_PRICE GetInputNeutralApplied() const { return m_inputNeutralApplied; }
   ENUM_TIMEFRAMES   GetInputTrendTimeframe() const { return m_inputTrendTimeframe; }
   ENUM_TIMEFRAMES   GetInputNeutralTimeframe() const { return m_inputNeutralTimeframe; }
   double            GetInputNeutralDistance() const { return m_inputNeutralDistance; }
  };

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CTrendFilter::CTrendFilter() : CFilterBase("Trend Filter")
  {
   m_logger = NULL;
   m_handleTrendMA = INVALID_HANDLE;
   m_handleNeutralMA = INVALID_HANDLE;

   // ═══ INPUT PARAMETERS (valores padrão) ═══
   m_inputUseTrendFilter = false;
   m_inputTrendPeriod = 0;
   m_inputTrendMethod = MODE_SMA;
   m_inputTrendApplied = PRICE_CLOSE;
   m_inputTrendTimeframe = PERIOD_CURRENT;
   
   m_inputUseNeutralZone = false;
   m_inputNeutralPeriod = 0;
   m_inputNeutralMethod = MODE_SMA;
   m_inputNeutralApplied = PRICE_CLOSE;
   m_inputNeutralTimeframe = PERIOD_CURRENT;
   m_inputNeutralDistance = 0;

   // ═══ WORKING PARAMETERS (começam iguais aos inputs) ═══
   m_useTrendFilter = false;
   m_trendPeriod = 0;
   m_trendMethod = MODE_SMA;
   m_trendApplied = PRICE_CLOSE;
   m_trendTimeframe = PERIOD_CURRENT;
   
   m_useNeutralZone = false;
   m_neutralPeriod = 0;
   m_neutralMethod = MODE_SMA;
   m_neutralApplied = PRICE_CLOSE;
   m_neutralTimeframe = PERIOD_CURRENT;
   m_neutralDistance = 0;

   ArraySetAsSeries(m_trendMA, true);
   ArraySetAsSeries(m_neutralMA, true);
  }

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CTrendFilter::~CTrendFilter()
  {
   Deinitialize();
  }

//+------------------------------------------------------------------+
//| Configuração                                                      |
//+------------------------------------------------------------------+
bool CTrendFilter::Setup(
   CLogger* logger,
   bool useTrendFilter,
   int trendPeriod,
   ENUM_MA_METHOD trendMethod,
   ENUM_APPLIED_PRICE trendApplied,
   ENUM_TIMEFRAMES trendTimeframe,
   bool useNeutralZone,
   int neutralPeriod,
   ENUM_MA_METHOD neutralMethod,
   ENUM_APPLIED_PRICE neutralApplied,
   ENUM_TIMEFRAMES neutralTimeframe,
   double neutralDistancePoints
)
  {
   m_logger = logger;

   // ═══════════════════════════════════════════════════════════
   // VALIDAÇÕES
   // ═══════════════════════════════════════════════════════════
   if(useTrendFilter && trendPeriod <= 0)
     {
      string msg = "[Trend Filter] Período da MA de tendência inválido: " + IntegerToString(trendPeriod);
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print("❌ ", msg);
      return false;
     }

   if(useNeutralZone && neutralPeriod <= 0)
     {
      string msg = "[Trend Filter] Período da MA de zona neutra inválido: " + IntegerToString(neutralPeriod);
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print("❌ ", msg);
      return false;
     }

   if(useNeutralZone && neutralDistancePoints < 0)
     {
      string msg = "[Trend Filter] Distância da zona neutra inválida: " + DoubleToString(neutralDistancePoints, 1);
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print("❌ ", msg);
      return false;
     }

   if(!useTrendFilter && !useNeutralZone)
     {
      string msg = "[Trend Filter] Ambos os modos desabilitados - filtro não terá efeito";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print("⚠️ ", msg);
     }

   // ═══════════════════════════════════════════════════════════
   // ARMAZENAR INPUTS (imutáveis - valores originais)
   // ═══════════════════════════════════════════════════════════
   m_inputUseTrendFilter = useTrendFilter;
   m_inputTrendPeriod = trendPeriod;
   m_inputTrendMethod = trendMethod;
   m_inputTrendApplied = trendApplied;
   m_inputTrendTimeframe = trendTimeframe;

   m_inputUseNeutralZone = useNeutralZone;
   m_inputNeutralPeriod = neutralPeriod;
   m_inputNeutralMethod = neutralMethod;
   m_inputNeutralApplied = neutralApplied;
   m_inputNeutralTimeframe = neutralTimeframe;
   m_inputNeutralDistance = neutralDistancePoints;

   // ═══════════════════════════════════════════════════════════
   // INICIALIZAR WORKING VARIABLES (mutáveis - começam iguais)
   // ═══════════════════════════════════════════════════════════
   m_useTrendFilter = useTrendFilter;
   m_trendPeriod = trendPeriod;
   m_trendMethod = trendMethod;
   m_trendApplied = trendApplied;
   m_trendTimeframe = trendTimeframe;

   m_useNeutralZone = useNeutralZone;
   m_neutralPeriod = neutralPeriod;
   m_neutralMethod = neutralMethod;
   m_neutralApplied = neutralApplied;
   m_neutralTimeframe = neutralTimeframe;
   m_neutralDistance = neutralDistancePoints;

   return true;
  }

//+------------------------------------------------------------------+
//| Inicialização                                                     |
//+------------------------------------------------------------------+
bool CTrendFilter::Initialize()
  {
   if(m_isInitialized)
      return true;

   // Se ambos desabilitados, não precisa criar indicadores
   if(!m_useTrendFilter && !m_useNeutralZone)
     {
      m_isInitialized = true;
      string msg = "[Trend Filter] Inicializado sem indicadores (ambos os modos desabilitados)";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print("⚠️ ", msg);
      return true;
     }

   // Criar handle da MA de tendência
   if(m_useTrendFilter)
     {
      m_handleTrendMA = iMA(
                           _Symbol,
                           m_trendTimeframe,
                           m_trendPeriod,
                           0,
                           m_trendMethod,
                           m_trendApplied
                        );

      if(m_handleTrendMA == INVALID_HANDLE)
        {
         int error = GetLastError();
         string msg = "[Trend Filter] Falha ao criar handle MA de tendência. Código: " + IntegerToString(error);
         if(m_logger != NULL)
            m_logger.LogError(msg);
         else
            Print("❌ ", msg);
         return false;
        }

      int calculated = BarsCalculated(m_handleTrendMA);
      if(calculated <= 0)
        {
         string msg = "[Trend Filter] MA de tendência ainda sem dados calculados";
         if(m_logger != NULL)
            m_logger.LogWarning(msg);
         else
            Print("⚠️ ", msg);
        }
     }

   // Criar handle da MA de zona neutra
   if(m_useNeutralZone)
     {
      m_handleNeutralMA = iMA(
                             _Symbol,
                             m_neutralTimeframe,
                             m_neutralPeriod,
                             0,
                             m_neutralMethod,
                             m_neutralApplied
                          );

      if(m_handleNeutralMA == INVALID_HANDLE)
        {
         int error = GetLastError();
         string msg = "[Trend Filter] Falha ao criar handle MA de zona neutra. Código: " + IntegerToString(error);
         if(m_logger != NULL)
            m_logger.LogError(msg);
         else
            Print("❌ ", msg);
         if(m_handleTrendMA != INVALID_HANDLE)
           {
            IndicatorRelease(m_handleTrendMA);
            m_handleTrendMA = INVALID_HANDLE;
           }
         return false;
        }

      int calculated = BarsCalculated(m_handleNeutralMA);
      if(calculated <= 0)
        {
         string msg = "[Trend Filter] MA de zona neutra ainda sem dados calculados";
         if(m_logger != NULL)
            m_logger.LogWarning(msg);
         else
            Print("⚠️ ", msg);
        }
     }

   m_isInitialized = true;

   string msg = "✅ [Trend Filter] Inicializado";
   if(m_useTrendFilter)
      msg += " | Tendência: " + IntegerToString(m_trendPeriod);
   if(m_useNeutralZone)
      msg += " | Zona Neutra: " + IntegerToString(m_neutralPeriod) + " (±" + DoubleToString(m_neutralDistance, 0) + " pts)";

   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);

   return true;
  }

//+------------------------------------------------------------------+
//| Desinicialização                                                  |
//+------------------------------------------------------------------+
void CTrendFilter::Deinitialize()
  {
   if(m_handleTrendMA != INVALID_HANDLE)
     {
      IndicatorRelease(m_handleTrendMA);
      m_handleTrendMA = INVALID_HANDLE;
     }

   if(m_handleNeutralMA != INVALID_HANDLE)
     {
      IndicatorRelease(m_handleNeutralMA);
      m_handleNeutralMA = INVALID_HANDLE;
     }

   m_isInitialized = false;
  }

//+------------------------------------------------------------------+
//| Atualizar indicadores                                            |
//+------------------------------------------------------------------+
bool CTrendFilter::UpdateIndicators()
  {
   if(m_useTrendFilter && m_handleTrendMA != INVALID_HANDLE)
     {
      int calculated = BarsCalculated(m_handleTrendMA);
      if(calculated <= 0)
        {
         string msg = "[Trend Filter] MA de tendência ainda calculando... (aguardar próximo tick)";
         if(m_logger != NULL)
            m_logger.LogWarning(msg);
         else
            Print("⚠️ ", msg);
         return false;
        }

      int copied = CopyBuffer(m_handleTrendMA, 0, 0, 3, m_trendMA);
      if(copied <= 0)
        {
         int error = GetLastError();
         string msg = "[Trend Filter] Erro ao copiar buffer MA de tendência. Código: " + IntegerToString(error);
         if(m_logger != NULL)
            m_logger.LogError(msg);
         else
            Print("❌ ", msg);
         return false;
        }
     }

   if(m_useNeutralZone && m_handleNeutralMA != INVALID_HANDLE)
     {
      int calculated = BarsCalculated(m_handleNeutralMA);
      if(calculated <= 0)
        {
         string msg = "[Trend Filter] MA de zona neutra ainda calculando... (aguardar próximo tick)";
         if(m_logger != NULL)
            m_logger.LogWarning(msg);
         else
            Print("⚠️ ", msg);
         return false;
        }

      int copied = CopyBuffer(m_handleNeutralMA, 0, 0, 3, m_neutralMA);
      if(copied <= 0)
        {
         int error = GetLastError();
         string msg = "[Trend Filter] Erro ao copiar buffer MA de zona neutra. Código: " + IntegerToString(error);
         if(m_logger != NULL)
            m_logger.LogError(msg);
         else
            Print("❌ ", msg);
         return false;
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Verificar direção da tendência (usa candle FECHADO [1])          |
//+------------------------------------------------------------------+
bool CTrendFilter::CheckTrendDirection(ENUM_SIGNAL_TYPE signal)
  {
   if(!m_useTrendFilter)
      return true;

   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

   if(signal == SIGNAL_BUY)
     {
      if(closePrice < m_trendMA[1])
        {
         string msg = "🔴 [Trend Filter] COMPRA bloqueada - preço abaixo da MA de tendência";
         if(m_logger != NULL)
            m_logger.LogInfo(msg);
         else
            Print(msg);
         return false;
        }
     }

   if(signal == SIGNAL_SELL)
     {
      if(closePrice > m_trendMA[1])
        {
         string msg = "🔴 [Trend Filter] VENDA bloqueada - preço acima da MA de tendência";
         if(m_logger != NULL)
            m_logger.LogInfo(msg);
         else
            Print(msg);
         return false;
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Verificar zona neutra (usa candle FECHADO [1])                   |
//+------------------------------------------------------------------+
bool CTrendFilter::CheckNeutralZone()
  {
   if(!m_useNeutralZone)
      return true;

   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);
   double distance = MathAbs(closePrice - m_neutralMA[1]);

   double pointValue = _Point;
   if(_Digits == 3 || _Digits == 5)
      pointValue *= 10;

   double distanceInPoints = distance / pointValue;

   if(distanceInPoints <= m_neutralDistance)
     {
      string msg = "🔴 [Trend Filter] Bloqueado - dentro da zona neutra (" + 
                   DoubleToString(distanceInPoints, 1) + " pts)";
      if(m_logger != NULL)
         m_logger.LogInfo(msg);
      else
         Print(msg);
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Validar sinal                                                     |
//+------------------------------------------------------------------+
bool CTrendFilter::ValidateSignal(ENUM_SIGNAL_TYPE signal)
  {
   if(!m_isEnabled)
      return true;

   if(signal == SIGNAL_NONE)
      return true;

   if(!m_isInitialized)
     {
      string msg = "[Trend Filter] Tentativa de validar sinal sem estar inicializado";
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print("❌ ", msg);
      return false;
     }

   if(!UpdateIndicators())
     {
      string msg = "[Trend Filter] Falha ao atualizar indicadores - BLOQUEANDO sinal por segurança";
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print("❌ ", msg);
      return false;
     }

   if(!CheckTrendDirection(signal))
      return false;

   if(!CheckNeutralZone())
      return false;

   return true;
  }

// ═══════════════════════════════════════════════════════════════
// HOT RELOAD - MÉTODOS SET QUENTES (v2.01)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| HOT RELOAD - Ativar/desativar filtro direcional                  |
//+------------------------------------------------------------------+
bool CTrendFilter::SetTrendFilterEnabled(bool enabled)
  {
   bool oldValue = m_useTrendFilter;
   m_useTrendFilter = enabled;

   string msg = "🔄 [Trend Filter] Filtro direcional: " + 
                (oldValue ? "ATIVADO" : "DESATIVADO") + " → " +
                (enabled ? "ATIVADO" : "DESATIVADO");
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);

   return true;
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Ativar/desativar zona neutra                        |
//+------------------------------------------------------------------+
bool CTrendFilter::SetNeutralZoneEnabled(bool enabled)
  {
   bool oldValue = m_useNeutralZone;
   m_useNeutralZone = enabled;

   string msg = "🔄 [Trend Filter] Zona neutra: " +
                (oldValue ? "ATIVADA" : "DESATIVADA") + " → " +
                (enabled ? "ATIVADA" : "DESATIVADA");
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);

   return true;
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar distância da zona neutra                    |
//+------------------------------------------------------------------+
bool CTrendFilter::SetNeutralDistance(double distancePoints)
  {
   if(distancePoints < 0)
     {
      string msg = "[Trend Filter] Distância inválida: " + DoubleToString(distancePoints, 1);
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print("❌ ", msg);
      return false;
     }

   double oldValue = m_neutralDistance;
   m_neutralDistance = distancePoints;
   
   string msg = StringFormat("🔄 [Trend Filter] Distância zona neutra alterada: %.0f → %.0f pts", 
                             oldValue, distancePoints);
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);

   return true;
  }

// ═══════════════════════════════════════════════════════════════
// COLD RELOAD - MÉTODOS SET FRIOS (v2.01)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar período da MA de tendência                 |
//+------------------------------------------------------------------+
bool CTrendFilter::SetTrendMAPeriod(int period)
  {
   if(period <= 0)
     {
      string msg = "[Trend Filter] Período inválido: " + IntegerToString(period);
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print("❌ ", msg);
      return false;
     }

   int oldValue = m_trendPeriod;
   m_trendPeriod = period;

   Deinitialize();
   bool success = Initialize();

   if(success)
     {
      string msg = StringFormat("🔄 [Trend Filter] Período MA tendência alterado: %d → %d (reiniciado)", 
                                oldValue, period);
      if(m_logger != NULL)
         m_logger.LogInfo(msg);
      else
         Print(msg);
     }

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar período da MA de zona neutra               |
//+------------------------------------------------------------------+
bool CTrendFilter::SetNeutralMAPeriod(int period)
  {
   if(period <= 0)
     {
      string msg = "[Trend Filter] Período inválido: " + IntegerToString(period);
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print("❌ ", msg);
      return false;
     }

   int oldValue = m_neutralPeriod;
   m_neutralPeriod = period;

   Deinitialize();
   bool success = Initialize();

   if(success)
     {
      string msg = StringFormat("🔄 [Trend Filter] Período MA zona neutra alterado: %d → %d (reiniciado)",
                                oldValue, period);
      if(m_logger != NULL)
         m_logger.LogInfo(msg);
      else
         Print(msg);
     }

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar método da MA de tendência                  |
//+------------------------------------------------------------------+
bool CTrendFilter::SetTrendMAMethod(ENUM_MA_METHOD method)
  {
   ENUM_MA_METHOD oldMethod = m_trendMethod;
   m_trendMethod = method;

   Deinitialize();
   bool success = Initialize();

   if(success)
     {
      string msg = "🔄 [Trend Filter] Método MA tendência alterado (reiniciado)";
      if(m_logger != NULL)
         m_logger.LogInfo(msg);
      else
         Print(msg);
     }

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar método da MA de zona neutra                |
//+------------------------------------------------------------------+
bool CTrendFilter::SetNeutralMAMethod(ENUM_MA_METHOD method)
  {
   ENUM_MA_METHOD oldMethod = m_neutralMethod;
   m_neutralMethod = method;

   Deinitialize();
   bool success = Initialize();

   if(success)
     {
      string msg = "🔄 [Trend Filter] Método MA zona neutra alterado (reiniciado)";
      if(m_logger != NULL)
         m_logger.LogInfo(msg);
      else
         Print(msg);
     }

   return success;
  }

//+------------------------------------------------------------------+
//| Getters                                                           |
//+------------------------------------------------------------------+
double CTrendFilter::GetTrendMA(int shift = 0)
  {
   if(!m_useTrendFilter || !m_isInitialized || shift >= ArraySize(m_trendMA))
      return 0.0;

   return m_trendMA[shift];
  }

double CTrendFilter::GetNeutralMA(int shift = 0)
  {
   if(!m_useNeutralZone || !m_isInitialized || shift >= ArraySize(m_neutralMA))
      return 0.0;

   return m_neutralMA[shift];
  }

double CTrendFilter::GetDistanceFromTrend()
  {
   if(!m_useTrendFilter || !m_isInitialized || !UpdateIndicators())
      return 0.0;

   double currentPrice = iClose(_Symbol, PERIOD_CURRENT, 0);
   return currentPrice - m_trendMA[0];
  }

double CTrendFilter::GetDistanceFromNeutral()
  {
   if(!m_useNeutralZone || !m_isInitialized || !UpdateIndicators())
      return 0.0;

   double currentPrice = iClose(_Symbol, PERIOD_CURRENT, 0);
   double distance = currentPrice - m_neutralMA[0];

   double pointValue = _Point;
   if(_Digits == 3 || _Digits == 5)
      pointValue *= 10;

   return distance / pointValue;
  }
//+------------------------------------------------------------------+
