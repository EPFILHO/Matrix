# 📘 Guia de Configuração — EPBot Matrix

> **Referência completa de todos os parâmetros de entrada do EA**
> Versão: **1.68** | Linguagem: **MQL5 (MetaTrader 5)**

---

## Como os parâmetros funcionam

Os parâmetros do EPBot Matrix são definidos na **janela de configuração do EA** ao inseri-lo no gráfico. Após a inicialização:

- Os parâmetros podem ser **alterados em tempo real** via painel GUI (hot-reload) — sem necessidade de remover e reinserir o EA.
- As configurações são **salvas automaticamente** no arquivo:
  ```
  MQL5/Files/Matrix_{symbol}_{magic}.cfg
  ```
- Parâmetros marcados com ✏️ suportam alteração em runtime via painel GUI.

---

## ⚙️ 1. Configurações Gerais

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `MagicNumber` | int | `123456` | Identificador único do EA. Diferencia as ordens deste EA das demais. Pode ser alterado em runtime via GUI ✏️ |
| `ShowDebugLogs` | bool | `false` | Ativa logs detalhados no journal do MetaTrader para diagnóstico |
| `DebugCooldown` | int | `5` | Intervalo mínimo em segundos entre logs repetidos. Evita flood no journal |

---

## 🕐 2. Filtro de Horário

Define a janela de tempo em que o EA está autorizado a abrir novas operações.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableTimeFilter` | bool | `false` | Ativa o filtro de horário ✏️ |
| `StartHour` | int | `9` | Hora de início da sessão de operação (formato 24h) ✏️ |
| `StartMinute` | int | `0` | Minuto de início da sessão ✏️ |
| `EndHour` | int | `17` | Hora de encerramento da sessão ✏️ |
| `EndMinute` | int | `0` | Minuto de encerramento da sessão ✏️ |
| `CloseOnEndTime` | bool | `false` | Se `true`, fecha todas as posições abertas ao atingir o horário de encerramento ✏️ |
| `CloseBeforeSessionEnd` | bool | `false` | Ativa o encerramento antecipado antes do fim da sessão ✏️ |
| `MinutesBeforeEnd` | int | `30` | Quantos minutos antes do `EndHour:EndMinute` o EA deve encerrar posições (requer `CloseBeforeSessionEnd = true`) ✏️ |

---

## 📰 3. Janelas de Volatilidade (Notícias)

Permite bloquear operações durante períodos de alta volatilidade esperada, como divulgação de notícias econômicas. Há suporte para até **3 janelas** independentes.

### Janela 1

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableNewsWindow1` | bool | `false` | Ativa o bloqueio na janela 1 ✏️ |
| `NewsStart1Hour` | int | `8` | Hora de início do bloqueio ✏️ |
| `NewsStart1Minute` | int | `30` | Minuto de início do bloqueio ✏️ |
| `NewsEnd1Hour` | int | `9` | Hora de fim do bloqueio ✏️ |
| `NewsEnd1Minute` | int | `0` | Minuto de fim do bloqueio ✏️ |

### Janela 2

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableNewsWindow2` | bool | `false` | Ativa o bloqueio na janela 2 ✏️ |
| `NewsStart2Hour` | int | `13` | Hora de início do bloqueio ✏️ |
| `NewsStart2Minute` | int | `30` | Minuto de início do bloqueio ✏️ |
| `NewsEnd2Hour` | int | `14` | Hora de fim do bloqueio ✏️ |
| `NewsEnd2Minute` | int | `0` | Minuto de fim do bloqueio ✏️ |

### Janela 3

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableNewsWindow3` | bool | `false` | Ativa o bloqueio na janela 3 ✏️ |
| `NewsStart3Hour` | int | `17` | Hora de início do bloqueio ✏️ |
| `NewsStart3Minute` | int | `0` | Minuto de início do bloqueio ✏️ |
| `NewsEnd3Hour` | int | `17` | Hora de fim do bloqueio ✏️ |
| `NewsEnd3Minute` | int | `30` | Minuto de fim do bloqueio ✏️ |

> **Dica:** Durante uma janela de bloqueio ativa, o EA não abre novas posições, mas **não fecha** as posições já abertas, a menos que outros controles (como `CloseOnEndTime`) determinem o contrário.

---

## 📊 4. Filtro de Spread

Impede a abertura de operações quando o spread do ativo está acima do limite aceitável.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableSpreadFilter` | bool | `false` | Ativa o filtro de spread ✏️ |
| `MaxSpread` | int | `0` | Spread máximo permitido em pontos. `0` = sem limite (desabilitado) ✏️ |

---

## 📅 5. Limites Diários

Controla quantas operações e qual resultado financeiro o EA pode acumular em um único dia.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableDailyLimits` | bool | `false` | Ativa os limites diários ✏️ |
| `MaxDailyTrades` | int | `0` | Número máximo de operações por dia. `0` = sem limite ✏️ |
| `MaxDailyLoss` | double | `0.0` | Perda máxima diária em moeda da conta. `0` = sem limite ✏️ |
| `MaxDailyGain` | double | `0.0` | Ganho máximo diário em moeda da conta. `0` = sem limite ✏️ |
| `ProfitTargetAction` | enum | `STOP_TRADING` | Ação ao atingir `MaxDailyGain`. `STOP_TRADING` = para de operar; `ACTIVATE_DD` = ativa proteção de drawdown ✏️ |

---

## 🔴 6. Controle de Sequência (Streak)

Monitora sequências de ganhos ou perdas consecutivas e aplica pausas ou interrupções automáticas.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableStreakControl` | bool | `false` | Ativa o controle de sequência ✏️ |
| `MaxLossStreak` | int | `3` | Número máximo de perdas consecutivas antes de acionar `LossStreakAction` ✏️ |
| `MaxWinStreak` | int | `5` | Número máximo de ganhos consecutivos antes de acionar `WinStreakAction` ✏️ |
| `LossStreakAction` | enum | `PAUSE_MINUTES` | Ação ao atingir `MaxLossStreak`. `PAUSE_MINUTES` = pausa por `StreakPauseMinutes`; `STOP_DAY` = para pelo restante do dia ✏️ |
| `WinStreakAction` | enum | `PAUSE_MINUTES` | Ação ao atingir `MaxWinStreak`. Mesmas opções do `LossStreakAction` ✏️ |
| `StreakPauseMinutes` | int | `60` | Duração da pausa em minutos (usado quando a ação for `PAUSE_MINUTES`) ✏️ |

---

## 📉 7. Proteção de Drawdown

Encerra a operação do EA quando o drawdown da conta ultrapassa um limite predefinido.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableDrawdown` | bool | `false` | Ativa a proteção de drawdown ✏️ |
| `DrawdownType` | enum | `PERCENT` | Tipo de medição: `FINANCIAL` = valor monetário; `PERCENT` = porcentagem do saldo/equity ✏️ |
| `DrawdownValue` | double | `5.0` | Limite de drawdown. Interpretado conforme `DrawdownType` (ex.: `5.0` = 5%) ✏️ |
| `DrawdownPeakMode` | enum | `REALIZED_ONLY` | Base para o cálculo do pico: `REALIZED_ONLY` = usa apenas o saldo realizado; `INCLUDING_FLOATING` = inclui posições abertas (equity) ✏️ |

---

## 🎯 8. Direção Permitida

Restringe o EA a operar apenas em uma direção do mercado.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `TradeDirection` | enum | `BOTH` | `BUY_ONLY` = apenas compras; `SELL_ONLY` = apenas vendas; `BOTH` = ambas as direções ✏️ |

---

## 💰 9. Gerenciamento de Risco

### 9.1 Configurações Globais

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `ATRPeriod` | int | `14` | Período do indicador ATR usado como referência global para SL, TP e trailing baseados em ATR |
| `Slippage` | int | `10` | Slippage máximo aceito em pontos ao executar ordens |
| `LotSize` | double | `0.01` | Volume padrão das operações em lotes ✏️ |

---

### 9.2 Stop Loss

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `SLType` | enum | `FIXED` | Método de cálculo do Stop Loss: `FIXED` = pontos fixos; `ATR` = ATR × multiplicador; `RANGE` = máxima/mínima do período × multiplicador |
| `SLFixed` | int | `100` | Distância do SL em pontos (usado quando `SLType = FIXED`) |
| `SLATRMultiplier` | double | `1.5` | Multiplicador aplicado ao ATR para definir o SL (usado quando `SLType = ATR`) |
| `SLRangePeriod` | int | `14` | Número de candles para cálculo do range (máxima − mínima) (usado quando `SLType = RANGE`) |
| `SLRangeMultiplier` | double | `1.0` | Multiplicador aplicado ao range calculado |
| `SLCompensateSpread` | bool | `false` | Se `true`, adiciona o spread atual ao SL para garantir cobertura efetiva |

---

### 9.3 Take Profit

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `TPType` | enum | `FIXED` | Método de cálculo do Take Profit: `FIXED` = pontos fixos; `ATR` = ATR × multiplicador; `NONE` = sem TP (gerenciado por trailing ou saída manual) |
| `TPFixed` | int | `150` | Distância do TP em pontos (usado quando `TPType = FIXED`) |
| `TPATRMultiplier` | double | `2.0` | Multiplicador aplicado ao ATR para definir o TP (usado quando `TPType = ATR`) |

---

### 9.4 Take Profit Parcial

Permite realizar parte da posição em alvos intermediários, mantendo o restante aberto.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnablePartialTP` | bool | `false` | Ativa o sistema de saídas parciais ✏️ |
| `TP1Volume` | double | `50.0` | Percentual do lote original a realizar no primeiro alvo (ex.: `50.0` = 50%) ✏️ |
| `TP1Distance` | int | `80` | Distância em pontos do preço de entrada para o primeiro alvo ✏️ |
| `TP2Volume` | double | `30.0` | Percentual do lote original a realizar no segundo alvo ✏️ |
| `TP2Distance` | int | `130` | Distância em pontos do preço de entrada para o segundo alvo ✏️ |

> **Nota:** `TP1Volume` e `TP2Volume` são percentuais do **lote original** da operação. O volume remanescente após o TP2 permanece aberto e é gerenciado pelo TP principal, trailing stop ou saída de estratégia.

---

### 9.5 Trailing Stop

Move o Stop Loss automaticamente conforme o preço avança a favor da posição.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `TrailingActivation` | enum | `ALWAYS` | Quando ativar o trailing: `ALWAYS` = desde a abertura; `AFTER_TP1` = após realizar TP parcial 1; `AFTER_TP2` = após realizar TP parcial 2; `NEVER` = desabilitado |
| `TrailingType` | enum | `FIXED` | Tipo de trailing: `FIXED` = distância fixa em pontos; `ATR` = baseado no ATR |
| `TrailingStart` | int | `50` | Ganho mínimo em pontos antes de o trailing começar a mover o SL (usado quando `TrailingType = FIXED`) |
| `TrailingStep` | int | `10` | Incremento mínimo em pontos para cada atualização do SL (usado quando `TrailingType = FIXED`) |
| `TrailingATRMultiplier` | double | `1.5` | Distância do trailing em múltiplos do ATR (usado quando `TrailingType = ATR`) |
| `TrailingATRStep` | double | `0.5` | Passo mínimo de atualização em múltiplos do ATR (usado quando `TrailingType = ATR`) |

---

### 9.6 Breakeven

Move o Stop Loss para o preço de entrada (ou próximo a ele) após atingir um ganho mínimo.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `BEActivation` | enum | `NEVER` | Quando ativar o breakeven: `ALWAYS` = desde a abertura; `AFTER_TP1` = após TP parcial 1; `AFTER_TP2` = após TP parcial 2; `NEVER` = desabilitado |
| `BEType` | enum | `FIXED` | Tipo de breakeven: `FIXED` = pontos fixos; `ATR` = baseado no ATR |
| `BEDistance` | int | `50` | Ganho em pontos necessário para acionar o breakeven (usado quando `BEType = FIXED`) |
| `BEOffset` | int | `5` | Pontos acima/abaixo do preço de entrada onde o SL será posicionado (lucro mínimo garantido) |
| `BEATRMultiplier` | double | `1.0` | Ganho em múltiplos do ATR para acionar o breakeven (usado quando `BEType = ATR`) |
| `BEATROffset` | double | `0.1` | Offset em múltiplos do ATR para o SL no breakeven |

---

## 📊 10. Gerenciador de Sinais

Define como o EA lida com sinais simultâneos de múltiplas estratégias.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `ConflictMode` | enum | `PRIORITY` | `PRIORITY` = usa o sinal da estratégia com maior prioridade (menor número em `*Priority`); `CANCEL` = cancela a entrada se houver conflito entre estratégias ✏️ |

---

## 📈 11. Estratégia MA Cross

Estratégia baseada no cruzamento de duas Médias Móveis. Compra quando a MA rápida cruza acima da lenta; vende no cruzamento inverso.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableMACross` | bool | `true` | Ativa a estratégia de cruzamento de MAs ✏️ |
| `MACrossPriority` | int | `1` | Prioridade da estratégia no gerenciador de sinais. Menor número = maior precedência ✏️ |
| `FastMAPeriod` | int | `9` | Período da Média Móvel rápida |
| `FastMAMethod` | enum | `EMA` | Método de cálculo da MA rápida: `SMA`, `EMA`, `SMMA`, `LWMA` |
| `FastMAApplied` | enum | `CLOSE` | Preço aplicado à MA rápida: `CLOSE`, `OPEN`, `HIGH`, `LOW`, `MEDIAN`, `TYPICAL`, `WEIGHTED` |
| `FastMATimeframe` | enum | `PERIOD_CURRENT` | Timeframe do indicador da MA rápida. `PERIOD_CURRENT` = mesmo timeframe do gráfico |
| `SlowMAPeriod` | int | `21` | Período da Média Móvel lenta |
| `SlowMAMethod` | enum | `EMA` | Método de cálculo da MA lenta: `SMA`, `EMA`, `SMMA`, `LWMA` |
| `SlowMAApplied` | enum | `CLOSE` | Preço aplicado à MA lenta |
| `SlowMATimeframe` | enum | `PERIOD_CURRENT` | Timeframe do indicador da MA lenta |
| `MACrossMinDistance` | int | `0` | Distância mínima em pontos entre as duas MAs para validar o sinal. `0` = desabilitado (qualquer distância é aceita) |
| `MACrossEntryMode` | enum | `NEXT_CANDLE` | Modo de entrada: `NEXT_CANDLE` = entra na abertura do candle seguinte ao cruzamento; `2ND_CANDLE` = aguarda mais um candle para confirmar |
| `MACrossExitMode` | enum | `FCO` | Modo de saída: `FCO` = fecha ao cruzamento inverso (Fecha Cruzamento Oposto); `VM` = vira mão (fecha e abre na direção oposta); `TP_SL` = aguarda TP ou SL |

---

## 📉 12. Estratégia RSI

Estratégia baseada no Índice de Força Relativa. Opera regiões de sobrecompra e sobrevenda.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableRSI` | bool | `false` | Ativa a estratégia de RSI ✏️ |
| `RSIPriority` | int | `2` | Prioridade no gerenciador de sinais ✏️ |
| `RSIPeriod` | int | `14` | Período de cálculo do RSI |
| `RSIApplied` | enum | `CLOSE` | Preço aplicado ao RSI |
| `RSITimeframe` | enum | `PERIOD_CURRENT` | Timeframe do indicador RSI |
| `RSIOversold` | double | `30.0` | Nível de sobrevenda. Cruzar para cima = sinal de compra |
| `RSIOverbought` | double | `70.0` | Nível de sobrecompra. Cruzar para baixo = sinal de venda |
| `RSISignalMode` | enum | `CROSSOVER` | Modo de sinal: `CROSSOVER` = sinal no cruzamento dos níveis de sobrecompra/sobrevenda; `MIDDLE` = sinal no cruzamento da linha 50 |

---

## 📊 13. Estratégia Bollinger Bands

Estratégia baseada nas Bandas de Bollinger com três modos de operação distintos.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableBB` | bool | `false` | Ativa a estratégia de Bollinger Bands ✏️ |
| `BBPriority` | int | `3` | Prioridade no gerenciador de sinais ✏️ |
| `BBPeriod` | int | `20` | Período das Bandas de Bollinger |
| `BBDeviation` | double | `2.0` | Número de desvios padrão das bandas |
| `BBApplied` | enum | `CLOSE` | Preço aplicado ao cálculo das bandas |
| `BBTimeframe` | enum | `PERIOD_CURRENT` | Timeframe do indicador |
| `BBMode` | enum | `BB_MODE_FFFD` | Modo de operação das Bollinger Bands (ver descrição abaixo) |
| `BBEntryMode` | enum | `NEXT_CANDLE` | Modo de entrada: `NEXT_CANDLE` ou `2ND_CANDLE` |
| `BBExitMode` | enum | `TP_SL` | Modo de saída: `FCO` = retorno à banda média; `VM` = vira mão; `TP_SL` = aguarda TP ou SL |

#### Modos de operação (BBMode)

| Modo | Descrição |
|------|-----------|
| `BB_MODE_FFFD` | **Fechou Fora → Fechou Dentro**: detecta quando o preço fecha além de uma banda e retorna para dentro. Indica reversão. Compra quando fecha fora da banda inferior e volta; vende quando fecha fora da banda superior e volta |
| `BB_MODE_REBOUND` | **Toque + Reversão**: entra quando o candle toca ou ultrapassa a banda e fecha voltando para dentro, confirmando rejeição do nível extremo |
| `BB_MODE_BREAKOUT` | **Rompimento**: entra a favor da tendência quando o preço fecha além de uma banda. Estratégia trend-following — compra no rompimento da banda superior; vende no rompimento da banda inferior |

---

## 🔍 14. Filtro de Tendência

Filtra os sinais das estratégias, permitindo apenas operações alinhadas com a tendência definida por uma Média Móvel.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableTrendFilter` | bool | `false` | Ativa o filtro de tendência ✏️ |
| `TrendMAPeriod` | int | `200` | Período da MA usada para definir a tendência |
| `TrendMAMethod` | enum | `EMA` | Método de cálculo: `SMA`, `EMA`, `SMMA`, `LWMA` |
| `TrendMAApplied` | enum | `CLOSE` | Preço aplicado à MA de tendência |
| `TrendMATimeframe` | enum | `PERIOD_CURRENT` | Timeframe da MA de tendência |
| `TrendMinDistance` | int | `0` | Distância mínima em pontos entre o preço e a MA para confirmar tendência. `0` = desabilitado |

> **Comportamento:** Com o filtro ativo, compras só são permitidas quando o preço está **acima** da MA de tendência, e vendas apenas quando o preço está **abaixo** dela.

---

## 📉 15. Filtro RSI

Filtra entradas com base no estado atual do RSI, evitando operações em regiões desfavoráveis.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableRSIFilter` | bool | `false` | Ativa o filtro RSI ✏️ |
| `RSIFilterPeriod` | int | `14` | Período do RSI usado como filtro |
| `RSIFilterApplied` | enum | `CLOSE` | Preço aplicado ao RSI do filtro |
| `RSIFilterTimeframe` | enum | `PERIOD_CURRENT` | Timeframe do RSI do filtro |
| `RSIFilterMode` | enum | `ZONE` | Modo de filtragem (ver abaixo) |
| `RSIFilterOversold` | double | `30.0` | Nível de sobrevenda para o filtro |
| `RSIFilterOverbought` | double | `70.0` | Nível de sobrecompra para o filtro |
| `RSIFilterNeutralLow` | double | `40.0` | Limite inferior da zona neutra (usado no modo `CUSTOM`) |
| `RSIFilterNeutralHigh` | double | `60.0` | Limite superior da zona neutra (usado no modo `CUSTOM`) |

#### Modos do filtro RSI (RSIFilterMode)

| Modo | Comportamento |
|------|---------------|
| `ZONE` | Bloqueia compras quando RSI está em sobrecompra (`> RSIFilterOverbought`); bloqueia vendas em sobrevenda (`< RSIFilterOversold`) |
| `DIRECTIONAL` | Permite compras apenas quando RSI está acima de 50; permite vendas apenas quando está abaixo de 50 |
| `CUSTOM` | Bloqueia operações quando o RSI está dentro da zona neutra definida por `RSIFilterNeutralLow` e `RSIFilterNeutralHigh` |

---

## 📊 16. Filtro Anti-Squeeze (Bollinger Bands)

Evita operações em períodos de baixa volatilidade (squeeze), onde as bandas estão muito estreitas e o mercado não oferece movimento direcional adequado.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `EnableBBFilter` | bool | `false` | Ativa o filtro anti-squeeze ✏️ |
| `BBFilterPeriod` | int | `20` | Período das Bollinger Bands usadas no filtro |
| `BBFilterDeviation` | double | `2.0` | Desvio padrão das bandas do filtro |
| `BBFilterApplied` | enum | `CLOSE` | Preço aplicado às bandas do filtro |
| `BBFilterTimeframe` | enum | `PERIOD_CURRENT` | Timeframe das bandas do filtro |
| `SqueezeMetric` | enum | `RELATIVE` | Métrica usada para identificar o squeeze (ver abaixo) |
| `SqueezeThreshold` | double | `1.0` | Limiar de squeeze. O EA bloqueia novas entradas quando a métrica calculada fica abaixo deste valor ✏️ |

#### Métricas de squeeze (SqueezeMetric)

| Métrica | Descrição |
|---------|-----------|
| `ABSOLUTE` | Largura das bandas em pontos (`banda superior − banda inferior`). Squeeze quando largura `< SqueezeThreshold` |
| `RELATIVE` | Largura como porcentagem da banda do meio (`largura / média × 100`). Squeeze quando resultado `< SqueezeThreshold` |
| `PERCENTILE` | Compara a largura atual com o histórico de larguras recentes. Squeeze quando a largura atual está abaixo do percentil definido em `SqueezeThreshold` (ex.: `20` = abaixo do percentil 20) |

---

## 🖥️ 17. Painel GUI

Controla a exibição do painel gráfico interativo no gráfico.

| Parâmetro | Tipo | Padrão | Descrição |
|-----------|------|--------|-----------|
| `ShowPanel` | bool | `true` | Exibe o painel GUI interativo no gráfico. O painel permite ajustar parâmetros ✏️ em tempo real sem reiniciar o EA |

---

## 🚀 Fluxo de Configuração Recomendado

Siga este passo a passo para configurar o EPBot Matrix de forma organizada e segura:

1. **Configure o Magic Number** — Atribua um identificador único (`MagicNumber`) para cada instância do EA, especialmente se rodar múltiplos EAs no mesmo terminal ou conta.

2. **Defina os Limites Diários e Proteções** — Configure `EnableDailyLimits`, `MaxDailyLoss`, `MaxDailyGain` e a proteção de drawdown (`EnableDrawdown`) antes de qualquer outra coisa. Esses são seus controles de risco primários.

3. **Configure o controle de sequência** — Ative `EnableStreakControl` e defina `MaxLossStreak` conforme seu plano de risco para evitar drawdowns progressivos em sequências ruins.

4. **Configure o horário de operação** — Use `EnableTimeFilter` para restringir o EA ao período de maior liquidez do ativo e ative as janelas de notícias (`EnableNewsWindow1/2/3`) conforme o calendário econômico relevante.

5. **Escolha e configure as estratégias ativas** — Ative apenas as estratégias que compõem sua lógica operacional (`EnableMACross`, `EnableRSI`, `EnableBB`), configure cada uma e defina a prioridade adequada em `ConflictMode`.

6. **Ative os filtros complementares** — Configure o filtro de tendência (`EnableTrendFilter`), filtro RSI (`EnableRSIFilter`) e filtro anti-squeeze (`EnableBBFilter`) para reduzir operações em condições desfavoráveis.

7. **Configure o gerenciamento de risco (SL/TP)** — Defina `SLType`, `TPType`, `LotSize` e os demais parâmetros de risco. Considere ativar o Trailing Stop e/ou Breakeven para proteger lucros.

8. **Teste em conta demo** — Execute o EA em conta demo por pelo menos 2 semanas antes de migrar para conta real. Monitore o journal (`ShowDebugLogs = true`) durante os primeiros dias para verificar o comportamento.

---

## ✏️ Nota sobre Hot-Reload

Todos os parâmetros marcados com ✏️ neste guia podem ser **alterados em tempo real** diretamente pelo painel GUI do EPBot Matrix, **sem necessidade de remover e reinserir o EA no gráfico**.

As alterações realizadas via painel são:
- Aplicadas imediatamente na próxima verificação de sinal
- Salvas automaticamente no arquivo de configuração `MQL5/Files/Matrix_{symbol}_{magic}.cfg`
- Restauradas automaticamente na próxima vez que o EA for inicializado no mesmo símbolo e magic number

Parâmetros **sem** a marcação ✏️ (como períodos de indicadores, métodos de cálculo e timeframes) exigem reinicialização do EA para que as alterações tenham efeito, pois envolvem a recriação de handles de indicadores internos.

---

*Documentação gerada para EPBot Matrix v1.68 — MQL5 / MetaTrader 5*
