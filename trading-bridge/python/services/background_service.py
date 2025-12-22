"""
Background Trading Service
Main service that runs trading system in background
"""
import os
import sys
import time
import threading
import logging
from pathlib import Path
from datetime import datetime

# Add parent directories to path
# Get the trading-bridge/python directory
current_dir = Path(__file__).parent.parent
trading_bridge_dir = current_dir.parent
python_dir = current_dir

# Add python directory to path first (so imports work)
sys.path.insert(0, str(python_dir))
sys.path.insert(0, str(trading_bridge_dir))

# Change to python directory for imports
original_cwd = os.getcwd()
try:
    os.chdir(str(python_dir))
except OSError:
    pass

try:
    from bridge.mql5_bridge import MQL5Bridge
    from brokers.broker_factory import BrokerFactory
    from trader.multi_symbol_trader import MultiSymbolTrader
except ImportError as e:
    # Log error but don't crash - allow service to start with minimal
    # functionality
    logging.basicConfig(level=logging.ERROR)
    logger = logging.getLogger(__name__)
    logger.error(f"Import error: {e}")
    logger.error(f"Python path: {sys.path}")
    logger.error(f"Current directory: {os.getcwd()}")
    logger.error(f"Python dir: {python_dir}")
    # Set to None to allow graceful degradation
    MQL5Bridge = None
    BrokerFactory = None
    MultiSymbolTrader = None
finally:
    # Restore original working directory
    try:
        os.chdir(original_cwd)
    except OSError:
        pass

# Setup logging
log_dir = Path(__file__).parent.parent.parent.parent / "logs"
log_dir.mkdir(parents=True, exist_ok=True)
log_file = log_dir / f"trading_service_{datetime.now().strftime('%Y%m%d')}.log"

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file, encoding='utf-8'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)


class BackgroundTradingService:
    """Main background trading service"""

    def __init__(self, bridge_port: int = 5555, use_ai: bool = False):
        """
        Initialize background trading service

        Args:
            bridge_port: Port for MQL5 bridge
            use_ai: If True, use AI trading service instead of basic service
        """
        self.bridge_port = bridge_port
        self.use_ai = use_ai
        self.bridge = None
        self.brokers = {}
        self.trader = None
        self.ai_service = None
        self.running = False
        self.bridge_thread = None

        # Health check
        self.last_health_check = None
        self.health_check_interval = 60  # seconds

        # Check if modules are available
        self.modules_available = MQL5Bridge is not None

    def start(self):
        """Start the trading service"""
        try:
            if self.use_ai:
                logger.info("Starting AI Trading Service...")
                self._start_ai_service()
                return

            logger.info("Starting Background Trading Service...")

            if not self.modules_available:
                msg = ("Trading modules not fully available - "
                       "running in minimal mode")
                logger.warning(msg)
                logger.warning("Service will run but trading functionality "
                               "may be limited")
                self.running = True
                self._service_loop_minimal()
                return

            # Initialize bridge
            self.bridge = MQL5Bridge(port=self.bridge_port)

            # Start bridge in separate thread
            self.bridge_thread = threading.Thread(
                target=self._run_bridge, daemon=True)
            self.bridge_thread.start()

            # Wait for bridge to start
            time.sleep(2)

            # Initialize brokers
            logger.info("Loading brokers...")
            self.brokers = BrokerFactory.create_all_brokers()
            logger.info(f"Loaded {len(self.brokers)} broker(s)")

            # Initialize multi-symbol trader
            self.trader = MultiSymbolTrader(
                bridge=self.bridge, broker_manager=self.brokers)
            logger.info("Multi-symbol trader initialized")

            # Log active symbols for today
            active_symbols = self.trader.get_active_symbols_today()
            current_day = datetime.now().strftime('%A')
            logger.info(
                f"Today is {current_day} - "
                f"{len(active_symbols)} symbol(s) active:")
            for symbol_config in active_symbols:
                symbol = symbol_config['symbol']
                broker = symbol_config['broker']
                logger.info(f"  - {symbol} @ {broker}")

            # Start main loop
            self.running = True
            logger.info("Background Trading Service started")

            # Main service loop
            self._service_loop()

        except Exception as e:
            logger.error(f"Failed to start service: {e}")
            import traceback
            logger.error(traceback.format_exc())
            # Don't raise - allow service to continue in minimal mode
            self.running = True
            self._service_loop_minimal()

    def _run_bridge(self):
        """Run bridge in separate thread"""
        try:
            self.bridge.start()
        except Exception as e:
            logger.error(f"Bridge error: {e}")

    def _service_loop(self):
        """Main service loop"""
        while self.running:
            try:
                # Health check
                self._health_check()

                # Monitor positions
                if self.trader:
                    self.trader.monitor_positions()

                # Check bridge status
                if self.bridge:
                    status = self.bridge.get_status()
                    if status['connection_status'] == 'disconnected':
                        logger.warning(
                            "Bridge disconnected, attempting to reconnect...")
                        # Bridge will auto-reconnect on next request

                # Sleep before next iteration
                time.sleep(5)

            except KeyboardInterrupt:
                logger.info("Service interrupted by user")
                self.stop()
                break
            except Exception as e:
                logger.error(f"Service loop error: {e}")
                time.sleep(10)

    def _service_loop_minimal(self):
        """Minimal service loop when modules not available"""
        while self.running:
            try:
                logger.info(
                    "Service running in minimal mode - waiting for modules")
                time.sleep(60)  # Check every minute
            except KeyboardInterrupt:
                logger.info("Service interrupted by user")
                self.stop()
                break
            except Exception as e:
                logger.error(f"Service loop error: {e}")
                time.sleep(10)

    def _health_check(self):
        """Perform health check"""
        current_time = time.time()

        if (self.last_health_check is None or
                current_time - self.last_health_check >=
                self.health_check_interval):

            # Check bridge
            if self.bridge:
                status = self.bridge.get_status()
                conn_status = status['connection_status']
                logger.debug(f"Bridge status: {conn_status}")

            # Check brokers
            for broker_name, broker in self.brokers.items():
                try:
                    account_info = broker.get_account_info()
                    balance = account_info.balance
                    logger.debug(f"{broker_name} account balance: {balance}")
                except Exception as e:
                    logger.warning(f"{broker_name} health check failed: {e}")

            self.last_health_check = current_time

    def _start_ai_service(self):
        """Start AI trading service"""
        try:
            from services.ai_trading_service import AITradingService
            import json

            # Load AI config
            config_file = (
                Path(__file__).parent.parent.parent / "config" /
                "ai_config.json")
            config = {}
            if config_file.exists():
                with open(config_file, 'r') as f:
                    config = json.load(f)

            self.ai_service = AITradingService(
                bridge_port=self.bridge_port, config=config)
            self.ai_service.start()

        except ImportError as e:
            logger.error(f"AI service not available: {e}")
            logger.info("Falling back to basic service")
            self.use_ai = False
            self.start()
        except Exception as e:
            logger.error(f"Error starting AI service: {e}")
            logger.info("Falling back to basic service")
            self.use_ai = False
            self.start()

    def stop(self):
        """Stop the trading service"""
        if self.use_ai and self.ai_service:
            logger.info("Stopping AI Trading Service...")
            self.ai_service.stop()
            return

        logger.info("Stopping Background Trading Service...")
        self.running = False

        if self.bridge:
            self.bridge.stop()

        logger.info("Background Trading Service stopped")

    def get_status(self) -> dict:
        """Get service status"""
        if self.use_ai and self.ai_service:
            return self.ai_service.get_status()

        status = {
            'running': self.running,
            'bridge_status': None,
            'brokers': list(self.brokers.keys()),
            'symbols': [],
            'mode': 'ai' if self.use_ai else 'basic'
        }

        if self.bridge:
            status['bridge_status'] = self.bridge.get_status()

        if self.trader:
            symbols = [s['symbol'] for s in self.trader.get_all_symbols()]
            status['symbols'] = symbols

        return status


def main():
    """Main entry point"""
    service = BackgroundTradingService()
    try:
        service.start()
    except KeyboardInterrupt:
        logger.info("Service stopped by user")
        service.stop()
    except Exception as e:
        logger.error(f"Service error: {e}")
        service.stop()
        raise


if __name__ == "__main__":
    main()
