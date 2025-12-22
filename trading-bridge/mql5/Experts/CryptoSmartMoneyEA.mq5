//+------------------------------------------------------------------+
//|                                        CryptoSmartMoneyEA.mq5    |
//|                   Smart Money + Fear & Greed for Crypto          |
//|                   For BTCUSD, BTCXAU - Weekend Trading           |
//+------------------------------------------------------------------+
#property copyright "Trading System 2025"
#property link      "https://github.com/yourusername"
#property version   "1.00"
#property description "Crypto Smart Money EA with Fear & Greed Index"
#property description "Pairs: BTCUSD, BTCXAU"
#property description "Weekend Trading Optimized"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
// Account Settings
input double   InpAccountBalance    = 15.0;        // Account Balance (ETH equivalent in $)
input double   InpRiskPercent       = 2.0;         // Risk Per Trade (%)
input double   InpMaxDailyLoss      = 5.0;         // Max Daily Loss (%)
input int      InpMaxTradesPerDay   = 3;           // Max Trades Per Day

// Smart Money Concept Settings
input int      InpOrderBlockLookback= 100;         // Order Block Lookback (crypto volatile)
input int      InpFVGMinPips        = 50;          // FVG Min Pips (crypto larger moves)
input bool     InpUseLiquidity      = true;        // Hunt Liquidity Zones

// Fear & Greed Simulation (via price action)
input int      InpVolatilityPeriod  = 20;          // Volatility Period
input double   InpFearThreshold     = 25.0;        // Fear Threshold (high vol = fear)
input double   InpGreedThreshold    = 75.0;        // Greed Threshold (low vol = greed)

// LTF Indicators
input int      InpRSIPeriod         = 14;          // RSI Period
input int      InpBBPeriod          = 20;          // Bollinger Bands Period
input double   InpBBDeviation       = 2.0;         // BB Deviation
input int      InpMACDFast          = 12;          // MACD Fast
input int      InpMACDSlow          = 26;          // MACD Slow
input int      InpMACDSignal        = 9;           // MACD Signal

// Trade Management
input double   InpRiskReward        = 3.0;         // Risk:Reward (crypto higher)
input int      InpSLPips            = 100;         // Default Stop Loss (pips)
input bool     InpUseBreakeven      = true;        // Move SL to Breakeven
input int      InpBreakevenPips     = 50;          // Breakeven Trigger (pips)

// Trading Schedule
input bool     InpTradeWeekdays     = false;       // Trade Weekdays
input bool     InpTradeWeekend      = true;        // Trade Weekend (Primary)
input int      InpStartHour         = 0;           // Trading Start Hour
input int      InpEndHour           = 24;          // Trading End Hour

// Magic Number
input int      InpMagicNumber       = 20251218;    // Magic Number

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  posInfo;

// Indicator handles
int            hRSI;
int            hBB;
int            hMACD;
int            hATR;

// Trading state
int            tradesToday;
double         dailyPnL;
datetime       currentDay;

// Fear & Greed state
double         currentFearGreed;    // 0=Extreme Fear, 100=Extreme Greed

// Smart Money structures
struct LiquidityZone {
   double   price;
   bool     isHighLiquidity;  // true = above (sell stops), false = below (buy stops)
   datetime time;
   bool     swept;
};

LiquidityZone  liquidityZones[];

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(50);  // Higher deviation for crypto
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   // Initialize indicators
   hRSI = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
   hBB = iBands(_Symbol, PERIOD_CURRENT, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   hMACD = iMACD(_Symbol, PERIOD_CURRENT, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
   hATR = iATR(_Symbol, PERIOD_CURRENT, InpVolatilityPeriod);
   
   if(hRSI == INVALID_HANDLE || hBB == INVALID_HANDLE || 
      hMACD == INVALID_HANDLE || hATR == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create indicator handles");
      return(INIT_FAILED);
   }
   
   // Initialize tracking
   tradesToday = 0;
   dailyPnL = 0;
   currentDay = TimeCurrent();
   currentFearGreed = 50.0;  // Neutral start
   
   Print("Crypto Smart Money EA initialized");
   Print("Account Balance: $", DoubleToString(InpAccountBalance, 2));
   Print("Pairs: BTCUSD, BTCXAU");
   Print("Mode: Weekend Trading with Fear & Greed Analysis");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(hRSI);
   IndicatorRelease(hBB);
   IndicatorRelease(hMACD);
   IndicatorRelease(hATR);
   
   Print("Crypto Smart Money EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Reset daily counters
   ResetDailyCounters();
   
   // Check trading schedule
   if(!IsTradingTime())
      return;
   
   // Check daily loss
   if(IsDailyLossExceeded())
      return;
   
   // Check max trades
   if(tradesToday >= InpMaxTradesPerDay)
      return;
   
   // Manage positions (breakeven)
   ManagePositions();
   
   // Only on new bar
   if(!IsNewBar())
      return;
   
   // Skip if position exists
   if(HasOpenPosition())
      return;
   
   // Calculate Fear & Greed from price action
   CalculateFearGreed();
   
   // Detect liquidity zones
   DetectLiquidityZones();
   
   // Get indicator values
   double rsi = GetRSI();
   int bbSignal = GetBBSignal();
   int macdSignal = GetMACDSignal();
   
   // Generate signal
   int signal = GenerateCryptoSignal(rsi, bbSignal, macdSignal);
   
   if(signal != 0)
   {
      ExecuteTrade(signal);
   }
}

//+------------------------------------------------------------------+
//| Reset daily counters                                              |
//+------------------------------------------------------------------+
void ResetDailyCounters()
{
   MqlDateTime dtCurrent, dtLast;
   TimeToStruct(TimeCurrent(), dtCurrent);
   TimeToStruct(currentDay, dtLast);
   
   if(dtCurrent.day != dtLast.day)
   {
      tradesToday = 0;
      dailyPnL = 0;
      currentDay = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| Check trading time                                                |
//+------------------------------------------------------------------+
bool IsTradingTime()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   bool isWeekend = (dt.day_of_week == 0 || dt.day_of_week == 6);
   
   if(isWeekend && !InpTradeWeekend)
      return false;
   if(!isWeekend && !InpTradeWeekdays)
      return false;
   
   if(dt.hour < InpStartHour || dt.hour >= InpEndHour)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check daily loss                                                  |
//+------------------------------------------------------------------+
bool IsDailyLossExceeded()
{
   double maxLoss = InpAccountBalance * (InpMaxDailyLoss / 100.0);
   return (dailyPnL <= -maxLoss);
}

//+------------------------------------------------------------------+
//| Check new bar                                                     |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   if(lastBarTime != currentBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check open position                                               |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(posInfo.SelectByIndex(i))
      {
         if(posInfo.Symbol() == _Symbol && posInfo.Magic() == InpMagicNumber)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Calculate Fear & Greed from volatility and price action          |
//+------------------------------------------------------------------+
void CalculateFearGreed()
{
   double atr[];
   ArraySetAsSeries(atr, true);
   
   if(CopyBuffer(hATR, 0, 0, InpVolatilityPeriod, atr) < InpVolatilityPeriod)
   {
      currentFearGreed = 50.0;
      return;
   }
   
   // Calculate average ATR
   double avgATR = 0;
   for(int i = 0; i < InpVolatilityPeriod; i++)
      avgATR += atr[i];
   avgATR /= InpVolatilityPeriod;
   
   // Current ATR vs Average
   double currentATR = atr[0];
   double volatilityRatio = currentATR / avgATR;
   
   // Get recent price action
   double closes[];
   ArraySetAsSeries(closes, true);
   CopyClose(_Symbol, PERIOD_H4, 0, 10, closes);
   
   // Calculate momentum
   double momentum = 0;
   if(ArraySize(closes) >= 10)
   {
      momentum = (closes[0] - closes[9]) / closes[9] * 100;
   }
   
   // Fear & Greed calculation
   // High volatility + negative momentum = FEAR (buy opportunity)
   // Low volatility + positive momentum = GREED (sell opportunity)
   
   double fearGreedBase = 50.0;
   
   // Volatility component (inverted - high vol = more fear)
   if(volatilityRatio > 1.5)
      fearGreedBase -= 25;  // High volatility = fear
   else if(volatilityRatio < 0.7)
      fearGreedBase += 25;  // Low volatility = complacency/greed
   
   // Momentum component
   if(momentum > 5)
      fearGreedBase += 20;  // Strong up = greed
   else if(momentum < -5)
      fearGreedBase -= 20;  // Strong down = fear
   
   currentFearGreed = MathMax(0, MathMin(100, fearGreedBase));
   
   string sentiment = "";
   if(currentFearGreed < 25) sentiment = "EXTREME FEAR";
   else if(currentFearGreed < 45) sentiment = "FEAR";
   else if(currentFearGreed < 55) sentiment = "NEUTRAL";
   else if(currentFearGreed < 75) sentiment = "GREED";
   else sentiment = "EXTREME GREED";
   
   Print("Fear & Greed: ", DoubleToString(currentFearGreed, 1), " (", sentiment, ")");
}

//+------------------------------------------------------------------+
//| Detect liquidity zones (stop hunt levels)                        |
//+------------------------------------------------------------------+
void DetectLiquidityZones()
{
   ArrayFree(liquidityZones);
   
   double highs[], lows[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   
   CopyHigh(_Symbol, PERIOD_H4, 0, InpOrderBlockLookback, highs);
   CopyLow(_Symbol, PERIOD_H4, 0, InpOrderBlockLookback, lows);
   
   datetime times[];
   ArraySetAsSeries(times, true);
   CopyTime(_Symbol, PERIOD_H4, 0, InpOrderBlockLookback, times);
   
   // Find swing highs (sell stop liquidity)
   for(int i = 2; i < InpOrderBlockLookback - 2; i++)
   {
      if(highs[i] > highs[i-1] && highs[i] > highs[i-2] &&
         highs[i] > highs[i+1] && highs[i] > highs[i+2])
      {
         LiquidityZone lz;
         lz.price = highs[i];
         lz.isHighLiquidity = true;
         lz.time = times[i];
         lz.swept = false;
         
         int size = ArraySize(liquidityZones);
         ArrayResize(liquidityZones, size + 1);
         liquidityZones[size] = lz;
      }
   }
   
   // Find swing lows (buy stop liquidity)
   for(int i = 2; i < InpOrderBlockLookback - 2; i++)
   {
      if(lows[i] < lows[i-1] && lows[i] < lows[i-2] &&
         lows[i] < lows[i+1] && lows[i] < lows[i+2])
      {
         LiquidityZone lz;
         lz.price = lows[i];
         lz.isHighLiquidity = false;
         lz.time = times[i];
         lz.swept = false;
         
         int size = ArraySize(liquidityZones);
         ArrayResize(liquidityZones, size + 1);
         liquidityZones[size] = lz;
      }
   }
}

//+------------------------------------------------------------------+
//| Get RSI                                                           |
//+------------------------------------------------------------------+
double GetRSI()
{
   double rsi[];
   ArraySetAsSeries(rsi, true);
   
   if(CopyBuffer(hRSI, 0, 0, 1, rsi) < 1)
      return 50.0;
   
   return rsi[0];
}

//+------------------------------------------------------------------+
//| Get Bollinger Bands signal                                        |
//+------------------------------------------------------------------+
int GetBBSignal()
{
   double upper[], lower[], middle[];
   ArraySetAsSeries(upper, true);
   ArraySetAsSeries(lower, true);
   ArraySetAsSeries(middle, true);
   
   if(CopyBuffer(hBB, 1, 0, 1, upper) < 1) return 0;
   if(CopyBuffer(hBB, 2, 0, 1, lower) < 1) return 0;
   if(CopyBuffer(hBB, 0, 0, 1, middle) < 1) return 0;
   
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   if(price <= lower[0])
      return 1;   // Price at lower band = potential buy
   if(price >= upper[0])
      return -1;  // Price at upper band = potential sell
   
   return 0;
}

//+------------------------------------------------------------------+
//| Get MACD signal                                                   |
//+------------------------------------------------------------------+
int GetMACDSignal()
{
   double macdMain[], macdSignal[];
   ArraySetAsSeries(macdMain, true);
   ArraySetAsSeries(macdSignal, true);
   
   if(CopyBuffer(hMACD, 0, 0, 3, macdMain) < 3) return 0;
   if(CopyBuffer(hMACD, 1, 0, 3, macdSignal) < 3) return 0;
   
   // Bullish cross
   if(macdMain[1] <= macdSignal[1] && macdMain[0] > macdSignal[0])
      return 1;
   
   // Bearish cross
   if(macdMain[1] >= macdSignal[1] && macdMain[0] < macdSignal[0])
      return -1;
   
   return 0;
}

//+------------------------------------------------------------------+
//| Generate crypto trading signal                                    |
//+------------------------------------------------------------------+
int GenerateCryptoSignal(double rsi, int bbSignal, int macdSignal)
{
   int fearGreedSignal = 0;
   int liquiditySignal = 0;
   int indicatorSignal = 0;
   
   // Fear & Greed trading logic
   // Buy when FEAR (contrarian)
   // Sell when GREED (contrarian)
   if(currentFearGreed < InpFearThreshold)
   {
      fearGreedSignal = 1;  // FEAR = Buy opportunity
      Print("Fear & Greed: FEAR - Looking for BUY");
   }
   else if(currentFearGreed > InpGreedThreshold)
   {
      fearGreedSignal = -1;  // GREED = Sell opportunity
      Print("Fear & Greed: GREED - Looking for SELL");
   }
   
   // Liquidity sweep detection
   if(InpUseLiquidity)
   {
      double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      for(int i = 0; i < ArraySize(liquidityZones); i++)
      {
         if(liquidityZones[i].swept)
            continue;
         
         double distance = MathAbs(currentPrice - liquidityZones[i].price);
         double threshold = InpFVGMinPips * _Point * 10;
         
         // Price swept above liquidity (sell stops taken) = potential reversal down
         if(liquidityZones[i].isHighLiquidity && 
            currentPrice > liquidityZones[i].price &&
            distance < threshold * 2)
         {
            liquiditySignal = -1;
            Print("Liquidity Sweep: Above high - potential SELL");
         }
         // Price swept below liquidity (buy stops taken) = potential reversal up
         else if(!liquidityZones[i].isHighLiquidity && 
                 currentPrice < liquidityZones[i].price &&
                 distance < threshold * 2)
         {
            liquiditySignal = 1;
            Print("Liquidity Sweep: Below low - potential BUY");
         }
      }
   }
   
   // Indicator confluence
   if(bbSignal == 1 && macdSignal >= 0 && rsi < 40)
   {
      indicatorSignal = 1;
   }
   else if(bbSignal == -1 && macdSignal <= 0 && rsi > 60)
   {
      indicatorSignal = -1;
   }
   
   // Final signal logic
   // Need at least 2 confirmations
   int totalBuy = 0, totalSell = 0;
   
   if(fearGreedSignal == 1) totalBuy++;
   if(fearGreedSignal == -1) totalSell++;
   if(liquiditySignal == 1) totalBuy++;
   if(liquiditySignal == -1) totalSell++;
   if(indicatorSignal == 1) totalBuy++;
   if(indicatorSignal == -1) totalSell++;
   
   if(totalBuy >= 2)
   {
      Print("CRYPTO BUY: F&G=", fearGreedSignal, " Liq=", liquiditySignal, " Ind=", indicatorSignal);
      return 1;
   }
   else if(totalSell >= 2)
   {
      Print("CRYPTO SELL: F&G=", fearGreedSignal, " Liq=", liquiditySignal, " Ind=", indicatorSignal);
      return -1;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Execute trade                                                     |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal)
{
   double atr[];
   ArraySetAsSeries(atr, true);
   CopyBuffer(hATR, 0, 0, 1, atr);
   
   double slPoints = MathMax(atr[0] * 2, InpSLPips * _Point * 10);
   double tpPoints = slPoints * InpRiskReward;
   
   // Position sizing for small account
   double riskAmount = InpAccountBalance * (InpRiskPercent / 100.0);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   
   if(tickSize == 0) tickSize = _Point;
   if(tickValue == 0) tickValue = 1;
   
   double pointValue = tickValue / tickSize * _Point;
   double lotSize = riskAmount / (slPoints / _Point * pointValue);
   
   // Normalize
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(lotStep == 0) lotStep = 0.01;
   lotSize = MathMax(minLot, MathMin(maxLot, MathFloor(lotSize / lotStep) * lotStep));
   
   double price, sl, tp;
   
   if(signal == 1)
   {
      price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      sl = NormalizeDouble(price - slPoints, _Digits);
      tp = NormalizeDouble(price + tpPoints, _Digits);
      
      if(trade.Buy(lotSize, _Symbol, price, sl, tp, "Crypto SMC Buy"))
      {
         Print("CRYPTO BUY: Lot=", lotSize, " SL=", sl, " TP=", tp);
         tradesToday++;
      }
   }
   else if(signal == -1)
   {
      price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      sl = NormalizeDouble(price + slPoints, _Digits);
      tp = NormalizeDouble(price - tpPoints, _Digits);
      
      if(trade.Sell(lotSize, _Symbol, price, sl, tp, "Crypto SMC Sell"))
      {
         Print("CRYPTO SELL: Lot=", lotSize, " SL=", sl, " TP=", tp);
         tradesToday++;
      }
   }
}

//+------------------------------------------------------------------+
//| Manage positions                                                  |
//+------------------------------------------------------------------+
void ManagePositions()
{
   if(!InpUseBreakeven)
      return;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(posInfo.SelectByIndex(i))
      {
         if(posInfo.Symbol() != _Symbol || posInfo.Magic() != InpMagicNumber)
            continue;
         
         double openPrice = posInfo.PriceOpen();
         double currentSL = posInfo.StopLoss();
         double beThreshold = InpBreakevenPips * _Point * 10;
         
         if(posInfo.PositionType() == POSITION_TYPE_BUY)
         {
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            
            if(bid - openPrice >= beThreshold && currentSL < openPrice)
            {
               double newSL = openPrice + _Point * 10;  // 1 pip profit
               trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
               Print("Moved to breakeven: ", posInfo.Ticket());
            }
         }
         else
         {
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            
            if(openPrice - ask >= beThreshold && (currentSL > openPrice || currentSL == 0))
            {
               double newSL = openPrice - _Point * 10;
               trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
               Print("Moved to breakeven: ", posInfo.Ticket());
            }
         }
         
         dailyPnL += posInfo.Profit();
      }
   }
}

//+------------------------------------------------------------------+























