//+------------------------------------------------------------------+
//|                                                 EPBot_Matrix.mq5 |
//|                                         Copyright 2025, EP Filho |
//|                        EA Modular Multistrategy - EPBot Matrix   |
//|                                                      Versão 1.00 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EP Filho"
#property link      "https://github.com/EPFILHO"
#property version   "1.00"
#property description "EPBot Matrix - Sistema de Trading Modular Multistrategy"
#property description "Arquitetura profissional com hot reload e logging avançado"

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
// CONTROLE DE CANDLES
// ═══════════════════════════════════════════════════════════════
datetime g_lastBarTime = 0;  // Controle de novo candle

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
   Print("            EPBOT MATRIX v1.00 - INICIALIZANDO...              ");
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
   
   if(!g_logger.Init(inp_LoggerMode, _Symbol, inp_MagicNumber))
   {
      Print("❌ ERRO CRÍTICO: Falha ao inicializar Logger!");
      delete g_logger;
      g_logger = NULL;
      return INIT_FAILED;
   }
   
   g_logger.LogInfo("✅ Logger inicializado com sucesso - Modo: " + EnumToString(inp_LoggerMode));
   
   // ═══════════════════════════════════════════════════════════════
   // ETAPA 2: INICIALIZAR BLOCKERS
   // ═══════════════════════════════════════════════════════════════
   g_blockers = new CBlockers();
   if(g_blockers == NULL)
   {
      g_logger.LogError("❌ Falha ao criar Blockers!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
   }
   
   if(!g_blockers.Init(
      g_logger,
      inp_EnableTimeFilter,
      inp_StartHour,
      inp_StartMinute,
      inp_EndHour,
      inp_EndMinute,
      inp_CloseOnEndTime,
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
      g_logger.LogError("❌ Falha ao inicializar Blockers!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
   }
   
   g_logger.LogInfo("✅ Blockers inicializado com sucesso");
   
   // ═══════════════════════════════════════════════════════════════
   // ETAPA 3: INICIALIZAR RISK MANAGER
   // ═══════════════════════════════════════════════════════════════
   g_riskManager = new CRiskManager();
   if(g_riskManager == NULL)
   {
      g_logger.LogError("❌ Falha ao criar RiskManager!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
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
      inp_UseTrailing,
      inp_TrailingType,
      inp_TrailingStart,
      inp_TrailingStep,
      inp_TrailingATRStart,
      inp_TrailingATRStep,
      inp_Trailing_CompensateSpread,
      // Breakeven
      inp_UseBreakeven,
      inp_BEType,
      inp_BEActivation,
      inp_BEOffset,
      inp_BE_ATRActivation,
      inp_BE_ATROffset,
      // Partial TP (desativado por enquanto)
      false,  // usePartialTP
      false,  // tp1Enable
      0,      // tp1Percent
      TP_NONE, // tp1Type
      0,      // tp1Distance
      0,      // tp1ATRMult
      false,  // tp2Enable
      0,      // tp2Percent
      TP_NONE, // tp2Type
      0,      // tp2Distance
      0,      // tp2ATRMult
      // Ativação Condicional (padrão ALWAYS)
      TRAILING_ALWAYS,
      BE_ALWAYS,
      // Global
      _Symbol,
      inp_ATRPeriod
   ))
   {
      g_logger.LogError("❌ Falha ao inicializar RiskManager!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
   }
   
   g_logger.LogInfo("✅ RiskManager inicializado com sucesso");
   
   // ═══════════════════════════════════════════════════════════════
   // ETAPA 4: INICIALIZAR SIGNAL MANAGER
   // ═══════════════════════════════════════════════════════════════
   g_signalManager = new CSignalManager();
   if(g_signalManager == NULL)
   {
      g_logger.LogError("❌ Falha ao criar SignalManager!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
   }
   
   // Inicializar (passa logger para as strategies/filters)
   if(!g_signalManager.Initialize(g_logger))
   {
      g_logger.LogError("❌ Falha ao inicializar SignalManager!");
      CleanupAndReturn(INIT_FAILED);
      return INIT_FAILED;
   }
   
   // Configurar modo de conflito
   g_signalManager.SetConflictResolution(inp_ConflictMode);
   
   g_logger.LogInfo("✅ SignalManager inicializado com sucesso - Modo: " + EnumToString(inp_ConflictMode));
   
   // ═══════════════════════════════════════════════════════════════
   // ETAPA 5: CRIAR E REGISTRAR ESTRATÉGIAS
   // ═══════════════════════════════════════════════════════════════
   
   //--- 5.1: MA CROSS STRATEGY
   if(inp_UseMACross)
   {
      g_maCrossStrategy = new CMACrossStrategy();
      if(g_maCrossStrategy == NULL)
      {
         g_logger.LogError("❌ Falha ao criar MACrossStrategy!");
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
         g_logger.LogError("❌ Falha ao configurar MACrossStrategy!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      // Inicializar a estratégia
      if(!g_maCrossStrategy.Initialize())
      {
         g_logger.LogError("❌ Falha ao inicializar MACrossStrategy!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      // Definir prioridade ANTES de adicionar
      g_maCrossStrategy.SetPriority(inp_MACrossPriority);
      
      if(!g_signalManager.AddStrategy(g_maCrossStrategy))
      {
         g_logger.LogError("❌ Falha ao registrar MACrossStrategy no SignalManager!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      g_logger.LogInfo("✅ MACrossStrategy criada e registrada - Prioridade: " + IntegerToString(inp_MACrossPriority));
   }
   else
   {
      g_logger.LogInfo("ℹ️ MACrossStrategy desativada");
   }
   
   //--- 5.2: RSI STRATEGY
   if(inp_UseRSI)
   {
      g_rsiStrategy = new CRSIStrategy();
      if(g_rsiStrategy == NULL)
      {
         g_logger.LogError("❌ Falha ao criar RSIStrategy!");
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
         g_logger.LogError("❌ Falha ao configurar RSIStrategy!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      // Inicializar a estratégia
      if(!g_rsiStrategy.Initialize())
      {
         g_logger.LogError("❌ Falha ao inicializar RSIStrategy!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      // Definir prioridade ANTES de adicionar
      g_rsiStrategy.SetPriority(inp_RSIPriority);
      
      if(!g_signalManager.AddStrategy(g_rsiStrategy))
      {
         g_logger.LogError("❌ Falha ao registrar RSIStrategy no SignalManager!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      g_logger.LogInfo("✅ RSIStrategy criada e registrada - Prioridade: " + IntegerToString(inp_RSIPriority));
   }
   else
   {
      g_logger.LogInfo("ℹ️ RSIStrategy desativada");
   }
   
   // ═══════════════════════════════════════════════════════════════
   // ETAPA 6: CRIAR E REGISTRAR FILTROS
   // ═══════════════════════════════════════════════════════════════
   
   //--- 6.1: TREND FILTER
   if(inp_UseTrendFilter)
   {
      g_trendFilter = new CTrendFilter();
      if(g_trendFilter == NULL)
      {
         g_logger.LogError("❌ Falha ao criar TrendFilter!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      if(!g_trendFilter.Setup(
         g_logger,
         inp_UseTrendFilter,
         inp_TrendMAPeriod,
         inp_TrendMAMethod,
         inp_TrendMAApplied,
         inp_TrendMATF,
         false,  // useNeutralZone (não temos input para isso ainda)
         0,      // neutralPeriod
         MODE_SMA, // neutralMethod
         PRICE_CLOSE, // neutralApplied
         PERIOD_CURRENT, // neutralTimeframe
         inp_TrendMinDistance
      ))
      {
         g_logger.LogError("❌ Falha ao configurar TrendFilter!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      // Inicializar o filtro
      if(!g_trendFilter.Initialize())
      {
         g_logger.LogError("❌ Falha ao inicializar TrendFilter!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      if(!g_signalManager.AddFilter(g_trendFilter))
      {
         g_logger.LogError("❌ Falha ao registrar TrendFilter no SignalManager!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      g_logger.LogInfo("✅ TrendFilter criado e registrado");
   }
   else
   {
      g_logger.LogInfo("ℹ️ TrendFilter desativado");
   }
   
   //--- 6.2: RSI FILTER
   if(inp_UseRSIFilter)
   {
      g_rsiFilter = new CRSIFilter();
      if(g_rsiFilter == NULL)
      {
         g_logger.LogError("❌ Falha ao criar RSIFilter!");
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
         g_logger.LogError("❌ Falha ao configurar RSIFilter!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      // Inicializar o filtro
      if(!g_rsiFilter.Initialize())
      {
         g_logger.LogError("❌ Falha ao inicializar RSIFilter!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      if(!g_signalManager.AddFilter(g_rsiFilter))
      {
         g_logger.LogError("❌ Falha ao registrar RSIFilter no SignalManager!");
         CleanupAndReturn(INIT_FAILED);
         return INIT_FAILED;
      }
      
      g_logger.LogInfo("✅ RSIFilter criado e registrado");
   }
   else
   {
      g_logger.LogInfo("ℹ️ RSIFilter desativado");
   }
   
   // ═══════════════════════════════════════════════════════════════
   // ETAPA 7: CONFIGURAÇÕES FINAIS
   // ═══════════════════════════════════════════════════════════════
   
   // Inicializar controle de candles
   g_lastBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   // ═══════════════════════════════════════════════════════════════
   // SUCESSO!
   // ═══════════════════════════════════════════════════════════════
   Print("════════════════════════════════════════════════════════════════");
   Print("          ✅ EPBOT MATRIX INICIALIZADO COM SUCESSO!            ");
   Print("════════════════════════════════════════════════════════════════");
   g_logger.LogInfo("🚀 EPBot Matrix v1.00 - PRONTO PARA OPERAR!");
   g_logger.LogInfo("📊 Símbolo: " + _Symbol);
   g_logger.LogInfo("⏰ Timeframe: " + EnumToString(PERIOD_CURRENT));
   g_logger.LogInfo("🎯 Magic Number: " + IntegerToString(inp_MagicNumber));
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| FUNÇÃO DE DESINICIALIZAÇÃO - OnDeinit()                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   g_logger.LogInfo("════════════════════════════════════════════════════════════════");
   g_logger.LogInfo("            EPBOT MATRIX - FINALIZANDO...                      ");
   g_logger.LogInfo("════════════════════════════════════════════════════════════════");
   g_logger.LogInfo("Motivo: " + IntegerToString(reason) + " - " + GetDeinitReasonText(reason));
   
   // Salvar relatório diário antes de finalizar
   if(g_logger != NULL && g_logger.GetDailyTrades() > 0)
   {
      g_logger.LogInfo("📄 Gerando relatório final...");
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
   if(g_rsiFilter != NULL) { delete g_rsiFilter; g_rsiFilter = NULL; }
   if(g_trendFilter != NULL) { delete g_trendFilter; g_trendFilter = NULL; }
   if(g_rsiStrategy != NULL) { delete g_rsiStrategy; g_rsiStrategy = NULL; }
   if(g_maCrossStrategy != NULL) { delete g_maCrossStrategy; g_maCrossStrategy = NULL; }
   
   // ETAPA 3: Deletar SignalManager
   //          (destrutor vai chamar Deinitialize() mas ponteiros estão NULL - seguro!)
   if(g_signalManager != NULL) { delete g_signalManager; g_signalManager = NULL; }
   
   // ETAPA 4: Deletar módulos base
   if(g_riskManager != NULL) { delete g_riskManager; g_riskManager = NULL; }
   if(g_blockers != NULL) { delete g_blockers; g_blockers = NULL; }
   if(g_logger != NULL) { delete g_logger; g_logger = NULL; }
   
   Print("════════════════════════════════════════════════════════════════");
   Print("           ✅ EPBOT MATRIX FINALIZADO COM SUCESSO!              ");
   Print("════════════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| FUNÇÃO PRINCIPAL - OnTick()                                       |
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
      g_logger.LogDebug("🕐 Novo candle detectado: " + TimeToString(currentBarTime));
   }
   
   // Detectar mudança de dia (para reset diário e relatório)
   static int lastDay = 0;
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   
   if(lastDay != 0 && timeStruct.day != lastDay)
   {
      // Novo dia detectado - gerar relatório do dia anterior
      g_logger.LogInfo("═══════════════════════════════════════════════════════════════");
      g_logger.LogInfo("📅 NOVO DIA DETECTADO - " + TimeToString(TimeCurrent(), TIME_DATE));
      g_logger.LogInfo("═══════════════════════════════════════════════════════════════");
      
      // Gerar relatório final do dia anterior (se houve trades)
      if(g_logger.GetDailyTrades() > 0)
      {
         g_logger.LogInfo("📄 Gerando relatório do dia anterior...");
         g_logger.SaveDailyReport();
         
         // TODO: Quando módulos tiverem ResetDaily(), descomentar:
         // g_logger.ResetDaily();
         // g_blockers.ResetDaily();
         
         g_logger.LogInfo("✅ Relatório salvo - Iniciando novo dia de trading");
      }
      else
      {
         g_logger.LogInfo("ℹ️ Dia anterior sem trades - Iniciando novo dia");
      }
      
      g_logger.LogInfo("═══════════════════════════════════════════════════════════════");
   }
   
   lastDay = timeStruct.day;
   
   // ═══════════════════════════════════════════════════════════════
   // ETAPA 2: VERIFICAR BLOCKERS
   // ═══════════════════════════════════════════════════════════════
   
   // Calcular estatísticas diárias para Blockers
   int dailyTrades = g_logger.GetDailyTrades();
   double dailyProfit = g_logger.GetDailyProfit();
   string blockReason = "";
   
   if(!g_blockers.CanTrade(dailyTrades, dailyProfit, blockReason))
   {
      g_logger.LogDebug("🚫 Trading bloqueado: " + blockReason);
      return;
   }
   
   // ═══════════════════════════════════════════════════════════════
   // ETAPA 3: VERIFICAR SE JÁ TEM POSIÇÃO ABERTA
   // ═══════════════════════════════════════════════════════════════
   
   // Detectar fechamento de posição
   static ulong lastPositionTicket = 0;
   bool hasPosition = PositionSelect(_Symbol);
   
   // Se tinha posição e agora não tem mais = fechou!
   if(lastPositionTicket > 0 && !hasPosition)
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
                  
                  g_logger.LogInfo("📊 Posição #" + IntegerToString(lastPositionTicket) + " fechada | P/L: $" + DoubleToString(positionProfit, 2));
                  
                  // Gerar relatório TXT atualizado após cada trade
                  g_logger.SaveDailyReport();
                  g_logger.LogInfo("📄 Relatório diário atualizado");
                  
                  break;
               }
            }
         }
      }
      
      lastPositionTicket = 0;
   }
   
   // Atualizar ticket da posição atual
   if(hasPosition)
   {
      lastPositionTicket = PositionGetInteger(POSITION_TICKET);
   }
   
   if(hasPosition)
   {
      // ════════════════════════════════════════════════════════════
      // GERENCIAMENTO DE POSIÇÃO ABERTA
      // ════════════════════════════════════════════════════════════
      ManageOpenPosition();
      return;
   }
   
   // ═══════════════════════════════════════════════════════════════
   // ETAPA 4: BUSCAR SINAL (só se não tem posição)
   // ═══════════════════════════════════════════════════════════════
   ENUM_SIGNAL_TYPE signal = g_signalManager.GetSignal();
   
   if(signal == SIGNAL_NONE)
   {
      g_logger.LogDebug("ℹ️ Nenhum sinal válido detectado");
      return;
   }
   
   // ═══════════════════════════════════════════════════════════════
   // ETAPA 5: EXECUTAR TRADE
   // ═══════════════════════════════════════════════════════════════
   ExecuteTrade(signal);
}

//+------------------------------------------------------------------+
//| GERENCIAR POSIÇÃO ABERTA                                         |
//+------------------------------------------------------------------+
void ManageOpenPosition()
{
   // ═══════════════════════════════════════════════════════════════
   // GERENCIAMENTO DE RISCO
   // ═══════════════════════════════════════════════════════════════
   
   // Obter dados da posição
   if(!PositionSelect(_Symbol))
      return;
   
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double currentPrice = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   ulong ticket = PositionGetInteger(POSITION_TICKET);
   
   // Trailing Stop
   if(inp_UseTrailing)
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
            g_logger.LogInfo("✅ Trailing Stop movido para " + DoubleToString(trailing.new_sl_price, _Digits));
         }
      }
   }
   
   // Breakeven
   if(inp_UseBreakeven)
   {
      static bool beActivated = false; // TODO: Controlar por posição
      
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
            g_logger.LogInfo("✅ Breakeven ativado em " + DoubleToString(breakeven.new_sl_price, _Digits));
            beActivated = true;
         }
      }
   }
   
// ═══════════════════════════════════════════════════════════════
   // VERIFICAR SINAL DE SAÍDA (Exit por sinal oposto)
   // ═══════════════════════════════════════════════════════════════
   
   // Verificar se MACross está configurada para exit por sinal oposto
   bool checkExit = false;
   
   if(inp_UseMACross && (inp_ExitMode == EXIT_FCO || inp_ExitMode == EXIT_VM))
   {
      checkExit = true;
   }
   
   // Se alguma strategy precisa checar exit, buscar sinal RAW (sem filtros)
   if(checkExit)
   {
      ENUM_SIGNAL_TYPE exitSignal = g_signalManager.GetRawSignal();
      
      // Verificar se sinal é OPOSTO à posição atual
      bool shouldExit = false;
      
      if(posType == POSITION_TYPE_BUY && exitSignal == SIGNAL_SELL)
      {
         shouldExit = true;
         g_logger.LogInfo("🔄 Exit detectado: Sinal de VENDA com posição de COMPRA aberta");
      }
      else if(posType == POSITION_TYPE_SELL && exitSignal == SIGNAL_BUY)
      {
         shouldExit = true;
         g_logger.LogInfo("🔄 Exit detectado: Sinal de COMPRA com posição de VENDA aberta");
      }
      
      // Fechar posição se sinal oposto detectado
      if(shouldExit)
      {
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
         request.comment = "Exit: Sinal Oposto";
         request.type_filling = GetTypeFilling(_Symbol);
         
         if(OrderSend(request, result))
         {
            if(result.retcode == TRADE_RETCODE_DONE)
            {
               g_logger.LogInfo("✅ Posição fechada por sinal oposto");
               g_logger.LogInfo("   Ticket: " + IntegerToString(result.order));
               g_logger.LogInfo("   Preço: " + DoubleToString(result.price, _Digits));
            }
            else
            {
               g_logger.LogWarning("⚠️ Fechamento parcial - Retcode: " + IntegerToString(result.retcode));
            }
         }
         else
         {
            g_logger.LogError("❌ Falha ao fechar posição - Código: " + IntegerToString(result.retcode));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| EXECUTAR TRADE                                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_SIGNAL_TYPE signal)
{
   g_logger.LogInfo("════════════════════════════════════════════════════════════════");
   g_logger.LogInfo("🎯 SINAL DETECTADO: " + EnumToString(signal));
   
   // ═══════════════════════════════════════════════════════════════
   // DETERMINAR TIPO DE ORDEM
   // ═══════════════════════════════════════════════════════════════
   ENUM_ORDER_TYPE orderType;
   
   if(signal == SIGNAL_BUY)
      orderType = ORDER_TYPE_BUY;
   else if(signal == SIGNAL_SELL)
      orderType = ORDER_TYPE_SELL;
   else
   {
      g_logger.LogWarning("⚠️ Sinal inválido ignorado: " + EnumToString(signal));
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
      g_logger.LogError("❌ Falha ao calcular lote - Valor inválido: " + DoubleToString(lotSize, 2));
      return;
   }
   
   // Stop Loss
   double slPrice = g_riskManager.CalculateSLPrice(orderType, price);
   if(slPrice <= 0)
   {
      g_logger.LogError("❌ Falha ao calcular SL - Valor inválido");
      return;
   }
   
   // Take Profit
   double tpPrice = g_riskManager.CalculateTPPrice(orderType, price);
   // TP pode ser 0 se configurado como NONE
   
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
   request.tp = tpPrice;
   request.deviation = inp_Slippage;
   request.magic = inp_MagicNumber;
   request.comment = inp_TradeComment;
   request.type_filling = GetTypeFilling(_Symbol);
   
   // Log dos parâmetros
   g_logger.LogInfo("📊 Parâmetros da Ordem:");
   g_logger.LogInfo("   Tipo: " + EnumToString(orderType));
   g_logger.LogInfo("   Lote: " + DoubleToString(lotSize, 2));
   g_logger.LogInfo("   Preço: " + DoubleToString(price, _Digits));
   g_logger.LogInfo("   SL: " + DoubleToString(slPrice, _Digits));
   g_logger.LogInfo("   TP: " + DoubleToString(tpPrice, _Digits));
   
   // Enviar ordem
   if(!OrderSend(request, result))
   {
      g_logger.LogError("❌ Falha ao enviar ordem - Código: " + IntegerToString(result.retcode));
      g_logger.LogError("   Descrição: " + result.comment);
      return;
   }
   
   // Verificar resultado
   if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
   {
      g_logger.LogInfo("✅ ORDEM EXECUTADA COM SUCESSO!");
      g_logger.LogInfo("   Ticket: " + IntegerToString(result.order));
      g_logger.LogInfo("   Deal: " + IntegerToString(result.deal));
      g_logger.LogInfo("   Volume: " + DoubleToString(result.volume, 2));
      g_logger.LogInfo("   Preço: " + DoubleToString(result.price, _Digits));
      
      // Atualizar estatísticas do Logger (SaveTrade será chamado no fechamento)
      // Blockers.UpdateAfterTrade será chamado quando soubermos o resultado
   }
   else
   {
      g_logger.LogWarning("⚠️ Ordem parcialmente executada - Retcode: " + IntegerToString(result.retcode));
      g_logger.LogWarning("   Descrição: " + result.comment);
   }
   
   g_logger.LogInfo("════════════════════════════════════════════════════════════════");
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
   else if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
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
//| FIM DO EA - EPBOT MATRIX v1.00                                   |
//+------------------------------------------------------------------+
