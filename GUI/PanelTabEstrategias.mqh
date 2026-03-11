//+------------------------------------------------------------------+
//|                                         PanelTabEstrategias.mqh  |
//|                                         Copyright 2026, EP Filho |
//|          Panel Tab: ESTRATEGIAS — orquestração genérica           |
//|                     Versão 1.26 - Claude Parte 027 (Claude Code) |
//+------------------------------------------------------------------+
// v1.26 (Parte 027):
// REESCRITO: orquestração genérica via CStrategyPanelBase[]
//   CreateTabEstrategias: cria botão GERAL + 1 por painel registrado
//   SetEstratPageVis(int): page=0 → GERAL labels; page>0 → panel.Show/Hide
//   ShowEstratPage(int): esconde todos, mostra page selecionado
//   UpdateEstratBtnStyles(): loop sobre m_e_stratBtns[]
//   UpdateEstrategias(): page=0 → loop genérico; page>0 → panel.Update()
//   Adicionar nova estratégia: RegisterPanels() + 0 linhas aqui
//
// v1.25 (Parte 026): sub-página GERAL genérica
// v1.13–1.24: histórico anterior (MA Cross + RSI hard-coded)

//+------------------------------------------------------------------+
//| ABA 2: ESTRATEGIAS — Criar controles                              |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabEstrategias(void)
  {
   int sy = CONTENT_TOP;
   int totalBtns = 1 + m_stratPanelCount;  // GERAL + N painéis
   m_stratBtnCount = totalBtns;
   int sw = (PANEL_WIDTH - 40) / MathMax(totalBtns, 1);

// ── Botão GERAL (índice 0) ──
   if(!m_e_stratBtns[0].Create(m_chart_id, PFX + "e_sb0", m_subwin,
                               5, sy, 5 + sw, sy + TAB_BTN_H))
      return false;
   m_e_stratBtns[0].Text("GERAL");
   m_e_stratBtns[0].FontSize(7);
   if(!Add(m_e_stratBtns[0])) return false;

// ── Botões dos painéis (índices 1..N) ──
   for(int i = 0; i < m_stratPanelCount; i++)
     {
      int idx = i + 1;
      int x1 = 5 + idx * (sw + 2);
      int x2 = x1 + sw;
      if(!m_e_stratBtns[idx].Create(m_chart_id, PFX + "e_sb" + IntegerToString(idx), m_subwin,
                                    x1, sy, x2, sy + TAB_BTN_H))
         return false;
      m_e_stratBtns[idx].Text(m_stratPanels[i].GetName());
      m_e_stratBtns[idx].FontSize(7);
      if(!Add(m_e_stratBtns[idx])) return false;
     }

// ── Sub-página GERAL ──
   {
    int yov = ESTRAT_CONTENT_Y;
    if(!CreateHdr(m_ov_lStrHdr, "ov_sHdr", "ESTRATEGIAS REGISTRADAS", yov)) return false;
    yov += PANEL_GAP_Y + 2;

    for(int i = 0; i < MAX_OVERVIEW_ROWS; i++)
      {
       string si = IntegerToString(i);
       if(!m_ov_eStrName[i].Create(m_chart_id, PFX + "ov_sN" + si, m_subwin,
                                   COL_LABEL_X, yov, COL_VALUE_X - 4, yov + PANEL_GAP_Y))
          return false;
       m_ov_eStrName[i].FontSize(8);
       m_ov_eStrName[i].Color(CLR_VALUE);
       m_ov_eStrName[i].Text("");
       if(!Add(m_ov_eStrName[i])) return false;
       m_ov_eStrName[i].Hide();

       if(!m_ov_eStrStatus[i].Create(m_chart_id, PFX + "ov_sS" + si, m_subwin,
                                     COL_VALUE_X, yov, COL_VALUE_X + COL_VALUE_W, yov + PANEL_GAP_Y))
          return false;
       m_ov_eStrStatus[i].FontSize(8);
       m_ov_eStrStatus[i].Color(CLR_NEUTRAL);
       m_ov_eStrStatus[i].Text("");
       if(!Add(m_ov_eStrStatus[i])) return false;
       m_ov_eStrStatus[i].Hide();

       yov += PANEL_GAP_Y;
      }
   }

// ── Criar controles de cada painel ──
   for(int i = 0; i < m_stratPanelCount; i++)
     {
      if(!m_stratPanels[i].Create(this, m_chart_id, m_subwin)) return false;
     }

// ── Sub-página inicial ──
   ShowEstratPage(m_stratPanelCount > 0 ? 1 : 0);

   return true;
  }

//+------------------------------------------------------------------+
//| SetEstratPageVis — show/hide controles de uma sub-página          |
//+------------------------------------------------------------------+
void CEPBotPanel::SetEstratPageVis(int page, bool vis)
  {
   if(page == 0)
     {
      // GERAL
      if(vis) m_ov_lStrHdr.Show(); else m_ov_lStrHdr.Hide();
      if(!vis)
        {
         for(int i = 0; i < MAX_OVERVIEW_ROWS; i++)
           { m_ov_eStrName[i].Hide(); m_ov_eStrStatus[i].Hide(); }
        }
      // Quando vis=true as linhas são exibidas no próximo UpdateEstrategias()
     }
   else
     {
      int idx = page - 1;
      if(idx >= 0 && idx < m_stratPanelCount && m_stratPanels[idx] != NULL)
        {
         if(vis) m_stratPanels[idx].Show();
         else    m_stratPanels[idx].Hide();
        }
     }
  }

//+------------------------------------------------------------------+
//| ShowEstratPage — alterna sub-página ativa                         |
//+------------------------------------------------------------------+
void CEPBotPanel::ShowEstratPage(int page)
  {
   m_estratPage = page;
   SetEstratPageVis(0, false);
   for(int i = 0; i < m_stratPanelCount; i++)
      SetEstratPageVis(i + 1, false);
   SetEstratPageVis(page, true);
   UpdateEstratBtnStyles();
  }

//+------------------------------------------------------------------+
//| UpdateEstratBtnStyles — destaque no botão da sub-página ativa     |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateEstratBtnStyles(void)
  {
   for(int i = 0; i < m_stratBtnCount; i++)
     {
      m_e_stratBtns[i].Pressed(false);
      bool active = (i == m_estratPage);
      m_e_stratBtns[i].ColorBackground(active ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
      m_e_stratBtns[i].Color(active ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
     }
  }

//+------------------------------------------------------------------+
//| UpdateEstrategias — atualiza dados da aba ESTRATEGIAS             |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateEstrategias(void)
  {
   if(m_estratPage == 0)
     {
      // GERAL: lista genérica via SignalManager
      int count = (m_signalManager != NULL) ? m_signalManager.GetStrategyCount() : 0;
      for(int i = 0; i < MAX_OVERVIEW_ROWS; i++)
        {
         if(i < count)
           {
            CStrategyBase *s = m_signalManager.GetStrategy(i);
            if(s != NULL)
              {
               m_ov_eStrName[i].Text(s.GetName());
               bool en = s.GetEnabled();
               m_ov_eStrStatus[i].Text(s.GetStatusSummary());
               m_ov_eStrStatus[i].Color(en ? CLR_POSITIVE : CLR_NEUTRAL);
               m_ov_eStrName[i].Show();
               m_ov_eStrStatus[i].Show();
              }
           }
         else
           {
            m_ov_eStrName[i].Hide();
            m_ov_eStrStatus[i].Hide();
           }
        }
     }
   else
     {
      int idx = m_estratPage - 1;
      if(idx >= 0 && idx < m_stratPanelCount && m_stratPanels[idx] != NULL)
         m_stratPanels[idx].Update();
     }
  }
//+------------------------------------------------------------------+
