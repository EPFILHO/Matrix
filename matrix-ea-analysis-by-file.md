# Análise EPBot Matrix v1.59 — Problemas por Arquivo

**Data:** 2026-04-03 | **Total:** 100 problemas (8 Critical, 17 High, 30 Medium, 45 Low)

---

## EPBot_Matrix.mq5 (6 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| L-30 | LOW | ~736-738 | Comentário `KNOWN LIMITATION` desatualizado — já foi corrigido na v1.59, deve ser removido |
| L-31 | LOW | ~1474 | Comentário diz "v1.58" mas a versão é 1.59 |
| L-32 | LOW | ~756, 889, 915, 1155 | `inp_ExitMode` usada diretamente em OnTick em vez de working variable — não reflete hot reload via GUI |
| L-33 | LOW | ~1360 | Fallback de posição no ExecuteTrade usa janela de 5 segundos — pode falhar com latência alta |
| L-34 | LOW | ~626 | `static int lastDay = 0` — restart à meia-noite pode não detectar mudança de dia corretamente |
| L-35 | LOW | ~1467-1471 | OnTimer chama `g_panel.Update()` sem proteção contra exceções |

---

## Core/RiskManager.mqh (19 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| **C-01** | **CRITICAL** | ~1538-1552 | **Trailing Stop nunca ativa para SELL com SL=0** — condição `newSL >= currentSL` com `currentSL == 0` é sempre true. Posições SELL ficam sem proteção. **Correção:** adicionar guard `if(currentSL == 0)` antes do check |
| **C-02** | **CRITICAL** | ~1664-1670 | **Breakeven nunca ativa para SELL com SL=0** — mesmo padrão do C-01. **Correção:** adicionar guard `if(currentSL == 0)` |
| **C-03** | **CRITICAL** | ~1720, 1735 | **Cache ATR usa `_Symbol` em vez de `m_symbol`** — se EA opera em símbolo diferente do gráfico, todos os cálculos ATR podem estar errados. **Correção:** substituir `_Symbol` por `m_symbol` |
| H-01 | HIGH | ~1145-1152 | `SetATRPeriod` não recria handle ATR — após mudar período via GUI, cálculos usam período original. **Correção:** liberar handle antigo, criar novo, resetar cache |
| H-02 | HIGH | ~1806-1852 | Lote cumulativo TP1+TP2 pode exceder lote total — calculados independentemente sem validação de soma. **Correção:** validar `tp1.lotSize + tp2.lotSize <= totalLotSize` |
| H-03 | HIGH | ~746-760 | Validação TP2 > TP1 só funciona para distâncias fixas — quando tipos diferem (ATR vs FIXED), TP2 pode estar mais perto. **Correção:** validar em runtime em `CalculatePartialTPLevels()` |
| M-01 | MEDIUM | ~1583 | Epsilon hardcoded `0.00001` no Trailing — não adequado para todos instrumentos. Usar `SYMBOL_TRADE_TICK_SIZE` |
| M-02 | MEDIUM | ~1227-1228 | Spread compensation pode double-count para SELL — SL para SELL fica mais distante que pretendido |
| M-03 | MEDIUM | ~1296-1297 | TP spread compensation pode ser assimétrica entre BUY e SELL |
| M-04 | MEDIUM | ~1462-1471 | `ValidateSLTP.is_valid` sempre retorna true — campo enganoso, caller nunca sabe se original era inválido |
| M-05 | MEDIUM | ~1747, 1759 | `NormalizePrice/NormalizeStep` guard verifica `== 0` em vez de `<= 0` — valores negativos passam |
| M-06 | MEDIUM | ~1107, 1125 | Cache ATR não invalidada ao recriar handle em `SetSLType/SetTPType` — cache serve valores do handle antigo |
| M-07 | MEDIUM | ~1770-1776 | `GetStopLevel()` força mínimo 1 ponto quando broker retorna 0 — desnecessariamente restritivo |
| M-29 | MEDIUM | — | `SL_RANGE` sem fallback quando `CalculateAverageRange()` retorna 0 — SL fica no preço de entrada |
| M-30 | MEDIUM | ~1806, 1847 | `lotStep` pode ser 0 em `CalculatePartialTPLevels` — divisão por zero causa crash |
| L-01 | LOW | ~1942 | `PrintConfiguration` header diz "v3.14" em vez de "v3.16" |
| L-02 | LOW | — | `PrintConfiguration` incompleta — só imprime Lote e SL, faltam TP/Trailing/BE/Partial |
| L-03 | LOW | ~810, 866 | Comparação direta `!=` em float nos setters de hot reload — logs espúrios por imprecisão de ponto flutuante |
| L-04 | LOW | — | `TP_NONE` não tratado para tipos individuais de partial TP — distância 0 coloca TP no preço de entrada |
| L-05 | LOW | ~458-459 | `SetTrailingActivation/SetBEActivation` não logam mudanças |
| L-06 | LOW | — | Múltiplas chamadas redundantes a `SymbolInfoDouble/SymbolInfoInteger` por tick — falta cache |

---

## Core/TradeManager.mqh (21 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| **C-04** | **CRITICAL** | ~646, 705 | **Variável `openPrice` não declarada em `MonitorPartialTP()`** — deveria ser `m_positions[index].openPrice`. CSV corrompido |
| **C-05** | **CRITICAL** | ~642, 646, 701, 705 | **Chamadas a `m_logger` sem NULL check em `MonitorPartialTP()`** — crash se logger for NULL. **Correção:** envolver em `if(m_logger != NULL)` |
| **C-06** | **CRITICAL** | ~594, 627-706 | **Índice stale após `ExecutePartialClose`** — callbacks podem modificar array `m_positions[]`, tornando index inválido → array out-of-bounds. **Correção:** re-validar index após cada partial close |
| **C-07** | **CRITICAL** | ~605-752 | **TP1+TP2 disparam no mesmo tick** — segunda close usa preço e volume obsoletos. **Correção:** `return;` após TP1 completar |
| H-04 | HIGH | ~791-792 | Lote arredondado pode ser zero ou sub-mínimo em `ExecutePartialClose` — ex: `MathFloor(0.02/0.03)*0.03 = 0.0`. **Correção:** validar `lot >= SYMBOL_VOLUME_MIN` |
| H-05 | HIGH | ~910-916 | `SetMagicNumber` deleta arquivo do magic NOVO em vez do antigo — `DeleteState()` chamada APÓS atualizar `m_magicNumber`. **Correção:** deletar ANTES de atualizar |
| H-06 | HIGH | ~243 | `ResyncExistingPositions` não valida `PositionGetTicket` — ticket 0 cria entrada fantasma. **Correção:** `if(ticket == 0) continue;` |
| M-08 | MEDIUM | ~549 | `HistorySelect` com janela de 300s pode perder deals em desconexões > 5min. Usar `openTime` da posição |
| M-09 | MEDIUM | ~1075-1076 | `SaveState` tem janela de perda de dados — `FileDelete` + `FileMove` não é atômico. **Correção:** rename direto |
| M-10 | MEDIUM | ~1092-1109 | SaveState fallback deleta `.tmp` mesmo quando copy falhou — pode perder ambos os arquivos |
| M-11 | MEDIUM | ~1011-1016 | `ReadValue` retorna trailing whitespace — `StringToTime` pode falhar. Adicionar `StringTrimRight()` |
| M-12 | MEDIUM | ~205-225 | `Init()` sempre retorna true — sem validação de inputs (symbol vazio, slippage negativo, NULL logger) |
| M-13 | MEDIUM | ~853 | `PositionSelectByTicket` em `CleanClosedPositions` altera seleção global de posição |
| M-14 | MEDIUM | ~311-325 | `tp1_lot + tp2_lot` não validado contra `originalLot` em `RegisterPosition` |
| M-28 | MEDIUM | ~1145-1146 | `LoadState` tem O(n²) array growth — `ArrayResize` cresce por 1. Usar terceiro parâmetro de reserva |
| L-07 | LOW | ~394-400 | `GetPositionIndex` busca linear O(n) chamada repetidamente por posição por tick |
| L-08 | LOW | ~328 | `ArrayResize` cresce por 1 em `RegisterPosition` — sem reserva de capacidade |
| L-09 | LOW | ~311-325 | TP lots não validados contra mínimos do broker no registro |
| L-10 | LOW | ~252-275 | Resync com state file ausente perde config de TP silenciosamente |
| L-11 | LOW | ~838 | Error condition logada como `LOG_EVENT` em vez de `LOG_ERROR` |
| L-12 | LOW | ~993-996 | `FileWriteString` retorno não verificado em `WriteKV` |
| L-13 | LOW | ~1218-1222 | `DeleteState` não limpa arquivos `.tmp` órfãos |
| L-14 | LOW | ~880-886 | `Clear()` não persiste estado vazio — state file mantém posições antigas |

---

## Core/Blockers.mqh (6 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| H-07 | HIGH | ~370 | `ActivateDrawdownProtection` chamada com `projectedProfit` incorreto — passa mesmo valor para ambos args em vez de incluir floating P/L |
| H-08 | HIGH | ~597-613 | `SetMagicNumber` não atualiza próprio `m_magicNumber` — delega para submodulos mas esquece de si mesmo |
| M-17 | MEDIUM | ~632-638 | Filtro de direção não trata order types pendentes — `BUY_LIMIT`, `SELL_STOP`, etc. bypassa o filtro |
| L-16 | LOW | ~271-278, 323 | Log de versão desatualizado — header diz v3.26, Init loga v3.25 |
| L-20 | LOW | ~481-505 | `ResetDaily` não reseta estados de transição de filtros |
| L-21 | LOW | ~798-804 | `PrintConfiguration` delega para métodos não implementados (TODO Part 033) — possível erro de compilação |

---

## Core/BlockerDrawdown.mqh (4 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| **C-08** | **CRITICAL** | ~346-349 | **`ShouldCloseByDrawdown` retorna false quando limite atingido — sem retry.** Se primeira tentativa falha, posição fica aberta indefinidamente. **Correção:** retornar true quando `m_drawdownLimitReached` está setado |
| M-15 | MEDIUM | ~569-573 | `UpdatePeakProfit` não verifica `m_drawdownProtectionActive` — pico pode inflar antes da ativação |
| M-18 | MEDIUM | ~578-614 | `SetDrawdownValue(0)` não desativa proteção ativa — trading bloqueado até reset diário |
| M-19 | MEDIUM | ~583-584 | `SetDrawdownValue` não valida porcentagem > 100 via hot reload — drawdown nunca atingido |
| L-15 | LOW | ~268, 309 | `blockReason` formata como porcentagem mesmo para drawdown financeiro ("150.00%" vs "$150.00") |

---

## Core/BlockerFilters.mqh (3 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| M-16 | MEDIUM | ~424-434 | `GetRelevantSession` não lida com sessões cross-midnight (22:00-03:00) — proteção silenciosamente desabilitada |
| L-18 | LOW | ~312-368 | News filter parameters não validados no Init — time filter valida, news filter aceita qualquer valor |
| L-22 | LOW | ~427 | Sessão end minute tratado como ativo (comparação `<=`) — no minuto exato do fim, sessão é "ativa" |

---

## Core/BlockerLimits.mqh (2 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| L-17 | LOW | ~801-819 | `SetDailyLimits` sempre loga mesmo sem mudança — não segue padrão dos outros hot reload methods |
| L-19 | LOW | ~564-565, 614-615 | Streak pause com 0 minutos despausa instantaneamente — comportamento não documentado |

---

## Core/Logger.mqh (2 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| M-26 | MEDIUM | ~399-407 | Throttle array cresce sem limite — por 1 elemento a cada novo contexto, sem cleanup |
| M-27 | MEDIUM | ~459-463 | `GenerateThrottleKey` usa apenas context, ignora message — todas mensagens do mesmo context compartilham throttle |

---

## Strategy/SignalManager.mqh (3 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| H-10 | HIGH | ~154-182 | `GetExitSignal()` não resolve conflitos de prioridade — retorna primeiro encontrado, diferente de `GetSignal()` que resolve via prioridade |
| L-26 | LOW | — | `m_inputConflictMode` capturado em `Initialize()` ao invés de construtor — mudanças pré-Initialize corrompem valor original |
| L-28 | LOW | — | `Deinitialize()` não nulifica ponteiros — potenciais dangling references |

---

## Strategy/Strategies/MACrossStrategy.mqh (4 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| H-11* | HIGH | — | Cold reload não reverte parâmetros quando `Initialize()` falha — componente desabilitado permanentemente |
| M-20* | MEDIUM | — | `m_minDistance` usa `_Point` (points) vs TrendFilter que usa pips — diferença de 10x em brokers 5 dígitos |
| M-24 | MEDIUM | — | E2C bar tracking usa apenas `m_fastTimeframe` para `iTime()` — dessincronizado quando fast/slow usam TF diferentes |
| L-29 | LOW | — | `CheckExitSignal()` chama `UpdateIndicators()` redundantemente quando já chamado para entry |

---

## Strategy/Strategies/RSIStrategy.mqh (3 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| H-11* | HIGH | — | Cold reload não reverte parâmetros quando `Initialize()` falha |
| L-23 | LOW | — | `Setup()` não valida `oversold < overbought` |
| L-27 | LOW | — | Solicita `m_signal_shift + 3` valores de CopyBuffer mas só precisa de `m_signal_shift + 2` |

---

## Strategy/Strategies/BollingerBandsStrategy.mqh (3 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| H-09 | HIGH | ~429 | E2C espera 2 candles vs MACross que espera 1 — inconsistência não documentada para mesmo enum `ENTRY_2ND_CANDLE` |
| H-11* | HIGH | — | Cold reload não reverte parâmetros quando `Initialize()` falha |
| M-23 | MEDIUM | — | E2C trava no primeiro sinal sem reavaliar — sinal pode ter sido invalidado |

---

## Strategy/Filters/TrendFilter.mqh (1 problema)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| H-12 | HIGH | ~348-359, 637-650 | Hot-enable sem handle cria estado inválido — filtro bloqueia TUDO permanentemente. **Correção:** disparar cold reload ao habilitar |

---

## Strategy/Filters/RSIFilter.mqh (4 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| H-11* | HIGH | — | Cold reload não reverte parâmetros quando `Initialize()` falha |
| M-21* | MEDIUM | — | Default shift=0 vs RSIStrategy shift=1 — filtro valida contra barra em formação |
| M-22 | MEDIUM | — | `CheckDirectionFilter()` hardcoda midline=50.0 — ignora parâmetro configurável |
| L-24 | LOW | — | `Setup()` não valida relação entre níveis (`oversold < lower_neutral < upper_neutral < overbought`) |
| L-25 | LOW | — | `GetFilterStatus()` chama `ValidateSignal()` que dispara CopyBuffer — getter com efeito colateral de I/O |

---

## Strategy/Filters/BollingerBandsFilter.mqh (1 problema)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| H-11* | HIGH | — | Cold reload não reverte parâmetros quando `Initialize()` falha |

---

## GUI/PanelPersistence.mqh (1 problema)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| H-13 | HIGH | ~476-561 | `ApplyLoadedConfig` não sincroniza estado dos sub-painéis — config carregada é silenciosamente sobrescrita ao clicar INICIAR |

---

## GUI/PanelTabConfig.mqh (2 problemas)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| H-14 | HIGH | ~1662-2093 | `ApplyConfig` valida e aplica em passo único — falha no meio cria config parcialmente aplicada. **Correção:** two-pass |
| H-15 | HIGH | ~1519-1524, 1554-1557 | Radio buttons resetam valores editados pelo usuário para defaults `inp_*` |

---

## GUI/Panel.mqh (1 problema)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| H-17 | HIGH | ~1447-1458 | `ValidateAndApplyAll` ignora retorno bool dos sub-painéis `Apply()` — falhas silenciosas |

---

## GUI/Panels/RSIStrategyPanel.mqh, RSIFilterPanel.mqh, BollingerBandsFilterPanel.mqh (1 problema compartilhado)

| # | Sev. | Linha(s) | Problema |
|---|------|----------|----------|
| H-16 | HIGH | ~341, ~274, ~320 | `SetEnabled(true)` apaga highlights de erro rosa incondicionalmente — MACrossPanel faz correto, estes não |

---

## GUI — Problemas Menores (10 problemas)

| # | Sev. | Problema |
|---|------|----------|
| L-36 | LOW | `SetEditEnabled` em PanelTabConfig não preserva `CLR_FIELD_ERROR` para todos campos |
| L-37 | LOW | `CycleTF()` percorre todos 21 timeframes mesmo quando ativo não suporta todos |
| L-38 | LOW | `StringToDouble` em edits de preço retorna 0 para string vazia sem aviso |
| L-39 | LOW | Timer de 1500ms pode causar flicker visual se `Update()` for lento |
| L-40 | LOW | `SaveCurrentConfig` chamado em `OnClickDebug` pode ser desnecessário |
| L-41 | LOW | Banner de load config não tem timeout automático |
| L-42 | LOW | Panel height/width são constantes — não se adaptam a resolução de tela |
| L-43 | LOW | Config file não tem versionamento — mudanças de formato podem corromper loads |
| L-44 | LOW | `ChartEvent` sem debounce para cliques rápidos em botões |
| L-45 | LOW | `MouseProtection` é O(widgets) a cada MOUSE_MOVE event |

---

## Problemas Cross-File (2 problemas)

| # | Sev. | Arquivos | Problema |
|---|------|----------|----------|
| M-20 | MEDIUM | MACrossStrategy.mqh vs TrendFilter.mqh | Unidade de distância inconsistente — `_Point` vs pips (10x diferença em 5 dígitos) |
| M-25 | MEDIUM | Todas estratégias e filtros | Até 16+ `CopyBuffer` calls por tick — maioria redundante em ticks intra-barra |

---

## Arquivos Sem Problemas

- `Core/Utils.mqh`
- `Core/Inputs.mqh`
- `Core/ConfigPersistence.mqh`
- `Strategy/Base/StrategyBase.mqh`
- `Strategy/Base/FilterBase.mqh`

---

_*H-11 é um problema compartilhado entre 5 arquivos (MACrossStrategy, RSIStrategy, BollingerBandsStrategy, RSIFilter, BollingerBandsFilter)_
_*M-20 e M-21 são problemas de inconsistência cross-file_
