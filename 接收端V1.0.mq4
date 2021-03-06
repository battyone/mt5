#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
string url="http://local.com/mt4"; 
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
  {

  }
void OnTick()
  {
//---
  string data_remote = send("tick");//先去查询服务器端的数据 
  Sleep(250);
  }
//+------------------------------------------------------------------+
string send(string data)//往服务器发数据
{
   string cookie=NULL,headers; 
   char   post[],result[]; 
   
   ResetLastError(); 
   StringToCharArray(data,post);
   string str = "";
   int res=WebRequest("POST",url,NULL,5000,post,result,headers); 
   if(res==-1) 
     { 
      Print("接收端报错: Error in WebRequest. Error code  =",GetLastError()); 
      //MessageBox("Add the address '"+url+"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     } 
   else 
     { 
      if(res==200) 
        { 
            str = CharArrayToString(result,0,WHOLE_ARRAY,CP_ACP);
            //Print(str);
            deal_go(str);
            
        } 
      else 
         PrintFormat("Downloading '%s' failed, error code %d",url,res); 
     } 
     return str;
}

string convert_symbol(string sy)
{
 string sy_new;
 if(sy == "OILUS") sy_new = "OILUSe";
 if(sy == "OILUK") sy_new = "OILUKe";
 else return sy;
 return sy_new;
}

void deal_go(string to_split)
{
   //string status,mt5ticket,sy;
   //int entry,type,magic;
   //double lots,sl,tp;
   if(StringLen(to_split) == 0) return;
   string sep=",";                // 分隔符为字符 
   ushort u_sep;                  // 分隔符字符代码 
   string result[];               // 获得字符串数组 
   u_sep=StringGetCharacter(sep,0); 
   int k=StringSplit(to_split,u_sep,result); 
   string status = result[0];
   string mt5ticket = result[1];
   string sy = convert_symbol(result[2]);
   int entry = StrToInteger(result[3]);//0表示开单，买进或者卖出，1表示平仓单
   int type = StrToInteger(result[4]);//0表示buy单，1表示sell单
   double lots = NormalizeDouble(StrToDouble(result[5]),2);
   double sl = StrToDouble(result[6]);
   double tp = StrToDouble(result[7]);
   int magic = StrToInteger(result[8]);
   double ask    = MarketInfo(sy,MODE_ASK); 
   double bid    = MarketInfo(sy,MODE_BID);
   if(status == "open") //open,mt5ticket,XAUUSD,0,0,0.02,1.1234,2.2345,magic,0,pos_id,
   {

      if(type == 0)
      {
         int res = OrderSend(sy,OP_BUY,lots,ask,150,sl,tp,mt5ticket,magic,0,0);
         if(res>0)
         {
            string s = StringConcatenate("openok,",mt5ticket,",",IntegerToString(res));
            response(s);
            Sleep(150);
         }else{ 
         Print("OrderSend failed with error #",GetLastError()); 
         } 
      
      }
      if(type == 1)
      {
         int res = OrderSend(sy,OP_SELL,lots,bid,150,sl,tp,mt5ticket,magic,0,0);
         if(res>0) 
         {
            string s = StringConcatenate("openok,",mt5ticket,",",IntegerToString(res));
            response(s);
            Sleep(150);
         }else{ 
         Print("OrderSend failed with error #",GetLastError()); 
         }  
      }   
   }
   
   if(status == "CLOSE_HAND_TICKET")//open,mt5ticket,XAUUSD,0,0,0.02,1.1234,2.2345,magic,mt4ticket,pos_id,mt5out_ticket,OUTLOTS
   {
      string mt5out_ticket = result[11];
      int ticket = result[9];
      double close_lots = NormalizeDouble(StringToDouble(result[12]),2); 
      double diff_lots = NormalizeDouble(lots - close_lots,2);
      //close_lots = (diff_lots == 0 || diff_lots == lots/2)?close_lots:lots;//解决放大系数是0.5倍时候有0.01平不掉的问题
      
      Print("lots ",lots,"  close_lots ",close_lots,"  diff_lots  ",diff_lots," equal ",NormalizeDouble(diff_lots,2) == 0.01);
      //diff_lots = formatlots(sy,diff_lots);
      if(NormalizeDouble(diff_lots,2) == 0.01) close_lots=lots;
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
      {
         bool res = OrderClose(ticket,close_lots,OrderClosePrice(),150,0);
         
         if(res)
         {
            string s;
            if(diff_lots > 0)
            {
               int pos = OrdersHistoryTotal();
               string mt4ticket;
               if(OrderSelect(pos-1,SELECT_BY_POS,MODE_HISTORY))
               {
                  mt4ticket = get_his_comment(OrderComment());
               }  
               s = StringConcatenate("closehalfok,",mt5ticket,",",mt5out_ticket,",",DoubleToString(diff_lots),",",mt4ticket);
            }else s = StringConcatenate("closeallok,",mt5ticket,",",mt5out_ticket);//("closeallok,EAINkey,eaoutKEY")
            response(s);
            Sleep(150);
         } 
         else Print("OrderSend failed with error #",GetLastError()); 
      }
   }
   
   if(status == "CLOSE_EA_TICKET")//接收:open,mt5ticket,XAUUSD,0,0,0.02,1.1234,2.2345,magic,0,pos_id,mt5out_ticket,closelots
   {
      string mt5out_ticket = result[11]; 
      int ticket = result[9];
      double close_lots = NormalizeDouble(StringToDouble(result[12]),2); 
      double res_lots = NormalizeDouble(lots - close_lots,2);
      res_lots = formatlots(sy,res_lots);
      if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))//res:"closehalf,EAINkey,eaoutKEY,0.01,mt4ticket"
      {
         bool res = OrderClose(ticket,close_lots,OrderClosePrice(),150,0);
         if(res)
         {
            int pos = OrdersHistoryTotal();
            string mt4ticket;
            if(OrderSelect(pos-1,SELECT_BY_POS,MODE_HISTORY))
            {
               mt4ticket = get_his_comment(OrderComment());
            }  
            string s = StringConcatenate("closehalfok,",mt5ticket,",",mt5out_ticket,",",DoubleToString(res_lots),",",mt4ticket);
            response(s);
            Sleep(150);
         } 
         else Print("OrderSend failed with error #",GetLastError()); 
      }
   }

}

void response(string data)//往服务器发数据
{
   string cookie=NULL,headers; 
   char   post[],result[]; 
   ResetLastError(); 
   StringToCharArray(data,post);
   string str = "";
   int res=WebRequest("POST",url,NULL,500,post,result,headers); 
   if(res==-1) 
     { 
      Print("Error in WebRequest. Error code  =",GetLastError()); 
      MessageBox("Add the address '"+url+"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION); 
     } 
   else 
     { 
      if(res==200) 
        { 
            str = CharArrayToString(result,0,WHOLE_ARRAY,CP_ACP);
            Print(str);
            
        } 
      else 
         PrintFormat("Downloading '%s' failed, error code %d",url,res); 
     } 
}

string get_his_comment(string to_split)
{
   string sep="#";                // A separator as a character 
   ushort u_sep;                  // The code of the separator character 
   string result[];               // An array to get strings 
   u_sep=StringGetCharacter(sep,0); 
   int k=StringSplit(to_split,u_sep,result);
   return result[k-1];
}

double formatlots(string symbol,double lots)
   {
     double a=0;
     double minilots=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
     double steplots=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
     if(lots<minilots) return(0);
     else
      {
        double a1=MathFloor(lots/minilots)*minilots;
        a=a1+MathFloor((lots-a1)/steplots)*steplots;
      }
     return(a);
   }