enum CatSkill {
  none(''),
  sprint('Chạy vọt'),
  feint('Đổi hướng'),
  zigzag('Zíc-zắc'),
  slippery('Tuột tay'),
  vanish('Biến mất');

  const CatSkill(this.label);
  final String label;
}
