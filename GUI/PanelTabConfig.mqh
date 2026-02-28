//+------------------------------------------------------------------+
//|                                            PanelTabConfig.mqh    |
//|                                         Copyright 2026, EP Filho |
//|   Panel Tab: CONFIG — Sub-páginas + Hot Reload (APLICAR)          |
//|                     Versão 1.17 - Claude Parte 023 (Claude Code) |
//+------------------------------------------------------------------+
// Implementações de CEPBotPanel para a aba CONFIG.
// Incluído por Panel.mqh — NÃO incluir diretamente.
//
// Sub-páginas: RISCO | RISCO 2 | BLOQUEIOS | OUTROS
// Campos CEdit editáveis + botões de toggle/cycle
// Botão APLICAR chama setters hot-reload nos módulos
//
// ═══════════════════════════════════════════════════════════════
// CHANGELOG
// ═══════════════════════════════════════════════════════════════
// v1.17 (2026-02-28):
// + Partial TP movido de RISCO 2 → RISCO (m_c2_bPTP/iTP* → m_cr_bPTP/iTP*)
//   RefreshRisco2State: removida lógica PTP → agora em RefreshRiscoState
// + BLOQUEIOS: radio Profit Target Action (PARAR|ATIVAR DD) em Daily Limits
// + BLOQUEIOS: radio Streak Action (PAUSAR|PARAR DIA) por Loss/Win + campos pause
// + BLOQUEIOS: DRAWDOWN com header separado + radio DD Type + DD Peak Mode
// + 5 novos handlers: OnClickLossStreakAction/WinStreakAction/DDType/DDPeakMode/PTA
// + RefreshStreakState() — enable/disable campos de pausa por action
//
// v1.16 (2026-02-25):
// + RADIO GROUPS: Cycle buttons → CButton[] horizontais
//   (SL Type, TP Type, Direcao com botoes individuais por opcao)
// + CreateRadioGroup(), SetRadioSelection() — helpers reutilizaveis
// + Sub-pagina RISCO 2: Trailing ON/OFF, BE ON/OFF, Partial TP
//   (CFG_PAGE_COUNT 3→4, separacao de concerns)
// + RefreshRisco2State() — enable/disable campos Trailing/BE/Partial
//
// v1.14 (2026-02-25):
// + REVERT Move(): campos em posições FIXAS + enable/disable visual
// + RefreshRiscoState() — habilita/desabilita campos por tipo SL/TP
// + SetEditEnabled/SetButtonEnabled: cinza+ReadOnly quando desabilitado
// + Conflito TP ATR vs Partial TP: bloqueio mútuo
//   (TP=ATR bloqueia toggle Partial; Partial ativo pula ATR no ciclo)
// + Fix minimize/maximize: ReapplyTabVisibility re-exibe aba ativa
//
// v1.13 (2026-02-24):
// + LayoutRisco() dinâmico com Move() — elimina gaps ao show/hide
// + Campos ATR Period, Range Period, Comp Spread agora inline
//   com SL/TP (eliminada seção CONFIGURACAO separada)
// + Todos controles RISCO criados incondicionalmente
// + MoveRowLI/LB/Hdr helpers para reposicionamento
//
// v1.12 (2026-02-23):
// + SL Type cycle button (FIXO → ATR → RANGE) com label/valor dinâmico
// + TP Type cycle button (NENHUM → FIXO → ATR) com show/hide dinâmico
//
// v1.11 (2026-02-23):
// + FIX: ChartRedraw() nos handlers de toggle
// + Campos expandidos RISCO: ATR Period, Range Period, Compensar Spread
//
// v1.10 (2026-02-22):
// + Versão inicial — extraído de Panel.mqh
// ═══════════════════════════════════════════════════════════════

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
//| Helper: CreateRadioGroup — Label + N CButtons horizontais          |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateRadioGroup(CLabel &lbl, CButton &btns[],
                                    string labelName, string btnPrefix,
                                    string labelText,
                                    const string &texts[], int count, int y)
  {
   if(!lbl.Create(m_chart_id, PFX + labelName, m_subwin,
                  COL_LABEL_X, y, COL_VALUE_X - 5, y + PANEL_GAP_Y))
      return false;
   lbl.Text(labelText);
   lbl.Color(CLR_LABEL);
   lbl.FontSize(8);
   if(!Add(lbl))
      return false;

   int totalW = COL_VALUE_W;
   int gap    = 2;
   int btnW   = (totalW - (count - 1) * gap) / count;
   int x0     = COL_VALUE_X;

   for(int i = 0; i < count; i++)
     {
      int bx1 = x0 + i * (btnW + gap);
      int bx2 = (i == count - 1) ? (COL_VALUE_X + COL_VALUE_W) : (bx1 + btnW);
      if(!btns[i].Create(m_chart_id, PFX + btnPrefix + IntegerToString(i),
                         m_subwin, bx1, y, bx2, y + PANEL_GAP_Y + 2))
         return false;
      btns[i].Text(texts[i]);
      btns[i].FontSize(7);
      if(!Add(btns[i]))
         return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Helper: SetRadioSelection — destaca ativo, dim inativos            |
//+------------------------------------------------------------------+
void CEPBotPanel::SetRadioSelection(CButton &btns[], int count, int selected)
  {
   for(int i = 0; i < count; i++)
     {
      btns[i].Pressed(false);   // Reset MT5 native OBJPROP_STATE toggle
      if(i == selected)
        {
         btns[i].ColorBackground(CLR_RADIO_ACTIVE);
         btns[i].Color(CLR_RADIO_TXT_ACT);
        }
      else
        {
         btns[i].ColorBackground(CLR_RADIO_INACTIVE);
         btns[i].Color(CLR_RADIO_TXT_INACT);
        }
     }
  }

//+------------------------------------------------------------------+
//| Mapping: enum <-> radio index                                      |
//+------------------------------------------------------------------+
int CEPBotPanel::SLTypeToIndex(ENUM_SL_TYPE t)
  { return (t == SL_FIXED) ? 0 : (t == SL_ATR) ? 1 : 2; }

ENUM_SL_TYPE CEPBotPanel::IndexToSLType(int i)
  { return (i == 0) ? SL_FIXED : (i == 1) ? SL_ATR : SL_RANGE; }

int CEPBotPanel::TPTypeToIndex(ENUM_TP_TYPE t)
  { return (t == TP_NONE) ? 0 : (t == TP_FIXED) ? 1 : 2; }

ENUM_TP_TYPE CEPBotPanel::IndexToTPType(int i)
  { return (i == 0) ? TP_NONE : (i == 1) ? TP_FIXED : TP_ATR; }

//+------------------------------------------------------------------+
//| SetEditEnabled — habilita/desabilita visualmente label+edit        |
//+------------------------------------------------------------------+
void CEPBotPanel::SetEditEnabled(CLabel &lbl, CEdit &inp, bool enable)
  {
   if(enable)
     {
      lbl.Color(CLR_LABEL);
      inp.ReadOnly(false);
      inp.ColorBackground(clrWhite);
      inp.Color(clrBlack);
     }
   else
     {
      lbl.Color(C'180,180,180');
      inp.ReadOnly(true);
      inp.ColorBackground(C'220,220,220');
      inp.Color(C'160,160,160');
     }
  }

//+------------------------------------------------------------------+
//| SetButtonEnabled — habilita/desabilita visualmente label+button    |
//+------------------------------------------------------------------+
void CEPBotPanel::SetButtonEnabled(CLabel &lbl, CButton &btn, bool enable)
  {
   if(enable)
     {
      lbl.Color(CLR_LABEL);
      // Cores do botão gerenciadas pelo handler (ON/OFF, cycle, etc.)
     }
   else
     {
      lbl.Color(C'180,180,180');
      btn.ColorBackground(C'160,160,160');
      btn.Color(C'200,200,200');
     }
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

// ── Botões de sub-página (4 botões) ──
   int sw = (PANEL_WIDTH - 40) / CFG_PAGE_COUNT;
   int sy = CONTENT_TOP;

   if(!m_cfg_btnRisco.Create(m_chart_id, PFX + "cfg_bR", m_subwin,
                             5, sy, 5 + sw, sy + TAB_BTN_H))
      return false;
   m_cfg_btnRisco.Text("RISCO");
   m_cfg_btnRisco.FontSize(7);
   if(!Add(m_cfg_btnRisco))
      return false;

   if(!m_cfg_btnRisco2.Create(m_chart_id, PFX + "cfg_bR2", m_subwin,
                              5 + (sw + 2), sy, 5 + sw * 2 + 2, sy + TAB_BTN_H))
      return false;
   m_cfg_btnRisco2.Text("RISCO 2");
   m_cfg_btnRisco2.FontSize(7);
   if(!Add(m_cfg_btnRisco2))
      return false;

   if(!m_cfg_btnBloq.Create(m_chart_id, PFX + "cfg_bB", m_subwin,
                            5 + (sw + 2) * 2, sy, 5 + sw * 3 + 4, sy + TAB_BTN_H))
      return false;
   m_cfg_btnBloq.Text("BLOQUEIOS");
   m_cfg_btnBloq.FontSize(7);
   if(!Add(m_cfg_btnBloq))
      return false;

   if(!m_cfg_btnOutros.Create(m_chart_id, PFX + "cfg_bO", m_subwin,
                              5 + (sw + 2) * 3, sy, 5 + sw * 4 + 6, sy + TAB_BTN_H))
      return false;
   m_cfg_btnOutros.Text("OUTROS");
   m_cfg_btnOutros.FontSize(7);
   if(!Add(m_cfg_btnOutros))
      return false;

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: RISCO (simplificada — SL/TP/Spread)
// ════════════════════════════════════════════════════════════
   int y = CFG_CONTENT_Y;

   if(!CreateHdr(m_cr_hdr1, "cr_h1", "GESTAO DE RISCO", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(!CreateLI(m_cr_lLot, m_cr_iLot, "cr_lLt", "cr_iLt", "Lote:", y)) return false;
   y += PANEL_GAP_Y;

// ATR Period (compartilhado entre SL e TP)
   if(!CreateLI(m_cr_lATRp, m_cr_iATRp, "cr_lAP", "cr_iAP", "ATR Period:", y)) return false;
   y += PANEL_GAP_Y;

// Range Period
   if(!CreateLI(m_cr_lRngP, m_cr_iRngP, "cr_lRP", "cr_iRP", "Range Period:", y)) return false;
   y += PANEL_GAP_Y + 2;

// ── STOP LOSS ──
   y += PANEL_GAP_SECTION;
   if(!CreateHdr(m_cr_hdrSL, "cr_hSL", "STOP LOSS", y)) return false;
   y += PANEL_GAP_Y + 2;
   {
    string sltTexts[] = {"FIXO", "ATR", "RANGE"};
    if(!CreateRadioGroup(m_cr_lSLT, m_cr_bSLT, "cr_lST", "cr_bST", "Tipo SL:", sltTexts, 3, y))
       return false;
   }
   y += PANEL_GAP_Y + 2;

// SL value (label muda conforme tipo)
   if(!CreateLI(m_cr_lSL, m_cr_iSL, "cr_lSL", "cr_iSL", "SL (Fixo pts):", y)) return false;
   y += PANEL_GAP_Y;

// Comp Spread SL
   if(!CreateLB(m_cr_lCSL, m_cr_bCSL, "cr_lCS", "cr_bCS", "Comp. Spread SL:", y)) return false;
   y += PANEL_GAP_Y + 2;

// ── TAKE PROFIT ──
   y += PANEL_GAP_SECTION;
   if(!CreateHdr(m_cr_hdrTP, "cr_hTP", "TAKE PROFIT", y)) return false;
   y += PANEL_GAP_Y + 2;
   {
    string tptTexts[] = {"NENHUM", "FIXO", "ATR"};
    if(!CreateRadioGroup(m_cr_lTPT, m_cr_bTPT, "cr_lTT", "cr_bTT", "Tipo TP:", tptTexts, 3, y))
       return false;
   }
   y += PANEL_GAP_Y + 2;

// TP value
   if(!CreateLI(m_cr_lTP, m_cr_iTP, "cr_lTP", "cr_iTP", "TP (Fixo pts):", y)) return false;
   y += PANEL_GAP_Y;

// Comp Spread TP
   if(!CreateLB(m_cr_lCTP, m_cr_bCTP, "cr_lCT", "cr_bCT", "Comp. Spread TP:", y)) return false;
   y += PANEL_GAP_Y + 2;

// ── PARTIAL TP (movido de RISCO 2) ──
   y += PANEL_GAP_SECTION;
   if(!CreateHdr(m_cr_hdrPTP, "cr_hPTP", "PARTIAL TP", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLB(m_cr_lPTP, m_cr_bPTP, "cr_lPTP", "cr_bPTP", "Partial TP:", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLI(m_cr_lTP1p, m_cr_iTP1p, "cr_l1p", "cr_i1p", "TP1 %:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLI(m_cr_lTP1d, m_cr_iTP1d, "cr_l1d", "cr_i1d", "TP1 Dist (pts):", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLI(m_cr_lTP2p, m_cr_iTP2p, "cr_l2p", "cr_i2p", "TP2 %:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLI(m_cr_lTP2d, m_cr_iTP2d, "cr_l2d", "cr_i2d", "TP2 Dist (pts):", y)) return false;
   y += PANEL_GAP_Y;

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: RISCO 2 (Trailing/BE)
// ════════════════════════════════════════════════════════════
   y = CFG_CONTENT_Y;

// TRAILING
   if(!CreateHdr(m_c2_hdr1, "c2_h1", "TRAILING", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLB(m_c2_lTrlAct, m_c2_bTrlAct, "c2_lTA", "c2_bTA", "Trailing:", y)) return false;
   y += PANEL_GAP_Y + 2;
   {
    string trSuffix = (inp_TrailingType == TRAILING_FIXED) ? " (pts):" : " (ATR x):";
    if(!CreateLI(m_c2_lTrlSt, m_c2_iTrlSt, "c2_lTS", "c2_iTS", "Trail Start" + trSuffix, y)) return false;
    y += PANEL_GAP_Y;
    if(!CreateLI(m_c2_lTrlSp, m_c2_iTrlSp, "c2_lTP2", "c2_iTP2", "Trail Step" + trSuffix, y)) return false;
    y += PANEL_GAP_Y;
   }
   if(!CreateLB(m_c2_lCTrl, m_c2_bCTrl, "c2_lCR", "c2_bCR", "Comp. Spread Trail:", y)) return false;
   y += PANEL_GAP_Y + 2;

// BREAK EVEN
   y += PANEL_GAP_SECTION;
   if(!CreateHdr(m_c2_hdr2, "c2_h2", "BREAK EVEN", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLB(m_c2_lBEAct, m_c2_bBEAct, "c2_lBA", "c2_bBA", "Break Even:", y)) return false;
   y += PANEL_GAP_Y + 2;
   {
    string beSuffix = (inp_BEType == BE_FIXED) ? " (pts):" : " (ATR x):";
    if(!CreateLI(m_c2_lBEVal, m_c2_iBEVal, "c2_lBV", "c2_iBV", "BE Ativacao" + beSuffix, y)) return false;
    y += PANEL_GAP_Y;
    if(!CreateLI(m_c2_lBEOff, m_c2_iBEOff, "c2_lBO", "c2_iBO", "BE Offset" + beSuffix, y)) return false;
    y += PANEL_GAP_Y;
   }

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: BLOQUEIOS
// ════════════════════════════════════════════════════════════
   y = CFG_CONTENT_Y;

   if(!CreateHdr(m_cb_hdr1, "cb_h1", "BLOQUEIOS", y)) return false;
   y += PANEL_GAP_Y + 2;

   if(!CreateLI(m_cb_lSpr, m_cb_iSpr, "cb_lSp", "cb_iSp", "Max Spread (0=sem):", y)) return false;
   y += PANEL_GAP_Y;
   {
    string dirTexts[] = {"AMBOS", "BUY", "SELL"};
    if(!CreateRadioGroup(m_cb_lDir, m_cb_bDir, "cb_lDr", "cb_bDr", "Direcao:", dirTexts, 3, y))
       return false;
   }
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
      // Profit Target Action
      {
       string ptaTexts[] = {"PARAR", "ATIVAR DD"};
       if(!CreateRadioGroup(m_cb_lPTA, m_cb_bPTA, "cb_lPTA", "cb_bPTA", "Profit Acao:", ptaTexts, 2, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;
     }

   if(m_cfg_hasStreak)
     {
      y += PANEL_GAP_SECTION;
      if(!CreateHdr(m_cb_hdr3, "cb_h3", "SEQUENCIAS", y)) return false;
      y += PANEL_GAP_Y + 2;
      if(!CreateLI(m_cb_lLStr, m_cb_iLStr, "cb_lLS", "cb_iLS", "Max Loss Streak:", y)) return false;
      y += PANEL_GAP_Y;
      // Loss Streak Action radio
      {
       string lsaTexts[] = {"PAUSAR", "PARAR DIA"};
       if(!CreateRadioGroup(m_cb_lLStrA, m_cb_bLStrA, "cb_lLSA", "cb_bLSA", "Loss Acao:", lsaTexts, 2, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;
      if(!CreateLI(m_cb_lLStrP, m_cb_iLStrP, "cb_lLSP", "cb_iLSP", "Pausa Loss (min):", y)) return false;
      y += PANEL_GAP_Y;

      if(!CreateLI(m_cb_lWStr, m_cb_iWStr, "cb_lWS", "cb_iWS", "Max Win Streak:", y)) return false;
      y += PANEL_GAP_Y;
      // Win Streak Action radio
      {
       string wsaTexts[] = {"PAUSAR", "PARAR DIA"};
       if(!CreateRadioGroup(m_cb_lWStrA, m_cb_bWStrA, "cb_lWSA", "cb_bWSA", "Win Acao:", wsaTexts, 2, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;
      if(!CreateLI(m_cb_lWStrP, m_cb_iWStrP, "cb_lWSP", "cb_iWSP", "Pausa Win (min):", y)) return false;
      y += PANEL_GAP_Y;
     }

   if(m_cfg_hasDrawdown)
     {
      y += PANEL_GAP_SECTION;
      if(!CreateHdr(m_cb_hdr4, "cb_h4", "DRAWDOWN", y)) return false;
      y += PANEL_GAP_Y + 2;
      string ddLabel = (inp_DrawdownType == DD_FINANCIAL) ? "Drawdown $:" : "Drawdown %:";
      if(!CreateLI(m_cb_lDD, m_cb_iDD, "cb_lDD", "cb_iDD", ddLabel, y)) return false;
      y += PANEL_GAP_Y;
      // DD Type radio
      {
       string ddtTexts[] = {"FINANCEIRO", "PERCENTUAL"};
       if(!CreateRadioGroup(m_cb_lDDT, m_cb_bDDT, "cb_lDT", "cb_bDT", "Tipo DD:", ddtTexts, 2, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;
      // DD Peak Mode radio
      {
       string ddpTexts[] = {"SO REAL.", "C/FLUTUANTE"};
       if(!CreateRadioGroup(m_cb_lDDPk, m_cb_bDDPk, "cb_lDPk", "cb_bDPk", "Modo Peak:", ddpTexts, 2, y))
          return false;
      }
      y += PANEL_GAP_Y;
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

// ── Risco (radio groups) ──
   m_cr_iLot.Text(DoubleToString(inp_LotSize, 2));

// SL Type radio group
   SetRadioSelection(m_cr_bSLT, 3, SLTypeToIndex(m_cur_slType));

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

// ATR Period + Range Period
   m_cr_iATRp.Text(IntegerToString(inp_ATRPeriod));
   m_cr_iRngP.Text(IntegerToString(inp_RangePeriod));

// Comp Spread SL
   m_cur_compSL = inp_SL_CompensateSpread;
   m_cr_bCSL.Text(m_cur_compSL ? "ON" : "OFF");
   m_cr_bCSL.ColorBackground(m_cur_compSL ? C'30,120,70' : C'120,50,50');
   m_cr_bCSL.Color(clrWhite);

// TP Type radio group
   SetRadioSelection(m_cr_bTPT, 3, TPTypeToIndex(m_cur_tpType));

// TP value + label
   string tpLabel = (m_cur_tpType == TP_FIXED) ? "TP (Fixo pts):" : "TP (ATR x):";
   m_cr_lTP.Text(tpLabel);
   if(m_cur_tpType == TP_FIXED)
      m_cr_iTP.Text(IntegerToString(inp_FixedTP));
   else if(m_cur_tpType == TP_ATR)
      m_cr_iTP.Text(DoubleToString(inp_TP_ATRMultiplier, 1));
   else
      m_cr_iTP.Text("---");

// Comp Spread TP
   m_cur_compTP = inp_TP_CompensateSpread;
   m_cr_bCTP.Text(m_cur_compTP ? "ON" : "OFF");
   m_cr_bCTP.ColorBackground(m_cur_compTP ? C'30,120,70' : C'120,50,50');
   m_cr_bCTP.Color(clrWhite);

// ── Risco 2 (Trailing/BE/Partial TP) ──
   m_cur_trailOn = m_cfg_hasTrailing;
   m_c2_bTrlAct.Text(m_cur_trailOn ? "ON" : "OFF");
   m_c2_bTrlAct.ColorBackground(m_cur_trailOn ? C'30,120,70' : C'120,50,50');
   m_c2_bTrlAct.Color(clrWhite);

   if(inp_TrailingType == TRAILING_FIXED)
     {
      m_c2_iTrlSt.Text(IntegerToString(inp_TrailingStart));
      m_c2_iTrlSp.Text(IntegerToString(inp_TrailingStep));
     }
   else
     {
      m_c2_iTrlSt.Text(DoubleToString(inp_TrailingATRStart, 2));
      m_c2_iTrlSp.Text(DoubleToString(inp_TrailingATRStep, 2));
     }

   m_cur_compTrail = inp_Trailing_CompensateSpread;
   m_c2_bCTrl.Text(m_cur_compTrail ? "ON" : "OFF");
   m_c2_bCTrl.ColorBackground(m_cur_compTrail ? C'30,120,70' : C'120,50,50');
   m_c2_bCTrl.Color(clrWhite);

   m_cur_beOn = m_cfg_hasBE;
   m_c2_bBEAct.Text(m_cur_beOn ? "ON" : "OFF");
   m_c2_bBEAct.ColorBackground(m_cur_beOn ? C'30,120,70' : C'120,50,50');
   m_c2_bBEAct.Color(clrWhite);

   if(inp_BEType == BE_FIXED)
     {
      m_c2_iBEVal.Text(IntegerToString(inp_BEActivation));
      m_c2_iBEOff.Text(IntegerToString(inp_BEOffset));
     }
   else
     {
      m_c2_iBEVal.Text(DoubleToString(inp_BE_ATRActivation, 2));
      m_c2_iBEOff.Text(DoubleToString(inp_BE_ATROffset, 2));
     }

   m_cr_bPTP.Text(m_cur_partialTP ? "ATIVO" : "DESAB.");
   m_cr_bPTP.ColorBackground(m_cur_partialTP ? C'30,120,70' : C'120,50,50');
   m_cr_bPTP.Color(clrWhite);
   m_cr_iTP1p.Text(DoubleToString(inp_PartialTP1_Percent, 1));
   m_cr_iTP1d.Text(IntegerToString(inp_PartialTP1_Distance));
   m_cr_iTP2p.Text(DoubleToString(inp_PartialTP2_Percent, 1));
   m_cr_iTP2d.Text(IntegerToString(inp_PartialTP2_Distance));

// ── Bloqueios ──
   m_cb_iSpr.Text(IntegerToString(inp_MaxSpread));

// Direction radio group
   SetRadioSelection(m_cb_bDir, 3, (int)m_cur_direction);

   if(m_cfg_hasDailyLimits)
     {
      m_cb_iTrd.Text(IntegerToString(inp_MaxDailyTrades));
      m_cb_iLoss.Text(DoubleToString(inp_MaxDailyLoss, 2));
      m_cb_iGain.Text(DoubleToString(inp_MaxDailyGain, 2));
      // Profit Target Action
      m_cur_profitTargetAction = inp_ProfitTargetAction;
      SetRadioSelection(m_cb_bPTA, 2, (int)m_cur_profitTargetAction);
     }

   if(m_cfg_hasStreak)
     {
      m_cb_iLStr.Text(IntegerToString(inp_MaxLossStreak));
      // Loss Streak Action
      m_cur_lossStreakAction = inp_LossStreakAction;
      SetRadioSelection(m_cb_bLStrA, 2, (int)m_cur_lossStreakAction);
      m_cb_iLStrP.Text(IntegerToString(inp_LossPauseMinutes));

      m_cb_iWStr.Text(IntegerToString(inp_MaxWinStreak));
      // Win Streak Action
      m_cur_winStreakAction = inp_WinStreakAction;
      SetRadioSelection(m_cb_bWStrA, 2, (int)m_cur_winStreakAction);
      m_cb_iWStrP.Text(IntegerToString(inp_WinPauseMinutes));
     }

   if(m_cfg_hasDrawdown)
     {
      m_cb_iDD.Text(DoubleToString(inp_DrawdownValue, 2));
      // DD Type
      m_cur_ddType = inp_DrawdownType;
      SetRadioSelection(m_cb_bDDT, 2, (int)m_cur_ddType);
      // DD Peak Mode
      m_cur_ddPeakMode = inp_DrawdownPeakMode;
      SetRadioSelection(m_cb_bDDPk, 2, (int)m_cur_ddPeakMode);
     }

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
//| RefreshRiscoState — habilita/desabilita campos conforme tipo SL/TP |
//+------------------------------------------------------------------+
void CEPBotPanel::RefreshRiscoState(void)
  {
// ATR Period: habilitado quando qualquer feature usa ATR
   SetEditEnabled(m_cr_lATRp, m_cr_iATRp, m_cfg_hasATR);

// Range Period: habilitado quando SL = RANGE
   SetEditEnabled(m_cr_lRngP, m_cr_iRngP, m_cfg_hasRange);

// TP value: habilitado quando TP != NENHUM
   SetEditEnabled(m_cr_lTP, m_cr_iTP, m_cfg_hasTP);

// Comp Spread TP: habilitado quando TP != NENHUM
   SetButtonEnabled(m_cr_lCTP, m_cr_bCTP, m_cfg_hasTP);
   if(m_cfg_hasTP)
     {
      m_cr_bCTP.ColorBackground(m_cur_compTP ? C'30,120,70' : C'120,50,50');
      m_cr_bCTP.Color(clrWhite);
     }

// ── Partial TP (movido de RISCO 2) ──
   bool ptpBlocked = (m_cur_tpType == TP_ATR);

// Forçar OFF se TP=ATR (conflito)
   if(ptpBlocked && m_cur_partialTP)
     {
      m_cur_partialTP = false;
      m_cr_bPTP.Text("DESAB.");
     }

   if(ptpBlocked)
     {
      SetButtonEnabled(m_cr_lPTP, m_cr_bPTP, false);
      m_cr_bPTP.Text("BLOQ.");
     }
   else
     {
      m_cr_lPTP.Color(CLR_LABEL);
      m_cr_bPTP.ColorBackground(m_cur_partialTP ? C'30,120,70' : C'120,50,50');
      m_cr_bPTP.Color(clrWhite);
      m_cr_bPTP.Text(m_cur_partialTP ? "ATIVO" : "DESAB.");
     }

// Campos TP1/TP2: habilitados se PTP ativo e não bloqueado
   bool ptpActive = (m_cur_partialTP && !ptpBlocked);
   SetEditEnabled(m_cr_lTP1p, m_cr_iTP1p, ptpActive);
   SetEditEnabled(m_cr_lTP1d, m_cr_iTP1d, ptpActive);
   SetEditEnabled(m_cr_lTP2p, m_cr_iTP2p, ptpActive);
   SetEditEnabled(m_cr_lTP2d, m_cr_iTP2d, ptpActive);

// Dim radio TP ATR se Partial TP ativo (conflito)
   if(m_cur_partialTP)
     {
      m_cr_bTPT[2].ColorBackground(C'160,160,160');
      m_cr_bTPT[2].Color(C'200,200,200');
     }

   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| RefreshRisco2State — enable/disable Trailing/BE/Partial TP         |
//+------------------------------------------------------------------+
void CEPBotPanel::RefreshRisco2State(void)
  {
// Trailing fields: habilitado se toggle ON
   SetEditEnabled(m_c2_lTrlSt, m_c2_iTrlSt, m_cur_trailOn);
   SetEditEnabled(m_c2_lTrlSp, m_c2_iTrlSp, m_cur_trailOn);
   SetButtonEnabled(m_c2_lCTrl, m_c2_bCTrl, m_cur_trailOn);
   if(m_cur_trailOn)
     {
      m_c2_bCTrl.ColorBackground(m_cur_compTrail ? C'30,120,70' : C'120,50,50');
      m_c2_bCTrl.Color(clrWhite);
     }

// BE fields: habilitado se toggle ON
   SetEditEnabled(m_c2_lBEVal, m_c2_iBEVal, m_cur_beOn);
   SetEditEnabled(m_c2_lBEOff, m_c2_iBEOff, m_cur_beOn);

   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| ShowCfgPage — alterna sub-página ativa do CONFIG                   |
//+------------------------------------------------------------------+
void CEPBotPanel::ShowCfgPage(ENUM_CONFIG_PAGE page)
  {
   m_cfgPage = page;
   for(int p = 0; p < CFG_PAGE_COUNT; p++)
      SetCfgPageVis((ENUM_CONFIG_PAGE)p, false);
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
            m_cr_lATRp.Show(); m_cr_iATRp.Show();
            m_cr_lRngP.Show(); m_cr_iRngP.Show();
            m_cr_hdrSL.Show();
            m_cr_lSLT.Show(); for(int i=0;i<3;i++) m_cr_bSLT[i].Show();
            m_cr_lSL.Show(); m_cr_iSL.Show();
            m_cr_lCSL.Show(); m_cr_bCSL.Show();
            m_cr_hdrTP.Show();
            m_cr_lTPT.Show(); for(int i=0;i<3;i++) m_cr_bTPT[i].Show();
            m_cr_lTP.Show(); m_cr_iTP.Show();
            m_cr_lCTP.Show(); m_cr_bCTP.Show();
            m_cr_hdrPTP.Show(); m_cr_lPTP.Show(); m_cr_bPTP.Show();
            m_cr_lTP1p.Show(); m_cr_iTP1p.Show();
            m_cr_lTP1d.Show(); m_cr_iTP1d.Show();
            m_cr_lTP2p.Show(); m_cr_iTP2p.Show();
            m_cr_lTP2d.Show(); m_cr_iTP2d.Show();
            RefreshRiscoState();
           }
         else
           {
            m_cr_hdr1.Hide(); m_cr_lLot.Hide(); m_cr_iLot.Hide();
            m_cr_lATRp.Hide(); m_cr_iATRp.Hide();
            m_cr_lRngP.Hide(); m_cr_iRngP.Hide();
            m_cr_hdrSL.Hide();
            m_cr_lSLT.Hide(); for(int i=0;i<3;i++) m_cr_bSLT[i].Hide();
            m_cr_lSL.Hide(); m_cr_iSL.Hide();
            m_cr_lCSL.Hide(); m_cr_bCSL.Hide();
            m_cr_hdrTP.Hide();
            m_cr_lTPT.Hide(); for(int i=0;i<3;i++) m_cr_bTPT[i].Hide();
            m_cr_lTP.Hide(); m_cr_iTP.Hide();
            m_cr_lCTP.Hide(); m_cr_bCTP.Hide();
            m_cr_hdrPTP.Hide(); m_cr_lPTP.Hide(); m_cr_bPTP.Hide();
            m_cr_lTP1p.Hide(); m_cr_iTP1p.Hide();
            m_cr_lTP1d.Hide(); m_cr_iTP1d.Hide();
            m_cr_lTP2p.Hide(); m_cr_iTP2p.Hide();
            m_cr_lTP2d.Hide(); m_cr_iTP2d.Hide();
           }
         break;
        }

      case CFG_RISCO2:
        {
         if(vis)
           {
            m_c2_hdr1.Show(); m_c2_lTrlAct.Show(); m_c2_bTrlAct.Show();
            m_c2_lTrlSt.Show(); m_c2_iTrlSt.Show();
            m_c2_lTrlSp.Show(); m_c2_iTrlSp.Show();
            m_c2_lCTrl.Show(); m_c2_bCTrl.Show();
            m_c2_hdr2.Show(); m_c2_lBEAct.Show(); m_c2_bBEAct.Show();
            m_c2_lBEVal.Show(); m_c2_iBEVal.Show();
            m_c2_lBEOff.Show(); m_c2_iBEOff.Show();
            RefreshRisco2State();
           }
         else
           {
            m_c2_hdr1.Hide(); m_c2_lTrlAct.Hide(); m_c2_bTrlAct.Hide();
            m_c2_lTrlSt.Hide(); m_c2_iTrlSt.Hide();
            m_c2_lTrlSp.Hide(); m_c2_iTrlSp.Hide();
            m_c2_lCTrl.Hide(); m_c2_bCTrl.Hide();
            m_c2_hdr2.Hide(); m_c2_lBEAct.Hide(); m_c2_bBEAct.Hide();
            m_c2_lBEVal.Hide(); m_c2_iBEVal.Hide();
            m_c2_lBEOff.Hide(); m_c2_iBEOff.Hide();
           }
         break;
        }

      case CFG_BLOQUEIOS:
        {
         if(vis)
           {
            m_cb_hdr1.Show(); m_cb_lSpr.Show(); m_cb_iSpr.Show();
            m_cb_lDir.Show(); for(int i=0;i<3;i++) m_cb_bDir[i].Show();
            if(m_cfg_hasDailyLimits)
              {
               m_cb_hdr2.Show(); m_cb_lTrd.Show(); m_cb_iTrd.Show();
               m_cb_lLoss.Show(); m_cb_iLoss.Show();
               m_cb_lGain.Show(); m_cb_iGain.Show();
               m_cb_lPTA.Show(); for(int i=0;i<2;i++) m_cb_bPTA[i].Show();
              }
            if(m_cfg_hasStreak)
              {
               m_cb_hdr3.Show(); m_cb_lLStr.Show(); m_cb_iLStr.Show();
               m_cb_lLStrA.Show(); for(int i=0;i<2;i++) m_cb_bLStrA[i].Show();
               m_cb_lWStr.Show(); m_cb_iWStr.Show();
               m_cb_lWStrA.Show(); for(int i=0;i<2;i++) m_cb_bWStrA[i].Show();
               RefreshStreakState();
              }
            if(m_cfg_hasDrawdown)
              {
               m_cb_hdr4.Show(); m_cb_lDD.Show(); m_cb_iDD.Show();
               m_cb_lDDT.Show(); for(int i=0;i<2;i++) m_cb_bDDT[i].Show();
               m_cb_lDDPk.Show(); for(int i=0;i<2;i++) m_cb_bDDPk[i].Show();
              }
           }
         else
           {
            m_cb_hdr1.Hide(); m_cb_lSpr.Hide(); m_cb_iSpr.Hide();
            m_cb_lDir.Hide(); for(int i=0;i<3;i++) m_cb_bDir[i].Hide();
            if(m_cfg_hasDailyLimits)
              {
               m_cb_hdr2.Hide(); m_cb_lTrd.Hide(); m_cb_iTrd.Hide();
               m_cb_lLoss.Hide(); m_cb_iLoss.Hide();
               m_cb_lGain.Hide(); m_cb_iGain.Hide();
               m_cb_lPTA.Hide(); for(int i=0;i<2;i++) m_cb_bPTA[i].Hide();
              }
            if(m_cfg_hasStreak)
              {
               m_cb_hdr3.Hide(); m_cb_lLStr.Hide(); m_cb_iLStr.Hide();
               m_cb_lLStrA.Hide(); for(int i=0;i<2;i++) m_cb_bLStrA[i].Hide();
               m_cb_lLStrP.Hide(); m_cb_iLStrP.Hide();
               m_cb_lWStr.Hide(); m_cb_iWStr.Hide();
               m_cb_lWStrA.Hide(); for(int i=0;i<2;i++) m_cb_bWStrA[i].Hide();
               m_cb_lWStrP.Hide(); m_cb_iWStrP.Hide();
              }
            if(m_cfg_hasDrawdown)
              {
               m_cb_hdr4.Hide(); m_cb_lDD.Hide(); m_cb_iDD.Hide();
               m_cb_lDDT.Hide(); for(int i=0;i<2;i++) m_cb_bDDT[i].Hide();
               m_cb_lDDPk.Hide(); for(int i=0;i<2;i++) m_cb_bDDPk[i].Hide();
              }
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
   m_cfg_btnRisco.Pressed(false);  m_cfg_btnRisco2.Pressed(false);
   m_cfg_btnBloq.Pressed(false);   m_cfg_btnOutros.Pressed(false);

   m_cfg_btnRisco.ColorBackground((m_cfgPage == CFG_RISCO)      ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
   m_cfg_btnRisco2.ColorBackground((m_cfgPage == CFG_RISCO2)    ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
   m_cfg_btnBloq.ColorBackground((m_cfgPage == CFG_BLOQUEIOS)   ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
   m_cfg_btnOutros.ColorBackground((m_cfgPage == CFG_OUTROS)    ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);

   m_cfg_btnRisco.Color((m_cfgPage == CFG_RISCO)      ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_cfg_btnRisco2.Color((m_cfgPage == CFG_RISCO2)    ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_cfg_btnBloq.Color((m_cfgPage == CFG_BLOQUEIOS)   ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_cfg_btnOutros.Color((m_cfgPage == CFG_OUTROS)    ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
  }

//+------------------------------------------------------------------+
//| Handlers de clique das sub-páginas                                 |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickCfgRisco(void)   { ShowCfgPage(CFG_RISCO);     }
void CEPBotPanel::OnClickCfgRisco2(void)  { ShowCfgPage(CFG_RISCO2);    }
void CEPBotPanel::OnClickCfgBloq(void)    { ShowCfgPage(CFG_BLOQUEIOS); }
void CEPBotPanel::OnClickCfgOutros(void)  { ShowCfgPage(CFG_OUTROS);    }

//+------------------------------------------------------------------+
//| Toggle/Cycle handlers                                              |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickDirection(int selected)
  {
   m_cur_direction = (ENUM_TRADE_DIRECTION)selected;
   SetRadioSelection(m_cb_bDir, 3, selected);
   ChartRedraw();
  }

void CEPBotPanel::OnClickConflict(void)
  {
   m_cur_conflict = (m_cur_conflict == CONFLICT_PRIORITY) ? CONFLICT_CANCEL : CONFLICT_PRIORITY;
   m_co_bConfl.Pressed(false);
   m_co_bConfl.Text((m_cur_conflict == CONFLICT_PRIORITY) ? "PRIORIDADE" : "CANCELAR");
   ChartRedraw();
  }

void CEPBotPanel::OnClickDebug(void)
  {
   m_cur_debug = !m_cur_debug;
   m_co_bDbg.Pressed(false);
   m_co_bDbg.Text(m_cur_debug ? "ON" : "OFF");
   m_co_bDbg.ColorBackground(m_cur_debug ? C'30,120,70' : C'120,50,50');
   ChartRedraw();
  }

void CEPBotPanel::OnClickPartialTP(void)
  {
// Bloqueado se TP = ATR (conflito conceitual)
   if(m_cur_tpType == TP_ATR)
      return;

   m_cur_partialTP = !m_cur_partialTP;
   m_cr_bPTP.Pressed(false);
   m_cr_bPTP.Text(m_cur_partialTP ? "ATIVO" : "DESAB.");
   m_cr_bPTP.ColorBackground(m_cur_partialTP ? C'30,120,70' : C'120,50,50');
// Partial TP agora em RISCO — atualiza estado visual incluindo conflito e dim ATR
   RefreshRiscoState();
  }

//+------------------------------------------------------------------+
//| OnClickTrailToggle — liga/desliga Trailing                         |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickTrailToggle(void)
  {
   m_cur_trailOn = !m_cur_trailOn;
   m_c2_bTrlAct.Pressed(false);
   m_c2_bTrlAct.Text(m_cur_trailOn ? "ON" : "OFF");
   m_c2_bTrlAct.ColorBackground(m_cur_trailOn ? C'30,120,70' : C'120,50,50');
   RefreshRisco2State();
  }

//+------------------------------------------------------------------+
//| OnClickBEToggle — liga/desliga Break Even                          |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickBEToggle(void)
  {
   m_cur_beOn = !m_cur_beOn;
   m_c2_bBEAct.Pressed(false);
   m_c2_bBEAct.Text(m_cur_beOn ? "ON" : "OFF");
   m_c2_bBEAct.ColorBackground(m_cur_beOn ? C'30,120,70' : C'120,50,50');
   RefreshRisco2State();
  }

//+------------------------------------------------------------------+
//| OnClickSLType — radio: 0=FIXO, 1=ATR, 2=RANGE                    |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickSLType(int selected)
  {
   m_cur_slType = IndexToSLType(selected);
   SetRadioSelection(m_cr_bSLT, 3, selected);

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

// Recalcular flags e atualizar estado visual
   m_cfg_hasATR   = (m_cur_slType == SL_ATR || m_cur_tpType == TP_ATR ||
                     inp_TrailingType == TRAILING_ATR || inp_BEType == BE_ATR);
   m_cfg_hasRange = (m_cur_slType == SL_RANGE);

   RefreshRiscoState();
  }

//+------------------------------------------------------------------+
//| OnClickTPType — radio: 0=NENHUM, 1=FIXO, 2=ATR                    |
//| (se ATR selecionado, Partial TP é forçado OFF via RefreshRisco2)   |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickTPType(int selected)
  {

   m_cur_tpType = IndexToTPType(selected);
   SetRadioSelection(m_cr_bTPT, 3, selected);

// Recalcular flags
   m_cfg_hasTP  = (m_cur_tpType != TP_NONE);
   m_cfg_hasATR = (m_cur_slType == SL_ATR || m_cur_tpType == TP_ATR ||
                   inp_TrailingType == TRAILING_ATR || inp_BEType == BE_ATR);

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
   else
     {
      m_cr_lTP.Text("TP:");
      m_cr_iTP.Text("---");
     }

// Atualizar RISCO 2 primeiro (força Partial TP OFF se ATR)
   RefreshRisco2State();
// Atualizar estado visual RISCO (usa m_cur_partialTP já atualizado)
   RefreshRiscoState();
  }

//+------------------------------------------------------------------+
//| OnClickApply — valida campos e chama setters hot-reload            |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickApply(void)
  {
   m_cfg_btnApply.Pressed(false);
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

      // SL Value (baseado no tipo ATUAL)
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
      else if(m_cur_slType == SL_RANGE)
        {
         double mult = StringToDouble(m_cr_iSL.Text());
         if(mult > 0) m_riskManager.SetRangeMultiplier(mult); else errors++;
        }

      // TP Type
      m_riskManager.SetTPType(m_cur_tpType);

      // TP Value (só se habilitado)
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

      // Trailing activation (toggle ON/OFF)
      m_riskManager.SetTrailingActivation(m_cur_trailOn ? TRAILING_ALWAYS : TRAILING_NEVER);

      // Trailing params (só se toggle ON)
      if(m_cur_trailOn)
        {
         if(inp_TrailingType == TRAILING_FIXED)
           {
            int start = (int)StringToInteger(m_c2_iTrlSt.Text());
            int step  = (int)StringToInteger(m_c2_iTrlSp.Text());
            if(start >= 0 && step >= 0)
               m_riskManager.SetTrailingParams(start, step);
            else
               errors++;
           }
         else
           {
            double start = StringToDouble(m_c2_iTrlSt.Text());
            double step  = StringToDouble(m_c2_iTrlSp.Text());
            if(start > 0 && step > 0)
               m_riskManager.SetTrailingATRParams(start, step);
            else
               errors++;
           }
        }

      // BE activation (toggle ON/OFF)
      m_riskManager.SetBEActivation(m_cur_beOn ? BE_ALWAYS : BE_NEVER);

      // BE params (só se toggle ON)
      if(m_cur_beOn)
        {
         if(inp_BEType == BE_FIXED)
           {
            int act = (int)StringToInteger(m_c2_iBEVal.Text());
            int off = (int)StringToInteger(m_c2_iBEOff.Text());
            if(act >= 0 && off >= 0)
               m_riskManager.SetBreakevenParams(act, off);
            else
               errors++;
           }
         else
           {
            double act = StringToDouble(m_c2_iBEVal.Text());
            double off = StringToDouble(m_c2_iBEOff.Text());
            if(act > 0 && off >= 0)
               m_riskManager.SetBreakevenATRParams(act, off);
            else
               errors++;
           }
        }

      // Partial TP (não aplica se bloqueado por TP=ATR)
      m_riskManager.SetUsePartialTP(m_cur_partialTP);
      if(m_cur_partialTP)
        {
         double tp1p = StringToDouble(m_cr_iTP1p.Text());
         int    tp1d = (int)StringToInteger(m_cr_iTP1d.Text());
         m_riskManager.SetPartialTP1((tp1p > 0 && tp1d > 0), tp1p, tp1d);

         double tp2p = StringToDouble(m_cr_iTP2p.Text());
         int    tp2d = (int)StringToInteger(m_cr_iTP2d.Text());
         m_riskManager.SetPartialTP2((tp2p > 0 && tp2d > 0), tp2p, tp2d);
        }

      // ATR Period (só se alguma feature usa ATR)
      if(m_cfg_hasATR)
        {
         int atrP = (int)StringToInteger(m_cr_iATRp.Text());
         if(atrP >= 1) m_riskManager.SetATRPeriod(atrP); else errors++;
        }

      // Range Period (só se SL=RANGE)
      if(m_cfg_hasRange)
        {
         int rngP = (int)StringToInteger(m_cr_iRngP.Text());
         if(rngP >= 1) m_riskManager.SetRangePeriod(rngP); else errors++;
        }

      // Spread Compensation
      m_riskManager.SetSLCompensateSpread(m_cur_compSL);
      if(m_cfg_hasTP) m_riskManager.SetTPCompensateSpread(m_cur_compTP);
      if(m_cur_trailOn) m_riskManager.SetTrailingCompensateSpread(m_cur_compTrail);
     }

// ═══════════════════════════════════════════════
// BLOQUEIOS
// ═══════════════════════════════════════════════
   if(m_blockers != NULL)
     {
      int spr = (int)StringToInteger(m_cb_iSpr.Text());
      if(spr >= 0) m_blockers.SetMaxSpread(spr); else errors++;

      m_blockers.SetTradeDirection(m_cur_direction);

      if(m_cfg_hasDailyLimits)
        {
         int maxTrd   = (int)StringToInteger(m_cb_iTrd.Text());
         double maxLs = StringToDouble(m_cb_iLoss.Text());
         double maxGn = StringToDouble(m_cb_iGain.Text());
         if(maxTrd >= 0 && maxLs >= 0 && maxGn >= 0)
            m_blockers.SetDailyLimits(maxTrd, maxLs, maxGn, m_cur_profitTargetAction);
         else
            errors++;
        }

      if(m_cfg_hasStreak)
        {
         int lStr  = (int)StringToInteger(m_cb_iLStr.Text());
         int wStr  = (int)StringToInteger(m_cb_iWStr.Text());
         int lPause = (int)StringToInteger(m_cb_iLStrP.Text());
         int wPause = (int)StringToInteger(m_cb_iWStrP.Text());
         if(lStr >= 0 && wStr >= 0 && lPause >= 0 && wPause >= 0)
            m_blockers.SetStreakLimits(lStr, m_cur_lossStreakAction, lPause,
                                      wStr, m_cur_winStreakAction,  wPause);
         else
            errors++;
        }

      if(m_cfg_hasDrawdown)
        {
         double dd = StringToDouble(m_cb_iDD.Text());
         if(dd >= 0)
           {
            m_blockers.SetDrawdownValue(dd);
            m_blockers.SetDrawdownType(m_cur_ddType);
            m_blockers.SetDrawdownPeakMode(m_cur_ddPeakMode);
           }
         else
            errors++;
        }
     }

// ═══════════════════════════════════════════════
// OUTROS
// ═══════════════════════════════════════════════
   if(m_tradeManager != NULL)
     {
      int slip = (int)StringToInteger(m_co_iSlip.Text());
      if(slip >= 0) m_tradeManager.SetSlippage(slip); else errors++;
     }

   if(m_signalManager != NULL)
      m_signalManager.SetConflictResolution(m_cur_conflict);

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
   m_cr_bCSL.Pressed(false);
   m_cr_bCSL.Text(m_cur_compSL ? "ON" : "OFF");
   m_cr_bCSL.ColorBackground(m_cur_compSL ? C'30,120,70' : C'120,50,50');
   ChartRedraw();
  }

void CEPBotPanel::OnClickCompTP(void)
  {
// Bloqueado se TP = NENHUM
   if(!m_cfg_hasTP) return;
   m_cur_compTP = !m_cur_compTP;
   m_cr_bCTP.Pressed(false);
   m_cr_bCTP.Text(m_cur_compTP ? "ON" : "OFF");
   m_cr_bCTP.ColorBackground(m_cur_compTP ? C'30,120,70' : C'120,50,50');
   ChartRedraw();
  }

void CEPBotPanel::OnClickCompTrail(void)
  {
// Bloqueado se Trailing desligado
   if(!m_cur_trailOn) return;
   m_cur_compTrail = !m_cur_compTrail;
   m_c2_bCTrl.Pressed(false);
   m_c2_bCTrl.Text(m_cur_compTrail ? "ON" : "OFF");
   m_c2_bCTrl.ColorBackground(m_cur_compTrail ? C'30,120,70' : C'120,50,50');
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| RefreshStreakState — enable/disable campos de pausa por action    |
//+------------------------------------------------------------------+
void CEPBotPanel::RefreshStreakState(void)
  {
   if(!m_cfg_hasStreak) return;

// Loss Pause Minutes: visível só se action = PAUSAR
   bool lPause = (m_cur_lossStreakAction == STREAK_PAUSE);
   SetEditEnabled(m_cb_lLStrP, m_cb_iLStrP, lPause);
   if(lPause)
     { m_cb_lLStrP.Show(); m_cb_iLStrP.Show(); }
   else
     { m_cb_lLStrP.Hide(); m_cb_iLStrP.Hide(); }

// Win Pause Minutes: visível só se action = PAUSAR
   bool wPause = (m_cur_winStreakAction == STREAK_PAUSE);
   SetEditEnabled(m_cb_lWStrP, m_cb_iWStrP, wPause);
   if(wPause)
     { m_cb_lWStrP.Show(); m_cb_iWStrP.Show(); }
   else
     { m_cb_lWStrP.Hide(); m_cb_iWStrP.Hide(); }
  }

//+------------------------------------------------------------------+
//| Novos handlers BLOQUEIOS (Parte 023)                              |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickLossStreakAction(int selected)
  {
   m_cur_lossStreakAction = (ENUM_STREAK_ACTION)selected;
   SetRadioSelection(m_cb_bLStrA, 2, selected);
   RefreshStreakState();
   ChartRedraw();
  }

void CEPBotPanel::OnClickWinStreakAction(int selected)
  {
   m_cur_winStreakAction = (ENUM_STREAK_ACTION)selected;
   SetRadioSelection(m_cb_bWStrA, 2, selected);
   RefreshStreakState();
   ChartRedraw();
  }

void CEPBotPanel::OnClickDDType(int selected)
  {
   m_cur_ddType = (ENUM_DRAWDOWN_TYPE)selected;
   SetRadioSelection(m_cb_bDDT, 2, selected);
// Atualizar label do campo de valor drawdown
   string ddLabel = (m_cur_ddType == DD_FINANCIAL) ? "Drawdown $:" : "Drawdown %:";
   m_cb_lDD.Text(ddLabel);
   ChartRedraw();
  }

void CEPBotPanel::OnClickDDPeakMode(int selected)
  {
   m_cur_ddPeakMode = (ENUM_DRAWDOWN_PEAK_MODE)selected;
   SetRadioSelection(m_cb_bDDPk, 2, selected);
   ChartRedraw();
  }

void CEPBotPanel::OnClickProfitTargetAction(int selected)
  {
   m_cur_profitTargetAction = (ENUM_PROFIT_TARGET_ACTION)selected;
   SetRadioSelection(m_cb_bPTA, 2, selected);
   ChartRedraw();
  }
//+------------------------------------------------------------------+
