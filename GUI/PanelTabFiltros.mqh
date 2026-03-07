//+------------------------------------------------------------------+
//|                                            PanelTabFiltros.mqh   |
//|                                         Copyright 2026, EP Filho |
//|          Panel Tab: FILTROS — Create + Update                     |
//|                     Versão 1.14 - Claude Parte 024 (Claude Code) |
//+------------------------------------------------------------------+
// Implementações de CEPBotPanel para a aba FILTROS.
// Incluído por Panel.mqh — NÃO incluir diretamente.
//
// v1.14 (Parte 024):
// + Price selector (cycle) para TrendFilter: CLOSE/OPEN/HIGH/LOW/MEDIAN/TYPICAL
//   m_ft_lPrice/m_ft_bPrice; m_cur_trendPrice state var
//   OnClickTrendPrice: usa CycleAppliedPrice + AppliedPriceShortText
//   OnClickApplyTrend: substituído 3 cold reloads por SetMACold() (1 única reinit)
//
// v1.13 (Parte 024):
// + Toggle ON/OFF + botão APLICAR para TrendFilter e RSIFilter
//   TrendFilter: Período MA, Método (cycle), TF (cycle), Zona Neutra
//   RSIFilter: Período, TF (cycle), Modo (radio 3), Oversold, Overbought
// + Removidos guards NULL de UpdateFiltros:
//   filtros sempre existem — SetEnabled() define estado inicial
// + OnClickTrendToggle, OnClickApplyTrend, OnClickTrendMethod, OnClickTrendTF
// + OnClickRSIFiltToggle, OnClickApplyRSIFilt, OnClickRSIFiltTF, OnClickRSIFiltMode
// + MAMethodShortText, RSIFiltModeText: helpers de texto
//
// v1.12 (Parte 024):
// + Sub-páginas: [TREND] [RSI]
// + ShowFiltrosPage, SetFiltrosPageVis, UpdateFiltrosBtnStyles
// + OnClickFiltrosTrend, OnClickFiltrosRSI

//+------------------------------------------------------------------+
//| ABA 3: FILTROS — Criar controles                                  |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabFiltros(void)
  {
   int sy = CONTENT_TOP;

// ── Botões de sub-página ──
   int sw = (PANEL_WIDTH - 40) / FILTROS_PAGE_COUNT;

   if(!m_f_btnTrend.Create(m_chart_id, PFX + "f_bTr", m_subwin,
                           5, sy, 5 + sw, sy + TAB_BTN_H))
      return false;
   m_f_btnTrend.Text("TREND");
   m_f_btnTrend.FontSize(7);
   if(!Add(m_f_btnTrend))
      return false;

   if(!m_f_btnRSI.Create(m_chart_id, PFX + "f_bRS", m_subwin,
                         5 + (sw + 2), sy, 5 + sw * 2 + 2, sy + TAB_BTN_H))
      return false;
   m_f_btnRSI.Text("RSI FILT");
   m_f_btnRSI.FontSize(7);
   if(!Add(m_f_btnRSI))
      return false;

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: TREND FILTER
// ════════════════════════════════════════════════════════════
   int y = FILTROS_CONTENT_Y;

// ── Display ──
   if(!CreateHdr(m_f_hdr1, "f_h1", "TREND FILTER", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_f_lTrendSt, m_f_eTrendSt, "f_lTS", "f_eTS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_f_lTrendMA, m_f_eTrendMA, "f_lTM", "f_eTM", "MA Tendencia:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_f_lTrendDist, m_f_eTrendDist, "f_lTD", "f_eTD", "Distancia:", y)) return false;

// ── Configurações ──
   y += PANEL_GAP_Y;
   y += PANEL_GAP_SECTION;
   if(!CreateHdr(m_ft_hdrConf, "ft_hConf", "CONFIGURACOES", y)) return false;
   y += PANEL_GAP_Y + 2;

// Toggle ON/OFF
   m_pendingTrendEnabled = (m_trendFilter != NULL) ? m_trendFilter.IsEnabled() : false;
   if(!m_f_btnTrendToggle.Create(m_chart_id, PFX + "f_bTrOn", m_subwin,
                                  COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 22))
      return false;
   m_f_btnTrendToggle.FontSize(8);
   if(!Add(m_f_btnTrendToggle)) return false;
   ApplyToggleStyle(m_f_btnTrendToggle, m_pendingTrendEnabled);
   y += 24;

// Período MA
   {
    int p = (m_trendFilter != NULL) ? m_trendFilter.GetMAPeriod() : 200;
    if(!CreateLI(m_ft_lPeriod, m_ft_iPeriod, "ft_lPd", "ft_iPd", "Periodo MA:", y)) return false;
    m_ft_iPeriod.Text(IntegerToString(p));
   }
   y += PANEL_GAP_Y;

// Método MA (radio 4: SMA|EMA|SMMA|LWMA — igual ao MA Cross)
   {
    ENUM_MA_METHOD meth = (m_trendFilter != NULL) ? m_trendFilter.GetMAMethod() : MODE_SMA;
    m_cur_trendMethod = meth;
    string methTexts[] = {"SMA", "EMA", "SMMA", "LWMA"};
    if(!CreateRadioGroup(m_ft_lMethod, m_ft_bMethod, "ft_lMt", "ft_bMt", "Metodo MA:", methTexts, 4, y))
       return false;
    SetRadioSelection(m_ft_bMethod, 4, MAMethodToIndex(meth));
   }
   y += PANEL_GAP_Y + 2;

// Time Frame (cycle)
   {
    ENUM_TIMEFRAMES tf = (m_trendFilter != NULL) ? m_trendFilter.GetMATimeframe() : PERIOD_CURRENT;
    m_cur_trendTF = tf;
    if(!CreateLB(m_ft_lTF, m_ft_bTF, "ft_lTF", "ft_bTF", "Time Frame:", y)) return false;
    m_ft_bTF.Text(TFName(tf));
    m_ft_bTF.ColorBackground(C'50,80,140'); m_ft_bTF.Color(clrWhite);
   }
   y += PANEL_GAP_Y + 2;

// Applied Price (cycle)
   {
    ENUM_APPLIED_PRICE pr = (m_trendFilter != NULL) ? m_trendFilter.GetMAApplied() : PRICE_CLOSE;
    m_cur_trendPrice = pr;
    if(!CreateLB(m_ft_lPrice, m_ft_bPrice, "ft_lPr", "ft_bPr", "Price:", y)) return false;
    m_ft_bPrice.Text(AppliedPriceShortText(pr));
    m_ft_bPrice.ColorBackground(C'50,80,140'); m_ft_bPrice.Color(clrWhite);
   }
   y += PANEL_GAP_Y + 2;

// Zona Neutra (pts)
   {
    double nd = (m_trendFilter != NULL) ? m_trendFilter.GetNeutralDistance() : 0;
    if(!CreateLI(m_ft_lNeutDist, m_ft_iNeutDist, "ft_lND", "ft_iND", "Zona Neutra (pts):", y)) return false;
    m_ft_iNeutDist.Text(DoubleToString(nd, 0));
   }
   y += PANEL_GAP_Y + 8;

// Botão APLICAR (posição fixa perto do rodapé)
   if(!m_f_btnApplyTrend.Create(m_chart_id, PFX + "f_applyTr", m_subwin,
                                 COL_LABEL_X, CFG_APPLY_Y,
                                 COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 24))
      return false;
   m_f_btnApplyTrend.Text("APLICAR TREND FILTER");
   m_f_btnApplyTrend.FontSize(9);
   m_f_btnApplyTrend.ColorBackground(C'30,120,70');
   m_f_btnApplyTrend.Color(clrWhite);
   if(!Add(m_f_btnApplyTrend)) return false;

   if(!m_f_statusTrend.Create(m_chart_id, PFX + "f_stTr", m_subwin,
                               COL_LABEL_X, CFG_APPLY_Y + 28,
                               COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 28 + PANEL_GAP_Y))
      return false;
   m_f_statusTrend.Text("");
   m_f_statusTrend.FontSize(8);
   m_f_statusTrend.Color(CLR_NEUTRAL);
   if(!Add(m_f_statusTrend)) return false;
   m_f_statusTrendExpiry = 0;

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: RSI FILTER
// ════════════════════════════════════════════════════════════
   y = FILTROS_CONTENT_Y;

// ── Display ──
   if(!CreateHdr(m_f_hdr2, "f_h2", "RSI FILTER", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_f_lRFiltSt, m_f_eRFiltSt, "f_lFS", "f_eFS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_f_lRFiltRSI, m_f_eRFiltRSI, "f_lFR", "f_eFR", "RSI Atual:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_f_lRFiltMode, m_f_eRFiltMode, "f_lFM", "f_eFM", "Modo:", y)) return false;

// ── Configurações ──
   y += PANEL_GAP_Y;
   y += PANEL_GAP_SECTION;
   if(!CreateHdr(m_frf_hdrConf, "frf_hConf", "CONFIGURACOES", y)) return false;
   y += PANEL_GAP_Y + 2;

// Toggle ON/OFF
   m_pendingRSIFiltEnabled = (m_rsiFilter != NULL) ? m_rsiFilter.IsEnabled() : false;
   if(!m_f_btnRSIFiltToggle.Create(m_chart_id, PFX + "f_bRFOn", m_subwin,
                                    COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 22))
      return false;
   m_f_btnRSIFiltToggle.FontSize(8);
   if(!Add(m_f_btnRSIFiltToggle)) return false;
   ApplyToggleStyle(m_f_btnRSIFiltToggle, m_pendingRSIFiltEnabled);
   y += 24;

// Período
   {
    int p = (m_rsiFilter != NULL) ? m_rsiFilter.GetPeriod() : 14;
    if(!CreateLI(m_frf_lPeriod, m_frf_iPeriod, "frf_lPd", "frf_iPd", "Periodo:", y)) return false;
    m_frf_iPeriod.Text(IntegerToString(p));
   }
   y += PANEL_GAP_Y;

// Time Frame (cycle)
   {
    ENUM_TIMEFRAMES tf = (m_rsiFilter != NULL) ? m_rsiFilter.GetTimeframe() : PERIOD_CURRENT;
    m_cur_rsiFiltTF = tf;
    if(!CreateLB(m_frf_lTF, m_frf_bTF, "frf_lTF", "frf_bTF", "Time Frame:", y)) return false;
    m_frf_bTF.Text(TFName(tf));
    m_frf_bTF.ColorBackground(C'50,80,140'); m_frf_bTF.Color(clrWhite);
   }
   y += PANEL_GAP_Y + 2;

// Modo (radio 3: ZONE / DIR. / NEUTRO)
   y += PANEL_GAP_SECTION;
   {
    string modeTexts[] = {"ZONE", "DIR.", "NEUTRO"};
    ENUM_RSI_FILTER_MODE fm = (m_rsiFilter != NULL) ? m_rsiFilter.GetFilterMode() : RSI_FILTER_ZONE;
    m_cur_rsiFiltMode = fm;
    if(!CreateRadioGroup(m_frf_lMode, m_frf_bMode, "frf_lMd", "frf_bMd", "Modo:", modeTexts, 3, y))
       return false;
    SetRadioSelection(m_frf_bMode, 3, (int)fm);
   }
   y += PANEL_GAP_Y + 2;

// Oversold
   {
    double os = (m_rsiFilter != NULL) ? m_rsiFilter.GetOversold() : 30.0;
    if(!CreateLI(m_frf_lOversold, m_frf_iOversold, "frf_lOS", "frf_iOS", "Oversold:", y)) return false;
    m_frf_iOversold.Text(DoubleToString(os, 1));
   }
   y += PANEL_GAP_Y;

// Overbought
   {
    double ob = (m_rsiFilter != NULL) ? m_rsiFilter.GetOverbought() : 70.0;
    if(!CreateLI(m_frf_lOverbought, m_frf_iOverbought, "frf_lOB", "frf_iOB", "Overbought:", y)) return false;
    m_frf_iOverbought.Text(DoubleToString(ob, 1));
   }
   y += PANEL_GAP_Y + 8;

// Botão APLICAR
   if(!m_f_btnApplyRSIFilt.Create(m_chart_id, PFX + "f_applyRF", m_subwin,
                                   COL_LABEL_X, CFG_APPLY_Y,
                                   COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 24))
      return false;
   m_f_btnApplyRSIFilt.Text("APLICAR RSI FILTER");
   m_f_btnApplyRSIFilt.FontSize(9);
   m_f_btnApplyRSIFilt.ColorBackground(C'30,120,70');
   m_f_btnApplyRSIFilt.Color(clrWhite);
   if(!Add(m_f_btnApplyRSIFilt)) return false;

   if(!m_f_statusRSIFilt.Create(m_chart_id, PFX + "f_stRF", m_subwin,
                                 COL_LABEL_X, CFG_APPLY_Y + 28,
                                 COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 28 + PANEL_GAP_Y))
      return false;
   m_f_statusRSIFilt.Text("");
   m_f_statusRSIFilt.FontSize(8);
   m_f_statusRSIFilt.Color(CLR_NEUTRAL);
   if(!Add(m_f_statusRSIFilt)) return false;
   m_f_statusRSIFiltExpiry = 0;

// ── Sub-página inicial ──
   ShowFiltrosPage(FILTROS_TREND);

   return true;
  }

//+------------------------------------------------------------------+
//| SetFiltrosPageVis — show/hide controles de uma sub-página         |
//+------------------------------------------------------------------+
void CEPBotPanel::SetFiltrosPageVis(ENUM_FILTROS_PAGE page, bool vis)
  {
   switch(page)
     {
      case FILTROS_TREND:
         if(vis)
           {
            m_f_hdr1.Show(); m_f_lTrendSt.Show(); m_f_eTrendSt.Show();
            m_f_lTrendMA.Show(); m_f_eTrendMA.Show(); m_f_lTrendDist.Show(); m_f_eTrendDist.Show();
            m_ft_hdrConf.Show(); m_f_btnTrendToggle.Show();
            m_ft_lPeriod.Show(); m_ft_iPeriod.Show();
            m_ft_lMethod.Show(); for(int i=0;i<4;i++) m_ft_bMethod[i].Show();
            m_ft_lTF.Show(); m_ft_bTF.Show();
            m_ft_lPrice.Show(); m_ft_bPrice.Show();
            m_ft_lNeutDist.Show(); m_ft_iNeutDist.Show();
            m_f_btnApplyTrend.Show(); m_f_statusTrend.Show();
           }
         else
           {
            m_f_hdr1.Hide(); m_f_lTrendSt.Hide(); m_f_eTrendSt.Hide();
            m_f_lTrendMA.Hide(); m_f_eTrendMA.Hide(); m_f_lTrendDist.Hide(); m_f_eTrendDist.Hide();
            m_ft_hdrConf.Hide(); m_f_btnTrendToggle.Hide();
            m_ft_lPeriod.Hide(); m_ft_iPeriod.Hide();
            m_ft_lMethod.Hide(); for(int i=0;i<4;i++) m_ft_bMethod[i].Hide();
            m_ft_lTF.Hide(); m_ft_bTF.Hide();
            m_ft_lPrice.Hide(); m_ft_bPrice.Hide();
            m_ft_lNeutDist.Hide(); m_ft_iNeutDist.Hide();
            m_f_btnApplyTrend.Hide(); m_f_statusTrend.Hide();
           }
         break;
      case FILTROS_RSI:
         if(vis)
           {
            m_f_hdr2.Show(); m_f_lRFiltSt.Show(); m_f_eRFiltSt.Show();
            m_f_lRFiltRSI.Show(); m_f_eRFiltRSI.Show(); m_f_lRFiltMode.Show(); m_f_eRFiltMode.Show();
            m_frf_hdrConf.Show(); m_f_btnRSIFiltToggle.Show();
            m_frf_lPeriod.Show(); m_frf_iPeriod.Show();
            m_frf_lTF.Show(); m_frf_bTF.Show();
            m_frf_lMode.Show(); for(int i=0;i<3;i++) m_frf_bMode[i].Show();
            m_frf_lOversold.Show(); m_frf_iOversold.Show();
            m_frf_lOverbought.Show(); m_frf_iOverbought.Show();
            m_f_btnApplyRSIFilt.Show(); m_f_statusRSIFilt.Show();
           }
         else
           {
            m_f_hdr2.Hide(); m_f_lRFiltSt.Hide(); m_f_eRFiltSt.Hide();
            m_f_lRFiltRSI.Hide(); m_f_eRFiltRSI.Hide(); m_f_lRFiltMode.Hide(); m_f_eRFiltMode.Hide();
            m_frf_hdrConf.Hide(); m_f_btnRSIFiltToggle.Hide();
            m_frf_lPeriod.Hide(); m_frf_iPeriod.Hide();
            m_frf_lTF.Hide(); m_frf_bTF.Hide();
            m_frf_lMode.Hide(); for(int i=0;i<3;i++) m_frf_bMode[i].Hide();
            m_frf_lOversold.Hide(); m_frf_iOversold.Hide();
            m_frf_lOverbought.Hide(); m_frf_iOverbought.Hide();
            m_f_btnApplyRSIFilt.Hide(); m_f_statusRSIFilt.Hide();
           }
         break;
     }
  }

//+------------------------------------------------------------------+
//| ShowFiltrosPage — alterna sub-página ativa do FILTROS             |
//+------------------------------------------------------------------+
void CEPBotPanel::ShowFiltrosPage(ENUM_FILTROS_PAGE page)
  {
   m_filtrosPage = page;
   for(int p = 0; p < FILTROS_PAGE_COUNT; p++)
      SetFiltrosPageVis((ENUM_FILTROS_PAGE)p, false);
   SetFiltrosPageVis(page, true);
   UpdateFiltrosBtnStyles();
  }

//+------------------------------------------------------------------+
//| UpdateFiltrosBtnStyles — destaque no botão da sub-página ativa    |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateFiltrosBtnStyles(void)
  {
   m_f_btnTrend.Pressed(false); m_f_btnRSI.Pressed(false);

   m_f_btnTrend.ColorBackground((m_filtrosPage == FILTROS_TREND) ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
   m_f_btnRSI.ColorBackground(  (m_filtrosPage == FILTROS_RSI)   ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);

   m_f_btnTrend.Color((m_filtrosPage == FILTROS_TREND) ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_f_btnRSI.Color(  (m_filtrosPage == FILTROS_RSI)   ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
  }

//+------------------------------------------------------------------+
//| Handlers de clique das sub-páginas FILTROS                        |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickFiltrosTrend(void) { ShowFiltrosPage(FILTROS_TREND); }
void CEPBotPanel::OnClickFiltrosRSI(void)   { ShowFiltrosPage(FILTROS_RSI); }

//+------------------------------------------------------------------+
//| UpdateFiltros — atualiza dados da aba FILTROS                     |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateFiltros(void)
  {
   if(m_filtrosPage == FILTROS_TREND)
     {
// ── Trend Filter — display ──
      if(m_trendFilter.IsInitialized())
        {
         bool active = m_trendFilter.IsEnabled();
         SetEV(m_f_eTrendSt, active ? "Ativo" : "Inativo",
               active ? CLR_POSITIVE : CLR_NEUTRAL);
         SetEV(m_f_eTrendMA, DoubleToString(m_trendFilter.GetMA(), _Digits), CLR_VALUE);
         SetEV(m_f_eTrendDist, DoubleToString(m_trendFilter.GetDistanceFromMA(), 1) + " pts", CLR_VALUE);
        }
      else
        {
         SetEV(m_f_eTrendSt, "Nao iniciado", CLR_NEUTRAL);
         SetEV(m_f_eTrendMA, "--", CLR_NEUTRAL);
         SetEV(m_f_eTrendDist, "--", CLR_NEUTRAL);
        }
// ── Trend Filter — sincronizar toggle visual ──
      ApplyToggleStyle(m_f_btnTrendToggle, m_pendingTrendEnabled);
     }
   else if(m_filtrosPage == FILTROS_RSI)
     {
// ── RSI Filter — display ──
      if(m_rsiFilter.IsInitialized())
        {
         bool active = m_rsiFilter.IsEnabled();
         SetEV(m_f_eRFiltSt, active ? "Ativo" : "Inativo",
               active ? CLR_POSITIVE : CLR_NEUTRAL);
         SetEV(m_f_eRFiltRSI, DoubleToString(m_rsiFilter.GetCurrentRSI(), 1), CLR_VALUE);
         SetEV(m_f_eRFiltMode, m_rsiFilter.GetFilterModeText(), CLR_VALUE);
        }
      else
        {
         SetEV(m_f_eRFiltSt, "Nao iniciado", CLR_NEUTRAL);
         SetEV(m_f_eRFiltRSI, "--", CLR_NEUTRAL);
         SetEV(m_f_eRFiltMode, "--", CLR_NEUTRAL);
        }
// ── RSI Filter — sincronizar toggle visual ──
      ApplyToggleStyle(m_f_btnRSIFiltToggle, m_pendingRSIFiltEnabled);
     }
  }

//+------------------------------------------------------------------+
//| TREND FILTER — Toggle ON/OFF (muda estado pendente)               |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickTrendToggle(void)
  {
   m_pendingTrendEnabled = !m_pendingTrendEnabled;
   ApplyToggleStyle(m_f_btnTrendToggle, m_pendingTrendEnabled);
  }

//+------------------------------------------------------------------+
//| TREND FILTER — APLICAR configurações                              |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickApplyTrend(void)
  {
   int    period = (int)StringToInteger(m_ft_iPeriod.Text());
   double neutDist = StringToDouble(m_ft_iNeutDist.Text());

   int errors = 0;

   if(period <= 0)
     {
      m_f_statusTrend.Text("Periodo invalido!");
      m_f_statusTrend.Color(CLR_NEGATIVE);
      m_f_statusTrendExpiry = GetTickCount() + 10000;
      errors++;
     }
   if(neutDist < 0)
     {
      m_f_statusTrend.Text("Zona neutra invalida!");
      m_f_statusTrend.Color(CLR_NEGATIVE);
      m_f_statusTrendExpiry = GetTickCount() + 10000;
      errors++;
     }
   if(errors > 0) return;

// Hot reload primeiro (sem reinit)
   m_trendFilter.SetEnabled(m_pendingTrendEnabled);
   m_trendFilter.SetTrendFilterEnabled(m_pendingTrendEnabled);
   m_trendFilter.SetNeutralDistance(neutDist);

// Cold reload: SetMACold faz 1 única reinicialização com todos os parâmetros frios
   bool coldOk = m_trendFilter.SetMACold(period, m_cur_trendMethod,
                                          m_cur_trendTF, m_cur_trendPrice);

   string msg = "Aplicado" + (m_pendingTrendEnabled ? " [ON]" : " [OFF]");
   if(!coldOk)
      msg += " (aviso: falha cold reload)";
   m_f_statusTrend.Text(msg);
   m_f_statusTrend.Color(CLR_POSITIVE);
   m_f_statusTrendExpiry = GetTickCount() + 10000;
  }

//+------------------------------------------------------------------+
//| TREND FILTER — Método MA: radio SMA|EMA|SMMA|LWMA                |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickTrendMethod(int i)
  {
   m_cur_trendMethod = IndexToMAMethod(i);
   SetRadioSelection(m_ft_bMethod, 4, i);
  }

//+------------------------------------------------------------------+
//| TREND FILTER — TF: cycle igual ao RSI/MA                          |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickTrendTF(void)
  {
   ENUM_TIMEFRAMES tfs[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30,
                             PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1,
                             PERIOD_MN1, PERIOD_CURRENT};
   int count = ArraySize(tfs);
   int cur = 0;
   for(int i = 0; i < count; i++)
      if(tfs[i] == m_cur_trendTF) { cur = i; break; }
   cur = (cur + 1) % count;
   m_cur_trendTF = tfs[cur];
   m_ft_bTF.Text(TFName(m_cur_trendTF));
  }

//+------------------------------------------------------------------+
//| TREND FILTER — Price: cycle de applied price                      |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickTrendPrice(void)
  {
   m_cur_trendPrice = CycleAppliedPrice(m_cur_trendPrice);
   m_ft_bPrice.Text(AppliedPriceShortText(m_cur_trendPrice));
  }

//+------------------------------------------------------------------+
//| RSI FILTER — Toggle ON/OFF (muda estado pendente)                 |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickRSIFiltToggle(void)
  {
   m_pendingRSIFiltEnabled = !m_pendingRSIFiltEnabled;
   ApplyToggleStyle(m_f_btnRSIFiltToggle, m_pendingRSIFiltEnabled);
  }

//+------------------------------------------------------------------+
//| RSI FILTER — APLICAR configurações                                |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickApplyRSIFilt(void)
  {
   int    period     = (int)StringToInteger(m_frf_iPeriod.Text());
   double oversold   = StringToDouble(m_frf_iOversold.Text());
   double overbought = StringToDouble(m_frf_iOverbought.Text());

   int errors = 0;

   if(period <= 0)
     {
      m_f_statusRSIFilt.Text("Periodo invalido!");
      m_f_statusRSIFilt.Color(CLR_NEGATIVE);
      m_f_statusRSIFiltExpiry = GetTickCount() + 10000;
      errors++;
     }
   if(oversold <= 0 || oversold >= 100)
     {
      m_f_statusRSIFilt.Text("Oversold invalido!");
      m_f_statusRSIFilt.Color(CLR_NEGATIVE);
      m_f_statusRSIFiltExpiry = GetTickCount() + 10000;
      errors++;
     }
   if(overbought <= 0 || overbought >= 100 || overbought <= oversold)
     {
      m_f_statusRSIFilt.Text("Overbought invalido!");
      m_f_statusRSIFilt.Color(CLR_NEGATIVE);
      m_f_statusRSIFiltExpiry = GetTickCount() + 10000;
      errors++;
     }
   if(errors > 0) return;

// Parâmetros quentes (sem reinit)
   m_rsiFilter.SetEnabled(m_pendingRSIFiltEnabled);
   m_rsiFilter.SetFilterMode(m_cur_rsiFiltMode);
   m_rsiFilter.SetOversold(oversold);
   m_rsiFilter.SetOverbought(overbought);

// Período e TF são cold reload (chamam Deinitialize/Initialize)
   m_rsiFilter.SetPeriod(period);
   m_rsiFilter.SetTimeframe(m_cur_rsiFiltTF);

   string msg = "Aplicado" + (m_pendingRSIFiltEnabled ? " [ON]" : " [OFF]");
   m_f_statusRSIFilt.Text(msg);
   m_f_statusRSIFilt.Color(CLR_POSITIVE);
   m_f_statusRSIFiltExpiry = GetTickCount() + 10000;
  }

//+------------------------------------------------------------------+
//| RSI FILTER — TF: cycle                                            |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickRSIFiltTF(void)
  {
   ENUM_TIMEFRAMES tfs[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30,
                             PERIOD_H1, PERIOD_H4, PERIOD_D1, PERIOD_W1,
                             PERIOD_MN1, PERIOD_CURRENT};
   int count = ArraySize(tfs);
   int cur = 0;
   for(int i = 0; i < count; i++)
      if(tfs[i] == m_cur_rsiFiltTF) { cur = i; break; }
   cur = (cur + 1) % count;
   m_cur_rsiFiltTF = tfs[cur];
   m_frf_bTF.Text(TFName(m_cur_rsiFiltTF));
  }

//+------------------------------------------------------------------+
//| RSI FILTER — Modo: radio (ZONE=0 / DIR=1 / NEUTRO=2)             |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickRSIFiltMode(int i)
  {
   m_cur_rsiFiltMode = (ENUM_RSI_FILTER_MODE)i;
   SetRadioSelection(m_frf_bMode, 3, i);
  }

//+------------------------------------------------------------------+
//| RSIFiltModeText — texto curto para enum RSI Filter mode           |
//+------------------------------------------------------------------+
string CEPBotPanel::RSIFiltModeText(ENUM_RSI_FILTER_MODE mode)
  {
   switch(mode)
     {
      case RSI_FILTER_ZONE:      return "ZONE";
      case RSI_FILTER_DIRECTION: return "DIR.";
      case RSI_FILTER_NEUTRAL:   return "NEUTRO";
     }
   return "?";
  }

//+------------------------------------------------------------------+
//| MAMethodShortText — texto curto para método MA                    |
//+------------------------------------------------------------------+
string CEPBotPanel::MAMethodShortText(ENUM_MA_METHOD method)
  {
   switch(method)
     {
      case MODE_SMA:  return "SMA";
      case MODE_EMA:  return "EMA";
      case MODE_SMMA: return "SMMA";
      case MODE_LWMA: return "LWMA";
     }
   return "SMA";
  }
//+------------------------------------------------------------------+
