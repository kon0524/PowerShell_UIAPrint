add-type -AssemblyName microsoft.VisualBasic

# MSPAINT���J�n���A����ݒ�_�C�A���O�𗧂��グ��
# $FILEPATH			[in]	XLSX�t�@�C���ւ̃p�X
# $DRVNAME			[in]	�h���C�o���i�v�����^�A�C�R�����j
# result_process	[out]	MSPAINT��Process�I�u�W�F�N�g���擾
# result_window		[out]	MSPAINT�̃��C���E�B���h�E��Window�I�u�W�F�N�g���擾
# result_dialog		[out]	MSPAINT�̈���_�C�A���O��Window�I�u�W�F�N�g���擾
# result_dialog		[out]	�h���C�o����ݒ�_�C�A���O��Window�I�u�W�F�N�g���擾
function MSPAINT_Start($FILEPATH, $DRVNAME, [ref]$result_process, [ref]$result_window, [ref]$result_app_dialog, [ref]$result_dialog){

	Write-Verbose -Message"'MSPAINT'���N������"

	# �A�v���P�[�V�����̃p�X���擾
	#$app_path = [System.Environment]::ExpandEnvironmentVariables("%systemroot%\system32\mspaint.exe")
	$app_path = "mspaint.exe"

	# �t�@�C���̃p�X�̊m�F
	if ( -not (Test-Path $FILEPATH)){
		Write-Warning -Message "$FILEPATH��������܂���"
		return $False
	}

	# �A�v���P�[�V�����iMSPAINT�j���N��
	Write-Verbose -Message"'$FILEPATH'���N������"
	$app_process = Start-Process -FilePath $app_path -PassThru -ArgumentList $FILEPATH
	if ($app_process -eq $null){
		return $False
	}
	$result_process.value = $app_process
	
	# �ő�10�b�ҋ@
	if ($False -eq $app_process.WaitForInputIdle(10000)) {
		Write-Warning -Message "���͉\��ԑ҂��^�C���A�E�g"
		return $False
	}
	
	# mainWindow�̎擾
	$window = Get-UIAWindow -Class 'MSPaintApp' -ProcessId $app_process.Id
	if ($window -eq $null){
		Write-Warning -Message "Window���擾�ł��Ȃ��B�����𒆒f����"
		return $False
	}
	$result_window.value = $window

	# Ctrl+P�ň�����j���[�ɃW�����v
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyDown([WindowsInput.Native.VirtualKeyCode]::CONTROL) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_P) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyUp([WindowsInput.Native.VirtualKeyCode]::CONTROL) >$null
	Start-Sleep -Millisecond 200
	
	# �ő�10�b�ҋ@
	if ($False -eq $app_process.WaitForInputIdle(30000)) {
		Write-Warning -Message "���͉\��ԑ҂��^�C���A�E�g"
		return $False
	}

	# ����_�C�A���O���擾
	$dialog = Get-UiaChildWindow -InputObject $window -Class '#32770'
	if ($dialog -eq $null){
		Write-Warning -Message "����_�C�A���O��������Ȃ��B�����𒆒f����" >$null
		return $False
	}
	$result_app_dialog.value = $dialog
	
	# �Ώۂ̃v�����^�h���C�o��I��
	Write-Verbose -Message"�Ώۂ̃v�����^�h���C�o��I��"
	$list = Get-UiaList -InputObject $dialog -Name '�v�����^�[�̑I��'
	$selected_listitem = Get-UiaListSelection -InputObject $list
	if ($selected_listitem.Value -ne $DRVNAME){
		try{
			(Get-UiaListItem -InputObject $list -Name $DRVNAME -ErrorAction Stop| Invoke-UiaListItemSelectItem) >$null
		}catch{
			Write-Warning -Message "�Ώۂ̃v�����^�[����������Ȃ��B�����𒆒f����" >$null
			return $False
		}
	}

	# ����ݒ�_�C�A���O���N������(Alt+r)
	Write-Verbose -Message"����ݒ�_�C�A���O���N������"
	Start-Sleep -Millisecond 200
	$dialog.Keyboard.KeyDown([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	$dialog.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_R) >$null
	$dialog.Keyboard.KeyUp([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	Start-Sleep -Millisecond 200
	

	# ����ݒ�_�C�A���O�̎擾
	try{
		($driver_dialog = (Get-UiaChildWindow -InputObject $dialog -Regex -Name '����ݒ�' -ErrorAction Stop)) >$null
	} catch {
		Write-Warning -Message "����ݒ�_�C�A���O���擾�ł��܂���B�����𒆒f���܂�"
		return $False
	}
	if ($driver_dialog -eq $null){
		Write-Warning -Message "����ݒ�_�C�A���O���擾�ł��܂���B�����𒆒f���܂�"
		return $False
	}
	$result_dialog.value = $driver_dialog

	return $True
}


# ����{�^������������i����^�u���J���Ă����ԂŎg�p���邱�Ɓj
# $window		[in]	MSPAINT�̃��C���E�B���h�E��Window�I�u�W�F�N�g
# $app_dialog	[in]	MSPAINT�̈���_�C�A���O�I�u�W�F�N�g
function MSPAINT_Print($window, $app_dialog){
	if ($app_dialog -eq $null){
		return
	}
	
	# ����{�^��������(Alt+p)
	Start-Sleep -Millisecond 200
	$app_dialog.Keyboard.KeyDown([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	$app_dialog.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_P) >$null
	$app_dialog.Keyboard.KeyUp([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	Start-Sleep -Millisecond 200
	
	# ������_�C�A���O���o������܂ł̃E�G�C�g
	Start-Sleep -Millisecond 5000

	# ������_�C�A���O�̃N���[�Y�҂�
	Write-Verbose -Message"������_�C�A���O�N���[�Y�҂�"
	do{
		Start-Sleep -Millisecond 200
	}while($window.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::ReadyForUserInteraction)
	Write-Verbose -Message"������_�C�A���O�N���[�Y�҂��I��"
}


# �E�B���h�E���I������
# $window	[in]	MSPAINT�̃��C���E�B���h�E��Window�I�u�W�F�N�g
function MSPAINT_Exit($window){
	if ($window -eq $null){
		return
	}
	
	# �A�v���P�[�V���������(Ctrl+F4)
	Write-Verbose -Message"�A�v���P�[�V���������"
	$window.Close()

	# �ۑ��_�C�A���O�����オ��҂�
	Start-Sleep -Millisecond 200
	($window.WaitForInputIdle(3000)) >$null
	
	# �ۑ��_�C�A���O�̊m�F�i�擾�ł��Ȃ������疳���j
	if ($window.WindowInteractionState -eq [System.Windows.Automation.WindowInteractionState]::BlockedByModalWindow){
		($cw = Get-UiaChildWindow -InputObject $window -Class 'NUIDialog' -ErrorAction SilentlyContinue) >$null
		if($cw -ne $null){
			# �ۑ����Ȃ�
			[Microsoft.VisualBasic.Interaction]::AppActivate($window.Current.ProcessId)
			$cw.Keyboard.KeyDown([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
			$cw.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_N) >$null
			$cw.Keyboard.KeyUp([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
		}
	}
}


# MSPAINT�������I������
# $process	[in]	MSPAINT��Process�I�u�W�F�N�g
# $window	[in]	MSPAINT�̃��C���E�B���h�E��Window�I�u�W�F�N�g
# $dialog	[in]	MSPAINT�̈���ݒ�_�C�A���O��Window�I�u�W�F�N�g
function MSPAINT_Abort($process, $window, $app_dialog, $dialog){
	New-Variable tmp_process
	
	# Process���L�����m�F�i�Ď擾�j
	try{
		($tmp_process = Get-Process -Id $process.id -ErrorAction SilentlyContinue) >$null
	} catch {
		return
	}
	if($tmp_process -eq $null){
		return
	}

	# �_�C�A���O���N�����̏ꍇ
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

		MSPAINT_Exit($window)
	}
	# MSPAINT�̈���_�C�A���O���N�����̏ꍇ
	elseif( ($app_dialog -ne $null) -and ($app_dialog.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing) ){
		Write-Verbose -Message"�A�v���P�[�V�����̈���_�C�A���O�����"
		do{
			($app_dialog.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::ESCAPE)) >$null
			Start-Sleep -Millisecond 200
		}while($app_dialog.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing)

		MSPAINT_Exit($window)
	}
	# MSPAINT�E�B���h�E���N�����̏ꍇ
	elseif($window -ne $null -and $window.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing){
		MSPAINT_Exit($window)
	}
	else{
		# �ُ펖�ԂȂ̂ŏI��������
		$tmp_process.Kill()
	}

	# �v���Z�X�I���҂��iWindow��_�C�A���O�𐳏탋�[�g�ŏI���j
	if ($process.WaitForExit(60000)){
		return
	}

	# �v���Z�X�������I���i���탋�[�g�ŏI�����Ȃ��ꍇ�j
	$tmp_process.Kill()
	$process.WaitForExit()
}
