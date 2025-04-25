// aiClient.js
require("dotenv").config();
const axios = require("axios");

const API_KEY = process.env.AI_API_KEY;
const API_URL = process.env.AI_API_URL; // Например: https://api.intelligence.io.solutions/api/v1
const client = axios.create({
  baseURL: `${API_URL}`,
  headers: {
    Authorization: API_KEY,
    "Content-Type": "application/json",
  },
});

async function sendMessageToAI(message) {
  const response = await client.post("/chat/completions", {
    model: "deepseek-ai/DeepSeek-R1",
    messages: [{ role: "user", content: message }],
  });

  return response.data;
}

module.exports = {
  sendMessageToAI,
};