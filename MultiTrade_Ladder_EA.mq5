//+------------------------------------------------------------------+
//|                                        MultiTrade_Ladder_EA.mq5  |
//|                                        Copyright 2026, EP Filho  |
//|          EA Multi-Trades com TP Escalonado (Ladder / Escada)     |
//|                                 Versao 1.00 - Claude Code        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO"
#property version   "1.00"
#property description "EA que abre X trades com TPs escalonados em Y pontos."
#property description "Quando um TP e atingido, abre novo trade estendendo a escada."
#property description "Mantem sempre X trades abertos enquanto a escada estiver ativa."

#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//| ENUMERACOES                                                       |
//+------------------------------------------------------------------+
enum ENUM_LADDER_DIRECTION
  {
   LADDER_BUY  = 0,   // Compra (Buy)
   LADDER_SELL = 1    // Venda (Sell)
  };

//+------------------------------------------------------------------+
//| INPUTS                                                            |
//+------------------------------------------------------------------+
input group           "=== Configuracoes da Escada ==="
input ENUM_LADDER_DIRECTION inp_Direction   = LADDER_BUY;  // Direcao das operacoes
input int                   inp_NumTrades   = 3;           // Quantidade de trades simultaneos (X)
input int                   inp_TPPoints    = 100;         // Distancia do TP em pontos por nivel (Y)
input double                inp_LotSize     = 0.01;        // Volume por trade (lotes)
input int                   inp_SLPoints    = 0;           // Stop Loss em pontos (0 = sem SL)

input group           "=== Controle ==="
input bool                  inp_AutoRestart = false;       // Reiniciar escada se todas fecharem por SL
input int                   inp_MaxCycles   = 0;           // Maximo de ciclos (0 = ilimitado)
input bool                  inp_ShowLines   = true;        // Mostrar linhas de TP no grafico

input group           "=== Identificacao ==="
input long                  inp_MagicNumber = 77777;       // Magic Number
input int                   inp_Slippage    = 10;          // Slippage maximo (pontos)
input string                inp_Comment     = "Ladder";    // Comentario das ordens

//+------------------------------------------------------------------+
//| VARIAVEIS GLOBAIS                                                 |
//+------------------------------------------------------------------+
CTrade g_trade;

bool   g_ladderActive      = false;  // Escada ativa (ja abriu trades iniciais)
int    g_cycleCount         = 0;     // Contador de ciclos completados
int    g_prevPositionCount  = 0;     // Qtd de posicoes no tick anterior

// Rastreamento de tickets para detectar fechamentos
ulong  g_trackedTickets[];           // Tickets das posicoes rastreadas

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Validacoes de input
   if(inp_NumTrades < 1)
     {
      Print("ERRO: Numero de trades deve ser >= 1");
      return INIT_FAILED;
     }
   if(inp_TPPoints < 1)
     {
      Print("ERRO: TP em pontos deve ser >= 1");
      return INIT_FAILED;
     }
   if(inp_LotSize <= 0)
     {
      Print("ERRO: Volume invalido");
      return INIT_FAILED;
     }

//--- Verificar modo Hedging
   ENUM_ACCOUNT_MARGIN_MODE marginMode =
      (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   if(marginMode != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      Print("AVISO: Esta conta nao e HEDGING. O EA requer modo Hedging para multiplas posicoes.");
      Print("       Modo atual: ", EnumToString(marginMode));
     }

//--- Configurar CTrade
   g_trade.SetExpertMagicNumber(inp_MagicNumber);
   g_trade.SetDeviationInPoints(inp_Slippage);
   g_trade.SetTypeFilling(DetectTypeFilling(_Symbol));

//--- Detectar posicoes existentes (restart do terminal)
   int existing = CountMyPositions();
   if(existing > 0)
     {
      g_ladderActive = true;
      g_prevPositionCount = existing;
      SyncTrackedTickets();

      PrintFormat("Escada ressincronizada: %d posicoes encontradas", existing);
     }

//--- Banner de inicializacao
   Print("===========================================================");
   Print("   MULTI-TRADE LADDER EA v1.00 INICIALIZADO");
   PrintFormat("   Direcao: %s | Trades: %d | TP: %d pts | Lote: %.2f",
               (inp_Direction == LADDER_BUY) ? "COMPRA" : "VENDA",
               inp_NumTrades, inp_TPPoints, inp_LotSize);
   if(inp_SLPoints > 0)
      PrintFormat("   SL: %d pts", inp_SLPoints);
   else
      Print("   SL: Desativado");
   PrintFormat("   Magic: %I64d | Auto-restart: %s",
               inp_MagicNumber, inp_AutoRestart ? "SIM" : "NAO");
   Print("===========================================================");

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   RemoveAllChartLines();
   Comment("");
   Print("Multi-Trade Ladder EA finalizado. Motivo: ", reason);
  }

//+------------------------------------------------------------------+
//| OnTick - Loop principal                                           |
//+------------------------------------------------------------------+
void OnTick()
  {
   int currentCount = CountMyPositions();

//--- CASO 1: Escada nao ativa, sem posicoes -> abrir escada inicial
   if(!g_ladderActive && currentCount == 0)
     {
      // Verificar limite de ciclos
      if(inp_MaxCycles > 0 && g_cycleCount >= inp_MaxCycles)
        {
         UpdateChartInfo(currentCount, "Limite de ciclos atingido");
         return;
        }

      if(OpenInitialLadder())
        {
         g_ladderActive = true;
         g_cycleCount++;
         g_prevPositionCount = CountMyPositions();
         SyncTrackedTickets();
        }

      UpdateChartInfo(CountMyPositions(), "Escada aberta");
      return;
     }

//--- CASO 2: Escada nao ativa, mas ha posicoes existentes (restart)
   if(!g_ladderActive && currentCount > 0)
     {
      g_ladderActive = true;
      g_prevPositionCount = currentCount;
      SyncTrackedTickets();
      UpdateChartInfo(currentCount, "Escada resumida");
      return;
     }

//--- CASO 3: Escada ativa, todas as posicoes fecharam
   if(g_ladderActive && currentCount == 0)
     {
      g_ladderActive = false;
      RemoveAllChartLines();
      ArrayResize(g_trackedTickets, 0);

      Print("============================================");
      Print("   TODAS AS POSICOES FECHADAS!");
      Print("============================================");

      if(inp_AutoRestart)
        {
         if(inp_MaxCycles > 0 && g_cycleCount >= inp_MaxCycles)
           {
            Print("Limite de ciclos atingido: ", g_cycleCount);
            UpdateChartInfo(0, "Ciclos esgotados");
           }
         else
           {
            Print("Auto-restart: Nova escada sera aberta...");
            UpdateChartInfo(0, "Reiniciando...");
            // Escada sera reaberta no proximo tick (CASO 1)
           }
        }
      else
        {
         Print("Auto-restart desativado. EA aguardando.");
         UpdateChartInfo(0, "Parado - Todas fechadas");
        }

      g_prevPositionCount = 0;
      return;
     }

//--- CASO 4: Escada ativa, algum(ns) trade(s) fechou(aram)
   if(g_ladderActive && currentCount < g_prevPositionCount && currentCount > 0)
     {
      int closed = g_prevPositionCount - currentCount;

      // Detectar quais tickets fecharam
      DetectClosedPositions();

      // Quantos faltam para chegar a X
      int toOpen = inp_NumTrades - currentCount;
      if(toOpen > 0)
        {
         PrintFormat("Detectado %d fechamento(s). Abrindo %d reposicao(oes)...",
                     closed, toOpen);

         int opened = 0;
         for(int i = 0; i < toOpen; i++)
           {
            if(OpenReplacementTrade())
               opened++;
            else
               break;
           }

         PrintFormat("Reposicoes abertas: %d/%d", opened, toOpen);
        }

      SyncTrackedTickets();
     }

//--- Atualizar contagem e info do grafico
   g_prevPositionCount = CountMyPositions();
   UpdateChartInfo(g_prevPositionCount, g_ladderActive ? "Ativa" : "Inativa");

//--- Atualizar linhas de TP no grafico
   if(inp_ShowLines)
      UpdateTPLines();
  }

//+------------------------------------------------------------------+
//| Abrir escada inicial - X trades com TPs escalonados               |
//+------------------------------------------------------------------+
bool OpenInitialLadder()
  {
   double price;
   if(inp_Direction == LADDER_BUY)
      price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   else
      price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(price <= 0)
     {
      Print("ERRO: Preco invalido para abertura da escada");
      return false;
     }

//--- Calcular SL (mesmo para todos os trades iniciais)
   double sl = 0;
   if(inp_SLPoints > 0)
     {
      if(inp_Direction == LADDER_BUY)
         sl = NormalizeDouble(price - inp_SLPoints * _Point, _Digits);
      else
         sl = NormalizeDouble(price + inp_SLPoints * _Point, _Digits);
     }

   Print("===========================================================");
   PrintFormat("ABRINDO ESCADA INICIAL: %d trades @ %s",
               inp_NumTrades, DoubleToString(price, _Digits));

   int opened = 0;

   for(int i = 1; i <= inp_NumTrades; i++)
     {
      //--- Calcular TP escalonado: nivel i = i * Y pontos
      double tp;
      if(inp_Direction == LADDER_BUY)
         tp = NormalizeDouble(price + i * inp_TPPoints * _Point, _Digits);
      else
         tp = NormalizeDouble(price - i * inp_TPPoints * _Point, _Digits);

      //--- Comentario com numero do nivel
      string comment = StringFormat("%s_L%d", inp_Comment, i);

      //--- Enviar ordem
      bool success = false;
      if(inp_Direction == LADDER_BUY)
         success = g_trade.Buy(inp_LotSize, _Symbol, price, sl, tp, comment);
      else
         success = g_trade.Sell(inp_LotSize, _Symbol, price, sl, tp, comment);

      if(success && g_trade.ResultRetcode() == TRADE_RETCODE_DONE)
        {
         opened++;
         PrintFormat("   Trade %d/%d: %s @ %s | TP: %s (%d pts) | SL: %s",
                     i, inp_NumTrades,
                     (inp_Direction == LADDER_BUY) ? "BUY" : "SELL",
                     DoubleToString(price, _Digits),
                     DoubleToString(tp, _Digits),
                     i * inp_TPPoints,
                     (sl > 0) ? DoubleToString(sl, _Digits) : "---");
        }
      else
        {
         PrintFormat("   ERRO trade %d/%d | Retcode: %d | %s",
                     i, inp_NumTrades,
                     g_trade.ResultRetcode(),
                     g_trade.ResultComment());
        }
     }

   PrintFormat("Escada aberta: %d/%d trades com sucesso", opened, inp_NumTrades);
   Print("===========================================================");

   return (opened > 0);
  }

//+------------------------------------------------------------------+
//| Abrir trade de reposicao (estende a escada)                       |
//+------------------------------------------------------------------+
bool OpenReplacementTrade()
  {
//--- Preco atual
   double price;
   if(inp_Direction == LADDER_BUY)
      price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   else
      price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(price <= 0)
     {
      Print("ERRO: Preco invalido para reposicao");
      return false;
     }

//--- Encontrar o TP mais distante entre as posicoes abertas
   double furthestTP = GetFurthestTP();
   if(furthestTP <= 0)
     {
      Print("ERRO: Nao foi possivel determinar o TP mais distante");
      return false;
     }

//--- Novo TP = TP mais distante + Y pontos
   double tp;
   if(inp_Direction == LADDER_BUY)
      tp = NormalizeDouble(furthestTP + inp_TPPoints * _Point, _Digits);
   else
      tp = NormalizeDouble(furthestTP - inp_TPPoints * _Point, _Digits);

//--- Validar TP (deve estar alem do preco atual)
   if(inp_Direction == LADDER_BUY && tp <= price)
     {
      PrintFormat("AVISO: TP reposicao (%.5f) <= preco atual (%.5f). Ajustando...", tp, price);
      tp = NormalizeDouble(price + inp_TPPoints * _Point, _Digits);
     }
   if(inp_Direction == LADDER_SELL && tp >= price)
     {
      PrintFormat("AVISO: TP reposicao (%.5f) >= preco atual (%.5f). Ajustando...", tp, price);
      tp = NormalizeDouble(price - inp_TPPoints * _Point, _Digits);
     }

//--- SL individual baseado no preco de entrada
   double sl = 0;
   if(inp_SLPoints > 0)
     {
      if(inp_Direction == LADDER_BUY)
         sl = NormalizeDouble(price - inp_SLPoints * _Point, _Digits);
      else
         sl = NormalizeDouble(price + inp_SLPoints * _Point, _Digits);
     }

//--- Enviar ordem
   string comment = StringFormat("%s_R", inp_Comment);
   bool success = false;

   if(inp_Direction == LADDER_BUY)
      success = g_trade.Buy(inp_LotSize, _Symbol, price, sl, tp, comment);
   else
      success = g_trade.Sell(inp_LotSize, _Symbol, price, sl, tp, comment);

   if(success && g_trade.ResultRetcode() == TRADE_RETCODE_DONE)
     {
      PrintFormat("REPOSICAO: %s @ %s | TP: %s | SL: %s | Distante+Y",
                  (inp_Direction == LADDER_BUY) ? "BUY" : "SELL",
                  DoubleToString(g_trade.ResultPrice(), _Digits),
                  DoubleToString(tp, _Digits),
                  (sl > 0) ? DoubleToString(sl, _Digits) : "---");
      return true;
     }

   PrintFormat("ERRO reposicao | Retcode: %d | %s",
               g_trade.ResultRetcode(), g_trade.ResultComment());
   return false;
  }

//+------------------------------------------------------------------+
//| Contar posicoes deste EA no simbolo atual                         |
//+------------------------------------------------------------------+
int CountMyPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == inp_MagicNumber)
        {
         count++;
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Encontrar o TP mais distante entre posicoes abertas               |
//| Para BUY: retorna o MAIOR TP                                     |
//| Para SELL: retorna o MENOR TP                                    |
//+------------------------------------------------------------------+
double GetFurthestTP()
  {
   double furthest = 0;
   bool   found    = false;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != inp_MagicNumber)
         continue;

      double tp = PositionGetDouble(POSITION_TP);
      if(tp <= 0)
         continue;

      if(!found)
        {
         furthest = tp;
         found = true;
        }
      else
        {
         if(inp_Direction == LADDER_BUY && tp > furthest)
            furthest = tp;
         else
            if(inp_Direction == LADDER_SELL && tp < furthest)
               furthest = tp;
        }
     }

   return furthest;
  }

//+------------------------------------------------------------------+
//| Encontrar o TP mais proximo (para info)                           |
//+------------------------------------------------------------------+
double GetNearestTP()
  {
   double nearest = 0;
   bool   found   = false;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != inp_MagicNumber)
         continue;

      double tp = PositionGetDouble(POSITION_TP);
      if(tp <= 0)
         continue;

      if(!found)
        {
         nearest = tp;
         found = true;
        }
      else
        {
         if(inp_Direction == LADDER_BUY && tp < nearest)
            nearest = tp;
         else
            if(inp_Direction == LADDER_SELL && tp > nearest)
               nearest = tp;
        }
     }

   return nearest;
  }

//+------------------------------------------------------------------+
//| Calcular lucro total flutuante das posicoes do EA                 |
//+------------------------------------------------------------------+
double GetTotalFloatingProfit()
  {
   double total = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != inp_MagicNumber)
         continue;

      total += PositionGetDouble(POSITION_PROFIT);
     }
   return total;
  }

//+------------------------------------------------------------------+
//| Sincronizar array de tickets rastreados                           |
//+------------------------------------------------------------------+
void SyncTrackedTickets()
  {
   int count = CountMyPositions();
   ArrayResize(g_trackedTickets, 0);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != inp_MagicNumber)
         continue;

      ulong ticket = PositionGetTicket(i);
      int size = ArraySize(g_trackedTickets);
      ArrayResize(g_trackedTickets, size + 1);
      g_trackedTickets[size] = ticket;
     }
  }

//+------------------------------------------------------------------+
//| Detectar posicoes que fecharam (para logging)                     |
//+------------------------------------------------------------------+
void DetectClosedPositions()
  {
//--- Obter tickets atuais
   ulong currentTickets[];
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != inp_MagicNumber)
         continue;

      ulong ticket = PositionGetTicket(i);
      int size = ArraySize(currentTickets);
      ArrayResize(currentTickets, size + 1);
      currentTickets[size] = ticket;
     }

//--- Comparar com tickets rastreados para encontrar os que fecharam
   for(int i = 0; i < ArraySize(g_trackedTickets); i++)
     {
      bool stillOpen = false;
      for(int j = 0; j < ArraySize(currentTickets); j++)
        {
         if(g_trackedTickets[i] == currentTickets[j])
           {
            stillOpen = true;
            break;
           }
        }

      if(!stillOpen)
        {
         ulong closedTicket = g_trackedTickets[i];

         //--- Buscar info no historico
         if(HistorySelectByPosition(closedTicket))
           {
            double profit = 0;
            for(int d = HistoryDealsTotal() - 1; d >= 0; d--)
              {
               ulong dealTicket = HistoryDealGetTicket(d);
               if(HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) == closedTicket)
                 {
                  long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
                  if(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_OUT_BY)
                    {
                     profit += HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                    }
                 }
              }

            PrintFormat("Posicao #%I64u FECHADA | Lucro: $%.2f", closedTicket, profit);
           }
         else
           {
            PrintFormat("Posicao #%I64u FECHADA (sem detalhes no historico)", closedTicket);
           }

         //--- Remover linha do grafico
         if(inp_ShowLines)
           {
            string lineName = StringFormat("Ladder_TP_%I64u", closedTicket);
            ObjectDelete(0, lineName);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Atualizar informacoes no grafico (Comment)                        |
//+------------------------------------------------------------------+
void UpdateChartInfo(int posCount, string status)
  {
   double nearestTP  = GetNearestTP();
   double furthestTP = GetFurthestTP();
   double floatPL    = GetTotalFloatingProfit();
   double currentPrice = (inp_Direction == LADDER_BUY)
                         ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                         : SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   string info = "";
   info += "==================================\n";
   info += "  MULTI-TRADE LADDER EA v1.00\n";
   info += "==================================\n";
   info += StringFormat("  Direcao:     %s\n", (inp_Direction == LADDER_BUY) ? "COMPRA" : "VENDA");
   info += StringFormat("  Status:      %s\n", status);
   info += StringFormat("  Posicoes:    %d / %d\n", posCount, inp_NumTrades);
   info += StringFormat("  Ciclo:       %d", g_cycleCount);
   if(inp_MaxCycles > 0)
      info += StringFormat(" / %d", inp_MaxCycles);
   info += "\n";
   info += "----------------------------------\n";
   info += StringFormat("  Preco atual: %s\n", DoubleToString(currentPrice, _Digits));

   if(posCount > 0)
     {
      info += StringFormat("  TP proximo:  %s\n", (nearestTP > 0) ? DoubleToString(nearestTP, _Digits) : "---");
      info += StringFormat("  TP distante: %s\n", (furthestTP > 0) ? DoubleToString(furthestTP, _Digits) : "---");

      //--- Distancia ate o TP mais proximo
      if(nearestTP > 0 && currentPrice > 0)
        {
         double distPoints;
         if(inp_Direction == LADDER_BUY)
            distPoints = (nearestTP - currentPrice) / _Point;
         else
            distPoints = (currentPrice - nearestTP) / _Point;
         info += StringFormat("  Dist prox:   %.0f pts\n", distPoints);
        }
     }

   info += StringFormat("  P/L flutuante: $%.2f\n", floatPL);
   info += "==================================";

   Comment(info);
  }

//+------------------------------------------------------------------+
//| Atualizar linhas de TP no grafico                                 |
//+------------------------------------------------------------------+
void UpdateTPLines()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != inp_MagicNumber)
         continue;

      ulong  ticket = PositionGetTicket(i);
      double tp     = PositionGetDouble(POSITION_TP);

      if(tp <= 0)
         continue;

      string lineName = StringFormat("Ladder_TP_%I64u", ticket);

      if(ObjectFind(0, lineName) < 0)
        {
         ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, tp);
         ObjectSetInteger(0, lineName, OBJPROP_COLOR,
                          (inp_Direction == LADDER_BUY) ? clrDodgerBlue : clrOrangeRed);
         ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, lineName, OBJPROP_BACK, true);
         ObjectSetString(0, lineName, OBJPROP_TOOLTIP,
                         StringFormat("Ladder TP #%I64u: %s", ticket, DoubleToString(tp, _Digits)));
        }
      else
        {
         //--- Atualizar preco caso tenha mudado
         ObjectSetDouble(0, lineName, OBJPROP_PRICE, tp);
        }
     }
  }

//+------------------------------------------------------------------+
//| Remover todas as linhas de TP do grafico                          |
//+------------------------------------------------------------------+
void RemoveAllChartLines()
  {
   int totalObjects = ObjectsTotal(0, 0, OBJ_HLINE);
   for(int i = totalObjects - 1; i >= 0; i--)
     {
      string name = ObjectName(0, i, 0, OBJ_HLINE);
      if(StringFind(name, "Ladder_TP_") == 0)
        {
         ObjectDelete(0, name);
        }
     }
  }

//+------------------------------------------------------------------+
//| Detectar tipo de preenchimento suportado pelo simbolo             |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING DetectTypeFilling(string symbol)
  {
   uint filling = (uint)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);

   if((filling & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;
   else
      if((filling & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC)
         return ORDER_FILLING_IOC;
      else
         return ORDER_FILLING_RETURN;
  }
//+------------------------------------------------------------------+
