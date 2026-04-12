//+------------------------------------------------------------------+
//|                                                       Inputs.mqh |
//|                                         Copyright 2026, EP Filho |
//|                   Sistema de Inputs Centralizados - EPBot Matrix |
//|                     Versão 1.09 - Claude Parte 027 (Claude Code) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO"
#property version   "1.09"

// ═══════════════════════════════════════════════════════════════
// CHANGELOG v1.09 (Parte 027):
// ✅ Sem novos inputs (apenas GUI expõe campos existentes)
//    Magic Number, Trade Comment, Daily Limits agora na GUI
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v1.08 (Parte 026):
// ✅ Novos inputs para BB Strategy (Bollinger Bands):
//    inp_UseBB, inp_BBPriority, inp_BBPeriod, inp_BBDeviation,
//    inp_BBApplied, inp_BBTF, inp_BBMode, inp_BBEntryMode, inp_BBExitMode
// ✅ Novos inputs para BB Filter (Anti-Squeeze):
//    inp_UseBBFilter, inp_BBFiltPeriod, inp_BBFiltDeviation,
//    inp_BBFiltApplied, inp_BBFiltTF, inp_BBFiltMetric,
//    inp_BBFiltThreshold, inp_BBFiltPercPeriod
// ✅ Includes: BollingerBandsStrategy.mqh, BollingerBandsFilter.mqh
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v1.07:
// ✅ inp_MACrossMinDistance integrado ao MACrossStrategy::Setup() (v2.26)
//    Filtro de força do cruzamento: sinal só gerado se dist(MA rápida, MA lenta) >= N pontos
// ✅ inp_RSISignalShift removido — RSIStrategy usa shift=1 fixo (v2.15)
// ✅ Seção 007 TRADE MANAGER removida (grupo vazio no MT5 — era desnecessário)
// CHANGELOG v1.06:
// ✅ TODO (resolvido em v1.07): inp_MACrossMinDistance agora passado ao Setup()
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v1.05:
// ✅ Novo input inp_ShowPanel (Seção 008 - Painel GUI):
//    - Controla exibição do painel GUI no gráfico
//    - Default: true (painel visível)
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v1.04:
// ✅ Novo input inp_DrawdownPeakMode:
//    - Permite escolher entre pico Realizado ou com Flutuante
//    - Enum ENUM_DRAWDOWN_PEAK_MODE (definido em Blockers.mqh)
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v1.03:
// ✅ Remoção de inp_InitialBalance:
//    - Input manual removido (auto-detectado via AccountBalance)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| INCLUDES NECESSÁRIOS PARA ENUMS                                  |
//+------------------------------------------------------------------+
#include "Logger.mqh"
#include "Blockers.mqh"
#include "RiskManager.mqh"
#include "../Strategy/SignalManager.mqh"
#include "../Strategy/Strategies/MACrossStrategy.mqh"
#include "../Strategy/Strategies/RSIStrategy.mqh"
#include "../Strategy/Filters/RSIFilter.mqh"
#include "../Strategy/Strategies/BollingerBandsStrategy.mqh"
#include "../Strategy/Filters/BollingerBandsFilter.mqh"

//+------------------------------------------------------------------+
//| INPUTS GERAIS DO EA                                              |
//+------------------------------------------------------------------+
input group "═══════════════ ⚙️ CONFIGURAÇÕES GERAIS ═══════════════"
input int    inp_MagicNumber = 123456;              // Magic Number

//+------------------------------------------------------------------+
//| SEÇÃO 001 - LOGGER                                               |
//+------------------------------------------------------------------+
input group "═══════════════ 📊 LOGGER ═══════════════"
input bool inp_ShowDebugLogs = false;     // Mostrar logs DEBUG?
input int  inp_DebugCooldownSec = 5;      // Cooldown para logs DEBUG (segundos)

//+------------------------------------------------------------------+
//| SEÇÃO 002 - BLOCKERS                                             |
//+------------------------------------------------------------------+
input group "═══════════════ 🚫 BLOCKERS ═══════════════"

//--- 🕐 HORÁRIO DE OPERAÇÃO
input group "🕐 Horário de Operação - Segurança: Minuto Final pelo menos 5min antes do fim do Horário de Negociação do Ativo"
input bool   inp_EnableTimeFilter = false;        // Ativar Filtro de Horário
input int    inp_StartHour = 9;                   // Hora Inicial (0-23)
input int    inp_StartMinute = 0;                 // Minuto Inicial (0-59)
input int    inp_EndHour = 17;                    // Hora Final (0-23)
input int    inp_EndMinute = 0;                   // Minuto Final (0-59) - Segurança: 5min antes do fim do Horário de Negociação
input bool   inp_CloseOnEndTime = false;          // Fechar Posição ao Fim do Horário definido
// ═════════════════════════════════════════════════════════════════
// FILTRO DE PROTEÇÃO DE SESSÃO
// ═════════════════════════════════════════════════════════════════
input group "═══ Proteção de Sessão (Mercado Real) ═══"
input bool     inp_CloseBeforeSessionEnd = true;           // Fechar antes do fim da sessão?
input int      inp_MinutesBeforeSessionEnd = 5;            // Minutos antes do fim da sessão - Segurança: 5min antes

//--- 📰 HORÁRIOS DE VOLATILIDADE (NEWS)
input group "📰 Horários de Volatilidade (News)"
input bool   inp_EnableNews1 = false;             // Ativar Bloqueio 1
input int    inp_News1StartH = 10;                // Bloqueio 1 - Hora Início
input int    inp_News1StartM = 0;                 // Bloqueio 1 - Minuto Início
input int    inp_News1EndH = 10;                  // Bloqueio 1 - Hora Fim
input int    inp_News1EndM = 15;                  // Bloqueio 1 - Minuto Fim

input bool   inp_EnableNews2 = false;             // Ativar Bloqueio 2
input int    inp_News2StartH = 14;                // Bloqueio 2 - Hora Início
input int    inp_News2StartM = 0;                 // Bloqueio 2 - Minuto Início
input int    inp_News2EndH = 14;                  // Bloqueio 2 - Hora Fim
input int    inp_News2EndM = 15;                  // Bloqueio 2 - Minuto Fim

input bool   inp_EnableNews3 = false;             // Ativar Bloqueio 3
input int    inp_News3StartH = 15;                // Bloqueio 3 - Hora Início
input int    inp_News3StartM = 0;                 // Bloqueio 3 - Minuto Início
input int    inp_News3EndH = 15;                  // Bloqueio 3 - Hora Fim
input int    inp_News3EndM = 5;                   // Bloqueio 3 - Minuto Fim

//--- 📊 SPREAD
input group "📊 Controle de Spread"
input int    inp_MaxSpread = 0;                   // Spread Máximo (0=ilimitado)

//--- 📅 LIMITES DIÁRIOS
input group "📅 Limites Diários"
input bool   inp_EnableDailyLimits = false;       // Ativar Limites Diários
input int    inp_MaxDailyTrades = 0;              // Máximo de Trades/Dia (0=ilimitado)
input double inp_MaxDailyLoss = 0;                // Perda Máxima/Dia (0=ilimitado)
input double inp_MaxDailyGain = 0;                // Ganho Máximo/Dia (0=ilimitado)
input ENUM_PROFIT_TARGET_ACTION inp_ProfitTargetAction = PROFIT_ACTION_STOP;  // Ação ao Atingir Meta

//--- 🔴 CONTROLE DE SEQUÊNCIA (STREAK)
input group "🔴 Controle de Sequência (Streak)"
input bool   inp_EnableStreakControl = false;     // Ativar Controle de Streak
input int    inp_MaxLossStreak = 0;               // Máx. Perdas Consecutivas (0=ilimitado)
input ENUM_STREAK_ACTION inp_LossStreakAction = STREAK_PAUSE;  // Ação - Loss Streak
input int    inp_LossPauseMinutes = 30;           // Minutos de Pausa (Loss Streak)
input int    inp_MaxWinStreak = 0;                // Máx. Ganhos Consecutivos (0=ilimitado)
input ENUM_STREAK_ACTION inp_WinStreakAction = STREAK_STOP_DAY;  // Ação - Win Streak
input int    inp_WinPauseMinutes = 0;             // Minutos de Pausa (Win Streak)

//--- 📉 PROTEÇÃO DE DRAWDOWN
input group "📉 Proteção de Drawdown"
input bool   inp_EnableDrawdown = false;          // Ativar Proteção Drawdown
input ENUM_DRAWDOWN_TYPE inp_DrawdownType = DD_FINANCIAL;  // Tipo de Drawdown
input double inp_DrawdownValue = 0;               // Valor do Drawdown
input ENUM_DRAWDOWN_PEAK_MODE inp_DrawdownPeakMode = DD_PEAK_REALIZED_ONLY;  // Modo de Cálculo do Pico

//--- 🎯 DIREÇÃO PERMITIDA
input group "🎯 Direção Permitida"
input ENUM_TRADE_DIRECTION inp_TradeDirection = DIRECTION_BOTH;  // Direção de Trading

//+------------------------------------------------------------------+
//| SEÇÃO 003 - RISK MANAGER                                         |
//+------------------------------------------------------------------+
input group "═══════════════ 💰 RISK MANAGER ═══════════════"

//--- ⚙️ CONFIGURAÇÕES GLOBAIS
input group "⚙️ Configurações Globais (Risk Manager)"
input int    inp_ATRPeriod = 14;                  // Período do ATR
input int    inp_Slippage = 10;                   // Slippage (pontos)

//--- 📊 TAMANHO DO LOTE
input group "📊 Tamanho do Lote"
input double inp_LotSize = 0.01;                  // Tamanho do Lote

//--- 🛑 STOP LOSS
input group "🛑 Stop Loss"
input ENUM_SL_TYPE inp_SLType = SL_FIXED;         // Tipo de Stop Loss
input int    inp_FixedSL = 100;                   // SL Fixo (pontos)
input double inp_SL_ATRMultiplier = 2.0;          // Multiplicador ATR (SL)
input int    inp_RangePeriod = 20;                // Período Range (SL)
input double inp_RangeMultiplier = 1.5;           // Multiplicador Range (SL)
input bool   inp_SL_CompensateSpread = false;     // Compensar Spread no SL

//--- 🎯 TAKE PROFIT
input group "🎯 Take Profit"
input ENUM_TP_TYPE inp_TPType = TP_FIXED;         // Tipo de Take Profit
input int    inp_FixedTP = 200;                   // TP Fixo (pontos)
input double inp_TP_ATRMultiplier = 5.0;          // Multiplicador ATR (TP)
input bool   inp_TP_CompensateSpread = false;     // Compensar Spread no TP

//--- 🎯 PARTIAL TAKE PROFIT (v1.01 - NOVO!)
input group "🎯 Partial Take Profit"
input bool   inp_UsePartialTP = false;            // Ativar Partial TP
input double inp_PartialTP1_Percent = 50.0;       // TP1: % do Volume
input int    inp_PartialTP1_Distance = 100;       // TP1: Distância (pontos)
input double inp_PartialTP2_Percent = 30.0;       // TP2: % do Volume
input int    inp_PartialTP2_Distance = 200;       // TP2: Distância (pontos)

//--- 🔄 TRAILING STOP
input group "🔄 Trailing Stop"
input ENUM_TRAILING_ACTIVATION inp_TrailingActivation = TRAILING_ALWAYS;  // Ativar Trailing
input ENUM_TRAILING_TYPE inp_TrailingType = TRAILING_FIXED;  // Tipo de Trailing
input int    inp_TrailingStart = 50;              // Início Trailing (pontos)
input int    inp_TrailingStep = 30;               // Step Trailing (pontos)
input double inp_TrailingATRStart = 0.5;          // Início Trailing (ATR)
input double inp_TrailingATRStep = 1.0;           // Step Trailing (ATR)
input bool   inp_Trailing_CompensateSpread = false;  // Compensar Spread no Trailing

//--- ⚖️ BREAKEVEN
input group "⚖️ Breakeven"
input ENUM_BE_ACTIVATION inp_BEActivationMode = BE_ALWAYS;                // Ativar Breakeven
input ENUM_BE_TYPE inp_BEType = BE_FIXED;         // Tipo de Breakeven
input int    inp_BEActivation = 50;               // Ativação BE (pontos)
input int    inp_BEOffset = 5;                    // Offset BE (pontos)
input double inp_BE_ATRActivation = 0.5;          // Ativação BE (ATR)
input double inp_BE_ATROffset = 0.05;             // Offset BE (ATR)

//+------------------------------------------------------------------+
//| SEÇÃO 004 - SIGNAL MANAGER                                       |
//+------------------------------------------------------------------+
input group "═══════════════ 📊 SIGNAL MANAGER ═══════════════"
input ENUM_CONFLICT_RESOLUTION inp_ConflictMode = CONFLICT_PRIORITY;  // Modo de Resolução de Conflitos

//+------------------------------------------------------------------+
//| SEÇÃO 005 - STRATEGIES                                           |
//+------------------------------------------------------------------+
input group "═══════════════ 📈 STRATEGIES ═══════════════"

//--- 📊 MA CROSS STRATEGY
input group "📊 MA Cross Strategy"
input bool   inp_UseMACross = true;                     // Ativar MA Cross Strategy
input int    inp_MACrossPriority = 10;                  // Prioridade MA Cross
input int    inp_FastPeriod = 9;                        // Período MA Rápida
input ENUM_MA_METHOD inp_FastMethod = MODE_EMA;         // Método MA Rápida
input ENUM_APPLIED_PRICE inp_FastApplied = PRICE_CLOSE; // Preço MA Rápida
input ENUM_TIMEFRAMES inp_FastTF = PERIOD_CURRENT;      // Timeframe MA Rápida
input int    inp_SlowPeriod = 21;                       // Período MA Lenta
input ENUM_MA_METHOD inp_SlowMethod = MODE_EMA;         // Método MA Lenta
input ENUM_APPLIED_PRICE inp_SlowApplied = PRICE_CLOSE; // Preço MA Lenta
input ENUM_TIMEFRAMES inp_SlowTF = PERIOD_CURRENT;      // Timeframe MA Lenta
input int    inp_MACrossMinDistance = 0;                // Distância Mínima entre MAs (0=desativado)
input ENUM_ENTRY_MODE inp_EntryMode = ENTRY_NEXT_CANDLE; // Modo de Entrada
input ENUM_EXIT_MODE inp_ExitMode = EXIT_TP_SL;       // Modo de Saída

//--- 📉 RSI STRATEGY
input group "📉 RSI Strategy"
input bool   inp_UseRSI = false;                        // Ativar RSI Strategy
input int    inp_RSIPriority = 5;                       // Prioridade RSI
input int    inp_RSIPeriod = 14;                        // Período RSI
input ENUM_APPLIED_PRICE inp_RSIApplied = PRICE_CLOSE;  // Preço RSI
input ENUM_TIMEFRAMES inp_RSITF = PERIOD_CURRENT;       // Timeframe RSI
input int    inp_RSIOversold = 30;                      // Nível Oversold (Sobrevendido)
input int    inp_RSIOverbought = 70;                    // Nível Overbought (Sobrecomprado)
input ENUM_RSI_SIGNAL_MODE inp_RSIMode = RSI_MODE_CROSSOVER;  // Modo de Operação RSI
input int    inp_RSIMidLevel = 50;                      // Nível Médio (para modo Crossover/Middle)
// inp_RSISignalShift removido (v1.07): sempre usa shift=1 (última barra fechada)

//--- 📊 BOLLINGER BANDS STRATEGY
input group "📊 Bollinger Bands Strategy"
input bool   inp_UseBB = false;                              // Ativar BB Strategy
input int    inp_BBPriority = 3;                             // Prioridade BB
input int    inp_BBPeriod = 20;                              // Período BB
input double inp_BBDeviation = 2.0;                          // Desvio Padrão BB
input ENUM_APPLIED_PRICE inp_BBApplied = PRICE_CLOSE;        // Preço Aplicado BB
input ENUM_TIMEFRAMES inp_BBTF = PERIOD_CURRENT;             // Timeframe BB
input ENUM_BB_SIGNAL_MODE inp_BBMode = BB_MODE_FFFD;         // Modo de Operação BB
input ENUM_ENTRY_MODE inp_BBEntryMode = ENTRY_NEXT_CANDLE;   // Modo de Entrada BB
input ENUM_EXIT_MODE inp_BBExitMode = EXIT_TP_SL;            // Modo de Saída BB

//+------------------------------------------------------------------+
//| SEÇÃO 006 - FILTERS                                              |
//+------------------------------------------------------------------+
input group "═══════════════ 🔍 FILTERS ═══════════════"

//--- 📊 TREND FILTER (Filtro de Tendência)
input group "📊 Trend Filter"
input bool   inp_UseTrendFilter = false;                // Ativar Trend Filter
input int    inp_TrendMAPeriod = 50;                    // Período MA Tendência
input ENUM_MA_METHOD inp_TrendMAMethod = MODE_SMA;      // Método MA Tendência
input ENUM_APPLIED_PRICE inp_TrendMAApplied = PRICE_CLOSE; // Preço MA Tendência
input ENUM_TIMEFRAMES inp_TrendMATF = PERIOD_CURRENT;   // Timeframe MA Tendência
input int    inp_TrendMinDistance = 0;                  // Distância Mínima do Preço à MA (0=desativado)

//--- 📉 RSI FILTER (Filtro RSI)
input group "📉 RSI Filter"
input bool   inp_UseRSIFilter = false;                  // Ativar RSI Filter
input int    inp_RSIFilterPeriod = 14;                  // Período RSI (Filter)
input ENUM_APPLIED_PRICE inp_RSIFilterApplied = PRICE_CLOSE; // Preço RSI (Filter)
input ENUM_TIMEFRAMES inp_RSIFilterTF = PERIOD_CURRENT; // Timeframe RSI (Filter)
input ENUM_RSI_FILTER_MODE inp_RSIFilterMode = RSI_FILTER_ZONE;  // Modo do Filtro RSI
input int    inp_RSIFilterOversold = 30;                // Nível Oversold (Filter)
input int    inp_RSIFilterOverbought = 70;              // Nível Overbought (Filter)
input double inp_RSIFilterLowerNeutral = 40;            // Limite Inferior Zona Neutra
input double inp_RSIFilterUpperNeutral = 60;            // Limite Superior Zona Neutra
input int    inp_RSIFilterShift = 1;                    // Shift do Filtro RSI (0=barra atual, 1=barra fechada)

//--- 📊 BB FILTER (Filtro Bollinger Bands - Anti-Squeeze)
input group "📊 BB Filter (Anti-Squeeze)"
input bool   inp_UseBBFilter = false;                        // Ativar BB Filter
input int    inp_BBFiltPeriod = 20;                          // Período BB (Filter)
input double inp_BBFiltDeviation = 2.0;                      // Desvio Padrão BB (Filter)
input ENUM_APPLIED_PRICE inp_BBFiltApplied = PRICE_CLOSE;    // Preço BB (Filter)
input ENUM_TIMEFRAMES inp_BBFiltTF = PERIOD_CURRENT;         // Timeframe BB (Filter)
input ENUM_BB_SQUEEZE_METRIC inp_BBFiltMetric = BB_SQUEEZE_RELATIVE; // Métrica Anti-Squeeze
input double inp_BBFiltThreshold = 1.0;                      // Threshold Squeeze (depende da métrica)
input int    inp_BBFiltPercPeriod = 50;                      // Período Percentil (só modo Percentil)

//+------------------------------------------------------------------+
//| SEÇÃO 008 - PAINEL GUI                                            |
//+------------------------------------------------------------------+
input group "═══════════════ 🖥️ PAINEL GUI ═══════════════"
input bool inp_ShowPanel = true;                     // Mostrar Painel no Gráfico

//+------------------------------------------------------------------+
//| FIM DO ARQUIVO DE INPUTS v1.09                                   |
//+------------------------------------------------------------------+
