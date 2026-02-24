# Mini Dating App

Ứng dụng hẹn hò đơn giản giúp kết nối người dùng thông qua sở thích và tìm kiếm thời gian rảnh chung để hẹn hò.

## 🚀 Tính năng chính

- **Tạo Profile:** Người dùng nhập Tên, Tuổi, Giới tính, Bio, Email và **Avatar URL** để tham gia.
- **Khám phá (Discover):** Hiển thị danh sách người dùng với bộ lọc **Giới tính** và **Độ tuổi**.
- **Match Logic:** Khi hai người dùng thích nhau, hệ thống ghi nhận một "Match" và hiển thị popup chúc mừng.
- **Hệ thống Chat:** Sau khi match, hai người có thể nhắn tin trực tiếp với nhau ngay trên ứng dụng.
- **Quản lý Availability:** Người dùng chọn các khung giờ rảnh. Hệ thống tự động **ngăn chặn chọn ngày trong quá khứ** hoặc khung giờ không hợp lệ.
- **Đề xuất lịch hẹn thông minh:** Tìm slot trùng đầu tiên và **gợi ý hoạt động** (Cafe, Ăn tối, Đi dạo...) dựa trên khung giờ đó.

## 🛠 Công nghệ sử dụng

- **Frontend:** React, Tailwind CSS, Axios.
- **Backend:** Spring Boot 3 (Java), Spring Data JPA.
- **Database:** H2 / MySQL.
- **Lưu trữ:** Dữ liệu người dùng, likes, matches, messages và lịch rảnh được quản lý tập trung tại backend.

## 🧠 Logic hệ thống

### 1. Logic Match & Chat
- Khi User A Like User B, hệ thống kiểm tra tính đối xứng để tạo `Match`.
- Bản ghi `ChatMessage` lưu lịch sử trò chuyện giữa sender và receiver, hỗ trợ hiển thị theo thời gian thực (polling).

### 2. Logic Tìm Slot Trùng & Gợi ý (Smart Scheduling)
- So sánh các đoạn thời gian của 2 user: `max(start1, start2) < min(end1, end2)`.
- **Suggestion Engine:** Phân tích `hour` của slot trùng để đưa ra lời nhắn phù hợp (VD: 19h -> "Một buổi tối lãng mạn đang chờ!").

## 📈 Hướng phát triển tương lai

- **Gợi ý địa điểm:** Tích hợp Google Maps API để gợi ý quán cafe/nhà hàng cụ thể.
- **Xác thực OTP/OAuth2:** Tăng cường bảo mật với Google Login hoặc Email OTP.
- **Smart Notification:** Đẩy thông báo (Push Notification) khi có tin nhắn mới hoặc có người Like.

## 💡 Đề xuất 3 tính năng thêm cho sản phẩm

1. **Smart Matching dựa trên Bio:** Sử dụng NLP/AI để phân tích sở thích trong bản mô tả (Bio) và gợi ý những người có cùng đam mê.
2. **Ice Breaker Questions:** Tự động đưa ra các câu hỏi gợi mở trong khung chat để giúp hai người bắt đầu cuộc trò chuyện dễ dàng hơn.
3. **Double Date / Group Meetup:** Cho phép tạo các cuộc hẹn nhóm giữa nhiều cặp đã match để tăng tính an toàn và thú vị cho lần gặp đầu tiên.
