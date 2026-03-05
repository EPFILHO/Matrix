//+------------------------------------------------------------------+
//|                                                     Blockers.mqh |
//|                                         Copyright 2026, EP Filho |
//|                              Sistema de Bloqueios - EPBot Matrix |
//|                     Versão 3.21 - Claude Parte 024 (Claude Code) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "3.21"
#property strict

// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.21 (Parte 024):
// + Getters públicos para GUI RESULTADOS:
//   DD: GetDrawdownType(), GetDrawdownValue(), GetDrawdownPeakMode()
//   Streak: IsStreakControlEnabled(), GetMaxLossStreak(), GetMaxWinStreak(),
//   GetLossStreakAction(), GetWinStreakAction(), GetLoss/WinPauseMinutes()
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.20 (Parte 024):
// ✅ Fix: CheckDrawdownLimit() usava ACCOUNT_BALANCE - m_initialBalance
//    para calcular lucro atual — quando EA iniciava com DD desligado,
//    m_initialBalance ficava 0, corrompendo m_dailyPeakProfit com o
//    saldo total da conta (~R$1.220.586) em vez do lucro do dia ($3.055)
// + CheckDrawdownLimit() agora usa m_logger.GetDailyProfit() + floating
//    (POSITION_PROFIT + POSITION_SWAP) — mesma lógica de
//    ShouldCloseByDrawdown() e GetCurrentDrawdown(), sem dependência
//    de m_initialBalance ou ACCOUNT_BALANCE
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.19 (Parte 024):
// ✅ Fix: DD ativado via hot reload sem meta de lucro nunca ativava
//    m_drawdownProtectionActive — ShouldCloseByDrawdown() retornava false
//    imediatamente, ignorando o limite configurado via painel
// + TryActivateDrawdownNow(dailyProfit): ativa proteção imediatamente
//    ao ligar DD via hot reload, usando lucro diário atual como pico
// ✅ Fix: GetCurrentDrawdown() usava ACCOUNT_BALANCE (sem floating) —
//    corrigido para lucro projetado (fechados + floating + swap),
//    consistente com ShouldCloseByDrawdown()
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.18 (Parte 023):
// ✅ Fix: ShouldCloseOnEndTime() usava > endMinutes — fechava a posição somente
//    no primeiro tick de 17:36, enquanto CheckTimeFilter já bloqueava novas entradas
//    desde 17:35. Padronizado para >= endMinutes: ao chegar em 17:35 (primeiro minuto
//    fora da janela) novas entradas são bloqueadas E posição aberta é fechada no
//    mesmo momento, sem esperar o próximo candle.
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.17 (Parte 023):
// ✅ Fix: CheckTimeFilter() usava <= endMinutes (inclusivo) — padrão diferente
//    do CheckNewsFilter(). Padronizado para < endMinutes (exclusivo) em ambos
//    os casos (janela normal e overnight), mantendo consistência de comportamento:
//    o horário de término é o PRIMEIRO minuto fora do intervalo em todos os filtros.
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.16 (Parte 023):
// ✅ Fix: CheckNewsFilter() usava <= newsEnd (inclusivo) — liberava apenas no
//    minuto seguinte ao fim. Corrigido para < newsEnd (exclusivo): ao atingir
//    o minuto de término, operações já são liberadas.
//    Mesmo fix aplicado nas checagens de log de transição em CanTrade().
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.15 (Parte 023):
// + CanTrade(): logging de transição de estado para 4 bloqueadores
//   silenciosos: TimeFilter, NewsFilter, SpreadFilter, DailyLimits
//   - Loga ao ENTRAR no bloqueio (com detalhes: janela, spread, $)
//   - Loga ao SAIR do bloqueio (operações liberadas)
//   - NewsFilter: identifica qual janela (1/2/3) está ativa
//   - Padrão: static bool por bloqueador, log apenas em transições
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.14 (Parte 023):
// ✅ Fix: SetDrawdownValue() não atualizava m_enableDrawdown no hot-reload
// ✅ Fix: SetDailyLimits() não atualizava m_enableDailyLimits no hot-reload
// ✅ Fix: SetStreakLimits() não cancelava m_streakPauseActive ao subir limite
// ✅ Fix: SetDrawdownValue() não limpava m_drawdownLimitReached ao subir limite
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.12 (Parte 023):
// ✅ Fix Bug: Streak não bloqueava após hot-reload com EA iniciado sem streak
// + ReconstructStreakFromHistory(): reconstrói contadores consecutivos do CSV
// + Init(): chama ReconstructStreakFromHistory() após reset de contadores
// + UpdateAfterTrade(): remove guard if(m_enableStreakControl) — sempre conta
// + SetStreakLimits(): ativa m_enableStreakControl e reconstrói ao ativar
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.11 (Parte 023):
// + SetCloseBeforeSessionEnd(bool, int) — hot-reload do fechar antes
//   do fim da sessão, atualiza m_closeBeforeSessionEnd e
//   m_minutesBeforeSessionEnd atomicamente
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.10 (Parte 024):
// + SetTimeFilter(bool,int,int,int,int) — hot-reload do filtro de horário
// + SetCloseOnEndTime(bool) — hot-reload do fechar posição ao fim
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.09 (Parte 023):
// + SetDrawdownType(ENUM_DRAWDOWN_TYPE) — hot-reload do tipo DD
// + SetDrawdownPeakMode(ENUM_DRAWDOWN_PEAK_MODE) — hot-reload do modo de pico
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.08:
// ✅ Fix: Funções Hot Reload só logam quando há mudança real
//    - SetMaxSpread, SetTradeDirection, SetDailyLimits,
//      SetStreakLimits, SetDrawdownValue
//    - Evita logs redundantes na inicialização/recarregamento
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.07:
// ✅ Timestamp de ativação do Drawdown nos logs de fechamento:
//    - Novo membro m_drawdownActivationTime
//    - Log de fechamento por DD inclui horário de ativação
//    - Informação puramente visual, sem impacto funcional
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.06:
// ✅ Modo de Cálculo do Pico de Drawdown configurável:
//    - Novo enum ENUM_DRAWDOWN_PEAK_MODE
//    - DD_PEAK_REALIZED_ONLY: pico baseado apenas em trades fechados
//    - DD_PEAK_INCLUDE_FLOATING: pico inclui P/L flutuante
//    - ActivateDrawdownProtection() recebe closedProfit e projectedProfit
//    - ShouldCloseByDrawdown() usa peakCandidate conforme modo
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.05:
// ✅ Remoção de inp_InitialBalance:
//    - Saldo inicial auto-detectado via AccountInfoDouble(ACCOUNT_BALANCE)
//    - Init() não recebe mais parâmetro initialBalance
//    - m_peakBalance inicializado com saldo real da conta
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.04:
// ✅ VERIFICAÇÃO DE DRAWDOWN EM TEMPO REAL:
//    - Novo método ShouldCloseByDrawdown(ticket, dailyProfit, reason)
//    - Calcula drawdown com lucro PROJETADO (fechados + aberta)
//    - Fecha NO EXATO MOMENTO que atinge limite de drawdown
//    - Atualiza pico de lucro em tempo real
//    - Compatível com proteção de drawdown existente
//    - Mantém coerência com verificação de limites diários
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.03:
// ✅ CORREÇÃO CRÍTICA - VERIFICAÇÃO EM TEMPO REAL:
//    - Novo método ShouldCloseByDailyLimit(ticket, dailyProfit, reason)
//    - Calcula lucro PROJETADO (fechados + aberta + swap)
//    - Fecha NO EXATO MOMENTO que atinge limite (não depois!)
//    - Logs detalhados mostrando composição do lucro
//    - Mantém compatibilidade com drawdown protection
//    - Validação de Magic Number
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.02:
// ✅ CORREÇÃO CRÍTICA - MERCADOS 24/7 (CRIPTO):
//    - Detecta quando sessão retorna 00:00→00:00 (sempre aberto)
//    - Ignora proteção de sessão para mercados 24/7
//    - Log informativo uma única vez ao detectar
//    - Corrige bloqueio indevido em BTC, ETH e outros ativos 24h
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.01:
// ✅ CORREÇÃO CRÍTICA DE LOGGING SPAM:
//    - CanTrade(): Log de sessão apenas em TRANSIÇÕES de estado
//    - ShouldCloseOnEndTime(): Log apenas 1x por ticket
//    - ShouldCloseBeforeSessionEnd(): Log apenas 1x por ticket
//    - Uso de static para controle de estados
//    - Mantém TODA funcionalidade v3.00
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v3.00:
// ✅ REFATORAÇÃO COMPLETA DE LOGGING:
//    - Migração para Logger v3.00 (5 níveis + throttle inteligente)
//    - Remoção de throttle manual (m_lastXWarning)
//    - Uso de THROTTLE_TIME automático do Logger
//    - PrintStatus() e PrintConfiguration() atualizados
// ✅ Mantém TODAS as funcionalidades v2.02:
//    - Validação de Magic Number
//    - Proteção de sessão
//    - Hot reload
//    - Compatibilidade total
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

// ✅ NOVO v3.01: Estados de sessão para logging inteligente
enum ENUM_SESSION_STATE
  {
   SESSION_BEFORE,       // Antes da sessão iniciar
   SESSION_ACTIVE,       // Sessão ativa (operação normal)
   SESSION_PROTECTION,   // Janela de proteção (X min antes do fim)
   SESSION_AFTER         // Após encerramento da sessão
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
   ENUM_DRAWDOWN_PEAK_MODE m_inputDrawdownPeakMode;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - DRAWDOWN (valores usados)
   // ═══════════════════════════════════════════════════════════════
   bool              m_enableDrawdown;
   ENUM_DRAWDOWN_TYPE m_drawdownType;
   double            m_drawdownValue;
   double            m_initialBalance;
   double            m_peakBalance;
   ENUM_DRAWDOWN_PEAK_MODE m_drawdownPeakMode;

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
   datetime          m_drawdownActivationTime;

   datetime          m_lastResetDate;
   ENUM_BLOCKER_REASON m_currentBlocker;

   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS - VERIFICADORES INDIVIDUAIS
   // ═══════════════════════════════════════════════════════════════
   bool              CheckTimeFilter();
   bool              CheckNewsFilter();
   bool              CheckSpreadFilter();
   bool              CheckDailyLimits(int dailyTrades, double dailyProfit);
   bool              CheckStreakLimit();
   bool              CheckDrawdownLimit();
   void              ReconstructStreakFromHistory();
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
      bool enableDD, ENUM_DRAWDOWN_TYPE ddType, double ddValue, ENUM_DRAWDOWN_PEAK_MODE ddPeakMode,
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
   bool              ShouldCloseByDailyLimit(ulong positionTicket, double dailyProfit, string &closeReason);
   bool              ShouldCloseByDrawdown(ulong positionTicket, double dailyProfit, string &closeReason);

   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS DE ATUALIZAÇÃO DE ESTADO
   // ═══════════════════════════════════════════════════════════════
   void              UpdateAfterTrade(bool isWin, double tradeProfit);
   void              UpdatePeakBalance(double currentBalance);
   void              UpdatePeakProfit(double currentProfit);
   void              ActivateDrawdownProtection(double closedProfit, double projectedProfit);
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
   void              SetDrawdownType(ENUM_DRAWDOWN_TYPE newType);
   void              SetDrawdownPeakMode(ENUM_DRAWDOWN_PEAK_MODE newMode);
   void              TryActivateDrawdownNow(double dailyProfit);
   void              SetTimeFilter(bool enable, int startH, int startM, int endH, int endM);
   void              SetCloseOnEndTime(bool close);
   void              SetCloseBeforeSessionEnd(bool close, int minutes);
   void              SetNewsFilter(int window, bool enable, int startH, int startM, int endH, int endM);

   // ═══════════════════════════════════════════════════════════════
   // GETTERS - INFORMAÇÕES DE ESTADO
   // ═══════════════════════════════════════════════════════════════
   int               GetCurrentLossStreak() const { return m_currentLossStreak; }
   int               GetCurrentWinStreak() const { return m_currentWinStreak; }
   double            GetCurrentDrawdown();
   double            GetDailyPeakProfit() const { return m_dailyPeakProfit; }
   bool              IsDrawdownProtectionActive() const { return m_drawdownProtectionActive; }
   bool              IsDrawdownLimitReached() const { return m_drawdownLimitReached; }
   ENUM_DRAWDOWN_TYPE      GetDrawdownType() const      { return m_drawdownType; }
   double                  GetDrawdownValue() const     { return m_drawdownValue; }
   ENUM_DRAWDOWN_PEAK_MODE GetDrawdownPeakMode() const  { return m_drawdownPeakMode; }
   ENUM_BLOCKER_REASON GetActiveBlocker() const { return m_currentBlocker; }
   bool              IsBlocked() const { return m_currentBlocker != BLOCKER_NONE; }
   bool              IsStreakControlEnabled() const { return m_enableStreakControl; }
   bool              IsStreakPaused() const { return m_streakPauseActive; }
   datetime          GetStreakPauseUntil() const { return m_streakPauseUntil; }
   string            GetStreakPauseReason() const { return m_streakPauseReason; }
   int               GetMaxLossStreak() const      { return m_maxLossStreak; }
   int               GetMaxWinStreak() const       { return m_maxWinStreak; }
   ENUM_STREAK_ACTION GetLossStreakAction() const   { return m_lossStreakAction; }
   ENUM_STREAK_ACTION GetWinStreakAction() const    { return m_winStreakAction; }
   int               GetLossPauseMinutes() const   { return m_lossPauseMinutes; }
   int               GetWinPauseMinutes() const    { return m_winPauseMinutes; }

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
   m_inputDrawdownPeakMode = DD_PEAK_REALIZED_ONLY;

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
   m_drawdownPeakMode = DD_PEAK_REALIZED_ONLY;

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
   m_drawdownActivationTime = 0;

   m_lastResetDate = TimeCurrent();
   m_currentBlocker = BLOCKER_NONE;
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
   bool enableDD, ENUM_DRAWDOWN_TYPE ddType, double ddValue, ENUM_DRAWDOWN_PEAK_MODE ddPeakMode,
   ENUM_TRADE_DIRECTION tradeDirection
)
  {
// Armazenar referência ao logger
   m_logger = logger;
   m_magicNumber = magicNumber;

   if(m_logger != NULL)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "╔══════════════════════════════════════════════════════╗");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "║        EPBOT MATRIX - INICIALIZANDO BLOCKERS        ║");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "║              VERSÃO COMPLETA v3.18                   ║");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "╚══════════════════════════════════════════════════════╝");
     }
   else
     {
      Print("╔══════════════════════════════════════════════════════╗");
      Print("║        EPBOT MATRIX - INICIALIZANDO BLOCKERS        ║");
      Print("║              VERSÃO COMPLETA v3.18                   ║");
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
            m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Horários inválidos!");
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
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", timeMsg);
      else
         Print(timeMsg);

      if(closeOnEnd)
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "   └─ Fecha posição ao fim do horário");
         else
            Print("   └─ Fecha posição ao fim do horário");
        }
     }
   else
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "⏰ Filtro de Horário: DESATIVADO");
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
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📰 Horários de Volatilidade:");
      else
         Print("📰 Horários de Volatilidade:");

      if(news1)
        {
         string msg = "   • Bloqueio 1: " + StringFormat("%02d:%02d - %02d:%02d", n1StartH, n1StartM, n1EndH, n1EndM);
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
         else
            Print(msg);
        }
      if(news2)
        {
         string msg = "   • Bloqueio 2: " + StringFormat("%02d:%02d - %02d:%02d", n2StartH, n2StartM, n2EndH, n2EndM);
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
         else
            Print(msg);
        }
      if(news3)
        {
         string msg = "   • Bloqueio 3: " + StringFormat("%02d:%02d - %02d:%02d", n3StartH, n3StartM, n3EndH, n3EndM);
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
         else
            Print(msg);
        }
     }
   else
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📰 Horários de Volatilidade: DESATIVADOS");
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
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
      else
         Print(msg);
     }
   else
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📊 Spread Máximo: ILIMITADO");
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
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📅 Limites Diários:");
      else
         Print("📅 Limites Diários:");

      if(maxTrades > 0)
        {
         string msg = "   - Max Trades: " + IntegerToString(maxTrades);
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
         else
            Print(msg);
        }
      if(maxLoss != 0)
        {
         string msg = "   - Max Loss: $" + DoubleToString(m_maxDailyLoss, 2);
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
         else
            Print(msg);
        }
      if(maxGain != 0)
        {
         string msg1 = "   - Max Gain: $" + DoubleToString(m_maxDailyGain, 2);
         string msg2 = "     └─ Ação: " + (profitAction == PROFIT_ACTION_STOP ? "PARAR ao atingir meta" : "ATIVAR proteção de drawdown");
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
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "🔴 Controle de Streak:");
      else
         Print("🔴 Controle de Streak:");

      if(maxLossStreak > 0)
        {
         string msg = "   • Loss Streak: Max " + IntegerToString(maxLossStreak) + " perdas";
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
         else
            Print(msg);

         string actionMsg = (lossAction == STREAK_PAUSE) ?
                            "     └─ Ação: Pausar por " + IntegerToString(lossPauseMin) + " minutos" :
                            "     └─ Ação: Parar até fim do dia";
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", actionMsg);
         else
            Print(actionMsg);
        }

      if(maxWinStreak > 0)
        {
         string msg = "   • Win Streak: Max " + IntegerToString(maxWinStreak) + " ganhos";
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
         else
            Print(msg);

         string actionMsg = (winAction == STREAK_PAUSE) ?
                            "     └─ Ação: Pausar por " + IntegerToString(winPauseMin) + " minutos" :
                            "     └─ Ação: Parar até fim do dia";
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", actionMsg);
         else
            Print(actionMsg);
        }
     }
   else
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "🔴 Controle de Streak: DESATIVADO");
      else
         Print("🔴 Controle de Streak: DESATIVADO");
     }

// ───────────────────────────────────────────────────────────────
// DRAWDOWN
// ───────────────────────────────────────────────────────────────
   m_inputEnableDrawdown = enableDD;
   m_inputDrawdownType = ddType;
   m_inputDrawdownValue = ddValue;
   m_inputDrawdownPeakMode = ddPeakMode;
   m_enableDrawdown = enableDD;
   m_drawdownType = ddType;
   m_drawdownValue = ddValue;
   m_drawdownPeakMode = ddPeakMode;

   if(enableDD)
     {
      if(ddValue <= 0 || (ddType == DD_PERCENTAGE && ddValue > 100))
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Drawdown inválido!");
         else
            Print("❌ Drawdown inválido!");
         return false;
        }

      double autoBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      if(autoBalance <= 0)
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Saldo da conta inválido (zero ou negativo)!");
         else
            Print("❌ Saldo da conta inválido (zero ou negativo)!");
         return false;
        }

      m_inputInitialBalance = autoBalance;
      m_initialBalance = autoBalance;
      m_peakBalance = autoBalance;

      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📉 Drawdown Máximo:");
      else
         Print("📉 Drawdown Máximo:");

      string typeMsg = (ddType == DD_FINANCIAL) ?
                       "   - Tipo: Financeiro ($" + DoubleToString(ddValue, 2) + ")" :
                       "   - Tipo: Percentual (" + DoubleToString(ddValue, 2) + "%)";
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", typeMsg);
      else
         Print(typeMsg);

      string balMsg = "   - Saldo Inicial (auto): $" + DoubleToString(autoBalance, 2);
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", balMsg);
      else
         Print(balMsg);

      string peakMsg = (ddPeakMode == DD_PEAK_REALIZED_ONLY) ?
                        "   - Pico: Apenas Lucro Realizado (fechados)" :
                        "   - Pico: Incluir P/L Flutuante (fechados + aberta)";
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", peakMsg);
      else
         Print(peakMsg);
     }
   else
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📉 Proteção Drawdown: DESATIVADA");
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
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", dirMsg);
   else
      Print(dirMsg);

// ───────────────────────────────────────────────────────────────
// RESET ESTADO
// ───────────────────────────────────────────────────────────────
   m_currentLossStreak = 0;
   m_currentWinStreak = 0;
   ReconstructStreakFromHistory();  // reconstrói do CSV independente de enableStreak
   m_streakPauseActive = false;
   m_streakPauseUntil = 0;
   m_streakPauseReason = "";
   m_dailyPeakProfit = 0.0;
   m_drawdownProtectionActive = false;
   m_drawdownLimitReached = false;
   m_drawdownActivationTime = 0;
   m_lastResetDate = TimeCurrent();
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

   // Só logar se houve mudança real
   if(oldValue != newMaxSpread)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("Spread máximo alterado: %d → %d pontos", oldValue, newMaxSpread));
      else
         Print("🔄 Spread máximo alterado: ", oldValue, " → ", newMaxSpread, " pontos");
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar direção de trading                          |
//+------------------------------------------------------------------+
void CBlockers::SetTradeDirection(ENUM_TRADE_DIRECTION newDirection)
  {
   ENUM_TRADE_DIRECTION oldDirection = m_tradeDirection;
   m_tradeDirection = newDirection;

   // Só logar se houve mudança real
   if(oldDirection != newDirection)
     {
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
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("Direção alterada: %s → %s", oldText, newText));
      else
         Print("🔄 Direção alterada: ", oldText, " → ", newText);
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar limites diários                             |
//+------------------------------------------------------------------+
void CBlockers::SetDailyLimits(int maxTrades, double maxLoss, double maxGain, ENUM_PROFIT_TARGET_ACTION action)
  {
   int oldMaxTrades = m_maxDailyTrades;
   double oldMaxLoss = m_maxDailyLoss;
   double oldMaxGain = m_maxDailyGain;
   ENUM_PROFIT_TARGET_ACTION oldAction = m_profitTargetAction;

   m_maxDailyTrades = maxTrades;
   m_maxDailyLoss = MathAbs(maxLoss);
   m_maxDailyGain = MathAbs(maxGain);
   m_profitTargetAction = action;
   m_enableDailyLimits = (maxTrades > 0 || m_maxDailyLoss > 0 || m_maxDailyGain > 0);

   // Só logar se houve mudança real
   if(oldMaxTrades != maxTrades || oldMaxLoss != m_maxDailyLoss || oldMaxGain != m_maxDailyGain || oldAction != action)
     {
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "Limites diários alterados:");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "   • Max Trades: " + IntegerToString(maxTrades));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "   • Max Loss: $" + DoubleToString(m_maxDailyLoss, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "   • Max Gain: $" + DoubleToString(m_maxDailyGain, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "   • Ação: " + (action == PROFIT_ACTION_STOP ? "PARAR" : "ATIVAR DD"));
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
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar limites de streak                           |
//+------------------------------------------------------------------+
void CBlockers::SetStreakLimits(int maxLoss, ENUM_STREAK_ACTION lossAction, int lossPause,
                                int maxWin, ENUM_STREAK_ACTION winAction, int winPause)
  {
   int oldMaxLoss = m_maxLossStreak;
   ENUM_STREAK_ACTION oldLossAction = m_lossStreakAction;
   int oldLossPause = m_lossPauseMinutes;
   int oldMaxWin = m_maxWinStreak;
   ENUM_STREAK_ACTION oldWinAction = m_winStreakAction;
   int oldWinPause = m_winPauseMinutes;

   bool wasEnabled = m_enableStreakControl;

   m_maxLossStreak = maxLoss;
   m_lossStreakAction = lossAction;
   m_lossPauseMinutes = lossPause;
   m_maxWinStreak = maxWin;
   m_winStreakAction = winAction;
   m_winPauseMinutes = winPause;

   m_enableStreakControl = (maxLoss > 0 || maxWin > 0);

   // Se ativando pela primeira vez via hot-reload, reconstrói streak do CSV
   if(!wasEnabled && m_enableStreakControl)
      ReconstructStreakFromHistory();

   // Se há pausa ativa, verificar se ainda é válida com os novos limites.
   // Exemplo: pausa ativada com limit=1 (streak=2), usuário sobe para limit=3
   // → a pausa não seria mais justificada e deve ser cancelada.
   if(m_streakPauseActive)
     {
      bool stillBlocked = (m_maxLossStreak > 0 && m_currentLossStreak >= m_maxLossStreak) ||
                          (m_maxWinStreak  > 0 && m_currentWinStreak  >= m_maxWinStreak);
      if(!stillBlocked)
        {
         m_streakPauseActive  = false;
         m_streakPauseUntil   = 0;
         m_streakPauseReason  = "";
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
               "▶️ Pausa de streak cancelada — sequência atual não viola o novo limite");
         else
            Print("▶️ Pausa de streak cancelada — sequência atual não viola o novo limite");
        }
     }

   // Só logar se houve mudança real
   if(oldMaxLoss != maxLoss || oldLossAction != lossAction || oldLossPause != lossPause ||
      oldMaxWin != maxWin || oldWinAction != winAction || oldWinPause != winPause)
     {
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "Limites de streak alterados:");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "   • Loss: Max " + IntegerToString(maxLoss));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            "     └─ " + (lossAction == STREAK_PAUSE ? "Pausar " + IntegerToString(lossPause) + " min" : "Parar dia"));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "   • Win: Max " + IntegerToString(maxWin));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            "     └─ " + (winAction == STREAK_PAUSE ? "Pausar " + IntegerToString(winPause) + " min" : "Parar dia"));
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
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar valor de drawdown                           |
//+------------------------------------------------------------------+
void CBlockers::SetDrawdownValue(double newValue)
  {
   double oldValue = m_drawdownValue;
   bool oldEnabled = m_enableDrawdown;
   m_drawdownValue = newValue;
   m_enableDrawdown = (newValue > 0);

   // Só logar se houve mudança real
   if(oldValue != newValue)
     {
      string typeText = (m_drawdownType == DD_FINANCIAL) ? "$" : "%";

      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("Drawdown alterado: %s%.2f → %s%.2f", typeText, oldValue, typeText, newValue));
      else
         Print("🔄 Drawdown alterado: ", typeText, oldValue, " → ", typeText, newValue);
     }

   if(oldEnabled != m_enableDrawdown)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            "Drawdown: " + (m_enableDrawdown ? "ATIVADO" : "DESATIVADO"));
      else
         Print("🔄 Drawdown: ", m_enableDrawdown ? "ATIVADO" : "DESATIVADO");
     }

   // Se o limite foi atingido anteriormente e o valor mudou, limpar o bloqueio.
   // O próximo tick de CheckDrawdownLimit() re-avalia com o novo valor — se ainda
   // estiver acima do novo limite, o bloqueio volta imediatamente; se não estiver,
   // o EA retoma. Idêntico ao padrão de cancelamento de pausa do streak.
   if(m_drawdownLimitReached && oldValue != newValue)
     {
      m_drawdownLimitReached = false;
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            "▶️ Bloqueio de drawdown liberado — novo limite será reavaliado no próximo tick");
      else
         Print("▶️ Bloqueio de drawdown liberado — novo limite será reavaliado no próximo tick");
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload — Ativa proteção de DD imediatamente se DD foi ligado |
//| via painel sem meta de lucro configurada (fix: bug hot reload)   |
//+------------------------------------------------------------------+
void CBlockers::TryActivateDrawdownNow(double dailyProfit)
  {
   if(!m_enableDrawdown || m_drawdownProtectionActive)
      return;

   ActivateDrawdownProtection(dailyProfit, dailyProfit);

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "🛡️ Drawdown ativado via hot reload — pico inicial: $" +
         DoubleToString(m_dailyPeakProfit, 2));
   else
      Print("🛡️ Drawdown ativado via hot reload — pico inicial: $", m_dailyPeakProfit);
  }

//+------------------------------------------------------------------+
//| SetDrawdownType — altera tipo de drawdown (FINANCEIRO/%)         |
//+------------------------------------------------------------------+
void CBlockers::SetDrawdownType(ENUM_DRAWDOWN_TYPE newType)
  {
   if(m_drawdownType == newType) return;
   m_drawdownType = newType;
   string typeText = (newType == DD_FINANCIAL) ? "FINANCEIRO ($)" : "PERCENTUAL (%)";
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "DrawdownType: " + typeText);
   else
      Print("🔄 DrawdownType: ", typeText);
  }

//+------------------------------------------------------------------+
//| SetDrawdownPeakMode — altera modo de cálculo do pico             |
//+------------------------------------------------------------------+
void CBlockers::SetDrawdownPeakMode(ENUM_DRAWDOWN_PEAK_MODE newMode)
  {
   if(m_drawdownPeakMode == newMode) return;
   m_drawdownPeakMode = newMode;
   string modeText = (newMode == DD_PEAK_REALIZED_ONLY) ? "SO REALIZADO" : "C/ FLUTUANTE";
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "DrawdownPeakMode: " + modeText);
   else
      Print("🔄 DrawdownPeakMode: ", modeText);
  }

//+------------------------------------------------------------------+
//| SetTimeFilter — hot-reload do filtro de horário                  |
//+------------------------------------------------------------------+
void CBlockers::SetTimeFilter(bool enable, int startH, int startM, int endH, int endM)
  {
   m_enableTimeFilter = enable;
   m_startHour        = startH;
   m_startMinute      = startM;
   m_endHour          = endH;
   m_endMinute        = endM;
   string info = enable
      ? StringFormat("ON %02d:%02d -> %02d:%02d", startH, startM, endH, endM)
      : "OFF";
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "TimeFilter: " + info);
   else
      Print("🔄 TimeFilter: ", info);
  }

//+------------------------------------------------------------------+
//| SetCloseOnEndTime — hot-reload do fechar posição ao fim          |
//+------------------------------------------------------------------+
void CBlockers::SetCloseOnEndTime(bool close)
  {
   if(m_closeOnEndTime == close) return;
   m_closeOnEndTime = close;
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "CloseOnEndTime: " + (close ? "ON" : "OFF"));
   else
      Print("🔄 CloseOnEndTime: ", close ? "ON" : "OFF");
  }

//+------------------------------------------------------------------+
//| ReconstructStreakFromHistory — recalcula streak do CSV do dia   |
//+------------------------------------------------------------------+
void CBlockers::ReconstructStreakFromHistory()
  {
   if(m_logger == NULL) return;
   bool results[];
   int count = m_logger.GetDailyTradeResults(results);
   m_currentLossStreak = 0;
   m_currentWinStreak  = 0;
   for(int i = 0; i < count; i++)
     {
      if(results[i]) { m_currentWinStreak++;  m_currentLossStreak = 0; }
      else           { m_currentLossStreak++; m_currentWinStreak  = 0; }
     }
   if(count > 0)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT",
         StringFormat("📊 Streak reconstruído: %dL / %dW consecutivos (de %d trades)",
                      m_currentLossStreak, m_currentWinStreak, count));
  }

//+------------------------------------------------------------------+
//| SetCloseBeforeSessionEnd — hot-reload do fechar antes do fim    |
//+------------------------------------------------------------------+
void CBlockers::SetCloseBeforeSessionEnd(bool close, int minutes)
  {
   bool changed = (m_closeBeforeSessionEnd != close || m_minutesBeforeSessionEnd != minutes);
   m_closeBeforeSessionEnd = close;
   m_minutesBeforeSessionEnd = minutes;
   if(!changed) return;
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         StringFormat("CloseBeforeSessionEnd: %s | %d min", close ? "ON" : "OFF", minutes));
   else
      Print("🔄 CloseBeforeSessionEnd: ", close ? "ON" : "OFF", " | ", minutes, " min");
  }

//+------------------------------------------------------------------+
//| SetNewsFilter — hot-reload dos filtros de janela de notícias     |
//+------------------------------------------------------------------+
void CBlockers::SetNewsFilter(int window, bool enable,
                               int startH, int startM, int endH, int endM)
  {
   if(window < 1 || window > 3) return;

   if(window == 1)
     {
      m_enableNewsFilter1  = enable;
      m_newsStart1Hour     = startH;  m_newsStart1Minute = startM;
      m_newsEnd1Hour       = endH;    m_newsEnd1Minute   = endM;
     }
   else if(window == 2)
     {
      m_enableNewsFilter2  = enable;
      m_newsStart2Hour     = startH;  m_newsStart2Minute = startM;
      m_newsEnd2Hour       = endH;    m_newsEnd2Minute   = endM;
     }
   else
     {
      m_enableNewsFilter3  = enable;
      m_newsStart3Hour     = startH;  m_newsStart3Minute = startM;
      m_newsEnd3Hour       = endH;    m_newsEnd3Minute   = endM;
     }

   string info = enable
      ? StringFormat("ON %02d:%02d -> %02d:%02d", startH, startM, endH, endM)
      : "OFF";
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
                   StringFormat("NewsFilter%d: %s", window, info));
   else
      Print(StringFormat("🔄 NewsFilter%d: %s", window, info));
  }

//+------------------------------------------------------------------+
//| Verifica se pode operar (método principal)                       |
//| ✅ v3.01: Logging de sessão apenas em TRANSIÇÕES de estado      |
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
// ✅ v3.01: PROTEÇÃO DE SESSÃO COM THROTTLING INTELIGENTE
// Loga apenas quando MUDA de estado
// ───────────────────────────────────────────────────────────────
   if(m_closeBeforeSessionEnd)
     {
      MqlDateTime now;
      TimeToStruct(TimeCurrent(), now);

      datetime sessionStart, sessionEnd;

      if(SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)now.day_of_week, 0,
                                sessionStart, sessionEnd))
        {
         MqlDateTime sessionStartTime, sessionEndTime;
         TimeToStruct(sessionStart, sessionStartTime);
         TimeToStruct(sessionEnd,   sessionEndTime);

         int currentMinutes    = now.hour           * 60 + now.min;
         int sessionStartMin   = sessionStartTime.hour * 60 + sessionStartTime.min;
         int sessionEndMin     = sessionEndTime.hour   * 60 + sessionEndTime.min;

         // ✅ v3.01: DETECTAR MERCADOS 24/7 (CRIPTO, FOREX)
         // Se sessão retorna 00:00 → 00:00, significa "sempre aberto"
         if(sessionStartMin == 0 && sessionEndMin == 0)
           {
            // Mercado 24/7 - ignorar proteção de sessão
            static bool s_crypto24x7Logged = false;
            if(!s_crypto24x7Logged && m_logger != NULL)
              {
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", 
                  "🌐 Mercado 24/7 detectado - proteção de sessão DESATIVADA para este símbolo");
               s_crypto24x7Logged = true;
              }
            // Pular toda a lógica de proteção - continuar para próximas verificações
           }
         else
           {
            // ✅ Mercado com horário definido - aplicar proteção normalmente
            int deltaStart = currentMinutes - sessionStartMin;
            int deltaEnd   = sessionEndMin   - currentMinutes;

            // ✅ Determinar estado atual
            ENUM_SESSION_STATE currentState;
         
         if(deltaStart < 0)
            currentState = SESSION_BEFORE;
         else if(deltaEnd < 0)
            currentState = SESSION_AFTER;
         else if(deltaEnd <= m_minutesBeforeSessionEnd)
            currentState = SESSION_PROTECTION;
         else
            currentState = SESSION_ACTIVE;

         // ✅ Variável static para controlar último estado logado
         static ENUM_SESSION_STATE lastLoggedState = SESSION_ACTIVE;

         // ✅ LOGA APENAS SE MUDOU DE ESTADO
         if(currentState != lastLoggedState)
           {
            lastLoggedState = currentState;

            if(m_logger != NULL)
              {
               switch(currentState)
                 {
                  case SESSION_BEFORE:
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "═══════════════════════════════════════════════════════");
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "⏰ Sessão de negociação AINDA NÃO INICIOU");
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION",
                        StringFormat("   Sessão: %02d:%02d → %02d:%02d",
                                    sessionStartTime.hour, sessionStartTime.min,
                                    sessionEndTime.hour,   sessionEndTime.min));
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "   Novas entradas bloqueadas até abertura da sessão");
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "═══════════════════════════════════════════════════════");
                     break;

                  case SESSION_PROTECTION:
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "═══════════════════════════════════════════════════════");
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "⏰ Proteção de Sessão ATIVADA - bloqueando novas entradas");
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION",
                        StringFormat("   Sessão encerra: %02d:%02d", sessionEndTime.hour, sessionEndTime.min));
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION",
                        StringFormat("   Margem segurança: %d minutos", m_minutesBeforeSessionEnd));
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION",
                        StringFormat("   Faltam %d minutos para sessão encerrar", deltaEnd));
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "═══════════════════════════════════════════════════════");
                     break;

                  case SESSION_AFTER:
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "═══════════════════════════════════════════════════════");
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "⏰ Sessão de negociação ENCERRADA");
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION",
                        StringFormat("   Sessão: %02d:%02d → %02d:%02d",
                                    sessionStartTime.hour, sessionStartTime.min,
                                    sessionEndTime.hour,   sessionEndTime.min));
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "   Novas entradas bloqueadas até próxima sessão");
                     m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "═══════════════════════════════════════════════════════");
                     break;

                  case SESSION_ACTIVE:
                     // Não loga nada quando volta ao normal
                     break;
                 }
              }
           }

         // ✅ BLOQUEIA se não estiver ativo
         if(currentState != SESSION_ACTIVE)
           {
            m_currentBlocker = BLOCKER_TIME_FILTER;
            
            switch(currentState)
              {
               case SESSION_BEFORE:
                  blockReason = "Sessão de negociação ainda não iniciou";
                  break;
               case SESSION_PROTECTION:
                  blockReason = StringFormat("Proteção de sessão: faltam %d min (janela %d min)",
                                           deltaEnd, m_minutesBeforeSessionEnd);
                  break;
               case SESSION_AFTER:
                  blockReason = "Sessão de negociação encerrada";
                  break;
              }

            return false;
           }
           } // Fim do else - mercado com horário definido
        }
     }

// ── Filtro de Horário — logging de transição ──
     {
      bool blocked = !CheckTimeFilter();
      static bool s_tfWasBlocked = false;
      if(blocked)
        {
         m_currentBlocker = BLOCKER_TIME_FILTER;
         blockReason = "Fora do horário permitido";
         if(!s_tfWasBlocked && m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
               StringFormat("🕐 FILTRO HORÁRIO: operações bloqueadas | janela %02d:%02d-%02d:%02d",
                            m_startHour, m_startMinute, m_endHour, m_endMinute));
         s_tfWasBlocked = true;
         return false;
        }
      else if(s_tfWasBlocked)
        {
         s_tfWasBlocked = false;
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
               StringFormat("✅ FILTRO HORÁRIO: janela %02d:%02d-%02d:%02d ativa, operações liberadas",
                            m_startHour, m_startMinute, m_endHour, m_endMinute));
        }
     }

// ── Filtro de Notícias — logging de transição ──
     {
      bool blocked = !CheckNewsFilter();
      static bool s_nfWasBlocked = false;
      if(blocked)
        {
         m_currentBlocker = BLOCKER_NEWS_FILTER;
         blockReason = "Horário de volatilidade";
         if(!s_nfWasBlocked && m_logger != NULL)
           {
            MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
            int cur = dt.hour * 60 + dt.min;
            string wDesc = "janela ativa";
            int s1=m_newsStart1Hour*60+m_newsStart1Minute, e1=m_newsEnd1Hour*60+m_newsEnd1Minute;
            int s2=m_newsStart2Hour*60+m_newsStart2Minute, e2=m_newsEnd2Hour*60+m_newsEnd2Minute;
            int s3=m_newsStart3Hour*60+m_newsStart3Minute, e3=m_newsEnd3Hour*60+m_newsEnd3Minute;
            if(m_enableNewsFilter1 && s1<e1 && cur>=s1 && cur<e1)
               wDesc = StringFormat("Janela 1 %02d:%02d-%02d:%02d", m_newsStart1Hour, m_newsStart1Minute, m_newsEnd1Hour, m_newsEnd1Minute);
            else if(m_enableNewsFilter2 && s2<e2 && cur>=s2 && cur<e2)
               wDesc = StringFormat("Janela 2 %02d:%02d-%02d:%02d", m_newsStart2Hour, m_newsStart2Minute, m_newsEnd2Hour, m_newsEnd2Minute);
            else if(m_enableNewsFilter3 && s3<e3 && cur>=s3 && cur<e3)
               wDesc = StringFormat("Janela 3 %02d:%02d-%02d:%02d", m_newsStart3Hour, m_newsStart3Minute, m_newsEnd3Hour, m_newsEnd3Minute);
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
               StringFormat("📰 FILTRO NOTICIAS: operações bloqueadas | %s", wDesc));
           }
         s_nfWasBlocked = true;
         return false;
        }
      else if(s_nfWasBlocked)
        {
         s_nfWasBlocked = false;
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
               "✅ FILTRO NOTICIAS: janela encerrada, operações liberadas");
        }
     }

// ── Filtro de Spread — logging de transição ──
     {
      bool blocked = !CheckSpreadFilter();
      static bool s_sfWasBlocked = false;
      if(blocked)
        {
         m_currentBlocker = BLOCKER_SPREAD;
         long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
         blockReason = StringFormat("Spread alto (%d > %d)", spread, m_maxSpread);
         if(!s_sfWasBlocked && m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
               StringFormat("⛔ SPREAD ALTO: %d pts (máx: %d pts) — operações bloqueadas", spread, m_maxSpread));
         s_sfWasBlocked = true;
         return false;
        }
      else if(s_sfWasBlocked)
        {
         s_sfWasBlocked = false;
         if(m_logger != NULL)
           {
            long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
               StringFormat("✅ SPREAD NORMALIZADO: %d pts — operações liberadas", spread));
           }
        }
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

// ── Limites Diários — logging de transição ──
     {
      bool blocked = !CheckDailyLimits(dailyTrades, dailyProfit);
      static bool s_dlWasBlocked = false;
      static ENUM_BLOCKER_REASON s_dlLastReason = BLOCKER_NONE;
      if(blocked)
        {
         blockReason = GetBlockerReasonText(m_currentBlocker);
         bool isNew = !s_dlWasBlocked || (m_currentBlocker != s_dlLastReason);
         if(isNew && m_logger != NULL)
           {
            string msg;
            switch(m_currentBlocker)
              {
               case BLOCKER_DAILY_TRADES: msg = StringFormat("🔒 MAX TRADES/DIA: %d trades atingido", dailyTrades); break;
               case BLOCKER_DAILY_LOSS:   msg = StringFormat("🔒 MAX PERDA/DIA: $%.2f atingido", MathAbs(dailyProfit)); break;
               case BLOCKER_DAILY_GAIN:   msg = StringFormat("🔒 PROFIT TARGET: $%.2f atingido", dailyProfit); break;
               default:                   msg = "🔒 LIMITE DIÁRIO atingido"; break;
              }
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK", msg);
           }
         s_dlWasBlocked = true;
         s_dlLastReason = m_currentBlocker;
         return false;
        }
      else if(s_dlWasBlocked)
        {
         // Diário só libera no novo dia — ResetDaily() já loga "✅ Contadores zerados!"
         s_dlWasBlocked = false;
         s_dlLastReason = BLOCKER_NONE;
        }
     }

   if(m_enableDailyLimits &&
      m_maxDailyGain > 0 &&
      dailyProfit >= m_maxDailyGain &&
      m_profitTargetAction == PROFIT_ACTION_ENABLE_DRAWDOWN)
     {
      if(!m_drawdownProtectionActive)
        {
         ActivateDrawdownProtection(dailyProfit, dailyProfit);
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
//| Verifica se deve fechar posição por término de horário           |
//| ✅ v3.01: Logging apenas 1x por ticket                          |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseOnEndTime(ulong positionTicket)
  {
   if(!m_enableTimeFilter || !m_closeOnEndTime)
      return false;

   if(!PositionSelectByTicket(positionTicket))
      return false;

// Validar Magic Number
   long posMagic = PositionGetInteger(POSITION_MAGIC);
   if(posMagic != m_magicNumber)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "TIME_CLOSE",
            "Ignorando posição #" + IntegerToString((int)positionTicket) +
            " (Magic " + IntegerToString((int)posMagic) + " ≠ " +
            IntegerToString(m_magicNumber) + ")");
      return false;
     }

   datetime now = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(now, dt);

   int currentMinutes = dt.hour * 60 + dt.min;
   int startMinutes   = m_startHour * 60 + m_startMinute;
   int endMinutes     = m_endHour   * 60 + m_endMinute;

   bool shouldClose = false;

// Janela normal no mesmo dia
   if(startMinutes <= endMinutes)
     {
      if(currentMinutes >= endMinutes)
         shouldClose = true;
     }
// Janela que atravessa meia-noite
   else
     {
      if(currentMinutes >= endMinutes && currentMinutes < startMinutes)
         shouldClose = true;
     }

   if(shouldClose)
     {
      // ✅ v3.01: Log apenas 1x por ticket usando static
      static ulong lastLoggedTicket = 0;
      
      if(lastLoggedTicket != positionTicket)
        {
         lastLoggedTicket = positionTicket;
         
         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "TIME_CLOSE", "⏰ Término de horário de operação atingido");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "TIME_CLOSE",
               "   Horário: " + StringFormat("%02d:%02d - %02d:%02d", 
                  m_startHour, m_startMinute, m_endHour, m_endMinute));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "TIME_CLOSE",
               "   Posição #" + IntegerToString((int)positionTicket) + " deve ser fechada");
           }
        }

      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição antes do fim da sessão           |
//| ✅ v3.01: Logging apenas 1x por ticket                          |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseBeforeSessionEnd(ulong positionTicket)
  {
   if(!m_closeBeforeSessionEnd)
      return false;

   if(!PositionSelectByTicket(positionTicket))
      return false;

// Validar Magic Number
   long posMagic = PositionGetInteger(POSITION_MAGIC);
   if(posMagic != m_magicNumber)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "SESSION_CLOSE",
            "Ignorando posição #" + IntegerToString((int)positionTicket) +
            " (Magic " + IntegerToString((int)posMagic) + " ≠ " +
            IntegerToString(m_magicNumber) + ")");
      return false;
     }

   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);

   datetime sessionStart, sessionEnd;

   if(!SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)now.day_of_week, 0, sessionStart, sessionEnd))
      return false;

   MqlDateTime sessionEndTime;
   TimeToStruct(sessionEnd, sessionEndTime);

   int currentMinutes     = now.hour * 60 + now.min;
   int sessionEndMinutes  = sessionEndTime.hour * 60 + sessionEndTime.min;

   if(sessionEndMinutes < currentMinutes)
      sessionEndMinutes += 24 * 60;

   int minutesUntilSessionEnd = sessionEndMinutes - currentMinutes;

   if(minutesUntilSessionEnd <= m_minutesBeforeSessionEnd && minutesUntilSessionEnd >= 0)
     {
      // ✅ v3.01: Log apenas 1x por ticket usando static
      static ulong lastLoggedTicket = 0;
      
      if(lastLoggedTicket != positionTicket)
        {
         lastLoggedTicket = positionTicket;
         
         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION_CLOSE", "════════════════════════════════════════════════════════════════");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION_CLOSE", "⏰ Proteção de Sessão - fechando posição existente");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION_CLOSE",
               StringFormat("   Sessão encerra: %02d:%02d", sessionEndTime.hour, sessionEndTime.min));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION_CLOSE",
               StringFormat("   Margem: %d min | Faltam: %d min", 
                  m_minutesBeforeSessionEnd, minutesUntilSessionEnd));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION_CLOSE",
               "   Posição #" + IntegerToString((int)positionTicket) + " deve ser fechada");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION_CLOSE", "════════════════════════════════════════════════════════════════");
           }
        }

      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição por limite diário atingido       |
//| ✅ v3.03: Calcula lucro PROJETADO (fechados + aberta)           |
//| Fecha NO EXATO MOMENTO que atinge o limite                       |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseByDailyLimit(ulong positionTicket, double dailyProfit, string &closeReason)
  {
   closeReason = "";

// Se limites diários estiverem desativados, não faz nada
   if(!m_enableDailyLimits)
      return false;

// ═══════════════════════════════════════════════════════════════
// SELECIONAR POSIÇÃO E CALCULAR LUCRO PROJETADO
// ═══════════════════════════════════════════════════════════════
   if(!PositionSelectByTicket(positionTicket))
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DAILY_LIMIT",
            "Erro ao selecionar posição #" + IntegerToString((int)positionTicket));
      return false;
     }

// Validar Magic Number
   long posMagic = PositionGetInteger(POSITION_MAGIC);
   if(posMagic != m_magicNumber)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DAILY_LIMIT",
            "Ignorando posição #" + IntegerToString((int)positionTicket) +
            " (Magic " + IntegerToString((int)posMagic) + " ≠ " +
            IntegerToString(m_magicNumber) + ")");
      return false;
     }

// ✅ PEGA LUCRO EM TEMPO REAL DA POSIÇÃO ABERTA
   double currentProfit = PositionGetDouble(POSITION_PROFIT);
   double swap = PositionGetDouble(POSITION_SWAP);
   
// ✅ CALCULA LUCRO SE FECHAR AGORA (fechados + aberta)
   double projectedProfit = dailyProfit + currentProfit + swap;

// ═══════════════════════════════════════════════════════════════
// VERIFICAR LIMITE DE PERDA DIÁRIA (lucro projetado)
// ═══════════════════════════════════════════════════════════════
   if(m_maxDailyLoss > 0 && projectedProfit <= -m_maxDailyLoss)
     {
      closeReason = StringFormat("LIMITE DE PERDA DIÁRIA ATINGIDO: %.2f / %.2f",
                                projectedProfit, -m_maxDailyLoss);

      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT", "════════════════════════════════════════════════════════════════");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT", "🚨 LIMITE DE PERDA DIÁRIA ATINGIDO!");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
            "   📉 Perda projetada: $" + DoubleToString(projectedProfit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
            "   🛑 Limite configurado: $" + DoubleToString(-m_maxDailyLoss, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
            "   📊 Composição: Fechados=$" + DoubleToString(dailyProfit, 2) +
            " + Aberta=$" + DoubleToString(currentProfit, 2) +
            " + Swap=$" + DoubleToString(swap, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
            "   ✅ FECHANDO POSIÇÃO IMEDIATAMENTE para proteger capital");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT", "════════════════════════════════════════════════════════════════");
        }
      else
        {
         Print("════════════════════════════════════════════════════════════════");
         Print("🚨 LIMITE DE PERDA DIÁRIA ATINGIDO!");
         Print("   📉 Perda projetada: $", DoubleToString(projectedProfit, 2));
         Print("   🛑 Limite configurado: $", DoubleToString(-m_maxDailyLoss, 2));
         Print("   ✅ FECHANDO POSIÇÃO IMEDIATAMENTE");
         Print("════════════════════════════════════════════════════════════════");
        }

      return true;
     }

// ═══════════════════════════════════════════════════════════════
// VERIFICAR LIMITE DE GANHO DIÁRIO (lucro projetado)
// ═══════════════════════════════════════════════════════════════
   if(m_maxDailyGain > 0 && projectedProfit >= m_maxDailyGain)
     {
      // Se ação for PARAR, fecha imediatamente
      if(m_profitTargetAction == PROFIT_ACTION_STOP)
        {
         closeReason = StringFormat("META DE GANHO DIÁRIA ATINGIDA: %.2f / %.2f",
                                   projectedProfit, m_maxDailyGain);

         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT", "════════════════════════════════════════════════════════════════");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT", "🎯 META DE GANHO DIÁRIA ATINGIDA!");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
               "   📈 Lucro projetado: $" + DoubleToString(projectedProfit, 2));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
               "   🎯 Meta configurada: $" + DoubleToString(m_maxDailyGain, 2));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
               "   📊 Composição: Fechados=$" + DoubleToString(dailyProfit, 2) +
               " + Aberta=$" + DoubleToString(currentProfit, 2) +
               " + Swap=$" + DoubleToString(swap, 2));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT",
               "   ✅ FECHANDO POSIÇÃO IMEDIATAMENTE - Meta atingida!");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DAILY_LIMIT", "════════════════════════════════════════════════════════════════");
           }
         else
           {
            Print("════════════════════════════════════════════════════════════════");
            Print("🎯 META DE GANHO DIÁRIA ATINGIDA!");
            Print("   📈 Lucro projetado: $", DoubleToString(projectedProfit, 2));
            Print("   🎯 Meta configurada: $", DoubleToString(m_maxDailyGain, 2));
            Print("   ✅ FECHANDO POSIÇÃO IMEDIATAMENTE");
            Print("════════════════════════════════════════════════════════════════");
           }

         return true;
        }
      // Se ação for ATIVAR DRAWDOWN, só ativa mas NÃO fecha
      else // PROFIT_ACTION_ENABLE_DRAWDOWN
        {
         // Ativa proteção de drawdown se ainda não estiver ativa
         if(!m_drawdownProtectionActive)
           {
            ActivateDrawdownProtection(dailyProfit, projectedProfit);
           }

         // Continua verificando drawdown (não fecha ainda)
         closeReason = "";
         return false;
        }
     }

// ═══════════════════════════════════════════════════════════════
// NENHUM LIMITE ATINGIDO - PODE CONTINUAR
// ═══════════════════════════════════════════════════════════════
   return false;
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição por drawdown atingido            |
//| ✅ v3.04: Calcula drawdown com lucro PROJETADO em tempo real    |
//| Fecha NO EXATO MOMENTO que atinge limite de drawdown            |
//+------------------------------------------------------------------+
bool CBlockers::ShouldCloseByDrawdown(ulong positionTicket, double dailyProfit, string &closeReason)
  {
   closeReason = "";

// Só funciona se proteção de drawdown estiver ATIVA
   if(!m_drawdownProtectionActive)
      return false;

// Se já atingiu limite antes, não precisa verificar de novo
   if(m_drawdownLimitReached)
      return false;

// ═══════════════════════════════════════════════════════════════
// SELECIONAR POSIÇÃO E CALCULAR LUCRO PROJETADO
// ═══════════════════════════════════════════════════════════════
   if(!PositionSelectByTicket(positionTicket))
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DRAWDOWN",
            "Erro ao selecionar posição #" + IntegerToString((int)positionTicket));
      return false;
     }

// Validar Magic Number
   long posMagic = PositionGetInteger(POSITION_MAGIC);
   if(posMagic != m_magicNumber)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DRAWDOWN",
            "Ignorando posição #" + IntegerToString((int)positionTicket) +
            " (Magic " + IntegerToString((int)posMagic) + " ≠ " +
            IntegerToString(m_magicNumber) + ")");
      return false;
     }

// ✅ PEGA LUCRO EM TEMPO REAL DA POSIÇÃO ABERTA
   double currentProfit = PositionGetDouble(POSITION_PROFIT);
   double swap = PositionGetDouble(POSITION_SWAP);
   
// ✅ CALCULA LUCRO PROJETADO SE FECHAR AGORA
   double projectedProfit = dailyProfit + currentProfit + swap;

// ═══════════════════════════════════════════════════════════════
// ATUALIZAR PICO DE LUCRO SE NECESSÁRIO
// ═══════════════════════════════════════════════════════════════
   double peakCandidate = (m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY) ? dailyProfit : projectedProfit;
   if(peakCandidate > m_dailyPeakProfit)
     {
      m_dailyPeakProfit = peakCandidate;

      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_TIME, "DRAWDOWN",
            "🔼 Novo pico de lucro: $" + DoubleToString(m_dailyPeakProfit, 2), 60);
     }

// ═══════════════════════════════════════════════════════════════
// CALCULAR DRAWDOWN ATUAL
// ═══════════════════════════════════════════════════════════════
   double currentDD = m_dailyPeakProfit - projectedProfit;
   double ddLimit = 0;

   if(m_drawdownType == DD_FINANCIAL)
     {
      // Drawdown financeiro (valor fixo em $)
      ddLimit = m_drawdownValue;
     }
   else
     {
      // Drawdown percentual (% do pico)
      ddLimit = (m_dailyPeakProfit * m_drawdownValue) / 100.0;
     }

// Log de debug a cada 60s mostrando situação atual
   static datetime lastDebugLog = 0;
   if(TimeCurrent() - lastDebugLog >= 60)
     {
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DRAWDOWN",
            StringFormat("📊 Drawdown: Pico=%.2f | Projetado=%.2f | DD=%.2f / %.2f",
                        m_dailyPeakProfit, projectedProfit, currentDD, ddLimit));
        }
      lastDebugLog = TimeCurrent();
     }

// ═══════════════════════════════════════════════════════════════
// VERIFICAR SE ATINGIU LIMITE DE DRAWDOWN
// ═══════════════════════════════════════════════════════════════
   if(currentDD >= ddLimit)
     {
      m_drawdownLimitReached = true;

      // Montar mensagem de fechamento
      if(m_drawdownType == DD_FINANCIAL)
        {
         closeReason = StringFormat("LIMITE DE DRAWDOWN ATINGIDO: %.2f / %.2f (Financeiro)",
                                   currentDD, ddLimit);
        }
      else
        {
         double ddPercent = (currentDD / m_dailyPeakProfit) * 100.0;
         closeReason = StringFormat("LIMITE DE DRAWDOWN ATINGIDO: %.1f%% / %.1f%%",
                                   ddPercent, m_drawdownValue);
        }

      // Logs detalhados
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "════════════════════════════════════════════════════════════════");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "🛑 LIMITE DE DRAWDOWN ATINGIDO!");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
            "   📊 Pico do dia: $" + DoubleToString(m_dailyPeakProfit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
            "   💰 Lucro projetado: $" + DoubleToString(projectedProfit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
            "   📉 Drawdown atual: $" + DoubleToString(currentDD, 2));

         if(m_drawdownType == DD_FINANCIAL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
               "   🛑 Limite: $" + DoubleToString(ddLimit, 2) + " (Financeiro)");
           }
         else
           {
            double ddPercent = (currentDD / m_dailyPeakProfit) * 100.0;
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
               StringFormat("   🛑 Limite: %.1f%% = $%.2f", m_drawdownValue, ddLimit));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
               StringFormat("   📊 DD atual: %.1f%%", ddPercent));
           }

         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
            "   📊 Composição: Fechados=$" + DoubleToString(dailyProfit, 2) +
            " + Aberta=$" + DoubleToString(currentProfit, 2) +
            " + Swap=$" + DoubleToString(swap, 2));

         string modeStr = (m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY) ? "realizado" : "projetado";
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
            "   🛡️ Ativado às " + TimeToString(m_drawdownActivationTime, TIME_MINUTES) +
            " | Pico inicial (" + modeStr + "): $" + DoubleToString(m_dailyPeakProfit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
            "   🛡️ LUCRO PROTEGIDO! Fechando posição IMEDIATAMENTE");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "════════════════════════════════════════════════════════════════");
        }
      else
        {
         Print("════════════════════════════════════════════════════════════════");
         Print("🛑 LIMITE DE DRAWDOWN ATINGIDO!");
         Print("   📊 Pico do dia: $", DoubleToString(m_dailyPeakProfit, 2));
         Print("   💰 Lucro projetado: $", DoubleToString(projectedProfit, 2));
         Print("   📉 Drawdown atual: $", DoubleToString(currentDD, 2));

         if(m_drawdownType == DD_FINANCIAL)
            Print("   🛑 Limite: $", DoubleToString(ddLimit, 2), " (Financeiro)");
         else
           {
            double ddPercent = (currentDD / m_dailyPeakProfit) * 100.0;
            Print("   🛑 Limite: ", DoubleToString(m_drawdownValue, 1), "% = $", DoubleToString(ddLimit, 2));
            Print("   📊 DD atual: ", DoubleToString(ddPercent, 1), "%");
           }

         string modeStr2 = (m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY) ? "realizado" : "projetado";
         Print("   🛡️ Ativado às ", TimeToString(m_drawdownActivationTime, TIME_MINUTES),
            " | Pico inicial (", modeStr2, "): $", DoubleToString(m_dailyPeakProfit, 2));
         Print("   🛡️ LUCRO PROTEGIDO! Fechando posição IMEDIATAMENTE");
         Print("════════════════════════════════════════════════════════════════");
        }

      return true;
     }

// ═══════════════════════════════════════════════════════════════
// DRAWDOWN DENTRO DO LIMITE - PODE CONTINUAR
// ═══════════════════════════════════════════════════════════════
   return false;
  }

//+------------------------------------------------------------------+
//| Atualiza estado após um trade                                    |
//+------------------------------------------------------------------+
void CBlockers::UpdateAfterTrade(bool isWin, double tradeProfit)
  {
   // Contadores sempre atualizados (independente de m_enableStreakControl),
   // para que hot-reload de limites encontre o streak correto.
   if(isWin)
     {
      m_currentWinStreak++;
      m_currentLossStreak = 0;

      if(m_maxWinStreak > 0 && m_currentWinStreak >= m_maxWinStreak)
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
               "⚠️ WIN STREAK ATINGIDO: " + IntegerToString(m_currentWinStreak) + " ganhos consecutivos!");
         else
            Print("⚠️ WIN STREAK ATINGIDO: ", m_currentWinStreak, " ganhos consecutivos!");
        }
     }
   else
     {
      m_currentLossStreak++;
      m_currentWinStreak = 0;

      if(m_maxLossStreak > 0 && m_currentLossStreak >= m_maxLossStreak)
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK",
               "⚠️ LOSS STREAK ATINGIDO: " + IntegerToString(m_currentLossStreak) + " perdas consecutivas!");
         else
            Print("⚠️ LOSS STREAK ATINGIDO: ", m_currentLossStreak, " perdas consecutivas!");
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
void CBlockers::ActivateDrawdownProtection(double closedProfit, double projectedProfit)
  {
   if(!m_enableDrawdown)
      return;

   m_drawdownProtectionActive = true;
   m_drawdownActivationTime = TimeCurrent();

   // Escolher pico baseado no modo configurado
   if(m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY)
      m_dailyPeakProfit = closedProfit;
   else
      m_dailyPeakProfit = projectedProfit;

   string modeStr = (m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY) ? "realizado" : "projetado";

   if(m_logger != NULL)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "═══════════════════════════════════════════════════════");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "🛡️ PROTEÇÃO DE DRAWDOWN ATIVADA!");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "   Pico de lucro (" + modeStr + "): $" + DoubleToString(m_dailyPeakProfit, 2));

      if(m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
            "   📊 Fechados: $" + DoubleToString(closedProfit, 2) +
            " | Projetado: $" + DoubleToString(projectedProfit, 2));

      if(m_drawdownType == DD_FINANCIAL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
            "   Proteção: Máx $" + DoubleToString(m_drawdownValue, 2) + " de drawdown");
      else
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
            "   Proteção: Máx " + DoubleToString(m_drawdownValue, 1) + "% de drawdown");

      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "═══════════════════════════════════════════════════════");
     }
   else
     {
      Print("═══════════════════════════════════════════════════════");
      Print("🛡️ PROTEÇÃO DE DRAWDOWN ATIVADA!");
      Print("   Pico de lucro (", modeStr, "): $", DoubleToString(m_dailyPeakProfit, 2));

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
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "RESET", "🔄 RESET DIÁRIO - Limpando contadores...");
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
   m_drawdownActivationTime = 0;
   m_currentBlocker = BLOCKER_NONE;
   m_lastResetDate = TimeCurrent();

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "RESET", "✅ Contadores zerados!");
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

   // Inclui floating + swap de posições abertas do EA, igual ao ShouldCloseByDrawdown()
   // Evita inconsistência onde painel mostrava DD menor que o usado para fechar
   double floating = 0.0, swap = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
        {
         floating += PositionGetDouble(POSITION_PROFIT);
         swap     += PositionGetDouble(POSITION_SWAP);
        }
     }

   double closedProfit = (m_logger != NULL) ? m_logger.GetDailyProfit() : 0.0;
   double projectedProfit = closedProfit + floating + swap;

   if(projectedProfit >= m_dailyPeakProfit)
      return 0.0;

   double currentDD = m_dailyPeakProfit - projectedProfit;

   if(m_drawdownType == DD_FINANCIAL)
      return currentDD;

   return (currentDD / m_dailyPeakProfit) * 100.0;
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
      return (currentMinutes >= startMinutes && currentMinutes < endMinutes);
     }

   return (currentMinutes >= startMinutes || currentMinutes < endMinutes);
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
         if(currentMinutes >= newsStart1 && currentMinutes < newsEnd1)
            return false;
        }
     }

   if(m_enableNewsFilter2)
     {
      int newsStart2 = m_newsStart2Hour * 60 + m_newsStart2Minute;
      int newsEnd2 = m_newsEnd2Hour * 60 + m_newsEnd2Minute;

      if(newsStart2 < newsEnd2)
        {
         if(currentMinutes >= newsStart2 && currentMinutes < newsEnd2)
            return false;
        }
     }

   if(m_enableNewsFilter3)
     {
      int newsStart3 = m_newsStart3Hour * 60 + m_newsStart3Minute;
      int newsEnd3 = m_newsEnd3Hour * 60 + m_newsEnd3Minute;

      if(newsStart3 < newsEnd3)
        {
         if(currentMinutes >= newsStart3 && currentMinutes < newsEnd3)
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
            ActivateDrawdownProtection(dailyProfit, dailyProfit);
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

// ═══════════════════════════════════════════════════════════════
// VERIFICAR SE PAUSA ESTÁ ATIVA
// ═══════════════════════════════════════════════════════════════
   if(m_streakPauseActive)
     {
      if(TimeCurrent() < m_streakPauseUntil)
        {
         // ✅ LOG_DEBUG com throttle de 300s (loga a cada 5min)
         int remainingMinutes = (int)((m_streakPauseUntil - TimeCurrent()) / 60);

         m_logger.Log(LOG_DEBUG, THROTTLE_TIME, "STREAK",
            "⏸️ EA pausado - Restam " + IntegerToString(remainingMinutes) +
            " minutos | Motivo: " + m_streakPauseReason,
            300);

         return false;
        }
      else
        {
         // ✅ Pausa finalizada - LOG_EVENT sem throttle (acontece 1x)
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
            Print("   📊 Sequência que causou pausa: ", m_streakPauseReason);
            Print("   🔄 Contadores zerados - pronto para novo ciclo");
           }

         m_streakPauseActive = false;
         m_streakPauseReason = "";
         m_currentWinStreak = 0;
         m_currentLossStreak = 0;

         return true;
        }
     }

// ═══════════════════════════════════════════════════════════════
// VERIFICAR SE ATINGIU LOSS STREAK
// ═══════════════════════════════════════════════════════════════
   if(m_maxLossStreak > 0 && m_currentLossStreak >= m_maxLossStreak)
     {
      // ✅ Ativando pausa - LOG_EVENT sem throttle (acontece 1x)
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", "🛑 SEQUÊNCIA DE PERDAS ATINGIDA!");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", 
            "   📉 Perdas consecutivas: " + IntegerToString(m_currentLossStreak));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", 
            "   🎯 Limite configurado: " + IntegerToString(m_maxLossStreak));
        }
      else
        {
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
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", 
               "   ⏱️ Tempo da pausa: " + IntegerToString(m_lossPauseMinutes) + " minutos");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", 
               "   🔄 Retorno previsto: " + TimeToString(m_streakPauseUntil, TIME_DATE|TIME_MINUTES));
           }
         else
           {
            Print("   ⏱️ Tempo da pausa: ", m_lossPauseMinutes, " minutos");
            Print("   🔄 Retorno previsto: ", TimeToString(m_streakPauseUntil, TIME_DATE|TIME_MINUTES));
           }
        }
      else
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", "   🛑 EA PAUSADO até o FIM DO DIA");
         else
            Print("   🛑 EA PAUSADO até o FIM DO DIA");
        }

      return false;
     }

// ═══════════════════════════════════════════════════════════════
// VERIFICAR SE ATINGIU WIN STREAK
// ═══════════════════════════════════════════════════════════════
   if(m_maxWinStreak > 0 && m_currentWinStreak >= m_maxWinStreak)
     {
      // ✅ Ativando pausa - LOG_EVENT sem throttle (acontece 1x)
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", "🎯 SEQUÊNCIA DE GANHOS ATINGIDA!");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", 
            "   📈 Ganhos consecutivos: " + IntegerToString(m_currentWinStreak));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", 
            "   🎯 Limite configurado: " + IntegerToString(m_maxWinStreak));
        }
      else
        {
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
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", 
               "   ⏱️ Tempo da pausa: " + IntegerToString(m_winPauseMinutes) + " minutos");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", 
               "   🔄 Retorno previsto: " + TimeToString(m_streakPauseUntil, TIME_DATE|TIME_MINUTES));
           }
         else
           {
            Print("   ⏱️ Tempo da pausa: ", m_winPauseMinutes, " minutos");
            Print("   🔄 Retorno previsto: ", TimeToString(m_streakPauseUntil, TIME_DATE|TIME_MINUTES));
           }
        }
      else
        {
         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", "   🎯 META DE SEQUÊNCIA ATINGIDA!");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STREAK", "   🛑 EA PAUSADO até o FIM DO DIA");
           }
         else
           {
            Print("   🎯 META DE SEQUÊNCIA ATINGIDA!");
            Print("   🛑 EA PAUSADO até o FIM DO DIA");
           }
        }

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

// ✅ v3.20: usa lucro do dia (fechados) + floating, consistente com
// ShouldCloseByDrawdown() — não usa mais ACCOUNT_BALANCE - m_initialBalance
// que causava corrupção do pico quando DD era ligado via hot reload
// com EA iniciado sem DD (m_initialBalance == 0)
   double dailyProfit = (m_logger != NULL) ? m_logger.GetDailyProfit() : 0.0;

   double floating = 0.0, swap = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
        {
         floating += PositionGetDouble(POSITION_PROFIT);
         swap     += PositionGetDouble(POSITION_SWAP);
        }
     }
   double projectedProfit = dailyProfit + floating + swap;

   double peakCandidate = (m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY) ? dailyProfit : projectedProfit;
   if(peakCandidate > m_dailyPeakProfit)
      m_dailyPeakProfit = peakCandidate;

   double currentProfit = projectedProfit;
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
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "═══════════════════════════════════════════════════════");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "🛑 LIMITE DE DRAWDOWN ATINGIDO!");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", 
            "   📊 Pico do dia: $" + DoubleToString(m_dailyPeakProfit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", 
            "   💰 Lucro atual: $" + DoubleToString(currentProfit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", 
            "   📉 Drawdown: $" + DoubleToString(currentDD, 2));

         if(m_drawdownType == DD_FINANCIAL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", 
               "   🛑 Limite: $" + DoubleToString(ddLimit, 2) + " (Financeiro)");
         else
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", 
               "   🛑 Limite: " + DoubleToString(m_drawdownValue, 1) + "% = $" + DoubleToString(ddLimit, 2));

         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", 
            "   🛡️ LUCRO PROTEGIDO! EA pausado até o fim do dia");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "═══════════════════════════════════════════════════════");
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

   if(m_currentBlocker != BLOCKER_NONE)
     {
      string msg = "🚫 BLOQUEADO: " + GetBlockerReasonText(m_currentBlocker);
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", msg);
      else
         Print(msg);
     }
   else
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "✅ LIBERADO PARA OPERAR");
      else
         Print("✅ LIBERADO PARA OPERAR");
     }

   if(m_logger != NULL)
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "");
   else
      Print("");

   if(m_enableTimeFilter)
     {
      datetime now = TimeCurrent();
      MqlDateTime t;
      TimeToStruct(now, t);

      if(m_logger != NULL)
        {
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "⏰ Horário:");
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "   Atual: " + StringFormat("%02d:%02d", t.hour, t.min));
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", 
            "   Permitido: " + StringFormat("%02d:%02d - %02d:%02d", m_startHour, m_startMinute, m_endHour, m_endMinute));
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "   Status: " + (CheckTimeFilter() ? "✅ OK" : "❌ BLOQUEADO"));
        }
      else
        {
         Print("⏰ Horário:");
         Print("   Atual: ", StringFormat("%02d:%02d", t.hour, t.min));
         Print("   Permitido: ", StringFormat("%02d:%02d - %02d:%02d", m_startHour, m_startMinute, m_endHour, m_endMinute));
         Print("   Status: ", CheckTimeFilter() ? "✅ OK" : "❌ BLOQUEADO");
        }
     }

   if(m_enableStreakControl)
     {
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "");
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "🔴 Streaks:");
         if(m_maxLossStreak > 0)
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", 
               "   Loss: " + IntegerToString(m_currentLossStreak) + " de " + IntegerToString(m_maxLossStreak));
         if(m_maxWinStreak > 0)
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", 
               "   Win: " + IntegerToString(m_currentWinStreak) + " de " + IntegerToString(m_maxWinStreak));

         if(m_streakPauseActive)
           {
            int remaining = (int)((m_streakPauseUntil - TimeCurrent()) / 60);
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", 
               "   ⏸️ PAUSADO: " + m_streakPauseReason + " (" + IntegerToString(remaining) + " min)");
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
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "");
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "📉 Drawdown (proteção ativa):");
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "   Pico: $" + DoubleToString(m_dailyPeakProfit, 2));
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "   Atual: $" + DoubleToString(currentProfit, 2));
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", "   DD: $" + DoubleToString(currentDD, 2));
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "STATUS", 
            "   Status: " + (m_drawdownLimitReached ? "❌ LIMITE ATINGIDO" : "✅ OK"));
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
     }
   else
     {
      Print("╔══════════════════════════════════════════════════════╗");
      Print("║         BLOCKERS - CONFIGURAÇÃO COMPLETA            ║");
      Print("╚══════════════════════════════════════════════════════╝");
      Print("");
     }

   if(m_logger != NULL)
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "⏰ Horário:");
   else
      Print("⏰ Horário:");

   if(m_enableTimeFilter)
     {
      string msg = "   " + StringFormat("%02d:%02d - %02d:%02d", m_startHour, m_startMinute, m_endHour, m_endMinute);
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", msg);
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "   Fecha ao fim: " + (m_closeOnEndTime ? "SIM" : "NÃO"));
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
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "   DESATIVADO");
      else
         Print("   DESATIVADO");
     }

   if(m_logger != NULL)
     {
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "═══════════════════════════════════════════════════════");
     }
   else
     {
      Print("");
      Print("═══════════════════════════════════════════════════════");
     }
  }
//+------------------------------------------------------------------+
