# 📊 BLOCKERS.MQH - AUDITORIA COMPLETA DE LOGS

## Resumo Executivo
- **Total de logs**: ~150 mensagens
- **Hierarquias usadas**: INFO (maioria), WARNING (bloqueios), ERROR (validações), DEBUG (ignores)
- **Throttle atual**: Once (3), Throttled (1), Normal (resto)

---

## 🚨 PROBLEMAS IDENTIFICADOS

### ❌ Problema 1: Bloqueios de SESSÃO estão como WARNING (devem ser INFO)
**Linhas**: 1168, 1205, 1236
- `blocker_session_before` → LogWarningOnce → **DEVERIA SER LogInfoOnce**
- `blocker_session_window` → LogWarningOnce → **DEVERIA SER LogInfoOnce**
- `blocker_session_after` → LogWarningOnce → **DEVERIA SER LogInfoOnce**

**Motivo**: Bloqueios por horário são comportamento **NORMAL e ESPERADO**, não são warnings.

---

## 📋 INVENTÁRIO COMPLETO DE LOGS

### 1️⃣ INICIALIZAÇÃO (Initialize)
| Linha | Mensagem | Hierarquia | Throttle | Status |
|-------|----------|------------|----------|--------|
| 548-551 | Banner de inicialização | INFO | None | ✅ OK (roda 1x) |
| 581 | "Horários inválidos!" | ERROR | None | ✅ OK |
| 601 | Configuração de horário | INFO | None | ✅ OK |
| 608 | "Fecha posição ao fim" | INFO | None | ✅ OK |
| 616 | "Filtro de Horário: DESATIVADO" | INFO | None | ✅ OK |
| 663-695 | Horários de volatilidade | INFO | None | ✅ OK |
| 710-717 | Spread máximo | INFO | None | ✅ OK |
| 741-780 | Limites diários | INFO | None | ✅ OK |
| 808-849 | Controle de streak | INFO | None | ✅ OK |
| 869-910 | Drawdown máximo | INFO/ERROR | None | ✅ OK |
| 937 | Direção permitida | INFO | None | ✅ OK |
| 957-959 | "Blockers inicializados" | INFO | None | ✅ OK |

**Análise**: Logs de inicialização estão corretos (INFO, sem throttle, rodando 1x).

---

### 2️⃣ BLOQUEIOS DE SESSÃO (CanTrade - CheckTimeFilter)
| Linha | Contexto | Mensagem | Hierarquia | Throttle | ❌ Problema |
|-------|----------|----------|------------|----------|------------|
| 1168 | Sessão ainda não iniciou | "Sessão ainda não iniciou" | **WARNING** | Once | ❌ **DEVERIA SER INFO** |
| 1205 | Proteção antes do fim | "Proteção de Sessão" | **WARNING** | Once | ❌ **DEVERIA SER INFO** |
| 1236 | Sessão encerrada | "Sessão ENCERRADA" | **WARNING** | Once | ❌ **DEVERIA SER INFO** |

**Recomendação**: Trocar todos de `LogWarningOnce` → `LogInfoOnce`

**Justificativa**:
- Bloqueios por horário são **comportamento esperado**, não são avisos
- O usuário configurou horário de operação, então é **normal** estar bloqueado fora dele
- WARNING deve ser reservado para situações **anormais** (spread alto, streak, drawdown)

---

### 3️⃣ FECHAMENTO POR HORÁRIO (ShouldCloseOnEndTime, ShouldCloseBeforeSessionEnd)
| Linha | Contexto | Mensagem | Hierarquia | Throttle | Status |
|-------|----------|----------|------------|----------|--------|
| 1354 | Ignora outra posição | "Ignorando posição #X (MagicNumber diferente)" | DEBUG | None | ✅ OK |
| 1378-1382 | Término de horário | "Término de horário atingido" | INFO | None | ⚠️ Pode gerar FLOOD |
| 1401-1405 | Fora horário noturno | "Fora do horário (janela noturna)" | INFO | None | ⚠️ Pode gerar FLOOD |
| 1437 | Ignora outra posição | "Ignorando posição #X" | DEBUG | None | ✅ OK |
| 1475-1482 | Proteção de sessão | "Proteção de Sessão ativada" | INFO | None | ⚠️ Pode gerar FLOOD |

**Recomendação**:
- Linha 1378-1382: Adicionar `LogInfoOnce("blocker_close_endtime", msg)`
- Linha 1401-1405: Adicionar `LogInfoOnce("blocker_close_overnight", msg)`
- Linha 1475-1482: Adicionar `LogInfoOnce("blocker_close_protection", msg)`

**Motivo**: Essas mensagens podem ser chamadas múltiplas vezes (a cada tick) se houver posição aberta.

---

### 4️⃣ BLOQUEIOS DE SPREAD (CanTrade - CheckSpreadFilter)
| Linha | Contexto | Mensagem | Hierarquia | Throttle | Status |
|-------|----------|----------|------------|----------|--------|
| 1511 | Spread alto | "Spread muito alto: X pontos" | WARNING | None | ❌ **GERA FLOOD** |
| 1525 | Spread alto (backup) | "Spread muito alto" | WARNING | None | ❌ **GERA FLOOD** |

**Recomendação**:
```mql5
// Linha 1511
m_logger.LogWarningThrottled("blocker_spread_high", msg, 60);  // 1 log/min

// Linha 1525
m_logger.LogWarningThrottled("blocker_spread_high_fallback", msg, 60);
```

**Motivo**: Spread pode ficar alto por vários ticks seguidos, gerando flood massivo.

---

### 5️⃣ PROTEÇÃO DE DRAWDOWN (ActivateDrawdownProtection, CheckDrawdownFilter)
| Linha | Contexto | Mensagem | Hierarquia | Throttle | Status |
|-------|----------|----------|------------|----------|--------|
| 1567-1576 | Ativação de drawdown | "PROTEÇÃO DE DRAWDOWN ATIVADA!" | INFO | None | ✅ OK (roda 1x) |
| 1971-1983 | Drawdown atingido | "LIMITE DE DRAWDOWN ATINGIDO!" | WARNING | None | ⚠️ Pode repetir |

**Recomendação**:
- Linha 1971-1983: Adicionar `LogWarningOnce("blocker_drawdown_limit", msg)`

---

### 6️⃣ RESET DIÁRIO (ResetDaily)
| Linha | Mensagem | Hierarquia | Throttle | Status |
|-------|----------|------------|----------|--------|
| 1599 | "RESET DIÁRIO - Limpando contadores" | INFO | None | ✅ OK (roda 1x/dia) |
| 1615 | "Contadores zerados!" | INFO | None | ✅ OK |

---

### 7️⃣ STREAK (CheckAndUpdateStreak, IsStreakPaused)
| Linha | Contexto | Mensagem | Hierarquia | Throttle | Status |
|-------|----------|----------|------------|----------|--------|
| 1793 | EA pausado (aguardando) | "EA pausado por streak" | WARNING | Throttled (300s) | ✅ OK |
| 1802-1807 | Pausa finalizada | "PAUSA DE SEQUÊNCIA FINALIZADA" | INFO | None | ✅ OK (roda 1x) |
| 1832-1871 | Sequência de perdas | "SEQUÊNCIA DE PERDAS ATINGIDA!" | WARNING | None | ✅ OK (roda 1x) |
| 1882-1927 | Sequência de ganhos | "SEQUÊNCIA DE GANHOS ATINGIDA!" | WARNING | None | ✅ OK (roda 1x) |

**Análise**: Streak está bem implementado!
- Evento único (atingir streak) loga 1x sem throttle ✅
- Aguardando pausa loga a cada 5min (mostra progresso) ✅

---

### 8️⃣ ALTERAÇÕES EM RUNTIME (UpdateXxx)
| Linha | Contexto | Hierarquia | Throttle | Status |
|-------|----------|------------|----------|--------|
| 984 | UpdateMaxSpread | INFO | None | ✅ OK |
| 1027 | UpdateDirection | INFO | None | ✅ OK |
| 1044-1048 | UpdateDailyLimits | INFO | None | ✅ OK |
| 1075-1079 | UpdateStreakLimits | INFO | None | ✅ OK |
| 1102 | UpdateDrawdown | INFO | None | ✅ OK |

---

### 9️⃣ STATUS E DEBUG (GetStatus, GetFullConfig)
| Linha | Contexto | Hierarquia | Status |
|-------|----------|------------|--------|
| 2082-2202 | GetStatus() | INFO/WARNING | ✅ OK (chamado manualmente) |
| 2218-2262 | GetFullConfig() | INFO | ✅ OK (chamado manualmente) |

---

## 🎯 RESUMO DE MUDANÇAS NECESSÁRIAS

### ALTA PRIORIDADE (Geram FLOOD)
| Linha | Atual | Deve ser | Motivo |
|-------|-------|----------|--------|
| 1511 | `LogWarning(msg)` | `LogWarningThrottled("blocker_spread_high", msg, 60)` | Flood a cada tick |
| 1525 | `LogWarning(msg)` | `LogWarningThrottled("blocker_spread_high_fallback", msg, 60)` | Flood a cada tick |
| 1378-1382 | `LogInfo(...)` (5 linhas) | `LogInfoOnce("blocker_close_endtime", msg_consolidado)` | Flood a cada tick |
| 1401-1405 | `LogInfo(...)` (5 linhas) | `LogInfoOnce("blocker_close_overnight", msg_consolidado)` | Flood a cada tick |
| 1475-1482 | `LogInfo(...)` (8 linhas) | `LogInfoOnce("blocker_close_protection", msg_consolidado)` | Flood a cada tick |

### MÉDIA PRIORIDADE (Hierarquia incorreta)
| Linha | Atual | Deve ser | Motivo |
|-------|-------|----------|--------|
| 1168 | `LogWarningOnce(...)` | `LogInfoOnce(...)` | Sessão é comportamento normal, não warning |
| 1205 | `LogWarningOnce(...)` | `LogInfoOnce(...)` | Proteção de sessão é normal |
| 1236 | `LogWarningOnce(...)` | `LogInfoOnce(...)` | Sessão encerrada é normal |

### BAIXA PRIORIDADE (Segurança extra)
| Linha | Atual | Deve ser | Motivo |
|-------|-------|----------|--------|
| 1971-1983 | `LogWarning(...)` (múltiplas linhas) | `LogWarningOnce("blocker_drawdown_limit", msg)` | Pode repetir se drawdown persistir |

---

## 📊 ESTATÍSTICAS

| Categoria | Quantidade | Throttle Necessário? |
|-----------|------------|---------------------|
| Inicialização | ~40 | ❌ Não (roda 1x) |
| Bloqueios de sessão | 3 | ✅ Sim (Once) - **já feito** |
| Fechamento por horário | 3 | ⚠️ **Precisa Once** |
| Spread | 2 | ⚠️ **Precisa Throttled** |
| Streak | 4 | ✅ Sim - **já feito** |
| Drawdown | 2 | ⚠️ Precisa Once (1 de 2) |
| Runtime updates | 5 | ❌ Não (manual) |
| Status/Debug | ~100 | ❌ Não (manual) |

---

## ✅ CHECKLIST DE CORREÇÕES

### Corrigir HIERARQUIA (INFO vs WARNING)
- [ ] Linha 1168: `LogWarningOnce` → `LogInfoOnce` (sessão antes)
- [ ] Linha 1205: `LogWarningOnce` → `LogInfoOnce` (sessão janela)
- [ ] Linha 1236: `LogWarningOnce` → `LogInfoOnce` (sessão depois)

### Adicionar THROTTLE para evitar FLOOD
- [ ] Linha 1378-1382: Consolidar + `LogInfoOnce("blocker_close_endtime", ...)`
- [ ] Linha 1401-1405: Consolidar + `LogInfoOnce("blocker_close_overnight", ...)`
- [ ] Linha 1475-1482: Consolidar + `LogInfoOnce("blocker_close_protection", ...)`
- [ ] Linha 1511: `LogWarning` → `LogWarningThrottled("blocker_spread_high", msg, 60)`
- [ ] Linha 1525: `LogWarning` → `LogWarningThrottled("blocker_spread_high_fallback", msg, 60)`
- [ ] Linha 1971-1983: Consolidar + `LogWarningOnce("blocker_drawdown_limit", ...)`

---

## 🎯 PRIORIZAÇÃO

1. **URGENTE**: Spread (linhas 1511, 1525) - gera flood massivo
2. **IMPORTANTE**: Fechamento por horário (1378, 1401, 1475) - gera flood quando tem posição
3. **MÉDIO**: Hierarquia de sessão (1168, 1205, 1236) - mais correto semanticamente
4. **BAIXO**: Drawdown (1971) - edge case raro

---

**Gerado em**: 2026-01-11
**Arquivo analisado**: Core/Blockers.mqh v3.00
**Total de linhas**: 2270
