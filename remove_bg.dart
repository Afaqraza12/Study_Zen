import 'dart:io';
import 'package:image/image.dart';

void main() {
  print('Loading image...');
  final inputBytes = File('assets/logo.png').readAsBytesSync();
  final image = decodeImage(inputBytes);
  
  if (image == null) {
    print('Failed to load image.');
    return;
  }
  
  print('Processing pixels...');
  // The background is dark. Let's make anything very dark (R,G,B < 40) transparent.
  // Also we can use anti-aliasing feathering by adjusting alpha based on brightness.
  for (var p in image) {
    // p is a Pixel
    final r = p.r;
    final g = p.g;
    final b = p.b;
    
    // Calculate brightness
    final brightness = (r + g + b) / 3;
    
    if (brightness < 20) {
      p.a = 0; // Fully transparent
    } else if (brightness < 45) {
      // Semi-transparent for smooth edges
      p.a = ((brightness - 20) / 25 * 255).round();
    }
  }
  
  print('Saving image...');
  File('assets/logo_transparent.png').writeAsBytesSync(encodePng(image));
  print('Background removed successfully and saved to assets/logo_transparent.png!');
}
