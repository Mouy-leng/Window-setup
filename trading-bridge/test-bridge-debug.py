#!/usr/bin/env python3
"""
Debug script to test Python-MQL5 Bridge connection
Tests the bridge service and verifies it's working correctly
"""
import sys
import time
import json
from pathlib import Path

# Add parent directories to path
sys.path.insert(0, str(Path(__file__).parent / "python"))

try:
    from bridge.mql5_bridge import MQL5Bridge, start_bridge
    from bridge.signal_manager import TradeSignal, SignalManager
    print("✓ Successfully imported bridge modules")
except ImportError as e:
    print(f"✗ Import error: {e}")
    print("Please ensure all dependencies are installed:")
    print("  pip install pyzmq requests python-dotenv")
    sys.exit(1)

def test_bridge():
    """Test bridge functionality"""
    print("\n" + "="*50)
    print("Testing Python-MQL5 Bridge")
    print("="*50)
    
    # Test 1: Create bridge instance
    print("\n[Test 1] Creating bridge instance...")
    try:
        bridge = MQL5Bridge(port=5555)
        print("  ✓ Bridge instance created")
    except Exception as e:
        print(f"  ✗ Failed to create bridge: {e}")
        return False
    
    # Test 2: Create test signal
    print("\n[Test 2] Creating test trade signal...")
    try:
        signal = TradeSignal(
            symbol="EURUSD",
            action="BUY",
            broker="EXNESS",
            lot_size=0.01,
            stop_loss=1.08500,
            take_profit=1.09500,
            comment="Test signal from debug script"
        )
        is_valid, error = signal.validate()
        if is_valid:
            print(f"  ✓ Signal created and validated: {signal.action} {signal.symbol}")
        else:
            print(f"  ✗ Signal validation failed: {error}")
            return False
    except Exception as e:
        print(f"  ✗ Failed to create signal: {e}")
        return False
    
    # Test 3: Add signal to bridge
    print("\n[Test 3] Adding signal to bridge...")
    try:
        success, error = bridge.send_signal(signal)
        if success:
            print(f"  ✓ Signal added to bridge queue")
            print(f"    Queue size: {bridge.signal_manager.get_queue_size()}")
        else:
            print(f"  ✗ Failed to add signal: {error}")
            return False
    except Exception as e:
        print(f"  ✗ Error adding signal: {e}")
        return False
    
    # Test 4: Get bridge status
    print("\n[Test 4] Getting bridge status...")
    try:
        status = bridge.get_status()
        print(f"  ✓ Bridge status retrieved:")
        print(f"    Connection: {status['connection_status']}")
        print(f"    Queue size: {status['queue_size']}")
        print(f"    Signals sent: {status['stats']['signals_sent']}")
    except Exception as e:
        print(f"  ✗ Failed to get status: {e}")
        return False
    
    print("\n" + "="*50)
    print("All tests passed! Bridge is working correctly.")
    print("="*50)
    print("\nNote: To test the full bridge server, run:")
    print("  python -m python.bridge.mql5_bridge")
    print("\nOr start the background service:")
    print("  python python/services/background_service.py")
    
    return True

if __name__ == "__main__":
    success = test_bridge()
    sys.exit(0 if success else 1)

