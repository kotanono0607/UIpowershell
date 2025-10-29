# Invoke-MouseGet �֐��̒�`
function Invoke-MouseGet {
    param(
        [string]$Caller  # �Ăяo�����̖��O���󂯎��p�����[�^
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # �O���[�o���ϐ���������
    $global:MouseClickResult = ""

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "�N���b�N���č��W���擾"
    $form.WindowState = 'Maximized'
    $form.TopMost = $true
    $form.Opacity = 0.1  # �f�o�b�O�p�ɓ����x��ݒ�

    # �}�E�X�N���b�N�C�x���g�̐ݒ�
    $form.Add_MouseClick({
        $pos = [System.Windows.Forms.Cursor]::Position
        $x = $pos.X
        $y = $pos.Y
        Write-Host "�}�E�X���N���b�N����܂����BX=$x, Y=$y"

        # �Ăяo�����ɂ���ăe�L�X�g��ω�������
        if ($Caller -eq "Addon1") {
            $global:MouseClickResult = "�w����W�����N���b�N -X���W $x -Y���W $y"
        } elseif ($Caller -eq "Addon2") {
            $global:MouseClickResult = "�w����W�Ɉړ� -X���W $x -Y���W $y"
        } else {
            $global:MouseClickResult = "�w����W�����N���b�N -X���W $x -Y���W $y"
        }

        # �t�H�[�������
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    })

    # �t�H�[�������[�_���ŕ\��
    $form.ShowDialog() | Out-Null

    # ���ʂ�Ԃ��i�O���[�o���ϐ��ɐݒ�ς݁j
    return $global:MouseClickResult
}
