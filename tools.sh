#!/bin/bash

# Установка Ansible, если он не установлен
install_ansible() {
  if ! command -v ansible &> /dev/null; then
    echo "Установка Ansible..."
    sudo apt update
    sudo apt install -y ansible
  else
    echo "Ansible уже установлен."
  fi
}

# Создание YAML-файла с задачами и меню
create_ansible_playbook() {
  cat <<EOF > ubuntu_tasks.yml
---
- name: Меню для выполнения задач на свежеустановленной Ubuntu
  hosts: localhost
  become: yes  # Запрашиваем права sudo
  gather_facts: no
  vars_prompt:
    - name: task_number
      prompt: |
        Выберите номер задачи для выполнения:
        1. Обновить компоненты системы
        2. Очистить старые ядра
        3. Установить базовые программы (net-tools, mc, nano, htop, cron)
        4. Дать доступ по SSH для root
        5. Установить Docker и Portainer
        6. Выключить IPv6
        7. Выход
      private: no

  # Отключаем вывод пропущенных задач
  display_skipped_hosts: false

  tasks:
    - name: Обновить компоненты системы
      apt:
        update_cache: yes
        upgrade: dist
      when: task_number == "1"

    - name: Очистить старые ядра
      block:
        - name: Поиск старых ядер
          shell: |
            dpkg --list | grep linux-image | awk '{ print \$2 }' | sort -V | sed -n '/'$(uname -r)'/q;p'
          args:
            executable: /bin/bash
          register: old_kernels

        - name: Удалить старые ядра (если они есть)
          apt:
            name: "{{ old_kernels.stdout_lines }}"
            state: absent
            purge: yes
          when: old_kernels.stdout_lines | length > 0

        - name: Вывод результата очистки ядер
          debug:
            msg: |
              Удалены следующие ядра:
              {{ old_kernels.stdout_lines | join('\n') }}
          when: old_kernels.stdout_lines | length > 0

        - name: Сообщение, если старых ядер нет
          debug:
            msg: "Старые ядра не найдены."
          when: old_kernels.stdout_lines | length == 0
      when: task_number == "2"

    - name: Установить базовые программы
      apt:
        name:
          - net-tools
          - mc
          - nano
          - htop
          - cron
        state: present
      when: task_number == "3"

    - name: Дать доступ по SSH для root
      block:
        - name: Разрешить вход по SSH для root
          lineinfile:
            path: /etc/ssh/sshd_config
            regexp: '^#?PermitRootLogin'
            line: 'PermitRootLogin yes'
            state: present

        - name: Перезапустить службу SSH
          service:
            name: ssh
            state: restarted
      when: task_number == "4"

    - name: Установить Docker и Portainer
      block:
        - name: Установить зависимости для Docker
          apt:
            name:
              - apt-transport-https
              - ca-certificates
              - curl
              - software-properties-common
            state: present

        - name: Добавить GPG-ключ Docker
          apt_key:
            url: https://download.docker.com/linux/ubuntu/gpg
            state: present

        - name: Добавить репозиторий Docker
          apt_repository:
            repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable
            state: present

        - name: Установить Docker
          apt:
            name: docker-ce
            state: present

        - name: Запустить и включить Docker
          service:
            name: docker
            state: started
            enabled: yes

        - name: Установить Portainer
          docker_container:
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
      when: task_number == "5"

    - name: Выключить IPv6
      block:
        - name: Отключить IPv6 в sysctl
          sysctl:
            name: "{{ item }}"
            value: '1'
            state: present
            reload: yes
          loop:
            - net.ipv6.conf.all.disable_ipv6
            - net.ipv6.conf.default.disable_ipv6

        - name: Отключить IPv6 в GRUB
          lineinfile:
            path: /etc/default/grub
            regexp: '^GRUB_CMDLINE_LINUX='
            line: 'GRUB_CMDLINE_LINUX="ipv6.disable=1"'
            state: present

        - name: Обновить конфигурацию GRUB
          shell: update-grub
          args:
            executable: /bin/bash

        - name: Перезагрузить систему (требуется для применения изменений IPv6)
          reboot:
      when: task_number == "6"

    - name: Выход
      debug:
        msg: "Выход из меню"
      when: task_number == "7"

    - name: Ошибка выбора
      debug:
        msg: "Неверный выбор. Пожалуйста, выберите номер от 1 до 7."
      when: task_number not in ["1", "2", "3", "4", "5", "6", "7"]
EOF
  echo "YAML-файл с задачами создан: ubuntu_tasks.yml"
}

# Основной скрипт
main() {
  # Устанавливаем Ansible
  install_ansible

  # Создаем YAML-файл с задачами
  create_ansible_playbook

  # Основной цикл меню
  while true; do
    echo "Запуск Ansible-playbook..."
    ansible-playbook ubuntu_tasks.yml

    # Проверяем, был ли выбран выход
    if grep -q "task_number: \"7\"" ubuntu_tasks.yml; then
      echo "Выход из меню."
      break
    fi
  done
}

# Запуск основной функции
main
