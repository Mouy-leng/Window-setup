# Trading Schedule Configuration

## Overview

The trading system is configured to trade different symbols on weekdays vs weekends:

- **Weekdays (Monday-Friday)**: At least 5 symbols active
- **Weekends (Saturday-Sunday)**: 3 symbols active

## Current Configuration

### Weekday Symbols (Monday-Friday)

1. **EURUSD** - Euro/US Dollar
2. **GBPUSD** - British Pound/US Dollar
3. **USDJPY** - US Dollar/Japanese Yen
4. **AUDUSD** - Australian Dollar/US Dollar
5. **USDCAD** - US Dollar/Canadian Dollar
6. **EURJPY** - Euro/Japanese Yen
7. **GBPJPY** - British Pound/Japanese Yen

**Total: 7 symbols** (exceeds minimum of 5)

### Weekend Symbols (Saturday-Sunday)

1. **BTCUSD** - Bitcoin/US Dollar (Cryptocurrency)
2. **ETHUSD** - Ethereum/US Dollar (Cryptocurrency)
3. **XAUUSD** - Gold/US Dollar (Precious Metal)

**Total: 3 symbols** (meets requirement)

## How It Works

The system automatically filters symbols based on the current day of the week:

- On **Monday-Friday**: Only weekday symbols are active
- On **Saturday-Sunday**: Only weekend symbols are active

### Symbol Filtering Logic

The `MultiSymbolTrader` class includes methods to:

- `get_active_symbols_today()` - Returns symbols that can be traded today
- `get_weekday_symbols()` - Returns all weekday-configured symbols
- `get_weekend_symbols()` - Returns all weekend-configured symbols
- `_is_symbol_tradeable_today()` - Checks if a symbol can be traded today

### Configuration Format

Each symbol in `config/symbols.json` includes a `trading_days` field:

```json
{
  "symbol": "EURUSD",
  "broker": "EXNESS",
  "enabled": true,
  "trading_days": ["monday", "tuesday", "wednesday", "thursday", "friday"],
  "risk_percent": 1.0,
  "max_positions": 1,
  "min_lot_size": 0.01,
  "max_lot_size": 10.0
}
```

## Verification

When the trading service starts, it logs which symbols are active for the current day:

```text
Today is Monday - 7 symbol(s) active:
  - EURUSD @ EXNESS
  - GBPUSD @ EXNESS
  - USDJPY @ EXNESS
  - AUDUSD @ EXNESS
  - USDCAD @ EXNESS
  - EURJPY @ EXNESS
  - GBPJPY @ EXNESS
```

Or on weekends:

```text
Today is Saturday - 3 symbol(s) active:
  - BTCUSD @ EXNESS
  - ETHUSD @ EXNESS
  - XAUUSD @ EXNESS
```

## Adding More Symbols

To add more symbols:

1. Edit `config/symbols.json`
2. Add symbol configuration with appropriate `trading_days`
3. Restart the trading service

### Example: Add Weekday Symbol

```json
{
  "symbol": "NZDUSD",
  "broker": "EXNESS",
  "enabled": true,
  "trading_days": ["monday", "tuesday", "wednesday", "thursday", "friday"],
  "risk_percent": 1.0,
  "max_positions": 1,
  "min_lot_size": 0.01,
  "max_lot_size": 10.0
}
```

### Example: Add Weekend Symbol

```json
{
  "symbol": "XAGUSD",
  "broker": "EXNESS",
  "enabled": true,
  "trading_days": ["saturday", "sunday"],
  "risk_percent": 1.0,
  "max_positions": 1,
  "min_lot_size": 0.01,
  "max_lot_size": 10.0
}
```

## Notes

- Symbols are automatically enabled/disabled based on the day of the week
- The system checks the day at runtime, so no manual intervention is needed
- If a symbol doesn't have `trading_days` specified, it will be available all days
- The system uses Python's `datetime.weekday()` which returns 0=Monday, 6=Sunday

---

**Last Updated**: December 2025  
**Status**: ✅ Configured and Active
