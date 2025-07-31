Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Ajouter appel WinAPI GetAsyncKeyState pour surveiller Esc ---
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Keyboard {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
    [DllImport("user32.dll")]
    public static extern short GetKeyState(int vKey);
}
"@

# Constante pour la touche Échap
$VK_ESCAPE = 0x1B

# --- Fonction : crée un formulaire plein écran ---
function Flash-Screen {
    $forms = @()

    # Créer un formulaire pour chaque écran
    foreach ($screen in [System.Windows.Forms.Screen]::AllScreens) {
        $form = New-Object System.Windows.Forms.Form
        $form.FormBorderStyle = 'None'
        $form.WindowState = 'Normal'
        $form.StartPosition = 'Manual'
        $form.Location = $screen.Bounds.Location
        $form.Size = $screen.Bounds.Size
        $form.TopMost = $true
        $form.BackColor = 'Red'
        $form.Opacity = 0.7

        # Ajouter un label avec texte d'alerte principal
        $label = New-Object System.Windows.Forms.Label
        $label.Text = "VA BADGER !"
        $label.Font = New-Object System.Drawing.Font("Arial", 72, [System.Drawing.FontStyle]::Bold)
        $label.ForeColor = 'White'
        $label.BackColor = 'Transparent'
        $label.TextAlign = 'MiddleCenter'
        $label.Dock = 'Fill'
        $form.Controls.Add($label)

        # Ajouter un label avec instruction pour quitter
        $instructionLabel = New-Object System.Windows.Forms.Label
        $instructionLabel.Text = "Appuie sur echap pour quitter"
        $instructionLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Regular)
        $instructionLabel.ForeColor = 'White'
        $instructionLabel.BackColor = 'Transparent'
        $instructionLabel.TextAlign = 'MiddleCenter'
        $instructionLabel.Dock = 'Bottom'
        $instructionLabel.Height = 50
        $form.Controls.Add($instructionLabel)

        # Ajouter gestion des événements clavier
        $form.KeyPreview = $true
        $form.Add_KeyDown({
            param($sender, $e)
            if ($e.KeyCode -eq 'Escape') {
                $script:exitRequested = $true
            }
        })

        # Ajouter gestion des événements de focus
        $form.Add_Activated({
            $script:exitRequested = $false
        })

        $forms += $form
    }

    return $forms
}

# --- Fonction : joue un son ---
function Play-AlertSound {
    [console]::beep(1000, 300)
}

# --- Début ---
$forms = Flash-Screen
$script:exitRequested = $false
$startTime = Get-Date
$flashCount = 0

# Boucle jusqu'à Échap ou timeout (5 minutes max)
while ($true) {
    # Vérifier Escape en premier
    $key1 = [Keyboard]::GetAsyncKeyState($VK_ESCAPE)
    if (($key1 -band 0x8000) -or $script:exitRequested) {
        break
    }

    # Afficher tous les formulaires
    foreach ($form in $forms) {
        $form.Show()
        $form.Activate()
    }
    [System.Windows.Forms.Application]::DoEvents()

    # Vérifier Escape pendant l'affichage
    $key1 = [Keyboard]::GetAsyncKeyState($VK_ESCAPE)
    if (($key1 -band 0x8000) -or $script:exitRequested) {
        break
    }

    Play-AlertSound

    # Vérifications multiples pendant le délai
    for ($i = 0; $i -lt 25; $i++) {
        Start-Sleep -Milliseconds 10
        [System.Windows.Forms.Application]::DoEvents()
        $key1 = [Keyboard]::GetAsyncKeyState($VK_ESCAPE)
        if (($key1 -band 0x8000) -or $script:exitRequested) {
            break
        }
    }

    if (($key1 -band 0x8000) -or $script:exitRequested) {
        break
    }

    # Cacher tous les formulaires
    foreach ($form in $forms) {
        $form.Hide()
    }

    # Vérifications pendant la pause
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Milliseconds 10
        [System.Windows.Forms.Application]::DoEvents()
        $key1 = [Keyboard]::GetAsyncKeyState($VK_ESCAPE)
        if (($key1 -band 0x8000) -or $script:exitRequested) {
            break
        }
    }

    if (($key1 -band 0x8000) -or $script:exitRequested) {
        break
    }

    # Timeout de sécurité (5 minutes)
    if ((Get-Date) - $startTime -gt [TimeSpan]::FromMinutes(5)) {
        break
    }
}

# Nettoyage
foreach ($form in $forms) {
    $form.Close()
    $form.Dispose()
}
