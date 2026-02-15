---
name: notification-test
description: Test the macOS notification system
disable-model-invocation: true
---

# Notification Test Skill

This skill helps test the macOS notification receiver.

When invoked, send a test notification using the notification system to verify it's working correctly.

Use the command at `bin/claude-hook` to send a test notification.

Example:
```bash
python3 bin/claude-hook test "Test Title" "Test message from Claude"
```

If notifications are working, the user should see a desktop notification with the ninja icon.
