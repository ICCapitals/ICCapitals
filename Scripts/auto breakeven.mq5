//+------------------------------------------------------------------+
//|                                               Auto Breakeven.mq5 |
//|                                   Copyright 2021, Italo Coutinho |
//|                   https://github.com/ItaloCoutinho/ItaloCoutinho |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Italo Coutinho"
#property link      "https://github.com/ItaloCoutinho/ItaloCoutinho"
#property version   "1.00"

//#property script_show_inputs

input int AutobreakevenSecure = 2; /*Ticks to garantee Breakeven on the first entry
                                    Quantidade de ticks que deseja sair antes do Breakeven para garantir que saia da operação! */
input bool PositionBE = true;       //Position breakeven usa o preço médio da posição como Breakeven
input bool MoveSL = false;           //Deseja mover o SL ou o TP para o Breakeven, SL = true, TP = false

// Variáveis de controle
bool ActPos = false;

//Importação de Bibliotecas
#include <Trade\Trade.mqh>                                
#include <Trade\PositionInfo.mqh>                         
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

CTrade         *m_trade;
CSymbolInfo    *m_symbol;
CPositionInfo  *m_position_info; 
CAccountInfo   *m_account;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
      m_trade = new CTrade();
      m_symbol = new CSymbolInfo();   
      m_position_info = new CPositionInfo();   
      m_account = new CAccountInfo();
      
       m_symbol.Name(Symbol());
       m_symbol.RefreshRates();
       
      double ticksize     = m_symbol.TickSize();
    
      double sl;
      double tp;
      double be;
      
      m_position_info.Select(Symbol());
      
      if (m_position_info.Identifier()>0)
         ActPos = true;
      
      //Print("Auto Breakeven");
      //Print(ticksize);
      
      if(ActPos == true)
      {
         be = m_position_info.PriceOpen();
         
         //Print(be);
         
         //Print(m_position_info.PositionType());
         
         if (m_position_info.PositionType() == 0)  //Buy
         {
            be = be-AutobreakevenSecure*ticksize;
            if (MoveSL == true)
            {
               if(m_symbol.Bid() < be)
               {
                  DeleteClass();
                  return;
               }
            }
            else
            {
               if(m_symbol.Bid() > be)
               {
                  DeleteClass();
                  return;
               }
            }
         }
         else                                      //Sell
         {
            be = be+AutobreakevenSecure*ticksize;
            if (MoveSL == true)
            {
               if(m_symbol.Ask() > be)
               {
                  DeleteClass();
                  return;
               }
            }
            else
            {
               if(m_symbol.Ask() < be)
               {
                  DeleteClass();
                  return;
               }
            }
         }
         
         if (MoveSL == true)
         {
            sl = be;
            tp = m_position_info.TakeProfit();
         }
         else
         {
            sl = m_position_info.StopLoss();
            tp = be;
         }
         
         m_trade.PositionModify(Symbol(),sl,tp);
      }
      DeleteClass();
  }
//+------------------------------------------------------------------+
void DeleteClass()
{
   if(m_position_info != NULL)
        delete m_position_info;
    
    if(m_symbol != NULL)
        delete m_symbol;  
    
    if(m_trade != NULL)
        delete m_trade;  
    
    if(m_account != NULL)
        delete m_account; 
}
