//+------------------------------------------------------------------+
//|                                                         Risk.mqh |
//|                                          Italo Coutinho Capitals |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Italo Coutinho Capitals"
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>                                
#include <Trade\PositionInfo.mqh>                         
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>

CTrade         *m_trade;
CSymbolInfo    *m_symbol;
CPositionInfo  *PosInf; 
CAccountInfo   *Account;
      
class CRiskManage
{
   //Variáveis
            
      //Account Balance
         public:
            double AccBalance;
            bool FixBalance;     //Fix Account Balance (true = sim, false = não)
            double MaxRisk;      //Risco máximo por trade
            string Expert;       //Expert Advisor Name
            
            bool ScaleIn;        //Faz ou não scale in
            int ScaleInMaxTimes; //Quantidade Máxima de vezes em que escala, não conta a primeira entrada da posição, somente as escaladas
            
            int AutobreakevenSecure; /*Ticks to garantee Breakeven on the first entry
                                    Quantidade de ticks que deseja sair antes do Breakeven para garantir que saia da operação! */
                                    
            double RiskR;           // Loss Ratio
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
            double Take;            //Take Profit
            
            //Preço
            double SlPrice;
            double TPPrice;
            
            //enum MAType = MODE_EMA;
            int MAPeriod;
            int MATickDist;
            
      protected:
            string dbname;
                                 
            int DML;
            int WML;
            int MML;
            
            int DAL;
            int WAL;
            int MAL;
            
            int OpHr;
            int OpMin;
            
            string MxTime;
            
            double IdlR;     //Ideal Risk
            double MaxR;      //Max Risk


      //Max Continuous Loss Positions, Day, Week and Month
         /*protected:
            int DML;
            int WML;
            int MML;
      
      //Continuous Loss Positions, Day, Week and Month
            int DAL;
            int WAL;
            int MAL;*/
         
   
   public:
   /*double SLToPips(double StopLoss)
   {
      int Rnd = 0;
      int Pip = 1;
   
      if (Symbol().PipSize == 1E-05)
      {
          Rnd = 6;
          Pip = 100000;
      }
      else if (Symbol().PipSize == 0.0001)
      {
          Rnd = 5;
          Pip = 10000;
      }
      else if (Symbol.PipSize == 0.001)
      {
          Rnd = 4;
          Pip = 1000;
      }
      else if (Symbol.PipSize == 0.01)
      {
          Rnd = 3;
          Pip = 100;
      }
      else if (Symbol.PipSize == 0.1)
      {
          Rnd = 2;
          Pip = 10;
      }
      else if (Symbol.PipSize == 1)
      {
          Rnd = 1;
          Pip = 1;
      }
   
      //Print("Stop Loss: {0}, PipSize {1}, Rnd: {2}, Pip: {3}", StopLoss, Symbol.PipSize, Rnd, Pip);
   
      StopLoss = Math.Round(StopLoss, Rnd);
      StopLoss = StopLoss * Pip;
   
      //Print("Stop Loss: {0}", StopLoss);
   
      return StopLoss;
   }*/
   
   void Ini()
   {
      Account = new CAccountInfo();
      m_symbol = new CSymbolInfo();
      PosInf = new CPositionInfo();
      m_trade = new CTrade();
      
      dbname = "ICCapitals.sqlite";
      
      InsertOp();
      InsertRuinR();
      
      DrawDownManagement();
   }
   
   void Deini()
   {
      if(PosInf != NULL)
        delete PosInf;
      
      if(m_symbol != NULL)
        delete m_symbol;  
      
      if(m_trade != NULL)
        delete m_trade;  
      
      if(Account != NULL)
        delete Account; 
   }
   
   double RiskManage(double StopLoss)
   {
      m_symbol.Name(Symbol());
      
      double lots_min     = m_symbol.LotsMin();
      double lots_max     = m_symbol.LotsMax();
      double lots_step    = m_symbol.LotsStep();
      
      double ticksize     = m_symbol.TickSize();
      double tickvalue    = m_symbol.TickValue();
        
      int normalization_factor = 0;
      double lots = 0.0;
      
      if (StopLoss < 0)
          return 0;
   
      double MaxStop;
      if (Account.Balance() <= 5 || FixBalance == true)
          MaxStop = AccBalance * (MaxRisk / 100);
      else
          MaxStop = Account.Balance() * (MaxRisk / 100);
   
      //Print("Account Balance: {3} {0}, with MaxRisk: {1}%, and MaxStop {3} {2}", Account.Balance, MaxRisk, MaxStop, Account.Currency);
      
      //Print(StopLoss);
      
      StopLoss = StopLoss/ticksize;
      StopLoss = (int)round(StopLoss);
      StopLoss = StopLoss*ticksize;
      
      double Loss = StopLoss * tickvalue;
   
      /*Print(ticksize);
      Print(tickvalue);
      
      Print(Loss);*/
      
      //Print("Max Stop: {5} {0}, with Loss {5} {1}, PipValue {5} {3}, Stop loss: {4}", MaxStop, Loss, Symbol.PipSize, Symbol.PipValue, StopLoss, Account.Currency);
   
      double Lots = MaxStop / Loss;
      Lots = MathRound(Lots);
      
      //Se parte de Lots foi deixada de lado, operar também no Fracionário!
   
      //Print("Normalized Volume: {0}, Lots: {1}", Lots, Symbol.VolumeInUnitsToQuantity(Lots));
      
      if(lots_step == 0.01) { normalization_factor = 2; }
      if(lots_step == 0.1)  { normalization_factor = 1; }
      
      Lots = NormalizeDouble(Lots, normalization_factor);
   
      if (Lots < lots_min) { Lots = lots_min; }
      if (Lots > lots_max) { Lots = lots_max; }
   
      return Lots;
   }
  
   void LotsManage()
   {
      PosInf.Select(Symbol());
    
      double StopLoss = PosInf.StopLoss();
      
      if (PosInf.PositionType() == 0)  //Buy
      {
         StopLoss = PosInf.PriceOpen() - StopLoss;
      }
      else                                      //Sell
      {
         StopLoss = StopLoss - PosInf.PriceOpen();
      }
      
      //Print(StopLoss);
      
      if (StopLoss>0)
      {
         double TradeVol = RiskManage(StopLoss);
         
         if (ScaleIn = true)
         {
            TradeVol = TradeVol*(ScaleInMaxTimes+1);
         }
         
         //Verifica se foram feitas duas entradas
         double vol = PosInf.Volume(); //m_trade.RequestVolume();
         /*Print(vol);
         Print(TradeVol);
         Print(TradeVol<vol);
         Print(vol-TradeVol);*/
         if (TradeVol < vol)
         {
            //Se sim fecha metade da posição
            //m_trade.PositionClosePartial(Symbol(),vol,10);
            //Print("Position Close");
            //m_trade.PositionClose(Symbol());
            
            if (PosInf.PositionType() == 0)  //Buy
            {
               m_trade.Sell(vol-TradeVol,Symbol());
            }
            else                                      //Sell
            {
               m_trade.Buy(vol-TradeVol,Symbol());
            }
            
            //m_trade.PositionClosePartial(Symbol(),vol-TradeVol);
         }   
      }
   }
   
   void ScaleInManage(bool BE, bool PositionBE)
   {
       double sl_lots;
       
       double lots;
       
       if (CheckPos(false))
       {
         SlPrice = PosInf.StopLoss();
         
         if (BE = true);
            //TPPrice = Breakeven(PositionBE);
         else
            TPPrice = PosInf.TakeProfit();
         
         if (PosInf.PositionType() == 0)  //Buy
         {
            sl_lots = m_symbol.Ask() - SlPrice;
            
            lots = RiskManage(sl_lots);
            
            m_trade.PositionOpen(Symbol(), ORDER_TYPE_BUY, lots, m_symbol.Ask(), SlPrice, TPPrice);
         }
         else                                      //Sell
         {
            sl_lots = SlPrice - m_symbol.Bid();
            
            lots = RiskManage(sl_lots);
            
            m_trade.PositionOpen(Symbol(), ORDER_TYPE_SELL, lots, m_symbol.Ask(), SlPrice, TPPrice);
         }
      }
   }
   
   void Breakeven(bool PositionBE)
   {
      double ticksize     = m_symbol.TickSize();
      
      if (PosInf.PositionType() == 0)  //Buy
      {
         TPPrice = PosInf.PriceOpen()-AutobreakevenSecure*ticksize;
      }
      else                                      //Sell
      {
         TPPrice = PosInf.PriceOpen()+AutobreakevenSecure*ticksize;
      }
   }
   
   void MATrailingSL()
   {
      double digits       = m_symbol.Digits();
      double ticksize     = m_symbol.TickSize();
      
      int MADef = iMA(Symbol(),PERIOD_CURRENT,MAPeriod,0,MODE_EMA,PRICE_CLOSE);
      
      double MAVal[];
      CopyBuffer(MADef,0,1,1,MAVal);
      
      MAVal[0] = NormalizeDouble(MAVal[0], (int)digits);
      if (PosInf.PositionType() == 0)  //Buy
      {
         SlPrice = MAVal[0]-MATickDist*ticksize;
      }
      else
      {
         SlPrice = MAVal[0]-MATickDist*ticksize;
      }
      TPPrice = PosInf.TakeProfit();
      
      m_trade.PositionModify(Symbol(),SlPrice,TPPrice);
      
      //Print("Moving Average Value: ", MAVal[0]);
         
   }
   
   bool CheckPos(bool Cls)
   {
      
      bool ActPos = false;

       PosInf.Select(Symbol());
       
       if (PosInf.Identifier()>0)
         ActPos = true;
       
       if (ActPos == true && Cls == true)
       {
         m_trade.PositionClose(Symbol());
       }
       
       return ActPos;
       
   }
   
   bool DrawDownManagement()
   {
      //Consecutive Loss Position
      
      LoadDB();
      
      CheckEoD();
      
      CheckRuin();
      
      //Checa se o SL atual é menor que o SL Máximo no Banco de Dados
      if (MAL < MML)
          if (WAL < WML)
          {
              if (DAL < DML)
                  return true;
              else
              {
                  CheckPos(true);
                  return false;
              }
          }
      CheckPos(true);
      return false;
   }
    
   bool CheckRuin ()
   {
      LoadRuinDB();
      if (MaxR<MaxRisk)
      {
         CheckPos(true);
         return false;
      }
      else if (MaxRisk<IdlR)
      {
         Print("You can increase your risk by "+(IdlR-MaxRisk)+"%");
      }
      return true;
   }
   
   void SetSLTP(bool Bull)
   {    
      double digits       = m_symbol.Digits();
      
      if(Bull)
      {
         SlPrice = NormalizeDouble(m_symbol.Ask() - Take*RiskR, (int)digits);    
         TPPrice = NormalizeDouble(m_symbol.Ask() + Take, (int)digits);
      }
      else
      {
         SlPrice = NormalizeDouble(m_symbol.Bid() + Take*RiskR, (int)digits);    
         TPPrice = NormalizeDouble(m_symbol.Bid() - Take, (int)digits);
      }
   }
   
   void SetMaxDD()
   {
      if(RiskR == 5)           //5x1                  
      {
         DML = 1;
         WML = 5;
         MML = WML*2;
      }
      else if(RiskR == 4)           //4x1                  
      {
         /*DML = 1;
         WML = 5;
         MML = WML*2;*/
      }
      else if(RiskR == 3)           //3x1                  
      {
         /*DML = 1;
         WML = 5;
         MML = WML*2;*/
      }
      else if(RiskR == 2)           //2x1                  
      {
         /*DML = 1;
         WML = 5;
         MML = WML*2;*/
      }
      else if(RiskR == 1)           //1x1                  
      {
         /*DML = 1;
         WML = 5;
         MML = WML*2;*/
      }
      else if(RiskR ==  0.5)           //1x2                  
      {
         DML = 4;
         WML = 16;
         MML = WML*2;
      }
      else if(RiskR == 0.33)           //1x3                  
      {
         /*DML = 1;
         WML = 5;
         MML = WML*2;*/
      }
      else if(RiskR == 0.25)           //1x4                  
      {
         /*DML = 1;
         WML = 5;
         MML = WML*2;*/
      }
      else if(RiskR == 0.2)           //1x5                  
      {
         /*DML = 1;
         WML = 5;
         MML = WML*2;*/
      }
   }
   
   void SetMaxTime()
   {
      //string MxTime;
      if (Expert == "Fade Ômega" || Expert == "Fade Ômega Secure")
         MxTime = "14:00";
      else if (Expert == "Momentum Sigma" || Expert == "Momentum Sigma Secure");
         //MxTime = "14:00";   
         
      //MxRTime = "2020/01/01 "+MxRTime+":00";
      
      //Print(MxRTime);
      
      //MxTime = StringToTime(MxRTime);
      
      //Print(MxTime);
   }
   
   void SetMaxRuinR()
   {
      if(RiskR == 5)           //5x1                  
      {
         IdlR = 1;
         MaxR = 5;
      }
      else if(RiskR == 4)           //4x1                  
      {
         /*IdlR = 1;
         MaxR = 5;*/
      }
      else if(RiskR == 3)           //3x1                  
      {
         /*IdlR = 1;
         MaxR = 5;*/
      }
      else if(RiskR == 2)           //2x1                  
      {
         /*IdlR = 1;
         MaxR = 5;*/
      }
      else if(RiskR == 1)           //1x1                  
      {
         /*IdlR = 1;
         MaxR = 5;*/
      }
      else if(RiskR ==  0.5)           //1x2                  
      {
         IdlR = 0.25;
         MaxR = 0.5;
      }
      else if(RiskR == 0.33)           //1x3                  
      {
         /*IdlR = 1;
         MaxR = 5;*/
      }
      else if(RiskR == 0.25)           //1x4                  
      {
         /*IdlR = 1;
         MaxR = 5;*/
      }
      else if(RiskR == 0.2)           //1x5                  
      {
         /*IdlR = 1;
         MaxR = 5;*/
      }
   }
   
   void CheckEoD()
   {
      MqlDateTime Attime, nxtday; 
      if(OpHr <= 3 || OpHr == NULL)
      {
         TimeToStruct(TimeGMT()-1,Attime);
         TimeToStruct(TimeGMT(),nxtday);
      }
      else
      {
         TimeToStruct(TimeGMT(),Attime);
         TimeToStruct(TimeGMT()+1,nxtday);
      }
      /*int AtHr;
      int AtMin;
      
      // Brazil GMT - 3, ou seja adicione 3 horas para virar o horário GMT
      //Print(TimeLocal());
      //string AtTm = TimeToString(TimeLocal());
      string AtTm = TimeToString(TimeGMT());
      //Print(Tm);
      AtHr = StringSubstr(AtTm,10,4);
      AtMin = StringSubstr(AtTm,13,2);
      AtMin = AtMin+StringSubstr(AtTm,14,2);
      //Print(Hr, ":", Min);*/
      
      if (OpHr < Attime.hour || (OpHr == Attime.hour && OpMin < Attime.min))
      {
         CheckPos(true);
         DAL = 0;
         SaveDB("Day");
            
         if (FRIDAY <= Attime.day_of_week)
         {
            WAL = 0;
            SaveDB("Week");
         }
         
         if (Attime.mon<nxtday.mon)
         {
            MAL = 0;
            SaveDB("Month");
         }
      }
   }
   
   void NewLoss ()
   {
      //Salva o Loss na variável
      
      LoadDB();
      
      DAL++;
      WAL++;
      MAL++;
      
      SaveDB("Day");
      SaveDB("Week");
      SaveDB("Month");
   }
   
   void SaveDB(string UpdtType = "")
   {
      //Salva o SL atual no Banco de Dados
      string Updt = "";
      
      int db = DatabaseOpen(dbname,DATABASE_OPEN_READWRITE|DATABASE_OPEN_COMMON);
      
      if (db == INVALID_HANDLE)
      {
         CreateDB();
         /*Print("Banco de dados: ",dbname, " falhou ao abrir com código ", GetLastError());
         return;*/
      }
      
      int request = DatabasePrepare(db, "SELECT * FROM Operacionais WHERE (Operacional = '"+Expert+"')");
      
      if (request == INVALID_HANDLE)
      {
         Print("Banco de Dados: ", dbname, " erro ao selecionar com código ",GetLastError());
         DatabaseClose(db);
         return;
      }
      else
      {
         //Print("Consulta feita com sucesso");
      }
      
      if (UpdtType == "Day")
         Updt = "DAL="+DAL;
      else if (UpdtType == "Week")
         Updt = "WAL="+WAL;
      else if (UpdtType == "Month")
         Updt = "MAL="+MAL;
      else if (UpdtType == "DMax")
         Updt = "DML="+DML;
      else if (UpdtType == "WMax")
         Updt = "WML="+WML;
      else if (UpdtType == "MMax")
         Updt = "MML="+MML;
      else if (UpdtType == "MaxTime")
      {
         SetMaxTime();
         Updt = "MaxT='"+MxTime+"'";
      }
         
      //Print("UPDATE Operacionais SET "+Updt+" WHERE Operacional='"+Expert+"'");
      
      if (!DatabaseExecute(db, "UPDATE Operacionais SET "+Updt+" WHERE Operacional='"+Expert+"'"))
      {
         Print("Banco de Dados: ", dbname, " erro ao fazer update com código ",GetLastError());
         DatabaseClose(db);
         return;
      }
      else
      {
         //Print("Update realizado com sucesso");
      }
      
      DatabaseFinalize(request);
      
      DatabaseClose(db);
   }
   
   void LoadDB()
   {
      //Salva o SL atual no Banco de Dados
      string Updt = "";
      
      int db = DatabaseOpen(dbname,DATABASE_OPEN_READONLY|DATABASE_OPEN_COMMON);
      
      if (db == INVALID_HANDLE)
      {
         CreateDB();
         /*Print("Banco de dados: ",dbname, " falhou ao abrir com código ", GetLastError());
         return;*/
      }
      
      //Print("SELECT * FROM Operacionais WHERE (Operacional='"+Expert+"')");
      
      int request = DatabasePrepare(db, "SELECT * FROM Operacionais WHERE Operacional='"+Expert+"'");
      
      if (request == INVALID_HANDLE)
      {
         Print("Banco de Dados: ", dbname, " erro ao selecionar com código ",GetLastError());
         DatabaseClose(db);
         return;
      }
      else
      {
         //Print("Consulta feita com sucesso");
      }
      
      string op, MaxTm;
      
      for (int i=0; DatabaseRead(request);i++)
      {
         DatabaseColumnText(request,0,op);        //Operacional
         DatabaseColumnInteger(request,1,DML);    //DML
         DatabaseColumnInteger(request,2,WML);    //WML
         DatabaseColumnInteger(request,3,MML);    //MML
         DatabaseColumnInteger(request,4,DAL);    //DAL
         DatabaseColumnInteger(request,5,WAL);    //WAL
         DatabaseColumnInteger(request,6,MAL);    //MAL
         DatabaseColumnText(request,7,MaxTm);    //MaxTime
         
         //Print(i, " | Operacional: ", op, " | DML: ", DML, " | WML: ", WML, " | MML: ", MML, " | DAL: ", DAL, " | WAL: ", WAL, " | MAL: ", MAL, " | MaxTime: ", MaxTm);
      }
      
      OpHr = StringSubstr(MaxTm,0,2);
      OpMin = StringSubstr(MaxTm,3,2);
      //OpMin = OpMin+StringSubstr(MaxTm,3,2);
      
      //Print("Max Time: ",MaxTm, " Max Hour: ", OpHr, " Max Minutes: ", OpMin);
      
      DatabaseFinalize(request);
      
      DatabaseClose(db);
   }
   
   void CreateDB()
   {
      //Importa o SL atual do Banco de Dados
      
      int db = DatabaseOpen(dbname,DATABASE_OPEN_READWRITE|DATABASE_OPEN_CREATE|DATABASE_OPEN_COMMON);
      if (db == INVALID_HANDLE)
      {
         /*Print("Banco de dados: ",dbname, " falhou ao abrir com código ", GetLastError());
         return;*/
      }
      
      //Print("Banco de dados criado com sucesso");
      
      if(!DatabaseExecute(db, "CREATE TABLE Operacionais("
                              "Operacional   TEXT  NOT NULL,"        //Operacional
                              "DML           INT   NOT NULL,"        //Day Max Loss
                              "WML           INT   NOT NULL,"        //Week Max Loss
                              "MML           INT   NOT NULL,"        //Month Max Loss
                              "DAL           INT   NOT NULL,"        //Day Actual Loss
                              "WAL           INT   NOT NULL,"        //Week Actual Loss
                              "MAL           INT   NOT NULL,"        //Month Actual Loss
                              "MaxT          TIME  NULL);"))         //Max Time
      {
         /*Print("Banco de Dados: ", dbname, " erro ao criar tabela com código ",GetLastError());
         DatabaseClose(db);
         return;*/
      }
      else
      {
         //Print("Tabela Operacionais criada com sucesso");
      }
      
      DatabaseClose(db);
      
      InsertOp();
   }
   
   void InsertOp ()
   {
      int db = DatabaseOpen(dbname,DATABASE_OPEN_READWRITE|DATABASE_OPEN_CREATE|DATABASE_OPEN_COMMON);
      
      int request = DatabasePrepare(db, "SELECT * FROM Operacionais WHERE Operacional='"+Expert+"'");
      
      //Print("DB Request: ",DatabaseRead(request));
      
      if (!DatabaseRead(request))
      {
         SetMaxDD();
         SetMaxTime();
         
         //Print("INSERT INTO Operacionais (Operacional, DML, WML, MML, DAL, WAL, MAL, MaxT) VALUES ('"+Expert+"',"+DML+","+WML+","+MML+",0,0,0,'"+MxTime+"');");
         
         if(!DatabaseExecute(db, "INSERT INTO Operacionais (Operacional, DML, WML, MML, DAL, WAL, MAL, MaxT) VALUES ('"+Expert+"',"+DML+","+WML+","+MML+",0,0,0,'"+MxTime+"');"))
         {
            Print("Banco de Dados: ", dbname, " erro ao inserir linha com código ",GetLastError());
            DatabaseClose(db);
            return;
         }
         else
         {
            //Print("Registro criado com sucesso");
         }
      }
      
      DatabaseFinalize(request);
      
      DatabaseClose(db);
   }
   
   void SaveRuinDB(string UpdtType = "")
   {
      //Salva o SL atual no Banco de Dados
      string Updt = "";
      
      int db = DatabaseOpen(dbname,DATABASE_OPEN_READWRITE|DATABASE_OPEN_COMMON);
      
      if (db == INVALID_HANDLE)
      {
         CreateRuinDB();
         /*Print("Banco de dados: ",dbname, " falhou ao abrir com código ", GetLastError());
         return;*/
      }
      
      int request = DatabasePrepare(db, "SELECT * FROM RuinRisk WHERE (RiskR = '"+RiskR+"')");
      
      if (request == INVALID_HANDLE)
      {
         Print("Banco de Dados: ", dbname, " erro ao selecionar com código ",GetLastError());
         InsertRuinR();
         DatabaseClose(db);
         return;
      }
      else
      {
         //Print("Consulta feita com sucesso");
      }
      
      if (UpdtType == "Initial Risk")
         Updt = "IdlR="+IdlR;
      else if (UpdtType == "Max Risk")
         Updt = "MaxR="+MaxR;
         
      //Print("UPDATE Operacionais SET "+Updt+" WHERE Operacional='"+Expert+"'");
      
      if (!DatabaseExecute(db, "UPDATE RuinRisk SET "+Updt+" WHERE RiskR="+RiskR))
      {
         Print("Banco de Dados: ", dbname, " erro ao fazer update com código ",GetLastError());
         DatabaseClose(db);
         return;
      }
      else
      {
         //Print("Update realizado com sucesso");
      }
      
      DatabaseFinalize(request);
      
      DatabaseClose(db);
   }
   
   void LoadRuinDB()
   {
      //Salva o SL atual no Banco de Dados
      string Updt = "";
      
      int db = DatabaseOpen(dbname,DATABASE_OPEN_READONLY|DATABASE_OPEN_COMMON);
      
      if (db == INVALID_HANDLE)
      {
         CreateRuinDB();
         /*Print("Banco de dados: ",dbname, " falhou ao abrir com código ", GetLastError());
         return;*/
      }
      
      //Print("SELECT * FROM Operacionais WHERE (Operacional='"+Expert+"')");
      
      int request = DatabasePrepare(db, "SELECT * FROM RuinR WHERE RiskR="+RiskR);
      
      if (request == INVALID_HANDLE)
      {
         Print("Banco de Dados: ", dbname, " erro ao selecionar com código ",GetLastError());
         InsertRuinR();
         DatabaseClose(db);
         return;
      }
      else
      {
         //Print("Consulta feita com sucesso");
      }
      
      int Risk;
      
      for (int i=0; DatabaseRead(request);i++)
      {
         DatabaseColumnInteger(request,0,Risk); //Risk
         DatabaseColumnDouble(request,1,IdlR);  //Initial Risk
         DatabaseColumnDouble(request,2,MaxR);  //Max Risk
         
         //Print(i, " | Risco: ", Risk, " | Risco Ideal: ", IdlR, " | Risco Máximo: ", MaxR);
      }
      
      DatabaseFinalize(request);
      
      DatabaseClose(db);
   }
   
   void CreateRuinDB()
   {
      //Importa o SL atual do Banco de Dados
      int db = DatabaseOpen(dbname,DATABASE_OPEN_READWRITE|DATABASE_OPEN_CREATE|DATABASE_OPEN_COMMON);
      if (db == INVALID_HANDLE)
      {
         /*Print("Banco de dados: ",dbname, " falhou ao abrir com código ", GetLastError());
         return;*/
      }
      
      //Print("Banco de dados criado com sucesso");
      
      if(!DatabaseExecute(db, "CREATE TABLE RuinR("
                              "RiskR   INT  NOT NULL,"         //Risk Return
                              "IdlR    DOUBLE   NOT NULL,"     //Ideal Risk
                              "MaxR    DOUBLE   NOT NULL);"))  //Max Risk
      {
         /*Print("Banco de Dados: ", dbname, " erro ao criar tabela com código ",GetLastError());
         DatabaseClose(db);
         return;*/
      }
      else
      {
         //Print("Tabela Operacionais criada com sucesso");
      }
      
      DatabaseClose(db);
      
      InsertRuinR();

   }
   
   void InsertRuinR()
   {
      int db = DatabaseOpen(dbname,DATABASE_OPEN_READWRITE|DATABASE_OPEN_CREATE|DATABASE_OPEN_COMMON);
      
      int request = DatabasePrepare(db, "SELECT * FROM RuinR WHERE RiskR="+RiskR);
      
      if (request == INVALID_HANDLE)
      {
         CreateRuinDB();
      }
      
      //Print("DB Request: ",DatabaseRead(request));
      
      if (!DatabaseRead(request))
      {
         SetMaxRuinR();
         
         //Print("INSERT INTO RuinR (RiskR, IdlR, MaxR) VALUES ("+RiskR+","+IdlR+","+MaxR+");");
         
         if(!DatabaseExecute(db, "INSERT INTO RuinR (RiskR, IdlR, MaxR) VALUES ("+RiskR+","+IdlR+","+MaxR+");"))
         {
            Print("Banco de Dados: ", dbname, " erro ao inserir linha com código ",GetLastError());
            DatabaseClose(db);
            return;
         }
         else
         {
            //Print("Registro criado com sucesso");
         }
      }

      DatabaseFinalize(request);
      
      DatabaseClose(db);
   }
};
