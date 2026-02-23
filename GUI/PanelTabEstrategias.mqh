//+------------------------------------------------------------------+
//|                                         PanelTabEstrategias.mqh  |
//|                                         Copyright 2026, EP Filho |
//|          Panel Tab: ESTRATEGIAS — Create + Update                 |
//|                     Versão 1.11 - Claude Parte 022 (Claude Code) |
//+------------------------------------------------------------------+
// Implementações de CEPBotPanel para a aba ESTRATEGIAS.
// Incluído por Panel.mqh — NÃO incluir diretamente.

//+------------------------------------------------------------------+
//| ABA 2: ESTRATEGIAS — Criar controles                              |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabEstrategias(void)
  {
   int y = CONTENT_TOP;

   if(!CreateHdr(m_e_hdr1, "e_h1", "SIGNAL MANAGER", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_e_lStratCnt, m_e_eStratCnt, "e_lSC", "e_eSC", "Estrategias:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lFiltCnt, m_e_eFiltCnt, "e_lFC", "e_eFC", "Filtros:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lConflict, m_e_eConflict, "e_lCf", "e_eCf", "Modo Conflito:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_e_hdr2, "e_h2", "MA CROSS STRATEGY", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_e_lMAStatus, m_e_eMAStatus, "e_lMS", "e_eMS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMAFast, m_e_eMAFast, "e_lMF", "e_eMF", "MA Rapida:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMASlow, m_e_eMASlow, "e_lML", "e_eML", "MA Lenta:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMACross, m_e_eMACross, "e_lMC", "e_eMC", "Ultimo Cruz.:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMACandles, m_e_eMACandles, "e_lMN", "e_eMN", "Candles Apos:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMAEntry, m_e_eMAEntry, "e_lME", "e_eME", "Entrada:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMAExit, m_e_eMAExit, "e_lMX", "e_eMX", "Saida:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_e_hdr3, "e_h3", "RSI STRATEGY", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_e_lRSIStatus, m_e_eRSIStatus, "e_lRS", "e_eRS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRSICurr, m_e_eRSICurr, "e_lRC", "e_eRC", "RSI Atual:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRSIMode, m_e_eRSIMode, "e_lRM", "e_eRM", "Modo:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRSILevels, m_e_eRSILevels, "e_lRL", "e_eRL", "Niveis:", y)) return false;

   return true;
  }

//+------------------------------------------------------------------+
//| UpdateEstrategias — atualiza dados da aba ESTRATEGIAS             |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateEstrategias(void)
  {
// ── Signal Manager ──
   if(m_signalManager != NULL)
     {
      SetEV(m_e_eStratCnt, IntegerToString(m_signalManager.GetStrategyCount()), CLR_VALUE);
      SetEV(m_e_eFiltCnt, IntegerToString(m_signalManager.GetFilterCount()), CLR_VALUE);
      string cm = (m_signalManager.GetConflictMode() == CONFLICT_PRIORITY) ? "Prioridade" : "Cancelar";
      SetEV(m_e_eConflict, cm, CLR_VALUE);
     }

// ── MA Cross ──
   if(m_maCross != NULL && m_maCross.IsInitialized())
     {
      SetEV(m_e_eMAStatus, "Ativo (P:" + IntegerToString(m_maCross.GetPriority()) + ")", CLR_POSITIVE);
      SetEV(m_e_eMAFast, DoubleToString(m_maCross.GetMAFast(), _Digits), CLR_VALUE);
      SetEV(m_e_eMASlow, DoubleToString(m_maCross.GetMASlow(), _Digits), CLR_VALUE);

      ENUM_SIGNAL_TYPE lastCross = m_maCross.GetLastCross();
      string crossTxt = (lastCross == SIGNAL_BUY) ? "BUY" : (lastCross == SIGNAL_SELL) ? "SELL" : "Nenhum";
      color crossClr = (lastCross == SIGNAL_BUY) ? CLR_POSITIVE : (lastCross == SIGNAL_SELL) ? CLR_NEGATIVE : CLR_NEUTRAL;
      SetEV(m_e_eMACross, crossTxt, crossClr);
      SetEV(m_e_eMACandles, IntegerToString(m_maCross.GetCandlesAfterCross()), CLR_VALUE);

      string entryTxt = (m_maCross.GetEntryMode() == ENTRY_NEXT_CANDLE) ? "Next Candle" : "2nd Candle";
      SetEV(m_e_eMAEntry, entryTxt, CLR_VALUE);

      ENUM_EXIT_MODE em = m_maCross.GetExitMode();
      string exitTxt = (em == EXIT_FCO) ? "FCO" : (em == EXIT_VM) ? "VM" : "TP/SL";
      SetEV(m_e_eMAExit, exitTxt, CLR_VALUE);
     }
   else
     {
      SetEV(m_e_eMAStatus, "Inativo", CLR_NEUTRAL);
      SetEV(m_e_eMAFast, "--", CLR_NEUTRAL);
      SetEV(m_e_eMASlow, "--", CLR_NEUTRAL);
      SetEV(m_e_eMACross, "--", CLR_NEUTRAL);
      SetEV(m_e_eMACandles, "--", CLR_NEUTRAL);
      SetEV(m_e_eMAEntry, "--", CLR_NEUTRAL);
      SetEV(m_e_eMAExit, "--", CLR_NEUTRAL);
     }

// ── RSI Strategy ──
   if(m_rsiStrategy != NULL && m_rsiStrategy.IsInitialized())
     {
      SetEV(m_e_eRSIStatus, "Ativo (P:" + IntegerToString(m_rsiStrategy.GetPriority()) + ")", CLR_POSITIVE);
      SetEV(m_e_eRSICurr, DoubleToString(m_rsiStrategy.GetCurrentRSI(), 1), CLR_VALUE);
      SetEV(m_e_eRSIMode, m_rsiStrategy.GetSignalModeText(), CLR_VALUE);
      SetEV(m_e_eRSILevels, DoubleToString(m_rsiStrategy.GetOversold(), 0) + " / " +
            DoubleToString(m_rsiStrategy.GetOverbought(), 0), CLR_VALUE);
     }
   else
     {
      SetEV(m_e_eRSIStatus, "Inativo", CLR_NEUTRAL);
      SetEV(m_e_eRSICurr, "--", CLR_NEUTRAL);
      SetEV(m_e_eRSIMode, "--", CLR_NEUTRAL);
      SetEV(m_e_eRSILevels, "--", CLR_NEUTRAL);
     }
  }
//+------------------------------------------------------------------+
