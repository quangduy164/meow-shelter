// Tốc độ di chuyển mèo
const double catWalkSpeed = 60.0;
const double catRunSpeed = 150.0;
const double catDashSpeed = 250.0;

// Kích thước mèo
const double catWidth = 80.0;
const double catHeight = 80.0;

// Thời gian tối thiểu / tối đa cho mỗi hành động (giây)
const double minActionTime = 1.0;
const double maxActionTime = 3.5;
const double minIdleTime = 0.8;
const double maxIdleTime = 2.5;

// Frame count cho từng sprite sheet
const int framesIdle = 6;
const int framesWalk = 6;
const int framesRun = 8;
const int framesTurnAround = 6;
const int framesDragged = 4;
const int framesDropSuccess = 5;
const int framesDropWrong = 5;
const int framesPanic = 4;
const int framesDashEscape = 6;
const int framesCelebrate = 5;

// Tốc độ animation (step time giữa mỗi frame)
const double animationStepTime = 0.12;
