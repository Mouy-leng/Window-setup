# Next Steps - Complete Setup Guide

## ✅ What's Done

1. ✅ Exness configuration structure verified
2. ✅ Signal listening system tested and working
3. ✅ PythonBridgeEA.mq5 copied to MT5
4. ✅ PythonBridge.mqh copied to MT5
5. ✅ Port configuration matches (5555)
6. ✅ Symbol schedule configured (7 weekday + 3 weekend)

## 🎯 What's Next (In Order)

### Step 1: Update Exness Credentials ⚠️ REQUIRED

**File**: `C:\Users\USER\OneDrive\trading-bridge\config\brokers.json`

Replace placeholders with real values:
```json
{
  "brokers": [
    {
      "name": "EXNESS",
      "api_url": "https://api.exness.com",
      "account_id": "YOUR_REAL_ACCOUNT_ID",
      "api_key": "YOUR_REAL_API_KEY",
      "api_secret": "YOUR_REAL_API_SECRET",
      "enabled": true
    }
  ]
}
```

**How to get Exness API credentials:**
1. Log into your Exness account
2. Go to API settings/management
3. Generate API key and secret
4. Copy account ID from account settings

### Step 2: Compile EA in MetaEditor ⚠️ REQUIRED

1. Open MetaEditor (F4 in MT5 or Tools → MetaQuotes Language Editor)
2. Open: `MQL5\Experts\PythonBridgeEA.mq5`
3. Press **F7** to compile
4. Verify: "0 error(s), 0 warning(s)" in compile log
5. Check: `PythonBridgeEA.ex5` file created

**See**: `COMPILE-EA.md` for detailed instructions

### Step 3: Start Python Bridge Service ⚠️ REQUIRED

**Option A: Using the launcher (Recommended)**
```powershell
cd C:\Users\USER\OneDrive\trading-bridge
python run-trading-service.py
```

**Option B: Test connection first**
```powershell
cd C:\Users\USER\OneDrive\trading-bridge
python test-bridge-connection.py
```

**Verify it's running:**
```powershell
Get-Process python -ErrorAction SilentlyContinue
```

### Step 4: Attach EA to Chart in MT5 ⚠️ REQUIRED

1. Open MT5 Terminal
2. Open a chart (e.g., EURUSD - one of your weekday symbols)
3. In Navigator panel, find **Expert Advisors**
4. Drag **PythonBridgeEA** to the chart
5. In the dialog, verify parameters:
   - **BridgePort**: 5555
   - **BrokerName**: EXNESS
   - **AutoExecute**: true
   - **DefaultLotSize**: 0.01
6. Click **OK**

### Step 5: Verify Connection ✅

**Check MT5 Experts Tab:**
- Should see: "Python Bridge EA initialized"
- Should see: "Bridge connection initialized on port 5555"
- No error messages

**Check Python Logs:**
```powershell
cd C:\Users\USER\OneDrive\trading-bridge\logs
Get-Content mql5_bridge_*.log -Tail 20
```

**Check Bridge Status:**
- Connection status should show "connected"
- Heartbeat should be updating

## 🧪 Testing the System

### Test 1: Bridge Connection
```powershell
# Start test script
cd C:\Users\USER\OneDrive\trading-bridge
python test-bridge-connection.py
```

### Test 2: Send Test Signal
After EA is connected, you can test by creating a signal in Python:
```python
from bridge.signal_manager import TradeSignal
from bridge.mql5_bridge import MQL5Bridge

bridge = MQL5Bridge(port=5555)
# ... (bridge should already be running)

signal = TradeSignal(
    symbol="EURUSD",
    action="BUY",
    broker="EXNESS",
    lot_size=0.01,
    stop_loss=1.0850,
    take_profit=1.0900
)
bridge.send_signal(signal)
```

### Test 3: Verify Trade Execution
- Check MT5 Terminal for new position
- Check Python logs for execution confirmation
- Verify Exness account (if using real account)

## 📋 Quick Checklist

- [ ] Update Exness credentials in brokers.json
- [ ] Compile PythonBridgeEA.mq5 in MetaEditor
- [ ] Start Python bridge service
- [ ] Attach EA to chart in MT5
- [ ] Verify connection in MT5 Experts tab
- [ ] Check Python bridge logs
- [ ] Test signal flow (optional)

## 🚨 Important Notes

1. **Port Must Match**: EA BridgePort (5555) = Python bridge port (5555) ✅
2. **Service First**: Start Python service BEFORE attaching EA
3. **Real Credentials**: Placeholder credentials won't work for trading
4. **Symbol Match**: EA should be on a chart with a configured symbol
5. **Weekday/Weekend**: Only appropriate symbols are active based on day

## 📊 Current Status

| Task | Status |
|------|--------|
| Files Copied | ✅ Done |
| Configuration | ✅ Done |
| Port Matching | ✅ Done |
| Exness Credentials | ⏳ Next |
| EA Compilation | ⏳ Next |
| Service Start | ⏳ Next |
| EA Attachment | ⏳ Next |
| Connection Test | ⏳ Next |

## 🎯 Ready to Proceed

You're ready for the next steps! Start with:
1. **Update Exness credentials** (if you have them)
2. **Compile the EA** in MetaEditor
3. **Start the Python service**
4. **Attach EA to chart**

---

**All setup files are ready. Follow the steps above to complete the setup!**

