import 'package:material_ui/material_ui.dart';

import '../../game/cats/cat_breed.dart';

/// One frame of a cat sprite sheet. Sheets are [frames] square cells laid out
/// side by side; this crops out cell [frame]. Use it everywhere a cat is drawn
/// with Flutter widgets so cropping never drifts between screens.
class CatSprite extends StatefulWidget {
  const CatSprite({
    super.key,
    required this.type,
    this.action = 'idle',
    this.frames = 6,
    this.frame = 0,
    this.flip = false,
    this.size = 80,
  });

  final String type;

  /// Sheet name, e.g. "idle", "walk", "drop-success".
  final String action;
  final int frames;
  final int frame;
  final bool flip;
  final double size;

  static int decodeHeight(double size, double pixelRatio) =>
      ((size * pixelRatio) / 64).ceil().clamp(1, 1 << 20) * 64;

  static ImageProvider _provider(String type, String action, int height) =>
      ResizeImage.resizeIfNeeded(null, height,
          AssetImage('assets/images/${CatBreed.of(type).sheet(action)}'));

  /// Match live decode buckets exactly; warm only the chosen cat's sheets.
  static Future<void> precacheActions(BuildContext context,
      {required String type,
      required Iterable<String> actions,
      required Iterable<double> sizes}) async {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final heights = sizes.map((s) => decodeHeight(s, ratio)).toSet();
    for (final height in heights) {
      for (final action in actions) {
        if (!context.mounted) return;
        await precacheImage(_provider(type, action, height), context,
            onError: (_, __) {});
      }
    }
  }

  @override
  State<CatSprite> createState() => _CatSpriteState();
}

class _CatSpriteState extends State<CatSprite> {
  ImageProvider? _requested, _displayed;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _image;
  int _shownFrames = 1, _shownFrame = 0;
  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(CatSprite old) {
    super.didUpdateWidget(old);
    _resolve();
  }

  void _release(ImageInfo? info) {
    if (info != null) {
      // RawImage may still paint this handle until the next build completes.
      WidgetsBinding.instance.addPostFrameCallback((_) => info.dispose());
    }
  }

  void _resolve() {
    final provider = CatSprite._provider(
        widget.type,
        widget.action,
        CatSprite.decodeHeight(
            widget.size, MediaQuery.devicePixelRatioOf(context)));
    if (provider == _requested) return;
    if (_listener != null) _stream?.removeListener(_listener!);
    _requested = provider;
    final request = ++_request;
    final stream = provider.resolve(createLocalImageConfiguration(context));
    _stream = stream;
    _listener = ImageStreamListener((info, synchronous) {
      if (!mounted || request != _request) {
        info.dispose();
        return;
      }
      _release(_image);
      _image = info;
      _displayed = provider;
      _shownFrames = widget.frames;
      _shownFrame = widget.frame;
      if (!synchronous) setState(() {});
    }, onError: (_, __) {
      // Keep the last complete frame if an optional sheet fails to load.
    });
    stream.addListener(_listener!);
  }

  @override
  void dispose() {
    _request++;
    if (_listener != null) _stream?.removeListener(_listener!);
    _release(_image);
    _image = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Image and crop metadata switch together. Applying the new frame count
    // to the old sheet would show sliced/empty cells while decoding.
    if (_displayed == _requested && _image != null) {
      _shownFrames = widget.frames;
      _shownFrame = widget.frame;
    }
    final frames = _shownFrames.clamp(1, 1 << 20);
    final frame = _shownFrame.clamp(0, frames - 1);
    return Transform.flip(
        flipX: widget.flip,
        child: SizedBox.square(
          dimension: widget.size,
          child: _image == null
              ? CircleAvatar(backgroundColor: CatBreed.of(widget.type).color)
              : ClipRect(
                  child: OverflowBox(
                  maxWidth: widget.size * frames,
                  maxHeight: widget.size,
                  alignment: Alignment(
                      frames <= 1 ? -1 : -1 + 2 * frame / (frames - 1), 0),
                  child: RawImage(
                      image: _image!.image,
                      scale: _image!.scale,
                      width: widget.size * frames,
                      height: widget.size,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium),
                )),
        ));
  }
}

/// A breed's first idle frame in a round badge (chooser buttons, chapters).
class CatFace extends StatelessWidget {
  const CatFace(this.type,
      {super.key, this.size = 46, this.border, this.background});
  final String type;
  final double size;
  final Color? border;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            border:
                border == null ? null : Border.all(color: border!, width: 2)),
        child: ClipOval(child: CatSprite(type: type, size: size)),
      );
}
