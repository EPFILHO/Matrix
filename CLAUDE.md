# EPBot Matrix — Notas de Sessão

## Parte 028 — Concluída (2026-03-29)

### O que foi feito
- SIGNAL MANAGER na aba STATUS exibe apenas ativos (não total)
- CONFIG → OUTROS: botões Conflito Sinais e Debug Logs travados com EA rodando
- `ApplyConfig()` retorna `bool`; `ValidateAndApplyAll()` verifica o retorno
- Double-save eliminado (SaveCurrentConfig() removido de dentro de ApplyConfig)
- Guards `m_eaStarted` em `OnClickConflict()` e `OnClickDebug()`
- Log de Trade Comment adicionado (só se mudar)
- Slippage: só loga se mudar
- Debug Logs / Debug Cooldown: nunca logam

---

## Parte 029 — Em andamento (2026-03-30)

### O que foi feito

#### CONFIG → RISCO
- [x] Guard `m_eaStarted` em OnClickSLType, OnClickTPType, OnClickPartialTP, OnClickCompSL, OnClickCompTP
- [x] `SetAllControlsEnabled`: radio groups SL/TP + toggles PTP/CSL/CTP
- [x] Restauração de cores ao habilitar (SetRadioSelection + RefreshRiscoState)

#### CONFIG → RISCO 2
- [x] Guard `m_eaStarted` em OnClickTrailToggle, OnClickBEToggle, OnClickDailyLimitsToggle, OnClickDLProfitTargetAction, OnClickCompTrail, OnClickDDToggle, OnClickDDType, OnClickDDPeakMode
- [x] `SetAllControlsEnabled`: toggles TrlAct/BEAct/DLAct/DDAct/CTrl + radios DLPTA/DDT/DDPk
- [x] Restauração via RefreshDailyLimitsState + RefreshRisco2State

#### CONFIG → BLOQUEIOS
- [x] Guard `m_eaStarted` em OnClickDirection, OnClickLossStreakToggle, OnClickWinStreakToggle, OnClickTFToggle, OnClickTFClose, OnClickCBSToggle, OnClickLossStreakAction, OnClickWinStreakAction
- [x] `SetAllControlsEnabled`: radio Dir + toggles LStr/WStr/TF/TFCl/CBS + edits de streak/TF/CBS
- [x] Restauração via RefreshStreakState + RefreshBloqTimeFilter + RefreshBloqSessionEnd

#### CONFIG → BLOQ2 (News)
- [x] Guard `m_eaStarted` em OnClickNewsOn1/2/3
- [x] `SetAllControlsEnabled`: toggles N1/N2/N3 + edits H/M de cada janela
- [x] Restauração via RefreshNewsState(1/2/3)

#### ESTRAT. / FILTROS
- [x] Guard `m_eaStarted` no dispatch de OnClick dos sub-painéis (Panel.mqh)
- [x] SetEnabled() expandido em todos os 6 sub-painéis para cobrir CButtons:
  - MACrossPanel: 4+4 radio method, 2 TF, 2 Price, 2 Entry, 3 Exit
  - RSIStrategyPanel: TF, 3 Mode
  - BollingerBandsPanel: TF, 3 Mode, 2 Entry, 3 Exit
  - TrendFilterPanel: 4 Method, TF, Price
  - RSIFilterPanel: TF, 3 Mode
  - BollingerBandsFilterPanel: TF, 3 Mode

### TODO restante
- [ ] Validações dos campos (RISCO, RISCO2, BLOQUEIOS, BLOQ2)
- [ ] Commit + push + PR

### Geral
- [x] PR da Parte 028 → main (PR #9 mergeado)
