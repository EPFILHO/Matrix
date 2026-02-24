//+------------------------------------------------------------------+
//|                                                       Panel.mqh  |
//|                                         Copyright 2026, EP Filho |
//|                          Painel GUI com Abas - EPBot Matrix      |
//|                     Versão 1.13 - Claude Parte 022 (Claude Code) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "1.13"
#property strict

// ═══════════════════════════════════════════════════════════════
// CHANGELOG
// ═══════════════════════════════════════════════════════════════
// v1.13 (2026-02-24):
// + LayoutRisco() dinâmico com Move() — elimina gaps ao show/hide
// + Campos ATR Period, Range Period, Comp Spread agora inline com SL/TP
//   (eliminada seção CONFIGURACAO separada)
// + Todos controles RISCO criados incondicionalmente para suportar Move()
// + MoveRowLI/LB/Hdr helpers para reposicionamento dinâmico
// + Removido m_cr_hdr3 (header CONFIGURACAO)
//
// v1.12 (2026-02-23):
// + SL Type cycle button (FIXO → ATR → RANGE) com label/valor dinâmico
// + TP Type cycle button (NENHUM → FIXO → ATR) com show/hide dinâmico
// + TP, ATR Period, Range Period, Comp Spread TP agora SEMPRE criados
//   (visibilidade controlada dinamicamente pelos type selectors)
// + SetSLType, SetTPType, SetRangeMultiplier em RiskManager (v3.14)
// + PANEL_HEIGHT 540→600, CFG_APPLY_Y 420→520
//
// v1.11 (2026-02-23):
// + FIX: ChartRedraw() nos handlers de toggle (Direção não atualizava)
// + FIX: encavalamento sub-páginas CONFIG (ReapplyTabVisibility)
// + RISCO expandido: ATR Period, Range Period, Compensar Spread
//   (SL/TP/Trailing) com 5 novos setters em RiskManager
//
// v1.10 (2026-02-22):
// + HOT RELOAD: aba CONFIG redesenhada com campos editáveis
//   - 3 sub-páginas: RISCO | BLOQUEIOS | OUTROS
//   - CEdit para valores numéricos, CButton para toggles/cycles
//   - Botão APLICAR chama setters hot-reload nos módulos
//   - Campos condicionais (só aparecem se feature está ativa)
// + PARTIÇÃO: código dividido em 5 arquivos por aba
//   - Panel.mqh (core hub), PanelTabStatus/Resultados/Estrategias/
//     Filtros/Config.mqh (implementações por aba)
//
// v1.09 (2026-02-22):
// + MouseProtection() também desabilita CHART_MOUSE_SCROLL,
//   impedindo rolar/deslocar o gráfico quando cursor sobre o painel.
//
// v1.08 (2026-02-22):
// + Proteção de mouse: MouseProtection() desabilita
//   CHART_DRAG_TRADE_LEVELS quando o cursor está sobre o painel,
//   impedindo arrastar linhas de SL/TP acidentalmente.
//   Restaura ao sair do painel ou ao destruir o objeto.
//
// v1.07 (2026-02-22):
// + Seção financeira: Ganhos / Perdas / P/L Total (substitui
//   P/L Trades Fechados e P/L TPs Parciais — dados imprecisos)
//
// v1.06 (2026-02-22):
// + Fix troca de abas: ShowTab() agora chama SetTabVis(tab,true)
//   explicitamente após ReapplyTabVisibility (que só esconde)
//
// v1.05 (2026-02-22):
// + Nova aba FILTROS (5 abas: STATUS/RESULT./ESTRAT./FILTROS/CONFIG)
// + Cores: labels preto, headers azul escuro (fundo claro do SO)
// + Fix encavalamento: OnEvent manual + ReapplyTabVisibility
//   (apenas Hide abas inativas, nunca força Show)
// + Fix minimize/maximize: evita labels "soltos" no gráfico
//
// v1.04 (2026-02-22):
// + Fix: Sobrescreve CreateButtonClose() em vez de acessar
//   m_button_close (private em CDialog) — elimina botão X
//
// v1.03 (2026-02-21):
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
#include <Controls\Edit.mqh>

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
#define PANEL_HEIGHT         600

#define PANEL_GAP_Y          18
#define PANEL_GAP_SECTION    8

#define COL_LABEL_X          10
#define COL_VALUE_X          195
#define COL_VALUE_W          210

#define CONTENT_TOP          32
#define TAB_BTN_H            22

// Layout CONFIG sub-páginas
#define CFG_CONTENT_Y        (CONTENT_TOP + TAB_BTN_H + 6)
#define CFG_APPLY_Y          520

// ═══════════════════════════════════════════════════════════════
// CORES
// ═══════════════════════════════════════════════════════════════
#define CLR_TAB_ACTIVE       C'50,120,200'
#define CLR_TAB_INACTIVE     C'70,70,70'
#define CLR_TAB_TXT_ACT      clrWhite
#define CLR_TAB_TXT_INACT    C'190,190,190'
#define CLR_LABEL            clrBlack
#define CLR_VALUE            clrBlack
#define CLR_POSITIVE         C'0,160,70'
#define CLR_NEGATIVE         C'200,50,50'
#define CLR_WARNING          C'200,140,0'
#define CLR_NEUTRAL          C'100,100,100'
#define CLR_HEADER           C'0,50,160'

// ═══════════════════════════════════════════════════════════════
// PREFIXO DE OBJETOS (evita colisão)
// ═══════════════════════════════════════════════════════════════
#define PFX "EPBM_"

// ═══════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════
enum ENUM_PANEL_TAB
  {
   TAB_STATUS = 0,
   TAB_RESULTADOS = 1,
   TAB_ESTRATEGIAS = 2,
   TAB_FILTROS = 3,
   TAB_CONFIG = 4
  };
#define TAB_COUNT 5

enum ENUM_CONFIG_PAGE
  {
   CFG_RISCO = 0,
   CFG_BLOQUEIOS = 1,
   CFG_OUTROS = 2
  };
#define CFG_PAGE_COUNT 3

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
   ENUM_CONFIG_PAGE   m_cfgPage;
   int                m_magicNumber;
   string             m_symbol;

   // ── Proteção de mouse ──
   bool               m_origDragTrade;
   bool               m_origMouseScroll;
   bool               m_mouseOverPanel;

   // ── Botões de aba ──
   CButton            m_btnTab0;
   CButton            m_btnTab1;
   CButton            m_btnTab2;
   CButton            m_btnTab3;
   CButton            m_btnTab4;

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
   CLabel  m_r_lGains;         CLabel  m_r_eGains;
   CLabel  m_r_lTotalLoss;     CLabel  m_r_eTotalLoss;

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

   // ════════════════════════════════════════
   // ABA 3: FILTROS
   // ════════════════════════════════════════
   CLabel  m_f_hdr1;
   CLabel  m_f_lTrendSt;       CLabel  m_f_eTrendSt;
   CLabel  m_f_lTrendMA;       CLabel  m_f_eTrendMA;
   CLabel  m_f_lTrendDist;     CLabel  m_f_eTrendDist;

   CLabel  m_f_hdr2;
   CLabel  m_f_lRFiltSt;       CLabel  m_f_eRFiltSt;
   CLabel  m_f_lRFiltRSI;      CLabel  m_f_eRFiltRSI;
   CLabel  m_f_lRFiltMode;     CLabel  m_f_eRFiltMode;

   // ════════════════════════════════════════
   // ABA 4: CONFIG — Hot Reload
   // ════════════════════════════════════════
   // Sub-page buttons
   CButton  m_cfg_btnRisco;
   CButton  m_cfg_btnBloq;
   CButton  m_cfg_btnOutros;

   // --- Risco sub-page ---
   CLabel   m_cr_hdr1;
   CLabel   m_cr_lLot;    CEdit   m_cr_iLot;
   CLabel   m_cr_lSLT;    CButton m_cr_bSLT;    // SL Type cycle
   CLabel   m_cr_lSL;     CEdit   m_cr_iSL;
   CLabel   m_cr_lTPT;    CButton m_cr_bTPT;    // TP Type cycle
   CLabel   m_cr_lTP;     CEdit   m_cr_iTP;
   CLabel   m_cr_lTrlSt;  CEdit   m_cr_iTrlSt;
   CLabel   m_cr_lTrlSp;  CEdit   m_cr_iTrlSp;
   CLabel   m_cr_lBEAct;  CEdit   m_cr_iBEAct;
   CLabel   m_cr_lBEOff;  CEdit   m_cr_iBEOff;
   CLabel   m_cr_hdr2;
   CLabel   m_cr_lPTP;    CButton m_cr_bPTP;
   CLabel   m_cr_lTP1p;   CEdit   m_cr_iTP1p;
   CLabel   m_cr_lTP1d;   CEdit   m_cr_iTP1d;
   CLabel   m_cr_lTP2p;   CEdit   m_cr_iTP2p;
   CLabel   m_cr_lTP2d;   CEdit   m_cr_iTP2d;
   CLabel   m_cr_lATRp;   CEdit   m_cr_iATRp;
   CLabel   m_cr_lRngP;   CEdit   m_cr_iRngP;
   CLabel   m_cr_lCSL;    CButton m_cr_bCSL;
   CLabel   m_cr_lCTP;    CButton m_cr_bCTP;
   CLabel   m_cr_lCTrl;   CButton m_cr_bCTrl;

   // --- Bloqueios sub-page ---
   CLabel   m_cb_hdr1;
   CLabel   m_cb_lSpr;    CEdit   m_cb_iSpr;
   CLabel   m_cb_lDir;    CButton m_cb_bDir;
   CLabel   m_cb_hdr2;
   CLabel   m_cb_lTrd;    CEdit   m_cb_iTrd;
   CLabel   m_cb_lLoss;   CEdit   m_cb_iLoss;
   CLabel   m_cb_lGain;   CEdit   m_cb_iGain;
   CLabel   m_cb_hdr3;
   CLabel   m_cb_lLStr;   CEdit   m_cb_iLStr;
   CLabel   m_cb_lWStr;   CEdit   m_cb_iWStr;
   CLabel   m_cb_lDD;     CEdit   m_cb_iDD;

   // --- Outros sub-page ---
   CLabel   m_co_hdr1;
   CLabel   m_co_lSlip;   CEdit   m_co_iSlip;
   CLabel   m_co_lConfl;  CButton m_co_bConfl;
   CLabel   m_co_lDbg;    CButton m_co_bDbg;
   CLabel   m_co_lDbgCd;  CEdit   m_co_iDbgCd;

   // APLICAR + status
   CButton  m_cfg_btnApply;
   CLabel   m_cfg_status;

   // Feature flags (definidos em CreateTabConfig)
   bool     m_cfg_hasTP;
   bool     m_cfg_hasTrailing;
   bool     m_cfg_hasBE;
   bool     m_cfg_hasDailyLimits;
   bool     m_cfg_hasStreak;
   bool     m_cfg_hasDrawdown;
   bool     m_cfg_hasATR;       // qualquer feature usa ATR?
   bool     m_cfg_hasRange;     // SL usa Range?

   // Estado dos toggles/cycles
   ENUM_TRADE_DIRECTION     m_cur_direction;
   ENUM_CONFLICT_RESOLUTION m_cur_conflict;
   ENUM_SL_TYPE             m_cur_slType;
   ENUM_TP_TYPE             m_cur_tpType;
   bool                     m_cur_debug;
   bool                     m_cur_partialTP;
   bool                     m_cur_compSL;
   bool                     m_cur_compTP;
   bool                     m_cur_compTrail;

   // ── Helpers privados ──
   bool              CreateLV(CLabel &lbl, CLabel &val, string ln, string en, string lt, int y);
   bool              CreateLI(CLabel &lbl, CEdit &inp, string ln, string en, string lt, int y);
   bool              CreateLB(CLabel &lbl, CButton &btn, string ln, string bn, string lt, int y);
   bool              CreateHdr(CLabel &lbl, string name, string text, int y);
   void              SetEV(CLabel &val, string value, color clr = CLR_VALUE);

   bool              CreateTabButtons(void);
   bool              CreateTabStatus(void);
   bool              CreateTabResultados(void);
   bool              CreateTabEstrategias(void);
   bool              CreateTabFiltros(void);
   bool              CreateTabConfig(void);

   void              ShowTab(ENUM_PANEL_TAB tab);
   void              SetTabVis(ENUM_PANEL_TAB tab, bool vis);
   void              UpdateTabStyles(void);

   void              UpdateStatus(void);
   void              UpdateResultados(void);
   void              UpdateEstrategias(void);
   void              UpdateFiltros(void);
   void              PopulateConfig(void);
   void              ReapplyTabVisibility(void);

   string            BlockerToStr(ENUM_BLOCKER_REASON r);

   // CONFIG sub-pages
   void              ShowCfgPage(ENUM_CONFIG_PAGE page);
   void              SetCfgPageVis(ENUM_CONFIG_PAGE page, bool vis);
   void              UpdateCfgBtnStyles(void);
   void              ApplyConfig(void);

   // Layout dinâmico RISCO (reposiciona controles com Move)
   void              LayoutRisco(void);
   void              MoveRowLI(CLabel &lbl, CEdit &inp, int abs_y);
   void              MoveRowLB(CLabel &lbl, CButton &btn, int abs_y);
   void              MoveRowHdr(CLabel &lbl, int abs_y);

   // Handlers de clique
   void              OnClickTab0(void);
   void              OnClickTab1(void);
   void              OnClickTab2(void);
   void              OnClickTab3(void);
   void              OnClickTab4(void);
   void              OnClickCfgRisco(void);
   void              OnClickCfgBloq(void);
   void              OnClickCfgOutros(void);
   void              OnClickApply(void);
   void              OnClickDirection(void);
   void              OnClickConflict(void);
   void              OnClickDebug(void);
   void              OnClickPartialTP(void);
   void              OnClickSLType(void);
   void              OnClickTPType(void);
   void              OnClickCompSL(void);
   void              OnClickCompTP(void);
   void              OnClickCompTrail(void);

protected:
   virtual bool      CreateButtonClose(void) { return true; }

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
   void              MouseProtection(const int x, const int y);

   virtual bool      OnEvent(const int id, const long &lparam,
                             const double &dparam, const string &sparam);
  };

//+------------------------------------------------------------------+
//| Construtor / Destrutor                                            |
//+------------------------------------------------------------------+
CEPBotPanel::CEPBotPanel(void)
   : m_activeTab(TAB_STATUS), m_cfgPage(CFG_RISCO),
     m_logger(NULL), m_blockers(NULL), m_riskManager(NULL),
     m_tradeManager(NULL), m_signalManager(NULL),
     m_maCross(NULL), m_rsiStrategy(NULL),
     m_trendFilter(NULL), m_rsiFilter(NULL),
     m_magicNumber(0), m_symbol(""),
     m_origDragTrade(true), m_origMouseScroll(true), m_mouseOverPanel(false),
     m_cfg_hasTP(false), m_cfg_hasTrailing(false), m_cfg_hasBE(false),
     m_cfg_hasDailyLimits(false), m_cfg_hasStreak(false), m_cfg_hasDrawdown(false),
     m_cfg_hasATR(false), m_cfg_hasRange(false),
     m_cur_direction(DIRECTION_BOTH), m_cur_conflict(CONFLICT_PRIORITY),
     m_cur_slType(SL_FIXED), m_cur_tpType(TP_NONE),
     m_cur_debug(false), m_cur_partialTP(false),
     m_cur_compSL(false), m_cur_compTP(false), m_cur_compTrail(false)
  {
  }

CEPBotPanel::~CEPBotPanel(void)
  {
   ChartSetInteger(0, CHART_DRAG_TRADE_LEVELS, m_origDragTrade);
   ChartSetInteger(0, CHART_MOUSE_SCROLL, m_origMouseScroll);
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

   if(!CreateTabButtons())    return false;
   if(!CreateTabStatus())     return false;
   if(!CreateTabResultados()) return false;
   if(!CreateTabEstrategias()) return false;
   if(!CreateTabFiltros())    return false;
   if(!CreateTabConfig())     return false;

   m_origDragTrade  = (bool)ChartGetInteger(chart, CHART_DRAG_TRADE_LEVELS);
   m_origMouseScroll = (bool)ChartGetInteger(chart, CHART_MOUSE_SCROLL);
   ChartSetInteger(chart, CHART_EVENT_MOUSE_MOVE, true);

   PopulateConfig();
   ShowTab(TAB_STATUS);
   return true;
  }

//+------------------------------------------------------------------+
//| HELPERS: CreateLV, CreateHdr, SetEV                               |
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
   int w = (PANEL_WIDTH - 30) / TAB_COUNT;
   int y1 = 3, y2 = 3 + TAB_BTN_H;

   if(!m_btnTab0.Create(m_chart_id, PFX + "tab0", m_subwin, 5, y1, 5 + w, y2))
      return false;
   m_btnTab0.Text("STATUS");
   m_btnTab0.FontSize(7);
   if(!Add(m_btnTab0))
      return false;

   if(!m_btnTab1.Create(m_chart_id, PFX + "tab1", m_subwin, 5 + (w + 2), y1, 5 + w * 2 + 2, y2))
      return false;
   m_btnTab1.Text("RESULT.");
   m_btnTab1.FontSize(7);
   if(!Add(m_btnTab1))
      return false;

   if(!m_btnTab2.Create(m_chart_id, PFX + "tab2", m_subwin, 5 + (w + 2) * 2, y1, 5 + w * 3 + 4, y2))
      return false;
   m_btnTab2.Text("ESTRAT.");
   m_btnTab2.FontSize(7);
   if(!Add(m_btnTab2))
      return false;

   if(!m_btnTab3.Create(m_chart_id, PFX + "tab3", m_subwin, 5 + (w + 2) * 3, y1, 5 + w * 4 + 6, y2))
      return false;
   m_btnTab3.Text("FILTROS");
   m_btnTab3.FontSize(7);
   if(!Add(m_btnTab3))
      return false;

   if(!m_btnTab4.Create(m_chart_id, PFX + "tab4", m_subwin, 5 + (w + 2) * 4, y1, 5 + w * 5 + 8, y2))
      return false;
   m_btnTab4.Text("CONFIG");
   m_btnTab4.FontSize(7);
   if(!Add(m_btnTab4))
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| OnEvent — manual (substitui EVENT_MAP para fix de encavalamento)  |
//+------------------------------------------------------------------+
bool CEPBotPanel::OnEvent(const int id, const long &lparam,
                           const double &dparam, const string &sparam)
  {
   if(id == (CHARTEVENT_CUSTOM + ON_CLICK))
     {
      // Abas principais
      if(lparam == m_btnTab0.Id()) { OnClickTab0(); return true; }
      if(lparam == m_btnTab1.Id()) { OnClickTab1(); return true; }
      if(lparam == m_btnTab2.Id()) { OnClickTab2(); return true; }
      if(lparam == m_btnTab3.Id()) { OnClickTab3(); return true; }
      if(lparam == m_btnTab4.Id()) { OnClickTab4(); return true; }

      // CONFIG: sub-páginas
      if(lparam == m_cfg_btnRisco.Id())  { OnClickCfgRisco();  return true; }
      if(lparam == m_cfg_btnBloq.Id())   { OnClickCfgBloq();   return true; }
      if(lparam == m_cfg_btnOutros.Id()) { OnClickCfgOutros(); return true; }

      // CONFIG: APLICAR
      if(lparam == m_cfg_btnApply.Id())  { OnClickApply(); return true; }

      // CONFIG: toggles/cycles
      if(lparam == m_cb_bDir.Id())       { OnClickDirection(); return true; }
      if(lparam == m_co_bConfl.Id())     { OnClickConflict();  return true; }
      if(lparam == m_co_bDbg.Id())       { OnClickDebug();     return true; }
      if(lparam == m_cr_bSLT.Id())       { OnClickSLType();    return true; }
      if(lparam == m_cr_bTPT.Id())       { OnClickTPType();    return true; }
      if(lparam == m_cr_bPTP.Id())       { OnClickPartialTP(); return true; }
      if(lparam == m_cr_bCSL.Id())       { OnClickCompSL();    return true; }
      if(lparam == m_cr_bCTP.Id())       { OnClickCompTP();    return true; }
      if(lparam == m_cr_bCTrl.Id())      { OnClickCompTrail(); return true; }
     }

   bool result = CAppDialog::OnEvent(id, lparam, dparam, sparam);

   if(result)
      ReapplyTabVisibility();

   return result;
  }

//+------------------------------------------------------------------+
//| ReapplyTabVisibility                                               |
//+------------------------------------------------------------------+
void CEPBotPanel::ReapplyTabVisibility(void)
  {
   for(int t = 0; t < TAB_COUNT; t++)
     {
      if(t != (int)m_activeTab)
         SetTabVis((ENUM_PANEL_TAB)t, false);
     }
// Fix encavalamento: se CONFIG ativa, re-esconder sub-páginas inativas
   if(m_activeTab == TAB_CONFIG)
     {
      for(int p = 0; p < CFG_PAGE_COUNT; p++)
        {
         if(p != (int)m_cfgPage)
            SetCfgPageVis((ENUM_CONFIG_PAGE)p, false);
        }
     }
  }

// Handlers de clique das abas
void CEPBotPanel::OnClickTab0(void) { ShowTab(TAB_STATUS); }
void CEPBotPanel::OnClickTab1(void) { ShowTab(TAB_RESULTADOS); }
void CEPBotPanel::OnClickTab2(void) { ShowTab(TAB_ESTRATEGIAS); }
void CEPBotPanel::OnClickTab3(void) { ShowTab(TAB_FILTROS); }
void CEPBotPanel::OnClickTab4(void) { ShowTab(TAB_CONFIG); }

//+------------------------------------------------------------------+
//| ShowTab — alterna a visibilidade das abas                         |
//+------------------------------------------------------------------+
void CEPBotPanel::ShowTab(ENUM_PANEL_TAB tab)
  {
   m_activeTab = tab;
   ReapplyTabVisibility();
   SetTabVis(tab, true);
   UpdateTabStyles();

   switch(tab)
     {
      case TAB_STATUS:      UpdateStatus();       break;
      case TAB_RESULTADOS:  UpdateResultados();   break;
      case TAB_ESTRATEGIAS: UpdateEstrategias();  break;
      case TAB_FILTROS:     UpdateFiltros();      break;
      case TAB_CONFIG:      /* user-editable */   break;
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
                    m_r_lGains.Show(); m_r_eGains.Show(); m_r_lTotalLoss.Show(); m_r_eTotalLoss.Show();
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
                    m_r_lGains.Hide(); m_r_eGains.Hide(); m_r_lTotalLoss.Hide(); m_r_eTotalLoss.Hide();
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
                    m_e_lRSILevels.Show(); m_e_eRSILevels.Show(); }
         else    { m_e_hdr1.Hide(); m_e_lStratCnt.Hide(); m_e_eStratCnt.Hide();
                    m_e_lFiltCnt.Hide(); m_e_eFiltCnt.Hide(); m_e_lConflict.Hide(); m_e_eConflict.Hide();
                    m_e_hdr2.Hide(); m_e_lMAStatus.Hide(); m_e_eMAStatus.Hide();
                    m_e_lMAFast.Hide(); m_e_eMAFast.Hide(); m_e_lMASlow.Hide(); m_e_eMASlow.Hide();
                    m_e_lMACross.Hide(); m_e_eMACross.Hide(); m_e_lMACandles.Hide(); m_e_eMACandles.Hide();
                    m_e_lMAEntry.Hide(); m_e_eMAEntry.Hide(); m_e_lMAExit.Hide(); m_e_eMAExit.Hide();
                    m_e_hdr3.Hide(); m_e_lRSIStatus.Hide(); m_e_eRSIStatus.Hide();
                    m_e_lRSICurr.Hide(); m_e_eRSICurr.Hide(); m_e_lRSIMode.Hide(); m_e_eRSIMode.Hide();
                    m_e_lRSILevels.Hide(); m_e_eRSILevels.Hide(); }
         break;
        }
      case TAB_FILTROS:
        {
         if(vis) { m_f_hdr1.Show(); m_f_lTrendSt.Show(); m_f_eTrendSt.Show();
                    m_f_lTrendMA.Show(); m_f_eTrendMA.Show(); m_f_lTrendDist.Show(); m_f_eTrendDist.Show();
                    m_f_hdr2.Show(); m_f_lRFiltSt.Show(); m_f_eRFiltSt.Show();
                    m_f_lRFiltRSI.Show(); m_f_eRFiltRSI.Show(); m_f_lRFiltMode.Show(); m_f_eRFiltMode.Show(); }
         else    { m_f_hdr1.Hide(); m_f_lTrendSt.Hide(); m_f_eTrendSt.Hide();
                    m_f_lTrendMA.Hide(); m_f_eTrendMA.Hide(); m_f_lTrendDist.Hide(); m_f_eTrendDist.Hide();
                    m_f_hdr2.Hide(); m_f_lRFiltSt.Hide(); m_f_eRFiltSt.Hide();
                    m_f_lRFiltRSI.Hide(); m_f_eRFiltRSI.Hide(); m_f_lRFiltMode.Hide(); m_f_eRFiltMode.Hide(); }
         break;
        }
      case TAB_CONFIG:
        {
         if(vis)
           {
            // Sub-page buttons + apply + status
            m_cfg_btnRisco.Show(); m_cfg_btnBloq.Show(); m_cfg_btnOutros.Show();
            m_cfg_btnApply.Show(); m_cfg_status.Show();
            // Show active sub-page
            ShowCfgPage(m_cfgPage);
           }
         else
           {
            m_cfg_btnRisco.Hide(); m_cfg_btnBloq.Hide(); m_cfg_btnOutros.Hide();
            m_cfg_btnApply.Hide(); m_cfg_status.Hide();
            SetCfgPageVis(CFG_RISCO, false);
            SetCfgPageVis(CFG_BLOQUEIOS, false);
            SetCfgPageVis(CFG_OUTROS, false);
           }
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
   m_btnTab3.ColorBackground((m_activeTab == TAB_FILTROS)     ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);
   m_btnTab4.ColorBackground((m_activeTab == TAB_CONFIG)      ? CLR_TAB_ACTIVE : CLR_TAB_INACTIVE);

   m_btnTab0.Color((m_activeTab == TAB_STATUS)      ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_btnTab1.Color((m_activeTab == TAB_RESULTADOS)  ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_btnTab2.Color((m_activeTab == TAB_ESTRATEGIAS) ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_btnTab3.Color((m_activeTab == TAB_FILTROS)     ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
   m_btnTab4.Color((m_activeTab == TAB_CONFIG)      ? CLR_TAB_TXT_ACT : CLR_TAB_TXT_INACT);
  }

//+------------------------------------------------------------------+
//| Update — chamado pelo timer, atualiza apenas a aba ativa          |
//+------------------------------------------------------------------+
void CEPBotPanel::Update(void)
  {
   switch(m_activeTab)
     {
      case TAB_STATUS:      UpdateStatus();       break;
      case TAB_RESULTADOS:  UpdateResultados();   break;
      case TAB_ESTRATEGIAS: UpdateEstrategias();  break;
      case TAB_FILTROS:     UpdateFiltros();      break;
      case TAB_CONFIG:      /* user-editable */   break;
     }
  }

//+------------------------------------------------------------------+
//| MouseProtection — desabilita arrasto e scroll sobre o painel      |
//+------------------------------------------------------------------+
void CEPBotPanel::MouseProtection(const int x, const int y)
  {
   bool inside = (x >= Left() && x <= Right() && y >= Top() && y <= Bottom());

   if(inside && !m_mouseOverPanel)
     {
      ChartSetInteger(0, CHART_DRAG_TRADE_LEVELS, false);
      ChartSetInteger(0, CHART_MOUSE_SCROLL, false);
      m_mouseOverPanel = true;
     }
   else if(!inside && m_mouseOverPanel)
     {
      ChartSetInteger(0, CHART_DRAG_TRADE_LEVELS, m_origDragTrade);
      ChartSetInteger(0, CHART_MOUSE_SCROLL, m_origMouseScroll);
      m_mouseOverPanel = false;
     }
  }

// ═══════════════════════════════════════════════════════════════
// IMPLEMENTAÇÕES DAS ABAS (arquivos separados por manutenção)
// ═══════════════════════════════════════════════════════════════
#include "PanelTabStatus.mqh"
#include "PanelTabResultados.mqh"
#include "PanelTabEstrategias.mqh"
#include "PanelTabFiltros.mqh"
#include "PanelTabConfig.mqh"

//+------------------------------------------------------------------+
