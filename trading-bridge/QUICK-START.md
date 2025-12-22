# Trading System - Quick Start Guide

## ✅ System Configured and Ready

Your trading system is now configured with:
- **7 weekday symbols** (Monday-Friday)
- **3 weekend symbols** (Saturday-Sunday)

## 🚀 Start the Trading System

### Quick Start (Recommended)
```powershell
cd C:\Users\USER\OneDrive\trading-bridge
python run-trading-service.py
```

### Or Use PowerShell Script
```powershell
cd C:\Users\USER\OneDrive\trading-bridge
.\start-trading-system.ps1
```

## 📊 Check Status

### Verify Service is Running
```powershell
Get-Process python -ErrorAction SilentlyContinue
```

### View Recent Logs
```powershell
cd C:\Users\USER\OneDrive\trading-bridge\logs
Get-Content trading_service_*.log -Tail 30
```

### Check Active Symbols
The service automatically logs which symbols are active:
- **Weekdays**: EURUSD, GBPUSD, USDJPY, AUDUSD, USDCAD, EURJPY, GBPJPY
- **Weekends**: BTCUSD, ETHUSD, XAUUSD

## 📁 Important Files

- `config/symbols.json` - Symbol configuration (7 weekday + 3 weekend)
- `config/brokers.json` - Broker API configuration
- `run-trading-service.py` - Main launcher (fixes Python paths)
- `start-trading-system.ps1` - PowerShell startup script
- `logs/` - Service logs directory

## ⚙️ Configuration

### Current Symbol Schedule

**Monday-Friday (7 symbols):**
1. EURUSD
2. GBPUSD
3. USDJPY
4. AUDUSD
5. USDCAD
6. EURJPY
7. GBPJPY

**Saturday-Sunday (3 symbols):**
1. BTCUSD
2. ETHUSD
3. XAUUSD

## 🔧 Troubleshooting

### Service Not Starting
1. Check Python is installed: `python --version`
2. Check dependencies: `pip list | findstr pyzmq`
3. View error logs in `logs/` directory

### Import Errors
- Use `run-trading-service.py` instead of direct Python call
- This script fixes Python path issues automatically

### No Active Symbols
- Check current day of week
- Verify `config/symbols.json` exists and is valid JSON
- Check service logs for configuration errors

## 📝 Next Steps

1. ✅ Configuration complete
2. ✅ Symbols configured
3. ✅ Service launcher created
4. ⏳ **Start the service** (use command above)
5. ⏳ Verify broker API connection
6. ⏳ Monitor trading activity

---

**Ready to trade!** Start the service using the commands above.

