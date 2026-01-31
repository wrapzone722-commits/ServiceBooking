# ServiceBooking iOS App

Легкое клиентское iOS приложение для записи на услуги.

## Архитектура

**Принцип: ВСЕ данные на сервере, приложение - только интерфейс**

- Приложение НЕ хранит данные локально
- Данные загружаются с сервера при каждом открытии экрана
- Pull-to-refresh для обновления
- Кэширование HTTP отключено
- При отсутствии сети показывается баннер

## Структура

```
ServiceBooking/
├── Models/           # Модели данных (DTO)
├── Services/         # API сервис (только сетевые запросы)
├── ViewModels/       # Логика UI (данные в памяти)
├── Views/            # SwiftUI экраны
└── Resources/        # Assets
```

## Функционал

| Вкладка | Описание |
|---------|----------|
| Услуги | Каталог услуг с поиском и фильтрами |
| Мои записи | Предстоящие, прошедшие, отмененные |
| Профиль | Контакты и социальные сети |

## Первый запуск

При первом запуске приложение **единоразово** предлагает отсканировать QR-код из веб-консоли. После сканирования:
- Приложение получает URL API и подключается к консоли
- Загружаются услуги, слоты и параметры
- Профиль и контакты синхронизируются с API

## Запуск

```bash
open /Users/aleksandrslynuk/Desktop/ServiceBooking/ServiceBooking.xcodeproj
```

---

# API Specification (для веб-разработчика)

## Общие требования

- **Формат:** JSON
- **Авторизация:** Bearer Token в заголовке `Authorization`
- **Даты:** ISO 8601 (`2025-01-31T10:00:00Z`)
- **Без кэширования:** iOS приложение не кэширует данные

## Endpoints

### GET /services
Список услуг.

```json
[
  {
    "_id": "string",
    "name": "Химчистка салона",
    "description": "Описание услуги",
    "price": 5000,
    "duration": 60,
    "category": "Автоуслуги",
    "image_url": "string | null",
    "is_active": true
  }
]
```

### GET /bookings
Записи пользователя.

```json
[
  {
    "_id": "string",
    "service_id": "string",
    "service_name": "Химчистка салона",
    "user_id": "string",
    "date_time": "2025-01-31T10:00:00Z",
    "status": "pending",
    "price": 5000,
    "duration": 60,
    "notes": "string | null",
    "created_at": "2025-01-30T12:00:00Z"
  }
]
```

**Статусы:** `pending` | `confirmed` | `in_progress` | `completed` | `cancelled`

### POST /bookings
Создать запись.

**Request:**
```json
{
  "service_id": "string",
  "date_time": "2025-01-31T10:00:00Z",
  "notes": "string | null"
}
```

### DELETE /bookings/:id
Отменить запись.

### GET /slots?service_id=:id&date=YYYY-MM-DD
Доступные слоты.

```json
[
  {
    "_id": "string",
    "time": "2025-01-31T10:00:00Z",
    "isAvailable": true
  }
]
```

### GET /profile
Профиль пользователя.

```json
{
  "_id": "string",
  "first_name": "Александр",
  "last_name": "Иванов",
  "phone": "+7 (999) 123-45-67",
  "email": "string | null",
  "avatar_url": "string | null",
  "social_links": {
    "telegram": "@username",
    "whatsapp": "+79991234567",
    "instagram": "username",
    "vk": "username"
  },
  "created_at": "2025-01-01T00:00:00Z"
}
```

### PUT /profile
Обновить профиль.

```json
{
  "first_name": "string",
  "last_name": "string", 
  "email": "string | null",
  "social_links": { ... }
}
```

## QR-код для подключения (веб-консоль)

В настройках веб-консоли должен быть раздел с **QR-кодом** для подключения iOS приложения. Клиент сканирует его при первом запуске.

**Форматы содержимого QR-кода:**

1. **Простой URL:**
   ```
   https://api.your-service.com/v1
   ```

2. **JSON с параметрами:**
   ```json
   {
     "base_url": "https://api.your-service.com/v1",
     "token": "optional_access_token"
   }
   ```

3. **Custom URL scheme:**
   ```
   servicebooking://config?url=https://api.your-service.com/v1&token=xxx
   ```

После сканирования приложение сохраняет конфигурацию и использует указанный API для:
- Загрузки услуг (GET /services)
- Создания записей (POST /bookings)
- Отправки данных профиля (GET/PUT /profile)
- Получения слотов (GET /slots)

---

## Веб-консоль админа

Должна управлять:
- Услугами (создание, редактирование, категории)
- Записями (подтверждение, отмена)
- Расписанием (рабочие часы, слоты)
- Клиентами (просмотр)

**Важно:** Любые изменения в веб-консоли мгновенно отображаются в iOS приложении при следующем запросе к API.
