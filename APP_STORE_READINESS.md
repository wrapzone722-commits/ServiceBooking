# Готовность к публикации в App Store

Проверка проекта Service Booking перед загрузкой в App Store Connect.

## ✅ Выполнено в проекте

### Метаданные и конфигурация
- **Версия:** 1.0.0 (MARKETING_VERSION), сборка 1 (CURRENT_PROJECT_VERSION)
- **Bundle ID:** `com.servicebooking.app` (основное приложение), `com.servicebooking.app.widget` (виджет)
- **Отображаемое имя:** «Service Booking»
- **Категория:** Lifestyle (`public.app-category.lifestyle`)
- **Минимальная iOS:** 17.0 (IPHONEOS_DEPLOYMENT_TARGET)
- **Копирайт:** задан в настройках сборки (INFOPLIST_KEY_NSHumanReadableCopyright)
- **Локализация:** ru (основной), en (CFBundleLocalizations в Info.plist)
- **Ориентация:** портрет (iPhone), все ориентации (iPad), полноэкранный режим

### Конфиденциальность и разрешения
- **Privacy Manifest** (`PrivacyInfo.xcprivacy`): настроен (UserDefaults, типы данных, без трекинга)
- **Описания разрешений в Info.plist:**
  - Камера (профиль)
  - Фото (выбор и сохранение)
  - Контакты (автозаполнение)
  - Календарь (напоминания о записях)
- **App Transport Security:** произвольные загрузки отключены; localhost/127.0.0.1 разрешены только для разработки

### Ресурсы
- **Иконка приложения:** все размеры в `AppIcon.appiconset` (включая 1024×1024 для App Store)
- **Launch Screen:** `LaunchScreen.storyboard` (чёрный фон)
- **Локализация строк:** `Localizable.xcstrings`

### Подписи и команда
- **Code Signing:** Automatic
- **Development Team:** M7434XB3SP (проверьте в Xcode, что это ваша команда)

### Виджет и расширения
- **ServiceBookingWidget:** Live Activity, версия синхронизирована с основным приложением

---

## Перед загрузкой в App Store Connect

1. **Apple Developer**
   - Убедитесь, что приложение и виджет зарегистрированы в [App Store Connect](https://appstoreconnect.apple.com) с теми же Bundle ID.
   - Соглашения и банковские/налоговые данные актуальны.

2. **Сборка для архива**
   - В Xcode: **Product → Scheme → Edit Scheme** → Run и Archive используют конфигурацию **Release**.
   - Выберите целевое устройство **Any iOS Device**.
   - **Product → Archive**. После успешного архива: **Distribute App** → **App Store Connect** → **Upload**.

3. **Проверка после загрузки**
   - В App Store Connect заполните метаданные: описание, ключевые слова, скриншоты (6.7", 6.5", 5.5" для iPhone; при поддержке iPad — скриншоты iPad).
   - Укажите ссылки на **Политику конфиденциальности** и **Пользовательское соглашение** (в приложении они открываются в `PrivacyPolicyView` и `TermsOfUseView` — убедитесь, что URL актуальны).
   - Ответьте на вопросы о конфиденциальности (доступ к камере, фото, контактам, календарю и т.д.).
   - Выберите рейтинг возраста и при необходимости экспортное соответствие.

4. **Рекомендации по контенту**
   - URL API по умолчанию (`https://api.your-service.com/api/v1`) используется только до первой настройки (QR или ручной ввод). Для продакшена пользователь настраивает свой бэкенд — это соответствует модели приложения.
   - Если нужны Push-уведомления или Associated Domains, добавьте соответствующие возможности в Xcode (Signing & Capabilities) и создайте/подключите файл entitlements.

---

## Получение IPA-файла

IPA можно получить только на Mac, где в Xcode добавлен ваш Apple ID и есть профили для `com.servicebooking.app` и `com.servicebooking.app.widget`.

### Вариант 1: скрипт (терминал)

```bash
make ipa
# или: ./scripts/export-ipa.sh
```

Готовый файл: **`build/ServiceBooking.ipa`**. По умолчанию экспорт идёт с методом **development** (IPA для установки на зарегистрированные устройства). Для загрузки в App Store откройте архив в Xcode (Organizer) → Distribute App → App Store Connect.

### Вариант 2: вручную в Xcode

1. Выберите целевое устройство **Any iOS Device**.
2. **Product → Archive**.
3. В Organizer: **Distribute App** → **App Store Connect** → **Upload** (загрузка без сохранения IPA)  
   либо **Distribute App** → **Custom** → **Export** и сохраните `.ipa` на диск.

---

## Проверка сборки

В Xcode: выберите целевое устройство **Any iOS Device**, затем **Product → Archive**. Успешный архив означает готовность к загрузке в App Store Connect (Distribute App → App Store Connect → Upload).
