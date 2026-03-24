//+------------------------------------------------------------------+
//|                                          PanelTabResultados.mqh  |
//|                                         Copyright 2026, EP Filho |
//|          Panel Tab: RESULTADOS — Create + Update                  |
//|                     Versão 1.12 - Claude Parte 024 (Claude Code) |
//+------------------------------------------------------------------+
// Implementações de CEPBotPanel para a aba RESULTADOS.
// Incluído por Panel.mqh — NÃO incluir diretamente.
//
// v1.12 (Parte 024):
// ✅ Fix: "Drawdown Atual: 180.00%" — GetCurrentDrawdown() retorna $ mas
//    GUI appendava "%" — corrigido para "$180.00 / $200.00"
// + Seção PROTECAO expandida: DD Limite (tipo+valor), DD Modo Pico,
//   DD Atual (valor/limite), Streak (ativado/desativado/pausado),
//   Seq. Perdas/Ganhos com limite e ação (Pausar Xmin / Parar dia)

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
   if(!CreateLV(m_r_lDDLim, m_r_eDDLim, "r_lDL", "r_eDL", "DD Limite:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lDDMode, m_r_eDDMode, "r_lDM", "r_eDM", "DD Modo Pico:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lDD, m_r_eDD, "r_lDD", "r_eDD", "DD Atual:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lPeak, m_r_ePeak, "r_lPk", "r_ePk", "Pico Lucro Dia:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lStreak, m_r_eStreak, "r_lSk", "r_eSk", "Streak:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lLossStrk, m_r_eLossStrk, "r_lLS", "r_eLS", "Seq. Perdas:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lWinStrk, m_r_eWinStrk, "r_lWS", "r_eWS", "Seq. Ganhos:", y)) return false;

// ── Registrar controles para Show/Hide genérico em SetTabVis ──
   m_resultCtrlCount = 0;
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_hdr1);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lGains);     TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eGains);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lTotalLoss); TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eTotalLoss);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lProfit);    TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eProfit);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_hdr2);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lTrades);    TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eTrades);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lWins);      TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eWins);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lLosses);    TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eLosses);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lDraws);     TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eDraws);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_hdr3);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lWinRate);   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eWinRate);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lPayoff);    TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_ePayoff);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lPF);        TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_ePF);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_hdr4);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lDDLim);     TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eDDLim);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lDDMode);    TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eDDMode);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lDD);        TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eDD);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lPeak);      TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_ePeak);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lStreak);    TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eStreak);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lLossStrk);  TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eLossStrk);
   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_lWinStrk);   TrackCtrl(m_resultCtrls, m_resultCtrlCount, m_r_eWinStrk);

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

// ── Proteção: Drawdown ──
   if(m_blockers != NULL)
     {
      if(m_blockers.IsDrawdownProtectionActive() || m_blockers.GetDrawdownValue() > 0)
        {
         ENUM_DRAWDOWN_TYPE ddType = m_blockers.GetDrawdownType();
         double ddVal = m_blockers.GetDrawdownValue();

         // DD Limite
         if(ddType == DD_FINANCIAL)
            SetEV(m_r_eDDLim, "$" + DoubleToString(ddVal, 2) + " (Financeiro)", CLR_VALUE);
         else
            SetEV(m_r_eDDLim, DoubleToString(ddVal, 1) + "% (Percentual)", CLR_VALUE);

         // DD Modo Pico
         if(m_blockers.GetDrawdownPeakMode() == DD_PEAK_REALIZED_ONLY)
            SetEV(m_r_eDDMode, "So Realizado", CLR_VALUE);
         else
            SetEV(m_r_eDDMode, "C/ Flutuante", CLR_VALUE);

         // DD Atual: "valor / limite"
         double dd = m_blockers.GetCurrentDrawdown();
         if(ddType == DD_FINANCIAL)
            SetEV(m_r_eDD, "$" + DoubleToString(dd, 2) + " / $" + DoubleToString(ddVal, 2),
                  (dd == 0) ? CLR_POSITIVE : (dd >= ddVal) ? CLR_NEGATIVE : CLR_WARNING);
         else
            SetEV(m_r_eDD, DoubleToString(dd, 1) + "% / " + DoubleToString(ddVal, 1) + "%",
                  (dd == 0) ? CLR_POSITIVE : (dd >= ddVal) ? CLR_NEGATIVE : CLR_WARNING);
        }
      else
        {
         SetEV(m_r_eDDLim,  "--", CLR_VALUE);
         SetEV(m_r_eDDMode, "--", CLR_VALUE);
         SetEV(m_r_eDD,     "--", CLR_VALUE);
        }

      // Pico (sempre mostra)
      SetEV(m_r_ePeak, "$" + DoubleToString(m_blockers.GetDailyPeakProfit(), 2), CLR_VALUE);

      // ── Proteção: Streak ──
      if(m_blockers.IsStreakControlEnabled())
        {
         if(m_blockers.IsStreakPaused())
           {
            MqlDateTime pauseTime;
            TimeToStruct(m_blockers.GetStreakPauseUntil(), pauseTime);
            SetEV(m_r_eStreak, StringFormat("PAUSADO ate %02d:%02d", pauseTime.hour, pauseTime.min), CLR_WARNING);
           }
         else
            SetEV(m_r_eStreak, "ATIVADO", CLR_POSITIVE);

         // Seq. Perdas: "4 / 5 (Pausar 5min)"
         int maxL = m_blockers.GetMaxLossStreak();
         int curL = m_blockers.GetCurrentLossStreak();
         if(maxL > 0)
           {
            string actionL = (m_blockers.GetLossStreakAction() == STREAK_PAUSE)
               ? "Pausar " + IntegerToString(m_blockers.GetLossPauseMinutes()) + "min"
               : "Parar dia";
            SetEV(m_r_eLossStrk,
               IntegerToString(curL) + " / " + IntegerToString(maxL) + " (" + actionL + ")",
               (curL >= maxL) ? CLR_NEGATIVE : CLR_VALUE);
           }
         else
            SetEV(m_r_eLossStrk, IntegerToString(curL) + " (sem limite)", CLR_VALUE);

         // Seq. Ganhos: "0 / 3 (Parar dia)"
         int maxW = m_blockers.GetMaxWinStreak();
         int curW = m_blockers.GetCurrentWinStreak();
         if(maxW > 0)
           {
            string actionW = (m_blockers.GetWinStreakAction() == STREAK_PAUSE)
               ? "Pausar " + IntegerToString(m_blockers.GetWinPauseMinutes()) + "min"
               : "Parar dia";
            SetEV(m_r_eWinStrk,
               IntegerToString(curW) + " / " + IntegerToString(maxW) + " (" + actionW + ")",
               (curW >= maxW) ? CLR_NEGATIVE : CLR_VALUE);
           }
         else
            SetEV(m_r_eWinStrk, IntegerToString(curW) + " (sem limite)", CLR_VALUE);
        }
      else
        {
         SetEV(m_r_eStreak, "DESATIVADO", CLR_VALUE);
         SetEV(m_r_eLossStrk, IntegerToString(m_blockers.GetCurrentLossStreak()) + " (sem limite)", CLR_VALUE);
         SetEV(m_r_eWinStrk, IntegerToString(m_blockers.GetCurrentWinStreak()) + " (sem limite)", CLR_VALUE);
        }
     }
  }
//+------------------------------------------------------------------+
