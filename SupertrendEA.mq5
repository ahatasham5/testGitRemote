#property strict

input int    InpATRPeriod=10;
input double InpMultiplier=3.0;

int    superHandle=INVALID_HANDLE;
double up[],down[],trend[];

int OnInit()
{
   superHandle=iCustom(_Symbol,_Period,"Supertrend",InpATRPeriod,InpMultiplier);
   if(superHandle==INVALID_HANDLE)
      return(INIT_FAILED);
   ArraySetAsSeries(up,true);
   ArraySetAsSeries(down,true);
   ArraySetAsSeries(trend,true);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(superHandle!=INVALID_HANDLE)
      IndicatorRelease(superHandle);
}

void OnTick()
{
   if(superHandle==INVALID_HANDLE)
      return;

   if(CopyBuffer(superHandle,0,0,1,up)<=0)
      return;
   if(CopyBuffer(superHandle,1,0,1,down)<=0)
      return;
   if(CopyBuffer(superHandle,2,0,1,trend)<=0)
      return;

   double currentTrend=trend[0];
   // Example: print trend value
   Print("Supertrend:",currentTrend);
   // Trade logic can be implemented here using up[0],down[0],trend[0]
}
