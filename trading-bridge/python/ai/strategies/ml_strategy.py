"""
ML-Based Trading Strategy
Machine learning-based trading strategy
"""
from typing import Dict, Optional
import logging
from .base_strategy import BaseStrategy

logger = logging.getLogger(__name__)


class MLStrategy(BaseStrategy):
    """
    Machine learning-based trading strategy
    Uses price prediction and signal classification
    """
    
    def __init__(self, config: Optional[Dict] = None):
        """
        Initialize ML strategy
        
        Args:
            config: Strategy configuration
        """
        super().__init__("ML Strategy", config)
        self.price_predictor = None
        self.signal_classifier = None
        self._initialize_components()
    
    def _initialize_components(self):
        """Initialize ML components"""
        try:
            from ..models.price_predictor import PricePredictor
            from ..models.signal_classifier import SignalClassifier
            
            self.price_predictor = PricePredictor()
            self.signal_classifier = SignalClassifier()
            
        except ImportError as e:
            logger.warning(f"ML components not available: {e}")
    
    def generate_signal(self, symbol: str, market_data: Dict) -> Optional[Dict]:
        """
        Generate trading signal using ML
        
        Args:
            symbol: Trading symbol
            market_data: Market data and analysis
            
        Returns:
            Trading signal dictionary
        """
        if not self.price_predictor or not self.signal_classifier:
            return None
        
        try:
            # Get price prediction
            timeframe = market_data.get('timeframe', 'H1')
            prediction = self.price_predictor.predict(symbol, timeframe)
            
            if 'error' in prediction:
                return None
            
            # Classify signal
            signals = self.signal_classifier.classify(market_data, prediction)
            
            if not signals:
                return None
            
            # Get best signal
            best_signal = max(signals, key=lambda x: x.get('confidence', 0.0))
            
            # Build complete signal
            signal = {
                'action': best_signal.get('action', 'HOLD'),
                'symbol': symbol,
                'confidence': best_signal.get('confidence', 0.0),
                'reasoning': best_signal.get('reasoning', 'ML-based signal'),
                'strategy': self.name,
                'prediction': prediction,
                'market_analysis': market_data
            }
            
            if self.validate_signal(signal):
                return signal
            
            return None
            
        except Exception as e:
            logger.error(f"Error generating ML signal: {e}")
            return None
    
    def get_required_indicators(self) -> list:
        """Get required indicators"""
        return ['price', 'volume', 'prediction']



























