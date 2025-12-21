# Invoke-MouseGet 関数の定義 Ver 2.0
# ウィンドウ選択対応版

function Invoke-MouseGet {
    param(
        [string]$Caller  # 呼び出し元の名前を受け取るパラメータ
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # ウィンドウ選択モジュールをインポート
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'ウィンドウ選択.psm1'
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    }

    # グローバル変数を初期化
    $global:MouseClickResult = ""

    # ウィンドウ選択（全画面オプション付き）
    $selection = $null
    if (Get-Command Show-WindowSelectorWithFullscreen -ErrorAction SilentlyContinue) {
        $selection = Show-WindowSelectorWithFullscreen -DialogTitle "クリック対象を選択"
    }

    if ($null -eq $selection) {
        # キャンセルされた
        return "# キャンセルされました"
    }

    $windowMode = $selection.Mode -eq "Window"
    $windowTitle = ""
    $windowLeft = 0
    $windowTop = 0

    if ($windowMode) {
        $windowTitle = $selection.Title
        $windowLeft = $selection.Rect.Left
        $windowTop = $selection.Rect.Top

        # 選択したウィンドウをフォアグラウンドに
        Start-Sleep -Milliseconds 200
        if ([WindowHelper]::IsIconic($selection.Handle)) {
            [WindowHelper]::ShowWindow($selection.Handle, 9) | Out-Null
        }
        [WindowHelper]::SetForegroundWindow($selection.Handle) | Out-Null
        Start-Sleep -Milliseconds 300
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "クリックして座標を取得"
    $form.WindowState = 'Maximized'
    $form.TopMost = $true
    $form.Opacity = 0.1  # デバッグ用に透明度を設定

    # マウスクリックイベントの設定
    $form.Add_MouseClick({
        $pos = [System.Windows.Forms.Cursor]::Position
        $x = $pos.X
        $y = $pos.Y
        Write-Host "マウスがクリックされました。X=$x, Y=$y"

        if ($windowMode) {
            # ウィンドウ相対座標を計算
            $relX = $x - $windowLeft
            $relY = $y - $windowTop
            Write-Host "ウィンドウ相対座標: X=$relX, Y=$relY (ウィンドウ: $windowTitle)"

            # ウィンドウ相対座標用のコードを生成
            if ($Caller -eq "Addon1") {
                $global:MouseClickResult = "ウィンドウ相対クリック -ウィンドウ名 `"$windowTitle`" -相対X $relX -相対Y $relY -クリック種別 `"左`""
            } elseif ($Caller -eq "Addon2") {
                $global:MouseClickResult = "ウィンドウ相対移動 -ウィンドウ名 `"$windowTitle`" -相対X $relX -相対Y $relY"
            } elseif ($Caller -eq "Addon3") {
                $global:MouseClickResult = "ウィンドウ相対クリック -ウィンドウ名 `"$windowTitle`" -相対X $relX -相対Y $relY -クリック種別 `"右`""
            } elseif ($Caller -eq "Addon4") {
                $global:MouseClickResult = "ウィンドウ相対クリック -ウィンドウ名 `"$windowTitle`" -相対X $relX -相対Y $relY -クリック種別 `"ダブル`""
            } else {
                $global:MouseClickResult = "ウィンドウ相対クリック -ウィンドウ名 `"$windowTitle`" -相対X $relX -相対Y $relY -クリック種別 `"左`""
            }
        } else {
            # 従来の絶対座標コード
            if ($Caller -eq "Addon1") {
                $global:MouseClickResult = "指定座標を左クリック -X座標 $x -Y座標 $y"
            } elseif ($Caller -eq "Addon2") {
                $global:MouseClickResult = "指定座標に移動 -X座標 $x -Y座標 $y"
            } elseif ($Caller -eq "Addon3") {
                $global:MouseClickResult = "指定座標を右クリック -X座標 $x -Y座標 $y"
            } elseif ($Caller -eq "Addon4") {
                $global:MouseClickResult = "指定座標をダブルクリック -X座標 $x -Y座標 $y"
            } else {
                $global:MouseClickResult = "指定座標を左クリック -X座標 $x -Y座標 $y"
            }
        }

        # フォームを閉じる
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    })

    # フォームをモーダルで表示
    $form.ShowDialog() | Out-Null

    # 結果を返す（グローバル変数に設定済み）
    return $global:MouseClickResult
}
