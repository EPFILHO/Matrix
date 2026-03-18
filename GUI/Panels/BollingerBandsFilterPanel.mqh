//+------------------------------------------------------------------+
//|                                     BollingerBandsFilterPanel.mqh |
//|                                         Copyright 2026, EP Filho |
//|         Sub-página GUI — Bollinger Bands Filter (Anti-Squeeze)   |
//|                     Versão 1.01 - Claude Parte 026 (Claude Code) |
//+------------------------------------------------------------------+
// Incluído por Panel.mqh APÓS a definição completa de CEPBotPanel.
// NÃO incluir diretamente.
//+------------------------------------------------------------------+

class CBollingerBandsFilterPanel : public CFilterPanelBase
  {
private:
   CBollingerBandsFilter *m_filter;

   // Estado pendente
   bool               m_pendingEnabled;
   ENUM_TIMEFRAMES    m_cur_TF;
   ENUM_BB_SQUEEZE_METRIC m_cur_metric;
   uint               m_statusExpiry;

   // Controles — display
   CLabel   m_hdr;
   CLabel   m_lDesc;     // Descrição do que o filtro faz
   CLabel   m_lStatus;  CLabel  m_eStatus;
   CLabel   m_lWidth;   CLabel  m_eWidth;
   CLabel   m_lMode;    CLabel  m_eMode;

   // Controles — config
   CLabel   m_hdrConf;
   CButton  m_btnToggle;
   CLabel   m_lPeriod;   CEdit   m_iPeriod;
   CLabel   m_lDev;      CEdit   m_iDev;
   CLabel   m_lTF;       CButton m_bTF;
   CLabel   m_lMode2;    CButton m_bMode[3];
   CLabel   m_lModeDesc;
   CLabel   m_lThreshold; CEdit  m_iThreshold;
   CLabel   m_lThreshHint; // Legenda do threshold
   CLabel   m_lPercPeriod; CEdit m_iPercPeriod;
   CLabel   m_lPercHint;   // Legenda do período percentil
   CButton  m_btnApply;
   CLabel   m_lblStatus;

public:
   CBollingerBandsFilterPanel(CBollingerBandsFilter *filter)
      : m_filter(filter),
        m_pendingEnabled(false),
        m_cur_TF(PERIOD_CURRENT),
        m_cur_metric(BB_SQUEEZE_RELATIVE),
        m_statusExpiry(0)
     {}

   virtual string GetName(void) const { return "BB FILT"; }

   virtual bool Create(CEPBotPanel *parent, long chart_id, int subwin)
     {
      m_chart_id = chart_id;
      m_subwin   = subwin;
      int y = FILTROS_CONTENT_Y;

      // Display
      if(!parent.CreateHdr(m_hdr, "f_hBB", "BB FILTER (ANTI-SQUEEZE)", y)) return false;
      y += PANEL_GAP_Y + 2;
      // Descrição do filtro
      if(!m_lDesc.Create(chart_id, PFX + "fbf_lDesc", subwin,
                          COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lDesc.Font("Tahoma"); m_lDesc.FontSize(7); m_lDesc.Color(CLR_NEUTRAL);
      m_lDesc.Text("Bloqueia trades quando as bandas estão estreitas (squeeze)");
      if(!parent.AddControl(m_lDesc)) return false;
      y += 15;
      if(!parent.CreateLV(m_lStatus, m_eStatus, "f_lBFS", "f_eBFS", "Status:",     y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lWidth,  m_eWidth,  "f_lBFW", "f_eBFW", "Largura:",    y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lMode, m_eMode, "f_lBFM", "f_eBFM", "Modo:",    y)) return false;

      // Config
      y += PANEL_GAP_Y;
      y += PANEL_GAP_SECTION;
      if(!parent.CreateHdr(m_hdrConf, "fbf_hConf", "CONFIGURACOES", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Toggle
      m_pendingEnabled = (m_filter != NULL) ? m_filter.IsEnabled() : false;
      if(!m_btnToggle.Create(chart_id, PFX + "f_bBFOn", subwin,
                             COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 22))
         return false;
      m_btnToggle.FontSize(8);
      if(!parent.AddControl(m_btnToggle)) return false;
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      y += 24;

      // Período BB
      {
       int p = (m_filter != NULL) ? m_filter.GetPeriod() : 20;
       if(!parent.CreateLI(m_lPeriod, m_iPeriod, "fbf_lPd", "fbf_iPd", "Periodo BB:", y)) return false;
       m_iPeriod.Text(IntegerToString(p));
      }
      y += PANEL_GAP_Y;

      // Desvio
      {
       double d = (m_filter != NULL) ? m_filter.GetDeviation() : 2.0;
       if(!parent.CreateLI(m_lDev, m_iDev, "fbf_lDv", "fbf_iDv", "Desvio:", y)) return false;
       m_iDev.Text(DoubleToString(d, 1));
      }
      y += PANEL_GAP_Y;

      // Time Frame
      {
       ENUM_TIMEFRAMES tf = (m_filter != NULL) ? m_filter.GetTimeframe() : PERIOD_CURRENT;
       m_cur_TF = tf;
       if(!parent.CreateLB(m_lTF, m_bTF, "fbf_lTF", "fbf_bTF", "Time Frame:", y)) return false;
       m_bTF.Text(TFName(tf));
       m_bTF.ColorBackground(C'50,80,140'); m_bTF.Color(clrWhite);
      }
      y += PANEL_GAP_Y + 2;

      // Métrica Squeeze (radio 3)
      y += PANEL_GAP_SECTION;
      {
       ENUM_BB_SQUEEZE_METRIC sm = (m_filter != NULL) ? m_filter.GetSqueezeMetric() : BB_SQUEEZE_RELATIVE;
       m_cur_metric = sm;
       string modeTexts[] = {"ABSOLUTO", "RELATIVO", "PERCENTIL"};
       if(!parent.CreateRadioGroup(m_lMode2, m_bMode, "fbf_lMt", "fbf_bMt", "Modo:", modeTexts, 3, y))
          return false;
       SetRadioSel(m_bMode, 3, (int)sm);
      }
      y += PANEL_GAP_Y + 2;

      // Legenda dinâmica da métrica
      if(!m_lModeDesc.Create(chart_id, PFX + "fbf_lMDesc", subwin,
                                COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lModeDesc.Font("Tahoma"); m_lModeDesc.FontSize(7); m_lModeDesc.Color(CLR_NEUTRAL);
      m_lModeDesc.Text(_ModeDesc(m_cur_metric));
      if(!parent.AddControl(m_lModeDesc)) return false;
      y += 15;

      // Threshold
      y += PANEL_GAP_SECTION;
      {
       double th = (m_filter != NULL) ? m_filter.GetSqueezeThreshold() : 1.0;
       if(!parent.CreateLI(m_lThreshold, m_iThreshold, "fbf_lTh", "fbf_iTh", "Limite:", y)) return false;
       m_iThreshold.Text(DoubleToString(th, 2));
      }
      y += PANEL_GAP_Y;
      // Dica do threshold (muda conforme a métrica)
      if(!m_lThreshHint.Create(chart_id, PFX + "fbf_lThH", subwin,
                                COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lThreshHint.Font("Tahoma"); m_lThreshHint.FontSize(7); m_lThreshHint.Color(CLR_NEUTRAL);
      m_lThreshHint.Text(_ThreshHint(m_cur_metric));
      if(!parent.AddControl(m_lThreshHint)) return false;
      y += 15;

      // Período do Percentil
      {
       int pp = (m_filter != NULL) ? m_filter.GetPercentilePeriod() : 50;
       if(!parent.CreateLI(m_lPercPeriod, m_iPercPeriod, "fbf_lPP", "fbf_iPP", "Periodo Percentil:", y)) return false;
       m_iPercPeriod.Text(IntegerToString(pp));
      }
      y += PANEL_GAP_Y;
      // Dica do período percentil
      if(!m_lPercHint.Create(chart_id, PFX + "fbf_lPPH", subwin,
                              COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lPercHint.Font("Tahoma"); m_lPercHint.FontSize(7); m_lPercHint.Color(CLR_NEUTRAL);
      m_lPercHint.Text("Barras para cálculo do percentil");
      if(!parent.AddControl(m_lPercHint)) return false;
      y += 15;

      // Botão APLICAR
      if(!m_btnApply.Create(chart_id, PFX + "f_applyBF", subwin,
                             COL_LABEL_X, CFG_APPLY_Y,
                             COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 24))
         return false;
      m_btnApply.Text("APLICAR BB FILTER");
      m_btnApply.FontSize(9);
      m_btnApply.ColorBackground(C'30,120,70');
      m_btnApply.Color(clrWhite);
      if(!parent.AddControl(m_btnApply)) return false;

      if(!m_lblStatus.Create(chart_id, PFX + "f_stBF", subwin,
                              COL_LABEL_X, CFG_APPLY_Y + 28,
                              COL_VALUE_X + COL_VALUE_W, CFG_APPLY_Y + 28 + PANEL_GAP_Y))
         return false;
      m_lblStatus.Text(""); m_lblStatus.FontSize(8); m_lblStatus.Color(CLR_NEUTRAL);
      if(!parent.AddControl(m_lblStatus)) return false;
      m_statusExpiry = 0;
      return true;
     }

   virtual void Show(void)
     {
      m_hdr.Show(); m_lDesc.Show();
      m_lStatus.Show(); m_eStatus.Show();
      m_lWidth.Show(); m_eWidth.Show();
      m_lMode.Show(); m_eMode.Show();
      m_hdrConf.Show(); m_btnToggle.Show();
      m_lPeriod.Show(); m_iPeriod.Show();
      m_lDev.Show(); m_iDev.Show();
      m_lTF.Show(); m_bTF.Show();
      m_lMode2.Show(); for(int i = 0; i < 3; i++) m_bMode[i].Show();
      m_lModeDesc.Show();
      m_lThreshold.Show(); m_iThreshold.Show(); m_lThreshHint.Show();
      m_lPercPeriod.Show(); m_iPercPeriod.Show(); m_lPercHint.Show();
      m_btnApply.Show(); m_lblStatus.Show();
     }

   virtual void Hide(void)
     {
      m_hdr.Hide(); m_lDesc.Hide();
      m_lStatus.Hide(); m_eStatus.Hide();
      m_lWidth.Hide(); m_eWidth.Hide();
      m_lMode.Hide(); m_eMode.Hide();
      m_hdrConf.Hide(); m_btnToggle.Hide();
      m_lPeriod.Hide(); m_iPeriod.Hide();
      m_lDev.Hide(); m_iDev.Hide();
      m_lTF.Hide(); m_bTF.Hide();
      m_lMode2.Hide(); for(int i = 0; i < 3; i++) m_bMode[i].Hide();
      m_lModeDesc.Hide();
      m_lThreshold.Hide(); m_iThreshold.Hide(); m_lThreshHint.Hide();
      m_lPercPeriod.Hide(); m_iPercPeriod.Hide(); m_lPercHint.Hide();
      m_btnApply.Hide(); m_lblStatus.Hide();
     }

   virtual void Update(void)
     {
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      m_lModeDesc.Text(_ModeDesc(m_cur_metric));
      m_lThreshHint.Text(_ThreshHint(m_cur_metric));
      if(m_filter != NULL && m_filter.IsInitialized())
        {
         bool active = m_filter.IsEnabled();
         m_eStatus.Text(active ? "Ativo" : "Inativo");
         m_eStatus.Color(active ? CLR_POSITIVE : CLR_NEUTRAL);
         double bw = m_filter.GetCurrentBandWidth();
         double bwPct = m_filter.GetCurrentBandWidthRelative();
         m_eWidth.Text(DoubleToString(bw, 1) + " pts (" + DoubleToString(bwPct, 2) + "%)");
         m_eWidth.Color(CLR_VALUE);
         m_eMode.Text(m_filter.GetSqueezeMetricText() + " | Limite: " + DoubleToString(m_filter.GetSqueezeThreshold(), 2));
         m_eMode.Color(CLR_VALUE);
        }
      else
        {
         m_eStatus.Text("Não iniciado"); m_eStatus.Color(CLR_NEUTRAL);
         m_eWidth.Text("--");            m_eWidth.Color(CLR_NEUTRAL);
         m_eMode.Text("--");             m_eMode.Color(CLR_NEUTRAL);
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
      for(int i = 0; i < 3; i++)
         if(name == m_bMode[i].Name())
           {
            m_cur_metric = (ENUM_BB_SQUEEZE_METRIC)i;
            SetRadioSel(m_bMode, 3, i);
            m_lModeDesc.Text(_ModeDesc(m_cur_metric));
            m_lThreshHint.Text(_ThreshHint(m_cur_metric));
            return true;
           }
      return false;
     }

private:
   string _ModeDesc(ENUM_BB_SQUEEZE_METRIC metric)
     {
      switch(metric)
        {
         case BB_SQUEEZE_ABSOLUTE:   return "ABSOLUTO: largura em pontos (upper-lower)";
         case BB_SQUEEZE_RELATIVE:   return "RELATIVO: largura % da banda central";
         case BB_SQUEEZE_PERCENTILE: return "PERCENTIL: compara com N barras anteriores";
         default:                    return "";
        }
     }

   string _ThreshHint(ENUM_BB_SQUEEZE_METRIC metric)
     {
      switch(metric)
        {
         case BB_SQUEEZE_ABSOLUTE:   return "Bloqueia se largura < X pts";
         case BB_SQUEEZE_RELATIVE:   return "Bloqueia se largura < X %";
         case BB_SQUEEZE_PERCENTILE: return "Bloqueia se percentil < X";
         default:                    return "";
        }
     }

   void _OnApply(void)
     {
      if(m_filter == NULL)
        {
         m_lblStatus.Text("Filtro não disponível");
         m_lblStatus.Color(CLR_NEGATIVE);
         m_statusExpiry = GetTickCount() + 10000;
         return;
        }
      int    period     = (int)StringToInteger(m_iPeriod.Text());
      double deviation  = StringToDouble(m_iDev.Text());
      double threshold  = StringToDouble(m_iThreshold.Text());
      int    percPeriod = (int)StringToInteger(m_iPercPeriod.Text());
      int errors = 0;

      if(period <= 0) errors++;
      if(deviation <= 0) errors++;
      if(threshold <= 0) errors++;
      if(percPeriod <= 0) errors++;

      if(errors > 0)
        {
         m_lblStatus.Text("Valores inválidos! (todos devem ser > 0)");
         m_lblStatus.Color(CLR_NEGATIVE);
         m_statusExpiry = GetTickCount() + 10000;
         return;
        }

      m_filter.SetEnabled(m_pendingEnabled);
      m_filter.SetSqueezeMetric(m_cur_metric);
      m_filter.SetSqueezeThreshold(threshold);
      m_filter.SetPercentilePeriod(percPeriod);
      m_filter.SetPeriod(period);
      m_filter.SetDeviation(deviation);
      m_filter.SetTimeframe(m_cur_TF);

      string msg = "Aplicado" + (m_pendingEnabled ? " [ON]" : " [OFF]");
      m_lblStatus.Text(msg);
      m_lblStatus.Color(CLR_POSITIVE);
      m_statusExpiry = GetTickCount() + 10000;
     }
  };
//+------------------------------------------------------------------+
