//+------------------------------------------------------------------+
//|                                                 MACrossPanel.mqh |
//|                                         Copyright 2026, EP Filho |
//|         Sub-página GUI — MA Cross Strategy                        |
//|                     Versão 1.05 - Claude Parte 027 (Claude Code) |
//+------------------------------------------------------------------+
// Incluído por Panel.mqh APÓS a definição completa de CEPBotPanel.
// NÃO incluir diretamente.
//
// CHANGELOG v1.05 (Parte 027) — Fase 2: Controle de Estado:
// * Removido botão APLICAR (m_btnApply) — aplicação centralizada
// * _OnApply convertido para Apply() público; adicionado SetEnabled()
//
// CHANGELOG v1.04 (Parte 027):
// + SetStrategy(): setter tipado para re-injeção de ponteiro
//   (usado por ReconnectModules e config persistence)
//+------------------------------------------------------------------+

class CMACrossPanel : public CStrategyPanelBase
  {
private:
   CMACrossStrategy *m_strategy;

   // Estado pendente (aplicado via APLICAR)
   bool               m_pendingEnabled;
   ENUM_MA_METHOD     m_cur_fastMethod;
   ENUM_MA_METHOD     m_cur_slowMethod;
   ENUM_TIMEFRAMES    m_cur_fastTF;
   ENUM_TIMEFRAMES    m_cur_slowTF;
   ENUM_APPLIED_PRICE m_cur_fastPrice;
   ENUM_APPLIED_PRICE m_cur_slowPrice;
   ENUM_ENTRY_MODE    m_cur_entry;
   ENUM_EXIT_MODE     m_cur_exit;
   uint               m_statusExpiry;

   // Controles — display read-only
   CLabel   m_hdr;
   CButton  m_btnToggle;
   CLabel   m_lStatus;   CLabel  m_eStatus;
   CLabel   m_lFast;     CLabel  m_eFast;
   CLabel   m_lSlow;     CLabel  m_eSlow;
   CLabel   m_lCross;    CLabel  m_eCross;
   CLabel   m_lCandles;  CLabel  m_eCandles;

   // Controles — config editável
   CLabel   m_hdrConf;
   CLabel   m_lPriority; CEdit   m_iPriority;
   CLabel   m_lFastP;    CEdit   m_iFastP;
   CLabel   m_lFastM;    CButton m_bFastM[4];
   CLabel   m_lFastTF;   CButton m_bFastTF;
   CLabel   m_lFastPr;   CButton m_bFastPr;
   CLabel   m_lSlowP;    CEdit   m_iSlowP;
   CLabel   m_lSlowM;    CButton m_bSlowM[4];
   CLabel   m_lSlowTF;   CButton m_bSlowTF;
   CLabel   m_lSlowPr;   CButton m_bSlowPr;
   CLabel   m_hdrSig;
   CLabel   m_lEntry;    CButton m_bEntry[2];
   CLabel   m_lEntryDesc;
   CLabel   m_lExit;     CButton m_bExit[3];
   CLabel   m_lExitDesc;
   CLabel   m_lblStatus;

public:
   CMACrossPanel(CMACrossStrategy *strategy)
      : m_strategy(strategy),
        m_pendingEnabled(false),
        m_cur_fastMethod(MODE_SMA), m_cur_slowMethod(MODE_SMA),
        m_cur_fastTF(PERIOD_CURRENT), m_cur_slowTF(PERIOD_CURRENT),
        m_cur_fastPrice(PRICE_CLOSE), m_cur_slowPrice(PRICE_CLOSE),
        m_cur_entry(ENTRY_NEXT_CANDLE), m_cur_exit(EXIT_FCO),
        m_statusExpiry(0)
     {}

   virtual string GetName(void) const { return "MA CROSS"; }
   void           SetStrategy(CMACrossStrategy *s) { m_strategy = s; }

   virtual bool Create(CEPBotPanel *parent, long chart_id, int subwin)
     {
      m_parent   = parent;
      m_chart_id = chart_id;
      m_subwin   = subwin;
      int y = ESTRAT_CONTENT_Y;

      if(!parent.CreateHdr(m_hdr, "e_h2", "MA CROSS STRATEGY", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Toggle ON/OFF
      m_pendingEnabled = (m_strategy != NULL) ? m_strategy.GetEnabled() : false;
      if(!m_btnToggle.Create(chart_id, PFX + "e_bMAOn", subwin,
                             COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + 20))
         return false;
      m_btnToggle.FontSize(8);
      if(!parent.AddControl(m_btnToggle)) return false;
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      y += 24;

      // Display: Status, MAs, Cross, Candles
      if(!parent.CreateLV(m_lStatus, m_eStatus, "e_lMS", "e_eMS", "Status:", y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lFast, m_eFast, "e_lMF", "e_eMF", "MA Rapida:", y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lSlow, m_eSlow, "e_lML", "e_eML", "MA Lenta:", y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lCross, m_eCross, "e_lMC", "e_eMC", "Ultimo Cruz.:", y)) return false;
      y += PANEL_GAP_Y;
      if(!parent.CreateLV(m_lCandles, m_eCandles, "e_lMN", "e_eMN", "Candles Apos:", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Config: FAST MA
      y += PANEL_GAP_SECTION;
      if(!parent.CreateHdr(m_hdrConf, "ce_h1", "CONFIGURACOES", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Prioridade
      {
       int pr = (m_strategy != NULL) ? m_strategy.GetPriority() : 10;
       if(!parent.CreateLI(m_lPriority, m_iPriority, "ce_lPR", "ce_iPR", "Prioridade:", y)) return false;
       m_iPriority.Text(IntegerToString(pr));
      }
      y += PANEL_GAP_Y;

      if(!parent.CreateLI(m_lFastP, m_iFastP, "ce_lFP", "ce_iFP", "Periodo Rapida:", y)) return false;
      y += PANEL_GAP_Y;
      {
       string fmTexts[] = {"SMA", "EMA", "SMMA", "LWMA"};
       if(!parent.CreateRadioGroup(m_lFastM, m_bFastM, "ce_lFM", "ce_bFM", "Metodo Rapida:", fmTexts, 4, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;
      if(!parent.CreateLB(m_lFastTF, m_bFastTF, "ce_lFT", "ce_bFT", "Time Frame Rapida:", y)) return false;
      y += PANEL_GAP_Y + 2;
      if(!parent.CreateLB(m_lFastPr, m_bFastPr, "ce_lFPr", "ce_bFPr", "Preco Rapida:", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Config: SLOW MA
      y += PANEL_GAP_SECTION;
      if(!parent.CreateLI(m_lSlowP, m_iSlowP, "ce_lSP", "ce_iSP", "Periodo Lenta:", y)) return false;
      y += PANEL_GAP_Y;
      {
       string smTexts[] = {"SMA", "EMA", "SMMA", "LWMA"};
       if(!parent.CreateRadioGroup(m_lSlowM, m_bSlowM, "ce_lSM", "ce_bSM", "Metodo Lenta:", smTexts, 4, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;
      if(!parent.CreateLB(m_lSlowTF, m_bSlowTF, "ce_lST2", "ce_bST2", "Time Frame Lenta:", y)) return false;
      y += PANEL_GAP_Y + 2;
      if(!parent.CreateLB(m_lSlowPr, m_bSlowPr, "ce_lSPr", "ce_bSPr", "Preco Lenta:", y)) return false;
      y += PANEL_GAP_Y + 2;

      // Config: SINAIS
      y += PANEL_GAP_SECTION;
      if(!parent.CreateHdr(m_hdrSig, "ce_h2", "SINAIS", y)) return false;
      y += PANEL_GAP_Y + 2;
      {
       string entTexts[] = {"PROX. CANDLE", "2o. CANDLE"};
       if(!parent.CreateRadioGroup(m_lEntry, m_bEntry, "ce_lEN", "ce_bEN", "Entrada:", entTexts, 2, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;

      // Legenda dinâmica de entrada
      if(!m_lEntryDesc.Create(chart_id, PFX + "ce_eLgD", subwin,
                               COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lEntryDesc.Font("Tahoma"); m_lEntryDesc.FontSize(7); m_lEntryDesc.Color(CLR_NEUTRAL);
      m_lEntryDesc.Text(_EntryDesc(m_cur_entry));
      if(!parent.AddControl(m_lEntryDesc)) return false;
      y += 15;

      {
       string extTexts[] = {"FCO", "VM", "TP-SL"};
       if(!parent.CreateRadioGroup(m_lExit, m_bExit, "ce_lEX", "ce_bEX", "Saida:", extTexts, 3, y))
          return false;
      }
      y += PANEL_GAP_Y + 2;

      // Legenda dinâmica de saída
      if(!m_lExitDesc.Create(chart_id, PFX + "e_legD", subwin,
                              COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + 13))
         return false;
      m_lExitDesc.Font("Tahoma"); m_lExitDesc.FontSize(7); m_lExitDesc.Color(CLR_NEUTRAL);
      m_lExitDesc.Text(_ExitDesc(m_cur_exit));
      if(!parent.AddControl(m_lExitDesc)) return false;

      // Label de status
      if(!m_lblStatus.Create(chart_id, PFX + "e_stMA", subwin,
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
      m_lFast.Show(); m_eFast.Show();
      m_lSlow.Show(); m_eSlow.Show();
      m_lCross.Show(); m_eCross.Show();
      m_lCandles.Show(); m_eCandles.Show();
      m_hdrConf.Show();
      m_lPriority.Show(); m_iPriority.Show();
      m_lFastP.Show(); m_iFastP.Show();
      m_lFastM.Show(); for(int i = 0; i < 4; i++) m_bFastM[i].Show();
      m_lFastTF.Show(); m_bFastTF.Show();
      m_lFastPr.Show(); m_bFastPr.Show();
      m_lSlowP.Show(); m_iSlowP.Show();
      m_lSlowM.Show(); for(int i = 0; i < 4; i++) m_bSlowM[i].Show();
      m_lSlowTF.Show(); m_bSlowTF.Show();
      m_lSlowPr.Show(); m_bSlowPr.Show();
      m_hdrSig.Show();
      m_lEntry.Show(); for(int i = 0; i < 2; i++) m_bEntry[i].Show();
      m_lEntryDesc.Show();
      m_lExit.Show();  for(int i = 0; i < 3; i++) m_bExit[i].Show();
      m_lExitDesc.Show();
      m_lblStatus.Show();
     }

   virtual void Hide(void)
     {
      m_hdr.Hide(); m_btnToggle.Hide();
      m_lStatus.Hide(); m_eStatus.Hide();
      m_lFast.Hide(); m_eFast.Hide();
      m_lSlow.Hide(); m_eSlow.Hide();
      m_lCross.Hide(); m_eCross.Hide();
      m_lCandles.Hide(); m_eCandles.Hide();
      m_hdrConf.Hide();
      m_lPriority.Hide(); m_iPriority.Hide();
      m_lFastP.Hide(); m_iFastP.Hide();
      m_lFastM.Hide(); for(int i = 0; i < 4; i++) m_bFastM[i].Hide();
      m_lFastTF.Hide(); m_bFastTF.Hide();
      m_lFastPr.Hide(); m_bFastPr.Hide();
      m_lSlowP.Hide(); m_iSlowP.Hide();
      m_lSlowM.Hide(); for(int i = 0; i < 4; i++) m_bSlowM[i].Hide();
      m_lSlowTF.Hide(); m_bSlowTF.Hide();
      m_lSlowPr.Hide(); m_bSlowPr.Hide();
      m_hdrSig.Hide();
      m_lEntry.Hide(); for(int i = 0; i < 2; i++) m_bEntry[i].Hide();
      m_lEntryDesc.Hide();
      m_lExit.Hide();  for(int i = 0; i < 3; i++) m_bExit[i].Hide();
      m_lExitDesc.Hide();
      m_lblStatus.Hide();
     }

   virtual void Update(void)
     {
      ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
      m_lEntryDesc.Text(_EntryDesc(m_cur_entry));
      m_lExitDesc.Text(_ExitDesc(m_cur_exit));
      if(m_strategy != NULL && m_strategy.IsInitialized() && m_strategy.GetEnabled())
        {
         m_eStatus.Text("Ativo (Prioridade:" + IntegerToString(m_strategy.GetPriority()) + ")");
         m_eStatus.Color(CLR_POSITIVE);
         m_eFast.Text(DoubleToString(m_strategy.GetMAFast(), _Digits));
         m_eFast.Color(CLR_VALUE);
         m_eSlow.Text(DoubleToString(m_strategy.GetMASlow(), _Digits));
         m_eSlow.Color(CLR_VALUE);
         ENUM_SIGNAL_TYPE lc = m_strategy.GetLastCross();
         string crossTxt = (lc == SIGNAL_BUY) ? "BUY" : (lc == SIGNAL_SELL) ? "SELL" : "Nenhum";
         color  crossClr = (lc == SIGNAL_BUY) ? CLR_POSITIVE : (lc == SIGNAL_SELL) ? CLR_NEGATIVE : CLR_NEUTRAL;
         m_eCross.Text(crossTxt); m_eCross.Color(crossClr);
         m_eCandles.Text(IntegerToString(m_strategy.GetCandlesAfterCross()));
         m_eCandles.Color(CLR_VALUE);
        }
      else
        {
         m_eStatus.Text("Inativo");  m_eStatus.Color(CLR_NEUTRAL);
         m_eFast.Text("--");         m_eFast.Color(CLR_NEUTRAL);
         m_eSlow.Text("--");         m_eSlow.Color(CLR_NEUTRAL);
         m_eCross.Text("--");        m_eCross.Color(CLR_NEUTRAL);
         m_eCandles.Text("--");      m_eCandles.Color(CLR_NEUTRAL);
        }
      // Auto-clear status message
      if(m_statusExpiry > 0 && GetTickCount() >= m_statusExpiry)
        { m_lblStatus.Text(""); m_statusExpiry = 0; ChartRedraw(); }
     }

   virtual bool OnClick(string name)
     {
      // Toggle
      if(name == m_btnToggle.Name())
        {
         m_btnToggle.Pressed(false);
         m_pendingEnabled = !m_pendingEnabled;
         ApplyToggleStyle(m_btnToggle, m_pendingEnabled);
         return true;
        }
      // Fast Method radio
      for(int i = 0; i < 4; i++)
         if(name == m_bFastM[i].Name())
           { m_cur_fastMethod = IndexToMAMethod(i); SetRadioSel(m_bFastM, 4, i); return true; }
      // Slow Method radio
      for(int i = 0; i < 4; i++)
         if(name == m_bSlowM[i].Name())
           { m_cur_slowMethod = IndexToMAMethod(i); SetRadioSel(m_bSlowM, 4, i); return true; }
      // Entry radio
      for(int i = 0; i < 2; i++)
         if(name == m_bEntry[i].Name())
           { m_cur_entry = (i == 0) ? ENTRY_NEXT_CANDLE : ENTRY_2ND_CANDLE; SetRadioSel(m_bEntry, 2, i); m_lEntryDesc.Text(_EntryDesc(m_cur_entry)); return true; }
      // Exit radio
      for(int i = 0; i < 3; i++)
         if(name == m_bExit[i].Name())
           { m_cur_exit = (i == 0) ? EXIT_FCO : (i == 1) ? EXIT_VM : EXIT_TP_SL; SetRadioSel(m_bExit, 3, i); m_lExitDesc.Text(_ExitDesc(m_cur_exit)); return true; }
      // Fast TF cycle
      if(name == m_bFastTF.Name())
        {
         m_bFastTF.Pressed(false);
         m_cur_fastTF = CycleTF(m_cur_fastTF);
         m_bFastTF.Text(TFName(m_cur_fastTF));
         return true;
        }
      // Slow TF cycle
      if(name == m_bSlowTF.Name())
        {
         m_bSlowTF.Pressed(false);
         m_cur_slowTF = CycleTF(m_cur_slowTF);
         m_bSlowTF.Text(TFName(m_cur_slowTF));
         return true;
        }
      // Fast Price cycle
      if(name == m_bFastPr.Name())
        {
         m_bFastPr.Pressed(false);
         m_cur_fastPrice = CycleAppliedPrice(m_cur_fastPrice);
         m_bFastPr.Text(AppliedPriceShortText(m_cur_fastPrice));
         return true;
        }
      // Slow Price cycle
      if(name == m_bSlowPr.Name())
        {
         m_bSlowPr.Pressed(false);
         m_cur_slowPrice = CycleAppliedPrice(m_cur_slowPrice);
         m_bSlowPr.Text(AppliedPriceShortText(m_cur_slowPrice));
         return true;
        }
      return false;
     }

private:
   string _EntryDesc(ENUM_ENTRY_MODE mode)
     {
      switch(mode)
        {
         case ENTRY_NEXT_CANDLE: return "Entra na abertura do proximo candle";
         case ENTRY_2ND_CANDLE:  return "Espera confirmacao no 2o candle (E2C)";
         default:                return "";
        }
     }

   string _ExitDesc(ENUM_EXIT_MODE mode)
     {
      switch(mode)
        {
         case EXIT_FCO:   return "FCO: Fechar no Cruzamento Oposto";
         case EXIT_VM:    return "VM: Virar a mao (inverte posicao)";
         case EXIT_TP_SL: return "TP/SL: Sair no Take Profit ou Stop Loss";
         default:         return "";
        }
     }

   void _InitFields(void)
     {
      int                pr  = (m_strategy != NULL) ? m_strategy.GetPriority()      : 10;
      ENUM_MA_METHOD     fm  = (m_strategy != NULL) ? m_strategy.GetFastMethod()    : MODE_SMA;
      ENUM_MA_METHOD     sm  = (m_strategy != NULL) ? m_strategy.GetSlowMethod()    : MODE_SMA;
      ENUM_TIMEFRAMES    ft  = (m_strategy != NULL) ? m_strategy.GetFastTimeframe() : PERIOD_CURRENT;
      ENUM_TIMEFRAMES    st  = (m_strategy != NULL) ? m_strategy.GetSlowTimeframe() : PERIOD_CURRENT;
      ENUM_APPLIED_PRICE fpr = (m_strategy != NULL) ? m_strategy.GetFastApplied()   : PRICE_CLOSE;
      ENUM_APPLIED_PRICE spr = (m_strategy != NULL) ? m_strategy.GetSlowApplied()   : PRICE_CLOSE;
      int             fp  = (m_strategy != NULL) ? m_strategy.GetFastPeriod()    : inp_FastPeriod;
      int             sp  = (m_strategy != NULL) ? m_strategy.GetSlowPeriod()    : inp_SlowPeriod;
      ENUM_ENTRY_MODE en  = (m_strategy != NULL) ? m_strategy.GetEntryMode()     : inp_EntryMode;
      ENUM_EXIT_MODE  ex  = (m_strategy != NULL) ? m_strategy.GetExitMode()      : inp_ExitMode;

      m_cur_fastMethod = fm; m_cur_slowMethod = sm;
      m_cur_fastTF     = ft; m_cur_slowTF     = st;
      m_cur_fastPrice  = fpr; m_cur_slowPrice = spr;
      m_cur_entry      = en; m_cur_exit       = ex;

      m_iPriority.Text(IntegerToString(pr));
      m_iFastP.Text(IntegerToString(fp));
      m_iSlowP.Text(IntegerToString(sp));
      SetRadioSel(m_bFastM, 4, MAMethodToIndex(fm));
      SetRadioSel(m_bSlowM, 4, MAMethodToIndex(sm));
      m_bFastTF.Text(TFName(ft));       m_bFastTF.ColorBackground(C'50,80,140');   m_bFastTF.Color(clrWhite);
      m_bSlowTF.Text(TFName(st));       m_bSlowTF.ColorBackground(C'50,80,140');   m_bSlowTF.Color(clrWhite);
      m_bFastPr.Text(AppliedPriceShortText(fpr)); m_bFastPr.ColorBackground(C'50,80,140'); m_bFastPr.Color(clrWhite);
      m_bSlowPr.Text(AppliedPriceShortText(spr)); m_bSlowPr.ColorBackground(C'50,80,140'); m_bSlowPr.Color(clrWhite);
      SetRadioSel(m_bEntry, 2, (en == ENTRY_NEXT_CANDLE) ? 0 : 1);
      SetRadioSel(m_bExit,  3, (ex == EXIT_FCO) ? 0 : (ex == EXIT_VM) ? 1 : 2);
     }

public:
   bool Apply(void)
     {
      if(m_strategy == NULL) return false;
      int errors = 0;
      int fastP = (int)StringToInteger(m_iFastP.Text());
      int slowP = (int)StringToInteger(m_iSlowP.Text());
      int prio  = (int)StringToInteger(m_iPriority.Text());

      if(fastP > 0 && fastP <= 1000 && slowP > 0 && slowP <= 1000 && fastP < slowP)
        {
         if(!m_strategy.SetMAParams(fastP, slowP,
                                    m_cur_fastMethod, m_cur_slowMethod,
                                    m_cur_fastTF, m_cur_slowTF,
                                    m_cur_fastPrice, m_cur_slowPrice))
            errors++;
        }
      else
         errors++;

      if(prio <= 0) errors++;

      if(errors > 0)
        {
         m_lblStatus.Text("Valores invalidos");
         m_lblStatus.Color(CLR_NEGATIVE);
         m_statusExpiry = GetTickCount() + 10000;
         ChartRedraw();
         return false;
        }

      // Auto-ajuste de prioridade
      if(m_parent != NULL)
        {
         int resolved = m_parent.ResolveStrategyPriority(prio, "MA Cross Strategy");
         if(resolved != prio)
           {
            prio = resolved;
            m_iPriority.Text(IntegerToString(prio));
           }
        }

      m_strategy.SetPriority(prio);
      m_strategy.SetEntryMode(m_cur_entry);
      m_strategy.SetExitMode(m_cur_exit);
      m_strategy.SetEnabled(m_pendingEnabled);
      return true;
     }

   void SetEnabled(bool enable)
     {
      m_iFastP.ReadOnly(!enable);
      m_iSlowP.ReadOnly(!enable);
      m_iPriority.ReadOnly(!enable);
      color bg = enable ? C'25,25,25' : C'50,50,50';
      m_iFastP.ColorBackground(bg);
      m_iSlowP.ColorBackground(bg);
      m_iPriority.ColorBackground(bg);
      SetRadioGroupEnabled(m_lFastM, m_bFastM, 4, enable);
      SetButtonEnabled(m_lFastTF, m_bFastTF, enable);
      SetButtonEnabled(m_lFastPr, m_bFastPr, enable);
      SetRadioGroupEnabled(m_lSlowM, m_bSlowM, 4, enable);
      SetButtonEnabled(m_lSlowTF, m_bSlowTF, enable);
      SetButtonEnabled(m_lSlowPr, m_bSlowPr, enable);
      SetRadioGroupEnabled(m_lEntry, m_bEntry, 2, enable);
      SetRadioGroupEnabled(m_lExit, m_bExit, 3, enable);
      if(enable)
        {
         SetRadioSel(m_bFastM, 4, MAMethodToIndex(m_cur_fastMethod));
         m_bFastTF.ColorBackground(C'50,80,140'); m_bFastTF.Color(clrWhite);
         m_bFastPr.ColorBackground(C'50,80,140'); m_bFastPr.Color(clrWhite);
         SetRadioSel(m_bSlowM, 4, MAMethodToIndex(m_cur_slowMethod));
         m_bSlowTF.ColorBackground(C'50,80,140'); m_bSlowTF.Color(clrWhite);
         m_bSlowPr.ColorBackground(C'50,80,140'); m_bSlowPr.Color(clrWhite);
         SetRadioSel(m_bEntry, 2, (int)m_cur_entry);
         SetRadioSel(m_bExit, 3, (int)m_cur_exit);
        }
     }
  };
//+------------------------------------------------------------------+
