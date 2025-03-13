#!/bin/sh

# Установка Ansible, если он не установлен
install_ansible() {
  if ! command -v ansible > /dev/null 2>&1; then
    echo "Установка Ansible..."
    sudo apt update
    sudo apt install -y ansible
  else
    echo "Ansible уже установлен."
  fi
}

# Создание файла ansible.cfg
create_ansible_cfg() {
  cat <<EOF > ansible.cfg
[defaults]
display_skipped_hosts = False
stdout_callback = debug
EOF
  echo "Файл ansible.cfg создан."
}

# Создание YAML-файла с задачами
create_ansible_playbook() {
  cat <<EOF > ubuntu_tasks.yml
---
- name: Меню управления сервером Ubuntu
  hosts: localhost
  become: yes
  gather_facts: yes  # Включаем сбор фактов

  vars_prompt:
    - name: task_number
      prompt: |
        ═══════════════════════════════════════
         Меню управления Ubuntu Server
        ═══════════════════════════════════════
         1. Полное обновление системы
         2. Очистка старых ядер
         3. Удаление ненужных пакетов
         4. Установка базовых утилит
         5. Настройка доступа SSH для root
         6. Установка Docker и Portainer
         7. Отключение IPv6
         8. Выход

        Введите номер задачи:
      private: no

  tasks:
    - name: Проверка выбора "Выход"
      copy:
        dest: ./exit_flag.txt
        content: "{{ 'true' if task_number == '8' else 'false' }}"
      when: task_number == "8"

    - name: "[1] - Запуск обновления системы"
      debug:
        msg: "Инициирую полное обновление системы..."
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
        msg: "Система успешно обновлена!"
      when: 
        - task_number == "1"
        - update_result is changed

    - name: "[2] - Поиск старых ядер"
      debug:
        msg: "Ищу старые версии ядер..."
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
            msg: "Актуальные ядра не найдены, удаление не требуется"
          when: kernels_to_remove.stdout == ""
      when: task_number == "2"

    - name: "[3] - Очистка пакетов"
      debug:
        msg: "Выполняю очистку ненужных пакетов..."
      when: task_number == "3"

    - name: Удаление ненужных пакетов
      apt:
        autoremove: yes
        autoclean: yes
      when: task_number == "3"
      register: autoremove_result

    - name: Результат очистки
      debug:
        msg: "Освобождено места: {{ autoremove_result.freed_space | default('0') }}B"
      when: task_number == "3"

    - name: "[4] - Установка ПО"
      debug:
        msg: "Начинаю установку базовых утилит..."
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

    - name: "[5] - Настройка SSH"
      debug:
        msg: "Настраиваю доступ для root..."
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
        msg: "Доступ по SSH для root успешно настроен!"
      when: task_number == "5"

    - name: "[6] - Установка Docker"
      debug:
        msg: "Начинаю установку Docker и Portainer..."
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
        msg: "Docker и Portainer успешно установлены!\nАдрес панели: https://{{ ansible_host }}:9443"
      when: task_number == "6"

    - name: "[7] - Отключение IPv6"
      debug:
        msg: "Выполняю отключение IPv6..."
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
        msg: "IPv6 успешно отключен!"
      when: task_number == "7"

    - name: Выход
      debug:
        msg: "Завершение работы..."
      when: task_number == "8"

    - name: Ошибка выбора
      debug:
        msg: "Ошибка: Некорректный номер задачи!"
      when: task_number not in ["1","2","3","4","5","6","7","8"]
EOF
}

main() {
  echo "═══════════════════════════════════════"
  echo "  Настройка Ubuntu Server"
  echo "═══════════════════════════════════════"
  
  install_ansible
  create_ansible_cfg
  create_ansible_playbook

  while true; do
    # Удаляем временный файл перед каждым запуском
    rm -f ./exit_flag.txt

    ansible-playbook ubuntu_tasks.yml
    if [ $? -eq 0 ]; then
      # Проверяем, был ли выбран пункт "Выход"
      if [ -f ./exit_flag.txt ] && grep -q "true" ./exit_flag.txt; then
        echo "Работа завершена."
        break
      fi
    else
      echo "Произошла ошибка. Повторите попытку."
    fi
  done
}

main
