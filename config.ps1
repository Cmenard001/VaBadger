# Script de configuration pour VaBadger
# Ajoute une tache planifiee pour executer Alerte.ps1 tous les jours

# Recuperer l'utilisateur original (avant elevation)
param(
    [string]$OriginalUser = ""
)

# Si pas d'utilisateur passe en parametre, on est dans l'execution initiale
if ([string]::IsNullOrEmpty($OriginalUser)) {
    $OriginalUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

# Verifier les droits administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "Verification des droits administrateur: $isAdmin" -ForegroundColor Gray
Write-Host "Utilisateur original: $OriginalUser" -ForegroundColor Gray

if (-not $isAdmin) {
    Write-Host "Ce script necessite des droits administrateur pour creer une tache planifiee." -ForegroundColor Yellow
    Write-Host "Demande d'elevation des privileges..." -ForegroundColor Cyan
    Write-Host ""

    # Relancer le script en mode administrateur en passant l'utilisateur original
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -OriginalUser `"$OriginalUser`"" -Verb RunAs
        exit
    }
    catch {
        Write-Host "Erreur: Impossible d'obtenir les droits administrateur." -ForegroundColor Red
        Write-Host "Veuillez relancer PowerShell en tant qu'administrateur manuellement." -ForegroundColor Yellow
        pause
        exit 1
    }
}

# Recuperer le chemin absolu du dossier du script
$scriptPath = $PSScriptRoot
$alertScriptPath = Join-Path $scriptPath "Alerte.ps1"

# Verifier que le script d'alerte existe
if (-not (Test-Path $alertScriptPath)) {
    Write-Host "Erreur: Le fichier Alerte.ps1 n'a pas ete trouve dans $scriptPath" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "=== Configuration de VaBadger ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Script d'alerte: $alertScriptPath" -ForegroundColor Green
Write-Host ""

# Demander le mode d'execution
Write-Host "Choisissez le mode d'execution:" -ForegroundColor Cyan
Write-Host "  1 - Aujourd'hui a une heure precise (execution unique)" -ForegroundColor White
Write-Host "  2 - Tous les jours a une heure precise (execution quotidienne)" -ForegroundColor White
Write-Host ""

do {
    $modeInput = Read-Host "Votre choix (1 ou 2)"
    if ($modeInput -eq "1" -or $modeInput -eq "2") {
        $modeValide = $true
    }
    else {
        Write-Host "Erreur: Veuillez choisir 1 ou 2" -ForegroundColor Red
        $modeValide = $false
    }
} while (-not $modeValide)

$executionQuotidienne = ($modeInput -eq "2")
Write-Host ""

# Demander l'heure d'execution
do {
    if ($executionQuotidienne) {
        $heureInput = Read-Host "A quelle heure souhaitez-vous executer l'alerte quotidienne? (format HH:MM, ex: 14:30)"
    }
    else {
        $heureInput = Read-Host "A quelle heure souhaitez-vous executer l'alerte aujourd'hui? (format HH:MM, ex: 14:30)"
    }

    # Valider le format
    if ($heureInput -match '^\d{1,2}:\d{2}$') {
        $heureParts = $heureInput -split ':'
        $heure = [int]$heureParts[0]
        $minute = [int]$heureParts[1]

        if ($heure -ge 0 -and $heure -le 23 -and $minute -ge 0 -and $minute -le 59) {
            $heureValide = $true
        }
        else {
            Write-Host "Erreur: L'heure doit etre entre 00:00 et 23:59" -ForegroundColor Red
            $heureValide = $false
        }
    }
    else {
        Write-Host "Erreur: Format invalide. Utilisez le format HH:MM (ex: 14:30)" -ForegroundColor Red
        $heureValide = $false
    }
} while (-not $heureValide)

Write-Host ""
Write-Host "Configuration de la tache planifiee..." -ForegroundColor Yellow

# Nom de la tache
$taskName = "VaBadger_DailyAlert"

# Supprimer la tache si elle existe deja
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Suppression de l'ancienne tache planifiee..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Creer l'action (executer PowerShell avec le script)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$alertScriptPath`""

# Creer le declencheur selon le mode choisi
if ($executionQuotidienne) {
    # Tous les jours a l'heure specifiee
    $trigger = New-ScheduledTaskTrigger -Daily -At $heureInput
}
else {
    # Aujourd'hui a l'heure specifiee (execution unique)
    $dateExecution = Get-Date -Hour $heure -Minute $minute -Second 0
    $trigger = New-ScheduledTaskTrigger -Once -At $dateExecution
}

# Correction des changements d'heure (DST)
# On retire le decalage de fuseau horaire de StartBoundary pour forcer l'utilisation de l'heure locale courante
if ($trigger.StartBoundary) {
    $trigger.StartBoundary = [datetime]::Parse($trigger.StartBoundary).ToString("yyyy-MM-ddTHH:mm:ss")
}

# Creer les parametres de la tache
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

# Creer le principal avec l'utilisateur original
Write-Host "Utilisateur pour la tache: $OriginalUser" -ForegroundColor Gray
$principal = New-ScheduledTaskPrincipal -UserId $OriginalUser -LogonType Interactive -RunLevel Highest

# Enregistrer la tache
try {
    Write-Host "Tentative d'enregistrement de la tache..." -ForegroundColor Gray

    $result = Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Alerte quotidienne VaBadger" -Force -ErrorAction Stop

    Write-Host "Commande Register-ScheduledTask executee" -ForegroundColor Gray
    Write-Host "Resultat: $($result.TaskName)" -ForegroundColor Gray

    # Attendre un peu pour que Windows enregistre la tache
    Start-Sleep -Milliseconds 500

    # Verifier que la tache a bien ete creee
    Write-Host "Verification de la creation de la tache..." -ForegroundColor Gray
    $verifyTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    if ($verifyTask) {
        Write-Host ""
        Write-Host "Tache planifiee creee avec succes!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Details de la configuration:" -ForegroundColor Cyan
        Write-Host "  - Nom de la tache: $taskName" -ForegroundColor White
        if ($executionQuotidienne) {
            Write-Host "  - Frequence: Tous les jours a $heureInput" -ForegroundColor White
        }
        else {
            Write-Host "  - Frequence: Aujourd'hui a $heureInput (execution unique)" -ForegroundColor White
        }
        Write-Host "  - Script execute: $alertScriptPath" -ForegroundColor White
        Write-Host "  - Etat: $($verifyTask.State)" -ForegroundColor White
        Write-Host "  - Utilisateur: $OriginalUser" -ForegroundColor White
        Write-Host ""

        # Double verification avec schtasks
        Write-Host "Double verification avec schtasks..." -ForegroundColor Gray
        $schtaskCheck = schtasks /query /tn "$taskName" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Verification schtasks: OK" -ForegroundColor Green
        }
        else {
            Write-Host "Verification schtasks: ECHEC" -ForegroundColor Red
            Write-Host "Output: $schtaskCheck" -ForegroundColor Red
        }

        Write-Host ""
        Write-Host "Vous pouvez modifier ou supprimer cette tache dans le Planificateur de taches Windows." -ForegroundColor Gray
    }
    else {
        Write-Host ""
        Write-Host "ERREUR: La tache a ete enregistree mais n'a pas pu etre verifiee." -ForegroundColor Red
        Write-Host "Verifiez que vous avez bien les droits administrateur." -ForegroundColor Yellow
        Write-Host "Est administrateur: $isAdmin" -ForegroundColor Yellow
        pause
        exit 1
    }

}
catch {
    Write-Host ""
    Write-Host "Erreur lors de la creation de la tache planifiee:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "Type d'erreur: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Assurez-vous que PowerShell est lance en mode Administrateur!" -ForegroundColor Yellow
    Write-Host "Est administrateur: $isAdmin" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host ""
pause
