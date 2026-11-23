// Tốc độ di chuyển mèo
const double catWalkSpeed = 60.0;
const double catRunSpeed = 200.0;
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
const int framesJump = 6;
const int framesRoll = 6;

// Ngồi trên thuyền câu cá / chèo thuyền
const int framesFishCast = 6;
const int framesFishWait = 6;
const int framesFishReel = 6;
const int framesFishHold = 4;
const int framesRow = 6;
const int framesSleep = 6;

/// Centre of the cupped front paws in each fish-hold frame, in sheet pixels
/// (one frame is 256 x 256, cat facing right). The caught fish is drawn here.
const fishHoldPaws = [
  (148.0, 160.0),
  (163.0, 128.0),
  (150.0, 135.0),
  (148.0, 163.0),
];

/// How high each jump-sheet frame already draws the cat, as a share of the
/// sprite size. Code that moves the cat itself subtracts this so the feet
/// follow the physics instead of being lifted twice.
const jumpSheetLift = [0.0, .075, .19, .1, 0.0, 0.0];
const int framesTurnAround = 6;
const int framesDragged = 4;
const int framesDropSuccess = 5;
const int framesDropWrong = 5;
const int framesPanic = 4;
const int framesDashEscape = 6;
const int framesCelebrate = 5;
const int framesVanish = 6;

// Tốc độ animation (step time giữa mỗi frame)
const double animationStepTime = 0.12;
const double vanishStepTime = 0.22;
const double sleepStepTime = 0.32;
