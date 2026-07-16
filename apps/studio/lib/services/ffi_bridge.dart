import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

/// FFI bindings to RPL Core native library.
class RplCore {
  static RplCore? _instance;
  late final DynamicLibrary _lib;

  // FFI function signatures
  late final Pointer<Utf8> Function() _version;
  late final Pointer<Utf8> Function(Pointer<Utf8>) _execute;
  late final void Function(Pointer<Utf8>) _freeString;

  RplCore._() {
    _lib = _loadLibrary();
    _version = _lib
        .lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
          'rpl_version',
        );
    _execute = _lib
        .lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>),
          Pointer<Utf8> Function(Pointer<Utf8>)
        >('rpl_execute');
    _freeString = _lib
        .lookupFunction<
          Void Function(Pointer<Utf8>),
          void Function(Pointer<Utf8>)
        >('rpl_free_string');
  }

  static RplCore get instance {
    _instance ??= RplCore._();
    return _instance!;
  }

  /// Load the native library based on platform.
  static DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('librpl_studio_core.so');
    } else if (Platform.isIOS || Platform.isMacOS) {
      return DynamicLibrary.open(
        'libflutter_rust_bridge.framework/libflutter_rust_bridge',
      );
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('rpl_studio_core.dll');
    } else {
      // Linux
      return DynamicLibrary.open('librpl_studio_core.so');
    }
  }

  /// Get RPL version string.
  String version() {
    final ptr = _version();
    final result = ptr.toDartString();
    _freeString(ptr);
    return result;
  }

  /// Execute RPL code and return output.
  /// Returns Map with either {"ok": output} or {"error": message}.
  Map<String, String> execute(String code) {
    final codePtr = code.toNativeUtf8();
    final resultPtr = _execute(codePtr);
    calloc.free(codePtr);

    final resultStr = resultPtr.toDartString();
    _freeString(resultPtr);

    // Parse JSON-like result
    if (resultStr.startsWith('{"ok":')) {
      final output = resultStr.substring(7, resultStr.length - 2);
      return {'ok': output};
    } else if (resultStr.startsWith('{"error":')) {
      final error = resultStr.substring(10, resultStr.length - 2);
      return {'error': error};
    }

    return {'error': resultStr};
  }
}
