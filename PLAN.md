# PLANO: Correção Completa da Persistência + Hot-Reload do Magic Number (Parte 028)

## Contexto
O hot-reload do Magic Number (e outros campos) via painel GUI tem múltiplos furos:
módulos não atualizados, campos não persistidos, estados stale, e riscos de
comportamento perigoso (drawdown não protege, streaks errados, etc.).

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
| ConfigPersistence.mqh | +4 campos SConfigData, validação enums | 028 |
| PanelPersistence.mqh | Collect/Apply novos campos, fix double-assign | 028 |
| PanelTabConfig.mqh | ApplyMagicNumberChange(), hot-reload centralizado | 028 |
| Logger.mqh | ReloadForMagic() | 028 |
| BlockerDrawdown.mqh | SetMagicNumber() com reset de estado | 028 |
| BlockerFilters.mqh | SetMagicNumber() limpa caches transição | 028 |
| Blockers.mqh | SetMagicNumber() completo + ReconstructStreaks() | 028 |
| TradeManager.mqh | SetMagicNumber() com cleanup + resync | 028 |

---

## ORDEM DE IMPLEMENTAÇÃO

```
1. ConfigPersistence.mqh  ← struct + Save + Load + validação  (base de tudo)
2. Logger.mqh             ← ReloadForMagic()                  (sem dependências)
3. BlockerDrawdown.mqh    ← SetMagicNumber()                  (sem dependências)
4. BlockerFilters.mqh     ← expandir SetMagicNumber()         (sem dependências)
5. TradeManager.mqh       ← expandir SetMagicNumber()         (sem dependências)
6. Blockers.mqh           ← expandir SetMagicNumber() + ReconstructStreaks()
7. PanelPersistence.mqh   ← Collect + Apply + fix assignments
8. PanelTabConfig.mqh     ← ApplyMagicNumberChange() + hot-reload
```

Etapas 2-5 podem ser feitas em paralelo (sem dependências entre si).
Etapa 6 depende de 3+4. Etapa 7 depende de 1. Etapa 8 depende de todas.

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

1. **Posições abertas ao mudar magic**: O ResyncExistingPositions() só encontrará
   posições do NOVO magic. Posições do magic antigo ficam "órfãs" (sem trailing,
   sem BE, sem parciais). Logar warning se houver posições abertas com magic antigo.

2. **Nome do .cfg muda com o magic**: O .cfg antigo fica intacto para se o
   usuário voltar ao magic anterior → stats e config restauram automaticamente.

3. **tradeComment com caracteres especiais**: O Save/Load usa key=value
   line-based. Verificar se TradeComment com "=" ou quebra de linha não
   quebra o parse. Se necessário, escapar.

4. **Ordem das chamadas**: Logger DEVE ser recarregado ANTES de
   Blockers.ReconstructStreaks(), pois os streaks leem do Logger.

---

## TOTAL ESTIMADO
- **8 arquivos** modificados
- **~80-100 linhas** de código novo
- **0 arquivos** novos criados
- **0 mudanças** em lógica de trading existente
