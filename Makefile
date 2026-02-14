# Makefile for NotificationReceiver macOS app

APP_NAME = NotificationReceiver
BUNDLE_NAME = $(APP_NAME).app
BUILD_DIR = build
CONTENTS_DIR = $(BUILD_DIR)/$(BUNDLE_NAME)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

SOURCES = main.m AppDelegate.m JSONRPCServer.m NotificationManager.m
OBJECTS = $(SOURCES:.m=.o)

CC = clang
CFLAGS = -framework Cocoa -framework Foundation -fobjc-arc
LDFLAGS = -framework Cocoa -framework Foundation

.PHONY: all clean run

all: $(BUILD_DIR)/$(BUNDLE_NAME)

$(BUILD_DIR)/$(BUNDLE_NAME): $(OBJECTS) Info.plist
	@echo "Creating app bundle..."
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	$(CC) $(LDFLAGS) -o $(MACOS_DIR)/$(APP_NAME) $(OBJECTS)
	@cp Info.plist $(CONTENTS_DIR)/
	@if [ -f ninja_menubar.png ]; then cp ninja_menubar.png $(RESOURCES_DIR)/ninja.png; fi
	@if [ -f AppIcon.icns ]; then cp AppIcon.icns $(RESOURCES_DIR)/; fi
	@echo "Build complete: $(BUILD_DIR)/$(BUNDLE_NAME)"

%.o: %.m
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) *.o

run: all
	@echo "Starting $(APP_NAME)..."
	@open $(BUILD_DIR)/$(BUNDLE_NAME)

.PHONY: test
test:
	@echo "Sending test notification..."
	@echo '{"jsonrpc":"2.0","method":"notify","params":{"title":"Test","message":"Hello from JSON-RPC!"},"id":1}' | nc localhost 8080
