//+------------------------------------------------------------------+
//|                                             FilterPanelBase.mqh  |
//|                                         Copyright 2026, EP Filho |
//|         Interface base para sub-páginas de filtro                 |
//|                     Versão 1.01 - Claude Parte 027 (Claude Code) |
//+------------------------------------------------------------------+
// Incluído por Panel.mqh ANTES da definição de CEPBotPanel.
// Usa forward declaration para CEPBotPanel.
//
// ═══════════════════════════════════════════════════════════════
// CHANGELOG
// ═══════════════════════════════════════════════════════════════
// v1.01 (Parte 027):
// + m_parent (CEPBotPanel*): referência ao painel principal
//   Necessário para persistência de config (acesso a helpers públicos)
//
// v1.00 (Parte 025):
// + Interface base CFilterPanelBase para sub-páginas de filtro
// ═══════════════════════════════════════════════════════════════
//+------------------------------------------------------------------+

// Forward declaration — CEPBotPanel é definido em Panel.mqh
class CEPBotPanel;

class CFilterPanelBase
  {
protected:
   CEPBotPanel      *m_parent;   // Referência ao painel principal (Parte 027: persistência)
   long              m_chart_id;
   int               m_subwin;
public:
   virtual          ~CFilterPanelBase(void) {}
   virtual string    GetName(void) const = 0;
   virtual bool      Create(CEPBotPanel *parent, long chart_id, int subwin) = 0;
   virtual void      Show(void) = 0;
   virtual void      Hide(void) = 0;
   virtual void      Update(void) = 0;
   // Retorna true se o clique foi tratado por este painel
   virtual bool      OnClick(string name) = 0;
  };
//+------------------------------------------------------------------+
