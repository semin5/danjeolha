$ErrorActionPreference = 'Stop'
$taskRegistry = 'C:\Users\semin5\.codex\pets'
$taskProtected = 'C:\Users\semin5\.codex\pets\danjeolha'
$taskArchiveParent = 'C:\Users\semin5\.codex\pet-backups'
$taskArchive = 'C:\Users\semin5\.codex\pet-backups\unregistered-20261022-083258'
$taskIds = @('draco-malfoy-a','phoebe-v2')

function Get-TaskFileSnapshot([string]$taskDirectory) {
 @(Get-ChildItem -LiteralPath $taskDirectory -Recurse -File -Force | ForEach-Object {
  [pscustomobject]@{relative=$_.FullName.Substring($taskDirectory.Length+1);sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash}
 })
}

if ((Resolve-Path -LiteralPath $taskRegistry).ProviderPath -ne $taskRegistry) { throw 'Unexpected registry path' }
if ((Get-Item -LiteralPath $taskRegistry -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Registry is a link' }
if (Test-Path -LiteralPath $taskArchive) { throw 'Recovery directory already exists' }
if (Test-Path -LiteralPath $taskArchiveParent) {
 if ((Get-Item -LiteralPath $taskArchiveParent -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Recovery parent is a link' }
}
$taskEntries = @(Get-ChildItem -LiteralPath $taskRegistry -Directory -Force | Select-Object -ExpandProperty Name)
if (@(Compare-Object @('danjeolha','draco-malfoy-a','phoebe-v2') $taskEntries).Count -ne 0) { throw 'Pet registry changed; inspect again' }
$taskKeepManifest = Get-Content -LiteralPath ($taskProtected+'\pet.json') -Raw | ConvertFrom-Json
if ($taskKeepManifest.id -ne 'danjeolha' -or $taskKeepManifest.displayName -ne '단절하') { throw 'Protected identity differs' }
$taskKeepBefore = @(Get-TaskFileSnapshot $taskProtected)
if ((Get-FileHash -LiteralPath ($taskProtected+'\pet.json') -Algorithm SHA256).Hash -ne '74F26A4CFDD79BCA2B9E1F883EC50593A7838B6912A928AE1214C8DEF7BCAF69') { throw 'Protected metadata changed since independent check' }
if ((Get-FileHash -LiteralPath ($taskProtected+'\spritesheet.webp') -Algorithm SHA256).Hash -ne '755B94FB6F3BF9E6EF0DEBDA6310D357F5C42E7297CAB6044261EE19A175B252') { throw 'Protected artwork changed since independent check' }

$taskMoves = foreach ($taskId in $taskIds) {
 $taskSource = (Resolve-Path -LiteralPath (Join-Path $taskRegistry $taskId)).ProviderPath
 $taskDestination = [IO.Path]::GetFullPath((Join-Path $taskArchive $taskId))
 if ($taskSource -ne ($taskRegistry+'\'+$taskId) -or $taskSource -eq $taskProtected) { throw 'Unsafe source target' }
 if (-not $taskSource.StartsWith($taskRegistry+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Source escaped registry' }
 if ($taskDestination -ne ($taskArchive+'\'+$taskId) -or -not $taskDestination.StartsWith($taskArchive+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe recovery target' }
 if (@(Get-Item -LiteralPath $taskSource -Force; Get-ChildItem -LiteralPath $taskSource -Recurse -Force) | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }) { throw 'Refusing linked pet files' }
 $taskManifest = Get-Content -LiteralPath ($taskSource+'\pet.json') -Raw | ConvertFrom-Json
 if ($taskManifest.id -ne $taskId) { throw 'Target manifest identity mismatch' }
 [pscustomobject]@{id=$taskId;displayName=$taskManifest.displayName;source=$taskSource;recovery=$taskDestination;files=@(Get-TaskFileSnapshot $taskSource)}
}

New-Item -ItemType Directory -Path $taskArchiveParent -Force | Out-Null
New-Item -ItemType Directory -Path $taskArchive | Out-Null
$taskMoved = @()
try {
 foreach ($taskMove in $taskMoves) {
  Move-Item -LiteralPath $taskMove.source -Destination $taskMove.recovery
  $taskMoved += $taskMove
  foreach ($taskFile in $taskMove.files) {
   if ((Get-FileHash -LiteralPath (Join-Path $taskMove.recovery $taskFile.relative) -Algorithm SHA256).Hash -ne $taskFile.sha256) { throw 'Recovery file hash mismatch' }
  }
  if (@(Get-ChildItem -LiteralPath $taskMove.recovery -Recurse -File -Force).Count -ne $taskMove.files.Count) { throw 'Recovery file count mismatch' }
 }
 foreach ($taskFile in $taskKeepBefore) {
  if ((Get-FileHash -LiteralPath (Join-Path $taskProtected $taskFile.relative) -Algorithm SHA256).Hash -ne $taskFile.sha256) { throw 'Protected file changed' }
 }
 $taskRemaining = @(Get-ChildItem -LiteralPath $taskRegistry -Directory -Force | Select-Object -ExpandProperty Name)
 if ($taskRemaining.Count -ne 1 -or $taskRemaining[0] -ne 'danjeolha') { throw 'Unexpected remaining custom pet list' }
} catch {
 foreach ($taskMove in @($taskMoved | Sort-Object id -Descending)) {
  if ((Test-Path -LiteralPath $taskMove.recovery) -and -not (Test-Path -LiteralPath $taskMove.source)) {
   Move-Item -LiteralPath $taskMove.recovery -Destination $taskMove.source
  }
 }
 throw
}
[pscustomobject]@{ok=$true;action='unregister-local-custom-pets';protectedId='danjeolha';protectedUnchanged=$true;protectedFiles=$taskKeepBefore;unregistered=$taskMoves;remainingCustomPets=$taskRemaining;recoverable=$true;deleted=$false;recoveryDirectory=$taskArchive;completedUtc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json -Depth 7
