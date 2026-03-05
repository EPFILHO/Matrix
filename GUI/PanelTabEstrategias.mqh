//+------------------------------------------------------------------+
//|                                         PanelTabEstrategias.mqh  |
//|                                         Copyright 2026, EP Filho |
//|          Panel Tab: ESTRATEGIAS — Create + Update                 |
//|                     Versão 1.12 - Claude Parte 024 (Claude Code) |
//+------------------------------------------------------------------+
// Implementações de CEPBotPanel para a aba ESTRATEGIAS.
// Incluído por Panel.mqh — NÃO incluir diretamente.
//
// v1.12 (Parte 024):
// + Sub-páginas: [MA CROSS] [RSI]
// + SIGNAL MANAGER removido daqui → movido para aba STATUS
// + ShowEstratPage, SetEstratPageVis, UpdateEstratBtnStyles
// + OnClickEstratMACross, OnClickEstratRSI

//+------------------------------------------------------------------+
//| ABA 2: ESTRATEGIAS — Criar controles                              |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabEstrategias(void)
  {
   int sy = CONTENT_TOP;

// ── Botões de sub-página ──
   int sw = (PANEL_WIDTH - 40) / ESTRAT_PAGE_COUNT;

   if(!m_e_btnMACross.Create(m_chart_id, PFX + "e_bMC", m_subwin,
                             5, sy, 5 + sw, sy + TAB_BTN_H))
      return false;
   m_e_btnMACross.Text("MA CROSS");
   m_e_btnMACross.FontSize(7);
   if(!Add(m_e_btnMACross))
      return false;

   if(!m_e_btnRSI.Create(m_chart_id, PFX + "e_bRS", m_subwin,
                         5 + (sw + 2), sy, 5 + sw * 2 + 2, sy + TAB_BTN_H))
      return false;
   m_e_btnRSI.Text("RSI");
   m_e_btnRSI.FontSize(7);
   if(!Add(m_e_btnRSI))
      return false;

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: MA CROSS STRATEGY
// ════════════════════════════════════════════════════════════
   int y = ESTRAT_CONTENT_Y;

   if(!CreateHdr(m_e_hdr2, "e_h2", "MA CROSS STRATEGY", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_e_lMAStatus, m_e_eMAStatus, "e_lMS", "e_eMS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMAFast, m_e_eMAFast, "e_lMF", "e_eMF", "MA Rapida:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMASlow, m_e_eMASlow, "e_lML", "e_eML", "MA Lenta:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMACross, m_e_eMACross, "e_lMC", "e_eMC", "Ultimo Cruz.:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMACandles, m_e_eMACandles, "e_lMN", "e_eMN", "Candles Apos:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMAEntry, m_e_eMAEntry, "e_lME", "e_eME", "Entrada:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMAExit, m_e_eMAExit, "e_lMX", "e_eMX", "Saida:", y)) return false;

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: RSI STRATEGY
// ════════════════════════════════════════════════════════════
   y = ESTRAT_CONTENT_Y;

   if(!CreateHdr(m_e_hdr3, "e_h3", "RSI STRATEGY", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_e_lRSIStatus, m_e_eRSIStatus, "e_lRS", "e_eRS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRSICurr, m_e_eRSICurr, "e_lRC", "e_eRC", "RSI Atual:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRSIMode, m_e_eRSIMode, "e_lRM", "e_eRM", "Modo:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRSILevels, m_e_eRSILevels, "e_lRL", "e_eRL", "Niveis:", y)) return false;

// ── Sub-página inicial ──
   ShowEstratPage(ESTRAT_MA_CROSS);

   return true;
  }

//+------------------------------------------------------------------+
//| SetEstratPageVis — show/hide controles de uma sub-página          |
//+------------------------------------------------------------------+
void CEPBotPanel::SetEstratPageVis(ENUM_ESTRAT_PAGE page, bool vis)
  {
   switch(page)
     {
      case ESTRAT_MA_CROSS:
         if(vis) { m_e_hdr2.Show(); m_e_lMAStatus.Show(); m_e_eMAStatus.Show();
                    m_e_lMAFast.Show(); m_e_eMAFast.Show(); m_e_lMASlow.Show(); m_e_eMASlow.Show();
                    m_e_lMACross.Show(); m_e_eMACross.Show(); m_e_lMACandles.Show(); m_e_eMACandles.Show();
                    m_e_lMAEntry.Show(); m_e_eMAEntry.Show(); m_e_lMAExit.Show(); m_e_eMAExit.Show(); }
         else    { m_e_hdr2.Hide(); m_e_lMAStatus.Hide(); m_e_eMAStatus.Hide();
                    m_e_lMAFast.Hide(); m_e_eMAFast.Hide(); m_e_lMASlow.Hide(); m_e_eMASlow.Hide();
                    m_e_lMACross.Hide(); m_e_eMACross.Hide(); m_e_lMACandles.Hide(); m_e_eMACandles.Hide();
                    m_e_lMAEntry.Hide(); m_e_eMAEntry.Hide(); m_e_lMAExit.Hide(); m_e_eMAExit.Hide(); }
         break;
      case ESTRAT_RSI:
         if(vis) { m_e_hdr3.Show(); m_e_lRSIStatus.Show(); m_e_eRSIStatus.Show();
                    m_e_lRSICurr.Show(); m_e_eRSICurr.Show(); m_e_lRSIMode.Show(); m_e_eRSIMode.Show();
                    m_e_lRSILevels.Show(); m_e_eRSILevels.Show(); }
         else    { m_e_hdr3.Hide(); m_e_lRSIStatus.Hide(); m_e_eRSIStatus.Hide();
                    m_e_lRSICurr.Hide(); m_e_eRSICurr.Hide(); m_e_lRSIMode.Hide(); m_e_eRSIMode.Hide();
                    m_e_lRSILevels.Hide(); m_e_eRSILevels.Hide(); }
         break;
     }
  }

//+------------------------------------------------------------------+
//| ShowEstratPage — alterna sub-página ativa do ESTRAT.              |
//+------------------------------------------------------------------+
void CEPBotPanel::ShowEstratPage(ENUM_ESTRAT_PAGE page)
  {
   m_estratPage = page;
   for(int p = 0; p < ESTRAT_PAGE_COUNT; p++)
      SetEstratPageVis((ENUM_ESTRAT_PAGE)p, false);
   SetEstratPageVis(page, true);
   UpdateEstratBtnStyles();
  }

//+------------------------------------------------------------------+
//| UpdateEstratBtnStyles — destaque no botão da sub-página ativa     |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateEstratBtnStyles(void)
  {
   m_e_btnMACross.Pressed(false); m_e_btnRSI.Pressed(false);

   m_e_btnMACross.ColorBackground((m_estratPage == ESTRAT_MA_CROSS) ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
   m_e_btnRSI.ColorBackground(    (m_estratPage == ESTRAT_RSI)      ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);

   m_e_btnMACross.Color((m_estratPage == ESTRAT_MA_CROSS) ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_e_btnRSI.Color(    (m_estratPage == ESTRAT_RSI)      ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
  }

//+------------------------------------------------------------------+
//| Handlers de clique das sub-páginas ESTRAT.                        |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickEstratMACross(void) { ShowEstratPage(ESTRAT_MA_CROSS); }
void CEPBotPanel::OnClickEstratRSI(void)     { ShowEstratPage(ESTRAT_RSI); }

//+------------------------------------------------------------------+
//| UpdateEstrategias — atualiza dados da aba ESTRATEGIAS             |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateEstrategias(void)
  {
   if(m_estratPage == ESTRAT_MA_CROSS)
     {
// ── MA Cross ──
      if(m_maCross != NULL && m_maCross.IsInitialized())
        {
         SetEV(m_e_eMAStatus, "Ativo (P:" + IntegerToString(m_maCross.GetPriority()) + ")", CLR_POSITIVE);
         SetEV(m_e_eMAFast, DoubleToString(m_maCross.GetMAFast(), _Digits), CLR_VALUE);
         SetEV(m_e_eMASlow, DoubleToString(m_maCross.GetMASlow(), _Digits), CLR_VALUE);

         ENUM_SIGNAL_TYPE lastCross = m_maCross.GetLastCross();
         string crossTxt = (lastCross == SIGNAL_BUY) ? "BUY" : (lastCross == SIGNAL_SELL) ? "SELL" : "Nenhum";
         color crossClr = (lastCross == SIGNAL_BUY) ? CLR_POSITIVE : (lastCross == SIGNAL_SELL) ? CLR_NEGATIVE : CLR_NEUTRAL;
         SetEV(m_e_eMACross, crossTxt, crossClr);
         SetEV(m_e_eMACandles, IntegerToString(m_maCross.GetCandlesAfterCross()), CLR_VALUE);

         string entryTxt = (m_maCross.GetEntryMode() == ENTRY_NEXT_CANDLE) ? "Next Candle" : "2nd Candle";
         SetEV(m_e_eMAEntry, entryTxt, CLR_VALUE);

         ENUM_EXIT_MODE em = m_maCross.GetExitMode();
         string exitTxt = (em == EXIT_FCO) ? "FCO" : (em == EXIT_VM) ? "VM" : "TP/SL";
         SetEV(m_e_eMAExit, exitTxt, CLR_VALUE);
        }
      else
        {
         SetEV(m_e_eMAStatus, "Inativo", CLR_NEUTRAL);
         SetEV(m_e_eMAFast, "--", CLR_NEUTRAL);
         SetEV(m_e_eMASlow, "--", CLR_NEUTRAL);
         SetEV(m_e_eMACross, "--", CLR_NEUTRAL);
         SetEV(m_e_eMACandles, "--", CLR_NEUTRAL);
         SetEV(m_e_eMAEntry, "--", CLR_NEUTRAL);
         SetEV(m_e_eMAExit, "--", CLR_NEUTRAL);
        }
     }
   else if(m_estratPage == ESTRAT_RSI)
     {
// ── RSI Strategy ──
      if(m_rsiStrategy != NULL && m_rsiStrategy.IsInitialized())
        {
         SetEV(m_e_eRSIStatus, "Ativo (P:" + IntegerToString(m_rsiStrategy.GetPriority()) + ")", CLR_POSITIVE);
         SetEV(m_e_eRSICurr, DoubleToString(m_rsiStrategy.GetCurrentRSI(), 1), CLR_VALUE);
         SetEV(m_e_eRSIMode, m_rsiStrategy.GetSignalModeText(), CLR_VALUE);
         SetEV(m_e_eRSILevels, DoubleToString(m_rsiStrategy.GetOversold(), 0) + " / " +
               DoubleToString(m_rsiStrategy.GetOverbought(), 0), CLR_VALUE);
        }
      else
        {
         SetEV(m_e_eRSIStatus, "Inativo", CLR_NEUTRAL);
         SetEV(m_e_eRSICurr, "--", CLR_NEUTRAL);
         SetEV(m_e_eRSIMode, "--", CLR_NEUTRAL);
         SetEV(m_e_eRSILevels, "--", CLR_NEUTRAL);
        }
     }
  }
//+------------------------------------------------------------------+
