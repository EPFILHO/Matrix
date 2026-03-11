//+------------------------------------------------------------------+
//|                                            PanelTabFiltros.mqh   |
//|                                         Copyright 2026, EP Filho |
//|          Panel Tab: FILTROS — orquestração genérica               |
//|                     Versão 1.17 - Claude Parte 025 (Claude Code) |
//+------------------------------------------------------------------+
// v1.17 (Parte 025):
// REESCRITO: orquestração genérica via CFilterPanelBase[]
//   Mesma estrutura de PanelTabEstrategias v1.26
//   CreateTabFiltros: cria botão GERAL + 1 por painel registrado
//   SetFiltrosPageVis(int): page=0 → GERAL labels; page>0 → panel.Show/Hide
//   ShowFiltrosPage(int): esconde todos, mostra page selecionado
//   UpdateFiltrosBtnStyles(): loop sobre m_f_filtBtns[]
//   UpdateFiltros(): page=0 → loop genérico; page>0 → panel.Update()
//   Adicionar novo filtro: RegisterPanels() + 0 linhas aqui
//
// v1.16 (Parte 025): sub-página GERAL genérica
// v1.12–1.15: histórico anterior (Trend + RSI Filter hard-coded)

//+------------------------------------------------------------------+
//| ABA 3: FILTROS — Criar controles                                  |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabFiltros(void)
  {
   int sy = CONTENT_TOP;
   int totalBtns = 1 + m_filtPanelCount;  // GERAL + N painéis
   m_filtBtnCount = totalBtns;
   int sw = (PANEL_WIDTH - 40) / MathMax(totalBtns, 1);

// ── Botão GERAL (índice 0) ──
   if(!m_f_filtBtns[0].Create(m_chart_id, PFX + "f_fb0", m_subwin,
                              5, sy, 5 + sw, sy + TAB_BTN_H))
      return false;
   m_f_filtBtns[0].Text("GERAL");
   m_f_filtBtns[0].FontSize(7);
   if(!Add(m_f_filtBtns[0])) return false;

// ── Botões dos painéis (índices 1..N) ──
   for(int i = 0; i < m_filtPanelCount; i++)
     {
      int idx = i + 1;
      int x1 = 5 + idx * (sw + 2);
      int x2 = x1 + sw;
      if(!m_f_filtBtns[idx].Create(m_chart_id, PFX + "f_fb" + IntegerToString(idx), m_subwin,
                                   x1, sy, x2, sy + TAB_BTN_H))
         return false;
      m_f_filtBtns[idx].Text(m_filtPanels[i].GetName());
      m_f_filtBtns[idx].FontSize(7);
      if(!Add(m_f_filtBtns[idx])) return false;
     }

// ── Sub-página GERAL ──
   {
    int yov = FILTROS_CONTENT_Y;
    if(!CreateHdr(m_ov_lFiltHdr, "ov_fHdr", "FILTROS REGISTRADOS", yov)) return false;
    yov += PANEL_GAP_Y + 2;

    for(int i = 0; i < MAX_OVERVIEW_ROWS; i++)
      {
       string si = IntegerToString(i);
       if(!m_ov_eFiltName[i].Create(m_chart_id, PFX + "ov_fN" + si, m_subwin,
                                    COL_LABEL_X, yov, COL_VALUE_X - 4, yov + PANEL_GAP_Y))
          return false;
       m_ov_eFiltName[i].FontSize(8);
       m_ov_eFiltName[i].Color(CLR_VALUE);
       m_ov_eFiltName[i].Text("");
       if(!Add(m_ov_eFiltName[i])) return false;
       m_ov_eFiltName[i].Hide();

       if(!m_ov_eFiltStatus[i].Create(m_chart_id, PFX + "ov_fS" + si, m_subwin,
                                      COL_VALUE_X, yov, COL_VALUE_X + COL_VALUE_W, yov + PANEL_GAP_Y))
          return false;
       m_ov_eFiltStatus[i].FontSize(8);
       m_ov_eFiltStatus[i].Color(CLR_NEUTRAL);
       m_ov_eFiltStatus[i].Text("");
       if(!Add(m_ov_eFiltStatus[i])) return false;
       m_ov_eFiltStatus[i].Hide();

       yov += PANEL_GAP_Y;
      }
   }

// ── Criar controles de cada painel ──
   for(int i = 0; i < m_filtPanelCount; i++)
     {
      if(!m_filtPanels[i].Create(this, m_chart_id, m_subwin)) return false;
     }

// ── Sub-página inicial ──
   ShowFiltrosPage(m_filtPanelCount > 0 ? 1 : 0);

   return true;
  }

//+------------------------------------------------------------------+
//| SetFiltrosPageVis — show/hide controles de uma sub-página         |
//+------------------------------------------------------------------+
void CEPBotPanel::SetFiltrosPageVis(int page, bool vis)
  {
   if(page == 0)
     {
      // GERAL
      if(vis) m_ov_lFiltHdr.Show(); else m_ov_lFiltHdr.Hide();
      if(!vis)
        {
         for(int i = 0; i < MAX_OVERVIEW_ROWS; i++)
           { m_ov_eFiltName[i].Hide(); m_ov_eFiltStatus[i].Hide(); }
        }
     }
   else
     {
      int idx = page - 1;
      if(idx >= 0 && idx < m_filtPanelCount && m_filtPanels[idx] != NULL)
        {
         if(vis) m_filtPanels[idx].Show();
         else    m_filtPanels[idx].Hide();
        }
     }
  }

//+------------------------------------------------------------------+
//| ShowFiltrosPage — alterna sub-página ativa                        |
//+------------------------------------------------------------------+
void CEPBotPanel::ShowFiltrosPage(int page)
  {
   m_filtrosPage = page;
   SetFiltrosPageVis(0, false);
   for(int i = 0; i < m_filtPanelCount; i++)
      SetFiltrosPageVis(i + 1, false);
   SetFiltrosPageVis(page, true);
   UpdateFiltrosBtnStyles();
  }

//+------------------------------------------------------------------+
//| UpdateFiltrosBtnStyles — destaque no botão da sub-página ativa    |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateFiltrosBtnStyles(void)
  {
   for(int i = 0; i < m_filtBtnCount; i++)
     {
      m_f_filtBtns[i].Pressed(false);
      bool active = (i == m_filtrosPage);
      m_f_filtBtns[i].ColorBackground(active ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
      m_f_filtBtns[i].Color(active ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
     }
  }

//+------------------------------------------------------------------+
//| UpdateFiltros — atualiza dados da aba FILTROS                     |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateFiltros(void)
  {
   if(m_filtrosPage == 0)
     {
      // GERAL: lista genérica via SignalManager
      int count = (m_signalManager != NULL) ? m_signalManager.GetFilterCount() : 0;
      for(int i = 0; i < MAX_OVERVIEW_ROWS; i++)
        {
         if(i < count)
           {
            CFilterBase *f = m_signalManager.GetFilter(i);
            if(f != NULL)
              {
               m_ov_eFiltName[i].Text(f.GetName());
               bool en = f.IsEnabled();
               m_ov_eFiltStatus[i].Text(f.GetStatusSummary());
               m_ov_eFiltStatus[i].Color(en ? CLR_POSITIVE : CLR_NEUTRAL);
               m_ov_eFiltName[i].Show();
               m_ov_eFiltStatus[i].Show();
              }
           }
         else
           {
            m_ov_eFiltName[i].Hide();
            m_ov_eFiltStatus[i].Hide();
           }
        }
     }
   else
     {
      int idx = m_filtrosPage - 1;
      if(idx >= 0 && idx < m_filtPanelCount && m_filtPanels[idx] != NULL)
         m_filtPanels[idx].Update();
     }
  }
//+------------------------------------------------------------------+
