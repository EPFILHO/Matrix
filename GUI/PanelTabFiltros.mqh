//+------------------------------------------------------------------+
//|                                            PanelTabFiltros.mqh   |
//|                                         Copyright 2026, EP Filho |
//|          Panel Tab: FILTROS — Create + Update                     |
//|                     Versão 1.12 - Claude Parte 024 (Claude Code) |
//+------------------------------------------------------------------+
// Implementações de CEPBotPanel para a aba FILTROS.
// Incluído por Panel.mqh — NÃO incluir diretamente.
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
   m_f_btnRSI.Text("RSI");
   m_f_btnRSI.FontSize(7);
   if(!Add(m_f_btnRSI))
      return false;

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: TREND FILTER
// ════════════════════════════════════════════════════════════
   int y = FILTROS_CONTENT_Y;

   if(!CreateHdr(m_f_hdr1, "f_h1", "TREND FILTER", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_f_lTrendSt, m_f_eTrendSt, "f_lTS", "f_eTS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_f_lTrendMA, m_f_eTrendMA, "f_lTM", "f_eTM", "MA Tendencia:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_f_lTrendDist, m_f_eTrendDist, "f_lTD", "f_eTD", "Distancia:", y)) return false;

// ════════════════════════════════════════════════════════════
// SUB-PÁGINA: RSI FILTER
// ════════════════════════════════════════════════════════════
   y = FILTROS_CONTENT_Y;

   if(!CreateHdr(m_f_hdr2, "f_h2", "RSI FILTER", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_f_lRFiltSt, m_f_eRFiltSt, "f_lFS", "f_eFS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_f_lRFiltRSI, m_f_eRFiltRSI, "f_lFR", "f_eFR", "RSI Atual:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_f_lRFiltMode, m_f_eRFiltMode, "f_lFM", "f_eFM", "Modo:", y)) return false;

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
         if(vis) { m_f_hdr1.Show(); m_f_lTrendSt.Show(); m_f_eTrendSt.Show();
                    m_f_lTrendMA.Show(); m_f_eTrendMA.Show(); m_f_lTrendDist.Show(); m_f_eTrendDist.Show(); }
         else    { m_f_hdr1.Hide(); m_f_lTrendSt.Hide(); m_f_eTrendSt.Hide();
                    m_f_lTrendMA.Hide(); m_f_eTrendMA.Hide(); m_f_lTrendDist.Hide(); m_f_eTrendDist.Hide(); }
         break;
      case FILTROS_RSI:
         if(vis) { m_f_hdr2.Show(); m_f_lRFiltSt.Show(); m_f_eRFiltSt.Show();
                    m_f_lRFiltRSI.Show(); m_f_eRFiltRSI.Show(); m_f_lRFiltMode.Show(); m_f_eRFiltMode.Show(); }
         else    { m_f_hdr2.Hide(); m_f_lRFiltSt.Hide(); m_f_eRFiltSt.Hide();
                    m_f_lRFiltRSI.Hide(); m_f_eRFiltRSI.Hide(); m_f_lRFiltMode.Hide(); m_f_eRFiltMode.Hide(); }
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
// ── Trend Filter ──
      if(m_trendFilter != NULL && m_trendFilter.IsInitialized())
        {
         SetEV(m_f_eTrendSt, m_trendFilter.IsTrendFilterActive() ? "Ativo" : "Inativo",
               m_trendFilter.IsTrendFilterActive() ? CLR_POSITIVE : CLR_NEUTRAL);
         SetEV(m_f_eTrendMA, DoubleToString(m_trendFilter.GetMA(), _Digits), CLR_VALUE);
         SetEV(m_f_eTrendDist, DoubleToString(m_trendFilter.GetDistanceFromMA(), 1) + " pts", CLR_VALUE);
        }
      else
        {
         SetEV(m_f_eTrendSt, "Inativo", CLR_NEUTRAL);
         SetEV(m_f_eTrendMA, "--", CLR_NEUTRAL);
         SetEV(m_f_eTrendDist, "--", CLR_NEUTRAL);
        }
     }
   else if(m_filtrosPage == FILTROS_RSI)
     {
// ── RSI Filter ──
      if(m_rsiFilter != NULL && m_rsiFilter.IsInitialized())
        {
         SetEV(m_f_eRFiltSt, m_rsiFilter.IsEnabled() ? "Ativo" : "Desabilitado",
               m_rsiFilter.IsEnabled() ? CLR_POSITIVE : CLR_NEUTRAL);
         SetEV(m_f_eRFiltRSI, DoubleToString(m_rsiFilter.GetCurrentRSI(), 1), CLR_VALUE);
         SetEV(m_f_eRFiltMode, m_rsiFilter.GetFilterModeText(), CLR_VALUE);
        }
      else
        {
         SetEV(m_f_eRFiltSt, "Inativo", CLR_NEUTRAL);
         SetEV(m_f_eRFiltRSI, "--", CLR_NEUTRAL);
         SetEV(m_f_eRFiltMode, "--", CLR_NEUTRAL);
        }
     }
  }
//+------------------------------------------------------------------+
