//+------------------------------------------------------------------+
//|                                           StrategyPanelBase.mqh  |
//|                                         Copyright 2026, EP Filho |
//|         Interface base para sub-páginas de estratégia             |
//|                     Versão 1.01 - Claude Parte 027 (Claude Code) |
//+------------------------------------------------------------------+
// Incluído por Panel.mqh ANTES da definição de CEPBotPanel.
// Usa forward declaration para CEPBotPanel.
//+------------------------------------------------------------------+

// Forward declaration — CEPBotPanel é definido em Panel.mqh
class CEPBotPanel;

class CStrategyPanelBase
  {
protected:
   long              m_chart_id;
   int               m_subwin;
   CEPBotPanel      *m_parent;   // Referência ao painel principal (para prioridade etc.)
public:
   virtual          ~CStrategyPanelBase(void) {}
   virtual string    GetName(void) const = 0;
   virtual bool      Create(CEPBotPanel *parent, long chart_id, int subwin) = 0;
   virtual void      Show(void) = 0;
   virtual void      Hide(void) = 0;
   virtual void      Update(void) = 0;
   // Retorna true se o clique foi tratado por este painel
   virtual bool      OnClick(string name) = 0;
  };
//+------------------------------------------------------------------+
