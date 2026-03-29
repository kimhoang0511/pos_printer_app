#!/bin/sh
echo "$PRODUCT_NAME.app" > "$PROJECT_DIR"/Flutter/ephemeral/.app_filename && "$FLUTTER_ROOT"/packages/flutter_tools/bin/macos_assemble.sh embed
xattr -dr com.apple.provenance "$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME" 2>/dev/null || true

