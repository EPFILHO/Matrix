//+------------------------------------------------------------------+
//|                                                     Blockers.mqh |
//|                                         Copyright 2025, EP Filho |
//|                              Sistema de Bloqueios - EPBot Matrix |
//|                                                      Versão 3.00 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EP Filho"
#property version   "3.00"
#property strict

// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.00:
// ✅ Refatoração completa do sistema de logging
// ✅ Uso do Logger v3.00 com sistema de throttle automático
// ✅ Removidas variáveis de throttle manual (m_lastXxxWarning)
// ✅ Todos os logs agora usam métodos throttled (Once/Throttled)
// ✅ Simplificação: removido pattern if(m_logger != NULL) ... else Print()
// ✅ Verbosidade controlada: bloqueios repetitivos agora usam LogWarningOnce
// ═══════════════════════════════════════════════════════════════
//
// CHANGELOG v2.02:
// ✅ CORREÇÃO CRÍTICA: Validação de Magic Number adicionada em:
//    - ShouldCloseOnEndTime()
//    - ShouldCloseBeforeSessionEnd()
// ✅ Agora cada EA fecha APENAS suas próprias posições
// ✅ Compatível com múltiplos EAs no mesmo gráfico (HEDGING)
// ✅ Logs informativos quando posição de outro EA é ignorada
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════
#include "Logger.mqh"

//+------------------------------------------------------------------+
//| Enumerações                                                      |
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

//+------------------------------------------------------------------+
//| Classe: CBlockers                                                |
//| Gerencia TODOS os bloqueadores do sistema                        |
//+------------------------------------------------------------------+
class CBlockers
  {
private:
   // ═══════════════════════════════════════════════════════════════
   // LOGGER
   // ═══════════════════════════════════════════════════════════════
   CLogger*          m_logger;                // Referência ao logger centralizado
   int               m_magicNumber;           // Magic number do EA

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - HORÁRIO (valores originais, imutáveis)
   // ═══════════════════════════════════════════════════════════════
   bool              m_inputEnableTimeFilter;
   int               m_inputStartHour;
   int               m_inputStartMinute;
   int               m_inputEndHour;
   int               m_inputEndMinute;
   bool              m_inputCloseOnEndTime;
   bool              m_closeBeforeSessionEnd;      // Fechar antes do fim da sessão?
   int               m_minutesBeforeSessionEnd;    // Minutos antes do fim da sessão


   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - HORÁRIO (valores usados no código, mutáveis)
   // ═══════════════════════════════════════════════════════════════
   bool              m_enableTimeFilter;
   int               m_startHour;
   int               m_startMinute;
   int               m_endHour;
   int               m_endMinute;
   bool              m_closeOnEndTime;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - NEWS FILTERS (valores originais)
   // ═══════════════════════════════════════════════════════════════
   bool              m_inputEnableNewsFilter1;
   int               m_inputNewsStart1Hour;
   int               m_inputNewsStart1Minute;
   int               m_inputNewsEnd1Hour;
   int               m_inputNewsEnd1Minute;

   bool              m_inputEnableNewsFilter2;
   int               m_inputNewsStart2Hour;
   int               m_inputNewsStart2Minute;
   int               m_inputNewsEnd2Hour;
   int               m_inputNewsEnd2Minute;

   bool              m_inputEnableNewsFilter3;
   int               m_inputNewsStart3Hour;
   int               m_inputNewsStart3Minute;
   int               m_inputNewsEnd3Hour;
   int               m_inputNewsEnd3Minute;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - NEWS FILTERS (valores usados)
   // ═══════════════════════════════════════════════════════════════
   bool              m_enableNewsFilter1;
   int               m_newsStart1Hour;
   int               m_newsStart1Minute;
   int               m_newsEnd1Hour;
   int               m_newsEnd1Minute;

   bool              m_enableNewsFilter2;
   int               m_newsStart2Hour;
   int               m_newsStart2Minute;
   int               m_newsEnd2Hour;
   int               m_newsEnd2Minute;

   bool              m_enableNewsFilter3;
   int               m_newsStart3Hour;
   int               m_newsStart3Minute;
   int               m_newsEnd3Hour;
   int               m_newsEnd3Minute;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - SPREAD (valor original)
   // ═══════════════════════════════════════════════════════════════
   int               m_inputMaxSpread;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - SPREAD (valor usado)
   // ═══════════════════════════════════════════════════════════════
   int               m_maxSpread;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - LIMITES DIÁRIOS (valores originais)
   // ═══════════════════════════════════════════════════════════════
   bool              m_inputEnableDailyLimits;
   int               m_inputMaxDailyTrades;
   double            m_inputMaxDailyLoss;
   double            m_inputMaxDailyGain;
   ENUM_PROFIT_TARGET_ACTION m_inputProfitTargetAction;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - LIMITES DIÁRIOS (valores usados)
   // ═══════════════════════════════════════════════════════════════
   bool              m_enableDailyLimits;
   int               m_maxDailyTrades;
   double            m_maxDailyLoss;
   double            m_maxDailyGain;
   ENUM_PROFIT_TARGET_ACTION m_profitTargetAction;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - STREAK (valores originais)
   // ═══════════════════════════════════════════════════════════════
   bool              m_inputEnableStreakControl;
   int               m_inputMaxLossStreak;
   ENUM_STREAK_ACTION m_inputLossStreakAction;
   int               m_inputLossPauseMinutes;
   int               m_inputMaxWinStreak;
   ENUM_STREAK_ACTION m_inputWinStreakAction;
   int               m_inputWinPauseMinutes;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - STREAK (valores usados)
   // ═══════════════════════════════════════════════════════════════
   bool              m_enableStreakControl;
   int               m_maxLossStreak;
   ENUM_STREAK_ACTION m_lossStreakAction;
   int               m_lossPauseMinutes;
   int               m_maxWinStreak;
   ENUM_STREAK_ACTION m_winStreakAction;
   int               m_winPauseMinutes;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - DRAWDOWN (valores originais)
   // ═══════════════════════════════════════════════════════════════
   bool              m_inputEnableDrawdown;
   ENUM_DRAWDOWN_TYPE m_inputDrawdownType;
   double            m_inputDrawdownValue;
   double            m_inputInitialBalance;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - DRAWDOWN (valores usados)
   // ═══════════════════════════════════════════════════════════════
   bool              m_enableDrawdown;
   ENUM_DRAWDOWN_TYPE m_drawdownType;
   double            m_drawdownValue;
   double            m_initialBalance;
   double            m_peakBalance;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - DIREÇÃO (valor original)
   // ═══════════════════════════════════════════════════════════════
   ENUM_TRADE_DIRECTION m_inputTradeDirection;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - DIREÇÃO (valor usado)
   // ═══════════════════════════════════════════════════════════════
   ENUM_TRADE_DIRECTION m_tradeDirection;

   // ═══════════════════════════════════════════════════════════════
   // ESTADO INTERNO (não são inputs, não precisam de duplicação)
   // ═══════════════════════════════════════════════════════════════
   int               m_currentLossStreak;
   int               m_currentWinStreak;
   bool              m_streakPauseActive;
   datetime          m_streakPauseUntil;
   string            m_streakPauseReason;

   double            m_dailyPeakProfit;
   bool              m_drawdownProtectionActive;
   bool              m_drawdownLimitReached;

   datetime          m_lastResetDate;
   ENUM_BLOCKER_REASON m_currentBlocker;

   // ═══════════════════════════════════════════════════════════════
   // v3.00: Throttle manual removido - agora usa Logger v3.00
   // Variáveis removidas: m_lastStreakWarning, m_lastNewsWarning,
   // m_lastTimeWarning, m_lastDailyLimitWarning
   // ═══════════════════════════════════════════════════════════════

   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS - VERIFICADORES INDIVIDUAIS
   // ═══════════════════════════════════════════════════════════════
   bool              CheckTimeFilter();
   bool              CheckNewsFilter();
   bool              CheckSpreadFilter();
   bool              CheckDailyLimits(int dailyTrades, double dailyProfit);
   bool              CheckStreakLimit();
   bool              CheckDrawdownLimit();
   bool              CheckDirectionAllowed(int orderType);

   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS - UTILITÁRIOS
   // ═══════════════════════════════════════════════════════════════
   bool              IsNewDay();
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
      bool enableDD, ENUM_DRAWDOWN_TYPE ddType, double ddValue, double initialBalance,
      // Direção
      ENUM_TRADE_DIRECTION tradeDirection
   );

   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS PRINCIPAIS - VERIFICAÇÃO DE TRADING
   // ═══════════════════════════════════════════════════════════════
   bool              CanTrade(int dailyTrades, double dailyProfit, string &blockReason);
   bool              CanTradeDirection(int orderType, string &blockReason);
   bool              ShouldCloseOnEndTime(ulong positionTicket);
   bool              ShouldCloseBeforeSessionEnd(ulong positionTicket);

   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS DE ATUALIZAÇÃO DE ESTADO
   // ═══════════════════════════════════════════════════════════════
   void              UpdateAfterTrade(bool isWin, double tradeProfit);
   void              UpdatePeakBalance(double currentBalance);
   void              UpdatePeakProfit(double currentProfit);
   void              ActivateDrawdownProtection(double peakProfit);
   void              ResetDaily();

   // ═══════════════════════════════════════════════════════════════
   // HOT RELOAD - Alterações em Runtime (parâmetros que fazem sentido mudar)
   // ═══════════════════════════════════════════════════════════════
   void              SetMaxSpread(int newMaxSpread);
   void              SetTradeDirection(ENUM_TRADE_DIRECTION newDirection);
   void              SetDailyLimits(int maxTrades, double maxLoss, double maxGain, ENUM_PROFIT_TARGET_ACTION action);
   void              SetStreakLimits(int maxLoss, ENUM_STREAK_ACTION lossAction, int lossPause,
                                     int maxWin, ENUM_STREAK_ACTION winAction, int winPause);
   void              SetDrawdownValue(double newValue);

   // ═══════════════════════════════════════════════════════════════
   // GETTERS - INFORMAÇÕES DE ESTADO
   // ═══════════════════════════════════════════════════════════════
   int               GetCurrentLossStreak() const { return m_currentLossStreak; }
   int               GetCurrentWinStreak() const { return m_currentWinStreak; }
   double            GetCurrentDrawdown();
   double            GetDailyPeakProfit() const { return m_dailyPeakProfit; }
   bool              IsDrawdownProtectionActive() const { return m_drawdownProtectionActive; }
   bool              IsDrawdownLimitReached() const { return m_drawdownLimitReached; }
   ENUM_BLOCKER_REASON GetActiveBlocker() const { return m_currentBlocker; }
   bool              IsBlocked() const { return m_currentBlocker != BLOCKER_NONE; }
   bool              IsStreakPaused() const { return m_streakPauseActive; }
   datetime          GetStreakPauseUntil() const { return m_streakPauseUntil; }
   string            GetStreakPauseReason() const { return m_streakPauseReason; }

   // ═══════════════════════════════════════════════════════════════
   // GETTERS - CONFIGURAÇÃO (Working values)
   // ═══════════════════════════════════════════════════════════════
   int               GetMaxSpread() const { return m_maxSpread; }
   ENUM_TRADE_DIRECTION GetTradeDirection() const { return m_tradeDirection; }

   // ═══════════════════════════════════════════════════════════════
   // GETTERS - CONFIGURAÇÃO (Input values - valores originais)
   // ═══════════════════════════════════════════════════════════════
   int               GetInputMaxSpread() const { return m_inputMaxSpread; }
   ENUM_TRADE_DIRECTION GetInputTradeDirection() const { return m_inputTradeDirection; }

   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS DE DEBUG/INFO
   // ═══════════════════════════════════════════════════════════════
   void              PrintStatus();
   void              PrintConfiguration();
  };

//+------------------------------------------------------------------+
//| Construtor                                                       |
//+------------------------------------------------------------------+
CBlockers::CBlockers()
  {
// Logger
   m_logger = NULL;
   m_magicNumber = 0;

// ═══ INPUT PARAMETERS (valores padrão seguros) ═══

// Horário
   m_inputEnableTimeFilter = false;
   m_inputStartHour = 9;
   m_inputStartMinute = 0;
   m_inputEndHour = 17;
   m_inputEndMinute = 0;
   m_inputCloseOnEndTime = false;

// News
   m_inputEnableNewsFilter1 = false;
   m_inputNewsStart1Hour = 10;
   m_inputNewsStart1Minute = 0;
   m_inputNewsEnd1Hour = 10;
   m_inputNewsEnd1Minute = 15;

   m_inputEnableNewsFilter2 = false;
   m_inputNewsStart2Hour = 14;
   m_inputNewsStart2Minute = 0;
   m_inputNewsEnd2Hour = 14;
   m_inputNewsEnd2Minute = 15;

   m_inputEnableNewsFilter3 = false;
   m_inputNewsStart3Hour = 15;
   m_inputNewsStart3Minute = 0;
   m_inputNewsEnd3Hour = 15;
   m_inputNewsEnd3Minute = 5;

// Spread
   m_inputMaxSpread = 0;

// Limites diários
   m_inputEnableDailyLimits = false;
   m_inputMaxDailyTrades = 0;
   m_inputMaxDailyLoss = 0.0;
   m_inputMaxDailyGain = 0.0;
   m_inputProfitTargetAction = PROFIT_ACTION_STOP;

// Streak
   m_inputEnableStreakControl = false;
   m_inputMaxLossStreak = 0;
   m_inputLossStreakAction = STREAK_PAUSE;
   m_inputLossPauseMinutes = 30;
   m_inputMaxWinStreak = 0;
   m_inputWinStreakAction = STREAK_STOP_DAY;
   m_inputWinPauseMinutes = 0;

// Drawdown
   m_inputEnableDrawdown = false;
   m_inputDrawdownType = DD_FINANCIAL;
   m_inputDrawdownValue = 0.0;
   m_inputInitialBalance = 0.0;

// Direção
   m_inputTradeDirection = DIRECTION_BOTH;

// ═══ WORKING PARAMETERS (copiar dos inputs) ═══

// Horário
   m_enableTimeFilter = false;
   m_startHour = 9;
   m_startMinute = 0;
   m_endHour = 17;
   m_endMinute = 0;
   m_closeOnEndTime = false;
   m_closeBeforeSessionEnd = false;
   m_minutesBeforeSessionEnd = 5;

// News
   m_enableNewsFilter1 = false;
   m_newsStart1Hour = 10;
   m_newsStart1Minute = 0;
   m_newsEnd1Hour = 10;
   m_newsEnd1Minute = 15;

   m_enableNewsFilter2 = false;
   m_newsStart2Hour = 14;
   m_newsStart2Minute = 0;
   m_newsEnd2Hour = 14;
   m_newsEnd2Minute = 15;

   m_enableNewsFilter3 = false;
   m_newsStart3Hour = 15;
   m_newsStart3Minute = 0;
   m_newsEnd3Hour = 15;
   m_newsEnd3Minute = 5;

// Spread
   m_maxSpread = 0;

// Limites diários
   m_enableDailyLimits = false;
   m_maxDailyTrades = 0;
   m_maxDailyLoss = 0.0;
   m_maxDailyGain = 0.0;
   m_profitTargetAction = PROFIT_ACTION_STOP;

// Streak
   m_enableStreakControl = false;
   m_maxLossStreak = 0;
   m_lossStreakAction = STREAK_PAUSE;
   m_lossPauseMinutes = 30;
   m_maxWinStreak = 0;
   m_winStreakAction = STREAK_STOP_DAY;
   m_winPauseMinutes = 0;

// Drawdown
   m_enableDrawdown = false;
   m_drawdownType = DD_FINANCIAL;
   m_drawdownValue = 0.0;
   m_initialBalance = 0.0;
   m_peakBalance = 0.0;

// Direção
   m_tradeDirection = DIRECTION_BOTH;

// ═══ ESTADO INTERNO ═══
   m_currentLossStreak = 0;
   m_currentWinStreak = 0;
   m_streakPauseActive = false;
   m_streakPauseUntil = 0;
   m_streakPauseReason = "";

   m_dailyPeakProfit = 0.0;
   m_drawdownProtectionActive = false;
   m_drawdownLimitReached = false;

   m_lastResetDate = TimeCurrent();
   m_currentBlocker = BLOCKER_NONE;

   // v3.00: Throttle manual removido (agora usa Logger v3.00)
  }

//+------------------------------------------------------------------+
//| Destrutor                                                        |
//+------------------------------------------------------------------+
CBlockers::~CBlockers()
  {
// Nada a fazer por enquanto
  }

//+------------------------------------------------------------------+
//| Inicialização do módulo                                          |
//+------------------------------------------------------------------+
bool CBlockers::Init(
   CLogger* logger,
   int magicNumber,
   // Horário
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
   bool enableDD, ENUM_DRAWDOWN_TYPE ddType, double ddValue, double initialBalance,
   ENUM_TRADE_DIRECTION tradeDirection
)
  {
// Armazenar referência ao logger
   m_logger = logger;
   m_magicNumber = magicNumber;

   if(m_logger != NULL)
     {
      m_logger.LogInfo("╔══════════════════════════════════════════════════════╗");
      m_logger.LogInfo("║        EPBOT MATRIX - INICIALIZANDO BLOCKERS        ║");
      m_logger.LogInfo("║              VERSÃO COMPLETA v2.02                   ║");
      m_logger.LogInfo("╚══════════════════════════════════════════════════════╝");
     }
   else
     {
      Print("╔══════════════════════════════════════════════════════╗");
      Print("║        EPBOT MATRIX - INICIALIZANDO BLOCKERS        ║");
      Print("║              VERSÃO COMPLETA v2.02                   ║");
      Print("╚══════════════════════════════════════════════════════╝");
     }

// ═══════════════════════════════════════════════════════════════
// SALVAR INPUTS (valores originais) E INICIALIZAR WORKING
// ═══════════════════════════════════════════════════════════════

// ───────────────────────────────────────────────────────────────
// HORÁRIO
// ───────────────────────────────────────────────────────────────
   m_inputEnableTimeFilter = enableTime;
   m_inputCloseOnEndTime = closeOnEnd;
   m_enableTimeFilter = enableTime;
   m_closeOnEndTime = closeOnEnd;
   m_closeBeforeSessionEnd = closeBeforeSessionEnd;
   m_minutesBeforeSessionEnd = minutesBeforeSessionEnd; 

   if(enableTime)
     {
      if(startH < 0 || startH > 23 || endH < 0 || endH > 23 ||
         startM < 0 || startM > 59 || endM < 0 || endM > 59)
        {
         if(m_logger != NULL)
            m_logger.LogError("Horários inválidos!");
         else
            Print("❌ Horários inválidos!");
         return false;
        }

      m_inputStartHour = startH;
      m_inputStartMinute = startM;
      m_inputEndHour = endH;
      m_inputEndMinute = endM;

      m_startHour = startH;
      m_startMinute = startM;
      m_endHour = endH;
      m_endMinute = endM;

      string timeMsg = "⏰ Filtro de Horário: " +
                       StringFormat("%02d:%02d - %02d:%02d", startH, startM, endH, endM);

      if(m_logger != NULL)
         m_logger.LogInfo(timeMsg);
      else
         Print(timeMsg);

      if(closeOnEnd)
        {
         if(m_logger != NULL)
            m_logger.LogInfo("   └─ Fecha posição ao fim do horário");
         else
            Print("   └─ Fecha posição ao fim do horário");
        }
     }
   else
     {
      if(m_logger != NULL)
         m_logger.LogInfo("⏰ Filtro de Horário: DESATIVADO");
      else
         Print("⏰ Filtro de Horário: DESATIVADO");
     }

// ───────────────────────────────────────────────────────────────
// NEWS FILTERS
// ───────────────────────────────────────────────────────────────
   m_inputEnableNewsFilter1 = news1;
   m_inputNewsStart1Hour = n1StartH;
   m_inputNewsStart1Minute = n1StartM;
   m_inputNewsEnd1Hour = n1EndH;
   m_inputNewsEnd1Minute = n1EndM;

   m_enableNewsFilter1 = news1;
   m_newsStart1Hour = n1StartH;
   m_newsStart1Minute = n1StartM;
   m_newsEnd1Hour = n1EndH;
   m_newsEnd1Minute = n1EndM;

   m_inputEnableNewsFilter2 = news2;
   m_inputNewsStart2Hour = n2StartH;
   m_inputNewsStart2Minute = n2StartM;
   m_inputNewsEnd2Hour = n2EndH;
   m_inputNewsEnd2Minute = n2EndM;

   m_enableNewsFilter2 = news2;
   m_newsStart2Hour = n2StartH;
   m_newsStart2Minute = n2StartM;
   m_newsEnd2Hour = n2EndH;
   m_newsEnd2Minute = n2EndM;

   m_inputEnableNewsFilter3 = news3;
   m_inputNewsStart3Hour = n3StartH;
   m_inputNewsStart3Minute = n3StartM;
   m_inputNewsEnd3Hour = n3EndH;
   m_inputNewsEnd3Minute = n3EndM;

   m_enableNewsFilter3 = news3;
   m_newsStart3Hour = n3StartH;
   m_newsStart3Minute = n3StartM;
   m_newsEnd3Hour = n3EndH;
   m_newsEnd3Minute = n3EndM;

   if(news1 || news2 || news3)
     {
      if(m_logger != NULL)
         m_logger.LogInfo("📰 Horários de Volatilidade:");
      else
         Print("📰 Horários de Volatilidade:");

      if(news1)
        {
         string msg = "   • Bloqueio 1: " + StringFormat("%02d:%02d - %02d:%02d", n1StartH, n1StartM, n1EndH, n1EndM);
         if(m_logger != NULL)
            m_logger.LogInfo(msg);
         else
            Print(msg);
        }
      if(news2)
        {
         string msg = "   • Bloqueio 2: " + StringFormat("%02d:%02d - %02d:%02d", n2StartH, n2StartM, n2EndH, n2EndM);
         if(m_logger != NULL)
            m_logger.LogInfo(msg);
         else
            Print(msg);
        }
      if(news3)
        {
         string msg = "   • Bloqueio 3: " + StringFormat("%02d:%02d - %02d:%02d", n3StartH, n3StartM, n3EndH, n3EndM);
         if(m_logger != NULL)
            m_logger.LogInfo(msg);
         else
            Print(msg);
        }
     }
   else
     {
      if(m_logger != NULL)
         m_logger.LogInfo("📰 Horários de Volatilidade: DESATIVADOS");
      else
         Print("📰 Horários de Volatilidade: DESATIVADOS");
     }

// ───────────────────────────────────────────────────────────────
// SPREAD
// ───────────────────────────────────────────────────────────────
   m_inputMaxSpread = maxSpread;
   m_maxSpread = maxSpread;

   if(maxSpread > 0)
     {
      string msg = "📊 Spread Máximo: " + IntegerToString(maxSpread) + " pontos";
      if(m_logger != NULL)
         m_logger.LogInfo(msg);
      else
         Print(msg);
     }
   else
     {
      if(m_logger != NULL)
         m_logger.LogInfo("📊 Spread Máximo: ILIMITADO");
      else
         Print("📊 Spread Máximo: ILIMITADO");
     }

// ───────────────────────────────────────────────────────────────
// LIMITES DIÁRIOS
// ───────────────────────────────────────────────────────────────
   m_inputEnableDailyLimits = enableLimits;
   m_inputProfitTargetAction = profitAction;
   m_enableDailyLimits = enableLimits;
   m_profitTargetAction = profitAction;

   if(enableLimits)
     {
      m_inputMaxDailyTrades = maxTrades;
      m_inputMaxDailyLoss = MathAbs(maxLoss);
      m_inputMaxDailyGain = MathAbs(maxGain);

      m_maxDailyTrades = maxTrades;
      m_maxDailyLoss = MathAbs(maxLoss);
      m_maxDailyGain = MathAbs(maxGain);

      if(m_logger != NULL)
         m_logger.LogInfo("📅 Limites Diários:");
      else
         Print("📅 Limites Diários:");

      if(maxTrades > 0)
        {
         string msg = "   - Max Trades: " + IntegerToString(maxTrades);
         if(m_logger != NULL)
            m_logger.LogInfo(msg);
         else
            Print(msg);
        }
      if(maxLoss != 0)
        {
         string msg = "   - Max Loss: $" + DoubleToString(m_maxDailyLoss, 2);
         if(m_logger != NULL)
            m_logger.LogInfo(msg);
         else
            Print(msg);
        }
      if(maxGain != 0)
        {
         string msg1 = "   - Max Gain: $" + DoubleToString(m_maxDailyGain, 2);
         string msg2 = "     └─ Ação: " + (profitAction == PROFIT_ACTION_STOP ? "PARAR ao atingir meta" : "ATIVAR proteção de drawdown");
         if(m_logger != NULL)
           {
            m_logger.LogInfo(msg1);
            m_logger.LogInfo(msg2);
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
         m_logger.LogInfo("📅 Limites Diários: DESATIVADOS");
      else
         Print("📅 Limites Diários: DESATIVADOS");
     }

// ───────────────────────────────────────────────────────────────
// STREAK
// ───────────────────────────────────────────────────────────────
   m_inputEnableStreakControl = enableStreak;
   m_enableStreakControl = enableStreak;

   if(enableStreak)
     {
      m_inputMaxLossStreak = maxLossStreak;
      m_inputLossStreakAction = lossAction;
      m_inputLossPauseMinutes = lossPauseMin;
      m_inputMaxWinStreak = maxWinStreak;
      m_inputWinStreakAction = winAction;
      m_inputWinPauseMinutes = winPauseMin;

      m_maxLossStreak = maxLossStreak;
      m_lossStreakAction = lossAction;
      m_lossPauseMinutes = lossPauseMin;
      m_maxWinStreak = maxWinStreak;
      m_winStreakAction = winAction;
      m_winPauseMinutes = winPauseMin;

      if(m_logger != NULL)
         m_logger.LogInfo("🔴 Controle de Streak:");
      else
         Print("🔴 Controle de Streak:");

      if(maxLossStreak > 0)
        {
         string msg = "   • Loss Streak: Max " + IntegerToString(maxLossStreak) + " perdas";
         if(m_logger != NULL)
            m_logger.LogInfo(msg);
         else
            Print(msg);

         string actionMsg = (lossAction == STREAK_PAUSE) ?
                            "     └─ Ação: Pausar por " + IntegerToString(lossPauseMin) + " minutos" :
                            "     └─ Ação: Parar até fim do dia";
         if(m_logger != NULL)
            m_logger.LogInfo(actionMsg);
         else
            Print(actionMsg);
        }

      if(maxWinStreak > 0)
        {
         string msg = "   • Win Streak: Max " + IntegerToString(maxWinStreak) + " ganhos";
         if(m_logger != NULL)
            m_logger.LogInfo(msg);
         else
            Print(msg);

         string actionMsg = (winAction == STREAK_PAUSE) ?
                            "     └─ Ação: Pausar por " + IntegerToString(winPauseMin) + " minutos" :
                            "     └─ Ação: Parar até fim do dia";
         if(m_logger != NULL)
            m_logger.LogInfo(actionMsg);
         else
            Print(actionMsg);
        }
     }
   else
     {
      if(m_logger != NULL)
         m_logger.LogInfo("🔴 Controle de Streak: DESATIVADO");
      else
         Print("🔴 Controle de Streak: DESATIVADO");
     }

// ───────────────────────────────────────────────────────────────
// DRAWDOWN
// ───────────────────────────────────────────────────────────────
   m_inputEnableDrawdown = enableDD;
   m_inputDrawdownType = ddType;
   m_inputDrawdownValue = ddValue;
   m_enableDrawdown = enableDD;
   m_drawdownType = ddType;
   m_drawdownValue = ddValue;

   if(enableDD)
     {
      if(ddValue <= 0 || (ddType == DD_PERCENTAGE && ddValue > 100))
        {
         if(m_logger != NULL)
            m_logger.LogError("Drawdown inválido!");
         else
            Print("❌ Drawdown inválido!");
         return false;
        }

      if(initialBalance <= 0)
        {
         if(m_logger != NULL)
            m_logger.LogError("Saldo inicial inválido!");
         else
            Print("❌ Saldo inicial inválido!");
         return false;
        }

      m_inputInitialBalance = initialBalance;
      m_initialBalance = initialBalance;
      m_peakBalance = initialBalance;

      if(m_logger != NULL)
         m_logger.LogInfo("📉 Drawdown Máximo:");
      else
         Print("📉 Drawdown Máximo:");

      string typeMsg = (ddType == DD_FINANCIAL) ?
                       "   - Tipo: Financeiro ($" + DoubleToString(ddValue, 2) + ")" :
                       "   - Tipo: Percentual (" + DoubleToString(ddValue, 2) + "%)";
      if(m_logger != NULL)
         m_logger.LogInfo(typeMsg);
      else
         Print(typeMsg);

      string balMsg = "   - Saldo Inicial: $" + DoubleToString(initialBalance, 2);
      if(m_logger != NULL)
         m_logger.LogInfo(balMsg);
      else
         Print(balMsg);
     }
   else
     {
      if(m_logger != NULL)
         m_logger.LogInfo("📉 Proteção Drawdown: DESATIVADA");
      else
         Print("📉 Proteção Drawdown: DESATIVADA");
     }

// ───────────────────────────────────────────────────────────────
// DIREÇÃO
// ───────────────────────────────────────────────────────────────
   m_inputTradeDirection = tradeDirection;
   m_tradeDirection = tradeDirection;

   string dirText = "";
   switch(tradeDirection)
     {
      case DIRECTION_BOTH:
         dirText = "Ambas (Compra e Venda)";
         break;
      case DIRECTION_BUY_ONLY:
         dirText = "Apenas COMPRAS";
         break;
      case DIRECTION_SELL_ONLY:
         dirText = "Apenas VENDAS";
         break;
     }

   string dirMsg = "🎯 Direção Permitida: " + dirText;
   if(m_logger != NULL)
      m_logger.LogInfo(dirMsg);
   else
      Print(dirMsg);

// ───────────────────────────────────────────────────────────────
// RESET ESTADO
// ───────────────────────────────────────────────────────────────
   m_currentLossStreak = 0;
   m_currentWinStreak = 0;
   m_streakPauseActive = false;
   m_streakPauseUntil = 0;
   m_streakPauseReason = "";
   m_dailyPeakProfit = 0.0;
   m_drawdownProtectionActive = false;
   m_drawdownLimitReached = false;
   m_lastResetDate = TimeCurrent();
   m_currentBlocker = BLOCKER_NONE;

   if(m_logger != NULL)
     {
      m_logger.LogInfo("");
      m_logger.LogInfo("✅ Blockers inicializados com sucesso!");
      m_logger.LogInfo("");
     }
   else
     {
      Print("");
      Print("✅ Blockers inicializados com sucesso!");
      Print("");
     }

   return true;
  }

// ═══════════════════════════════════════════════════════════════
// HOT RELOAD - MÉTODOS SET (alteração em runtime)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Hot Reload - Alterar spread máximo                               |
//+------------------------------------------------------------------+
void CBlockers::SetMaxSpread(int newMaxSpread)
  {
   int oldValue = m_maxSpread;
   m_maxSpread = newMaxSpread;

   if(m_logger != NULL)
      m_logger.LogInfo(StringFormat("🔄 Spread máximo alterado: %d → %d pontos", oldValue, newMaxSpread));
   else
      Print("🔄 Spread máximo alterado: ", oldValue, " → ", newMaxSpread, " pontos");
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar direção de trading                          |
//+------------------------------------------------------------------+
void CBlockers::SetTradeDirection(ENUM_TRADE_DIRECTION newDirection)
  {
   ENUM_TRADE_DIRECTION oldDirection = m_tradeDirection;
   m_tradeDirection = newDirection;

   string oldText = "";
   string newText = "";

   switch(oldDirection)
     {
      case DIRECTION_BOTH:
         oldText = "AMBAS";
         break;
      case DIRECTION_BUY_ONLY:
         oldText = "APENAS COMPRAS";
         break;
      case DIRECTION_SELL_ONLY:
         oldText = "APENAS VENDAS";
         break;
     }

   switch(newDirection)
     {
      case DIRECTION_BOTH:
         newText = "AMBAS";
         break;
      case DIRECTION_BUY_ONLY:
         newText = "APENAS COMPRAS";
         break;
      case DIRECTION_SELL_ONLY:
         newText = "APENAS VENDAS";
         break;
     }

   if(m_logger != NULL)
      m_logger.LogInfo(StringFormat("🔄 Direção alterada: %s → %s", oldText, newText));
   else
      Print("🔄 Direção alterada: ", oldText, " → ", newText);
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar limites diários                             |
//+------------------------------------------------------------------+
void CBlockers::SetDailyLimits(int maxTrades, double maxLoss, double maxGain, ENUM_PROFIT_TARGET_ACTION action)
  {
   m_maxDailyTrades = maxTrades;
   m_maxDailyLoss = MathAbs(maxLoss);
   m_maxDailyGain = MathAbs(maxGain);
   m_profitTargetAction = action;

   if(m_logger != NULL)
     {
      m_logger.LogInfo("🔄 Limites diários alterados:");
      m_logger.LogInfo("   • Max Trades: " + IntegerToString(maxTrades));
      m_logger.LogInfo("   • Max Loss: $" + DoubleToString(m_maxDailyLoss, 2));
      m_logger.LogInfo("   • Max Gain: $" + DoubleToString(m_maxDailyGain, 2));
      m_logger.LogInfo("   • Ação: " + (action == PROFIT_ACTION_STOP ? "PARAR" : "ATIVAR DD"));
     }
   else
     {
      Print("🔄 Limites diários alterados:");
      Print("   • Max Trades: ", maxTrades);
      Print("   • Max Loss: $", DoubleToString(m_maxDailyLoss, 2));
      Print("   • Max Gain: $", DoubleToString(m_maxDailyGain, 2));
      Print("   • Ação: ", action == PROFIT_ACTION_STOP ? "PARAR" : "ATIVAR DD");
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar limites de streak                           |
//+------------------------------------------------------------------+
void CBlockers::SetStreakLimits(int maxLoss, ENUM_STREAK_ACTION lossAction, int lossPause,
                                int maxWin, ENUM_STREAK_ACTION winAction, int winPause)
  {
   m_maxLossStreak = maxLoss;
   m_lossStreakAction = lossAction;
   m_lossPauseMinutes = lossPause;
   m_maxWinStreak = maxWin;
   m_winStreakAction = winAction;
   m_winPauseMinutes = winPause;

   if(m_logger != NULL)
     {
      m_logger.LogInfo("🔄 Limites de streak alterados:");
      m_logger.LogInfo("   • Loss: Max " + IntegerToString(maxLoss));
      m_logger.LogInfo("     └─ " + (lossAction == STREAK_PAUSE ? "Pausar " + IntegerToString(lossPause) + " min" : "Parar dia"));
      m_logger.LogInfo("   • Win: Max " + IntegerToString(maxWin));
      m_logger.LogInfo("     └─ " + (winAction == STREAK_PAUSE ? "Pausar " + IntegerToString(winPause) + " min" : "Parar dia"));
     }
   else
     {
      Print("🔄 Limites de streak alterados:");
      Print("   • Loss: Max ", maxLoss);
      Print("     └─ ", lossAction == STREAK_PAUSE ? "Pausar " + IntegerToString(lossPause) + " min" : "Parar dia");
      Print("   • Win: Max ", maxWin);
      Print("     └─ ", winAction == STREAK_PAUSE ? "Pausar " + IntegerToString(winPause) + " min" : "Parar dia");
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar valor de drawdown                           |
//+------------------------------------------------------------------+
void CBlockers::SetDrawdownValue(double newValue)
  {
   double oldValue = m_drawdownValue;
   m_drawdownValue = newValue;

   string typeText = (m_drawdownType == DD_FINANCIAL) ? "$" : "%";

   if(m_logger != NULL)
      m_logger.LogInfo(StringFormat("🔄 Drawdown alterado: %s%.2f → %s%.2f",
                                    typeText, oldValue, typeText, newValue));
   else
      Print("🔄 Drawdown alterado: ", typeText, oldValue, " → ", typeText, newValue);
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
   blockReason = "";

// ───────────────────────────────────────────────────────────────
// PROTEÇÃO DE SESSÃO - BLOQUEIA:
// 1) ANTES do fim (janela m_minutesBeforeSessionEnd)
// 2) DEPOIS do fim da sessão (até próxima sessão)
// ───────────────────────────────────────────────────────────────
   if(m_closeBeforeSessionEnd)
     {
      MqlDateTime now;
      TimeToStruct(TimeCurrent(), now);

      datetime sessionStart, sessionEnd;

      // Usa sessão de negociação da corretora (trade session)
      if(SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)now.day_of_week, 0,
                                sessionStart, sessionEnd))
        {
         MqlDateTime sessionStartTime, sessionEndTime;
         TimeToStruct(sessionStart, sessionStartTime);
         TimeToStruct(sessionEnd,   sessionEndTime);

         int currentMinutes    = now.hour           * 60 + now.min;
         int sessionStartMin   = sessionStartTime.hour * 60 + sessionStartTime.min;
         int sessionEndMin     = sessionEndTime.hour   * 60 + sessionEndTime.min;

         int deltaStart = currentMinutes - sessionStartMin; // <0 antes da sessão
         int deltaEnd   = sessionEndMin   - currentMinutes; // <0 depois da sessão

         // 0) ANTES da sessão de negociação abrir → bloquear tudo
         if(deltaStart < 0)
           {
            m_currentBlocker = BLOCKER_TIME_FILTER;
            blockReason = "Sessão de negociação ainda não iniciou";

            // v3.00: Usa throttle automático (1 log a cada 300s)
            if(m_logger != NULL)
              {
               string msg = StringFormat(
                  "═══════════════════════════════════════════════════════\n" +
                  "⏰ [Blockers] Sessão de negociação AINDA NÃO INICIOU\n" +
                  "   Sessão: %02d:%02d → %02d:%02d\n" +
                  "   Horário atual: %02d:%02d\n" +
                  "   Novas entradas bloqueadas até abertura da sessão\n" +
                  "═══════════════════════════════════════════════════════",
                  sessionStartTime.hour, sessionStartTime.min,
                  sessionEndTime.hour, sessionEndTime.min,
                  now.hour, now.min
               );
               m_logger.LogInfoThrottled("blocker_session_before", msg, 300);
              }

            return false;
           }

         // 1) DENTRO da sessão, mas na janela de proteção antes do fim
         if(deltaEnd >= 0 && deltaEnd <= m_minutesBeforeSessionEnd)
           {
            m_currentBlocker = BLOCKER_TIME_FILTER;
            blockReason = StringFormat(
                             "Proteção de sessão: faltam %d min (janela %d min)",
                             deltaEnd, m_minutesBeforeSessionEnd
                          );

            // v3.00: Usa throttle automático (1 log a cada 300s)
            if(m_logger != NULL)
              {
               string msg = StringFormat(
                  "═══════════════════════════════════════════════════════\n" +
                  "⏰ [Blockers] Proteção de Sessão - bloqueando novas entradas\n" +
                  "   Sessão encerra: %02d:%02d\n" +
                  "   Horário atual: %02d:%02d\n" +
                  "   Margem segurança: %d minutos\n" +
                  "   Faltam %d minutos para sessão encerrar\n" +
                  "═══════════════════════════════════════════════════════",
                  sessionEndTime.hour, sessionEndTime.min,
                  now.hour, now.min,
                  m_minutesBeforeSessionEnd,
                  deltaEnd
               );
               m_logger.LogInfoThrottled("blocker_session_window", msg, 300);
              }

            return false;
           }

         // 2) DEPOIS do fim da sessão → bloquear até próxima sessão
         if(deltaEnd < 0)
           {
            m_currentBlocker = BLOCKER_TIME_FILTER;
            blockReason = "Sessão de negociação encerrada";

            // v3.00: Usa throttle automático (1 log a cada 300s)
            if(m_logger != NULL)
              {
               string msg = StringFormat(
                  "═══════════════════════════════════════════════════════\n" +
                  "⏰ [Blockers] Sessão de negociação ENCERRADA\n" +
                  "   Sessão encerra: %02d:%02d\n" +
                  "   Horário atual: %02d:%02d\n" +
                  "   Novas entradas bloqueadas até próxima sessão\n" +
                  "═══════════════════════════════════════════════════════",
                  sessionEndTime.hour, sessionEndTime.min,
                  now.hour, now.min
               );
               m_logger.LogInfoThrottled("blocker_session_after", msg, 300);
              }

            return false;
           }
        }
     }

// Verificações
   if(!CheckTimeFilter())
     {
      m_currentBlocker = BLOCKER_TIME_FILTER;
      blockReason = "Fora do horário permitido";
      return false;
     }

   if(!CheckNewsFilter())
     {
      m_currentBlocker = BLOCKER_NEWS_FILTER;
      blockReason = "Horário de volatilidade";
      return false;
     }

   if(!CheckSpreadFilter())
     {
      m_currentBlocker = BLOCKER_SPREAD;
      long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      blockReason = StringFormat("Spread alto (%d > %d)", spread, m_maxSpread);
      return false;
     }

   if(!CheckStreakLimit())
     {
      if(m_currentWinStreak >= m_maxWinStreak && m_maxWinStreak > 0)
        {
         m_currentBlocker = BLOCKER_WIN_STREAK;
         blockReason = StringFormat("Win Streak de %d atingido", m_currentWinStreak);
        }
      else
        {
         m_currentBlocker = BLOCKER_LOSS_STREAK;
         blockReason = StringFormat("Loss Streak de %d atingido", m_currentLossStreak);
        }
      return false;
     }

   if(!CheckDailyLimits(dailyTrades, dailyProfit))
     {
      blockReason = GetBlockerReasonText(m_currentBlocker);
      return false;
     }

   if(m_enableDailyLimits &&
      m_maxDailyGain > 0 &&
      dailyProfit >= m_maxDailyGain &&
      m_profitTargetAction == PROFIT_ACTION_ENABLE_DRAWDOWN)
     {
      if(!m_drawdownProtectionActive)
        {
         ActivateDrawdownProtection(dailyProfit);
        }
     }

   if(!CheckDrawdownLimit())
     {
      m_currentBlocker = BLOCKER_DRAWDOWN;
      blockReason = StringFormat("Drawdown %.2f%% excedido", GetCurrentDrawdown());
      return false;
     }

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
//| PÚBLICO: Verifica se deve fechar posição por término de horário  |
//| ✅ v2.02: VALIDAÇÃO DE MAGIC NUMBER ADICIONADA                   |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseOnEndTime(ulong positionTicket)
  {
// Se filtro de horário ou fechamento no fim estiverem desativados, não faz nada
   if(!m_enableTimeFilter || !m_closeOnEndTime)
      return false;

// Garante que a posição existe
   if(!PositionSelectByTicket(positionTicket))
      return false;

// ✅ VALIDAR MAGIC NUMBER - CORREÇÃO CRÍTICA v2.02
   long posMagic = PositionGetInteger(POSITION_MAGIC);
   if(posMagic != m_magicNumber)
     {
      if(m_logger != NULL)
         m_logger.LogDebug("⏭️ [Blockers] Ignorando posição #" + IntegerToString((int)positionTicket) 
                         + " (Magic " + IntegerToString((int)posMagic) + " ≠ " 
                         + IntegerToString(m_magicNumber) + ")");
      return false;
     }

   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   int currentMinutes = dt.hour * 60 + dt.min;
   int startMinutes   = m_startHour * 60 + m_startMinute;
   int endMinutes     = m_endHour   * 60 + m_endMinute;

// ✅ CORREÇÃO: Só fecha se PASSOU do fim, não se está antes do início

// Janela normal no mesmo dia (ex.: 09:00–17:00)
   if(startMinutes <= endMinutes)
     {
      // Só fecha se passou do horário de fim
      if(currentMinutes > endMinutes)
        {
         if(m_logger != NULL)
           {
            m_logger.LogInfo("⏰ [Blockers] Término de horário de operação atingido");
            m_logger.LogInfo("   Início: " + IntegerToString(m_startHour) + ":" + IntegerToString(m_startMinute));
            m_logger.LogInfo("   Fim:    " + IntegerToString(m_endHour)   + ":" + IntegerToString(m_endMinute));
            m_logger.LogInfo("   Agora:  " + IntegerToString(dt.hour)     + ":" + IntegerToString(dt.min));
            m_logger.LogInfo("   Posição #" + IntegerToString((int)positionTicket) + " deve ser fechada por horário");
           }
         else
           {
            Print("⏰ [Blockers] Término de horário de operação atingido para posição #", positionTicket);
           }
         
         return true;
        }
      return false;
     }
// Janela que atravessa meia-noite (ex.: 22:00–02:00)
   else
     {
      // Está entre fim e início = FORA da janela = deve fechar
      if(currentMinutes > endMinutes && currentMinutes < startMinutes)
        {
         if(m_logger != NULL)
           {
            m_logger.LogInfo("⏰ [Blockers] Fora do horário de operação (janela noturna)");
            m_logger.LogInfo("   Janela: " + IntegerToString(m_startHour) + ":" + IntegerToString(m_startMinute)
                          + " - " + IntegerToString(m_endHour) + ":" + IntegerToString(m_endMinute));
            m_logger.LogInfo("   Agora:  " + IntegerToString(dt.hour) + ":" + IntegerToString(dt.min));
            m_logger.LogInfo("   Posição #" + IntegerToString((int)positionTicket) + " deve ser fechada");
           }
         else
           {
            Print("⏰ [Blockers] Fora do horário noturno para posição #", positionTicket);
           }
         
         return true;
        }
      return false;
     }
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição antes do fim da sessão           |
//| ✅ v2.02: VALIDAÇÃO DE MAGIC NUMBER ADICIONADA                   |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseBeforeSessionEnd(ulong positionTicket)
  {
// Se proteção de sessão estiver desativada, não faz nada
   if(!m_closeBeforeSessionEnd)
      return false;

// Garante que a posição existe
   if(!PositionSelectByTicket(positionTicket))
      return false;
      
// ✅ VALIDAR MAGIC NUMBER - CORREÇÃO CRÍTICA v2.02
   long posMagic = PositionGetInteger(POSITION_MAGIC);
   if(posMagic != m_magicNumber)
     {
      if(m_logger != NULL)
         m_logger.LogDebug("⏭️ [Blockers] Ignorando posição #" + IntegerToString((int)positionTicket) 
                         + " (Magic " + IntegerToString((int)posMagic) + " ≠ " 
                         + IntegerToString(m_magicNumber) + " na proteção de sessão)");
      return false;
     }      

// Obtém horário atual
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);

// Obtém informações da sessão de negociação do SÍMBOLO ATUAL
   datetime sessionStart, sessionEnd;

   if(!SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)now.day_of_week, 0, sessionStart, sessionEnd))
     {
      // Se falhar, pode ser fim de semana ou símbolo sem sessão definida
      return false;
     }

// Converte horário do fim da sessão
   MqlDateTime sessionEndTime;
   TimeToStruct(sessionEnd, sessionEndTime);

// Calcula minutos até o fim da sessão
   int currentMinutes     = now.hour * 60 + now.min;
   int sessionEndMinutes  = sessionEndTime.hour * 60 + sessionEndTime.min;

// Trata caso de sessão que cruza meia-noite
   if(sessionEndMinutes < currentMinutes)
      sessionEndMinutes += 24 * 60;

   int minutesUntilSessionEnd = sessionEndMinutes - currentMinutes;

// Se faltam X minutos ou menos para o fim da sessão
   if(minutesUntilSessionEnd <= m_minutesBeforeSessionEnd && minutesUntilSessionEnd >= 0)
     {
      if(m_logger != NULL)
        {
         m_logger.LogInfo("════════════════════════════════════════════════════════════════");
         m_logger.LogInfo("⏰ [Blockers] Proteção de Sessão ativada");
         m_logger.LogInfo(StringFormat("   Sessão encerra: %02d:%02d", sessionEndTime.hour, sessionEndTime.min));
         m_logger.LogInfo(StringFormat("   Horário atual: %02d:%02d", now.hour, now.min));
         m_logger.LogInfo(StringFormat("   Margem segurança: %d minutos", m_minutesBeforeSessionEnd));
         m_logger.LogInfo(StringFormat("   Faltam %d minutos para sessão encerrar", minutesUntilSessionEnd));
         m_logger.LogInfo("   Posição #" + IntegerToString((int)positionTicket) + " deve ser fechada por proteção de sessão");
         m_logger.LogInfo("════════════════════════════════════════════════════════════════");
        }
      else
        {
         Print("⏰ [Blockers] Proteção de Sessão ativada para posição #", positionTicket);
        }

      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Atualiza estado após um trade                                    |
//+------------------------------------------------------------------+
void CBlockers::UpdateAfterTrade(bool isWin, double tradeProfit)
  {
   if(m_enableStreakControl)
     {
      if(isWin)
        {
         m_currentWinStreak++;
         m_currentLossStreak = 0;

         if(m_maxWinStreak > 0 && m_currentWinStreak >= m_maxWinStreak)
           {
            string msg = "⚠️ WIN STREAK ATINGIDO: " + IntegerToString(m_currentWinStreak) + " ganhos consecutivos!";
            if(m_logger != NULL)
               m_logger.LogWarning(msg);
            else
               Print(msg);
           }
        }
      else
        {
         m_currentLossStreak++;
         m_currentWinStreak = 0;

         if(m_maxLossStreak > 0 && m_currentLossStreak >= m_maxLossStreak)
           {
            string msg = "⚠️ LOSS STREAK ATINGIDO: " + IntegerToString(m_currentLossStreak) + " perdas consecutivas!";
            if(m_logger != NULL)
               m_logger.LogWarning(msg);
            else
               Print(msg);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Atualiza pico de saldo (para cálculo de drawdown)                |
//+------------------------------------------------------------------+
void CBlockers::UpdatePeakBalance(double currentBalance)
  {
   if(!m_enableDrawdown)
      return;

   if(currentBalance > m_peakBalance)
      m_peakBalance = currentBalance;
  }

//+------------------------------------------------------------------+
//| Atualiza pico de lucro diário                                    |
//+------------------------------------------------------------------+
void CBlockers::UpdatePeakProfit(double currentProfit)
  {
   if(currentProfit > m_dailyPeakProfit)
      m_dailyPeakProfit = currentProfit;
  }

//+------------------------------------------------------------------+
//| Ativa proteção de drawdown (após atingir meta)                   |
//+------------------------------------------------------------------+
void CBlockers::ActivateDrawdownProtection(double peakProfit)
  {
   if(!m_enableDrawdown)
      return;

   m_drawdownProtectionActive = true;
   m_dailyPeakProfit = peakProfit;

   if(m_logger != NULL)
     {
      m_logger.LogInfo("═══════════════════════════════════════════════════════");
      m_logger.LogInfo("🛡️ PROTEÇÃO DE DRAWDOWN ATIVADA!");
      m_logger.LogInfo("   Pico de lucro: $" + DoubleToString(peakProfit, 2));

      if(m_drawdownType == DD_FINANCIAL)
         m_logger.LogInfo("   Proteção: Máx $" + DoubleToString(m_drawdownValue, 2) + " de drawdown");
      else
         m_logger.LogInfo("   Proteção: Máx " + DoubleToString(m_drawdownValue, 1) + "% de drawdown");

      m_logger.LogInfo("═══════════════════════════════════════════════════════");
     }
   else
     {
      Print("═══════════════════════════════════════════════════════");
      Print("🛡️ PROTEÇÃO DE DRAWDOWN ATIVADA!");
      Print("   Pico de lucro: $", DoubleToString(peakProfit, 2));

      if(m_drawdownType == DD_FINANCIAL)
         Print("   Proteção: Máx $", DoubleToString(m_drawdownValue, 2), " de drawdown");
      else
         Print("   Proteção: Máx ", DoubleToString(m_drawdownValue, 1), "% de drawdown");

      Print("═══════════════════════════════════════════════════════");
     }
  }

//+------------------------------------------------------------------+
//| Reset diário (limpa contadores)                                  |
//+------------------------------------------------------------------+
void CBlockers::ResetDaily()
  {
   if(m_logger != NULL)
      m_logger.LogInfo("🔄 RESET DIÁRIO - Limpando contadores...");
   else
      Print("🔄 RESET DIÁRIO - Limpando contadores...");

   m_currentLossStreak = 0;
   m_currentWinStreak = 0;
   m_streakPauseActive = false;
   m_streakPauseUntil = 0;
   m_streakPauseReason = "";
   m_dailyPeakProfit = 0.0;
   m_drawdownProtectionActive = false;
   m_drawdownLimitReached = false;
   m_currentBlocker = BLOCKER_NONE;
   m_lastResetDate = TimeCurrent();

   if(m_logger != NULL)
      m_logger.LogInfo("✅ Contadores zerados!");
   else
      Print("✅ Contadores zerados!");
  }

//+------------------------------------------------------------------+
//| Calcula drawdown atual                                           |
//+------------------------------------------------------------------+
double CBlockers::GetCurrentDrawdown()
  {
   if(!m_drawdownProtectionActive || m_dailyPeakProfit <= 0)
      return 0.0;

   double currentProfit = AccountInfoDouble(ACCOUNT_BALANCE) - m_initialBalance;

   if(currentProfit >= m_dailyPeakProfit)
      return 0.0;

   double dd = ((m_dailyPeakProfit - currentProfit) / m_dailyPeakProfit) * 100.0;
   return dd;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica filtro de horário                              |
//+------------------------------------------------------------------+
bool CBlockers::CheckTimeFilter()
  {
   if(!m_enableTimeFilter)
      return true;

   datetime now = TimeCurrent();
   MqlDateTime timeStruct;
   TimeToStruct(now, timeStruct);

   int currentMinutes = timeStruct.hour * 60 + timeStruct.min;
   int startMinutes = m_startHour * 60 + m_startMinute;
   int endMinutes = m_endHour * 60 + m_endMinute;

   if(startMinutes < endMinutes)
     {
      return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);
     }

   return (currentMinutes >= startMinutes || currentMinutes <= endMinutes);
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica news filters                                   |
//+------------------------------------------------------------------+
bool CBlockers::CheckNewsFilter()
  {
   if(!m_enableNewsFilter1 && !m_enableNewsFilter2 && !m_enableNewsFilter3)
      return true;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int currentMinutes = dt.hour * 60 + dt.min;

   if(m_enableNewsFilter1)
     {
      int newsStart1 = m_newsStart1Hour * 60 + m_newsStart1Minute;
      int newsEnd1 = m_newsEnd1Hour * 60 + m_newsEnd1Minute;

      if(newsStart1 < newsEnd1)
        {
         if(currentMinutes >= newsStart1 && currentMinutes <= newsEnd1)
            return false;
        }
     }

   if(m_enableNewsFilter2)
     {
      int newsStart2 = m_newsStart2Hour * 60 + m_newsStart2Minute;
      int newsEnd2 = m_newsEnd2Hour * 60 + m_newsEnd2Minute;

      if(newsStart2 < newsEnd2)
        {
         if(currentMinutes >= newsStart2 && currentMinutes <= newsEnd2)
            return false;
        }
     }

   if(m_enableNewsFilter3)
     {
      int newsStart3 = m_newsStart3Hour * 60 + m_newsStart3Minute;
      int newsEnd3 = m_newsEnd3Hour * 60 + m_newsEnd3Minute;

      if(newsStart3 < newsEnd3)
        {
         if(currentMinutes >= newsStart3 && currentMinutes <= newsEnd3)
            return false;
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica filtro de spread                               |
//+------------------------------------------------------------------+
bool CBlockers::CheckSpreadFilter()
  {
   if(m_maxSpread <= 0)
      return true;

   long spreadPoints = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

   if(spreadPoints > m_maxSpread)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica limites diários                                |
//+------------------------------------------------------------------+
bool CBlockers::CheckDailyLimits(int dailyTrades, double dailyProfit)
  {
   if(!m_enableDailyLimits)
      return true;

   if(m_maxDailyTrades > 0 && dailyTrades >= m_maxDailyTrades)
     {
      m_currentBlocker = BLOCKER_DAILY_TRADES;
      return false;
     }

   if(m_maxDailyLoss > 0 && dailyProfit <= -m_maxDailyLoss)
     {
      m_currentBlocker = BLOCKER_DAILY_LOSS;
      return false;
     }

   if(m_maxDailyGain > 0 && dailyProfit >= m_maxDailyGain)
     {
      if(m_profitTargetAction == PROFIT_ACTION_STOP)
        {
         m_currentBlocker = BLOCKER_DAILY_GAIN;
         return false;
        }
      else
        {
         if(!m_drawdownProtectionActive)
           {
            ActivateDrawdownProtection(dailyProfit);
           }
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica limite de streak                               |
//+------------------------------------------------------------------+
bool CBlockers::CheckStreakLimit()
  {
   if(!m_enableStreakControl)
      return true;

   if(m_streakPauseActive)
     {
      if(TimeCurrent() < m_streakPauseUntil)
        {
         if(TimeCurrent() - m_lastStreakWarning > 300)
           {
            int remainingMinutes = (int)((m_streakPauseUntil - TimeCurrent()) / 60);

            if(m_logger != NULL)
              {
               m_logger.LogWarning("═══════════════════════════════════════════════════════");
               m_logger.LogWarning("⏸️ EA PAUSADO POR SEQUÊNCIA");
               m_logger.LogWarning("   📊 Motivo: " + m_streakPauseReason);
               m_logger.LogWarning("   ⏱️ Tempo restante: " + IntegerToString(remainingMinutes) + " minutos");
               m_logger.LogWarning("═══════════════════════════════════════════════════════");
              }
            else
              {
               Print("═══════════════════════════════════════════════════════");
               Print("⏸️ EA PAUSADO POR SEQUÊNCIA");
               Print("   📊 Motivo: ", m_streakPauseReason);
               Print("   ⏱️ Tempo restante: ", remainingMinutes, " minutos");
               Print("═══════════════════════════════════════════════════════");
              }
            m_lastStreakWarning = TimeCurrent();
           }
         return false;
        }
      else
        {
         if(m_logger != NULL)
           {
            m_logger.LogInfo("═══════════════════════════════════════════════════════");
            m_logger.LogInfo("▶️ PAUSA DE SEQUÊNCIA FINALIZADA");
            m_logger.LogInfo("   📊 Sequência que causou pausa: " + m_streakPauseReason);
            m_logger.LogInfo("   🔄 Contadores zerados - pronto para novo ciclo");
            m_logger.LogInfo("   ✅ EA retomando operações normais");
            m_logger.LogInfo("═══════════════════════════════════════════════════════");
           }
         else
           {
            Print("═══════════════════════════════════════════════════════");
            Print("▶️ PAUSA DE SEQUÊNCIA FINALIZADA");
            Print("   📊 Sequência que causou pausa: ", m_streakPauseReason);
            Print("   🔄 Contadores zerados - pronto para novo ciclo");
            Print("   ✅ EA retomando operações normais");
            Print("═══════════════════════════════════════════════════════");
           }

         m_streakPauseActive = false;
         m_streakPauseReason = "";
         m_currentWinStreak = 0;
         m_currentLossStreak = 0;

         return true;
        }
     }

   if(m_maxLossStreak > 0 && m_currentLossStreak >= m_maxLossStreak)
     {
      if(m_logger != NULL)
        {
         m_logger.LogWarning("═══════════════════════════════════════════════════════");
         m_logger.LogWarning("🛑 SEQUÊNCIA DE PERDAS ATINGIDA!");
         m_logger.LogWarning("   📉 Perdas consecutivas: " + IntegerToString(m_currentLossStreak));
         m_logger.LogWarning("   🎯 Limite configurado: " + IntegerToString(m_maxLossStreak));
        }
      else
        {
         Print("═══════════════════════════════════════════════════════");
         Print("🛑 SEQUÊNCIA DE PERDAS ATINGIDA!");
         Print("   📉 Perdas consecutivas: ", m_currentLossStreak);
         Print("   🎯 Limite configurado: ", m_maxLossStreak);
        }

      if(m_lossStreakAction == STREAK_PAUSE)
        {
         m_streakPauseActive = true;
         m_streakPauseUntil = TimeCurrent() + (m_lossPauseMinutes * 60);
         m_streakPauseReason = StringFormat("%d perdas consecutivas", m_currentLossStreak);

         if(m_logger != NULL)
           {
            m_logger.LogWarning("   ⏸️ EA PAUSADO por " + IntegerToString(m_lossPauseMinutes) + " minutos");
            m_logger.LogWarning("   🔄 Retorno previsto: " + TimeToString(m_streakPauseUntil, TIME_DATE|TIME_MINUTES));
           }
         else
           {
            Print("   ⏸️ EA PAUSADO por ", m_lossPauseMinutes, " minutos");
            Print("   🔄 Retorno previsto: ", TimeToString(m_streakPauseUntil, TIME_DATE|TIME_MINUTES));
           }
        }
      else
        {
         if(m_logger != NULL)
            m_logger.LogWarning("   🛑 EA PAUSADO até o FIM DO DIA");
         else
            Print("   🛑 EA PAUSADO até o FIM DO DIA");
        }

      if(m_logger != NULL)
         m_logger.LogWarning("═══════════════════════════════════════════════════════");
      else
         Print("═══════════════════════════════════════════════════════");

      return false;
     }

   if(m_maxWinStreak > 0 && m_currentWinStreak >= m_maxWinStreak)
     {
      if(m_logger != NULL)
        {
         m_logger.LogWarning("═══════════════════════════════════════════════════════");
         m_logger.LogWarning("🎯 SEQUÊNCIA DE GANHOS ATINGIDA!");
         m_logger.LogWarning("   📈 Ganhos consecutivos: " + IntegerToString(m_currentWinStreak));
         m_logger.LogWarning("   🎯 Limite configurado: " + IntegerToString(m_maxWinStreak));
        }
      else
        {
         Print("═══════════════════════════════════════════════════════");
         Print("🎯 SEQUÊNCIA DE GANHOS ATINGIDA!");
         Print("   📈 Ganhos consecutivos: ", m_currentWinStreak);
         Print("   🎯 Limite configurado: ", m_maxWinStreak);
        }

      if(m_winStreakAction == STREAK_PAUSE)
        {
         m_streakPauseActive = true;
         m_streakPauseUntil = TimeCurrent() + (m_winPauseMinutes * 60);
         m_streakPauseReason = StringFormat("%d ganhos consecutivos", m_currentWinStreak);

         if(m_logger != NULL)
           {
            m_logger.LogWarning("   ⏸️ EA PAUSADO por " + IntegerToString(m_winPauseMinutes) + " minutos");
            m_logger.LogWarning("   🔄 Retorno previsto: " + TimeToString(m_streakPauseUntil, TIME_DATE|TIME_MINUTES));
           }
         else
           {
            Print("   ⏸️ EA PAUSADO por ", m_winPauseMinutes, " minutos");
            Print("   🔄 Retorno previsto: ", TimeToString(m_streakPauseUntil, TIME_DATE|TIME_MINUTES));
           }
        }
      else
        {
         if(m_logger != NULL)
           {
            m_logger.LogWarning("   🎯 META DE SEQUÊNCIA ATINGIDA!");
            m_logger.LogWarning("   🛑 EA PAUSADO até o FIM DO DIA");
           }
         else
           {
            Print("   🎯 META DE SEQUÊNCIA ATINGIDA!");
            Print("   🛑 EA PAUSADO até o FIM DO DIA");
           }
        }

      if(m_logger != NULL)
         m_logger.LogWarning("═══════════════════════════════════════════════════════");
      else
         Print("═══════════════════════════════════════════════════════");

      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica limite de drawdown                             |
//+------------------------------------------------------------------+
bool CBlockers::CheckDrawdownLimit()
  {
   if(!m_drawdownProtectionActive)
      return true;

   if(m_drawdownLimitReached)
      return false;

   double currentProfit = AccountInfoDouble(ACCOUNT_BALANCE) - m_initialBalance;

   if(currentProfit > m_dailyPeakProfit)
      m_dailyPeakProfit = currentProfit;

   double currentDD = m_dailyPeakProfit - currentProfit;
   double ddLimit = 0;

   if(m_drawdownType == DD_FINANCIAL)
     {
      ddLimit = m_drawdownValue;
     }
   else
     {
      ddLimit = (m_dailyPeakProfit * m_drawdownValue) / 100.0;
     }

   if(currentDD >= ddLimit)
     {
      m_drawdownLimitReached = true;

      if(m_logger != NULL)
        {
         m_logger.LogWarning("═══════════════════════════════════════════════════════");
         m_logger.LogWarning("🛑 LIMITE DE DRAWDOWN ATINGIDO!");
         m_logger.LogWarning("   📊 Pico do dia: $" + DoubleToString(m_dailyPeakProfit, 2));
         m_logger.LogWarning("   💰 Lucro atual: $" + DoubleToString(currentProfit, 2));
         m_logger.LogWarning("   📉 Drawdown: $" + DoubleToString(currentDD, 2));

         if(m_drawdownType == DD_FINANCIAL)
            m_logger.LogWarning("   🛑 Limite: $" + DoubleToString(ddLimit, 2) + " (Financeiro)");
         else
            m_logger.LogWarning("   🛑 Limite: " + DoubleToString(m_drawdownValue, 1) + "% = $" + DoubleToString(ddLimit, 2));

         m_logger.LogWarning("   🛡️ LUCRO PROTEGIDO! EA pausado até o fim do dia");
         m_logger.LogWarning("═══════════════════════════════════════════════════════");
        }
      else
        {
         Print("═══════════════════════════════════════════════════════");
         Print("🛑 LIMITE DE DRAWDOWN ATINGIDO!");
         Print("   📊 Pico do dia: $", DoubleToString(m_dailyPeakProfit, 2));
         Print("   💰 Lucro atual: $", DoubleToString(currentProfit, 2));
         Print("   📉 Drawdown: $", DoubleToString(currentDD, 2));

         if(m_drawdownType == DD_FINANCIAL)
            Print("   🛑 Limite: $", DoubleToString(ddLimit, 2), " (Financeiro)");
         else
            Print("   🛑 Limite: ", DoubleToString(m_drawdownValue, 1), "% = $", DoubleToString(ddLimit, 2));

         Print("   🛡️ LUCRO PROTEGIDO! EA pausado até o fim do dia");
         Print("═══════════════════════════════════════════════════════");
        }

      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica se direção é permitida                         |
//+------------------------------------------------------------------+
bool CBlockers::CheckDirectionAllowed(int orderType)
  {
   if(m_tradeDirection == DIRECTION_BOTH)
      return true;

   if(m_tradeDirection == DIRECTION_BUY_ONLY && orderType == ORDER_TYPE_SELL)
      return false;

   if(m_tradeDirection == DIRECTION_SELL_ONLY && orderType == ORDER_TYPE_BUY)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica se é um novo dia                               |
//+------------------------------------------------------------------+
bool CBlockers::IsNewDay()
  {
   datetime now = TimeCurrent();

   MqlDateTime lastDate, currentDate;
   TimeToStruct(m_lastResetDate, lastDate);
   TimeToStruct(now, currentDate);

   return (lastDate.year != currentDate.year ||
           lastDate.mon != currentDate.mon ||
           lastDate.day != currentDate.day);
  }

//+------------------------------------------------------------------+
//| PRIVADO: Converte enum de bloqueio em texto                      |
//+------------------------------------------------------------------+
string CBlockers::GetBlockerReasonText(ENUM_BLOCKER_REASON reason)
  {
   switch(reason)
     {
      case BLOCKER_NONE:
         return "Sem bloqueio";
      case BLOCKER_TIME_FILTER:
         return "Fora do horário";
      case BLOCKER_NEWS_FILTER:
         return "Horário de volatilidade";
      case BLOCKER_SPREAD:
         return "Spread alto";
      case BLOCKER_DAILY_TRADES:
         return "Limite de trades diários";
      case BLOCKER_DAILY_LOSS:
         return "Perda diária máxima";
      case BLOCKER_DAILY_GAIN:
         return "Ganho diário máximo";
      case BLOCKER_LOSS_STREAK:
         return "Sequência de perdas";
      case BLOCKER_WIN_STREAK:
         return "Sequência de ganhos";
      case BLOCKER_DRAWDOWN:
         return "Drawdown máximo";
      case BLOCKER_DIRECTION:
         return "Direção bloqueada";
      default:
         return "Bloqueio desconhecido";
     }
  }

//+------------------------------------------------------------------+
//| Imprime status atual                                             |
//+------------------------------------------------------------------+
void CBlockers::PrintStatus()
  {
   if(m_logger != NULL)
     {
      m_logger.LogInfo("╔══════════════════════════════════════════════════════╗");
      m_logger.LogInfo("║            BLOCKERS - STATUS ATUAL                   ║");
      m_logger.LogInfo("╚══════════════════════════════════════════════════════╝");
      m_logger.LogInfo("");
     }
   else
     {
      Print("╔══════════════════════════════════════════════════════╗");
      Print("║            BLOCKERS - STATUS ATUAL                   ║");
      Print("╚══════════════════════════════════════════════════════╝");
      Print("");
     }

   if(m_currentBlocker != BLOCKER_NONE)
     {
      string msg = "🚫 BLOQUEADO: " + GetBlockerReasonText(m_currentBlocker);
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print(msg);
     }
   else
     {
      if(m_logger != NULL)
         m_logger.LogInfo("✅ LIBERADO PARA OPERAR");
      else
         Print("✅ LIBERADO PARA OPERAR");
     }

   if(m_logger != NULL)
      m_logger.LogInfo("");
   else
      Print("");

   if(m_enableTimeFilter)
     {
      datetime now = TimeCurrent();
      MqlDateTime t;
      TimeToStruct(now, t);

      if(m_logger != NULL)
        {
         m_logger.LogInfo("⏰ Horário:");
         m_logger.LogInfo("   Atual: " + StringFormat("%02d:%02d", t.hour, t.min));
         m_logger.LogInfo("   Permitido: " + StringFormat("%02d:%02d - %02d:%02d",
                          m_startHour, m_startMinute, m_endHour, m_endMinute));
         m_logger.LogInfo("   Status: " + (CheckTimeFilter() ? "✅ OK" : "❌ BLOQUEADO"));
        }
      else
        {
         Print("⏰ Horário:");
         Print("   Atual: ", StringFormat("%02d:%02d", t.hour, t.min));
         Print("   Permitido: ", StringFormat("%02d:%02d - %02d:%02d",
                                              m_startHour, m_startMinute, m_endHour, m_endMinute));
         Print("   Status: ", CheckTimeFilter() ? "✅ OK" : "❌ BLOQUEADO");
        }
     }

   if(m_enableStreakControl)
     {
      if(m_logger != NULL)
        {
         m_logger.LogInfo("");
         m_logger.LogInfo("🔴 Streaks:");
         if(m_maxLossStreak > 0)
            m_logger.LogInfo("   Loss: " + IntegerToString(m_currentLossStreak) + " de " + IntegerToString(m_maxLossStreak));
         if(m_maxWinStreak > 0)
            m_logger.LogInfo("   Win: " + IntegerToString(m_currentWinStreak) + " de " + IntegerToString(m_maxWinStreak));

         if(m_streakPauseActive)
           {
            int remaining = (int)((m_streakPauseUntil - TimeCurrent()) / 60);
            m_logger.LogWarning("   ⏸️ PAUSADO: " + m_streakPauseReason + " (" + IntegerToString(remaining) + " min)");
           }
        }
      else
        {
         Print("");
         Print("🔴 Streaks:");
         if(m_maxLossStreak > 0)
            Print("   Loss: ", m_currentLossStreak, " de ", m_maxLossStreak);
         if(m_maxWinStreak > 0)
            Print("   Win: ", m_currentWinStreak, " de ", m_maxWinStreak);

         if(m_streakPauseActive)
           {
            int remaining = (int)((m_streakPauseUntil - TimeCurrent()) / 60);
            Print("   ⏸️ PAUSADO: ", m_streakPauseReason, " (", remaining, " min)");
           }
        }
     }

   if(m_drawdownProtectionActive)
     {
      double currentProfit = AccountInfoDouble(ACCOUNT_BALANCE) - m_initialBalance;
      double currentDD = m_dailyPeakProfit - currentProfit;

      if(m_logger != NULL)
        {
         m_logger.LogInfo("");
         m_logger.LogInfo("📉 Drawdown (proteção ativa):");
         m_logger.LogInfo("   Pico: $" + DoubleToString(m_dailyPeakProfit, 2));
         m_logger.LogInfo("   Atual: $" + DoubleToString(currentProfit, 2));
         m_logger.LogInfo("   DD: $" + DoubleToString(currentDD, 2));
         m_logger.LogInfo("   Status: " + (m_drawdownLimitReached ? "❌ LIMITE ATINGIDO" : "✅ OK"));
        }
      else
        {
         Print("");
         Print("📉 Drawdown (proteção ativa):");
         Print("   Pico: $", DoubleToString(m_dailyPeakProfit, 2));
         Print("   Atual: $", DoubleToString(currentProfit, 2));
         Print("   DD: $", DoubleToString(currentDD, 2));
         Print("   Status: ", m_drawdownLimitReached ? "❌ LIMITE ATINGIDO" : "✅ OK");
        }
     }

   if(m_logger != NULL)
     {
      m_logger.LogInfo("");
      m_logger.LogInfo("═══════════════════════════════════════════════════════");
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
      m_logger.LogInfo("╔══════════════════════════════════════════════════════╗");
      m_logger.LogInfo("║         BLOCKERS - CONFIGURAÇÃO COMPLETA            ║");
      m_logger.LogInfo("╚══════════════════════════════════════════════════════╝");
      m_logger.LogInfo("");
     }
   else
     {
      Print("╔══════════════════════════════════════════════════════╗");
      Print("║         BLOCKERS - CONFIGURAÇÃO COMPLETA            ║");
      Print("╚══════════════════════════════════════════════════════╝");
      Print("");
     }

   if(m_logger != NULL)
      m_logger.LogInfo("⏰ Horário:");
   else
      Print("⏰ Horário:");

   if(m_enableTimeFilter)
     {
      string msg = "   " + StringFormat("%02d:%02d - %02d:%02d",
                                        m_startHour, m_startMinute, m_endHour, m_endMinute);
      if(m_logger != NULL)
        {
         m_logger.LogInfo(msg);
         m_logger.LogInfo("   Fecha ao fim: " + (m_closeOnEndTime ? "SIM" : "NÃO"));
        }
      else
        {
         Print(msg);
         Print("   Fecha ao fim: ", m_closeOnEndTime ? "SIM" : "NÃO");
        }
     }
   else
     {
      if(m_logger != NULL)
         m_logger.LogInfo("   DESATIVADO");
      else
         Print("   DESATIVADO");
     }

   if(m_logger != NULL)
     {
      m_logger.LogInfo("");
      m_logger.LogInfo("═══════════════════════════════════════════════════════");
     }
   else
     {
      Print("");
      Print("═══════════════════════════════════════════════════════");
     }
  }
//+------------------------------------------------------------------+
