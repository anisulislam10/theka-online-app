import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Global in-memory cache for storage paths to avoid re-fetching on every scroll frame
final Map<String, Uint8List> _secureImageCache = {};

class SecureFirebaseImage extends StatefulWidget {
  final String pathOrUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  const SecureFirebaseImage({
    super.key,
    required this.pathOrUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<SecureFirebaseImage> createState() => _SecureFirebaseImageState();
}

class _SecureFirebaseImageState extends State<SecureFirebaseImage> {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(SecureFirebaseImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pathOrUrl != widget.pathOrUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final path = widget.pathOrUrl;

    if (path.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    // If it's a standard URL, CachedNetworkImage will handle it in build()
    if (path.startsWith('http://') || path.startsWith('https://')) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    // It is a Firebase Storage Path
    if (_secureImageCache.containsKey(path)) {
      if (mounted) {
        setState(() {
          _imageData = _secureImageCache[path];
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final ref = FirebaseStorage.instance.ref(path);
      // Limit to 5MB to prevent memory crash on very large images
      final Uint8List? data = await ref.getData(5 * 1024 * 1024);

      if (data != null) {
        _secureImageCache[path] = data; // Cache it
        if (mounted) {
          setState(() {
            _imageData = data;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        throw Exception("No data returned");
      }
    } catch (e) {
      debugPrint("❌ SecureFirebaseImage loading error for \$path: \$e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pathOrUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    if (widget.pathOrUrl.startsWith('http://') || widget.pathOrUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: widget.pathOrUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: widget.placeholder ?? (context, url) => _buildPlaceholder(),
        errorWidget: widget.errorWidget ?? (context, url, err) => _buildErrorWidget(context),
      );
    }

    if (_isLoading) {
      return widget.placeholder != null
          ? widget.placeholder!(context, widget.pathOrUrl)
          : _buildPlaceholder();
    }

    if (_hasError || _imageData == null) {
      return widget.errorWidget != null
          ? widget.errorWidget!(context, widget.pathOrUrl, "Error loading image")
          : _buildErrorWidget(context);
    }

    return Image.memory(
      _imageData!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) =>
          widget.errorWidget != null
              ? widget.errorWidget!(context, widget.pathOrUrl, error)
              : _buildErrorWidget(context),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
