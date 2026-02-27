# 🎓 Hellen App: AI-Powered English Learning Platform

**Hellen App** là một hệ sinh thái học tiếng Anh hiện đại, kết hợp sức mạnh của **Large Language Models (LLMs)** và các công nghệ hỗ trợ ngôn ngữ tiên tiến. Ứng dụng không chỉ là nơi lưu trữ từ vựng mà còn là một "gia sư AI" cá nhân, tự động tạo nội dung học tập dựa trên chính dữ liệu của người dùng.

---

## 🚀 Tính năng Chi tiết

### 🤖 Hệ thống Trí tuệ Nhân tạo (AI Core)
Tận dụng **Groq API** với mô hình **Llama 3.3 70B** để mang lại hiệu suất xử lý ngôn ngữ tự nhiên vượt trội:
- **Smart Reading Generator:** Phân tích danh sách từ vựng bạn đang học để viết một bài đọc hiểu logic, có ngữ cảnh, giúp bạn học từ thông qua việc đọc.
- **Dynamic Listening Creator:** Tạo kịch bản hội thoại và nội dung nghe dựa trên trình độ hiện tại của người dùng.
- **AI Grammar Assistant:** Không chỉ sửa lỗi mà còn giải thích tại sao câu của bạn sai và đề xuất cách diễn đạt tự nhiên hơn.
- **Automated Contextual Meaning:** Tự động tìm ví dụ và ngữ cảnh sử dụng cho từ vựng mới.

### 📚 Quản lý Học tập Thông minh
- **Cấu trúc Phân cấp:** Người dùng > Thư mục (Folders) > Bộ từ vựng (Vocabulary Sets).
- **Đa phương tiện:** Mỗi từ vựng hỗ trợ:
  - Định nghĩa nhiều nghĩa (Meanings & Definitions).
  - Hình ảnh minh họa (Image Upload).
  - Phát âm (TTS) và ví dụ sử dụng.
- **Dịch thuật Tức thời:** Tích hợp MyMemory API hỗ trợ dịch thuật đa ngôn ngữ với độ trễ thấp.

### 🎮 Chế độ Luyện tập & Tương tác
- **Flashcards:** Học tập dựa trên phương pháp lặp lại ngắt quãng (Spaced Repetition).
- **Game Modes:** Các trò chơi tương tác (Matching, Quiz) giúp việc học bớt nhàm chán.
- **Speech Practice:** Sử dụng **Speech-to-Text (STT)** để đánh giá khả năng phát âm của người dùng ngay trên ứng dụng.

---

## 🏗️ Kiến trúc Hệ thống

### Backend (Spring Boot Architecture)
Sử dụng mô hình **Controller-Service-Repository**:
- **Entities:** Quản lý mối quan hệ phức tạp giữa `User`, `Folder`, `Vocabulary`, và các bản ghi `GameResult`.
- **Cache System:** Sử dụng `ListeningContentCache` và `ReadingContentCache` để tối ưu hóa chi phí gọi API AI và tăng tốc độ phản hồi cho người dùng.
- **Security:** Tích hợp quy trình xác thực người dùng (Authentication) để bảo mật dữ liệu cá nhân.

### Frontend (Flutter MVVM)
- **View:** Giao diện người dùng mượt mà, hỗ trợ cả Android, iOS và Web.
- **ViewModel (Provider):** Tách biệt logic xử lý dữ liệu và giao diện, đảm bảo ứng dụng chạy ổn định và dễ bảo trì.
- **Services:** Các module độc lập cho `TTS`, `STT`, `Sound`, và `Image Upload`.

---

## 🛠️ Yêu cầu & Cấu hình Chi tiết

### 1. Backend Setup
**Yêu cầu:** JDK 17, Maven 3.x, MySQL 8.x.

**Biến môi trường cần thiết:**
Tạo tệp `application.properties` hoặc thiết lập biến môi trường:
```properties
# Database
spring.datasource.url=jdbc:mysql://localhost:3306/learning_vocabulary
spring.datasource.username=your_db_user
spring.datasource.password=your_db_password

# AI & API Keys
groq.api.key=gsk_xxxxxxxxxxxx... # Lấy tại console.groq.com
```

**Khởi chạy:**
```bash
cd back_end
mvn clean install
mvn spring-boot:run
```

### 2. Frontend Setup
**Yêu cầu:** Flutter SDK >= 3.7.0.

**Cấu hình API Endpoint:**
Mở `front_end/lib/core/app_constants.dart` (hoặc tệp cấu hình tương ứng) để trỏ về server:
```dart
const String baseUrl = "http://10.0.2.2:8080/api"; // Cho Emulator Android
// const String baseUrl = "http://localhost:8080/api"; // Cho Web/iOS Simulator
```

**Khởi chạy:**
```bash
cd front_end
flutter pub get
flutter run
```

---

## 📂 Sơ đồ Thư mục Chính

### Backend
- `controllers/`: Xử lý các HTTP Requests và điều phối luồng dữ liệu.
- `services/`: Chứa toàn bộ "logic nghiệp vụ", bao gồm các thuật toán AI và kết nối API bên thứ 3.
- `repositories/`: Giao tiếp với MySQL thông qua Spring Data JPA.
- `entities/`: Định nghĩa cấu trúc bảng và mối quan hệ Database.

### Frontend
- `lib/features/`: Chia theo module tính năng (Xác thực, Từ điển, Chế độ học...).
- `lib/api/`: Các lớp Wrapper để giao tiếp với Backend và các dịch vụ phần cứng (Mic, Loa, Camera).
- `lib/core/`: Chứa các hằng số, theme và widgets dùng chung cho toàn bộ app.

---

## 📈 Kế hoạch Phát triển (Roadmap)
- [ ] Tích hợp tính năng nhắc nhở học tập qua thông báo đẩy (Push Notifications).
- [ ] Bổ sung chế độ học nhóm và bảng xếp hạng (Leaderboard).
- [ ] Hỗ trợ học từ vựng qua Video (YouTube API integration).
- [ ] Phát triển phiên bản Desktop (Windows/macOS).

---

## 👤 Tác giả
- **Danh Nguyễn Nhựt An**
- Email: [an.danh@example.com] (Cập nhật email của bạn nếu muốn)

---
*Dự án này được xây dựng với tâm huyết nhằm giúp người Việt chinh phục tiếng Anh dễ dàng hơn nhờ công nghệ AI.*
