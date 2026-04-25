# ARCHITECTURE — EPBot Matrix

Decisões arquiteturais que orientam o EA. Documento vivo: atualize quando
uma decisão mudar; o histórico de versões está no `CHANGELOG.md`.

---

## 1. Estrutura modular

```
EPBot_Matrix.mq5         # entrypoint (OnInit/OnTick/OnDeinit/OnTrade)
Core/                    # núcleo: Logger, Blockers, RiskManager, etc
GUI/                     # painel + sub-painéis por estratégia/filtro
Strategy/                # estratégias e filtros (Base + concretos)
```

- `Core/` é independente de GUI; pode rodar headless (backtest).
- `GUI/` recebe ponteiros para os módulos via `Init()` (DI).
- `Strategy/` define interfaces base (`StrategyBase`, `FilterBase`); todas
  as estratégias e filtros herdam delas e são orquestrados pelo
  `SignalManager`.

## 2. Bloqueio operacional (CBlockers)

Refatorado na Parte 025 em três módulos coesos, mantendo a API pública:

- `BlockerFilters` — TimeFilter, NewsFilter, SpreadFilter
- `BlockerDrawdown` — Drawdown protection
- `BlockerLimits` — Daily limits + Streak control

`CBlockers` é orquestrador. Ordem de avaliação no `CanTrade()`:
**DailyLimits → Streak → demais**. Diagnóstico correto quando dois
bloqueios coincidem.

## 3. Hot reload de configuração

- Toda configuração editável na GUI **deve** ter um setter no módulo que
  pode ser chamado em qualquer momento (`SetX(...)`).
- Setters de parâmetros que alteram handle de indicador (period, TF,
  applied price) usam o padrão **skip if unchanged**: se valor for
  idêntico, retorna sem `Deinitialize+Initialize`. Setters logam apenas
  quando o valor muda.
- Variáveis runtime (`g_magicNumber`, `g_slippage`) substituem leituras
  de `inp_*` em código vivo, porque inputs são read-only.

## 4. Persistência de configuração (.cfg)

- `Core/ConfigPersistence.mqh` salva/carrega `SConfigData` em
  `MQL5/Files/Matrix_{symbol}_{magic}.cfg`.
- Formato `key=value` (legível, forward-compatible).
- Escrita atômica (`.tmp` + `rename`); guard de backtest (`MQL_TESTER`).
- Política por `REASON_*` no `OnDeinit`/`OnInit`:
  - `REASON_PARAMETERS` → deleta config (preset alterado pelo usuário).
  - `REASON_CHARTCHANGE/TEMPLATE/RECOMPILE/ACCOUNT` → auto-carrega
    silenciosamente.
  - `REASON_CLOSE/REMOVE/PROGRAM` → mostra banner Carregar/Ignorar.
- **Persistência por TIPO** (Parte 034): SL/TP/Trailing/BE persistem os
  3 valores (FIXO/ATR/RANGE) por tipo, não só o ativo. Sem isso, o
  usuário perdia edições ao trocar de tipo.
- **Atomicidade do Apply** (Parte 034 H-14): valida todos os campos
  primeiro; se houver QUALQUER erro, retorna sem aplicar nada.

## 5. Reconnect on chart change

`OnDeinit(REASON_CHARTCHANGE)` **não** destrói o painel.
`OnInit` detecta `g_panel != NULL` e chama `ReconnectModules()` que
re-injeta ponteiros novos sem recriar objetos gráficos. Sub-painéis
recebem ponteiros via `SetStrategy/SetFilter` tipados com `dynamic_cast`.

## 6. Trava de Timeframes (Parte 36)

Estratégias e filtros têm timeframe próprio, **independente do gráfico**.
Defaults dos 7 inputs de TF (Fast/Slow/RSI/BB/Trend/RSIFilter/BBFilt) são
`PERIOD_M1`. `PERIOD_CURRENT` foi removido do operacional (Inputs) e da
GUI (`PanelUtils.TFName/CycleTF`). Elimina o risco da estratégia mudar
silenciosamente quando o usuário troca o TF do gráfico.

## 7. Grace period (Parte 36)

Globais `g_graceBarTime` e `g_lastPanelStarted` bloqueiam **novas
entradas** no candle do init/start. Cobre primeira carga,
`REASON_CHARTCHANGE`, `REASON_RECOMPILE` e clique "Iniciar" no painel.
**Não** afeta gerência de posição já aberta (trailing/BE/PartialTP
seguem normal).

## 8. Detecção de fechamento de posição (HistoryProcessor)

Extraído na Parte 36 para `Core/HistoryProcessor.mqh`. Lógica:

1. Detecta fechamento comparando ticket anterior x atual (`lastPositionTicket`
   existia e não há mais posição).
2. **Padrão ouro MQL5**: itera todos os deals da posição e soma
   `DEAL_PROFIT` de TODOS os deals com `DEAL_ENTRY_OUT|OUT_BY` (parciais
   + final). Referência: https://www.mql5.com/en/forum/439334
3. `totalPositionProfit` classifica win/loss; `finalDealProfit` (último
   deal não-Partial) é o que entra no `m_dailyProfit` (sem double-count
   de parciais já contabilizados em tempo real).

## 9. Race condition em ExecuteTrade (Parte 031 v1.58)

Em mercados voláteis (Gold), o broker pode retornar `result.deal=0` e
`result.price=0`. Padrão de robustez:

1. Tentar localizar deal via `result.deal` (caminho normal).
2. Se falhar: retry 5x × 100ms.
3. Se ainda falhar (MÉTODO 1.5): `HistoryOrderSelect` + iteração de
   deals filtrados por `DEAL_ORDER`.
4. `RegisterPosition` usa `POSITION_PRICE_OPEN`/`POSITION_VOLUME` (dados
   reais), nunca `result.price/volume`.

Mesmo padrão aplicado a `ExecutePartialClose` (Parte 031 v1.26
TradeManager).

## 10. Partial TPs e CSV

- TPs parciais salvos como linhas separadas no CSV (3 linhas por trade
  com TP1+TP2: Partial TP1, Partial TP2, deal final).
- `LoadDailyStats()` reconhece linhas "Partial TP" e ressincroniza após
  reinício.
- `Logger.UpdateStats(finalProfit, totalProfit)`: classificação win/loss
  pelo total da posição; acúmulo em `m_dailyProfit` apenas pelo
  finalProfit (parciais somam em tempo real via `AddPartialTPProfit`).

## 11. Filtro de spread otimizado (Parte 033 Issue #27)

Antes: log "SPREAD ALTO/NORMALIZADO" gerado em toda transição, mesmo
sem sinal. Agora: `CanTrade(skipSpread=true)` antes do sinal. Se sinal
detectado (≠ SIGNAL_NONE), `IsSpreadOk()` checa e loga apenas se sinal
real foi bloqueado.

## 12. Comentário de ordem dinâmico (Parte 033 Issue #28)

Cada estratégia implementa `GetShortName()`: "MACross", "RSI", "BB".
`SignalManager.GetLastSignalShortSource()` devolve o nome da estratégia
que emitiu o sinal. `ExecuteTrade` usa esse nome no comment da ordem
("EPBot MACross", "EPBot RSI", "EPBot BB"). `inp_TradeComment` foi
removido.

## 13. Sub-painéis modulares na GUI

`CStrategyPanelBase` e `CFilterPanelBase` definem a interface comum:
`Build()`, `Update()`, `Apply(string &outErr)`, `SetEnabled(bool)`,
`Reload()`. Cada estratégia/filtro tem seu próprio painel em
`GUI/Panels/`. `RegisterPanels()` (factory) povoa arrays dinâmicos;
ChartEvent usa loops genéricos.

**Adicionar uma nova estratégia**: 1 arquivo novo em `Strategy/Strategies/`
+ 1 painel em `GUI/Panels/` + 2 linhas em `RegisterPanels()`.

## 14. Validação por campo na GUI (Parte 030)

- `CLR_FIELD_ERROR` (rosa claro): `MarkFieldError()` pinta CEdit
  inválido.
- `Apply(string &outErr)` retorna nomes de campos inválidos para o
  header do painel.
- `ValidateAndApplyAll()` acumula erros CONFIG + sub-painéis numa
  mensagem só.
- Limites dinâmicos por ativo: `CalcMaxPoints`, `CalcMinSLTP`,
  `CalcSymbolLotLimits`.

## 15. Travas com EA rodando (Parte 029)

Quando EA está em execução (`m_eaStarted=true`), todos os controles GUI
ficam bloqueados (radio groups, toggles, edits). `m_locked` em
sub-painéis impede `Update()` de sobrescrever estado travado. O dispatch
de OnClick em sub-painéis tem guard `m_eaStarted`.

## 16. Botão INICIAR/PAUSAR (Parte 027)

Botão no topo do painel (acima das tabs), sempre visível. Estado
inicial: PAUSADO (verde "INICIAR EA"). Guard no `OnTick` bloqueia
**novas posições** quando pausado, mas **não** afeta gerência de
posições abertas (trailing/BE/PartialTP continuam). Em backtest
(`g_panel==NULL`), guard é bypassed.

## 17. Erros conhecidos / Limitações

- **Streak vs Logger win/loss em TP1+TP2 com SL final**: streak usa
  `totalPositionProfit` (correto); Logger usa `finalDealProfit` (loss
  visual no relatório). Cenário raro; correção exigiria mudar formato
  CSV. Ver KNOWN LIMITATION no `CHANGELOG.md`.
- **Assimetria StrategyBase × FilterBase**: `GetEnabled/SetEnabled` vs
  `IsEnabled/SetEnabled`. Herdado; código atual usa o método correto em
  cada lugar.

---

## Princípios de design (resumo)

1. **DI explícita**: módulos recebem dependências em `Init()`; nunca via
   global lookup.
2. **Hot reload first**: parâmetro editável na GUI tem que ter setter no
   módulo. Setter é idempotente (não-op se valor não mudou).
3. **Atomicidade de Apply**: validar tudo, depois aplicar tudo. Estado
   inconsistente é bug.
4. **Padrão ouro MQL5 para deals**: somar todos os OUT/OUT_BY; nunca
   confiar só no deal final.
5. **Robustez contra broker flaky**: retry com timeout para `result.deal=0`
   e `result.price=0`.
6. **Independência de TF de gráfico**: estratégia tem seu próprio TF.
7. **Persistência forward-compatible**: `key=value` em texto; chaves
   novas têm fallback (retrocompat).
