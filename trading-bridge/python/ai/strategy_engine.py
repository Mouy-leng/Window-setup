"""
AI Strategy Engine
Main AI coordinator for trading system
"""
import logging
from typing import Dict, List, Optional
from datetime import datetime
from pathlib import Path

logger = logging.getLogger(__name__)


class AIStrategyEngine:
    """
    Complete AI trading strategy engine
    Coordinates all AI components for autonomous trading
    """
    
    def __init__(self, config: Optional[Dict] = None):
        """
        Initialize AI Strategy Engine
        
        Args:
            config: Configuration dictionary
        """
        self.config = config or {}
        self.models = {}
        self.market_data = {}
        self.performance_history = []
        self.is_initialized = False
        
        # Initialize components
        self._initialize_components()
    
    def _initialize_components(self):
        """Initialize AI components"""
        try:
            # Lazy import to avoid errors if dependencies not installed
            from .analyzers.market_analyzer import AIMarketAnalyzer
            from .models.price_predictor import PricePredictor
            from .models.signal_classifier import SignalClassifier
            from .risk_manager import AIRiskManager
            
            self.market_analyzer = AIMarketAnalyzer()
            self.price_predictor = PricePredictor()
            self.signal_classifier = SignalClassifier()
            self.risk_manager = AIRiskManager()
            
            self.is_initialized = True
            logger.info("AI Strategy Engine initialized successfully")
            
        except ImportError as e:
            logger.warning(f"AI components not fully available: {e}")
            logger.warning("Running in limited mode - install AI dependencies")
            self.is_initialized = False
    
    def analyze_market(self, symbol: str, timeframe: str = "H1") -> Dict:
        """
        AI-powered comprehensive market analysis
        
        Args:
            symbol: Trading symbol (e.g., 'EURUSD')
            timeframe: Timeframe for analysis (e.g., 'H1', 'H4', 'D1')
            
        Returns:
            Dictionary with market analysis results:
            - sentiment: Market sentiment (bullish/bearish/neutral)
            - trend: Trend direction and strength
            - volatility: Volatility level
            - signals: Trading signals
            - confidence: Confidence score (0-1)
        """
        if not self.is_initialized:
            return {
                'error': 'AI components not initialized',
                'sentiment': 'neutral',
                'trend': 'unknown',
                'volatility': 0.0,
                'signals': [],
                'confidence': 0.0
            }
        
        try:
            # Use market analyzer
            analysis = self.market_analyzer.analyze(symbol, timeframe)
            
            # Get price prediction
            prediction = self.price_predictor.predict(symbol, timeframe)
            
            # Classify signals
            signals = self.signal_classifier.classify(analysis, prediction)
            
            # Combine results
            result = {
                'symbol': symbol,
                'timeframe': timeframe,
                'timestamp': datetime.now().isoformat(),
                'sentiment': analysis.get('sentiment', 'neutral'),
                'trend': analysis.get('trend', {}),
                'volatility': analysis.get('volatility', 0.0),
                'prediction': prediction,
                'signals': signals,
                'confidence': self._calculate_confidence(analysis, prediction, signals)
            }
            
            logger.debug(f"Market analysis completed for {symbol}")
            return result
            
        except Exception as e:
            logger.error(f"Error in market analysis: {e}")
            return {
                'error': str(e),
                'sentiment': 'neutral',
                'trend': 'unknown',
                'volatility': 0.0,
                'signals': [],
                'confidence': 0.0
            }
    
    def generate_signal(self, symbol: str, timeframe: str = "H1") -> Optional[Dict]:
        """
        Generate AI trading signal
        
        Args:
            symbol: Trading symbol
            timeframe: Analysis timeframe
            
        Returns:
            Trading signal dictionary:
            - action: BUY/SELL/HOLD
            - symbol: Trading symbol
            - confidence: Confidence score (0-1)
            - lot_size: Recommended position size
            - stop_loss: Recommended stop loss
            - take_profit: Recommended take profit
            - reasoning: Signal reasoning
        """
        if not self.is_initialized:
            logger.warning("AI components not initialized - cannot generate signal")
            return None
        
        try:
            # Analyze market
            analysis = self.analyze_market(symbol, timeframe)
            
            if 'error' in analysis:
                return None
            
            # Extract best signal
            signals = analysis.get('signals', [])
            if not signals:
                return {
                    'action': 'HOLD',
                    'symbol': symbol,
                    'confidence': 0.0,
                    'reasoning': 'No clear signal from AI analysis'
                }
            
            # Get best signal (highest confidence)
            best_signal = max(signals, key=lambda x: x.get('confidence', 0.0))
            
            # Assess risk
            risk_assessment = self.risk_manager.assess_risk(
                symbol=symbol,
                action=best_signal.get('action'),
                confidence=best_signal.get('confidence', 0.0)
            )
            
            # Build signal
            signal = {
                'action': best_signal.get('action', 'HOLD'),
                'symbol': symbol,
                'confidence': best_signal.get('confidence', 0.0),
                'lot_size': risk_assessment.get('recommended_lot_size', 0.01),
                'stop_loss': risk_assessment.get('stop_loss', None),
                'take_profit': risk_assessment.get('take_profit', None),
                'reasoning': best_signal.get('reasoning', 'AI-generated signal'),
                'timestamp': datetime.now().isoformat()
            }
            
            logger.info(f"Generated signal: {signal['action']} {symbol} (confidence: {signal['confidence']:.2f})")
            return signal
            
        except Exception as e:
            logger.error(f"Error generating signal: {e}")
            return None
    
    def assess_risk(self, signal: Dict) -> Dict:
        """
        AI risk assessment for trading signal
        
        Args:
            signal: Trading signal dictionary
            
        Returns:
            Risk assessment dictionary:
            - risk_score: Risk score (0-1)
            - recommended_lot_size: Recommended position size
            - max_risk: Maximum risk percentage
            - stop_loss: Recommended stop loss
            - take_profit: Recommended take profit
        """
        if not self.is_initialized:
            return {
                'risk_score': 0.5,
                'recommended_lot_size': 0.01,
                'max_risk': 1.0,
                'stop_loss': None,
                'take_profit': None
            }
        
        try:
            return self.risk_manager.assess_risk(
                symbol=signal.get('symbol'),
                action=signal.get('action'),
                confidence=signal.get('confidence', 0.5)
            )
        except Exception as e:
            logger.error(f"Error in risk assessment: {e}")
            return {
                'risk_score': 0.5,
                'recommended_lot_size': 0.01,
                'max_risk': 1.0
            }
    
    def update_models(self, performance_data: Dict):
        """
        Update AI models based on performance data
        Continuous learning from trading results
        
        Args:
            performance_data: Performance metrics and results
        """
        if not self.is_initialized:
            return
        
        try:
            # Store performance data
            self.performance_history.append({
                'timestamp': datetime.now().isoformat(),
                'data': performance_data
            })
            
            # Keep only recent history (last 1000 entries)
            if len(self.performance_history) > 1000:
                self.performance_history = self.performance_history[-1000:]
            
            # Update models (implement retraining logic)
            logger.info("Performance data recorded for model updates")
            
        except Exception as e:
            logger.error(f"Error updating models: {e}")
    
    def _calculate_confidence(self, analysis: Dict, prediction: Dict, signals: List) -> float:
        """
        Calculate overall confidence score
        
        Args:
            analysis: Market analysis results
            prediction: Price prediction results
            signals: Trading signals
            
        Returns:
            Confidence score (0-1)
        """
        try:
            # Combine confidence from different sources
            analysis_conf = analysis.get('confidence', 0.5)
            prediction_conf = prediction.get('confidence', 0.5)
            
            if signals:
                signal_conf = max([s.get('confidence', 0.0) for s in signals])
            else:
                signal_conf = 0.0
            
            # Weighted average
            confidence = (analysis_conf * 0.3 + prediction_conf * 0.4 + signal_conf * 0.3)
            return min(max(confidence, 0.0), 1.0)
            
        except Exception:
            return 0.5
    
    def get_status(self) -> Dict:
        """Get AI engine status"""
        return {
            'initialized': self.is_initialized,
            'components': {
                'market_analyzer': hasattr(self, 'market_analyzer'),
                'price_predictor': hasattr(self, 'price_predictor'),
                'signal_classifier': hasattr(self, 'signal_classifier'),
                'risk_manager': hasattr(self, 'risk_manager')
            },
            'performance_history_size': len(self.performance_history)
        }



























