# Terminal font

`terminal.psf` is the 12×24 Terminus PSF2 bitmap font used by the QEMU-only
framebuffer backend. It was sourced from Debian's `console-setup-linux`
package at `/usr/share/consolefonts/Lat38-Terminus24x12.psf.gz`, decompressed
without transformation.

- PSF2 magic: `0x864AB572`
- Glyphs: 256
- Glyph size: 12×24, 48 bytes per glyph
- SHA-256: `d44d99979aebb067ac76d3780962d11151d6e8eb34aefae51e3d0015286d6ba7`

The font is placed in MyFS as `terminal.psf`; it is never linked into
`kernel.bin`. Terminus is distributed under the SIL Open Font License 1.1.
