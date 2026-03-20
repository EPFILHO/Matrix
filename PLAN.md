# Plano: Fix CAppDialog minimize/maximize em troca de timeframe

## Problema
Quando o timeframe muda, o MT5 chama `OnDeinit(REASON_CHARTCHANGE)` → `OnInit()`.
O código atual destrói o painel e recria do zero, causando:
1. Estado minimizado perdido (sempre reabre maximizado)
2. Bug do `m_deinit_reason` interno do CAppDialog (botões min/max param de funcionar)

## Solução: Abordagem B — Destroy/Recreate com persistência de estado via GlobalVariable

**Por que esta abordagem e não "pular o Destroy"?**
- Os sub-painéis (CMACrossPanel, CRSIStrategyPanel, etc.) recebem ponteiros de estratégia/filtro **via construtor** e não têm setters
- Todos os módulos (logger, blockers, strategies, filters) **precisam** ser re-inicializados na troca de TF (novos handles de indicador)
- Pular o Destroy exigiria: (a) método ReinitModules no painel, (b) setters em todos os 6 sub-painéis, (c) limpeza e recriação de sub-painéis sem afetar controles gráficos existentes — alto risco de regressão
- A abordagem B é mais segura, mantém o fluxo existente intacto, e resolve o problema visível

## Mudanças necessárias

### Arquivo 1: `EPBot_Matrix.mq5` — OnDeinit (~5 linhas)

**Antes do Destroy do painel (ETAPA 0), adicionar:**
- Detectar se reason == REASON_CHARTCHANGE
- Se sim, salvar estado minimizado em GlobalVariable `"EPBot_<MagicNumber>_Minimized"`
  - Usar MagicNumber no nome para evitar conflitos entre instâncias

**Código conceitual:**
```
if(reason == REASON_CHARTCHANGE && g_panel != NULL)
   GlobalVariableSet("EPBot_" + IntegerToString(inp_MagicNumber) + "_Minimized",
                     m_minimized ? 1.0 : 0.0);
```

**Desafio:** `m_minimized` é campo protegido do CAppDialog, não acessível diretamente.
- **Solução:** Adicionar getter `IsMinimized()` em CEPBotPanel que retorna `m_minimized`

### Arquivo 2: `GUI/Panel.mqh` — Novo getter (~3 linhas)

Na seção `public` de CEPBotPanel, adicionar:
```
bool IsMinimized(void) const { return m_minimized; }
```

### Arquivo 3: `EPBot_Matrix.mq5` — OnInit, ETAPA 9 (~8 linhas)

**Após `g_panel.Run()`, adicionar restauração de estado:**
```
string gvName = "EPBot_" + IntegerToString(inp_MagicNumber) + "_Minimized";
if(GlobalVariableCheck(gvName))
{
   if(GlobalVariableGet(gvName) != 0.0)
      g_panel.Minimize();
   GlobalVariableDel(gvName);
}
```

### Arquivo 4: `EPBot_Matrix.mq5` — CleanupAll (~3 linhas)

Também salvar estado na CleanupAll caso seja chamada por REASON_CHARTCHANGE (improvável, mas defensivo).

## Arquivos afetados (resumo)

| Arquivo | Mudança | Linhas |
|---------|---------|--------|
| `GUI/Panel.mqh` | Adicionar `IsMinimized()` getter | ~3 |
| `EPBot_Matrix.mq5` OnDeinit | Salvar estado antes do Destroy | ~5 |
| `EPBot_Matrix.mq5` OnInit | Restaurar estado após Run() | ~8 |

## O que NÃO muda
- Toda a lógica de criação/destruição de módulos (etapas 1-8 do OnInit)
- Toda a lógica do painel (tabs, sub-painéis, botões, config hot-reload)
- Fluxo de OnChartEvent, OnTimer, Update
- Nenhum sub-painel é modificado
- CleanupAll mantém comportamento atual

## Riscos e mitigações
- **Risco:** `Minimize()` chamado antes do painel estar totalmente visível → label flicker
  - **Mitigação:** Chamar `Minimize()` APÓS `Run()` e após `ShowTab(TAB_STATUS)` já ter executado dentro de `CreatePanel`
- **Risco:** GlobalVariable órfã se EA crashar
  - **Mitigação:** `GlobalVariableDel` imediato após leitura; GVs temporárias não persistem entre restarts do terminal
- **Risco:** Múltiplas instâncias com mesmo MagicNumber
  - **Mitigação:** Nome inclui MagicNumber, e é deletada imediatamente após uso

## Estimativa de impacto
- ~16 linhas de código novo
- 2 arquivos editados
- Zero mudança em lógica existente
- Corrige: painel sempre maximiza ao trocar TF
- Não corrige: bug profundo do m_deinit_reason (requer patch no Dialog.mqh da stdlib) — mas na prática, como o ciclo destroy/create é feito corretamente com a ordem existente, os botões min/max continuam funcionando normalmente
