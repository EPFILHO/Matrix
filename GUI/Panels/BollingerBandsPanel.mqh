//+------------------------------------------------------------------+
//|                                           BollingerBandsPanel.mqh |
//|                                         Copyright 2026, EP Filho |
//|         Sub-página GUI — Bollinger Bands Strategy                 |
//|                     Versão 1.11 - Claude Parte 035 (Claude Code) |
//+------------------------------------------------------------------+
// Incluído por Panel.mqh APÓS a definição completa de CEPBotPanel.
// NÃO incluir diretamente.
//
// CHANGELOG v1.11 (Parte 035) — AppliedPrice:
// + Botão "Preço" entre Time Frame e bloco SINAIS, cicla CLOSE→OPEN→HIGH→LOW→MEDIAN→TYPICAL
// + Apply() chama m_strategy.SetAppliedPrice(m_cur_price) — hot-reload via Deinit+Init
// + Reload/InitFields lêem GetAppliedPrice(); _RefreshFieldState/SetEnabled cobrem m_bPrice
//
// CHANGELOG v1.10 (Parte 033) — persistência:
// * Reload(): repopula campos GUI a partir do módulo (fix Issue #22)
//   chamado por ApplyLoadedConfig após atualizar os módulos
//
// CHANGELOG v1.09 (Parte 033) — Issue #29:
// * Novo método _RefreshFieldState() que respeita m_pendingEnabled
//   como toggle mestre (todos campos cinza/desabilitados quando OFF)
// * Update(): chama _RefreshFieldState() quando !m_locked
// * OnClick() do toggle: chama _RefreshFieldState() após alternar
//
// CHANGELOG v1.07 (Parte 029):
// * m_locked: Update() não sobrescreve visual quando EA rodando
//
// CHANGELOG v1.06 (Parte 029):
// * SetEnabled(): toggle ON/OFF cinza, campos fundo branco/cinza,
//   labels dim, TF + Mode/Entry/Exit radios cobertos
//
// CHANGELOG v1.05 (Parte 027) — Fase 2: Controle de Estado:
// * Removido botão APLICAR (m_btnApply) — aplicação centralizada
// * _OnApply convertido para Apply() público; adicionado SetEnabled()
//
// CHANGELOG v1.04 (Parte 027):
// + SetStrategy(): setter tipado para re-injeção de ponteiro
//   (usado por ReconnectModules e config persistence)
//+------------------------------------------------------------------+

class CBollingerBandsPanel : public CStrategyPanelBase
  {
private:
   CBollingerBandsStrategy *m_strategy;

   // Estado pendente (aplicado via APLICAR)
   bool               m_pendingEnabled;
   ENUM_TIMEFRAMES    m_cur_TF;
   ENUM_APPLIED_PRICE m_cur_price;   // Parte 035 — AppliedPrice
   ENUM_BB_SIGNAL_MODE m_cur_mode;
   ENUM_ENTRY_MODE    m_cur_entry;
   ENUM_EXIT_MODE     m_cur_exit;
   uint               m_statusExpiry;

   // Controles — display read-only
   CLabel   m_hdr;
   CLabel   m_lDesc;     // Descrição do que a estratégia faz
   CButton  m_btnToggle;
   CLabel   m_lStatus;   CLabel  m_eStatus;
   CLabel   m_lUpper;    CLabel  m_eUpper;
   CLabel   m_lMiddle;   CLabel  m_eMiddle;
   CLabel   m_lLower;    CLabel  m_eLower;
   CLabel   m_lWidth;    CLabel  m_eWidth;

   // Controles — config editável
   CLabel   m_hdrConf;
   CLabel   m_lPriority; CEdit   m_iPriority;
   CLabel   m_lPeriod;   CEdit   m_iPeriod;
   CLabel   m_lDev;      CEdit   m_iDev;
   CLabel   m_lDevHint;  // Legenda desvio
   CLabel   m_lTF;       CButton m_bTF;
   CLabel   m_lPrice;    CButton m_bPrice;   // Parte 035 — AppliedPrice
   CLabel   m_hdrSig;
   CLabel   m_lMode;     CButton m_bMode[3];
   CLabel   m_lModeDesc;
   CLabel   m_lEntry;    CButton m_bEntry[2];
   CLabel   m_lEntryDesc;
   CLabel   m_lExit;     CButton m_bExit[3];
   CLabel   m_lExitDesc;
   CLabel   m_lblStatus;

public:
   CBollingerBandsPanel(CBollingerBandsStrategy *strategy)
      : m_strategy(strategy),
        m_pendingEnabled(false),
        m_cur_TF(PERIOD_CURRENT),
        m_cur_price(PRICE_CLOSE),
        m_cur_mode(BB_MODE_FFFD),
        m_cur_entry(ENTRY_NEXT_CANDLE),
        m_cur_exit(EXIT_TP_SL),
        m_statusExpiry(0)
     {}

   virtual string GetName(void) const { return "BB"; }
   void           SetStrategy(CBollingerBandsStrategy *s) { m_strategy = s; }

   bool Apply(string &outErr)
     {
      outErr = "";
      if(m_strategy == NULL)
         return false;

      // Clear highlights
      ClearFieldError(m_iPeriod); ClearFieldError(m_iDev); ClearFieldError(m_iPriority);

      int period = (int)StringToInteger(m_iPeriod.Text());
      double dev = StringToDouble(m_iDev.Text());
      int prio = (int)StringToInteger(m_iPriority.Text());

      // Validação com highlight individual
      string errFields = "";
      if(period < 2 || period > 500) { errFields += "BB Per, ";   MarkFieldError(m_iPeriod); }
      if(dev <= 0 || dev > 10.0)     { errFields += "BB Dev, ";   MarkFieldError(m_iDev); }
      if(prio <= 0)                  { errFields += "BB Prior, "; MarkFieldError(m_iPriority); }

      if(errFields != "")
        {
         outErr = errFields;
         m_lblStatus.Text("Valores invalidos"); m_lblStatus.Color(CLR_NEGATIVE);
         m_statusExpiry = GetTickCount() + 10000; ChartRedraw();
         return false;
        }

      // Aplicar
      if(!m_strategy.SetPeriod(period) || !m_strategy.SetDeviation(dev))
         return false;

      // Auto-ajuste de prioridade se conflitar com outra estratégia
      if(m_parent != NULL)
        {
         int resolved = m_parent.ResolveStrategyPriority(prio, "BB Strategy");
         if(resolved != prio)
           {
            prio = resolved;
            m_iPriority.Text(IntegerToString(prio));
           }
        }

      m_strategy.SetPriority(prio);
      m_strategy.SetTimeframe(m_cur_TF);
      m_strategy.SetAppliedPrice(m_cur_price);
      m_strategy.SetSignalMode(m_cur_mode);
      m_strategy.SetEntryMode(m_cur_entry);
      m_strategy.SetExitMode(m_cur_exit);
      m_strategy.SetEnabled(m_pendingEnabled);
      ChartRedraw();
      return true;
     }

   void SetEnabled(bool enable)
     {
      m_locked = !enable;
      color fg = enable ? clrBlack : C'160,160,160';
      m_iPeriod.ReadOnly(!enable);   m_iPeriod.Color(fg);
      m_iDev.ReadOnly(!enable);      m_iDev.Color(fg);
      m_iPriority.ReadOnly(!enable); m_iPriority.Color(fg);
      if(enable)
        {
         if(m_iPeriod.ColorBackground() != CLR_FIELD_ERROR)   m_iPeriod.ColorBackground(clrWhite);
         if(m_iDev.ColorBackground() != CLR_FIELD_ERROR)      m_iDev.ColorBackground(clrWhite);
         if(m_iPriority.ColorBackground() != CLR_FIELD_ERROR) m_iPriority.ColorBackground(clrWhite);
        }
      else
        {
         if(m_iPeriod.ColorBackground() != CLR_FIELD_ERROR)   m_iPeriod.ColorBackground(C'220,220,220');
         if(m_iDev.ColorBackground() != CLR_FIELD_ERROR)      m_iDev.ColorBackground(C'220,220,220');
         if(m_iPriority.ColorBackground() != CLR_FIELD_ERROR) m_iPriority.ColorBackground(C'220,220,220');
        }
      // Labels
      color lc = enable ? CLR_LABEL : C'180,180,180';
      m_lPriority.Color(lc); m_lPeriod.Color(lc); m_lDev.Color(lc);
      // Toggle ON/OFF
      if(!enable)
        { m_btnToggle.ColorBackground(C'160,160,160'); m_btnToggle.Color(C'200,200,200'); }
      else
         ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      // Buttons + radios
      SetButtonEnabled(m_lTF, m_bTF, enable);
      SetButtonEnabled(m_lPrice, m_bPrice, enable);
      SetRadioGroupEnabled(m_lMode, m_bMode, 3, enable);
      SetRadioGroupEnabled(m_lEntry, m_bEntry, 2, enable);
      SetRadioGroupEnabled(m_lExit, m_bExit, 3, enable);
      if(enable)
        {
         m_bTF.ColorBackground(C'50,80,140'); m_bTF.Color(clrWhite);
         m_bPrice.ColorBackground(C'50,80,140'); m_bPrice.Color(clrWhite);
         SetRadioSel(m_bMode, 3, (int)m_cur_mode);
         SetRadioSel(m_bEntry, 2, (int)m_cur_entry);
         SetRadioSel(m_bExit, 3, (int)m_cur_exit);
        }
     }

   virtual bool Create(CEPBotPanel *parent, long chart_id, int subwin)
     {
      m_parent   = parent;
      m_chart_id = chart_id;
      m_subwin   = subwin;
      int y = ESTRAT_CONTENT_Y;

      if(!parent.CreateHdr(m_hdr, "e_hBB", "BOLLINGER BANDS STRATEGY", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Descrição da estratégia
      if(!m_lDesc.Create(chart_id, PFX + "bb_lDesc", subwin,
                          COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lDesc.Font("Tahoma"); m_lDesc.FontSize(7); m_lDesc.Color(CLR_NEUTRAL);
      m_lDesc.Text("Sinais de compra/venda baseados nas Bandas de Bollinger");
      if(!parent.AddControl(m_lDesc)) return false;
      y += 15;

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

      // Prioridade (para resolução de conflitos entre estratégias)
      {
       int pr = (m_strategy != NULL) ? m_strategy.GetPriority() : 3;
       if(!parent.CreateLI(m_lPriority, m_iPriority, "bb_lPR", "bb_iPR", "Prioridade:", y)) return false;
       m_iPriority.Text(IntegerToString(pr));
      }
      y += PANEL_GAP_Y;

      if(!parent.CreateLI(m_lPeriod, m_iPeriod, "bb_lPD", "bb_iPD", "Periodo:", y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLI(m_lDev, m_iDev, "bb_lDV", "bb_iDV", "Desvio:", y)) return false;
      y += PANEL_GAP_Y;
      // Dica sobre desvio
      if(!m_lDevHint.Create(chart_id, PFX + "bb_lDVH", subwin,
                             COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lDevHint.Font("Tahoma"); m_lDevHint.FontSize(7); m_lDevHint.Color(CLR_NEUTRAL);
      m_lDevHint.Text("Desvio padrão das bandas (ex: 2.0 = 2 sigma)");
      if(!parent.AddControl(m_lDevHint)) return false;
      y += 15;
      if(!parent.CreateLB(m_lTF, m_bTF, "bb_lTF", "bb_bTF", "Time Frame:", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Parte 035 — Applied Price
      {
       ENUM_APPLIED_PRICE pr = (m_strategy != NULL) ? m_strategy.GetAppliedPrice() : PRICE_CLOSE;
       m_cur_price = pr;
       if(!parent.CreateLB(m_lPrice, m_bPrice, "bb_lPr", "bb_bPr", "Preco:", y)) return false;
       m_bPrice.Text(AppliedPriceShortText(pr));
       m_bPrice.ColorBackground(C'50,80,140'); m_bPrice.Color(clrWhite);
      }
      y += PANEL_GAP_Y + 2;

      // Modo de sinal (radio 3)
      y += PANEL_GAP_SECTION;
      if(!parent.CreateHdr(m_hdrSig, "bb_h2", "SINAIS", y)) return false;
      y += PANEL_GAP_Y + 2;
      {
       string modeTexts[] = {"FFFD", "REBOUND", "BREAKOUT"};
       if(!parent.CreateRadioGroup(m_lMode, m_bMode, "bb_lMD", "bb_bMD", "Modo:", modeTexts, 3, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;

      // Legenda dinâmica do modo
      if(!m_lModeDesc.Create(chart_id, PFX + "bb_lMDesc", subwin,
                              COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lModeDesc.Font("Tahoma"); m_lModeDesc.FontSize(7); m_lModeDesc.Color(CLR_NEUTRAL);
      m_lModeDesc.Text(_ModeDesc(BB_MODE_FFFD));
      if(!parent.AddControl(m_lModeDesc)) return false;
      y += 15;

      y += PANEL_GAP_SECTION;
      {
       string entTexts[] = {"PRÓXIMO CANDLE", "2º CANDLE"};
       if(!parent.CreateRadioGroup(m_lEntry, m_bEntry, "bb_lEN", "bb_bEN", "Entrada:", entTexts, 2, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;

      // Legenda dinâmica de entrada
      if(!m_lEntryDesc.Create(chart_id, PFX + "bb_eLgD", subwin,
                               COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lEntryDesc.Font("Tahoma"); m_lEntryDesc.FontSize(7); m_lEntryDesc.Color(CLR_NEUTRAL);
      m_lEntryDesc.Text(_EntryDesc(m_cur_entry));
      if(!parent.AddControl(m_lEntryDesc)) return false;
      y += 15;

      {
       string extTexts[] = {"FCO", "VM", "TP-SL"};
       if(!parent.CreateRadioGroup(m_lExit, m_bExit, "bb_lEX", "bb_bEX", "Saida:", extTexts, 3, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;

      // Legenda dinâmica de saída
      if(!m_lExitDesc.Create(chart_id, PFX + "bb_legD", subwin,
                              COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lExitDesc.Font("Tahoma"); m_lExitDesc.FontSize(7); m_lExitDesc.Color(CLR_NEUTRAL);
      m_lExitDesc.Text(_ExitDesc(m_cur_exit));
      if(!parent.AddControl(m_lExitDesc)) return false;

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
      m_hdr.Show(); m_lDesc.Show(); m_btnToggle.Show();
      m_lStatus.Show(); m_eStatus.Show();
      m_lUpper.Show(); m_eUpper.Show();
      m_lMiddle.Show(); m_eMiddle.Show();
      m_lLower.Show(); m_eLower.Show();
      m_lWidth.Show(); m_eWidth.Show();
      m_hdrConf.Show();
      m_lPriority.Show(); m_iPriority.Show();
      m_lPeriod.Show(); m_iPeriod.Show();
      m_lDev.Show(); m_iDev.Show(); m_lDevHint.Show();
      m_lTF.Show(); m_bTF.Show();
      m_lPrice.Show(); m_bPrice.Show();
      m_hdrSig.Show();
      m_lMode.Show(); for(int i = 0; i < 3; i++) m_bMode[i].Show();
      m_lModeDesc.Show();
      m_lEntry.Show(); for(int i = 0; i < 2; i++) m_bEntry[i].Show();
      m_lEntryDesc.Show();
      m_lExit.Show();  for(int i = 0; i < 3; i++) m_bExit[i].Show();
      m_lExitDesc.Show();
      m_lblStatus.Show();
     }

   virtual void Hide(void)
     {
      m_hdr.Hide(); m_lDesc.Hide(); m_btnToggle.Hide();
      m_lStatus.Hide(); m_eStatus.Hide();
      m_lUpper.Hide(); m_eUpper.Hide();
      m_lMiddle.Hide(); m_eMiddle.Hide();
      m_lLower.Hide(); m_eLower.Hide();
      m_lWidth.Hide(); m_eWidth.Hide();
      m_hdrConf.Hide();
      m_lPriority.Hide(); m_iPriority.Hide();
      m_lPeriod.Hide(); m_iPeriod.Hide();
      m_lDev.Hide(); m_iDev.Hide(); m_lDevHint.Hide();
      m_lTF.Hide(); m_bTF.Hide();
      m_lPrice.Hide(); m_bPrice.Hide();
      m_hdrSig.Hide();
      m_lMode.Hide(); for(int i = 0; i < 3; i++) m_bMode[i].Hide();
      m_lModeDesc.Hide();
      m_lEntry.Hide(); for(int i = 0; i < 2; i++) m_bEntry[i].Hide();
      m_lEntryDesc.Hide();
      m_lExit.Hide();  for(int i = 0; i < 3; i++) m_bExit[i].Hide();
      m_lExitDesc.Hide();
      m_lblStatus.Hide();
     }

   virtual void Update(void)
     {
      if(!m_locked)
        {
         ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
         _RefreshFieldState();
        }
      m_lModeDesc.Text(_ModeDesc(m_cur_mode));
      m_lEntryDesc.Text(_EntryDesc(m_cur_entry));
      m_lExitDesc.Text(_ExitDesc(m_cur_exit));
      if(m_strategy != NULL && m_strategy.IsInitialized() && m_strategy.GetEnabled())
        {
         m_eStatus.Text("Ativo (Prioridade:" + IntegerToString(m_strategy.GetPriority()) + ")");
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
           { m_cur_entry = (i == 0) ? ENTRY_NEXT_CANDLE : ENTRY_2ND_CANDLE; SetRadioSel(m_bEntry, 2, i); m_lEntryDesc.Text(_EntryDesc(m_cur_entry)); return true; }
      // Exit radio
      for(int i = 0; i < 3; i++)
         if(name == m_bExit[i].Name())
           { m_cur_exit = (i == 0) ? EXIT_FCO : (i == 1) ? EXIT_VM : EXIT_TP_SL; SetRadioSel(m_bExit, 3, i); m_lExitDesc.Text(_ExitDesc(m_cur_exit)); return true; }
      return false;
     }

private:
   string _ModeDesc(ENUM_BB_SIGNAL_MODE mode)
     {
      switch(mode)
        {
         case BB_MODE_FFFD:     return "FFFD: candle[2] fecha fora, candle[1] volta p/ dentro";
         case BB_MODE_REBOUND:  return "REBOUND: preço toca a banda e fecha na direção oposta";
         case BB_MODE_BREAKOUT: return "BREAKOUT: preço rompe a banda (sinal de tendência)";
         default:               return "";
        }
     }

   string _EntryDesc(ENUM_ENTRY_MODE mode)
     {
      switch(mode)
        {
         case ENTRY_NEXT_CANDLE: return "Entra na abertura do próximo candle";
         case ENTRY_2ND_CANDLE:  return "Espera confirmação no 2º candle (E2C)";
         default:                return "";
        }
     }

   string _ExitDesc(ENUM_EXIT_MODE mode)
     {
      switch(mode)
        {
         case EXIT_FCO:   return "FCO: Fechar no Cruzamento da Middle";
         case EXIT_VM:    return "VM: Virar a mão (inverte posição)";
         case EXIT_TP_SL: return "TP/SL: Sair no Take Profit ou Stop Loss";
         default:         return "";
        }
     }

   void _InitFields(void)
     {
      int              pr  = (m_strategy != NULL) ? m_strategy.GetPriority()    : 3;
      int              pd  = (m_strategy != NULL) ? m_strategy.GetPeriod()      : 20;
      double           dv  = (m_strategy != NULL) ? m_strategy.GetDeviation()   : 2.0;
      ENUM_TIMEFRAMES  tf  = (m_strategy != NULL) ? m_strategy.GetTimeframe()   : PERIOD_CURRENT;
      ENUM_APPLIED_PRICE px = (m_strategy != NULL) ? m_strategy.GetAppliedPrice(): PRICE_CLOSE;
      ENUM_BB_SIGNAL_MODE md = (m_strategy != NULL) ? m_strategy.GetSignalMode() : BB_MODE_FFFD;
      ENUM_ENTRY_MODE  en  = (m_strategy != NULL) ? m_strategy.GetEntryMode()   : ENTRY_NEXT_CANDLE;
      ENUM_EXIT_MODE   ex  = (m_strategy != NULL) ? m_strategy.GetExitMode()    : EXIT_TP_SL;

      m_cur_TF    = tf;
      m_cur_price = px;
      m_cur_mode  = md;
      m_cur_entry = en;
      m_cur_exit  = ex;

      m_iPriority.Text(IntegerToString(pr));
      m_iPeriod.Text(IntegerToString(pd));
      m_iDev.Text(DoubleToString(dv, 1));
      m_bTF.Text(TFName(tf));
      m_bTF.ColorBackground(C'50,80,140'); m_bTF.Color(clrWhite);
      m_bPrice.Text(AppliedPriceShortText(px));
      m_bPrice.ColorBackground(C'50,80,140'); m_bPrice.Color(clrWhite);
      SetRadioSel(m_bMode, 3, (int)md);
      SetRadioSel(m_bEntry, 2, (en == ENTRY_NEXT_CANDLE) ? 0 : 1);
      SetRadioSel(m_bExit,  3, (ex == EXIT_FCO) ? 0 : (ex == EXIT_VM) ? 1 : 2);
     }

   virtual void Reload(void) override
     {
      m_pendingEnabled = (m_strategy != NULL) ? m_strategy.GetEnabled() : false;
      _InitFields();
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      _RefreshFieldState();
     }

   void _RefreshFieldState(void)
     {
      bool on = m_pendingEnabled;
      SetEditEnabled(m_lPriority, m_iPriority, on);
      SetEditEnabled(m_lPeriod,   m_iPeriod,   on);
      SetEditEnabled(m_lDev,      m_iDev,      on);
      SetButtonEnabled(m_lTF, m_bTF, on);
      SetButtonEnabled(m_lPrice, m_bPrice, on);
      SetRadioGroupEnabled(m_lMode,  m_bMode,  3, on);
      SetRadioGroupEnabled(m_lEntry, m_bEntry, 2, on);
      SetRadioGroupEnabled(m_lExit,  m_bExit,  3, on);
      if(on)
        {
         m_bTF.ColorBackground(C'50,80,140'); m_bTF.Color(clrWhite);
         m_bPrice.ColorBackground(C'50,80,140'); m_bPrice.Color(clrWhite);
         SetRadioSel(m_bMode,  3, (int)m_cur_mode);
         SetRadioSel(m_bEntry, 2, (m_cur_entry == ENTRY_NEXT_CANDLE) ? 0 : 1);
         SetRadioSel(m_bExit,  3, (m_cur_exit == EXIT_FCO) ? 0 : (m_cur_exit == EXIT_VM) ? 1 : 2);
        }
     }
  };
//+------------------------------------------------------------------+
