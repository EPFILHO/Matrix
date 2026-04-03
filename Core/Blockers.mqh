//+------------------------------------------------------------------+
//|                                                  Blockers.mqh    |
//|                                      Copyright 2026, EP Filho    |
//|                    Sistema de Bloqueios - EPBot Matrix           |
//|                Versao 3.26 - PrintConfiguration() completa      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "3.26"
#property strict

//+------------------------------------------------------------------+
//| CHANGELOG v3.25 (Refatoração crítica):                           |
//| FIX 1 — IsNewDay()/ResetDaily() removidos de CanTrade().         |
//|          O EA principal é o único dono da lógica de virada de    |
//+------------------------------------------------------------------+
//| CHANGELOG v3.26:                                                 |
//| + PrintConfiguration() completada: delega para submodulos       |
//|   (m_filters, m_limits, m_drawdown) e exibe geral + spread +    |
//|   direcao de forma legivel (antes apenas inteiros)              |
//+------------------------------------------------------------------+
//|          dia. Duplo reset causava zeragem de streak no meio do    |
//|          dia e conflito de responsabilidades.                     |
//| FIX 2 — m_lastResetDate inicializado com D'1970.01.01' em vez    |
//|          de TimeCurrent() para evitar race condition quando EA    |
//|          inicia às 23:59 e primeiro tick vem às 00:01.           |
//|          IsNewDay() mantido apenas para uso interno seguro.       |
//| FIX 3 — SetMagicNumber() loga a reconstrução de streak para      |
//|          visibilidade do operador.                                |
//| FIX 4 — ResetDaily() documenta comportamento de m_tradeDirection  |
//|          (persiste entre dias por design — agora explícito).      |
//+------------------------------------------------------------------+
//| CHANGELOG v3.24 (Parte 027):                                     |
//| + SetMagicNumber() — facade para BlockerFilters.SetMagicNumber()  |
//+------------------------------------------------------------------+
//| CHANGELOG v3.23 (Parte 025):                                     |
//| + Refatoração: CBlockers dividido em 3 módulos coesos:           |
//|   - BlockerFilters.mqh: TimeFilter + NewsFilter + SpreadFilter   |
//|   - BlockerDrawdown.mqh: DrawdownProtection                      |
//|   - BlockerLimits.mqh: DailyLimits + StreakControl               |
//| + CBlockers passa a ser orchestrator — API pública inalterada    |
//+------------------------------------------------------------------+

// ═══════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════
#include "Logger.mqh"

//+------------------------------------------------------------------+
//| Enumerações                                                      |
//+------------------------------------------------------------------+

enum ENUM_TRADE_DIRECTION
{
   DIRECTION_BOTH,       // Ambos (Compra e Venda)
   DIRECTION_BUY_ONLY,   // Apenas Compras
   DIRECTION_SELL_ONLY   // Apenas Vendas
};

enum ENUM_STREAK_ACTION
{
   STREAK_PAUSE,    // Pausar por X minutos e depois retomar
   STREAK_STOP_DAY  // Parar até o fim do dia
};

enum ENUM_PROFIT_TARGET_ACTION
{
   PROFIT_ACTION_STOP,              // Parar de operar
   PROFIT_ACTION_ENABLE_DRAWDOWN    // Ativar Proteção de Drawdown
};

enum ENUM_DRAWDOWN_TYPE
{
   DD_FINANCIAL,   // Financeiro (valor fixo)
   DD_PERCENTAGE   // Percentual (% do lucro conquistado)
};

enum ENUM_DRAWDOWN_PEAK_MODE
{
   DD_PEAK_REALIZED_ONLY   = 0, // Apenas Lucro Realizado
   DD_PEAK_INCLUDE_FLOATING = 1  // Incluir P/L Flutuante
};

enum ENUM_BLOCKER_REASON
{
   BLOCKER_NONE = 0,
   BLOCKER_TIME_FILTER,
   BLOCKER_NEWS_FILTER,
   BLOCKER_SPREAD,
   BLOCKER_DAILY_TRADES,
   BLOCKER_DAILY_LOSS,
   BLOCKER_DAILY_GAIN,
   BLOCKER_LOSS_STREAK,
   BLOCKER_WIN_STREAK,
   BLOCKER_DRAWDOWN,
   BLOCKER_DIRECTION
};

enum ENUM_SESSION_STATE
{
   SESSION_BEFORE,
   SESSION_ACTIVE,
   SESSION_PROTECTION,
   SESSION_AFTER
};

// ═══════════════════════════════════════════════════════════════
// SUBMODULES
// ═══════════════════════════════════════════════════════════════
#include "BlockerFilters.mqh"
#include "BlockerDrawdown.mqh"
#include "BlockerLimits.mqh"

//+------------------------------------------------------------------+
//| Classe CBlockers — Orchestrator                                  |
//+------------------------------------------------------------------+
class CBlockers
{
private:
   CBlockerFilters   m_filters;
   CBlockerDrawdown  m_drawdown;
   CBlockerLimits    m_limits;

   CLogger*               m_logger;
   int                    m_magicNumber;
   ENUM_TRADE_DIRECTION   m_inputTradeDirection;
   ENUM_TRADE_DIRECTION   m_tradeDirection;

   datetime               m_lastResetDate;
   ENUM_BLOCKER_REASON    m_currentBlocker;

   bool   IsNewDay();
   bool   CheckDirectionAllowed(int orderType);
   string GetBlockerReasonText(ENUM_BLOCKER_REASON reason);

public:
   CBlockers();
   ~CBlockers();

   bool Init(
      CLogger* logger,
      int magicNumber,
      bool enableTime, int startH, int startM, int endH, int endM,
      bool closeOnEnd, bool closeBeforeSessionEnd, int minutesBeforeSessionEnd,
      bool news1, int n1StartH, int n1StartM, int n1EndH, int n1EndM,
      bool news2, int n2StartH, int n2StartM, int n2EndH, int n2EndM,
      bool news3, int n3StartH, int n3StartM, int n3EndH, int n3EndM,
      int maxSpread,
      bool enableLimits, int maxTrades, double maxLoss, double maxGain,
      ENUM_PROFIT_TARGET_ACTION profitAction,
      bool enableStreak,
      int maxLossStreak, ENUM_STREAK_ACTION lossAction, int lossPauseMin,
      int maxWinStreak,  ENUM_STREAK_ACTION winAction,  int winPauseMin,
      bool enableDD, ENUM_DRAWDOWN_TYPE ddType, double ddValue,
      ENUM_DRAWDOWN_PEAK_MODE ddPeakMode,
      ENUM_TRADE_DIRECTION tradeDirection
   );

   // Métodos principais
   bool CanTrade(int dailyTrades, double dailyProfit, string &blockReason);
   bool CanTradeDirection(int orderType, string &blockReason);
   bool ShouldCloseOnEndTime(ulong positionTicket);
   bool ShouldCloseBeforeSessionEnd(ulong positionTicket);
   bool ShouldCloseByDailyLimit(ulong positionTicket, double dailyProfit, string &closeReason);
   bool ShouldCloseByDrawdown(ulong positionTicket, double dailyProfit, string &closeReason);

   // Atualização de estado
   void UpdateAfterTrade(bool isWin, double tradeProfit);
   void UpdatePeakBalance(double currentBalance);
   void UpdatePeakProfit(double currentProfit);
   void ActivateDrawdownProtection(double closedProfit, double projectedProfit);
   void ResetDaily();

   // Hot Reload
   void SetMaxSpread(int newMaxSpread);
   void SetTradeDirection(ENUM_TRADE_DIRECTION newDirection);
   void SetDailyLimits(int maxTrades, double maxLoss, double maxGain, ENUM_PROFIT_TARGET_ACTION action);
   void SetStreakLimits(int maxLoss, ENUM_STREAK_ACTION lossAction, int lossPause,
                        int maxWin,  ENUM_STREAK_ACTION winAction,  int winPause);
   void SetDrawdownValue(double newValue);
   void SetDrawdownType(ENUM_DRAWDOWN_TYPE newType);
   void SetDrawdownPeakMode(ENUM_DRAWDOWN_PEAK_MODE newMode);
   void TryActivateDrawdownNow(double dailyProfit);
   void SetTimeFilter(bool enable, int startH, int startM, int endH, int endM);
   void SetCloseOnEndTime(bool close);
   void SetCloseBeforeSessionEnd(bool close, int minutes);
   void SetNewsFilter(int window, bool enable, int startH, int startM, int endH, int endM);
   void SetMagicNumber(int newMagic);

   // Getters — estado
   int      GetCurrentLossStreak()         const { return m_limits.GetCurrentLossStreak(); }
   int      GetCurrentWinStreak()          const { return m_limits.GetCurrentWinStreak(); }
   double   GetCurrentDrawdown()                 { return m_drawdown.GetCurrentDrawdown(); }
   double   GetDailyPeakProfit()           const { return m_drawdown.GetDailyPeakProfit(); }
   bool     IsDrawdownProtectionActive()   const { return m_drawdown.IsDrawdownProtectionActive(); }
   bool     IsDrawdownLimitReached()       const { return m_drawdown.IsDrawdownLimitReached(); }
   ENUM_DRAWDOWN_TYPE     GetDrawdownType()     const { return m_drawdown.GetDrawdownType(); }
   double                 GetDrawdownValue()    const { return m_drawdown.GetDrawdownValue(); }
   ENUM_DRAWDOWN_PEAK_MODE GetDrawdownPeakMode() const { return m_drawdown.GetDrawdownPeakMode(); }
   ENUM_BLOCKER_REASON    GetActiveBlocker()    const { return m_currentBlocker; }
   bool     IsBlocked()                    const { return m_currentBlocker != BLOCKER_NONE; }
   bool     IsStreakControlEnabled()       const { return m_limits.IsStreakControlEnabled(); }
   bool     IsStreakPaused()               const { return m_limits.IsStreakPaused(); }
   datetime GetStreakPauseUntil()          const { return m_limits.GetStreakPauseUntil(); }
   string   GetStreakPauseReason()         const { return m_limits.GetStreakPauseReason(); }
   int      GetMaxLossStreak()             const { return m_limits.GetMaxLossStreak(); }
   int      GetMaxWinStreak()              const { return m_limits.GetMaxWinStreak(); }
   ENUM_STREAK_ACTION GetLossStreakAction() const { return m_limits.GetLossStreakAction(); }
   ENUM_STREAK_ACTION GetWinStreakAction()  const { return m_limits.GetWinStreakAction(); }
   int      GetLossPauseMinutes()          const { return m_limits.GetLossPauseMinutes(); }
   int      GetWinPauseMinutes()           const { return m_limits.GetWinPauseMinutes(); }

   // Getters — configuração
   int                  GetMaxSpread()            const { return m_filters.GetMaxSpread(); }
   ENUM_TRADE_DIRECTION GetTradeDirection()        const { return m_tradeDirection; }
   int                  GetInputMaxSpread()        const { return m_filters.GetInputMaxSpread(); }
   ENUM_TRADE_DIRECTION GetInputTradeDirection()   const { return m_inputTradeDirection; }

   // Debug
   void PrintStatus();
   void PrintConfiguration();
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
   // FIX 2: inicializar com data zero em vez de TimeCurrent()
   // para que IsNewDay() nunca retorne false erroneamente
   // no primeiro dia de operação.
   m_lastResetDate       = 0;
   m_currentBlocker      = BLOCKER_NONE;
}

//+------------------------------------------------------------------+
//| Destrutor                                                        |
//+------------------------------------------------------------------+
CBlockers::~CBlockers() {}

//+------------------------------------------------------------------+
//| Init()                                                           |
//+------------------------------------------------------------------+
bool CBlockers::Init(
   CLogger* logger, int magicNumber,
   bool enableTime, int startH, int startM, int endH, int endM,
   bool closeOnEnd, bool closeBeforeSessionEnd, int minutesBeforeSessionEnd,
   bool news1, int n1StartH, int n1StartM, int n1EndH, int n1EndM,
   bool news2, int n2StartH, int n2StartM, int n2EndH, int n2EndM,
   bool news3, int n3StartH, int n3StartM, int n3EndH, int n3EndM,
   int maxSpread,
   bool enableLimits, int maxTrades, double maxLoss, double maxGain,
   ENUM_PROFIT_TARGET_ACTION profitAction,
   bool enableStreak,
   int maxLossStreak, ENUM_STREAK_ACTION lossAction, int lossPauseMin,
   int maxWinStreak,  ENUM_STREAK_ACTION winAction,  int winPauseMin,
   bool enableDD, ENUM_DRAWDOWN_TYPE ddType, double ddValue,
   ENUM_DRAWDOWN_PEAK_MODE ddPeakMode,
   ENUM_TRADE_DIRECTION tradeDirection
)
{
   m_logger      = logger;
   m_magicNumber = magicNumber;

   if(m_logger != NULL)
   {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "╔══════════════════════════════════════════════════════╗");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "║     EPBOT MATRIX - INICIALIZANDO BLOCKERS v3.25     ║");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "╚══════════════════════════════════════════════════════╝");
   }
   else
   {
      Print("╔══════════════════════════════════════════════════════╗");
      Print("║     EPBOT MATRIX - INICIALIZANDO BLOCKERS v3.25     ║");
      Print("╚══════════════════════════════════════════════════════╝");
   }

   if(!m_filters.Init(logger, magicNumber,
         enableTime, startH, startM, endH, endM,
                  closeOnEnd, closeBeforeSessionEnd, minutesBeforeSessionEnd,
         news1, n1StartH, n1StartM, n1EndH, n1EndM,
         news2, n2StartH, n2StartM, n2EndH, n2EndM,
         news3, n3StartH, n3StartM, n3EndH, n3EndM,
         maxSpread))
      return false;

   if(!m_limits.Init(logger,
         enableLimits, maxTrades, maxLoss, maxGain, profitAction,
         enableStreak,
         maxLossStreak, lossAction, lossPauseMin,
         maxWinStreak,  winAction,  winPauseMin))
      return false;

   if(!m_drawdown.Init(logger, magicNumber, enableDD, ddType, ddValue, ddPeakMode))
      return false;

   m_inputTradeDirection = tradeDirection;
   m_tradeDirection      = tradeDirection;

   string dirText = "";
   switch(tradeDirection)
   {
      case DIRECTION_BOTH:      dirText = "Ambas (Compra e Venda)"; break;
      case DIRECTION_BUY_ONLY:  dirText = "Apenas COMPRAS";         break;
      case DIRECTION_SELL_ONLY: dirText = "Apenas VENDAS";          break;
   }
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "🎯 Direção Permitida: " + dirText);
   else
      Print("🎯 Direção Permitida: ", dirText);

   // FIX 2: m_lastResetDate setado para hoje (dia atual, hora 00:00)
   // para que IsNewDay() não dispare falsamente no mesmo dia da init.
   MqlDateTime td; TimeToStruct(TimeCurrent(), td);
   td.hour = 0; td.min = 0; td.sec = 0;
   m_lastResetDate  = StructToTime(td);
   m_currentBlocker = BLOCKER_NONE;

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "✅ Blockers v3.25 inicializados!");
   else
      Print("✅ Blockers v3.25 inicializados!");

   return true;
}

//+------------------------------------------------------------------+
//| CanTrade()                                                       |
//| FIX 1: IsNewDay()/ResetDaily() REMOVIDOS daqui.                  |
//| O EA principal (OnTick) é o único responsável pela virada de dia.|
//| Manter reset aqui causava: duplo reset, zeragem de streak no      |
//| meio do dia, e conflito de responsabilidades entre módulos.       |
//+------------------------------------------------------------------+
bool CBlockers::CanTrade(int dailyTrades, double dailyProfit, string &blockReason)
{
   m_currentBlocker = BLOCKER_NONE;
   blockReason      = "";

   // ── PROTEÇÃO DE SESSÃO ──────────────────────────────────────────
   if(!m_filters.CheckSessionBlocking(m_currentBlocker, blockReason))
      return false;

   // ── FILTRO DE HORÁRIO ───────────────────────────────────────────
   if(!m_filters.CheckTimeWithLog(m_currentBlocker, blockReason))
      return false;

   // ── FILTRO DE NOTÍCIAS ──────────────────────────────────────────
   if(!m_filters.CheckNewsWithLog(m_currentBlocker, blockReason))
      return false;

   // ── FILTRO DE SPREAD ────────────────────────────────────────────
   if(!m_filters.CheckSpreadWithLog(m_currentBlocker, blockReason))
      return false;

   // ── LIMITES DIÁRIOS (antes do Streak — diagnóstico correto) ─────
   bool activateDD = false;
   if(!m_limits.CheckDailyLimitsWithLog(dailyTrades, dailyProfit,
         m_currentBlocker, blockReason, activateDD))
      return false;

   // ── STREAK ──────────────────────────────────────────────────────
   if(!m_limits.CheckStreakWithLog(m_currentBlocker, blockReason))
      return false;

   // ── ATIVAR DRAWDOWN se profit target atingido com ação ENABLE_DD ─
   if(activateDD && !m_drawdown.IsDrawdownProtectionActive())
      m_drawdown.ActivateDrawdownProtection(dailyProfit, dailyProfit);

   // ── DRAWDOWN ─────────────────────────────────────────────────────
   if(!m_drawdown.CheckDrawdownWithLog(m_currentBlocker, blockReason))
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| CanTradeDirection()                                              |
//+------------------------------------------------------------------+
bool CBlockers::CanTradeDirection(int orderType, string &blockReason)
{
   if(!CheckDirectionAllowed(orderType))
   {
      m_currentBlocker = BLOCKER_DIRECTION;
      blockReason = (orderType == ORDER_TYPE_BUY)
         ? "Compras bloqueadas - Apenas VENDAS permitidas"
         : "Vendas bloqueadas - Apenas COMPRAS permitidas";
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| ShouldCloseOnEndTime()                                           |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseOnEndTime(ulong positionTicket)
{
   return m_filters.ShouldCloseOnEndTime(positionTicket);
}

//+------------------------------------------------------------------+
//| ShouldCloseBeforeSessionEnd()                                    |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseBeforeSessionEnd(ulong positionTicket)
{
   return m_filters.ShouldCloseBeforeSessionEnd(positionTicket);
}

//+------------------------------------------------------------------+
//| ShouldCloseByDailyLimit()                                        |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseByDailyLimit(ulong positionTicket,
                                         double dailyProfit,
                                         string &closeReason)
{
   bool   activateDD       = false;
   double activateDDClosed = 0;
   double activateDDProj   = 0;

   bool result = m_limits.ShouldCloseByDailyLimit(
      positionTicket, dailyProfit, closeReason,
      activateDD, activateDDClosed, activateDDProj);

   if(activateDD && !m_drawdown.IsDrawdownProtectionActive())
      m_drawdown.ActivateDrawdownProtection(activateDDClosed, activateDDProj);

   return result;
}

//+------------------------------------------------------------------+
//| ShouldCloseByDrawdown()                                          |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseByDrawdown(ulong positionTicket,
                                       double dailyProfit,
                                       string &closeReason)
{
   return m_drawdown.ShouldCloseByDrawdown(positionTicket, dailyProfit, closeReason);
}

//+------------------------------------------------------------------+
//| UpdateAfterTrade()                                               |
//+------------------------------------------------------------------+
void CBlockers::UpdateAfterTrade(bool isWin, double tradeProfit)
{
   m_limits.UpdateAfterTrade(isWin, tradeProfit);
}

//+------------------------------------------------------------------+
//| UpdatePeakBalance()                                              |
//+------------------------------------------------------------------+
void CBlockers::UpdatePeakBalance(double currentBalance)
{
   m_drawdown.UpdatePeakBalance(currentBalance);
}

//+------------------------------------------------------------------+
//| UpdatePeakProfit()                                               |
//+------------------------------------------------------------------+
void CBlockers::UpdatePeakProfit(double currentProfit)
{
   m_drawdown.UpdatePeakProfit(currentProfit);
}

//+------------------------------------------------------------------+
//| ActivateDrawdownProtection()                                     |
//+------------------------------------------------------------------+
void CBlockers::ActivateDrawdownProtection(double closedProfit, double projectedProfit)
{
   m_drawdown.ActivateDrawdownProtection(closedProfit, projectedProfit);
}

//+------------------------------------------------------------------+
//| ResetDaily()                                                     |
//| FIX 4: m_tradeDirection NÃO é resetado por design —             |
//| alterações via GUI persistem entre dias (comportamento           |
//| intencional). Para resetar para o input original, use            |
//| SetTradeDirection(m_inputTradeDirection) explicitamente.         |
//+------------------------------------------------------------------+
void CBlockers::ResetDaily()
{
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "RESET",
         "🔄 RESET DIÁRIO - Limpando contadores...");
   else
      Print("🔄 RESET DIÁRIO - Limpando contadores...");

   m_limits.ResetDaily();
   m_drawdown.ResetDaily();
   m_currentBlocker = BLOCKER_NONE;

   // Atualiza data do último reset para hoje (meia-noite)
   MqlDateTime td; TimeToStruct(TimeCurrent(), td);
   td.hour = 0; td.min = 0; td.sec = 0;
   m_lastResetDate = StructToTime(td);

   // NOTA: m_tradeDirection preservado intencionalmente.
   // Alterações via GUI (hot reload) persistem entre dias.

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
//| Hot Reload — Direção                                             |
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
            "Direção alterada: " + oldText + " → " + newText);
      else
         Print("🔄 Direção alterada: ", oldText, " → ", newText);
   }
}

//+------------------------------------------------------------------+
//| Hot Reload — Limites diários                                     |
//+------------------------------------------------------------------+
void CBlockers::SetDailyLimits(int maxTrades, double maxLoss, double maxGain,
                                ENUM_PROFIT_TARGET_ACTION action)
{
   m_limits.SetDailyLimits(maxTrades, maxLoss, maxGain, action);
}

//+------------------------------------------------------------------+
//| Hot Reload — Streak                                              |
//+------------------------------------------------------------------+
void CBlockers::SetStreakLimits(int maxLoss, ENUM_STREAK_ACTION lossAction, int lossPause,
                                 int maxWin,  ENUM_STREAK_ACTION winAction,  int winPause)
{
   m_limits.SetStreakLimits(maxLoss, lossAction, lossPause, maxWin, winAction, winPause);
}

//+------------------------------------------------------------------+
//| Hot Reload — Drawdown                                            |
//+------------------------------------------------------------------+
void CBlockers::SetDrawdownValue(double newValue)   { m_drawdown.SetDrawdownValue(newValue); }
void CBlockers::SetDrawdownType(ENUM_DRAWDOWN_TYPE newType) { m_drawdown.SetDrawdownType(newType); }
void CBlockers::SetDrawdownPeakMode(ENUM_DRAWDOWN_PEAK_MODE newMode) { m_drawdown.SetDrawdownPeakMode(newMode); }
void CBlockers::TryActivateDrawdownNow(double dailyProfit) { m_drawdown.TryActivateDrawdownNow(dailyProfit); }

//+------------------------------------------------------------------+
//| Hot Reload — Filtros de horário/notícias                         |
//+------------------------------------------------------------------+
void CBlockers::SetTimeFilter(bool enable, int startH, int startM, int endH, int endM)
{
   m_filters.SetTimeFilter(enable, startH, startM, endH, endM);
}
void CBlockers::SetCloseOnEndTime(bool close)
{
   m_filters.SetCloseOnEndTime(close);
}
void CBlockers::SetCloseBeforeSessionEnd(bool close, int minutes)
{
   m_filters.SetCloseBeforeSessionEnd(close, minutes);
}
void CBlockers::SetNewsFilter(int window, bool enable,
                               int startH, int startM, int endH, int endM)
{
   m_filters.SetNewsFilter(window, enable, startH, startM, endH, endM);
}

//+------------------------------------------------------------------+
//| Hot Reload — Magic Number                                        |
//| FIX 3: loga reconstrução de streak para visibilidade.            |
//+------------------------------------------------------------------+
void CBlockers::SetMagicNumber(int newMagic)
{
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         StringFormat("🔄 Magic alterado para %d — reconstruindo streak do histórico...",
            newMagic));

   m_filters.SetMagicNumber(newMagic);
   m_drawdown.SetMagicNumber(newMagic);
   m_limits.ReconstructStreakFromHistory();

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         StringFormat("✅ Streak reconstruído | Loss: %d | Win: %d",
            m_limits.GetCurrentLossStreak(),
            m_limits.GetCurrentWinStreak()));
}

//+------------------------------------------------------------------+
//| PRIVADO: IsNewDay()                                              |
//+------------------------------------------------------------------+
bool CBlockers::IsNewDay()
{
   MqlDateTime lastDate, currentDate;
   TimeToStruct(m_lastResetDate,  lastDate);
   TimeToStruct(TimeCurrent(),    currentDate);

   return (lastDate.year != currentDate.year ||
           lastDate.mon  != currentDate.mon  ||
           lastDate.day  != currentDate.day);
}

//+------------------------------------------------------------------+
//| PRIVADO: CheckDirectionAllowed()                                 |
//+------------------------------------------------------------------+
bool CBlockers::CheckDirectionAllowed(int orderType)
{
   if(m_tradeDirection == DIRECTION_BOTH) return true;
   if(m_tradeDirection == DIRECTION_BUY_ONLY  && orderType == ORDER_TYPE_SELL) return false;
   if(m_tradeDirection == DIRECTION_SELL_ONLY && orderType == ORDER_TYPE_BUY)  return false;
   return true;
}

//+------------------------------------------------------------------+
//| PRIVADO: GetBlockerReasonText()                                  |
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
//| PrintStatus()                                                    |
//+------------------------------------------------------------------+
void CBlockers::PrintStatus()
{
   string header = "╔══════════════════════════════════════════════════════╗";
   string title  = "║            BLOCKERS - STATUS ATUAL                  ║";
   string footer = "╚══════════════════════════════════════════════════════╝";

   if(m_logger != NULL)
   {
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", header);
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", title);
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", footer);
   }
   else { Print(header); Print(title); Print(footer); }

   string statusMsg = (m_currentBlocker != BLOCKER_NONE)
      ? "🚫 BLOQUEADO: " + GetBlockerReasonText(m_currentBlocker)
      : "✅ LIBERADO PARA OPERAR";

   if(m_logger != NULL)
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", statusMsg);
   else
      Print(statusMsg);

   if(m_limits.IsStreakControlEnabled())
   {
      if(m_logger != NULL)
      {
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "");
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "🔴 Streaks:");
         if(m_limits.GetMaxLossStreak() > 0)
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS",
               "  Loss: " + IntegerToString(m_limits.GetCurrentLossStreak()) +
               " de "     + IntegerToString(m_limits.GetMaxLossStreak()));
         if(m_limits.GetMaxWinStreak() > 0)
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS",
               "  Win: "  + IntegerToString(m_limits.GetCurrentWinStreak()) +
               " de "     + IntegerToString(m_limits.GetMaxWinStreak()));
         if(m_limits.IsStreakPaused())
         {
            int remaining = (int)((m_limits.GetStreakPauseUntil() - TimeCurrent()) / 60);
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS",
               "  ⏸️ PAUSADO: " + m_limits.GetStreakPauseReason() +
               " (" + IntegerToString(remaining) + " min)");
         }
      }
      else
      {
         Print("");
         Print("🔴 Streaks:");
         if(m_limits.GetMaxLossStreak() > 0)
            Print("  Loss: ", m_limits.GetCurrentLossStreak(),
                  " de ", m_limits.GetMaxLossStreak());
         if(m_limits.GetMaxWinStreak() > 0)
            Print("  Win: ",  m_limits.GetCurrentWinStreak(),
                  " de ", m_limits.GetMaxWinStreak());
         if(m_limits.IsStreakPaused())
         {
            int remaining = (int)((m_limits.GetStreakPauseUntil() - TimeCurrent()) / 60);
            Print("  ⏸️ PAUSADO: ", m_limits.GetStreakPauseReason(),
                  " (", remaining, " min)");
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
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS",
            "  Pico:    $" + DoubleToString(m_drawdown.GetDailyPeakProfit(), 2));
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS",
            "  DD atual: " + DoubleToString(currentDD, 2));
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS",
            "  Status:  " + (m_drawdown.IsDrawdownLimitReached()
               ? "❌ LIMITE ATINGIDO" : "✅ OK"));
      }
      else
      {
         Print("");
         Print("📉 Drawdown (proteção ativa):");
         Print("  Pico:    $", DoubleToString(m_drawdown.GetDailyPeakProfit(), 2));
         Print("  DD atual: ", DoubleToString(currentDD, 2));
         Print("  Status:  ", m_drawdown.IsDrawdownLimitReached()
            ? "❌ LIMITE ATINGIDO" : "✅ OK");
      }
   }

   string sep = "═══════════════════════════════════════════════════════";
   if(m_logger != NULL)
   {
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", sep);
   }
   else { Print(""); Print(sep); }
}

//+------------------------------------------------------------------+
//| PrintConfiguration()                                             |
//+------------------------------------------------------------------+
void CBlockers::PrintConfiguration()
{
   string sep = "═══════════════════════════════════════════════════════";
   string hdr = "╔══════════════════════════════════════════════════════╗";
   string ftr = "╚══════════════════════════════════════════════════════╝";

   // Helper lambda-style macro via local function not available in MQL5
   // so we duplicate logger/print pattern inline
   #define CFG_LOG(msg) if(m_logger != NULL) m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", (msg)); else Print(msg)

   CFG_LOG(hdr);
   CFG_LOG("║          BLOCKERS - CONFIGURACAO COMPLETA            ║");
   CFG_LOG(ftr);
   CFG_LOG("");

   // ── Geral ────────────────────────────────────────────────────
   CFG_LOG("[ GERAL ]");
   string dirText;
   switch(m_tradeDirection)
     {
      case DIRECTION_BOTH:      dirText = "Ambas (Compra e Venda)"; break;
      case DIRECTION_BUY_ONLY:  dirText = "Apenas COMPRAS";         break;
      case DIRECTION_SELL_ONLY: dirText = "Apenas VENDAS";          break;
      default:                  dirText = "Desconhecida";            break;
     }
   CFG_LOG("  Spread Max atual : " + IntegerToString(m_filters.GetMaxSpread()) + " pts");
   CFG_LOG("  Spread Max input : " + IntegerToString(m_filters.GetInputMaxSpread()) + " pts");
   CFG_LOG("  Direcao          : " + dirText);
   CFG_LOG("");

   // ── Filtros (delegado ao submodulo) ──────────────────────────
   m_filters.PrintConfiguration();

   // ── Limites diarios e streak ─────────────────────────────────
   m_limits.PrintConfiguration();

   // ── Drawdown ─────────────────────────────────────────────────
   m_drawdown.PrintConfiguration();

   CFG_LOG("");
   CFG_LOG(sep);

   #undef CFG_LOG
  }
//| FIM — Blockers.mqh v3.25                                        |
//+------------------------------------------------------------------+
