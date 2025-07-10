<# : hybrid batch + powershell script
@powershell -noprofile -Window min -c "$param='%*';$ScriptPath='%~f0';iex((Get-Content('%~f0') -Raw))"&exit/b
#>
$OnlyUSBsticks="NO"
$Title = "Win10+ Setup Disk - Windows To Go"
$Host.UI.RawUI.BackgroundColor = "Blue"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host
#
#   Contributors: @rpo, @freddie-o, @BAU & @abbodi1406, @mephistooo2

#   Homepage: https://forums.mydigitallife.net/threads/win10-setup-disk-works-with-uefi-secure-boot-bios-install-wim-over-4-gb.79268/
#   https://forums.mydigitallife.net/threads/win10-setup-disk-works-with-uefi-secure-boot-bios-install-wim-over-4-gb.79268/page-24#post-1884180
#
#******************************************************************************
$host.ui.rawui.windowtitle = $title
Add-Type -AssemblyName System.Windows.Forms # Load the System.Windows.Forms class
[System.Windows.Forms.Application]::EnableVisualStyles()
$Width = 425; $Height = 270
#
#******************************************************************************
Add-Type -AssemblyName System.Windows.Forms # Load the System.Windows.Forms class
[System.Windows.Forms.Application]::EnableVisualStyles()
$Width = 425; $Height = 270
#
#******************************************************************************
Function Copy_Progression ($Files,$Partition,$fs) {
#
# suffix 1 : variables for general processing
# suffix 2 : variables for single file processing
[long]$TotalBytes = ($Files | measure -Sum length).Sum
[long]$Total1 = 0 # bytes completed
$index = 0
$FilesCount = $Files.Count
$StopWatch1 = [Diagnostics.Stopwatch]::StartNew()
$Buffer = New-Object Byte[] (4MB) # 4MB buffer
#
ForEach ($File in $Files) {
    $FileFullName = $File.fullname
    [long]$FileLength = $File.Length
    $index++
    # create the target path for this file (e.g., H:\sources\boot.wim)
    $DestFile = $partition+$FileFullName.Substring($iso.length)
    $DestDir= Split-Path $DestFile -Parent
    # if it doesn't exist, create it
    if (!(Test-Path $DestDir)){New-Item -ItemType Directory "$DestDir" -Force >$Null}
    $SourceFile = [io.file]::OpenRead($FileFullName)
    $DestinationFile = [io.file]::Create($DestFile)
    $FileLength=$File.Length
    $Sync.FileName="$($DestFile -Replace '^...')"
    $StopWatch2 = [Diagnostics.Stopwatch]::StartNew()
    [long]$Total2 = [long]$Count = 0
    $LastStopWatch = 0
    do {
        # copy 4MB of the source file to the target file
        $Count = $SourceFile.Read($buffer, 0, $buffer.Length)
        $DestinationFile.Write($buffer, 0, $Count)
        # this is just for write-progress
        # stopwatch is used to calculate remaining time
        $Total2 += $Count
        $Total1 += $Count
        #
        # General statistics
        #
        $CompletionRate1 = $Total1 / $TotalBytes * 100
        [int]$MSElapsed = [int]$StopWatch1.ElapsedMilliseconds
        if (($Total1 -ne $TotalBytes) -and ($Total1 -ne 0)) {
            [int]$RemainingSeconds1 = $MSElapsed * ($TotalBytes / $Total1  - 1) / 1000
        } else {[int]$RemainingSeconds1 = 0}
        $s="$Partition $FS {0,5} / {1,5} files  - {2,5} remaining" -f $index,$FilesCount,($FilesCount - $index)
        $s="$s{0,10:0} MB / {1,6:0} MB" -f ($Total1/1MB),($TotalBytes/1MB)
        $s="$s`r`n`r`nPercent complete = {0,3:0}%      {1,4} minutes {2,2} seconds remaining" -f $CompletionRate1,[math]::Truncate($RemainingSeconds1/60),($RemainingSeconds1%60)
        $Sync.Label1=$s
        $Sync.CompletionRate1 = $CompletionRate1
        #
        # Statistics for the current file
        #
        [int]$MSElapsed = [int]$StopWatch2.ElapsedMilliseconds
        if ($Count -ne 0) {
            $CompletionRate2 = $Total2 / $FileLength * 100
            [int]$RemainingSeconds2 = $MSElapsed * ($FileLength / $Total2  - 1) / 1000
            if ($MSElapsed -ge 1000) {
                [single]$xferrate = $Total2 / $MSElapsed / 1mb * 1000}
            else{[single]$xferrate = 0.0}
        }else {
            $CompletionRate2 = 100
            [int]$RemainingSeconds2 = 0
        }
        $s="Copying file @ {0,6:n2} MB/s" -f $xferrate
        $s="$s{0,16:0} MB / {1,6:0} MB" -f ($Total2/1MB),($filelength/1MB)
        $s="$s`r`n`r`nPercent complete = {0,3:0}%      {1,4} minutes {2,2} seconds remaining" -f $CompletionRate2,[math]::Truncate($RemainingSeconds2/60),($RemainingSeconds2%60)
        If (($CompletionRate2 -eq 100) -or (($MSElapsed - $LastStopWatch) -gt 1000)){
            $LastStopWatch = $MSElapsed
        }
        $Sync.Label2=$s
        $Sync.CompletionRate2 = $CompletionRate2
        $Sync.Flag = 1
    } while ($Count -gt 0)
    $StopWatch2.Stop()
    $StopWatch2.Reset()
    $SourceFile.Close()
    $DestinationFile.Close()
}
If($fs -eq "NTFS"){$Sync.Flag = -1}
$StopWatch1.Stop()
$StopWatch1.Reset()
$Buffer=$Null
#
}# End of Copy_With_Progression Function
#******************************************************************************
#
$Display_Error = {
    $Information.Hide()
    $Form.Controls.Clear()
    $Form.Controls.AddRange(@($OKButton, $Label1))
    $Label1.ForeColor = "Red"
    $Label1.BackColor = "White"
    $Label1.Location=New-Object System.Drawing.Point(10,80)
    $Label1.AutoSize = $True
    $OKButton.Location=New-Object System.Drawing.Point(170,185)
    $OKButton.Text = "Exit"
    $Form.Controls.Add($OKButton)
    [void]$Form.Showdialog()
    exit}
#
$Form = New-Object System.Windows.Forms.Form -Property @{ # Create the screen form (window)
    TopMost = $True; ShowIcon = $False; ControlBox = $False
    ForeColor = "White"; BackColor = "Blue"; Font = 'Consolas,10'
    Text = "$Title"; Width = $Width;Height = $Height
    StartPosition = "CenterScreen"; SizeGripStyle = "Hide"
    ShowInTaskbar = $False; MaximizeBox = $False; MinimizeBox = $False}
#
# Add an OK button to the form
$OKButton = New-Object System.Windows.Forms.Button  -Property @{
    Location = New-Object System.Drawing.Point(25,185)
    Size = New-Object System.Drawing.Size(80,26)
    DialogResult = "OK"}
$Form.Controls.Add($OKButton)
#
# Add Cancel button
$CancelButton = New-Object System.Windows.Forms.Button  -Property @{
    Location = New-Object System.Drawing.Point(300,185)
    Size = New-Object System.Drawing.Size(80,26)
    DialogResult = "Cancel"}
#
# Create label
$Label0 = New-Object system.Windows.Forms.Label  -Property @{
    Location = New-Object System.Drawing.Point(20,10)
    Size = New-Object System.Drawing.Size(365,25)
    Font = "Arial,12"; ForeColor = "Red"; BackColor = "White"}
#
$Label1 = New-Object system.Windows.Forms.Label  -Property @{
    Location = New-Object System.Drawing.Point(60,70)
    Size = New-Object System.Drawing.Size(380,150)}
#
# How to use
#
$HowTo= New-Object system.Windows.Forms.Form  -Property @{
    TopMost = $True; ShowIcon = $False; ControlBox = $False
    ShowInTaskbar = $False; Width = $Width;Height = $Height
    Font = "Arial,10"}
#
$HowToText = New-Object system.Windows.Forms.RichTextBox  -Property @{
    Location = New-Object System.Drawing.Point(10,30)
    Dock = "Fill"; BackColor = 'Blue'; ForeColor = 'White'}
$HowTo.Controls.Add($HowToText)
#
# Information window
#
$Information= New-Object system.Windows.Forms.Form  -Property @{
    TopMost = $True; ShowIcon = $False; ControlBox = $False
    Text = $Title
    ShowInTaskbar = $False; StartPosition = 'CenterScreen'
    Width = $Width; Height = $Height
    BackColor = 'Blue'; ForeColor = 'White'; Font = "Arial,12"}
#
$InformationText = New-Object system.Windows.Forms.RichTextBox  -Property @{
    Location = New-Object System.Drawing.Point(10,30)
    Dock = "Fill"; BackColor = 'Blue'; ForeColor = 'White'}
$Information.Controls.Add($InformationText)
#
# ********************************************************
#
# This script must be run as administrator
#
# Test administrator privileges
$uac_error="UAC elevation for Administrator privileges failed"
$Label1.Text = @"
$uac_error!`r`n`r`nRight-click on the script.
Select "Run as administrator".
"@
If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    # Test to prevent infinite loop when UAC elevation for Administrator privileges fails
    If($param -eq $uac_error){
        $Form.ForeColor = "Red"
        $Form.BackColor = "White"
        $Label1.Location = New-Object System.Drawing.Point(20,50)
        $Label1.Size = New-Object System.Drawing.Size(380,120)
        $OKButton.Location = New-Object System.Drawing.Point(200,185)
        $OKButton.Size = New-Object System.Drawing.Size(200,185)
        $OKButton.Text = "Exit"
        $Form.Controls.AddRange(@($OKButton, $Label1))
        [void]$Form.Showdialog()
        exit}
# Restart the script to get administrator privileges and exit
# 1. Try if it is a cmd script
    If($ScriptPath.Length -gt 0)
        {Start-Process "$ScriptPath" $uac_error -Verb runAs; exit}
# 2. Try if it is a ps1 script
    If($PSCommandPath.Length -gt 0)
        {Start-Process PowerShell -Verb runAs -ArgumentList "-f ""$PSCommandPath"" ""$uac_error"""; exit}
# 3. exe guess
    $ScriptPath = [Environment]::GetCommandLineArgs()[0]
    Start-Process "$ScriptPath" $uac_error -Verb runAs; exit
}
# ********************************************************
#
# File browser dialog object
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Title="Select install.wim/esd in the ISO image or extracted sources folder"
    Multiselect = $false                 # Only one file can be selected
    Filter = 'ISO images (*.iso;*install.wim;*install.esd)|*.iso;*install.wim;*install.esd' # Select only iso files
}
#
Function Update_bcd ($partition){
# Set bootmenupolicy to Legacy for $partition
bcdedit /store "$partition\boot\bcd" /set '{default}' bootmenupolicy Legacy >$Null
bcdedit /store "$partition\EFI\Microsoft\boot\bcd" /set '{default}' bootmenupolicy Legacy >$Null
remove-item "$partition\boot\bcd.*" -force
remove-item "$partition\EFI\Microsoft\boot\bcd.*" -force}
#

# --- Filter including VHD/VHDX support ---
$Form.Controls.Clear()
$Label0.Text = "No disk found."
$Label1.Text = "Please plug in or connect your disk first.`n`nRetry or Cancel."
$OKButton.Text = "Retry"
$OKButton.Width = 100
$CancelButton.Text = "Cancel"

do {
    # Find VHD or USB disks via DiskDrive
    $FromDiskDrive = Get-CimInstance Win32_DiskDrive | Where-Object {
        $_.InterfaceType -eq 'USB' -or
        $_.MediaType -match 'External' -or
        $_.Model -match 'VHD|Virtual|Sanal' -or
        $_.Caption -match 'VHD|Virtual|Sanal' -or
        $_.PNPDeviceID -match 'VHD|MSFT'
    }

    # Prompt user if both are empty
    if ($FromDiskDrive.Count -eq 0) {
        $Form.Controls.AddRange(@($OKButton, $CancelButton, $Label0, $Label1))
        if ($Form.ShowDialog() -eq "Cancel") { exit }
        Start-Sleep -Seconds 2
    } else {
        break
    }

} while ($true)

# Transfer the disk here
$Disks = $FromDiskDrive



#
# Add Source Windows ISO label
$Label1.Location = New-Object System.Drawing.Point(20,15)
$Label1.Size = New-Object System.Drawing.Size(400,20)
$Label1.Text = "Windows (ISO or extracted sources folder)"
#
# Add ISO file name to the form
$ISOFile = New-Object System.Windows.Forms.TextBox -Property @{
    Location = New-Object System.Drawing.Point(20,35)
    Size = New-Object System.Drawing.Size(364,24)
    Backcolor = "White"; ForeColor = "Black"
    ReadOnly = $True
    BorderStyle = "FixedSingle"}
#
# Add Target USB Disk label
$TargetUSB = New-Object System.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Point(20,80)
    Text = "Target USB Disk"
    Size = New-Object System.Drawing.Size(200,20)}
#
# Create and populate USB Disk dropdown list
$USBDiskList = New-Object System.Windows.Forms.ComboBox -Property @{
    DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    Location = New-Object System.Drawing.Point(20,100)
    Size = New-Object System.Drawing.Size(363,22)}
#
$Windows = New-Object System.Windows.Forms.RadioButton -Property @{
    Location = New-Object System.Drawing.Point(30,145)
    Text = "Windows Setup Disk"
    Size = New-Object System.Drawing.Size(190,20)
    Checked = $True}
#
$Wintogo = New-Object System.Windows.Forms.RadioButton -Property @{
    Location = New-Object System.Drawing.Point(250,145)
    Text = "Windows To Go"
    Size = New-Object System.Drawing.Size(140,20)
    Checked = $False}
#
# Add Select ISO button
$SelectISOButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(20,185)
    Text = "Windows ISO"
    Size = New-Object System.Drawing.Size(110,26)}
#
# Add Create Setup Disk button
$OKButton.Location = New-Object System.Drawing.Point(140,185)
$OKButton.Size = New-Object System.Drawing.Size(155,26)
$OKButton.Text=""
$OKButton.Enabled = $False
#
# Add Cancel button
$CancelButton.Text = "Cancel"
#
$SelectISOButton.Add_Click({
If ($FileBrowser.ShowDialog() -ne "Cancel"){ # If Cancel, just skip
    $Global:ImagePath = $FileBrowser.filename   # return the file name
    If($ImagePath.Split(".")[-1] -eq "iso"){
        $Global:dvd = $True
        $ISOFile.Text = Split-Path -Path $ImagePath -leaf # file name (.iso)
    }Else{
        $Global:dvd = $False
        $Global:ImagePath=Split-Path $ImagePath -Parent|Split-Path -Parent
        $ISOFile.Text = $ImagePath
    }
    if(($ISOFile.Text).length -gt 44){
        $ISOFile.Text = $ImagePath.PadRight(100).substring(0,43)+"..."}
    $OKButton.Text = "Create Disk"
    $OKButton.Enabled = $True
    $OKButton.Focus()}})
#
$USBDisks=@() # Array containing USB disk numbers
Foreach ($Disk in $Disks){
    $FriendlyName = ($Disk.Caption).PadRight(40).substring(0,35)
    $USBDisks+=$Disk.Index
    $USBDiskList.Items.Add(("{0,-30}{1,10:n2} GB" -f $FriendlyName,($Disk.Size/1GB))) >$Null
}
#
$GroupBox = New-Object System.Windows.Forms.GroupBox # Add a group box to the form
$GroupBox.Location = New-Object System.Drawing.Point(7,0)
$GroupBox.Size = New-Object System.Drawing.Size(390,225)
#
$Form.Controls.Clear()
$Form.Controls.AddRange(@($Label1, $OKbutton, $CancelButton, $ISOFile, `
    $TargetUSB, $SelectISOButton, $USBDiskList,    `
    $Wintogo, $Windows, $GroupBox))
#
$USBDiskList.SelectedIndex=0
#
$HowToText.Text = @"
`n1- Plug in your USB device.
`n2- Click the Windows ISO button and select the ISO file or the install.wim/esd file in the extracted folder. `nATTENTION: The esd file will fail in the Windows To Go process.
`n3- Select the "Target USB Disk" from the dropdown menu.
`n4- Select the "Windows Setup Disk" or "Windows To Go" option.
`n5- Click "Create Disk" to create the Windows Setup Disk or Windows To Go environment.
"@
$HowTo.Show()
$HowTo.Refresh()
$Result= $Form.ShowDialog()
$HowTo.Dispose()
$HowTo.Close()
If($Result -eq "Cancel") {exit}
$SetUp = $Windows.Checked
If($SetUp){$Title=$Title.Split("-")[0]} else
    {$Title=($Title.Split("-")[1]).Trim()}
$Form.Text = $Title
$Information.Text = $Title
#
# At this point, the connected USB disk and ISO image path are defined
#
$USB=$USBDisks[$USBDiskList.SelectedIndex] # USB device disk number
#
$Form.Controls.Clear()
$Form.Controls.AddRange(@($OKButton, $CancelButton, $Label1, $Label0))
$OKButton.Location = New-Object System.Drawing.Point(25,185)
$OKButton.Text = "Yes"
$CancelButton.Text = "No"
$OKButton.Size = New-Object System.Drawing.Size(80,26)
$Label1.Location = New-Object System.Drawing.Point(20,50)
$Label1.Size = New-Object System.Drawing.Size(380,180)
$Label0.Text = "WARNING`n"
$Label1.Text = @"
The USB device will be converted to MBR schema, re-partitioned, and formatted.`n
All existing partitions and data on the USB device will be deleted.`n
Are you sure you want to continue?
"@
if($Form.ShowDialog() -eq "Cancel") {exit}
#
$Information.Show()
If($dvd){
$InformationText.AppendText("`nMounting and checking ISO image`n")
$Information.Refresh()
#
# Check if iso is already mounted, get the drive letter
If($ISO = (Get-DiskImage $ImagePath|Get-Volume).DriveLetter){$Mounted = $True}Else
# Mount the iso and get the drive letter
    {$Mounted = $False;If(!($ISO = (Mount-DiskImage $ImagePath|Get-Volume).DriveLetter)){Exit}}
$ISO=$ISO+":"
}Else{$ISO = $ImagePath}
#
Stop-Service ShellHWDetection -ErrorAction SilentlyContinue >$Null
$ProgressPreference="SilentlyContinue"
#
$InformationText.AppendText("`nCleaning USB disk and converting to MBR partition scheme`n")
$Information.Refresh()
"Select disk $USB`nclean`nconvert MBR`nexit"|diskpart >$Null
If($LASTEXITCODE -ne 0){
    $Label1.Text = "Diskpart operations failed with error code $LASTEXITCODE."
    & $Display_Error}
#
$InformationText.AppendText("`nCreating FAT32 boot partition and marking it as active`n")
$Information.Refresh()
Try{
If($SetUp){
$usbfat32 = (New-Partition -DiskNumber $usb -Size 1GB -AssignDriveLetter -IsActive|
    Format-Volume -FileSystem FAT32 -NewFileSystemLabel "BOOT").DriveLetter + ":"
} else {
$usbfat32 = (New-Partition -DiskNumber $usb -Size 100MB -AssignDriveLetter -IsActive|
    Format-Volume -FileSystem FAT32 -NewFileSystemLabel "SYSTEM").DriveLetter + ":"
}
}
Catch{
    $Label1.Text = "An error occurred while creating/formatting the FAT32 partition.`n"
    & $Display_Error
}
$PartitionSize = (Get-Volume ($usbfat32 -Replace ".$")).Size/1GB
If($PartitionSize -eq 0){
    $Label1.Text = "An error occurred while creating/formatting the FAT32 partition.`n"
    & $Display_Error}
If($SetUp){
$Files32 = Get-ChildItem $iso\boot, $iso\efi, `
    $iso\sources\boot.wim, $iso\bootmgr.*, $iso\bootmgr -Recurse -File -Force
$FilesSize = ($Files32 | measure -Sum Length).Sum/1GB
$Label1.Text = "FAT32 partition {0,1:n2} GB is too small. `n{1,1:n2} GB required." -f
$PartitionSize,$FilesSize
If ($FilesSize -gt $PartitionSize){& $Display_Error}
}
#
$InformationText.AppendText("`nCreating NTFS setup partition")
$Information.Refresh()
Try{
If($SetUp){$Label="Win Setup"} Else {$Label="Windows To Go"}
$usbntfs = (New-Partition -DiskNumber $usb -UseMaximumSize -AssignDriveLetter|
    Format-Volume -FileSystem NTFS -NewFileSystemLabel $Label).DriveLetter + ":"
}
Catch{
    $Label1.Text = "An error occurred while creating/formatting the NTFS partition`n"
    & $Display_Error
}
$PartitionSize = (Get-Volume ($usbntfs -Replace ".$")).Size/1GB
If($PartitionSize -eq 0){
    $Label1.Text = "An error occurred while creating/formatting the NTFS partition`n"
    & $Display_Error}
If($SetUp){
$FilesNTFS = Get-ChildItem $iso -Recurse -File -Force
$FilesSize = ($FilesNTFS | measure -Sum Length).Sum/1GB
$Label1.Text = "NTFS partition {0,1:n2} GB is too small. {1,1:n2} GB required." -f
$PartitionSize,$FilesSize
If($FilesSize -gt $PartitionSize){& $Display_Error}
}
#
$InformationText.Text = ""
$Information.Hide()
Start-Service ShellHWDetection -erroraction silentlycontinue >$Null
#
If($SetUp){
#******************************************************************************
#
# Create synchronized hash table
$Sync = [hashtable]::Synchronized(@{})
#$Sync.Host = $host
$Sync.Flag = 0
#
# Create runspace
$runspace = [runspacefactory]::CreateRunspace()
# Open the runspace
$runspace.Open()
# Add the synchronized hash table to the runspace
$runspace.SessionStateProxy.SetVariable('Sync',$Sync)
# Create PowerShell instance
$powershell = [powershell]::Create()
# Add the runspace to the PowerShell instance
$powershell.Runspace = $runspace
# Add the code to be executed
$Null = $powershell.AddScript({
#
    $Width = 420; $Height = 270
    $Form = New-Object System.Windows.Forms.Form -Property @{ # Create the screen form
    TopMost = $True; ShowIcon = $False; ControlBox = $True
    Text = " "; Font = 'Consolas,10'
    Width = $Width; Height = $Height
    StartPosition = "CenterScreen"; SizeGripStyle = "Hide"
    ShowInTaskbar = $False; MaximizeBox = $False; MinimizeBox = $False
    ForeColor = "White"; BackColor = "Blue"}
#
    $form.Add_Closing({param($sender,$e)
        $Sync.Flag =-2
        [environment]::exit(1)})
#
    $Label1 = New-Object system.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Point(5, 25)
    Size = New-Object System.Drawing.Size(($Width-20),65)
    Font= "Verdana"}
    #
    $ProgressBar1 = New-Object System.Windows.Forms.ProgressBar -Property @{
    Value = 0; Minimum = 0; Maximum = 100; Style="Continuous"
    Location = New-Object System.Drawing.Point(5, 85)
    Size = New-Object System.Drawing.Size(($Width-25),20)}
#
    $Label2 = New-Object system.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Point(0, 130)
    Size = New-Object System.Drawing.Size(($Width-20),65)
    Font= "Verdana"}
#
    $ProgressBar2 = New-Object System.Windows.Forms.ProgressBar -Property @{
    Value = 0; Minimum = 0; Maximum = 100; Style="Continuous"
    Location = New-Object System.Drawing.Point(5, 190)
    Size = New-Object System.Drawing.Size(($Width-25),20)}
    $Form.Show()
    $Form.Controls.AddRange(@($Label1, $Label2, $ProgressBar1, $ProgressBar2))
#
    While ($Sync.Flag -eq 0){Start-Sleep -Milliseconds 100}
    While ($Sync.Flag -gt 0) {
    $Form.Text = $Sync.FileName
    $Label1.Text = $Sync.Label1
    $Label2.Text = $Sync.Label2
    $ProgressBar1.Value   =    $Sync.CompletionRate1
    $ProgressBar2.Value   =    $Sync.CompletionRate2
    $Form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
    $Null = Start-Sleep -MilliSeconds 100
    }Else{$form.Close();$Form.Dispose()}
}) # end of addscript
# Start the runspace
$handle = $powershell.BeginInvoke()
#
Copy_Progression $Files32 $usbfat32 "FAT32"
Copy_Progression $Filesntfs $usbntfs "NTFS"
$Sync.Flag = -1 # indicate the end
While(!$Handle.IsCompleted){$Null = Start-Sleep -MilliSeconds 100}
# Cleanup after the runspace is complete
$powershell.EndInvoke($handle)
$runspace.Close()
$powershell.Dispose()
#******************************************************************************
} Else {
#
    # Create a new window
    $WTGIndexForm = New-Object System.Windows.Forms.Form
    $WTGIndexForm.Text = "Windows Version Selection"
    $WTGIndexForm.Width = 400
    $WTGIndexForm.Height = 250
    $WTGIndexForm.FormBorderStyle = 'FixedDialog'
    $WTGIndexForm.StartPosition = 'CenterScreen'
    $WTGIndexForm.TopMost = $true

    # Create a label
    $WTGLabel = New-Object System.Windows.Forms.Label
    $WTGLabel.Text = "Select one of the listed Windows versions for the Windows To Go process:"
    $WTGLabel.AutoSize = $true
    $WTGLabel.Location = New-Object System.Drawing.Point(10, 10)
    $WTGIndexForm.Controls.Add($WTGLabel)

    # Create a list box
    $WTGListBox = New-Object System.Windows.Forms.ListBox
    $WTGListBox.Width = 360
    $WTGListBox.Height = 150
    $WTGListBox.Location = New-Object System.Drawing.Point(10, 30)
    $WTGIndexForm.Controls.Add($WTGListBox)

    # Create an OK button
    $WTGOKButton = New-Object System.Windows.Forms.Button
    $WTGOKButton.Text = "OK"
    $WTGOKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $WTGOKButton.Location = New-Object System.Drawing.Point(150, 183)
    $WTGIndexForm.Controls.Add($WTGOKButton)

    # Get Windows versions within the ISO
    try {
        $WindowsImages = Get-WindowsImage -ImagePath "$ISO\Sources\Install.wim"
        if ($WindowsImages.Count -gt 0) {
            foreach ($Image in $WindowsImages) {
                $WTGListBox.Items.Add("$(($Image.ImageName).Trim()) (Index: $($Image.ImageIndex))")
            }
            # Select the first item
            $WTGListBox.SelectedIndex = 0
            $WTGIndexResult = $WTGIndexForm.ShowDialog()

            if ($WTGIndexResult -eq [System.Windows.Forms.DialogResult]::OK) {
                # Get the index number of the selected item
                $SelectedItem = $WTGListBox.SelectedItem
                [int]$SelectedIndex = $SelectedItem.ToString().Split('(')[1].Split(':')[1].TrimEnd(')')

                # Show processing information
                $ProgressBar = New-Object System.Windows.Forms.ProgressBar -Property @{
                    Style = "Marquee"; MarqueeAnimationSpeed = 20
                    Location = New-Object System.Drawing.Point(5, 150)
                    Size = New-Object System.Drawing.Size(($Width-25),20)}
                #
                $Label0.AutoSize = $True
                $Label0.Location = New-Object System.Drawing.Point(40,40)
                $Label0.Text = "Processing... `n`nThis may take a long time, please wait...."
                #
                $Information.Controls.Remove($InformationText)
                $Information.Controls.AddRange(@($Label0, $ProgressBar))
                $Information.Show()
                #
                $jobScript = {param($iso,$usbntfs,$index);Expand-WindowsImage -ImagePath "$iso\Sources\Install.wim" -ApplyPath "$($usbntfs)\" -Index $index}
                $job=Start-Job  $jobScript -ArgumentList $iso, $usbntfs, $SelectedIndex
                do {[System.Windows.Forms.Application]::DoEvents()} until ($job.State -ne "Running")
                $Information.Hide()
                $Information.Controls.Remove($Label0)
                $Information.Controls.Remove($ProgressBar)
                If($job.State -ne "Completed"){
                $Label1.Text = "Error occurred while applying the image"
                    & $Display_Error}
                Remove-Job -Job $job -Force
                #
                bcdboot $usbntfs\windows /s $usbfat32 /f ALL
                If(!(Test-Path $usbfat32\bootmgr))
                    {Copy-Item $iso\bootmgr $usbfat32\bootmgr}
                If(!(Test-Path $usbfat32\bootmgr.efi))
                    {Copy-Item $iso\bootmgr $usbfat32\bootmgr.efi}
            } else {
                # User cancelled
                exit
            }
        } else {
            $Label1.Text = "No Windows image found in the selected ISO file."
            & $Display_Error
        }
    } catch {
        $Label1.Text = "An error occurred while reading `nWindows image information."
        & $Display_Error
    } finally {
        $WTGIndexForm.Dispose()
        $WTGIndexForm.Close()
    }
}
#
$Form.Controls.Clear()
$OKButton.Location = New-Object System.Drawing.Point(25,185)
$OKButton.Text = "Continue"
$CancelButton.Location = New-Object System.Drawing.Point(300,185)
$CancelButton.Text = "Cancel"
if($SetUp){
$Label1.Text = "All folders and files have been copied.`n`nClick the Continue button to proceed with `nthe BCD update.`n"
} else {
$Label1.Text = "Image applied.`n`nClick the Continue button to proceed with `nthe BCD update.`n"
}
$Label1.Location=New-Object System.Drawing.Point(30,80)
$Label1.Size = New-Object System.Drawing.Size(380,80)
$Form.Controls.AddRange(@($OKButton, $Label1, $CancelButton))
If($Form.Showdialog() -eq "Cancel"){exit}
#
$Information.Controls.Add($InformationText)
$InformationText.AppendText("`nUpdating BCD`n")
$Information.Show()
$Information.Refresh()
Update_BCD $usbfat32
#
$InformationText.AppendText("`nRemoving drive letter to hide FAT32 boot partition`n")
$Information.Refresh()
Get-Volume ($usbfat32 -replace ".$")|Get-Partition|
    Remove-PartitionAccessPath -accesspath $usbfat32
#
If($DVD){
$InformationText.AppendText("`nEjecting mounted ISO image if it was mounted by the script")
$Information.Refresh()
# Eject the mounted ISO image if mounted by the script
If(!$Mounted){DisMount-DiskImage $ImagePath >$Null}
}
#
$Information.Dispose()
$Information.Close()
$Form.Controls.Clear()
$Form.Controls.AddRange(@($OKButton, $Label1))
$OKButton.Location=New-Object System.Drawing.Point(170,185)
$Label1.Location=New-Object System.Drawing.Point(20,80)
$Label1.AutoSize = $True
$Label1.Text = "Disk created successfully."
$OKButton.Text = "Exit"
[void]$Form.ShowDialog()