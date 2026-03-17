//+------------------------------------------------------------------+
//|                                           BollingerBandsPanel.mqh |
//|                                         Copyright 2026, EP Filho |
//|         Sub-página GUI — Bollinger Bands Strategy                 |
//|                     Versão 1.00 - Claude Parte 026 (Claude Code) |
//+------------------------------------------------------------------+
// Incluído por Panel.mqh APÓS a definição completa de CEPBotPanel.
// NÃO incluir diretamente.
//+------------------------------------------------------------------+

class CBollingerBandsPanel : public CStrategyPanelBase
  {
private:
   CBollingerBandsStrategy *m_strategy;

   // Estado pendente (aplicado via APLICAR)
   bool               m_pendingEnabled;
   ENUM_TIMEFRAMES    m_cur_TF;
   ENUM_BB_SIGNAL_MODE m_cur_mode;
   ENUM_ENTRY_MODE    m_cur_entry;
   ENUM_EXIT_MODE     m_cur_exit;
   uint               m_statusExpiry;

   // Controles — display read-only
   CLabel   m_hdr;
   CButton  m_btnToggle;
   CLabel   m_lStatus;   CLabel  m_eStatus;
   CLabel   m_lUpper;    CLabel  m_eUpper;
   CLabel   m_lMiddle;   CLabel  m_eMiddle;
   CLabel   m_lLower;    CLabel  m_eLower;
   CLabel   m_lWidth;    CLabel  m_eWidth;

   // Controles — config editável
   CLabel   m_hdrConf;
   CLabel   m_lPeriod;   CEdit   m_iPeriod;
   CLabel   m_lDev;      CEdit   m_iDev;
   CLabel   m_lTF;       CButton m_bTF;
   CLabel   m_hdrSig;
   CLabel   m_lMode;     CButton m_bMode[3];
   CLabel   m_lModeDesc;
   CLabel   m_lEntry;    CButton m_bEntry[2];
   CLabel   m_lExit;     CButton m_bExit[3];
   CLabel   m_lLeg1;
   CLabel   m_lLeg2;
   CLabel   m_lLeg3;
   CButton  m_btnApply;
   CLabel   m_lblStatus;

public:
   CBollingerBandsPanel(CBollingerBandsStrategy *strategy)
      : m_strategy(strategy),
        m_pendingEnabled(false),
        m_cur_TF(PERIOD_CURRENT),
        m_cur_mode(BB_MODE_FFFD),
        m_cur_entry(ENTRY_NEXT_CANDLE),
        m_cur_exit(EXIT_TP_SL),
        m_statusExpiry(0)
     {}

   virtual string GetName(void) const { return "BB"; }

   virtual bool Create(CEPBotPanel *parent, long chart_id, int subwin)
     {
      m_chart_id = chart_id;
      m_subwin   = subwin;
      int y = ESTRAT_CONTENT_Y;

      if(!parent.CreateHdr(m_hdr, "e_hBB", "BOLLINGER BANDS STRATEGY", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Toggle ON/OFF
      m_pendingEnabled = (m_strategy != NULL) ? m_strategy.GetEnabled() : false;
      if(!m_btnToggle.Create(chart_id, PFX + "e_bBBOn", subwin,
                             COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 20))
         return false;
      m_btnToggle.FontSize(8);
      if(!parent.AddControl(m_btnToggle)) return false;
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      y += 24;

      // Display
      if(!parent.CreateLV(m_lStatus, m_eStatus, "e_lBBS", "e_eBBS", "Status:",      y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lUpper,  m_eUpper,  "e_lBBU", "e_eBBU", "Banda Sup.:",  y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lMiddle, m_eMiddle, "e_lBBM", "e_eBBM", "Banda Med.:",  y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lLower,  m_eLower,  "e_lBBL", "e_eBBL", "Banda Inf.:",  y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lWidth,  m_eWidth,  "e_lBBW", "e_eBBW", "Largura:",     y)) return false;
      y += PANEL_GAP_Y + 2;

      // Config
      y += PANEL_GAP_SECTION;
      if(!parent.CreateHdr(m_hdrConf, "bb_h1", "CONFIGURACOES", y)) return false;
      y += PANEL_GAP_Y + 2;

      if(!parent.CreateLI(m_lPeriod, m_iPeriod, "bb_lPD", "bb_iPD", "Periodo:", y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLI(m_lDev, m_iDev, "bb_lDV", "bb_iDV", "Desvio:", y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLB(m_lTF, m_bTF, "bb_lTF", "bb_bTF", "Time Frame:", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Modo de sinal (radio 3)
      y += PANEL_GAP_SECTION;
      if(!parent.CreateHdr(m_hdrSig, "bb_h2", "SINAIS", y)) return false;
      y += PANEL_GAP_Y + 2;
      {
       string modeTexts[] = {"FFFD", "REBND.", "BREAK."};
       if(!parent.CreateRadioGroup(m_lMode, m_bMode, "bb_lMD", "bb_bMD", "Modo:", modeTexts, 3, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;

      // Legenda dinâmica do modo
      if(!m_lModeDesc.Create(chart_id, PFX + "bb_lMDesc", subwin,
                              COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lModeDesc.FontSize(7); m_lModeDesc.Color(CLR_NEUTRAL);
      m_lModeDesc.Text(_ModeDesc(BB_MODE_FFFD));
      if(!parent.AddControl(m_lModeDesc)) return false;
      y += 15;

      y += PANEL_GAP_SECTION;
      {
       string entTexts[] = {"PROX. CANDLE", "2o. CANDLE"};
       if(!parent.CreateRadioGroup(m_lEntry, m_bEntry, "bb_lEN", "bb_bEN", "Entrada:", entTexts, 2, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;
      {
       string extTexts[] = {"FCO", "VM", "TP-SL"};
       if(!parent.CreateRadioGroup(m_lExit, m_bExit, "bb_lEX", "bb_bEX", "Saida:", extTexts, 3, y))
          return false;
      }
      y += PANEL_GAP_Y + 8;

      // Legendas FCO/VM/TP-SL
      if(!m_lLeg1.Create(chart_id, PFX + "bb_leg1", subwin,
                          COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + PANEL_GAP_Y))
         return false;
      m_lLeg1.Text("FCO - Fechar no Cruzamento da Middle");
      m_lLeg1.FontSize(7); m_lLeg1.Color(CLR_NEUTRAL);
      if(!parent.AddControl(m_lLeg1)) return false;
      y += PANEL_GAP_Y;

      if(!m_lLeg2.Create(chart_id, PFX + "bb_leg2", subwin,
                          COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + PANEL_GAP_Y))
         return false;
      m_lLeg2.Text("VM - Virar a mao");
      m_lLeg2.FontSize(7); m_lLeg2.Color(CLR_NEUTRAL);
      if(!parent.AddControl(m_lLeg2)) return false;
      y += PANEL_GAP_Y;

      if(!m_lLeg3.Create(chart_id, PFX + "bb_leg3", subwin,
                          COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + PANEL_GAP_Y))
         return false;
      m_lLeg3.Text("TP/SL - Sair no TP/SL configurados");
      m_lLeg3.FontSize(7); m_lLeg3.Color(CLR_NEUTRAL);
      if(!parent.AddControl(m_lLeg3)) return false;

      // Botão APLICAR
      if(!m_btnApply.Create(chart_id, PFX + "e_applyBB", subwin,
                             COL_LABEL_X, CFG_APPLY_Y,
                             COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 24))
         return false;
      m_btnApply.Text("APLICAR BB STRATEGY");
      m_btnApply.FontSize(9);
      m_btnApply.ColorBackground(C'30,120,70');
      m_btnApply.Color(clrWhite);
      if(!parent.AddControl(m_btnApply)) return false;

      // Label de status
      if(!m_lblStatus.Create(chart_id, PFX + "e_stBB", subwin,
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
      m_lUpper.Show(); m_eUpper.Show();
      m_lMiddle.Show(); m_eMiddle.Show();
      m_lLower.Show(); m_eLower.Show();
      m_lWidth.Show(); m_eWidth.Show();
      m_hdrConf.Show();
      m_lPeriod.Show(); m_iPeriod.Show();
      m_lDev.Show(); m_iDev.Show();
      m_lTF.Show(); m_bTF.Show();
      m_hdrSig.Show();
      m_lMode.Show(); for(int i = 0; i < 3; i++) m_bMode[i].Show();
      m_lModeDesc.Show();
      m_lEntry.Show(); for(int i = 0; i < 2; i++) m_bEntry[i].Show();
      m_lExit.Show();  for(int i = 0; i < 3; i++) m_bExit[i].Show();
      m_lLeg1.Show(); m_lLeg2.Show(); m_lLeg3.Show();
      m_btnApply.Show(); m_lblStatus.Show();
     }

   virtual void Hide(void)
     {
      m_hdr.Hide(); m_btnToggle.Hide();
      m_lStatus.Hide(); m_eStatus.Hide();
      m_lUpper.Hide(); m_eUpper.Hide();
      m_lMiddle.Hide(); m_eMiddle.Hide();
      m_lLower.Hide(); m_eLower.Hide();
      m_lWidth.Hide(); m_eWidth.Hide();
      m_hdrConf.Hide();
      m_lPeriod.Hide(); m_iPeriod.Hide();
      m_lDev.Hide(); m_iDev.Hide();
      m_lTF.Hide(); m_bTF.Hide();
      m_hdrSig.Hide();
      m_lMode.Hide(); for(int i = 0; i < 3; i++) m_bMode[i].Hide();
      m_lModeDesc.Hide();
      m_lEntry.Hide(); for(int i = 0; i < 2; i++) m_bEntry[i].Hide();
      m_lExit.Hide();  for(int i = 0; i < 3; i++) m_bExit[i].Hide();
      m_lLeg1.Hide(); m_lLeg2.Hide(); m_lLeg3.Hide();
      m_btnApply.Hide(); m_lblStatus.Hide();
     }

   virtual void Update(void)
     {
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      m_lModeDesc.Text(_ModeDesc(m_cur_mode));
      if(m_strategy != NULL && m_strategy.IsInitialized() && m_strategy.GetEnabled())
        {
         m_eStatus.Text("Ativo (P:" + IntegerToString(m_strategy.GetPriority()) + ")");
         m_eStatus.Color(CLR_POSITIVE);
         m_eUpper.Text(DoubleToString(m_strategy.GetUpperBand(), _Digits));
         m_eUpper.Color(CLR_VALUE);
         m_eMiddle.Text(DoubleToString(m_strategy.GetMiddleBand(), _Digits));
         m_eMiddle.Color(CLR_VALUE);
         m_eLower.Text(DoubleToString(m_strategy.GetLowerBand(), _Digits));
         m_eLower.Color(CLR_VALUE);
         double bw = m_strategy.GetBandWidth() / _Point;
         m_eWidth.Text(DoubleToString(bw, 1) + " pts");
         m_eWidth.Color(CLR_VALUE);
        }
      else
        {
         m_eStatus.Text("Inativo");  m_eStatus.Color(CLR_NEUTRAL);
         m_eUpper.Text("--");        m_eUpper.Color(CLR_NEUTRAL);
         m_eMiddle.Text("--");       m_eMiddle.Color(CLR_NEUTRAL);
         m_eLower.Text("--");        m_eLower.Color(CLR_NEUTRAL);
         m_eWidth.Text("--");        m_eWidth.Color(CLR_NEUTRAL);
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
         m_cur_TF = CycleTF(m_cur_TF);
         m_bTF.Text(TFName(m_cur_TF));
         return true;
        }
      // Modo radio
      for(int i = 0; i < 3; i++)
         if(name == m_bMode[i].Name())
           {
            m_cur_mode = (ENUM_BB_SIGNAL_MODE)i;
            SetRadioSel(m_bMode, 3, i);
            m_lModeDesc.Text(_ModeDesc(m_cur_mode));
            return true;
           }
      // Entry radio
      for(int i = 0; i < 2; i++)
         if(name == m_bEntry[i].Name())
           { m_cur_entry = (i == 0) ? ENTRY_NEXT_CANDLE : ENTRY_2ND_CANDLE; SetRadioSel(m_bEntry, 2, i); return true; }
      // Exit radio
      for(int i = 0; i < 3; i++)
         if(name == m_bExit[i].Name())
           { m_cur_exit = (i == 0) ? EXIT_FCO : (i == 1) ? EXIT_VM : EXIT_TP_SL; SetRadioSel(m_bExit, 3, i); return true; }
      return false;
     }

private:
   string _ModeDesc(ENUM_BB_SIGNAL_MODE mode)
     {
      switch(mode)
        {
         case BB_MODE_FFFD:     return "FFFD: Fechou Fora, Fechou Dentro (reversao)";
         case BB_MODE_REBOUND:  return "Rebound: toque na banda + reversao";
         case BB_MODE_BREAKOUT: return "Breakout: rompimento da banda (tendencia)";
         default:               return "";
        }
     }

   void _InitFields(void)
     {
      int              pd  = (m_strategy != NULL) ? m_strategy.GetPeriod()      : 20;
      double           dv  = (m_strategy != NULL) ? m_strategy.GetDeviation()   : 2.0;
      ENUM_TIMEFRAMES  tf  = (m_strategy != NULL) ? m_strategy.GetTimeframe()   : PERIOD_CURRENT;
      ENUM_BB_SIGNAL_MODE md = (m_strategy != NULL) ? m_strategy.GetSignalMode() : BB_MODE_FFFD;
      ENUM_ENTRY_MODE  en  = (m_strategy != NULL) ? m_strategy.GetEntryMode()   : ENTRY_NEXT_CANDLE;
      ENUM_EXIT_MODE   ex  = (m_strategy != NULL) ? m_strategy.GetExitMode()    : EXIT_TP_SL;

      m_cur_TF    = tf;
      m_cur_mode  = md;
      m_cur_entry = en;
      m_cur_exit  = ex;

      m_iPeriod.Text(IntegerToString(pd));
      m_iDev.Text(DoubleToString(dv, 1));
      m_bTF.Text(TFName(tf));
      m_bTF.ColorBackground(C'50,80,140'); m_bTF.Color(clrWhite);
      SetRadioSel(m_bMode, 3, (int)md);
      SetRadioSel(m_bEntry, 2, (en == ENTRY_NEXT_CANDLE) ? 0 : 1);
      SetRadioSel(m_bExit,  3, (ex == EXIT_FCO) ? 0 : (ex == EXIT_VM) ? 1 : 2);
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
      double dev = StringToDouble(m_iDev.Text());

      if(period >= 2) { if(!m_strategy.SetPeriod(period)) errors++; }
      else errors++;
      if(dev > 0) { if(!m_strategy.SetDeviation(dev)) errors++; }
      else errors++;

      m_strategy.SetTimeframe(m_cur_TF);
      m_strategy.SetSignalMode(m_cur_mode);
      m_strategy.SetEntryMode(m_cur_entry);
      m_strategy.SetExitMode(m_cur_exit);
      m_strategy.SetEnabled(m_pendingEnabled);

      if(errors == 0)
        { m_lblStatus.Text("Aplicado com sucesso!"); m_lblStatus.Color(CLR_POSITIVE); }
      else
        { m_lblStatus.Text("Valores invalidos (Period>=2, Desvio>0)"); m_lblStatus.Color(CLR_NEGATIVE); }
      m_statusExpiry = GetTickCount() + 10000;
      ChartRedraw();
     }
  };
//+------------------------------------------------------------------+
