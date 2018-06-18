Param(
	[parameter(mandatory)][string]$PRINTERICONNAME,
	[parameter(mandatory)][string]$DATAPATH,
	[parameter(mandatory)][string]$TESTSCRIPTPATH
)

Import-Module "C:\devel\UIAutomation\UIAutomation.dll"
. ".\util\acrobat_print.ps1"
. ".\util\util.ps1"

# UI�n�C���C�g������
[UIAutomation.Preferences]::Highlight = $false

# ����
$LASTEXITCODE = 99
$DATAPATH = Convert-Path $DATAPATH
$TESTSCRIPTPATH = Convert-Path $TESTSCRIPTPATH

New-Variable process 
New-Variable window
New-Variable acrobat_dialog
New-Variable dialog
$result = $False

# �J�n�R�����g
Write-Host "----------------------" -ForegroundColor Cyan
Write-Host "$PSCommandPath" -ForegroundColor Cyan
Write-Host "$PRINTERICONNAME" -ForegroundColor Cyan
Write-Host "$DATAPATH" -ForegroundColor Cyan
Write-Host "$TESTSCRIPTPATH" -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan


# ACROBAT���J�n���A����ݒ�_�C�A���O�𗧂��グ��
try{
	$result = $False
	$result = (ACROBAT_Start $DATAPATH $PRINTERICONNAME ([ref]$process) ([ref]$window) ([ref]$acrobat_dialog) ([ref]$dialog))
}catch{
	$result = $False
}
if ($False -eq $result) {
	Write-Host "[FAILED] start Application" -ForegroundColor Red
	ACROBAT_Abort $process $window $acrobat_dialog $dialog
	exit 1
}

# ����ݒ�Ƀe�X�g�p�^�[���̐ݒ�l��ݒ肷��
try{
	Write-Host "����ݒ�"
	$result = $False
	$result = (&$TESTSCRIPTPATH $dialog)
} catch {
	$result = $False
}
if ($False -eq $result){
	Write-Host "[FAILED] call TEST_SCRIPT($TESTSCRIPTPATH)" -ForegroundColor Red
	ACROBAT_Abort $process $window $acrobat_dialog $dialog
	exit 1
}

# OK�{�^��������
try{
	$result = $False
	$result = (Click_ButtonOK $dialog)
}catch{
	$result = $False
}
if ($False -eq $result){
	Write-Host "[FAILED] click OK-BUTTON" -ForegroundColor Red
	ACROBAT_Abort $process $window $acrobat_dialog $dialog
	exit 1
}

# ����{�^��������
try{
	Write-Host "�������"
	$result = $False
	$result = (ACROBAT_Print $window $acrobat_dialog)
}catch{
	$result = $False
}
if ($False -eq $result){
	Write-Host "[FAILED] click PRINT-BUTTON" -ForegroundColor Red
	ACROBAT_Abort $process $window $acrobat_dialog $dialog
	exit 1
}

# �A�v���P�[�V�������I��
ACROBAT_Exit $window

#�v���Z�X�I���҂�
$process.WaitForExit()

exit 0