#!/usr/bin/env python
"""
Trading Service Launcher
Fixes Python path and starts the background service
"""
import sys
import os
from pathlib import Path

# Get the trading-bridge directory
script_dir = Path(__file__).parent.absolute()
python_dir = script_dir / "python"

# Add python directory to path
sys.path.insert(0, str(python_dir))
sys.path.insert(0, str(script_dir))

# Change to python directory
os.chdir(str(python_dir))

# Now import and run the service
if __name__ == "__main__":
    from services.background_service import main
    main()