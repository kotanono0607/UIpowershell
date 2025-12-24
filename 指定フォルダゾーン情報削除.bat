@echo off
rem Ver1.3 このフォルダ配下のゾーン情報を一括削除（PowerShell一括・Bypass、集計改善）
setlocal EnableExtensions

rem --- このバッチファイルがあるフォルダを対象にする ---
set "TARGET=%~dp0"
rem 末尾のバックスラッシュを削除
if "%TARGET:~-1%"=="\" set "TARGET=%TARGET:~0,-1%"

echo.
echo ==== 処理開始: %TARGET% ====
echo.

powershell -ExecutionPolicy Bypass -NoProfile -Command ^
  "$ErrorActionPreference='SilentlyContinue';" ^
  "$path = '%TARGET%';" ^
  "$total=0; $hit=0; $removed=0; $failed=0;" ^
  "Get-ChildItem -LiteralPath $path -Recurse -File -Force | ForEach-Object {" ^
  "  $total++;" ^
  "  $full = $_.FullName;" ^
  "  $streams = Get-Item -LiteralPath $full -Stream * -ErrorAction SilentlyContinue;" ^
  "  if($streams.Stream -contains 'Zone.Identifier') {" ^
  "    $hit++;" ^
  "    Write-Host '[対象]' $full;" ^
  "    Write-Host '[前] ストリーム一覧:';" ^
  "    Get-Item -LiteralPath $full -Stream * | Format-Table -AutoSize | Out-String | Write-Host;" ^
  "    Remove-Item -LiteralPath $full -Stream 'Zone.Identifier' -ErrorAction SilentlyContinue;" ^
  "    Write-Host '';" ^
  "    Write-Host '[後] ストリーム一覧:';" ^
  "    $after = Get-Item -LiteralPath $full -Stream * -ErrorAction SilentlyContinue;" ^
  "    $after | Format-Table -AutoSize | Out-String | Write-Host;" ^
  "    if(-not ($after.Stream -contains 'Zone.Identifier')) { $removed++; Write-Host '-> 削除成功'; } else { $failed++; Write-Host '-> 削除失敗'; }" ^
  "    Write-Host ''" ^
  "  }" ^
  "};" ^
  "Write-Host '==== 集計 ====';" ^
  "Write-Host ('検査ファイル数 : {0}' -f $total);" ^
  "Write-Host ('ゾーン検出     : {0}' -f $hit);" ^
  "Write-Host ('削除成功       : {0}' -f $removed);" ^
  "Write-Host ('削除失敗       : {0}' -f $failed);"

echo.
echo 完了。
pause
endlocal
