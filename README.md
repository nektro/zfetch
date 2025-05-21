# zfetch

![loc](https://sloc.xyz/github/nektro/zfetch)
[![license](https://img.shields.io/github/license/nektro/zfetch.svg)](https://github.com/nektro/zfetch/blob/master/LICENSE)
[![nektro @ github sponsors](https://img.shields.io/badge/sponsors-nektro-purple?logo=github)](https://github.com/sponsors/nektro)
[![Zig](https://img.shields.io/badge/Zig-0.14-f7a41d)](https://ziglang.org/)
[![Zigmod](https://img.shields.io/badge/Zigmod-latest-f7a41d)](https://github.com/nektro/zigmod)

A HTTP request library for Zig with HTTPS support.

> [!WARNING]
> This package is deprecated and only being maintained to work with the latest version of Zig. Any new usage should switch to `std.http.Client`.

## Features

* HTTPS support, including trust handling (provided by [iguanaTLS](https://github.com/alexnask/iguanaTLS))
* A relatively simple interface.

## Notes

* Passing `null` as the `trust_chain` in Request.init will tell zfetch to **not check server certificates**. If you do
  not trust your connection, please provide a iguanaTLS x509 certificate chain.
* zfetch only does rudimentary checks to ensure functions are called in the right order. These are nowhere near enough
  to prevent you from doing so, please call the functions in the order they are intended to be called in.

## Adding zfetch as a package

### Gyro

```zzz
# gyro.zzz

...

deps:
  truemedian/zfetch: ^0.1.1

...
```

### Zigmod

```yaml
# zig.mod

...

dependencies:
  - type: git
    path: https://github.com/truemedian/zfetch

...
```

### Submodules

> Assuming zfetch is **recursively** checked out at `libs/zfetch`

```zig
// build.zig

const zfetch = @import("libs/zfetch/build.zig");

...

exe.addPackage(zfetch.getPackage(b, "libs/zfetch"));

...
```

## Examples

see [examples](https://github.com/truemedian/zfetch/tree/master/examples).

**More Coming Soon...?**
