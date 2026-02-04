//+------------------------------------------------------------------+
//|                                                       Logger.mqh |
//|                                         Copyright 2026, EP Filho |
//|                                Sistema de Logging - EPBot Matrix |
//|                     Versão 3.23 - Claude Parte 021 (Claude Code) |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, EP Filho"
#property link      "https://github.com/EPFILHO"
#property version   "3.23"

// ═══════════════════════════════════════════════════════════════════
// CHANGELOG v3.23:
// ✅ Fix: Usa TimeTradeServer() para determinação de data (evita bug pré-mercado)
// ✅ Fix: ResetDaily() agora atualiza m_txtFileName para o novo dia
// ✅ Novo: GetReliableDate() centraliza obtenção de data confiável
//
// CHANGELOG v3.22:
// ✅ Compatível com TradeManager v1.22 que agora passa valores REAIS
// ✅ SavePartialTrade() agora recebe valores REAIS do deal (não estimados)
// ✅ Elimina discrepâncias por slippage em mercados voláteis
// ═══════════════════════════════════════════════════════════════════
// CHANGELOG v3.21:
// ✅ Fix: AddPartialTPProfit() agora atualiza m_grossProfit
// ✅ Fix: SaveDailyReport() usa GetDailyProfit() para incluir TPs parciais
// ✅ Relatório diário agora mostra valores corretos (igual MT5)
// ═══════════════════════════════════════════════════════════════════
// CHANGELOG v3.20:
// ✅ Novo: SavePartialTrade() salva cada TP parcial imediatamente no CSV
// ✅ Ajustado: LoadDailyStats() reconhece linhas "Partial TP" e acumula
//    em m_partialTPProfit (não conta como trade separado)
// ✅ Habilita ressincronização de TPs parciais ao reiniciar EA
// ═══════════════════════════════════════════════════════════════════
// CHANGELOG v3.10:
// ✅ CORREÇÃO CRÍTICA: TPs parciais agora contabilizados no dailyProfit
// ✅ Novo: m_partialTPProfit rastreia lucros de TPs parciais
// ✅ Novo: AddPartialTPProfit() para registrar lucro de TP parcial
// ✅ Novo: GetPartialTPProfit() para consultar lucro parcial acumulado
// ✅ GetDailyProfit() agora inclui m_partialTPProfit
// ✅ ResetDaily() limpa m_partialTPProfit
// ═══════════════════════════════════════════════════════════════════
// CHANGELOG v3.00:
// ✅ NOVA ARQUITETURA DE LOGGING FOCADA EM TRADING
// ✅ Níveis orientados ao negócio (ERROR/TRADE/EVENT/SIGNAL/DEBUG)
// ✅ Throttle inteligente separado por contexto
// ✅ ERROR/TRADE/EVENT/SIGNAL SEMPRE aparecem
// ✅ DEBUG condicional (controlado por input)
// ✅ Mantém compatibilidade com versão anterior
// ═══════════════════════════════════════════════════════════════════

//+------------------------------------------------------------------+
//| Enumerações - Nova Arquitetura v3.00                             |
//+------------------------------------------------------------------+

// Nível de Log - ORIENTADO AO NEGÓCIO (Trading)
enum ENUM_LOG_LEVEL
  {
   LOG_ERROR,    // SEMPRE visível - falhas operacionais
   LOG_TRADE,    // SEMPRE visível - trades, entries, exits
   LOG_EVENT,    // SEMPRE visível - inicialização, mudança de dia, configurações
   LOG_SIGNAL,   // SEMPRE visível - sinais detectados (mesmo que rejeitados)
   LOG_DEBUG     // Opcional - detalhes internos para debugging
  };

// Modo de Throttle - CONTROLE DE FREQUÊNCIA
enum ENUM_LOG_THROTTLE
  {
   THROTTLE_NONE,      // Sempre loga (trades, erros, eventos)
   THROTTLE_CANDLE,    // Uma vez por candle (sinais, filtros)
   THROTTLE_TIME,      // Cooldown em segundos (debug repetitivo)
   THROTTLE_CHANGE,    // Apenas quando valor muda
   THROTTLE_TICK       // Todo tick (sem throttle - debug agressivo)
  };

//+------------------------------------------------------------------+
//| Estrutura: Controle de Throttle                                  |
//+------------------------------------------------------------------+
struct SThrottleControl
  {
   string            key;           // Identificador único (context + hash)
   datetime          lastLog;       // Último log
   datetime          lastCandle;    // Último candle logado
   string            lastValue;     // Último valor (para THROTTLE_CHANGE)
  };

//+------------------------------------------------------------------+
//| Classe Logger v3.00 - Sistema de logs e relatórios               |
//+------------------------------------------------------------------+
class CLogger
  {
private:
   // ═══════════════════════════════════════════════════════════
   // INPUT PARAMETER (imutável - valor original)
   // ═══════════════════════════════════════════════════════════
   bool              m_inputShowDebug;      // Mostrar logs DEBUG?
   int               m_inputDebugCooldown;  // Cooldown para DEBUG com THROTTLE_TIME
   
   // ═══════════════════════════════════════════════════════════
   // WORKING PARAMETERS (mutáveis - usados no código)
   // ═══════════════════════════════════════════════════════════
   bool              m_showDebug;
   int               m_debugCooldown;
   
   // ═══════════════════════════════════════════════════════════
   // CONFIGURAÇÃO
   // ═══════════════════════════════════════════════════════════
   string            m_symbol;
   int               m_magicNumber;
   
   // ═══════════════════════════════════════════════════════════
   // ARQUIVOS
   // ═══════════════════════════════════════════════════════════
   string            m_csvFileName;
   string            m_txtFileName;
   
   // ═══════════════════════════════════════════════════════════
   // CONTROLE DE THROTTLE
   // ═══════════════════════════════════════════════════════════
   SThrottleControl  m_throttles[];
   
   // ═══════════════════════════════════════════════════════════
   // ESTATÍSTICAS DO DIA
   // ═══════════════════════════════════════════════════════════
   double            m_dailyProfit;
   double            m_partialTPProfit;   // 🆕 v3.10: Lucro acumulado de TPs parciais
   int               m_dailyTrades;
   int               m_dailyWins;
   int               m_dailyLosses;
   int               m_dailyDraws;
   double            m_grossProfit;
   double            m_grossLoss;
   
   // ═══════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS
   // ═══════════════════════════════════════════════════════════
   bool              ShouldLog(ENUM_LOG_LEVEL level, ENUM_LOG_THROTTLE throttle, string context, string message, int cooldownSec);
   void              UpdateThrottle(string key, string value);
   string            GenerateThrottleKey(string context, string message);
   string            GetLevelPrefix(ENUM_LOG_LEVEL level);
   datetime          GetReliableDate();

public:
   // ═══════════════════════════════════════════════════════════
   // CONSTRUTOR/DESTRUTOR
   // ═══════════════════════════════════════════════════════════
                     CLogger();
                    ~CLogger();
   
   // ═══════════════════════════════════════════════════════════
   // INICIALIZAÇÃO
   // ═══════════════════════════════════════════════════════════
   bool              Init(bool showDebug, string symbol, int magic, int debugCooldown = 5);
   
   // ═══════════════════════════════════════════════════════════
   // NOVO MÉTODO UNIFICADO v3.00
   // ═══════════════════════════════════════════════════════════
   void              Log(
                        ENUM_LOG_LEVEL level,
                        ENUM_LOG_THROTTLE throttle,
                        string context,
                        string message,
                        int cooldownSec = 5
                     );
   
   // ═══════════════════════════════════════════════════════════
   // MÉTODOS LEGADOS (compatibilidade com v2.00)
   // ═══════════════════════════════════════════════════════════
   void              LogInfo(string message);
   void              LogWarning(string message);
   void              LogError(string message);
   void              LogDebug(string message);
   
   // ═══════════════════════════════════════════════════════════
   // TRADES
   // ═══════════════════════════════════════════════════════════
   void              SaveTrade(ulong positionId, double profit);
   void              SavePartialTrade(ulong positionId, ulong dealTicket, string tradeType,
                                      double entryPrice, double exitPrice, double volume,
                                      double profit, string motivo);  // 🆕 v3.20
   void              UpdateStats(double profit);
   
   // ═══════════════════════════════════════════════════════════
   // RELATÓRIOS
   // ═══════════════════════════════════════════════════════════
   void              LoadDailyStats();
   void              SaveDailyReport();
   string            GetConfigSummary();
   
   // ═══════════════════════════════════════════════════════════
   // HOT RELOAD
   // ═══════════════════════════════════════════════════════════
   void              SetShowDebug(bool show);
   void              SetDebugCooldown(int seconds);
   
   // ═══════════════════════════════════════════════════════════
   // 🆕 v3.10: PARTIAL TP PROFIT TRACKING
   // ═══════════════════════════════════════════════════════════
   void              AddPartialTPProfit(double profit);
   double            GetPartialTPProfit() { return m_partialTPProfit; }

   // ═══════════════════════════════════════════════════════════
   // GETTERS
   // ═══════════════════════════════════════════════════════════
   // 🆕 v3.10: Agora inclui lucro de TPs parciais para cálculo correto de limites
   double            GetDailyProfit() { return m_dailyProfit + m_partialTPProfit; }
   double            GetClosedTradesProfit() { return m_dailyProfit; }  // Apenas trades 100% fechados
   int               GetDailyTrades() { return m_dailyTrades; }
   int               GetDailyWins() { return m_dailyWins; }
   int               GetDailyLosses() { return m_dailyLosses; }
   int               GetDailyDraws() { return m_dailyDraws; }

   bool              GetShowDebug() { return m_showDebug; }
   bool              GetInputShowDebug() { return m_inputShowDebug; }
   
   // ═══════════════════════════════════════════════════════════
   // RESET
   // ═══════════════════════════════════════════════════════════
   void              ResetDaily();
  };

//+------------------------------------------------------------------+
//| Construtor                                                        |
//+------------------------------------------------------------------+
CLogger::CLogger()
  {
   m_inputShowDebug = false;
   m_inputDebugCooldown = 5;
   m_showDebug = false;
   m_debugCooldown = 5;

   m_dailyProfit = 0;
   m_partialTPProfit = 0;  // 🆕 v3.10
   m_dailyTrades = 0;
   m_dailyWins = 0;
   m_dailyLosses = 0;
   m_dailyDraws = 0;
   m_grossProfit = 0;
   m_grossLoss = 0;

   ArrayResize(m_throttles, 0);
  }

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CLogger::~CLogger()
  {
   ArrayFree(m_throttles);
  }

//+------------------------------------------------------------------+
//| Inicialização v3.00                                              |
//+------------------------------------------------------------------+
bool CLogger::Init(bool showDebug, string symbol, int magic, int debugCooldown = 5)
  {
   // Salvar INPUT
   m_inputShowDebug = showDebug;
   m_inputDebugCooldown = debugCooldown;
   
   // Inicializar WORKING
   m_showDebug = showDebug;
   m_debugCooldown = debugCooldown;
   
   m_symbol = symbol;
   m_magicNumber = magic;
   
   // Criar nomes de arquivos (usa TimeTradeServer para data correta pré-mercado)
   MqlDateTime dt;
   TimeToStruct(GetReliableDate(), dt);
   
   m_csvFileName = StringFormat("EPBot_Matrix_TradeLog_%s_M%d_%d.csv", 
                                 m_symbol, m_magicNumber, dt.year);
   
   m_txtFileName = StringFormat("EPBot_Matrix_DailySummary_%s_M%d_%02d%02d%04d.txt",
                                m_symbol, m_magicNumber, dt.day, dt.mon, dt.year);
   
   Print("╔══════════════════════════════════════════════════════════════╗");
   Print("║           LOGGER v3.00 - NOVA ARQUITETURA                   ║");
   Print("╠══════════════════════════════════════════════════════════════╣");
   Print("║  ERROR/TRADE/EVENT/SIGNAL: Sempre visíveis                  ║");
   Print("║  DEBUG: ", showDebug ? "ATIVADO" : "DESATIVADO", "                                          ║");
   Print("║  Throttle DEBUG: ", debugCooldown, " segundos                               ║");
   Print("╚══════════════════════════════════════════════════════════════╝");
   
   LoadDailyStats();
   
   return true;
  }

//+------------------------------------------------------------------+
//| NOVO MÉTODO UNIFICADO - Log() v3.00                              |
//+------------------------------------------------------------------+
void CLogger::Log(
   ENUM_LOG_LEVEL level,
   ENUM_LOG_THROTTLE throttle,
   string context,
   string message,
   int cooldownSec = 5
)
  {
   // ═══════════════════════════════════════════════════════════
   // REGRA 1: DEBUG é condicional
   // ═══════════════════════════════════════════════════════════
   if(level == LOG_DEBUG && !m_showDebug)
      return;
   
   // ═══════════════════════════════════════════════════════════
   // REGRA 2: Verificar throttle
   // ═══════════════════════════════════════════════════════════
   if(!ShouldLog(level, throttle, context, message, cooldownSec))
      return;
   
   // ═══════════════════════════════════════════════════════════
   // REGRA 3: Formatar e imprimir
   // ═══════════════════════════════════════════════════════════
   string prefix = GetLevelPrefix(level);
   string fullMessage = StringFormat("%s [%s] %s", prefix, context, message);
   
   Print(fullMessage);
  }

//+------------------------------------------------------------------+
//| Verificar se deve logar (throttle)                               |
//+------------------------------------------------------------------+
bool CLogger::ShouldLog(
   ENUM_LOG_LEVEL level,
   ENUM_LOG_THROTTLE throttle,
   string context,
   string message,
   int cooldownSec
)
  {
   // ═══════════════════════════════════════════════════════════
   // THROTTLE_NONE e THROTTLE_TICK: SEMPRE loga
   // ═══════════════════════════════════════════════════════════
   if(throttle == THROTTLE_NONE || throttle == THROTTLE_TICK)
     {
      return true;
     }
   
   // ═══════════════════════════════════════════════════════════
   // Gerar chave única
   // ═══════════════════════════════════════════════════════════
   string key = GenerateThrottleKey(context, message);
   
   // Buscar controle existente
   int index = -1;
   for(int i = 0; i < ArraySize(m_throttles); i++)
     {
      if(m_throttles[i].key == key)
        {
         index = i;
         break;
        }
     }
   
   // Criar novo se não existe
   if(index < 0)
     {
      index = ArraySize(m_throttles);
      ArrayResize(m_throttles, index + 1);
      m_throttles[index].key = key;
      m_throttles[index].lastLog = 0;
      m_throttles[index].lastCandle = 0;
      m_throttles[index].lastValue = "";
     }
   
   datetime now = TimeCurrent();
   datetime currentCandle = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   // ═══════════════════════════════════════════════════════════
   // THROTTLE_CANDLE: 1x por candle
   // ═══════════════════════════════════════════════════════════
   if(throttle == THROTTLE_CANDLE)
     {
      if(m_throttles[index].lastCandle == currentCandle)
         return false;
      
      m_throttles[index].lastCandle = currentCandle;
      m_throttles[index].lastLog = now;
      return true;
     }
   
   // ═══════════════════════════════════════════════════════════
   // THROTTLE_TIME: Cooldown em segundos
   // ═══════════════════════════════════════════════════════════
   if(throttle == THROTTLE_TIME)
     {
      // Usar cooldown específico ou padrão
      int cooldown = (level == LOG_DEBUG) ? m_debugCooldown : cooldownSec;
      
      if((now - m_throttles[index].lastLog) < cooldown)
         return false;
      
      m_throttles[index].lastLog = now;
      return true;
     }
   
   // ═══════════════════════════════════════════════════════════
   // THROTTLE_CHANGE: Apenas quando valor muda
   // ═══════════════════════════════════════════════════════════
   if(throttle == THROTTLE_CHANGE)
     {
      if(m_throttles[index].lastValue == message)
         return false;
      
      m_throttles[index].lastValue = message;
      m_throttles[index].lastLog = now;
      return true;
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Gerar chave de throttle                                          |
//+------------------------------------------------------------------+
string CLogger::GenerateThrottleKey(string context, string message)
  {
   // Usa apenas o contexto para agrupar mensagens similares
   return context;
  }

//+------------------------------------------------------------------+
//| Obter prefixo do nível                                           |
//+------------------------------------------------------------------+
string CLogger::GetLevelPrefix(ENUM_LOG_LEVEL level)
  {
   switch(level)
     {
      case LOG_ERROR:   return "❌ [ERROR]";
      case LOG_TRADE:   return "💰 [TRADE]";
      case LOG_EVENT:   return "📅 [EVENT]";
      case LOG_SIGNAL:  return "🎯 [SIGNAL]";
      case LOG_DEBUG:   return "🔍 [DEBUG]";
      default:          return "ℹ️ [INFO]";
     }
  }

//+------------------------------------------------------------------+
//| Data confiável (independente de ticks recebidos)                 |
//| TimeTradeServer() calcula o horário real do servidor mesmo       |
//| antes do mercado abrir, diferente de TimeCurrent() que retorna   |
//| o horário do último tick recebido (pode ser de ontem).           |
//+------------------------------------------------------------------+
datetime CLogger::GetReliableDate()
  {
   return TimeTradeServer();
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar exibição de DEBUG                           |
//+------------------------------------------------------------------+
void CLogger::SetShowDebug(bool show)
  {
   bool oldValue = m_showDebug;
   m_showDebug = show;
   
   Print("🔄 Logger: DEBUG ", show ? "ATIVADO" : "DESATIVADO");
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar cooldown de DEBUG                           |
//+------------------------------------------------------------------+
void CLogger::SetDebugCooldown(int seconds)
  {
   int oldValue = m_debugCooldown;
   m_debugCooldown = seconds;
   
   Print("🔄 Logger: Cooldown DEBUG: ", oldValue, " → ", seconds, " segundos");
  }

//+------------------------------------------------------------------+
//| MÉTODOS LEGADOS - Compatibilidade com v2.00                      |
//+------------------------------------------------------------------+

void CLogger::LogInfo(string message)
  {
   Log(LOG_EVENT, THROTTLE_NONE, "INFO", message);
  }

void CLogger::LogWarning(string message)
  {
   Log(LOG_EVENT, THROTTLE_NONE, "WARNING", message);
  }

void CLogger::LogError(string message)
  {
   Log(LOG_ERROR, THROTTLE_NONE, "ERROR", message);
  }

void CLogger::LogDebug(string message)
  {
   Log(LOG_DEBUG, THROTTLE_TICK, "DEBUG", message);
  }

//+------------------------------------------------------------------+
//| Salvar trade                                                     |
//+------------------------------------------------------------------+
void CLogger::SaveTrade(ulong positionId, double profit)
  {
   LogDebug("SaveTrade chamado - Position: " + IntegerToString(positionId));
   
   // Verificar se arquivo existe (criar header se novo)
   bool fileExists = false;
   int testHandle = FileOpen(m_csvFileName, FILE_READ | FILE_CSV);
   if(testHandle != INVALID_HANDLE)
     {
      fileExists = true;
      FileClose(testHandle);
     }
   
   // Abrir arquivo para escrita
   int fileHandle = FileOpen(m_csvFileName, FILE_READ | FILE_WRITE | FILE_CSV);
   if(fileHandle == INVALID_HANDLE)
     {
      LogError("Erro ao abrir CSV: " + IntegerToString(GetLastError()));
      return;
     }
   
   // Escrever header se arquivo novo
   if(!fileExists)
     {
      string header = "Data,Hora,Ticket,Tipo,Entrada,Saida,Volume,SL,TP,Profit,Swap,Comissao,Total,Spread,DuracaoMin,Motivo,Origem";
      FileWriteString(fileHandle, header + "\n");
     }
   
   // Ir para o final do arquivo
   FileSeek(fileHandle, 0, SEEK_END);
   
   // Selecionar histórico da posição
   if(!HistorySelectByPosition(positionId))
     {
      LogError("Não foi possível carregar histórico da posição " + IntegerToString(positionId));
      FileClose(fileHandle);
      return;
     }
   
   // Variáveis do trade
   ulong positionTicket = positionId;
   string tradeType = "";
   string tradeOrigin = "EA";
   double entryPrice = 0;
   double exitPrice = 0;
   double volume = 0;
   double sl = 0;
   double tp = 0;
   double swap = 0;
   double commission = 0;
   datetime openTime = 0;
   datetime closeTime = 0;
   
   // Iterar pelos deals da posição
   for(int i = 0; i < HistoryDealsTotal(); i++)
     {
      ulong dealTicket = HistoryDealGetTicket(i);
      long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
      
      // Deal de ENTRADA
      if(dealEntry == DEAL_ENTRY_IN)
        {
         entryPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
         openTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
         volume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
         
         long dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
         tradeType = (dealType == DEAL_TYPE_BUY) ? "BUY" : "SELL";
         
         // Detectar origem pelo comentário
         string comment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
         if(StringFind(comment, "Manual") >= 0 || StringFind(comment, "Button") >= 0)
            tradeOrigin = "MANUAL";
         else
            tradeOrigin = "EA";
        }
      // Deal de SAÍDA
      else if(dealEntry == DEAL_ENTRY_OUT)
        {
         exitPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
         closeTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
         swap = HistoryDealGetDouble(dealTicket, DEAL_SWAP);
         commission = HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
         sl = HistoryDealGetDouble(dealTicket, DEAL_SL);
         tp = HistoryDealGetDouble(dealTicket, DEAL_TP);
        }
     }
   
   // Validar dados
   if(openTime == 0 || closeTime == 0)
     {
      LogWarning("Dados de tempo inválidos para posição " + IntegerToString(positionId));
      FileClose(fileHandle);
      return;
     }
   
   // Calcular duração
   int durationMinutes = (int)((closeTime - openTime) / 60);
   
   // Detectar motivo de saída (simplificado por agora)
   string exitReason = "EA";
   
   // Calcular total
   double totalProfit = profit + swap + commission;
   int spreadPoints = (int)SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
   
   // Formatar data e hora
   MqlDateTime dt;
   TimeToStruct(closeTime, dt);
   string tradeDate = StringFormat("%04d-%02d-%02d", dt.year, dt.mon, dt.day);
   string tradeTime = StringFormat("%02d:%02d:%02d", dt.hour, dt.min, dt.sec);
   
   // Escrever linha CSV
   string csvLine = StringFormat("%s,%s,%llu,%s,%.5f,%.5f,%.2f,%.5f,%.5f,%.2f,%.2f,%.2f,%.2f,%d,%d,%s,%s",
                                 tradeDate,
                                 tradeTime,
                                 positionTicket,
                                 tradeType,
                                 entryPrice,
                                 exitPrice,
                                 volume,
                                 sl,
                                 tp,
                                 profit,
                                 swap,
                                 commission,
                                 totalProfit,
                                 spreadPoints,
                                 durationMinutes,
                                 exitReason,
                                 tradeOrigin
                                );
   
   FileWriteString(fileHandle, csvLine + "\n");
   FileClose(fileHandle);

   LogInfo(StringFormat("📊 Trade salvo: #%llu | %s | %dmin | %.2f",
                        positionTicket, tradeType, durationMinutes, totalProfit));
  }

//+------------------------------------------------------------------+
//| 🆕 v3.20: Salvar TP parcial imediatamente no CSV                 |
//+------------------------------------------------------------------+
void CLogger::SavePartialTrade(ulong positionId, ulong dealTicket, string tradeType,
                               double entryPrice, double exitPrice, double volume,
                               double profit, string motivo)
  {
   // Verificar se arquivo existe (criar header se novo)
   bool fileExists = false;
   int testHandle = FileOpen(m_csvFileName, FILE_READ | FILE_CSV);
   if(testHandle != INVALID_HANDLE)
     {
      fileExists = true;
      FileClose(testHandle);
     }

   // Abrir arquivo para escrita
   int fileHandle = FileOpen(m_csvFileName, FILE_READ | FILE_WRITE | FILE_CSV);
   if(fileHandle == INVALID_HANDLE)
     {
      LogError("Erro ao abrir CSV para TP parcial: " + IntegerToString(GetLastError()));
      return;
     }

   // Escrever header se arquivo novo
   if(!fileExists)
     {
      string header = "Data,Hora,Ticket,Tipo,Entrada,Saida,Volume,SL,TP,Profit,Swap,Comissao,Total,Spread,DuracaoMin,Motivo,Origem";
      FileWriteString(fileHandle, header + "\n");
     }

   // Ir para o final do arquivo
   FileSeek(fileHandle, 0, SEEK_END);

   // Formatar data e hora atual
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   string tradeDate = StringFormat("%04d-%02d-%02d", dt.year, dt.mon, dt.day);
   string tradeTime = StringFormat("%02d:%02d:%02d", dt.hour, dt.min, dt.sec);

   // Dados simplificados para TP parcial
   int spreadPoints = (int)SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);

   // Escrever linha CSV
   // Nota: SL, TP, Swap, Comissao, DuracaoMin são 0 para parciais (não aplicável)
   string csvLine = StringFormat("%s,%s,%llu,%s,%.5f,%.5f,%.2f,%.5f,%.5f,%.2f,%.2f,%.2f,%.2f,%d,%d,%s,%s",
                                 tradeDate,
                                 tradeTime,
                                 positionId,          // Ticket da posição (não do deal)
                                 tradeType,
                                 entryPrice,
                                 exitPrice,
                                 volume,
                                 0.0,                 // SL (não aplicável)
                                 0.0,                 // TP (não aplicável)
                                 profit,
                                 0.0,                 // Swap (não aplicável)
                                 0.0,                 // Comissão (não aplicável)
                                 profit,              // Total = Profit para parciais
                                 spreadPoints,
                                 0,                   // Duração (não aplicável)
                                 motivo,              // "Partial TP1" ou "Partial TP2"
                                 "EA"
                                );

   FileWriteString(fileHandle, csvLine + "\n");
   FileClose(fileHandle);

   LogInfo(StringFormat("📊 TP Parcial salvo: #%llu | %s | %.2f lotes | $%.2f | %s",
                        positionId, tradeType, volume, profit, motivo));
  }

//+------------------------------------------------------------------+
//| Atualizar estatísticas                                           |
//+------------------------------------------------------------------+
void CLogger::UpdateStats(double profit)
  {
   m_dailyProfit += profit;
   m_dailyTrades++;
   
   // Classificar trade
   bool isBreakeven = (MathAbs(profit) < 0.01);
   
   if(isBreakeven)
     {
      m_dailyDraws++;
      LogDebug("Trade classificado como EMPATE");
     }
   else if(profit > 0)
     {
      m_dailyWins++;
      m_grossProfit += profit;
      LogDebug("Trade classificado como GANHO");
     }
   else
     {
      m_dailyLosses++;
      m_grossLoss += MathAbs(profit);
      LogDebug("Trade classificado como PERDA");
     }
   
   // Log resumo
   LogInfo(StringFormat("💰 P/L Atualizado: $%.2f | Trades: %d (%dW/%dL/%dE)",
                       GetDailyProfit(), m_dailyTrades, m_dailyWins, m_dailyLosses, m_dailyDraws));
  }

//+------------------------------------------------------------------+
//| Carregar estatísticas (v3.20 - reconhece TPs parciais)           |
//+------------------------------------------------------------------+
void CLogger::LoadDailyStats()
  {
   // Reset inicial
   m_dailyProfit = 0;
   m_partialTPProfit = 0;
   m_dailyTrades = 0;
   m_dailyWins = 0;
   m_dailyLosses = 0;
   m_dailyDraws = 0;
   m_grossProfit = 0;
   m_grossLoss = 0;

   // Tentar abrir CSV
   int fileHandle = FileOpen(m_csvFileName, FILE_READ | FILE_CSV);

   if(fileHandle == INVALID_HANDLE)
     {
      LogInfo("📂 CSV não encontrado - primeira execução do dia");
      return;
     }

   // Ler header
   string header = FileReadString(fileHandle);

   // Data de hoje (usa TimeTradeServer para data correta pré-mercado)
   MqlDateTime dt;
   TimeToStruct(GetReliableDate(), dt);
   string today = StringFormat("%04d-%02d-%02d", dt.year, dt.mon, dt.day);

   int tradesCarregados = 0;
   int parciaisCarregados = 0;

   // Ler linha por linha
   while(!FileIsEnding(fileHandle))
     {
      string line = FileReadString(fileHandle);

      if(line == "" || StringLen(line) < 10)
         continue;

      string campos[];
      int numCampos = StringSplit(line, ',', campos);

      if(numCampos < 16)  // Precisa ter campo Motivo (índice 15)
         continue;

      string tradeDate = campos[0];

      // Só processa trades de hoje
      if(tradeDate != today)
         continue;

      // Extrair dados
      double profit = StringToDouble(campos[9]);
      string motivo = campos[15];

      // ═══════════════════════════════════════════════════════════════
      // 🆕 v3.20: Detectar se é TP parcial pelo campo Motivo
      // ═══════════════════════════════════════════════════════════════
      bool isPartialTP = (StringFind(motivo, "Partial") >= 0);

      if(isPartialTP)
        {
         // TP Parcial: acumula em m_partialTPProfit, NÃO conta como trade
         m_partialTPProfit += profit;

         // 🆕 v3.21: Também atualizar m_grossProfit para relatórios corretos
         if(profit > 0)
            m_grossProfit += profit;

         parciaisCarregados++;
        }
      else
        {
         // Trade completo: lógica original
         m_dailyTrades++;
         m_dailyProfit += profit;

         // Classificar (breakeven tratado como empate)
         bool isBreakeven = (MathAbs(profit) < 0.01);

         if(isBreakeven)
           {
            m_dailyDraws++;
           }
         else if(profit > 0)
           {
            m_dailyWins++;
            m_grossProfit += profit;
           }
         else
           {
            m_dailyLosses++;
            m_grossLoss += MathAbs(profit);
           }

         tradesCarregados++;
        }
     }

   FileClose(fileHandle);

   if(tradesCarregados > 0 || parciaisCarregados > 0)
     {
      LogInfo(StringFormat("📊 Carregados: %d trades | P/L: $%.2f | %dW/%dL/%dE",
                          m_dailyTrades, m_dailyProfit, m_dailyWins, m_dailyLosses, m_dailyDraws));
      if(parciaisCarregados > 0)
         LogInfo(StringFormat("📊 TPs Parciais: %d | Lucro parcial: $%.2f | Total dia: $%.2f",
                             parciaisCarregados, m_partialTPProfit, GetDailyProfit()));
     }
  }

//+------------------------------------------------------------------+
//| Salvar relatório                                                 |
//+------------------------------------------------------------------+
void CLogger::SaveDailyReport()
  {
   LogDebug("SaveDailyReport - Gerando relatório TXT");
   
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   int fileHandle = FileOpen(m_txtFileName, FILE_WRITE | FILE_TXT);
   
   if(fileHandle == INVALID_HANDLE)
     {
      LogError("Erro ao criar relatório TXT: " + IntegerToString(GetLastError()));
      return;
     }
   
   string date = StringFormat("%02d.%02d.%04d", dt.day, dt.mon, dt.year);
   double totalDailyProfit = GetDailyProfit();  // 🆕 v3.21: Usa GetDailyProfit() para incluir TPs parciais
   double winRate = (m_dailyTrades > 0) ? (m_dailyWins * 100.0 / m_dailyTrades) : 0;
   double profitFactor = (m_grossLoss > 0) ? (m_grossProfit / m_grossLoss) : 0;
   double avgTrade = (m_dailyTrades > 0) ? (totalDailyProfit / m_dailyTrades) : 0;
   double avgWin = (m_dailyWins > 0) ? (m_grossProfit / m_dailyWins) : 0;
   double avgLoss = (m_dailyLosses > 0) ? (m_grossLoss / m_dailyLosses) : 0;
   double payoffRatio = (avgLoss > 0) ? (avgWin / avgLoss) : 0;
   
   // Cabeçalho
   FileWriteString(fileHandle, "╔========================================================╗\n");
   FileWriteString(fileHandle, "║        EPBot Matrix                                    ║\n");
   FileWriteString(fileHandle, "║        Relatório Diário de Performance                 ║\n");
   FileWriteString(fileHandle, "╚========================================================╝\n\n");
   
   FileWriteString(fileHandle, "DATA: " + date + "\n");
   FileWriteString(fileHandle, "ATIVO: " + m_symbol + "\n");
   FileWriteString(fileHandle, "MAGIC NUMBER: " + IntegerToString(m_magicNumber) + "\n\n");
   
   FileWriteString(fileHandle, "========================================================\n\n");
   
   // Configurações (placeholder)
   FileWriteString(fileHandle, GetConfigSummary());
   
   // Resumo de Trades
   FileWriteString(fileHandle, "📊 RESUMO DE TRADES\n\n");
   FileWriteString(fileHandle, "  Total de Operações: " + IntegerToString(m_dailyTrades) + "\n");
   FileWriteString(fileHandle, "  ├─ Ganhos: " + IntegerToString(m_dailyWins) + 
                   " (" + DoubleToString(winRate, 1) + "%)\n");
   FileWriteString(fileHandle, "  ├─ Perdas: " + IntegerToString(m_dailyLosses) + 
                   " (" + DoubleToString(100 - winRate, 1) + "%)\n");
   
   if(m_dailyDraws > 0)
     {
      double drawRate = (m_dailyTrades > 0) ? (m_dailyDraws * 100.0 / m_dailyTrades) : 0;
      FileWriteString(fileHandle, "  └─ Empates: " + IntegerToString(m_dailyDraws) + 
                      " (" + DoubleToString(drawRate, 1) + "%)\n\n");
     }
   else
     {
      FileWriteString(fileHandle, "  └─ Empates: 0\n\n");
     }
   
   FileWriteString(fileHandle, "========================================================\n\n");
   
   // Resultado Financeiro
   FileWriteString(fileHandle, "💰 RESULTADO FINANCEIRO\n\n");
   FileWriteString(fileHandle, "  L/P Bruto:        $" + DoubleToString(totalDailyProfit, 2) + "\n");
   FileWriteString(fileHandle, "  ──────────────────────────────────────\n");
   FileWriteString(fileHandle, "  L/P Líquido:      $" + DoubleToString(totalDailyProfit, 2) + "\n\n");
   
   FileWriteString(fileHandle, "========================================================\n\n");
   
   // Métricas de Performance
   FileWriteString(fileHandle, "📈 MÉTRICAS DE PERFORMANCE\n\n");
   FileWriteString(fileHandle, "  Ganho Total:        $" + DoubleToString(m_grossProfit, 2) + "\n");
   FileWriteString(fileHandle, "  Perda Total:        $" + DoubleToString(m_grossLoss, 2) + "\n");
   
   string pfText = "  Profit Factor:      ";
   if(m_grossLoss == 0)
     {
      if(m_grossProfit > 0)
         pfText += "∞ (100% acerto) ⭐ PERFEITO";
      else
         pfText += "N/A (sem trades)";
     }
   else
     {
      pfText += DoubleToString(profitFactor, 2);
      if(profitFactor >= 2.0)
         pfText += " ⭐ Excelente";
      else if(profitFactor >= 1.5)
         pfText += " ✓ Bom";
      else if(profitFactor >= 1.0)
         pfText += " ⚠ Regular";
      else
         pfText += " ✗ Ruim";
     }
   FileWriteString(fileHandle, pfText + "\n\n");
   
   FileWriteString(fileHandle, "  Média por Trade:    $" + DoubleToString(avgTrade, 2) + "\n");
   FileWriteString(fileHandle, "  Média de Ganho:     $" + DoubleToString(avgWin, 2) + "\n");
   FileWriteString(fileHandle, "  Média de Perda:     $" + DoubleToString(avgLoss, 2) + "\n");
   
   string payoffText = "  Payoff Ratio:       " + DoubleToString(payoffRatio, 2);
   if(m_dailyLosses > 0 && m_dailyWins > 0)
     {
      if(payoffRatio >= 1.0)
         payoffText += " (ganhos " + DoubleToString(payoffRatio, 2) + "× maiores)";
      else if(payoffRatio > 0)
        {
         double inversePayoff = 1.0 / payoffRatio;
         payoffText += " (perdas " + DoubleToString(inversePayoff, 2) + "× maiores)";
        }
     }
   FileWriteString(fileHandle, payoffText + "\n\n");
   
   FileWriteString(fileHandle, "========================================================\n\n");
   
   // Rodapé
   FileWriteString(fileHandle, "✅ FIM DO RELATÓRIO\n");
   string footerDate = StringFormat("%02d.%02d.%04d %02d:%02d:%02d",
                                    dt.day, dt.mon, dt.year, dt.hour, dt.min, dt.sec);
   FileWriteString(fileHandle, "Arquivo gerado em: " + footerDate + "\n");
   
   FileClose(fileHandle);
   
   LogInfo("📄 Relatório TXT salvo: " + m_txtFileName);
  }

//+------------------------------------------------------------------+
//| Obter resumo de configuração                                     |
//+------------------------------------------------------------------+
string CLogger::GetConfigSummary()
  {
   // Por enquanto retorna placeholder
   // Esse método será preenchido quando integrarmos com o EA principal
   // Pois precisa de acesso aos inputs do EA
   
   string config = "";
   config += "⚙️ CONFIGURAÇÕES DO ROBÔ\n\n";
   config += "  📊 Estratégia: MA Cross\n";
   config += "  🛡️ Gestão de Risco: SL/TP/Trailing\n";
   config += "  🔍 Filtros: BB, ADX, RSI, etc\n";
   config += "\n";
   config += "  (Detalhes completos serão preenchidos na integração)\n";
   config += "\n========================================================\n\n";
   
   return config;
  }

//+------------------------------------------------------------------+
//| 🆕 v3.10: Adicionar lucro de TP parcial                          |
//+------------------------------------------------------------------+
void CLogger::AddPartialTPProfit(double profit)
  {
   m_partialTPProfit += profit;

   // 🆕 v3.21: Atualizar m_grossProfit para relatórios corretos
   if(profit > 0)
      m_grossProfit += profit;

   Log(LOG_EVENT, THROTTLE_NONE, "PARTIAL_TP",
       StringFormat("🎯 Lucro parcial registrado: $%.2f | Acumulado TPs: $%.2f | Total dia: $%.2f",
                    profit, m_partialTPProfit, GetDailyProfit()));
  }

//+------------------------------------------------------------------+
//| Reset diário                                                     |
//+------------------------------------------------------------------+
void CLogger::ResetDaily()
  {
   m_dailyProfit = 0;
   m_partialTPProfit = 0;  // 🆕 v3.10
   m_dailyTrades = 0;
   m_dailyWins = 0;
   m_dailyLosses = 0;
   m_dailyDraws = 0;
   m_grossProfit = 0;
   m_grossLoss = 0;

   // Atualizar nome do arquivo TXT para o novo dia
   MqlDateTime dt;
   TimeToStruct(GetReliableDate(), dt);
   m_txtFileName = StringFormat("EPBot_Matrix_DailySummary_%s_M%d_%02d%02d%04d.txt",
                                 m_symbol, m_magicNumber, dt.day, dt.mon, dt.year);

   LogInfo("📅 Estatísticas diárias resetadas | Novo relatório: " + m_txtFileName);
  }
//+------------------------------------------------------------------+
