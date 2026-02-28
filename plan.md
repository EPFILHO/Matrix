# Plano de Desenvolvimento — EPBot Matrix GUI (Hot Reload)

## Estado Atual
- **EA**: v1.40 (Parte 023)
- **Panel.mqh**: v1.17 (Parte 023)
- **PanelTabConfig.mqh**: v1.17 (Parte 023)
- **Blockers.mqh**: v3.09 (Parte 023)

---

## Histórico de Partes

### Parte 022 — Hot Reload + Radio Buttons + RISCO 2
**Status: CONCLUÍDO**

- [x] CONFIG aba totalmente redesenhada com campos editáveis (CEdit)
- [x] Helpers CreateLI / CreateLB / CreateHdr / CreateRadioGroup / SetRadioSelection
- [x] SetEditEnabled / SetButtonEnabled (enable/disable visual label+campo)
- [x] 4 sub-páginas: RISCO | RISCO 2 | BLOQUEIOS | OUTROS
- [x] RISCO: Lote, SL Type (radio FIXO|ATR|RANGE), SL valor, ATR Period,
      Range Period, Comp Spread SL, TP Type (radio NENHUM|FIXO|ATR),
      TP valor, Comp Spread TP
- [x] RISCO 2: Trailing ON/OFF + Start/Step, Comp Spread Trail,
      BE ON/OFF + Ativação/Offset, Partial TP + TP1/TP2 dist/pct
- [x] BLOQUEIOS: Max Spread, Direção (radio AMBOS|BUY|SELL),
      Daily Limits (Max Trades/Loss/Gain), Streak (Loss/Win count), Drawdown valor
- [x] OUTROS: Slippage, Conflito Sinais (cycle), Debug ON/OFF, Debug Cooldown
- [x] Botão APLICAR → ApplyConfig() → setters hot-reload
- [x] PopulateConfig() — preenche campos com valores iniciais dos inp_*
- [x] RefreshRiscoState() — enable/disable campos por tipo SL/TP
- [x] RefreshRisco2State() — enable/disable campos Trailing/BE
- [x] Conflito TP ATR vs Partial TP: bloqueio mútuo
- [x] ChartEvent override: intercepta CHARTEVENT_OBJECT_CLICK por nome
- [x] Panel v1.16, EPBot_Matrix.mq5 v1.39

---

### Parte 023 — BLOQUEIOS Expandido + Partial TP → RISCO
**Status: CONCLUÍDO**

- [x] Partial TP movido de RISCO 2 → RISCO (m_c2_bPTP → m_cr_bPTP etc.)
      RefreshRiscoState absorve lógica de conflito e enable/disable dos campos TP1/2
- [x] RISCO 2: apenas Trailing + BE (Partial TP removido)
- [x] BLOQUEIOS — Limites Diários: radio Profit Target Action
      PARAR | ATIVAR DD — ApplyConfig usa m_cur_profitTargetAction (não mais inp_)
- [x] BLOQUEIOS — Sequências: radio Streak Action (PAUSAR | PARAR DIA) por Loss e Win
      + campos Pausa Min (visíveis apenas quando action = PAUSAR)
      RefreshStreakState() gerencia visibilidade dinâmica
- [x] BLOQUEIOS — Drawdown: seção separada com header
      radio DD Type (FINANCEIRO | PERCENTUAL)
      radio DD Peak Mode (SÓ REAL. | C/FLUTUANTE)
      ApplyConfig chama SetDrawdownType() + SetDrawdownPeakMode()
- [x] Blockers v3.09: SetDrawdownType() + SetDrawdownPeakMode() com log HOT_RELOAD
- [x] 5 novos state vars: m_cur_lossStreakAction, m_cur_winStreakAction,
      m_cur_ddType, m_cur_ddPeakMode, m_cur_profitTargetAction
- [x] 6 novos handlers: OnClickLossStreakAction, OnClickWinStreakAction,
      OnClickDDType, OnClickDDPeakMode, OnClickProfitTargetAction, RefreshStreakState
- [x] Panel v1.17, PanelTabConfig v1.17, EPBot_Matrix.mq5 v1.40

---

## Próximas Partes

### FASE 2 — Horários e Filtro de Notícias (Parte 024+)
**Status: PENDENTE**

> **Bloqueador**: Blockers.mqh não possui setters hot-reload para Horários nem News.
> Ambos são configurados apenas via `Init()`. Requer refatoração do Init antes de
> expor na GUI.

#### Sub-tarefas

##### 2a — Setters Hot-Reload para Horários
- [ ] Blockers.mqh: adicionar `SetTradingHours(startH, startM, endH, endM)`
- [ ] Blockers.mqh: adicionar `SetUseTradingHours(bool enable)`
- [ ] GUI: nova sub-página HORÁRIOS (ou expandir BLOQUEIOS)
      Campos: Hora Início, Minuto Início, Hora Fim, Minuto Fim
      Toggle: Usar Horários ON/OFF

##### 2b — Setters Hot-Reload para Notícias
- [ ] Blockers.mqh: `SetNewsFilterEnabled(bool)`, `SetNewsMinutesBefore(int)`,
      `SetNewsMinutesAfter(int)`, `SetNewsImpact(ENUM_NEWS_IMPACT)`
- [ ] GUI: seção NOTICIAS em BLOQUEIOS ou nova sub-página
      Toggle ON/OFF, minutos antes/depois, nível impacto (radio)

##### 2c — Sub-página HORÁRIOS na GUI
- [ ] Panel.mqh: novos membros m_ch_* (Horários sub-page)
- [ ] PanelTabConfig.mqh: CreateTabConfig + SetCfgPageVis + PopulateConfig
- [ ] ApplyConfig: chamar novos setters

---

## Notas de Arquitetura

### Padrão "Parte"
Cada conversa = um número de Parte. Arquivos modificados recebem:
- Header: `Versão X.Y - Claude Parte NNN (Claude Code)`
- `#property version` atualizado
- Entrada no CHANGELOG interno

### Padrão Hot-Reload
Módulos têm dois conjuntos de parâmetros:
- `m_input*` — valores originais (imutáveis após Init)
- `m_*` — valores de trabalho (alterados pelos setters hot-reload)
Setters fazem `if(new == current) return;` + log HOT_RELOAD via Logger.

### Padrão Radio Button (MQL5)
MQL5 não tem radio group nativo horizontal. Solução:
- `CButton[] btns` — array de N botões horizontais
- `CreateRadioGroup()` — cria e posiciona proporcionalmente
- `SetRadioSelection()` — destaca ativo (verde), dim inativos (cinza)
- ChartEvent intercepta por nome: `for(int i=0;i<N;i++) if(sparam == btns[i].Name())`

### Padrão Enable/Disable Visual
- `SetEditEnabled(CLabel&, CEdit&, bool)` — cinza + ReadOnly
- `SetButtonEnabled(CLabel&, CButton&, bool)` — cinza no label + fundo cinza no botão
- `RefreshXxxState()` — função que aplica estado visual completo de uma sub-página
