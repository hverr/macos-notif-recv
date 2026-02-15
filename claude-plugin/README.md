# macOS Notifications Plugin for Claude Code

A Claude Code plugin that provides desktop notifications for Claude events with a custom ninja icon.

## Features

- 🥷 Custom ninja icon for all notifications
- 🔔 Automatic notifications for Claude events (Stop, Notification, SubagentStop)
- ⚡ Native macOS notification center integration
- 🎯 JSON-RPC server for programmatic notifications
- 🔧 Easy configuration and testing

## Prerequisites

- macOS 10.15 (Catalina) or later
- Python 3.7+
- Claude Code

## Quick Start

### 1. Build the notification receiver app

```bash
cd mac-notif-recv
make
make run
```

The ninja icon should appear in your menu bar.

### 2. Configure the plugin

From the project root:
```bash
python3 claude-plugin/bin/claude-hook configure localhost:9090
python3 claude-plugin/bin/claude-hook install
```

### 3. Test it

```bash
python3 claude-plugin/bin/claude-hook test
```

Or use the Claude Code command (after plugin installation):
```bash
/macos-notifications:notify
```

## Installation as Plugin

To install this as a Claude Code plugin:

```bash
# From the project root
cd /path/to/mac-notif-recv
claude plugin add --local claude-plugin

# Or from a Git repository
claude plugin add https://github.com/yourusername/mac-notif-recv/claude-plugin
```

## How It Works

### Notification Receiver (macOS App)

- Lives in your menu bar with the ninja icon
- Listens on port 8080 for JSON-RPC requests
- Displays native macOS notifications

### Hook Client (Python Script)

- Integrates with Claude Code hooks
- Sends notifications when Claude events occur
- Configurable via `~/.macos-notif-for-claude`

### Plugin Structure

```
.claude-plugin/
  plugin.json       # Plugin manifest
hooks/
  hooks.json        # Hook definitions for Claude events
commands/
  notify            # /macos-notifications:notify command
skills/
  notification-test/  # Test skill
bin/
  claude-hook       # Python client script
```

## Commands

After plugin installation:
- `/macos-notifications:notify` - Send a test notification from Claude

From command line (paths relative to project root):
- `python3 claude-plugin/bin/claude-hook test` - Send test notification
- `python3 claude-plugin/bin/claude-hook configure <host>:<port>` - Configure server
- `python3 claude-plugin/bin/claude-hook install` - Install hooks

## Events

The plugin automatically sends notifications for:

- **Notification** - When Claude needs your attention
- **Stop** - When Claude finishes responding
- **SubagentStop** - When a Claude agent completes a task

## Configuration

Server configuration is stored in `~/.macos-notif-for-claude`:

```json
{
  "hostname": "localhost",
  "port": 8080
}
```

## Customization

### Change the Icon

Replace `ninja_transparent.png` and rebuild the app:

```bash
# Create transparent version of your icon
# ... (use provided transparency tool)

# Rebuild icon set
make clean
make
```

### Add More Events

Edit `hooks/hooks.json` to add hooks for other Claude events like:
- `SessionStart`
- `UserPromptSubmit`
- `PreToolUse`
- `PostToolUse`
- `TaskCompleted`

## Troubleshooting

**No notifications appearing?**
- Check if the menu bar app is running (look for ninja icon)
- Test with: `python3 bin/claude-hook test "Test" "Message"`
- Check Console.app for app logs

**Hooks not working?**
- Verify installation: `cat ~/.claude/settings.json`
- Make sure the hook command path is correct
- Test manually: `echo '{"hook_event_name":"Stop"}' | python3 bin/claude-hook run`

**Port already in use?**
- Change the port in Makefile (default: 8080)
- Reconfigure: `python3 bin/claude-hook configure localhost:PORT`

## License

MIT
