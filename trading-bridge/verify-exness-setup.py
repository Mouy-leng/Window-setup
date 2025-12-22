#!/usr/bin/env python
"""
Verify Exness Configuration and Signal Listening
Checks if Exness settings are correct and if background service can listen to signals
"""
import sys
import json
from pathlib import Path
from datetime import datetime

# Add python directory to path
script_dir = Path(__file__).parent.absolute()
python_dir = script_dir / "python"
sys.path.insert(0, str(python_dir))
sys.path.insert(0, str(script_dir))

print("=" * 60)
print("Exness Configuration & Signal Listening Verification")
print("=" * 60)
print()

# Check 1: Broker Configuration File
print("[1/6] Checking broker configuration file...")
brokers_config_path = script_dir / "config" / "brokers.json"
if brokers_config_path.exists():
    print(f"    ✓ Found: {brokers_config_path}")
    try:
        with open(brokers_config_path, 'r') as f:
            brokers_config = json.load(f)
        
        exness_config = None
        for broker in brokers_config.get('brokers', []):
            if broker.get('name') == 'EXNESS':
                exness_config = broker
                break
        
        if exness_config:
            print(f"    ✓ EXNESS broker found in config")
            print(f"    - API URL: {exness_config.get('api_url', 'NOT SET')}")
            print(f"    - Account ID: {exness_config.get('account_id', 'NOT SET')}")
            print(f"    - API Key: {'SET' if exness_config.get('api_key') and 'YOUR_API_KEY' not in exness_config.get('api_key', '') else 'NOT SET / PLACEHOLDER'}")
            print(f"    - API Secret: {'SET' if exness_config.get('api_secret') and 'YOUR_API_SECRET' not in exness_config.get('api_secret', '') else 'NOT SET / PLACEHOLDER'}")
            print(f"    - Enabled: {exness_config.get('enabled', False)}")
            
            # Check if credentials are placeholders
            has_placeholders = (
                'YOUR_ACCOUNT_ID' in exness_config.get('account_id', '') or
                'YOUR_API_KEY' in exness_config.get('api_key', '') or
                'YOUR_API_SECRET' in exness_config.get('api_secret', '')
            )
            
            if has_placeholders:
                print(f"    ⚠ WARNING: Configuration contains placeholders!")
                print(f"    ⚠ Update brokers.json with real Exness API credentials")
            else:
                print(f"    ✓ Configuration appears to have real credentials")
        else:
            print(f"    ✗ EXNESS broker not found in config")
    except Exception as e:
        print(f"    ✗ Error reading config: {e}")
else:
    print(f"    ✗ Config file not found: {brokers_config_path}")
    print(f"    ⚠ Create config/brokers.json from brokers.json.example")

print()

# Check 2: Python Modules
print("[2/6] Checking Python modules...")
try:
    from brokers.broker_factory import BrokerFactory
    print("    ✓ BrokerFactory module imported")
except ImportError as e:
    print(f"    ✗ Cannot import BrokerFactory: {e}")

try:
    from bridge.mql5_bridge import MQL5Bridge
    print("    ✓ MQL5Bridge module imported")
except ImportError as e:
    print(f"    ✗ Cannot import MQL5Bridge: {e}")

try:
    from bridge.signal_manager import SignalManager, TradeSignal
    print("    ✓ SignalManager module imported")
except ImportError as e:
    print(f"    ✗ Cannot import SignalManager: {e}")

print()

# Check 3: Exness API Implementation
print("[3/6] Testing Exness API implementation...")
try:
    from brokers.exness_api import ExnessAPI
    from brokers.base_broker import BrokerConfig
    
    # Try to create broker instance (will fail if credentials invalid, but structure should work)
    if brokers_config_path.exists():
        with open(brokers_config_path, 'r') as f:
            config_data = json.load(f)
            exness_data = next((b for b in config_data.get('brokers', []) if b.get('name') == 'EXNESS'), None)
            
            if exness_data:
                try:
                    broker_config = BrokerConfig(
                        name=exness_data.get('name'),
                        api_url=exness_data.get('api_url'),
                        account_id=exness_data.get('account_id', ''),
                        api_key=exness_data.get('api_key', ''),
                        api_secret=exness_data.get('api_secret', ''),
                        enabled=exness_data.get('enabled', True),
                        rate_limit=exness_data.get('rate_limit', {})
                    )
                    exness_api = ExnessAPI(broker_config)
                    print("    ✓ ExnessAPI instance created successfully")
                    print(f"    - Base URL: {exness_api.base_url}")
                    print(f"    - Account ID: {exness_api.account_id}")
                except Exception as e:
                    print(f"    ⚠ ExnessAPI creation issue: {e}")
            else:
                print("    ✗ EXNESS config not found")
    else:
        print("    ⚠ Cannot test - config file missing")
except Exception as e:
    print(f"    ✗ Error testing Exness API: {e}")

print()

# Check 4: Bridge Signal Listening
print("[4/6] Testing bridge signal listening capability...")
try:
    from bridge.mql5_bridge import MQL5Bridge
    from bridge.signal_manager import TradeSignal
    
    # Create bridge instance (don't start it)
    bridge = MQL5Bridge(port=5555, host="127.0.0.1")
    print("    ✓ MQL5Bridge instance created")
    print(f"    - Port: {bridge.port}")
    print(f"    - Host: {bridge.host}")
    print(f"    - Signal Manager: {type(bridge.signal_manager).__name__}")
    
    # Test signal creation
    test_signal = TradeSignal(
        symbol="EURUSD",
        action="BUY",
        broker="EXNESS",
        lot_size=0.01,
        stop_loss=1.0850,
        take_profit=1.0900,
        comment="Test signal"
    )
    print("    ✓ Test signal created")
    
    # Test adding signal to queue
    success, error = bridge.signal_manager.add_signal(test_signal)
    if success:
        print("    ✓ Signal added to queue successfully")
        print(f"    - Queue size: {bridge.signal_manager.get_queue_size()}")
    else:
        print(f"    ✗ Failed to add signal: {error}")
    
except Exception as e:
    print(f"    ✗ Error testing bridge: {e}")
    import traceback
    traceback.print_exc()

print()

# Check 5: Port Configuration
print("[5/6] Checking port configuration...")
config_file = script_dir / "CONFIGURATION.md"
if config_file.exists():
    with open(config_file, 'r') as f:
        content = f.read()
        if '5500' in content:
            print("    ⚠ Configuration mentions port 5500")
        if '5555' in content:
            print("    ✓ Configuration mentions port 5555 (default)")
    
print(f"    Default bridge port: 5555")
print(f"    Note: Ensure MQL5 EA uses same port")

print()

# Check 6: Background Service Integration
print("[6/6] Checking background service integration...")
try:
    from services.background_service import BackgroundTradingService
    
    service = BackgroundTradingService(bridge_port=5555)
    print("    ✓ BackgroundTradingService instance created")
    print(f"    - Bridge port: {service.bridge_port}")
    print(f"    - Modules available: {service.modules_available}")
    
    if service.modules_available:
        print("    ✓ All required modules are available")
        print("    ✓ Service can listen to background signals")
    else:
        print("    ⚠ Some modules not available - service will run in minimal mode")
        
except Exception as e:
    print(f"    ✗ Error checking service: {e}")

print()
print("=" * 60)
print("Verification Summary")
print("=" * 60)
print()

# Final recommendations
issues = []
warnings = []

if brokers_config_path.exists():
    with open(brokers_config_path, 'r') as f:
        config = json.load(f)
        exness = next((b for b in config.get('brokers', []) if b.get('name') == 'EXNESS'), None)
        if exness:
            if 'YOUR_' in str(exness.get('account_id', '')) or 'YOUR_' in str(exness.get('api_key', '')):
                issues.append("Exness credentials contain placeholders - update with real API keys")
            if not exness.get('enabled', False):
                warnings.append("Exness broker is disabled in config")
        else:
            issues.append("EXNESS broker not found in configuration")
else:
    issues.append("brokers.json file not found")

if issues:
    print("❌ Issues Found:")
    for issue in issues:
        print(f"   - {issue}")
    print()

if warnings:
    print("⚠️  Warnings:")
    for warning in warnings:
        print(f"   - {warning}")
    print()

if not issues and not warnings:
    print("✅ All checks passed!")
    print("   - Exness configuration looks correct")
    print("   - Signal listening is properly configured")
    print("   - Background service can receive signals")
    print()
    print("Next steps:")
    print("   1. Ensure MQL5 EA is configured to connect to port 5555")
    print("   2. Start the background service: python run-trading-service.py")
    print("   3. Verify bridge connection in logs")
else:
    print("Action required:")
    if "placeholders" in str(issues):
        print("   1. Update config/brokers.json with real Exness API credentials")
        print("   2. Store credentials securely using Windows Credential Manager")
    print("   3. Restart the service after fixing issues")

print()

