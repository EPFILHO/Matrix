//+------------------------------------------------------------------+
//|                                           BlockerFilters.mqh     |
//|                                        Copyright 2026, EP Filho  |
//|           Filtros de Condição de Mercado - EPBot Matrix          |
//|                       Versão 1.02 - Claude Parte 032             |
//+------------------------------------------------------------------+
// NOTA: Enums (ENUM_BLOCKER_REASON, ENUM_SESSION_STATE, etc.) e
// Logger.mqh são incluídos por Blockers.mqh ANTES deste arquivo.

// ═══════════════════════════════════════════════════════════════
// CHANGELOG v1.02 (Parte 032):
// + FIX: CheckNewsFilter() — janelas de notícia que cruzam meia-noite
//   (ex: 23:45 → 00:15) nunca bloqueavam porque a condição
//   newsStart < newsEnd falhava antes do check. Lógica replicada
//   de CheckTimeFilter(): se newsStart > newsEnd, trata crossover.
//
// + FIX: ShouldCloseBeforeSessionEnd() — quando sessão já encerrou
//   (currentMinutes > sessionEndMinutes), o código somava 24h e
//   minutesUntilSessionEnd ficava ~1410 — posição nunca fechava.
//   Corrigido: se sessionEnd < currentMinutes, minutesUntilSessionEnd = 0.
//
// + FIX: CheckSessionBlocking() — session_index=0 retorna apenas a
//   primeira sessão do dia. Para instrumentos com duas sessões,
//   agora itera todas as sessões disponíveis e usa aquela que
//   contém o horário atual (ou a mais próxima de encerrar).
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v1.01 (Parte 027):
// + SetMagicNumber() / GetMagicNumber() — hot reload do Magic Number
// ═══════════════════════════════════════════════════════════════

#ifndef BLOCKER_FILTERS_MQH
#define BLOCKER_FILTERS_MQH

//+------------------------------------------------------------------+
//| Classe: CBlockerFilters                                          |
//| Filtros de condição de mercado: Horário + Notícias + Spread     |
//+------------------------------------------------------------------+
class CBlockerFilters
  {
private:
   CLogger*                  m_logger;
   int                       m_magicNumber;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - HORÁRIO
   // ═══════════════════════════════════════════════════════════════
   bool                      m_inputEnableTimeFilter;
   int                       m_inputStartHour;
   int                       m_inputStartMinute;
   int                       m_inputEndHour;
   int                       m_inputEndMinute;
   bool                      m_inputCloseOnEndTime;
   bool                      m_closeBeforeSessionEnd;
   int                       m_minutesBeforeSessionEnd;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - HORÁRIO
   // ═══════════════════════════════════════════════════════════════
   bool                      m_enableTimeFilter;
   int                       m_startHour;
   int                       m_startMinute;
   int                       m_endHour;
   int                       m_endMinute;
   bool                      m_closeOnEndTime;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - NEWS FILTERS
   // ═══════════════════════════════════════════════════════════════
   bool                      m_inputEnableNewsFilter1;
   int                       m_inputNewsStart1Hour;
   int                       m_inputNewsStart1Minute;
   int                       m_inputNewsEnd1Hour;
   int                       m_inputNewsEnd1Minute;
   bool                      m_inputEnableNewsFilter2;
   int                       m_inputNewsStart2Hour;
   int                       m_inputNewsStart2Minute;
   int                       m_inputNewsEnd2Hour;
   int                       m_inputNewsEnd2Minute;
   bool                      m_inputEnableNewsFilter3;
   int                       m_inputNewsStart3Hour;
   int                       m_inputNewsStart3Minute;
   int                       m_inputNewsEnd3Hour;
   int                       m_inputNewsEnd3Minute;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - NEWS FILTERS
   // ═══════════════════════════════════════════════════════════════
   bool                      m_enableNewsFilter1;
   int                       m_newsStart1Hour;
   int                       m_newsStart1Minute;
   int                       m_newsEnd1Hour;
   int                       m_newsEnd1Minute;
   bool                      m_enableNewsFilter2;
   int                       m_newsStart2Hour;
   int                       m_newsStart2Minute;
   int                       m_newsEnd2Hour;
   int                       m_newsEnd2Minute;
   bool                      m_enableNewsFilter3;
   int                       m_newsStart3Hour;
   int                       m_newsStart3Minute;
   int                       m_newsEnd3Hour;
   int                       m_newsEnd3Minute;

   // ═══════════════════════════════════════════════════════════════
   // INPUT / WORKING PARAMETERS - SPREAD
   // ═══════════════════════════════════════════════════════════════
   int                       m_inputMaxSpread;
   int                       m_maxSpread;

   // ═══════════════════════════════════════════════════════════════
   // ESTADO DE TRANSIÇÃO
   // ═══════════════════════════════════════════════════════════════
   bool                      m_sCrypto24x7Logged;
   ENUM_SESSION_STATE        m_sLastSessionState;
   bool                      m_sTfWasBlocked;
   bool                      m_sNfWasBlocked;
   bool                      m_sSfWasBlocked;
   ulong                     m_sCloseOnEndLastTicket;
   ulong                     m_sCloseBeforeSessionLastTicket;

   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS
   // ═══════════════════════════════════════════════════════════════
   bool              CheckTimeFilter();
   bool              CheckNewsFilter();
   bool              CheckSpreadFilter();
   bool              IsInNewsWindow(int cur, int startMin, int endMin);

   // FIX v1.02: helper para buscar sessão relevante do dia
   bool              GetRelevantSession(ENUM_DAY_OF_WEEK dow,
                                        int currentMinutes,
                                        MqlDateTime &outSessionEndTime,
                                        int &outDeltaEnd,
                                        int &outSessionStartMin,
                                        int &outSessionEndMin);

public:
                     CBlockerFilters();
                    ~CBlockerFilters();

   bool              Init(
      CLogger*       logger,
      int            magicNumber,
      bool           enableTime,
      int            startH, int startM, int endH, int endM, bool closeOnEnd,
      bool           closeBeforeSessionEnd, int minutesBeforeSessionEnd,
      bool           news1, int n1StartH, int n1StartM, int n1EndH, int n1EndM,
      bool           news2, int n2StartH, int n2StartM, int n2EndH, int n2EndM,
      bool           news3, int n3StartH, int n3StartM, int n3EndH, int n3EndM,
      int            maxSpread
   );

   // ═══════════════════════════════════════════════════════════════
   // VERIFICAÇÕES PARA CanTrade
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
   int               GetMaxSpread()      const { return m_maxSpread;   }
   int               GetInputMaxSpread() const { return m_inputMaxSpread; }
   int               GetMagicNumber()    const { return m_magicNumber; }
  };

//+------------------------------------------------------------------+
//| Construtor                                                       |
//+------------------------------------------------------------------+
CBlockerFilters::CBlockerFilters()
  {
   m_logger      = NULL;
   m_magicNumber = 0;

   m_inputEnableTimeFilter    = false;
   m_inputStartHour           = 9;
   m_inputStartMinute         = 0;
   m_inputEndHour             = 17;
   m_inputEndMinute           = 0;
   m_inputCloseOnEndTime      = false;
   m_closeBeforeSessionEnd    = false;
   m_minutesBeforeSessionEnd  = 5;

   m_enableTimeFilter = false;
   m_startHour        = 9;
   m_startMinute      = 0;
   m_endHour          = 17;
   m_endMinute        = 0;
   m_closeOnEndTime   = false;

   m_inputEnableNewsFilter1   = false;
   m_inputNewsStart1Hour      = 10; m_inputNewsStart1Minute = 0;
   m_inputNewsEnd1Hour        = 10; m_inputNewsEnd1Minute   = 15;
   m_inputEnableNewsFilter2   = false;
   m_inputNewsStart2Hour      = 14; m_inputNewsStart2Minute = 0;
   m_inputNewsEnd2Hour        = 14; m_inputNewsEnd2Minute   = 15;
   m_inputEnableNewsFilter3   = false;
   m_inputNewsStart3Hour      = 15; m_inputNewsStart3Minute = 0;
   m_inputNewsEnd3Hour        = 15; m_inputNewsEnd3Minute   = 5;

   m_enableNewsFilter1  = false;
   m_newsStart1Hour     = 10; m_newsStart1Minute = 0;
   m_newsEnd1Hour       = 10; m_newsEnd1Minute   = 15;
   m_enableNewsFilter2  = false;
   m_newsStart2Hour     = 14; m_newsStart2Minute = 0;
   m_newsEnd2Hour       = 14; m_newsEnd2Minute   = 15;
   m_enableNewsFilter3  = false;
   m_newsStart3Hour     = 15; m_newsStart3Minute = 0;
   m_newsEnd3Hour       = 15; m_newsEnd3Minute   = 5;

   m_inputMaxSpread = 0;
   m_maxSpread      = 0;

   m_sCrypto24x7Logged             = false;
   m_sLastSessionState             = SESSION_ACTIVE;
   m_sTfWasBlocked                 = false;
   m_sNfWasBlocked                 = false;
   m_sSfWasBlocked                 = false;
   m_sCloseOnEndLastTicket         = 0;
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
   CLogger*       logger,
   int            magicNumber,
   bool           enableTime,
   int            startH, int startM, int endH, int endM, bool closeOnEnd,
   bool           closeBeforeSessionEnd, int minutesBeforeSessionEnd,
   bool           news1, int n1StartH, int n1StartM, int n1EndH, int n1EndM,
   bool           news2, int n2StartH, int n2StartM, int n2EndH, int n2EndM,
   bool           news3, int n3StartH, int n3StartM, int n3EndH, int n3EndM,
   int            maxSpread
)
  {
   m_logger      = logger;
   m_magicNumber = magicNumber;

   // ── HORÁRIO ───────────────────────────────────────────────────
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
         if(m_logger != NULL)
            m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Horários inválidos!");
         else
            Print("❌ Horários inválidos!");
         return false;
        }

      m_inputStartHour = startH; m_inputStartMinute = startM;
      m_inputEndHour   = endH;   m_inputEndMinute   = endM;
      m_startHour      = startH; m_startMinute      = startM;
      m_endHour        = endH;   m_endMinute        = endM;

      string timeMsg = "⏰ Filtro de Horário: " +
                       StringFormat("%02d:%02d - %02d:%02d", startH, startM, endH, endM);
      if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", timeMsg);
      else Print(timeMsg);

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

   // ── NEWS FILTERS ──────────────────────────────────────────────
   m_inputEnableNewsFilter1 = news1;
   m_inputNewsStart1Hour = n1StartH; m_inputNewsStart1Minute = n1StartM;
   m_inputNewsEnd1Hour   = n1EndH;   m_inputNewsEnd1Minute   = n1EndM;
   m_enableNewsFilter1   = news1;
   m_newsStart1Hour      = n1StartH; m_newsStart1Minute      = n1StartM;
   m_newsEnd1Hour        = n1EndH;   m_newsEnd1Minute        = n1EndM;

   m_inputEnableNewsFilter2 = news2;
   m_inputNewsStart2Hour = n2StartH; m_inputNewsStart2Minute = n2StartM;
   m_inputNewsEnd2Hour   = n2EndH;   m_inputNewsEnd2Minute   = n2EndM;
   m_enableNewsFilter2   = news2;
   m_newsStart2Hour      = n2StartH; m_newsStart2Minute      = n2StartM;
   m_newsEnd2Hour        = n2EndH;   m_newsEnd2Minute        = n2EndM;

   m_inputEnableNewsFilter3 = news3;
   m_inputNewsStart3Hour = n3StartH; m_inputNewsStart3Minute = n3StartM;
   m_inputNewsEnd3Hour   = n3EndH;   m_inputNewsEnd3Minute   = n3EndM;
   m_enableNewsFilter3   = news3;
   m_newsStart3Hour      = n3StartH; m_newsStart3Minute      = n3StartM;
   m_newsEnd3Hour        = n3EndH;   m_newsEnd3Minute        = n3EndM;

   if(news1 || news2 || news3)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📰 Horários de Volatilidade:");
      else
         Print("📰 Horários de Volatilidade:");
      if(news1)
        {
         string msg = "   • Bloqueio 1: " +
                      StringFormat("%02d:%02d - %02d:%02d", n1StartH, n1StartM, n1EndH, n1EndM);
         if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
         else Print(msg);
        }
      if(news2)
        {
         string msg = "   • Bloqueio 2: " +
                      StringFormat("%02d:%02d - %02d:%02d", n2StartH, n2StartM, n2EndH, n2EndM);
         if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
         else Print(msg);
        }
      if(news3)
        {
         string msg = "   • Bloqueio 3: " +
                      StringFormat("%02d:%02d - %02d:%02d", n3StartH, n3StartM, n3EndH, n3EndM);
         if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
         else Print(msg);
        }
     }
   else
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📰 Horários de Volatilidade: DESATIVADOS");
      else
         Print("📰 Horários de Volatilidade: DESATIVADOS");
     }

   // ── SPREAD ────────────────────────────────────────────────────
   m_inputMaxSpread = maxSpread;
   m_maxSpread      = maxSpread;

   if(maxSpread > 0)
     {
      string msg = "📊 Spread Máximo: " + IntegerToString(maxSpread) + " pontos";
      if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", msg);
      else Print(msg);
     }
   else
     {
      if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📊 Spread Máximo: ILIMITADO");
      else Print("📊 Spread Máximo: ILIMITADO");
     }

   return true;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Busca a sessão relevante para o horário atual           |
//| FIX v1.02: itera todas as sessões, não apenas índice 0           |
//+------------------------------------------------------------------+
bool CBlockerFilters::GetRelevantSession(ENUM_DAY_OF_WEEK dow,
                                          int currentMinutes,
                                          MqlDateTime &outSessionEndTime,
                                          int &outDeltaEnd,
                                          int &outSessionStartMin,
                                          int &outSessionEndMin)
  {
   datetime sessionStart, sessionEnd;
   int bestDeltaEnd = INT_MAX;
   bool found       = false;

   for(int idx = 0; idx < 10; idx++)  // max 10 sessões por dia
     {
      if(!SymbolInfoSessionTrade(_Symbol, dow, idx, sessionStart, sessionEnd))
         break;

      MqlDateTime ssTime, seTime;
      TimeToStruct(sessionStart, ssTime);
      TimeToStruct(sessionEnd,   seTime);
      int ssMin = ssTime.hour * 60 + ssTime.min;
      int seMin = seTime.hour * 60 + seTime.min;

      // Mercado 24/7 — sinaliza ao chamador
      if(ssMin == 0 && seMin == 0)
        {
         outSessionStartMin = 0;
         outSessionEndMin   = 0;
         outDeltaEnd        = 0;
         return true;
        }

      int deltaEnd = seMin - currentMinutes;

      // Prefere a sessão que contém o horário atual
      if(currentMinutes >= ssMin && currentMinutes <= seMin)
        {
         TimeToStruct(sessionEnd, outSessionEndTime);
         outDeltaEnd        = deltaEnd;
         outSessionStartMin = ssMin;
         outSessionEndMin   = seMin;
         return true;
        }

      // Fallback: sessão mais próxima de encerrar no futuro
      if(deltaEnd > 0 && deltaEnd < bestDeltaEnd)
        {
         bestDeltaEnd = deltaEnd;
         TimeToStruct(sessionEnd, outSessionEndTime);
         outDeltaEnd        = deltaEnd;
         outSessionStartMin = ssMin;
         outSessionEndMin   = seMin;
         found = true;
        }
     }

   return found;
  }

//+------------------------------------------------------------------+
//| Verifica proteção de sessão (closeBeforeSessionEnd)              |
//| FIX v1.02: usa GetRelevantSession() para múltiplas sessões/dia   |
//+------------------------------------------------------------------+
bool CBlockerFilters::CheckSessionBlocking(ENUM_BLOCKER_REASON &blocker, string &blockReason)
  {
   if(!m_closeBeforeSessionEnd)
      return true;

   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   int currentMinutes = now.hour * 60 + now.min;

   MqlDateTime sessionEndTime;
   int deltaEnd       = 0;
   int sessionStartMin = 0;
   int sessionEndMin   = 0;

   if(!GetRelevantSession((ENUM_DAY_OF_WEEK)now.day_of_week,
                           currentMinutes, sessionEndTime, deltaEnd,
                           sessionStartMin, sessionEndMin))
      return true;

   // Mercado 24/7
   if(sessionStartMin == 0 && sessionEndMin == 0)
     {
      if(!m_sCrypto24x7Logged && m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION",
                      "🌐 Mercado 24/7 detectado - proteção de sessão DESATIVADA para este símbolo");
         m_sCrypto24x7Logged = true;
        }
      return true;
     }

   ENUM_SESSION_STATE currentState;
   if(currentMinutes < sessionStartMin)
      currentState = SESSION_BEFORE;
   else if(currentMinutes > sessionEndMin)
      currentState = SESSION_AFTER;
   else if(deltaEnd <= m_minutesBeforeSessionEnd)
      currentState = SESSION_PROTECTION;
   else
      currentState = SESSION_ACTIVE;

   if(currentState != m_sLastSessionState)
     {
      m_sLastSessionState = currentState;
      if(m_logger != NULL)
        {
         switch(currentState)
           {
            case SESSION_BEFORE:
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "═══════════════════════════════════════════════════════");
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "⏰ Sessão de negociação AINDA NÃO INICIOU");
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION",
                            StringFormat("   Sessão: %02d:%02d → %02d:%02d",
                                         sessionStartMin / 60, sessionStartMin % 60,
                                         sessionEndTime.hour, sessionEndTime.min));
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
                                         sessionStartMin / 60, sessionStartMin % 60,
                                         sessionEndTime.hour, sessionEndTime.min));
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "   Novas entradas bloqueadas até próxima sessão");
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION", "═══════════════════════════════════════════════════════");
               break;
            case SESSION_ACTIVE:
               break;
           }
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
         default:
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
      if(!m_sTfWasBlocked && m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
                      StringFormat("🕐 FILTRO HORÁRIO: operações bloqueadas | janela %02d:%02d-%02d:%02d",
                                   m_startHour, m_startMinute, m_endHour, m_endMinute));
      m_sTfWasBlocked = true;
      return false;
     }
   else if(m_sTfWasBlocked)
     {
      m_sTfWasBlocked = false;
      if(m_logger != NULL)
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
      if(!m_sNfWasBlocked && m_logger != NULL)
        {
         MqlDateTime dt;
         TimeToStruct(TimeCurrent(), dt);
         int cur     = dt.hour * 60 + dt.min;
         string wDesc = "janela ativa";

         int s1 = m_newsStart1Hour*60+m_newsStart1Minute, e1 = m_newsEnd1Hour*60+m_newsEnd1Minute;
         int s2 = m_newsStart2Hour*60+m_newsStart2Minute, e2 = m_newsEnd2Hour*60+m_newsEnd2Minute;
         int s3 = m_newsStart3Hour*60+m_newsStart3Minute, e3 = m_newsEnd3Hour*60+m_newsEnd3Minute;

         // Lógica de identificação espelha CheckNewsFilter() exatamente
         if(m_enableNewsFilter1 && IsInNewsWindow(cur, s1, e1))
            wDesc = StringFormat("Bloqueio 1: %02d:%02d-%02d:%02d",
                                 m_newsStart1Hour, m_newsStart1Minute, m_newsEnd1Hour, m_newsEnd1Minute);
         else if(m_enableNewsFilter2 && IsInNewsWindow(cur, s2, e2))
            wDesc = StringFormat("Bloqueio 2: %02d:%02d-%02d:%02d",
                                 m_newsStart2Hour, m_newsStart2Minute, m_newsEnd2Hour, m_newsEnd2Minute);
         else if(m_enableNewsFilter3 && IsInNewsWindow(cur, s3, e3))
            wDesc = StringFormat("Bloqueio 3: %02d:%02d-%02d:%02d",
                                 m_newsStart3Hour, m_newsStart3Minute, m_newsEnd3Hour, m_newsEnd3Minute);

         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
                      "📰 FILTRO NOTÍCIAS: operações bloqueadas | " + wDesc);
        }
      m_sNfWasBlocked = true;
      return false;
     }
   else if(m_sNfWasBlocked)
     {
      m_sNfWasBlocked = false;
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
                      "✅ FILTRO NOTÍCIAS: janela encerrada, operações liberadas");
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
      long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
      blocker     = BLOCKER_SPREAD;
      blockReason = StringFormat("Spread alto (%d > %d)", spread, m_maxSpread);
      if(!m_sSfWasBlocked && m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
                      StringFormat("⛔ SPREAD ALTO: %d pts (máx: %d pts) — operações bloqueadas",
                                   spread, m_maxSpread));
      m_sSfWasBlocked = true;
      return false;
     }
   else if(m_sSfWasBlocked)
     {
      m_sSfWasBlocked = false;
      if(m_logger != NULL)
        {
         long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "BLOCK",
                      StringFormat("✅ SPREAD NORMALIZADO: %d pts — operações liberadas", spread));
        }
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
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "TIME_CLOSE",
                      "Ignorando posição #" + IntegerToString((int)positionTicket) +
                      " (Magic " + IntegerToString((int)posMagic) +
                      " ≠ " + IntegerToString(m_magicNumber) + ")");
      return false;
     }

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int currentMinutes = dt.hour * 60 + dt.min;
   int startMinutes   = m_startHour * 60 + m_startMinute;
   int endMinutes     = m_endHour   * 60 + m_endMinute;

   bool shouldClose = false;
   if(startMinutes <= endMinutes)
      shouldClose = (currentMinutes >= endMinutes);
   else
      // crossover meia-noite: fora da janela = entre endMinutes e startMinutes
      shouldClose = (currentMinutes >= endMinutes && currentMinutes < startMinutes);

   if(shouldClose && m_sCloseOnEndLastTicket != positionTicket)
     {
      m_sCloseOnEndLastTicket = positionTicket;
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "TIME_CLOSE",
                      "⏰ Término de horário de operação atingido");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "TIME_CLOSE",
                      "   Horário: " +
                      StringFormat("%02d:%02d - %02d:%02d", m_startHour, m_startMinute, m_endHour, m_endMinute));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "TIME_CLOSE",
                      "   Posição #" + IntegerToString((int)positionTicket) + " deve ser fechada");
        }
     }
   return shouldClose;
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição antes do fim da sessão           |
//| FIX v1.02: sessão já encerrada → minutesUntilSessionEnd = 0     |
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
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "SESSION_CLOSE",
                      "Ignorando posição #" + IntegerToString((int)positionTicket) +
                      " (Magic " + IntegerToString((int)posMagic) +
                      " ≠ " + IntegerToString(m_magicNumber) + ")");
      return false;
     }

   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   int currentMinutes = now.hour * 60 + now.min;

   MqlDateTime sessionEndTime;
   int deltaEnd        = 0;
   int sessionStartMin = 0;
   int sessionEndMin   = 0;

   if(!GetRelevantSession((ENUM_DAY_OF_WEEK)now.day_of_week,
                           currentMinutes, sessionEndTime, deltaEnd,
                           sessionStartMin, sessionEndMin))
      return false;

   // Mercado 24/7 — nunca fecha por sessão
   if(sessionStartMin == 0 && sessionEndMin == 0)
      return false;

   // FIX v1.02: sessão já encerrou → minutesUntilSessionEnd = 0 (deve fechar)
   int minutesUntilSessionEnd;
   if(sessionEndMin < currentMinutes)
      minutesUntilSessionEnd = 0;
   else
      minutesUntilSessionEnd = sessionEndMin - currentMinutes;

   if(minutesUntilSessionEnd <= m_minutesBeforeSessionEnd)
     {
      if(m_sCloseBeforeSessionLastTicket != positionTicket)
        {
         m_sCloseBeforeSessionLastTicket = positionTicket;
         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION_CLOSE",
                         "════════════════════════════════════════════════════════════════");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION_CLOSE",
                         "⏰ Proteção de Sessão - fechando posição existente");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION_CLOSE",
                         StringFormat("   Sessão encerra: %02d:%02d",
                                      sessionEndTime.hour, sessionEndTime.min));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION_CLOSE",
                         StringFormat("   Margem: %d min | Faltam: %d min",
                                      m_minutesBeforeSessionEnd, minutesUntilSessionEnd));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION_CLOSE",
                         "   Posição #" + IntegerToString((int)positionTicket) + " deve ser fechada");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "SESSION_CLOSE",
                         "════════════════════════════════════════════════════════════════");
           }
        }
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Hot Reload - Filtro de horário                                   |
//+------------------------------------------------------------------+
void CBlockerFilters::SetTimeFilter(bool enable, int startH, int startM, int endH, int endM)
  {
   bool changed = (m_enableTimeFilter != enable ||
                   m_startHour != startH || m_startMinute != startM ||
                   m_endHour   != endH   || m_endMinute   != endM);
   m_enableTimeFilter = enable;
   m_startHour = startH; m_startMinute = startM;
   m_endHour   = endH;   m_endMinute   = endM;
   if(!changed) return;
   string info = enable ? StringFormat("ON %02d:%02d -> %02d:%02d", startH, startM, endH, endM) : "OFF";
   if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "TimeFilter: " + info);
  }

//+------------------------------------------------------------------+
//| Hot Reload - Fechar ao fim do horário                            |
//+------------------------------------------------------------------+
void CBlockerFilters::SetCloseOnEndTime(bool close)
  {
   if(m_closeOnEndTime == close) return;
   m_closeOnEndTime = close;
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "CloseOnEndTime: " + (close ? "ON" : "OFF"));
   else
      Print("🔄 CloseOnEndTime: ", close ? "ON" : "OFF");
  }

//+------------------------------------------------------------------+
//| Hot Reload - Fechar antes do fim da sessão                       |
//+------------------------------------------------------------------+
void CBlockerFilters::SetCloseBeforeSessionEnd(bool close, int minutes)
  {
   bool changed = (m_closeBeforeSessionEnd != close || m_minutesBeforeSessionEnd != minutes);
   m_closeBeforeSessionEnd   = close;
   m_minutesBeforeSessionEnd = minutes;
   if(!changed) return;
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
                   StringFormat("CloseBeforeSessionEnd: %s | %d min", close ? "ON" : "OFF", minutes));
   else
      Print("🔄 CloseBeforeSessionEnd: ", close ? "ON" : "OFF", " | ", minutes, " min");
  }

//+------------------------------------------------------------------+
//| Hot Reload - News filter                                         |
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
                 m_newsEnd1Hour   != endH   || m_newsEnd1Minute   != endM);
      m_enableNewsFilter1 = enable;
      m_newsStart1Hour = startH; m_newsStart1Minute = startM;
      m_newsEnd1Hour   = endH;   m_newsEnd1Minute   = endM;
     }
   else if(window == 2)
     {
      changed = (m_enableNewsFilter2 != enable ||
                 m_newsStart2Hour != startH || m_newsStart2Minute != startM ||
                 m_newsEnd2Hour   != endH   || m_newsEnd2Minute   != endM);
      m_enableNewsFilter2 = enable;
      m_newsStart2Hour = startH; m_newsStart2Minute = startM;
      m_newsEnd2Hour   = endH;   m_newsEnd2Minute   = endM;
     }
   else
     {
      changed = (m_enableNewsFilter3 != enable ||
                 m_newsStart3Hour != startH || m_newsStart3Minute != startM ||
                 m_newsEnd3Hour   != endH   || m_newsEnd3Minute   != endM);
      m_enableNewsFilter3 = enable;
      m_newsStart3Hour = startH; m_newsStart3Minute = startM;
      m_newsEnd3Hour   = endH;   m_newsEnd3Minute   = endM;
     }
   if(!changed) return;
   string info = enable ? StringFormat("ON %02d:%02d -> %02d:%02d", startH, startM, endH, endM) : "OFF";
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
                   StringFormat("NewsFilter%d: %s", window, info));
  }

//+------------------------------------------------------------------+
//| Hot Reload - Spread máximo                                       |
//+------------------------------------------------------------------+
void CBlockerFilters::SetMaxSpread(int newMaxSpread)
  {
   int oldValue = m_maxSpread;
   m_maxSpread  = newMaxSpread;
   if(oldValue == newMaxSpread) return;
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
                   StringFormat("Spread máximo alterado: %d → %d pontos", oldValue, newMaxSpread));
   else
      Print("🔄 Spread máximo: ", oldValue, " → ", newMaxSpread, " pontos");
  }

//+------------------------------------------------------------------+
//| Hot Reload - Magic Number                                        |
//+------------------------------------------------------------------+
void CBlockerFilters::SetMagicNumber(int newMagic)
  {
   m_magicNumber                   = newMagic;
   m_sCloseOnEndLastTicket         = 0;
   m_sCloseBeforeSessionLastTicket = 0;
  }

//+------------------------------------------------------------------+
//| PRIVADO: helper — verifica se currentMinutes está na janela      |
//| Suporta crossover de meia-noite (start > end)                    |
//+------------------------------------------------------------------+
bool CBlockerFilters::IsInNewsWindow(int cur, int startMin, int endMin)
  {
   if(startMin < endMin)
      return (cur >= startMin && cur < endMin);
   else if(startMin > endMin)
      // crossover: ex 23:45 → 00:15
      return (cur >= startMin || cur < endMin);
   return false;  // start == end: janela zero, nunca bloqueia
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica filtro de horário                              |
//+------------------------------------------------------------------+
bool CBlockerFilters::CheckTimeFilter()
  {
   if(!m_enableTimeFilter) return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int cur   = dt.hour * 60 + dt.min;
   int start = m_startHour * 60 + m_startMinute;
   int end   = m_endHour   * 60 + m_endMinute;
   if(start < end)
      return (cur >= start && cur < end);
   return (cur >= start || cur < end);  // crossover meia-noite
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica news filters                                   |
//| FIX v1.02: suporta crossover de meia-noite via IsInNewsWindow()  |
//+------------------------------------------------------------------+
bool CBlockerFilters::CheckNewsFilter()
  {
   if(!m_enableNewsFilter1 && !m_enableNewsFilter2 && !m_enableNewsFilter3)
      return true;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int cur = dt.hour * 60 + dt.min;

   if(m_enableNewsFilter1)
     {
      int s = m_newsStart1Hour*60+m_newsStart1Minute, e = m_newsEnd1Hour*60+m_newsEnd1Minute;
      if(IsInNewsWindow(cur, s, e)) return false;
     }
   if(m_enableNewsFilter2)
     {
      int s = m_newsStart2Hour*60+m_newsStart2Minute, e = m_newsEnd2Hour*60+m_newsEnd2Minute;
      if(IsInNewsWindow(cur, s, e)) return false;
     }
   if(m_enableNewsFilter3)
     {
      int s = m_newsStart3Hour*60+m_newsStart3Minute, e = m_newsEnd3Hour*60+m_newsEnd3Minute;
      if(IsInNewsWindow(cur, s, e)) return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| PRIVADO: Verifica filtro de spread                               |
//+------------------------------------------------------------------+
bool CBlockerFilters::CheckSpreadFilter()
  {
   if(m_maxSpread <= 0) return true;
   return (SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) <= m_maxSpread);
  }

#endif  // BLOCKER_FILTERS_MQH
//+------------------------------------------------------------------+
