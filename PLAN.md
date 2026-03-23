# PLANO: Persistência + Hot-Reload + Controle de Estado do EA (Parte 027)

## Contexto
O hot-reload do Magic Number (e outros campos) via painel GUI tem múltiplos furos:
módulos não atualizados, campos não persistidos, estados stale, e riscos de
comportamento perigoso (drawdown não protege, streaks errados, etc.).

Além disso, o EA permite edição de parâmetros enquanto está rodando, criando
risco de inconsistência e operações órfãs. Este plano implementa um modelo
de estado robusto:

### Modelo de Estado do EA
```
┌─────────────────────────────────────────────────────────────┐
│  PAUSADO (sem posições abertas)                             │
│  → Todos os controles HABILITADOS (edição livre)            │
│  → 3 botões visíveis:                                       │
│    [▶ INICIAR]  [💾 SALVAR]  [✖ CANCELAR]                  │
│                                                             │
│  INICIAR: valida tudo → aplica → salva .cfg → inicia       │
│  SALVAR:  valida tudo → aplica → salva .cfg (sem iniciar)  │
│  CANCELAR: recarrega último .cfg salvo → reverte edits     │
├─────────────────────────────────────────────────────────────┤
│  RODANDO                                                    │
│  → Todos os controles DESABILITADOS (read-only)             │
│  → Apenas 1 botão visível:                                  │
│    [⏸ PAUSAR EA]                                            │
│  → SALVAR e CANCELAR ocultos/desabilitados (nada a editar)  │
│  → Ao clicar PAUSAR:                                        │
│    - Se há posições abertas → BLOQUEIA com mensagem:        │
│      "Feche as posições antes de pausar"                    │
│    - Se não há posições → pausa e libera controles          │
├─────────────────────────────────────────────────────────────┤
│  PAUSADO (com posições abertas) — estado transitório        │
│  → NÃO DEVE OCORRER (pausar é bloqueado com posições)       │
│  → Se ocorrer (edge case): controles DESABILITADOS          │
└─────────────────────────────────────────────────────────────┘
```

Este plano corrige TUDO de uma vez, organizado em etapas lógicas.

---

## ETAPA 1: SConfigData — Adicionar campos faltantes
**Arquivo:** `Core/ConfigPersistence.mqh` (struct SConfigData, ~linha 44)

Adicionar ao struct:
```cpp
// ── OUTROS (novos) ──
int               magicNumber;         // Hot-reload magic
string            tradeComment;        // Hot-reload comment

// ── RISCO: Tipos Trailing/BE ──
ENUM_TRAILING_TYPE trailingType;       // TRAILING_FIXED ou TRAILING_ATR
ENUM_BE_TYPE       beType;             // BE_FIXED ou BE_ATR
```

**Justificativa:**
- `magicNumber` e `tradeComment`: permitem persistir alterações feitas via GUI
- `trailingType` e `beType`: sem eles, ao carregar config o sistema usa `inp_TrailingType`
  (do .set) e pode interpretar 50pts fixos como 50x ATR — catastrófico

**Nota:** `m_eaStarted` NÃO será persistido (decisão de segurança: EA sempre
inicia pausado após restart, forçando o usuário a confirmar).

---

## ETAPA 2: ConfigPersistence Save/Load — Novos campos + validação
**Arquivo:** `Core/ConfigPersistence.mqh`

### Save() (~linha 298):
Adicionar WriteKV para os 4 novos campos na seção OUTROS:
```
WriteKV(h, "MagicNumber",   IntegerToString(data.magicNumber));
WriteKV(h, "TradeComment",  data.tradeComment);
WriteKV(h, "TrailingType",  IntegerToString((int)data.trailingType));
WriteKV(h, "BEType",        IntegerToString((int)data.beType));
```

### Load() (~linha 530):
Adicionar parsing para os 4 novos campos:
```
if(key == "MagicNumber")   data.magicNumber   = (int)StringToInteger(val);
if(key == "TradeComment")  data.tradeComment  = val;
if(key == "TrailingType")  data.trailingType  = (ENUM_TRAILING_TYPE)StringToInteger(val);
if(key == "BEType")        data.beType        = (ENUM_BE_TYPE)StringToInteger(val);
```

### Validação no Load():
Adicionar bloco de validação de enums APÓS o loop de parsing:
```cpp
// Validação de enums (proteção contra .cfg corrompido)
if(data.slType < SL_FIXED || data.slType > SL_RANGE)
   data.slType = SL_FIXED;
if(data.tpType < TP_FIXED || data.tpType > TP_ATR)
   data.tpType = TP_FIXED;
if(data.trailingType < TRAILING_FIXED || data.trailingType > TRAILING_ATR)
   data.trailingType = TRAILING_FIXED;
if(data.beType < BE_FIXED || data.beType > BE_ATR)
   data.beType = BE_FIXED;
if(data.tradeDirection < TRADE_BUY || data.tradeDirection > TRADE_BOTH)
   data.tradeDirection = TRADE_BOTH;
```

---

## ETAPA 3: CollectConfigData — Coletar novos campos + fix double-assignment
**Arquivo:** `GUI/PanelPersistence.mqh` (CollectConfigData, ~linha 52)

### 3a. Adicionar coleta dos novos campos:
```cpp
data.magicNumber   = m_magicNumber;
data.tradeComment  = m_co_iComm.Text();
data.trailingType  = inp_TrailingType;
data.beType        = inp_BEType;
```

### 3b. Fix double-assignment SL/TP/Trailing/BE:
Substituir a coleta "cega" (que lê o mesmo CEdit 3x com casts diferentes) por
coleta condicional baseada no tipo ativo:

**SL (linhas ~64-66):**
```cpp
data.slType = m_cur_slType;
if(m_cur_slType == SL_FIXED)
   data.fixedSL = (int)StringToInteger(m_cr_iSL.Text());
else if(m_cur_slType == SL_ATR)
   data.slATRMultiplier = StringToDouble(m_cr_iSL.Text());
else // SL_RANGE
   data.rangeMultiplier = StringToDouble(m_cr_iSL.Text());
```

**TP (linhas ~69-70):**
```cpp
data.tpType = m_cur_tpType;
if(m_cur_tpType == TP_FIXED)
   data.fixedTP = (int)StringToInteger(m_cr_iTP.Text());
else
   data.tpATRMultiplier = StringToDouble(m_cr_iTP.Text());
```

**Trailing (linhas ~77-80):**
```cpp
if(inp_TrailingType == TRAILING_FIXED) {
   data.trailStartFixed = (int)StringToInteger(m_c2_iTrlSt.Text());
   data.trailStepFixed  = (int)StringToInteger(m_c2_iTrlSp.Text());
} else {
   data.trailStartATR = StringToDouble(m_c2_iTrlSt.Text());
   data.trailStepATR  = StringToDouble(m_c2_iTrlSp.Text());
}
```

**BE (linhas ~85-88):**
```cpp
if(inp_BEType == BE_FIXED) {
   data.beActivationFixed = (int)StringToInteger(m_c2_iBEVal.Text());
   data.beOffsetFixed     = (int)StringToInteger(m_c2_iBEOff.Text());
} else {
   data.beActivationATR = StringToDouble(m_c2_iBEVal.Text());
   data.beOffsetATR     = StringToDouble(m_c2_iBEOff.Text());
}
```

---

## ETAPA 4: ApplyLoadedConfig — Usar tipos salvos + aplicar novos campos
**Arquivo:** `GUI/PanelPersistence.mqh` (ApplyLoadedConfig, ~linha 256)

### 4a. Trailing/BE — usar tipo do config salvo (não do input):
Substituir:
```cpp
if(inp_TrailingType == TRAILING_FIXED)   // ERRADO: usa input atual
```
Por:
```cpp
if(data.trailingType == TRAILING_FIXED)  // CORRETO: usa tipo salvo
```
Idem para `inp_BEType` → `data.beType`.

### 4b. Magic Number e Trade Comment — aplicar ao carregar:
Após aplicar os outros campos:
```cpp
// Magic Number (se salvo e válido)
if(data.magicNumber > 0)
{
   m_co_iMagic.Text(IntegerToString(data.magicNumber));
   if(data.magicNumber != m_magicNumber)
      ApplyMagicNumberChange(data.magicNumber);  // Método novo (ver Etapa 6)
}

// Trade Comment
if(data.tradeComment != "")
{
   m_co_iComm.Text(data.tradeComment);
   g_tradeComment = data.tradeComment;
}
```

---

## ETAPA 5: Logger — Método ReloadForMagic()
**Arquivo:** `Core/Logger.mqh`

Criar novo método público:
```cpp
void CLogger::ReloadForMagic(int newMagic)
{
   // 1. Salvar relatório do magic atual (se teve trades)
   if(m_dailyTrades > 0)
      SaveDailyReport();

   // 2. Atualizar magic
   int oldMagic = m_magicNumber;
   m_magicNumber = newMagic;

   // 3. Recalcular nomes dos arquivos CSV/TXT
   MqlDateTime dt;
   TimeToStruct(GetReliableDate(), dt);
   m_csvFileName = StringFormat("EPBot_Matrix_TradeLog_%s_M%d_%d.csv",
                                 m_symbol, m_magicNumber, dt.year);
   m_txtFileName = StringFormat("EPBot_Matrix_DailySummary_%s_M%d_%02d%02d%04d.txt",
                                 m_symbol, m_magicNumber, dt.day, dt.mon, dt.year);

   // 4. Reconstruir stats do novo magic (LoadDailyStats faz reset + leitura)
   LoadDailyStats();

   LogInfo(StringFormat("Magic reload: %d → %d | Stats: %d trades, $%.2f",
           oldMagic, newMagic, m_dailyTrades, GetDailyProfit()));
}
```

**Efeito:** Se o novo magic já operou hoje, as stats voltam. Se nunca operou,
fica zerado. Stats do magic antigo ficam intactas no CSV antigo.

---

## ETAPA 6: Hot-Reload centralizado — ApplyMagicNumberChange()
**Arquivo:** `GUI/PanelTabConfig.mqh` (ou Panel.mqh)

Criar método que orquestra a mudança de magic em TODOS os módulos na ordem correta:

```cpp
void CEPBotPanel::ApplyMagicNumberChange(int newMagic)
{
   int oldMagic = m_magicNumber;
   if(newMagic == oldMagic) return;

   // 1. Atualizar painel (fix: m_magicNumber nunca era atualizado)
   m_magicNumber = newMagic;

   // 2. Atualizar global
   g_magicNumber = newMagic;

   // 3. Logger PRIMEIRO (precisa estar pronto antes dos blockers reconstruírem streaks)
   if(m_logger != NULL)
      m_logger.ReloadForMagic(newMagic);

   // 4. TradeManager: atualizar magic + limpar positions + resync
   m_tradeManager.SetMagicNumber(newMagic);

   // 5. Blockers: TODOS os submódulos (filters + drawdown + reconstruct streaks)
   if(m_blockers != NULL)
      m_blockers.SetMagicNumber(newMagic);

   // 6. Persistência: salvar no arquivo do NOVO magic
   SaveCurrentConfig();
}
```

**Substituir** o bloco atual do hot-reload (PanelTabConfig.mqh:1867-1872) por:
```cpp
int magic = (int)StringToInteger(m_co_iMagic.Text());
if(magic > 0)
   ApplyMagicNumberChange(magic);
else
   errors++;
```

**Nota:** O SaveCurrentConfig() no final do ApplyMagicNumberChange() agora já
usa m_magicNumber atualizado, então o .cfg é salvo com o nome do NOVO magic.

---

## ETAPA 7: BlockerDrawdown — Adicionar SetMagicNumber()
**Arquivo:** `Core/BlockerDrawdown.mqh`

Adicionar método público:
```cpp
void CBlockerDrawdown::SetMagicNumber(int newMagic)
{
   m_magicNumber = newMagic;

   // Resetar estado de drawdown (peak calculado com magic antigo é inválido)
   m_dailyPeakProfit          = 0.0;
   m_drawdownProtectionActive = false;
   m_drawdownLimitReached     = false;
   m_drawdownActivationTime   = 0;
}
```

---

## ETAPA 8: Blockers facade — Expandir SetMagicNumber() + ReconstructStreaks()
**Arquivo:** `Core/Blockers.mqh` (SetMagicNumber, ~linha 634)

Expandir para incluir todos os submódulos:
```cpp
void CBlockers::SetMagicNumber(int newMagic)
{
   m_filters.SetMagicNumber(newMagic);
   m_drawdown.SetMagicNumber(newMagic);   // NOVO: reseta peak/estado
   m_limits.ReconstructStreakFromHistory(); // NOVO: reconstrói streaks do novo Logger
}
```

---

## ETAPA 9: BlockerFilters — Limpar caches de transição
**Arquivo:** `Core/BlockerFilters.mqh` (SetMagicNumber, ~linha 795)

Expandir o SetMagicNumber existente:
```cpp
void CBlockerFilters::SetMagicNumber(int newMagic)
{
   m_magicNumber = newMagic;

   // Limpar caches de transição (tickets do magic antigo são inválidos)
   m_sCloseOnEndLastTicket         = 0;
   m_sCloseBeforeSessionLastTicket = 0;
}
```

---

## ETAPA 10: TradeManager — Melhorar SetMagicNumber()
**Arquivo:** `Core/TradeManager.mqh` (SetMagicNumber, ~linha 916)

Expandir para limpar state e resync:
```cpp
void CTradeManager::SetMagicNumber(int newMagic)
{
   int oldValue = m_magicNumber;
   if(oldValue == newMagic) return;

   m_magicNumber = newMagic;

   // Limpar posições registradas (pertencem ao magic antigo)
   ArrayResize(m_positions, 0);

   // Deletar state file do magic antigo
   DeleteState();

   // Re-sincronizar posições abertas do novo magic (se houver)
   ResyncExistingPositions();

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "Magic Number: " + IntegerToString(oldValue) + " → " + IntegerToString(newMagic)
         + " | Posições resincronizadas");
}
```

---

## ETAPA 11: Changelogs
Atualizar headers de versão nos arquivos modificados:

| Arquivo | Mudança principal | Parte |
|---------|-------------------|-------|
| ConfigPersistence.mqh | +4 campos SConfigData, validação enums | 027 |
| PanelPersistence.mqh | Collect/Apply novos campos, fix double-assign | 027 |
| PanelTabConfig.mqh | ApplyMagicNumberChange(), hot-reload centralizado | 027 |
| Logger.mqh | ReloadForMagic() | 027 |
| BlockerDrawdown.mqh | SetMagicNumber() com reset de estado | 027 |
| BlockerFilters.mqh | SetMagicNumber() limpa caches transição | 027 |
| Blockers.mqh | SetMagicNumber() completo + ReconstructStreaks() | 027 |
| TradeManager.mqh | SetMagicNumber() com cleanup + resync | 027 |

---

## ETAPA 12: Remover botões APLICAR individuais dos sub-painéis
**Arquivos:** `GUI/Panels/MACrossPanel.mqh`, `RSIStrategyPanel.mqh`,
`BollingerBandsPanel.mqh`, `TrendFilterPanel.mqh`, `RSIFilterPanel.mqh`,
`BollingerBandsFilterPanel.mqh`

Em cada um dos 6 sub-painéis:

### 12a. Remover criação do botão APLICAR:
Remover o bloco `m_btnApply.Create(...)` + `m_btnApply.Text("APLICAR ...")` +
`parent.AddControl(m_btnApply)` do método `Create()`.

### 12b. Remover handler de click:
Remover a verificação `if(name == m_btnApply.Name())` do `OnEvent()`.

### 12c. Manter o método `_OnApply()`:
O método `_OnApply()` (validação + aplicação nos módulos) continua existindo,
mas agora será chamado pelo INICIAR centralizado (Etapa 14), não pelo botão.
Remover a chamada `m_parent.SaveCurrentConfig()` de dentro do `_OnApply()`
(o save será feito uma única vez pelo INICIAR, após tudo aplicado).

### 12d. Tornar `_OnApply()` público:
Mudar de private para public para que o painel principal possa chamá-lo.
Retornar `bool` (true=sucesso, false=erro de validação):
```cpp
public:
   bool  Apply(void);   // antigo _OnApply(), agora retorna sucesso/erro
```

---

## ETAPA 13: SetAllControlsEnabled() — Travar/liberar controles
**Arquivo:** `GUI/PanelTabConfig.mqh` (novo método) + `GUI/Panels/*.mqh`

### 13a. Método no painel principal:
```cpp
void CEPBotPanel::SetAllControlsEnabled(bool enable)
{
   // ── CONFIG: RISCO ──
   SetEditEnabled(m_cr_lLot, m_cr_iLot, enable);
   SetEditEnabled(m_cr_lSL,  m_cr_iSL,  enable);
   SetEditEnabled(m_cr_lTP,  m_cr_iTP,  enable);
   SetEditEnabled(m_cr_lATRp, m_cr_iATRp, enable);
   SetEditEnabled(m_cr_lRngP, m_cr_iRngP, enable);
   SetEditEnabled(m_cr_lTP1p, m_cr_iTP1p, enable);
   SetEditEnabled(m_cr_lTP1d, m_cr_iTP1d, enable);
   SetEditEnabled(m_cr_lTP2p, m_cr_iTP2p, enable);
   SetEditEnabled(m_cr_lTP2d, m_cr_iTP2d, enable);
   // radio buttons SL/TP type, toggles PTP, CompSpread...
   // (usar SetButtonEnabled para cada toggle/radio)

   // ── CONFIG: RISCO 2 ──
   SetEditEnabled(m_c2_lTrlSt, m_c2_iTrlSt, enable);
   SetEditEnabled(m_c2_lTrlSp, m_c2_iTrlSp, enable);
   SetEditEnabled(m_c2_lBEVal, m_c2_iBEVal, enable);
   SetEditEnabled(m_c2_lBEOff, m_c2_iBEOff, enable);
   SetEditEnabled(m_c2_lDLTrd, m_c2_iDLTrd, enable);
   SetEditEnabled(m_c2_lDLLoss, m_c2_iDLLoss, enable);
   SetEditEnabled(m_c2_lDLGain, m_c2_iDLGain, enable);
   SetEditEnabled(m_c2_lDD, m_c2_iDD, enable);
   // toggles: Trailing, BE, DailyLimits, DD, radios DDType/DDPeak/PTA

   // ── CONFIG: BLOQUEIOS ──
   SetEditEnabled(m_cb_lSpr, m_cb_iSpr, enable);
   // streaks, time filter, CBS edits + toggles...

   // ── CONFIG: BLOQ2 (NEWS) ──
   // 3 janelas de notícias: toggles + edits H/M

   // ── CONFIG: OUTROS ──
   SetEditEnabled(m_co_lMagic, m_co_iMagic, enable);
   SetEditEnabled(m_co_lComm, m_co_iComm, enable);
   SetEditEnabled(m_co_lSlip, m_co_iSlip, enable);
   SetEditEnabled(m_co_lDbgCd, m_co_iDbgCd, enable);
   // toggles debug, conflict

   // ── BOTÃO APLICAR CONFIG (removido? ou desabilitado) ──
   m_cfg_btnApply.ColorBackground(enable ? C'30,120,70' : C'80,80,80');

   // ── SUB-PAINÉIS: Estratégias + Filtros ──
   for(int i = 0; i < m_stratPanelCount; i++)
      m_stratPanels[i].SetEnabled(enable);
   for(int i = 0; i < m_filtPanelCount; i++)
      m_filtPanels[i].SetEnabled(enable);

   ChartRedraw();
}
```

### 13b. Método SetEnabled() nos sub-painéis (base class):
Cada sub-painel precisa de um `SetEnabled(bool enable)` que desabilita/habilita
seus CEdits e CButtons internos. Implementar na classe base `CStrategyPanelBase`
ou em cada sub-painel individualmente.

```cpp
// Em CStrategyPanelBase ou em cada panel:
virtual void SetEnabled(bool enable);
```

Cada sub-painel implementa desabilitando seus próprios campos:
- CEdits: `ReadOnly(!enable)` + cor de fundo cinza
- CButtons (toggles/radios): cor esmaecida + ignorar clicks

### 13c. Sobre o botão APLICAR CONFIG principal:
O botão APLICAR da aba CONFIG pode ser **mantido** como alternativa rápida
para testar configs sem iniciar o EA (validar e aplicar sem iniciar trading).
Quando o EA está rodando, fica desabilitado (cinza).

---

## ETAPA 14: 3 Botões (INICIAR / SALVAR / CANCELAR) + checar posições
**Arquivo:** `GUI/Panel.mqh` ou `GUI/PanelTabConfig.mqh`

### 14a. Criar os 3 botões (substituem o botão único INICIAR/PAUSAR):
```cpp
CButton  m_btnStart;     // ▶ INICIAR EA  /  ⏸ PAUSAR EA (toggle)
CButton  m_btnSave;      // 💾 SALVAR
CButton  m_btnCancel;    // ✖ CANCELAR
```

**Layout (EA pausado):** 3 botões lado a lado na área de controle
**Layout (EA rodando):** Só PAUSAR visível; SALVAR e CANCELAR ocultos/desabilitados

### 14b. OnClickStart (INICIAR / PAUSAR):
```cpp
void CEPBotPanel::OnClickStart(void)
{
   m_btnStart.Pressed(false);

   // ═══ PAUSAR (EA rodando → quer pausar) ═══
   if(m_eaStarted)
   {
      int openPos = CountOpenPositions(m_magicNumber);
      if(openPos > 0)
      {
         ShowStatus("Feche " + IntegerToString(openPos)
                    + " posição(ões) antes de pausar", CLR_NEGATIVE);
         return;
      }
      SetStarted(false);
      SetAllControlsEnabled(true);
      ShowSaveCancelButtons(true);   // Mostrar SALVAR + CANCELAR
      return;
   }

   // ═══ INICIAR (EA pausado → quer iniciar) ═══
   if(!ValidateAndApplyAll())        // Valida + aplica config + estratégias + filtros
      return;                        // Erros → não inicia

   SaveCurrentConfig();
   SetStarted(true);
   SetAllControlsEnabled(false);
   ShowSaveCancelButtons(false);     // Ocultar SALVAR + CANCELAR
}
```

### 14c. OnClickSave (SALVAR):
```cpp
void CEPBotPanel::OnClickSave(void)
{
   m_btnSave.Pressed(false);

   if(!ValidateAndApplyAll())
      return;

   SaveCurrentConfig();
   ShowStatus("Config salva com sucesso!", CLR_POSITIVE);
}
```

### 14d. OnClickCancel (CANCELAR):
```cpp
void CEPBotPanel::OnClickCancel(void)
{
   m_btnCancel.Pressed(false);

   // Recarregar último .cfg salvo (reverte todas as edições)
   if(!LoadCurrentConfig())
   {
      ShowStatus("Nenhuma config salva encontrada", CLR_NEGATIVE);
      return;
   }

   // ApplyLoadedConfig() preenche todos os CEdits/botões com valores do .cfg
   ApplyLoadedConfig(m_lastLoadedConfig);
   ShowStatus("Config restaurada do último save", CLR_POSITIVE);
}
```

### 14e. ValidateAndApplyAll() — Método compartilhado:
```cpp
bool CEPBotPanel::ValidateAndApplyAll(void)
{
   // 1. CONFIG geral
   if(!ApplyConfig())    // Refatorado para retornar bool
      return false;

   // 2. Estratégias ativas
   bool hasErrors = false;
   for(int i = 0; i < m_stratPanelCount; i++)
      if(!m_stratPanels[i].Apply())
         hasErrors = true;

   // 3. Filtros ativos
   for(int i = 0; i < m_filtPanelCount; i++)
      if(!m_filtPanels[i].Apply())
         hasErrors = true;

   if(hasErrors)
   {
      ShowStatus("Corrija os erros antes de prosseguir", CLR_NEGATIVE);
      return false;
   }
   return true;
}
```

### 14f. Helpers:
```cpp
int CEPBotPanel::CountOpenPositions(int magic)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByIndex(i))
         if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
            PositionGetInteger(POSITION_MAGIC) == magic)
            count++;
   }
   return count;
}

void CEPBotPanel::ShowSaveCancelButtons(bool show)
{
   // Mostrar/ocultar SALVAR e CANCELAR
   // Quando EA rodando: só PAUSAR visível
   // Quando EA pausado: todos visíveis
}

void CEPBotPanel::ShowStatus(string text, color clr)
{
   m_cfg_status.Text(text);
   m_cfg_status.Color(clr);
   m_cfgStatusExpiry = GetTickCount() + 10000;
   ChartRedraw();
}

// Refatorar ApplyConfig() para retornar bool:
bool CEPBotPanel::ApplyConfig(void)   // era void
{
   // ... validação existente ...
   if(errors > 0) return false;
   // ... aplicação ...
   return true;
}
```

---

## ETAPA 15: Fix TrendFilter.mqh — array out of range (linha 552)
**Arquivo:** `Strategy/Filters/TrendFilter.mqh`

**Bug:** Erro fatal `array out of range in 'TrendFilter.mqh' (552,12)` que
remove o EA do gráfico.

**Causa raiz:** `UpdateIndicators()` linha 390-391:
```cpp
if(m_handleMA == INVALID_HANDLE)
   return true;   // ← BUG! Retorna TRUE sem popular m_ma[]
```
Quando `m_handleMA == INVALID_HANDLE`, o método retorna `true` (indicando sucesso),
mas `m_ma[]` nunca foi preenchido via `CopyBuffer`. Na sequência, `ValidateSignal()`
linha 552 acessa `m_ma[0]` e `m_ma[1]` → crash.

**Cenários que disparam:**
- TrendFilter criado mas `Init()` falhou (handle inválido permanece INVALID_HANDLE)
- Handle liberado via `Cleanup()` mas `ValidateSignal()` ainda é chamado
- Hot-reload recriando indicador → handle temporariamente INVALID_HANDLE

**Fix:**
```cpp
// ANTES (bugado):
if(m_handleMA == INVALID_HANDLE)
   return true;

// DEPOIS (correto):
if(m_handleMA == INVALID_HANDLE)
   return false;   // Sem handle = dados não disponíveis
```

**Fix adicional de segurança:** Adicionar guard antes do acesso ao array na
linha 552:
```cpp
// ANTES:
if(m_ma[0] == 0 || m_ma[1] == 0)

// DEPOIS:
if(ArraySize(m_ma) < 2 || m_ma[0] == 0 || m_ma[1] == 0)
```

---

## ETAPA 16: Estado inicial do EA — Controles habilitados ao iniciar
**Arquivo:** `GUI/Panel.mqh`

### 16a. No Init() / CreatePanel():
Após criar todos os controles, como `m_eaStarted` começa `false` (EA pausado),
os controles já devem estar habilitados. Mostrar os 3 botões (INICIAR/SALVAR/CANCELAR).

### 16b. No ApplyLoadedConfig():
Após carregar config (banner CARREGAR ou auto-load), NÃO iniciar o EA
automaticamente. Os controles ficam habilitados, o EA fica pausado.
O usuário precisa clicar INICIAR para validar/aplicar/começar.

### 16c. Exibir status visual claro:
Quando pausado, a aba STATUS deve mostrar "PAUSADO" (amarelo) — já implementado
na Parte 027 anterior.

---

## ETAPA 11: Changelogs
Atualizar headers de versão nos arquivos modificados:

| Arquivo | Mudança principal | Parte |
|---------|-------------------|-------|
| ConfigPersistence.mqh | +4 campos SConfigData, validação enums | 027 |
| PanelPersistence.mqh | Collect/Apply novos campos, fix double-assign | 027 |
| PanelTabConfig.mqh | ApplyMagicNumberChange(), SetAllControlsEnabled(), ApplyConfig→bool | 027 |
| Panel.mqh | 3 botões (INICIAR/SALVAR/CANCELAR), CountOpenPositions() | 027 |
| TrendFilter.mqh | Fix array out of range (handle INVALID retornava true) | 027 |
| Logger.mqh | ReloadForMagic() | 027 |
| BlockerDrawdown.mqh | SetMagicNumber() com reset de estado | 027 |
| BlockerFilters.mqh | SetMagicNumber() limpa caches transição | 027 |
| Blockers.mqh | SetMagicNumber() completo + ReconstructStreaks() | 027 |
| TradeManager.mqh | SetMagicNumber() com cleanup + resync | 027 |
| MACrossPanel.mqh | Remover APLICAR, Apply() público | 027 |
| RSIStrategyPanel.mqh | Remover APLICAR, Apply() público | 027 |
| BollingerBandsPanel.mqh | Remover APLICAR, Apply() público | 027 |
| TrendFilterPanel.mqh | Remover APLICAR, Apply() público | 027 |
| RSIFilterPanel.mqh | Remover APLICAR, Apply() público | 027 |
| BollingerBandsFilterPanel.mqh | Remover APLICAR, Apply() público | 027 |

---

## ORDEM DE IMPLEMENTAÇÃO

```
FASE 1 — PERSISTÊNCIA + HOT-RELOAD (sem mudança de UX)
  1. ConfigPersistence.mqh  ← struct + Save + Load + validação
  2. Logger.mqh             ← ReloadForMagic()
  3. BlockerDrawdown.mqh    ← SetMagicNumber()
  4. BlockerFilters.mqh     ← expandir SetMagicNumber()
  5. TradeManager.mqh       ← expandir SetMagicNumber()
  6. Blockers.mqh           ← expandir SetMagicNumber() + ReconstructStreaks()
  7. PanelPersistence.mqh   ← Collect + Apply + fix assignments
  8. PanelTabConfig.mqh     ← ApplyMagicNumberChange() + hot-reload

FASE 2 — CONTROLE DE ESTADO (UX: 3 botões + travar controles)
  9.  Sub-painéis (6 arqs)  ← Remover APLICAR, Apply() público, SetEnabled()
  10. PanelTabConfig.mqh    ← SetAllControlsEnabled(), ApplyConfig()→bool
  11. Panel.mqh             ← 3 botões (INICIAR/SALVAR/CANCELAR), CountOpenPositions()

FASE 3 — BUGFIX
  12. TrendFilter.mqh       ← Fix array out of range (handle INVALID → return false)

FASE 4 — CHANGELOGS
  13. Todos os arquivos     ← Atualizar versões/changelogs
```

Etapas 2-5 podem ser feitas em paralelo (sem dependências entre si).
Etapa 6 depende de 3+4. Etapa 7 depende de 1. Etapa 8 depende de 6+7.
Fase 2 depende da Fase 1 estar completa.

---

## COMPATIBILIDADE COM .cfg ANTIGOS

O Load() usa key-value. Campos novos simplesmente não existirão em configs
salvos antes desta versão → ficam com valor zero/default do ZeroMemory().

Tratamento na ApplyLoadedConfig:
- `data.magicNumber == 0` → usar `m_magicNumber` atual (não mudar)
- `data.tradeComment == ""` → manter comment atual
- `data.trailingType == 0` (TRAILING_FIXED) → é o default correto
- `data.beType == 0` (BE_FIXED) → é o default correto

Nenhuma migração necessária. Configs antigos carregam normalmente.

---

## RISCOS E CUIDADOS

1. **Posições abertas ao mudar magic**: Com o novo modelo, magic SÓ pode ser
   alterado com EA pausado (sem posições). O risco de operação órfã é eliminado.

2. **Nome do .cfg muda com o magic**: O .cfg antigo fica intacto para se o
   usuário voltar ao magic anterior → stats e config restauram automaticamente.

3. **tradeComment com caracteres especiais**: O Save/Load usa key=value
   line-based. Verificar se TradeComment com "=" ou quebra de linha não
   quebra o parse. Se necessário, escapar.

4. **Ordem das chamadas**: Logger DEVE ser recarregado ANTES de
   Blockers.ReconstructStreaks(), pois os streaks leem do Logger.

5. **Botão SALVAR**: Substitui o antigo APLICAR CONFIG. Valida + aplica + salva
   sem iniciar trading. Desabilitado quando EA está rodando.

7. **Botão CANCELAR**: Recarrega último .cfg salvo. Se nunca salvou, mostra
   mensagem "Nenhuma config salva". Desabilitado quando EA está rodando.

8. **TrendFilter crash**: Bug crítico — `UpdateIndicators()` retorna `true` com
   `m_handleMA == INVALID_HANDLE`, causando acesso a array vazio. Fix simples
   mas impacto alto (remove o EA do gráfico).

6. **Edge case: MT5 fecha com posição aberta**: No restart, EA inicia pausado
   (m_eaStarted=false). Se há posição aberta do magic, os controles devem ficar
   travados. O OnInit deve verificar posições abertas e travar se necessário.

---

## TOTAL ESTIMADO
- **16 arquivos** modificados
- **~250-300 linhas** de código novo/alterado
- **~30 linhas** removidas (botões APLICAR dos sub-painéis)
- **0 arquivos** novos criados
- Lógica de trading existente: **inalterada**
- **1 bugfix crítico** (TrendFilter array out of range)
