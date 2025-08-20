//+------------------------------------------------------------------+
//|                                         Supertrend_EA_Complete.mq5 |
//|                        Copyright 2025, MetaQuotes Software Corp.  |
//|                                             https://www.mql5.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- Input Parameters
input double Factor = 3.0;       // ATR Factor
input int ATR_Period = 10;       // ATR Period
input double LotSize = 0.1;      // Lot Size
input int StopLoss = 100;        // Stop Loss (in points)
input int TakeProfit = 200;      // Take Profit (in points)

//--- Global Variables
int atrHandle;
double finalUpBand[];
double finalDownBand[];
int trendDirection[];
double supertrend[];

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize arrays
   ArraySetAsSeries(finalUpBand, true);
   ArraySetAsSeries(finalDownBand, true);
   ArraySetAsSeries(trendDirection, true);
   ArraySetAsSeries(supertrend, true);

   // Create ATR indicator handle
   atrHandle = iATR(_Symbol, _Period, ATR_Period);
   if(atrHandle == INVALID_HANDLE)
   {
      Print("Failed to create ATR handle");
      return(INIT_FAILED);
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(atrHandle != INVALID_HANDLE)
      IndicatorRelease(atrHandle);

   // Remove all objects created by the EA
   ObjectsDeleteAll(0, "Supertrend_");
   ObjectsDeleteAll(0, "BuySignal_");
   ObjectsDeleteAll(0, "SellSignal_");
   ObjectsDeleteAll(0, "BuyArrow_");
   ObjectsDeleteAll(0, "SellArrow_");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!IsNewBar()) return; // Process only on new bar to match Pine Script behavior

   // Get number of bars
   int bars = Bars(_Symbol, _Period);

   // Resize arrays
   ArrayResize(finalUpBand, bars);
   ArrayResize(finalDownBand, bars);
   ArrayResize(trendDirection, bars);
   ArrayResize(supertrend, bars);

   // Get price data
   double close[], high[], low[];
   datetime time[];
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(time, true);
   if(CopyClose(_Symbol, _Period, 0, bars, close) < bars ||
      CopyHigh(_Symbol, _Period, 0, bars, high) < bars ||
      CopyLow(_Symbol, _Period, 0, bars, low) < bars ||
      CopyTime(_Symbol, _Period, 0, bars, time) < bars)
   {
      Print("Failed to copy price data");
      return;
   }

   // Get ATR values
   double atrValue[];
   ArraySetAsSeries(atrValue, true);
   if(CopyBuffer(atrHandle, 0, 0, bars, atrValue) < bars)
   {
      Print("Failed to copy ATR data");
      return;
   }

   // Calculate Supertrend
   for(int i = bars - 2; i >= 0; i--)
   {
      double hl2 = (high[i] + low[i]) / 2.0;
      double upBand = hl2 - (Factor * atrValue[i]);
      double downBand = hl2 + (Factor * atrValue[i]);

      if(i == bars - 2)
      {
         finalUpBand[i] = upBand;
         finalDownBand[i] = downBand;
         trendDirection[i] = 1;
      }
      else
      {
         finalUpBand[i] = close[i + 1] > finalUpBand[i + 1] ? MathMax(upBand, finalUpBand[i + 1]) : upBand;
         finalDownBand[i] = close[i + 1] < finalDownBand[i + 1] ? MathMin(downBand, finalDownBand[i + 1]) : downBand;
         trendDirection[i] = close[i] > finalDownBand[i + 1] ? 1 : close[i] < finalUpBand[i + 1] ? -1 : trendDirection[i + 1];
      }

      supertrend[i] = trendDirection[i] == 1 ? finalUpBand[i] : finalDownBand[i];
   }

   // Plot Supertrend line
   for(int i = 0; i < bars - 1; i++)
   {
      string objName = "Supertrend_" + IntegerToString(i);
      if(ObjectFind(0, objName) < 0)
         ObjectCreate(0, objName, OBJ_TREND, 0, time[i+1], supertrend[i+1], time[i], supertrend[i]);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, trendDirection[i] == 1 ? clrGreen : clrRed);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
   }

   // Detect Buy/Sell Signals
   bool buySignal = close[1] > supertrend[2] && close[2] <= supertrend[2]; // Crossover
   bool sellSignal = close[1] < supertrend[2] && close[2] >= supertrend[2]; // Crossunder

   // Plot Buy/Sell Labels and Arrows (mimicking TradingView boxes)
   if(buySignal)
   {
      string objName = "BuySignal_" + TimeToString(TimeCurrent());
      ObjectCreate(0, objName, OBJ_TEXT, 0, time[1], low[1] - 10 * _Point);
      ObjectSetString(0, objName, OBJPROP_TEXT, "BUY");
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrGreen);
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 10);

      string arrowName = "BuyArrow_" + TimeToString(TimeCurrent());
      ObjectCreate(0, arrowName, OBJ_ARROW_UP, 0, time[1], low[1] - 5 * _Point);
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 1);
   }

   if(sellSignal)
   {
      string objName = "SellSignal_" + TimeToString(TimeCurrent());
      ObjectCreate(0, objName, OBJ_TEXT, 0, time[1], high[1] + 10 * _Point);
      ObjectSetString(0, objName, OBJPROP_TEXT, "SELL");
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, clrRed);
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 10);

      string arrowName = "SellArrow_" + TimeToString(TimeCurrent());
      ObjectCreate(0, arrowName, OBJ_ARROW_DOWN, 0, time[1], high[1] + 5 * _Point);
      ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 1);
   }

   // Trade Management
   if(buySignal && !PositionExists(ORDER_TYPE_BUY))
   {
      double sl = close[1] - StopLoss * _Point;
      double tp = close[1] + TakeProfit * _Point;
      TradeBuy(LotSize, sl, tp);
   }

   if(sellSignal && !PositionExists(ORDER_TYPE_SELL))
   {
      double sl = close[1] + StopLoss * _Point;
      double tp = close[1] - TakeProfit * _Point;
      TradeSell(LotSize, sl, tp);
   }
}

//+------------------------------------------------------------------+
//| Check for new bar                                                |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime lastBar = 0;
   datetime currentBar = iTime(_Symbol, _Period, 0);
   if(currentBar != lastBar)
   {
      lastBar = currentBar;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if a position of the specified type exists                 |
//+------------------------------------------------------------------+
bool PositionExists(ENUM_ORDER_TYPE orderType)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_TYPE) == orderType)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Execute Buy Trade                                                |
//+------------------------------------------------------------------+
void TradeBuy(double lot, double sl, double tp)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lot;
   request.type = ORDER_TYPE_BUY;
   request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = 123456;
   request.type_filling = ORDER_FILLING_IOC;

   if(!OrderSend(request, result))
      Print("Buy order failed: ", GetLastError());
   else
      Print("Buy order placed: Ticket #", result.order);
}

//+------------------------------------------------------------------+
//| Execute Sell Trade                                               |
//+------------------------------------------------------------------+
void TradeSell(double lot, double sl, double tp)
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lot;
   request.type = ORDER_TYPE_SELL;
   request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.magic = 123456;
   request.type_filling = ORDER_FILLING_IOC;

   if(!OrderSend(request, result))
      Print("Sell order failed: ", GetLastError());
   else
      Print("Sell order placed: Ticket #", result.order);
}

//+------------------------------------------------------------------+
