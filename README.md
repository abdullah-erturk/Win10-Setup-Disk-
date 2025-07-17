<a href="https://buymeacoffee.com/abdullaherturk" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>

# 💽 Win10+ Setup - Win To Go

![sample](https://github.com/abdullah-erturk/Win10-Setup-Disk-/blob/main/1.jpg)


## ⚠️ DİKKAT
> GUI arayüzde TR karakterlerin bozuk görünmemesi için bu dosyayı indirin: tr_Win10+Setup-WinToGo.zip

> Bu PowerShell aracı, bir Windows ISO dosyasından USB kurulum diski veya Windows To Go ortamı oluşturmanızı sağlar. ISO seçimi, disk biçimlendirme, sürüm seçimi ve kurulum adımları grafik arayüz üzerinden kolayca yönetilir.

> This PowerShell tool lets you create a USB installation disk or Windows To Go media from a Windows ISO file. ISO selection, disk formatting, version selection, and installation steps are easily managed through the graphical interface.

<details>
<summary>Önizlemeler/Previews</summary>

![sample](https://raw.githubusercontent.com/abdullah-erturk/Win10-Setup-Disk-/main/1.jpg)  
![sample](https://raw.githubusercontent.com/abdullah-erturk/Win10-Setup-Disk-/main/2.jpg)  
![sample](https://raw.githubusercontent.com/abdullah-erturk/Win10-Setup-Disk-/main/3.jpg)

</details>

---

<details>
<summary>Türkçe Açıklama</summary>

## 🚀 Özellikler

- Windows ISO dosyasından kurulum USB'si oluşturur.  
- Windows To Go (taşınabilir Windows) desteği. 
- ISO, install.wim veya install.esd dosyalarını destekler.
- `install.wim` içinde bulunan Windows sürümünü seçme özelliği. (To Go için)
- VHD/VHDX ve USB disk desteği. 
- GUI (grafiksel arayüz) ile kullanım.
- Tam ilerleme çubuğu ve tahmini süre göstergeleri.
- BCD ve BOOT yapılandırma desteği.
- FAT32'nin 4 GB sınırlaması nedeniyle 4 GB'ın üzerinde install.wim dosyasına sahip Windows ISO dosyalarını kolayca USB diske yazdırır.
- Katılımsız kurulum için özel xml dosya seçim desteği

## Windows 11 Sistem Gereksinimlerini Atlatma
USB Disk oluşturma esnasında:
`AutoUnattend.xml` ve `auto.cmd` dosyasını otomatik olarak USB kök dizinine kopyalar.

Bu sayede `AutoUnattend.xml` dosyası ile sıfırdan kurulumda ve `auto.cmd` dosyası ile de yükseltme yoluyla Windows 11 sistem gereksinimleri atlanmış olur.

✅TPM, Secure Boot, CPU, RAM, disk kontrollerini tamamen atlar.

✅Yerel kullanıcı hesabı ile kuruluma izin verir.

✅Uyumlu olmayan sistem uyarılarını engeller.

✅Güncelleme kanalı uyarılarını bastırır.

✅Masaüstü uyarılarını gizler.


## 💡 Gereksinimler

- **Windows 10 veya 11**
- **Yönetici (Administrator)** yetkileriyle çalıştırılmalıdır
- PowerShell 5.x veya üzeri
- `DISM`, `bcdboot`, `diskpart` erişimi

## 🔧 Kullanım

1. Script dosyasına sağ tıklayın, **Yönetici olarak çalıştır** seçeneğini seçin  
2. ISO dosyasını veya `install.wim/esd` dosyasını seçin  
3. Bağlı USB/VHD cihazlardan birini seçin  
4. "Kurulum Diski" veya "Windows To Go" seçeneğini işaretleyin  
5. "Diski Oluştur" düğmesine tıklayın  
6. Windows ISO'su içinden kurulacak sürümü seçin  
7. Otomatik olarak bölümlendirme, biçimlendirme ve dosya aktarımı işlemleri yapılır  
8. Script, disk yapılandırmalarını (BCD, BOOT) tamamlar

## 🔐 Uyarı

> Seçilen USB/VHD cihaz **tamamen biçimlendirilir** ve üzerindeki tüm veriler silinir.  
> Lütfen yedek almayı unutmayın.

## 💡NOT
- Windows 10 sürüm 1507, 1511 veya 1607 Ana Bilgisayar İşletim Sisteminde Win10+ Kurulum Diski oluşturamazsınız. Windows 10'un bu eski sürümleri, çıkarılabilir depolama aygıtlarında birden çok bölüm okumayı ve oluşturmayı desteklemez.

## 🛠 Katkıda Bulunanlar

- `@rpo`, `@freddie-o`, `@BAU`, `@abbodi1406`, `@mephistooo2`, `@bensuslu11`

- Her türlü öneri ve geri bildirim için lütfen GitHub üzerinden katkıda bulunun.

</details>

---

<details>
<summary>English Description</summary>

## 🚀 Features

- Create bootable Windows installation USB from ISO  
- Full **Windows To Go** support  
- Supports `install.wim`, `install.esd` and ISO formats  
- Ability to select Windows version in install.wim (for To Go)
- Detects VHD/VHDX and USB drives  
- GUI powered with progress bars and ETA  
- Auto partitioning with dual-partition structure (FAT32 + NTFS)  
- Automatically configures boot via `bcdboot`, `bcdedit`, etc.
- For Windows ISOs that have an install.wim over 4GB -- due to the 4GB limitation of FAT32
- Support for custom XML file selection for unattended installation

## Bypass Windows 11 System Requirements
While creating a USB Disk:
It automatically copies the `AutoUnattend.xml` and `auto.cmd` files to the USB root directory.

This way, the Windows 11 system requirements can be bypassed during a clean install using the `AutoUnattend.xml` file, and during an upgrade using the `auto.cmd` file.

✅Completely bypasses TPM, Secure Boot, CPU, RAM, disk checks.

✅Allows installation with a local user account.

✅Prevents non-compliant system warnings.

✅Suppresses update channel warnings.

✅Hides desktop alerts.


## 💡 Requirements

- **Windows 10 or 11**
- Must be run as **Administrator**
- PowerShell 5.x or higher
- Requires access to: `DISM`, `bcdboot`, `diskpart`

## 🔧 How to Use

1. Right-click on the script and choose **Run as Administrator**  
2. Select your Windows ISO or `install.wim/esd`  
3. Choose a connected USB/VHD target device  
4. Select either **Setup USB** or **Windows To Go** mode  
5. Click **Create Disk** to begin  
6. Choose your preferred Windows version if prompted  
7. Script performs all necessary steps (formatting, copying, BCD setup, etc.)  
8. Done!

## ⚠️ Warning

> The selected USB/VHD device will be **completely formatted** and all data will be erased.  
> Please make sure to back up your data.

## 💡NOTE
- You cannot create a Win10+ Setup Disk on Windows 10 versions 1507, 1511 or 1607 Host OS. These older versions of Windows 10 do not support reading and creating multiple partitions on removable storage devices.

## 🛠 Contributors

- `@rpo`, `@freddie-o`, `@BAU`, `@abbodi1406`, `@mephistooo2`, `@bensuslu11`

- Please contribute via GitHub for any suggestions or feedback.

</details>
