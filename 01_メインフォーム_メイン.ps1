
# タイトル: 複数のボタンに独立したドラッグ＆ドロップを設定する

$global:グループモード = 0

$global:青色 = [System.Drawing.Color]::FromArgb(200, 220, 255)

$global:ピンク青色 = [System.Drawing.Color]::FromArgb(227, 206, 229)

$global:ピンク赤色 = [System.Drawing.Color]::FromArgb(252, 160, 158)

# スクリプトの実行ディレクトリを変更（スクリプトの場所を基準にする）
# 注: $PSScriptRoot はスクリプトが配置されているディレクトリを自動的に取得
if ($PSScriptRoot) {
    Set-Location -Path $PSScriptRoot
} else {
    # スクリプトが直接実行されていない場合のフォールバック
    Set-Location -Path (Split-Path -Parent $MyInvocation.MyCommand.Path)
}



$スクリプトPath = $PSScriptRoot # 現在のスクリプトのディレクトリを変数に格納
$MainpsName = $MyInvocation.MyCommand.Name#メインスクリプト名取得
Get-ChildItem -Path "$スクリプトPath\" -Filter "*.ps1" | Where-Object { $_.Name -ne $MainpsName } | ForEach-Object {. $_.FullName} # フォルダ内のすべてのps1ファイルを取得し、メインスクリプトを除いて読み込む

$codeFolderPath = Join-Path -Path $スクリプトPath -ChildPath "01_code" # 01_codeフォルダ内の.ps1ファイルを取得し、メインスクリプトを除外

write-host "aa" $codeFolderPath

Get-ChildItem -Path $codeFolderPath -Filter "*.ps1" | Where-Object { $_.Name -ne $MainpsName } | ForEach-Object {. $_.FullName }

$メインPath = Split-Path $スクリプトPath # ひとつ上の階層のパスを取得


JSON初回

# 関数の呼び出し例
$global:folderPath = 取得-JSON値 -jsonFilePath "$スクリプトPath\個々の履歴\メイン.json" -keyName "フォルダパス"

write-host "aaa" $global:folderPath

$global:JSONPath = "$global:folderPath\variables.json"

# Windows Formsを利用するためのアセンブリを読み込み
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DPIHelper {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
"@
    # DPIスケーリングを無効化
[DPIHelper]::SetProcessDPIAware()

# グローバル変数の宣言
$global:ボタンカウンタ = 1                # 生成されるボタンのカウンタ
$global:ドラッグ中のボタン = $null         # ドラッグ中のボタン
$global:黄色ボタングループカウンタ = 1000   # 黄色ボタンのグループIDカウンタ（ループ用・1000番台）
$global:緑色ボタングループカウンタ = 2000   # 緑色ボタンのグループIDカウンタ（条件分岐用・2000番台）
$global:drawObjects = @()                  # 描画オブジェクトを保持するリスト

#========== メインコード ==========

$Global:表示スクリプト座標 = @{ X = 0; Y = 0 }

$Global:Pink選択中 = $false

# グローバル変数をオブジェクトの配列として定義
$Global:Pink選択配列 = @()

for ($A = 0; $A -le 6; $A++) {
    $Global:Pink選択配列 += [PSCustomObject]@{
        レイヤー = $A
        Y座標    = 0
        値        = 0
        展開ボタン        = 0
    }
}



$Global:現在展開中のスクリプト名 = ""


# フォームを生成
$メインフォーム = 00_フォームを作成する -幅 1400 -高さ 900


# フォーム生成直後に通常表示を強制
$メインフォーム.WindowState   = [System.Windows.Forms.FormWindowState]::Normal  # 通常
$メインフォーム.StartPosition = 'CenterScreen'                                   # 任意
$メインフォーム.ShowInTaskbar = $true                                             # 念のため


                
#$ボタン02 = 00_メインにボタンを作成する -コンテナ $メインフォーム  -テキスト "Group" -ボタン名 "002" -幅 80 -高さ 40 -X位置 860 -Y位置 300 -枠線 0 -背景色  ([System.Drawing.Color]::FromArgb(255, 255, 255)) -フォントサイズ 8 -クリックアクション $ボタン2アクション

#$ボタン1 = 00_メインにボタンを作成する -コンテナ $メインフォーム  -テキスト "レイヤー化`n→" -ボタン名 "001" -幅 80 -高さ 40 -X位置 860 -Y位置 350 -枠線 0 -背景色  ([System.Drawing.Color]::FromArgb(255, 255, 255)) -フォントサイズ 8 -クリックアクション $ボタン2アクション

#$ボタンA1 = 00_メインにボタンを作成する -コンテナ $メインフォーム  -テキスト "テスト" -ボタン名 "005" -幅 80 -高さ 40 -X位置 860 -Y位置 400 -枠線 0 -背景色  ([System.Drawing.Color]::FromArgb(255, 255, 255)) -フォントサイズ 8 -クリックアクション $ボタン2アクション

$ボタン03 = 00_メインにボタンを作成する -コンテナ $メインフォーム  -テキスト "▶" -ボタン名 "003右" -幅 40 -高さ 20 -X位置 900 -Y位置 40 -枠線 0 -背景色  ([System.Drawing.Color]::FromArgb(255, 255, 255)) -フォントサイズ 8 -クリックアクション $ボタン2アクション
$ボタン04 = 00_メインにボタンを作成する -コンテナ $メインフォーム  -テキスト "◀" -ボタン名 "004左" -幅 40 -高さ 20 -X位置 850 -Y位置 40 -枠線 0 -背景色  ([System.Drawing.Color]::FromArgb(255, 255, 255)) -フォントサイズ 8 -クリックアクション $ボタン2アクション


# コマンドを定義するハッシュテーブル #これつかってる？
$コマンド = @{
    'File.New1'    = { 実行イベント }
    'File.New2'    = { 変数イベント }
    'folder.New'    = { フォルダ作成イベント }
   　'folder.change'    = { フォルダ切替イベント }
    
    'File.New'    = { [System.Windows.Forms.MessageBox]::Show("新規が選択されました。", "ツールバーアクション") }
    'File.Open'   = { [System.Windows.Forms.MessageBox]::Show("開くが選択されました。", "ツールバーアクション") }
    'File.Exit'   = { $メインフォーム.Close() }
    'Edit.Copy'   = { [System.Windows.Forms.MessageBox]::Show("コピーが選択されました。", "ツールバーアクション") }
    'Edit.Paste'  = { [System.Windows.Forms.MessageBox]::Show("貼り付けが選択されました。", "ツールバーアクション") }
    'Help.About'  = { [System.Windows.Forms.MessageBox]::Show("このアプリケーションについて。", "ツールバーアクション") }
}

# メニュー構造を定義する
$メニュー構造 = @(
    @{
        名前         = "実行"
        ツールチップ = "スクリプトを実行する機能を提供します。"
        項目         = @(
            @{ テキスト = "実行"; アクション = { 実行イベント } }
        )
    },
    @{
        名前         = "変数"
        ツールチップ = "変数の管理や設定を行います。"
        項目         = @(
            @{ テキスト = "変数管理"; アクション = { 変数イベント } }
        )
    },
    @{
        名前         = "folder切替"
        ツールチップ = "フォルダや設定の切り替えを行います。"
        項目         = @(
            @{ テキスト = "作成"; アクション = { フォルダ作成イベント } }
            @{ テキスト = "切替"; アクション = { フォルダ切替イベント } }
            @{ テキスト = "終了"; アクション = { Write-Host "終了がクリックされました" } }
        )
    },
    @{
        名前         = "ファイル"
        ツールチップ = "ファイルの操作を行います。"
        項目         = @(
            @{ テキスト = "新規"; アクション = { Write-Host "新規がクリックされました" } }
            @{ テキスト = "開く"; アクション = { Write-Host "開くがクリックされました" } }
            @{ テキスト = "終了"; アクション = { Write-Host "終了がクリックされました" } }
        )
    },
    @{
        名前         = "編集"
        ツールチップ = "編集操作を行います。"
        項目         = @(
            @{ テキスト = "コピー"; アクション = { Write-Host "コピーがクリックされました" } }
            @{ テキスト = "貼り付け"; アクション = { Write-Host "貼り付けがクリックされました" } }
        )
    },
    @{
        名前         = "ヘルプ"
        ツールチップ = "アプリケーションの情報を表示します。"
        項目         = @(
            @{ テキスト = "このアプリケーションについて"; アクション = { Write-Host "ヘルプがクリックされました" } }
        )
    }
)




ツールバーを追加 -フォーム $メインフォーム -メニュー構造 $メニュー構造


フォームにラベル追加 -フォーム $メインフォーム -テキスト "ノード操作" -X座標 190 -Y座標 125

フォームにラベル追加 -フォーム $メインフォーム -テキスト "メイン操作" -X座標 190 -Y座標 40

フォームにラベル追加 -フォーム $メインフォーム -テキスト "メインパネル" -X座標 650 -Y座標 40
フォームにラベル追加 -フォーム $メインフォーム -テキスト "プレビューパネル" -X座標 1050 -Y座標 40

フォームにラベル追加 -フォーム $メインフォーム -テキスト "説明" -X座標 200 -Y座標 620
フォームにラベル追加 -フォーム $メインフォーム -テキスト "→" -X座標 480 -Y座標 350

# グローバル変数の宣言
$Global:不可視左の左パネル = $null
$Global:可視左パネル = $null
$Global:可視右パネル = $null
$Global:不可視右の右パネル = $null

# $Global:表示スクリプト座標 は既に行64で定義済み（重複削除）

$Global:レイヤー階層の深さ　= 1

#$Global:表示スクリプト座標.X# X座標にアクセス
#$Global:表示スクリプト座標.Y# Y座標にアクセス


$global:レイヤー0 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ 750 -X位置 550 -Y位置 70 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(255, 255, 255))  -フレーム名 "0" -枠線あり $true

$global:レイヤー1 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ 750 -X位置 550 -Y位置 70 -Visible $true -背景色 ([System.Drawing.Color]::FromArgb(255, 255, 255))  -フレーム名 "1" -枠線あり $true
00_フレームパネルにラベルを追加する -フレームパネル $global:レイヤー1 -ラベルテキスト "レイヤー1" -X位置 120 -Y位置 0 -フォント (New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)) -フォント色 ([System.Drawing.Color]::Blue)
$global:レイヤー2 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ 750 -X位置 940 -Y位置 70 -Visible $true -背景色 ([System.Drawing.Color]::FromArgb(255, 255, 255))  -フレーム名 "2" -枠線あり $true
00_フレームパネルにラベルを追加する -フレームパネル $global:レイヤー2 -ラベルテキスト "レイヤー2" -X位置 120 -Y位置 0 -フォント (New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)) -フォント色 ([System.Drawing.Color]::Blue)
$global:レイヤー3 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ 750 -X位置 1330 -Y位置 70 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(255, 255, 255))  -フレーム名 "3" -枠線あり $true
00_フレームパネルにラベルを追加する -フレームパネル $global:レイヤー3 -ラベルテキスト "レイヤー3" -X位置 120 -Y位置 0 -フォント (New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)) -フォント色 ([System.Drawing.Color]::Blue)
$global:レイヤー4 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ 750 -X位置 1330 -Y位置 70 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(255, 255, 255))  -フレーム名 "4" -枠線あり $true
00_フレームパネルにラベルを追加する -フレームパネル $global:レイヤー4 -ラベルテキスト "レイヤー4" -X位置 120 -Y位置 0 -フォント (New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)) -フォント色 ([System.Drawing.Color]::Blue)
$global:レイヤー5 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ 750 -X位置 1330 -Y位置 70 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(255, 255, 255))  -フレーム名 "5" -枠線あり $true
00_フレームパネルにラベルを追加する -フレームパネル $global:レイヤー5 -ラベルテキスト "レイヤー5" -X位置 120 -Y位置 0 -フォント (New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)) -フォント色 ([System.Drawing.Color]::Blue)

$global:レイヤー6 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ 750 -X位置 1330 -Y位置 70 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(255, 255, 255))  -フレーム名 "6" -枠線あり $true

$Global:不可視左の左パネル = $global:レイヤー0
$Global:可視左パネル = $global:レイヤー1
$Global:可視右パネル = $global:レイヤー2
$Global:不可視右の右パネル = $global:レイヤー3




function デバッグJSONファイル {
    param (
        [string]$jsonPath  # JSONファイルのパス
    )

    # JSONデータの読み込み
    try {
        $json = Get-Content $jsonPath | ConvertFrom-Json
        write-host "JSONファイルを正常に読み込みました。"  # 読み込み成功のメッセージ
    }
    catch {
        write-host "JSONファイルの読み込みに失敗しました。"  # 読み込み失敗メッセージ
        return
    }

    # JSONの中身を表示
    write-host "JSONの内容:"
    $json | Format-List

    # エントリが存在する場合は、それを確認する
    if ($json.PSObject.Properties["エントリ"]) {
        write-host "`n'エントリ' セクションの内容:"
        $json.エントリ | Format-List
    } else {
        write-host "'エントリ' セクションが見つかりませんでした。"
    }

    # 最後のIDを表示
    if ($json.PSObject.Properties["最後のID"]) {
        write-host "`n'最後のID': $($json.最後のID)"
    } else {
        write-host "'最後のID' が見つかりませんでした。"
    }
}

# 使用例（デバッグ用のため本番では無効化）
# $jsonPath1 = "C:\Users\hello\Documents\WindowsPowerShell\chord\RPA-UI2\個々の履歴\AAAAAA111\コード.json"
# デバッグJSONファイル -jsonPath $jsonPath1




$global:説明フレーム = 00_フレームを作成する -フォーム $メインフォーム -幅 450 -高さ 200 -X位置 10 -Y位置 650 -Visible $true -背景色 ([System.Drawing.Color]::FromArgb(255, 255, 255))  -枠線あり $true

# 説明フレームに説明用のLabelを追加
$global:説明ラベル = New-Object System.Windows.Forms.Label
$global:説明ラベル.AutoSize = $false
$global:説明ラベル.Size = New-Object System.Drawing.Size(435, 185)  # フレームサイズに合わせる
$global:説明ラベル.Location = New-Object System.Drawing.Point(10, 10)
$global:説明ラベル.Text = "ここに説明文が表示されます。"
$global:説明ラベル.Font = New-Object System.Drawing.Font("MS UI Gothic", 12)
$global:説明ラベル.TextAlign = "TopLeft"
#$global:説明ラベル.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$global:説明ラベル.BorderStyle = [System.Windows.Forms.BorderStyle]::None

# 説明フレームにLabelを追加
$global:説明フレーム.Controls.Add($global:説明ラベル)

# メインフレームのPaintイベントを設定
00_メインフレームパネルのPaintイベントを設定する -フレームパネル $Global:可視左パネル

# メインフレームのDragEnterイベントを設定
00_フレームのDragEnterイベントを設定する -フレーム $Global:可視左パネル

# メインフレームのDragDropイベントを設定
00_フレームのDragDropイベントを設定する -フレーム $Global:可視左パネル


$メイン高さ　= 450
$メインY位置　= 150

# 操作フレーム（左側）を生成（イベントハンドラーは設定しない）
$操作フレームパネル1= 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ $メイン高さ -X位置 150 -Y位置 $メインY位置 -Visible $true -背景色 ([System.Drawing.Color]::FromArgb(180, 180, 180))
$操作フレームパネル2 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ $メイン高さ -X位置 150 -Y位置 $メインY位置 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(250, 215, 220))
$操作フレームパネル3 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ $メイン高さ -X位置 150 -Y位置 $メインY位置 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(210, 255, 240))
$操作フレームパネル4 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ $メイン高さ -X位置 150 -Y位置 $メインY位置 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(225, 245, 230))
$操作フレームパネル5 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ $メイン高さ -X位置 150 -Y位置 $メインY位置 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(250, 250, 230))
$操作フレームパネル6 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ $メイン高さ -X位置 150 -Y位置 $メインY位置 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(240, 230, 250))
$操作フレームパネル7 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ $メイン高さ -X位置 150 -Y位置 $メインY位置 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(245, 245, 245))
$操作フレームパネル8 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ $メイン高さ -X位置 150 -Y位置 $メインY位置 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(220, 235, 255))
$操作フレームパネル9 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ $メイン高さ -X位置 150 -Y位置 $メインY位置 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(255, 250, 220))
$操作フレームパネル10 = 00_フレームを作成する -フォーム $メインフォーム -幅 300 -高さ $メイン高さ -X位置 150 -Y位置 $メインY位置 -Visible $false -背景色 ([System.Drawing.Color]::FromArgb(255, 235, 240))

$操作フレームパネルA1= 00_フレームを作成する -フォーム $メインフォーム -幅 450 -高さ 50 -X位置 10 -Y位置 70 -Visible $true -背景色 ([System.Drawing.Color]::FromArgb(255, 255, 255)) -枠線あり $true



# 1. JSONストアの初期化（初回のみ実行）
JSONストアを初期化

$切替上部y = 150

$切替1 = 00_ボタンを作成する -コンテナ $メインフォーム -テキスト "制御構文" -幅 140 -高さ 30 -X位置 10 -Y位置 $切替上部y -背景色 ([System.Drawing.Color]::FromArgb(180, 180, 180)) -ドラッグ可能 $false -フォントサイズ 12
$切替2 = 00_ボタンを作成する -コンテナ $メインフォーム -テキスト "マウス操作" -幅 140 -高さ 30 -X位置 10 -Y位置 ($切替上部y +30) -背景色 ([System.Drawing.Color]::FromArgb(250, 215, 220)) -ドラッグ可能 $false -フォントサイズ 12
$切替3 = 00_ボタンを作成する -コンテナ $メインフォーム -テキスト "キーボード操作" -幅 140 -高さ 30 -X位置 10 -Y位置  ($切替上部y +60) -背景色 ([System.Drawing.Color]::FromArgb(210, 255, 240)) -ドラッグ可能 $false -フォントサイズ 12
$切替4 = 00_ボタンを作成する -コンテナ $メインフォーム -テキスト "UIAutomation" -幅 140 -高さ 30 -X位置 10 -Y位置  ($切替上部y +90) -背景色 ([System.Drawing.Color]::FromArgb(225, 245, 230)) -ドラッグ可能 $false -フォントサイズ 12
$切替5 = 00_ボタンを作成する -コンテナ $メインフォーム -テキスト "ファイル操作" -幅 140 -高さ 30 -X位置 10 -Y位置  ($切替上部y +120) -背景色 ([System.Drawing.Color]::FromArgb(250, 250, 230)) -ドラッグ可能 $false -フォントサイズ 12
$切替6 = 00_ボタンを作成する -コンテナ $メインフォーム -テキスト "データ処理" -幅 140 -高さ 30 -X位置 10 -Y位置  ($切替上部y +150) -背景色 ([System.Drawing.Color]::FromArgb(240, 230, 250)) -ドラッグ可能 $false -フォントサイズ 12
$切替7 = 00_ボタンを作成する -コンテナ $メインフォーム -テキスト "スクリプト実行" -幅 140 -高さ 30 -X位置 10 -Y位置  ($切替上部y +180) -背景色 ([System.Drawing.Color]::FromArgb(245, 245, 245)) -ドラッグ可能 $false -フォントサイズ 12
$切替8 = 00_ボタンを作成する -コンテナ $メインフォーム -テキスト "Excel処理" -幅 140 -高さ 30 -X位置 10 -Y位置  ($切替上部y +210) -背景色 ([System.Drawing.Color]::FromArgb(220, 235, 255)) -ドラッグ可能 $false -フォントサイズ 12
$切替9 = 00_ボタンを作成する -コンテナ $メインフォーム -テキスト "ウインドウ操作" -幅 140 -高さ 30 -X位置 10 -Y位置  ($切替上部y +240) -背景色 ([System.Drawing.Color]::FromArgb(255, 250, 220)) -ドラッグ可能 $false -フォントサイズ 12
$切替10 = 00_ボタンを作成する -コンテナ $メインフォーム -テキスト "画像処理" -幅 140 -高さ 30 -X位置 10 -Y位置  ($切替上部y +270) -背景色 ([System.Drawing.Color]::FromArgb(255, 235, 240)) -ドラッグ可能 $false -フォントサイズ 12



function 非表示 {
$操作フレームパネル1.Visible = $false
$操作フレームパネル2.Visible = $false
$操作フレームパネル3.Visible = $false
$操作フレームパネル4.Visible = $false
$操作フレームパネル5.Visible = $false
$操作フレームパネル6.Visible = $false
$操作フレームパネル7.Visible = $false
$操作フレームパネル8.Visible = $false
$操作フレームパネル9.Visible = $false
$操作フレームパネル10.Visible = $false

}

if ($切替1 -ne $null) { $切替1.Add_Click({ 非表示; $操作フレームパネル1.Visible = $true }) }
if ($切替2 -ne $null) { $切替2.Add_Click({ 非表示; $操作フレームパネル2.Visible = $true }) }
if ($切替3 -ne $null) { $切替3.Add_Click({ 非表示; $操作フレームパネル3.Visible = $true }) }
if ($切替4 -ne $null) { $切替4.Add_Click({ 非表示; $操作フレームパネル4.Visible = $true }) }
if ($切替5 -ne $null) { $切替5.Add_Click({ 非表示; $操作フレームパネル5.Visible = $true }) }
if ($切替6 -ne $null) { $切替6.Add_Click({ 非表示; $操作フレームパネル6.Visible = $true }) }
if ($切替7 -ne $null) { $切替7.Add_Click({ 非表示; $操作フレームパネル7.Visible = $true }) }
if ($切替8 -ne $null) { $切替8.Add_Click({ 非表示; $操作フレームパネル8.Visible = $true }) }
if ($切替9 -ne $null) { $切替9.Add_Click({ 非表示; $操作フレームパネル9.Visible = $true }) }
if ($切替10 -ne $null) { $切替10.Add_Click({ 非表示; $操作フレームパネル10.Visible = $true }) }

# 切替ボタンに対応する説明文を定義
$global:切替ボタン説明 = @{
    "制御構文"     = "制御構文に関する説明文をここに記載します。"
    "マウス操作"   = "マウス操作に関する説明文をここに記載します。"
    "キーボード操作" = "キーボード操作に関する説明文をここに記載します。"
    "UIAutomation" = "UIAutomationに関する説明文をここに記載します。"
    "ファイル操作" = "ファイル操作に関する説明文をここに記載します。"
    "データ処理"   = "データ処理に関する説明文をここに記載します。"
    "スクリプト実行" = "スクリプト実行に関する説明文をここに記載します。"
}

# 作成ボタンの説明文
$global:作成ボタン説明 = @{
    "1-1" = "順次処理に関する説明文をここに記載します。"
    "1-2" = "条件分岐に関する説明文をここに記載します。"
    "1-3" = "ループ処理に関する説明文をここに記載します。"
    "1-4" = "順次処理（別バージョン）に関する説明文をここに記載します。"
    "2-1" = "マウス座標取得（左クリック）に関する説明文をここに記載します。"
    "2-2" = "マウス移動に関する説明文をここに記載します。"
    "3-1" = "キー操作に関する説明文をここに記載します。"
    "3-2" = "キー入力に関する説明文をここに記載します。"
    "4-1" = "UIに関する説明文をここに記載します。"
    # 必要に応じて追加してください
}


# 外部スクリプト内の関数を呼び出して切替ボタンのイベントを設定
$切替ボタン一覧 = @($切替1, $切替2, $切替3, $切替4, $切替5, $切替6, $切替7)
$切替テキスト一覧 = @("制御構文", "マウス操作", "キーボード操作", "UIAutomation", "ファイル操作", "データ処理", "スクリプト実行")
切替ボタンイベント $切替ボタン一覧 -SwitchTexts $切替テキスト一覧

# 外部スクリプト内の関数を呼び出して実行ボタンのイベントを設定
#実行ボタンイベント -Button $実行ボタン

#変数ボタンイベント -Button $変数ボタン

#フォルダ作成イベント -Button $フォルダ作成
$ボタン1 = 00_メインにボタンを作成する -コンテナ $操作フレームパネルA1  -テキスト "レイヤー化" -ボタン名 "001" -幅 80 -高さ 40 -X位置 60 -Y位置 5 -枠線 0 -背景色  ([System.Drawing.Color]::FromArgb(255, 255, 255)) -フォントサイズ 8 -クリックアクション $ボタン2アクション
$ボタン全削除 = 00_メインにボタンを作成する -コンテナ $操作フレームパネルA1  -テキスト "全削除" -ボタン名 "CLEAR_ALL" -幅 50 -高さ 40 -X位置 145 -Y位置 5 -枠線 0 -背景色  ([System.Drawing.Color]::FromArgb(255, 200, 200)) -フォントサイズ 8 -クリックアクション $ボタン2アクション
$ボタンA2 = 00_メインにボタンを作成する -コンテナ $操作フレームパネルA1  -テキスト "変数" -ボタン名 "A001" -幅 80 -高さ 40 -X位置 200 -Y位置 5 -枠線 0 -背景色  ([System.Drawing.Color]::FromArgb(255, 255, 255)) -フォントサイズ 8 -クリックアクション $ボタン2アクション
#↑挙動はどこで設定している？


#フォルダ切替イベント -Button $フォルダ切替




$jsonData = Get-Content -Path ".\ボタン設定.json" | ConvertFrom-Json

$前回の処理番号左側 = $null
$script:初期Y = 10

foreach ($ボタン in $jsonData) {
    $背景色 = [System.Drawing.Color]::FromName($ボタン.背景色)
    $コンテナ = Get-Variable -Name $ボタン.コンテナ -Scope Global -ErrorAction SilentlyContinue

    # 処理番号の左側を取得
    $処理番号左側 = $ボタン.処理番号 -split '-' | Select-Object -First 1
    Write-Host "処理番号の左側: $処理番号左側"

    # 処理番号の左側が変わったタイミングで初期Yをリセット
    if ($処理番号左側 -ne $前回の処理番号左側) {
        Write-Host "処理番号が変わったため、初期Yをリセット"
        $script:初期Y = 10
    }

    # Y位置を設定して次回のために増加
    $Y位置 = $script:初期Y
    $script:初期Y += 40

    if ($コンテナ) {
        作成ボタンとイベント設定 -処理番号 $ボタン.処理番号 -テキスト $ボタン.テキスト `
            -ボタン名 $ボタン.ボタン名 -背景色 $背景色 `
            -コンテナ $コンテナ.Value -Y位置 $Y位置 -説明 $ボタン.説明
    }

    # 前回の処理番号を更新
    $前回の処理番号左側 = $処理番号左側
}


# 【タイトル: 出力-ボタン情報 JSON読込対応版 Ver1.0】
# タイトル: 出力-ボタン情報 JSONキー1専用版  Ver1.0
function 出力-ボタン情報 {
    param (
        [string]$jsonFilePath  # JSONファイルのパス
    )

    #------------------------------------------------------------
    # ① JSONファイルの存在確認と読込
    #------------------------------------------------------------
    if (-not (Test-Path $jsonFilePath)) {
        throw "JSONファイルが見つかりません: $jsonFilePath"
    }

    # -Raw を付けて一括読込 → ConvertFrom-Json
    $jsonData = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json

    #------------------------------------------------------------
    # ② 階層(1～5)ごとの構成配列をループ
    #    ★ここで階層名が '1' でなければスキップする★
    #------------------------------------------------------------
    foreach ($階層Prop in $jsonData.PSObject.Properties) {

        if ($階層Prop.Name -ne '1') { continue }   # ← 追加行

        $階層番号 = $階層Prop.Name
        $構成配列 = $階層Prop.Value.構成   # 配列 (空の場合もあり)
        if (-not $構成配列) { continue }   # ボタンが無ければ次の階層へ

        foreach ($button in $構成配列) {

            #----------------------------------------------------
            # ③ デバッグ出力
            #----------------------------------------------------
            Write-Host "[階層 $階層番号] ボタン名: $($button.ボタン名) `tY座標: $($button.Y座標) `t順番: $($button.順番) `tボタン色: $($button.ボタン色) `tテキスト: $($button.テキスト) `t処理番号: $($button.処理番号) `t幅: $($button.幅) `t高さ: $($button.高さ)"

            #----------------------------------------------------
            # ④ 色指定を System.Drawing.Color に変換
            #----------------------------------------------------
            $buttonColor = if ($button.ボタン色 -match '^[A-Fa-f0-9]{6}$') {
                [System.Drawing.ColorTranslator]::FromHtml("#$($button.ボタン色)")
            } else {
                [System.Drawing.Color]::FromName($button.ボタン色)
            }

            #----------------------------------------------------
            # ⑤ ボタン生成
            #----------------------------------------------------
            $新ボタン = 00_ボタンを作成する `
                -コンテナ      $Global:可視左パネル `
                -テキスト      $button.テキスト `
                -ボタン名      $button.ボタン名 `
                -幅           $button.幅 `
                -高さ         $button.高さ `
                -X位置         $button.X座標 `
                -Y位置         $button.Y座標 `
                -枠線          1 `
                -背景色        $buttonColor `
                -ドラッグ可能  $true `
                -ボタンタイプ  "ノード" `
                -ボタンタイプ2 $button.script `
                -処理番号      $button.処理番号

            #----------------------------------------------------
            # ⑥ GroupIDを復元（JSONに存在する場合）
            #----------------------------------------------------
            if ($button.PSObject.Properties.Name -contains 'GroupID' -and $button.GroupID -ne $null -and $button.GroupID -ne "") {
                $新ボタン.Tag.GroupID = $button.GroupID
                Write-Host "[復元] GroupID=$($button.GroupID) を設定: $($button.ボタン名)"
            }
        }
    }
}


#---　ボタン生成処理
出力-ボタン情報 -jsonFilePath "$global:folderPath\memory.json"

00_ボタンの上詰め再配置関数 -フレーム $Global:可視左パネル

00_矢印追記処理 -フレームパネル $Global:可視左パネル


# フォームを表示
$メインフォーム.Add_Shown({ $メインフォーム.Activate() })

[void]$メインフォーム.ShowDialog()
