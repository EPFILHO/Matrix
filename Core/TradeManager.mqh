//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                                         Copyright 2025, EP Filho |
//|              Gerenciamento de Posições Individuais - EPBot Matrix|
//|                                                      Versão 1.00 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EP Filho"
#property version   "1.00"

// ═══════════════════════════════════════════════════════════════════
// INCLUDES
// ═══════════════════════════════════════════════════════════════════
#include "Logger.mqh"
#include "RiskManager.mqh"

// ═══════════════════════════════════════════════════════════════════
// ARQUITETURA TRADEMANAGER v1.00:
// - Rastreia CADA posição individualmente com seu próprio estado
// - Gerencia Breakeven por posição (não global)
// - Gerencia Trailing por posição (não global)
// - Gerencia Partial TP por posição (TP1, TP2)
// - Hot Reload completo (Input + Working variables)
// - Integração total com Logger e RiskManager
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
   
   bool              ExecutePartialClose(ulong ticket, double lot, string comment);
   ENUM_ORDER_TYPE_FILLING GetTypeFilling();

public:
                     CTradeManager();
                    ~CTradeManager();
   
   bool              Init(CLogger* logger, CRiskManager* riskManager, string symbol, int magicNumber, int slippage);
   
   bool              RegisterPosition(ulong ticket, ENUM_POSITION_TYPE posType, double openPrice, double openLot, bool usePartialTP, SPartialTPLevel &tpLevels[]);
   bool              UnregisterPosition(ulong ticket);
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
   int               GetInputSlippage() const { return m_inputSlippage; }
   int               GetSlippage() const { return m_slippage; }
   
   void              PrintAllPositions();
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
//| Inicialização                                                     |
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
      m_logger.LogInfo("✅ TradeManager inicializado");
      m_logger.LogInfo("   Símbolo: " + m_symbol);
      m_logger.LogInfo("   Magic: " + IntegerToString(m_magicNumber));
      m_logger.LogInfo("   Slippage: " + IntegerToString(m_slippage) + " pts");
   }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Registrar posição                                                |
//+------------------------------------------------------------------+
bool CTradeManager::RegisterPosition(ulong ticket, ENUM_POSITION_TYPE posType, double openPrice, double openLot, bool usePartialTP, SPartialTPLevel &tpLevels[])
  {
   if(GetPositionIndex(ticket) >= 0)
   {
      if(m_logger != NULL)
         m_logger.LogWarning("⚠️ Posição #" + IntegerToString(ticket) + " já registrada!");
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
      m_logger.LogInfo("📊 Posição registrada no TradeManager:");
      m_logger.LogInfo("   Ticket: #" + IntegerToString(ticket));
      m_logger.LogInfo("   Tipo: " + EnumToString(posType));
      m_logger.LogInfo("   Preço: " + DoubleToString(openPrice, _Digits));
      m_logger.LogInfo("   Lote: " + DoubleToString(openLot, 2));
      
      if(usePartialTP)
      {
         m_logger.LogInfo("   🎯 Partial TP ATIVO:");
         if(newPos.tp1_enabled)
            m_logger.LogInfo("      TP1: " + DoubleToString(newPos.tp1_lot, 2) + " @ " + DoubleToString(newPos.tp1_price, _Digits));
         if(newPos.tp2_enabled)
            m_logger.LogInfo("      TP2: " + DoubleToString(newPos.tp2_lot, 2) + " @ " + DoubleToString(newPos.tp2_price, _Digits));
      }
   }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Remover posição                                                  |
//+------------------------------------------------------------------+
bool CTradeManager::UnregisterPosition(ulong ticket)
  {
   int index = GetPositionIndex(ticket);
   if(index < 0)
   {
      if(m_logger != NULL)
         m_logger.LogWarning("⚠️ Tentativa de remover posição não encontrada: #" + IntegerToString(ticket));
      return false;
   }
   
   int size = ArraySize(m_positions);
   for(int i = index; i < size - 1; i++)
      m_positions[i] = m_positions[i + 1];
   ArrayResize(m_positions, size - 1);
   
   if(m_logger != NULL)
      m_logger.LogInfo("🗑️ Posição #" + IntegerToString(ticket) + " removida do TradeManager");
   
   return true;
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
//| Marcar Breakeven                                                 |
//+------------------------------------------------------------------+
void CTradeManager::SetBreakevenActivated(ulong ticket, bool state)
  {
   int index = GetPositionIndex(ticket);
   if(index < 0) return;
   
   bool oldState = m_positions[index].beActivated;
   m_positions[index].beActivated = state;
   
   if(m_logger != NULL && oldState != state)
   {
      if(state)
         m_logger.LogInfo("🔒 Breakeven ativado para posição #" + IntegerToString(ticket));
      else
         m_logger.LogInfo("🔓 Breakeven desativado para posição #" + IntegerToString(ticket));
   }
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
//| Marcar Trailing                                                  |
//+------------------------------------------------------------------+
void CTradeManager::SetTrailingActive(ulong ticket, bool state)
  {
   int index = GetPositionIndex(ticket);
   if(index < 0) return;
   
   bool oldState = m_positions[index].trailingActive;
   m_positions[index].trailingActive = state;
   
   if(m_logger != NULL && oldState != state)
   {
      if(state)
         m_logger.LogInfo("📈 Trailing ativado para posição #" + IntegerToString(ticket));
      else
         m_logger.LogInfo("📉 Trailing desativado para posição #" + IntegerToString(ticket));
   }
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
//| Marcar TP1                                                       |
//+------------------------------------------------------------------+
void CTradeManager::SetTP1Executed(ulong ticket, bool state)
  {
   int index = GetPositionIndex(ticket);
   if(index < 0) return;
   
   bool oldState = m_positions[index].tp1_executed;
   m_positions[index].tp1_executed = state;
   
   if(m_logger != NULL && oldState != state && state)
   {
      m_logger.LogInfo("🎯 TP1 executado para posição #" + IntegerToString(ticket));
      m_logger.LogInfo("   Lote fechado: " + DoubleToString(m_positions[index].tp1_lot, 2));
      m_logger.LogInfo("   Preço: " + DoubleToString(m_positions[index].tp1_price, _Digits));
   }
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
//| Marcar TP2                                                       |
//+------------------------------------------------------------------+
void CTradeManager::SetTP2Executed(ulong ticket, bool state)
  {
   int index = GetPositionIndex(ticket);
   if(index < 0) return;
   
   bool oldState = m_positions[index].tp2_executed;
   m_positions[index].tp2_executed = state;
   
   if(m_logger != NULL && oldState != state && state)
   {
      m_logger.LogInfo("🎯 TP2 executado para posição #" + IntegerToString(ticket));
      m_logger.LogInfo("   Lote fechado: " + DoubleToString(m_positions[index].tp2_lot, 2));
      m_logger.LogInfo("   Preço: " + DoubleToString(m_positions[index].tp2_price, _Digits));
   }
  }

//+------------------------------------------------------------------+
//| Monitorar Partial TP                                             |
//+------------------------------------------------------------------+
void CTradeManager::MonitorPartialTP(ulong ticket)
  {
   int index = GetPositionIndex(ticket);
   if(index < 0 || !m_positions[index].hasPartialTP) return;
   
   double currentPrice = (m_positions[index].posType == POSITION_TYPE_BUY) ? 
                         SymbolInfoDouble(m_symbol, SYMBOL_BID) : 
                         SymbolInfoDouble(m_symbol, SYMBOL_ASK);
   
   // TP1
   if(m_positions[index].tp1_enabled && !m_positions[index].tp1_executed)
   {
      bool tp1Hit = (m_positions[index].posType == POSITION_TYPE_BUY && currentPrice >= m_positions[index].tp1_price) ||
                    (m_positions[index].posType == POSITION_TYPE_SELL && currentPrice <= m_positions[index].tp1_price);
      
      if(tp1Hit)
      {
         if(m_logger != NULL)
         {
            m_logger.LogInfo("═══════════════════════════════════════════════════════════════");
            m_logger.LogInfo("🎯 TP1 ATINGIDO - Posição #" + IntegerToString(ticket));
            m_logger.LogInfo("   Preço alvo: " + DoubleToString(m_positions[index].tp1_price, _Digits));
            m_logger.LogInfo("   Preço atual: " + DoubleToString(currentPrice, _Digits));
            m_logger.LogInfo("   Fechando: " + DoubleToString(m_positions[index].tp1_lot, 2) + " lote(s)");
         }
         
         if(ExecutePartialClose(ticket, m_positions[index].tp1_lot, "Partial TP1"))
         {
            SetTP1Executed(ticket, true);
            if(m_logger != NULL) m_logger.LogInfo("✅ TP1 executado com sucesso!");
         }
         else
         {
            if(m_logger != NULL) m_logger.LogError("❌ Falha ao executar TP1");
         }
         
         if(m_logger != NULL)
            m_logger.LogInfo("═══════════════════════════════════════════════════════════════");
      }
   }
   
   // TP2
   if(m_positions[index].tp2_enabled && !m_positions[index].tp2_executed)
   {
      bool tp2Hit = (m_positions[index].posType == POSITION_TYPE_BUY && currentPrice >= m_positions[index].tp2_price) ||
                    (m_positions[index].posType == POSITION_TYPE_SELL && currentPrice <= m_positions[index].tp2_price);
      
      if(tp2Hit)
      {
         if(m_logger != NULL)
         {
            m_logger.LogInfo("═══════════════════════════════════════════════════════════════");
            m_logger.LogInfo("🎯 TP2 ATINGIDO - Posição #" + IntegerToString(ticket));
            m_logger.LogInfo("   Preço alvo: " + DoubleToString(m_positions[index].tp2_price, _Digits));
            m_logger.LogInfo("   Preço atual: " + DoubleToString(currentPrice, _Digits));
            m_logger.LogInfo("   Fechando: " + DoubleToString(m_positions[index].tp2_lot, 2) + " lote(s)");
         }
         
         if(ExecutePartialClose(ticket, m_positions[index].tp2_lot, "Partial TP2"))
         {
            SetTP2Executed(ticket, true);
            if(m_logger != NULL) m_logger.LogInfo("✅ TP2 executado com sucesso!");
         }
         else
         {
            if(m_logger != NULL) m_logger.LogError("❌ Falha ao executar TP2");
         }
         
         if(m_logger != NULL)
            m_logger.LogInfo("═══════════════════════════════════════════════════════════════");
      }
   }
  }

//+------------------------------------------------------------------+
//| Executar fechamento parcial                                      |
//+------------------------------------------------------------------+
bool CTradeManager::ExecutePartialClose(ulong ticket, double lot, string comment)
  {
   if(!PositionSelectByTicket(ticket))
   {
      if(m_logger != NULL)
         m_logger.LogError("❌ Posição #" + IntegerToString(ticket) + " não encontrada");
      return false;
   }
   
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double currentVolume = PositionGetDouble(POSITION_VOLUME);
   
   if(lot >= currentVolume)
   {
      if(m_logger != NULL)
         m_logger.LogWarning("⚠️ Lote parcial >= lote atual - Ajustando");
      
      double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      lot = currentVolume - minLot;
      
      if(lot <= 0)
      {
         if(m_logger != NULL)
            m_logger.LogError("❌ Não é possível fechar parcial - Lote insuficiente");
         return false;
      }
   }
   
   double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   lot = MathFloor(lot / lotStep) * lotStep;
   
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
         m_logger.LogError("❌ Falha ao enviar ordem parcial");
         m_logger.LogError("   Retcode: " + IntegerToString(result.retcode));
      }
      return false;
   }
   
   if(result.retcode == TRADE_RETCODE_DONE)
   {
      if(m_logger != NULL)
      {
         m_logger.LogInfo("✅ Fechamento parcial executado:");
         m_logger.LogInfo("   Deal: #" + IntegerToString(result.deal));
         m_logger.LogInfo("   Volume: " + DoubleToString(result.volume, 2));
         m_logger.LogInfo("   Preço: " + DoubleToString(result.price, _Digits));
      }
      return true;
   }
   
   if(m_logger != NULL)
      m_logger.LogWarning("⚠️ Retcode: " + IntegerToString(result.retcode));
   
   return false;
  }

//+------------------------------------------------------------------+
//| Limpar posições fechadas                                         |
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
            m_logger.LogDebug("🗑️ Posição fechada removida: #" + IntegerToString(ticket));
      }
   }
   
   if(removedCount > 0 && m_logger != NULL)
      m_logger.LogInfo("🧹 Limpeza: " + IntegerToString(removedCount) + " posição(ões) removida(s)");
  }

//+------------------------------------------------------------------+
//| Limpar todas                                                     |
//+------------------------------------------------------------------+
void CTradeManager::Clear()
  {
   ArrayResize(m_positions, 0);
   if(m_logger != NULL)
      m_logger.LogInfo("🗑️ TradeManager: Todas as posições limpas");
  }

//+------------------------------------------------------------------+
//| Hot Reload                                                       |
//+------------------------------------------------------------------+
void CTradeManager::SetSlippage(int newSlippage)
  {
   int oldValue = m_slippage;
   m_slippage = newSlippage;
   
   if(m_logger != NULL)
      m_logger.LogInfo("🔄 Slippage: " + IntegerToString(oldValue) + " → " + IntegerToString(newSlippage) + " pts");
  }

//+------------------------------------------------------------------+
//| Debug                                                            |
//+------------------------------------------------------------------+
void CTradeManager::PrintAllPositions()
  {
   if(m_logger == NULL) return;
   
   int count = ArraySize(m_positions);
   
   m_logger.LogInfo("═══════════════════════════════════════════════════════════════");
   m_logger.LogInfo("📊 TRADEMANAGER - POSIÇÕES: " + IntegerToString(count));
   m_logger.LogInfo("═══════════════════════════════════════════════════════════════");
   
   if(count == 0)
   {
      m_logger.LogInfo("   (Nenhuma posição rastreada)");
   }
   else
   {
      for(int i = 0; i < count; i++)
      {
         m_logger.LogInfo("");
         m_logger.LogInfo("🔹 Posição #" + IntegerToString(i + 1) + ":");
         m_logger.LogInfo("   Ticket: #" + IntegerToString(m_positions[i].ticket));
         m_logger.LogInfo("   Tipo: " + EnumToString(m_positions[i].posType));
         m_logger.LogInfo("   Breakeven: " + (m_positions[i].beActivated ? "ATIVADO" : "não"));
         m_logger.LogInfo("   Trailing: " + (m_positions[i].trailingActive ? "ATIVO" : "não"));
         
         if(m_positions[i].hasPartialTP)
         {
            m_logger.LogInfo("   🎯 Partial TP:");
            if(m_positions[i].tp1_enabled)
               m_logger.LogInfo("      TP1: " + (m_positions[i].tp1_executed ? "✅" : "⏳") + 
                              " | " + DoubleToString(m_positions[i].tp1_lot, 2) + " @ " + DoubleToString(m_positions[i].tp1_price, _Digits));
            if(m_positions[i].tp2_enabled)
               m_logger.LogInfo("      TP2: " + (m_positions[i].tp2_executed ? "✅" : "⏳") + 
                              " | " + DoubleToString(m_positions[i].tp2_lot, 2) + " @ " + DoubleToString(m_positions[i].tp2_price, _Digits));
         }
      }
   }
   
   m_logger.LogInfo("═══════════════════════════════════════════════════════════════");
  }

//+------------------------------------------------------------------+
//| GetTypeFilling                                                   |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING CTradeManager::GetTypeFilling()
  {
   uint filling = (uint)SymbolInfoInteger(m_symbol, SYMBOL_FILLING_MODE);
   
   if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   else if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
      return ORDER_FILLING_IOC;
   
   return ORDER_FILLING_RETURN;
  }
//+------------------------------------------------------------------+
