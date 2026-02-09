# GoTripViet – Hệ thống khuyến nghị tour du lịch ứng dụng AI

GoTripViet là hệ thống đặt tour theo kiến trúc Microservices, hỗ trợ:

- Web client (React)
- Mobile (Flutter/Dart – nếu có thư mục riêng)
- Backend tách service: user, catalog/product, inventory, booking, payment, AI
- API-Gateway làm cổng vào thống nhất
- AI Chatbox theo hướng RAG (Ollama + Qdrant)

---

## 0) Tác giả

- GoTripViet – Dự án công nghệ thông tin: “Hệ thống khuyến nghị tour du lịch ứng dụng AI” của sinh viên Lê Công Tuấn (52200033) và Danh Nguyễn Nhựt An (5220008)

## 1) Yêu cầu môi trường

- Node.js (khuyến nghị: >= 18)
- npm
- MongoDB (local hoặc MongoDB Atlas)
- Docker (để chạy Qdrant cho AI-service)

---

## 2) Cấu trúc thư mục (tham khảo)

```
.
├── client/                       # React Web
└── server/
    ├── api-gateway/              # Gateway
    ├── user-service/
    ├── catalog-service/          # (product-service)
    ├── inventory-service/
    ├── booking-service/
    ├── payment-service/
    └── ai-service/
```

---

## 3) Cài đặt dependencies

### 3.1 Cài dependencies cho client

```bash
cd client
npm install
```

### 3.2 Cài dependencies cho từng service backend

Ví dụ (lặp lại cho mỗi service):

```bash
cd server/user-service
npm install

cd ../catalog-service
npm install

cd ../inventory-service
npm install

cd ../booking-service
npm install

cd ../payment-service
npm install

cd ../ai-service
npm install

cd ../api-gateway
npm install

cd ../../client
npm install
```

---

## 4) Cấu hình biến môi trường (.env)

Mỗi service sẽ có `.env` riêng (và gateway cũng có `.env` riêng).

Tối thiểu bạn cần đảm bảo:

- MongoDB URI cho từng service
- JWT_SECRET (gateway và user-service phải khớp nếu gateway verify JWT)
- INTERNAL_API_KEY (cho các route internal giữa các service)
- Base URL giữa các service (nếu service gọi nhau)
- Với AI-service: QDRANT_URL, QDRANT_COLLECTION, OLLAMA_URL, model name...

---

## 5) Chạy hệ thống

### 5.1 Chạy Client (React)

```bash
cd client
npm run dev
```

---

### 5.2 Chạy Backend Microservices (mỗi service một terminal)

Mỗi service bạn vào đúng thư mục và chạy:

```bash
npm start
```

Ví dụ:

```bash
cd server/user-service
npm start
```

Lặp lại tương tự cho:

- catalog-service (product-service)
- inventory-service
- booking-service
- payment-service
- ai-service (lưu ý: cần Qdrant chạy trước)

---

### 5.3 Chạy API-Gateway

```bash
cd server/api-gateway
npm start
```

> Khuyến nghị thứ tự chạy:

1. MongoDB
2. Các service (user/catalog/inventory/booking/payment/ai)
3. API-Gateway
4. Client

---

## 6) Chạy AI-service (Qdrant bằng Docker)

AI-service cần Qdrant làm Vector Database. Bạn chạy Qdrant bằng Docker như sau:

```bash
docker run -d \
  --name qdrant \
  -p 6333:6333 \
  -v qdrant_storage:/qdrant/storage \
  qdrant/qdrant
```

Kiểm tra Qdrant đã chạy:

```bash
docker ps
```

Hoặc gọi thử:

```bash
curl http://localhost:6333/collections
```

> Lưu ý:

- Nếu container `qdrant` đã tồn tại, bạn có thể start lại bằng:
  ```bash
  docker start qdrant
  ```
- Nếu bị trùng port, hãy đổi `-p 6333:6333` sang port khác và cập nhật `QDRANT_URL` trong `.env` AI-service.

---

## 7) Troubleshooting nhanh

- **Client gọi API bị 404**: kiểm tra gateway đang chạy và route prefix đúng.
- **401/Forbidden Invalid token**: kiểm tra JWT_SECRET đồng bộ + header Authorization đúng.
- **AI không gợi ý được**: kiểm tra Qdrant đã chạy, QDRANT_URL đúng, và dữ liệu đã được index vào Qdrant.
- **Lỗi kết nối giữa service**: kiểm tra BASE_URL/PORT trong `.env` từng service.

---
