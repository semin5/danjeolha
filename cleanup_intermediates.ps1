$ErrorActionPreference = 'Stop'
$taskRun = 'C:\Users\semin5\IdeaProjects\danjeolha-pet\run-20261018'
$taskRecovery = 'C:\Users\semin5\IdeaProjects\danjeolha-pet\run-20261018-recovery'
$taskNames = @(
 'prompts','references','decoded','frames','imagegen-jobs.json',
 'final\spritesheet-aligned.webp','final\spritesheet-cleaned.png',
 'final\spritesheet-cleaned.webp','final\spritesheet-extended.png',
 'final\spritesheet.png','final\spritesheet.webp',
 'qa\rows','qa\stable-approved-frames','qa\stable-experiment',
 'qa\cardinal-270-initial.png','qa\cardinal-probe.png',
 'qa\cardinals-attempt-1.png','qa\cardinals-attempt-3-small-yaw.png',
 'qa\contact-sheet.png','qa\look-directions-pre-registration.png',
 'qa\look-row-9-attempt-1.png','qa\look-row-9-registered.png',
 'qa\spritesheet-pre-foot-alignment.png','qa\standard-native-approved.png',
 'qa\standard-native-auto.png'
)
if (Test-Path -LiteralPath $taskRecovery) { throw 'Recovery destination already exists' }
$taskRunPrefix = [System.IO.Path]::GetFullPath($taskRun) + '\'
$taskRecoveryPrefix = [System.IO.Path]::GetFullPath($taskRecovery) + '\'
$taskMoves = foreach ($taskName in $taskNames) {
 $taskSource = (Resolve-Path -LiteralPath (Join-Path $taskRun $taskName)).ProviderPath
 $taskDestination = [System.IO.Path]::GetFullPath((Join-Path $taskRecovery $taskName))
 if (-not $taskSource.StartsWith($taskRunPrefix,[System.StringComparison]::OrdinalIgnoreCase)) { throw ('Unsafe source: '+$taskSource) }
 if (-not $taskDestination.StartsWith($taskRecoveryPrefix,[System.StringComparison]::OrdinalIgnoreCase)) { throw ('Unsafe destination: '+$taskDestination) }
 [pscustomobject]@{source=$taskSource;destination=$taskDestination}
}
New-Item -ItemType Directory -Path $taskRecovery | Out-Null
foreach ($taskMove in $taskMoves) {
 $taskParent = [System.IO.Path]::GetDirectoryName($taskMove.destination)
 New-Item -ItemType Directory -Path $taskParent -Force | Out-Null
 Move-Item -LiteralPath $taskMove.source -Destination $taskMove.destination
}
[pscustomobject]@{ok=$true;recoverable=$true;deleted=$false;recoveryDirectory=$taskRecovery;moved=$taskMoves} | ConvertTo-Json -Depth 4
