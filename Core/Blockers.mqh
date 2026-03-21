//+------------------------------------------------------------------+
//|                                                     Blockers.mqh |
//|                                         Copyright 2026, EP Filho |
//|                              Sistema de Bloqueios - EPBot Matrix |
//|                     Versão 3.24 - Claude Parte 027 (Claude Code) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "3.24"
#property strict

// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.24 (Parte 027):
// + SetMagicNumber() — facade para BlockerFilters.SetMagicNumber()
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.23 (Parte 025):
// + Refatoração: CBlockers dividido em 3 módulos coesos:
//   - BlockerFilters.mqh: TimeFilter + NewsFilter + SpreadFilter
//   - BlockerDrawdown.mqh: DrawdownProtection
//   - BlockerLimits.mqh: DailyLimits + StreakControl
// + CBlockers passa a ser orchestrator — API pública inalterada
// + Statics locais em CanTrade/ShouldClose* convertidas em membros
//   de instância nas classes correspondentes (sem side effects)
// + CheckDailyLimits: dependência cruzada com DrawdownProtection
//   eliminada via flag activateDD (out param) — sem circular deps
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.22 (Parte 025):
// + CanTrade(): DailyLimits verificado ANTES do Streak
//   Diagnóstico correto quando ambos bloqueiam simultaneamente
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.21 (Parte 024):
// + Getters públicos para GUI RESULTADOS:
//   DD: GetDrawdownType(), GetDrawdownValue(), GetDrawdownPeakMode()
//   Streak: IsStreakControlEnabled(), GetMaxLossStreak(), GetMaxWinStreak(),
//   GetLossStreakAction(), GetWinStreakAction(), GetLoss/WinPauseMinutes()
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.20 (Parte 024):
// ✅ Fix: CheckDrawdownLimit() usa m_logger.GetDailyProfit() + floating
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.19 (Parte 024):
// + TryActivateDrawdownNow(dailyProfit)
// ✅ Fix: GetCurrentDrawdown() inclui floating
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════
#include "Logger.mqh"

//+------------------------------------------------------------------+
//| Enumerações (definidas AQUI, antes dos includes dos submodules)  |
//| São usadas pelo EA, GUI e pelos submodules incluídos abaixo.     |
//+------------------------------------------------------------------+

// Tipo de direção permitida
enum ENUM_TRADE_DIRECTION
  {
   DIRECTION_BOTH,      // Ambos (Compra e Venda)
   DIRECTION_BUY_ONLY,  // Apenas Compras
   DIRECTION_SELL_ONLY  // Apenas Vendas
  };

// Ação após atingir streak
enum ENUM_STREAK_ACTION
  {
   STREAK_PAUSE,      // Pausar por X minutos e depois retomar
   STREAK_STOP_DAY    // Parar de operar até o fim do dia (Horário da CORRETORA)
  };

// Ação ao atingir meta de lucro
enum ENUM_PROFIT_TARGET_ACTION
  {
   PROFIT_ACTION_STOP,              // Parar de operar
   PROFIT_ACTION_ENABLE_DRAWDOWN    // Ativar Proteção de Drawdown
  };

// Tipo de drawdown
enum ENUM_DRAWDOWN_TYPE
  {
   DD_FINANCIAL,    // Financeiro (valor fixo)
   DD_PERCENTAGE    // Percentual (% do lucro conquistado)
  };

// Modo de cálculo do pico de drawdown
enum ENUM_DRAWDOWN_PEAK_MODE
  {
   DD_PEAK_REALIZED_ONLY = 0,     // Apenas Lucro Realizado (Fechados)
   DD_PEAK_INCLUDE_FLOATING = 1   // Incluir P/L Flutuante
  };

// Razão do bloqueio (para debug/log)
enum ENUM_BLOCKER_REASON
  {
   BLOCKER_NONE = 0,              // Sem bloqueio
   BLOCKER_TIME_FILTER,           // Fora do horário permitido
   BLOCKER_NEWS_FILTER,           // Horário de volatilidade
   BLOCKER_SPREAD,                // Spread alto
   BLOCKER_DAILY_TRADES,          // Limite de trades diários atingido
   BLOCKER_DAILY_LOSS,            // Perda diária máxima atingida
   BLOCKER_DAILY_GAIN,            // Ganho diário máximo atingido
   BLOCKER_LOSS_STREAK,           // Sequência de perdas excedida
   BLOCKER_WIN_STREAK,            // Sequência de ganhos excedida
   BLOCKER_DRAWDOWN,              // Drawdown máximo atingido
   BLOCKER_DIRECTION              // Direção não permitida
  };

// Estados de sessão para logging inteligente
enum ENUM_SESSION_STATE
  {
   SESSION_BEFORE,       // Antes da sessão iniciar
   SESSION_ACTIVE,       // Sessão ativa (operação normal)
   SESSION_PROTECTION,   // Janela de proteção (X min antes do fim)
   SESSION_AFTER         // Após encerramento da sessão
  };

// ═══════════════════════════════════════════════════════════════
// SUBMODULES (incluídos após os enums — podem usar todos os tipos acima)
// ═══════════════════════════════════════════════════════════════
#include "BlockerFilters.mqh"
#include "BlockerDrawdown.mqh"
#include "BlockerLimits.mqh"

//+------------------------------------------------------------------+
//| Classe: CBlockers                                                |
//| Orchestrator — agrega CBlockerFilters, CBlockerDrawdown,        |
//| CBlockerLimits e mantém API pública 100% compatível.            |
//+------------------------------------------------------------------+
class CBlockers
  {
private:
   // ═══════════════════════════════════════════════════════════════
   // SUBMODULES
   // ═══════════════════════════════════════════════════════════════
   CBlockerFilters   m_filters;
   CBlockerDrawdown  m_drawdown;
   CBlockerLimits    m_limits;

   // ═══════════════════════════════════════════════════════════════
   // ESTADO PRÓPRIO DO ORCHESTRATOR
   // ═══════════════════════════════════════════════════════════════
   CLogger*          m_logger;
   int               m_magicNumber;

   // TradeDirection (simples demais para módulo próprio)
   ENUM_TRADE_DIRECTION m_inputTradeDirection;
   ENUM_TRADE_DIRECTION m_tradeDirection;

   // Estado de controle diário
   datetime          m_lastResetDate;
   ENUM_BLOCKER_REASON m_currentBlocker;

   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS
   // ═══════════════════════════════════════════════════════════════
   bool              IsNewDay();
   bool              CheckDirectionAllowed(int orderType);
   string            GetBlockerReasonText(ENUM_BLOCKER_REASON reason);

public:
   // ═══════════════════════════════════════════════════════════════
   // CONSTRUTOR E INICIALIZAÇÃO
   // ═══════════════════════════════════════════════════════════════
                     CBlockers();
                    ~CBlockers();

   bool              Init(
      CLogger* logger,
      int magicNumber,
      // Horário
      bool enableTime, int startH, int startM, int endH, int endM, bool closeOnEnd, bool closeBeforeSessionEnd, int minutesBeforeSessionEnd,
      // News (3 bloqueios)
      bool news1, int n1StartH, int n1StartM, int n1EndH, int n1EndM,
      bool news2, int n2StartH, int n2StartM, int n2EndH, int n2EndM,
      bool news3, int n3StartH, int n3StartM, int n3EndH, int n3EndM,
      // Spread
      int maxSpread,
      // Limites diários
      bool enableLimits, int maxTrades, double maxLoss, double maxGain,
      ENUM_PROFIT_TARGET_ACTION profitAction,
      // Streak
      bool enableStreak,
      int maxLossStreak, ENUM_STREAK_ACTION lossAction, int lossPauseMin,
      int maxWinStreak, ENUM_STREAK_ACTION winAction, int winPauseMin,
      // Drawdown
      bool enableDD, ENUM_DRAWDOWN_TYPE ddType, double ddValue, ENUM_DRAWDOWN_PEAK_MODE ddPeakMode,
      // Direção
      ENUM_TRADE_DIRECTION tradeDirection
   );

   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS PRINCIPAIS
   // ═══════════════════════════════════════════════════════════════
   bool              CanTrade(int dailyTrades, double dailyProfit, string &blockReason);
   bool              CanTradeDirection(int orderType, string &blockReason);
   bool              ShouldCloseOnEndTime(ulong positionTicket);
   bool              ShouldCloseBeforeSessionEnd(ulong positionTicket);
   bool              ShouldCloseByDailyLimit(ulong positionTicket, double dailyProfit, string &closeReason);
   bool              ShouldCloseByDrawdown(ulong positionTicket, double dailyProfit, string &closeReason);

   // ═══════════════════════════════════════════════════════════════
   // ATUALIZAÇÃO DE ESTADO
   // ═══════════════════════════════════════════════════════════════
   void              UpdateAfterTrade(bool isWin, double tradeProfit);
   void              UpdatePeakBalance(double currentBalance);
   void              UpdatePeakProfit(double currentProfit);
   void              ActivateDrawdownProtection(double closedProfit, double projectedProfit);
   void              ResetDaily();

   // ═══════════════════════════════════════════════════════════════
   // HOT RELOAD
   // ═══════════════════════════════════════════════════════════════
   void              SetMaxSpread(int newMaxSpread);
   void              SetTradeDirection(ENUM_TRADE_DIRECTION newDirection);
   void              SetDailyLimits(int maxTrades, double maxLoss, double maxGain, ENUM_PROFIT_TARGET_ACTION action);
   void              SetStreakLimits(int maxLoss, ENUM_STREAK_ACTION lossAction, int lossPause,
                                     int maxWin, ENUM_STREAK_ACTION winAction, int winPause);
   void              SetDrawdownValue(double newValue);
   void              SetDrawdownType(ENUM_DRAWDOWN_TYPE newType);
   void              SetDrawdownPeakMode(ENUM_DRAWDOWN_PEAK_MODE newMode);
   void              TryActivateDrawdownNow(double dailyProfit);
   void              SetTimeFilter(bool enable, int startH, int startM, int endH, int endM);
   void              SetCloseOnEndTime(bool close);
   void              SetCloseBeforeSessionEnd(bool close, int minutes);
   void              SetNewsFilter(int window, bool enable, int startH, int startM, int endH, int endM);
   void              SetMagicNumber(int newMagic);

   // ═══════════════════════════════════════════════════════════════
   // GETTERS — ESTADO
   // ═══════════════════════════════════════════════════════════════
   int               GetCurrentLossStreak() const { return m_limits.GetCurrentLossStreak(); }
   int               GetCurrentWinStreak()  const { return m_limits.GetCurrentWinStreak(); }
   double            GetCurrentDrawdown()         { return m_drawdown.GetCurrentDrawdown(); }
   double            GetDailyPeakProfit() const   { return m_drawdown.GetDailyPeakProfit(); }
   bool              IsDrawdownProtectionActive() const { return m_drawdown.IsDrawdownProtectionActive(); }
   bool              IsDrawdownLimitReached() const    { return m_drawdown.IsDrawdownLimitReached(); }
   ENUM_DRAWDOWN_TYPE      GetDrawdownType() const     { return m_drawdown.GetDrawdownType(); }
   double                  GetDrawdownValue() const    { return m_drawdown.GetDrawdownValue(); }
   ENUM_DRAWDOWN_PEAK_MODE GetDrawdownPeakMode() const { return m_drawdown.GetDrawdownPeakMode(); }
   ENUM_BLOCKER_REASON GetActiveBlocker() const        { return m_currentBlocker; }
   bool              IsBlocked() const                 { return m_currentBlocker != BLOCKER_NONE; }
   bool              IsStreakControlEnabled() const    { return m_limits.IsStreakControlEnabled(); }
   bool              IsStreakPaused() const            { return m_limits.IsStreakPaused(); }
   datetime          GetStreakPauseUntil() const       { return m_limits.GetStreakPauseUntil(); }
   string            GetStreakPauseReason() const      { return m_limits.GetStreakPauseReason(); }
   int               GetMaxLossStreak() const          { return m_limits.GetMaxLossStreak(); }
   int               GetMaxWinStreak() const           { return m_limits.GetMaxWinStreak(); }
   ENUM_STREAK_ACTION GetLossStreakAction() const      { return m_limits.GetLossStreakAction(); }
   ENUM_STREAK_ACTION GetWinStreakAction() const       { return m_limits.GetWinStreakAction(); }
   int               GetLossPauseMinutes() const      { return m_limits.GetLossPauseMinutes(); }
   int               GetWinPauseMinutes() const       { return m_limits.GetWinPauseMinutes(); }

   // ═══════════════════════════════════════════════════════════════
   // GETTERS — CONFIGURAÇÃO
   // ═══════════════════════════════════════════════════════════════
   int               GetMaxSpread() const       { return m_filters.GetMaxSpread(); }
   ENUM_TRADE_DIRECTION GetTradeDirection() const { return m_tradeDirection; }
   int               GetInputMaxSpread() const  { return m_filters.GetInputMaxSpread(); }
   ENUM_TRADE_DIRECTION GetInputTradeDirection() const { return m_inputTradeDirection; }

   // ═══════════════════════════════════════════════════════════════
   // DEBUG
   // ═══════════════════════════════════════════════════════════════
   void              PrintStatus();
   void              PrintConfiguration();
  };

//+------------------------------------------------------------------+
//| Construtor                                                       |
//+------------------------------------------------------------------+
CBlockers::CBlockers()
  {
   m_logger              = NULL;
   m_magicNumber         = 0;
   m_inputTradeDirection = DIRECTION_BOTH;
   m_tradeDirection      = DIRECTION_BOTH;
   m_lastResetDate       = TimeCurrent();
   m_currentBlocker      = BLOCKER_NONE;
  }

//+------------------------------------------------------------------+
//| Destrutor                                                        |
//+------------------------------------------------------------------+
CBlockers::~CBlockers()
  {
  }

//+------------------------------------------------------------------+
//| Inicialização                                                    |
//+------------------------------------------------------------------+
bool CBlockers::Init(
   CLogger* logger,
   int magicNumber,
   bool enableTime, int startH, int startM, int endH, int endM, bool closeOnEnd, bool closeBeforeSessionEnd, int minutesBeforeSessionEnd,
   bool news1, int n1StartH, int n1StartM, int n1EndH, int n1EndM,
   bool news2, int n2StartH, int n2StartM, int n2EndH, int n2EndM,
   bool news3, int n3StartH, int n3StartM, int n3EndH, int n3EndM,
   int maxSpread,
   bool enableLimits, int maxTrades, double maxLoss, double maxGain,
   ENUM_PROFIT_TARGET_ACTION profitAction,
   bool enableStreak,
   int maxLossStreak, ENUM_STREAK_ACTION lossAction, int lossPauseMin,
   int maxWinStreak, ENUM_STREAK_ACTION winAction, int winPauseMin,
   bool enableDD, ENUM_DRAWDOWN_TYPE ddType, double ddValue, ENUM_DRAWDOWN_PEAK_MODE ddPeakMode,
   ENUM_TRADE_DIRECTION tradeDirection
)
  {
   m_logger      = logger;
   m_magicNumber = magicNumber;

   if(m_logger != NULL)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "╔══════════════════════════════════════════════════════╗");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "║        EPBOT MATRIX - INICIALIZANDO BLOCKERS        ║");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "║              VERSÃO COMPLETA v3.23                   ║");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "╚══════════════════════════════════════════════════════╝");
     }
   else
     {
      Print("╔══════════════════════════════════════════════════════╗");
      Print("║        EPBOT MATRIX - INICIALIZANDO BLOCKERS        ║");
      Print("║              VERSÃO COMPLETA v3.23                   ║");
      Print("╚══════════════════════════════════════════════════════╝");
     }

// ── FILTROS (Horário + Notícias + Spread) ────────────────────────
   if(!m_filters.Init(logger, magicNumber,
                       enableTime, startH, startM, endH, endM, closeOnEnd, closeBeforeSessionEnd, minutesBeforeSessionEnd,
                       news1, n1StartH, n1StartM, n1EndH, n1EndM,
                       news2, n2StartH, n2StartM, n2EndH, n2EndM,
                       news3, n3StartH, n3StartM, n3EndH, n3EndM,
                       maxSpread))
      return false;

// ── LIMITES (DailyLimits + Streak) ──────────────────────────────
   if(!m_limits.Init(logger,
                      enableLimits, maxTrades, maxLoss, maxGain, profitAction,
                      enableStreak,
                      maxLossStreak, lossAction, lossPauseMin,
                      maxWinStreak, winAction, winPauseMin))
      return false;

// ── DRAWDOWN ─────────────────────────────────────────────────────
   if(!m_drawdown.Init(logger, magicNumber, enableDD, ddType, ddValue, ddPeakMode))
      return false;

// ── DIREÇÃO ──────────────────────────────────────────────────────
   m_inputTradeDirection = tradeDirection;
   m_tradeDirection      = tradeDirection;

   string dirText = "";
   switch(tradeDirection)
     {
      case DIRECTION_BOTH:      dirText = "Ambas (Compra e Venda)"; break;
      case DIRECTION_BUY_ONLY:  dirText = "Apenas COMPRAS";         break;
      case DIRECTION_SELL_ONLY: dirText = "Apenas VENDAS";          break;
     }
   string dirMsg = "🎯 Direção Permitida: " + dirText;
   if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", dirMsg); else Print(dirMsg);

// ── RESET ESTADO ─────────────────────────────────────────────────
   m_lastResetDate  = TimeCurrent();
   m_currentBlocker = BLOCKER_NONE;

   if(m_logger != NULL)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "✅ Blockers inicializados com sucesso!");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "");
     }
   else
     {
      Print("");
      Print("✅ Blockers inicializados com sucesso!");
      Print("");
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Verifica se pode operar (método principal)                       |
//+------------------------------------------------------------------+
bool CBlockers::CanTrade(int dailyTrades, double dailyProfit, string &blockReason)
  {
// Reset diário se necessário
   if(IsNewDay())
      ResetDaily();

// Limpar bloqueador anterior
   m_currentBlocker = BLOCKER_NONE;
   blockReason      = "";

// ── PROTEÇÃO DE SESSÃO ────────────────────────────────────────────
   if(!m_filters.CheckSessionBlocking(m_currentBlocker, blockReason))
      return false;

// ── FILTRO DE HORÁRIO ─────────────────────────────────────────────
   if(!m_filters.CheckTimeWithLog(m_currentBlocker, blockReason))
      return false;

// ── FILTRO DE NOTÍCIAS ────────────────────────────────────────────
   if(!m_filters.CheckNewsWithLog(m_currentBlocker, blockReason))
      return false;

// ── FILTRO DE SPREAD ──────────────────────────────────────────────
   if(!m_filters.CheckSpreadWithLog(m_currentBlocker, blockReason))
      return false;

// ── LIMITES DIÁRIOS (v3.22: antes do Streak para diagnóstico correto) ──
   bool activateDD = false;
   if(!m_limits.CheckDailyLimitsWithLog(dailyTrades, dailyProfit,
                                         m_currentBlocker, blockReason, activateDD))
      return false;

// ── STREAK ────────────────────────────────────────────────────────
   if(!m_limits.CheckStreakWithLog(m_currentBlocker, blockReason))
      return false;

// ── ATIVAR DRAWDOWN se profit target atingido com ação ENABLE_DD ──
   if(activateDD && !m_drawdown.IsDrawdownProtectionActive())
      m_drawdown.ActivateDrawdownProtection(dailyProfit, dailyProfit);

// ── DRAWDOWN ──────────────────────────────────────────────────────
   if(!m_drawdown.CheckDrawdownWithLog(m_currentBlocker, blockReason))
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Verifica se direção é permitida                                  |
//+------------------------------------------------------------------+
bool CBlockers::CanTradeDirection(int orderType, string &blockReason)
  {
   if(!CheckDirectionAllowed(orderType))
     {
      m_currentBlocker = BLOCKER_DIRECTION;
      if(orderType == ORDER_TYPE_BUY)
         blockReason = "Compras bloqueadas - Apenas VENDAS permitidas";
      else
         blockReason = "Vendas bloqueadas - Apenas COMPRAS permitidas";
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição por término de horário           |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseOnEndTime(ulong positionTicket)
  {
   return m_filters.ShouldCloseOnEndTime(positionTicket);
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição antes do fim da sessão           |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseBeforeSessionEnd(ulong positionTicket)
  {
   return m_filters.ShouldCloseBeforeSessionEnd(positionTicket);
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição por limite diário                |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseByDailyLimit(ulong positionTicket, double dailyProfit, string &closeReason)
  {
   bool   activateDD       = false;
   double activateDDClosed = 0;
   double activateDDProj   = 0;

   bool result = m_limits.ShouldCloseByDailyLimit(positionTicket, dailyProfit, closeReason,
                                                    activateDD, activateDDClosed, activateDDProj);

   if(activateDD && !m_drawdown.IsDrawdownProtectionActive())
      m_drawdown.ActivateDrawdownProtection(activateDDClosed, activateDDProj);

   return result;
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição por drawdown                     |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseByDrawdown(ulong positionTicket, double dailyProfit, string &closeReason)
  {
   return m_drawdown.ShouldCloseByDrawdown(positionTicket, dailyProfit, closeReason);
  }

//+------------------------------------------------------------------+
//| Atualiza estado após um trade                                    |
//+------------------------------------------------------------------+
void CBlockers::UpdateAfterTrade(bool isWin, double tradeProfit)
  {
   m_limits.UpdateAfterTrade(isWin, tradeProfit);
  }

//+------------------------------------------------------------------+
//| Atualiza pico de saldo                                           |
//+------------------------------------------------------------------+
void CBlockers::UpdatePeakBalance(double currentBalance)
  {
   m_drawdown.UpdatePeakBalance(currentBalance);
  }

//+------------------------------------------------------------------+
//| Atualiza pico de lucro diário                                    |
//+------------------------------------------------------------------+
void CBlockers::UpdatePeakProfit(double currentProfit)
  {
   m_drawdown.UpdatePeakProfit(currentProfit);
  }

//+------------------------------------------------------------------+
//| Ativa proteção de drawdown                                       |
//+------------------------------------------------------------------+
void CBlockers::ActivateDrawdownProtection(double closedProfit, double projectedProfit)
  {
   m_drawdown.ActivateDrawdownProtection(closedProfit, projectedProfit);
  }

//+------------------------------------------------------------------+
//| Reset diário                                                     |
//+------------------------------------------------------------------+
void CBlockers::ResetDaily()
  {
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "RESET", "🔄 RESET DIÁRIO - Limpando contadores...");
   else
      Print("🔄 RESET DIÁRIO - Limpando contadores...");

   m_limits.ResetDaily();
   m_drawdown.ResetDaily();
   m_currentBlocker = BLOCKER_NONE;
   m_lastResetDate  = TimeCurrent();

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "RESET", "✅ Contadores zerados!");
   else
      Print("✅ Contadores zerados!");
  }

//+------------------------------------------------------------------+
//| Hot Reload — Spread                                              |
//+------------------------------------------------------------------+
void CBlockers::SetMaxSpread(int newMaxSpread)
  {
   m_filters.SetMaxSpread(newMaxSpread);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Direção de trading                                  |
//+------------------------------------------------------------------+
void CBlockers::SetTradeDirection(ENUM_TRADE_DIRECTION newDirection)
  {
   ENUM_TRADE_DIRECTION oldDirection = m_tradeDirection;
   m_tradeDirection = newDirection;

   if(oldDirection != newDirection)
     {
      string oldText = "", newText = "";
      switch(oldDirection)
        {
         case DIRECTION_BOTH:      oldText = "AMBAS";          break;
         case DIRECTION_BUY_ONLY:  oldText = "APENAS COMPRAS"; break;
         case DIRECTION_SELL_ONLY: oldText = "APENAS VENDAS";  break;
        }
      switch(newDirection)
        {
         case DIRECTION_BOTH:      newText = "AMBAS";          break;
         case DIRECTION_BUY_ONLY:  newText = "APENAS COMPRAS"; break;
         case DIRECTION_SELL_ONLY: newText = "APENAS VENDAS";  break;
        }
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("Direção alterada: %s → %s", oldText, newText));
      else
         Print("🔄 Direção alterada: ", oldText, " → ", newText);
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload — Limites diários                                     |
//+------------------------------------------------------------------+
void CBlockers::SetDailyLimits(int maxTrades, double maxLoss, double maxGain, ENUM_PROFIT_TARGET_ACTION action)
  {
   m_limits.SetDailyLimits(maxTrades, maxLoss, maxGain, action);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Streak                                              |
//+------------------------------------------------------------------+
void CBlockers::SetStreakLimits(int maxLoss, ENUM_STREAK_ACTION lossAction, int lossPause,
                                 int maxWin, ENUM_STREAK_ACTION winAction, int winPause)
  {
   m_limits.SetStreakLimits(maxLoss, lossAction, lossPause, maxWin, winAction, winPause);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Drawdown value                                      |
//+------------------------------------------------------------------+
void CBlockers::SetDrawdownValue(double newValue)
  {
   m_drawdown.SetDrawdownValue(newValue);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Drawdown type                                       |
//+------------------------------------------------------------------+
void CBlockers::SetDrawdownType(ENUM_DRAWDOWN_TYPE newType)
  {
   m_drawdown.SetDrawdownType(newType);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Drawdown peak mode                                  |
//+------------------------------------------------------------------+
void CBlockers::SetDrawdownPeakMode(ENUM_DRAWDOWN_PEAK_MODE newMode)
  {
   m_drawdown.SetDrawdownPeakMode(newMode);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Ativa DD imediatamente (fix hot reload)             |
//+------------------------------------------------------------------+
void CBlockers::TryActivateDrawdownNow(double dailyProfit)
  {
   m_drawdown.TryActivateDrawdownNow(dailyProfit);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Magic Number                                        |
//+------------------------------------------------------------------+
void CBlockers::SetMagicNumber(int newMagic)
  {
   m_filters.SetMagicNumber(newMagic);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Filtro de horário                                   |
//+------------------------------------------------------------------+
void CBlockers::SetTimeFilter(bool enable, int startH, int startM, int endH, int endM)
  {
   m_filters.SetTimeFilter(enable, startH, startM, endH, endM);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Fechar ao fim do horário                            |
//+------------------------------------------------------------------+
void CBlockers::SetCloseOnEndTime(bool close)
  {
   m_filters.SetCloseOnEndTime(close);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Fechar antes do fim da sessão                       |
//+------------------------------------------------------------------+
void CBlockers::SetCloseBeforeSessionEnd(bool close, int minutes)
  {
   m_filters.SetCloseBeforeSessionEnd(close, minutes);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Filtro de notícias                                  |
//+------------------------------------------------------------------+
void CBlockers::SetNewsFilter(int window, bool enable, int startH, int startM, int endH, int endM)
  {
   m_filters.SetNewsFilter(window, enable, startH, startM, endH, endM);
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica se é novo dia                                  |
//+------------------------------------------------------------------+
bool CBlockers::IsNewDay()
  {
   datetime now = TimeCurrent();
   MqlDateTime lastDate, currentDate;
   TimeToStruct(m_lastResetDate, lastDate);
   TimeToStruct(now, currentDate);
   return (lastDate.year != currentDate.year ||
           lastDate.mon  != currentDate.mon  ||
           lastDate.day  != currentDate.day);
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica se direção é permitida                         |
//+------------------------------------------------------------------+
bool CBlockers::CheckDirectionAllowed(int orderType)
  {
   if(m_tradeDirection == DIRECTION_BOTH) return true;
   if(m_tradeDirection == DIRECTION_BUY_ONLY  && orderType == ORDER_TYPE_SELL) return false;
   if(m_tradeDirection == DIRECTION_SELL_ONLY && orderType == ORDER_TYPE_BUY)  return false;
   return true;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Converte enum de bloqueio em texto                      |
//+------------------------------------------------------------------+
string CBlockers::GetBlockerReasonText(ENUM_BLOCKER_REASON reason)
  {
   switch(reason)
     {
      case BLOCKER_NONE:         return "Sem bloqueio";
      case BLOCKER_TIME_FILTER:  return "Fora do horário";
      case BLOCKER_NEWS_FILTER:  return "Horário de volatilidade";
      case BLOCKER_SPREAD:       return "Spread alto";
      case BLOCKER_DAILY_TRADES: return "Limite de trades diários";
      case BLOCKER_DAILY_LOSS:   return "Perda diária máxima";
      case BLOCKER_DAILY_GAIN:   return "Ganho diário máximo";
      case BLOCKER_LOSS_STREAK:  return "Sequência de perdas";
      case BLOCKER_WIN_STREAK:   return "Sequência de ganhos";
      case BLOCKER_DRAWDOWN:     return "Drawdown máximo";
      case BLOCKER_DIRECTION:    return "Direção bloqueada";
      default:                   return "Bloqueio desconhecido";
     }
  }

//+------------------------------------------------------------------+
//| Imprime status atual                                             |
//+------------------------------------------------------------------+
void CBlockers::PrintStatus()
  {
   if(m_logger != NULL)
     {
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "╔══════════════════════════════════════════════════════╗");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "║            BLOCKERS - STATUS ATUAL                   ║");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "╚══════════════════════════════════════════════════════╝");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "");
     }
   else
     {
      Print("╔══════════════════════════════════════════════════════╗");
      Print("║            BLOCKERS - STATUS ATUAL                   ║");
      Print("╚══════════════════════════════════════════════════════╝");
      Print("");
     }

   string statusMsg = (m_currentBlocker != BLOCKER_NONE)
      ? "🚫 BLOQUEADO: " + GetBlockerReasonText(m_currentBlocker)
      : "✅ LIBERADO PARA OPERAR";
   if(m_logger != NULL) m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", statusMsg);
   else Print(statusMsg);

   if(m_limits.IsStreakControlEnabled())
     {
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "");
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "🔴 Streaks:");
         if(m_limits.GetMaxLossStreak() > 0)
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS",
               "   Loss: " + IntegerToString(m_limits.GetCurrentLossStreak()) +
               " de " + IntegerToString(m_limits.GetMaxLossStreak()));
         if(m_limits.GetMaxWinStreak() > 0)
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS",
               "   Win: " + IntegerToString(m_limits.GetCurrentWinStreak()) +
               " de " + IntegerToString(m_limits.GetMaxWinStreak()));
         if(m_limits.IsStreakPaused())
           {
            int remaining = (int)((m_limits.GetStreakPauseUntil() - TimeCurrent()) / 60);
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS",
               "   ⏸️ PAUSADO: " + m_limits.GetStreakPauseReason() +
               " (" + IntegerToString(remaining) + " min)");
           }
        }
      else
        {
         Print("");
         Print("🔴 Streaks:");
         if(m_limits.GetMaxLossStreak() > 0)
            Print("   Loss: ", m_limits.GetCurrentLossStreak(), " de ", m_limits.GetMaxLossStreak());
         if(m_limits.GetMaxWinStreak() > 0)
            Print("   Win: ", m_limits.GetCurrentWinStreak(), " de ", m_limits.GetMaxWinStreak());
         if(m_limits.IsStreakPaused())
           {
            int remaining = (int)((m_limits.GetStreakPauseUntil() - TimeCurrent()) / 60);
            Print("   ⏸️ PAUSADO: ", m_limits.GetStreakPauseReason(), " (", remaining, " min)");
           }
        }
     }

   if(m_drawdown.IsDrawdownProtectionActive())
     {
      double currentDD = m_drawdown.GetCurrentDrawdown();
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "");
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "📉 Drawdown (proteção ativa):");
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "   Pico: $" + DoubleToString(m_drawdown.GetDailyPeakProfit(), 2));
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "   DD atual: " + DoubleToString(currentDD, 2));
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS",
            "   Status: " + (m_drawdown.IsDrawdownLimitReached() ? "❌ LIMITE ATINGIDO" : "✅ OK"));
        }
      else
        {
         Print("");
         Print("📉 Drawdown (proteção ativa):");
         Print("   Pico: $", DoubleToString(m_drawdown.GetDailyPeakProfit(), 2));
         Print("   DD atual: ", DoubleToString(currentDD, 2));
         Print("   Status: ", m_drawdown.IsDrawdownLimitReached() ? "❌ LIMITE ATINGIDO" : "✅ OK");
        }
     }

   if(m_logger != NULL)
     {
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "═══════════════════════════════════════════════════════");
     }
   else
     {
      Print("");
      Print("═══════════════════════════════════════════════════════");
     }
  }

//+------------------------------------------------------------------+
//| Imprime configuração completa                                    |
//+------------------------------------------------------------------+
void CBlockers::PrintConfiguration()
  {
   if(m_logger != NULL)
     {
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "╔══════════════════════════════════════════════════════╗");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "║         BLOCKERS - CONFIGURAÇÃO COMPLETA            ║");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "╚══════════════════════════════════════════════════════╝");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "   Spread Máx: " + IntegerToString(m_filters.GetMaxSpread()));
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "   Direção: " + IntegerToString((int)m_tradeDirection));
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "═══════════════════════════════════════════════════════");
     }
   else
     {
      Print("╔══════════════════════════════════════════════════════╗");
      Print("║         BLOCKERS - CONFIGURAÇÃO COMPLETA            ║");
      Print("╚══════════════════════════════════════════════════════╝");
      Print("");
      Print("   Spread Máx: ", m_filters.GetMaxSpread());
      Print("   Direção: ", (int)m_tradeDirection);
      Print("");
      Print("═══════════════════════════════════════════════════════");
     }
  }

//+------------------------------------------------------------------+
