// Copyright (c) 2013-present, the authors of the Pointy Castle project
// This library is dually licensed under LGPL 3 and MPL 2.0.
// See file LICENSE for more information.

library pointycastle.src.utils;

import "dart:typed_data";

var _negOne = BigInt.from(-1);
var _negOneArray = Uint8List.fromList([0xff]);
final _zeroList = Uint8List.fromList([0]);
final _b256 = BigInt.from(256);
final _minusOne = BigInt.from(-1);

void _twosComplement(Uint8List result) {
  var carry = 1;
  for (int j = result.length - 1; j >= 0; --j) {
// flip the bits
    result[j] ^= 0xFF;

    if (result[j] == 255 && carry == 1) {
// overflow
      result[j] = 0;
      carry = 1;
    } else {
      result[j] += carry;
      carry = 0;
    }
  }
  result[0] = result[0] | 0x80;
}

BigInt decodeBigInt(Uint8List bytes) {
  var isNegative = (bytes[0] & 0x80) != 0;
  var result = BigInt.zero;
  for (int i = 0; i < bytes.length; ++i) {
    result = result << 8;
    var x = isNegative ? (bytes[i] ^ 0xff) : bytes[i];
    result += BigInt.from(x);
  }
  if (isNegative) return (result + BigInt.one) * _minusOne;

  return result;
}

Uint8List encodeBigInt(BigInt number) {
  var orig = number;

  if (number.bitLength == 0) {
    if (number == _negOne) {
      return _negOneArray;
    } else {
      return _zeroList;
    }
  }
  // we may need one extra byte for padding
  var bytes = (number.bitLength / 8).ceil() + 1;
  var result = Uint8List(bytes);

  number = number.abs();
  for (int i = 0, j = bytes - 1; i < (bytes); i++, --j) {
    var x = number.remainder(_b256).toInt();
    result[j] = x;
    number = number >> 8;
  }

  if (orig.isNegative) {
    _twosComplement(result);
    if ((result[1] & 0x80) == 0x80) {
      // high order bit is a one - we don't need pad
      return result.sublist(1);
    }
  } else {
    if ((result[1] & 0x80) != 0x80) {
      // hi order bit is a 0, we dont need pad
      return result.sublist(1);
    }
  }
  return result;
}
