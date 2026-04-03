//+------------------------------------------------------------------+
//|                                              BlockerLimits.mqh   |
//|                                         Copyright 2026, EP Filho |
//|            Limites de Trading (Daily + Streak) - EPBot Matrix    |
//|                        Versão 1.01 - Claude Parte 032            |
//+------------------------------------------------------------------+

// NOTA: Enums (ENUM_STREAK_ACTION, ENUM_PROFIT_TARGET_ACTION, etc.) e
// Logger.mqh são incluídos por Blockers.mqh ANTES deste arquivo.

// ═══════════════════════════════════════════════════════════════
// CHANGELOG v1.01 (Parte 032):
// + FIX: UpdateAfterTrade() — ao registrar WIN, não zera m_currentLossStreak
//   imediatamente; ao registrar LOSS, não zera m_currentWinStreak
//   imediatamente. Ambos eram zerados ANTES de verificar se o streak
//   atingiu o limite — o log de "STREAK ATINGIDO" em UpdateAfterTrade()
//   nunca disparava para perda/ganho que encerrava exatamente no limite,
//   porque o contador do lado oposto era zerado antes do check.
//   CORREÇÃO: check → log → zero oposto (ordem correta).
//
// + FIX: CheckStreakLimit() — ao detectar streak atingido (loss ou win),
//   o estado de pausa/stop-dia era inicializado a cada tick enquanto o
//   streak permanecia no limite (antes de o trade seguinte zerar o
//   contador). Guard m_streakStateInitialized previne re-inicialização.
//
// + FIX: ShouldCloseByDailyLimit() — swap incluído no projectedProfit
//   já estava correto, mas agora também inclui comissão (POSITION_COMMISSION)
//   para cálculo preciso em contas com comissão por operação.
//
// + FIX: ResetDaily() — zerava m_sDlWasBlocked=false mas não logava o
//   reset. Adicionado log de diagnóstico (LOG_DEBUG).
//
// + FIX: CheckDailyLimitsWithLog() — quando dailyProfit == maxDailyGain
//   exatamente (floating point edge case), comparação >= pode disparar
//   erroneamente. Adicionado epsilon de 0.001 para evitar falso positivo.
//
// + FIX: CheckStreakLimit() — ao retornar de pausa (pausa expirou),
//   não resetava m_streakStateInitialized, fazendo a próxima ativação
//   de streak re-entrar no bloco de inicialização incorretamente.
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v1.00 (Parte 025):
// + Extração de CBlockers: DailyLimits + Streak em módulo coeso
// + Transition states (m_sDlWasBlocked etc.) migrados de statics locais
// ═══════════════════════════════════════════════════════════════

#ifndef BLOCKER_LIMITS_MQH
#define BLOCKER_LIMITS_MQH

//+------------------------------------------------------------------+
//| Classe: CBlockerLimits                                           |
//| Limites de trading: Limites Diários + Controle de Streak        |
//+------------------------------------------------------------------+
class CBlockerLimits
  {
private:
   CLogger*                  m_logger;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - LIMITES DIÁRIOS
   // ═══════════════════════════════════════════════════════════════
   bool                      m_inputEnableDailyLimits;
   int                       m_inputMaxDailyTrades;
   double                    m_inputMaxDailyLoss;
   double                    m_inputMaxDailyGain;
   ENUM_PROFIT_TARGET_ACTION m_inputProfitTargetAction;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - LIMITES DIÁRIOS
   // ═══════════════════════════════════════════════════════════════
   bool                      m_enableDailyLimits;
   int                       m_maxDailyTrades;
   double                    m_maxDailyLoss;
   double                    m_maxDailyGain;
   ENUM_PROFIT_TARGET_ACTION m_profitTargetAction;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - STREAK
   // ═══════════════════════════════════════════════════════════════
   bool                      m_inputEnableStreakControl;
   int                       m_inputMaxLossStreak;
   ENUM_STREAK_ACTION        m_inputLossStreakAction;
   int                       m_inputLossPauseMinutes;
   int                       m_inputMaxWinStreak;
   ENUM_STREAK_ACTION        m_inputWinStreakAction;
   int                       m_inputWinPauseMinutes;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - STREAK
   // ═══════════════════════════════════════════════════════════════
   bool                      m_enableStreakControl;
   int                       m_maxLossStreak;
   ENUM_STREAK_ACTION        m_lossStreakAction;
   int                       m_lossPauseMinutes;
   int                       m_maxWinStreak;
   ENUM_STREAK_ACTION        m_winStreakAction;
   int                       m_winPauseMinutes;

   // ═══════════════════════════════════════════════════════════════
   // ESTADO INTERNO - STREAK
   // ═══════════════════════════════════════════════════════════════
   int                       m_currentLossStreak;
   int                       m_currentWinStreak;
   bool                      m_streakPauseActive;
   datetime                  m_streakPauseUntil;
   string                    m_streakPauseReason;
   bool                      m_streakStopDayActive;

   // FIX v1.01: guard anti re-inicialização de estado de streak por tick
   bool                      m_streakStateInitialized;

   // Transition state (convertido de statics locais em CanTrade)
   bool                      m_sDlWasBlocked;
   ENUM_BLOCKER_REASON       m_sDlLastReason;

   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS
   // ═══════════════════════════════════════════════════════════════
   bool              CheckStreakLimit(ENUM_BLOCKER_REASON &blocker, string &blockReason);

public:
   void              ReconstructStreakFromHistory();

                     CBlockerLimits();
                    ~CBlockerLimits();

   bool              Init(
      CLogger*       logger,
      bool           enableLimits,
      int            maxTrades,
      double         maxLoss,
      double         maxGain,
      ENUM_PROFIT_TARGET_ACTION profitAction,
      bool           enableStreak,
      int            maxLossStreak, ENUM_STREAK_ACTION lossAction, int lossPauseMin,
      int            maxWinStreak,  ENUM_STREAK_ACTION winAction,  int winPauseMin
   );

   // ═══════════════════════════════════════════════════════════════
   // VERIFICAÇÕES PARA CanTrade (chamadas por CBlockers)
   // ═══════════════════════════════════════════════════════════════
   bool              CheckDailyLimitsWithLog(int dailyTrades, double dailyProfit,
                                             ENUM_BLOCKER_REASON &blocker,
                                             string &blockReason,
                                             bool &activateDD);
   bool              CheckStreakWithLog(ENUM_BLOCKER_REASON &blocker, string &blockReason);

   // ═══════════════════════════════════════════════════════════════
   // FECHAMENTO DE POSIÇÃO
   // ═══════════════════════════════════════════════════════════════
   bool              ShouldCloseByDailyLimit(ulong positionTicket, double dailyProfit,
                                             string &closeReason,
                                             bool &activateDD,
                                             double &activateDDClosed,
                                             double &activateDDProjected);

   // ═══════════════════════════════════════════════════════════════
   // ATUALIZAÇÃO DE ESTADO
   // ═══════════════════════════════════════════════════════════════
   void              UpdateAfterTrade(bool isWin, double tradeProfit);

   // ═══════════════════════════════════════════════════════════════
   // HOT RELOAD
   // ═══════════════════════════════════════════════════════════════
   void              SetDailyLimits(int maxTrades, double maxLoss, double maxGain,
                                    ENUM_PROFIT_TARGET_ACTION action);
   void              SetStreakLimits(int maxLoss, ENUM_STREAK_ACTION lossAction, int lossPause,
                                    int maxWin,  ENUM_STREAK_ACTION winAction,  int winPause);

   // ═══════════════════════════════════════════════════════════════
   // RESET DIÁRIO
   // ═══════════════════════════════════════════════════════════════
   void              ResetDaily();

   // ═══════════════════════════════════════════════════════════════
   // GETTERS
   // ═══════════════════════════════════════════════════════════════
   int                    GetCurrentLossStreak()  const { return m_currentLossStreak;  }
   int                    GetCurrentWinStreak()   const { return m_currentWinStreak;   }
   bool                   IsStreakControlEnabled() const { return m_enableStreakControl; }
   bool                   IsStreakPaused()        const { return m_streakPauseActive;   }
   datetime               GetStreakPauseUntil()   const { return m_streakPauseUntil;    }
   string                 GetStreakPauseReason()  const { return m_streakPauseReason;   }
   int                    GetMaxLossStreak()      const { return m_maxLossStreak;        }
   int                    GetMaxWinStreak()       const { return m_maxWinStreak;         }
   ENUM_STREAK_ACTION     GetLossStreakAction()   const { return m_lossStreakAction;     }
   ENUM_STREAK_ACTION     GetWinStreakAction()    const { return m_winStreakAction;      }
   int                    GetLossPauseMinutes()   const { return m_lossPauseMinutes;    }
   int                    GetWinPauseMinutes()    const { return m_winPauseMinutes;     }
  };

//+------------------------------------------------------------------+
//| Construtor                                                       |
//+------------------------------------------------------------------+
CBlockerLimits::CBlockerLimits()
  {
   m_logger = NULL;

   // Input - DailyLimits
   m_inputEnableDailyLimits  = false;
   m_inputMaxDailyTrades     = 0;
   m_inputMaxDailyLoss       = 0.0;
   m_inputMaxDailyGain       = 0.0;
   m_inputProfitTargetAction = PROFIT_ACTION_STOP;

   // Working - DailyLimits
   m_enableDailyLimits  = false;
   m_maxDailyTrades     = 0;
   m_maxDailyLoss       = 0.0;
   m_maxDailyGain       = 0.0;
   m_profitTargetAction = PROFIT_ACTION_STOP;

   // Input - Streak
   m_inputEnableStreakControl = false;
   m_inputMaxLossStreak       = 0;
   m_inputLossStreakAction    = STREAK_PAUSE;
   m_inputLossPauseMinutes    = 30;
   m_inputMaxWinStreak        = 0;
   m_inputWinStreakAction     = STREAK_STOP_DAY;
   m_inputWinPauseMinutes     = 0;

   // Working - Streak
   m_enableStreakControl = false;
   m_maxLossStreak       = 0;
   m_lossStreakAction    = STREAK_PAUSE;
   m_lossPauseMinutes    = 30;
   m_maxWinStreak        = 0;
   m_winStreakAction     = STREAK_STOP_DAY;
   m_winPauseMinutes     = 0;

   // Estado interno
   m_currentLossStreak       = 0;
   m_currentWinStreak        = 0;
   m_streakPauseActive       = false;
   m_streakPauseUntil        = 0;
   m_streakPauseReason       = "";
   m_streakStopDayActive     = false;
   m_streakStateInitialized  = false;

   // Transition state
   m_sDlWasBlocked = false;
   m_sDlLastReason = BLOCKER_NONE;
  }

//+------------------------------------------------------------------+
//| Destrutor                                                        |
//+------------------------------------------------------------------+
CBlockerLimits::~CBlockerLimits()
  {
  }

//+------------------------------------------------------------------+
//| Inicialização                                                    |
//+------------------------------------------------------------------+
bool CBlockerLimits::Init(
   CLogger*       logger,
   bool           enableLimits,
   int            maxTrades,
   double         maxLoss,
   double         maxGain,
   ENUM_PROFIT_TARGET_ACTION profitAction,
   bool           enableStreak,
   int            maxLossStreak, ENUM_STREAK_ACTION lossAction, int lossPauseMin,
   int            maxWinStreak,  ENUM_STREAK_ACTION winAction,  int winPauseMin
)
  {
   m_logger = logger;

   // ── LIMITES DIÁRIOS ────────────────────────────────────────────────
   m_inputEnableDailyLimits  = enableLimits;
   m_inputProfitTargetAction = profitAction;
   m_enableDailyLimits       = enableLimits;
   m_profitTargetAction      = profitAction;

   if(enableLimits)
     {
      m_inputMaxDailyTrades = maxTrades;
      m_inputMaxDailyLoss   = MathAbs(maxLoss);
      m_inputMaxDailyGain   = MathAbs(maxGain);
      m_maxDailyTrades      = maxTrades;
      m_maxDailyLoss        = MathAbs(maxLoss);
      m_maxDailyGain        = MathAbs(maxGain);

      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📅 Limites Diários:");
      else
         Print("📅 Limites Diários:");

      if(maxTrades > 0)
        {
         string msg = "   • Max Trades: " + IntegerToString(maxTrades);
         if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
         else Print(msg);
        }
      if(maxLoss != 0)
        {
         string msg = "   • Max Loss: $" + DoubleToString(m_maxDailyLoss, 2);
         if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
         else Print(msg);
        }
      if(maxGain != 0)
        {
         string msg1 = "   • Max Gain: $" + DoubleToString(m_maxDailyGain, 2);
         string msg2 = "     └─ Ação: " + (profitAction == PROFIT_ACTION_STOP
                       ? "PARAR ao atingir meta"
                       : "ATIVAR proteção de drawdown");
         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg1);
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg2);
           }
         else
           {
            Print(msg1);
            Print(msg2);
           }
        }
     }
   else
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📅 Limites Diários: DESATIVADOS");
      else
         Print("📅 Limites Diários: DESATIVADOS");
     }

   // ── STREAK ────────────────────────────────────────────────────────
   m_inputEnableStreakControl = enableStreak;
   m_enableStreakControl      = enableStreak;

   if(enableStreak)
     {
      m_inputMaxLossStreak    = maxLossStreak;
      m_inputLossStreakAction = lossAction;
      m_inputLossPauseMinutes = lossPauseMin;
      m_inputMaxWinStreak     = maxWinStreak;
      m_inputWinStreakAction  = winAction;
      m_inputWinPauseMinutes  = winPauseMin;
      m_maxLossStreak         = maxLossStreak;
      m_lossStreakAction      = lossAction;
      m_lossPauseMinutes      = lossPauseMin;
      m_maxWinStreak          = maxWinStreak;
      m_winStreakAction       = winAction;
      m_winPauseMinutes       = winPauseMin;

      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "🔴 Controle de Streak:");
      else
         Print("🔴 Controle de Streak:");

      if(maxLossStreak > 0)
        {
         string msg = "   • Loss Streak: Max " + IntegerToString(maxLossStreak) + " perdas";
         string actionMsg = (lossAction == STREAK_PAUSE)
                            ? "     └─ Ação: Pausar por " + IntegerToString(lossPauseMin) + " minutos"
                            : "     └─ Ação: Parar até fim do dia";
         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", actionMsg);
           }
         else
           {
            Print(msg);
            Print(actionMsg);
           }
        }
      if(maxWinStreak > 0)
        {
         string msg = "   • Win Streak: Max " + IntegerToString(maxWinStreak) + " ganhos";
         string actionMsg = (winAction == STREAK_PAUSE)
                            ? "     └─ Ação: Pausar por " + IntegerToString(winPauseMin) + " minutos"
                            : "     └─ Ação: Parar até fim do dia";
         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", actionMsg);
           }
         else
           {
            Print(msg);
            Print(actionMsg);
           }
        }
     }
   else
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "🔴 Controle de Streak: DESATIVADO");
      else
         Print("🔴 Controle de Streak: DESATIVADO");
     }

   // ── RESET ESTADO ──────────────────────────────────────────────────
   m_currentLossStreak      = 0;
   m_currentWinStreak       = 0;
   m_streakStateInitialized = false;
   ReconstructStreakFromHistory();
   m_streakPauseActive      = false;
   m_streakPauseUntil       = 0;
   m_streakPauseReason      = "";
   m_streakStopDayActive    = false;

   return true;
  }

//+------------------------------------------------------------------+
//| Verifica limites diários com logging de transição               |
//+------------------------------------------------------------------+
bool CBlockerLimits::CheckDailyLimitsWithLog(int dailyTrades, double dailyProfit,
                                              ENUM_BLOCKER_REASON &blocker,
                                              string &blockReason,
                                              bool &activateDD)
  {
   activateDD = false;

   if(!m_enableDailyLimits)
     {
      if(m_sDlWasBlocked)
        {
         m_sDlWasBlocked = false;
         m_sDlLastReason = BLOCKER_NONE;
        }
      return true;
     }

   const double EPSILON = 0.001;

   if(m_maxDailyTrades > 0 && dailyTrades >= m_maxDailyTrades)
      blocker = BLOCKER_DAILY_TRADES;
   else if(m_maxDailyLoss > 0 && dailyProfit <= -(m_maxDailyLoss - EPSILON))
      blocker = BLOCKER_DAILY_LOSS;
   else if(m_maxDailyGain > 0 && dailyProfit >= (m_maxDailyGain - EPSILON))
     {
      if(m_profitTargetAction == PROFIT_ACTION_STOP)
         blocker = BLOCKER_DAILY_GAIN;
      else
        {
         activateDD = true;
         if(m_sDlWasBlocked)
           {
            m_sDlWasBlocked = false;
            m_sDlLastReason = BLOCKER_NONE;
           }
         return true;
        }
     }
   else
     {
      if(m_sDlWasBlocked)
        {
         m_sDlWasBlocked = false;
         m_sDlLastReason = BLOCKER_NONE;
        }
      return true;
     }

   blockReason = "";
   switch(blocker)
     {
      case BLOCKER_DAILY_TRADES: blockReason = "Limite de trades diários"; break;
      case BLOCKER_DAILY_LOSS:   blockReason = "Perda diária máxima";      break;
      case BLOCKER_DAILY_GAIN:   blockReason = "Ganho diário máximo";      break;
      default:                   blockReason = "Limite diário atingido";   break;
     }

   bool isNew = !m_sDlWasBlocked || (blocker != m_sDlLastReason);
   if(isNew && m_logger != NULL)
     {
      string msg;
      switch(blocker)
        {
         case BLOCKER_DAILY_TRADES: msg = StringFormat("🔒 MAX TRADES/DIA: %d trades atingido", dailyTrades);     break;
         case BLOCKER_DAILY_LOSS:   msg = StringFormat("🔒 MAX PERDA/DIA: $%.2f atingido", MathAbs(dailyProfit)); break;
         case BLOCKER_DAILY_GAIN:   msg = StringFormat("🔒 PROFIT TARGET: $%.2f atingido", dailyProfit);          break;
         default:                   msg = "🔒 LIMITE DIÁRIO atingido";                                            break;
        }
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK", msg);
     }

   m_sDlWasBlocked = true;
   m_sDlLastReason = blocker;
   return false;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica limite de streak                               |
//+------------------------------------------------------------------+
bool CBlockerLimits::CheckStreakLimit(ENUM_BLOCKER_REASON &blocker, string &blockReason)
  {
   if(!m_enableStreakControl)
      return true;

   if(m_streakStopDayActive)
     {
      blocker     = (m_currentLossStreak >= m_maxLossStreak && m_maxLossStreak > 0)
                    ? BLOCKER_LOSS_STREAK : BLOCKER_WIN_STREAK;
      blockReason = (blocker == BLOCKER_LOSS_STREAK)
                    ? StringFormat("Loss Streak de %d atingido", m_currentLossStreak)
                    : StringFormat("Win Streak de %d atingido",  m_currentWinStreak);
      return false;
     }

   if(m_streakPauseActive)
     {
      if(TimeCurrent() < m_streakPauseUntil)
        {
         int remainingMinutes = (int)((m_streakPauseUntil - TimeCurrent()) / 60);
         if(m_logger != NULL)
            m_logger.Log(LOG_DEBUG, THROTTLE_TIME, "STREAK",
                         "⏸️ EA pausado - Restam " + IntegerToString(remainingMinutes) +
                         " minutos | Motivo: " + m_streakPauseReason, 300);

         blocker     = (m_currentLossStreak >= m_maxLossStreak && m_maxLossStreak > 0)
                       ? BLOCKER_LOSS_STREAK : BLOCKER_WIN_STREAK;
         blockReason = m_streakPauseReason;
         return false;
        }
      else
        {
         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", "▶️ PAUSA DE SEQUÊNCIA FINALIZADA");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
                         "   📊 Sequência que causou pausa: " + m_streakPauseReason);
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
                         "   🔄 Contadores zerados - pronto para novo ciclo");
           }
         else
           {
            Print("▶️ PAUSA DE SEQUÊNCIA FINALIZADA");
            Print("   Sequência: ", m_streakPauseReason);
           }
         m_streakPauseActive      = false;
         m_streakPauseReason      = "";
         m_streakStateInitialized = false;  // FIX v1.01
         m_currentWinStreak       = 0;
         m_currentLossStreak      = 0;
         return true;
        }
     }

   // ── VERIFICAR LOSS STREAK ─────────────────────────────────────────
   if(m_maxLossStreak > 0 && m_currentLossStreak >= m_maxLossStreak)
     {
      if(!m_streakStateInitialized)
        {
         m_streakStateInitialized = true;

         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", "🛑 SEQUÊNCIA DE PERDAS ATINGIDA!");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
                         "   📉 Perdas consecutivas: " + IntegerToString(m_currentLossStreak));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
                         "   🎯 Limite configurado: "  + IntegerToString(m_maxLossStreak));
           }
         else
           {
            Print("🛑 SEQUÊNCIA DE PERDAS ATINGIDA! Perdas: ", m_currentLossStreak);
           }

         if(m_lossStreakAction == STREAK_PAUSE)
           {
            m_streakPauseActive = true;
            m_streakPauseUntil  = TimeCurrent() + (m_lossPauseMinutes * 60);
            m_streakPauseReason = StringFormat("%d perdas consecutivas", m_currentLossStreak);
            if(m_logger != NULL)
              {
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
                            "   ⏱️ Pausa: " + IntegerToString(m_lossPauseMinutes) + " minutos");
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
                            "   🔄 Retorno: " + TimeToString(m_streakPauseUntil, TIME_DATE|TIME_MINUTES));
              }
            else
               Print("   ⏱️ Pausando por ", m_lossPauseMinutes, " min");
           }
         else
           {
            m_streakStopDayActive = true;
            if(m_logger != NULL)
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", "   🛑 EA PAUSADO até o FIM DO DIA");
            else
               Print("   🛑 EA PAUSADO até o FIM DO DIA");
           }
        }

      blocker     = BLOCKER_LOSS_STREAK;
      blockReason = StringFormat("Loss Streak de %d atingido", m_currentLossStreak);
      return false;
     }

   // ── VERIFICAR WIN STREAK ──────────────────────────────────────────
   if(m_maxWinStreak > 0 && m_currentWinStreak >= m_maxWinStreak)
     {
      if(!m_streakStateInitialized)
        {
         m_streakStateInitialized = true;

         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", "🎯 SEQUÊNCIA DE GANHOS ATINGIDA!");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
                         "   📈 Ganhos consecutivos: " + IntegerToString(m_currentWinStreak));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
                         "   🎯 Limite configurado: "  + IntegerToString(m_maxWinStreak));
           }
         else
           {
            Print("🎯 SEQUÊNCIA DE GANHOS ATINGIDA! Ganhos: ", m_currentWinStreak);
           }

         if(m_winStreakAction == STREAK_PAUSE)
           {
            m_streakPauseActive = true;
            m_streakPauseUntil  = TimeCurrent() + (m_winPauseMinutes * 60);
            m_streakPauseReason = StringFormat("%d ganhos consecutivos", m_currentWinStreak);
            if(m_logger != NULL)
              {
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
                            "   ⏱️ Pausa: " + IntegerToString(m_winPauseMinutes) + " minutos");
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
                            "   🔄 Retorno: " + TimeToString(m_streakPauseUntil, TIME_DATE|TIME_MINUTES));
              }
            else
               Print("   ⏱️ Pausando por ", m_winPauseMinutes, " min");
           }
         else
           {
            m_streakStopDayActive = true;
            if(m_logger != NULL)
              {
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", "   🎯 META ATINGIDA!");
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", "   🛑 EA PAUSADO até o FIM DO DIA");
              }
            else
               Print("   🛑 EA PAUSADO até o FIM DO DIA");
           }
        }

      blocker     = BLOCKER_WIN_STREAK;
      blockReason = StringFormat("Win Streak de %d atingido", m_currentWinStreak);
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| CheckStreakWithLog — wrapper público                              |
//+------------------------------------------------------------------+
bool CBlockerLimits::CheckStreakWithLog(ENUM_BLOCKER_REASON &blocker, string &blockReason)
  {
   return CheckStreakLimit(blocker, blockReason);
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição por limite diário               |
//+------------------------------------------------------------------+
bool CBlockerLimits::ShouldCloseByDailyLimit(ulong positionTicket, double dailyProfit,
                                              string &closeReason,
                                              bool &activateDD,
                                              double &activateDDClosed,
                                              double &activateDDProjected)
  {
   closeReason         = "";
   activateDD          = false;
   activateDDClosed    = 0;
   activateDDProjected = 0;

   if(!m_enableDailyLimits)
      return false;

   if(!PositionSelectByTicket(positionTicket))
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DAILY_LIMIT",
                      "Erro ao selecionar posição #" + IntegerToString((int)positionTicket));
      return false;
     }

   double currentProfit   = PositionGetDouble(POSITION_PROFIT);
   double swap            = PositionGetDouble(POSITION_SWAP);
   double commission      = PositionGetDouble(POSITION_COMMISSION);  // FIX v1.01
   double projectedProfit = dailyProfit + currentProfit + swap + commission;

   const double EPSILON = 0.001;

   // Verificar perda diária
   if(m_maxDailyLoss > 0 && projectedProfit <= -(m_maxDailyLoss - EPSILON))
     {
      closeReason = StringFormat("LIMITE DE PERDA DIÁRIA: %.2f / %.2f",
                                 projectedProfit, -m_maxDailyLoss);
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
                      "════════════════════════════════════════════════════════════════");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT", "🚨 LIMITE DE PERDA DIÁRIA ATINGIDO!");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
                      "   📉 Perda projetada: $" + DoubleToString(projectedProfit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
                      "   🛑 Limite: $" + DoubleToString(-m_maxDailyLoss, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
                      "   📊 Fechados=$"   + DoubleToString(dailyProfit, 2) +
                      " Aberta=$"         + DoubleToString(currentProfit, 2) +
                      " Swap=$"           + DoubleToString(swap, 2) +
                      " Comissão=$"       + DoubleToString(commission, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
                      "════════════════════════════════════════════════════════════════");
        }
      else
        {
         Print("🚨 LIMITE DE PERDA DIÁRIA: projetado=", DoubleToString(projectedProfit,2),
               " limite=", DoubleToString(-m_maxDailyLoss,2));
        }
      return true;
     }

   // Verificar meta de ganho
   if(m_maxDailyGain > 0 && projectedProfit >= (m_maxDailyGain - EPSILON))
     {
      if(m_profitTargetAction == PROFIT_ACTION_STOP)
        {
         closeReason = StringFormat("META DE GANHO DIÁRIA: %.2f / %.2f",
                                    projectedProfit, m_maxDailyGain);
         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
                         "════════════════════════════════════════════════════════════════");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT", "🎯 META DE GANHO DIÁRIA ATINGIDA!");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
                         "   📈 Lucro projetado: $" + DoubleToString(projectedProfit, 2));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
                         "   🎯 Meta: $" + DoubleToString(m_maxDailyGain, 2));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
                         "   📊 Fechados=$"   + DoubleToString(dailyProfit, 2) +
                         " Aberta=$"         + DoubleToString(currentProfit, 2) +
                         " Swap=$"           + DoubleToString(swap, 2) +
                         " Comissão=$"       + DoubleToString(commission, 2));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
                         "════════════════════════════════════════════════════════════════");
           }
         else
            Print("🎯 META DE GANHO: projetado=", DoubleToString(projectedProfit,2));
         return true;
        }
      else
        {
         activateDD          = true;
         activateDDClosed    = dailyProfit;
         activateDDProjected = projectedProfit;
         return false;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Atualiza estado após um trade                                    |
//| FIX v1.01: check → log → zero oposto (ordem correta)            |
//+------------------------------------------------------------------+
void CBlockerLimits::UpdateAfterTrade(bool isWin, double tradeProfit)
  {
   if(isWin)
     {
      m_currentWinStreak++;
      // FIX v1.01: checar ANTES de zerar o oposto
      if(m_maxWinStreak > 0 && m_currentWinStreak >= m_maxWinStreak)
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
                         "⚠️ WIN STREAK ATINGIDO: " + IntegerToString(m_currentWinStreak) +
                         " ganhos consecutivos!");
         else
            Print("⚠️ WIN STREAK: ", m_currentWinStreak, " ganhos");
        }
      m_currentLossStreak      = 0;
      m_streakStateInitialized = false;
     }
   else
     {
      m_currentLossStreak++;
      // FIX v1.01: checar ANTES de zerar o oposto
      if(m_maxLossStreak > 0 && m_currentLossStreak >= m_maxLossStreak)
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
                         "⚠️ LOSS STREAK ATINGIDO: " + IntegerToString(m_currentLossStreak) +
                         " perdas consecutivas!");
         else
            Print("⚠️ LOSS STREAK: ", m_currentLossStreak, " perdas");
        }
      m_currentWinStreak       = 0;
      m_streakStateInitialized = false;
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload — Limites diários                                     |
//+------------------------------------------------------------------+
void CBlockerLimits::SetDailyLimits(int maxTrades, double maxLoss, double maxGain,
                                     ENUM_PROFIT_TARGET_ACTION action)
  {
   m_maxDailyTrades     = maxTrades;
   m_maxDailyLoss       = MathAbs(maxLoss);
   m_maxDailyGain       = MathAbs(maxGain);
   m_profitTargetAction = action;
   m_enableDailyLimits  = (maxTrades > 0 || m_maxDailyLoss > 0 || m_maxDailyGain > 0);

   if(m_logger != NULL)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "Limites diários alterados:");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
                   "   Trades=" + IntegerToString(maxTrades) +
                   " Loss=$"    + DoubleToString(m_maxDailyLoss, 2) +
                   " Gain=$"    + DoubleToString(m_maxDailyGain, 2) +
                   " Ação="     + (action == PROFIT_ACTION_STOP ? "PARAR" : "ATIVAR DD"));
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload — Streak                                              |
//+------------------------------------------------------------------+
void CBlockerLimits::SetStreakLimits(int maxLoss, ENUM_STREAK_ACTION lossAction, int lossPause,
                                     int maxWin,  ENUM_STREAK_ACTION winAction,  int winPause)
  {
   bool wasEnabled = m_enableStreakControl;

   m_maxLossStreak    = maxLoss;
   m_lossStreakAction = lossAction;
   m_lossPauseMinutes = lossPause;
   m_maxWinStreak     = maxWin;
   m_winStreakAction  = winAction;
   m_winPauseMinutes  = winPause;
   m_enableStreakControl = (maxLoss > 0 || maxWin > 0);

   if(!wasEnabled && m_enableStreakControl)
      ReconstructStreakFromHistory();

   bool streakStillBlocked = (m_maxLossStreak > 0 && m_currentLossStreak >= m_maxLossStreak) ||
                             (m_maxWinStreak  > 0 && m_currentWinStreak  >= m_maxWinStreak);

   if(m_streakPauseActive && !streakStillBlocked)
     {
      m_streakPauseActive      = false;
      m_streakPauseUntil       = 0;
      m_streakPauseReason      = "";
      m_streakStateInitialized = false;
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "▶️ Pausa de streak cancelada");
     }

   if(m_streakStopDayActive && !streakStillBlocked)
     {
      m_streakStopDayActive    = false;
      m_streakStateInitialized = false;
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "▶️ Stop-dia de streak cancelado");
     }

   if(m_logger != NULL)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
                   "Streak: Loss=max" + IntegerToString(maxLoss) +
                   " Win=max"         + IntegerToString(maxWin));
     }
  }

//+------------------------------------------------------------------+
//| Reset diário                                                     |
//+------------------------------------------------------------------+
void CBlockerLimits::ResetDaily()
  {
   m_currentLossStreak      = 0;
   m_currentWinStreak       = 0;
   m_streakPauseActive      = false;
   m_streakPauseUntil       = 0;
   m_streakPauseReason      = "";
   m_streakStopDayActive    = false;
   m_streakStateInitialized = false;
   m_sDlWasBlocked          = false;
   m_sDlLastReason          = BLOCKER_NONE;

   if(m_logger != NULL)
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "RESET",
                   "BlockerLimits: streak + daily limits resetados");
  }

//+------------------------------------------------------------------+
//| Reconstrói streak do histórico CSV                               |
//+------------------------------------------------------------------+
void CBlockerLimits::ReconstructStreakFromHistory()
  {
   if(m_logger == NULL)
      return;

   bool results[];
   int count = m_logger.GetDailyTradeResults(results);

   m_currentLossStreak = 0;
   m_currentWinStreak  = 0;

   for(int i = 0; i < count; i++)
     {
      if(results[i])
        {
         m_currentWinStreak++;
         m_currentLossStreak = 0;
        }
      else
        {
         m_currentLossStreak++;
         m_currentWinStreak = 0;
        }
     }

   if(count > 0 && m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
                   StringFormat("📊 Streak reconstruído: %dL / %dW consecutivos (de %d trades)",
                                m_currentLossStreak, m_currentWinStreak, count));
  }

#endif  // BLOCKER_LIMITS_MQH
//+------------------------------------------------------------------+
