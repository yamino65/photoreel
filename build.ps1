# slideshow.html から、ホーム画面に追加して全画面で使える版（docs フォルダ。GitHub Pages で公開される）を作るスクリプト
# 使い方: PowerShell で  ./build.ps1  を実行

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$app  = Join-Path $root "docs"
New-Item -ItemType Directory -Force $app | Out-Null

# ---- 1. 各ページ（本体の前に、全画面起動用の head を足す） ----
function Build-Page([string]$src, [string]$out, [string]$title, [string]$extraHead) {
  $head = @"
<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="$title">
<meta name="theme-color" content="#15131a">
$extraHead
<link rel="apple-touch-icon" href="icon-180.png">
<style>
  /* claude.ai が自動で足してくれていた基本スタイルの代わり */
  body { margin: 0; font-size: 14px; }
  img { max-width: 100%; }
  [hidden] { display: none !important; }
  /* ステータスバー（時計や電池の表示）に文字が隠れないよう上に余白 */
  .wrap { padding-top: calc(28px + env(safe-area-inset-top, 0px)) !important; }
</style>
"@
  $body = Get-Content (Join-Path $root $src) -Raw -Encoding UTF8
  $html = $head + $body + "`n</html>`n"
  [IO.File]::WriteAllText((Join-Path $app $out), $html, [Text.UTF8Encoding]::new($false))
}
Build-Page "slideshow.html" "index.html" "フォトリール" '<link rel="manifest" href="manifest.webmanifest">'
Build-Page "loop.html"      "loop.html"  "ループPiP"   ''   # 動画をPiPでくり返し再生するページ

# ---- 2. manifest（「アプリとして起動するときは全画面で」という設定ファイル） ----
$manifest = @'
{
  "name": "フォトリール",
  "short_name": "フォトリール",
  "start_url": "./",
  "display": "fullscreen",
  "background_color": "#15131a",
  "theme_color": "#15131a",
  "icons": [
    { "src": "icon-180.png", "sizes": "180x180", "type": "image/png" },
    { "src": "icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
'@
[IO.File]::WriteAllText((Join-Path $app "manifest.webmanifest"), $manifest, [Text.UTF8Encoding]::new($false))

# ---- 3. アイコン画像（映写機のリールの絵）を描いて PNG で保存 ----
Add-Type -AssemblyName System.Drawing
function New-Icon([int]$size, [string]$path) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = "AntiAlias"
  $g.Clear([System.Drawing.Color]::FromArgb(21, 19, 26))           # 背景
  $amber = [System.Drawing.Color]::FromArgb(240, 181, 74)
  $c = $size / 2; $r = $size * 0.34
  $g.FillEllipse((New-Object System.Drawing.SolidBrush $amber), $c - $r, $c - $r, $r * 2, $r * 2)  # リール本体
  $hole = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(21, 19, 26))
  $hr = $size * 0.075
  foreach ($a in 0, 90, 180, 270) {                                  # 4つの穴
    $rad = $a * [Math]::PI / 180
    $x = $c + [Math]::Cos($rad) * $r * 0.55; $y = $c + [Math]::Sin($rad) * $r * 0.55
    $g.FillEllipse($hole, $x - $hr, $y - $hr, $hr * 2, $hr * 2)
  }
  $g.FillEllipse($hole, $c - $hr * 0.6, $c - $hr * 0.6, $hr * 1.2, $hr * 1.2)  # 中心の軸
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
}
New-Icon 180 (Join-Path $app "icon-180.png")
New-Icon 512 (Join-Path $app "icon-512.png")

Write-Host "docs フォルダに書き出しました: $app"
