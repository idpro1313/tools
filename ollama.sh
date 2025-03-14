#!/bin/sh

# Определяем переменные
OLLAMA_CONTAINER_NAME="ollama"
OLLAMA_DATA_DIR="/ai/ollama"
OLLAMA_PORT="11434"

# Создаем директорию для данных Ollama
mkdir -p "${OLLAMA_DATA_DIR}"
chown -R "$(whoami):$(whoami)" "${OLLAMA_DATA_DIR}"

# Создаем Ansible Playbook для установки Ollama
cat <<EOF > install_ollama.yml
---
- name: Установка Ollama в Docker
  hosts: localhost
  become: yes
  tasks:
    - name: Запуск контейнера Ollama
      docker_container:
        name: "${OLLAMA_CONTAINER_NAME}"
        image: ollama/ollama
        state: started
        restart_policy: always
        ports:
          - "${OLLAMA_PORT}:${OLLAMA_PORT}"
        volumes:
          - "${OLLAMA_DATA_DIR}:/root/.ollama"
EOF

# Запускаем Ansible Playbook
ansible-playbook install_ollama.yml

# Проверяем, что контейнер запущен
if docker ps | grep "${OLLAMA_CONTAINER_NAME}"; then
  echo "Ollama успешно установлен и запущен!"
  echo "Данные хранятся в ${OLLAMA_DATA_DIR}"
else
  echo "Ошибка: контейнер Ollama не запущен."
fi
