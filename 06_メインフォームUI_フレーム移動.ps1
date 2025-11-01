# フレームパネルをフォームから削除する関数


function メインフレームの左を押した場合の処理 {

        00_フレームを表示する -フレームパネル $Global:不可視右の右パネル

        $layers = @($Global:可視左パネル, $Global:可視右パネル, $Global:不可視右の右パネル) # レイヤーパネルを配列に格納
        $moveIterations = 3 # 移動を繰り返す回数を設定

        for ($i = 1; $i -le $moveIterations; $i++) {
            foreach ($layer in $layers) {
                00_フレームを移動する -フレームパネル $layer -deltaX -130 -deltaY 0 -相対
            }
            Start-Sleep -Milliseconds 100
        }

        00_フレームを非表示にする -フレームパネル $Global:可視左パネル

        $Global:不可視左の左パネル = $Global:可視左パネル
        $Global:可視左パネル = $Global:可視右パネル
        $Global:可視右パネル = $Global:不可視右の右パネル
        $新しいレイヤー名 = 新しいレイヤー名を取得する -パネル $Global:不可視右の右パネル　-向き "左"# 関数を呼び出して新しいレイヤー名を取得
        $Global:不可視右の右パネル = (Get-Variable -Name $新しいレイヤー名 -Scope Global).Value　# レイヤー名から変数を取得して不可視右の右パネルに割り当て

        # 現在のレイヤーより深いレイヤーをすべてクリア
        $現在のレイヤー番号 = グローバル変数から数値取得 -パネル $Global:可視左パネル
        Write-Host "左矢印: 現在のレイヤー $現在のレイヤー番号 より深いレイヤーをクリアします" -ForegroundColor Yellow

        if ($null -ne $現在のレイヤー番号) {
            for ($i = [int]$現在のレイヤー番号 + 1; $i -le 6; $i++) {
                $レイヤー変数名 = "レイヤー$i"
                if (Get-Variable -Name $レイヤー変数名 -Scope Global -ErrorAction SilentlyContinue) {
                    $クリア対象パネル = (Get-Variable -Name $レイヤー変数名 -Scope Global).Value
                    Write-Host "  レイヤー$i をクリア" -ForegroundColor Cyan
                    フレームパネルからすべてのボタンを削除する -フレームパネル $クリア対象パネル
                }
            }
            # レイヤー階層の深さを更新
            $Global:レイヤー階層の深さ = [int]$現在のレイヤー番号
        }

        # 階層パス表示を更新
        階層パス表示を更新する
}
function メインフレームの右を押した場合の処理 {

        00_フレームを表示する -フレームパネル $Global:不可視左の左パネル

        $layers = @($Global:不可視左の左パネル, $Global:可視左パネル,$Global:可視右パネル) # レイヤーパネルを配列に格納
        $moveIterations = 3 # 移動を繰り返す回数を設定

        for ($i = 1; $i -le $moveIterations; $i++) {
            foreach ($layer in $layers) {
                00_フレームを移動する -フレームパネル $layer -deltaX 130 -deltaY 0 -相対
            }
            Start-Sleep -Milliseconds 100
        }

         00_フレームを非表示にする -フレームパネル $Global:可視右パネル

        $Global:不可視右の右パネル = $Global:可視右パネル
        $Global:可視右パネル = $Global:可視左パネル
        $Global:可視左パネル = $Global:不可視左の左パネル


        $新しいレイヤー名 = 新しいレイヤー名を取得する -パネル $Global:不可視左の左パネル -向き "右"　# 関数を呼び出して新しいレイヤー名を取得
        $Global:不可視左の左パネル = (Get-Variable -Name $新しいレイヤー名 -Scope Global).Value　# レイヤー名から変数を取得して不可視右の右パネルに割り当て

        # 現在のレイヤーより深いレイヤーをすべてクリア
        $現在のレイヤー番号 = グローバル変数から数値取得 -パネル $Global:可視左パネル
        Write-Host "右矢印: 現在のレイヤー $現在のレイヤー番号 より深いレイヤーをクリアします" -ForegroundColor Yellow

        if ($null -ne $現在のレイヤー番号) {
            for ($i = [int]$現在のレイヤー番号 + 1; $i -le 6; $i++) {
                $レイヤー変数名 = "レイヤー$i"
                if (Get-Variable -Name $レイヤー変数名 -Scope Global -ErrorAction SilentlyContinue) {
                    $クリア対象パネル = (Get-Variable -Name $レイヤー変数名 -Scope Global).Value
                    Write-Host "  レイヤー$i をクリア" -ForegroundColor Cyan
                    フレームパネルからすべてのボタンを削除する -フレームパネル $クリア対象パネル
                }
            }
            # レイヤー階層の深さを更新
            $Global:レイヤー階層の深さ = [int]$現在のレイヤー番号
        }

        # 階層パス表示を更新
        階層パス表示を更新する
}



# 必要なモジュールをインポート（System.Windows.Forms を使用する場合）
Add-Type -AssemblyName System.Windows.Forms

# 1. グローバル変数からレイヤー名の最後の文字を取得する関数
function グローバル変数から数値取得 {
    param (
        [System.Windows.Forms.Panel]$パネル
    )

    # グローバルスコープから「レイヤー」を含む変数を検索
    $一致する変数 = Get-Variable -Scope Global | Where-Object {
        $_.Value -eq $パネル -and $_.Name -like '*レイヤー*'
    } | Select-Object -First 1

    if ($一致する変数) {
        $レイヤー名 = $一致する変数.Name
        #Write-Host "対応する変数名: $レイヤー名"

        try {
            # 名前の最後の文字を取得（文字列として）
            $最後の文字 = $レイヤー名[-1].ToString()
            #Write-Host "最後の文字: $最後の文字"
            return $最後の文字
        }
        catch {
            #Write-Host "レイヤー名から最後の文字を取得できませんでした。エラー: $_" -ForegroundColor Red
            return $null
        }
    }
    else {
        #Write-Host "該当するレイヤー変数が見つかりません。" -ForegroundColor Red
        return $null
    }
}

# 2. 新しいレイヤー名を取得する関数
function 新しいレイヤー名を取得する {
    param (
        [System.Windows.Forms.Panel]$パネル,
        [string]$向き
    )

    # レイヤーの最後の文字を取得する関数を呼び出す
    $最後の文字 = グローバル変数から数値取得　-パネル $パネル

    if ($null -ne $最後の文字) {
        # 最後の文字が数字であることを確認
        if ($最後の文字 -match '^\d$') {
            if ($向き -eq "左") {
                $新しい番号 = [int]$最後の文字 + 1
            }
            elseif ($向き -eq "右") {
                $新しい番号 = [int]$最後の文字 - 1
            }
            else {
                #Write-Host "向きの値が無効です。'左' または '右' を指定してください。" -ForegroundColor Yellow
                return $null
            }

            # 新しいレイヤー名を作成
            $新しいレイヤー名 = "レイヤー$新しい番号"
            return $新しいレイヤー名
        }
        else {
            #Write-Host "レイヤー名の最後の文字が数字ではありません。値を確認してください。" -ForegroundColor Red
            return $null
        }
    }
    else {
        return $null
    }
}



function 00_フレームを削除する {
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Panel]$フレームパネル  # 削除対象のフレームパネル
    )

    # フレームパネルが存在し、フォームに追加されていることを確認
    if ($フレームパネル -eq $null) {
        #Write-Host "警告: フレームパネルが指定されていません。" -ForegroundColor Yellow
        return
    }

    if ($フレームパネル.Parent -eq $null) {
        #Write-Host "警告: フレームパネルがフォームに追加されていません。" -ForegroundColor Yellow
        return
    }

    # 削除処理
    try {
        # フレームパネルを親から削除
        $フレームパネル.Parent.Controls.Remove($フレームパネル)

        # フレームパネルのリソースを解放
        $フレームパネル.Dispose()

        #Write-Host "フレームパネルをフォームから削除しました。" -ForegroundColor Green
    }
    catch {
        #Write-Host "フレームパネルの削除中にエラーが発生しました。 - $_" -ForegroundColor Red
    }
}






# フレームパネルを新しい位置に移動する関数（相対移動と絶対移動をサポート）
function 00_フレームを移動する {
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Panel]$フレームパネル,  # 移動対象のフレームパネル

        # 絶対移動用のパラメータ
        [Parameter(Mandatory = $false)]
        [int]$新X位置,  # 新しいX座標（絶対）

        [Parameter(Mandatory = $false)]
        [int]$新Y位置,   # 新しいY座標（絶対）

        # 相対移動用のパラメータ
        [Parameter(Mandatory = $false)]
        [int]$deltaX = 0,  # X方向の移動量（相対）

        [Parameter(Mandatory = $false)]
        [int]$deltaY = 0,  # Y方向の移動量（相対）

        # 相対移動を指定するスイッチ
        [switch]$相対
    )

    # フレームパネルが存在し、フォームに追加されていることを確認
    if ($フレームパネル -eq $null) {
        #Write-Host "警告: フレームパネルが指定されていません。" -ForegroundColor Yellow
        return
    }

    if ($フレームパネル.Parent -eq $null) {
        #Write-Host "警告: フレームパネルがフォームに追加されていません。" -ForegroundColor Yellow
        return
    }

    # 移動処理
    try {
        if ($相対) {
            # 相対移動の場合
            $現在の位置 = $フレームパネル.Location
            $新X = $現在の位置.X + $deltaX
            $新Y = $現在の位置.Y + $deltaY
            $フレームパネル.Location = New-Object System.Drawing.Point($新X, $新Y)
            ##Write-Host "フレームパネルを相対位置に移動しました。ΔX: $deltaX, ΔY: $deltaY" -ForegroundColor Green
        }
        else {
            # 絶対移動の場合
            if ($新X位置 -eq $null -or $新Y位置 -eq $null) {
                #Write-Host "警告: 絶対移動の場合は新しいX位置とY位置を指定してください。" -ForegroundColor Yellow
                return
            }
            $フレームパネル.Location = New-Object System.Drawing.Point($新X位置, $新Y位置)
            ##Write-Host "フレームパネルを新しい位置に移動しました。X: $新X位置, Y: $新Y位置" -ForegroundColor Green
        }
    }
    catch {
        #Write-Host "フレームパネルの移動中にエラーが発生しました。 - $_" -ForegroundColor Red
    }
}



# フレームパネルを非表示にする関数
function 00_フレームを非表示にする {
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Panel]$フレームパネル  # 非表示にするフレームパネル
    )

    # フレームパネルが存在し、フォームに追加されていることを確認
    if ($フレームパネル -eq $null) {
        #Write-Host "警告: フレームパネルが指定されていません。" -ForegroundColor Yellow
        return
    }

    if ($フレームパネル.Parent -eq $null) {
        #Write-Host "警告: フレームパネルがフォームに追加されていません。" -ForegroundColor Yellow
        return
    }

    # 非表示処理
    try {
        $フレームパネル.Visible = $false
        #Write-Host "フレームパネルを非表示にしました。" -ForegroundColor Green
    }
    catch {
        #Write-Host "フレームパネルの非表示中にエラーが発生しました。 - $_" -ForegroundColor Red
    }
}


# フレームパネルを表示する関数
function 00_フレームを表示する {
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Panel]$フレームパネル  # 表示するフレームパネル
    )

    # フレームパネルが存在し、フォームに追加されていることを確認
    if ($フレームパネル -eq $null) {
        #Write-Host "警告: フレームパネルが指定されていません。" -ForegroundColor Yellow
        return
    }

    if ($フレームパネル.Parent -eq $null) {
        #Write-Host "警告: フレームパネルがフォームに追加されていません。" -ForegroundColor Yellow
        return
    }

    # 表示処理
    try {
        $フレームパネル.Visible = $true
        #Write-Host "フレームパネルを表示しました。" -ForegroundColor Green
    }
    catch {
        #Write-Host "フレームパネルの表示中にエラーが発生しました。 - $_" -ForegroundColor Red
    }
}



# フレームパネルにラベルを追加する関数
function 00_フレームパネルにラベルを追加する {
    param (
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Panel]$フレームパネル,    # ラベルを追加するフレームパネル

        [Parameter(Mandatory = $true)]
        [string]$ラベルテキスト,                        # ラベルに表示するテキスト

        [int]$X位置 = 10,                                 # ラベルのX座標（フレームパネル内での位置）
        [int]$Y位置 = 10,                                 # ラベルのY座標（フレームパネル内での位置）

        [System.Drawing.Font]$フォント = (New-Object System.Drawing.Font("MS UI Gothic", 12)), # ラベルのフォント
        [System.Drawing.Color]$フォント色 = [System.Drawing.Color]::Black,                   # ラベルのテキスト色
        [System.Drawing.Color]$背景色 = [System.Drawing.Color]::Transparent               # ラベルの背景色
    )

    # フレームパネルが存在し、フォームに追加されていることを確認
    if ($フレームパネル -eq $null) {
        #Write-Host "警告: フレームパネルが指定されていません。" -ForegroundColor Yellow
        return
    }

    if ($フレームパネル.Parent -eq $null) {
        #Write-Host "警告: フレームパネルがフォームに追加されていません。" -ForegroundColor Yellow
        return
    }

    # ラベルの作成と設定
    try {
        # ラベルの作成
        $ラベル = New-Object System.Windows.Forms.Label
        $ラベル.Text = $ラベルテキスト
        $ラベル.AutoSize = $true
        $ラベル.Location = New-Object System.Drawing.Point($X位置, $Y位置)
        $ラベル.Font = $フォント
        $ラベル.ForeColor = $フォント色
        $ラベル.BackColor = $背景色

        # 必要に応じて他のプロパティも設定可能
        # 例: クリックイベントの追加など

        # ラベルをフレームパネルに追加
        $フレームパネル.Controls.Add($ラベル)

        #Write-Host "ラベルをフレームパネルに追加しました。テキスト: '$ラベルテキスト', 位置: X=$X位置, Y=$Y位置" -ForegroundColor Green
    }
    catch {
        #Write-Host "ラベルの追加中にエラーが発生しました。 - $_" -ForegroundColor Red
    }
}

function パネル名を表示する {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # フォームの作成
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "パネル名一覧"
    $form.Size = New-Object System.Drawing.Size(400, 250)

    # 表示するグローバル変数のリスト
    $globalVars = @(
        $Global:不可視左の左パネル,
        $Global:可視左パネル,
        $Global:可視右パネル,
        $Global:不可視右の右パネル
    )

    # ラベルの作成と配置
    $yPos = 20
    foreach ($panel in $globalVars) {
        if ($panel -ne $null) {
            # 同じオブジェクトを参照し、名前に「レイヤー」を含むグローバル変数を検索
            $一致する変数 = Get-Variable -Scope Global | Where-Object {
                $_.Value -eq $panel -and $_.Name -like '*レイヤー*'
            } | Select-Object -First 1

            if ($一致する変数) {
                $レイヤー名 = $一致する変数.Name
                $表示テキスト = "$($一致する変数.Name): $($panel.Name)"
            }
            else {
                $表示テキスト = "該当なし: パネル名 = $($panel.Name)"
            }
        }
        else {
            $表示テキスト = "未定義のパネル"
        }

        # ラベルを作成
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $表示テキスト
        $label.AutoSize = $true
        $label.Location = New-Object System.Drawing.Point(20, $yPos)
        $form.Controls.Add($label)
        $yPos += 40
    }

    # フォームを表示
    $form.ShowDialog()
}
