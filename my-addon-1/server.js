const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const path = require("path");

const { sendMessageToAI } = require("./aiClient");
const { getStates, connectWebSocket } = require("./haClient");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, "public")));

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

// 💬 Обращение к ИИ
app.post("/api/chat", async (req, res) => {
  try {
    const aiResponse = await sendMessageToAI(req.body.message);
    res.json(aiResponse);
  } catch (err) {
    res.status(500).json({ error: "AI API error" });
  }
});

// 🏠 Получение состояния HA
app.get("/api/states", async (req, res) => {
  try {
    const states = await getStates();
    res.json(states);
  } catch (err) {
    res.status(500).json({ error: "HA API error" });
  }
});

app.listen(PORT, () => {
  console.log(`Сервер запущен на http://localhost:${PORT}`);

  // 🔌 WebSocket HA
  connectWebSocket((event) => {
    console.log("📡 HA событие:", event.entity_id, event.new_state?.state);
    // здесь можно логировать, сохранять, пересылать и т.д.
  });
});
