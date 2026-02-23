//+------------------------------------------------------------------+
//|                                            PanelTabConfig.mqh    |
//|                                         Copyright 2026, EP Filho |
//|   Panel Tab: CONFIG — Sub-páginas + Hot Reload (APLICAR)          |
//|                     Versão 1.12 - Claude Parte 023 (Claude Code) |
//+------------------------------------------------------------------+
// Implementações de CEPBotPanel para a aba CONFIG.
// Incluído por Panel.mqh — NÃO incluir diretamente.
//
// Sub-páginas: RISCO | BLOQUEIOS | OUTROS
// Campos CEdit editáveis + botões de toggle/cycle
// Botão APLICAR chama setters hot-reload nos módulos

//+------------------------------------------------------------------+
//| Helper: CreateLI — Label + CEdit (input editável)                 |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateLI(CLabel &lbl, CEdit &inp,
                           string ln, string en, string lt, int y)
  {
   if(!lbl.Create(m_chart_id, PFX + ln, m_subwin,
                  COL_LABEL_X, y, COL_VALUE_X - 5, y + PANEL_GAP_Y))
      return false;
   lbl.Text(lt);
   lbl.Color(CLR_LABEL);
   lbl.FontSize(8);
   if(!Add(lbl))
      return false;

   if(!inp.Create(m_chart_id, PFX + en, m_subwin,
                  COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + PANEL_GAP_Y))
      return false;
   inp.Text("");
   inp.FontSize(8);
   if(!Add(inp))
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Helper: CreateLB — Label + CButton (toggle/cycle)                 |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateLB(CLabel &lbl, CButton &btn,
                           string ln, string bn, string lt, int y)
  {
   if(!lbl.Create(m_chart_id, PFX + ln, m_subwin,
                  COL_LABEL_X, y, COL_VALUE_X - 5, y + PANEL_GAP_Y))
      return false;
   lbl.Text(lt);
   lbl.Color(CLR_LABEL);
   lbl.FontSize(8);
   if(!Add(lbl))
      return false;

   if(!btn.Create(m_chart_id, PFX + bn, m_subwin,
                  COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + PANEL_GAP_Y + 2))
      return false;
   btn.FontSize(8);
   if(!Add(btn))
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| ABA 4: CONFIG — Criar todos os controles (3 sub-páginas)          |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabConfig(void)
  {
// ── Determinar features ativas (baseado nos inp_* definidos no Init) ──
   m_cfg_hasTP         = (inp_TPType != TP_NONE);
   m_cfg_hasTrailing   = (inp_TrailingActivation != TRAILING_NEVER);
   m_cfg_hasBE         = (inp_BEActivationMode != BE_NEVER);
   m_cfg_hasDailyLimits = inp_EnableDailyLimits;
   m_cfg_hasStreak     = inp_EnableStreakControl;
   m_cfg_hasDrawdown   = inp_EnableDrawdown;
   m_cfg_hasATR        = (inp_SLType == SL_ATR || inp_TPType == TP_ATR ||
                           inp_TrailingType == TRAILING_ATR || inp_BEType == BE_ATR);
   m_cfg_hasRange      = (inp_SLType == SL_RANGE);

// ── Botões de sub-página ──
   int sw = (PANEL_WIDTH - 40) / CFG_PAGE_COUNT;
   int sy = CONTENT_TOP;

   if(!m_cfg_btnRisco.Create(m_chart_id, PFX + "cfg_bR", m_subwin,
                             5, sy, 5 + sw, sy + TAB_BTN_H))
      return false;
   m_cfg_btnRisco.Text("RISCO");
   m_cfg_btnRisco.FontSize(7);
   if(!Add(m_cfg_btnRisco))
      return false;

   if(!m_cfg_btnBloq.Create(m_chart_id, PFX + "cfg_bB", m_subwin,
                            5 + (sw + 2), sy, 5 + sw * 2 + 2, sy + TAB_BTN_H))
      return false;
   m_cfg_btnBloq.Text("BLOQUEIOS");
   m_cfg_btnBloq.FontSize(7);
   if(!Add(m_cfg_btnBloq))
      return false;

   if(!m_cfg_btnOutros.Create(m_chart_id, PFX + "cfg_bO", m_subwin,
                              5 + (sw + 2) * 2, sy, 5 + sw * 3 + 4, sy + TAB_BTN_H))
      return false;
   m_cfg_btnOutros.Text("OUTROS");
   m_cfg_btnOutros.FontSize(7);
   if(!Add(m_cfg_btnOutros))
      return false;

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: RISCO
// ════════════════════════════════════════════════════════════
   int y = CFG_CONTENT_Y;

   if(!CreateHdr(m_cr_hdr1, "cr_h1", "GESTAO DE RISCO", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(!CreateLI(m_cr_lLot, m_cr_iLot, "cr_lLt", "cr_iLt", "Lote:", y)) return false;
   y += PANEL_GAP_Y;

// SL Type cycle button + SL value field
   if(!CreateLB(m_cr_lSLT, m_cr_bSLT, "cr_lST", "cr_bST", "Tipo SL:", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(!CreateLI(m_cr_lSL, m_cr_iSL, "cr_lSL", "cr_iSL", "SL (Fixo pts):", y)) return false;
   y += PANEL_GAP_Y;

// TP Type cycle button + TP value field (SEMPRE criados)
   if(!CreateLB(m_cr_lTPT, m_cr_bTPT, "cr_lTT", "cr_bTT", "Tipo TP:", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(!CreateLI(m_cr_lTP, m_cr_iTP, "cr_lTP", "cr_iTP", "TP (Fixo pts):", y)) return false;
   y += PANEL_GAP_Y;

// Trailing — condicional (tipo não alterável ainda)
   if(m_cfg_hasTrailing)
     {
      string trSuffix = (inp_TrailingType == TRAILING_FIXED) ? " (pts):" : " (ATR x):";
      if(!CreateLI(m_cr_lTrlSt, m_cr_iTrlSt, "cr_lTS", "cr_iTS", "Trail Start" + trSuffix, y)) return false;
      y += PANEL_GAP_Y;
      if(!CreateLI(m_cr_lTrlSp, m_cr_iTrlSp, "cr_lTP2", "cr_iTP2", "Trail Step" + trSuffix, y)) return false;
      y += PANEL_GAP_Y;
     }

// BE — condicional (tipo não alterável ainda)
   if(m_cfg_hasBE)
     {
      string beSuffix = (inp_BEType == BE_FIXED) ? " (pts):" : " (ATR x):";
      if(!CreateLI(m_cr_lBEAct, m_cr_iBEAct, "cr_lBA", "cr_iBA", "BE Ativacao" + beSuffix, y)) return false;
      y += PANEL_GAP_Y;
      if(!CreateLI(m_cr_lBEOff, m_cr_iBEOff, "cr_lBO", "cr_iBO", "BE Offset" + beSuffix, y)) return false;
      y += PANEL_GAP_Y;
     }

// Partial TP — sempre (toggle + campos)
   y += PANEL_GAP_SECTION;
   if(!CreateHdr(m_cr_hdr2, "cr_h2", "PARTIAL TP", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLB(m_cr_lPTP, m_cr_bPTP, "cr_lPT", "cr_bPT", "Partial TP:", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLI(m_cr_lTP1p, m_cr_iTP1p, "cr_l1p", "cr_i1p", "TP1 %:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLI(m_cr_lTP1d, m_cr_iTP1d, "cr_l1d", "cr_i1d", "TP1 Dist (pts):", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLI(m_cr_lTP2p, m_cr_iTP2p, "cr_l2p", "cr_i2p", "TP2 %:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLI(m_cr_lTP2d, m_cr_iTP2d, "cr_l2d", "cr_i2d", "TP2 Dist (pts):", y)) return false;
   y += PANEL_GAP_Y;

// Seção CONFIGURACAO (ATR, Range, Spread Compensation — SEMPRE criados)
   y += PANEL_GAP_SECTION;
   if(!CreateHdr(m_cr_hdr3, "cr_h3", "CONFIGURACAO", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(!CreateLI(m_cr_lATRp, m_cr_iATRp, "cr_lAP", "cr_iAP", "ATR Period:", y)) return false;
   y += PANEL_GAP_Y;

   if(!CreateLI(m_cr_lRngP, m_cr_iRngP, "cr_lRP", "cr_iRP", "Range Period:", y)) return false;
   y += PANEL_GAP_Y;

   if(!CreateLB(m_cr_lCSL, m_cr_bCSL, "cr_lCS", "cr_bCS", "Compen. Spread SL:", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(!CreateLB(m_cr_lCTP, m_cr_bCTP, "cr_lCT", "cr_bCT", "Compen. Spread TP:", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(m_cfg_hasTrailing)
     {
      if(!CreateLB(m_cr_lCTrl, m_cr_bCTrl, "cr_lCR", "cr_bCR", "Compen. Spread Trail:", y)) return false;
     }

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: BLOQUEIOS
// ════════════════════════════════════════════════════════════
   y = CFG_CONTENT_Y;

   if(!CreateHdr(m_cb_hdr1, "cb_h1", "BLOQUEIOS", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(!CreateLI(m_cb_lSpr, m_cb_iSpr, "cb_lSp", "cb_iSp", "Max Spread (0=sem):", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLB(m_cb_lDir, m_cb_bDir, "cb_lDr", "cb_bDr", "Direcao:", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(m_cfg_hasDailyLimits)
     {
      y += PANEL_GAP_SECTION;
      if(!CreateHdr(m_cb_hdr2, "cb_h2", "LIMITES DIARIOS", y)) return false;
      y += PANEL_GAP_Y + 2;
      if(!CreateLI(m_cb_lTrd, m_cb_iTrd, "cb_lTd", "cb_iTd", "Max Trades (0=sem):", y)) return false;
      y += PANEL_GAP_Y;
      if(!CreateLI(m_cb_lLoss, m_cb_iLoss, "cb_lLs", "cb_iLs", "Max Loss $:", y)) return false;
      y += PANEL_GAP_Y;
      if(!CreateLI(m_cb_lGain, m_cb_iGain, "cb_lGn", "cb_iGn", "Max Gain $:", y)) return false;
      y += PANEL_GAP_Y;
     }

   if(m_cfg_hasStreak)
     {
      y += PANEL_GAP_SECTION;
      if(!CreateHdr(m_cb_hdr3, "cb_h3", "SEQUENCIAS", y)) return false;
      y += PANEL_GAP_Y + 2;
      if(!CreateLI(m_cb_lLStr, m_cb_iLStr, "cb_lLS", "cb_iLS", "Max Loss Streak:", y)) return false;
      y += PANEL_GAP_Y;
      if(!CreateLI(m_cb_lWStr, m_cb_iWStr, "cb_lWS", "cb_iWS", "Max Win Streak:", y)) return false;
      y += PANEL_GAP_Y;
     }

   if(m_cfg_hasDrawdown)
     {
      string ddLabel = (inp_DrawdownType == DD_FINANCIAL) ? "Drawdown $:" : "Drawdown %:";
      if(!CreateLI(m_cb_lDD, m_cb_iDD, "cb_lDD", "cb_iDD", ddLabel, y)) return false;
     }

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: OUTROS
// ════════════════════════════════════════════════════════════
   y = CFG_CONTENT_Y;

   if(!CreateHdr(m_co_hdr1, "co_h1", "OUTROS", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(!CreateLI(m_co_lSlip, m_co_iSlip, "co_lSl", "co_iSl", "Slippage (pts):", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLB(m_co_lConfl, m_co_bConfl, "co_lCf", "co_bCf", "Conflito Sinais:", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLB(m_co_lDbg, m_co_bDbg, "co_lDb", "co_bDb", "Debug Logs:", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLI(m_co_lDbgCd, m_co_iDbgCd, "co_lDc", "co_iDc", "Debug Cooldown (s):", y)) return false;

// ════════════════════════════════════════════════════════════
// APLICAR + STATUS (fixos, visíveis em todas sub-páginas)
// ════════════════════════════════════════════════════════════
   if(!m_cfg_btnApply.Create(m_chart_id, PFX + "cfg_apply", m_subwin,
                             COL_LABEL_X, CFG_APPLY_Y,
                             COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 24))
      return false;
   m_cfg_btnApply.Text("APLICAR");
   m_cfg_btnApply.FontSize(9);
   m_cfg_btnApply.ColorBackground(C'30,120,70');
   m_cfg_btnApply.Color(clrWhite);
   if(!Add(m_cfg_btnApply))
      return false;

   if(!m_cfg_status.Create(m_chart_id, PFX + "cfg_st", m_subwin,
                           COL_LABEL_X, CFG_APPLY_Y + 28,
                           COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 28 + PANEL_GAP_Y))
      return false;
   m_cfg_status.Text("");
   m_cfg_status.FontSize(8);
   m_cfg_status.Color(CLR_NEUTRAL);
   if(!Add(m_cfg_status))
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| PopulateConfig — preenche campos com valores iniciais              |
//+------------------------------------------------------------------+
void CEPBotPanel::PopulateConfig(void)
  {
// ── Estado dos toggles/cycles ──
   m_cur_direction = inp_TradeDirection;
   m_cur_conflict  = inp_ConflictMode;
   m_cur_slType    = inp_SLType;
   m_cur_tpType    = inp_TPType;
   m_cur_debug     = inp_ShowDebugLogs;
   m_cur_partialTP = inp_UsePartialTP;

// ── Recalcular flags dinâmicos ──
   m_cfg_hasTP    = (m_cur_tpType != TP_NONE);
   m_cfg_hasATR   = (m_cur_slType == SL_ATR || m_cur_tpType == TP_ATR ||
                     inp_TrailingType == TRAILING_ATR || inp_BEType == BE_ATR);
   m_cfg_hasRange = (m_cur_slType == SL_RANGE);

// ── Risco ──
   m_cr_iLot.Text(DoubleToString(inp_LotSize, 2));

// SL Type button
   string slTypeTxt = (m_cur_slType == SL_FIXED) ? "FIXO" :
                      (m_cur_slType == SL_ATR)   ? "ATR"  : "RANGE";
   m_cr_bSLT.Text(slTypeTxt);
   m_cr_bSLT.ColorBackground(C'50,80,140');
   m_cr_bSLT.Color(clrWhite);

// SL value + label
   string slLabel = (m_cur_slType == SL_FIXED) ? "SL (Fixo pts):" :
                    (m_cur_slType == SL_ATR)   ? "SL (ATR x):" : "SL (Range x):";
   m_cr_lSL.Text(slLabel);
   if(m_cur_slType == SL_FIXED)
      m_cr_iSL.Text(IntegerToString(inp_FixedSL));
   else if(m_cur_slType == SL_ATR)
      m_cr_iSL.Text(DoubleToString(inp_SL_ATRMultiplier, 1));
   else
      m_cr_iSL.Text(DoubleToString(inp_RangeMultiplier, 1));

// TP Type button
   string tpTypeTxt = (m_cur_tpType == TP_NONE)  ? "NENHUM" :
                      (m_cur_tpType == TP_FIXED) ? "FIXO"   : "ATR";
   m_cr_bTPT.Text(tpTypeTxt);
   m_cr_bTPT.ColorBackground(C'50,80,140');
   m_cr_bTPT.Color(clrWhite);

// TP value + label
   if(m_cfg_hasTP)
     {
      string tpLabel = (m_cur_tpType == TP_FIXED) ? "TP (Fixo pts):" : "TP (ATR x):";
      m_cr_lTP.Text(tpLabel);
      if(m_cur_tpType == TP_FIXED)
         m_cr_iTP.Text(IntegerToString(inp_FixedTP));
      else
         m_cr_iTP.Text(DoubleToString(inp_TP_ATRMultiplier, 1));
     }

   if(m_cfg_hasTrailing)
     {
      if(inp_TrailingType == TRAILING_FIXED)
        {
         m_cr_iTrlSt.Text(IntegerToString(inp_TrailingStart));
         m_cr_iTrlSp.Text(IntegerToString(inp_TrailingStep));
        }
      else
        {
         m_cr_iTrlSt.Text(DoubleToString(inp_TrailingATRStart, 2));
         m_cr_iTrlSp.Text(DoubleToString(inp_TrailingATRStep, 2));
        }
     }

   if(m_cfg_hasBE)
     {
      if(inp_BEType == BE_FIXED)
        {
         m_cr_iBEAct.Text(IntegerToString(inp_BEActivation));
         m_cr_iBEOff.Text(IntegerToString(inp_BEOffset));
        }
      else
        {
         m_cr_iBEAct.Text(DoubleToString(inp_BE_ATRActivation, 2));
         m_cr_iBEOff.Text(DoubleToString(inp_BE_ATROffset, 2));
        }
     }

// Partial TP
   m_cr_bPTP.Text(m_cur_partialTP ? "ATIVO" : "DESAB.");
   m_cr_bPTP.ColorBackground(m_cur_partialTP ? C'30,120,70' : C'120,50,50');
   m_cr_bPTP.Color(clrWhite);
   m_cr_iTP1p.Text(DoubleToString(inp_PartialTP1_Percent, 1));
   m_cr_iTP1d.Text(IntegerToString(inp_PartialTP1_Distance));
   m_cr_iTP2p.Text(DoubleToString(inp_PartialTP2_Percent, 1));
   m_cr_iTP2d.Text(IntegerToString(inp_PartialTP2_Distance));

// Configuração (ATR, Range, Spread Comp — sempre populados)
   m_cr_iATRp.Text(IntegerToString(inp_ATRPeriod));
   m_cr_iRngP.Text(IntegerToString(inp_RangePeriod));

   m_cur_compSL = inp_SL_CompensateSpread;
   m_cr_bCSL.Text(m_cur_compSL ? "ON" : "OFF");
   m_cr_bCSL.ColorBackground(m_cur_compSL ? C'30,120,70' : C'120,50,50');
   m_cr_bCSL.Color(clrWhite);

   m_cur_compTP = inp_TP_CompensateSpread;
   m_cr_bCTP.Text(m_cur_compTP ? "ON" : "OFF");
   m_cr_bCTP.ColorBackground(m_cur_compTP ? C'30,120,70' : C'120,50,50');
   m_cr_bCTP.Color(clrWhite);

   if(m_cfg_hasTrailing)
     {
      m_cur_compTrail = inp_Trailing_CompensateSpread;
      m_cr_bCTrl.Text(m_cur_compTrail ? "ON" : "OFF");
      m_cr_bCTrl.ColorBackground(m_cur_compTrail ? C'30,120,70' : C'120,50,50');
      m_cr_bCTrl.Color(clrWhite);
     }

// ── Bloqueios ──
   m_cb_iSpr.Text(IntegerToString(inp_MaxSpread));

   string dirTxt = (m_cur_direction == DIRECTION_BOTH)     ? "AMBOS" :
                   (m_cur_direction == DIRECTION_BUY_ONLY) ? "APENAS BUY" : "APENAS SELL";
   m_cb_bDir.Text(dirTxt);
   m_cb_bDir.ColorBackground(C'50,80,140');
   m_cb_bDir.Color(clrWhite);

   if(m_cfg_hasDailyLimits)
     {
      m_cb_iTrd.Text(IntegerToString(inp_MaxDailyTrades));
      m_cb_iLoss.Text(DoubleToString(inp_MaxDailyLoss, 2));
      m_cb_iGain.Text(DoubleToString(inp_MaxDailyGain, 2));
     }

   if(m_cfg_hasStreak)
     {
      m_cb_iLStr.Text(IntegerToString(inp_MaxLossStreak));
      m_cb_iWStr.Text(IntegerToString(inp_MaxWinStreak));
     }

   if(m_cfg_hasDrawdown)
      m_cb_iDD.Text(DoubleToString(inp_DrawdownValue, 2));

// ── Outros ──
   m_co_iSlip.Text(IntegerToString(inp_Slippage));

   string conflTxt = (m_cur_conflict == CONFLICT_PRIORITY) ? "PRIORIDADE" : "CANCELAR";
   m_co_bConfl.Text(conflTxt);
   m_co_bConfl.ColorBackground(C'50,80,140');
   m_co_bConfl.Color(clrWhite);

   m_co_bDbg.Text(m_cur_debug ? "ON" : "OFF");
   m_co_bDbg.ColorBackground(m_cur_debug ? C'30,120,70' : C'120,50,50');
   m_co_bDbg.Color(clrWhite);

   m_co_iDbgCd.Text(IntegerToString(inp_DebugCooldownSec));

// ── Sub-página inicial ──
   ShowCfgPage(CFG_RISCO);
  }

//+------------------------------------------------------------------+
//| ShowCfgPage — alterna sub-página ativa do CONFIG                   |
//+------------------------------------------------------------------+
void CEPBotPanel::ShowCfgPage(ENUM_CONFIG_PAGE page)
  {
   m_cfgPage = page;
   SetCfgPageVis(CFG_RISCO, false);
   SetCfgPageVis(CFG_BLOQUEIOS, false);
   SetCfgPageVis(CFG_OUTROS, false);
   SetCfgPageVis(page, true);
   UpdateCfgBtnStyles();
  }

//+------------------------------------------------------------------+
//| SetCfgPageVis — show/hide controles de uma sub-página              |
//+------------------------------------------------------------------+
void CEPBotPanel::SetCfgPageVis(ENUM_CONFIG_PAGE page, bool vis)
  {
   switch(page)
     {
      case CFG_RISCO:
        {
         if(vis)
           {
            m_cr_hdr1.Show(); m_cr_lLot.Show(); m_cr_iLot.Show();
            m_cr_lSLT.Show(); m_cr_bSLT.Show();
            m_cr_lSL.Show(); m_cr_iSL.Show();
            m_cr_lTPT.Show(); m_cr_bTPT.Show();
            if(m_cfg_hasTP) { m_cr_lTP.Show(); m_cr_iTP.Show(); }
            else            { m_cr_lTP.Hide(); m_cr_iTP.Hide(); }
            if(m_cfg_hasTrailing) { m_cr_lTrlSt.Show(); m_cr_iTrlSt.Show();
                                    m_cr_lTrlSp.Show(); m_cr_iTrlSp.Show(); }
            if(m_cfg_hasBE) { m_cr_lBEAct.Show(); m_cr_iBEAct.Show();
                              m_cr_lBEOff.Show(); m_cr_iBEOff.Show(); }
            m_cr_hdr2.Show(); m_cr_lPTP.Show(); m_cr_bPTP.Show();
            m_cr_lTP1p.Show(); m_cr_iTP1p.Show(); m_cr_lTP1d.Show(); m_cr_iTP1d.Show();
            m_cr_lTP2p.Show(); m_cr_iTP2p.Show(); m_cr_lTP2d.Show(); m_cr_iTP2d.Show();
            m_cr_hdr3.Show(); m_cr_lCSL.Show(); m_cr_bCSL.Show();
            if(m_cfg_hasATR)    { m_cr_lATRp.Show(); m_cr_iATRp.Show(); }
            else                { m_cr_lATRp.Hide(); m_cr_iATRp.Hide(); }
            if(m_cfg_hasRange)  { m_cr_lRngP.Show(); m_cr_iRngP.Show(); }
            else                { m_cr_lRngP.Hide(); m_cr_iRngP.Hide(); }
            if(m_cfg_hasTP)     { m_cr_lCTP.Show(); m_cr_bCTP.Show(); }
            else                { m_cr_lCTP.Hide(); m_cr_bCTP.Hide(); }
            if(m_cfg_hasTrailing) { m_cr_lCTrl.Show(); m_cr_bCTrl.Show(); }
           }
         else
           {
            m_cr_hdr1.Hide(); m_cr_lLot.Hide(); m_cr_iLot.Hide();
            m_cr_lSLT.Hide(); m_cr_bSLT.Hide();
            m_cr_lSL.Hide(); m_cr_iSL.Hide();
            m_cr_lTPT.Hide(); m_cr_bTPT.Hide();
            m_cr_lTP.Hide(); m_cr_iTP.Hide();
            if(m_cfg_hasTrailing) { m_cr_lTrlSt.Hide(); m_cr_iTrlSt.Hide();
                                    m_cr_lTrlSp.Hide(); m_cr_iTrlSp.Hide(); }
            if(m_cfg_hasBE) { m_cr_lBEAct.Hide(); m_cr_iBEAct.Hide();
                              m_cr_lBEOff.Hide(); m_cr_iBEOff.Hide(); }
            m_cr_hdr2.Hide(); m_cr_lPTP.Hide(); m_cr_bPTP.Hide();
            m_cr_lTP1p.Hide(); m_cr_iTP1p.Hide(); m_cr_lTP1d.Hide(); m_cr_iTP1d.Hide();
            m_cr_lTP2p.Hide(); m_cr_iTP2p.Hide(); m_cr_lTP2d.Hide(); m_cr_iTP2d.Hide();
            m_cr_hdr3.Hide(); m_cr_lCSL.Hide(); m_cr_bCSL.Hide();
            m_cr_lATRp.Hide(); m_cr_iATRp.Hide();
            m_cr_lRngP.Hide(); m_cr_iRngP.Hide();
            m_cr_lCTP.Hide(); m_cr_bCTP.Hide();
            if(m_cfg_hasTrailing) { m_cr_lCTrl.Hide(); m_cr_bCTrl.Hide(); }
           }
         break;
        }

      case CFG_BLOQUEIOS:
        {
         if(vis)
           {
            m_cb_hdr1.Show(); m_cb_lSpr.Show(); m_cb_iSpr.Show();
            m_cb_lDir.Show(); m_cb_bDir.Show();
            if(m_cfg_hasDailyLimits) { m_cb_hdr2.Show(); m_cb_lTrd.Show(); m_cb_iTrd.Show();
                                       m_cb_lLoss.Show(); m_cb_iLoss.Show();
                                       m_cb_lGain.Show(); m_cb_iGain.Show(); }
            if(m_cfg_hasStreak)      { m_cb_hdr3.Show(); m_cb_lLStr.Show(); m_cb_iLStr.Show();
                                       m_cb_lWStr.Show(); m_cb_iWStr.Show(); }
            if(m_cfg_hasDrawdown)    { m_cb_lDD.Show(); m_cb_iDD.Show(); }
           }
         else
           {
            m_cb_hdr1.Hide(); m_cb_lSpr.Hide(); m_cb_iSpr.Hide();
            m_cb_lDir.Hide(); m_cb_bDir.Hide();
            if(m_cfg_hasDailyLimits) { m_cb_hdr2.Hide(); m_cb_lTrd.Hide(); m_cb_iTrd.Hide();
                                       m_cb_lLoss.Hide(); m_cb_iLoss.Hide();
                                       m_cb_lGain.Hide(); m_cb_iGain.Hide(); }
            if(m_cfg_hasStreak)      { m_cb_hdr3.Hide(); m_cb_lLStr.Hide(); m_cb_iLStr.Hide();
                                       m_cb_lWStr.Hide(); m_cb_iWStr.Hide(); }
            if(m_cfg_hasDrawdown)    { m_cb_lDD.Hide(); m_cb_iDD.Hide(); }
           }
         break;
        }

      case CFG_OUTROS:
        {
         if(vis)
           {
            m_co_hdr1.Show(); m_co_lSlip.Show(); m_co_iSlip.Show();
            m_co_lConfl.Show(); m_co_bConfl.Show();
            m_co_lDbg.Show(); m_co_bDbg.Show();
            m_co_lDbgCd.Show(); m_co_iDbgCd.Show();
           }
         else
           {
            m_co_hdr1.Hide(); m_co_lSlip.Hide(); m_co_iSlip.Hide();
            m_co_lConfl.Hide(); m_co_bConfl.Hide();
            m_co_lDbg.Hide(); m_co_bDbg.Hide();
            m_co_lDbgCd.Hide(); m_co_iDbgCd.Hide();
           }
         break;
        }
     }
  }

//+------------------------------------------------------------------+
//| UpdateCfgBtnStyles — destaque no botão da sub-página ativa         |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateCfgBtnStyles(void)
  {
   m_cfg_btnRisco.ColorBackground((m_cfgPage == CFG_RISCO)     ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
   m_cfg_btnBloq.ColorBackground((m_cfgPage == CFG_BLOQUEIOS)  ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
   m_cfg_btnOutros.ColorBackground((m_cfgPage == CFG_OUTROS)   ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);

   m_cfg_btnRisco.Color((m_cfgPage == CFG_RISCO)     ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_cfg_btnBloq.Color((m_cfgPage == CFG_BLOQUEIOS)  ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_cfg_btnOutros.Color((m_cfgPage == CFG_OUTROS)   ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
  }

//+------------------------------------------------------------------+
//| Handlers de clique das sub-páginas                                 |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickCfgRisco(void)   { ShowCfgPage(CFG_RISCO);     }
void CEPBotPanel::OnClickCfgBloq(void)    { ShowCfgPage(CFG_BLOQUEIOS); }
void CEPBotPanel::OnClickCfgOutros(void)  { ShowCfgPage(CFG_OUTROS);    }

//+------------------------------------------------------------------+
//| Toggle/Cycle handlers                                              |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickDirection(void)
  {
   if(m_cur_direction == DIRECTION_BOTH)
      m_cur_direction = DIRECTION_BUY_ONLY;
   else if(m_cur_direction == DIRECTION_BUY_ONLY)
      m_cur_direction = DIRECTION_SELL_ONLY;
   else
      m_cur_direction = DIRECTION_BOTH;

   string txt = (m_cur_direction == DIRECTION_BOTH)     ? "AMBOS" :
                (m_cur_direction == DIRECTION_BUY_ONLY) ? "APENAS BUY" : "APENAS SELL";
   m_cb_bDir.Text(txt);
   ChartRedraw();
  }

void CEPBotPanel::OnClickConflict(void)
  {
   m_cur_conflict = (m_cur_conflict == CONFLICT_PRIORITY) ? CONFLICT_CANCEL : CONFLICT_PRIORITY;
   m_co_bConfl.Text((m_cur_conflict == CONFLICT_PRIORITY) ? "PRIORIDADE" : "CANCELAR");
   ChartRedraw();
  }

void CEPBotPanel::OnClickDebug(void)
  {
   m_cur_debug = !m_cur_debug;
   m_co_bDbg.Text(m_cur_debug ? "ON" : "OFF");
   m_co_bDbg.ColorBackground(m_cur_debug ? C'30,120,70' : C'120,50,50');
   ChartRedraw();
  }

void CEPBotPanel::OnClickPartialTP(void)
  {
   m_cur_partialTP = !m_cur_partialTP;
   m_cr_bPTP.Text(m_cur_partialTP ? "ATIVO" : "DESAB.");
   m_cr_bPTP.ColorBackground(m_cur_partialTP ? C'30,120,70' : C'120,50,50');
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| OnClickSLType — ciclo: FIXED → ATR → RANGE → FIXED               |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickSLType(void)
  {
   if(m_cur_slType == SL_FIXED)
      m_cur_slType = SL_ATR;
   else if(m_cur_slType == SL_ATR)
      m_cur_slType = SL_RANGE;
   else
      m_cur_slType = SL_FIXED;

// Atualizar botão
   string typeTxt = (m_cur_slType == SL_FIXED) ? "FIXO" :
                    (m_cur_slType == SL_ATR)   ? "ATR"  : "RANGE";
   m_cr_bSLT.Text(typeTxt);

// Atualizar label + valor do SL
   string slLabel = (m_cur_slType == SL_FIXED) ? "SL (Fixo pts):" :
                    (m_cur_slType == SL_ATR)   ? "SL (ATR x):" : "SL (Range x):";
   m_cr_lSL.Text(slLabel);

   if(m_cur_slType == SL_FIXED)
      m_cr_iSL.Text(IntegerToString(inp_FixedSL));
   else if(m_cur_slType == SL_ATR)
      m_cr_iSL.Text(DoubleToString(inp_SL_ATRMultiplier, 1));
   else
      m_cr_iSL.Text(DoubleToString(inp_RangeMultiplier, 1));

// Recalcular flags dinâmicos e atualizar visibilidade
   m_cfg_hasATR   = (m_cur_slType == SL_ATR || m_cur_tpType == TP_ATR ||
                     inp_TrailingType == TRAILING_ATR || inp_BEType == BE_ATR);
   m_cfg_hasRange = (m_cur_slType == SL_RANGE);

   if(m_cfg_hasATR) { m_cr_lATRp.Show(); m_cr_iATRp.Show(); }
   else             { m_cr_lATRp.Hide(); m_cr_iATRp.Hide(); }
   if(m_cfg_hasRange) { m_cr_lRngP.Show(); m_cr_iRngP.Show(); }
   else               { m_cr_lRngP.Hide(); m_cr_iRngP.Hide(); }

   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| OnClickTPType — ciclo: NONE → FIXED → ATR → NONE                  |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickTPType(void)
  {
   if(m_cur_tpType == TP_NONE)
      m_cur_tpType = TP_FIXED;
   else if(m_cur_tpType == TP_FIXED)
      m_cur_tpType = TP_ATR;
   else
      m_cur_tpType = TP_NONE;

// Atualizar botão
   string typeTxt = (m_cur_tpType == TP_NONE)  ? "NENHUM" :
                    (m_cur_tpType == TP_FIXED) ? "FIXO"   : "ATR";
   m_cr_bTPT.Text(typeTxt);

// Recalcular flags
   m_cfg_hasTP  = (m_cur_tpType != TP_NONE);
   m_cfg_hasATR = (m_cur_slType == SL_ATR || m_cur_tpType == TP_ATR ||
                   inp_TrailingType == TRAILING_ATR || inp_BEType == BE_ATR);

// TP value field
   if(m_cfg_hasTP)
     {
      string tpLabel = (m_cur_tpType == TP_FIXED) ? "TP (Fixo pts):" : "TP (ATR x):";
      m_cr_lTP.Text(tpLabel);
      if(m_cur_tpType == TP_FIXED)
         m_cr_iTP.Text(IntegerToString(inp_FixedTP));
      else
         m_cr_iTP.Text(DoubleToString(inp_TP_ATRMultiplier, 1));
      m_cr_lTP.Show(); m_cr_iTP.Show();
      m_cr_lCTP.Show(); m_cr_bCTP.Show();
     }
   else
     {
      m_cr_lTP.Hide(); m_cr_iTP.Hide();
      m_cr_lCTP.Hide(); m_cr_bCTP.Hide();
     }

// ATR Period visibility
   if(m_cfg_hasATR) { m_cr_lATRp.Show(); m_cr_iATRp.Show(); }
   else             { m_cr_lATRp.Hide(); m_cr_iATRp.Hide(); }

   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| OnClickApply — valida campos e chama setters hot-reload            |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickApply(void)
  {
   ApplyConfig();
  }

//+------------------------------------------------------------------+
//| ApplyConfig — lê CEdit, valida e chama setters nos módulos         |
//+------------------------------------------------------------------+
void CEPBotPanel::ApplyConfig(void)
  {
   int errors = 0;

// ═══════════════════════════════════════════════
// RISCO
// ═══════════════════════════════════════════════
   if(m_riskManager != NULL)
     {
      // Lote
      double lot = StringToDouble(m_cr_iLot.Text());
      if(lot > 0)
         m_riskManager.SetLotSize(lot);
      else
         errors++;

      // SL Type
      m_riskManager.SetSLType(m_cur_slType);

      // SL Value (baseado no tipo ATUAL, não no inp_*)
      if(m_cur_slType == SL_FIXED)
        {
         int sl = (int)StringToInteger(m_cr_iSL.Text());
         if(sl >= 0) m_riskManager.SetFixedSL(sl); else errors++;
        }
      else if(m_cur_slType == SL_ATR)
        {
         double mult = StringToDouble(m_cr_iSL.Text());
         if(mult > 0) m_riskManager.SetSLATRMultiplier(mult); else errors++;
        }
      // SL_RANGE: o valor é o multiplicador de range
      else if(m_cur_slType == SL_RANGE)
        {
         double mult = StringToDouble(m_cr_iSL.Text());
         if(mult > 0) m_riskManager.SetRangeMultiplier(mult); else errors++;
        }

      // TP Type
      m_riskManager.SetTPType(m_cur_tpType);

      // TP Value
      if(m_cfg_hasTP)
        {
         if(m_cur_tpType == TP_FIXED)
           {
            int tp = (int)StringToInteger(m_cr_iTP.Text());
            if(tp >= 0) m_riskManager.SetFixedTP(tp); else errors++;
           }
         else if(m_cur_tpType == TP_ATR)
           {
            double mult = StringToDouble(m_cr_iTP.Text());
            if(mult > 0) m_riskManager.SetTPATRMultiplier(mult); else errors++;
           }
        }

      // Trailing
      if(m_cfg_hasTrailing)
        {
         if(inp_TrailingType == TRAILING_FIXED)
           {
            int start = (int)StringToInteger(m_cr_iTrlSt.Text());
            int step  = (int)StringToInteger(m_cr_iTrlSp.Text());
            if(start >= 0 && step >= 0)
               m_riskManager.SetTrailingParams(start, step);
            else
               errors++;
           }
         else
           {
            double start = StringToDouble(m_cr_iTrlSt.Text());
            double step  = StringToDouble(m_cr_iTrlSp.Text());
            if(start > 0 && step > 0)
               m_riskManager.SetTrailingATRParams(start, step);
            else
               errors++;
           }
        }

      // BE
      if(m_cfg_hasBE)
        {
         if(inp_BEType == BE_FIXED)
           {
            int act = (int)StringToInteger(m_cr_iBEAct.Text());
            int off = (int)StringToInteger(m_cr_iBEOff.Text());
            if(act >= 0 && off >= 0)
               m_riskManager.SetBreakevenParams(act, off);
            else
               errors++;
           }
         else
           {
            double act = StringToDouble(m_cr_iBEAct.Text());
            double off = StringToDouble(m_cr_iBEOff.Text());
            if(act > 0 && off >= 0)
               m_riskManager.SetBreakevenATRParams(act, off);
            else
               errors++;
           }
        }

      // Partial TP
      m_riskManager.SetUsePartialTP(m_cur_partialTP);
      double tp1p = StringToDouble(m_cr_iTP1p.Text());
      int    tp1d = (int)StringToInteger(m_cr_iTP1d.Text());
      m_riskManager.SetPartialTP1((tp1p > 0 && tp1d > 0), tp1p, tp1d);

      double tp2p = StringToDouble(m_cr_iTP2p.Text());
      int    tp2d = (int)StringToInteger(m_cr_iTP2d.Text());
      m_riskManager.SetPartialTP2((tp2p > 0 && tp2d > 0), tp2p, tp2d);

      // ATR Period (sempre aplicar se visível)
      if(m_cfg_hasATR)
        {
         int atrP = (int)StringToInteger(m_cr_iATRp.Text());
         if(atrP >= 1) m_riskManager.SetATRPeriod(atrP); else errors++;
        }

      // Range Period (sempre aplicar se visível)
      if(m_cfg_hasRange)
        {
         int rngP = (int)StringToInteger(m_cr_iRngP.Text());
         if(rngP >= 1) m_riskManager.SetRangePeriod(rngP); else errors++;
        }

      // Spread Compensation
      m_riskManager.SetSLCompensateSpread(m_cur_compSL);
      if(m_cfg_hasTP) m_riskManager.SetTPCompensateSpread(m_cur_compTP);
      if(m_cfg_hasTrailing) m_riskManager.SetTrailingCompensateSpread(m_cur_compTrail);
     }

// ═══════════════════════════════════════════════
// BLOQUEIOS
// ═══════════════════════════════════════════════
   if(m_blockers != NULL)
     {
      // Spread
      int spr = (int)StringToInteger(m_cb_iSpr.Text());
      if(spr >= 0) m_blockers.SetMaxSpread(spr); else errors++;

      // Direção
      m_blockers.SetTradeDirection(m_cur_direction);

      // Daily Limits
      if(m_cfg_hasDailyLimits)
        {
         int maxTrd   = (int)StringToInteger(m_cb_iTrd.Text());
         double maxLs = StringToDouble(m_cb_iLoss.Text());
         double maxGn = StringToDouble(m_cb_iGain.Text());
         if(maxTrd >= 0 && maxLs >= 0 && maxGn >= 0)
            m_blockers.SetDailyLimits(maxTrd, maxLs, maxGn, inp_ProfitTargetAction);
         else
            errors++;
        }

      // Streaks
      if(m_cfg_hasStreak)
        {
         int lStr = (int)StringToInteger(m_cb_iLStr.Text());
         int wStr = (int)StringToInteger(m_cb_iWStr.Text());
         if(lStr >= 0 && wStr >= 0)
            m_blockers.SetStreakLimits(lStr, inp_LossStreakAction, inp_LossPauseMinutes,
                                      wStr, inp_WinStreakAction, inp_WinPauseMinutes);
         else
            errors++;
        }

      // Drawdown
      if(m_cfg_hasDrawdown)
        {
         double dd = StringToDouble(m_cb_iDD.Text());
         if(dd >= 0) m_blockers.SetDrawdownValue(dd); else errors++;
        }
     }

// ═══════════════════════════════════════════════
// OUTROS
// ═══════════════════════════════════════════════
   // Slippage
   if(m_tradeManager != NULL)
     {
      int slip = (int)StringToInteger(m_co_iSlip.Text());
      if(slip >= 0) m_tradeManager.SetSlippage(slip); else errors++;
     }

   // Conflito Sinais
   if(m_signalManager != NULL)
      m_signalManager.SetConflictResolution(m_cur_conflict);

   // Debug
   if(m_logger != NULL)
     {
      m_logger.SetShowDebug(m_cur_debug);
      int cd = (int)StringToInteger(m_co_iDbgCd.Text());
      if(cd >= 0) m_logger.SetDebugCooldown(cd); else errors++;
     }

// ═══════════════════════════════════════════════
// FEEDBACK
// ═══════════════════════════════════════════════
   if(errors == 0)
     {
      m_cfg_status.Text("Aplicado com sucesso!");
      m_cfg_status.Color(CLR_POSITIVE);
     }
   else
     {
      m_cfg_status.Text(IntegerToString(errors) + " campo(s) invalido(s)");
      m_cfg_status.Color(CLR_NEGATIVE);
     }
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Toggle handlers: Spread Compensation                               |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickCompSL(void)
  {
   m_cur_compSL = !m_cur_compSL;
   m_cr_bCSL.Text(m_cur_compSL ? "ON" : "OFF");
   m_cr_bCSL.ColorBackground(m_cur_compSL ? C'30,120,70' : C'120,50,50');
   ChartRedraw();
  }

void CEPBotPanel::OnClickCompTP(void)
  {
   m_cur_compTP = !m_cur_compTP;
   m_cr_bCTP.Text(m_cur_compTP ? "ON" : "OFF");
   m_cr_bCTP.ColorBackground(m_cur_compTP ? C'30,120,70' : C'120,50,50');
   ChartRedraw();
  }

void CEPBotPanel::OnClickCompTrail(void)
  {
   m_cur_compTrail = !m_cur_compTrail;
   m_cr_bCTrl.Text(m_cur_compTrail ? "ON" : "OFF");
   m_cr_bCTrl.ColorBackground(m_cur_compTrail ? C'30,120,70' : C'120,50,50');
   ChartRedraw();
  }
//+------------------------------------------------------------------+
