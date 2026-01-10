# lingos

Renkli konu kartları ve metin-konuşma destekli alıştırmalarla TR/EN/FI öğrenme deneyimi.

## Özellikler
- Dil seçimi (ana/hedef) ilk açılışta yapılır, tercihler saklanır.
- Konular ve terimler `assets/data/content.json` içinden yüklenir (hayvanlar, renkler, sayılar, şekiller, yönler; her terimde emoji, çoklu topic desteği).
- Öğrenme akışı: Meet adımı (kart + çeviri, animasyonlu gösterim, TTS), ardından Listen & Select (işitsel çoktan seçmeli, doğru seçim sonrası Remember adımı). Next butonu TTS bitene kadar pasif.
- TTS `flutter_tts` ile; dil kodları TR/EN/FI için sistem sesi kullanılır ve konuşma tamamlanması beklenir.
- Tema renkleri ve progress bar her konuya özel tonlarla ilerlemeyi gösterir.

## Çalıştırma
```bash
flutter pub get
flutter run
```
İsteğe göre platform seçin (örn. `-d macos`).

## Yapı
- `lib/main.dart`: başlatma, dil ve veri yükleme, MaterialApp.
- `lib/pages/`: Gate (dil kontrolü), Home (konu grid), Learning (akış), Settings.
- `lib/pages/learning/actions/`: Meet, Listen & Select, Remember adımları.
- `lib/services/`: dil tercihleri, TTS, terim/topic veri sağlayıcıları.
- `assets/data/content.json`: konu ve terim içeriği (küçük harf metinler, renkler, emojiler).
