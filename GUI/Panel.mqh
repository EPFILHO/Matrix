//+------------------------------------------------------------------+
//|                                                       Panel.mqh  |
//|                                         Copyright 2026, EP Filho |
//|                          Painel GUI com Abas - EPBot Matrix      |
//|                     Versão 1.03 - Claude Parte 025 (Claude Code) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "1.03"
#property strict

// ═══════════════════════════════════════════════════════════════
// CHANGELOG
// ═══════════════════════════════════════════════════════════════
// v1.03 (2026-02-21):
// + Esconde botão X (m_button_close.Hide()) — previne fechar EA
// + Substitui todos CEdit de valor por CLabel — controle total
//   de cor, sem dependência do tema do SO, visual mais limpo
// + Melhora contraste: valores em branco, chaves em cinza médio
//
// v1.02 (2026-02-21):
// + Adiciona #include de Inputs.mqh (resolve inp_MagicNumber,
//   inp_TradeComment, inp_LotSize undeclared)
//
// v1.01 (2026-02-21):
// + Autocontido: adiciona #include das dependências do projeto
//   (Core, Strategy, Filters) — compilável standalone
//
// v1.00:
// + Painel GUI com 4 abas (STATUS, RESULTADOS, ESTRATEGIAS, CONFIG)
// + Tema escuro com cores semânticas (verde/vermelho/laranja)
// + Atualização por timer (1.5s) — apenas aba ativa
// + Módulo separado (GUI/Panel.mqh) — não interfere na lógica do EA
// + NULL-safe: módulos desabilitados exibem "Inativo"
// ═══════════════════════════════════════════════════════════════

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>

// Dependências do projeto (autocontido — compilável standalone)
#include "../Core/Inputs.mqh"
#include "../Core/Logger.mqh"
#include "../Core/Blockers.mqh"
#include "../Core/RiskManager.mqh"
#include "../Core/TradeManager.mqh"
#include "../Strategy/SignalManager.mqh"
#include "../Strategy/Strategies/MACrossStrategy.mqh"
#include "../Strategy/Strategies/RSIStrategy.mqh"
#include "../Strategy/Filters/TrendFilter.mqh"
#include "../Strategy/Filters/RSIFilter.mqh"

// ═══════════════════════════════════════════════════════════════
// DIMENSÕES E LAYOUT
// ═══════════════════════════════════════════════════════════════
#define PANEL_WIDTH          430
#define PANEL_HEIGHT         540

#define PANEL_GAP_Y          18
#define PANEL_GAP_SECTION    8

#define COL_LABEL_X          10
#define COL_VALUE_X          195
#define COL_VALUE_W          210

#define CONTENT_TOP          32
#define TAB_BTN_H            22

// ═══════════════════════════════════════════════════════════════
// CORES — TEMA ESCURO
// ═══════════════════════════════════════════════════════════════
#define CLR_TAB_ACTIVE       C'50,120,200'
#define CLR_TAB_INACTIVE     C'70,70,70'
#define CLR_TAB_TXT_ACT      clrWhite
#define CLR_TAB_TXT_INACT    C'190,190,190'
#define CLR_LABEL            C'150,150,150'
#define CLR_VALUE            clrWhite
#define CLR_POSITIVE         C'0,210,90'
#define CLR_NEGATIVE         C'230,70,70'
#define CLR_WARNING          C'255,190,0'
#define CLR_NEUTRAL          C'170,170,170'
#define CLR_HEADER           C'120,190,255'

// ═══════════════════════════════════════════════════════════════
// PREFIXO DE OBJETOS (evita colisão)
// ═══════════════════════════════════════════════════════════════
#define PFX "EPBM_"

// ═══════════════════════════════════════════════════════════════
// ENUM DE ABAS
// ═══════════════════════════════════════════════════════════════
enum ENUM_PANEL_TAB
  {
   TAB_STATUS = 0,
   TAB_RESULTADOS = 1,
   TAB_ESTRATEGIAS = 2,
   TAB_CONFIG = 3
  };

//+------------------------------------------------------------------+
//| Classe principal do painel                                        |
//+------------------------------------------------------------------+
class CEPBotPanel : public CAppDialog
  {
private:
   // ── Ponteiros dos módulos (read-only) ──
   CLogger           *m_logger;
   CBlockers         *m_blockers;
   CRiskManager      *m_riskManager;
   CTradeManager     *m_tradeManager;
   CSignalManager    *m_signalManager;
   CMACrossStrategy  *m_maCross;
   CRSIStrategy      *m_rsiStrategy;
   CTrendFilter      *m_trendFilter;
   CRSIFilter        *m_rsiFilter;

   // ── Estado ──
   ENUM_PANEL_TAB     m_activeTab;
   int                m_magicNumber;
   string             m_symbol;

   // ── Botões de aba ──
   CButton            m_btnTab0;
   CButton            m_btnTab1;
   CButton            m_btnTab2;
   CButton            m_btnTab3;

   // ════════════════════════════════════════
   // ABA 0: STATUS
   // ════════════════════════════════════════
   CLabel  m_s_hdr1;
   CLabel  m_s_lTrading;       CLabel  m_s_eTrading;
   CLabel  m_s_lBlocker;       CLabel  m_s_eBlocker;
   CLabel  m_s_lSpread;        CLabel  m_s_eSpread;
   CLabel  m_s_lTime;          CLabel  m_s_eTime;

   CLabel  m_s_hdr2;
   CLabel  m_s_lHasPos;        CLabel  m_s_eHasPos;
   CLabel  m_s_lTicket;        CLabel  m_s_eTicket;
   CLabel  m_s_lPosType;       CLabel  m_s_ePosType;
   CLabel  m_s_lPosProfit;     CLabel  m_s_ePosProfit;
   CLabel  m_s_lBE;            CLabel  m_s_eBE;
   CLabel  m_s_lTrail;         CLabel  m_s_eTrail;
   CLabel  m_s_lPartial;       CLabel  m_s_ePartial;

   CLabel  m_s_hdr3;
   CLabel  m_s_lSignal;        CLabel  m_s_eSignal;
   CLabel  m_s_lBlocked;       CLabel  m_s_eBlocked;

   // ════════════════════════════════════════
   // ABA 1: RESULTADOS
   // ════════════════════════════════════════
   CLabel  m_r_hdr1;
   CLabel  m_r_lProfit;        CLabel  m_r_eProfit;
   CLabel  m_r_lClosed;        CLabel  m_r_eClosed;
   CLabel  m_r_lPartial;       CLabel  m_r_ePartial;

   CLabel  m_r_hdr2;
   CLabel  m_r_lTrades;        CLabel  m_r_eTrades;
   CLabel  m_r_lWins;          CLabel  m_r_eWins;
   CLabel  m_r_lLosses;        CLabel  m_r_eLosses;
   CLabel  m_r_lDraws;         CLabel  m_r_eDraws;

   CLabel  m_r_hdr3;
   CLabel  m_r_lWinRate;       CLabel  m_r_eWinRate;
   CLabel  m_r_lPayoff;        CLabel  m_r_ePayoff;
   CLabel  m_r_lPF;            CLabel  m_r_ePF;

   CLabel  m_r_hdr4;
   CLabel  m_r_lDD;            CLabel  m_r_eDD;
   CLabel  m_r_lPeak;          CLabel  m_r_ePeak;
   CLabel  m_r_lLossStrk;      CLabel  m_r_eLossStrk;
   CLabel  m_r_lWinStrk;       CLabel  m_r_eWinStrk;

   // ════════════════════════════════════════
   // ABA 2: ESTRATEGIAS
   // ════════════════════════════════════════
   CLabel  m_e_hdr1;
   CLabel  m_e_lStratCnt;      CLabel  m_e_eStratCnt;
   CLabel  m_e_lFiltCnt;       CLabel  m_e_eFiltCnt;
   CLabel  m_e_lConflict;      CLabel  m_e_eConflict;

   CLabel  m_e_hdr2;
   CLabel  m_e_lMAStatus;      CLabel  m_e_eMAStatus;
   CLabel  m_e_lMAFast;        CLabel  m_e_eMAFast;
   CLabel  m_e_lMASlow;        CLabel  m_e_eMASlow;
   CLabel  m_e_lMACross;       CLabel  m_e_eMACross;
   CLabel  m_e_lMACandles;     CLabel  m_e_eMACandles;
   CLabel  m_e_lMAEntry;       CLabel  m_e_eMAEntry;
   CLabel  m_e_lMAExit;        CLabel  m_e_eMAExit;

   CLabel  m_e_hdr3;
   CLabel  m_e_lRSIStatus;     CLabel  m_e_eRSIStatus;
   CLabel  m_e_lRSICurr;       CLabel  m_e_eRSICurr;
   CLabel  m_e_lRSIMode;       CLabel  m_e_eRSIMode;
   CLabel  m_e_lRSILevels;     CLabel  m_e_eRSILevels;

   CLabel  m_e_hdr4;
   CLabel  m_e_lTrendSt;       CLabel  m_e_eTrendSt;
   CLabel  m_e_lTrendMA;       CLabel  m_e_eTrendMA;
   CLabel  m_e_lTrendDist;     CLabel  m_e_eTrendDist;

   CLabel  m_e_hdr5;
   CLabel  m_e_lRFiltSt;       CLabel  m_e_eRFiltSt;
   CLabel  m_e_lRFiltRSI;      CLabel  m_e_eRFiltRSI;
   CLabel  m_e_lRFiltMode;     CLabel  m_e_eRFiltMode;

   // ════════════════════════════════════════
   // ABA 3: CONFIG
   // ════════════════════════════════════════
   CLabel  m_c_hdr1;
   CLabel  m_c_lMagic;         CLabel  m_c_eMagic;
   CLabel  m_c_lComment;       CLabel  m_c_eComment;
   CLabel  m_c_lLot;           CLabel  m_c_eLot;

   CLabel  m_c_hdr2;
   CLabel  m_c_lSL;            CLabel  m_c_eSL;
   CLabel  m_c_lTP;            CLabel  m_c_eTP;
   CLabel  m_c_lTrail;         CLabel  m_c_eTrail;
   CLabel  m_c_lBE;            CLabel  m_c_eBE;
   CLabel  m_c_lPTP;           CLabel  m_c_ePTP;

   CLabel  m_c_hdr3;
   CLabel  m_c_lTimeF;         CLabel  m_c_eTimeF;
   CLabel  m_c_lMaxSpr;        CLabel  m_c_eMaxSpr;
   CLabel  m_c_lDaily;         CLabel  m_c_eDaily;
   CLabel  m_c_lStreak;        CLabel  m_c_eStreak;
   CLabel  m_c_lDrawdown;      CLabel  m_c_eDrawdown;
   CLabel  m_c_lDirection;     CLabel  m_c_eDirection;

   // ── Helpers privados ──
   bool              CreateLV(CLabel &lbl, CLabel &val, string ln, string en, string lt, int y);
   bool              CreateHdr(CLabel &lbl, string name, string text, int y);
   void              SetEV(CLabel &val, string value, color clr = CLR_VALUE);

   bool              CreateTabButtons(void);
   bool              CreateTabStatus(void);
   bool              CreateTabResultados(void);
   bool              CreateTabEstrategias(void);
   bool              CreateTabConfig(void);

   void              ShowTab(ENUM_PANEL_TAB tab);
   void              SetTabVis(ENUM_PANEL_TAB tab, bool vis);
   void              UpdateTabStyles(void);

   void              UpdateStatus(void);
   void              UpdateResultados(void);
   void              UpdateEstrategias(void);
   void              PopulateConfig(void);

   string            BlockerToStr(ENUM_BLOCKER_REASON r);

   // Handlers de clique das abas (usados pelo EVENT_MAP)
   void              OnClickTab0(void);
   void              OnClickTab1(void);
   void              OnClickTab2(void);
   void              OnClickTab3(void);

public:
                     CEPBotPanel(void);
                    ~CEPBotPanel(void);

   bool              Init(CLogger *logger, CBlockers *blockers, CRiskManager *risk,
                          CTradeManager *trade, CSignalManager *signal,
                          CMACrossStrategy *maCross, CRSIStrategy *rsi,
                          CTrendFilter *trend, CRSIFilter *rsiFilt,
                          int magic, string symbol);

   bool              CreatePanel(long chart, string name, int subwin,
                                 int x1, int y1, int x2, int y2);
   void              Update(void);

   virtual bool      OnEvent(const int id, const long &lparam,
                             const double &dparam, const string &sparam);
  };

//+------------------------------------------------------------------+
//| Construtor / Destrutor                                            |
//+------------------------------------------------------------------+
CEPBotPanel::CEPBotPanel(void)
   : m_activeTab(TAB_STATUS),
     m_logger(NULL), m_blockers(NULL), m_riskManager(NULL),
     m_tradeManager(NULL), m_signalManager(NULL),
     m_maCross(NULL), m_rsiStrategy(NULL),
     m_trendFilter(NULL), m_rsiFilter(NULL),
     m_magicNumber(0), m_symbol("")
  {
  }

CEPBotPanel::~CEPBotPanel(void)
  {
  }

//+------------------------------------------------------------------+
//| Init — recebe ponteiros de todos os módulos                       |
//+------------------------------------------------------------------+
bool CEPBotPanel::Init(CLogger *logger, CBlockers *blockers, CRiskManager *risk,
                       CTradeManager *trade, CSignalManager *signal,
                       CMACrossStrategy *maCross, CRSIStrategy *rsi,
                       CTrendFilter *trend, CRSIFilter *rsiFilt,
                       int magic, string symbol)
  {
   m_logger       = logger;
   m_blockers     = blockers;
   m_riskManager  = risk;
   m_tradeManager = trade;
   m_signalManager = signal;
   m_maCross      = maCross;
   m_rsiStrategy  = rsi;
   m_trendFilter  = trend;
   m_rsiFilter    = rsiFilt;
   m_magicNumber  = magic;
   m_symbol       = symbol;
   return true;
  }

//+------------------------------------------------------------------+
//| CreatePanel — cria janela e todos os controles                    |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreatePanel(long chart, string name, int subwin,
                              int x1, int y1, int x2, int y2)
  {
   if(!Create(chart, name, subwin, x1, y1, x2, y2))
      return false;

   m_button_close.Hide();   // X escondido — fecha apenas via OnDeinit do EA

   if(!CreateTabButtons())   return false;
   if(!CreateTabStatus())    return false;
   if(!CreateTabResultados()) return false;
   if(!CreateTabEstrategias()) return false;
   if(!CreateTabConfig())    return false;

   PopulateConfig();
   ShowTab(TAB_STATUS);
   return true;
  }

//+------------------------------------------------------------------+
//| HELPERS: CreateLV (Label + Value Edit), CreateHdr, SetEV          |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateLV(CLabel &lbl, CLabel &val,
                           string ln, string en, string lt, int y)
  {
   if(!lbl.Create(m_chart_id, PFX + ln, m_subwin,
                  COL_LABEL_X, y, COL_VALUE_X - 5, y + PANEL_GAP_Y))
      return false;
   lbl.Text(lt);
   lbl.Color(CLR_LABEL);
   lbl.FontSize(8);
   if(!Add(lbl))
      return false;

   if(!val.Create(m_chart_id, PFX + en, m_subwin,
                  COL_VALUE_X, y, COL_VALUE_X + COL_VALUE_W, y + PANEL_GAP_Y))
      return false;
   val.Text("--");
   val.Color(CLR_VALUE);
   val.FontSize(8);
   if(!Add(val))
      return false;

   return true;
  }

bool CEPBotPanel::CreateHdr(CLabel &lbl, string name, string text, int y)
  {
   if(!lbl.Create(m_chart_id, PFX + name, m_subwin,
                  COL_LABEL_X, y, COL_VALUE_X + COL_VALUE_W, y + PANEL_GAP_Y))
      return false;
   lbl.Text(text);
   lbl.Color(CLR_HEADER);
   lbl.FontSize(9);
   if(!Add(lbl))
      return false;
   return true;
  }

void CEPBotPanel::SetEV(CLabel &val, string value, color clr)
  {
   val.Text(value);
   val.Color(clr);
  }

//+------------------------------------------------------------------+
//| Botões de aba                                                     |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabButtons(void)
  {
   int w = (PANEL_WIDTH - 30) / 4;
   int y1 = 3, y2 = 3 + TAB_BTN_H;

   if(!m_btnTab0.Create(m_chart_id, PFX + "tab0", m_subwin, 5, y1, 5 + w, y2))
      return false;
   m_btnTab0.Text("STATUS");
   m_btnTab0.FontSize(8);
   if(!Add(m_btnTab0))
      return false;

   if(!m_btnTab1.Create(m_chart_id, PFX + "tab1", m_subwin, 5 + w + 2, y1, 5 + w * 2 + 2, y2))
      return false;
   m_btnTab1.Text("RESULTADOS");
   m_btnTab1.FontSize(8);
   if(!Add(m_btnTab1))
      return false;

   if(!m_btnTab2.Create(m_chart_id, PFX + "tab2", m_subwin, 5 + (w + 2) * 2, y1, 5 + w * 3 + 4, y2))
      return false;
   m_btnTab2.Text("ESTRATEGIAS");
   m_btnTab2.FontSize(7);
   if(!Add(m_btnTab2))
      return false;

   if(!m_btnTab3.Create(m_chart_id, PFX + "tab3", m_subwin, 5 + (w + 2) * 3, y1, 5 + w * 4 + 6, y2))
      return false;
   m_btnTab3.Text("CONFIG");
   m_btnTab3.FontSize(8);
   if(!Add(m_btnTab3))
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| EVENT MAP                                                         |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CEPBotPanel)
ON_EVENT(ON_CLICK, m_btnTab0, OnClickTab0)
ON_EVENT(ON_CLICK, m_btnTab1, OnClickTab1)
ON_EVENT(ON_CLICK, m_btnTab2, OnClickTab2)
ON_EVENT(ON_CLICK, m_btnTab3, OnClickTab3)
EVENT_MAP_END(CAppDialog)

// Handlers de clique das abas (declarados inline fora da classe via define)
void CEPBotPanel::OnClickTab0(void) { ShowTab(TAB_STATUS); }
void CEPBotPanel::OnClickTab1(void) { ShowTab(TAB_RESULTADOS); }
void CEPBotPanel::OnClickTab2(void) { ShowTab(TAB_ESTRATEGIAS); }
void CEPBotPanel::OnClickTab3(void) { ShowTab(TAB_CONFIG); }

//+------------------------------------------------------------------+
//| ABA 0: STATUS — Criar controles                                   |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabStatus(void)
  {
   int y = CONTENT_TOP;

   if(!CreateHdr(m_s_hdr1, "s_h1", "ESTADO DO SISTEMA", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_s_lTrading, m_s_eTrading, "s_lTr", "s_eTr", "Trading:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lBlocker, m_s_eBlocker, "s_lBl", "s_eBl", "Bloqueador:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lSpread, m_s_eSpread, "s_lSp", "s_eSp", "Spread:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lTime, m_s_eTime, "s_lTm", "s_eTm", "Horario:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_s_hdr2, "s_h2", "POSICAO", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_s_lHasPos, m_s_eHasPos, "s_lHP", "s_eHP", "Posicao Aberta:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lTicket, m_s_eTicket, "s_lTk", "s_eTk", "Ticket:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lPosType, m_s_ePosType, "s_lPT", "s_ePT", "Tipo:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lPosProfit, m_s_ePosProfit, "s_lPP", "s_ePP", "P/L Flutuante:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lBE, m_s_eBE, "s_lBE", "s_eBE", "Breakeven:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lTrail, m_s_eTrail, "s_lTl", "s_eTl", "Trailing:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lPartial, m_s_ePartial, "s_lPt", "s_ePt", "Partial TP:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_s_hdr3, "s_h3", "SINAIS", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_s_lSignal, m_s_eSignal, "s_lSg", "s_eSg", "Ultimo Sinal:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_s_lBlocked, m_s_eBlocked, "s_lBk", "s_eBk", "Bloqueado por:", y)) return false;

   return true;
  }

//+------------------------------------------------------------------+
//| ABA 1: RESULTADOS — Criar controles                               |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabResultados(void)
  {
   int y = CONTENT_TOP;

   if(!CreateHdr(m_r_hdr1, "r_h1", "RESULTADO FINANCEIRO", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_r_lProfit, m_r_eProfit, "r_lPr", "r_ePr", "P/L Total Dia:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lClosed, m_r_eClosed, "r_lCl", "r_eCl", "P/L Trades Fechados:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lPartial, m_r_ePartial, "r_lPt", "r_ePt", "P/L TPs Parciais:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_r_hdr2, "r_h2", "TRADES DO DIA", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_r_lTrades, m_r_eTrades, "r_lTd", "r_eTd", "Total Trades:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lWins, m_r_eWins, "r_lWn", "r_eWn", "Ganhos:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lLosses, m_r_eLosses, "r_lLs", "r_eLs", "Perdas:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lDraws, m_r_eDraws, "r_lDr", "r_eDr", "Empates:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_r_hdr3, "r_h3", "METRICAS", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_r_lWinRate, m_r_eWinRate, "r_lWR", "r_eWR", "Win Rate:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lPayoff, m_r_ePayoff, "r_lPO", "r_ePO", "Payoff Ratio:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lPF, m_r_ePF, "r_lPF", "r_ePF", "Profit Factor:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_r_hdr4, "r_h4", "PROTECAO", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_r_lDD, m_r_eDD, "r_lDD", "r_eDD", "Drawdown Atual:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lPeak, m_r_ePeak, "r_lPk", "r_ePk", "Pico Lucro Dia:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lLossStrk, m_r_eLossStrk, "r_lLS", "r_eLS", "Seq. Perdas:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_r_lWinStrk, m_r_eWinStrk, "r_lWS", "r_eWS", "Seq. Ganhos:", y)) return false;

   return true;
  }

//+------------------------------------------------------------------+
//| ABA 2: ESTRATEGIAS — Criar controles                              |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabEstrategias(void)
  {
   int y = CONTENT_TOP;

   if(!CreateHdr(m_e_hdr1, "e_h1", "SIGNAL MANAGER", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_e_lStratCnt, m_e_eStratCnt, "e_lSC", "e_eSC", "Estrategias:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lFiltCnt, m_e_eFiltCnt, "e_lFC", "e_eFC", "Filtros:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lConflict, m_e_eConflict, "e_lCf", "e_eCf", "Modo Conflito:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_e_hdr2, "e_h2", "MA CROSS STRATEGY", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_e_lMAStatus, m_e_eMAStatus, "e_lMS", "e_eMS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMAFast, m_e_eMAFast, "e_lMF", "e_eMF", "MA Rapida:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMASlow, m_e_eMASlow, "e_lML", "e_eML", "MA Lenta:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMACross, m_e_eMACross, "e_lMC", "e_eMC", "Ultimo Cruz.:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMACandles, m_e_eMACandles, "e_lMN", "e_eMN", "Candles Apos:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMAEntry, m_e_eMAEntry, "e_lME", "e_eME", "Entrada:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lMAExit, m_e_eMAExit, "e_lMX", "e_eMX", "Saida:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_e_hdr3, "e_h3", "RSI STRATEGY", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_e_lRSIStatus, m_e_eRSIStatus, "e_lRS", "e_eRS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRSICurr, m_e_eRSICurr, "e_lRC", "e_eRC", "RSI Atual:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRSIMode, m_e_eRSIMode, "e_lRM", "e_eRM", "Modo:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRSILevels, m_e_eRSILevels, "e_lRL", "e_eRL", "Niveis:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_e_hdr4, "e_h4", "TREND FILTER", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_e_lTrendSt, m_e_eTrendSt, "e_lTS", "e_eTS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lTrendMA, m_e_eTrendMA, "e_lTM", "e_eTM", "MA Tendencia:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lTrendDist, m_e_eTrendDist, "e_lTD", "e_eTD", "Distancia:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_e_hdr5, "e_h5", "RSI FILTER", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_e_lRFiltSt, m_e_eRFiltSt, "e_lFS", "e_eFS", "Status:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRFiltRSI, m_e_eRFiltRSI, "e_lFR", "e_eFR", "RSI Atual:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_e_lRFiltMode, m_e_eRFiltMode, "e_lFM", "e_eFM", "Modo:", y)) return false;

   return true;
  }

//+------------------------------------------------------------------+
//| ABA 3: CONFIG — Criar controles (valores estáticos)               |
//+------------------------------------------------------------------+
bool CEPBotPanel::CreateTabConfig(void)
  {
   int y = CONTENT_TOP;

   if(!CreateHdr(m_c_hdr1, "c_h1", "GERAL", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_c_lMagic, m_c_eMagic, "c_lMg", "c_eMg", "Magic Number:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_c_lComment, m_c_eComment, "c_lCm", "c_eCm", "Comentario:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_c_lLot, m_c_eLot, "c_lLt", "c_eLt", "Lote:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_c_hdr2, "c_h2", "RISCO", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_c_lSL, m_c_eSL, "c_lSL", "c_eSL", "Stop Loss:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_c_lTP, m_c_eTP, "c_lTP", "c_eTP", "Take Profit:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_c_lTrail, m_c_eTrail, "c_lTl", "c_eTl", "Trailing:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_c_lBE, m_c_eBE, "c_lBE", "c_eBE", "Breakeven:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_c_lPTP, m_c_ePTP, "c_lPT", "c_ePT", "Partial TP:", y)) return false;

   y += PANEL_GAP_Y + PANEL_GAP_SECTION;
   if(!CreateHdr(m_c_hdr3, "c_h3", "BLOQUEIOS", y)) return false;
   y += PANEL_GAP_Y + 2;
   if(!CreateLV(m_c_lTimeF, m_c_eTimeF, "c_lTF", "c_eTF", "Horario:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_c_lMaxSpr, m_c_eMaxSpr, "c_lMS", "c_eMS2", "Max Spread:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_c_lDaily, m_c_eDaily, "c_lDy", "c_eDy", "Limites Diarios:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_c_lStreak, m_c_eStreak, "c_lSk", "c_eSk", "Streaks:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_c_lDrawdown, m_c_eDrawdown, "c_lDd", "c_eDd", "Drawdown:", y)) return false;
   y += PANEL_GAP_Y;
   if(!CreateLV(m_c_lDirection, m_c_eDirection, "c_lDr", "c_eDr", "Direcao:", y)) return false;

   return true;
  }

//+------------------------------------------------------------------+
//| ShowTab — alterna a visibilidade das abas                         |
//+------------------------------------------------------------------+
void CEPBotPanel::ShowTab(ENUM_PANEL_TAB tab)
  {
   // Esconder todas
   SetTabVis(TAB_STATUS, false);
   SetTabVis(TAB_RESULTADOS, false);
   SetTabVis(TAB_ESTRATEGIAS, false);
   SetTabVis(TAB_CONFIG, false);

   // Mostrar a selecionada
   m_activeTab = tab;
   SetTabVis(tab, true);
   UpdateTabStyles();

   // Atualizar dados imediatamente
   switch(tab)
     {
      case TAB_STATUS:      UpdateStatus();      break;
      case TAB_RESULTADOS:  UpdateResultados();   break;
      case TAB_ESTRATEGIAS: UpdateEstrategias();  break;
      case TAB_CONFIG:      /* estático */        break;
     }
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| SetTabVis — show/hide todos controles de uma aba                  |
//+------------------------------------------------------------------+
void CEPBotPanel::SetTabVis(ENUM_PANEL_TAB tab, bool vis)
  {
   switch(tab)
     {
      case TAB_STATUS:
        {
         if(vis) { m_s_hdr1.Show(); m_s_lTrading.Show(); m_s_eTrading.Show();
                    m_s_lBlocker.Show(); m_s_eBlocker.Show(); m_s_lSpread.Show(); m_s_eSpread.Show();
                    m_s_lTime.Show(); m_s_eTime.Show();
                    m_s_hdr2.Show(); m_s_lHasPos.Show(); m_s_eHasPos.Show();
                    m_s_lTicket.Show(); m_s_eTicket.Show(); m_s_lPosType.Show(); m_s_ePosType.Show();
                    m_s_lPosProfit.Show(); m_s_ePosProfit.Show(); m_s_lBE.Show(); m_s_eBE.Show();
                    m_s_lTrail.Show(); m_s_eTrail.Show(); m_s_lPartial.Show(); m_s_ePartial.Show();
                    m_s_hdr3.Show(); m_s_lSignal.Show(); m_s_eSignal.Show();
                    m_s_lBlocked.Show(); m_s_eBlocked.Show(); }
         else    { m_s_hdr1.Hide(); m_s_lTrading.Hide(); m_s_eTrading.Hide();
                    m_s_lBlocker.Hide(); m_s_eBlocker.Hide(); m_s_lSpread.Hide(); m_s_eSpread.Hide();
                    m_s_lTime.Hide(); m_s_eTime.Hide();
                    m_s_hdr2.Hide(); m_s_lHasPos.Hide(); m_s_eHasPos.Hide();
                    m_s_lTicket.Hide(); m_s_eTicket.Hide(); m_s_lPosType.Hide(); m_s_ePosType.Hide();
                    m_s_lPosProfit.Hide(); m_s_ePosProfit.Hide(); m_s_lBE.Hide(); m_s_eBE.Hide();
                    m_s_lTrail.Hide(); m_s_eTrail.Hide(); m_s_lPartial.Hide(); m_s_ePartial.Hide();
                    m_s_hdr3.Hide(); m_s_lSignal.Hide(); m_s_eSignal.Hide();
                    m_s_lBlocked.Hide(); m_s_eBlocked.Hide(); }
         break;
        }
      case TAB_RESULTADOS:
        {
         if(vis) { m_r_hdr1.Show(); m_r_lProfit.Show(); m_r_eProfit.Show();
                    m_r_lClosed.Show(); m_r_eClosed.Show(); m_r_lPartial.Show(); m_r_ePartial.Show();
                    m_r_hdr2.Show(); m_r_lTrades.Show(); m_r_eTrades.Show();
                    m_r_lWins.Show(); m_r_eWins.Show(); m_r_lLosses.Show(); m_r_eLosses.Show();
                    m_r_lDraws.Show(); m_r_eDraws.Show();
                    m_r_hdr3.Show(); m_r_lWinRate.Show(); m_r_eWinRate.Show();
                    m_r_lPayoff.Show(); m_r_ePayoff.Show(); m_r_lPF.Show(); m_r_ePF.Show();
                    m_r_hdr4.Show(); m_r_lDD.Show(); m_r_eDD.Show();
                    m_r_lPeak.Show(); m_r_ePeak.Show();
                    m_r_lLossStrk.Show(); m_r_eLossStrk.Show();
                    m_r_lWinStrk.Show(); m_r_eWinStrk.Show(); }
         else    { m_r_hdr1.Hide(); m_r_lProfit.Hide(); m_r_eProfit.Hide();
                    m_r_lClosed.Hide(); m_r_eClosed.Hide(); m_r_lPartial.Hide(); m_r_ePartial.Hide();
                    m_r_hdr2.Hide(); m_r_lTrades.Hide(); m_r_eTrades.Hide();
                    m_r_lWins.Hide(); m_r_eWins.Hide(); m_r_lLosses.Hide(); m_r_eLosses.Hide();
                    m_r_lDraws.Hide(); m_r_eDraws.Hide();
                    m_r_hdr3.Hide(); m_r_lWinRate.Hide(); m_r_eWinRate.Hide();
                    m_r_lPayoff.Hide(); m_r_ePayoff.Hide(); m_r_lPF.Hide(); m_r_ePF.Hide();
                    m_r_hdr4.Hide(); m_r_lDD.Hide(); m_r_eDD.Hide();
                    m_r_lPeak.Hide(); m_r_ePeak.Hide();
                    m_r_lLossStrk.Hide(); m_r_eLossStrk.Hide();
                    m_r_lWinStrk.Hide(); m_r_eWinStrk.Hide(); }
         break;
        }
      case TAB_ESTRATEGIAS:
        {
         if(vis) { m_e_hdr1.Show(); m_e_lStratCnt.Show(); m_e_eStratCnt.Show();
                    m_e_lFiltCnt.Show(); m_e_eFiltCnt.Show(); m_e_lConflict.Show(); m_e_eConflict.Show();
                    m_e_hdr2.Show(); m_e_lMAStatus.Show(); m_e_eMAStatus.Show();
                    m_e_lMAFast.Show(); m_e_eMAFast.Show(); m_e_lMASlow.Show(); m_e_eMASlow.Show();
                    m_e_lMACross.Show(); m_e_eMACross.Show(); m_e_lMACandles.Show(); m_e_eMACandles.Show();
                    m_e_lMAEntry.Show(); m_e_eMAEntry.Show(); m_e_lMAExit.Show(); m_e_eMAExit.Show();
                    m_e_hdr3.Show(); m_e_lRSIStatus.Show(); m_e_eRSIStatus.Show();
                    m_e_lRSICurr.Show(); m_e_eRSICurr.Show(); m_e_lRSIMode.Show(); m_e_eRSIMode.Show();
                    m_e_lRSILevels.Show(); m_e_eRSILevels.Show();
                    m_e_hdr4.Show(); m_e_lTrendSt.Show(); m_e_eTrendSt.Show();
                    m_e_lTrendMA.Show(); m_e_eTrendMA.Show(); m_e_lTrendDist.Show(); m_e_eTrendDist.Show();
                    m_e_hdr5.Show(); m_e_lRFiltSt.Show(); m_e_eRFiltSt.Show();
                    m_e_lRFiltRSI.Show(); m_e_eRFiltRSI.Show(); m_e_lRFiltMode.Show(); m_e_eRFiltMode.Show(); }
         else    { m_e_hdr1.Hide(); m_e_lStratCnt.Hide(); m_e_eStratCnt.Hide();
                    m_e_lFiltCnt.Hide(); m_e_eFiltCnt.Hide(); m_e_lConflict.Hide(); m_e_eConflict.Hide();
                    m_e_hdr2.Hide(); m_e_lMAStatus.Hide(); m_e_eMAStatus.Hide();
                    m_e_lMAFast.Hide(); m_e_eMAFast.Hide(); m_e_lMASlow.Hide(); m_e_eMASlow.Hide();
                    m_e_lMACross.Hide(); m_e_eMACross.Hide(); m_e_lMACandles.Hide(); m_e_eMACandles.Hide();
                    m_e_lMAEntry.Hide(); m_e_eMAEntry.Hide(); m_e_lMAExit.Hide(); m_e_eMAExit.Hide();
                    m_e_hdr3.Hide(); m_e_lRSIStatus.Hide(); m_e_eRSIStatus.Hide();
                    m_e_lRSICurr.Hide(); m_e_eRSICurr.Hide(); m_e_lRSIMode.Hide(); m_e_eRSIMode.Hide();
                    m_e_lRSILevels.Hide(); m_e_eRSILevels.Hide();
                    m_e_hdr4.Hide(); m_e_lTrendSt.Hide(); m_e_eTrendSt.Hide();
                    m_e_lTrendMA.Hide(); m_e_eTrendMA.Hide(); m_e_lTrendDist.Hide(); m_e_eTrendDist.Hide();
                    m_e_hdr5.Hide(); m_e_lRFiltSt.Hide(); m_e_eRFiltSt.Hide();
                    m_e_lRFiltRSI.Hide(); m_e_eRFiltRSI.Hide(); m_e_lRFiltMode.Hide(); m_e_eRFiltMode.Hide(); }
         break;
        }
      case TAB_CONFIG:
        {
         if(vis) { m_c_hdr1.Show(); m_c_lMagic.Show(); m_c_eMagic.Show();
                    m_c_lComment.Show(); m_c_eComment.Show(); m_c_lLot.Show(); m_c_eLot.Show();
                    m_c_hdr2.Show(); m_c_lSL.Show(); m_c_eSL.Show();
                    m_c_lTP.Show(); m_c_eTP.Show(); m_c_lTrail.Show(); m_c_eTrail.Show();
                    m_c_lBE.Show(); m_c_eBE.Show(); m_c_lPTP.Show(); m_c_ePTP.Show();
                    m_c_hdr3.Show(); m_c_lTimeF.Show(); m_c_eTimeF.Show();
                    m_c_lMaxSpr.Show(); m_c_eMaxSpr.Show(); m_c_lDaily.Show(); m_c_eDaily.Show();
                    m_c_lStreak.Show(); m_c_eStreak.Show();
                    m_c_lDrawdown.Show(); m_c_eDrawdown.Show();
                    m_c_lDirection.Show(); m_c_eDirection.Show(); }
         else    { m_c_hdr1.Hide(); m_c_lMagic.Hide(); m_c_eMagic.Hide();
                    m_c_lComment.Hide(); m_c_eComment.Hide(); m_c_lLot.Hide(); m_c_eLot.Hide();
                    m_c_hdr2.Hide(); m_c_lSL.Hide(); m_c_eSL.Hide();
                    m_c_lTP.Hide(); m_c_eTP.Hide(); m_c_lTrail.Hide(); m_c_eTrail.Hide();
                    m_c_lBE.Hide(); m_c_eBE.Hide(); m_c_lPTP.Hide(); m_c_ePTP.Hide();
                    m_c_hdr3.Hide(); m_c_lTimeF.Hide(); m_c_eTimeF.Hide();
                    m_c_lMaxSpr.Hide(); m_c_eMaxSpr.Hide(); m_c_lDaily.Hide(); m_c_eDaily.Hide();
                    m_c_lStreak.Hide(); m_c_eStreak.Hide();
                    m_c_lDrawdown.Hide(); m_c_eDrawdown.Hide();
                    m_c_lDirection.Hide(); m_c_eDirection.Hide(); }
         break;
        }
     }
  }

//+------------------------------------------------------------------+
//| Atualizar estilo dos botões de aba                                |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateTabStyles(void)
  {
   m_btnTab0.ColorBackground((m_activeTab == TAB_STATUS)      ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
   m_btnTab1.ColorBackground((m_activeTab == TAB_RESULTADOS)  ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
   m_btnTab2.ColorBackground((m_activeTab == TAB_ESTRATEGIAS) ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
   m_btnTab3.ColorBackground((m_activeTab == TAB_CONFIG)      ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);

   m_btnTab0.Color((m_activeTab == TAB_STATUS)      ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_btnTab1.Color((m_activeTab == TAB_RESULTADOS)  ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_btnTab2.Color((m_activeTab == TAB_ESTRATEGIAS) ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_btnTab3.Color((m_activeTab == TAB_CONFIG)      ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
  }

//+------------------------------------------------------------------+
//| Update — chamado pelo timer, atualiza apenas a aba ativa          |
//+------------------------------------------------------------------+
void CEPBotPanel::Update(void)
  {
   switch(m_activeTab)
     {
      case TAB_STATUS:      UpdateStatus();      break;
      case TAB_RESULTADOS:  UpdateResultados();   break;
      case TAB_ESTRATEGIAS: UpdateEstrategias();  break;
      case TAB_CONFIG:      /* estático */        break;
     }
  }

//+------------------------------------------------------------------+
//| UpdateStatus — aba 0                                              |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateStatus(void)
  {
// ── Estado do Sistema ──
   if(m_blockers != NULL)
     {
      string blockReason = "";
      bool blocked = !m_blockers.CanTrade(
                        (m_logger != NULL) ? m_logger.GetDailyTrades() : 0,
                        (m_logger != NULL) ? m_logger.GetDailyProfit() : 0,
                        blockReason);

      SetEV(m_s_eTrading, blocked ? "BLOQUEADO" : "Permitido",
            blocked ? CLR_NEGATIVE : CLR_POSITIVE);
      SetEV(m_s_eBlocker, blocked ? BlockerToStr(m_blockers.GetActiveBlocker()) : "Nenhum",
            blocked ? CLR_WARNING : CLR_NEUTRAL);

      int spread = (int)SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
      int maxSpr = m_blockers.GetMaxSpread();
      string sprTxt = IntegerToString(spread) + (maxSpr > 0 ? " / Max: " + IntegerToString(maxSpr) : "");
      SetEV(m_s_eSpread, sprTxt, (maxSpr > 0 && spread > maxSpr) ? CLR_NEGATIVE : CLR_VALUE);

      MqlDateTime tm;
      TimeCurrent(tm);
      SetEV(m_s_eTime, StringFormat("%02d:%02d:%02d", tm.hour, tm.min, tm.sec), CLR_VALUE);
     }
   else
     {
      SetEV(m_s_eTrading, "N/A", CLR_NEUTRAL);
      SetEV(m_s_eBlocker, "N/A", CLR_NEUTRAL);
      SetEV(m_s_eSpread, "N/A", CLR_NEUTRAL);
      SetEV(m_s_eTime, "N/A", CLR_NEUTRAL);
     }

// ── Posição ──
   bool hasPos = false;
   ulong posTicket = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != m_symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != m_magicNumber)
         continue;
      hasPos = true;
      posTicket = PositionGetTicket(i);
      break;
     }

   if(hasPos && PositionSelectByTicket(posTicket))
     {
      ENUM_POSITION_TYPE pt = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

      SetEV(m_s_eHasPos, "Sim", CLR_POSITIVE);
      SetEV(m_s_eTicket, "#" + IntegerToString((long)posTicket), CLR_VALUE);
      SetEV(m_s_ePosType, (pt == POSITION_TYPE_BUY) ? "BUY" : "SELL",
            (pt == POSITION_TYPE_BUY) ? CLR_POSITIVE : CLR_NEGATIVE);
      SetEV(m_s_ePosProfit, "$" + DoubleToString(profit, 2),
            (profit > 0.01) ? CLR_POSITIVE : (profit < -0.01) ? CLR_NEGATIVE : CLR_VALUE);

      if(m_tradeManager != NULL)
        {
         SetEV(m_s_eBE, m_tradeManager.IsBreakevenActivated(posTicket) ? "Ativado" : "Pendente",
               m_tradeManager.IsBreakevenActivated(posTicket) ? CLR_POSITIVE : CLR_NEUTRAL);
         SetEV(m_s_eTrail, m_tradeManager.IsTrailingActive(posTicket) ? "Ativo" : "Inativo",
               m_tradeManager.IsTrailingActive(posTicket) ? CLR_POSITIVE : CLR_NEUTRAL);

         bool tp1 = m_tradeManager.IsTP1Executed(posTicket);
         bool tp2 = m_tradeManager.IsTP2Executed(posTicket);
         string tpTxt = tp1 ? (tp2 ? "TP1+TP2 OK" : "TP1 OK") : "Pendente";
         SetEV(m_s_ePartial, tpTxt, tp1 ? CLR_POSITIVE : CLR_NEUTRAL);
        }
      else
        {
         SetEV(m_s_eBE, "--", CLR_NEUTRAL);
         SetEV(m_s_eTrail, "--", CLR_NEUTRAL);
         SetEV(m_s_ePartial, "--", CLR_NEUTRAL);
        }
     }
   else
     {
      SetEV(m_s_eHasPos, "Nao", CLR_NEUTRAL);
      SetEV(m_s_eTicket, "--", CLR_NEUTRAL);
      SetEV(m_s_ePosType, "--", CLR_NEUTRAL);
      SetEV(m_s_ePosProfit, "--", CLR_NEUTRAL);
      SetEV(m_s_eBE, "--", CLR_NEUTRAL);
      SetEV(m_s_eTrail, "--", CLR_NEUTRAL);
      SetEV(m_s_ePartial, "--", CLR_NEUTRAL);
     }

// ── Sinais ──
   if(m_signalManager != NULL)
     {
      string src = m_signalManager.GetLastSignalSource();
      string blk = m_signalManager.GetLastBlockedBy();
      SetEV(m_s_eSignal, (src != "") ? src : "Nenhum", (src != "") ? CLR_VALUE : CLR_NEUTRAL);
      SetEV(m_s_eBlocked, (blk != "") ? blk : "Nenhum", (blk != "") ? CLR_WARNING : CLR_NEUTRAL);
     }
   else
     {
      SetEV(m_s_eSignal, "N/A", CLR_NEUTRAL);
      SetEV(m_s_eBlocked, "N/A", CLR_NEUTRAL);
     }
  }

//+------------------------------------------------------------------+
//| UpdateResultados — aba 1                                          |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateResultados(void)
  {
   if(m_logger == NULL)
      return;

// ── Financeiro ──
   double totalProfit = m_logger.GetDailyProfit();
   double closedProfit = m_logger.GetClosedTradesProfit();
   double partialProfit = m_logger.GetPartialTPProfit();

   SetEV(m_r_eProfit, "$" + DoubleToString(totalProfit, 2),
         (totalProfit > 0.01) ? CLR_POSITIVE : (totalProfit < -0.01) ? CLR_NEGATIVE : CLR_VALUE);
   SetEV(m_r_eClosed, "$" + DoubleToString(closedProfit, 2),
         (closedProfit > 0.01) ? CLR_POSITIVE : (closedProfit < -0.01) ? CLR_NEGATIVE : CLR_VALUE);
   SetEV(m_r_ePartial, "$" + DoubleToString(partialProfit, 2),
         (partialProfit > 0.01) ? CLR_POSITIVE : CLR_NEUTRAL);

// ── Trades ──
   int trades = m_logger.GetDailyTrades();
   int wins   = m_logger.GetDailyWins();
   int losses = m_logger.GetDailyLosses();
   int draws  = m_logger.GetDailyDraws();

   SetEV(m_r_eTrades, IntegerToString(trades), CLR_VALUE);
   SetEV(m_r_eWins, IntegerToString(wins), CLR_POSITIVE);
   SetEV(m_r_eLosses, IntegerToString(losses), (losses > 0) ? CLR_NEGATIVE : CLR_VALUE);
   SetEV(m_r_eDraws, IntegerToString(draws), CLR_NEUTRAL);

// ── Métricas ──
   double winRate = (wins + losses > 0) ? (double)wins / (wins + losses) * 100.0 : 0;
   double grossP = m_logger.GetGrossProfit();
   double grossL = m_logger.GetGrossLoss();
   double avgWin  = (wins > 0) ? grossP / wins : 0;
   double avgLoss = (losses > 0) ? grossL / losses : 0;
   double payoff = (avgLoss > 0) ? avgWin / avgLoss : 0;
   double pf = (grossL > 0) ? grossP / grossL : 0;

   SetEV(m_r_eWinRate, DoubleToString(winRate, 1) + "%",
         (winRate >= 50) ? CLR_POSITIVE : (winRate >= 30) ? CLR_WARNING : CLR_NEGATIVE);
   SetEV(m_r_ePayoff, DoubleToString(payoff, 2),
         (payoff >= 1.5) ? CLR_POSITIVE : (payoff >= 1.0) ? CLR_WARNING : CLR_NEUTRAL);
   SetEV(m_r_ePF, (grossL > 0) ? DoubleToString(pf, 2) : (grossP > 0) ? "INF" : "0.00",
         (pf >= 1.5) ? CLR_POSITIVE : (pf >= 1.0) ? CLR_WARNING : CLR_NEGATIVE);

// ── Proteção ──
   if(m_blockers != NULL)
     {
      double dd = m_blockers.GetCurrentDrawdown();
      double peak = m_blockers.GetDailyPeakProfit();
      int lossStrk = m_blockers.GetCurrentLossStreak();
      int winStrk  = m_blockers.GetCurrentWinStreak();

      SetEV(m_r_eDD, DoubleToString(dd, 2) + "%",
            (dd == 0) ? CLR_POSITIVE : (dd > 50) ? CLR_NEGATIVE : CLR_WARNING);
      SetEV(m_r_ePeak, "$" + DoubleToString(peak, 2), CLR_VALUE);
      SetEV(m_r_eLossStrk, IntegerToString(lossStrk), (lossStrk >= 3) ? CLR_NEGATIVE : CLR_VALUE);
      SetEV(m_r_eWinStrk, IntegerToString(winStrk), (winStrk >= 3) ? CLR_POSITIVE : CLR_VALUE);
     }
  }

//+------------------------------------------------------------------+
//| UpdateEstrategias — aba 2                                         |
//+------------------------------------------------------------------+
void CEPBotPanel::UpdateEstrategias(void)
  {
// ── Signal Manager ──
   if(m_signalManager != NULL)
     {
      SetEV(m_e_eStratCnt, IntegerToString(m_signalManager.GetStrategyCount()), CLR_VALUE);
      SetEV(m_e_eFiltCnt, IntegerToString(m_signalManager.GetFilterCount()), CLR_VALUE);
      string cm = (m_signalManager.GetConflictMode() == CONFLICT_PRIORITY) ? "Prioridade" : "Cancelar";
      SetEV(m_e_eConflict, cm, CLR_VALUE);
     }

// ── MA Cross ──
   if(m_maCross != NULL && m_maCross.IsInitialized())
     {
      SetEV(m_e_eMAStatus, "Ativo (P:" + IntegerToString(m_maCross.GetPriority()) + ")", CLR_POSITIVE);
      SetEV(m_e_eMAFast, DoubleToString(m_maCross.GetMAFast(), _Digits), CLR_VALUE);
      SetEV(m_e_eMASlow, DoubleToString(m_maCross.GetMASlow(), _Digits), CLR_VALUE);

      ENUM_SIGNAL_TYPE lastCross = m_maCross.GetLastCross();
      string crossTxt = (lastCross == SIGNAL_BUY) ? "BUY" : (lastCross == SIGNAL_SELL) ? "SELL" : "Nenhum";
      color crossClr = (lastCross == SIGNAL_BUY) ? CLR_POSITIVE : (lastCross == SIGNAL_SELL) ? CLR_NEGATIVE : CLR_NEUTRAL;
      SetEV(m_e_eMACross, crossTxt, crossClr);
      SetEV(m_e_eMACandles, IntegerToString(m_maCross.GetCandlesAfterCross()), CLR_VALUE);

      string entryTxt = (m_maCross.GetEntryMode() == ENTRY_NEXT_CANDLE) ? "Next Candle" : "2nd Candle";
      SetEV(m_e_eMAEntry, entryTxt, CLR_VALUE);

      ENUM_EXIT_MODE em = m_maCross.GetExitMode();
      string exitTxt = (em == EXIT_FCO) ? "FCO" : (em == EXIT_VM) ? "VM" : "TP/SL";
      SetEV(m_e_eMAExit, exitTxt, CLR_VALUE);
     }
   else
     {
      SetEV(m_e_eMAStatus, "Inativo", CLR_NEUTRAL);
      SetEV(m_e_eMAFast, "--", CLR_NEUTRAL);
      SetEV(m_e_eMASlow, "--", CLR_NEUTRAL);
      SetEV(m_e_eMACross, "--", CLR_NEUTRAL);
      SetEV(m_e_eMACandles, "--", CLR_NEUTRAL);
      SetEV(m_e_eMAEntry, "--", CLR_NEUTRAL);
      SetEV(m_e_eMAExit, "--", CLR_NEUTRAL);
     }

// ── RSI Strategy ──
   if(m_rsiStrategy != NULL && m_rsiStrategy.IsInitialized())
     {
      SetEV(m_e_eRSIStatus, "Ativo (P:" + IntegerToString(m_rsiStrategy.GetPriority()) + ")", CLR_POSITIVE);
      SetEV(m_e_eRSICurr, DoubleToString(m_rsiStrategy.GetCurrentRSI(), 1), CLR_VALUE);
      SetEV(m_e_eRSIMode, m_rsiStrategy.GetSignalModeText(), CLR_VALUE);
      SetEV(m_e_eRSILevels, DoubleToString(m_rsiStrategy.GetOversold(), 0) + " / " +
            DoubleToString(m_rsiStrategy.GetOverbought(), 0), CLR_VALUE);
     }
   else
     {
      SetEV(m_e_eRSIStatus, "Inativo", CLR_NEUTRAL);
      SetEV(m_e_eRSICurr, "--", CLR_NEUTRAL);
      SetEV(m_e_eRSIMode, "--", CLR_NEUTRAL);
      SetEV(m_e_eRSILevels, "--", CLR_NEUTRAL);
     }

// ── Trend Filter ──
   if(m_trendFilter != NULL && m_trendFilter.IsInitialized())
     {
      SetEV(m_e_eTrendSt, m_trendFilter.IsTrendFilterActive() ? "Ativo" : "Inativo",
            m_trendFilter.IsTrendFilterActive() ? CLR_POSITIVE : CLR_NEUTRAL);
      SetEV(m_e_eTrendMA, DoubleToString(m_trendFilter.GetMA(), _Digits), CLR_VALUE);
      SetEV(m_e_eTrendDist, DoubleToString(m_trendFilter.GetDistanceFromMA(), 1) + " pts", CLR_VALUE);
     }
   else
     {
      SetEV(m_e_eTrendSt, "Inativo", CLR_NEUTRAL);
      SetEV(m_e_eTrendMA, "--", CLR_NEUTRAL);
      SetEV(m_e_eTrendDist, "--", CLR_NEUTRAL);
     }

// ── RSI Filter ──
   if(m_rsiFilter != NULL && m_rsiFilter.IsInitialized())
     {
      SetEV(m_e_eRFiltSt, m_rsiFilter.IsEnabled() ? "Ativo" : "Desabilitado",
            m_rsiFilter.IsEnabled() ? CLR_POSITIVE : CLR_NEUTRAL);
      SetEV(m_e_eRFiltRSI, DoubleToString(m_rsiFilter.GetCurrentRSI(), 1), CLR_VALUE);
      SetEV(m_e_eRFiltMode, m_rsiFilter.GetFilterModeText(), CLR_VALUE);
     }
   else
     {
      SetEV(m_e_eRFiltSt, "Inativo", CLR_NEUTRAL);
      SetEV(m_e_eRFiltRSI, "--", CLR_NEUTRAL);
      SetEV(m_e_eRFiltMode, "--", CLR_NEUTRAL);
     }
  }

//+------------------------------------------------------------------+
//| PopulateConfig — aba 3 (chamado uma vez)                          |
//+------------------------------------------------------------------+
void CEPBotPanel::PopulateConfig(void)
  {
// ── Geral ──
   SetEV(m_c_eMagic, IntegerToString(inp_MagicNumber), CLR_VALUE);
   SetEV(m_c_eComment, inp_TradeComment, CLR_VALUE);
   SetEV(m_c_eLot, DoubleToString(inp_LotSize, 2), CLR_VALUE);

// ── Risco ──
   string slType = (inp_SLType == SL_FIXED) ? "Fixo" : (inp_SLType == SL_ATR) ? "ATR" : "Range";
   SetEV(m_c_eSL, slType + ": " + IntegerToString(inp_FixedSL) + " pts", CLR_VALUE);

   string tpType = (inp_TPType == TP_FIXED) ? "Fixo" : (inp_TPType == TP_ATR) ? "ATR" : "Sem TP";
   SetEV(m_c_eTP, tpType + ": " + IntegerToString(inp_FixedTP), CLR_VALUE);

   bool useTrail = (inp_TrailingActivation != TRAILING_NEVER);
   SetEV(m_c_eTrail, useTrail ? "Ativo" : "Desab.", useTrail ? CLR_POSITIVE : CLR_NEUTRAL);
   bool useBE = (inp_BEActivationMode != BE_NEVER);
   SetEV(m_c_eBE, useBE ? "Ativo" : "Desab.", useBE ? CLR_POSITIVE : CLR_NEUTRAL);
   SetEV(m_c_ePTP, inp_UsePartialTP ? "Ativo" : "Desab.", inp_UsePartialTP ? CLR_POSITIVE : CLR_NEUTRAL);

// ── Bloqueios ──
   if(inp_EnableTimeFilter)
      SetEV(m_c_eTimeF, StringFormat("%02d:%02d - %02d:%02d",
            inp_StartHour, inp_StartMinute, inp_EndHour, inp_EndMinute), CLR_VALUE);
   else
      SetEV(m_c_eTimeF, "Desab.", CLR_NEUTRAL);

   SetEV(m_c_eMaxSpr, (inp_MaxSpread > 0) ? IntegerToString(inp_MaxSpread) : "Sem limite", CLR_VALUE);

   if(inp_EnableDailyLimits)
      SetEV(m_c_eDaily, IntegerToString(inp_MaxDailyTrades) + " trades | -$" +
            DoubleToString(inp_MaxDailyLoss, 0) + " / +$" + DoubleToString(inp_MaxDailyGain, 0), CLR_VALUE);
   else
      SetEV(m_c_eDaily, "Desab.", CLR_NEUTRAL);

   SetEV(m_c_eStreak, inp_EnableStreakControl ? "Ativo" : "Desab.",
         inp_EnableStreakControl ? CLR_POSITIVE : CLR_NEUTRAL);

   SetEV(m_c_eDrawdown, inp_EnableDrawdown ? "Ativo" : "Desab.",
         inp_EnableDrawdown ? CLR_POSITIVE : CLR_NEUTRAL);

   string dir = (inp_TradeDirection == DIRECTION_BOTH) ? "Ambos" :
                (inp_TradeDirection == DIRECTION_BUY_ONLY) ? "Apenas BUY" : "Apenas SELL";
   SetEV(m_c_eDirection, dir, CLR_VALUE);
  }

//+------------------------------------------------------------------+
//| BlockerToStr — converte enum para texto legível                   |
//+------------------------------------------------------------------+
string CEPBotPanel::BlockerToStr(ENUM_BLOCKER_REASON r)
  {
   switch(r)
     {
      case BLOCKER_NONE:         return "Nenhum";
      case BLOCKER_TIME_FILTER:  return "Fora do horario";
      case BLOCKER_NEWS_FILTER:  return "Volatilidade";
      case BLOCKER_SPREAD:       return "Spread alto";
      case BLOCKER_DAILY_TRADES: return "Limite trades";
      case BLOCKER_DAILY_LOSS:   return "Perda maxima";
      case BLOCKER_DAILY_GAIN:   return "Ganho maximo";
      case BLOCKER_LOSS_STREAK:  return "Seq. perdas";
      case BLOCKER_WIN_STREAK:   return "Seq. ganhos";
      case BLOCKER_DRAWDOWN:     return "Drawdown";
      case BLOCKER_DIRECTION:    return "Direcao bloq.";
      default:                   return "Desconhecido";
     }
  }

//+------------------------------------------------------------------+
