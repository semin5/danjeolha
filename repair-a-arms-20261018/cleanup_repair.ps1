$ErrorActionPreference='Stop'
$taskRun='C:\Users\semin5\IdeaProjects\danjeolha-pet\repair-a-arms-20261018'
$taskRecovery='C:\Users\semin5\IdeaProjects\danjeolha-pet\repair-a-arms-20261018-recovery'
$taskSourceFile='C:\Users\semin5\.codex\generated_images\01a14ee3-ba6c-71b1-ac9f-a7c042a16ffe\exec-c760eb98-7ff0-4048-94fa-b53aebbf97df.png'
$taskNames=@('prompts','references','decoded','frames','imagegen-jobs.json','final\base-A.png','final\spritesheet-preclean.png','final\spritesheet-preclean.webp','final\spritesheet.png','qa\running-registered-preclean.png','qa\running-cleaned.png')
if(Test-Path -LiteralPath $taskRecovery){throw 'Recovery directory already exists'}
$taskSourceHash=(Get-FileHash -LiteralPath $taskSourceFile -Algorithm SHA256).Hash
$taskCopiedHash=(Get-FileHash -LiteralPath ($taskRun+'\decoded\running.png') -Algorithm SHA256).Hash
if($taskSourceHash -ne $taskCopiedHash){throw 'Selected generated copy hash differs'}
$taskRunPrefix=[System.IO.Path]::GetFullPath($taskRun)+'\'
$taskRecoveryPrefix=[System.IO.Path]::GetFullPath($taskRecovery)+'\'
$taskMoves=foreach($taskName in $taskNames){
 $taskSource=(Resolve-Path -LiteralPath (Join-Path $taskRun $taskName)).ProviderPath
 $taskDestination=[System.IO.Path]::GetFullPath((Join-Path $taskRecovery $taskName))
 if(-not $taskSource.StartsWith($taskRunPrefix,[System.StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe source'}
 if(-not $taskDestination.StartsWith($taskRecoveryPrefix,[System.StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe destination'}
 [pscustomobject]@{source=$taskSource;destination=$taskDestination}
}
if([System.IO.Path]::GetFullPath($taskSourceFile) -ne 'C:\Users\semin5\.codex\generated_images\01a14ee3-ba6c-71b1-ac9f-a7c042a16ffe\exec-c760eb98-7ff0-4048-94fa-b53aebbf97df.png'){throw 'Unsafe generated source'}
New-Item -ItemType Directory -Path $taskRecovery | Out-Null
foreach($taskMove in $taskMoves){
 New-Item -ItemType Directory -Path ([System.IO.Path]::GetDirectoryName($taskMove.destination)) -Force | Out-Null
 Move-Item -LiteralPath $taskMove.source -Destination $taskMove.destination
}
Move-Item -LiteralPath $taskSourceFile -Destination ($taskRecovery+'\selected-generated-source.png')
[pscustomobject]@{ok=$true;recoverable=$true;deleted=$false;movedRunEntries=$taskMoves.Count;selectedOriginalMoved=$true;recoveryDirectory=$taskRecovery;BBackupRetained=($taskRun+'\backup')} | ConvertTo-Json
