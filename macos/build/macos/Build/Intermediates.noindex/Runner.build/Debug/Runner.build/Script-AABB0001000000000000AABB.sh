#!/bin/sh
find -L "$BUILT_PRODUCTS_DIR/$FULL_PRODUCT_NAME" -exec xattr -c {} \; 2>/dev/null || true

