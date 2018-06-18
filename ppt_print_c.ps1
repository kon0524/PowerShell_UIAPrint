Param(
	[parameter(mandatory)][string]$PRINTERICONNAME,
	[parameter(mandatory)][string]$DATAPATH,
	[parameter(mandatory)][string]$TESTSCRIPTPATH
)
. ".\util\powerpoint_print.ps1"
. ".\util\util.ps1"

# ����
$LASTEXITCODE = 99
$DATAPATH = Convert-Path $DATAPATH
$TESTSCRIPTPATH = Convert-Path $TESTSCRIPTPATH

New-Variable process 
New-Variable window
New-Variable dialog
$result = $False

# �J�n�R�����g
Write-Host "----------------------" -ForegroundColor Cyan
Write-Host "$PSCommandPath" -ForegroundColor Cyan
Write-Host "$PRINTERICONNAME" -ForegroundColor Cyan
Write-Host "$DATAPATH" -ForegroundColor Cyan
Write-Host "$TESTSCRIPTPATH" -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan

# POWERPOINT���J�n���A����ݒ�_�C�A���O�𗧂��グ��
try{
	$result = $False
	$result = (POWERPOINT_Start $DATAPATH $PRINTERICONNAME ([ref]$process) ([ref]$window) ([ref]$dialog))
} catch {
	$result = $False
}
if ($False -eq $result) {
	Write-Host "[FAILED] start Application" -ForegroundColor Red
	POWERPOINT_Abort $process $window $dialog
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
	POWERPOINT_Abort $process $window $dialog
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
	POWERPOINT_Abort $process $window $dialog
	exit 1
}

# �������
try{
	Write-Host "�������"
	$result = $False
	$result = (POWERPOINT_Print $window)
}catch{
	$result = $False
}
if ($False -eq $result){
	Write-Host "[FAILED] click PRINT-BUTTON" -ForegroundColor Red
	POWERPOINT_Abort $process $window $dialog
	exit 1
}

# �A�v���P�[�V�������I��
POWERPOINT_Exit ($window)

# ������f�_�C�A���O������̂�҂�
$process.WaitForExit()

exit 0
