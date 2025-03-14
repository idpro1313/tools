#!/bin/sh

# Определяем переменные
OLLAMA_CONTAINER_NAME="ollama"
OPENWEBUI_CONTAINER_NAME="open-webui"
WATCHTOWER_CONTAINER_NAME="watchtower"
OLLAMA_DATA_DIR="/ai/ollama"  # Папка в корне файловой системы
OPENWEBUI_DATA_VOLUME="open-webui-data"
CURRENT_IP=$(hostname -I | awk '{print $1}')

# Проверяем права доступа к корневой файловой системе
if [ ! -w "/" ]; then
  echo "Ошибка: у вас нет прав на запись в корневую файловую систему."
  echo "Запустите скрипт с правами root или измените права доступа."
  exit 1
fi

# Создаем директорию для данных Ollama
echo "Создание папки ${OLLAMA_DATA_DIR}..."
sudo mkdir -p "${OLLAMA_DATA_DIR}"
sudo chown -R "$(whoami):$(whoami)" "${OLLAMA_DATA_DIR}"

# Запускаем Ollama
echo "Запуск контейнера Ollama..."
docker run -d \
  --name "${OLLAMA_CONTAINER_NAME}" \
  -v "${OLLAMA_DATA_DIR}:/root/.ollama" \
  -p 11434:11434 \
  --restart always \
  ollama/ollama

# Запускаем Open WebUI
echo "Запуск контейнера Open WebUI..."
docker run -d \
  --name "${OPENWEBUI_CONTAINER_NAME}" \
  -p 3000:8080 \
  --add-host="host-gateway:${CURRENT_IP}" \
  -v "${OPENWEBUI_DATA_VOLUME}:/app/backend/data" \
  --restart always \
  ghcr.io/open-webui/open-webui:main

# Запускаем Watchtower для автоматического обновления контейнеров
echo "Запуск Watchtower для автоматического обновления..."
docker run -d \
  --name "${WATCHTOWER_CONTAINER_NAME}" \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --restart always \
  containrrr/watchtower \
  "${OLLAMA_CONTAINER_NAME}" "${OPENWEBUI_CONTAINER_NAME}"

# Проверяем, что контейнеры запущены
echo "Проверка запущенных контейнеров..."
if docker ps | grep "${OLLAMA_CONTAINER_NAME}" && \
   docker ps | grep "${OPENWEBUI_CONTAINER_NAME}" && \
   docker ps | grep "${WATCHTOWER_CONTAINER_NAME}"; then
  echo "Все контейнеры успешно запущены!"
  echo "Ollama доступен на порту 11434."
  echo "Open WebUI доступен на порту 3000."
  echo "Watchtower настроен для автоматического обновления."
else
  echo "Ошибка: не все контейнеры запущены."
fi
