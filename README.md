<p align="center">
  <img src="/docs/logo.png" alt="zighash logo" width="75%"/>
</p>

Zighash is a zero-dependency Zig package for generating fast, non-cryptographic hash values using a variety of popular algorithms: **FNV-1a**, **MurmurHash3**, **SpookyHash**, **xxHash**, **SuperFastHash**, and **CityHash**. Perfect for hash-based data structures, checksums, deduplication, and performance-sensitive applications.

## ✨ **Features**

* **Multiple Hash Algorithms:**

  * **FNV-1a:** `fnv1aHash32`, `fnv1aHash64`
  * **SuperFastHash:** `superFastHash32`
  * **MurmurHash3:** `murmur3Hash32`
  * **SpookyHash:** `spookyHash32`, `spookyHash64`
  * **xxHash:** `xxHash32`, `xxHash64`
  * **CityHash:** `cityHash32`, `cityHash64`
* **Pure Zig Implementation:** Zero dependencies, works at runtime and at comptime.
* **Comprehensive Testing:** Built-in `std.testing` suite ensures correctness.

## 🚀 Getting Started

### Fetch via `zig fetch`

You can use the built‑in Zig fetcher to download and pin a tarball:

```bash
zig fetch --save git+https://github.com/galactixx/zighash#v0.2.0
```

> This adds an `zighash` entry under `.dependencies` in your `build.zig.zon`. 

Then in your build.zig:

```zig
const zighash_mod = b.dependency("zighash", .{
    .target = target,
    .optimize = optimize,
}).module("zighash");

// add to library
lib_mod.addImport("zighash", zighash_mod);

// add to executable
exe.root_module.addImport("zighash", zighash_mod);
```

This lets you `const zh = @import("zighash");` in your Zig code.

## 📚 **Usage**

```zig
const std = @import("std");
const zh  = @import("zighash");

pub fn main() void {
    const key = "Hello, Zig!";
    const hash32 = zh.fnv1aHash32(key);
    const hash64 = zh.xxHash64(key);

    std.debug.print("FNV-1a 32-bit: {x}\n", .{hash32});
    std.debug.print("xxHash 64-bit: {x}\n", .{hash64});
}
```

## 🔍 **API**

### FNV-1a

```zig
pub fn fnv1aHash32(key: []const u8) u32
```

* **Parameters:**

  * `key`: The input byte slice (`[]const u8`) to hash.
* **Returns:** A 32-bit unsigned integer (`u32`) representing the FNV-1a hash.

```zig
pub fn fnv1aHash64(key: []const u8) u64
```

* **Parameters:**

  * `key`: The input byte slice.
* **Returns:** A 64-bit unsigned integer (`u64`) representing the FNV-1a hash.

---

### MurmurHash3

```zig
pub fn murmur3Hash32(key: []const u8, seed: u32) u32
```

* **Parameters:**

  * `key`: The input byte slice.
  * `seed`: The 32-bit seed.
* **Returns:** A 32-bit unsigned integer (`u32`) computed by MurmurHash3.

---

### SpookyHash

```zig
pub fn spookyHash32(key: []const u8, seed: u32) u32
pub fn spookyHash64(key: []const u8, seed: u64) u64
```

* **Parameters:**

  * `key`: The input byte slice.
  * `seed`: The 32-bit (`u32`) or 64-bit (`u64`) seed.
* **Returns:** 32-bit (`u32`) or 64-bit (`u64`) hash values.

---

### xxHash

```zig
pub fn xxHash32(key: []const u8, seed: u32) u32
pub fn xxHash64(key: []const u8, seed: u64) u64
```

* **Parameters:**

  * `key`: The input byte slice.
  * `seed`: The 32-bit (`u32`) or 64-bit (`u64`) seed.
* **Returns:** 32-bit or 64-bit non-cryptographic hash.

---

### SuperFastHash

```zig
pub fn superFastHash32(key: []const u8) u32
```

* **Parameters:**

  * `key`: The input byte slice.
* **Returns:** A 32-bit non-cryptographic hash.

---

### CityHash

```zig
pub fn cityHash32(key: []const u8) u32
pub fn cityHash64(key: []const u8) u64
```

* **Parameters:**

  * `key`: The input byte slice.
* **Returns:** 32-bit or 64-bit hash optimized for varied input lengths.

## 🤝 **License**

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 📞 **Contact**

Have questions or want to contribute? Open an issue or pull request on [GitHub](https://github.com/galactixx/zighash).
