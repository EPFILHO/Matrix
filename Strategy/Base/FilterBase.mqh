//+------------------------------------------------------------------+
//|                                                   FilterBase.mqh |
//|                                         Copyright 2026, EP Filho |
//|                                  Interface Base para Filtros     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "2.00"
#property strict

#include "StrategyBase.mqh"  // Para usar ENUM_SIGNAL_TYPE

//+------------------------------------------------------------------+
//| Classe Base Abstrata para Filtros                                |
//+------------------------------------------------------------------+
class CFilterBase
{
protected:
   string m_filterName;        // Nome do filtro
   bool   m_isEnabled;         // Filtro ativo/inativo (working variable)
   bool   m_isInitialized;     // Flag de inicialização
   
public:
   // Construtor
   CFilterBase(string name) : 
      m_filterName(name), 
      m_isEnabled(true), 
      m_isInitialized(false) {}
   
   // Destrutor virtual
   virtual ~CFilterBase() {}
   
   // ═══════════════════════════════════════════════════════════
   // MÉTODOS VIRTUAIS PUROS (obrigatórios em classes filhas)
   // ═══════════════════════════════════════════════════════════
   
   // Inicialização e finalização
   virtual bool Initialize() = 0;
   virtual void Deinitialize() = 0;
   
   // Valida se o sinal passa pelo filtro
   // Retorna: true = sinal aprovado, false = sinal bloqueado
   virtual bool ValidateSignal(ENUM_SIGNAL_TYPE signal) = 0;
   
   // ═══════════════════════════════════════════════════════════
   // ATUALIZAÇÃO DE PARÂMETROS EM RUNTIME
   // ═══════════════════════════════════════════════════════════
   
   // Parâmetros "quentes" - não requerem reinicializar indicadores
   // Exemplos: limites (ADX min, RSI levels), distâncias, flags on/off
   virtual bool UpdateHotParameters() { return true; }  // Implementação opcional
   
   // Parâmetros "frios" - requerem reinicializar indicadores
   // Exemplos: períodos, métodos, timeframes
   virtual bool UpdateColdParameters() { return true; }  // Implementação opcional
   
   // ═══════════════════════════════════════════════════════════
   // CONTROLE DE ESTADO (working variables)
   // ═══════════════════════════════════════════════════════════
   
   void Enable() { m_isEnabled = true; }
   void Disable() { m_isEnabled = false; }
   bool IsEnabled() const { return m_isEnabled; }
   void SetEnabled(bool enabled) { m_isEnabled = enabled; }
   
   // ═══════════════════════════════════════════════════════════
   // GETTERS
   // ═══════════════════════════════════════════════════════════
   
   string GetName() const { return m_filterName; }
   bool IsInitialized() const { return m_isInitialized; }
};
