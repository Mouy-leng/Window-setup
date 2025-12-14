# Browser Support for Secure Trading

This directory contains browser-based interfaces for monitoring and controlling your secure trading setup.

## Features

- **Secure Dashboard**: Real-time monitoring of security status
- **Browser-based Execution**: Run monitoring tools directly in your browser
- **Cross-platform**: Works on any modern browser (Chrome, Firefox, Edge, Safari)
- **No External Dependencies**: Pure HTML/CSS/JavaScript implementation

## Files

- `dashboard.html`: Main security monitoring dashboard
- `README.md`: This file

## Usage

### Local Mode

1. Open `dashboard.html` in your browser
2. Click "Start Monitoring" to begin security checks
3. Monitor the activity log for real-time updates

### Server Mode (Optional)

You can serve the dashboard using any HTTP server:

**Python 3:**
```bash
cd browser-support
python -m http.server 8080
```

**Node.js:**
```bash
cd browser-support
npx http-server -p 8080
```

Then navigate to `http://localhost:8080/dashboard.html`

## Security Features

- Content Security Policy (CSP) enabled
- No external resource loading
- Sandboxed execution environment
- Secure communication protocols
- Real-time security monitoring

## Browser Compatibility

- Chrome 90+
- Firefox 88+
- Edge 90+
- Safari 14+
- Opera 76+

## Integration with MQL5

The browser dashboard can be integrated with your MQL5 trading setup:

1. Run the MQL5 security monitoring script
2. Open the browser dashboard
3. Both systems will work in parallel for comprehensive monitoring

## Notes

- All operations are performed locally for maximum security
- No data is sent to external servers
- Browser mode is optional and complements local execution
- Can be used for research, monitoring, and job management
