FROM node:18-alpine

# Создаём директорию
WORKDIR /app

# Копируем файлы
COPY server.js .
COPY run.sh .

# Делаем скрипт исполняемым
RUN chmod +x /app/run.sh

# Устанавливаем зависимости, если есть
# RUN npm install

# Запускаем
CMD ["/app/run.sh"]
