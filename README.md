# Academic Assessment & Audit Management System

**ISO/IEC 25010 ve IEEE Standartlarına Uygun Akademik Süreç ve Değerlendirme Denetim Portalı**

İstanbul Kültür Üniversitesi — SEN0421 Software Development with Standards

## Mimari

Üç katmanlı yapı:

| Katman | Teknoloji | Klasör |
|---|---|---|
| Mobil istemci | Flutter | `mobile/` |
| REST API | Node.js / Express | `backend/` |
| Veritabanı | PostgreSQL (migration betikleri) | `database/` |
| Harici servis | CATS SSO | – |

## Klasör Yapısı

```
mobile/                 Flutter uygulaması
backend/                Node.js / Express API
database/               Migration ve seed betikleri
docs/
  reports/              İki haftalık ilerleme raporları
  sprint-1/
    WP-01_mobil-prototip/      Arda Özcan
    WP-02_kimlik-dogrulama/    Aysu Akdüzen
    WP-03_sistem-mimarisi/     Barış Akman, Bora Kaan Haydar
    WP-04_veritabani/          Bora Kaan Haydar
```

## Ekip

| Ad Soyad | Rol |
|---|---|
| Arda Özcan | Mobil Arayüz, Repo Sorumlusu |
| Bora Kaan Haydar | Veritabanı & Backend Lideri |
| Aysu Akdüzen | Kimlik Doğrulama & Güvenlik |
| Barış Akman | Sistem Mimarı |

## Katkı Kuralları

`main` dalına doğrudan push yapılamaz. Her geliştirme ayrı bir feature branch'te yapılır ve Pull Request ile gönderilir.
Ayrıntılar: [CONTRIBUTING.md](CONTRIBUTING.md)
