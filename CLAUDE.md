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

## Parte 029 — Concluída (2026-03-31)

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

#### FIXES — Sub-painéis (Estratégias/Filtros)
- [x] **m_locked flag**: adicionado em FilterPanelBase + StrategyPanelBase
  - Update() verifica `!m_locked` antes de chamar `ApplyToggleStyle()` e `_RefreshFieldState()`
  - Impede que Update() sobrescreva estado visual travado quando EA rodando
  - Fixes: botões ON/OFF não piscam cinza→colorido, campos não ficam habilitados
- [x] **TFName() + CycleTF()**: agora cobrem todos os 21 timeframes do MQL5
  - Antes: apenas 10 timeframes (M1, M5, M15, M30, H1, H4, D1, W1, MN1)
  - Depois: +11 faltantes (M2, M3, M4, M6, M10, M12, M20, H2, H3, H6, H8, H12)
  - Fixa: "??" em TimeFrame buttons para gráficos em M2, etc.

#### FIXES — DD Toggle (RISCO 2)
- [x] **DD ficava cinza ao destravar EA**
  - Root cause: `SetAllControlsEnabled(true)` restaurava Trailing/BE/DailyLimits mas esquecia DD
  - Fix: adicionada restauração de cor do DD toggle (ON/OFF/REQUER META)
- [x] **Lógica DD centralizada em RefreshRisco2State()**
  - Removida duplicação: `OnClickDDToggle` + `RefreshDailyLimitsState` + `RefreshRisco2State`
  - Agora único ponto de verdade para cor do DD toggle em todos os 3 estados

### Versões atualizadas
- FilterPanelBase.mqh: 1.02 → 1.03
- StrategyPanelBase.mqh: 1.02 → 1.03
- PanelUtils.mqh: 1.01 → 1.02
- Panel.mqh: 1.59 → 1.60
- PanelTabConfig.mqh: 1.34 → 1.35
- TrendFilterPanel.mqh: 1.05 → 1.06
- RSIFilterPanel.mqh: 1.06 → 1.07
- BollingerBandsFilterPanel.mqh: 1.06 → 1.07
- RSIStrategyPanel.mqh: 1.06 → 1.07
- BollingerBandsPanel.mqh: 1.06 → 1.07
- MACrossPanel.mqh: 1.06 → 1.07

### TODO restante (Parte 030)
- [ ] Validações dos campos (RISCO, RISCO2, BLOQUEIOS, BLOQ2)
- [ ] Criar PR da Parte 029 → main

### Geral
- [x] PR da Parte 028 → main (PR #9 mergeado)
- [x] Parte 029: GUI locks + sub-panel fixes + DD logic centralized
