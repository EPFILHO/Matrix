//+------------------------------------------------------------------+
//|                                                       Logger.mqh |
//|                                         Copyright 2025, EP Filho |
//|                                Sistema de Logging - EPBot Matrix |
//|                                                      Versão 3.00 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, EP Filho"
#property link      "https://github.com/EPFILHO"
#property version   "3.00"

/*
═══════════════════════════════════════════════════════════════════════════════
   📚 GUIA DE USO DO LOGGER v3.00
═══════════════════════════════════════════════════════════════════════════════

   ┌─────────────────────────────────────────────────────────────────────────┐
   │ NÍVEIS DE LOG (hierárquicos)                                            │
   └─────────────────────────────────────────────────────────────────────────┘

   LOG_MINIMAL  → Só erros e warnings (produção silenciosa)
                  Exemplo: Spread bloqueado, erros críticos

   LOG_COMPLETE → Erros, warnings e info (padrão - produção normal)
                  Exemplo: Trades executados, sinais detectados

   LOG_DEBUG    → Tudo incluindo detalhes técnicos (desenvolvimento)
                  Exemplo: Valores calculados, estados internos

   ┌─────────────────────────────────────────────────────────────────────────┐
   │ MÉTODOS BÁSICOS                                                         │
   └─────────────────────────────────────────────────────────────────────────┘

   LogError(msg)   → ❌ SEMPRE mostra (crítico - sem verificação de nível)
   LogWarning(msg) → ⚠️  Mostra em MINIMAL ou superior
   LogInfo(msg)    → ℹ️  Mostra em COMPLETE ou superior
   LogDebug(msg)   → 🔍 Mostra SOMENTE em DEBUG

   Exemplos:
   logger.LogError("Falha ao abrir posição");           // SEMPRE aparece
   logger.LogWarning("Spread alto - trade bloqueado");  // MINIMAL+
   logger.LogInfo("Trade executado com sucesso");       // COMPLETE+
   logger.LogDebug("SL calculado: 1.2345");             // DEBUG only

   ┌─────────────────────────────────────────────────────────────────────────┐
   │ SISTEMA DE THROTTLE (anti-flood)                                        │
   └─────────────────────────────────────────────────────────────────────────┘

   Para evitar logs repetitivos, use versões "throttled":

   1️⃣ ONCE - Loga só na primeira ocorrência

      LogWarningOnce(key, msg)

      Uso: Bloqueios que podem durar vários ticks
      Exemplo:
         if(horarioBloqueado) {
             logger.LogWarningOnce("blocker_horario", "🚫 Horário de volatilidade");
         } else {
             logger.ClearOnce("blocker_horario");  // Limpa para logar de novo
         }

      Saída: Loga só quando ENTRA em bloqueio (não repete a cada tick)

   2️⃣ PER_CANDLE - Loga uma vez por candle (barra)

      LogInfoPerCandle(key, msg)

      Uso: Eventos que acontecem a cada tick mas só interessam 1x/candle
      Exemplo:
         logger.LogInfoPerCandle("no_signal", "Nenhum sinal válido detectado");

      Saída: Loga no máximo 1x por barra, mesmo sendo chamado a cada tick

   3️⃣ THROTTLED - Loga no máximo a cada X segundos

      LogDebugThrottled(key, msg, intervalSeconds)

      Uso: Logs de alta frequência (trailing, monitoring)
      Exemplo:
         logger.LogDebugThrottled("trailing", "SL: " + sl, 5);

      Saída: Loga no máximo a cada 5 segundos

   ⚠️ IMPORTANTE: A "key" deve ser ÚNICA para cada tipo de mensagem

   Versões disponíveis:
   - LogErrorOnce(key, msg)
   - LogErrorPerCandle(key, msg)
   - LogErrorThrottled(key, msg, seconds)
   - LogWarningOnce(key, msg)
   - LogWarningPerCanle(key, msg)
   - LogWarningThrottled(key, msg, seconds)
   - LogInfoOnce(key, msg)
   - LogInfoPerCandle(key, msg)
   - LogInfoThrottled(key, msg, seconds)
   - LogDebugOnce(key, msg)
   - LogDebugPerCandle(key, msg)
   - LogDebugThrottled(key, msg, seconds)

   ┌─────────────────────────────────────────────────────────────────────────┐
   │ LIMPEZA DE THROTTLE                                                     │
   └─────────────────────────────────────────────────────────────────────────┘

   ClearOnce(key)      → Limpa flag ONCE de uma key específica
   ClearAllOnce()      → Limpa todas as flags ONCE
   ClearAllThrottle()  → Limpa todo o histórico de throttle

   Uso: Para resetar throttle quando condição muda (Opção A)

═══════════════════════════════════════════════════════════════════════════════
*/

//+------------------------------------------------------------------+
//| Enum para nível de log                                           |
//+------------------------------------------------------------------+
enum ENUM_LOG_LEVEL
  {
   LOG_MINIMAL,     // Apenas erros e warnings
   LOG_COMPLETE,    // Padrão: erros, warnings e info
   LOG_DEBUG        // Tudo + detalhes técnicos
  };

//+------------------------------------------------------------------+
//| Estrutura para controle de throttle                              |
//+------------------------------------------------------------------+
struct SThrottleData
  {
   datetime          lastLogTime;      // Última vez que logou (para THROTTLED)
   int               lastBarIndex;     // Última barra que logou (para PER_CANDLE)
   bool              wasLogged;        // Flag se já logou (para ONCE)
  };

//+------------------------------------------------------------------+
//| Classe Logger - Sistema de logs e relatórios                     |
//+------------------------------------------------------------------+
class CLogger
  {
private:
   // ═══════════════════════════════════════════════════════════
   // INPUT PARAMETER (imutável - valor original)
   // ═══════════════════════════════════════════════════════════
   ENUM_LOG_LEVEL    m_inputLogLevel;
   
   // ═══════════════════════════════════════════════════════════
   // WORKING PARAMETER (mutável - usado no código)
   // ═══════════════════════════════════════════════════════════
   ENUM_LOG_LEVEL    m_logLevel;
   
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
   // CONTROLE DE THROTTLE (anti-flood) - v3.00
   // ═══════════════════════════════════════════════════════════
   string            m_throttleKeys[];       // Array de keys
   SThrottleData     m_throttleData[];       // Array de dados de throttle
   int               m_throttleCount;        // Contador de throttles registrados
   
   // ═══════════════════════════════════════════════════════════
   // ESTATÍSTICAS DO DIA
   // ═══════════════════════════════════════════════════════════
   double            m_dailyProfit;
   int               m_dailyTrades;
   int               m_dailyWins;
   int               m_dailyLosses;
   int               m_dailyDraws;
   double            m_grossProfit;
   double            m_grossLoss;

   // ═══════════════════════════════════════════════════════════
   // MÉTODOS PRIVADOS DE THROTTLE (v3.00)
   // ═══════════════════════════════════════════════════════════
   int               FindThrottleKey(string key);
   SThrottleData*    GetOrCreateThrottle(string key);
   bool              ShouldLogOnce(string key);
   bool              ShouldLogPerCandle(string key);
   bool              ShouldLogThrottled(string key, int intervalSeconds);

public:
   // ═══════════════════════════════════════════════════════════
   // CONSTRUTOR/DESTRUTOR
   // ═══════════════════════════════════════════════════════════
                     CLogger();
                    ~CLogger();
   
   // ═══════════════════════════════════════════════════════════
   // INICIALIZAÇÃO
   // ═══════════════════════════════════════════════════════════
   bool              Init(ENUM_LOG_LEVEL level, string symbol, int magic);
   
   // ═══════════════════════════════════════════════════════════
   // LOGS BÁSICOS
   // ═══════════════════════════════════════════════════════════
   void              LogInfo(string message);
   void              LogWarning(string message);
   void              LogError(string message);
   void              LogDebug(string message);

   // ═══════════════════════════════════════════════════════════
   // LOGS COM THROTTLE (v3.00 - anti-flood)
   // ═══════════════════════════════════════════════════════════

   // --- ERROR com throttle ---
   void              LogErrorOnce(string key, string message);
   void              LogErrorPerCandle(string key, string message);
   void              LogErrorThrottled(string key, string message, int intervalSeconds);

   // --- WARNING com throttle ---
   void              LogWarningOnce(string key, string message);
   void              LogWarningPerCandle(string key, string message);
   void              LogWarningThrottled(string key, string message, int intervalSeconds);

   // --- INFO com throttle ---
   void              LogInfoOnce(string key, string message);
   void              LogInfoPerCandle(string key, string message);
   void              LogInfoThrottled(string key, string message, int intervalSeconds);

   // --- DEBUG com throttle ---
   void              LogDebugOnce(string key, string message);
   void              LogDebugPerCandle(string key, string message);
   void              LogDebugThrottled(string key, string message, int intervalSeconds);

   // ═══════════════════════════════════════════════════════════
   // LIMPEZA DE THROTTLE (v3.00)
   // ═══════════════════════════════════════════════════════════
   void              ClearOnce(string key);         // Limpa flag ONCE de uma key
   void              ClearAllOnce();                // Limpa todas as flags ONCE
   void              ClearAllThrottle();            // Limpa todo histórico de throttle
   
   // ═══════════════════════════════════════════════════════════
   // TRADES
   // ═══════════════════════════════════════════════════════════
   void              SaveTrade(ulong positionId, double profit);
   void              UpdateStats(double profit);
   
   // ═══════════════════════════════════════════════════════════
   // RELATÓRIOS
   // ═══════════════════════════════════════════════════════════
   void              LoadDailyStats();
   void              SaveDailyReport();
   string            GetConfigSummary();
   
   // ═══════════════════════════════════════════════════════════
   // HOT RELOAD - Alteração em Runtime
   // ═══════════════════════════════════════════════════════════
   void              SetLogLevel(ENUM_LOG_LEVEL newLevel);
   
   // ═══════════════════════════════════════════════════════════
   // GETTERS DE ESTATÍSTICAS
   // ═══════════════════════════════════════════════════════════
   double            GetDailyProfit() { return m_dailyProfit; }
   int               GetDailyTrades() { return m_dailyTrades; }
   int               GetDailyWins() { return m_dailyWins; }
   int               GetDailyLosses() { return m_dailyLosses; }
   int               GetDailyDraws() { return m_dailyDraws; }
   
   // ═══════════════════════════════════════════════════════════
   // GETTERS DE CONFIGURAÇÃO
   // ═══════════════════════════════════════════════════════════
   ENUM_LOG_LEVEL    GetLogLevel() { return m_logLevel; }
   ENUM_LOG_LEVEL    GetInputLogLevel() { return m_inputLogLevel; }
   
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
   m_inputLogLevel = LOG_COMPLETE;
   m_logLevel = LOG_COMPLETE;

   // Inicializar throttle (v3.00)
   m_throttleCount = 0;
   ArrayResize(m_throttleKeys, 0);
   ArrayResize(m_throttleData, 0);

   m_dailyProfit = 0;
   m_dailyTrades = 0;
   m_dailyWins = 0;
   m_dailyLosses = 0;
   m_dailyDraws = 0;
   m_grossProfit = 0;
   m_grossLoss = 0;
  }

//+------------------------------------------------------------------+
//| Destrutor                                                         |
//+------------------------------------------------------------------+
CLogger::~CLogger()
  {
   // Cleanup se necessário
  }

//+------------------------------------------------------------------+
//| Inicialização                                                     |
//+------------------------------------------------------------------+
bool CLogger::Init(ENUM_LOG_LEVEL level, string symbol, int magic)
  {
   // ═══ SALVAR INPUT (valor original) ═══
   m_inputLogLevel = level;
   
   // ═══ INICIALIZAR WORKING (começa igual ao input) ═══
   m_logLevel = level;
   
   m_symbol = symbol;
   m_magicNumber = magic;
   
   // Criar nomes de arquivos
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   m_csvFileName = StringFormat("EPBot_Matrix_TradeLog_%s_M%d_%d.csv", 
                                 m_symbol, m_magicNumber, dt.year);
   
   m_txtFileName = StringFormat("EPBot_Matrix_DailySummary_%s_M%d_%02d%02d%04d.txt",
                                m_symbol, m_magicNumber, dt.day, dt.mon, dt.year);
   
   LogInfo("📂 CSV: " + m_csvFileName);
   LogInfo("📄 TXT: " + m_txtFileName);
   
   // Carregar estatísticas do dia (se existirem)
   LoadDailyStats();
   
   Print("✅ Logger inicializado - Nível: ", EnumToString(m_logLevel));
   return true;
  }

//+------------------------------------------------------------------+
//| Hot Reload - Alterar nível de log em runtime                     |
//+------------------------------------------------------------------+
void CLogger::SetLogLevel(ENUM_LOG_LEVEL newLevel)
  {
   ENUM_LOG_LEVEL oldLevel = m_logLevel;
   m_logLevel = newLevel;
   
   LogInfo(StringFormat("🔄 Nível de log alterado: %s → %s", 
                        EnumToString(oldLevel), 
                        EnumToString(newLevel)));
  }

//+------------------------------------------------------------------+
//| Log de informação (v3.00 - corrigido hierarquia)                 |
//+------------------------------------------------------------------+
void CLogger::LogInfo(string message)
  {
   if(m_logLevel >= LOG_COMPLETE)  // ✅ CORRIGIDO: era LOG_MINIMAL
     {
      Print("ℹ️ [INFO] ", message);
     }
  }

//+------------------------------------------------------------------+
//| Log de aviso (v3.00 - corrigido hierarquia)                      |
//+------------------------------------------------------------------+
void CLogger::LogWarning(string message)
  {
   if(m_logLevel >= LOG_MINIMAL)  // ✅ OK: continua MINIMAL
     {
      Print("⚠️ [WARN] ", message);
     }
  }

//+------------------------------------------------------------------+
//| Log de erro (v3.00 - corrigido hierarquia)                       |
//+------------------------------------------------------------------+
void CLogger::LogError(string message)
  {
   // ✅ CORRIGIDO: SEMPRE mostra erro (sem verificação de nível)
   Print("❌ [ERROR] ", message);
  }

//+------------------------------------------------------------------+
//| Log de debug (v3.00 - já estava correto)                         |
//+------------------------------------------------------------------+
void CLogger::LogDebug(string message)
  {
   if(m_logLevel >= LOG_DEBUG)  // ✅ OK: só em DEBUG
     {
      Print("🔍 [DEBUG] ", message);
     }
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
                       m_dailyProfit, m_dailyTrades, m_dailyWins, m_dailyLosses, m_dailyDraws));
  }

//+------------------------------------------------------------------+
//| Carregar estatísticas                                            |
//+------------------------------------------------------------------+
void CLogger::LoadDailyStats()
  {
   // Reset inicial
   m_dailyProfit = 0;
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
   
   // Data de hoje
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   string today = StringFormat("%04d-%02d-%02d", dt.year, dt.mon, dt.day);
   
   int tradesCarregados = 0;
   
   // Ler linha por linha
   while(!FileIsEnding(fileHandle))
     {
      string line = FileReadString(fileHandle);
      
      if(line == "" || StringLen(line) < 10)
         continue;
      
      string campos[];
      int numCampos = StringSplit(line, ',', campos);
      
      if(numCampos < 13)
         continue;
      
      string tradeDate = campos[0];
      
      // Só processa trades de hoje
      if(tradeDate != today)
         continue;
      
      // Extrair dados
      double profit = StringToDouble(campos[9]);
      
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
   
   FileClose(fileHandle);
   
   if(tradesCarregados > 0)
     {
      LogInfo(StringFormat("📊 Carregados: %d trades | P/L: $%.2f | %dW/%dL/%dE",
                          m_dailyTrades, m_dailyProfit, m_dailyWins, m_dailyLosses, m_dailyDraws));
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
   double winRate = (m_dailyTrades > 0) ? (m_dailyWins * 100.0 / m_dailyTrades) : 0;
   double profitFactor = (m_grossLoss > 0) ? (m_grossProfit / m_grossLoss) : 0;
   double avgTrade = (m_dailyTrades > 0) ? (m_dailyProfit / m_dailyTrades) : 0;
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
   FileWriteString(fileHandle, "  L/P Bruto:        $" + DoubleToString(m_dailyProfit, 2) + "\n");
   FileWriteString(fileHandle, "  ──────────────────────────────────────\n");
   FileWriteString(fileHandle, "  L/P Líquido:      $" + DoubleToString(m_dailyProfit, 2) + "\n\n");
   
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
//| Reset diário                                                     |
//+------------------------------------------------------------------+
void CLogger::ResetDaily()
  {
   m_dailyProfit = 0;
   m_dailyTrades = 0;
   m_dailyWins = 0;
   m_dailyLosses = 0;
   m_dailyDraws = 0;
   m_grossProfit = 0;
   m_grossLoss = 0;

   LogInfo("📅 Estatísticas diárias resetadas");
  }

//+------------------------------------------------------------------+
//| MÉTODOS PRIVADOS DE THROTTLE (v3.00)                             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Encontrar índice da key no array de throttle                     |
//+------------------------------------------------------------------+
int CLogger::FindThrottleKey(string key)
  {
   for(int i = 0; i < m_throttleCount; i++)
     {
      if(m_throttleKeys[i] == key)
         return i;
     }
   return -1;  // Não encontrado
  }

//+------------------------------------------------------------------+
//| Obter ou criar entrada de throttle para uma key                  |
//+------------------------------------------------------------------+
SThrottleData* CLogger::GetOrCreateThrottle(string key)
  {
   int index = FindThrottleKey(key);

   // Se já existe, retorna ponteiro
   if(index >= 0)
      return GetPointer(m_throttleData[index]);

   // Não existe - criar novo
   m_throttleCount++;
   ArrayResize(m_throttleKeys, m_throttleCount);
   ArrayResize(m_throttleData, m_throttleCount);

   m_throttleKeys[m_throttleCount - 1] = key;

   // Inicializar nova entrada
   m_throttleData[m_throttleCount - 1].lastLogTime = 0;
   m_throttleData[m_throttleCount - 1].lastBarIndex = -1;
   m_throttleData[m_throttleCount - 1].wasLogged = false;

   return GetPointer(m_throttleData[m_throttleCount - 1]);
  }

//+------------------------------------------------------------------+
//| Verificar se deve logar (ONCE)                                   |
//+------------------------------------------------------------------+
bool CLogger::ShouldLogOnce(string key)
  {
   SThrottleData* throttle = GetOrCreateThrottle(key);

   if(!throttle.wasLogged)
     {
      throttle.wasLogged = true;  // Marca como logado
      return true;                // Loga desta vez
     }

   return false;  // Já logou, não loga de novo
  }

//+------------------------------------------------------------------+
//| Verificar se deve logar (PER_CANDLE)                             |
//+------------------------------------------------------------------+
bool CLogger::ShouldLogPerCandle(string key)
  {
   SThrottleData* throttle = GetOrCreateThrottle(key);

   int currentBar = Bars(_Symbol, PERIOD_CURRENT);

   // Se é uma nova barra, permite logar
   if(throttle.lastBarIndex != currentBar)
     {
      throttle.lastBarIndex = currentBar;
      return true;
     }

   return false;  // Mesma barra, não loga
  }

//+------------------------------------------------------------------+
//| Verificar se deve logar (THROTTLED por tempo)                    |
//+------------------------------------------------------------------+
bool CLogger::ShouldLogThrottled(string key, int intervalSeconds)
  {
   SThrottleData* throttle = GetOrCreateThrottle(key);

   datetime now = TimeCurrent();

   // Se passou tempo suficiente, permite logar
   if((now - throttle.lastLogTime) >= intervalSeconds)
     {
      throttle.lastLogTime = now;
      return true;
     }

   return false;  // Ainda em throttle, não loga
  }

//+------------------------------------------------------------------+
//| MÉTODOS PÚBLICOS DE THROTTLE - ERROR                             |
//+------------------------------------------------------------------+

void CLogger::LogErrorOnce(string key, string message)
  {
   if(ShouldLogOnce(key))
      LogError(message);
  }

void CLogger::LogErrorPerCandle(string key, string message)
  {
   if(ShouldLogPerCandle(key))
      LogError(message);
  }

void CLogger::LogErrorThrottled(string key, string message, int intervalSeconds)
  {
   if(ShouldLogThrottled(key, intervalSeconds))
      LogError(message);
  }

//+------------------------------------------------------------------+
//| MÉTODOS PÚBLICOS DE THROTTLE - WARNING                           |
//+------------------------------------------------------------------+

void CLogger::LogWarningOnce(string key, string message)
  {
   if(ShouldLogOnce(key))
      LogWarning(message);
  }

void CLogger::LogWarningPerCandle(string key, string message)
  {
   if(ShouldLogPerCandle(key))
      LogWarning(message);
  }

void CLogger::LogWarningThrottled(string key, string message, int intervalSeconds)
  {
   if(ShouldLogThrottled(key, intervalSeconds))
      LogWarning(message);
  }

//+------------------------------------------------------------------+
//| MÉTODOS PÚBLICOS DE THROTTLE - INFO                              |
//+------------------------------------------------------------------+

void CLogger::LogInfoOnce(string key, string message)
  {
   if(ShouldLogOnce(key))
      LogInfo(message);
  }

void CLogger::LogInfoPerCandle(string key, string message)
  {
   if(ShouldLogPerCandle(key))
      LogInfo(message);
  }

void CLogger::LogInfoThrottled(string key, string message, int intervalSeconds)
  {
   if(ShouldLogThrottled(key, intervalSeconds))
      LogInfo(message);
  }

//+------------------------------------------------------------------+
//| MÉTODOS PÚBLICOS DE THROTTLE - DEBUG                             |
//+------------------------------------------------------------------+

void CLogger::LogDebugOnce(string key, string message)
  {
   if(ShouldLogOnce(key))
      LogDebug(message);
  }

void CLogger::LogDebugPerCandle(string key, string message)
  {
   if(ShouldLogPerCandle(key))
      LogDebug(message);
  }

void CLogger::LogDebugThrottled(string key, string message, int intervalSeconds)
  {
   if(ShouldLogThrottled(key, intervalSeconds))
      LogDebug(message);
  }

//+------------------------------------------------------------------+
//| LIMPEZA DE THROTTLE                                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Limpar flag ONCE de uma key específica (Opção A)                 |
//+------------------------------------------------------------------+
void CLogger::ClearOnce(string key)
  {
   int index = FindThrottleKey(key);
   if(index >= 0)
     {
      m_throttleData[index].wasLogged = false;
     }
  }

//+------------------------------------------------------------------+
//| Limpar todas as flags ONCE                                       |
//+------------------------------------------------------------------+
void CLogger::ClearAllOnce()
  {
   for(int i = 0; i < m_throttleCount; i++)
     {
      m_throttleData[i].wasLogged = false;
     }
  }

//+------------------------------------------------------------------+
//| Limpar todo o histórico de throttle                              |
//+------------------------------------------------------------------+
void CLogger::ClearAllThrottle()
  {
   m_throttleCount = 0;
   ArrayResize(m_throttleKeys, 0);
   ArrayResize(m_throttleData, 0);
  }

//+------------------------------------------------------------------+
