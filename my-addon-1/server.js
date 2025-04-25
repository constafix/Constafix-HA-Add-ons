const express = require("express");
const axios = require("axios");
const cors = require("cors");
const bodyParser = require("body-parser");
const path = require("path");

const app = express();
const PORT = 3000;

// ⚠️ Вставь сюда свой токен
const API_KEY = "Bearer io-v2-eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvd25lciI6IjQ0MDlmYWYwLTk4MzItNDBhOC1hZDc4LWIzMWY2M2NiZjkyNSIsImV4cCI6NDg5OTEwMTgwM30.H46Wt5iF4Bq_JynAVFwG5SG8BwoKywAcQH34bssJ20P_ElSjr9WhJyFvyrKtFaeJdxc_OQ7BqtZNnSyo6kAq7w";

// Мидлвары
app.use(cors());
app.use(bodyParser.json());

// Обслуживаем статические файлы из папки "public"
app.use(express.static(path.join(__dirname, "public")));

// Отдаём index.html при GET-запросе к корню
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

// Обработка POST-запроса к API
app.post("/api/chat", async (req, res) => {
  try {
    const userMessage = req.body.message;

    const response = await axios.post(
      "https://api.intelligence.io.solutions/api/v1/chat/completions",
      {
        model: "deepseek-ai/DeepSeek-R1", // Или подходящая модель
        messages: [
          { role: "user", content: userMessage }
        ],
      },
      {
        headers: {
          Authorization: API_KEY,
          "Content-Type": "application/json"
        }
      }
    );

    res.json(response.data);
  } catch (err) {
    console.error(err.response?.data || err.message);
    res.status(500).json({ error: "Ошибка при обращении к API" });
  }
});

app.listen(PORT, () => {
  console.log(`Сервер запущен на http://localhost:${PORT}`);
});
