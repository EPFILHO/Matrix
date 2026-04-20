//+------------------------------------------------------------------+
//|                                     BollingerBandsFilterPanel.mqh |
//|                                         Copyright 2026, EP Filho |
//|         Sub-página GUI — Bollinger Bands Filter (Anti-Squeeze)   |
//|                     Versão 1.11 - Claude Parte 035 (Claude Code) |
//+------------------------------------------------------------------+
// Incluído por Panel.mqh APÓS a definição completa de CEPBotPanel.
// NÃO incluir diretamente.
//
// CHANGELOG v1.11 (Parte 035) — AppliedPrice:
// * Novo botão "Preço" ciclando CLOSE/OPEN/HIGH/LOW/MEDIAN/TYPICAL
// * Apply(): chama SetAppliedPrice() (hot-reload via Deinit+Init)
// * Reload()/_RefreshFieldState(): sincroniza visual e toggle
//
// CHANGELOG v1.10 (Parte 033) — persistência:
// * Reload(): repopula campos GUI a partir do módulo (fix Issue #22)
//   chamado por ApplyLoadedConfig após atualizar os módulos
//
// CHANGELOG v1.09 (Parte 033) — Issue #29:
// * _RefreshFieldState(): respeita m_pendingEnabled como toggle mestre
//   (todos campos cinza/desabilitados quando toggle OFF)
// * OnClick() do toggle: chama _RefreshFieldState() após alternar
//
// CHANGELOG v1.07 (Parte 029):
// * m_locked: Update() não sobrescreve visual quando EA rodando
//
// CHANGELOG v1.06 (Parte 029):
// * SetEnabled(): toggle ON/OFF cinza, campos fundo branco/cinza,
//   labels dim, TF + Mode radios cobertos
//
// CHANGELOG v1.05 (Parte 027) — Fase 2: Controle de Estado:
// * Removido botão APLICAR (m_btnApply) — aplicação centralizada
// * _OnApply convertido para Apply() público; adicionado SetEnabled()
//
// CHANGELOG v1.04 (Parte 027):
// + SetFilter(): setter tipado para re-injeção de ponteiro
//   (usado por ReconnectModules e config persistence)
//+------------------------------------------------------------------+

class CBollingerBandsFilterPanel : public CFilterPanelBase
  {
private:
   CBollingerBandsFilter *m_filter;

   // Estado pendente
   bool               m_pendingEnabled;
   ENUM_TIMEFRAMES    m_cur_TF;
   ENUM_APPLIED_PRICE m_cur_price;
   ENUM_BB_SQUEEZE_METRIC m_cur_metric;

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
   CLabel   m_lPrice;    CButton m_bPrice;
   CLabel   m_lMode2;    CButton m_bMode[3];
   CLabel   m_lModeDesc;
   CLabel   m_lThreshold; CEdit  m_iThreshold;
   CLabel   m_lThreshHint; // Legenda do threshold
   CLabel   m_lPercPeriod; CEdit m_iPercPeriod;
   CLabel   m_lPercHint;   // Legenda do período percentil

public:
   CBollingerBandsFilterPanel(CBollingerBandsFilter *filter)
      : m_filter(filter),
        m_pendingEnabled(false),
        m_cur_TF(PERIOD_CURRENT),
        m_cur_price(PRICE_CLOSE),
        m_cur_metric(BB_SQUEEZE_RELATIVE)
     {}

   virtual string GetName(void) const { return "BB FILT"; }
   void           SetFilter(CBollingerBandsFilter *f) { m_filter = f; }

   virtual bool Create(CEPBotPanel *parent, long chart_id, int subwin)
     {
      m_parent   = parent;
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

      // Applied Price
      {
       ENUM_APPLIED_PRICE pr = (m_filter != NULL) ? m_filter.GetAppliedPrice() : PRICE_CLOSE;
       m_cur_price = pr;
       if(!parent.CreateLB(m_lPrice, m_bPrice, "fbf_lPr", "fbf_bPr", "Preco:", y)) return false;
       m_bPrice.Text(AppliedPriceShortText(pr));
       m_bPrice.ColorBackground(C'50,80,140'); m_bPrice.Color(clrWhite);
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
      m_lPrice.Show(); m_bPrice.Show();
      m_lMode2.Show(); for(int i = 0; i < 3; i++) m_bMode[i].Show();
      m_lModeDesc.Show();
      m_lThreshold.Show(); m_iThreshold.Show(); m_lThreshHint.Show();
      m_lPercPeriod.Show(); m_iPercPeriod.Show(); m_lPercHint.Show();
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
      m_lPrice.Hide(); m_bPrice.Hide();
      m_lMode2.Hide(); for(int i = 0; i < 3; i++) m_bMode[i].Hide();
      m_lModeDesc.Hide();
      m_lThreshold.Hide(); m_iThreshold.Hide(); m_lThreshHint.Hide();
      m_lPercPeriod.Hide(); m_iPercPeriod.Hide(); m_lPercHint.Hide();
     }

   virtual void Update(void)
     {
      if(!m_locked)
        {
         ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
         _RefreshFieldState();
        }
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
     }

   virtual bool OnClick(string name)
     {
      if(name == m_btnToggle.Name())
        {
         m_btnToggle.Pressed(false);
         m_pendingEnabled = !m_pendingEnabled;
         ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
         _RefreshFieldState();
         return true;
        }
      if(name == m_bTF.Name())
        {
         m_bTF.Pressed(false);
         m_cur_TF = CycleTF(m_cur_TF);
         m_bTF.Text(TFName(m_cur_TF));
         return true;
        }
      if(name == m_bPrice.Name())
        {
         m_bPrice.Pressed(false);
         m_cur_price = CycleAppliedPrice(m_cur_price);
         m_bPrice.Text(AppliedPriceShortText(m_cur_price));
         return true;
        }
      for(int i = 0; i < 3; i++)
         if(name == m_bMode[i].Name())
           {
            m_cur_metric = (ENUM_BB_SQUEEZE_METRIC)i;
            SetRadioSel(m_bMode, 3, i);
            m_lModeDesc.Text(_ModeDesc(m_cur_metric));
            m_lThreshHint.Text(_ThreshHint(m_cur_metric));
            _RefreshFieldState();
            return true;
           }
      return false;
     }

public:
   bool Apply(string &outErr)
     {
      outErr = "";
      if(m_filter == NULL)
         return false;

      ClearFieldError(m_iPeriod); ClearFieldError(m_iDev);
      ClearFieldError(m_iThreshold); ClearFieldError(m_iPercPeriod);

      int    period     = (int)StringToInteger(m_iPeriod.Text());
      double deviation  = StringToDouble(m_iDev.Text());
      double threshold  = StringToDouble(m_iThreshold.Text());
      int    percPeriod = (int)StringToInteger(m_iPercPeriod.Text());

      string errFields = "";
      if(period <= 0 || period > 500)   { errFields += "BFilt Per, ";  MarkFieldError(m_iPeriod); }
      if(deviation <= 0 || deviation > 10.0) { errFields += "BFilt Dev, ";  MarkFieldError(m_iDev); }
      if(threshold <= 0)                { errFields += "BFilt Thr, ";  MarkFieldError(m_iThreshold); }
      if(m_cur_metric == BB_SQUEEZE_PERCENTILE && (percPeriod <= 0 || percPeriod > 500))
        { errFields += "BFilt PercP, "; MarkFieldError(m_iPercPeriod); }

      if(errFields != "")
        { outErr = errFields; return false; }

      m_filter.SetEnabled(m_pendingEnabled);
      m_filter.SetSqueezeMetric(m_cur_metric);
      m_filter.SetSqueezeThreshold(threshold);
      m_filter.SetPercentilePeriod(percPeriod);
      m_filter.SetPeriod(period);
      m_filter.SetDeviation(deviation);
      m_filter.SetTimeframe(m_cur_TF);
      m_filter.SetAppliedPrice(m_cur_price);
      return true;
     }

   void SetEnabled(bool enable)
     {
      m_locked = !enable;
      color fg = enable ? clrBlack : C'160,160,160';
      m_iPeriod.ReadOnly(!enable);    m_iPeriod.Color(fg);
      m_iDev.ReadOnly(!enable);       m_iDev.Color(fg);
      m_iThreshold.ReadOnly(!enable); m_iThreshold.Color(fg);
      m_iPercPeriod.ReadOnly(!enable); m_iPercPeriod.Color(fg);
      if(enable)
        {
         if(m_iPeriod.ColorBackground() != CLR_FIELD_ERROR)    m_iPeriod.ColorBackground(clrWhite);
         if(m_iDev.ColorBackground() != CLR_FIELD_ERROR)       m_iDev.ColorBackground(clrWhite);
         if(m_iThreshold.ColorBackground() != CLR_FIELD_ERROR) m_iThreshold.ColorBackground(clrWhite);
         if(m_iPercPeriod.ColorBackground() != CLR_FIELD_ERROR) m_iPercPeriod.ColorBackground(clrWhite);
        }
      else
        {
         if(m_iPeriod.ColorBackground() != CLR_FIELD_ERROR)    m_iPeriod.ColorBackground(C'220,220,220');
         if(m_iDev.ColorBackground() != CLR_FIELD_ERROR)       m_iDev.ColorBackground(C'220,220,220');
         if(m_iThreshold.ColorBackground() != CLR_FIELD_ERROR) m_iThreshold.ColorBackground(C'220,220,220');
         if(m_iPercPeriod.ColorBackground() != CLR_FIELD_ERROR) m_iPercPeriod.ColorBackground(C'220,220,220');
        }
      // Labels
      color lc = enable ? CLR_LABEL : C'180,180,180';
      m_lPeriod.Color(lc); m_lDev.Color(lc); m_lThreshold.Color(lc); m_lPercPeriod.Color(lc);
      // Toggle ON/OFF
      if(!enable)
        { m_btnToggle.ColorBackground(C'160,160,160'); m_btnToggle.Color(C'200,200,200'); }
      else
         ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      // Buttons + radios
      SetButtonEnabled(m_lTF, m_bTF, enable);
      SetButtonEnabled(m_lPrice, m_bPrice, enable);
      SetRadioGroupEnabled(m_lMode2, m_bMode, 3, enable);
      if(enable)
        {
         m_bTF.ColorBackground(C'50,80,140'); m_bTF.Color(clrWhite);
         m_bPrice.ColorBackground(C'50,80,140'); m_bPrice.Color(clrWhite);
         SetRadioSel(m_bMode, 3, (int)m_cur_metric);
        }
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

   virtual void Reload(void) override
     {
      if(m_filter == NULL) return;
      m_pendingEnabled = m_filter.IsEnabled();
      m_cur_TF         = m_filter.GetTimeframe();
      m_cur_price      = m_filter.GetAppliedPrice();
      m_cur_metric     = m_filter.GetSqueezeMetric();
      m_iPeriod.Text(IntegerToString(m_filter.GetPeriod()));
      m_iDev.Text(DoubleToString(m_filter.GetDeviation(), 1));
      m_iThreshold.Text(DoubleToString(m_filter.GetSqueezeThreshold(), 2));
      m_iPercPeriod.Text(IntegerToString(m_filter.GetPercentilePeriod()));
      m_bTF.Text(TFName(m_cur_TF));
      m_bPrice.Text(AppliedPriceShortText(m_cur_price));
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      SetRadioSel(m_bMode, 3, (int)m_cur_metric);
      m_lModeDesc.Text(_ModeDesc(m_cur_metric));
      m_lThreshHint.Text(_ThreshHint(m_cur_metric));
      _RefreshFieldState();
     }

   void _RefreshFieldState(void)
     {
      bool on       = m_pendingEnabled;
      bool percMode = (m_cur_metric == BB_SQUEEZE_PERCENTILE);
      SetEditEnabled(m_lPeriod,    m_iPeriod,    on);
      SetEditEnabled(m_lDev,       m_iDev,       on);
      SetEditEnabled(m_lThreshold, m_iThreshold, on);
      SetButtonEnabled(m_lTF, m_bTF, on);
      SetButtonEnabled(m_lPrice, m_bPrice, on);
      SetRadioGroupEnabled(m_lMode2, m_bMode, 3, on);
      SetEditEnabled(m_lPercPeriod, m_iPercPeriod, on && percMode);
      if(on)
        {
         m_bTF.ColorBackground(C'50,80,140'); m_bTF.Color(clrWhite);
         m_bPrice.ColorBackground(C'50,80,140'); m_bPrice.Color(clrWhite);
         SetRadioSel(m_bMode, 3, (int)m_cur_metric);
         m_lPercHint.Color(percMode ? CLR_NEUTRAL : C'180,180,180');
        }
      else
        { m_lPercHint.Color(C'180,180,180'); }
     }

  };
//+------------------------------------------------------------------+
