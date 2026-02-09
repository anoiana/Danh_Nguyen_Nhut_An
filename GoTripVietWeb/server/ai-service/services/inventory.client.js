const axios = require("axios");
const { INVENTORY_SERVICE_URL } = require("../config/env");

const http = axios.create({
  baseURL: INVENTORY_SERVICE_URL,
  timeout: 15000,
});

async function getActiveEvents() {
  // endpoint public mới: GET /events/active
  const { data } = await http.get("/events/active");
  return data;
}

module.exports = { getActiveEvents };
