//+------------------------------------------------------------------+
//|                                             BlockerFilters.mqh   |
//|                                         Copyright 2026, EP Filho |
//|              Filtros de Condição de Mercado - EPBot Matrix       |
//|                     Versão 1.02 - Claude Parte 031 (Claude Code) |
// CHANGELOG v1.02 (Parte 031):
// * Limpeza: removidos `if(m_logger != NULL)` e `else Print()` fallbacks
//
// CHANGELOG v1.01 (Parte 027):
// + SetMagicNumber() / GetMagicNumber() — hot reload do Magic Number
//+------------------------------------------------------------------+
// NOTA: Enums (ENUM_BLOCKER_REASON, ENUM_SESSION_STATE, etc.) e
// Logger.mqh são incluídos por Blockers.mqh ANTES deste arquivo.
#ifndef BLOCKER_FILTERS_MQH
#define BLOCKER_FILTERS_MQH

//+------------------------------------------------------------------+
//| Classe: CBlockerFilters                                          |
//| Filtros de condição de mercado: Horário + Notícias + Spread      |
//+------------------------------------------------------------------+
class CBlockerFilters
  {
private:
   CLogger*          m_logger;
   int               m_magicNumber;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - HORÁRIO
   // ═══════════════════════════════════════════════════════════════
   bool              m_inputEnableTimeFilter;
   int               m_inputStartHour;
   int               m_inputStartMinute;
   int               m_inputEndHour;
   int               m_inputEndMinute;
   bool              m_inputCloseOnEndTime;
   bool              m_closeBeforeSessionEnd;
   int               m_minutesBeforeSessionEnd;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - HORÁRIO
   // ═══════════════════════════════════════════════════════════════
   bool              m_enableTimeFilter;
   int               m_startHour;
   int               m_startMinute;
   int               m_endHour;
   int               m_endMinute;
   bool              m_closeOnEndTime;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - NEWS FILTERS
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
   // WORKING PARAMETERS - NEWS FILTERS
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
   // INPUT / WORKING PARAMETERS - SPREAD
   // ═══════════════════════════════════════════════════════════════
   int               m_inputMaxSpread;
   int               m_maxSpread;

   // ═══════════════════════════════════════════════════════════════
   // ESTADO DE TRANSIÇÃO (convertido de statics locais em CanTrade)
   // ═══════════════════════════════════════════════════════════════
   bool               m_sCrypto24x7Logged;
   ENUM_SESSION_STATE m_sLastSessionState;
   bool               m_sTfWasBlocked;
   bool               m_sNfWasBlocked;
   bool               m_sSfWasBlocked;
   ulong              m_sCloseOnEndLastTicket;
   ulong              m_sCloseBeforeSessionLastTicket;

   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS
   // ═══════════════════════════════════════════════════════════════
   bool              CheckTimeFilter();
   bool              CheckNewsFilter();
   bool              CheckSpreadFilter();

public:
                     CBlockerFilters();
                    ~CBlockerFilters();

   bool              Init(
      CLogger* logger,
      int magicNumber,
      bool enableTime, int startH, int startM, int endH, int endM,
      bool closeOnEnd, bool closeBeforeSessionEnd, int minutesBeforeSessionEnd,
      bool news1, int n1StartH, int n1StartM, int n1EndH, int n1EndM,
      bool news2, int n2StartH, int n2StartM, int n2EndH, int n2EndM,
      bool news3, int n3StartH, int n3StartM, int n3EndH, int n3EndM,
      int maxSpread
   );

   // ═══════════════════════════════════════════════════════════════
   // VERIFICAÇÕES PARA CanTrade (chamadas por CBlockers)
   // ═══════════════════════════════════════════════════════════════
   bool              CheckSessionBlocking(ENUM_BLOCKER_REASON &blocker, string &blockReason);
   bool              CheckTimeWithLog(ENUM_BLOCKER_REASON &blocker, string &blockReason);
   bool              CheckNewsWithLog(ENUM_BLOCKER_REASON &blocker, string &blockReason);
   bool              CheckSpreadWithLog(ENUM_BLOCKER_REASON &blocker, string &blockReason);

   // ═══════════════════════════════════════════════════════════════
   // FECHAMENTO DE POSIÇÕES
   // ═══════════════════════════════════════════════════════════════
   bool              ShouldCloseOnEndTime(ulong positionTicket);
   bool              ShouldCloseBeforeSessionEnd(ulong positionTicket);

   // ═══════════════════════════════════════════════════════════════
   // HOT RELOAD
   // ═══════════════════════════════════════════════════════════════
   void              SetTimeFilter(bool enable, int startH, int startM, int endH, int endM);
   void              SetCloseOnEndTime(bool close);
   void              SetCloseBeforeSessionEnd(bool close, int minutes);
   void              SetNewsFilter(int window, bool enable, int startH, int startM, int endH, int endM);
   void              SetMaxSpread(int newMaxSpread);
   void              SetMagicNumber(int newMagic);

   // ═══════════════════════════════════════════════════════════════
   // GETTERS
   // ═══════════════════════════════════════════════════════════════
   int               GetMaxSpread() const      { return m_maxSpread; }
   int               GetInputMaxSpread() const { return m_inputMaxSpread; }
   int               GetMagicNumber() const    { return m_magicNumber; }
  };

//+------------------------------------------------------------------+
//| Construtor                                                       |
//+------------------------------------------------------------------+
CBlockerFilters::CBlockerFilters()
  {
   m_logger    = NULL;
   m_magicNumber = 0;

// Horário - inputs
   m_inputEnableTimeFilter   = false;
   m_inputStartHour          = 9;
   m_inputStartMinute        = 0;
   m_inputEndHour            = 17;
   m_inputEndMinute          = 0;
   m_inputCloseOnEndTime     = false;
   m_closeBeforeSessionEnd   = false;
   m_minutesBeforeSessionEnd = 5;

// Horário - working
   m_enableTimeFilter = false;
   m_startHour        = 9;
   m_startMinute      = 0;
   m_endHour          = 17;
   m_endMinute        = 0;
   m_closeOnEndTime   = false;

// News - inputs
   m_inputEnableNewsFilter1   = false;
   m_inputNewsStart1Hour      = 10; m_inputNewsStart1Minute = 0;
   m_inputNewsEnd1Hour        = 10; m_inputNewsEnd1Minute   = 15;
   m_inputEnableNewsFilter2   = false;
   m_inputNewsStart2Hour      = 14; m_inputNewsStart2Minute = 0;
   m_inputNewsEnd2Hour        = 14; m_inputNewsEnd2Minute   = 15;
   m_inputEnableNewsFilter3   = false;
   m_inputNewsStart3Hour      = 15; m_inputNewsStart3Minute = 0;
   m_inputNewsEnd3Hour        = 15; m_inputNewsEnd3Minute   = 5;

// News - working
   m_enableNewsFilter1  = false;
   m_newsStart1Hour     = 10; m_newsStart1Minute = 0;
   m_newsEnd1Hour       = 10; m_newsEnd1Minute   = 15;
   m_enableNewsFilter2  = false;
   m_newsStart2Hour     = 14; m_newsStart2Minute = 0;
   m_newsEnd2Hour       = 14; m_newsEnd2Minute   = 15;
   m_enableNewsFilter3  = false;
   m_newsStart3Hour     = 15; m_newsStart3Minute = 0;
   m_newsEnd3Hour       = 15; m_newsEnd3Minute   = 5;

// Spread
   m_inputMaxSpread = 0;
   m_maxSpread      = 0;

// Transition state
   m_sCrypto24x7Logged            = false;
   m_sLastSessionState            = SESSION_ACTIVE;
   m_sTfWasBlocked                = false;
   m_sNfWasBlocked                = false;
   m_sSfWasBlocked                = false;
   m_sCloseOnEndLastTicket        = 0;
   m_sCloseBeforeSessionLastTicket = 0;
  }

//+------------------------------------------------------------------+
//| Destrutor                                                        |
//+------------------------------------------------------------------+
CBlockerFilters::~CBlockerFilters()
  {
  }

//+------------------------------------------------------------------+
//| Inicialização                                                    |
//+------------------------------------------------------------------+
bool CBlockerFilters::Init(
   CLogger* logger,
   int magicNumber,
   bool enableTime, int startH, int startM, int endH, int endM,
   bool closeOnEnd, bool closeBeforeSessionEnd, int minutesBeforeSessionEnd,
   bool news1, int n1StartH, int n1StartM, int n1EndH, int n1EndM,
   bool news2, int n2StartH, int n2StartM, int n2EndH, int n2EndM,
   bool news3, int n3StartH, int n3StartM, int n3EndH, int n3EndM,
   int maxSpread
)
  {
   m_logger      = logger;
   m_magicNumber = magicNumber;

// ── HORÁRIO ──────────────────────────────────────────────────────
   m_inputEnableTimeFilter   = enableTime;
   m_inputCloseOnEndTime     = closeOnEnd;
   m_enableTimeFilter        = enableTime;
   m_closeOnEndTime          = closeOnEnd;
   m_closeBeforeSessionEnd   = closeBeforeSessionEnd;
   m_minutesBeforeSessionEnd = minutesBeforeSessionEnd;

   if(enableTime)
     {
      if(startH < 0 || startH > 23 || endH < 0 || endH > 23 ||
         startM < 0 || startM > 59 || endM < 0 || endM > 59)
        {
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Horários inválidos!");
         return false;
        }

      m_inputStartHour = startH; m_inputStartMinute = startM;
      m_inputEndHour   = endH;   m_inputEndMinute   = endM;
      m_startHour      = startH; m_startMinute      = startM;
      m_endHour        = endH;   m_endMinute        = endM;

      string timeMsg = "⏰ Filtro de Horário: " +
                       StringFormat("%02d:%02d - %02d:%02d", startH, startM, endH, endM);
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", timeMsg);

      if(closeOnEnd)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "   └─ Fecha posição ao fim do horário");
        }
     }
   else
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "⏰ Filtro de Horário: DESATIVADO");
     }

// ── NEWS FILTERS ─────────────────────────────────────────────────
   m_inputEnableNewsFilter1 = news1;
   m_inputNewsStart1Hour = n1StartH; m_inputNewsStart1Minute = n1StartM;
   m_inputNewsEnd1Hour   = n1EndH;   m_inputNewsEnd1Minute   = n1EndM;
   m_enableNewsFilter1  = news1;
   m_newsStart1Hour     = n1StartH; m_newsStart1Minute = n1StartM;
   m_newsEnd1Hour       = n1EndH;   m_newsEnd1Minute   = n1EndM;

   m_inputEnableNewsFilter2 = news2;
   m_inputNewsStart2Hour = n2StartH; m_inputNewsStart2Minute = n2StartM;
   m_inputNewsEnd2Hour   = n2EndH;   m_inputNewsEnd2Minute   = n2EndM;
   m_enableNewsFilter2  = news2;
   m_newsStart2Hour     = n2StartH; m_newsStart2Minute = n2StartM;
   m_newsEnd2Hour       = n2EndH;   m_newsEnd2Minute   = n2EndM;

   m_inputEnableNewsFilter3 = news3;
   m_inputNewsStart3Hour = n3StartH; m_inputNewsStart3Minute = n3StartM;
   m_inputNewsEnd3Hour   = n3EndH;   m_inputNewsEnd3Minute   = n3EndM;
   m_enableNewsFilter3  = news3;
   m_newsStart3Hour     = n3StartH; m_newsStart3Minute = n3StartM;
   m_newsEnd3Hour       = n3EndH;   m_newsEnd3Minute   = n3EndM;

   if(news1 || news2 || news3)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📰 Horários de Volatilidade:");

      if(news1)
        {
         string msg = "   • Bloqueio 1: " + StringFormat("%02d:%02d - %02d:%02d", n1StartH, n1StartM, n1EndH, n1EndM);
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
        }
      if(news2)
        {
         string msg = "   • Bloqueio 2: " + StringFormat("%02d:%02d - %02d:%02d", n2StartH, n2StartM, n2EndH, n2EndM);
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
        }
      if(news3)
        {
         string msg = "   • Bloqueio 3: " + StringFormat("%02d:%02d - %02d:%02d", n3StartH, n3StartM, n3EndH, n3EndM);
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
        }
     }
   else
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📰 Horários de Volatilidade: DESATIVADOS");
     }

// ── SPREAD ───────────────────────────────────────────────────────
   m_inputMaxSpread = maxSpread;
   m_maxSpread      = maxSpread;

   if(maxSpread > 0)
     {
      string msg = "📊 Spread Máximo: " + IntegerToString(maxSpread) + " pontos";
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
     }
   else
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📊 Spread Máximo: ILIMITADO");
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Verifica proteção de sessão (closeBeforeSessionEnd)              |
//+------------------------------------------------------------------+
bool CBlockerFilters::CheckSessionBlocking(ENUM_BLOCKER_REASON &blocker, string &blockReason)
  {
   if(!m_closeBeforeSessionEnd)
      return true;

   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);

   datetime sessionStart, sessionEnd;
   if(!SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)now.day_of_week, 0, sessionStart, sessionEnd))
      return true;

   MqlDateTime sessionStartTime, sessionEndTime;
   TimeToStruct(sessionStart, sessionStartTime);
   TimeToStruct(sessionEnd,   sessionEndTime);

   int currentMinutes  = now.hour             * 60 + now.min;
   int sessionStartMin = sessionStartTime.hour * 60 + sessionStartTime.min;
   int sessionEndMin   = sessionEndTime.hour   * 60 + sessionEndTime.min;

// Mercado 24/7 — ignorar proteção
   if(sessionStartMin == 0 && sessionEndMin == 0)
     {
      if(!m_sCrypto24x7Logged)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION",
            "🌐 Mercado 24/7 detectado - proteção de sessão DESATIVADA para este símbolo");
         m_sCrypto24x7Logged = true;
        }
      return true;
     }

   int deltaStart = currentMinutes - sessionStartMin;
   int deltaEnd   = sessionEndMin  - currentMinutes;

   ENUM_SESSION_STATE currentState;
   if(deltaStart < 0)
      currentState = SESSION_BEFORE;
   else if(deltaEnd < 0)
      currentState = SESSION_AFTER;
   else if(deltaEnd <= m_minutesBeforeSessionEnd)
      currentState = SESSION_PROTECTION;
   else
      currentState = SESSION_ACTIVE;

// Log apenas em transição de estado
   if(currentState != m_sLastSessionState)
     {
      m_sLastSessionState = currentState;
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
            break;
        }
     }

   if(currentState != SESSION_ACTIVE)
     {
      blocker = BLOCKER_TIME_FILTER;
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

   return true;
  }

//+------------------------------------------------------------------+
//| Verifica filtro de horário com logging de transição              |
//+------------------------------------------------------------------+
bool CBlockerFilters::CheckTimeWithLog(ENUM_BLOCKER_REASON &blocker, string &blockReason)
  {
   bool blocked = !CheckTimeFilter();
   if(blocked)
     {
      blocker     = BLOCKER_TIME_FILTER;
      blockReason = "Fora do horário permitido";
      if(!m_sTfWasBlocked)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
            StringFormat("🕐 FILTRO HORÁRIO: operações bloqueadas | janela %02d:%02d-%02d:%02d",
                         m_startHour, m_startMinute, m_endHour, m_endMinute));
      m_sTfWasBlocked = true;
      return false;
     }
   else if(m_sTfWasBlocked)
     {
      m_sTfWasBlocked = false;
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
         StringFormat("✅ FILTRO HORÁRIO: janela %02d:%02d-%02d:%02d ativa, operações liberadas",
                      m_startHour, m_startMinute, m_endHour, m_endMinute));
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Verifica filtro de notícias com logging de transição             |
//+------------------------------------------------------------------+
bool CBlockerFilters::CheckNewsWithLog(ENUM_BLOCKER_REASON &blocker, string &blockReason)
  {
   bool blocked = !CheckNewsFilter();
   if(blocked)
     {
      blocker     = BLOCKER_NEWS_FILTER;
      blockReason = "Horário de volatilidade";
      if(!m_sNfWasBlocked)
        {
         MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
         int cur = dt.hour * 60 + dt.min;
         string wDesc = "janela ativa";
         int s1 = m_newsStart1Hour*60+m_newsStart1Minute, e1 = m_newsEnd1Hour*60+m_newsEnd1Minute;
         int s2 = m_newsStart2Hour*60+m_newsStart2Minute, e2 = m_newsEnd2Hour*60+m_newsEnd2Minute;
         int s3 = m_newsStart3Hour*60+m_newsStart3Minute, e3 = m_newsEnd3Hour*60+m_newsEnd3Minute;
         if(m_enableNewsFilter1 && s1<e1 && cur>=s1 && cur<e1)
            wDesc = StringFormat("Janela 1 %02d:%02d-%02d:%02d", m_newsStart1Hour, m_newsStart1Minute, m_newsEnd1Hour, m_newsEnd1Minute);
         else if(m_enableNewsFilter2 && s2<e2 && cur>=s2 && cur<e2)
            wDesc = StringFormat("Janela 2 %02d:%02d-%02d:%02d", m_newsStart2Hour, m_newsStart2Minute, m_newsEnd2Hour, m_newsEnd2Minute);
         else if(m_enableNewsFilter3 && s3<e3 && cur>=s3 && cur<e3)
            wDesc = StringFormat("Janela 3 %02d:%02d-%02d:%02d", m_newsStart3Hour, m_newsStart3Minute, m_newsEnd3Hour, m_newsEnd3Minute);
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
            StringFormat("📰 FILTRO NOTICIAS: operações bloqueadas | %s", wDesc));
        }
      m_sNfWasBlocked = true;
      return false;
     }
   else if(m_sNfWasBlocked)
     {
      m_sNfWasBlocked = false;
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
         "✅ FILTRO NOTICIAS: janela encerrada, operações liberadas");
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Verifica filtro de spread com logging de transição               |
//+------------------------------------------------------------------+
bool CBlockerFilters::CheckSpreadWithLog(ENUM_BLOCKER_REASON &blocker, string &blockReason)
  {
   bool blocked = !CheckSpreadFilter();
   if(blocked)
     {
      blocker = BLOCKER_SPREAD;
      long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      blockReason = StringFormat("Spread alto (%d > %d)", spread, m_maxSpread);
      if(!m_sSfWasBlocked)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
            StringFormat("⛔ SPREAD ALTO: %d pts (máx: %d pts) — operações bloqueadas", spread, m_maxSpread));
      m_sSfWasBlocked = true;
      return false;
     }
   else if(m_sSfWasBlocked)
     {
      m_sSfWasBlocked = false;
      long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
         StringFormat("✅ SPREAD NORMALIZADO: %d pts — operações liberadas", spread));
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição por término de horário           |
//+------------------------------------------------------------------+
bool CBlockerFilters::ShouldCloseOnEndTime(ulong positionTicket)
  {
   if(!m_enableTimeFilter || !m_closeOnEndTime)
      return false;

   if(!PositionSelectByTicket(positionTicket))
      return false;

   long posMagic = PositionGetInteger(POSITION_MAGIC);
   if(posMagic != m_magicNumber)
     {
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
   if(startMinutes <= endMinutes)
     { if(currentMinutes >= endMinutes) shouldClose = true; }
   else
     { if(currentMinutes >= endMinutes && currentMinutes < startMinutes) shouldClose = true; }

   if(shouldClose)
     {
      if(m_sCloseOnEndLastTicket != positionTicket)
        {
         m_sCloseOnEndLastTicket = positionTicket;
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "TIME_CLOSE", "⏰ Término de horário de operação atingido");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "TIME_CLOSE",
            "   Horário: " + StringFormat("%02d:%02d - %02d:%02d",
               m_startHour, m_startMinute, m_endHour, m_endMinute));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "TIME_CLOSE",
            "   Posição #" + IntegerToString((int)positionTicket) + " deve ser fechada");
        }
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição antes do fim da sessão           |
//+------------------------------------------------------------------+
bool CBlockerFilters::ShouldCloseBeforeSessionEnd(ulong positionTicket)
  {
   if(!m_closeBeforeSessionEnd)
      return false;

   if(!PositionSelectByTicket(positionTicket))
      return false;

   long posMagic = PositionGetInteger(POSITION_MAGIC);
   if(posMagic != m_magicNumber)
     {
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

   int currentMinutes    = now.hour * 60 + now.min;
   int sessionEndMinutes = sessionEndTime.hour * 60 + sessionEndTime.min;

   if(sessionEndMinutes < currentMinutes)
      sessionEndMinutes += 24 * 60;

   int minutesUntilSessionEnd = sessionEndMinutes - currentMinutes;

   if(minutesUntilSessionEnd <= m_minutesBeforeSessionEnd && minutesUntilSessionEnd >= 0)
     {
      if(m_sCloseBeforeSessionLastTicket != positionTicket)
        {
         m_sCloseBeforeSessionLastTicket = positionTicket;
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
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar filtro de horário                           |
//+------------------------------------------------------------------+
void CBlockerFilters::SetTimeFilter(bool enable, int startH, int startM, int endH, int endM)
  {
   bool changed = (m_enableTimeFilter != enable ||
                   m_startHour != startH || m_startMinute != startM ||
                   m_endHour != endH || m_endMinute != endM);
   m_enableTimeFilter = enable;
   m_startHour        = startH;
   m_startMinute      = startM;
   m_endHour          = endH;
   m_endMinute        = endM;
   if(!changed) return;
   string info = enable
      ? StringFormat("ON %02d:%02d -> %02d:%02d", startH, startM, endH, endM)
      : "OFF";
   m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "TimeFilter: " + info);
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar fechar ao fim do horário                    |
//+------------------------------------------------------------------+
void CBlockerFilters::SetCloseOnEndTime(bool close)
  {
   if(m_closeOnEndTime == close) return;
   m_closeOnEndTime = close;
   m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
      "CloseOnEndTime: " + (close ? "ON" : "OFF"));
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar fechar antes do fim da sessão               |
//+------------------------------------------------------------------+
void CBlockerFilters::SetCloseBeforeSessionEnd(bool close, int minutes)
  {
   bool changed = (m_closeBeforeSessionEnd != close || m_minutesBeforeSessionEnd != minutes);
   m_closeBeforeSessionEnd   = close;
   m_minutesBeforeSessionEnd = minutes;
   if(!changed) return;
   m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
      StringFormat("CloseBeforeSessionEnd: %s | %d min", close ? "ON" : "OFF", minutes));
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar filtro de notícias                          |
//+------------------------------------------------------------------+
void CBlockerFilters::SetNewsFilter(int window, bool enable,
                                    int startH, int startM, int endH, int endM)
  {
   if(window < 1 || window > 3) return;

   bool changed = false;
   if(window == 1)
     {
      changed = (m_enableNewsFilter1 != enable ||
                 m_newsStart1Hour != startH || m_newsStart1Minute != startM ||
                 m_newsEnd1Hour != endH || m_newsEnd1Minute != endM);
      m_enableNewsFilter1 = enable;
      m_newsStart1Hour    = startH; m_newsStart1Minute = startM;
      m_newsEnd1Hour      = endH;   m_newsEnd1Minute   = endM;
     }
   else if(window == 2)
     {
      changed = (m_enableNewsFilter2 != enable ||
                 m_newsStart2Hour != startH || m_newsStart2Minute != startM ||
                 m_newsEnd2Hour != endH || m_newsEnd2Minute != endM);
      m_enableNewsFilter2 = enable;
      m_newsStart2Hour    = startH; m_newsStart2Minute = startM;
      m_newsEnd2Hour      = endH;   m_newsEnd2Minute   = endM;
     }
   else
     {
      changed = (m_enableNewsFilter3 != enable ||
                 m_newsStart3Hour != startH || m_newsStart3Minute != startM ||
                 m_newsEnd3Hour != endH || m_newsEnd3Minute != endM);
      m_enableNewsFilter3 = enable;
      m_newsStart3Hour    = startH; m_newsStart3Minute = startM;
      m_newsEnd3Hour      = endH;   m_newsEnd3Minute   = endM;
     }

   if(!changed) return;
   string info = enable
      ? StringFormat("ON %02d:%02d -> %02d:%02d", startH, startM, endH, endM)
      : "OFF";
   m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
                StringFormat("NewsFilter%d: %s", window, info));
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar spread máximo                               |
//+------------------------------------------------------------------+
void CBlockerFilters::SetMaxSpread(int newMaxSpread)
  {
   int oldValue  = m_maxSpread;
   m_maxSpread   = newMaxSpread;
   if(oldValue != newMaxSpread)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         StringFormat("Spread máximo alterado: %d → %d pontos", oldValue, newMaxSpread));
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload — Magic Number                                        |
//+------------------------------------------------------------------+
void CBlockerFilters::SetMagicNumber(int newMagic)
  {
   m_magicNumber = newMagic;

   // Limpar caches de transição (tickets do magic antigo são inválidos)
   m_sCloseOnEndLastTicket         = 0;
   m_sCloseBeforeSessionLastTicket = 0;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica filtro de horário                              |
//+------------------------------------------------------------------+
bool CBlockerFilters::CheckTimeFilter()
  {
   if(!m_enableTimeFilter) return true;

   datetime now = TimeCurrent();
   MqlDateTime timeStruct;
   TimeToStruct(now, timeStruct);

   int currentMinutes = timeStruct.hour * 60 + timeStruct.min;
   int startMinutes   = m_startHour * 60 + m_startMinute;
   int endMinutes     = m_endHour   * 60 + m_endMinute;

   if(startMinutes < endMinutes)
      return (currentMinutes >= startMinutes && currentMinutes < endMinutes);

   return (currentMinutes >= startMinutes || currentMinutes < endMinutes);
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica news filters                                   |
//+------------------------------------------------------------------+
bool CBlockerFilters::CheckNewsFilter()
  {
   if(!m_enableNewsFilter1 && !m_enableNewsFilter2 && !m_enableNewsFilter3)
      return true;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int currentMinutes = dt.hour * 60 + dt.min;

   if(m_enableNewsFilter1)
     {
      int newsStart1 = m_newsStart1Hour * 60 + m_newsStart1Minute;
      int newsEnd1   = m_newsEnd1Hour   * 60 + m_newsEnd1Minute;
      if(newsStart1 < newsEnd1 && currentMinutes >= newsStart1 && currentMinutes < newsEnd1)
         return false;
     }

   if(m_enableNewsFilter2)
     {
      int newsStart2 = m_newsStart2Hour * 60 + m_newsStart2Minute;
      int newsEnd2   = m_newsEnd2Hour   * 60 + m_newsEnd2Minute;
      if(newsStart2 < newsEnd2 && currentMinutes >= newsStart2 && currentMinutes < newsEnd2)
         return false;
     }

   if(m_enableNewsFilter3)
     {
      int newsStart3 = m_newsStart3Hour * 60 + m_newsStart3Minute;
      int newsEnd3   = m_newsEnd3Hour   * 60 + m_newsEnd3Minute;
      if(newsStart3 < newsEnd3 && currentMinutes >= newsStart3 && currentMinutes < newsEnd3)
         return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica filtro de spread                               |
//+------------------------------------------------------------------+
bool CBlockerFilters::CheckSpreadFilter()
  {
   if(m_maxSpread <= 0) return true;
   long spreadPoints = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   return (spreadPoints <= m_maxSpread);
  }

#endif // BLOCKER_FILTERS_MQH
//+------------------------------------------------------------------+
