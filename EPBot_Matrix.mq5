//+------------------------------------------------------------------+
//|                                                 EPBot_Matrix.mq5 |
//|                                         Copyright 2026, EP Filho |
//|                          EA Modular Multistrategy - EPBot Matrix |
//|                     Versão 1.40 - Claude Parte 023 (Claude Code) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO"
#property version   "1.40"
#property description "EPBot Matrix - Sistema de Trading Modular Multi Estratégias"

//+------------------------------------------------------------------+
//| CHANGELOG v1.40:                                                 |
//| PANEL v1.17 + BLOCKERS v3.09 — CONFIG BLOQUEIOS EXPANDIDO (Parte 023): |
//|    - Partial TP movido de RISCO 2 → RISCO (m_cr_bPTP etc.)       |
//|    - BLOQUEIOS: radio Profit Target Action (PARAR|ATIVAR DD)      |
//|    - BLOQUEIOS: radio Streak Action (PAUSAR|PARAR DIA) + pause min|
//|    - BLOQUEIOS: radio DD Type (FINANCEIRO|PERCENTUAL)             |
//|    - BLOQUEIOS: radio DD Peak Mode (SO REAL.|C/FLUTUANTE)         |
//|    - Blockers v3.09: SetDrawdownType + SetDrawdownPeakMode        |
//|    - RefreshStreakState: pausa fields visíveis só se PAUSAR ativo  |
//+------------------------------------------------------------------+
//| CHANGELOG v1.39:                                                 |
//| PANEL v1.16 — RADIO BUTTONS + RISCO 2 (Claude Code):             |
//|    - Cycle buttons -> CButton[] horizontais (SL Type, TP Type,    |
//|      Direcao) — clique determinisico, sem ciclo                   |
//|    - Sub-pagina RISCO 2: Trailing ON/OFF, BE ON/OFF, Partial TP   |
//|    - SetTrailingActivation/SetBEActivation: hot-reload toggles    |
//|    - RefreshRisco2State: enable/disable campos Trail/BE/Partial    |
//|    - 4 sub-paginas CONFIG: RISCO | RISCO 2 | BLOQUEIOS | OUTROS   |
//+------------------------------------------------------------------+
//| CHANGELOG v1.38:                                                 |
//| PANEL v1.15 — FIX CLICKS (Claude Code):                          |
//|    - OnEvent: CAppDialog::OnEvent() agora processa PRIMEIRO       |
//|      (gera ON_CLICK a partir de CHARTEVENT_OBJECT_CLICK)          |
//|    - Fix: SL Type, Direction e demais botões agora respondem      |
//+------------------------------------------------------------------+
//| CHANGELOG v1.37:                                                 |
//| 🖥️ PANEL v1.14 — POSIÇÕES FIXAS + ENABLE/DISABLE (Claude Code):  |
//|    - Abandonado Move(): campos em posições fixas, sempre visíveis  |
//|    - RefreshRiscoState(): enable/disable visual por tipo SL/TP    |
//|    - Campos desabilitados: label cinza, CEdit ReadOnly + fundo    |
//|    - Conflito TP ATR vs Partial TP: bloqueio mútuo com "BLOQ."   |
//|    - Fix: clicks em Direction/SL Type agora funcionam             |
//|    - Fix: minimize/maximize sem encavalamento de texto            |
//+------------------------------------------------------------------+
//| CHANGELOG v1.36:                                                 |
//| 🖥️ PANEL v1.13 — LAYOUT RISCO DINÂMICO (Claude Code):             |
//|    - LayoutRisco() com Move() — campos se reposicionam sem gaps   |
//|    - ATR Period, Range Period, Comp Spread inline com SL/TP       |
//|    - Eliminada seção CONFIGURACAO separada                         |
//|    - Todos controles RISCO criados incondicionalmente              |
//+------------------------------------------------------------------+
//| CHANGELOG v1.35:                                                 |
//| 🖥️ PANEL v1.12 — SELETORES DE TIPO SL/TP (Claude Code):          |
//|    - SL Type: cycle button FIXO → ATR → RANGE (label dinâmico)   |
//|    - TP Type: cycle button NENHUM → FIXO → ATR (show/hide)       |
//|    - TP, ATR Period, Range Period, Comp TP sempre criados         |
//|    - RiskManager v3.14: SetSLType, SetTPType, SetRangeMultiplier |
//|    - PANEL_HEIGHT 540→600, CFG_APPLY_Y 420→520                   |
//+------------------------------------------------------------------+
//| CHANGELOG v1.34:                                                 |
//| 🖥️ PANEL v1.11 — FIX + RISCO EXPANDIDO (Claude Code):            |
//|    - Fix: ChartRedraw() nos toggles (Direção não atualizava)     |
//|    - Fix: encavalamento sub-páginas CONFIG                        |
//|    - RISCO: ATR Period, Range Period, Compensar Spread SL/TP/Trail|
//|    - RiskManager: 5 novos setters hot-reload                      |
//+------------------------------------------------------------------+
//| CHANGELOG v1.33:                                                 |
//| 🖥️ HOT RELOAD + PARTIÇÃO DO PAINEL (Claude Code):                |
//|    - Panel.mqh v1.10: aba CONFIG redesenhada com campos editáveis|
//|      3 sub-páginas (RISCO | BLOQUEIOS | OUTROS)                  |
//|      CEdit para valores numéricos, CButton para toggles/cycles   |
//|      Botão APLICAR chama setters hot-reload nos módulos           |
//|      Campos condicionais (só aparecem se feature está ativa)      |
//|    - Código do painel dividido em 6 arquivos por aba:            |
//|      Panel.mqh (core), PanelTab{Status,Resultados,Estrategias,   |
//|      Filtros,Config}.mqh                                         |
//+------------------------------------------------------------------+
//| CHANGELOG v1.32:                                                 |
//| 🖥️ PAINEL GUI (Claude Code):                                     |
//|    - Novo módulo GUI/Panel.mqh (v1.09) com 5 abas               |
//|    - Integração: include, global, OnInit, OnDeinit, OnChartEvent |
//|    - Timer 1.5s para atualização seletiva da aba ativa           |
//|    - Proteção de mouse: MouseProtection() desabilita             |
//|      CHART_DRAG_TRADE_LEVELS e CHART_MOUSE_SCROLL sobre painel   |
//|    - Input inp_ShowPanel para habilitar/desabilitar               |
//+------------------------------------------------------------------+
//| CHANGELOG v1.31:                                                 |
//| 🎯 CORREÇÃO: Revisão completa de bugs (Claude Code):             |
//|    - CopyBuffer: validação alterada de <= 0 para < count         |
//|    - HistorySelect: janela ampliada de 10s para 60s              |
//|    - Log adicionado quando PositionSelectByTicket falha           |
//+------------------------------------------------------------------+
//| CHANGELOG v1.30:                                                 |
//| 🎯 CORREÇÃO: Entrada no mesmo CANDLE                             |
//| 🎯 CORREÇÃO: Filtro de Direção não funcionava:                   |
//|    - CanTradeDirection() existia mas nunca era chamada            |
//|    - Adicionada verificação em ExecuteTrade() antes do OrderSend  |
//|    - inp_TradeDirection (SELL_ONLY/BUY_ONLY) agora respeitado    |
//|    - Log com LOG_EVENT quando direção é bloqueada                |
//+------------------------------------------------------------------+
//| CHANGELOG v1.29:                                                 |
//| 🔧 Modo de Cálculo do Pico de Drawdown configurável:             |
//|    - Init() passa inp_DrawdownPeakMode para Blockers             |
//|    - ActivateDrawdownProtection() recebe closedProfit e          |
//|      projectedProfit separados                                   |
//|    - Compatível com Blockers v3.06                               |
//+------------------------------------------------------------------+
//| CHANGELOG v1.28:                                                 |
//| 🔧 Remoção de inp_InitialBalance:                                |
//|    - Saldo inicial agora auto-detectado via AccountBalance()     |
//|    - Removido parâmetro da chamada g_blockers.Init()             |
//|    - Compatível com Blockers v3.05                               |
//+------------------------------------------------------------------+
//| CHANGELOG v1.27:                                                 |
//| 🎯 CORREÇÃO: TPs Parciais agora usam valores REAIS do deal:      |
//|    - TradeManager v1.22 busca DEAL_PROFIT/DEAL_PRICE do histórico|
//|    - Elimina discrepâncias por slippage em mercados voláteis     |
//|    - Logger v3.22 compatível com novos valores reais             |
//|    - Fallback para estimativa se deal não encontrado             |
//+------------------------------------------------------------------+
//| CHANGELOG v1.26:                                                 |
//| 📊 TPs Parciais agora salvos no CSV (3 linhas por trade):        |
//|    - Logger v3.20 com SavePartialTrade()                         |
//|    - TradeManager v1.21 chama SavePartialTrade() após TP1/TP2    |
//|    - LoadDailyStats() reconhece linhas "Partial TP"              |
//|    - Habilita ressincronização de TPs parciais ao reiniciar      |
//+------------------------------------------------------------------+
//| CHANGELOG v1.24:                                                 |
//| 🎯 CORREÇÃO CRÍTICA - TPs Parciais no Daily Profit:              |
//|    - Lucro de TP1/TP2 agora contabilizado em tempo real         |
//|    - GetDailyProfit() inclui m_partialTPProfit                  |
//|    - Limites diários (ganho/perda) consideram TPs parciais      |
//|    - Drawdown protection considera TPs parciais realizados      |
//|    - Logger v3.10 com AddPartialTPProfit()                      |
//|    - TradeManager v1.20 registra lucro após cada TP parcial     |
//+------------------------------------------------------------------+
//| CHANGELOG v1.23:                                                 |
//| 🛡️ VERIFICAÇÃO DE DRAWDOWN EM TEMPO REAL:                       |
//|    - Calcula drawdown com lucro PROJETADO (fechados + aberta)   |
//|    - Fecha NO EXATO MOMENTO que atinge limite de drawdown       |
//|    - Atualiza pico de lucro em tempo real                       |
//|    - Mantém coerência com verificação de limites diários        |
//|    - Compatível com Blockers v3.04                              |
//+------------------------------------------------------------------+
//| CHANGELOG v1.22:                                                 |
//| 🚨 CORREÇÃO CRÍTICA - Verificação de Limites em Tempo Real:     |
//|    - Calcula lucro PROJETADO (fechados + posição aberta)        |
//|    - Fecha NO EXATO MOMENTO que atinge limite diário            |
//|    - Não deixa "dinheiro na mesa"                               |
//|    - Compatível com Blockers v3.03                              |
//|    - Verifica ANTES de trailing/breakeven/exit signals          |
//+------------------------------------------------------------------+

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

// 5️⃣ GUI (painel opcional)
#include "GUI/Panel.mqh"

//+------------------------------------------------------------------+
//| VARIÁVEIS GLOBAIS - INSTÂNCIAS DOS MÓDULOS                       |
//+------------------------------------------------------------------+

// ═══════════════════════════════════════════════════════════════
// MÓDULOS CORE
// ═══════════════════════════════════════════════════════════════
CLogger*        g_logger        = NULL;  // Sistema de logging centralizado
CBlockers*      g_blockers      = NULL;  // Gerenciador de bloqueios
CRiskManager*   g_riskManager   = NULL;  // Gerenciador de risco
CTradeManager*  g_tradeManager  = NULL;  // Gerenciador de posições (v1.22)
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
// GUI (painel opcional)
// ═══════════════════════════════════════════════════════════════
CEPBotPanel*  g_panel       = NULL;  // Painel GUI com abas

// ═══════════════════════════════════════════════════════════════
// CONTROLE DE CANDLES E POSIÇÕES (CORRIGIDO!)
// ═══════════════════════════════════════════════════════════════
datetime g_lastBarTime = 0;          // Controle de novo candle
datetime g_lastTradeBarTime = 0;     // Controle de último trade executado
datetime g_lastExitBarTime = 0;      // Controle de último exit (para FCO)
ulong    g_lastPositionTicket = 0;   // Ticket da última posição (global - sobrevive a restarts)

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
   Print("            EPBOT MATRIX v1.40 - INICIALIZANDO...              ");
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
         inp_DrawdownPeakMode,
         inp_TradeDirection
      ))
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar Blockers!");
      return INIT_FAILED;
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 3: INICIALIZAR RISK MANAGER
// ═══════════════════════════════════════════════════════════════
   g_riskManager = new CRiskManager();
   if(g_riskManager == NULL)
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar RiskManager!");
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
      return INIT_FAILED;
     }

   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "RiskManager inicializado com sucesso!");

// ═══════════════════════════════════════════════════════════════
// ETAPA 3.5: VALIDAR CONFIGURAÇÃO 
// ═══════════════════════════════════════════════════════════════
// ✅ BLOQUEAR: TP_ATR + Partial TP (conflito de conceito)
   if(inp_UsePartialTP && inp_TPType == TP_ATR)
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "════════════════════════════════════════════════════════════════");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "❌ CONFIGURAÇÃO INVÁLIDA - CONFLITO DE CONCEITO");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "   Partial TP usa níveis FIXOS em pontos");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "   TP ATR é DINÂMICO baseado em volatilidade");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "   → Combinação gera comportamento inconsistente!");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "💡 ESCOLHA UMA DAS OPÇÕES VÁLIDAS:");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "   1️⃣ TP FIXED + Partial TP = ✅ OK");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "      → Todos os níveis fixos e conhecidos");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "   2️⃣ TP NONE + Partial TP = ✅ OK");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "      → Apenas takes parciais, sem TP principal");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "   3️⃣ TP ATR sem Partial TP = ✅ OK");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "      → TP dinâmico baseado em volatilidade");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "");
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "CONFIG", "════════════════════════════════════════════════════════════════");
      
      return INIT_FAILED;
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 4: INICIALIZAR TRADE MANAGER
// ═══════════════════════════════════════════════════════════════
   g_tradeManager = new CTradeManager();
   if(g_tradeManager == NULL)
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar TradeManager!");
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
      
      // SINCRONIZAR g_lastPositionTicket para detectar fechamento futuro
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(PositionGetSymbol(i) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == inp_MagicNumber)
           {
            g_lastPositionTicket = PositionGetTicket(i);
            
            g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
                        StringFormat("🔄 lastPositionTicket sincronizado: %I64u", g_lastPositionTicket));
            break;  // Assumindo uma posição por EA
           }
        }
     }

// ═══════════════════════════════════════════════════════════════
// ETAPA 5: INICIALIZAR SIGNAL MANAGER
// ═══════════════════════════════════════════════════════════════
   g_signalManager = new CSignalManager();
   if(g_signalManager == NULL)
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar SignalManager!");
      return INIT_FAILED;
     }

// Inicializar (passa logger para as strategies/filters)
   if(!g_signalManager.Initialize(g_logger))
     {
      g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar SignalManager!");
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
         return INIT_FAILED;
        }

      // Inicializar a estratégia
      if(!g_maCrossStrategy.Initialize())
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar MACrossStrategy!");
         return INIT_FAILED;
        }

      // Definir prioridade ANTES de adicionar
      g_maCrossStrategy.SetPriority(inp_MACrossPriority);

      if(!g_signalManager.AddStrategy(g_maCrossStrategy))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar MACrossStrategy no SignalManager!");
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
         return INIT_FAILED;
        }

      // Inicializar a estratégia
      if(!g_rsiStrategy.Initialize())
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar RSIStrategy!");
         return INIT_FAILED;
        }

      // Definir prioridade ANTES de adicionar
      g_rsiStrategy.SetPriority(inp_RSIPriority);

      if(!g_signalManager.AddStrategy(g_rsiStrategy))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar RSIStrategy no SignalManager!");
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
         return INIT_FAILED;
        }

      // Inicializar o filtro
      if(!g_trendFilter.Initialize())
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar TrendFilter!");
         return INIT_FAILED;
        }

      if(!g_signalManager.AddFilter(g_trendFilter))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar TrendFilter no SignalManager!");
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
         return INIT_FAILED;
        }

      // Inicializar o filtro
      if(!g_rsiFilter.Initialize())
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao inicializar RSIFilter!");
         return INIT_FAILED;
        }

      if(!g_signalManager.AddFilter(g_rsiFilter))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao registrar RSIFilter no SignalManager!");
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
// ETAPA 9: PAINEL GUI (opcional)
// ═══════════════════════════════════════════════════════════════
   if(inp_ShowPanel && !MQLInfoInteger(MQL_TESTER))
     {
      g_panel = new CEPBotPanel();
      if(g_panel != NULL)
        {
         g_panel.Init(g_logger, g_blockers, g_riskManager, g_tradeManager,
                      g_signalManager, g_maCrossStrategy, g_rsiStrategy,
                      g_trendFilter, g_rsiFilter, inp_MagicNumber, _Symbol);

         int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
         int x1 = chartWidth - PANEL_WIDTH - 10;
         if(!g_panel.CreatePanel(0, "EPBotMatrix - Versão 1.40", 0, x1, 20, x1 + PANEL_WIDTH, 20 + PANEL_HEIGHT))
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

// ═══════════════════════════════════════════════════════════════
// SUCESSO!
// ═══════════════════════════════════════════════════════════════
   Print("════════════════════════════════════════════════════════════════");
   Print("          ✅ EPBOT MATRIX INICIALIZADO COM SUCESSO!            ");
   Print("════════════════════════════════════════════════════════════════");

   g_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "🚀 EPBot Matrix v1.40 - PRONTO PARA OPERAR!");
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
// Proteger TODOS os logs contra ponteiro NULL
   if(g_logger != NULL)
     {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT", "════════════════════════════════════════════════════════════════");
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT", "            EPBOT MATRIX - FINALIZANDO...                      ");
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT", "════════════════════════════════════════════════════════════════");
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT",
                   "Motivo: " + IntegerToString(reason) + " - " + GetDeinitReasonText(reason));

      // Salvar relatório diário antes de finalizar
      if(g_logger.GetDailyTrades() > 0)
        {
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DEINIT", "📄 Gerando relatório final...");
         g_logger.SaveDailyReport();
        }
     }

// ═══════════════════════════════════════════════════════════════
// LIMPEZA SEGURA - Ordem inversa da inicialização
// ═══════════════════════════════════════════════════════════════

// ETAPA 0: Destruir painel GUI (ANTES dos módulos)
   if(g_panel != NULL)
     {
      g_panel.Destroy(reason);
      delete g_panel;
      g_panel = NULL;
     }
   EventKillTimer();

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
//| FUNÇÃO PRINCIPAL - OnTick()                                      |
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

// Usar variável GLOBAL (não mais static local)

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
   if(g_lastPositionTicket > 0 && !hasMyPosition)
     {
      // Buscar informação do fechamento no histórico
      if(HistorySelectByPosition(g_lastPositionTicket))
        {
         // ═══════════════════════════════════════════════════════════════
         // v1.26: PADRÃO OURO MQL5 - Calcular lucro total da posição
         // somando TODOS os deals de saída diretamente do histórico
         // Referência: https://www.mql5.com/en/forum/439334
         // ═══════════════════════════════════════════════════════════════
         double totalPositionProfit = 0;  // Soma de TODOS os deals de saída desta posição
         double finalDealProfit = 0;      // Apenas o deal final (para salvar no CSV)
         ulong  finalDealTicket = 0;
         bool   foundFinalDeal = false;

         // Iterar por TODOS os deals desta posição
         for(int i = 0; i < HistoryDealsTotal(); i++)
           {
            ulong dealTicket = HistoryDealGetTicket(i);
            if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == g_lastPositionTicket)
              {
               long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
               if(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY)
                 {
                  // Somar lucro de TODOS os deals de saída (parciais + final)
                  double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                  totalPositionProfit += dealProfit;

                  string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);

                  // TPs parciais já foram salvos por SavePartialTrade()
                  if(StringFind(dealComment, "Partial") >= 0)
                     continue;

                  // Este é um deal final (SL, TP fixo, trailing, etc)
                  finalDealProfit = dealProfit;
                  finalDealTicket = dealTicket;
                  foundFinalDeal = true;
                  // NÃO usar break - continuar para pegar o último
                 }
              }
           }

         // Processar o deal final (se encontrado)
         if(foundFinalDeal)
           {
            // Salvar trade no Logger (apenas o deal final)
            g_logger.SaveTrade(g_lastPositionTicket, finalDealProfit);

            // Atualizar estatísticas (apenas o deal final)
            g_logger.UpdateStats(finalDealProfit);

            // Registrar no Blockers - usar totalPositionProfit para determinar win/loss
            bool isWin = (totalPositionProfit > 0);
            g_blockers.UpdateAfterTrade(isWin, finalDealProfit);

            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "CLOSE",
                         "📊 Posição #" + IntegerToString(g_lastPositionTicket) +
                         " fechada | P/L final: $" + DoubleToString(finalDealProfit, 2) +
                         " | Total posição: $" + DoubleToString(totalPositionProfit, 2));

            // Gerar relatório TXT atualizado após cada trade
            g_logger.SaveDailyReport();
            g_logger.Log(LOG_TRADE, THROTTLE_NONE, "REPORT", "📄 Relatório diário atualizado");
           }
        }

      // Remover do TradeManager
      g_tradeManager.UnregisterPosition(g_lastPositionTicket);

      // Bloquear re-entrada no mesmo candle ao fechar posição (exceto no modo VM)
      if(inp_ExitMode != EXIT_VM)
        {
         g_lastTradeBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
         g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "RESET", "🔄 Controle de candle atualizado - aguardando próximo candle para novo trade");
        }

      g_lastPositionTicket = 0;
     }

// ═══════════════════════════════════════════════════════════════
// SE EXISTE POSIÇÃO DESTE EA: GERENCIAR
// ═══════════════════════════════════════════════════════════════
   if(hasMyPosition)
     {
      // Atualizar ticket da posição atual
      g_lastPositionTicket = myPositionTicket;

      // Selecionar a posição específica
      if(!PositionSelectByTicket(myPositionTicket))
        {
         g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "POSITION",
            "⚠️ Falha ao selecionar posição #" + IntegerToString((int)myPositionTicket));
         return;
        }

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
// 🚨 VERIFICAR LIMITES DIÁRIOS EM TEMPO REAL
// Calcula lucro PROJETADO (fechados + aberta) e fecha NO EXATO
// MOMENTO que atinge o limite configurado
// ═══════════════════════════════════════════════════════════════
   double dailyProfit = g_logger.GetDailyProfit();
   string closeReason = "";

   // ✅ Passa TICKET para calcular lucro projetado em tempo real
   if(g_blockers.ShouldCloseByDailyLimit(ticket, dailyProfit, closeReason))
     {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
                   "🚨 " + closeReason);
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
                   "   Fechando posição #" + IntegerToString((int)ticket) + " IMEDIATAMENTE");

      // Monta request de fechamento
      MqlTradeRequest request = {};
      MqlTradeResult result = {};

      request.action = TRADE_ACTION_DEAL;
      request.position = ticket;
      request.symbol = _Symbol;
      request.volume = PositionGetDouble(POSITION_VOLUME);
      request.type = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      request.price = (posType == POSITION_TYPE_BUY) ?
                     SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                     SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      request.deviation = inp_Slippage;
      request.magic = inp_MagicNumber;
      request.comment = "Daily Limit";
      request.type_filling = GetTypeFilling(_Symbol);

      // Envia ordem
      if(!OrderSend(request, result))
        {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "DAILY_LIMIT",
            "❌ Erro ao fechar posição #" + IntegerToString((int)ticket) +
            " | Código: " + IntegerToString(result.retcode) +
            " | " + result.comment);
        }
      else
        {
         if(result.retcode == TRADE_RETCODE_DONE)
           {
            g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
               "✅ Posição #" + IntegerToString((int)ticket) + " fechada por limite diário");
            g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
               "   Preço: " + DoubleToString(result.price, _Digits));
           }
         else
           {
            g_logger.Log(LOG_ERROR, THROTTLE_NONE, "DAILY_LIMIT",
               "⚠️ Fechamento com retcode: " + IntegerToString(result.retcode));
           }
        }

      return; // ✅ SAI IMEDIATAMENTE - não continua gerenciamento
     }

// ═══════════════════════════════════════════════════════════════
// 🛡️ VERIFICAR DRAWDOWN EM TEMPO REAL
// Calcula drawdown com lucro PROJETADO e fecha NO EXATO MOMENTO
// que atinge o limite de drawdown configurado
// ═══════════════════════════════════════════════════════════════
   if(g_blockers.IsDrawdownProtectionActive())
     {
      string ddCloseReason = "";
      
      // ✅ Passa TICKET para calcular drawdown com lucro projetado
      if(g_blockers.ShouldCloseByDrawdown(ticket, dailyProfit, ddCloseReason))
        {
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                      "🛑 " + ddCloseReason);
         g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                      "   Fechando posição #" + IntegerToString((int)ticket) + " IMEDIATAMENTE");

         // Monta request de fechamento
         MqlTradeRequest request = {};
         MqlTradeResult result = {};

         request.action = TRADE_ACTION_DEAL;
         request.position = ticket;
         request.symbol = _Symbol;
         request.volume = PositionGetDouble(POSITION_VOLUME);
         request.type = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
         request.price = (posType == POSITION_TYPE_BUY) ?
                        SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                        SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         request.deviation = inp_Slippage;
         request.magic = inp_MagicNumber;
         request.comment = "Drawdown Limit";
         request.type_filling = GetTypeFilling(_Symbol);

         // Envia ordem
         if(!OrderSend(request, result))
           {
            g_logger.Log(LOG_ERROR, THROTTLE_NONE, "DRAWDOWN",
               "❌ Erro ao fechar posição #" + IntegerToString((int)ticket) +
               " | Código: " + IntegerToString(result.retcode) +
               " | " + result.comment);
           }
         else
           {
            if(result.retcode == TRADE_RETCODE_DONE)
              {
               g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                  "✅ Posição #" + IntegerToString((int)ticket) + " fechada por drawdown");
               g_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                  "   Preço: " + DoubleToString(result.price, _Digits));
              }
            else
              {
               g_logger.Log(LOG_ERROR, THROTTLE_NONE, "DRAWDOWN",
                  "⚠️ Fechamento com retcode: " + IntegerToString(result.retcode));
              }
           }

         return; // ✅ SAI IMEDIATAMENTE - não continua gerenciamento
        }
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
   STrailingResult trailing = g_riskManager.CalculateTrailing(
      posType, currentPrice, entryPrice, currentSL);
   
   if(trailing.should_move)
   {
      MqlTradeRequest request = {};
      MqlTradeResult result = {};
      
      request.action = TRADE_ACTION_SLTP;
      request.position = ticket;
      request.symbol = _Symbol;
      request.sl = trailing.new_sl_price;
      
      // Só LÊ TP se TP2 não foi executado
      double tpForLog = 0.0;
      if(!tp2Executed)
      {
         double currentTP = PositionGetDouble(POSITION_TP);
         request.tp = currentTP;
         tpForLog = currentTP;
      }
      // Se tp2Executed = true, request.tp fica 0 (padrão)
      
      if(OrderSend(request, result))
      {
         string tpInfo = (tpForLog == 0) ? " (sem TP)" : 
                         StringFormat(" | TP: %.5f", tpForLog);
         
         g_logger.Log(LOG_TRADE, THROTTLE_TIME, "TRAILING", 
            StringFormat("✅ Trailing: SL %.5f → %.5f%s", 
            currentSL, trailing.new_sl_price, tpInfo), 5);
      }
      else
      {
         g_logger.Log(LOG_ERROR, THROTTLE_NONE, "TRAILING",
            StringFormat("❌ Falha | Pos: #%I64u | Retcode: %d (%s) | SL: %.5f | TP: %.5f", 
            ticket, result.retcode, result.comment, trailing.new_sl_price, tpForLog));
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
//| EXECUTAR TRADE                                            |
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
// VERIFICAR FILTRO DE DIREÇÃO
// ═══════════════════════════════════════════════════════════════
   string dirBlockReason = "";
   if(!g_blockers.CanTradeDirection(orderType, dirBlockReason))
     {
      g_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCKER", "🚫 " + dirBlockReason);
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
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   Order: " + IntegerToString(result.order));
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   Deal: " + IntegerToString(result.deal));
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   Volume: " + DoubleToString(result.volume, 2));
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE", "   Preço: " + DoubleToString(result.price, _Digits));

      // 🆕 REGISTRAR CANDLE DO TRADE
      g_lastTradeBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
      g_logger.Log(LOG_TRADE, THROTTLE_NONE, "TRADE",
                   "📊 Trade executado no candle: " + TimeToString(g_lastTradeBarTime));

      // ═══════════════════════════════════════════════════════════════
      // ✅ CORREÇÃO  - OBTER TICKET CORRETO DA POSIÇÃO
      // ═══════════════════════════════════════════════════════════════
      ulong positionTicket = 0;
      
      // MÉTODO 1: INSTITUCIONAL - Usar DEAL_POSITION_ID
      if(result.deal > 0)
        {
         // Atualizar histórico para garantir que deal está disponível
         datetime from = TimeCurrent() - 60;
         datetime to = TimeCurrent();
         
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
              {
               g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "TRADE",
                           "⚠️ Deal não encontrado na história: " + IntegerToString(result.deal));
              }
           }
         else
           {
            g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "TRADE",
                        "⚠️ Falha ao atualizar histórico");
           }
        }
      
      // MÉTODO 2: FALLBACK - Busca robusta por símbolo/magic/tempo
      if(positionTicket == 0 || !PositionSelectByTicket(positionTicket))
        {
         g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "TRADE",
                     "⚠️ Fallback: Buscando posição por símbolo + magic...");
         
         int total = PositionsTotal();
         for(int i = 0; i < total; i++)
           {
            ulong ticket = PositionGetTicket(i);
            if(ticket == 0) continue;
            
            if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
               PositionGetInteger(POSITION_MAGIC) == inp_MagicNumber)
              {
               // Verificar se foi aberta "agora" (últimos 5 segundos)
               datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
               if(TimeCurrent() - openTime < 5)
                 {
                  positionTicket = ticket;
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
                     "❌ Posição não encontrada após abertura! Order: " + IntegerToString(result.order));
         return;
        }

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

      // ✅ REGISTRAR COM O TICKET CORRETO
      g_tradeManager.RegisterPosition(
         positionTicket,  // ✅ TICKET CORRETO DA POSIÇÃO
         (orderType == ORDER_TYPE_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL,
         result.price,
         result.volume,
         hasPartialTP,
         tpLevels
      );
      
      // ATUALIZAR g_lastPositionTicket GLOBAL
      g_lastPositionTicket = positionTicket;
      g_logger.Log(LOG_DEBUG, THROTTLE_NONE, "TRADE",
                  StringFormat("🔄 g_lastPositionTicket atualizado: %I64u", g_lastPositionTicket));
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
//| EVENTO DE GRÁFICO — encaminha para o painel GUI                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam,
                  const double &dparam, const string &sparam)
  {
   if(g_panel != NULL)
     {
      g_panel.ChartEvent(id, lparam, dparam, sparam);

      // Proteção: desabilita arrasto de SL/TP quando mouse sobre o painel
      if(id == CHARTEVENT_MOUSE_MOVE)
         g_panel.MouseProtection((int)lparam, (int)dparam);
     }
  }

//+------------------------------------------------------------------+
//| TIMER — atualiza o painel GUI                                     |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(g_panel != NULL)
      g_panel.Update();
  }

//+------------------------------------------------------------------+
//| FIM DO EA - EPBOT MATRIX v1.40                                   |
//+------------------------------------------------------------------+
