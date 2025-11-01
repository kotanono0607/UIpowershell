# 全画面ドラッグ矩形スクリーンショットオーバーレイ Ver 3.4 + JSON管理 + 戻り値追加 Ver.3

function フォルダ作成 {
    [CmdletBinding()]
    param()
    $screenDir = Join-Path -Path $global:folderPath -ChildPath 'screen_shot'
    if (-not (Test-Path $screenDir)) {
        New-Item -ItemType Directory -Path $screenDir | Out-Null
    }
    return $screenDir
}

function JSON読み込み {
    [CmdletBinding()]
    param()
    $dir      = フォルダ作成
    $jsonPath = Join-Path -Path $dir -ChildPath 'metadata.json'
    if (Test-Path $jsonPath) {
        $data = Get-Content $jsonPath -Raw | ConvertFrom-Json
    }
    else {
        $data = @{
            LastDate  = ''
            LastIndex = 0
            Files     = @()
        }
    }
    return @{ Data = $data; Path = $jsonPath }
}

function JSON書き込み {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] $Data,
        [Parameter(Mandatory=$true)] $Path
    )
    $Data | ConvertTo-Json -Depth 5 | Set-Content -Path $Path
}

function 全画面ドラッグ矩形オーバーレイ {
    [CmdletBinding()]
    param()

    Add-Type -TypeDefinition @"
using System;
using System.Windows.Forms;
using System.Drawing;
public class ドラッグ矩形フォーム : Form {
    public Rectangle DragRectangle { get; private set; }
    private Point startPoint;
    private Point currentPoint;
    private bool dragging = false;
    public ドラッグ矩形フォーム() {
        this.FormBorderStyle = FormBorderStyle.None;
        this.WindowState      = FormWindowState.Maximized;
        this.TopMost          = true;
        this.BackColor        = Color.Black;
        this.Opacity          = 0.5;
        this.SetStyle(ControlStyles.OptimizedDoubleBuffer | ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint, true);
        this.UpdateStyles();
    }
    protected override void OnMouseDown(MouseEventArgs e) {
        if (e.Button == MouseButtons.Left) {
            startPoint   = e.Location;
            currentPoint = e.Location;
            dragging     = true;
            this.Invalidate();
        }
        base.OnMouseDown(e);
    }
    protected override void OnMouseMove(MouseEventArgs e) {
        if (dragging) {
            currentPoint = e.Location;
            this.Invalidate();
        }
        base.OnMouseMove(e);
    }
    protected override void OnMouseUp(MouseEventArgs e) {
        if (e.Button == MouseButtons.Left) {
            dragging = false;
            int x = Math.Min(startPoint.X, currentPoint.X);
            int y = Math.Min(startPoint.Y, currentPoint.Y);
            int w = Math.Abs(currentPoint.X - startPoint.X);
            int h = Math.Abs(currentPoint.Y - startPoint.Y);
            DragRectangle = new Rectangle(x, y, w, h);
            this.Close();
        }
        base.OnMouseUp(e);
    }
    protected override void OnPaint(PaintEventArgs e) {
        base.OnPaint(e);
        if (dragging) {
            int x = Math.Min(startPoint.X, currentPoint.X);
            int y = Math.Min(startPoint.Y, currentPoint.Y);
            int w = Math.Abs(currentPoint.X - startPoint.X);
            int h = Math.Abs(currentPoint.Y - startPoint.Y);
            using (var pen = new Pen(Color.Red, 2)) {
                e.Graphics.DrawRectangle(pen, x, y, w, h);
            }
        }
    }
}
"@ -ReferencedAssemblies "System.Windows.Forms","System.Drawing"

    $form = New-Object ドラッグ矩形フォーム
    $form.ShowDialog() | Out-Null

    $rect = $form.DragRectangle
    if ($rect.Width -gt 0 -and $rect.Height -gt 0) {
        $bmp = New-Object System.Drawing.Bitmap $rect.Width, $rect.Height
        $g   = [System.Drawing.Graphics]::FromImage($bmp)
        $g.CopyFromScreen($rect.X, $rect.Y, 0, 0, $rect.Size)
        $g.Dispose()

        $jsonInfo = JSON読み込み
        $data     = $jsonInfo.Data
        $jsonPath = $jsonInfo.Path
        $today    = (Get-Date).ToString('yyyyMMdd')
        if ($data.LastDate -eq $today) {
            $index = $data.LastIndex + 1
        }
        else {
            $index = 1
        }

        $dir      = フォルダ作成
        $fileName = "{0}_{1}.png" -f $today, $index
        $filePath = Join-Path $dir $fileName

        $bmp.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()

        $data.LastDate  = $today
        $data.LastIndex = $index
        $data.Files    += $fileName
        JSON書き込み -Data $data -Path $jsonPath

        # 追加：生成したスクリーンショットのファイル名を戻り値として返す
        return $fileName
    }
    else {
        # 範囲指定がなかった場合は空文字を返す
        return ''
    }
}
