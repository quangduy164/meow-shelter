import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../../online/fishing_world.dart';

/// Owns only the temporary banner; presence and join detection live in the world.
class FishingArrivalNotice extends StatefulWidget {
  const FishingArrivalNotice({super.key, required this.world});
  final FishingWorld world;
  @override
  State<FishingArrivalNotice> createState() => _FishingArrivalNoticeState();
}

class _FishingArrivalNoticeState extends State<FishingArrivalNotice> {
  Timer? _timer;
  String? _name;

  @override
  void initState() {
    super.initState();
    widget.world.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _changed();
    });
  }

  @override
  void didUpdateWidget(FishingArrivalNotice old) {
    super.didUpdateWidget(old);
    if (old.world == widget.world) return;
    old.world.removeListener(_changed);
    _timer?.cancel();
    _name = null;
    widget.world.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _changed();
    });
  }

  void _changed() {
    if (!widget.world.online) {
      _timer?.cancel();
      if (_name != null) setState(() => _name = null);
      return;
    }
    if (_name != null) return;
    final name = widget.world.takeArrival();
    if (name == null) return;
    setState(() => _name = name);
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _name = null);
      _changed();
    });
  }

  @override
  void dispose() {
    widget.world.removeListener(_changed);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: Center(
          child: _name == null
              ? const SizedBox.shrink()
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xDD24373D),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('$_name đã vào phòng',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13)))));
}
