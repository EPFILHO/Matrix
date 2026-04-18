//+------------------------------------------------------------------+
//|                                           ConfigPersistence.mqh  |
//|                                         Copyright 2026, EP Filho |
//|     Persistência de configurações GUI — EPBot Matrix              |
//|                     Versão 1.02 - Claude Parte 033 (Claude Code) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property version   "1.02"
#property strict

// ═══════════════════════════════════════════════════════════════
// CHANGELOG
// ═══════════════════════════════════════════════════════════════
// v1.02 (Parte 033) — Issue #28:
// - Removido campo tradeComment de SConfigData
// - WriteKV e ReadKV do TradeComment eliminados
// ═══════════════════════════════════════════════════════════════
// v1.01 (Parte 027):
// * Fix: SConfigData campos rsiOversold, rsiOverbought, rsiMidLevel,
//   trendMinDistance, rsiFiltOversold, rsiFiltOverbought alterados
//   de int para double (evita truncamento de valores fracionários)
// * Fix: Save/Load usa DoubleToString/StringToDouble para esses campos
//
// v1.00 (Parte 027):
// + SConfigData: struct com TODOS os parâmetros configuráveis via GUI
// + CConfigPersistence: Save/Load/Delete/Exists/GetLastModified
//   - Formato: key=value (legível e forward-compatible)
//   - Escrita atômica via .tmp + rename
//   - Guard de backtest (MQL_TESTER)
//   - Arquivo: MQL5/Files/Matrix_{symbol}_{magic}.cfg
// ═══════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Includes necessários para enums                                   |
//+------------------------------------------------------------------+
#include "Blockers.mqh"
#include "RiskManager.mqh"
#include "../Strategy/Strategies/MACrossStrategy.mqh"
#include "../Strategy/Strategies/RSIStrategy.mqh"
#include "../Strategy/Strategies/BollingerBandsStrategy.mqh"
#include "../Strategy/Filters/TrendFilter.mqh"
#include "../Strategy/Filters/RSIFilter.mqh"
#include "../Strategy/Filters/BollingerBandsFilter.mqh"

//+------------------------------------------------------------------+
//| Struct com TODOS os parâmetros configuráveis via GUI               |
//+------------------------------------------------------------------+
struct SConfigData
  {
   int               version;           // Versão do formato (para compatibilidade futura)
   datetime          lastModified;      // Timestamp da última gravação

   // ── RISCO ──
   double            lotSize;
   ENUM_SL_TYPE      slType;
   int               fixedSL;
   double            slATRMultiplier;
   double            rangeMultiplier;
   bool              slCompensateSpread;
   ENUM_TP_TYPE      tpType;
   int               fixedTP;
   double            tpATRMultiplier;
   bool              tpCompensateSpread;
   int               atrPeriod;
   int               rangePeriod;

   // ── RISCO 2: Trailing ──
   bool              trailOn;
   int               trailStartFixed;
   int               trailStepFixed;
   double            trailStartATR;
   double            trailStepATR;
   bool              trailCompensateSpread;

   // ── RISCO 2: Breakeven ──
   bool              beOn;
   int               beActivationFixed;
   int               beOffsetFixed;
   double            beActivationATR;
   double            beOffsetATR;

   // ── RISCO 2: Partial TP ──
   bool              partialTP;
   double            tp1Percent;
   int               tp1Distance;
   double            tp2Percent;
   int               tp2Distance;

   // ── RISCO 2: Daily Limits ──
   bool              dailyLimitsOn;
   int               maxDailyTrades;
   double            maxDailyLoss;
   double            maxDailyGain;
   ENUM_PROFIT_TARGET_ACTION profitTargetAction;

   // ── RISCO 2: Drawdown ──
   bool              ddOn;
   double            ddValue;
   ENUM_DRAWDOWN_TYPE ddType;
   ENUM_DRAWDOWN_PEAK_MODE ddPeakMode;

   // ── BLOQUEIOS: Spread/Direção ──
   int               maxSpread;
   ENUM_TRADE_DIRECTION tradeDirection;

   // ── BLOQUEIOS: Streak ──
   bool              lossStreakOn;
   int               maxLossStreak;
   ENUM_STREAK_ACTION lossStreakAction;
   int               lossPauseMinutes;
   bool              winStreakOn;
   int               maxWinStreak;
   ENUM_STREAK_ACTION winStreakAction;
   int               winPauseMinutes;

   // ── BLOQUEIOS: Filtro de Horário ──
   bool              timeFilterOn;
   int               tfStartH;
   int               tfStartM;
   int               tfEndH;
   int               tfEndM;
   bool              tfCloseOnEnd;

   // ── BLOQUEIOS: Proteção Sessão ──
   bool              cbsOn;
   int               cbsMinutes;

   // ── BLOQUEIOS: News ──
   bool              newsOn1;
   int               news1SH, news1SM, news1EH, news1EM;
   bool              newsOn2;
   int               news2SH, news2SM, news2EH, news2EM;
   bool              newsOn3;
   int               news3SH, news3SM, news3EH, news3EM;

   // ── OUTROS ──
   int               magicNumber;         // Hot-reload magic
   int               slippage;
   ENUM_CONFLICT_RESOLUTION conflictMode;
   bool              showDebug;
   int               debugCooldown;

   // ── RISCO: Tipos Trailing/BE ──
   ENUM_TRAILING_TYPE trailingType;       // TRAILING_FIXED ou TRAILING_ATR
   ENUM_BE_TYPE       beType;             // BE_FIXED ou BE_ATR

   // ── MA CROSS STRATEGY ──
   bool              maEnabled;
   int               maPriority;
   int               maFastPeriod;
   ENUM_MA_METHOD    maFastMethod;
   ENUM_APPLIED_PRICE maFastApplied;
   ENUM_TIMEFRAMES   maFastTF;
   int               maSlowPeriod;
   ENUM_MA_METHOD    maSlowMethod;
   ENUM_APPLIED_PRICE maSlowApplied;
   ENUM_TIMEFRAMES   maSlowTF;
   int               maMinDistance;
   ENUM_ENTRY_MODE   maEntryMode;
   ENUM_EXIT_MODE    maExitMode;

   // ── RSI STRATEGY ──
   bool              rsiEnabled;
   int               rsiPriority;
   int               rsiPeriod;
   ENUM_APPLIED_PRICE rsiApplied;
   ENUM_TIMEFRAMES   rsiTF;
   ENUM_RSI_SIGNAL_MODE rsiMode;
   double            rsiOversold;
   double            rsiOverbought;
   double            rsiMidLevel;

   // ── BB STRATEGY ──
   bool              bbEnabled;
   int               bbPriority;
   int               bbPeriod;
   double            bbDeviation;
   ENUM_APPLIED_PRICE bbApplied;
   ENUM_TIMEFRAMES   bbTF;
   ENUM_BB_SIGNAL_MODE bbMode;
   ENUM_ENTRY_MODE   bbEntryMode;
   ENUM_EXIT_MODE    bbExitMode;

   // ── TREND FILTER ──
   bool              trendEnabled;
   int               trendPeriod;
   ENUM_MA_METHOD    trendMethod;
   ENUM_APPLIED_PRICE trendApplied;
   ENUM_TIMEFRAMES   trendTF;
   double            trendMinDistance;

   // ── RSI FILTER ──
   bool              rsiFiltEnabled;
   int               rsiFiltPeriod;
   ENUM_APPLIED_PRICE rsiFiltApplied;
   ENUM_TIMEFRAMES   rsiFiltTF;
   ENUM_RSI_FILTER_MODE rsiFiltMode;
   double            rsiFiltOversold;
   double            rsiFiltOverbought;
   double            rsiFiltLowerNeutral;
   double            rsiFiltUpperNeutral;
   int               rsiFiltShift;

   // ── BB FILTER ──
   bool              bbFiltEnabled;
   int               bbFiltPeriod;
   double            bbFiltDeviation;
   ENUM_APPLIED_PRICE bbFiltApplied;
   ENUM_TIMEFRAMES   bbFiltTF;
   ENUM_BB_SQUEEZE_METRIC bbFiltMetric;
   double            bbFiltThreshold;
   int               bbFiltPercPeriod;
  };

//+------------------------------------------------------------------+
//| Classe de persistência — funções estáticas                        |
//+------------------------------------------------------------------+
class CConfigPersistence
  {
public:
   static string     GetFileName(string symbol, int magic);
   static bool       Save(string symbol, int magic, const SConfigData &data);
   static bool       Load(string symbol, int magic, SConfigData &data);
   static bool       Exists(string symbol, int magic);
   static void       Delete(string symbol, int magic);
   static string     GetLastModifiedStr(string symbol, int magic);

private:
   static void       WriteKV(int handle, string key, string value);
   static string     ReadValue(string line);
   static string     ReadKey(string line);
  };

//+------------------------------------------------------------------+
//| GetFileName — retorna nome do arquivo de config                   |
//+------------------------------------------------------------------+
string CConfigPersistence::GetFileName(string symbol, int magic)
  {
   return "Matrix_" + symbol + "_" + IntegerToString(magic) + ".cfg";
  }

//+------------------------------------------------------------------+
//| Exists — verifica se o arquivo de config existe                   |
//+------------------------------------------------------------------+
bool CConfigPersistence::Exists(string symbol, int magic)
  {
   if(MQLInfoInteger(MQL_TESTER)) return false;
   string fn = GetFileName(symbol, magic);
   int h = FileOpen(fn, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) return false;
   FileClose(h);
   return true;
  }

//+------------------------------------------------------------------+
//| Delete — remove o arquivo de config                               |
//+------------------------------------------------------------------+
void CConfigPersistence::Delete(string symbol, int magic)
  {
   if(MQLInfoInteger(MQL_TESTER)) return;
   string fn = GetFileName(symbol, magic);
   FileDelete(fn);
  }

//+------------------------------------------------------------------+
//| GetLastModifiedStr — retorna data da última modificação           |
//+------------------------------------------------------------------+
string CConfigPersistence::GetLastModifiedStr(string symbol, int magic)
  {
   if(MQLInfoInteger(MQL_TESTER)) return "";
   SConfigData data;
   if(!Load(symbol, magic, data)) return "";
   return TimeToString(data.lastModified, TIME_DATE | TIME_MINUTES);
  }

//+------------------------------------------------------------------+
//| WriteKV — escreve key=value no arquivo                            |
//+------------------------------------------------------------------+
void CConfigPersistence::WriteKV(int handle, string key, string value)
  {
   FileWriteString(handle, key + "=" + value + "\n");
  }

//+------------------------------------------------------------------+
//| ReadKey — extrai a chave de uma linha "key=value"                 |
//+------------------------------------------------------------------+
string CConfigPersistence::ReadKey(string line)
  {
   int pos = StringFind(line, "=");
   if(pos < 0) return "";
   return StringSubstr(line, 0, pos);
  }

//+------------------------------------------------------------------+
//| ReadValue — extrai o valor de uma linha "key=value"               |
//+------------------------------------------------------------------+
string CConfigPersistence::ReadValue(string line)
  {
   int pos = StringFind(line, "=");
   if(pos < 0) return "";
   return StringSubstr(line, pos + 1);
  }

//+------------------------------------------------------------------+
//| Save — grava todas as configs em arquivo (escrita atômica)        |
//+------------------------------------------------------------------+
bool CConfigPersistence::Save(string symbol, int magic, const SConfigData &data)
  {
   if(MQLInfoInteger(MQL_TESTER)) return false;

   string fn = GetFileName(symbol, magic);
   string fnTmp = fn + ".tmp";

// Escrever no .tmp primeiro (escrita atômica)
   int h = FileOpen(fnTmp, FILE_WRITE | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE)
     {
      Print("ConfigPersistence: Falha ao abrir " + fnTmp + " para escrita");
      return false;
     }

// ── Header ──
   FileWriteString(h, "# Matrix EA Config - NAO EDITAR MANUALMENTE\n");
   WriteKV(h, "ConfigVersion", "1");
   WriteKV(h, "LastModified", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));

// ── RISCO ──
   FileWriteString(h, "# RISCO\n");
   WriteKV(h, "LotSize",            DoubleToString(data.lotSize, 2));
   WriteKV(h, "SLType",             IntegerToString((int)data.slType));
   WriteKV(h, "FixedSL",            IntegerToString(data.fixedSL));
   WriteKV(h, "SLATRMultiplier",    DoubleToString(data.slATRMultiplier, 2));
   WriteKV(h, "RangeMultiplier",    DoubleToString(data.rangeMultiplier, 2));
   WriteKV(h, "SLCompensateSpread", IntegerToString(data.slCompensateSpread));
   WriteKV(h, "TPType",             IntegerToString((int)data.tpType));
   WriteKV(h, "FixedTP",            IntegerToString(data.fixedTP));
   WriteKV(h, "TPATRMultiplier",    DoubleToString(data.tpATRMultiplier, 2));
   WriteKV(h, "TPCompensateSpread", IntegerToString(data.tpCompensateSpread));
   WriteKV(h, "ATRPeriod",          IntegerToString(data.atrPeriod));
   WriteKV(h, "RangePeriod",        IntegerToString(data.rangePeriod));

// ── Trailing ──
   FileWriteString(h, "# TRAILING\n");
   WriteKV(h, "TrailOn",            IntegerToString(data.trailOn));
   WriteKV(h, "TrailStartFixed",    IntegerToString(data.trailStartFixed));
   WriteKV(h, "TrailStepFixed",     IntegerToString(data.trailStepFixed));
   WriteKV(h, "TrailStartATR",      DoubleToString(data.trailStartATR, 2));
   WriteKV(h, "TrailStepATR",       DoubleToString(data.trailStepATR, 2));
   WriteKV(h, "TrailCompSpread",    IntegerToString(data.trailCompensateSpread));

// ── Breakeven ──
   FileWriteString(h, "# BREAKEVEN\n");
   WriteKV(h, "BEOn",               IntegerToString(data.beOn));
   WriteKV(h, "BEActivationFixed",  IntegerToString(data.beActivationFixed));
   WriteKV(h, "BEOffsetFixed",      IntegerToString(data.beOffsetFixed));
   WriteKV(h, "BEActivationATR",    DoubleToString(data.beActivationATR, 2));
   WriteKV(h, "BEOffsetATR",        DoubleToString(data.beOffsetATR, 2));

// ── Partial TP ──
   FileWriteString(h, "# PARTIAL TP\n");
   WriteKV(h, "PartialTP",          IntegerToString(data.partialTP));
   WriteKV(h, "TP1Percent",         DoubleToString(data.tp1Percent, 1));
   WriteKV(h, "TP1Distance",        IntegerToString(data.tp1Distance));
   WriteKV(h, "TP2Percent",         DoubleToString(data.tp2Percent, 1));
   WriteKV(h, "TP2Distance",        IntegerToString(data.tp2Distance));

// ── Daily Limits ──
   FileWriteString(h, "# DAILY LIMITS\n");
   WriteKV(h, "DailyLimitsOn",      IntegerToString(data.dailyLimitsOn));
   WriteKV(h, "MaxDailyTrades",     IntegerToString(data.maxDailyTrades));
   WriteKV(h, "MaxDailyLoss",       DoubleToString(data.maxDailyLoss, 2));
   WriteKV(h, "MaxDailyGain",       DoubleToString(data.maxDailyGain, 2));
   WriteKV(h, "ProfitTargetAction", IntegerToString((int)data.profitTargetAction));

// ── Drawdown ──
   FileWriteString(h, "# DRAWDOWN\n");
   WriteKV(h, "DDOn",               IntegerToString(data.ddOn));
   WriteKV(h, "DDValue",            DoubleToString(data.ddValue, 2));
   WriteKV(h, "DDType",             IntegerToString((int)data.ddType));
   WriteKV(h, "DDPeakMode",         IntegerToString((int)data.ddPeakMode));

// ── Bloqueios ──
   FileWriteString(h, "# BLOQUEIOS\n");
   WriteKV(h, "MaxSpread",          IntegerToString(data.maxSpread));
   WriteKV(h, "TradeDirection",     IntegerToString((int)data.tradeDirection));

// ── Streak ──
   FileWriteString(h, "# STREAK\n");
   WriteKV(h, "LossStreakOn",       IntegerToString(data.lossStreakOn));
   WriteKV(h, "MaxLossStreak",      IntegerToString(data.maxLossStreak));
   WriteKV(h, "LossStreakAction",   IntegerToString((int)data.lossStreakAction));
   WriteKV(h, "LossPauseMinutes",   IntegerToString(data.lossPauseMinutes));
   WriteKV(h, "WinStreakOn",        IntegerToString(data.winStreakOn));
   WriteKV(h, "MaxWinStreak",       IntegerToString(data.maxWinStreak));
   WriteKV(h, "WinStreakAction",    IntegerToString((int)data.winStreakAction));
   WriteKV(h, "WinPauseMinutes",    IntegerToString(data.winPauseMinutes));

// ── Filtro de Horário ──
   FileWriteString(h, "# TIME FILTER\n");
   WriteKV(h, "TimeFilterOn",       IntegerToString(data.timeFilterOn));
   WriteKV(h, "TFStartH",           IntegerToString(data.tfStartH));
   WriteKV(h, "TFStartM",           IntegerToString(data.tfStartM));
   WriteKV(h, "TFEndH",             IntegerToString(data.tfEndH));
   WriteKV(h, "TFEndM",             IntegerToString(data.tfEndM));
   WriteKV(h, "TFCloseOnEnd",       IntegerToString(data.tfCloseOnEnd));

// ── Proteção Sessão ──
   WriteKV(h, "CBSOn",              IntegerToString(data.cbsOn));
   WriteKV(h, "CBSMinutes",         IntegerToString(data.cbsMinutes));

// ── News ──
   FileWriteString(h, "# NEWS\n");
   WriteKV(h, "NewsOn1",            IntegerToString(data.newsOn1));
   WriteKV(h, "News1SH",            IntegerToString(data.news1SH));
   WriteKV(h, "News1SM",            IntegerToString(data.news1SM));
   WriteKV(h, "News1EH",            IntegerToString(data.news1EH));
   WriteKV(h, "News1EM",            IntegerToString(data.news1EM));
   WriteKV(h, "NewsOn2",            IntegerToString(data.newsOn2));
   WriteKV(h, "News2SH",            IntegerToString(data.news2SH));
   WriteKV(h, "News2SM",            IntegerToString(data.news2SM));
   WriteKV(h, "News2EH",            IntegerToString(data.news2EH));
   WriteKV(h, "News2EM",            IntegerToString(data.news2EM));
   WriteKV(h, "NewsOn3",            IntegerToString(data.newsOn3));
   WriteKV(h, "News3SH",            IntegerToString(data.news3SH));
   WriteKV(h, "News3SM",            IntegerToString(data.news3SM));
   WriteKV(h, "News3EH",            IntegerToString(data.news3EH));
   WriteKV(h, "News3EM",            IntegerToString(data.news3EM));

// ── Outros ──
   FileWriteString(h, "# OUTROS\n");
   WriteKV(h, "MagicNumber",        IntegerToString(data.magicNumber));
   WriteKV(h, "Slippage",           IntegerToString(data.slippage));
   WriteKV(h, "ConflictMode",       IntegerToString((int)data.conflictMode));
   WriteKV(h, "ShowDebug",          IntegerToString(data.showDebug));
   WriteKV(h, "DebugCooldown",      IntegerToString(data.debugCooldown));
   WriteKV(h, "TrailingType",       IntegerToString((int)data.trailingType));
   WriteKV(h, "BEType",             IntegerToString((int)data.beType));

// ── MA Cross Strategy ──
   FileWriteString(h, "# MA CROSS\n");
   WriteKV(h, "MAEnabled",          IntegerToString(data.maEnabled));
   WriteKV(h, "MAPriority",         IntegerToString(data.maPriority));
   WriteKV(h, "MAFastPeriod",       IntegerToString(data.maFastPeriod));
   WriteKV(h, "MAFastMethod",       IntegerToString((int)data.maFastMethod));
   WriteKV(h, "MAFastApplied",      IntegerToString((int)data.maFastApplied));
   WriteKV(h, "MAFastTF",           IntegerToString((int)data.maFastTF));
   WriteKV(h, "MASlowPeriod",       IntegerToString(data.maSlowPeriod));
   WriteKV(h, "MASlowMethod",       IntegerToString((int)data.maSlowMethod));
   WriteKV(h, "MASlowApplied",      IntegerToString((int)data.maSlowApplied));
   WriteKV(h, "MASlowTF",           IntegerToString((int)data.maSlowTF));
   WriteKV(h, "MAMinDistance",       IntegerToString(data.maMinDistance));
   WriteKV(h, "MAEntryMode",        IntegerToString((int)data.maEntryMode));
   WriteKV(h, "MAExitMode",         IntegerToString((int)data.maExitMode));

// ── RSI Strategy ──
   FileWriteString(h, "# RSI STRATEGY\n");
   WriteKV(h, "RSIEnabled",         IntegerToString(data.rsiEnabled));
   WriteKV(h, "RSIPriority",        IntegerToString(data.rsiPriority));
   WriteKV(h, "RSIPeriod",          IntegerToString(data.rsiPeriod));
   WriteKV(h, "RSIApplied",         IntegerToString((int)data.rsiApplied));
   WriteKV(h, "RSITF",              IntegerToString((int)data.rsiTF));
   WriteKV(h, "RSIMode",            IntegerToString((int)data.rsiMode));
   WriteKV(h, "RSIOversold",        DoubleToString(data.rsiOversold, 1));
   WriteKV(h, "RSIOverbought",      DoubleToString(data.rsiOverbought, 1));
   WriteKV(h, "RSIMidLevel",        DoubleToString(data.rsiMidLevel, 1));

// ── BB Strategy ──
   FileWriteString(h, "# BB STRATEGY\n");
   WriteKV(h, "BBEnabled",          IntegerToString(data.bbEnabled));
   WriteKV(h, "BBPriority",         IntegerToString(data.bbPriority));
   WriteKV(h, "BBPeriod",           IntegerToString(data.bbPeriod));
   WriteKV(h, "BBDeviation",        DoubleToString(data.bbDeviation, 1));
   WriteKV(h, "BBApplied",          IntegerToString((int)data.bbApplied));
   WriteKV(h, "BBTF",               IntegerToString((int)data.bbTF));
   WriteKV(h, "BBMode",             IntegerToString((int)data.bbMode));
   WriteKV(h, "BBEntryMode",        IntegerToString((int)data.bbEntryMode));
   WriteKV(h, "BBExitMode",         IntegerToString((int)data.bbExitMode));

// ── Trend Filter ──
   FileWriteString(h, "# TREND FILTER\n");
   WriteKV(h, "TrendEnabled",       IntegerToString(data.trendEnabled));
   WriteKV(h, "TrendPeriod",        IntegerToString(data.trendPeriod));
   WriteKV(h, "TrendMethod",        IntegerToString((int)data.trendMethod));
   WriteKV(h, "TrendApplied",       IntegerToString((int)data.trendApplied));
   WriteKV(h, "TrendTF",            IntegerToString((int)data.trendTF));
   WriteKV(h, "TrendMinDistance",    DoubleToString(data.trendMinDistance, 2));

// ── RSI Filter ──
   FileWriteString(h, "# RSI FILTER\n");
   WriteKV(h, "RSIFiltEnabled",     IntegerToString(data.rsiFiltEnabled));
   WriteKV(h, "RSIFiltPeriod",      IntegerToString(data.rsiFiltPeriod));
   WriteKV(h, "RSIFiltApplied",     IntegerToString((int)data.rsiFiltApplied));
   WriteKV(h, "RSIFiltTF",          IntegerToString((int)data.rsiFiltTF));
   WriteKV(h, "RSIFiltMode",        IntegerToString((int)data.rsiFiltMode));
   WriteKV(h, "RSIFiltOversold",    DoubleToString(data.rsiFiltOversold, 1));
   WriteKV(h, "RSIFiltOverbought",  DoubleToString(data.rsiFiltOverbought, 1));
   WriteKV(h, "RSIFiltLowerNeutral",DoubleToString(data.rsiFiltLowerNeutral, 1));
   WriteKV(h, "RSIFiltUpperNeutral",DoubleToString(data.rsiFiltUpperNeutral, 1));
   WriteKV(h, "RSIFiltShift",       IntegerToString(data.rsiFiltShift));

// ── BB Filter ──
   FileWriteString(h, "# BB FILTER\n");
   WriteKV(h, "BBFiltEnabled",      IntegerToString(data.bbFiltEnabled));
   WriteKV(h, "BBFiltPeriod",       IntegerToString(data.bbFiltPeriod));
   WriteKV(h, "BBFiltDeviation",    DoubleToString(data.bbFiltDeviation, 1));
   WriteKV(h, "BBFiltApplied",      IntegerToString((int)data.bbFiltApplied));
   WriteKV(h, "BBFiltTF",           IntegerToString((int)data.bbFiltTF));
   WriteKV(h, "BBFiltMetric",       IntegerToString((int)data.bbFiltMetric));
   WriteKV(h, "BBFiltThreshold",    DoubleToString(data.bbFiltThreshold, 2));
   WriteKV(h, "BBFiltPercPeriod",   IntegerToString(data.bbFiltPercPeriod));

   FileClose(h);

// Escrita atômica: apagar o antigo e renomear .tmp → .cfg
   FileDelete(fn);
   if(!FileMove(fnTmp, 0, fn, 0))
     {
      Print("ConfigPersistence: FileMove falhou — usando .tmp diretamente");
      // Fallback: .tmp já contém os dados corretos
      // Tentar copiar manualmente
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
//| Load — carrega todas as configs do arquivo                        |
//+------------------------------------------------------------------+
bool CConfigPersistence::Load(string symbol, int magic, SConfigData &data)
  {
   if(MQLInfoInteger(MQL_TESTER)) return false;

   string fn = GetFileName(symbol, magic);
   int h = FileOpen(fn, FILE_READ | FILE_TXT | FILE_ANSI);
   if(h == INVALID_HANDLE) return false;

// Ler todas as linhas e popular a struct
   while(!FileIsEnding(h))
     {
      string line = FileReadString(h);

      // Ignorar comentários e linhas vazias
      if(StringLen(line) == 0) continue;
      if(StringGetCharacter(line, 0) == '#') continue;

      string key = ReadKey(line);
      string val = ReadValue(line);
      if(StringLen(key) == 0) continue;

      // ── Parse por chave ──
      // Header
      if(key == "ConfigVersion")       data.version = (int)StringToInteger(val);
      else if(key == "LastModified")    data.lastModified = StringToTime(val);
      // Risco
      else if(key == "LotSize")            data.lotSize = StringToDouble(val);
      else if(key == "SLType")             data.slType = (ENUM_SL_TYPE)StringToInteger(val);
      else if(key == "FixedSL")            data.fixedSL = (int)StringToInteger(val);
      else if(key == "SLATRMultiplier")    data.slATRMultiplier = StringToDouble(val);
      else if(key == "RangeMultiplier")    data.rangeMultiplier = StringToDouble(val);
      else if(key == "SLCompensateSpread") data.slCompensateSpread = (bool)StringToInteger(val);
      else if(key == "TPType")             data.tpType = (ENUM_TP_TYPE)StringToInteger(val);
      else if(key == "FixedTP")            data.fixedTP = (int)StringToInteger(val);
      else if(key == "TPATRMultiplier")    data.tpATRMultiplier = StringToDouble(val);
      else if(key == "TPCompensateSpread") data.tpCompensateSpread = (bool)StringToInteger(val);
      else if(key == "ATRPeriod")          data.atrPeriod = (int)StringToInteger(val);
      else if(key == "RangePeriod")        data.rangePeriod = (int)StringToInteger(val);
      // Trailing
      else if(key == "TrailOn")            data.trailOn = (bool)StringToInteger(val);
      else if(key == "TrailStartFixed")    data.trailStartFixed = (int)StringToInteger(val);
      else if(key == "TrailStepFixed")     data.trailStepFixed = (int)StringToInteger(val);
      else if(key == "TrailStartATR")      data.trailStartATR = StringToDouble(val);
      else if(key == "TrailStepATR")       data.trailStepATR = StringToDouble(val);
      else if(key == "TrailCompSpread")    data.trailCompensateSpread = (bool)StringToInteger(val);
      // Breakeven
      else if(key == "BEOn")               data.beOn = (bool)StringToInteger(val);
      else if(key == "BEActivationFixed")  data.beActivationFixed = (int)StringToInteger(val);
      else if(key == "BEOffsetFixed")      data.beOffsetFixed = (int)StringToInteger(val);
      else if(key == "BEActivationATR")    data.beActivationATR = StringToDouble(val);
      else if(key == "BEOffsetATR")        data.beOffsetATR = StringToDouble(val);
      // Partial TP
      else if(key == "PartialTP")          data.partialTP = (bool)StringToInteger(val);
      else if(key == "TP1Percent")         data.tp1Percent = StringToDouble(val);
      else if(key == "TP1Distance")        data.tp1Distance = (int)StringToInteger(val);
      else if(key == "TP2Percent")         data.tp2Percent = StringToDouble(val);
      else if(key == "TP2Distance")        data.tp2Distance = (int)StringToInteger(val);
      // Daily Limits
      else if(key == "DailyLimitsOn")      data.dailyLimitsOn = (bool)StringToInteger(val);
      else if(key == "MaxDailyTrades")     data.maxDailyTrades = (int)StringToInteger(val);
      else if(key == "MaxDailyLoss")       data.maxDailyLoss = StringToDouble(val);
      else if(key == "MaxDailyGain")       data.maxDailyGain = StringToDouble(val);
      else if(key == "ProfitTargetAction") data.profitTargetAction = (ENUM_PROFIT_TARGET_ACTION)StringToInteger(val);
      // Drawdown
      else if(key == "DDOn")               data.ddOn = (bool)StringToInteger(val);
      else if(key == "DDValue")            data.ddValue = StringToDouble(val);
      else if(key == "DDType")             data.ddType = (ENUM_DRAWDOWN_TYPE)StringToInteger(val);
      else if(key == "DDPeakMode")         data.ddPeakMode = (ENUM_DRAWDOWN_PEAK_MODE)StringToInteger(val);
      // Bloqueios
      else if(key == "MaxSpread")          data.maxSpread = (int)StringToInteger(val);
      else if(key == "TradeDirection")     data.tradeDirection = (ENUM_TRADE_DIRECTION)StringToInteger(val);
      // Streak
      else if(key == "LossStreakOn")       data.lossStreakOn = (bool)StringToInteger(val);
      else if(key == "MaxLossStreak")      data.maxLossStreak = (int)StringToInteger(val);
      else if(key == "LossStreakAction")   data.lossStreakAction = (ENUM_STREAK_ACTION)StringToInteger(val);
      else if(key == "LossPauseMinutes")   data.lossPauseMinutes = (int)StringToInteger(val);
      else if(key == "WinStreakOn")        data.winStreakOn = (bool)StringToInteger(val);
      else if(key == "MaxWinStreak")       data.maxWinStreak = (int)StringToInteger(val);
      else if(key == "WinStreakAction")    data.winStreakAction = (ENUM_STREAK_ACTION)StringToInteger(val);
      else if(key == "WinPauseMinutes")    data.winPauseMinutes = (int)StringToInteger(val);
      // Filtro de Horário
      else if(key == "TimeFilterOn")       data.timeFilterOn = (bool)StringToInteger(val);
      else if(key == "TFStartH")           data.tfStartH = (int)StringToInteger(val);
      else if(key == "TFStartM")           data.tfStartM = (int)StringToInteger(val);
      else if(key == "TFEndH")             data.tfEndH = (int)StringToInteger(val);
      else if(key == "TFEndM")             data.tfEndM = (int)StringToInteger(val);
      else if(key == "TFCloseOnEnd")       data.tfCloseOnEnd = (bool)StringToInteger(val);
      // Proteção Sessão
      else if(key == "CBSOn")              data.cbsOn = (bool)StringToInteger(val);
      else if(key == "CBSMinutes")         data.cbsMinutes = (int)StringToInteger(val);
      // News
      else if(key == "NewsOn1")            data.newsOn1 = (bool)StringToInteger(val);
      else if(key == "News1SH")            data.news1SH = (int)StringToInteger(val);
      else if(key == "News1SM")            data.news1SM = (int)StringToInteger(val);
      else if(key == "News1EH")            data.news1EH = (int)StringToInteger(val);
      else if(key == "News1EM")            data.news1EM = (int)StringToInteger(val);
      else if(key == "NewsOn2")            data.newsOn2 = (bool)StringToInteger(val);
      else if(key == "News2SH")            data.news2SH = (int)StringToInteger(val);
      else if(key == "News2SM")            data.news2SM = (int)StringToInteger(val);
      else if(key == "News2EH")            data.news2EH = (int)StringToInteger(val);
      else if(key == "News2EM")            data.news2EM = (int)StringToInteger(val);
      else if(key == "NewsOn3")            data.newsOn3 = (bool)StringToInteger(val);
      else if(key == "News3SH")            data.news3SH = (int)StringToInteger(val);
      else if(key == "News3SM")            data.news3SM = (int)StringToInteger(val);
      else if(key == "News3EH")            data.news3EH = (int)StringToInteger(val);
      else if(key == "News3EM")            data.news3EM = (int)StringToInteger(val);
      // Outros
      else if(key == "MagicNumber")        data.magicNumber = (int)StringToInteger(val);
      else if(key == "Slippage")           data.slippage = (int)StringToInteger(val);
      else if(key == "ConflictMode")       data.conflictMode = (ENUM_CONFLICT_RESOLUTION)StringToInteger(val);
      else if(key == "ShowDebug")          data.showDebug = (bool)StringToInteger(val);
      else if(key == "DebugCooldown")      data.debugCooldown = (int)StringToInteger(val);
      else if(key == "TrailingType")       data.trailingType = (ENUM_TRAILING_TYPE)StringToInteger(val);
      else if(key == "BEType")             data.beType = (ENUM_BE_TYPE)StringToInteger(val);
      // MA Cross
      else if(key == "MAEnabled")          data.maEnabled = (bool)StringToInteger(val);
      else if(key == "MAPriority")         data.maPriority = (int)StringToInteger(val);
      else if(key == "MAFastPeriod")       data.maFastPeriod = (int)StringToInteger(val);
      else if(key == "MAFastMethod")       data.maFastMethod = (ENUM_MA_METHOD)StringToInteger(val);
      else if(key == "MAFastApplied")      data.maFastApplied = (ENUM_APPLIED_PRICE)StringToInteger(val);
      else if(key == "MAFastTF")           data.maFastTF = (ENUM_TIMEFRAMES)StringToInteger(val);
      else if(key == "MASlowPeriod")       data.maSlowPeriod = (int)StringToInteger(val);
      else if(key == "MASlowMethod")       data.maSlowMethod = (ENUM_MA_METHOD)StringToInteger(val);
      else if(key == "MASlowApplied")      data.maSlowApplied = (ENUM_APPLIED_PRICE)StringToInteger(val);
      else if(key == "MASlowTF")           data.maSlowTF = (ENUM_TIMEFRAMES)StringToInteger(val);
      else if(key == "MAMinDistance")       data.maMinDistance = (int)StringToInteger(val);
      else if(key == "MAEntryMode")        data.maEntryMode = (ENUM_ENTRY_MODE)StringToInteger(val);
      else if(key == "MAExitMode")         data.maExitMode = (ENUM_EXIT_MODE)StringToInteger(val);
      // RSI Strategy
      else if(key == "RSIEnabled")         data.rsiEnabled = (bool)StringToInteger(val);
      else if(key == "RSIPriority")        data.rsiPriority = (int)StringToInteger(val);
      else if(key == "RSIPeriod")          data.rsiPeriod = (int)StringToInteger(val);
      else if(key == "RSIApplied")         data.rsiApplied = (ENUM_APPLIED_PRICE)StringToInteger(val);
      else if(key == "RSITF")              data.rsiTF = (ENUM_TIMEFRAMES)StringToInteger(val);
      else if(key == "RSIMode")            data.rsiMode = (ENUM_RSI_SIGNAL_MODE)StringToInteger(val);
      else if(key == "RSIOversold")        data.rsiOversold = StringToDouble(val);
      else if(key == "RSIOverbought")      data.rsiOverbought = StringToDouble(val);
      else if(key == "RSIMidLevel")        data.rsiMidLevel = StringToDouble(val);
      // BB Strategy
      else if(key == "BBEnabled")          data.bbEnabled = (bool)StringToInteger(val);
      else if(key == "BBPriority")         data.bbPriority = (int)StringToInteger(val);
      else if(key == "BBPeriod")           data.bbPeriod = (int)StringToInteger(val);
      else if(key == "BBDeviation")        data.bbDeviation = StringToDouble(val);
      else if(key == "BBApplied")          data.bbApplied = (ENUM_APPLIED_PRICE)StringToInteger(val);
      else if(key == "BBTF")               data.bbTF = (ENUM_TIMEFRAMES)StringToInteger(val);
      else if(key == "BBMode")             data.bbMode = (ENUM_BB_SIGNAL_MODE)StringToInteger(val);
      else if(key == "BBEntryMode")        data.bbEntryMode = (ENUM_ENTRY_MODE)StringToInteger(val);
      else if(key == "BBExitMode")         data.bbExitMode = (ENUM_EXIT_MODE)StringToInteger(val);
      // Trend Filter
      else if(key == "TrendEnabled")       data.trendEnabled = (bool)StringToInteger(val);
      else if(key == "TrendPeriod")        data.trendPeriod = (int)StringToInteger(val);
      else if(key == "TrendMethod")        data.trendMethod = (ENUM_MA_METHOD)StringToInteger(val);
      else if(key == "TrendApplied")       data.trendApplied = (ENUM_APPLIED_PRICE)StringToInteger(val);
      else if(key == "TrendTF")            data.trendTF = (ENUM_TIMEFRAMES)StringToInteger(val);
      else if(key == "TrendMinDistance")    data.trendMinDistance = StringToDouble(val);
      // RSI Filter
      else if(key == "RSIFiltEnabled")     data.rsiFiltEnabled = (bool)StringToInteger(val);
      else if(key == "RSIFiltPeriod")      data.rsiFiltPeriod = (int)StringToInteger(val);
      else if(key == "RSIFiltApplied")     data.rsiFiltApplied = (ENUM_APPLIED_PRICE)StringToInteger(val);
      else if(key == "RSIFiltTF")          data.rsiFiltTF = (ENUM_TIMEFRAMES)StringToInteger(val);
      else if(key == "RSIFiltMode")        data.rsiFiltMode = (ENUM_RSI_FILTER_MODE)StringToInteger(val);
      else if(key == "RSIFiltOversold")    data.rsiFiltOversold = StringToDouble(val);
      else if(key == "RSIFiltOverbought")  data.rsiFiltOverbought = StringToDouble(val);
      else if(key == "RSIFiltLowerNeutral")data.rsiFiltLowerNeutral = StringToDouble(val);
      else if(key == "RSIFiltUpperNeutral")data.rsiFiltUpperNeutral = StringToDouble(val);
      else if(key == "RSIFiltShift")       data.rsiFiltShift = (int)StringToInteger(val);
      // BB Filter
      else if(key == "BBFiltEnabled")      data.bbFiltEnabled = (bool)StringToInteger(val);
      else if(key == "BBFiltPeriod")       data.bbFiltPeriod = (int)StringToInteger(val);
      else if(key == "BBFiltDeviation")    data.bbFiltDeviation = StringToDouble(val);
      else if(key == "BBFiltApplied")      data.bbFiltApplied = (ENUM_APPLIED_PRICE)StringToInteger(val);
      else if(key == "BBFiltTF")           data.bbFiltTF = (ENUM_TIMEFRAMES)StringToInteger(val);
      else if(key == "BBFiltMetric")       data.bbFiltMetric = (ENUM_BB_SQUEEZE_METRIC)StringToInteger(val);
      else if(key == "BBFiltThreshold")    data.bbFiltThreshold = StringToDouble(val);
      else if(key == "BBFiltPercPeriod")   data.bbFiltPercPeriod = (int)StringToInteger(val);
     }

   FileClose(h);

// ── Validação de enums (proteção contra .cfg corrompido) ──
   if(data.slType < SL_FIXED || data.slType > SL_RANGE)
      data.slType = SL_FIXED;
   if(data.tpType < TP_FIXED || data.tpType > TP_ATR)
      data.tpType = TP_FIXED;
   if(data.trailingType < TRAILING_FIXED || data.trailingType > TRAILING_ATR)
      data.trailingType = TRAILING_FIXED;
   if(data.beType < BE_FIXED || data.beType > BE_ATR)
      data.beType = BE_FIXED;
   if(data.tradeDirection < DIRECTION_BOTH || data.tradeDirection > DIRECTION_SELL_ONLY)
      data.tradeDirection = DIRECTION_BOTH;

   return true;
  }

//+------------------------------------------------------------------+
//| FIM DO ARQUIVO ConfigPersistence.mqh v1.01                        |
//+------------------------------------------------------------------+
