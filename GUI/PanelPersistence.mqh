//+------------------------------------------------------------------+
//|                                           PanelPersistence.mqh   |
//|                                         Copyright 2026, EP Filho |
//|   Panel: Persistência de Config — Save/Load/Banner                |
//|                     Versão 1.08 - Claude Parte 035 (Claude Code) |
//+------------------------------------------------------------------+
// Implementações de CEPBotPanel para persistência de configurações.
// Incluído por Panel.mqh — NÃO incluir diretamente.
//
// Changelog: ver CHANGELOG.md

//+------------------------------------------------------------------+
//| SaveCurrentConfig — coleta e salva configuração atual              |
//+------------------------------------------------------------------+
void CEPBotPanel::SaveCurrentConfig(void)
  {
   if(MQLInfoInteger(MQL_TESTER)) return;

   SConfigData data;
   ZeroMemory(data);
   CollectConfigData(data);
   m_savedConfig = data;   // Snapshot para CANCELAR
   CConfigPersistence::Save(m_symbol, m_initMagicNumber, data);
  }

//+------------------------------------------------------------------+
//| HasSavedConfig — verifica se existe config salva para load        |
//+------------------------------------------------------------------+
bool CEPBotPanel::HasSavedConfig(void)
  {
   return CConfigPersistence::Exists(m_symbol, m_initMagicNumber);
  }

//+------------------------------------------------------------------+
//| CollectConfigData — preenche struct a partir do estado atual       |
//| Usa m_cur_* (GUI state) + CEdit fields + getters dos módulos      |
//+------------------------------------------------------------------+
void CEPBotPanel::CollectConfigData(SConfigData &data)
  {
   data.version = 1;
   data.lastModified = TimeLocal();  // Hora local do trader (não hora do broker)

// ═══════════════════════════════════════════════
// CONFIG TAB: lê do GUI state (m_cur_*) e CEdit fields
// ═══════════════════════════════════════════════

// ── RISCO ──
   data.lotSize           = StringToDouble(m_cr_iLot.Text());
   data.slType            = m_cur_slType;
   data.slCompensateSpread = m_cur_compSL;
   data.tpType            = m_cur_tpType;
   data.tpCompensateSpread = m_cur_compTP;
   data.atrPeriod         = (int)StringToInteger(m_cr_iATRp.Text());
   data.rangePeriod       = (int)StringToInteger(m_cr_iRngP.Text());

// ── Trailing / Breakeven (toggles) ──
   data.trailOn               = m_cur_trailOn;
   data.trailCompensateSpread = m_cur_compTrail;
   // Parte 035 — enum composto: toggle OFF → NEVER, toggle ON → radio mode
   data.trailingActivation    = m_cur_trailOn ? m_cur_trailMode : TRAILING_NEVER;
   data.beOn              = m_cur_beOn;

// ═══════════════════════════════════════════════
// Parte 034 — persiste TODOS os valores por tipo
// Lê do módulo (estado corrente) e sobrescreve o tipo ATIVO com o CEdit
// (captura a última edição do usuário antes do Save)
// ═══════════════════════════════════════════════
   if(m_riskManager != NULL)
     {
      // SL — 3 tipos
      data.fixedSL          = m_riskManager.GetFixedSL();
      data.slATRMultiplier  = m_riskManager.GetSLATRMultiplier();
      data.rangeMultiplier  = m_riskManager.GetRangeMultiplier();
      // TP — 2 tipos
      data.fixedTP          = m_riskManager.GetFixedTP();
      data.tpATRMultiplier  = m_riskManager.GetTPATRMultiplier();
      // Trailing — 2 tipos
      data.trailStartFixed  = m_riskManager.GetTrailingStart();
      data.trailStepFixed   = m_riskManager.GetTrailingStep();
      data.trailStartATR    = m_riskManager.GetTrailingATRStart();
      data.trailStepATR     = m_riskManager.GetTrailingATRStep();
      // Breakeven — 2 tipos
      data.beActivationFixed = m_riskManager.GetBEActivation();
      data.beOffsetFixed     = m_riskManager.GetBEOffset();
      data.beActivationATR   = m_riskManager.GetBEATRActivation();
      data.beOffsetATR       = m_riskManager.GetBEATROffset();
     }

   // Override: tipo ATIVO vem do CEdit (captura edição mais recente)
   if(m_cur_slType == SL_FIXED)
      data.fixedSL         = (int)StringToInteger(m_cr_iSL.Text());
   else if(m_cur_slType == SL_ATR)
      data.slATRMultiplier = StringToDouble(m_cr_iSL.Text());
   else
      data.rangeMultiplier = StringToDouble(m_cr_iSL.Text());

   if(m_cur_tpType == TP_FIXED)
      data.fixedTP         = (int)StringToInteger(m_cr_iTP.Text());
   else if(m_cur_tpType == TP_ATR)
      data.tpATRMultiplier = StringToDouble(m_cr_iTP.Text());

   if(m_cur_trailOn)
     {
      if(m_cur_trailingType == TRAILING_FIXED)
        {
         data.trailStartFixed = (int)StringToInteger(m_c2_iTrlSt.Text());
         data.trailStepFixed  = (int)StringToInteger(m_c2_iTrlSp.Text());
        }
      else
        {
         data.trailStartATR   = StringToDouble(m_c2_iTrlSt.Text());
         data.trailStepATR    = StringToDouble(m_c2_iTrlSp.Text());
        }
     }

   if(m_cur_beOn)
     {
      if(m_cur_beType == BE_FIXED)
        {
         data.beActivationFixed = (int)StringToInteger(m_c2_iBEVal.Text());
         data.beOffsetFixed     = (int)StringToInteger(m_c2_iBEOff.Text());
        }
      else
        {
         data.beActivationATR   = StringToDouble(m_c2_iBEVal.Text());
         data.beOffsetATR       = StringToDouble(m_c2_iBEOff.Text());
        }
     }

// ── Partial TP ──
   data.partialTP         = m_cur_partialTP;
   data.tp1Percent        = StringToDouble(m_cr_iTP1p.Text());
   data.tp1Distance       = (int)StringToInteger(m_cr_iTP1d.Text());
   data.tp2Percent        = StringToDouble(m_cr_iTP2p.Text());
   data.tp2Distance       = (int)StringToInteger(m_cr_iTP2d.Text());

// ── Daily Limits ──
   data.dailyLimitsOn     = m_cur_dailyLimitsOn;
   data.maxDailyTrades    = (int)StringToInteger(m_c2_iDLTrd.Text());
   data.maxDailyLoss      = StringToDouble(m_c2_iDLLoss.Text());
   data.maxDailyGain      = StringToDouble(m_c2_iDLGain.Text());
   data.profitTargetAction = m_cur_profitTargetAction;

// ── Drawdown ──
   data.ddOn              = m_cur_ddOn;
   data.ddValue           = StringToDouble(m_c2_iDD.Text());
   data.ddType            = m_cur_ddType;
   data.ddPeakMode        = m_cur_ddPeakMode;

// ── Bloqueios ──
   data.maxSpread         = (int)StringToInteger(m_cb_iSpr.Text());
   data.tradeDirection    = m_cur_direction;

// ── Streak ──
   data.lossStreakOn      = m_cur_lossStreakOn;
   data.maxLossStreak     = (int)StringToInteger(m_cb_iLStr.Text());
   data.lossStreakAction  = m_cur_lossStreakAction;
   data.lossPauseMinutes  = (int)StringToInteger(m_cb_iLStrP.Text());
   data.winStreakOn        = m_cur_winStreakOn;
   data.maxWinStreak      = (int)StringToInteger(m_cb_iWStr.Text());
   data.winStreakAction   = m_cur_winStreakAction;
   data.winPauseMinutes   = (int)StringToInteger(m_cb_iWStrP.Text());

// ── Filtro de Horário ──
   data.timeFilterOn      = m_cur_tfOn;
   data.tfStartH          = (int)StringToInteger(m_cb_iTFSH.Text());
   data.tfStartM          = (int)StringToInteger(m_cb_iTFSM.Text());
   data.tfEndH            = (int)StringToInteger(m_cb_iTFEH.Text());
   data.tfEndM            = (int)StringToInteger(m_cb_iTFEM.Text());
   data.tfCloseOnEnd      = m_cur_tfClose;

// ── Proteção Sessão ──
   data.cbsOn             = m_cur_cbsOn;
   data.cbsMinutes        = (int)StringToInteger(m_cb_iCBSMin.Text());

// ── News ──
   data.newsOn1           = m_cur_newsOn1;
   data.news1SH           = (int)StringToInteger(m_cb2_iN1SH.Text());
   data.news1SM           = (int)StringToInteger(m_cb2_iN1SM.Text());
   data.news1EH           = (int)StringToInteger(m_cb2_iN1EH.Text());
   data.news1EM           = (int)StringToInteger(m_cb2_iN1EM.Text());
   data.newsOn2           = m_cur_newsOn2;
   data.news2SH           = (int)StringToInteger(m_cb2_iN2SH.Text());
   data.news2SM           = (int)StringToInteger(m_cb2_iN2SM.Text());
   data.news2EH           = (int)StringToInteger(m_cb2_iN2EH.Text());
   data.news2EM           = (int)StringToInteger(m_cb2_iN2EM.Text());
   data.newsOn3           = m_cur_newsOn3;
   data.news3SH           = (int)StringToInteger(m_cb2_iN3SH.Text());
   data.news3SM           = (int)StringToInteger(m_cb2_iN3SM.Text());
   data.news3EH           = (int)StringToInteger(m_cb2_iN3EH.Text());
   data.news3EM           = (int)StringToInteger(m_cb2_iN3EM.Text());

// ── Outros ──
   data.magicNumber       = m_magicNumber;
   data.slippage          = (int)StringToInteger(m_co_iSlip.Text());
   data.conflictMode      = m_cur_conflict;
   data.showDebug         = m_cur_debug;
   data.debugCooldown     = (int)StringToInteger(m_co_iDbgCd.Text());
   data.trailingType      = m_cur_trailingType;
   data.beType            = m_cur_beType;

// ═══════════════════════════════════════════════
// STRATEGIES: lê dos objetos via getters
// ═══════════════════════════════════════════════

// ── MA Cross ──
   if(m_maCross != NULL)
     {
      data.maEnabled     = m_maCross.GetEnabled();
      data.maPriority    = m_maCross.GetPriority();
      data.maFastPeriod  = m_maCross.GetFastPeriod();
      data.maFastMethod  = m_maCross.GetFastMethod();
      data.maFastApplied = m_maCross.GetFastApplied();
      data.maFastTF      = m_maCross.GetFastTimeframe();
      data.maSlowPeriod  = m_maCross.GetSlowPeriod();
      data.maSlowMethod  = m_maCross.GetSlowMethod();
      data.maSlowApplied = m_maCross.GetSlowApplied();
      data.maSlowTF      = m_maCross.GetSlowTimeframe();
      data.maMinDistance  = m_maCross.GetMinDistance();
      data.maEntryMode   = m_maCross.GetEntryMode();
      data.maExitMode    = m_maCross.GetExitMode();
     }

// ── RSI Strategy ──
   if(m_rsiStrategy != NULL)
     {
      data.rsiEnabled    = m_rsiStrategy.GetEnabled();
      data.rsiPriority   = m_rsiStrategy.GetPriority();
      data.rsiPeriod     = m_rsiStrategy.GetPeriod();
      data.rsiApplied    = m_rsiStrategy.GetAppliedPrice();
      data.rsiTF         = m_rsiStrategy.GetTimeframe();
      data.rsiMode       = m_rsiStrategy.GetSignalMode();
      data.rsiOversold   = m_rsiStrategy.GetOversold();
      data.rsiOverbought = m_rsiStrategy.GetOverbought();
      data.rsiMidLevel   = m_rsiStrategy.GetMiddle();
     }

// ── BB Strategy ──
   if(m_bbStrategy != NULL)
     {
      data.bbEnabled     = m_bbStrategy.GetEnabled();
      data.bbPriority    = m_bbStrategy.GetPriority();
      data.bbPeriod      = m_bbStrategy.GetPeriod();
      data.bbDeviation   = m_bbStrategy.GetDeviation();
      data.bbApplied     = m_bbStrategy.GetAppliedPrice();
      data.bbTF          = m_bbStrategy.GetTimeframe();
      data.bbMode        = m_bbStrategy.GetSignalMode();
      data.bbEntryMode   = m_bbStrategy.GetEntryMode();
      data.bbExitMode    = m_bbStrategy.GetExitMode();
     }

// ═══════════════════════════════════════════════
// FILTERS: lê dos objetos via getters
// ═══════════════════════════════════════════════

// ── Trend Filter ──
   if(m_trendFilter != NULL)
     {
      data.trendEnabled     = m_trendFilter.IsTrendFilterActive();
      data.trendPeriod      = m_trendFilter.GetMAPeriod();
      data.trendMethod      = m_trendFilter.GetMAMethod();
      data.trendApplied     = m_trendFilter.GetMAApplied();
      data.trendTF          = m_trendFilter.GetMATimeframe();
      data.trendMinDistance  = m_trendFilter.GetNeutralDistance();
     }

// ── RSI Filter ──
   if(m_rsiFilter != NULL)
     {
      data.rsiFiltEnabled      = m_rsiFilter.IsEnabled();
      data.rsiFiltPeriod       = m_rsiFilter.GetPeriod();
      data.rsiFiltApplied      = m_rsiFilter.GetAppliedPrice();
      data.rsiFiltTF           = m_rsiFilter.GetTimeframe();
      data.rsiFiltMode         = m_rsiFilter.GetFilterMode();
      data.rsiFiltOversold     = m_rsiFilter.GetOversold();
      data.rsiFiltOverbought   = m_rsiFilter.GetOverbought();
      data.rsiFiltLowerNeutral = m_rsiFilter.GetLowerNeutral();
      data.rsiFiltUpperNeutral = m_rsiFilter.GetUpperNeutral();
      data.rsiFiltShift        = m_rsiFilter.GetShift();
     }

// ── BB Filter ──
   if(m_bbFilter != NULL)
     {
      data.bbFiltEnabled    = m_bbFilter.IsEnabled();
      data.bbFiltPeriod     = m_bbFilter.GetPeriod();
      data.bbFiltDeviation  = m_bbFilter.GetDeviation();
      data.bbFiltApplied    = m_bbFilter.GetAppliedPrice();
      data.bbFiltTF         = m_bbFilter.GetTimeframe();
      data.bbFiltMetric     = m_bbFilter.GetSqueezeMetric();
      data.bbFiltThreshold  = m_bbFilter.GetSqueezeThreshold();
      data.bbFiltPercPeriod = m_bbFilter.GetPercentilePeriod();
     }
  }

//+------------------------------------------------------------------+
//| ApplyLoadedConfig — aplica SConfigData nos módulos e atualiza GUI |
//+------------------------------------------------------------------+
void CEPBotPanel::ApplyLoadedConfig(const SConfigData &data)
  {
// ═══════════════════════════════════════════════
// 1. Atualizar state vars do painel (m_cur_*)
// ═══════════════════════════════════════════════
   m_cur_slType            = data.slType;
   m_cur_tpType            = data.tpType;
   m_cur_compSL            = data.slCompensateSpread;
   m_cur_compTP            = data.tpCompensateSpread;
   m_cur_compTrail         = data.trailCompensateSpread;
   m_cur_trailOn           = data.trailOn;
   // Parte 035 — deriva m_cur_trailMode do enum persistido (NEVER → mantém último radio = ALWAYS)
   m_cur_trailMode         = (data.trailingActivation == TRAILING_NEVER) ? TRAILING_ALWAYS : data.trailingActivation;
   m_cur_beOn              = data.beOn;
   m_cur_partialTP         = data.partialTP;
   m_cur_dailyLimitsOn     = data.dailyLimitsOn;
   m_cur_profitTargetAction = data.profitTargetAction;
   m_cur_ddOn              = data.ddOn;
   m_cur_ddType            = data.ddType;
   m_cur_ddPeakMode        = data.ddPeakMode;
   m_cur_direction         = data.tradeDirection;
   m_cur_lossStreakOn      = data.lossStreakOn;
   m_cur_lossStreakAction  = data.lossStreakAction;
   m_cur_winStreakOn       = data.winStreakOn;
   m_cur_winStreakAction   = data.winStreakAction;
   m_cur_tfOn              = data.timeFilterOn;
   m_cur_tfClose           = data.tfCloseOnEnd;
   m_cur_cbsOn             = data.cbsOn;
   m_cur_newsOn1           = data.newsOn1;
   m_cur_newsOn2           = data.newsOn2;
   m_cur_newsOn3           = data.newsOn3;
   m_cur_conflict          = data.conflictMode;
   m_cur_debug             = data.showDebug;
   m_cur_trailingType      = data.trailingType;
   m_cur_beType            = data.beType;

   // Recalcular feature flags
   m_cfg_hasTP    = (m_cur_tpType != TP_NONE);
   m_cfg_hasATR   = (m_cur_slType == SL_ATR || m_cur_tpType == TP_ATR ||
                     m_cur_trailingType == TRAILING_ATR || m_cur_beType == BE_ATR);
   m_cfg_hasRange = (m_cur_slType == SL_RANGE);

// ═══════════════════════════════════════════════
// 2. Atualizar CEdit fields do CONFIG tab
// ═══════════════════════════════════════════════
   m_cr_iLot.Text(DoubleToString(data.lotSize, 2));

   // SL value — depende do tipo
   if(data.slType == SL_FIXED)
      m_cr_iSL.Text(IntegerToString(data.fixedSL));
   else if(data.slType == SL_ATR)
      m_cr_iSL.Text(DoubleToString(data.slATRMultiplier, 2));
   else
      m_cr_iSL.Text(DoubleToString(data.rangeMultiplier, 2));

   // TP value
   if(data.tpType == TP_FIXED)
      m_cr_iTP.Text(IntegerToString(data.fixedTP));
   else if(data.tpType == TP_ATR)
      m_cr_iTP.Text(DoubleToString(data.tpATRMultiplier, 2));

   m_cr_iATRp.Text(IntegerToString(data.atrPeriod));
   m_cr_iRngP.Text(IntegerToString(data.rangePeriod));

   // Trailing
   if(m_cur_trailingType == TRAILING_FIXED)
     {
      m_c2_iTrlSt.Text(IntegerToString(data.trailStartFixed));
      m_c2_iTrlSp.Text(IntegerToString(data.trailStepFixed));
     }
   else
     {
      m_c2_iTrlSt.Text(DoubleToString(data.trailStartATR, 2));
      m_c2_iTrlSp.Text(DoubleToString(data.trailStepATR, 2));
     }

   // Breakeven
   if(m_cur_beType == BE_FIXED)
     {
      m_c2_iBEVal.Text(IntegerToString(data.beActivationFixed));
      m_c2_iBEOff.Text(IntegerToString(data.beOffsetFixed));
     }
   else
     {
      m_c2_iBEVal.Text(DoubleToString(data.beActivationATR, 2));
      m_c2_iBEOff.Text(DoubleToString(data.beOffsetATR, 2));
     }

   // Partial TP
   m_cr_iTP1p.Text(DoubleToString(data.tp1Percent, 1));
   m_cr_iTP1d.Text(IntegerToString(data.tp1Distance));
   m_cr_iTP2p.Text(DoubleToString(data.tp2Percent, 1));
   m_cr_iTP2d.Text(IntegerToString(data.tp2Distance));

   // Daily Limits
   m_c2_iDLTrd.Text(IntegerToString(data.maxDailyTrades));
   m_c2_iDLLoss.Text(DoubleToString(data.maxDailyLoss, 2));
   m_c2_iDLGain.Text(DoubleToString(data.maxDailyGain, 2));

   // Drawdown
   m_c2_iDD.Text(DoubleToString(data.ddValue, 2));

   // Bloqueios
   m_cb_iSpr.Text(IntegerToString(data.maxSpread));

   // Streak
   m_cb_iLStr.Text(IntegerToString(data.maxLossStreak));
   m_cb_iLStrP.Text(IntegerToString(data.lossPauseMinutes));
   m_cb_iWStr.Text(IntegerToString(data.maxWinStreak));
   m_cb_iWStrP.Text(IntegerToString(data.winPauseMinutes));

   // Time Filter
   m_cb_iTFSH.Text(IntegerToString(data.tfStartH));
   m_cb_iTFSM.Text(IntegerToString(data.tfStartM));
   m_cb_iTFEH.Text(IntegerToString(data.tfEndH));
   m_cb_iTFEM.Text(IntegerToString(data.tfEndM));

   // Session
   m_cb_iCBSMin.Text(IntegerToString(data.cbsMinutes));

   // News
   m_cb2_iN1SH.Text(IntegerToString(data.news1SH));
   m_cb2_iN1SM.Text(IntegerToString(data.news1SM));
   m_cb2_iN1EH.Text(IntegerToString(data.news1EH));
   m_cb2_iN1EM.Text(IntegerToString(data.news1EM));
   m_cb2_iN2SH.Text(IntegerToString(data.news2SH));
   m_cb2_iN2SM.Text(IntegerToString(data.news2SM));
   m_cb2_iN2EH.Text(IntegerToString(data.news2EH));
   m_cb2_iN2EM.Text(IntegerToString(data.news2EM));
   m_cb2_iN3SH.Text(IntegerToString(data.news3SH));
   m_cb2_iN3SM.Text(IntegerToString(data.news3SM));
   m_cb2_iN3EH.Text(IntegerToString(data.news3EH));
   m_cb2_iN3EM.Text(IntegerToString(data.news3EM));

   // Outros
   if(data.magicNumber > 0)
      m_co_iMagic.Text(IntegerToString(data.magicNumber));
   m_co_iSlip.Text(IntegerToString(data.slippage));
   m_co_iDbgCd.Text(IntegerToString(data.debugCooldown));

// ═══════════════════════════════════════════════
// 3. Atualizar radio buttons e toggles visuais
// ═══════════════════════════════════════════════
   SetRadioSelection(m_cr_bSLT, 3, SLTypeToIndex(data.slType));
   SetRadioSelection(m_cr_bTPT, 3, TPTypeToIndex(data.tpType));
   SetRadioSelection(m_cb_bDir, 3, (int)data.tradeDirection);
   SetRadioSelection(m_c2_bDLPTA, 2, (int)data.profitTargetAction);
   SetRadioSelection(m_c2_bDDT, 2, (int)data.ddType);
   SetRadioSelection(m_c2_bDDPk, 2, (int)data.ddPeakMode);
   SetRadioSelection(m_cb_bLStrA, 2, (int)data.lossStreakAction);
   SetRadioSelection(m_cb_bWStrA, 2, (int)data.winStreakAction);

   ApplyToggleStyle(m_c2_bTrlAct, data.trailOn);
   ApplyToggleStyle(m_c2_bBEAct, data.beOn);
   ApplyToggleStyle(m_cr_bPTP, data.partialTP);
   ApplyToggleStyle(m_c2_bDLAct, data.dailyLimitsOn);
   ApplyToggleStyle(m_c2_bDDAct, data.ddOn);
   ApplyToggleStyle(m_cb_bLStrOn, data.lossStreakOn);
   ApplyToggleStyle(m_cb_bWStrOn, data.winStreakOn);
   ApplyToggleStyle(m_cb_bTFOn, data.timeFilterOn);
   ApplyToggleStyle(m_cb_bTFCl, data.tfCloseOnEnd);
   ApplyToggleStyle(m_cb_bCBSOn, data.cbsOn);
   ApplyToggleStyle(m_co_bDbg, data.showDebug);
   ApplyToggleStyle(m_cb2_bN1On, data.newsOn1);
   ApplyToggleStyle(m_cb2_bN2On, data.newsOn2);
   ApplyToggleStyle(m_cb2_bN3On, data.newsOn3);

// ═══════════════════════════════════════════════
// 4. Refresh visual states (enable/disable por toggle)
// ═══════════════════════════════════════════════
   RefreshRiscoState();
   RefreshRisco2State();
   RefreshDailyLimitsState();
   RefreshStreakState();
   RefreshBloqTimeFilter();
   RefreshBloqSessionEnd();
   RefreshNewsState(1);
   RefreshNewsState(2);
   RefreshNewsState(3);

// ═══════════════════════════════════════════════
// Parte 034 — Aplicar valores de TODOS os tipos no módulo
// (ApplyConfig só cobre o tipo ATIVO via CEdit; aqui cobrimos os inativos)
// 0 = não sobrescreve → compat com .cfg antigos (fix 3)
// ═══════════════════════════════════════════════
   if(m_riskManager != NULL)
     {
      // SL (3 tipos)
      if(data.fixedSL > 0)          m_riskManager.SetFixedSL(data.fixedSL);
      if(data.slATRMultiplier > 0)  m_riskManager.SetSLATRMultiplier(data.slATRMultiplier);
      if(data.rangeMultiplier > 0)  m_riskManager.SetRangeMultiplier(data.rangeMultiplier);
      // TP (2 tipos)
      if(data.fixedTP > 0)          m_riskManager.SetFixedTP(data.fixedTP);
      if(data.tpATRMultiplier > 0)  m_riskManager.SetTPATRMultiplier(data.tpATRMultiplier);
      // Trailing (2 tipos) — start E step > 0 juntos, offset pode ser 0
      if(data.trailStartFixed > 0 && data.trailStepFixed > 0)
         m_riskManager.SetTrailingParams(data.trailStartFixed, data.trailStepFixed);
      if(data.trailStartATR > 0 && data.trailStepATR > 0)
         m_riskManager.SetTrailingATRParams(data.trailStartATR, data.trailStepATR);
      // BE (2 tipos) — gate por activation > 0 (offset pode ser 0)
      if(data.beActivationFixed > 0)
         m_riskManager.SetBreakevenParams(data.beActivationFixed, data.beOffsetFixed);
      if(data.beActivationATR > 0)
         m_riskManager.SetBreakevenATRParams(data.beActivationATR, data.beOffsetATR);
     }

// ═══════════════════════════════════════════════
// 5. Aplicar nos MÓDULOS — chama ApplyConfig() que lê os CEdit/m_cur_*
// ═══════════════════════════════════════════════
   string loadErr = "";
   ApplyConfig(loadErr);

// ═══════════════════════════════════════════════
// 6. Aplicar STRATEGIES via setters
// ═══════════════════════════════════════════════
   if(m_maCross != NULL)
     {
      m_maCross.SetEnabled(data.maEnabled);
      m_maCross.SetPriority(data.maPriority);
      m_maCross.SetMAParams(data.maFastPeriod, data.maSlowPeriod,
                            data.maFastMethod, data.maSlowMethod,
                            data.maFastTF, data.maSlowTF,
                            data.maFastApplied, data.maSlowApplied);
      m_maCross.SetMinDistance(data.maMinDistance);
      m_maCross.SetEntryMode(data.maEntryMode);
      m_maCross.SetExitMode(data.maExitMode);
     }

   if(m_rsiStrategy != NULL)
     {
      m_rsiStrategy.SetEnabled(data.rsiEnabled);
      m_rsiStrategy.SetPriority(data.rsiPriority);
      m_rsiStrategy.SetPeriod(data.rsiPeriod);
      m_rsiStrategy.SetAppliedPrice(data.rsiApplied);
      m_rsiStrategy.SetTimeframe(data.rsiTF);
      m_rsiStrategy.SetSignalMode(data.rsiMode);
      m_rsiStrategy.SetOversold(data.rsiOversold);
      m_rsiStrategy.SetOverbought(data.rsiOverbought);
      m_rsiStrategy.SetMiddle(data.rsiMidLevel);
     }

   if(m_bbStrategy != NULL)
     {
      m_bbStrategy.SetEnabled(data.bbEnabled);
      m_bbStrategy.SetPriority(data.bbPriority);
      m_bbStrategy.SetPeriod(data.bbPeriod);
      m_bbStrategy.SetDeviation(data.bbDeviation);
      m_bbStrategy.SetAppliedPrice(data.bbApplied);
      m_bbStrategy.SetTimeframe(data.bbTF);
      m_bbStrategy.SetSignalMode(data.bbMode);
      m_bbStrategy.SetEntryMode(data.bbEntryMode);
      m_bbStrategy.SetExitMode(data.bbExitMode);
     }

// ═══════════════════════════════════════════════
// 7. Aplicar FILTERS via setters
// ═══════════════════════════════════════════════
   if(m_trendFilter != NULL)
     {
      m_trendFilter.SetEnabled(data.trendEnabled);
      m_trendFilter.SetTrendFilterEnabled(data.trendEnabled);
      m_trendFilter.SetMACold(data.trendPeriod, data.trendMethod,
                              data.trendTF, data.trendApplied);
      m_trendFilter.SetNeutralDistance(data.trendMinDistance);
     }

   if(m_rsiFilter != NULL)
     {
      m_rsiFilter.SetEnabled(data.rsiFiltEnabled);
      m_rsiFilter.SetPeriod(data.rsiFiltPeriod);
      m_rsiFilter.SetAppliedPrice(data.rsiFiltApplied);
      m_rsiFilter.SetTimeframe(data.rsiFiltTF);
      m_rsiFilter.SetFilterMode(data.rsiFiltMode);
      m_rsiFilter.SetOversold(data.rsiFiltOversold);
      m_rsiFilter.SetOverbought(data.rsiFiltOverbought);
      m_rsiFilter.SetLowerNeutral(data.rsiFiltLowerNeutral);
      m_rsiFilter.SetUpperNeutral(data.rsiFiltUpperNeutral);
      m_rsiFilter.SetShift(data.rsiFiltShift);
     }

   if(m_bbFilter != NULL)
     {
      m_bbFilter.SetEnabled(data.bbFiltEnabled);
      m_bbFilter.SetPeriod(data.bbFiltPeriod);
      m_bbFilter.SetDeviation(data.bbFiltDeviation);
      m_bbFilter.SetAppliedPrice(data.bbFiltApplied);
      m_bbFilter.SetTimeframe(data.bbFiltTF);
      m_bbFilter.SetSqueezeMetric(data.bbFiltMetric);
      m_bbFilter.SetSqueezeThreshold(data.bbFiltThreshold);
      m_bbFilter.SetPercentilePeriod(data.bbFiltPercPeriod);
     }

// ═══════════════════════════════════════════════
// 8. Atualizar sub-painéis de estratégia e filtro
//    Reload() repopula campos GUI a partir dos módulos já atualizados
//    Update() atualiza labels de display (Status, valores atuais, etc.)
// ═══════════════════════════════════════════════
   for(int i = 0; i < m_stratPanelCount; i++)
      if(m_stratPanels[i] != NULL) { m_stratPanels[i].Reload(); m_stratPanels[i].Update(); }

   for(int i = 0; i < m_filtPanelCount; i++)
      if(m_filtPanels[i] != NULL) { m_filtPanels[i].Reload(); m_filtPanels[i].Update(); }

   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| ShowLoadBanner — mostra banner de confirmação para carregar config |
//+------------------------------------------------------------------+
void CEPBotPanel::ShowLoadBanner(const SConfigData &data)
  {
   m_pendingLoadData = data;
   m_loadBannerVisible = true;

   string timeStr = TimeToString(data.lastModified, TIME_DATE | TIME_MINUTES);
   m_lb_msg.Text("Config salva encontrada (" + timeStr + ")");
   m_lb_msg.Color(C'255,200,60');
   m_lb_bg.Show();
   m_lb_msg.Show();
   m_lb_btnLoad.Show();
   m_lb_btnIgnore.Show();
   m_lb_descLoad.Show();
   m_lb_descIgnore.Show();
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| HideLoadBanner — esconde o banner                                 |
//+------------------------------------------------------------------+
void CEPBotPanel::HideLoadBanner(void)
  {
   m_loadBannerVisible = false;
   m_lb_bg.Hide();
   m_lb_msg.Hide();
   m_lb_btnLoad.Hide();
   m_lb_btnIgnore.Hide();
   m_lb_descLoad.Hide();
   m_lb_descIgnore.Hide();
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| OnClickLoadBanner — usuário clicou CARREGAR                       |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickLoadBanner(void)
  {
   HideLoadBanner();
   ApplyLoadedConfig(m_pendingLoadData);

   m_cfg_status.Text("Config salva carregada!");
   m_cfg_status.Color(CLR_POSITIVE);
   m_cfgStatusExpiry = GetTickCount() + 10000;
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| OnClickIgnoreBanner — usuário clicou IGNORAR                      |
//+------------------------------------------------------------------+
void CEPBotPanel::OnClickIgnoreBanner(void)
  {
   HideLoadBanner();
// Deletar o arquivo para não perguntar novamente
   CConfigPersistence::Delete(m_symbol, m_initMagicNumber);

   m_cfg_status.Text("Config salva ignorada");
   m_cfg_status.Color(CLR_NEUTRAL);
   m_cfgStatusExpiry = GetTickCount() + 10000;
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| FIM DO ARQUIVO PanelPersistence.mqh v1.00                         |
//+------------------------------------------------------------------+
