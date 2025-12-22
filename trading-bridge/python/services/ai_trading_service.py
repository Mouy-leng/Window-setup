"""
AI Trading Service
Complete AI trading system that integrates all AI components
"""
import time
import threading
import logging
from pathlib import Path
from datetime import datetime
from typing import Dict, Optional, List

# Add parent directories to path
import sys
import os
current_dir = Path(__file__).parent.parent  # python directory
trading_bridge_dir = current_dir.parent      # trading-bridge directory
# Add python directory to path (where all modules are)
if str(current_dir) not in sys.path:
    sys.path.insert(0, str(current_dir))
# Add trading-bridge directory to path
if str(trading_bridge_dir) not in sys.path:
    sys.path.insert(0, str(trading_bridge_dir))
# Also add current working directory
if os.getcwd() not in sys.path:
    sys.path.insert(0, os.getcwd())

# Setup logging
log_dir = Path(__file__).parent.parent.parent.parent / "logs"
log_dir.mkdir(parents=True, exist_ok=True)
log_file = log_dir / f"ai_trading_service_{datetime.now().strftime('%Y%m%d')}.log"

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file, encoding='utf-8'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

# Import existing components
try:
    from bridge.mql5_bridge import MQL5Bridge
    from brokers.broker_factory import BrokerFactory
    from trader.multi_symbol_trader import MultiSymbolTrader
    from bridge.signal_manager import TradeSignal, TradeAction
except ImportError as e:
    logger.error(f"Import error: {e}")
    MQL5Bridge = None
    BrokerFactory = None
    MultiSymbolTrader = None

# Import AI components
try:
    from ai.strategy_engine import AIStrategyEngine
    from ai.strategies.ml_strategy import MLStrategy
    from ai.strategies.technical_strategy import TechnicalStrategy
except ImportError as e:
    logger.warning(f"AI components import error: {e}")
    AIStrategyEngine = None
    MLStrategy = None
    TechnicalStrategy = None


class AITradingService:
    """
    Complete AI trading service
    Integrates all AI components for autonomous trading
    """
    
    def __init__(self, bridge_port: int = 5555, config: Optional[Dict] = None):
        """
        Initialize AI Trading Service
        
        Args:
            bridge_port: Port for MQL5 bridge
            config: Configuration dictionary
        """
        self.bridge_port = bridge_port
        self.config = config or {}
        self.bridge = None
        self.brokers = {}
        self.trader = None
        self.ai_engine = None
        self.strategies = []
        self.running = False
        self.bridge_thread = None
        
        # Trading symbols to monitor
        self.symbols = self.config.get('symbols', [])
        
        # Analysis interval (seconds)
        self.analysis_interval = self.config.get('analysis_interval', 300)  # 5 minutes default
        
        # Health check
        self.last_health_check = None
        self.health_check_interval = 60  # seconds
    
    def start(self):
        """Start the AI trading service"""
        try:
            logger.info("Starting AI Trading Service...")
            
            # Initialize AI engine
            if AIStrategyEngine:
                self.ai_engine = AIStrategyEngine(config=self.config.get('ai', {}))
                logger.info("AI Strategy Engine initialized")
            else:
                logger.error("AI Strategy Engine not available - cannot start AI service")
                return
            
            # Initialize strategies
            self._initialize_strategies()
            
            # Initialize bridge
            if MQL5Bridge:
                self.bridge = MQL5Bridge(port=self.bridge_port)
                self.bridge_thread = threading.Thread(target=self._run_bridge, daemon=True)
                self.bridge_thread.start()
                time.sleep(2)  # Wait for bridge to start
                logger.info("MQL5 Bridge started")
            else:
                logger.warning("MQL5 Bridge not available - running in analysis-only mode")
            
            # Initialize brokers
            if BrokerFactory:
                self.brokers = BrokerFactory.create_all_brokers()
                logger.info(f"Loaded {len(self.brokers)} broker(s)")
            else:
                logger.warning("Broker factory not available")
            
            # Initialize trader
            if MultiSymbolTrader:
                self.trader = MultiSymbolTrader(bridge=self.bridge, broker_manager=self.brokers)
                logger.info("Multi-symbol trader initialized")
            else:
                logger.warning("Multi-symbol trader not available")
            
            # Load symbols from config
            self._load_symbols()
            
            # Start main loop
            self.running = True
            logger.info("AI Trading Service started")
            logger.info(f"Monitoring {len(self.symbols)} symbol(s)")
            
            # Main service loop
            self._service_loop()
            
        except Exception as e:
            logger.error(f"Failed to start AI service: {e}")
            import traceback
            logger.error(traceback.format_exc())
            self.running = False
    
    def _initialize_strategies(self):
        """Initialize trading strategies"""
        try:
            # ML Strategy
            if MLStrategy:
                ml_strategy = MLStrategy(config=self.config.get('ml_strategy', {}))
                self.strategies.append(ml_strategy)
                logger.info("ML Strategy initialized")
            
            # Technical Strategy
            if TechnicalStrategy:
                tech_strategy = TechnicalStrategy(config=self.config.get('technical_strategy', {}))
                self.strategies.append(tech_strategy)
                logger.info("Technical Strategy initialized")
            
            logger.info(f"Initialized {len(self.strategies)} strategy(ies)")
            
        except Exception as e:
            logger.error(f"Error initializing strategies: {e}")
    
    def _load_symbols(self):
        """Load trading symbols from configuration"""
        try:
            # Load from config file if available
            config_file = Path(__file__).parent.parent.parent / "config" / "symbols.json"
            if config_file.exists():
                import json
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    symbols = config.get('symbols', [])
                    for symbol_config in symbols:
                        symbol = symbol_config.get('symbol', '')
                        if symbol:
                            self.symbols.append(symbol)
                            logger.info(f"Loaded symbol: {symbol}")
            
            # If no symbols loaded, use default
            if not self.symbols:
                self.symbols = ['EURUSD', 'GBPUSD', 'USDJPY']  # Default symbols
                logger.info(f"Using default symbols: {self.symbols}")
            
        except Exception as e:
            logger.error(f"Error loading symbols: {e}")
            self.symbols = ['EURUSD']  # Fallback
    
    def _run_bridge(self):
        """Run bridge in separate thread"""
        try:
            if self.bridge:
                self.bridge.start()
        except Exception as e:
            logger.error(f"Bridge error: {e}")
    
    def _service_loop(self):
        """Main service loop - autonomous trading"""
        logger.info("Starting autonomous trading loop...")
        
        while self.running:
            try:
                # Health check
                self._health_check()
                
                # Analyze markets and generate signals
                self._analyze_and_trade()
                
                # Monitor positions
                if self.trader:
                    self.trader.monitor_positions()
                
                # Sleep before next iteration
                time.sleep(self.analysis_interval)
                
            except KeyboardInterrupt:
                logger.info("Service interrupted by user")
                self.stop()
                break
            except Exception as e:
                logger.error(f"Service loop error: {e}")
                import traceback
                logger.error(traceback.format_exc())
                time.sleep(10)  # Wait before retrying
    
    def _analyze_and_trade(self):
        """Analyze markets and execute trades"""
        if not self.ai_engine:
            return
        
        for symbol in self.symbols:
            try:
                # Analyze market
                logger.debug(f"Analyzing {symbol}...")
                market_analysis = self.ai_engine.analyze_market(symbol, timeframe="H1")
                
                if 'error' in market_analysis:
                    logger.warning(f"Market analysis error for {symbol}: {market_analysis['error']}")
                    continue
                
                # Generate signal using strategies
                best_signal = None
                best_confidence = 0.0
                
                for strategy in self.strategies:
                    try:
                        signal = strategy.generate_signal(symbol, market_analysis)
                        if signal and signal.get('confidence', 0.0) > best_confidence:
                            best_signal = signal
                            best_confidence = signal.get('confidence', 0.0)
                    except Exception as e:
                        logger.error(f"Error in strategy {strategy.name}: {e}")
                
                # If we have a good signal, assess risk and execute
                if best_signal and best_confidence >= self.config.get('min_confidence', 0.6):
                    self._process_signal(symbol, best_signal, market_analysis)
                
            except Exception as e:
                logger.error(f"Error analyzing {symbol}: {e}")
    
    def _process_signal(self, symbol: str, signal: Dict, market_analysis: Dict):
        """Process trading signal"""
        try:
            action = signal.get('action', 'HOLD')
            confidence = signal.get('confidence', 0.0)
            
            if action == 'HOLD':
                return
            
            # Assess risk
            risk_assessment = self.ai_engine.assess_risk(signal)
            
            if not risk_assessment.get('approved', False):
                logger.info(f"Signal for {symbol} not approved by risk manager")
                return
            
            # Get recommended position size
            lot_size = risk_assessment.get('recommended_lot_size', 0.01)
            stop_loss = risk_assessment.get('stop_loss')
            take_profit = risk_assessment.get('take_profit')
            
            # Create trade signal
            trade_signal = TradeSignal(
                symbol=symbol,
                action=action,
                broker=self.config.get('default_broker', 'EXNESS'),
                lot_size=lot_size,
                stop_loss=stop_loss,
                take_profit=take_profit,
                comment=f"AI Signal: {signal.get('reasoning', '')} (confidence: {confidence:.2f})"
            )
            
            # Send signal to bridge or execute directly
            if self.bridge:
                success, error = self.bridge.send_signal(trade_signal)
                if success:
                    logger.info(f"Signal sent: {action} {symbol} @ {lot_size} lots")
                else:
                    logger.warning(f"Failed to send signal: {error}")
            elif self.trader:
                # Execute directly via trader
                broker = self.config.get('default_broker', 'EXNESS')
                result = self.trader.execute_trade(
                    symbol=symbol,
                    broker=broker,
                    action=action,
                    lot_size=lot_size,
                    stop_loss=stop_loss,
                    take_profit=take_profit,
                    comment=trade_signal.comment
                )
                if result.success:
                    logger.info(f"Trade executed: {action} {symbol} @ {lot_size} lots")
                else:
                    logger.warning(f"Trade execution failed: {result.message}")
            
        except Exception as e:
            logger.error(f"Error processing signal: {e}")
    
    def _health_check(self):
        """Perform health check"""
        current_time = time.time()
        
        if (self.last_health_check is None or 
            current_time - self.last_health_check >= self.health_check_interval):
            
            # Check AI engine
            if self.ai_engine:
                status = self.ai_engine.get_status()
                logger.debug(f"AI Engine status: {status}")
            
            # Check bridge
            if self.bridge:
                status = self.bridge.get_status()
                logger.debug(f"Bridge status: {status.get('connection_status', 'unknown')}")
            
            # Check brokers
            for broker_name, broker in self.brokers.items():
                try:
                    account_info = broker.get_account_info()
                    logger.debug(f"{broker_name} account balance: {account_info.balance}")
                except Exception as e:
                    logger.warning(f"{broker_name} health check failed: {e}")
            
            self.last_health_check = current_time
    
    def stop(self):
        """Stop the AI trading service"""
        logger.info("Stopping AI Trading Service...")
        self.running = False
        
        if self.bridge:
            self.bridge.stop()
        
        logger.info("AI Trading Service stopped")
    
    def get_status(self) -> Dict:
        """Get service status"""
        status = {
            'running': self.running,
            'ai_engine_initialized': self.ai_engine is not None and self.ai_engine.is_initialized,
            'strategies': [s.name for s in self.strategies],
            'symbols': self.symbols,
            'bridge_status': None,
            'brokers': list(self.brokers.keys())
        }
        
        if self.bridge:
            status['bridge_status'] = self.bridge.get_status()
        
        if self.ai_engine:
            status['ai_engine_status'] = self.ai_engine.get_status()
        
        return status


def main():
    """Main entry point"""
    service = AITradingService()
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


























