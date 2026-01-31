# Настройка подписи приложения

Ошибки **"Signing requires a development team"** или **"entitlements require signing"** возникают, когда не выбрана команда разработчика.

## Решение

### 1. Добавьте Apple ID в Xcode
- Откройте **Xcode** → **Settings** (⌘,) → вкладка **Accounts**
- Нажмите **+** → **Apple ID** → войдите с вашим Apple ID
- Дождитесь загрузки профилей (появится "Personal Team" или ваша команда)

### 2. Выберите команду разработчика
- Откройте проект **ServiceBooking.xcodeproj** в Xcode
- В левой панели (Navigator) выберите **ServiceBooking** (синяя иконка проекта)
- Выберите таргет **ServiceBooking** в списке TARGETS
- Откройте вкладку **Signing & Capabilities**
- Убедитесь, что включено **Automatically manage signing**
- В поле **Team** нажмите на выпадающий список и выберите:
  - **Personal Team (Ваше имя)** — для симулятора и своего iPhone (бесплатно)
  - Или вашу команду Apple Developer — для публикации в App Store

> Если в списке Team пусто или "None" — сначала добавьте Apple ID (шаг 1)

### 3. Capabilities (Camera, Contacts, Photo Library)
Если в Signing & Capabilities отображаются Camera, Contacts, Photo Library — **их можно удалить**:
- Нажмите **×** рядом с каждой — доступ к камере и фото работает через ключи в Info.plist, отдельные capabilities не требуются
- Это может убрать ошибку entitlements, если команда ещё не настроена

### 4. Сборка
- Для **симулятора**: выберите симулятор и нажмите Run (⌘R)
- Для **реального устройства**: подключите iPhone, выберите его как destination и нажмите Run

---

**Примечание:** Personal Team (бесплатный Apple ID) позволяет запускать приложение только на своих устройствах. Для публикации в App Store нужна подписка Apple Developer Program.
