﻿# JSONファイルに対する変数操作関数定義スクリプト
#$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納
#$変数ファイルパス =  $global:JSONPath# JSONファイルのパスを指定

# 変数をJSONファイルから読み込む関数
function 変数をJSONから読み込む {
    param (
        [string]$JSONファイルパス = $変数ファイルパス
    )

    # JSON読み込み（共通関数使用）
    $読み込んだ変数 = Read-JsonSafe -Path $JSONファイルパス -Required $true -Silent $false
    if (-not $読み込んだ変数) {
        throw "JSONファイルの読み込みに失敗しました: $JSONファイルパス"
    }

    try {

        $変数 = @{}

        foreach ($キー in $読み込んだ変数.PSObject.Properties.Name) {
            $値 = $読み込んだ変数.$キー
            if ($値 -is [System.Array]) {
                if ($値.Length -gt 0 -and ($値[0] -is [System.Array] -or $値[0] -is [System.Object[]])) {
                    # 二次元配列
                    $配列 = @()
                    foreach ($行 in $値) {
                        $行データ = @()
                        foreach ($セル in $行) {
                            $行データ += $セル
                        }
                        $配列 += ,$行データ
                    }
                    $変数[$キー] = $配列
                } else {
                    # 一次元配列
                    $変数[$キー] = $値
                }
            } else {
                # 単一値
                $変数[$キー] = $値
            }
        }

        return $変数
    } catch {
        throw "JSONの読み込みに失敗しました: $_"
    }
}

# 変数をJSONファイルに保存する関数
function 変数をJSONに保存する {
    param (
        [hashtable]$変数,
        [string]$JSONファイルパス = $変数ファイルパス
    )

    try {
        # JSON保存（共通関数使用 - 親ディレクトリ作成も自動）
        # Write-JsonSafeはTrueを返すため、出力を抑制
        Write-JsonSafe -Path $JSONファイルパス -Data $変数 -Depth 10 -CreateDirectory $true -Silent $false | Out-Null
    } catch {
        throw "JSONの保存に失敗しました: $_"
    }
}

# 変数を追加・更新する関数
function 変数を追加する {
    param (
        [hashtable]$変数,
        [string]$名前,
        [string]$型,  # "単一値", "一次元", "二次元"
        $値
    )

    if ([string]::IsNullOrWhiteSpace($名前)) {
        throw "変数名を入力してください。"
    }

    switch ($型) {
        "単一値" {
            $変数[$名前] = $値
        }
        "一次元" {
            if (-not ($値 -is [System.Array])) {
                throw "一次元配列の値は配列である必要があります。"
            }
            $変数[$名前] = $値
        }
        "二次元" {
            # 配列チェックを緩和：配列であり、要素があり、最初の要素がインデックス可能であればOK
            if (-not ($値 -is [System.Array])) {
                throw "二次元配列の値は配列である必要があります。実際の型: $($値.GetType().FullName)"
            }
            if ($値.Count -eq 0) {
                throw "二次元配列の値が空です。"
            }
            # 最初の要素が配列かどうかの厳密なチェックは行わない（様々な配列型に対応）
            # 代わりに、インデックスアクセス可能かどうかで判断
            try {
                $testAccess = $値[0][0]
            } catch {
                throw "二次元配列の値は二次元の配列である必要があります。値[0]の型: $($値[0].GetType().FullName)"
            }
            $変数[$名前] = $値
        }
        default {
            throw "無効なデータ型です。'単一値'、'一次元'、または'二次元'を指定してください。"
        }
    }

    Write-Host "変数 '$名前' を追加しました。"
}

# 変数を参照する関数
function 変数の値を取得する {
    param (
        [hashtable]$変数,
        [string]$名前
    )

    if ($変数.ContainsKey($名前)) {
        return $変数[$名前]
    } else {
        throw "変数 '$名前' が見つかりません。"
    }
}



# 二次元データの指定要素を取得する関数
function 二次元値を取得する {
    param (
        [array]$データ,    # 二次元データ
        [int]$行番号,      # 行番号（0から始まるインデックス）
        [int]$列番号       # 列番号（0から始まるインデックス）
    )
    # 行番号と列番号を指定して値を取得
    return $データ[$行番号][$列番号]
}

# 変数をDataGridViewで表示する関数（実行時用）
function 変数をグリッド表示 {
    param(
        [string]$変数名,
        $データ
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # データが配列でない場合はMessageBoxで表示
    if (-not ($データ -is [System.Array])) {
        [System.Windows.Forms.MessageBox]::Show(
            "【変数名】$変数名`n【型】単一値`n`n【内容】`n$データ",
            "変数の内容",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return
    }

    # 一次元配列の場合
    if (-not ($データ[0] -is [System.Array])) {
        $表示テキスト = "【変数名】$変数名`n【型】一次元配列`n【要素数】$($データ.Count)`n`n【内容】`n"
        for ($i = 0; $i -lt [Math]::Min($データ.Count, 50); $i++) {
            $表示テキスト += "[$i] $($データ[$i])`n"
        }
        if ($データ.Count -gt 50) {
            $表示テキスト += "... (以降省略、全$($データ.Count)件)"
        }
        [System.Windows.Forms.MessageBox]::Show($表示テキスト, "変数の内容", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }

    # 二次元配列の場合はDataGridViewで表示
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "変数ビューア: $変数名"
    $フォーム.Size = New-Object System.Drawing.Size(900, 600)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.Topmost = $true

    # 情報ラベル
    $情報ラベル = New-Object System.Windows.Forms.Label
    $情報ラベル.Text = "変数名: $変数名  |  行数: $($データ.Count)  |  列数: $($データ[0].Count)"
    $情報ラベル.Location = New-Object System.Drawing.Point(10, 10)
    $情報ラベル.Size = New-Object System.Drawing.Size(860, 20)
    $情報ラベル.Font = New-Object System.Drawing.Font("メイリオ", 10)

    # DataGridView
    $グリッド = New-Object System.Windows.Forms.DataGridView
    $グリッド.Location = New-Object System.Drawing.Point(10, 40)
    $グリッド.Size = New-Object System.Drawing.Size(860, 470)
    $グリッド.AllowUserToAddRows = $false
    $グリッド.AllowUserToDeleteRows = $false
    $グリッド.ReadOnly = $true
    $グリッド.AutoSizeColumnsMode = "AllCells"
    $グリッド.ColumnHeadersHeightSizeMode = "AutoSize"
    $グリッド.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

    # ヘッダー行（最初の行）を列名として使用
    $ヘッダー = $データ[0]
    for ($col = 0; $col -lt $ヘッダー.Count; $col++) {
        $列名 = if ($ヘッダー[$col]) { $ヘッダー[$col].ToString() } else { "列$col" }
        $グリッド.Columns.Add("col$col", $列名) | Out-Null
    }

    # データ行を追加（2行目以降）
    for ($row = 1; $row -lt $データ.Count; $row++) {
        $行データ = @()
        for ($col = 0; $col -lt $データ[$row].Count; $col++) {
            $値 = if ($null -eq $データ[$row][$col]) { "" } else { $データ[$row][$col].ToString() }
            $行データ += $値
        }
        $グリッド.Rows.Add($行データ) | Out-Null
    }

    # 閉じるボタン
    $閉じるボタン = New-Object System.Windows.Forms.Button
    $閉じるボタン.Text = "閉じる"
    $閉じるボタン.Location = New-Object System.Drawing.Point(780, 520)
    $閉じるボタン.Size = New-Object System.Drawing.Size(90, 30)
    $閉じるボタン.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
    $閉じるボタン.Add_Click({ $フォーム.Close() })

    $フォーム.Controls.Add($情報ラベル)
    $フォーム.Controls.Add($グリッド)
    $フォーム.Controls.Add($閉じるボタン)

    $フォーム.ShowDialog() | Out-Null
}
