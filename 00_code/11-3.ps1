
function 11_3 {
    # ファイル削除：ファイルを削除

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ファイル削除設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 220)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 削除対象
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "削除するファイルパス："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $ファイルパステキスト = New-Object System.Windows.Forms.TextBox
    $ファイルパステキスト.Location = New-Object System.Drawing.Point(20, 45)
    $ファイルパステキスト.Size = New-Object System.Drawing.Size(350, 25)

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(380, 43)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 25)
    $参照ボタン.Add_Click({
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = "削除するファイルを選択"
        $dialog.Filter = "すべてのファイル (*.*)|*.*"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $ファイルパステキスト.Text = $dialog.FileName
        }
    })

    # 確認メッセージ
    $確認チェック = New-Object System.Windows.Forms.CheckBox
    $確認チェック.Text = "実行時に確認メッセージを表示しない"
    $確認チェック.Location = New-Object System.Drawing.Point(20, 85)
    $確認チェック.Size = New-Object System.Drawing.Size(250, 25)

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 140)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 140)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $ファイルパステキスト, $参照ボタン, $確認チェック, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $ファイルパス = $ファイルパステキスト.Text
    $確認なし = $確認チェック.Checked

    if ($確認なし) {
        $entryString = @"
# ファイル削除: $ファイルパス
try {
    if (Test-Path -Path "$ファイルパス") {
        Remove-Item -Path "$ファイルパス" -Force
        Write-Host "ファイルを削除しました: $ファイルパス"
    } else {
        Write-Host "ファイルが見つかりません: $ファイルパス" -ForegroundColor Yellow
    }
} catch {
    Write-Host "エラー: ファイル削除に失敗しました - `$(`$_.Exception.Message)" -ForegroundColor Red
}
"@
    } else {
        $entryString = @"
# ファイル削除（確認あり）: $ファイルパス
try {
    if (Test-Path -Path "$ファイルパス") {
        `$確認 = [System.Windows.Forms.MessageBox]::Show("ファイルを削除しますか？`n$ファイルパス", "確認", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        if (`$確認 -eq [System.Windows.Forms.DialogResult]::Yes) {
            Remove-Item -Path "$ファイルパス" -Force
            Write-Host "ファイルを削除しました: $ファイルパス"
        } else {
            Write-Host "ファイル削除をキャンセルしました"
        }
    } else {
        Write-Host "ファイルが見つかりません: $ファイルパス" -ForegroundColor Yellow
    }
} catch {
    Write-Host "エラー: ファイル削除に失敗しました - `$(`$_.Exception.Message)" -ForegroundColor Red
}
"@
    }

    return $entryString
}
