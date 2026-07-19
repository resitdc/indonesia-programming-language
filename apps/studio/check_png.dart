import 'dart:io';
import 'package:image/image.dart';

void main() {
  final bytes = File('assets/rakoda-white.png').readAsBytesSync();
  final image = decodeImage(bytes);
  if (image == null) {
    print('Failed to decode');
    return;
  }
  print('Size: ${image.width} x ${image.height}');
  int white = 0;
  int transp = 0;
  int other = 0;
  for (final p in image) {
    if (p.a == 0) {
      transp++;
    } else if (p.r == 255 && p.g == 255 && p.b == 255) {
      white++;
    } else {
      other++;
    }
  }
  print('Transparent: $transp, White: $white, Other: $other');
}
