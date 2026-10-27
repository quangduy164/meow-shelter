$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$images = Join-Path $root 'assets/images'
$background = [System.Drawing.Bitmap]::FromFile((Join-Path $images 'Background/shelter-yard-background.png'))
$output = [System.Drawing.Bitmap]::new(1920, 1080)
$graphics = [System.Drawing.Graphics]::FromImage($output)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

function Add-Cat([string]$type, [int]$x, [int]$bottom, [int]$height, [bool]$flip) {
    $name = $type.ToLowerInvariant()
    $sheet = [System.Drawing.Bitmap]::FromFile((Join-Path $images "Cat/$type/cat-$name-idle.png"))
    try {
        $left = 256; $top = 256; $right = 0; $end = 0
        for ($py = 0; $py -lt 256; $py++) {
            for ($px = 0; $px -lt 256; $px++) {
                if ($sheet.GetPixel($px, $py).A -gt 24) {
                    $left = [Math]::Min($left, $px); $top = [Math]::Min($top, $py)
                    $right = [Math]::Max($right, $px); $end = [Math]::Max($end, $py)
                }
            }
        }
        if ($right -le $left -or $end -le $top) { throw "Empty frame: $type" }
        $crop = [System.Drawing.Rectangle]::new($left, $top, $right - $left + 1, $end - $top + 1)
        $cat = $sheet.Clone($crop, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            if ($flip) { $cat.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
            $width = [int]($height * $cat.Width / $cat.Height)
            $shadow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(45, 48, 67, 27))
            try { $graphics.FillEllipse($shadow, $x + 12, $bottom - 15, $width - 24, 30) }
            finally { $shadow.Dispose() }
            $graphics.DrawImage($cat, $x, ($bottom - $height), $width, $height)
        } finally { $cat.Dispose() }
    } finally { $sheet.Dispose() }
}

try {
    # Preserve the full garden framing; the menu occupies the clear central path.
    $graphics.DrawImage($background, 0, 0, 1920, 1080)
    Add-Cat 'Scottish' 490 650 155 $false
    Add-Cat 'Orange' 220 865 235 $false
    Add-Cat 'Himalaya' 1260 650 165 $true
    Add-Cat 'Black' 1415 870 215 $true
    $path = Join-Path $images 'Background/home-background.png'
    $output.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    if ($output.Width -ne 1920 -or $output.Height -ne 1080) { throw 'Unexpected output size' }
    Write-Output "Created $path (1920x1080)"
} finally {
    $graphics.Dispose()
    $output.Dispose()
    $background.Dispose()
}
