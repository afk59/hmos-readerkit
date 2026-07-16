# Reader Kit Dokümantasyonu — Kod, Yazım ve API Hata Raporu

**Tarih:** 2026-07-16
**Kapsam:** `./docs` klasöründeki 11 resmi Reader Kit dokümanı (1-about-kit.txt … 11-Notifying the Reading Progress.txt)
**Yöntem:** Her dosyadaki kod örnekleri, API imzaları ve açıklama metinleri satır satır incelenmiş; ArkTS'in derleme kuralları (tip güvenliği, `catch` bloğu tipleme, `any`/`unknown` kısıtlaması) ve HarmonyOS API kullanım kalıpları temel alınarak değerlendirilmiştir.

Aşağıdaki bulgular, dosya sırasına göre gruplanmıştır. Her bulgu için **Dosya Adı**, **Sorun Nedir?**, **Neden Hatalı?** ve **Önerilen Çözüm** alanları doldurulmuştur.

---

## 1. Dosya: `2-Obtaining Book Information.txt`

### 1.1 — `PixelMap` tipi yanlış/eksik import ile kullanılmış

**Sorun Nedir?**
Kod şu importu yapıyor: `import { image } from '@kit.ImageKit';` ancak state değişkeni `@State bookCover: PixelMap | null = null;` şeklinde, `image` namespace'i olmadan, çıplak `PixelMap` olarak tanımlanmış.

**Neden Hatalı?**
`image` modülü namespace olarak import edildiğinde, içindeki `PixelMap` tipine `image.PixelMap` şeklinde erişilmesi gerekir. Çıplak `PixelMap` sembolü hiçbir yerde tanımlı/import edilmiş değildir; bu da ArkTS derleyicisinde **"Cannot find name 'PixelMap'"** hatasına yol açar. Aynı dosyada `image.ImageSource` doğru şekilde namespace ile kullanılmışken `PixelMap` için bu kurala uyulmaması, tutarsızlığı daha da belirgin kılıyor.

**Önerilen Çözüm:**
```typescript
@State bookCover: image.PixelMap | null = null;
```
veya
```typescript
import { image, PixelMap } from '@kit.ImageKit';
```

---

### 1.2 — `catch` bloğunda tipsiz hata erişimi

**Sorun Nedir?**
`getBookInfo()` fonksiyonunda: `catch (error) { ... error.code ... error.message ... }` — `error` değişkeni herhangi bir tipe cast edilmeden doğrudan kullanılıyor.

**Neden Hatalı?**
ArkTS, `any`/`unknown` kullanımını ciddi şekilde kısıtlar; `catch` bloğu değişkeni varsayılan olarak `Error` tipindedir ve `Error` sınıfının `code` adında bir alanı yoktur. Bu nedenle `error.code` erişimi derleme hatası (**Property 'code' does not exist on type 'Error'**) üretir. İlginç şekilde aynı doküman setinin 5 ve 6 numaralı dosyalarında doğru kalıp (`(error as BusinessError).code`) örnek olarak gösteriliyor; bu dosyada ise unutulmuş.

**Önerilen Çözüm:**
```typescript
} catch (error) {
  const err = error as BusinessError;
  hilog.error(0x0000, 'testTAG', `getBookInfo failed, Code: ${err.code}, message: ${err.message}`);
}
```

---

### 1.3 — Belgelenmemiş "sihirli sayı": kapak resmi için `spineIndex = -1`

**Sorun Nedir?**
Kapak görüntüsünü almak için `getResourceContent(-1, bookInfo.bookCoverImage)` çağrısı yapılıyor; kod yorumunda "SpineIndex is not required for obtaining the book cover" deniyor ama API tablosunda `getResourceContent(spineIndex: number, filePath: string): ArrayBuffer` imzasında `-1` değerinin özel bir anlamı olduğu belirtilmiyor.

**Neden Hatalı?**
Bir geliştirici yalnızca API tablosuna bakarak `-1`'in geçerli/özel bir davranış tetiklediğini anlayamaz. Belgesiz "sihirli sayı" kullanımı, yanlış parametre geçişine veya (API tarafında bu davranış gelecekte değiştirilirse) sessiz hatalara yol açabilir.

**Önerilen Çözüm:**
API açıklamasına şu not eklenmeli: *"Kapak görüntüsü almak için `spineIndex` parametresi `-1` olarak gönderilmelidir; bu değer spine bağımsız kaynaklar içindir."* Alternatif olarak kapak için ayrı, kendi içinde açık bir `getBookCoverContent(filePath: string): ArrayBuffer` API'si sağlanabilir.

---

## 2. Dosya: `3-Obtaining the Catalog Item List.txt`

### 2.1 — Kopyala-yapıştır hatası: yanlış fonksiyon adı loglanıyor

**Sorun Nedir?**
`getResourceItemByCatalog()` fonksiyonunun `catch` bloğunda şu satır var: `hilog.error(0x0000, "testTAG", \`getDomPos failed, Code: ${error.code}...\`);` — fonksiyonun kendi adı yerine başka bir fonksiyonun ("getDomPos") adı loglanıyor.

**Neden Hatalı?**
Bu, `getDomPos()` fonksiyonundan kopyalanıp `getResourceItemByCatalog()` içine yapıştırılmış ancak metnin güncellenmediği açık bir kopyala-yapıştır hatasıdır. Üretimde bir hata oluştuğunda log kaydı yanlış fonksiyonu işaret edeceği için hata ayıklama sürecini yanlış yöne sürükler.

**Önerilen Çözüm:**
```typescript
hilog.error(0x0000, "testTAG", `getResourceItemByCatalog failed, Code: ${err.code}, message: ${err.message}`);
```

---

### 2.2 — `catch` bloklarında tipsiz hata erişimi (iki ayrı yerde)

**Sorun Nedir?**
Hem `getDomPos()` hem `getResourceItemByCatalog()` fonksiyonlarında `error.code` / `error.message` doğrudan, `BusinessError` tipine cast edilmeden kullanılıyor.

**Neden Hatalı?**
1.2 numaralı bulguyla aynı gerekçe: `Error` tipinde `code` alanı yoktur, ArkTS derleme hatası verir.

**Önerilen Çözüm:**
Her iki `catch` bloğunda da `const err = error as BusinessError;` cast'i eklenmeli.

---

### 2.3 — Belgelenen davranış kodda uygulanmamış

**Sorun Nedir?**
`jumpToCatalogItem()` fonksiyonunun yorum satırında "Call the startPlay API and pass domPos and resourceIndex to navigate to the specified location." deniyor ancak fonksiyon gövdesinde yalnızca `hilog.info(...)` çağrısı var; `startPlay` hiçbir yerde çağrılmıyor.

**Neden Hatalı?**
Dokümantasyon metni ile kod örneği birbiriyle tutarsız; bu, entegrasyonun en kritik adımının (gerçek sayfaya geçiş) örnekte eksik bırakıldığı izlenimini oluşturur ve deneyimsiz bir geliştirici bu adımı atlayabilir.

**Önerilen Çözüm:**
Kod örneğine gerçek çağrı eklenmeli veya en azından bir sonraki adıma (Building a Reader dokümanına) net bir referansla bağlanmalı:
```typescript
this.readerComponentController.startPlay(resourceIndex, domPos);
```

---

## 3. Dosya: `4-Building a Reader.txt`

### 3.1 — `startPlay` çağrısında eksik `await`

**Sorun Nedir?**
`startPlay()` özel (private) metodunun içinde şu satır var: `this.readerComponentController.startPlay(spineIndex|| 0, domPos);` — başında `await` yok.

**Neden Hatalı?**
API tablosunda `startPlay(spineIndex: number, domPos: string): Promise<void>` olarak tanımlanmış, yani asenkron bir işlemdir. `await` edilmezse, bu çağrı reddedilirse (reject) oluşan hata etraftaki `try/catch` bloğu tarafından **yakalanamaz** ve bir "unhandled promise rejection" oluşur.

**Önerilen Çözüm:**
```typescript
await this.readerComponentController.startPlay(spineIndex || 0, domPos);
```

---

### 3.2 — Controller örneği yarış durumu (race condition)

**Sorun Nedir?**
`aboutToAppear()` içinde `this.registerListener()` ve `this.startPlay(...)` çağrılıyor. Ancak `readerComponentController` alanı başta `new readerCore.ReaderComponentController()` ile geçici bir örnek olarak oluşturuluyor; gerçek/bileşene bağlı örnek yalnızca `ReadPageComponent`'in `readerCallback`'i tetiklendiğinde (`this.readerComponentController = data;`) atanıyor. ArkUI yaşam döngüsünde `build()` her zaman `aboutToAppear()`'dan **sonra** çalıştığından, `readerCallback` henüz tetiklenmemiş olabilir.

**Neden Hatalı?**
`registerListener()` ve `init/setPageConfig/registerBookParser/startPlay` çağrıları, callback tetiklenmeden önce geçici (placeholder) controller örneği üzerinde çalışabilir. Bu durumda `'pageShow'` dinleyicisi hiçbir zaman gerçek bileşenden tetiklenmeyebilir veya `startPlay` etkisiz kalabilir — race condition'ın sonucu cihaza, zamanlamaya göre değişir, bu da hatayı test ortamında yakalamayı zorlaştırır.

**Önerilen Çözüm:**
`registerListener()` ve reader açma mantığı, `aboutToAppear()` yerine `readerCallback` içinde, gerçek `data` örneği atandıktan **sonra** çağrılmalı:
```typescript
readerCallback: (err: BusinessError, data: readerCore.ReaderComponentController) => {
  if (err) { return; }
  this.readerComponentController = data;
  this.registerListener();
  this.startPlay(filePath, spineIndex, domPos);
}
```

---

### 3.3 — API tablosu eksik

**Sorun Nedir?**
"API Description" tablosunda yalnızca 5 API listeleniyor (`getDefaultHandler`, `init`, `setPageConfig`, `registerBookParser`, `startPlay`); ancak aynı dokümanın kod örneğinde `on('pageShow')`, `off('pageShow')` ve `releaseBook()` API'leri de kullanılıyor ve bu üçü tabloda yer almıyor.

**Neden Hatalı?**
Dokümantasyon eksikliği: bir geliştirici yalnızca tabloya bakarak bu üç API'nin var olduğunu ve `ReaderComponentController`'ın bir parçası olduğunu anlayamaz.

**Önerilen Çözüm:**
Tabloya şu satırlar eklenmeli:
| API | Açıklama |
|---|---|
| `on('pageShow', callback)` | Sayfa gösterim olayını dinler. |
| `off('pageShow')` | Sayfa gösterim dinleyicisini kaldırır. |
| `releaseBook(): void` | Kitap örneğini serbest bırakır. |

---

### 3.4 — `readerCallback` içindeki `err` parametresi hiç kontrol edilmiyor

**Sorun Nedir?**
```typescript
readerCallback: (err: BusinessError, data: readerCore.ReaderComponentController) => {
  this.readerComponentController = data;
}
```
`err` parametresi imzada tanımlı olmasına rağmen fonksiyon gövdesinde hiç kullanılmıyor/kontrol edilmiyor.

**Neden Hatalı?**
Bileşen başlatma sırasında bir hata oluşsa bile kod bunu fark etmeden `data`'yı doğrudan atar; bu da geçersiz/eksik yapılandırılmış bir controller ile devam edilmesine ve daha sonra anlaşılması güç, dolaylı hatalara (örn. `startPlay` neden çalışmıyor?) neden olabilir.

**Önerilen Çözüm:**
```typescript
readerCallback: (err: BusinessError, data: readerCore.ReaderComponentController) => {
  if (err) {
    hilog.error(0x0000, 'testTag', `ReadPageComponent init failed, code: ${err.code}`);
    return;
  }
  this.readerComponentController = data;
}
```

---

## 4. Dosya: `5-Customizing the Font.txt`

### 4.1 — (KRİTİK) `resourceRequest` callback'i kendi `filePath` parametresini yok sayıyor

**Sorun Nedir?**
`resourceRequest` callback fonksiyonu parametre olarak `filePath: string` alıyor ve `isFont(filePath)` kontrolünü bu parametre ile yapıyor. Ancak asıl dosya okuma işleminde parametre yerine sınıfın alanı kullanılıyor:
```typescript
let value: Uint8Array = context.resourceManager.getRawFileContentSync(this.readerSetting.fontPath);
...
return this.loadFileFromPath(this.readerSetting.fontPath);
```

**Neden Hatalı?**
Tipografi (typesetting) motoru bu callback'i **her kaynak isteği için `filePath` parametresiyle** çağırır; callback bu parametreyi yok sayıp sabit `this.readerSetting.fontPath` değerini kullanırsa:
1. Motor farklı/birden fazla kaynak istediğinde (örn. birden fazla font ağırlığı veya farklı bir dosya) her zaman aynı (yanlış) dosya döner.
2. `fontPath` sandbox mutlak yolu olarak ayarlanmışsa (`this.getUIContext().getHostContext()!.filesDir + '/fonts/...'`), bu değer `getRawFileContentSync`'e verilir — oysa bu API yalnızca `resources/rawfile` **göreli** yollarını kabul eder; mutlak sandbox yolu verildiğinde çağrı başarısız olur ve gereksiz yere `catch` bloğuna düşülür.

Karşılaştırma: Aynı desenin **doğru** hâli 6 numaralı dosyada (`Customizing the Page Background.txt`) gösteriliyor — orada callback doğrudan kendi `filePath` parametresini kullanıyor (`getRawFileContentSync(filePath)`). Bu dosya ile 6 numaralı dosya arasındaki tutarsızlık, hatanın kasıtsız olduğunu doğruluyor.

**Önerilen Çözüm:**
```typescript
private resourceRequest: bookParser.CallbackRes<string, ArrayBuffer> = (filePath: string): ArrayBuffer => {
  if (filePath.length === 0 || !this.isFont(filePath)) {
    return new ArrayBuffer(0);
  }
  try {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const value: Uint8Array = context.resourceManager.getRawFileContentSync(filePath);
    return value.buffer as ArrayBuffer;
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0x0000, 'testTag', `resourceRequest failed, code: ${err.code}, message: ${err.message}`);
  }
  return this.loadFileFromPath(filePath);
}
```

---

### 4.2 — `loadFileFromPath` içinde alakasız hata mesajı ve tipsiz/format hatası

**Sorun Nedir?**
```typescript
} catch (err) {
  hilog.error(0x0000, 'testTag', "mkdir failed with error message: ", err.message, ", error code: ", err.code);
  return new ArrayBuffer(0);
}
```

**Neden Hatalı?**
Üç ayrı sorun bir arada:
1. **Alakasız mesaj:** Fonksiyon bir dosya **okuma** (font/kaynak) işlemi yapıyor; "mkdir failed" (dizin oluşturma başarısız) mesajı bu işlemle hiç ilgili değil — başka bir yerden kopyalanıp unutulmuş bir metin.
2. **Tipsiz erişim:** `err.message` / `err.code`, `err`'in `BusinessError`'a cast edilmesi olmadan kullanılıyor (bkz. bulgu 1.2).
3. **hilog format hatası:** `hilog.error(domain, tag, format, ...args)` imzasında `format` dizesinin, verilen argümanların yerleştirileceği `%{public}s` / `%{public}d` gibi yer tutucular içermesi gerekir. Burada literal string'de hiçbir yer tutucu yok; bu nedenle `err.message` ve `err.code` **log çıktısına hiç yansımaz** — sadece "mkdir failed with error message:" sabit metni görünür, asıl hata bilgisi kaybolur.

**Önerilen Çözüm:**
```typescript
} catch (error) {
  const err = error as BusinessError;
  hilog.error(0x0000, 'testTag', 'loadFileFromPath failed, code: %{public}d, message: %{public}s', err.code, err.message);
  return new ArrayBuffer(0);
}
```

---

## 5. Dosya: `6-Customizing the Page Background.txt`

### 5.1 — Örnek değerler ile yorum satırları çelişiyor ("açık" dendiği halde koyu renkler kullanılmış)

**Sorun Nedir?**
Arka plan rengi örneğinde:
```typescript
this.readerSetting.themeColor = '#000000'; // siyah
// If a light background color is set, disable the dark mode.
this.readerSetting.nightMode = false;
// Adjust the font color for a light background color.
this.readerSetting.fontColor = '#FFFFFF'; // beyaz
```
Yorumlar "light background color" (açık arka plan rengi) senaryosunu anlatıyor ama `themeColor` değeri `#000000` (siyah/koyu). Aynı şekilde arka plan görseli örneğinde dosya adı `dark_sky_first.jpg` (adında açıkça "dark" geçiyor) olmasına rağmen yorum yine "light background image" (açık arka plan görseli) diyor.

**Neden Hatalı?**
Bu örneği olduğu gibi kopyalayan bir geliştirici, siyah arka plan + beyaz yazıdan oluşan **koyu** bir görünüm elde eder, ama kod `nightMode = false` bırakıldığı için bunun sistem gece moduyla senkron olmayan, tutarsız bir "gündüz modu = koyu renkli sayfa" durumuna yol açar. Ayrıca örnek başlı başına kafa karıştırıcıdır: okuyucu "light" kelimesinden dolayı açık renkli bir arka plan beklerken siyah bir arka planla karşılaşır.

**Önerilen Çözüm:**
Açık tema örneği için tutarlı değerler kullanılmalı:
```typescript
this.readerSetting.themeColor = '#FFFFFF';
this.readerSetting.themeBgImg = '';
this.readerSetting.nightMode = false;
this.readerSetting.fontColor = '#000000';
```
Koyu tema/görsel örneği ayrı gösterilecekse dosya adı ve yorumlar birbiriyle eşleşmeli (örn. `dark_sky_first.jpg` için `nightMode = true` ve açık renkli font kullanılmalı).

---

### 5.2 — `loadFileFromPath` içinde aynı "mkdir failed" kopyala-yapıştır hatası

**Sorun Nedir?**
Bu dosyadaki `loadFileFromPath()` fonksiyonu, 5 numaralı dosyadakiyle **birebir aynı** hatalı `catch` bloğunu içeriyor: `"mkdir failed with error message: "` mesajı, tipsiz `err.message`/`err.code` erişimi ve yer tutucusuz `hilog.error` format dizesi.

**Neden Hatalı?**
Bulgu 4.2 ile aynı gerekçe. Aynı hatanın iki ayrı dokümanda tekrarlanması, bu kod parçasının tek bir ortak şablondan çoğaltıldığını ve hiçbir yerde düzeltilmediğini gösteriyor.

**Önerilen Çözüm:**
Bulgu 4.2'deki çözüm burada da uygulanmalı.

---

## 6. Dosya: `9-Listening to Text Scaling Factor Value Changes.txt`

### 6.1 — Null olabilen alan, non-nullable API parametresine doğrudan geçiriliyor

**Sorun Nedir?**
```typescript
private screenDensityCallBack: Callback<number> | null = null;
...
display.on('change', this.screenDensityCallBack);
...
display.off('change', this.screenDensityCallBack);
```
Alan tipi `Callback<number> | null` olmasına rağmen, `display.on`/`display.off` çağrılarına doğrudan, null kontrolü veya non-null assertion (`!`) olmadan geçiriliyor.

**Neden Hatalı?**
`display.on(type: 'change', callback: Callback<number>)` imzası `null` kabul etmez (parametre tipi non-nullable `Callback<number>`'dır). ArkTS'in katı null kontrolü (strict null checks) altında, `Callback<number> | null` tipindeki bir değerin `Callback<number>` bekleyen bir parametreye doğrudan geçirilmesi **tip uyuşmazlığı derleme hatası** verir; çalışma zamanında `registerScreenDensityChange()` fonksiyonu bu alanı atamadan önce çağrılmadıkça kod mantığı doğru olsa da, statik tip denetimi bunu kabul etmez.

**Önerilen Çözüm:**
```typescript
display.on('change', this.screenDensityCallBack!);
...
display.off('change', this.screenDensityCallBack!);
```
Ya da alanı başta non-nullable ve doğrudan atanmış olarak tanımlamak:
```typescript
private screenDensityCallBack: Callback<number> = (data: number) => { ... };
```

---

## 7. Dosya: `11-Notifying the Reading Progress.txt`

### 7.1 — Aynı doküman içinde tutarsız alan adı: `domPos` vs. `startDomPos` (DevEco Studio ile doğrulandı)

**Sorun Nedir?**
Doküman metninde şöyle deniyor: *"The domPos and resourceIndex attributes in the page rendering information are used to identify the reading progress."* Ancak hemen altındaki kod yorumunda şu yazıyor: *"pass the **data.resourceIndex** and **data.startDomPos** values to the **startPlay** API"* — aynı alan, bir yerde `domPos`, diğer yerde `startDomPos` olarak adlandırılmış.

**Neden Hatalı?**
Bu, `PageDataInfo` arayüzünün gerçek alan adı konusunda doğrudan çelişki yaratıyor. **Güncelleme:** Örnek uygulamayı gerçek DevEco Studio ArkTS derleyicisine karşı derlerken bu doğrulandı — derleyici `data.domPos` için tam olarak şu hatayı verdi: `Property 'domPos' does not exist on type 'PageDataInfo'.` Yani metindeki isim (`domPos`) **yanlış**, kod yorumundaki isim (`startDomPos`) **doğru** imiş. İlk raporumuzda (bu bulgunun önceki sürümünde) tam tersi öneriyi vermiştik çünkü diğer dokümanlarda (`domPos` chapter-navigation değişkeni olarak) daha sık görülen isim oydu; ancak `PageDataInfo.startDomPos` ile `getDomPosByCatalogHref()`'in döndürdüğü yerel `domPos` değişkeni **aynı isimde ama farklı iki kavram** olduğu ortaya çıktı — biri sayfa gösterim olayının resmi alan adı (`startDomPos`), diğeri ise sadece bir yerel değişken ismi (`domPos`). Bu belirsizlik, dokümanın kendisinin `PageDataInfo` için tam bir arayüz/tip tanımı vermemesinden kaynaklanıyor (bkz. Bulgu 8).

**Önerilen Çözüm:**
Doküman metni koddaki gerçek alan adıyla (`startDomPos`) uyumlu hale getirilmeli; karışıklığı önlemek için metinde açıkça belirtilmeli: *"the `resourceIndex` and `startDomPos` fields of `PageDataInfo`"*:
```typescript
this.readerComponentController.on('pageShow', (data: readerCore.PageDataInfo): void => {
  // Save data.resourceIndex and data.startDomPos here, and pass them to startPlay to resume reading later.
});
```

---

### 7.2 — Gereksiz `async` işaretleyici

**Sorun Nedir?**
```typescript
private async setOnPageShowListener(){
  try {
    this.readerComponentController.on('pageShow', (data: readerCore.PageDataInfo): void => { ... });
  } catch (err) { ... }
}
```
Fonksiyon `async` olarak işaretlenmiş ancak gövdesinde hiçbir `await` ifadesi yok; `on(...)` çağrısı senkron bir kayıt işlemidir.

**Neden Hatalı?**
İşlevsel bir hata değildir ama yanıltıcıdır: `async` işaretleyici, fonksiyonun asenkron bir iş yaptığı ve çağıranın sonucu `await` etmesi gerektiği izlenimini verir; oysa fonksiyon aslında senkron çalışır ve döndürdüğü `Promise<void>` hiçbir zaman gerçek bir bekleme içermez. Birçok lint/derleyici kural seti (`require-await` benzeri) bu durumu uyarı olarak işaretler.

**Önerilen Çözüm:**
```typescript
private setOnPageShowListener(): void {
  try {
    this.readerComponentController.on('pageShow', (data: readerCore.PageDataInfo): void => {
      hilog.info(0x0000, 'testTag', 'pageshow: data is: ' + JSON.stringify(data));
    });
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0x0000, 'testTag', `failed to init, Code is ${err.code}, message is ${err.message}`);
  }
}
```

---

## 8. Genel / Mimari Gözlem (Bilgi Amaçlı — Doğrudan "Bug" Değil)

**Dosya Adı:** `1-about-kit.txt` ve tüm doküman seti

**Sorun Nedir?** Hiçbir dokümanda `BookInfo`, `CatalogItem`, `SpineItem`, `ReaderSetting` ve `PageDataInfo` arayüzlerinin tam alan listesi ve tipleri (bir TypeScript `interface` bloğu olarak) verilmiyor; alanlar yalnızca kod örnekleri içinde parça parça (`bookInfo.bookTitle`, `item.catalogLevel`, `data.state` vb.) kullanılarak ima ediliyor.

**Neden Hatalı?** Doğrudan bir derleme hatası değildir, ancak Bulgu 7.1'de görüldüğü gibi alan adı tutarsızlıklarının fark edilmesini zorlaştırıyor ve geliştiricilerin IDE otomatik tamamlama olmadan doğru alan adlarını tahmin etmesini gerektiriyor.

**Önerilen Çözüm:** Her dokümana ilgili arayüzün tam tip tanımını (ör. `interface PageDataInfo { state: PageState; resourceIndex: number; domPos: string; }`) ekleyen bir "Tip Referansı" eki eklenmesi önerilir.

**Ayrıca not:** Reader Kit'in **Emulator'da desteklenmediği** (`1-about-kit.txt`, "Emulator Support" bölümü) tüm kod örneklerinin başında tekrar hatırlatılsaydı, geliştiricilerin bu kısıtı fark etmeden emulator üzerinde test edip anlamsız hatalarla karşılaşması önlenebilirdi.

---

## Özet Tablo

| # | Dosya | Kısa Özet | Ciddiyet |
|---|---|---|---|
| 1.1 | 2-Obtaining Book Information | Çıplak `PixelMap` tipi (import/namespace hatası) | Yüksek (derleme hatası) |
| 1.2 | 2-Obtaining Book Information | Tipsiz `catch(error).code` | Yüksek (derleme hatası) |
| 1.3 | 2-Obtaining Book Information | Belgesiz `spineIndex = -1` sihirli sayısı | Orta |
| 2.1 | 3-Obtaining the Catalog Item List | Yanlış fonksiyon adı loglanıyor | Düşük |
| 2.2 | 3-Obtaining the Catalog Item List | Tipsiz `catch(error).code` (x2) | Yüksek (derleme hatası) |
| 2.3 | 3-Obtaining the Catalog Item List | `startPlay` çağrısı belgelenmiş ama kodda yok | Orta |
| 3.1 | 4-Building a Reader | `startPlay` çağrısında eksik `await` | Yüksek |
| 3.2 | 4-Building a Reader | Controller örneği yarış durumu | Yüksek |
| 3.3 | 4-Building a Reader | API tablosu eksik (`on`/`off`/`releaseBook`) | Orta |
| 3.4 | 4-Building a Reader | `readerCallback`'te `err` kontrol edilmiyor | Orta |
| 4.1 | 5-Customizing the Font | `resourceRequest` kendi `filePath` parametresini yok sayıyor | **Kritik** |
| 4.2 | 5-Customizing the Font | Alakasız "mkdir failed" mesajı + format/tip hatası | Orta |
| 5.1 | 6-Customizing the Page Background | Örnek/yorum çelişkisi (açık vs. koyu) | Orta |
| 5.2 | 6-Customizing the Page Background | Aynı "mkdir failed" hatası tekrarlanmış | Orta |
| 6.1 | 9-Listening to Text Scaling Factor | Nullable alan, non-nullable parametreye geçiriliyor | Yüksek (derleme hatası) |
| 7.1 | 11-Notifying the Reading Progress | `domPos` vs. `startDomPos` tutarsızlığı (doğru alan adı: `startDomPos`, derleyici ile doğrulandı) | Yüksek |
| 7.2 | 11-Notifying the Reading Progress | Gereksiz `async` işaretleyici | Düşük |
| 8 | Genel | Arayüz tip tanımları eksik | Bilgi amaçlı |
