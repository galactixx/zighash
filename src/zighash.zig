const std = @import("std");

fn toLittleEndian(comptime IntT: type, bytes: []const u8) IntT {
    var endian: IntT = 0;

    for (0..bytes.len) |idx| {
        const byteCast: IntT = @intCast(bytes[idx]);
        endian |= byteCast << @intCast(idx * 8);
    }
    return endian;
}

fn rotl64(val: u64, rot: u6) u64 {
    return (val << rot) | (val >> (63 - rot + 1));
}

fn rotl32(val: u32, rot: u5) u32 {
    return (val << rot) | (val >> (31 - rot + 1));
}

fn rotr32(val: u32, rot: u5) u32 {
    return (val >> rot) | (val << (31 - rot + 1));
}

fn rotr64(val: u64, rot: u6) u64 {
    return (val >> rot) | (val << (63 - rot + 1));
}

pub fn fnv1aHash32(key: []const u8) u32 {
    var fnv1aHash: u32 = 2166136261;
    for (0..key.len) |i| {
        fnv1aHash = 16777619 *% (fnv1aHash ^ key[i]);
    }
    return fnv1aHash;
}

pub fn fnv1aHash64(key: []const u8) u64 {
    var fnv1aHash: u64 = 14695981039346656037;
    for (0..key.len) |i| {
        fnv1aHash = 1099511628211 *% (fnv1aHash ^ key[i]);
    }
    return fnv1aHash;
}

fn jenkinsMix(a: *u32, b: *u32, c: *u32) void {
    a.* -%= c.*;
    a.* ^= rotl32(c.*, 4);
    c.* +%= b.*;
    b.* -%= a.*;
    b.* ^= rotl32(a.*, 6);
    a.* +%= c.*;
    c.* -%= b.*;
    c.* ^= rotl32(b.*, 8);
    b.* +%= a.*;
    a.* -%= c.*;
    a.* ^= rotl32(c.*, 16);
    c.* +%= b.*;
    b.* -%= a.*;
    b.* ^= rotl32(a.*, 19);
    a.* +%= c.*;
    c.* -%= b.*;
    c.* ^= rotl32(b.*, 4);
    b.* +%= a.*;
}

fn jenkinsFinal(a: *u32, b: *u32, c: *u32) void {
    c.* ^= b.*;
    c.* -%= rotl32(b.*, 14);
    a.* ^= c.*;
    a.* -%= rotl32(c.*, 11);
    b.* ^= a.*;
    b.* -%= rotl32(a.*, 25);
    c.* ^= b.*;
    c.* -%= rotl32(b.*, 16);
    a.* ^= c.*;
    a.* -%= rotl32(c.*, 4);
    b.* ^= a.*;
    b.* -%= rotl32(a.*, 14);
    c.* ^= b.*;
    c.* -%= rotl32(b.*, 24);
}

pub fn jenkinsLookup3(key: []const u8) u32 {
    const seed: u32 = 0;
    const length: u32 = @truncate(key.len);
    var bytesLeft: usize = key.len;
    var a: u32 = 0xdeadbeef +% (length << 2) +% seed;
    var b: u32 = 0xdeadbeef +% (length << 2) +% seed;
    var c: u32 = 0xdeadbeef +% (length << 2) +% seed;

    var i: usize = 0;
    while (bytesLeft > 3) : (bytesLeft -= 3) {
        a +%= key[i];
        b +%= key[i + 1];
        c +%= key[i + 2];
        jenkinsMix(&a, &b, &c);
        i += 3;
    }

    switch (bytesLeft) {
        3 => c +%= @intCast(key[i + 2]),
        2 => c +%= @intCast(key[i + 1]),
        1 => c +%= @intCast(key[i]),
        else => {},
    }

    if (bytesLeft > 0) {
        jenkinsFinal(&a, &b, &c);
    }

    return c;
}

const sc: u64 = 0xdeadbeefdeadbeef;

fn shortPass(byte: u8, lsl: u6) u64 {
    const byte64: u64 = @intCast(byte);
    return byte64 << lsl;
}

fn shortMix(h0: *u64, h1: *u64, h2: *u64, h3: *u64) void {
    h2.* = rotl64(h2.*, 50);
    h2.* +%= h3.*;
    h0.* ^= h2.*;
    h3.* = rotl64(h3.*, 52);
    h3.* +%= h0.*;
    h1.* ^= h3.*;
    h0.* = rotl64(h0.*, 30);
    h0.* +%= h1.*;
    h2.* ^= h0.*;
    h1.* = rotl64(h1.*, 41);
    h1.* +%= h2.*;
    h3.* ^= h1.*;
    h2.* = rotl64(h2.*, 54);
    h2.* +%= h3.*;
    h0.* ^= h2.*;
    h3.* = rotl64(h3.*, 48);
    h3.* +%= h0.*;
    h1.* ^= h3.*;
    h0.* = rotl64(h0.*, 38);
    h0.* +%= h1.*;
    h2.* ^= h0.*;
    h1.* = rotl64(h1.*, 37);
    h1.* +%= h2.*;
    h3.* ^= h1.*;
    h2.* = rotl64(h2.*, 62);
    h2.* +%= h3.*;
    h0.* ^= h2.*;
    h3.* = rotl64(h3.*, 34);
    h3.* +%= h0.*;
    h1.* ^= h3.*;
    h0.* = rotl64(h0.*, 5);
    h0.* +%= h1.*;
    h2.* ^= h0.*;
    h1.* = rotl64(h1.*, 36);
    h1.* +%= h2.*;
    h3.* ^= h1.*;
}

fn shortEnd(h0: *u64, h1: *u64, h2: *u64, h3: *u64) void {
    h3.* ^= h2.*;
    h2.* = rotl64(h2.*, 15);
    h3.* +%= h2.*;
    h0.* ^= h3.*;
    h3.* = rotl64(h3.*, 52);
    h0.* +%= h3.*;
    h1.* ^= h0.*;
    h0.* = rotl64(h0.*, 26);
    h1.* +%= h0.*;
    h2.* ^= h1.*;
    h1.* = rotl64(h1.*, 51);
    h2.* +%= h1.*;
    h3.* ^= h2.*;
    h2.* = rotl64(h2.*, 28);
    h3.* +%= h2.*;
    h0.* ^= h3.*;
    h3.* = rotl64(h3.*, 9);
    h0.* +%= h3.*;
    h1.* ^= h0.*;
    h0.* = rotl64(h0.*, 47);
    h1.* +%= h0.*;
    h2.* ^= h1.*;
    h1.* = rotl64(h1.*, 54);
    h2.* +%= h1.*;
    h3.* ^= h2.*;
    h2.* = rotl64(h2.*, 32);
    h3.* +%= h2.*;
    h0.* ^= h3.*;
    h3.* = rotl64(h3.*, 25);
    h0.* +%= h3.*;
    h1.* ^= h0.*;
    h0.* = rotl64(h0.*, 63);
    h1.* +%= h0.*;
}

fn shortReturn(h0: u64, h1: u64, h2: u64, h3: u64) struct { u64, u64 } {
    var a: u64 = h0;
    var b: u64 = h1;
    var c: u64 = h2;
    var d: u64 = h3;
    shortEnd(&a, &b, &c, &d);
    return .{ a, b };
}

fn endPartial(
    h0: *u64,
    h1: *u64,
    h2: *u64,
    h3: *u64,
    h4: *u64,
    h5: *u64,
    h6: *u64,
    h7: *u64,
    h8: *u64,
    h9: *u64,
    h10: *u64,
    h11: *u64,
) void {
    h11.* +%= h1.*;
    h2.* ^= h11.*;
    h1.* = rotl64(h1.*, 44);

    h0.* +%= h2.*;
    h3.* ^= h0.*;
    h2.* = rotl64(h2.*, 15);

    h1.* +%= h3.*;
    h4.* ^= h1.*;
    h3.* = rotl64(h3.*, 34);

    h2.* +%= h4.*;
    h5.* ^= h2.*;
    h4.* = rotl64(h4.*, 21);

    h3.* +%= h5.*;
    h6.* ^= h3.*;
    h5.* = rotl64(h5.*, 38);

    h4.* +%= h6.*;
    h7.* ^= h4.*;
    h6.* = rotl64(h6.*, 33);

    h5.* +%= h7.*;
    h8.* ^= h5.*;
    h7.* = rotl64(h7.*, 10);

    h6.* +%= h8.*;
    h9.* ^= h6.*;
    h8.* = rotl64(h8.*, 13);

    h7.* +%= h9.*;
    h10.* ^= h7.*;
    h9.* = rotl64(h9.*, 38);

    h8.* +%= h10.*;
    h11.* ^= h8.*;
    h10.* = rotl64(h10.*, 53);

    h9.* +%= h11.*;
    h0.* ^= h9.*;
    h11.* = rotl64(h11.*, 42);

    h10.* +%= h0.*;
    h1.* ^= h10.*;
    h0.* = rotl64(h0.*, 54);
}

fn spookyHash128(key: []const u8) struct { u64, u64 } {
    const seed: u32 = 0;
    if (key.len < 192) {
        var a: u64 = 0;
        var b: u64 = 0;
        var c: u64 = sc;
        var d: u64 = sc;

        var i: usize = 0;
        var bytesLeft: usize = key.len;
        if (key.len > 15) {
            while (bytesLeft >= 32) : (bytesLeft -= 32) {
                c +%= read8To64(key, i);
                d +%= read8To64(key, i + 8);
                shortMix(&a, &b, &c, &d);
                a +%= read8To64(key, i + 16);
                b +%= read8To64(key, i + 24);
                i += 32;
            }

            if (bytesLeft >= 16) {
                c +%= read8To64(key, i);
                d +%= read8To64(key, i + 8);
                shortMix(&a, &b, &c, &d);
                bytesLeft -= 16;
                i += 16;
            }
        }

        const length: u64 = @truncate(key.len);
        d +%= (length << 56);

        // first four bytes
        if (bytesLeft >= 15) {
            d +%= shortPass(key[i + 14], 48);
        }
        if (bytesLeft >= 14) {
            d +%= shortPass(key[i + 13], 40);
        }
        if (bytesLeft >= 13) {
            d +%= shortPass(key[i + 12], 32);
        }
        if (bytesLeft >= 12) {
            d +%= read4To32(key, i + 8);
            c +%= read8To64(key, i);
            return shortReturn(a, b, c, d);
        }

        // second four bytes
        if (bytesLeft >= 11) {
            d +%= shortPass(key[i + 10], 16);
        }
        if (bytesLeft >= 10) {
            d +%= shortPass(key[i + 9], 8);
        }
        if (bytesLeft >= 9) {
            d +%= key[i + 8];
        }
        if (bytesLeft >= 8) {
            c +%= read8To64(key, i);
            return shortReturn(a, b, c, d);
        }

        // third four bytes
        if (bytesLeft >= 7) {
            c +%= shortPass(key[i + 6], 48);
        }
        if (bytesLeft >= 6) {
            c +%= shortPass(key[i + 5], 40);
        }
        if (bytesLeft >= 5) {
            c +%= shortPass(key[i + 4], 32);
        }
        if (bytesLeft >= 4) {
            c +%= read4To32(key, i);
            return shortReturn(a, b, c, d);
        }

        // last four bytes
        if (bytesLeft >= 3) {
            c +%= shortPass(key[i + 2], 16);
        }
        if (bytesLeft >= 2) {
            c +%= shortPass(key[i + 1], 8);
        }
        if (bytesLeft >= 1) {
            c +%= key[i];
            return shortReturn(a, b, c, d);
        }
        c +%= sc;
        d +%= sc;
        return shortReturn(a, b, c, d);
    } else {
        var h0: u64 = @intCast(seed);
        var h1: u64 = @intCast(seed);
        var h2: u64 = sc;
        var h3: u64 = @intCast(seed);
        var h4: u64 = @intCast(seed);
        var h5: u64 = sc;
        var h6: u64 = @intCast(seed);
        var h7: u64 = @intCast(seed);
        var h8: u64 = sc;
        var h9: u64 = @intCast(seed);
        var h10: u64 = @intCast(seed);
        var h11: u64 = sc;

        var bytesLeft: usize = key.len;
        var i: usize = 0;

        while (bytesLeft >= 96) : (bytesLeft -= 96) {
            h0 +%= read8To64(key, i);
            h2 ^= h10;
            h11 ^= h0;
            h0 = rotl64(h0, 11);
            h11 +%= h1;

            h1 +%= read8To64(key, i + 8);
            h3 ^= h11;
            h0 ^= h1;
            h1 = rotl64(h1, 32);
            h0 +%= h2;

            h2 +%= read8To64(key, i + 16);
            h4 ^= h0;
            h1 ^= h2;
            h2 = rotl64(h2, 43);
            h1 +%= h3;

            h3 +%= read8To64(key, i + 24);
            h5 ^= h1;
            h2 ^= h3;
            h3 = rotl64(h3, 31);
            h2 +%= h4;

            h4 +%= read8To64(key, i + 32);
            h6 ^= h2;
            h3 ^= h4;
            h4 = rotl64(h4, 17);
            h3 +%= h5;

            h5 +%= read8To64(key, i + 40);
            h7 ^= h3;
            h4 ^= h5;
            h5 = rotl64(h5, 28);
            h4 +%= h6;

            h6 +%= read8To64(key, i + 48);
            h8 ^= h4;
            h5 ^= h6;
            h6 = rotl64(h6, 39);
            h5 +%= h7;

            h7 +%= read8To64(key, i + 56);
            h9 ^= h5;
            h6 ^= h7;
            h7 = rotl64(h7, 57);
            h6 +%= h8;

            h8 +%= read8To64(key, i + 64);
            h10 ^= h6;
            h7 ^= h8;
            h8 = rotl64(h8, 55);
            h7 +%= h9;

            h9 +%= read8To64(key, i + 72);
            h11 ^= h7;
            h8 ^= h9;
            h9 = rotl64(h9, 54);
            h8 +%= h10;

            h10 +%= read8To64(key, i + 80);
            h0 ^= h8;
            h9 ^= h10;
            h10 = rotl64(h10, 22);
            h9 +%= h11;

            h11 +%= read8To64(key, i + 88);
            h1 ^= h9;
            h10 ^= h11;
            h11 = rotl64(h11, 46);
            h10 +%= h0;
            i += 96;
        }

        var buf: [96]u8 = undefined;
        @memcpy(buf[0..bytesLeft], key[i..]);
        @memset(buf[bytesLeft..96], 0);
        buf[95] = @truncate(bytesLeft);

        h0 +%= read8To64(buf[0..], 0);
        h1 +%= read8To64(buf[0..], 8);
        h2 +%= read8To64(buf[0..], 16);
        h3 +%= read8To64(buf[0..], 24);
        h4 +%= read8To64(buf[0..], 32);
        h5 +%= read8To64(buf[0..], 40);
        h6 +%= read8To64(buf[0..], 48);
        h7 +%= read8To64(buf[0..], 56);
        h8 +%= read8To64(buf[0..], 64);
        h9 +%= read8To64(buf[0..], 72);
        h10 +%= read8To64(buf[0..], 80);
        h11 +%= read8To64(buf[0..], 88);

        endPartial(&h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);
        endPartial(&h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);
        endPartial(&h0, &h1, &h2, &h3, &h4, &h5, &h6, &h7, &h8, &h9, &h10, &h11);
        return .{ h0, h1 };
    }
}

pub fn spookyHash64(key: []const u8) u64 {
    const hash1, _ = spookyHash128(key);
    return @truncate(hash1);
}

pub fn spookyHash32(key: []const u8) u32 {
    const hash1, _ = spookyHash128(key);
    return @truncate(hash1);
}

const murc1: u32 = 0xCC9E2D51;
const murc2: u32 = 0x1B873593;

pub fn murmur3Hash32(key: []const u8) u32 {
    var h: u32 = 0;
    var bytesLeft: usize = key.len;
    var i: usize = 0;
    while (bytesLeft >= 4) : (bytesLeft -= 4) {
        var k: u32 = std.mem.readInt(u32, @ptrCast(key[i .. i + 4]), .little);
        k *%= murc1;
        k = rotl32(k, 15);
        k *%= murc2;
        h ^= k;
        h = rotl32(h, 13);
        h = (h *% 5) +% 0xe6546b64;
        i += 4;
    }

    if (bytesLeft > 0) {
        var j: u32 = toLittleEndian(u32, key[key.len - bytesLeft ..]);
        j *%= murc1;
        j = rotl32(j, 15);
        j *%= murc2;
        h ^= j;
    }

    h ^= @truncate(key.len);
    h ^= h >> 16;
    h *%= 0x85ebca6b;
    h ^= h >> 13;
    h *%= 0xc2b2ae35;
    h ^= h >> 16;
    return h;
}

// xxHash 64-bit prime constants (P1 - P5)
const xx64p1 = 11400714785074694791;
const xx64p2 = 14029467366897019727;
const xx64p3 = 1609587929392839161;
const xx64p4 = 9650029242287828579;
const xx64p5 = 2870177450012600261;

fn xxPass64(a: u64, k: u64) u64 {
    var acc: u64 = a;
    acc = acc +% k *% xx64p2;
    acc = rotl64(acc, 31);
    acc = acc *% xx64p1;
    return acc;
}

fn xxPass64Bytes(acc: u64, bytes: []const u8) u64 {
    const k: u64 = std.mem.readInt(u64, @ptrCast(bytes[0..]), .little);
    return xxPass64(acc, k);
}

fn xxPass32(a: u32, k: u32) u32 {
    var acc: u32 = a;
    acc = acc +% k *% xx32p2;
    acc = rotl32(acc, 13);
    acc = acc *% xx32p1;
    return acc;
}

fn xxPass32Bytes(acc: u32, bytes: []const u8) u32 {
    const k: u32 = std.mem.readInt(u32, @ptrCast(bytes[0..]), .little);
    return xxPass32(acc, k);
}

pub fn xxHash64(key: []const u8) u64 {
    var h: u64 = 0;
    const seed: u64 = 0;
    var bytesLeft = key.len;

    if (key.len >= 32) {
        // set-up all the accumulators
        var v1: u64 = seed +% xx64p1 +% xx64p2;
        var v2: u64 = seed +% xx64p2;
        var v3: u64 = seed +% 0;
        var v4: u64 = seed -% xx64p1;

        var i: usize = 0;
        while (bytesLeft >= 32) : (bytesLeft -= 32) {
            v1 = xxPass64Bytes(v1, key[i .. i + 8]);
            v2 = xxPass64Bytes(v2, key[i + 8 .. i + 16]);
            v3 = xxPass64Bytes(v3, key[i + 16 .. i + 24]);
            v4 = xxPass64Bytes(v4, key[i + 24 .. i + 32]);
            i += 32;
        }

        h = rotl64(v1, 1) +%
            rotl64(v2, 7) +%
            rotl64(v3, 12) +%
            rotl64(v4, 18);

        const accs: [4]u64 = .{ v1, v2, v3, v4 };
        for (accs) |acc| {
            h ^= xxPass64(0, acc);
            h *%= xx64p1;
            h +%= xx64p4;
        }
        bytesLeft = key.len - i;
    } else {
        h +%= seed +% xx64p5;
    }

    h +%= @truncate(key.len);
    if (bytesLeft > 0) {
        var start: usize = key.len - bytesLeft;

        while (bytesLeft >= 8) : (bytesLeft -= 8) {
            const k: u64 = xxPass64Bytes(0, key[start .. start + 8]);
            h ^= k;
            h = rotl64(h, 27) *% xx64p1;
            h +%= xx64p4;
            start += 8;
        }

        if (bytesLeft >= 4) {
            const k: u64 = toLittleEndian(u64, key[start .. start + 4]);
            h ^= (k *% xx64p1);
            h = rotl64(h, 23) *% xx64p2;
            h +%= xx64p3;
            start += 4;
            bytesLeft -= 4;
        }

        for (0..bytesLeft) |i| {
            const k: u64 = @intCast(key[start + i]);
            h ^= (k *% xx64p5);
            h = rotl64(h, 11) *% xx64p1;
        }
    }

    h ^= (h >> 33);
    h *%= xx64p2;
    h ^= (h >> 29);
    h *%= xx64p3;
    h ^= h >> 32;
    return h;
}

// xxHash 32-bit prime constants (P1 - P5)
const xx32p1: u32 = 2654435761;
const xx32p2: u32 = 2246822519;
const xx32p3: u32 = 3266489917;
const xx32p4: u32 = 668265263;
const xx32p5: u32 = 374761393;

pub fn xxHash32(key: []const u8) u32 {
    var h: u32 = 0;
    const seed: u32 = 0;
    var bytesLeft = key.len;

    if (key.len >= 16) {
        // set-up all the accumulators
        var v1: u32 = seed +% xx32p1 +% xx32p2;
        var v2: u32 = seed +% xx32p2;
        var v3: u32 = seed +% 0;
        var v4: u32 = seed -% xx32p1;

        var i: usize = 0;
        while (bytesLeft >= 16) : (bytesLeft -= 16) {
            v1 = xxPass32Bytes(v1, key[i .. i + 4]);
            v2 = xxPass32Bytes(v2, key[i + 4 .. i + 8]);
            v3 = xxPass32Bytes(v3, key[i + 8 .. i + 12]);
            v4 = xxPass32Bytes(v4, key[i + 12 .. i + 16]);
            i += 16;
        }

        h = rotl32(v1, 1) +%
            rotl32(v2, 7) +%
            rotl32(v3, 12) +%
            rotl32(v4, 18);

        bytesLeft = key.len - i;
    } else {
        h +%= seed +% xx32p5;
    }

    h +%= @truncate(key.len);
    if (bytesLeft > 0) {
        var start: usize = key.len - bytesLeft;

        while (bytesLeft >= 4) : (bytesLeft -= 4) {
            const k: u32 = toLittleEndian(u32, key[start .. start + 4]);
            h +%= k *% xx32p3;
            h = rotl32(h, 17) *% xx32p4;
            start += 4;
        }

        for (0..bytesLeft) |i| {
            const k: u32 = @intCast(key[start + i]);
            h +%= k *% xx32p5;
            h = rotl32(h, 11) *% xx32p1;
        }
    }

    h ^= (h >> 15);
    h *%= xx32p2;
    h ^= (h >> 13);
    h *%= xx32p3;
    h ^= h >> 16;
    return h;
}

const cityc1: u32 = 0xcc9e2d51;
const cityc2: u32 = 0x1b873593;

fn mur(a: u32, b: u32) u32 {
    var x: u32 = a;
    var y: u32 = b;
    x *%= cityc1;
    x = rotr32(x, 17);
    x *%= cityc2;
    y ^= x;
    y = rotr32(y, 19);
    return y *% 5 +% 0xe6546b64;
}

fn fmix(a: u32) u32 {
    var x: u32 = a;
    x ^= x >> 16;
    x *%= 0x85ebca6b;
    x ^= x >> 13;
    x *%= 0xc2b2ae35;
    x ^= x >> 16;
    return x;
}

fn read4To32(buffer: []const u8, start: usize) u32 {
    return std.mem.readInt(u32, @ptrCast(buffer[start .. start + 4]), .little);
}

fn read8To64(buffer: []const u8, start: usize) u64 {
    return std.mem.readInt(u64, @ptrCast(buffer[start .. start + 8]), .little);
}

pub fn cityHash32(key: []const u8) u32 {
    if (key.len <= 4) {
        var b: u32 = 0;
        var c: u32 = 9;

        for (0..key.len) |i| {
            const val: u32 = @intCast(key[i]);
            b = b *% cityc1 +% val;
            c ^= b;
        }

        const mur1 = mur(@truncate(key.len), c);
        const mur2 = mur(b, mur1);
        return fmix(mur2);
    } else if (key.len <= 12) {
        var a: u32 = @truncate(key.len);
        var b: u32 = a *% 5;
        var c: u32 = 9;
        const d: u32 = b;

        a +%= read4To32(key, 0);
        b +%= read4To32(key, key.len - 4);
        c +%= read4To32(key, (key.len >> 1) & 4);

        const mur1: u32 = mur(a, d);
        const mur2: u32 = mur(b, mur1);
        const mur3: u32 = mur(c, mur2);
        return fmix(mur3);
    } else if (key.len <= 24) {
        const a: u32 = read4To32(key, (key.len >> 1) - 4);
        const b: u32 = read4To32(key, 4);
        const c: u32 = read4To32(key, key.len - 8);
        const d: u32 = read4To32(key, key.len >> 1);
        const e: u32 = read4To32(key, 0);
        const f: u32 = read4To32(key, key.len - 4);
        const g: u32 = @truncate(key.len);

        const mur1: u32 = mur(a, g);
        const mur2: u32 = mur(b, mur1);
        const mur3: u32 = mur(c, mur2);
        const mur4: u32 = mur(d, mur3);
        const mur5: u32 = mur(e, mur4);
        const mur6: u32 = mur(f, mur5);
        return fmix(mur6);
    } else {
        var h: u32 = @truncate(key.len);
        var g: u32 = cityc1 *% h;
        var f: u32 = g;

        var a1: u32 = read4To32(key, key.len - 4);
        a1 = rotr32(a1 *% cityc1, 17) *% cityc2;

        var a2: u32 = read4To32(key, @truncate(key.len - 8));
        a2 = rotr32(a2 *% cityc1, 17) *% cityc2;

        var a3: u32 = read4To32(key, @truncate(key.len - 16));
        a3 = rotr32(a3 *% cityc1, 17) *% cityc2;

        var a4: u32 = read4To32(key, @truncate(key.len - 12));
        a4 = rotr32(a4 *% cityc1, 17) *% cityc2;

        var a5: u32 = read4To32(key, @truncate(key.len - 20));
        a5 = rotr32(a5 *% cityc1, 17) *% cityc2;

        h ^= a1;
        h = rotr32(h, 19);
        h = h *% 5 +% 0xe6546b64;
        h ^= a3;
        h = rotr32(h, 19);
        h = h *% 5 +% 0xe6546b64;
        g ^= a2;
        g = rotr32(g, 19);
        g = g *% 5 +% 0xe6546b64;
        g ^= a4;
        g = rotr32(g, 19);
        g = g *% 5 +% 0xe6546b64;
        f +%= a5;
        f = rotr32(f, 19);
        f = f *% 5 +% 0xe6546b64;

        var i: usize = 0;
        for (0..key.len / 20) |_| {
            const b1: u32 = rotr32(read4To32(key, i) *% cityc1, 17) *% cityc2;
            const b2: u32 = read4To32(key, i + 4);
            const b3: u32 = rotr32(read4To32(key, i + 8) *% cityc1, 17) *% cityc2;
            const b4: u32 = rotr32(read4To32(key, i + 12) *% cityc1, 17) *% cityc2;
            const b5: u32 = read4To32(key, i + 16);

            h ^= b1;
            h = rotr32(h, 18);
            h = h *% 5 +% 0xe6546b64;
            f +%= b2;
            f = rotr32(f, 19);
            f *%= cityc1;
            g +%= b3;
            g = rotr32(g, 18);
            g = g *% 5 +% 0xe6546b64;
            h ^= b4 +% b2;
            h = rotr32(h, 19);
            h = h *% 5 +% 0xe6546b64;
            g ^= b5;
            g = @byteSwap(g) *% 5;
            h +%= b5 *% 5;
            h = @byteSwap(h);
            f +%= b1;

            std.mem.swap(u32, &f, &h);
            std.mem.swap(u32, &f, &g);
            i += 20;
        }

        g = rotr32(g, 11) *% cityc1;
        g = rotr32(g, 17) *% cityc1;
        f = rotr32(f, 11) *% cityc1;
        f = rotr32(f, 17) *% cityc1;
        h = rotr32(h +% g, 19);
        h = h *% 5 +% 0xe6546b64;
        h = rotr32(h, 17) *% cityc1;
        h = rotr32(h +% f, 19);
        h = h *% 5 +% 0xe6546b64;
        h = rotr32(h, 17) *% cityc1;
        return h;
    }
}

const k0: u64 = 0xC3A5C85C97CB3127;
const k1: u64 = 0xB492B66FBE98F273;
const k2: u64 = 0x9AE16A3B2F90404F;

fn shiftMix(v: u64) u64 {
    return v ^ (v >> 47);
}

fn hashLen16(u: u64, v: u64, mul: u64) u64 {
    var a: u64 = (u ^ v) *% mul;
    a ^= (a >> 47);
    var b: u64 = (v ^ a) *% mul;
    b ^= (b >> 47);
    b *%= mul;
    return b;
}

fn hashLen16From128(x: u64, y: u64) u64 {
    const kMul: u64 = 0x9ddfea08eb382d69;
    var a: u64 = (x ^ y) *% kMul;
    a ^= (a >> 47);
    var b: u64 = (y ^ a) *% kMul;
    b ^= (b >> 47);
    b *%= kMul;
    return b;
}

fn weakHashLen32(key: []const u8, a: u64, b: u64) struct { u64, u64 } {
    const f: u64 = read8To64(key, 0);
    const g: u64 = read8To64(key, 8);
    const h: u64 = read8To64(key, 16);
    const i: u64 = read8To64(key, 24);
    var x: u64 = a;
    var y: u64 = b;
    x +%= f;
    y = rotr64(y +% x +% i, 21);
    const c: u64 = x;
    x +%= g;
    x +%= h;
    y +%= rotr64(x, 44);
    return .{ x +% i, y +% c };
}

pub fn cityHash64(key: []const u8) u64 {
    if (key.len <= 16) {
        if (key.len >= 8) {
            const mul: u64 = k2 +% key.len *% 2;
            const a: u64 = read8To64(key, 0) +% k2;
            const b: u64 = read8To64(key, key.len - 8);
            const c: u64 = rotr64(b, 37) *% mul +% a;
            const d: u64 = (rotr64(a, 25) +% b) *% mul;
            return hashLen16(c, d, mul);
        } else if (key.len >= 4) {
            const mul: u64 = k2 +% key.len *% 2;
            const a: u64 = read4To32(key, 0);

            const u: u64 = key.len +% (a << 3);
            const v: u64 = read4To32(key, key.len - 4);
            return hashLen16(u, v, mul);
        } else if (key.len > 0) {
            const a: u32 = @intCast(key[0]);
            const b: u32 = @intCast(key[key.len >> 1]);
            const c: u32 = @intCast(key[key.len - 1]);
            const y: u32 = a +% (b << 8);
            const z: u32 = @truncate(key.len +% (c << 2));
            return shiftMix(y *% k2 ^ z *% k0) *% k2;
        } else {
            return k2;
        }
    } else if (key.len <= 32) {
        const mul: u64 = k2 +% key.len *% 2;
        const a: u64 = read8To64(key, 0) *% k1;
        const b: u64 = read8To64(key, 8);
        const c: u64 = read8To64(key, key.len - 8) *% mul;
        const d: u64 = read8To64(key, key.len - 16) *% k2;

        const u: u64 = rotr64(a +% b, 43) +% rotr64(c, 30) +% d;
        const v: u64 = a +% rotr64(b +% k2, 18) +% c;
        return hashLen16(u, v, mul);
    } else if (key.len <= 64) {
        const mul: u64 = k2 +% key.len *% 2;
        var a: u64 = read8To64(key, 0) *% k2;
        var b: u64 = read8To64(key, 8);
        const c: u64 = read8To64(key, key.len - 24);
        const d: u64 = read8To64(key, key.len - 32);
        const e: u64 = read8To64(key, 16) *% k2;
        const f: u64 = read8To64(key, 24) *% 9;
        const g: u64 = read8To64(key, key.len - 8);
        const h: u64 = read8To64(key, key.len - 16) *% mul;
        const u: u64 = rotr64(a +% g, 43) +% (rotr64(b, 30) +% c) *% 9;
        const v: u64 = ((a +% g) ^ d) +% f +% 1;
        const w: u64 = @byteSwap((u +% v) *% mul) +% h;
        const x: u64 = rotr64(e +% f, 42) +% c;
        const y: u64 = (@byteSwap((v +% w) *% mul) +% g) *% mul;
        const z: u64 = e +% f +% c;
        a = @byteSwap((x +% z) *% mul +% y) +% b;
        b = shiftMix((z +% a) *% mul +% d +% h) *% mul;
        return b +% x;
    } else {
        var x: u64 = read8To64(key, key.len - 40);
        var y: u64 = read8To64(key, key.len - 16) +% read8To64(
            key,
            key.len - 56,
        );
        var z: u64 = hashLen16From128(
            read8To64(key, key.len - 48) +% key.len,
            read8To64(key, key.len - 24),
        );

        var vWeakHash = weakHashLen32(key[key.len - 64 ..], key.len, z);
        var v1: u64 = vWeakHash[0];
        var v2: u64 = vWeakHash[1];

        var wWeakHash = weakHashLen32(key[key.len - 32 ..], y +% k1, x);
        var w1: u64 = wWeakHash[0];
        var w2: u64 = wWeakHash[1];

        x = x *% k1 +% read8To64(key, 0);

        var i: usize = 0;
        for (0..key.len / 64) |_| {
            x = rotr64(x +% y +% v1 +% read8To64(key, i + 8), 37) *% k1;
            y = rotr64(y +% v2 +% read8To64(key, i + 48), 42) *% k1;
            x ^= w2;
            y +%= v1 +% read8To64(key, i + 40);
            z = rotr64(z +% w1, 33) *% k1;

            vWeakHash = weakHashLen32(key, v2 *% k1, x +% w1);
            v1 = vWeakHash[0];
            v2 = vWeakHash[1];

            wWeakHash = weakHashLen32(
                key[i + 32 ..],
                z +% w2,
                y +% read8To64(key, i + 16),
            );
            w1 = wWeakHash[0];
            w2 = wWeakHash[1];
            std.mem.swap(u64, &z, &x);

            i += 64;
        }
        const fh = hashLen16From128(v1, w1);
        const sh = hashLen16From128(v2, w2);
        return hashLen16From128(fh +% shiftMix(y) *% k1 +% z, sh +% x);
    }
}

test "32-bit hash equals" {
    const tests = [_]struct {
        key: []const u8,
        hash: u32,
        hasher: *const fn (key: []const u8) u32,
    }{
        .{
            .key = "",
            .hash = 2166136261,
            .hasher = fnv1aHash32,
        },
        .{
            .key = "Spam",
            .hash = 2829595432,
            .hasher = fnv1aHash32,
        },
        .{
            .key = "FNV1a32",
            .hash = 1071197150,
            .hasher = fnv1aHash32,
        },
        .{
            .key = "abcdefghijklmnopqrstuvwxyz0123456789",
            .hash = 1981843661,
            .hasher = fnv1aHash32,
        },
        .{
            .key = &[_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 },
            .hash = 797261938,
            .hasher = fnv1aHash32,
        },
        .{
            .key = "",
            .hash = 0,
            .hasher = murmur3Hash32,
        },
        .{
            .key = "hello",
            .hash = 613153351,
            .hasher = murmur3Hash32,
        },
        .{
            .key = "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF",
            .hash = 673109539,
            .hasher = murmur3Hash32,
        },
        .{
            .key = "",
            .hash = 46947589,
            .hasher = xxHash32,
        },
        .{
            .key = &[_]u8{ 0x9E, 0xFF, 0x1F, 0x4B, 0x5E, 0x53, 0x2F, 0xDD, 0xB5 },
            .hash = 3945165279,
            .hasher = xxHash32,
        },
        .{
            .key = "0123456789ABCDEFGHIJKLMNOPQRefghijklmnopqrstuvwxyzs",
            .hash = 315866898,
            .hasher = xxHash32,
        },
        .{
            .key = "",
            .hash = 3696677242,
            .hasher = cityHash32,
        },
        .{
            .key = "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            .hash = 3701358904,
            .hasher = cityHash32,
        },
        .{
            .key = "abcdefghijklmn",
            .hash = 2676528814,
            .hasher = cityHash32,
        },
        .{
            .key = "",
            .hash = 3735928559,
            .hasher = jenkinsLookup3,
        },
        .{
            .key = "",
            .hash = 1811220761,
            .hasher = spookyHash32,
        },
        .{
            .key = "foobar",
            .hash = 65920665,
            .hasher = spookyHash32,
        },
        .{
            .key = "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTU",
            .hash = 1804443105,
            .hasher = spookyHash32,
        },
        .{
            .key = "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQ",
            .hash = 3453064038,
            .hasher = spookyHash32,
        },
        .{
            .key = "Hi",
            .hash = 1178407427,
            .hasher = spookyHash32,
        },
        .{
            .key = "testinput",
            .hash = 842918276,
            .hasher = spookyHash32,
        },
        .{
            .key = "1234567890-abcdefghijklmnopqrstuvwxyz-A",
            .hash = 2798250829,
            .hasher = spookyHash32,
        },
        .{
            .key = "Zig-and-Rust-and-Go-Integration-202",
            .hash = 3371096965,
            .hasher = spookyHash32,
        },
        .{
            .key = "ABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABABAB",
            .hash = 4047240521,
            .hasher = spookyHash32,
        },
        .{
            .key = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
            .hash = 3433483701,
            .hasher = spookyHash32,
        },
        .{
            .key = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ++
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ++
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ++
                "AAAAAAAAAAAA",
            .hash = 1669341740,
            .hasher = spookyHash32,
        },
        .{
            .key = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ++
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ++
                "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ++
                "AAAAAAAAAAAABBBBBBBB",
            .hash = 2577041638,
            .hasher = spookyHash32,
        },
    };

    for (tests) |hashTest| {
        const hash: u32 = hashTest.hasher(hashTest.key);
        try std.testing.expectEqual(hashTest.hash, hash);
    }
}

test "64-bit hash equals" {
    const tests = [_]struct {
        key: []const u8,
        hash: u64,
        hasher: *const fn (key: []const u8) u64,
    }{
        .{
            .key = "",
            .hash = 14695981039346656037,
            .hasher = fnv1aHash64,
        },
        .{
            .key = "a",
            .hash = 12638187200555641996,
            .hasher = fnv1aHash64,
        },
        .{
            .key = "FNV1a64",
            .hash = 11445829140922082009,
            .hasher = fnv1aHash64,
        },
        .{
            .key = "The quick brown fox jumps over the lazy dog",
            .hash = 17580284887202820368,
            .hasher = fnv1aHash64,
        },
        .{
            .key = &[_]u8{ 0x00, 0xFF, 0x10, 0x20, 0x30 },
            .hash = 1421577967308416032,
            .hasher = fnv1aHash64,
        },
        .{
            .key = "",
            .hash = 17241709254077376921,
            .hasher = xxHash64,
        },
        .{
            .key = "asdf",
            .hash = 4708639809588864798,
            .hasher = xxHash64,
        },
        .{
            .key = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
            .hash = 17321129452528567775,
            .hasher = xxHash64,
        },
        .{
            .key = "",
            .hash = 11160318154034397263,
            .hasher = cityHash64,
        },
        .{
            .key = "a93jAbkjj",
            .hash = 16340543126167916629,
            .hasher = cityHash64,
        },
        .{
            .key = "\xff\xee\xdd\xcc",
            .hash = 2883375492416478063,
            .hasher = cityHash64,
        },
        .{
            .key = "",
            .hash = 2533000996631939353,
            .hasher = spookyHash64,
        },
        .{
            .key = "ABC123",
            .hash = 7422541954525714374,
            .hasher = spookyHash64,
        },
        .{
            .key = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXY1234567890ABCDE",
            .hash = 14414801508010396549,
            .hasher = spookyHash64,
        },
        .{
            .key = "HELLOWORLDABCDEFGHIJKL1234567890MNOPQ",
            .hash = 17083147413736147347,
            .hasher = spookyHash64,
        },
        .{
            .key = "XY",
            .hash = 4350368303415703306,
            .hasher = spookyHash64,
        },
        .{
            .key = "ZigRustGo",
            .hash = 5870813825580372420,
            .hasher = spookyHash64,
        },
        .{
            .key = "Test-Case-Input-For-SpookyHash-XYZ-12345",
            .hash = 2793878970131685276,
            .hasher = spookyHash64,
        },
        .{
            .key = "Integration-Test-String-Example-1234",
            .hash = 9418471063303507045,
            .hasher = spookyHash64,
        },
        .{
            .key = "ABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCD",
            .hash = 9463967066173872020,
            .hasher = spookyHash64,
        },
        .{
            .key = "PatternXPatternXPatternXPatternXPatternXPatternXPatternXPatternXP",
            .hash = 12552504793583828975,
            .hasher = spookyHash64,
        },
        .{
            .key = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ++
                "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB" ++
                "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC",
            .hash = 7095554170450427737,
            .hasher = spookyHash64,
        },
        .{
            .key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" ++
                "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY" ++
                "YYYYYYYYYYYYYYYYYYYZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ",
            .hash = 6224377824603928185,
            .hasher = spookyHash64,
        },
    };

    for (tests) |hashTest| {
        const hash: u64 = hashTest.hasher(hashTest.key);
        try std.testing.expectEqual(hashTest.hash, hash);
    }
}
