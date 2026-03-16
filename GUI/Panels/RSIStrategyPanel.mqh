//+------------------------------------------------------------------+
//|                                            RSIStrategyPanel.mqh  |
//|                                         Copyright 2026, EP Filho |
//|         Sub-página GUI — RSI Strategy                             |
//|                     Versão 1.00 - Claude Parte 025 (Claude Code) |
//+------------------------------------------------------------------+
// Incluído por Panel.mqh APÓS a definição completa de CEPBotPanel.
// NÃO incluir diretamente.
//+------------------------------------------------------------------+

class CRSIStrategyPanel : public CStrategyPanelBase
  {
private:
   CRSIStrategy     *m_strategy;

   // Estado pendente
   bool               m_pendingEnabled;
   ENUM_TIMEFRAMES    m_cur_rsiTF;
   ENUM_RSI_SIGNAL_MODE m_cur_rsiMode;
   uint               m_statusExpiry;

   // Controles — display
   CLabel   m_hdr;
   CButton  m_btnToggle;
   CLabel   m_lStatus;   CLabel  m_eStatus;
   CLabel   m_lCurr;     CLabel  m_eCurr;
   CLabel   m_lMode;     CLabel  m_eMode;
   CLabel   m_lLevels;   CLabel  m_eLevels;

   // Controles — config
   CLabel   m_hdrConf;
   CLabel   m_lPeriod;   CEdit   m_iPeriod;
   CLabel   m_lTF;       CButton m_bTF;
   CLabel   m_lMode2;    CButton m_bMode[3];
   CLabel   m_lModeDesc;
   CLabel   m_lOversold;   CEdit m_iOversold;
   CLabel   m_lOverbought; CEdit m_iOverbought;
   CLabel   m_lMiddle;     CEdit m_iMiddle;
   CButton  m_btnApply;
   CLabel   m_lblStatus;

public:
   CRSIStrategyPanel(CRSIStrategy *strategy)
      : m_strategy(strategy),
        m_pendingEnabled(false),
        m_cur_rsiTF(PERIOD_CURRENT),
        m_cur_rsiMode(RSI_MODE_CROSSOVER),
        m_statusExpiry(0)
     {}

   virtual string GetName(void) const { return "RSI"; }

   virtual bool Create(CEPBotPanel *parent, long chart_id, int subwin)
     {
      m_chart_id = chart_id;
      m_subwin   = subwin;
      int y = ESTRAT_CONTENT_Y;

      if(!parent.CreateHdr(m_hdr, "e_h3", "RSI STRATEGY", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Toggle ON/OFF
      m_pendingEnabled = (m_strategy != NULL) ? m_strategy.GetEnabled() : false;
      if(!m_btnToggle.Create(chart_id, PFX + "e_bRSOn", subwin,
                             COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 20))
         return false;
      m_btnToggle.FontSize(8);
      if(!parent.AddControl(m_btnToggle)) return false;
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      y += 24;

      // Display
      if(!parent.CreateLV(m_lStatus,  m_eStatus,  "e_lRS",  "e_eRS",  "Status:",    y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lCurr,    m_eCurr,    "e_lRC",  "e_eRC",  "RSI Atual:", y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lMode,    m_eMode,    "e_lRM",  "e_eRM",  "Modo:",      y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lLevels,  m_eLevels,  "e_lRL",  "e_eRL",  "Niveis:",    y)) return false;
      y += PANEL_GAP_Y + 2;

      // Config
      y += PANEL_GAP_SECTION;
      if(!parent.CreateHdr(m_hdrConf, "re_h1", "CONFIGURACOES", y)) return false;
      y += PANEL_GAP_Y + 2;

      if(!parent.CreateLI(m_lPeriod, m_iPeriod, "re_lPD", "re_iPD", "Periodo:", y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLB(m_lTF,     m_bTF,     "re_lTF", "re_bTF", "Time Frame:", y)) return false;
      y += PANEL_GAP_Y + 2;

      y += PANEL_GAP_SECTION;
      {
       string modeTexts[] = {"CROSS.", "ZONE", "MEDIO"};
       if(!parent.CreateRadioGroup(m_lMode2, m_bMode, "re_lMD", "re_bMD", "Modo:", modeTexts, 3, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;

      // Legenda dinâmica do modo
      if(!m_lModeDesc.Create(chart_id, PFX + "re_lMDesc", subwin,
                              COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lModeDesc.FontSize(7); m_lModeDesc.Color(CLR_NEUTRAL);
      m_lModeDesc.Text(RSIModeDesc(RSI_MODE_CROSSOVER));
      if(!parent.AddControl(m_lModeDesc)) return false;
      y += 15;

      y += PANEL_GAP_SECTION;
      if(!parent.CreateLI(m_lOversold,   m_iOversold,   "re_lOS", "re_iOS", "Oversold:",   y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLI(m_lOverbought, m_iOverbought, "re_lOB", "re_iOB", "Overbought:", y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLI(m_lMiddle,     m_iMiddle,     "re_lMI", "re_iMI", "Medio:",      y)) return false;
      y += PANEL_GAP_Y + 8;

      // Botão APLICAR
      if(!m_btnApply.Create(chart_id, PFX + "e_applyRSI", subwin,
                             COL_LABEL_X, CFG_APPLY_Y,
                             COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 24))
         return false;
      m_btnApply.Text("APLICAR RSI");
      m_btnApply.FontSize(9);
      m_btnApply.ColorBackground(C'30,120,70');
      m_btnApply.Color(clrWhite);
      if(!parent.AddControl(m_btnApply)) return false;

      // Label de status
      if(!m_lblStatus.Create(chart_id, PFX + "e_stRSI", subwin,
                              COL_LABEL_X, CFG_APPLY_Y + 28,
                              COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 28 + PANEL_GAP_Y))
         return false;
      m_lblStatus.Text(""); m_lblStatus.FontSize(8); m_lblStatus.Color(CLR_NEUTRAL);
      if(!parent.AddControl(m_lblStatus)) return false;

      // Preenche valores iniciais
      _InitFields();
      m_statusExpiry = 0;
      return true;
     }

   virtual void Show(void)
     {
      m_hdr.Show(); m_btnToggle.Show();
      m_lStatus.Show(); m_eStatus.Show();
      m_lCurr.Show(); m_eCurr.Show();
      m_lMode.Show(); m_eMode.Show();
      m_lLevels.Show(); m_eLevels.Show();
      m_hdrConf.Show();
      m_lPeriod.Show(); m_iPeriod.Show();
      m_lTF.Show(); m_bTF.Show();
      m_lMode2.Show(); for(int i = 0; i < 3; i++) m_bMode[i].Show();
      m_lModeDesc.Show();
      m_lOversold.Show(); m_iOversold.Show();
      m_lOverbought.Show(); m_iOverbought.Show();
      m_lMiddle.Show(); m_iMiddle.Show();
      m_btnApply.Show(); m_lblStatus.Show();
     }

   virtual void Hide(void)
     {
      m_hdr.Hide(); m_btnToggle.Hide();
      m_lStatus.Hide(); m_eStatus.Hide();
      m_lCurr.Hide(); m_eCurr.Hide();
      m_lMode.Hide(); m_eMode.Hide();
      m_lLevels.Hide(); m_eLevels.Hide();
      m_hdrConf.Hide();
      m_lPeriod.Hide(); m_iPeriod.Hide();
      m_lTF.Hide(); m_bTF.Hide();
      m_lMode2.Hide(); for(int i = 0; i < 3; i++) m_bMode[i].Hide();
      m_lModeDesc.Hide();
      m_lOversold.Hide(); m_iOversold.Hide();
      m_lOverbought.Hide(); m_iOverbought.Hide();
      m_lMiddle.Hide(); m_iMiddle.Hide();
      m_btnApply.Hide(); m_lblStatus.Hide();
     }

   virtual void Update(void)
     {
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      m_lModeDesc.Text(RSIModeDesc(m_cur_rsiMode));
      if(m_strategy != NULL && m_strategy.IsInitialized() && m_strategy.GetEnabled())
        {
         m_eStatus.Text("Ativo (P:" + IntegerToString(m_strategy.GetPriority()) + ")");
         m_eStatus.Color(CLR_POSITIVE);
         m_eCurr.Text(DoubleToString(m_strategy.GetCurrentRSI(), 1));
         m_eCurr.Color(CLR_VALUE);
         m_eMode.Text(m_strategy.GetSignalModeText());
         m_eMode.Color(CLR_VALUE);
         m_eLevels.Text(DoubleToString(m_strategy.GetOversold(), 0) + " / " +
                        DoubleToString(m_strategy.GetOverbought(), 0));
         m_eLevels.Color(CLR_VALUE);
        }
      else
        {
         m_eStatus.Text("Inativo");  m_eStatus.Color(CLR_NEUTRAL);
         m_eCurr.Text("--");         m_eCurr.Color(CLR_NEUTRAL);
         m_eMode.Text("--");         m_eMode.Color(CLR_NEUTRAL);
         m_eLevels.Text("--");       m_eLevels.Color(CLR_NEUTRAL);
        }
      if(m_statusExpiry > 0 && GetTickCount() >= m_statusExpiry)
        { m_lblStatus.Text(""); m_statusExpiry = 0; ChartRedraw(); }
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
      if(name == m_btnApply.Name())
        { m_btnApply.Pressed(false); _OnApply(); return true; }
      if(name == m_bTF.Name())
        {
         m_bTF.Pressed(false);
         m_cur_rsiTF = CycleTF(m_cur_rsiTF);
         m_bTF.Text(TFName(m_cur_rsiTF));
         return true;
        }
      for(int i = 0; i < 3; i++)
         if(name == m_bMode[i].Name())
           {
            m_cur_rsiMode = IndexToRSIMode(i);
            SetRadioSel(m_bMode, 3, i);
            m_lModeDesc.Text(RSIModeDesc(m_cur_rsiMode));
            return true;
           }
      return false;
     }

private:
   void _InitFields(void)
     {
      int                  rp  = (m_strategy != NULL) ? m_strategy.GetPeriod()      : 14;
      ENUM_TIMEFRAMES      rt  = (m_strategy != NULL) ? m_strategy.GetTimeframe()   : PERIOD_CURRENT;
      ENUM_RSI_SIGNAL_MODE rm  = (m_strategy != NULL) ? m_strategy.GetSignalMode()  : RSI_MODE_CROSSOVER;
      double               ros = (m_strategy != NULL) ? m_strategy.GetOversold()    : 30.0;
      double               rob = (m_strategy != NULL) ? m_strategy.GetOverbought()  : 70.0;
      double               rmi = (m_strategy != NULL) ? m_strategy.GetMiddle()      : 50.0;

      m_cur_rsiTF   = rt;
      m_cur_rsiMode = rm;

      m_iPeriod.Text(IntegerToString(rp));
      m_iOversold.Text(DoubleToString(ros, 1));
      m_iOverbought.Text(DoubleToString(rob, 1));
      m_iMiddle.Text(DoubleToString(rmi, 1));
      m_bTF.Text(TFName(rt));
      m_bTF.ColorBackground(C'50,80,140'); m_bTF.Color(clrWhite);
      SetRadioSel(m_bMode, 3, RSIModeToIndex(rm));
     }

   void _OnApply(void)
     {
      if(m_strategy == NULL)
        {
         m_lblStatus.Text("Estrategia nao disponivel");
         m_lblStatus.Color(CLR_NEGATIVE);
         m_statusExpiry = GetTickCount() + 10000;
         return;
        }
      int errors = 0;
      int period = (int)StringToInteger(m_iPeriod.Text());
      if(period >= 2) { if(!m_strategy.SetPeriod(period)) errors++; }
      else errors++;

      m_strategy.SetTimeframe(m_cur_rsiTF);
      m_strategy.SetSignalMode(m_cur_rsiMode);

      double os = StringToDouble(m_iOversold.Text());
      double ob = StringToDouble(m_iOverbought.Text());
      double mi = StringToDouble(m_iMiddle.Text());

      if(os > 0 && os < 100) m_strategy.SetOversold(os);   else errors++;
      if(ob > 0 && ob < 100) m_strategy.SetOverbought(ob); else errors++;
      if(mi > 0 && mi < 100) m_strategy.SetMiddle(mi);     else errors++;

      m_strategy.SetEnabled(m_pendingEnabled);

      if(errors == 0)
        { m_lblStatus.Text("Aplicado com sucesso!"); m_lblStatus.Color(CLR_POSITIVE); }
      else
        { m_lblStatus.Text("Valores invalidos (Period>=2, Niveis 0-100)"); m_lblStatus.Color(CLR_NEGATIVE); }
      m_statusExpiry = GetTickCount() + 10000;
      ChartRedraw();
     }
  };
//+------------------------------------------------------------------+
