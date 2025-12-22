# AI Trading System - API Documentation

## Overview

This module provides AI-powered trading intelligence for the trading bridge system.

## Modules

### Core Components

#### `strategy_engine.py`
Main AI strategy engine that coordinates all AI components.

**Class**: `AIStrategyEngine`

**Methods**:
- `analyze_market(symbol, timeframe)` - Comprehensive market analysis
- `generate_signal(symbol, timeframe)` - Generate trading signal
- `assess_risk(signal)` - AI-powered risk assessment
- `update_models(performance_data)` - Update models from performance

#### `analyzers/market_analyzer.py`
AI-powered market analysis.

**Class**: `AIMarketAnalyzer`

**Methods**:
- `analyze(symbol, timeframe)` - Perform market analysis

#### `models/price_predictor.py`
Price prediction using deep learning.

**Class**: `PricePredictor`

**Methods**:
- `predict(symbol, timeframe, horizon)` - Predict future prices
- `train(training_data, epochs)` - Train model
- `load_model(model_path)` - Load pre-trained model

#### `models/signal_classifier.py`
Signal classification using ML.

**Class**: `SignalClassifier`

**Methods**:
- `classify(market_analysis, price_prediction)` - Classify signals
- `train(training_data, labels)` - Train classifier
- `load_model(model_path)` - Load pre-trained model

#### `risk_manager.py`
Intelligent risk management.

**Class**: `AIRiskManager`

**Methods**:
- `assess_risk(symbol, action, confidence)` - Assess trade risk
- `add_position(symbol, position_data)` - Track position
- `remove_position(symbol)` - Remove position
- `get_portfolio_risk()` - Get portfolio risk status

### Strategies

#### `strategies/base_strategy.py`
Base class for all strategies.

**Class**: `BaseStrategy`

**Methods**:
- `generate_signal(symbol, market_data)` - Generate signal (abstract)
- `get_required_indicators()` - Get required indicators (abstract)
- `validate_signal(signal)` - Validate signal

#### `strategies/ml_strategy.py`
ML-based trading strategy.

**Class**: `MLStrategy`

#### `strategies/technical_strategy.py`
Technical analysis strategy.

**Class**: `TechnicalStrategy`

### Utilities

#### `utils/data_collector.py`
Market data collection.

**Class**: `DataCollector`

**Methods**:
- `collect_historical_data(symbol, timeframe, periods)` - Collect historical data
- `preprocess_data(raw_data)` - Preprocess data for training

#### `utils/train_models.py`
Model training utilities.

**Functions**:
- `train_price_predictor(symbol, timeframe, epochs)` - Train price predictor
- `train_signal_classifier(training_data, labels)` - Train classifier

#### `utils/performance_monitor.py`
Performance monitoring.

**Class**: `PerformanceMonitor`

**Methods**:
- `record_prediction(symbol, prediction, actual_price)` - Record prediction
- `record_signal(symbol, signal, executed)` - Record signal
- `calculate_metrics()` - Calculate performance metrics

## Usage Examples

### Basic Usage

```python
from ai.strategy_engine import AIStrategyEngine

# Initialize engine
engine = AIStrategyEngine()

# Analyze market
analysis = engine.analyze_market('EURUSD', 'H1')

# Generate signal
signal = engine.generate_signal('EURUSD', 'H1')

# Assess risk
risk = engine.assess_risk(signal)
```

### Using Strategies

```python
from ai.strategies.ml_strategy import MLStrategy

# Initialize strategy
strategy = MLStrategy()

# Generate signal
signal = strategy.generate_signal('EURUSD', market_data)
```

### Risk Management

```python
from ai.risk_manager import AIRiskManager

# Initialize risk manager
risk_manager = AIRiskManager()

# Assess risk
risk_assessment = risk_manager.assess_risk(
    symbol='EURUSD',
    action='BUY',
    confidence=0.75
)
```

## Configuration

Configuration is stored in `trading-bridge/config/ai_config.json`.

See main guide for configuration details.

## Dependencies

- numpy
- pandas
- scikit-learn
- tensorflow (or torch)
- pandas-ta
- yfinance
- ccxt

Install with:
```bash
pip install -r trading-bridge/requirements.txt
```

---

**Version**: 1.0.0



























