import 'dart:io';
import 'package:image/image.dart';

void main() {
  final image = Image(width: 512, height: 512);
  
  // Fill with transparent background
  fill(image, color: ColorRgba8(0, 0, 0, 0));
  
  // The SVG viewBox is 344x464.
  // Center it in a 512x512 image.
  // offsetX = (512 - 344) / 2 = 84
  // offsetY = (512 - 464) / 2 = 24
  
  int offsetX = 84;
  int offsetY = 24;
  int size = 104;
  
  final positions = [
    [0, 0],
    [0, 120],
    [0, 240],
    [0, 360],
    [120, 0],
    [120, 240],
    [240, 120],
    [240, 360]
  ];
  
  for (var pos in positions) {
    int x1 = offsetX + pos[0];
    int y1 = offsetY + pos[1];
    int x2 = x1 + size - 1;
    int y2 = y1 + size - 1;
    
    fillRect(image, x1: x1, y1: y1, x2: x2, y2: y2, color: ColorRgba8(255, 255, 255, 255));
  }
  
  final png = encodePng(image);
  File('assets/rakoda-white.png').writeAsBytesSync(png);
  print('Generated rakoda-white.png successfully.');
}
