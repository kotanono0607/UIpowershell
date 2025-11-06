# ローカル変更をmainブランチにプッシュ (Ver 2.0)
# 使い方:
#   .\git-push-local.ps1                              # 自動コミットメッセージ
#   .\git-push-local.ps1 "Feat: 新機能追加"            # カスタムメッセージ
#   $env:PUSH_FORCE=1; .\git-push-local.ps1           # 強制プッシュ許可
#
# 動作:
#   - claudeブランチの場合: 変更をコミット後、mainにマージしてプッシュ
#   - mainブランチの場合: 変更を直接コミット＆プッシュ

param(
    [string]$コミットメッセージ = ""
)

# ===== 設定 =====
$作業パス = "C:\Users\hello\Documents\WindowsPowerShell\chord\RPA-UI2"
$詳細表示 = $true
# ===============

# ===== 実行前の基本設定 =====
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# ===== ユーティリティ =====
function 情報([string]$m){ Write-Host "[情報] $m" -ForegroundColor Green }
function 警告([string]$m){ Write-Warning $m }
function 失敗([string]$m){ throw $m }

function 実行git([string[]]$引数, [switch]$静か){
    $args2 = @('-C', $作業パス) + $引数
    if ($詳細表示){ Write-Host "git $($args2 -join ' ')" -ForegroundColor DarkGray }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $psi.Arguments = [string]::Join(" ", $args2)
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    if (-not $静か) {
        if ($stdout) { Write-Host ($stdout.TrimEnd()) }
        if ($stderr) { Write-Host ($stderr.TrimEnd()) }
    }
    if ($p.ExitCode -ne 0) {
        失敗 ("git 失敗: git {0}`n{1}" -f $psi.Arguments, $stderr)
    }
    return $stdout
}
function 実行git静か([string[]]$引数){ 実行git $引数 -静か | Out-Null }

# ===== 事前チェック =====
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  ローカル変更をGitにプッシュ" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $作業パス)) { 失敗 "作業パスが存在しない: $作業パス" }
if (-not (Test-Path (Join-Path $作業パス ".git"))) { 失敗 ".git が見つかりません: $作業パス" }

情報 "作業ディレクトリ: $作業パス"
Write-Host ""

# ===== メイン処理 =====
try {
    # 1) 現在のブランチを確認
    $現在ブランチ = ([string](実行git @('rev-parse','--abbrev-ref','HEAD') -静か)).Trim()
    情報 "現在のブランチ: $現在ブランチ"

    # 自動プッシュのみに固定（恒久化・引数不要）
    $自動モード = $true


    # 2) mainブランチの場合は確認（自動モードでは確認スキップ）
    if ($現在ブランチ -eq 'main') {
        if (-not $自動モード) {
            Write-Host ""
            Write-Host "【警告】mainブランチに直接コミットします" -ForegroundColor Yellow
            Write-Host "  ローカルの変更がリモートのmainブランチに反映されます。" -ForegroundColor Yellow
            Write-Host ""
            $continue = Read-Host "mainブランチにコミット・プッシュしますか？ (y/N)"
            if ($continue -ne 'y') {
                失敗 "ユーザーによりキャンセルされました"
            }
            情報 "mainブランチへのコミット・プッシュを続行します"
        } else {
            情報 "mainブランチに自動プッシュします"
        }
    }

    # 3) claudeブランチでない場合も確認（自動モードでは確認スキップ）
    if ($現在ブランチ -ne 'main' -and $現在ブランチ -notmatch '^claude/') {
        if (-not $自動モード) {
            警告 "現在のブランチは main または claude/* ではありません: $現在ブランチ"
            $continue = Read-Host "このブランチにコミットしますか？ (y/N)"
            if ($continue -ne 'y') {
                失敗 "ユーザーによりキャンセルされました"
            }
        }
    }

    # 4) リモートから最新情報を取得
    情報 "リモートから最新情報を取得中..."
    実行git静か @('fetch','origin','--prune')

    # 5) 変更の確認
    $status = 実行git @('status','--porcelain') -静か
    $変更あり = -not [string]::IsNullOrWhiteSpace($status)

    if (-not $変更あり) {
        情報 "コミットする変更がありません"

        # claudeブランチの場合は、mainにマージする処理へ
        if ($現在ブランチ -match '^claude/') {
            情報 "claudeブランチの内容をmainにマージします"
            # 変更はないが、マージ処理は続行
        } else {
            Write-Host ""
            情報 "完了（変更なし）"
            exit 0
        }
    }

    # 6) 変更がある場合のみコミット処理を実行
    if ($変更あり) {
        Write-Host ""
        Write-Host "【変更ファイル一覧】" -ForegroundColor Yellow
        Write-Host $status
        Write-Host ""

        # 全変更をステージング（確認プロンプトなし）
        情報 "変更をステージング中..."
        実行git静か @('add','.')

        # ステージングされた内容を確認
        $staged = 実行git @('diff','--cached','--name-status') -静か
        if ([string]::IsNullOrWhiteSpace($staged)) {
            情報 "ステージングされた変更がありません（.gitignoreで除外された可能性）"

            # claudeブランチの場合は、mainにマージする処理へ
            if ($現在ブランチ -match '^claude/') {
                情報 "claudeブランチの内容をmainにマージします"
                $変更あり = $false
            } else {
                Write-Host ""
                情報 "完了（変更なし）"
                exit 0
            }
        } else {
            Write-Host ""
            Write-Host "【ステージングされたファイル】" -ForegroundColor Yellow
            Write-Host $staged
            Write-Host ""

            # コミットメッセージの生成
            if ([string]::IsNullOrWhiteSpace($コミットメッセージ)) {
                # 自動生成: 変更されたファイルの概要
                $stagedLines = [regex]::Split([string]$staged, "\r?\n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                $fileCount = @($stagedLines).Count

                # 主な変更タイプを判定
                $changeTypes = @()
                if ($staged -match '^A\s') { $changeTypes += "追加" }
                if ($staged -match '^M\s') { $changeTypes += "更新" }
                if ($staged -match '^D\s') { $changeTypes += "削除" }

                $changeDesc = if ($changeTypes.Count -gt 0) { $changeTypes -join "・" } else { "変更" }

                $コミットメッセージ = "Update: $changeDesc ($fileCount ファイル)"
                情報 "自動生成されたコミットメッセージ: $コミットメッセージ"
            } else {
                情報 "コミットメッセージ: $コミットメッセージ"
            }

            # コミット
            情報 "コミット中..."

            # コミットメッセージを一時ファイルに書き込む（文字化け対策）
            $tempMsgFile = Join-Path $作業パス ".git\COMMIT_EDITMSG_TEMP"
            try {
                # UTF-8 BOMなしで保存
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($tempMsgFile, $コミットメッセージ, $utf8NoBom)

                # ファイルからコミットメッセージを読み込む
                実行git @('commit','-F', $tempMsgFile)
            } finally {
                # 一時ファイルを削除
                if (Test-Path $tempMsgFile) {
                    Remove-Item $tempMsgFile -Force -ErrorAction SilentlyContinue
                }
            }
            Write-Host ""
        }
    }

    # 7) claudeブランチの場合、mainにマージ
    if ($現在ブランチ -match '^claude/') {
        Write-Host ""
        情報 "claudeブランチからmainブランチにマージします..."

        # mainにチェックアウト
        情報 "mainブランチに切り替え中..."
        実行git @('checkout','main')

        # mainを最新化
        情報 "mainブランチを最新化中..."
        try {
            実行git @('pull','origin','main')
        } catch {
            警告 "mainブランチのpullに失敗しました（リモートが空の可能性）。続行します。"
        }

        # claudeブランチをマージ
        情報 "claudeブランチをマージ中..."
        $mergeMsg = "Merge branch '$現在ブランチ' into main"

        # マージメッセージを一時ファイルに書き込む（引用符の問題を回避）
        $tempMergeMsgFile = Join-Path $作業パス ".git\MERGE_MSG_TEMP"
        try {
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($tempMergeMsgFile, $mergeMsg, $utf8NoBom)

            # ファイルからマージメッセージを読み込む
            実行git @('merge','--no-ff',$現在ブランチ,'-F',$tempMergeMsgFile)
        } finally {
            # 一時ファイルを削除
            if (Test-Path $tempMergeMsgFile) {
                Remove-Item $tempMergeMsgFile -Force -ErrorAction SilentlyContinue
            }
        }

        情報 "マージ完了"
        Write-Host ""
    }

    # 8) mainブランチにプッシュ
    情報 "mainブランチをリモートにプッシュ中..."
    $強制許可 = ($env:PUSH_FORCE -eq '1')

    # リモートブランチの存在確認
    $remoteExists = $false
    try {
        実行git静か @('rev-parse','--verify', "origin/main")
        $remoteExists = $true
    } catch {
        情報 "リモートのmainブランチが存在しません。新規作成します。"
    }

    if ($remoteExists) {
        # リモートブランチが存在する場合、ahead/behindをチェック
        try {
            $ab = ([string](実行git @('rev-list','--left-right','--count', "main...origin/main") -静か)).Trim()
            $nums = $ab -split '\s+'
            if ($nums.Count -eq 2) {
                $ahead = [int]$nums[0]
                $behind = [int]$nums[1]
                情報 "ahead: $ahead, behind: $behind"

                if ($behind -gt 0) {
                    警告 "リモートのmainブランチの方が進んでいます（behind: $behind）"
                    if ($強制許可) {
                        警告 "強制プッシュを実行します（PUSH_FORCE=1）"
                        実行git @('push','--force-with-lease','origin','main')
                    } else {
                        失敗 "プッシュできません。先にリモートの変更を取り込むか、`$env:PUSH_FORCE=1 を設定してください。"
                    }
                } else {
                    実行git @('push','origin','main')
                }
            }
        } catch {
            # rev-list失敗時は通常プッシュを試行
            実行git @('push','origin','main')
        }
    } else {
        # 新規ブランチの場合
        実行git @('push','-u','origin','main')
    }

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    情報 "完了: mainブランチをリモートにプッシュしました"
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    if ($変更あり -and $コミットメッセージ) {
        情報 "コミットメッセージ: $コミットメッセージ"
    }
    情報 "元のブランチ: $現在ブランチ"
    情報 "プッシュ先: main"
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "[エラー] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "トラブルシューティング:" -ForegroundColor Yellow
    Write-Host "  1. 現在のブランチを確認: git branch" -ForegroundColor Yellow
    Write-Host "  2. 変更内容を確認: git status" -ForegroundColor Yellow
    Write-Host "  3. リモートの状態を確認: git fetch && git status" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}