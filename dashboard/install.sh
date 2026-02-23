#!/bin/bash
set -e

# Buffer Dashboard Installer
# One command: bash <(curl -s https://raw.githubusercontent.com/sigmalabs-ai/buffer/main/dashboard/install.sh)

TOOLS_DIR="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}/tools"
SCRATCH_DIR="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}/scratch"
PORT=8111
PLIST_LABEL="com.openclaw.buffer-dashboard"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"
REPO_BASE="https://raw.githubusercontent.com/sigmalabs-ai/buffer/main/dashboard"

echo "Buffer Dashboard Installer"
echo "=========================="
echo ""

# Create directories
mkdir -p "$TOOLS_DIR"
mkdir -p "$SCRATCH_DIR"

# Download files
echo "Downloading dashboard files..."
curl -sf "$REPO_BASE/server.mjs" -o "$TOOLS_DIR/buffer-dashboard-server.mjs"
curl -sf "$REPO_BASE/dashboard.html" -o "$TOOLS_DIR/buffer-dashboard.html"

# Update server to reference the correct HTML file
sed -i '' "s|context-monitor.html|buffer-dashboard.html|g" "$TOOLS_DIR/buffer-dashboard-server.mjs" 2>/dev/null || \
sed -i "s|context-monitor.html|buffer-dashboard.html|g" "$TOOLS_DIR/buffer-dashboard-server.mjs" 2>/dev/null || true

echo "✓ Files installed to $TOOLS_DIR"

# Detect Node.js
NODE_PATH=$(which node 2>/dev/null)
if [ -z "$NODE_PATH" ]; then
  echo "✗ Node.js not found. Install Node.js and re-run."
  exit 1
fi
echo "✓ Node.js found at $NODE_PATH"

# Set up launchd service (macOS)
if [ "$(uname)" = "Darwin" ]; then
  # Stop existing service if running
  launchctl bootout "gui/$(id -u)/${PLIST_LABEL}" 2>/dev/null || true
  
  cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${NODE_PATH}</string>
        <string>${TOOLS_DIR}/buffer-dashboard-server.mjs</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/buffer-dashboard.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/buffer-dashboard.log</string>
</dict>
</plist>
EOF

  launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null || \
  launchctl load "$PLIST_PATH" 2>/dev/null || true

  echo "✓ Service installed and started"
  echo ""
  echo "Dashboard running at: http://127.0.0.1:${PORT}"
  echo ""
  echo "To expose via Tailscale:"
  echo "  tailscale serve --bg 8112 http://127.0.0.1:${PORT}"
  echo ""
  echo "To uninstall:"
  echo "  launchctl bootout gui/$(id -u)/${PLIST_LABEL}"
  echo "  rm $PLIST_PATH"
  echo "  rm $TOOLS_DIR/buffer-dashboard-server.mjs"
  echo "  rm $TOOLS_DIR/buffer-dashboard.html"

# Linux: create a systemd user service
elif command -v systemctl &>/dev/null; then
  SERVICE_DIR="$HOME/.config/systemd/user"
  mkdir -p "$SERVICE_DIR"
  
  cat > "$SERVICE_DIR/buffer-dashboard.service" << EOF
[Unit]
Description=Buffer Dashboard
After=network.target

[Service]
ExecStart=${NODE_PATH} ${TOOLS_DIR}/buffer-dashboard-server.mjs
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable buffer-dashboard
  systemctl --user start buffer-dashboard

  echo "✓ Systemd service installed and started"
  echo ""
  echo "Dashboard running at: http://127.0.0.1:${PORT}"
  echo ""
  echo "To uninstall:"
  echo "  systemctl --user stop buffer-dashboard"
  echo "  systemctl --user disable buffer-dashboard"
  echo "  rm $SERVICE_DIR/buffer-dashboard.service"
  echo "  rm $TOOLS_DIR/buffer-dashboard-server.mjs"
  echo "  rm $TOOLS_DIR/buffer-dashboard.html"

else
  echo ""
  echo "Dashboard installed but no service manager detected."
  echo "Start manually with:"
  echo "  node $TOOLS_DIR/buffer-dashboard-server.mjs"
  echo ""
  echo "Dashboard will be at: http://127.0.0.1:${PORT}"
fi

echo ""
echo "Built by Sigma Labs"
