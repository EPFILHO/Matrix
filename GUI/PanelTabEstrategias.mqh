//+------------------------------------------------------------------+
//|                                         PanelTabEstrategias.mqh  |
//|                                         Copyright 2026, EP Filho |
//|          Panel Tab: ESTRATEGIAS — Create + Update                 |
//|                     Versão 1.16 - Claude Parte 024 (Claude Code) |
//+------------------------------------------------------------------+
// v1.16 (Parte 024):
// + MA Cross e RSI: botão toggle ON/OFF (m_e_btnMAToggle, m_e_btnRSIToggle)
// + ApplyToggleStyle: verde (LIGADO) / vermelho (DESLIGADO)
// + Handlers: OnClickMAToggle, OnClickRSIToggle
// + MACrossStrategy v2.23 e RSIStrategy v2.12: m_enabled, SetEnabled(), GetEnabled()
//
// v1.15 (Parte 024):
// + RSI sub-página: campos editáveis hot/cold reload inline
//   Period(edit), TF(cycle), Mode(radio 3), Oversold, Overbought, Middle
//   Botão APLICAR próprio (m_e_btnApplyRSI) + status (m_e_statusRSI)
// + Helpers: RSIModeToIndex, IndexToRSIMode
// + Handlers: OnClickApplyRSI, OnClickRSIMode, OnClickRSITF
//
// v1.13 (Parte 024):
// + MA Cross sub-página: campos editáveis hot/cold reload inline
//   Fast/Slow Period, Method(4), TF(cycle), Entry(2), Exit(3)
//   Botão APLICAR próprio (m_e_btnApplyMA) + status (m_e_statusMA)
// + Helpers: CycleTF, TFName, MAMethodToIndex, IndexToMAMethod
// + Handlers: OnClickApplyMA, OnClickMAFastMethod/SlowMethod,
//   OnClickMAFastTF/SlowTF, OnClickMAEntry, OnClickMAExit
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

// ── Toggle ON/OFF MA Cross ──
   {
    bool maOn = (m_maCross != NULL) ? m_maCross.GetEnabled() : true;
    if(!m_e_btnMAToggle.Create(m_chart_id, PFX + "e_bMAOn", m_subwin,
                               COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 20))
       return false;
    m_e_btnMAToggle.FontSize(8);
    if(!Add(m_e_btnMAToggle)) return false;
    ApplyToggleStyle(m_e_btnMAToggle, maOn);
   }
   y += 24;

   if(!CreateLV(m_e_lMAStatus, m_e_eMAStatus, "e_lMS", "e_eMS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMAFast, m_e_eMAFast, "e_lMF", "e_eMF", "MA Rapida:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMASlow, m_e_eMASlow, "e_lML", "e_eML", "MA Lenta:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMACross, m_e_eMACross, "e_lMC", "e_eMC", "Ultimo Cruz.:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMACandles, m_e_eMACandles, "e_lMN", "e_eMN", "Candles Apos:", y)) return false;
   y += PANEL_GAP_Y + 2;

// ── CONFIGURAÇÕES EDITÁVEIS ──
   y += PANEL_GAP_SECTION;
   if(!CreateHdr(m_ce_hdr1, "ce_h1", "CONFIGURACOES", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(!CreateLI(m_ce_lFastP, m_ce_iFastP, "ce_lFP", "ce_iFP", "Fast Period:", y)) return false;
   y += PANEL_GAP_Y;
   {
    string fmTexts[] = {"SMA", "EMA", "SMMA", "LWMA"};
    if(!CreateRadioGroup(m_ce_lFastM, m_ce_bFastM, "ce_lFM", "ce_bFM", "Fast Method:", fmTexts, 4, y))
       return false;
   }
   y += PANEL_GAP_Y + 2;
   if(!CreateLB(m_ce_lFastTF, m_ce_bFastTF, "ce_lFT", "ce_bFT", "Fast Time Frame:", y)) return false;
   y += PANEL_GAP_Y + 2;

   y += PANEL_GAP_SECTION;
   if(!CreateLI(m_ce_lSlowP, m_ce_iSlowP, "ce_lSP", "ce_iSP", "Slow Period:", y)) return false;
   y += PANEL_GAP_Y;
   {
    string smTexts[] = {"SMA", "EMA", "SMMA", "LWMA"};
    if(!CreateRadioGroup(m_ce_lSlowM, m_ce_bSlowM, "ce_lSM", "ce_bSM", "Slow Method:", smTexts, 4, y))
       return false;
   }
   y += PANEL_GAP_Y + 2;
   if(!CreateLB(m_ce_lSlowTF, m_ce_bSlowTF, "ce_lST2", "ce_bST2", "Slow Time Frame:", y)) return false;
   y += PANEL_GAP_Y + 2;

   y += PANEL_GAP_SECTION;
   if(!CreateHdr(m_ce_hdr2, "ce_h2", "SINAIS", y)) return false;
   y += PANEL_GAP_Y + 2;
   {
    string entTexts[] = {"PROX. CANDLE", "2o. CANDLE"};
    if(!CreateRadioGroup(m_ce_lEntry, m_ce_bEntry, "ce_lEN", "ce_bEN", "Entrada:", entTexts, 2, y))
       return false;
   }
   y += PANEL_GAP_Y + 2;
   {
    string extTexts[] = {"FCO", "VM", "TP-SL"};
    if(!CreateRadioGroup(m_ce_lExit, m_ce_bExit, "ce_lEX", "ce_bEX", "Saida:", extTexts, 3, y))
       return false;
   }
   y += PANEL_GAP_Y + 8;

// ── LEGENDA DAS SIGLAS ──
   if(!m_e_lLeg1.Create(m_chart_id, PFX + "e_leg1", m_subwin,
                         COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + PANEL_GAP_Y))
      return false;
   m_e_lLeg1.Text("FCO - Fechar no Cruzamento Oposto");
   m_e_lLeg1.FontSize(7);
   m_e_lLeg1.Color(CLR_NEUTRAL);
   if(!Add(m_e_lLeg1)) return false;
   y += PANEL_GAP_Y;

   if(!m_e_lLeg2.Create(m_chart_id, PFX + "e_leg2", m_subwin,
                         COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + PANEL_GAP_Y))
      return false;
   m_e_lLeg2.Text("VM - Virar a mao");
   m_e_lLeg2.FontSize(7);
   m_e_lLeg2.Color(CLR_NEUTRAL);
   if(!Add(m_e_lLeg2)) return false;
   y += PANEL_GAP_Y;

   if(!m_e_lLeg3.Create(m_chart_id, PFX + "e_leg3", m_subwin,
                         COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + PANEL_GAP_Y))
      return false;
   m_e_lLeg3.Text("TP/SL - Sair no TP/SL configurados");
   m_e_lLeg3.FontSize(7);
   m_e_lLeg3.Color(CLR_NEUTRAL);
   if(!Add(m_e_lLeg3)) return false;

// ── BOTÃO APLICAR MA CROSS (posição fixa, igual ao CONFIG) ──
   if(!m_e_btnApplyMA.Create(m_chart_id, PFX + "e_applyMA", m_subwin,
                              COL_LABEL_X, CFG_APPLY_Y,
                              COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 24))
      return false;
   m_e_btnApplyMA.Text("APLICAR MA CROSS");
   m_e_btnApplyMA.FontSize(9);
   m_e_btnApplyMA.ColorBackground(C'30,120,70');
   m_e_btnApplyMA.Color(clrWhite);
   if(!Add(m_e_btnApplyMA))
      return false;

   if(!m_e_statusMA.Create(m_chart_id, PFX + "e_stMA", m_subwin,
                            COL_LABEL_X, CFG_APPLY_Y + 28,
                            COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 28 + PANEL_GAP_Y))
      return false;
   m_e_statusMA.Text("");
   m_e_statusMA.FontSize(8);
   m_e_statusMA.Color(CLR_NEUTRAL);
   if(!Add(m_e_statusMA))
      return false;

// ── Preenche campos com valores iniciais ──
   {
    ENUM_MA_METHOD  fm = (m_maCross != NULL) ? m_maCross.GetFastMethod()    : inp_FastMethod;
    ENUM_MA_METHOD  sm = (m_maCross != NULL) ? m_maCross.GetSlowMethod()    : inp_SlowMethod;
    ENUM_TIMEFRAMES ft = (m_maCross != NULL) ? m_maCross.GetFastTimeframe() : inp_FastTF;
    ENUM_TIMEFRAMES st = (m_maCross != NULL) ? m_maCross.GetSlowTimeframe() : inp_SlowTF;
    int             fp = (m_maCross != NULL) ? m_maCross.GetFastPeriod()    : inp_FastPeriod;
    int             sp = (m_maCross != NULL) ? m_maCross.GetSlowPeriod()    : inp_SlowPeriod;
    ENUM_ENTRY_MODE en = (m_maCross != NULL) ? m_maCross.GetEntryMode()     : inp_EntryMode;
    ENUM_EXIT_MODE  ex = (m_maCross != NULL) ? m_maCross.GetExitMode()      : inp_ExitMode;

    m_cur_maFastMethod = fm;  m_cur_maSlowMethod = sm;
    m_cur_maFastTF     = ft;  m_cur_maSlowTF     = st;
    m_cur_maEntry      = en;  m_cur_maExit       = ex;

    m_ce_iFastP.Text(IntegerToString(fp));
    m_ce_iSlowP.Text(IntegerToString(sp));
    SetRadioSelection(m_ce_bFastM, 4, MAMethodToIndex(fm));
    SetRadioSelection(m_ce_bSlowM, 4, MAMethodToIndex(sm));
    m_ce_bFastTF.Text(TFName(ft));  m_ce_bFastTF.ColorBackground(C'50,80,140'); m_ce_bFastTF.Color(clrWhite);
    m_ce_bSlowTF.Text(TFName(st));  m_ce_bSlowTF.ColorBackground(C'50,80,140'); m_ce_bSlowTF.Color(clrWhite);
    SetRadioSelection(m_ce_bEntry, 2, (en == ENTRY_NEXT_CANDLE) ? 0 : 1);
    SetRadioSelection(m_ce_bExit,  3, (ex == EXIT_FCO) ? 0 : (ex == EXIT_VM) ? 1 : 2);
   }
   m_e_statusMAExpiry = 0;

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: RSI STRATEGY
// ════════════════════════════════════════════════════════════
   y = ESTRAT_CONTENT_Y;

   if(!CreateHdr(m_e_hdr3, "e_h3", "RSI STRATEGY", y)) return false;
   y += PANEL_GAP_Y + 2;

// ── Toggle ON/OFF RSI ──
   {
    bool rsiOn = (m_rsiStrategy != NULL) ? m_rsiStrategy.GetEnabled() : true;
    if(!m_e_btnRSIToggle.Create(m_chart_id, PFX + "e_bRSOn", m_subwin,
                                COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 20))
       return false;
    m_e_btnRSIToggle.FontSize(8);
    if(!Add(m_e_btnRSIToggle)) return false;
    ApplyToggleStyle(m_e_btnRSIToggle, rsiOn);
   }
   y += 24;

   if(!CreateLV(m_e_lRSIStatus, m_e_eRSIStatus, "e_lRS", "e_eRS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRSICurr, m_e_eRSICurr, "e_lRC", "e_eRC", "RSI Atual:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRSIMode, m_e_eRSIMode, "e_lRM", "e_eRM", "Modo:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRSILevels, m_e_eRSILevels, "e_lRL", "e_eRL", "Niveis:", y)) return false;
   y += PANEL_GAP_Y + 2;

// ── CONFIGURAÇÕES EDITÁVEIS RSI ──
   y += PANEL_GAP_SECTION;
   if(!CreateHdr(m_re_hdr1, "re_h1", "CONFIGURACOES", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(!CreateLI(m_re_lPeriod, m_re_iPeriod, "re_lPD", "re_iPD", "Periodo:", y)) return false;
   y += PANEL_GAP_Y;

   if(!CreateLB(m_re_lTF, m_re_bTF, "re_lTF", "re_bTF", "Time Frame:", y)) return false;
   y += PANEL_GAP_Y + 2;

   y += PANEL_GAP_SECTION;
   {
    string modeTexts[] = {"CROSS.", "ZONE", "MEDIO"};
    if(!CreateRadioGroup(m_re_lMode, m_re_bMode, "re_lMD", "re_bMD", "Modo:", modeTexts, 3, y))
       return false;
   }
   y += PANEL_GAP_Y + 2;

   y += PANEL_GAP_SECTION;
   if(!CreateLI(m_re_lOversold,   m_re_iOversold,   "re_lOS", "re_iOS", "Oversold:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLI(m_re_lOverbought, m_re_iOverbought, "re_lOB", "re_iOB", "Overbought:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLI(m_re_lMiddle, m_re_iMiddle, "re_lMI", "re_iMI", "Medio:", y)) return false;
   y += PANEL_GAP_Y + 8;

// ── BOTÃO APLICAR RSI (posição fixa) ──
   if(!m_e_btnApplyRSI.Create(m_chart_id, PFX + "e_applyRSI", m_subwin,
                               COL_LABEL_X, CFG_APPLY_Y,
                               COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 24))
      return false;
   m_e_btnApplyRSI.Text("APLICAR RSI");
   m_e_btnApplyRSI.FontSize(9);
   m_e_btnApplyRSI.ColorBackground(C'30,120,70');
   m_e_btnApplyRSI.Color(clrWhite);
   if(!Add(m_e_btnApplyRSI))
      return false;

   if(!m_e_statusRSI.Create(m_chart_id, PFX + "e_stRSI", m_subwin,
                             COL_LABEL_X, CFG_APPLY_Y + 28,
                             COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 28 + PANEL_GAP_Y))
      return false;
   m_e_statusRSI.Text("");
   m_e_statusRSI.FontSize(8);
   m_e_statusRSI.Color(CLR_NEUTRAL);
   if(!Add(m_e_statusRSI))
      return false;

// ── Preenche campos RSI com valores iniciais ──
   {
    int                  rp  = (m_rsiStrategy != NULL) ? m_rsiStrategy.GetPeriod()      : 14;
    ENUM_TIMEFRAMES      rt  = (m_rsiStrategy != NULL) ? m_rsiStrategy.GetTimeframe()   : PERIOD_CURRENT;
    ENUM_RSI_SIGNAL_MODE rm  = (m_rsiStrategy != NULL) ? m_rsiStrategy.GetSignalMode()  : RSI_MODE_CROSSOVER;
    double               ros = (m_rsiStrategy != NULL) ? m_rsiStrategy.GetOversold()    : 30.0;
    double               rob = (m_rsiStrategy != NULL) ? m_rsiStrategy.GetOverbought()  : 70.0;
    double               rmi = (m_rsiStrategy != NULL) ? m_rsiStrategy.GetMiddle()      : 50.0;

    m_cur_rsiTF   = rt;
    m_cur_rsiMode = rm;

    m_re_iPeriod.Text(IntegerToString(rp));
    m_re_iOversold.Text(DoubleToString(ros, 1));
    m_re_iOverbought.Text(DoubleToString(rob, 1));
    m_re_iMiddle.Text(DoubleToString(rmi, 1));
    m_re_bTF.Text(TFName(rt));
    m_re_bTF.ColorBackground(C'50,80,140'); m_re_bTF.Color(clrWhite);
    SetRadioSelection(m_re_bMode, 3, RSIModeToIndex(rm));
   }
   m_e_statusRSIExpiry = 0;

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
         if(vis)
           {
            m_e_hdr2.Show(); m_e_btnMAToggle.Show();
            m_e_lMAStatus.Show(); m_e_eMAStatus.Show();
            m_e_lMAFast.Show(); m_e_eMAFast.Show(); m_e_lMASlow.Show(); m_e_eMASlow.Show();
            m_e_lMACross.Show(); m_e_eMACross.Show(); m_e_lMACandles.Show(); m_e_eMACandles.Show();
            m_ce_hdr1.Show();
            m_ce_lFastP.Show(); m_ce_iFastP.Show();
            m_ce_lFastM.Show(); for(int i=0;i<4;i++) m_ce_bFastM[i].Show();
            m_ce_lFastTF.Show(); m_ce_bFastTF.Show();
            m_ce_lSlowP.Show(); m_ce_iSlowP.Show();
            m_ce_lSlowM.Show(); for(int i=0;i<4;i++) m_ce_bSlowM[i].Show();
            m_ce_lSlowTF.Show(); m_ce_bSlowTF.Show();
            m_ce_hdr2.Show();
            m_ce_lEntry.Show(); for(int i=0;i<2;i++) m_ce_bEntry[i].Show();
            m_ce_lExit.Show();  for(int i=0;i<3;i++) m_ce_bExit[i].Show();
            m_e_lLeg1.Show(); m_e_lLeg2.Show(); m_e_lLeg3.Show();
            m_e_btnApplyMA.Show(); m_e_statusMA.Show();
           }
         else
           {
            m_e_hdr2.Hide(); m_e_btnMAToggle.Hide();
            m_e_lMAStatus.Hide(); m_e_eMAStatus.Hide();
            m_e_lMAFast.Hide(); m_e_eMAFast.Hide(); m_e_lMASlow.Hide(); m_e_eMASlow.Hide();
            m_e_lMACross.Hide(); m_e_eMACross.Hide(); m_e_lMACandles.Hide(); m_e_eMACandles.Hide();
            m_ce_hdr1.Hide();
            m_ce_lFastP.Hide(); m_ce_iFastP.Hide();
            m_ce_lFastM.Hide(); for(int i=0;i<4;i++) m_ce_bFastM[i].Hide();
            m_ce_lFastTF.Hide(); m_ce_bFastTF.Hide();
            m_ce_lSlowP.Hide(); m_ce_iSlowP.Hide();
            m_ce_lSlowM.Hide(); for(int i=0;i<4;i++) m_ce_bSlowM[i].Hide();
            m_ce_lSlowTF.Hide(); m_ce_bSlowTF.Hide();
            m_ce_hdr2.Hide();
            m_ce_lEntry.Hide(); for(int i=0;i<2;i++) m_ce_bEntry[i].Hide();
            m_ce_lExit.Hide();  for(int i=0;i<3;i++) m_ce_bExit[i].Hide();
            m_e_lLeg1.Hide(); m_e_lLeg2.Hide(); m_e_lLeg3.Hide();
            m_e_btnApplyMA.Hide(); m_e_statusMA.Hide();
           }
         break;
      case ESTRAT_RSI:
         if(vis)
           {
            m_e_hdr3.Show(); m_e_btnRSIToggle.Show();
            m_e_lRSIStatus.Show(); m_e_eRSIStatus.Show();
            m_e_lRSICurr.Show(); m_e_eRSICurr.Show(); m_e_lRSIMode.Show(); m_e_eRSIMode.Show();
            m_e_lRSILevels.Show(); m_e_eRSILevels.Show();
            m_re_hdr1.Show();
            m_re_lPeriod.Show(); m_re_iPeriod.Show();
            m_re_lTF.Show(); m_re_bTF.Show();
            m_re_lMode.Show(); for(int i=0;i<3;i++) m_re_bMode[i].Show();
            m_re_lOversold.Show(); m_re_iOversold.Show();
            m_re_lOverbought.Show(); m_re_iOverbought.Show();
            m_re_lMiddle.Show(); m_re_iMiddle.Show();
            m_e_btnApplyRSI.Show(); m_e_statusRSI.Show();
           }
         else
           {
            m_e_hdr3.Hide(); m_e_btnRSIToggle.Hide();
            m_e_lRSIStatus.Hide(); m_e_eRSIStatus.Hide();
            m_e_lRSICurr.Hide(); m_e_eRSICurr.Hide(); m_e_lRSIMode.Hide(); m_e_eRSIMode.Hide();
            m_e_lRSILevels.Hide(); m_e_eRSILevels.Hide();
            m_re_hdr1.Hide();
            m_re_lPeriod.Hide(); m_re_iPeriod.Hide();
            m_re_lTF.Hide(); m_re_bTF.Hide();
            m_re_lMode.Hide(); for(int i=0;i<3;i++) m_re_bMode[i].Hide();
            m_re_lOversold.Hide(); m_re_iOversold.Hide();
            m_re_lOverbought.Hide(); m_re_iOverbought.Hide();
            m_re_lMiddle.Hide(); m_re_iMiddle.Hide();
            m_e_btnApplyRSI.Hide(); m_e_statusRSI.Hide();
           }
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
//| Helpers — TF cycle, TF name, MA method mapping                    |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES CEPBotPanel::CycleTF(ENUM_TIMEFRAMES tf)
  {
   static const ENUM_TIMEFRAMES tfs[] =
     {PERIOD_CURRENT, PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30,
      PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1, PERIOD_MN1};
   for(int i = 0; i < 10; i++)
      if(tfs[i] == tf)
         return tfs[(i + 1) % 10];
   return PERIOD_CURRENT;
  }

string CEPBotPanel::TFName(ENUM_TIMEFRAMES tf)
  {
   switch(tf)
     {
      case PERIOD_CURRENT: return "ATUAL";
      case PERIOD_M1:      return "M1";
      case PERIOD_M5:      return "M5";
      case PERIOD_M15:     return "M15";
      case PERIOD_M30:     return "M30";
      case PERIOD_H1:      return "H1";
      case PERIOD_H4:      return "H4";
      case PERIOD_D1:      return "D1";
      case PERIOD_W1:      return "W1";
      case PERIOD_MN1:     return "MN1";
      default:             return "??";
     }
  }

int CEPBotPanel::MAMethodToIndex(ENUM_MA_METHOD m)
  { return (m == MODE_SMA) ? 0 : (m == MODE_EMA) ? 1 : (m == MODE_SMMA) ? 2 : 3; }

ENUM_MA_METHOD CEPBotPanel::IndexToMAMethod(int i)
  { return (i == 0) ? MODE_SMA : (i == 1) ? MODE_EMA : (i == 2) ? MODE_SMMA : MODE_LWMA; }

int CEPBotPanel::RSIModeToIndex(ENUM_RSI_SIGNAL_MODE m)
  { return (m == RSI_MODE_CROSSOVER) ? 0 : (m == RSI_MODE_ZONE) ? 1 : 2; }

ENUM_RSI_SIGNAL_MODE CEPBotPanel::IndexToRSIMode(int i)
  { return (i == 0) ? RSI_MODE_CROSSOVER : (i == 1) ? RSI_MODE_ZONE : RSI_MODE_MIDDLE; }

//+------------------------------------------------------------------+
//| MA Cross — handlers de clique dos campos editáveis                |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickMAFastMethod(int i)
  { m_cur_maFastMethod = IndexToMAMethod(i); SetRadioSelection(m_ce_bFastM, 4, i); }

void CEPBotPanel::OnClickMASlowMethod(int i)
  { m_cur_maSlowMethod = IndexToMAMethod(i); SetRadioSelection(m_ce_bSlowM, 4, i); }

void CEPBotPanel::OnClickMAFastTF(void)
  {
   m_ce_bFastTF.Pressed(false);
   m_cur_maFastTF = CycleTF(m_cur_maFastTF);
   m_ce_bFastTF.Text(TFName(m_cur_maFastTF));
  }

void CEPBotPanel::OnClickMASlowTF(void)
  {
   m_ce_bSlowTF.Pressed(false);
   m_cur_maSlowTF = CycleTF(m_cur_maSlowTF);
   m_ce_bSlowTF.Text(TFName(m_cur_maSlowTF));
  }

void CEPBotPanel::OnClickMAEntry(int i)
  { m_cur_maEntry = (i == 0) ? ENTRY_NEXT_CANDLE : ENTRY_2ND_CANDLE; SetRadioSelection(m_ce_bEntry, 2, i); }

void CEPBotPanel::OnClickMAExit(int i)
  { m_cur_maExit = (i == 0) ? EXIT_FCO : (i == 1) ? EXIT_VM : EXIT_TP_SL; SetRadioSelection(m_ce_bExit, 3, i); }

//+------------------------------------------------------------------+
//| OnClickApplyMA — aplica configurações MA Cross                    |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickApplyMA(void)
  {
   if(m_maCross == NULL) return;

   int errors = 0;

   int fastP = (int)StringToInteger(m_ce_iFastP.Text());
   int slowP = (int)StringToInteger(m_ce_iSlowP.Text());

   if(fastP > 0 && slowP > 0 && fastP < slowP)
     {
      if(!m_maCross.SetMAParams(fastP, slowP,
                                m_cur_maFastMethod, m_cur_maSlowMethod,
                                m_cur_maFastTF, m_cur_maSlowTF))
         errors++;
     }
   else
      errors++;

   // Hot-reload: entry e exit mode (sem reiniciar indicadores)
   m_maCross.SetEntryMode(m_cur_maEntry);
   m_maCross.SetExitMode(m_cur_maExit);

   if(errors == 0)
     {
      m_e_statusMA.Text("Aplicado com sucesso!");
      m_e_statusMA.Color(CLR_POSITIVE);
     }
   else
     {
      m_e_statusMA.Text("Periodo invalido (fast < slow > 0)");
      m_e_statusMA.Color(CLR_NEGATIVE);
     }
   m_e_statusMAExpiry = GetTickCount() + 10000;
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| ApplyToggleStyle — aplica estilo verde/vermelho ao botão toggle   |
//+------------------------------------------------------------------+
void CEPBotPanel::ApplyToggleStyle(CButton &btn, bool enabled)
  {
   btn.Text(enabled ? "LIGADO" : "DESLIGADO");
   btn.ColorBackground(enabled ? C'30,120,70' : C'160,40,40');
   btn.Color(clrWhite);
  }

//+------------------------------------------------------------------+
//| Toggles ON/OFF das estratégias                                    |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickMAToggle(void)
  {
   if(m_maCross == NULL) return;
   bool newState = !m_maCross.GetEnabled();
   m_maCross.SetEnabled(newState);
   ApplyToggleStyle(m_e_btnMAToggle, newState);
  }

void CEPBotPanel::OnClickRSIToggle(void)
  {
   if(m_rsiStrategy == NULL) return;
   bool newState = !m_rsiStrategy.GetEnabled();
   m_rsiStrategy.SetEnabled(newState);
   ApplyToggleStyle(m_e_btnRSIToggle, newState);
  }

//+------------------------------------------------------------------+
//| RSI — handlers de clique dos campos editáveis                     |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickRSIMode(int i)
  { m_cur_rsiMode = IndexToRSIMode(i); SetRadioSelection(m_re_bMode, 3, i); }

void CEPBotPanel::OnClickRSITF(void)
  {
   m_re_bTF.Pressed(false);
   m_cur_rsiTF = CycleTF(m_cur_rsiTF);
   m_re_bTF.Text(TFName(m_cur_rsiTF));
  }

//+------------------------------------------------------------------+
//| OnClickApplyRSI — aplica configurações RSI                        |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickApplyRSI(void)
  {
   if(m_rsiStrategy == NULL) return;

   int errors = 0;

   // Cold reload: Period
   int period = (int)StringToInteger(m_re_iPeriod.Text());
   if(period >= 2)
     {
      if(!m_rsiStrategy.SetPeriod(period)) errors++;
     }
   else
      errors++;

   // Cold reload: Timeframe
   m_rsiStrategy.SetTimeframe(m_cur_rsiTF);

   // Hot reload: Signal Mode
   m_rsiStrategy.SetSignalMode(m_cur_rsiMode);

   // Hot reload: Níveis
   double os = StringToDouble(m_re_iOversold.Text());
   double ob = StringToDouble(m_re_iOverbought.Text());
   double mi = StringToDouble(m_re_iMiddle.Text());

   if(os > 0 && os < 100) m_rsiStrategy.SetOversold(os);   else errors++;
   if(ob > 0 && ob < 100) m_rsiStrategy.SetOverbought(ob); else errors++;
   if(mi > 0 && mi < 100) m_rsiStrategy.SetMiddle(mi);     else errors++;

   if(errors == 0)
     {
      m_e_statusRSI.Text("Aplicado com sucesso!");
      m_e_statusRSI.Color(CLR_POSITIVE);
     }
   else
     {
      m_e_statusRSI.Text("Valores invalidos (Period>=2, Niveis 0-100)");
      m_e_statusRSI.Color(CLR_NEGATIVE);
     }
   m_e_statusRSIExpiry = GetTickCount() + 10000;
   ChartRedraw();
  }

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

        }
      else
        {
         SetEV(m_e_eMAStatus, "Inativo", CLR_NEUTRAL);
         SetEV(m_e_eMAFast, "--", CLR_NEUTRAL);
         SetEV(m_e_eMASlow, "--", CLR_NEUTRAL);
         SetEV(m_e_eMACross, "--", CLR_NEUTRAL);
         SetEV(m_e_eMACandles, "--", CLR_NEUTRAL);
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
