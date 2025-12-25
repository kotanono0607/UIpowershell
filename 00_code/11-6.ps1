﻿
function 11_6 {
    # ファイル一覧取得：フォルダ内のファイル一覧を取得

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ファイル一覧取得設定"
    $フォーム.Size = New-Object System.Drawing.Size(500, 320)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()
    })

    # 対象フォルダ
    $ラベル1 = New-Object System.Windows.Forms.Label
    $ラベル1.Text = "対象フォルダ："
    $ラベル1.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル1.AutoSize = $true

    $フォルダパステキスト = New-Object System.Windows.Forms.TextBox
    $フォルダパステキスト.Location = New-Object System.Drawing.Point(20, 45)
    $フォルダパステキスト.Size = New-Object System.Drawing.Size(350, 25)

    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(380, 43)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 25)
    $参照ボタン.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "フォルダを選択"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $フォルダパステキスト.Text = $dialog.SelectedPath
        }
    })

    # フィルタ
    $ラベル2 = New-Object System.Windows.Forms.Label
    $ラベル2.Text = "ファイルフィルタ（例: *.xlsx, *.txt）："
    $ラベル2.Location = New-Object System.Drawing.Point(20, 85)
    $ラベル2.AutoSize = $true

    $フィルタテキスト = New-Object System.Windows.Forms.TextBox
    $フィルタテキスト.Location = New-Object System.Drawing.Point(20, 110)
    $フィルタテキスト.Size = New-Object System.Drawing.Size(200, 25)
    $フィルタテキスト.Text = "*.*"

    # サブフォルダ
    $サブフォルダチェック = New-Object System.Windows.Forms.CheckBox
    $サブフォルダチェック.Text = "サブフォルダも検索する"
    $サブフォルダチェック.Location = New-Object System.Drawing.Point(20, 150)
    $サブフォルダチェック.Size = New-Object System.Drawing.Size(200, 25)

    # 格納先変数
    $ラベル3 = New-Object System.Windows.Forms.Label
    $ラベル3.Text = "結果を格納する変数名："
    $ラベル3.Location = New-Object System.Drawing.Point(20, 185)
    $ラベル3.AutoSize = $true

    $変数名テキスト = New-Object System.Windows.Forms.TextBox
    $変数名テキスト.Location = New-Object System.Drawing.Point(20, 210)
    $変数名テキスト.Size = New-Object System.Drawing.Size(200, 25)
    $変数名テキスト.Text = "ファイル一覧"

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(290, 240)
    $OKボタン.Size = New-Object System.Drawing.Size(90, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(390, 240)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(90, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル1, $フォルダパステキスト, $参照ボタン, $ラベル2, $フィルタテキスト, $サブフォルダチェック, $ラベル3, $変数名テキスト, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $メインメニューハンドル = メインメニューを最小化
    $結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    $フォルダパス = $フォルダパステキスト.Text
    $フィルタ = $フィルタテキスト.Text
    $サブフォルダ = $サブフォルダチェック.Checked
    $変数名 = $変数名テキスト.Text

    $recurse = if ($サブフォルダ) { "-Recurse" } else { "" }

    $entryString = @"
# ファイル一覧取得: $フォルダパス ($フィルタ)
try {
    `$$変数名 = @(Get-ChildItem -Path "$フォルダパス" -Filter "$フィルタ" -File $recurse | Select-Object -ExpandProperty FullName)
    変数を追加する -変数 `$変数 -名前 "$変数名" -型 "配列" -値 `$$変数名
    Write-Host "ファイル一覧を取得しました: `$(`$$変数名.Count) 件"
} catch {
    Write-Host "エラー: ファイル一覧取得に失敗しました - `$(`$_.Exception.Message)" -ForegroundColor Red
}
"@

    return $entryString
}
