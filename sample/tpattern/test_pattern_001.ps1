Param( [parameter(mandatory)]$DIALOG )

# [���e�T�C�Y]�ݒ�
Write-Host "[���e�T�C�Y]�ݒ�"
if (-not (Set_ComboBox $DIALOG "���e�T�C�Y(D):" "A3 (297 x 420 mm)")){
	return $False
}

return $True
