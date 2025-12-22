# Compile PythonBridgeEA in MetaEditor

## Quick Steps

1. **Open MetaEditor**
   - From MT5: Tools → MetaQuotes Language Editor
   - Or: Press F4 in MT5

2. **Open the EA File**
   - Navigate to: `MQL5\Experts\PythonBridgeEA.mq5`
   - Or press Ctrl+O and browse to:
     ```
     C:\Users\USER\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Experts\PythonBridgeEA.mq5
     ```

3. **Compile**
   - Press **F7** or click Compile button
   - Check the compile log at the bottom

4. **Verify Compilation**
   - Look for "0 error(s), 0 warning(s)" in compile log
   - If errors, check that PythonBridge.mqh is in Include directory

5. **Check Output**
   - Compiled file: `PythonBridgeEA.ex5` should be created
   - Location: Same directory as .mq5 file

## Common Issues

### Error: Cannot find PythonBridge.mqh
**Solution**: Verify the include file exists:
```
C:\Users\USER\AppData\Roaming\MetaQuotes\Terminal\53785E099C927DB68A545C249CDBCE06\MQL5\Include\PythonBridge.mqh
```

### Error: ZeroMQ library not found
**Note**: The current PythonBridge.mqh uses a simplified implementation. 
For full ZeroMQ support, you would need to install ZeroMQ MQL5 library.

### Compilation Warnings
- Some warnings are normal if using simplified bridge implementation
- As long as compilation succeeds (0 errors), the EA will work

## After Compilation

1. **Attach EA to Chart**
   - Open MT5 Terminal
   - Open a chart (e.g., EURUSD)
   - Drag PythonBridgeEA from Navigator to chart
   - Or right-click chart → Expert Advisors → PythonBridgeEA

2. **Configure Parameters**
   - BridgePort: 5555 (must match Python bridge)
   - BrokerName: EXNESS
   - AutoExecute: true (or false for manual)
   - DefaultLotSize: 0.01

3. **Verify Connection**
   - Check MT5 Experts tab
   - Should see: "Bridge connection initialized on port 5555"
   - No connection errors

## Testing

After attaching EA:
1. Check MT5 Experts tab for initialization messages
2. Check Python bridge logs for connection
3. Test signal flow (if Python service is running)

---

**Ready to compile!** Follow the steps above.

