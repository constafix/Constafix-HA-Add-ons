# 📦 PostgreSQL Server — Reliable Database Add-on for Home Assistant  
### Built for stability, simplicity, and performance.  
**By Constafix — crafting the digital future of your smart home.**

--- 

**PostgreSQL Server** is a custom Home Assistant add-on that runs a standalone PostgreSQL 16 server inside the Supervisor environment. Designed for integrations, dashboards, analytics, or data logging — this add-on helps extend the capabilities of your smart home.

### 🔧 Features
- ✅ Automatic database initialization on first start
- ✅ Configuration through Home Assistant UI
- ✅ Fully compatible with PostgreSQL 16
- ✅ External LAN access support (configurable)
- ✅ Data persists across restarts and updates
- ✅ Supports multiple CPU architectures (amd64, armv7, aarch64, etc.)

### 💡 Use Cases
- Store data from custom integrations
- Serve as a backend for dashboards like Grafana
- Connect with scripts, automations, and analytics tools
- Use as a shared smart home database

### 🚀 Quick Start
1. Install the add-on via **Supervisor → Add-ons**
2. Go to the **Configuration** tab:
   - Set `database`, `username` and `password`
3. Start the add-on
4. Connect using any PostgreSQL client:
   ```bash
   psql postgresql://<user>:<pass>@<HA_IP>:5432/<database>
   ```

### 🔐 Security Note
This add-on does not expose its ports to the internet by default. For LAN access, ensure your `pg_hba.conf` allows connections from the desired IP ranges. TLS is not enabled by default — use at your own risk or wrap connections via a secure tunnel/VPN.

---

## 🇷🇺 

**PostgreSQL Server** — это пользовательский аддон для Home Assistant, запускающий отдельный сервер PostgreSQL 16 внутри среды Supervisor. Он идеально подходит для хранения данных от интеграций, логирования, аналитики или подключения внешних инструментов.

### 🔧 Возможности
- ✅ Автоматическая инициализация базы данных при первом запуске
- ✅ Настройка через интерфейс Home Assistant
- ✅ Совместимость с PostgreSQL 16
- ✅ Поддержка внешнего доступа по локальной сети (настраивается)
- ✅ Данные сохраняются между перезапусками и обновлениями
- ✅ Поддержка всех популярных архитектур CPU (amd64, armv7, aarch64 и др.)

### 💡 Примеры использования
- Хранение данных пользовательских интеграций
- Использование как базы данных для дашбордов (например, Grafana)
- Подключение из скриптов и автоматизаций
- Общая база данных для умного дома

### 🚀 Быстрый старт
1. Установите аддон через **Supervisor → Add-ons**
2. Перейдите во вкладку **Configuration**:
   - Укажите `database`, `username` и `password`
3. Запустите аддон
4. Подключитесь с помощью клиента PostgreSQL:
   ```bash
   psql postgresql://<user>:<pass>@<IP_HA>:5432/<database>
   ```

### 🔐 Примечание по безопасности
По умолчанию аддон не публикует порты в интернет. Для доступа по локальной сети проверьте настройки `pg_hba.conf`. TLS-соединение по умолчанию не используется — обеспечьте безопасность через VPN или туннель, если необходимо.

---

**© Constafix — создаём цифровое будущее вашего умного дома.**