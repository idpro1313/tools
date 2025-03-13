#!/bin/sh

# Цвета для оформления (если терминал поддерживает)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Установка Ansible, если он не установлен
install_ansible() {
  if ! command -v ansible > /dev/null 2>&1; then
    printf "${YELLOW}Установка Ansible...${NC}\n"
    sudo apt update
    sudo apt install -y ansible
  else
    printf "${GREEN}Ansible уже установлен.${NC}\n"
  fi
}

# Создание файла ansible.cfg
create_ansible_cfg() {
  cat <<EOF > ansible.cfg
[defaults]
display_skipped_hosts = False
stdout_callback = debug
EOF
  printf "${GREEN}Файл ansible.cfg создан.${NC}\n"
}

# Создание YAML-файла с задачами
create_ansible_playbook() {
  cat <<EOF > ubuntu_tasks.yml
---
- name: Меню управления сервером Ubuntu
  hosts: localhost
  become: yes
  gather_facts: no

  vars_prompt:
    - name: task_number
      prompt: |
        \n${BLUE}═══════════════════════════════════════
         Меню управления Ubuntu Server
        ═══════════════════════════════════════${NC}
         ${GREEN}1${NC}. Полное обновление системы
         ${GREEN}2${NC}. Очистка старых ядер
         ${GREEN}3${NC}. Удаление ненужных пакетов
         ${GREEN}4${NC}. Установка базовых утилит
         ${GREEN}5${NC}. Настройка доступа SSH для root
         ${GREEN}6${NC}. Установка Docker и Portainer
         ${GREEN}7${NC}. Отключение IPv6
         ${GREEN}8${NC}. Выход

        Введите номер задачи: 
      private: no

  tasks:
    - name: "[1] - Запуск обновления системы"
      debug:
        msg: "${YELLOW}Инициирую полное обновление системы...${NC}"
      when: task_number == "1"

    - name: Выполнить обновление
      apt:
        update_cache: yes
        upgrade: dist
        autoremove: yes
      when: task_number == "1"
      register: update_result

    - name: Результат обновления
      debug:
        msg: "${GREEN}Система успешно обновлена!${NC}"
      when: 
        - task_number == "1"
        - update_result is changed

    - name: "[2] - Поиск старых ядер"
      debug:
        msg: "${YELLOW}Ищу старые версии ядер...${NC}"
      when: task_number == "2"

    - name: Удаление старых ядер
      block:
        - name: Поиск пакетов для удаления
          shell: |
            kernels_to_remove=\$(echo \$(dpkg --list | grep linux-image | awk '{ print \$2 }' | sort -V | sed -n '/'"\$(uname -r)"'/q;p') \\
            \$(dpkg --list | grep linux-headers | awk '{ print \$2 }' | sort -V | sed -n '/'"\$(uname -r | sed "s/\\([0-9.-]*\\)-\\([^0-9]\\+\\)/\\1/")"'/q;p'))
            if [ -n "\$kernels_to_remove" ]; then
              echo "\$kernels_to_remove"
            else
              echo ""
            fi
          args:
            executable: /bin/bash
          register: kernels_to_remove

        - name: Удаление пакетов
          shell: |
            echo "Удаляемые пакеты: {{ kernels_to_remove.stdout }}"
            echo "{{ kernels_to_remove.stdout }}" | xargs sudo apt-get -y purge
          when: kernels_to_remove.stdout != ""

        - name: Нет ядер для удаления
          debug:
            msg: "${YELLOW}Актуальные ядра не найдены, удаление не требуется${NC}"
          when: kernels_to_remove.stdout == ""
      when: task_number == "2"

    - name: "[3] - Очистка пакетов"
      debug:
        msg: "${YELLOW}Выполняю очистку ненужных пакетов...${NC}"
      when: task_number == "3"

    - name: Удаление ненужных пакетов
      apt:
        autoremove: yes
        autoclean: yes
      when: task_number == "3"
      register: autoremove_result

    - name: Результат очистки
      debug:
        msg: "${GREEN}Освобождено места: {{ autoremove_result.freed_space | default('0') }}B${NC}"
      when: task_number == "3"

    - name: "[4] - Установка ПО"
      debug:
        msg: "${YELLOW}Начинаю установку базовых утилит...${NC}"
      when: task_number == "4"

    - name: Установка пакетов
      apt:
        name:
          - net-tools
          - mc
          - nano
          - htop
          - cron
        state: present
      when: task_number == "4"
      register: install_result

    - name: Результат установки
      debug:
        msg: "${GREEN}Успешно установлены пакеты:\n{{ install_result.results | map(attribute='item') | join('\n') }}${NC}"
      when: task_number == "4"

    - name: "[5] - Настройка SSH"
      debug:
        msg: "${YELLOW}Настраиваю доступ для root...${NC}"
      when: task_number == "5"

    - name: Настройка SSH
      block:
        - lineinfile:
            path: /etc/ssh/sshd_config
            regexp: '^#?PermitRootLogin'
            line: 'PermitRootLogin yes'
            state: present

        - service:
            name: ssh
            state: restarted
      when: task_number == "5"

    - name: Результат настройки SSH
      debug:
        msg: "${GREEN}Доступ по SSH для root успешно настроен!${NC}"
      when: task_number == "5"

    - name: "[6] - Установка Docker"
      debug:
        msg: "${YELLOW}Начинаю установку Docker и Portainer...${NC}"
      when: task_number == "6"

    - name: Установка Docker
      block:
        - apt:
            name:
              - apt-transport-https
              - ca-certificates
              - curl
              - software-properties-common
            state: present

        - apt_key:
            url: https://download.docker.com/linux/ubuntu/gpg
            state: present

        - apt_repository:
            repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
            state: present

        - apt:
            name: docker-ce
            state: present

        - service:
            name: docker
            state: started
            enabled: yes

        - docker_container:
            name: portainer
            image: portainer/portainer-ce:latest
            ports:
              - "8000:8000"
              - "9443:9443"
            volumes:
              - /var/run/docker.sock:/var/run/docker.sock
              - portainer_data:/data
            restart_policy: always
            state: started
      when: task_number == "6"

    - name: Результат установки Docker
      debug:
        msg: "${GREEN}Docker и Portainer успешно установлены!\nАдрес панели: https://{{ ansible_host }}:9443${NC}"
      when: task_number == "6"

    - name: "[7] - Отключение IPv6"
      debug:
        msg: "${YELLOW}Выполняю отключение IPv6...${NC}"
      when: task_number == "7"

    - name: Отключение IPv6
      block:
        - sysctl:
            name: "{{ item }}"
            value: '1'
            state: present
            reload: yes
          loop:
            - net.ipv6.conf.all.disable_ipv6
            - net.ipv6.conf.default.disable_ipv6

        - shell: sysctl --system
      when: task_number == "7"

    - name: Результат отключения IPv6
      debug:
        msg: "${GREEN}IPv6 успешно отключен!${NC}"
      when: task_number == "7"

    - name: Выход
      debug:
        msg: "${BLUE}Завершение работы...${NC}"
      when: task_number == "8"

    - name: Ошибка выбора
      debug:
        msg: "${RED}Ошибка: Некорректный номер задачи!${NC}"
      when: task_number not in ["1","2","3","4","5","6","7","8"]
EOF
}

main() {
  printf "${BLUE}═══════════════════════════════════════\n"
  printf "  Настройка Ubuntu Server\n"
  printf "═══════════════════════════════════════${NC}\n"
  
  install_ansible
  create_ansible_cfg
  create_ansible_playbook

  while true; do
    ansible-playbook ubuntu_tasks.yml
    if [ $? -eq 0 ]; then
      printf "${BLUE}Работа завершена.${NC}\n"
      break
    else
      printf "${RED}Произошла ошибка. Повторите попытку.${NC}\n"
    fi
  done
}

main
