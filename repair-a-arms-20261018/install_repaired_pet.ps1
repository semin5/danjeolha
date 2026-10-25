$ErrorActionPreference='Stop'
$taskRun='C:\Users\semin5\IdeaProjects\danjeolha-pet\repair-a-arms-20261018'
$taskTarget='C:\Users\semin5\.codex\pets\danjeolha'
$taskChecks=@{'qa\review.json'='ok';'qa\running-inspection.json'='ok';'final\validation.json'='ok';'qa\chroma-despill-repaired-row.json'='ok';'qa\arm-preclean-review.json'='approved';'qa\final-visual-review.json'='approved';'qa\preserved-state-pixels.json'='ok'}
foreach($taskCheck in $taskChecks.GetEnumerator()) {
 $taskData=Get-Content -LiteralPath (Join-Path $taskRun $taskCheck.Key) -Raw | ConvertFrom-Json
 if($taskData.($taskCheck.Value) -ne $true){throw ('QA failed: '+$taskCheck.Key)}
}
$taskReview=Get-Content -LiteralPath ($taskRun+'\qa\final-visual-review.json') -Raw | ConvertFrom-Json
$taskNewHash=(Get-FileHash -LiteralPath ($taskRun+'\final\spritesheet.webp') -Algorithm SHA256).Hash
if($taskNewHash -ne $taskReview.final_sha256){throw 'Reviewed atlas hash differs'}
$taskManifest=Get-Content -LiteralPath ($taskRun+'\final\pet.json') -Raw | ConvertFrom-Json
if($taskManifest.id -ne 'danjeolha' -or $taskManifest.displayName -ne '단절하' -or $taskManifest.spriteVersionNumber -ne 1){throw 'Unexpected A metadata'}
foreach($taskName in @('pet.json','spritesheet.webp')) {
 $taskCurrent=(Get-FileHash -LiteralPath (Join-Path $taskTarget $taskName) -Algorithm SHA256).Hash
 $taskBackup=(Get-FileHash -LiteralPath (Join-Path ($taskRun+'\backup') $taskName) -Algorithm SHA256).Hash
 if($taskCurrent -ne $taskBackup){throw ('Installed file changed since backup: '+$taskName)}
}
$taskPreserved=Get-Content -LiteralPath ($taskRun+'\qa\preserved-pets.json') -Raw | ConvertFrom-Json
foreach($taskEntry in $taskPreserved.files.PSObject.Properties){
 if((Get-FileHash -LiteralPath $taskEntry.Name -Algorithm SHA256).Hash -ne $taskEntry.Value){throw ('Other pet changed: '+$taskEntry.Name)}
}
try {
 Copy-Item -LiteralPath ($taskRun+'\final\spritesheet.webp') -Destination ($taskTarget+'\spritesheet.webp') -Force
 Copy-Item -LiteralPath ($taskRun+'\final\pet.json') -Destination ($taskTarget+'\pet.json') -Force
 if((Get-FileHash -LiteralPath ($taskTarget+'\spritesheet.webp') -Algorithm SHA256).Hash -ne $taskNewHash){throw 'Installed atlas hash mismatch'}
} catch {
 Copy-Item -LiteralPath ($taskRun+'\backup\spritesheet.webp') -Destination ($taskTarget+'\spritesheet.webp') -Force
 Copy-Item -LiteralPath ($taskRun+'\backup\pet.json') -Destination ($taskTarget+'\pet.json') -Force
 throw
}
foreach($taskEntry in $taskPreserved.files.PSObject.Properties){
 if((Get-FileHash -LiteralPath $taskEntry.Name -Algorithm SHA256).Hash -ne $taskEntry.Value){throw ('Other pet changed: '+$taskEntry.Name)}
}
[pscustomobject]@{installed=$true;path=$taskTarget;spriteVersionNumber=1;sha256=$taskNewHash;oldVersionRecoverable=$true;backup=($taskRun+'\backup');otherPetsUnchanged=$true;automaticallySelected=$false}|ConvertTo-Json
