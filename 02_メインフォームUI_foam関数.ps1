
# �O���[�o���ϐ��̏�����
$global:�{�^���J�E���^ = 1
$global:���F�{�^���O���[�v�J�E���^ = 1
$global:�ΐF�{�^���O���[�v�J�E���^ = 1
$global:�h���b�O���̃{�^�� = $null


function 00_�t�H�[�����쐬���� {
    param(
        [int]$�� = 1400,
        [int]$���� = 900
    )

    # �^�C�g��: �t�H�[�������i�ŏ����΍􍞂݁jVer1.2
    # �ړI:
    # - ������Ԃ�K�� Normal �ɂ���
    # - TopMost �펞ON����߁A�O�ʉ��̓C�x���g�Ő���
    # - Shown/Resize �C�x���g�ōŏ����ɗ������ꍇ�̕��A��ۏ�

    # �t�H�[���̍쐬�Ɗ�{�ݒ�
    $���C���t�H�[�� = New-Object System.Windows.Forms.Form

    # ��ʌn�̊�{�v���p�e�B
    $���C���t�H�[��.Text            = "�h���b�O���h���b�v�Ń{�^���̈ʒu��ύX"  # �^�C�g��
    $���C���t�H�[��.Width           = $��
    $���C���t�H�[��.Height          = $����
    $���C���t�H�[��.StartPosition   = "CenterScreen"                              # ��ʒ���
    $���C���t�H�[��.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
    $���C���t�H�[��.ShowInTaskbar   = $true
    $���C���t�H�[��.MinimizeBox     = $true
    $���C���t�H�[��.MaximizeBox     = $true
    $���C���t�H�[��.Name            = "���C���t�H�[��"                           # Name�v���p�e�B
    $���C���t�H�[��.AllowDrop       = $false                                       # �t�H�[�����̂̃h���b�v����
    $���C���t�H�[��.BackColor       = [System.Drawing.Color]::FromArgb(255,255,255)

    # ���ŏ����΍�: ������Ԃ𖾎��I��Normal��
    $���C���t�H�[��.WindowState     = [System.Windows.Forms.FormWindowState]::Normal

    # ���펞�O�ʂ͂�߂�i���̃t�H�[����OS�ƌ��܂��₷���j
    $���C���t�H�[��.TopMost = $false

    # ��Shown���̕ی�: �ŏ����Ȃ瑦Normal�֖߂��A�O�ʉ�
    $���C���t�H�[��.Add_Shown({
        param($s,$e)
        # �������ŏ����Ȃ������ŋ���
        if ($s.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized) {
            $s.WindowState = [System.Windows.Forms.FormWindowState]::Normal
        }
        # ��u����TopMost�ɂ��đO�ʉ����Ă���߂��iZ�I�[�_�[����p�̏��Z�j
        $s.TopMost = $true
        $s.TopMost = $false
        $s.Activate()
    })

    # ��Resize���̕ی�: �����ŏ����ɗ������瑦���A
    $���C���t�H�[��.Add_Resize({
        param($s,$e)
        switch ($s.WindowState) {
            ([System.Windows.Forms.FormWindowState]::Minimized) {
                # �ŏ����ɗ������u�ԂɈ����߂�
                $s.WindowState = [System.Windows.Forms.FormWindowState]::Normal
                $s.Activate()
            }
            ([System.Windows.Forms.FormWindowState]::Normal) {
                # ���ɏ����Ȃ�
            }
            ([System.Windows.Forms.FormWindowState]::Maximized) {
                # ���ɏ����Ȃ�
            }
        }
    })

    # �t�H�[����Ԃ�
    return $���C���t�H�[��
}

function 00_�t���[����DragDrop�C�x���g��ݒ肷�� {
    param (
        [System.Windows.Forms.Panel]$�t���[��
    )

    $�t���[��.Add_DragDrop({
        param($sender, $e)

        # �h���b�O���̃{�^�����擾
        $�{�^�� = $e.Data.GetData([System.Windows.Forms.Button])

        if ($�{�^�� -ne $null -and $�{�^��.Tag.IsDragging) {

            # �h���b�v��̃t���[�����̍��W�ɕϊ�
            $�h���b�v��ʍ��W = New-Object System.Drawing.Point($e.X, $e.Y)
            $�h���b�v�_ = $sender.PointToClient($�h���b�v��ʍ��W)

            # ���݂̈ʒu�ƐF
            $���݂�Y   = $�{�^��.Location.Y
            $���݂̐F  = $�{�^��.BackColor

            # �{�^���̒��SY����ɔz�u������Y���v�Z
            $���SY   = $�h���b�v�_.Y
            $�z�uY   = $���SY - ($�{�^��.Height / 2) + 10

            # ============================
            # �l�X�g�֎~�`�F�b�N:
            #   - ��������(��)�����[�v(��)�̒��ɓ�����
            #   - ���[�v(��)����������(��)�̒��ɓ�����
            # ============================
            $�֎~�t���O = �h���b�v�֎~�`�F�b�N_�l�X�g�K�� `
                -�t���[�� $sender `
                -�ړ��{�^�� $�{�^�� `
                -�ݒu��]Y $�z�uY

            if ($�֎~�t���O) {
                [System.Windows.Forms.MessageBox]::Show(
                    "���̈ʒu�ɂ͔z�u�ł��܂���B`r`n�l�X�g�͋֎~�ł��B",
                    "�z�u�֎~",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null

                # �h���b�O��Ԃ����Z�b�g���ďI��
                $�{�^��.Tag.IsDragging = $false
                $�{�^��.Tag.StartPoint = [System.Drawing.Point]::Empty
                $global:�h���b�O���̃{�^�� = $null
                return
            }

            # ============================
            # �����̓��F�u���b�N�Փ˃`�F�b�N
            # �i���� 10_�{�^���̈ꗗ�擾 �� bool ��Ԃ��Ă�̂ł���ɍ��킹��j
            # ============================
            $�Փ˂��� = 10_�{�^���̈ꗗ�擾 `
                -�t���[�� $sender `
                -���݂�Y $���݂�Y `
                -�ݒu��]Y $�z�uY `
                -���݂̐F $���݂̐F

            if ($�Փ˂���) {
                # ���F�u���b�N�̗̈���܂���/���荞�ޓ��ŋ���
                # �����ł͉������Ȃ��Ŕ�����
            }
            else {
                # �X�i�b�vX���t���[�������ɂ��낦��
                $�X�i�b�vX = [Math]::Floor(($sender.ClientSize.Width - $�{�^��.Width) / 2)

                # ���ۂɈړ�
                $�{�^��.Location = New-Object System.Drawing.Point($�X�i�b�vX, $�z�uY)

                # �h���b�O��Ԃ̃��Z�b�g
                $�{�^��.Tag.IsDragging = $false
                $�{�^��.Tag.StartPoint = [System.Drawing.Point]::Empty
                $global:�h���b�O���̃{�^�� = $null

                # �S�̂̐���ƃ��C���ĕ`��
                00_�{�^���̏�l�ߍĔz�u�֐� -�t���[�� $sender
                00_���ǋL���� -�t���[���p�l�� $Global:�����p�l��
            }
        }
    })
}


function �h���b�v�֎~�`�F�b�N_�l�X�g�K�� {
    param (
        [System.Windows.Forms.Panel]$�t���[��,      # �h���b�v��p�l��
        [System.Windows.Forms.Button]$�ړ��{�^��,   # ���h���b�O���Ă�{�^��
        [int]$�ݒu��]Y                              # �h���b�v��ɒu���\���Y
    )

    # ���[�e�B���e�B: �w��F+GroupID�̃u���b�N�c�͈͂�Ԃ�(TopY/BottomY)
    # movingBtn ������ newY �𔽉f���Čv�Z����
    function Get-GroupRangeAfterMove {
        param(
            [System.Windows.Forms.Panel]$panel,
            [System.Windows.Forms.Button]$movingBtn,
            [int]$newY,
            [System.Drawing.Color]$targetColor
        )

        if (-not $movingBtn.Tag) { return $null }
        $gid = $movingBtn.Tag.GroupID
        if ($null -eq $gid) { return $null }

        # ���� GroupID ���� �w��F �̃{�^�����W�߂�
        $sameGroupBtns = $panel.Controls |
            Where-Object {
                $_ -is [System.Windows.Forms.Button] -and
                $_.Tag -ne $null -and
                $_.Tag.GroupID -eq $gid -and
                $_.Tag.BackgroundColor -ne $null -and
                $_.Tag.BackgroundColor.ToArgb() -eq $targetColor.ToArgb()
            }

        # "�J�n" "�I��" ��2�{��������ĂȂ��Ɛ������͈͂��o���Ȃ�
        if ($sameGroupBtns.Count -lt 2) {
            return $null
        }

        $yList = @()
        foreach ($btn in $sameGroupBtns) {
            if ($btn -eq $movingBtn) {
                $yList += $newY
            } else {
                $yList += $btn.Location.Y
            }
        }

        $topY    = ($yList | Measure-Object -Minimum).Minimum
        $bottomY = ($yList | Measure-Object -Maximum).Maximum

        return [pscustomobject]@{
            GroupID  = $gid
            TopY     = [int]$topY
            BottomY  = [int]$bottomY
        }
    }

    # ���[�e�B���e�B: �p�l���S�̂���A�w��F���Ƃ� GroupID �P�ʂ͈̔͂����
    function Get-AllGroupRanges {
        param(
            [System.Windows.Forms.Panel]$panel,
            [System.Drawing.Color]$targetColor
        )

        $colorBtns = $panel.Controls |
            Where-Object {
                $_ -is [System.Windows.Forms.Button] -and
                $_.Tag -ne $null -and
                $_.Tag.BackgroundColor -ne $null -and
                $_.Tag.BackgroundColor.ToArgb() -eq $targetColor.ToArgb()
            }

        $grouped = $colorBtns | Group-Object -Property { $_.Tag.GroupID }

        $ranges = @()

        foreach ($g in $grouped) {
            # ���̃O���[�v�̃{�^��(�J�n/�I��)��2�����Ȃ�X�L�b�v
            if ($g.Group.Count -lt 2) { continue }

            $sorted = $g.Group | Sort-Object { $_.Location.Y }
            $topY    = $sorted[0].Location.Y
            $bottomY = $sorted[-1].Location.Y

            $ranges += [pscustomobject]@{
                GroupID = $g.Name
                TopY    = [int]$topY
                BottomY = [int]$bottomY
            }
        }

        return $ranges
    }

    # 2�͈̔�(condRange=�� / loopRange=��)�̑g�ݍ��킹���ᔽ���ǂ���
    # �߂�l: $true = �ᔽ
    function Is-IllegalPair {
        param(
            $condRange,
            $loopRange
        )

        if ($null -eq $condRange -or $null -eq $loopRange) {
            return $false
        }

        $cTop =  $condRange.TopY
        $cBot =  $condRange.BottomY
        $lTop =  $loopRange.TopY
        $lBot =  $loopRange.BottomY

        # �܂��d�Ȃ��Ă邩�ǂ���
        $overlap = ($cBot -gt $lTop) -and ($cTop -lt $lBot)
        if (-not $overlap) {
            # ���S�ɏ㉺�ɗ���Ă� �� OK
            return $false
        }

        # �������򂪃��[�v�̊��S�����Ȃ�OK
        $condInsideLoop = ($cTop -ge $lTop) -and ($cBot -le $lBot)
        if ($condInsideLoop) {
            # OK (���[�v���O���A�������򂪓���) �͍��@
            return $false
        }

        # ����ȊO�̏d�Ȃ�̓_��
        # - ���� (�Б������˂�����ł�)
        # - ���[�v����������̓����Ɋۂ��Ɠ���
        return $true
    }

    # ������ �V�K�ǉ�: �O���[�v���f�`�F�b�N�֐� ������
    # �O���[�v���̃{�^�������E���܂����i�ꕔ�������A�ꕔ���O���j���`�F�b�N
    function Check-GroupFragmentation {
        param(
            [System.Windows.Forms.Panel]$panel,
            [System.Windows.Forms.Button]$movingBtn,
            [int]$newY,
            [System.Drawing.Color]$groupColor,
            [System.Drawing.Color]$boundaryColor
        )

        if (-not $movingBtn.Tag) { return $false }
        $gid = $movingBtn.Tag.GroupID
        if ($null -eq $gid) { return $false }

        # ����GroupID���w��F�̃{�^����S�Ď擾
        $sameGroupBtns = $panel.Controls |
            Where-Object {
                $_ -is [System.Windows.Forms.Button] -and
                $_.Tag -ne $null -and
                $_.Tag.GroupID -eq $gid -and
                $_.Tag.BackgroundColor -ne $null -and
                $_.Tag.BackgroundColor.ToArgb() -eq $groupColor.ToArgb()
            }

        if ($sameGroupBtns.Count -lt 2) {
            return $false
        }

        # ���E�F�̃O���[�v�͈͂�S�Ď擾
        $boundaryRanges = Get-AllGroupRanges -panel $panel -targetColor $boundaryColor

        foreach ($br in $boundaryRanges) {
            $insideCount = 0
            $outsideCount = 0

            # �O���[�v���̊e�{�^�������E�̓������O�����`�F�b�N
            foreach ($btn in $sameGroupBtns) {
                $btnY = if ($btn -eq $movingBtn) { $newY } else { $btn.Location.Y }

                if (($btnY -ge $br.TopY) -and ($btnY -le $br.BottomY)) {
                    $insideCount++
                } else {
                    $outsideCount++
                }
            }

            # �ꕔ�������A�ꕔ���O�� = �O���[�v���f = �֎~
            if ($insideCount -gt 0 -and $outsideCount -gt 0) {
                return $true
            }
        }

        return $false
    }

    # ��������{��
    $���F = $null
    if ($�ړ��{�^��.Tag -and $�ړ��{�^��.Tag.BackgroundColor) {
        $���F = $�ړ��{�^��.Tag.BackgroundColor
    }

    $isGreen  = ($���F -ne $null -and $���F.ToArgb() -eq [System.Drawing.Color]::SpringGreen.ToArgb())
    $isYellow = ($���F -ne $null -and $���F.ToArgb() -eq [System.Drawing.Color]::LemonChiffon.ToArgb())

    # �p�l����̑S��������u���b�N�͈͂ƑS���[�v�u���b�N�͈͂��Ɏ���Ă���
    $allCondRanges = Get-AllGroupRanges -panel $�t���[�� -targetColor ([System.Drawing.Color]::SpringGreen)
    $allLoopRanges = Get-AllGroupRanges -panel $�t���[�� -targetColor ([System.Drawing.Color]::LemonChiffon)

    # �܂��u�P�̃m�[�h�����ɗ�����v�P�[�X�̑����`�F�b�N
    if ($isYellow) {
        foreach ($cr in $allCondRanges) {
            if ($�ݒu��]Y -ge $cr.TopY -and $�ݒu��]Y -le $cr.BottomY) {
                # ���[�v�̔C�Ӄm�[�h����������̕��̒��ɓ����̂͋֎~
                return $true
            }
        }
    }
    elseif ($isGreen) {
        foreach ($lr in $allLoopRanges) {
            if ($�ݒu��]Y -ge $lr.TopY -and $�ݒu��]Y -le $lr.BottomY) {
                # ��������m�[�h�����[�v�̕��Ɏh���̂͋֎~
                # (�����[�v�̓r���ɏ�����������荞�܂���̂��_��)
                return $true
            }
        }
    }

    # ������ �V�K�ǉ�: �O���[�v���f�`�F�b�N ������
    if ($isGreen) {
        # ��������O���[�v�����[�v�̋��E���܂������`�F�b�N
        $isFragmented = Check-GroupFragmentation `
            -panel $�t���[�� `
            -movingBtn $�ړ��{�^�� `
            -newY $�ݒu��]Y `
            -groupColor ([System.Drawing.Color]::SpringGreen) `
            -boundaryColor ([System.Drawing.Color]::LemonChiffon)
        
        if ($isFragmented) {
            return $true
        }
    }

    if ($isYellow) {
        # ���[�v�O���[�v����������̋��E���܂������`�F�b�N
        $isFragmented = Check-GroupFragmentation `
            -panel $�t���[�� `
            -movingBtn $�ړ��{�^�� `
            -newY $�ݒu��]Y `
            -groupColor ([System.Drawing.Color]::LemonChiffon) `
            -boundaryColor ([System.Drawing.Color]::SpringGreen)
        
        if ($isFragmented) {
            return $true
        }
    }

    # ���ɁA�O���[�v�S�̂Ƃ��Ă̐������`�F�b�N
    if ($isGreen) {
        # ���̏�������O���[�v���ړ���ǂ������c�͈͂ɂȂ邩
        $movedCondRange = Get-GroupRangeAfterMove -panel $�t���[�� `
                                                 -movingBtn $�ړ��{�^�� `
                                                 -newY $�ݒu��]Y `
                                                 -targetColor ([System.Drawing.Color]::SpringGreen)

        foreach ($lr in $allLoopRanges) {
            if (Is-IllegalPair -condRange $movedCondRange -loopRange $lr) {
                return $true
            }
        }

        return $false
    }

    if ($isYellow) {
        # ���̃��[�v�O���[�v���ړ���ǂ������c�͈͂ɂȂ邩
        $movedLoopRange = Get-GroupRangeAfterMove -panel $�t���[�� `
                                                 -movingBtn $�ړ��{�^�� `
                                                 -newY $�ݒu��]Y `
                                                 -targetColor ([System.Drawing.Color]::LemonChiffon)

        foreach ($cr in $allCondRanges) {
            if (Is-IllegalPair -condRange $cr -loopRange $movedLoopRange) {
                return $true
            }
        }

        return $false
    }

    # �΂ł����ł��Ȃ��m�[�h�͋K�����Ȃ�
    return $false
}


function 00_�t���[����DragEnter�C�x���g��ݒ肷�� {
  param (
    [System.Windows.Forms.Panel]$�t���[��
  )

  $�t���[��.Add_DragEnter({
    param($sender, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.Button])) {
      $e.Effect = [System.Windows.Forms.DragDropEffects]::Move
    } else {
      $e.Effect = [System.Windows.Forms.DragDropEffects]::None
    }
  })
}

function 10_�{�^���̈ꗗ�擾 {
    param (
        [System.Windows.Forms.Panel]$�t���[��,
        [Int]$���݂�Y,
        [System.Drawing.Color]$���݂̐F,
        [Int]$�ݒu��]Y
    )
    
    # ���݂̐F��SpringGreen�܂���LemonChiffon�łȂ��ꍇ�A�t���O��Ԃ�
    if (-not ($���݂̐F -eq [System.Drawing.Color]::SpringGreen -or $���݂̐F -eq [System.Drawing.Color]::LemonChiffon)) {
        return $false
    }

    # ���݂̃{�^����Y�ʒu���Ƀ\�[�g
    $�\�[�g�ς݃{�^�� = $�t���[��.Controls |
                      Where-Object { $_ -is [System.Windows.Forms.Button] } |
                      Sort-Object { $_.Location.Y }
    
    # Y���W�͈̔͂�����
    $minY = [Math]::Min($���݂�Y, $�ݒu��]Y)
    $maxY = [Math]::Max($���݂�Y, $�ݒu��]Y)
    
    # �t���O��������
    $SameColorExists = $false
    
    foreach ($�{�^�� in $�\�[�g�ς݃{�^��) {
        $�{�^��Y = $�{�^��.Location.Y
        $�{�^���F = $�{�^��.BackColor
        
        ##Write-Host "�F: $�{�^���F" +  " �{�^��Y���W: $�{�^��Y"
    
        if ($���݂̐F -eq [System.Drawing.Color]::SpringGreen) {
    
        # Y���W���͈͓�����BackColor�����݂̐F�����`�F�b�N
        if ($�{�^��Y -ge $minY -and $�{�^��Y -le $maxY -and $�{�^���F -eq [System.Drawing.Color]::SpringGreen -and $�{�^��Y -ne $���݂�Y) {
            ##Write-Host "�{�^�� '$($�{�^��.Text)' ���w��͈͓��ɂ���ABackColor�����݂̐F�ł��B1"
            $SameColorExists = $true
            break  # �ŏ��Ɍ������烋�[�v�𔲂���
        }


        } elseif($���݂̐F -eq [System.Drawing.Color]::LemonChiffon) {

        if ($�{�^��Y -ge $minY -and $�{�^��Y -le $maxY -and $�{�^���F -eq [System.Drawing.Color]::LemonChiffon -and $�{�^��Y -ne $���݂�Y) {
            ##Write-Host "�{�^�� '$($�{�^��.Text)' ���w��͈͓��ɂ���ABackColor�����݂̐F�ł�2�B"
            $SameColorExists = $true
            break  # �ŏ��Ɍ������烋�[�v�𔲂���
        }
            
        }

    }
    
    # �t���O��Ԃ�l�Ƃ��ĕԂ�
    return $SameColorExists
}

function 00_�{�^���̏�l�ߍĔz�u�֐� {
  param (
    [System.Windows.Forms.Panel]$�t���[��,
    [int]$�{�^������ = 30,
    [int]$�Ԋu = 20  
  )

  # �{�^���̍����ƊԊu��ݒ�
  $�{�^������ = 30
  $�{�^���Ԋu = $�Ԋu

  # ���݂̃{�^����Y�ʒu���Ƀ\�[�g
  $�\�[�g�ς݃{�^�� = $�t���[��.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] } | Sort-Object { $_.Location.Y }

  $���݂�Y�ʒu = 0  # �{�^���z�u�̏����ʒu

  # "�������� �J�n"�A"�������� ����"�A"�������� �I��"�̈ʒu�����
  $�J�n�C���f�b�N�X = -1
  $���ԃC���f�b�N�X = -1
  $�I���C���f�b�N�X = -1

  for ($i = 0; $i -lt $�\�[�g�ς݃{�^��.Count; $i++) {
    if ($�\�[�g�ς݃{�^��[$i].Text -eq "�������� �J�n") {
      $�J�n�C���f�b�N�X = $i
    }
    if ($�\�[�g�ς݃{�^��[$i].Text -eq "�������� ����") {
      $���ԃC���f�b�N�X = $i
    }
    if ($�\�[�g�ς݃{�^��[$i].Text -eq "�������� �I��") {
      $�I���C���f�b�N�X = $i
    }
  }

  for ($�C���f�b�N�X = 0; $�C���f�b�N�X -lt $�\�[�g�ς݃{�^��.Count; $�C���f�b�N�X++) {
    $�{�^���e�L�X�g = $�\�[�g�ς݃{�^��[$�C���f�b�N�X].Text

    # �{�^���̐F��ݒ肷���������
    if ($�J�n�C���f�b�N�X -ne -1 -and $���ԃC���f�b�N�X -ne -1 -and $�C���f�b�N�X -gt $�J�n�C���f�b�N�X -and $�C���f�b�N�X -lt $���ԃC���f�b�N�X) {

 
if ($�\�[�g�ς݃{�^��[$�C���f�b�N�X].Tag.script -eq "�X�N���v�g") {
       $�\�[�g�ς݃{�^��[$�C���f�b�N�X].BackColor = $global:�s���N�ԐF
} else {
       $�\�[�g�ς݃{�^��[$�C���f�b�N�X].BackColor = [System.Drawing.Color]::Salmon
}




    } elseif ($���ԃC���f�b�N�X -ne -1 -and $�I���C���f�b�N�X -ne -1 -and $�C���f�b�N�X -gt $���ԃC���f�b�N�X -and $�C���f�b�N�X -lt $�I���C���f�b�N�X) {



if ($�\�[�g�ς݃{�^��[$�C���f�b�N�X].Tag.script -eq "�X�N���v�g") {
      $�\�[�g�ς݃{�^��[$�C���f�b�N�X].BackColor = $global:�s���N�F
} else {
       $�\�[�g�ς݃{�^��[$�C���f�b�N�X].BackColor =$global:�F
}


    } else {
      # ���݂̐F���擾
      $���݂̐F = $�\�[�g�ς݃{�^��[$�C���f�b�N�X].BackColor

      # ���݂̐F�� Salmon �܂��� FromArgb(200, 220, 255) �̏ꍇ�̂� White �ɕύX
      if ($���݂̐F.ToArgb() -eq [System.Drawing.Color]::Salmon.ToArgb() -or $���݂̐F.ToArgb() -eq $global:�F.ToArgb()) {
        $�\�[�g�ς݃{�^��[$�C���f�b�N�X].BackColor = [System.Drawing.Color]::White
      }
      if ($�\�[�g�ς݃{�^��[$�C���f�b�N�X].Tag.script -eq "�X�N���v�g") {
        $�\�[�g�ς݃{�^��[$�C���f�b�N�X].BackColor = [System.Drawing.Color]::Pink
      }
    }


    # �{�^���Ԋu�ƍ����̒����i"�������� ����"�̏ꍇ��0�Ƃ���j
    if ($�{�^���e�L�X�g -eq "�������� ����") {
      $�g�p����Ԋu = 10
      $�g�p���鍂�� = 0
    } else {
      $�g�p����Ԋu = $�{�^���Ԋu
      $�g�p���鍂�� = $�{�^������
    }

    # ��]�ʒu���v�Z
    $��]�ʒuY = $���݂�Y�ʒu + $�g�p����Ԋu

    # �{�^���̔z�u���X�V
    $�\�[�g�ς݃{�^��[$�C���f�b�N�X].Location = New-Object System.Drawing.Point(
      [Math]::Floor(($�t���[��.ClientSize.Width - $�\�[�g�ς݃{�^��[$�C���f�b�N�X].Width) / 2),
      $��]�ʒuY
    )

    # ���݂�Y�ʒu���X�V
    $���݂�Y�ʒu = $��]�ʒuY + $�g�p���鍂��
  }
}

function 00_�t���[�����쐬���� {
    param (
        [System.Windows.Forms.Form]$�t�H�[��,           # �t���[����ǉ�����t�H�[��
        [int]$�� = 300,                                # �t���[���̕�
        [int]$���� = 600,                              # �t���[���̍���
        [int]$X�ʒu = 100,                              # �t���[����X���W
        [int]$Y�ʒu = 20,                               # �t���[����Y���W
        [string]$�t���[���� = "�t���[���p�l��",         # �t���[���̖��O
        [bool]$Visible = $true,                        # �p�l���̏����\�����
        [System.Drawing.Color]$�w�i�F = ([System.Drawing.Color]::FromArgb(240,240,240)),  # �w�i�F
        [bool]$�g������ = $false                        # �g���̗L��
    )

    # �p�l���쐬
    $�t���[���p�l�� = New-Object System.Windows.Forms.Panel
    $�t���[���p�l��.Size = New-Object System.Drawing.Size($��, $����)
    $�t���[���p�l��.Location = New-Object System.Drawing.Point($X�ʒu, $Y�ʒu)
    $�t���[���p�l��.AllowDrop = $true
    $�t���[���p�l��.AutoScroll = $true
    $�t���[���p�l��.Name = $�t���[����
    $�t���[���p�l��.Visible = $Visible
    $�t���[���p�l��.BackColor = $�w�i�F

    if ($�g������) {
        $�t���[���p�l��.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    }
    else {
        $�t���[���p�l��.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    }

    # �`��I�u�W�F�N�g�p�̃v���p�e�B�� Tag �ɒǉ�
    $�t���[���p�l��.Tag = @{ DrawObjects = @() }

    # �t���[����Click�C�x���g��ݒ�
    $�t���[���p�l��.Add_Click({
        param($sender, $e)
        [System.Windows.Forms.MessageBox]::Show("�t���[�����N���b�N����܂����B")
    })

    # �t���[�����t�H�[���ɒǉ�
    $�t�H�[��.Controls.Add($�t���[���p�l��)

    # Paint�C�x���g�̐ݒ�
    00_���C���t���[���p�l����Paint�C�x���g��ݒ肷�� -�t���[���p�l�� $�t���[���p�l��

    # �t���[����Ԃ�
    return $�t���[���p�l��
}

function script:�R���e�L�X�g���j���[������������ {
    ###Write-Host "�R���e�L�X�g���j���[�����������܂��B"
    if (-not $script:ContextMenuInitialized) {
        # �R���e�L�X�g���j���[���X�N���v�g�X�R�[�v�Œ�`
        $script:�E�N���b�N���j���[ = New-Object System.Windows.Forms.ContextMenuStrip
        $script:���O�ύX���j���[�A�C�e�� = $script:�E�N���b�N���j���[.Items.Add("���O�ύX")
        $script:�X�N���v�g�ҏW���j���[�A�C�e�� = $script:�E�N���b�N���j���[.Items.Add("�X�N���v�g�ҏW")
        $script:�X�N���v�g���s���j���[�A�C�e�� = $script:�E�N���b�N���j���[.Items.Add("�X�N���v�g���s")
        $script:�폜���j���[�A�C�e�� = $script:�E�N���b�N���j���[.Items.Add("�폜")

        ###Write-Host "�R���e�L�X�g���j���[���ڂ�ǉ����܂����B"

        # �C�x���g�n���h���[�̐ݒ�
        $script:���O�ύX���j���[�A�C�e��.Add_Click({ 
            ###Write-Host "���O�ύX���j���[���N���b�N����܂����B"
            script:���O�ύX���� 
        })
        $script:�X�N���v�g�ҏW���j���[�A�C�e��.Add_Click({ 
            ###Write-Host "�X�N���v�g�ҏW���j���[���N���b�N����܂����B"
            script:�X�N���v�g�ҏW���� 
        })
        $script:�X�N���v�g���s���j���[�A�C�e��.Add_Click({ 
            ###Write-Host "�X�N���v�g�ҏW���j���[���N���b�N����܂����B"
            script:�X�N���v�g���s���� 
        })
        $script:�폜���j���[�A�C�e��.Add_Click({ 
            ###Write-Host "�폜���j���[���N���b�N����܂����B"
            script:�폜���� 
        })

        # �C�x���g�n���h���[����x�����ݒ肳�ꂽ���Ƃ��L�^
        $script:ContextMenuInitialized = $true
        ###Write-Host "�R���e�L�X�g���j���[�̏��������������܂����B"
    }
    else {
        ###Write-Host "�R���e�L�X�g���j���[�͊��ɏ���������Ă��܂��B"
    }
}

function script:���O�ύX���� {
    ###Write-Host "���O�ύX�������J�n���܂��B"
    if ($null -ne $���C���t�H�[��) {
        ###Write-Host "���C���t�H�[�����\���ɂ��܂��B"
        $���C���t�H�[��.Hide()
    }

    # �E�N���b�N���Ɋi�[�����{�^�����擾
    $btn = $script:�E�N���b�N���j���[.Tag
    ###Write-Host "�擾�����{�^��: $($btn.Name)"

    if ($btn -ne $null) {
        # ���̓{�b�N�X��\�����ĐV�������O���擾
        ###Write-Host "���̓{�b�N�X��\�����ĐV�������O���擾���܂��B"
        $�V�������O = [Microsoft.VisualBasic.Interaction]::InputBox(
            "�V�����{�^��������͂��Ă�������:",  # �v�����v�g
            "�{�^�����̕ύX",                    # �^�C�g��
            $btn.Text                            # �f�t�H���g�l
        )
        ###Write-Host "���[�U�[�����͂����V�������O: '$�V�������O'"

        # ���[�U�[�����͂����ꍇ�̂݃e�L�X�g���X�V
        if (![string]::IsNullOrWhiteSpace($�V�������O)) {
            ###Write-Host "�{�^���̃e�L�X�g���X�V���܂��B"
            $btn.Text = $�V�������O
        }
        else {
            ###Write-Host "�V�������O�����͂���܂���ł����B�ύX���L�����Z�����܂��B"
        }
    }
    else {
        Write-Warning "�{�^�����擾�ł��܂���ł����B"
    }

    if ($null -ne $���C���t�H�[��) {
        ###Write-Host "���C���t�H�[�����ĕ\�����܂��B"
        $���C���t�H�[��.Show()
    }
    ###Write-Host "���O�ύX�������������܂����B"
}

function script:�X�N���v�g�ҏW���� {
    ###Write-Host "�X�N���v�g�ҏW�������J�n���܂��B"
    if ($null -ne $���C���t�H�[��) {
        ###Write-Host "���C���t�H�[�����\���ɂ��܂��B"
        $���C���t�H�[��.Hide()
    }

    # �E�N���b�N���Ɋi�[�����{�^�����擾
    $btn = $script:�E�N���b�N���j���[.Tag
    ###Write-Host "�擾�����{�^��: $($btn.Name)"

    if ($btn -ne $null) {
        $�G���g��ID = $btn.Name.ToString()
        ###Write-Host "�G���g��ID: $�G���g��ID"

        # �X�N���v�g�ҏW�p�̃t�H�[�����쐬
        ###Write-Host "�X�N���v�g�ҏW�p�t�H�[�����쐬���܂��B"
        $�ҏW�t�H�[�� = New-Object System.Windows.Forms.Form
        $�ҏW�t�H�[��.Text = "�X�N���v�g�ҏW"
        $�ҏW�t�H�[��.Size = New-Object System.Drawing.Size(600, 400)
        $�ҏW�t�H�[��.StartPosition = "CenterScreen"

        # �X�N���v�g�擾�֐������݂���O��
        ###Write-Host "ID�ŃG���g�����擾���܂��B"
        try {
            $�擾�����G���g�� = ID�ŃG���g�����擾 -ID $�G���g��ID
            ###Write-Host "�擾�����G���g��: $�擾�����G���g��"
        }
        catch {
            Write-Error "�G���g���̎擾���ɃG���[���������܂���: $_"
            return
        }

        # �e�L�X�g�{�b�N�X�̍쐬
        ###Write-Host "�e�L�X�g�{�b�N�X���쐬���܂��B"
        $�e�L�X�g�{�b�N�X = New-Object System.Windows.Forms.TextBox
        $�e�L�X�g�{�b�N�X.Multiline = $true
        $�e�L�X�g�{�b�N�X.ScrollBars = "Both"
        $�e�L�X�g�{�b�N�X.WordWrap = $false
        $�e�L�X�g�{�b�N�X.Size = New-Object System.Drawing.Size(580, 300)
        $�e�L�X�g�{�b�N�X.Font = New-Object System.Drawing.Font("Consolas", 10)
        $�e�L�X�g�{�b�N�X.Location = New-Object System.Drawing.Point(10, 10)
        $�e�L�X�g�{�b�N�X.Text = $�擾�����G���g��  # �{�^���̃^�O�ɕۑ����ꂽ�X�N���v�g��ǂݍ���
        ###Write-Host "�e�L�X�g�{�b�N�X�ɃX�N���v�g��ݒ肵�܂����B"

        # �ۑ��{�^���̍쐬
        ###Write-Host "�ۑ��{�^�����쐬���܂��B"
        $�ۑ��{�^�� = New-Object System.Windows.Forms.Button
        $�ۑ��{�^��.Text = "�ۑ�"
        $�ۑ��{�^��.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $�ۑ��{�^��.Anchor = "Bottom, Right"
        $�ۑ��{�^��.Location = New-Object System.Drawing.Point(420, 330)
        $�ۑ��{�^��.Size = New-Object System.Drawing.Size(75, 25)

        # �L�����Z���{�^���̍쐬
        ###Write-Host "�L�����Z���{�^�����쐬���܂��B"
        $�L�����Z���{�^�� = New-Object System.Windows.Forms.Button
        $�L�����Z���{�^��.Text = "�L�����Z��"
        $�L�����Z���{�^��.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $�L�����Z���{�^��.Anchor = "Bottom, Right"
        $�L�����Z���{�^��.Location = New-Object System.Drawing.Point(500, 330)
        $�L�����Z���{�^��.Size = New-Object System.Drawing.Size(75, 25)

        # �t�H�[���ɃR���g���[����ǉ�
        ###Write-Host "�t�H�[���ɃR���g���[����ǉ����܂��B"
        $�ҏW�t�H�[��.Controls.Add($�e�L�X�g�{�b�N�X)
        $�ҏW�t�H�[��.Controls.Add($�ۑ��{�^��)
        $�ҏW�t�H�[��.Controls.Add($�L�����Z���{�^��)

        # �t�H�[���̃{�^����ݒ�
        $�ҏW�t�H�[��.AcceptButton = $�ۑ��{�^��
        $�ҏW�t�H�[��.CancelButton = $�L�����Z���{�^��

        # �t�H�[�������[�_���ŕ\��
        ###Write-Host "�X�N���v�g�ҏW�t�H�[����\�����܂��B"
        $���� = $�ҏW�t�H�[��.ShowDialog()
        ###Write-Host "�X�N���v�g�ҏW�t�H�[���������܂����B"

        if ($���� -eq [System.Windows.Forms.DialogResult]::OK) {
            ###Write-Host "�ۑ��{�^�����N���b�N����܂����B�G���g����u�����܂��B"
            try {
                ID�ŃG���g����u�� -ID $�G���g��ID -�V���������� $�e�L�X�g�{�b�N�X.Text
                ###Write-Host "�G���g���̒u�����������܂����B"
            }
            catch {
                Write-Error "�G���g���̒u�����ɃG���[���������܂���: $_"
            }
        }
        else {
            ###Write-Host "�ҏW���L�����Z������܂����B"
        }

        # �ҏW�t�H�[����j��
        ###Write-Host "�ҏW�t�H�[����j�����܂��B"
        $�ҏW�t�H�[��.Dispose()
    }
    else {
        Write-Warning "�{�^�����擾�ł��܂���ł����B"
    }

    if ($null -ne $���C���t�H�[��) {
        ###Write-Host "���C���t�H�[�����ĕ\�����܂��B"
        $���C���t�H�[��.Show()
    }
    ###Write-Host "�X�N���v�g�ҏW�������������܂����B"
}

function script:�X�N���v�g���s���� {
    ###Write-Host "�X�N���v�g���s�������J�n���܂��B"
    if ($null -ne $���C���t�H�[��) {
        ###Write-Host "���C���t�H�[�����\���ɂ��܂��B"
        $���C���t�H�[��.Hide()
    }

    # �E�N���b�N���Ɋi�[�����{�^�����擾
    $btn = $script:�E�N���b�N���j���[.Tag
    ###Write-Host "�擾�����{�^��: $($btn.Name)"

    if ($btn -ne $null) {
        $�G���g��ID = $btn.Name.ToString()
        ###Write-Host "�G���g��ID: $�G���g��ID"

        # �X�N���v�g���s�p�̃t�H�[�����쐬
        ###Write-Host "�X�N���v�g���s�p�t�H�[�����쐬���܂��B"
        $���s�t�H�[�� = New-Object System.Windows.Forms.Form
        $���s�t�H�[��.Text = "�X�N���v�g���s"
        $���s�t�H�[��.Size = New-Object System.Drawing.Size(600, 500)
        $���s�t�H�[��.StartPosition = "CenterScreen"

        # �X�N���v�g�擾�֐������݂���O��
        ###Write-Host "ID�ŃG���g�����擾���܂��B"
        try {
            $�擾�����G���g�� = ID�ŃG���g�����擾 -ID $�G���g��ID
            ###Write-Host "�擾�����G���g��: $�擾�����G���g��"
        }
        catch {
            Write-Error "�G���g���̎擾���ɃG���[���������܂���: $_"
            return
        }

        # �X�N���v�g���͗p�e�L�X�g�{�b�N�X�̍쐬
        ###Write-Host "�X�N���v�g���͗p�e�L�X�g�{�b�N�X���쐬���܂��B"
        $�e�L�X�g�{�b�N�X = New-Object System.Windows.Forms.TextBox
        $�e�L�X�g�{�b�N�X.Multiline = $true
        $�e�L�X�g�{�b�N�X.ScrollBars = "Both"
        $�e�L�X�g�{�b�N�X.WordWrap = $false
        $�e�L�X�g�{�b�N�X.Size = New-Object System.Drawing.Size(580, 250)
        $�e�L�X�g�{�b�N�X.Font = New-Object System.Drawing.Font("Consolas", 10)
        $�e�L�X�g�{�b�N�X.Location = New-Object System.Drawing.Point(10, 10)
        $�e�L�X�g�{�b�N�X.Text = $�擾�����G���g��
        
        # �R���\�[���o�͗p�e�L�X�g�{�b�N�X�̍쐬
        ###Write-Host "�R���\�[���p�e�L�X�g�{�b�N�X���쐬���܂��B"
        $�R���\�[���{�b�N�X = New-Object System.Windows.Forms.TextBox
        $�R���\�[���{�b�N�X.Multiline = $true
        $�R���\�[���{�b�N�X.ScrollBars = "Both"
        $�R���\�[���{�b�N�X.WordWrap = $false
        $�R���\�[���{�b�N�X.ReadOnly = $true
        $�R���\�[���{�b�N�X.Size = New-Object System.Drawing.Size(580, 150)
        $�R���\�[���{�b�N�X.Font = New-Object System.Drawing.Font("Consolas", 10)
        $�R���\�[���{�b�N�X.Location = New-Object System.Drawing.Point(10, 270)

        # ���s�{�^���̍쐬
        ###Write-Host "���s�{�^�����쐬���܂��B"
        $���s�{�^�� = New-Object System.Windows.Forms.Button
        $���s�{�^��.Text = "���s"
        $���s�{�^��.Anchor = "Bottom, Right"
        $���s�{�^��.Location = New-Object System.Drawing.Point(420, 430)
        $���s�{�^��.Size = New-Object System.Drawing.Size(75, 25)
        $���s�{�^��.Add_Click({
            $output = Invoke-Expression $�e�L�X�g�{�b�N�X.Text 2>&1
            $�R���\�[���{�b�N�X.Text = $output
        })

        # �L�����Z���{�^���̍쐬
        ###Write-Host "�L�����Z���{�^�����쐬���܂��B"
        $�L�����Z���{�^�� = New-Object System.Windows.Forms.Button
        $�L�����Z���{�^��.Text = "�L�����Z��"
        $�L�����Z���{�^��.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $�L�����Z���{�^��.Anchor = "Bottom, Right"
        $�L�����Z���{�^��.Location = New-Object System.Drawing.Point(500, 430)
        $�L�����Z���{�^��.Size = New-Object System.Drawing.Size(75, 25)

        # �t�H�[���ɃR���g���[����ǉ�
        ###Write-Host "�t�H�[���ɃR���g���[����ǉ����܂��B"
        $���s�t�H�[��.Controls.Add($�e�L�X�g�{�b�N�X)
        $���s�t�H�[��.Controls.Add($�R���\�[���{�b�N�X)
        $���s�t�H�[��.Controls.Add($���s�{�^��)
        $���s�t�H�[��.Controls.Add($�L�����Z���{�^��)

        # �t�H�[���̃{�^����ݒ�
        $���s�t�H�[��.CancelButton = $�L�����Z���{�^��

        # �t�H�[�������[�_���ŕ\��
        ###Write-Host "�X�N���v�g���s�t�H�[����\�����܂��B"
        $���s�t�H�[��.ShowDialog()
        ###Write-Host "�X�N���v�g���s�t�H�[���������܂����B"
    }
    else {
        Write-Warning "�{�^�����擾�ł��܂���ł����B"
    }

    if ($null -ne $���C���t�H�[��) {
        ###Write-Host "���C���t�H�[�����ĕ\�����܂��B"
        $���C���t�H�[��.Show()
    }
    ###Write-Host "�X�N���v�g���s�������������܂����B"
}


function ��������{�^���폜���� {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Windows.Forms.Button]$�{�^��
    )

    #-----------------------------
    # �@ ��{���̎擾
    #-----------------------------
    $parent  = $�{�^��.Parent
    if (-not $parent) { return }

    $myY     = $�{�^��.Location.Y
    $myText  = $�{�^��.Text.Trim()

    #-----------------------------
    # �A �T���^�[�Q�b�g������
    #-----------------------------
    switch ($myText) {
        '�������� �J�n' {
            $����     = '��'       # ������艺����T��
            $�~������ = @('�������� ����','�������� �I��')
        }
        '�������� �I��' {
            $����     = '��'       # �������㑤��T��
            $�~������ = @('�������� ����','�������� �J�n')
        }
        default {
            Write-Verbose "SpringGreen �����ΏۊO�e�L�X�g [$myText]"
            return
        }
    }

    #-----------------------------
    # �B �Z��R���g���[��������𒊏o
    #-----------------------------
    #   $���n�b�V��[�e�L�X�g] = �ł��߂� Control
    $���n�b�V�� = @{}

    foreach ($ctrl in $parent.Controls) {
        if (-not ($ctrl -is [System.Windows.Forms.Button])) { continue }
        $txt = $ctrl.Text.Trim()
        if ($txt -notin $�~������) { continue }

        $delta = $ctrl.Location.Y - $myY
        if (($���� -eq '��' -and $delta -le 0) -or
            ($���� -eq '��' -and $delta -ge 0)) { continue }   # �������t�Ȃ珜�O

        $���� = [math]::Abs($delta)

        # �܂��o�^����Ă��Ȃ� or �����Ƌ߂��{�^���Ȃ�̗p
        if (-not $���n�b�V��.ContainsKey($txt) -or
            $���� -lt $���n�b�V��[$txt].����) {

            $���n�b�V��[$txt] = [pscustomobject]@{
                Ctrl  = $ctrl
                ����  = $����
            }
        }
    }

    #-----------------------------
    # �C �R�����Ă��邩����
    #-----------------------------
    $�폜�Ώ� = @($�{�^��)   # �������g�͕K���폜
    foreach ($name in $�~������) {
        if ($���n�b�V��.ContainsKey($name)) {
            $�폜�Ώ� += $���n�b�V��[$name].Ctrl
        }
    }

    if ($�폜�Ώ�.Count -lt 3) {
        Write-Warning "�Z�b�g������Ȃ����ߍ폜���܂���B"
        return
    }

    #-----------------------------
    # �D �폜���s
    #-----------------------------
    foreach ($b in $�폜�Ώ�) {
        try {
            $parent.Controls.Remove($b)
            $b.Dispose()
        }
        catch {
            Write-Warning "�{�^�� [$($b.Text)] �̍폜�Ɏ��s: $_"
        }
    }

    #-----------------------------
    # �E �㏈���i�z�u�����Ȃǁj
    #-----------------------------
    if (Get-Command 00_�{�^���̏�l�ߍĔz�u�֐� -ErrorAction SilentlyContinue) {
        00_�{�^���̏�l�ߍĔz�u�֐� -�t���[�� $parent
    }
    if (Get-Command 00_���ǋL���� -ErrorAction SilentlyContinue) {
        00_���ǋL���� -�t���[���p�l�� $Global:�����p�l��
    }
}

function ���[�v�{�^���폜���� {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.Windows.Forms.Button]$�{�^��
    )

    #-----------------------------
    # �@ �e�R���e�i��GroupID�̎擾
    #-----------------------------
    $parent = $�{�^��.Parent
    if (-not $parent) { return }

    # ���[�v�J�n�^�I���{�^���ɂ͓���GroupID�������Ă���z��
    $targetGroupID = $�{�^��.Tag.GroupID

    #-----------------------------
    # �A ����GroupID������ LemonChiffon �{�^�������W
    #    �i�J�n�E�I����2�����낤�͂��j
    #-----------------------------
    $���{�^���ꗗ = @()

    foreach ($ctrl in $parent.Controls) {
        # �{�^���ȊO�͖���
        if (-not ($ctrl -is [System.Windows.Forms.Button])) {
            continue
        }

        # �F��LemonChiffon�ȊO�͖����i���[�v�ȊO�͑ΏۊO�j
        if ($ctrl.BackColor.ToArgb() -ne [System.Drawing.Color]::LemonChiffon.ToArgb()) {
            continue
        }

        # GroupID����v������̂����E��
        if ($ctrl.Tag.GroupID -eq $targetGroupID) {
            $���{�^���ꗗ += $ctrl
        }
    }

    #-----------------------------
    # �B 2�����Ă��邩�`�F�b�N
    #    �Е��������Ă�ꍇ�͉������Ȃ��Ōx��
    #-----------------------------
    if ($���{�^���ꗗ.Count -lt 2) {
        Write-Warning "���[�v�J�n/�I���̃Z�b�g������Ȃ����ߍ폜���܂���B"
        return
    }

    #-----------------------------
    # �C ���ۂɍ폜
    #-----------------------------
    foreach ($b in $���{�^���ꗗ) {
        try {
            $parent.Controls.Remove($b)
            $b.Dispose()
        }
        catch {
            Write-Warning "���[�v�{�^�� [$($b.Text)] �̍폜�Ɏ��s: $_"
        }
    }

    #-----------------------------
    # �D �㏈���i�l�ߒ����Ɩ��ĕ`��j
    #    ��������{�^���폜�����Ɠ�������ɂ��낦��
    #-----------------------------
    if (Get-Command 00_�{�^���̏�l�ߍĔz�u�֐� -ErrorAction SilentlyContinue) {
        00_�{�^���̏�l�ߍĔz�u�֐� -�t���[�� $parent
    }
    if (Get-Command 00_���ǋL���� -ErrorAction SilentlyContinue) {
        00_���ǋL���� -�t���[���p�l�� $Global:�����p�l��
    }
}





function script:�폜���� {
    ###Write-Host "�폜�������J�n���܂��B"
    # �E�N���b�N���Ɋi�[�����{�^�����擾
    $btn = $script:�E�N���b�N���j���[.Tag
    ###Write-Host "�擾�����{�^��: $($btn.Name)"


    # ���� ��������i�΁j��p�폜 ����
    if ($btn.BackColor -eq [System.Drawing.Color]::SpringGreen) {
        ��������{�^���폜���� -�{�^�� $btn
        return   # ��������͂����Ŋ���
    }
    # ���� ���[�v�i���j��p�폜 ����
    elseif ($btn.BackColor -eq [System.Drawing.Color]::LemonChiffon) {
        ���[�v�{�^���폜���� -�{�^�� $btn
        return   # ���[�v�͂����Ŋ���
    }

    # �������牺�͏]���́u���ʂ�1���������v���[�g


    if ($btn -ne $null) {
        if ($btn.Parent -ne $null) {
            ###Write-Host "�{�^���̐e�R���e�i���擾���܂����B"
            try {
                ###Write-Host "�{�^����e�R���e�i����폜���܂��B"
                $btn.Parent.Controls.Remove($btn)
                $btn.Dispose()
                ###Write-Host "�{�^�����폜���܂����B"

                # �O���֐�����`����Ă���ꍇ�̂ݎ��s
                if (Get-Command 00_�{�^���̏�l�ߍĔz�u�֐� -ErrorAction SilentlyContinue) {
                    ###Write-Host "�{�^���̏�l�ߍĔz�u�֐����Ăяo���܂��B"
                    00_�{�^���̏�l�ߍĔz�u�֐� -�t���[�� $btn.Parent
                }
                else {
                    Write-Warning "�֐� '00_�{�^���̏�l�ߍĔz�u�֐�' ����`����Ă��܂���B"
                }

                if (Get-Command 00_���ǋL���� -ErrorAction SilentlyContinue) {
                    ###Write-Host "���ǋL�������Ăяo���܂��B"
                    00_���ǋL���� -�t���[���p�l�� $Global:�����p�l��
                }
                else {
                    Write-Warning "�֐� '00_���ǋL����' ����`����Ă��܂���B"
                }
            }
            catch {
                Write-Error "�{�^���̍폜���ɃG���[���������܂���: $_"
            }
        }
        else {
            Write-Warning "�{�^���̐e�����݂��܂���B"
        }
    }
    else {
        Write-Warning "�폜�Ώۂ̃{�^�����擾�ł��܂���ł����B"
    }
    ###Write-Host "�폜�������������܂����B"
}

function script:�{�^���N���b�N���\�� {
    param (
        [System.Windows.Forms.Button]$sender
    )
   
#    if ($global:�O���[�v���[�h -eq 1 -and $sender.Parent.Name -eq $Global:�����p�l��.Name) {
   


    # Shift�L�[��������Ă���ꍇ�ɏ�����ύX
    if ([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift -and $sender.Parent.Name -eq $Global:�����p�l��.Name) {





        # �O���[�v���[�h�̏ꍇ�̏������e�������ɋL�q
 $�O���[�v��� = @"
�O���[�v���[�h���:
  �{�^����: $($sender.Name)
  �{�^���e�L�X�g: $($sender.Text)
  �O���[�v���ł̏��������s��...
"@

        # ���ɃO���[�v���[�h���K�p����Ă���ꍇ�̓��Z�b�g
        if ($sender.FlatStyle -eq [System.Windows.Forms.FlatStyle]::Flat -and $sender.FlatAppearance.BorderColor -eq [System.Drawing.Color]::Red) {
            ###Write-Host "���ɃO���[�v���[�h���K�p����Ă��邽�߁A���Z�b�g���܂��B"

            #$sender.FlatStyle = [System.Windows.Forms.FlatStyle]::Standard
            $sender.FlatAppearance.BorderColor = [System.Drawing.Color]::Black
            $sender.FlatAppearance.BorderSize = 1

        }
        else {
            ###Write-Host "�O���[�v���[�h��K�p���܂��B"

            # �O���[�v���[�h�̓K�p����
            #$sender.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $sender.FlatAppearance.BorderColor = [System.Drawing.Color]::Red
            $sender.FlatAppearance.BorderSize = 3
        }
        �K�p-�Ԙg�ɋ��܂ꂽ�{�^���X�^�C�� -�t���[���p�l�� $Global:�����p�l�� #$global:���C���[�p�l��
               #Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show("g3", "�^�C�g��")

    }
    else {
        ##Write-Host "�ʏ탂�[�h�ŏ��������s���܂��B"

      #  if ($sender.BackColor -eq [System.Drawing.Color]::Pink -and $sender.Parent.Name -eq $Global:�����p�l��.Name) {
        if ($sender.Tag.script -eq "�X�N���v�g" -and $sender.Parent.Name -eq $Global:�����p�l��.Name) {
            ##Write-Host "�w�i�F��Pink�̃{�^���ł��B"
            ####Write-Host "�{�^����: $($sender.Name)"
                        # �O���[�o���ϐ��ɍ��W���i�[
            $�Ō�̕��� = �O���[�o���ϐ����琔�l�擾�@-�p�l�� $Global:�����p�l�� 

            $A = [int]$�Ō�̕���

             $Global:Pink�I��z��[$A].Y���W = $sender.Location.Y +15
�@�@�@�@�@�@ $Global:Pink�I��z��[$A].�l = 1
            $Global:Pink�I��z��[$A].�W�J�{�^�� = $sender.Name

            $Global:���ݓW�J���̃X�N���v�g�� = $sender.Name


            Write-Host $Global:���ݓW�J���̃X�N���v�g�� -ForegroundColor Red

            ##Write-Host "AA-" $Global:���ݓW�J���̃X�N���v�g��

                       $Global:Pink�I�� = $true
                       #����\������ -�t�H�[�� $���C���t�H�[�� -�� 1400 -���� 900 -���T�C�Y 10 -���p�x 30 -PictureBoxX 850 -PictureBoxY 100 -PictureBox�� 90 -PictureBox���� 20
               �t���[���p�l�����炷�ׂẴ{�^�����폜���� -�t���[���p�l�� $Global:���E�p�l��
            $�擾�����G���g�� = ID�ŃG���g�����擾 -ID $sender.Name
                Write-Host $�擾�����G���g�� -ForegroundColor Red
            PINK����{�^���쐬 -������ $�擾�����G���g��

        $�Ō�̕��� = �O���[�o���ϐ����琔�l�擾�@-�p�l�� $Global:�����p�l��
        $Global:���C���[�K�w�̐[�� = [int]$�Ō�̕��� + 1

        # Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($Global:���C���[�K�w�̐[��, "�^^�CC�gg��?A") 
 


           00_���ǋL���� -�t���[���p�l�� $Global:�����p�l��
            #[System.Windows.Forms.MessageBox]::Show("�w�i�F��Pink�̃{�^����: $�擾�����G���g��", "�w�i�FPink", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }

$��� = @"
�{�^�����:
  ���O: $($sender.Name)
  �e�L�X�g: $($sender.Text)
  �T�C�Y: $($sender.Size.Width) x $($sender.Size.Height)
  �ʒu: X=$($sender.Location.X), Y=$($sender.Location.Y)
  �w�i�F: $($sender.BackColor)
"@

        ##Write-Host "�������b�Z�[�W�{�b�N�X�ŕ\�����܂��B"
        [System.Windows.Forms.MessageBox]::Show($���, "�{�^�����", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }

    ###Write-Host "�{�^���N���b�N���\���������������܂����B"
}



function PINK����{�^���쐬 {
    param (
        [string]$������
    )

    Write-Host " !!!!!!" -ForegroundColor Yellow

    $����Y = 20 # Y���W�̏����l

    # ����������s�ŕ������A�ŏ���1�s���X�L�b�v
    $������ -split "`r?`n" | Select-Object -Skip 1 | ForEach-Object {
        # �e�s���Z�~�R�����ŕ���
        $parts = $_ -split ';'

        # �e������ϐ��Ɋ��蓖��
        $�{�^���� = $parts[0].Trim()
        $�w�i�F�� = $parts[1].Trim()
        $�e�L�X�g = $parts[2].Trim()
        $�^�C�v = $parts[3].Trim()

        #-----------------------------------------------------------------------------------------------------

        # �F������System.Drawing.Color�I�u�W�F�N�g���擾
        try {
            # �F������F���擾
            $�w�i�F = [System.Drawing.Color]::FromName($�w�i�F��)
            if (!$�w�i�F.IsKnownColor) {
                throw "�����ȐF��"
            }
        }
        catch {
            # �F���������ȏꍇ�A�F�R�[�h�Ƃ��ĉ�͂����݂�
            try {
                # HEX�J���[�R�[�h�i#�Ȃ��j�����o���A������#��t��
                if ($�w�i�F�� -match '^[0-9A-Fa-f]{6}$' -or $�w�i�F�� -match '^[0-9A-Fa-f]{8}$') {
                    $hexColor = "#$�w�i�F��"
                    $�w�i�F = [System.Drawing.ColorTranslator]::FromHtml($hexColor)
                }
                # HEX�J���[�R�[�h�i#����j�����o
                elseif ($�w�i�F�� -match '^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$') {
                    $�w�i�F = [System.Drawing.ColorTranslator]::FromHtml($�w�i�F��)
                }
                # RGB�`���i��: 255,0,255�j�����o
                elseif ($�w�i�F�� -match '^\d{1,3},\d{1,3},\d{1,3}$') {
                    $rgb = $�w�i�F�� -split ','
                    $�w�i�F = [System.Drawing.Color]::FromArgb(
                        [int]$rgb[0],
                        [int]$rgb[1],
                        [int]$rgb[2]
                    )
                }
                else {
                    throw "�����ȐF�w��"
                }
            }
            catch {
                ##Write-Host "�x��: �F���܂��͐F�R�[�h�������ł��B�{�^���̍쐬���X�L�b�v���܂��B - �F��: $�w�i�F��" -ForegroundColor Yellow
                ##Write-Host " - ���e: $_" -ForegroundColor Yellow
                return
            }
        }

        # �f�o�b�O�o��
        ##Write-Host "�{�^����: $�{�^����, �w�i�F: $�w�i�F��, �e�L�X�g: $�e�L�X�g" -ForegroundColor Green

        $�� = 120        
        $����X = [Math]::Floor(($Global:���E�p�l��.ClientSize.Width - $��) / 2)# �����z�u�̂��߂�X���W���v�Z

        # �{�^���e�L�X�g�� "�������� ����" �̏ꍇ
        if ($�e�L�X�g -eq "�������� ����") {
        $����Y = $����Y - 5
        $�V�{�^�� = 00_�{�^�����쐬���� -�R���e�i $Global:���E�p�l�� -�e�L�X�g $�e�L�X�g -�{�^���� $�{�^���� -�� $�� -���� 1 -X�ʒu $����X -Y�ʒu $����Y -�g�� 1 -�w�i�F $�w�i�F -�h���b�O�\ $false 

        $����Y += 10         
        }else{
            Write-Host "AAAA" -ForegroundColor Yellow
        $�V�{�^�� = 00_�{�^�����쐬���� -�R���e�i $Global:���E�p�l�� -�e�L�X�g $�e�L�X�g -�{�^���� $�{�^���� -�� $�� -���� 30 -X�ʒu $����X -Y�ʒu $����Y -�g�� 1 -�w�i�F $�w�i�F -�h���b�O�\ $true�@-�{�^���^�C�v "�m�[�h"�@-�{�^���^�C�v2 $�^�C�v

        $����Y += 50
        }



    }
    00_���C���t���[���p�l����Paint�C�x���g��ݒ肷�� -�t���[���p�l�� $Global:���E�p�l��
    00_���ǋL���� -�t���[���p�l�� $Global:���E�p�l��
}

function 00_�{�^�����쐬���� {
    param (
        [System.Windows.Forms.Control]$�R���e�i,          # �{�^����ǉ�����R���e�i�i�t���[���j
        [string]$�e�L�X�g = "�h���b�O�ňړ�",              # �{�^���̃e�L�X�g
        [string]$�{�^����,                                # �{�^����
        [int]$�� = 120,                                   # �{�^���̕�
        [int]$���� = 30,                                  # �{�^���̍���
        [int]$X�ʒu = 10,                                 # �{�^����X���W
        [int]$Y�ʒu = 20,                                 # �{�^����Y���W
        [int]$�g�� = 0,                                   # �{�^���̘g���T�C�Y
        [System.Drawing.Color]$�w�i�F,                    # �{�^���̔w�i�F�i�K�{�j
        [bool]$�h���b�O�\ = $true,                      # �h���b�O�\���ǂ���
        [int]$�t�H���g�T�C�Y = 10,
        [string]$�{�^���^�C�v = "�Ȃ�",
        [string]$�{�^���^�C�v2 = "�Ȃ�",
        [string]$�����ԍ� = "�Ȃ�"
    )

    ###Write-Host "00_�{�^�����쐬���܂��B�{�^����: $�{�^����"
    
    # �R���e�L�X�g���j���[�̏�����
    script:�R���e�L�X�g���j���[������������

    # �{�^���̍쐬
    ###Write-Host "�{�^�����쐬���܂��B"
    $�{�^�� = New-Object System.Windows.Forms.Button
    $�{�^��.Text = $�e�L�X�g #$�{�^���� # 
    $�{�^��.Size = New-Object System.Drawing.Size($��, $����)
    $�{�^��.Location = New-Object System.Drawing.Point($X�ʒu, $Y�ʒu)
    $�{�^��.AllowDrop = $false                            # �{�^�����̂̃h���b�v�𖳌���
    $�{�^��.Name = $�{�^����                              # �{�^����Name�v���p�e�B��ݒ�
    $�{�^��.BackColor = $�w�i�F                           # �{�^���̔w�i�F��ݒ�
    $�{�^��.UseVisualStyleBackColor = $false              # BackColor��L���ɂ���

    ###Write-Host "�{�^���̃t�H���g��ݒ肵�܂��B"
    # �t�H���g�T�C�Y�̐ݒ�
    $�{�^��.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", $�t�H���g�T�C�Y)

    $�{�^��.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $�{�^��.FlatAppearance.BorderSize = $�g��

    $�{�^��.Tag = @{
        BackgroundColor = $�w�i�F
        GroupID = $null
        MultiLineTags = $null # �K�v�ɉ����Đݒ�
        script = $null # �K�v�ɉ����Đݒ�
        �����ԍ� = $�����ԍ�
    } # �w�i�F��Tag�v���p�e�B�ɕۑ�

      if ($�{�^���^�C�v2 -eq "�X�N���v�g") {
      $�{�^��.Tag.script = "�X�N���v�g"
      }

    # �R���e�L�X�g���j���[��ݒ�
    $�{�^��.ContextMenuStrip = $script:�E�N���b�N���j���[

    if ($�h���b�O�\) {
        ###Write-Host "�h���b�O�\�ȃ{�^���̐ݒ�����܂��B"
        # �t���O��ǉ�
        $�{�^��.Tag.IsDragging = $false
        $�{�^��.Tag.StartPoint = [System.Drawing.Point]::Empty

        # �{�^����MouseDown�C�x���g�Ńh���b�O�̊J�n�ƉE�N���b�N�̏�����ݒ�
        ###Write-Host "MouseDown�C�x���g�n���h���[��ǉ����܂��B"
        $�{�^��.Add_MouseDown({
            param($sender, $e)
            ###Write-Host "MouseDown�C�x���g���������܂����B�{�^��: $($sender.Name), �{�^��: $($e.Button)"
            if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                # �h���b�O�J�n�ʒu���L�^
                ###Write-Host "���N���b�N�����o����܂����B�h���b�O�J�n�ʒu���L�^���܂��B"
                $sender.Tag.StartPoint = $e.Location
                $sender.Tag.IsDragging = $false
            }
            elseif ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
                ###Write-Host "�E�N���b�N�����o����܂����B"
                # �E�N���b�N�����i�K�v�ɉ����Ēǉ��j
            }
        })

        # �{�^����MouseMove�C�x���g�Ńh���b�O�̔���
        ###Write-Host "MouseMove�C�x���g�n���h���[��ǉ����܂��B"
        $�{�^��.Add_MouseMove({
            param($sender, $e)
            if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
                if (-not $sender.Tag.IsDragging) {
                    # �}�E�X���ړ������������v�Z
                    $dx = [Math]::Abs($e.X - $sender.Tag.StartPoint.X)
                    $dy = [Math]::Abs($e.Y - $sender.Tag.StartPoint.Y)
                    ###Write-Host "�}�E�X�ړ�����: dx=$dx, dy=$dy"
                    if ($dx -ge 5 -or $dy -ge 5) {
                        ###Write-Host "�h���b�O���J�n���܂��B"
                        $sender.Tag.IsDragging = $true
                        # �h���b�O���̃{�^����ݒ�
                        $global:�h���b�O���̃{�^�� = $sender
                        # �h���b�O���J�n
                        $sender.DoDragDrop($sender, [System.Windows.Forms.DragDropEffects]::Move)
                    }
                }
            }
        })

        # �{�^����DragDrop�C�x���g�ňʒu���X�V
        ###Write-Host "DragDrop�C�x���g�n���h���[��ǉ����܂��B"
        $�{�^��.Add_DragDrop({
            param($sender, $e)
            ###Write-Host "DragDrop�C�x���g���������܂����B"
            if ($global:�h���b�O���̃{�^�� -ne $null) {
                $targetButton = $e.Data.GetData([System.Windows.Forms.DataFormats]::Object)
                if ($targetButton -ne $null -and $targetButton -is [System.Windows.Forms.Button]) {
                    ###Write-Host "�h���b�O���̃{�^�����ړ����܂��B�{�^��: $($targetButton.Name)"
                    # �e�R���e�i���Ń{�^���̃C���f�b�N�X��ύX
                    $sender.Parent.Controls.SetChildIndex($targetButton, 0)
                    # �V�����ʒu���v�Z
                    $newLocation = $sender.PointToClient($e.Location)
                    ###Write-Host "�V�����ʒu: X=$($newLocation.X), Y=$($newLocation.Y)"
                    $targetButton.Location = $newLocation
                    $global:�h���b�O���̃{�^�� = $null
                }
                else {
                    Write-Warning "�h���b�O�f�[�^���{�^���ł͂���܂���B"
                }
            }
            else {
                Write-Warning "�h���b�O���̃{�^�������݂��܂���B"
            }
        })

        # �{�^����DragEnter�C�x���g�ŃG�t�F�N�g��ݒ�
        ###Write-Host "DragEnter�C�x���g�n���h���[��ǉ����܂��B"
        $�{�^��.Add_DragEnter({
            param($sender, $e)
            if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::Object)) {
                ###Write-Host "DragEnter: Move�G�t�F�N�g��ݒ肵�܂��B"
                $e.Effect = [System.Windows.Forms.DragDropEffects]::Move
            }
            else {
                ###Write-Host "DragEnter: Move�G�t�F�N�g��ݒ�ł��܂���B"
            }
        })
    }

    # �{�^���N���b�N���ɏ���\������C�x���g�n���h���[��ǉ�
    ###Write-Host "Click�C�x���g�n���h���[��ǉ����܂��B"
    if ($�{�^���^�C�v -eq "�m�[�h") {

    $�{�^��.Add_Click({
        param($sender, $e)


        ###Write-Host "Click�C�x���g���������܂����B�{�^��: $($sender.Name)"
        script:�{�^���N���b�N���\�� -sender $sender
    })
    } else {
        # False�̏������e
    }

    


    # �E�N���b�N���Ƀ��j���[�\���A���̎��_�őΏۃ{�^����Tag��
    ###Write-Host "MouseUp�C�x���g�n���h���[��ǉ����܂��B"
    $�{�^��.Add_MouseUp({
        param($sender, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            ###Write-Host "�E�N���b�N�����o����܂����B���j���[��\�����܂��B"
            $script:�E�N���b�N���j���[.Tag = $sender
            $script:�E�N���b�N���j���[.Show($sender, $e.Location)
        }
    })

    # �R���e�i�Ƀ{�^����ǉ�
    ###Write-Host "�{�^�����R���e�i�ɒǉ����܂��B"
    $�R���e�i.Controls.Add($�{�^��)

    # �{�^���I�u�W�F�N�g��Ԃ�
    ###Write-Host "�{�^���̍쐬���������܂����B"
    return $�{�^��
}

function 00_���C���Ƀ{�^�����쐬���� {
    param (
        [System.Windows.Forms.Control]$�R���e�i,          # �{�^����ǉ�����R���e�i�i�t���[���j
        [string]$�e�L�X�g = "�h���b�O�ňړ�",              # �{�^���̃e�L�X�g
        [string]$�{�^����,                                # �{�^����
        [int]$�� = 120,                                   # �{�^���̕�
        [int]$���� = 30,                                  # �{�^���̍���
        [int]$X�ʒu = 10,                                 # �{�^����X���W
        [int]$Y�ʒu = 20,                                 # �{�^����Y���W
        [int]$�g�� = 1,                                   # �{�^���̘g���T�C�Y
        [System.Drawing.Color]$�w�i�F,                    # �{�^���̔w�i�F�i�K�{�j
        [int]$�t�H���g�T�C�Y = 10,                        # �t�H���g�T�C�Y
        [scriptblock]$�N���b�N�A�N�V����                   # �{�^���N���b�N���̃A�N�V����
    )

    $�{�^�� = New-Object System.Windows.Forms.Button
    $�{�^��.Text = $�e�L�X�g -replace "`n", [Environment]::NewLine # ���s�𔽉f
    $�{�^��.Size = New-Object System.Drawing.Size($��, $����)
    $�{�^��.Location = New-Object System.Drawing.Point($X�ʒu, $Y�ʒu)
    $�{�^��.AllowDrop = $false                            # �{�^�����̂̃h���b�v�𖳌���
    $�{�^��.Name = $�{�^����                              # �{�^����Name�v���p�e�B��ݒ�
    $�{�^��.BackColor = $�w�i�F                           # �{�^���̔w�i�F��ݒ�
    $�{�^��.UseVisualStyleBackColor = $false              # BackColor��L���ɂ���
    $�{�^��.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    ###Write-Host "�{�^���̃t�H���g��ݒ肵�܂��B"
    # �t�H���g�T�C�Y�̐ݒ�
    $�{�^��.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", $�t�H���g�T�C�Y)

    $�{�^��.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $�{�^��.FlatAppearance.BorderSize = $�g��

    # �N���b�N�C�x���g�̓o�^
    $�{�^��.Add_Click({
        param($sender, $e)
        ###Write-Host "Click�C�x���g���������܂����B�{�^��: $($sender.Name)"
    
        if ($sender.Name -eq "001") {
            # 001 �ɑ΂���A�N�V����
            �\��-�Ԙg�{�^�����ꗗ -�t���[���p�l�� $Global:�����p�l��
        } elseif ($sender.Name -eq "002") {
            # 002 �ɑ΂���A�N�V����
        $global:�O���[�v���[�h = 1
        } elseif ($sender.Name -eq "003�E") {



        �@   $�Ō�̕��� = �O���[�o���ϐ����琔�l�擾�@-�p�l�� $Global:�����p�l�� 
�@�@�@##Write-Host "���p�l��" $�Ō�̕���



if ($�Ō�̕��� -ge 2) { 
    # True�̏������e�i$���l��2�ȏ�̏ꍇ�j
    �����폜���� -�t�H�[�� $���C���t�H�[��
            ���C���t���[���̉E���������ꍇ�̏���

  
} else {
    # False�̏������e�i$���l��1�ȉ��̏ꍇ�j
}

00_���ǋL���� -�t���[���p�l�� $Global:�����p�l��
       } elseif ($sender.Name -eq "004��") {


�@   $�Ō�̕��� = �O���[�o���ϐ����琔�l�擾�@-�p�l�� $Global:�����p�l�� 
�@�@�@##Write-Host "���p�l��" $�Ō�̕���
        
        if ($�Ō�̕��� -le 3) { 
            # True�̏������e�i$���l��3�ȉ��̏ꍇ�j
            �����폜���� -�t�H�[�� $���C���t�H�[��
             ���C���t���[���̍����������ꍇ�̏���
        } else {
            # False�̏������e�i$���l��4�ȏ�̏ꍇ�j
        }

        00_���ǋL���� -�t���[���p�l�� $Global:�����p�l��
     

        }else {
            ###Write-Host "�{�^������001�܂���002�ł͂���܂���B�A�N�V�����͎��s����܂���B"
        }

# ���C���t���[����Paint�C�x���g��ݒ�
00_���C���t���[���p�l����Paint�C�x���g��ݒ肷�� -�t���[���p�l�� $Global:�����p�l��

# ���C���t���[����DragEnter�C�x���g��ݒ�
00_�t���[����DragEnter�C�x���g��ݒ肷�� -�t���[�� $Global:�����p�l��

# ���C���t���[����DragDrop�C�x���g��ݒ�
00_�t���[����DragDrop�C�x���g��ݒ肷�� -�t���[�� $Global:�����p�l��



    })

    # �R���e�i�Ƀ{�^����ǉ�
    ###Write-Host "�{�^�����R���e�i�ɒǉ����܂��B"
    $�R���e�i.Controls.Add($�{�^��)

    # �{�^���I�u�W�F�N�g��Ԃ�
    ###Write-Host "�{�^���̍쐬���������܂����B"
    return $�{�^��
}


function 00_�ėp�F�{�^�����쐬���� {
  param (
    [System.Windows.Forms.Control]$�R���e�i,     # �{�^����ǉ�����R���e�i�i�t���[���j
    [string]$�e�L�X�g,                # �{�^���̃e�L�X�g
    [string]$�{�^����,                # �{�^����
    [int]$��,                     # �{�^���̕�
    [int]$����,                    # �{�^���̍���
    [int]$X�ʒu,                   # �{�^����X���W
    [int]$Y�ʒu,                   # �{�^����Y���W
    [System.Drawing.Color]$�w�i�F           # �{�^���̔w�i�F
  )

  # �{�^���̍쐬
  $�F�{�^�� = New-Object System.Windows.Forms.Button

  # --- ��{���C�A�E�g�֘A ---
  $�F�{�^��.Text = $�e�L�X�g                                     # �{�^����ɕ\������e�L�X�g
  $�F�{�^��.Size = New-Object System.Drawing.Size($��, $����)     # �{�^���̕\���T�C�Y
  $�F�{�^��.Location = New-Object System.Drawing.Point($X�ʒu, $Y�ʒu) # �{�^���̔z�u���W
  $�F�{�^��.Name = $�{�^����                                     # �R���g���[����
  $�F�{�^��.Font = New-Object System.Drawing.Font("Meiryo UI", 10, [System.Drawing.FontStyle]::Bold)
  # �� �����{�ǂ݂₷���t�H���g�B�׎��������Ȃ� Bold �O���Ă�OK�B

  # --- �w�i�F�ƕ����F�̓K�p ---
  $�F�{�^��.BackColor = $�w�i�F
  $�F�{�^��.ForeColor = [System.Drawing.Color]::Black             # �� �����F�����ɌŒ�
  $�F�{�^��.UseVisualStyleBackColor = $false                      # �e�[�}�ˑ��ɂ��Ȃ�

  # --- �t���b�g&�g���Ȃ��ݒ� ---
  $�F�{�^��.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat    # �t���b�g�\��
  $�F�{�^��.FlatAppearance.BorderSize = 0                         # �g���Ȃ�
  $�F�{�^��.FlatAppearance.BorderColor = $�w�i�F                  # �O�̂��ߓ��F�œh��Ԃ�����

  # --- �z�o�[�E�N���b�N���̐F�ω���}�~ ---
  $�F�{�^��.FlatAppearance.MouseOverBackColor = $�w�i�F           # �z�o�[���̔w�i�F
  $�F�{�^��.FlatAppearance.MouseDownBackColor = $�w�i�F           # �N���b�N���̔w�i�F

  # --- ���^����Tag�ɕۑ��i���R�[�h�̈Ӑ}���ێ��j---
  $�F�{�^��.Tag = @{
    BackgroundColor = $�w�i�F
    GroupID = $null
  }

  # --- �R���e�i�ɒǉ� ---
  $�R���e�i.Controls.Add($�F�{�^��)

  # --- ������{�^����Ԃ��i��ŃC�x���g�Ƃ��\��p�j---
  return $�F�{�^��
}


function 00_�ėp�F�{�^���̃N���b�N�C�x���g��ݒ肷�� {
    param(
        [System.Windows.Forms.Button]$�{�^��,
        [int]$�����{�^���̍��� = 30,
        [int]$�����{�^���̕� = 120,
        [int]$�����{�^���̊Ԋu = 20,
        [int]$���� = 0,
        [string]$�����ԍ�
    )

    # �{�^����Tag�Ɋ֘A����ۑ�
    $�{�^��.Tag = @{
        �{�^������      = $�����{�^���̍���
        �Ԋu           = $�����{�^���̊Ԋu
        ��             = $�����{�^���̕�
        �����ԍ�       = $�����ԍ�
        BackgroundColor = $�{�^��.BackColor
    }

    # �N���b�N�C�x���g��ݒ�
    $�{�^��.Add_Click({
        param($sender, $e)

        # Tag����K�v�ȏ����擾
        $tag = $sender.Tag
        $buttonColor = $tag.BackgroundColor
        $buttonText  = $sender.Text
        $buttonName  = ID��������������

        $�{�^������ = $tag.�{�^������
        $�Ԋu     = $tag.�Ԋu
        $��       = $tag.��

        $���C���t���[���p�l�� = $Global:�����p�l��
        $global:���C���[�p�l�� = $���C���t���[���p�l��
        $����X = [Math]::Floor(($���C���t���[���p�l��.ClientSize.Width - $��) / 2)

        # ����Y�ʒu���v�Z����֐�
        function Get-NextYPosition {
            param(
                [System.Windows.Forms.Control]$panel,
                [int]$����,
                [int]$�Ԋu
            )
            if ($panel.Controls.Count -eq 0) {
                return $�Ԋu
            }
            else {
                $�ŉ��{�^�� = $panel.Controls |
                    Where-Object { $_ -is [System.Windows.Forms.Button] } |
                    Sort-Object { $_.Location.Y } |
                    Select-Object -Last 1
                return $�ŉ��{�^��.Location.Y + $���� + $�Ԋu
            }
        }

        $����Y = Get-NextYPosition -panel $���C���t���[���p�l�� -���� $�{�^������ -�Ԋu $�Ԋu

        switch ($buttonText) {
            "���[�v" {
                # �O���[�vID���擾�E�X�V
                $currentGroupID = $global:���F�{�^���O���[�v�J�E���^
                $global:���F�{�^���O���[�v�J�E���^++

                # �J�n�{�^���̍쐬
                $�{�^��1 = 00_�{�^�����쐬���� -�R���e�i $���C���t���[���p�l�� -�e�L�X�g "$buttonText �J�n" -�{�^���� "$buttonName-1" -�� $�� -���� $�{�^������ -X�ʒu $����X -Y�ʒu $����Y -�g�� 1 -�w�i�F $buttonColor -�h���b�O�\ $true�@-�{�^���^�C�v "�m�[�h" -�����ԍ� $tag.�����ԍ�
                $�{�^��1.Tag.GroupID = $currentGroupID
                $global:�{�^���J�E���^++

                # �I���{�^���̍쐬
                $����Y += $�{�^������ + $�Ԋu
                $�{�^��2 = 00_�{�^�����쐬���� -�R���e�i $���C���t���[���p�l�� -�e�L�X�g "$buttonText �I��" -�{�^���� "$buttonName-2" -�� $�� -���� $�{�^������ -X�ʒu $����X -Y�ʒu $����Y -�g�� 1 -�w�i�F $buttonColor -�h���b�O�\ $true�@-�{�^���^�C�v "�m�[�h" -�����ԍ� $tag.�����ԍ�
                00_�����񏈗����e -�{�^���� $buttonName -�����ԍ� $tag.�����ԍ�
                $�{�^��2.Tag.GroupID = $currentGroupID
                $global:�{�^���J�E���^++
            }
            "��������" {
                # �O���[�vID���擾�E�X�V
                $currentGroupID = $global:�ΐF�{�^���O���[�v�J�E���^
                $global:�ΐF�{�^���O���[�v�J�E���^++

                # �J�n�{�^���̍쐬
                $�{�^��1 = 00_�{�^�����쐬���� -�R���e�i $���C���t���[���p�l�� -�e�L�X�g "$buttonText �J�n" -�{�^���� "$buttonName-1" -�� $�� -���� $�{�^������ -X�ʒu $����X -Y�ʒu $����Y -�g�� 1 -�w�i�F $buttonColor -�h���b�O�\ $true�@-�{�^���^�C�v "�m�[�h" -�����ԍ� $tag.�����ԍ�
                $�{�^��1.Tag.GroupID = $currentGroupID
                $global:�{�^���J�E���^++

                # ���ԃ{�^���i�O���[���C���j�̍쐬
                $����Y += $�{�^������ + $�Ԋu
                $�{�^������ = 00_�{�^�����쐬���� -�R���e�i $���C���t���[���p�l�� -�e�L�X�g "$buttonText ����" -�{�^���� "$buttonName-2" -�� $�� -���� 1 -X�ʒu $����X -Y�ʒu ($����Y - 10) -�g�� 1 -�w�i�F ([System.Drawing.Color]::Gray) -�h���b�O�\ $false�@-�{�^���^�C�v "�m�[�h" -�����ԍ� $tag.�����ԍ�

                # �I���{�^���̍쐬
                $�{�^��2 = 00_�{�^�����쐬���� -�R���e�i $���C���t���[���p�l�� -�e�L�X�g "$buttonText �I��" -�{�^���� "$buttonName-3" -�� $�� -���� $�{�^������ -X�ʒu $����X -Y�ʒu $����Y -�g�� 1 -�w�i�F $buttonColor -�h���b�O�\ $true�@-�{�^���^�C�v "�m�[�h" -�����ԍ� $tag.�����ԍ�
                00_�����񏈗����e -�{�^���� $buttonName -�����ԍ� $tag.�����ԍ�
                $�{�^��2.Tag.GroupID = $currentGroupID
                $global:�{�^���J�E���^++
            }
            default {

                # �������s�{�^���̍쐬
                $�V�{�^�� = 00_�{�^�����쐬���� -�R���e�i $���C���t���[���p�l�� -�e�L�X�g $buttonText -�{�^���� "$buttonName-1" -�� $�� -���� $�{�^������ -X�ʒu $����X -Y�ʒu $����Y -�g�� 1 -�w�i�F $buttonColor -�h���b�O�\ $true�@-�{�^���^�C�v "�m�[�h" -�����ԍ� $tag.�����ԍ�
                00_�����񏈗����e -�{�^���� $buttonName -�����ԍ� $tag.�����ԍ� -�{�^�� $�V�{�^��

                #$currentIndex = Get-ButtonIndex -�Ώۃ{�^�� $�V�{�^�� -�t���[���p�l�� $���C���t���[���p�l��
                $global:�{�^���J�E���^++

            }
        }

        # ���̒ǋL����
        00_���ǋL���� -�t���[���p�l�� $Global:�����p�l��
    })
}

# JSON�t�@�C������w��L�[�̒l���擾����֐�
function �擾-JSON�l {
    param (
        [string]$jsonFilePath, # JSON�t�@�C���̃p�X
        [string]$keyName       # �擾�������L�[��
    )
    # �t�@�C�����m�F
    if (-Not (Test-Path $jsonFilePath)) {
        throw "�w�肳�ꂽ�t�@�C����������܂���: $jsonFilePath"
    }

    # JSON�t�@�C����ǂݍ���
    $jsonContent = Get-Content -Path $jsonFilePath | ConvertFrom-Json

    # �w�肳�ꂽ�L�[�̒l���擾
    if ($jsonContent.PSObject.Properties[$keyName]) {
        return $jsonContent.$keyName
    } else {
        throw "�w�肳�ꂽ�L�[��JSON�ɑ��݂��܂���: $keyName"
    }
}

function �t�H�[���Ƀ��x���ǉ� {
    param (
        [Parameter(Mandatory)]
        [System.Windows.Forms.Form]$�t�H�[��, # �t�H�[���I�u�W�F�N�g
        
        [Parameter(Mandatory)]
        [string]$�e�L�X�g, # ���x���ɕ\������e�L�X�g
        
        [Parameter(Mandatory)]
        [int]$X���W, # ���x����X���W
        
        [Parameter(Mandatory)]
        [int]$Y���W  # ���x����Y���W
    )
    # ���x�����쐬
    $���x�� = New-Object System.Windows.Forms.Label
    $���x��.Text = $�e�L�X�g
    $���x��.Location = New-Object System.Drawing.Point($X���W, $Y���W)
    #$���x��.AutoSize = $true

    # �t�H���g�X�^�C����ݒ�i�^�L���X�g��ǉ��j
    $�t�H���g�X�^�C�� = [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold)
    $���x��.Font = New-Object System.Drawing.Font("Arial", 10, $�t�H���g�X�^�C��)

    # �e�L�X�g�̐F��ݒ�
    $���x��.ForeColor = [System.Drawing.Color]::black

    # �w�i�F��ݒ�i�����ɂ���ꍇ�͕s�v�j
    #$���x��.BackColor = [System.Drawing.Color]::LightYellow

    # �e�L�X�g�̔z�u��ݒ�
    $���x��.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    # �t�H�[���Ƀ��x����ǉ�
    $�t�H�[��.Controls.Add($���x��)
}

# �{�^���̃C���f�b�N�X���擾����֐�
function Get-ButtonIndex {
    param (
        [System.Windows.Forms.Button]$�Ώۃ{�^��,
        [System.Windows.Forms.Panel]$�t���[���p�l��
    )

    # �t���[�����̃{�^����Y���W�Ń\�[�g
    $sortedButtons = $�t���[���p�l��.Controls |
                     Where-Object { $_ -is [System.Windows.Forms.Button] } |
                     Sort-Object { $_.Location.Y }

    # �C���f�b�N�X���擾
    $index = 0
    foreach ($btn in $sortedButtons) {
        if ($btn -eq $�Ώۃ{�^��) {
            return $index
        }
        $index++
    }

    # �{�^����������Ȃ��ꍇ��-1��Ԃ�
    return -1
}

function �K�p-�Ԙg�ɋ��܂ꂽ�{�^���X�^�C�� {
    param (
        [System.Windows.Forms.Panel]$�t���[���p�l��
    )
          #Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($�t���[���p�l��.Name, "�^�C�g��")
    # �R���g���[�����f�o�b�O�o��
    ###Write-Host "=== �f�o�b�O: �R���g���[���ꗗ ==="
    foreach ($control in $�t���[���p�l��.Controls) {
        ##Write-Host "�R���g���[��: $($control.GetType().Name), Text: $($control.Text)"
    }
    ###Write-Host "==============================="

    # �t���[�����̃{�^�����擾���ă\�[�g
    $�\�[�g�ς݃{�^�� = $�t���[���p�l��.Controls |
                        Where-Object { $_ -is [System.Windows.Forms.Button] } |
                        Sort-Object { $_.Location.Y }

    #Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($�\�[�g�ς݃{�^��.Count, "�^�C�g��")

    # �f�o�b�O: �{�^�������o��
    ###Write-Host "=== �f�o�b�O: �{�^����� ==="
    foreach ($�{�^�� in $�\�[�g�ς݃{�^��) {
        $�g�F = if ($�{�^��.FlatStyle -eq 'Flat') {
            $�{�^��.FlatAppearance.BorderColor
                      #Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show("q", "�^�C�g��")
        } else {
            "���ݒ�"

        }
        ###Write-Host "�{�^��: $($�{�^��.Text), �g�̐F: $�g�F, FlatStyle: $($�{�^��.FlatStyle), Location: $($�{�^��.Location)"
    }
    ###Write-Host "==========================="

    # �Ԙg�̃{�^���̃C���f�b�N�X��T��
    $�Ԙg�{�^���C���f�b�N�X = @()
    for ($i = 0; $i -lt $�\�[�g�ς݃{�^��.Count; $i++) {
        $�{�^�� = $�\�[�g�ς݃{�^��[$i]
        # �f�o�b�O: �F��r�̌��ʂ��ڍׂɏo��
        if ($�{�^��.FlatStyle -eq 'Flat') {
            $���݂̐F = $�{�^��.FlatAppearance.BorderColor
            ###Write-Host "�f�o�b�O: �{�^��[$($�{�^��.Text)] �̘g�F (ARGB): $($���݂̐F.ToArgb())"

            if ($���݂̐F.ToArgb() -eq [System.Drawing.Color]::Red.ToArgb()) {
                ###Write-Host "�Ԙg�{�^�����o: $($�{�^��.Text) (�C���f�b�N�X: $i)"
                $�Ԙg�{�^���C���f�b�N�X += $i
            }
        }
    }

    # �Ԙg�{�^����2�ȏ゠��ꍇ�ɏ��������s
    if ($�Ԙg�{�^���C���f�b�N�X.Count -ge 2) {
        $�J�n�C���f�b�N�X = $�Ԙg�{�^���C���f�b�N�X[0]
        $�I���C���f�b�N�X = $�Ԙg�{�^���C���f�b�N�X[-1]
          #Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show("aka2izyo", "�^�C�g��")
        # �Ԙg�ɋ��܂ꂽ�{�^���ɃX�^�C����K�p
        ###Write-Host "�Ԙg�ɋ��܂ꂽ�{�^��:"
        for ($i = $�J�n�C���f�b�N�X + 1; $i -lt $�I���C���f�b�N�X; $i++) {
            $���܂ꂽ�{�^�� = $�\�[�g�ς݃{�^��[$i]
            ###Write-Host " - $($���܂ꂽ�{�^��.Text) �ɃX�^�C����K�p���܂��B"

            # �X�^�C����K�p
            $���܂ꂽ�{�^��.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $���܂ꂽ�{�^��.FlatAppearance.BorderColor = [System.Drawing.Color]::Red
            $���܂ꂽ�{�^��.FlatAppearance.BorderSize = 3
        }


    } else {
        ###Write-Host "�Ԙg�̃{�^����2�ȏ㑶�݂��܂���B"
    }
}

function �\��-�Ԙg�{�^�����ꗗ {
    param (
        [System.Windows.Forms.Panel]$�t���[���p�l��
    )
    $global:�O���[�v���[�h = 0

    # �t���[�����̃{�^�����擾���ă\�[�g
    $�\�[�g�ς݃{�^�� = $�t���[���p�l��.Controls |
                        Where-Object { $_ -is [System.Windows.Forms.Button] } |
                        Sort-Object { $_.Location.Y }

    # �Ԙg�̃{�^���̖��O��Y�ʒu�����W
    $�Ԙg�{�^�����X�g = @()
    foreach ($�{�^�� in $�\�[�g�ς݃{�^��) {
        if ($�{�^��.FlatStyle -eq 'Flat' -and 
            $�{�^��.FlatAppearance.BorderColor.ToArgb() -eq [System.Drawing.Color]::Red.ToArgb()) {
            $�Ԙg�{�^�����X�g += @{
                Name = $�{�^��.Name
                Y�ʒu = $�{�^��.Location.Y
            }
        }
    }



    # �Ԙg�̃{�^���̖��O�ꗗ���o�͂��A�폜
    if ($�Ԙg�{�^�����X�g.Count -gt 0) {


        $�ŏ�Y�ʒu = [int]::MaxValue  # �폜�Ώۃ{�^���̍ŏ�Y�ʒu���擾���邽�߂̕ϐ�
        $�폜�����{�^����� = @()         # �폜�����{�^���̏����i�[����z��

        foreach ($�{�^����� in $�Ԙg�{�^�����X�g) {
            $���O = $�{�^�����.Name
            $Y�ʒu = $�{�^�����.Y�ʒu


            if ($Y�ʒu -lt $�ŏ�Y�ʒu) {            # �ŏ�Y�ʒu���X�V
                $�ŏ�Y�ʒu = $Y�ʒu
            }

            $�폜�Ώۃ{�^�� = $�t���[���p�l��.Controls[$���O]            # �{�^�����擾
            
            if ($�폜�Ώۃ{�^�� -ne $null) {
                $�{�^���F = $�폜�Ώۃ{�^��.BackColor.Name                # �{�^���̔w�i�F�ƃe�L�X�g���擾
                $�e�L�X�g = $�폜�Ώۃ{�^��.Text
                $�^�C�v = $�폜�Ώۃ{�^��.Tag.script

                $�t���[���p�l��.Controls.Remove($�폜�Ώۃ{�^��)                # �{�^�����p�l������폜
                $�폜�Ώۃ{�^��.Dispose()                # �K�v�ɉ����ă{�^����j��
          
                $�폜�����{�^����� += "$���O;$�{�^���F;$�e�L�X�g;$�^�C�v"                # �폜�����{�^���̏���z��ɒǉ��i���O-�{�^���F-�e�L�X�g�j

            }
            else {
                ###Write-Host "�{�^�� '$���O' ��������܂���ł����B"
            }
        }

        $����Y = $�ŏ�Y�ʒu        # �폜���ꂽ�Ԙg�{�^���̒��ōł����Y�ʒu������Y�ʒu�Ƃ��Đݒ�
        $entryString = $�폜�����{�^����� -join "_"         # �폜�����{�^���̏����A���_�[�X�R�A�ŘA������������ɕϊ�

       # [System.Windows.Forms.MessageBox]::Show($entryString , "debug���\��", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

        $�Ō�̕��� = �O���[�o���ϐ����琔�l�擾�@-�p�l�� $Global:�����p�l�� 

        $A = [int]$�Ō�̕���

        # $�t���[���p�l��   $����Y
        $Global:Pink�I��z��[$A].����Y = $����Y
        $Global:Pink�I��z��[$A].�l = 1



        # �V�����{�^���̍쐬
        $buttonName  = ID��������������
        $�� = 120
        $����X = [Math]::Floor(($�t���[���p�l��.ClientSize.Width - $��) / 2)
        $�V�{�^�� = 00_�{�^�����쐬���� -�R���e�i $�t���[���p�l�� -�e�L�X�g "�X�N���v�g" -�{�^���� "$buttonName-1" -�� 120 -���� 30 -X�ʒu $����X -Y�ʒu $����Y -�g�� 1 -�w�i�F ([System.Drawing.Color]::Pink) -�h���b�O�\ $true -�{�^���^�C�v "�m�[�h" -�{�^���^�C�v2 "�X�N���v�g"

        00_�����񏈗����e -�{�^���� "$buttonName" -�����ԍ� "99-1" -���ڃG���g�� $entryString -�{�^�� $�V�{�^��



        # �{�^���J�E���^�̃C���N�������g
        $global:�{�^���J�E���^++

        # �{�^���̍Ĕz�u�i�K�v�ɉ����āj
        00_�{�^���̏�l�ߍĔz�u�֐� -�t���[�� $�t���[���p�l��
        00_���ǋL���� -�t���[���p�l�� $�t���[���p�l��
    } else {
        #Write-Host "�Ԙg�̃{�^�������݂��܂���B"
    }
}

function �t���[���p�l�����炷�ׂẴ{�^�����폜���� {
    param (
        [System.Windows.Forms.Panel]$�t���[���p�l��
    )

    # �p�l�����̂��ׂẴ{�^�����擾
    $�{�^�����X�g = $�t���[���p�l��.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] }

    foreach ($�{�^�� in $�{�^�����X�g) {
        try {
            # �{�^�����p�l������폜
            $�t���[���p�l��.Controls.Remove($�{�^��)

            # �{�^���̃��\�[�X�����
            $�{�^��.Dispose()

            ##Write-Host "�{�^�� '$($�{�^��.Name)' ���폜���܂����B" -ForegroundColor Green
        }
        catch {
            ##Write-Host "�{�^�� '$($�{�^��.Name)' �̍폜���ɃG���[���������܂����B - $_" -ForegroundColor Red
        }
    }

    # �K�v�ɉ����āA�ĕ`����g���K�[
    $�t���[���p�l��.Invalidate()
}

# ����`���֐�
function ����`�� {
    param (
        [int]$��,
        [int]$����,
        [System.Drawing.Point]$�n�_,
        [System.Drawing.Point]$�I�_,
        [float]$���T�C�Y = 10.0,    # ���w�b�h�̃T�C�Y
        [float]$���p�x = 30.0      # ���w�b�h�̊p�x�i�x���@�j
    )

    # �f�o�b�O: �󂯎�����n�_�ƏI�_��\��
    #Write-Host "����`�� - �n�_: ($($�n�_.X), $($�n�_.Y)), �I�_: ($($�I�_.X), $($�I�_.Y))"

    # Bitmap ���쐬�i32bppArgb �œ����x���T�|�[�g�j
    $bitmap = New-Object System.Drawing.Bitmap($��, $����, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $�O���t�B�b�N�X = [System.Drawing.Graphics]::FromImage($bitmap)

    # �w�i�F�𓧖��ɐݒ�
    $�O���t�B�b�N�X.Clear([System.Drawing.Color]::Transparent)

    # �y���̐ݒ�
    $�y�� = New-Object System.Drawing.Pen([System.Drawing.Color]::Pink, 2)

    try {
        # ���C�����C����`��
        $�O���t�B�b�N�X.DrawLine($�y��, $�n�_, $�I�_)

        # �x�N�g���̌v�Z
        $dx = $�I�_.X - $�n�_.X
        $dy = $�I�_.Y - $�n�_.Y
        $���� = [math]::Sqrt($dx * $dx + $dy * $dy)

        if ($���� -eq 0) { 
            #Write-Host "���̒�����0�̂��߁A���w�b�h��`��ł��܂���B"
            return $bitmap
        }

        # �P�ʃx�N�g��
        $ux = $dx / $����
        $uy = $dy / $����

        # ���w�b�h�̊p�x�����W�A���ɕϊ�
        $�p�x���W�A�� = [math]::PI * $���p�x / 180.0

        # ���w�b�h�̃|�C���g�v�Z
        $sin = [math]::Sin($�p�x���W�A��)
        $cos = [math]::Cos($�p�x���W�A��)

        $�_1X = [math]::Round($�I�_.X - $���T�C�Y * ($cos * $ux + $sin * $uy))
        $�_1Y = [math]::Round($�I�_.Y - $���T�C�Y * ($cos * $uy - $sin * $ux))
        $�_2X = [math]::Round($�I�_.X - $���T�C�Y * ($cos * $ux - $sin * $uy))
        $�_2Y = [math]::Round($�I�_.Y - $���T�C�Y * ($cos * $uy + $sin * $ux))

        $�_1 = New-Object System.Drawing.Point -ArgumentList $�_1X, $�_1Y
        $�_2 = New-Object System.Drawing.Point -ArgumentList $�_2X, $�_2Y

        # �f�o�b�O: ���w�b�h�̓_��\��
        #Write-Host "���w�b�h�̓_1: ($($�_1.X), $($�_1.Y)), �_2: ($($�_2.X), $($�_2.Y))"

        # ���w�b�h��`��
        $�O���t�B�b�N�X.DrawLine($�y��, $�I�_, $�_1)
        $�O���t�B�b�N�X.DrawLine($�y��, $�I�_, $�_2)
    }
    catch {
        #Write-Host "�`�撆�ɃG���[���������܂���: $_"
    }
    finally {
        # ���\�[�X�̉��
        $�y��.Dispose()
        $�O���t�B�b�N�X.Dispose()
    }

    return $bitmap
}

# ����\������֐�
function ����\������ {
    param (
        [System.Windows.Forms.Form]$�t�H�[��,
        [int]$��,
        [int]$����,
        [System.Drawing.Point]$�n�_,
        [System.Drawing.Point]$�I�_,
        [float]$���T�C�Y = 10.0,    # ���w�b�h�̃T�C�Y
        [float]$���p�x = 30.0,     # ���w�b�h�̊p�x�i�x���@�j
        [int]$PictureBoxX = 0,        # PictureBox��X���W
        [int]$PictureBoxY = 0,        # PictureBox��Y���W
        [int]$PictureBox�� = 1400,    # PictureBox�̕�
        [int]$PictureBox���� = 900     # PictureBox�̍���
    )

    # �f�o�b�O: �󂯎�����n�_�ƏI�_��\��
    #Write-Host "����\������ - �n�_: ($($�n�_.X), $($�n�_.Y)), �I�_: ($($�I�_.X), $($�I�_.Y))"

    # ����`���֐����Ăяo���� Bitmap ���擾
    $bitmap = ����`�� -�� $�� -���� $���� -�n�_ $�n�_ -�I�_ $�I�_ -���T�C�Y $���T�C�Y -���p�x $���p�x
    #Write-Host "���̕`�悪�������܂����B"

    # PictureBox ���쐬
    $pictureBox = New-Object System.Windows.Forms.PictureBox
    $pictureBox.Name = "ArrowPictureBox"  # ���O��ݒ�
    $pictureBox.Image = $bitmap
    $pictureBox.Location = New-Object System.Drawing.Point($PictureBoxX, $PictureBoxY)
    $pictureBox.Size = New-Object System.Drawing.Size($PictureBox��, $PictureBox����)
    $pictureBox.SizeMode = "Normal"  # AutoSize �ł͂Ȃ� Normal �ɐݒ�
    $pictureBox.BackColor =  [System.Drawing.Color]::FromArgb(255, 255, 255)  # �w�i���ꎞ�I�ɉ��F�ɐݒ肵�Ċm�F
    $pictureBox.Parent = $�t�H�[��  # �e���t�H�[���ɐݒ�
    $pictureBox.BringToFront()      # PictureBox��O�ʂɈړ�

    # �f�o�b�O: PictureBox �̈ʒu�ƃT�C�Y��\��
    #Write-Host "PictureBox �̈ʒu: ($PictureBoxX, $PictureBoxY), �T�C�Y: ($PictureBox��, $PictureBox����)"

    # PictureBox ���t�H�[���ɒǉ�
    $�t�H�[��.Controls.Add($pictureBox)
}

function �����폜���� {
    param (
        [System.Windows.Forms.Form]$�t�H�[��
    )

    # ���O��PictureBox������
    $pictureBox = $�t�H�[��.Controls | Where-Object { $_.Name -eq "ArrowPictureBox" }

    if ($pictureBox) {
        # PictureBox���t�H�[������폜
        $�t�H�[��.Controls.Remove($pictureBox)
        $pictureBox.Dispose()
        #Write-Host "�����폜���܂����B"
    }
    else {
        ##Write-Host "��󂪌�����܂���ł����B"
    }
}

function Check-Pink�I��z��Objects {
    #Write-Host "---- Check-Pink�I��z��Objects �֐��J�n ----"

    # �O���[�o���ϐ������݂��邩�m�F
    if (-not (Test-Path variable:Global:Pink�I��z��)) {
        Write-Warning "�O���[�o���ϐ� 'Pink�I��z��' �����݂��܂���B"
        #Write-Host "����: FALSE"
        return $false
    } else {
        #Write-Host "�O���[�o���ϐ� 'Pink�I��z��' �͑��݂��܂��B"
    }

    # �O���[�o���ϐ����z��ł��邩�m�F
    if (-not ($Global:Pink�I��z�� -is [System.Array])) {
        Write-Warning "'Pink�I��z��' �͔z��ł͂���܂���B"
        #Write-Host "���݂̒l: $($Global:Pink�I��z��)"
        #Write-Host "����: FALSE"
        return $false
    } else {
        #Write-Host "'Pink�I��z��' �͔z��ł��B"
    }

    # �e�I�u�W�F�N�g�����[�v���āA'�l' �v���p�e�B��1���ǂ������`�F�b�N
    foreach ($item in $Global:Pink�I��z��) {
        #Write-Host "`n--- ���C���[ $($item.���C���[) �̓��e ---"
        #Write-Host "����Y: $($item.����Y)"
        #Write-Host "�l: $($item.�l)"

        if ($item.�l -eq 1) {
            #Write-Host "���C���[ $($item.���C���[) �̒l��1�ł��B"
            #Write-Host "����: TRUE"
            return $true
        } else {
            #Write-Host "���C���[ $($item.���C���[) �̒l��1�ł͂���܂���B"
        }
    }

    # ���ׂẴ��C���[�̒l��0�̏ꍇ
    #Write-Host "`n���ׂẴ��C���[�̒l��0�ł��B"
    #Write-Host "����: FALSE"
    return $false
}

