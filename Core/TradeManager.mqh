//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                                         Copyright 2026, EP Filho |
//|             Gerenciamento de Posições Individuais - EPBot Matrix |
//|                     Versão 1.26 - Claude Parte 032 (Claude Code) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "1.26"

// CHANGELOG v1.26 (Parte 032):
// * H-04: ExecutePartialClose — validação lot >= minLot APÓS MathFloor rounding
// * H-04: ExecutePartialClose — fallback lotStep <= 0 (previne divisão por zero)
// * H-05: SetMagicNumber — DeleteState() agora chamado ANTES de atualizar m_magicNumber
//         (antes deletava state file do magic novo em vez do antigo)
// * H-06: ResyncExistingPositions — guard ticket==0 em PositionGetTicket
//
// CHANGELOG v1.25 (Parte 028):
// * SetSlippage(): só loga/aplica quando valor realmente muda
//
// CHANGELOG v1.24 (Parte 027):
// + SaveState() / LoadState() / DeleteState() — persistência do estado
//   das posições (BE, Trailing, TP1/TP2 executed) em arquivo .state
// + Arquivo: MQL5/Files/Matrix_{symbol}_{magic}.state
// + Auto-save em: RegisterPosition, UnregisterPosition, Set*() mutators
// + Auto-load em: ResyncExistingPositions (restaura flags após restart)
// + Guard de backtest (MQL_TESTER) — não grava em otimização
//
// CHANGELOG v1.23 (Parte 027):
// + SetMagicNumber() / GetMagicNumber() — hot reload do Magic Number

// ═══════════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════════
#include "Logger.mqh"
#include "RiskManager.mqh"

// ═══════════════════════════════════════════════════════════════════
// ARQUITETURA TRADEMANAGER v1.22:
// - Rastreia CADA posição individualmente com seu próprio estado
// - Gerencia Breakeven por posição (não global)
// - Gerencia Trailing por posição (não global)
// - Gerencia Partial TP por posição (TP1, TP2)
// - Hot Reload completo (Input + Working variables)
// - Integração total com Logger e RiskManager
// - ReSync
//
// NOVIDADES v1.22:
// + CORREÇÃO: TPs parciais agora usam valores REAIS do deal (não estimados)
// + Busca DEAL_PROFIT e DEAL_PRICE do histórico após execução
// + Elimina discrepâncias por slippage em mercados voláteis
// + ExecutePartialClose agora retorna deal ticket por referência
//
// NOVIDADES v1.21:
// + Chama Logger.SavePartialTrade() após cada TP parcial executado
// + TPs parciais agora salvos no CSV imediatamente (3 linhas por trade)
// + Habilita ressincronização ao reiniciar EA
//
// NOVIDADES v1.20:
// + CORREÇÃO CRÍTICA: Lucro de TPs parciais agora é registrado no Logger
// + Após cada TP parcial, calcula lucro e chama Logger.AddPartialTPProfit()
// + Garante que limites diários considerem lucros parciais realizados
//
// NOVIDADES v1.11:
// + Remove TP Fixo após TP2 (deixa trailing livre)
//
// NOVIDADES v1.10:
// + Migração para Logger v3.00 (5 níveis + throttle inteligente)
// + Todas as mensagens classificadas (ERROR/EVENT/DEBUG)
// + PrintAllPositions() agora usa LOG_DEBUG
//
// IMPORTANTE MQL5: Usa ÍNDICES ao invés de ponteiros!
// MQL5 não permite ponteiros para structs simples
// ═══════════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Estrutura: Estado de uma Posição Individual                      |
//+------------------------------------------------------------------+
struct SPositionState
  {
   ulong             ticket;
   datetime          openTime;
   double            openPrice;
   double            originalLot;
   ENUM_POSITION_TYPE posType;

   bool              beActivated;
   bool              trailingActive;

   bool              hasPartialTP;
   bool              tp1_enabled;
   double            tp1_price;
   double            tp1_lot;
   bool              tp1_executed;
   bool              tp2_enabled;
   double            tp2_price;
   double            tp2_lot;
   bool              tp2_executed;
  };

//+------------------------------------------------------------------+
//| Classe: CTradeManager                                            |
//+------------------------------------------------------------------+
class CTradeManager
  {
private:
   CLogger*          m_logger;
   CRiskManager*     m_riskManager;
   SPositionState    m_positions[];

   string            m_inputSymbol;
   int               m_inputMagicNumber;
   int               m_inputSlippage;

   string            m_symbol;
   int               m_magicNumber;
   int               m_slippage;

   bool              ExecutePartialClose(ulong ticket, double lot, string comment, ulong &outDealTicket);
   ENUM_ORDER_TYPE_FILLING GetTypeFilling();
   bool              m_isResyncing;
   string            GetStateFileName();
   void              WriteKV(int handle, string key, string value);
   string            ReadKey(string line);
   string            ReadValue(string line);

public:
                     CTradeManager();
                    ~CTradeManager();

   bool              Init(CLogger* logger, CRiskManager* riskManager, string symbol, int magicNumber, int slippage);

   int               ResyncExistingPositions();
   bool              RegisterPosition(ulong ticket, ENUM_POSITION_TYPE posType, double openPrice, double openLot, bool usePartialTP, SPartialTPLevel &tpLevels[]);
   bool              UnregisterPosition(ulong ticket);
   bool              ClosePosition(ulong ticket, double lotToClose, string comment);

   int               GetPositionIndex(ulong ticket);
   int               GetPositionCount() const { return ArraySize(m_positions); }

   bool              IsBreakevenActivated(ulong ticket);
   void              SetBreakevenActivated(ulong ticket, bool state);

   bool              IsTrailingActive(ulong ticket);
   void              SetTrailingActive(ulong ticket, bool state);

   bool              IsTP1Executed(ulong ticket);
   void              SetTP1Executed(ulong ticket, bool state);

   bool              IsTP2Executed(ulong ticket);
   void              SetTP2Executed(ulong ticket, bool state);

   void              MonitorPartialTP(ulong ticket);
   void              CleanClosedPositions();
   void              Clear();

   void              SetSlippage(int newSlippage);
   void              SetMagicNumber(int newMagic);
   int               GetInputSlippage() const { return m_inputSlippage; }
   int               GetSlippage() const { return m_slippage; }
   int               GetMagicNumber() const { return m_magicNumber; }

   void              PrintAllPositions();

   bool              SaveState();
   bool              LoadState();
   void              DeleteState();
  };

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager()
  {
   m_logger = NULL;
   m_riskManager = NULL;
   m_inputSymbol = _Symbol;
   m_inputMagicNumber = 0;
   m_inputSlippage = 10;
   m_symbol = _Symbol;
   m_magicNumber = 0;
   m_slippage = 10;
   m_isResyncing = false;
   ArrayResize(m_positions, 0);
  }

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager()
  {
   Clear();
  }

//+------------------------------------------------------------------+
//| Inicialização (v1.10 - Logging refatorado)                       |
//+------------------------------------------------------------------+
bool CTradeManager::Init(CLogger* logger, CRiskManager* riskManager, string symbol, int magicNumber, int slippage)
  {
   m_logger = logger;
   m_riskManager = riskManager;
   m_inputSymbol = symbol;
   m_inputMagicNumber = magicNumber;
   m_inputSlippage = slippage;
   m_symbol = symbol;
   m_magicNumber = magicNumber;
   m_slippage = slippage;

   if(m_logger != NULL)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "✅ TradeManager inicializado");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "   Símbolo: " + m_symbol);
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "   Magic: " + IntegerToString(m_magicNumber));
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "   Slippage: " + IntegerToString(m_slippage) + " pts");
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Ressincronizar posições existentes (v1.10)                       |
//+------------------------------------------------------------------+
int CTradeManager::ResyncExistingPositions()
  {
   int synced = 0;
   m_isResyncing = true;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != m_symbol)
         continue;

      if(PositionGetInteger(POSITION_MAGIC) != m_magicNumber)
         continue;

      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;  // ticket inválido

      // Já registrada?
      if(GetPositionIndex(ticket) >= 0)
         continue;

      // Registrar sem Partial TP (posição já existente)
      SPartialTPLevel emptyLevels[];

      RegisterPosition(
         ticket,
         (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE),
         PositionGetDouble(POSITION_PRICE_OPEN),
         PositionGetDouble(POSITION_VOLUME),
         false,  // Sem partial TP para posições ressincronizadas
         emptyLevels
      );

      synced++;

      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "RESYNC", 
            "🔄 Posição ressincronizada: #" + IntegerToString(ticket));
     }

   m_isResyncing = false;

   // Após resync, restaurar estado salvo (TP1/TP2/BE/Trailing)
   if(synced > 0)
     {
      LoadState();
      SaveState();  // Salvar estado restaurado
     }

   return synced;
  }

//+------------------------------------------------------------------+
//| Registrar posição (v1.10)                                        |
//+------------------------------------------------------------------+
bool CTradeManager::RegisterPosition(ulong ticket, ENUM_POSITION_TYPE posType, double openPrice, double openLot, bool usePartialTP, SPartialTPLevel &tpLevels[])
  {
   if(GetPositionIndex(ticket) >= 0)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "WARNING", 
            "⚠️ Posição #" + IntegerToString(ticket) + " já registrada!");
      return false;
     }

   SPositionState newPos;
   newPos.ticket = ticket;
   newPos.openTime = TimeCurrent();
   newPos.openPrice = openPrice;
   newPos.originalLot = openLot;
   newPos.posType = posType;
   newPos.beActivated = false;
   newPos.trailingActive = false;
   newPos.hasPartialTP = usePartialTP;
   newPos.tp1_enabled = false;
   newPos.tp1_price = 0;
   newPos.tp1_lot = 0;
   newPos.tp1_executed = false;
   newPos.tp2_enabled = false;
   newPos.tp2_price = 0;
   newPos.tp2_lot = 0;
   newPos.tp2_executed = false;

   if(usePartialTP && ArraySize(tpLevels) > 0)
     {
      if(ArraySize(tpLevels) >= 1 && tpLevels[0].enabled)
        {
         newPos.tp1_enabled = true;
         newPos.tp1_price = tpLevels[0].priceLevel;
         newPos.tp1_lot = tpLevels[0].lotSize;
        }
      if(ArraySize(tpLevels) >= 2 && tpLevels[1].enabled)
        {
         newPos.tp2_enabled = true;
         newPos.tp2_price = tpLevels[1].priceLevel;
         newPos.tp2_lot = tpLevels[1].lotSize;
        }
     }

   int size = ArraySize(m_positions);
   ArrayResize(m_positions, size + 1);
   m_positions[size] = newPos;

   if(m_logger != NULL)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "📊 Posição registrada no TradeManager:");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "   Ticket: #" + IntegerToString(ticket));
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "   Tipo: " + EnumToString(posType));
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "   Preço: " + DoubleToString(openPrice, _Digits));
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "   Lote: " + DoubleToString(openLot, 2));

      if(usePartialTP)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "   🎯 Partial TP ATIVO:");
         if(newPos.tp1_enabled)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
               "      TP1: " + DoubleToString(newPos.tp1_lot, 2) + " @ " + DoubleToString(newPos.tp1_price, _Digits));
         if(newPos.tp2_enabled)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
               "      TP2: " + DoubleToString(newPos.tp2_lot, 2) + " @ " + DoubleToString(newPos.tp2_price, _Digits));
        }
     }

   SaveState();
   return true;
  }

//+------------------------------------------------------------------+
//| Remover posição (v1.10)                                          |
//+------------------------------------------------------------------+
bool CTradeManager::UnregisterPosition(ulong ticket)
  {
   int index = GetPositionIndex(ticket);
   if(index < 0)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "WARNING", 
            "⚠️ Tentativa de remover posição não encontrada: #" + IntegerToString(ticket));
      return false;
     }

   int size = ArraySize(m_positions);
   for(int i = index; i < size - 1; i++)
      m_positions[i] = m_positions[i + 1];
   ArrayResize(m_positions, size - 1);

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
         "🗑️ Posição #" + IntegerToString(ticket) + " removida do TradeManager");

   SaveState();
   return true;
  }

//+------------------------------------------------------------------+
//| Fechar posição (total ou parcial) - v1.22                        |
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(ulong ticket, double lotToClose, string comment)
  {
   ulong dealTicket = 0;
   return ExecutePartialClose(ticket, lotToClose, comment, dealTicket);
  }

//+------------------------------------------------------------------+
//| Buscar índice                                                    |
//+------------------------------------------------------------------+
int CTradeManager::GetPositionIndex(ulong ticket)
  {
   for(int i = 0; i < ArraySize(m_positions); i++)
      if(m_positions[i].ticket == ticket)
         return i;
   return -1;
  }

//+------------------------------------------------------------------+
//| Breakeven ativado?                                               |
//+------------------------------------------------------------------+
bool CTradeManager::IsBreakevenActivated(ulong ticket)
  {
   int index = GetPositionIndex(ticket);
   return (index >= 0) ? m_positions[index].beActivated : false;
  }

//+------------------------------------------------------------------+
//| Marcar Breakeven (v1.10)                                         |
//+------------------------------------------------------------------+
void CTradeManager::SetBreakevenActivated(ulong ticket, bool state)
  {
   int index = GetPositionIndex(ticket);
   if(index < 0)
      return;

   bool oldState = m_positions[index].beActivated;
   m_positions[index].beActivated = state;

   if(m_logger != NULL && oldState != state)
     {
      if(state)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
            "🔒 Breakeven ativado para posição #" + IntegerToString(ticket));
      else
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
            "🔓 Breakeven desativado para posição #" + IntegerToString(ticket));
     }

   if(oldState != state) SaveState();
  }

//+------------------------------------------------------------------+
//| Trailing ativo?                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::IsTrailingActive(ulong ticket)
  {
   int index = GetPositionIndex(ticket);
   return (index >= 0) ? m_positions[index].trailingActive : false;
  }

//+------------------------------------------------------------------+
//| Marcar Trailing (v1.10)                                          |
//+------------------------------------------------------------------+
void CTradeManager::SetTrailingActive(ulong ticket, bool state)
  {
   int index = GetPositionIndex(ticket);
   if(index < 0)
      return;

   bool oldState = m_positions[index].trailingActive;
   m_positions[index].trailingActive = state;

   if(m_logger != NULL && oldState != state)
     {
      if(state)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
            "📈 Trailing ativado para posição #" + IntegerToString(ticket));
      else
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
            "📉 Trailing desativado para posição #" + IntegerToString(ticket));
     }

   if(oldState != state) SaveState();
  }

//+------------------------------------------------------------------+
//| TP1 executado?                                                   |
//+------------------------------------------------------------------+
bool CTradeManager::IsTP1Executed(ulong ticket)
  {
   int index = GetPositionIndex(ticket);
   return (index >= 0) ? m_positions[index].tp1_executed : false;
  }

//+------------------------------------------------------------------+
//| Marcar TP1 (v1.10)                                               |
//+------------------------------------------------------------------+
void CTradeManager::SetTP1Executed(ulong ticket, bool state)
  {
   int index = GetPositionIndex(ticket);
   if(index < 0)
      return;

   bool oldState = m_positions[index].tp1_executed;
   m_positions[index].tp1_executed = state;

   if(m_logger != NULL && oldState != state && state)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
         "🎯 TP1 executado para posição #" + IntegerToString(ticket));
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
         "   Lote fechado: " + DoubleToString(m_positions[index].tp1_lot, 2));
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
         "   Preço: " + DoubleToString(m_positions[index].tp1_price, _Digits));
     }

   if(oldState != state) SaveState();
  }

//+------------------------------------------------------------------+
//| TP2 executado?                                                   |
//+------------------------------------------------------------------+
bool CTradeManager::IsTP2Executed(ulong ticket)
  {
   int index = GetPositionIndex(ticket);
   return (index >= 0) ? m_positions[index].tp2_executed : false;
  }

//+------------------------------------------------------------------+
//| Marcar TP2 (v1.10)                                               |
//+------------------------------------------------------------------+
void CTradeManager::SetTP2Executed(ulong ticket, bool state)
  {
   int index = GetPositionIndex(ticket);
   if(index < 0)
      return;

   bool oldState = m_positions[index].tp2_executed;
   m_positions[index].tp2_executed = state;

   if(m_logger != NULL && oldState != state && state)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
         "🎯 TP2 executado para posição #" + IntegerToString(ticket));
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
         "   Lote fechado: " + DoubleToString(m_positions[index].tp2_lot, 2));
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
         "   Preço: " + DoubleToString(m_positions[index].tp2_price, _Digits));
     }

   if(oldState != state) SaveState();
  }

//+------------------------------------------------------------------+
//| Monitorar Partial TP (v1.22)                                     |
//| CORREÇÃO: Agora busca valores REAIS do deal no histórico         |
//+------------------------------------------------------------------+
void CTradeManager::MonitorPartialTP(ulong ticket)
  {
   int index = GetPositionIndex(ticket);
   if(index < 0 || !m_positions[index].hasPartialTP)
      return;

   double currentPrice = (m_positions[index].posType == POSITION_TYPE_BUY) ?
                         SymbolInfoDouble(m_symbol, SYMBOL_BID) :
                         SymbolInfoDouble(m_symbol, SYMBOL_ASK);

   // ═══════════════════════════════════════════════════════════════
   // TP1
   // ═══════════════════════════════════════════════════════════════
   if(m_positions[index].tp1_enabled && !m_positions[index].tp1_executed)
     {
      bool tp1Hit = (m_positions[index].posType == POSITION_TYPE_BUY && currentPrice >= m_positions[index].tp1_price) ||
                    (m_positions[index].posType == POSITION_TYPE_SELL && currentPrice <= m_positions[index].tp1_price);

      if(tp1Hit)
        {
         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "═══════════════════════════════════════════════════════════════");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "🎯 TP1 ATINGIDO - Posição #" + IntegerToString(ticket));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
               "   Preço alvo: " + DoubleToString(m_positions[index].tp1_price, _Digits));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
               "   Preço atual: " + DoubleToString(currentPrice, _Digits));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
               "   Fechando: " + DoubleToString(m_positions[index].tp1_lot, 2) + " lote(s)");
           }

         double lotToClose = m_positions[index].tp1_lot;
         ulong dealTicket = 0;

         if(ExecutePartialClose(ticket, lotToClose, "Partial TP1", dealTicket))
           {
            SetTP1Executed(ticket, true);
            if(m_logger != NULL)
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "✅ TP1 executado com sucesso!");

            // ═══════════════════════════════════════════════════════════════
            // 🆕 v1.22: BUSCAR VALORES REAIS DO DEAL NO HISTÓRICO
            // Elimina discrepâncias por slippage
            // ═══════════════════════════════════════════════════════════════
            if(m_logger != NULL && dealTicket > 0)
              {
               double realProfit = 0;
               double realExitPrice = 0;
               double realVolume = 0;
               double openPrice = m_positions[index].openPrice;

               // Atualizar histórico e buscar deal
               datetime from = TimeCurrent() - 60;  // Último minuto
               datetime to = TimeCurrent() + 1;

               if(HistorySelect(from, to) && HistoryDealSelect(dealTicket))
                 {
                  // 🎯 VALORES REAIS DO DEAL
                  realProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                  realExitPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
                  realVolume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);

                  m_logger.Log(LOG_EVENT, THROTTLE_NONE, "PARTIAL_TP",
                     StringFormat("   📊 Deal #%I64u - Valores REAIS:", dealTicket));
                  m_logger.Log(LOG_EVENT, THROTTLE_NONE, "PARTIAL_TP",
                     StringFormat("      Preço execução: %.5f", realExitPrice));
                  m_logger.Log(LOG_EVENT, THROTTLE_NONE, "PARTIAL_TP",
                     StringFormat("      Volume: %.2f", realVolume));
                  m_logger.Log(LOG_EVENT, THROTTLE_NONE, "PARTIAL_TP",
                     StringFormat("      💰 Lucro REAL: $%.2f", realProfit));
                 }
               else
                 {
                  // Fallback: calcular estimado se deal não encontrado
                  m_logger.Log(LOG_EVENT, THROTTLE_NONE, "PARTIAL_TP",
                     "⚠️ Deal não encontrado no histórico - usando estimativa");

                  double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
                  double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);

                  double priceDiff = (m_positions[index].posType == POSITION_TYPE_BUY) ?
                                     (currentPrice - openPrice) : (openPrice - currentPrice);

                  realProfit = (priceDiff / tickSize) * tickValue * lotToClose;
                  realExitPrice = currentPrice;
                  realVolume = lotToClose;
                 }

               // Registrar no Logger para contabilizar no dailyProfit
               m_logger.AddPartialTPProfit(realProfit);

               // Salvar TP parcial no CSV com valores REAIS
               string tradeType = (m_positions[index].posType == POSITION_TYPE_BUY) ? "BUY" : "SELL";
               m_logger.SavePartialTrade(ticket, dealTicket, tradeType, openPrice, realExitPrice,
                                         realVolume, realProfit, "Partial TP1");
              }
           }
         else
           {
            if(m_logger != NULL)
               m_logger.Log(LOG_ERROR, THROTTLE_NONE, "PARTIAL_TP", "❌ Falha ao executar TP1");
           }

         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "═══════════════════════════════════════════════════════════════");
        }
     }

   // ═══════════════════════════════════════════════════════════════
   // TP2
   // ═══════════════════════════════════════════════════════════════
   if(m_positions[index].tp2_enabled && !m_positions[index].tp2_executed)
     {
      bool tp2Hit = (m_positions[index].posType == POSITION_TYPE_BUY && currentPrice >= m_positions[index].tp2_price) ||
                    (m_positions[index].posType == POSITION_TYPE_SELL && currentPrice <= m_positions[index].tp2_price);

      if(tp2Hit)
        {
         if(m_logger != NULL)
           {
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "═══════════════════════════════════════════════════════════════");
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "🎯 TP2 ATINGIDO - Posição #" + IntegerToString(ticket));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
               "   Preço alvo: " + DoubleToString(m_positions[index].tp2_price, _Digits));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
               "   Preço atual: " + DoubleToString(currentPrice, _Digits));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
               "   Fechando: " + DoubleToString(m_positions[index].tp2_lot, 2) + " lote(s)");
           }

         double lotToClose = m_positions[index].tp2_lot;
         ulong dealTicket = 0;

         if(ExecutePartialClose(ticket, lotToClose, "Partial TP2", dealTicket))
           {
            SetTP2Executed(ticket, true);
            if(m_logger != NULL)
               m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "✅ TP2 executado com sucesso!");

            // ═══════════════════════════════════════════════════════════════
            // 🆕 v1.22: BUSCAR VALORES REAIS DO DEAL NO HISTÓRICO
            // Elimina discrepâncias por slippage
            // ═══════════════════════════════════════════════════════════════
            if(m_logger != NULL && dealTicket > 0)
              {
               double realProfit = 0;
               double realExitPrice = 0;
               double realVolume = 0;
               double openPrice = m_positions[index].openPrice;

               // Atualizar histórico e buscar deal
               datetime from = TimeCurrent() - 60;  // Último minuto
               datetime to = TimeCurrent() + 1;

               if(HistorySelect(from, to) && HistoryDealSelect(dealTicket))
                 {
                  // 🎯 VALORES REAIS DO DEAL
                  realProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                  realExitPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
                  realVolume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);

                  m_logger.Log(LOG_EVENT, THROTTLE_NONE, "PARTIAL_TP",
                     StringFormat("   📊 Deal #%I64u - Valores REAIS:", dealTicket));
                  m_logger.Log(LOG_EVENT, THROTTLE_NONE, "PARTIAL_TP",
                     StringFormat("      Preço execução: %.5f", realExitPrice));
                  m_logger.Log(LOG_EVENT, THROTTLE_NONE, "PARTIAL_TP",
                     StringFormat("      Volume: %.2f", realVolume));
                  m_logger.Log(LOG_EVENT, THROTTLE_NONE, "PARTIAL_TP",
                     StringFormat("      💰 Lucro REAL: $%.2f", realProfit));
                 }
               else
                 {
                  // Fallback: calcular estimado se deal não encontrado
                  m_logger.Log(LOG_EVENT, THROTTLE_NONE, "PARTIAL_TP",
                     "⚠️ Deal não encontrado no histórico - usando estimativa");

                  double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
                  double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);

                  double priceDiff = (m_positions[index].posType == POSITION_TYPE_BUY) ?
                                     (currentPrice - openPrice) : (openPrice - currentPrice);

                  realProfit = (priceDiff / tickSize) * tickValue * lotToClose;
                  realExitPrice = currentPrice;
                  realVolume = lotToClose;
                 }

               // Registrar no Logger para contabilizar no dailyProfit
               m_logger.AddPartialTPProfit(realProfit);

               // Salvar TP parcial no CSV com valores REAIS
               string tradeType = (m_positions[index].posType == POSITION_TYPE_BUY) ? "BUY" : "SELL";
               m_logger.SavePartialTrade(ticket, dealTicket, tradeType, openPrice, realExitPrice,
                                         realVolume, realProfit, "Partial TP2");
              }

            // ╔══════════════════════════════════════════════════════════════╗
            // ║  🆕 v1.11 - REMOVER TP FIXO APÓS TP2 (deixa trailing livre) ║
            // ╚══════════════════════════════════════════════════════════════╝
            if(PositionSelectByTicket(ticket))
              {
               double currentTP = PositionGetDouble(POSITION_TP);

               if(currentTP > 0)  // Só tenta remover se houver TP
                 {
                  MqlTradeRequest request = {};
                  MqlTradeResult result = {};

                  request.action = TRADE_ACTION_SLTP;
                  request.position = ticket;
                  request.symbol = m_symbol;
                  request.sl = PositionGetDouble(POSITION_SL);  // Mantém SL atual
                  request.tp = 0;  // Remove TP
                  request.magic = m_magicNumber;

                  if(OrderSend(request, result) && result.retcode == TRADE_RETCODE_DONE)
                    {
                     if(m_logger != NULL)
                        m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
                           "🔓 TP Fixo removido - Trailing livre para operar");
                    }
                  else
                    {
                     if(m_logger != NULL)
                        m_logger.Log(LOG_EVENT, THROTTLE_NONE, "WARNING",
                           "⚠️ Não foi possível remover TP - Retcode: " + IntegerToString(result.retcode));
                    }
                 }
              }
           }
         else
           {
            if(m_logger != NULL)
               m_logger.Log(LOG_ERROR, THROTTLE_NONE, "PARTIAL_TP", "❌ Falha ao executar TP2");
           }

         if(m_logger != NULL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "═══════════════════════════════════════════════════════════════");
        }
     }
  }

//+------------------------------------------------------------------+
//| Executar fechamento parcial (v1.22)                              |
//| Retorna deal ticket por referência para buscar valores reais     |
//+------------------------------------------------------------------+
bool CTradeManager::ExecutePartialClose(ulong ticket, double lot, string comment, ulong &outDealTicket)
  {
   outDealTicket = 0;  // Inicializa

   if(!PositionSelectByTicket(ticket))
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "CLOSE",
            "❌ Posição #" + IntegerToString(ticket) + " não encontrada");
      return false;
     }

   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double currentVolume = PositionGetDouble(POSITION_VOLUME);

   if(lot >= currentVolume)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "CLOSE", "⚠️ Lote parcial >= lote atual - Ajustando");

      double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      lot = currentVolume - minLot;

      if(lot <= 0)
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_ERROR, THROTTLE_NONE, "CLOSE",
               "❌ Não é possível fechar parcial - Lote insuficiente");
         return false;
        }
     }

   double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   if(lotStep <= 0) lotStep = 0.01;  // fallback seguro
   lot = MathFloor((lot + lotStep * 0.1) / lotStep) * lotStep;  // +epsilon previne truncamento por imprecisão IEEE 754

   double minLotFinal = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   if(lot < minLotFinal - lotStep * 0.1)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "CLOSE",
            "❌ Lote parcial " + DoubleToString(lot, 2) + " < mínimo " + DoubleToString(minLotFinal, 2) + " após arredondamento");
      return false;
     }

   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol = m_symbol;
   request.volume = lot;
   request.type = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   request.price = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(m_symbol, SYMBOL_BID) : SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   request.deviation = m_slippage;
   request.magic = m_magicNumber;
   request.comment = comment;
   request.type_filling = GetTypeFilling();

   if(!OrderSend(request, result))
     {
      if(m_logger != NULL)
        {
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "CLOSE", "❌ Falha ao enviar ordem parcial");
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "CLOSE",
            "   Retcode: " + IntegerToString(result.retcode));
        }
      return false;
     }

   if(result.retcode == TRADE_RETCODE_DONE)
     {
      // 🆕 v1.22: Retornar deal ticket para buscar valores reais
      outDealTicket = result.deal;

      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO", "✅ Fechamento parcial executado:");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
            "   Deal: #" + IntegerToString(result.deal));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
            "   Volume: " + DoubleToString(result.volume, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INFO",
            "   Preço: " + DoubleToString(result.price, _Digits));
        }
      return true;
     }

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "CLOSE",
         "⚠️ Retcode: " + IntegerToString(result.retcode));

   return false;
  }

//+------------------------------------------------------------------+
//| Limpar posições fechadas (v1.10)                                 |
//+------------------------------------------------------------------+
void CTradeManager::CleanClosedPositions()
  {
   int removedCount = 0;

   for(int i = ArraySize(m_positions) - 1; i >= 0; i--)
     {
      if(!PositionSelectByTicket(m_positions[i].ticket))
        {
         ulong ticket = m_positions[i].ticket;
         int size = ArraySize(m_positions);
         for(int j = i; j < size - 1; j++)
            m_positions[j] = m_positions[j + 1];
         ArrayResize(m_positions, size - 1);
         removedCount++;

         if(m_logger != NULL)
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "CLEANUP", 
               "🗑️ Posição fechada removida: #" + IntegerToString(ticket));
        }
     }

   if(removedCount > 0)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "CLEANUP",
            "🧹 Limpeza: " + IntegerToString(removedCount) + " posição(ões) removida(s)");
      SaveState();
     }
  }

//+------------------------------------------------------------------+
//| Limpar todas (v1.10)                                             |
//+------------------------------------------------------------------+
void CTradeManager::Clear()
  {
   ArrayResize(m_positions, 0);
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "CLEANUP", 
         "🗑️ TradeManager: Todas as posições limpas");
  }

//+------------------------------------------------------------------+
//| Hot Reload (v1.10)                                               |
//+------------------------------------------------------------------+
void CTradeManager::SetSlippage(int newSlippage)
  {
   int oldValue = m_slippage;
   if(newSlippage == oldValue) return;
   m_slippage = newSlippage;

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "🔄 Slippage: " + IntegerToString(oldValue) + " → " + IntegerToString(newSlippage) + " pts");
  }

//+------------------------------------------------------------------+
//| Hot Reload — Magic Number                                        |
//+------------------------------------------------------------------+
void CTradeManager::SetMagicNumber(int newMagic)
  {
   int oldValue = m_magicNumber;
   if(oldValue == newMagic) return;

   // Deletar state file do magic antigo ANTES de atualizar m_magicNumber
   DeleteState();

   m_magicNumber = newMagic;

   // Limpar posições registradas (pertencem ao magic antigo)
   ArrayResize(m_positions, 0);

   // Re-sincronizar posições abertas do novo magic (se houver)
   ResyncExistingPositions();

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
         "Magic Number: " + IntegerToString(oldValue) + " -> " + IntegerToString(newMagic)
         + " | Posicoes resincronizadas");
  }

//+------------------------------------------------------------------+
//| Debug (v1.10)                                                    |
//+------------------------------------------------------------------+
void CTradeManager::PrintAllPositions()
  {
   if(m_logger == NULL)
      return;

   int count = ArraySize(m_positions);

   m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", "═══════════════════════════════════════════════════════════════");
   m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", "📊 TRADEMANAGER - POSIÇÕES: " + IntegerToString(count));
   m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", "═══════════════════════════════════════════════════════════════");

   if(count == 0)
     {
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", "   (Nenhuma posição rastreada)");
     }
   else
     {
      for(int i = 0; i < count; i++)
        {
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", "");
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", "🔹 Posição #" + IntegerToString(i + 1) + ":");
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", "   Ticket: #" + IntegerToString(m_positions[i].ticket));
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", "   Tipo: " + EnumToString(m_positions[i].posType));
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", "   Breakeven: " + (m_positions[i].beActivated ? "ATIVADO" : "não"));
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", "   Trailing: " + (m_positions[i].trailingActive ? "ATIVO" : "não"));

         if(m_positions[i].hasPartialTP)
           {
            m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", "   🎯 Partial TP:");
            if(m_positions[i].tp1_enabled)
               m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", 
                  "      TP1: " + (m_positions[i].tp1_executed ? "✅" : "⏳") +
                  " | " + DoubleToString(m_positions[i].tp1_lot, 2) + " @ " + DoubleToString(m_positions[i].tp1_price, _Digits));
            if(m_positions[i].tp2_enabled)
               m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", 
                  "      TP2: " + (m_positions[i].tp2_executed ? "✅" : "⏳") +
                  " | " + DoubleToString(m_positions[i].tp2_lot, 2) + " @ " + DoubleToString(m_positions[i].tp2_price, _Digits));
           }
        }
     }

   m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DEBUG", "═══════════════════════════════════════════════════════════════");
  }

//+------------------------------------------------------------------+
//| GetTypeFilling                                                   |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING CTradeManager::GetTypeFilling()
  {
   uint filling = (uint)SymbolInfoInteger(m_symbol, SYMBOL_FILLING_MODE);

   if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   else
      if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
         return ORDER_FILLING_IOC;

   return ORDER_FILLING_RETURN;
  }

//+------------------------------------------------------------------+
//| GetStateFileName — arquivo de persistência de estado              |
//+------------------------------------------------------------------+
string CTradeManager::GetStateFileName()
  {
   return "Matrix_" + m_symbol + "_" + IntegerToString(m_magicNumber) + ".state";
  }

//+------------------------------------------------------------------+
//| WriteKV — escreve key=value                                       |
//+------------------------------------------------------------------+
void CTradeManager::WriteKV(int handle, string key, string value)
  {
   FileWriteString(handle, key + "=" + value + "\n");
  }

//+------------------------------------------------------------------+
//| ReadKey — extrai chave de "key=value"                              |
//+------------------------------------------------------------------+
string CTradeManager::ReadKey(string line)
  {
   int pos = StringFind(line, "=");
   if(pos <= 0) return "";
   return StringSubstr(line, 0, pos);
  }

//+------------------------------------------------------------------+
//| ReadValue — extrai valor de "key=value"                            |
//+------------------------------------------------------------------+
string CTradeManager::ReadValue(string line)
  {
   int pos = StringFind(line, "=");
   if(pos < 0) return "";
   return StringSubstr(line, pos + 1);
  }

//+------------------------------------------------------------------+
//| SaveState — persiste estado de todas as posições (v1.24)          |
//+------------------------------------------------------------------+
bool CTradeManager::SaveState()
  {
   if(MQLInfoInteger(MQL_TESTER)) return false;
   if(m_isResyncing) return true;  // Suprimir durante resync (LoadState vem depois)

   int count = ArraySize(m_positions);

   // Se não há posições, apagar o arquivo
   if(count == 0)
     {
      DeleteState();
      return true;
     }

   string fn = GetStateFileName();
   string fnTmp = fn + ".tmp";

   int h = FileOpen(fnTmp, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_ERROR, THROTTLE_NONE, "STATE", "❌ Falha ao abrir " + fnTmp);
      return false;
     }

   FileWriteString(h, "# TradeManager State - NAO EDITAR MANUALMENTE\n");
   WriteKV(h, "StateVersion", "1");
   WriteKV(h, "PositionCount", IntegerToString(count));
   WriteKV(h, "Timestamp", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));

   for(int i = 0; i < count; i++)
     {
      string prefix = "P" + IntegerToString(i) + "_";
      WriteKV(h, prefix + "Ticket",         IntegerToString(m_positions[i].ticket));
      WriteKV(h, prefix + "OpenTime",       TimeToString(m_positions[i].openTime, TIME_DATE | TIME_SECONDS));
      WriteKV(h, prefix + "OpenPrice",      DoubleToString(m_positions[i].openPrice, _Digits));
      WriteKV(h, prefix + "OriginalLot",    DoubleToString(m_positions[i].originalLot, 2));
      WriteKV(h, prefix + "PosType",        IntegerToString((int)m_positions[i].posType));
      WriteKV(h, prefix + "BEActivated",    IntegerToString(m_positions[i].beActivated));
      WriteKV(h, prefix + "TrailingActive", IntegerToString(m_positions[i].trailingActive));
      WriteKV(h, prefix + "HasPartialTP",   IntegerToString(m_positions[i].hasPartialTP));
      WriteKV(h, prefix + "TP1Enabled",     IntegerToString(m_positions[i].tp1_enabled));
      WriteKV(h, prefix + "TP1Price",       DoubleToString(m_positions[i].tp1_price, _Digits));
      WriteKV(h, prefix + "TP1Lot",         DoubleToString(m_positions[i].tp1_lot, 2));
      WriteKV(h, prefix + "TP1Executed",    IntegerToString(m_positions[i].tp1_executed));
      WriteKV(h, prefix + "TP2Enabled",     IntegerToString(m_positions[i].tp2_enabled));
      WriteKV(h, prefix + "TP2Price",       DoubleToString(m_positions[i].tp2_price, _Digits));
      WriteKV(h, prefix + "TP2Lot",         DoubleToString(m_positions[i].tp2_lot, 2));
      WriteKV(h, prefix + "TP2Executed",    IntegerToString(m_positions[i].tp2_executed));
     }

   FileClose(h);

   // Escrita atômica
   FileDelete(fn);
   if(!FileMove(fnTmp, 0, fn, 0))
     {
      int src = FileOpen(fnTmp, FILE_READ | FILE_TXT | FILE_ANSI);
      if(src != INVALID_HANDLE)
        {
         int dst = FileOpen(fn, FILE_WRITE | FILE_TXT | FILE_ANSI);
         if(dst != INVALID_HANDLE)
           {
            while(!FileIsEnding(src))
               FileWriteString(dst, FileReadString(src) + "\n");
            FileClose(dst);
           }
         FileClose(src);
         FileDelete(fnTmp);
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| LoadState — restaura estado das posições após restart (v1.24)     |
//+------------------------------------------------------------------+
bool CTradeManager::LoadState()
  {
   if(MQLInfoInteger(MQL_TESTER)) return false;

   string fn = GetStateFileName();
   int h = FileOpen(fn, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) return false;

   // Parse em duas passagens: primeiro conta, depois preenche
   int posCount = 0;

   // Ler todas as KVs em arrays temporários
   string keys[];
   string vals[];
   int kvCount = 0;

   while(!FileIsEnding(h))
     {
      string line = FileReadString(h);
      if(StringLen(line) == 0) continue;
      if(StringGetCharacter(line, 0) == '#') continue;

      string key = ReadKey(line);
      string val = ReadValue(line);
      if(StringLen(key) == 0) continue;

      ArrayResize(keys, kvCount + 1);
      ArrayResize(vals, kvCount + 1);
      keys[kvCount] = key;
      vals[kvCount] = val;
      kvCount++;

      if(key == "PositionCount")
         posCount = (int)StringToInteger(val);
     }
   FileClose(h);

   if(posCount == 0) return true;

   // Para cada posição salva, tentar encontrar na lista m_positions e restaurar flags
   int restored = 0;
   for(int i = 0; i < posCount; i++)
     {
      string prefix = "P" + IntegerToString(i) + "_";
      ulong savedTicket = 0;

      // Encontrar o ticket dessa posição salva
      for(int k = 0; k < kvCount; k++)
        {
         if(keys[k] == prefix + "Ticket")
           {
            savedTicket = (ulong)StringToInteger(vals[k]);
            break;
           }
        }

      if(savedTicket == 0) continue;

      // Procurar essa posição no array m_positions (já registrada por ResyncExistingPositions)
      int idx = GetPositionIndex(savedTicket);
      if(idx < 0) continue;  // Posição não existe mais no broker

      // Restaurar TODOS os campos do estado salvo
      for(int k = 0; k < kvCount; k++)
        {
         if(StringFind(keys[k], prefix) != 0) continue;

         string field = StringSubstr(keys[k], StringLen(prefix));

         if(field == "OpenTime")        m_positions[idx].openTime       = StringToTime(vals[k]);
         else if(field == "OpenPrice")  m_positions[idx].openPrice      = StringToDouble(vals[k]);
         else if(field == "OriginalLot")m_positions[idx].originalLot    = StringToDouble(vals[k]);
         else if(field == "PosType")    m_positions[idx].posType        = (ENUM_POSITION_TYPE)StringToInteger(vals[k]);
         else if(field == "BEActivated")    m_positions[idx].beActivated    = (bool)StringToInteger(vals[k]);
         else if(field == "TrailingActive") m_positions[idx].trailingActive = (bool)StringToInteger(vals[k]);
         else if(field == "HasPartialTP")   m_positions[idx].hasPartialTP   = (bool)StringToInteger(vals[k]);
         else if(field == "TP1Enabled")     m_positions[idx].tp1_enabled    = (bool)StringToInteger(vals[k]);
         else if(field == "TP1Price")       m_positions[idx].tp1_price      = StringToDouble(vals[k]);
         else if(field == "TP1Lot")         m_positions[idx].tp1_lot        = StringToDouble(vals[k]);
         else if(field == "TP1Executed")    m_positions[idx].tp1_executed   = (bool)StringToInteger(vals[k]);
         else if(field == "TP2Enabled")     m_positions[idx].tp2_enabled    = (bool)StringToInteger(vals[k]);
         else if(field == "TP2Price")       m_positions[idx].tp2_price      = StringToDouble(vals[k]);
         else if(field == "TP2Lot")         m_positions[idx].tp2_lot        = StringToDouble(vals[k]);
         else if(field == "TP2Executed")    m_positions[idx].tp2_executed   = (bool)StringToInteger(vals[k]);
        }

      restored++;
     }

   if(m_logger != NULL && restored > 0)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "STATE",
         "🔄 Estado restaurado para " + IntegerToString(restored) + " posição(ões)");

   return true;
  }

//+------------------------------------------------------------------+
//| DeleteState — remove arquivo de estado (v1.24)                    |
//+------------------------------------------------------------------+
void CTradeManager::DeleteState()
  {
   if(MQLInfoInteger(MQL_TESTER)) return;
   FileDelete(GetStateFileName());
  }

//+------------------------------------------------------------------+
//| FIM DO ARQUIVO
//+------------------------------------------------------------------+
