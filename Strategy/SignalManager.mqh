//+------------------------------------------------------------------+
//|                                               SignalManager.mqh  |
//|                                         Copyright 2025, EP Filho |
//|                   Gerenciador de Sinais e Filtros - EPBot Matrix |
//|                                                      Versão 2.02 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EP Filho"
#property version   "2.02"
#property strict

// ═══════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════
#include "../Core/Logger.mqh"
#include "Base/StrategyBase.mqh"
#include "Base/FilterBase.mqh"

//+------------------------------------------------------------------+
//| Enum para resolução de conflitos entre estratégias               |
//+------------------------------------------------------------------+
enum ENUM_CONFLICT_RESOLUTION
{
   CONFLICT_PRIORITY = 0,     // Usa prioridade (maior número ganha)
   CONFLICT_CANCEL = 1        // Cancela operação se sinais conflitantes
};

//+------------------------------------------------------------------+
//| Estrutura para armazenar estratégias                             |
//+------------------------------------------------------------------+
struct StrategyItem
{
   CStrategyBase* strategy;   // Ponteiro para estratégia
   bool enabled;              // Ativa/inativa (working variable)
};

//+------------------------------------------------------------------+
//| Gerenciador de Sinais                                            |
//+------------------------------------------------------------------+
class CSignalManager
{
private:
   // ═══════════════════════════════════════════════════════════
   // LOGGER
   // ═══════════════════════════════════════════════════════════
   CLogger* m_logger;

   // ═══════════════════════════════════════════════════════════
   // ARRAYS DE ESTRATÉGIAS E FILTROS (gerenciamento dinâmico)
   // ═══════════════════════════════════════════════════════════
   StrategyItem m_strategies[];      // Array de estratégias
   CFilterBase* m_filters[];         // Array de filtros
   
   int m_strategyCount;
   int m_filterCount;
   
   // ═══════════════════════════════════════════════════════════
   // INPUT PARAMETER - CONFIGURAÇÃO (valor original)
   // ═══════════════════════════════════════════════════════════
   ENUM_CONFLICT_RESOLUTION m_inputConflictMode;

   // ═══════════════════════════════════════════════════════════
   // WORKING PARAMETER - CONFIGURAÇÃO (valor usado)
   // ═══════════════════════════════════════════════════════════
   ENUM_CONFLICT_RESOLUTION m_conflictMode;
   
   // ═══════════════════════════════════════════════════════════
   // DEBUG/LOG (não são parâmetros, não precisam duplicação)
   // ═══════════════════════════════════════════════════════════
   string m_lastSignalSource;
   string m_lastBlockedBy;
   
   // ═══════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS
   // ═══════════════════════════════════════════════════════════
   ENUM_SIGNAL_TYPE ResolveConflict(ENUM_SIGNAL_TYPE &signals[], int count);
   bool ApplyFilters(ENUM_SIGNAL_TYPE signal);
   int FindStrategyIndex(string name);
   int FindFilterIndex(string name);
   
public:
   // ═══════════════════════════════════════════════════════════
   // CONSTRUTOR E DESTRUTOR
   // ═══════════════════════════════════════════════════════════
   CSignalManager();
   ~CSignalManager();
   
   // ═══════════════════════════════════════════════════════════
   // CONFIGURAÇÃO - Hot Reload
   // ═══════════════════════════════════════════════════════════
   void SetConflictResolution(ENUM_CONFLICT_RESOLUTION mode);
   
   // ═══════════════════════════════════════════════════════════
   // GERENCIAMENTO DE ESTRATÉGIAS - Hot Reload nativo
   // ═══════════════════════════════════════════════════════════
   bool AddStrategy(CStrategyBase* strategy);
   bool RemoveStrategy(string strategyName);
   bool EnableStrategy(string strategyName);       // ✅ Hot reload
   bool DisableStrategy(string strategyName);      // ✅ Hot reload
   bool SetStrategyPriority(string strategyName, int priority);  // ✅ Hot reload
   
   // ═══════════════════════════════════════════════════════════
   // GERENCIAMENTO DE FILTROS - Hot Reload nativo
   // ═══════════════════════════════════════════════════════════
   bool AddFilter(CFilterBase* filter);
   bool RemoveFilter(string filterName);
   bool EnableFilter(string filterName);           // ✅ Hot reload
   bool DisableFilter(string filterName);          // ✅ Hot reload
   
   // ═══════════════════════════════════════════════════════════
   // INICIALIZAÇÃO
   // ═══════════════════════════════════════════════════════════
   bool Initialize(CLogger* logger);
   void Deinitialize();
   void Clear();  // Limpar referências sem deletar objetos
   
   // ═══════════════════════════════════════════════════════════
   // MÉTODOS PRINCIPAIS
   // ═══════════════════════════════════════════════════════════
   ENUM_SIGNAL_TYPE GetSignal();           // Com filtros (para ENTRADAS)
   ENUM_SIGNAL_TYPE GetRawSignal();        // Sem filtros (para SAÍDAS)
   
   // ═══════════════════════════════════════════════════════════
   // GETTERS - Working values
   // ═══════════════════════════════════════════════════════════
   string GetLastSignalSource() const { return m_lastSignalSource; }
   string GetLastBlockedBy() const { return m_lastBlockedBy; }
   int GetStrategyCount() const { return m_strategyCount; }
   int GetFilterCount() const { return m_filterCount; }
   ENUM_CONFLICT_RESOLUTION GetConflictMode() const { return m_conflictMode; }

   // ═══════════════════════════════════════════════════════════
   // GETTERS - Input values (valores originais)
   // ═══════════════════════════════════════════════════════════
   ENUM_CONFLICT_RESOLUTION GetInputConflictMode() const { return m_inputConflictMode; }
   
   // ═══════════════════════════════════════════════════════════
   // DEBUG/INFO
   // ═══════════════════════════════════════════════════════════
   void PrintStatus();
};

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CSignalManager::CSignalManager()
{
   m_logger = NULL;
   m_strategyCount = 0;
   m_filterCount = 0;
   
   // Input parameter (valor padrão)
   m_inputConflictMode = CONFLICT_PRIORITY;
   
   // Working parameter (começa igual ao input)
   m_conflictMode = CONFLICT_PRIORITY;
   
   m_lastSignalSource = "";
   m_lastBlockedBy = "";
   
   ArrayResize(m_strategies, 0);
   ArrayResize(m_filters, 0);
}

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CSignalManager::~CSignalManager()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Hot Reload - Configurar modo de resolução de conflitos           |
//+------------------------------------------------------------------+
void CSignalManager::SetConflictResolution(ENUM_CONFLICT_RESOLUTION mode)
{
   ENUM_CONFLICT_RESOLUTION oldMode = m_conflictMode;
   m_conflictMode = mode;
   
   string oldModeStr = (oldMode == CONFLICT_PRIORITY) ? "Prioridade" : "Cancelar";
   string newModeStr = (mode == CONFLICT_PRIORITY) ? "Prioridade" : "Cancelar";
   
   string msg = "🔄 [Signal Manager] Modo de conflito alterado: " + oldModeStr + " → " + newModeStr;
   
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);
}

//+------------------------------------------------------------------+
//| Hot Reload - Adicionar estratégia                                |
//+------------------------------------------------------------------+
bool CSignalManager::AddStrategy(CStrategyBase* strategy)
{
   if(strategy == NULL)
   {
      string msg = "[Signal Manager] Estratégia nula";
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print("❌ ", msg);
      return false;
   }
   
   if(FindStrategyIndex(strategy.GetName()) >= 0)
   {
      string msg = "[Signal Manager] Estratégia '" + strategy.GetName() + "' já existe";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print("⚠️ ", msg);
      return false;
   }
   
   ArrayResize(m_strategies, m_strategyCount + 1);
   m_strategies[m_strategyCount].strategy = strategy;
   m_strategies[m_strategyCount].enabled = true;
   m_strategyCount++;
   
   string msg = "✅ [Signal Manager] Estratégia adicionada: '" + strategy.GetName() + 
                "' (Prioridade: " + IntegerToString(strategy.GetPriority()) + ")";
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);
   
   return true;
}

//+------------------------------------------------------------------+
//| Hot Reload - Remover estratégia                                  |
//+------------------------------------------------------------------+
bool CSignalManager::RemoveStrategy(string strategyName)
{
   int index = FindStrategyIndex(strategyName);
   if(index < 0)
   {
      string msg = "[Signal Manager] Estratégia '" + strategyName + "' não encontrada";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print("⚠️ ", msg);
      return false;
   }
   
   for(int i = index; i < m_strategyCount - 1; i++)
   {
      m_strategies[i] = m_strategies[i + 1];
   }
   
   m_strategyCount--;
   ArrayResize(m_strategies, m_strategyCount);
   
   string msg = "🗑️ [Signal Manager] Estratégia removida: '" + strategyName + "'";
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);
   
   return true;
}

//+------------------------------------------------------------------+
//| Hot Reload - Ativar estratégia                                   |
//+------------------------------------------------------------------+
bool CSignalManager::EnableStrategy(string strategyName)
{
   int index = FindStrategyIndex(strategyName);
   if(index < 0)
   {
      string msg = "[Signal Manager] Estratégia '" + strategyName + "' não encontrada";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print("⚠️ ", msg);
      return false;
   }
   
   m_strategies[index].enabled = true;
   
   string msg = "✅ [Signal Manager] Estratégia habilitada: '" + strategyName + "'";
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);
   
   return true;
}

//+------------------------------------------------------------------+
//| Hot Reload - Desativar estratégia                                |
//+------------------------------------------------------------------+
bool CSignalManager::DisableStrategy(string strategyName)
{
   int index = FindStrategyIndex(strategyName);
   if(index < 0)
   {
      string msg = "[Signal Manager] Estratégia '" + strategyName + "' não encontrada";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print("⚠️ ", msg);
      return false;
   }
   
   m_strategies[index].enabled = false;
   
   string msg = "⏸️ [Signal Manager] Estratégia desabilitada: '" + strategyName + "'";
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);
   
   return true;
}

//+------------------------------------------------------------------+
//| Hot Reload - Definir prioridade da estratégia                    |
//+------------------------------------------------------------------+
bool CSignalManager::SetStrategyPriority(string strategyName, int priority)
{
   int index = FindStrategyIndex(strategyName);
   if(index < 0)
   {
      string msg = "[Signal Manager] Estratégia '" + strategyName + "' não encontrada";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print("⚠️ ", msg);
      return false;
   }
   
   if(m_strategies[index].strategy != NULL)
   {
      int oldPriority = m_strategies[index].strategy.GetPriority();
      m_strategies[index].strategy.SetPriority(priority);
      
      string msg = "🔧 [Signal Manager] Prioridade alterada: '" + strategyName + 
                   "' " + IntegerToString(oldPriority) + " → " + IntegerToString(priority);
      if(m_logger != NULL)
         m_logger.LogInfo(msg);
      else
         Print(msg);
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Hot Reload - Adicionar filtro                                    |
//+------------------------------------------------------------------+
bool CSignalManager::AddFilter(CFilterBase* filter)
{
   if(filter == NULL)
   {
      string msg = "[Signal Manager] Filtro nulo";
      if(m_logger != NULL)
         m_logger.LogError(msg);
      else
         Print("❌ ", msg);
      return false;
   }
   
   if(FindFilterIndex(filter.GetName()) >= 0)
   {
      string msg = "[Signal Manager] Filtro '" + filter.GetName() + "' já existe";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print("⚠️ ", msg);
      return false;
   }
   
   ArrayResize(m_filters, m_filterCount + 1);
   m_filters[m_filterCount] = filter;
   m_filterCount++;
   
   string msg = "✅ [Signal Manager] Filtro adicionado: '" + filter.GetName() + "'";
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);
   
   return true;
}

//+------------------------------------------------------------------+
//| Hot Reload - Remover filtro                                      |
//+------------------------------------------------------------------+
bool CSignalManager::RemoveFilter(string filterName)
{
   int index = FindFilterIndex(filterName);
   if(index < 0)
   {
      string msg = "[Signal Manager] Filtro '" + filterName + "' não encontrado";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print("⚠️ ", msg);
      return false;
   }
   
   for(int i = index; i < m_filterCount - 1; i++)
   {
      m_filters[i] = m_filters[i + 1];
   }
   
   m_filterCount--;
   ArrayResize(m_filters, m_filterCount);
   
   string msg = "🗑️ [Signal Manager] Filtro removido: '" + filterName + "'";
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);
   
   return true;
}

//+------------------------------------------------------------------+
//| Hot Reload - Ativar filtro                                       |
//+------------------------------------------------------------------+
bool CSignalManager::EnableFilter(string filterName)
{
   int index = FindFilterIndex(filterName);
   if(index < 0)
   {
      string msg = "[Signal Manager] Filtro '" + filterName + "' não encontrado";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print("⚠️ ", msg);
      return false;
   }
   
   m_filters[index].Enable();
   
   string msg = "✅ [Signal Manager] Filtro habilitado: '" + filterName + "'";
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);
   
   return true;
}

//+------------------------------------------------------------------+
//| Hot Reload - Desativar filtro                                    |
//+------------------------------------------------------------------+
bool CSignalManager::DisableFilter(string filterName)
{
   int index = FindFilterIndex(filterName);
   if(index < 0)
   {
      string msg = "[Signal Manager] Filtro '" + filterName + "' não encontrado";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print("⚠️ ", msg);
      return false;
   }
   
   m_filters[index].Disable();
   
   string msg = "⏸️ [Signal Manager] Filtro desabilitado: '" + filterName + "'";
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);
   
   return true;
}

//+------------------------------------------------------------------+
//| Inicializar todas as estratégias e filtros                       |
//+------------------------------------------------------------------+
bool CSignalManager::Initialize(CLogger* logger)
{
   m_logger = logger;
   
   // Salvar input parameter (valor original)
   m_inputConflictMode = m_conflictMode;
   
   string msg = "🚀 [Signal Manager] Inicializando...";
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);
   
   bool success = true;
   
   // Inicializar estratégias
   for(int i = 0; i < m_strategyCount; i++)
   {
      if(m_strategies[i].strategy != NULL)
      {
         if(!m_strategies[i].strategy.Initialize())
         {
            string errMsg = "[Signal Manager] Falha ao inicializar estratégia: '" + 
                           m_strategies[i].strategy.GetName() + "'";
            if(m_logger != NULL)
               m_logger.LogError(errMsg);
            else
               Print("❌ ", errMsg);
            success = false;
         }
      }
   }
   
   // Inicializar filtros
   for(int i = 0; i < m_filterCount; i++)
   {
      if(m_filters[i] != NULL)
      {
         if(!m_filters[i].Initialize())
         {
            string errMsg = "[Signal Manager] Falha ao inicializar filtro: '" + 
                           m_filters[i].GetName() + "'";
            if(m_logger != NULL)
               m_logger.LogError(errMsg);
            else
               Print("❌ ", errMsg);
            success = false;
         }
      }
   }
   
   if(success)
   {
      string successMsg = "✅ [Signal Manager] Inicializado com sucesso";
      if(m_logger != NULL)
         m_logger.LogInfo(successMsg);
      else
         Print(successMsg);
   }
   
   return success;
}

//+------------------------------------------------------------------+
//| Desinicializar                                                   |
//+------------------------------------------------------------------+
void CSignalManager::Deinitialize()
{
   for(int i = 0; i < m_strategyCount; i++)
   {
      if(m_strategies[i].strategy != NULL)
      {
         m_strategies[i].strategy.Deinitialize();
      }
   }
   
   for(int i = 0; i < m_filterCount; i++)
   {
      if(m_filters[i] != NULL)
      {
         m_filters[i].Deinitialize();
      }
   }
   
   string msg = "🔌 [Signal Manager] Desinicializado";
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);
}

//+------------------------------------------------------------------+
//| Limpar referências (chamado antes de deletar objetos externos)   |
//+------------------------------------------------------------------+
void CSignalManager::Clear()
{
   // Zerar ponteiros para evitar acesso a memória inválida no destrutor
   for(int i = 0; i < m_strategyCount; i++)
   {
      m_strategies[i].strategy = NULL;
   }
   
   for(int i = 0; i < m_filterCount; i++)
   {
      m_filters[i] = NULL;
   }
   
   string msg = "🧹 [Signal Manager] Referências limpas";
   if(m_logger != NULL)
      m_logger.LogInfo(msg);
   else
      Print(msg);
}

//+------------------------------------------------------------------+
//| Encontrar índice da estratégia por nome                          |
//+------------------------------------------------------------------+
int CSignalManager::FindStrategyIndex(string name)
{
   for(int i = 0; i < m_strategyCount; i++)
   {
      if(m_strategies[i].strategy != NULL && 
         m_strategies[i].strategy.GetName() == name)
      {
         return i;
      }
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Encontrar índice do filtro por nome                              |
//+------------------------------------------------------------------+
int CSignalManager::FindFilterIndex(string name)
{
   for(int i = 0; i < m_filterCount; i++)
   {
      if(m_filters[i] != NULL && m_filters[i].GetName() == name)
      {
         return i;
      }
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Resolver conflitos entre sinais (usa PRIORIDADE)                 |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CSignalManager::ResolveConflict(ENUM_SIGNAL_TYPE &signals[], int count)
{
   if(count == 0)
      return SIGNAL_NONE;
   
   if(count == 1)
      return signals[0];
   
   // Verificar se há conflito
   bool hasBuy = false;
   bool hasSell = false;
   
   for(int i = 0; i < count; i++)
   {
      if(signals[i] == SIGNAL_BUY) hasBuy = true;
      if(signals[i] == SIGNAL_SELL) hasSell = true;
   }
   
   // Se não há conflito (todos iguais), retorna o primeiro válido
   if(!hasBuy || !hasSell)
   {
      for(int i = 0; i < count; i++)
      {
         if(signals[i] != SIGNAL_NONE)
            return signals[i];
      }
      return SIGNAL_NONE;
   }
   
   // Há conflito (BUY e SELL simultâneos)
   if(m_conflictMode == CONFLICT_CANCEL)
   {
      string msg = "🚫 [Signal Manager] Conflito detectado - operação cancelada";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print(msg);
      return SIGNAL_NONE;
   }
   
   // CONFLICT_PRIORITY: Usar MAIOR prioridade
   int maxPriority = -999999;
   ENUM_SIGNAL_TYPE winningSignal = SIGNAL_NONE;
   string winningStrategy = "";
   
   for(int i = 0; i < m_strategyCount; i++)
   {
      if(m_strategies[i].enabled && 
         m_strategies[i].strategy != NULL && 
         signals[i] != SIGNAL_NONE)
      {
         int priority = m_strategies[i].strategy.GetPriority();
         
         if(priority > maxPriority)
         {
            maxPriority = priority;
            winningSignal = signals[i];
            winningStrategy = m_strategies[i].strategy.GetName();
         }
      }
   }
   
   if(winningSignal != SIGNAL_NONE)
   {
      string msg = "⚖️ [Signal Manager] Conflito detectado - vencedor por prioridade: '" + 
                   winningStrategy + "' (" + IntegerToString(maxPriority) + ")";
      if(m_logger != NULL)
         m_logger.LogWarning(msg);
      else
         Print(msg);
   }
   
   return winningSignal;
}

//+------------------------------------------------------------------+
//| Aplicar todos os filtros ao sinal                                |
//+------------------------------------------------------------------+
bool CSignalManager::ApplyFilters(ENUM_SIGNAL_TYPE signal)
{
   m_lastBlockedBy = "";
   
   for(int i = 0; i < m_filterCount; i++)
   {
      if(m_filters[i] != NULL && m_filters[i].IsEnabled())
      {
         if(!m_filters[i].ValidateSignal(signal))
         {
            m_lastBlockedBy = m_filters[i].GetName();
            return false;
         }
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Obter sinal RAW (sem filtros) - para SAÍDAS                      |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CSignalManager::GetRawSignal()
{
   ENUM_SIGNAL_TYPE signals[];
   ArrayResize(signals, m_strategyCount);
   
   for(int i = 0; i < m_strategyCount; i++)
   {
      if(m_strategies[i].enabled && m_strategies[i].strategy != NULL)
      {
         signals[i] = m_strategies[i].strategy.GetSignal();
      }
      else
      {
         signals[i] = SIGNAL_NONE;
      }
   }
   
   return ResolveConflict(signals, m_strategyCount);
}

//+------------------------------------------------------------------+
//| Obter sinal final COM FILTROS - para ENTRADAS                    |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CSignalManager::GetSignal()
{
   m_lastSignalSource = "";
   m_lastBlockedBy = "";
   
   // Coletar sinais de todas as estratégias ativas
   ENUM_SIGNAL_TYPE signals[];
   ArrayResize(signals, m_strategyCount);
   
   int validSignals = 0;
   for(int i = 0; i < m_strategyCount; i++)
   {
      if(m_strategies[i].enabled && m_strategies[i].strategy != NULL)
      {
         signals[i] = m_strategies[i].strategy.GetSignal();
         
         if(signals[i] != SIGNAL_NONE)
         {
            validSignals++;
            if(m_lastSignalSource == "")
               m_lastSignalSource = m_strategies[i].strategy.GetName();
            else
               m_lastSignalSource += ", " + m_strategies[i].strategy.GetName();
         }
      }
      else
      {
         signals[i] = SIGNAL_NONE;
      }
   }
   
   if(validSignals == 0)
      return SIGNAL_NONE;
   
   // Resolver conflitos (se houver)
   ENUM_SIGNAL_TYPE finalSignal = ResolveConflict(signals, m_strategyCount);
   
   if(finalSignal == SIGNAL_NONE)
      return SIGNAL_NONE;
   
   // Aplicar filtros
   if(!ApplyFilters(finalSignal))
   {
      return SIGNAL_NONE;
   }
   
   return finalSignal;
}

//+------------------------------------------------------------------+
//| Imprimir status do Signal Manager                                |
//+------------------------------------------------------------------+
void CSignalManager::PrintStatus()
{
   if(m_logger != NULL)
     {
      m_logger.LogInfo("═══════════════════════════════════════════════════════");
      m_logger.LogInfo("📊 [Signal Manager v2.02] Status");
      m_logger.LogInfo("═══════════════════════════════════════════════════════");
      
      m_logger.LogInfo("🎯 Estratégias (" + IntegerToString(m_strategyCount) + "):");
      for(int i = 0; i < m_strategyCount; i++)
      {
         if(m_strategies[i].strategy != NULL)
         {
            string status = m_strategies[i].enabled ? "✅" : "⏸️";
            int priority = m_strategies[i].strategy.GetPriority();
            m_logger.LogInfo("  " + IntegerToString(i+1) + ". " + status + " " + m_strategies[i].strategy.GetName() + 
                           " (Prioridade: " + IntegerToString(priority) + ")");
         }
      }
      
      m_logger.LogInfo("🔍 Filtros (" + IntegerToString(m_filterCount) + "):");
      for(int i = 0; i < m_filterCount; i++)
      {
         if(m_filters[i] != NULL)
         {
            string status = m_filters[i].IsEnabled() ? "✅" : "⏸️";
            m_logger.LogInfo("  " + IntegerToString(i+1) + ". " + status + " " + m_filters[i].GetName());
         }
      }
      
      string conflictMode = (m_conflictMode == CONFLICT_PRIORITY) ? "Prioridade (maior número ganha)" : "Cancelar conflitos";
      m_logger.LogInfo("⚙️ Resolução de conflitos: " + conflictMode);
      
      m_logger.LogInfo("═══════════════════════════════════════════════════════");
     }
   else
     {
      Print("═══════════════════════════════════════════════════════");
      Print("📊 [Signal Manager v2.02] Status");
      Print("═══════════════════════════════════════════════════════");
      
      Print("🎯 Estratégias (", m_strategyCount, "):");
      for(int i = 0; i < m_strategyCount; i++)
      {
         if(m_strategies[i].strategy != NULL)
         {
            string status = m_strategies[i].enabled ? "✅" : "⏸️";
            int priority = m_strategies[i].strategy.GetPriority();
            Print("  ", i+1, ". ", status, " ", m_strategies[i].strategy.GetName(), 
                  " (Prioridade: ", priority, ")");
         }
      }
      
      Print("🔍 Filtros (", m_filterCount, "):");
      for(int i = 0; i < m_filterCount; i++)
      {
         if(m_filters[i] != NULL)
         {
            string status = m_filters[i].IsEnabled() ? "✅" : "⏸️";
            Print("  ", i+1, ". ", status, " ", m_filters[i].GetName());
         }
      }
      
      string conflictMode = (m_conflictMode == CONFLICT_PRIORITY) ? "Prioridade (maior número ganha)" : "Cancelar conflitos";
      Print("⚙️ Resolução de conflitos: ", conflictMode);
      
      Print("═══════════════════════════════════════════════════════");
     }
}
//+------------------------------------------------------------------+
