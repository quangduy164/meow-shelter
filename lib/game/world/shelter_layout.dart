typedef ShelterPlacement = ({
  String type,
  String label,
  String asset,
  double x,
  double y
});

List<ShelterPlacement> shelterLayout(List<String> catTypes) {
  final shelters =
      <({String type, String label, String asset, double x, double y})>[
    (
      type: 'orange',
      label: 'MÈO CAM',
      asset: 'Bed/bed-orange.png',
      x: 0.00,
      y: 0.20
    ),
    (
      type: 'himalaya',
      label: 'HIMALAYA',
      asset: 'Bed/bed-himalaya.png',
      x: 0.80,
      y: 0.20
    ),
    (
      type: 'scottish',
      label: 'SCOTTISH',
      asset: 'Bed/bed-scottish.png',
      x: 0.00,
      y: 0.59
    ),
    (
      type: 'calico',
      label: 'CALICO',
      asset: 'Bed/bed-calico.png',
      x: 0.80,
      y: 0.59
    ),
  ];
  if (catTypes.contains('black')) {
    shelters.add((
      type: 'black',
      label: 'MÈO ĐEN',
      asset: 'Bed/bed-scottish.png',
      x: 0.40,
      y: 0.59,
    ));
  }
  return shelters;
}
