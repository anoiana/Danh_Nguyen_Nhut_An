const axios = require("axios");
const { CATALOG_SERVICE_URL } = require("../config/env");

const http = axios.create({
  baseURL: CATALOG_SERVICE_URL,
  timeout: 15000,
});

let cached = { data: null, at: 0 };

async function listLocations() {
  const now = Date.now();
  if (cached.data && now - cached.at < 10 * 60 * 1000) return cached.data; // 10 phút

  const { data } = await http.get("/locations");
  const locations = Array.isArray(data) ? data : data?.data || [];
  cached = { data: locations, at: now };
  return locations;
}

module.exports = { listLocations };
