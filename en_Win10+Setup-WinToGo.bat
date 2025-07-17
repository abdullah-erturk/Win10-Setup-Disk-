<# : hybrid batch + powershell script
@powershell -noprofile -Window Hidden -c "$param='%*';$ScriptPath='%~f0';iex((Get-Content('%~f0') -Raw))"&exit/b
#>

$Title = "Win10+ Setup Disk - Windows To Go"
$Host.UI.RawUI.BackgroundColor = "Gray"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

#   https://github.com/abdullah-erturk/
#   https://github.com/abdullah-erturk/Win10-Setup-Disk-
#   Contributors: @rpo, @freddie-o, @BAU & @abbodi1406, @mephistooo2, @mustafa-gotr (bensuslu11)

$host.ui.rawui.windowtitle = $title
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
$Width = 500; $Height = 590

# Global variables
$Global:ImagePath = ""
$Global:dvd = $False
$Global:ISO = ""
$Global:USB = 0
$Global:SetUp = $True
$Global:ProcessRunning = $False
$Global:usbntfs = ""
$Global:usbfat32 = ""
$Global:Mounted = $False
$Global:BypassTPM = $False
$Global:CustomAutoUnattendPath = ""

# File browser (AutoUnattend.xml)
$CustomAutoUnattendBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Title="Select AutoUnattend.xml file"
    Multiselect = $false
    Filter = 'XML Files (*.xml)|*.xml'
}

Function Copy_Progression ($Files,$Partition,$fs) {
    [long]$TotalBytes = ($Files | measure -Sum length).Sum
    [long]$Total1 = 0
    $index = 0
    $FilesCount = $Files.Count
    $StopWatch1 = [Diagnostics.Stopwatch]::StartNew()
    $Buffer = New-Object Byte[] (4MB)

    $MainProgressBar.Visible = $True
    $ProgressLabel.Visible = $True
    $ProgressLabel.Text = "File copying process is starting..."
    $MainProgressBar.Value = 0

    ForEach ($File in $Files) {
        $FileFullName = $File.fullname
        [long]$FileLength = $File.Length
        $index++
        $DestFile = $partition+$FileFullName.Substring($Global:iso.length)
        $DestDir= Split-Path $DestFile -Parent

        if (!(Test-Path $DestDir)){New-Item -ItemType Directory "$DestDir" -Force >$Null}
        $SourceFile = [io.file]::OpenRead($FileFullName)
        $DestinationFile = [io.file]::Create($DestFile)

        $OutputTextBox.AppendText("$index/$FilesCount - $(Split-Path $FileFullName -Leaf) is being copied...`r`n")
        $OutputTextBox.ScrollToCaret()

        $StopWatch2 = [Diagnostics.Stopwatch]::StartNew()
        [long]$Total2 = [long]$Count = 0

        do {
            $Count = $SourceFile.Read($buffer, 0, $buffer.Length)
            $DestinationFile.Write($buffer, 0, $Count)
            $Total2 += $Count
            $Total1 += $Count

            $CompletionRate1 = $Total1 / $TotalBytes * 100
            [int]$MSElapsed = [int]$StopWatch1.ElapsedMilliseconds
            if (($Total1 -ne $TotalBytes) -and ($Total1 -ne 0)) {
                [int]$RemainingSeconds1 = $MSElapsed * ($TotalBytes / $Total1  - 1) / 1000
            } else {[int]$RemainingSeconds1 = 0}

            $MainProgressBar.Value = [math]::Min(100, [math]::Max(0, [int]$CompletionRate1))
            $ProgressLabel.Text = "Completed: {0:F1}% - {1} minutes {2} seconds remaining" -f $CompletionRate1,[math]::Truncate($RemainingSeconds1/60),($RemainingSeconds1%60)

            $Form.Refresh()
            [System.Windows.Forms.Application]::DoEvents()

        } while ($Count -gt 0)

        $StopWatch2.Stop()
        $StopWatch2.Reset()
        $SourceFile.Close()
        $DestinationFile.Close()

        $OutputTextBox.AppendText("$(Split-Path $FileFullName -Leaf) completed.`r`n")
        $OutputTextBox.ScrollToCaret()
    }

    $MainProgressBar.Value = 100
    $ProgressLabel.Text = "File copying process completed!"
    $OutputTextBox.AppendText("All files copied successfully.`r`n")
    $OutputTextBox.ScrollToCaret()

    $StopWatch1.Stop()
    $StopWatch1.Reset()
    $Buffer=$Null
}

Function Show_Error ($message) {
    $OutputTextBox.AppendText("ERROR: $message`r`n")
    $OutputTextBox.ScrollToCaret()
    $MainProgressBar.Visible = $False
    $ProgressLabel.Visible = $False
    $ProgressLabel.Text = "An error occurred!"
    $ProcessRunning = $False
    Enable_Controls
}

Function Update_bcd ($partition){
    bcdedit /store $partition\boot\bcd /set '{default}' bootmenupolicy Legacy >$Null
    bcdedit /store $partition\EFI\Microsoft\boot\bcd /set '{default}' bootmenupolicy Legacy >$Null
    remove-item "$partition\boot\bcd.*" -force -ErrorAction SilentlyContinue
    remove-item "$partition\EFI\Microsoft\boot\bcd.*" -force -ErrorAction SilentlyContinue
}

Function Disable_Controls {
    $TabControl.Enabled = $False
    $SelectISOButton.Enabled = $False
    $USBDiskList.Enabled = $False
    $Windows.Enabled = $False
    $Wintogo.Enabled = $False
    $OKButton.Enabled = $False
    $ExitButton.Text = "Exit"
    $BypassTPMCheckbox.Enabled = $False
    $SelectAutoUnattendButton.Enabled = $False
    $Global:ProcessRunning = $True
    $WTGSelectButton.Enabled = $False
}

Function Enable_Controls {
    $TabControl.Enabled = $True
    $SelectISOButton.Enabled = $True
    $USBDiskList.Enabled = $True
    if ($WTGListBox.Visible -eq $True) { # If Windows To Go version selection is visible
        $Windows.Enabled = $False
        $Wintogo.Enabled = $True
        $BypassTPMCheckbox.Enabled = $False
		$USBDiskList.Enabled = $False
    } else {
        $Windows.Enabled = $True
        $Wintogo.Enabled = $True
        if ($Windows.Checked) {
            $BypassTPMCheckbox.Enabled = $True
            if (!$BypassTPMCheckbox.Checked) {
                $SelectAutoUnattendButton.Enabled = $True
                $ClearAutoUnattendButton.Enabled = $True
            } else {
                $SelectAutoUnattendButton.Enabled = $False
                $ClearAutoUnattendButton.Enabled = $True
            }
        } else {
            $BypassTPMCheckbox.Enabled = $False
            $SelectAutoUnattendButton.Enabled = $False
            $ClearAutoUnattendButton.Enabled = $True
        }
    }
    $Global:ProcessRunning = $False
    if (!$Wintogo.Checked) {
        $WTGSelectButton.Enabled = $False
    } else {
        if ($WTGListBox.Visible -eq $True) {
            $WTGSelectButton.Enabled = $True
        } else {
            $WTGSelectButton.Enabled = $False
        }
    }
}

Function Start_Process {
    if ($ProcessRunning) { return }

    # Get confirmation
    $result = [System.Windows.Forms.MessageBox]::Show(
        "The USB device will be converted to MBR schema, repartitioned and formatted.`n`nAll partitions and data currently on the USB device will be deleted.`n`nAre you sure you want to continue?",
        "WARNING",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($result -eq [System.Windows.Forms.DialogResult]::No) { return }

    Disable_Controls

    $OutputTextBox.Clear()
    $OutputTextBox.AppendText("Process is starting...`r`n")
    $OutputTextBox.ScrollToCaret()

    try {
        # ISO mounting
        if($Global:dvd){
            $OutputTextBox.AppendText("Mounting and checking ISO image...`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            # Check if ISO is already mounted, get drive letter
            If($Global:ISO = (Get-DiskImage $Global:ImagePath|Get-Volume).DriveLetter){
                $Global:Mounted = $True
            }Else{
                # Mount ISO and get drive letter
                $Global:Mounted = $False
                If(!($Global:ISO = (Mount-DiskImage $Global:ImagePath|Get-Volume).DriveLetter)){
                    Show_Error "Failed to mount ISO file"
                    return
                }
            }
            $Global:ISO = $Global:ISO + ":"
        }Else{
            $Global:ISO = $Global:ImagePath
        }

        # Stop system service
        Stop-Service ShellHWDetection -ErrorAction SilentlyContinue >$Null
        $ProgressPreference="SilentlyContinue"
        $OutputTextBox.AppendText("Preparation operations completed.`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        # Clear USB disk
        $OutputTextBox.AppendText("Cleaning USB disk and converting to MBR partition scheme...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        "Select disk $Global:USB`nclean`nconvert MBR`nexit"|diskpart >$Null
        If($LASTEXITCODE -ne 0){
            Show_Error "Diskpart operations failed (Code: $LASTEXITCODE)"
            return
        }

        $OutputTextBox.AppendText("USB disk successfully cleaned and converted to MBR.`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        # Create FAT32 partition
        $OutputTextBox.AppendText("Creating FAT32 boot partition and marking as active...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        Try{
            If($Global:SetUp){
                $Global:usbfat32 = (New-Partition -DiskNumber $Global:usb -Size 1GB -AssignDriveLetter -IsActive|
                    Format-Volume -FileSystem FAT32 -NewFileSystemLabel "BOOT").DriveLetter + ":"
            } else {
                $Global:usbfat32 = (New-Partition -DiskNumber $Global:usb -Size 100MB -AssignDriveLetter -IsActive|
                    Format-Volume -FileSystem FAT32 -NewFileSystemLabel "SYSTEM").DriveLetter + ":"
            }
        }
        Catch{
            Show_Error "Failed to create FAT32 partition"
            return
        }

        $PartitionSize = (Get-Volume ($Global:usbfat32 -Replace ".$")).Size/1GB
        If($PartitionSize -eq 0){
            Show_Error "FAT32 partition size is 0 GB"
            return
        }

        $OutputTextBox.AppendText("FAT32 partition successfully created ($($PartitionSize.ToString("F2")) GB).`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        # File size check
        If($Global:SetUp){
            $Files32 = Get-ChildItem $Global:iso\boot, $Global:iso\efi, $Global:iso\sources\boot.wim, $Global:iso\bootmgr.*, $Global:iso\bootmgr -Recurse -File -Force
            $FilesSize = ($Files32 | measure -Sum Length).Sum/1GB
            $OutputTextBox.AppendText("FAT32 file size check: $($FilesSize.ToString("F2")) GB required.`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            If ($FilesSize -gt $PartitionSize){
                Show_Error "FAT32 partition is too small ($($PartitionSize.ToString("F2")) GB available, $($FilesSize.ToString("F2")) GB required)"
                return
            }

            $OutputTextBox.AppendText("FAT32 partition size is sufficient.`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()
        }

        # Create NTFS partition
        $OutputTextBox.AppendText("Creating NTFS setup partition...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        Try{
            If($Global:SetUp){$Label="Win Setup"} Else {$Label="Windows To Go"}
            $Global:usbntfs = (New-Partition -DiskNumber $Global:usb -UseMaximumSize -AssignDriveLetter|
                Format-Volume -FileSystem NTFS -NewFileSystemLabel $Label).DriveLetter + ":"
        }
        Catch{
            Show_Error "Failed to create NTFS partition"
            return
        }

        $PartitionSize = (Get-Volume ($Global:usbntfs -Replace ".$")).Size/1GB
        If($PartitionSize -eq 0){
            Show_Error "NTFS partition size is 0 GB"
            return
        }

        $OutputTextBox.AppendText("NTFS partition successfully created ($($PartitionSize.ToString("F2")) GB).`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        # NTFS file size check
        If($Global:SetUp){
            $FilesNTFS = Get-ChildItem $Global:iso -Recurse -File -Force
            $FilesSize = ($FilesNTFS | measure -Sum Length).Sum/1GB
            $OutputTextBox.AppendText("NTFS file size check: $($FilesSize.ToString("F2")) GB required.`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            If($FilesSize -gt $PartitionSize){
                Show_Error "NTFS partition is too small ($($PartitionSize.ToString("F2")) GB available, $($FilesSize.ToString("F2")) GB required)"
                return
            }

            $OutputTextBox.AppendText("NTFS partition size is sufficient.`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()
        }

        Start-Service ShellHWDetection -erroraction silentlycontinue >$Null

        # File copying or image application
        If($Global:SetUp){
            $OutputTextBox.AppendText("Starting file copying process...`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            Copy_Progression $Files32 $Global:usbfat32 "FAT32"
            Copy_Progression $Filesntfs $Global:usbntfs "NTFS"

        } Else {
            # Windows To Go - Version selection in main GUI
            $OutputTextBox.AppendText("Reading version information for Windows To Go...`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            # ISO path debug
            $OutputTextBox.AppendText("ISO path: $Global:ISO`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            # Check if install.wim file exists
            $installWimPath = "$Global:ISO\Sources\Install.wim"
            $OutputTextBox.AppendText("Install.wim path: $installWimPath`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()

            if (!(Test-Path $installWimPath)) {
                Show_Error "Install.wim file not found: $installWimPath"
                return
            }

            try {
                $WindowsImages = Get-WindowsImage -ImagePath $installWimPath
                if ($WindowsImages.Count -gt 0) {
                    # Create list for version selection
                    $WTGListBox.Items.Clear()
                    foreach ($Image in $WindowsImages) {
                        $WTGListBox.Items.Add("$(($Image.ImageName).Trim()) (Index: $($Image.ImageIndex))")
                    }
                    $WTGListBox.SelectedIndex = 0
                    $WTGListBox.Visible = $True
                    $WTGSelectButton.Visible = $True
                    $OutputTextBox.AppendText("Select one of the listed Windows versions and click the 'Select' button.`r`n")
                    $OutputTextBox.ScrollToCaret()
                    return
                } else {
                    Show_Error "No Windows image found in the selected ISO file"
                    return
                }
            } catch {
                Show_Error "Error reading Windows image information: $($_.Exception.Message)"
                return
            }
        }

        # Update BCD
        $OutputTextBox.AppendText("Updating BCD...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()
        Update_BCD $Global:usbfat32

        # Hide drive letter
        $OutputTextBox.AppendText("Removing drive letter to hide FAT32 boot partition...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()
        Get-Volume ($Global:usbfat32 -replace ".$")|Get-Partition| Remove-PartitionAccessPath -accesspath $Global:usbfat32

        # Eject ISO
        If($Global:DVD){
            $OutputTextBox.AppendText("Ejecting mounted ISO image...`r`n")
            $OutputTextBox.ScrollToCaret()
            $Form.Refresh()
            If(!$Global:Mounted){DisMount-DiskImage $Global:ImagePath >$Null}
        }

        # Write additional files
        if ($Global:SetUp) {
            Write_Additional_Files $Global:usbntfs $Global:CustomAutoUnattendPath $Global:BypassTPM
        }

        # Completed
        $MainProgressBar.Value = 100
        $ProgressLabel.Text = "All operations completed successfully!"
        $OutputTextBox.AppendText("`r`n=== OPERATIONS COMPLETED ===`r`n")
        $OutputTextBox.AppendText("Disk successfully created!`r`n")
        $OutputTextBox.AppendText("You can safely eject the USB disk.`r`n")
        $OutputTextBox.ScrollToCaret()

    } catch {
        Show_Error "Unexpected error: $($_.Exception.Message)"
    } finally {
        Enable_Controls
    }
}

Function Apply_WTG_Image {
    Disable_Controls # Disable controls while Windows To Go process starts

    if (-not $WTGListBox.SelectedItem) {
        $OutputTextBox.AppendText("Please select a Windows version.`r`n")
        return
    }

    $WTGListBox.Visible = $False
    $WTGSelectButton.Visible = $False
    $WTGSelectButton.Enabled = $False

    $SelectedItem = $WTGListBox.SelectedItem
    [int]$SelectedIndex = $SelectedItem.ToString().Split('(')[1].Split(':')[1].TrimEnd(')')

    $OutputTextBox.AppendText("Applying Windows To Go image (Index: $SelectedIndex)...`r`n")
    $OutputTextBox.ScrollToCaret()
    $MainProgressBar.Visible = $True
    $ProgressLabel.Visible = $True
    $ProgressLabel.Text = "Applying Windows To Go image. This process may take a long time, please wait..."
    $MainProgressBar.Style = "Marquee"
    $MainProgressBar.MarqueeAnimationSpeed = 20
    $Form.Refresh()

    try {
        $installWimPath = "$Global:ISO\Sources\Install.wim"
        $jobScript = {param($installWimPath,$usbntfs,$index);Expand-WindowsImage -ImagePath $installWimPath -ApplyPath "$($usbntfs)\" -Index $index}
        $job=Start-Job $jobScript -ArgumentList $installWimPath, $Global:usbntfs, $SelectedIndex

        do {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100
        } until ($job.State -ne "Running")

        $MainProgressBar.Style = "Continuous"
        $MainProgressBar.Value = 100
        $ProgressLabel.Text = "Windows To Go image applied!"

        If($job.State -ne "Completed"){
            $jobError = Receive-Job -Job $job -ErrorAction SilentlyContinue
            Remove-Job -Job $job -Force
            Show_Error "An error occurred while applying the image: $jobError"
            return
        }

        Remove-Job -Job $job -Force
        $OutputTextBox.AppendText("Windows To Go image successfully applied.`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        # BCD settings
        $OutputTextBox.AppendText("Preparing BCD boot configuration...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()

        bcdboot $Global:usbntfs\windows /s $Global:usbfat32 /f ALL
        If(!(Test-Path $Global:usbfat32\bootmgr)){Copy-Item $Global:ISO\bootmgr $Global:usbfat32\bootmgr}
        If(!(Test-Path $Global:usbfat32\bootmgr.efi)){Copy-Item $Global:ISO\bootmgr $Global:usbfat32\bootmgr.efi}

        # Continue
        Continue_Process

    } catch {
        Show_Error "An error occurred while applying the Windows To Go image: $($_.Exception.Message)"
    }
}

Function Continue_Process {
    # Update BCD
    $OutputTextBox.AppendText("Updating BCD...`r`n")
    $OutputTextBox.ScrollToCaret()
    $Form.Refresh()
    Update_BCD $Global:usbfat32

    # Hide drive letter
    $OutputTextBox.AppendText("Removing drive letter to hide FAT32 boot partition...`r`n")
    $OutputTextBox.ScrollToCaret()
    $Form.Refresh()
    Get-Volume ($Global:usbfat32 -replace ".$")|Get-Partition| Remove-PartitionAccessPath -accesspath $Global:usbfat32

    # Eject ISO
    If($Global:DVD){
        $OutputTextBox.AppendText("Ejecting mounted ISO image...`r`n")
        $OutputTextBox.ScrollToCaret()
        $Form.Refresh()
        If(!$Global:Mounted){DisMount-DiskImage $Global:ImagePath >$Null}
    }

    # Write additional files (always false for Windows To Go)
    # Write_Additional_Files $Global:usbntfs $Global:CustomAutoUnattendPath

    # Completed
    $MainProgressBar.Value = 100
    $ProgressLabel.Text = "All operations completed successfully!"
    $OutputTextBox.AppendText("`r`n=== OPERATIONS COMPLETED ===`r`n")
    $OutputTextBox.AppendText("Disk successfully created!`r`n")
    $OutputTextBox.AppendText("You can safely eject the USB disk.`r`n")
    $OutputTextBox.ScrollToCaret()

    Enable_Controls
}

Function Write_Additional_Files($usbntfs, $customPath, $bypassTPM) {
    $OutputTextBox.AppendText("Writing additional files...`r`n")
    $OutputTextBox.ScrollToCaret()

    # AutoUnattend.xml and auto.cmd files
    $targetAutoUnattend = Join-Path $usbntfs "AutoUnattend.xml"
    $targetauto = Join-Path $usbntfs "auto.cmd"

# https://github.com/AveYo/MediaCreationTool.bat/blob/main/bypass11/AutoUnattend.xml
# AutoUnattend.xml Base64 encode
$base64AutoUnattend = @"
PHVuYXR0ZW5kIHhtbG5zPSJ1cm46c2NoZW1hcy1taWNyb3NvZnQtY29tOnVuYXR0ZW5kIj4NCiAgPHNldHRpbmdzIHBhc3M9IndpbmRvd3NQRSI+PGNvbXBvbmVudCBuYW1lPSJNaWNyb3NvZnQtV2luZG93cy1TZXR1cCIgcHJvY2Vzc29yQXJjaGl0ZWN0dXJlPSJhbWQ2NCIgbGFuZ3VhZ2U9Im5ldXRyYWwiDQogICB4bWxuczp3Y209Imh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vV01JQ29uZmlnLzIwMDIvU3RhdGUiIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiDQogICBwdWJsaWNLZXlUb2tlbj0iMzFiZjM4NTZhZDM2NGUzNSIgdmVyc2lvblNjb3BlPSJub25TeFMiPg0KICAgIDxVc2VyRGF0YT48UHJvZHVjdEtleT48S2V5PkFBQUFBLVZWVlZWLUVFRUVFLVlZWVlZLU9PT09PPC9LZXk+PFdpbGxTaG93VUk+T25FcnJvcjwvV2lsbFNob3dVST48L1Byb2R1Y3RLZXk+PC9Vc2VyRGF0YT4NCiAgICA8Q29tcGxpYW5jZUNoZWNrPjxEaXNwbGF5UmVwb3J0Pk5ldmVyPC9EaXNwbGF5UmVwb3J0PjwvQ29tcGxpYW5jZUNoZWNrPjxEaWFnbm9zdGljcz48T3B0SW4+ZmFsc2U8L09wdEluPjwvRGlhZ25vc3RpY3M+DQogICAgPER5bmFtaWNVcGRhdGU+PEVuYWJsZT50cnVlPC9FbmFibGU+PFdpbGxTaG93VUk+TmV2ZXI8L1dpbGxTaG93VUk+PC9EeW5hbWljVXBkYXRlPjxFbmFibGVOZXR3b3JrPnRydWU8L0VuYWJsZU5ldHdvcms+DQogICAgPFJ1blN5bmNocm9ub3VzPg0KICAgICAgPCEtLSBTa2lwIDExIENoZWNrcyBvbiBCb290IHZpYSByZWcgLSB1bnJlbGlhYmxlIHZzIHdpbnNldHVwLmRsbCBwYXRjaCB1c2VkIGluIE1lZGlhQ3JlYXRpb25Ub29sLmJhdCAtLT4NCiAgICAgIDxSdW5TeW5jaHJvbm91c0NvbW1hbmQgd2NtOmFjdGlvbj0iYWRkIj48T3JkZXI+MTwvT3JkZXI+DQogICAgICAgIDxQYXRoPnJlZyBhZGQgSEtMTVxTWVNURU1cU2V0dXBcTGFiQ29uZmlnIC92IEJ5cGFzc1RQTUNoZWNrIC9kIDEgL3QgcmVnX2R3b3JkIC9mPC9QYXRoPjwvUnVuU3luY2hyb25vdXNDb21tYW5kPg0KICAgICAgPFJ1blN5bmNocm9ub3VzQ29tbWFuZCB3Y206YWN0aW9uPSJhZGQiPjxPcmRlcj4yPC9PcmRlcj4NCiAgICAgICAgPFBhdGg+cmVnIGFkZCBIS0xNXFNZU1RFTVxTZXR1cFxMYWJDb25maWcgL3YgQnlwYXNzU2VjdXJlQm9vdENoZWNrIC9kIDEgL3QgcmVnX2R3b3JkIC9mPC9QYXRoPjwvUnVuU3luY2hyb25vdXNDb21tYW5kPg0KICAgICAgPFJ1blN5bmNocm9ub3VzQ29tbWFuZCB3Y206YWN0aW9uPSJhZGQiPjxPcmRlcj4zPC9PcmRlcj4NCiAgICAgICAgPFBhdGg+cmVnIGFkZCBIS0xNXFNZU1RFTVxTZXR1cFxMYWJDb25maWcgL3YgQnlwYXNzUkFNQ2hlY2sgL2QgMSAvdCByZWdfZHdvcmQgL2Y8L1BhdGg+PC9SdW5TeW5jaHJvbm91c0NvbW1hbmQ+DQogICAgICA8UnVuU3luY2hyb25vdXNDb21tYW5kIHdjbTphY3Rpb249ImFkZCI+PE9yZGVyPjQ8L09yZGVyPg0KICAgICAgICA8UGF0aD5yZWcgYWRkIEhLTE1cU1lTVEVNXFNldHVwXExhYkNvbmZpZyAvdiBCeXBhc3NTdG9yYWdlQ2hlY2sgL2QgMSAvdCByZWdfZHdvcmQgL2Y8L1BhdGg+PC9SdW5TeW5jaHJvbm91c0NvbW1hbmQ+DQogICAgICA8UnVuU3luY2hyb25vdXNDb21tYW5kIHdjbTphY3Rpb249ImFkZCI+PE9yZGVyPjU8L09yZGVyPg0KICAgICAgICA8UGF0aD5yZWcgYWRkIEhLTE1cU1lTVEVNXFNldHVwXExhYkNvbmZpZyAvdiBCeXBhc3NDUFVDaGVjayAvZCAxIC90IHJlZ19kd29yZCAvZjwvUGF0aD48L1J1blN5bmNocm9ub3VzQ29tbWFuZD4NCiAgICA8L1J1blN5bmNocm9ub3VzPg0KICA8L2NvbXBvbmVudD48L3NldHRpbmdzPiAgDQogIDxzZXR0aW5ncyBwYXNzPSJzcGVjaWFsaXplIj48Y29tcG9uZW50IG5hbWU9Ik1pY3Jvc29mdC1XaW5kb3dzLURlcGxveW1lbnQiIHByb2Nlc3NvckFyY2hpdGVjdHVyZT0iYW1kNjQiIGxhbmd1YWdlPSJuZXV0cmFsIg0KICAgeG1sbnM6d2NtPSJodHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29tL1dNSUNvbmZpZy8yMDAyL1N0YXRlIiB4bWxuczp4c2k9Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvWE1MU2NoZW1hLWluc3RhbmNlIg0KICAgcHVibGljS2V5VG9rZW49IjMxYmYzODU2YWQzNjRlMzUiIHZlcnNpb25TY29wZT0ibm9uU3hTIj4NCiAgICA8UnVuU3luY2hyb25vdXM+DQogICAgICA8IS0tIG9mZmxpbmUgbG9jYWwgYWNjb3VudCB2aWEgT09CRVxCWVBBU1NOUk8gb24gZXZlcnkgc2l0ZSBidXQgbGl0ZXJhbGx5IG5vIG9uZSBjcmVkaXRzIEF2ZVlvIGZvciBzaGFyaW5nIGl0IC0tPg0KICAgICAgPFJ1blN5bmNocm9ub3VzQ29tbWFuZCB3Y206YWN0aW9uPSJhZGQiPjxPcmRlcj4xPC9PcmRlcj4NCiAgICAgICAgPFBhdGg+cmVnIGFkZCBIS0xNXFNPRlRXQVJFXE1pY3Jvc29mdFxXaW5kb3dzXEN1cnJlbnRWZXJzaW9uXE9PQkUgL3YgQnlwYXNzTlJPIC90IHJlZ19kd29yZCAvZCAxIC9mPC9QYXRoPg0KICAgICAgPC9SdW5TeW5jaHJvbm91c0NvbW1hbmQ+DQogICAgICA8IS0tIGhpZGUgdW5zdXBwb3J0ZWQgbmFnIG9uIHVwZGF0ZSBzZXR0aW5ncyAtIDI1SDEgaXMgbm90IGEgdHlwbyA7KSAtLT4NCiAgICAgIDxSdW5TeW5jaHJvbm91c0NvbW1hbmQgd2NtOmFjdGlvbj0iYWRkIj48T3JkZXI+MjwvT3JkZXI+DQogICAgICAgIDxQYXRoPnJlZyBhZGQgSEtMTVxTT0ZUV0FSRVxQb2xpY2llc1xNaWNyb3NvZnRcV2luZG93c1xXaW5kb3dzVXBkYXRlIC92IFRhcmdldFJlbGVhc2VWZXJzaW9uIC9kIDEgL3QgcmVnX2R3b3JkIC9mPC9QYXRoPg0KICAgICAgPC9SdW5TeW5jaHJvbm91c0NvbW1hbmQ+DQogICAgICA8UnVuU3luY2hyb25vdXNDb21tYW5kIHdjbTphY3Rpb249ImFkZCI+PE9yZGVyPjM8L09yZGVyPg0KICAgICAgICA8UGF0aD5yZWcgYWRkIEhLTE1cU09GVFdBUkVcUG9saWNpZXNcTWljcm9zb2Z0XFdpbmRvd3NcV2luZG93c1VwZGF0ZSAvdiBUYXJnZXRSZWxlYXNlVmVyc2lvbkluZm8gL2QgMjVIMSAvZjwvUGF0aD4NCiAgICAgIDwvUnVuU3luY2hyb25vdXNDb21tYW5kPg0KICAgIDwvUnVuU3luY2hyb25vdXM+DQogIDwvY29tcG9uZW50Pjwvc2V0dGluZ3M+DQogIDxzZXR0aW5ncyBwYXNzPSJvb2JlU3lzdGVtIj48Y29tcG9uZW50IG5hbWU9Ik1pY3Jvc29mdC1XaW5kb3dzLVNoZWxsLVNldHVwIiBwcm9jZXNzb3JBcmNoaXRlY3R1cmU9ImFtZDY0IiBsYW5ndWFnZT0ibmV1dHJhbCIgDQogICB4bWxuczp3Y209Imh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vV01JQ29uZmlnLzIwMDIvU3RhdGUiIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiDQogICBwdWJsaWNLZXlUb2tlbj0iMzFiZjM4NTZhZDM2NGUzNSIgdmVyc2lvblNjb3BlPSJub25TeFMiPg0KICAgIDxPT0JFPg0KICAgICAgPEhpZGVMb2NhbEFjY291bnRTY3JlZW4+ZmFsc2U8L0hpZGVMb2NhbEFjY291bnRTY3JlZW4+PEhpZGVPbmxpbmVBY2NvdW50U2NyZWVucz5mYWxzZTwvSGlkZU9ubGluZUFjY291bnRTY3JlZW5zPg0KICAgICAgPEhpZGVXaXJlbGVzc1NldHVwSW5PT0JFPmZhbHNlPC9IaWRlV2lyZWxlc3NTZXR1cEluT09CRT48UHJvdGVjdFlvdXJQQz4zPC9Qcm90ZWN0WW91clBDPg0KICAgIDwvT09CRT4gIA0KICAgIDxGaXJzdExvZ29uQ29tbWFuZHM+DQogICAgICA8IS0tIGhpZGUgdW5zdXBwb3J0ZWQgbmFnIG9uIGRlc2t0b3AgLSBvcmlnaW5hbGx5IHNoYXJlZCBieSBhd3VjdGwgQCBNREwgLS0+DQogICAgICA8U3luY2hyb25vdXNDb21tYW5kIHdjbTphY3Rpb249ImFkZCI+PE9yZGVyPjE8L09yZGVyPg0KICAgICAgICA8Q29tbWFuZExpbmU+cmVnIGFkZCAiSEtDVVxDb250cm9sIFBhbmVsXFVuc3VwcG9ydGVkSGFyZHdhcmVOb3RpZmljYXRpb25DYWNoZSIgL3YgU1YxIC9kIDAgL3QgcmVnX2R3b3JkIC9mPC9Db21tYW5kTGluZT4NCiAgICAgIDwvU3luY2hyb25vdXNDb21tYW5kPjxTeW5jaHJvbm91c0NvbW1hbmQgd2NtOmFjdGlvbj0iYWRkIj48T3JkZXI+MjwvT3JkZXI+DQogICAgICAgIDxDb21tYW5kTGluZT5yZWcgYWRkICJIS0NVXENvbnRyb2wgUGFuZWxcVW5zdXBwb3J0ZWRIYXJkd2FyZU5vdGlmaWNhdGlvbkNhY2hlIiAvdiBTVjIgL2QgMCAvdCByZWdfZHdvcmQgL2Y8L0NvbW1hbmRMaW5lPg0KICAgICAgPC9TeW5jaHJvbm91c0NvbW1hbmQ+DQogICAgPC9GaXJzdExvZ29uQ29tbWFuZHM+DQogIDwvY29tcG9uZW50Pjwvc2V0dGluZ3M+DQo8L3VuYXR0ZW5kPg==
"@ -replace '\s',''

# https://github.com/lzw29107/MediaCreationTool.bat/blob/main/bypass11/auto.cmd
# auto.cmd Base64 encode
$base64auto = @"
QGVjaG8gb2ZmJiB0aXRsZSBBdXRvIFVwZ3JhZGUgLSBNQ1QgfHwgIHN1cHBvcnRzIFVsdGltYXRlIC8gUG9zUmVhZHkgLyBFbWJlZGRlZCAvIExUU0MgLyBFbnRlcnByaXNlIEV2YWwNCnNldCAiRURJVElPTl9TV0lUQ0g9Ig0Kc2V0ICJTS0lQXzExX1NFVFVQX0NIRUNLUz0xIg0Kc2V0IE9QVElPTlM9L1NlbGZIb3N0IC9BdXRvIFVwZ3JhZGUgL01pZ0Nob2ljZSBVcGdyYWRlIC9Db21wYXQgSWdub3JlV2FybmluZyAvTWlncmF0ZURyaXZlcnMgQWxsIC9SZXNpemVSZWNvdmVyeVBhcnRpdGlvbiBEaXNhYmxlDQpzZXQgT1BUSU9OUz0lT1BUSU9OUyUgL1Nob3dPT0JFIE5vbmUgL1RlbGVtZXRyeSBEaXNhYmxlIC9Db21wYWN0T1MgRGlzYWJsZSAvRHluYW1pY1VwZGF0ZSBFbmFibGUgL1NraXBTdW1tYXJ5IC9FdWxhIEFjY2VwdA0KDQpwdXNoZCAiJX5kcDAiICYgZm9yICUldyBpbiAoJTEpIGRvIHB1c2hkICUldw0KZm9yICUlaSBpbiAoIng4NlwiICJ4NjRcIiAiIikgZG8gaWYgZXhpc3QgIiUlfmlzb3VyY2VzXHNldHVwcHJlcC5leGUiIHNldCAiZGlyPSUlfmkiDQpwdXNoZCAiJWRpciVzb3VyY2VzIiB8fCAoZWNobyAiJWRpciVzb3VyY2VzIiBub3QgZm91bmQhIHNjcmlwdCBzaG91bGQgYmUgcnVuIGZyb20gd2luZG93cyBzZXR1cCBtZWRpYSAmIHRpbWVvdXQgL3QgNSAmIGV4aXQgL2IpDQoNCjo6IyBzdGFydCBzb3VyY2VzXHNldHVwIGlmIHVuZGVyIHdpbnBlICh3aGVuIGJvb3RlZCBmcm9tIG1lZGlhKSBbU2hpZnRdICsgW0YxMF06IGM6XGF1dG8gb3IgZDpcYXV0byBvciBlOlxhdXRvIGV0Yy4NCnJlZyBxdWVyeSAiSEtMTVxTb2Z0d2FyZVxNaWNyb3NvZnRcV2luZG93cyBOVFxDdXJyZW50VmVyc2lvblxXaW5QRSI+bnVsIDI+bnVsICYmICgNCiBmb3IgJSVzIGluIChzQ1BVIHNSQU0gc1NlY3VyZUJvb3Qgc1N0b3JhZ2Ugc1RQTSkgZG8gcmVnIGFkZCBIS0xNXFNZU1RFTVxTZXR1cFxMYWJDb25maWcgL2YgL3YgQnlwYXMlJXNDaGVjayAvZCAxIC90IHJlZ19kd29yZA0KIHN0YXJ0ICJXaW5QRSIgc291cmNlc1xzZXR1cC5leGUgJiBleGl0IC9iIA0KKSANCg0KOjojIGluaXQgdmFyaWFibGVzDQpzZXRsb2NhbCBFbmFibGVEZWxheWVkRXhwYW5zaW9uDQpzZXQgIlBBVEg9JVN5c3RlbVJvb3QlXFN5c3RlbTMyOyVTeXN0ZW1Sb290JVxTeXN0ZW0zMlx3aW5kb3dzcG93ZXJzaGVsbFx2MS4wXDslUEFUSCUiDQpzZXQgIlBBVEg9JVN5c3RlbVJvb3QlXFN5c25hdGl2ZTslU3lzdGVtUm9vdCVcU3lzbmF0aXZlXHdpbmRvd3Nwb3dlcnNoZWxsXHYxLjBcOyVQQVRIJSINCg0KOjojIGVsZXZhdGUgc28gdGhhdCB3b3JrYXJvdW5kcyBjYW4gYmUgc2V0IHVuZGVyIHdpbmRvd3MNCmZsdG1jID5udWwgfHwgKHNldCBfPSIlfmYwIiAlKiYgcG93ZXJzaGVsbCAtbm9wIC1jIHN0YXJ0IC12ZXJiIHJ1bmFzIGNtZCBcIi9kIC94IC9jIGNhbGwgJGVudjpfXCImIGV4aXQgL2IpDQoNCjo6IyB1bmRvIGFueSBwcmV2aW91cyByZWdlZGl0IGVkaXRpb24gcmVuYW1lIChpZiB1cGdyYWRlIHdhcyBpbnRlcnJ1cHRlZCkNCnNldCAiTlQ9SEtMTVxTT0ZUV0FSRVxNaWNyb3NvZnRcV2luZG93cyBOVFxDdXJyZW50VmVyc2lvbiINCmZvciAlJXYgaW4gKENvbXBvc2l0aW9uRWRpdGlvbklEIEVkaXRpb25JRCBQcm9kdWN0TmFtZSkgZG8gKA0KIGNhbGwgOnJlZ19xdWVyeSAiJU5UJSIgJSV2X3VuZG8gJSV2DQogaWYgZGVmaW5lZCAlJXYgcmVnIGRlbGV0ZSAiJU5UJSIgL3YgJSV2X3VuZG8gL2YgJiBmb3IgJSVBIGluICgzMiA2NCkgZG8gcmVnIGFkZCAiJU5UJSIgL3YgJSV2IC9kICIhJSV2ISIgL2YgL3JlZzolJUEgDQopID5udWwgMj5udWwNCg0KOjojIGdldCBjdXJyZW50IHZlcnNpb24NCmZvciAlJXYgaW4gKENvbXBvc2l0aW9uRWRpdGlvbklEIEVkaXRpb25JRCBQcm9kdWN0TmFtZSBDdXJyZW50QnVpbGROdW1iZXIpIGRvIGNhbGwgOnJlZ19xdWVyeSAiJU5UJSIgJSV2ICUldg0KZm9yIC9mICJ0b2tlbnM9Mi0zIGRlbGltcz1bLiIgJSVpIGluICgndmVyJykgZG8gZm9yICUlcyBpbiAoJSVpKSBkbyBzZXQgL2EgVmVyc2lvbj0lJXMqMTArJSVqDQoNCjo6IyBXSU1fSU5GTyB3XzU9d2ltXzV0aCBiXzU9YnVpbGRfNXRoIHBfNT1wYXRjaF81dGggYV81PWFyY2hfNXRoIGxfNT1sYW5nXzV0aCBlXzU9ZWRpXzV0aCBkXzU9ZGVzY181dGggaV81PWVkaV81dGggaV9Db3JlPWluZGV4DQpzZXQgIjA9JX5mMCImIHNldCB3aW09JiBzZXQgZXh0PS5lc2QmIGlmIGV4aXN0IGluc3RhbGwud2ltIChzZXQgZXh0PS53aW0pIGVsc2UgaWYgZXhpc3QgaW5zdGFsbC5zd20gc2V0IGV4dD0uc3dtDQpzZXQgc25pcHBldD1wb3dlcnNoZWxsIC1ub3AgLWMgaWV4IChbaW8uZmlsZV06OlJlYWRBbGxUZXh0KCRlbnY6MCktc3BsaXQnI1s6XXdpbV9pbmZvWzpdJylbMV07IFdJTV9JTkZPIGluc3RhbGwlZXh0JSAwIDAgIA0Kc2V0IHdfY291bnQ9MCYgZm9yIC9mICJ0b2tlbnM9MS03IGRlbGltcz0sIiAlJWkgaW4gKCciJXNuaXBwZXQlIicpIGRvIChzZXQgd18lJWk9JSVpLCUlaiwlJWssJSVsLCUlbSwlJW4sJSVvJiBzZXQgL2Egd19jb3VudCs9MQ0Kc2V0IGJfJSVpPSUlaiYgc2V0IHBfJSVpPSUlayYgc2V0IGFfJSVpPSUlbCYgc2V0IGxfJSVpPSUlbSYgc2V0IGVfJSVpPSUlbiYgc2V0IGRfJSVpPSUlbyYgc2V0IGlfJSVuPSUlaSYgc2V0IGlfJSVpPSUlbikNCg0KOjojIHByaW50IGF2YWlsYWJsZSBlZGl0aW9ucyBpbiBpbnN0YWxsLmVzZCB2aWEgd2ltX2luZm8gc25pcHBldA0KZWNobzstLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0NCmZvciAvbCAlJWkgaW4gKDEsMSwld19jb3VudCUpIGRvIGNhbGwgZWNobzslJXdfJSVpJSUNCmVjaG87LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tDQoNCjo6IyBnZXQgcmVxdWVzdGVkIGVkaXRpb24gaW4gRUkuY2ZnIG9yIFBJRC50eHQgb3IgT1BUSU9OUw0KaWYgZXhpc3QgcHJvZHVjdC5pbmkgZm9yIC9mICJ0b2tlbnM9MSwyIGRlbGltcz09IiAlJU8gaW4gKHByb2R1Y3QuaW5pKSBkbyBpZiBub3QgIiUlUCIgZXF1ICIiIChzZXQgcGlkXyUlTz0lJVAmIHNldCBwbl8lJVA9JSVPKQ0Kc2V0IEVJPSYgc2V0IE5hbWU9JiBzZXQgZUlEPSYgc2V0IHJlZz0mIHNldCAiY2ZnX2ZpbHRlcj1FZGl0aW9uSUQgQ2hhbm5lbCBPRU0gUmV0YWlsIFZvbHVtZSBfRGVmYXVsdCBWTCAwIDEgXiQiDQppZiBleGlzdCBFSS5jZmcgZm9yIC9mICJ0b2tlbnM9KiIgJSVpIGluICgnZmluZHN0ciAvdiAvaSAvciAiJWNmZ19maWx0ZXIlIiBFSS5jZmcnKSBkbyAoc2V0IEVJPSUlaSYgc2V0IGVJRD0lJWkpDQppZiBleGlzdCBQSUQudHh0IGZvciAvZiAiZGVsaW1zPTsiICUlaSBpbiAoUElELnR4dCkgZG8gc2V0ICUlaSAyPm51bA0KaWYgbm90IGRlZmluZWQgVmFsdWUgZm9yICUlcyBpbiAoJU9QVElPTlMlKSBkbyBpZiBkZWZpbmVkIHBuXyUlcyAoc2V0IE5hbWU9IXBuXyUlcyEmIHNldCBOYW1lPSFOYW1lOmd2bGs9ISkNCmlmIGRlZmluZWQgVmFsdWUgaWYgbm90IGRlZmluZWQgTmFtZSBmb3IgJSVzIGluICglVmFsdWUlKSBkbyAoc2V0IE5hbWU9IXBuXyUlcyEmIHNldCBOYW1lPSFOYW1lOmd2bGs9ISkNCmlmIGRlZmluZWQgRURJVElPTl9TV0lUQ0ggKHNldCBlSUQ9JUVESVRJT05fU1dJVENIJSkgZWxzZSBpZiBkZWZpbmVkIE5hbWUgZm9yICUlcyBpbiAoJU5hbWUlKSBkbyAoc2V0IGVJRD0lTmFtZSUpDQppZiBub3QgZGVmaW5lZCBlSUQgc2V0IGVJRD0lRWRpdGlvbklEJSYgaWYgbm90IGRlZmluZWQgRWRpdGlvbklEIHNldCBlSUQ9UHJvZmVzc2lvbmFsJiBzZXQgRWRpdGlvbklEPVByb2Zlc3Npb25hbA0KaWYgL2kgIiVFZGl0aW9uSUQlIiBlcXUgIiVlSUQlIiAoc2V0IGNoYW5nZWQ9KSBlbHNlIHNldCBjaGFuZ2VkPTENCg0KOjojIHVwZ3JhZGUgbWF0cml4IC0gbm93IGFsc28gZm9yIEVudGVycHJpc2UgRXZhbCAtIGF1dG9tYXRpY2FsbHkgcGljayBlZGl0aW9uIHRoYXQgd291bGQga2VlcCBmaWxlcyBhbmQgYXBwcw0KaWYgL2kgQ29yZUNvdW50cnlTcGVjaWZpYyBlcXUgJWVJRCUgc2V0ICJjb21wPSFlSUQhIiAmIHNldCAicmVnPSFlSUQhIiAmIGlmIG5vdCBkZWZpbmVkIGlfIWVJRCEgc2V0ICJlSUQ9Q29yZSINCmlmIC9pIENvcmVTaW5nbGVMYW5ndWFnZSAgZXF1ICVlSUQlIHNldCAiY29tcD1Db3JlIiAgJiBzZXQgInJlZz0hZUlEISIgJiBpZiBub3QgZGVmaW5lZCBpXyFlSUQhIHNldCAiZUlEPUNvcmUiDQpmb3IgJSVlIGluIChTdGFydGVyIEhvbWVCYXNpYyBIb21lUHJlbWl1bSBDb3JlQ29ubmVjdGVkQ291bnRyeVNwZWNpZmljIENvcmVDb25uZWN0ZWRTaW5nbGVMYW5ndWFnZSBDb3JlQ29ubmVjdGVkIENvcmUpIGRvICgNCiBpZiAvaSAlJWUgIGVxdSAlZUlEJSBzZXQgImNvbXA9Q29yZSIgICYgc2V0ICJlSUQ9Q29yZSINCiBpZiAvaSAlJWVOIGVxdSAlZUlEJSBzZXQgImNvbXA9Q29yZU4iICYgc2V0ICJlSUQ9Q29yZU4iDQogaWYgL2kgJSVlICBlcXUgJWVJRCUgaWYgbm90IGRlZmluZWQgaV9Db3JlICBzZXQgImVJRD1Qcm9mZXNzaW9uYWwiICAmIGlmIG5vdCBkZWZpbmVkIHJlZyBzZXQgInJlZz1Db3JlIg0KIGlmIC9pICUlZU4gZXF1ICVlSUQlIGlmIG5vdCBkZWZpbmVkIGlfQ29yZU4gc2V0ICJlSUQ9UHJvZmVzc2lvbmFsTiIgJiBpZiBub3QgZGVmaW5lZCByZWcgc2V0ICJyZWc9Q29yZU4iDQopDQpmb3IgJSVlIGluIChVbHRpbWF0ZSBQcm9mZXNzaW9uYWxTdHVkZW50IFByb2Zlc3Npb25hbENvdW50cnlTcGVjaWZpYyBQcm9mZXNzaW9uYWxTaW5nbGVMYW5ndWFnZSkgZG8gKA0KICBpZiAvaSAlJWUgZXF1ICVlSUQlIChzZXQgImVJRD1Qcm9mZXNzaW9uYWwiKSBlbHNlIGlmIC9pICUlZU4gZXF1ICVlSUQlIHNldCAiZUlEPVByb2Zlc3Npb25hbE4iDQopDQpmb3IgJSVlIGluIChFbnRlcnByaXNlRyBFbnRlcnByaXNlUyBJb1RFbnRlcnByaXNlUyBJb1RFbnRlcnByaXNlIEVtYmVkZGVkKSBkbyAoDQogIGlmIC9pICUlZSBlcXUgJWVJRCUgKHNldCAiZUlEPUVudGVycHJpc2UiKSBlbHNlIGlmIC9pICUlZU4gZXF1ICVlSUQlIHNldCAiZUlEPUVudGVycHJpc2VOIg0KKQ0KZm9yICUlZSBpbiAoRW50ZXJwcmlzZSBFbnRlcnByaXNlUykgZG8gKA0KICBpZiAvaSAlJWVFdmFsIGVxdSAlZUlEJSAoc2V0ICJlSUQ9RW50ZXJwcmlzZSIpIGVsc2UgaWYgL2kgJSVlTkV2YWwgZXF1ICVlSUQlIHNldCAiZUlEPUVudGVycHJpc2VOIg0KKQ0KaWYgL2kgRW50ZXJwcmlzZSAgZXF1ICVlSUQlIHNldCAiY29tcD0hZUlEISIgJiBpZiBub3QgZGVmaW5lZCBpXyFlSUQhIHNldCAiZUlEPVByb2Zlc3Npb25hbCIgICYgc2V0ICJyZWc9IWNvbXAhIg0KaWYgL2kgRW50ZXJwcmlzZU4gZXF1ICVlSUQlIHNldCAiY29tcD0hZUlEISIgJiBpZiBub3QgZGVmaW5lZCBpXyFlSUQhIHNldCAiZUlEPVByb2Zlc3Npb25hbE4iICYgc2V0ICJyZWc9IWNvbXAhIg0KZm9yICUlZSBpbiAoRWR1Y2F0aW9uIFByb2Zlc3Npb25hbEVkdWNhdGlvbiBQcm9mZXNzaW9uYWxXb3Jrc3RhdGlvbiBQcm9mZXNzaW9uYWwgQ2xvdWQpIGRvICgNCiAgaWYgL2kgJSVlTiBlcXUgJWVJRCUgc2V0ICJjb21wPUVudGVycHJpc2VOIiAgJiBpZiBub3QgZGVmaW5lZCByZWcgc2V0ICJyZWc9JSVlTiINCiAgaWYgL2kgJSVlICBlcXUgJWVJRCUgc2V0ICJjb21wPUVudGVycHJpc2UiICAgJiBpZiBub3QgZGVmaW5lZCByZWcgc2V0ICJyZWc9JSVlIg0KICBpZiAvaSAlJWVOIGVxdSAlZUlEJSBzZXQgImVJRD1Qcm9mZXNzaW9uYWxOIiAmIGlmIGRlZmluZWQgaV8lJWVOICBzZXQgImVJRD0lJWVOIg0KICBpZiAvaSAlJWUgIGVxdSAlZUlEJSBzZXQgImVJRD1Qcm9mZXNzaW9uYWwiICAmIGlmIGRlZmluZWQgaV8lJWUgICBzZXQgImVJRD0lJWUiDQopDQpzZXQgaW5kZXg9JiBzZXQgbHN0PVByb2Zlc3Npb25hbCYgZm9yIC9sICUlaSBpbiAoMSwxLCV3X2NvdW50JSkgZG8gaWYgL2kgIWlfJSVpISBlcXUgIWVJRCEgc2V0ICJpbmRleD0lJWkiICYgc2V0ICJlSUQ9IWlfJSVpISIgDQppZiBub3QgZGVmaW5lZCBpbmRleCBzZXQgaW5kZXg9MSYgc2V0IGVJRD0haV8xISYgaWYgZGVmaW5lZCBpXyVsc3QlIHNldCAiaW5kZXg9IWlfJWxzdCUhIiAmIHNldCAiZUlEPSVsc3QlIiYgc2V0ICJjb21wPUVudGVycHJpc2UiDQpzZXQgQnVpbGQ9IWJfJWluZGV4JSEmIHNldCBPUFRJT05TPSVPUFRJT05TJSAvSW1hZ2VJbmRleCAlaW5kZXglJiBpZiBkZWZpbmVkIGNoYW5nZWQgaWYgbm90IGRlZmluZWQgcmVnIHNldCAicmVnPSFlSUQhIg0KZWNobztDdXJyZW50IGVkaXRpb246ICVFZGl0aW9uSUQlICYgZWNobztSZWdlZGl0IGVkaXRpb246ICVyZWclICYgZWNobztJbmRleDogJWluZGV4JSAgSW1hZ2U6ICVlSUQlDQp0aW1lb3V0IC90IDEwDQoNCjo6IyBkaXNhYmxlIHVwZ3JhZGUgYmxvY2tzDQpyZWcgYWRkICJIS0xNXFNPRlRXQVJFXFBvbGljaWVzXE1pY3Jvc29mdFxXaW5kb3dzXFdpbmRvd3NVcGRhdGUiIC9mIC92IERpc2FibGVXVWZCU2FmZWd1YXJkcyAvZCAxIC90IHJlZ19kd29yZCA+bnVsIDI+bnVsICANCg0KOjojIHByZXZlbnQgdXNhZ2Ugb2YgTUNUIGZvciBpbnRlcm1lZGlhcnkgdXBncmFkZSBpbiBEeW5hbWljIFVwZGF0ZSAoY2F1c2luZyA3IHRvIDE5SDEgaW5zdGVhZCBvZiA3IHRvIDIxSDIgZm9yIGV4YW1wbGUpIA0KaWYgIiVCdWlsZCUiIGd0ciAiMTUwNjMiIChzZXQgT1BUSU9OUz0lT1BUSU9OUyUgL1VwZGF0ZU1lZGlhIERlY2xpbmUpDQoNCjo6IyBza2lwIHdpbmRvd3MgMTEgdXBncmFkZSBjaGVja3M6IGFkZCBsYXVuY2ggb3B0aW9uIHRyaWNrIGlmIG9sZC1zdHlsZSAwLWJ5dGUgZmlsZSB0cmljayBpcyBub3Qgb24gdGhlIG1lZGlhICANCmlmICIlQnVpbGQlIiBsc3MgIjIyMDAwIiBzZXQgL2EgU0tJUF8xMV9TRVRVUF9DSEVDS1M9MA0KcmVnIGFkZCBIS0xNXFNZU1RFTVxTZXR1cFxNb1NldHVwIC9mIC92IEFsbG93VXBncmFkZXNXaXRoVW5zdXBwb3J0ZWRUUE1vckNQVSAvZCAxIC90IHJlZ19kd29yZCA+bnVsIDI+bnVsICZyZW0gOjojIFRQTSAxLjIrIG9ubHkNCmlmICIlU0tJUF8xMV9TRVRVUF9DSEVDS1MlIiBlcXUgIjEiIGNkLj5hcHByYWlzZXJyZXMuZGxsIDI+bnVsICYgcmVtIDo6IyB3cml0YWJsZSBtZWRpYSBvbmx5DQpmb3IgJSVBIGluIChhcHByYWlzZXJyZXMuZGxsKSBkbyBpZiAlJX56QSBndHIgMCAoc2V0IFRSSUNLPS9Qcm9kdWN0IFNlcnZlciApIGVsc2UgKHNldCBUUklDSz0pDQppZiAiJVNLSVBfMTFfU0VUVVBfQ0hFQ0tTJSIgZXF1ICIxIiAoc2V0IE9QVElPTlM9JVRSSUNLJSVPUFRJT05TJSkNCg0KOjojIGF1dG8gdXBncmFkZSB3aXRoIGVkaXRpb24gbGllIHdvcmthcm91bmQgdG8ga2VlcCBmaWxlcyBhbmQgYXBwcyAtIGFsbCAxOTA0eCBidWlsZHMgYWxsb3cgdXAvZG93bmdyYWRlIGJldHdlZW4gdGhlbQ0KaWYgZGVmaW5lZCByZWcgY2FsbCA6cmVuYW1lICVyZWclDQpzdGFydCAiYXV0byIgc2V0dXBwcmVwLmV4ZSAlT1BUSU9OUyUNCmVjaG87RE9ORQ0KDQpFWElUIC9iDQoNCjpyZW5hbWUgRWRpdGlvbklEDQpzZXQgIk5UPUhLTE1cU09GVFdBUkVcTWljcm9zb2Z0XFdpbmRvd3MgTlRcQ3VycmVudFZlcnNpb24iDQpmb3IgJSV2IGluIChDb21wb3NpdGlvbkVkaXRpb25JRCBFZGl0aW9uSUQgUHJvZHVjdE5hbWUpIGRvIHJlZyBhZGQgIiVOVCUiIC92ICUldl91bmRvIC9kICIhJSV2ISIgL2YgPm51bCAyPm51bA0KZm9yICUlQSBpbiAoMzIgNjQpIGRvICggDQogcmVnIGFkZCAiJU5UJSIgL3YgQ29tcG9zaXRpb25FZGl0aW9uSUQgL2QgIiVjb21wJSIgL2YgL3JlZzolJUENCiByZWcgYWRkICIlTlQlIiAvdiBFZGl0aW9uSUQgL2QgIiV+MSIgL2YgL3JlZzolJUENCiByZWcgYWRkICIlTlQlIiAvdiBQcm9kdWN0TmFtZSAvZCAiJX4xIiAvZiAvcmVnOiUlQQ0KKSA+bnVsIDI+bnVsDQpleGl0IC9iDQoNCjpyZWdfcXVlcnkgW1VTQUdFXSBjYWxsIDpyZWdfcXVlcnkgIkhLQ1VcVm9sYXRpbGUgRW52aXJvbm1lbnQiIFZhbHVlIHZhcmlhYmxlDQooZm9yIC9mICJ0b2tlbnM9MioiICUlUiBpbiAoJ3JlZyBxdWVyeSAiJX4xIiAvdiAiJX4yIiAvc2UgInwiICU0IDJePm51bCcpIGRvIHNldCAiJX4zPSUlUyIpICYgZXhpdCAvYg0KDQojOldJTV9JTkZPOiMgW1BBUkFNU106ICJmaWxlIiBbb3B0aW9uYWxdSW5kZXggb3IgMCA9IGFsbCAgT3V0cHV0IDAgPSB0eHQgMSA9IHhtbCAyID0gZmlsZS50eHQgMyA9IGZpbGUueG1sIDQgPSB4bWwgb2JqZWN0DQpzZXQgXiAjPTskZjA9W2lvLmZpbGVdOjpSZWFkQWxsVGV4dCgkZW52OjApOyAkMD0oJGYwLXNwbGl0ICcjWzpdV0lNX0lORk9bOl0nICwzKVsxXTsgJDE9JGVudjoxLXJlcGxhY2UnKFtgQCRdKScsJ2AkMSc7IGlleCgkMCskMSkNCnNldCBeICM9JiBzZXQgIjA9JX5mMCImIHNldCAxPTtXSU1fSU5GTyAlKiYgcG93ZXJzaGVsbCAtbm9wIC1jICIlIyUiJiBleGl0IC9iICVlcnJvcmNvZGUlDQpmdW5jdGlvbiBXSU1fSU5GTyAoJGZpbGUgPSAnaW5zdGFsbC5lc2QnLCAkaW5kZXggPSAwLCAkb3V0ID0gMCkgeyA6aW5mbyB3aGlsZSAoJHRydWUpIHsNCiAgJGJsb2NrID0gMjA5NzE1MjsgJGJ5dGVzID0gbmV3LW9iamVjdCAnQnl0ZVtdJyAoJGJsb2NrKTsgJGJlZ2luID0gW3VpbnQ2NF0wOyAkZmluYWwgPSBbdWludDY0XTA7ICRsaW1pdCA9IFt1aW50NjRdMA0KICAkc3RlcHMgPSBbaW50XShbdWludDY0XShbSU8uRmlsZUluZm9dJGZpbGUpLkxlbmd0aCAvICRibG9jayAtIDEpOyAkZW5jID0gW1RleHQuRW5jb2RpbmddOjpHZXRFbmNvZGluZygyODU5MSk7ICRkZWxpbSA9IEAoKQ0KICBmb3JlYWNoICgkZCBpbiAnL0lOU1RBTExBVElPTlRZUEUnLCcvV0lNJykgeyRkZWxpbSArPSAkZW5jLkdldFN0cmluZyhbVGV4dC5FbmNvZGluZ106OlVuaWNvZGUuR2V0Qnl0ZXMoW2NoYXJdNjArICRkICtbY2hhcl02MikpfQ0KICAkZiA9IG5ldy1vYmplY3QgSU8uRmlsZVN0cmVhbSAoJGZpbGUsIDMsIDEsIDEpOyAkcCA9IDA7ICRwID0gJGYuU2VlaygwLCAyKQ0KICBmb3IgKCRvID0gMTsgJG8gLWxlICRzdGVwczsgJG8rKykgeyANCiAgICAkcCA9ICRmLlNlZWsoLSRibG9jaywgMSk7ICRyID0gJGYuUmVhZCgkYnl0ZXMsIDAsICRibG9jayk7IGlmICgkciAtbmUgJGJsb2NrKSB7d3JpdGUtaG9zdCBpbnZhbGlkIGJsb2NrICRyOyBicmVha30NCiAgICAkdSA9IFtUZXh0LkVuY29kaW5nXTo6R2V0RW5jb2RpbmcoMjg1OTEpLkdldFN0cmluZygkYnl0ZXMpOyAkdCA9ICR1Lkxhc3RJbmRleE9mKCRkZWxpbVswXSwgW1N0cmluZ0NvbXBhcmlzb25dOjpPcmRpbmFsKSANCiAgICBpZiAoJHQgLWx0IDApIHsgJHAgPSAkZi5TZWVrKC0kYmxvY2ssIDEpfSBlbHNlIHsgW3ZvaWRdJGYuU2VlaygoJHQgLSRibG9jayksIDEpDQogICAgICBmb3IgKCRvID0gMTsgJG8gLWxlICRibG9jazsgJG8rKykgeyBbdm9pZF0kZi5TZWVrKC0yLCAxKTsgaWYgKCRmLlJlYWRCeXRlKCkgLWVxIDB4ZmUpIHskYmVnaW4gPSAkZi5Qb3NpdGlvbjsgYnJlYWt9IH0NCiAgICAgICRsaW1pdCA9ICRmLkxlbmd0aCAtICRiZWdpbjsgaWYgKCRsaW1pdCAtbHQgJGJsb2NrKSB7JHggPSAkbGltaXR9IGVsc2UgeyR4ID0gJGJsb2NrfQ0KICAgICAgJGJ5dGVzID0gbmV3LW9iamVjdCAnQnl0ZVtdJyAoJHgpOyAkciA9ICRmLlJlYWQoJGJ5dGVzLCAwLCAkeCkgDQogICAgICAkdSA9IFtUZXh0LkVuY29kaW5nXTo6R2V0RW5jb2RpbmcoMjg1OTEpLkdldFN0cmluZygkYnl0ZXMpOyAkdCA9ICR1LkluZGV4T2YoJGRlbGltWzFdLCBbU3RyaW5nQ29tcGFyaXNvbl06Ok9yZGluYWwpDQogICAgICBpZiAoJHQgLWdlIDApIHtbdm9pZF0kZi5TZWVrKCgkdCArIDEyIC0keCksIDEpOyAkZmluYWwgPSAkZi5Qb3NpdGlvbn0gOyBicmVhayB9IH0NCiAgaWYgKCRiZWdpbiAtZ3QgMCAtYW5kICRmaW5hbCAtZ3QgJGJlZ2luKSB7DQogICAgJHggPSAkZmluYWwgLSAkYmVnaW47IFt2b2lkXSRmLlNlZWsoLSR4LCAxKTsgJGJ5dGVzID0gbmV3LW9iamVjdCAnQnl0ZVtdJyAoJHgpOyAkciA9ICRmLlJlYWQoJGJ5dGVzLCAwLCAkeCkNCiAgICBpZiAoJHIgLW5lICR4KSB7JGYuRGlzcG9zZSgpOyBicmVha30gZWxzZSB7W3htbF0keG1sID0gW1RleHQuRW5jb2RpbmddOjpVbmljb2RlLkdldFN0cmluZygkYnl0ZXMpOyAkZi5EaXNwb3NlKCl9DQogIH0gZWxzZSB7JGYuRGlzcG9zZSgpfSA7IGJyZWFrIDppbmZvIH0NCiAgaWYgKCRvdXQgLWVxIDEpIHtbY29uc29sZV06Ok91dHB1dEVuY29kaW5nPVtUZXh0LkVuY29kaW5nXTo6VVRGODsgJHhtbC5TYXZlKFtDb25zb2xlXTo6T3V0KTsgJyc7IHJldHVybn0gDQogIGlmICgkb3V0IC1lcSAzKSB7dHJ5eyR4bWwuU2F2ZSgoJGZpbGUtcmVwbGFjZSdlc2QkJywneG1sJykpfWNhdGNoe307IHJldHVybn07IGlmICgkb3V0IC1lcSA0KSB7cmV0dXJuICR4bWx9DQogICR0eHQgPSAnJzsgZm9yZWFjaCAoJGkgaW4gJHhtbC5XSU0uSU1BR0UpIHtpZiAoJGluZGV4IC1ndCAwIC1hbmQgJCgkaS5JTkRFWCkgLW5lICRpbmRleCkge2NvbnRpbnVlfTsgW2ludF0kYT0nMScrJGkuV0lORE9XUy5BUkNIDQogICR0eHQrPSAkaS5JTkRFWCsnLCcrJGkuV0lORE9XUy5WRVJTSU9OLkJVSUxEKycsJyskaS5XSU5ET1dTLlZFUlNJT04uU1BCVUlMRCsnLCcrJChAezEwPSd4ODYnOzE1PSdhcm0nOzE5PSd4NjQnOzExMj0nYXJtNjQnfVskYV0pDQogICR0eHQrPSAnLCcrJGkuV0lORE9XUy5MQU5HVUFHRVMuTEFOR1VBR0UrJywnKyRpLldJTkRPV1MuRURJVElPTklEKycsJyskaS5OQU1FK1tjaGFyXTEzK1tjaGFyXTEwfTsgJHR4dD0kdHh0LXJlcGxhY2UnLCg/PSwpJywnLCAnDQogIGlmICgkb3V0IC1lcSAyKSB7dHJ5e1tpby5maWxlXTo6V3JpdGVBbGxUZXh0KCgkZmlsZS1yZXBsYWNlJ2VzZCQnLCd0eHQnKSwkdHh0KX1jYXRjaHt9OyByZXR1cm59OyBpZiAoJG91dCAtZXEgMCkge3JldHVybiAkdHh0fQ0KfSAjOldJTV9JTkZPOiMgUXVpY2sgV0lNIFNXTSBFU0QgSVNPIGluZm8gdjIgLSBsZWFuIGFuZCBtZWFuIHNuaXBwZXQgYnkgQXZlWW8sIDIwMjE=
"@ -replace '\s',''

    $hasInstallImage = Get-Item "$usbntfs\sources\install.*" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'install\.(wim|esd)$' }

    if ($hasInstallImage) {
        if ($customPath -ne "" -and (Test-Path $customPath)) {
            try {
                Copy-Item $customPath $targetAutoUnattend -Force
                $OutputTextBox.AppendText("Custom AutoUnattend.xml file copied.`r`n")
            } catch {
                $OutputTextBox.AppendText("Error copying custom AutoUnattend.xml file: $($_.Exception.Message)`r`n")
                # Fallback to base64 content if copying fails
                if ($bypassTPM) {
                    [IO.File]::WriteAllBytes($targetAutoUnattend, [Convert]::FromBase64String($base64AutoUnattend))
                    $OutputTextBox.AppendText("Default AutoUnattend.xml content written (in case of error).`r`n")
                }
            }
        } else {
            if ($bypassTPM) {
                [IO.File]::WriteAllBytes($targetAutoUnattend, [Convert]::FromBase64String($base64AutoUnattend))
                $OutputTextBox.AppendText("AutoUnattend.xml file written.`r`n")
            }
        }
        if ($bypassTPM) {
            [IO.File]::WriteAllBytes($targetauto, [Convert]::FromBase64String($base64auto))
            $OutputTextBox.AppendText("auto.cmd file written.`r`n")
        }
    }
    $OutputTextBox.ScrollToCaret()
}

# Administrator control
If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    If($param -eq "UAC_ERROR"){
        [System.Windows.Forms.MessageBox]::Show("UAC elevation for Administrator privileges failed!`n`nRight-click on the script and select 'Run as administrator'.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        exit
    }

    If($ScriptPath.Length -gt 0){
        Start-Process "$ScriptPath" "UAC_ERROR" -Verb runAs; exit
    }

    If($PSCommandPath.Length -gt 0){
        Start-Process PowerShell -Verb runAs -ArgumentList "-f ""$PSCommandPath"" ""UAC_ERROR"""; exit
    }

    $ScriptPath = [Environment]::GetCommandLineArgs()[0]
    Start-Process "$ScriptPath" "UAC_ERROR" -Verb runAs; exit
}

# Main Form
$Form = New-Object System.Windows.Forms.Form -Property @{
    TopMost = $True; ShowIcon = $True; ControlBox = $True
    ForeColor = "White"; BackColor = "Gray"; Font = 'Consolas,10'
    Text = "$Title"; Width = $Width; Height = $Height
    StartPosition = "CenterScreen"; SizeGripStyle = "Hide"
    ShowInTaskbar = $True; MaximizeBox = $False; # User extension action blocked
    MinimizeBox = $True # Added minimize icon
    FormBorderStyle = 'FixedSingle' # Prevents the user from changing the window size
}

# File browser
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Title="Select install.wim/esd in the ISO image or extracted source folder"
    Multiselect = $false
    Filter = 'ISO images (*.iso;*install.wim;*install.esd)|*.iso;*install.wim;*install.esd'
}

# USB disk control
do {
    $FromDiskDrive = Get-CimInstance Win32_DiskDrive | Where-Object {
        $_.InterfaceType -eq 'USB' -or
        $_.MediaType -match 'External' -or
        $_.Model -match 'VHD|Virtual|Sanal' -or
        $_.Caption -match 'VHD|Virtual|Sanal' -or
        $_.PNPDeviceID -match 'VHD|MSFT'
    }

    if ($FromDiskDrive.Count -eq 0) {
        $result = [System.Windows.Forms.MessageBox]::Show("No disk found.`n`nPlease connect or attach your disk first.", "Warning", [System.Windows.Forms.MessageBoxButtons]::RetryCancel, [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) { exit }
        Start-Sleep -Seconds 2
    } else {
        break
    }
} while ($true)

$Disks = $FromDiskDrive

# Tab control
$TabControl = New-Object System.Windows.Forms.TabControl -Property @{
    Location = New-Object System.Drawing.Point(10, 10)
    Size = New-Object System.Drawing.Size(460, 330)
}

# Main tab
$MainTab = New-Object System.Windows.Forms.TabPage -Property @{
    Text = "Main Menu"
    BackColor = "Gray"
    ForeColor = "White"
}

# How to use tab
$HowToTab = New-Object System.Windows.Forms.TabPage -Property @{
    Text = "How to Use?"
    BackColor = "Gray"
    ForeColor = "White"
}

$HowToText = New-Object System.Windows.Forms.RichTextBox -Property @{
    Location = New-Object System.Drawing.Point(10, 10)
    Size = New-Object System.Drawing.Size(430, 290)
    BackColor = "Gray"
    ForeColor = "White"
    ReadOnly = $True
    BorderStyle = "None"
    Font = "Arial,9"
    Text = @"
1- Connect your USB device.

2- Click the Windows ISO button and select the ISO file or the install.wim/esd file in the extracted folder.
ATTENTION: The esd file causes an error in the Windows To Go process.

3- Select "Target USB Disk" from the dropdown menu.

4- Select the "Windows Setup Disk" or "Windows To Go" option.

5- If you selected "Windows Setup Disk", you can optionally check the "Bypass Windows 11 system requirements" option.

6- Optionally, you can select your own automatic installation file using the "Select Custom AutoUnattend.xml File" button.

7- Click "Create Disk" to create a Windows Setup Disk or Windows To Go environment.
"@
}
$HowToTab.Controls.Add($HowToText)

# Output text box
$OutputTextBox = New-Object System.Windows.Forms.TextBox -Property @{
    Location = New-Object System.Drawing.Point(10, 350)
    Size = New-Object System.Drawing.Size(460, 130)
    Multiline = $True
    ScrollBars = "Vertical"
    ReadOnly = $True
    BackColor = "Black"
    ForeColor = "White"
    Font = "Consolas,9"
    BorderStyle = "FixedSingle"
}

# Progress bar
$MainProgressBar = New-Object System.Windows.Forms.ProgressBar -Property @{
    Location = New-Object System.Drawing.Point(10, 490)
    Size = New-Object System.Drawing.Size(460, 25)
    Minimum = 0
    Maximum = 100
    Value = 0
    Style = "Continuous"
    Visible = $False
}

# Progress label
$ProgressLabel = New-Object System.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Point(10, 520)
    Size = New-Object System.Drawing.Size(460, 20)
    Text = ""
    ForeColor = "White"
    BackColor = "Gray"
    Font = "Arial,9"
    TextAlign = "MiddleCenter"
    Visible = $False
}

# ISO file path
$Label1 = New-Object System.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Point(20, 15)
    Size = New-Object System.Drawing.Size(400, 20)
    Text = "Windows (ISO or extracted source folder)"
    ForeColor = "White"
    BackColor = "Gray"
}

$ISOFile = New-Object System.Windows.Forms.TextBox -Property @{
    Location = New-Object System.Drawing.Point(20,35)
    Size = New-Object System.Drawing.Size(410,24)
    BackColor = "White"; ForeColor = "Black"
    ReadOnly = $True
    BorderStyle = "FixedSingle"
}

# Target USB disk
$TargetUSB = New-Object System.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Point(20,80)
    Text = "Target USB Disk"
    Size = New-Object System.Drawing.Size(200,20)
    ForeColor = "White"
    BackColor = "Gray"
}

$USBDiskList = New-Object System.Windows.Forms.ComboBox -Property @{
    DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    Location = New-Object System.Drawing.Point(20,100)
    Size = New-Object System.Drawing.Size(410,22)
}

# Radio buttons
$Windows = New-Object System.Windows.Forms.RadioButton -Property @{
    Location = New-Object System.Drawing.Point(50,155)
    Text = "Windows Setup Disk"
    Size = New-Object System.Drawing.Size(190,20)
    Checked = $True
    ForeColor = "White"
    BackColor = "Gray"
}

$Wintogo = New-Object System.Windows.Forms.RadioButton -Property @{
    Location = New-Object System.Drawing.Point(280,155)
    Text = "Windows To Go"
    Size = New-Object System.Drawing.Size(140,20)
    Checked = $False
    ForeColor = "White"
    BackColor = "Gray"
}

# Checkbox
$BypassTPMCheckbox = New-Object System.Windows.Forms.CheckBox -Property @{
    Location = New-Object System.Drawing.Point(65, 180)
    Text = "Bypass Windows 11 system requirements"
    Size = New-Object System.Drawing.Size(330, 20)
    ForeColor = "White"
    BackColor = "Gray"
    Enabled = $True
}

# AutoUnattend Select button
$SelectAutoUnattendButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(45,210)
    Text = "Select Custom Unattend.xml File"
    Size = New-Object System.Drawing.Size(275,30)
    Enabled = $True
}

# Clear button
$ClearAutoUnattendButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(325, 210)
    Text = "Clear"
    Size = New-Object System.Drawing.Size(80, 30)
    Enabled = $True # Always on at startup
}

$ToolTip = New-Object System.Windows.Forms.ToolTip
$ToolTip.Active = $True
$ToolTip.ShowAlways = $True
$ToolTip.SetToolTip($ClearAutoUnattendButton, "Refreshes USB Disk List and clears user selections. `nIt is recommended to use this button before starting a new process.")


# WTG List (hidden)
$WTGListBox = New-Object System.Windows.Forms.ListBox -Property @{
    Location = New-Object System.Drawing.Point(10, 200)
    Size = New-Object System.Drawing.Size(360, 100)
    Visible = $False
}

# Buttons
$SelectISOButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(45,250)
    Text = "Windows ISO"
    Size = New-Object System.Drawing.Size(110,26)
}

$OKButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(160, 250)
    Size = New-Object System.Drawing.Size(160, 26)
    Text = "Create Disk"
    Enabled = $False
}

$ExitButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(325, 250)
    Size = New-Object System.Drawing.Size(80, 26)
    Text = "Exit"
}

$WTGSelectButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(360, 210)
    Size = New-Object System.Drawing.Size(100, 70)
    Text = "Select"
    Visible = $False
}

# Populate USB disk list
$USBDisks=@()
Foreach ($Disk in $Disks){
    $FriendlyName = ($Disk.Caption).PadRight(40).substring(0,35)
    $USBDisks+=$Disk.Index
    $USBDiskList.Items.Add(("{0,-30}{1,10:n2} GB" -f $FriendlyName,($Disk.Size/1GB))) >$Null
}
$USBDiskList.SelectedIndex = 0

# Event handlers
$SelectISOButton.Add_Click({
    If ($FileBrowser.ShowDialog() -ne "Cancel"){
        $Global:ImagePath = $FileBrowser.filename
        If($Global:ImagePath.Split(".")[-1] -eq "iso"){
            $Global:dvd = $True
            $ISOFile.Text = Split-Path -Path $Global:ImagePath -leaf
        }Else{
            $Global:dvd = $False
            $Global:ImagePath=Split-Path $Global:ImagePath -Parent|Split-Path -Parent
            $ISOFile.Text = $Global:ImagePath
        }
        if(($ISOFile.Text).length -gt 44){
            $ISOFile.Text = $Global:ImagePath.PadRight(100).substring(0,43)+"..."
        }
        $OKButton.Enabled = $True
        $OKButton.Focus()
    }
})

$OKButton.Add_Click({
    $Global:USB = $USBDisks[$USBDiskList.SelectedIndex]
    $Global:SetUp = $Windows.Checked
    $Global:BypassTPM = $BypassTPMCheckbox.Checked									
    Start_Process
})

$ExitButton.Add_Click({
    $Form.Close()
})

$WTGSelectButton.Add_Click({
    Apply_WTG_Image
})

$Form.Add_FormClosing({
    if ($Global:DVD -and $Global:Mounted) {
        try {
            Dismount-DiskImage -ImagePath $Global:ImagePath -ErrorAction SilentlyContinue
        } catch {
            # There is nothing to do in case of error.
        }
    }
})

# Clear button event handler
$ClearAutoUnattendButton.Add_Click({
    if (-not $Windows.Checked) {
        $Windows.Checked = $True
    }
    if ($BypassTPMCheckbox.Checked) {
        $BypassTPMCheckbox.Checked = $False
    }
    $Global:CustomAutoUnattendPath = ""
    $ISOFile.Text = ""
    $OKButton.Enabled = $False
	$BypassTPMCheckbox.Enabled = $True
    $ClearAutoUnattendButton.Enabled = $True
	$ProgressLabel.Text = ""
	$MainProgressBar.Visible = $False
	$OutputTextBox.Clear()
	$OutputTextBox.AppendText("`r`nReady`r`nSelect ISO file and click the 'Create Disk' button.`r`n")

    # Reload USB disk list
    $USBDiskList.Items.Clear()
    $FromDiskDrive = Get-CimInstance Win32_DiskDrive | Where-Object {
        $_.InterfaceType -eq 'USB' -or
        $_.MediaType -match 'External' -or
        $_.Model -match 'VHD|Virtual|Sanal' -or
        $_.Caption -match 'VHD|Virtual|Sanal' -or
        $_.PNPDeviceID -match 'VHD|MSFT'
    }
    $Disks = $FromDiskDrive
    $USBDisks=@()
    Foreach ($Disk in $Disks){
        $FriendlyName = ($Disk.Caption).PadRight(40).substring(0,35)
        $USBDisks+=$Disk.Index
        $USBDiskList.Items.Add(("{0,-30}{1,10:n2} GB" -f $FriendlyName,($Disk.Size/1GB))) >$Null
    }
    if ($USBDiskList.Items.Count -gt 0) {
        $USBDiskList.SelectedIndex = 0
    } else {
        $USBDiskList.SelectedIndex = -1
    }

    # If the Select Custom Unattend.xml file button is disabled, activate it and clear the selection.
    if ($SelectAutoUnattendButton.Enabled -eq $False) {
        $SelectAutoUnattendButton.Enabled = $True
    }
    $Global:CustomAutoUnattendPath = ""
    $SelectAutoUnattendButton.Text = "Select custom Unattend.xml file"
    $ClearAutoUnattendButton.Enabled = $True 
})

# AutoUnattend selection
$SelectAutoUnattendButton.Add_Click({
    if ($CustomAutoUnattendBrowser.ShowDialog() -ne "Cancel") {
        $Global:CustomAutoUnattendPath = $CustomAutoUnattendBrowser.FileName
        $SelectAutoUnattendButton.Text = "$($Global:CustomAutoUnattendPath.Split('\')[-1]) seçildi"
        $ClearAutoUnattendButton.Enabled = $True
		$BypassTPMCheckbox.Enabled = $False
    }
})

$Windows.Add_CheckedChanged({
    if ($Windows.Checked) {
        $BypassTPMCheckbox.Enabled = $True
        if (!$BypassTPMCheckbox.Checked) {
            $SelectAutoUnattendButton.Enabled = $True
            $ClearAutoUnattendButton.Enabled = $True
        } else {
            $SelectAutoUnattendButton.Enabled = $False
            $ClearAutoUnattendButton.Enabled = $True
        }
    } else {
        $BypassTPMCheckbox.Enabled = $False
        $SelectAutoUnattendButton.Enabled = $False
        $ClearAutoUnattendButton.Enabled = $True
    }
})

$BypassTPMCheckbox.Add_CheckedChanged({
    if ($Windows.Checked) {
        if ($BypassTPMCheckbox.Checked) {
            $SelectAutoUnattendButton.Enabled = $False
            $ClearAutoUnattendButton.Enabled = $True
            $Global:CustomAutoUnattendPath = ""
            $SelectAutoUnattendButton.Text = "Select custom Unattend.xml file"
        } else {
            $SelectAutoUnattendButton.Enabled = $True
            $ClearAutoUnattendButton.Enabled = $True
        }
    }
})

$Wintogo.Add_CheckedChanged({
    if ($Wintogo.Checked) {
        $BypassTPMCheckbox.Enabled = $False
        $SelectAutoUnattendButton.Enabled = $False
        $ClearAutoUnattendButton.Enabled = $True
        $Global:CustomAutoUnattendPath = ""
        $SelectAutoUnattendButton.Text = "Select custom Unattend.xml file"
    }
})

$TabControl.Controls.Add($MainTab)
$TabControl.Controls.Add($HowToTab)
$MainTab.Controls.Add($WTGListBox)
$MainTab.Controls.Add($WTGSelectButton)
$MainTab.Controls.Add($Label1)
$MainTab.Controls.Add($ISOFile)
$MainTab.Controls.Add($SelectISOButton)
$MainTab.Controls.Add($TargetUSB)
$MainTab.Controls.Add($USBDiskList)
$MainTab.Controls.Add($Windows)
$MainTab.Controls.Add($Wintogo)
$MainTab.Controls.Add($OKButton)
$MainTab.Controls.Add($ExitButton)
$MainTab.Controls.Add($BypassTPMCheckbox)
$MainTab.Controls.Add($SelectAutoUnattendButton)
$MainTab.Controls.Add($ClearAutoUnattendButton)
$Form.Controls.Add($TabControl)
$Form.Controls.Add($OutputTextBox)
$Form.Controls.Add($MainProgressBar)
$Form.Controls.Add($ProgressLabel)

$OutputTextBox.AppendText("`r`nReady`r`nSelect ISO file and click the 'Create Disk' button.`r`n")
$OutputTextBox.ScrollToCaret()

$Form.ShowDialog()
