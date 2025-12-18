
function 5_2 {
    Add-Type -AssemblyName System.Windows.Forms

    # フォームの作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "URLを開く"
    $フォーム.Size = New-Object System.Drawing.Size(450, 220)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $フォーム.MaximizeBox = $false

    # ラベル
    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = "入力方法を選択してください:"
    $ラベル.Location = New-Object System.Drawing.Point(10, 15)
    $ラベル.AutoSize = $true
    $フォーム.Controls.Add($ラベル)

    # ラジオボタン1: URL直接入力
    $ラジオURL = New-Object System.Windows.Forms.RadioButton
    $ラジオURL.Text = "URLを直接入力"
    $ラジオURL.Location = New-Object System.Drawing.Point(20, 40)
    $ラジオURL.AutoSize = $true
    $ラジオURL.Checked = $true
    $フォーム.Controls.Add($ラジオURL)

    # ラジオボタン2: ファイル選択
    $ラジオファイル = New-Object System.Windows.Forms.RadioButton
    $ラジオファイル.Text = "ファイルを選択（.url / .html）"
    $ラジオファイル.Location = New-Object System.Drawing.Point(20, 65)
    $ラジオファイル.AutoSize = $true
    $フォーム.Controls.Add($ラジオファイル)

    # 入力欄
    $テキストボックス = New-Object System.Windows.Forms.TextBox
    $テキストボックス.Location = New-Object System.Drawing.Point(20, 100)
    $テキストボックス.Size = New-Object System.Drawing.Size(300, 25)
    $テキストボックス.Text = "https://"
    $フォーム.Controls.Add($テキストボックス)

    # 参照ボタン
    $参照ボタン = New-Object System.Windows.Forms.Button
    $参照ボタン.Text = "参照..."
    $参照ボタン.Location = New-Object System.Drawing.Point(330, 98)
    $参照ボタン.Size = New-Object System.Drawing.Size(80, 25)
    $参照ボタン.Enabled = $false
    $フォーム.Controls.Add($参照ボタン)

    # ラジオボタン切り替え時の処理
    $ラジオURL.Add_CheckedChanged({
        if ($ラジオURL.Checked) {
            $テキストボックス.Enabled = $true
            $テキストボックス.Text = "https://"
            $参照ボタン.Enabled = $false
        }
    })

    $ラジオファイル.Add_CheckedChanged({
        if ($ラジオファイル.Checked) {
            $テキストボックス.Enabled = $false
            $テキストボックス.Text = ""
            $参照ボタン.Enabled = $true
        }
    })

    # 参照ボタンクリック時の処理
    $参照ボタン.Add_Click({
        $ダイアログ = New-Object System.Windows.Forms.OpenFileDialog
        $ダイアログ.Title = "開くファイルを選択"
        $ダイアログ.Filter = "URL/HTML Files (*.url;*.html;*.htm)|*.url;*.html;*.htm|URL Shortcuts (*.url)|*.url|HTML Files (*.html;*.htm)|*.html;*.htm|All Files (*.*)|*.*"
        $ダイアログ.InitialDirectory = [Environment]::GetFolderPath('Desktop')

        if ($ダイアログ.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $選択ファイル = $ダイアログ.FileName

            # .urlファイルの場合はURLを抽出
            if ($選択ファイル -match '\.url$') {
                $抽出URL = $null
                $内容 = Get-Content -Path $選択ファイル -Encoding Default
                foreach ($行 in $内容) {
                    if ($行 -match '^URL=(.+)$') {
                        $抽出URL = $Matches[1]
                        break
                    }
                }
                if ($抽出URL) {
                    $テキストボックス.Text = $抽出URL
                    Write-Host "[URLを開く] .urlファイルからURL抽出: $抽出URL" -ForegroundColor Cyan
                } else {
                    $テキストボックス.Text = $選択ファイル
                    Write-Host "[URLを開く] .urlファイルからURL抽出失敗、パスを使用" -ForegroundColor Yellow
                }
            } else {
                # .html等はそのままパスを使用
                $テキストボックス.Text = $選択ファイル
            }
        }
    })

    # OKボタン
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(250, 145)
    $OKボタン.Size = New-Object System.Drawing.Size(75, 25)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.AcceptButton = $OKボタン
    $フォーム.Controls.Add($OKボタン)

    # キャンセルボタン
    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(335, 145)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(75, 25)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.CancelButton = $キャンセルボタン
    $フォーム.Controls.Add($キャンセルボタン)

    # ダイアログ表示
    $結果 = $フォーム.ShowDialog()

    if ($結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        $URL = $テキストボックス.Text.Trim()
        if ($URL -and $URL -ne "https://") {
            return "URLを開く -URL `"$URL`""
        }
    }

    return "# キャンセルされました"
}
