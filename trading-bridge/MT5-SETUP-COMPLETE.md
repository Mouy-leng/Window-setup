# MT5 Expert Advisor Setup - Complete

## ✅ Files Copied to MT5 Directory

The PythonBridgeEA has been copied to your MT5 terminal directory:

**Expert Advisor:**
```
C:\Users\USER\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Experts\PythonBridgeEA.mq5
```

**Include File:**
```
C:\Users\USER\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Include\PythonBridge.mqh
```

## 🔧 Configuration Summary

### Python Bridge Settings
- **Port**: 5555 (matches Python bridge)
- **Host**: 127.0.0.1 (localhost)
- **Status**: ✅ Configured correctly

### Exness Settings
- **Broker Name**: EXNESS
- **API URL**: https://api.exness.com
- **Credentials**: ⚠️ Need to update with real API keys

### EA Parameters (Default)
- **BridgePort**: 5555 ✅
- **BrokerName**: "EXNESS" ✅
- **AutoExecute**: true ✅
- **DefaultLotSize**: 0.01 ✅

## 📋 Next Steps

### 1. Compile the EA in MetaEditor
1. Open MetaEditor
2. Navigate to: `MQL5\Experts\PythonBridgeEA.mq5`
3. Press **F7** to compile
4. Check for errors in the compile log

### 2. Update Exness Credentials
Edit `C:\Users\USER\OneDrive\trading-bridge\config\brokers.json`:
- Replace `YOUR_ACCOUNT_ID` with real account ID
- Replace `YOUR_API_KEY_HERE` with real API key
- Replace `YOUR_API_SECRET_HERE` with real API secret

### 3. Start Python Bridge Service
```powershell
cd C:\Users\USER\OneDrive\trading-bridge
python run-trading-service.py
```

### 4. Attach EA to Chart
1. Open MT5 Terminal
2. Open a chart (e.g., EURUSD)
3. Drag `PythonBridgeEA` from Navigator to chart
4. Verify parameters:
   - BridgePort: 5555
   - BrokerName: EXNESS
   - AutoExecute: true
5. Click OK

### 5. Verify Connection
Check the MT5 Experts tab for:
- "Python Bridge EA initialized"
- "Bridge connection initialized on port 5555"
- No connection errors

## 🔍 Verification Checklist

- [x] PythonBridgeEA.mq5 copied to MT5 Experts directory
- [x] PythonBridge.mqh copied to MT5 Include directory
- [x] EA configured for port 5555
- [x] EA configured for EXNESS broker
- [ ] EA compiled successfully in MetaEditor
- [ ] Exness credentials updated in brokers.json
- [ ] Python bridge service running
- [ ] EA attached to chart
- [ ] Bridge connection established

## 📊 Connection Flow

```
Python Trading Service (Port 5555)
    ↓ (listening for requests)
MQL5 Bridge (ZeroMQ)
    ↓ (MQL5 EA requests signals)
PythonBridgeEA.mq5
    ↓ (executes trades)
MT5 Terminal → Exness Broker
```

## 🐛 Troubleshooting

### EA Won't Compile
- Check that PythonBridge.mqh is in Include directory
- Verify all required MQL5 includes are available
- Check MetaEditor compile log for errors

### Bridge Connection Failed
- Verify Python service is running
- Check port 5555 is not blocked by firewall
- Ensure EA BridgePort parameter is 5555
- Check Python bridge logs: `trading-bridge\logs\mql5_bridge_*.log`

### No Signals Received
- Verify Python service is running
- Check signal queue in Python logs
- Verify EA is requesting signals (check MT5 Experts tab)
- Check bridge connection status

### Exness API Errors
- Verify API credentials are correct
- Check API key permissions
- Verify account ID matches
- Check Exness API documentation

## 📝 Important Notes

1. **Port Must Match**: EA BridgePort (5555) must match Python bridge port
2. **Service Must Run First**: Start Python service before attaching EA
3. **Real Credentials Required**: Placeholder credentials won't work for trading
4. **AutoExecute**: Set to false if you want manual trade confirmation

## ✅ Status

**Files**: ✅ Copied  
**Configuration**: ✅ Correct  
**Port**: ✅ 5555 (matches)  
**Broker**: ✅ EXNESS  
**Credentials**: ⚠️ Need real API keys  

---

**Setup Date**: December 23, 2025  
**Ready for**: Compilation and Testing

