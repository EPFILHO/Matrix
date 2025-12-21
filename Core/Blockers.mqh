//+------------------------------------------------------------------+
//|                                                     Blockers.mqh |
//|                                         Copyright 2025, EP Filho |
//|                        Sistema de Bloqueios - EPBot Matrix       |
//|                           VERSÃO COMPLETA - Todas Features       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EP Filho"
#property version   "2.00"
#property strict

//+------------------------------------------------------------------+
//| Enumerações - Importadas do EPBot anterior                       |
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
   // CONFIGURAÇÕES DE HORÁRIO
   // ═══════════════════════════════════════════════════════════════
   bool              m_enableTimeFilter;      // Ativar filtro de horário
   int               m_startHour;             // Hora de início (0-23)
   int               m_startMinute;           // Minuto de início (0-59)
   int               m_endHour;               // Hora de término (0-23)
   int               m_endMinute;             // Minuto de término (0-59)
   bool              m_closeOnEndTime;        // Fechar posição ao fim do horário
   
   // ═══════════════════════════════════════════════════════════════
   // CONFIGURAÇÕES DE NEWS FILTERS (3 bloqueios)
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
   // CONFIGURAÇÕES DE SPREAD
   // ═══════════════════════════════════════════════════════════════
   int               m_maxSpread;             // Spread máximo em pontos (0=ilimitado)
   
   // ═══════════════════════════════════════════════════════════════
   // CONFIGURAÇÕES DE LIMITES DIÁRIOS
   // ═══════════════════════════════════════════════════════════════
   bool              m_enableDailyLimits;     // Ativar limites diários
   int               m_maxDailyTrades;        // Máximo de trades por dia (0=ilimitado)
   double            m_maxDailyLoss;          // Perda máxima diária (0=ilimitado)
   double            m_maxDailyGain;          // Ganho máximo diário (0=ilimitado)
   ENUM_PROFIT_TARGET_ACTION m_profitTargetAction;  // Ação ao atingir meta
   
   // ═══════════════════════════════════════════════════════════════
   // CONFIGURAÇÕES DE STREAK (SEQUÊNCIA)
   // ═══════════════════════════════════════════════════════════════
   bool              m_enableStreakControl;   // Ativar controle de sequência
   
   // Loss Streak
   int               m_maxLossStreak;         // Máx. perdas consecutivas (0=ilimitado)
   ENUM_STREAK_ACTION m_lossStreakAction;     // Ação após atingir loss streak
   int               m_lossPauseMinutes;      // Minutos de pausa (se STREAK_PAUSE)
   
   // Win Streak
   int               m_maxWinStreak;          // Máx. ganhos consecutivos (0=ilimitado)
   ENUM_STREAK_ACTION m_winStreakAction;      // Ação após atingir win streak
   int               m_winPauseMinutes;       // Minutos de pausa (se STREAK_PAUSE)
   
   // ═══════════════════════════════════════════════════════════════
   // CONFIGURAÇÕES DE DRAWDOWN
   // ═══════════════════════════════════════════════════════════════
   bool              m_enableDrawdown;        // Ativar proteção drawdown
   ENUM_DRAWDOWN_TYPE m_drawdownType;         // Tipo (financeiro ou %)
   double            m_drawdownValue;         // Valor do drawdown
   double            m_initialBalance;        // Saldo inicial de referência
   double            m_peakBalance;           // Pico de saldo (para DD)
   
   // ═══════════════════════════════════════════════════════════════
   // CONFIGURAÇÕES DE DIREÇÃO
   // ═══════════════════════════════════════════════════════════════
   ENUM_TRADE_DIRECTION m_tradeDirection;     // Direção permitida
   
   // ═══════════════════════════════════════════════════════════════
   // ESTADO INTERNO
   // ═══════════════════════════════════════════════════════════════
   int               m_currentLossStreak;     // Sequência atual de perdas
   int               m_currentWinStreak;      // Sequência atual de ganhos
   bool              m_streakPauseActive;     // EA está pausado por streak?
   datetime          m_streakPauseUntil;      // Até quando está pausado
   string            m_streakPauseReason;     // Motivo da pausa
   
   double            m_dailyPeakProfit;       // Maior lucro do dia
   bool              m_drawdownProtectionActive; // Proteção DD ativada?
   bool              m_drawdownLimitReached;  // Atingiu limite de DD?
   
   datetime          m_lastResetDate;         // Data do último reset diário
   ENUM_BLOCKER_REASON m_currentBlocker;      // Bloqueador ativo atual
   
   // Throttles para logs
   datetime          m_lastStreakWarning;
   datetime          m_lastNewsWarning;
   datetime          m_lastTimeWarning;
   datetime          m_lastDailyLimitWarning;
   
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
                         // Horário
                         bool enableTime, int startH, int startM, int endH, int endM, bool closeOnEnd,
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
   
   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS DE ATUALIZAÇÃO DE ESTADO
   // ═══════════════════════════════════════════════════════════════
   void              UpdateAfterTrade(bool isWin, double tradeProfit);
   void              UpdatePeakBalance(double currentBalance);
   void              UpdatePeakProfit(double currentProfit);
   void              ActivateDrawdownProtection(double peakProfit);
   void              ResetDaily();
   
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
   // MÉTODOS DE DEBUG/INFO
   // ═══════════════════════════════════════════════════════════════
   void              PrintStatus();
   void              PrintConfiguration();
  };

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CBlockers::CBlockers()
  {
   // Inicializar com valores padrão seguros
   m_enableTimeFilter = false;
   m_startHour = 9;
   m_startMinute = 0;
   m_endHour = 17;
   m_endMinute = 0;
   m_closeOnEndTime = false;
   
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
   
   m_maxSpread = 0;
   
   m_enableDailyLimits = false;
   m_maxDailyTrades = 0;
   m_maxDailyLoss = 0.0;
   m_maxDailyGain = 0.0;
   m_profitTargetAction = PROFIT_ACTION_STOP;
   
   m_enableStreakControl = false;
   m_maxLossStreak = 0;
   m_lossStreakAction = STREAK_PAUSE;
   m_lossPauseMinutes = 30;
   m_maxWinStreak = 0;
   m_winStreakAction = STREAK_STOP_DAY;
   m_winPauseMinutes = 0;
   
   m_enableDrawdown = false;
   m_drawdownType = DD_FINANCIAL;
   m_drawdownValue = 0.0;
   m_initialBalance = 0.0;
   m_peakBalance = 0.0;
   
   m_tradeDirection = DIRECTION_BOTH;
   
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
   
   m_lastStreakWarning = 0;
   m_lastNewsWarning = 0;
   m_lastTimeWarning = 0;
   m_lastDailyLimitWarning = 0;
  }

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CBlockers::~CBlockers()
  {
   // Nada a fazer por enquanto
  }

//+------------------------------------------------------------------+
//| Inicialização do módulo                                          |
//+------------------------------------------------------------------+
bool CBlockers::Init(
   bool enableTime, int startH, int startM, int endH, int endM, bool closeOnEnd,
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
   Print("╔══════════════════════════════════════════════════════╗");
   Print("║        EPBOT MATRIX - INICIALIZANDO BLOCKERS        ║");
   Print("║              VERSÃO COMPLETA v2.00                   ║");
   Print("╚══════════════════════════════════════════════════════╝");
   
   // ───────────────────────────────────────────────────────────────
   // HORÁRIO
   // ───────────────────────────────────────────────────────────────
   m_enableTimeFilter = enableTime;
   m_closeOnEndTime = closeOnEnd;
   
   if(enableTime)
     {
      if(startH < 0 || startH > 23 || endH < 0 || endH > 23 ||
         startM < 0 || startM > 59 || endM < 0 || endM > 59)
        {
         Print("❌ Horários inválidos!");
         return false;
        }
      
      m_startHour = startH;
      m_startMinute = startM;
      m_endHour = endH;
      m_endMinute = endM;
      
      Print("⏰ Filtro de Horário: ", 
            StringFormat("%02d:%02d - %02d:%02d", startH, startM, endH, endM));
      if(closeOnEnd)
         Print("   └─ Fecha posição ao fim do horário");
     }
   else
     {
      Print("⏰ Filtro de Horário: DESATIVADO");
     }
   
   // ───────────────────────────────────────────────────────────────
   // NEWS FILTERS
   // ───────────────────────────────────────────────────────────────
   m_enableNewsFilter1 = news1;
   m_newsStart1Hour = n1StartH;
   m_newsStart1Minute = n1StartM;
   m_newsEnd1Hour = n1EndH;
   m_newsEnd1Minute = n1EndM;
   
   m_enableNewsFilter2 = news2;
   m_newsStart2Hour = n2StartH;
   m_newsStart2Minute = n2StartM;
   m_newsEnd2Hour = n2EndH;
   m_newsEnd2Minute = n2EndM;
   
   m_enableNewsFilter3 = news3;
   m_newsStart3Hour = n3StartH;
   m_newsStart3Minute = n3StartM;
   m_newsEnd3Hour = n3EndH;
   m_newsEnd3Minute = n3EndM;
   
   if(news1 || news2 || news3)
     {
      Print("📰 Horários de Volatilidade:");
      if(news1)
         Print("   • Bloqueio 1: ", StringFormat("%02d:%02d - %02d:%02d", n1StartH, n1StartM, n1EndH, n1EndM));
      if(news2)
         Print("   • Bloqueio 2: ", StringFormat("%02d:%02d - %02d:%02d", n2StartH, n2StartM, n2EndH, n2EndM));
      if(news3)
         Print("   • Bloqueio 3: ", StringFormat("%02d:%02d - %02d:%02d", n3StartH, n3StartM, n3EndH, n3EndM));
     }
   else
     {
      Print("📰 Horários de Volatilidade: DESATIVADOS");
     }
   
   // ───────────────────────────────────────────────────────────────
   // SPREAD
   // ───────────────────────────────────────────────────────────────
   m_maxSpread = maxSpread;
   
   if(maxSpread > 0)
      Print("📊 Spread Máximo: ", maxSpread, " pontos");
   else
      Print("📊 Spread Máximo: ILIMITADO");
   
   // ───────────────────────────────────────────────────────────────
   // LIMITES DIÁRIOS
   // ───────────────────────────────────────────────────────────────
   m_enableDailyLimits = enableLimits;
   m_profitTargetAction = profitAction;
   
   if(enableLimits)
     {
      m_maxDailyTrades = maxTrades;
      m_maxDailyLoss = MathAbs(maxLoss);
      m_maxDailyGain = MathAbs(maxGain);
      
      Print("📅 Limites Diários:");
      if(maxTrades > 0)
         Print("   - Max Trades: ", maxTrades);
      if(maxLoss != 0)
         Print("   - Max Loss: $", DoubleToString(m_maxDailyLoss, 2));
      if(maxGain != 0)
        {
         Print("   - Max Gain: $", DoubleToString(m_maxDailyGain, 2));
         if(profitAction == PROFIT_ACTION_STOP)
            Print("     └─ Ação: PARAR ao atingir meta");
         else
            Print("     └─ Ação: ATIVAR proteção de drawdown");
        }
     }
   else
     {
      Print("📅 Limites Diários: DESATIVADOS");
     }
   
   // ───────────────────────────────────────────────────────────────
   // STREAK
   // ───────────────────────────────────────────────────────────────
   m_enableStreakControl = enableStreak;
   
   if(enableStreak)
     {
      // Loss Streak
      m_maxLossStreak = maxLossStreak;
      m_lossStreakAction = lossAction;
      m_lossPauseMinutes = lossPauseMin;
      
      // Win Streak
      m_maxWinStreak = maxWinStreak;
      m_winStreakAction = winAction;
      m_winPauseMinutes = winPauseMin;
      
      Print("🔴 Controle de Streak:");
      
      if(maxLossStreak > 0)
        {
         Print("   • Loss Streak: Max ", maxLossStreak, " perdas");
         if(lossAction == STREAK_PAUSE)
            Print("     └─ Ação: Pausar por ", lossPauseMin, " minutos");
         else
            Print("     └─ Ação: Parar até fim do dia");
        }
      
      if(maxWinStreak > 0)
        {
         Print("   • Win Streak: Max ", maxWinStreak, " ganhos");
         if(winAction == STREAK_PAUSE)
            Print("     └─ Ação: Pausar por ", winPauseMin, " minutos");
         else
            Print("     └─ Ação: Parar até fim do dia");
        }
     }
   else
     {
      Print("🔴 Controle de Streak: DESATIVADO");
     }
   
   // ───────────────────────────────────────────────────────────────
   // DRAWDOWN
   // ───────────────────────────────────────────────────────────────
   m_enableDrawdown = enableDD;
   m_drawdownType = ddType;
   m_drawdownValue = ddValue;
   
   if(enableDD)
     {
      if(ddValue <= 0 || (ddType == DD_PERCENTAGE && ddValue > 100))
        {
         Print("❌ Drawdown inválido!");
         return false;
        }
      
      if(initialBalance <= 0)
        {
         Print("❌ Saldo inicial inválido!");
         return false;
        }
      
      m_initialBalance = initialBalance;
      m_peakBalance = initialBalance;
      
      Print("📉 Drawdown Máximo:");
      if(ddType == DD_FINANCIAL)
         Print("   - Tipo: Financeiro ($", DoubleToString(ddValue, 2), ")");
      else
         Print("   - Tipo: Percentual (", DoubleToString(ddValue, 2), "%)");
      Print("   - Saldo Inicial: $", DoubleToString(initialBalance, 2));
     }
   else
     {
      Print("📉 Proteção Drawdown: DESATIVADA");
     }
   
   // ───────────────────────────────────────────────────────────────
   // DIREÇÃO
   // ───────────────────────────────────────────────────────────────
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
   Print("🎯 Direção Permitida: ", dirText);
   
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
   
   Print("");
   Print("✅ Blockers inicializados com sucesso!");
   Print("");
   
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
   blockReason = "";
   
   // ───────────────────────────────────────────────────────────────
   // 1. VERIFICAR HORÁRIO
   // ───────────────────────────────────────────────────────────────
   if(!CheckTimeFilter())
     {
      m_currentBlocker = BLOCKER_TIME_FILTER;
      blockReason = "Fora do horário permitido";
      return false;
     }
   
   // ───────────────────────────────────────────────────────────────
   // 2. VERIFICAR NEWS FILTERS
   // ───────────────────────────────────────────────────────────────
   if(!CheckNewsFilter())
     {
      m_currentBlocker = BLOCKER_NEWS_FILTER;
      blockReason = "Horário de volatilidade";
      return false;
     }
   
   // ───────────────────────────────────────────────────────────────
   // 3. VERIFICAR SPREAD
   // ───────────────────────────────────────────────────────────────
   if(!CheckSpreadFilter())
     {
      m_currentBlocker = BLOCKER_SPREAD;
      long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      blockReason = StringFormat("Spread alto (%d > %d)", spread, m_maxSpread);
      return false;
     }
   
   // ───────────────────────────────────────────────────────────────
   // 4. VERIFICAR STREAK (WIN ou LOSS)
   // ───────────────────────────────────────────────────────────────
   if(!CheckStreakLimit())
     {
      // Determinar qual streak bloqueou
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
   
   // ───────────────────────────────────────────────────────────────
   // 5. VERIFICAR LIMITES DIÁRIOS
   // ───────────────────────────────────────────────────────────────
   if(!CheckDailyLimits(dailyTrades, dailyProfit))
     {
      // m_currentBlocker já foi setado em CheckDailyLimits
      blockReason = GetBlockerReasonText(m_currentBlocker);
      return false;
     }
   
   // ───────────────────────────────────────────────────────────────
   // 6. VERIFICAR DRAWDOWN
   // ───────────────────────────────────────────────────────────────
   if(!CheckDrawdownLimit())
     {
      m_currentBlocker = BLOCKER_DRAWDOWN;
      blockReason = StringFormat("Drawdown %.2f%% excedido", GetCurrentDrawdown());
      return false;
     }
   
   // ───────────────────────────────────────────────────────────────
   // TUDO OK!
   // ───────────────────────────────────────────────────────────────
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
//| Verifica se deve fechar posição por fim de horário               |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseOnEndTime(ulong positionTicket)
  {
   if(!m_enableTimeFilter || !m_closeOnEndTime)
      return false;
   
   if(positionTicket == 0)
      return false;
   
   // Verificar se está FORA do horário
   if(CheckTimeFilter())
      return false;  // Ainda dentro do horário
   
   return true;  // Fora do horário = deve fechar
  }

//+------------------------------------------------------------------+
//| Atualiza estado após um trade                                    |
//+------------------------------------------------------------------+
void CBlockers::UpdateAfterTrade(bool isWin, double tradeProfit)
  {
   // ───────────────────────────────────────────────────────────────
   // ATUALIZAR STREAKS
   // ───────────────────────────────────────────────────────────────
   if(m_enableStreakControl)
     {
      if(isWin)
        {
         // Vitória: incrementar win streak, zerar loss streak
         m_currentWinStreak++;
         m_currentLossStreak = 0;
         
         if(m_maxWinStreak > 0 && m_currentWinStreak >= m_maxWinStreak)
            Print("⚠️ WIN STREAK ATINGIDO: ", m_currentWinStreak, " ganhos consecutivos!");
        }
      else
        {
         // Perda: incrementar loss streak, zerar win streak
         m_currentLossStreak++;
         m_currentWinStreak = 0;
         
         if(m_maxLossStreak > 0 && m_currentLossStreak >= m_maxLossStreak)
            Print("⚠️ LOSS STREAK ATINGIDO: ", m_currentLossStreak, " perdas consecutivas!");
        }
     }
  }

//+------------------------------------------------------------------+
//| Atualiza pico de saldo (para cálculo de drawdown)                |
//+------------------------------------------------------------------+
void CBlockers::UpdatePeakBalance(double currentBalance)
  {
   if(!m_enableDrawdown) return;
   
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
   if(!m_enableDrawdown) return;
   
   m_drawdownProtectionActive = true;
   m_dailyPeakProfit = peakProfit;
   
   Print("═══════════════════════════════════════════════════════");
   Print("🛡️ PROTEÇÃO DE DRAWDOWN ATIVADA!");
   Print("   Pico de lucro: $", DoubleToString(peakProfit, 2));
   if(m_drawdownType == DD_FINANCIAL)
      Print("   Proteção: Máx $", DoubleToString(m_drawdownValue, 2), " de drawdown");
   else
      Print("   Proteção: Máx ", DoubleToString(m_drawdownValue, 1), "% de drawdown");
   Print("═══════════════════════════════════════════════════════");
  }

//+------------------------------------------------------------------+
//| Reset diário (limpa contadores)                                  |
//+------------------------------------------------------------------+
void CBlockers::ResetDaily()
  {
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
   
   // Caso 1: Horário não atravessa meia-noite (ex: 09:00 - 17:00)
   if(startMinutes < endMinutes)
     {
      return (currentMinutes >= startMinutes && currentMinutes <= endMinutes);
     }
   
   // Caso 2: Horário atravessa meia-noite (ex: 23:00 - 02:00)
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
   
   // Verificar bloqueio 1
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
   
   // Verificar bloqueio 2
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
   
   // Verificar bloqueio 3
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
   
   // ───────────────────────────────────────────────────────────────
   // LIMITE DE TRADES
   // ───────────────────────────────────────────────────────────────
   if(m_maxDailyTrades > 0 && dailyTrades >= m_maxDailyTrades)
     {
      m_currentBlocker = BLOCKER_DAILY_TRADES;
      return false;
     }
   
   // ───────────────────────────────────────────────────────────────
   // LIMITE DE PERDA
   // ───────────────────────────────────────────────────────────────
   if(m_maxDailyLoss > 0 && dailyProfit <= -m_maxDailyLoss)
     {
      m_currentBlocker = BLOCKER_DAILY_LOSS;
      return false;
     }
   
   // ───══════════════════════════════════════════════════════════════
   // LIMITE DE GANHO (META)
   // ───────────────────────────────────────────────────────────────
   if(m_maxDailyGain > 0 && dailyProfit >= m_maxDailyGain)
     {
      // Verificar qual ação tomar
      if(m_profitTargetAction == PROFIT_ACTION_STOP)
        {
         // Para de operar
         m_currentBlocker = BLOCKER_DAILY_GAIN;
         return false;
        }
      else  // PROFIT_ACTION_ENABLE_DRAWDOWN
        {
         // Ativa proteção de drawdown (se ainda não ativou)
         if(!m_drawdownProtectionActive)
           {
            ActivateDrawdownProtection(dailyProfit);
           }
         
         // Continua operando (mas com proteção DD ativa)
         // A verificação de DD será feita em CheckDrawdownLimit()
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
   
   // ───────────────────────────────────────────────────────────────
   // VERIFICAR SE ESTÁ EM PAUSA POR STREAK
   // ───────────────────────────────────────────────────────────────
   if(m_streakPauseActive)
     {
      // Ainda está em pausa?
      if(TimeCurrent() < m_streakPauseUntil)
        {
         // Log throttle: só loga a cada 5 minutos
         if(TimeCurrent() - m_lastStreakWarning > 300)
           {
            int remainingMinutes = (int)((m_streakPauseUntil - TimeCurrent()) / 60);
            Print("═══════════════════════════════════════════════════════");
            Print("⏸️ EA PAUSADO POR SEQUÊNCIA");
            Print("   📊 Motivo: ", m_streakPauseReason);
            Print("   ⏱️ Tempo restante: ", remainingMinutes, " minutos");
            Print("═══════════════════════════════════════════════════════");
            m_lastStreakWarning = TimeCurrent();
           }
         return false;  // Bloqueado
        }
      else
        {
         // Pausa acabou - retomar operações
         Print("═══════════════════════════════════════════════════════");
         Print("▶️ PAUSA DE SEQUÊNCIA FINALIZADA");
         Print("   📊 Sequência que causou pausa: ", m_streakPauseReason);
         Print("   🔄 Contadores zerados - pronto para novo ciclo");
         Print("   ✅ EA retomando operações normais");
         Print("═══════════════════════════════════════════════════════");
         
         m_streakPauseActive = false;
         m_streakPauseReason = "";
         m_currentWinStreak = 0;
         m_currentLossStreak = 0;
         
         return true;
        }
     }
   
   // ───────────────────────────────────────────────────────────────
   // VERIFICAR LOSS STREAK
   // ───────────────────────────────────────────────────────────────
   if(m_maxLossStreak > 0 && m_currentLossStreak >= m_maxLossStreak)
     {
      Print("═══════════════════════════════════════════════════════");
      Print("🛑 SEQUÊNCIA DE PERDAS ATINGIDA!");
      Print("   📉 Perdas consecutivas: ", m_currentLossStreak);
      Print("   🎯 Limite configurado: ", m_maxLossStreak);
      
      if(m_lossStreakAction == STREAK_PAUSE)
        {
         m_streakPauseActive = true;
         m_streakPauseUntil = TimeCurrent() + (m_lossPauseMinutes * 60);
         m_streakPauseReason = StringFormat("%d perdas consecutivas", m_currentLossStreak);
         
         Print("   ⏸️ EA PAUSADO por ", m_lossPauseMinutes, " minutos");
         Print("   🔄 Retorno previsto: ", TimeToString(m_streakPauseUntil, TIME_DATE|TIME_MINUTES));
        }
      else  // STREAK_STOP_DAY
        {
         Print("   🛑 EA PAUSADO até o FIM DO DIA");
        }
      
      Print("═══════════════════════════════════════════════════════");
      return false;
     }
   
   // ───────────────────────────────────────────────────────────────
   // VERIFICAR WIN STREAK
   // ───────────────────────────────────────────────────────────────
   if(m_maxWinStreak > 0 && m_currentWinStreak >= m_maxWinStreak)
     {
      Print("═══════════════════════════════════════════════════════");
      Print("🎯 SEQUÊNCIA DE GANHOS ATINGIDA!");
      Print("   📈 Ganhos consecutivos: ", m_currentWinStreak);
      Print("   🎯 Limite configurado: ", m_maxWinStreak);
      
      if(m_winStreakAction == STREAK_PAUSE)
        {
         m_streakPauseActive = true;
         m_streakPauseUntil = TimeCurrent() + (m_winPauseMinutes * 60);
         m_streakPauseReason = StringFormat("%d ganhos consecutivos", m_currentWinStreak);
         
         Print("   ⏸️ EA PAUSADO por ", m_winPauseMinutes, " minutos");
         Print("   🔄 Retorno previsto: ", TimeToString(m_streakPauseUntil, TIME_DATE|TIME_MINUTES));
        }
      else  // STREAK_STOP_DAY
        {
         Print("   🎯 META DE SEQUÊNCIA ATINGIDA!");
         Print("   🛑 EA PAUSADO até o FIM DO DIA");
        }
      
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
   
   // Atualizar pico
   if(currentProfit > m_dailyPeakProfit)
      m_dailyPeakProfit = currentProfit;
   
   // Calcular drawdown atual
   double currentDD = m_dailyPeakProfit - currentProfit;
   double ddLimit = 0;
   
   if(m_drawdownType == DD_FINANCIAL)
     {
      ddLimit = m_drawdownValue;
     }
   else  // DD_PERCENTAGE
     {
      ddLimit = (m_dailyPeakProfit * m_drawdownValue) / 100.0;
     }
   
   // Verificar se ultrapassou limite
   if(currentDD >= ddLimit)
     {
      m_drawdownLimitReached = true;
      
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
      case BLOCKER_NONE:          return "Sem bloqueio";
      case BLOCKER_TIME_FILTER:   return "Fora do horário";
      case BLOCKER_NEWS_FILTER:   return "Horário de volatilidade";
      case BLOCKER_SPREAD:        return "Spread alto";
      case BLOCKER_DAILY_TRADES:  return "Limite de trades diários";
      case BLOCKER_DAILY_LOSS:    return "Perda diária máxima";
      case BLOCKER_DAILY_GAIN:    return "Ganho diário máximo";
      case BLOCKER_LOSS_STREAK:   return "Sequência de perdas";
      case BLOCKER_WIN_STREAK:    return "Sequência de ganhos";
      case BLOCKER_DRAWDOWN:      return "Drawdown máximo";
      case BLOCKER_DIRECTION:     return "Direção bloqueada";
      default:                    return "Bloqueio desconhecido";
     }
  }

//+------------------------------------------------------------------+
//| Imprime status atual                                             |
//+------------------------------------------------------------------+
void CBlockers::PrintStatus()
  {
   Print("╔══════════════════════════════════════════════════════╗");
   Print("║            BLOCKERS - STATUS ATUAL                   ║");
   Print("╚══════════════════════════════════════════════════════╝");
   Print("");
   
   // Bloqueador ativo
   if(m_currentBlocker != BLOCKER_NONE)
     {
      Print("🚫 BLOQUEADO: ", GetBlockerReasonText(m_currentBlocker));
     }
   else
     {
      Print("✅ LIBERADO PARA OPERAR");
     }
   Print("");
   
   // Horário
   if(m_enableTimeFilter)
     {
      datetime now = TimeCurrent();
      MqlDateTime t;
      TimeToStruct(now, t);
      
      Print("⏰ Horário:");
      Print("   Atual: ", StringFormat("%02d:%02d", t.hour, t.min));
      Print("   Permitido: ", StringFormat("%02d:%02d - %02d:%02d", 
            m_startHour, m_startMinute, m_endHour, m_endMinute));
      Print("   Status: ", CheckTimeFilter() ? "✅ OK" : "❌ BLOQUEADO");
     }
   
   // Streaks
   if(m_enableStreakControl)
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
   
   // Drawdown
   if(m_drawdownProtectionActive)
     {
      double currentProfit = AccountInfoDouble(ACCOUNT_BALANCE) - m_initialBalance;
      double currentDD = m_dailyPeakProfit - currentProfit;
      
      Print("");
      Print("📉 Drawdown (proteção ativa):");
      Print("   Pico: $", DoubleToString(m_dailyPeakProfit, 2));
      Print("   Atual: $", DoubleToString(currentProfit, 2));
      Print("   DD: $", DoubleToString(currentDD, 2));
      Print("   Status: ", m_drawdownLimitReached ? "❌ LIMITE ATINGIDO" : "✅ OK");
     }
   
   Print("");
   Print("═══════════════════════════════════════════════════════");
  }

//+------------------------------------------------------------------+
//| Imprime configuração completa                                    |
//+------------------------------------------------------------------+
void CBlockers::PrintConfiguration()
  {
   Print("╔══════════════════════════════════════════════════════╗");
   Print("║         BLOCKERS - CONFIGURAÇÃO COMPLETA            ║");
   Print("╚══════════════════════════════════════════════════════╝");
   Print("");
   
   // Horário
   Print("⏰ Horário:");
   if(m_enableTimeFilter)
     {
      Print("   ", StringFormat("%02d:%02d - %02d:%02d", 
            m_startHour, m_startMinute, m_endHour, m_endMinute));
      Print("   Fecha ao fim: ", m_closeOnEndTime ? "SIM" : "NÃO");
     }
   else
      Print("   DESATIVADO");
   
   // News
   Print("");
   Print("📰 News Filters:");
   if(m_enableNewsFilter1 || m_enableNewsFilter2 || m_enableNewsFilter3)
     {
      if(m_enableNewsFilter1)
         Print("   1: ", StringFormat("%02d:%02d - %02d:%02d", 
               m_newsStart1Hour, m_newsStart1Minute, m_newsEnd1Hour, m_newsEnd1Minute));
      if(m_enableNewsFilter2)
         Print("   2: ", StringFormat("%02d:%02d - %02d:%02d", 
               m_newsStart2Hour, m_newsStart2Minute, m_newsEnd2Hour, m_newsEnd2Minute));
      if(m_enableNewsFilter3)
         Print("   3: ", StringFormat("%02d:%02d - %02d:%02d", 
               m_newsStart3Hour, m_newsStart3Minute, m_newsEnd3Hour, m_newsEnd3Minute));
     }
   else
      Print("   DESATIVADOS");
   
   // Spread
   Print("");
   Print("📊 Spread:");
   if(m_maxSpread > 0)
      Print("   Máximo: ", m_maxSpread, " pontos");
   else
      Print("   ILIMITADO");
   
   // Limites diários
   Print("");
   Print("📅 Limites Diários:");
   if(m_enableDailyLimits)
     {
      if(m_maxDailyTrades > 0)
         Print("   Trades: ", m_maxDailyTrades);
      if(m_maxDailyLoss > 0)
         Print("   Loss: $", DoubleToString(m_maxDailyLoss, 2));
      if(m_maxDailyGain > 0)
        {
         Print("   Gain: $", DoubleToString(m_maxDailyGain, 2));
         Print("   Ação: ", m_profitTargetAction == PROFIT_ACTION_STOP ? "PARAR" : "ATIVAR DD");
        }
     }
   else
      Print("   DESATIVADOS");
   
   // Streak
   Print("");
   Print("🔴 Streak Control:");
   if(m_enableStreakControl)
     {
      if(m_maxLossStreak > 0)
        {
         Print("   Loss: Max ", m_maxLossStreak);
         Print("   Ação: ", m_lossStreakAction == STREAK_PAUSE ? 
               "Pausar " + IntegerToString(m_lossPauseMinutes) + " min" : "Parar dia");
        }
      if(m_maxWinStreak > 0)
        {
         Print("   Win: Max ", m_maxWinStreak);
         Print("   Ação: ", m_winStreakAction == STREAK_PAUSE ? 
               "Pausar " + IntegerToString(m_winPauseMinutes) + " min" : "Parar dia");
        }
     }
   else
      Print("   DESATIVADO");
   
   // Drawdown
   Print("");
   Print("📉 Drawdown:");
   if(m_enableDrawdown)
     {
      if(m_drawdownType == DD_FINANCIAL)
         Print("   Tipo: Financeiro ($", DoubleToString(m_drawdownValue, 2), ")");
      else
         Print("   Tipo: Percentual (", DoubleToString(m_drawdownValue, 2), "%)");
     }
   else
      Print("   DESATIVADO");
   
   // Direção
   Print("");
   Print("🎯 Direção:");
   switch(m_tradeDirection)
     {
      case DIRECTION_BOTH:
         Print("   AMBAS");
         break;
      case DIRECTION_BUY_ONLY:
         Print("   APENAS COMPRAS");
         break;
      case DIRECTION_SELL_ONLY:
         Print("   APENAS VENDAS");
         break;
     }
   
   Print("");
   Print("═══════════════════════════════════════════════════════");
  }

//+------------------------------------------------------------------+
