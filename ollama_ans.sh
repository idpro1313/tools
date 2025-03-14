#!/bin/sh

# Определяем переменные
PLAYBOOK_FILE="/tmp/install_ollama_openwebui.yml"
OLLAMA_DATA_DIR="/ai/ollama"
CURRENT_USER=$(whoami)

# Функция для вывода сообщений
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Создаем Ansible Playbook
log "Создание временного Ansible Playbook..."
cat <<EOF > "${PLAYBOOK_FILE}"
---
- name: Установка Ollama, Open WebUI и Watchtower
  hosts: localhost
  become: yes
  tasks:
    - name: Создание папки ${OLLAMA_DATA_DIR}
      file:
        path: ${OLLAMA_DATA_DIR}
        state: directory
        owner: ${CURRENT_USER}
        group: ${CURRENT_USER}
        mode: '0755'

    - name: Запуск контейнера Ollama
      docker_container:
        name: ollama
        image: ollama/ollama
        state: started
        restart_policy: always
        volumes:
          - ${OLLAMA_DATA_DIR}:/root/.ollama
        ports:
          - "11434:11434"

    - name: Получение текущего IP адреса
      shell: hostname -I | awk '{print \$1}'
      register: current_ip

    - name: Запуск контейнера Open WebUI
      docker_container:
        name: open-webui
        image: ghcr.io/open-webui/open-webui:main
        state: started
        restart_policy: always
        ports:
          - "3000:8080"
        volumes:
          - open-webui-data:/app/backend/data
        extra_hosts:
          - "host-gateway:{{ current_ip.stdout }}"

    - name: Запуск Watchtower для автоматического обновления
      docker_container:
        name: watchtower
        image: containrrr/watchtower
        state: started
        restart_policy: always
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
        command: --interval 86400 ollama open-webui  # Проверка обновлений каждые 24 часа

    - name: Проверка запущенных контейнеров
      shell: docker ps --format "{{ '{{' }}.Names{{ '}}' }}"
      register: running_containers

    - name: Вывод статуса контейнеров
      debug:
        msg: |
          Запущенные контейнеры:
          {{ running_containers.stdout_lines }}
EOF

# Запускаем Ansible Playbook с подробным выводом
log "Запуск Ansible Playbook..."
ansible-playbook -v "${PLAYBOOK_FILE}"

# Удаляем временный Playbook
log "Удаление временного Playbook..."
rm -f "${PLAYBOOK_FILE}"

# Завершение
log "Установка завершена!"
