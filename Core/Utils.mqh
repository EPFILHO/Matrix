//+------------------------------------------------------------------+
//|                                                      Utils.mqh   |
//|                                        Copyright 2026, EP Filho |
//|          Utilitarios globais reutilizaveis — EPBot Matrix        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "1.00"

#ifndef UTILS_MQH
#define UTILS_MQH

//+------------------------------------------------------------------+
//| GetTypeFilling                                                    |
//| Detecta o tipo de filling suportado pelo simbolo.                |
//| Retorna SYMBOL_FILLING_FOK, IOC ou RETURN conforme disponivel.   |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetTypeFilling(const string symbol)
  {
   long filling = 0;
   if(!SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE, filling))
      return ORDER_FILLING_FOK;

   if((filling & SYMBOL_FILLING_FOK) != 0)
      return ORDER_FILLING_FOK;
   if((filling & SYMBOL_FILLING_IOC) != 0)
      return ORDER_FILLING_IOC;

   return ORDER_FILLING_RETURN;
  }

#endif // UTILS_MQH
