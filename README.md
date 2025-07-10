# 💽 Windows Kurulum USB'si ve Windows To Go Oluşturucu

> GUI tabanlı PowerShell scripti ile UEFI uyumlu Windows kurulum diski veya Windows To Go ortamı hazırlayın.  
> NTFS ve FAT32 çift bölmeli yapı desteği, ISO bağlama, VHD/VHDX aygıt algılama ve install.wim sürüm seçimiyle birlikte.

---

<details>
<summary>🇹🇷 Türkçe Açıklama</summary>

## 🚀 Özellikler

- Windows ISO dosyasından kurulum USB'si oluşturur  
- Windows To Go (taşınabilir Windows) desteği  
- ISO, install.wim veya install.esd dosyalarını destekler  
- `install.wim` içinde bulunan Windows sürümünü seçme özelliği  
- VHD/VHDX ve USB disk desteği  
- GUI (grafiksel arayüz) ile kullanım  
- Tam ilerleme çubuğu ve tahmini süre göstergeleri  
- BCD ve BOOT yapılandırma desteği

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

## 🛠 Katkıda Bulunanlar

- `@rpo`, `@freddie-o`, `@BAU`, `@abbodi1406`, `@mephistooo2`

</details>

---

<details>
<summary>🇬🇧 English Description</summary>

## 🚀 Features

- Create bootable Windows installation USB from ISO  
- Full **Windows To Go** support  
- Supports `install.wim`, `install.esd` and ISO formats  
- Lets user select desired Windows edition from WIM  
- Detects VHD/VHDX and USB drives  
- GUI powered with progress bars and ETA  
- Auto partitioning with dual-partition structure (FAT32 + NTFS)  
- Automatically configures boot via `bcdboot`, `bcdedit`, etc.

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

## 🛠 Contributors

- `@rpo`, `@freddie-o`, `@BAU`, `@abbodi1406`, `@mephistooo2`

</details>
