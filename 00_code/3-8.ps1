function 3_8 {
    # IME切替：日本語入力のオン・オフを切り替え

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "IME切替"
    $フォーム.Size = New-Object System.Drawing.Size(350, 220)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 切替方法
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "IME切替方法："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $切替方法コンボ = New-Object System.Windows.Forms.ComboBox
    $切替方法コンボ.Location = New-Object System.Drawing.Point(20, 45)
    $切替方法コンボ.Size = New-Object System.Drawing.Size(290, 25)
    $切替方法コンボ.DropDownStyle = "DropDownList"
    $切替方法コンボ.Items.AddRange(@(
        "トグル（半角/全角キー）",
        "日本語入力オン（ひらがなモード）",
        "日本語入力オフ（英数モード）",
        "カタカナモード",
        "半角カタカナモード"
    ))
    $切替方法コンボ.SelectedIndex = 0

    # 説明
    $説明ラベル = New-Object System.Windows.Forms.Label
    $説明ラベル.Text = "※ キーボードのIME状態を切り替えます`n   環境によっては動作が異なる場合があります"
    $説明ラベル.Location = New-Object System.Drawing.Point(20, 90)
    $説明ラベル.Size = New-Object System.Drawing.Size(300, 40)
    $説明ラベル.ForeColor = [System.Drawing.Color]::Gray

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(140, 145)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(240, 145)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $切替方法コンボ, $説明ラベル, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $切替方法 = $切替方法コンボ.SelectedItem

    switch ($切替方法) {
        "トグル（半角/全角キー）" {
            $entryString = @"
# IME切替: トグル
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("{KANJI}")
Write-Host "IMEをトグルしました" -ForegroundColor Green
"@
        }
        "日本語入力オン（ひらがなモード）" {
            $entryString = @"
# IME切替: 日本語入力オン
Add-Type -AssemblyName System.Windows.Forms
# Ctrl+CapsLockでひらがなモードに
[System.Windows.Forms.SendKeys]::SendWait("^{CAPSLOCK}")
Write-Host "日本語入力をオンにしました" -ForegroundColor Green
"@
        }
        "日本語入力オフ（英数モード）" {
            $entryString = @"
# IME切替: 日本語入力オフ
Add-Type -AssemblyName System.Windows.Forms
# Shift+CapsLockで英数モードに
[System.Windows.Forms.SendKeys]::SendWait("+{CAPSLOCK}")
Write-Host "日本語入力をオフにしました" -ForegroundColor Green
"@
        }
        "カタカナモード" {
            $entryString = @"
# IME切替: カタカナモード
Add-Type -AssemblyName System.Windows.Forms
# Shift+Ctrl+CapsLockでカタカナモードに
[System.Windows.Forms.SendKeys]::SendWait("+^{CAPSLOCK}")
Write-Host "カタカナモードに切り替えました" -ForegroundColor Green
"@
        }
        "半角カタカナモード" {
            $entryString = @"
# IME切替: 半角カタカナモード
Add-Type -AssemblyName System.Windows.Forms
# Alt+CapsLockで半角カタカナモードに
[System.Windows.Forms.SendKeys]::SendWait("%{CAPSLOCK}")
Write-Host "半角カタカナモードに切り替えました" -ForegroundColor Green
"@
        }
    }

    return $entryString
}
