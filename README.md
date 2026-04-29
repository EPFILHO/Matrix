# 🤖 EPBot Matrix

<div align="center">

![Versão](https://img.shields.io/badge/versão-v1.68-blue?style=for-the-badge)
![Linguagem](https://img.shields.io/badge/linguagem-MQL5-orange?style=for-the-badge)
![Plataforma](https://img.shields.io/badge/plataforma-MetaTrader%205-blueviolet?style=for-the-badge)
![Status](https://img.shields.io/badge/status-Archived-red?style=for-the-badge)

**Expert Advisor multi-estratégia para MetaTrader 5**

> ⚠️ **Projeto encerrado.** O EPBot Matrix foi descontinuado em favor do projeto **Fusion**, que sucede este EA com arquitetura unificada e mais recursos. Este repositório é mantido apenas para referência histórica.

</div>

---

## 📖 Sobre o Projeto

O **EPBot Matrix** é um Expert Advisor (EA) modular e *production-grade* desenvolvido para a plataforma MetaTrader 5. Construído com foco em robustez e flexibilidade, o projeto reúne **múltiplas estratégias de trading**, **gerenciamento de risco multi-camada**, um **dashboard GUI interativo com 5 abas** e suporte a **hot-reload de configurações** — tudo sem necessidade de reiniciar o EA.

A arquitetura modular separa claramente responsabilidades entre estratégias, filtros, gerenciamento de risco e interface gráfica, permitindo manutenção e extensão independentes de cada componente. O EA é totalmente compatível com **backtest e otimização** no Strategy Tester do MetaTrader 5 (modo headless sem GUI).

---

## ✨ Funcionalidades Principais

- 📊 **3 Estratégias de trading**: MA Cross (Cruzamento de Médias Móveis), RSI e Bollinger Bands
- 🔍 **3 Filtros de confirmação**: Filtro de Tendência (MA), Filtro RSI e Filtro Anti-Squeeze (BB)
- 🛡️ **Gerenciamento de risco multi-camada**: Stop Loss fixo/ATR/Range, Take Profit parcial (TP1 e TP2), Trailing Stop e Breakeven automático
- 🚧 **Proteções avançadas**: filtros de horário, janelas de notícias, controle de spread, drawdown, sequências de perdas/ganhos e limites diários
- 🖥️ **Dashboard GUI interativo** com 5 abas e atualização em tempo real
- 💾 **Persistência de configuração** entre reinicializações e sessões
- ⚡ **Hot-reload** de parâmetros via painel sem reiniciar o EA
- 🧪 **Compatível com backtest/otimização** (modo headless automático)

---

## ⚙️ Pré-requisitos

| Requisito | Versão mínima |
|---|---|
| MetaTrader 5 | Build 2800+ |
| Conta de trading | Demo ou real em qualquer corretora MT5 |

---

## 🚀 Instalação

1. **Clone ou baixe** este repositório:
   ```bash
   git clone https://github.com/epfilho/epbot-matrix.git
   ```

2. **Copie o arquivo principal** para a pasta de EAs do MetaTrader 5:
   ```
   EPBot_Matrix.mq5  →  <MetaTrader5>/MQL5/Experts/
   ```

3. **Copie as pastas de módulos** mantendo a estrutura de diretórios:
   ```
   Core/      →  <MetaTrader5>/MQL5/Experts/Core/
   Strategy/  →  <MetaTrader5>/MQL5/Experts/Strategy/
   GUI/       →  <MetaTrader5>/MQL5/Experts/GUI/
   ```

4. **Compile o EA** abrindo o MetaEditor e pressionando `Ctrl+F7` com o arquivo `EPBot_Matrix.mq5` aberto. Verifique se não há erros no log de compilação.

5. **Anexe o EA** ao gráfico desejado no MetaTrader 5 arrastando-o da aba *Navigator* → *Expert Advisors*.

---

## 🏁 Primeiro Uso

Ao iniciar pela primeira vez (ou após uma reinicialização), o EA exibe um **banner de configuração** com duas opções:

- **"Carregar"** — restaura as configurações salvas na sessão anterior (recomendado para continuidade)
- **"Ignorar"** — inicia com os parâmetros padrão definidos nas inputs do EA

Após a escolha, o **painel GUI** aparecerá no canto superior esquerdo do gráfico. Para começar a operar, clique no botão **"INICIAR EA"** na aba principal do painel.

> 💡 **Dica:** configure os parâmetros de risco e estratégia antes de clicar em "INICIAR EA". Você pode ajustá-los a qualquer momento via GUI sem precisar reiniciar.

---

## 📈 Estratégias de Trading

### 📉 7.1 MA Cross — Cruzamento de Médias Móveis

Estratégia clássica baseada no cruzamento de duas médias móveis (rápida e lenta).

| Parâmetro | Descrição |
|---|---|
| MA Rápida / Lenta | Período, método (SMA/EMA/SMMA/LWMA) e preço aplicado configuráveis |
| Timeframe | Timeframe independente do gráfico principal |
| Modos de entrada | `NEXT_CANDLE` (candle seguinte ao cruzamento) ou `2ND_CANDLE` (segunda confirmação) |
| Modos de saída | `FCO` (First Cross Out — fecha ao cruzamento inverso), `VM` (Virar a Mão — inverte a posição) ou `TP/SL` padrão |
| Distância mínima | Filtro de distância mínima entre as MAs para evitar entradas em zonas planas |

---

### 📊 7.2 RSI — Índice de Força Relativa

Estratégia baseada nos níveis de sobrecompra e sobrevenda do RSI.

| Parâmetro | Descrição |
|---|---|
| Níveis | Sobrecompra e sobrevenda configuráveis (padrão: 70/30) |
| Modos | Cruzamento de nível (entra quando RSI cruza o limiar) ou Cruzamento do meio (cruza a linha 50) |
| Timeframe | Timeframe independente, permitindo uso de RSI em tempo gráfico diferente |

---

### 🎯 7.3 Bollinger Bands

Estratégia baseada nas Bandas de Bollinger com três modos de operação distintos:

| Modo | Descrição |
|---|---|
| `FFFD` | **Fechou Fora / Fechou Dentro** — entra quando o preço sai e retorna para dentro da banda |
| `Rebound` | Entrada na reversão ao toque da banda extrema |
| `Breakout` | Entrada no rompimento confirmado da banda |

- **Parâmetros**: período, desvio padrão, preço aplicado e timeframe configuráveis
- **Saída**: via cruzamento da banda do meio (FCO) ou TP/SL padrão

---

## 🔍 Filtros de Confirmação

### 📏 8.1 Filtro de Tendência (MA)

Permite operações apenas no sentido da tendência identificada por uma média móvel configurável.

- **Zona neutra**: define uma distância em pontos ao redor da MA — quando o preço está nessa zona, novas operações são bloqueadas, evitando entradas em mercados laterais próximos à média.

---

### 📉 8.2 Filtro RSI

Complementa as estratégias com confirmação de momentum via RSI. Possui **4 modos de operação**:

| Modo | Comportamento |
|---|---|
| Por zona | Bloqueia compras em sobrecompra e vendas em sobrevenda |
| Direcional | Permite apenas operações no sentido do RSI |
| Zonas customizadas | Intervalo neutro definido pelo usuário |
| Neutro | Bloqueia operações quando RSI está na faixa central |

---

### 🌀 8.3 Filtro Anti-Squeeze (Bollinger Bands)

Bloqueia operações quando a volatilidade do mercado está baixa (squeeze), evitando entradas em períodos de compressão onde os sinais tendem a ser falsos.

| Métrica | Descrição |
|---|---|
| Absoluta | Largura mínima absoluta das bandas em pontos |
| Relativa | Largura das bandas relativa ao preço atual (%) |
| Percentil histórico | Bloqueia se a largura atual está abaixo de um percentil histórico configurável |

---

## 🛡️ Gerenciamento de Risco

### Stop Loss

| Tipo | Descrição |
|---|---|
| `FIXED` | Stop Loss em pontos fixos |
| `ATR` | Stop Loss baseado no ATR (Average True Range) multiplicado por um fator configurável |
| `RANGE` | Stop Loss baseado no range de N candles anteriores |

> Todos os modos suportam **compensação de spread** automática.

---

### Take Profit

| Tipo | Descrição |
|---|---|
| `FIXED` | Take Profit em pontos fixos |
| `ATR` | Take Profit baseado no ATR com fator configurável |
| `NONE` | Sem Take Profit fixo (saída pela estratégia ou trailing) |

---

### Take Profit Parcial (TP1 e TP2)

Permite fechar parcialmente a posição em dois alvos intermediários:

| Parâmetro | Descrição |
|---|---|
| TP1 / TP2 Distância | Distância do ponto de entrada para cada alvo parcial |
| TP1 / TP2 Volume (%) | Percentual do volume original a ser fechado em cada alvo |

---

### Trailing Stop

| Parâmetro | Opções |
|---|---|
| Tipo | `FIXED` (em pontos) ou `ATR` (dinâmico) |
| Ativação | `ALWAYS` / `AFTER_TP1` / `AFTER_TP2` / `NEVER` |

---

### Breakeven

Move automaticamente o Stop Loss para o ponto de entrada (ou com folga configurável) assim que o preço atinge um determinado nível de lucro.

| Parâmetro | Opções |
|---|---|
| Tipo | `FIXED` (em pontos) ou `ATR` (dinâmico) |
| Ativação | `ALWAYS` / `AFTER_TP1` / `AFTER_TP2` / `NEVER` |

---

## 🚧 Proteções e Bloqueadores

O EA possui um sistema de proteções em camadas que bloqueia novas entradas em condições desfavoráveis:

- ⏰ **Filtro de horário** — define a janela de sessão em que o EA pode abrir novas posições
- 🔒 **Fechamento automático** — encerra posições abertas antes do fim da sessão configurada
- 📰 **Janelas de notícias** — 3 janelas de bloqueio configuráveis (minutos antes/depois de notícias de alto impacto)
- 📡 **Filtro de spread** — bloqueia entradas quando o spread atual ultrapassa o máximo configurado
- 📉 **Limites diários** — número máximo de trades, perda máxima diária (R$) e ganho máximo diário (R$)
- 🔢 **Controle de sequência** — máximo de perdas e ganhos consecutivos antes de pausar o EA
- 🛑 **Proteção de drawdown** — bloqueio por drawdown financeiro (R$) ou percentual (%) em relação ao saldo/equity

---

## 🗂️ Estrutura do Projeto

```
EPBot_Matrix/
│
├── EPBot_Matrix.mq5          # Arquivo principal (entry point do EA)
│
├── Core/                     # Módulos core independentes e reutilizáveis
│   ├── Inputs.mqh            # Centralização de todos os parâmetros de entrada
│   ├── Logger.mqh            # Sistema de log, relatórios e diagnóstico
│   ├── Blockers.mqh          # Orquestrador de todas as proteções e bloqueadores
│   ├── RiskManager.mqh       # Cálculo de volumes, SL, TP e risco por operação
│   ├── TradeManager.mqh      # Rastreamento e gestão de posições abertas
│   └── ConfigPersistence.mqh # Persistência de configuração entre reinicializações
│
├── Strategy/                 # Estratégias de trading e filtros de confirmação
│   ├── Base/                 # Classes abstratas (interfaces)
│   │   ├── IStrategy.mqh     # Interface base para estratégias
│   │   └── IFilter.mqh       # Interface base para filtros
│   ├── Strategies/           # Implementações das estratégias
│   │   ├── MACross.mqh       # Estratégia de Cruzamento de Médias Móveis
│   │   ├── RSIStrategy.mqh   # Estratégia baseada no RSI
│   │   └── BBStrategy.mqh    # Estratégia baseada em Bollinger Bands
│   └── Filters/              # Implementações dos filtros
│       ├── TrendFilter.mqh   # Filtro de tendência por MA
│       ├── RSIFilter.mqh     # Filtro de confirmação por RSI
│       └── BBFilter.mqh      # Filtro Anti-Squeeze por Bollinger Bands
│
└── GUI/                      # Dashboard interativo
    ├── Panel.mqh             # Painel principal com gerenciamento das 5 abas
    └── Panels/               # Sub-painéis por contexto
        ├── PanelMain.mqh     # Aba principal (status, controles, métricas)
        ├── PanelStrategy.mqh # Aba de configuração das estratégias
        ├── PanelFilters.mqh  # Aba de configuração dos filtros
        ├── PanelRisk.mqh     # Aba de gerenciamento de risco
        └── PanelProtect.mqh  # Aba de proteções e bloqueadores
```

---

## 📚 Documentação

| Documento | Descrição |
|---|---|
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Decisões arquiteturais, padrões de design e justificativas técnicas |
| [`CHANGELOG.md`](CHANGELOG.md) | Histórico completo de versões e mudanças desde a v1.0 |
| [`GUIA_CONFIG.md`](GUIA_CONFIG.md) | Referência completa de todos os parâmetros de entrada e configuração |

---

## ⚠️ Aviso de Risco

> **IMPORTANTE — Leia antes de utilizar.**
>
> Trading automatizado envolve **risco significativo de perda financeira**. Resultados passados — incluindo backtests e otimizações — **não garantem resultados futuros**. O desempenho em conta demo pode diferir substancialmente do desempenho em conta real devido a diferenças de spread, latência, liquidez e condições de mercado.
>
> Este software é fornecido **"como está"**, sem qualquer garantia de lucro ou desempenho. Ele **não constitui consultoria financeira, recomendação de investimento ou oferta de serviços regulados**. O uso deste EA é de **inteira responsabilidade do usuário**.
>
> Opere apenas com capital que você pode se dar ao luxo de perder. Em caso de dúvida, consulte um profissional financeiro habilitado.

---

## 👤 Créditos e Licença

| Campo | Informação |
|---|---|
| **Autor** | EP Filho |
| **Versão final** | v1.68 |
| **Status** | Projeto pessoal encerrado — descontinuado em favor do projeto Fusion |
| **Desenvolvimento** | Desenvolvido com auxílio do [Claude Code](https://claude.ai/code) (Anthropic) |

---

<div align="center">

*EPBot Matrix — desenvolvido com dedicação por EP Filho.*
*Descontinuado em 2026 em favor do projeto Fusion.*

</div>
