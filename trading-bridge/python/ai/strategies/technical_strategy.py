"""
Technical Analysis Strategy
AI-enhanced technical analysis trading strategy
"""
from typing import Dict, Optional
import logging
from .base_strategy import BaseStrategy

logger = logging.getLogger(__name__)


class TechnicalStrategy(BaseStrategy):
    """
    AI-enhanced technical analysis strategy
    Uses multiple indicators with AI confirmation
    """
    
    def __init__(self, config: Optional[Dict] = None):
        """
        Initialize technical strategy
        
        Args:
            config: Strategy configuration
        """
        super().__init__("Technical Analysis Strategy", config)
        self.indicators = config.get('indicators', ['RSI', 'MACD', 'MA'])
    
    def generate_signal(self, symbol: str, market_data: Dict) -> Optional[Dict]:
        """
        Generate trading signal using technical analysis
        
        Args:
            symbol: Trading symbol
            market_data: Market data and analysis
            
        Returns:
            Trading signal dictionary
        """
        try:
            indicators = market_data.get('indicators', {})
            sentiment = market_data.get('sentiment', 'neutral')
            trend = market_data.get('trend', {})
            
            # Analyze indicators
            signal_strength = 0.0
            signal_action = 'HOLD'
            reasoning_parts = []
            
            # RSI analysis
            if 'RSI' in indicators:
                rsi = indicators['RSI']
                if rsi < 30:
                    signal_strength += 0.3
                    signal_action = 'BUY'
                    reasoning_parts.append('RSI oversold')
                elif rsi > 70:
                    signal_strength += 0.3
                    signal_action = 'SELL'
                    reasoning_parts.append('RSI overbought')
            
            # MACD analysis
            if 'MACD' in indicators:
                macd = indicators['MACD']
                if macd.get('signal', '') == 'bullish':
                    signal_strength += 0.2
                    if signal_action == 'HOLD':
                        signal_action = 'BUY'
                    reasoning_parts.append('MACD bullish')
                elif macd.get('signal', '') == 'bearish':
                    signal_strength += 0.2
                    if signal_action == 'HOLD':
                        signal_action = 'SELL'
                    reasoning_parts.append('MACD bearish')
            
            # Trend analysis
            trend_direction = trend.get('direction', 'unknown')
            trend_strength = trend.get('strength', 0.0)
            
            if trend_direction == 'up' and signal_action == 'BUY':
                signal_strength += trend_strength * 0.3
                reasoning_parts.append('Uptrend confirmed')
            elif trend_direction == 'down' and signal_action == 'SELL':
                signal_strength += trend_strength * 0.3
                reasoning_parts.append('Downtrend confirmed')
            
            # Sentiment confirmation
            if sentiment == 'bullish' and signal_action == 'BUY':
                signal_strength += 0.2
            elif sentiment == 'bearish' and signal_action == 'SELL':
                signal_strength += 0.2
            
            # Generate signal if strength is sufficient
            if signal_strength >= 0.5:
                signal = {
                    'action': signal_action,
                    'symbol': symbol,
                    'confidence': min(signal_strength, 1.0),
                    'reasoning': '; '.join(reasoning_parts) if reasoning_parts else 'Technical analysis signal',
                    'strategy': self.name,
                    'indicators': indicators
                }
                
                if self.validate_signal(signal):
                    return signal
            
            return None
            
        except Exception as e:
            logger.error(f"Error generating technical signal: {e}")
            return None
    
    def get_required_indicators(self) -> list:
        """Get required indicators"""
        return self.indicators



























