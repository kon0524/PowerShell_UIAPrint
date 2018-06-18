Import-Module "..\UIAutomation\UIAutomation.dll"
add-type -AssemblyName microsoft.VisualBasic

# EXCEL���J�n���A����ݒ�_�C�A���O�𗧂��グ��
# $FILEPATH			[in]	XLSX�t�@�C���ւ̃p�X
# $DRVNAME			[in]	�h���C�o���i�v�����^�A�C�R�����j
# result_process	[out]	EXCEL��Process�I�u�W�F�N�g���擾
# result_window		[out]	EXCEL�̃��C���E�B���h�E��Window�I�u�W�F�N�g���擾
# result_dialog		[out]	EXCEL�̈���ݒ�_�C�A���O��Window�I�u�W�F�N�g���擾
function EXCEL_Start($FILEPATH, $DRVNAME, [ref]$result_process, [ref]$result_window, [ref]$result_dialog){

	Write-Verbose -Message"'Excel'���N������"

	# �g���qdocx�̊֘A�A�v���P�[�V�����̃p�X���擾
	$assoc_val = cmd /c assoc .xlsx
	$assoc_command = cmd /c ftype $assoc_val.Split("=")[1]
	$app_path = $assoc_command.Split('"*"')[1]
	if ($app_path -notmatch "EXCEL.EXE\s*$"){
		Write-Warning -Message "�g���q'xlsx'��'EXCEL.EXE'���֘A�����Ă��܂���"
		return $False
	}

	# �t�@�C���̃p�X�̊m�F
	if ( -not (Test-Path $FILEPATH)){
		Write-Warning -Message "$FILEPATH��������܂���"
		return $False
	}

	# �A�v���P�[�V�����iEXCEL�j���N��
	Write-Verbose -Message"'$FILEPATH'���N������"
	$app_process = Start-Process -FilePath $app_path -PassThru -ArgumentList "/e", "/r", $FILEPATH
	$result_process.value = $app_process
	
	# �ő�10�b�ҋ@
	if ($False -eq $app_process.WaitForInputIdle(10000)) {
		Write-Warning -Message "���͉\��ԑ҂��^�C���A�E�g"
		return $False
	}
	
	# mainWindow�̎擾
	$window = Get-UIAWindow -Class 'XLMAIN' -ProcessId $app_process.Id
	if ($window -eq $null){
		Write-Warning -Message "Window���擾�ł��Ȃ��B�����𒆒f����"
		return $False
	}

	# �ی샂�[�h������
	Write-Verbose -Message"�ی샂�[�h������"
	try{
		$protect_button = Get-UiaButton -InputObject $window -Class 'NetUISimpleButton' -Name '�ҏW��L���ɂ���(E)' -ErrorAction Stop
		if ($protect_button -ne $null){
			try {
				$protect_button | Invoke-UiaButtonClick
			} catch {}
			
			# �ی샂�[�h���������Window����蒼�����߁AWindow���Ď擾
			Start-Sleep -Millisecond 200
			$window = Get-UiaWindow -Class 'XLMAIN' -ProcessId $app_process.Id
			if ($window -eq $null){
				Write-Warning -Message "Window���擾�ł��Ȃ��B�����𒆒f����"
				return $False
			}
		}
	} catch {}

	# �ő�10�b�ҋ@
	if ($False -eq $window.WaitForInputIdle(30000)) {
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
	Start-Sleep -Millisecond 200

	# ����^�u���擾
	$window = Get-UiaWindow  -Class 'XLMAIN' -ProcessId $app_process.Id
	if ($window -eq $null){
		Write-Warning -Message "Window���擾�ł��Ȃ��B�����𒆒f����"
		return ��False
	}
	$result_window.value = $window

	# �Ώۂ̃v�����^�h���C�o��I��
	Write-Verbose -Message"�Ώۂ̃v�����^�h���C�o��I��"
	$tab = $window | Get-UiaGroup -Class 'NetUISlabContainer' -Name '���'
	$group = $tab | Get-UiaGroup -Class 'NetUIElement' -Name '�v�����^�['
	$combobox = $group | Get-UiaComboBox -Class 'NetUIDropdownAnchor' -Name '�g�p����v�����^�['
	if ($combobox.Value -ne $TARGET_DRV_NAME) {
		Write-Verbose -Message"�Ώۂ̃v�����^�ɕύX: $TARGET_DRV_NAME"
		try{
			$combobox | Invoke-UiaComboBoxExpand | Get-UiaListItem -Name $DRVNAME -ErrorAction Stop | Invoke-UiaListItemClick
		} catch {
	 		Write-Warning -Message "�Ώۂ̃v�����^�[����������Ȃ��B�����𒆒f����"
	 		return $False
		}
	}

	# �Ώۂ̃v�����^�h���C�o��I��
	Write-Verbose -Message"'�u�b�N�S�̂����'��I��"
	$tab = $window | Get-UiaGroup -Class 'NetUISlabContainer' -Name '���'
	$group = $tab | Get-UiaGroup -Class 'NetUIElement' -Name '�ݒ�'
	$combobox = $group | Get-UiaComboBox -Class 'NetUIDropdownAnchor' -Name '����Ώ�'
	if ($combobox.Value -ne '�u�b�N�S�̂����') {
		try{
			$combobox | Invoke-UiaComboBoxExpand | Get-UiaListItem -Name '�u�b�N�S�̂����' -ErrorAction Stop | Invoke-UiaListItemClick
		} catch {
	 		Write-Warning -Message "'�u�b�N�S�̂����'�ɐݒ�ł��Ȃ��B�����𒆒f����"
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
		($print_dialog = $window | Get-UiaChildWindow -Name "$TARGET_DRV_NAME*" -ErrorAction Stop) >$null
	} catch {
		Write-Warning -Message "����ݒ�_�C�A���O���擾�ł��܂���B�����𒆒f���܂�"
		return $False
	}
	$result_dialog.value = $print_dialog
	return $True
}


# ����{�^������������i����^�u���J���Ă����ԂŎg�p���邱�Ɓj
# $window	[in]	EXCEL�̃��C���E�B���h�E��Window�I�u�W�F�N�g
function EXCEL_Print($window){
	if ($window -eq $null){
		return
	}
	
	# ����{�^��������(Alt+p,p)
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_P) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_P) >$null
	Start-Sleep -Millisecond 200
	
	# ����_�C�A���O���o������܂ł̃E�G�C�g
	Start-Sleep -Millisecond 5000

	# ����_�C�A���O�̃N���[�Y�҂�
	Write-Verbose -Message"����_�C�A���O�N���[�Y�҂�"
	do{
		Start-Sleep -Millisecond 200
	}while($window.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::ReadyForUserInteraction)
	Write-Verbose -Message"����_�C�A���O�N���[�Y�҂��I��"
}


# �E�B���h�E���I������
# $window	[in]	EXCEL�̃��C���E�B���h�E��Window�I�u�W�F�N�g
function EXCEL_Exit($window){
	if ($window -eq $null){
		return
	}
	
	# �A�v���P�[�V���������(Ctrl+F4)
	Write-Verbose -Message"�A�v���P�[�V���������"
	$window.Close()
	
	Start-Sleep -Millisecond 1000
	
	# �ۑ��_�C�A���O�̊m�F�i�擾�ł��Ȃ������疳���j
	if ($window.WindowInteractionState -eq [System.Windows.Automation.WindowInteractionState]::BlockedByModalWindow){
		($cw = Get-UiaChildWindow -InputObject $window -Class 'NUIDialog') >$null
		if($cw -ne $null){
			# �ۑ����Ȃ��{�^���iALT+N�j�̎擾
			$bt = $cw.Children.Buttons | Where-Object {$_.Current.AccessKey -eq "ALT+N"}
			if($bt -ne $null){
				for([int]$i=0; $i -lt 10; $i++){
					# Window���A�N�e�B�u�ɂ���
					[Microsoft.VisualBasic.Interaction]::AppActivate($window.Current.ProcessId)
					
					# �ۑ����Ȃ��{�^���iALT+N�j����������
					(Invoke-UiaButtonClick -InputObject $bt) > $null
					
					if($window.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::BlockedByModalWindow){
						break;
					}
					Start-Sleep 200
				}
			}
		}
	}
}


# EXCEL�������I������
# $process	[in]	EXCEL��Process�I�u�W�F�N�g
# $window	[in]	EXCEL�̃��C���E�B���h�E��Window�I�u�W�F�N�g
# $dialog	[in]	EXCEL�̈���ݒ�_�C�A���O��Window�I�u�W�F�N�g
function EXCEL_Abort($process, $window, $dialog){
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

		EXCEL_Exit($window)
	}
	# Excel�E�B���h�E���N�����̏ꍇ
	elseif($window -ne $null -and $window.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing){
		EXCEL_Exit($window)
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
