#!/bin/bash
# Launch Chrome with remote debugging for MCP Server
# This allows AI assistants to inspect browser state via Chrome DevTools Protocol

echo "Stopping any existing Chrome debug instances..."
pkill -f "chrome-debug-profile" 2>/dev/null || true

echo "Launching Chrome with remote debugging on port 9222..."
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-debug-profile \
  --no-first-run \
  --no-default-browser-check \
  > /tmp/chrome-debug.log 2>&1 &

sleep 2

echo "Verifying Chrome remote debugging..."
if curl -s http://localhost:9222/json/version > /dev/null 2>&1; then
    echo "✅ Chrome remote debugging is active on port 9222"
    echo ""
    echo "Browser Info:"
    curl -s http://localhost:9222/json/version | python3 -m json.tool
    echo ""
    echo "📝 Navigate Chrome to: http://localhost:8000/auth/login/"
    echo "🔍 AI Assistant can now inspect browser state via DevTools MCP"
else
    echo "❌ Failed to start Chrome remote debugging"
    exit 1
fi
