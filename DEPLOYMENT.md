# Руководство администратора

## 1. Системные требования

Для продакшн-развёртывания рекомендуется:
- Операционная система: Ubuntu 22.04 LTS / Debian 12 / CentOS 8+
- CPU: 2 ядра или больше
- RAM: минимум 4 ГБ, рекомендуется 8 ГБ
- Диск: минимум 20 ГБ свободного пространства
- Docker и Docker Compose для контейнерного развёртывания

## 2. Подготовка сервера

1. Установите обновления операционной системы.
2. Установите Docker и Docker Compose.
3. Скопируйте проект на сервер.
4. Настройте `.env` с реальными значениями доступа.

## 3. Конфигурация обратного прокси (Nginx)

Пример конфигурации для Nginx:

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /path/to/frontend/dist/;
    }

    client_max_body_size 10m;
}
```

### Примечание
- `proxy_pass` должен указывать на адрес backend-сервиса.
- Убедитесь, что порт 8000 свободен и прослушивается приложением.

## 4. Запуск в продакшн

Запуск через Docker Compose:

```bash
docker compose up -d --build
```

Проверка состояния контейнеров:

```bash
docker compose ps
```

Просмотр логов:

```bash
docker compose logs -f
```

## 5. Восстановление после сбоев

### 5.1. Если упала база данных

1. Проверьте статус контейнера/PostgreSQL.
2. Оцените логи:

```bash
docker compose logs postgres
```

3. Если база не запускается, выполните проверку диска и прав на файлы.
4. Если есть дамп, восстановите его через `psql`.

### 5.2. Если переполнился диск

1. Очистите ненужные Docker-образы и контейнеры:

```bash
docker system prune -af
```

2. Освободите место в логах:

```bash
truncate -s 0 /var/log/nginx/access.log
truncate -s 0 /var/log/nginx/error.log
```

3. Проверьте текущее использование диска:

```bash
df -h
```

## 6. Бэкап и восстановление

Рекомендуется регулярно создавать дампы базы данных:

```bash
pg_dump -U postgres -d reviews > backup.sql
```

Восстановление:

```bash
psql -U postgres -d reviews < backup.sql
```

## 7. Контрольные действия администратора

- Проверяйте состояние контейнеров и сервисов после каждой перезагрузки.
- Обновляйте зависимости и образы Docker только в тестовой среде перед продакшном.
- Храните `.env` отдельно от репозитория и никогда не отправляйте его на GitHub.
