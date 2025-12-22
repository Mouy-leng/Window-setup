"""
AI Performance Monitor
Monitors AI system performance and metrics
"""
import logging
from typing import Dict, List, Optional
from datetime import datetime
from pathlib import Path
import json

logger = logging.getLogger(__name__)


class PerformanceMonitor:
    """
    Monitors AI trading system performance
    """
    
    def __init__(self, config: Optional[Dict] = None):
        """
        Initialize performance monitor
        
        Args:
            config: Configuration dictionary
        """
        self.config = config or {}
        self.metrics = {
            'predictions': [],
            'signals': [],
            'trades': [],
            'performance': {}
        }
        self.log_dir = Path(__file__).parent.parent.parent.parent / "logs"
        self.log_dir.mkdir(parents=True, exist_ok=True)
    
    def record_prediction(self, symbol: str, prediction: Dict, actual_price: Optional[float] = None):
        """
        Record price prediction
        
        Args:
            symbol: Trading symbol
            prediction: Prediction dictionary
            actual_price: Actual price (for accuracy calculation)
        """
        try:
            entry = {
                'timestamp': datetime.now().isoformat(),
                'symbol': symbol,
                'prediction': prediction,
                'actual_price': actual_price,
                'accuracy': None
            }
            
            # Calculate accuracy if actual price available
            if actual_price and prediction.get('predicted_price'):
                predicted = prediction.get('predicted_price')
                error = abs(predicted - actual_price) / actual_price if actual_price > 0 else 1.0
                entry['accuracy'] = 1.0 - min(error, 1.0)
            
            self.metrics['predictions'].append(entry)
            
            # Keep only recent predictions (last 1000)
            if len(self.metrics['predictions']) > 1000:
                self.metrics['predictions'] = self.metrics['predictions'][-1000:]
            
            logger.debug(f"Recorded prediction for {symbol}")
            
        except Exception as e:
            logger.error(f"Error recording prediction: {e}")
    
    def record_signal(self, symbol: str, signal: Dict, executed: bool = False):
        """
        Record trading signal
        
        Args:
            symbol: Trading symbol
            signal: Signal dictionary
            executed: Whether signal was executed
        """
        try:
            entry = {
                'timestamp': datetime.now().isoformat(),
                'symbol': symbol,
                'signal': signal,
                'executed': executed
            }
            
            self.metrics['signals'].append(entry)
            
            # Keep only recent signals (last 1000)
            if len(self.metrics['signals']) > 1000:
                self.metrics['signals'] = self.metrics['signals'][-1000:]
            
            logger.debug(f"Recorded signal for {symbol}")
            
        except Exception as e:
            logger.error(f"Error recording signal: {e}")
    
    def calculate_metrics(self) -> Dict:
        """
        Calculate performance metrics
        
        Returns:
            Metrics dictionary
        """
        try:
            metrics = {
                'prediction_accuracy': self._calculate_prediction_accuracy(),
                'signal_success_rate': self._calculate_signal_success_rate(),
                'total_signals': len(self.metrics['signals']),
                'executed_signals': len([s for s in self.metrics['signals'] if s.get('executed', False)]),
                'total_predictions': len(self.metrics['predictions'])
            }
            
            self.metrics['performance'] = metrics
            return metrics
            
        except Exception as e:
            logger.error(f"Error calculating metrics: {e}")
            return {}
    
    def _calculate_prediction_accuracy(self) -> float:
        """Calculate average prediction accuracy"""
        predictions_with_accuracy = [
            p for p in self.metrics['predictions'] 
            if p.get('accuracy') is not None
        ]
        
        if not predictions_with_accuracy:
            return 0.0
        
        avg_accuracy = sum([p['accuracy'] for p in predictions_with_accuracy]) / len(predictions_with_accuracy)
        return avg_accuracy
    
    def _calculate_signal_success_rate(self) -> float:
        """Calculate signal success rate"""
        # TODO: Implement signal success rate calculation
        # This requires tracking which signals led to profitable trades
        return 0.0
    
    def save_metrics(self):
        """Save metrics to file"""
        try:
            metrics_file = self.log_dir / f"ai_performance_{datetime.now().strftime('%Y%m%d')}.json"
            
            with open(metrics_file, 'w') as f:
                json.dump(self.metrics, f, indent=2)
            
            logger.info(f"Metrics saved to {metrics_file}")
            
        except Exception as e:
            logger.error(f"Error saving metrics: {e}")
    
    def get_summary(self) -> Dict:
        """Get performance summary"""
        metrics = self.calculate_metrics()
        
        return {
            'timestamp': datetime.now().isoformat(),
            'metrics': metrics,
            'recent_predictions': len([p for p in self.metrics['predictions'] if 
                                     (datetime.now() - datetime.fromisoformat(p['timestamp'])).days < 1]),
            'recent_signals': len([s for s in self.metrics['signals'] if 
                                  (datetime.now() - datetime.fromisoformat(s['timestamp'])).days < 1])
        }



























