//+------------------------------------------------------------------+
//|                                              EPBot_Matrix.mq5    |
//|                                      Copyright 2026, EP Filho    |
//|                    EA Modular Multistrategy - EPBot Matrix        |
//|                    Versão 1.59 - Correções de qualidade         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO"
#property version   "1.59"
#property description "EPBot Matrix - Sistema de Trading Modular Multi Estratégias"

#define EA_VERSION "1.59"

//+------------------------------------------------------------------+
//| CHANGELOG v1.59 (Correções de qualidade):                       |
//| FIX 1 — UpdateStats() agora usa totalPositionProfit em vez de   |
//|          finalDealProfit, eliminando inconsistência entre        |
//|          Logger.m_dailyWins/Losses e o cálculo do Streak.       |
//| FIX 2 — FetchDealRealValues() extraido como método privado em   |
//|          TradeManager.mqh, remove bloco duplicado TP1/TP2.      |
//| FIX 3 — Janela HistorySelect em TradeManager: 60s -> 300s       |
//|          (brokers com alta latência).                            |
//| FIX 4 — GetTypeFilling() centralizado em Core/Utils.mqh,        |
//|          remove duplicata em TradeManager e EPBot_Matrix.        |
//| FIX 5 — SaveState(): fallback de cópia agora loga cada etapa.   |
//| FIX 6 — PrintConfiguration() em Blockers.mqh imprime todos os   |
//|          parâmetros de limites, streak e drawdown.               |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| CHANGELOG v1.58 (Refatoração crítica):                           |
//| FIX 1 — ResetDaily do Blockers agora chamado em TODOS os dias,   |
//|          inclusive quando não houve trades no dia anterior.       |
//| FIX 2 — isVMActive usa g_maCrossStrategy.GetEnabled() em vez de  |
//|          inp_UseMACross (não reflete hot reload via GUI).         |
//| FIX 3 — EXIT_VM verifica CanTrade() + CanTradeDirection() antes  |
//|          de ExecuteTrade (bypasse de blockers corrigido).         |
//| FIX 4 — Breakeven protege TP=0 quando tp2Executed=true,          |
//|          comportamento idêntico ao Trailing.                      |
//| FIX 5 — Guard para posição duplicada: detecta >1 posição com     |
//|          mesmo magic e loga alerta crítico.                       |
//| FIX 6 — iTime() calculado uma única vez por OnTick, reutilizado  |
//|          (elimina chamada duplicada e variável redundante).       |
//| FIX 7 — g_tradingAllowed removido (era variável morta).          |
//| FIX 8 — Ordem de ResetDaily corrigida: Blockers.ResetDaily()     |
//|          chamado ANTES de Logger.ResetDaily() para evitar leitura |
//|          de profit zerado durante o reset do Blockers.            |
//+------------------------------------------------------------------+
//| CHANGELOG v1.57 (Parte 031):                                     |
//| - Fix: memory leak no OnDeinit — g_bbStrategy e g_bbFilter não   |
//|   eram deletados na ETAPA 2 (CleanupAll só roda em INIT_FAILED)  |
//| - Botão INICIAR/PAUSAR no topo do painel (acima das tabs)        |
//|   Estado inicial: PAUSADO (verde "INICIAR EA")                   |
//|   Ao clicar: alterna para ATIVO (amarelo "PAUSAR EA")            |
//| - Guard no OnTick: bloqueia abertura de novas posições quando     |
//|   pausado, mas NÃO afeta gerenciamento de posições abertas       |
//| - Tester: g_panel==NULL → guard bypassed, trading funciona normal |
//| - STATUS tab: mostra "PAUSADO" (amarelo) quando EA não iniciado   |
//| - Layout: PANEL_HEIGHT 600→626, CONTENT_TOP +26px (START_BTN_H)  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| ✅ CORRIGIDO v1.59 (era KNOWN LIMITATION em 2026-03):          |
//| ⚠️ INCONSISTÊNCIA: Logger.m_dailyWins/Losses vs Streak           |
//| Quando TP1+TP2 executam E o deal final fecha no prejuízo:        |
//| - Streak usa totalPositionProfit → WIN ✅                        |
//| - Logger UpdateStats() usa totalPositionProfit → WIN ✅        |
//| Bug eliminado — consistência total entre Logger e Streak.      |
//| Ver análise completa no histórico do projeto.                     |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| NOTAS TÉCNICAS / DÉBITOS TÉCNICOS                                |
//+------------------------------------------------------------------+
// [1] GAP Init/CreatePanel — Parte 025
// RegisterPanels() é chamado em Init(), mas controles GUI só são
// criados em CreatePanel(). Timer só ativa após CreatePanel() —
// não é bug hoje, mas atenção ao refatorar ciclo de vida.
//
// [2] Assimetria de API StrategyBase x FilterBase — Parte 025
// CStrategyBase usa GetEnabled() / SetEnabled()
// CFilterBase  usa IsEnabled()  / SetEnabled()
// Unificar para GetEnabled() nas duas bases quando conveniente.
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| INCLUDES - ORDEM IMPORTANTE                                      |
//+------------------------------------------------------------------+
// 0️⃣ RUNTIME VARS — cópias editáveis dos inputs (hot reload)
int    g_magicNumber  = 0;
int    g_slippage     = 0;
string g_tradeComment = "";

// 1️⃣ INPUTS CENTRALIZADOS
#include "Core/Inputs.mqh"

// 1.5️⃣ ESTRATÉGIA BASE
#include "Strategy/Base/StrategyBase.mqh"

// 2️⃣ MÓDULOS CORE
#include "Core/TradeManager.mqh"

// 3️⃣ FILTROS ADICIONAIS
#include "Strategy/Filters/TrendFilter.mqh"

// 4️⃣ GUI
#include "GUI/Panel.mqh"

//+------------------------------------------------------------------+
//| VARIÁVEIS GLOBAIS                                                |
//+------------------------------------------------------------------+
CLogger*                  g_logger          = NULL;
CBlockers*                g_blockers        = NULL;
CRiskManager*             g_riskManager     = NULL;
CTradeManager*            g_tradeManager    = NULL;
CSignalManager*           g_signalManager   = NULL;

CMACrossStrategy*         g_maCrossStrategy = NULL;
CRSIStrategy*             g_rsiStrategy     = NULL;
CBollingerBandsStrategy*  g_bbStrategy      = NULL;

CTrendFilter*             g_trendFilter     = NULL;
CRSIFilter*               g_rsiFilter       = NULL;
CBollingerBandsFilter*    g_bbFilter        = NULL;

CEPBotPanel*              g_panel           = NULL;

datetime g_lastBarTime        = 0;
datetime g_lastTradeBarTime   = 0;
datetime g_lastExitBarTime    = 0;
ulong    g_lastPositionTicket = 0;
// REMOVIDO: g_tradingAllowed — era variável morta (FIX 7)

//+------------------------------------------------------------------+
//| CLEANUP — libera todos os objetos globais (null-safe)            |
//+------------------------------------------------------------------+
void CleanupAll()
{
   if(g_panel != NULL)
   {
      g_panel.Destroy(REASON_INITFAILED);
      delete g_panel;
      g_panel = NULL;
   }
   EventKillTimer();

   if(g_signalManager != NULL)
   {
      g_signalManager.Deinitialize();
      g_signalManager.Clear();
   }

   if(g_bbFilter        != NULL) { delete g_bbFilter;        g_bbFilter        = NULL; }
   if(g_rsiFilter       != NULL) { delete g_rsiFilter;       g_rsiFilter       = NULL; }
   if(g_trendFilter     != NULL) { delete g_trendFilter;     g_trendFilter     = NULL; }
   if(g_bbStrategy      != NULL) { delete g_bbStrategy;      g_bbStrategy      = NULL; }
   if(g_rsiStrategy     != NULL) { delete g_rsiStrategy;     g_rsiStrategy     = NULL; }
   if(g_maCrossStrategy != NULL) { delete g_maCrossStrategy; g_maCrossStrategy = NULL; }

   if(g_signalManager != NULL) { delete g_signalManager; g_signalManager = NULL; }
   if(g_riskManager   != NULL) { delete g_riskManager;   g_riskManager   = NULL; }
   if(g_tradeManager  != NULL) { delete g_tradeManager;  g_tradeManager  = NULL; }
   if(g_blockers      != NULL) { delete g_blockers;      g_blockers      = NULL; }
   if(g_logger        != NULL) { delete g_logger;        g_logger        = NULL; }
}

//+------------------------------------------------------------------+
//| OnInit()                                                         |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("════════════════════════════════════════════════════════════════");
   Print(" EPBOT MATRIX v" + EA_VERSION + " - INICIALIZANDO... ");
   Print("════════════════════════════════════════════════════════════════");

   g_magicNumber  = inp_MagicNumber;
   g_slippage     = inp_Slippage;
   g_tradeComment = inp_TradeComment;

   //--- ETAPA 1: LOGGER
   g_logger = new CLogger();
   if(g_logger == NULL) { Print("❌ Falha ao criar Logger!"); return INIT_FAILED; }
   if(!g_logger.Init(inp_ShowDebugLogs, _Symbol, g_magicNumber, inp_DebugCooldownSec))
   {
      Print("❌ Falha ao inicializar Logger!");
      CleanupAll();
      return INIT_FAILED;
   }

   //--- ETAPA 2: BLOCKERS
   g_blockers = new CBlockers();
   if(g_blockers == NULL)
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar Blockers!");
      CleanupAll();
      return INIT_FAILED;
   }
   if(!g_blockers.Init(
         g_logger, g_magicNumber,
         inp_EnableTimeFilter,
         inp_StartHour, inp_StartMinute, inp_EndHour, inp_EndMinute,
         inp_CloseOnEndTime, inp_CloseBeforeSessionEnd, inp_MinutesBeforeSessionEnd,
         inp_EnableNews1, inp_News1StartH, inp_News1StartM, inp_News1EndH, inp_News1EndM,
         inp_EnableNews2, inp_News2StartH, inp_News2StartM, inp_News2EndH, inp_News2EndM,
         inp_EnableNews3, inp_News3StartH, inp_News3StartM, inp_News3EndH, inp_News3EndM,
         inp_MaxSpread,
         inp_EnableDailyLimits,
         inp_MaxDailyTrades, inp_MaxDailyLoss, inp_MaxDailyGain,
         inp_ProfitTargetAction,
         inp_EnableStreakControl,
         inp_MaxLossStreak, inp_LossStreakAction, inp_LossPauseMinutes,
         inp_MaxWinStreak,  inp_WinStreakAction,  inp_WinPauseMinutes,
         inp_EnableDrawdown, inp_DrawdownType, inp_DrawdownValue, inp_DrawdownPeakMode,
         inp_TradeDirection
      ))
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar Blockers!");
      CleanupAll();
      return INIT_FAILED;
   }

   //--- ETAPA 3: RISK MANAGER
   g_riskManager = new CRiskManager();
   if(g_riskManager == NULL)
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar RiskManager!");
      CleanupAll();
      return INIT_FAILED;
   }

   double tp3_percent = 100.0 - inp_PartialTP1_Percent - inp_PartialTP2_Percent;
   if(inp_UsePartialTP)
   {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG", "🎯 PARTIAL TAKE PROFIT:");
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG", StringFormat("  TP1: %.1f%% @ %d pts", inp_PartialTP1_Percent, inp_PartialTP1_Distance));
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG", StringFormat("  TP2: %.1f%% @ %d pts", inp_PartialTP2_Percent, inp_PartialTP2_Distance));
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG", StringFormat("  TP3: %.1f%% (restante)", tp3_percent));
   }

   if(!g_riskManager.Init(
         g_logger,
         inp_LotSize,
         inp_SLType, inp_FixedSL, inp_SL_ATRMultiplier, inp_RangePeriod, inp_RangeMultiplier, inp_SL_CompensateSpread,
         inp_TPType, inp_FixedTP, inp_TP_ATRMultiplier, inp_TP_CompensateSpread,
         inp_TrailingType, inp_TrailingStart, inp_TrailingStep, inp_TrailingATRStart, inp_TrailingATRStep, inp_Trailing_CompensateSpread,
         inp_BEType, inp_BEActivation, inp_BEOffset, inp_BE_ATRActivation, inp_BE_ATROffset,
         inp_UsePartialTP,
         true,  inp_PartialTP1_Percent, TP_FIXED, inp_PartialTP1_Distance, 0,
         true,  inp_PartialTP2_Percent, TP_FIXED, inp_PartialTP2_Distance, 0,
         inp_TrailingActivation, inp_BEActivationMode,
         _Symbol, inp_ATRPeriod
      ))
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar RiskManager!");
      CleanupAll();
      return INIT_FAILED;
   }
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "RiskManager inicializado!");

   //--- ETAPA 3.5: VALIDAR CONFIGURAÇÃO
   if(inp_UsePartialTP && inp_TPType == TP_ATR)
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "❌ CONFLITO: Partial TP + TP_ATR são incompatíveis!");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "   Use TP_FIXED ou TP_NONE com Partial TP.");
      CleanupAll();
      return INIT_FAILED;
   }

      //--- ETAPA 4: TRADE MANAGER
   g_tradeManager = new CTradeManager();
   if(g_tradeManager == NULL)
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar TradeManager!");
      CleanupAll();
      return INIT_FAILED;
   }
   if(!g_tradeManager.Init(g_logger, g_riskManager, _Symbol, g_magicNumber, g_slippage))
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar TradeManager!");
      CleanupAll();
      return INIT_FAILED;
   }
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "TradeManager inicializado!");

   //--- ETAPA 4.5: RESSINCRONIZAR POSIÇÕES EXISTENTES
   int syncedPositions = g_tradeManager.ResyncExistingPositions();
   if(syncedPositions > 0)
   {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
         "🔄 " + IntegerToString(syncedPositions) + " posição(ões) ressincronizada(s)");

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(PositionGetSymbol(i) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == g_magicNumber)
         {
            g_lastPositionTicket = PositionGetTicket(i);
            g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
               StringFormat("🔄 lastPositionTicket sincronizado: %I64u", g_lastPositionTicket));
            break;
         }
      }
   }

   //--- ETAPA 5: SIGNAL MANAGER
   g_signalManager = new CSignalManager();
   if(g_signalManager == NULL)
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar SignalManager!");
      CleanupAll();
      return INIT_FAILED;
   }
   if(!g_signalManager.Initialize(g_logger))
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar SignalManager!");
      CleanupAll();
      return INIT_FAILED;
   }
   g_signalManager.SetConflictResolution(inp_ConflictMode);

   //--- ETAPA 6: STRATEGIES

   // 6.1: MA CROSS
   g_maCrossStrategy = new CMACrossStrategy();
   if(g_maCrossStrategy == NULL) { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar MACrossStrategy!"); CleanupAll(); return INIT_FAILED; }
   if(!g_maCrossStrategy.Setup(g_logger,
         inp_FastPeriod, inp_FastMethod, inp_FastApplied, inp_FastTF,
         inp_SlowPeriod, inp_SlowMethod, inp_SlowApplied, inp_SlowTF,
         inp_EntryMode, inp_ExitMode, inp_MACrossMinDistance))
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao configurar MACrossStrategy!"); CleanupAll(); return INIT_FAILED; }
   if(!g_maCrossStrategy.Initialize())
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar MACrossStrategy!"); CleanupAll(); return INIT_FAILED; }
   g_maCrossStrategy.SetEnabled(inp_UseMACross);
   g_maCrossStrategy.SetPriority(inp_MACrossPriority);
   if(!g_signalManager.AddStrategy(g_maCrossStrategy))
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar MACrossStrategy!"); CleanupAll(); return INIT_FAILED; }
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
      "MACrossStrategy registrada" + (inp_UseMACross ? " (ATIVA)" : " (INATIVA)") +
      " - Prioridade: " + IntegerToString(inp_MACrossPriority));

   // 6.2: RSI
   g_rsiStrategy = new CRSIStrategy();
   if(g_rsiStrategy == NULL) { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar RSIStrategy!"); CleanupAll(); return INIT_FAILED; }
   if(!g_rsiStrategy.Setup(g_logger, _Symbol, inp_RSITF, inp_RSIPeriod, inp_RSIApplied,
         inp_RSIMode, inp_RSIOversold, inp_RSIOverbought, inp_RSIMidLevel))
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao configurar RSIStrategy!"); CleanupAll(); return INIT_FAILED; }
   if(!g_rsiStrategy.Initialize())
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar RSIStrategy!"); CleanupAll(); return INIT_FAILED; }
   g_rsiStrategy.SetEnabled(inp_UseRSI);
   g_rsiStrategy.SetPriority(inp_RSIPriority);
   if(!g_signalManager.AddStrategy(g_rsiStrategy))
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar RSIStrategy!"); CleanupAll(); return INIT_FAILED; }
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
      "RSIStrategy registrada" + (inp_UseRSI ? " (ATIVA)" : " (INATIVA)") +
      " - Prioridade: " + IntegerToString(inp_RSIPriority));

   // 6.3: BOLLINGER BANDS
   g_bbStrategy = new CBollingerBandsStrategy();
   if(g_bbStrategy == NULL) { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar BBStrategy!"); CleanupAll(); return INIT_FAILED; }
   if(!g_bbStrategy.Setup(g_logger, _Symbol, inp_BBTF, inp_BBPeriod, inp_BBDeviation,
         inp_BBApplied, inp_BBMode, inp_BBEntryMode, inp_BBExitMode))
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao configurar BBStrategy!"); CleanupAll(); return INIT_FAILED; }
   if(!g_bbStrategy.Initialize())
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar BBStrategy!"); CleanupAll(); return INIT_FAILED; }
   g_bbStrategy.SetEnabled(inp_UseBB);
   g_bbStrategy.SetPriority(inp_BBPriority);
   if(!g_signalManager.AddStrategy(g_bbStrategy))
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar BBStrategy!"); CleanupAll(); return INIT_FAILED; }
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
      "BBStrategy registrada" + (inp_UseBB ? " (ATIVA)" : " (INATIVA)") +
      " - Prioridade: " + IntegerToString(inp_BBPriority));

   //--- ETAPA 7: FILTERS

   // 7.1: TREND FILTER
   g_trendFilter = new CTrendFilter();
   if(g_trendFilter == NULL) { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar TrendFilter!"); CleanupAll(); return INIT_FAILED; }
   if(!g_trendFilter.Setup(g_logger, inp_UseTrendFilter,
         inp_TrendMAPeriod, inp_TrendMAMethod, inp_TrendMAApplied, inp_TrendMATF, inp_TrendMinDistance))
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao configurar TrendFilter!"); CleanupAll(); return INIT_FAILED; }
   if(!g_trendFilter.Initialize())
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar TrendFilter!"); CleanupAll(); return INIT_FAILED; }
   g_trendFilter.SetEnabled(inp_UseTrendFilter || inp_TrendMinDistance > 0);
   if(!g_signalManager.AddFilter(g_trendFilter))
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar TrendFilter!"); CleanupAll(); return INIT_FAILED; }
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
      "TrendFilter registrado" + ((inp_UseTrendFilter || inp_TrendMinDistance > 0) ? " (ATIVO)" : " (INATIVO)"));

   // 7.2: RSI FILTER
   g_rsiFilter = new CRSIFilter();
   if(g_rsiFilter == NULL) { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar RSIFilter!"); CleanupAll(); return INIT_FAILED; }
   if(!g_rsiFilter.Setup(g_logger, _Symbol, inp_RSIFilterTF, inp_RSIFilterPeriod, inp_RSIFilterApplied,
         inp_RSIFilterMode, inp_RSIFilterOversold, inp_RSIFilterOverbought,
         inp_RSIFilterLowerNeutral, inp_RSIFilterUpperNeutral, inp_RSIFilterShift))
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao configurar RSIFilter!"); CleanupAll(); return INIT_FAILED; }
   if(!g_rsiFilter.Initialize())
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar RSIFilter!"); CleanupAll(); return INIT_FAILED; }
   g_rsiFilter.SetEnabled(inp_UseRSIFilter);
   if(!g_signalManager.AddFilter(g_rsiFilter))
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar RSIFilter!"); CleanupAll(); return INIT_FAILED; }
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
      "RSIFilter registrado" + (inp_UseRSIFilter ? " (ATIVO)" : " (INATIVO)"));

   // 7.3: BB FILTER
   g_bbFilter = new CBollingerBandsFilter();
   if(g_bbFilter == NULL) { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar BBFilter!"); CleanupAll(); return INIT_FAILED; }
   if(!g_bbFilter.Setup(g_logger, _Symbol, inp_BBFiltTF, inp_BBFiltPeriod, inp_BBFiltDeviation,
         inp_BBFiltApplied, inp_BBFiltMetric, inp_BBFiltThreshold, inp_BBFiltPercPeriod))
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao configurar BBFilter!"); CleanupAll(); return INIT_FAILED; }
   if(!g_bbFilter.Initialize())
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar BBFilter!"); CleanupAll(); return INIT_FAILED; }
   g_bbFilter.SetEnabled(inp_UseBBFilter);
   if(!g_signalManager.AddFilter(g_bbFilter))
   { g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar BBFilter!"); CleanupAll(); return INIT_FAILED; }
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
      "BBFilter registrado" + (inp_UseBBFilter ? " (ATIVO)" : " (INATIVO)"));

   //--- ETAPA 8: CONFIGURAÇÕES FINAIS
   g_lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

   //--- ETAPA 9: PAINEL GUI
   if(g_panel != NULL && (!inp_ShowPanel || MQLInfoInteger(MQL_TESTER)))
   {
      g_panel.Destroy(REASON_REMOVE);
      delete g_panel;
      g_panel = NULL;
   }

   if(inp_ShowPanel && !MQLInfoInteger(MQL_TESTER))
   {
      if(g_panel != NULL)
      {
         g_panel.ReconnectModules(g_logger, g_blockers, g_riskManager, g_tradeManager,
            g_signalManager, g_maCrossStrategy, g_rsiStrategy, g_bbStrategy,
            g_trendFilter, g_rsiFilter, g_bbFilter);
         EventSetMillisecondTimer(1500);
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "Painel GUI reconectado (troca de TF)");
      }
      else
      {
         g_panel = new CEPBotPanel();
         if(g_panel != NULL)
         {
            g_panel.Init(g_logger, g_blockers, g_riskManager, g_tradeManager,
               g_signalManager, g_maCrossStrategy, g_rsiStrategy, g_bbStrategy,
               g_trendFilter, g_rsiFilter, g_bbFilter,
               g_magicNumber, _Symbol);

            int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
            int x1 = chartWidth - PANEL_WIDTH - 10;
            if(!g_panel.CreatePanel(0, "EPBotMatrix - Versão " + EA_VERSION,
                  0, x1, 20, x1 + PANEL_WIDTH, 20 + PANEL_HEIGHT))
            {
               g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar painel GUI");
               delete g_panel;
               g_panel = NULL;
            }
            else
            {
               g_panel.Run();
               EventSetMillisecondTimer(1500);
                              g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "Painel GUI criado com sucesso");
            }
         }
      }
   }

   //--- ETAPA 10: PERSISTÊNCIA DE CONFIGURAÇÕES
   if(!MQLInfoInteger(MQL_TESTER) && g_panel != NULL)
   {
      int prevReason = UninitializeReason();
      if(prevReason == REASON_PARAMETERS)
      {
         CConfigPersistence::Delete(_Symbol, g_magicNumber);
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG", "Preset alterado - config salva deletada");
      }
      else if(prevReason == REASON_CHARTCHANGE || prevReason == REASON_TEMPLATE)
      {
         if(CConfigPersistence::Exists(_Symbol, g_magicNumber))
         {
            SConfigData loadedData; ZeroMemory(loadedData);
            if(CConfigPersistence::Load(_Symbol, g_magicNumber, loadedData))
            {
               g_panel.ApplyLoadedConfig(loadedData);
               g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG", "Config carregada automaticamente (TF/template)");
            }
         }
      }
      else if(prevReason == REASON_CLOSE || prevReason == REASON_REMOVE)
      {
         if(CConfigPersistence::Exists(_Symbol, g_magicNumber))
         {
            SConfigData loadedData; ZeroMemory(loadedData);
            if(CConfigPersistence::Load(_Symbol, g_magicNumber, loadedData))
            {
               g_panel.ShowLoadBanner(loadedData);
               g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG", "Config salva encontrada - banner exibido");
            }
         }
      }
      else if(prevReason == REASON_RECOMPILE || prevReason == REASON_ACCOUNT)
      {
         if(CConfigPersistence::Exists(_Symbol, g_magicNumber))
         {
            SConfigData loadedData; ZeroMemory(loadedData);
            if(CConfigPersistence::Load(_Symbol, g_magicNumber, loadedData))
            {
               g_panel.ApplyLoadedConfig(loadedData);
               g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG", "Config carregada automaticamente (recompile/account)");
            }
         }
      }
      else
      {
         // REASON_PROGRAM e outros: EA adicionado fresh
         if(CConfigPersistence::Exists(_Symbol, g_magicNumber))
         {
            SConfigData loadedData; ZeroMemory(loadedData);
            if(CConfigPersistence::Load(_Symbol, g_magicNumber, loadedData))
            {
               g_panel.ShowLoadBanner(loadedData);
               g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG",
                  "Config salva encontrada (reason=" + IntegerToString(prevReason) + ") - banner exibido");
            }
         }
      }
   }

   Print("════════════════════════════════════════════════════════════════");
   Print(" ✅ EPBOT MATRIX INICIALIZADO COM SUCESSO! ");
   Print("════════════════════════════════════════════════════════════════");
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "🚀 EPBot Matrix v" + EA_VERSION + " - PRONTO!");
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📊 Símbolo: " + _Symbol);
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "⏰ Timeframe: " + EnumToString(PERIOD_CURRENT));
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "🎯 Magic: " + IntegerToString(g_magicNumber));
   if(inp_UsePartialTP)
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "🎯 Partial TP: ATIVADO");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit()                                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_logger != NULL)
   {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT", "════════════════════════════════════════");
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT", " EPBOT MATRIX - FINALIZANDO...");
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT", "Motivo: " + IntegerToString(reason) +
         " - " + GetDeinitReasonText(reason));

      if(g_logger.GetDailyTrades() > 0)
      {
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT", "📄 Gerando relatório final...");
         g_logger.SaveDailyReport();
      }
   }

   // PAINEL
   if(g_panel != NULL)
   {
      if(reason == REASON_CHARTCHANGE)
      {
         // Mantém painel vivo — OnInit vai reconectar via ReconnectModules()
         // Apenas mata o timer; painel e objetos gráficos preservados
      }
      else
      {
         g_panel.Destroy(REASON_REMOVE);
         delete g_panel;
         g_panel = NULL;
      }
   }
   EventKillTimer();

   // SignalManager: desinicializar antes de deletar strategies/filters
   if(g_signalManager != NULL)
   {
      g_signalManager.Deinitialize();
      g_signalManager.Clear();
   }

   // Deletar filters e strategies
   if(g_bbFilter        != NULL) { delete g_bbFilter;        g_bbFilter        = NULL; }
   if(g_rsiFilter       != NULL) { delete g_rsiFilter;       g_rsiFilter       = NULL; }
   if(g_trendFilter     != NULL) { delete g_trendFilter;     g_trendFilter     = NULL; }
   if(g_bbStrategy      != NULL) { delete g_bbStrategy;      g_bbStrategy      = NULL; }
   if(g_rsiStrategy     != NULL) { delete g_rsiStrategy;     g_rsiStrategy     = NULL; }
   if(g_maCrossStrategy != NULL) { delete g_maCrossStrategy; g_maCrossStrategy = NULL; }

   // Deletar SignalManager
   if(g_signalManager != NULL) { delete g_signalManager; g_signalManager = NULL; }

   // Deletar módulos base
   if(g_riskManager  != NULL) { delete g_riskManager;  g_riskManager  = NULL; }
   if(g_tradeManager != NULL) { delete g_tradeManager;  g_tradeManager = NULL; }
   if(g_blockers     != NULL) { delete g_blockers;      g_blockers     = NULL; }
   if(g_logger       != NULL) { delete g_logger;        g_logger       = NULL; }

   Print("════════════════════════════════════════════════════════════════");
   Print(" ✅ EPBOT MATRIX FINALIZADO COM SUCESSO! ");
   Print("════════════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| OnTick()                                                         |
//+------------------------------------------------------------------+
void OnTick()
{
   // ═══════════════════════════════════════════════════════════════
   // ETAPA 1: iTime calculado UMA vez — reutilizado em todo o tick
   // FIX 6: elimina chamadas duplicadas e variável redundante
   // ═══════════════════════════════════════════════════════════════
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   bool isNewBar = (currentBarTime != g_lastBarTime);
   if(isNewBar)
   {
      g_lastBarTime = currentBarTime;
      g_logger.Log(LOG_DEBUG, THROTTLE_CANDLE, "TICK",
         "🕐 Novo candle: " + TimeToString(currentBarTime));
   }

   // ═══════════════════════════════════════════════════════════════
   // DETECTAR MUDANÇA DE DIA
   // ═══════════════════════════════════════════════════════════════
   static int lastDay = 0;
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);

   if(lastDay != 0 && timeStruct.day != lastDay)
   {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY", "═══════════════════════════════════════");
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY",
         "📅 NOVO DIA: " + TimeToString(TimeCurrent(), TIME_DATE));
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY", "═══════════════════════════════════════");

      if(g_logger.GetDailyTrades() > 0)
      {
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY", "📄 Gerando relatório do dia anterior...");
         g_logger.SaveDailyReport();

         // FIX 8: Blockers.ResetDaily() ANTES de Logger.ResetDaily()
         // para que o Blockers ainda leia o dailyProfit correto
         // durante seu próprio reset (ex: pico de drawdown).
         g_blockers.ResetDaily();
         g_logger.ResetDaily();

         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY", "✅ Relatório salvo - novo dia iniciado");
      }
      else
      {
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY", "ℹ️ Dia anterior sem trades");

         // FIX 1: ResetDaily chamado mesmo sem trades
         // Sem isso, contadores do Blockers (dailyTrades, streaks,
         // profit limits) acumulavam do dia anterior silenciosamente.
         g_blockers.ResetDaily();
         // Logger não precisa de reset (contadores já estão zerados),
         // mas chamamos para garantir consistência de estado interno.
         g_logger.ResetDaily();
      }
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY", "═══════════════════════════════════════");
   }
   lastDay = timeStruct.day;

   // ═══════════════════════════════════════════════════════════════
   // ETAPA 1.5: DETECTAR FECHAMENTO DE POSIÇÃO
   // ═══════════════════════════════════════════════════════════════

   // FIX 5: Contar posições deste EA para detectar duplicata
   bool hasMyPosition  = false;
   ulong myPositionTicket = 0;
   int   myPositionCount  = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetSymbol(i) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) == g_magicNumber)
      {
         myPositionCount++;
         if(!hasMyPosition)
         {
            hasMyPosition  = true;
            myPositionTicket = PositionGetTicket(i);
         }
      }
   }

   // FIX 5: Alerta crítico se houver mais de uma posição aberta
   if(myPositionCount > 1)
   {
      g_logger.Log(LOG_ERROR, THROTTLE_TIME,
         "POSITION",
         StringFormat("⚠️ ALERTA: %d posições abertas com magic %d! "
                      "Apenas a primeira está sendo gerenciada. "
                      "Verifique e feche manualmente as demais.",
                      myPositionCount, g_magicNumber),
         30);
   }

   // Se tinha posição registrada e agora não tem mais = fechou
   if(g_lastPositionTicket > 0 && !hasMyPosition)
   {
      if(HistorySelectByPosition(g_lastPositionTicket))
      {
         double totalPositionProfit = 0;
         double finalDealProfit     = 0;
         ulong  finalDealTicket     = 0;
         bool   foundFinalDeal      = false;

         for(int i = 0; i < HistoryDealsTotal(); i++)
         {
            ulong dealTicket = HistoryDealGetTicket(i);
            if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == g_lastPositionTicket)
            {
               long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
               if(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY)
               {
                  double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                  totalPositionProfit += dealProfit;

                  string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
                  if(StringFind(dealComment, "Partial") >= 0) continue;

                  finalDealProfit = dealProfit;
                  finalDealTicket = dealTicket;
                  foundFinalDeal  = true;
               }
            }
         }

         if(foundFinalDeal)
         {
            g_logger.SaveTrade(g_lastPositionTicket, finalDealProfit);

            // ⚠️ KNOWN LIMITATION: UpdateStats usa finalDealProfit,
            // streak usa totalPositionProfit. Ver changelog v1.58.
            g_logger.UpdateStats(totalPositionProfit);

            bool isWin = (totalPositionProfit > 0);
            g_blockers.UpdateAfterTrade(isWin, finalDealProfit);

            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "CLOSE",
               "📊 Posição #" + IntegerToString(g_lastPositionTicket) +
               " fechada | P/L final: $" + DoubleToString(finalDealProfit, 2) +
               " | Total posição: $" + DoubleToString(totalPositionProfit, 2));

            g_logger.SaveDailyReport();
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "REPORT", "📄 Relatório atualizado");
         }
      }

      g_tradeManager.UnregisterPosition(g_lastPositionTicket);

      // Bloquear re-entrada no mesmo candle (exceto VM)
            if(inp_ExitMode != EXIT_VM)
      {
         g_lastTradeBarTime = currentBarTime; // FIX 6: reutiliza var já calculada
         g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "RESET",
            "🔄 Controle de candle atualizado - aguardando próximo candle");
      }
      g_lastPositionTicket = 0;
   }

   // ═══════════════════════════════════════════════════════════════
   // SE EXISTE POSIÇÃO: GERENCIAR
   // ═══════════════════════════════════════════════════════════════
   if(hasMyPosition)
   {
      g_lastPositionTicket = myPositionTicket;

      if(!PositionSelectByTicket(myPositionTicket))
      {
         g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "POSITION",
            "⚠️ Falha ao selecionar posição #" + IntegerToString((int)myPositionTicket));
         return;
      }

      ulong ticket   = PositionGetInteger(POSITION_TICKET);
      double volume  = PositionGetDouble(POSITION_VOLUME);
      ENUM_POSITION_TYPE posType =
         (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      double closePrice = (posType == POSITION_TYPE_BUY)
         ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
         : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      // ─── FECHAMENTO POR HORÁRIO (duas camadas) ───────────────────
      bool   shouldCloseByOperation = false;
      bool   shouldCloseBySession   = false;
      string closeTrigger           = "";

      if(g_blockers != NULL && g_blockers.ShouldCloseOnEndTime(ticket))
      {
         shouldCloseByOperation = true;
         closeTrigger = "Operation";
      }
      if(!shouldCloseByOperation &&
         g_blockers != NULL && g_blockers.ShouldCloseBeforeSessionEnd(ticket))
      {
         shouldCloseBySession = true;
         closeTrigger = "Session";
      }

      if(shouldCloseByOperation || shouldCloseBySession)
      {
         if(closePrice <= 0)
         {
            g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TIME_CLOSE",
               "[Core] Preço inválido - continuando gerenciamento normal");
            ManageOpenPosition(ticket);
            return;
         }

         MqlTradeRequest request = {};
         MqlTradeResult  result  = {};
         request.action       = TRADE_ACTION_DEAL;
         request.position     = ticket;
         request.symbol       = _Symbol;
         request.volume       = volume;
         request.price        = closePrice;
         request.deviation    = g_slippage;
         request.type         = (posType == POSITION_TYPE_BUY)
                                 ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
         request.type_filling = GetTypeFilling(_Symbol);
         request.magic        = g_magicNumber;
         request.comment      = "Close[" + closeTrigger + "]";

         g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TIME_CLOSE",
            "🔒 Fechando posição por: " + closeTrigger +
            " | Ticket: " + IntegerToString((int)ticket));

         if(!OrderSend(request, result))
         {
            g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TIME_CLOSE",
               "[Core] OrderSend falhou - Erro: " + IntegerToString(GetLastError()));
            ManageOpenPosition(ticket);
            return;
         }

         if(result.retcode == TRADE_RETCODE_DONE)
         {
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TIME_CLOSE",
               "[Core] ✅ Fechado por " + closeTrigger +
               " | Deal: #" + IntegerToString((int)result.deal) +
               " | Preço: " + DoubleToString(result.price, _Digits));
            return;
         }
         else
         {
            g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TIME_CLOSE",
               "[Core] Fechamento falhou - Retcode: " + IntegerToString(result.retcode));
            ManageOpenPosition(ticket);
            return;
         }
      }

      // Gerenciamento normal
      ManageOpenPosition(ticket);
      return; // ✅ SEMPRE SAI APÓS GERENCIAR
   }

   // ═══════════════════════════════════════════════════════════════
   // GUARD: EA pausado pelo usuário
   // ═══════════════════════════════════════════════════════════════
   if(g_panel != NULL && !g_panel.IsStarted()) return;

   // ═══════════════════════════════════════════════════════════════
   // ETAPA 2: BLOCKERS (só sem posição aberta)
   // ═══════════════════════════════════════════════════════════════
   int    dailyTrades = g_logger.GetDailyTrades();
   double dailyProfit = g_logger.GetDailyProfit();
   string blockReason = "";

   if(!g_blockers.CanTrade(dailyTrades, dailyProfit, blockReason))
   {
      g_logger.Log(LOG_DEBUG, THROTTLE_TIME, "BLOCKER",
         "🚫 Trading bloqueado: " + blockReason, 60);
      return;
   }

   // ═══════════════════════════════════════════════════════════════
   // ETAPA 3.5: GUARD DE CANDLE
   // FIX 2: usa g_maCrossStrategy.GetEnabled() em vez de
   // inp_UseMACross, que não reflete toggles feitos via GUI.
   // ═══════════════════════════════════════════════════════════════
   bool isVMActive = (g_maCrossStrategy != NULL &&
                      g_maCrossStrategy.GetEnabled() &&
                      inp_ExitMode == EXIT_VM);

   if(!isVMActive)
   {
      if(currentBarTime == g_lastTradeBarTime) // FIX 6: reutiliza var
      {
         g_logger.Log(LOG_DEBUG, THROTTLE_CANDLE, "BLOCKER",
            "⏸️ Já operou neste candle - aguardando próximo");
         return;
      }
   }

   // ═══════════════════════════════════════════════════════════════
   // ETAPA 4: BUSCAR SINAL
   // ═══════════════════════════════════════════════════════════════
   ENUM_SIGNAL_TYPE signal = g_signalManager.GetSignal();
   if(signal == SIGNAL_NONE)
   {
      g_logger.Log(LOG_DEBUG, THROTTLE_CANDLE, "SIGNAL",
         "ℹ️ Nenhum sinal válido");
      return;
   }

   // ═══════════════════════════════════════════════════════════════
   // ETAPA 4.5: BLOQUEIO FCO
   // ═══════════════════════════════════════════════════════════════
   if(inp_ExitMode == EXIT_FCO)
   {
      if(currentBarTime == g_lastExitBarTime) // FIX 6: reutiliza var
      {
         g_logger.Log(LOG_DEBUG, THROTTLE_CANDLE, "FCO",
            "🚫 FCO bloqueado - não entra no sinal do exit");
         return;
      }
   }

   // ═══════════════════════════════════════════════════════════════
   // ETAPA 5: EXECUTAR TRADE
   // ═══════════════════════════════════════════════════════════════
   ExecuteTrade(signal);
}

//+------------------------------------------------------------------+
//| ManageOpenPosition()                                             |
//+------------------------------------------------------------------+
void ManageOpenPosition(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;

   ENUM_POSITION_TYPE posType =
      (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double currentPrice = (posType == POSITION_TYPE_BUY)
      ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
      : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL  = PositionGetDouble(POSITION_SL);

   // Verificar registro no TradeManager
   int index = g_tradeManager.GetPositionIndex(ticket);
   if(index < 0)
   {
      g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "POSITION",
         "⚠️ Posição não encontrada no TradeManager - ignorando gerenciamento");
      return;
   }

   // ─── LIMITES DIÁRIOS EM TEMPO REAL ──────────────────────────────
   double dailyProfit = g_logger.GetDailyProfit();
   string closeReason = "";

   if(g_blockers.ShouldCloseByDailyLimit(ticket, dailyProfit, closeReason))
   {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
         "🚨 " + closeReason);
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
         " Fechando posição #" + IntegerToString((int)ticket) + " IMEDIATAMENTE");

      MqlTradeRequest request = {};
      MqlTradeResult  result  = {};
      request.action       = TRADE_ACTION_DEAL;
      request.position     = ticket;
      request.symbol       = _Symbol;
      request.volume       = PositionGetDouble(POSITION_VOLUME);
      request.type         = (posType == POSITION_TYPE_BUY)
                              ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      request.price        = (posType == POSITION_TYPE_BUY)
                              ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                              : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      request.deviation    = g_slippage;
      request.magic        = g_magicNumber;
      request.comment      = "Daily Limit";
      request.type_filling = GetTypeFilling(_Symbol);

      if(!OrderSend(request, result))
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "DAILY_LIMIT",
            "❌ Erro ao fechar | Retcode: " + IntegerToString(result.retcode) +
            " | " + result.comment);
      else if(result.retcode == TRADE_RETCODE_DONE)
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
            "✅ Posição #" + IntegerToString((int)ticket) + " fechada por limite diário" +
            " | Preço: " + DoubleToString(result.price, _Digits));
      else
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "DAILY_LIMIT",
            "⚠️ Retcode: " + IntegerToString(result.retcode));

      return;
   }

   // ─── DRAWDOWN EM TEMPO REAL ──────────────────────────────────────
   if(g_blockers.IsDrawdownProtectionActive())
   {
      string ddCloseReason = "";
      if(g_blockers.ShouldCloseByDrawdown(ticket, dailyProfit, ddCloseReason))
      {
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
            "🛑 " + ddCloseReason);
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
            " Fechando posição #" + IntegerToString((int)ticket) + " IMEDIATAMENTE");

         MqlTradeRequest request = {};
         MqlTradeResult  result  = {};
         request.action       = TRADE_ACTION_DEAL;
         request.position     = ticket;
         request.symbol       = _Symbol;
         request.volume       = PositionGetDouble(POSITION_VOLUME);
         request.type         = (posType == POSITION_TYPE_BUY)
                                 ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
         request.price        = (posType == POSITION_TYPE_BUY)
                                 ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                 : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         request.deviation    = g_slippage;
         request.magic        = g_magicNumber;
         request.comment      = "Drawdown Limit";
         request.type_filling = GetTypeFilling(_Symbol);

         if(!OrderSend(request, result))
            g_logger.Log(LOG_ERROR, THROTTLE_NONE, "DRAWDOWN",
               "❌ Erro ao fechar | Retcode: " + IntegerToString(result.retcode) +
               " | " + result.comment);
         else if(result.retcode == TRADE_RETCODE_DONE)
            g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
               "✅ Posição #" + IntegerToString((int)ticket) + " fechada por drawdown" +
               " | Preço: " + DoubleToString(result.price, _Digits));
         else
            g_logger.Log(LOG_ERROR, THROTTLE_NONE, "DRAWDOWN",
               "⚠️ Retcode: " + IntegerToString(result.retcode));

         return;
      }
   }

   // ─── PARTIAL TP ──────────────────────────────────────────────────
   if(inp_UsePartialTP)
      g_tradeManager.MonitorPartialTP(ticket);

   bool tp1Executed = g_tradeManager.IsTP1Executed(ticket);
   bool tp2Executed = g_tradeManager.IsTP2Executed(ticket);

   // ─── TRAILING STOP ───────────────────────────────────────────────
   if(g_riskManager.ShouldActivateTrailing(tp1Executed, tp2Executed))
   {
      STrailingResult trailing = g_riskManager.CalculateTrailing(
         posType, currentPrice, entryPrice, currentSL);

      if(trailing.should_move)
      {
         MqlTradeRequest request = {};
         MqlTradeResult  result  = {};
         request.action   = TRADE_ACTION_SLTP;
         request.position = ticket;
         request.symbol   = _Symbol;
         request.sl       = trailing.new_sl_price;

         // Só preserva TP se TP2 ainda não foi executado
                  double tpForLog = 0.0;
         if(!tp2Executed)
         {
            double currentTP = PositionGetDouble(POSITION_TP);
            request.tp = currentTP;
            tpForLog   = currentTP;
         }
         // tp2Executed=true → request.tp fica 0 (sem TP — correto)

         if(OrderSend(request, result))
         {
            string tpInfo = (tpForLog == 0)
               ? " (sem TP)"
               : StringFormat(" | TP: %.5f", tpForLog);
            g_logger.Log(LOG_TRADE, THROTTLE_TIME, "TRAILING",
               StringFormat("✅ Trailing: SL %.5f → %.5f%s",
                  currentSL, trailing.new_sl_price, tpInfo), 5);
         }
         else
         {
            g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRAILING",
               StringFormat("❌ Falha | Pos: #%I64u | Retcode: %d (%s) | SL: %.5f | TP: %.5f",
                  ticket, result.retcode, result.comment,
                  trailing.new_sl_price, tpForLog));
         }
      }
   }

   // ─── BREAKEVEN ───────────────────────────────────────────────────
   if(g_riskManager.ShouldActivateBreakeven(tp1Executed, tp2Executed))
   {
      bool beActivated = g_tradeManager.IsBreakevenActivated(ticket);
      SBreakevenResult breakeven = g_riskManager.CalculateBreakeven(
         posType, currentPrice, entryPrice, currentSL, beActivated);

      if(breakeven.should_activate)
      {
         MqlTradeRequest request = {};
         MqlTradeResult  result  = {};
         request.action   = TRADE_ACTION_SLTP;
         request.position = ticket;
         request.symbol   = _Symbol;
         request.sl       = breakeven.new_sl_price;

         // FIX 4: Breakeven protege TP=0 quando tp2Executed=true,
         // comportamento agora idêntico ao Trailing.
         // Sem esse fix, o BE re-enviava PositionGetDouble(POSITION_TP)
         // que pode ser 0 após TP2, zerando o TP acidentalmente.
         if(!tp2Executed)
            request.tp = PositionGetDouble(POSITION_TP);
         // tp2Executed=true → request.tp fica 0 (sem TP — correto)

         if(OrderSend(request, result))
         {
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "BREAKEVEN",
               "✅ Breakeven ativado em " +
               DoubleToString(breakeven.new_sl_price, _Digits));
            g_tradeManager.SetBreakevenActivated(ticket, true);
         }
      }
   }

   // ─── EXIT SIGNAL ─────────────────────────────────────────────────
   ENUM_SIGNAL_TYPE exitSignal = g_signalManager.GetExitSignal(posType);
   if(exitSignal != SIGNAL_NONE)
   {
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "EXIT",
         "🔄 Exit signal detectado - fechando posição");

      MqlTradeRequest request = {};
      MqlTradeResult  result  = {};
      request.action       = TRADE_ACTION_DEAL;
      request.position     = ticket;
      request.symbol       = _Symbol;
      request.volume       = PositionGetDouble(POSITION_VOLUME);
      request.type         = (posType == POSITION_TYPE_BUY)
                              ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      request.price        = currentPrice;
      request.deviation    = g_slippage;
      request.magic        = g_magicNumber;
      request.comment      = "Exit: " + g_signalManager.GetLastSignalSource();
      request.type_filling = GetTypeFilling(_Symbol);

      if(OrderSend(request, result))
      {
         if(result.retcode == TRADE_RETCODE_DONE)
         {
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "EXIT",
               "✅ Posição fechada por exit signal" +
               " | Fonte: " + g_signalManager.GetLastSignalSource() +
               " | Preço: " + DoubleToString(result.price, _Digits));

            if(inp_ExitMode == EXIT_VM)
            {
               // FIX 3: EXIT_VM verifica CanTrade() + CanTradeDirection()
               // antes de abrir a posição oposta.
               // Sem esse fix, a virada de mão ignorava todos os blockers
               // (horário, spread, limites diários, streak, etc).
               int    dailyTrades = g_logger.GetDailyTrades();
               double dailyProfit = g_logger.GetDailyProfit();
               string blockReason = "";

               if(!g_blockers.CanTrade(dailyTrades, dailyProfit, blockReason))
               {
                  g_logger.Log(LOG_EVENT, THROTTLE_NONE, "VM",
                     "🚫 Virar a Mão bloqueado (CanTrade): " + blockReason);
               }
               else
               {
                  // Determinar tipo da ordem oposta para checar direção
                  ENUM_ORDER_TYPE vmOrderType = (posType == POSITION_TYPE_BUY)
                     ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
                  string dirBlockReason = "";

                  if(!g_blockers.CanTradeDirection(vmOrderType, dirBlockReason))
                  {
                     g_logger.Log(LOG_EVENT, THROTTLE_NONE, "VM",
                        "🚫 Virar a Mão bloqueado (direção): " + dirBlockReason);
                  }
                  else
                  {
                     g_logger.Log(LOG_TRADE, THROTTLE_NONE, "VM",
                        "🔄 VIRAR A MÃO - Executando entrada oposta IMEDIATAMENTE");
                     ExecuteTrade(exitSignal);
                  }
               }
            }
            else // EXIT_FCO
            {
               g_lastExitBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
               g_logger.Log(LOG_TRADE, THROTTLE_NONE, "FCO",
                  "⏸️ EXIT_FCO - bloqueando re-entrada neste sinal");
            }
         }
         else
         {
            g_logger.Log(LOG_ERROR, THROTTLE_NONE, "EXIT",
               "⚠️ Retcode: " + IntegerToString(result.retcode));
         }
      }
      else
      {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "EXIT",
            "❌ Falha ao fechar posição - Código: " +
            IntegerToString(result.retcode));
      }
   }
}

//+------------------------------------------------------------------+
//| ExecuteTrade()                                                   |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_SIGNAL_TYPE signal)
{
   g_logger.Log(LOG_SIGNAL, THROTTLE_NONE, "SIGNAL",
      "════════════════════════════════════════════════════════════════");
   g_logger.Log(LOG_SIGNAL, THROTTLE_NONE, "SIGNAL",
      "🎯 SINAL: " + EnumToString(signal));

   // Determinar tipo de ordem
   ENUM_ORDER_TYPE orderType;
   if     (signal == SIGNAL_BUY)  orderType = ORDER_TYPE_BUY;
   else if(signal == SIGNAL_SELL) orderType = ORDER_TYPE_SELL;
   else
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "SIGNAL",
         "⚠️ Sinal inválido: " + EnumToString(signal));
      return;
   }

   // Filtro de direção
   string dirBlockReason = "";
   if(!g_blockers.CanTradeDirection(orderType, dirBlockReason))
   {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCKER", "🚫 " + dirBlockReason);
      return;
   }

   // Calcular preço
   double price = (orderType == ORDER_TYPE_BUY)
      ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
      : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Lote
   double lotSize = g_riskManager.GetLotSize();
   if(lotSize <= 0)
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRADE",
         "❌ Lote inválido: " + DoubleToString(lotSize, 2));
      return;
   }

   // SL
   double slPrice = g_riskManager.CalculateSLPrice(orderType, price);
   if(slPrice <= 0)
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRADE", "❌ SL inválido");
      return;
   }

   // TP
   double tpPrice = g_riskManager.CalculateTPPrice(orderType, price);

   // Validar SL/TP contra níveis mínimos do broker
   SValidateSLTPResult validation = g_riskManager.ValidateSLTP(
      (orderType == ORDER_TYPE_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL,
      price, slPrice, tpPrice);
   slPrice = validation.validated_sl;
   tpPrice = validation.validated_tp;
   if(validation.sl_adjusted || validation.tp_adjusted)
      g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "VALIDATION", "⚠️ " + validation.message);

   // Montar request
   MqlTradeRequest request = {};
   MqlTradeResult  result  = {};
   request.action       = TRADE_ACTION_DEAL;
   request.symbol       = _Symbol;
   request.volume       = lotSize;
   request.type         = orderType;
   request.price        = price;
   request.sl           = slPrice;
   request.tp           = tpPrice;
   request.deviation    = g_slippage;
   request.magic        = g_magicNumber;
   request.comment      = g_tradeComment;
   request.type_filling = GetTypeFilling(_Symbol);

   g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "📊 Parâmetros:");
   g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "  Tipo:  " + EnumToString(orderType));
   g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "  Lote:  " + DoubleToString(lotSize, 2));
   g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "  Preço: " + DoubleToString(price, _Digits));
   g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "  SL:    " + DoubleToString(slPrice, _Digits));
   g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "  TP:    " +
      (tpPrice > 0 ? DoubleToString(tpPrice, _Digits) : "Partial TP"));

   if(!OrderSend(request, result))
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRADE",
         "❌ Falha ao enviar ordem - Código: " + IntegerToString(result.retcode) +
         " | " + result.comment);
      return;
   }

   if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
   {
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "✅ ORDEM EXECUTADA!");
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE",
         "  Order: " + IntegerToString(result.order));
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE",
         "  Deal:  " + IntegerToString(result.deal));
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE",
         "  Vol:   " + DoubleToString(result.volume, 2));
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE",
         "  Preço: " + DoubleToString(result.price, _Digits));

      // Registrar candle do trade
      g_lastTradeBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

      // ── OBTER TICKET DA POSIÇÃO ──────────────────────────────────
      ulong positionTicket = 0;

      // MÉTODO 1: DEAL_POSITION_ID (institucional)
      if(result.deal > 0)
      {
         datetime from = TimeCurrent() - 60;
         datetime to   = TimeCurrent();
         if(HistorySelect(from, to))
         {
            if(HistoryDealSelect(result.deal))
            {
               positionTicket = HistoryDealGetInteger(result.deal, DEAL_POSITION_ID);
               g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE",
                  StringFormat("🎯 Order: %I64u → Deal: %I64u → Position: %I64u",
                     result.order, result.deal, positionTicket));
            }
            else
               g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "TRADE",
                  "⚠️ Deal não encontrado na história: " + IntegerToString(result.deal));
         }
         else
            g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "TRADE", "⚠️ Falha ao atualizar histórico");
      }

      // MÉTODO 2: FALLBACK por símbolo + magic + tempo
      if(positionTicket == 0 || !PositionSelectByTicket(positionTicket))
      {
         g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "TRADE",
            "⚠️ Fallback: buscando posição por símbolo + magic...");
         int total = PositionsTotal();
         for(int i = 0; i < total; i++)
         {
            ulong tk = PositionGetTicket(i);
            if(tk == 0) continue;
            if(PositionGetString(POSITION_SYMBOL)  == _Symbol &&
                              PositionGetInteger(POSITION_MAGIC) == g_magicNumber)
            {
               datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
               if(TimeCurrent() - openTime < 5)
               {
                  positionTicket = tk;
                  g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE",
                     StringFormat("✅ Posição encontrada (fallback): %I64u", positionTicket));
                  break;
               }
            }
         }
      }

      // Validação final
      if(positionTicket == 0 || !PositionSelectByTicket(positionTicket))
      {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRADE",
            "❌ Posição não encontrada após abertura! Order: " +
            IntegerToString(result.order));
         return;
      }

      // ── REGISTRAR NO TRADEMANAGER ────────────────────────────────
      SPartialTPLevel tpLevels[];
      bool hasPartialTP = inp_UsePartialTP;

      if(hasPartialTP)
      {
         hasPartialTP = g_riskManager.CalculatePartialTPLevels(
            orderType, result.price, result.volume, tpLevels);

         if(hasPartialTP)
         {
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "PARTIAL_TP",
               "🎯 Partial TP configurado:");
            for(int i = 0; i < ArraySize(tpLevels); i++)
            {
               if(tpLevels[i].enabled)
                  g_logger.Log(LOG_TRADE, THROTTLE_NONE, "PARTIAL_TP",
                     "  " + tpLevels[i].description);
            }
         }
      }

      g_tradeManager.RegisterPosition(
         positionTicket,
         (orderType == ORDER_TYPE_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL,
         result.price,
         result.volume,
         hasPartialTP,
         tpLevels
      );

      g_lastPositionTicket = positionTicket;
      g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "TRADE",
         StringFormat("🔄 g_lastPositionTicket: %I64u", g_lastPositionTicket));
   }
   else
   {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRADE",
         "⚠️ Ordem parcialmente executada - Retcode: " +
         IntegerToString(result.retcode) +
         " | " + result.comment);
   }

   g_logger.Log(LOG_SIGNAL, THROTTLE_NONE, "SIGNAL",
      "════════════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| GetTypeFilling()                                                 |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetTypeFilling(string symbol)
{
   uint filling = (uint)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   else if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      return ORDER_FILLING_IOC;
   else
      return ORDER_FILLING_RETURN;
}

//+------------------------------------------------------------------+
//| GetDeinitReasonText()                                            |
//+------------------------------------------------------------------+
string GetDeinitReasonText(int reason)
{
   switch(reason)
   {
      case REASON_PROGRAM:     return "Expert removido do gráfico";
      case REASON_REMOVE:      return "Programa deletado";
      case REASON_RECOMPILE:   return "Programa recompilado";
      case REASON_CHARTCHANGE: return "Símbolo ou timeframe alterado";
      case REASON_CHARTCLOSE:  return "Gráfico fechado";
      case REASON_PARAMETERS:  return "Parâmetros de entrada alterados";
      case REASON_ACCOUNT:     return "Conta alterada";
      case REASON_TEMPLATE:    return "Template aplicado";
      case REASON_INITFAILED:  return "Falha na inicialização";
      case REASON_CLOSE:       return "Terminal fechado";
      default:                 return "Motivo desconhecido";
   }
}

//+------------------------------------------------------------------+
//| OnChartEvent()                                                   |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long   &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(g_panel != NULL)
   {
      g_panel.ChartEvent(id, lparam, dparam, sparam);
      if(id == CHARTEVENT_MOUSE_MOVE)
         g_panel.MouseProtection((int)lparam, (int)dparam);
   }
}

//+------------------------------------------------------------------+
//| OnTimer()                                                        |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(g_panel != NULL)
      g_panel.Update();
}

//+------------------------------------------------------------------+
//| FIM DO EA - EPBOT MATRIX v1.58                                   |
//+------------------------------------------------------------------+
