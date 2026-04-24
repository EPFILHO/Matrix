//+------------------------------------------------------------------+
//|                                                   PanelUtils.mqh |
//|                                         Copyright 2026, EP Filho |
//|          Funções utilitárias livres para sub-páginas do painel    |
//|                     Versão 1.03 - Claude Parte 030 (Claude Code) |
//|          + free-function Enable/Disable helpers para painéis      |
//+------------------------------------------------------------------+
// NOTA: Incluído por Panel.mqh APÓS #include das dependências de
//       Strategy/Filters e <Controls\Button.mqh>.
//       NÃO incluir diretamente — os tipos ENUM_RSI_* devem estar
//       definidos antes deste arquivo.
//
// CHANGELOG v1.02 (Parte 029):
// * TFName(): adicionados todos os timeframes MQL5 (M2-M20, H2-H12)
// * CycleTF(): adicionados todos os timeframes MQL5
//
// CHANGELOG v1.03 (Parte 030):
// * CLR_FIELD_ERROR: constante para highlight de campos inválidos
// * MarkFieldError(): pinta fundo do CEdit vermelho claro
// * ClearFieldError(): restaura fundo branco (se campo habilitado)
// * CalcMaxPoints(): calcula limite max de pontos baseado no ativo
// * CalcMinSLTP(): calcula SL/TP mínimo do broker (STOPS_LEVEL)
// * CalcSymbolLotLimits(): obtém min/max/step de lote do ativo
//+------------------------------------------------------------------+

//── Timeframe ──────────────────────────────────────────────────────
string TFName(ENUM_TIMEFRAMES tf)
  {
   switch(tf)
     {
      case PERIOD_M1:      return "M1";
      case PERIOD_M2:      return "M2";
      case PERIOD_M3:      return "M3";
      case PERIOD_M4:      return "M4";
      case PERIOD_M5:      return "M5";
      case PERIOD_M6:      return "M6";
      case PERIOD_M10:     return "M10";
      case PERIOD_M12:     return "M12";
      case PERIOD_M15:     return "M15";
      case PERIOD_M20:     return "M20";
      case PERIOD_M30:     return "M30";
      case PERIOD_H1:      return "H1";
      case PERIOD_H2:      return "H2";
      case PERIOD_H3:      return "H3";
      case PERIOD_H4:      return "H4";
      case PERIOD_H6:      return "H6";
      case PERIOD_H8:      return "H8";
      case PERIOD_H12:     return "H12";
      case PERIOD_D1:      return "D1";
      case PERIOD_W1:      return "W1";
      case PERIOD_MN1:     return "MN1";
      default:             return "??";
     }
  }

ENUM_TIMEFRAMES CycleTF(ENUM_TIMEFRAMES tf)
  {
   static const ENUM_TIMEFRAMES tfs[] =
     {PERIOD_M1, PERIOD_M2, PERIOD_M3, PERIOD_M4,
      PERIOD_M5, PERIOD_M6, PERIOD_M10, PERIOD_M12, PERIOD_M15,
      PERIOD_M20, PERIOD_M30, PERIOD_H1, PERIOD_H2, PERIOD_H3,
      PERIOD_H4, PERIOD_H6, PERIOD_H8, PERIOD_H12, PERIOD_D1,
      PERIOD_W1, PERIOD_MN1};
   int count = ArraySize(tfs);
   for(int i = 0; i < count; i++)
      if(tfs[i] == tf) return tfs[(i + 1) % count];
   return PERIOD_M1;
  }

//── MA Method ──────────────────────────────────────────────────────
int MAMethodToIndex(ENUM_MA_METHOD m)
  { return (m == MODE_SMA) ? 0 : (m == MODE_EMA) ? 1 : (m == MODE_SMMA) ? 2 : 3; }

ENUM_MA_METHOD IndexToMAMethod(int i)
  { return (i == 0) ? MODE_SMA : (i == 1) ? MODE_EMA : (i == 2) ? MODE_SMMA : MODE_LWMA; }

string MAMethodShortText(ENUM_MA_METHOD method)
  {
   switch(method)
     {
      case MODE_SMA:  return "SMA";
      case MODE_EMA:  return "EMA";
      case MODE_SMMA: return "SMMA";
      case MODE_LWMA: return "LWMA";
     }
   return "SMA";
  }

//── Applied Price ──────────────────────────────────────────────────
string AppliedPriceShortText(ENUM_APPLIED_PRICE price)
  {
   switch(price)
     {
      case PRICE_CLOSE:    return "CLOSE";
      case PRICE_OPEN:     return "OPEN";
      case PRICE_HIGH:     return "HIGH";
      case PRICE_LOW:      return "LOW";
      case PRICE_MEDIAN:   return "MEDIAN";
      case PRICE_TYPICAL:  return "TYPICAL";
      case PRICE_WEIGHTED: return "WGTD.";
     }
   return "CLOSE";
  }

ENUM_APPLIED_PRICE CycleAppliedPrice(ENUM_APPLIED_PRICE cur)
  {
   ENUM_APPLIED_PRICE seq[] = {PRICE_CLOSE, PRICE_OPEN, PRICE_HIGH,
                               PRICE_LOW,   PRICE_MEDIAN, PRICE_TYPICAL};
   int count = ArraySize(seq);
   for(int i = 0; i < count; i++)
      if(seq[i] == cur) return seq[(i + 1) % count];
   return PRICE_CLOSE;
  }

//── RSI Signal Mode ────────────────────────────────────────────────
int RSIModeToIndex(ENUM_RSI_SIGNAL_MODE m)
  { return (m == RSI_MODE_CROSSOVER) ? 0 : (m == RSI_MODE_ZONE) ? 1 : 2; }

ENUM_RSI_SIGNAL_MODE IndexToRSIMode(int i)
  { return (i == 0) ? RSI_MODE_CROSSOVER : (i == 1) ? RSI_MODE_ZONE : RSI_MODE_MIDDLE; }

string RSIModeDesc(ENUM_RSI_SIGNAL_MODE mode)
  {
   switch(mode)
     {
      case RSI_MODE_CROSSOVER: return "CROSS: sinal no cruzamento do nivel OS/OB";
      case RSI_MODE_ZONE:      return "ZONE: sinal enquanto RSI esta na zona OS/OB";
      case RSI_MODE_MIDDLE:    return "MEDIO: sinal no cruzamento da linha central (50)";
      default:                 return "";
     }
  }

//── RSI Filter Mode ────────────────────────────────────────────────
string RSIFiltModeText(ENUM_RSI_FILTER_MODE mode)
  {
   switch(mode)
     {
      case RSI_FILTER_ZONE:      return "ZONE";
      case RSI_FILTER_DIRECTION: return "DIR.";
      case RSI_FILTER_NEUTRAL:   return "NEUTRO";
     }
   return "?";
  }

//── Toggle button style ────────────────────────────────────────────
void ApplyToggleStyle(CButton &btn, bool enabled)
  {
   btn.Text(enabled ? "ON" : "OFF");
   btn.ColorBackground(enabled ? C'30,120,70' : C'160,40,40');
   btn.Color(clrWhite);
  }

//── Radio group selection ──────────────────────────────────────────
void SetRadioSel(CButton &btns[], int count, int selected)
  {
   for(int i = 0; i < count; i++)
     {
      btns[i].Pressed(false);
      if(i == selected)
        { btns[i].ColorBackground(CLR_RADIO_ACTIVE);   btns[i].Color(CLR_RADIO_TXT_ACT); }
      else
        { btns[i].ColorBackground(CLR_RADIO_INACTIVE); btns[i].Color(CLR_RADIO_TXT_INACT); }
     }
  }

//── Field validation constant (Parte 030) ────────────────────────
#define CLR_FIELD_ERROR   C'255,210,210'   // rosa claro para campo inválido

//── Enable/Disable helpers (for panels) ──────────────────────────
void SetEditEnabled(CLabel &lbl, CEdit &inp, bool enable)
  {
   if(enable)
     {
      lbl.Color(CLR_LABEL);
      inp.ReadOnly(false);
      if(inp.ColorBackground() != CLR_FIELD_ERROR)
         inp.ColorBackground(clrWhite);
      inp.Color(clrBlack);
     }
   else
     {
      lbl.Color(C'180,180,180');
      inp.ReadOnly(true);
      inp.ColorBackground(C'220,220,220');
      inp.Color(C'160,160,160');
     }
  }

void SetButtonEnabled(CLabel &lbl, CButton &btn, bool enable)
  {
   if(enable)
     {
      lbl.Color(CLR_LABEL);
     }
   else
     {
      lbl.Color(C'180,180,180');
      btn.ColorBackground(C'160,160,160');
      btn.Color(C'200,200,200');
     }
  }

void SetRadioGroupEnabled(CLabel &lbl, CButton &btns[], int count, bool enable)
  {
   if(enable)
      lbl.Color(CLR_LABEL);
   else
     {
      lbl.Color(C'180,180,180');
      for(int i = 0; i < count; i++)
        {
         btns[i].ColorBackground(C'160,160,160');
         btns[i].Color(C'200,200,200');
        }
     }
  }

//── Field validation helpers (Parte 030) ──────────────────────────
void MarkFieldError(CEdit &inp)
  {
   inp.ColorBackground(CLR_FIELD_ERROR);
  }

void ClearFieldError(CEdit &inp)
  {
   if(!inp.ReadOnly())
      inp.ColorBackground(clrWhite);
  }

//── Symbol-based dynamic limits (Parte 030) ───────────────────────
// Calcula o máximo de pontos baseado em percentual do preço do ativo
// pctOfPrice: 0.25 = 25%, 0.50 = 50%, etc.
// fallback: valor retornado se não conseguir ler preço/point
int CalcMaxPoints(double pctOfPrice, int fallback)
  {
   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(bid <= 0 || point <= 0)
      return fallback;
   return (int)(bid * pctOfPrice / point);
  }

// Retorna o SL/TP mínimo do broker (STOPS_LEVEL), mínimo 1
int CalcMinSLTP(void)
  {
   int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   return (stopsLevel > 0) ? stopsLevel : 1;
  }

// Obtém limites de lote do ativo (min, max, step)
void CalcSymbolLotLimits(double &lotMin, double &lotMax, double &lotStep)
  {
   lotMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   lotMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(lotMin  <= 0) lotMin  = 0.01;
   if(lotMax  <= 0) lotMax  = 1000.0;
   if(lotStep <= 0) lotStep = 0.01;
  }
//+------------------------------------------------------------------+
