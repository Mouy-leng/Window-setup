//+------------------------------------------------------------------+
//|                                             SecureTrading.mq5    |
//|                                     Security-Enhanced Trading EA |
//|                             For secure local and remote execution|
//+------------------------------------------------------------------+
#property copyright "Window-Setup Security"
#property link      "https://github.com/Mouy-leng/Window-setup"
#property version   "1.00"
#property strict

//--- Security Configuration
input bool     EnableSecurity = true;           // Enable security features
input bool     AllowWebRequests = true;         // Allow web requests
input int      MaxDailyTrades = 50;            // Maximum trades per day
input double   MaxRiskPerTrade = 0.02;         // Maximum risk per trade (2%)
input bool     LogAllOperations = true;        // Log all operations for audit
input string   TrustedHosts = "localhost,127.0.0.1"; // Trusted hosts for web requests

//--- Global Variables
int dailyTradeCount = 0;
datetime lastResetDate;
string logFile = "secure_trading.log";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    //--- Initialize security features
    if(EnableSecurity)
    {
        Print("Security features enabled");
        InitializeSecurity();
    }
    
    //--- Set up logging
    if(LogAllOperations)
    {
        LogMessage("EA Initialized - Security Mode: " + (string)EnableSecurity);
    }
    
    //--- Initialize trade counter
    lastResetDate = TimeCurrent();
    dailyTradeCount = 0;
    
    //--- Check terminal permissions
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        Alert("Trading is not allowed. Please check terminal settings.");
        return(INIT_FAILED);
    }
    
    //--- Verify account security
    if(EnableSecurity && !VerifyAccountSecurity())
    {
        Alert("Account security verification failed!");
        return(INIT_FAILED);
    }
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(LogAllOperations)
    {
        LogMessage("EA Stopped - Reason: " + (string)reason);
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Reset daily counter if new day
    if(TimeToStruct(TimeCurrent()).day != TimeToStruct(lastResetDate).day)
    {
        dailyTradeCount = 0;
        lastResetDate = TimeCurrent();
        LogMessage("Daily trade counter reset");
    }
    
    //--- Security check before trading
    if(EnableSecurity && !PerformSecurityCheck())
    {
        LogMessage("Security check failed - trading suspended", true);
        return;
    }
    
    //--- Your trading logic here
    // This is a template - implement your strategy
}

//+------------------------------------------------------------------+
//| Initialize security features                                     |
//+------------------------------------------------------------------+
void InitializeSecurity()
{
    //--- Verify DLL imports are disabled unless explicitly needed
    if(!MQL5InfoInteger(MQL5_DLLS_ALLOWED))
    {
        Print("DLL imports disabled - Enhanced security mode");
    }
    
    //--- Check web request permissions
    if(AllowWebRequests && !TerminalInfoInteger(TERMINAL_CONNECTED))
    {
        Print("Warning: Terminal not connected to internet");
    }
    
    //--- Log security initialization
    LogMessage("Security features initialized successfully");
}

//+------------------------------------------------------------------+
//| Verify account security                                          |
//+------------------------------------------------------------------+
bool VerifyAccountSecurity()
{
    //--- Check account type
    ENUM_ACCOUNT_TRADE_MODE accountMode = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
    
    if(accountMode == ACCOUNT_TRADE_MODE_DEMO)
    {
        LogMessage("Running on DEMO account - Security verified");
        return true;
    }
    else if(accountMode == ACCOUNT_TRADE_MODE_REAL)
    {
        LogMessage("WARNING: Running on REAL account - Extra caution advised", true);
        //--- Additional real account verification
        if(AccountInfoDouble(ACCOUNT_BALANCE) < 100)
        {
            LogMessage("Account balance too low for safe trading", true);
            return false;
        }
        return true;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Perform security check                                           |
//+------------------------------------------------------------------+
bool PerformSecurityCheck()
{
    //--- Check daily trade limit
    if(dailyTradeCount >= MaxDailyTrades)
    {
        LogMessage("Daily trade limit reached: " + (string)MaxDailyTrades, true);
        return false;
    }
    
    //--- Check if trading is allowed
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        LogMessage("Trading not allowed by terminal", true);
        return false;
    }
    
    //--- Check connection status
    if(!TerminalInfoInteger(TERMINAL_CONNECTED))
    {
        LogMessage("Terminal not connected to server", true);
        return false;
    }
    
    //--- All checks passed
    return true;
}

//+------------------------------------------------------------------+
//| Calculate position size with risk management                     |
//+------------------------------------------------------------------+
double CalculateSecurePositionSize(double stopLossPips)
{
    //--- Get account balance
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    //--- Calculate maximum risk amount
    double riskAmount = balance * MaxRiskPerTrade;
    
    //--- Calculate pip value
    double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    
    //--- Calculate position size
    double positionSize = riskAmount / (stopLossPips * pipValue);
    
    //--- Round to lot step
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    positionSize = MathFloor(positionSize / lotStep) * lotStep;
    
    //--- Ensure within limits
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    
    positionSize = MathMax(minLot, MathMin(maxLot, positionSize));
    
    LogMessage("Calculated position size: " + (string)positionSize + " lots");
    
    return positionSize;
}

//+------------------------------------------------------------------+
//| Log message to file and console                                  |
//+------------------------------------------------------------------+
void LogMessage(string message, bool isWarning = false)
{
    string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
    string logEntry = timestamp + " - " + (isWarning ? "[WARNING] " : "[INFO] ") + message;
    
    //--- Print to console
    Print(logEntry);
    
    //--- Write to file if enabled
    if(LogAllOperations)
    {
        int handle = FileOpen(logFile, FILE_WRITE|FILE_READ|FILE_TXT|FILE_ANSI, '\n');
        if(handle != INVALID_HANDLE)
        {
            FileSeek(handle, 0, SEEK_END);
            FileWriteString(handle, logEntry + "\n");
            FileClose(handle);
        }
    }
}

//+------------------------------------------------------------------+
//| Secure web request function                                      |
//+------------------------------------------------------------------+
bool SecureWebRequest(string url, string &result)
{
    //--- Security check for web requests
    if(!AllowWebRequests)
    {
        LogMessage("Web requests disabled by security policy", true);
        return false;
    }
    
    //--- Verify trusted host
    string trustedList[];
    StringSplit(TrustedHosts, ',', trustedList);
    
    bool isTrusted = false;
    for(int i = 0; i < ArraySize(trustedList); i++)
    {
        if(StringFind(url, trustedList[i]) >= 0)
        {
            isTrusted = true;
            break;
        }
    }
    
    if(!isTrusted)
    {
        LogMessage("Web request to untrusted host blocked: " + url, true);
        return false;
    }
    
    //--- Perform web request
    char data[];
    char resultData[];
    string headers = "";
    
    int timeout = 5000; // 5 seconds timeout
    int res = WebRequest("GET", url, headers, timeout, data, resultData, headers);
    
    if(res == 200)
    {
        result = CharArrayToString(resultData);
        LogMessage("Web request successful: " + url);
        return true;
    }
    else
    {
        LogMessage("Web request failed with code: " + (string)res, true);
        return false;
    }
}
