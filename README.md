# EPBot Matrix

Um Expert Advisor (EA) modular e multi-estratégia para MetaTrader 5 (MT5), projetado para oferecer flexibilidade, controle de risco e uma interface gráfica intuitiva para operações automatizadas.

## ✨ Principais recursos

O **EPBot Matrix** foi desenvolvido com uma arquitetura robusta para otimizar a automação de estratégias de trading, incluindo:

-   **Arquitetura Modular**: Separação clara entre `Core` (infraestrutura), `Strategy` (lógica de trading) e `GUI` (interface gráfica).
-   **Multi-Estratégia**: Suporte para execução simultânea ou seletiva de diversas estratégias de trading.
-   **Filtros de Entrada**: Mecanismos para refinar os sinais de entrada, aumentando a qualidade das operações.
-   **Gestão de Risco Avançada**: Ferramentas integradas para controle de stop loss, take profit, trailing stop e breakeven.
-   **Bloqueios Operacionais**: Funcionalidades para evitar operações em condições indesejadas (e.g., horários específicos, notícias, limites de drawdown).
-   **Painel Gráfico (GUI)**: Interface interativa diretamente no gráfico do MT5 para monitoramento e configuração em tempo real.
-   **Hot Reload de Configurações**: Capacidade de aplicar certas alterações de parâmetros sem a necessidade de reiniciar o EA.
-   **Persistência de Configurações**: Salvamento e carregamento de parâmetros para agilizar a configuração.
-   **Resiliência Operacional**: Mecanismos para ressincronização de posições e logging detalhado para diagnóstico.

## 🏗️ Estrutura do projeto

A organização do código reflete a arquitetura modular, facilitando a manutenção e a adição de novas funcionalidades.

Matrix/
├── Core/                 # Módulos de infraestrutura e gestão
│   ├── BlockerDrawdown.mqh
│   ├── BlockerFilters.mqh
│   ├── BlockerLimits.mqh
│   ├── Blockers.mqh
│   ├── ConfigPersistence.mqh
│   ├── Inputs.mqh
│   ├── Logger.mqh
│   ├── RiskManager.mqh
│   └── TradeManager.mqh
├── GUI/                  # Módulos da interface gráfica
│   ├── Panels/
│   ├── FilterPanelBase.mqh
│   ├── Panel.mqh
│   ├── PanelPersistence.mqh
│   ├── PanelTabConfig.mqh
│   ├── PanelTabEstrategias.mqh
│   ├── PanelTabFiltros.mqh
│   ├── PanelTabResultados.mqh
│   ├── PanelTabStatus.mqh
│   ├── PanelUtils.mqh
│   └── StrategyPanelBase.mqh
├── Strategy/             # Módulos de estratégias e sinais
│   ├── Base/
│   ├── Filters/
│   ├── Strategies/
│   └── SignalManager.mqh
├── CLAUDE.md             # Notas de desenvolvimento e histórico
└── EPBot_Matrix.mq5      # Arquivo principal do Expert Advisor

## 🧠 Arquitetura

O **EPBot Matrix** é dividido em três componentes principais:

### Core
Contém os módulos fundamentais para a operação do EA, como o `Logger` para registro de eventos, `RiskManager` para controle de risco, `TradeManager` para execução de ordens e `Blockers` para aplicação de regras de bloqueio. É a base que garante a estabilidade e a conformidade operacional.

### Strategy
Gerencia a lógica de trading. O `SignalManager` coordena as diversas `Strategies` (lógicas de entrada/saída) e `Filters` (condições adicionais para validação de sinais), permitindo a construção de sistemas complexos e adaptáveis.

### GUI
Responsável pela interface gráfica interativa exibida no gráfico do MT5. Inclui o `Panel` principal e suas abas (`PanelTabStatus`, `PanelTabEstrategias`, etc.), que permitem ao usuário monitorar o EA, ajustar parâmetros e visualizar informações em tempo real.

## 📈 Estratégias disponíveis

O **EPBot Matrix** oferece diversas estratégias de trading que podem ser configuradas e combinadas:

-   **MA Cross Strategy**: Baseada no cruzamento de Médias Móveis.
-   **RSI Strategy**: Utiliza o Índice de Força Relativa (RSI) para identificar condições de sobrecompra/sobrevenda.
-   **Bollinger Bands Strategy**: Opera com base nas Bandas de Bollinger para identificar volatilidade e reversões.

## 🛡️ Filtros e controles de risco

Para aumentar a robustez e a segurança das operações, o EA incorpora:

### Filtros de Sinal
-   **Trend Filter**: Filtra sinais com base na direção da tendência predominante.
-   **RSI Filter**: Utiliza o RSI como um filtro adicional para validar sinais.
-   **Bollinger Bands Filter**: Filtra sinais com base na posição do preço em relação às Bandas de Bollinger.

### Controles de Risco
-   **Stop Loss e Take Profit**: Definição de limites de perda e ganho.
-   **Trailing Stop**: Ajuste dinâmico do stop loss para proteger lucros.
-   **Breakeven**: Movimento do stop loss para o ponto de entrada após certo ganho.
-   **Controle de Lote**: Gerenciamento do tamanho das posições.
-   **Bloqueios por Drawdown e Limites Diários**: Prevenção de perdas excessivas.
-   **Bloqueios por Horário e Notícias**: Evita operações em períodos de alta volatilidade ou baixa liquidez.

## 🖥️ Painel gráfico

O painel gráfico é um diferencial do **EPBot Matrix**, proporcionando:

-   **Visualização em Abas**: Organização de informações em abas dedicadas (Status, Resultados, Estratégias, Filtros, Configurações).
-   **Configuração em Tempo Real**: Ajuste de parâmetros e ativação/desativação de funcionalidades diretamente no gráfico.
-   **Feedback Visual**: Indicadores visuais para erros de configuração ou status operacional.
-   **Botão Global de Controle**: Iniciar/pausar o EA com um clique.
-   **Persistência de Estado**: Mantém as configurações do painel mesmo após reiniciar o terminal.

## 🚀 Instalação

Para instalar o **EPBot Matrix** em seu MetaTrader 5:

1.  **Clone o repositório**:
    ```bash
    git clone https://github.com/EPFILHO/Matrix.git
    ```
2.  **Copie os arquivos**:
    Navegue até a pasta `MQL5` do seu terminal MT5 (geralmente em `C:\Users\\AppData\Roaming\MetaQuotes\Terminal\\MQL5`).
    Copie as pastas `Core`, `GUI`, `Strategy` e o arquivo `EPBot_Matrix.mq5` para as respectivas subpastas dentro de `MQL5/Experts/` ou crie uma nova pasta para o projeto.
    Exemplo:
    -   `EPBot_Matrix.mq5` para `MQL5/Experts/Matrix/`
    -   `Core/` para `MQL5/Experts/Matrix/Core/`
    -   `GUI/` para `MQL5/Experts/Matrix/GUI/`
    -   `Strategy/` para `MQL5/Experts/Matrix/Strategy/`
3.  **Compile no MetaEditor**:
    Abra o MetaEditor (Ctrl+D no MT5), localize o arquivo `EPBot_Matrix.mq5` e compile-o (F7). Certifique-se de que não há erros de compilação.
4.  **Anexe ao gráfico**:
    No terminal MT5, abra um gráfico do ativo desejado. Arraste o `EPBot_Matrix` da janela "Navegador" para o gráfico.
5.  **Configure e ative**:
    Na janela de propriedades do EA, revise os parâmetros de entrada e certifique-se de que a opção "Permitir Negociação Algorítmica" esteja marcada. Clique em "OK".

## ⚙️ Como usar

Após a instalação e anexação ao gráfico:

1.  **Ajuste os parâmetros**: Utilize a janela de "Propriedades do Expert Advisor" ou o painel gráfico para configurar as estratégias, filtros e regras de risco desejadas.
2.  **Monitore o painel**: Acompanhe o status, resultados e informações operacionais através do painel gráfico interativo.
3.  **Inicie/Pause**: Use o botão global no painel para iniciar ou pausar a execução do EA conforme necessário.
4.  **Acompanhe os logs**: Verifique a aba "Experts" no terminal MT5 para logs detalhados de operação e diagnóstico.

## 📋 Estado do projeto

O **EPBot Matrix** é um projeto em **desenvolvimento ativo e contínuo**. Ele reflete um esforço constante em aprimorar a automação de trading, com base em feedback e necessidades operacionais reais. Melhorias, correções de bugs e novas funcionalidades são implementadas regularmente para aumentar sua robustez e capacidade.

## ⚠️ Aviso de risco

O trading automatizado em mercados financeiros envolve **riscos significativos**, incluindo a perda total do capital investido. O **EPBot Matrix** é uma ferramenta de automação e não garante lucros.

-   Sempre teste o EA exaustivamente em **contas demo** antes de utilizá-lo em contas reais.
-   Compreenda completamente as estratégias, filtros e configurações de risco antes de operar.
-   Ajuste os parâmetros de risco de acordo com sua tolerância e capital disponível.
-   Acompanhe o EA ativamente, mesmo em modo automatizado.

A responsabilidade pelo uso e pelos resultados obtidos com este Expert Advisor é **exclusivamente do usuário**.

## 🤝 Contribuição

Contribuições são bem-vindas para aprimorar o **EPBot Matrix**. Se você deseja contribuir, por favor:

1.  Faça um fork do repositório.
2.  Crie uma nova branch para sua funcionalidade ou correção (`git checkout -b feature/minha-feature` ou `bugfix/corrige-bug`).
3.  Implemente suas alterações, mantendo a estrutura modular do projeto.
4.  Envie um Pull Request detalhando as mudanças propostas.

## 📄 Licença

[TO BE COMPLETED]
