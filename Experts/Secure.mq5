//+------------------------------------------------------------------+
//|                                                       Secure.mq5 |
//|                                      Copyright 2021, IC Capitals |
//|                                    https://github.com/ICCapitals |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, IC Capitals"
#property link      "https://github.com/ICCapitals"
#property version   "1.00"

//Inputs
input double      RiskPercentage = 0.1; // Risk Percentage per Trade
input double AcBalance = 15482;
input bool FxBalance = true;
//input double StopLoss = 45;
input double      LossRatio    = 0.5; // Loss Ratio
                                 /* Risco x Retorno
                                    5x1 = 5
                                    4x1 = 4
                                    3x1 = 3
                                    2x1 = 2
                                    1x1 = 1
                                    1x2 = 0.5
                                    1x3 = 0.33
                                    1x4 = 0.25
                                    1x5 = 0.2  */
input string Expert = "Secure";     //Expert Name, Used to Acess the Database and Risk
                                    
//Importação de Bibliotecas
#include <ICCapitals\Risk.mqh>
//#include <ICCapitals\Transactions.mqh>

CRiskManage Rsk;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      Rsk.AccBalance = AcBalance;
      Rsk.FixBalance = FxBalance;
      Rsk.Expert = Expert;
      Rsk.MaxRisk = RiskPercentage;
      Rsk.ScaleIn = false;
      Rsk.RiskR = LossRatio;
      
      Rsk.Ini();

//--- create timer
   EventSetTimer(300);
   
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
      Rsk.Deini();
      //--- destroy timer
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
      Rsk.CheckEoD();
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
      Rsk.LotsManage();
      Rsk.DrawDownManagement();   
  }
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction & trans,
                        const MqlTradeRequest & request,
                        const MqlTradeResult & result)
   {
      if (HistoryDealSelect(trans.deal))
      {
         ENUM_DEAL_ENTRY deal_entry = (ENUM_DEAL_ENTRY) HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
         ENUM_DEAL_REASON deal_reason = (ENUM_DEAL_REASON) HistoryDealGetInteger(trans.deal, DEAL_REASON);
         if(EnumToString(deal_entry) == "DEAL_ENTRY_IN")
            {
            }
         else if(EnumToString(deal_entry) == "DEAL_ENTRY_OUT")
            {
               if(EnumToString(deal_reason) == "DEAL_REASON_SL")
               {
                     Print("Sl");
                    Rsk.NewLoss();
               }
          } 
      }      
}
