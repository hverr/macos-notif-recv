# macOS Notification Receiver

A native macOS menu bar application that listens for JSON-RPC requests and displays system notifications with a custom ninja icon.

Includes a **Claude Code plugin** with hooks for automatic notifications when Claude needs your attention.

**📦 Plugin Documentation**: See [PLUGIN.md](PLUGIN.md) for Claude Code plugin installation and usage.

## Features

- Menu bar application (no dock icon) with custom ninja icon
- Listens on port 8080 for JSON-RPC 2.0 requests
- Displays macOS notifications with title and message
- Compatible with macOS Catalina 10.15 and later

## Building

Build the application using the included Makefile:

```bash
make
```

This will create `build/NotificationReceiver.app`

## Running

Start the application:

```bash
make run
```

Or launch the app bundle directly:

```bash
open build/NotificationReceiver.app
```

The app will appear in your menu bar with a green indicator when running successfully.

## Usage

Send JSON-RPC requests to `localhost:8080` to display notifications.

### Request Format

```json
{
  "jsonrpc": "2.0",
  "method": "notify",
  "params": {
    "title": "Notification Title",
    "message": "Notification message text"
  },
  "id": 1
}
```

### Response Format

Success:
```json
{
  "jsonrpc": "2.0",
  "result": "success",
  "id": 1
}
```

Error:
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32700,
    "message": "Parse error"
  },
  "id": null
}
```

### Example

Using `nc` (netcat):

```bash
printf '{"jsonrpc":"2.0","method":"notify","params":{"title":"Hello","message":"World"},"id":1}' | nc localhost 8080
```

Using `curl`:

```bash
curl -X POST http://localhost:8080 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"notify","params":{"title":"Hello","message":"World"},"id":1}'
```

Or use the built-in test:

```bash
make test
```

## Error Codes

- `-32700`: Parse error (invalid JSON)
- `-32600`: Invalid Request (not JSON-RPC 2.0)
- `-32601`: Method not found (method != "notify")
- `-32602`: Invalid params (missing title or message)
- `-32603`: Internal error

## Files

- `main.m` - Application entry point
- `AppDelegate.h/m` - App lifecycle and menu bar management
- `JSONRPCServer.h/m` - TCP server and JSON-RPC handler
- `NotificationManager.h/m` - macOS notification display
- `Info.plist` - App configuration
- `Makefile` - Build system
- `ninja_menubar.png` - Menu bar icon (32x32)

## Cleaning

Remove build artifacts:

```bash
make clean
```

## Quitting

Click the menu bar icon and select "Quit" or press Cmd+Q when the app has focus.

---

# Claude Hook Integration

The `claude-hook` Python client integrates with Claude Code to send desktop notifications when the agent needs input or finishes tasks.

## Installation

### macOS App

Build and run the notification receiver:

```bash
make
make run
```

The ninja icon should appear in your menu bar.

### Claude Code Plugin

See [claude-plugin/README.md](claude-plugin/README.md) for plugin installation and usage.

Quick setup:
```bash
python3 claude-plugin/bin/claude-hook configure localhost:8080
python3 claude-plugin/bin/claude-hook install
```

## Testing

Test notifications:

```bash
# Direct test
python3 claude-plugin/bin/claude-hook test "Hello" "World"

# Or use printf with nc
printf '{"jsonrpc":"2.0","method":"notify","params":{"title":"Test","message":"Hello"},"id":1}' | nc localhost 8080
```

## Project Structure

```
mac-notif-recv/
├── claude-plugin/          # Claude Code plugin
│   ├── .claude-plugin/     # Plugin manifest
│   ├── bin/                # claude-hook Python script
│   ├── commands/           # Plugin commands
│   ├── hooks/              # Hook definitions
│   ├── skills/             # Plugin skills
│   └── README.md           # Plugin documentation
├── *.m, *.h                # Objective-C source files
├── Makefile                # Build system
├── Info.plist              # App configuration
└── README.md               # This file
```
