Import-Module "..\..\UIAutomation\UIAutomation.dll"

# �p�����[�^
$target_drivername = 'RICOH MP C2504 JPN RPCS'
$pattern_path = '.\tpattern'

# �Ώۃt�@�C��
$filearray = @(
  Convert-Path '.\DATA\sample.bmp'
)

# �e�X�g�p�^�[���t�@�C���̎��W
$tp_files = (Get-ChildItem -Recurse "$pattern_path\*.ps1" | Where-Object{ $_.Length -ne $null } | Select-Object Fullname)

# ScriptRoot������
Set-Location ..
[Environment]::CurrentDirectory = $PWD

# �e�X�g�f�[�^��
foreach($target_datapath in $filearray)
{
	# �e�X�g�p�^�[����
	foreach($file in $tp_files)
	{
		$pattern_filepath = $file.FullName

		# �g���q�ʂɌĂяo����ς���
		$ext = [System.IO.Path]::GetExtension($target_datapath)
		$call_script = $null
		switch ($ext) {
		    ".doc"	{ $call_script = '.\doc_print_c.ps1'}
		    ".docx"	{ $call_script = '.\doc_print_c.ps1'}
		    ".xls"	{ $call_script = '.\xls_print_c.ps1'}
		    ".xlsx"	{ $call_script = '.\xls_print_c.ps1'}
		    ".ppt"	{ $call_script = '.\ppt_print_c.ps1'}
		    ".pptx"	{ $call_script = '.\ppt_print_c.ps1'}
		    ".pdf"	{ $call_script = '.\pdf_print_c.ps1'}
		    ".bmp"	{ $call_script = '.\bmp_print_c.ps1'}
		    ".tif"	{ $call_script = '.\tif_print_c.ps1'}
		    default { "No match." }
		}
		if ($null -ne $call_script){
			#powershell -File $call_script $target_drivername $target_datapath $pattern_filepath
			. $call_script $target_drivername $target_datapath $pattern_filepath
		}
	}
}

