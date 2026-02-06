//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                                         Copyright 2026, EP Filho |
//|                       Sistema de Cálculo de Risco - EPBot Matrix |
//|                                   Versão 3.12 - Claude Parte 021 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "3.12" 

// ═══════════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════════
#include "Logger.mqh"

// ═══════════════════════════════════════════════════════════════════
// ARQUITETURA LIMPA v3.0:
// - RiskManager APENAS CALCULA valores
// - Core/TradeExecutor EXECUTA as operações
// - Stateless - sem gerenciar tickets ou estado de posições
// 
// NOVIDADES v3.0:
// + Partial Take Profit (até 3 níveis configuráveis)
// + Trailing/Breakeven com ativação condicional (ALWAYS/AFTER_TP1/AFTER_TP2/NEVER)
//
// NOVIDADES v3.01:
// + Padrão Input + Working variables para hot reload
// + Métodos Set para alterar parâmetros em runtime
// + Getters para Input e Working values
// + ValidateSLTP() - Validação contra níveis mínimos do broker
//
// NOVIDADES v3.02:
// + REMOVIDO: inp_UseTrailing e inp_UseBreakeven (redundância)
// + SIMPLIFICADO: Trailing/BE ativados via enum (NEVER = desligado)
//
// NOVIDADES v3.10:
// + Migração para Logger v3.00 (5 níveis + throttle inteligente)
// + Todas as mensagens classificadas (ERROR/EVENT/DEBUG)
// + PrintConfiguration() agora usa LOG_DEBUG
//
// NOVIDADES v3.11:
// + TP FALLBACK: Quando Partial TP ativo, usa TP Fixo como proteção
// + Protege contra falha de conexão/PC desligado
// + TP será removido pelo TradeManager após TP2
//
// NOVIDADES v3.12:
// + Fix: Funções Hot Reload só logam quando há mudança real nos valores
// + Evita logs redundantes na inicialização/recarregamento
// ═══════════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Enumerações - Tipos de Gestão de Risco                           |
//+------------------------------------------------------------------+

// Tipo de Stop Loss
enum ENUM_SL_TYPE
  {
   SL_FIXED,      // Fixo (pontos)
   SL_RANGE,      // Dinâmico (Range)
   SL_ATR         // Dinâmico (ATR)
  };

// Tipo de Take Profit
enum ENUM_TP_TYPE
  {
   TP_FIXED,      // Fixo (em pontos)
   TP_ATR,        // Dinâmico (ATR)
   TP_NONE        // Sem Take Profit
  };

// Tipo de Trailing Stop
enum ENUM_TRAILING_TYPE
  {
   TRAILING_FIXED,    // Fixo (em pontos)
   TRAILING_ATR       // Dinâmico (ATR)
  };

// Tipo de Breakeven
enum ENUM_BE_TYPE
  {
   BE_FIXED,          // Fixo (pontos)
   BE_ATR             // Dinâmico (ATR)
  };

// Ativação Condicional do Trailing Stop
enum ENUM_TRAILING_ACTIVATION
  {
   TRAILING_ALWAYS,       // Sempre (desde entrada)
   TRAILING_AFTER_TP1,    // Após fechar primeira parcial
   TRAILING_AFTER_TP2,    // Após fechar segunda parcial
   TRAILING_NEVER         // Nunca (desativado)
  };

// Ativação Condicional do Breakeven
enum ENUM_BE_ACTIVATION
  {
   BE_ALWAYS,             // Sempre (quando atingir distância)
   BE_AFTER_TP1,          // Após fechar primeira parcial
   BE_AFTER_TP2,          // Após fechar segunda parcial
   BE_NEVER               // Nunca (desativado)
  };

//+------------------------------------------------------------------+
//| Estrutura: Resultado de Cálculo de Trailing                      |
//+------------------------------------------------------------------+
struct STrailingResult
  {
   bool              should_move;      // Deve mover o SL?
   double            new_sl_price;     // Novo preço de SL
   string            reason;           // Razão (para log)
  };

//+------------------------------------------------------------------+
//| Estrutura: Resultado de Cálculo de Breakeven                     |
//+------------------------------------------------------------------+
struct SBreakevenResult
  {
   bool              should_activate;  // Deve ativar BE?
   double            new_sl_price;     // Novo preço de SL
   string            reason;           // Razão (para log)
  };

//+------------------------------------------------------------------+
//| Estrutura: Nível de Take Profit Parcial                          |
//+------------------------------------------------------------------+
struct SPartialTPLevel
  {
   bool              enabled;          // Nível ativo?
   double            priceLevel;       // Preço do TP
   double            lotSize;          // Lote a fechar neste nível
   double            percentLot;       // % do lote original
   string            description;      // "TP1: 50% @ 125450.00"
  };

//+------------------------------------------------------------------+
//| Estrutura: Resultado de Validação de SL/TP (v3.01)               |
//+------------------------------------------------------------------+
struct SValidateSLTPResult
  {
   bool              is_valid;         // SL/TP são válidos?
   double            validated_sl;     // SL validado
   double            validated_tp;     // TP validado
   bool              sl_adjusted;      // SL foi ajustado?
   bool              tp_adjusted;      // TP foi ajustado?
   string            message;          // Mensagem (para log)
  };

//+------------------------------------------------------------------+
//| Classe: CRiskManager - APENAS CÁLCULOS                           |
//+------------------------------------------------------------------+
class CRiskManager
  {
private:
   // ═══════════════════════════════════════════════════════════════
   // LOGGER
   // ═══════════════════════════════════════════════════════════════
   CLogger*          m_logger;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - LOTE (valor original)
   // ═══════════════════════════════════════════════════════════════
   double            m_inputLotSize;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - LOTE (valor usado)
   // ═══════════════════════════════════════════════════════════════
   double            m_lotSize;
   
   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - STOP LOSS (valores originais)
   // ═══════════════════════════════════════════════════════════════
   ENUM_SL_TYPE      m_inputSLType;
   int               m_inputFixedSL;
   double            m_inputSLATRMultiplier;
   int               m_inputRangePeriod;
   double            m_inputRangeMultiplier;
   bool              m_inputSLCompensateSpread;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - STOP LOSS (valores usados)
   // ═══════════════════════════════════════════════════════════════
   ENUM_SL_TYPE      m_slType;
   int               m_fixedSL;
   double            m_slATRMultiplier;
   int               m_rangePeriod;
   double            m_rangeMultiplier;
   bool              m_slCompensateSpread;
   
   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - TAKE PROFIT (valores originais)
   // ═══════════════════════════════════════════════════════════════
   ENUM_TP_TYPE      m_inputTPType;
   int               m_inputFixedTP;
   double            m_inputTPATRMultiplier;
   bool              m_inputTPCompensateSpread;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - TAKE PROFIT (valores usados)
   // ═══════════════════════════════════════════════════════════════
   ENUM_TP_TYPE      m_tpType;
   int               m_fixedTP;
   double            m_tpATRMultiplier;
   bool              m_tpCompensateSpread;
   
   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - TRAILING STOP (valores originais)
   // ═══════════════════════════════════════════════════════════════
   ENUM_TRAILING_TYPE m_inputTrailingType;
   int               m_inputTrailingStart;
   int               m_inputTrailingStep;
   double            m_inputTrailingATRStart;
   double            m_inputTrailingATRStep;
   bool              m_inputTrailingCompensateSpread;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - TRAILING STOP (valores usados)
   // ═══════════════════════════════════════════════════════════════
   ENUM_TRAILING_TYPE m_trailingType;
   int               m_trailingStart;
   int               m_trailingStep;
   double            m_trailingATRStart;
   double            m_trailingATRStep;
   bool              m_trailingCompensateSpread;
   
   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - BREAKEVEN (valores originais)
   // ═══════════════════════════════════════════════════════════════
   ENUM_BE_TYPE      m_inputBreakevenType;
   int               m_inputBEActivation;
   int               m_inputBEOffset;
   double            m_inputBEATRActivation;
   double            m_inputBEATROffset;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - BREAKEVEN (valores usados)
   // ═══════════════════════════════════════════════════════════════
   ENUM_BE_TYPE      m_breakevenType;
   int               m_beActivation;
   int               m_beOffset;
   double            m_beATRActivation;
   double            m_beATROffset;
   
   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - PARTIAL TP (v3.0) (valores originais)
   // ═══════════════════════════════════════════════════════════════
   bool              m_inputUsePartialTP;
   
   bool              m_inputTP1_enable;
   double            m_inputTP1_percent;
   ENUM_TP_TYPE      m_inputTP1_type;
   int               m_inputTP1_distance;
   double            m_inputTP1_atrMult;
   
   bool              m_inputTP2_enable;
   double            m_inputTP2_percent;
   ENUM_TP_TYPE      m_inputTP2_type;
   int               m_inputTP2_distance;
   double            m_inputTP2_atrMult;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - PARTIAL TP (v3.0) (valores usados)
   // ═══════════════════════════════════════════════════════════════
   bool              m_usePartialTP;
   
   bool              m_tp1_enable;
   double            m_tp1_percent;
   ENUM_TP_TYPE      m_tp1_type;
   int               m_tp1_distance;
   double            m_tp1_atrMult;
   
   bool              m_tp2_enable;
   double            m_tp2_percent;
   ENUM_TP_TYPE      m_tp2_type;
   int               m_tp2_distance;
   double            m_tp2_atrMult;
   
   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - ATIVAÇÃO CONDICIONAL (v3.0) (valores originais)
   // ═══════════════════════════════════════════════════════════════
   ENUM_TRAILING_ACTIVATION m_inputTrailingActivation;
   ENUM_BE_ACTIVATION       m_inputBEActivation_mode;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - ATIVAÇÃO CONDICIONAL (v3.0) (valores usados)
   // ═══════════════════════════════════════════════════════════════
   ENUM_TRAILING_ACTIVATION m_trailingActivation;
   ENUM_BE_ACTIVATION       m_beActivation_mode;
   
   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - GLOBAL (valores originais - não mudam em runtime)
   // ═══════════════════════════════════════════════════════════════
   string            m_inputSymbol;
   int               m_inputATRPeriod;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - GLOBAL (valores usados)
   // ═══════════════════════════════════════════════════════════════
   string            m_symbol;
   int               m_atrPeriod;
   
   // ═══════════════════════════════════════════════════════════════
   // HANDLES DE INDICADORES (não duplica - é interno)
   // ═══════════════════════════════════════════════════════════════
   int               m_handleATR;
   
   // ═══════════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS - HELPERS
   // ═══════════════════════════════════════════════════════════════
   double            CalculateAverageRange();
   double            GetATRValue(int index = 0);
   double            NormalizePrice(double price);
   double            NormalizeStep(double step);
   int               GetStopLevel();

public:
   // ═══════════════════════════════════════════════════════════════
   // CONSTRUTOR E INICIALIZAÇÃO
   // ═══════════════════════════════════════════════════════════════
                     CRiskManager();
                    ~CRiskManager();
   
   bool              Init(
      CLogger* logger,
      // Lote
      double lotSize,
      // Stop Loss
      ENUM_SL_TYPE slType, int fixedSL, double slATRMult, 
      int rangePeriod, double rangeMult, bool slCompensateSpread,
      // Take Profit
      ENUM_TP_TYPE tpType, int fixedTP, double tpATRMult, bool tpCompensateSpread,
      // Trailing (v3.02: REMOVIDO useTrailing - usar modo NEVER para desligar)
      ENUM_TRAILING_TYPE trailingType,
      int trailingStart, int trailingStep,
      double trailingATRStart, double trailingATRStep, bool trailingCompensateSpread,
      // Breakeven (v3.02: REMOVIDO useBreakeven - usar modo NEVER para desligar)
      ENUM_BE_TYPE beType,
      int beActivation, int beOffset,
      double beATRActivation, double beATROffset,
      // Partial TP (v3.0)
      bool usePartialTP,
      bool tp1Enable, double tp1Percent, ENUM_TP_TYPE tp1Type, int tp1Distance, double tp1ATRMult,
      bool tp2Enable, double tp2Percent, ENUM_TP_TYPE tp2Type, int tp2Distance, double tp2ATRMult,
      // Ativação Condicional (v3.0)
      ENUM_TRAILING_ACTIVATION trailingActivation,
      ENUM_BE_ACTIVATION beActivationMode,
      // Global
      string symbol, int atrPeriod
   );
   
   // ═══════════════════════════════════════════════════════════════
   // CÁLCULO DE LOTE
   // ═══════════════════════════════════════════════════════════════
   double            GetLotSize() const { return m_lotSize; }
   
   // ═══════════════════════════════════════════════════════════════
   // CÁLCULO DE STOP LOSS E TAKE PROFIT
   // ═══════════════════════════════════════════════════════════════
   double            CalculateSLPrice(ENUM_ORDER_TYPE orderType, double entryPrice);
   double            CalculateTPPrice(ENUM_ORDER_TYPE orderType, double entryPrice);
   
   // ═══════════════════════════════════════════════════════════════
   // VALIDAÇÃO DE SL/TP CONTRA NÍVEIS MÍNIMOS DO BROKER (v3.01)
   // ═══════════════════════════════════════════════════════════════
   SValidateSLTPResult ValidateSLTP(
      ENUM_POSITION_TYPE posType,
      double entryPrice,
      double proposedSL,
      double proposedTP
   );
   
   // ═══════════════════════════════════════════════════════════════
   // CÁLCULO DE TRAILING STOP
   // ═══════════════════════════════════════════════════════════════
   STrailingResult   CalculateTrailing(
      ENUM_POSITION_TYPE posType,
      double currentPrice,
      double entryPrice,
      double currentSL
   );
   
   // ═══════════════════════════════════════════════════════════════
   // CÁLCULO DE BREAKEVEN
   // ═══════════════════════════════════════════════════════════════
   SBreakevenResult  CalculateBreakeven(
      ENUM_POSITION_TYPE posType,
      double currentPrice,
      double entryPrice,
      double currentSL,
      bool alreadyActivated
   );
   
   // ═══════════════════════════════════════════════════════════════
   // CÁLCULO DE PARTIAL TAKE PROFIT (v3.0)
   // ═══════════════════════════════════════════════════════════════
   bool              CalculatePartialTPLevels(
      ENUM_ORDER_TYPE orderType,
      double entryPrice,
      double totalLotSize,
      SPartialTPLevel &levels[]
   );
   
   // ═══════════════════════════════════════════════════════════════
   // ATIVAÇÃO CONDICIONAL (v3.0)
   // ═══════════════════════════════════════════════════════════════
   bool              ShouldActivateTrailing(bool tp1Executed, bool tp2Executed);
   bool              ShouldActivateBreakeven(bool tp1Executed, bool tp2Executed);
   
   // ═══════════════════════════════════════════════════════════════
   // HOT RELOAD - Alterações em Runtime (v3.01)
   // ═══════════════════════════════════════════════════════════════
   void              SetLotSize(double newLotSize);
   void              SetFixedSL(int newSL);
   void              SetFixedTP(int newTP);
   void              SetSLATRMultiplier(double newMult);
   void              SetTPATRMultiplier(double newMult);
   void              SetTrailingParams(int start, int step);
   void              SetTrailingATRParams(double start, double step);
   void              SetBreakevenParams(int activation, int offset);
   void              SetBreakevenATRParams(double activation, double offset);
   void              SetPartialTP1(bool enable, double percent, int distance);
   void              SetPartialTP2(bool enable, double percent, int distance);
   void              SetUsePartialTP(bool enable);
   
   // ═══════════════════════════════════════════════════════════════
   // GETTERS DE CONFIGURAÇÃO (Working values)
   // ═══════════════════════════════════════════════════════════════
   bool              IsPartialTPEnabled() const { return m_usePartialTP; }
   int               GetFixedSL() const { return m_fixedSL; }
   int               GetFixedTP() const { return m_fixedTP; }

   // ═══════════════════════════════════════════════════════════════
   // GETTERS DE CONFIGURAÇÃO (Input values - valores originais)
   // ═══════════════════════════════════════════════════════════════
   double            GetInputLotSize() const { return m_inputLotSize; }
   int               GetInputFixedSL() const { return m_inputFixedSL; }
   int               GetInputFixedTP() const { return m_inputFixedTP; }
   
   // ═══════════════════════════════════════════════════════════════
   // DEBUG
   // ═══════════════════════════════════════════════════════════════
   void              PrintConfiguration();
  };

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager()
  {
   m_logger = NULL;
   
   // ═══ INPUT PARAMETERS (valores padrão) ═══
   m_inputLotSize = 1.0;
   
   m_inputSLType = SL_FIXED;
   m_inputFixedSL = 100;
   m_inputSLATRMultiplier = 3.0;
   m_inputRangePeriod = 20;
   m_inputRangeMultiplier = 1.5;
   m_inputSLCompensateSpread = false;
   
   m_inputTPType = TP_FIXED;
   m_inputFixedTP = 200;
   m_inputTPATRMultiplier = 5.0;
   m_inputTPCompensateSpread = false;
   
   m_inputTrailingType = TRAILING_FIXED;
   m_inputTrailingStart = 50;
   m_inputTrailingStep = 30;
   m_inputTrailingATRStart = 0.5;
   m_inputTrailingATRStep = 1.0;
   m_inputTrailingCompensateSpread = false;
   
   m_inputBreakevenType = BE_FIXED;
   m_inputBEActivation = 50;
   m_inputBEOffset = 5;
   m_inputBEATRActivation = 0.5;
   m_inputBEATROffset = 0.05;
   
   m_inputUsePartialTP = false;
   m_inputTP1_enable = true;
   m_inputTP1_percent = 50.0;
   m_inputTP1_type = TP_FIXED;
   m_inputTP1_distance = 100;
   m_inputTP1_atrMult = 1.0;
   
   m_inputTP2_enable = true;
   m_inputTP2_percent = 30.0;
   m_inputTP2_type = TP_FIXED;
   m_inputTP2_distance = 200;
   m_inputTP2_atrMult = 2.0;
   
   m_inputTrailingActivation = TRAILING_ALWAYS;
   m_inputBEActivation_mode = BE_ALWAYS;
   
   m_inputSymbol = _Symbol;
   m_inputATRPeriod = 14;
   
   // ═══ WORKING PARAMETERS (copiar dos inputs) ═══
   m_lotSize = 1.0;
   
   m_slType = SL_FIXED;
   m_fixedSL = 100;
   m_slATRMultiplier = 3.0;
   m_rangePeriod = 20;
   m_rangeMultiplier = 1.5;
   m_slCompensateSpread = false;
   
   m_tpType = TP_FIXED;
   m_fixedTP = 200;
   m_tpATRMultiplier = 5.0;
   m_tpCompensateSpread = false;
   
   m_trailingType = TRAILING_FIXED;
   m_trailingStart = 50;
   m_trailingStep = 30;
   m_trailingATRStart = 0.5;
   m_trailingATRStep = 1.0;
   m_trailingCompensateSpread = false;
   
   m_breakevenType = BE_FIXED;
   m_beActivation = 50;
   m_beOffset = 5;
   m_beATRActivation = 0.5;
   m_beATROffset = 0.05;
   
   m_usePartialTP = false;
   m_tp1_enable = true;
   m_tp1_percent = 50.0;
   m_tp1_type = TP_FIXED;
   m_tp1_distance = 100;
   m_tp1_atrMult = 1.0;
   
   m_tp2_enable = true;
   m_tp2_percent = 30.0;
   m_tp2_type = TP_FIXED;
   m_tp2_distance = 200;
   m_tp2_atrMult = 2.0;
   
   m_trailingActivation = TRAILING_ALWAYS;
   m_beActivation_mode = BE_ALWAYS;
   
   m_symbol = _Symbol;
   m_atrPeriod = 14;
   
   m_handleATR = INVALID_HANDLE;
  }

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager()
  {
   if(m_handleATR != INVALID_HANDLE)
     {
      IndicatorRelease(m_handleATR);
      m_handleATR = INVALID_HANDLE;
     }
  }

//+------------------------------------------------------------------+
//| Inicialização (v3.10 - Logging refatorado)                       |
//+------------------------------------------------------------------+
bool CRiskManager::Init(
   CLogger* logger,
   double lotSize,
   ENUM_SL_TYPE slType, int fixedSL, double slATRMult,
   int rangePeriod, double rangeMult, bool slCompensateSpread,
   ENUM_TP_TYPE tpType, int fixedTP, double tpATRMult, bool tpCompensateSpread,
   ENUM_TRAILING_TYPE trailingType,
   int trailingStart, int trailingStep,
   double trailingATRStart, double trailingATRStep, bool trailingCompensateSpread,
   ENUM_BE_TYPE beType,
   int beActivation, int beOffset,
   double beATRActivation, double beATROffset,
   bool usePartialTP,
   bool tp1Enable, double tp1Percent, ENUM_TP_TYPE tp1Type, int tp1Distance, double tp1ATRMult,
   bool tp2Enable, double tp2Percent, ENUM_TP_TYPE tp2Type, int tp2Distance, double tp2ATRMult,
   ENUM_TRAILING_ACTIVATION trailingActivation,
   ENUM_BE_ACTIVATION beActivationMode,
   string symbol, int atrPeriod
)
  {
   m_logger = logger;

   // ═══ SALVAR INPUT PARAMETERS (valores originais) ═══
   m_inputLotSize = lotSize;
   
   m_inputSLType = slType;
   m_inputFixedSL = fixedSL;
   m_inputSLATRMultiplier = slATRMult;
   m_inputRangePeriod = rangePeriod;
   m_inputRangeMultiplier = rangeMult;
   m_inputSLCompensateSpread = slCompensateSpread;
   
   m_inputTPType = tpType;
   m_inputFixedTP = fixedTP;
   m_inputTPATRMultiplier = tpATRMult;
   m_inputTPCompensateSpread = tpCompensateSpread;
   
   m_inputTrailingType = trailingType;
   m_inputTrailingStart = trailingStart;
   m_inputTrailingStep = trailingStep;
   m_inputTrailingATRStart = trailingATRStart;
   m_inputTrailingATRStep = trailingATRStep;
   m_inputTrailingCompensateSpread = trailingCompensateSpread;
   
   m_inputBreakevenType = beType;
   m_inputBEActivation = beActivation;
   m_inputBEOffset = beOffset;
   m_inputBEATRActivation = beATRActivation;
   m_inputBEATROffset = beATROffset;
   
   m_inputUsePartialTP = usePartialTP;
   m_inputTP1_enable = tp1Enable;
   m_inputTP1_percent = tp1Percent;
   m_inputTP1_type = tp1Type;
   m_inputTP1_distance = tp1Distance;
   m_inputTP1_atrMult = tp1ATRMult;
   
   m_inputTP2_enable = tp2Enable;
   m_inputTP2_percent = tp2Percent;
   m_inputTP2_type = tp2Type;
   m_inputTP2_distance = tp2Distance;
   m_inputTP2_atrMult = tp2ATRMult;
   
   m_inputTrailingActivation = trailingActivation;
   m_inputBEActivation_mode = beActivationMode;
   
   m_inputSymbol = symbol;
   m_inputATRPeriod = atrPeriod;

   // ═══ INICIALIZAR WORKING PARAMETERS (começam iguais aos inputs) ═══
   m_lotSize = lotSize;
   
   m_slType = slType;
   m_fixedSL = fixedSL;
   m_slATRMultiplier = slATRMult;
   m_rangePeriod = rangePeriod;
   m_rangeMultiplier = rangeMult;
   m_slCompensateSpread = slCompensateSpread;
   
   m_tpType = tpType;
   m_fixedTP = fixedTP;
   m_tpATRMultiplier = tpATRMult;
   m_tpCompensateSpread = tpCompensateSpread;
   
   m_trailingType = trailingType;
   m_trailingStart = trailingStart;
   m_trailingStep = trailingStep;
   m_trailingATRStart = trailingATRStart;
   m_trailingATRStep = trailingATRStep;
   m_trailingCompensateSpread = trailingCompensateSpread;
   
   m_breakevenType = beType;
   m_beActivation = beActivation;
   m_beOffset = beOffset;
   m_beATRActivation = beATRActivation;
   m_beATROffset = beATROffset;
   
   m_usePartialTP = usePartialTP;
   m_tp1_enable = tp1Enable;
   m_tp1_percent = tp1Percent;
   m_tp1_type = tp1Type;
   m_tp1_distance = tp1Distance;
   m_tp1_atrMult = tp1ATRMult;
   
   m_tp2_enable = tp2Enable;
   m_tp2_percent = tp2Percent;
   m_tp2_type = tp2Type;
   m_tp2_distance = tp2Distance;
   m_tp2_atrMult = tp2ATRMult;
   
   m_trailingActivation = trailingActivation;
   m_beActivation_mode = beActivationMode;
   
   m_symbol = symbol;
   m_atrPeriod = atrPeriod;
   
   // ═══════════════════════════════════════════════════════════════
   // VALIDAR PARTIAL TP
   // ═══════════════════════════════════════════════════════════════
   if(m_usePartialTP)
     {
      double totalPercent = 0;
      if(m_tp1_enable) totalPercent += m_tp1_percent;
      if(m_tp2_enable) totalPercent += m_tp2_percent;
      
      if(totalPercent >= 100.0)
        {
         if(m_logger != NULL)
           {
            m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Soma dos % de TP parcial >= 100%!");
            m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT",
               StringFormat("   TP1: %.1f%% + TP2: %.1f%% = %.1f%%", 
                           m_tp1_percent, m_tp2_percent, totalPercent));
           }
         else
           {
            Print("❌ Soma dos % de TP parcial >= 100%!");
            Print(StringFormat("   TP1: %.1f%% + TP2: %.1f%% = %.1f%%", 
                              m_tp1_percent, m_tp2_percent, totalPercent));
           }
         return false;
        }
      
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
            StringFormat("✅ Partial TP validado: %.1f%% fechado em parciais, %.1f%% para trailing",
                        totalPercent, 100.0 - totalPercent));
        }
      else
        {
         Print(StringFormat("✅ Partial TP validado: %.1f%% fechado em parciais, %.1f%% para trailing",
                           totalPercent, 100.0 - totalPercent));
        }
     }
   
   // ═══════════════════════════════════════════════════════════════
   // CRIAR HANDLE ATR SE NECESSÁRIO
   // ═══════════════════════════════════════════════════════════════
   if(m_slType == SL_ATR || m_tpType == TP_ATR || 
      m_trailingType == TRAILING_ATR || m_breakevenType == BE_ATR ||
      (m_usePartialTP && (m_tp1_type == TP_ATR || m_tp2_type == TP_ATR)))
     {
      m_handleATR = iATR(m_symbol, PERIOD_CURRENT, m_atrPeriod);
      
      if(m_handleATR == INVALID_HANDLE)
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Falha ao criar handle ATR");
         else
            Print("❌ Falha ao criar handle ATR");
         return false;
        }
     }
   
   return true;
  }

// ═══════════════════════════════════════════════════════════════
// HOT RELOAD - MÉTODOS SET (v3.10 - Logging refatorado)
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Hot Reload - Alterar tamanho do lote                             |
//+------------------------------------------------------------------+
void CRiskManager::SetLotSize(double newLotSize)
  {
   double oldValue = m_lotSize;
   m_lotSize = newLotSize;

   // Só logar se houve mudança real
   if(oldValue != newLotSize)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("🔄 Lote alterado: %.2f → %.2f", oldValue, newLotSize));
      else
         Print("🔄 Lote alterado: ", oldValue, " → ", newLotSize);
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar SL fixo                                     |
//+------------------------------------------------------------------+
void CRiskManager::SetFixedSL(int newSL)
  {
   int oldValue = m_fixedSL;
   m_fixedSL = newSL;

   // Só logar se houve mudança real
   if(oldValue != newSL)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("🔄 SL fixo alterado: %d → %d pts", oldValue, newSL));
      else
         Print("🔄 SL fixo alterado: ", oldValue, " → ", newSL, " pts");
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar TP fixo                                     |
//+------------------------------------------------------------------+
void CRiskManager::SetFixedTP(int newTP)
  {
   int oldValue = m_fixedTP;
   m_fixedTP = newTP;

   // Só logar se houve mudança real
   if(oldValue != newTP)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("🔄 TP fixo alterado: %d → %d pts", oldValue, newTP));
      else
         Print("🔄 TP fixo alterado: ", oldValue, " → ", newTP, " pts");
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar multiplicador ATR do SL                     |
//+------------------------------------------------------------------+
void CRiskManager::SetSLATRMultiplier(double newMult)
  {
   double oldValue = m_slATRMultiplier;
   m_slATRMultiplier = newMult;

   // Só logar se houve mudança real
   if(oldValue != newMult)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("🔄 SL ATR mult alterado: %.1f → %.1f×", oldValue, newMult));
      else
         Print("🔄 SL ATR mult alterado: ", oldValue, " → ", newMult, "×");
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar multiplicador ATR do TP                     |
//+------------------------------------------------------------------+
void CRiskManager::SetTPATRMultiplier(double newMult)
  {
   double oldValue = m_tpATRMultiplier;
   m_tpATRMultiplier = newMult;

   // Só logar se houve mudança real
   if(oldValue != newMult)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("🔄 TP ATR mult alterado: %.1f → %.1f×", oldValue, newMult));
      else
         Print("🔄 TP ATR mult alterado: ", oldValue, " → ", newMult, "×");
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar parâmetros de trailing fixo                 |
//+------------------------------------------------------------------+
void CRiskManager::SetTrailingParams(int start, int step)
  {
   int oldStart = m_trailingStart;
   int oldStep = m_trailingStep;
   m_trailingStart = start;
   m_trailingStep = step;

   // Só logar se houve mudança real
   if(oldStart != start || oldStep != step)
     {
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "🔄 Trailing fixo alterado:");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("   • Start: %d → %d pts", oldStart, start));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("   • Step: %d → %d pts", oldStep, step));
        }
      else
        {
         Print("🔄 Trailing fixo alterado:");
         Print("   • Start: ", oldStart, " → ", start, " pts");
         Print("   • Step: ", oldStep, " → ", step, " pts");
        }
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar parâmetros de trailing ATR                  |
//+------------------------------------------------------------------+
void CRiskManager::SetTrailingATRParams(double start, double step)
  {
   double oldStart = m_trailingATRStart;
   double oldStep = m_trailingATRStep;
   m_trailingATRStart = start;
   m_trailingATRStep = step;

   // Só logar se houve mudança real
   if(oldStart != start || oldStep != step)
     {
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "🔄 Trailing ATR alterado:");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("   • Start: %.1f → %.1f× ATR", oldStart, start));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("   • Step: %.1f → %.1f× ATR", oldStep, step));
        }
      else
        {
         Print("🔄 Trailing ATR alterado:");
         Print("   • Start: ", oldStart, " → ", start, "× ATR");
         Print("   • Step: ", oldStep, " → ", step, "× ATR");
        }
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar parâmetros de breakeven fixo                |
//+------------------------------------------------------------------+
void CRiskManager::SetBreakevenParams(int activation, int offset)
  {
   int oldActivation = m_beActivation;
   int oldOffset = m_beOffset;
   m_beActivation = activation;
   m_beOffset = offset;

   // Só logar se houve mudança real
   if(oldActivation != activation || oldOffset != offset)
     {
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "🔄 Breakeven fixo alterado:");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("   • Ativação: %d → %d pts", oldActivation, activation));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("   • Offset: %d → %d pts", oldOffset, offset));
        }
      else
        {
         Print("🔄 Breakeven fixo alterado:");
         Print("   • Ativação: ", oldActivation, " → ", activation, " pts");
         Print("   • Offset: ", oldOffset, " → ", offset, " pts");
        }
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar parâmetros de breakeven ATR                 |
//+------------------------------------------------------------------+
void CRiskManager::SetBreakevenATRParams(double activation, double offset)
  {
   double oldActivation = m_beATRActivation;
   double oldOffset = m_beATROffset;
   m_beATRActivation = activation;
   m_beATROffset = offset;

   // Só logar se houve mudança real
   if(oldActivation != activation || oldOffset != offset)
     {
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "🔄 Breakeven ATR alterado:");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("   • Ativação: %.2f → %.2f× ATR", oldActivation, activation));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("   • Offset: %.2f → %.2f× ATR", oldOffset, offset));
        }
      else
        {
         Print("🔄 Breakeven ATR alterado:");
         Print("   • Ativação: ", oldActivation, " → ", activation, "× ATR");
         Print("   • Offset: ", oldOffset, " → ", offset, "× ATR");
        }
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar TP1 parcial                                 |
//+------------------------------------------------------------------+
void CRiskManager::SetPartialTP1(bool enable, double percent, int distance)
  {
   bool oldEnable = m_tp1_enable;
   double oldPercent = m_tp1_percent;
   int oldDistance = m_tp1_distance;
   m_tp1_enable = enable;
   m_tp1_percent = percent;
   m_tp1_distance = distance;

   // Só logar se houve mudança real
   if(oldEnable != enable || oldPercent != percent || oldDistance != distance)
     {
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "🔄 TP1 parcial alterado:");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            "   • Ativo: " + (enable ? "SIM" : "NÃO"));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("   • Percentual: %.1f%%", percent));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("   • Distância: %d pts", distance));
        }
      else
        {
         Print("🔄 TP1 parcial alterado:");
         Print("   • Ativo: ", enable ? "SIM" : "NÃO");
         Print("   • Percentual: ", percent, "%");
         Print("   • Distância: ", distance, " pts");
        }
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar TP2 parcial                                 |
//+------------------------------------------------------------------+
void CRiskManager::SetPartialTP2(bool enable, double percent, int distance)
  {
   bool oldEnable = m_tp2_enable;
   double oldPercent = m_tp2_percent;
   int oldDistance = m_tp2_distance;
   m_tp2_enable = enable;
   m_tp2_percent = percent;
   m_tp2_distance = distance;

   // Só logar se houve mudança real
   if(oldEnable != enable || oldPercent != percent || oldDistance != distance)
     {
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "🔄 TP2 parcial alterado:");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            "   • Ativo: " + (enable ? "SIM" : "NÃO"));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("   • Percentual: %.1f%%", percent));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
            StringFormat("   • Distância: %d pts", distance));
        }
      else
        {
         Print("🔄 TP2 parcial alterado:");
         Print("   • Ativo: ", enable ? "SIM" : "NÃO");
         Print("   • Percentual: ", percent, "%");
         Print("   • Distância: ", distance, " pts");
        }
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload - Ativar/Desativar partial TP                         |
//+------------------------------------------------------------------+
void CRiskManager::SetUsePartialTP(bool enable)
  {
   bool oldValue = m_usePartialTP;
   m_usePartialTP = enable;
   
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "🔄 Partial TP: " + (enable ? "ATIVADO" : "DESATIVADO"));
   else
      Print("🔄 Partial TP: ", enable ? "ATIVADO" : "DESATIVADO");
  }

// ═══════════════════════════════════════════════════════════════
// MÉTODOS DE CÁLCULO - PERMANECEM IDÊNTICOS
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Calcular preço de Stop Loss                                      |
//+------------------------------------------------------------------+
double CRiskManager::CalculateSLPrice(ENUM_ORDER_TYPE orderType, double entryPrice)
  {
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD) * point;
   double slDistance = 0;
   
   switch(m_slType)
     {
      case SL_FIXED:
         slDistance = m_fixedSL * point;
         break;
         
      case SL_RANGE:
        {
         double avgRange = CalculateAverageRange();
         slDistance = avgRange * m_rangeMultiplier;
        }
         break;
         
      case SL_ATR:
        {
         double atr = GetATRValue();
         if(atr > 0)
            slDistance = atr * m_slATRMultiplier;
         else
            slDistance = m_fixedSL * point;
        }
         break;
     }
   
   if(m_slCompensateSpread)
      slDistance += spread;
   
   double slPrice = 0;
   if(orderType == ORDER_TYPE_BUY)
      slPrice = entryPrice - slDistance;
   else
      slPrice = entryPrice + slDistance;
   
   slPrice = NormalizePrice(slPrice);
   
   int stopLevel = GetStopLevel();
   double minDistance = stopLevel * point;
   
   if(orderType == ORDER_TYPE_BUY)
     {
      double minSL = entryPrice - minDistance;
      if(slPrice > minSL)
         slPrice = minSL;
     }
   else
     {
      double maxSL = entryPrice + minDistance;
      if(slPrice < maxSL)
         slPrice = maxSL;
     }
   
   return slPrice;
  }

//+------------------------------------------------------------------+
//| Calcular preço de Take Profit (v3.11 - TP FALLBACK)             |
//+------------------------------------------------------------------+
double CRiskManager::CalculateTPPrice(ENUM_ORDER_TYPE orderType, double entryPrice)
  {
   // ═══════════════════════════════════════════════════════════════
   // 🆕 v3.11: PARTIAL TP ATIVO → USA TP FIXO COMO FALLBACK
   // ═══════════════════════════════════════════════════════════════
   if(m_usePartialTP)
     {
      double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      double tpDistance = m_fixedTP * point;
      
      double tpPrice = 0;
      if(orderType == ORDER_TYPE_BUY)
         tpPrice = entryPrice + tpDistance;
      else
         tpPrice = entryPrice - tpDistance;
      
      // Normalizar
      tpPrice = NormalizePrice(tpPrice);
      
      // Log informativo
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "CONFIG",
            "🎯 Partial TP ativo - TP Fixo como fallback: " + 
            DoubleToString(tpDistance/point, 1) + " pts");
      
      return tpPrice;  // ← RETORNA AQUI!
     }
   
   // ═══════════════════════════════════════════════════════════════
   // SEM PARTIAL TP: LÓGICA NORMAL (código existente)
   // ═══════════════════════════════════════════════════════════════
   if(m_tpType == TP_NONE)
      return 0;
   
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD) * point;
   double tpDistance = 0;
   
   switch(m_tpType)
     {
      case TP_FIXED:
         tpDistance = m_fixedTP * point;
         break;
         
      case TP_ATR:
        {
         double atr = GetATRValue();
         if(atr > 0)
            tpDistance = atr * m_tpATRMultiplier;
         else
            tpDistance = m_fixedTP * point;
        }
         break;
         
      case TP_NONE:
         return 0;
     }
   
   if(m_tpCompensateSpread)
      tpDistance -= spread;
   
   double tpPrice = 0;
   if(orderType == ORDER_TYPE_BUY)
      tpPrice = entryPrice + tpDistance;
   else
      tpPrice = entryPrice - tpDistance;
   
   tpPrice = NormalizePrice(tpPrice);
   
   return tpPrice;
  }

//+------------------------------------------------------------------+
//| Validar SL/TP contra níveis mínimos do broker (v3.10)            |
//+------------------------------------------------------------------+
SValidateSLTPResult CRiskManager::ValidateSLTP(
   ENUM_POSITION_TYPE posType,
   double entryPrice,
   double proposedSL,
   double proposedTP
)
  {
   SValidateSLTPResult result;
   result.is_valid = true;
   result.validated_sl = proposedSL;
   result.validated_tp = proposedTP;
   result.sl_adjusted = false;
   result.tp_adjusted = false;
   result.message = "";
   
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int stopLevel = GetStopLevel();
   double minDistance = stopLevel * point;
   
   // ═══════════════════════════════════════════════════════════════
   // VALIDAR STOP LOSS
   // ═══════════════════════════════════════════════════════════════
   if(proposedSL > 0)
     {
      double slDistance = 0;
      
      if(posType == POSITION_TYPE_BUY)
        {
         slDistance = entryPrice - proposedSL;
         
         if(slDistance < minDistance)
           {
            result.validated_sl = entryPrice - minDistance;
            result.validated_sl = NormalizePrice(result.validated_sl);
            result.sl_adjusted = true;
            
            if(m_logger != NULL)
              {
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  "⚠️ SL ajustado para respeitar stop level mínimo");
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  StringFormat("   Stop Level: %d pts (%.5f)", stopLevel, minDistance));
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  StringFormat("   SL proposto: %.5f (%.5f pts)", proposedSL, slDistance));
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  StringFormat("   SL validado: %.5f (%.5f pts)", result.validated_sl, minDistance));
              }
            else
              {
               Print("⚠️ SL ajustado para respeitar stop level mínimo");
               Print("   SL proposto: ", proposedSL, " → SL validado: ", result.validated_sl);
              }
           }
        }
      else
        {
         slDistance = proposedSL - entryPrice;
         
         if(slDistance < minDistance)
           {
            result.validated_sl = entryPrice + minDistance;
            result.validated_sl = NormalizePrice(result.validated_sl);
            result.sl_adjusted = true;
            
            if(m_logger != NULL)
              {
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  "⚠️ SL ajustado para respeitar stop level mínimo");
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  StringFormat("   Stop Level: %d pts (%.5f)", stopLevel, minDistance));
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  StringFormat("   SL proposto: %.5f (%.5f pts)", proposedSL, slDistance));
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  StringFormat("   SL validado: %.5f (%.5f pts)", result.validated_sl, minDistance));
              }
            else
              {
               Print("⚠️ SL ajustado para respeitar stop level mínimo");
               Print("   SL proposto: ", proposedSL, " → SL validado: ", result.validated_sl);
              }
           }
        }
     }
   
   // ═══════════════════════════════════════════════════════════════
   // VALIDAR TAKE PROFIT
   // ═══════════════════════════════════════════════════════════════
   if(proposedTP > 0)
     {
      double tpDistance = 0;
      
      if(posType == POSITION_TYPE_BUY)
        {
         tpDistance = proposedTP - entryPrice;
         
         if(tpDistance < minDistance)
           {
            result.validated_tp = entryPrice + minDistance;
            result.validated_tp = NormalizePrice(result.validated_tp);
            result.tp_adjusted = true;
            
            if(m_logger != NULL)
              {
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  "⚠️ TP ajustado para respeitar stop level mínimo");
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  StringFormat("   Stop Level: %d pts (%.5f)", stopLevel, minDistance));
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  StringFormat("   TP proposto: %.5f (%.5f pts)", proposedTP, tpDistance));
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  StringFormat("   TP validado: %.5f (%.5f pts)", result.validated_tp, minDistance));
              }
            else
              {
               Print("⚠️ TP ajustado para respeitar stop level mínimo");
               Print("   TP proposto: ", proposedTP, " → TP validado: ", result.validated_tp);
              }
           }
        }
      else
        {
         tpDistance = entryPrice - proposedTP;
         
         if(tpDistance < minDistance)
           {
            result.validated_tp = entryPrice - minDistance;
            result.validated_tp = NormalizePrice(result.validated_tp);
            result.tp_adjusted = true;
            
            if(m_logger != NULL)
              {
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  "⚠️ TP ajustado para respeitar stop level mínimo");
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  StringFormat("   Stop Level: %d pts (%.5f)", stopLevel, minDistance));
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  StringFormat("   TP proposto: %.5f (%.5f pts)", proposedTP, tpDistance));
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "VALIDATION",
                  StringFormat("   TP validado: %.5f (%.5f pts)", result.validated_tp, minDistance));
              }
            else
              {
               Print("⚠️ TP ajustado para respeitar stop level mínimo");
               Print("   TP proposto: ", proposedTP, " → TP validado: ", result.validated_tp);
              }
           }
        }
     }
   
   if(result.sl_adjusted || result.tp_adjusted)
     {
      result.message = "SL/TP ajustados para respeitar stop level do broker";
      result.is_valid = true;
     }
   else
     {
      result.message = "SL/TP dentro dos níveis mínimos do broker";
      result.is_valid = true;
     }
   
   return result;
  }

//+------------------------------------------------------------------+
//| Calcular Trailing Stop                                           |
//+------------------------------------------------------------------+
STrailingResult CRiskManager::CalculateTrailing(
   ENUM_POSITION_TYPE posType,
   double currentPrice,
   double entryPrice,
   double currentSL
)
  {
   STrailingResult result;
   result.should_move = false;
   result.new_sl_price = currentSL;
   result.reason = "";
   
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD) * point;
   
   double profitDistance = 0;
   if(posType == POSITION_TYPE_BUY)
      profitDistance = currentPrice - entryPrice;
   else
      profitDistance = entryPrice - currentPrice;
   
   double activationDistance = 0;
   double stepDistance = 0;
   
   if(m_trailingType == TRAILING_FIXED)
     {
      activationDistance = m_trailingStart * point;
      stepDistance = m_trailingStep * point;
     }
   else if(m_trailingType == TRAILING_ATR)
     {
      double atr = GetATRValue();
      if(atr > 0)
        {
         activationDistance = atr * m_trailingATRStart;
         stepDistance = atr * m_trailingATRStep;
        }
      else
        {
         result.reason = "ATR indisponível";
         return result;
        }
     }
   
   if(profitDistance < activationDistance)
     {
      result.reason = "Lucro insuficiente para ativar trailing";
      return result;
     }
   
   double newSL = 0;
   
   if(posType == POSITION_TYPE_BUY)
     {
      newSL = currentPrice - stepDistance;
      
      if(m_trailingCompensateSpread)
         newSL -= spread;
      
      if(newSL <= currentSL)
        {
         result.reason = "Novo SL não melhora o atual";
         return result;
        }
     }
   else
     {
      newSL = currentPrice + stepDistance;
      
      if(m_trailingCompensateSpread)
         newSL += spread;
      
      if(newSL >= currentSL)
        {
         result.reason = "Novo SL não melhora o atual";
         return result;
        }
     }
   
   newSL = NormalizePrice(newSL);
   
   int stopLevel = GetStopLevel();
   double minDistance = stopLevel * point;
   
   if(posType == POSITION_TYPE_BUY)
     {
      double minSL = currentPrice - minDistance;
      if(newSL > minSL)
        {
         result.reason = "Violaria stop level mínimo";
         return result;
        }
     }
   else
     {
      double maxSL = currentPrice + minDistance;
      if(newSL < maxSL)
        {
         result.reason = "Violaria stop level mínimo";
         return result;
        }
     }
   
   double movement = MathAbs(newSL - currentSL);
   if(movement < 0.00001)
     {
      result.reason = "Movimento insignificante";
      return result;
     }
   
   result.should_move = true;
   result.new_sl_price = newSL;
   result.reason = "Trailing ativado - SL movido";
   
   return result;
  }

//+------------------------------------------------------------------+
//| Calcular Breakeven                                               |
//+------------------------------------------------------------------+
SBreakevenResult CRiskManager::CalculateBreakeven(
   ENUM_POSITION_TYPE posType,
   double currentPrice,
   double entryPrice,
   double currentSL,
   bool alreadyActivated
)
  {
   SBreakevenResult result;
   result.should_activate = false;
   result.new_sl_price = currentSL;
   result.reason = "";
   
   if(alreadyActivated)
     {
      result.reason = "Breakeven já ativado anteriormente";
      return result;
     }
   
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   
   double profitDistance = 0;
   if(posType == POSITION_TYPE_BUY)
      profitDistance = currentPrice - entryPrice;
   else
      profitDistance = entryPrice - currentPrice;
   
   double activationDistance = 0;
   double offsetDistance = 0;
   
   if(m_breakevenType == BE_FIXED)
     {
      activationDistance = m_beActivation * point;
      offsetDistance = m_beOffset * point;
     }
   else if(m_breakevenType == BE_ATR)
     {
      double atr = GetATRValue();
      if(atr > 0)
        {
         activationDistance = atr * m_beATRActivation;
         offsetDistance = atr * m_beATROffset;
        }
      else
        {
         result.reason = "ATR indisponível";
         return result;
        }
     }
   
   if(profitDistance < activationDistance)
     {
      result.reason = "Lucro insuficiente para ativar breakeven";
      return result;
     }
   
   double newSL = 0;
   
   if(posType == POSITION_TYPE_BUY)
      newSL = entryPrice + offsetDistance;
   else
      newSL = entryPrice - offsetDistance;
   
   newSL = NormalizePrice(newSL);
   
   if(posType == POSITION_TYPE_BUY && newSL <= currentSL)
     {
      result.reason = "Breakeven não melhora SL atual";
      return result;
     }
   
   if(posType == POSITION_TYPE_SELL && newSL >= currentSL)
     {
      result.reason = "Breakeven não melhora SL atual";
      return result;
     }
   
   result.should_activate = true;
   result.new_sl_price = newSL;
   result.reason = "Breakeven ativado";
   
   return result;
  }

//+------------------------------------------------------------------+
//| Calcular média do Range (High - Low)                             |
//+------------------------------------------------------------------+
double CRiskManager::CalculateAverageRange()
  {
   double totalRange = 0;
   int validBars = 0;
   
   for(int i = 1; i <= m_rangePeriod; i++)
     {
      double high = iHigh(m_symbol, PERIOD_CURRENT, i);
      double low = iLow(m_symbol, PERIOD_CURRENT, i);
      
      if(high > 0 && low > 0)
        {
         totalRange += (high - low);
         validBars++;
        }
     }
   
   if(validBars > 0)
      return totalRange / validBars;
   
   return 0;
  }

//+------------------------------------------------------------------+
//| Obter valor do ATR                                               |
//+------------------------------------------------------------------+
double CRiskManager::GetATRValue(int index = 0)
  {
   if(m_handleATR == INVALID_HANDLE)
      return 0;
   
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   
   if(CopyBuffer(m_handleATR, 0, index, 1, atrBuffer) <= 0)
      return 0;
   
   return atrBuffer[0];
  }

//+------------------------------------------------------------------+
//| Normalizar preço para tick size válido                           |
//+------------------------------------------------------------------+
double CRiskManager::NormalizePrice(double price)
  {
   double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize == 0)
      return price;
   
   return MathRound(price / tickSize) * tickSize;
  }

//+------------------------------------------------------------------+
//| Normalizar distância para tick size válido                       |
//+------------------------------------------------------------------+
double CRiskManager::NormalizeStep(double step)
  {
   double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize == 0)
      return step;
   
   return MathCeil(step / tickSize) * tickSize;
  }

//+------------------------------------------------------------------+
//| Obter Stop Level do broker                                       |
//+------------------------------------------------------------------+
int CRiskManager::GetStopLevel()
  {
   int stopLevel = (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
   
   if(stopLevel == 0)
      stopLevel = 1;
   
   return stopLevel;
  }

//+------------------------------------------------------------------+
//| Calcular níveis de Take Profit Parcial                           |
//+------------------------------------------------------------------+
bool CRiskManager::CalculatePartialTPLevels(
   ENUM_ORDER_TYPE orderType,
   double entryPrice,
   double totalLotSize,
   SPartialTPLevel &levels[]
)
  {
   if(!m_usePartialTP)
      return false;
   
   ArrayResize(levels, 0);
   
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   double spread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD) * point;
   int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   
   double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
   
   if(m_tp1_enable && m_tp1_percent > 0)
     {
      SPartialTPLevel tp1;
      tp1.enabled = true;
      tp1.percentLot = m_tp1_percent;
      tp1.lotSize = MathFloor((totalLotSize * m_tp1_percent / 100.0) / lotStep) * lotStep;
      
      if(tp1.lotSize < minLot)
         tp1.lotSize = minLot;
      if(tp1.lotSize > totalLotSize)
         tp1.lotSize = totalLotSize;
      
      double distance = 0;
      if(m_tp1_type == TP_FIXED)
        {
         distance = m_tp1_distance * point;
        }
      else if(m_tp1_type == TP_ATR)
        {
         double atr = GetATRValue();
         if(atr > 0)
            distance = atr * m_tp1_atrMult;
         else
            distance = m_tp1_distance * point;
        }
      
      if(m_tpCompensateSpread)
         distance -= spread;
      
      if(orderType == ORDER_TYPE_BUY)
         tp1.priceLevel = entryPrice + distance;
      else
         tp1.priceLevel = entryPrice - distance;
      
      tp1.priceLevel = NormalizePrice(tp1.priceLevel);
      tp1.description = StringFormat("TP1: %.1f%% @ %s", m_tp1_percent, DoubleToString(tp1.priceLevel, digits));
      
      ArrayResize(levels, ArraySize(levels) + 1);
      levels[ArraySize(levels) - 1] = tp1;
     }
   
   if(m_tp2_enable && m_tp2_percent > 0)
     {
      SPartialTPLevel tp2;
      tp2.enabled = true;
      tp2.percentLot = m_tp2_percent;
      tp2.lotSize = MathFloor((totalLotSize * m_tp2_percent / 100.0) / lotStep) * lotStep;
      
      if(tp2.lotSize < minLot)
         tp2.lotSize = minLot;
      if(tp2.lotSize > totalLotSize)
         tp2.lotSize = totalLotSize;
      
      double distance = 0;
      if(m_tp2_type == TP_FIXED)
        {
         distance = m_tp2_distance * point;
        }
      else if(m_tp2_type == TP_ATR)
        {
         double atr = GetATRValue();
         if(atr > 0)
            distance = atr * m_tp2_atrMult;
         else
            distance = m_tp2_distance * point;
        }
      
      if(m_tpCompensateSpread)
         distance -= spread;
      
      if(orderType == ORDER_TYPE_BUY)
         tp2.priceLevel = entryPrice + distance;
      else
         tp2.priceLevel = entryPrice - distance;
      
      tp2.priceLevel = NormalizePrice(tp2.priceLevel);
      tp2.description = StringFormat("TP2: %.1f%% @ %s", m_tp2_percent, DoubleToString(tp2.priceLevel, digits));
      
      ArrayResize(levels, ArraySize(levels) + 1);
      levels[ArraySize(levels) - 1] = tp2;
     }
   
   return ArraySize(levels) > 0;
  }

//+------------------------------------------------------------------+
//| Verifica se deve ativar Trailing Stop (v3.10)                    |
//+------------------------------------------------------------------+
bool CRiskManager::ShouldActivateTrailing(bool tp1Executed, bool tp2Executed)
  {
   switch(m_trailingActivation)
     {
      case TRAILING_ALWAYS:
         return true;
         
      case TRAILING_AFTER_TP1:
         return tp1Executed;
         
      case TRAILING_AFTER_TP2:
         return (tp1Executed && tp2Executed);
         
      case TRAILING_NEVER:
         return false;
         
      default:
         return false;
     }
  }

//+------------------------------------------------------------------+
//| Verifica se deve ativar Breakeven (v3.10)                        |
//+------------------------------------------------------------------+
bool CRiskManager::ShouldActivateBreakeven(bool tp1Executed, bool tp2Executed)
  {
   switch(m_beActivation_mode)
     {
      case BE_ALWAYS:
         return true;
         
      case BE_AFTER_TP1:
         return tp1Executed;
         
      case BE_AFTER_TP2:
         return (tp1Executed && tp2Executed);
         
      case BE_NEVER:
         return false;
         
      default:
         return false;
     }
  }

//+------------------------------------------------------------------+
//| Imprimir configuração completa (v3.10)                           |
//+------------------------------------------------------------------+
void CRiskManager::PrintConfiguration()
  {
   if(m_logger != NULL)
     {
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "╔══════════════════════════════════════════════════════╗");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "║       RISKMANAGER v3.11 - CONFIGURAÇÃO ATUAL        ║");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "╚══════════════════════════════════════════════════════╝");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "");
      
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "💰 LOTE:");
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", 
         "   Tamanho: " + DoubleToString(m_lotSize, 2));
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "");
      
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "🛑 STOP LOSS:");
      switch(m_slType)
        {
         case SL_FIXED:
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "   Tipo: FIXO");
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", 
               "   Distância: " + IntegerToString(m_fixedSL) + " pts");
            break;
         case SL_RANGE:
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "   Tipo: DINÂMICO RANGE");
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", 
               "   Período: " + IntegerToString(m_rangePeriod) + " barras");
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", 
               "   Multiplicador: " + DoubleToString(m_rangeMultiplier, 1) + "×");
            break;
         case SL_ATR:
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "   Tipo: DINÂMICO ATR");
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", 
               "   Multiplicador: " + DoubleToString(m_slATRMultiplier, 1) + "×");
            break;
        }
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", 
         "   Compensar Spread: " + (m_slCompensateSpread ? "SIM" : "NÃO"));
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "");
      
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CONFIG", "═══════════════════════════════════════════════════════");
     }
   else
     {
      Print("╔══════════════════════════════════════════════════════╗");
      Print("║       RISKMANAGER v3.11 - CONFIGURAÇÃO ATUAL        ║");
      Print("╚══════════════════════════════════════════════════════╝");
      Print("");
      
      Print("💰 LOTE:");
      Print("   Tamanho: ", m_lotSize);
      Print("");
      
      Print("═══════════════════════════════════════════════════════");
     }
  }
//+------------------------------------------------------------------+
