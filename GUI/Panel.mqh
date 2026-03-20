//+------------------------------------------------------------------+
//|                                                       Panel.mqh  |
//|                                         Copyright 2026, EP Filho |
//|                          Painel GUI com Abas - EPBot Matrix      |
//|                     Versão 1.49 - Claude Parte 027 (Claude Code) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "1.49"
#property strict

// ═══════════════════════════════════════════════════════════════
// CHANGELOG
// ═══════════════════════════════════════════════════════════════
// v1.49 (Parte 027):
// + OUTROS: Magic Number (CEdit + aviso warning) e Comentário das Ordens
//   m_co_lMagic/iMagic, m_co_lMagicW, m_co_lComm/iComm
//   Posicionados acima de Slippage/Conflito; Debug e Debug Cooldown por último
// + RISCO 2: Limites Diários movidos de BLOQUEIOS com toggle ON/OFF dinâmico
//   m_c2_hdr4, m_c2_lDLAct/bDLAct, lDLTrd/iDLTrd, lDLLoss/iDLLoss,
//   lDLGain/iDLGain, lDLPTA/bDLPTA[2] — posicionados ACIMA de TRAILING
//   m_cur_dailyLimitsOn: novo estado
//   OnClickDailyLimitsToggle, RefreshDailyLimitsState, OnClickDLProfitTargetAction
// + Removidos: m_cb_hdr2/lTrd/iTrd/lLoss/iLoss/lGain/iGain/lPTA/bPTA (BLOQUEIOS)
//   OnClickProfitTargetAction → substituído por OnClickDLProfitTargetAction
//
// v1.48 (Parte 026):
// + ReconnectModules(): re-injeta ponteiros após troca de TF sem
//   recriar objetos gráficos. Usa dynamic_cast + SetStrategy/SetFilter
//   tipados em cada sub-painel concreto.
// + if(!m_minimized) antes de ShowTab() — evita controles soltos
//   ao trocar TF com painel minimizado.
//
// v1.47 (Parte 026):
// - Simplificação minimize/maximize: removido deferred minimize
//   (m_pendingMinimize), DoMinimize(), SetPendingMinimize(),
//   IsMinimized(), explicit Hide() de ~400 controles no OnEvent.
//   Confiamos no cascade nativo do CAppDialog para hide/show.
//   Mantido: Update() early-return + ChartEvent bypass quando
//   m_minimized (evita processamento desnecessário).
//   Painel sempre inicia maximizado após troca de timeframe.
//
// v1.42 (Parte 026):
// + Fix GUI minimize: Update() retorna imediatamente se m_minimized
//   Evita labels "soltos" no gráfico quando painel está minimizado
//   (UpdateEstrategias/UpdateFiltros chamavam .Show() a cada timer tick)
//
// v1.41 (Parte 026):
// - Removido GetPriorityMapText() (não mais utilizado)
// v1.40 (Parte 026):
// + ResolveStrategyPriority(): auto-ajuste de prioridade (incrementa se conflito)
// + Painéis de estratégia agora têm campo Prioridade editável com auto-ajuste
//
// v1.39 (Parte 026):
// + BB Strategy e BB Filter integrados em RegisterPanels()
//   BollingerBandsPanel.mqh + BollingerBandsFilterPanel.mqh
// + Init() recebe ponteiros BB Strategy + BB Filter
// + m_bbStrategy, m_bbFilter: novos membros ponteiro
//
// v1.38 (Parte 025):
// + CStrategyPanelBase / CFilterPanelBase: base abstrata para sub-páginas
//   Cada estratégia/filtro encapsula seus controles em GUI/Panels/*.mqh
//   RegisterPanels(): factory method — cria painéis e popula arrays dinâmicos
//   ChartEvent: loops genéricos (2 linhas) em vez de if-chains por controle
//   PanelTabEstrategias/Filtros: simplificado para ~150 / ~100 linhas
//   Nova estratégia/filtro = 1 arquivo novo + 2 linhas em RegisterPanels()
// + PanelUtils.mqh: funções livres (TFName, CycleTF, ApplyToggleStyle, ...)
//   Remove duplicação de static methods em CEPBotPanel
// + Helpers CreateLV/CreateHdr/etc tornados public para acesso pelos painéis
// + AddControl(CWnd&): wrapper público de Add()
// + MAX_STRAT_PANELS=6, MAX_FILT_PANELS=6: tamanho fixo dos arrays de botões
// + m_e_stratBtns[MAX_STRAT_PANELS], m_f_filtBtns[MAX_FILT_PANELS]: nav buttons
// + int m_estratPage / m_filtrosPage: substitui ENUM_ESTRAT/FILTROS_PAGE (extensível)
//
// v1.37 (Parte 025):
// + Sub-página GERAL em ESTRATEGIAS e FILTROS (GUI genérica)
//   ESTRAT_OVERVIEW=0, ESTRAT_PAGE_COUNT 2→3; FILTROS_OVERVIEW=0, FILTROS_PAGE_COUNT 2→3
//   MAX_OVERVIEW_ROWS=6: até 6 linhas auto-iteradas via SignalManager.GetStrategy/Filter(i)
//   m_e_btnOverview, m_ov_lStrHdr, m_ov_eStrName[6], m_ov_eStrStatus[6]
//   m_f_btnOverview, m_ov_lFiltHdr, m_ov_eFiltName[6], m_ov_eFiltStatus[6]
//   OnClickEstratOverview, OnClickFiltrosOverview
//   Novas estratégias/filtros aparecem em GERAL automaticamente sem editar GUI
//
// v1.36 (Parte 024):
// + Price (CLOSE/OPEN/HIGH/LOW/MEDIAN/TYPICAL) para MA Cross (Fast+Slow) e TrendFilter
//   m_ce_lFastPrice/m_ce_bFastPrice, m_ce_lSlowPrice/m_ce_bSlowPrice
//   m_ft_lPrice/m_ft_bPrice; state vars m_cur_maFastPrice/SlowPrice/trendPrice
//   OnClickMAFastPrice, OnClickMASlowPrice, OnClickTrendPrice
//   AppliedPriceShortText, CycleAppliedPrice: helpers estáticos
//
// v1.35 (Parte 024):
// + Toggle ON/OFF + APLICAR para TrendFilter e RSIFilter (aba FILTROS)
//   m_f_btnTrendToggle, m_f_btnApplyTrend, m_ft_*: Período MA, Método, TF, Zona Neutra
//   m_f_btnRSIFiltToggle, m_f_btnApplyRSIFilt, m_frf_*: Período, TF, Modo, Oversold, Overbought
// + m_pendingTrendEnabled, m_pendingRSIFiltEnabled: flags de pending state
// + m_cur_trendMethod, m_cur_trendTF, m_cur_rsiFiltMode, m_cur_rsiFiltTF
// + m_f_statusTrendExpiry, m_f_statusRSIFiltExpiry: expiração de mensagens
// + OnClickTrendToggle/ApplyTrend/TrendMethod/TrendTF
// + OnClickRSIFiltToggle/ApplyRSIFilt/RSIFiltTF/RSIFiltMode
// + RSIFiltModeText, MAMethodShortText: helpers estáticos
// + OnEvent: novo bloco de eventos para botões FILTROS
//
// v1.34 (Parte 024):
// + Removido hot-create de RSI: m_rsiPanelOwned, GetRSIStrategy(), IsRSIPanelOwned()
// + Padrão igual ao MACross: RSI só existe se inp_UseRSI=true no init
//
// v1.33 (Parte 024 - fix compilação):
// + FIX: removido CRSIStrategy** (MQL5 não suporta ponteiro-para-ponteiro)
// + Adicionados getters GetRSIStrategy() e IsRSIPanelOwned() para sync EA↔Panel
//
// v1.30 (Parte 024):
// + PanelTabEstrategias v1.18: ApplyToggleStyle avail param (N/A cinza)
//   m_re_lModeDesc: legenda dinâmica CROSS/ZONE/MEDIO, RSIModeDesc()
// + Panel.mqh: declaração RSIModeDesc() + m_re_lModeDesc membro
//
// v1.29 (Parte 024):
// + PanelTabEstrategias v1.17: toggle default OFF quando NULL, labels ON/OFF,
//   UpdateEstrategias sincroniza toggle + estado "Suspenso"
//
// v1.28 (Parte 024):
// + m_cr_lPTPHint: novo membro CLabel para dica visual TP=NENHUM + Partial TP
//   na sub-página RISCO (criado em PanelTabConfig v1.25)
// + MA Cross e RSI: botões toggle ON/OFF (m_e_btnMAToggle, m_e_btnRSIToggle)
//   OnClickMAToggle, OnClickRSIToggle, ApplyToggleStyle
//   MACrossStrategy v2.23 e RSIStrategy v2.12: m_enabled, SetEnabled(), GetEnabled()
//
// v1.27 (Parte 024):
// + MA Cross: m_e_lMAEntry/eMAEntry/lMAExit/eMAExit → removidos
//   Substituídos por m_e_lLeg1/lLeg2/lLeg3 (legenda FCO/VM/TP-SL)
// + m_ce_bEntry comentário: NEXT CANDLE|2ND CANDLE → PROX. CANDLE|2o. CANDLE
// + RSI sub-página: campos editáveis hot/cold reload
//   m_re_*: Period(edit), TF(cycle), Mode(radio 3), Oversold, Overbought, Middle
//   m_e_btnApplyRSI, m_e_statusRSI, m_e_statusRSIExpiry
//   m_cur_rsiTF, m_cur_rsiMode: state vars
//   OnClickApplyRSI, OnClickRSIMode, OnClickRSITF,
//   RSIModeToIndex, IndexToRSIMode: helpers
//   Auto-clear m_e_statusRSIExpiry no Update() switch TAB_ESTRATEGIAS
//
// v1.26 (Parte 024):
// + ESTRAT aba (MA Cross sub-página): campos editáveis hot/cold reload inline
//   m_ce_*: Fast/Slow Period, Method(4), TF(cycle), Entry(2), Exit(3)
//   m_e_btnApplyMA, m_e_statusMA, m_e_statusMAExpiry
//   m_cur_maFastMethod/SlowMethod/FastTF/SlowTF/maEntry/maExit: state vars
//   OnClickApplyMA, OnClickMAFastMethod/SlowMethod, OnClickMAFastTF/SlowTF
//   OnClickMAEntry, OnClickMAExit, CycleTF, TFName, MAMethodToIndex, IndexToMAMethod
//   Auto-clear m_e_statusMAExpiry no Update() switch TAB_ESTRATEGIAS
//
// v1.25 (Parte 024):
// + Aba RESULTADOS/PROTECAO: novos CLabel members para DD expandido
//   m_r_lDDLim/eDDLim (DD Limite), m_r_lDDMode/eDDMode (DD Modo Pico),
//   m_r_lStreak/eStreak (Streak estado) + Show/Hide no SetTabVis()
// ═══════════════════════════════════════════════════════════════
// v1.24 (Parte 024):
// + Sub-páginas em ESTRAT.: [MA CROSS] [RSI]
// + Sub-páginas em FILTROS: [TREND] [RSI]
// + SIGNAL MANAGER movido de ESTRAT. → STATUS (abaixo de SINAIS)
// + ENUM_ESTRAT_PAGE, ENUM_FILTROS_PAGE, ESTRAT_CONTENT_Y, FILTROS_CONTENT_Y
// + m_estratPage, m_filtrosPage: estado das sub-páginas ativas
// + m_e_btnMACross, m_e_btnRSI: botões sub-página ESTRAT.
// + m_f_btnTrend, m_f_btnRSI: botões sub-página FILTROS
// + m_s_hdrSM, m_s_lStrats/eStrats, m_s_lFilts/eFilts, m_s_lConflict/eConflict: SM na aba STATUS
// + ShowEstratPage/SetEstratPageVis/UpdateEstratBtnStyles/OnClickEstratMACross/RSI
// + ShowFiltrosPage/SetFiltrosPageVis/UpdateFiltrosBtnStyles/OnClickFiltrosTrend/RSI
// + ReapplyTabVisibility: fix encavalamento sub-páginas ESTRAT./FILTROS
// ═══════════════════════════════════════════════════════════════
//
// v1.23 (2026-03-03):
// + Layout: COL_VALUE_X 195→150, COL_VALUE_W 210→255 (campos de valor
//   ficam 45px mais próximos dos labels em todas as abas; borda direita
//   permanece inalterada em x=405)
// + Auto-hide status CONFIG: m_cfgStatusExpiry (uint) armazena timestamp
//   de expiração; Update() limpa m_cfg_status após 10s automaticamente
// + m_cfgStatusExpiry inicializado a 0 no construtor
//
// + CFG_BLOQ2 = 4, CFG_PAGE_COUNT = 5
// + m_cfg_btnBloq2: novo botão de aba "BLOQ 2"
// + m_cb2_* (24 controles): BLOQUEIO 2 — Filtro de Notícias (3 janelas)
// + m_cur_newsOn1/2/3: novos estados
// + OnClickCfgBloq2, OnClickNewsOn1/2/3, RefreshNewsState(w): novos handlers
//
// v1.21 (2026-03-01):
// + Fechar Antes do Fim da Sessão na sub-página BLOQUEIOS
// + m_cb_hdr5, m_cb_lCBSOn/bCBSOn, m_cb_lCBSMin/iCBSMin
// + m_cur_cbsOn: novo estado
// + OnClickCBSToggle, RefreshBloqSessionEnd: novos handlers
//
// v1.20 (2026-03-01):
// + Filtro de Horário na sub-página BLOQUEIOS
// + m_cb_hdr4, m_cb_lTFOn/bTFOn, m_cb_lTFSH/iTFSH, m_cb_lTFSM/iTFSM
// + m_cb_lTFEH/iTFEH, m_cb_lTFEM/iTFEM, m_cb_lTFCl/bTFCl
// + m_cur_tfOn, m_cur_tfClose: novos estados
// + OnClickTFToggle, OnClickTFClose: novos handlers
// + RefreshBloqTimeFilter: enable/disable campos por toggle
//
// v1.19 (2026-02-28):
// + Toggles ON/OFF individuais: DrawDown (RISCO 2), Loss Streak, Win Streak (BLOQUEIOS)
// + m_cur_ddOn, m_cur_lossStreakOn, m_cur_winStreakOn: novos estados
// + m_c2_bDDAct, m_cb_bLStrOn, m_cb_bWStrOn: novos botões toggle
// + OnClickDDToggle, OnClickLossStreakToggle, OnClickWinStreakToggle: novos handlers
// + RefreshRisco2State/RefreshStreakState: enable/disable sub-campos por toggle
//
// v1.18 (2026-02-28):
// + DrawDown movido de BLOQUEIOS → RISCO 2 (m_cb_hdr4/lDD/bDDT/bDDPk → m_c2_hdr3/*)
// + Streak e DrawDown criados incondicionalmente (sempre visíveis)
// + RefreshStreakState: removido early-return por m_cfg_hasStreak
// + ChartEvent: m_cb_bDDT/bDDPk → m_c2_bDDT/bDDPk
//
// v1.17 (2026-02-28):
// + Partial TP movido de RISCO 2 → RISCO (m_c2_bPTP/iTP* → m_cr_bPTP/iTP*)
// + BLOQUEIOS expandido: radio Streak Action (PAUSAR|PARAR DIA) por Loss/Win
// + BLOQUEIOS: campos Pausa Min (Loss/Win) — visíveis só se action=PAUSAR
// + BLOQUEIOS: radio DD Type (FINANCEIRO|PERCENTUAL), DD Peak Mode (SÓ REAL.|C/FLUTUANTE)
// + BLOQUEIOS: radio Profit Target Action (PARAR|ATIVAR DD)
// + Novos state vars: m_cur_lossStreakAction/winStreakAction/ddType/ddPeakMode/profitTargetAction
// + RefreshStreakState() — enable/disable campos de pausa por action selecionada
// + Novos handlers: OnClickLossStreakAction, OnClickWinStreakAction, OnClickDDType,
//   OnClickDDPeakMode, OnClickProfitTargetAction
//
// v1.16 (2026-02-25):
// + RADIO GROUPS: Cycle buttons → CButton[] horizontais
//   (SL Type, TP Type, Direcao agora com botoes individuais por opcao)
// + CreateRadioGroup() — helper para criar grupo de N CButtons horizontal
// + SetRadioSelection() — helper para destacar botao ativo/dimmed
// + Sub-pagina RISCO 2: Trailing ON/OFF, BE ON/OFF, Partial TP
//   (CFG_PAGE_COUNT 3→4, separacao de concerns)
// + RefreshRisco2State() — enable/disable campos Trailing/BE/Partial
//
// v1.15 (2026-02-25):
// + FIX CLICKS: OnEvent agora chama CAppDialog::OnEvent() PRIMEIRO
//   (CAppDialog precisa processar CHARTEVENT_OBJECT_CLICK para gerar ON_CLICK)
//   Corrige SL Type, Direction, e demais botões que não respondiam
//
// v1.14 (2026-02-25):
// + REVERT Move(): campos fixos + enable/disable visual (cinza/read-only)
// + RefreshRiscoState() — habilita/desabilita campos por tipo SL/TP
// + SetEditEnabled/SetButtonEnabled helpers visuais
// + Conflito TP ATR vs Partial TP: bloqueio mútuo
// + Fix minimize/maximize encavalamento
//
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
#include "../Core/ConfigPersistence.mqh"
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
#define COL_VALUE_X          150
#define COL_VALUE_W          255

#define CONTENT_TOP          32
#define TAB_BTN_H            22

// Layout sub-páginas (CONFIG, ESTRAT., FILTROS)
#define CFG_CONTENT_Y        (CONTENT_TOP + TAB_BTN_H + 6)
#define ESTRAT_CONTENT_Y     (CONTENT_TOP + TAB_BTN_H + 6)
#define FILTROS_CONTENT_Y    (CONTENT_TOP + TAB_BTN_H + 6)
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
#define CLR_RADIO_ACTIVE     C'30,120,70'
#define CLR_RADIO_INACTIVE   C'180,180,180'
#define CLR_RADIO_TXT_ACT    clrWhite
#define CLR_RADIO_TXT_INACT  C'80,80,80'

// Utilitários e interfaces de painel (APÓS #defines, ANTES da definição de CEPBotPanel)
#include "PanelUtils.mqh"
#include "StrategyPanelBase.mqh"
#include "FilterPanelBase.mqh"

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
   CFG_RISCO2 = 1,
   CFG_BLOQUEIOS = 2,
   CFG_OUTROS = 3,
   CFG_BLOQ2 = 4
  };
#define CFG_PAGE_COUNT 5

// Sub-páginas ESTRAT/FILTROS agora são int (índice 0=GERAL, 1..N=painéis)
// Mantidos como aliases de compatibilidade para SetTabVis/ReapplyTabVisibility
#define ESTRAT_PAGE_COUNT  3   // GERAL + MACross + RSI (para backward compat em loops)
#define FILTROS_PAGE_COUNT 3   // GERAL + Trend + RSI Filt

#define MAX_OVERVIEW_ROWS  6   // máximo de linhas na sub-página GERAL
#define MAX_STRAT_PANELS   6   // máximo de botões de sub-página ESTRAT. (inclui GERAL)
#define MAX_FILT_PANELS    6   // máximo de botões de sub-página FILTROS (inclui GERAL)

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
   CMACrossStrategy        *m_maCross;
   CRSIStrategy            *m_rsiStrategy;
   CBollingerBandsStrategy *m_bbStrategy;
   CTrendFilter            *m_trendFilter;
   CRSIFilter              *m_rsiFilter;
   CBollingerBandsFilter   *m_bbFilter;

   // ── Painéis dinâmicos (criados em RegisterPanels) ──
   CStrategyPanelBase *m_stratPanels[];
   CFilterPanelBase   *m_filtPanels[];
   int                 m_stratPanelCount;
   int                 m_filtPanelCount;
   CButton             m_e_stratBtns[MAX_STRAT_PANELS];  // [0]=GERAL, [1..N]=painéis
   CButton             m_f_filtBtns[MAX_FILT_PANELS];    // [0]=GERAL, [1..N]=painéis
   int                 m_stratBtnCount;
   int                 m_filtBtnCount;

   // ── Estado ──
   ENUM_PANEL_TAB     m_activeTab;
   ENUM_CONFIG_PAGE   m_cfgPage;
   int                m_estratPage;    // 0=GERAL, 1..N=painel
   int                m_filtrosPage;   // 0=GERAL, 1..N=painel
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

   // SIGNAL MANAGER (movido de ESTRAT. — Parte 024)
   CLabel  m_s_hdrSM;
   CLabel  m_s_lStrats;        CLabel  m_s_eStrats;
   CLabel  m_s_lFilts;         CLabel  m_s_eFilts;
   CLabel  m_s_lConflict;      CLabel  m_s_eConflict;

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
   CLabel  m_r_lDDLim;         CLabel  m_r_eDDLim;
   CLabel  m_r_lDDMode;        CLabel  m_r_eDDMode;
   CLabel  m_r_lDD;            CLabel  m_r_eDD;
   CLabel  m_r_lPeak;          CLabel  m_r_ePeak;
   CLabel  m_r_lStreak;        CLabel  m_r_eStreak;
   CLabel  m_r_lLossStrk;      CLabel  m_r_eLossStrk;
   CLabel  m_r_lWinStrk;       CLabel  m_r_eWinStrk;

   // ════════════════════════════════════════
   // ABA 2: ESTRATEGIAS
   // ════════════════════════════════════════
   // GERAL sub-page — visão genérica (auto-iterada via SignalManager)
   CLabel  m_ov_lStrHdr;
   CLabel  m_ov_eStrName[MAX_OVERVIEW_ROWS];
   CLabel  m_ov_eStrStatus[MAX_OVERVIEW_ROWS];
   // Controles de estratégia específicos agora vivem nos painéis (GUI/Panels/*.mqh)

   // ════════════════════════════════════════
   // ABA 3: FILTROS
   // ════════════════════════════════════════
   // GERAL sub-page — visão genérica (auto-iterada via SignalManager)
   CLabel  m_ov_lFiltHdr;
   CLabel  m_ov_eFiltName[MAX_OVERVIEW_ROWS];
   CLabel  m_ov_eFiltStatus[MAX_OVERVIEW_ROWS];
   // Controles de filtro específicos agora vivem nos painéis (GUI/Panels/*.mqh)

   // ════════════════════════════════════════
   // ABA 4: CONFIG — Hot Reload
   // ════════════════════════════════════════
   // Sub-page buttons
   CButton  m_cfg_btnRisco;
   CButton  m_cfg_btnRisco2;
   CButton  m_cfg_btnBloq;
   CButton  m_cfg_btnOutros;
   CButton  m_cfg_btnBloq2;

   // --- Risco sub-page (SL/TP/Spread/PartialTP) ---
   CLabel   m_cr_hdr1;
   CLabel   m_cr_lLot;    CEdit    m_cr_iLot;
   CLabel   m_cr_lATRp;   CEdit    m_cr_iATRp;
   CLabel   m_cr_lRngP;   CEdit    m_cr_iRngP;
   CLabel   m_cr_hdrSL;                            // Header "STOP LOSS"
   CLabel   m_cr_lSLT;    CButton  m_cr_bSLT[3];  // Radio: FIXO | ATR | RANGE
   CLabel   m_cr_lSL;     CEdit    m_cr_iSL;
   CLabel   m_cr_lCSL;    CButton  m_cr_bCSL;
   CLabel   m_cr_hdrTP;                            // Header "TAKE PROFIT"
   CLabel   m_cr_lTPT;    CButton  m_cr_bTPT[3];  // Radio: NENHUM | FIXO | ATR
   CLabel   m_cr_lTP;     CEdit    m_cr_iTP;
   CLabel   m_cr_lCTP;    CButton  m_cr_bCTP;
   // Partial TP (movido de RISCO 2 para cá)
   CLabel   m_cr_hdrPTP;
   CLabel   m_cr_lPTP;    CButton  m_cr_bPTP;     // Partial TP toggle
   CLabel   m_cr_lTP1p;   CEdit    m_cr_iTP1p;
   CLabel   m_cr_lTP1d;   CEdit    m_cr_iTP1d;
   CLabel   m_cr_lTP2p;   CEdit    m_cr_iTP2p;
   CLabel   m_cr_lTP2d;   CEdit    m_cr_iTP2d;
   CLabel   m_cr_lPTPHint;  // Dica: TP=NENHUM + Partial TP sem alvo final

   // --- Risco 2 sub-page (Trailing/BE/DrawDown) ---
   CLabel   m_c2_hdr1;
   CLabel   m_c2_lTrlAct;  CButton m_c2_bTrlAct;  // Trailing ON/OFF
   CLabel   m_c2_lTrlSt;   CEdit   m_c2_iTrlSt;
   CLabel   m_c2_lTrlSp;   CEdit   m_c2_iTrlSp;
   CLabel   m_c2_lCTrl;    CButton m_c2_bCTrl;     // Comp Spread Trail
   CLabel   m_c2_hdr2;
   CLabel   m_c2_lBEAct;   CButton m_c2_bBEAct;   // BE ON/OFF
   CLabel   m_c2_lBEVal;   CEdit   m_c2_iBEVal;
   CLabel   m_c2_lBEOff;   CEdit   m_c2_iBEOff;
   // --- Limites Diários (movido de BLOQUEIOS para RISCO 2 — Parte 027) ---
   CLabel   m_c2_hdr4;                              // Header "LIMITES DIARIOS"
   CLabel   m_c2_lDLAct;    CButton m_c2_bDLAct;    // Daily Limits ON/OFF toggle
   CLabel   m_c2_lDLTrd;    CEdit   m_c2_iDLTrd;    // Max Trades/Dia
   CLabel   m_c2_lDLLoss;   CEdit   m_c2_iDLLoss;   // Max Loss/Dia
   CLabel   m_c2_lDLGain;   CEdit   m_c2_iDLGain;   // Max Gain/Dia
   CLabel   m_c2_lDLPTA;    CButton m_c2_bDLPTA[2];  // Radio: PARAR | ATIVAR DD
   CLabel   m_c2_hdr3;                              // Header "DRAWDOWN"
   CLabel   m_c2_lDDAct;    CButton m_c2_bDDAct;    // DrawDown ON/OFF
   CLabel   m_c2_lDD;       CEdit   m_c2_iDD;
   CLabel   m_c2_lDDT;      CButton m_c2_bDDT[2];   // Radio: FINANCEIRO | PERCENTUAL
   CLabel   m_c2_lDDPk;     CButton m_c2_bDDPk[2];  // Radio: REALIZADO | FLUTUANTE

   // --- Bloqueios sub-page ---
   CLabel   m_cb_hdr1;
   CLabel   m_cb_lSpr;    CEdit   m_cb_iSpr;
   CLabel   m_cb_lDir;    CButton m_cb_bDir[3];   // Radio: AMBOS | BUY | SELL
   // (Daily Limits movido para RISCO 2 — Parte 027: m_c2_hdr4/lDL*/iDL*/bDL*)
   CLabel   m_cb_hdr3;
   CLabel   m_cb_lLStrOn; CButton m_cb_bLStrOn;   // Loss Streak ON/OFF
   CLabel   m_cb_lLStr;   CEdit   m_cb_iLStr;
   CLabel   m_cb_lLStrA;  CButton m_cb_bLStrA[2]; // Radio: PAUSAR | PARAR DIA
   CLabel   m_cb_lLStrP;  CEdit   m_cb_iLStrP;    // Loss Pause Minutes
   CLabel   m_cb_lWStrOn; CButton m_cb_bWStrOn;   // Win Streak ON/OFF
   CLabel   m_cb_lWStr;   CEdit   m_cb_iWStr;
   CLabel   m_cb_lWStrA;  CButton m_cb_bWStrA[2]; // Radio: PAUSAR | PARAR DIA
   CLabel   m_cb_lWStrP;  CEdit   m_cb_iWStrP;    // Win Pause Minutes
   // (DrawDown movido para RISCO 2 em v1.18 → m_c2_hdr3/lDD/lDDT/lDDPk)
   // --- Filtro de Horário (v1.20) ---
   CLabel   m_cb_hdr4;
   CLabel   m_cb_lTFOn;  CButton m_cb_bTFOn;     // Filtro Horário ON/OFF
   CLabel   m_cb_lTFSH;  CEdit   m_cb_iTFSH;     // Hora Início (0-23)
   CLabel   m_cb_lTFSM;  CEdit   m_cb_iTFSM;     // Min Início (0-59)
   CLabel   m_cb_lTFEH;  CEdit   m_cb_iTFEH;     // Hora Fim (0-23)
   CLabel   m_cb_lTFEM;  CEdit   m_cb_iTFEM;     // Min Fim (0-59)
   CLabel   m_cb_lTFCl;  CButton m_cb_bTFCl;     // Fechar ao Fim ON/OFF
   // --- Fechar Antes do Fim da Sessão (v1.21) ---
   CLabel   m_cb_hdr5;
   CLabel   m_cb_lCBSOn;  CButton m_cb_bCBSOn;   // Prot. Fim Sessão ON/OFF
   CLabel   m_cb_lCBSMin; CEdit   m_cb_iCBSMin;  // Minutos antes do fim

   // --- BLOQUEIO 2: Filtro de Notícias (v1.22) ---
   CLabel   m_cb2_hdr1;                           // "FILTRO NOTICIAS"
   // Janela 1
   CLabel   m_cb2_hdr2;                           // "Janela 1"
   CLabel   m_cb2_lN1On;  CButton m_cb2_bN1On;   // toggle ON/OFF
   CLabel   m_cb2_lN1SH;  CEdit   m_cb2_iN1SH;   // Hora Início
   CLabel   m_cb2_lN1SM;  CEdit   m_cb2_iN1SM;   // Min Início
   CLabel   m_cb2_lN1EH;  CEdit   m_cb2_iN1EH;   // Hora Fim
   CLabel   m_cb2_lN1EM;  CEdit   m_cb2_iN1EM;   // Min Fim
   // Janela 2
   CLabel   m_cb2_hdr3;
   CLabel   m_cb2_lN2On;  CButton m_cb2_bN2On;
   CLabel   m_cb2_lN2SH;  CEdit   m_cb2_iN2SH;
   CLabel   m_cb2_lN2SM;  CEdit   m_cb2_iN2SM;
   CLabel   m_cb2_lN2EH;  CEdit   m_cb2_iN2EH;
   CLabel   m_cb2_lN2EM;  CEdit   m_cb2_iN2EM;
   // Janela 3
   CLabel   m_cb2_hdr4;
   CLabel   m_cb2_lN3On;  CButton m_cb2_bN3On;
   CLabel   m_cb2_lN3SH;  CEdit   m_cb2_iN3SH;
   CLabel   m_cb2_lN3SM;  CEdit   m_cb2_iN3SM;
   CLabel   m_cb2_lN3EH;  CEdit   m_cb2_iN3EH;
   CLabel   m_cb2_lN3EM;  CEdit   m_cb2_iN3EM;

   // --- Outros sub-page ---
   CLabel   m_co_hdr1;
   CLabel   m_co_lSlip;   CEdit   m_co_iSlip;
   CLabel   m_co_lConfl;  CButton m_co_bConfl;
   CLabel   m_co_lMagic;  CEdit   m_co_iMagic;   // Magic Number (v1.28 Parte 027)
   CLabel   m_co_lMagicW;                         // Aviso Magic Number
   CLabel   m_co_lComm;   CEdit   m_co_iComm;    // Comentário das Ordens (v1.28 Parte 027)
   CLabel   m_co_lDbg;    CButton m_co_bDbg;
   CLabel   m_co_lDbgCd;  CEdit   m_co_iDbgCd;

   // APLICAR + status
   CButton  m_cfg_btnApply;
   CLabel   m_cfg_status;
   uint     m_cfgStatusExpiry;     // GetTickCount() em que a msg expira

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
   ENUM_TRADE_DIRECTION      m_cur_direction;
   ENUM_CONFLICT_RESOLUTION  m_cur_conflict;
   ENUM_SL_TYPE              m_cur_slType;
   ENUM_TP_TYPE              m_cur_tpType;
   bool                      m_cur_debug;
   bool                      m_cur_partialTP;
   bool                      m_cur_compSL;
   bool                      m_cur_compTP;
   bool                      m_cur_compTrail;
   bool                      m_cur_trailOn;
   bool                      m_cur_beOn;
   bool                      m_cur_dailyLimitsOn;  // Daily Limits toggle (Parte 027)
   bool                      m_cur_ddOn;
   bool                      m_cur_lossStreakOn;
   bool                      m_cur_winStreakOn;
   bool                      m_cur_tfOn;
   bool                      m_cur_tfClose;
   bool                      m_cur_cbsOn;
   // Novos estados (Parte 023)
   ENUM_STREAK_ACTION        m_cur_lossStreakAction;
   ENUM_STREAK_ACTION        m_cur_winStreakAction;
   ENUM_DRAWDOWN_TYPE        m_cur_ddType;
   ENUM_DRAWDOWN_PEAK_MODE   m_cur_ddPeakMode;
   ENUM_PROFIT_TARGET_ACTION m_cur_profitTargetAction;
   // Filtro de Notícias (v1.22)
   bool                      m_cur_newsOn1;
   bool                      m_cur_newsOn2;
   bool                      m_cur_newsOn3;
   // (MA Cross e RSI ESTRAT state vars movidos para CMACrossPanel / CRSIStrategyPanel)

   // ── Banner de carregamento de config salva (Parte 027) ──
   bool               m_loadBannerVisible;
   CLabel             m_lb_msg;          // "Configurações salvas encontradas (DD/MM HH:MM)"
   CButton            m_lb_btnLoad;      // "CARREGAR"
   CButton            m_lb_btnIgnore;    // "IGNORAR"
   SConfigData        m_pendingLoadData; // Dados carregados pendentes de confirmação

   // ── Prioridade: resolução de conflitos entre estratégias ──
public:
   int               ResolveStrategyPriority(int desired, string excludeName);

   // ── Helpers públicos (usados pelos painéis GUI/Panels/*.mqh) ──
public:
   bool              CreateLV(CLabel &lbl, CLabel &val, string ln, string en, string lt, int y);
   bool              CreateLI(CLabel &lbl, CEdit &inp, string ln, string en, string lt, int y);
   bool              CreateLB(CLabel &lbl, CButton &btn, string ln, string bn, string lt, int y);
   bool              CreateHdr(CLabel &lbl, string name, string text, int y);
   void              SetEV(CLabel &val, string value, color clr = CLR_VALUE);
   bool              AddControl(CWnd &ctrl) { return Add(ctrl); }

   // Radio group helpers
   bool              CreateRadioGroup(CLabel &lbl, CButton &btns[],
                                      string labelName, string btnPrefix,
                                      string labelText,
                                      const string &texts[], int count, int y);
   void              SetRadioSelection(CButton &btns[], int count, int selected);

private:
   int               SLTypeToIndex(ENUM_SL_TYPE t);
   ENUM_SL_TYPE      IndexToSLType(int i);
   int               TPTypeToIndex(ENUM_TP_TYPE t);
   ENUM_TP_TYPE      IndexToTPType(int i);

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

   // ESTRAT. sub-pages
   void              ShowEstratPage(int page);
   void              SetEstratPageVis(int page, bool vis);
   void              UpdateEstratBtnStyles(void);

   // FILTROS sub-pages
   void              ShowFiltrosPage(int page);
   void              SetFiltrosPageVis(int page, bool vis);
   void              UpdateFiltrosBtnStyles(void);

   // Panel factory
   void              RegisterPanels(void);
   void              ApplyConfig(void);

   // Estado visual RISCO (enable/disable campos por tipo SL/TP)
   void              RefreshRiscoState(void);
   void              RefreshRisco2State(void);
   void              RefreshStreakState(void);
   void              RefreshBloqTimeFilter(void);
   void              SetEditEnabled(CLabel &lbl, CEdit &inp, bool enable);
   void              SetButtonEnabled(CLabel &lbl, CButton &btn, bool enable);

   // Handlers de clique
   void              OnClickTab0(void);
   void              OnClickTab1(void);
   void              OnClickTab2(void);
   void              OnClickTab3(void);
   void              OnClickTab4(void);
   void              OnClickCfgRisco(void);
   void              OnClickCfgRisco2(void);
   void              OnClickCfgBloq(void);
   void              OnClickCfgOutros(void);
   void              OnClickApply(void);
   void              OnClickDirection(int selected);
   void              OnClickConflict(void);
   void              OnClickDebug(void);
   void              OnClickPartialTP(void);
   void              OnClickSLType(int selected);
   void              OnClickTPType(int selected);
   void              OnClickCompSL(void);
   void              OnClickCompTP(void);
   void              OnClickCompTrail(void);
   void              OnClickTrailToggle(void);
   void              OnClickBEToggle(void);
   void              OnClickDailyLimitsToggle(void);  // Parte 027
   void              RefreshDailyLimitsState(void);    // Parte 027
   void              OnClickDLProfitTargetAction(int selected);  // Parte 027
   void              OnClickDDToggle(void);
   void              OnClickLossStreakToggle(void);
   void              OnClickWinStreakToggle(void);
   void              OnClickTFToggle(void);
   void              OnClickTFClose(void);
   void              OnClickCBSToggle(void);
   void              RefreshBloqSessionEnd(void);
   void              OnClickLossStreakAction(int selected);
   void              OnClickWinStreakAction(int selected);
   void              OnClickDDType(int selected);
   void              OnClickDDPeakMode(int selected);
   // OnClickProfitTargetAction removido (Parte 027): substituído por OnClickDLProfitTargetAction
   void              OnClickCfgBloq2(void);
   void              OnClickNewsOn1(void);
   void              OnClickNewsOn2(void);
   void              OnClickNewsOn3(void);
   void              RefreshNewsState(int w);
   // (MA Cross / RSI handlers movidos para GUI/Panels/MACrossPanel.mqh e RSIStrategyPanel.mqh)
   // (Trend/RSI Filter handlers movidos para GUI/Panels/TrendFilterPanel.mqh e RSIFilterPanel.mqh)
   // (CycleTF, TFName, ApplyToggleStyle, etc. movidos para GUI/PanelUtils.mqh)

   // ── Persistência (Parte 027) ──
   void              CollectConfigData(SConfigData &data);
   void              ApplyLoadedConfig(const SConfigData &data);
   // Load banner handlers
   void              OnClickLoadBanner(void);
   void              OnClickIgnoreBanner(void);

protected:
   virtual bool      CreateButtonClose(void) { return true; }

public:
                     CEPBotPanel(void);
                    ~CEPBotPanel(void);

   bool              Init(CLogger *logger, CBlockers *blockers, CRiskManager *risk,
                          CTradeManager *trade, CSignalManager *signal,
                          CMACrossStrategy *maCross, CRSIStrategy *rsi,
                          CBollingerBandsStrategy *bb,
                          CTrendFilter *trend, CRSIFilter *rsiFilt,
                          CBollingerBandsFilter *bbFilt,
                          int magic, string symbol);

   void              ReconnectModules(CLogger *logger, CBlockers *blockers, CRiskManager *risk,
                                     CTradeManager *trade, CSignalManager *signal,
                                     CMACrossStrategy *maCross, CRSIStrategy *rsi,
                                     CBollingerBandsStrategy *bb,
                                     CTrendFilter *trend, CRSIFilter *rsiFilt,
                                     CBollingerBandsFilter *bbFilt);

   bool              CreatePanel(long chart, string name, int subwin,
                                 int x1, int y1, int x2, int y2);
   void              Update(void);
   void              MouseProtection(const int x, const int y);
   virtual bool      OnEvent(const int id, const long &lparam,
                             const double &dparam, const string &sparam);

   // ── Persistência pública (Parte 027) ──
   void              SaveCurrentConfig(void);
   void              ShowLoadBanner(const SConfigData &data);
   void              HideLoadBanner(void);
   bool              HasSavedConfig(void);

public:
   virtual void      ChartEvent(const int id, const long &lparam,
                                const double &dparam, const string &sparam);

  };

//+------------------------------------------------------------------+
//| Construtor / Destrutor                                            |
//+------------------------------------------------------------------+
CEPBotPanel::CEPBotPanel(void)
   : m_activeTab(TAB_STATUS), m_cfgPage(CFG_RISCO),
     m_estratPage(1), m_filtrosPage(1),
     m_logger(NULL), m_blockers(NULL), m_riskManager(NULL),
     m_tradeManager(NULL), m_signalManager(NULL),
     m_maCross(NULL), m_rsiStrategy(NULL),
     m_trendFilter(NULL), m_rsiFilter(NULL),
     m_stratPanelCount(0), m_filtPanelCount(0),
     m_stratBtnCount(0), m_filtBtnCount(0),
     m_magicNumber(0), m_symbol(""),
     m_origDragTrade(true), m_origMouseScroll(true), m_mouseOverPanel(false),
     m_cfg_hasTP(false), m_cfg_hasTrailing(false), m_cfg_hasBE(false),
     m_cfg_hasDailyLimits(false), m_cfg_hasStreak(false), m_cfg_hasDrawdown(false),
     m_cfg_hasATR(false), m_cfg_hasRange(false),
     m_cur_direction(DIRECTION_BOTH), m_cur_conflict(CONFLICT_PRIORITY),
     m_cur_slType(SL_FIXED), m_cur_tpType(TP_NONE),
     m_cur_debug(false), m_cur_partialTP(false),
     m_cur_compSL(false), m_cur_compTP(false), m_cur_compTrail(false),
     m_cur_trailOn(false), m_cur_beOn(false),
     m_cur_dailyLimitsOn(false),
     m_cur_ddOn(false), m_cur_lossStreakOn(false), m_cur_winStreakOn(false),
     m_cur_tfOn(false), m_cur_tfClose(false), m_cur_cbsOn(false),
     m_cur_lossStreakAction(STREAK_PAUSE), m_cur_winStreakAction(STREAK_PAUSE),
     m_cur_ddType(DD_FINANCIAL), m_cur_ddPeakMode(DD_PEAK_REALIZED_ONLY),
     m_cur_profitTargetAction(PROFIT_ACTION_STOP),
     m_cfgStatusExpiry(0),
     m_loadBannerVisible(false)
  {
  }

CEPBotPanel::~CEPBotPanel(void)
  {
   ChartSetInteger(0, CHART_DRAG_TRADE_LEVELS, m_origDragTrade);
   ChartSetInteger(0, CHART_MOUSE_SCROLL, m_origMouseScroll);
   for(int i = 0; i < m_stratPanelCount; i++)
     { delete m_stratPanels[i]; m_stratPanels[i] = NULL; }
   for(int i = 0; i < m_filtPanelCount; i++)
     { delete m_filtPanels[i]; m_filtPanels[i] = NULL; }
  }

//+------------------------------------------------------------------+
//| Init — recebe ponteiros de todos os módulos                       |
//+------------------------------------------------------------------+
bool CEPBotPanel::Init(CLogger *logger, CBlockers *blockers, CRiskManager *risk,
                       CTradeManager *trade, CSignalManager *signal,
                       CMACrossStrategy *maCross, CRSIStrategy *rsi,
                       CBollingerBandsStrategy *bb,
                       CTrendFilter *trend, CRSIFilter *rsiFilt,
                       CBollingerBandsFilter *bbFilt,
                       int magic, string symbol)
  {
   m_logger       = logger;
   m_blockers     = blockers;
   m_riskManager  = risk;
   m_tradeManager = trade;
   m_signalManager = signal;
   m_maCross      = maCross;
   m_rsiStrategy  = rsi;
   m_bbStrategy   = bb;
   m_trendFilter  = trend;
   m_rsiFilter    = rsiFilt;
   m_bbFilter     = bbFilt;
   m_magicNumber  = magic;
   m_symbol       = symbol;
   RegisterPanels();
   return true;
  }

//+------------------------------------------------------------------+
//| ReconnectModules — atualiza ponteiros após troca de TF            |
//| NÃO chama RegisterPanels() (sub-painéis gráficos já existem).    |
//| Apenas re-injeta ponteiros novos no painel e nos sub-painéis.     |
//+------------------------------------------------------------------+
void CEPBotPanel::ReconnectModules(CLogger *logger, CBlockers *blockers, CRiskManager *risk,
                                   CTradeManager *trade, CSignalManager *signal,
                                   CMACrossStrategy *maCross, CRSIStrategy *rsi,
                                   CBollingerBandsStrategy *bb,
                                   CTrendFilter *trend, CRSIFilter *rsiFilt,
                                   CBollingerBandsFilter *bbFilt)
  {
   // 1) Atualizar ponteiros do painel principal
   m_logger       = logger;
   m_blockers     = blockers;
   m_riskManager  = risk;
   m_tradeManager = trade;
   m_signalManager = signal;
   m_maCross      = maCross;
   m_rsiStrategy  = rsi;
   m_bbStrategy   = bb;
   m_trendFilter  = trend;
   m_rsiFilter    = rsiFilt;
   m_bbFilter     = bbFilt;

   // 2) Propagar para sub-painéis de estratégia via cast tipado
   //    (mesma ordem que RegisterPanels: MACross, RSI, BB)
   int si = 0;
   if(maCross != NULL && si < m_stratPanelCount)
     { CMACrossPanel *p = dynamic_cast<CMACrossPanel *>(m_stratPanels[si++]); if(p != NULL) p.SetStrategy(maCross); }
   if(rsi != NULL && si < m_stratPanelCount)
     { CRSIStrategyPanel *p = dynamic_cast<CRSIStrategyPanel *>(m_stratPanels[si++]); if(p != NULL) p.SetStrategy(rsi); }
   if(bb != NULL && si < m_stratPanelCount)
     { CBollingerBandsPanel *p = dynamic_cast<CBollingerBandsPanel *>(m_stratPanels[si++]); if(p != NULL) p.SetStrategy(bb); }

   // 3) Propagar para sub-painéis de filtro via cast tipado
   //    (mesma ordem que RegisterPanels: Trend, RSI, BB)
   int fi = 0;
   if(trend != NULL && fi < m_filtPanelCount)
     { CTrendFilterPanel *p = dynamic_cast<CTrendFilterPanel *>(m_filtPanels[fi++]); if(p != NULL) p.SetFilter(trend); }
   if(rsiFilt != NULL && fi < m_filtPanelCount)
     { CRSIFilterPanel *p = dynamic_cast<CRSIFilterPanel *>(m_filtPanels[fi++]); if(p != NULL) p.SetFilter(rsiFilt); }
   if(bbFilt != NULL && fi < m_filtPanelCount)
     { CBollingerBandsFilterPanel *p = dynamic_cast<CBollingerBandsFilterPanel *>(m_filtPanels[fi++]); if(p != NULL) p.SetFilter(bbFilt); }

   // 4) Restaurar visibilidade: só se painel NÃO está minimizado.
   //    Se minimizado, CAppDialog já escondeu todos os controles — ShowTab()
   //    os traria de volta "soltos" no gráfico.
   if(!m_minimized)
      ShowTab(m_activeTab);
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

// ── Banner de Load Config (inicialmente oculto) ──
   int bannerY = CONTENT_TOP + 2;
   if(!m_lb_msg.Create(m_chart_id, PFX + "lb_msg", m_subwin,
                       COL_LABEL_X, bannerY, COL_LABEL_X + 380, bannerY + PANEL_GAP_Y))
      return false;
   m_lb_msg.Text("");
   m_lb_msg.Color(CLR_WARNING);
   m_lb_msg.FontSize(8);
   if(!Add(m_lb_msg)) return false;
   m_lb_msg.Hide();

   int btnY = bannerY + PANEL_GAP_Y + 2;
   if(!m_lb_btnLoad.Create(m_chart_id, PFX + "lb_load", m_subwin,
                           COL_LABEL_X, btnY, COL_LABEL_X + 100, btnY + 20))
      return false;
   m_lb_btnLoad.Text("CARREGAR");
   m_lb_btnLoad.FontSize(8);
   m_lb_btnLoad.ColorBackground(C'0,140,60');
   m_lb_btnLoad.Color(clrWhite);
   if(!Add(m_lb_btnLoad)) return false;
   m_lb_btnLoad.Hide();

   if(!m_lb_btnIgnore.Create(m_chart_id, PFX + "lb_ignore", m_subwin,
                             COL_LABEL_X + 110, btnY, COL_LABEL_X + 210, btnY + 20))
      return false;
   m_lb_btnIgnore.Text("IGNORAR");
   m_lb_btnIgnore.FontSize(8);
   m_lb_btnIgnore.ColorBackground(C'160,60,60');
   m_lb_btnIgnore.Color(clrWhite);
   if(!Add(m_lb_btnIgnore)) return false;
   m_lb_btnIgnore.Hide();

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
//| ChartEvent — intercepta CHARTEVENT_OBJECT_CLICK antes de tudo     |
//| (nivel mais alto: recebe o evento RAW do MT5, antes de CAppDialog)|
//+------------------------------------------------------------------+
void CEPBotPanel::ChartEvent(const int id, const long &lparam,
                              const double &dparam, const string &sparam)
  {
// ══════════════════════════════════════════════════════════════════
// Minimizado: passar tudo direto para CAppDialog (só o botão
// minimize/maximize precisa responder — nossos controles estão ocultos)
// ══════════════════════════════════════════════════════════════════
   if(m_minimized)
     {
      CAppDialog::ChartEvent(id, lparam, dparam, sparam);
      return;
     }

// ══════════════════════════════════════════════════════════════════
// CHARTEVENT_OBJECT_CLICK: interceptar pelo nome (sparam)
// CAppDialog::OnEvent NÃO recebe este evento — ele é processado
// internamente por CAppDialog::ChartEvent. Por isso usamos este
// override para capturar nossos botões ANTES do CAppDialog.
// ══════════════════════════════════════════════════════════════════
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      // Abas principais
      if(sparam == m_btnTab0.Name()) { m_btnTab0.Pressed(false); OnClickTab0(); ChartRedraw(); return; }
      if(sparam == m_btnTab1.Name()) { m_btnTab1.Pressed(false); OnClickTab1(); ChartRedraw(); return; }
      if(sparam == m_btnTab2.Name()) { m_btnTab2.Pressed(false); OnClickTab2(); ChartRedraw(); return; }
      if(sparam == m_btnTab3.Name()) { m_btnTab3.Pressed(false); OnClickTab3(); ChartRedraw(); return; }
      if(sparam == m_btnTab4.Name()) { m_btnTab4.Pressed(false); OnClickTab4(); ChartRedraw(); return; }

      // ESTRAT.: botões de navegação (genérico)
      for(int i = 0; i < m_stratBtnCount; i++)
        {
         if(sparam == m_e_stratBtns[i].Name())
           { m_e_stratBtns[i].Pressed(false); ShowEstratPage(i); ChartRedraw(); return; }
        }
      // ESTRAT.: eventos dos painéis (genérico)
      for(int i = 0; i < m_stratPanelCount; i++)
        {
         if(m_stratPanels[i] != NULL && m_stratPanels[i].OnClick(sparam)) { ChartRedraw(); return; }
        }

      // FILTROS: botões de navegação (genérico)
      for(int i = 0; i < m_filtBtnCount; i++)
        {
         if(sparam == m_f_filtBtns[i].Name())
           { m_f_filtBtns[i].Pressed(false); ShowFiltrosPage(i); ChartRedraw(); return; }
        }
      // FILTROS: eventos dos painéis (genérico)
      for(int i = 0; i < m_filtPanelCount; i++)
        {
         if(m_filtPanels[i] != NULL && m_filtPanels[i].OnClick(sparam)) { ChartRedraw(); return; }
        }

      // CONFIG: sub-páginas
      if(sparam == m_cfg_btnRisco.Name())  { m_cfg_btnRisco.Pressed(false);  OnClickCfgRisco();  ChartRedraw(); return; }
      if(sparam == m_cfg_btnRisco2.Name()) { m_cfg_btnRisco2.Pressed(false); OnClickCfgRisco2(); ChartRedraw(); return; }
      if(sparam == m_cfg_btnBloq.Name())   { m_cfg_btnBloq.Pressed(false);   OnClickCfgBloq();   ChartRedraw(); return; }
      if(sparam == m_cfg_btnOutros.Name()) { m_cfg_btnOutros.Pressed(false); OnClickCfgOutros(); ChartRedraw(); return; }
      if(sparam == m_cfg_btnBloq2.Name())  { m_cfg_btnBloq2.Pressed(false);  OnClickCfgBloq2();  ChartRedraw(); return; }

      // CONFIG: APLICAR
      if(sparam == m_cfg_btnApply.Name())  { m_cfg_btnApply.Pressed(false); OnClickApply(); ChartRedraw(); return; }

      // CONFIG: radio groups (SL Type, TP Type, Direction)
      for(int i = 0; i < 3; i++)
        {
         if(sparam == m_cr_bSLT[i].Name()) { OnClickSLType(i);    ChartRedraw(); return; }
         if(sparam == m_cr_bTPT[i].Name()) { OnClickTPType(i);    ChartRedraw(); return; }
         if(sparam == m_cb_bDir[i].Name()) { OnClickDirection(i);  ChartRedraw(); return; }
        }

      // CONFIG: RISCO toggles
      if(sparam == m_cr_bCSL.Name()) { OnClickCompSL();  ChartRedraw(); return; }
      if(sparam == m_cr_bCTP.Name()) { OnClickCompTP();  ChartRedraw(); return; }

      // CONFIG: RISCO toggles (Partial TP agora em RISCO)
      if(sparam == m_cr_bPTP.Name()) { OnClickPartialTP(); ChartRedraw(); return; }

      // CONFIG: RISCO 2 toggles
      if(sparam == m_c2_bDLAct.Name())  { OnClickDailyLimitsToggle(); ChartRedraw(); return; }
      if(sparam == m_c2_bTrlAct.Name()) { OnClickTrailToggle(); ChartRedraw(); return; }
      if(sparam == m_c2_bBEAct.Name())  { OnClickBEToggle();    ChartRedraw(); return; }
      if(sparam == m_c2_bCTrl.Name())   { OnClickCompTrail();   ChartRedraw(); return; }
      if(sparam == m_c2_bDDAct.Name())  { OnClickDDToggle();    ChartRedraw(); return; }

      // CONFIG: BLOQUEIOS toggles
      if(sparam == m_cb_bLStrOn.Name()) { OnClickLossStreakToggle(); ChartRedraw(); return; }
      if(sparam == m_cb_bWStrOn.Name()) { OnClickWinStreakToggle();  ChartRedraw(); return; }
      if(sparam == m_cb_bTFOn.Name())   { OnClickTFToggle();         ChartRedraw(); return; }
      if(sparam == m_cb_bTFCl.Name())   { OnClickTFClose();          ChartRedraw(); return; }
      if(sparam == m_cb_bCBSOn.Name())  { OnClickCBSToggle();        ChartRedraw(); return; }

      // CONFIG: BLOQUEIOS radio groups (2 opções cada)
      for(int i = 0; i < 2; i++)
        {
         if(sparam == m_cb_bLStrA[i].Name())  { OnClickLossStreakAction(i);   ChartRedraw(); return; }
         if(sparam == m_cb_bWStrA[i].Name())  { OnClickWinStreakAction(i);    ChartRedraw(); return; }
        }
      // CONFIG: RISCO 2 radio groups — Daily Limits + DrawDown
      for(int i = 0; i < 2; i++)
        {
         if(sparam == m_c2_bDLPTA[i].Name())  { OnClickDLProfitTargetAction(i); ChartRedraw(); return; }
         if(sparam == m_c2_bDDT[i].Name())    { OnClickDDType(i);               ChartRedraw(); return; }
         if(sparam == m_c2_bDDPk[i].Name())   { OnClickDDPeakMode(i);           ChartRedraw(); return; }
        }

      // CONFIG: BLOQUEIO 2 — news window toggles
      if(sparam == m_cb2_bN1On.Name()) { m_cb2_bN1On.Pressed(false); OnClickNewsOn1(); ChartRedraw(); return; }
      if(sparam == m_cb2_bN2On.Name()) { m_cb2_bN2On.Pressed(false); OnClickNewsOn2(); ChartRedraw(); return; }
      if(sparam == m_cb2_bN3On.Name()) { m_cb2_bN3On.Pressed(false); OnClickNewsOn3(); ChartRedraw(); return; }

      // BANNER: Load/Ignore config
      if(sparam == m_lb_btnLoad.Name())   { m_lb_btnLoad.Pressed(false);   OnClickLoadBanner();   ChartRedraw(); return; }
      if(sparam == m_lb_btnIgnore.Name()) { m_lb_btnIgnore.Pressed(false); OnClickIgnoreBanner(); ChartRedraw(); return; }

      // CONFIG: OUTROS toggles
      if(sparam == m_co_bConfl.Name()) { OnClickConflict(); ChartRedraw(); return; }
      if(sparam == m_co_bDbg.Name())   { OnClickDebug();    ChartRedraw(); return; }

      // Não é nosso → cai pro CAppDialog abaixo
     }

// CAppDialog: processa tudo que não interceptamos (close, minimize,
// drag, CEdit focus, etc.)
   CAppDialog::ChartEvent(id, lparam, dparam, sparam);
  }

//+------------------------------------------------------------------+
//| OnEvent — chamado pelo CAppDialog internamente                     |
//| (CAppDialog::ChartEvent chama OnEvent para eventos custom)        |
//+------------------------------------------------------------------+
bool CEPBotPanel::OnEvent(const int id, const long &lparam,
                           const double &dparam, const string &sparam)
  {
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
// Fix encavalamento: re-esconder sub-páginas inativas da aba ativa
   if(m_activeTab == TAB_CONFIG)
     {
      for(int p = 0; p < CFG_PAGE_COUNT; p++)
        {
         if(p != (int)m_cfgPage)
            SetCfgPageVis((ENUM_CONFIG_PAGE)p, false);
        }
     }
   if(m_activeTab == TAB_ESTRATEGIAS)
     {
      if(m_estratPage != 0)
        { m_ov_lStrHdr.Hide(); for(int i=0;i<MAX_OVERVIEW_ROWS;i++){m_ov_eStrName[i].Hide();m_ov_eStrStatus[i].Hide();} }
      for(int p = 0; p < m_stratPanelCount; p++)
        { if(p+1 != m_estratPage && m_stratPanels[p] != NULL) m_stratPanels[p].Hide(); }
     }
   if(m_activeTab == TAB_FILTROS)
     {
      if(m_filtrosPage != 0)
        { m_ov_lFiltHdr.Hide(); for(int i=0;i<MAX_OVERVIEW_ROWS;i++){m_ov_eFiltName[i].Hide();m_ov_eFiltStatus[i].Hide();} }
      for(int p = 0; p < m_filtPanelCount; p++)
        { if(p+1 != m_filtrosPage && m_filtPanels[p] != NULL) m_filtPanels[p].Hide(); }
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
                    m_s_lBlocked.Show(); m_s_eBlocked.Show();
                    m_s_hdrSM.Show(); m_s_lStrats.Show(); m_s_eStrats.Show();
                    m_s_lFilts.Show(); m_s_eFilts.Show(); m_s_lConflict.Show(); m_s_eConflict.Show(); }
         else    { m_s_hdr1.Hide(); m_s_lTrading.Hide(); m_s_eTrading.Hide();
                    m_s_lBlocker.Hide(); m_s_eBlocker.Hide(); m_s_lSpread.Hide(); m_s_eSpread.Hide();
                    m_s_lTime.Hide(); m_s_eTime.Hide();
                    m_s_hdr2.Hide(); m_s_lHasPos.Hide(); m_s_eHasPos.Hide();
                    m_s_lTicket.Hide(); m_s_eTicket.Hide(); m_s_lPosType.Hide(); m_s_ePosType.Hide();
                    m_s_lPosProfit.Hide(); m_s_ePosProfit.Hide(); m_s_lBE.Hide(); m_s_eBE.Hide();
                    m_s_lTrail.Hide(); m_s_eTrail.Hide(); m_s_lPartial.Hide(); m_s_ePartial.Hide();
                    m_s_hdr3.Hide(); m_s_lSignal.Hide(); m_s_eSignal.Hide();
                    m_s_lBlocked.Hide(); m_s_eBlocked.Hide();
                    m_s_hdrSM.Hide(); m_s_lStrats.Hide(); m_s_eStrats.Hide();
                    m_s_lFilts.Hide(); m_s_eFilts.Hide(); m_s_lConflict.Hide(); m_s_eConflict.Hide(); }
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
                    m_r_hdr4.Show();
                    m_r_lDDLim.Show(); m_r_eDDLim.Show();
                    m_r_lDDMode.Show(); m_r_eDDMode.Show();
                    m_r_lDD.Show(); m_r_eDD.Show();
                    m_r_lPeak.Show(); m_r_ePeak.Show();
                    m_r_lStreak.Show(); m_r_eStreak.Show();
                    m_r_lLossStrk.Show(); m_r_eLossStrk.Show();
                    m_r_lWinStrk.Show(); m_r_eWinStrk.Show(); }
         else    { m_r_hdr1.Hide(); m_r_lProfit.Hide(); m_r_eProfit.Hide();
                    m_r_lGains.Hide(); m_r_eGains.Hide(); m_r_lTotalLoss.Hide(); m_r_eTotalLoss.Hide();
                    m_r_hdr2.Hide(); m_r_lTrades.Hide(); m_r_eTrades.Hide();
                    m_r_lWins.Hide(); m_r_eWins.Hide(); m_r_lLosses.Hide(); m_r_eLosses.Hide();
                    m_r_lDraws.Hide(); m_r_eDraws.Hide();
                    m_r_hdr3.Hide(); m_r_lWinRate.Hide(); m_r_eWinRate.Hide();
                    m_r_lPayoff.Hide(); m_r_ePayoff.Hide(); m_r_lPF.Hide(); m_r_ePF.Hide();
                    m_r_hdr4.Hide();
                    m_r_lDDLim.Hide(); m_r_eDDLim.Hide();
                    m_r_lDDMode.Hide(); m_r_eDDMode.Hide();
                    m_r_lDD.Hide(); m_r_eDD.Hide();
                    m_r_lPeak.Hide(); m_r_ePeak.Hide();
                    m_r_lStreak.Hide(); m_r_eStreak.Hide();
                    m_r_lLossStrk.Hide(); m_r_eLossStrk.Hide();
                    m_r_lWinStrk.Hide(); m_r_eWinStrk.Hide(); }
         break;
        }
      case TAB_ESTRATEGIAS:
        {
         if(vis)
           {
            for(int i = 0; i < m_stratBtnCount; i++) m_e_stratBtns[i].Show();
            ShowEstratPage(m_estratPage);
           }
         else
           {
            for(int i = 0; i < m_stratBtnCount; i++) m_e_stratBtns[i].Hide();
            m_ov_lStrHdr.Hide();
            for(int i = 0; i < MAX_OVERVIEW_ROWS; i++) { m_ov_eStrName[i].Hide(); m_ov_eStrStatus[i].Hide(); }
            for(int i = 0; i < m_stratPanelCount; i++) if(m_stratPanels[i] != NULL) m_stratPanels[i].Hide();
           }
         break;
        }
      case TAB_FILTROS:
        {
         if(vis)
           {
            for(int i = 0; i < m_filtBtnCount; i++) m_f_filtBtns[i].Show();
            ShowFiltrosPage(m_filtrosPage);
           }
         else
           {
            for(int i = 0; i < m_filtBtnCount; i++) m_f_filtBtns[i].Hide();
            m_ov_lFiltHdr.Hide();
            for(int i = 0; i < MAX_OVERVIEW_ROWS; i++) { m_ov_eFiltName[i].Hide(); m_ov_eFiltStatus[i].Hide(); }
            for(int i = 0; i < m_filtPanelCount; i++) if(m_filtPanels[i] != NULL) m_filtPanels[i].Hide();
           }
         break;
        }
      case TAB_CONFIG:
        {
         if(vis)
           {
            // Sub-page buttons + apply + status
            m_cfg_btnRisco.Show(); m_cfg_btnRisco2.Show();
            m_cfg_btnBloq.Show(); m_cfg_btnOutros.Show(); m_cfg_btnBloq2.Show();
            m_cfg_btnApply.Show(); m_cfg_status.Show();
            // Show active sub-page
            ShowCfgPage(m_cfgPage);
           }
         else
           {
            m_cfg_btnRisco.Hide(); m_cfg_btnRisco2.Hide();
            m_cfg_btnBloq.Hide(); m_cfg_btnOutros.Hide(); m_cfg_btnBloq2.Hide();
            m_cfg_btnApply.Hide(); m_cfg_status.Hide();
            SetCfgPageVis(CFG_RISCO, false);
            SetCfgPageVis(CFG_RISCO2, false);
            SetCfgPageVis(CFG_BLOQUEIOS, false);
            SetCfgPageVis(CFG_OUTROS, false);
            SetCfgPageVis(CFG_BLOQ2, false);
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
   m_btnTab0.Pressed(false); m_btnTab1.Pressed(false); m_btnTab2.Pressed(false);
   m_btnTab3.Pressed(false); m_btnTab4.Pressed(false);

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
   // Não atualiza se minimizado — evita labels "soltos" no gráfico
   if(m_minimized)
      return;

   switch(m_activeTab)
     {
      case TAB_STATUS:      UpdateStatus();       break;
      case TAB_RESULTADOS:  UpdateResultados();   break;
      case TAB_ESTRATEGIAS:
         UpdateEstrategias();
         break;
      case TAB_FILTROS:
         UpdateFiltros();
         break;
      case TAB_CONFIG:
         if(m_cfgStatusExpiry > 0 && GetTickCount() >= m_cfgStatusExpiry)
           { m_cfg_status.Text(""); m_cfgStatusExpiry = 0; ChartRedraw(); }
         break;
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

// Painéis de estratégia/filtro (definem CMACrossPanel, etc.)
// Incluídos APÓS CEPBotPanel — painéis usam CEPBotPanel* com acesso completo
#include "Panels/MACrossPanel.mqh"
#include "Panels/RSIStrategyPanel.mqh"
#include "Panels/BollingerBandsPanel.mqh"
#include "Panels/TrendFilterPanel.mqh"
#include "Panels/RSIFilterPanel.mqh"
#include "Panels/BollingerBandsFilterPanel.mqh"

#include "PanelTabStatus.mqh"
#include "PanelTabResultados.mqh"
#include "PanelTabEstrategias.mqh"
#include "PanelTabFiltros.mqh"
#include "PanelTabConfig.mqh"
#include "PanelPersistence.mqh"

//+------------------------------------------------------------------+
//| RegisterPanels — factory method: cria sub-páginas de estratégia  |
//| e filtro. Adicionar nova estratégia = 2 linhas aqui.             |
//+------------------------------------------------------------------+
void CEPBotPanel::RegisterPanels(void)
  {
   m_stratPanelCount = 0;
   m_filtPanelCount  = 0;
   ArrayResize(m_stratPanels, 0);
   ArrayResize(m_filtPanels,  0);

   // ── Estratégias ──
   if(m_maCross != NULL)
     {
      ArrayResize(m_stratPanels, ++m_stratPanelCount);
      m_stratPanels[m_stratPanelCount - 1] = new CMACrossPanel(m_maCross);
     }
   if(m_rsiStrategy != NULL)
     {
      ArrayResize(m_stratPanels, ++m_stratPanelCount);
      m_stratPanels[m_stratPanelCount - 1] = new CRSIStrategyPanel(m_rsiStrategy);
     }
   if(m_bbStrategy != NULL)
     {
      ArrayResize(m_stratPanels, ++m_stratPanelCount);
      m_stratPanels[m_stratPanelCount - 1] = new CBollingerBandsPanel(m_bbStrategy);
     }

   // ── Filtros ──
   if(m_trendFilter != NULL)
     {
      ArrayResize(m_filtPanels, ++m_filtPanelCount);
      m_filtPanels[m_filtPanelCount - 1] = new CTrendFilterPanel(m_trendFilter);
     }
   if(m_rsiFilter != NULL)
     {
      ArrayResize(m_filtPanels, ++m_filtPanelCount);
      m_filtPanels[m_filtPanelCount - 1] = new CRSIFilterPanel(m_rsiFilter);
     }
   if(m_bbFilter != NULL)
     {
      ArrayResize(m_filtPanels, ++m_filtPanelCount);
      m_filtPanels[m_filtPanelCount - 1] = new CBollingerBandsFilterPanel(m_bbFilter);
     }
  }

//+------------------------------------------------------------------+
//| ResolveStrategyPriority — auto-ajuste de prioridade               |
//| Se 'desired' já está em uso por outra estratégia, incrementa      |
//| até encontrar um valor livre.                                      |
//+------------------------------------------------------------------+
int CEPBotPanel::ResolveStrategyPriority(int desired, string excludeName)
  {
   if(m_signalManager == NULL) return desired;
   for(int attempt = 0; attempt < 100; attempt++)
     {
      bool conflict = false;
      for(int i = 0; i < m_signalManager.GetStrategyCount(); i++)
        {
         CStrategyBase *s = m_signalManager.GetStrategy(i);
         if(s != NULL && s.GetName() != excludeName && s.GetPriority() == desired)
           { conflict = true; break; }
        }
      if(!conflict) return desired;
      desired++;
     }
   return desired;
  }

//+------------------------------------------------------------------+
