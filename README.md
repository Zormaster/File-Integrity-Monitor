# File-Integrity-Monitor

## Overview

The File Integrity Monitor (FileIntegrityMonitor.ps1) is a PowerShell script designed to monitor changes to files within a specified folder. It provides two main functionalities:

1. **Collect New Baseline:** This option allows you to create a baseline by calculating and storing the hash values of files in a specified folder.

2. **Begin Monitoring with Saved Baseline:** After creating a baseline, you can use this option to continuously monitor files for any changes, additions, modifications, or removals based on the saved baseline.

## Usage

### 1. Collect New Baseline

To collect a new baseline:

```powershell
.\FileIntegrityMonitor.ps1
```

Choose option 'A' and follow the prompts to select the target files. The script will calculate the hash values and store them in `baseline.txt`. If a baseline file already exists, it will be erased.

### 2. Begin Monitoring with Saved Baseline

To begin monitoring with a saved baseline:

```powershell
.\FileIntegrityMonitor.ps1
```

Choose option 'B' and the script will start monitoring the specified files based on the saved baseline.

## Features

- **File Hash Calculation:** The script uses SHA512 hashing algorithm to calculate the hash values of files.

- **Real-time Notifications:** It provides real-time notifications for file changes, additions, modifications, and removals.

- **Continuous Monitoring:** The script runs continuously, periodically checking for changes based on the specified interval.

- **Baseline Management:** The baseline is saved in `baseline.txt` and is used as a reference for monitoring.

## Notifications

The script utilizes Windows Toast Notifications to alert the user about file changes. Notifications include information about the file and the type of change detected.

## Requirements

- PowerShell (Windows PowerShell or PowerShell Core)
- Windows OS (for Toast Notifications)

## Disclaimer

This script is provided as-is without any warranty. Use it responsibly and ensure that you have appropriate permissions to monitor files.

## Contributing

Contributions are welcome! If you find issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This script is licensed under the [GNU GENERAL PUBLIC LICENSE](LICENSE).
