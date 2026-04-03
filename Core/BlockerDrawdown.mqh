//+------------------------------------------------------------------+
//|                                           BlockerDrawdown.mqh    |
//|                                        Copyright 2026, EP Filho  |
//|           Proteção de Drawdown - EPBot Matrix                    |
//|                       Versão 1.02 - Claude Parte 032             |
//+------------------------------------------------------------------+
// NOTA: Enums (ENUM_DRAWDOWN_TYPE, ENUM_DRAWDOWN_PEAK_MODE, etc.) e
// Logger.mqh são incluídos por Blockers.mqh ANTES deste arquivo.

// ═══════════════════════════════════════════════════════════════
// CHANGELOG v1.02 (Parte 032):
// + FIX: ShouldCloseByDrawdown() + CheckDrawdownWithLog() — agora
//   incluem POSITION_COMMISSION no projectedProfit. Em contas com
//   comissão por operação, o drawdown projetado estava subestimado.
//
// + FIX: ActivateDrawdownProtection() — o pico inicial no modo
//   DD_PEAK_PROJECTED agora recebe o projectedProfit com commission
//   já incluída (responsabilidade do chamador). Documentado no header.
//
// + FIX: TryActivateDrawdownNow() — calcula floating+swap+commission
//   da posição aberta antes de chamar ActivateDrawdownProtection,
//   evitando pico subavaliado no modo DD_PEAK_PROJECTED em hot reload.
//
// + FIX: CheckDrawdownWithLog() — pico só avança se
//   m_drawdownProtectionActive == true. Impede inflação artificial
//   do pico enquanto EA está bloqueado por outro motivo.
//
// + FIX: Drawdown percentual com pico == 0: ddLimit calculado como 0
//   disparava bloqueio imediato mesmo sem queda. Adicionado guard:
//   se m_dailyPeakProfit <= 0, retorna true (sem bloqueio).
//
// + FIX: ResetDaily() — reseta m_sLastDebugLog para evitar supressão
//   do primeiro log de debug do novo dia.
// ═══════════════════════════════════════════════════════════════
// CHANGELOG v1.01 (Parte 027):
// + SetMagicNumber(int newMagic): hot reload do Magic Number
//   Reseta peak/drawdown state (peak calculado com magic antigo é inválido)
// ═══════════════════════════════════════════════════════════════

#ifndef BLOCKER_DRAWDOWN_MQH
#define BLOCKER_DRAWDOWN_MQH

//+------------------------------------------------------------------+
//| Classe: CBlockerDrawdown                                         |
//| Proteção de drawdown diário                                      |
//+------------------------------------------------------------------+
class CBlockerDrawdown
  {
private:
   CLogger*                  m_logger;
   int                       m_magicNumber;

   // ═══════════════════════════════════════════════════════════════
   // INPUT PARAMETERS - DRAWDOWN
   // ═══════════════════════════════════════════════════════════════
   bool                      m_inputEnableDrawdown;
   ENUM_DRAWDOWN_TYPE        m_inputDrawdownType;
   double                    m_inputDrawdownValue;
   double                    m_inputInitialBalance;
   ENUM_DRAWDOWN_PEAK_MODE   m_inputDrawdownPeakMode;

   // ═══════════════════════════════════════════════════════════════
   // WORKING PARAMETERS - DRAWDOWN
   // ═══════════════════════════════════════════════════════════════
   bool                      m_enableDrawdown;
   ENUM_DRAWDOWN_TYPE        m_drawdownType;
   double                    m_drawdownValue;
   double                    m_initialBalance;
   double                    m_peakBalance;
   ENUM_DRAWDOWN_PEAK_MODE   m_drawdownPeakMode;

   // ═══════════════════════════════════════════════════════════════
   // ESTADO INTERNO
   // ═══════════════════════════════════════════════════════════════
   double                    m_dailyPeakProfit;
   bool                      m_drawdownProtectionActive;
   bool                      m_drawdownLimitReached;
   datetime                  m_drawdownActivationTime;

   // Transition state
   datetime                  m_sLastDebugLog;

public:
                     CBlockerDrawdown();
                    ~CBlockerDrawdown();

   bool              Init(
      CLogger*       logger,
      int            magicNumber,
      bool           enableDD,
      ENUM_DRAWDOWN_TYPE ddType,
      double         ddValue,
      ENUM_DRAWDOWN_PEAK_MODE ddPeakMode
   );

   // ═══════════════════════════════════════════════════════════════
   // VERIFICAÇÃO PARA CanTrade (chamada por CBlockers)
   // ═══════════════════════════════════════════════════════════════
   bool              CheckDrawdownWithLog(ENUM_BLOCKER_REASON &blocker, string &blockReason);

   // ═══════════════════════════════════════════════════════════════
   // FECHAMENTO DE POSIÇÃO
   // ═══════════════════════════════════════════════════════════════
   bool              ShouldCloseByDrawdown(ulong positionTicket, double dailyProfit,
                                           string &closeReason);

   // ═══════════════════════════════════════════════════════════════
   // ATIVAÇÃO E ATUALIZAÇÃO
   // NOTA: projectedProfit deve incluir floating + swap + commission
   // ═══════════════════════════════════════════════════════════════
   void              ActivateDrawdownProtection(double closedProfit, double projectedProfit);
   void              TryActivateDrawdownNow(double dailyProfit);
   void              UpdatePeakBalance(double currentBalance);
   void              UpdatePeakProfit(double currentProfit);

   // ═══════════════════════════════════════════════════════════════
   // HOT RELOAD
   // ═══════════════════════════════════════════════════════════════
   void              SetMagicNumber(int newMagic);
   void              SetDrawdownValue(double newValue);
   void              SetDrawdownType(ENUM_DRAWDOWN_TYPE newType);
   void              SetDrawdownPeakMode(ENUM_DRAWDOWN_PEAK_MODE newMode);

   // ═══════════════════════════════════════════════════════════════
   // RESET DIÁRIO
   // ═══════════════════════════════════════════════════════════════
   void              ResetDaily();

   // ═══════════════════════════════════════════════════════════════
   // GETTERS
   // ═══════════════════════════════════════════════════════════════
   double            GetCurrentDrawdown();
   double            GetDailyPeakProfit()           const { return m_dailyPeakProfit;           }
   bool              IsDrawdownProtectionActive()   const { return m_drawdownProtectionActive;   }
   bool              IsDrawdownLimitReached()       const { return m_drawdownLimitReached;       }
   ENUM_DRAWDOWN_TYPE GetDrawdownType()             const { return m_drawdownType;               }
   double            GetDrawdownValue()             const { return m_drawdownValue;              }
   ENUM_DRAWDOWN_PEAK_MODE GetDrawdownPeakMode()   const { return m_drawdownPeakMode;           }
  };

//+------------------------------------------------------------------+
//| Construtor                                                       |
//+------------------------------------------------------------------+
CBlockerDrawdown::CBlockerDrawdown()
  {
   m_logger      = NULL;
   m_magicNumber = 0;

   m_inputEnableDrawdown  = false;
   m_inputDrawdownType    = DD_FINANCIAL;
   m_inputDrawdownValue   = 0.0;
   m_inputInitialBalance  = 0.0;
   m_inputDrawdownPeakMode = DD_PEAK_REALIZED_ONLY;

   m_enableDrawdown   = false;
   m_drawdownType     = DD_FINANCIAL;
   m_drawdownValue    = 0.0;
   m_initialBalance   = 0.0;
   m_peakBalance      = 0.0;
   m_drawdownPeakMode = DD_PEAK_REALIZED_ONLY;

   m_dailyPeakProfit          = 0.0;
   m_drawdownProtectionActive = false;
   m_drawdownLimitReached     = false;
   m_drawdownActivationTime   = 0;
   m_sLastDebugLog            = 0;
  }

//+------------------------------------------------------------------+
//| Destrutor                                                        |
//+------------------------------------------------------------------+
CBlockerDrawdown::~CBlockerDrawdown()
  {
  }

//+------------------------------------------------------------------+
//| Inicialização                                                    |
//+------------------------------------------------------------------+
bool CBlockerDrawdown::Init(
   CLogger*       logger,
   int            magicNumber,
   bool           enableDD,
   ENUM_DRAWDOWN_TYPE ddType,
   double         ddValue,
   ENUM_DRAWDOWN_PEAK_MODE ddPeakMode
)
  {
   m_logger      = logger;
   m_magicNumber = magicNumber;

   m_inputEnableDrawdown   = enableDD;
   m_inputDrawdownType     = ddType;
   m_inputDrawdownValue    = ddValue;
   m_inputDrawdownPeakMode = ddPeakMode;
   m_enableDrawdown        = enableDD;
   m_drawdownType          = ddType;
   m_drawdownValue         = ddValue;
   m_drawdownPeakMode      = ddPeakMode;

   if(enableDD)
     {
      if(ddValue <= 0 || (ddType == DD_PERCENTAGE && ddValue > 100))
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Drawdown inválido!");
         else
            Print("❌ Drawdown inválido!");
         return false;
        }

      double autoBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      if(autoBalance <= 0)
        {
         if(m_logger != NULL)
            m_logger.Log(LOG_ERROR, THROTTLE_NONE, "INIT", "Saldo da conta inválido (zero ou negativo)!");
         else
            Print("❌ Saldo da conta inválido (zero ou negativo)!");
         return false;
        }

      m_inputInitialBalance = autoBalance;
      m_initialBalance      = autoBalance;
      m_peakBalance         = autoBalance;

      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📉 Drawdown Máximo:");
      else
         Print("📉 Drawdown Máximo:");

      string typeMsg = (ddType == DD_FINANCIAL)
                       ? "   - Tipo: Financeiro ($" + DoubleToString(ddValue, 2) + ")"
                       : "   - Tipo: Percentual (" + DoubleToString(ddValue, 2) + "%)";
      if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", typeMsg);
      else Print(typeMsg);

      string balMsg = "   - Saldo Inicial (auto): $" + DoubleToString(autoBalance, 2);
      if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", balMsg);
      else Print(balMsg);

      string peakMsg = (ddPeakMode == DD_PEAK_REALIZED_ONLY)
                       ? "   - Pico: Apenas Lucro Realizado (fechados)"
                       : "   - Pico: Incluir P/L Flutuante (fechados + aberta)";
      if(m_logger != NULL) m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", peakMsg);
      else Print(peakMsg);
     }
   else
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "INIT", "📉 Proteção Drawdown: DESATIVADA");
      else
         Print("📉 Proteção Drawdown: DESATIVADA");
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Verifica limite de drawdown com logging (para CanTrade)          |
//+------------------------------------------------------------------+
bool CBlockerDrawdown::CheckDrawdownWithLog(ENUM_BLOCKER_REASON &blocker, string &blockReason)
  {
   if(!m_drawdownProtectionActive)
      return true;

   if(m_drawdownLimitReached)
     {
      blocker     = BLOCKER_DRAWDOWN;
      blockReason = StringFormat("Drawdown %.2f%% excedido", GetCurrentDrawdown());
      return false;
     }

   double dailyProfit = (m_logger != NULL) ? m_logger.GetDailyProfit() : 0.0;
   double floating    = 0.0;
   double swap        = 0.0;
   double commission  = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
        {
         floating   += PositionGetDouble(POSITION_PROFIT);
         swap       += PositionGetDouble(POSITION_SWAP);
         commission += PositionGetDouble(POSITION_COMMISSION);  // FIX v1.02
        }
     }

   double projectedProfit = dailyProfit + floating + swap + commission;

   // FIX v1.02: pico só avança quando proteção está ativa
   double peakCandidate = (m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY)
                          ? dailyProfit : projectedProfit;
   if(peakCandidate > m_dailyPeakProfit)
      m_dailyPeakProfit = peakCandidate;

   // FIX v1.02: guard pico zero — evita falso positivo no percentual
   if(m_dailyPeakProfit <= 0)
      return true;

   double currentDD = m_dailyPeakProfit - projectedProfit;
   double ddLimit   = (m_drawdownType == DD_FINANCIAL)
                      ? m_drawdownValue
                      : (m_dailyPeakProfit * m_drawdownValue) / 100.0;

   if(currentDD >= ddLimit)
     {
      m_drawdownLimitReached = true;
      blocker     = BLOCKER_DRAWDOWN;
      blockReason = StringFormat("Drawdown %.2f%% excedido", GetCurrentDrawdown());

      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "═══════════════════════════════════════════════════════");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "🛑 LIMITE DE DRAWDOWN ATINGIDO!");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "   📊 Pico do dia: $"  + DoubleToString(m_dailyPeakProfit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "   💰 Lucro atual: $"  + DoubleToString(projectedProfit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "   📉 Drawdown: $"     + DoubleToString(currentDD, 2));
         if(m_drawdownType == DD_FINANCIAL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "   🛑 Limite: $" + DoubleToString(ddLimit, 2) + " (Financeiro)");
         else
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "   🛑 Limite: " + DoubleToString(m_drawdownValue, 1) + "% = $" + DoubleToString(ddLimit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "   🛡️ LUCRO PROTEGIDO! EA pausado até o fim do dia");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "═══════════════════════════════════════════════════════");
        }
      else
        {
         Print("🛑 LIMITE DE DRAWDOWN ATINGIDO! Pico=$", DoubleToString(m_dailyPeakProfit,2),
               " Atual=$", DoubleToString(projectedProfit,2),
               " DD=$", DoubleToString(currentDD,2));
        }
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Verifica se deve fechar posição por drawdown                     |
//+------------------------------------------------------------------+
bool CBlockerDrawdown::ShouldCloseByDrawdown(ulong positionTicket, double dailyProfit,
                                              string &closeReason)
  {
   closeReason = "";

   if(!m_drawdownProtectionActive)
      return false;

   if(m_drawdownLimitReached)
      return false;

   if(!PositionSelectByTicket(positionTicket))
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DRAWDOWN",
                      "Erro ao selecionar posição #" + IntegerToString((int)positionTicket));
      return false;
     }

   long posMagic = PositionGetInteger(POSITION_MAGIC);
   if(posMagic != m_magicNumber)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DRAWDOWN",
                      "Ignorando posição #" + IntegerToString((int)positionTicket) +
                      " (Magic " + IntegerToString((int)posMagic) +
                      " ≠ " + IntegerToString(m_magicNumber) + ")");
      return false;
     }

   double currentProfit = PositionGetDouble(POSITION_PROFIT);
   double swap          = PositionGetDouble(POSITION_SWAP);
   double commission    = PositionGetDouble(POSITION_COMMISSION);  // FIX v1.02
   double projectedProfit = dailyProfit + currentProfit + swap + commission;

   // Atualizar pico
   double peakCandidate = (m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY)
                          ? dailyProfit : projectedProfit;
   if(peakCandidate > m_dailyPeakProfit)
     {
      m_dailyPeakProfit = peakCandidate;
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_TIME, "DRAWDOWN",
                      "🔼 Novo pico de lucro: $" + DoubleToString(m_dailyPeakProfit, 2), 60);
     }

   // Debug log a cada 60s
   if(TimeCurrent() - m_sLastDebugLog >= 60)
     {
      // FIX v1.02: guard pico zero no log também
      double ddLimit_dbg = 0.0;
      if(m_dailyPeakProfit > 0)
         ddLimit_dbg = (m_drawdownType == DD_FINANCIAL)
                       ? m_drawdownValue
                       : (m_dailyPeakProfit * m_drawdownValue) / 100.0;

      double currentDD_dbg = m_dailyPeakProfit - projectedProfit;
      if(m_logger != NULL)
         m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "DRAWDOWN",
                      StringFormat("📊 Drawdown: Pico=%.2f | Projetado=%.2f | DD=%.2f / %.2f",
                                   m_dailyPeakProfit, projectedProfit, currentDD_dbg, ddLimit_dbg));
      m_sLastDebugLog = TimeCurrent();
     }

   // FIX v1.02: guard pico zero
   if(m_dailyPeakProfit <= 0)
      return false;

   double currentDD = m_dailyPeakProfit - projectedProfit;
   double ddLimit   = (m_drawdownType == DD_FINANCIAL)
                      ? m_drawdownValue
                      : (m_dailyPeakProfit * m_drawdownValue) / 100.0;

   if(currentDD >= ddLimit)
     {
      m_drawdownLimitReached = true;

      if(m_drawdownType == DD_FINANCIAL)
         closeReason = StringFormat("LIMITE DE DRAWDOWN ATINGIDO: %.2f / %.2f (Financeiro)",
                                    currentDD, ddLimit);
      else
        {
         double ddPercent = (currentDD / m_dailyPeakProfit) * 100.0;
         closeReason = StringFormat("LIMITE DE DRAWDOWN ATINGIDO: %.1f%% / %.1f%%",
                                    ddPercent, m_drawdownValue);
        }

      if(m_logger != NULL)
        {
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "════════════════════════════════════════════════════════════════");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "🛑 LIMITE DE DRAWDOWN ATINGIDO!");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "   📊 Pico do dia: $"     + DoubleToString(m_dailyPeakProfit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "   💰 Lucro projetado: $" + DoubleToString(projectedProfit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "   📉 Drawdown atual: $"  + DoubleToString(currentDD, 2));
         if(m_drawdownType == DD_FINANCIAL)
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                         "   🛑 Limite: $" + DoubleToString(ddLimit, 2) + " (Financeiro)");
         else
           {
            double ddPercent = (currentDD / m_dailyPeakProfit) * 100.0;
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                         StringFormat("   🛑 Limite: %.1f%% = $%.2f", m_drawdownValue, ddLimit));
            m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                         StringFormat("   📊 DD atual: %.1f%%", ddPercent));
           }
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                      "   📊 Composição: Fechados=$" + DoubleToString(dailyProfit, 2) +
                      " + Aberta=$"  + DoubleToString(currentProfit, 2) +
                      " + Swap=$"    + DoubleToString(swap, 2) +
                      " + Comissão=$" + DoubleToString(commission, 2));  // FIX v1.02
         string modeStr = (m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY) ? "realizado" : "projetado";
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                      "   🛡️ Ativado às " + TimeToString(m_drawdownActivationTime, TIME_MINUTES) +
                      " | Pico inicial (" + modeStr + "): $" + DoubleToString(m_dailyPeakProfit, 2));
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "   🛡️ LUCRO PROTEGIDO! Fechando posição IMEDIATAMENTE");
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "════════════════════════════════════════════════════════════════");
        }
      else
        {
         Print("🛑 LIMITE DE DRAWDOWN ATINGIDO! Pico=$", DoubleToString(m_dailyPeakProfit,2),
               " Projetado=$", DoubleToString(projectedProfit,2),
               " DD=$", DoubleToString(currentDD,2));
        }
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Ativa proteção de drawdown (após atingir meta)                   |
//| NOTA: projectedProfit deve incluir floating + swap + commission  |
//+------------------------------------------------------------------+
void CBlockerDrawdown::ActivateDrawdownProtection(double closedProfit, double projectedProfit)
  {
   if(!m_enableDrawdown)
      return;

   m_drawdownProtectionActive = true;
   m_drawdownActivationTime   = TimeCurrent();

   if(m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY)
      m_dailyPeakProfit = closedProfit;
   else
      m_dailyPeakProfit = projectedProfit;

   string modeStr = (m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY) ? "realizado" : "projetado";

   if(m_logger != NULL)
     {
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "═══════════════════════════════════════════════════════");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "🛡️ PROTEÇÃO DE DRAWDOWN ATIVADA!");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                   "   Pico de lucro (" + modeStr + "): $" + DoubleToString(m_dailyPeakProfit, 2));
      if(m_drawdownPeakMode == DD_PEAK_REALIZED_ONLY)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                      "   📊 Fechados: $" + DoubleToString(closedProfit, 2) +
                      " | Projetado: $" + DoubleToString(projectedProfit, 2));
      if(m_drawdownType == DD_FINANCIAL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                      "   Proteção: Máx $" + DoubleToString(m_drawdownValue, 2) + " de drawdown");
      else
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN",
                      "   Proteção: Máx " + DoubleToString(m_drawdownValue, 1) + "% de drawdown");
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "DRAWDOWN", "═══════════════════════════════════════════════════════");
     }
   else
     {
      Print("═══════════════════════════════════════════════════════");
      Print("🛡️ PROTEÇÃO DE DRAWDOWN ATIVADA!");
      Print("   Pico de lucro (", modeStr, "): $", DoubleToString(m_dailyPeakProfit, 2));
      if(m_drawdownType == DD_FINANCIAL)
         Print("   Proteção: Máx $", DoubleToString(m_drawdownValue, 2), " de drawdown");
      else
         Print("   Proteção: Máx ", DoubleToString(m_drawdownValue, 1), "% de drawdown");
      Print("═══════════════════════════════════════════════════════");
     }
  }

//+------------------------------------------------------------------+
//| Tenta ativar proteção imediatamente via hot reload               |
//| FIX v1.02: calcula floating+swap+commission antes de ativar     |
//+------------------------------------------------------------------+
void CBlockerDrawdown::TryActivateDrawdownNow(double dailyProfit)
  {
   if(!m_enableDrawdown || m_drawdownProtectionActive)
      return;

   // FIX v1.02: calcular projectedProfit corretamente
   double floating   = 0.0;
   double swap       = 0.0;
   double commission = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
        {
         floating   += PositionGetDouble(POSITION_PROFIT);
         swap       += PositionGetDouble(POSITION_SWAP);
         commission += PositionGetDouble(POSITION_COMMISSION);
        }
     }

   double projectedProfit = dailyProfit + floating + swap + commission;
   ActivateDrawdownProtection(dailyProfit, projectedProfit);

   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
                   "🛡️ Drawdown ativado via hot reload — pico inicial: $" +
                   DoubleToString(m_dailyPeakProfit, 2));
   else
      Print("🛡️ Drawdown ativado via hot reload — pico inicial: $", m_dailyPeakProfit);
  }

//+------------------------------------------------------------------+
//| Atualiza pico de saldo                                           |
//+------------------------------------------------------------------+
void CBlockerDrawdown::UpdatePeakBalance(double currentBalance)
  {
   if(!m_enableDrawdown)
      return;
   if(currentBalance > m_peakBalance)
      m_peakBalance = currentBalance;
  }

//+------------------------------------------------------------------+
//| Atualiza pico de lucro diário                                    |
//+------------------------------------------------------------------+
void CBlockerDrawdown::UpdatePeakProfit(double currentProfit)
  {
   if(currentProfit > m_dailyPeakProfit)
      m_dailyPeakProfit = currentProfit;
  }

//+------------------------------------------------------------------+
//| Hot Reload — Valor de drawdown                                   |
//+------------------------------------------------------------------+
void CBlockerDrawdown::SetDrawdownValue(double newValue)
  {
   double oldValue  = m_drawdownValue;
   bool   oldEnabled = m_enableDrawdown;

   m_drawdownValue  = newValue;
   m_enableDrawdown = (newValue > 0);

   if(oldValue != newValue)
     {
      string typeText = (m_drawdownType == DD_FINANCIAL) ? "$" : "%";
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
                      StringFormat("Drawdown alterado: %s%.2f → %s%.2f",
                                   typeText, oldValue, typeText, newValue));
      else
         Print("🔄 Drawdown alterado: ", typeText, oldValue, " → ", typeText, newValue);
     }

   if(oldEnabled != m_enableDrawdown)
     {
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
                      "Drawdown: " + (m_enableDrawdown ? "ATIVADO" : "DESATIVADO"));
      else
         Print("🔄 Drawdown: ", m_enableDrawdown ? "ATIVADO" : "DESATIVADO");
     }

   if(m_drawdownLimitReached && oldValue != newValue)
     {
      m_drawdownLimitReached = false;
      if(m_logger != NULL)
         m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD",
                      "▶️ Bloqueio de drawdown liberado — novo limite será reavaliado no próximo tick");
      else
         Print("▶️ Bloqueio de drawdown liberado");
     }
  }

//+------------------------------------------------------------------+
//| Hot Reload — Tipo de drawdown                                    |
//+------------------------------------------------------------------+
void CBlockerDrawdown::SetDrawdownType(ENUM_DRAWDOWN_TYPE newType)
  {
   if(m_drawdownType == newType)
      return;
   m_drawdownType = newType;
   string typeText = (newType == DD_FINANCIAL) ? "FINANCEIRO ($)" : "PERCENTUAL (%)";
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "DrawdownType: " + typeText);
   else
      Print("🔄 DrawdownType: ", typeText);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Modo de pico                                        |
//+------------------------------------------------------------------+
void CBlockerDrawdown::SetDrawdownPeakMode(ENUM_DRAWDOWN_PEAK_MODE newMode)
  {
   if(m_drawdownPeakMode == newMode)
      return;
   m_drawdownPeakMode = newMode;
   string modeText = (newMode == DD_PEAK_REALIZED_ONLY) ? "SÓ REALIZADO" : "C/ FLUTUANTE";
   if(m_logger != NULL)
      m_logger.Log(LOG_EVENT, THROTTLE_NONE, "HOT_RELOAD", "DrawdownPeakMode: " + modeText);
   else
      Print("🔄 DrawdownPeakMode: ", modeText);
  }

//+------------------------------------------------------------------+
//| Hot Reload — Magic Number (reseta estado de drawdown)            |
//+------------------------------------------------------------------+
void CBlockerDrawdown::SetMagicNumber(int newMagic)
  {
   m_magicNumber              = newMagic;
   m_dailyPeakProfit          = 0.0;
   m_drawdownProtectionActive = false;
   m_drawdownLimitReached     = false;
   m_drawdownActivationTime   = 0;
  }

//+------------------------------------------------------------------+
//| Reset diário — zera estado de drawdown                           |
//+------------------------------------------------------------------+
void CBlockerDrawdown::ResetDaily()
  {
   m_dailyPeakProfit          = 0.0;
   m_drawdownProtectionActive = false;
   m_drawdownLimitReached     = false;
   m_drawdownActivationTime   = 0;
   m_sLastDebugLog            = 0;  // FIX v1.02

   if(m_logger != NULL)
      m_logger.Log(LOG_DEBUG, THROTTLE_NONE, "RESET", "BlockerDrawdown: estado zerado");
  }

//+------------------------------------------------------------------+
//| Calcula drawdown atual                                           |
//+------------------------------------------------------------------+
double CBlockerDrawdown::GetCurrentDrawdown()
  {
   if(!m_drawdownProtectionActive || m_dailyPeakProfit <= 0)
      return 0.0;

   double floating    = 0.0;
   double swap        = 0.0;
   double commission  = 0.0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
        {
         floating   += PositionGetDouble(POSITION_PROFIT);
         swap       += PositionGetDouble(POSITION_SWAP);
         commission += PositionGetDouble(POSITION_COMMISSION);
        }
     }

   double closedProfit    = (m_logger != NULL) ? m_logger.GetDailyProfit() : 0.0;
   double projectedProfit = closedProfit + floating + swap + commission;

   if(projectedProfit >= m_dailyPeakProfit)
      return 0.0;

   double currentDD = m_dailyPeakProfit - projectedProfit;

   if(m_drawdownType == DD_FINANCIAL)
      return currentDD;

   return (currentDD / m_dailyPeakProfit) * 100.0;
  }

#endif  // BLOCKER_DRAWDOWN_MQH
//+------------------------------------------------------------------+
