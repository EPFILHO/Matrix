//+------------------------------------------------------------------+
//|                                           StrategyPanelBase.mqh  |
//|                                         Copyright 2026, EP Filho |
//|         Interface base para sub-páginas de estratégia             |
//|                     Versão 1.05 - Claude Parte 033 (Claude Code) |
//+------------------------------------------------------------------+
// Incluído por Panel.mqh ANTES da definição de CEPBotPanel.
// Usa forward declaration para CEPBotPanel.
//
// Changelog: ver CHANGELOG.md
//+------------------------------------------------------------------+

// Forward declaration — CEPBotPanel é definido em Panel.mqh
class CEPBotPanel;

class CStrategyPanelBase
  {
protected:
   long              m_chart_id;
   int               m_subwin;
   CEPBotPanel      *m_parent;   // Referência ao painel principal (para prioridade etc.)
   bool              m_locked;    // true = EA rodando, Update() não sobrescreve visual
public:
   virtual          ~CStrategyPanelBase(void) {}
   virtual string    GetName(void) const = 0;
   virtual bool      Create(CEPBotPanel *parent, long chart_id, int subwin) = 0;
   virtual void      Show(void) = 0;
   virtual void      Hide(void) = 0;
   virtual void      Update(void) = 0;
   // Retorna true se o clique foi tratado por este painel
   virtual bool      OnClick(string name) = 0;
   // Valida + aplica nos módulos (chamado pelo INICIAR/SALVAR centralizado)
   virtual bool      Apply(string &outErr) = 0;
   // Habilita/desabilita edição dos controles
   virtual void      SetEnabled(bool enable) = 0;
   // Repopula campos GUI a partir do módulo (chamado após ApplyLoadedConfig)
   virtual void      Reload(void) {}
  };
//+------------------------------------------------------------------+
