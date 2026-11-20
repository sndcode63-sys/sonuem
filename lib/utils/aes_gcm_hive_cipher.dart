import 'dart:math';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';

class AesGcmHiveCipher implements HiveCipher {
  static final _rng = Random.secure();

  final List<int> _keyBytes;

  AesGcmHiveCipher(this._keyBytes);

  @override
  int calculateKeyCrc() {
    var crc = 0;
    for (final byte in _keyBytes) {
      crc = (crc + byte) & 0xFFFFFFFF;
    }
    return crc;
  }

  @override
  int maxEncryptedSize(Uint8List inp) {
    return 12 + 16 + inp.length;
  }

  @override
  int encrypt(Uint8List inp, int inpOff, int inpLength, Uint8List out, int outOff) {
    final plaintext = inp.sublist(inpOff, inpOff + inpLength);
    final encrypted = _encryptSync(plaintext);
    out.setRange(outOff, outOff + encrypted.length, encrypted);
    return encrypted.length;
  }

  @override
  int decrypt(Uint8List inp, int inpOff, int inpLength, Uint8List out, int outOff) {
    final cipherBytes = inp.sublist(inpOff, inpOff + inpLength);
    final decrypted = _decryptSync(cipherBytes);
    out.setRange(outOff, outOff + decrypted.length, decrypted);
    return decrypted.length;
  }

  Uint8List _encryptSync(Uint8List plaintext) {
    final nonce = Uint8List(12);
    for (var i = 0; i < 12; i++) {
      nonce[i] = _rng.nextInt(256);
    }


    final result = _aesGcmEncryptSync(plaintext, nonce);

    final out = Uint8List(12 + 16 + result.ciphertext.length);
    out.setRange(0, 12, nonce);
    out.setRange(12, 28, result.tag);
    out.setRange(28, 28 + result.ciphertext.length, result.ciphertext);
    return out;
  }

  Uint8List _decryptSync(Uint8List data) {
    if (data.length < 28) throw HiveError('Invalid AES-GCM ciphertext: too short');

    final nonce = data.sublist(0, 12);
    final tag = data.sublist(12, 28);
    final ciphertext = data.sublist(28);

    return _aesGcmDecryptSync(ciphertext, nonce, tag);
  }


  _GcmResult _aesGcmEncryptSync(Uint8List plaintext, Uint8List nonce) {
    final key = Uint8List.fromList(_keyBytes);

    final ciphertext = _aesCtr(key, nonce, plaintext);

    final tag = _ghash(key, nonce, ciphertext, plaintext.length);

    return _GcmResult(ciphertext, tag);
  }

  Uint8List _aesGcmDecryptSync(Uint8List ciphertext, Uint8List nonce, Uint8List tag) {
    final key = Uint8List.fromList(_keyBytes);

    final expectedTag = _ghash(key, nonce, ciphertext, ciphertext.length);
    if (!_constantTimeEqual(tag, expectedTag)) {
      throw HiveError('AES-GCM: Authentication tag mismatch — data tampered or wrong key');
    }

    return _aesCtr(key, nonce, ciphertext);
  }

  // ─── AES block cipher
  static const _sbox = [
    0x63,0x7c,0x77,0x7b,0xf2,0x6b,0x6f,0xc5,0x30,0x01,0x67,0x2b,0xfe,0xd7,0xab,0x76,
    0xca,0x82,0xc9,0x7d,0xfa,0x59,0x47,0xf0,0xad,0xd4,0xa2,0xaf,0x9c,0xa4,0x72,0xc0,
    0xb7,0xfd,0x93,0x26,0x36,0x3f,0xf7,0xcc,0x34,0xa5,0xe5,0xf1,0x71,0xd8,0x31,0x15,
    0x04,0xc7,0x23,0xc3,0x18,0x96,0x05,0x9a,0x07,0x12,0x80,0xe2,0xeb,0x27,0xb2,0x75,
    0x09,0x83,0x2c,0x1a,0x1b,0x6e,0x5a,0xa0,0x52,0x3b,0xd6,0xb3,0x29,0xe3,0x2f,0x84,
    0x53,0xd1,0x00,0xed,0x20,0xfc,0xb1,0x5b,0x6a,0xcb,0xbe,0x39,0x4a,0x4c,0x58,0xcf,
    0xd0,0xef,0xaa,0xfb,0x43,0x4d,0x33,0x85,0x45,0xf9,0x02,0x7f,0x50,0x3c,0x9f,0xa8,
    0x51,0xa3,0x40,0x8f,0x92,0x9d,0x38,0xf5,0xbc,0xb6,0xda,0x21,0x10,0xff,0xf3,0xd2,
    0xcd,0x0c,0x13,0xec,0x5f,0x97,0x44,0x17,0xc4,0xa7,0x7e,0x3d,0x64,0x5d,0x19,0x73,
    0x60,0x81,0x4f,0xdc,0x22,0x2a,0x90,0x88,0x46,0xee,0xb8,0x14,0xde,0x5e,0x0b,0xdb,
    0xe0,0x32,0x3a,0x0a,0x49,0x06,0x24,0x5c,0xc2,0xd3,0xac,0x62,0x91,0x95,0xe4,0x79,
    0xe7,0xc8,0x37,0x6d,0x8d,0xd5,0x4e,0xa9,0x6c,0x56,0xf4,0xea,0x65,0x7a,0xae,0x08,
    0xba,0x78,0x25,0x2e,0x1c,0xa6,0xb4,0xc6,0xe8,0xdd,0x74,0x1f,0x4b,0xbd,0x8b,0x8a,
    0x70,0x3e,0xb5,0x66,0x48,0x03,0xf6,0x0e,0x61,0x35,0x57,0xb9,0x86,0xc1,0x1d,0x9e,
    0xe1,0xf8,0x98,0x11,0x69,0xd9,0x8e,0x94,0x9b,0x1e,0x87,0xe9,0xce,0x55,0x28,0xdf,
    0x8c,0xa1,0x89,0x0d,0xbf,0xe6,0x42,0x68,0x41,0x99,0x2d,0x0f,0xb0,0x54,0xbb,0x16,
  ];

  static const _rcon = [
    0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0x1b,0x36,0x6c,0xd8,0xab,0x4d,0x9a,
  ];

  static List<Uint8List> _keyExpand(Uint8List key) {
    final w = List<List<int>>.generate(60, (_) => List<int>.filled(4, 0));
    for (var i = 0; i < 8; i++) {
      w[i] = [key[4*i], key[4*i+1], key[4*i+2], key[4*i+3]];
    }
    for (var i = 8; i < 60; i++) {
      var temp = List<int>.from(w[i-1]);
      if (i % 8 == 0) {
        temp = [_sbox[temp[1]]^_rcon[(i~/8)-1], _sbox[temp[2]], _sbox[temp[3]], _sbox[temp[0]]];
      } else if (i % 8 == 4) {
        temp = [_sbox[temp[0]], _sbox[temp[1]], _sbox[temp[2]], _sbox[temp[3]]];
      }
      w[i] = [w[i-8][0]^temp[0], w[i-8][1]^temp[1], w[i-8][2]^temp[2], w[i-8][3]^temp[3]];
    }
    return List.generate(15, (r) {
      final rk = Uint8List(16);
      for (var i = 0; i < 4; i++) {
        for (var j = 0; j < 4; j++) {
          rk[4*i+j] = w[4*r+i][j];
        }
      }
      return rk;
    });
  }

  static int _xtime(int a) => ((a << 1) ^ ((a & 0x80) != 0 ? 0x1b : 0)) & 0xff;

  static Uint8List _aesBlock(Uint8List key, Uint8List block) {
    final rk = _keyExpand(key);
    final s = Uint8List.fromList(block);

    // Initial round key addition
    for (var i = 0; i < 16; i++) {
      s[i] ^= rk[0][i];
    }

    for (var round = 1; round <= 14; round++) {
      // SubBytes
      for (var i = 0; i < 16; i++) {
        s[i] = _sbox[s[i]];
      }
      // ShiftRows
      final t = Uint8List.fromList(s);
      s[1]=t[5]; s[5]=t[9]; s[9]=t[13]; s[13]=t[1];
      s[2]=t[10]; s[6]=t[14]; s[10]=t[2]; s[14]=t[6];
      s[3]=t[15]; s[7]=t[3]; s[11]=t[7]; s[15]=t[11];
      if (round < 14) {
        for (var c = 0; c < 4; c++) {
          final a = s.sublist(4*c, 4*c+4);
          s[4*c]   = _xtime(a[0]) ^ (_xtime(a[1])^a[1]) ^ a[2] ^ a[3];
          s[4*c+1] = a[0] ^ _xtime(a[1]) ^ (_xtime(a[2])^a[2]) ^ a[3];
          s[4*c+2] = a[0] ^ a[1] ^ _xtime(a[2]) ^ (_xtime(a[3])^a[3]);
          s[4*c+3] = (_xtime(a[0])^a[0]) ^ a[1] ^ a[2] ^ _xtime(a[3]);
        }
      }
      // AddRoundKey
      for (var i = 0; i < 16; i++) {
        s[i] ^= rk[round][i];
      }
    }
    return s;
  }

  Uint8List _aesCtr(Uint8List key, Uint8List nonce, Uint8List data) {
    final out = Uint8List(data.length);
    // J0 = nonce || 0x00000001
    final counter = Uint8List(16)
      ..setRange(0, 12, nonce)
      ..[15] = 2;

    var pos = 0;
    while (pos < data.length) {
      final keystream = _aesBlock(key, counter);
      final chunkLen = (data.length - pos).clamp(0, 16);
      for (var i = 0; i < chunkLen; i++) {
        out[pos + i] = data[pos + i] ^ keystream[i];
      }
      pos += chunkLen;
      for (var i = 15; i >= 12; i--) {
        counter[i] = (counter[i] + 1) & 0xff;
        if (counter[i] != 0) break;
      }
    }
    return out;
  }

  Uint8List _ghash(Uint8List key, Uint8List nonce, Uint8List ciphertext, int plainLen) {
    // H = AES(key, 0^128)
    final h = _aesBlock(key, Uint8List(16));


    final j0 = Uint8List(16)..setRange(0, 12, nonce)..[15] = 1;
    final encJ0 = _aesBlock(key, j0);

    var x = Uint8List(16);
    x = _ghashUpdate(x, h, ciphertext);

    final lenBlock = Uint8List(16);
    final ctBits = ciphertext.length * 8;
    for (var i = 0; i < 8; i++) {
      lenBlock[15 - i] = (ctBits >> (8 * i)) & 0xff;
    }
    x = _ghashUpdate(x, h, lenBlock);

    final tag = Uint8List(16);
    for (var i = 0; i < 16; i++) tag[i] = x[i] ^ encJ0[i];
    return tag;
  }

  Uint8List _ghashUpdate(Uint8List x, Uint8List h, Uint8List data) {
    final padded = _padTo16(data);
    for (var i = 0; i < padded.length; i += 16) {
      final block = padded.sublist(i, i + 16);
      for (var j = 0; j < 16; j++) {
        x[j] ^= block[j];
      }
      x = _gfMul(x, h);
    }
    return x;
  }

  static Uint8List _padTo16(Uint8List data) {
    if (data.length % 16 == 0) return data;
    final padded = Uint8List(((data.length + 15) ~/ 16) * 16);
    padded.setRange(0, data.length, data);
    return padded;
  }

  static Uint8List _gfMul(Uint8List x, Uint8List y) {
    final z = Uint8List(16);
    final v = Uint8List.fromList(y);
    for (var i = 0; i < 128; i++) {
      if ((x[i >> 3] >> (7 - (i & 7))) & 1 == 1) {
        for (var j = 0; j < 16; j++) z[j] ^= v[j];
      }
      final lsb = v[15] & 1;
      _shiftRight(v);
      if (lsb == 1) v[0] ^= 0xe1;
    }
    return z;
  }

  static void _shiftRight(Uint8List v) {
    for (var i = 15; i > 0; i--) {
      v[i] = ((v[i] >> 1) | ((v[i-1] & 1) << 7)) & 0xff;
    }
    v[0] >>= 1;
  }

  static bool _constantTimeEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) result |= a[i] ^ b[i];
    return result == 0;
  }
}

class _GcmResult {
  final Uint8List ciphertext;
  final Uint8List tag;
  _GcmResult(this.ciphertext, this.tag);
}
