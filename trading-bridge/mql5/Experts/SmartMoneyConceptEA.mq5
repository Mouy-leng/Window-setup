//+------------------------------------------------------------------+
//|                                         SmartMoneyConceptEA.mq5  |
//|                        Smart Money Concept + LTF Indicators       |
//|                        For Exness - Small Account ($149.83)       |
//+------------------------------------------------------------------+
#property copyright "Trading System 2025"
#property link      "https://github.com/yourusername"
#property version   "1.00"
#property description "Smart Money Concept EA with Lower Timeframe Indicators"
#property description "Pairs: EURUSD, USDJPY, XAUUSD, GBPJPY (Forex)"
#property description "Crypto: BTCUSD, BTCXAU (Weekend)"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
// Account Settings
input double   InpAccountBalance    = 149.83;      // Account Balance ($)
input double   InpRiskPercent       = 1.0;         // Risk Per Trade (%)
input double   InpMaxDailyLoss      = 3.0;         // Max Daily Loss (%)
input int      InpMaxTradesPerDay   = 5;           // Max Trades Per Day

// Smart Money Concept Settings
input int      InpHTFPeriod         = 240;         // HTF Analysis Period (M15=15, H1=60, H4=240)
input int      InpLTFPeriod         = 5;           // LTF Entry Period (M1=1, M5=5)
input int      InpOrderBlockLookback= 50;          // Order Block Lookback Bars
input int      InpFVGMinPips        = 5;           // Fair Value Gap Min Pips
input bool     InpUseBOS            = true;        // Use Break of Structure
input bool     InpUseCHOCH          = true;        // Use Change of Character

// LTF Indicators Settings
input int      InpRSIPeriod         = 14;          // RSI Period
input int      InpRSIOverbought     = 70;          // RSI Overbought Level
input int      InpRSIOversold       = 30;          // RSI Oversold Level
input int      InpEMAFast           = 8;           // Fast EMA Period
input int      InpEMASlow           = 21;          // Slow EMA Period
input int      InpATRPeriod         = 14;          // ATR Period for SL/TP

// Trade Management
input double   InpRiskReward        = 2.0;         // Risk:Reward Ratio
input int      InpSLPips            = 20;          // Default Stop Loss (pips)
input int      InpTPPips            = 40;          // Default Take Profit (pips)
input bool     InpUseTrailingStop   = true;        // Use Trailing Stop
input int      InpTrailingStart     = 15;          // Trailing Start (pips)
input int      InpTrailingStep      = 5;           // Trailing Step (pips)

// Trading Schedule (Server Time)
input int      InpStartHour         = 8;           // Trading Start Hour
input int      InpEndHour           = 20;          // Trading End Hour
input bool     InpTradeMonday       = true;        // Trade on Monday
input bool     InpTradeTuesday      = true;        // Trade on Tuesday
input bool     InpTradeWednesday    = true;        // Trade on Wednesday
input bool     InpTradeThursday     = true;        // Trade on Thursday
input bool     InpTradeFriday       = false;       // Trade on Friday (risky)
input bool     InpTradeWeekend      = false;       // Trade Weekend (Crypto Only)

// Magic Number
input int      InpMagicNumber       = 20251217;    // Magic Number

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  posInfo;
COrderInfo     orderInfo;

// Indicator handles
int            hRSI;
int            hEMAFast;
int            hEMASlow;
int            hATR;

// Trading state
datetime       lastTradeTime;
int            tradesToday;
double         dailyPnL;
datetime       currentDay;

// Smart Money structures
struct OrderBlock {
   double   highPrice;
   double   lowPrice;
   datetime time;
   bool     isBullish;
   bool     isValid;
};

struct FairValueGap {
   double   highPrice;
   double   lowPrice;
   datetime time;
   bool     isBullish;
   bool     isFilled;
};

struct MarketStructure {
   double   lastSwingHigh;
   double   lastSwingLow;
   bool     isBullishTrend;
   bool     bosDetected;
   bool     chochDetected;
};

OrderBlock     activeOrderBlocks[];
FairValueGap   activeFVGs[];
MarketStructure currentStructure;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   // Initialize indicators
   hRSI = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
   hEMAFast = iMA(_Symbol, PERIOD_CURRENT, InpEMAFast, 0, MODE_EMA, PRICE_CLOSE);
   hEMASlow = iMA(_Symbol, PERIOD_CURRENT, InpEMASlow, 0, MODE_EMA, PRICE_CLOSE);
   hATR = iATR(_Symbol, PERIOD_CURRENT, InpATRPeriod);
   
   if(hRSI == INVALID_HANDLE || hEMAFast == INVALID_HANDLE || 
      hEMASlow == INVALID_HANDLE || hATR == INVALID_HANDLE)
   {
      Print("ERROR: Failed to create indicator handles");
      return(INIT_FAILED);
   }
   
   // Initialize tracking
   lastTradeTime = 0;
   tradesToday = 0;
   dailyPnL = 0;
   currentDay = TimeCurrent();
   
   // Initialize market structure
   currentStructure.isBullishTrend = false;
   currentStructure.bosDetected = false;
   currentStructure.chochDetected = false;
   
   Print("Smart Money Concept EA initialized");
   Print("Account Balance: $", DoubleToString(InpAccountBalance, 2));
   Print("Risk per trade: ", DoubleToString(InpRiskPercent, 1), "%");
   Print("Max Daily Loss: ", DoubleToString(InpMaxDailyLoss, 1), "%");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release indicator handles
   IndicatorRelease(hRSI);
   IndicatorRelease(hEMAFast);
   IndicatorRelease(hEMASlow);
   IndicatorRelease(hATR);
   
   Print("Smart Money Concept EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Reset daily counters if new day
   ResetDailyCounters();
   
   // Check if trading is allowed
   if(!IsTradingAllowed())
      return;
   
   // Check daily loss limit
   if(IsDailyLossExceeded())
   {
      Print("Daily loss limit reached. No more trades today.");
      return;
   }
   
   // Check max trades per day
   if(tradesToday >= InpMaxTradesPerDay)
   {
      return;
   }
   
   // Manage existing positions (trailing stop)
   ManagePositions();
   
   // Only check for new entries on new bar
   if(!IsNewBar())
      return;
   
   // Skip if already have position for this symbol
   if(HasOpenPosition())
      return;
   
   // Analyze Smart Money Concept
   AnalyzeMarketStructure();
   DetectOrderBlocks();
   DetectFairValueGaps();
   
   // Get LTF indicator signals
   double rsi = GetRSI();
   bool emaSignalBuy = IsEMACrossUp();
   bool emaSignalSell = IsEMACrossDown();
   
   // Generate trade signal
   int signal = GenerateSignal(rsi, emaSignalBuy, emaSignalSell);
   
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
      Print("New trading day - counters reset");
   }
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                       |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   // Check day of week
   if(dt.day_of_week == 0) return InpTradeWeekend;  // Sunday
   if(dt.day_of_week == 1) return InpTradeMonday;
   if(dt.day_of_week == 2) return InpTradeTuesday;
   if(dt.day_of_week == 3) return InpTradeWednesday;
   if(dt.day_of_week == 4) return InpTradeThursday;
   if(dt.day_of_week == 5) return InpTradeFriday;
   if(dt.day_of_week == 6) return InpTradeWeekend;  // Saturday
   
   // Check trading hours
   if(dt.hour < InpStartHour || dt.hour >= InpEndHour)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if daily loss exceeded                                      |
//+------------------------------------------------------------------+
bool IsDailyLossExceeded()
{
   double maxLoss = InpAccountBalance * (InpMaxDailyLoss / 100.0);
   return (dailyPnL <= -maxLoss);
}

//+------------------------------------------------------------------+
//| Check if new bar formed                                           |
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
//| Check if already have position                                    |
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
//| Analyze market structure for Smart Money Concept                  |
//+------------------------------------------------------------------+
void AnalyzeMarketStructure()
{
   double highs[], lows[], closes[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   ArraySetAsSeries(closes, true);
   
   int copied = CopyHigh(_Symbol, PERIOD_H1, 0, InpOrderBlockLookback, highs);
   CopyLow(_Symbol, PERIOD_H1, 0, InpOrderBlockLookback, lows);
   CopyClose(_Symbol, PERIOD_H1, 0, InpOrderBlockLookback, closes);
   
   if(copied < InpOrderBlockLookback)
      return;
   
   // Find swing highs and lows
   double swingHigh = 0, swingLow = DBL_MAX;
   int swingHighIdx = 0, swingLowIdx = 0;
   
   for(int i = 2; i < InpOrderBlockLookback - 2; i++)
   {
      // Swing High detection
      if(highs[i] > highs[i-1] && highs[i] > highs[i-2] &&
         highs[i] > highs[i+1] && highs[i] > highs[i+2])
      {
         if(highs[i] > swingHigh)
         {
            swingHigh = highs[i];
            swingHighIdx = i;
         }
      }
      
      // Swing Low detection
      if(lows[i] < lows[i-1] && lows[i] < lows[i-2] &&
         lows[i] < lows[i+1] && lows[i] < lows[i+2])
      {
         if(lows[i] < swingLow)
         {
            swingLow = lows[i];
            swingLowIdx = i;
         }
      }
   }
   
   // Determine trend and structure
   double currentPrice = closes[0];
   bool prevBullish = currentStructure.isBullishTrend;
   
   currentStructure.lastSwingHigh = swingHigh;
   currentStructure.lastSwingLow = swingLow;
   currentStructure.isBullishTrend = (swingLowIdx > swingHighIdx);
   
   // Detect Break of Structure (BOS)
   if(InpUseBOS)
   {
      if(currentStructure.isBullishTrend && currentPrice > swingHigh)
      {
         currentStructure.bosDetected = true;
         Print("BOS: Bullish break of structure detected");
      }
      else if(!currentStructure.isBullishTrend && currentPrice < swingLow)
      {
         currentStructure.bosDetected = true;
         Print("BOS: Bearish break of structure detected");
      }
      else
      {
         currentStructure.bosDetected = false;
      }
   }
   
   // Detect Change of Character (CHOCH)
   if(InpUseCHOCH)
   {
      if(prevBullish && !currentStructure.isBullishTrend)
      {
         currentStructure.chochDetected = true;
         Print("CHOCH: Bearish change of character detected");
      }
      else if(!prevBullish && currentStructure.isBullishTrend)
      {
         currentStructure.chochDetected = true;
         Print("CHOCH: Bullish change of character detected");
      }
      else
      {
         currentStructure.chochDetected = false;
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Order Blocks                                               |
//+------------------------------------------------------------------+
void DetectOrderBlocks()
{
   ArrayFree(activeOrderBlocks);
   
   double opens[], closes[], highs[], lows[];
   ArraySetAsSeries(opens, true);
   ArraySetAsSeries(closes, true);
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   
   CopyOpen(_Symbol, PERIOD_H1, 0, InpOrderBlockLookback, opens);
   CopyClose(_Symbol, PERIOD_H1, 0, InpOrderBlockLookback, closes);
   CopyHigh(_Symbol, PERIOD_H1, 0, InpOrderBlockLookback, highs);
   CopyLow(_Symbol, PERIOD_H1, 0, InpOrderBlockLookback, lows);
   
   datetime times[];
   ArraySetAsSeries(times, true);
   CopyTime(_Symbol, PERIOD_H1, 0, InpOrderBlockLookback, times);
   
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   for(int i = 3; i < InpOrderBlockLookback - 1; i++)
   {
      // Bullish Order Block: Last down candle before strong up move
      if(closes[i] < opens[i] &&                    // Bearish candle
         closes[i-1] > opens[i-1] &&                // Followed by bullish
         closes[i-2] > opens[i-2] &&                // And another bullish
         (highs[i-1] - lows[i-1]) > (highs[i] - lows[i]) * 1.5)  // Strong move
      {
         // Check if price is near OB (within 50 pips)
         double obHigh = highs[i];
         double obLow = lows[i];
         
         if(currentPrice >= obLow && currentPrice <= obHigh + 50 * _Point)
         {
            OrderBlock ob;
            ob.highPrice = obHigh;
            ob.lowPrice = obLow;
            ob.time = times[i];
            ob.isBullish = true;
            ob.isValid = true;
            
            int size = ArraySize(activeOrderBlocks);
            ArrayResize(activeOrderBlocks, size + 1);
            activeOrderBlocks[size] = ob;
         }
      }
      
      // Bearish Order Block: Last up candle before strong down move
      if(closes[i] > opens[i] &&                    // Bullish candle
         closes[i-1] < opens[i-1] &&                // Followed by bearish
         closes[i-2] < opens[i-2] &&                // And another bearish
         (highs[i-1] - lows[i-1]) > (highs[i] - lows[i]) * 1.5)  // Strong move
      {
         double obHigh = highs[i];
         double obLow = lows[i];
         
         if(currentPrice <= obHigh && currentPrice >= obLow - 50 * _Point)
         {
            OrderBlock ob;
            ob.highPrice = obHigh;
            ob.lowPrice = obLow;
            ob.time = times[i];
            ob.isBullish = false;
            ob.isValid = true;
            
            int size = ArraySize(activeOrderBlocks);
            ArrayResize(activeOrderBlocks, size + 1);
            activeOrderBlocks[size] = ob;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Fair Value Gaps                                            |
//+------------------------------------------------------------------+
void DetectFairValueGaps()
{
   ArrayFree(activeFVGs);
   
   double highs[], lows[];
   ArraySetAsSeries(highs, true);
   ArraySetAsSeries(lows, true);
   
   CopyHigh(_Symbol, PERIOD_H1, 0, InpOrderBlockLookback, highs);
   CopyLow(_Symbol, PERIOD_H1, 0, InpOrderBlockLookback, lows);
   
   datetime times[];
   ArraySetAsSeries(times, true);
   CopyTime(_Symbol, PERIOD_H1, 0, InpOrderBlockLookback, times);
   
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double minGap = InpFVGMinPips * _Point * 10;
   
   for(int i = 2; i < InpOrderBlockLookback - 1; i++)
   {
      // Bullish FVG: Gap between candle 0 low and candle 2 high
      if(lows[i-2] > highs[i])
      {
         double gapSize = lows[i-2] - highs[i];
         if(gapSize >= minGap)
         {
            // Check if price is in or near FVG
            if(currentPrice >= highs[i] && currentPrice <= lows[i-2])
            {
               FairValueGap fvg;
               fvg.highPrice = lows[i-2];
               fvg.lowPrice = highs[i];
               fvg.time = times[i-1];
               fvg.isBullish = true;
               fvg.isFilled = false;
               
               int size = ArraySize(activeFVGs);
               ArrayResize(activeFVGs, size + 1);
               activeFVGs[size] = fvg;
            }
         }
      }
      
      // Bearish FVG: Gap between candle 0 high and candle 2 low
      if(highs[i-2] < lows[i])
      {
         double gapSize = lows[i] - highs[i-2];
         if(gapSize >= minGap)
         {
            if(currentPrice <= lows[i] && currentPrice >= highs[i-2])
            {
               FairValueGap fvg;
               fvg.highPrice = lows[i];
               fvg.lowPrice = highs[i-2];
               fvg.time = times[i-1];
               fvg.isBullish = false;
               fvg.isFilled = false;
               
               int size = ArraySize(activeFVGs);
               ArrayResize(activeFVGs, size + 1);
               activeFVGs[size] = fvg;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get RSI value                                                     |
//+------------------------------------------------------------------+
double GetRSI()
{
   double rsi[];
   ArraySetAsSeries(rsi, true);
   
   if(CopyBuffer(hRSI, 0, 0, 3, rsi) < 3)
      return 50.0;
   
   return rsi[0];
}

//+------------------------------------------------------------------+
//| Check EMA cross up                                                |
//+------------------------------------------------------------------+
bool IsEMACrossUp()
{
   double emaFast[], emaSlow[];
   ArraySetAsSeries(emaFast, true);
   ArraySetAsSeries(emaSlow, true);
   
   if(CopyBuffer(hEMAFast, 0, 0, 3, emaFast) < 3)
      return false;
   if(CopyBuffer(hEMASlow, 0, 0, 3, emaSlow) < 3)
      return false;
   
   // Cross up: fast was below slow, now above
   return (emaFast[1] <= emaSlow[1] && emaFast[0] > emaSlow[0]);
}

//+------------------------------------------------------------------+
//| Check EMA cross down                                              |
//+------------------------------------------------------------------+
bool IsEMACrossDown()
{
   double emaFast[], emaSlow[];
   ArraySetAsSeries(emaFast, true);
   ArraySetAsSeries(emaSlow, true);
   
   if(CopyBuffer(hEMAFast, 0, 0, 3, emaFast) < 3)
      return false;
   if(CopyBuffer(hEMASlow, 0, 0, 3, emaSlow) < 3)
      return false;
   
   // Cross down: fast was above slow, now below
   return (emaFast[1] >= emaSlow[1] && emaFast[0] < emaSlow[0]);
}

//+------------------------------------------------------------------+
//| Get ATR value for position sizing                                 |
//+------------------------------------------------------------------+
double GetATR()
{
   double atr[];
   ArraySetAsSeries(atr, true);
   
   if(CopyBuffer(hATR, 0, 0, 1, atr) < 1)
      return InpSLPips * _Point * 10;
   
   return atr[0];
}

//+------------------------------------------------------------------+
//| Generate trading signal                                           |
//+------------------------------------------------------------------+
int GenerateSignal(double rsi, bool emaBuy, bool emaSell)
{
   int smcSignal = 0;
   int ltfSignal = 0;
   
   // SMC Analysis
   // Bullish setup: Bullish OB + Price in OB + Bullish structure
   for(int i = 0; i < ArraySize(activeOrderBlocks); i++)
   {
      if(activeOrderBlocks[i].isBullish && activeOrderBlocks[i].isValid)
      {
         if(currentStructure.isBullishTrend || currentStructure.chochDetected)
         {
            smcSignal = 1;  // Buy signal
            break;
         }
      }
      else if(!activeOrderBlocks[i].isBullish && activeOrderBlocks[i].isValid)
      {
         if(!currentStructure.isBullishTrend || currentStructure.chochDetected)
         {
            smcSignal = -1;  // Sell signal
            break;
         }
      }
   }
   
   // FVG confluence
   for(int i = 0; i < ArraySize(activeFVGs); i++)
   {
      if(activeFVGs[i].isBullish && !activeFVGs[i].isFilled && smcSignal >= 0)
      {
         smcSignal = 1;
      }
      else if(!activeFVGs[i].isBullish && !activeFVGs[i].isFilled && smcSignal <= 0)
      {
         smcSignal = -1;
      }
   }
   
   // LTF Indicator confirmation
   if(emaBuy && rsi < InpRSIOverbought && rsi > InpRSIOversold)
   {
      ltfSignal = 1;
   }
   else if(emaSell && rsi > InpRSIOversold && rsi < InpRSIOverbought)
   {
      ltfSignal = -1;
   }
   
   // RSI divergence (oversold for buy, overbought for sell)
   if(rsi < InpRSIOversold && smcSignal > 0)
   {
      ltfSignal = 1;
   }
   else if(rsi > InpRSIOverbought && smcSignal < 0)
   {
      ltfSignal = -1;
   }
   
   // Final signal: SMC + LTF confluence
   if(smcSignal == 1 && ltfSignal >= 0)
   {
      Print("BUY Signal: SMC=", smcSignal, " LTF=", ltfSignal, " RSI=", DoubleToString(rsi, 1));
      return 1;
   }
   else if(smcSignal == -1 && ltfSignal <= 0)
   {
      Print("SELL Signal: SMC=", smcSignal, " LTF=", ltfSignal, " RSI=", DoubleToString(rsi, 1));
      return -1;
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Execute trade                                                     |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal)
{
   double atr = GetATR();
   double slPoints = MathMax(atr * 1.5, InpSLPips * _Point * 10);
   double tpPoints = slPoints * InpRiskReward;
   
   // Calculate position size based on risk
   double riskAmount = InpAccountBalance * (InpRiskPercent / 100.0);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pointValue = tickValue / tickSize * _Point;
   
   double lotSize = riskAmount / (slPoints / _Point * pointValue);
   
   // Normalize lot size
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lotSize = MathMax(minLot, MathMin(maxLot, MathFloor(lotSize / lotStep) * lotStep));
   
   // For small accounts, use minimum lot
   if(lotSize < minLot)
      lotSize = minLot;
   
   double price, sl, tp;
   
   if(signal == 1)  // BUY
   {
      price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      sl = NormalizeDouble(price - slPoints, _Digits);
      tp = NormalizeDouble(price + tpPoints, _Digits);
      
      if(trade.Buy(lotSize, _Symbol, price, sl, tp, "SMC Buy"))
      {
         Print("BUY executed: Lot=", lotSize, " SL=", sl, " TP=", tp);
         tradesToday++;
         lastTradeTime = TimeCurrent();
      }
      else
      {
         Print("BUY failed: ", trade.ResultRetcodeDescription());
      }
   }
   else if(signal == -1)  // SELL
   {
      price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      sl = NormalizeDouble(price + slPoints, _Digits);
      tp = NormalizeDouble(price - tpPoints, _Digits);
      
      if(trade.Sell(lotSize, _Symbol, price, sl, tp, "SMC Sell"))
      {
         Print("SELL executed: Lot=", lotSize, " SL=", sl, " TP=", tp);
         tradesToday++;
         lastTradeTime = TimeCurrent();
      }
      else
      {
         Print("SELL failed: ", trade.ResultRetcodeDescription());
      }
   }
}

//+------------------------------------------------------------------+
//| Manage existing positions (trailing stop)                        |
//+------------------------------------------------------------------+
void ManagePositions()
{
   if(!InpUseTrailingStop)
      return;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(posInfo.SelectByIndex(i))
      {
         if(posInfo.Symbol() != _Symbol || posInfo.Magic() != InpMagicNumber)
            continue;
         
         double currentProfit = posInfo.Profit();
         double openPrice = posInfo.PriceOpen();
         double currentSL = posInfo.StopLoss();
         double trailingStart = InpTrailingStart * _Point * 10;
         double trailingStep = InpTrailingStep * _Point * 10;
         
         if(posInfo.PositionType() == POSITION_TYPE_BUY)
         {
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double profit = bid - openPrice;
            
            if(profit >= trailingStart)
            {
               double newSL = NormalizeDouble(bid - trailingStep, _Digits);
               if(newSL > currentSL)
               {
                  trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
               }
            }
         }
         else if(posInfo.PositionType() == POSITION_TYPE_SELL)
         {
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double profit = openPrice - ask;
            
            if(profit >= trailingStart)
            {
               double newSL = NormalizeDouble(ask + trailingStep, _Digits);
               if(newSL < currentSL || currentSL == 0)
               {
                  trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
               }
            }
         }
         
         // Update daily PnL
         dailyPnL += currentProfit;
      }
   }
}

//+------------------------------------------------------------------+























