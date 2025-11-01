﻿
function JSON初回 {
# ファイルパスの設定
$スクリプトディレクトリ = $PSScriptRoot
$global:jsonパス = Join-Path -Path $スクリプトディレクトリ -ChildPath "コード.json"



# メイン.json のパスを設定
#$スクリプトディレクトリ = $PSScriptRoot
#$メインJSONパス = Join-Path -Path $スクリプトディレクトリ -ChildPath "メイン.json"

# メイン.json のパスを設定
$スクリプトディレクトリ = $PSScriptRoot
if (-not $スクリプトディレクトリ) {
    #Write-Host "スクリプトディレクトリが取得できません。スクリプトは .ps1 ファイルとして保存され、直接実行されている必要があります。"
    return
}



$メインJSONパス = "$スクリプトディレクトリ\個々の履歴\メイン.json" 

# メイン.json の存在確認
if (-not (Test-Path -Path $メインJSONパス)) {
    #Write-Host "メイン.json が存在しません: $メインJSONパス"
    return
}

# メイン.json の内容を読み込む（共通関数使用）
$メインデータ = Read-JsonSafe -Path $メインJSONパス -Required $false -Silent $true
if (-not $メインデータ) {
    #Write-Host "メイン.json の読み込みに失敗しました。"
    return
}
if (-not $メインデータ.フォルダパス) {
    #Write-Host "メイン.json に新規フォルダパスが設定されていません。"
    return
}
$新規フォルダパス = $メインデータ.フォルダパス

# コード.json のパスを設定
$global:jsonパス = Join-Path -Path $新規フォルダパス -ChildPath "コード.json"

# コード.json の存在確認
if (-not (Test-Path -Path $global:jsonパス)) {
    #Write-Host "コード.json が $新規フォルダパス に存在しません。"
    return
}

# コード.json の内容を読み込む（共通関数使用）
$コードデータ = Read-JsonSafe -Path $global:jsonパス -Required $false -Silent $true
if ($コードデータ) {
    #Write-Host "コード.json の内容を正常に読み込みました。"
    $コードデータ
} else {
    #Write-Host "コード.json の読み込みに失敗しました。"
    return
}


}






JSON初回


# JSONストアの初期化関数（共通関数使用）
function JSONストアを初期化 {
    Initialize-JsonStore -Path $global:jsonパス -Silent $true
}

# IDを生成する関数
function IDを生成する {
    param (
        [Parameter(Mandatory = $false)]
        [string]$指定値
    )

    # JSONファイルが存在しない場合は初期化
    if (-Not (Test-Path $global:jsonパス)) {
        JSONストアを初期化
    }

    # JSONファイルを読み込む（共通関数使用）
    $json内容 = Read-JsonSafe -Path $global:jsonパス -Required $true -Silent $true
    if (-not $json内容) {
        Write-Error "JSONファイルの読み込みに失敗しました。"
        return $null
    }

    if ($指定値) {
        if ($指定値 -le $json内容."最後のID") {
            Write-Error "指定されたID ($指定値) は既に使用されています。"
            return $null
        }
        $新しいID = $指定値
    }
    else {
        # 最後のIDをインクリメント
        $新しいID = $json内容."最後のID" + 1
    }

    $json内容."最後のID" = $新しいID

    # JSONファイルに保存（共通関数使用）
    try {
        Write-JsonSafe -Path $global:jsonパス -Data $json内容 -Depth 5 -Silent $true
    }
    catch {
        Write-Error "JSONファイルの更新に失敗しました。"
        return $null
    }

    return $新しいID
}

# 文字列を追加する関数（IDは自動生成）
function エントリを追加 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$文字列
    )

    # 新しいIDを生成
    $ID = IDを生成する
    if (-Not $ID) {
        Write-Error "新しいIDの生成に失敗しました。"
        return
    }

    # `---` で文字列を分割
    $separator = '---'
    $parts = $文字列 -split [Regex]::Escape($separator)

    # JSONファイルを読み込む（共通関数使用）
    $json内容 = Read-JsonSafe -Path $global:jsonパス -Required $true -Silent $true
    if (-not $json内容) {
        Write-Error "JSONファイルの読み込みに失敗しました。"
        return
    }

    # 'エントリ'をハッシュテーブルに変換
    $エントリハッシュ = @{}
    foreach ($プロパティ in $json内容."エントリ".PSObject.Properties) {
        $エントリハッシュ[$プロパティ.Name] = $プロパティ.Value
    }

    # 各部分にサブIDを割り当てて追加
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $subId = "$ID-$($i + 1)"
        $エントリハッシュ[$subId] = $parts[$i].Trim()
        #Write-Host "エントリが追加されました。ID: $subId"
    }

    # 'エントリ'に代入
    $json内容."エントリ" = $エントリハッシュ

    # JSONファイルに保存（共通関数使用）
    try {
        Write-JsonSafe -Path $global:jsonパス -Data $json内容 -Depth 5 -Silent $true
    }
    catch {
        Write-Error "JSONファイルの更新に失敗しました。"
        return
    }

    #Write-Output "ID $ID のエントリが追加されました。"
    return $ID
}


# 他の関数や設定部分は省略


# エントリを削除する関数
function IDでエントリを削除 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ID
    )

    # JSONファイルが存在しない場合
    if (-Not (Test-Path $global:jsonパス)) {
        Write-Error "JSONストアが存在しません。"
        return
    }

    # JSONファイルを読み込む（共通関数使用）
    $json内容 = Read-JsonSafe -Path $global:jsonパス -Required $true -Silent $true
    if (-not $json内容) {
        Write-Error "JSONファイルの読み込みに失敗しました。"
        return
    }

    # エントリキーのパターンを定義（例: "1-1", "1-2", ...）
    $キー正規表現 = "^$ID-\d+$"

    # 既存のエントリを収集
    $既存キー = $json内容."エントリ".PSObject.Properties.Name | Where-Object { $_ -match $キー正規表現 }

    if ($既存キー.Count -eq 0) {
        Write-Warning "指定されたID ($ID) のエントリは存在しません。"
        return
    }

    # 既存のエントリを削除
    foreach ($キー in $既存キー) {
        $json内容."エントリ".PSObject.Properties.Remove($キー) | Out-Null
        #Write-Host "エントリが削除されました。ID: $キー"
    }

    # JSONファイルに保存（共通関数使用）
    try {
        Write-JsonSafe -Path $global:jsonパス -Data $json内容 -Depth 5 -Silent $true
    }
    catch {
        Write-Error "JSONファイルの更新に失敗しました。"
        return
    }

    #Write-Output "ID $ID のエントリを削除しました。"
}

# 他の関数や設定部分は省略




# 文字列を追加する関数（IDを指定可能）
function エントリを追加_指定ID {
    param (
        [Parameter(Mandatory = $true)]
        [string]$文字列,

        [Parameter(Mandatory = $true)]
        [string]$ID
    )

    # 指定されたIDを生成
    #$新しいID = IDを生成する -指定値 $ID

    $新しいID =  $ID


    if (-Not $新しいID) {
        Write-Error "指定されたID ($ID) の生成に失敗しました。"
        return
    }

    # `---` で文字列を分割
    $separator = '---'
    $parts = $文字列 -split [Regex]::Escape($separator)

    # JSONファイルを読み込む（共通関数使用）
    $json内容 = Read-JsonSafe -Path $global:jsonパス -Required $true -Silent $true
    if (-not $json内容) {
        Write-Error "JSONファイルの読み込みに失敗しました。"
        return
    }

    # 'エントリ'をハッシュテーブルに変換
    $エントリハッシュ = @{}
    foreach ($プロパティ in $json内容."エントリ".PSObject.Properties) {
        $エントリハッシュ[$プロパティ.Name] = $プロパティ.Value
    }

    # 各部分にサブIDを割り当てて追加
    for ($i = 0; $i -lt $parts.Count; $i++) {
        $subId = "$ID-$($i + 1)"
        $エントリハッシュ[$subId] = $parts[$i].Trim()
        #Write-Host "エントリが追加されました。ID: $subId"
    }

    # 'エントリ'に代入
    $json内容."エントリ" = $エントリハッシュ

    # JSONファイルに保存（共通関数使用）
    try {
        Write-JsonSafe -Path $global:jsonパス -Data $json内容 -Depth 5 -Silent $true
    }
    catch {
        Write-Error "JSONファイルの更新に失敗しました。"
        return
    }

    #Write-Output "ID $ID のエントリが追加されました。"
    return $ID
}


# IDを使用して文字列を取得する関数
function IDでエントリを取得 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ID
    )

    # JSONファイルが存在しない場合
    if (-Not (Test-Path $global:jsonパス)) {
        Write-Error "JSONストアが存在しません。まずは `JSONストアを初期化` を実行してください。"
        return $null
    }

    # JSONファイルを読み込む（共通関数使用）
    $json内容 = Read-JsonSafe -Path $global:jsonパス -Required $true -Silent $true
    if (-not $json内容) {
        Write-Error "JSONファイルの読み込みに失敗しました。"
        return $null
    }

    if ($json内容."エントリ".PSObject.Properties.Name -contains $ID) {
        # エントリを返す
        return $json内容."エントリ".$ID
    }
    else {
        Write-Warning "指定されたID ($ID) のエントリは存在しません。"
        return $null
    }
}

# すべてのエントリを一覧表示する関数
function 全エントリを表示 {
    # JSONファイルが存在しない場合
    if (-Not (Test-Path $global:jsonパス)) {
        Write-Error "JSONストアが存在しません。まずは `JSONストアを初期化` を実行してください。"
        return
    }

    # JSONファイルを読み込む（共通関数使用）
    $json内容 = Read-JsonSafe -Path $global:jsonパス -Required $true -Silent $true
    if (-not $json内容) {
        Write-Error "JSONファイルの読み込みに失敗しました。"
        return
    }

    # エントリを表示
    if ($json内容."エントリ".Count -eq 0) {
        #Write-Output "エントリは存在しません。"
    }
    else {
        foreach ($エントリ in $json内容."エントリ".GetEnumerator()) {
            #Write-Output "ID: $($エントリ.Key)"
            #Write-Output "内容:`n$($エントリ.Value)"
            #Write-Output "---------------------------"
        }
    }
}

# エントリを削除する関数（重複定義 - この関数は既に上で定義されているため不要）
# 注: この関数定義は185-233行目と重複しています



# IDと新しい文字列を引数にエントリを置換する関数
function IDでエントリを置換 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ID,

        [Parameter(Mandatory = $true)]
        [string]$新しい文字列
    )

    #Write-Host "ID $ID のエントリを置換中..."

    # JSONファイルが存在するか確認
    if (-Not (Test-Path $global:jsonパス)) {
        Write-Error "JSONストアが存在しません。まずは `JSONストアを初期化` を実行してください。"
        return
    }

    # JSONファイルを読み込む（共通関数使用）
    $json内容 = Read-JsonSafe -Path $global:jsonパス -Required $true -Silent $true
    if (-not $json内容) {
        Write-Error "JSONファイルの読み込みに失敗しました。エラー: $_"
        return
    }

    # 'エントリ'ハッシュテーブルを取得
    $エントリハッシュ = @{}
    foreach ($プロパティ in $json内容."エントリ".PSObject.Properties) {
        $エントリハッシュ[$プロパティ.Name] = $プロパティ.Value
    }

    # 指定IDに対応するエントリを置換または追加
    if ($エントリハッシュ.ContainsKey($ID)) {
        #Write-Host "既存のエントリが見つかりました。置換します。"
    } else {
        #Write-Host "新しいエントリを追加します。"
    }

    $エントリハッシュ[$ID] = $新しい文字列.Trim()
    #Write-Host "エントリが追加または置換されました。ID: $ID"

    # 更新された 'エントリ'をJSONに戻す
    $json内容."エントリ" = $エントリハッシュ

    # JSONファイルに保存（共通関数使用）
    try {
        Write-JsonSafe -Path $global:jsonパス -Data $json内容 -Depth 5 -Silent $true
    }
    catch {
        Write-Error "JSONファイルの更新に失敗しました。エラー: $_"
        return
    }

    #Write-Output "ID $ID のエントリが置換されました。"
}




# 自動生成バージョンのIDを生成する関数（サブIDなし）
function IDを自動生成する {

    # JSONファイルが存在しない場合は初期化
    if (-Not (Test-Path $global:jsonパス)) {
        JSONストアを初期化
    }

    # JSONファイルを読み込む（共通関数使用）
    $json内容 = Read-JsonSafe -Path $global:jsonパス -Required $true -Silent $true
    if (-not $json内容) {
        Write-Error "JSONファイルの読み込みに失敗しました。"
        return $null
    }

    # '最後のID' を取得してインクリメント
    $lastID = $json内容."最後のID"

    $newID = ($lastID + 1).ToString()

    # '最後のID' を更新
    $json内容."最後のID" = [int]$newID

    # JSONファイルに保存（共通関数使用）
    try {
        Write-JsonSafe -Path $global:jsonパス -Data $json内容 -Depth 5 -Silent $true
    }
    catch {
        Write-Error "JSONファイルの更新に失敗しました。"
        return $null
    }

    return $newID
}


