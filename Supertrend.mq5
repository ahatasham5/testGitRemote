#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

#property indicator_label1  "UpTrend"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen

#property indicator_label2  "DownTrend"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed

#property indicator_label3  "SuperTrend"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrBlue

input int    InpATRPeriod=10;
input double InpMultiplier=3.0;

double UpTrendBuffer[];
double DownTrendBuffer[];
double SuperTrendBuffer[];

int OnInit()
{
   SetIndexBuffer(0,UpTrendBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DownTrendBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,SuperTrendBuffer,INDICATOR_DATA);
   ArraySetAsSeries(UpTrendBuffer,true);
   ArraySetAsSeries(DownTrendBuffer,true);
   ArraySetAsSeries(SuperTrendBuffer,true);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpATRPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpATRPeriod);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,InpATRPeriod);
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total<=InpATRPeriod)
      return(0);

   int start = prev_calculated>0 ? prev_calculated-1 : InpATRPeriod;

   double atr[];
   ArraySetAsSeries(atr,true);
   if(CopyBuffer(iATR(_Symbol,_Period,InpATRPeriod),0,0,rates_total,atr)<=0)
      return(0);

   for(int i=start;i<rates_total;i++)
   {
      double median = (high[i]+low[i])/2.0;
      double upperBand = median + InpMultiplier*atr[i];
      double lowerBand = median - InpMultiplier*atr[i];

      if(i==start)
      {
         UpTrendBuffer[i] = upperBand;
         DownTrendBuffer[i] = lowerBand;
         SuperTrendBuffer[i] = median;
         continue;
      }

      double prevClose = close[i-1];
      double prevUp    = UpTrendBuffer[i-1];
      double prevDown  = DownTrendBuffer[i-1];
      double prevSuper = SuperTrendBuffer[i-1];

      if(upperBand<prevUp || prevClose>prevUp)
         UpTrendBuffer[i]=upperBand;
      else
         UpTrendBuffer[i]=prevUp;

      if(lowerBand>prevDown || prevClose<prevDown)
         DownTrendBuffer[i]=lowerBand;
      else
         DownTrendBuffer[i]=prevDown;

      if(prevSuper==prevUp)
      {
         if(close[i]<=UpTrendBuffer[i])
            SuperTrendBuffer[i]=UpTrendBuffer[i];
         else
            SuperTrendBuffer[i]=DownTrendBuffer[i];
      }
      else
      {
         if(close[i]>=DownTrendBuffer[i])
            SuperTrendBuffer[i]=DownTrendBuffer[i];
         else
            SuperTrendBuffer[i]=UpTrendBuffer[i];
      }

      if(SuperTrendBuffer[i]==UpTrendBuffer[i])
      {
         DownTrendBuffer[i]=EMPTY_VALUE;
      }
      else
      {
         UpTrendBuffer[i]=EMPTY_VALUE;
      }
   }

   return(rates_total);
}
