# Plano: Hot Reload — Edição de Parâmetros via GUI

## Resumo
Transformar a aba CONFIG do painel de **read-only** para **editável**, permitindo
ao usuário alterar parâmetros em tempo real sem reiniciar o EA. Usa os 25 setters
hot-reload que já existem nos módulos (Blockers, RiskManager, TradeManager,
SignalManager, Logger). Botão **APLICAR** para confirmar alterações.

## Escopo: Todos os parâmetros hot-reloadable

### Campos editáveis (CEdit — campo de texto numérico):

**GESTÃO DE RISCO** (7-12 campos, dependendo da configuração):
| # | Label | Tipo | Setter | Condição |
|---|-------|------|--------|----------|
| 1 | Lote | double | SetLotSize() | sempre |
| 2 | SL (Fixo/ATR×/Range×) | int/double | SetFixedSL / SetSLATRMultiplier | sempre (label adapta ao tipo) |
| 3 | TP (Fixo/ATR×) | int/double | SetFixedTP / SetTPATRMultiplier | só se TP != TP_NONE |
| 4 | Trail Start | int/double | SetTrailingParams / SetTrailingATRParams | só se Trailing != NEVER |
| 5 | Trail Step | int/double | (mesmo setter acima) | só se Trailing != NEVER |
| 6 | BE Ativação | int/double | SetBreakevenParams / SetBreakevenATRParams | só se BE != NEVER |
| 7 | BE Offset | int/double | (mesmo setter acima) | só se BE != NEVER |
| 8 | TP1 % | double | SetPartialTP1() | só se PartialTP habilitado |
| 9 | TP1 Dist | int | SetPartialTP1() | só se PartialTP habilitado |
| 10 | TP2 % | double | SetPartialTP2() | só se PartialTP habilitado |
| 11 | TP2 Dist | int | SetPartialTP2() | só se PartialTP habilitado |

**BLOQUEIOS** (2-8 campos):
| # | Label | Tipo | Setter | Condição |
|---|-------|------|--------|----------|
| 12 | Max Spread | int | SetMaxSpread() | sempre |
| 13 | Max Trades | int | SetDailyLimits() | só se DailyLimits ativo |
| 14 | Max Loss $ | double | SetDailyLimits() | só se DailyLimits ativo |
| 15 | Max Gain $ | double | SetDailyLimits() | só se DailyLimits ativo |
| 16 | Loss Streak | int | SetStreakLimits() | só se StreakControl ativo |
| 17 | Win Streak | int | SetStreakLimits() | só se StreakControl ativo |
| 18 | Drawdown | double | SetDrawdownValue() | só se Drawdown ativo |

**OUTROS** (3 campos):
| # | Label | Tipo | Setter | Condição |
|---|-------|------|--------|----------|
| 19 | Slippage | int | SetSlippage() | sempre |
| 20 | Debug Cooldown | int | SetDebugCooldown() | sempre |

### Campos com botão de toggle/cycle (CButton):
| # | Label | Valores | Setter |
|---|-------|---------|--------|
| 21 | Direção | AMBOS → APENAS BUY → APENAS SELL | SetTradeDirection() |
| 22 | Debug Logs | ON / OFF | SetShowDebug() |

### Campos read-only (CLabel — mantidos sem edição):
- Magic Number, Comentário (informativos, não alteráveis em runtime)

### Total: 8-22 campos editáveis (adapta conforme features habilitadas)

---

## Arquitetura Técnica

### Novos includes
```cpp
#include <Controls\Edit.mqh>   // CEdit para campos editáveis
```

### Novos helpers
```
CreateLI(CLabel &lbl, CEdit &inp, ...) — Label + Input (CEdit)
CreateLB(CLabel &lbl, CButton &btn, ...) — Label + Button (cycle/toggle)
```

### Novos membros na classe CEPBotPanel
- ~22 CEdit + ~2 CButton para campos editáveis
- 1 CButton m_btnApply (APLICAR)
- 1 CLabel m_c_status (mensagem de feedback)
- Variáveis de estado: m_curDirection (enum), m_curDebug (bool)

### Fluxo do APLICAR
```
OnEvent() → detecta clique no m_btnApply → ApplyConfig()
  ├─ Lê valores de todos os CEdit (StringToDouble/StringToInteger)
  ├─ Valida (>= 0, numérico)
  ├─ Se inválido: pinta campo de vermelho, mostra erro no m_c_status
  ├─ Se válido: chama setter no módulo correspondente
  ├─ Atualiza m_c_status: "Aplicado!" (verde) por 3 segundos
  └─ Log via Logger: HOT_RELOAD (cada setter já faz isso internamente)
```

---

## Fases de Implementação

### Fase 1: Infraestrutura (Panel.mqh)
- [ ] Adicionar `#include <Controls\Edit.mqh>`
- [ ] Aumentar PANEL_HEIGHT de 540 → 600 (comporta todos os campos)
- [ ] Criar helper `CreateLI()` (Label + CEdit)
- [ ] Criar helper `CreateLB()` (Label + CButton cycle)
- [ ] Declarar todos os novos membros (CEdit, CButton, estado)
- [ ] Declarar novos métodos: ApplyConfig(), OnClickApply(), OnClickDirection(), OnClickDebug()

### Fase 2: Redesign CreateTabConfig()
- [ ] Remover criação antiga dos CLabel config (m_c_eXXX)
- [ ] Seção GERAL: Magic (read-only), Comment (read-only), Lot (CEdit)
- [ ] Seção RISCO: SL, TP, Trailing, BE, PartialTP — campos condicionais
- [ ] Seção BLOQUEIOS: Spread, Direção (button), Daily, Streak, Drawdown — condicionais
- [ ] Seção OUTROS: Slippage, Debug (button), Debug Cooldown
- [ ] Botão APLICAR no final
- [ ] Label de status/feedback

### Fase 3: SetTabVis() para CONFIG
- [ ] Atualizar case TAB_CONFIG para Show/Hide todos os novos controles
- [ ] Manter consistência com as outras abas

### Fase 4: PopulateConfig() → reescrever
- [ ] Preencher CEdit com valores iniciais dos inp_* (formatação numérica)
- [ ] Configurar texto dos botões Direction e Debug
- [ ] Labels adaptam ao tipo (ex: "SL (Fixo):" vs "SL (ATR×):")

### Fase 5: ApplyConfig()
- [ ] Ler cada CEdit → StringToDouble / StringToInteger
- [ ] Validar: >= 0, numérico, lot dentro de limites do símbolo
- [ ] Chamar setters nos módulos (m_riskManager->SetLotSize(), etc.)
- [ ] Para SetDailyLimits: lê 3 campos + passa inp_ProfitTargetAction inalterado
- [ ] Para SetStreakLimits: lê 2 campos + passa ações/pausas inalteradas do inp_*
- [ ] Para SetPartialTP1/TP2: lê 2 campos cada + estado enable do inp_*
- [ ] Feedback visual: m_c_status "Aplicado!" (verde)

### Fase 6: Event wiring
- [ ] OnEvent(): capturar clique do m_btnApply → OnClickApply() → ApplyConfig()
- [ ] OnEvent(): capturar clique m_btnDirection → ciclar enum, atualizar texto
- [ ] OnEvent(): capturar clique m_btnDebug → toggle, atualizar texto

### Fase 7: Testes mentais + Versão + Commit
- [ ] Verificar fluxo completo: init → populate → edit → apply → setter → log
- [ ] Verificar que campos condicionais funcionam (features desabilitadas = ocultos)
- [ ] Verificar que SetTabVis() inclui TODOS os novos controles
- [ ] Verificar destrutor (CAppDialog limpa automaticamente via Add())
- [ ] Panel.mqh versão 1.10
- [ ] EPBot_Matrix.mq5 changelog atualizado
- [ ] Commit + Push

---

## Arquivos Modificados
1. **GUI/Panel.mqh** — mudanças principais (redesign da aba CONFIG)
2. **EPBot_Matrix.mq5** — apenas changelog/versão

## Arquivos NÃO modificados
- Nenhum módulo (Blockers, RiskManager, TradeManager, etc.) — setters já existem!

## Riscos e Mitigações
- **Risco**: Painel não cabe na tela → PANEL_HEIGHT 600px é razoável (MT5 mínimo 600px)
- **Risco**: CEdit + CAppDialog → CEdit funciona com Add() igual ao CLabel
- **Risco**: Valores inválidos → Validação antes de chamar setters
- **Risco**: SetTabVis() fica enorme → Organizar por seções, comentar bem
