//+------------------------------------------------------------------+
//|                                            PanelTabFiltros.mqh   |
//|                                         Copyright 2026, EP Filho |
//|          Panel Tab: FILTROS — Create + Update                     |
//|                     Versão 1.11 - Claude Parte 022 (Claude Code) |
//+------------------------------------------------------------------+
// Implementações de CEPBotPanel para a aba FILTROS.
// Incluído por Panel.mqh — NÃO incluir diretamente.

//+------------------------------------------------------------------+
//| ABA 3: FILTROS — Criar controles                                  |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabFiltros(void)
  {
   int y = CONTENT_TOP;

   if(!CreateHdr(m_f_hdr1, "f_h1", "TREND FILTER", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_f_lTrendSt, m_f_eTrendSt, "f_lTS", "f_eTS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_f_lTrendMA, m_f_eTrendMA, "f_lTM", "f_eTM", "MA Tendencia:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_f_lTrendDist, m_f_eTrendDist, "f_lTD", "f_eTD", "Distancia:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_f_hdr2, "f_h2", "RSI FILTER", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_f_lRFiltSt, m_f_eRFiltSt, "f_lFS", "f_eFS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_f_lRFiltRSI, m_f_eRFiltRSI, "f_lFR", "f_eFR", "RSI Atual:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_f_lRFiltMode, m_f_eRFiltMode, "f_lFM", "f_eFM", "Modo:", y)) return false;

   return true;
  }

//+------------------------------------------------------------------+
//| UpdateFiltros — atualiza dados da aba FILTROS                     |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateFiltros(void)
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
//+------------------------------------------------------------------+
