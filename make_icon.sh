#!/bin/bash
# Rebuild assets/the-rock.ico (the Windows tray/exe icon) from one frame of
# the gif. Default is frame 11 -- the peak of the eyebrow raise.
#
#   ./make_icon.sh [frame-index]
#
# macOS only (uses ImageIO); the .ico it writes is what win.rc compiles in.
set -euo pipefail
cd "$(dirname "$0")"

FRAME="${1:-11}"
GIF="assets/the-rock.gif"
ICO="assets/the-rock.ico"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/extract.mm" <<'MM'
#import <Cocoa/Cocoa.h>
#import <ImageIO/ImageIO.h>
int main(int argc, const char **argv) { @autoreleasepool {
  NSData *d = [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]];
  CGImageSourceRef s = CGImageSourceCreateWithData((__bridge CFDataRef)d, NULL);
  if (!s) { fprintf(stderr, "cannot read gif\n"); return 1; }
  size_t n = CGImageSourceGetCount(s), i = (size_t)atoi(argv[2]);
  if (i >= n) { fprintf(stderr, "frame %zu out of range (%zu frames)\n", i, n); return 1; }
  CGImageRef img = CGImageSourceCreateImageAtIndex(s, i, NULL);
  NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];
  NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
  [png writeToFile:[NSString stringWithUTF8String:argv[3]] atomically:YES];
  printf("frame %zu of %zu\n", i, n);
} return 0; }
MM

clang++ -x objective-c++ -fobjc-arc -O1 "$TMP/extract.mm" -o "$TMP/extract" \
  -framework Cocoa -framework ImageIO
"$TMP/extract" "$GIF" "$FRAME" "$TMP/frame.png"

for s in 16 32 48 64 128 256; do
  sips -s format png -z $s $s "$TMP/frame.png" --out "$TMP/$s.png" >/dev/null
done

python3 - "$TMP" "$ICO" <<'PY'
import struct, sys
tmp, out_path = sys.argv[1], sys.argv[2]
sizes = [16, 32, 48, 64, 128, 256]
imgs = [(s, open(f"{tmp}/{s}.png", "rb").read()) for s in sizes]

blob = bytearray(struct.pack("<HHH", 0, 1, len(imgs)))   # ICONDIR
offset = 6 + 16 * len(imgs)
entries, payload = bytearray(), bytearray()
for s, data in imgs:
    dim = 0 if s >= 256 else s                            # 0 means 256
    entries += struct.pack("<BBBBHHII", dim, dim, 0, 0, 1, 32, len(data), offset)
    payload += data
    offset += len(data)
open(out_path, "wb").write(bytes(blob + entries + payload))
print(f"wrote {out_path} ({len(blob)+len(entries)+len(payload)} bytes, {len(imgs)} sizes)")
PY
