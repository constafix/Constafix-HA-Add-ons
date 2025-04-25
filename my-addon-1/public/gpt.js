function askGPT() {
  const prompt = document.getElementById("prompt").value;
  document.getElementById("output").textContent = "Отправка...";

  fetch("http://localhost:3000/api/chat", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ message: prompt })
  })
    .then(res => res.json())
    .then(data => {
      document.getElementById("output").textContent =
        data.choices?.[0]?.message?.content || "Нет ответа от модели.";
    })
    .catch(err => {
      document.getElementById("output").textContent = "Ошибка: " + err.message;
    });
}
