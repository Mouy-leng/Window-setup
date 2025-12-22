"""
Base Strategy Class
Abstract base class for all AI trading strategies
"""
from abc import ABC, abstractmethod
from typing import Dict, Optional
import logging

logger = logging.getLogger(__name__)


class BaseStrategy(ABC):
    """
    Abstract base class for all AI trading strategies
    """
    
    def __init__(self, name: str, config: Optional[Dict] = None):
        """
        Initialize strategy
        
        Args:
            name: Strategy name
            config: Strategy configuration
        """
        self.name = name
        self.config = config or {}
        self.is_active = True
    
    @abstractmethod
    def generate_signal(self, symbol: str, market_data: Dict) -> Optional[Dict]:
        """
        Generate trading signal
        
        Args:
            symbol: Trading symbol
            market_data: Market data and analysis
            
        Returns:
            Trading signal dictionary or None
        """
        pass
    
    @abstractmethod
    def get_required_indicators(self) -> list:
        """
        Get list of required indicators for this strategy
        
        Returns:
            List of indicator names
        """
        pass
    
    def validate_signal(self, signal: Dict) -> bool:
        """
        Validate trading signal
        
        Args:
            signal: Trading signal dictionary
            
        Returns:
            True if signal is valid
        """
        required_fields = ['action', 'symbol', 'confidence']
        return all(field in signal for field in required_fields)
    
    def get_status(self) -> Dict:
        """Get strategy status"""
        return {
            'name': self.name,
            'active': self.is_active,
            'config': self.config
        }



























