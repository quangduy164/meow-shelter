import '../cats/cat_breed.dart';

typedef ShelterPlacement = ({String type, String label, double x, double y});

/// Bed slot for each breed, as fractions of the yard.
const _slots = {
  'orange': (0.00, 0.19),
  'himalaya': (0.80, 0.19),
  'scottish': (0.00, 0.56),
  'calico': (0.80, 0.56),
  'black': (0.40, 0.56),
};

/// One bed per breed that appears in [catTypes]; names come from
/// [CatBreed] so a new breed only needs a slot here.
List<ShelterPlacement> shelterLayout(List<String> catTypes) => [
      for (final breed in CatBreed.all)
        if (catTypes.contains(breed.id))
          (
            type: breed.id,
            label: breed.upperName,
            x: _slots[breed.id]!.$1,
            y: _slots[breed.id]!.$2,
          ),
    ];
