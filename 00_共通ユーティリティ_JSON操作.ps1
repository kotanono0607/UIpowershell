# ================================================================
# 17_共通ユーティリティ_JSON操作.ps1
# ================================================================
# 責任: JSON操作の共通化・統一
#
# 含まれる関数:
#   - Read-JsonSafe        : 安全なJSON読み込み
#   - Write-JsonSafe       : 安全なJSON書き込み
#   - Test-JsonPath        : JSONファイル存在確認
#   - Initialize-JsonStore : JSONストアの初期化
#
# 作成日: 2025-11-01
# 目的: JSON操作の重複コードを削減し、エラーハンドリングを統一
# ================================================================

<#
.SYNOPSIS
JSONファイルを安全に読み込む

.DESCRIPTION
Test-Path、Get-Content、ConvertFrom-Jsonを統合した安全なJSON読み込み関数。
エラーハンドリングとロギングを統一。

.PARAMETER Path
JSONファイルのパス

.PARAMETER Required
$trueの場合、ファイルが存在しない場合にエラーをスローする（デフォルト: $true）

.PARAMETER Silent
$trueの場合、エラーメッセージを表示しない（デフォルト: $false）

.EXAMPLE
$data = Read-JsonSafe -Path "C:\path\to\file.json"

.EXAMPLE
$data = Read-JsonSafe -Path $jsonPath -Required $false -Silent $true
#>
function Read-JsonSafe {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [bool]$Required = $true,

        [Parameter(Mandatory=$false)]
        [bool]$Silent = $false
    )

    # ファイル存在確認
    if (-not (Test-Path -Path $Path)) {
        if ($Required) {
            if (-not $Silent) {
                Write-Host "[ERROR] JSONファイルが見つかりません: $Path" -ForegroundColor Red
            }
            throw "JSONファイルが見つかりません: $Path"
        } else {
            if (-not $Silent) {
                Write-Host "[WARNING] JSONファイルが見つかりません: $Path" -ForegroundColor Yellow
            }
            return $null
        }
    }

    # JSON読み込み
    try {
        $jsonContent = Get-Content -Path $Path -Raw -Encoding UTF8
        $data = $jsonContent | ConvertFrom-Json

        if (-not $Silent) {
            Write-Host "[INFO] JSON読み込み成功: $Path" -ForegroundColor Green
        }

        return $data
    } catch {
        if (-not $Silent) {
            Write-Host "[ERROR] JSON読み込みエラー: $Path" -ForegroundColor Red
            Write-Host "        エラー詳細: $_" -ForegroundColor Red
        }

        if ($Required) {
            throw "JSON読み込みに失敗しました: $_"
        } else {
            return $null
        }
    }
}

<#
.SYNOPSIS
データをJSON形式でファイルに安全に書き込む

.DESCRIPTION
ConvertTo-Json、Set-Contentを統合した安全なJSON書き込み関数。
エラーハンドリングとロギングを統一。

.PARAMETER Path
JSONファイルのパス

.PARAMETER Data
書き込むデータ（ハッシュテーブル、配列、オブジェクト）

.PARAMETER Depth
JSON変換の深さ（デフォルト: 10）

.PARAMETER CreateDirectory
親ディレクトリが存在しない場合に作成する（デフォルト: $true）

.PARAMETER Silent
$trueの場合、成功メッセージを表示しない（デフォルト: $false）

.EXAMPLE
Write-JsonSafe -Path "C:\path\to\file.json" -Data $myData

.EXAMPLE
Write-JsonSafe -Path $jsonPath -Data $myData -Depth 5 -Silent $true
#>
function Write-JsonSafe {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true)]
        [object]$Data,

        [Parameter(Mandatory=$false)]
        [int]$Depth = 10,

        [Parameter(Mandatory=$false)]
        [bool]$CreateDirectory = $true,

        [Parameter(Mandatory=$false)]
        [bool]$Silent = $false
    )

    try {
        # 親ディレクトリの確認・作成
        $parentDir = Split-Path -Parent $Path
        if ($parentDir -and -not (Test-Path -Path $parentDir)) {
            if ($CreateDirectory) {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                if (-not $Silent) {
                    Write-Host "[INFO] ディレクトリを作成しました: $parentDir" -ForegroundColor Cyan
                }
            } else {
                throw "親ディレクトリが存在しません: $parentDir"
            }
        }

        # JSON変換と書き込み
        $jsonContent = $Data | ConvertTo-Json -Depth $Depth -Compress:$false
        $jsonContent | Set-Content -Path $Path -Encoding UTF8 -Force

        if (-not $Silent) {
            Write-Host "[INFO] JSON書き込み成功: $Path" -ForegroundColor Green
        }

        return $true
    } catch {
        if (-not $Silent) {
            Write-Host "[ERROR] JSON書き込みエラー: $Path" -ForegroundColor Red
            Write-Host "        エラー詳細: $_" -ForegroundColor Red
        }
        throw "JSON書き込みに失敗しました: $_"
    }
}

<#
.SYNOPSIS
JSONファイルの存在を確認する

.DESCRIPTION
Test-Pathのラッパー関数。オプションでログ出力。

.PARAMETER Path
JSONファイルのパス

.PARAMETER Silent
$trueの場合、メッセージを表示しない（デフォルト: $true）

.EXAMPLE
if (Test-JsonPath -Path $jsonPath) { ... }

.EXAMPLE
Test-JsonPath -Path $jsonPath -Silent $false
#>
function Test-JsonPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [bool]$Silent = $true
    )

    $exists = Test-Path -Path $Path

    if (-not $Silent) {
        if ($exists) {
            Write-Host "[INFO] JSONファイルが存在します: $Path" -ForegroundColor Green
        } else {
            Write-Host "[WARNING] JSONファイルが存在しません: $Path" -ForegroundColor Yellow
        }
    }

    return $exists
}

<#
.SYNOPSIS
JSONストアを初期化する

.DESCRIPTION
コード.jsonの初期化に使用する共通関数。
ファイルが存在しない場合のみ、初期構造を作成する。

.PARAMETER Path
JSONファイルのパス

.PARAMETER InitialData
初期データ（デフォルト: 最後のID=0、エントリ=空ハッシュ）

.PARAMETER Silent
$trueの場合、メッセージを表示しない（デフォルト: $false）

.EXAMPLE
Initialize-JsonStore -Path $global:jsonパス

.EXAMPLE
Initialize-JsonStore -Path $path -InitialData @{key="value"}
#>
function Initialize-JsonStore {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [hashtable]$InitialData = @{
            "最後のID" = 0
            "エントリ" = @{}
        },

        [Parameter(Mandatory=$false)]
        [bool]$Silent = $false,

        [Parameter(Mandatory=$false)]
        [bool]$ValidateStructure = $true
    )

    $shouldInitialize = $false

    # ファイルが存在しない場合は初期化
    if (-not (Test-JsonPath -Path $Path -Silent $true)) {
        $shouldInitialize = $true
        if (-not $Silent) {
            Write-Host "[INFO] JSONファイルが存在しないため初期化します: $Path" -ForegroundColor Cyan
        }
    }
    # ファイルが存在する場合、構造を検証（ValidateStructure=trueの場合）
    elseif ($ValidateStructure) {
        try {
            # 直接Get-Contentで読み込む（循環参照を避けるため）
            $jsonContent = Get-Content -Path $Path -Raw -Encoding UTF8 -ErrorAction Stop
            $existing = $jsonContent | ConvertFrom-Json

            # 必須プロパティのチェック
            $hasRequiredProps = $true
            foreach ($key in $InitialData.Keys) {
                if (-not ($existing.PSObject.Properties.Name -contains $key)) {
                    $hasRequiredProps = $false
                    if (-not $Silent) {
                        Write-Host "[WARNING] JSONに必須プロパティ '$key' がありません" -ForegroundColor Yellow
                    }
                    break
                }
            }

            if (-not $hasRequiredProps) {
                $shouldInitialize = $true
                if (-not $Silent) {
                    Write-Host "[INFO] JSON構造が不正なため再初期化します: $Path" -ForegroundColor Cyan
                }
            }
        }
        catch {
            $shouldInitialize = $true
            if (-not $Silent) {
                Write-Host "[WARNING] JSON読み込みエラーのため再初期化します: $_" -ForegroundColor Yellow
            }
        }
    }

    # 初期化が必要な場合
    if ($shouldInitialize) {
        # 親ディレクトリが存在しない場合は作成
        $parentDir = Split-Path -Parent $Path
        if ($parentDir -and -not (Test-Path -Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        # 初期データをJSONとして保存
        $InitialData | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8 -Force

        if (-not $Silent) {
            Write-Host "[INFO] JSONストアを初期化しました: $Path" -ForegroundColor Green
        }

        return $true
    }
    else {
        if (-not $Silent) {
            Write-Host "[INFO] JSONストアは既に正しい構造で存在します: $Path" -ForegroundColor Cyan
        }

        return $false
    }
}

<#
.SYNOPSIS
JSONファイルから指定されたキーの値を取得する

.DESCRIPTION
Read-JsonSafeを使用してJSONファイルを読み込み、指定されたキーの値を返す。

.PARAMETER jsonFilePath
JSONファイルのパス

.PARAMETER keyName
取得したいキー名

.EXAMPLE
$folderPath = 取得-JSON値 -jsonFilePath "$スクリプトPath\03_history\メイン.json" -keyName "フォルダパス"
#>
function 取得-JSON値 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$jsonFilePath,

        [Parameter(Mandatory=$true)]
        [string]$keyName
    )

    # JSONファイルを読み込み（共通関数使用）
    $jsonContent = Read-JsonSafe -Path $jsonFilePath -Required $true -Silent $false

    if (-not $jsonContent) {
        throw "指定されたファイルが見つかりません: $jsonFilePath"
    }

    # 指定されたキーの値を取得
    if ($jsonContent.PSObject.Properties[$keyName]) {
        return $jsonContent.$keyName
    } else {
        throw "指定されたキーがJSONに存在しません: $keyName"
    }
}

# ================================================================
# 使用例（コメントアウト）
# ================================================================
<#
# 読み込み例
$data = Read-JsonSafe -Path "C:\path\to\file.json"
if ($data) {
    Write-Host "データ読み込み成功"
}

# 書き込み例
$myData = @{
    name = "test"
    values = @(1, 2, 3)
}
Write-JsonSafe -Path "C:\path\to\output.json" -Data $myData

# 初期化例
Initialize-JsonStore -Path $global:jsonパス

# 値取得例
$folderPath = 取得-JSON値 -jsonFilePath "$スクリプトPath\03_history\メイン.json" -keyName "フォルダパス"
#>
