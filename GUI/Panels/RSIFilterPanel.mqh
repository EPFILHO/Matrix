//+------------------------------------------------------------------+
//|                                              RSIFilterPanel.mqh  |
//|                                         Copyright 2026, EP Filho |
//|         Sub-página GUI — RSI Filter                               |
//|                     Versão 1.05 - Claude Parte 027 (Claude Code) |
//+------------------------------------------------------------------+
// Incluído por Panel.mqh APÓS a definição completa de CEPBotPanel.
// NÃO incluir diretamente.
//
// CHANGELOG v1.05 (Parte 027) — Bugfix:
// * Fix: trailing comma na lista de inicialização do construtor
//
// CHANGELOG v1.04 (Parte 027) — Fase 2: Controle de Estado:
// * Removido botão APLICAR (m_btnApply) — aplicação centralizada
// * _OnApply convertido para Apply() público; adicionado SetEnabled()
//
// CHANGELOG v1.03 (Parte 027):
// + SetFilter(): setter tipado para re-injeção de ponteiro
//   (usado por ReconnectModules e config persistence)
//+------------------------------------------------------------------+

class CRSIFilterPanel : public CFilterPanelBase
  {
private:
   CRSIFilter       *m_filter;

   // Estado pendente
   bool               m_pendingEnabled;
   ENUM_TIMEFRAMES    m_cur_TF;
   ENUM_RSI_FILTER_MODE m_cur_mode;

   // Controles — display
   CLabel   m_hdr;
   CLabel   m_lStatus;  CLabel  m_eStatus;
   CLabel   m_lRSI;     CLabel  m_eRSI;
   CLabel   m_lMode;    CLabel  m_eMode;

   // Controles — config
   CLabel   m_hdrConf;
   CButton  m_btnToggle;
   CLabel   m_lPeriod;   CEdit   m_iPeriod;
   CLabel   m_lTF;       CButton m_bTF;
   CLabel   m_lMode2;    CButton m_bMode[3];
   CLabel   m_lModeDesc;
   CLabel   m_lOversold;   CEdit m_iOversold;
   CLabel   m_lOverbought; CEdit m_iOverbought;

public:
   CRSIFilterPanel(CRSIFilter *filter)
      : m_filter(filter),
        m_pendingEnabled(false),
        m_cur_TF(PERIOD_CURRENT),
        m_cur_mode(RSI_FILTER_ZONE)
     {}

   virtual string GetName(void) const { return "RSI FILT"; }
   void           SetFilter(CRSIFilter *f) { m_filter = f; }

   virtual bool Create(CEPBotPanel *parent, long chart_id, int subwin)
     {
      m_parent   = parent;
      m_chart_id = chart_id;
      m_subwin   = subwin;
      int y = FILTROS_CONTENT_Y;

      // Display
      if(!parent.CreateHdr(m_hdr, "f_h2", "RSI FILTER", y)) return false;
      y += PANEL_GAP_Y + 2;
      if(!parent.CreateLV(m_lStatus, m_eStatus, "f_lFS", "f_eFS", "Status:",    y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lRSI,   m_eRSI,   "f_lFR", "f_eFR", "RSI Atual:", y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lMode,  m_eMode,  "f_lFM", "f_eFM", "Modo:",      y)) return false;

      // Config
      y += PANEL_GAP_Y;
      y += PANEL_GAP_SECTION;
      if(!parent.CreateHdr(m_hdrConf, "frf_hConf", "CONFIGURACOES", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Toggle
      m_pendingEnabled = (m_filter != NULL) ? m_filter.IsEnabled() : false;
      if(!m_btnToggle.Create(chart_id, PFX + "f_bRFOn", subwin,
                             COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 22))
         return false;
      m_btnToggle.FontSize(8);
      if(!parent.AddControl(m_btnToggle)) return false;
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      y += 24;

      // Período
      {
       int p = (m_filter != NULL) ? m_filter.GetPeriod() : 14;
       if(!parent.CreateLI(m_lPeriod, m_iPeriod, "frf_lPd", "frf_iPd", "Periodo:", y)) return false;
       m_iPeriod.Text(IntegerToString(p));
      }
      y += PANEL_GAP_Y;

      // Time Frame
      {
       ENUM_TIMEFRAMES tf = (m_filter != NULL) ? m_filter.GetTimeframe() : PERIOD_CURRENT;
       m_cur_TF = tf;
       if(!parent.CreateLB(m_lTF, m_bTF, "frf_lTF", "frf_bTF", "Time Frame:", y)) return false;
       m_bTF.Text(TFName(tf));
       m_bTF.ColorBackground(C'50,80,140'); m_bTF.Color(clrWhite);
      }
      y += PANEL_GAP_Y + 2;

      // Modo (radio 3)
      y += PANEL_GAP_SECTION;
      {
       ENUM_RSI_FILTER_MODE fm = (m_filter != NULL) ? m_filter.GetFilterMode() : RSI_FILTER_ZONE;
       m_cur_mode = fm;
       string modeTexts[] = {"ZONA", "DIREÇÃO", "NEUTRO"};
       if(!parent.CreateRadioGroup(m_lMode2, m_bMode, "frf_lMd", "frf_bMd", "Modo:", modeTexts, 3, y))
          return false;
       SetRadioSel(m_bMode, 3, (int)fm);
      }
      y += PANEL_GAP_Y + 2;

      // Legenda dinâmica do modo
      if(!m_lModeDesc.Create(chart_id, PFX + "frf_lMDesc", subwin,
                              COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lModeDesc.Font("Tahoma"); m_lModeDesc.FontSize(7); m_lModeDesc.Color(CLR_NEUTRAL);
      m_lModeDesc.Text(_ModeDesc(m_cur_mode));
      if(!parent.AddControl(m_lModeDesc)) return false;
      y += 15;

      // Sobrevendido
      {
       double os = (m_filter != NULL) ? m_filter.GetOversold() : 30.0;
       if(!parent.CreateLI(m_lOversold, m_iOversold, "frf_lOS", "frf_iOS", "Sobrevendido (OS):", y)) return false;
       m_iOversold.Text(DoubleToString(os, 1));
      }
      y += PANEL_GAP_Y;

      // Overbought
      {
       double ob = (m_filter != NULL) ? m_filter.GetOverbought() : 70.0;
       if(!parent.CreateLI(m_lOverbought, m_iOverbought, "frf_lOB", "frf_iOB", "Sobrecomprado (OB):", y)) return false;
       m_iOverbought.Text(DoubleToString(ob, 1));
      }
      y += PANEL_GAP_Y + 8;

      return true;
     }

   virtual void Show(void)
     {
      m_hdr.Show();
      m_lStatus.Show(); m_eStatus.Show();
      m_lRSI.Show(); m_eRSI.Show();
      m_lMode.Show(); m_eMode.Show();
      m_hdrConf.Show(); m_btnToggle.Show();
      m_lPeriod.Show(); m_iPeriod.Show();
      m_lTF.Show(); m_bTF.Show();
      m_lMode2.Show(); for(int i = 0; i < 3; i++) m_bMode[i].Show();
      m_lModeDesc.Show();
      m_lOversold.Show(); m_iOversold.Show();
      m_lOverbought.Show(); m_iOverbought.Show();
     }

   virtual void Hide(void)
     {
      m_hdr.Hide();
      m_lStatus.Hide(); m_eStatus.Hide();
      m_lRSI.Hide(); m_eRSI.Hide();
      m_lMode.Hide(); m_eMode.Hide();
      m_hdrConf.Hide(); m_btnToggle.Hide();
      m_lPeriod.Hide(); m_iPeriod.Hide();
      m_lTF.Hide(); m_bTF.Hide();
      m_lMode2.Hide(); for(int i = 0; i < 3; i++) m_bMode[i].Hide();
      m_lModeDesc.Hide();
      m_lOversold.Hide(); m_iOversold.Hide();
      m_lOverbought.Hide(); m_iOverbought.Hide();
     }

   virtual void Update(void)
     {
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      m_lModeDesc.Text(_ModeDesc(m_cur_mode));
      if(m_filter != NULL && m_filter.IsInitialized())
        {
         bool active = m_filter.IsEnabled();
         m_eStatus.Text(active ? "Ativo" : "Inativo");
         m_eStatus.Color(active ? CLR_POSITIVE : CLR_NEUTRAL);
         m_eRSI.Text(DoubleToString(m_filter.GetCurrentRSI(), 1));
         m_eRSI.Color(CLR_VALUE);
         m_eMode.Text(m_filter.GetFilterModeText());
         m_eMode.Color(CLR_VALUE);
        }
      else
        {
         m_eStatus.Text("Não iniciado"); m_eStatus.Color(CLR_NEUTRAL);
         m_eRSI.Text("--");             m_eRSI.Color(CLR_NEUTRAL);
         m_eMode.Text("--");            m_eMode.Color(CLR_NEUTRAL);
        }
      _RefreshFieldState();
     }

   virtual bool OnClick(string name)
     {
      if(name == m_btnToggle.Name())
        {
         m_btnToggle.Pressed(false);
         m_pendingEnabled = !m_pendingEnabled;
         ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
         return true;
        }
      if(name == m_bTF.Name())
        {
         m_bTF.Pressed(false);
         m_cur_TF = CycleTF(m_cur_TF);
         m_bTF.Text(TFName(m_cur_TF));
         return true;
        }
      for(int i = 0; i < 3; i++)
         if(name == m_bMode[i].Name())
           { m_cur_mode = (ENUM_RSI_FILTER_MODE)i; SetRadioSel(m_bMode, 3, i); m_lModeDesc.Text(_ModeDesc(m_cur_mode)); _RefreshFieldState(); return true; }
      return false;
     }

public:
   bool Apply(void)
     {
      if(m_filter == NULL)
         return false;

      int    period     = (int)StringToInteger(m_iPeriod.Text());
      double oversold   = StringToDouble(m_iOversold.Text());
      double overbought = StringToDouble(m_iOverbought.Text());

      if(period < 2 || period > 500)
         return false;
      if(m_cur_mode != RSI_FILTER_NEUTRAL)
        {
         if(oversold <= 0 || oversold >= 100)
            return false;
         if(overbought <= 0 || overbought >= 100)
            return false;
         if(overbought <= oversold)
            return false;
        }

      m_filter.SetEnabled(m_pendingEnabled);
      m_filter.SetFilterMode(m_cur_mode);
      m_filter.SetOversold(oversold);
      m_filter.SetOverbought(overbought);
      m_filter.SetPeriod(period);
      m_filter.SetTimeframe(m_cur_TF);
      return true;
     }

   void SetEnabled(bool enable)
     {
      color bg = enable ? clrWhite : C'60,60,60';
      m_iPeriod.ReadOnly(!enable);     m_iPeriod.ColorBackground(bg);
      m_iOversold.ReadOnly(!enable);   m_iOversold.ColorBackground(bg);
      m_iOverbought.ReadOnly(!enable); m_iOverbought.ColorBackground(bg);
     }

private:
   string _ModeDesc(ENUM_RSI_FILTER_MODE mode)
     {
      switch(mode)
        {
         case RSI_FILTER_ZONE:    return "ZONA: bloqueia se RSI em zona extrema";
         case RSI_FILTER_DIRECTION: return "DIREÇÃO: só permite trades na direção do RSI";
         case RSI_FILTER_NEUTRAL: return "NEUTRO: bloqueia se RSI entre 40 e 60";
         default:                 return "";
        }
     }

   void _RefreshFieldState(void)
     {
      bool showLevels = (m_cur_mode != RSI_FILTER_NEUTRAL);
      SetEditEnabled(m_lOversold, m_iOversold, showLevels);
      SetEditEnabled(m_lOverbought, m_iOverbought, showLevels);
     }

  };
//+------------------------------------------------------------------+
