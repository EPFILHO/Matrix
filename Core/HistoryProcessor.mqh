//+------------------------------------------------------------------+
//|                                             HistoryProcessor.mqh |
//|                                         Copyright 2026, EP Filho |
//|         Processador de Fechamento de Posições - EPBot Matrix     |
//|                     Versão 1.00 - Refatoração (Fatia 1)          |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO"
#property version   "1.00"

// ═══════════════════════════════════════════════════════════════════
// CHANGELOG v1.00:
// + Extraído de EPBot_Matrix.mq5 OnTick() (linhas 1432–1515 originais).
// + Detecta fechamento de posição comparando ticket anterior x atual.
// + Padrão MQL5: soma TODOS os deals de saída (partial + final)
//   para classificar win/loss corretamente (ver referência interna
//   em https://www.mql5.com/en/forum/439334).
// + Depende de CLogger, CBlockers, CTradeManager via DI (Init).
// ═══════════════════════════════════════════════════════════════════

#include "Logger.mqh"
#include "Blockers.mqh"
#include "TradeManager.mqh"

//+------------------------------------------------------------------+
//| Classe CHistoryProcessor                                         |
//| Detecta fechamento de posição e atualiza estatísticas/bloqueios. |
//+------------------------------------------------------------------+
class CHistoryProcessor
  {
private:
   CLogger*          m_logger;
   CBlockers*        m_blockers;
   CTradeManager*    m_tradeManager;

public:
                     CHistoryProcessor();
                    ~CHistoryProcessor();

   bool              Init(CLogger *logger, CBlockers *blockers, CTradeManager *tradeManager);

   // ═══════════════════════════════════════════════════════════════
   // Detecta e processa fechamento de posição.
   //
   // Parâmetros:
   //   lastPositionTicket - ticket registrado no tick anterior (0 = sem posição)
   //   hasCurrentPosition - existe posição do EA neste tick?
   //   lockTradeCandle    - se true E houve fechamento, atualiza lastTradeBarTime
   //                        (bloqueia re-entrada no mesmo candle; skip em modo VM)
   //   lastTradeBarTime   - [INOUT] recebe iTime(0) quando lockTradeCandle=true
   //                         e fechamento foi detectado
   //
   // Retorno: true quando detectou fechamento (posição existia e sumiu).
   //          O chamador deve zerar seu g_lastPositionTicket quando receber true.
   // ═══════════════════════════════════════════════════════════════
   bool              ProcessClosure(ulong lastPositionTicket,
                                    bool hasCurrentPosition,
                                    bool lockTradeCandle,
                                    datetime &lastTradeBarTime);
  };

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CHistoryProcessor::CHistoryProcessor()
  {
   m_logger       = NULL;
   m_blockers     = NULL;
   m_tradeManager = NULL;
  }

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CHistoryProcessor::~CHistoryProcessor()
  {
   m_logger       = NULL;
   m_blockers     = NULL;
   m_tradeManager = NULL;
  }

//+------------------------------------------------------------------+
//| Inicialização (dependency injection)                              |
//+------------------------------------------------------------------+
bool CHistoryProcessor::Init(CLogger *logger, CBlockers *blockers, CTradeManager *tradeManager)
  {
   if(logger == NULL || blockers == NULL || tradeManager == NULL)
      return false;

   m_logger       = logger;
   m_blockers     = blockers;
   m_tradeManager = tradeManager;
   return true;
  }

//+------------------------------------------------------------------+
//| Processa fechamento de posição                                    |
//+------------------------------------------------------------------+
bool CHistoryProcessor::ProcessClosure(ulong lastPositionTicket,
                                       bool hasCurrentPosition,
                                       bool lockTradeCandle,
                                       datetime &lastTradeBarTime)
  {
// Só há fechamento quando tinha ticket e não tem mais posição
   if(lastPositionTicket == 0 || hasCurrentPosition)
      return false;

// Buscar informação do fechamento no histórico
   if(HistorySelectByPosition(lastPositionTicket))
     {
      // ═══════════════════════════════════════════════════════════════
      // PADRÃO OURO MQL5: Somar TODOS os deals de saída desta posição
      // Referência: https://www.mql5.com/en/forum/439334
      // ═══════════════════════════════════════════════════════════════
      double totalPositionProfit = 0;
      double finalDealProfit     = 0;
      ulong  finalDealTicket     = 0;
      bool   foundFinalDeal      = false;

      for(int i = 0; i < HistoryDealsTotal(); i++)
        {
         ulong dealTicket = HistoryDealGetTicket(i);
         if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == lastPositionTicket)
           {
            long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
            if(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY)
              {
               // Somar lucro de TODOS os deals de saída (parciais + final)
               double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
               totalPositionProfit += dealProfit;

               string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);

               // TPs parciais já foram salvos por SavePartialTrade()
               if(StringFind(dealComment, "Partial") >= 0)
                  continue;

               // Deal final (SL, TP fixo, trailing, etc)
               finalDealProfit = dealProfit;
               finalDealTicket = dealTicket;
               foundFinalDeal  = true;
               // NÃO usar break - continuar para pegar o último
              }
           }
        }

      if(foundFinalDeal)
        {
         // Salvar trade no Logger (apenas o deal final)
         m_logger.SaveTrade(lastPositionTicket, finalDealProfit);

         // Atualizar estatísticas — totalPositionProfit classifica win/loss
         // (soma parciais + final); m_dailyProfit acumula só finalDealProfit.
         m_logger.UpdateStats(finalDealProfit, totalPositionProfit);

         // Registrar no Blockers — totalPositionProfit determina win/loss
         bool isWin = (totalPositionProfit > 0);
         m_blockers.UpdateAfterTrade(isWin, finalDealProfit);

         m_logger.Log(LOG_TRADE, THROTTLE_NONE, "CLOSE",
                      "📊 Posição #" + IntegerToString(lastPositionTicket) +
                      " fechada | P/L final: $" + DoubleToString(finalDealProfit, 2) +
                      " | Total posição: $" + DoubleToString(totalPositionProfit, 2));

         // Gerar relatório TXT atualizado após cada trade
         m_logger.SaveDailyReport();
         m_logger.Log(LOG_TRADE, THROTTLE_NONE, "REPORT", "📄 Relatório diário atualizado");
        }
     }

// Remover do TradeManager
   m_tradeManager.UnregisterPosition(lastPositionTicket);

// Bloquear re-entrada no mesmo candle ao fechar posição (exceto no modo VM)
   if(lockTradeCandle)
     {
      lastTradeBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "RESET",
                   "🔄 Controle de candle atualizado - aguardando próximo candle para novo trade");
     }

   return true;
  }
//+------------------------------------------------------------------+
