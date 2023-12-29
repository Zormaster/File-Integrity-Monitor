Write-Host ""
Write-Host "What would you like to do?"
Write-Host "A) Collect new Baseline?"
Write-Host "B) Begin monitoring files with saved baseline?"

$response = Read-Host -Prompt "Please enter 'A' or 'B'"

Write-Host ""

Function Calculate-File-Hash($filepath) {
    $hash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $hash
}

Function Erase-Baseline-If-Already-Exists() {
    if (Test-Path -Path "./baseline.txt") {
        Remove-Item -Path "./baseline.txt"
    }
}

function Show-Notification {
    [cmdletbinding()]
    Param (
        [string]
        $ToastTitle,
        [string]
        [parameter(ValueFromPipeline)]
        $ToastText
    )

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $Template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)

    $RawXml = [xml] $Template.GetXml()
    ($RawXml.toast.visual.binding.text|where {$_.id -eq "1"}).AppendChild($RawXml.CreateTextNode($ToastTitle)) > $null
    ($RawXml.toast.visual.binding.text|where {$_.id -eq "2"}).AppendChild($RawXml.CreateTextNode($ToastText)) > $null

    $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $SerializedXml.LoadXml($RawXml.OuterXml)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $Toast.Tag = "PowerShell"
    $Toast.Group = "PowerShell"
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("PowerShell")
    $Notifier.Show($Toast);
}

if ($response -eq "A".ToUpper()) {
    # Erase Baseline if it already exists
    Erase-Baseline-If-Already-Exists
    Show-Notification -ToastTitle "File Integrity Monitor" -ToastText "Baseline has been erased!"

    # Calculate Hash from the target files and store in baseline.txt
    Write-Host "Collecting new baseline..." -ForegroundColor Cyan
    # Collect all files in the target folder
    Add-Type -AssemblyName System.Windows.Forms
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
        InitialDirectory = [Environment]::GetFolderPath('MyDocuments') 
        Multiselect = $True
        ShowHelp = $True
        # Filter = 'Documents (*.docx)|*.docx|SpreadSheet (*.xlsx)|*.xlsx'
    }
    $null = $FileBrowser.ShowDialog()
    $FileBrowser

    # For file, calculate the hash and write to baseline.txt
    foreach ($file in $FileBrowser.FileNames) {
        $hash = Calculate-File-Hash($file)
        "$($file)|$($hash.Hash)" | Out-File -FilePath "./baseline.txt" -Append
    }

} elseif ($response -eq "B".ToUpper()) {

    $fileHashDictionay = @{}

    # Load file|hash from baseline.txt and store them in a dictionary
    $baseline = Get-Content -Path "./baseline.txt"

    foreach ($line in $baseline) {
        $fileHashDictionay.add($line.Split("|")[0], $line.Split("|")[1]) 
    }
    $fileHashDictionay
    # Begin monitoring files with saved Baseline
    Write-Host "Starting monitoring..." -ForegroundColor Yellow

    $CheckInterval = 1 # Set the interval between notifications in seconds
    $NotificationState = @{}  # Dictionary to track notification state for each file

    while ($true) {
        Write-Host "Checking if files have changed..."

        foreach ($file in $fileHashDictionay.Keys) {
            $hash = Calculate-File-Hash $file

            if ($fileHashDictionay[$file] -eq $null) {
                # File has been added
                if (-not $NotificationState.ContainsKey($file)) {
                    Write-Host "$($file) has been created!" -ForegroundColor Green
                    Show-Notification -ToastTitle "File Integrity Monitor" -ToastText "$($file) has been created!"
                    $NotificationState[$file] = $true
                }
            } elseif ($fileHashDictionay[$file] -ne $hash.Hash) {
                # File has been modified
                if (-not $NotificationState.ContainsKey($file) -or -not $NotificationState[$file]) {
                    Write-Host "$($file) has been modified!" -ForegroundColor Red
                    Show-Notification -ToastTitle "File Integrity Monitor" -ToastText "$($file) has been modified!"
                    $NotificationState[$file] = $true
                }
            } elseif ($NotificationState.ContainsKey($file) -and $NotificationState[$file]) {
                # File has reverted to the baseline
                Write-Host "$($file) has been reverted!" -ForegroundColor Yellow
                Show-Notification -ToastTitle "File Integrity Monitor" -ToastText "$($file) has been reverted to baseline!"
                $NotificationState[$file] = $false
            }
        }

        foreach ($key in $fileHashDictionay.Keys) {
            $baselineFileStillExists = Test-Path -Path $key
            if (-not $baselineFileStillExists) {
                # File has been removed
                if (-not $NotificationState.ContainsKey($key)) {
                    Write-Host "$($key) has been removed!" -ForegroundColor DarkRed
                    Show-Notification -ToastTitle "File Integrity Monitor" -ToastText "$($key) has been removed!"
                    $NotificationState[$key] = $true
                }
            }
        }

        Start-Sleep -Seconds $CheckInterval
    }
}