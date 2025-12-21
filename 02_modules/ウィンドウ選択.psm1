# ウィンドウ選択モジュール Ver 1.0
# サムネイル付きのウィンドウ選択UIを提供

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Win32 API 定義
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Drawing;
using System.Collections.Generic;

public class WindowHelper {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);

    [DllImport("user32.dll")]
    public static extern IntPtr GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("dwmapi.dll")]
    public static extern int DwmGetWindowAttribute(IntPtr hwnd, int dwAttribute, out bool pvAttribute, int cbAttribute);

    public const int SW_RESTORE = 9;
    public const int GWL_EXSTYLE = -20;
    public const int WS_EX_TOOLWINDOW = 0x00000080;
    public const int DWMWA_CLOAKED = 14;

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    public static string GetWindowTitle(IntPtr hWnd) {
        int length = GetWindowTextLength(hWnd);
        if (length == 0) return "";
        StringBuilder sb = new StringBuilder(length + 1);
        GetWindowText(hWnd, sb, sb.Capacity);
        return sb.ToString();
    }

    public static bool IsAltTabWindow(IntPtr hWnd) {
        if (!IsWindowVisible(hWnd)) return false;

        // 最小化されているウィンドウは除外
        if (IsIconic(hWnd)) return false;

        // タイトルがないウィンドウは除外
        string title = GetWindowTitle(hWnd);
        if (string.IsNullOrEmpty(title)) return false;

        // ツールウィンドウは除外
        IntPtr exStyle = GetWindowLong(hWnd, GWL_EXSTYLE);
        if (((int)exStyle & WS_EX_TOOLWINDOW) != 0) return false;

        // Windows 10/11 の Cloaked ウィンドウは除外
        bool isCloaked = false;
        DwmGetWindowAttribute(hWnd, DWMWA_CLOAKED, out isCloaked, sizeof(bool));
        if (isCloaked) return false;

        return true;
    }

    public static Bitmap CaptureWindow(IntPtr hWnd, int maxWidth, int maxHeight) {
        RECT rect;
        if (!GetWindowRect(hWnd, out rect)) return null;

        int width = rect.Right - rect.Left;
        int height = rect.Bottom - rect.Top;

        if (width <= 0 || height <= 0) return null;

        // ウィンドウをキャプチャ
        Bitmap bmp = new Bitmap(width, height);
        using (Graphics g = Graphics.FromImage(bmp)) {
            IntPtr hdc = g.GetHdc();
            PrintWindow(hWnd, hdc, 2); // PW_RENDERFULLCONTENT = 2
            g.ReleaseHdc(hdc);
        }

        // サムネイルサイズに縮小
        float scale = Math.Min((float)maxWidth / width, (float)maxHeight / height);
        int thumbWidth = (int)(width * scale);
        int thumbHeight = (int)(height * scale);

        Bitmap thumbnail = new Bitmap(thumbWidth, thumbHeight);
        using (Graphics g = Graphics.FromImage(thumbnail)) {
            g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            g.DrawImage(bmp, 0, 0, thumbWidth, thumbHeight);
        }
        bmp.Dispose();

        return thumbnail;
    }
}
"@ -ReferencedAssemblies "System.Drawing.dll" -ErrorAction SilentlyContinue

function Get-VisibleWindows {
    <#
    .SYNOPSIS
    表示中のウィンドウ一覧を取得する
    #>
    $windows = New-Object System.Collections.ArrayList

    $callback = [WindowHelper+EnumWindowsProc]{
        param([IntPtr]$hWnd, [IntPtr]$lParam)

        if ([WindowHelper]::IsAltTabWindow($hWnd)) {
            $title = [WindowHelper]::GetWindowTitle($hWnd)
            $null = $script:windowList.Add(@{
                Handle = $hWnd
                Title = $title
            })
        }
        return $true
    }

    $script:windowList = $windows
    [WindowHelper]::EnumWindows($callback, [IntPtr]::Zero) | Out-Null

    return $windows
}

function Show-WindowSelector {
    <#
    .SYNOPSIS
    ウィンドウ選択ダイアログを表示する

    .OUTPUTS
    選択されたウィンドウのハンドル。キャンセル時は $null
    #>
    [CmdletBinding()]
    param(
        [int]$ThumbnailWidth = 160,
        [int]$ThumbnailHeight = 120,
        [int]$Columns = 4
    )

    # ウィンドウ一覧を取得
    $windows = Get-VisibleWindows

    if ($windows.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "選択可能なウィンドウがありません。",
            "ウィンドウ選択",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return $null
    }

    # フォーム作成
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "キャプチャするウィンドウを選択"
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $form.ForeColor = [System.Drawing.Color]::White
    $form.KeyPreview = $true

    # 選択結果を格納する変数
    $script:selectedHandle = $null

    # FlowLayoutPanel（グリッド表示用）
    $flowPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowPanel.Dock = "Fill"
    $flowPanel.AutoScroll = $true
    $flowPanel.Padding = New-Object System.Windows.Forms.Padding(10)
    $flowPanel.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)

    # 各ウィンドウのパネルを作成
    foreach ($window in $windows) {
        $panel = New-Object System.Windows.Forms.Panel
        $panel.Width = $ThumbnailWidth + 20
        $panel.Height = $ThumbnailHeight + 40
        $panel.Margin = New-Object System.Windows.Forms.Padding(5)
        $panel.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 65)
        $panel.Cursor = [System.Windows.Forms.Cursors]::Hand
        $panel.Tag = $window.Handle

        # サムネイル画像
        $pictureBox = New-Object System.Windows.Forms.PictureBox
        $pictureBox.Width = $ThumbnailWidth
        $pictureBox.Height = $ThumbnailHeight
        $pictureBox.Location = New-Object System.Drawing.Point(10, 5)
        $pictureBox.SizeMode = "Zoom"
        $pictureBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $pictureBox.Tag = $window.Handle

        # サムネイルを取得
        try {
            $thumbnail = [WindowHelper]::CaptureWindow($window.Handle, $ThumbnailWidth, $ThumbnailHeight)
            if ($thumbnail) {
                $pictureBox.Image = $thumbnail
            }
        } catch {
            # サムネイル取得失敗時は空のまま
        }

        # タイトルラベル
        $label = New-Object System.Windows.Forms.Label
        $label.Text = if ($window.Title.Length -gt 20) { $window.Title.Substring(0, 17) + "..." } else { $window.Title }
        $label.Width = $ThumbnailWidth
        $label.Height = 30
        $label.Location = New-Object System.Drawing.Point(10, $ThumbnailHeight + 5)
        $label.TextAlign = "MiddleCenter"
        $label.ForeColor = [System.Drawing.Color]::White
        $label.BackColor = [System.Drawing.Color]::Transparent
        $label.Tag = $window.Handle

        # ホバー効果
        $hoverEnter = {
            $this.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
        }
        $hoverLeave = {
            $this.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 65)
        }

        $panel.Add_MouseEnter($hoverEnter)
        $panel.Add_MouseLeave($hoverLeave)
        $pictureBox.Add_MouseEnter({ $this.Parent.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204) })
        $pictureBox.Add_MouseLeave({ $this.Parent.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 65) })
        $label.Add_MouseEnter({ $this.Parent.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204) })
        $label.Add_MouseLeave({ $this.Parent.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 65) })

        # クリックイベント
        $clickHandler = {
            param($sender, $e)
            $script:selectedHandle = $sender.Tag
            $form.Close()
        }

        $panel.Add_Click($clickHandler)
        $pictureBox.Add_Click($clickHandler)
        $label.Add_Click($clickHandler)

        $panel.Controls.Add($pictureBox)
        $panel.Controls.Add($label)
        $flowPanel.Controls.Add($panel)
    }

    # ステータスバー
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Dock = "Bottom"
    $statusLabel.Height = 30
    $statusLabel.Text = "  クリックで選択 / Escでキャンセル"
    $statusLabel.TextAlign = "MiddleLeft"
    $statusLabel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $statusLabel.ForeColor = [System.Drawing.Color]::LightGray

    # Escキーでキャンセル
    $form.Add_KeyDown({
        if ($_.KeyCode -eq "Escape") {
            $script:selectedHandle = $null
            $form.Close()
        }
    })

    # フォームサイズを計算
    $cols = [Math]::Min($Columns, $windows.Count)
    $rows = [Math]::Ceiling($windows.Count / $Columns)
    $formWidth = [Math]::Min(($ThumbnailWidth + 30) * $cols + 50, 800)
    $formHeight = [Math]::Min(($ThumbnailHeight + 50) * $rows + 80, 600)
    $form.Width = $formWidth
    $form.Height = $formHeight

    $form.Controls.Add($flowPanel)
    $form.Controls.Add($statusLabel)

    # 表示
    $form.ShowDialog() | Out-Null

    return $script:selectedHandle
}

function Select-WindowAndCapture {
    <#
    .SYNOPSIS
    ウィンドウを選択し、そのウィンドウをフォアグラウンドに持ってくる

    .OUTPUTS
    成功時は $true、キャンセル時は $false
    #>
    [CmdletBinding()]
    param()

    # ウィンドウ選択ダイアログを表示
    $selectedHandle = Show-WindowSelector

    if ($null -eq $selectedHandle) {
        Write-Host "ウィンドウ選択がキャンセルされました。" -ForegroundColor Yellow
        return $false
    }

    # 選択したウィンドウをフォアグラウンドに
    Start-Sleep -Milliseconds 200
    [WindowHelper]::ShowWindow($selectedHandle, [WindowHelper]::SW_RESTORE) | Out-Null
    [WindowHelper]::SetForegroundWindow($selectedHandle) | Out-Null
    Start-Sleep -Milliseconds 300

    return $true
}

# エクスポート
Export-ModuleMember -Function Get-VisibleWindows, Show-WindowSelector, Select-WindowAndCapture
