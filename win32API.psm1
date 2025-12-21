if (-not ([System.Management.Automation.PSTypeName]'winAPIUser32').Type) {
    Add-Type @"
        using System;
        using System.Text;
        using System.Runtime.InteropServices;

        public class winAPIUser32 {
            // Windows API の関数デリゲート定義
            public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

            // API 関数のインポート
            [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

            [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
            public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool IsWindowVisible(IntPtr hWnd);

            [DllImport("user32.dll")]
            public static extern bool SetForegroundWindow(IntPtr hWnd);

            [DllImport("user32.dll")]
            public static extern bool SetCursorPos(int x, int y);

            [DllImport("user32.dll")]
            public static extern void mouse_event(int dwFlags, int dx, int dy, int cButtons, int dwExtraInfo);
            public const int MOUSEEVENTF_LEFTDOWN = 0x02;
            public const int MOUSEEVENTF_LEFTUP = 0x04;
            public const int MOUSEEVENTF_RIGHTDOWN = 0x08;
            public const int MOUSEEVENTF_RIGHTUP = 0x10;
            public const int MOUSEEVENTF_WHEEL = 0x0800;
            public const int WHEEL_DELTA = 120;

            // ウィンドウ矩形取得用
            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

            [StructLayout(LayoutKind.Sequential)]
            public struct RECT {
                public int Left;
                public int Top;
                public int Right;
                public int Bottom;
            }

            // クリックイベントとマウス操作に関連する構造体定義
            [StructLayout(LayoutKind.Sequential)]
            public struct INPUT {
                public int Type;
                public MOUSEKEYBDHARDWAREINPUT Data;
            }

            [StructLayout(LayoutKind.Explicit)]
            public struct MOUSEKEYBDHARDWAREINPUT {
                [FieldOffset(0)]
                public MOUSEINPUT Mouse;
            }

            public struct MOUSEINPUT {
                public int dx;
                public int dy;
                public uint mouseData;
                public uint dwFlags;
                public uint time;
                public IntPtr dwExtraInfo;
            }

            // クリック操作を行うメソッド
            [DllImport("user32.dll", SetLastError = true)]
            public static extern uint SendInput(uint nInputs, [In] INPUT[] pInputs, int cbSize);

            // 指定座標で左クリックを実行
            public static void PerformLeftClick(int x, int y) {
                SetCursorPos(x, y);
                mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
                mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
            }

            // 現在のカーソル位置で左クリックを実行
            public static void LeftClick() {
                mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
                mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
            }

            // SendInputを使用して左クリックを実行
            public static void SendInputLeftClick() {
                INPUT[] inputs = new INPUT[2];
                inputs[0].Type = 0;  // INPUT_MOUSE
                inputs[0].Data.Mouse.dwFlags = MOUSEEVENTF_LEFTDOWN;
                inputs[1].Type = 0;  // INPUT_MOUSE
                inputs[1].Data.Mouse.dwFlags = MOUSEEVENTF_LEFTUP;
                SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT)));
            }

            // 指定座標で右クリックを実行
            public static void PerformRightClick(int x, int y) {
                SetCursorPos(x, y);
                mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0);
                mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
            }

            // 現在のカーソル位置で右クリックを実行
            public static void RightClick() {
                mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0);
                mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
            }

            // 指定座標でダブルクリックを実行
            public static void PerformDoubleClick(int x, int y) {
                SetCursorPos(x, y);
                mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
                mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
                mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
                mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
            }

            // 現在のカーソル位置でダブルクリックを実行
            public static void DoubleClick() {
                mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
                mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
                mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
                mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
            }

            // 指定座標でマウスホイールスクロールを実行
            // scrollAmount: 正の値で上スクロール、負の値で下スクロール（WHEEL_DELTA単位）
            public static void PerformWheelScroll(int x, int y, int scrollAmount) {
                SetCursorPos(x, y);
                mouse_event(MOUSEEVENTF_WHEEL, 0, 0, scrollAmount, 0);
            }

            // 現在のカーソル位置でマウスホイールスクロールを実行
            public static void WheelScroll(int scrollAmount) {
                mouse_event(MOUSEEVENTF_WHEEL, 0, 0, scrollAmount, 0);
            }

            // ウィンドウの表示状態を変更するメソッド
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
            public const int SW_RESTORE = 9;
            public const int SW_MAXIMIZE = 3;
            public const int SW_MINIMIZE = 6;

            // ウィンドウの移動とサイズ変更
            [DllImport("user32.dll")]
            public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

            // ウィンドウを閉じるためのメッセージ
            [DllImport("user32.dll")]
            public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
            public const uint WM_CLOSE = 0x0010;

            public static void ウィンドウを最大化(string タイトル) {
                EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
                    StringBuilder title = new StringBuilder(256);
                    GetWindowText(hWnd, title, title.Capacity);
                    if (title.ToString().Contains(タイトル) && IsWindowVisible(hWnd)) {
                        ShowWindow(hWnd, SW_MAXIMIZE);
                        return false;  // 検索を停止
                    }
                    return true;  // 検索を続行
                }, IntPtr.Zero);
            }

            public static void ウィンドウを最小化(string タイトル) {
                EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
                    StringBuilder title = new StringBuilder(256);
                    GetWindowText(hWnd, title, title.Capacity);
                    if (title.ToString().Contains(タイトル) && IsWindowVisible(hWnd)) {
                        ShowWindow(hWnd, SW_MINIMIZE);
                        return false;  // 検索を停止
                    }
                    return true;  // 検索を続行
                }, IntPtr.Zero);
            }

            public static void ウィンドウを通常化(string タイトル) {
                EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
                    StringBuilder title = new StringBuilder(256);
                    GetWindowText(hWnd, title, title.Capacity);
                    if (title.ToString().Contains(タイトル) && IsWindowVisible(hWnd)) {
                        ShowWindow(hWnd, SW_RESTORE);
                        return false;  // 検索を停止
                    }
                    return true;  // 検索を続行
                }, IntPtr.Zero);
            }
        }
"@
}

Add-Type -AssemblyName "UIAutomationClient"

# System.Windows.Formsアセンブリをロード
Add-Type -AssemblyName System.Windows.Forms


#Import-Module -Name "\\mainsv\gpo$\00_スクリプト\00_汎用関数\01_win32.psm1"

function 氏名から氏を取得 {
    param (
        [string]$氏名
    )
    # 氏名を空白で分割し、左側（氏）を取得
    $氏 = ($氏名 -split ' ')[0]
    return $氏
}

function 文字列からウインドウハンドルを探す  {
    param([string]$検索文字列)
    $見つかったハンドル = $null

    $callback = {
        param([IntPtr]$hWnd, [IntPtr]$lParam)

        $builder = New-Object System.Text.StringBuilder 256
        [winAPIUser32]::GetWindowText($hWnd, $builder, $builder.Capacity)
        $title = $builder.ToString()

        if ($title -like "*$検索文字列*" -and [winAPIUser32]::IsWindowVisible($hWnd)) {
            $script:見つかったハンドル = $hWnd
            return $false  # 検索を停止
        }
        return $true  # 検索を続行
    }

    $result = [winAPIUser32]::EnumWindows([winAPIUser32+EnumWindowsProc]$callback, [IntPtr]::Zero)
    
    if ($script:見つかったハンドル -ne $null) {
        return $script:見つかったハンドル
    }
    return $null
}

function ウインドウハンドルでアクティブにする {
    param(
        [Parameter(Mandatory=$true)]
        [IntPtr]$ウインドウハンドル
    )

    [winAPIUser32]::SetForegroundWindow($ウインドウハンドル) | Out-Null
}

function 指定座標を左クリック {
    param(
        [Parameter(Mandatory=$true)]
        [Int]$X座標,
         [Int]$Y座標
    )
    [winAPIUser32]::PerformLeftClick($X座標, $Y座標) | Out-Null
    #[winAPIUser32]::SendInputLeftClick()
}

function 左クリック {
    指定秒待機　0.1
    [winAPIUser32]::SendInputLeftClick() | Out-Null
    指定秒待機　0.1
}

function 指定座標に移動 {
    param(
        [Parameter(Mandatory=$true)]
        [Int]$X座標,
         [Int]$Y座標
    )
    [winAPIUser32]::SetCursorPos($X座標, $Y座標) | Out-Null
}

function 指定座標を右クリック {
    param(
        [Parameter(Mandatory=$true)]
        [Int]$X座標,
        [Int]$Y座標
    )
    指定秒待機 0.1
    [winAPIUser32]::PerformRightClick($X座標, $Y座標) | Out-Null
    指定秒待機 0.1
}

function 右クリック {
    指定秒待機 0.1
    [winAPIUser32]::RightClick() | Out-Null
    指定秒待機 0.1
}

function 指定座標をダブルクリック {
    param(
        [Parameter(Mandatory=$true)]
        [Int]$X座標,
        [Int]$Y座標
    )
    指定秒待機 0.1
    [winAPIUser32]::PerformDoubleClick($X座標, $Y座標) | Out-Null
    指定秒待機 0.1
}

function ダブルクリック {
    指定秒待機 0.1
    [winAPIUser32]::DoubleClick() | Out-Null
    指定秒待機 0.1
}

# ========== ウィンドウ相対座標操作 (Ver 1.5) ==========

function Get-WindowHandleByTitle {
    <#
    .SYNOPSIS
    ウィンドウタイトルからウィンドウハンドルを取得する
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ウィンドウ名
    )

    $result = $null
    [winAPIUser32]::EnumWindows({
        param([IntPtr]$hWnd, [IntPtr]$lParam)
        $title = New-Object System.Text.StringBuilder 256
        [winAPIUser32]::GetWindowText($hWnd, $title, $title.Capacity) | Out-Null
        if ($title.ToString().Contains($ウィンドウ名) -and [winAPIUser32]::IsWindowVisible($hWnd)) {
            $script:foundHandle = $hWnd
            return $false  # 検索停止
        }
        return $true  # 検索続行
    }, [IntPtr]::Zero) | Out-Null

    return $script:foundHandle
}

function ウィンドウ相対クリック {
    <#
    .SYNOPSIS
    ウィンドウの相対座標でクリックを実行する

    .DESCRIPTION
    指定されたウィンドウを見つけ、そのウィンドウの左上を基準とした相対座標でクリックを実行します。
    ウィンドウの位置が変わっても、相対座標が同じであれば同じ位置をクリックできます。

    .PARAMETER ウィンドウ名
    対象ウィンドウのタイトル（部分一致）

    .PARAMETER 相対X
    ウィンドウ左上からのX座標オフセット

    .PARAMETER 相対Y
    ウィンドウ左上からのY座標オフセット

    .PARAMETER クリック種別
    "左", "右", "ダブル" のいずれか（デフォルト: 左）
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ウィンドウ名,
        [Parameter(Mandatory=$true)]
        [int]$相対X,
        [Parameter(Mandatory=$true)]
        [int]$相対Y,
        [ValidateSet("左", "右", "ダブル")]
        [string]$クリック種別 = "左"
    )

    # ウィンドウハンドルを取得
    $hWnd = Get-WindowHandleByTitle -ウィンドウ名 $ウィンドウ名
    if ($null -eq $hWnd -or $hWnd -eq [IntPtr]::Zero) {
        Write-Host "エラー: ウィンドウ '$ウィンドウ名' が見つかりません" -ForegroundColor Red
        return
    }

    # ウィンドウをフォアグラウンドに
    [winAPIUser32]::SetForegroundWindow($hWnd) | Out-Null
    Start-Sleep -Milliseconds 100

    # ウィンドウ矩形を取得
    $rect = New-Object winAPIUser32+RECT
    [winAPIUser32]::GetWindowRect($hWnd, [ref]$rect) | Out-Null

    # 絶対座標を計算
    $absoluteX = $rect.Left + $相対X
    $absoluteY = $rect.Top + $相対Y

    # クリック実行
    指定秒待機 0.1
    switch ($クリック種別) {
        "左" { [winAPIUser32]::PerformLeftClick($absoluteX, $absoluteY) | Out-Null }
        "右" { [winAPIUser32]::PerformRightClick($absoluteX, $absoluteY) | Out-Null }
        "ダブル" { [winAPIUser32]::PerformDoubleClick($absoluteX, $absoluteY) | Out-Null }
    }
    指定秒待機 0.1

    Write-Host "ウィンドウ '$ウィンドウ名' の相対座標 ($相対X, $相対Y) → 絶対座標 ($absoluteX, $absoluteY) で${クリック種別}クリック実行" -ForegroundColor Green
}

function ウィンドウ相対移動 {
    <#
    .SYNOPSIS
    ウィンドウの相対座標にマウスカーソルを移動する

    .PARAMETER ウィンドウ名
    対象ウィンドウのタイトル（部分一致）

    .PARAMETER 相対X
    ウィンドウ左上からのX座標オフセット

    .PARAMETER 相対Y
    ウィンドウ左上からのY座標オフセット
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ウィンドウ名,
        [Parameter(Mandatory=$true)]
        [int]$相対X,
        [Parameter(Mandatory=$true)]
        [int]$相対Y
    )

    # ウィンドウハンドルを取得
    $hWnd = Get-WindowHandleByTitle -ウィンドウ名 $ウィンドウ名
    if ($null -eq $hWnd -or $hWnd -eq [IntPtr]::Zero) {
        Write-Host "エラー: ウィンドウ '$ウィンドウ名' が見つかりません" -ForegroundColor Red
        return
    }

    # ウィンドウをフォアグラウンドに
    [winAPIUser32]::SetForegroundWindow($hWnd) | Out-Null
    Start-Sleep -Milliseconds 100

    # ウィンドウ矩形を取得
    $rect = New-Object winAPIUser32+RECT
    [winAPIUser32]::GetWindowRect($hWnd, [ref]$rect) | Out-Null

    # 絶対座標を計算
    $absoluteX = $rect.Left + $相対X
    $absoluteY = $rect.Top + $相対Y

    # カーソル移動
    [winAPIUser32]::SetCursorPos($absoluteX, $absoluteY) | Out-Null

    Write-Host "ウィンドウ '$ウィンドウ名' の相対座標 ($相対X, $相対Y) → 絶対座標 ($absoluteX, $absoluteY) に移動" -ForegroundColor Green
}

# ========== ウィンドウ相対座標操作 ここまで ==========

function クリップボードの文字列取得 {
    <#
    .SYNOPSIS
    クリップボードの内容から、指定された文字列の上または下にある行を取得します。
    .DESCRIPTION
    クリップボードのテキストを解析し、指定された文字列の上または下にある指定された番目の行を返します。
    .PARAMETER 方向
    '上' または '下'。検索する方向を指定します。
    .PARAMETER 番号
    取得したい行の位置（何番目か）を指定します。
    .PARAMETER 文字列
    検索する文字列を指定します。
    .EXAMPLE
    クリップボードの文字列取得 -方向 下 -番号 1 -文字列 "特定の文字列"
    指定された文字列の下にある1番目の行を取得します。
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$方向,
        [Parameter(Mandatory=$true)]
        [int]$番号,
        [Parameter(Mandatory=$true)]
        [string]$文字列
    )
    # クリップボードからテキストを取得
    $クリップボードテキスト = Get-Clipboard
    # テキストを行に分割
    $行列 = $クリップボードテキスト -split "`r`n"
    # 指定された文字列の行インデックスを見つける
    $行インデックス = $行列.IndexOf($文字列)
    if ($行インデックス -eq -1) {
        Write-Output "指定された文字列は見つかりませんでした。"
        return
    }
    # 目的の行を取得
    if ($方向 -eq "上") {
        $目標インデックス = $行インデックス - $番号
    } elseif ($方向 -eq "下") {
        $目標インデックス = $行インデックス + $番号
    } else {
        Write-Output "方向は '上' または '下' を指定してください。"
        return
    }
    if ($目標インデックス -lt 0 -or $目標インデックス -ge $行列.Count) {
        Write-Output "指定された範囲はテキストの範囲外です。"
        return
    }
    # 目的の行を返す
    $行列[$目標インデックス]
}

function 画面中央にマウスを移動 {
    # 画面の解像度を取得
    $ScreenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
    $ScreenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height
    # 画面の中央座標を計算
    $X = $ScreenWidth / 2
    $Y = $ScreenHeight / 2
    # マウスカーソルを画面の中央に移動
    [winAPIUser32]::SetCursorPos($X, $Y) | Out-Null
}

function 指定秒待機 {
    param(
        [Parameter(Mandatory=$true)]
        [double]$秒数  # intからdoubleへの変更
    )
    Start-Sleep -Seconds $秒数
}
# 指定したキー操作を実行する関数 - Ver 2.0
function キー操作 {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet(
            "Ctrl+A", "Ctrl+C", "Ctrl+V", "Ctrl+X", "Ctrl+Z", "Ctrl+Y", "Ctrl+S", "Ctrl+F", "Ctrl+N", "Ctrl+O", "Ctrl+P", "Ctrl+W", "Ctrl+T",
            "Alt+F4", "Alt+Tab", "Alt+D",
            "Enter", "Tab", "Shift+Tab", "Esc", "Del", "Backspace", "Space",
            "Home", "End", "PageUp", "PageDown",
            "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight",
            "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"
        )]
        [string]$キーコマンド
    )
    switch ($キーコマンド) {
        # Ctrl系
        "Ctrl+A" { [System.Windows.Forms.SendKeys]::SendWait("^a") }
        "Ctrl+C" { [System.Windows.Forms.SendKeys]::SendWait("^c") }
        "Ctrl+V" { [System.Windows.Forms.SendKeys]::SendWait("^v") }
        "Ctrl+X" { [System.Windows.Forms.SendKeys]::SendWait("^x") }
        "Ctrl+Z" { [System.Windows.Forms.SendKeys]::SendWait("^z") }
        "Ctrl+Y" { [System.Windows.Forms.SendKeys]::SendWait("^y") }
        "Ctrl+S" { [System.Windows.Forms.SendKeys]::SendWait("^s") }
        "Ctrl+F" { [System.Windows.Forms.SendKeys]::SendWait("^f") }
        "Ctrl+N" { [System.Windows.Forms.SendKeys]::SendWait("^n") }
        "Ctrl+O" { [System.Windows.Forms.SendKeys]::SendWait("^o") }
        "Ctrl+P" { [System.Windows.Forms.SendKeys]::SendWait("^p") }
        "Ctrl+W" { [System.Windows.Forms.SendKeys]::SendWait("^w") }
        "Ctrl+T" { [System.Windows.Forms.SendKeys]::SendWait("^t") }
        # Alt系
        "Alt+F4" { [System.Windows.Forms.SendKeys]::SendWait("%{F4}") }
        "Alt+Tab" { [System.Windows.Forms.SendKeys]::SendWait("%{TAB}") }
        "Alt+D" { [System.Windows.Forms.SendKeys]::SendWait("%d") }
        # 基本キー
        "Enter" { [System.Windows.Forms.SendKeys]::SendWait("~") }
        "Tab" { [System.Windows.Forms.SendKeys]::SendWait("{TAB}") }
        "Shift+Tab" { [System.Windows.Forms.SendKeys]::SendWait("+{TAB}") }
        "Esc" { [System.Windows.Forms.SendKeys]::SendWait("{ESC}") }
        "Del" { [System.Windows.Forms.SendKeys]::SendWait("{DEL}") }
        "Backspace" { [System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}") }
        "Space" { [System.Windows.Forms.SendKeys]::SendWait(" ") }
        # ナビゲーション
        "Home" { [System.Windows.Forms.SendKeys]::SendWait("{HOME}") }
        "End" { [System.Windows.Forms.SendKeys]::SendWait("{END}") }
        "PageUp" { [System.Windows.Forms.SendKeys]::SendWait("{PGUP}") }
        "PageDown" { [System.Windows.Forms.SendKeys]::SendWait("{PGDN}") }
        # 矢印キー
        "ArrowUp" { [System.Windows.Forms.SendKeys]::SendWait("{UP}") }
        "ArrowDown" { [System.Windows.Forms.SendKeys]::SendWait("{DOWN}") }
        "ArrowLeft" { [System.Windows.Forms.SendKeys]::SendWait("{LEFT}") }
        "ArrowRight" { [System.Windows.Forms.SendKeys]::SendWait("{RIGHT}") }
        # ファンクションキー
        "F1" { [System.Windows.Forms.SendKeys]::SendWait("{F1}") }
        "F2" { [System.Windows.Forms.SendKeys]::SendWait("{F2}") }
        "F3" { [System.Windows.Forms.SendKeys]::SendWait("{F3}") }
        "F4" { [System.Windows.Forms.SendKeys]::SendWait("{F4}") }
        "F5" { [System.Windows.Forms.SendKeys]::SendWait("{F5}") }
        "F6" { [System.Windows.Forms.SendKeys]::SendWait("{F6}") }
        "F7" { [System.Windows.Forms.SendKeys]::SendWait("{F7}") }
        "F8" { [System.Windows.Forms.SendKeys]::SendWait("{F8}") }
        "F9" { [System.Windows.Forms.SendKeys]::SendWait("{F9}") }
        "F10" { [System.Windows.Forms.SendKeys]::SendWait("{F10}") }
        "F11" { [System.Windows.Forms.SendKeys]::SendWait("{F11}") }
        "F12" { [System.Windows.Forms.SendKeys]::SendWait("{F12}") }
        default { Write-Host "指定されたキーコマンドはサポートされていません。" }
    }

}

function ウィンドウ指定キー操作 {
    <#
    .SYNOPSIS
    指定したウィンドウをアクティブ化してからキー操作を実行する

    .DESCRIPTION
    ウィンドウ名で対象ウィンドウを検索し、フォアグラウンドにしてからキー操作を送信します。
    これにより、確実に目的のウィンドウにキー入力を送信できます。

    .PARAMETER ウィンドウ名
    対象ウィンドウのタイトル（部分一致）

    .PARAMETER キーコマンド
    送信するキーコマンド
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ウィンドウ名,
        [Parameter(Mandatory=$true)]
        [ValidateSet(
            "Ctrl+A", "Ctrl+C", "Ctrl+V", "Ctrl+X", "Ctrl+Z", "Ctrl+Y", "Ctrl+S", "Ctrl+F", "Ctrl+N", "Ctrl+O", "Ctrl+P", "Ctrl+W", "Ctrl+T",
            "Alt+F4", "Alt+Tab", "Alt+D",
            "Enter", "Tab", "Shift+Tab", "Esc", "Del", "Backspace", "Space",
            "Home", "End", "PageUp", "PageDown",
            "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight",
            "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"
        )]
        [string]$キーコマンド
    )

    # ウィンドウハンドルを取得
    $hWnd = Get-WindowHandleByTitle -ウィンドウ名 $ウィンドウ名
    if ($null -eq $hWnd -or $hWnd -eq [IntPtr]::Zero) {
        Write-Host "エラー: ウィンドウ '$ウィンドウ名' が見つかりません" -ForegroundColor Red
        return
    }

    # ウィンドウをフォアグラウンドに
    [winAPIUser32]::SetForegroundWindow($hWnd) | Out-Null
    Start-Sleep -Milliseconds 200

    Write-Host "ウィンドウ '$ウィンドウ名' をアクティブ化して '$キーコマンド' を送信" -ForegroundColor Green

    # 既存のキー操作を呼び出し
    キー操作 -キーコマンド $キーコマンド
}

function キーワード検索 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$検査文字列
    )
指定秒待機　-秒数 1
キー操作　-キーコマンド Ctrl+F
指定秒待機　-秒数 1
文字列をクリップボードに格納 -文字列 $検査文字列
指定秒待機　-秒数 1
キー操作 -キーコマンド Ctrl+V
指定秒待機　-秒数 1
キー操作 -キーコマンド Esc
指定秒待機　-秒数 1 
キー操作 -キーコマンド Enter
指定秒待機　-秒数 1 
}
function 文字列貼付 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$入力文字列
    )

文字列をクリップボードに格納 -文字列 $入力文字列
指定秒待機　-秒数 0.5
キー操作 -キーコマンド Ctrl+V
}

# 指定した文字列を一文字ずつ入力する関数 - Ver 2.0
function 文字列入力 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$入力文字列
    )
    Add-Type -AssemblyName System.Windows.Forms
    $入力文字列.ToCharArray() | ForEach-Object {
        [System.Windows.Forms.SendKeys]::SendWait($_.ToString())
        Start-Sleep -Milliseconds 100 # 100ミリ秒の遅延
    }
}function 特定タイトルウインドウを最大化する {
    param(
        [Parameter(Mandatory=$true)]
        [string]$タイトル
    )
    [winAPIUser32]::ウィンドウを最大化($タイトル) | Out-Null
}function 特定タイトルウインドウを最小化する {
    param(
        [Parameter(Mandatory=$true)]
        [string]$タイトル
    )
    [winAPIUser32]::ウィンドウを最小化($タイトル) | Out-Null
}


function 特定タイトルウインドウを通常化する {
    param(
        [Parameter(Mandatory=$true)]
        [string]$タイトル
    )
    [winAPIUser32]::ウィンドウを通常化($タイトル) | Out-Null
}

function ウインドウを閉じる {
    param(
        [Parameter(Mandatory=$true)]
        [IntPtr]$ウインドウハンドル
    )
    [winAPIUser32]::PostMessage($ウインドウハンドル, [winAPIUser32]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
}

function ウインドウ矩形取得 {
    param(
        [Parameter(Mandatory=$true)]
        [IntPtr]$ウインドウハンドル
    )
    $rect = New-Object winAPIUser32+RECT
    [winAPIUser32]::GetWindowRect($ウインドウハンドル, [ref]$rect) | Out-Null
    return @{
        X = $rect.Left
        Y = $rect.Top
        幅 = $rect.Right - $rect.Left
        高さ = $rect.Bottom - $rect.Top
    }
}

function ウインドウ移動 {
    param(
        [Parameter(Mandatory=$true)]
        [IntPtr]$ウインドウハンドル,
        [Parameter(Mandatory=$true)]
        [int]$X,
        [Parameter(Mandatory=$true)]
        [int]$Y
    )
    $rect = New-Object winAPIUser32+RECT
    [winAPIUser32]::GetWindowRect($ウインドウハンドル, [ref]$rect) | Out-Null
    $幅 = $rect.Right - $rect.Left
    $高さ = $rect.Bottom - $rect.Top
    [winAPIUser32]::MoveWindow($ウインドウハンドル, $X, $Y, $幅, $高さ, $true) | Out-Null
}

function ウインドウサイズ変更 {
    param(
        [Parameter(Mandatory=$true)]
        [IntPtr]$ウインドウハンドル,
        [Parameter(Mandatory=$true)]
        [int]$幅,
        [Parameter(Mandatory=$true)]
        [int]$高さ
    )
    $rect = New-Object winAPIUser32+RECT
    [winAPIUser32]::GetWindowRect($ウインドウハンドル, [ref]$rect) | Out-Null
    [winAPIUser32]::MoveWindow($ウインドウハンドル, $rect.Left, $rect.Top, $幅, $高さ, $true) | Out-Null
}

function ウインドウ移動サイズ変更 {
    param(
        [Parameter(Mandatory=$true)]
        [IntPtr]$ウインドウハンドル,
        [Parameter(Mandatory=$true)]
        [int]$X,
        [Parameter(Mandatory=$true)]
        [int]$Y,
        [Parameter(Mandatory=$true)]
        [int]$幅,
        [Parameter(Mandatory=$true)]
        [int]$高さ
    )
    [winAPIUser32]::MoveWindow($ウインドウハンドル, $X, $Y, $幅, $高さ, $true) | Out-Null
}

function シークレットモードでURLを開く {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url
    )
    # Edgeをシークレットモードで開く
    Start-Process "msedge" -ArgumentList "$Url -inprivate"
    # Edgeが開くのを待ち、F11を押して全画面表示にする
    Start-Sleep -Seconds 5
    Add-Type -AssemblyName System.Windows.Forms
    #[System.Windows.Forms.SendKeys]::SendWait("{F11}")
    # 少し待ってから、Ctrl+0を送信して拡大率を100%に設定
    Start-Sleep -Seconds 1
    [System.Windows.Forms.SendKeys]::SendWait("^0")
}# 文字列をクリップボードに格納する関数 - Ver1
function 文字列をクリップボードに格納 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$文字列
    )
    # 文字列をクリップボードに格納
    $文字列 | Set-Clipboard
}

function 取得_呼び出し元情報 {
    $callStack = Get-PSCallStack
    $scriptName = [string]$callStack[1].ScriptName  # 呼び出し元のスクリプト名を取得（文字列）
    $lineNumber = [int]$callStack[1].ScriptLineNumber  # 呼び出し元の行番号を取得（整数）
    
    # フォーマットされた文字列を作成して返す
    return "実行行：$lineNumber　スクリプト名：$scriptName"
}

function 実行エラーログ処理 {
    param (
        [string]$scriptPath,
         [string]$エラー行,
        [System.Windows.Automation.AutomationElement]$ルート要素
    )

    # 現在の日時を取得してフォルダ名を生成（yyyymmddhhmmss）
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    $errorLogFolder = "$scriptPath\$timestamp`_エラーログ"

    # フォルダを作成
    New-Item -Path $errorLogFolder -ItemType Directory | Out-Null

    # スクリーンショットを撮影して保存する処理
    function 撮影スクリーンショット {
        $screenshotPath = "$errorLogFolder\Screenshot_$timestamp.png"
    
        # .NETのSystem.Drawingを使用してスクリーンショットを撮影
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $screenWidth = [System.Windows.Forms.SystemInformation]::VirtualScreen.Width
        $screenHeight = [System.Windows.Forms.SystemInformation]::VirtualScreen.Height
        
        $bitmap = New-Object Drawing.Bitmap $screenWidth, $screenHeight
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        
        # 画面全体をキャプチャ
        $graphics.CopyFromScreen(0, 0, 0, 0, $bitmap.Size)
        
        # スクリーンショットをPNG形式で保存
        $bitmap.Save($screenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
        
        # リソースを解放
        $graphics.Dispose()
        $bitmap.Dispose()
        
        Write-Host "スクリーンショットが保存されました: $screenshotPath"
    }

    # 変数一覧をテキストファイルに保存する処理
    function 保存変数一覧 {
        $variableListPath = "$errorLogFolder\VariableList_$timestamp.txt"

        # 変数一覧を取得し、ファイルに書き込む
        Get-Variable | ForEach-Object {
            "$($_.Name) = $($_.Value)"
        } | Out-File -FilePath $variableListPath -Encoding UTF8

        Write-Host "変数一覧が保存されました: $variableListPath"

        

        Add-Content $variableListPath $エラー行

    }

    # ルート要素とその子要素の情報をログに書き込む処理
    function ルート要素ログ保存 {
        $elementListLogPath = "$errorLogFolder\RootElementAndChildren_$timestamp.txt"

        # ルート要素の情報を追加
        $elementDetails = @()
        $elementDetails += "Root Element:"
        $elementDetails += "Name: $($ルート要素.Current.Name), ID: $($ルート要素.Current.AutomationId), Type: $($ルート要素.Current.LocalizedControlType), ClassName: $($ルート要素.Current.ClassName)"

        # 子要素を取得してログに追加
        $子要素 = $ルート要素.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)

        $elementDetails += "Child Elements:"
        foreach ($element in $子要素) {
            $details = "Name: $($element.Current.Name), ID: $($element.Current.AutomationId), Type: $($element.Current.LocalizedControlType), ClassName: $($element.Current.ClassName)"
            $elementDetails += $details
        }

        # 要素の詳細をファイルに保存
        $elementDetails | Out-File -FilePath $elementListLogPath -Encoding UTF8


        Write-Host "ルート要素と子要素の一覧が保存されました: $elementListLogPath"
    }

    # スクリーンショットを撮影
    撮影スクリーンショット

    # 変数一覧を保存
    保存変数一覧

    # ルート要素とその子要素の情報をログに保存
    ルート要素ログ保存
}

function UI操作2 {
    param (
        [string]$ウインドウ名,
        [string]$名前,
        [string]$ID,
        [string]$タイプ,
        [string]$クラス名前,
        [string]$パターン,
        [string]$目的動作,
        [string]$入力内容,
        [int]$要素何番目 = 0,  # デフォルト値を0に設定
        [int]$要素X = 960,      # デフォルト値はウインドウ中央のX座標
        [int]$要素Y = 540,        # デフォルト値はウインドウ中央のY座標
        [string]$実行行 = 0,
         [int]$最低要素数 = 100 
    )
    
    # 関数の呼び出し
    $ウインドウハンドル = 文字列からウインドウハンドルを探す -検索文字列 $ウインドウ名
    Write-Host ("ウインドウハンドル: " + $ウインドウハンドル)
    ウインドウハンドルでアクティブにする -ウインドウハンドル  $ウインドウハンドル
    # ウインドウハンドルからUIAutomationの要素を取得
    $ルート要素 = [System.Windows.Automation.AutomationElement]::FromHandle($ウインドウハンドル)
        指定秒待機 -秒数 0.1
    if ($null -eq $ルート要素) {
        Write-Host ("ウインドウハンドルが見つかりません: " + $ウインドウハンドル)
        exit
    }



    # 要素数の確認とリトライ
    $試行回数 = 0
    $最大試行回数 = 20
    do {
        $試行回数++
        指定秒待機 -秒数 0.2
        $全要素 = $ルート要素.FindAll([System.Windows.Automation.TreeScope]::Subtree, [System.Windows.Automation.Condition]::TrueCondition)
        指定秒待機 -秒数 0.2
        $要素数 = $全要素.Count
        Write-Host ("試行回数: $試行回数、要素の総数: $要素数")

        if ($要素数 -gt $最低要素数) {
            break
        } elseif ($試行回数 -ge $最大試行回数) {
            Write-Host ("要素の数が50以下のため、処理を終了します。")
            exit
        } else {
            Write-Host ("要素の数が50以下です。1秒待機して再試行します。")

        }
    } while ($試行回数 -lt $最大試行回数)











    # 条件の作成
    $条件リスト = @()
    #if ($名前) {$条件リスト += [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty, $名前)}
    if ($ID) {$条件リスト += [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::AutomationIdProperty, $ID)}
    if ($タイプ) {$条件リスト += [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::LocalizedControlTypeProperty, $タイプ)}
    if ($クラス名前) {$条件リスト += [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ClassNameProperty, $クラス名前)}

    $条件 = switch ($条件リスト.Count) {
        0 { [System.Windows.Automation.Condition]::TrueCondition }
        1 { $条件リスト[0] }
        default { [System.Windows.Automation.AndCondition]::new($条件リスト) }
    }

    $試行回数 = 0
    $一致する要素リスト = @()
    while ($一致する要素リスト.Count -eq 0 -and $試行回数 -lt 10) {
        指定秒待機 -秒数 0.1

        # ここを修正：TreeScope.Descendants を TreeScope.Subtree に変更
        $子要素 = $ルート要素.FindAll([System.Windows.Automation.TreeScope]::Subtree, $条件)
        Write-Host ("検索回数: " + ($試行回数 + 1) + "、検索された要素数: " + $子要素.Count)

        $一致する要素リスト = $子要素 | Where-Object {
            ($名前 -eq "" -or $_.Current.Name -like "*$名前*") -and
            ($ID -eq "" -or $_.Current.AutomationId -like "*$ID*") -and
            ($タイプ -eq "" -or $_.Current.LocalizedControlType -like "*$タイプ*") -and
            ($クラス名前 -eq "" -or $_.Current.ClassName -like "*$クラス名前*") -and
            $_.Current.BoundingRectangle.X -ge 0 -and
            $_.Current.BoundingRectangle.Y -ge 0 -and
            $_.Current.BoundingRectangle.Right -le 1920 -and
            $_.Current.BoundingRectangle.Bottom -le 1080
        }
        $試行回数++
    }

    if ($一致する要素リスト.Count -gt 0) {
        # 要素Xと要素Yに最も近い要素を選択
        $一致する要素 = $一致する要素リスト | Sort-Object {
            ($_.Current.BoundingRectangle.X - $要素X) * ($_.Current.BoundingRectangle.X - $要素X) +
            ($_.Current.BoundingRectangle.Y - $要素Y) * ($_.Current.BoundingRectangle.Y - $要素Y)
        } | Select-Object -First 1

        Write-Host ("一致する要素が見つかりました:")
        Write-Host ("  名前: " + $一致する要素.Current.Name)
        Write-Host ("  ID: " + $一致する要素.Current.AutomationId)
        Write-Host ("  タイプ: " + $一致する要素.Current.LocalizedControlType)
        Write-Host ("  X座標: " + $一致する要素.Current.BoundingRectangle.X)
        Write-Host ("  Y座標: " + $一致する要素.Current.BoundingRectangle.Y)

        # ここでパターンに基づいた操作を実行
        if ($目的動作 -eq "クリック" -and $パターン -eq "InvokePatternIdentifiers.Pattern") {
            $取得パターン = $一致する要素.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
            $取得パターン.Invoke()
            Write-Host ("Invoke操作（クリック）を実行しました。")
        } elseif ($目的動作 -eq "クリック" -and $パターン -ne "InvokePatternIdentifiers.Pattern") {
            $バウンディングボックス = $一致する要素.Current.BoundingRectangle
            $中心X = $バウンディングボックス.X + ($バウンディングボックス.Width / 2)
            $中心Y = $バウンディングボックス.Y + ($バウンディングボックス.Height / 2)
            指定座標を左クリック -X座標 $中心X -Y座標 $中心Y
            Write-Host ("Invoke操作（クリック）を実行しました。")
        } elseif ($目的動作 -eq "入力") {
            $取得パターン = $一致する要素.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
            $取得パターン.SetValue($入力内容)
            Write-Host ("Value操作（入力）を実行しました。入力内容: $入力内容")
        } elseif ($目的動作 -eq "切り替え") {
            $取得パターン = $一致する要素.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern)
            $取得パターン.Toggle()
            Write-Host ("Toggle操作（切り替え）を実行しました。")
        } elseif ($目的動作 -eq "展開") {
            $取得パターン = $一致する要素.GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern)
            $取得パターン.Expand()
            Write-Host ("Expand操作（展開）を実行しました。")
        } elseif ($目的動作 -eq "選択") {
            $取得パターン = $一致する要素.GetCurrentPattern([System.Windows.Automation.SelectionPattern]::Pattern)
            $取得パターン.Select()
            Write-Host ("SelectionItem操作（選択）を実行しました。")
        } elseif ($目的動作 -eq "範囲設定") {
            $取得パターン = $一致する要素.GetCurrentPattern([System.Windows.Automation.RangeValuePattern]::Pattern)
            $取得パターン.SetValue($入力内容)
            Write-Host ("RangeValue操作（範囲設定）を実行しました。値: $入力内容")
        }
    } else {
        Write-Host "一致する要素が見つかりませんでした。"

        # スクリプト名部分を抽出（前回の方法を使用）
        $scriptName = ($実行行 -split "スクリプト名：")[1].Trim()

        # Split-Pathを使ってフォルダパスを抽出
        $folderPath = Split-Path $scriptName

        # フォルダパスを表示
        Write-Host "フォルダパス: $folderPath"

        # エラーログ処理を実行
        実行エラーログ処理 -scriptPath $folderPath -エラー行 $実行行 -ルート要素 $ルート要素

        $表示 = "名前:$名前 ID:$ID タイプ:$タイプ クラス名前:$クラス名前"
        デバッグ表示 -表示文字 $表示 -表示時間秒 1 -追加項目 "待機"
        デバッグ表示 -表示文 $実行行 -表示時間秒 1 -追加項目 "待機"

        Exit
    }
}
function UI操作 {
    param (
        [string]$ウインドウ名,
        [string]$名前,
        [string]$ID,
        [string]$タイプ,
        [string]$クラス名前,
        [string]$パターン,
        [string]$目的動作,
        [string]$入力内容,
        [int]$要素何番目 = 0,  # デフォルト値を0に設定
        [int]$要素X = 960,      # デフォルト値はウインドウ中央のX座標
        [int]$要素Y = 540,        # デフォルト値はウインドウ中央のY座標
        [string]$実行行 = 0 
    )
    
    # 関数の呼び出し
    $ウインドウハンドル = 文字列からウインドウハンドルを探す -検索文字列 $ウインドウ名
    Write-Host ("ウインドウハンドル: " + $ウインドウハンドル)

    # ウインドウハンドルからUIAutomationの要素を取得
   指定秒待機 -秒数 0.5
    $ルート要素 = [System.Windows.Automation.AutomationElement]::FromHandle($ウインドウハンドル)
    指定秒待機 -秒数 0.5
    if ($null -eq $ルート要素) {
        Write-Host ("ウインドウハンドルが見つかりません: " + $ウインドウハンドル)
        exit
    }
    指定秒待機 -秒数 0.1
        # 条件の作成

    $条件リスト = @()
    #if ($名前) {$条件リスト += [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty, $名前)}
    if ($ID) {$条件リスト += [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::AutomationIdProperty, $ID)}
    if ($タイプ) {$条件リスト += [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::LocalizedControlTypeProperty, $タイプ)}
    if ($クラス名前) {$条件リスト += [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ClassNameProperty, $クラス名前)}

    $条件 = switch ($条件リスト.Count) {
        0 { [System.Windows.Automation.Condition]::TrueCondition }
        1 { $条件リスト[0] }
        default { [System.Windows.Automation.AndCondition]::new($条件リスト) }
    }

    # 診断ログ: 検索条件を表示
    Write-Host "=== UI操作 診断情報 ===" -ForegroundColor Cyan
    Write-Host "  ウインドウ名: $ウインドウ名" -ForegroundColor Gray
    Write-Host "  検索条件:" -ForegroundColor Gray
    Write-Host "    名前: '$名前'" -ForegroundColor Gray
    Write-Host "    ID: '$ID'" -ForegroundColor Gray
    Write-Host "    タイプ: '$タイプ'" -ForegroundColor Gray
    Write-Host "    クラス名前: '$クラス名前'" -ForegroundColor Gray

    # ルート要素の情報を表示
    try {
        Write-Host "  ルート要素情報:" -ForegroundColor Gray
        Write-Host "    Name: $($ルート要素.Current.Name)" -ForegroundColor Gray
        Write-Host "    ClassName: $($ルート要素.Current.ClassName)" -ForegroundColor Gray
        Write-Host "    ControlType: $($ルート要素.Current.LocalizedControlType)" -ForegroundColor Gray
    } catch {
        Write-Host "  ルート要素情報取得エラー: $_" -ForegroundColor Yellow
    }
    Write-Host "========================" -ForegroundColor Cyan

    指定秒待機 -秒数 0.1
    $試行回数 = 0
    $一致する要素リスト = @()
    while ($一致する要素リスト.Count -eq 0 -and $試行回数 -lt 30) {
        指定秒待機 -秒数 1

        # まず条件なしで全要素数を確認
        $全子要素 = $ルート要素.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
        $子要素 = $ルート要素.FindAll([System.Windows.Automation.TreeScope]::Descendants, $条件)

        Write-Host ("検索回数: " + ($試行回数 + 1) + "、全要素数: " + $全子要素.Count + "、条件一致: " + $子要素.Count) -ForegroundColor $(if ($子要素.Count -eq 0) { "Yellow" } else { "Green" })

        # 条件一致が0で全要素があれば、最初の数個の要素情報を表示
        if ($子要素.Count -eq 0 -and $全子要素.Count -gt 0 -and $試行回数 -eq 0) {
            Write-Host "  [診断] 条件に一致しない - サンプル要素:" -ForegroundColor Yellow
            $全子要素 | Select-Object -First 5 | ForEach-Object {
                Write-Host "    Name='$($_.Current.Name)' ID='$($_.Current.AutomationId)' Type='$($_.Current.LocalizedControlType)' Class='$($_.Current.ClassName)'" -ForegroundColor Gray
            }
        }

        $一致する要素リスト = $子要素 | Where-Object {
            ($名前 -eq "" -or $_.Current.Name -like "*$名前*") -and
            ($ID -eq "" -or $_.Current.AutomationId -like "*$ID*") -and
            ($タイプ -eq "" -or $_.Current.LocalizedControlType -like "*$タイプ*") -and
            ($クラス名前 -eq "" -or $_.Current.ClassName -like "*$クラス名前*") -and
            ($_).Current.BoundingRectangle.X -ge 0 -and
            ($_).Current.BoundingRectangle.Y -ge 0 -and
            ($_).Current.BoundingRectangle.Right -le 1920 -and
            ($_).Current.BoundingRectangle.Bottom -le 1080
        }

        # フィルタ後に減った場合は理由を表示
        if ($子要素.Count -gt 0 -and $一致する要素リスト.Count -eq 0 -and $試行回数 -eq 0) {
            Write-Host "  [診断] 座標フィルタで除外された可能性" -ForegroundColor Yellow
            $子要素 | Select-Object -First 3 | ForEach-Object {
                $rect = $_.Current.BoundingRectangle
                Write-Host "    座標: X=$($rect.X) Y=$($rect.Y) Right=$($rect.Right) Bottom=$($rect.Bottom)" -ForegroundColor Gray
            }
        }

        $試行回数++
    }

    if ($一致する要素リスト.Count -gt 0) {
        # 要素Xと要素Yに最も近い要素を選択
        $一致する要素 = $一致する要素リスト | Sort-Object {
            ($_.Current.BoundingRectangle.X - $要素X) * ($_.Current.BoundingRectangle.X - $要素X) +
            ($_.Current.BoundingRectangle.Y - $要素Y) * ($_.Current.BoundingRectangle.Y - $要素Y)
        } | Select-Object -First 1

        Write-Host ("一致する要素が見つかりました:")
        Write-Host ("  名前: " + $一致する要素.Current.Name)
        Write-Host ("  ID: " + $一致する要素.Current.AutomationId)
        Write-Host ("  タイプ: " + $一致する要素.Current.LocalizedControlType)
        Write-Host ("  X座標: " + $一致する要素.Current.BoundingRectangle.X)
        Write-Host ("  Y座標: " + $一致する要素.Current.BoundingRectangle.Y)

        # ここでパターンに基づいた操作を実行
        if ($目的動作 -eq "クリック" -and $パターン -eq "InvokePatternIdentifiers.Pattern") {
            $取得パターン = $一致する要素.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
            $取得パターン.Invoke()
            Write-Host ("Invoke操作（クリック）を実行しました。")
        } elseif ($目的動作 -eq "クリック" -and $パターン -ne "InvokePatternIdentifiers.Pattern") {
            $バウンディングボックス = $一致する要素.Current.BoundingRectangle
            $中心X = $バウンディングボックス.X + ($バウンディングボックス.Width / 2)
            $中心Y = $バウンディングボックス.Y + ($バウンディングボックス.Height / 2)
            指定座標を左クリック -X座標 $中心X -Y座標 $中心Y
            Write-Host ("Invoke操作（クリック）を実行しました。")
        } elseif ($目的動作 -eq "入力") {
            $取得パターン = $一致する要素.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
            $取得パターン.SetValue($入力内容)
            Write-Host ("Value操作（入力）を実行しました。入力内容: $入力内容")
        } elseif ($目的動作 -eq "切り替え") {
            $取得パターン = $一致する要素.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern)
            $取得パターン.Toggle()
            Write-Host ("Toggle操作（切り替え）を実行しました。")
        } elseif ($目的動作 -eq "展開") {
            $取得パターン = $一致する要素.GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern)
            $取得パターン.Expand()
            Write-Host ("Expand操作（展開）を実行しました。")
        } elseif ($目的動作 -eq "選択") {
            $取得パターン = $一致する要素.GetCurrentPattern([System.Windows.Automation.SelectionPattern]::Pattern)
            $取得パターン.Select()
            Write-Host ("SelectionItem操作（選択）を実行しました。")
        } elseif ($目的動作 -eq "範囲設定") {
            $取得パターン = $一致する要素.GetCurrentPattern([System.Windows.Automation.RangeValuePattern]::Pattern)
            $取得パターン.SetValue($入力内容)
            Write-Host ("RangeValue操作（範囲設定）を実行しました。値: $入力内容")
        }
    } else {
        Write-Host "一致する要素が見つかりませんでした。"


Write-host "qq"

Write-host $実行行



# スクリプト名部分を抽出（前回の方法を使用）
$scriptName = ($実行行 -split "スクリプト名：")[1].Trim()

# Split-Pathを使ってフォルダパスを抽出
$folderPath = Split-Path $scriptName

# フォルダパスを表示
Write-Host "フォルダパス: $folderPath"




# エラーログ処理を実行
実行エラーログ処理 -scriptPath $folderPath -エラー行 $実行行 -ルート要素 $ルート要素

        $表示 = "名前:$名前 ID:$ID タイプ:$タイプ クラス名前:$クラス名前"
        デバッグ表示 -表示文字 $表示 -表示時間秒 1 -追加項目 "待機"
         デバッグ表示 -表示文 $実行行 -表示時間秒 1 -追加項目 "待機"

        Exit
    }
}
            
function ウインドウ待機 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ウインドウ名の一部
    )
    $見つかったハンドル = $null
    while ($true) {
        $callback = {
            param([IntPtr]$hWnd, [IntPtr]$lParam)
            $builder = New-Object System.Text.StringBuilder 256
            [winAPIUser32]::GetWindowText($hWnd, $builder, $builder.Capacity)
            $title = $builder.ToString()
            $isVisible = [winAPIUser32]::IsWindowVisible($hWnd)
            # デバッグ出力：ウインドウのタイトルと可視状態
            Write-Host "チェック中のウインドウ: タイトル = '$title', 可視状態 = $isVisible"
            if ($title -like "*$ウインドウ名の一部*" -and $isVisible) {
                Write-Host "目的のウインドウが見つかりました: タイトル = '$title'"
                $script:見つかったハンドル = "11"
                   break  #
                return $false  # 検索を停止（コールバックを終了）
            }
            return $true  # 検索を続行
        }
        [winAPIUser32]::EnumWindows([winAPIUser32+EnumWindowsProc]$callback, [IntPtr]::Zero) | Out-Null
        if ($見つかったハンドル -ne $null) {
            Write-Host "関数を終了します。"
            break  # ループから抜け、関数を終了
        } else {
            Write-Host "ウインドウが見つかりません。再試行します..."
            Start-Sleep -Seconds 1
        }
    }
}
# PowerShellにWPFを使うためのアセンブリを読み込む
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function デバッグ表示 {
    param (
        [string]$表示文字 = "デフォルトメッセージ",
        [int]$表示時間秒 = 3,
        [string]$追加項目 = ""
    )

    # Windows Formsでフォームを作成
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "デバッグ表示"
    $form.Size = New-Object System.Drawing.Size(600, 100)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.FormBorderStyle = "None"
    $form.BackColor = [System.Drawing.Color]::White

    # メッセージラベル
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $表示文字
    $label.AutoSize = $false
    $label.Size = New-Object System.Drawing.Size(580, 40)
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.TextAlign = "MiddleCenter"
    $label.Font = New-Object System.Drawing.Font("メイリオ", 12)
    $form.Controls.Add($label)

    if ($追加項目 -eq "待機") {
        # 待機モード：OKボタンを表示
        $label.Size = New-Object System.Drawing.Size(580, 30)
        $label.Location = New-Object System.Drawing.Point(10, 10)

        $waitLabel = New-Object System.Windows.Forms.Label
        $waitLabel.Text = "待機中..."
        $waitLabel.AutoSize = $false
        $waitLabel.Size = New-Object System.Drawing.Size(580, 20)
        $waitLabel.Location = New-Object System.Drawing.Point(10, 40)
        $waitLabel.TextAlign = "MiddleCenter"
        $form.Controls.Add($waitLabel)

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "OK"
        $okButton.Size = New-Object System.Drawing.Size(80, 30)
        $okButton.Location = New-Object System.Drawing.Point(260, 60)
        $okButton.Add_Click({ $form.Close() })
        $form.Controls.Add($okButton)

        $form.Size = New-Object System.Drawing.Size(600, 120)
        $form.ShowDialog() | Out-Null
    } else {
        # 自動クローズモード：Timerで指定秒後に閉じる
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = $表示時間秒 * 1000
        $timer.Add_Tick({
            $timer.Stop()
            $form.Close()
        })
        $timer.Start()

        $form.ShowDialog() | Out-Null
        $timer.Dispose()
    }

    $form.Dispose()
}


function 要素が存在するか {
    param (
        [string]$ウインドウ名,
        [string]$名前,
        [string]$ID,
        [string]$タイプ,
        [string]$クラス名前,
        [string]$メッセージ = "指定された要素"  # デフォルトメッセージ
    )
    # ウインドウハンドルを取得
    $ウインドウハンドル = 文字列からウインドウハンドルを探す -検索文字列 $ウインドウ名
    Write-Host ("ウインドウハンドル: " + $ウインドウハンドル)
    Start-Sleep -Seconds 0.1
    # ウインドウハンドルからUIAutomationの要素を取得
    $ルート要素 = [System.Windows.Automation.AutomationElement]::FromHandle($ウインドウハンドル)
    Start-Sleep -Seconds  0.1
    if ($null -eq $ルート要素) {
        Write-Host ("ウインドウハンドルが見つかりません: " + $ウインドウハンドル)
        return 0
    }
    # 条件の作成
    $条件リスト = @()
    if (![string]::IsNullOrEmpty($名前)) {
        $条件リスト += [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::NameProperty, $名前)
    }
    if (![string]::IsNullOrEmpty($ID)) {
        $条件リスト += [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::AutomationIdProperty, $ID)
    }
    if (![string]::IsNullOrEmpty($タイプ)) {
        $条件リスト += [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::LocalizedControlTypeProperty, $タイプ)
    }
    if (![string]::IsNullOrEmpty($クラス名前)) {
        $条件リスト += [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ClassNameProperty, $クラス名前)
    }
    $条件 = switch ($条件リスト.Count) {
        0 { [System.Windows.Automation.Condition]::TrueCondition }
        1 { $条件リスト[0] }
        default { [System.Windows.Automation.AndCondition]::new($条件リスト) }
    }

    # 要素が見つかるまで5回調査
    $試行回数 = 0
    $一致する要素リスト = @()
    while ($一致する要素リスト.Count -eq 0 -and $試行回数 -lt 5) {
        Start-Sleep -Seconds 0.1
        $一致する要素リスト = $ルート要素.FindAll([System.Windows.Automation.TreeScope]::Descendants, $条件)
        Write-Host ("検索回数: " + ($試行回数 + 1) + "、検索された要素数: " + $一致する要素リスト.Count)
        $試行回数++
    }

    if ($一致する要素リスト.Count -gt 0) {
        Write-Host $一致する要素リスト.Count
        デバッグ表示 -表示文字 "$メッセージ が存在します。"
        return 1
    } else {
        デバッグ表示 -表示文字 "$メッセージ は存在しません。"
        return 0
    }
}

function 共済番号取得 {
　$フルユーザー名 = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
　$分割名 = $フルユーザー名.Split("\\")
　$ユーザー名 = $分割名[-1]
　$最終ユーザー名 = $ユーザー名.Substring($ユーザー名.Length - 4)
　 return $最終ユーザー名
}


# メッセージボックスを表示する関数
function メッセージボックス表示 {
    param (
        [string]$メッセージ,
        [string]$タイトル = "デフォルトタイトル" # 省略可能引数
    )
    # System.Windows.Formsアセンブリをロード
    Add-Type -AssemblyName System.Windows.Forms
    # メッセージボックスを表示
    [System.Windows.Forms.MessageBox]::Show($メッセージ, $タイトル)
}


# Microsoft Edgeを正常に閉じる関数
function Edge閉じる {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class User32 {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
        public const int WM_CLOSE = 0x0010;
    }
"@
    # 'msedge' プロセスを取得
    $edgeProcesses = Get-Process -Name "msedge" -ErrorAction SilentlyContinue
    if ($edgeProcesses) {
        foreach ($process in $edgeProcesses) {
            $hWnd = $process.MainWindowHandle
            if ($hWnd -ne [IntPtr]::Zero) {
                [User32]::PostMessage($hWnd, [User32]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
                Write-Host "Microsoft Edge を正常に閉じるメッセージを送信しました。"
            } else {
                Write-Host "Microsoft Edge のウィンドウハンドルが見つかりません。"
            }
        }
    } else {
        Write-Host "Microsoft Edge は起動していません。"
    }
}


# 複数の変数を編集する関数
function 編集複数変数2 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$変数1名,
        [Parameter(Mandatory = $true)]
        [ref]$変数1,
        [Parameter(Mandatory = $false)]
        [string]$変数2名,
        [Parameter(Mandatory = $false)]
        [ref]$変数2,
        [Parameter(Mandatory = $false)]
        [string]$変数3名,
        [Parameter(Mandatory = $false)]
        [ref]$変数3
    )
    # System.Windows.Formsアセンブリをロード
    Add-Type -AssemblyName System.Windows.Forms
    # フォームの作成
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "変数編集"
    $form.Size = New-Object System.Drawing.Size(400, 300)
    # ラベルとテキストボックスの作成
    $controls = @{}
    $yPos = 10
    # 変数1のラベルとテキストボックス
    $label1 = New-Object System.Windows.Forms.Label
    $label1.Text = "$変数1名 "
    $label1.AutoSize = $true
    $label1.Location = New-Object System.Drawing.Point(10, $yPos)
    $form.Controls.Add($label1)
    $textbox1 = New-Object System.Windows.Forms.TextBox
    $textbox1.Text = $変数1.Value
    $textbox1.Location = New-Object System.Drawing.Point(200, $yPos)
    $textbox1.Width = 150
    $form.Controls.Add($textbox1)
    $controls["変数1"] = $textbox1
    $yPos += 30
    # 変数2のラベルとテキストボックス（省略可能）
    if ($PSBoundParameters.ContainsKey('変数2') -and $変数2名) {
        $label2 = New-Object System.Windows.Forms.Label
        $label2.Text = "$変数2名 "
        $label2.AutoSize = $true
        $label2.Location = New-Object System.Drawing.Point(10, $yPos)
        $form.Controls.Add($label2)
        $textbox2 = New-Object System.Windows.Forms.TextBox
        $textbox2.Text = $変数2.Value
        $textbox2.Location = New-Object System.Drawing.Point(200, $yPos)
        $textbox2.Width = 150
        $form.Controls.Add($textbox2)
        $controls["変数2"] = $textbox2
        $yPos += 30
    }
    # 変数3のラベルとテキストボックス（省略可能）
    if ($PSBoundParameters.ContainsKey('変数3') -and $変数3名) {
        $label3 = New-Object System.Windows.Forms.Label
        $label3.Text = "$変数3名 "
        $label3.AutoSize = $true
        $label3.Location = New-Object System.Drawing.Point(10, $yPos)
        $form.Controls.Add($label3)
        $textbox3 = New-Object System.Windows.Forms.TextBox
        $textbox3.Text = $変数3.Value
        $textbox3.Location = New-Object System.Drawing.Point(200, $yPos)
        $textbox3.Width = 150
        $form.Controls.Add($textbox3)
        $controls["変数3"] = $textbox3
        $yPos += 30
    }
    # OKボタンの作成
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(150, $yPos)
    $okButton.Add_Click({
        $変数1.Value = $controls["変数1"].Text
        if ($PSBoundParameters.ContainsKey('変数2')) {
            $変数2.Value = $controls["変数2"].Text
        }
        if ($PSBoundParameters.ContainsKey('変数3')) {
            $変数3.Value = $controls["変数3"].Text
        }
        $form.Close()
    })
    $form.Controls.Add($okButton)
    # フォームの表示
    $form.ShowDialog() | Out-Null
}


function 編集複数変数 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$変数1名,
        [Parameter(Mandatory = $true)]
        [ref]$変数1,
        [Parameter(Mandatory = $false)]
        [string]$変数2名,
        [Parameter(Mandatory = $false)]
        [ref]$変数2,
        [Parameter(Mandatory = $false)]
        [string]$変数3名,
        [Parameter(Mandatory = $false)]
        [ref]$変数3
    )
    # System.Windows.Formsアセンブリをロード
    Add-Type -AssemblyName System.Windows.Forms
    # フォームの作成
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "変数編集"
    $form.Size = New-Object System.Drawing.Size(400, 300)
    $form.TopMost = $true  # フォアグラウンド固定

    # ラベルとテキストボックスの作成
    $controls = @{}
    $yPos = 10

    # 変数1のラベルとテキストボックス
    $label1 = New-Object System.Windows.Forms.Label
    $label1.Text = "$変数1名 "
    $label1.AutoSize = $true
    $label1.Location = New-Object System.Drawing.Point(10, $yPos)
    $form.Controls.Add($label1)

    # 変数1を確実に文字列に変換してテキストボックスに表示
    $textbox1 = New-Object System.Windows.Forms.TextBox
    $textbox1.Text = 確実に文字列へ変換 $変数1.Value
    $textbox1.Location = New-Object System.Drawing.Point(200, $yPos)
    $textbox1.Width = 150
    $form.Controls.Add($textbox1)
    $controls["変数1"] = $textbox1
    $yPos += 30

    # 変数2のラベルとテキストボックス（省略可能）
    if ($PSBoundParameters.ContainsKey('変数2') -and $変数2名) {
        $label2 = New-Object System.Windows.Forms.Label
        $label2.Text = "$変数2名 "
        $label2.AutoSize = $true
        $label2.Location = New-Object System.Drawing.Point(10, $yPos)
        $form.Controls.Add($label2)

        # 変数2を確実に文字列に変換してテキストボックスに表示
        $textbox2 = New-Object System.Windows.Forms.TextBox
        $textbox2.Text = 確実に文字列へ変換 $変数2.Value
        $textbox2.Location = New-Object System.Drawing.Point(200, $yPos)
        $textbox2.Width = 150
        $form.Controls.Add($textbox2)
        $controls["変数2"] = $textbox2
        $yPos += 30
    }

    # 変数3のラベルとテキストボックス（省略可能）
    if ($PSBoundParameters.ContainsKey('変数3') -and $変数3名) {
        $label3 = New-Object System.Windows.Forms.Label
        $label3.Text = "$変数3名 "
        $label3.AutoSize = $true
        $label3.Location = New-Object System.Drawing.Point(10, $yPos)
        $form.Controls.Add($label3)

        # 変数3を確実に文字列に変換してテキストボックスに表示
        $textbox3 = New-Object System.Windows.Forms.TextBox
        $textbox3.Text = 確実に文字列へ変換 $変数3.Value
        $textbox3.Location = New-Object System.Drawing.Point(200, $yPos)
        $textbox3.Width = 150
        $form.Controls.Add($textbox3)
        $controls["変数3"] = $textbox3
        $yPos += 30
    }

    # OKボタンの作成
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(150, $yPos)
    $okButton.Add_Click({
        $変数1.Value = 確実に文字列へ変換 $controls["変数1"].Text
        if ($PSBoundParameters.ContainsKey('変数2')) {
            $変数2.Value = 確実に文字列へ変換 $controls["変数2"].Text
        }
        if ($PSBoundParameters.ContainsKey('変数3')) {
            $変数3.Value = 確実に文字列へ変換 $controls["変数3"].Text
        }
        $form.Close()
    })
    $form.Controls.Add($okButton)

    # フォームの表示
    $form.ShowDialog() | Out-Null
}

# 変数を文字列に変換する関数
function 確実に文字列へ変換 {
    param (
        [Parameter(Mandatory = $true)]
        $入力変数
    )
    
    # 入力変数がnullの場合は空文字にする
    if ($null -eq $入力変数) {
        return ""
    }
    
    # 変数を文字列に変換
    return [string]$入力変数
}

# 指定アプリ起動関数 修正 Ver1.2
function 指定アプリ起動 {
    param(
        [Parameter(Mandatory=$true)]
        [string]$パス,
        [string[]]$引数
    )

    # パラメーターを格納するハッシュテーブルを作成
    $params = @{ FilePath = $パス }

    # 引数が存在し、かつ空でない場合に ArgumentList を追加
    if ($引数 -and $引数.Count -gt 0) {
        $params["ArgumentList"] = $引数
    }

    # Start-Process をスプラッティングで呼び出す
    Start-Process @params
}

# URLを開く Ver2.2
function URLを開く {
    param(
        [Parameter(Mandatory=$true)]
        [string]$URL,

        [switch]$新規ウインドウ,
        [switch]$シークレットモード,
        [switch]$フルスクリーン
    )

    # オプションが指定されていない場合は既定ブラウザで開く
    if (-not $新規ウインドウ -and -not $シークレットモード -and -not $フルスクリーン) {
        Start-Process $URL
        return
    }

    # Edgeの引数を構築（文字列として構築）
    $引数文字列 = ""

    if ($新規ウインドウ) {
        $引数文字列 += "--new-window "
    }

    if ($シークレットモード) {
        $引数文字列 += "-inprivate "
    }

    $引数文字列 += "`"$URL`""

    # Edge で開く
    Start-Process "msedge" -ArgumentList $引数文字列

    # フルスクリーンはF11キー送信で実現
    if ($フルスクリーン) {
        Start-Sleep -Seconds 2
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.SendKeys]::SendWait("{F11}")
    }
}

# ウインドウ存在確認 Ver1.3
function ウインドウ存在確認 {
    <#
      .SYNOPSIS
          指定タイトルを含むウインドウが存在するかを真偽値で返します。
      .PARAMETER タイトル
          判定したいウインドウタイトル（文字列）。
      .PARAMETER 部分一致
          スイッチ指定で部分一致（既定）。
      .PARAMETER 完全一致
          スイッチ指定で完全一致。
      .OUTPUTS
          [bool]  存在すれば $true、存在しなければ $false
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string]$タイトル,

        [switch]$部分一致,
        [switch]$完全一致
    )

    # 既定は部分一致（どちらも指定なし／両方指定の場合）
    if (-not $部分一致 -and -not $完全一致) { $部分一致 = $true }
    if ($部分一致 -and $完全一致)           { $完全一致 = $false }

    # ===== ここが重要 =====
    # 前回検索結果をクリア
    Set-Variable -Name 見つかったハンドル -Scope Script -Value $null -ErrorAction SilentlyContinue

    # ウインドウハンドルを取得
    $hwnd = 文字列からウインドウハンドルを探す -検索文字列 $タイトル

    # 完全一致モードの場合はタイトル再チェック
    if ($完全一致 -and $hwnd -ne $null) {
        $sb = New-Object System.Text.StringBuilder 256
        [winAPIUser32]::GetWindowText($hwnd, $sb, $sb.Capacity)
        if ($sb.ToString() -ne $タイトル) { return $false }
    }

    return ($hwnd -ne $null)
}

function 開いているウインドウタイトル取得 {
    <#
      .SYNOPSIS
          現在表示されているトップレベルウインドウのタイトル一覧を取得
      .OUTPUTS
          [string[]] タイトル配列（重複なし・昇順）
    #>

    # タイトル格納用の List オブジェクト
    $titleList = [System.Collections.Generic.List[string]]::new()

    # 列挙用コールバック
    $callback = {
        param([IntPtr]$hWnd, [IntPtr]$lParam)

        # 可視ウインドウのみ対象
        if (-not [winAPIUser32]::IsWindowVisible($hWnd)) { return $true }

        # タイトル取得
        $sb = New-Object System.Text.StringBuilder 256
        [winAPIUser32]::GetWindowText($hWnd, $sb, $sb.Capacity)
        $title = $sb.ToString()

        # 空タイトルを除外し List に追加
        if (![string]::IsNullOrWhiteSpace($title)) {
            $null = $titleList.Add($title)   # Add() は戻り値があるので捨てる
        }
        return $true  # 列挙を続行
    }

    # ウインドウを列挙
    [winAPIUser32]::EnumWindows([winAPIUser32+EnumWindowsProc]$callback, [IntPtr]::Zero) | Out-Null

    # タイトルからブラウザ名等を削除して整形
    $cleanedTitles = $titleList.ToArray() | ForEach-Object {
        $t = $_
        # " - " で分割してブラウザ関連パーツを除去
        $parts = $t -split '\s+-\s+'
        $filteredParts = @()
        foreach ($part in $parts) {
            $p = $part.Trim()
            # ブラウザ関連キーワードを含むパーツをスキップ
            if ($p -match 'Microsoft.*Edge|Google.*Chrome|Mozilla.*Firefox|^\[InPrivate\]$|^InPrivate$|^シークレット$|^プライベート$') {
                continue
            }
            if ($p -ne '') {
                $filteredParts += $p
            }
        }
        # 残ったパーツを再結合
        ($filteredParts -join ' - ').Trim()
    }

    # 重複排除＋ソートして返却
    return ($cleanedTitles | Sort-Object -Unique)
}

# 単一変数読み込み関数 Ver7
function 単一変数を設定する {
    <#
        .SYNOPSIS
        呼び出し元 PS1 と同じフォルダーにある variables.json から
        スカラー（単一変数）を取得し、**Global スコープ** に変数を作成します。
    #>

    param(
        [string]$FileName = 'variables.json'   # JSON のファイル名（必要なら変更）
    )

    #--- 呼び出し元 PS1 を特定 -----------------------------------------------
    $callerFrame = Get-PSCallStack |
                   Where-Object { $_.ScriptName -like '*.ps1' } |
                   Select-Object -First 1
    if (-not $callerFrame) {
        throw 'ps1 スクリプトから実行されていません。'
    }

    #--- JSON パスを決定 ------------------------------------------------------
    $jsonPath = Join-Path (Split-Path $callerFrame.ScriptName -Parent) $FileName
    if (-not (Test-Path $jsonPath)) {
        throw "JSON が見つかりません: $jsonPath"
    }

    #--- JSON 読み込み --------------------------------------------------------
    $vars = Get-Content $jsonPath -Raw | ConvertFrom-Json

    #--- スカラー値だけを Global スコープへ配置 -------------------------------
    foreach ($prop in $vars.PSObject.Properties) {
        $val = $prop.Value
        if ($val -is [string] -or $val -is [int] -or $val -is [double] -or $val -is [bool]) {
            Set-Variable -Name $prop.Name -Value $val -Scope Global -Force
        }
    }
}




function 画像マッチングを検出する {
    <#
    .SYNOPSIS
    テンプレート画像をスクリーン上で検索する

    .DESCRIPTION
    Ver 1.2: 検索領域パラメータを追加。指定された場合、その領域内のみを検索対象とします。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$テンプレートパス,
        [double]$しきい値 = 0.7,
        [int]   $画面No    = 0,
        # 検索領域パラメータ（オプション）
        [int]$検索領域Left = -1,
        [int]$検索領域Top = -1,
        [int]$検索領域Width = -1,
        [int]$検索領域Height = -1
    )

    # DPI 無効化
    Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;
public static class DPIHelper {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
"@ -ErrorAction SilentlyContinue
    [DPIHelper]::SetProcessDPIAware() | Out-Null

    # Modules フォルダ内から DLL を検索
    $modulesRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
    $opencvDll    = Get-ChildItem -Path $modulesRoot -Filter 'OpenCvSharp.dll' -Recurse | Select-Object -First 1
    $extDll       = Get-ChildItem -Path $modulesRoot -Filter 'OpenCvSharp.Extensions.dll' -Recurse | Select-Object -First 1
    if (-not $opencvDll -or -not $extDll) {
        Write-Error "OpenCvSharp.dll または OpenCvSharp.Extensions.dll が見つかりません。Modules フォルダを確認してください。"
        return
    }

    # DLL 読み込み
    [Reflection.Assembly]::LoadFrom($opencvDll.FullName) | Out-Null
    [Reflection.Assembly]::LoadFrom($extDll.FullName)    | Out-Null
    $env:Path += ";$($opencvDll.DirectoryName)"

    # C# クラス登録（Ver 1.2: 領域指定対応版）
    if (-not ([type]::GetType("画像マッチングテスト_V3", $false))) {
        Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Windows.Forms;
using OpenCvSharp;
using OpenCvSharp.Extensions;

public static class 画像マッチングテスト_V3 {
    // 画面番号指定版（既存互換）
    public static bool 画面から座標を取得する(int screenNo, string templatePath, double threshold, out int cx, out int cy) {
        cx = cy = -1;
        Screen sc = Screen.AllScreens[screenNo];
        return 領域から座標を取得する(sc.Bounds.X, sc.Bounds.Y, sc.Bounds.Width, sc.Bounds.Height,
                                       templatePath, threshold, out cx, out cy);
    }

    // 領域指定版（新規）
    public static bool 領域から座標を取得する(int left, int top, int width, int height,
                                               string templatePath, double threshold, out int cx, out int cy) {
        cx = cy = -1;

        // Bitmap の生成と破棄
        using (Bitmap bmp = new Bitmap(width, height)) {
            using (Graphics g = Graphics.FromImage(bmp)) {
                g.CopyFromScreen(left, top, 0, 0, bmp.Size);
            }
            // Mat に変換
            Mat src  = BitmapConverter.ToMat(bmp);
            Mat src3 = src.CvtColor(ColorConversionCodes.BGRA2BGR);

            // テンプレート読み込み
            Mat templ = Cv2.ImRead(templatePath);
            int tw = templ.Width;
            int th = templ.Height;
            if (tw > src3.Width || th > src3.Height) {
                templ.Dispose();
                src3.Dispose();
                src.Dispose();
                return false;
            }

            // テンプレートマッチング
            Mat res = src3.MatchTemplate(templ, TemplateMatchModes.CCoeffNormed);
            double minVal, maxVal;
            OpenCvSharp.Point minLoc, maxLoc;
            Cv2.MinMaxLoc(res, out minVal, out maxVal, out minLoc, out maxLoc);

            bool found = (maxVal >= threshold);
            if (found) {
                // 領域の左上を基準に絶対座標を計算
                cx = left + maxLoc.X + tw / 2;
                cy = top + maxLoc.Y + th / 2;
            }

            // クリーンアップ
            res.Dispose();
            templ.Dispose();
            src3.Dispose();
            src.Dispose();
            return found;
        }
    }
}
"@ -ReferencedAssemblies @(
            "System.Windows.Forms.dll",
            "System.Drawing.dll",
            "System.Runtime.dll",
            $opencvDll.FullName,
            $extDll.FullName
        )
    }

    # マッチング実行
    [int]$x = 0; [int]$y = 0

    if ($検索領域Left -ge 0 -and $検索領域Top -ge 0 -and $検索領域Width -gt 0 -and $検索領域Height -gt 0) {
        # 領域指定版
        $found = [画像マッチングテスト_V3]::領域から座標を取得する(
            $検索領域Left, $検索領域Top, $検索領域Width, $検索領域Height,
            $テンプレートパス, $しきい値, [ref]$x, [ref]$y)
    }
    else {
        # 画面番号指定版（既存互換）
        $found = [画像マッチングテスト_V3]::画面から座標を取得する(
            $画面No, $テンプレートパス, $しきい値, [ref]$x, [ref]$y)
    }

    return [PSCustomObject]@{ Found = $found; X = $x; Y = $y }
}

# 画像マッチ移動 Ver1.5 - ウィンドウ限定検索対応
function 画像マッチ移動 {
    <#
    .SYNOPSIS
    テンプレート画像をスクリーン上で検索し、見つかった位置にカーソルを移動する

    .DESCRIPTION
    Ver 1.5: ウィンドウ名パラメータを追加。指定された場合、そのウィンドウ内のみを検索対象とします。

    .PARAMETER ファイル名
    テンプレート画像のファイル名またはパス

    .PARAMETER しきい値
    マッチングのしきい値 (0.0-1.0)。デフォルト: 0.7

    .PARAMETER フォルダパス
    screen_shot フォルダの親パス

    .PARAMETER ウィンドウ名
    検索対象を限定するウィンドウのタイトル（部分一致）。省略時は全画面検索。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ファイル名,
        [double]$しきい値 = 0.7,
        [string]$フォルダパス = "",
        [string]$ウィンドウ名 = ""  # 追加: ウィンドウ限定検索用
    )

    # パス決定
    if ([System.IO.Path]::IsPathRooted($ファイル名)) {
        $テンプレートパス = $ファイル名
    }
    elseif (-not [string]::IsNullOrEmpty($フォルダパス)) {
        $screenDir = Join-Path $フォルダパス 'screen_shot'
        $テンプレートパス = Join-Path $screenDir $ファイル名
    }
    else {
        $callerScriptPath = $MyInvocation.ScriptName
        $callerScriptDir  = Split-Path -Path $callerScriptPath -Parent
        $dirPart = [System.IO.Path]::GetDirectoryName($ファイル名)

        if ([string]::IsNullOrEmpty($dirPart)) {
            $テンプレートパス = 取得-最新テンプレートパス -ファイル名 $ファイル名 -呼び出し元パス $callerScriptPath
        }
        else {
            $テンプレートパス = Join-Path $callerScriptDir $ファイル名
        }
    }

    # 実在チェック
    if (-not (Test-Path -LiteralPath $テンプレートパス)) {
        Write-Host "⚠ テンプレート画像が見つかりません: $テンプレートパス"
        return $false
    }

    # ウィンドウ限定検索モード
    if (-not [string]::IsNullOrEmpty($ウィンドウ名)) {
        $hWnd = Get-WindowHandleByTitle -ウィンドウ名 $ウィンドウ名
        if ($null -eq $hWnd -or $hWnd -eq [IntPtr]::Zero) {
            Write-Host "⚠ ウィンドウ '$ウィンドウ名' が見つかりません。全画面検索に切り替えます。" -ForegroundColor Yellow
        }
        else {
            # ウィンドウをフォアグラウンドに
            [winAPIUser32]::SetForegroundWindow($hWnd) | Out-Null
            Start-Sleep -Milliseconds 200

            # ウィンドウ矩形を取得
            $rect = New-Object winAPIUser32+RECT
            [winAPIUser32]::GetWindowRect($hWnd, [ref]$rect) | Out-Null

            $windowLeft = $rect.Left
            $windowTop = $rect.Top
            $windowWidth = $rect.Right - $rect.Left
            $windowHeight = $rect.Bottom - $rect.Top

            Write-Host "🔍 ウィンドウ '$ウィンドウ名' 内を検索中... (位置: $windowLeft,$windowTop サイズ: ${windowWidth}x${windowHeight})"

            # ウィンドウ領域のみをキャプチャしてマッチング
            $res = 画像マッチングを検出する -テンプレートパス $テンプレートパス -しきい値 $しきい値 `
                   -検索領域Left $windowLeft -検索領域Top $windowTop `
                   -検索領域Width $windowWidth -検索領域Height $windowHeight

            if ($res.Found) {
                Write-Host "✅ ウィンドウ内で発見！座標 = ($($res.X), $($res.Y))"
                指定座標に移動 -X座標 $res.X -Y座標 $res.Y
                return $true
            }
            else {
                Write-Host "❌ ウィンドウ '$ウィンドウ名' 内では見つかりませんでした。"
                return $false
            }
        }
    }

    # 全スクリーン走査（既存動作）
    foreach ($i in 0..([System.Windows.Forms.Screen]::AllScreens.Count - 1)) {
        $res = 画像マッチングを検出する -テンプレートパス $テンプレートパス -しきい値 $しきい値 -画面No $i
        if ($res.Found) {
            Write-Host "✅ モニタ$i で発見！座標 = ($($res.X), $($res.Y))"
            指定座標に移動 -X座標 $res.X -Y座標 $res.Y
            return $true
        }
    }

    Write-Host "❌ 全モニタで見つかりませんでした。"
    return $false
}



# 取得-最新テンプレートパス.ps1 - Ver 1.2 修正版
function 取得-最新テンプレートパス {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ファイル名,
        [Parameter(Mandatory=$false)]
        [string]$呼び出し元パス
    )

    # ======================================================
    # 呼び出し元スクリプトのパスを解決
    # ======================================================
    $callerScriptPath = $呼び出し元パス

    # パラメータ未指定なら実行中のps1を参照
    if ([string]::IsNullOrEmpty($callerScriptPath)) {
        if ($PSCommandPath) {
            $callerScriptPath = $PSCommandPath
        } else {
            throw "呼び出し元スクリプトパスが取得できません。ps1ファイルから実行してください。"
        }
    }

    # ======================================================
    # 親フォルダからメイン設定(JSON)を探索
    # ======================================================
    $callerDir = Split-Path -Path $callerScriptPath -Parent
    $parentDir = Split-Path -Path $callerDir -Parent

    $mainJsonPath = Join-Path -Path $parentDir  -ChildPath 'メイン.json'
    if (-not (Test-Path $mainJsonPath)) {
        throw "メイン JSON が見つかりません: $mainJsonPath"
    }

    # ======================================================
    # メインJSON読み込み & フォルダパス取得（修正版）
    # ======================================================
    $mainJson = Get-Content -Path $mainJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json

    # コメント: 直接値取得して Null/空 判定（PS5.1で安定）
    $folderPath = $mainJson.'フォルダパス'
    if ([string]::IsNullOrWhiteSpace($folderPath)) {
        throw "メイン JSON の 'フォルダパス' が空、または未定義です: $mainJsonPath"
    }

    # ======================================================
    # テンプレ画像置き場(screen_shot)確認
    # ======================================================
    $screenDir = Join-Path $folderPath 'screen_shot'
    if (-not (Test-Path $screenDir)) {
        throw "スクリーンショットフォルダが見つかりません: $screenDir"
    }

    # ======================================================
    # ファイル名指定あり → それを返す
    # ======================================================
    if ($ファイル名) {
        $指定パス = Join-Path $screenDir $ファイル名
        if (-not (Test-Path $指定パス)) {
            throw "指定されたテンプレートファイルが存在しません: $指定パス"
        }
        return $指定パス
    }

    # ======================================================
    # ファイル名未指定 → metadata.json の最新版
    # ======================================================
    $metaPath = Join-Path $screenDir 'metadata.json'
    if (-not (Test-Path $metaPath)) {
        throw "metadata.json が見つかりません: $metaPath"
    }

    $metaData = Get-Content -Path $metaPath -Raw | ConvertFrom-Json
    if (-not $metaData.Files -or $metaData.Files.Count -eq 0) {
        throw "管理対象のファイルが存在しません。"
    }

    $latestFile = $metaData.Files[-1]
    return Join-Path $screenDir $latestFile
}


# 変数を文字列に変換する関数
function 確実に文字列へ変換 {
    param (
        [Parameter(Mandatory = $true)]
        $入力変数
    )
    
    # 入力変数がnullの場合は空文字にする
    if ($null -eq $入力変数) {
        return ""
    }
    
    # 変数を文字列に変換
    return [string]$入力変数
}


function 倍率補正 {
    param(
        [Parameter(Mandatory=$true)][int]$論理X,
        [Parameter(Mandatory=$true)][int]$論理Y
    )

    # --- ヘルパーEXEを準備 ---
    $base = Join-Path $env:TEMP 'DpiHelper_ISE'
    $exe  = Join-Path $base 'GetDpiHelper.exe'
    if (-not (Test-Path $exe)) {
        New-Item -ItemType Directory -Force -Path $base | Out-Null

        # C#コード
        @'
using System;
using System.Runtime.InteropServices;
static class Native {
    [DllImport("user32.dll")] public static extern IntPtr MonitorFromPoint(POINT pt, uint flags);
    [DllImport("Shcore.dll")] public static extern int GetDpiForMonitor(IntPtr hmon, int type, out uint x, out uint y);
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X; public int Y; }
}
class Program {
    static void Main() {
        var pt = new Native.POINT { X = 0, Y = 0 };
        var h = Native.MonitorFromPoint(pt, 2);
        uint dx = 96, dy = 96;
        try { Native.GetDpiForMonitor(h, 0, out dx, out dy); } catch {}
        Console.WriteLine("{0},{1}", dx, dy);
    }
}
'@ | Set-Content -Path (Join-Path $base 'GetDpiHelper.cs') -Encoding UTF8

        # マニフェスト（PerMonitorV2）
        @'
<?xml version="1.0" encoding="utf-8"?>
<assembly manifestVersion="1.0" xmlns="urn:schemas-microsoft-com:asm.v1">
  <application xmlns="urn:schemas-microsoft-com:asm.v3">
    <windowsSettings>
      <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true/pmv2</dpiAware>
    </windowsSettings>
  </application>
  <asmv3:application xmlns:asmv3="urn:schemas-microsoft-com:asm.v3">
    <asmv3:windowsSettings>
      <ms_windowsSettings:dpiAwareness xmlns:ms_windowsSettings="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</ms_windowsSettings:dpiAwareness>
    </asmv3:windowsSettings>
  </asmv3:application>
</assembly>
'@ | Set-Content -Path (Join-Path $base 'app.manifest') -Encoding UTF8

        # コンパイル
        $csc = @(
            "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
            "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not $csc) { throw "csc.exe が見つかりません" }
        & $csc /nologo /optimize+ /target:exe /out:$exe /win32manifest:(Join-Path $base 'app.manifest') (Join-Path $base 'GetDpiHelper.cs') | Out-Null
        if (-not (Test-Path $exe)) { throw "ヘルパーEXE生成失敗" }
    }

    # --- 外部ヘルパーでDPI取得 ---
    $out = & $exe 2>$null
    if (-not $out) { $out = "96,96" }
    $p = $out -split ','
    $scaleX = [double]$p[0] / 96
    $scaleY = [double]$p[1] / 96

    # --- 論理座標を物理座標に変換して配列で返す ---
    return ([int]($論理X * $scaleX)), ([int]($論理Y * $scaleY))
}

# ページスクロール関数
function ページスクロール {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ウインドウ名,

        [Parameter(Mandatory=$false)]
        [ValidateSet("上", "下")]
        [string]$方向 = "下",

        [Parameter(Mandatory=$false)]
        [int]$スクロール量 = 10  # ホイール回転数（1回転 = 120）
    )

    # ウインドウハンドルを取得
    $ウインドウハンドル = 文字列からウインドウハンドルを探す -検索文字列 $ウインドウ名
    if ($null -eq $ウインドウハンドル -or $ウインドウハンドル -eq [IntPtr]::Zero) {
        Write-Host "ウインドウが見つかりません: $ウインドウ名" -ForegroundColor Red
        return
    }

    # ウインドウをアクティブにする
    ウインドウハンドルでアクティブにする -ウインドウハンドル $ウインドウハンドル
    指定秒待機 -秒数 0.2

    # ウインドウの中央座標を取得
    $rect = New-Object winAPIUser32+RECT
    [winAPIUser32]::GetWindowRect($ウインドウハンドル, [ref]$rect) | Out-Null
    $centerX = [int](($rect.Left + $rect.Right) / 2)
    $centerY = [int](($rect.Top + $rect.Bottom) / 2)

    # スクロール方向に応じてスクロール量を設定
    $scrollAmount = $スクロール量 * [winAPIUser32]::WHEEL_DELTA
    if ($方向 -eq "下") {
        $scrollAmount = -$scrollAmount  # 下スクロールは負の値
    }

    Write-Host "ページスクロール: ウインドウ=$ウインドウ名, 方向=$方向, 量=$スクロール量" -ForegroundColor Cyan

    # マウスホイールスクロールを実行
    [winAPIUser32]::PerformWheelScroll($centerX, $centerY, $scrollAmount)
}

# ページ末尾へスクロール関数
function ページ末尾へスクロール {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ウインドウ名,

        [Parameter(Mandatory=$false)]
        [int]$繰り返し回数 = 20  # スクロール回数
    )

    Write-Host "ページ末尾へスクロール開始: $ウインドウ名" -ForegroundColor Cyan

    for ($i = 0; $i -lt $繰り返し回数; $i++) {
        ページスクロール -ウインドウ名 $ウインドウ名 -方向 "下" -スクロール量 5
        指定秒待機 -秒数 0.1
    }

    Write-Host "ページ末尾へスクロール完了" -ForegroundColor Green
}

# ページ先頭へスクロール関数
function ページ先頭へスクロール {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ウインドウ名,

        [Parameter(Mandatory=$false)]
        [int]$繰り返し回数 = 20  # スクロール回数
    )

    Write-Host "ページ先頭へスクロール開始: $ウインドウ名" -ForegroundColor Cyan

    for ($i = 0; $i -lt $繰り返し回数; $i++) {
        ページスクロール -ウインドウ名 $ウインドウ名 -方向 "上" -スクロール量 5
        指定秒待機 -秒数 0.1
    }

    Write-Host "ページ先頭へスクロール完了" -ForegroundColor Green
}

# ========================================
# ブラウザ JavaScript 操作関数
# ========================================

# テキスト要素をJSでクリック
function JSテキストクリック {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ウインドウ名,

        [Parameter(Mandatory=$true)]
        [string]$検索テキスト,

        [Parameter(Mandatory=$false)]
        [ValidateSet("部分一致", "完全一致")]
        [string]$一致方法 = "部分一致"
    )

    Add-Type -AssemblyName System.Windows.Forms

    Write-Host "JSテキストクリック開始: '$検索テキスト' ($一致方法)" -ForegroundColor Cyan

    # ウインドウをアクティブ化
    $hwnd = 文字列からウインドウハンドルを探す -検索文字列 $ウインドウ名
    if ($hwnd -ne [IntPtr]::Zero) {
        ウインドウハンドルでアクティブにする -ウインドウハンドル $hwnd
    }
    指定秒待機 -秒数 0.3

    # JavaScript コード生成
    if ($一致方法 -eq "完全一致") {
        $xpath = "//*[text()='$検索テキスト']"
    } else {
        $xpath = "//*[contains(text(),'$検索テキスト')]"
    }

    $jsCode = @"
(function(){
    var el = document.evaluate("$xpath", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
    if(el){ el.scrollIntoView({block:'center'}); el.click(); console.log('Clicked:', el); return 'OK'; }
    else { console.log('Not found: $検索テキスト'); return 'NotFound'; }
})();
"@

    # DevTools を開く (F12) ※Ctrl+Shift+JはNotion等で誤動作するため
    キー操作 -キーコマンド "F12"
    指定秒待機 -秒数 1.0

    # コンソールドロワーを開く (Esc)
    キー操作 -キーコマンド "Esc"
    指定秒待機 -秒数 0.5

    # JSコードをクリップボード経由で貼り付け
    文字列をクリップボードに格納 -文字列 $jsCode
    指定秒待機 -秒数 0.2

    # 貼り付け (Ctrl+V)
    キー操作 -キーコマンド "Ctrl+V"
    指定秒待機 -秒数 0.3

    # 実行 (Enter)
    キー操作 -キーコマンド "Enter"
    指定秒待機 -秒数 0.3

    # DevTools を閉じる (F12)
    キー操作 -キーコマンド "F12"
    指定秒待機 -秒数 0.3

    Write-Host "JSテキストクリック完了" -ForegroundColor Green
}

# ========================================
# テキスト要素クリック（UI Automation版）
# ========================================

# 見えているテキストを検索してクリック
function テキスト要素クリック {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ウインドウ名,

        [Parameter(Mandatory=$true)]
        [string]$検索テキスト,

        [Parameter(Mandatory=$false)]
        [ValidateSet("部分一致", "完全一致")]
        [string]$一致方法 = "部分一致"
    )

    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes

    Write-Host "テキスト要素クリック開始: '$検索テキスト' ($一致方法)" -ForegroundColor Cyan

    # ウインドウをアクティブ化
    $hwnd = 文字列からウインドウハンドルを探す -検索文字列 $ウインドウ名
    if ($hwnd -eq [IntPtr]::Zero) {
        Write-Host "ウインドウが見つかりません: $ウインドウ名" -ForegroundColor Red
        return $false
    }
    ウインドウハンドルでアクティブにする -ウインドウハンドル $hwnd
    指定秒待機 -秒数 0.3

    # ルート要素を取得
    $ルート要素 = [System.Windows.Automation.AutomationElement]::FromHandle($hwnd)
    if ($null -eq $ルート要素) {
        Write-Host "UI要素を取得できません" -ForegroundColor Red
        return $false
    }

    # 全要素を検索
    Write-Host "要素を検索中..." -ForegroundColor Yellow
    $全要素 = $ルート要素.FindAll(
        [System.Windows.Automation.TreeScope]::Subtree,
        [System.Windows.Automation.Condition]::TrueCondition
    )
    Write-Host "総要素数: $($全要素.Count)" -ForegroundColor Yellow

    # テキストで絞り込み
    $一致要素 = @()
    foreach ($要素 in $全要素) {
        $name = $要素.Current.Name
        if ([string]::IsNullOrEmpty($name)) { continue }

        $マッチ = $false
        if ($一致方法 -eq "完全一致") {
            $マッチ = ($name -eq $検索テキスト)
        } else {
            $マッチ = ($name -like "*$検索テキスト*")
        }

        if ($マッチ) {
            $rect = $要素.Current.BoundingRectangle
            # 画面内の要素のみ
            if ($rect.X -ge 0 -and $rect.Y -ge 0 -and $rect.Width -gt 0 -and $rect.Height -gt 0) {
                $一致要素 += @{
                    Element = $要素
                    Name = $name
                    X = [int]($rect.X + $rect.Width / 2)
                    Y = [int]($rect.Y + $rect.Height / 2)
                }
                Write-Host "  発見: '$name' at ($($rect.X), $($rect.Y))" -ForegroundColor Green
            }
        }
    }

    if ($一致要素.Count -eq 0) {
        Write-Host "テキスト '$検索テキスト' が見つかりません" -ForegroundColor Red
        return $false
    }

    # 最初に見つかった要素をクリック
    $target = $一致要素[0]
    Write-Host "クリック: '$($target.Name)' at ($($target.X), $($target.Y))" -ForegroundColor Cyan

    指定座標を左クリック -X座標 $target.X -Y座標 $target.Y

    Write-Host "テキスト要素クリック完了" -ForegroundColor Green
    return $true
}

# ============================================================
# 画像処理関連関数
# ============================================================

function 画像待機 {
    <#
    .SYNOPSIS
    画像が画面上に表示されるまで待機する

    .DESCRIPTION
    指定したテンプレート画像が画面上に表示されるまで待機します。
    タイムアウト時間を超えても見つからない場合はエラーを返します。

    .PARAMETER ファイル名
    テンプレート画像のファイル名

    .PARAMETER しきい値
    マッチングのしきい値 (0.0-1.0)。デフォルト: 0.7

    .PARAMETER タイムアウト秒
    最大待機時間（秒）。デフォルト: 30

    .PARAMETER 間隔ミリ秒
    チェック間隔（ミリ秒）。デフォルト: 500

    .PARAMETER フォルダパス
    スクリーンショットフォルダのベースパス

    .PARAMETER ウィンドウ名
    検索対象のウィンドウ名（部分一致）。省略時は全画面検索

    .OUTPUTS
    Boolean - 画像が見つかった場合はTrue、タイムアウト時はFalse
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイル名,

        [double]$しきい値 = 0.7,

        [int]$タイムアウト秒 = 30,

        [int]$間隔ミリ秒 = 500,

        [Parameter(Mandatory=$true)]
        [string]$フォルダパス,

        [string]$ウィンドウ名 = ""
    )

    $screenDir = Join-Path -Path $フォルダパス -ChildPath 'screen_shot'
    $テンプレートパス = Join-Path -Path $screenDir -ChildPath $ファイル名

    if (-not (Test-Path $テンプレートパス)) {
        Write-Host "⚠ テンプレート画像が見つかりません: $テンプレートパス" -ForegroundColor Red
        return $false
    }

    $開始時刻 = Get-Date
    $終了時刻 = $開始時刻.AddSeconds($タイムアウト秒)

    Write-Host "画像待機開始: $ファイル名 (タイムアウト: ${タイムアウト秒}秒)" -ForegroundColor Cyan

    while ((Get-Date) -lt $終了時刻) {
        $経過秒 = [math]::Round(((Get-Date) - $開始時刻).TotalSeconds, 1)

        if ($ウィンドウ名 -ne "") {
            # ウィンドウ限定検索
            $hwnd = [Win32]::FindWindow([IntPtr]::Zero, $ウィンドウ名)
            if ($hwnd -eq [IntPtr]::Zero) {
                $hwnd = ウィンドウハンドルを部分一致で取得 -部分タイトル $ウィンドウ名
            }
            if ($hwnd -ne [IntPtr]::Zero) {
                $rect = New-Object Win32+RECT
                [Win32]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
                $res = 画像マッチングを検出する -テンプレートパス $テンプレートパス -しきい値 $しきい値 `
                    -領域Left $rect.Left -領域Top $rect.Top -領域Right $rect.Right -領域Bottom $rect.Bottom
                if ($res.Found) {
                    Write-Host "✓ 画像を検出しました (${経過秒}秒)" -ForegroundColor Green
                    return $true
                }
            }
        } else {
            # 全画面検索
            $screenCount = [System.Windows.Forms.Screen]::AllScreens.Count
            for ($i = 0; $i -lt $screenCount; $i++) {
                $res = 画像マッチングを検出する -テンプレートパス $テンプレートパス -しきい値 $しきい値 -画面No $i
                if ($res.Found) {
                    Write-Host "✓ 画像を検出しました (${経過秒}秒)" -ForegroundColor Green
                    return $true
                }
            }
        }

        Start-Sleep -Milliseconds $間隔ミリ秒
    }

    Write-Host "✗ タイムアウト: 画像が見つかりませんでした (${タイムアウト秒}秒)" -ForegroundColor Yellow
    return $false
}

function 画像存在確認 {
    <#
    .SYNOPSIS
    画像が画面上に存在するかを確認する

    .DESCRIPTION
    指定したテンプレート画像が現在の画面上に存在するかを確認します。
    待機せず即座に結果を返します。

    .PARAMETER ファイル名
    テンプレート画像のファイル名

    .PARAMETER しきい値
    マッチングのしきい値 (0.0-1.0)。デフォルト: 0.7

    .PARAMETER フォルダパス
    スクリーンショットフォルダのベースパス

    .PARAMETER ウィンドウ名
    検索対象のウィンドウ名（部分一致）。省略時は全画面検索

    .OUTPUTS
    Boolean - 画像が存在する場合はTrue、存在しない場合はFalse
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイル名,

        [double]$しきい値 = 0.7,

        [Parameter(Mandatory=$true)]
        [string]$フォルダパス,

        [string]$ウィンドウ名 = ""
    )

    $screenDir = Join-Path -Path $フォルダパス -ChildPath 'screen_shot'
    $テンプレートパス = Join-Path -Path $screenDir -ChildPath $ファイル名

    if (-not (Test-Path $テンプレートパス)) {
        Write-Host "⚠ テンプレート画像が見つかりません: $テンプレートパス" -ForegroundColor Red
        return $false
    }

    if ($ウィンドウ名 -ne "") {
        # ウィンドウ限定検索
        $hwnd = [Win32]::FindWindow([IntPtr]::Zero, $ウィンドウ名)
        if ($hwnd -eq [IntPtr]::Zero) {
            $hwnd = ウィンドウハンドルを部分一致で取得 -部分タイトル $ウィンドウ名
        }
        if ($hwnd -ne [IntPtr]::Zero) {
            $rect = New-Object Win32+RECT
            [Win32]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
            $res = 画像マッチングを検出する -テンプレートパス $テンプレートパス -しきい値 $しきい値 `
                -領域Left $rect.Left -領域Top $rect.Top -領域Right $rect.Right -領域Bottom $rect.Bottom
            return $res.Found
        }
        return $false
    } else {
        # 全画面検索
        $screenCount = [System.Windows.Forms.Screen]::AllScreens.Count
        for ($i = 0; $i -lt $screenCount; $i++) {
            $res = 画像マッチングを検出する -テンプレートパス $テンプレートパス -しきい値 $しきい値 -画面No $i
            if ($res.Found) {
                return $true
            }
        }
        return $false
    }
}

function 画像クリック {
    <#
    .SYNOPSIS
    画像を検出してクリックする

    .DESCRIPTION
    指定したテンプレート画像を画面上で検索し、見つかった位置をクリックします。

    .PARAMETER ファイル名
    テンプレート画像のファイル名

    .PARAMETER しきい値
    マッチングのしきい値 (0.0-1.0)。デフォルト: 0.7

    .PARAMETER フォルダパス
    スクリーンショットフォルダのベースパス

    .PARAMETER ウィンドウ名
    検索対象のウィンドウ名（部分一致）。省略時は全画面検索

    .PARAMETER ダブルクリック
    ダブルクリックする場合はTrue

    .PARAMETER 右クリック
    右クリックする場合はTrue

    .OUTPUTS
    Boolean - クリック成功時はTrue、画像が見つからない場合はFalse
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ファイル名,

        [double]$しきい値 = 0.7,

        [Parameter(Mandatory=$true)]
        [string]$フォルダパス,

        [string]$ウィンドウ名 = "",

        [switch]$ダブルクリック,

        [switch]$右クリック
    )

    $screenDir = Join-Path -Path $フォルダパス -ChildPath 'screen_shot'
    $テンプレートパス = Join-Path -Path $screenDir -ChildPath $ファイル名

    if (-not (Test-Path $テンプレートパス)) {
        Write-Host "⚠ テンプレート画像が見つかりません: $テンプレートパス" -ForegroundColor Red
        return $false
    }

    $found = $false
    $clickX = 0
    $clickY = 0

    if ($ウィンドウ名 -ne "") {
        # ウィンドウ限定検索
        $hwnd = [Win32]::FindWindow([IntPtr]::Zero, $ウィンドウ名)
        if ($hwnd -eq [IntPtr]::Zero) {
            $hwnd = ウィンドウハンドルを部分一致で取得 -部分タイトル $ウィンドウ名
        }
        if ($hwnd -ne [IntPtr]::Zero) {
            $rect = New-Object Win32+RECT
            [Win32]::GetWindowRect($hwnd, [ref]$rect) | Out-Null
            $res = 画像マッチングを検出する -テンプレートパス $テンプレートパス -しきい値 $しきい値 `
                -領域Left $rect.Left -領域Top $rect.Top -領域Right $rect.Right -領域Bottom $rect.Bottom
            if ($res.Found) {
                $found = $true
                $clickX = $res.X
                $clickY = $res.Y
            }
        }
    } else {
        # 全画面検索
        $screenCount = [System.Windows.Forms.Screen]::AllScreens.Count
        for ($i = 0; $i -lt $screenCount; $i++) {
            $res = 画像マッチングを検出する -テンプレートパス $テンプレートパス -しきい値 $しきい値 -画面No $i
            if ($res.Found) {
                $found = $true
                $clickX = $res.X
                $clickY = $res.Y
                break
            }
        }
    }

    if (-not $found) {
        Write-Host "✗ 画像が見つかりませんでした: $ファイル名" -ForegroundColor Yellow
        return $false
    }

    # カーソル移動
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($clickX, $clickY)
    Start-Sleep -Milliseconds 50

    # クリック実行
    if ($右クリック) {
        指定座標を右クリック -X座標 $clickX -Y座標 $clickY
        Write-Host "✓ 画像位置を右クリック: ($clickX, $clickY)" -ForegroundColor Green
    } elseif ($ダブルクリック) {
        指定座標をダブルクリック -X座標 $clickX -Y座標 $clickY
        Write-Host "✓ 画像位置をダブルクリック: ($clickX, $clickY)" -ForegroundColor Green
    } else {
        指定座標を左クリック -X座標 $clickX -Y座標 $clickY
        Write-Host "✓ 画像位置をクリック: ($clickX, $clickY)" -ForegroundColor Green
    }

    return $true
}

function スクリーンショット保存 {
    <#
    .SYNOPSIS
    画面全体のスクリーンショットを保存する

    .DESCRIPTION
    指定したモニターの画面全体をスクリーンショットとして保存します。

    .PARAMETER 保存パス
    保存先のファイルパス（拡張子でフォーマット判定: .png, .jpg, .bmp）

    .PARAMETER 画面番号
    キャプチャする画面番号（0から開始）。デフォルト: 0（プライマリ）

    .PARAMETER 全画面
    すべてのモニターを1枚の画像としてキャプチャ

    .OUTPUTS
    Boolean - 保存成功時はTrue
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$保存パス,

        [int]$画面番号 = 0,

        [switch]$全画面
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    try {
        if ($全画面) {
            # 全モニターをキャプチャ
            $screens = [System.Windows.Forms.Screen]::AllScreens
            $minX = ($screens | ForEach-Object { $_.Bounds.X } | Measure-Object -Minimum).Minimum
            $minY = ($screens | ForEach-Object { $_.Bounds.Y } | Measure-Object -Minimum).Minimum
            $maxX = ($screens | ForEach-Object { $_.Bounds.X + $_.Bounds.Width } | Measure-Object -Maximum).Maximum
            $maxY = ($screens | ForEach-Object { $_.Bounds.Y + $_.Bounds.Height } | Measure-Object -Maximum).Maximum

            $width = $maxX - $minX
            $height = $maxY - $minY

            $bitmap = New-Object System.Drawing.Bitmap($width, $height)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphics.CopyFromScreen($minX, $minY, 0, 0, (New-Object System.Drawing.Size($width, $height)))
        } else {
            # 指定画面をキャプチャ
            $screens = [System.Windows.Forms.Screen]::AllScreens
            if ($画面番号 -ge $screens.Count) {
                Write-Host "⚠ 画面番号が範囲外です: $画面番号 (最大: $($screens.Count - 1))" -ForegroundColor Red
                return $false
            }
            $screen = $screens[$画面番号]
            $bounds = $screen.Bounds

            $bitmap = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)
        }

        # フォーマット判定
        $ext = [System.IO.Path]::GetExtension($保存パス).ToLower()
        $format = switch ($ext) {
            ".jpg"  { [System.Drawing.Imaging.ImageFormat]::Jpeg }
            ".jpeg" { [System.Drawing.Imaging.ImageFormat]::Jpeg }
            ".bmp"  { [System.Drawing.Imaging.ImageFormat]::Bmp }
            ".gif"  { [System.Drawing.Imaging.ImageFormat]::Gif }
            default { [System.Drawing.Imaging.ImageFormat]::Png }
        }

        # 保存先ディレクトリ作成
        $dir = [System.IO.Path]::GetDirectoryName($保存パス)
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        $bitmap.Save($保存パス, $format)
        $graphics.Dispose()
        $bitmap.Dispose()

        Write-Host "✓ スクリーンショットを保存しました: $保存パス" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ スクリーンショット保存に失敗しました: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function ウィンドウスクリーンショット {
    <#
    .SYNOPSIS
    指定したウィンドウのスクリーンショットを保存する

    .DESCRIPTION
    ウィンドウ名で指定したウィンドウの領域をスクリーンショットとして保存します。

    .PARAMETER ウィンドウ名
    キャプチャ対象のウィンドウ名（部分一致）

    .PARAMETER 保存パス
    保存先のファイルパス

    .OUTPUTS
    Boolean - 保存成功時はTrue
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ウィンドウ名,

        [Parameter(Mandatory=$true)]
        [string]$保存パス
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # ウィンドウハンドル取得
    $hwnd = [Win32]::FindWindow([IntPtr]::Zero, $ウィンドウ名)
    if ($hwnd -eq [IntPtr]::Zero) {
        $hwnd = ウィンドウハンドルを部分一致で取得 -部分タイトル $ウィンドウ名
    }

    if ($hwnd -eq [IntPtr]::Zero) {
        Write-Host "⚠ ウィンドウが見つかりません: $ウィンドウ名" -ForegroundColor Red
        return $false
    }

    try {
        # ウィンドウ領域取得
        $rect = New-Object Win32+RECT
        [Win32]::GetWindowRect($hwnd, [ref]$rect) | Out-Null

        $width = $rect.Right - $rect.Left
        $height = $rect.Bottom - $rect.Top

        if ($width -le 0 -or $height -le 0) {
            Write-Host "⚠ ウィンドウサイズが不正です" -ForegroundColor Red
            return $false
        }

        $bitmap = New-Object System.Drawing.Bitmap($width, $height)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, (New-Object System.Drawing.Size($width, $height)))

        # フォーマット判定
        $ext = [System.IO.Path]::GetExtension($保存パス).ToLower()
        $format = switch ($ext) {
            ".jpg"  { [System.Drawing.Imaging.ImageFormat]::Jpeg }
            ".jpeg" { [System.Drawing.Imaging.ImageFormat]::Jpeg }
            ".bmp"  { [System.Drawing.Imaging.ImageFormat]::Bmp }
            ".gif"  { [System.Drawing.Imaging.ImageFormat]::Gif }
            default { [System.Drawing.Imaging.ImageFormat]::Png }
        }

        # 保存先ディレクトリ作成
        $dir = [System.IO.Path]::GetDirectoryName($保存パス)
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        $bitmap.Save($保存パス, $format)
        $graphics.Dispose()
        $bitmap.Dispose()

        Write-Host "✓ ウィンドウスクリーンショットを保存しました: $保存パス" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ スクリーンショット保存に失敗しました: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# 入力ダイアログ表示 - ユーザーからテキスト入力を受け付けるダイアログ
# ============================================================================
function 入力ダイアログ表示 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$タイトル,

        [Parameter(Mandatory=$true)]
        [string]$プロンプト,

        [string]$デフォルト値 = ""
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $フォーム = New-Object System.Windows.Forms.Form
    $フォーム.Text = $タイトル
    $フォーム.Size = New-Object System.Drawing.Size(400, 180)
    $フォーム.StartPosition = "CenterScreen"
    $フォーム.FormBorderStyle = "FixedDialog"
    $フォーム.MaximizeBox = $false
    $フォーム.Topmost = $true

    $ラベル = New-Object System.Windows.Forms.Label
    $ラベル.Text = $プロンプト
    $ラベル.Location = New-Object System.Drawing.Point(20, 20)
    $ラベル.AutoSize = $true

    $テキストボックス = New-Object System.Windows.Forms.TextBox
    $テキストボックス.Location = New-Object System.Drawing.Point(20, 50)
    $テキストボックス.Size = New-Object System.Drawing.Size(340, 25)
    $テキストボックス.Text = $デフォルト値

    $OKボタン = New-Object System.Windows.Forms.Button
    $OKボタン.Text = "OK"
    $OKボタン.Location = New-Object System.Drawing.Point(180, 100)
    $OKボタン.Size = New-Object System.Drawing.Size(85, 30)
    $OKボタン.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $キャンセルボタン = New-Object System.Windows.Forms.Button
    $キャンセルボタン.Text = "キャンセル"
    $キャンセルボタン.Location = New-Object System.Drawing.Point(275, 100)
    $キャンセルボタン.Size = New-Object System.Drawing.Size(85, 30)
    $キャンセルボタン.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $フォーム.Controls.AddRange(@($ラベル, $テキストボックス, $OKボタン, $キャンセルボタン))
    $フォーム.AcceptButton = $OKボタン
    $フォーム.CancelButton = $キャンセルボタン

    $結果 = $フォーム.ShowDialog()

    if ($結果 -eq [System.Windows.Forms.DialogResult]::OK) {
        return $テキストボックス.Text
    }
    return $null
}

Export-ModuleMember -Function 画像待機, 画像存在確認, 画像クリック, スクリーンショット保存, ウィンドウスクリーンショット, 入力ダイアログ表示
