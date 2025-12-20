# ============================================
# モジュールレベルの初期化（関数の外で実行）
# ============================================

# メインメニュー最小化用のAPI定義（モジュールスコープ）
if (-not ([System.Management.Automation.PSTypeName]'UIGetMainMenuHelper').Type) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class UIGetMainMenuHelper {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    public const int SW_MINIMIZE = 6;
    public const int SW_RESTORE = 9;

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
}
"@
}

# モジュールスコープのメインメニュー最小化関数
function script:UIGet-メインメニューを最小化 {
    try {
        $handle = [UIGetMainMenuHelper]::FindUIpowershellWindow()
        if ($handle -ne [IntPtr]::Zero) {
            [UIGetMainMenuHelper]::ShowWindow($handle, [UIGetMainMenuHelper]::SW_MINIMIZE) | Out-Null
            return $handle
        }
    } catch {
        Write-Host "[UIGet] メインメニュー最小化エラー: $_" -ForegroundColor Yellow
    }
    return [IntPtr]::Zero
}

# モジュールスコープのメインメニュー復元関数
function script:UIGet-メインメニューを復元 {
    param([IntPtr]$ハンドル)
    try {
        if ($ハンドル -ne [IntPtr]::Zero) {
            [UIGetMainMenuHelper]::ShowWindow($ハンドル, [UIGetMainMenuHelper]::SW_RESTORE) | Out-Null
        }
    } catch {
        Write-Host "[UIGet] メインメニュー復元エラー: $_" -ForegroundColor Yellow
    }
}

# ============================================
# メイン関数
# ============================================
function Invoke-UIlement {
    param(
        [string]$Caller  # 呼び出し元の名前を受け取るパラメータ
    )


# 必要なアセンブリをロード
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 必要な型定義の準備（MouseHookとKeyboardHookを統合）
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

public class InputHook
{
    // マウスフック用の定数と変数
    private const int WH_MOUSE_LL = 14;
    private const int WM_LBUTTONDOWN = 0x0201;
    private static IntPtr mouseHookId = IntPtr.Zero;
    private static LowLevelMouseProc mouseHookProc = MouseHookCallback;

    // キーボードフック用の定数と変数
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_SYSKEYDOWN = 0x0104;
    private static IntPtr keyboardHookId = IntPtr.Zero;
    private static LowLevelKeyboardProc keyboardHookProc = KeyboardHookCallback;

    // デリゲートの定義
    public delegate IntPtr LowLevelMouseProc(int nCode, IntPtr wParam, IntPtr lParam);
    public delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    // WinAPI関数の宣言
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, Delegate lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    // ウィンドウハンドルを取得するための関数を宣言
    [DllImport("user32.dll")]
    private static extern IntPtr WindowFromPoint(System.Drawing.Point Point);

    [DllImport("user32.dll")]
    private static extern IntPtr GetAncestor(IntPtr hwnd, uint gaFlags);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    // マウスの位置を取得するための構造体
    [StructLayout(LayoutKind.Sequential)]
    public struct MSLLHOOKSTRUCT
    {
        public System.Drawing.Point pt;
        public int mouseData;
        public int flags;
        public int time;
        public IntPtr dwExtraInfo;
    }

    // キーボードフック用の構造体
    [StructLayout(LayoutKind.Sequential)]
    public struct KBDLLHOOKSTRUCT
    {
        public uint vkCode;
        public uint scanCode;
        public uint flags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    // フック状態を示すフラグ
    public static volatile bool IsMouseHooked = false;
    public static volatile bool IsKeyboardHooked = false;

    // 取得した情報を保持する変数
    public static IntPtr ClickedWindowHandle = IntPtr.Zero;
    public static string ClickedWindowTitle = "";
    public static volatile bool EscPressed = false;
    public static volatile bool F1Pressed = false;

    // マウスフックの設定
    public static void SetMouseHook()
    {
        if (mouseHookId != IntPtr.Zero)
        {
            UnhookMouse();
        }
        mouseHookId = SetWindowsHookEx(WH_MOUSE_LL, mouseHookProc, GetModuleHandle(Process.GetCurrentProcess().MainModule.ModuleName), 0);
        IsMouseHooked = true;
    }

    // キーボードフックの設定
    public static void SetKeyboardHook()
    {
        if (keyboardHookId != IntPtr.Zero)
        {
            UnhookKeyboard();
        }
        keyboardHookId = SetWindowsHookEx(WH_KEYBOARD_LL, keyboardHookProc, GetModuleHandle(Process.GetCurrentProcess().MainModule.ModuleName), 0);
        IsKeyboardHooked = true;
    }

    // マウスフックの解除
    public static void UnhookMouse()
    {
        UnhookWindowsHookEx(mouseHookId);
        mouseHookId = IntPtr.Zero;
        IsMouseHooked = false;
    }

    // キーボードフックの解除
    public static void UnhookKeyboard()
    {
        UnhookWindowsHookEx(keyboardHookId);
        keyboardHookId = IntPtr.Zero;
        IsKeyboardHooked = false;
    }

    // マウスフックのコールバック関数
    private static IntPtr MouseHookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && wParam == (IntPtr)WM_LBUTTONDOWN)
        {
            // マウスの座標を取得
            MSLLHOOKSTRUCT hookStruct = (MSLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(MSLLHOOKSTRUCT));

            // クリックされた位置にあるウィンドウのハンドルを取得
            IntPtr hWnd = WindowFromPoint(hookStruct.pt);

            // 最上位の親ウィンドウのハンドルを取得
            IntPtr rootHWnd = GetAncestor(hWnd, 2); // GA_ROOT = 2

            // ウィンドウタイトルを取得
            StringBuilder windowText = new StringBuilder(256);
            GetWindowText(rootHWnd, windowText, windowText.Capacity);
            ClickedWindowTitle = windowText.ToString();

            ClickedWindowHandle = rootHWnd;

            UnhookMouse();  // マウスフック解除
        }
        return CallNextHookEx(mouseHookId, nCode, wParam, lParam);
    }

    // キーボードフックのコールバック関数
    private static IntPtr KeyboardHookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if(nCode >= 0 && (wParam == (IntPtr)WM_KEYDOWN || wParam == (IntPtr)WM_SYSKEYDOWN))
        {
            KBDLLHOOKSTRUCT kbdStruct = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));
            if(kbdStruct.vkCode == (uint)Keys.Escape)
            {
                EscPressed = true;
            }
            else if(kbdStruct.vkCode == (uint)Keys.F1)
            {
                F1Pressed = true;
            }
        }
        return CallNextHookEx(keyboardHookId, nCode, wParam, lParam);
    }

    // 全てのフックを設定
    public static void SetHooks()
    {
        SetMouseHook();
        SetKeyboardHook();
    }

    // 全てのフックを解除
    public static void UnhookAll()
    {
        if (IsMouseHooked) UnhookMouse();
        if (IsKeyboardHooked) UnhookKeyboard();
    }
}
"@

# スクリプトの開始時に既存のフックを解除
[InputHook]::UnhookAll()
# フラグをリセット
[InputHook]::EscPressed = $false
[InputHook]::F1Pressed = $false

# Windows APIの関数宣言 (固有のクラス名を使用)
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class MyUniqueUser32 {
        [DllImport("user32.dll", CharSet=CharSet.Auto)]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
"@

try {
    # フックを設定
    [InputHook]::SetMouseHook()
    [InputHook]::SetKeyboardHook()

    function 出力クリックウィンドウ情報 {
        $handle = [InputHook]::ClickedWindowHandle
        $title = [InputHook]::ClickedWindowTitle

        # 不要な部分を削除
        $title = $title -replace ' - プロファイル.*', ''

        Write-Host "ウィンドウハンドル: $handle"
        Write-Host "ウィンドウタイトル: $title"
        # ハンドルとタイトルを一つの文字列に結合して返す
        return "$handle-$title"
    }

    # マウスクリック待機関数
    function マウスクリック待機関数 {
        # フックが解除されるまで待機
        while ([InputHook]::IsMouseHooked) {
            Start-Sleep -Milliseconds 100
        }

        # クリック後にウィンドウ情報を出力し、結合した結果を返す
        $windowInfo = 出力クリックウィンドウ情報
        Write-Host "ウィンドウ情報は $windowInfo"
        return $windowInfo
    }
    デバッグ表示 -表示文字 "ウインドウをクリックしてください" -表示時間秒 2
    # 関数を実行
    $windowInfo = マウスクリック待機関数


    # 結合されたウィンドウ情報をスプリットしてハンドルとタイトルに分割
    $splitInfo = $windowInfo -split '-'
    # スプリットしたウィンドウハンドルを整数に変換
    $handle = [int]$splitInfo[0]
    $title = $splitInfo[1]




    # UIAutomationCore.dll をロード
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes

    # UI要素を取得してCSVに出力する関数
    function Get-UIElementsToCsv {
        param (
            [Parameter(Mandatory = $true)]
            [IntPtr]$WindowHandle,
            [Parameter(Mandatory = $true)]
            [string]$CsvFilePath,
            [string]$WindowTitle,
            [int]$WaitSeconds = 30
        )
#-------------------------------------------------------------------------------
$timeout = 30  # タイムアウト時間（秒）

Write-Host "ウィンドウ内の要素を確認します..."

Add-Type -AssemblyName System.Windows.Forms

while ($true) {
    # ウィンドウをアクティブにし、ルート要素を取得
    ウインドウハンドルでアクティブにする -ウインドウハンドル $WindowHandle
    $rootElement = [System.Windows.Automation.AutomationElement]::FromHandle($WindowHandle)
    
    if ($rootElement -eq $null) {
        Write-Host "指定されたウィンドウハンドルから要素が取得できません。"
        return
    }
    
    # 現在の要素数を取得
    $elementCount = ($rootElement.FindAll(
        [System.Windows.Automation.TreeScope]::Subtree,
        [System.Windows.Automation.Condition]::TrueCondition
    )).Count
    Write-Host "現在の要素数: $elementCount"
    デバッグ表示 -表示文字 "現在の要素数: $elementCount" -表示時間秒 1

    $result = [System.Windows.Forms.MessageBox]::Show(
        "要素が $elementCount 件見つかりました。引き続き実行しますか？",
        "確認",
        [System.Windows.Forms.MessageBoxButtons]::YesNo
    )


    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        # 「はい」が選択された場合、要素数が増えるまでループ
        $prevElementCount = $elementCount
        $waitTime = 0

        while (($elementCount -le $prevElementCount) -and ($waitTime -lt $timeout)) {
            ウインドウハンドルでアクティブにする -ウインドウハンドル $WindowHandle
            Start-Sleep -Seconds 1
            $elementCount = ($rootElement.FindAll(
                [System.Windows.Automation.TreeScope]::Subtree,
                [System.Windows.Automation.Condition]::TrueCondition
            )).Count
            Write-Host "現在の要素数: $elementCount"
            デバッグ表示 -表示文字 "現在の要素数: $elementCount 待機時間: $waitTime" -表示時間秒 1
            $waitTime += 1
        }

        if ($elementCount -gt $prevElementCount) {
            Write-Host "要素数が前回より増えました。"
            # 要素数が増えたので、再度ループの先頭に戻り確認を行う
        } else {
            Write-Host "要素数が増えませんでした。タイムアウトまたは条件を満たさなかったため終了します。"
            break
        }
    } else {
        Write-Host "ユーザーが「いいえ」を選択しました。処理を終了します。"
        break
    }
}

デバッグ表示 -表示文字 "UI要素取得中" -表示時間秒 2
#-------------------------------------------------------------------------------



        $outputList = New-Object System.Collections.ArrayList

        #Start-Sleep -Seconds $WaitSeconds

        $rootElement.FindAll([System.Windows.Automation.TreeScope]::Subtree, [System.Windows.Automation.Condition]::TrueCondition) | ForEach-Object {
            $element = $_
            $patterns = $element.GetSupportedPatterns() | ForEach-Object {
                $_.ProgrammaticName -replace "Identifiers.Pattern", ""
            }
            $patternString = if ($patterns.Count -gt 0) { 
                $patterns -join "_" 
            } else { 
                "" 
            }

            $top = $element.Current.BoundingRectangle.Top
            $left = $element.Current.BoundingRectangle.Left

            # TopまたはLeftが∞もしくは-∞の場合、要素をスキップ
            if ([double]::IsInfinity($top) -or [double]::IsInfinity($left)) {
                return
            }

            $outputItem = New-Object PSObject -Property @{
                WindowTitle           = $WindowTitle
                AutomationId          = if ($element.Current.AutomationId) { $element.Current.AutomationId } else { "" }
                Name                  = if ($element.Current.Name) { $element.Current.Name } else { "" }
                ClassName             = if ($element.Current.ClassName) { $element.Current.ClassName } else { "" }
                LocalizedControlType  = if ($element.Current.LocalizedControlType) { $element.Current.LocalizedControlType } else { "" }
                Top                   = $top
                Left                  = $left
                Height                = $element.Current.BoundingRectangle.Height
                Width                 = $element.Current.BoundingRectangle.Width
                Patterns              = $patternString
            }

            [void]$outputList.Add($outputItem)
        }

        # 重複を削除
        $uniqueElements = $outputList | Select-Object -Unique -Property WindowTitle, AutomationId, Name, ClassName, LocalizedControlType, Top, Left, Height, Width, Patterns

        # 重複を削除した結果を一時的なCSVに保存
        $uniqueElements | Export-Csv -Path $CsvFilePath -NoTypeInformation -Encoding UTF8
        Write-Host "CSVファイルに出力が完了しました: $CsvFilePath"

        # 重複数を計算するためにCSVを再度読み込む
        $importedElements = Import-Csv -Path $CsvFilePath

        # 重複数を計算して追加
        $duplicateGroups = $importedElements | Group-Object -Property AutomationId, Name, ClassName, LocalizedControlType
        foreach ($group in $duplicateGroups) {
            $count = $group.Count
            foreach ($item in $group.Group) {
                $item | Add-Member -MemberType NoteProperty -Name DuplicateCount -Value $count -Force
            }
        }

        # 重複数を含めたCSVを再度保存
        $importedElements | Export-Csv -Path $CsvFilePath -NoTypeInformation -Encoding UTF8
    }

    # スクリプトのパスを取得
    $scriptPath = $PSScriptRoot

    if (-not $scriptPath) {
        $scriptPath = [System.IO.Path]::GetDirectoryName([System.Reflection.Assembly]::GetEntryAssembly().Location)
    }

    $csvPath = Join-Path -Path $scriptPath -ChildPath "output.csv"

    # UI要素をCSVに出力

    Get-UIElementsToCsv -WindowHandle $handle -CsvFilePath $csvPath -WindowTitle $title

    # UI要素を読み込む
    $uiElements = Import-Csv -Path $csvPath

    # ログファイルのパスを取得
    $logFilePath = Join-Path -Path $scriptPath -ChildPath "output_log.txt"

    # ログファイルの内容を読み込む関数
    function 更新ログ内容 {
        if (Test-Path $logFilePath) {
            $global:logContent = Get-Content $logFilePath -Raw
        } else {
            $global:logContent = "ログファイルが見つかりません。"
        }
    }

    # 初期ログ内容を読み込む
    更新ログ内容

    # 共通処理を関数化
    function ProcessSelectedPattern {
        param(
            [string]$selectedPattern,
            [string]$windowName,
            [string]$elementName,
            [string]$elementId,
            [string]$elementType,
            [string]$elementClassName,
            [double]$elementX,
            [double]$elementY
        )

        # 選択結果に基づいて、目的動作を決定
        $actionType = if ($selectedPattern -like "*Value*") { "入力" } else { "クリック" }


        # 呼び出し元によってテキストを変化させる
        if ($Caller -eq "AddonUI1") {
        # ログ出力（DuplicateCountを削除）
        $logEntry = 'UI操作 -ウインドウ名 "{0}" -名前 "{1}" -ID "{2}" -タイプ "{3}" -クラス名 "{4}" -パターン "{5}" -目的動作 "{6}" -入力内容 "" -要素X {7} -要素Y {8}' -f `
            $windowName, $elementName, $elementId, $elementType, $elementClassName, $selectedPattern, $actionType, $elementX, $elementY

        } elseif ($Caller -eq "AddonUI2") {
        # ログ出力（DuplicateCountを削除）
        $logEntry = '要素が存在するか  -ウインドウ名 "{0}" -名前 "{1}" -ID "{2}" -タイプ "{3}" -クラス名 "{4}"' -f `
            $windowName, $elementName, $elementId, $elementType, $elementClassName

        } else {
        # ログ出力（DuplicateCountを削除）
        $logEntry = 'UI操作 -ウインドウ名 "{0}" -名前 "{1}" -ID "{2}" -タイプ "{3}" -クラス名 "{4}" -パターン "{5}" -目的動作 "{6}" -入力内容 "" -要素X {7} -要素Y {8}' -f `
            $windowName, $elementName, $elementId, $elementType, $elementClassName, $selectedPattern, $actionType, $elementX, $elementY

        }







        [System.Windows.Forms.MessageBox]::Show($logEntry, "選択されたパターンの情報")

        # ログファイルに内容を出力
        Add-Content -Path $logFilePath -Value ($logEntry + "`n" + "-"*40 + "`n")



        




     $global:UIResult = $logEntry





        # ログ内容を更新
        更新ログ内容
        $logTextBox.Text = $global:logContent
    }

    # ハイライトフォームを作成
    $ハイライトフォーム = New-Object System.Windows.Forms.Form
    $ハイライトフォーム.Text = "ハイライトフォーム"
    $ハイライトフォーム.Width = 400
    $ハイライトフォーム.Height = 300
    $ハイライトフォーム.Opacity = 0.5  # 透明度を50%に設定
    $ハイライトフォーム.TopMost = $true  # 常に最前面に表示
    # タイトルバーを非表示にする
    $ハイライトフォーム.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None

    # フォームの背景色を設定（デフォルトは赤）
    $ハイライトフォーム.BackColor = [System.Drawing.Color]::Red

    # 描画用のパネルを作成
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $panel.BackColor = [System.Drawing.Color]::FromArgb(128, 255, 0, 0)  # 半透明の赤に設定

    $ハイライトフォーム.Controls.Add($panel)

    # 情報パネルを作成
    $情報パネル = New-Object System.Windows.Forms.Form
    $情報パネル.Text = "情報パネル"
    $情報パネル.Width = 300
    $情報パネル.Height = 250
    $情報パネル.Opacity = 0.8
    try {
        $情報パネル.BackColor = [System.Drawing.Color]::FromArgb(128, 0, 255, 0)
    } catch {
        # エラーを無視
    }
    $情報パネル.TopMost = $true  # 常に最前面に表示
    # タイトルバーを非表示にする
    $情報パネル.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None

    $情報パネル.Location = New-Object System.Drawing.Point(0, 0)

    # ラベルを情報パネルに追加
    $label2 = New-Object System.Windows.Forms.Label
    $label2.Dock = [System.Windows.Forms.DockStyle]::Top  # ラベルを情報パネルの上部に配置
    $label2.Height = 250  # ラベルの高さを増やしてテキストが収まるようにする
    $label2.TextAlign = [System.Drawing.ContentAlignment]::TopLeft  # テキストを左上に揃える
    $情報パネル.Controls.Add($label2)

    # サイドバーを作成
    $global:サイドバー = New-Object System.Windows.Forms.Form
    $global:サイドバー.Text = "サイドバー"
    $global:サイドバー.Width = 600  # 幅を広げる
    $global:サイドバー.Height = 600  # 高さを調整
    $global:サイドバー.Opacity = 0.9

    try {
        $global:サイドバー.BackColor = [System.Drawing.Color]::FromArgb(200, 255, 255, 0)  # 半透明の黄色
    } catch {
        # エラーを無視
    }

    $global:サイドバー.TopMost = $true  # 常に最前面に表示
    # タイトルバーを非表示にする
    $global:サイドバー.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None

    # サイドバーの初期状態は非表示にする
    $global:サイドバー.Visible = $false

    # サイドバーにテキストボックスを追加してログ内容を表示
    $logTextBox = New-Object System.Windows.Forms.TextBox
    $logTextBox.Multiline = $true
    $logTextBox.Dock = [System.Windows.Forms.DockStyle]::Fill
    $logTextBox.ReadOnly = $true
    $logTextBox.ScrollBars = 'Vertical'
    $logTextBox.Text = $global:logContent
    # 追加: テキストボックスがフォーカスを受け取らないように設定
    $logTextBox.TabStop = $false

    $global:サイドバー.Controls.Add($logTextBox)

    # ログ更新用のタイマーを設定
    $logUpdateTimer = New-Object System.Windows.Forms.Timer
    $logUpdateTimer.Interval = 1000  # 1秒ごとに更新

    $logUpdateTimer.Add_Tick({
        更新ログ内容
        $logTextBox.Text = $global:logContent

        # 選択位置と選択範囲を設定して選択状態を解除
        $logTextBox.SelectionStart = $logTextBox.Text.Length
        $logTextBox.SelectionLength = 0
    })

    # サイドバーの表示状態に応じてタイマーを制御
    $global:サイドバー.add_VisibleChanged({
        if ($global:サイドバー.Visible) {
            $logUpdateTimer.Start()
        } else {
            $logUpdateTimer.Stop()
        }
    })

    # 描画イベントを定義
    $panel.add_Paint({
        param ($sender, $e)
        
        # グラフィックスオブジェクトを取得
        $graphics = $e.Graphics
        
        # 線の色と幅を設定（ペンの色は常に白）
        $penColor = [System.Drawing.Color]::White
        $pen = New-Object System.Drawing.Pen($penColor, 2)
        
        # 矩形をウィンドウのふちに合わせて描画
        $graphics.DrawRectangle($pen, 0, 0, $panel.Width - 1, $panel.Height - 1)
        
        # リソースを解放
        $pen.Dispose()
    })

    # タイマーを設定してフォームの位置と色を更新
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 100

    $global:currentRowIndex = -1  # 現在のCSV行番号を保持

    # キーボードフックを設定（既に設定済みのためコメントアウト可能）
    # [InputHook]::SetKeyboardHook()

    $timer.Add_Tick({
        # キー入力のチェック
        if ([InputHook]::F1Pressed) {
            [InputHook]::F1Pressed = $false  # フラグをリセット

            # サイドバーの表示・非表示を切り替え
            if ($global:サイドバー.Visible) {
                $global:サイドバー.Hide()
            } else {
                $global:サイドバー.Show()
                # サイドバーの位置を固定（X=1500、Y=100）
                $global:サイドバー.Location = New-Object System.Drawing.Point(1500, 100)
                # 追加: アクティブコントロールを解除
                $global:サイドバー.ActiveControl = $null
            }
        }

        if ([InputHook]::EscPressed) {
            [InputHook]::UnhookAll()  # フックを解除
            $timer.Stop()
            $情報パネル.Close()
            $ハイライトフォーム.Close()
            $global:サイドバー.Close()
            $logUpdateTimer.Stop()
            return
        }

        $cursorPos = [System.Windows.Forms.Cursor]::Position
        $matchingElements = $uiElements | Where-Object {
            $element = $_
            $left = [double]$element.Left
            $top = [double]$element.Top
            $width = [double]$element.Width
            $height = [double]$element.Height
            $right = $left + $width
            $bottom = $top + $height
            ($cursorPos.X -ge ($left - 2)) -and ($cursorPos.X -le ($right + 2)) -and ($cursorPos.Y -ge ($top - 2)) -and ($cursorPos.Y -le ($bottom + 2))
        }
        if ($matchingElements.Count -gt 0) {
            $selectedElement = $matchingElements | Sort-Object {
                $width = [double]$_.Width
                $height = [double]$_.Height
                $width * $height
            } | Select-Object -First 1
            $global:currentRowIndex = $uiElements.IndexOf($selectedElement)
            $newWidth = [int][double]$selectedElement.Width
            $newHeight = [int][double]$selectedElement.Height
            $newX = [int][double]$selectedElement.Left
            $newY = [int][double]$selectedElement.Top
            $ハイライトフォーム.Width = $newWidth
            $ハイライトフォーム.Height = $newHeight
            $ハイライトフォーム.Location = New-Object System.Drawing.Point($newX, $newY)

            # パターンに応じてフォームの色を変更
            if ($selectedElement.Patterns -match 'Value') {
                # ValuePatternが含まれる場合、青色に設定
                $ハイライトフォーム.BackColor = [System.Drawing.Color]::Blue
                $panel.BackColor = [System.Drawing.Color]::FromArgb(128, 0, 0, 255)  # 半透明の青
            } else {
                # それ以外の場合、デフォルトの赤色に設定
                $ハイライトフォーム.BackColor = [System.Drawing.Color]::Red
                $panel.BackColor = [System.Drawing.Color]::FromArgb(128, 255, 0, 0)  # 半透明の赤
            }

            # マウスのY座標とX座標によって情報パネルの位置を変更
            if ($cursorPos.Y -le 200 -and $cursorPos.X -le 300) {
                $情報パネル.Location = New-Object System.Drawing.Point(10, 200)  # Y座標が200以上かつX座標が300以下の場合
            } else {
                $情報パネル.Location = New-Object System.Drawing.Point(10, 10)  # それ以外の場合
            }

            # 情報パネルのラベルに詳細情報を表示
            $label2.Text = "行番号: " + ($global:currentRowIndex + 1) + "`n" +
                           "AutomationId: " + $selectedElement.AutomationId + "`n" +
                           "Name: " + $selectedElement.Name + "`n" +
                           "ClassName: " + $selectedElement.ClassName + "`n" +
                           "LocalizedControlType: " + $selectedElement.LocalizedControlType + "`n" +
                           "DuplicateCount: " + $selectedElement.DuplicateCount + "`n" +
                           "Top: " + $selectedElement.Top + "`n" +
                           "Left: " + $selectedElement.Left + "`n" +
                           "Height: " + $selectedElement.Height + "`n" +
                           "Width: " + $selectedElement.Width + "`n" +
                           "パターン: " + $selectedElement.Patterns + "`n" +
                           "マウス座標: X=" + $cursorPos.X + ", Y=" + $cursorPos.Y
        } else {
            $global:currentRowIndex = -1
            $label2.Text = "Current Row Index: None"
        }
    })
    $timer.Start()

    # クリック処理の追加
    $panel.add_MouseClick({
        Write-Host "ウィンドウがクリックされました。"

        $情報パネル.Close()
        $ハイライトフォーム.Close()
        $global:サイドバー.Close()
        $timer.Stop()
        [InputHook]::UnhookAll()  # フックを解除
        $logUpdateTimer.Stop()

        # 現在参照しているCSV行の情報を処理
        if ($global:currentRowIndex -ne -1) {
            $selectedElement = $uiElements[$global:currentRowIndex]

            # 各値を変数に格納
            $windowName = $selectedElement.WindowTitle  # CSVから参照
            $elementName = $selectedElement.Name
            $elementId = $selectedElement.AutomationId
            $elementType = $selectedElement.LocalizedControlType
            $elementClassName = $selectedElement.ClassName
            $elementPattern = $selectedElement.Patterns  # Patternsの取得
            $elementX = [double]$selectedElement.Left
            $elementY = [double]$selectedElement.Top
            # DuplicateCountはログ出力には使用しない

            # Patternsを分割してリスト化
            $patternsList = $elementPattern -split '_'

            if ($patternsList.Count -gt 1) {
                # 複数のパターンが存在する場合、選択リストを表示
                $listForm = New-Object System.Windows.Forms.Form
                $listForm.Text = "パターン選択"
                $listForm.Width = 300
                $listForm.Height = 200

                # ListBoxを作成
                $listBox = New-Object System.Windows.Forms.ListBox
                $listBox.Dock = [System.Windows.Forms.DockStyle]::Fill

                # Patternsをリストに追加
                foreach ($pattern in $patternsList) {
                    # パターンに応じた補助テキストを設定
                    if ($pattern -like "*Invoke*") {
                        $displayPattern = "$pattern (クリック)"
                    } elseif ($pattern -like "*Value*") {
                        $displayPattern = "$pattern (入力)"
                    } elseif ($pattern -like "*Selection*") {
                        $displayPattern = "$pattern (選択)"
                    } else {
                        $displayPattern = "$pattern (その他)"
                    }

                    # 補助テキスト付きでリストに追加
                    $listBox.Items.Add($displayPattern)
                }

                # OKボタンを作成
                $okButton = New-Object System.Windows.Forms.Button
                $okButton.Text = "OK"
                $okButton.Dock = [System.Windows.Forms.DockStyle]::Bottom
                $okButton.add_Click({
                    # 選択されたパターンを取得
                    $selectedPattern = $listBox.SelectedItem -replace "\s*\(.*\)", ""
                    Write-Host "選択されたパターン: $selectedPattern"

                    # 共通関数を呼び出し
                    ProcessSelectedPattern -selectedPattern $selectedPattern -windowName $windowName -elementName $elementName -elementId $elementId -elementType $elementType -elementClassName $elementClassName -elementX $elementX -elementY $elementY

                    # パターン選択フォームを閉じる
                    $listForm.Close()
                })

                $listForm.Controls.Add($listBox)
                $listForm.Controls.Add($okButton)
                $menuHandle = UIGet-メインメニューを最小化
                $listForm.ShowDialog()
                UIGet-メインメニューを復元 -ハンドル $menuHandle
            } else {
                # パターンが1つしかない場合、そのままログ出力
                $selectedPattern = $patternsList[0]

                # 共通関数を呼び出し
                ProcessSelectedPattern -selectedPattern $selectedPattern -windowName $windowName -elementName $elementName -elementId $elementId -elementType $elementType -elementClassName $elementClassName -elementX $elementX -elementY $elementY
            }
        }
    })

    $情報パネル.Show()
    $情報パネル.Activate()

    # ハイライトフォームをモーダル表示
    #$ハイライトフォーム.ShowDialog()
    # 変更後
    $menuHandle = UIGet-メインメニューを最小化
    $result = $ハイライトフォーム.ShowDialog()
    UIGet-メインメニューを復元 -ハンドル $menuHandle

    $ハイライトフォーム.Activate()

    $timer.Stop()
    [InputHook]::UnhookAll()  # フックを解除
    $logUpdateTimer.Stop()

} finally {
    # スクリプトの終了時にフックを解除
    [InputHook]::UnhookAll()
    # フラグをリセット
    [InputHook]::EscPressed = $false
    [InputHook]::F1Pressed = $false
}

return $global:UIResult

}
 
 
 
