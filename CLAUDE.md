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
- [x] Expandir padrão "só loga se mudar" para mais campos — Feito na Parte 031
- [x] Criar PR da Parte 030 → main (PR #12 mergeado)

---

## Parte 031 — Em andamento (2026-04-03)

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

#### FIX — TrendFilter logava 2x ao toggle ON/OFF
- **Bug**: SetEnabled e SetTrendFilterEnabled ambos logavam ao toggle
- **Causa**: TrendFilterPanel.Apply() chama ambos (linhas 248-249)
- **Fix**: TrendFilter::SetEnabled feito mudo (sem log), SetTrendFilterEnabled já cobre

#### FIX — DD toggle "REQUER META" eliminado
- **Bug**: Estado tri-state (ON/OFF/REQUER META) confundia o trader
- **Fix**: DD agora é binário ON/OFF; forçado OFF quando dependências não satisfeitas
- OnClickDDToggle bloqueia click se `!ddAllowed`
- SetAllControlsEnabled restaura estado correto do DD toggle

#### FIX — CLR_FIELD_ERROR perdido ao desabilitar controles
- **Bug**: SetEditEnabled() e SetEnabled() sobrescreviam highlight rosa com cinza
- **Fix**: Condição `if(ColorBackground() != CLR_FIELD_ERROR)` antes de aplicar cinza
- Afeta: PanelTabConfig, MACrossPanel, BollingerBandsPanel, RSIFilterPanel, TrendFilterPanel, BollingerBandsFilterPanel

#### FIX — ValidateAndApplyAll ignorava retorno de Apply()
- **Bug**: Sub-painéis retornavam false (erro) mas ValidateAndApplyAll não capturava
- **Fix**: Checa `!Apply(err) || err != ""` e acumula erros de todos os painéis

### Versões atualizadas
- EPBot_Matrix.mq5: 1.56 → 1.57
- MACrossStrategy.mqh: 2.26 → 2.27
- RSIStrategy.mqh: 2.15 → 2.16
- BollingerBandsStrategy.mqh: 1.00 → 1.01
- TrendFilter.mqh: 2.23 → 2.24
- RSIFilter.mqh: 1.11 → 1.12
- BollingerBandsFilter.mqh: 1.00 → 1.01
- FilterBase.mqh: 2.01 → 2.02
- Panel.mqh: 1.61 (fixes DD toggle + ValidateAndApplyAll)
- PanelTabConfig.mqh: 1.36 (fixes DD toggle + CLR_FIELD_ERROR)
- BollingerBandsFilterPanel.mqh: 1.08 (fix CLR_FIELD_ERROR)
- BollingerBandsPanel.mqh: 1.08 (fix CLR_FIELD_ERROR)
- MACrossPanel.mqh: 1.08 (fix CLR_FIELD_ERROR)
- RSIFilterPanel.mqh: 1.08 (fix CLR_FIELD_ERROR)
- TrendFilterPanel.mqh: 1.07 (fix CLR_FIELD_ERROR)

### TODO restante
- [x] Criar PR da Parte 031 → main (PR #16)

#### FIX CRÍTICO — Race condition em ExecuteTrade
- **Bug**: Broker retornava `result.deal = 0` e `result.price = 0.00` em mercados
  voláteis (Gold sob spread spike). Posição era aberta na conta mas EA não
  conseguia rastreá-la → trailing/BE/PartialTP não funcionavam
- **Log do incidente**:
  ```
  ORDEM EXECUTADA COM SUCESSO!
  Order: 67489378, Deal: 0, Preço: 0.00
  ❌ Posição não encontrada após abertura! Order: 67489378
  ```
- **Causas do bug**:
  1. Método 1 (via `DEAL_POSITION_ID`) pulado porque `result.deal == 0`
  2. Método 2 fallback (`PositionsTotal`) executava cedo demais — posição
     ainda não estava visível ao broker/terminal
  3. `result.price = 0` e `result.volume = 0` eram usados depois em
     `CalculatePartialTPLevels` e `RegisterPosition` — valores errados

#### Solução implementada
- **Retry loop**: 5 tentativas × 100ms entre elas (500ms total no pior caso)
- **Novo MÉTODO 1.5**: busca via `HistorySelect` + iteração de `HistoryDealsTotal`
  filtrando por `DEAL_ORDER == result.order`. Resolve o caso em que
  `result.deal = 0` mas `result.order` é válido
- **Ordem de busca por tentativa**:
  1. MÉTODO 1: `result.deal > 0` → `HistoryDealSelect` → `DEAL_POSITION_ID`
  2. MÉTODO 1.5: `result.order > 0` → iteração de deals filtrados
  3. MÉTODO 2: fallback `PositionsTotal` (symbol + magic + tempo < 5s)
- **Dados reais da posição**: após localizar, usa `POSITION_PRICE_OPEN` e
  `POSITION_VOLUME` em vez de `result.price/result.volume`
  - Afeta: `CalculatePartialTPLevels` e `RegisterPosition`
  - Impede que partial TP seja calculado com preço = 0 ou volume = 0

#### Limpeza de dead code (12 arquivos)
- Removidos todos `if(m_logger != NULL)` e `else Print()` fallbacks
- m_logger nunca é NULL em operação — checks eram dead code
- Arquivos: BlockerLimits, BlockerDrawdown, BlockerFilters, RiskManager,
  Blockers, SignalManager, MACrossStrategy, RSIStrategy, BollingerBandsStrategy,
  TrendFilter, RSIFilter, BollingerBandsFilter

### Versões atualizadas (continuação)
- EPBot_Matrix.mq5: 1.57 → 1.59
- TradeManager.mqh: 1.24 → 1.26
- Logger.mqh: 3.28 → 3.29
- BlockerLimits.mqh: 1.00 → 1.01
- BlockerDrawdown.mqh: 1.01 → 1.02
- BlockerFilters.mqh: 1.01 → 1.02
- RiskManager.mqh: 3.16 → 3.17
- Blockers.mqh: 3.24 → 3.25
- SignalManager.mqh: 2.15 → 2.16
- MACrossStrategy.mqh: 2.27 → 2.28
- RSIStrategy.mqh: 2.16 → 2.17
- BollingerBandsStrategy.mqh: 1.01 → 1.02
- TrendFilter.mqh: 2.24 → 2.25
- RSIFilter.mqh: 1.12 → 1.13
- BollingerBandsFilter.mqh: 1.01 → 1.02

### TODO restante (Parte 031)
- [x] **Race condition no ExecutePartialClose**: mesmo bug do ExecuteTrade —
  Deal=0 fazia AddPartialTPProfit() nunca ser chamado → lucro parcial sumia
  (corrigido: retry 5x + guard removido + fallback garantido)
- [x] **Classificação win/loss errada**: UpdateStats usava finalDealProfit
  em vez de totalPositionProfit → trade de +$2.25 contado como LOSS
  (corrigido: 2º parâmetro totalPositionProfit em UpdateStats)
- [ ] **LoadDailyStats classifica errado no reinício**: ao recarregar o CSV,
  classifica pelo finalDealProfit (deal final) em vez do totalPositionProfit.
  Trade com partial TP lucrativo + trailing final negativo = reconstruído como
  LOSS. Afeta: win rate, streak, grossProfit/grossLoss pós-reinício.
  Solução: ao ler linha final no CSV, somar partials do mesmo ticket para
  obter totalPositionProfit e usar para classificação. (ver issue #20)
- [ ] **Trailing Start na GUI**: input `inp_TrailingStart` (início do trailing)
  ainda não está no painel. Adicionar campo + hot reload
- [ ] **Magic Number e RSI não salvos no .cfg**: (issue #22)
  - Magic Number alterado via hot reload não persiste no arquivo de config
  - Configurações do RSI (Period, OS, OB, Middle, TF, AppliedPrice, Mode) não salvam
  - Possível afeta outras estratégias/filtros. Verificar PanelPersistence.mqh
- [ ] **ResyncExistingPositions fallback após 5 tentativas**: (issue #21)
  - Quando ExecuteTrade falha 5x, posição fica órfã no broker mas não registrada no EA
  - Resultado: sem Trailing, sem BE, sem Partial TP
  - Solução: chamar ResyncExistingPositions como 6º fallback, recuperar TP levels
- [ ] **Log de bloqueio por spread otimizado**: atualmente loga "SPREAD ALTO"
  e "SPREAD NORMALIZADO" toda vez que spread sobe/desce, poluindo o log.
  Logar apenas se houve tentativa de entrada (sinal detectado foi bloqueado).
  Aviso visual continua na GUI (STATUS)
- [ ] **Estratégia no comentário da ordem**: adicionar ao campo `comment` da
  ordem o nome da estratégia que gerou o sinal (MACross, RSI, BB). Facilita
  análise posterior no histórico de trades
- [ ] **RSI e BB Filter: campos habilitados com botão OFF**: quando o toggle
  ON/OFF do RSIFilter ou BollingerBandsFilter está em OFF, os campos de
  configuração (Period, OS, OB, etc.) continuam habilitados para edição.
  Deveriam ficar desabilitados (cinza) enquanto o filtro estiver OFF
- [ ] Criar PR da Parte 031 → main

### TODO futuro (sem parte definida)
- [ ] **Desenhar indicadores no gráfico**: quando uma estratégia/filtro está
  ATIVO, plotar os objetos visuais no chart (MAs do MA Cross, bandas do BB,
  linhas de OS/OB do RSI). Ao desativar ou trocar de strategy, remover os
  objetos. Idem para filtros (TrendFilter, RSIFilter, BBFilter)
- [ ] **Múltiplos arquivos .cfg**: funcionalidade para salvar/carregar
  diversos perfis de configuração (ex: "Gold_Scalp.cfg", "EUR_Swing.cfg").
  Dropdown ou lista de perfis no painel, botões Salvar Como / Carregar

### Notas
- Race condition (result.deal=0) ocorre apenas em **conta real**, não reproduz
  em demo — comportamento típico de broker ao vivo sob volatilidade

---

## Parte 032 — Em andamento (2026-04-04)

### O que foi feito

#### FIXES BAIXO RISCO — Guards e Validações

**TradeManager.mqh** (3 fixes):
- [x] **H-04**: ExecutePartialClose — validação `lot >= minLot` APÓS MathFloor rounding
  - Antes: check `lot <= 0` acontecia antes do rounding, lot podia virar 0 depois
  - Adicionado fallback `lotStep <= 0 → 0.01` para prevenir divisão por zero
- [x] **H-05**: SetMagicNumber — `DeleteState()` movido para ANTES de `m_magicNumber = newMagic`
  - Antes: deletava state file do magic NOVO (m_magicNumber já atualizado)
  - Agora: deleta state file do magic ANTIGO corretamente
- [x] **H-06**: ResyncExistingPositions — guard `if(ticket == 0) continue`
  - Previne entrada fantasma com ticket inválido no array m_positions

**RiskManager.mqh** (2 fixes):
- [x] **M-30**: CalculatePartialTPLevels — guard `lotStep <= 0 → 0.01`
  - Previne divisão por zero se broker retornar SYMBOL_VOLUME_STEP = 0
- [x] **L-01**: PrintConfiguration — versão corrigida "v3.14" → "v3.17"

**TrendFilter.mqh** (1 fix):
- [x] **H-12**: SetTrendFilterEnabled — cold reload ao habilitar sem handle MA
  - Se ambos modos estavam desabilitados no Init (handle-less), habilitar via GUI
    agora dispara Deinitialize+Initialize para criar o handle
  - Se Initialize falhar, reverte `m_useTrendFilter = false` com log de erro
  - Previne estado inválido onde filtro bloqueia todos os sinais permanentemente

### Versões atualizadas
- TradeManager.mqh: 1.25 → 1.26
- RiskManager.mqh: 3.16 → 3.17
- TrendFilter.mqh: 2.24 → 2.25

### TODO restante (Parte 032 continuação)
- [ ] Fixes de risco médio/alto: C-01, C-02, C-06, C-07, H-01, H-02, H-11
- [ ] Criar PR da Parte 032 → main

