//+------------------------------------------------------------------+
//|                                                      DelStop.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
CTrade trade;
CPositionInfo posinfo;
void OnStart()
  {
   int ticket;
   int     total=OrdersTotal(); 
//--- �������ͨ������ 
   for(int j = 0;j <30;j++)
   {
      for(int i=0;i<total;i++) 
        { 
         //--- ͨ���б��еĲ�λ���ض������� 
         if(ticket=OrderGetTicket(i)) 
           { 
            trade.OrderDelete(ticket);
           } 
        }
      if(total ==0) break;
   }
  }
//+------------------------------------------------------------------+
