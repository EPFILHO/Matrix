//+------------------------------------------------------------------+
//|                                          PanelTabResultados.mqh  |
//|                                         Copyright 2026, EP Filho |
//|          Panel Tab: RESULTADOS — Create + Update                  |
//|                     Versão 1.11 - Claude Parte 022 (Claude Code) |
//+------------------------------------------------------------------+
// Implementações de CEPBotPanel para a aba RESULTADOS.
// Incluído por Panel.mqh — NÃO incluir diretamente.

//+------------------------------------------------------------------+
//| ABA 1: RESULTADOS — Criar controles                               |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabResultados(void)
  {
   int y = CONTENT_TOP;

   if(!CreateHdr(m_r_hdr1, "r_h1", "RESULTADO FINANCEIRO", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_r_lGains, m_r_eGains, "r_lGn", "r_eGn", "Ganhos:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lTotalLoss, m_r_eTotalLoss, "r_lTL", "r_eTL", "Perdas:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lProfit, m_r_eProfit, "r_lPr", "r_ePr", "P/L Total Dia:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_r_hdr2, "r_h2", "TRADES DO DIA", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_r_lTrades, m_r_eTrades, "r_lTd", "r_eTd", "Total Trades:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lWins, m_r_eWins, "r_lWn", "r_eWn", "Ganhos:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lLosses, m_r_eLosses, "r_lLs", "r_eLs", "Perdas:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lDraws, m_r_eDraws, "r_lDr", "r_eDr", "Empates:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_r_hdr3, "r_h3", "METRICAS", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_r_lWinRate, m_r_eWinRate, "r_lWR", "r_eWR", "Win Rate:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lPayoff, m_r_ePayoff, "r_lPO", "r_ePO", "Payoff Ratio:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lPF, m_r_ePF, "r_lPF", "r_ePF", "Profit Factor:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_r_hdr4, "r_h4", "PROTECAO", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_r_lDD, m_r_eDD, "r_lDD", "r_eDD", "Drawdown Atual:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lPeak, m_r_ePeak, "r_lPk", "r_ePk", "Pico Lucro Dia:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lLossStrk, m_r_eLossStrk, "r_lLS", "r_eLS", "Seq. Perdas:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lWinStrk, m_r_eWinStrk, "r_lWS", "r_eWS", "Seq. Ganhos:", y)) return false;

   return true;
  }

//+------------------------------------------------------------------+
//| UpdateResultados — atualiza dados da aba RESULTADOS               |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateResultados(void)
  {
   if(m_logger == NULL)
      return;

// ── Financeiro ──
   double grossP = m_logger.GetGrossProfit();
   double grossL = m_logger.GetGrossLoss();
   double totalProfit = m_logger.GetDailyProfit();

   SetEV(m_r_eGains, "+$" + DoubleToString(grossP, 2),
         (grossP > 0.01) ? CLR_POSITIVE : CLR_VALUE);
   SetEV(m_r_eTotalLoss, "-$" + DoubleToString(grossL, 2),
         (grossL > 0.01) ? CLR_NEGATIVE : CLR_VALUE);
   SetEV(m_r_eProfit, "$" + DoubleToString(totalProfit, 2),
         (totalProfit > 0.01) ? CLR_POSITIVE : (totalProfit < -0.01) ? CLR_NEGATIVE : CLR_VALUE);

// ── Trades ──
   int trades = m_logger.GetDailyTrades();
   int wins   = m_logger.GetDailyWins();
   int losses = m_logger.GetDailyLosses();
   int draws  = m_logger.GetDailyDraws();

   SetEV(m_r_eTrades, IntegerToString(trades), CLR_VALUE);
   SetEV(m_r_eWins, IntegerToString(wins), CLR_POSITIVE);
   SetEV(m_r_eLosses, IntegerToString(losses), (losses > 0) ? CLR_NEGATIVE : CLR_VALUE);
   SetEV(m_r_eDraws, IntegerToString(draws), CLR_NEUTRAL);

// ── Métricas ──
   double winRate = (wins + losses > 0) ? (double)wins / (wins + losses) * 100.0 : 0;
   double avgWin  = (wins > 0) ? grossP / wins : 0;
   double avgLoss = (losses > 0) ? grossL / losses : 0;
   double payoff = (avgLoss > 0) ? avgWin / avgLoss : 0;
   double pf = (grossL > 0) ? grossP / grossL : 0;

   SetEV(m_r_eWinRate, DoubleToString(winRate, 1) + "%",
         (winRate >= 50) ? CLR_POSITIVE : (winRate >= 30) ? CLR_WARNING : CLR_NEGATIVE);
   SetEV(m_r_ePayoff, DoubleToString(payoff, 2),
         (payoff >= 1.5) ? CLR_POSITIVE : (payoff >= 1.0) ? CLR_WARNING : CLR_NEUTRAL);
   SetEV(m_r_ePF, (grossL > 0) ? DoubleToString(pf, 2) : (grossP > 0) ? "INF" : "0.00",
         (pf >= 1.5) ? CLR_POSITIVE : (pf >= 1.0) ? CLR_WARNING : CLR_NEGATIVE);

// ── Proteção ──
   if(m_blockers != NULL)
     {
      double dd = m_blockers.GetCurrentDrawdown();
      double peak = m_blockers.GetDailyPeakProfit();
      int lossStrk = m_blockers.GetCurrentLossStreak();
      int winStrk  = m_blockers.GetCurrentWinStreak();

      SetEV(m_r_eDD, DoubleToString(dd, 2) + "%",
            (dd == 0) ? CLR_POSITIVE : (dd > 50) ? CLR_NEGATIVE : CLR_WARNING);
      SetEV(m_r_ePeak, "$" + DoubleToString(peak, 2), CLR_VALUE);
      SetEV(m_r_eLossStrk, IntegerToString(lossStrk), (lossStrk >= 3) ? CLR_NEGATIVE : CLR_VALUE);
      SetEV(m_r_eWinStrk, IntegerToString(winStrk), (winStrk >= 3) ? CLR_POSITIVE : CLR_VALUE);
     }
  }
//+------------------------------------------------------------------+
