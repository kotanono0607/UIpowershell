
function 10_6 {
    # ウィンドウスクリーンショット：特定のウィンドウをキャプチャ

    $スクリプトPath = $PSScriptRoot
    $メインPath = Split-Path $スクリプトPath

    # ウィンドウ選択モジュールをインポート
    $modulePath = Join-Path -Path $メインPath -ChildPath '02_modules\ウィンドウ選択.psm1'
    $windowTitle = ""

    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force

        # ウィンドウ選択
        $selection = Show-WindowSelector -DialogTitle "キャプチャするウィンドウを選択"

        if ($null -eq $selection) {
            return "# キャンセルされました"
        }

        $windowTitle = $selection.Title
    } else {
        # モジュールがない場合は手入力
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        $入力フォーム = New-Object System.Windows.Forms.Form
        $入力フォーム.Text = "ウィンドウ名入力"
        $入力フォーム.Size = New-Object System.Drawing.Size(400, 150)
        $入力フォーム.StartPosition = "CenterScreen"
        $入力フォーム.FormBorderStyle = "FixedDialog"
        $入力フォーム.MaximizeBox = $false
        $入力フォーム.Topmost = $true
    $入力フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

        $ラベル = New-Object System.Windows.Forms.Label
        $ラベル.Text = "ウィンドウ名（部分一致）："
        $ラベル.Location = New-Object System.Drawing.Point(20, 20)
        $ラベル.AutoSize = $true

        $テキスト = New-Object System.Windows.Forms.TextBox
        $テキスト.Location = New-Object System.Drawing.Point(20, 45)
        $テキスト.Size = New-Object System.Drawing.Size(340, 25)

        $OK = New-Object System.Windows.Forms.Button
        $OK.Text = "OK"
        $OK.Location = New-Object System.Drawing.Point(200, 80)
        $OK.DialogResult = [System.Windows.Forms.DialogResult]::OK

        $入力フォーム.Controls.AddRange(@($ラベル, $テキスト, $OK))
        $入力フォーム.AcceptButton = $OK

        if ($入力フォーム.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return $null
        }
        $windowTitle = $テキスト.Text
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ウィンドウスクリーンショット設定"
    $フォーム.Size = New-Object System.Drawing.Size(480, 200)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 対象ウィンドウ
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "対象ウィンドウ: $windowTitle"
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true
    $ラベル1.ForeColor = [System.Drawing.Color]::Blue

    # 保存先ファイルパス
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "保存先ファイルパス："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 55)
    $ラベル2.AutoSize = $true

    $保存先テキスト = New-Object System.Windows.Forms.TextBox
    $保存先テキスト.Location = New-Object System.Drawing.Point(20, 80)
    $保存先テキスト.Size = New-Object System.Drawing.Size(320, 25)
    $保存先テキスト.Text = "C:\temp\window_screenshot.png"

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(350, 78)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 25)
    $参照ボタン.Add_Click({
        $dialog = New-Object System.Windows.Forms.SaveFileDialog
        $dialog.Title = "保存先を選択"
        $dialog.Filter = "PNG画像 (*.png)|*.png|JPEG画像 (*.jpg)|*.jpg|BMP画像 (*.bmp)|*.bmp"
        $dialog.DefaultExt = "png"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $保存先テキスト.Text = $dialog.FileName
        }
    })

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(260, 120)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(360, 120)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $ラベル2, $保存先テキスト, $参照ボタン, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $保存パス = $保存先テキスト.Text

    $entryString = @"
# ウィンドウスクリーンショット: $windowTitle → $保存パス
ウィンドウスクリーンショット -ウィンドウ名 "$windowTitle" -保存パス "$保存パス"
"@

    return $entryString
}
