<# : hybrid batch + powershell script
@powershell -noprofile -Window min -c "$param='%*';$ScriptPath='%~f0';iex((Get-Content('%~f0') -Raw))"&exit/b
#>
$OnlyUSBsticks="NO"
$Title = "Win10+Kurulum Diski - Windows To Go"
$Host.UI.RawUI.BackgroundColor = "Blue"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

#   https://github.com/abdullah-erturk/

#   https://github.com/abdullah-erturk/Win10-Setup-Disk-

#   Katkıda bulunanlar: @rpo, @freddie-o, @BAU & @abbodi1406, @mephistooo2

#   Ana Sayfa: https://forums.mydigitallife.net/threads/win10-setup-disk-works-with-uefi-secure-boot-bios-install-wim-over-4-gb.79268/
#   https://forums.mydigitallife.net/threads/win10-setup-disk-works-with-uefi-secure-boot-bios-install-wim-over-4-gb.79268/page-24#post-1884180

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

# https://github.com/AveYo/MediaCreationTool.bat/blob/main/bypass11/AutoUnattend.xml
# AutoUnattend.xml Base64 encode
$base64AutoUnattend = @"
PHVuYXR0ZW5kIHhtbG5zPSJ1cm46c2NoZW1hcy1taWNyb3NvZnQtY29tOnVuYXR0ZW5kIj4NCiAgPHNldHRpbmdzIHBhc3M9IndpbmRvd3NQRSI+PGNvbXBvbmVudCBuYW1lPSJNaWNyb3NvZnQtV2luZG93cy1TZXR1cCIgcHJvY2Vzc29yQXJjaGl0ZWN0dXJlPSJhbWQ2NCIgbGFuZ3VhZ2U9Im5ldXRyYWwiDQogICB4bWxuczp3Y209Imh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vV01JQ29uZmlnLzIwMDIvU3RhdGUiIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiDQogICBwdWJsaWNLZXlUb2tlbj0iMzFiZjM4NTZhZDM2NGUzNSIgdmVyc2lvblNjb3BlPSJub25TeFMiPg0KICAgIDxVc2VyRGF0YT48UHJvZHVjdEtleT48S2V5PkFBQUFBLVZWVlZWLUVFRUVFLVlZWVlZLU9PT09PPC9LZXk+PFdpbGxTaG93VUk+T25FcnJvcjwvV2lsbFNob3dVST48L1Byb2R1Y3RLZXk+PC9Vc2VyRGF0YT4NCiAgICA8Q29tcGxpYW5jZUNoZWNrPjxEaXNwbGF5UmVwb3J0Pk5ldmVyPC9EaXNwbGF5UmVwb3J0PjwvQ29tcGxpYW5jZUNoZWNrPjxEaWFnbm9zdGljcz48T3B0SW4+ZmFsc2U8L09wdEluPjwvRGlhZ25vc3RpY3M+DQogICAgPER5bmFtaWNVcGRhdGU+PEVuYWJsZT50cnVlPC9FbmFibGU+PFdpbGxTaG93VUk+TmV2ZXI8L1dpbGxTaG93VUk+PC9EeW5hbWljVXBkYXRlPjxFbmFibGVOZXR3b3JrPnRydWU8L0VuYWJsZU5ldHdvcms+DQogICAgPFJ1blN5bmNocm9ub3VzPg0KICAgICAgPCEtLSBTa2lwIDExIENoZWNrcyBvbiBCb290IHZpYSByZWcgLSB1bnJlbGlhYmxlIHZzIHdpbnNldHVwLmRsbCBwYXRjaCB1c2VkIGluIE1lZGlhQ3JlYXRpb25Ub29sLmJhdCAtLT4NCiAgICAgIDxSdW5TeW5jaHJvbm91c0NvbW1hbmQgd2NtOmFjdGlvbj0iYWRkIj48T3JkZXI+MTwvT3JkZXI+DQogICAgICAgIDxQYXRoPnJlZyBhZGQgSEtMTVxTWVNURU1cU2V0dXBcTGFiQ29uZmlnIC92IEJ5cGFzc1RQTUNoZWNrIC9kIDEgL3QgcmVnX2R3b3JkIC9mPC9QYXRoPjwvUnVuU3luY2hyb25vdXNDb21tYW5kPg0KICAgICAgPFJ1blN5bmNocm9ub3VzQ29tbWFuZCB3Y206YWN0aW9uPSJhZGQiPjxPcmRlcj4yPC9PcmRlcj4NCiAgICAgICAgPFBhdGg+cmVnIGFkZCBIS0xNXFNZU1RFTVxTZXR1cFxMYWJDb25maWcgL3YgQnlwYXNzU2VjdXJlQm9vdENoZWNrIC9kIDEgL3QgcmVnX2R3b3JkIC9mPC9QYXRoPjwvUnVuU3luY2hyb25vdXNDb21tYW5kPg0KICAgICAgPFJ1blN5bmNocm9ub3VzQ29tbWFuZCB3Y206YWN0aW9uPSJhZGQiPjxPcmRlcj4zPC9PcmRlcj4NCiAgICAgICAgPFBhdGg+cmVnIGFkZCBIS0xNXFNZU1RFTVxTZXR1cFxMYWJDb25maWcgL3YgQnlwYXNzUkFNQ2hlY2sgL2QgMSAvdCByZWdfZHdvcmQgL2Y8L1BhdGg+PC9SdW5TeW5jaHJvbm91c0NvbW1hbmQ+DQogICAgICA8UnVuU3luY2hyb25vdXNDb21tYW5kIHdjbTphY3Rpb249ImFkZCI+PE9yZGVyPjQ8L09yZGVyPg0KICAgICAgICA8UGF0aD5yZWcgYWRkIEhLTE1cU1lTVEVNXFNldHVwXExhYkNvbmZpZyAvdiBCeXBhc3NTdG9yYWdlQ2hlY2sgL2QgMSAvdCByZWdfZHdvcmQgL2Y8L1BhdGg+PC9SdW5TeW5jaHJvbm91c0NvbW1hbmQ+DQogICAgICA8UnVuU3luY2hyb25vdXNDb21tYW5kIHdjbTphY3Rpb249ImFkZCI+PE9yZGVyPjU8L09yZGVyPg0KICAgICAgICA8UGF0aD5yZWcgYWRkIEhLTE1cU1lTVEVNXFNldHVwXExhYkNvbmZpZyAvdiBCeXBhc3NDUFVDaGVjayAvZCAxIC90IHJlZ19kd29yZCAvZjwvUGF0aD48L1J1blN5bmNocm9ub3VzQ29tbWFuZD4NCiAgICA8L1J1blN5bmNocm9ub3VzPg0KICA8L2NvbXBvbmVudD48L3NldHRpbmdzPiAgDQogIDxzZXR0aW5ncyBwYXNzPSJzcGVjaWFsaXplIj48Y29tcG9uZW50IG5hbWU9Ik1pY3Jvc29mdC1XaW5kb3dzLURlcGxveW1lbnQiIHByb2Nlc3NvckFyY2hpdGVjdHVyZT0iYW1kNjQiIGxhbmd1YWdlPSJuZXV0cmFsIg0KICAgeG1sbnM6d2NtPSJodHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29tL1dNSUNvbmZpZy8yMDAyL1N0YXRlIiB4bWxuczp4c2k9Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvWE1MU2NoZW1hLWluc3RhbmNlIg0KICAgcHVibGljS2V5VG9rZW49IjMxYmYzODU2YWQzNjRlMzUiIHZlcnNpb25TY29wZT0ibm9uU3hTIj4NCiAgICA8UnVuU3luY2hyb25vdXM+DQogICAgICA8IS0tIG9mZmxpbmUgbG9jYWwgYWNjb3VudCB2aWEgT09CRVxCWVBBU1NOUk8gb24gZXZlcnkgc2l0ZSBidXQgbGl0ZXJhbGx5IG5vIG9uZSBjcmVkaXRzIEF2ZVlvIGZvciBzaGFyaW5nIGl0IC0tPg0KICAgICAgPFJ1blN5bmNocm9ub3VzQ29tbWFuZCB3Y206YWN0aW9uPSJhZGQiPjxPcmRlcj4xPC9PcmRlcj4NCiAgICAgICAgPFBhdGg+cmVnIGFkZCBIS0xNXFNPRlRXQVJFXE1pY3Jvc29mdFxXaW5kb3dzXEN1cnJlbnRWZXJzaW9uXE9PQkUgL3YgQnlwYXNzTlJPIC90IHJlZ19kd29yZCAvZCAxIC9mPC9QYXRoPg0KICAgICAgPC9SdW5TeW5jaHJvbm91c0NvbW1hbmQ+DQogICAgICA8IS0tIGhpZGUgdW5zdXBwb3J0ZWQgbmFnIG9uIHVwZGF0ZSBzZXR0aW5ncyAtIDI1SDEgaXMgbm90IGEgdHlwbyA7KSAtLT4NCiAgICAgIDxSdW5TeW5jaHJvbm91c0NvbW1hbmQgd2NtOmFjdGlvbj0iYWRkIj48T3JkZXI+MjwvT3JkZXI+DQogICAgICAgIDxQYXRoPnJlZyBhZGQgSEtMTVxTT0ZUV0FSRVxQb2xpY2llc1xNaWNyb3NvZnRcV2luZG93c1xXaW5kb3dzVXBkYXRlIC92IFRhcmdldFJlbGVhc2VWZXJzaW9uIC9kIDEgL3QgcmVnX2R3b3JkIC9mPC9QYXRoPg0KICAgICAgPC9SdW5TeW5jaHJvbm91c0NvbW1hbmQ+DQogICAgICA8UnVuU3luY2hyb25vdXNDb21tYW5kIHdjbTphY3Rpb249ImFkZCI+PE9yZGVyPjM8L09yZGVyPg0KICAgICAgICA8UGF0aD5yZWcgYWRkIEhLTE1cU09GVFdBUkVcUG9saWNpZXNcTWljcm9zb2Z0XFdpbmRvd3NcV2luZG93c1VwZGF0ZSAvdiBUYXJnZXRSZWxlYXNlVmVyc2lvbkluZm8gL2QgMjVIMSAvZjwvUGF0aD4NCiAgICAgIDwvUnVuU3luY2hyb25vdXNDb21tYW5kPg0KICAgIDwvUnVuU3luY2hyb25vdXM+DQogIDwvY29tcG9uZW50Pjwvc2V0dGluZ3M+DQogIDxzZXR0aW5ncyBwYXNzPSJvb2JlU3lzdGVtIj48Y29tcG9uZW50IG5hbWU9Ik1pY3Jvc29mdC1XaW5kb3dzLVNoZWxsLVNldHVwIiBwcm9jZXNzb3JBcmNoaXRlY3R1cmU9ImFtZDY0IiBsYW5ndWFnZT0ibmV1dHJhbCIgDQogICB4bWxuczp3Y209Imh0dHA6Ly9zY2hlbWFzLm1pY3Jvc29mdC5jb20vV01JQ29uZmlnLzIwMDIvU3RhdGUiIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiDQogICBwdWJsaWNLZXlUb2tlbj0iMzFiZjM4NTZhZDM2NGUzNSIgdmVyc2lvblNjb3BlPSJub25TeFMiPg0KICAgIDxPT0JFPg0KICAgICAgPEhpZGVMb2NhbEFjY291bnRTY3JlZW4+ZmFsc2U8L0hpZGVMb2NhbEFjY291bnRTY3JlZW4+PEhpZGVPbmxpbmVBY2NvdW50U2NyZWVucz5mYWxzZTwvSGlkZU9ubGluZUFjY291bnRTY3JlZW5zPg0KICAgICAgPEhpZGVXaXJlbGVzc1NldHVwSW5PT0JFPmZhbHNlPC9IaWRlV2lyZWxlc3NTZXR1cEluT09CRT48UHJvdGVjdFlvdXJQQz4zPC9Qcm90ZWN0WW91clBDPg0KICAgIDwvT09CRT4gIA0KICAgIDxGaXJzdExvZ29uQ29tbWFuZHM+DQogICAgICA8IS0tIGhpZGUgdW5zdXBwb3J0ZWQgbmFnIG9uIGRlc2t0b3AgLSBvcmlnaW5hbGx5IHNoYXJlZCBieSBhd3VjdGwgQCBNREwgLS0+DQogICAgICA8U3luY2hyb25vdXNDb21tYW5kIHdjbTphY3Rpb249ImFkZCI+PE9yZGVyPjE8L09yZGVyPg0KICAgICAgICA8Q29tbWFuZExpbmU+cmVnIGFkZCAiSEtDVVxDb250cm9sIFBhbmVsXFVuc3VwcG9ydGVkSGFyZHdhcmVOb3RpZmljYXRpb25DYWNoZSIgL3YgU1YxIC9kIDAgL3QgcmVnX2R3b3JkIC9mPC9Db21tYW5kTGluZT4NCiAgICAgIDwvU3luY2hyb25vdXNDb21tYW5kPjxTeW5jaHJvbm91c0NvbW1hbmQgd2NtOmFjdGlvbj0iYWRkIj48T3JkZXI+MjwvT3JkZXI+DQogICAgICAgIDxDb21tYW5kTGluZT5yZWcgYWRkICJIS0NVXENvbnRyb2wgUGFuZWxcVW5zdXBwb3J0ZWRIYXJkd2FyZU5vdGlmaWNhdGlvbkNhY2hlIiAvdiBTVjIgL2QgMCAvdCByZWdfZHdvcmQgL2Y8L0NvbW1hbmRMaW5lPg0KICAgICAgPC9TeW5jaHJvbm91c0NvbW1hbmQ+DQogICAgPC9GaXJzdExvZ29uQ29tbWFuZHM+DQogIDwvY29tcG9uZW50Pjwvc2V0dGluZ3M+DQo8L3VuYXR0ZW5kPg0K
"@ -replace '\s',''

# https://github.com/lzw29107/MediaCreationTool.bat/blob/main/bypass11/auto.cmd
# auto.cmd Base64 encode
$base64auto = @"
QGVjaG8gb2ZmJiB0aXRsZSBBdXRvIFVwZ3JhZGUgLSBNQ1QgfHwgIHN1cHBvcnRzIFVsdGltYXRlIC8gUG9zUmVhZHkgLyBFbWJlZGRlZCAvIExUU0MgLyBFbnRlcnByaXNlIEV2YWwNCnNldCAiRURJVElPTl9TV0lUQ0g9Ig0Kc2V0ICJTS0lQXzExX1NFVFVQX0NIRUNLUz0xIg0Kc2V0IE9QVElPTlM9L1NlbGZIb3N0IC9BdXRvIFVwZ3JhZGUgL01pZ0Nob2ljZSBVcGdyYWRlIC9Db21wYXQgSWdub3JlV2FybmluZyAvTWlncmF0ZURyaXZlcnMgQWxsIC9SZXNpemVSZWNvdmVyeVBhcnRpdGlvbiBEaXNhYmxlDQpzZXQgT1BUSU9OUz0lT1BUSU9OUyUgL1Nob3dPT0JFIE5vbmUgL1RlbGVtZXRyeSBEaXNhYmxlIC9Db21wYWN0T1MgRGlzYWJsZSAvRHluYW1pY1VwZGF0ZSBFbmFibGUgL1NraXBTdW1tYXJ5IC9FdWxhIEFjY2VwdA0KDQpwdXNoZCAiJX5kcDAiICYgZm9yICUldyBpbiAoJTEpIGRvIHB1c2hkICUldw0KZm9yICUlaSBpbiAoIng4NlwiICJ4NjRcIiAiIikgZG8gaWYgZXhpc3QgIiUlfmlzb3VyY2VzXHNldHVwcHJlcC5leGUiIHNldCAiZGlyPSUlfmkiDQpwdXNoZCAiJWRpciVzb3VyY2VzIiB8fCAoZWNobyAiJWRpciVzb3VyY2VzIiBub3QgZm91bmQhIHNjcmlwdCBzaG91bGQgYmUgcnVuIGZyb20gd2luZG93cyBzZXR1cCBtZWRpYSAmIHRpbWVvdXQgL3QgNSAmIGV4aXQgL2IpDQoNCjo6IyBzdGFydCBzb3VyY2VzXHNldHVwIGlmIHVuZGVyIHdpbnBlICh3aGVuIGJvb3RlZCBmcm9tIG1lZGlhKSBbU2hpZnRdICsgW0YxMF06IGM6XGF1dG8gb3IgZDpcYXV0byBvciBlOlxhdXRvIGV0Yy4NCnJlZyBxdWVyeSAiSEtMTVxTb2Z0d2FyZVxNaWNyb3NvZnRcV2luZG93cyBOVFxDdXJyZW50VmVyc2lvblxXaW5QRSI+bnVsIDI+bnVsICYmICgNCiBmb3IgJSVzIGluIChzQ1BVIHNSQU0gc1NlY3VyZUJvb3Qgc1N0b3JhZ2Ugc1RQTSkgZG8gcmVnIGFkZCBIS0xNXFNZU1RFTVxTZXR1cFxMYWJDb25maWcgL2YgL3YgQnlwYXMlJXNDaGVjayAvZCAxIC90IHJlZ19kd29yZA0KIHN0YXJ0ICJXaW5QRSIgc291cmNlc1xzZXR1cC5leGUgJiBleGl0IC9iIA0KKSANCg0KOjojIGluaXQgdmFyaWFibGVzDQpzZXRsb2NhbCBFbmFibGVEZWxheWVkRXhwYW5zaW9uDQpzZXQgIlBBVEg9JVN5c3RlbVJvb3QlXFN5c3RlbTMyOyVTeXN0ZW1Sb290JVxTeXN0ZW0zMlx3aW5kb3dzcG93ZXJzaGVsbFx2MS4wXDslUEFUSCUiDQpzZXQgIlBBVEg9JVN5c3RlbVJvb3QlXFN5c25hdGl2ZTslU3lzdGVtUm9vdCVcU3lzbmF0aXZlXHdpbmRvd3Nwb3dlcnNoZWxsXHYxLjBcOyVQQVRIJSINCg0KOjojIGVsZXZhdGUgc28gdGhhdCB3b3JrYXJvdW5kcyBjYW4gYmUgc2V0IHVuZGVyIHdpbmRvd3MNCmZsdG1jID5udWwgfHwgKHNldCBfPSIlfmYwIiAlKiYgcG93ZXJzaGVsbCAtbm9wIC1jIHN0YXJ0IC12ZXJiIHJ1bmFzIGNtZCBcIi9kIC94IC9jIGNhbGwgJGVudjpfXCImIGV4aXQgL2IpDQoNCjo6IyB1bmRvIGFueSBwcmV2aW91cyByZWdlZGl0IGVkaXRpb24gcmVuYW1lIChpZiB1cGdyYWRlIHdhcyBpbnRlcnJ1cHRlZCkNCnNldCAiTlQ9SEtMTVxTT0ZUV0FSRVxNaWNyb3NvZnRcV2luZG93cyBOVFxDdXJyZW50VmVyc2lvbiINCmZvciAlJXYgaW4gKENvbXBvc2l0aW9uRWRpdGlvbklEIEVkaXRpb25JRCBQcm9kdWN0TmFtZSkgZG8gKA0KIGNhbGwgOnJlZ19xdWVyeSAiJU5UJSIgJSV2X3VuZG8gJSV2DQogaWYgZGVmaW5lZCAlJXYgcmVnIGRlbGV0ZSAiJU5UJSIgL3YgJSV2X3VuZG8gL2YgJiBmb3IgJSVBIGluICgzMiA2NCkgZG8gcmVnIGFkZCAiJU5UJSIgL3YgJSV2IC9kICIhJSV2ISIgL2YgL3JlZzolJUEgDQopID5udWwgMj5udWwNCg0KOjojIGdldCBjdXJyZW50IHZlcnNpb24NCmZvciAlJXYgaW4gKENvbXBvc2l0aW9uRWRpdGlvbklEIEVkaXRpb25JRCBQcm9kdWN0TmFtZSBDdXJyZW50QnVpbGROdW1iZXIpIGRvIGNhbGwgOnJlZ19xdWVyeSAiJU5UJSIgJSV2ICUldg0KZm9yIC9mICJ0b2tlbnM9Mi0zIGRlbGltcz1bLiIgJSVpIGluICgndmVyJykgZG8gZm9yICUlcyBpbiAoJSVpKSBkbyBzZXQgL2EgVmVyc2lvbj0lJXMqMTArJSVqDQoNCjo6IyBXSU1fSU5GTyB3XzU9d2ltXzV0aCBiXzU9YnVpbGRfNXRoIHBfNT1wYXRjaF81dGggYV81PWFyY2hfNXRoIGxfNT1sYW5nXzV0aCBlXzU9ZWRpXzV0aCBkXzU9ZGVzY181dGggaV81PWVkaV81dGggaV9Db3JlPWluZGV4DQpzZXQgIjA9JX5mMCImIHNldCB3aW09JiBzZXQgZXh0PS5lc2QmIGlmIGV4aXN0IGluc3RhbGwud2ltIChzZXQgZXh0PS53aW0pIGVsc2UgaWYgZXhpc3QgaW5zdGFsbC5zd20gc2V0IGV4dD0uc3dtDQpzZXQgc25pcHBldD1wb3dlcnNoZWxsIC1ub3AgLWMgaWV4IChbaW8uZmlsZV06OlJlYWRBbGxUZXh0KCRlbnY6MCktc3BsaXQnI1s6XXdpbV9pbmZvWzpdJylbMV07IFdJTV9JTkZPIGluc3RhbGwlZXh0JSAwIDAgIA0Kc2V0IHdfY291bnQ9MCYgZm9yIC9mICJ0b2tlbnM9MS03IGRlbGltcz0sIiAlJWkgaW4gKCciJXNuaXBwZXQlIicpIGRvIChzZXQgd18lJWk9JSVpLCUlaiwlJWssJSVsLCUlbSwlJW4sJSVvJiBzZXQgL2Egd19jb3VudCs9MQ0Kc2V0IGJfJSVpPSUlaiYgc2V0IHBfJSVpPSUlayYgc2V0IGFfJSVpPSUlbCYgc2V0IGxfJSVpPSUlbSYgc2V0IGVfJSVpPSUlbiYgc2V0IGRfJSVpPSUlbyYgc2V0IGlfJSVuPSUlaSYgc2V0IGlfJSVpPSUlbikNCg0KOjojIHByaW50IGF2YWlsYWJsZSBlZGl0aW9ucyBpbiBpbnN0YWxsLmVzZCB2aWEgd2ltX2luZm8gc25pcHBldA0KZWNobzstLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0NCmZvciAvbCAlJWkgaW4gKDEsMSwld19jb3VudCUpIGRvIGNhbGwgZWNobzslJXdfJSVpJSUNCmVjaG87LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tDQoNCjo6IyBnZXQgcmVxdWVzdGVkIGVkaXRpb24gaW4gRUkuY2ZnIG9yIFBJRC50eHQgb3IgT1BUSU9OUw0KaWYgZXhpc3QgcHJvZHVjdC5pbmkgZm9yIC9mICJ0b2tlbnM9MSwyIGRlbGltcz09IiAlJU8gaW4gKHByb2R1Y3QuaW5pKSBkbyBpZiBub3QgIiUlUCIgZXF1ICIiIChzZXQgcGlkXyUlTz0lJVAmIHNldCBwbl8lJVA9JSVPKQ0Kc2V0IEVJPSYgc2V0IE5hbWU9JiBzZXQgZUlEPSYgc2V0IHJlZz0mIHNldCAiY2ZnX2ZpbHRlcj1FZGl0aW9uSUQgQ2hhbm5lbCBPRU0gUmV0YWlsIFZvbHVtZSBfRGVmYXVsdCBWTCAwIDEgXiQiDQppZiBleGlzdCBFSS5jZmcgZm9yIC9mICJ0b2tlbnM9KiIgJSVpIGluICgnZmluZHN0ciAvdiAvaSAvciAiJWNmZ19maWx0ZXIlIiBFSS5jZmcnKSBkbyAoc2V0IEVJPSUlaSYgc2V0IGVJRD0lJWkpDQppZiBleGlzdCBQSUQudHh0IGZvciAvZiAiZGVsaW1zPTsiICUlaSBpbiAoUElELnR4dCkgZG8gc2V0ICUlaSAyPm51bA0KaWYgbm90IGRlZmluZWQgVmFsdWUgZm9yICUlcyBpbiAoJU9QVElPTlMlKSBkbyBpZiBkZWZpbmVkIHBuXyUlcyAoc2V0IE5hbWU9IXBuXyUlcyEmIHNldCBOYW1lPSFOYW1lOmd2bGs9ISkNCmlmIGRlZmluZWQgVmFsdWUgaWYgbm90IGRlZmluZWQgTmFtZSBmb3IgJSVzIGluICglVmFsdWUlKSBkbyAoc2V0IE5hbWU9IXBuXyUlcyEmIHNldCBOYW1lPSFOYW1lOmd2bGs9ISkNCmlmIGRlZmluZWQgRURJVElPTl9TV0lUQ0ggKHNldCBlSUQ9JUVESVRJT05fU1dJVENIJSkgZWxzZSBpZiBkZWZpbmVkIE5hbWUgZm9yICUlcyBpbiAoJU5hbWUlKSBkbyAoc2V0IGVJRD0lTmFtZSUpDQppZiBub3QgZGVmaW5lZCBlSUQgc2V0IGVJRD0lRWRpdGlvbklEJSYgaWYgbm90IGRlZmluZWQgRWRpdGlvbklEIHNldCBlSUQ9UHJvZmVzc2lvbmFsJiBzZXQgRWRpdGlvbklEPVByb2Zlc3Npb25hbA0KaWYgL2kgIiVFZGl0aW9uSUQlIiBlcXUgIiVlSUQlIiAoc2V0IGNoYW5nZWQ9KSBlbHNlIHNldCBjaGFuZ2VkPTENCg0KOjojIHVwZ3JhZGUgbWF0cml4IC0gbm93IGFsc28gZm9yIEVudGVycHJpc2UgRXZhbCAtIGF1dG9tYXRpY2FsbHkgcGljayBlZGl0aW9uIHRoYXQgd291bGQga2VlcCBmaWxlcyBhbmQgYXBwcw0KaWYgL2kgQ29yZUNvdW50cnlTcGVjaWZpYyBlcXUgJWVJRCUgc2V0ICJjb21wPSFlSUQhIiAmIHNldCAicmVnPSFlSUQhIiAmIGlmIG5vdCBkZWZpbmVkIGlfIWVJRCEgc2V0ICJlSUQ9Q29yZSINCmlmIC9pIENvcmVTaW5nbGVMYW5ndWFnZSAgZXF1ICVlSUQlIHNldCAiY29tcD1Db3JlIiAgJiBzZXQgInJlZz0hZUlEISIgJiBpZiBub3QgZGVmaW5lZCBpXyFlSUQhIHNldCAiZUlEPUNvcmUiDQpmb3IgJSVlIGluIChTdGFydGVyIEhvbWVCYXNpYyBIb21lUHJlbWl1bSBDb3JlQ29ubmVjdGVkQ291bnRyeVNwZWNpZmljIENvcmVDb25uZWN0ZWRTaW5nbGVMYW5ndWFnZSBDb3JlQ29ubmVjdGVkIENvcmUpIGRvICgNCiBpZiAvaSAlJWUgIGVxdSAlZUlEJSBzZXQgImNvbXA9Q29yZSIgICYgc2V0ICJlSUQ9Q29yZSINCiBpZiAvaSAlJWVOIGVxdSAlZUlEJSBzZXQgImNvbXA9Q29yZU4iICYgc2V0ICJlSUQ9Q29yZU4iDQogaWYgL2kgJSVlICBlcXUgJWVJRCUgaWYgbm90IGRlZmluZWQgaV9Db3JlICBzZXQgImVJRD1Qcm9mZXNzaW9uYWwiICAmIGlmIG5vdCBkZWZpbmVkIHJlZyBzZXQgInJlZz1Db3JlIg0KIGlmIC9pICUlZU4gZXF1ICVlSUQlIGlmIG5vdCBkZWZpbmVkIGlfQ29yZU4gc2V0ICJlSUQ9UHJvZmVzc2lvbmFsTiIgJiBpZiBub3QgZGVmaW5lZCByZWcgc2V0ICJyZWc9Q29yZU4iDQopDQpmb3IgJSVlIGluIChVbHRpbWF0ZSBQcm9mZXNzaW9uYWxTdHVkZW50IFByb2Zlc3Npb25hbENvdW50cnlTcGVjaWZpYyBQcm9mZXNzaW9uYWxTaW5nbGVMYW5ndWFnZSkgZG8gKA0KICBpZiAvaSAlJWUgZXF1ICVlSUQlIChzZXQgImVJRD1Qcm9mZXNzaW9uYWwiKSBlbHNlIGlmIC9pICUlZU4gZXF1ICVlSUQlIHNldCAiZUlEPVByb2Zlc3Npb25hbE4iDQopDQpmb3IgJSVlIGluIChFbnRlcnByaXNlRyBFbnRlcnByaXNlUyBJb1RFbnRlcnByaXNlUyBJb1RFbnRlcnByaXNlIEVtYmVkZGVkKSBkbyAoDQogIGlmIC9pICUlZSBlcXUgJWVJRCUgKHNldCAiZUlEPUVudGVycHJpc2UiKSBlbHNlIGlmIC9pICUlZU4gZXF1ICVlSUQlIHNldCAiZUlEPUVudGVycHJpc2VOIg0KKQ0KZm9yICUlZSBpbiAoRW50ZXJwcmlzZSBFbnRlcnByaXNlUykgZG8gKA0KICBpZiAvaSAlJWVFdmFsIGVxdSAlZUlEJSAoc2V0ICJlSUQ9RW50ZXJwcmlzZSIpIGVsc2UgaWYgL2kgJSVlTkV2YWwgZXF1ICVlSUQlIHNldCAiZUlEPUVudGVycHJpc2VOIg0KKQ0KaWYgL2kgRW50ZXJwcmlzZSAgZXF1ICVlSUQlIHNldCAiY29tcD0hZUlEISIgJiBpZiBub3QgZGVmaW5lZCBpXyFlSUQhIHNldCAiZUlEPVByb2Zlc3Npb25hbCIgICYgc2V0ICJyZWc9IWNvbXAhIg0KaWYgL2kgRW50ZXJwcmlzZU4gZXF1ICVlSUQlIHNldCAiY29tcD0hZUlEISIgJiBpZiBub3QgZGVmaW5lZCBpXyFlSUQhIHNldCAiZUlEPVByb2Zlc3Npb25hbE4iICYgc2V0ICJyZWc9IWNvbXAhIg0KZm9yICUlZSBpbiAoRWR1Y2F0aW9uIFByb2Zlc3Npb25hbEVkdWNhdGlvbiBQcm9mZXNzaW9uYWxXb3Jrc3RhdGlvbiBQcm9mZXNzaW9uYWwgQ2xvdWQpIGRvICgNCiAgaWYgL2kgJSVlTiBlcXUgJWVJRCUgc2V0ICJjb21wPUVudGVycHJpc2VOIiAgJiBpZiBub3QgZGVmaW5lZCByZWcgc2V0ICJyZWc9JSVlTiINCiAgaWYgL2kgJSVlICBlcXUgJWVJRCUgc2V0ICJjb21wPUVudGVycHJpc2UiICAgJiBpZiBub3QgZGVmaW5lZCByZWcgc2V0ICJyZWc9JSVlIg0KICBpZiAvaSAlJWVOIGVxdSAlZUlEJSBzZXQgImVJRD1Qcm9mZXNzaW9uYWxOIiAmIGlmIGRlZmluZWQgaV8lJWVOICBzZXQgImVJRD0lJWVOIg0KICBpZiAvaSAlJWUgIGVxdSAlZUlEJSBzZXQgImVJRD1Qcm9mZXNzaW9uYWwiICAmIGlmIGRlZmluZWQgaV8lJWUgICBzZXQgImVJRD0lJWUiDQopDQpzZXQgaW5kZXg9JiBzZXQgbHN0PVByb2Zlc3Npb25hbCYgZm9yIC9sICUlaSBpbiAoMSwxLCV3X2NvdW50JSkgZG8gaWYgL2kgIWlfJSVpISBlcXUgIWVJRCEgc2V0ICJpbmRleD0lJWkiICYgc2V0ICJlSUQ9IWlfJSVpISIgDQppZiBub3QgZGVmaW5lZCBpbmRleCBzZXQgaW5kZXg9MSYgc2V0IGVJRD0haV8xISYgaWYgZGVmaW5lZCBpXyVsc3QlIHNldCAiaW5kZXg9IWlfJWxzdCUhIiAmIHNldCAiZUlEPSVsc3QlIiYgc2V0ICJjb21wPUVudGVycHJpc2UiDQpzZXQgQnVpbGQ9IWJfJWluZGV4JSEmIHNldCBPUFRJT05TPSVPUFRJT05TJSAvSW1hZ2VJbmRleCAlaW5kZXglJiBpZiBkZWZpbmVkIGNoYW5nZWQgaWYgbm90IGRlZmluZWQgcmVnIHNldCAicmVnPSFlSUQhIg0KZWNobztDdXJyZW50IGVkaXRpb246ICVFZGl0aW9uSUQlICYgZWNobztSZWdlZGl0IGVkaXRpb246ICVyZWclICYgZWNobztJbmRleDogJWluZGV4JSAgSW1hZ2U6ICVlSUQlDQp0aW1lb3V0IC90IDEwDQoNCjo6IyBkaXNhYmxlIHVwZ3JhZGUgYmxvY2tzDQpyZWcgYWRkICJIS0xNXFNPRlRXQVJFXFBvbGljaWVzXE1pY3Jvc29mdFxXaW5kb3dzXFdpbmRvd3NVcGRhdGUiIC9mIC92IERpc2FibGVXVWZCU2FmZWd1YXJkcyAvZCAxIC90IHJlZ19kd29yZCA+bnVsIDI+bnVsICANCg0KOjojIHByZXZlbnQgdXNhZ2Ugb2YgTUNUIGZvciBpbnRlcm1lZGlhcnkgdXBncmFkZSBpbiBEeW5hbWljIFVwZGF0ZSAoY2F1c2luZyA3IHRvIDE5SDEgaW5zdGVhZCBvZiA3IHRvIDIxSDIgZm9yIGV4YW1wbGUpIA0KaWYgIiVCdWlsZCUiIGd0ciAiMTUwNjMiIChzZXQgT1BUSU9OUz0lT1BUSU9OUyUgL1VwZGF0ZU1lZGlhIERlY2xpbmUpDQoNCjo6IyBza2lwIHdpbmRvd3MgMTEgdXBncmFkZSBjaGVja3M6IGFkZCBsYXVuY2ggb3B0aW9uIHRyaWNrIGlmIG9sZC1zdHlsZSAwLWJ5dGUgZmlsZSB0cmljayBpcyBub3Qgb24gdGhlIG1lZGlhICANCmlmICIlQnVpbGQlIiBsc3MgIjIyMDAwIiBzZXQgL2EgU0tJUF8xMV9TRVRVUF9DSEVDS1M9MA0KcmVnIGFkZCBIS0xNXFNZU1RFTVxTZXR1cFxNb1NldHVwIC9mIC92IEFsbG93VXBncmFkZXNXaXRoVW5zdXBwb3J0ZWRUUE1vckNQVSAvZCAxIC90IHJlZ19kd29yZCA+bnVsIDI+bnVsICZyZW0gOjojIFRQTSAxLjIrIG9ubHkNCmlmICIlU0tJUF8xMV9TRVRVUF9DSEVDS1MlIiBlcXUgIjEiIGNkLj5hcHByYWlzZXJyZXMuZGxsIDI+bnVsICYgcmVtIDo6IyB3cml0YWJsZSBtZWRpYSBvbmx5DQpmb3IgJSVBIGluIChhcHByYWlzZXJyZXMuZGxsKSBkbyBpZiAlJX56QSBndHIgMCAoc2V0IFRSSUNLPS9Qcm9kdWN0IFNlcnZlciApIGVsc2UgKHNldCBUUklDSz0pDQppZiAiJVNLSVBfMTFfU0VUVVBfQ0hFQ0tTJSIgZXF1ICIxIiAoc2V0IE9QVElPTlM9JVRSSUNLJSVPUFRJT05TJSkNCg0KOjojIGF1dG8gdXBncmFkZSB3aXRoIGVkaXRpb24gbGllIHdvcmthcm91bmQgdG8ga2VlcCBmaWxlcyBhbmQgYXBwcyAtIGFsbCAxOTA0eCBidWlsZHMgYWxsb3cgdXAvZG93bmdyYWRlIGJldHdlZW4gdGhlbQ0KaWYgZGVmaW5lZCByZWcgY2FsbCA6cmVuYW1lICVyZWclDQpzdGFydCAiYXV0byIgc2V0dXBwcmVwLmV4ZSAlT1BUSU9OUyUNCmVjaG87RE9ORQ0KDQpFWElUIC9iDQoNCjpyZW5hbWUgRWRpdGlvbklEDQpzZXQgIk5UPUhLTE1cU09GVFdBUkVcTWljcm9zb2Z0XFdpbmRvd3MgTlRcQ3VycmVudFZlcnNpb24iDQpmb3IgJSV2IGluIChDb21wb3NpdGlvbkVkaXRpb25JRCBFZGl0aW9uSUQgUHJvZHVjdE5hbWUpIGRvIHJlZyBhZGQgIiVOVCUiIC92ICUldl91bmRvIC9kICIhJSV2ISIgL2YgPm51bCAyPm51bA0KZm9yICUlQSBpbiAoMzIgNjQpIGRvICggDQogcmVnIGFkZCAiJU5UJSIgL3YgQ29tcG9zaXRpb25FZGl0aW9uSUQgL2QgIiVjb21wJSIgL2YgL3JlZzolJUENCiByZWcgYWRkICIlTlQlIiAvdiBFZGl0aW9uSUQgL2QgIiV+MSIgL2YgL3JlZzolJUENCiByZWcgYWRkICIlTlQlIiAvdiBQcm9kdWN0TmFtZSAvZCAiJX4xIiAvZiAvcmVnOiUlQQ0KKSA+bnVsIDI+bnVsDQpleGl0IC9iDQoNCjpyZWdfcXVlcnkgW1VTQUdFXSBjYWxsIDpyZWdfcXVlcnkgIkhLQ1VcVm9sYXRpbGUgRW52aXJvbm1lbnQiIFZhbHVlIHZhcmlhYmxlDQooZm9yIC9mICJ0b2tlbnM9MioiICUlUiBpbiAoJ3JlZyBxdWVyeSAiJX4xIiAvdiAiJX4yIiAvc2UgInwiICU0IDJePm51bCcpIGRvIHNldCAiJX4zPSUlUyIpICYgZXhpdCAvYg0KDQojOldJTV9JTkZPOiMgW1BBUkFNU106ICJmaWxlIiBbb3B0aW9uYWxdSW5kZXggb3IgMCA9IGFsbCAgT3V0cHV0IDAgPSB0eHQgMSA9IHhtbCAyID0gZmlsZS50eHQgMyA9IGZpbGUueG1sIDQgPSB4bWwgb2JqZWN0DQpzZXQgXiAjPTskZjA9W2lvLmZpbGVdOjpSZWFkQWxsVGV4dCgkZW52OjApOyAkMD0oJGYwLXNwbGl0ICcjWzpdV0lNX0lORk9bOl0nICwzKVsxXTsgJDE9JGVudjoxLXJlcGxhY2UnKFtgQCRdKScsJ2AkMSc7IGlleCgkMCskMSkNCnNldCBeICM9JiBzZXQgIjA9JX5mMCImIHNldCAxPTtXSU1fSU5GTyAlKiYgcG93ZXJzaGVsbCAtbm9wIC1jICIlIyUiJiBleGl0IC9iICVlcnJvcmNvZGUlDQpmdW5jdGlvbiBXSU1fSU5GTyAoJGZpbGUgPSAnaW5zdGFsbC5lc2QnLCAkaW5kZXggPSAwLCAkb3V0ID0gMCkgeyA6aW5mbyB3aGlsZSAoJHRydWUpIHsNCiAgJGJsb2NrID0gMjA5NzE1MjsgJGJ5dGVzID0gbmV3LW9iamVjdCAnQnl0ZVtdJyAoJGJsb2NrKTsgJGJlZ2luID0gW3VpbnQ2NF0wOyAkZmluYWwgPSBbdWludDY0XTA7ICRsaW1pdCA9IFt1aW50NjRdMA0KICAkc3RlcHMgPSBbaW50XShbdWludDY0XShbSU8uRmlsZUluZm9dJGZpbGUpLkxlbmd0aCAvICRibG9jayAtIDEpOyAkZW5jID0gW1RleHQuRW5jb2RpbmddOjpHZXRFbmNvZGluZygyODU5MSk7ICRkZWxpbSA9IEAoKQ0KICBmb3JlYWNoICgkZCBpbiAnL0lOU1RBTExBVElPTlRZUEUnLCcvV0lNJykgeyRkZWxpbSArPSAkZW5jLkdldFN0cmluZyhbVGV4dC5FbmNvZGluZ106OlVuaWNvZGUuR2V0Qnl0ZXMoW2NoYXJdNjArICRkICtbY2hhcl02MikpfQ0KICAkZiA9IG5ldy1vYmplY3QgSU8uRmlsZVN0cmVhbSAoJGZpbGUsIDMsIDEsIDEpOyAkcCA9IDA7ICRwID0gJGYuU2VlaygwLCAyKQ0KICBmb3IgKCRvID0gMTsgJG8gLWxlICRzdGVwczsgJG8rKykgeyANCiAgICAkcCA9ICRmLlNlZWsoLSRibG9jaywgMSk7ICRyID0gJGYuUmVhZCgkYnl0ZXMsIDAsICRibG9jayk7IGlmICgkciAtbmUgJGJsb2NrKSB7d3JpdGUtaG9zdCBpbnZhbGlkIGJsb2NrICRyOyBicmVha30NCiAgICAkdSA9IFtUZXh0LkVuY29kaW5nXTo6R2V0RW5jb2RpbmcoMjg1OTEpLkdldFN0cmluZygkYnl0ZXMpOyAkdCA9ICR1Lkxhc3RJbmRleE9mKCRkZWxpbVswXSwgW1N0cmluZ0NvbXBhcmlzb25dOjpPcmRpbmFsKSANCiAgICBpZiAoJHQgLWx0IDApIHsgJHAgPSAkZi5TZWVrKC0kYmxvY2ssIDEpfSBlbHNlIHsgW3ZvaWRdJGYuU2VlaygoJHQgLSRibG9jayksIDEpDQogICAgICBmb3IgKCRvID0gMTsgJG8gLWxlICRibG9jazsgJG8rKykgeyBbdm9pZF0kZi5TZWVrKC0yLCAxKTsgaWYgKCRmLlJlYWRCeXRlKCkgLWVxIDB4ZmUpIHskYmVnaW4gPSAkZi5Qb3NpdGlvbjsgYnJlYWt9IH0NCiAgICAgICRsaW1pdCA9ICRmLkxlbmd0aCAtICRiZWdpbjsgaWYgKCRsaW1pdCAtbHQgJGJsb2NrKSB7JHggPSAkbGltaXR9IGVsc2UgeyR4ID0gJGJsb2NrfQ0KICAgICAgJGJ5dGVzID0gbmV3LW9iamVjdCAnQnl0ZVtdJyAoJHgpOyAkciA9ICRmLlJlYWQoJGJ5dGVzLCAwLCAkeCkgDQogICAgICAkdSA9IFtUZXh0LkVuY29kaW5nXTo6R2V0RW5jb2RpbmcoMjg1OTEpLkdldFN0cmluZygkYnl0ZXMpOyAkdCA9ICR1LkluZGV4T2YoJGRlbGltWzFdLCBbU3RyaW5nQ29tcGFyaXNvbl06Ok9yZGluYWwpDQogICAgICBpZiAoJHQgLWdlIDApIHtbdm9pZF0kZi5TZWVrKCgkdCArIDEyIC0keCksIDEpOyAkZmluYWwgPSAkZi5Qb3NpdGlvbn0gOyBicmVhayB9IH0NCiAgaWYgKCRiZWdpbiAtZ3QgMCAtYW5kICRmaW5hbCAtZ3QgJGJlZ2luKSB7DQogICAgJHggPSAkZmluYWwgLSAkYmVnaW47IFt2b2lkXSRmLlNlZWsoLSR4LCAxKTsgJGJ5dGVzID0gbmV3LW9iamVjdCAnQnl0ZVtdJyAoJHgpOyAkciA9ICRmLlJlYWQoJGJ5dGVzLCAwLCAkeCkNCiAgICBpZiAoJHIgLW5lICR4KSB7JGYuRGlzcG9zZSgpOyBicmVha30gZWxzZSB7W3htbF0keG1sID0gW1RleHQuRW5jb2RpbmddOjpVbmljb2RlLkdldFN0cmluZygkYnl0ZXMpOyAkZi5EaXNwb3NlKCl9DQogIH0gZWxzZSB7JGYuRGlzcG9zZSgpfSA7IGJyZWFrIDppbmZvIH0NCiAgaWYgKCRvdXQgLWVxIDEpIHtbY29uc29sZV06Ok91dHB1dEVuY29kaW5nPVtUZXh0LkVuY29kaW5nXTo6VVRGODsgJHhtbC5TYXZlKFtDb25zb2xlXTo6T3V0KTsgJyc7IHJldHVybn0gDQogIGlmICgkb3V0IC1lcSAzKSB7dHJ5eyR4bWwuU2F2ZSgoJGZpbGUtcmVwbGFjZSdlc2QkJywneG1sJykpfWNhdGNoe307IHJldHVybn07IGlmICgkb3V0IC1lcSA0KSB7cmV0dXJuICR4bWx9DQogICR0eHQgPSAnJzsgZm9yZWFjaCAoJGkgaW4gJHhtbC5XSU0uSU1BR0UpIHtpZiAoJGluZGV4IC1ndCAwIC1hbmQgJCgkaS5JTkRFWCkgLW5lICRpbmRleCkge2NvbnRpbnVlfTsgW2ludF0kYT0nMScrJGkuV0lORE9XUy5BUkNIDQogICR0eHQrPSAkaS5JTkRFWCsnLCcrJGkuV0lORE9XUy5WRVJTSU9OLkJVSUxEKycsJyskaS5XSU5ET1dTLlZFUlNJT04uU1BCVUlMRCsnLCcrJChAezEwPSd4ODYnOzE1PSdhcm0nOzE5PSd4NjQnOzExMj0nYXJtNjQnfVskYV0pDQogICR0eHQrPSAnLCcrJGkuV0lORE9XUy5MQU5HVUFHRVMuTEFOR1VBR0UrJywnKyRpLldJTkRPV1MuRURJVElPTklEKycsJyskaS5OQU1FK1tjaGFyXTEzK1tjaGFyXTEwfTsgJHR4dD0kdHh0LXJlcGxhY2UnLCg/PSwpJywnLCAnDQogIGlmICgkb3V0IC1lcSAyKSB7dHJ5e1tpby5maWxlXTo6V3JpdGVBbGxUZXh0KCgkZmlsZS1yZXBsYWNlJ2VzZCQnLCd0eHQnKSwkdHh0KX1jYXRjaHt9OyByZXR1cm59OyBpZiAoJG91dCAtZXEgMCkge3JldHVybiAkdHh0fQ0KfSAjOldJTV9JTkZPOiMgUXVpY2sgV0lNIFNXTSBFU0QgSVNPIGluZm8gdjIgLSBsZWFuIGFuZCBtZWFuIHNuaXBwZXQgYnkgQXZlWW8sIDIwMjENCg==
"@ -replace '\s',''

# USB kök dizine kopyalanacak dosyalar
$targetAutoUnattend = Join-Path $usbntfs "AutoUnattend.xml"
$targetauto = Join-Path $usbntfs "auto.cmd"

# install.wim veya install.esd kontrolü
$hasInstallImage = Get-Item "$usbntfs\sources\install.*" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'install\.(wim|esd)$' }

if ($hasInstallImage) {
    # Birinci dosyayı yaz
    [IO.File]::WriteAllBytes($targetAutoUnattend, [Convert]::FromBase64String($base64AutoUnattend))
    Write-Host "AutoUnattend.xml USB kök dizine yazıldı." -ForegroundColor Green

    # İkinci dosyayı yaz
    [IO.File]::WriteAllBytes($targetauto, [Convert]::FromBase64String($base64auto))
    Write-Host "auto.cmd USB kök dizine yazıldı." -ForegroundColor Green
}
else {
    Write-Host "install.wim veya install.esd bulunamadı, dosyalar yazılmadı." -ForegroundColor Yellow
}