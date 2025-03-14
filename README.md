# Tools (sh & ubuntu)
Unix tools 

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
    

#### Запуск:
-     sudo apt install git -y && git clone https://github.com/idpro1313/tools.git
-     cd tools && sudo sh ./tools.sh

#### Установка ollama в docker:
-     cd tools && sudo sh ./ollama.sh
-     docker run -d -p 3000:8080 --add-host=192.168.10.10:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main

#### Очистка 
-     cd .. && rm -rf tools 
