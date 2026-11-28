import '../game/cats/cat_breed.dart';

/// Chat stickers drawn per breed. They travel as plain chat text tokens:
/// `[[s:<breed>:<index>]]` for a breed's own emote and
/// `[[i:<index>:<breed>:<targetUid>]]` for a two-cat interaction.
class FishingSticker {
  const FishingSticker._(this.breed, this.index, this.target);
  final String breed;
  final int index;

  /// Uid of the friend for an interaction, null for a solo emote.
  final String? target;
  bool get interaction => target != null;

  static const emoteCount = 8;
  static const interactions = ['Đập tay', 'Ôm', 'Chia cá', 'Cọ má', 'Tựa vai'];
  static const emotes = {
    'orange': [
      'Liếm mép',
      'Thèm cá',
      'No căng bụng',
      'Ngủ khò',
      'Nháy mắt',
      'Gặm cá',
      'Đói quá',
      'Chào nha'
    ],
    'black': [
      'Ẩn mình',
      'Hứ',
      'Bí ẩn',
      'Lén nhìn',
      'Ngại đỏ mặt',
      'Giật mình',
      'Che mặt',
      'Ngáp'
    ],
    'himalaya': [
      'Xấu hổ',
      'Hết hồn',
      'Rưng rưng',
      'Rụt rè chào',
      'Ôm gối',
      'Trốn tuyết',
      'Phù',
      'Bẽn lẽn'
    ],
    'scottish': [
      'Chê',
      'Ta đây',
      'Uống trà',
      'Được đấy',
      'Ngầu',
      'Cạn lời',
      'Cục bột',
      'Dỗi'
    ],
    'calico': [
      'Lè lưỡi',
      'Cười lăn',
      'Vồ len',
      'Nhảy cẫng',
      'Chữ V',
      'Mắt sao',
      'Bleh',
      'Tung tim'
    ],
  };

  static String emoteSheet(String breed) =>
      'assets/images/${CatBreed.of(breed).sheet('emotes')}';
  static String interactSheet(String breed) =>
      'assets/images/${CatBreed.of(breed).sheet('interact')}';

  static String emote(String breed, int index) => '[[s:$breed:$index]]';
  static String interact(int index, String breed, String target) =>
      '[[i:$index:$breed:$target]]';

  static final _pattern =
      RegExp(r'^\[\[(s|i):([^:\]]+):([^:\]]+)(?::([^\]]+))?\]\]$');

  static FishingSticker? parse(String text) {
    final m = _pattern.firstMatch(text);
    if (m == null) return null;
    if (m[1] == 's') {
      final breed = m[2]!, index = int.tryParse(m[3]!);
      if (m[4] != null || !emotes.containsKey(breed)) return null;
      if (index == null || index < 0 || index >= emoteCount) return null;
      return FishingSticker._(breed, index, null);
    }
    final index = int.tryParse(m[2]!), breed = m[3]!, target = m[4];
    if (index == null || index < 0 || index >= interactions.length) return null;
    if (!emotes.containsKey(breed) || target == null || target.isEmpty) {
      return null;
    }
    return FishingSticker._(breed, index, target);
  }

  String get label => interaction ? interactions[index] : emotes[breed]![index];

  /// Readable text for the chat history.
  static String describe(String text) {
    final s = parse(text);
    return s == null ? text : '[${s.label}]';
  }
}
