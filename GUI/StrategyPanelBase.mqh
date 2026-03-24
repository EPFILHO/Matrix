//+------------------------------------------------------------------+
//|                                           StrategyPanelBase.mqh  |
//|                                         Copyright 2026, EP Filho |
//|         Interface base para sub-páginas de estratégia             |
//|                     Versão 1.02 - Claude Parte 027 (Claude Code) |
//+------------------------------------------------------------------+
// Incluído por Panel.mqh ANTES da definição de CEPBotPanel.
// Usa forward declaration para CEPBotPanel.
//
// CHANGELOG v1.02 (Parte 027) — Fase 2: Controle de Estado:
// + Pure virtual Apply() e SetEnabled(bool) para controle centralizado
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
   // Valida + aplica nos módulos (chamado pelo INICIAR/SALVAR centralizado)
   virtual bool      Apply(void) = 0;
   // Habilita/desabilita edição dos controles
   virtual void      SetEnabled(bool enable) = 0;
  };
//+------------------------------------------------------------------+
