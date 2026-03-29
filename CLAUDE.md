# EPBot Matrix — Notas de Sessão

## Parte 028 — Concluída (2026-03-29)

### O que foi feito
- SIGNAL MANAGER na aba STATUS exibe apenas ativos (não total)
- CONFIG → OUTROS: botões Conflito Sinais e Debug Logs travados com EA rodando
- `ApplyConfig()` retorna `bool`; `ValidateAndApplyAll()` verifica o retorno
- Double-save eliminado (SaveCurrentConfig() removido de dentro de ApplyConfig)
- Guards `m_eaStarted` em `OnClickConflict()` e `OnClickDebug()`
- Log de Trade Comment adicionado (só se mudar)
- Slippage: só loga se mudar
- Debug Logs / Debug Cooldown: nunca logam

---

## TODO — Parte 029

### CONFIG → RISCO
- [ ] Travar radio buttons SL type (FIXO / ATR / RANGE)
- [ ] Travar radio buttons TP type (FIXO / ATR)
- [ ] Travar toggle Partial TP
- [ ] Travar toggles Compensar Spread (SL / TP / Trailing)
- [ ] Validações dos campos

### CONFIG → RISCO 2
- [ ] Travar toggle Trailing ON/OFF e radios (FIXO / ATR)
- [ ] Travar toggle BE ON/OFF e radios (FIXO / ATR)
- [ ] Travar toggle Daily Limits ON/OFF e radios
- [ ] Travar toggle Drawdown ON/OFF e radios (tipo / peak)
- [ ] Validações dos campos

### CONFIG → BLOQUEIOS
- [ ] Travar toggle Streak Loss/Win ON/OFF e seus campos
- [ ] Travar toggle Time Filter ON/OFF e seus campos
- [ ] Travar toggle CBS ON/OFF e seus campos
- [ ] Validações dos campos

### CONFIG → BLOQ2 (News)
- [ ] Travar toggles News 1/2/3 ON/OFF e seus campos H/M
- [ ] Validações dos campos

### ESTRAT. / FILTROS
- [ ] Verificar se SetEnabled() dos sub-painéis está completo (todos os controles internos cobertos)

### Geral
- [ ] PR da Parte 028 → main
