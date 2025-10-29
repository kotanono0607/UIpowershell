# 20241117_���C��foam�֐�.ps1

function ���s�C�x���g {

            try {
                # ���C���t���[���p�l�����̃{�^�����擾���AY���W�Ń\�[�g
                $buttons = $global:���C���[1.Controls |
                           Where-Object { $_ -is [System.Windows.Forms.Button] } |
                           Sort-Object { $_.Location.Y }

                # �o�͗p�̕�����ϐ���������
                $output = ""

                # �{�^���̑������擾
                $buttonCount = $buttons.Count
                write-host "�{�^���J�E���g" + $buttons.Count
                # �Ō�Ɍ�������Green�{�^���̐eID���i�[
                $lastGreenParentId = $null

                for ($i = 0; $i -lt $buttonCount; $i++) {
                    $button = $buttons[$i]
                    $buttonName = $button.Name
                    $buttonText = $button.Text
                    $buttonColor = $button.BackColor  # �{�^���̔w�i�F���擾

                    # �w�i�F�̏����擾�i�F���j
                    $colorName = $buttonColor.Name

                    # �{�^�������R���\�[���ɏo��
                    $buttonInfo = "�{�^����: $buttonName, �e�L�X�g: $buttonText, �F: $colorName"
                    #Write-Host $buttonInfo

                    # �{�^�����݂̂�ID�Ƃ��Ďg�p
                    $id = $buttonName

                    # �G���g�����擾
                    $�擾�����G���g�� = ID�ŃG���g�����擾 -ID $id
                    Write-Host "�擾�����G���g��:$�擾�����G���g��"
                    if ($�擾�����G���g�� -ne $null) {
                        # �G���g���̓��e���R���\�[���ɏo��
                        Write-Host "�G���g��ID: $id`n���e:`n$�擾�����G���g��`n"

                        # �G���g���̓��e�݂̂�$output�ɒǉ��i��s��ǉ��j
                        $output += "$�擾�����G���g��`n`n"
                    }
                    else {
                        # �G���g�������݂��Ȃ��ꍇ�̃��b�Z�[�W���R���\�[���ɏo��
                        #Write-Host "�G���g��ID: $id �͑��݂��܂���B`n"
                    }

                    # ���݂̃{�^����Green�̏ꍇ�AlastGreenParentId���X�V
                    if ($colorName -eq "Green") {
                        # �eID�𒊏o�i��: "76-1" -> "76"�j
                        $lastGreenParentId = ($id -split '-')[0]
                    }

                    # ���݂̃{�^����Red�ŁA���̃{�^����Blue�̏ꍇ�ɓ����ID��}��
                    if ($colorName -eq "Red" -and ($i + 1) -lt $buttonCount) {
                        $nextButton = $buttons[$i + 1]
                        $nextColorName = $nextButton.BackColor.Name

                        if ($nextColorName -eq "Blue") {
                            if ($lastGreenParentId -ne $null) {
                                # �����ID��lastGreenParentId�Ɋ�Â��Đݒ�i��: "76-2"�j
                                $specialId = "$lastGreenParentId-2"

                                # �����ID�ŃG���g�����擾
                                $specialEntry = ID�ŃG���g�����擾 -ID $specialId
                                if ($specialEntry -ne $null) {
                                    # �G���g���̓��e���R���\�[���ɏo��
                                    #Write-Host "�G���g��ID: $specialId`n���e:`n$specialEntry`n"

                                    # �G���g���̓��e�݂̂�$output�ɒǉ��i��s��ǉ��j
                                    $output += "$specialEntry`n`n"
                                }
                                else {
                                    # �G���g�������݂��Ȃ��ꍇ�̃��b�Z�[�W���R���\�[���ɏo��
                                    #Write-Host "�G���g��ID: $specialId �͑��݂��܂���B`n"
                                }
                            }
                            else {
                                # lastGreenParentId���Ȃ��ꍇ�̃��b�Z�[�W���R���\�[���ɏo��
                                #Write-Host "���߂�Green�{�^�������݂��܂���B���ʂ�ID��}���ł��܂���B`n"
                            }
                        }
                    }
                }

                # �e�L�X�g�t�@�C���̃p�X��ݒ�ips1�Ɠ����f�B���N�g���j
                $outputFilePath = Join-Path -Path $global:folderPath  -ChildPath "output.ps1"

                # �o�͂��t�@�C���ɏ�������
                try {
                    $output | Set-Content -Path $outputFilePath -Force -Encoding UTF8
                    #Write-Host "�o�͂��t�@�C���ɏ������݂܂����B�t�@�C���p�X: $outputFilePath"
                }
                catch {
                    Write-Error "�o�̓t�@�C���̏������݂Ɏ��s���܂����B"
                    return
                }

                # �e�L�X�g�t�@�C�������j�^�[1�ōő剻���ĊJ��
                try {
                    # Notepad���ő剻���ꂽ��ԂŋN��
                    #Start-Process notepad.exe -ArgumentList $outputFilePath -WindowStyle Maximized
                    #Start-Process -FilePath "powershell_ise.exe" -ArgumentList $outputFilePath -WindowStyle Maximized
                    # -NoProfile ��t���邱�ƂŐV�����v���Z�X�Ƃ��ċN��
                   Start-Process -FilePath "powershell_ise.exe" -ArgumentList $outputFilePath -NoNewWindow

                    # �C���ŃR�[�h
                   #Start-Process -FilePath "powershell_ise.exe" -ArgumentList $outputFilePath -Separate


                    #Write-Host "�e�L�X�g�t�@�C�������j�^�[1�ōő剻���ĊJ���܂����B"
                }
                catch {
                    Write-Error "�e�L�X�g�t�@�C�����J���ۂɃG���[���������܂����B"
                }
            }
            catch {
                Write-Error "�G���[���������܂���: $_"
            }
  
       # Set-ExecuteButtonClickEvent �֐��̕�������
    } 

function �ϐ��C�x���g {

            $���C���t�H�[��.Hide()
            $�X�N���v�gPath = $PSScriptRoot # ���݂̃X�N���v�g�̃f�B���N�g����ϐ��Ɋi�[
            #."$�X�N���v�gPath\20241117_�ϐ��Ǘ�UI.ps1"
            $variableName = Show-VariableManagerForm
            $���C���t�H�[��.Show()     
}

function �t�H���_�쐬�C�x���g {

            $���C���t�H�[��.Hide()
            �V�K�t�H���_�쐬
            $���C���t�H�[��.Show()
     
}

function �t�H���_�ؑփC�x���g {

            $���C���t�H�[��.Hide()
           �t�H���_�I���ƕۑ� 
            $���C���t�H�[��.Show()     
}

function Update-�������x�� {
    param (
        [string]$������
    )
    if ($������) {
        $global:�������x��.Text = $������
        #Write-Host "���������X�V: $������"
    } else {
        $global:�������x��.Text = "�����ɐ��������\������܂��B"
        #Write-Host "���������N���A"
    }
}

function �ؑփ{�^���C�x���g {
    param (
        [array]$SwitchButtons,
        [array]$SwitchTexts
    )

    for ($i = 0; $i -lt $SwitchButtons.Count; $i++) {
        $�{�^�� = $SwitchButtons[$i]
        $�{�^���e�L�X�g = $SwitchTexts[$i]
        $������ = $global:�ؑփ{�^������[$�{�^��.Text]

        # �e�{�^����Tag�v���p�e�B�ɐ�������ݒ�
        $�{�^��.Tag = $������

        # GotFocus�C�x���g
        $�{�^��.Add_GotFocus({
            param($sender, $e)
            Update-�������x�� -������ $sender.Tag
            #Write-Host "$($sender.Text) �{�^���Ƀt�H�[�J�X��������܂����B"
        })

        # LostFocus�C�x���g
        $�{�^��.Add_LostFocus({
            param($sender, $e)
            Update-�������x�� -������ $null
            #Write-Host "$($sender.Text) �{�^���̃t�H�[�J�X���O��܂����B"
        })

        # MouseEnter�C�x���g
        $�{�^��.Add_MouseEnter({
            param($sender, $e)
            Update-�������x�� -������ $sender.Tag
            #Write-Host "$($sender.Text) �{�^���Ƀ}�E�X������܂����B"
        })

        # MouseLeave�C�x���g
        $�{�^��.Add_MouseLeave({
            param($sender, $e)
            Update-�������x�� -������ $null
            #Write-Host "$($sender.Text) �{�^������}�E�X������܂����B"
        })
    }
} # Set-SwitchButtonEventHandlers �֐��̕�������

# Windows�t�H�[���𗘗p���邽�߂̕K�v�ȃA�Z���u����ǂݍ���
Add-Type -AssemblyName System.Windows.Forms

function �V�K�t�H���_�쐬 {
    # �ۑ�����X�N���v�g�̓����ꏊ�Ƃ���V�K�t�H���_�쐬�X�N���v�g

    # ���݂̃X�N���v�g�̃p�X���擾
    $�ۑ���f�B���N�g�� = $PSScriptRoot
    #Write-Host "�ۑ���f�B���N�g��: $�ۑ���f�B���N�g��"


    $�ۑ���f�B���N�g�� = $�ۑ���f�B���N�g�� + "\�X�̗���"

    # �C���v�b�g�{�b�N�X�Ńt�H���_�����擾
    $���̓t�H�[�� = New-Object Windows.Forms.Form
    $���̓t�H�[��.Text = "�t�H���_������"
    $���̓t�H�[��.Size = New-Object Drawing.Size(400,150)

    $���x�� = New-Object Windows.Forms.Label
    $���x��.Text = "�V�����t�H���_������͂��Ă�������:"
    $���x��.AutoSize = $true
    $���x��.Location = New-Object Drawing.Point(10,20)

    $�e�L�X�g�{�b�N�X = New-Object Windows.Forms.TextBox
    $�e�L�X�g�{�b�N�X.Size = New-Object Drawing.Size(350,30)
    $�e�L�X�g�{�b�N�X.Location = New-Object Drawing.Point(10,50)

    $�{�^�� = New-Object Windows.Forms.Button
    $�{�^��.Text = "�쐬"
    $�{�^��.Location = New-Object Drawing.Point(10,90)
    $�{�^��.Add_Click({$���̓t�H�[��.Close()})

    $���̓t�H�[��.Controls.Add($���x��)
    $���̓t�H�[��.Controls.Add($�e�L�X�g�{�b�N�X)
    $���̓t�H�[��.Controls.Add($�{�^��)

    $���̓t�H�[��.ShowDialog()

    $�t�H���_�� = $�e�L�X�g�{�b�N�X.Text

    if (-not $�t�H���_��) {
        #Write-Host "�t�H���_�������͂���܂���ł����B�����𒆎~���܂��B"
        return
    }

    

    # �ۑ���̃t���p�X�𐶐�
    $�t�H���_�p�X = Join-Path -Path $�ۑ���f�B���N�g�� -ChildPath $�t�H���_��

    # �V�K�t�H���_���쐬
    if (-not (Test-Path -Path $�t�H���_�p�X)) {
        New-Item -Path $�t�H���_�p�X -ItemType Directory | Out-Null
        #Write-Host "�t�H���_���쐬����܂���: $�t�H���_�p�X"
    } else {
        #Write-Host "�t�H���_�͊��ɑ��݂��Ă��܂�: $�t�H���_�p�X"
    }

    # ���C��.json �t�@�C���ɕۑ�
    $jsonFilePath = Join-Path -Path $�ۑ���f�B���N�g�� -ChildPath "���C��.json"

    # JSON�f�[�^���쐬
    $jsonData = @{}
    if (Test-Path -Path $jsonFilePath) {
        # ������JSON�t�@�C��������ꍇ�͓ǂݍ���
        $existingData = Get-Content -Path $jsonFilePath | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($existingData) {
            $jsonData = $existingData
        }
    }
    $jsonData.�t�H���_�p�X = $�t�H���_�p�X

    # JSON�t�@�C���ɏ�������
    $jsonData | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonFilePath -Encoding UTF8
    #Write-Host "�t�H���_�p�X�����C��.json�ɕۑ�����܂���: $jsonFilePath"


    $�X�N���v�gPath = $PSScriptRoot # ���݂̃X�N���v�g�̃f�B���N�g����ϐ��Ɋi�[

    # �֐��̌Ăяo����
$global:folderPath = �擾-JSON�l -jsonFilePath "$�X�N���v�gPath\�X�̗���\���C��.json" -keyName "�t�H���_�p�X"
$global:JSONPath = "$global:folderPath\variables.json"

            $outputFile = $global:JSONPath
        try {
            # �o�̓t�H���_�����݂��Ȃ��ꍇ�͍쐬
            $outputFolder = Split-Path -Parent $outputFile

            [System.Windows.Forms.MessageBox]::Show($outputFolder) 

            if (-not (Test-Path -Path $outputFolder)) {
                New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
            }

            $global:variables | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8
            [System.Windows.Forms.MessageBox]::Show("�ϐ���JSON�`���ŕۑ�����܂���: `n$outputFile") | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show("JSON�̕ۑ��Ɏ��s���܂���: $_") | Out-Null
        }

        #."C:\Users\hallo\Documents\WindowsPowerShell\chord\RPA-UI2\20241112_(���C��)�R�[�hID�Ǘ�JSON.ps1"
        JSON����
        JSON�X�g�A��������


}

# Windows�t�H�[���𗘗p���邽�߂̕K�v�ȃA�Z���u����ǂݍ���
Add-Type -AssemblyName System.Windows.Forms

# Windows�t�H�[���𗘗p���邽�߂̕K�v�ȃA�Z���u����ǂݍ���
Add-Type -AssemblyName System.Windows.Forms

function �t�H���_�I���ƕۑ� {
    # �ۑ���f�B���N�g�����擾
    $�ۑ���f�B���N�g�� = Join-Path -Path $PSScriptRoot -ChildPath "�X�̗���"
    
    if (-not (Test-Path -Path $�ۑ���f�B���N�g��)) {
        New-Item -Path $�ۑ���f�B���N�g�� -ItemType Directory | Out-Null
    }
    
    # �ۑ���f�B���N�g�����̃t�H���_�ꗗ���擾
    $�t�H���_�ꗗ = Get-ChildItem -Path $�ۑ���f�B���N�g�� -Directory | Select-Object -ExpandProperty Name

    # �t�H�[���쐬
    $���̓t�H�[�� = New-Object Windows.Forms.Form
    $���̓t�H�[��.Text = "�t�H���_�I��"
    $���̓t�H�[��.Size = New-Object Drawing.Size(400,300)
    
    $���x�� = New-Object Windows.Forms.Label
    $���x��.Text = "�t�H���_��I�����Ă�������:"
    $���x��.AutoSize = $true
    $���x��.Location = New-Object Drawing.Point(10,10)

    $���X�g�{�b�N�X = New-Object Windows.Forms.ListBox
    $���X�g�{�b�N�X.Size = New-Object Drawing.Size(350,200)
    $���X�g�{�b�N�X.Location = New-Object Drawing.Point(10,40)
    $���X�g�{�b�N�X.Items.AddRange($�t�H���_�ꗗ)
    
    $�{�^�� = New-Object Windows.Forms.Button
    $�{�^��.Text = "�ۑ�"
    $�{�^��.Location = New-Object Drawing.Point(10,250)
    $�{�^��.Add_Click({
        if ($���X�g�{�b�N�X.SelectedItem) {
            $global:�I���t�H���_ = $���X�g�{�b�N�X.SelectedItem
            $���̓t�H�[��.Close()
        } else {
            [System.Windows.Forms.MessageBox]::Show("�t�H���_��I�����Ă��������B", "�G���[", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    })
    
    $���̓t�H�[��.Controls.Add($���x��)
    $���̓t�H�[��.Controls.Add($���X�g�{�b�N�X)
    $���̓t�H�[��.Controls.Add($�{�^��)

    # �t�H�[����\��
    $���̓t�H�[��.ShowDialog()

    if (-not $global:�I���t�H���_) {
        #Write-Host "�t�H���_���I������܂���ł����B�����𒆎~���܂��B"
        return
    }

    # �t�H���_�p�X���擾
    $�I���t�H���_�p�X = Join-Path -Path $�ۑ���f�B���N�g�� -ChildPath $global:�I���t�H���_

    # JSON�t�@�C���ւ̕ۑ�
    $jsonFilePath = Join-Path -Path $�ۑ���f�B���N�g�� -ChildPath "���C��.json"

    # JSON�f�[�^���쐬
    $jsonData = @{ �t�H���_�p�X = $�I���t�H���_�p�X }
    if (Test-Path -Path $jsonFilePath) {
        $existingData = Get-Content -Path $jsonFilePath | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($existingData) {
            $existingData.�t�H���_�p�X = $�I���t�H���_�p�X
            $jsonData = $existingData
        }
    }

    # JSON�t�@�C���ɏ�������
    $jsonData | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonFilePath -Encoding UTF8
    #Write-Host "�I�����ꂽ�t�H���_�p�X�����C��.json�ɕۑ�����܂���: $�I���t�H���_�p�X"

    # �֐��̌Ăяo����
    $�X�N���v�gPath = $PSScriptRoot # ���݂̃X�N���v�g�̃f�B���N�g����ϐ��Ɋi�[
    $global:folderPath = �擾-JSON�l -jsonFilePath "$�X�N���v�gPath\�X�̗���\���C��.json" -keyName "�t�H���_�p�X"
    $global:JSONPath = "$global:folderPath\variables.json"
}

function �쐬�{�^���ƃC�x���g�ݒ� {
    param (
        [string]$�����ԍ�,
        [string]$�e�L�X�g,
        [string]$�{�^����,
        [System.Drawing.Color]$�w�i�F,
        [object]$�R���e�i,
        [string]$����  # �V�����ǉ�
    )
    
#
    # �V�����{�^�����쐬
    $�V�����{�^�� = 00_�ėp�F�{�^�����쐬���� -�R���e�i $�R���e�i -�e�L�X�g $�e�L�X�g -�{�^���� $�{�^���� -�� 160 -���� 30 -X�ʒu 10 -Y�ʒu $Y�ʒu -�w�i�F $�w�i�F

    
$�V�����{�^��.Tag = @{
�����ԍ� = $�����ԍ�
���� = $����
  } 



    # �N���b�N�C�x���g��ݒ�i�K�v�ɉ����ĕێ��j
    00_�ėp�F�{�^���̃N���b�N�C�x���g��ݒ肷�� -�{�^�� $�V�����{�^�� -�����ԍ� $�����ԍ�


    # ���������n�b�V���e�[�u���ɒǉ�
    $global:�쐬�{�^������[$�����ԍ�] = $����
    #Write-Host "�쐬�{�^�������ǉ�: �����ԍ�=$�����ԍ�, ����=$����"

    # MouseEnter �C�x���g��ݒ�
    $�V�����{�^��.Add_MouseEnter({
        param($sender, $eventArgs)
        #Write-Host "MouseEnter �C�x���g����: sender=$sender, Text=$($sender.Text)"
        

                $global:�������x��.Text = $����
                   $tag = $sender.Tag
           $�����ԍ� = $tag.�����ԍ�
             $���� = $tag.����

        if ($null -eq $�����ԍ�) {
            #Write-Host "Error: �����ԍ��� null �ł��B"
        }

        if ($global:�쐬�{�^������.ContainsKey($�����ԍ�)) {
            #Write-Host "��������ݒ�: $($global:�쐬�{�^������[$�����ԍ�])"
            $global:�������x��.Text = $global:�쐬�{�^������[$�����ԍ�]
        } else {
            #Write-Host "��������������܂���: �����ԍ�=$�����ԍ�"
            $global:�������x��.Text = "���̃{�^���ɂ͐������ݒ肳��Ă��܂���B"
        }
    })



    # MouseLeave �C�x���g��ݒ�
    $�V�����{�^��.Add_MouseLeave({
        #Write-Host "MouseLeave �C�x���g����: �������x�����N���A"
        $global:�������x��.Text = ""
    })

    # GotFocus �C�x���g��ݒ�
    $�V�����{�^��.Add_GotFocus({
        param($sender, $eventArgs)
        #Write-Host "GotFocus �C�x���g����: sender=$sender, Text=$($sender.Text)"
        
        $global:�������x��.Text = $����
                   $tag = $sender.Tag
           $�����ԍ� = $tag.�����ԍ�
             $���� = $tag.����


        if ($null -eq $�����ԍ�) {
            #Write-Host "Error: �����ԍ��� null �ł��B"
        }

        if ($global:�쐬�{�^������.ContainsKey($�����ԍ�)) {
            #Write-Host "��������ݒ�: $($global:�쐬�{�^������[$�����ԍ�])"
            #$global:�������x��.Text = $global:�쐬�{�^������[$�����ԍ�]
            $global:�������x��.Text = $����
        } else {
            #Write-Host "��������������܂���: �����ԍ�=$�����ԍ�"
            $global:�������x��.Text = $����
            #$global:�������x��.Text = "���̃{�^���ɂ͐������ݒ肳��Ă��܂���B"
        }
    })

    # LostFocus �C�x���g��ݒ�
    $�V�����{�^��.Add_LostFocus({
        #Write-Host "LostFocus �C�x���g����: �������x�����N���A"
        $global:�������x��.Text = ""
    })
}
