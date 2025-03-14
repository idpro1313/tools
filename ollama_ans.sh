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
    - name: Проверка версии Ansible
      debug:
        msg: "Версия Ansible: {{ ansible_version }}"

    - name: Создание папки ${OLLAMA_DATA_DIR}
      file:
        path: ${OLLAMA_DATA_DIR}
        state: directory
        owner: ${CURRENT_USER}
        group: ${CURRENT_USER}
        mode: '0755'
      notify: "Задача 'Создание папки /ai/ollama' завершена"

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
      notify: "Задача 'Запуск контейнера Ollama' завершена"

    - name: Запуск контейнера Open WebUI с extra_hosts
      docker_container:
        name: open-webui
        image: ghcr.io/open-webui/open-webui:main
        state: started
        restart_policy: always
        ports:
          - "3000:8080"
        volumes:
          - open-webui:/app/backend/data
        extra_hosts:
          - "host.docker.internal:host-gateway"
      notify: "Задача 'Запуск контейнера Open WebUI' завершена"

    - name: Запуск Watchtower для автоматического обновления
      docker_container:
        name: watchtower
        image: containrrr/watchtower
        state: started
        restart_policy: always
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
        command: --interval 86400 ollama open-webui  # Проверка обновлений каждые 24 часа
      notify: "Задача 'Запуск Watchtower' завершена"

    - name: Проверка запущенных контейнеров
      shell: docker ps --format "{{ '{{' }}.Names{{ '}}' }}"
      register: running_containers
      notify: "Задача 'Проверка запущенных контейнеров' завершена"

    - name: Вывод статуса контейнеров
      debug:
        msg: |
          Запущенные контейнеры:
          {{ running_containers.stdout_lines }}
      notify: "Задача 'Вывод статуса контейнеров' завершена"

  handlers:
    - name: "Задача 'Создание папки /ai/ollama' завершена"
      debug:
        msg: "Задача 'Создание папки /ai/ollama' завершена"

    - name: "Задача 'Запуск контейнера Ollama' завершена"
      debug:
        msg: "Задача 'Запуск контейнера Ollama' завершена"

    - name: "Задача 'Запуск контейнера Open WebUI' завершена"
      debug:
        msg: "Задача 'Запуск контейнера Open WebUI' завершена"

    - name: "Задача 'Запуск Watchtower' завершена"
      debug:
        msg: "Задача 'Запуск Watchtower' завершена"

    - name: "Задача 'Проверка запущенных контейнеров' завершена"
      debug:
        msg: "Задача 'Проверка запущенных контейнеров' завершена"

    - name: "Задача 'Вывод статуса контейнеров' завершена"
      debug:
        msg: "Задача 'Вывод статуса контейнеров' завершена"
EOF

# Запускаем Ansible Playbook с подробным выводом
log "Запуск Ansible Playbook..."
ansible-playbook -v "${PLAYBOOK_FILE}"

# Удаляем временный Playbook
log "Удаление временного Playbook..."
rm -f "${PLAYBOOK_FILE}"

# Завершение
log "Установка завершена!"
