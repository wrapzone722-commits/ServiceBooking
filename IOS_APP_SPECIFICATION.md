# iOS App — Service Booking Client Implementation Specification

**Источник:** Спецификация от разработчика веб-консоли

## Overview

iOS-приложение для системы ServiceBooking позволяет пользователям:
- Регистрировать устройство и получать API-токен
- Просматривать услуги автомойки
- Видеть доступные слоты по каждому посту
- Бронировать услуги
- Просматривать свои записи

## API Endpoints

**Base URL:** `https://example.com/api/v1` (настраивается через QR или ручной ввод)

### 1. Регистрация устройства

`POST /clients/register`

**Запрос:**
```json
{
  "device_id": "UUID-string-here",
  "platform": "iOS 17.0",
  "app_version": "1.0.0"
}
```

**Ответ:**
```json
{
  "client_id": "usr_1234567890",
  "api_key": "abc123def456..."
}
```

**Реализовано:** device_id в Keychain, api_key в Keychain, регистрация при первом подключении.

### 2. Список услуг

`GET /services`

**Ответ:** массив с `_id`, `name`, `description`, `price`, `duration`, `category`, `image_url`, `is_active`.

### 3. Слоты

`GET /slots?service_id={id}&date={YYYY-MM-DD}&post_id=post_1`

**Ответ:**
```json
[
  { "time": "2026-02-01T09:00:00.000Z", "is_available": true },
  { "time": "2026-02-01T09:30:00.000Z", "is_available": false }
]
```

### 4. Посты

`GET /posts`

**Ответ:** массив постов с `_id`, `name`, `is_enabled`, `start_time`, `end_time`, `interval_minutes`.

### 5. Создание брони

`POST /bookings`

**Запрос:**
```json
{
  "service_id": "svc_1",
  "date_time": "2026-02-01T09:30:00.000Z",
  "post_id": "post_1",
  "notes": "Optional notes"
}
```

## Аутентификация

Все запросы (кроме `/clients/register`):
- `Authorization: Bearer {api_key}`
- `Content-Type: application/json`

## Статусы бронирований

- `pending` — ожидает подтверждения
- `confirmed` — подтверждена
- `in_progress` — в процессе
- `completed` — завершена
- `cancelled` — отменена

## Соответствие реализации

| Требование | Статус |
|------------|--------|
| Keychain для device_id, api_key | ✅ |
| POST /clients/register | ✅ |
| GET /services | ✅ |
| GET /slots с post_id | ✅ |
| GET /posts | ✅ |
| POST /bookings с post_id, notes | ✅ |
| Выбор поста в UI | ✅ |
| ISO 8601 даты | ✅ |
