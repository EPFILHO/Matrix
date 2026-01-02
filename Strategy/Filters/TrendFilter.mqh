//+------------------------------------------------------------------+
//|                                                  TrendFilter.mqh |
//|                                         Copyright 2025, EP Filho |
//|                      Filtro de Tendência por MA - EPBot Matrix   |
//|                                                      Versão 2.05 |
//|                                                                  |
//| CHANGELOG v2.05 - PRODUCTION:                                    |
//| - Logs otimizados: LogInfo para eventos, LogDebug para detalhes |
//| - Mantém arquitetura v2.04 (1 MA, zona automática)              |
//| - Ideal para LOG_COMPLETE (limpo) e LOG_DEBUG (verboso)         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EP Filho"
#property version   "2.05"
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
   // HANDLE DO INDICADOR (1 única MA)
   // ═══════════════════════════════════════════════════════════
   int               m_handleMA;

   // ═══════════════════════════════════════════════════════════
   // ARRAY (buffer interno)
   // ═══════════════════════════════════════════════════════════
   double            m_ma[];

   // ═══════════════════════════════════════════════════════════
   // THROTTLE ANTI-FLOOD (v2.04 - 1 log por candle)
   // ═══════════════════════════════════════════════════════════
   datetime          m_lastLogBar;

   // ═══════════════════════════════════════════════════════════
   // INPUT PARAMETERS (imutáveis - valores originais)
   // ═══════════════════════════════════════════════════════════
   bool              m_inputUseTrendFilter;
   int               m_inputMAPeriod;
   ENUM_MA_METHOD    m_inputMAMethod;
   ENUM_APPLIED_PRICE m_inputMAApplied;
   ENUM_TIMEFRAMES   m_inputMATimeframe;
   double            m_inputNeutralDistance;

   // ═══════════════════════════════════════════════════════════
   // WORKING PARAMETERS (mutáveis - valores em uso)
   // ═══════════════════════════════════════════════════════════
   bool              m_useTrendFilter;
   int               m_maPeriod;
   ENUM_MA_METHOD    m_maMethod;
   ENUM_APPLIED_PRICE m_maApplied;
   ENUM_TIMEFRAMES   m_maTimeframe;
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
      // Filtro de tendência (usa mesma MA)
      bool useTrendFilter,
      int maPeriod,
      ENUM_MA_METHOD maMethod,
      ENUM_APPLIED_PRICE maApplied,
      ENUM_TIMEFRAMES maTimeframe,
      // Zona neutra (usa mesma MA, ativa se distance > 0)
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
   bool              SetNeutralDistance(double distancePoints);

   // ═══════════════════════════════════════════════════════════
   // COLD RELOAD - Parâmetros frios (reinicia indicadores)
   // ═══════════════════════════════════════════════════════════
   bool              SetMAPeriod(int period);
   bool              SetMAMethod(ENUM_MA_METHOD method);

   // ═══════════════════════════════════════════════════════════
   // GETTERS - Working values (valores atuais em uso)
   // ═══════════════════════════════════════════════════════════
   double            GetMA(int shift = 0);
   double            GetDistanceFromMA();
   
   bool              IsTrendFilterActive() const { return m_useTrendFilter; }
   bool              IsNeutralZoneActive() const { return m_neutralDistance > 0; }
   int               GetMAPeriod() const { return m_maPeriod; }
   ENUM_MA_METHOD    GetMAMethod() const { return m_maMethod; }
   ENUM_APPLIED_PRICE GetMAApplied() const { return m_maApplied; }
   ENUM_TIMEFRAMES   GetMATimeframe() const { return m_maTimeframe; }
   double            GetNeutralDistance() const { return m_neutralDistance; }
   
   // ═══════════════════════════════════════════════════════════
   // GETTERS - Input values (valores originais da configuração)
   // ═══════════════════════════════════════════════════════════
   bool              GetInputUseTrendFilter() const { return m_inputUseTrendFilter; }
   int               GetInputMAPeriod() const { return m_inputMAPeriod; }
   ENUM_MA_METHOD    GetInputMAMethod() const { return m_inputMAMethod; }
   ENUM_APPLIED_PRICE GetInputMAApplied() const { return m_inputMAApplied; }
   ENUM_TIMEFRAMES   GetInputMATimeframe() const { return m_inputMATimeframe; }
   double            GetInputNeutralDistance() const { return m_inputNeutralDistance; }
  };

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CTrendFilter::CTrendFilter() : CFilterBase("Trend Filter")
  {
   m_logger = NULL;
   m_handleMA = INVALID_HANDLE;
   m_lastLogBar = 0;

   // ═══ INPUT PARAMETERS (valores padrão) ═══
   m_inputUseTrendFilter = false;
   m_inputMAPeriod = 0;
   m_inputMAMethod = MODE_SMA;
   m_inputMAApplied = PRICE_CLOSE;
   m_inputMATimeframe = PERIOD_CURRENT;
   m_inputNeutralDistance = 0;

   // ═══ WORKING PARAMETERS (começam iguais aos inputs) ═══
   m_useTrendFilter = false;
   m_maPeriod = 0;
   m_maMethod = MODE_SMA;
   m_maApplied = PRICE_CLOSE;
   m_maTimeframe = PERIOD_CURRENT;
   m_neutralDistance = 0;

   ArraySetAsSeries(m_ma, true);
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
   int maPeriod,
   ENUM_MA_METHOD maMethod,
   ENUM_APPLIED_PRICE maApplied,
   ENUM_TIMEFRAMES maTimeframe,
   double neutralDistancePoints
)
  {
   m_logger = logger;

   // ═══════════════════════════════════════════════════════════
   // VALIDAÇÕES
   // ═══════════════════════════════════════════════════════════
   if(maPeriod <= 0)
     {
      string msg = "[Trend Filter] Período da MA inválido: " + IntegerToString(maPeriod);
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print("❌ ", msg);
      return false;
     }

   if(neutralDistancePoints < 0)
     {
      string msg = "[Trend Filter] Distância da zona neutra inválida: " + DoubleToString(neutralDistancePoints, 1);
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print("❌ ", msg);
      return false;
     }

   if(!useTrendFilter && neutralDistancePoints == 0)
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
   m_inputMAPeriod = maPeriod;
   m_inputMAMethod = maMethod;
   m_inputMAApplied = maApplied;
   m_inputMATimeframe = maTimeframe;
   m_inputNeutralDistance = neutralDistancePoints;

   // ═══════════════════════════════════════════════════════════
   // INICIALIZAR WORKING VARIABLES (mutáveis - começam iguais)
   // ═══════════════════════════════════════════════════════════
   m_useTrendFilter = useTrendFilter;
   m_maPeriod = maPeriod;
   m_maMethod = maMethod;
   m_maApplied = maApplied;
   m_maTimeframe = maTimeframe;
   m_neutralDistance = neutralDistancePoints;

   return true;
  }

//+------------------------------------------------------------------+
//| Inicialização                                                     |
//+------------------------------------------------------------------+
bool CTrendFilter::Initialize()
  {
   if(m_isInitialized)
   {
      if(m_logger != NULL)
         m_logger.LogWarning("⚠️ [Trend Filter] Já está inicializado - ignorando");
      return true;
   }

   // Se ambos desabilitados, não precisa criar indicadores
   if(!m_useTrendFilter && m_neutralDistance == 0)
     {
      m_isInitialized = true;
      m_isEnabled = true;
      
      if(m_logger != NULL)
         m_logger.LogWarning("⚠️ [Trend Filter] Ambos modos desabilitados - sem efeito");
      
      return true;
     }

   // Criar handle da MA (usada para ambos os filtros)
   m_handleMA = iMA(
                   _Symbol,
                   m_maTimeframe,
                   m_maPeriod,
                   0,
                   m_maMethod,
                   m_maApplied
                );

   if(m_handleMA == INVALID_HANDLE)
     {
      int error = GetLastError();
      string msg = "❌ [Trend Filter] Falha ao criar handle MA - Código: " + IntegerToString(error);
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print(msg);
      return false;
     }

   int calculated = BarsCalculated(m_handleMA);
   if(calculated <= 0)
     {
      if(m_logger != NULL)
         m_logger.LogWarning("⚠️ [Trend Filter] MA ainda sem dados calculados (aguardar tick)");
     }

   m_isInitialized = true;
   m_isEnabled = true;

   // ✅ LOG RESUMIDO
   string msg = "✅ [Trend Filter] Inicializado | MA " + IntegerToString(m_maPeriod);
   if(m_useTrendFilter)
      msg += " | Direcional: ON";
   if(m_neutralDistance > 0)
      msg += " | Zona: ±" + DoubleToString(m_neutralDistance, 0) + " pts";

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
   if(m_handleMA != INVALID_HANDLE)
     {
      IndicatorRelease(m_handleMA);
      m_handleMA = INVALID_HANDLE;
      
      if(m_logger != NULL)
         m_logger.LogInfo("🔧 [Trend Filter] Handle MA liberado");
     }

   m_isInitialized = false;
  }

//+------------------------------------------------------------------+
//| Atualizar indicadores                                            |
//+------------------------------------------------------------------+
bool CTrendFilter::UpdateIndicators()
  {
   if(m_handleMA == INVALID_HANDLE)
      return true;

   int calculated = BarsCalculated(m_handleMA);
   if(calculated <= 0)
     {
      if(m_logger != NULL)
         m_logger.LogWarning("⚠️ [Trend Filter] MA ainda calculando... (aguardar tick)");
      return false;
     }

   int copied = CopyBuffer(m_handleMA, 0, 0, 3, m_ma);
   if(copied <= 0)
     {
      int error = GetLastError();
      string msg = "❌ [Trend Filter] Erro ao copiar buffer MA - Código: " + IntegerToString(error);
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print(msg);
      return false;
     }

   // 🔍 DEBUG: Buffer copiado (throttle para não poluir)
   datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);
   static datetime lastUpdateLog = 0;
   
   if(lastUpdateLog != currentBar && m_logger != NULL)
   {
      m_logger.LogDebug(StringFormat("📊 [Trend Filter] MA atualizada: [0]=%.2f [1]=%.2f", 
                                     m_ma[0], m_ma[1]));
      lastUpdateLog = currentBar;
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
   datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);

   if(signal == SIGNAL_BUY)
     {
      if(closePrice < m_ma[1])
        {
         // Throttle: só loga 1x por candle
         if(m_lastLogBar != currentBar)
           {
            string msg = "🔴 [Trend Filter] COMPRA bloqueada - preço abaixo da MA";
            if(m_logger != NULL)
               m_logger.LogInfo(msg);
            else
               Print(msg);
            m_lastLogBar = currentBar;
           }
         return false;
        }
      else
        {
         if(m_logger != NULL)
            m_logger.LogDebug("✅ [Trend Filter] COMPRA aprovada - preço acima MA");
        }
     }

   if(signal == SIGNAL_SELL)
     {
      if(closePrice > m_ma[1])
        {
         // Throttle: só loga 1x por candle
         if(m_lastLogBar != currentBar)
           {
            string msg = "🔴 [Trend Filter] VENDA bloqueada - preço acima da MA";
            if(m_logger != NULL)
               m_logger.LogInfo(msg);
            else
               Print(msg);
            m_lastLogBar = currentBar;
           }
         return false;
        }
      else
        {
         if(m_logger != NULL)
            m_logger.LogDebug("✅ [Trend Filter] VENDA aprovada - preço abaixo MA");
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Verificar zona neutra (usa candle FECHADO [1])                   |
//+------------------------------------------------------------------+
bool CTrendFilter::CheckNeutralZone()
  {
   // Zona ativa apenas se distance > 0 (automático)
   if(m_neutralDistance == 0)
      return true;

   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);
   double distance = MathAbs(closePrice - m_ma[1]);

   double pointValue = _Point;
   if(_Digits == 3 || _Digits == 5)
      pointValue *= 10;

   double distanceInPoints = distance / pointValue;

   // 🔍 DEBUG: Mostrar distância sempre em modo DEBUG
   if(m_logger != NULL)
      m_logger.LogDebug(StringFormat("📏 [Trend Filter] Distância: %.1f pts (mín: %.0f)", 
                                     distanceInPoints, m_neutralDistance));

   if(distanceInPoints <= m_neutralDistance)
     {
      datetime currentBar = iTime(_Symbol, PERIOD_CURRENT, 0);
      
      // Throttle: só loga 1x por candle
      if(m_lastLogBar != currentBar)
        {
         string msg = StringFormat("🔴 [Trend Filter] Bloqueado - zona neutra (%.1f ≤ %.0f pts)", 
                                   distanceInPoints, m_neutralDistance);
         if(m_logger != NULL)
            m_logger.LogInfo(msg);
         else
            Print(msg);
         m_lastLogBar = currentBar;
        }
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Validar sinal                                                     |
//+------------------------------------------------------------------+
bool CTrendFilter::ValidateSignal(ENUM_SIGNAL_TYPE signal)
  {
   // 🔍 DEBUG: Fluxo interno
   if(m_logger != NULL)
      m_logger.LogDebug("🔍 [Trend Filter] ValidateSignal(" + EnumToString(signal) + ")");

   if(!m_isEnabled)
   {
      if(m_logger != NULL)
         m_logger.LogWarning("⚠️ [Trend Filter] DESABILITADO (m_isEnabled=false)");
      return true;
   }

   if(signal == SIGNAL_NONE)
      return true;

   if(!m_isInitialized)
     {
      string msg = "❌ [Trend Filter] Tentativa de validar sinal SEM estar inicializado!";
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print(msg);
      return false;
     }

   if(!UpdateIndicators())
     {
      string msg = "❌ [Trend Filter] Falha ao atualizar indicadores - BLOQUEANDO por segurança";
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print(msg);
      return false;
     }

   // Verificar filtro direcional
   if(!CheckTrendDirection(signal))
      return false;

   // Verificar zona neutra
   if(!CheckNeutralZone())
      return false;

   // 🔍 DEBUG: Aprovado
   if(m_logger != NULL)
      m_logger.LogDebug("✅ [Trend Filter] Sinal aprovado");

   return true;
  }

// ═══════════════════════════════════════════════════════════════
// HOT RELOAD - MÉTODOS SET QUENTES (v2.04)
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
//| HOT RELOAD - Alterar distância da zona neutra                    |
//| v2.04 - Zona ativa automaticamente se distance > 0               |
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
   
   string status = (distancePoints > 0) ? "ATIVADA" : "DESATIVADA";
   string msg = StringFormat("🔄 [Trend Filter] Zona neutra: %.0f → %.0f pts (%s)", 
                             oldValue, distancePoints, status);
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);

   return true;
  }

// ═══════════════════════════════════════════════════════════════
// COLD RELOAD - MÉTODOS SET FRIOS (v2.04)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar período da MA                              |
//+------------------------------------------------------------------+
bool CTrendFilter::SetMAPeriod(int period)
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

   int oldValue = m_maPeriod;
   m_maPeriod = period;

   Deinitialize();
   bool success = Initialize();

   if(success)
     {
      string msg = StringFormat("🔄 [Trend Filter] Período MA alterado: %d → %d (reiniciado)", 
                                oldValue, period);
      if(m_logger != NULL)
         m_logger.LogInfo(msg);
      else
         Print(msg);
     }

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar método da MA                               |
//+------------------------------------------------------------------+
bool CTrendFilter::SetMAMethod(ENUM_MA_METHOD method)
  {
   ENUM_MA_METHOD oldMethod = m_maMethod;
   m_maMethod = method;

   Deinitialize();
   bool success = Initialize();

   if(success)
     {
      string msg = "🔄 [Trend Filter] Método MA alterado (reiniciado)";
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
double CTrendFilter::GetMA(int shift = 0)
  {
   if(!m_isInitialized || shift >= ArraySize(m_ma))
      return 0.0;

   return m_ma[shift];
  }

double CTrendFilter::GetDistanceFromMA()
  {
   if(!m_isInitialized || !UpdateIndicators())
      return 0.0;

   double currentPrice = iClose(_Symbol, PERIOD_CURRENT, 0);
   double distance = currentPrice - m_ma[0];

   double pointValue = _Point;
   if(_Digits == 3 || _Digits == 5)
      pointValue *= 10;

   return distance / pointValue;
  }
//+------------------------------------------------------------------+
