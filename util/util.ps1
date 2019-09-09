# �w�肳�ꂽ�R���{�{�b�N�X�ɒl��ݒ肷��
# $dialog			[in]	WINWORD�̈���ݒ�_�C�A���O��Window�I�u�W�F�N�g
# $combobox_name	[in]	�ݒ肷��R���{�{�b�N�X���̕�����
# $value			[in]	�R���{�{�b�N�X�ɐݒ肷��l�̕�����
function Set_ComboBox($dialog, $combobox_name, $value){
	New-Variable combobox
	try{
		$combobox = Get-UiaComboBox -InputObject $dialog -Class 'ComboBox' -Name $combobox_name -ErrorAction Stop
	} catch {
		Write-Warning -Message "'$combobox_name' �R���{�{�b�N�X��������܂���"
		return $False
	}

	if ($value -eq $combobox.Value){
		return $True
	}

	try{
		($combobox | Invoke-UiaComboBoxExpand | Get-UiaListItem -Name $value -ErrorAction Stop | Invoke-UiaListItemClick) >$null
	} catch {
		Write-Warning -Message "'$combobox_name' �R���{�{�b�N�X�ɁA�l '$value' �����݂��܂���"
		return $False
	}
	return $True
}


# ���݂̃_�C�A���O��OK�{�^������������
# $dialog	[in]	�_�C�A���O��Window�I�u�W�F�N�g
function Click_ButtonOK($dialog){
	try{
		($button = Get-UiaButton -InputObject $dialog -Class 'Button' -Name 'OK' -ErrorAction Stop ) >$null
		Invoke-UiaButtonClick -InputObject $button -ErrorAction Stop >$null
	} catch {
		return $False
	}
	
	return $True
}