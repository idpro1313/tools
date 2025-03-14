#!/bin/sh

# Получаем текущий основной IP адрес системы
CURRENT_IP=$(hostname -I | awk '{print $1}')

# Запускаем контейнер с динамическим IP
docker run -d \
  -p 3000:8080 \
  --add-host="host-gateway:${CURRENT_IP}" \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main

# Проверяем, что контейнер запущен
if docker ps | grep open-webui; then
  echo "Контейнер open-webui успешно запущен!"
  echo "Используемый IP адрес: ${CURRENT_IP}"
else
  echo "Ошибка: контейнер open-webui не запущен."
fi
