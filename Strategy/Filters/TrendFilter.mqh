//+------------------------------------------------------------------+
//|                                                  TrendFilter.mqh |
//|                                         Copyright 2026, EP Filho |
//|                      Filtro de Tendência por MA - EPBot Matrix   |
//|                     Versão 2.23 - Claude Parte 027 (Claude Code) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "2.24"
#property strict

// ═══════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════
#include "../../Core/Logger.mqh"
#include "../Base/FilterBase.mqh"

// ═══════════════════════════════════════════════════════════════
// NOVIDADES v2.23 (Parte 027):
// + Override GetStatusSummary(): retorna "Ativo"/"Inativo" baseado em
//   m_useTrendFilter/m_neutralDistance (não em m_isEnabled que é sempre true)
// * Fix: tela GERAL e sub-página TREND agora mostram status correto
//
// NOVIDADES v2.22 (Parte 027):
// * Fix: ValidateSignal() — early return true quando filtro desabilitado
//   (!m_useTrendFilter && m_neutralDistance==0). Evita deadlock permanente
// * Fix: UpdateIndicators() — revertido INVALID_HANDLE para return true
//   (v2.19 behavior). Quando filtro desabilitado, Initialize() não cria
//   handle → INVALID_HANDLE é estado válido, não erro
//
// NOVIDADES v2.21 (Parte 027):
// * Fix: GetDistanceFromMA() — guard !m_maReady em vez de !UpdateIndicators()
//   Evita chamar UpdateIndicators() fora do fluxo OnTick (timer do painel GUI)
//   + validação m_ma[0] <= 0 antes de usar
// * Fix: GetMA() — adicionado guard !m_maReady
//
// NOVIDADES v2.20 (Parte 027):
// * Fix: UpdateIndicators() retorna false quando handle é inválido
//   (antes retornava true, mascarando ausência de dados)
// * Fix: ValidateSignal() verifica ArraySize(m_ma) < 2 antes de acessar
//   m_ma[0]/m_ma[1] (previne array out of range)
//
// NOVIDADES v2.19 (Parte 024):
// + SetMAApplied(ENUM_APPLIED_PRICE): cold reload do applied price
// + SetMACold(period, method, tf, applied): setter combinado — 1 única reinicialização
//   Reverte todos os parâmetros se Initialize() falhar
//
// NOVIDADES v2.18 (Parte 024):
// + SetMATimeframe(ENUM_TIMEFRAMES tf): cold reload do timeframe da MA
//   Segue padrão de SetMAPeriod/SetMAMethod: Deinitialize→Initialize
//   Reverte para valor anterior se Initialize() falhar
//
// NOVIDADES v2.17 (Parte 024):
// + Fix: GetDistanceFromMA() guard ArraySize(m_ma)==0
//   Quando filtro desativado, handle=INVALID_HANDLE, UpdateIndicators()
//   retorna true sem popular m_ma[] → acesso a m_ma[0] causava
//   "array out of range" ao abrir sub-página TREND no painel.
//
// NOVIDADES v2.16 (Parte 022):
// + Fix: CopyBuffer validação alterada de <= 0 para < 3
// + Fix: m_maReady resetado para false quando CopyBuffer falha
//   (evita uso de dados antigos se indicador ficar temporariamente indisponível)
// ═══════════════════════════════════════════════════════════════
// NOVIDADES v2.10:
// + Migração para Logger v3.00 (5 níveis + throttle inteligente)
// + Todas as mensagens classificadas (ERROR/EVENT/DEBUG)
// + REMOVIDO throttle manual (m_lastLogBar) - usa THROTTLE_CANDLE
// + Código 75% mais limpo e profissional
//
// NOVIDADES v2.11:
// + CORREÇÃO DE SEGURANÇA: Bloqueia trades se MA não estiver calculada
// + Desabilita filtro automaticamente se dados inválidos no Initialize()
// + Reabilita filtro automaticamente quando MA fica pronta
// + Validação extra em ValidateSignal() para dados zerados
//
// NOVIDADES v2.12:
// + CORREÇÃO CRÍTICA: Flag interna m_maReady para controle de MA pronta
// + m_isEnabled SEMPRE true (SignalManager não pula o filtro)
// + m_maReady controla se MA está calculada (lógica interna)
// + ValidateSignal() verifica m_maReady ANTES de qualquer validação
//
// NOVIDADES v2.15:
// + SOLUÇÃO DEFINITIVA: Padrão SmartCross (que funcionava!)
// + Initialize() SÓ cria handle (NÃO tenta copiar buffer)
// + ValidateSignal() SEMPRE chama UpdateIndicators() PRIMEIRO
// + UpdateIndicators() copia dados no primeiro tick disponível
// + RESOLVE DEADLOCK: Não bloqueia antes de tentar copiar!
// ═══════════════════════════════════════════════════════════════

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
   // FLAG INTERNA - Controle de MA pronta
   // ═══════════════════════════════════════════════════════════
   bool              m_maReady;  // true = MA calculada e pronta

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
   bool              SetMATimeframe(ENUM_TIMEFRAMES tf);
   bool              SetMAApplied(ENUM_APPLIED_PRICE applied);
   // Setter combinado — reinicia indicadores apenas 1x
   bool              SetMACold(int period, ENUM_MA_METHOD method,
                               ENUM_TIMEFRAMES tf, ENUM_APPLIED_PRICE applied);

   // ═══════════════════════════════════════════════════════════
   // GETTERS - Working values (valores atuais em uso)
   // ═══════════════════════════════════════════════════════════
   double            GetMA(int shift = 0);
   double            GetDistanceFromMA();
   
   bool              IsTrendFilterActive() const { return m_useTrendFilter; }
   bool              IsNeutralZoneActive() const { return m_neutralDistance > 0; }

   // Override: status real depende de m_useTrendFilter, não de m_isEnabled
   virtual string    GetStatusSummary() const override
     {
      if(!m_isInitialized) return "Nao iniciado";
      return (m_useTrendFilter || m_neutralDistance > 0) ? "Ativo" : "Inativo";
     }
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
   m_maReady = false;

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
//| Configuração (v2.15)                                             |
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
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "SETUP", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   if(neutralDistancePoints < 0)
     {
      string msg = "[Trend Filter] Distância da zona neutra inválida: " + DoubleToString(neutralDistancePoints, 1);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "SETUP", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   if(!useTrendFilter && neutralDistancePoints == 0)
     {
      string msg = "[Trend Filter] Ambos os modos desabilitados - filtro não terá efeito";
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "WARNING", msg);
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
//| Inicialização (v2.15 - PADRÃO SMARTCROSS)                        |
//+------------------------------------------------------------------+
bool CTrendFilter::Initialize()
  {
   if(m_isInitialized)
   {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "WARNING", 
            "⚠️ [Trend Filter] Já está inicializado - ignorando");
      return true;
   }

   // Se ambos desabilitados, não precisa criar indicadores
   if(!m_useTrendFilter && m_neutralDistance == 0)
     {
      m_isInitialized = true;
      m_isEnabled = true;
      m_maReady = true;
      
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "WARNING", 
            "⚠️ [Trend Filter] Ambos modos desabilitados - sem efeito");
      
      return true;
     }

   // ═══════════════════════════════════════════════════════════════
   // 🆕 v2.15: PADRÃO SMARTCROSS - SÓ CRIAR HANDLE!
   // NÃO tenta copiar buffer aqui (deixa para o primeiro tick)
   // ═══════════════════════════════════════════════════════════════
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
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", msg);
      else
         Print(msg);
      return false;
     }

   // ✅ Handle criado com sucesso!
   m_isInitialized = true;
   m_isEnabled = true;
   m_maReady = false;  // Será marcada true no primeiro UpdateIndicators() bem-sucedido

   // Log resumido
   string msg = "✅ [Trend Filter] Inicializado | MA " + IntegerToString(m_maPeriod);
   if(m_useTrendFilter)
      msg += " | Direcional: ON";
   if(m_neutralDistance > 0)
      msg += " | Zona: ±" + DoubleToString(m_neutralDistance, 0) + " pts";

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", msg);
   else
      Print(msg);

   return true;
  }

//+------------------------------------------------------------------+
//| Desinicialização (v2.15)                                         |
//+------------------------------------------------------------------+
void CTrendFilter::Deinitialize()
  {
   if(m_handleMA != INVALID_HANDLE)
     {
      IndicatorRelease(m_handleMA);
      m_handleMA = INVALID_HANDLE;
      
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", 
            "🔧 [Trend Filter] Handle MA liberado");
     }

   m_isInitialized = false;
   m_maReady = false;
  }

//+------------------------------------------------------------------+
//| Atualizar indicadores (v2.15)                                    |
//+------------------------------------------------------------------+
bool CTrendFilter::UpdateIndicators()
  {
   if(m_handleMA == INVALID_HANDLE)
      return true;   // Sem handle = filtro desabilitado, não bloqueia sinal

   int calculated = BarsCalculated(m_handleMA);
   if(calculated <= 0)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "UPDATE", 
            "⚠️ [Trend Filter] MA ainda calculando... (aguardar tick)");
      return false;
     }

   int copied = CopyBuffer(m_handleMA, 0, 0, 3, m_ma);
   if(copied < 3)
     {
      m_maReady = false;
      int error = GetLastError();
      string msg = "❌ [Trend Filter] Erro ao copiar buffer MA (copiados: " + IntegerToString(copied) + "/3) - Código: " + IntegerToString(error);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "UPDATE", msg);
      else
         Print(msg);
      return false;
     }
   
   // ═══════════════════════════════════════════════════════════════
   // Validar dados e marcar MA como pronta (se ainda não estiver)
   // ═══════════════════════════════════════════════════════════════
   if(!m_maReady && m_ma[0] > 0 && m_ma[1] > 0)
     {
      m_maReady = true;
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "UPDATE", 
            "✅ [Trend Filter] MA pronta - Filtro LIBERADO para validações!");
     }

   // 🔍 DEBUG: Buffer copiado (throttle por candle)
   if(m_logger != NULL)
     {
      m_logger.Log(LOG_DEBUG, THROTTLE_CANDLE, "UPDATE",
         StringFormat("📊 [Trend Filter] MA atualizada: [0]=%.2f [1]=%.2f", m_ma[0], m_ma[1]));
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Verificar direção da tendência (v2.15)                           |
//+------------------------------------------------------------------+
bool CTrendFilter::CheckTrendDirection(ENUM_SIGNAL_TYPE signal)
  {
   if(!m_useTrendFilter)
      return true;

   double closePrice = iClose(_Symbol, PERIOD_CURRENT, 1);

   if(signal == SIGNAL_BUY)
     {
      if(closePrice < m_ma[1])
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_CANDLE, "INFO", 
               "🔴 [Trend Filter] COMPRA bloqueada - preço abaixo da MA");
         return false;
        }
      else
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "FILTER", 
               "✅ [Trend Filter] COMPRA aprovada - preço acima MA");
        }
     }

   if(signal == SIGNAL_SELL)
     {
      if(closePrice > m_ma[1])
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_CANDLE, "INFO", 
               "🔴 [Trend Filter] VENDA bloqueada - preço acima da MA");
         return false;
        }
      else
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "FILTER", 
               "✅ [Trend Filter] VENDA aprovada - preço abaixo MA");
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Verificar zona neutra (v2.15)                                    |
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
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "FILTER",
         StringFormat("📏 [Trend Filter] Distância: %.1f pts (mín: %.0f)", 
                     distanceInPoints, m_neutralDistance));

   if(distanceInPoints <= m_neutralDistance)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_CANDLE, "INFO",
            StringFormat("🔴 [Trend Filter] Bloqueado - zona neutra (%.1f ≤ %.0f pts)", 
                        distanceInPoints, m_neutralDistance));
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Validar sinal (v2.15 - PADRÃO SMARTCROSS)                        |
//+------------------------------------------------------------------+
bool CTrendFilter::ValidateSignal(ENUM_SIGNAL_TYPE signal)
  {
   if(signal == SIGNAL_NONE)
      return true;

   if(!m_isInitialized)
     {
      string msg = "❌ [Trend Filter] Tentativa de validar sinal SEM estar inicializado!";
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "VALIDATE", msg);
      else
         Print(msg);
      return false;
     }

   // ═══════════════════════════════════════════════════════════════
   // Filtro desabilitado (ambos modos off) — não bloqueia nenhum sinal
   // Initialize() setou m_maReady=true sem criar handle de MA
   // ═══════════════════════════════════════════════════════════════
   if(!m_useTrendFilter && m_neutralDistance == 0)
      return true;

   // ═══════════════════════════════════════════════════════════════
   // 🆕 v2.15: PADRÃO SMARTCROSS - SEMPRE tenta UpdateIndicators() PRIMEIRO!
   // NÃO bloqueia antes de tentar (resolve deadlock)
   // ═══════════════════════════════════════════════════════════════
   if(!UpdateIndicators())
     {
      string msg = "⚠️ [Trend Filter] Aguardando dados da MA - próximo tick";
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_CANDLE, "VALIDATE", msg);
      return false;
     }

   // ═══════════════════════════════════════════════════════════════
   // VALIDAÇÃO - Dados da MA inválidos (zero)
   // ═══════════════════════════════════════════════════════════════
   if(ArraySize(m_ma) < 2 || m_ma[0] == 0 || m_ma[1] == 0)
     {
      string msg = "⚠️ [Trend Filter] Dados da MA ainda inválidos - aguardando próximo tick";
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_CANDLE, "VALIDATE", msg);
      return false;
     }

   // Verificar filtro direcional
   if(!CheckTrendDirection(signal))
      return false;

   // Verificar zona neutra
   if(!CheckNeutralZone())
      return false;
      
   return true;
  }

// ═══════════════════════════════════════════════════════════════
// HOT RELOAD - MÉTODOS SET QUENTES (v2.15)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| HOT RELOAD - Ativar/desativar filtro direcional (v2.15)          |
//+------------------------------------------------------------------+
bool CTrendFilter::SetTrendFilterEnabled(bool enabled)
  {
   bool oldValue = m_useTrendFilter;
   if(oldValue == enabled) return true;
   m_useTrendFilter = enabled;

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "🔄 [Trend Filter] Filtro direcional: " +
         (oldValue ? "ATIVADO" : "DESATIVADO") + " → " +
         (enabled ? "ATIVADO" : "DESATIVADO"));

   return true;
  }

//+------------------------------------------------------------------+
//| HOT RELOAD - Alterar distância da zona neutra (v2.15)            |
//+------------------------------------------------------------------+
bool CTrendFilter::SetNeutralDistance(double distancePoints)
  {
   if(distancePoints < 0)
     {
      string msg = "[Trend Filter] Distância inválida: " + DoubleToString(distancePoints, 1);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "HOT_RELOAD", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   double oldValue = m_neutralDistance;
   m_neutralDistance = distancePoints;

   if(oldValue != distancePoints && m_logger != NULL)
     {
      string status = (distancePoints > 0) ? "ATIVADA" : "DESATIVADA";
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         StringFormat("🔄 [Trend Filter] Zona neutra: %.0f → %.0f pts (%s)",
                      oldValue, distancePoints, status));
     }

   return true;
  }

// ═══════════════════════════════════════════════════════════════
// COLD RELOAD - MÉTODOS SET FRIOS (v2.15)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar período da MA (v2.15)                      |
//+------------------------------------------------------------------+
bool CTrendFilter::SetMAPeriod(int period)
  {
   if(period <= 0)
     {
      string msg = "[Trend Filter] Período inválido: " + IntegerToString(period);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "COLD_RELOAD", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   int oldValue = m_maPeriod;
   if(oldValue == period) return true;
   m_maPeriod = period;

   Deinitialize();
   bool success = Initialize();

   if(success && m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         StringFormat("🔄 [Trend Filter] Período MA alterado: %d → %d (reiniciado)",
                      oldValue, period));

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar método da MA (v2.15)                       |
//+------------------------------------------------------------------+
bool CTrendFilter::SetMAMethod(ENUM_MA_METHOD method)
  {
   ENUM_MA_METHOD oldMethod = m_maMethod;
   if(oldMethod == method) return true;
   m_maMethod = method;

   Deinitialize();
   bool success = Initialize();

   if(success && m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         "🔄 [Trend Filter] Método MA alterado (reiniciado)");

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar timeframe da MA (v2.18)                    |
//+------------------------------------------------------------------+
bool CTrendFilter::SetMATimeframe(ENUM_TIMEFRAMES tf)
  {
   ENUM_TIMEFRAMES oldTF = m_maTimeframe;
   if(oldTF == tf) return true;
   m_maTimeframe = tf;

   Deinitialize();
   bool success = Initialize();

   if(!success)
      m_maTimeframe = oldTF;   // reverter se falhou
   else if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         "🔄 [Trend Filter] Timeframe MA alterado (reiniciado)");

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Alterar applied price da MA (v2.19)                |
//+------------------------------------------------------------------+
bool CTrendFilter::SetMAApplied(ENUM_APPLIED_PRICE applied)
  {
   ENUM_APPLIED_PRICE oldApplied = m_maApplied;
   if(oldApplied == applied) return true;
   m_maApplied = applied;

   Deinitialize();
   bool success = Initialize();

   if(!success)
      m_maApplied = oldApplied;   // reverter se falhou
   else if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD",
         "🔄 [Trend Filter] Applied price alterado: " +
         EnumToString(oldApplied) + " → " + EnumToString(applied) + " (reiniciado)");

   return success;
  }

//+------------------------------------------------------------------+
//| COLD RELOAD - Setter combinado: 1 única reinicialização (v2.19)  |
//+------------------------------------------------------------------+
bool CTrendFilter::SetMACold(int period, ENUM_MA_METHOD method,
                              ENUM_TIMEFRAMES tf, ENUM_APPLIED_PRICE applied)
  {
   if(period <= 0)
     {
      string msg = "[Trend Filter] SetMACold: período inválido " + IntegerToString(period);
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "COLD_RELOAD", msg);
      else
         Print("❌ ", msg);
      return false;
     }

   int                oldPeriod  = m_maPeriod;
   ENUM_MA_METHOD     oldMethod  = m_maMethod;
   ENUM_TIMEFRAMES    oldTF      = m_maTimeframe;
   ENUM_APPLIED_PRICE oldApplied = m_maApplied;

   bool changed = (oldPeriod != period || oldMethod != method ||
                   oldTF != tf || oldApplied != applied);
   if(!changed) return true;

   m_maPeriod    = period;
   m_maMethod    = method;
   m_maTimeframe = tf;
   m_maApplied   = applied;

   Deinitialize();
   bool success = Initialize();

   if(!success)
     {
      // reverter tudo se falhou
      m_maPeriod    = oldPeriod;
      m_maMethod    = oldMethod;
      m_maTimeframe = oldTF;
      m_maApplied   = oldApplied;
      Deinitialize();
      Initialize();
     }
   else if(m_logger != NULL)
     {
      string msg = StringFormat("🔄 [Trend Filter] Cold reload: MA %d→%d / %s→%s / %s→%s / %s→%s",
                                oldPeriod, period,
                                EnumToString(oldMethod), EnumToString(method),
                                EnumToString(oldTF), EnumToString(tf),
                                EnumToString(oldApplied), EnumToString(applied));
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "COLD_RELOAD", msg);
     }

   return success;
  }

//+------------------------------------------------------------------+
//| Getters                                                           |
//+------------------------------------------------------------------+
double CTrendFilter::GetMA(int shift = 0)
  {
   if(!m_isInitialized || !m_maReady || shift >= ArraySize(m_ma))
      return 0.0;

   return m_ma[shift];
  }

double CTrendFilter::GetDistanceFromMA()
  {
   if(!m_isInitialized || !m_maReady || ArraySize(m_ma) < 1)
      return 0.0;

   if(m_ma[0] <= 0)
      return 0.0;

   double currentPrice = iClose(_Symbol, PERIOD_CURRENT, 0);
   double distance = currentPrice - m_ma[0];

   double pointValue = _Point;
   if(_Digits == 3 || _Digits == 5)
      pointValue *= 10;

   return distance / pointValue;
  }
//+------------------------------------------------------------------+
