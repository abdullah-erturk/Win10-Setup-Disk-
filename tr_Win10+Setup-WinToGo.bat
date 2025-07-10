<# : hybrid batch + powershell script
@powershell -noprofile -Window min -c "$param='%*';$ScriptPath='%~f0';iex((Get-Content('%~f0') -Raw))"&exit/b
#>
$OnlyUSBsticks="NO"
$Title = "Win10+Kurulum Diski - Windows To Go"
$Host.UI.RawUI.BackgroundColor = "Blue"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host
#
#   Katkıda Bulunanlar: @rpo, @freddie-o, @BAU & @abbodi1406, mephistooo2

#   Anasayfa: https://forums.mydigitallife.net/threads/win10-setup-disk-works-with-uefi-secure-boot-bios-install-wim-over-4-gb.79268/
#   https://forums.mydigitallife.net/threads/win10-setup-disk-works-with-uefi-secure-boot-bios-install-wim-over-4-gb.79268/page-24#post-1884180
#
#******************************************************************************
$host.ui.rawui.windowtitle = $title
Add-Type -AssemblyName System.Windows.Forms # System.Windows.Forms sınıfını yükle
[System.Windows.Forms.Application]::EnableVisualStyles()
$Width = 425; $Height = 270
#
#******************************************************************************
Add-Type -AssemblyName System.Windows.Forms # System.Windows.Forms sınıfını yükle
[System.Windows.Forms.Application]::EnableVisualStyles()
$Width = 425; $Height = 270
#
#******************************************************************************
Function Copy_Progression ($Files,$Partition,$fs) {
#
# son ek 1 : genel işlem için değişkenler
# son ek 2 : tek dosya işlemi için değişkenler
[long]$TotalBytes = ($Files | measure -Sum length).Sum
[long]$Total1 = 0 # tamamlanan bayt
$index = 0
$FilesCount = $Files.Count
$StopWatch1 = [Diagnostics.Stopwatch]::StartNew()
$Buffer = New-Object Byte[] (4MB) # 4MB tampon
#
ForEach ($File in $Files) {
    $FileFullName = $File.fullname
    [long]$FileLength = $File.Length
    $index++
    # bu dosya için hedef yolu oluştur (ör: H:\sources\boot.wim)
    $DestFile = $partition+$FileFullName.Substring($iso.length)
    $DestDir= Split-Path $DestFile -Parent
    # yoksa, oluştur
    if (!(Test-Path $DestDir)){New-Item -ItemType Directory "$DestDir" -Force >$Null}
    $SourceFile = [io.file]::OpenRead($FileFullName)
    $DestinationFile = [io.file]::Create($DestFile)
    $FileLength=$File.Length
    $Sync.FileName="$($DestFile -Replace '^...')"
    $StopWatch2 = [Diagnostics.Stopwatch]::StartNew()
    [long]$Total2 = [long]$Count = 0
    $LastStopWatch = 0
    do {
        # kaynak dosyanın 4MB'ını hedef dosyaya kopyala
        $Count = $SourceFile.Read($buffer, 0, $buffer.Length)
        $DestinationFile.Write($buffer, 0, $Count)
        # bu sadece write-progress
        # kalan süreyi hesaplamak için kronometre kullanılır
        $Total2 += $Count
        $Total1 += $Count
        #
        # Genel istatistikler
        #
        $CompletionRate1 = $Total1 / $TotalBytes * 100
        [int]$MSElapsed = [int]$StopWatch1.ElapsedMilliseconds
        if (($Total1 -ne $TotalBytes) -and ($Total1 -ne 0)) {
            [int]$RemainingSeconds1 = $MSElapsed * ($TotalBytes / $Total1  - 1) / 1000
        } else {[int]$RemainingSeconds1 = 0}
        $s="$Partition $FS {0,5} / {1,5} dosya  - {2,5} kaldı" -f $index,$FilesCount,($FilesCount - $index)
        $s="$s{0,10:0} MB / {1,6:0} MB" -f ($Total1/1MB),($TotalBytes/1MB)
        $s="$s`r`n`r`nTamamlanma yüzdesi = {0,3:0}%     {1,4} dakika {2,2} saniye kaldı" -f $CompletionRate1,[math]::Truncate($RemainingSeconds1/60),($RemainingSeconds1%60)
        $Sync.Label1=$s
        $Sync.CompletionRate1 = $CompletionRate1
        #
        # Geçerli dosya için istatistikler
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
        $s="Dosya kopyalanıyor @ {0,6:n2} MB/sn" -f $xferrate
        $s="$s{0,16:0} MB / {1,6:0} MB" -f ($Total2/1MB),($filelength/1MB)
        $s="$s`r`n`r`nTamamlanma yüzdesi = {0,3:0}%     {1,4} dakika {2,2} saniye kaldı" -f $CompletionRate2,[math]::Truncate($RemainingSeconds2/60),($RemainingSeconds2%60)
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
}# Copy_With_Progression Fonksiyonu Sonu
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
    $OKButton.Text = "Çıkış"
    $Form.Controls.Add($OKButton)
    [void]$Form.Showdialog()
    exit}
#
$Form = New-Object System.Windows.Forms.Form -Property @{ # Ekran formunu (pencere) oluştur
    TopMost = $True; ShowIcon = $False; ControlBox = $False
    ForeColor = "White"; BackColor = "Blue"; Font = 'Consolas,10'
    Text = "$Title"; Width = $Width;Height = $Height
    StartPosition = "CenterScreen"; SizeGripStyle = "Hide"
    ShowInTaskbar = $False; MaximizeBox = $False; MinimizeBox = $False}
#
# Formda bir OK düğmesi ekle
$OKButton = New-Object System.Windows.Forms.Button  -Property @{
    Location = New-Object System.Drawing.Point(25,185)
    Size = New-Object System.Drawing.Size(80,26)
    DialogResult = "OK"}
$Form.Controls.Add($OKButton)
#
# Cancel butonu ekle
$CancelButton = New-Object System.Windows.Forms.Button  -Property @{
    Location = New-Object System.Drawing.Point(300,185)
    Size = New-Object System.Drawing.Size(80,26)
    DialogResult = "Cancel"}
#
# Etiket oluştur
$Label0 = New-Object system.Windows.Forms.Label  -Property @{
    Location = New-Object System.Drawing.Point(20,10)
    Size = New-Object System.Drawing.Size(365,25)
    Font = "Arial,12"; ForeColor = "Red"; BackColor = "White"}
#
$Label1 = New-Object system.Windows.Forms.Label  -Property @{
    Location = New-Object System.Drawing.Point(60,70)
    Size = New-Object System.Drawing.Size(380,150)}
#
#   Nasıl Kullanılır
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
#   Bilgi penceresi
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
#   Bu betik yönetici olarak çalıştırılmalıdır
#
#   Yönetici ayrıcalıklarını test et
$uac_error="Yönetici Ayrıcalıkları için UAC yükseltme başarısız oldu"
$Label1.Text = @"
$uac_error!`r`n`r`nBetik üzerine sağ tıklayın.
"Yönetici olarak çalıştır"ı seçin.
"@
If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    #   Yönetici ayrıcalıkları için UAC yükseltme başarısız olduğunda sonsuz döngüyü önlemek için test
    If($param -eq $uac_error){
        $Form.ForeColor = "Red"
        $Form.BackColor = "White"
        $Label1.Location = New-Object System.Drawing.Point(20,50)
        $Label1.Size = New-Object System.Drawing.Size(380,120)
        $OKButton.Location = New-Object System.Drawing.Point(200,185)
        $OKButton.Size = New-Object System.Drawing.Size(200,185)
        $OKButton.Text = "Çıkış"
        $Form.Controls.AddRange(@($OKButton, $Label1))
        [void]$Form.Showdialog()
        exit}
#   Yönetici ayrıcalıkları almak için betiği yeniden başlat ve çık
#   1. cmd betiği ise dene
    If($ScriptPath.Length -gt 0)
        {Start-Process "$ScriptPath" $uac_error -Verb runAs; exit}
#   2. ps1 betiği ise dene
    If($PSCommandPath.Length -gt 0)
        {Start-Process PowerShell -Verb runAs -ArgumentList "-f ""$PSCommandPath"" ""$uac_error"""; exit}
#   3. exe tahmini
    $ScriptPath = [Environment]::GetCommandLineArgs()[0]
    Start-Process "$ScriptPath" $uac_error -Verb runAs; exit
}
# ********************************************************
#
# Dosya tarayıcı diyalog nesnesi
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Title="ISO imajı veya çıkarılmış kaynak klasöründe install.wim/esd seçin"
    Multiselect = $false             # Sadece bir dosya seçilebilir
    Filter = 'ISO imajları (*.iso;*install.wim;*install.esd)|*.iso;*install.wim;*install.esd' # Sadece iso dosyalarını seç
}
#
Function Update_bcd ($partition){
#   $partition için bootmenupolicy Legacy olarak ayarla
bcdedit /store "$partition\boot\bcd" /set '{default}' bootmenupolicy Legacy >$Null
bcdedit /store "$partition\EFI\Microsoft\boot\bcd" /set '{default}' bootmenupolicy Legacy >$Null
remove-item "$partition\boot\bcd.*" -force
remove-item "$partition\EFI\Microsoft\boot\bcd.*" -force}
#

# --- VHD/VHDX desteği dahil filtre ---
$Form.Controls.Clear()
$Label0.Text = "Disk bulunamadı."
$Label1.Text = "Önce diskinizi takın veya bağlayın.`n`nTekrar Dene veya İptal."
$OKButton.Text = "Tekrar Dene"
$OKButton.Width = 100
$CancelButton.Text = "İptal"

do {
    # DiskDrive üzerinden VHD veya USB diskleri bul
    $FromDiskDrive = Get-CimInstance Win32_DiskDrive | Where-Object {
        $_.InterfaceType -eq 'USB' -or
        $_.MediaType -match 'External' -or
        $_.Model -match 'VHD|Virtual|Sanal' -or
        $_.Caption -match 'VHD|Virtual|Sanal' -or
        $_.PNPDeviceID -match 'VHD|MSFT'
    }

    # Her ikisi de boşsa kullanıcıdan onay al
    if ($FromDiskDrive.Count -eq 0) {
        $Form.Controls.AddRange(@($OKButton, $CancelButton, $Label0, $Label1))
        if ($Form.ShowDialog() -eq "Cancel") { exit }
        Start-Sleep -Seconds 2
    } else {
        break
    }

} while ($true)

# Diski buraya aktar
$Disks = $FromDiskDrive



#
# Kaynak Windows ISO etiketi ekle
$Label1.Location = New-Object System.Drawing.Point(20,15)
$Label1.Size = New-Object System.Drawing.Size(400,20)
$Label1.Text = "Windows (ISO veya çıkarılmış kaynak klasörü)"
#
# ISO dosya ismini forma ekle
$ISOFile = New-Object System.Windows.Forms.TextBox -Property @{
    Location = New-Object System.Drawing.Point(20,35)
    Size = New-Object System.Drawing.Size(364,24)
    Backcolor = "White"; ForeColor = "Black"
    ReadOnly = $True
    BorderStyle = "FixedSingle"}
#
# Hedef USB Disk etiketi ekle
$TargetUSB = New-Object System.Windows.Forms.Label -Property @{
    Location = New-Object System.Drawing.Point(20,80)
    Text = "Hedef USB Disk"
    Size = New-Object System.Drawing.Size(200,20)}
#
# USB Disk açılır listesini oluştur ve doldur
$USBDiskList = New-Object System.Windows.Forms.ComboBox -Property @{
    DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    Location = New-Object System.Drawing.Point(20,100)
    Size = New-Object System.Drawing.Size(363,22)}
#
$Windows = New-Object System.Windows.Forms.RadioButton -Property @{
    Location = New-Object System.Drawing.Point(30,145)
    Text = "Windows Kurulum Diski"
    Size = New-Object System.Drawing.Size(190,20)
    Checked = $True}
#
$Wintogo = New-Object System.Windows.Forms.RadioButton -Property @{
    Location = New-Object System.Drawing.Point(250,145)
    Text = "Windows To Go"
    Size = New-Object System.Drawing.Size(140,20)
    Checked = $False}
#
# ISO Seç düğmesi ekle
$SelectISOButton = New-Object System.Windows.Forms.Button -Property @{
    Location = New-Object System.Drawing.Point(20,185)
    Text = "Windows ISO"
    Size = New-Object System.Drawing.Size(110,26)}
#
# Kurulum Diski Oluştur düğmesi ekle
$OKButton.Location = New-Object System.Drawing.Point(140,185)
$OKButton.Size = New-Object System.Drawing.Size(155,26)
$OKButton.Text=""
$OKButton.Enabled = $False
#
# İptal düğmesi ekle
$CancelButton.Text = "İptal"
#
$SelectISOButton.Add_Click({
If ($FileBrowser.ShowDialog() -ne "Cancel"){ # İptal ise, sadece geç
    $Global:ImagePath = $FileBrowser.filename   # dosya adını döndür
    If($ImagePath.Split(".")[-1] -eq "iso"){
        $Global:dvd = $True
        $ISOFile.Text = Split-Path -Path $ImagePath -leaf # dosya adı (.iso)
    }Else{
        $Global:dvd = $False
        $Global:ImagePath=Split-Path $ImagePath -Parent|Split-Path -Parent
        $ISOFile.Text = $ImagePath
    }
    if(($ISOFile.Text).length -gt 44){
        $ISOFile.Text = $ImagePath.PadRight(100).substring(0,43)+"..."}
    $OKButton.Text = "Diski Oluştur"
    $OKButton.Enabled = $True
    $OKButton.Focus()}})
#
$USBDisks=@() # USB disk numaralarını içeren dizi
Foreach ($Disk in $Disks){
    $FriendlyName = ($Disk.Caption).PadRight(40).substring(0,35)
    $USBDisks+=$Disk.Index
    $USBDiskList.Items.Add(("{0,-30}{1,10:n2} GB" -f $FriendlyName,($Disk.Size/1GB))) >$Null
}
#
$GroupBox = New-Object System.Windows.Forms.GroupBox # Formda bir grup kutusu ekle
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
`n1- USB aygıtınızı takın.
`n2- Windows ISO butonuna tıklayarak ISO dosyası yada çıkarılmış klasördeki install.wim/esd dosyasını seçin. `nDİKKAT: Windows To Go işleminde esd dosyası hata verir.
`n3- Açılır menüden "Hedef USB Disk" seçin
`n4- "Windows Kurulum Diski" yada "Windows To Go" seçeneğini seçin.
`n5- Windows Kurulum Diski veya Windows To Go ortamı oluşturmak için "Diski Oluştur"a tıklayın.
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
# Bu noktada bağlı USB disk ve iso imaj yolu tanımlandı
#
$USB=$USBDisks[$USBDiskList.SelectedIndex] # USB aygıt disk numarası
#
$Form.Controls.Clear()
$Form.Controls.AddRange(@($OKButton, $CancelButton, $Label1, $Label0))
$OKButton.Location = New-Object System.Drawing.Point(25,185)
$OKButton.Text = "Evet"
$CancelButton.Text = "Hayır"
$OKButton.Size = New-Object System.Drawing.Size(80,26)
$Label1.Location = New-Object System.Drawing.Point(20,50)
$Label1.Size = New-Object System.Drawing.Size(380,180)
$Label0.Text = "UYARI`n"
$Label1.Text = @"
USB aygıtı MBR şemaya dönüştürülecek, tekrar bölümlendirilecek ve biçimlendirilecektir.`n
USB aygıtında şu anda bulunan tüm bölümler ve veriler silinecektir.`n
Devam etmek istediğinizden emin misiniz?
"@
if($Form.ShowDialog() -eq "Cancel") {exit}
#
$Information.Show()
If($dvd){
$InformationText.AppendText("`nISO imajı bağlanıyor ve kontrol ediliyor`n")
$Information.Refresh()
#
#   iso zaten bağlı mı kontrol et, sürücü harfini al
If($ISO = (Get-DiskImage $ImagePath|Get-Volume).DriveLetter){$Mounted = $True}Else
#   iso'yu bağla ve sürücü harfini al
    {$Mounted = $False;If(!($ISO = (Mount-DiskImage $ImagePath|Get-Volume).DriveLetter)){Exit}}
$ISO=$ISO+":"
}Else{$ISO = $ImagePath}
#
Stop-Service ShellHWDetection -ErrorAction SilentlyContinue >$Null
$ProgressPreference="SilentlyContinue"
#
$InformationText.AppendText("`nUSB disk temizleniyor ve MBR bölüm şemasına dönüştürülüyor`n")
$Information.Refresh()
"Select disk $USB`nclean`nconvert MBR`nexit"|diskpart >$Null
If($LASTEXITCODE -ne 0){
    $Label1.Text = "Diskpart işlemleri $LASTEXITCODE hata kodu ile başarısız oldu."
    & $Display_Error}
#
$InformationText.AppendText("`nFAT32 önyükleme bölümü oluşturuluyor ve aktif olarak işaretleniyor`n")
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
    $Label1.Text = "FAT32 bölümü oluşturulurken/biçimlendirilirken `nhata oluştu."
    & $Display_Error
}
$PartitionSize = (Get-Volume ($usbfat32 -Replace ".$")).Size/1GB
If($PartitionSize -eq 0){
    $Label1.Text = "FAT32 bölümü oluşturulurken/biçimlendirilirken `nhata oluştu."
    & $Display_Error}
If($SetUp){
$Files32 = Get-ChildItem $iso\boot, $iso\efi, `
    $iso\sources\boot.wim, $iso\bootmgr.*, $iso\bootmgr -Recurse -File -Force
$FilesSize = ($Files32 | measure -Sum Length).Sum/1GB
$Label1.Text = "FAT32 bölümü {0,1:n2} GB çok küçük. `n{1,1:n2} GB gerekli." -f
$PartitionSize,$FilesSize
If ($FilesSize -gt $PartitionSize){& $Display_Error}
}
#
$InformationText.AppendText("`nNTFS kurulum bölümü oluşturuluyor")
$Information.Refresh()
Try{
If($SetUp){$Label="Win Kurulum"} Else {$Label="Windows To Go"}
$usbntfs = (New-Partition -DiskNumber $usb -UseMaximumSize -AssignDriveLetter|
    Format-Volume -FileSystem NTFS -NewFileSystemLabel $Label).DriveLetter + ":"
}
Catch{
    $Label1.Text = "NTFS bölümü oluşturulurken/biçimlendirilirken `nhata oluştu"
    & $Display_Error
}
$PartitionSize = (Get-Volume ($usbntfs -Replace ".$")).Size/1GB
If($PartitionSize -eq 0){
    $Label1.Text = "NTFS bölümü oluşturulurken/biçimlendirilirken `nhata oluştu"
    & $Display_Error}
If($SetUp){
$FilesNTFS = Get-ChildItem $iso -Recurse -File -Force
$FilesSize = ($FilesNTFS | measure -Sum Length).Sum/1GB
$Label1.Text = "NTFS bölümü {0,1:n2} GB çok küçük. {1,1:n2} GB gerekli." -f
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
#   Eşzamanlı hash tablosu oluştur
$Sync = [hashtable]::Synchronized(@{})
#$Sync.Host = $host
$Sync.Flag = 0
#
#   Runspace oluştur
$runspace = [runspacefactory]::CreateRunspace()
#   Runspace'i aç
$runspace.Open()
#   Eşzamanlı hash tablosunu runspace'e ekle
$runspace.SessionStateProxy.SetVariable('Sync',$Sync)
#   PowerShell örneği oluştur
$powershell = [powershell]::Create()
#   Runspace'i PowerShell örneğine ekle
$powershell.Runspace = $runspace
#   Çalıştırılacak kodu ekle
$Null = $powershell.AddScript({
#
    $Width = 420; $Height = 270
    $Form = New-Object System.Windows.Forms.Form -Property @{ # Ekran formunu oluştur
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
    $ProgressBar1.Value  =   $Sync.CompletionRate1
    $ProgressBar2.Value  =   $Sync.CompletionRate2
    $Form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
    $Null = Start-Sleep -MilliSeconds 100
    }Else{$form.Close();$Form.Dispose()}
}) # addscript sonu
#   Runspace'i başlat
$handle = $powershell.BeginInvoke()
#
Copy_Progression $Files32 $usbfat32 "FAT32"
Copy_Progression $Filesntfs $usbntfs "NTFS"
$Sync.Flag = -1 # sonu belirt
While(!$Handle.IsCompleted){$Null = Start-Sleep -MilliSeconds 100}
#   Runspace tamamlandıktan sonra temizlik işlemleri
$powershell.EndInvoke($handle)
$runspace.Close()
$powershell.Dispose()
#******************************************************************************
} Else {
#
    # Yeni pencere oluştur
    $WTGIndexForm = New-Object System.Windows.Forms.Form
    $WTGIndexForm.Text = "Windows Sürüm Seçimi"
    $WTGIndexForm.Width = 400
    $WTGIndexForm.Height = 250
    $WTGIndexForm.FormBorderStyle = 'FixedDialog'
    $WTGIndexForm.StartPosition = 'CenterScreen'
    $WTGIndexForm.TopMost = $true

    # Etiket oluştur
    $WTGLabel = New-Object System.Windows.Forms.Label
    $WTGLabel.Text = "Windows To Go işlemi için listelenen Windows sürümünden birini seçin:"
    $WTGLabel.AutoSize = $true
    $WTGLabel.Location = New-Object System.Drawing.Point(10, 10)
    $WTGIndexForm.Controls.Add($WTGLabel)

    # Liste kutusu oluştur
    $WTGListBox = New-Object System.Windows.Forms.ListBox
    $WTGListBox.Width = 360
    $WTGListBox.Height = 150
    $WTGListBox.Location = New-Object System.Drawing.Point(10, 30)
    $WTGIndexForm.Controls.Add($WTGListBox)

    # Tamam butonu oluştur
    $WTGOKButton = New-Object System.Windows.Forms.Button
    $WTGOKButton.Text = "Tamam"
    $WTGOKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $WTGOKButton.Location = New-Object System.Drawing.Point(150, 183)
    $WTGIndexForm.Controls.Add($WTGOKButton)

    # ISO içindeki Windows sürümlerini al
    try {
        $WindowsImages = Get-WindowsImage -ImagePath "$ISO\Sources\Install.wim"
        if ($WindowsImages.Count -gt 0) {
            foreach ($Image in $WindowsImages) {
                $WTGListBox.Items.Add("$(($Image.ImageName).Trim()) (Index: $($Image.ImageIndex))")
            }
            # İlk öğeyi seç
            $WTGListBox.SelectedIndex = 0
            $WTGIndexResult = $WTGIndexForm.ShowDialog()

            if ($WTGIndexResult -eq [System.Windows.Forms.DialogResult]::OK) {
                # Seçilen öğenin index numarasını al
                $SelectedItem = $WTGListBox.SelectedItem
                [int]$SelectedIndex = $SelectedItem.ToString().Split('(')[1].Split(':')[1].TrimEnd(')')

                # İşlem bilgisini göster
                $ProgressBar = New-Object System.Windows.Forms.ProgressBar -Property @{
                    Style = "Marquee"; MarqueeAnimationSpeed = 20
                    Location = New-Object System.Drawing.Point(5, 150)
                    Size = New-Object System.Drawing.Size(($Width-25),20)}
                #
                $Label0.AutoSize = $True
                $Label0.Location = New-Object System.Drawing.Point(40,40)
                $Label0.Text = "İşleniyor... `n`nİşlem uzun sürebilir, lütfen bekleyin..."
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
                $Label1.Text = "İmaj uygulanırken hata oluştu"
                    & $Display_Error}
                Remove-Job -Job $job -Force
                #
                bcdboot $usbntfs\windows /s $usbfat32 /f ALL
                If(!(Test-Path $usbfat32\bootmgr))
                    {Copy-Item $iso\bootmgr $usbfat32\bootmgr}
                If(!(Test-Path $usbfat32\bootmgr.efi))
                    {Copy-Item $iso\bootmgr $usbfat32\bootmgr.efi}
            } else {
                # Kullanıcı iptal etti
                exit
            }
        } else {
            $Label1.Text = "Seçilen ISO dosyasında Windows imajı bulunamadı."
            & $Display_Error
        }
    } catch {
        $Label1.Text = "Windows imaj bilgileri okunurken bir hata oluştu."
        & $Display_Error
    } finally {
        $WTGIndexForm.Dispose()
        $WTGIndexForm.Close()
    }
}
#
$Form.Controls.Clear()
$OKButton.Location = New-Object System.Drawing.Point(25,185)
$OKButton.Text = "Devam"
$CancelButton.Location = New-Object System.Drawing.Point(300,185)
$CancelButton.Text = "İptal"
if($SetUp){
$Label1.Text = "Tüm klasörler ve dosyalar kopyalandı.`n`nDevam butonuna tıklayarak BCD güncelleme `nişlemine devam edin."
} else {
$Label1.Text = "İmaj uygulandı.`n`nDevam butonuna tıklayarak BCD güncelleme `nişlemine devam edin."
}
$Label1.Location=New-Object System.Drawing.Point(30,80)
$Label1.Size = New-Object System.Drawing.Size(380,80)
$Form.Controls.AddRange(@($OKButton, $Label1, $CancelButton))
If($Form.Showdialog() -eq "Cancel"){exit}
#
$Information.Controls.Add($InformationText)
$InformationText.AppendText("`nBCD güncelleniyor`n")
$Information.Show()
$Information.Refresh()
Update_BCD $usbfat32
#
$InformationText.AppendText("`nFAT32 önyükleme bölümünü gizlemek için sürücü harfi kaldırılıyor`n")
$Information.Refresh()
Get-Volume ($usbfat32 -replace ".$")|Get-Partition|
    Remove-PartitionAccessPath -accesspath $usbfat32
#
If($DVD){
$InformationText.AppendText("`nKomut dosyası tarafından yüklenmişse, bağlanmış ISO imajı çıkarılıyor")
$Information.Refresh()
# Betik tarafından yüklenmişse, bağlı iso imajını çıkar
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
$Label1.Text = "Disk başarıyla oluşturuldu."
$OKButton.Text = "Çıkış"
[void]$Form.ShowDialog()