FROM node:18-alpine

# Создаём директорию
WORKDIR /app

# Копируем package.json и package-lock.json (если есть)
COPY package*.json ./

# Устанавливаем зависимости
RUN npm install

# Копируем оставшиеся файлы
COPY . .

# Делаем скрипт исполняемым
RUN chmod +x /app/run.sh

# Запускаем
CMD ["/app/run.sh"]