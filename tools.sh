$ ./setup_and_run_ansible.sh
Установка Ansible...
Ansible уже установлен.
Файл ansible.cfg создан в текущей директории.
YAML-файл с задачами создан: ubuntu_tasks.yml
Запуск Ansible-playbook...

Выберите номер задачи для выполнения:
1. Обновить компоненты системы
2. Очистить старые ядра
3. Установить базовые программы (net-tools, mc, nano, htop, cron)
4. Дать доступ по SSH для root
5. Установить Docker и Portainer
6. Выключить IPv6
7. Выход
: 1

TASK [Обновить компоненты системы] ****************************************
changed: [localhost]

PLAY RECAP ****************************************************************
localhost: ok=1 changed=1 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0

Запуск Ansible-playbook...

Выберите номер задачи для выполнения:
1. Обновить компоненты системы
2. Очистить старые ядра
3. Установить базовые программы (net-tools, mc, nano, htop, cron)
4. Дать доступ по SSH для root
5. Установить Docker и Portainer
6. Выключить IPv6
7. Выход
: 7

TASK [Выход] **************************************************************
ok: [localhost] => {
    "msg": "Выход из меню"
}

PLAY RECAP ****************************************************************
localhost: ok=1 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0

Выход из меню.
