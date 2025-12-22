function 5_6 {
    # PowerShell実行：PowerShellスクリプトまたはコマンドを実行

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "PowerShell実行"
    $フォーム.Size = New-Object System.Drawing.Size(550, 380)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # 実行タイプ
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "実行タイプ："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $タイプコンボ = New-Object System.Windows.Forms.ComboBox
    $タイプコンボ.Location = New-Object System.Drawing.Point(20, 45)
    $タイプコンボ.Size = New-Object System.Drawing.Size(200, 25)
    $タイプコンボ.DropDownStyle = "DropDownList"
    $タイプコンボ.Items.AddRange(@("コマンド実行", "スクリプトファイル実行"))
    $タイプコンボ.SelectedIndex = 0

    # コマンド/スクリプト入力
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "実行するコマンド："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 80)
    $ラベル2.AutoSize = $true

    $コマンドテキスト = New-Object System.Windows.Forms.TextBox
    $コマンドテキスト.Location = New-Object System.Drawing.Point(20, 105)
    $コマンドテキスト.Size = New-Object System.Drawing.Size(400, 80)
    $コマンドテキスト.Multiline = $true
    $コマンドテキスト.ScrollBars = "Vertical"
    $コマンドテキスト.Text = ""

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(430, 105)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 27)
    $参照ボタン.Enabled = $false
    $参照ボタン.Add_Click({
        $openDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openDialog.Filter = "PowerShellスクリプト (*.ps1)|*.ps1|すべてのファイル (*.*)|*.*"
        $openDialog.Title = "スクリプトファイルを選択"
        if ($openDialog.ShowDialog() -eq "OK") {
            $コマンドテキスト.Text = $openDialog.FileName
        }
    })

    # タイプ変更時の処理
    $タイプコンボ.Add_SelectedIndexChanged({
        if ($タイプコンボ.SelectedItem -eq "スクリプトファイル実行") {
            $ラベル2.Text = "スクリプトファイルパス："
            $コマンドテキスト.Multiline = $false
            $コマンドテキスト.Size = New-Object System.Drawing.Size(400, 25)
            $参照ボタン.Enabled = $true
        } else {
            $ラベル2.Text = "実行するコマンド："
            $コマンドテキスト.Multiline = $true
            $コマンドテキスト.Size = New-Object System.Drawing.Size(400, 80)
            $参照ボタン.Enabled = $false
        }
    })

    # オプション
    $待機チェック = New-Object System.Windows.Forms.CheckBox
    $待機チェック.Text = "実行完了まで待機"
    $待機チェック.Location = New-Object System.Drawing.Point(20, 195)
    $待機チェック.AutoSize = $true
    $待機チェック.Checked = $true

    $新規ウィンドウチェック = New-Object System.Windows.Forms.CheckBox
    $新規ウィンドウチェック.Text = "新しいウィンドウで実行"
    $新規ウィンドウチェック.Location = New-Object System.Drawing.Point(180, 195)
    $新規ウィンドウチェック.AutoSize = $true

    # 結果変数
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "結果を格納する変数名（省略可）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 230)
    $ラベル3.AutoSize = $true

    $変数名テキスト = New-Object System.Windows.Forms.TextBox
    $変数名テキスト.Location = New-Object System.Drawing.Point(20, 255)
    $変数名テキスト.Size = New-Object System.Drawing.Size(150, 25)
    $変数名テキスト.Text = ""

    $説明ラベル = New-Object System.Windows.Forms.Label
    $説明ラベル.Text = "※ 結果取得は「新しいウィンドウで実行」がオフの場合のみ有効"
    $説明ラベル.Location = New-Object System.Drawing.Point(180, 258)
    $説明ラベル.AutoSize = $true
    $説明ラベル.ForeColor = [System.Drawing.Color]::Gray

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(340, 300)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(440, 300)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $タイプコンボ, $ラベル2, $コマンドテキスト, $参照ボタン, $待機チェック, $新規ウィンドウチェック, $ラベル3, $変数名テキスト, $説明ラベル, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $タイプ = $タイプコンボ.SelectedItem
    $コマンド = $コマンドテキスト.Text
    $変数名 = $変数名テキスト.Text

    if ([string]::IsNullOrWhiteSpace($コマンド)) {
        return "# キャンセルされました"
    }

    if ($タイプ -eq "スクリプトファイル実行") {
        # スクリプトファイル実行
        if ($新規ウィンドウチェック.Checked) {
            $待機引数 = if ($待機チェック.Checked) { " -Wait" } else { "" }
            $entryString = @"
# PowerShellスクリプト実行: $コマンド
Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$コマンド`""$待機引数
Write-Host "PowerShellスクリプトを実行しました" -ForegroundColor Green
"@
        } else {
            if ($変数名) {
                $entryString = @"
# PowerShellスクリプト実行: $コマンド (結果取得)
`$$変数名 = & "$コマンド"
変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
Write-Host "PowerShellスクリプト実行完了" -ForegroundColor Green
"@
            } else {
                $entryString = @"
# PowerShellスクリプト実行: $コマンド
& "$コマンド"
Write-Host "PowerShellスクリプト実行完了" -ForegroundColor Green
"@
            }
        }
    } else {
        # コマンド実行
        $コマンド一行 = $コマンド -replace "`r`n", "; "
        if ($新規ウィンドウチェック.Checked) {
            $待機引数 = if ($待機チェック.Checked) { " -Wait" } else { "" }
            $entryString = @"
# PowerShellコマンド実行 (新規ウィンドウ)
Start-Process -FilePath "powershell.exe" -ArgumentList "-Command $コマンド一行"$待機引数
Write-Host "PowerShellコマンドを実行しました" -ForegroundColor Green
"@
        } else {
            if ($変数名) {
                $entryString = @"
# PowerShellコマンド実行 (結果取得)
`$$変数名 = Invoke-Expression "$コマンド一行"
変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
Write-Host "PowerShellコマンド実行完了" -ForegroundColor Green
"@
            } else {
                $entryString = @"
# PowerShellコマンド実行
Invoke-Expression "$コマンド一行"
Write-Host "PowerShellコマンド実行完了" -ForegroundColor Green
"@
            }
        }
    }

    return $entryString
}
