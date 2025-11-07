# Invoke-MouseGet 関数の定義
function Invoke-MouseGet {
    param(
        [string]$Caller  # 呼び出し元の名前を受け取るパラメータ
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # グローバル変数を初期化
    $global:MouseClickResult = ""

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

        # 呼び出し元によってテキストを変化させる
        if ($Caller -eq "Addon1") {
            $global:MouseClickResult = "指定座標を左クリック -X座標 $x -Y座標 $y"
        } elseif ($Caller -eq "Addon2") {
            $global:MouseClickResult = "指定座標に移動 -X座標 $x -Y座標 $y"
        } else {
            $global:MouseClickResult = "指定座標を左クリック -X座標 $x -Y座標 $y"
        }

        # フォームを閉じる
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    })

    # フォームをモーダルで表示
    $form.ShowDialog() | Out-Null

    # 結果を返す（グローバル変数に設定済み）
    return $global:MouseClickResult
}
