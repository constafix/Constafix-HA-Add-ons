// haClient.js
require("dotenv").config();
const axios = require("axios");
const WebSocket = require("ws");

const HA_TOKEN = process.env.HA_TOKEN;
const HA_URL = process.env.HA_URL; // Например: http://homeassistant.local:8123
const WS_URL = process.env.HA_WS_URL; // Например: ws://homeassistant.local:8123/api/websocket

const haApi = axios.create({
  baseURL: `${HA_URL}/api`,
  headers: {
    Authorization: `Bearer ${HA_TOKEN}`,
    "Content-Type": "application/json",
  },
});

async function getStates() {
  const response = await haApi.get("/states");
  return response.data;
}

function connectWebSocket(onMessage) {
  const ws = new WebSocket(WS_URL);

  ws.on("open", () => {
    ws.send(
      JSON.stringify({
        type: "auth",
        access_token: HA_TOKEN,
      })
    );
  });

  ws.on("message", (data) => {
    const msg = JSON.parse(data);
    if (msg.type === "auth_ok") {
      console.log("✅ WebSocket auth successful");

      // Подписка на события
      ws.send(
        JSON.stringify({
          id: 1,
          type: "subscribe_events",
          event_type: "state_changed",
        })
      );
    }

    if (msg.type === "event" && onMessage) {
      onMessage(msg.event);
    }
  });

  ws.on("error", (err) => console.error("HA WebSocket error:", err));
  ws.on("close", () => console.warn("HA WebSocket закрыт"));

  return ws;
}

module.exports = {
  getStates,
  connectWebSocket,
};