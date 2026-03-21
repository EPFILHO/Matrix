//+------------------------------------------------------------------+
//|                                              PanelTabStatus.mqh  |
//|                                         Copyright 2026, EP Filho |
//|          Panel Tab: STATUS — Create + Update                      |
//|                     Versão 1.12 - Claude Parte 024 (Claude Code) |
//+------------------------------------------------------------------+
// Implementações de CEPBotPanel para a aba STATUS.
// Incluído por Panel.mqh — NÃO incluir diretamente.
//
// v1.12 (Parte 024):
// + SIGNAL MANAGER movido de ESTRAT. → STATUS (abaixo de SINAIS)
// + m_s_hdrSM, m_s_lStrats/eStrats, m_s_lFilts/eFilts, m_s_lConflict/eConflict

//+------------------------------------------------------------------+
//| ABA 0: STATUS — Criar controles                                   |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabStatus(void)
  {
   int y = CONTENT_TOP;

   if(!CreateHdr(m_s_hdr1, "s_h1", "ESTADO DO SISTEMA", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_s_lTrading, m_s_eTrading, "s_lTr", "s_eTr", "Trading:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lBlocker, m_s_eBlocker, "s_lBl", "s_eBl", "Bloqueador:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lSpread, m_s_eSpread, "s_lSp", "s_eSp", "Spread:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lTime, m_s_eTime, "s_lTm", "s_eTm", "Horario:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_s_hdr2, "s_h2", "POSICAO", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_s_lHasPos, m_s_eHasPos, "s_lHP", "s_eHP", "Posicao Aberta:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lTicket, m_s_eTicket, "s_lTk", "s_eTk", "Ticket:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lPosType, m_s_ePosType, "s_lPT", "s_ePT", "Tipo:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lPosProfit, m_s_ePosProfit, "s_lPP", "s_ePP", "P/L Flutuante:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lBE, m_s_eBE, "s_lBE", "s_eBE", "Breakeven:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lTrail, m_s_eTrail, "s_lTl", "s_eTl", "Trailing:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lPartial, m_s_ePartial, "s_lPt", "s_ePt", "Partial TP:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_s_hdr3, "s_h3", "SINAIS", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_s_lSignal, m_s_eSignal, "s_lSg", "s_eSg", "Ultimo Sinal:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lBlocked, m_s_eBlocked, "s_lBk", "s_eBk", "Bloqueado por:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_s_hdrSM, "s_hSM", "SIGNAL MANAGER", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_s_lStrats, m_s_eStrats, "s_lSt", "s_eSt", "Estrategias:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lFilts, m_s_eFilts, "s_lFl", "s_eFl", "Filtros:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lConflict, m_s_eConflict, "s_lCf", "s_eCf", "Modo Conflito:", y)) return false;

   return true;
  }

//+------------------------------------------------------------------+
//| UpdateStatus — atualiza dados da aba STATUS                       |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateStatus(void)
  {
// ── Estado do Sistema ──
   if(m_blockers != NULL)
     {
      string blockReason = "";
      bool blocked = !m_blockers.CanTrade(
                        (m_logger != NULL) ? m_logger.GetDailyTrades() : 0,
                        (m_logger != NULL) ? m_logger.GetDailyProfit() : 0,
                        blockReason);

      if(!m_eaStarted)
         SetEV(m_s_eTrading, "PAUSADO", CLR_WARNING);
      else
         SetEV(m_s_eTrading, blocked ? "BLOQUEADO" : "Permitido",
               blocked ? CLR_NEGATIVE : CLR_POSITIVE);
      SetEV(m_s_eBlocker, blocked ? BlockerToStr(m_blockers.GetActiveBlocker()) : "Nenhum",
            blocked ? CLR_WARNING : CLR_NEUTRAL);

      int spread = (int)SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
      int maxSpr = m_blockers.GetMaxSpread();
      string sprTxt = IntegerToString(spread) + (maxSpr > 0 ? " / Max: " + IntegerToString(maxSpr) : "");
      SetEV(m_s_eSpread, sprTxt, (maxSpr > 0 && spread > maxSpr) ? CLR_NEGATIVE : CLR_VALUE);

      MqlDateTime tm;
      TimeCurrent(tm);
      SetEV(m_s_eTime, StringFormat("%02d:%02d:%02d", tm.hour, tm.min, tm.sec), CLR_VALUE);
     }
   else
     {
      SetEV(m_s_eTrading, "N/A", CLR_NEUTRAL);
      SetEV(m_s_eBlocker, "N/A", CLR_NEUTRAL);
      SetEV(m_s_eSpread, "N/A", CLR_NEUTRAL);
      SetEV(m_s_eTime, "N/A", CLR_NEUTRAL);
     }

// ── Posição ──
   bool hasPos = false;
   ulong posTicket = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != m_symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != m_magicNumber)
         continue;
      hasPos = true;
      posTicket = PositionGetTicket(i);
      break;
     }

   if(hasPos && PositionSelectByTicket(posTicket))
     {
      ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

      SetEV(m_s_eHasPos, "Sim", CLR_POSITIVE);
      SetEV(m_s_eTicket, "#" + IntegerToString((long)posTicket), CLR_VALUE);
      SetEV(m_s_ePosType, (pt == POSITION_TYPE_BUY) ? "BUY" : "SELL",
            (pt == POSITION_TYPE_BUY) ? CLR_POSITIVE : CLR_NEGATIVE);
      SetEV(m_s_ePosProfit, "$" + DoubleToString(profit, 2),
            (profit > 0.01) ? CLR_POSITIVE : (profit < -0.01) ? CLR_NEGATIVE : CLR_VALUE);

      if(m_tradeManager != NULL)
        {
         SetEV(m_s_eBE, m_tradeManager.IsBreakevenActivated(posTicket) ? "Ativado" : "Pendente",
               m_tradeManager.IsBreakevenActivated(posTicket) ? CLR_POSITIVE : CLR_NEUTRAL);
         SetEV(m_s_eTrail, m_tradeManager.IsTrailingActive(posTicket) ? "Ativo" : "Inativo",
               m_tradeManager.IsTrailingActive(posTicket) ? CLR_POSITIVE : CLR_NEUTRAL);

         bool tp1 = m_tradeManager.IsTP1Executed(posTicket);
         bool tp2 = m_tradeManager.IsTP2Executed(posTicket);
         string tpTxt = tp1 ? (tp2 ? "TP1+TP2 OK" : "TP1 OK") : "Pendente";
         SetEV(m_s_ePartial, tpTxt, tp1 ? CLR_POSITIVE : CLR_NEUTRAL);
        }
      else
        {
         SetEV(m_s_eBE, "--", CLR_NEUTRAL);
         SetEV(m_s_eTrail, "--", CLR_NEUTRAL);
         SetEV(m_s_ePartial, "--", CLR_NEUTRAL);
        }
     }
   else
     {
      SetEV(m_s_eHasPos, "Nao", CLR_NEUTRAL);
      SetEV(m_s_eTicket, "--", CLR_NEUTRAL);
      SetEV(m_s_ePosType, "--", CLR_NEUTRAL);
      SetEV(m_s_ePosProfit, "--", CLR_NEUTRAL);
      SetEV(m_s_eBE, "--", CLR_NEUTRAL);
      SetEV(m_s_eTrail, "--", CLR_NEUTRAL);
      SetEV(m_s_ePartial, "--", CLR_NEUTRAL);
     }

// ── Sinais ──
   if(m_signalManager != NULL)
     {
      string src = m_signalManager.GetLastSignalSource();
      string blk = m_signalManager.GetLastBlockedBy();
      SetEV(m_s_eSignal, (src != "") ? src : "Nenhum", (src != "") ? CLR_VALUE : CLR_NEUTRAL);
      SetEV(m_s_eBlocked, (blk != "") ? blk : "Nenhum", (blk != "") ? CLR_WARNING : CLR_NEUTRAL);

// ── Signal Manager ──
      SetEV(m_s_eStrats, IntegerToString(m_signalManager.GetStrategyCount()), CLR_VALUE);
      SetEV(m_s_eFilts,  IntegerToString(m_signalManager.GetFilterCount()),   CLR_VALUE);
      string cm = (m_signalManager.GetConflictMode() == CONFLICT_PRIORITY) ? "Prioridade" : "Cancelar";
      SetEV(m_s_eConflict, cm, CLR_VALUE);
     }
   else
     {
      SetEV(m_s_eSignal, "N/A", CLR_NEUTRAL);
      SetEV(m_s_eBlocked, "N/A", CLR_NEUTRAL);
      SetEV(m_s_eStrats, "N/A", CLR_NEUTRAL);
      SetEV(m_s_eFilts,  "N/A", CLR_NEUTRAL);
      SetEV(m_s_eConflict, "N/A", CLR_NEUTRAL);
     }
  }

//+------------------------------------------------------------------+
//| BlockerToStr — converte enum para texto legível                   |
//+------------------------------------------------------------------+
string CEPBotPanel::BlockerToStr(ENUM_BLOCKER_REASON r)
  {
   switch(r)
     {
      case BLOCKER_NONE:         return "Nenhum";
      case BLOCKER_TIME_FILTER:  return "Fora do horario";
      case BLOCKER_NEWS_FILTER:  return "Volatilidade";
      case BLOCKER_SPREAD:       return "Spread alto";
      case BLOCKER_DAILY_TRADES: return "Limite trades";
      case BLOCKER_DAILY_LOSS:   return "Perda maxima";
      case BLOCKER_DAILY_GAIN:   return "Ganho maximo";
      case BLOCKER_LOSS_STREAK:  return "Seq. perdas";
      case BLOCKER_WIN_STREAK:   return "Seq. ganhos";
      case BLOCKER_DRAWDOWN:     return "Drawdown";
      case BLOCKER_DIRECTION:    return "Direcao bloq.";
      default:                   return "Desconhecido";
     }
  }
//+------------------------------------------------------------------+
