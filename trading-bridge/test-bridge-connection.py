#!/usr/bin/env python
"""
Test Bridge Connection
Tests if Python bridge can listen and MQL5 EA can connect
"""
import sys
import time
import json
from pathlib import Path
from datetime import datetime

# Add python directory to path
script_dir = Path(__file__).parent.absolute()
python_dir = script_dir / "python"
sys.path.insert(0, str(python_dir))
sys.path.insert(0, str(script_dir))

print("=" * 60)
print("Bridge Connection Test")
print("=" * 60)
print()

try:
    from bridge.mql5_bridge import MQL5Bridge
    from bridge.signal_manager import TradeSignal
    import threading
    
    print("[1/4] Creating bridge instance...")
    bridge = MQL5Bridge(port=5555, host="127.0.0.1")
    print("    ✓ Bridge created")
    print(f"    - Port: {bridge.port}")
    print(f"    - Host: {bridge.host}")
    print()
    
    print("[2/4] Starting bridge in background thread...")
    bridge_thread = threading.Thread(target=bridge.start, daemon=True)
    bridge_thread.start()
    print("    ✓ Bridge thread started")
    time.sleep(2)  # Wait for bridge to initialize
    print()
    
    print("[3/4] Testing signal creation and queuing...")
    test_signal = TradeSignal(
        symbol="EURUSD",
        action="BUY",
        broker="EXNESS",
        lot_size=0.01,
        stop_loss=1.0850,
        take_profit=1.0900,
        comment="Test signal from connection test"
    )
    
    success, error = bridge.send_signal(test_signal)
    if success:
        print("    ✓ Test signal created and queued")
        print(f"    - Symbol: {test_signal.symbol}")
        print(f"    - Action: {test_signal.action}")
        print(f"    - Queue size: {bridge.signal_manager.get_queue_size()}")
    else:
        print(f"    ✗ Failed to queue signal: {error}")
    print()
    
    print("[4/4] Checking bridge status...")
    status = bridge.get_status()
    print(f"    - Connection status: {status['connection_status']}")
    print(f"    - Queue size: {status['queue_size']}")
    print(f"    - Signals sent: {status['stats']['signals_sent']}")
    print()
    
    print("=" * 60)
    print("Test Results")
    print("=" * 60)
    print()
    
    if status['connection_status'] == 'listening':
        print("✅ Bridge is LISTENING on port 5555")
        print("✅ Ready to receive connections from MQL5 EA")
        print()
        print("Next steps:")
        print("  1. Compile PythonBridgeEA.mq5 in MetaEditor")
        print("  2. Attach EA to chart in MT5")
        print("  3. EA should connect automatically")
        print("  4. Check MT5 Experts tab for connection messages")
    else:
        print(f"⚠️  Bridge status: {status['connection_status']}")
        print("   Check logs for details")
    
    print()
    print("Bridge will continue running in background...")
    print("Press Ctrl+C to stop")
    print()
    
    # Keep running to maintain bridge
    try:
        while True:
            time.sleep(5)
            status = bridge.get_status()
            if status['connection_status'] == 'connected':
                print(f"[{datetime.now().strftime('%H:%M:%S')}] MQL5 EA connected! Queue: {status['queue_size']}")
            elif status['connection_status'] == 'listening':
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Waiting for MQL5 EA connection... Queue: {status['queue_size']}")
    except KeyboardInterrupt:
        print("\nStopping bridge...")
        bridge.stop()
        print("Bridge stopped")
        
except ImportError as e:
    print(f"✗ Import error: {e}")
    print("   Make sure all dependencies are installed:")
    print("   pip install -r requirements.txt")
except Exception as e:
    print(f"✗ Error: {e}")
    import traceback
    traceback.print_exc()

