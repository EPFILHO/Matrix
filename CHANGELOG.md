# CHANGELOG — EPBot Matrix

Histórico consolidado de mudanças do EA. Antes da Parte 36 cada arquivo
mantinha seu próprio bloco de CHANGELOG no header; este documento unifica
todos. Versões individuais dos arquivos continuam em `#property version`
e nos comentários do topo.

Organização: do mais recente ao mais antigo, agrupado por **Parte** (sessão
de trabalho). Cada Parte lista as mudanças por arquivo com a versão alvo.

---

## Parte 36 — Refatoração + Segurança Operacional

**EPBot_Matrix.mq5 v1.68**
- HistoryProcessor (Fatia 1 da refatoração do god file): bloco de detecção
  de fechamento de posição extraído do OnTick para
  `Core/HistoryProcessor.mqh` (CHistoryProcessor). OnTick fica ~82 linhas
  menor; lógica de soma de deals OUT/OUT_BY (padrão ouro MQL5) agora
  isolada e reutilizável.
- Trava de TFs (eliminação do PERIOD_CURRENT operacional).
- Grace period unificado: globais `g_graceBarTime` e `g_lastPanelStarted`
  bloqueiam novas entradas no candle do init/start. Cobre primeira carga,
  REASON_CHARTCHANGE, REASON_RECOMPILE e clique "Iniciar" no painel.
  Gerência de posição aberta segue normalmente.
- Fix cosmético: log "⏰ Timeframe:" usa `EnumToString(Period())` em vez
  de `EnumToString(PERIOD_CURRENT)` — agora mostra TF real do gráfico.

**Core/HistoryProcessor.mqh v1.00 (novo)**
- Extraído de `EPBot_Matrix.mq5` OnTick() (linhas 1432–1515 originais).
- Detecta fechamento de posição comparando ticket anterior x atual.
- Padrão MQL5: soma TODOS os deals de saída (partial + final) para
  classificar win/loss (ref. https://www.mql5.com/en/forum/439334).
- Depende de CLogger, CBlockers, CTradeManager via DI (Init).

**Core/Inputs.mqh v1.11**
- Defaults dos 7 inputs de timeframe trocados de PERIOD_CURRENT para
  PERIOD_M1 (`inp_FastTF`, `inp_SlowTF`, `inp_RSITF`, `inp_BBTF`,
  `inp_TrendMATF`, `inp_RSIFilterTF`, `inp_BBFiltTF`).
- Elimina o risco de a estratégia mudar silenciosamente quando o usuário
  troca o TF do gráfico. Estratégia/filtros agora têm TF próprio
  independente do gráfico.
- Presets antigos preservam o que estava salvo; só novas instâncias sem
  config recebem o default novo.

**GUI/PanelUtils.mqh v1.04**
- `TFName()`: removido case PERIOD_CURRENT (não exibe mais "ATUAL").
- `CycleTF()`: PERIOD_CURRENT removido do array; fallback agora é
  PERIOD_M1.

---

## Parte 035 — AppliedPrice GUI + TrailingActivation + Fixes TF "ATUAL"

**EPBot_Matrix.mq5 v1.67/v1.66/v1.65/v1.64**
- v1.67: AppliedPrice em RSI/BB Strategy panels — botão "Preço" cicla
  CLOSE→OPEN→HIGH→LOW→MEDIAN→TYPICAL; Apply chama SetAppliedPrice
  (hot-reload via Deinit+Init).
- v1.66: Fix TF "ATUAL" nas estratégias/filtros RSI e Bollinger Bands —
  Setup() de RSI/BB Strategy/Filter já não converte PERIOD_CURRENT em
  Period(); MACross e TrendFilter já preservavam, agora todos consistentes.
- v1.65: TrailingActivation na GUI — radio "SEMPRE | APOS TP1 | APOS TP2"
  em RISCO 2; hot-reload via SetTrailingActivation; persistência em .cfg
  via nova chave `TrailingActivation`; .cfg antigos retrocompatíveis.
  Antes o toggle colapsava 4 modos em ALWAYS/NEVER; agora preserva os 4.
- v1.64: AppliedPrice em RSI/BB Filter GUI — botão "Preço" nos panels de
  filtro com hot-reload e persistência via `SConfigData.rsi/bbFiltApplied`.

**Core/RiskManager.mqh v3.20**
- Novo getter `GetTrailingActivation()` — necessário para expor o enum
  `ENUM_TRAILING_ACTIVATION` à camada GUI/Persistência.

**Core/ConfigPersistence.mqh v1.03**
- `SConfigData.trailingActivation` (ENUM_TRAILING_ACTIVATION).
- Save/Load chave "TrailingActivation"; retrocompat: .cfg antigos sem a
  chave derivam o modo do `trailOn` (ON→ALWAYS / OFF→NEVER).

**GUI/Panel.mqh v1.63**
- Novos membros: `m_c2_lTrlMode` + `m_c2_bTrlMode[3]` (radio).
- Novo state var: `m_cur_trailMode` (ENUM_TRAILING_ACTIVATION).
- Handler `OnClickTrailMode` declarado + dispatcher atualizado.

**GUI/PanelTabConfig.mqh v1.39**
- Radio "Ativar em" em RISCO 2 (entre toggle Trailing e Trail Start).
- `RefreshRisco2State`: radio grayed/inativo quando toggle Trailing OFF.
- `OnClickTrailMode` handler (guard: ignora clique se toggle OFF).
- `ApplyConfig`: `SetTrailingActivation(m_cur_trailOn ? m_cur_trailMode : TRAILING_NEVER)`
  preserva os 4 modos do enum.

**GUI/PanelPersistence.mqh v1.08**
- `CollectConfigData`: grava `data.trailingActivation = (trailOn ? m_cur_trailMode : NEVER)`.
- `ApplyLoadedConfig`: deriva `m_cur_trailMode` do enum (NEVER → ALWAYS
  como default radio).

**GUI/Panels/BollingerBandsFilterPanel.mqh v1.11**
- Novo botão "Preço" ciclando CLOSE/OPEN/HIGH/LOW/MEDIAN/TYPICAL.
- Apply chama SetAppliedPrice; Reload e _RefreshFieldState sincronizam.

**GUI/Panels/BollingerBandsPanel.mqh v1.11**
- Botão "Preço" entre Time Frame e bloco SINAIS; hot-reload via
  Deinit+Init; cobertura no _RefreshFieldState/SetEnabled.

**GUI/Panels/RSIFilterPanel.mqh v1.11**
- Idem BB Filter Panel para AppliedPrice.

**GUI/Panels/RSIStrategyPanel.mqh v1.11**
- Idem BB Panel para AppliedPrice.

**Strategy/Filters/BollingerBandsFilter.mqh v1.03**
- Fix GUI: `Setup()` não converte mais PERIOD_CURRENT para `Period()`.

**Strategy/Filters/RSIFilter.mqh v1.14**
- Fix GUI: idem BB Filter.

**Strategy/Strategies/BollingerBandsStrategy.mqh v1.04**
- Fix GUI: idem BB Filter.

**Strategy/Strategies/RSIStrategy.mqh v2.19**
- Fix GUI: antes o painel RSI mostrava "M5" em vez de "ATUAL" porque
  GetTimeframe() retornava o TF do chart, não PERIOD_CURRENT (0).

---

## Parte 034 — Hot-reload fixes + Persistência por tipo

**EPBot_Matrix.mq5 v1.63/v1.62**
- v1.63 — fix hot-reload de ExitMode/UseMACross: linhas 1465/1610/1654/1938
  liam `inp_ExitMode` e `inp_UseMACross` (estáticos). Após hot-reload via
  GUI, decisões de lock de candle, FCO block e "virar a mão" ficavam
  defasadas. Agora leem `g_maCrossStrategy.GetExitMode()/GetEnabled()`.
- v1.62 — fix hot-reload do Partial TP: OnTick (MonitorPartialTP) e
  OnTrade (RegisterPosition) liam `inp_UsePartialTP` (estático). Agora
  usa `g_riskManager.IsPartialTPEnabled()`.

**Core/RiskManager.mqh v3.19**
- Adiciona getters para persistência completa de SL/TP/Trailing/BE por
  tipo: `GetSLATRMultiplier`, `GetTPATRMultiplier`, `GetRangeMultiplier`,
  `GetTrailingStart/Step/ATRStart/ATRStep`,
  `GetBEActivation/Offset/ATRActivation/ATROffset`. Necessário para que
  `CollectConfigData` leia os 3 valores por tipo (antes só o tipo ativo
  era persistido).

**GUI/PanelTabConfig.mqh v1.38**
- H-14 fix: `ApplyConfig` agora ATÔMICO — refatorado em duas passadas
  (valida todos os campos → se houver QUALQUER erro, retorna sem aplicar
  nada nos módulos). Antes, erros tardios deixavam estado inconsistente.
- H-15 fix: `OnClickSLType/OnClickTPType` agora lêem o valor corrente do
  RiskManager via getters em vez de `inp_*`. Preserva edições do usuário
  entre trocas de tipo.

**GUI/PanelPersistence.mqh v1.07**
- Fix arquitetural de persistência por tipo: `CollectConfigData` antes só
  gravava o valor do tipo ATIVO (SL/TP/Trailing/BE); inativos ficavam em
  0 por ZeroMemory, fazendo o usuário perder edições ao trocar de tipo.
  Agora lê os 3 valores de SL, 2 de TP, 2×2 de Trailing e 2×2 de BE via
  getters e só sobrescreve o ATIVO com o CEdit.
- `ApplyLoadedConfig`: aplica setters para TODOS os tipos no RiskManager.
  Usa 0 como sentinela de "não sobrescrever" para compat com .cfg antigos.

---

## Parte 033 — Issue #27, #28, #29, #22 + Hot-reload persistência GUI

**EPBot_Matrix.mq5 v1.61/v1.60**
- v1.61 (Issue #28): Comment das ordens agora usa
  `GetLastSignalShortSource()`: "EPBot MACross", "EPBot RSI", "EPBot BB"
  ao invés de "EPBot Matrix" (input removido). `g_tradeComment` removido.
- v1.60 (Issue #27): log de spread otimizado. `CanTrade()` chamado com
  `skipSpread=true` antes do sinal — spread não gera log sozinho. Após
  sinal detectado (≠ SIGNAL_NONE), `IsSpreadOk()` checa e loga
  "⛔ Entrada bloqueada por spread alto" apenas quando sinal real foi
  bloqueado. Elimina dezenas de logs por hora em ativos voláteis.

**Core/Blockers.mqh v3.26 + Core/BlockerFilters.mqh v1.03 (Issue #27)**
- `CanTrade()` recebe parâmetro `skipSpread` (default false). Quando true,
  pula verificação de spread.
- `IsSpreadOk(blockReason)`: wrapper público para checar spread sem log.
- Logs de "SPREAD ALTO"/"NORMALIZADO" eram gerados em toda transição,
  mesmo sem sinal de entrada. Agora `CheckSpreadWithLog()` é silenciosa;
  log ocorre no EA apenas quando há sinal. `m_sSfWasBlocked` removido.

**Core/Inputs.mqh v1.10 + Core/ConfigPersistence.mqh v1.02 (Issue #28)**
- Removido `inp_TradeComment` (comment vem de
  `SignalManager.GetLastSignalShortSource()`).
- Removido campo `tradeComment` de `SConfigData`; WriteKV/ReadKV
  eliminados.

**Core/RiskManager.mqh v3.18**
- H-02 fix: `CalculatePartialTPLevels` valida cruzado `tp1_lot + tp2_lot
  <= totalLotSize`. Se soma exceder, `tp2_lot` é reduzido para o lote
  residual, preservando TP1 intacto.
- Lot rounding: `MathFloor + epsilon` substituído por `MathRound` em
  todos os cálculos de lote de TP parcial. Evita perda de step em
  divisões IEEE 754.
- Limpeza: removidos 14 guards `if(m_logger != NULL)` + `else Print()`.

**Core/TradeManager.mqh v1.27**
- C-07 fix: `MonitorPartialTP` re-valida índice e re-obtém preço atual
  entre execução de TP1 e avaliação de TP2.
- C-07 fix: verificação de lote residual antes de `ExecutePartialClose`
  do TP2 — se posição tiver menos volume que `tp2_lot`, ajusta com
  MathRound ou cancela TP2 se residual < lote mínimo.

**Strategy/Base/StrategyBase.mqh v2.03 (Issue #28)**
- `GetShortName()` virtual: retorna nome curto da estratégia, usado no
  comentário das ordens (limite ~31 chars MQL5). Default: `m_strategyName`.

**Strategy/Strategies/MACrossStrategy.mqh v2.29**
- `GetShortName()` override → "MACross".

**Strategy/Strategies/RSIStrategy.mqh v2.18**
- `GetShortName()` override → "RSI".

**Strategy/Strategies/BollingerBandsStrategy.mqh v1.03**
- `GetShortName()` override → "BB".

**GUI/Panel.mqh v1.62 (Issue #28)**
- Removido `m_co_lComm/m_co_iComm` (campo Comentario).
- `SetEditEnabled` para `m_co_iComm` removido de `SetAllControlsEnabled`.

**GUI/PanelPersistence.mqh v1.06/v1.05**
- v1.06 (Issue #28): removido `data.tradeComment` em CollectConfigData
  e restauração de `m_co_iComm.Text()` em ApplyLoadedConfig.
- v1.05: `SaveCurrentConfig/HasSavedConfig/OnClickIgnoreBanner` usam
  `m_initMagicNumber` (fixo no init) em vez de `m_magicNumber` (mutável).
  Corrige bug onde mudar magic via GUI fazia save ir para arquivo
  diferente do que o EA busca ao reiniciar.
- `CollectConfigData`: usa `TimeLocal()` para `lastModified` em vez de
  `TimeCurrent()` — exibe hora local do trader no banner.

**GUI/StrategyPanelBase.mqh v1.05 + GUI/FilterPanelBase.mqh v1.05**
- `Reload()` virtual default no-op; painéis sobrescrevem para repopular
  campos GUI a partir do módulo (usado por ApplyLoadedConfig).

**GUI/Panels/* (vários, Issue #29 e Issue #22)**
- `_RefreshFieldState()`: respeita `m_pendingEnabled` como toggle mestre
  (todos campos cinza/desabilitados quando toggle OFF). Cobertura em
  BB Panel/Filter, MA Cross Panel, RSI Panel/Filter (v1.09/v1.10).
- `Reload()`: repopula campos GUI a partir do módulo (fix Issue #22),
  chamado por ApplyLoadedConfig após atualizar os módulos.
- Cobertura em todos os painéis v1.10 (BB Panel/Filter, MA Cross, RSI
  Panel/Filter, TrendFilterPanel v1.08).

---

## Parte 032 — Hardening do TrendFilter

**Strategy/Filters/TrendFilter.mqh v2.25**
- H-12: `SetTrendFilterEnabled` faz cold reload ao habilitar sem handle MA
  (previne estado inválido onde filtro bloqueia tudo permanentemente).

---

## Parte 031 — Race conditions, partial TP fixes, limpeza

**EPBot_Matrix.mq5 v1.59/v1.58/v1.57**
- v1.59: Fix — `UpdateStats()` passa `totalPositionProfit` para
  classificação win/loss correta (soma parciais + deal final). Antes,
  trade de +$2.25 era contado como LOSS porque só via o deal final
  -$0.75.
- v1.58: Fix CRÍTICO — race condition em `ExecuteTrade` quando broker
  retorna `result.deal=0` e `result.price=0` (comum no Gold sob spread
  volátil). Posição abria na conta mas EA não rastreava → trailing/BE/
  PartialTP não funcionavam.
  - Retry loop (5x × 100ms) para localizar posição após `OrderSend`.
  - Novo MÉTODO 1.5: busca via `HistoryOrderSelect` + iteração de deals
    filtrados por `DEAL_ORDER` (resolve `result.deal=0`).
  - `RegisterPosition` + `CalculatePartialTPLevels` agora usam
    `POSITION_PRICE_OPEN/POSITION_VOLUME` (dados reais da posição) em
    vez de `result.price/result.volume`.
- v1.57: Fix — memory leak no OnDeinit (g_bbStrategy e g_bbFilter não
  eram deletados na ETAPA 2; CleanupAll só rodava em INIT_FAILED).

**Core/Logger.mqh v3.29**
- `UpdateStats()` recebe 2º parâmetro opcional `totalPositionProfit` para
  classificação win/loss correta quando há partial TPs.
  - `m_dailyProfit` acumula apenas `finalDealProfit` (sem double-count).
  - Win/loss/draw classificado pelo resultado TOTAL da posição.
  - `grossProfit` acumula `finalDealProfit` só quando `classifyProfit > 0`.
  - Parâmetro omitido = comportamento antigo.
- LIMITAÇÃO CONHECIDA: `LoadDailyStats()` ainda classifica pelo
  `finalDealProfit` do CSV no reinício do EA (ver KNOWN LIMITATION).

**Core/TradeManager.mqh v1.26**
- Fix CRÍTICO: `ExecutePartialClose` retornava `Deal=0` em mercados
  voláteis (Gold). Guard `dealTicket > 0` no `MonitorPartialTP` impedia
  `AddPartialTPProfit()` e `SavePartialTrade()` de executar → lucro
  parcial desaparecia do sistema.
- `ExecutePartialClose`: retry 5x × 100ms para buscar deal via
  `DEAL_ORDER` no histórico (mesmo padrão de ExecuteTrade v1.58).
- `MonitorPartialTP`: guard `dealTicket > 0` removido. Se retry falhar,
  usa estimativa por preço como fallback.

**Core/Blockers.mqh v3.25 + BlockerDrawdown v1.02 + BlockerFilters v1.02 + BlockerLimits v1.01**
- Limpeza: removidos `if(m_logger != NULL)` e `else Print()` fallbacks
  (m_logger nunca é NULL no fluxo real).

**Strategy/Base/FilterBase.mqh v2.02**
- `SetEnabled()` virtual — permite override com log nas filhas.

**Strategy/Filters/RSIFilter.mqh v1.13/v1.12**
- `SetEnabled` override: loga "Filtro: ATIVADO/DESATIVADO" se mudar.
- `SetFilterMode/Oversold/Overbought/LowerNeutral/UpperNeutral/Shift`:
  só logam se valor realmente mudar.
- `SetPeriod/Timeframe/AppliedPrice`: skip Deinit+Init se parâmetros
  forem idênticos.

**Strategy/Filters/TrendFilter.mqh v2.25/v2.24**
- `SetEnabled` override; `SetTrendFilterEnabled/NeutralDistance` só logam
  se mudar; `SetMAPeriod/Method/Timeframe/Applied/MACold` skip
  Deinit+Init se idênticos.

**Strategy/Filters/BollingerBandsFilter.mqh v1.02/v1.01**
- `SetEnabled` override; `SetSqueezeMetric/Threshold/PercentilePeriod`
  só logam se mudar; `SetPeriod/Deviation/Timeframe/AppliedPrice` skip
  Deinit+Init se idênticos.

**Strategy/Strategies/MACrossStrategy.mqh v2.28/v2.27**
- Limpeza idem; `SetEnabled` override; `SetEntryMode/ExitMode` só logam
  se mudar; setters de MA skip Deinit+Init se idênticos.

**Strategy/Strategies/RSIStrategy.mqh v2.17/v2.16**
- Idem MACrossStrategy.

**Strategy/Strategies/BollingerBandsStrategy.mqh v1.02/v1.01**
- Idem MACrossStrategy.

---

## Parte 030 — Validação por campo na GUI

**GUI/PanelUtils.mqh v1.03**
- `CLR_FIELD_ERROR`: constante para highlight de campos inválidos.
- `MarkFieldError()`: pinta fundo do CEdit vermelho claro.
- `ClearFieldError()`: restaura fundo branco (se campo habilitado).
- `CalcMaxPoints()`: calcula limite max de pontos baseado no ativo.
- `CalcMinSLTP()`: SL/TP mínimo do broker (STOPS_LEVEL).
- `CalcSymbolLotLimits()`: min/max/step de lote do ativo.

**GUI/StrategyPanelBase.mqh v1.04 + GUI/FilterPanelBase.mqh v1.04**
- `Apply(string &outErr)`: retorna nomes dos campos inválidos para o
  header.

**GUI/Panel.mqh v1.61**
- `ValidateAndApplyAll()`: acumula erros CONFIG + sub-painéis numa
  mensagem só.
- `ApplyConfig()` assinatura: void → `string &outErr`.
- Validação cruzada: Exit Mode TP/SL requer TP (Fixo/ATR) definido.

**GUI/Panels/MACrossPanel.mqh v1.08**
- `Apply()`: highlight rosa por campo + mensagem
  "Invalido: Fast, Slow…".
- `SetEnabled()`: preserva CLR_FIELD_ERROR ao habilitar.

---

## Parte 029 — Travas com EA rodando + TFs completos

**GUI/PanelUtils.mqh v1.02**
- `TFName()`: adicionados todos os timeframes MQL5 (M2-M20, H2-H12).
- `CycleTF()`: idem.

**GUI/Panel.mqh v1.60/v1.59**
- v1.60: Fix restauração DD toggle ao destravar.
- v1.59: `SetAllControlsEnabled` expandido com radio groups, toggles e
  edits de RISCO, RISCO 2, BLOQUEIOS, BLOQ2 (News).
- Guard `m_eaStarted` no dispatch de OnClick dos sub-painéis.
- Sub-painéis `SetEnabled()`: cobertura de CButtons (toggle, TF, radios).

**GUI/StrategyPanelBase.mqh v1.03 + GUI/FilterPanelBase.mqh v1.03**
- `m_locked`: flag para impedir `Update()` de sobrescrever estado travado.

**GUI/Panels/TrendFilterPanel.mqh v1.06/v1.05**
- v1.06: `m_locked`; `Update()` não sobrescreve visual quando EA rodando.
- v1.05: `SetEnabled()` toggle ON/OFF cinza, campos fundo branco/cinza,
  labels dim, Method radios + TF/Price buttons cobertos.

---

## Parte 028 — Logs de debug silenciosos

**Core/Logger.mqh v3.28**
- `SetShowDebug()`: log removido — alterações de debug não são logadas.
- `SetDebugCooldown()`: idem.

**Core/TradeManager.mqh v1.25**
- `SetSlippage()`: só loga/aplica quando valor realmente muda.

**GUI/Panel.mqh v1.58**
- `SetAllControlsEnabled`: adiciona `SetButtonEnabled` para
  `m_co_bConfl` e `m_co_bDbg` (Conflito Sinais e Debug Logs não eram
  travados com EA rodando).
- `ApplyConfig()`: void → bool.

---

## Parte 027 — Config Persistence + Hot-reload Magic Number + INICIAR/PAUSAR

**EPBot_Matrix.mq5 v1.55/v1.54/v1.53**
- v1.55: Runtime vars `g_magicNumber`, `g_slippage` substituem `inp_*`
  (read-only) para suportar hot reload.
- v1.54: Config Persistence — banner redesenhado com caixa de destaque,
  descrições explicativas e bloqueio de navegação. Banner exibido para
  REASON_PROGRAM (EA adicionado fresh).
- v1.53: Config Persistence — salva/carrega configurações GUI entre
  restarts do EA (arquivo `.cfg` por símbolo+magic).
  - REASON_PARAMETERS: deleta config salva (preset alterado).
  - REASON_CHARTCHANGE/TEMPLATE: auto-carrega silenciosamente.
  - REASON_CLOSE/REMOVE: mostra banner Carregar/Ignorar.
  - REASON_RECOMPILE/ACCOUNT: auto-carrega silenciosamente.

**Core/ConfigPersistence.mqh v1.01/v1.00 (novo)**
- v1.00: `SConfigData` struct com TODOS os parâmetros configuráveis via
  GUI. `CConfigPersistence`: Save/Load/Delete/Exists/GetLastModified.
  Formato `key=value`. Escrita atômica via `.tmp` + rename. Guard de
  backtest (`MQL_TESTER`). Arquivo: `MQL5/Files/Matrix_{symbol}_{magic}.cfg`.
- v1.01: Fix — campos `rsiOversold`, `rsiOverbought`, `rsiMidLevel`,
  `trendMinDistance`, `rsiFiltOversold`, `rsiFiltOverbought` alterados
  de int para double (evita truncamento).

**Core/Inputs.mqh v1.09**
- Magic Number, Trade Comment, Daily Limits agora na GUI (sem novos
  inputs).

**Core/Logger.mqh v3.27**
- `ReloadForMagic(int newMagic)`: hot reload do Magic Number. Salva
  relatório do magic atual, atualiza filenames CSV/TXT, reconstrói stats
  via `LoadDailyStats()`.

**Core/Blockers.mqh v3.24 + BlockerDrawdown v1.01 + BlockerFilters v1.01**
- `SetMagicNumber()`: hot reload do Magic Number. Reseta peak/drawdown
  state (peak calculado com magic antigo é inválido).

**GUI/StrategyPanelBase.mqh v1.02 + GUI/FilterPanelBase.mqh v1.02/v1.01**
- v1.02: Pure virtual `Apply()` e `SetEnabled(bool)` para controle
  centralizado (Fase 2: Controle de Estado).
- v1.01: `m_parent (CEPBotPanel*)`: referência ao painel principal,
  necessário para persistência.

**GUI/Panel.mqh v1.57/v1.55/v1.54/v1.53/v1.52/v1.51/v1.50/v1.49**
- v1.57: REVERT v1.56 (minimize fix quebrado).
- v1.55: Bugfix NULL guards em ValidateAndApplyAll/SetAllControlsEnabled.
- v1.54: Fase 2 Controle de Estado — barra 3 botões (Start/Save/Cancel),
  `m_eaStarted`, `m_savedConfig` snapshot, `m_cur_trailingType/beType`
  runtime vars.
- v1.53: Botão INICIAR/PAUSAR no topo do painel (acima das tabs). Verde
  "INICIAR EA" / amarelo "PAUSAR EA". Layout: PANEL_HEIGHT 600→626.
- v1.52: Banner — bloqueio de navegação enquanto visível.
- v1.51: Banner redesenhado com caixa de destaque centralizada (CEdit
  background); descrições explicativas. Fix banner reaparecendo após
  minimize/restore.
- v1.50: Fix — `CollectConfigData` e `ApplyLoadedConfig` movidos para
  public. Fix — `m_bbStrategy` e `m_bbFilter` inicializados com NULL.
- v1.49: OUTROS — Magic Number (CEdit + aviso). RISCO 2 — Limites
  Diários movidos de BLOQUEIOS com toggle ON/OFF dinâmico.

---

## Parte 026 — Bollinger Bands + Reconexão de TF

**EPBot_Matrix.mq5 v1.52/v1.47**
- v1.52: Fix GUI na troca de TF (solução padrão ouro MQL5) —
  `OnDeinit(REASON_CHARTCHANGE)` NÃO destrói o painel. `OnInit` detecta
  `g_panel != NULL` e chama `ReconnectModules()` que re-injeta ponteiros
  novos sem recriar objetos gráficos. Sub-painéis recebem ponteiros via
  SetStrategy/SetFilter tipados com dynamic_cast. `if(!m_minimized)
  ShowTab()` evita controles soltos ao trocar TF com painel minimizado.
- v1.47: Bollinger Bands Strategy (FFFD/Rebound/Breakout); BB Filter
  (Anti-Squeeze, 3 métricas: Absoluto/Relativo/Percentil); GUI:
  BollingerBandsPanel + BollingerBandsFilterPanel.

**Core/Inputs.mqh v1.08**
- BB Strategy: `inp_UseBB`, `inp_BBPriority`, `inp_BBPeriod`,
  `inp_BBDeviation`, `inp_BBApplied`, `inp_BBTF`, `inp_BBMode`,
  `inp_BBEntryMode`, `inp_BBExitMode`.
- BB Filter: `inp_UseBBFilter`, `inp_BBFiltPeriod`, `inp_BBFiltDeviation`,
  `inp_BBFiltApplied`, `inp_BBFiltTF`, `inp_BBFiltMetric`,
  `inp_BBFiltThreshold`, `inp_BBFiltPercPeriod`.

**Strategy/Strategies/BollingerBandsStrategy.mqh v1.00 (novo)**
- 3 modos: BB_MODE_FFFD (Fechou Fora, Fechou Dentro — reversão
  confirmada); BB_MODE_REBOUND (toque + reversão na banda); BB_MODE_BREAKOUT
  (rompimento, trend-following).
- Indicador `iBands()` com período, desvio, applied price, timeframe.
- Suporte a entry mode (NEXT_CANDLE/E2C) e exit mode (FCO/VM/TP_SL).
- FCO em BB: sai quando preço cruza a banda central (middle).

**Strategy/Filters/BollingerBandsFilter.mqh v1.00 (novo)**
- Filtro Anti-Squeeze: bloqueia trades quando bandas estão estreitas
  (mercado em range).
- 3 métricas: BB_SQUEEZE_ABSOLUTE (pontos), BB_SQUEEZE_RELATIVE (%),
  BB_SQUEEZE_PERCENTILE (compara com últimas N barras).

**GUI/Panel.mqh v1.48/v1.47/v1.42/v1.41/v1.40/v1.39**
- v1.48: `ReconnectModules()` re-injeta ponteiros após troca de TF sem
  recriar objetos gráficos. Usa dynamic_cast + SetStrategy/SetFilter.
  `if(!m_minimized)` antes de ShowTab().
- v1.47: Simplificação minimize/maximize — removido deferred minimize.
  Mantido: Update() early-return + ChartEvent bypass quando minimized.
- v1.42: Fix GUI minimize — `Update()` retorna imediatamente se
  `m_minimized`. Evita labels "soltos" no gráfico.
- v1.41: Removido `GetPriorityMapText()` (não mais utilizado).
- v1.40: `ResolveStrategyPriority()`: auto-ajuste de prioridade
  (incrementa se conflito).
- v1.39: BB Strategy e BB Filter integrados em `RegisterPanels()`.

---

## Parte 025 — Refatoração Blockers + StrategyBase + Sub-painéis

**EPBot_Matrix.mq5 v1.45**
- `inp_RSISignalShift` removido do `RSIStrategy.Setup()` (sempre usa
  shift=1, barra fechada).
- Blockers v3.22: DailyLimits verificado ANTES do Streak em `CanTrade()`.
- `inp_MACrossMinDistance` integrado ao `MACrossStrategy.Setup()`.

**Core/Blockers.mqh v3.23/v3.22**
- v3.23: Refatoração — CBlockers dividido em 3 módulos coesos:
  `BlockerFilters.mqh` (Time + News + Spread), `BlockerDrawdown.mqh`
  (Drawdown), `BlockerLimits.mqh` (Daily + Streak). CBlockers passa a
  ser orchestrator — API pública inalterada.
- v3.22: `CanTrade()` — DailyLimits verificado ANTES do Streak;
  diagnóstico correto quando ambos bloqueiam.

**Strategy/Base/FilterBase.mqh v2.01 + StrategyBase.mqh v2.02**
- `GetStatusSummary()` virtual: retorna string de status para sub-página
  GERAL do painel GUI ("Não iniciado" / "Ativo (P:N)" / "Inativo").

**GUI/Panel.mqh v1.38/v1.37**
- v1.38: `CStrategyPanelBase` / `CFilterPanelBase` — base abstrata para
  sub-páginas. Cada estratégia/filtro encapsula seus controles em
  `GUI/Panels/*.mqh`. `RegisterPanels()` factory method. ChartEvent:
  loops genéricos. Nova estratégia/filtro = 1 arquivo novo + 2 linhas em
  RegisterPanels.
- v1.38: `PanelUtils.mqh` — funções livres (TFName, CycleTF,
  ApplyToggleStyle, ...).
- v1.37: Sub-página GERAL em ESTRATEGIAS e FILTROS — GUI genérica;
  `MAX_OVERVIEW_ROWS=6`; novas estratégias/filtros aparecem
  automaticamente sem editar GUI.

---

## Parte 024 — Sub-páginas ESTRAT/FILTROS + DD expandido

**EPBot_Matrix.mq5 v1.44/v1.43/v1.42/v1.41**
- v1.44: "Sempre criar" estratégias e filtros no OnInit; `inp_Use*`
  define estado inicial (ativo/inativo), não a criação.
- v1.43/v1.42: Removido hot-create de RSI; sync de ponteiro via getters.
- v1.41 (revisão): Fix — `CleanupAll()` previne memory leak em
  INIT_FAILED. Fix — `RSIStrategy v2.13` Setup() não força
  `m_enabled=true`. Fix — `m_e_statusMAExpiry` inicializado no construtor.
- v1.41 (original): Sub-páginas em ESTRAT [MA CROSS] [RSI]; em FILTROS
  [TREND] [RSI]; SIGNAL MANAGER movido de ESTRAT → STATUS. Fix DD não
  fechava posição ao ativar via hot reload. Fix `GetCurrentDrawdown()`
  inclui floating P/L.

**Core/Blockers.mqh v3.21/v3.20/v3.19**
- v3.21: Getters públicos para GUI RESULTADOS — DD: `GetDrawdownType`,
  `GetDrawdownValue`, `GetDrawdownPeakMode`. Streak:
  `IsStreakControlEnabled`, `GetMaxLossStreak/WinStreak`,
  `GetLossStreakAction/WinStreakAction`,
  `GetLoss/WinPauseMinutes`.
- v3.20: Fix `CheckDrawdownLimit()` usa `m_logger.GetDailyProfit()` +
  floating.
- v3.19: `TryActivateDrawdownNow(dailyProfit)`. Fix
  `GetCurrentDrawdown()` inclui floating.

**GUI/Panel.mqh v1.36/v1.35/v1.34/v1.33/v1.32/v1.31/v1.30/v1.29/v1.28/v1.27/v1.26/v1.25/v1.24**
- v1.36: AppliedPrice para MA Cross (Fast+Slow) e TrendFilter.
- v1.35: Toggle ON/OFF + APLICAR para TrendFilter e RSIFilter (aba
  FILTROS).
- v1.34: Removido hot-create de RSI; padrão igual ao MACross.
- v1.33: Fix compilação — removido CRSIStrategy** (MQL5 não suporta
  ponteiro-para-ponteiro).
- v1.30/v1.29/v1.28: Toggle ON/OFF MA Cross e RSI; legendas dinâmicas;
  PartialTPHint.
- v1.27: RSI sub-página com campos editáveis hot/cold reload.
- v1.26: ESTRAT (MA Cross sub-página) com campos editáveis inline.
- v1.25: Aba RESULTADOS/PROTECAO com novos labels para DD expandido.
- v1.24: Sub-páginas ESTRAT [MA CROSS] [RSI]; FILTROS [TREND] [RSI];
  SIGNAL MANAGER → STATUS.

---

## Parte 023 — DD configurável + Sub-páginas iniciais

**EPBot_Matrix.mq5 v1.40**
- Panel v1.17 + Blockers v3.09 — Config Bloqueios expandido. Partial TP
  movido de RISCO 2 → RISCO. BLOQUEIOS: radio Profit Target Action,
  Streak Action, DD Type, DD Peak Mode. Blockers v3.09:
  `SetDrawdownType` + `SetDrawdownPeakMode`.

**Core/Logger.mqh v3.26**
- Novo `m_dailyTradeResults[]` armazena sequência ordenada win/loss.
- Novo `GetDailyTradeResults()` expõe sequência para Blockers.
- `LoadDailyStats()` popula sequência para reconstrução de streak.
- `ResetDaily()` e construtor limpam a sequência.

---

## Histórico anterior (Parte 022 e antes)

Extraído de `EPBot_Matrix.mq5` (v1.39 e anteriores) e de `GUI/Panel.mqh`
(v1.23 e anteriores). Datado de fev/2026.

**EPBot_Matrix.mq5 — versões iniciais**
- v1.39: Radio buttons + RISCO 2 — Cycle buttons → CButton[] horizontais
  (SL Type, TP Type, Direção); sub-página RISCO 2 (Trailing/BE/Partial
  TP); 4 sub-páginas CONFIG.
- v1.38: Fix clicks — OnEvent processa CAppDialog::OnEvent() PRIMEIRO.
- v1.37: Painel posições fixas + enable/disable; conflito TP ATR vs
  Partial TP com bloqueio mútuo.
- v1.36: Layout RISCO dinâmico com Move().
- v1.35: Seletores de tipo SL/TP (FIXO→ATR→RANGE / NENHUM→FIXO→ATR);
  PANEL_HEIGHT 540→600.
- v1.34: RISCO expandido (ATR Period, Range Period, Compensar Spread).
- v1.33: HOT RELOAD — aba CONFIG redesenhada com campos editáveis;
  partição do painel em 6 arquivos (Panel + 5 PanelTab*).
- v1.32: Painel GUI inicial (5 abas, timer 1.5s, MouseProtection).
- v1.31: Correção de bugs — `CopyBuffer` validação; `HistorySelect`
  janela 10s→60s; log quando `PositionSelectByTicket` falha.
- v1.30: Filtro de Direção (`CanTradeDirection()` agora chamada);
  correção entrada no mesmo candle.
- v1.29: Modo cálculo do pico de Drawdown configurável.
- v1.28: Remoção de `inp_InitialBalance` (auto-detectado via
  AccountBalance).
- v1.27: TPs Parciais agora usam valores REAIS do deal (DEAL_PROFIT/
  DEAL_PRICE do histórico).
- v1.26: TPs Parciais salvos no CSV (3 linhas por trade).
- v1.24: Lucro de TP1/TP2 contabilizado em tempo real;
  `GetDailyProfit()` inclui `m_partialTPProfit`.
- v1.23: Verificação de Drawdown em tempo real (lucro projetado).
- v1.22: Verificação de Limites em Tempo Real (lucro projetado).

**GUI/Panel.mqh — versões iniciais (v1.23 → v1.00)**
- v1.23 (2026-03-03): Layout COL_VALUE_X 195→150; auto-hide status
  CONFIG; `m_cfg_btnBloq2`; BLOQUEIO 2 — Filtro de Notícias (3 janelas).
- v1.21 (2026-03-01): Fechar Antes do Fim da Sessão na sub-página
  BLOQUEIOS.
- v1.20: Filtro de Horário na sub-página BLOQUEIOS.
- v1.19: Toggles ON/OFF — DrawDown, Loss Streak, Win Streak.
- v1.18: DrawDown movido de BLOQUEIOS → RISCO 2; Streak/DD criados
  incondicionalmente.
- v1.17: Partial TP movido de RISCO 2 → RISCO; BLOQUEIOS expandido com
  radios.
- v1.16: Cycle buttons → CButton[]; sub-página RISCO 2.
- v1.15: Fix clicks (OnEvent chama CAppDialog::OnEvent PRIMEIRO).
- v1.14: REVERT Move; campos fixos + enable/disable visual.
- v1.13: LayoutRisco() dinâmico com Move().
- v1.12: SL Type cycle button; TP Type cycle button.
- v1.11: Fix `ChartRedraw()` nos handlers; encavalamento sub-páginas.
- v1.10: HOT RELOAD aba CONFIG; partição em 5 arquivos.
- v1.09: `MouseProtection()` desabilita CHART_MOUSE_SCROLL.
- v1.08: Proteção de mouse (CHART_DRAG_TRADE_LEVELS).
- v1.07: Seção financeira — Ganhos/Perdas/P/L Total.
- v1.06: Fix troca de abas — `ShowTab()` chama `SetTabVis(tab, true)`
  explicitamente.
- v1.05: Nova aba FILTROS (5 abas); cores ajustadas; fix encavalamento.
- v1.04: Fix — sobrescreve `CreateButtonClose()` em vez de acessar
  `m_button_close`.
- v1.03: Substitui CEdit de valor por CLabel (controle total de cor).
- v1.02: Adiciona `#include` de `Inputs.mqh`.
- v1.01: Autocontido — `#include` das dependências do projeto.
- v1.00: Painel GUI com 4 abas; tema escuro; timer 1.5s; NULL-safe.

---

## KNOWN LIMITATION (documentado em 2026-03)

**Inconsistência: Logger.m_dailyWins/Losses vs Streak**

Quando TP1+TP2 executam E o deal final fecha no prejuízo:
- Streak (`isWin`): usa `totalPositionProfit` → WIN ✅
- Logger UpdateStats: usa `finalDealProfit` → LOSS ❌

Consequências:
1. Win rate no relatório TXT pode ficar errado (cosmético).
2. Após reinício do EA, `LoadDailyStats()` lê o deal final como LOSS e
   reconstrói o streak incorretamente.

O que NÃO é afetado:
- Limites diários (gain/loss): `GetDailyProfit()` correto.
- Streak durante operação normal (sem reinício): correto.

Por que não foi corrigido:
- Cenário muito raro (TP1+TP2 hit + trailing + SL posterior).
- Impacto: streak off-by-1 por 1 trade, autocorrigido logo.
- Custo da correção: mudança no formato CSV (área sensível).
- Risco de regressão > benefício real.

---

## Notas técnicas / Débitos técnicos

**[1] GAP Init/CreatePanel — Parte 025**
`RegisterPanels()` é chamado em `Init()`, mas os controles GUI dos
painéis só são criados em `CreatePanel()`. Atualmente não é bug porque
o timer só ativa após `CreatePanel()` retornar.

**[2] Assimetria de API StrategyBase × FilterBase — Parte 025**
- `CStrategyBase` usa `GetEnabled()` / `SetEnabled()`.
- `CFilterBase` usa `IsEnabled()` / `SetEnabled()`.
Nomes diferentes para o mesmo conceito — herdado das versões anteriores.
