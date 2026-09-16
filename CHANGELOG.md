## 1.0.2
**Sep 16, 2026**
- Fix crash (SIGSEGV) in WebP encoder: no longer releases the borrowed `CGImage` data provider and color space refs returned by `CGImageGetDataProvider`/`CGImageGetColorSpace` (Get Rule — not owned), which caused a use-after-free when the `CGImage` was finalized.

## 1.0.1
**Sep 2, 2026**
- Improve pub score

## 1.0.0
**Sep 2, 2026**
- Initial release
