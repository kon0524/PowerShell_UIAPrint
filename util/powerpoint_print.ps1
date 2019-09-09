add-type -AssemblyName microsoft.VisualBasic

# POWERPOINT���J�n���A����ݒ�_�C�A���O�𗧂��グ��
# $FILEPATH			[in]	XLSX�t�@�C���ւ̃p�X
# $DRVNAME			[in]	�h���C�o���i�v�����^�A�C�R�����j
# result_process	[out]	POWERPOINT��Process�I�u�W�F�N�g���擾
# result_window		[out]	POWERPOINT�̃��C���E�B���h�E��Window�I�u�W�F�N�g���擾
# result_dialog		[out]	POWERPOINT�̈���ݒ�_�C�A���O��Window�I�u�W�F�N�g���擾
function POWERPOINT_Start($FILEPATH, $DRVNAME, [ref]$result_process, [ref]$result_window, [ref]$result_dialog){

	Write-Verbose -Message"'PowerPoint'���N������"

	# �g���qdocx�̊֘A�A�v���P�[�V�����̃p�X���擾
	$assoc_val = cmd /c assoc .pptx
	$assoc_command = cmd /c ftype $assoc_val.Split("=")[1]
	$app_path = $assoc_command.Split('"*"')[1]
	if ($app_path -notmatch "POWERPNT.EXE\s*$"){
		Write-Warning -Message "�g���q'docx'��'POWERPNT.EXE'���֘A�����Ă��܂���"
		return $False
	}
	
	# �t�@�C���̃p�X�̊m�F
	if ( -not (Test-Path $FILEPATH)){
		Write-Warning -Message "$FILEPATH��������܂���"
		return $False
	}
	
	# �A�v���P�[�V�����iPOWERPOINT�j���N��
	Write-Verbose -Message"'$FILEPATH'���N������"
	$app_process = Start-Process -FilePath $app_path -PassThru -ArgumentList $FILEPATH
	$result_process.value = $app_process
	
	# �ő�10�b�ҋ@
	if ($False -eq $app_process.WaitForInputIdle(10000)) {
		Write-Warning -Message "���͉\��ԑ҂��^�C���A�E�g"
		return $False
	}
	
	# mainWindow�̎擾
	$window = Get-UIAWindow -Class 'PPTFrameClass' -ProcessId $app_process.Id
	if ($window -eq $null){
		Write-Warning -Message "Window���擾�ł��Ȃ��B�����𒆒f����"
		return
	}
	$result_window.value = $window

	# �I�v�V�������o�b�O�O���E���h����ɕύX
	# �I�v�V�������J��
	Write-Verbose -Message"�I�v�V�����ݒ�ύX"
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyDown([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_F) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::VK_T) >$null
	Start-Sleep -Millisecond 200
	$window.Keyboard.KeyUp([WindowsInput.Native.VirtualKeyCode]::MENU) >$null
	Start-Sleep -Millisecond 200

	# �I�v�V�����_�C�A���O���擾
	$option_dialog = Get-UIAChildWindow -InputObject $window -Class 'NUIDialog' -Name 'PowerPoint �̃I�v�V����'
	if ($option_dialog -ne $null){
		# �ڍאݒ��ʂɐ؂�ւ�
		try{
			(Get-UiaList -InputObject $option_dialog | Get-UiaListItem -Class 'NetUIListViewItem' -Name '�ڍאݒ�' -ErrorAction Stop| Invoke-UiaListItemClick -ErrorAction Stop) >$null
		} catch {
			Write-Warning -Message "�I�v�V�����ݒ��ύX�ł��܂���ł���"
			$option_dialog.Close()
			return $False
		}
		
		# �o�b�N�O���E���h����̐ݒ��Ԃ��擾
		($checkbox = Get-UiaPane -InputObject $option_dialog -Name '�ڍאݒ�' -ErrorAction SilentlyContinue | Get-UiaCheckBox -Name '�o�b�N�O���E���h�ň������' -ErrorAction SilentlyContinue) >$null
		if ($checkbox -eq $null){
			Write-Warning -Message "�I�v�V�����ݒ��ύX�ł��܂���ł���"
			$option_dialog.Close()
			return $False
		}

		# �o�b�N�O���E���h�ň����Off�ɂ���
		While ($checkbox.ToggleState -ne 'Off'){
			Write-Verbose -Message"�I�v�V�����ݒ��'�o�b�N�O���E���h������Ȃ�'�ɕύX"
			(Set-UiaCheckBoxToggleState -InputObject $checkbox $False) >$null
		}
		
		# OK�{�^�����������ăN���[�Y
		(Get-UiaButton -InputObject $option_dialog -Name 'OK' | Invoke-UiaButtonClick) >$null
		
		# �����N���[�Y����Ă��Ȃ�������A�����I��
		Start-Sleep -Millisecond 200
		if ($option_dialog.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing){
			$option_dialog.Close()
		}
	}
	
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
	$tab = $window | Get-UiaGroup -Class 'NetUISlabContainer' -Name '���'
	if ($tab -eq $null){
		Write-Warning -Message "����^�u���擾�ł��Ȃ��B�����𒆒f����"
		return ��False
	}

	# �Ώۂ̃v�����^�h���C�o��I��
	Write-Verbose -Message"�Ώۂ̃v�����^�h���C�o��I��"
	$group = $tab | Get-UiaGroup -Class 'NetUIElement' -Name '�v�����^�['
	$combobox = $group | Get-UiaComboBox -Class 'NetUIDropdownAnchor' -Name '�g�p����v�����^�['
	if ($combobox.Value -ne $TARGET_DRV_NAME) {
		Write-Verbose -Message"�Ώۂ̃v�����^�ɕύX: $TARGET_DRV_NAME"
		try{
			($combobox | Invoke-UiaComboBoxExpand | Get-UiaListItem -Name $DRVNAME -ErrorAction Stop | Invoke-UiaListItemClick) >$null
		} catch {
	 		Write-Warning -Message "�Ώۂ̃v�����^�[����������Ȃ��B�����𒆒f����" -ForegroundColor Red >$null
	 		return $False
		}
	}

	# ����Ώۂ�I��
	Write-Verbose -Message"'���ׂẴX���C�h�����'��I��"
	$group = Get-UiaGroup -InputObject $tab -Class 'NetUIElement' -Name '�ݒ�'
	$combobox = Get-UiaComboBox -InputObject $group -Class 'NetUIDropdownAnchor' -Name '����Ώ�'
	if ($combobox.Value -ne '�u�b�N�S�̂����') {
		try{
			($combobox | Invoke-UiaComboBoxExpand | Get-UiaListItem -Name '���ׂẴX���C�h�����' -ErrorAction Stop | Invoke-UiaListItemClick) >$null
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
# $window	[in]	POWERPOINT�̃��C���E�B���h�E��Window�I�u�W�F�N�g
function POWERPOINT_Print($window){
	if ($window -eq $null){
		return
	}

	# �Ȃ��������ŏ����҂��Ȃ��ƈ���{�^����������Ȃ�...
	Start-Sleep -Millisecond 500

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
# $window	[in]	POWERPOINT�̃��C���E�B���h�E��Window�I�u�W�F�N�g
function POWERPOINT_Exit($window){
	if ($window -eq $null){
		return
	}
	
	# �A�v���P�[�V���������(Ctrl+F4)
	Write-Verbose -Message"�A�v���P�[�V���������"
	$window.Close()

	# �ۑ��_�C�A���O�����オ��҂�
	Start-Sleep -Millisecond 2000
	($window.WaitForInputIdle(10000)) >$null
	
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


# POWERPOINT�������I������
# $process	[in]	POWERPOINT��Process�I�u�W�F�N�g
# $window	[in]	POWERPOINT�̃��C���E�B���h�E��Window�I�u�W�F�N�g
# $dialog	[in]	POWERPOINT�̈���ݒ�_�C�A���O��Window�I�u�W�F�N�g
function POWERPOINT_Abort($process, $window, $dialog){
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
		
		POWERPOINT_Exit($window)
	}
	# POWERPOINT�E�B���h�E���N�����̏ꍇ
	elseif($window -ne $null -and $window.WindowInteractionState -ne [System.Windows.Automation.WindowInteractionState]::Closing){
		POWERPOINT_Exit($window)
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
