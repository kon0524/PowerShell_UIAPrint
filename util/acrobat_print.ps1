Import-Module "..\UIAutomation\UIAutomation.dll"

# ACROBAT���J�n���A����ݒ�_�C�A���O�𗧂��グ��
# $FILEPATH				[in]	PDF�t�@�C���ւ̃p�X
# $DRVNAME				[in]	�h���C�o���i�v�����^�A�C�R�����j
# result_process		[out]	Acrobat��Process�I�u�W�F�N�g���擾
# result_window			[out]	Acrobat�̃��C���E�B���h�E��Window�I�u�W�F�N�g���擾
# result_app_dialog		[out]	Acrobat�̈���ݒ�_�C�A���O��Window�I�u�W�F�N�g���擾
# result_dialog			[out]	�h���C�o�̈���ݒ�_�C�A���O��Window�I�u�W�F�N�g���擾
function ACROBAT_Start($FILEPATH, $DRVNAME, [ref]$result_process, [ref]$result_window, [ref]$result_app_dialog, [ref]$result_dialog){

	# �g���qpdf�̊֘A�A�v���P�[�V�����̃p�X���擾
	$assoc_val = cmd /c assoc .pdf
	$assoc_command = cmd /c ftype $assoc_val.Split("=")[1]
	$app_path = $assoc_command.Split('"*"')[1]
	if ($app_path -notmatch "AcroRd32.EXE\s*$"){
		Write-Warning -Message "�g���q'pdf'��'AcroRd32.EXE'���֘A�����Ă��܂���" 
		return $False
	}

	# �t�@�C���̃p�X�̊m�F
	if ( -not (Test-Path $FILEPATH)){
		Write-Warning -Message "$FILEPATH��������܂���"
		return $False
	}

	# pdf�̃A�v���P�[�V�����iAcrobat�j���N��
	Write-Verbose -Message"'$FILEPATH'���N������"
	$app_process = Start-Process -FilePath $app_path -PassThru -ArgumentList $FILEPATH
	if ($app_process -eq $null){
		Write-Warning -Message "Acrobat��Process���擾�ł��܂���"
		return $False
	}
	$result_process.value = $app_process

	# �ő�10�b�ҋ@
	if (!$app_process.WaitForInputIdle(10000)) {
		Write-Warning -Message "���͉\��ԑ҂��^�C���A�E�g"
		return $False
	}
	Start-Sleep -Millisecond 200
	
	# Acrobat�̓v���Z�X��2�N�����A2�ڂ�Window�������߁A�q�v���Z�X���擾����
	try {
		$app_process = Get-Process -pid (Get-WmiObject -Class Win32_Process | Where {$_.ParentProcessId -eq $app_process.Id}).ProcessId
	} catch {
		return $False
	}
	$result_process.value = $app_process

	# ���̂������オ��_�C�A���O�����i���܂ɃV���[�g�J�b�g�L�[���t�b�N����Ďז������̂Łj
	try{
		$app_process.WaitForInputIdle(10000) >$null
		$temp = Get-UiaWindow -ProcessId $app_process.Id -Title '�^�O�t������Ă��Ȃ������̓ǂݏグ*'
		$temp.Close()
	} catch {}

	# Acrobat�̃��C���E�B���h�E�擾�i
	$window = Get-UiaWindow -ProcessId $app_process.Id
	if ($window -eq $null){
		Write-Warning -Message "Acrobat��Window���擾�ł��܂���"
		return $False
	}
	$result_window.value = $window

	# �ő�10�b�ҋ@
	if (!$app_process.WaitForInputIdle(10000)) {
		Write-Warning -Message "���͉\��ԑ҂��^�C���A�E�g"
		return $False
	}

	# Ctrl+P�ň�����j���[�ɃW�����v
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyDown([WindowsInput.Native.VirtualKeyCode]::CONTROL) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_P) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyUp([WindowsInput.Native.VirtualKeyCode]::CONTROL) >$null

	# Acrobat�̈���_�C�A���O
	Start-Sleep -Millisecond 200
	$acro_dialog = Get-UiaWindow -Class '#32770' -Name '���'
	if($acro_dialog -eq $null){
		Write-Warning -Message "Acrobat�̈���_�C�A���O���擾�ł��܂���"
		return $False
	}
	$result_app_dialog.value = $acro_dialog
	
  	# �v�����^�[�̑I���R���{�{�b�N�X�̎擾 (�Ȃ����R���{�{�b�N�X��������)
	$combobox = Get-UiaComboBox -InputObject $acro_dialog -Class 'ComboBox' -Name '����(C) :'
	if ($combobox -eq $null){
 		Write-Warning -Message "�v�����^�[�ݒ肪������Ȃ��B�����𒆒f����"
 		return $False
	}
	if ($combobox.Value -ne $DRVNAME) {
		Write-Verbose -Message"�Ώۂ̃v�����^�ɕύX: $DRVNAME"
		try{
			($combobox | Invoke-UiaComboBoxExpand | Get-UiaListItem -Name $DRVNAME -ErrorAction Stop | Invoke-UiaListItemClick) >$null
		} catch {
	 		Write-Warning -Message "�Ώۂ̃v�����^�[����������Ȃ��B�����𒆒f����"
	 		return $False
		}
	}


	# ����ݒ�_�C�A���O���N������(Alt+p)
	Write-Verbose -Message"����ݒ�_�C�A���O���N������"
	Start-Sleep -Millisecond 200
	$acro_dialog.Keyboard.KeyDown([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	Start-Sleep -Millisecond 200
	$acro_dialog.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_P) >$null
	Start-Sleep -Millisecond 200
	$acro_dialog.Keyboard.KeyUp([WindowsInput.Native.VirtualKeyCode]::MENU) >$null

	# ����ݒ�_�C�A���O�̎擾
	Start-Sleep -Millisecond 200
	try{
		($print_dialog = Get-UiaWindow -Name "���" -ErrorAction Stop) >$null
	} catch {
		Write-Warning -Message "����ݒ�_�C�A���O���擾�ł��܂���B�����𒆒f���܂�"
		return $False
	}
	$result_dialog.value = $print_dialog
	return $True
}


# ����{�^������������i����_�C�A���O���J���Ă����ԂŎg�p���邱�Ɓj
# $window		[in]	Acrobat�̃��C���E�B���h�E��Window�I�u�W�F�N�g
# $app_dialog	[in]	Acrobat�̈���_�C�A���O��Window�I�u�W�F�N�g
function ACROBAT_Print($window, $app_dialog){
	if ($window -eq $null){
		return
	}
	if ($app_dialog -eq $null){
		return
	}
	
	# ����{�^��������
	Start-Sleep -Millisecond 200
	try{
		$app_dialog | Get-UiaButton -Class 'Button' -Name '���' | Invoke-UiaButtonClick > $null
	} catch {
		Write-Warning -Message "����{�^�����擾�ł��܂���B�����𒆒f���܂�"
		return
	}

	# ����_�C�A���O���o������܂ł̃E�G�C�g
	Start-Sleep -Millisecond 5000

	# ����_�C�A���O�N���[�Y�҂�
	Write-Verbose -Message"����_�C�A���O�N���[�Y�҂�"
	do{
		Start-Sleep -Millisecond 200
	}while($window.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::ReadyForUserInteraction)
	Write-Verbose -Message"����_�C�A���O�N���[�Y�҂��I��"
}


# �E�B���h�E���I������
function ACROBAT_Exit($window){
	if ($window -eq $null){
		return
	}

	# �A�v���P�[�V���������(Alt+F4)
	Write-Verbose -Message"�A�v���P�[�V���������"
	Start-Sleep -Millisecond 200
	$window.Close()
	#$window.Keyboard.KeyDown([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	#Start-Sleep -Millisecond 200
	#$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::F4) >$null
	#Start-Sleep -Millisecond 200
	#$window.Keyboard.KeyUp([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
}

# �A�v���P�[�V�����������I������
# process		[in]	Acrobat��Process�I�u�W�F�N�g���擾
# window		[in]	Acrobat�̃��C���E�B���h�E��Window�I�u�W�F�N�g���擾
# app_dialog	[in]	Acrobat�̈���ݒ�_�C�A���O��Window�I�u�W�F�N�g���擾
# dialog		[in]	�h���C�o�̈���ݒ�_�C�A���O��Window�I�u�W�F�N�g���擾
function ACROBAT_Abort($process, $window, $app_dialog, $dialog){
	New-Variable tmp_process
	try{
		($tmp_process = Get-Process -Id $process.id -ErrorAction SilentlyContinue) >$null
	} catch {
		return
	}
	if($tmp_process -eq $null){
		return
	}

	if( ($dialog -ne $null) -and ($dialog.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing) ){
		Write-Verbose -Message"�_�C�A���O�����"
		do{
			($dialog.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::ESCAPE)) >$null
			Start-Sleep -Millisecond 200
		}while($dialog.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing)

		Write-Verbose -Message"�A�v���P�[�V�����̈���_�C�A���O�����"
		do{
			($app_dialog.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::ESCAPE)) >$null
			Start-Sleep -Millisecond 200
		}while($app_dialog.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing)
		
		ACROBAT_Exit($window)
	}
	elseif( ($app_dialog -ne $null) -and ($app_dialog.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing) ){
		Write-Verbose -Message"�A�v���P�[�V�����̈���_�C�A���O�����"
		do{
			($app_dialog.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::ESCAPE)) >$null
			Start-Sleep -Millisecond 200
		}while($app_dialog.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing)

		ACROBAT_Exit($window)
	}
	elseif($window -ne $null -and $window.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing){
		ACROBAT_Exit($window)
	}
	else{
		$tmp_process.Kill()
	}

	# ������f�_�C�A���O������̂�҂�
	if($process.WaitForExit(30000)){
		return
	}

	$tmp_process.Kill()
	$process.WaitForExit()
}
