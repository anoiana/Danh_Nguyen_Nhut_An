const axios = require("axios");
const { CATALOG_SERVICE_URL } = require("../config/env");

const http = axios.create({
  baseURL: CATALOG_SERVICE_URL,
  timeout: 15000,
});

function extractProducts(data) {
  // backend có thể trả: { products: [...] } hoặc { data: { products: [...] } } hoặc trả thẳng mảng
  if (Array.isArray(data)) return data;
  if (Array.isArray(data?.products)) return data.products;
  if (Array.isArray(data?.data?.products)) return data.data.products;
  if (Array.isArray(data?.data)) return data.data;
  return [];
}

async function searchTours({ q }) {
  const keyword = (q || "").trim();

  const res = await http.get("/products", {
    params: {
      product_type: "tour", // ✅ lọc đúng tour
      q: keyword, // ✅ Home hay dùng q
      search: keyword, // ✅ fallback nếu backend dùng search
      limit: 20,
    },
  });

  return extractProducts(res.data);
}

async function getTourByIdOrSlug(idOrSlug) {
  const { data } = await http.get(`/products/${idOrSlug}`);
  return data;
}

async function listTours({ limit = 100, page = 1 } = {}) {
  const res = await http.get("/products", {
    params: { product_type: "tour", limit, page },
  });
  return extractProducts(res.data);
}

module.exports = { searchTours, listTours, getTourByIdOrSlug };
