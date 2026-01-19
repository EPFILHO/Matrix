//+------------------------------------------------------------------+
//|                                                 EPBot_Matrix.mq5 |
//|                                         Copyright 2025, EP Filho |
//|                          EA Modular Multistrategy - EPBot Matrix |
//|                                   Versão 1.12 - Claude Parte 017 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EP Filho"
#property link      "https://github.com/EPFILHO"
#property version   "1.12"
#property description "EPBot Matrix - Sistema de Trading Modular Multi Estratégias"

//+------------------------------------------------------------------+
//| INCLUDES - ORDEM IMPORTANTE                                      |
//+------------------------------------------------------------------+

// 1️⃣ INPUTS CENTRALIZADOS (primeiro!)
#include "Core/Inputs.mqh"

// 1.5️⃣ ESTRATÉGIA BASE (para ter ENUM_SIGNAL_TYPE)
#include "Strategy/Base/StrategyBase.mqh"

// 2️⃣ MÓDULOS CORE
// Logger já incluído via Inputs.mqh
// #include "Core/Logger.mqh"        // ✅ Já incluído
// Blockers já incluído via Inputs.mqh
// #include "Core/Blockers.mqh"      // ✅ Já incluído
// RiskManager já incluído via Inputs.mqh
// #include "Core/RiskManager.mqh"   // ✅ Já incluído
#include "Core/TradeManager.mqh"

// 3️⃣ SIGNAL MANAGER
// SignalManager já incluído via Inputs.mqh
// #include "Strategy/SignalManager.mqh"  // ✅ Já incluído

// 4️⃣ STRATEGIES E FILTERS
// MACrossStrategy já incluído via Inputs.mqh
// #include "Strategy/Strategies/MACrossStrategy.mqh"  // ✅ Já incluído
// RSIStrategy já incluído via Inputs.mqh
// #include "Strategy/Strategies/RSIStrategy.mqh"      // ✅ Já incluído
// RSIFilter já incluído via Inputs.mqh
// #include "Strategy/Filters/RSIFilter.mqh"           // ✅ Já incluído
#include "Strategy/Filters/TrendFilter.mqh"

//+------------------------------------------------------------------+
//| VARIÁVEIS GLOBAIS - INSTÂNCIAS DOS MÓDULOS                       |
//+------------------------------------------------------------------+

// ═══════════════════════════════════════════════════════════════
// MÓDULOS CORE
// ═══════════════════════════════════════════════════════════════
CLogger*        g_logger        = NULL;  // Sistema de logging centralizado
CBlockers*      g_blockers      = NULL;  // Gerenciador de bloqueios
CRiskManager*   g_riskManager   = NULL;  // Gerenciador de risco
CTradeManager*  g_tradeManager  = NULL;  // Gerenciador de posições (v1.01)
CSignalManager* g_signalManager = NULL;  // Orquestrador de sinais

// ═══════════════════════════════════════════════════════════════
// STRATEGIES (ponteiros - serão criadas dinamicamente)
// ═══════════════════════════════════════════════════════════════
CMACrossStrategy* g_maCrossStrategy = NULL;  // Estratégia MA Cross
CRSIStrategy*     g_rsiStrategy     = NULL;  // Estratégia RSI

// ═══════════════════════════════════════════════════════════════
// FILTERS (ponteiros - serão criados dinamicamente)
// ═══════════════════════════════════════════════════════════════
CTrendFilter* g_trendFilter = NULL;  // Filtro de tendência
CRSIFilter*   g_rsiFilter   = NULL;  // Filtro RSI

// ═══════════════════════════════════════════════════════════════
// CONTROLE DE CANDLES (v1.10 - MODIFICADO!)
// ═══════════════════════════════════════════════════════════════
datetime g_lastBarTime = 0;       // Controle de novo candle
datetime g_lastTradeBarTime = 0;  // 🆕 v1.10: Controle de último trade executado
datetime g_lastExitBarTime = 0;   // 🆕 v1.10: Controle de último exit (para FCO)

// ═══════════════════════════════════════════════════════════════
// VARIÁVEIS DE ESTADO
// ═══════════════════════════════════════════════════════════════
bool g_tradingAllowed = true;  // Controle geral de trading

//+------------------------------------------------------------------+
//| FUNÇÃO DE INICIALIZAÇÃO - OnInit()                               |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("════════════════════════════════════════════════════════════════");
   Print("            EPBOT MATRIX v1.12 - INICIALIZANDO...              ");
   Print("════════════════════════════════════════════════════════════════");

// ═══════════════════════════════════════════════════════════════
// ETAPA 1: INICIALIZAR LOGGER (sempre primeiro!)
// ═══════════════════════════════════════════════════════════════
   g_logger = new CLogger();
   if(g_logger == NULL)
     {
      Print("❌ ERRO CRÍTICO: Falha ao criar Logger!");
      return INIT_FAILED;
     }

   if(!g_logger.Init(inp_ShowDebugLogs, _Symbol, inp_MagicNumber, inp_DebugCooldownSec))
     {
      Print("❌ ERRO CRÍTICO: Falha ao inicializar Logger!");
      delete g_logger;
      g_logger = NULL;
      return INIT_FAILED;
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 2: INICIALIZAR BLOCKERS
// ═══════════════════════════════════════════════════════════════
   g_blockers = new CBlockers();
   if(g_blockers == NULL)
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar Blockers!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
     }

   if(!g_blockers.Init(
         g_logger,
         inp_MagicNumber,
         inp_EnableTimeFilter,
         inp_StartHour,
         inp_StartMinute,
         inp_EndHour,
         inp_EndMinute,
         inp_CloseOnEndTime,
         inp_CloseBeforeSessionEnd,
         inp_MinutesBeforeSessionEnd,
         inp_EnableNews1,
         inp_News1StartH,
         inp_News1StartM,
         inp_News1EndH,
         inp_News1EndM,
         inp_EnableNews2,
         inp_News2StartH,
         inp_News2StartM,
         inp_News2EndH,
         inp_News2EndM,
         inp_EnableNews3,
         inp_News3StartH,
         inp_News3StartM,
         inp_News3EndH,
         inp_News3EndM,
         inp_MaxSpread,
         inp_EnableDailyLimits,
         inp_MaxDailyTrades,
         inp_MaxDailyLoss,
         inp_MaxDailyGain,
         inp_ProfitTargetAction,
         inp_EnableStreakControl,
         inp_MaxLossStreak,
         inp_LossStreakAction,
         inp_LossPauseMinutes,
         inp_MaxWinStreak,
         inp_WinStreakAction,
         inp_WinPauseMinutes,
         inp_EnableDrawdown,
         inp_DrawdownType,
         inp_DrawdownValue,
         inp_InitialBalance,
         inp_TradeDirection
      ))
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar Blockers!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 3: INICIALIZAR RISK MANAGER
// ═══════════════════════════════════════════════════════════════
   g_riskManager = new CRiskManager();
   if(g_riskManager == NULL)
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar RiskManager!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
     }

// 🎯 PARTIAL TP - Configurar TP3 como volume restante
   double tp3_percent = 100.0 - inp_PartialTP1_Percent - inp_PartialTP2_Percent;

   if(inp_UsePartialTP)
     {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG", "═══════════════════════════════════════════════════════");
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG", "🎯 PARTIAL TAKE PROFIT - CONFIGURAÇÃO:");
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG",
                   StringFormat("   TP1: %.1f%% @ %d pts", inp_PartialTP1_Percent, inp_PartialTP1_Distance));
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG",
                   StringFormat("   TP2: %.1f%% @ %d pts", inp_PartialTP2_Percent, inp_PartialTP2_Distance));
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG",
                   StringFormat("   TP3: %.1f%% (restante - trailing)", tp3_percent));
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG", "═══════════════════════════════════════════════════════");
     }

   if(!g_riskManager.Init(
         g_logger,
// Lote
         inp_LotSize,
// Stop Loss
         inp_SLType,
         inp_FixedSL,
         inp_SL_ATRMultiplier,
         inp_RangePeriod,
         inp_RangeMultiplier,
         inp_SL_CompensateSpread,
// Take Profit
         inp_TPType,
         inp_FixedTP,
         inp_TP_ATRMultiplier,
         inp_TP_CompensateSpread,
// Trailing
         inp_TrailingType,
         inp_TrailingStart,
         inp_TrailingStep,
         inp_TrailingATRStart,
         inp_TrailingATRStep,
         inp_Trailing_CompensateSpread,
// Breakeven
         inp_BEType,
         inp_BEActivation,
         inp_BEOffset,
         inp_BE_ATRActivation,
         inp_BE_ATROffset,
// 🎯 PARTIAL TP
         inp_UsePartialTP,
         true,
         inp_PartialTP1_Percent,
         TP_FIXED,
         inp_PartialTP1_Distance,
         0,
         true,
         inp_PartialTP2_Percent,
         TP_FIXED,
         inp_PartialTP2_Distance,
         0,
// Ativação Condicional
         inp_TrailingActivation,
         inp_BEActivationMode,
// Global
         _Symbol,
         inp_ATRPeriod
      ))
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar RiskManager!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
     }

   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "RiskManager inicializado com sucesso!");

// ═══════════════════════════════════════════════════════════════
// ETAPA 4: INICIALIZAR TRADE MANAGER
// ═══════════════════════════════════════════════════════════════
   g_tradeManager = new CTradeManager();
   if(g_tradeManager == NULL)
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar TradeManager!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
     }

   if(!g_tradeManager.Init(
         g_logger,
         g_riskManager,
         _Symbol,
         inp_MagicNumber,
         inp_Slippage
      ))
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar TradeManager!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
     }

   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "TradeManager inicializado com sucesso!");

// ═══════════════════════════════════════════════════════════════
// ETAPA 4.5: RESSINCRONIZAR POSIÇÕES EXISTENTES
// ═══════════════════════════════════════════════════════════════
   int syncedPositions = g_tradeManager.ResyncExistingPositions();
   if(syncedPositions > 0)
     {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
                   "🔄 " + IntegerToString(syncedPositions) + " posição(ões) ressincronizada(s)");
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 5: INICIALIZAR SIGNAL MANAGER
// ═══════════════════════════════════════════════════════════════
   g_signalManager = new CSignalManager();
   if(g_signalManager == NULL)
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar SignalManager!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
     }

// Inicializar (passa logger para as strategies/filters)
   if(!g_signalManager.Initialize(g_logger))
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar SignalManager!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
     }

// Configurar modo de conflito
   g_signalManager.SetConflictResolution(inp_ConflictMode);

// ═══════════════════════════════════════════════════════════════
// ETAPA 6: CRIAR E REGISTRAR ESTRATÉGIAS
// ═══════════════════════════════════════════════════════════════

//--- 6.1: MA CROSS STRATEGY
   if(inp_UseMACross)
     {
      g_maCrossStrategy = new CMACrossStrategy();
      if(g_maCrossStrategy == NULL)
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar MACrossStrategy!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      if(!g_maCrossStrategy.Setup(
            g_logger,
            inp_FastPeriod,
            inp_FastMethod,
            inp_FastApplied,
            inp_FastTF,
            inp_SlowPeriod,
            inp_SlowMethod,
            inp_SlowApplied,
            inp_SlowTF,
            inp_EntryMode,
            inp_ExitMode
         ))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao configurar MACrossStrategy!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      // Inicializar a estratégia
      if(!g_maCrossStrategy.Initialize())
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar MACrossStrategy!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      // Definir prioridade ANTES de adicionar
      g_maCrossStrategy.SetPriority(inp_MACrossPriority);

      if(!g_signalManager.AddStrategy(g_maCrossStrategy))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar MACrossStrategy no SignalManager!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
                   "MACrossStrategy criada e registrada - Prioridade: " + IntegerToString(inp_MACrossPriority));
     }
   else
     {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "MACrossStrategy desativada");
     }

//--- 6.2: RSI STRATEGY
   if(inp_UseRSI)
     {
      g_rsiStrategy = new CRSIStrategy();
      if(g_rsiStrategy == NULL)
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar RSIStrategy!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      if(!g_rsiStrategy.Setup(
            g_logger,
            _Symbol,
            inp_RSITF,
            inp_RSIPeriod,
            inp_RSIApplied,
            inp_RSIMode,
            inp_RSIOversold,
            inp_RSIOverbought,
            inp_RSIMidLevel,
            inp_RSISignalShift
         ))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao configurar RSIStrategy!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      // Inicializar a estratégia
      if(!g_rsiStrategy.Initialize())
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar RSIStrategy!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      // Definir prioridade ANTES de adicionar
      g_rsiStrategy.SetPriority(inp_RSIPriority);

      if(!g_signalManager.AddStrategy(g_rsiStrategy))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar RSIStrategy no SignalManager!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
                   "RSIStrategy criada e registrada - Prioridade: " + IntegerToString(inp_RSIPriority));
     }
   else
     {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "RSIStrategy desativada");
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 7: CRIAR E REGISTRAR FILTROS
// ═══════════════════════════════════════════════════════════════

//--- 7.1: TREND FILTER
// ✅ CRIAR se filtro direcional OU zona neutra estiverem ativos
   if(inp_UseTrendFilter || inp_TrendMinDistance > 0)
     {
      g_trendFilter = new CTrendFilter();
      if(g_trendFilter == NULL)
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar TrendFilter!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      if(!g_trendFilter.Setup(
            g_logger,
            inp_UseTrendFilter,      // Filtro direcional
            inp_TrendMAPeriod,       // Período MA
            inp_TrendMAMethod,       // Método MA
            inp_TrendMAApplied,      // Preço aplicado
            inp_TrendMATF,           // Timeframe
            inp_TrendMinDistance     // Zona neutra (0=off)
         ))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao configurar TrendFilter!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      // Inicializar o filtro
      if(!g_trendFilter.Initialize())
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar TrendFilter!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      if(!g_signalManager.AddFilter(g_trendFilter))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar TrendFilter no SignalManager!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "TrendFilter criado e registrado");
     }
   else
     {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "TrendFilter desativado (ambos os modos OFF)");
     }

//--- 7.2: RSI FILTER
   if(inp_UseRSIFilter)
     {
      g_rsiFilter = new CRSIFilter();
      if(g_rsiFilter == NULL)
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar RSIFilter!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      if(!g_rsiFilter.Setup(
            g_logger,
            _Symbol,
            inp_RSIFilterTF,
            inp_RSIFilterPeriod,
            inp_RSIFilterApplied,
            inp_RSIFilterMode,
            inp_RSIFilterOversold,
            inp_RSIFilterOverbought,
            inp_RSIFilterLowerNeutral,
            inp_RSIFilterUpperNeutral,
            inp_RSIFilterShift
         ))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao configurar RSIFilter!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      // Inicializar o filtro
      if(!g_rsiFilter.Initialize())
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar RSIFilter!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      if(!g_signalManager.AddFilter(g_rsiFilter))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar RSIFilter no SignalManager!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
        }

      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "RSIFilter criado e registrado");
     }
   else
     {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "RSIFilter desativado");
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 8: CONFIGURAÇÕES FINAIS
// ═══════════════════════════════════════════════════════════════

// Inicializar controle de candles
   g_lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

// ═══════════════════════════════════════════════════════════════
// SUCESSO!
// ═══════════════════════════════════════════════════════════════
   Print("════════════════════════════════════════════════════════════════");
   Print("          ✅ EPBOT MATRIX INICIALIZADO COM SUCESSO!            ");
   Print("════════════════════════════════════════════════════════════════");

   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "🚀 EPBot Matrix v1.12 - PRONTO PARA OPERAR!");
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📊 Símbolo: " + _Symbol);
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "⏰ Timeframe: " + EnumToString(PERIOD_CURRENT));
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "🎯 Magic Number: " + IntegerToString(inp_MagicNumber));

   if(inp_UsePartialTP)
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "🎯 Partial TP: ATIVADO");

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| FUNÇÃO DE DESINICIALIZAÇÃO - OnDeinit()                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT", "════════════════════════════════════════════════════════════════");
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT", "            EPBOT MATRIX - FINALIZANDO...                      ");
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT", "════════════════════════════════════════════════════════════════");
   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT",
                "Motivo: " + IntegerToString(reason) + " - " + GetDeinitReasonText(reason));

// Salvar relatório diário antes de finalizar
   if(g_logger != NULL && g_logger.GetDailyTrades() > 0)
     {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT", "📄 Gerando relatório final...");
      g_logger.SaveDailyReport();
     }

// ═══════════════════════════════════════════════════════════════
// LIMPEZA SEGURA - Ordem inversa da inicialização
// ═══════════════════════════════════════════════════════════════

// ETAPA 1: Desinicializar SignalManager ANTES de deletar strategies/filters
//          (enquanto os ponteiros ainda são válidos)
   if(g_signalManager != NULL)
     {
      g_signalManager.Deinitialize();

      // CRÍTICO: Limpar referências para evitar acesso a ponteiros inválidos no destrutor
      g_signalManager.Clear();
     }

// ETAPA 2: Deletar filtros e estratégias
//          (agora é seguro porque ponteiros foram zerados)
   if(g_rsiFilter != NULL)
     {
      delete g_rsiFilter;
      g_rsiFilter = NULL;
     }
   if(g_trendFilter != NULL)
     {
      delete g_trendFilter;
      g_trendFilter = NULL;
     }
   if(g_rsiStrategy != NULL)
     {
      delete g_rsiStrategy;
      g_rsiStrategy = NULL;
     }
   if(g_maCrossStrategy != NULL)
     {
      delete g_maCrossStrategy;
      g_maCrossStrategy = NULL;
     }

// ETAPA 3: Deletar SignalManager
//          (destrutor vai chamar Deinitialize() mas ponteiros estão NULL - seguro!)
   if(g_signalManager != NULL)
     {
      delete g_signalManager;
      g_signalManager = NULL;
     }

// ETAPA 4: Deletar módulos base
   if(g_riskManager != NULL)
     {
      delete g_riskManager;
      g_riskManager = NULL;
     }
   if(g_tradeManager != NULL)
     {
      delete g_tradeManager;
      g_tradeManager = NULL;
     }
   if(g_blockers != NULL)
     {
      delete g_blockers;
      g_blockers = NULL;
     }
   if(g_logger != NULL)
     {
      delete g_logger;
      g_logger = NULL;
     }

   Print("════════════════════════════════════════════════════════════════");
   Print("           ✅ EPBOT MATRIX FINALIZADO COM SUCESSO!              ");
   Print("════════════════════════════════════════════════════════════════");
  }

//+------------------------------------------------------------------+
//| FUNÇÃO PRINCIPAL - OnTick() - VERSÃO CORRIGIDA DEFINITIVA        |
//+------------------------------------------------------------------+
void OnTick()
  {
// ═══════════════════════════════════════════════════════════════
// ETAPA 1: VERIFICAR NOVO CANDLE (se necessário)
// ═══════════════════════════════════════════════════════════════
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   bool isNewBar = (currentBarTime != g_lastBarTime);

   if(isNewBar)
     {
      g_lastBarTime = currentBarTime;
      g_logger.Log(LOG_DEBUG, THROTTLE_CANDLE, "TICK",
                   "🕐 Novo candle detectado: " + TimeToString(currentBarTime));
     }

// Detectar mudança de dia (para reset diário e relatório)
   static int lastDay = 0;
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);

   if(lastDay != 0 && timeStruct.day != lastDay)
     {
      // Novo dia detectado - gerar relatório do dia anterior
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY", "═══════════════════════════════════════════════════════════════");
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY",
                   "📅 NOVO DIA DETECTADO - " + TimeToString(TimeCurrent(), TIME_DATE));
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY", "═══════════════════════════════════════════════════════════════");

      // Gerar relatório final do dia anterior (se houve trades)
      if(g_logger.GetDailyTrades() > 0)
        {
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY", "📄 Gerando relatório do dia anterior...");
         g_logger.SaveDailyReport();

         g_logger.ResetDaily();
         g_blockers.ResetDaily();

         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY", "✅ Relatório salvo - Iniciando novo dia de trading");
        }
      else
        {
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY", "ℹ️ Dia anterior sem trades - Iniciando novo dia");
        }

      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAY", "═══════════════════════════════════════════════════════════════");
     }

   lastDay = timeStruct.day;

// ═══════════════════════════════════════════════════════════════
// ETAPA 1.5: DETECTAR FECHAMENTO DE POSIÇÃO (histórico)
// ═══════════════════════════════════════════════════════════════

   static ulong lastPositionTicket = 0;

// ═══════════════════════════════════════════════════════════════
// BUSCAR POSIÇÃO DESTE EA (funciona em HEDGING e NETTING)
// ═══════════════════════════════════════════════════════════════
   bool hasMyPosition = false;
   ulong myPositionTicket = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != _Symbol)
         continue;

      if(PositionGetInteger(POSITION_MAGIC) == inp_MagicNumber)
        {
         hasMyPosition = true;
         myPositionTicket = PositionGetTicket(i);
         break;
        }
     }

// Se tinha posição e agora não tem mais = fechou!
   if(lastPositionTicket > 0 && !hasMyPosition)
     {
      // Buscar informação do fechamento no histórico
      if(HistorySelectByPosition(lastPositionTicket))
        {
         // Calcular profit da posição fechada
         double positionProfit = 0;

         for(int i = 0; i < HistoryDealsTotal(); i++)
           {
            ulong dealTicket = HistoryDealGetTicket(i);
            if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == lastPositionTicket)
              {
               long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
               if(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY)
                 {
                  positionProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);

                  // Salvar trade no Logger
                  g_logger.SaveTrade(lastPositionTicket, positionProfit);

                  // Atualizar estatísticas
                  g_logger.UpdateStats(positionProfit);

                  // Registrar no Blockers
                  bool isWin = (positionProfit > 0);
                  g_blockers.UpdateAfterTrade(isWin, positionProfit);

                  g_logger.Log(LOG_TRADE, THROTTLE_NONE, "CLOSE",
                               "📊 Posição #" + IntegerToString(lastPositionTicket) +
                               " fechada | P/L: $" + DoubleToString(positionProfit, 2));

                  // Gerar relatório TXT atualizado após cada trade
                  g_logger.SaveDailyReport();
                  g_logger.Log(LOG_TRADE, THROTTLE_NONE, "REPORT", "📄 Relatório diário atualizado");

                  break;
                 }
              }
           }
        }

      // Remover do TradeManager
      g_tradeManager.UnregisterPosition(lastPositionTicket);

      // Resetar controle de candle ao fechar posição (exceto no modo VM)
      if(inp_ExitMode != EXIT_VM)
        {
         g_lastTradeBarTime = 0;
         g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "RESET", "🔄 Controle de candle resetado - pronto para novo trade");
        }

      lastPositionTicket = 0;
     }

// ═══════════════════════════════════════════════════════════════
// SE EXISTE POSIÇÃO DESTE EA: GERENCIAR
// ═══════════════════════════════════════════════════════════════
   if(hasMyPosition)
     {
      // Atualizar ticket da posição atual
      lastPositionTicket = myPositionTicket;

      // Selecionar a posição específica
      if(!PositionSelectByTicket(myPositionTicket))
         return;

      ulong  ticket = PositionGetInteger(POSITION_TICKET);
      double volume = PositionGetDouble(POSITION_VOLUME);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      // Preço de fechamento
      double closePrice = (posType == POSITION_TYPE_BUY)
                          ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                          : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      // ═══════════════════════════════════════════════════════════════
      // VERIFICAR FECHAMENTO POR HORÁRIO (DUAS CAMADAS)
      // ═══════════════════════════════════════════════════════════════
      bool   shouldCloseByOperation = false;
      bool   shouldCloseBySession   = false;
      string closeTrigger           = "";

      // Camada 1: Horário de Operação
      if(g_blockers != NULL && g_blockers.ShouldCloseOnEndTime(ticket))
        {
         shouldCloseByOperation = true;
         closeTrigger = "Operation";
        }

      // Camada 2: Proteção de Sessão
      if(!shouldCloseByOperation && g_blockers != NULL && g_blockers.ShouldCloseBeforeSessionEnd(ticket))
        {
         shouldCloseBySession = true;
         closeTrigger = "Session";
        }

      // Se QUALQUER camada pedir fechamento, executa
      if(shouldCloseByOperation || shouldCloseBySession)
        {
         if(closePrice <= 0)
           {
            g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TIME_CLOSE",
                         "[Core] Preço inválido - Continuando gerenciamento normal");
            ManageOpenPosition(ticket);
            return;
           }

         // Monta request de fechamento
         MqlTradeRequest request = {};
         MqlTradeResult  result  = {};

         request.action       = TRADE_ACTION_DEAL;
         request.position     = ticket;
         request.symbol       = _Symbol;
         request.volume       = volume;
         request.price        = closePrice;
         request.deviation    = inp_Slippage;
         request.type         = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
         request.type_filling = GetTypeFilling(_Symbol);
         request.magic        = inp_MagicNumber;
         request.comment      = "Close[" + closeTrigger + "]";

         g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TIME_CLOSE", "════════════════════════════════════════════════════════════════");
         g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TIME_CLOSE", "🔒 [Core] Fechando posição por: " + closeTrigger);
         g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TIME_CLOSE", "   Ticket: " + IntegerToString((int)ticket));
         g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TIME_CLOSE", "   Volume: " + DoubleToString(volume, 2));
         g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TIME_CLOSE", "   Preço: " + DoubleToString(closePrice, _Digits));

         if(!OrderSend(request, result))
           {
            g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TIME_CLOSE",
                         "[Core] OrderSend falhou - Erro: " + IntegerToString(GetLastError()));
            ManageOpenPosition(ticket);
            return;
           }

         // Tratar resultado
         if(result.retcode == TRADE_RETCODE_DONE)
           {
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TIME_CLOSE", "[Core] Posição fechada com sucesso");
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TIME_CLOSE", "   Deal: #" + IntegerToString((int)result.deal));
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TIME_CLOSE", "   Preço: " + DoubleToString(result.price, _Digits));
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TIME_CLOSE", "   Trigger: " + closeTrigger);
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TIME_CLOSE", "════════════════════════════════════════════════════════════════");
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

      // Se não fechou por horário, gerenciamento normal
      ManageOpenPosition(ticket);
      return;  // ✅ SEMPRE SAI APÓS GERENCIAR
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 2: VERIFICAR BLOCKERS (só se NÃO tem posição!)
// ═══════════════════════════════════════════════════════════════

   int dailyTrades = g_logger.GetDailyTrades();
   double dailyProfit = g_logger.GetDailyProfit();
   string blockReason = "";

   if(!g_blockers.CanTrade(dailyTrades, dailyProfit, blockReason))
     {
      g_logger.Log(LOG_DEBUG, THROTTLE_TIME, "BLOCKER", "🚫 Trading bloqueado: " + blockReason, 60);
      return;
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 3.5: VERIFICAR SE JÁ OPEROU NESTE CANDLE
// ═══════════════════════════════════════════════════════════════

   bool isVMActive = (inp_UseMACross && inp_ExitMode == EXIT_VM);

   if(!isVMActive)
     {
      datetime currentBarTime_Check = iTime(_Symbol, PERIOD_CURRENT, 0);

      if(currentBarTime_Check == g_lastTradeBarTime)
        {
         g_logger.Log(LOG_DEBUG, THROTTLE_CANDLE, "BLOCKER", "⏸️ Já operou neste candle - aguardando próximo");
         return;
        }
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 4: BUSCAR SINAL (só se não tem posição)
// ═══════════════════════════════════════════════════════════════
   ENUM_SIGNAL_TYPE signal = g_signalManager.GetSignal();

   if(signal == SIGNAL_NONE)
     {
      g_logger.Log(LOG_DEBUG, THROTTLE_CANDLE, "SIGNAL", "ℹ️ Nenhum sinal válido detectado");
      return;
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 4.5: BLOQUEIO FCO - Não entrar no candle do exit
// ═══════════════════════════════════════════════════════════════

   if(inp_ExitMode == EXIT_FCO)
     {
      datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

      if(currentBarTime == g_lastExitBarTime)
        {
         g_logger.Log(LOG_DEBUG, THROTTLE_CANDLE, "FCO", "🚫 FCO bloqueado - não entra no sinal que causou exit");
         return;
        }
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 5: EXECUTAR TRADE
// ═══════════════════════════════════════════════════════════════
   ExecuteTrade(signal);
  }

//+------------------------------------------------------------------+
//| GERENCIAR POSIÇÃO ABERTA - Recebe ticket específico               |
//+------------------------------------------------------------------+
void ManageOpenPosition(ulong ticket)
  {
   if(!PositionSelectByTicket(ticket))
      return;

   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double currentPrice = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);

// ═══════════════════════════════════════════════════════════════
// VERIFICAR SE POSIÇÃO ESTÁ REGISTRADA NO TRADEMANAGER
// ═══════════════════════════════════════════════════════════════
   int index = g_tradeManager.GetPositionIndex(ticket);
   if(index < 0)
     {
      g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "POSITION",
                   "⚠️ Posição não encontrada no TradeManager - Ignorando gerenciamento");
      return;
     }

// ═══════════════════════════════════════════════════════════════
// MONITORAR PARTIAL TP (se habilitado)
// ═══════════════════════════════════════════════════════════════
   if(inp_UsePartialTP)
     {
      g_tradeManager.MonitorPartialTP(ticket);
     }

// ═══════════════════════════════════════════════════════════════
// ATIVAR TRAILING/BREAKEVEN SE NECESSÁRIO
// ═══════════════════════════════════════════════════════════════
   bool tp1Executed = g_tradeManager.IsTP1Executed(ticket);
   bool tp2Executed = g_tradeManager.IsTP2Executed(ticket);

// ═══════════════════════════════════════════════════════════════
// TRAILING STOP
// ═══════════════════════════════════════════════════════════════
   if(g_riskManager.ShouldActivateTrailing(tp1Executed, tp2Executed))
     {
      STrailingResult trailing = g_riskManager.CalculateTrailing(posType, currentPrice, entryPrice, currentSL);

      if(trailing.should_move)
        {
         MqlTradeRequest request = {};
         MqlTradeResult result = {};

         request.action = TRADE_ACTION_SLTP;
         request.position = ticket;
         request.symbol = _Symbol;
         request.sl = trailing.new_sl_price;
         request.tp = PositionGetDouble(POSITION_TP);

         if(OrderSend(request, result))
           {
            g_logger.Log(LOG_TRADE, THROTTLE_TIME, "TRAILING",
                         "✅ Trailing Stop movido para " + DoubleToString(trailing.new_sl_price, _Digits), 5);
           }
        }
     }

// ═══════════════════════════════════════════════════════════════
// BREAKEVEN
// ═══════════════════════════════════════════════════════════════
   if(g_riskManager.ShouldActivateBreakeven(tp1Executed, tp2Executed))
     {
      bool beActivated = g_tradeManager.IsBreakevenActivated(ticket);

      SBreakevenResult breakeven = g_riskManager.CalculateBreakeven(posType, currentPrice, entryPrice, currentSL, beActivated);

      if(breakeven.should_activate)
        {
         MqlTradeRequest request = {};
         MqlTradeResult result = {};

         request.action = TRADE_ACTION_SLTP;
         request.position = ticket;
         request.symbol = _Symbol;
         request.sl = breakeven.new_sl_price;
         request.tp = PositionGetDouble(POSITION_TP);

         if(OrderSend(request, result))
           {
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "BREAKEVEN",
                         "✅ Breakeven ativado em " + DoubleToString(breakeven.new_sl_price, _Digits));
            g_tradeManager.SetBreakevenActivated(ticket, true);
           }
        }
     }

// ═══════════════════════════════════════════════════════════════
// VERIFICAR EXIT SIGNAL DAS STRATEGIES
// ═══════════════════════════════════════════════════════════════
   ENUM_SIGNAL_TYPE exitSignal = g_signalManager.GetExitSignal(posType);

   if(exitSignal != SIGNAL_NONE)
     {
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "EXIT", "🔄 Exit signal detectado - fechando posição");

      MqlTradeRequest request = {};
      MqlTradeResult result = {};

      request.action = TRADE_ACTION_DEAL;
      request.position = ticket;
      request.symbol = _Symbol;
      request.volume = PositionGetDouble(POSITION_VOLUME);
      request.type = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      request.price = currentPrice;
      request.deviation = inp_Slippage;
      request.magic = inp_MagicNumber;
      request.comment = "Exit: " + g_signalManager.GetLastSignalSource();
      request.type_filling = GetTypeFilling(_Symbol);

      if(OrderSend(request, result))
        {
         if(result.retcode == TRADE_RETCODE_DONE)
           {
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "EXIT", "✅ Posição fechada por exit signal");
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "EXIT", "   Fonte: " + g_signalManager.GetLastSignalSource());
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "EXIT", "   Preço: " + DoubleToString(result.price, _Digits));

            if(inp_ExitMode == EXIT_VM)
              {
               g_logger.Log(LOG_TRADE, THROTTLE_NONE, "VM", "🔄 VIRAR A MÃO - Executando entrada oposta IMEDIATAMENTE");
               ExecuteTrade(exitSignal);
              }
            else  // EXIT_FCO
              {
               g_lastExitBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
               g_logger.Log(LOG_TRADE, THROTTLE_NONE, "FCO", "⏸️ EXIT_FCO - Posição fechada, bloqueando re-entrada neste sinal");
              }
           }
         else
           {
            g_logger.Log(LOG_ERROR, THROTTLE_NONE, "EXIT", "⚠️ Retcode: " + IntegerToString(result.retcode));
           }
        }
      else
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "EXIT", "❌ Falha ao fechar posição - Código: " + IntegerToString(result.retcode));
        }
     }
  }

//+------------------------------------------------------------------+
//| EXECUTAR TRADE                                                   |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_SIGNAL_TYPE signal)
  {
   g_logger.Log(LOG_SIGNAL, THROTTLE_NONE, "SIGNAL", "════════════════════════════════════════════════════════════════");
   g_logger.Log(LOG_SIGNAL, THROTTLE_NONE, "SIGNAL", "🎯 SINAL DETECTADO: " + EnumToString(signal));

// ═══════════════════════════════════════════════════════════════
// DETERMINAR TIPO DE ORDEM
// ═══════════════════════════════════════════════════════════════
   ENUM_ORDER_TYPE orderType;

   if(signal == SIGNAL_BUY)
      orderType = ORDER_TYPE_BUY;
   else
      if(signal == SIGNAL_SELL)
         orderType = ORDER_TYPE_SELL;
      else
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "SIGNAL", "⚠️ Sinal inválido ignorado: " + EnumToString(signal));
         return;
        }

// ═══════════════════════════════════════════════════════════════
// CALCULAR PARÂMETROS DE RISCO
// ═══════════════════════════════════════════════════════════════

   double price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

// Lote
   double lotSize = g_riskManager.GetLotSize();
   if(lotSize <= 0)
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRADE",
                   "❌ Falha ao calcular lote - Valor inválido: " + DoubleToString(lotSize, 2));
      return;
     }

// Stop Loss
   double slPrice = g_riskManager.CalculateSLPrice(orderType, price);
   if(slPrice <= 0)
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRADE", "❌ Falha ao calcular SL - Valor inválido");
      return;
     }

// Take Profit (RiskManager decide se usa TP Fixo ou 0)
   double tpPrice = g_riskManager.CalculateTPPrice(orderType, price);

// ═══════════════════════════════════════════════════════════════
// VALIDAR SL/TP CONTRA NÍVEIS MÍNIMOS DO BROKER
// ═══════════════════════════════════════════════════════════════
   SValidateSLTPResult validation = g_riskManager.ValidateSLTP(
                                       (orderType == ORDER_TYPE_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL,
                                       price,
                                       slPrice,
                                       tpPrice
                                    );

// Usar valores validados
   slPrice = validation.validated_sl;
   tpPrice = validation.validated_tp;

   if(validation.sl_adjusted || validation.tp_adjusted)
     {
      g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "VALIDATION", "⚠️ " + validation.message);
     }

// ═══════════════════════════════════════════════════════════════
// ENVIAR ORDEM
// ═══════════════════════════════════════════════════════════════

   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = orderType;
   request.price = price;
   request.sl = slPrice;
   request.tp = tpPrice;  // 0 se usar Partial TP
   request.deviation = inp_Slippage;
   request.magic = inp_MagicNumber;
   request.comment = inp_TradeComment;
   request.type_filling = GetTypeFilling(_Symbol);

// Log dos parâmetros
   g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "📊 Parâmetros da Ordem:");
   g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   Tipo: " + EnumToString(orderType));
   g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   Lote: " + DoubleToString(lotSize, 2));
   g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   Preço: " + DoubleToString(price, _Digits));
   g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   SL: " + DoubleToString(slPrice, _Digits));
   g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   TP: " + (tpPrice > 0 ? DoubleToString(tpPrice, _Digits) : "Partial TP"));

// Enviar ordem
   if(!OrderSend(request, result))
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRADE", "❌ Falha ao enviar ordem - Código: " + IntegerToString(result.retcode));
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRADE", "   Descrição: " + result.comment);
      return;
     }

// Verificar resultado
   if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
     {
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "✅ ORDEM EXECUTADA COM SUCESSO!");
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   Ticket: " + IntegerToString(result.order));
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   Deal: " + IntegerToString(result.deal));
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   Volume: " + DoubleToString(result.volume, 2));
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   Preço: " + DoubleToString(result.price, _Digits));

      // 🆕 REGISTRAR CANDLE DO TRADE
      g_lastTradeBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE",
                   "📊 Trade executado no candle: " + TimeToString(g_lastTradeBarTime));

      // ═══════════════════════════════════════════════════════════════
      // REGISTRAR POSIÇÃO NO TRADEMANAGER
      // ═══════════════════════════════════════════════════════════════
      SPartialTPLevel tpLevels[];
      bool hasPartialTP = inp_UsePartialTP;

      // 🎯 CALCULAR NÍVEIS DE PARTIAL TP
      if(hasPartialTP)
        {
         hasPartialTP = g_riskManager.CalculatePartialTPLevels(
                           orderType,
                           result.price,
                           result.volume,
                           tpLevels
                        );

         if(hasPartialTP)
           {
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "PARTIAL_TP", "🎯 Partial TP configurado:");
            for(int i = 0; i < ArraySize(tpLevels); i++)
              {
               if(tpLevels[i].enabled)
                 {
                  g_logger.Log(LOG_TRADE, THROTTLE_NONE, "PARTIAL_TP", "   " + tpLevels[i].description);
                 }
              }
           }
        }

      // ✅ USAR ORDER TICKET (que vira POSITION ticket em ordens market)
      ulong positionTicket = result.order;

      // Verificar se a posição realmente existe
      if(!PositionSelectByTicket(positionTicket))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRADE",
                      "❌ Posição não encontrada após abertura! Order: " + IntegerToString(result.order));
         return;
        }

      g_tradeManager.RegisterPosition(
         positionTicket,  // ✅ CORRETO: result.order
         (orderType == ORDER_TYPE_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL,
         result.price,
         result.volume,
         hasPartialTP,
         tpLevels
      );
     }
   else
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRADE",
                   "⚠️ Ordem parcialmente executada - Retcode: " + IntegerToString(result.retcode));
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRADE", "   Descrição: " + result.comment);
     }

   g_logger.Log(LOG_SIGNAL, THROTTLE_NONE, "SIGNAL", "════════════════════════════════════════════════════════════════");
  }

//+------------------------------------------------------------------+
//| CLEANUP E RETORNO                                                |
//+------------------------------------------------------------------+
void CleanupAndReturn(int returnCode)
  {
// Liberar filtros
   if(g_rsiFilter != NULL)
     {
      delete g_rsiFilter;
      g_rsiFilter = NULL;
     }

   if(g_trendFilter != NULL)
     {
      delete g_trendFilter;
      g_trendFilter = NULL;
     }

// Liberar estratégias
   if(g_rsiStrategy != NULL)
     {
      delete g_rsiStrategy;
      g_rsiStrategy = NULL;
     }

   if(g_maCrossStrategy != NULL)
     {
      delete g_maCrossStrategy;
      g_maCrossStrategy = NULL;
     }

// SignalManager
   if(g_signalManager != NULL)
     {
      delete g_signalManager;
      g_signalManager = NULL;
     }

// RiskManager
   if(g_riskManager != NULL)
     {
      delete g_riskManager;
      g_riskManager = NULL;
     }

// TradeManager
   if(g_tradeManager != NULL)
     {
      delete g_tradeManager;
      g_tradeManager = NULL;
     }

// Blockers
   if(g_blockers != NULL)
     {
      delete g_blockers;
      g_blockers = NULL;
     }

// Logger (último sempre!)
   if(g_logger != NULL)
     {
      delete g_logger;
      g_logger = NULL;
     }
  }

//+------------------------------------------------------------------+
//| OBTER TIPO DE PREENCHIMENTO                                      |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetTypeFilling(string symbol)
  {
   uint filling = (uint)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);

   if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   else
      if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
         return ORDER_FILLING_IOC;
      else
         return ORDER_FILLING_RETURN;
  }

//+------------------------------------------------------------------+
//| OBTER TEXTO DO MOTIVO DE DEINIT                                  |
//+------------------------------------------------------------------+
string GetDeinitReasonText(int reason)
  {
   switch(reason)
     {
      case REASON_PROGRAM:
         return "Expert removido do gráfico";
      case REASON_REMOVE:
         return "Programa deletado";
      case REASON_RECOMPILE:
         return "Programa recompilado";
      case REASON_CHARTCHANGE:
         return "Símbolo ou timeframe alterado";
      case REASON_CHARTCLOSE:
         return "Gráfico fechado";
      case REASON_PARAMETERS:
         return "Parâmetros de entrada alterados";
      case REASON_ACCOUNT:
         return "Conta alterada";
      case REASON_TEMPLATE:
         return "Template aplicado";
      case REASON_INITFAILED:
         return "Falha na inicialização";
      case REASON_CLOSE:
         return "Terminal fechado";
      default:
         return "Motivo desconhecido";
     }
  }

//+------------------------------------------------------------------+
//| FIM DO EA - EPBOT MATRIX v1.12                                   |
//+------------------------------------------------------------------+
