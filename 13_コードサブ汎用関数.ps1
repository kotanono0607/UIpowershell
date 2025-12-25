# 必要なアセンブリの読み込み
Add-Type -AssemblyName System.Windows.Forms

# メインメニュー最小化/復元用のAPI定義（既に読み込み済みの場合はスキップ）
# try/catchで囲み、型が既に存在する場合のエラーを無視
try {
    if (-not ([type]::GetType('MainMenuHelper', $false))) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class MainMenuHelper {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    public const int SW_MINIMIZE = 6;
    public const int SW_RESTORE = 9;
    public const int SW_SHOW = 5;
    public const int SW_SHOWNORMAL = 1;

    public static IntPtr FindUIpowershellWindow() {
        IntPtr result = IntPtr.Zero;
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            if (!IsWindowVisible(hWnd)) return true;
            StringBuilder title = new StringBuilder(256);
            GetWindowText(hWnd, title, title.Capacity);
            if (title.ToString().StartsWith("UIpowershell")) {
                result = hWnd;
                return false;
            }
            return true;
        }, IntPtr.Zero);
        return result;
    }

    // 強制的にウィンドウを前面に持ってくる
    public static bool ForceForegroundWindow(IntPtr hWnd) {
        IntPtr foregroundWnd = GetForegroundWindow();
        uint foregroundThreadId = GetWindowThreadProcessId(foregroundWnd, out _);
        uint currentThreadId = GetCurrentThreadId();

        if (foregroundThreadId != currentThreadId) {
            AttachThreadInput(currentThreadId, foregroundThreadId, true);
            BringWindowToTop(hWnd);
            ShowWindow(hWnd, SW_SHOW);
            AttachThreadInput(currentThreadId, foregroundThreadId, false);
        } else {
            BringWindowToTop(hWnd);
            ShowWindow(hWnd, SW_SHOW);
        }

        return SetForegroundWindow(hWnd);
    }
}
"@
    }
} catch {
    # 型が既に存在する場合のエラーを無視（Podeのrunspace間で共有されるため）
}

# メインメニューを最小化する関数
function メインメニューを最小化 {
    try {
        # MainMenuHelper型が存在する場合のみ実行（リフレクションで動的に呼び出し）
        $helperType = [type]::GetType('MainMenuHelper', $false)
        if ($helperType) {
            $findMethod = $helperType.GetMethod('FindUIpowershellWindow')
            $showMethod = $helperType.GetMethod('ShowWindow')
            $swMinimize = $helperType.GetField('SW_MINIMIZE').GetValue($null)

            if ($findMethod -and $showMethod) {
                $handle = $findMethod.Invoke($null, @())
                if ($handle -ne [IntPtr]::Zero) {
                    $showMethod.Invoke($null, @($handle, $swMinimize)) | Out-Null
                    return $handle
                }
            }
        }
    } catch {
        # エラー時は何もしない（意図的に無視）
    }
    return [IntPtr]::Zero
}

# メインメニューを復元する関数
function メインメニューを復元 {
    param(
        [IntPtr]$ハンドル
    )
    try {
        # MainMenuHelper型が存在する場合のみ実行（リフレクションで動的に呼び出し）
        $helperType = [type]::GetType('MainMenuHelper', $false)
        if ($helperType -and $ハンドル -ne [IntPtr]::Zero) {
            $showMethod = $helperType.GetMethod('ShowWindow')
            $swRestore = $helperType.GetField('SW_RESTORE').GetValue($null)

            if ($showMethod) {
                $showMethod.Invoke($null, @($ハンドル, $swRestore)) | Out-Null
            }
        }
    } catch {
        # エラー時は何もしない（意図的に無視）
    }
}

# ============================================
# フォームを前面に表示する共通関数
# ============================================
# 使用方法: フォームを前面表示に設定 -フォーム $form
# ShowDialog()の前に呼び出してください
function フォームを前面表示に設定 {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Form]$フォーム
    )

    # Topmostを設定
    $フォーム.TopMost = $true

    # フォーム表示時に前面に持ってくるイベントを追加
    $フォーム.Add_Shown({
        $this.Activate()
        $this.BringToFront()

        # Windows APIで強制的に前面に持ってくる（MainMenuHelper型が存在する場合のみ）
        try {
            $helperType = [type]::GetType('MainMenuHelper', $false)
            if ($helperType) {
                $handle = $this.Handle
                if ($handle -ne [IntPtr]::Zero) {
                    $method = $helperType.GetMethod('ForceForegroundWindow')
                    if ($method) {
                        $method.Invoke($null, @($handle)) | Out-Null
                    }
                }
            }
        } catch {
            # エラー時は標準の方法で前面化（意図的に無視）
        }

        # 少し待ってから再度前面化（他のウィンドウが割り込む場合の対策）
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 100
        $form = $this
        $timer.Add_Tick({
            $this.Stop()
            $this.Dispose()
            $form.Activate()
            $form.BringToFront()
        })
        $timer.Start()
    })

    # フォームがアクティブでなくなった時も再度前面に持ってくる
    $フォーム.Add_Deactivate({
        # TopMostなので通常は前面に留まるが、念のため
        $this.TopMost = $true
    })
}

# 汎用的なアイテム選択関数の定義
function リストから項目を選択 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$フォームタイトル,       # フォームのタイトル
       
        [Parameter(Mandatory = $true)]
        [string]$ラベルテキスト,       # ラベルのテキスト

        [Parameter(Mandatory = $true)]
        [string[]]$選択肢リスト           # 選択肢のリスト
    )

    #Write-Host "リストから項目を選択 関数が呼び出されました。"

    # フォームの作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = $フォームタイトル
    $フォーム.Size = New-Object System.Drawing.Size(400,200)
    $フォーム.StartPosition = "CenterScreen"

    # ラベルの作成
    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = $ラベルテキスト
    $ラベル.AutoSize = $true
    $ラベル.Location = New-Object System.Drawing.Point(10,20)
    $フォーム.Controls.Add($ラベル)

    # コンボボックスの作成
    $コンボボックス = New-Object System.Windows.Forms.ComboBox
    $コンボボックス.Location = New-Object System.Drawing.Point(10,50)
    $コンボボックス.Size = New-Object System.Drawing.Size(360,20)
    $コンボボックス.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $コンボボックス.Items.AddRange($選択肢リスト)
    $コンボボックス.SelectedIndex = -1  # 何も選択されていない状態

    $フォーム.Controls.Add($コンボボックス)

    # OKボタンの作成
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Size = New-Object System.Drawing.Size(75,23)
    $OKボタン.Location = New-Object System.Drawing.Point(220,100)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.AcceptButton = $OKボタン
    $フォーム.Controls.Add($OKボタン)

    # Cancelボタンの作成
    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "Cancel"
    $キャンセルボタン.Size = New-Object System.Drawing.Size(75,23)
    $キャンセルボタン.Location = New-Object System.Drawing.Point(300,100)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.CancelButton = $キャンセルボタン
    $フォーム.Controls.Add($キャンセルボタン)

    # フォームの表示（常に前面に表示）
    フォームを前面表示に設定 -フォーム $フォーム
    $メインメニューハンドル = メインメニューを最小化
    $ダイアログ結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    # フォームの結果に応じて処理
    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($コンボボックス.SelectedItem -ne $null) {
            $選択項目 = $コンボボックス.SelectedItem
            #Write-Host "OKボタンがクリックされました。選択された項目: $選択項目"
            return $選択項目
        } else {
            [System.Windows.Forms.MessageBox]::Show("項目を選択してください。","エラー")
            #Write-Host "OKボタンがクリックされましたが、何も選択されていません。"
            return $null
        }
    } else {
        #Write-Host "Cancelボタンがクリックされました。選択をキャンセルします。"
        return $null
    }
}


# 文字列を入力する関数の定義
function 文字列を入力 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$フォームタイトル,       # フォームのタイトル
       
        [Parameter(Mandatory = $true)]
        [string]$ラベルテキスト        # ラベルのテキスト
    )

    #Write-Host "文字列を入力 関数が呼び出されました。"

    # フォームの作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = $フォームタイトル
    $フォーム.Size = New-Object System.Drawing.Size(400,250)
    $フォーム.StartPosition = "CenterScreen"

    # ラベルの作成
    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = $ラベルテキスト
    $ラベル.AutoSize = $true
    $ラベル.Location = New-Object System.Drawing.Point(10,20)
    $フォーム.Controls.Add($ラベル)

    # テキストボックスの作成
    $テキストボックス = New-Object System.Windows.Forms.TextBox
    $テキストボックス.Location = New-Object System.Drawing.Point(10,50)
    $テキストボックス.Size = New-Object System.Drawing.Size(360,20)
    $フォーム.Controls.Add($テキストボックス)

    # OKボタンの作成
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Size = New-Object System.Drawing.Size(75,23)
    $OKボタン.Location = New-Object System.Drawing.Point(220,150)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.AcceptButton = $OKボタン
    $フォーム.Controls.Add($OKボタン)

    # Cancelボタンの作成
    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "Cancel"
    $キャンセルボタン.Size = New-Object System.Drawing.Size(75,23)
    $キャンセルボタン.Location = New-Object System.Drawing.Point(300,150)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.CancelButton = $キャンセルボタン
    $フォーム.Controls.Add($キャンセルボタン)

    # 変数を使用ボタンの作成
    $変数使用ボタン = New-Object System.Windows.Forms.Button
    $変数使用ボタン.Text = "変数を使用"
    $変数使用ボタン.Size = New-Object System.Drawing.Size(100,23)
    $変数使用ボタン.Location = New-Object System.Drawing.Point(10,150)
    $フォーム.Controls.Add($変数使用ボタン)

    # 変数使用ボタンのイベントハンドラー
    $変数使用ボタン.Add_Click({
        #Write-Host "変数を使用ボタンがクリックされました。"


        　　#　＃＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝ここ決め打ち
             #$メインフォーム.Hide()
            #."C:\Users\hallo\Documents\WindowsPowerShell\chord\RPA-UI\20241117_変数管理システム.ps1"


            $variableName1 = Show-VariableManagerForm


                if ($variableName1 -ne $null) {
                    #Write-Host "選択された変数名1: $variableName1"
                } else {
                    #Write-Host "変数取得がキャンセルされました。"
                }


            #$メインフォーム.Show()


        # 変数管理システムを呼び出し、選択された変数名を取得
 

            $テキストボックス.Text += $variableName1

    })

    # フォームの表示（常に前面に表示）
    フォームを前面表示に設定 -フォーム $フォーム
    $メインメニューハンドル = メインメニューを最小化
    $ダイアログ結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    # フォームの結果に応じて処理
    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($テキストボックス.Text.Trim() -ne "") {
            $入力文字列 = $テキストボックス.Text.Trim()
            #Write-Host "OKボタンがクリックされました。入力された文字列: $入力文字列"
            return $入力文字列
        } else {
            [System.Windows.Forms.MessageBox]::Show("文字列を入力してください。","エラー")
            #Write-Host "OKボタンがクリックされましたが、何も入力されていません。"
            return $null
        }
    } else {
        #Write-Host "Cancelボタンがクリックされました。入力をキャンセルします。"
        return $null
    }
}

# 数値を入力.ps1 - Ver 1.0
function 数値を入力 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$フォームタイトル,      # フォームのタイトル
        [Parameter(Mandatory = $true)]
        [string]$ラベルテキスト       # ラベルのテキスト
    )

    # フォームの作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = $フォームタイトル
    $フォーム.Size = New-Object System.Drawing.Size(400, 200)
    $フォーム.StartPosition = "CenterScreen"

    # ラベルの作成
    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = $ラベルテキスト
    $ラベル.AutoSize = $true
    $ラベル.Location = New-Object System.Drawing.Point(10, 20)
    $フォーム.Controls.Add($ラベル)

    # 数値入力用 NumericUpDown コントロールの作成
    $数値入力 = New-Object System.Windows.Forms.NumericUpDown
    $数値入力.Location = New-Object System.Drawing.Point(10, 50)
    $数値入力.Size = New-Object System.Drawing.Size(360, 20)
    $数値入力.Minimum = [decimal]::MinValue   # 最小値を設定（必要に応じて変更可）
    $数値入力.Maximum = [decimal]::MaxValue   # 最大値を設定（必要に応じて変更可）
    $数値入力.DecimalPlaces = 0              # 整数のみ許可
    $フォーム.Controls.Add($数値入力)

    # OKボタンの作成
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Size = New-Object System.Drawing.Size(75, 23)
    $OKボタン.Location = New-Object System.Drawing.Point(220, 120)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.AcceptButton = $OKボタン
    $フォーム.Controls.Add($OKボタン)

    # Cancelボタンの作成
    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "Cancel"
    $キャンセルボタン.Size = New-Object System.Drawing.Size(75, 23)
    $キャンセルボタン.Location = New-Object System.Drawing.Point(300, 120)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.CancelButton = $キャンセルボタン
    $フォーム.Controls.Add($キャンセルボタン)

    # フォームを表示（常に前面に表示）
    フォームを前面表示に設定 -フォーム $フォーム
    $メインメニューハンドル = メインメニューを最小化
    $ダイアログ結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    # フォームの結果に応じて処理
    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        $入力数値 = [int]$数値入力.Value
        return $入力数値
    } else {
        return $null
    }
}

# ============================================
# RPA実行用関数
# ============================================

# キー操作関数 - キーコマンドを送信する
function キー操作 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$キーコマンド
    )

    # キーコマンドをSendKeys形式に変換
    $sendKeysCommand = $キーコマンド

    # キーコマンドのマッピング（SendKeys形式に変換）
    $keyMap = @{
        "Ctrl+A" = "^a"
        "Ctrl+C" = "^c"
        "Ctrl+V" = "^v"
        "Ctrl+F" = "^f"
        "Alt+F4" = "%{F4}"
        "Del" = "{DELETE}"
        "Enter" = "{ENTER}"
        "Tab" = "{TAB}"
        "Shift+Tab" = "+{TAB}"
        "PageUp" = "{PGUP}"
        "PageDown" = "{PGDN}"
        "ArrowUp" = "{UP}"
        "ArrowDown" = "{DOWN}"
        "ArrowLeft" = "{LEFT}"
        "ArrowRight" = "{RIGHT}"
        "Esc" = "{ESC}"
    }

    if ($keyMap.ContainsKey($キーコマンド)) {
        $sendKeysCommand = $keyMap[$キーコマンド]
    }

    try {
        # SendKeysを使用してキーを送信
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.SendKeys]::SendWait($sendKeysCommand)
    }
    catch {
        Write-Warning "キー操作の実行に失敗しました: $($_.Exception.Message)"
    }
}

# 文字列入力関数 - 文字列をキーボード入力として送信する
function 文字列入力 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$入力文字列
    )

    try {
        # SendKeysを使用して文字列を送信
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.SendKeys]::SendWait($入力文字列)
    }
    catch {
        Write-Warning "文字列入力の実行に失敗しました: $($_.Exception.Message)"
    }
}

# ファイルを選択する関数の定義 Ver1.0
function ファイルを選択 {
    param(
        [Parameter(Mandatory = $false)]
        [string]$タイトル = "ファイルを選択してください",

        [Parameter(Mandatory = $false)]
        [string]$フィルタ = "All Files (*.*)|*.*",

        [Parameter(Mandatory = $false)]
        [string]$初期ディレクトリ = [Environment]::GetFolderPath('Desktop')
    )

    # ファイル選択ダイアログの作成
    $ダイアログ = New-Object System.Windows.Forms.OpenFileDialog
    $ダイアログ.Title = $タイトル
    $ダイアログ.Filter = $フィルタ
    $ダイアログ.InitialDirectory = $初期ディレクトリ

    # ダイアログを表示
    $メインメニューハンドル = メインメニューを最小化
    $結果 = $ダイアログ.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        return $ダイアログ.FileName
    } else {
        return $null
    }
}

# 複数行テキストを編集する関数の定義
function 複数行テキストを編集 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$フォームタイトル,       # フォームのタイトル

        [Parameter(Mandatory = $true)]
        [string]$ラベルテキスト,        # ラベルのテキスト

        [Parameter(Mandatory = $false)]
        [string]$初期テキスト = ""      # 初期表示するテキスト
    )


    # フォームの作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = $フォームタイトル
    $フォーム.Size = New-Object System.Drawing.Size(1000,700)
    $フォーム.StartPosition = "CenterScreen"

    # ラベルの作成
    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = $ラベルテキスト
    $ラベル.AutoSize = $true
    $ラベル.Location = New-Object System.Drawing.Point(10,20)
    $フォーム.Controls.Add($ラベル)

    # 複数行テキストボックスの作成
    $テキストボックス = New-Object System.Windows.Forms.TextBox
    $テキストボックス.Location = New-Object System.Drawing.Point(10,50)
    $テキストボックス.Size = New-Object System.Drawing.Size(960,570)
    $テキストボックス.Multiline = $true
    $テキストボックス.ScrollBars = "Both"
    $テキストボックス.WordWrap = $false
    $テキストボックス.Font = New-Object System.Drawing.Font("Consolas",10)
    $テキストボックス.Text = $初期テキスト
    $フォーム.Controls.Add($テキストボックス)

    # OKボタンの作成
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Size = New-Object System.Drawing.Size(100,30)
    $OKボタン.Location = New-Object System.Drawing.Point(770,630)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.AcceptButton = $OKボタン
    $フォーム.Controls.Add($OKボタン)

    # Cancelボタンの作成
    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "Cancel"
    $キャンセルボタン.Size = New-Object System.Drawing.Size(100,30)
    $キャンセルボタン.Location = New-Object System.Drawing.Point(880,630)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.CancelButton = $キャンセルボタン
    $フォーム.Controls.Add($キャンセルボタン)

    # フォームの表示（常に前面に表示）
    フォームを前面表示に設定 -フォーム $フォーム
    $メインメニューハンドル = メインメニューを最小化
    $ダイアログ結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    # フォームの結果に応じて処理
    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        return $テキストボックス.Text
    } else {
        return $null
    }
}

# ノード設定編集フォーム関数の定義
function ノード設定を編集 {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ノード情報       # ノードの全情報を含むハッシュテーブル
    )


    # フォームの作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "ノード設定: $($ノード情報.text)"
    $フォーム.Size = New-Object System.Drawing.Size(850,750)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false

    $currentY = 10

    # ========================================
    # ノード名
    # ========================================
    $ラベル_ノード名 = New-Object System.Windows.Forms.Label
    $ラベル_ノード名.Text = "ノード名:"
    $ラベル_ノード名.AutoSize = $true
    $ラベル_ノード名.Location = New-Object System.Drawing.Point(10, $currentY)
    $ラベル_ノード名.Font = New-Object System.Drawing.Font("MS UI Gothic", 10, [System.Drawing.FontStyle]::Bold)
    $フォーム.Controls.Add($ラベル_ノード名)
    $currentY += 25

    $テキスト_ノード名 = New-Object System.Windows.Forms.TextBox
    $テキスト_ノード名.Location = New-Object System.Drawing.Point(10, $currentY)
    $テキスト_ノード名.Size = New-Object System.Drawing.Size(810, 25)
    $テキスト_ノード名.Text = $ノード情報.text
    $フォーム.Controls.Add($テキスト_ノード名)
    $currentY += 40

    # ========================================
    # 外観設定グループ
    # ========================================
    $グループ_外観 = New-Object System.Windows.Forms.GroupBox
    $グループ_外観.Text = "外観設定"
    $グループ_外観.Location = New-Object System.Drawing.Point(10, $currentY)
    $グループ_外観.Size = New-Object System.Drawing.Size(810, 180)
    $フォーム.Controls.Add($グループ_外観)

    # 背景色
    $ラベル_色 = New-Object System.Windows.Forms.Label
    $ラベル_色.Text = "背景色:"
    $ラベル_色.Location = New-Object System.Drawing.Point(15, 25)
    $ラベル_色.AutoSize = $true
    $グループ_外観.Controls.Add($ラベル_色)

    $コンボ_色 = New-Object System.Windows.Forms.ComboBox
    $コンボ_色.Location = New-Object System.Drawing.Point(15, 48)
    $コンボ_色.Size = New-Object System.Drawing.Size(200, 25)
    $コンボ_色.DropDownStyle = "DropDownList"
    $コンボ_色.Items.AddRange(@("White", "Pink", "LightGray", "LightBlue", "LightGreen", "LightYellow", "LightCoral", "Lavender"))
    if ($ノード情報.color) {
        $コンボ_色.SelectedItem = $ノード情報.color
    } else {
        $コンボ_色.SelectedItem = "White"
    }
    $グループ_外観.Controls.Add($コンボ_色)

    # 幅
    $ラベル_幅 = New-Object System.Windows.Forms.Label
    $ラベル_幅.Text = "幅:"
    $ラベル_幅.Location = New-Object System.Drawing.Point(240, 25)
    $ラベル_幅.AutoSize = $true
    $グループ_外観.Controls.Add($ラベル_幅)

    $数値_幅 = New-Object System.Windows.Forms.NumericUpDown
    $数値_幅.Location = New-Object System.Drawing.Point(240, 48)
    $数値_幅.Size = New-Object System.Drawing.Size(100, 25)
    $数値_幅.Minimum = 80
    $数値_幅.Maximum = 500
    $数値_幅.Value = if ($ノード情報.width) { $ノード情報.width } else { 120 }
    $グループ_外観.Controls.Add($数値_幅)

    # 高さ
    $ラベル_高さ = New-Object System.Windows.Forms.Label
    $ラベル_高さ.Text = "高さ:"
    $ラベル_高さ.Location = New-Object System.Drawing.Point(360, 25)
    $ラベル_高さ.AutoSize = $true
    $グループ_外観.Controls.Add($ラベル_高さ)

    $数値_高さ = New-Object System.Windows.Forms.NumericUpDown
    $数値_高さ.Location = New-Object System.Drawing.Point(360, 48)
    $数値_高さ.Size = New-Object System.Drawing.Size(100, 25)
    $数値_高さ.Minimum = 30
    $数値_高さ.Maximum = 200
    $数値_高さ.Value = if ($ノード情報.height) { $ノード情報.height } else { 40 }
    $グループ_外観.Controls.Add($数値_高さ)

    # X座標
    $ラベル_X = New-Object System.Windows.Forms.Label
    $ラベル_X.Text = "X座標:"
    $ラベル_X.Location = New-Object System.Drawing.Point(15, 90)
    $ラベル_X.AutoSize = $true
    $グループ_外観.Controls.Add($ラベル_X)

    $数値_X = New-Object System.Windows.Forms.NumericUpDown
    $数値_X.Location = New-Object System.Drawing.Point(15, 113)
    $数値_X.Size = New-Object System.Drawing.Size(150, 25)
    $数値_X.Minimum = 0
    $数値_X.Maximum = 2000
    $数値_X.Value = if ($ノード情報.x) { $ノード情報.x } else { 10 }
    $グループ_外観.Controls.Add($数値_X)

    # Y座標
    $ラベル_Y = New-Object System.Windows.Forms.Label
    $ラベル_Y.Text = "Y座標:"
    $ラベル_Y.Location = New-Object System.Drawing.Point(185, 90)
    $ラベル_Y.AutoSize = $true
    $グループ_外観.Controls.Add($ラベル_Y)

    $数値_Y = New-Object System.Windows.Forms.NumericUpDown
    $数値_Y.Location = New-Object System.Drawing.Point(185, 113)
    $数値_Y.Size = New-Object System.Drawing.Size(150, 25)
    $数値_Y.Minimum = 0
    $数値_Y.Maximum = 5000
    $数値_Y.Value = if ($ノード情報.y) { $ノード情報.y } else { 10 }
    $グループ_外観.Controls.Add($数値_Y)

    $currentY += 195

    # ========================================
    # カスタムフィールド（処理番号に応じて）
    # ========================================
    $テキスト_条件式 = $null
    $数値_ループ回数 = $null
    $テキスト_ループ変数 = $null

    if ($ノード情報.処理番号 -eq '1-2') {
        # 条件分岐
        $グループ_カスタム = New-Object System.Windows.Forms.GroupBox
        $グループ_カスタム.Text = "条件分岐設定"
        $グループ_カスタム.Location = New-Object System.Drawing.Point(10, $currentY)
        $グループ_カスタム.Size = New-Object System.Drawing.Size(810, 80)
        $グループ_カスタム.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 243, 205)
        $フォーム.Controls.Add($グループ_カスタム)

        $ラベル_条件式 = New-Object System.Windows.Forms.Label
        $ラベル_条件式.Text = "条件式:"
        $ラベル_条件式.Location = New-Object System.Drawing.Point(15, 25)
        $ラベル_条件式.AutoSize = $true
        $グループ_カスタム.Controls.Add($ラベル_条件式)

        $テキスト_条件式 = New-Object System.Windows.Forms.TextBox
        $テキスト_条件式.Location = New-Object System.Drawing.Point(15, 48)
        $テキスト_条件式.Size = New-Object System.Drawing.Size(780, 25)
        $テキスト_条件式.Text = if ($ノード情報.conditionExpression) { $ノード情報.conditionExpression } else { "" }
        $グループ_カスタム.Controls.Add($テキスト_条件式)

        $currentY += 95
    } elseif ($ノード情報.処理番号 -eq '1-3') {
        # ループ
        $グループ_カスタム = New-Object System.Windows.Forms.GroupBox
        $グループ_カスタム.Text = "ループ設定"
        $グループ_カスタム.Location = New-Object System.Drawing.Point(10, $currentY)
        $グループ_カスタム.Size = New-Object System.Drawing.Size(810, 110)
        $グループ_カスタム.BackColor = [System.Drawing.Color]::FromArgb(255, 209, 236, 241)
        $フォーム.Controls.Add($グループ_カスタム)

        $ラベル_ループ回数 = New-Object System.Windows.Forms.Label
        $ラベル_ループ回数.Text = "ループ回数:"
        $ラベル_ループ回数.Location = New-Object System.Drawing.Point(15, 25)
        $ラベル_ループ回数.AutoSize = $true
        $グループ_カスタム.Controls.Add($ラベル_ループ回数)

        $数値_ループ回数 = New-Object System.Windows.Forms.NumericUpDown
        $数値_ループ回数.Location = New-Object System.Drawing.Point(15, 48)
        $数値_ループ回数.Size = New-Object System.Drawing.Size(150, 25)
        $数値_ループ回数.Minimum = 1
        $数値_ループ回数.Maximum = 10000
        $数値_ループ回数.Value = if ($ノード情報.loopCount) { $ノード情報.loopCount } else { 1 }
        $グループ_カスタム.Controls.Add($数値_ループ回数)

        $ラベル_ループ変数 = New-Object System.Windows.Forms.Label
        $ラベル_ループ変数.Text = "ループ変数名:"
        $ラベル_ループ変数.Location = New-Object System.Drawing.Point(185, 25)
        $ラベル_ループ変数.AutoSize = $true
        $グループ_カスタム.Controls.Add($ラベル_ループ変数)

        $テキスト_ループ変数 = New-Object System.Windows.Forms.TextBox
        $テキスト_ループ変数.Location = New-Object System.Drawing.Point(185, 48)
        $テキスト_ループ変数.Size = New-Object System.Drawing.Size(200, 25)
        $テキスト_ループ変数.Text = if ($ノード情報.loopVariable) { $ノード情報.loopVariable } else { "i" }
        $グループ_カスタム.Controls.Add($テキスト_ループ変数)

        $currentY += 125
    }

    # ========================================
    # スクリプト
    # ========================================
    $ラベル_スクリプト = New-Object System.Windows.Forms.Label
    $ラベル_スクリプト.Text = "スクリプト:"
    $ラベル_スクリプト.AutoSize = $true
    $ラベル_スクリプト.Location = New-Object System.Drawing.Point(10, $currentY)
    $ラベル_スクリプト.Font = New-Object System.Drawing.Font("MS UI Gothic", 10, [System.Drawing.FontStyle]::Bold)
    $フォーム.Controls.Add($ラベル_スクリプト)
    $currentY += 25

    $テキスト_スクリプト = New-Object System.Windows.Forms.TextBox
    $テキスト_スクリプト.Location = New-Object System.Drawing.Point(10, $currentY)
    $テキスト_スクリプト.Size = New-Object System.Drawing.Size(810, 260)
    $テキスト_スクリプト.Multiline = $true
    $テキスト_スクリプト.ScrollBars = "Both"
    $テキスト_スクリプト.WordWrap = $false
    $テキスト_スクリプト.Font = New-Object System.Drawing.Font("Consolas", 10)
    $テキスト_スクリプト.Text = if ($ノード情報.script) { $ノード情報.script } else { "" }
    $フォーム.Controls.Add($テキスト_スクリプト)
    $currentY += 275

    # ========================================
    # OK/Cancelボタン
    # ========================================
    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "保存"
    $OKボタン.Size = New-Object System.Drawing.Size(100, 35)
    $OKボタン.Location = New-Object System.Drawing.Point(620, $currentY)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.AcceptButton = $OKボタン
    $フォーム.Controls.Add($OKボタン)

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Size = New-Object System.Drawing.Size(100, 35)
    $キャンセルボタン.Location = New-Object System.Drawing.Point(730, $currentY)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.CancelButton = $キャンセルボタン
    $フォーム.Controls.Add($キャンセルボタン)

    # フォームの表示（常に前面に表示）
    フォームを前面表示に設定 -フォーム $フォーム
    $メインメニューハンドル = メインメニューを最小化
    $ダイアログ結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    # フォームの結果に応じて処理
    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        
        $結果 = @{
            text = $テキスト_ノード名.Text
            color = $コンボ_色.SelectedItem.ToString()
            width = [int]$数値_幅.Value
            height = [int]$数値_高さ.Value
            x = [int]$数値_X.Value
            y = [int]$数値_Y.Value
            script = $テキスト_スクリプト.Text
        }

        # カスタムフィールドを追加
        if ($テキスト_条件式) {
            $結果.conditionExpression = $テキスト_条件式.Text
        }
        if ($数値_ループ回数) {
            $結果.loopCount = [int]$数値_ループ回数.Value
        }
        if ($テキスト_ループ変数) {
            $結果.loopVariable = $テキスト_ループ変数.Text
        }

        return $結果
    } else {
        return $null
    }
}


# ============================================
# 変数管理ダイアログ
# ============================================
function 変数管理を表示 {
    <#
    .SYNOPSIS
    変数管理ダイアログを表示（PowerShell Windows Forms版）

    .DESCRIPTION
    変数の一覧を表示し、追加・編集・削除を行うダイアログを表示します。

    .PARAMETER 変数リスト
    現在の変数リスト（配列形式）
    各要素は @{ name = "変数名"; value = "値"; type = "タイプ" } のハッシュテーブル

    .EXAMPLE
    $result = 変数管理を表示 -変数リスト $variables
    #>
    param(
        [Parameter(Mandatory = $false)]
        [array]$変数リスト = @()
    )


    # フォーム作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "変数管理"
    $フォーム.Size = New-Object System.Drawing.Size(700, 500)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $フォーム.MaximizeBox = $false

    # 変数を保持するためのスクリプト変数
    $script:現在の変数リスト = $変数リスト

    # ListView作成（変数一覧表示）
    $リストビュー = New-Object System.Windows.Forms.ListView
    $リストビュー.Location = New-Object System.Drawing.Point(20, 20)
    $リストビュー.Size = New-Object System.Drawing.Size(640, 350)
    $リストビュー.View = [System.Windows.Forms.View]::Details
    $リストビュー.FullRowSelect = $true
    $リストビュー.GridLines = $true
    $リストビュー.MultiSelect = $false

    # 列を追加
    $リストビュー.Columns.Add("変数名", 200) | Out-Null
    $リストビュー.Columns.Add("値", 300) | Out-Null
    $リストビュー.Columns.Add("タイプ", 100) | Out-Null

    $フォーム.Controls.Add($リストビュー)

    # ListView更新関数
    function Update-VariableListView {
        $リストビュー.Items.Clear()

        foreach ($var in $script:現在の変数リスト) {
            $item = New-Object System.Windows.Forms.ListViewItem($var.name)

            # 値の表示形式を調整
            $displayValue = ""
            if ($var.type -eq "一次元" -or $var.type -eq "二次元") {
                $displayValue = $var.displayValue
            } else {
                $displayValue = $var.value
            }

            # 長すぎる場合は省略
            if ($displayValue.Length -gt 80) {
                $displayValue = $displayValue.Substring(0, 77) + "..."
            }

            $item.SubItems.Add($displayValue) | Out-Null
            $item.SubItems.Add($var.type) | Out-Null
            $item.Tag = $var

            $リストビュー.Items.Add($item) | Out-Null
        }

    }

    # 追加ボタン
    $ボタン_追加 = New-Object System.Windows.Forms.Button
    $ボタン_追加.Text = "➕ 追加"
    $ボタン_追加.Location = New-Object System.Drawing.Point(20, 390)
    $ボタン_追加.Size = New-Object System.Drawing.Size(100, 30)
    $フォーム.Controls.Add($ボタン_追加)

    # 編集ボタン
    $ボタン_編集 = New-Object System.Windows.Forms.Button
    $ボタン_編集.Text = "✏️ 編集"
    $ボタン_編集.Location = New-Object System.Drawing.Point(130, 390)
    $ボタン_編集.Size = New-Object System.Drawing.Size(100, 30)
    $フォーム.Controls.Add($ボタン_編集)

    # 削除ボタン
    $ボタン_削除 = New-Object System.Windows.Forms.Button
    $ボタン_削除.Text = "🗑️ 削除"
    $ボタン_削除.Location = New-Object System.Drawing.Point(240, 390)
    $ボタン_削除.Size = New-Object System.Drawing.Size(100, 30)
    $フォーム.Controls.Add($ボタン_削除)

    # 閉じるボタン
    $ボタン_閉じる = New-Object System.Windows.Forms.Button
    $ボタン_閉じる.Text = "閉じる"
    $ボタン_閉じる.Location = New-Object System.Drawing.Point(560, 390)
    $ボタン_閉じる.Size = New-Object System.Drawing.Size(100, 30)
    $ボタン_閉じる.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.Controls.Add($ボタン_閉じる)

    # 追加ボタンクリックイベント
    $ボタン_追加.Add_Click({

        # 変数追加ダイアログを表示
        $result = Show-AddVariableDialog

        if ($result) {
            # リストに追加（実際のAPI呼び出しはJavaScript側で行う）
            $script:現在の変数リスト += $result
            Update-VariableListView
        }
    })

    # 編集ボタンクリックイベント
    $ボタン_編集.Add_Click({
        if ($リストビュー.SelectedItems.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "編集する変数を選択してください。",
                "変数管理",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }

        $selectedVar = $リストビュー.SelectedItems[0].Tag

        # 変数編集ダイアログを表示
        $result = Show-EditVariableDialog -変数情報 $selectedVar

        if ($result) {
            # リストを更新
            $index = 0
            for ($i = 0; $i -lt $script:現在の変数リスト.Count; $i++) {
                if ($script:現在の変数リスト[$i].name -eq $selectedVar.name) {
                    $index = $i
                    break
                }
            }
            $script:現在の変数リスト[$index] = $result
            Update-VariableListView
        }
    })

    # 削除ボタンクリックイベント
    $ボタン_削除.Add_Click({
        if ($リストビュー.SelectedItems.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "削除する変数を選択してください。",
                "変数管理",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }

        $selectedVar = $リストビュー.SelectedItems[0].Tag

        # 確認ダイアログ
        $confirmResult = [System.Windows.Forms.MessageBox]::Show(
            "変数「$($selectedVar.name)」を削除しますか？",
            "削除確認",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($confirmResult -eq [System.Windows.Forms.DialogResult]::Yes) {
            # リストから削除
            $script:現在の変数リスト = $script:現在の変数リスト | Where-Object { $_.name -ne $selectedVar.name }
            Update-VariableListView
        }
    })

    # 初期表示
    Update-VariableListView

    # ダイアログ表示（常に前面に表示）
    フォームを前面表示に設定 -フォーム $フォーム
    $メインメニューハンドル = メインメニューを最小化
    $ダイアログ結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル


    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        return @{
            success = $true
            variables = $script:現在の変数リスト
        }
    } else {
        return $null
    }
}


# 変数追加ダイアログ
function Show-AddVariableDialog {
    $ダイアログ = New-Object System.Windows.Forms.Form
    $ダイアログ.Text = "変数を追加"
    $ダイアログ.Size = New-Object System.Drawing.Size(450, 220)
    $ダイアログ.StartPosition = "CenterParent"
    $ダイアログ.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $ダイアログ.MaximizeBox = $false
    $ダイアログ.MinimizeBox = $false

    # 変数名ラベル
    $ラベル_変数名 = New-Object System.Windows.Forms.Label
    $ラベル_変数名.Text = "変数名:"
    $ラベル_変数名.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル_変数名.AutoSize = $true
    $ダイアログ.Controls.Add($ラベル_変数名)

    # 変数名テキストボックス
    $テキスト_変数名 = New-Object System.Windows.Forms.TextBox
    $テキスト_変数名.Location = New-Object System.Drawing.Point(120, 20)
    $テキスト_変数名.Size = New-Object System.Drawing.Size(290, 20)
    $ダイアログ.Controls.Add($テキスト_変数名)

    # 値ラベル
    $ラベル_値 = New-Object System.Windows.Forms.Label
    $ラベル_値.Text = "値:"
    $ラベル_値.Location = New-Object System.Drawing.Point(20, 60)
    $ラベル_値.AutoSize = $true
    $ダイアログ.Controls.Add($ラベル_値)

    # 値テキストボックス
    $テキスト_値 = New-Object System.Windows.Forms.TextBox
    $テキスト_値.Location = New-Object System.Drawing.Point(120, 60)
    $テキスト_値.Size = New-Object System.Drawing.Size(290, 20)
    $ダイアログ.Controls.Add($テキスト_値)

    # タイプラベル
    $ラベル_タイプ = New-Object System.Windows.Forms.Label
    $ラベル_タイプ.Text = "タイプ:"
    $ラベル_タイプ.Location = New-Object System.Drawing.Point(20, 100)
    $ラベル_タイプ.AutoSize = $true
    $ダイアログ.Controls.Add($ラベル_タイプ)

    # タイプコンボボックス
    $コンボ_タイプ = New-Object System.Windows.Forms.ComboBox
    $コンボ_タイプ.Location = New-Object System.Drawing.Point(120, 100)
    $コンボ_タイプ.Size = New-Object System.Drawing.Size(290, 20)
    $コンボ_タイプ.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $コンボ_タイプ.Items.AddRange(@("単一値", "一次元", "二次元"))
    $コンボ_タイプ.SelectedIndex = 0
    $ダイアログ.Controls.Add($コンボ_タイプ)

    # OKボタン
    $ボタン_OK = New-Object System.Windows.Forms.Button
    $ボタン_OK.Text = "OK"
    $ボタン_OK.Location = New-Object System.Drawing.Point(230, 140)
    $ボタン_OK.Size = New-Object System.Drawing.Size(80, 30)
    $ボタン_OK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $ダイアログ.Controls.Add($ボタン_OK)

    # キャンセルボタン
    $ボタン_キャンセル = New-Object System.Windows.Forms.Button
    $ボタン_キャンセル.Text = "キャンセル"
    $ボタン_キャンセル.Location = New-Object System.Drawing.Point(320, 140)
    $ボタン_キャンセル.Size = New-Object System.Drawing.Size(90, 30)
    $ボタン_キャンセル.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $ダイアログ.Controls.Add($ボタン_キャンセル)

    $ダイアログ.AcceptButton = $ボタン_OK
    $ダイアログ.CancelButton = $ボタン_キャンセル

    # 前面表示設定
    フォームを前面表示に設定 -フォーム $ダイアログ

    $メインメニューハンドル = メインメニューを最小化
    $result = $ダイアログ.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        if ([string]::IsNullOrWhiteSpace($テキスト_変数名.Text)) {
            [System.Windows.Forms.MessageBox]::Show(
                "変数名を入力してください。",
                "エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            return $null
        }

        return @{
            name = $テキスト_変数名.Text.Trim()
            value = $テキスト_値.Text
            type = $コンボ_タイプ.SelectedItem.ToString()
            displayValue = $テキスト_値.Text
        }
    }

    return $null
}


# 変数編集ダイアログ
function Show-EditVariableDialog {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$変数情報
    )

    $ダイアログ = New-Object System.Windows.Forms.Form
    $ダイアログ.Text = "変数を編集"
    $ダイアログ.Size = New-Object System.Drawing.Size(450, 220)
    $ダイアログ.StartPosition = "CenterParent"
    $ダイアログ.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $ダイアログ.MaximizeBox = $false
    $ダイアログ.MinimizeBox = $false

    # 変数名ラベル
    $ラベル_変数名 = New-Object System.Windows.Forms.Label
    $ラベル_変数名.Text = "変数名:"
    $ラベル_変数名.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル_変数名.AutoSize = $true
    $ダイアログ.Controls.Add($ラベル_変数名)

    # 変数名テキストボックス（読み取り専用）
    $テキスト_変数名 = New-Object System.Windows.Forms.TextBox
    $テキスト_変数名.Location = New-Object System.Drawing.Point(120, 20)
    $テキスト_変数名.Size = New-Object System.Drawing.Size(290, 20)
    $テキスト_変数名.Text = $変数情報.name
    $テキスト_変数名.ReadOnly = $true
    $テキスト_変数名.BackColor = [System.Drawing.SystemColors]::Control
    $ダイアログ.Controls.Add($テキスト_変数名)

    # 値ラベル
    $ラベル_値 = New-Object System.Windows.Forms.Label
    $ラベル_値.Text = "値:"
    $ラベル_値.Location = New-Object System.Drawing.Point(20, 60)
    $ラベル_値.AutoSize = $true
    $ダイアログ.Controls.Add($ラベル_値)

    # 値テキストボックス
    $テキスト_値 = New-Object System.Windows.Forms.TextBox
    $テキスト_値.Location = New-Object System.Drawing.Point(120, 60)
    $テキスト_値.Size = New-Object System.Drawing.Size(290, 20)

    # 現在の値を設定
    if ($変数情報.type -eq "一次元" -or $変数情報.type -eq "二次元") {
        $テキスト_値.Text = $変数情報.displayValue
    } else {
        $テキスト_値.Text = $変数情報.value
    }

    $ダイアログ.Controls.Add($テキスト_値)

    # タイプラベル
    $ラベル_タイプ = New-Object System.Windows.Forms.Label
    $ラベル_タイプ.Text = "タイプ:"
    $ラベル_タイプ.Location = New-Object System.Drawing.Point(20, 100)
    $ラベル_タイプ.AutoSize = $true
    $ダイアログ.Controls.Add($ラベル_タイプ)

    # タイプコンボボックス（読み取り専用）
    $コンボ_タイプ = New-Object System.Windows.Forms.ComboBox
    $コンボ_タイプ.Location = New-Object System.Drawing.Point(120, 100)
    $コンボ_タイプ.Size = New-Object System.Drawing.Size(290, 20)
    $コンボ_タイプ.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $コンボ_タイプ.Items.AddRange(@("単一値", "一次元", "二次元"))
    $コンボ_タイプ.SelectedItem = $変数情報.type
    $コンボ_タイプ.Enabled = $false
    $ダイアログ.Controls.Add($コンボ_タイプ)

    # OKボタン
    $ボタン_OK = New-Object System.Windows.Forms.Button
    $ボタン_OK.Text = "OK"
    $ボタン_OK.Location = New-Object System.Drawing.Point(230, 140)
    $ボタン_OK.Size = New-Object System.Drawing.Size(80, 30)
    $ボタン_OK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $ダイアログ.Controls.Add($ボタン_OK)

    # キャンセルボタン
    $ボタン_キャンセル = New-Object System.Windows.Forms.Button
    $ボタン_キャンセル.Text = "キャンセル"
    $ボタン_キャンセル.Location = New-Object System.Drawing.Point(320, 140)
    $ボタン_キャンセル.Size = New-Object System.Drawing.Size(90, 30)
    $ボタン_キャンセル.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $ダイアログ.Controls.Add($ボタン_キャンセル)

    $ダイアログ.AcceptButton = $ボタン_OK
    $ダイアログ.CancelButton = $ボタン_キャンセル

    # 前面表示設定
    フォームを前面表示に設定 -フォーム $ダイアログ

    $メインメニューハンドル = メインメニューを最小化
    $result = $ダイアログ.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return @{
            name = $テキスト_変数名.Text.Trim()
            value = $テキスト_値.Text
            type = $変数情報.type
            displayValue = $テキスト_値.Text
        }
    }

    return $null
}


# ============================================
# フォルダ切替ダイアログ
# ============================================
function フォルダ切替を表示 {
    <#
    .SYNOPSIS
    フォルダ切替ダイアログを表示（PowerShell Windows Forms版）

    .DESCRIPTION
    フォルダの一覧を表示し、選択・新規作成を行うダイアログを表示します。

    .PARAMETER フォルダリスト
    現在のフォルダリスト（配列）

    .PARAMETER 現在のフォルダ
    現在選択されているフォルダ名

    .EXAMPLE
    $result = フォルダ切替を表示 -フォルダリスト @("folder1", "folder2") -現在のフォルダ "folder1"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$フォルダリスト,

        [Parameter(Mandatory = $false)]
        [string]$現在のフォルダ = ""
    )


    # フォルダリストをスクリプト変数に保存
    $script:現在のフォルダリスト = [System.Collections.ArrayList]::new($フォルダリスト)
    $script:選択されたフォルダ = $null
    $script:新規作成されたフォルダ = $null

    # フォーム作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "フォルダ管理"
    $フォーム.Size = New-Object System.Drawing.Size(500, 450)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $フォーム.MaximizeBox = $false

    # 説明ラベル
    $ラベル_説明 = New-Object System.Windows.Forms.Label
    $ラベル_説明.Text = "フォルダを選択してください:"
    $ラベル_説明.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル_説明.AutoSize = $true
    $フォーム.Controls.Add($ラベル_説明)

    # 現在のフォルダ表示ラベル
    if ($現在のフォルダ) {
        $ラベル_現在 = New-Object System.Windows.Forms.Label
        $ラベル_現在.Text = "現在のフォルダ: $現在のフォルダ"
        $ラベル_現在.Location = New-Object System.Drawing.Point(20, 45)
        $ラベル_現在.AutoSize = $true
        $ラベル_現在.ForeColor = [System.Drawing.Color]::Blue
        $フォーム.Controls.Add($ラベル_現在)
    }

    # ListBox作成（フォルダ一覧表示）
    $リストボックス = New-Object System.Windows.Forms.ListBox
    $リストボックス.Location = New-Object System.Drawing.Point(20, 75)
    $リストボックス.Size = New-Object System.Drawing.Size(440, 250)
    $リストボックス.Font = New-Object System.Drawing.Font("Consolas", 10)
    $フォーム.Controls.Add($リストボックス)

    # ListBox更新関数
    function Update-FolderListBox {
        $リストボックス.Items.Clear()
        foreach ($folder in $script:現在のフォルダリスト) {
            $リストボックス.Items.Add($folder) | Out-Null
        }

        # 現在のフォルダを選択状態にする
        if ($現在のフォルダ -and $script:現在のフォルダリスト.Contains($現在のフォルダ)) {
            $index = $script:現在のフォルダリスト.IndexOf($現在のフォルダ)
            $リストボックス.SelectedIndex = $index
        }

    }

    # 選択ボタン
    $ボタン_選択 = New-Object System.Windows.Forms.Button
    $ボタン_選択.Text = "選択"
    $ボタン_選択.Location = New-Object System.Drawing.Point(20, 345)
    $ボタン_選択.Size = New-Object System.Drawing.Size(100, 35)
    $フォーム.Controls.Add($ボタン_選択)

    # 新規作成ボタン
    $ボタン_新規作成 = New-Object System.Windows.Forms.Button
    $ボタン_新規作成.Text = "新規作成"
    $ボタン_新規作成.Location = New-Object System.Drawing.Point(130, 345)
    $ボタン_新規作成.Size = New-Object System.Drawing.Size(100, 35)
    $フォーム.Controls.Add($ボタン_新規作成)

    # 削除ボタン
    $ボタン_削除 = New-Object System.Windows.Forms.Button
    $ボタン_削除.Text = "削除"
    $ボタン_削除.Location = New-Object System.Drawing.Point(240, 345)
    $ボタン_削除.Size = New-Object System.Drawing.Size(100, 35)
    $ボタン_削除.ForeColor = [System.Drawing.Color]::Red
    $フォーム.Controls.Add($ボタン_削除)

    # キャンセルボタン
    $ボタン_キャンセル = New-Object System.Windows.Forms.Button
    $ボタン_キャンセル.Text = "キャンセル"
    $ボタン_キャンセル.Location = New-Object System.Drawing.Point(360, 345)
    $ボタン_キャンセル.Size = New-Object System.Drawing.Size(100, 35)
    $ボタン_キャンセル.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $フォーム.Controls.Add($ボタン_キャンセル)

    # 選択ボタンクリックイベント
    $ボタン_選択.Add_Click({
        if ($リストボックス.SelectedItem) {
            $script:選択されたフォルダ = $リストボックス.SelectedItem.ToString()
            $フォーム.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $フォーム.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                "フォルダを選択してください。",
                "フォルダ切替",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    })

    # 新規作成ボタンクリックイベント
    $ボタン_新規作成.Add_Click({
        # 新規フォルダ名入力ダイアログ
        $入力フォーム = New-Object System.Windows.Forms.Form
        $入力フォーム.Text = "新しいフォルダを作成"
        $入力フォーム.Size = New-Object System.Drawing.Size(400, 150)
        $入力フォーム.StartPosition = "CenterParent"
        $入力フォーム.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        $入力フォーム.MaximizeBox = $false
        $入力フォーム.MinimizeBox = $false

        $ラベル = New-Object System.Windows.Forms.Label
        $ラベル.Text = "新しいフォルダ名:"
        $ラベル.Location = New-Object System.Drawing.Point(20, 20)
        $ラベル.AutoSize = $true
        $入力フォーム.Controls.Add($ラベル)

        $テキストボックス = New-Object System.Windows.Forms.TextBox
        $テキストボックス.Location = New-Object System.Drawing.Point(20, 50)
        $テキストボックス.Size = New-Object System.Drawing.Size(340, 20)
        $入力フォーム.Controls.Add($テキストボックス)

        $ボタン_OK = New-Object System.Windows.Forms.Button
        $ボタン_OK.Text = "作成"
        $ボタン_OK.Location = New-Object System.Drawing.Point(200, 80)
        $ボタン_OK.Size = New-Object System.Drawing.Size(75, 25)
        $ボタン_OK.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $入力フォーム.Controls.Add($ボタン_OK)

        $ボタン_キャンセル2 = New-Object System.Windows.Forms.Button
        $ボタン_キャンセル2.Text = "キャンセル"
        $ボタン_キャンセル2.Location = New-Object System.Drawing.Point(285, 80)
        $ボタン_キャンセル2.Size = New-Object System.Drawing.Size(75, 25)
        $ボタン_キャンセル2.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $入力フォーム.Controls.Add($ボタン_キャンセル2)

        $入力フォーム.AcceptButton = $ボタン_OK
        $入力フォーム.CancelButton = $ボタン_キャンセル2

        # 前面表示設定
        フォームを前面表示に設定 -フォーム $入力フォーム

        $メインメニューハンドル = メインメニューを最小化
        $result = $入力フォーム.ShowDialog()
        メインメニューを復元 -ハンドル $メインメニューハンドル

        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $新しいフォルダ名 = $テキストボックス.Text.Trim()

            if ([string]::IsNullOrWhiteSpace($新しいフォルダ名)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "フォルダ名を入力してください。",
                    "エラー",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
                return
            }

            if ($script:現在のフォルダリスト.Contains($新しいフォルダ名)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "そのフォルダは既に存在します。",
                    "エラー",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
                return
            }

            $script:現在のフォルダリスト.Add($新しいフォルダ名) | Out-Null
            $script:新規作成されたフォルダ = $新しいフォルダ名
            Update-FolderListBox

            # 作成したフォルダを選択状態にする
            $index = $script:現在のフォルダリスト.IndexOf($新しいフォルダ名)
            $リストボックス.SelectedIndex = $index
        }
    })

    # 削除ボタンクリックイベント
    $ボタン_削除.Add_Click({
        if ($リストボックス.SelectedItem) {
            $削除対象フォルダ = $リストボックス.SelectedItem.ToString()

            # 現在使用中のフォルダは削除不可
            if ($削除対象フォルダ -eq $現在のフォルダ) {
                [System.Windows.Forms.MessageBox]::Show(
                    "現在使用中のフォルダは削除できません。`n別のフォルダに切り替えてから削除してください。",
                    "削除エラー",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
                return
            }

            # 確認ダイアログ
            $確認結果 = [System.Windows.Forms.MessageBox]::Show(
                "フォルダ「$削除対象フォルダ」を削除しますか？`n`nこの操作は元に戻せません。",
                "フォルダ削除の確認",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )

            if ($確認結果 -eq [System.Windows.Forms.DialogResult]::Yes) {

                # 03_historyフォルダからフォルダを削除
                $historyPath = Join-Path $global:RootDir "03_history"
                $削除パス = Join-Path $historyPath $削除対象フォルダ

                if (Test-Path $削除パス) {
                    try {
                        Remove-Item -Path $削除パス -Recurse -Force

                        # リストから削除
                        $script:現在のフォルダリスト.Remove($削除対象フォルダ)
                        Update-FolderListBox

                        [System.Windows.Forms.MessageBox]::Show(
                            "フォルダ「$削除対象フォルダ」を削除しました。",
                            "削除完了",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Information
                        ) | Out-Null
                    } catch {
                        [System.Windows.Forms.MessageBox]::Show(
                            "フォルダの削除に失敗しました。`n$($_.Exception.Message)",
                            "削除エラー",
                            [System.Windows.Forms.MessageBoxButtons]::OK,
                            [System.Windows.Forms.MessageBoxIcon]::Error
                        ) | Out-Null
                    }
                } else {
                    # リストからは削除
                    $script:現在のフォルダリスト.Remove($削除対象フォルダ)
                    Update-FolderListBox
                }
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                "削除するフォルダを選択してください。",
                "フォルダ削除",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    })

    # ListBoxダブルクリックで選択
    $リストボックス.Add_DoubleClick({
        if ($リストボックス.SelectedItem) {
            $script:選択されたフォルダ = $リストボックス.SelectedItem.ToString()
            $フォーム.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $フォーム.Close()
        }
    })

    # 初期表示
    Update-FolderListBox

    # 前面表示設定
    フォームを前面表示に設定 -フォーム $フォーム

    $メインメニューハンドル = メインメニューを最小化
    $ダイアログ結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル


    if ($ダイアログ結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        return @{
            success = $true
            action = "select"
            folderName = $script:選択されたフォルダ
            newFolder = $script:新規作成されたフォルダ
        }
    } else {
        return $null
    }
}


# ============================================
# コード結果表示ダイアログ
# ============================================
function コード結果を表示 {
    <#
    .SYNOPSIS
    コード生成結果を表示（PowerShell Windows Forms版）

    .DESCRIPTION
    生成されたコードと情報を表示し、コピーやファイルを開く操作を提供します。

    .PARAMETER 生成結果
    コード生成結果を含むハッシュテーブル
    - code: 生成されたコード
    - nodeCount: ノード数
    - outputPath: 出力先パス
    - timestamp: 生成時刻

    .EXAMPLE
    $result = コード結果を表示 -生成結果 @{ code = "..."; nodeCount = 5; outputPath = "C:\path\to\file.ps1"; timestamp = "2025-11-15 10:30:00" }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$生成結果
    )


    # フォーム作成
    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = "✅ コード生成完了"
    $フォーム.Size = New-Object System.Drawing.Size(900, 700)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
    $フォーム.MinimumSize = New-Object System.Drawing.Size(700, 500)

    # 情報パネル
    $パネル_情報 = New-Object System.Windows.Forms.Panel
    $パネル_情報.Location = New-Object System.Drawing.Point(20, 20)
    $パネル_情報.Size = New-Object System.Drawing.Size(840, 100)
    $パネル_情報.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $パネル_情報.BackColor = [System.Drawing.Color]::FromArgb(232, 245, 233)  # Light green
    $フォーム.Controls.Add($パネル_情報)

    # ノード数ラベル
    $ラベル_ノード数 = New-Object System.Windows.Forms.Label
    $ラベル_ノード数.Text = "📊 ノード数: $($生成結果.nodeCount)個"
    $ラベル_ノード数.Location = New-Object System.Drawing.Point(15, 15)
    $ラベル_ノード数.AutoSize = $true
    $ラベル_ノード数.Font = New-Object System.Drawing.Font("メイリオ", 10, [System.Drawing.FontStyle]::Regular)
    $パネル_情報.Controls.Add($ラベル_ノード数)

    # 出力先ラベル
    $出力先テキスト = if ($生成結果.outputPath) { $生成結果.outputPath } else { "（メモリ内のみ）" }
    $ラベル_出力先 = New-Object System.Windows.Forms.Label
    $ラベル_出力先.Text = "📁 出力先: $出力先テキスト"
    $ラベル_出力先.Location = New-Object System.Drawing.Point(15, 40)
    $ラベル_出力先.Size = New-Object System.Drawing.Size(800, 20)
    $ラベル_出力先.Font = New-Object System.Drawing.Font("メイリオ", 10, [System.Drawing.FontStyle]::Regular)
    $パネル_情報.Controls.Add($ラベル_出力先)

    # 生成時刻ラベル
    $時刻テキスト = if ($生成結果.timestamp) { $生成結果.timestamp } else { Get-Date -Format "yyyy/MM/dd HH:mm:ss" }
    $ラベル_時刻 = New-Object System.Windows.Forms.Label
    $ラベル_時刻.Text = "⏱️ 生成時刻: $時刻テキスト"
    $ラベル_時刻.Location = New-Object System.Drawing.Point(15, 65)
    $ラベル_時刻.AutoSize = $true
    $ラベル_時刻.Font = New-Object System.Drawing.Font("メイリオ", 10, [System.Drawing.FontStyle]::Regular)
    $パネル_情報.Controls.Add($ラベル_時刻)

    # コードプレビューラベル
    $ラベル_コード = New-Object System.Windows.Forms.Label
    $ラベル_コード.Text = "生成されたコード:"
    $ラベル_コード.Location = New-Object System.Drawing.Point(20, 135)
    $ラベル_コード.AutoSize = $true
    $ラベル_コード.Font = New-Object System.Drawing.Font("メイリオ", 10, [System.Drawing.FontStyle]::Bold)
    $フォーム.Controls.Add($ラベル_コード)

    # コードプレビュー TextBox
    $テキスト_コード = New-Object System.Windows.Forms.TextBox
    $テキスト_コード.Location = New-Object System.Drawing.Point(20, 160)
    $テキスト_コード.Size = New-Object System.Drawing.Size(840, 430)
    $テキスト_コード.Multiline = $true
    $テキスト_コード.ReadOnly = $true
    $テキスト_コード.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
    $テキスト_コード.Font = New-Object System.Drawing.Font("Consolas", 10)
    $テキスト_コード.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
    $テキスト_コード.Text = $生成結果.code
    $テキスト_コード.WordWrap = $false
    $フォーム.Controls.Add($テキスト_コード)

    # リサイズイベント（コントロールのサイズを調整）
    $フォーム.Add_Resize({
        $newWidth = $フォーム.ClientSize.Width - 40
        $newHeight = $フォーム.ClientSize.Height - 180

        $パネル_情報.Width = $newWidth
        $テキスト_コード.Size = New-Object System.Drawing.Size($newWidth, ($newHeight - 70))

        # ボタンの位置を調整
        $ボタンY = $フォーム.ClientSize.Height - 50
        $ボタン_コピー.Location = New-Object System.Drawing.Point(20, $ボタンY)
        $ボタン_ファイル開く.Location = New-Object System.Drawing.Point(140, $ボタンY)
        $ボタン_ISE編集.Location = New-Object System.Drawing.Point(280, $ボタンY)
        $ボタン_EXE作成.Location = New-Object System.Drawing.Point(400, $ボタンY)
        $ボタン_実行.Location = New-Object System.Drawing.Point(520, $ボタンY)
        $ボタン_閉じる.Location = New-Object System.Drawing.Point(($フォーム.ClientSize.Width - 120), $ボタンY)
    })

    # コピーボタン
    $ボタン_コピー = New-Object System.Windows.Forms.Button
    $ボタン_コピー.Text = "📋 コピー"
    $ボタン_コピー.Location = New-Object System.Drawing.Point(20, 600)
    $ボタン_コピー.Size = New-Object System.Drawing.Size(110, 35)
    $フォーム.Controls.Add($ボタン_コピー)

    # ファイルを開くボタン
    $ボタン_ファイル開く = New-Object System.Windows.Forms.Button
    $ボタン_ファイル開く.Text = "📂 ファイルを開く"
    $ボタン_ファイル開く.Location = New-Object System.Drawing.Point(140, 600)
    $ボタン_ファイル開く.Size = New-Object System.Drawing.Size(130, 35)
    $フォーム.Controls.Add($ボタン_ファイル開く)

    # ファイルパスがない場合は無効化
    if (-not $生成結果.outputPath) {
        $ボタン_ファイル開く.Enabled = $false
    }

    # ISEで編集ボタン
    $ボタン_ISE編集 = New-Object System.Windows.Forms.Button
    $ボタン_ISE編集.Text = "✏️ ISEで編集"
    $ボタン_ISE編集.Location = New-Object System.Drawing.Point(280, 600)
    $ボタン_ISE編集.Size = New-Object System.Drawing.Size(110, 35)
    $フォーム.Controls.Add($ボタン_ISE編集)

    # ファイルパスがない場合は無効化
    if (-not $生成結果.outputPath) {
        $ボタン_ISE編集.Enabled = $false
    }

    # EXE作成ボタン
    $ボタン_EXE作成 = New-Object System.Windows.Forms.Button
    $ボタン_EXE作成.Text = "🔧 EXE作成"
    $ボタン_EXE作成.Location = New-Object System.Drawing.Point(400, 600)
    $ボタン_EXE作成.Size = New-Object System.Drawing.Size(110, 35)
    $ボタン_EXE作成.BackColor = [System.Drawing.Color]::FromArgb(255, 243, 224)  # Light orange
    $フォーム.Controls.Add($ボタン_EXE作成)

    # ファイルパスがない場合は無効化
    if (-not $生成結果.outputPath) {
        $ボタン_EXE作成.Enabled = $false
    }

    # 実行ボタン
    $ボタン_実行 = New-Object System.Windows.Forms.Button
    $ボタン_実行.Text = "🔥 実行"
    $ボタン_実行.Location = New-Object System.Drawing.Point(520, 600)
    $ボタン_実行.Size = New-Object System.Drawing.Size(100, 35)
    $ボタン_実行.BackColor = [System.Drawing.Color]::FromArgb(255, 200, 150)  # Orange
    $フォーム.Controls.Add($ボタン_実行)

    # 閉じるボタン
    $ボタン_閉じる = New-Object System.Windows.Forms.Button
    $ボタン_閉じる.Text = "閉じる"
    $ボタン_閉じる.Location = New-Object System.Drawing.Point(760, 600)
    $ボタン_閉じる.Size = New-Object System.Drawing.Size(100, 35)
    $ボタン_閉じる.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $フォーム.Controls.Add($ボタン_閉じる)

    # コピーボタンクリックイベント
    $ボタン_コピー.Add_Click({
        try {
            # 一時ファイル経由 + STAプロセスで日本語対応クリップボードコピー
            $tempFile = [System.IO.Path]::GetTempFileName()
            $テキスト_コード.Text | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline

            # STAモードの別プロセスでクリップボードにコピー
            $copyScript = "Get-Content -Path '$tempFile' -Raw -Encoding UTF8 | Set-Clipboard; Remove-Item -Path '$tempFile' -Force"
            Start-Process powershell -ArgumentList "-STA", "-NoProfile", "-WindowStyle", "Hidden", "-Command", $copyScript -Wait

            [System.Windows.Forms.MessageBox]::Show(
                "生成されたコードをクリップボードにコピーしました！",
                "コピー完了",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "コピーに失敗しました: $_",
                "エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    })

    # ファイルを開くボタンクリックイベント
    $ボタン_ファイル開く.Add_Click({
        if ($生成結果.outputPath -and (Test-Path $生成結果.outputPath)) {
            try {
                Start-Process $生成結果.outputPath
            } catch {
                [System.Windows.Forms.MessageBox]::Show(
                    "ファイルを開けませんでした: $_",
                    "エラー",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                "ファイルが見つかりません。",
                "エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    })

    # ISEで編集ボタンクリックイベント
    $ボタン_ISE編集.Add_Click({
        if ($生成結果.outputPath -and (Test-Path $生成結果.outputPath)) {
            try {
                Start-Process -FilePath "powershell_ise.exe" -ArgumentList $生成結果.outputPath
            } catch {
                [System.Windows.Forms.MessageBox]::Show(
                    "PowerShell ISEを起動できませんでした: $_",
                    "エラー",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                ) | Out-Null
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show(
                "ファイルが見つかりません。",
                "エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    })

    # EXE作成ボタンクリックイベント
    $ボタン_EXE作成.Add_Click({
        if (-not $生成結果.outputPath -or -not (Test-Path $生成結果.outputPath)) {
            [System.Windows.Forms.MessageBox]::Show(
                "PowerShellファイルが見つかりません。",
                "エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }

        try {

            # ps2exeモジュールの存在確認
            $ps2exeModule = Get-Module -ListAvailable -Name ps2exe | Select-Object -First 1
            if (-not $ps2exeModule) {
                throw "ps2exeモジュールがインストールされていません。`nInstall-Module ps2exe でインストールしてください。"
            }

            # robot-profile.jsonのパスを解決（メタデータ用に先に読み込む）
            $robotProfilePath = $null
            $profileContent = $null

            # 方法1: $global:RootDir から取得
            if ($global:RootDir -and (Test-Path (Join-Path $global:RootDir "robot-profile.json"))) {
                $robotProfilePath = Join-Path $global:RootDir "robot-profile.json"
            }
            # 方法2: $global:folderPath から2階層上
            elseif ($global:folderPath) {
                $rootFromFolder = Split-Path (Split-Path $global:folderPath -Parent) -Parent
                $pathFromFolder = Join-Path $rootFromFolder "robot-profile.json"
                if (Test-Path $pathFromFolder) {
                    $robotProfilePath = $pathFromFolder
                }
            }
            # 方法3: 出力ファイルから3階層上
            if (-not $robotProfilePath -and $生成結果.outputPath) {
                $rootFromOutput = Split-Path (Split-Path (Split-Path $生成結果.outputPath -Parent) -Parent) -Parent
                $pathFromOutput = Join-Path $rootFromOutput "robot-profile.json"
                if (Test-Path $pathFromOutput) {
                    $robotProfilePath = $pathFromOutput
                }
            }

            # robot-profile.jsonを読み込み
            if ($robotProfilePath -and (Test-Path $robotProfilePath)) {
                $profileContent = Get-Content -Path $robotProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json
            }

            # バージョン自動インクリメント
            $currentVersion = "1.0.0.0"
            if ($profileContent -and $profileContent.version) {
                $currentVersion = $profileContent.version
            }
            # バージョンをインクリメント（最後の数字を+1）
            $versionParts = $currentVersion -split '\.'
            if ($versionParts.Count -eq 4) {
                $versionParts[3] = [int]$versionParts[3] + 1
                $newVersion = $versionParts -join '.'
            } else {
                $newVersion = "1.0.0.1"
            }

            # ロボット名からメタデータとファイル名を設定
            $robotName = if ($profileContent -and $profileContent.name -and $profileContent.name -ne "") {
                $profileContent.name
            } else {
                "RPA自動化ツール"
            }
            $robotAuthor = if ($profileContent -and $profileContent.author -and $profileContent.author -ne "") {
                $profileContent.author
            } else {
                ""
            }
            $robotRole = if ($profileContent -and $profileContent.role -and $profileContent.role -ne "") {
                $profileContent.role
            } else {
                "UIpowershellで生成された自動化スクリプト"
            }
            # 表示設定を取得（デフォルトはtrue）
            $hasDisplay = $true
            if ($profileContent -and $null -ne $profileContent.hasDisplay) {
                $hasDisplay = [bool]$profileContent.hasDisplay
            }

            # メタ情報をrobot-profile.jsonから設定
            # ps2exeでは -title がWindowsの「ファイルの説明」に表示される
            $metaTitle = $robotRole         # ファイルの説明 = 役割
            $metaDescription = $robotRole   # 説明 = 役割
            $metaProduct = $robotName       # 製品名 = ロボット名
            $metaVersion = $newVersion
            $metaCopyright = if ($robotAuthor -ne "") {
                "Copyright $(Get-Date -Format 'yyyy') $robotAuthor"
            } else {
                "Copyright $(Get-Date -Format 'yyyy')"
            }

            # ファイル名をロボット名から生成（特殊文字をサニタイズ）
            $safeFileName = $robotName -replace '[\\/:*?"<>|]', '_'  # Windowsで使えない文字を置換
            $safeFileName = $safeFileName -replace '\s+', '_'        # 連続スペースをアンダースコアに
            $safeFileName = $safeFileName.Trim('_')                  # 先頭・末尾のアンダースコアを削除
            if ($safeFileName -eq "" -or $safeFileName -eq "_") {
                $safeFileName = "output"
            }

            # 出力EXEパス（ロボット名.exe）
            $outputDir = Split-Path $生成結果.outputPath -Parent
            $exePath = Join-Path $outputDir "$safeFileName.exe"


            # 確認ダイアログ
            $確認結果 = [System.Windows.Forms.MessageBox]::Show(
                "EXEファイルを作成しますか？`n`n出力先: $exePath",
                "EXE作成確認",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($確認結果 -ne [System.Windows.Forms.DialogResult]::Yes) {
                return
            }

            # win32API.psm1を埋め込んだ一時ファイルを作成

            # win32API.psm1のパスを解決（複数の方法でフォールバック）
            $win32ApiPath = $null

            # 方法1: $global:RootDir から取得
            if ($global:RootDir -and (Test-Path (Join-Path $global:RootDir "win32API.psm1"))) {
                $win32ApiPath = Join-Path $global:RootDir "win32API.psm1"
            }
            # 方法2: $global:folderPath から2階層上（03_history/XXXX → root）
            elseif ($global:folderPath) {
                $rootFromFolder = Split-Path (Split-Path $global:folderPath -Parent) -Parent
                $pathFromFolder = Join-Path $rootFromFolder "win32API.psm1"
                if (Test-Path $pathFromFolder) {
                    $win32ApiPath = $pathFromFolder
                }
            }
            # 方法3: 出力ファイルから3階層上（03_history/XXXX/output.ps1 → root）
            if (-not $win32ApiPath -and $生成結果.outputPath) {
                $rootFromOutput = Split-Path (Split-Path (Split-Path $生成結果.outputPath -Parent) -Parent) -Parent
                $pathFromOutput = Join-Path $rootFromOutput "win32API.psm1"
                if (Test-Path $pathFromOutput) {
                    $win32ApiPath = $pathFromOutput
                }
            }

            $tempScriptPath = $生成結果.outputPath -replace '\.ps1$', '_combined.ps1'

            if ($win32ApiPath -and (Test-Path $win32ApiPath)) {
                # win32API.psm1の内容を読み込み
                $win32ApiContent = Get-Content -Path $win32ApiPath -Raw -Encoding UTF8

                # 元のスクリプトを読み込み
                $originalScript = Get-Content -Path $生成結果.outputPath -Raw -Encoding UTF8

                # 表示なしの場合、Write-Host を削除
                if (-not $hasDisplay) {
                    # Write-Host行を削除（複数行対応）
                    $originalScript = $originalScript -replace '(?m)^\s*Write-Host\s+.*$', '# [サイレント] Write-Host削除'
                    $win32ApiContent = $win32ApiContent -replace '(?m)^\s*Write-Host\s+.*$', '# [サイレント] Write-Host削除'
                }

                # 結合（win32API.psm1の関数を先頭に配置）
                $combinedScript = @"
# ============================================
# win32API.psm1 埋め込み（EXE用）
# ============================================
$win32ApiContent

# ============================================
# 生成されたスクリプト
# ============================================
$originalScript
"@
                # 一時ファイルに保存
                Set-Content -Path $tempScriptPath -Value $combinedScript -Encoding UTF8 -Force

                $inputFileForExe = $tempScriptPath
            } else {

                # 表示なしの場合、Write-Hostを削除
                if (-not $hasDisplay) {
                    $originalScript = Get-Content -Path $生成結果.outputPath -Raw -Encoding UTF8
                    $originalScript = $originalScript -replace '(?m)^\s*Write-Host\s+.*$', '# [サイレント] Write-Host削除'
                    Set-Content -Path $tempScriptPath -Value $originalScript -Encoding UTF8 -Force
                    $inputFileForExe = $tempScriptPath
                } else {
                    $inputFileForExe = $生成結果.outputPath
                }
            }

            # ロボットアイコンをICOファイルに変換（$profileContentは既に読み込み済み）
            $iconPath = $null

            if ($profileContent) {
                try {
                    Add-Type -AssemblyName System.Drawing

                    $iconSize = 256
                    $resized = New-Object System.Drawing.Bitmap($iconSize, $iconSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
                    $graphics = [System.Drawing.Graphics]::FromImage($resized)
                    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

                    # ユーザーがアップロードした画像があるかチェック
                    $userImageData = $profileContent.image
                    $hasUserImage = $userImageData -and $userImageData -ne "" -and $userImageData.StartsWith("data:image")

                    if ($hasUserImage) {
                        # ユーザー画像を使用

                        # Base64データから画像を作成
                        $base64Data = $userImageData -replace '^data:image/[^;]+;base64,', ''
                        $imageBytes = [Convert]::FromBase64String($base64Data)
                        $ms = New-Object System.IO.MemoryStream($imageBytes, 0, $imageBytes.Length)
                        $userBitmap = [System.Drawing.Bitmap]::FromStream($ms)

                        # 背景色で塗りつぶし
                        $bgColorValue = $profileContent.bgcolor
                        if ($bgColorValue -and $bgColorValue -ne "") {
                            $bgColor = [System.Drawing.ColorTranslator]::FromHtml($bgColorValue)
                            $graphics.Clear($bgColor)
                        } else {
                            $graphics.Clear([System.Drawing.Color]::White)
                        }

                        # ユーザー画像を全体に描画（大きく表示）
                        $graphics.DrawImage($userBitmap, 0, 0, $iconSize, $iconSize)
                        $userBitmap.Dispose()
                        $ms.Dispose()
                        $graphics.Dispose()

                        # ICOファイルとして保存
                        $iconPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "robot_icon_$(Get-Date -Format 'yyyyMMddHHmmss').ico")

                        # 直接ICOバイナリを生成
                        $icoMs = New-Object System.IO.MemoryStream
                        $bw = New-Object System.IO.BinaryWriter($icoMs)

                        # ICOヘッダー
                        $bw.Write([int16]0)      # 予約（0）
                        $bw.Write([int16]1)      # タイプ（1=ICO）
                        $bw.Write([int16]1)      # 画像数

                        # 画像エントリ
                        $bw.Write([byte]0)       # 幅（0=256）
                        $bw.Write([byte]0)       # 高さ（0=256）
                        $bw.Write([byte]0)       # カラーパレット数
                        $bw.Write([byte]0)       # 予約
                        $bw.Write([int16]1)      # カラープレーン
                        $bw.Write([int16]32)     # ビット深度

                        # PNG データを取得
                        $pngMs = New-Object System.IO.MemoryStream
                        $resized.Save($pngMs, [System.Drawing.Imaging.ImageFormat]::Png)
                        $pngData = $pngMs.ToArray()
                        $pngMs.Dispose()

                        $bw.Write([int32]$pngData.Length)  # データサイズ
                        $bw.Write([int32]22)               # データオフセット

                        # PNGデータを書き込み
                        $bw.Write($pngData)

                        # ファイルに保存
                        [System.IO.File]::WriteAllBytes($iconPath, $icoMs.ToArray())
                        $bw.Dispose()
                        $icoMs.Dispose()
                        $resized.Dispose()

                    } else {
                        # robo.png + 背景色を使用（デフォルト）

                        # robo.pngのパスを検索
                        $roboPngPath = $null
                        $profileDir = Split-Path $robotProfilePath -Parent
                        $uiDir = Join-Path $profileDir "ui"
                        if (Test-Path (Join-Path $uiDir "robo.png")) {
                            $roboPngPath = Join-Path $uiDir "robo.png"
                        } elseif (Test-Path (Join-Path $profileDir "robo.png")) {
                            $roboPngPath = Join-Path $profileDir "robo.png"
                        }

                        if ($roboPngPath) {

                            # 背景色で全体を塗りつぶし
                            $bgColorValue = $profileContent.bgcolor
                            if ($bgColorValue -and $bgColorValue -ne "") {
                                $bgColor = [System.Drawing.ColorTranslator]::FromHtml($bgColorValue)
                                $graphics.Clear($bgColor)
                            } else {
                                $graphics.Clear([System.Drawing.Color]::FromArgb(232, 244, 252))  # デフォルト薄いブルー
                            }

                            # ロボット画像を全体に描画（大きく表示）
                            $robotBitmap = [System.Drawing.Bitmap]::FromFile($roboPngPath)
                            $graphics.DrawImage($robotBitmap, 0, 0, $iconSize, $iconSize)
                            $robotBitmap.Dispose()
                            $graphics.Dispose()

                            # まずPNGとして保存（デバッグ用）
                            $tempPngPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "robot_icon_debug.png")
                            $resized.Save($tempPngPath, [System.Drawing.Imaging.ImageFormat]::Png)

                            # ICOファイルとして保存（複数サイズ対応）
                            $iconPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "robot_icon_$(Get-Date -Format 'yyyyMMddHHmmss').ico")

                            # 直接ICOバイナリを生成
                            $ms = New-Object System.IO.MemoryStream
                            $bw = New-Object System.IO.BinaryWriter($ms)

                            # ICOヘッダー
                            $bw.Write([int16]0)      # 予約（0）
                            $bw.Write([int16]1)      # タイプ（1=ICO）
                            $bw.Write([int16]1)      # 画像数

                            # 画像エントリ
                            $bw.Write([byte]0)       # 幅（0=256）
                            $bw.Write([byte]0)       # 高さ（0=256）
                            $bw.Write([byte]0)       # カラーパレット数
                            $bw.Write([byte]0)       # 予約
                            $bw.Write([int16]1)      # カラープレーン
                            $bw.Write([int16]32)     # ビット深度

                            # PNG データを取得
                            $pngMs = New-Object System.IO.MemoryStream
                            $resized.Save($pngMs, [System.Drawing.Imaging.ImageFormat]::Png)
                            $pngData = $pngMs.ToArray()
                            $pngMs.Dispose()

                            $bw.Write([int32]$pngData.Length)  # データサイズ
                            $bw.Write([int32]22)               # データオフセット

                            # PNGデータを書き込み
                            $bw.Write($pngData)

                            # ファイルに保存
                            [System.IO.File]::WriteAllBytes($iconPath, $ms.ToArray())
                            $bw.Dispose()
                            $ms.Dispose()
                            $resized.Dispose()

                        } else {
                        }
                    }
                } catch {
                    $iconPath = $null
                }
            }

            # ps2exeを実行（メタ情報付き）
            Import-Module ps2exe -Force

            if ($iconPath -and (Test-Path $iconPath)) {
                if ($hasDisplay) {
                    # 表示あり：コンソール付きで生成
                    Invoke-ps2exe -inputFile $inputFileForExe -outputFile $exePath `
                        -title $metaTitle -description $metaDescription -product $metaProduct `
                        -version $metaVersion -copyright $metaCopyright -iconFile $iconPath
                } else {
                    # 表示なし：サイレント（コンソールなし）で生成
                    Invoke-ps2exe -inputFile $inputFileForExe -outputFile $exePath -noConsole `
                        -title $metaTitle -description $metaDescription -product $metaProduct `
                        -version $metaVersion -copyright $metaCopyright -iconFile $iconPath
                }
                # 一時ICOファイルを削除
                Remove-Item -Path $iconPath -Force -ErrorAction SilentlyContinue
            } else {
                if ($hasDisplay) {
                    # 表示あり：コンソール付きで生成
                    Invoke-ps2exe -inputFile $inputFileForExe -outputFile $exePath `
                        -title $metaTitle -description $metaDescription -product $metaProduct `
                        -version $metaVersion -copyright $metaCopyright
                } else {
                    # 表示なし：サイレント（コンソールなし）で生成
                    Invoke-ps2exe -inputFile $inputFileForExe -outputFile $exePath -noConsole `
                        -title $metaTitle -description $metaDescription -product $metaProduct `
                        -version $metaVersion -copyright $metaCopyright
                }
            }

            # 一時ファイルを削除
            if ((Test-Path $tempScriptPath) -and ($tempScriptPath -ne $生成結果.outputPath)) {
                Remove-Item -Path $tempScriptPath -Force -ErrorAction SilentlyContinue
            }

            # 成功確認
            if (Test-Path $exePath) {

                # バージョンをrobot-profile.jsonに保存
                if ($robotProfilePath -and (Test-Path $robotProfilePath)) {
                    try {
                        $profileContent.version = $newVersion
                        $profileContent | ConvertTo-Json -Depth 10 | Set-Content -Path $robotProfilePath -Encoding UTF8 -Force
                    } catch {
                        # エラーを無視（意図的）
                    }
                }

                # 強制停止用batファイルを生成
                try {
                    $exeFileName = [System.IO.Path]::GetFileNameWithoutExtension($exePath)
                    $stopBatPath = Join-Path $outputDir "${exeFileName}_停止.bat"
                    $stopBatContent = @"
@echo off
chcp 65001 > nul
echo $exeFileName を強制停止します...
taskkill /F /IM "$exeFileName.exe" 2>nul
if %errorlevel% equ 0 (
    echo 停止しました
) else (
    echo プロセスが見つかりませんでした
)
pause
"@
                    Set-Content -Path $stopBatPath -Value $stopBatContent -Encoding UTF8 -Force
                } catch {
                    # エラーを無視（意図的）
                }

                $開く結果 = [System.Windows.Forms.MessageBox]::Show(
                    "EXEファイルを作成しました！`n`n$exePath`n`nバージョン: $newVersion`n`nフォルダを開きますか？",
                    "EXE作成完了",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )

                if ($開く結果 -eq [System.Windows.Forms.DialogResult]::Yes) {
                    # フォルダを開いてファイルを選択状態にする
                    Start-Process explorer.exe -ArgumentList "/select,`"$exePath`""
                }

                # ダイアログを閉じる
                $フォーム.Close()
            } else {
                throw "EXEファイルの作成に失敗しました"
            }

        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "EXE作成中にエラーが発生しました:`n`n$_",
                "EXE作成エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    })

    # 実行ボタンクリックイベント
    $ボタン_実行.Add_Click({
        try {

            # テキストボックスの内容を取得（編集されている可能性あり）
            $実行コード = $テキスト_コード.Text

            if ([string]::IsNullOrWhiteSpace($実行コード)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "実行するコードがありません。",
                    "エラー",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
                return
            }

            # 確認ダイアログ
            $確認結果 = [System.Windows.Forms.MessageBox]::Show(
                "生成されたコードを実行しますか？`n`n※ マウス・キーボード操作が含まれる場合、`n　 実行中は操作しないでください。",
                "実行確認",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($確認結果 -ne [System.Windows.Forms.DialogResult]::Yes) {
                return
            }

            # RootDirを解決（複数の方法でフォールバック）
            $resolvedRootDir = $null

            # 方法1: $global:RootDir から取得
            if ($global:RootDir -and (Test-Path $global:RootDir)) {
                $resolvedRootDir = $global:RootDir
            }
            # 方法2: $global:folderPath から2階層上（03_history/XXXX → root）
            elseif ($global:folderPath) {
                $rootFromFolder = Split-Path (Split-Path $global:folderPath -Parent) -Parent
                if (Test-Path $rootFromFolder) {
                    $resolvedRootDir = $rootFromFolder
                }
            }
            # 方法3: 出力ファイルから3階層上（03_history/XXXX/output.ps1 → root）
            if (-not $resolvedRootDir -and $生成結果.outputPath) {
                $rootFromOutput = Split-Path (Split-Path (Split-Path $生成結果.outputPath -Parent) -Parent) -Parent
                if (Test-Path $rootFromOutput) {
                    $resolvedRootDir = $rootFromOutput
                }
            }


            # win32API.psm1を読み込み
            if ($resolvedRootDir) {
                $win32ApiPath = Join-Path $resolvedRootDir "win32API.psm1"
                if (Test-Path $win32ApiPath) {
                    Import-Module $win32ApiPath -Force -ErrorAction SilentlyContinue
                }

                # 汎用関数を読み込み
                $汎用関数パス = Join-Path $resolvedRootDir "13_コードサブ汎用関数.ps1"
                if (Test-Path $汎用関数パス) {
                    . $汎用関数パス
                }
            }

            # スクリプトを実行
            $output = Invoke-Expression $実行コード 2>&1 | Out-String

            [System.Windows.Forms.MessageBox]::Show(
                "🔥 コード実行完了！`n`n出力:`n$output",
                "実行完了",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null

        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "実行中にエラーが発生しました:`n`n$($_.Exception.Message)",
                "実行エラー",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    })

    # 前面表示設定
    フォームを前面表示に設定 -フォーム $フォーム

    $メインメニューハンドル = メインメニューを最小化
    $ダイアログ結果 = $フォーム.ShowDialog()
    メインメニューを復元 -ハンドル $メインメニューハンドル


    return @{
        success = $true
    }
}
