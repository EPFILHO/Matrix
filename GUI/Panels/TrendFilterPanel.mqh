//+------------------------------------------------------------------+
//|                                             TrendFilterPanel.mqh |
//|                                         Copyright 2026, EP Filho |
//|         Sub-página GUI — Trend Filter                             |
//|                     Versão 1.04 - Claude Parte 027 (Claude Code) |
//+------------------------------------------------------------------+
// Incluído por Panel.mqh APÓS a definição completa de CEPBotPanel.
// NÃO incluir diretamente.
//
// CHANGELOG v1.04 (Parte 027) — Fase 2: Controle de Estado:
// * Removido botão APLICAR (m_btnApply) — aplicação centralizada
// * _OnApply convertido para Apply() público; adicionado SetEnabled()
//
// CHANGELOG v1.03 (Parte 027):
// + SetFilter(): setter tipado para re-injeção de ponteiro
//   (usado por ReconnectModules e config persistence)
//+------------------------------------------------------------------+

class CTrendFilterPanel : public CFilterPanelBase
  {
private:
   CTrendFilter     *m_filter;

   // Estado pendente
   bool               m_pendingEnabled;
   ENUM_MA_METHOD     m_cur_method;
   ENUM_TIMEFRAMES    m_cur_TF;
   ENUM_APPLIED_PRICE m_cur_price;
   // Controles — display
   CLabel   m_hdr;
   CLabel   m_lStatus;  CLabel  m_eStatus;
   CLabel   m_lMA;      CLabel  m_eMA;
   CLabel   m_lDist;    CLabel  m_eDist;

   // Controles — config
   CLabel   m_hdrConf;
   CButton  m_btnToggle;
   CLabel   m_lPeriod;  CEdit   m_iPeriod;
   CLabel   m_lMethod;  CButton m_bMethod[4];
   CLabel   m_lTF;      CButton m_bTF;
   CLabel   m_lPrice;   CButton m_bPrice;
   CLabel   m_lNeutDist; CEdit  m_iNeutDist;

public:
   CTrendFilterPanel(CTrendFilter *filter)
      : m_filter(filter),
        m_pendingEnabled(false),
        m_cur_method(MODE_SMA),
        m_cur_TF(PERIOD_CURRENT),
        m_cur_price(PRICE_CLOSE)
     {}

   virtual string GetName(void) const { return "TREND"; }
   void           SetFilter(CTrendFilter *f) { m_filter = f; }

   virtual bool Create(CEPBotPanel *parent, long chart_id, int subwin)
     {
      m_parent   = parent;
      m_chart_id = chart_id;
      m_subwin   = subwin;
      int y = FILTROS_CONTENT_Y;

      // Display
      if(!parent.CreateHdr(m_hdr, "f_h1", "TREND FILTER", y)) return false;
      y += PANEL_GAP_Y + 2;
      if(!parent.CreateLV(m_lStatus, m_eStatus, "f_lTS", "f_eTS", "Status:",       y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lMA,     m_eMA,     "f_lTM", "f_eTM", "MA Tendencia:", y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lDist,   m_eDist,   "f_lTD", "f_eTD", "Distancia:",   y)) return false;

      // Config
      y += PANEL_GAP_Y;
      y += PANEL_GAP_SECTION;
      if(!parent.CreateHdr(m_hdrConf, "ft_hConf", "CONFIGURACOES", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Toggle
      m_pendingEnabled = (m_filter != NULL) ? m_filter.IsEnabled() : false;
      if(!m_btnToggle.Create(chart_id, PFX + "f_bTrOn", subwin,
                             COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 22))
         return false;
      m_btnToggle.FontSize(8);
      if(!parent.AddControl(m_btnToggle)) return false;
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      y += 24;

      // Período MA
      {
       int p = (m_filter != NULL) ? m_filter.GetMAPeriod() : 200;
       if(!parent.CreateLI(m_lPeriod, m_iPeriod, "ft_lPd", "ft_iPd", "Periodo MA:", y)) return false;
       m_iPeriod.Text(IntegerToString(p));
      }
      y += PANEL_GAP_Y;

      // Método MA
      {
       ENUM_MA_METHOD meth = (m_filter != NULL) ? m_filter.GetMAMethod() : MODE_SMA;
       m_cur_method = meth;
       string methTexts[] = {"SMA", "EMA", "SMMA", "LWMA"};
       if(!parent.CreateRadioGroup(m_lMethod, m_bMethod, "ft_lMt", "ft_bMt", "Metodo MA:", methTexts, 4, y))
          return false;
       SetRadioSel(m_bMethod, 4, MAMethodToIndex(meth));
      }
      y += PANEL_GAP_Y + 2;

      // Time Frame
      {
       ENUM_TIMEFRAMES tf = (m_filter != NULL) ? m_filter.GetMATimeframe() : PERIOD_CURRENT;
       m_cur_TF = tf;
       if(!parent.CreateLB(m_lTF, m_bTF, "ft_lTF", "ft_bTF", "Time Frame:", y)) return false;
       m_bTF.Text(TFName(tf));
       m_bTF.ColorBackground(C'50,80,140'); m_bTF.Color(clrWhite);
      }
      y += PANEL_GAP_Y + 2;

      // Applied Price
      {
       ENUM_APPLIED_PRICE pr = (m_filter != NULL) ? m_filter.GetMAApplied() : PRICE_CLOSE;
       m_cur_price = pr;
       if(!parent.CreateLB(m_lPrice, m_bPrice, "ft_lPr", "ft_bPr", "Preco:", y)) return false;
       m_bPrice.Text(AppliedPriceShortText(pr));
       m_bPrice.ColorBackground(C'50,80,140'); m_bPrice.Color(clrWhite);
      }
      y += PANEL_GAP_Y + 2;

      // Zona Neutra
      {
       double nd = (m_filter != NULL) ? m_filter.GetNeutralDistance() : 0;
       if(!parent.CreateLI(m_lNeutDist, m_iNeutDist, "ft_lND", "ft_iND", "Zona Neutra (pts):", y)) return false;
       m_iNeutDist.Text(DoubleToString(nd, 0));
      }
      y += PANEL_GAP_Y + 8;

      return true;
     }

   virtual void Show(void)
     {
      m_hdr.Show();
      m_lStatus.Show(); m_eStatus.Show();
      m_lMA.Show(); m_eMA.Show();
      m_lDist.Show(); m_eDist.Show();
      m_hdrConf.Show(); m_btnToggle.Show();
      m_lPeriod.Show(); m_iPeriod.Show();
      m_lMethod.Show(); for(int i = 0; i < 4; i++) m_bMethod[i].Show();
      m_lTF.Show(); m_bTF.Show();
      m_lPrice.Show(); m_bPrice.Show();
      m_lNeutDist.Show(); m_iNeutDist.Show();
     }

   virtual void Hide(void)
     {
      m_hdr.Hide();
      m_lStatus.Hide(); m_eStatus.Hide();
      m_lMA.Hide(); m_eMA.Hide();
      m_lDist.Hide(); m_eDist.Hide();
      m_hdrConf.Hide(); m_btnToggle.Hide();
      m_lPeriod.Hide(); m_iPeriod.Hide();
      m_lMethod.Hide(); for(int i = 0; i < 4; i++) m_bMethod[i].Hide();
      m_lTF.Hide(); m_bTF.Hide();
      m_lPrice.Hide(); m_bPrice.Hide();
      m_lNeutDist.Hide(); m_iNeutDist.Hide();
     }

   virtual void Update(void)
     {
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      if(m_filter != NULL && m_filter.IsInitialized())
        {
         bool active = m_filter.IsTrendFilterActive() || m_filter.IsNeutralZoneActive();
         m_eStatus.Text(active ? "Ativo" : "Inativo");
         m_eStatus.Color(active ? CLR_POSITIVE : CLR_NEUTRAL);
         m_eMA.Text(DoubleToString(m_filter.GetMA(), _Digits));
         m_eMA.Color(CLR_VALUE);
         m_eDist.Text(DoubleToString(m_filter.GetDistanceFromMA(), 1) + " pts");
         m_eDist.Color(CLR_VALUE);
        }
      else
        {
         m_eStatus.Text("Nao iniciado"); m_eStatus.Color(CLR_NEUTRAL);
         m_eMA.Text("--");               m_eMA.Color(CLR_NEUTRAL);
         m_eDist.Text("--");             m_eDist.Color(CLR_NEUTRAL);
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
         _RefreshFieldState();
         return true;
        }
      for(int i = 0; i < 4; i++)
         if(name == m_bMethod[i].Name())
           { m_cur_method = IndexToMAMethod(i); SetRadioSel(m_bMethod, 4, i); return true; }
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
      return false;
     }

public:
   bool Apply(void)
     {
      if(m_filter == NULL)
         return false;

      int    period   = (int)StringToInteger(m_iPeriod.Text());
      double neutDist = StringToDouble(m_iNeutDist.Text());
      if(period <= 0 || period > 1000)
         return false;
      if(neutDist < 0)
         return false;

      m_filter.SetEnabled(m_pendingEnabled);
      m_filter.SetTrendFilterEnabled(m_pendingEnabled);
      m_filter.SetNeutralDistance(neutDist);
      bool coldOk = m_filter.SetMACold(period, m_cur_method, m_cur_TF, m_cur_price);

      return coldOk;
     }

   void SetEnabled(bool enable)
     {
      color bg = enable ? clrWhite : C'60,60,60';
      m_iPeriod.ReadOnly(!enable);
      m_iPeriod.ColorBackground(bg);
      m_iNeutDist.ReadOnly(!enable);
      m_iNeutDist.ColorBackground(bg);
      SetRadioGroupEnabled(m_lMethod, m_bMethod, 4, enable);
      SetButtonEnabled(m_lTF, m_bTF, enable);
      SetButtonEnabled(m_lPrice, m_bPrice, enable);
      if(enable)
        {
         m_bTF.ColorBackground(C'50,80,140'); m_bTF.Color(clrWhite);
         m_bPrice.ColorBackground(C'50,80,140'); m_bPrice.Color(clrWhite);
         SetRadioSel(m_bMethod, 4, MAMethodToIndex(m_cur_method));
        }
     }

private:

   void _RefreshFieldState(void)
     {
      bool on = m_pendingEnabled;
      SetEditEnabled(m_lPeriod, m_iPeriod, on);
      SetRadioGroupEnabled(m_lMethod, m_bMethod, 4, on);
      SetButtonEnabled(m_lTF, m_bTF, on);
      SetButtonEnabled(m_lPrice, m_bPrice, on);
      SetEditEnabled(m_lNeutDist, m_iNeutDist, on);
      if(on)
        {
         m_bTF.ColorBackground(C'50,80,140'); m_bTF.Color(clrWhite);
         m_bPrice.ColorBackground(C'50,80,140'); m_bPrice.Color(clrWhite);
         SetRadioSel(m_bMethod, 4, MAMethodToIndex(m_cur_method));
        }
     }
  };
//+------------------------------------------------------------------+
