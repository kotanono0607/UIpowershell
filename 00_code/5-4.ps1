﻿function 5_4 {
    # コマンド実行：コマンドプロンプトでコマンドを実行

    $変数ファイルパス = $global:JSONPath
    $変数 = @{}

    if (Test-Path -Path $変数ファイルパス) {
        $変数 = 変数をJSONから読み込む -JSONファイルパス $変数ファイルパス
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "コマンド実行"
    $フォーム.Size = New-Object System.Drawing.Size(500, 320)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    # コマンド
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "実行するコマンド："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $コマンドテキスト = New-Object System.Windows.Forms.TextBox
    $コマンドテキスト.Location = New-Object System.Drawing.Point(20, 45)
    $コマンドテキスト.Size = New-Object System.Drawing.Size(440, 60)
    $コマンドテキスト.Multiline = $true
    $コマンドテキスト.ScrollBars = "Vertical"
    $コマンドテキスト.Text = ""

    # 作業ディレクトリ
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "作業ディレクトリ（省略可）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 115)
    $ラベル2.AutoSize = $true

    $作業ディレクトリテキスト = New-Object System.Windows.Forms.TextBox
    $作業ディレクトリテキスト.Location = New-Object System.Drawing.Point(20, 140)
    $作業ディレクトリテキスト.Size = New-Object System.Drawing.Size(350, 25)
    $作業ディレクトリテキスト.Text = ""

    $フォルダ参照ボタン = New-Object System.Windows.Forms.Button
    $フォルダ参照ボタン.Text = "参照..."
    $フォルダ参照ボタン.Location = New-Object System.Drawing.Point(380, 139)
    $フォルダ参照ボタン.Size = New-Object System.Drawing.Size(80, 27)
    $フォルダ参照ボタン.Add_Click({
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.Description = "作業ディレクトリを選択"
        if ($folderDialog.ShowDialog() -eq "OK") {
            $作業ディレクトリテキスト.Text = $folderDialog.SelectedPath
        }
    })

    # オプション
    $非表示チェック = New-Object System.Windows.Forms.CheckBox
    $非表示チェック.Text = "ウィンドウを非表示で実行"
    $非表示チェック.Location = New-Object System.Drawing.Point(20, 175)
    $非表示チェック.AutoSize = $true
    $非表示チェック.Checked = $true

    $待機チェック = New-Object System.Windows.Forms.CheckBox
    $待機チェック.Text = "実行完了まで待機"
    $待機チェック.Location = New-Object System.Drawing.Point(200, 175)
    $待機チェック.AutoSize = $true
    $待機チェック.Checked = $true

    # 結果変数
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "結果を格納する変数名（省略可）："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 205)
    $ラベル3.AutoSize = $true

    $変数名テキスト = New-Object System.Windows.Forms.TextBox
    $変数名テキスト.Location = New-Object System.Drawing.Point(20, 230)
    $変数名テキスト.Size = New-Object System.Drawing.Size(150, 25)
    $変数名テキスト.Text = ""

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 250)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 250)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $コマンドテキスト, $ラベル2, $作業ディレクトリテキスト, $フォルダ参照ボタン, $非表示チェック, $待機チェック, $ラベル3, $変数名テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return "# キャンセルされました" }

    $コマンド = $コマンドテキスト.Text -replace "`r`n", " "
    $作業ディレクトリ = $作業ディレクトリテキスト.Text
    $変数名 = $変数名テキスト.Text

    if ([string]::IsNullOrWhiteSpace($コマンド)) {
        return "# キャンセルされました"
    }

    $ウィンドウスタイル = if ($非表示チェック.Checked) { "Hidden" } else { "Normal" }
    $作業ディレクトリ引数 = if ($作業ディレクトリ) { " -WorkingDirectory `"$作業ディレクトリ`"" } else { "" }

    if ($待機チェック.Checked -and $変数名) {
        $entryString = @"
# コマンド実行: $コマンド (結果取得)
`$$変数名 = cmd /c "$コマンド"
変数を追加する -変数 `$変数 -名前 "$変数名" -型 "単一値" -値 `$$変数名
Write-Host "コマンド実行完了" -ForegroundColor Green
"@
    } elseif ($待機チェック.Checked) {
        $entryString = @"
# コマンド実行: $コマンド (待機)
`$プロセス = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $コマンド" -WindowStyle $ウィンドウスタイル$作業ディレクトリ引数 -PassThru -Wait
Write-Host "コマンド実行完了 (終了コード: `$(`$プロセス.ExitCode))" -ForegroundColor Green
"@
    } else {
        $entryString = @"
# コマンド実行: $コマンド
Start-Process -FilePath "cmd.exe" -ArgumentList "/c $コマンド" -WindowStyle $ウィンドウスタイル$作業ディレクトリ引数
Write-Host "コマンドを実行しました" -ForegroundColor Green
"@
    }

    return $entryString
}
