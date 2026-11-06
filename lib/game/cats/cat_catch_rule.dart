/// How a breed has to be caught: a short trait and the explanation shown in
/// the guide. Each breed's rule lives on its CatBreed; the tuning numbers
/// used by the behaviour are below.
class CatCatchRule {
  const CatCatchRule(this.trait, this.how);
  final String trait;
  final String how;

  /// Himalaya refuses fish closer than this and is startled by it.
  static const shyDistance = 120.0;

  /// Black cat refuses fish if another cat is this close to it.
  static const lonelyDistance = 160.0;
  static const scottishMeals = 2;
  static const calicoTaps = 3;

  /// Orange naps this many times longer than the normal catch window.
  static const orangeNap = 2.0;
}
