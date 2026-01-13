# Lingos

**Lingos**, çok dilli dil öğrenme platformu. Renkli konu kartları, interaktif alıştırmalar ve metin-konuşma teknolojileriyle zenginleştirilmiş bir öğrenme deneyimi sunar.

## 🌟 Özellikler

### Çok Dilli Destek
- **Desteklenen Diller**: Türkçe (TR), İngilizce (EN), Fince (FI), Fransızca (FR)
- Ana dil ve hedef dil seçimi
- Uygulama arayüzü dil desteği
- iOS ve macOS için yerel dil desteği (Info.plist)

### Öğrenme Aktiviteleri
Uygulama, her terim için çeşitli öğrenme aktiviteleri sunar:

1. **Meet (Tanış)**: Yeni kelimelerle tanışma - görsel, ses ve çeviri gösterimi
2. **Memory (Hafıza)**: Kapalı kartları eşleştirme oyunu
3. **Pair (Eşleştir)**: Sol ve sağ taraftaki kartları eşleştirme
4. **Select (Seçim)**: Çoktan seçmeli sorular (görselden kelime, sesten görsel, vb.)
5. **True/False (Doğru/Yanlış)**: İki kartın uyumlu olup olmadığını belirleme
6. **Merge (Birleştir)**: Kelimeyi parçalardan oluşturma
7. **Speak (Konuş)**: Konuşma tanıma ile telaffuz pratiği
8. **Display (Göster)**: Hatırlama ve gözden geçirme aktivitesi

### Teknolojiler
- **Text-to-Speech (TTS)**: Kelimelerin seslendirilmesi
- **Speech-to-Text (STT)**: Konuşma tanıma
- **Ses Efektleri**: Doğru/yanlış cevaplar için ses geri bildirimi
- **Animasyonlar**: Akıcı kullanıcı deneyimi

### İçerik Yapısı
- **Modüler İçerik**: Her dil için ayrı JSON dosyaları
- **Konu Bazlı Öğrenme**: Hayvanlar, Renkler, Sayılar, Şekiller, Yönler
- **Emoji Desteği**: Her terim ve konu için görsel gösterim
- **Soru Bankası**: Bazı terimler için çoklu soru desteği

## 📁 Proje Yapısı

```
lingos/
├── lib/
│   ├── main.dart                    # Uygulama giriş noktası
│   ├── models/                      # Veri modelleri
│   │   ├── term.dart                # Terim modeli
│   │   └── topic.dart               # Konu modeli
│   ├── pages/                       # Sayfa widget'ları
│   │   ├── gate_page.dart           # İlk açılış - dil seçimi
│   │   ├── home_page.dart           # Ana sayfa - konu seçimi
│   │   ├── learning_page.dart       # Öğrenme akışı yönetimi
│   │   └── learning/
│   │       └── actions/             # Öğrenme aktiviteleri
│   │           ├── display_action.dart
│   │           ├── memory_action.dart
│   │           ├── pair_action.dart
│   │           ├── select_action.dart
│   │           ├── true_false_action.dart
│   │           ├── merge_action.dart
│   │           ├── speak_action.dart
│   │           └── completed_action.dart
│   ├── services/                    # Servisler
│   │   ├── language_service.dart    # Dil yönetimi
│   │   ├── term_service.dart       # İçerik yükleme
│   │   ├── tts_service.dart        # Text-to-Speech
│   │   ├── stt_service.dart        # Speech-to-Text
│   │   ├── sound_service.dart      # Ses efektleri
│   │   └── app_localizations.dart  # Yerelleştirme
│   └── widgets/                     # Yeniden kullanılabilir widget'lar
│       ├── audio_card.dart
│       ├── visual_card.dart
│       ├── target_card.dart
│       ├── true_false_card.dart
│       └── merge_card.dart
├── assets/
│   ├── data/                        # İçerik dosyaları
│   │   ├── content.json             # Ana içerik (id ve emoji)
│   │   ├── content_en.json          # İngilizce çeviriler
│   │   ├── content_tr.json          # Türkçe çeviriler
│   │   ├── content_fi.json          # Fince çeviriler
│   │   └── content_fr.json          # Fransızca çeviriler
│   └── sound_effects/               # Ses efektleri
│       ├── correct.wav
│       └── incorrect.mp3
├── ios/                              # iOS platform dosyaları
├── macos/                            # macOS platform dosyaları
└── android/                          # Android platform dosyaları
```

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- Flutter SDK (3.10.3 veya üzeri)
- Dart SDK
- iOS/macOS için Xcode (macOS geliştirme için)
- Android Studio (Android geliştirme için)

### Kurulum
```bash
# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

### Platform Seçimi
```bash
# macOS için
flutter run -d macos

# iOS için
flutter run -d ios

# Android için
flutter run -d android
```

## 📱 Kullanım

### İlk Açılış
1. Uygulama açıldığında dil seçim ekranı görünür
2. Ana dilinizi seçin (öğrenmek istediğiniz dil)
3. Hedef dilinizi seçin (öğrenmek istediğiniz dil)
4. Ana dil ve hedef dil farklı olmalıdır

### Öğrenme Akışı
1. Ana sayfadan bir konu seçin (örn: Hayvanlar)
2. Öğrenme aktiviteleri otomatik olarak sırayla gösterilir
3. Her aktiviteyi tamamlayarak ilerleyin
4. Progress bar ile ilerlemenizi takip edin

### Aktivite Türleri
- **Görsel Kartlar**: Emoji ve görsellerle kelime öğrenme
- **Ses Kartları**: TTS ile telaffuz dinleme
- **Hedef Kartlar**: Metin tabanlı gösterim
- **Etkileşimli Kartlar**: Dokunma, sürükle-bırak, seçim

## 🛠️ Teknik Detaylar

### Bağımlılıklar
- `flutter_tts`: Text-to-Speech desteği
- `speech_to_text`: Konuşma tanıma
- `just_audio`: Ses efektleri çalma
- `shared_preferences`: Kullanıcı tercihlerini saklama
- `flutter_localizations`: Çoklu dil desteği

### İçerik Yapısı
İçerik modüler bir yapıda organize edilmiştir:

**content.json**: Sadece ID'ler ve emoji'ler
```json
{
  "topics": [{"id": "animals", "emoji": "🐾"}],
  "terms": [{"id": "animals_1", "topicIds": ["animals"], "emoji": "🐱"}]
}
```

**content_xx.json**: Her dil için çeviriler
```json
{
  "topics": {"animals": "Hayvanlar"},
  "terms": {"animals_1": "kedi"},
  "questions": {"animals_1": ["Hangi hayvan miyav der?"]}
}
```

### Mimari Prensipleri
- **Separation of Concerns**: Her servis ve widget tek bir sorumluluğa sahip
- **Layered Architecture**: Models → Services → Pages → Widgets
- **Single Source of Truth**: TermService merkezi veri yönetimi
- **Unidirectional Data Flow**: State yönetimi tek yönlü
- **Extensibility**: Yeni diller ve aktiviteler kolayca eklenebilir
- **Testability**: Servisler ve modeller test edilebilir yapıda

## 🌍 Yeni Dil Ekleme

- [ ] `assets/data` → `content_xx.json`
- [ ] `pubspec.yaml` → `assets` listesi
- [ ] `lib/services/language_service.dart` → `supportedLanguages`, `getLanguageDisplayName()`, `getLanguageEmoji()`
- [ ] `lib/main.dart` → `supportedLocales`
- [ ] `ios/Runner/Info.plist` → `CFBundleLocalizations`
- [ ] `macos/Runner/Info.plist` → `CFBundleLocalizations`
- [ ] `lib/models/term.dart` → `textXx`, constructor, `getText()`, `getQuestion()`, `fromJson()`, `toJson()`
- [ ] `lib/models/topic.dart` → `textXx`, constructor, `getName()`, `fromJson()`
- [ ] `lib/services/term_service.dart` → Dil yükleme listesi, `getTermText()`
- [ ] `lib/services/app_localizations.dart` → `_getString()`, `_xxStrings` map, tüm dil map'lerine `language_xx`

## 📝 Lisans

Bu proje özel kullanım içindir (`publish_to: 'none'`).

## 👥 Katkıda Bulunma

Proje aktif geliştirme aşamasındadır. Öneriler ve geri bildirimler için issue açabilirsiniz.

## 📄 Versiyon

**v1.0.0+1** - İlk stabil sürüm

---

**Lingos** ile eğlenceli ve etkili bir şekilde yeni diller öğrenin! 🚀
