Import-Module "..\UIAutomation\UIAutomation.dll"

# WINWORD���J�n���A����ݒ�_�C�A���O�𗧂��グ��
# $FILEPATH			[in]	DOCX�t�@�C���ւ̃p�X
# $DRVNAME			[in]	�h���C�o���i�v�����^�A�C�R�����j
# result_process	[out]	WINWORD��Process�I�u�W�F�N�g���擾
# result_window		[out]	WINWORD�̃��C���E�B���h�E��Window�I�u�W�F�N�g���擾
# result_dialog		[out]	WINWORD�̈���ݒ�_�C�A���O��Window�I�u�W�F�N�g���擾
function WINWORD_Start($FILEPATH, $DRVNAME, [ref]$result_process, [ref]$result_window, [ref]$result_dialog){

	Write-Verbose -Message"'Word'���N������"

	# �g���qdocx�̊֘A�A�v���P�[�V�����̃p�X���擾
	$assoc_val = cmd /c assoc .docx
	$assoc_command = cmd /c ftype $assoc_val.Split("=")[1]
	$app_path = $assoc_command.Split('"*"')[1]
	if ($app_path -notmatch "WINWORD.EXE\s*$"){
		Write-Warning -Message "�g���q'docx'��'WINWORD.EXE'���֘A�����Ă��܂���"
		return $False
	}

	# �t�@�C���̃p�X�̊m�F
	if ( -not (Test-Path $FILEPATH)){
		Write-Warning -Message "$FILEPATH��������܂���"
		return $False
	}

	# docx�̃A�v���P�[�V�����iWORD�j���N��
	Write-Verbose -Message"'$FILEPATH'���N������"
	$app_process = Start-Process -FilePath $app_path -PassThru -ArgumentList "/q", $FILEPATH
	if ($app_process -eq $null){
		Write-Warning -Message "Word���N���ł��܂���ł���"
		return $False
	}
	$result_process.value = $app_process
	
	# �ő�10�b�ҋ@
	if (!$app_process.WaitForInputIdle(10000)) {
		Write-Warning -Message "���͉\��ԑ҂��^�C���A�E�g"
		return $False
	}

	# ���C���E�B���h�E���擾
	$window = Get-UIAWindow -Class 'OpusApp' -ProcessId $app_process.Id
	if ($window -eq $null){
		Write-Warning -Message "Window���擾�ł��Ȃ��B�����𒆒f����"
		return $False
	}

	# �ی샂�[�h������
	Write-Verbose -Message"�ی샂�[�h������"
	try {
		($window | Get-UiaButton -Class 'NetUISimpleButton' -Name '�ҏW��L���ɂ���(E)' -ErrorAction Stop | Invoke-UiaButtonClick) >$null
	} catch {}

	# Ctrl+P�ň�����j���[�ɃW�����v
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyDown([WindowsInput.Native.VirtualKeyCode]::CONTROL) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_P) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyUp([WindowsInput.Native.VirtualKeyCode]::CONTROL) >$null
	Start-Sleep -Millisecond 200

	# ���C���E�B���h�E���擾
	$window = Get-UiaWindow  -Class 'OpusApp' -ProcessId $app_process.Id
	if ($window -eq $null){
		Write-Warning -Message "Window���擾�ł��Ȃ��B�����𒆒f����"
		return $False
	}
	$result_window.value = $window
	
	# ����^�u���擾
	$tab = $window | Get-UiaGroup -Class 'NetUISlabContainer' -Name '���'
	if ($tab -eq $null){
		Write-Warning -Message "����^�u���擾�ł��Ȃ��B�����𒆒f����"
		return $False
	}

	# �Ώۂ̃v�����^�h���C�o��I��
	Write-Verbose -Message"�Ώۂ̃v�����^�h���C�o��I��"
	$group = $tab | Get-UiaGroup -Class 'NetUIElement' -Name '�v�����^�['
	$combobox = $group | Get-UiaComboBox -Class 'NetUIDropdownAnchor' -Name '�g�p����v�����^�['
	if ($combobox.Value -ne $DRVNAME) {
		Write-Verbose -Message"�Ώۂ̃v�����^�ɕύX: $DRVNAME"
		try{
			$combobox | Invoke-UiaComboBoxExpand | Get-UiaListItem -Name $DRVNAME -ErrorAction Stop | Invoke-UiaListItemClick
		} catch {
	 		Write-Warning -Message "�Ώۂ̃v�����^�[����������Ȃ��B�����𒆒f����"
	 		return $False
		}
	}

	# ����ݒ�_�C�A���O���N������(Alt+p,r)
	Write-Verbose -Message"����ݒ�_�C�A���O���N������"
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_P) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_R) >$null
	Start-Sleep -Millisecond 200
	

	# ����ݒ�_�C�A���O�̎擾
	try{
		($print_dialog = $window | Get-UiaChildWindow -Name "$DRVNAME*" -ErrorAction Stop) >$null
	} catch {
		Write-Warning -Message "����ݒ�_�C�A���O���擾�ł��܂���B�����𒆒f���܂�"
		return $False
	}
	$result_dialog.value = $print_dialog
	return $True
}


# ����{�^������������i����^�u���J���Ă����ԂŎg�p���邱�Ɓj
# $window	[in]	WINWORD�̃��C���E�B���h�E��Window�I�u�W�F�N�g
function WINWORD_Print($window){
	if ($window -eq $null){
		return $False
	}
	
	# ����{�^��������(Alt+p,p)
	$window.Keyboard.KeyDown([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_P) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_P) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyUp([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	
	# ����{�^��������̑҂�
	if (!$window.WaitForInputIdle(10000)) {
		Write-Warning -Message "����{�^��������̓��͉\��ԑ҂��^�C���A�E�g"
	}
	return $True
}


# �E�B���h�E���I������
# $window	[in]	WINWORD�̃��C���E�B���h�E��Window�I�u�W�F�N�g
function WINWORD_Exit($window){
	if ($window -eq $null){
		return
	}
	
	# ���͉\��ԑ҂�
	$window.WaitForInputIdle(10000) > $null
	
	# �A�v���P�[�V���������(Ctrl+F4)
	Write-Verbose -Message"�A�v���P�[�V���������"
	$window.Keyboard.KeyDown([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::F4) >$null
	$window.Keyboard.KeyUp([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
}


# WINWORD�������I������
# $process	[in]	WINWORD��Process�I�u�W�F�N�g
# $window	[in]	WINWORD�̃��C���E�B���h�E��Window�I�u�W�F�N�g
# $dialog	[in]	WINWORD�̈���ݒ�_�C�A���O��Window�I�u�W�F�N�g
function WINWORD_Abort($process, $window, $dialog){
	Write-Verbose -Message"�����𒆒f���A�A�v���P�[�V���������"
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

		WINWORD_Exit($window)
	}
	elseif($window -ne $null -and $window.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing){
		WINWORD_Exit($window)
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
