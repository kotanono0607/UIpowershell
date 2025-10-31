
function 00_文字列処理内容 {
  param (
    [string]$ボタン名,
    [string]$処理番号,
    [string]$直接エントリ = "",
    [System.Windows.Forms.Button]$ボタン
  )


  # 処理番号に基づいて分岐
$メインフォーム.Hide()



# JSONファイルを読み込み
$jsonData = Get-Content -Path ".\ボタン設定.json" | ConvertFrom-Json

# 処理番号に対応する関数名を取得する辞書を作成
$関数マッピング = @{}
foreach ($entry in $jsonData) {
    $関数マッピング[$entry.処理番号] = $entry.関数名
}

if ($関数マッピング.ContainsKey($処理番号)) {
    $関数名 = $関数マッピング[$処理番号]
    
    # 99-1 の場合の特別処理
    if ($処理番号 -eq "99-1") {
        $entryString = & $関数名 -直接エントリ $直接エントリ
    } else {
        # 通常の関数呼び出し
        $entryString = & $関数名
    }

} else {
    Write-Error "処理番号が未対応です: $処理番号"
    return
}


# $entryString が空でない場合のみ関数を呼び出す
if (-not [string]::IsNullOrEmpty($entryString)) {
    エントリを追加_指定ID -ID $ボタン名 -文字列 $entryString
} else {
    Write-Error "エラー: $entryString は空の文字列です。"
}

$メインフォーム.Show()


    #        [System.Windows.Forms.MessageBox]::Show($ボタン名 , "debug情報表示", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
   エントリを追加_指定ID -ID $ボタン名 -文字列 $entryString -順番 "1"


   #-----------------------------------------レイヤー２処理追加

$最後の文字 = グローバル変数から数値取得　-パネル $Global:可視左パネル 
Write-Host "最後の文字” $最後の文字

    
       # [System.Windows.Forms.MessageBox]::Show($ボタン.BackColor.Name, "debug情報表示", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

if ($最後の文字 -ge 2 ) {　#PINkの場合、統合後のPINKのみ追加
    
  #      [System.Windows.Forms.MessageBox]::Show($ボタン.BackColor.Name + $Global:現在展開中のスクリプト名, "debug情報表示", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
          # ボタン一覧の取得

            $A = [int]$最後の文字
            $A = $A -1　
            $Global:Pink選択配列[$A].展開ボタン

        $ボタン一覧 = 一覧-フレームパネルのボタン一覧 -フレームパネル $Global:可視左パネル 
       $直接エントリ = "AAAA_"  + $ボタン一覧
        $取得したエントリ = $直接エントリ -replace '_', "`r`n"

        IDでエントリを置換 -ID  $Global:Pink選択配列[$A].展開ボタン  -新しい文字列  $取得したエントリ
          Write-Host $Global:現在展開中のスクリプト名 -ForegroundColor Green

        #下は確認 blue
        #$取得したエントリ = IDでエントリを取得 -ID $Global:現在展開中のスクリプト名
       # [System.Windows.Forms.MessageBox]::Show($Global:Pink選択配列[$A].展開ボタン, "debug情報表示", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

       }

    }


function 一覧-フレームパネルのボタン一覧 {
    param (
        [System.Windows.Forms.Panel]$フレームパネル
    )

    # フレームパネル内の全てのコントロールを取得
    $全コントロール = $フレームパネル.Controls

    # ボタンのみをフィルタリングし、Y座標でソート
    $ソート済みボタン = $全コントロール |
                        Where-Object { $_ -is [System.Windows.Forms.Button] } |
                        Sort-Object { $_.Location.Y }

    # ボタンが存在しない場合はメッセージを返す
    if ($ソート済みボタン.Count -eq 0) {
        return "フレームパネル内にボタンが存在しません。"
    }

    # 各ボタンの情報を収集
    $出力リスト = foreach ($ボタン in $ソート済みボタン) {
        "$($ボタン.Name);$($ボタン.BackColor.Name);$($ボタン.Text)"
    }

    # リストを '_' で結合して返す
    return ($出力リスト -join '_')
}
