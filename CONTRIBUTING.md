# Katkı Rehberi (Git İş Akışı)

`main` dalı korumalıdır: **doğrudan push yapılamaz**, her değişiklik bir Pull Request (PR) ile gelir ve repo sorumlusu (@aozcan4482) onaylamadan birleştirilemez.

## 1. Branch isimlendirme

```
feature/WP-<no>-<kisa-aciklama>     yeni iş paketi / özellik
fix/<kisa-aciklama>                 hata düzeltme
docs/<kisa-aciklama>                yalnızca doküman
```

Örnekler: `feature/WP-01-flutter-prototip`, `feature/WP-04-er-diyagrami`, `docs/sprint-1-rapor`

## 2. Adım adım

```bash
# 1) Repoyu bir kere klonla
git clone https://github.com/aozcan4482/SEN0421_AcademicAssestment.git
cd SEN0421_AcademicAssestment

# 2) Her işe başlamadan önce main'i güncelle
git checkout main
git pull origin main

# 3) Kendi branch'ini aç
git checkout -b feature/WP-02-yetki-matrisi

# 4) Dosyalarını ilgili klasöre koy, commit at
git add docs/sprint-1/WP-02_kimlik-dogrulama/
git commit -m "WP-02: Yetki matrisi ve CATS PoC dokümanı eklendi"

# 5) Branch'i GitHub'a gönder
git push -u origin feature/WP-02-yetki-matrisi
```

6) GitHub'da çıkan **"Compare & pull request"** butonuna bas → hedef `main` → PR şablonunu doldur → **Create pull request**.

7) İnceleme sonucu değişiklik istenirse aynı branch'te düzeltip tekrar `git push` yap; PR kendiliğinden güncellenir.

8) PR birleştirildikten sonra branch silinir. Yeni iş için 2. adımdan tekrar başla.

## 3. Commit mesajı

```
WP-<no>: <ne yapıldı>
```

Örnek: `WP-03: Seviye 1 DFD diyagramı eklendi`

## 4. Kurallar

- Bir PR = bir iş paketi. Başkasının WP klasörüne dokunma.
- `main`'e force push yapma, branch'i kendin birleştirme.
- PR açıklamasına ilgili WP numarasını ve standart maddesini yaz (ilerleme raporundaki "Kanıt / Çıktı" sütunu PR numarası ile doldurulacak).
- Çakışma (conflict) olursa: `git pull origin main` yap, çakışmayı çöz, commit atıp tekrar push et.
