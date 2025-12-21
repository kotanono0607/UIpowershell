# JSONファイルに対する変数操作関数定義スクリプト
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
        Write-JsonSafe -Path $JSONファイルパス -Data $変数 -Depth 10 -CreateDirectory $true -Silent $false
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

    # デバッグ: 受け取った値の型と内容を表示
    Write-Host "追加する変数の名前: $名前"
    Write-Host "追加する変数の型: $型"
    Write-Host "追加する変数の値の型: $($値.GetType())"
    if ($値 -is [object[]] -and $値.Count -gt 0) {
        Write-Host "追加する変数の値[0]の型: $($値[0].GetType())"
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
            if (-not ($値 -is [System.Array] -and $値.Count -gt 0 -and $値[0] -is [System.Array])) {
                throw "二次元配列の値は二次元の配列である必要があります。"
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
