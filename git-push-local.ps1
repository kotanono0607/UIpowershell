# ローカル変更をclaudeブランチにプッシュ (Ver 1.0)
# 使い方:
#   .\git-push-local.ps1                              # 自動コミットメッセージ
#   .\git-push-local.ps1 "Feat: 新機能追加"            # カスタムメッセージ
#   $env:PUSH_FORCE=1; .\git-push-local.ps1           # 強制プッシュ許可

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

    # 2) mainブランチにいる場合はエラー
    if ($現在ブランチ -eq 'main') {
        失敗 "mainブランチでは直接コミットできません。claude/* ブランチに切り替えてください。"
    }

    # 3) claudeブランチかチェック
    if ($現在ブランチ -notmatch '^claude/') {
        警告 "現在のブランチは claude/* ではありません: $現在ブランチ"
        $continue = Read-Host "このブランチにコミットしますか？ (y/N)"
        if ($continue -ne 'y') {
            失敗 "ユーザーによりキャンセルされました"
        }
    }

    # 4) リモートから最新情報を取得
    情報 "リモートから最新情報を取得中..."
    実行git静か @('fetch','origin','--prune')

    # 5) 変更の確認
    $status = 実行git @('status','--porcelain') -静か
    if ([string]::IsNullOrWhiteSpace($status)) {
        情報 "コミットする変更がありません"
        Write-Host ""
        情報 "完了（変更なし）"
        exit 0
    }

    Write-Host ""
    Write-Host "【変更ファイル一覧】" -ForegroundColor Yellow
    Write-Host $status
    Write-Host ""

    # 6) .gitignoreで除外されているファイルをチェック（logsなど）
    $logsPath = Join-Path $作業パス "logs"
    if (Test-Path $logsPath) {
        情報 "logsディレクトリが検出されました"

        # .gitignoreにlogsが含まれているかチェック
        $gitignorePath = Join-Path $作業パス ".gitignore"
        $logsIgnored = $false
        if (Test-Path $gitignorePath) {
            $gitignoreContent = Get-Content $gitignorePath -Raw
            if ($gitignoreContent -match '(?m)^logs(/|$)') {
                $logsIgnored = $true
                警告 "logsディレクトリは.gitignoreで除外されています"
            }
        }

        if (-not $logsIgnored) {
            警告 "logsディレクトリは.gitignoreに追加されていません"
            $addLogs = Read-Host "logsディレクトリをコミットに含めますか？ (y/N)"
            if ($addLogs -ne 'y') {
                情報 ".gitignoreにlogsを追加します"
                Add-Content -Path $gitignorePath -Value "`nlogs/" -Encoding UTF8
                実行git静か @('add','.gitignore')
            }
        }
    }

    # 7) 全変更をステージング
    情報 "変更をステージング中..."
    実行git静か @('add','.')

    # 8) ステージングされた内容を確認
    $staged = 実行git @('diff','--cached','--name-status') -静か
    if ([string]::IsNullOrWhiteSpace($staged)) {
        情報 "ステージングされた変更がありません（.gitignoreで除外された可能性）"
        Write-Host ""
        情報 "完了（変更なし）"
        exit 0
    }

    Write-Host ""
    Write-Host "【ステージングされたファイル】" -ForegroundColor Yellow
    Write-Host $staged
    Write-Host ""

    # 9) コミットメッセージの生成
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

    # 10) コミット
    情報 "コミット中..."
    実行git @('commit','-m', $コミットメッセージ)
    Write-Host ""

    # 11) リモートブランチの存在確認
    $remoteExists = $false
    try {
        実行git静か @('rev-parse','--verify', "origin/$現在ブランチ")
        $remoteExists = $true
    } catch {
        情報 "リモートブランチが存在しません。新規作成します。"
    }

    # 12) プッシュ
    情報 "リモートにプッシュ中..."
    $強制許可 = ($env:PUSH_FORCE -eq '1')

    if ($remoteExists) {
        # リモートブランチが存在する場合、ahead/behindをチェック
        try {
            $ab = ([string](実行git @('rev-list','--left-right','--count', "$現在ブランチ...origin/$現在ブランチ") -静か)).Trim()
            $nums = $ab -split '\s+'
            if ($nums.Count -eq 2) {
                $ahead = [int]$nums[0]
                $behind = [int]$nums[1]
                情報 "ahead: $ahead, behind: $behind"

                if ($behind -gt 0) {
                    警告 "リモートブランチの方が進んでいます（behind: $behind）"
                    if ($強制許可) {
                        警告 "強制プッシュを実行します（PUSH_FORCE=1）"
                        実行git @('push','--force-with-lease','origin', $現在ブランチ)
                    } else {
                        失敗 "プッシュできません。先にリモートの変更を取り込むか、`$env:PUSH_FORCE=1 を設定してください。"
                    }
                } else {
                    実行git @('push','origin', $現在ブランチ)
                }
            }
        } catch {
            # rev-list失敗時は通常プッシュを試行
            実行git @('push','origin', $現在ブランチ)
        }
    } else {
        # 新規ブランチの場合
        実行git @('push','-u','origin', $現在ブランチ)
    }

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    情報 "完了: ローカル変更をリモートにプッシュしました"
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    情報 "ブランチ: $現在ブランチ"
    情報 "コミットメッセージ: $コミットメッセージ"
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
