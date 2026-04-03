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

---

## Parte 030 — Concluída (2026-04-02)

### O que foi feito

#### INFRAESTRUTURA (PanelUtils.mqh)
- [x] `CLR_FIELD_ERROR`: constante rosa claro para highlight de campos inválidos
- [x] `MarkFieldError()` / `ClearFieldError()`: feedback visual em CEdit
- [x] `CalcMaxPoints()`: limite dinâmico baseado no preço do ativo (%)
- [x] `CalcMinSLTP()`: obtém SYMBOL_TRADE_STOPS_LEVEL do broker
- [x] `CalcSymbolLotLimits()`: obtém min/max/step de lote do ativo

#### CONFIG → RISCO + RISCO2
- [x] **Limites dinâmicos** baseados no ativo:
  - Lote: `SYMBOL_VOLUME_MIN/MAX`
  - SL fixo: `>= STOPS_LEVEL && <= 25% preço`
  - TP fixo: `>= STOPS_LEVEL && <= 50% preço`
  - SL/TP ATR mult: `> 0 && <= 100.0`
  - Trail Start/Step: validados individualmente com limites
  - BE Offset < BE Activation (validação cruzada!)
  - TP2 Dist > TP1 Dist (validação cruzada!)
  - ATR/Range Period: `>= 1 && <= 999`
- [x] **Highlight rosa** em cada campo inválido (MarkFieldError)
- [x] **Feedback por campo**: `"Invalido: Lote, SL, TP1%"` no header (não mais genérico)
- [x] **Persistência de cor** quando troca de aba (SetEditEnabled preserva CLR_FIELD_ERROR)

#### CONFIG → BLOQUEIOS + BLOQ2 + OUTROS
- [x] **Spread**: teto `1% preço`, mantém `0=sem limite`
- [x] **Daily Limits**: MaxTrades `<= 9999`, highlight individual
- [x] **Streak**: max `999`, Pausa max `1440min` (24h)
- [x] **DD%**: teto `100%` (percentual)
- [x] **TimeFilter**: highlight individual por campo H/M
- [x] **News Filter**: highlight dos 4 campos da janela inválida
- [x] **CBS**: max `1440min`
- [x] **Slippage/Magic/DbgCooldown**: highlight + nome no feedback
- [x] **DbgCooldown**: teto `3600s` (1h)

#### ESTRATÉGIAS / FILTROS (6 sub-painéis)
- [x] **Assinatura Apply()** mudou para `Apply(string &outErr)` para retornar erros
- [x] **MACrossPanel**: highlight Fast/Slow/Priority + nomes específicos
- [x] **RSIStrategyPanel**: highlight Period/OS/OB/Middle/Priority
- [x] **BollingerBandsPanel**: highlight Period/Dev/Priority
- [x] **TrendFilterPanel**: highlight Period/NeutDist
- [x] **RSIFilterPanel**: highlight Period/OS/OB
- [x] **BollingerBandsFilterPanel**: highlight Period/Dev/Threshold/PercPeriod
- [x] **Validação cruzada** em cada sub-painel (ex: OB > OS, dist order)

#### UNIFICAÇÃO DE FEEDBACK
- [x] **ValidateAndApplyAll()**: acumula erros de CONFIG + ESTRAT + FILTROS
- [x] **Uma única mensagem no header**: `"Invalido: Lote, MA Fast>=Slow, RFilt Per"`
- [x] **Sem dois rounds**: agora roda tudo de uma vez antes de informar erros
- [x] **SetEditEnabled() em sub-painéis**: preserva CLR_FIELD_ERROR entre abas

### Versões atualizadas
- PanelUtils.mqh: 1.02 → 1.03
- PanelTabConfig.mqh: 1.35 → 1.36
- Panel.mqh: 1.60 → 1.61
- PanelPersistence.mqh: 1.02 → 1.03
- StrategyPanelBase.mqh: 1.03 → 1.04
- FilterPanelBase.mqh: 1.03 → 1.04
- MACrossPanel.mqh: 1.07 → 1.08
- RSIStrategyPanel.mqh: 1.07 → 1.08
- BollingerBandsPanel.mqh: 1.07 → 1.08
- TrendFilterPanel.mqh: 1.06 → 1.07
- RSIFilterPanel.mqh: 1.07 → 1.08
- BollingerBandsFilterPanel.mqh: 1.07 → 1.08

#### FIXES ADICIONAIS (Sessão 030 continuação)
- [x] **Partial TP + TP=NONE + Trailing OFF**: pré-validação agora bloqueia corretamente
  - `ValidateAndApplyAll()` captura `return false` de `ApplyConfig()` 
  - Impede que "Config salva com sucesso!" sobrescreva mensagem de erro
- [x] **Max Gain fica rosa** na validação cruzada DD (DD ON + ProfitTargetAction=ATIVAR DD + Max Gain <= 0)
  - Adicionado `MarkFieldError(m_c2_iDLGain)` no bloco de validação cruzada
- [x] **MaxLoss/MaxGain aceitam 0** = "sem limite" (permitindo usar só MaxTrades, ou só MaxLoss, ou só MaxGain)
  - Validação volta a `>= 0` para ambos; MaxTrades mantém `>= 0`
- [x] **Aviso "Daily Limits ON mas sem valores"** removido
  - Zero é escolha válida do trader; não precisa de warning

### Versões atualizadas (continuação)
- Panel.mqh: 1.61 → (sem novo número, só changelog adicionado)
- PanelTabConfig.mqh: 1.36 → (sem novo número, só fixes e changelog)

### Geral
- [x] Parte 030: Validações de campos (CONFIG + ESTRAT + FILTROS)
- [x] PR da Parte 029 → main (PR #11 mergeado)
- [x] Validações cruzadas TP/SL + Partial TP implementadas e testadas
- [x] Feedback visual (pink highlight) consistente em todas as abas

### TODO restante (Parte 031)
- [ ] Expandir padrão "só loga se mudar" para mais campos:
  - **Em Parte 028**: Trade Comment, Slippage já implementados
  - **Faltam**: Magic Number (TradeManager.SetMagicNumber), Conflict Resolution, e demais campos que sofrem hot reload
  - Padrão estabelecido em TradeManager::SetSlippage() pode ser replicado
- [ ] Criar PR da Parte 030 → main

---

## Parte 031 — Concluída (2026-04-03)

### O que foi feito

#### HOT RELOAD — Expandir "só loga se mudar"

**RiskManager** (6 métodos):
- SetUsePartialTP: compara `oldValue != enable`
- SetATRPeriod: compara `oldValue != period`, mostra transição `old → new`
- SetRangePeriod: idem
- SetSLCompensateSpread: compara `oldValue != enable`
- SetTPCompensateSpread: idem
- SetTrailingCompensateSpread: idem

**BlockerFilters** (2 métodos):
- SetTimeFilter: compara todos 5 campos (enable + 4 horários)
- SetNewsFilter: compara campos da janela específica (1/2/3)

**Estratégias** (3 arquivos, 15 métodos):
- **MACrossStrategy**: SetEntryMode, SetExitMode (HOT); SetMAPeriods, SetMAMethods, SetMATimeframes, SetMAParams (COLD)
- **RSIStrategy**: SetSignalMode, SetOversold, SetOverbought, SetMiddle, SetEnabled (HOT); SetPeriod, SetTimeframe, SetAppliedPrice (COLD)
- **BollingerBandsStrategy**: SetSignalMode, SetEntryMode, SetExitMode, SetEnabled (HOT); SetPeriod, SetDeviation, SetTimeframe, SetAppliedPrice (COLD)

**Filtros** (3 arquivos, 23 métodos):
- **TrendFilter**: SetTrendFilterEnabled, SetNeutralDistance (HOT); SetMAPeriod, SetMAMethod, SetMATimeframe, SetMAApplied, SetMACold (COLD)
- **RSIFilter**: SetFilterMode, SetOversold, SetOverbought, SetLowerNeutral, SetUpperNeutral, SetShift (HOT); SetPeriod, SetTimeframe, SetAppliedPrice (COLD)
- **BollingerBandsFilter**: SetSqueezeMetric, SetSqueezeThreshold, SetPercentilePeriod (HOT); SetPeriod, SetDeviation, SetTimeframe, SetAppliedPrice (COLD)

#### COLD RELOAD — Skip Deinitialize+Initialize
Todos os métodos COLD agora:
1. Comparam valor antigo vs novo
2. Se iguais, retornam `true` imediatamente (sem Deinitialize)
3. Se diferentes, fazem Deinitialize+Initialize normal
4. Só logam se Initialize foi bem-sucedido E valor mudou

**Benefício**: Ganho de performance — não reinicializa indicadores se parâmetros são idênticos

#### FIX — Memory leak no OnDeinit
- **Bug**: g_bbStrategy e g_bbFilter não eram deletados na ETAPA 2 do OnDeinit
- **Causa**: CleanupAll() tem os 6 módulos, mas só é chamado em INIT_FAILED. OnDeinit normal não passava por CleanupAll()
- **Fix**: Adicionado delete explícito de g_bbFilter e g_bbStrategy na ETAPA 2
- **Impacto**: Toda remoção do EA vazava ~2 objetos

#### FIX — SetEnabled sem log em 4 módulos
- **Bug**: Toggle ON/OFF nos sub-painéis não logava em MACross, TrendFilter, RSIFilter, BBFilter
- **Causa**: SetEnabled herdava da classe base (setter mudo sem log)
- **Fix**: Override com log "ATIVADO/DESATIVADO" nos 4 módulos
- **FilterBase**: SetEnabled tornado `virtual` para permitir override
- RSIStrategy e BollingerBandsStrategy já tinham override — não precisaram de fix

#### Removidos fallbacks `else Print(...)`
Em todos os métodos corrigidos, removemos os fallbacks `else Print(msg)` para manter consistência com padrão: sempre usar `m_logger` (que nunca é NULL em operação).

### Versões atualizadas
- EPBot_Matrix.mq5: 1.56 → 1.57
- MACrossStrategy.mqh: 2.26 → 2.27
- RSIStrategy.mqh: 2.15 → 2.16
- BollingerBandsStrategy.mqh: 1.00 → 1.01
- TrendFilter.mqh: 2.23 → 2.24
- RSIFilter.mqh: 1.11 → 1.12
- BollingerBandsFilter.mqh: 1.00 → 1.01
- FilterBase.mqh: 2.01 → 2.02

### TODO restante (Parte 032)
- [ ] Criar PR da Parte 031 → main


- [ ] Criar PR da Parte 031 → main

---

## Parte 032 — Concluída (2026-04-03)

### O que foi feito

#### ANÁLISE DE QUALIDADE — EPBot Matrix v1.58

Revisão completa do codebase (`Core/`) em resposta a pergunta do usuário: _"meu EA está bom?"_

Arquivos analisados:
- `EPBot_Matrix.mq5`
- `Core/TradeManager.mqh`
- `Core/BlockerFilters.mqh`
- `Core/Blockers.mqh`

#### FIX 1 — Win/Loss inconsistency (`EPBot_Matrix.mq5`)

- **Bug**: `g_logger.UpdateStats(finalDealProfit)` usava o lucro do deal final (sem parciais), enquanto o Streak usava `totalPositionProfit`
- **Fix**: `g_logger.UpdateStats(totalPositionProfit)` — consistência total entre Logger e Streak
- **Impacto**: Em trades com TP1+TP2, o Logger contava como perda mesmo quando a posição era lucrativa
- Comentário `KNOWN LIMITATION` convertido em `✅ CORRIGIDO v1.59`

#### FIX 2 — `FetchDealRealValues()` centralizado (`TradeManager.mqh`)

- **Bug**: Bloco de ~60 linhas duplicado nos blocos TP1 e TP2 de `MonitorPartialTP()`
- **Fix**: Extraído como método privado `FetchDealRealValues()` — elimina duplicação, facilita manutenção
- Logs de diagnóstico (preço real, volume, lucro) mantidos no método centralizado

#### FIX 3 — `HistorySelect` 60s → 300s (`TradeManager.mqh`)

- **Bug**: Janela de 60s em `FetchDealRealValues()` insuficiente para brokers com alta latência
- **Fix**: Janela expandida para 300s (5 minutos) em ambas as ocorrências (TP1 e TP2)

#### FIX 4 — `GetTypeFilling()` centralizado em `Core/Utils.mqh`

- **Bug**: Função duplicada em `EPBot_Matrix.mq5` (global) e `TradeManager.mqh` (método privado)
- **Fix**: Criado `Core/Utils.mqh` com `GetTypeFilling(const string symbol)` usando operadores bitwise corretos
  - Lógica corrigida: `(filling & SYMBOL_FILLING_FOK) != 0` em vez de `== SYMBOL_FILLING_FOK`
- `EPBot_Matrix.mq5`: removida função global, adicionado `#include "Core/Utils.mqh"`
- `TradeManager.mqh`: método privado agora delega para `::GetTypeFilling(m_symbol)`, adicionado `#include "Utils.mqh"`

#### FIX 5 — `SaveState()` fallback com logs detalhados (`TradeManager.mqh`)

- **Bug**: Fallback de cópia manual (quando `FileMove()` falha) era silencioso — difícil diagnosticar falhas
- **Fix**: Cada etapa do fallback agora loga: abertura do src, abertura do dst, sucesso da cópia, deleção do tmp
- Sem alteração de comportamento, apenas melhor observabilidade

#### FIX 6 — `PrintConfiguration()` completa (`Blockers.mqh`)

- **Bug**: Stub que só imprimia Spread e Direção como inteiros (ilegível)
- **Fix**: Implementação completa usando macro `CFG_LOG` para evitar duplicação logger/Print:
  - Exibe Spread atual vs input em pts
  - Exibe Direção como texto legível ("Ambas", "Apenas COMPRAS", etc.)
  - Delega para `m_filters.PrintConfiguration()`, `m_limits.PrintConfiguration()`, `m_drawdown.PrintConfiguration()`
- Requer que os submodulos implementem `PrintConfiguration()` (delegação por design)

### Versões atualizadas

- `EPBot_Matrix.mq5`: 1.58 → 1.59
- `Core/TradeManager.mqh`: 1.25 → 1.27
  - 1.26: FetchDealRealValues + HistorySelect 300s + SaveState logs
  - 1.27: GetTypeFilling() delega para Core/Utils.mqh
- `Core/Blockers.mqh`: 3.25 → 3.26
- `Core/Utils.mqh`: criado (1.00) — `GetTypeFilling(const string symbol)`

### TODO restante (Parte 033)

- [ ] Implementar `PrintConfiguration()` nos submodulos (`BlockerFilters`, `BlockerLimits`, `BlockerDrawdown`)
- [ ] Criar PR da Parte 032 → main
- [ ] Revisar se há outros métodos com lógica duplicada nos submodulos de Blockers
