"""
Performance Optimizer
Optimizes trading parameters using AI
"""
import logging
from typing import Dict, List, Optional
from datetime import datetime
from pathlib import Path
import json

logger = logging.getLogger(__name__)


class PerformanceOptimizer:
    """
    AI-powered performance optimization
    Optimizes trading parameters and strategies
    """
    
    def __init__(self, config: Optional[Dict] = None):
        """
        Initialize performance optimizer
        
        Args:
            config: Configuration dictionary
        """
        self.config = config or {}
        self.performance_history = []
        self.optimization_results = {}
        self.data_dir = Path(__file__).parent.parent.parent.parent / "data" / "performance"
        self.data_dir.mkdir(parents=True, exist_ok=True)
    
    def track_performance(self, trade_result: Dict):
        """
        Track trade performance
        
        Args:
            trade_result: Trade result dictionary with:
                - symbol: Trading symbol
                - action: BUY/SELL
                - entry_price: Entry price
                - exit_price: Exit price (if closed)
                - profit: Profit/loss
                - duration: Trade duration
                - strategy: Strategy used
        """
        try:
            performance_entry = {
                'timestamp': datetime.now().isoformat(),
                **trade_result
            }
            
            self.performance_history.append(performance_entry)
            
            # Keep only recent history (last 1000 trades)
            if len(self.performance_history) > 1000:
                self.performance_history = self.performance_history[-1000:]
            
            # Save to file
            self._save_performance_data()
            
            logger.debug(f"Performance tracked: {trade_result.get('symbol')} - {trade_result.get('profit', 0):.2f}")
            
        except Exception as e:
            logger.error(f"Error tracking performance: {e}")
    
    def analyze_performance(self, strategy_name: Optional[str] = None) -> Dict:
        """
        Analyze trading performance
        
        Args:
            strategy_name: Optional strategy name to filter
            
        Returns:
            Performance analysis dictionary
        """
        try:
            if not self.performance_history:
                return {
                    'total_trades': 0,
                    'win_rate': 0.0,
                    'total_profit': 0.0,
                    'average_profit': 0.0,
                    'max_drawdown': 0.0
                }
            
            # Filter by strategy if specified
            trades = self.performance_history
            if strategy_name:
                trades = [t for t in trades if t.get('strategy') == strategy_name]
            
            if not trades:
                return {
                    'total_trades': 0,
                    'win_rate': 0.0,
                    'total_profit': 0.0
                }
            
            # Calculate metrics
            total_trades = len(trades)
            winning_trades = [t for t in trades if t.get('profit', 0) > 0]
            losing_trades = [t for t in trades if t.get('profit', 0) < 0]
            
            win_rate = len(winning_trades) / total_trades if total_trades > 0 else 0.0
            total_profit = sum([t.get('profit', 0) for t in trades])
            average_profit = total_profit / total_trades if total_trades > 0 else 0.0
            
            # Calculate max drawdown
            cumulative_profit = 0
            peak = 0
            max_drawdown = 0
            
            for trade in trades:
                cumulative_profit += trade.get('profit', 0)
                if cumulative_profit > peak:
                    peak = cumulative_profit
                drawdown = peak - cumulative_profit
                if drawdown > max_drawdown:
                    max_drawdown = drawdown
            
            return {
                'total_trades': total_trades,
                'winning_trades': len(winning_trades),
                'losing_trades': len(losing_trades),
                'win_rate': win_rate,
                'total_profit': total_profit,
                'average_profit': average_profit,
                'max_profit': max([t.get('profit', 0) for t in trades]) if trades else 0.0,
                'min_profit': min([t.get('profit', 0) for t in trades]) if trades else 0.0,
                'max_drawdown': max_drawdown,
                'strategy': strategy_name or 'all'
            }
            
        except Exception as e:
            logger.error(f"Error analyzing performance: {e}")
            return {}
    
    def optimize_parameters(self, strategy_name: str, parameters: Dict) -> Dict:
        """
        Optimize strategy parameters using performance data
        
        Args:
            strategy_name: Strategy name
            parameters: Current parameters to optimize
            
        Returns:
            Optimized parameters dictionary
        """
        try:
            # Analyze performance for this strategy
            performance = self.analyze_performance(strategy_name)
            
            # Simple optimization based on performance
            # TODO: Implement more sophisticated optimization (grid search, genetic algorithm, etc.)
            optimized = parameters.copy()
            
            # Adjust based on win rate
            win_rate = performance.get('win_rate', 0.5)
            if win_rate < 0.4:
                # Low win rate - reduce risk
                if 'risk_percent' in optimized:
                    optimized['risk_percent'] = optimized['risk_percent'] * 0.8
            elif win_rate > 0.6:
                # High win rate - can increase risk slightly
                if 'risk_percent' in optimized:
                    optimized['risk_percent'] = min(optimized['risk_percent'] * 1.1, 2.0)
            
            # Adjust based on drawdown
            max_drawdown = performance.get('max_drawdown', 0.0)
            if max_drawdown > 100:
                # High drawdown - reduce position sizes
                if 'lot_size_multiplier' in optimized:
                    optimized['lot_size_multiplier'] = optimized['lot_size_multiplier'] * 0.9
            
            self.optimization_results[strategy_name] = {
                'timestamp': datetime.now().isoformat(),
                'original': parameters,
                'optimized': optimized,
                'performance': performance
            }
            
            logger.info(f"Optimized parameters for {strategy_name}")
            return optimized
            
        except Exception as e:
            logger.error(f"Error optimizing parameters: {e}")
            return parameters
    
    def _save_performance_data(self):
        """Save performance data to file"""
        try:
            performance_file = self.data_dir / f"performance_{datetime.now().strftime('%Y%m%d')}.json"
            
            with open(performance_file, 'w') as f:
                json.dump(self.performance_history, f, indent=2)
            
        except Exception as e:
            logger.error(f"Error saving performance data: {e}")
    
    def get_optimization_history(self) -> Dict:
        """Get optimization history"""
        return self.optimization_results.copy()



























