# 🌊 Breeze — Mini Dating App Prototype

> Bài test kỹ thuật — Web Developer Intern @ Clique83.com (2026)

**Live Demo:** [Link Deploy](#) *(sẽ cập nhật sau khi deploy)*  
**Stack:** React + Vite (Frontend) · Spring Boot + MySQL (Backend)

---

## 📖 Mục lục

1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Cách lưu trữ dữ liệu](#2-cách-lưu-trữ-dữ-liệu)
3. [Logic Match hoạt động thế nào](#3-logic-match-hoạt-động-thế-nào)
4. [Logic tìm slot trùng hoạt động thế nào](#4-logic-tìm-slot-trùng-hoạt-động-thế-nào)
5. [Hướng dẫn chạy dự án](#5-hướng-dẫn-chạy-dự-án)
6. [Nếu có thêm thời gian, tôi sẽ cải thiện gì](#6-nếu-có-thêm-thời-gian-tôi-sẽ-cải-thiện-gì)
7. [Đề xuất tính năng bổ sung](#7-đề-xuất-tính-năng-bổ-sung)
8. [Điểm cộng — Các cải tiến đã thực hiện](#8-điểm-cộng--các-cải-tiến-đã-thực-hiện)

---

## 1. Tổng quan hệ thống

### Kiến trúc: Feature-Sliced N-Tier

Dự án được tổ chức theo **Feature-based Architecture** — mỗi tính năng (auth, matching, scheduling) được đóng gói riêng biệt với đầy đủ các layer.

```
Dating_web/
├── backend/                          # Spring Boot API Server
│   └── src/main/java/.../
│       ├── features/                 # Tổ chức theo tính năng
│       │   ├── auth/                 # Đăng ký, đăng nhập (Google OAuth + JWT)
│       │   │   └── controller/
│       │   ├── user/                 # Quản lý profile, discovery feed
│       │   │   ├── controller/
│       │   │   ├── service/          # DiscoveryService (feed 7 profiles/ngày)
│       │   │   ├── repository/
│       │   │   ├── entity/           # User entity
│       │   │   └── dto/
│       │   ├── matching/             # Like/Skip, Match detection
│       │   │   ├── controller/       # LikeController, MatchController
│       │   │   ├── service/          # LikeService (mutual like → match)
│       │   │   ├── repository/
│       │   │   ├── entity/           # Like, Match entities
│       │   │   └── dto/
│       │   ├── scheduling/           # Availability, Date Booking, Feedback
│       │   │   ├── controller/       # AvailabilityController, DateBookingController
│       │   │   ├── service/          # MatchingEngineService (slot algorithm)
│       │   │   ├── repository/
│       │   │   ├── entity/           # Availability, DateBooking entities
│       │   │   └── dto/
│       │   └── chat/                 # Real-time messaging (WebSocket)
│       └── infra/                    # Cross-cutting concerns
│           ├── config/               # WebSocket config
│           ├── security/             # JWT filter, Spring Security
│           └── exception/            # Global exception handler
│
├── frontend/                         # React + Vite
│   └── src/
│       ├── features/                 # Feature modules
│       │   ├── auth/                 # Login, Register, Profile Editor
│       │   │   ├── api/
│       │   │   ├── components/       # ProfileEditor → AvatarSection, InfoFields...
│       │   │   ├── hooks/            # useAuth, useProfileEditor
│       │   │   └── context/          # AuthContext (JWT state)
│       │   ├── matching/             # Feed, Matches, Bookings, Availability
│       │   │   ├── api/
│       │   │   ├── components/       # MatchFeed, FeedCard, AvailabilityModal...
│       │   │   └── hooks/            # useFeed, useAvailability
│       │   └── scheduling/
│       │       └── api/
│       ├── components/               # Shared UI components
│       │   ├── common/               # LoadingSpinner, EmptyState, ModalOverlay
│       │   └── layout/               # Header, GlobalMatchPopup
│       ├── hooks/                    # Shared hooks (useWebSocket)
│       ├── lib/                      # Axios client, constants
│       ├── context/                  # NotificationContext, LoadingContext
│       └── pages/                    # Route-level pages
```

### Tech Stack

| Layer | Công nghệ |
|-------|-----------|
| **Frontend** | React 18, Vite, React Router v6, Axios, TailwindCSS |
| **Backend** | Spring Boot 3, Spring Security, Spring WebSocket (STOMP) |
| **Database** | MySQL 8 (via JPA/Hibernate) |
| **Auth** | JWT + Google OAuth 2.0 |
| **Upload** | Cloudinary (avatar & photos) |
| **Real-time** | WebSocket (SockJS + STOMP) |

---

## 2. Cách lưu trữ dữ liệu

### Database: MySQL (Relational Database)

Tất cả dữ liệu được lưu trong **MySQL** thông qua **JPA/Hibernate**. Dữ liệu được persist vĩnh viễn, không mất khi reload.

**Các bảng chính:**

| Bảng | Mục đích | Các cột quan trọng |
|------|----------|---------------------|
| `users` | Hồ sơ người dùng | id, name, age, gender, bio, email, password, avatar_url, photos, interests |
| `likes` | Lưu Like/Skip giữa 2 users | id, from_user_id, to_user_id, type (LIKE/SKIP), created_at |
| `matches` | Lưu trạng thái match | id, user1_id, user2_id, status (WAITING/PROPOSED/SCHEDULED), created_at |
| `availabilities` | Thời gian rảnh | id, user_id, start_time, end_time |
| `date_bookings` | Lịch hẹn đã đặt | id, requester_id, recipient_id, start_time, end_time, venue, status |
| `activities` | Activity log | id, user_id, content, type, is_read, created_at |

**Cấu hình kết nối:**
```properties
spring.datasource.url=jdbc:mysql://localhost:3306/dating_db
spring.jpa.hibernate.ddl-auto=update  # Tự tạo/cập nhật schema
```

---

## 3. Logic Match hoạt động thế nào

### Flow: Like → Mutual Check → Match

```
User A nhấn "Like" User B
        │
        ▼
┌──────────────────────────────┐
│  LikeService.processLike()   │
│  1. Lưu Like(A → B) vào DB  │
│  2. Kiểm tra: B đã Like A?  │
│     │                        │
│     ├─ CHƯA → return false   │
│     │   (Chờ B like lại)     │
│     │                        │
│     └─ RỒI → MATCH! 🎉      │
│        MatchService          │
│        .createMatch(A, B)    │
│        Lưu Match vào DB      │
└──────────────────────────────┘
```

### Chi tiết kỹ thuật

**Bước 1 — Like:**
```java
// LikeService.java
if (!likeRepository.existsByFromUserAndToUser(fromUser, toUser)) {
    Like like = new Like(fromUser, toUser, Like.Type.LIKE);
    likeRepository.save(like);
}
```

**Bước 2 — Reciprocity Check (Kiểm tra ngược):**
```java
boolean isMutual = likeRepository.existsByFromUserAndToUserAndType(
    toUser, fromUser, Like.Type.LIKE
);
```
→ Nếu B đã Like A trước đó, `isMutual = true` → tạo Match.

**Bước 3 — Symmetry Normalization (Chống trùng):**
```java
// MatchService.java - Luôn lưu ID nhỏ hơn vào user1
if (u1.getId() < u2.getId()) {
    user1 = u1; user2 = u2;
} else {
    user1 = u2; user2 = u1;
}
```
→ Đảm bảo dù A like B hay B like A, chỉ tạo **1 Match record** duy nhất.

**Bước 4 — Thông báo:** Cả 2 users nhận activity log `"You and [tên] have matched! 💖"`.

### Edge Cases đã xử lý
- ✅ Không cho user like chính mình
- ✅ Không cho like trùng lặp (check `existsByFromUserAndToUser`)
- ✅ Không tạo match trùng (Symmetry Normalization)
- ✅ Skip cũng được lưu → user đã skip sẽ không xuất hiện lại trong feed

---

## 4. Logic tìm slot trùng hoạt động thế nào

### Flow: Availability → Algorithm → Proposed Date

```
A & B đã match
        │
        ▼
Cả 2 chọn availability (3 tuần tới)
        │
        ▼
Cả 2 nhấn "Submit Availability"
        │
        ▼
┌────────────────────────────────────────┐
│  MatchingEngineService                 │
│  .findFirstCommonSlot(userA, userB)    │
│                                        │
│  1. Lấy tất cả slots của A và B       │
│  2. Sắp xếp theo thời gian            │
│  3. So sánh từng cặp (A[i], B[j])     │
│  4. Tìm phần giao (overlap)           │
│  5. Overlap ≥ 90 phút? → ĐẠT!        │
│  6. Kiểm tra trùng booking cũ         │
│                                        │
│  ├─ TÌM THẤY → Tạo PROPOSED booking  │
│  │   + Random venue                    │
│  │   + WebSocket notify cả 2 bên      │
│  │                                     │
│  └─ KHÔNG TÌM THẤY                    │
│      + Xóa availability cả 2 bên      │
│      + Thông báo "Chọn lại!"          │
└────────────────────────────────────────┘
```

### Thuật toán chi tiết (MatchingEngineService.findFirstCommonSlot)

```java
// 1. Lấy availability của cả 2 users
List<Availability> list1 = availabilityRepository.findByUser(u1); // slots của A
List<Availability> list2 = availabilityRepository.findByUser(u2); // slots của B

// 2. Sắp xếp theo startTime (tìm slot sớm nhất)
list1.sort(by startTime);
list2.sort(by startTime);

// 3. Duyệt tất cả các cặp
for (Availability a : list1) {
    for (Availability b : list2) {
        // Chỉ so sánh cùng ngày
        if (!a.date == b.date) continue;

        // 4. Tìm phần giao:
        //    maxStart = max(a.start, b.start)  ← bắt đầu muộn hơn
        //    minEnd   = min(a.end, b.end)      ← kết thúc sớm hơn
        maxStart = max(a.startTime, b.startTime);
        minEnd   = min(a.endTime, b.endTime);

        // 5. Nếu có overlap & ≥ 90 phút
        if (maxStart < minEnd) {
            minutes = duration(maxStart, minEnd);
            if (minutes >= 90) {
                // 6. Kiểm tra không trùng booking đã có
                if (noOverlapWithExistingBookings) {
                    return new Slot(maxStart, minEnd); // ✅ FOUND!
                }
            }
        }
    }
}
return null; // ❌ Không tìm thấy
```

### Ví dụ minh họa

```
User A chọn:  Ngày 25/2, 09:00 → 17:00
User B chọn:  Ngày 25/2, 14:00 → 20:00

Tính overlap:
  maxStart = max(09:00, 14:00) = 14:00
  minEnd   = min(17:00, 20:00) = 17:00
  Duration = 17:00 - 14:00 = 180 phút ≥ 90 phút ✅

→ Kết quả: "Hai bạn có date hẹn vào: 25/2 lúc 14:00"
→ Venue: "The Coffee House - Tran Cao Van" (random)
```

### Sau khi tìm được slot

1. Tạo `DateBooking` với status `PROPOSED`
2. Chọn ngẫu nhiên 1 venue từ danh sách đối tác
3. Push thông báo real-time qua **WebSocket** tới cả 2 users
4. Cả 2 cần nhấn **"Confirm"** → Status chuyển thành `CONFIRMED`
5. Chat window mở trước buổi hẹn 4 tiếng

---

## 5. Hướng dẫn chạy dự án

### Yêu cầu

- **JDK 21+**
- **Node.js 18+** & **npm**
- **MySQL 8**

### Bước 1 — Tạo database MySQL

```sql
CREATE DATABASE dating_db;
```

### Bước 2 — Cấu hình Backend

Sửa file `backend/src/main/resources/application.properties`:
```properties
spring.datasource.url=jdbc:mysql://localhost:3306/dating_db
spring.datasource.username=root
spring.datasource.password=YOUR_PASSWORD
```

### Bước 3 — Chạy Backend

```bash
cd backend
./mvnw spring-boot:run
```
Server chạy tại `http://localhost:8080`

### Bước 4 — Chạy Frontend

```bash
cd frontend
npm install
npm run dev
```
App chạy tại `http://localhost:3000`

---

## 6. Nếu có thêm thời gian, tôi sẽ cải thiện gì

### 🧪 Testing
- **Unit tests** cho các service quan trọng (`LikeService`, `MatchingEngineService`)
- **Integration tests** cho API endpoints
- **Component tests** cho React components với React Testing Library

### 🏗️ Architecture
- **Error Boundary per-feature** — mỗi tab/feature có error boundary riêng, một tab lỗi không crash toàn app
- **API service layer thống nhất** — tạo base service class với error handling, retry logic, caching
- **State management tập trung** — sử dụng Zustand hoặc Redux Toolkit thay vì mix Context + local state

### 🎨 UI/UX
- **Responsive hoàn chỉnh** — tối ưu cho mobile view
- **Skeleton loading** cho mọi trang (hiện đã có cho feed, chưa có cho bookings)
- **Swipe gesture** trên mobile cho feed cards (thay vì chỉ nút Like/Skip)
- **Dark mode** toggle

### 🔒 Security
- **Input sanitization** chống XSS
- **Rate limiting** cho API endpoints
- **CORS configuration** chặt hơn cho production

---

## 7. Đề xuất tính năng bổ sung

### 1. 🎟️ Hệ thống Date Token (Payment Commitment)

**Lý do:** Theo mô hình Breeze thực tế, user phải thanh toán token trước khi date được xác nhận. Điều này:
- Giảm **90% tỷ lệ no-show** (vì đã bỏ tiền)
- Tạo **cam kết 2 chiều** — cả 2 bên đều nghiêm túc
- Là **mô hình kinh doanh chính** của app (pay-per-date, không subscription)

**Cách implement:**
- User mua token (ví dụ: 100.000 VNĐ/token)
- Mỗi date tiêu tốn 1 token từ mỗi bên
- Token được hoàn nếu đối phương hủy

### 2. 🛡️ Anti-Ghosting & Badge System

**Lý do:** Người dùng hẹn hò online thường bị "ghost" (đối phương biến mất không thông báo). Hệ thống penalty + reward:
- **Penalty:** Hủy date bị freeze tài khoản 48h, hủy 3 lần → ban vĩnh viễn
- **Badge "Respected":** User có lịch sử date tốt nhận badge hiển thị trên profile → tăng độ tin cậy
- **Tác dụng:** Xây dựng cộng đồng hẹn hò lành mạnh, lọc bỏ người thiếu trách nhiệm

**Cách implement:**
- Bảng `user_reputation` lưu điểm uy tín
- Post-date feedback ảnh hưởng đến điểm
- Đạt ngưỡng điểm → tự động gán badge

### 3. 🤖 Smart Matching Score (AI-powered)

**Lý do:** Hiện tại feed chỉ random 7 profiles. Nếu thêm **compatibility score** dựa trên:
- Sở thích chung (interests overlap)
- Độ tuổi phù hợp
- Lịch sử tương tác (loại profile user thường like)

→ Chất lượng match **tăng đáng kể**, user tìm được người phù hợp nhanh hơn, retention cao hơn.

**Cách implement:**
- Thuật toán scoring đơn giản: `score = (common_interests × 15) + age_proximity_bonus + activity_bonus`
- Sắp xếp feed theo score giảm dần thay vì random
- Nâng cấp sau: sử dụng ML (collaborative filtering) khi có đủ dữ liệu

---

## 8. Điểm cộng — Các cải tiến đã thực hiện

Dưới đây là các cải tiến đã được triển khai trong dự án, mapping theo **6 tiêu chí điểm cộng** của đề bài.

### ✅ 8.1. Thêm tính năng hợp lý

Ngoài yêu cầu cơ bản (Profile, Like/Match, Chọn lịch), dự án bổ sung các tính năng lấy cảm hứng từ mô hình **Breeze Dating App** thực tế:

| Tính năng | Mô tả | File chính |
|---|---|---|
| 💬 **Real-time Chat** | Chat qua WebSocket, chỉ mở 4h trước giờ hẹn (theo model Breeze — "no chat, just dates") | `ChatController.java`, `ChatWindow.jsx` |
| 💌 **Post-date Feedback** | Sau buổi hẹn, cả 2 đánh giá: có đến không? Muốn liên lạc tiếp không? | `DateBookingService.submitFeedback()`, `FeedbackModal.jsx` |
| 🤝 **Contact Exchange** | Chỉ tiết lộ thông tin liên hệ khi **CẢ HAI** bên đều chọn "muốn liên lạc" → bảo vệ quyền riêng tư | `DateBookingService.java` (mutual reveal logic) |
| � **Auto Venue Selection** | Hệ thống tự chọn venue từ danh sách 5 quán đối tác tại TP.HCM | `MatchingEngineService.VENUES[]` |
| 🔔 **Activity Center** | Trung tâm thông báo: match, booking, message, feedback — tất cả hoạt động được log | `ActivityService.java`, `ActivityCenter.jsx` |
| 📸 **Photo Upload** | Upload avatar và nhiều ảnh lên Cloudinary, không chỉ text input | `CloudinaryConfig.java`, `OnboardingFlow.jsx` |
| 🔐 **Google OAuth 2.0** | Đăng nhập nhanh bằng Google, xác thực danh tính (đề bài nói "không bắt buộc" nhưng tăng UX) | `AuthController.java`, `LoginForm.jsx` |

### ✅ 8.2. Xử lý Validation

| Validation | Vị trí | Mục đích |
|---|---|---|
| Slot phải ≥ 90 phút | `MatchingEngineService.findFirstCommonSlot()` | Đảm bảo chất lượng buổi hẹn |
| Không chọn ngày trong quá khứ | `useAvailability.js` | `if (date === minDateStr && start < new Date())` |
| Giới hạn 3 tuần tới | `MAX_SCHEDULE_DAYS_AHEAD` constant | Tránh chọn quá xa, thiếu cam kết |
| Slot không được overlap nhau | `useAvailability.js → isOverlap` check | Tránh nhập trùng lịch |
| Start time < End time | `useAvailability.js` | `if (start >= end)` |
| Tối thiểu 3 slots mới được submit | `MIN_AVAILABILITY_SLOTS` constant | Đủ lựa chọn cho thuật toán |
| Email unique | `User.java: @Column(unique = true)` | Không cho đăng ký trùng email |
| Không like chính mình | `MatchService.createMatch()` | `if (u1.getId().equals(u2.getId()))` |
| Không like trùng lặp | `LikeService.processLike()` | `existsByFromUserAndToUser()` |
| Chống double-booking | `MatchingEngineService` | `findOverlappingBookings()` trước khi tạo proposal |

### ✅ 8.3. Tối ưu UX

| Cải tiến UX | Chi tiết |
|---|---|
| 🎆 **Match Popup Animation** | Popup "It's a Match!" với bounce-in animation và hiệu ứng gradient, thay vì chỉ text thông báo |
| 🎟️ **E-Ticket Design** | Sau khi confirm booking → hiển thị "e-ticket" card với ticket punch-hole design, tạo cảm giác premium |
| ⏳ **Waiting State** | Khi User A đã submit availability nhưng User B chưa → hiển thị "Đang chờ đối phương..." với animation rõ ràng |
| 🔥 **Auto Status Badge** | Tự động phát hiện trạng thái: `Pending` → `Confirmed` → `Happening Now` → `Completed` với màu sắc phù hợp |
| 🎨 **Glassmorphism UI** | Toàn bộ giao diện sử dụng glassmorphism: backdrop-blur, gradient subtle, micro-animations |
| 📱 **Tab Navigation** | Feed / Matches / Bookings / Activity trên cùng 1 trang, chuyển tab mượt mà không reload |
| 🔔 **Toast Notifications** | `react-hot-toast` cho phản hồi tức thì: success (xanh), error (đỏ), info (xanh dương) |
| 👤 **Profile Detail Modal** | Click vào bất kỳ profile card → mở modal xem đầy đủ: ảnh, bio, sở thích, tuổi, trước khi quyết định Like/Skip |
| 🎯 **Onboarding Flow** | Đăng ký qua 4 bước: Thông tin → Sở thích → Upload ảnh → Hoàn tất (multi-step wizard thay vì 1 form dài) |

### ✅ 8.4. Thêm Loading State

| Loading State | Component | Khi nào hiển thị |
|---|---|---|
| `LoadingSpinner` | Reusable component | Khi đang load Matches, Bookings, Activities |
| `SkeletonCard` | Feed page | Placeholder skeleton khi đang fetch profiles từ API |
| `LoadingContext` | Global overlay | Khi submit availability, confirm booking, delete slot (blocking UI) |
| `submitting` state | `FeedbackModal.jsx` | Disable nút "Send Feedback" khi đang gửi, tránh double-submit |
| `EmptyState` | Matches, Bookings, Activities | Hiển thị friendly message + icon khi chưa có data, thay vì blank page |

### ✅ 8.5. Xử lý Edge Cases

| Edge Case | Cách xử lý | File |
|---|---|---|
| User Like chính mình | `IllegalArgumentException` | `MatchService.java` |
| Like trùng (Like 2 lần cùng người) | `existsByFromUserAndToUser()` → skip | `LikeService.java` |
| Match trùng (A-B = B-A) | **Symmetry Normalization**: luôn lưu smaller ID = user1 | `MatchService.createMatch()` |
| Slot trùng booking đã có | `findOverlappingBookings()` check trước khi propose | `MatchingEngineService.java` |
| Availability overlap chính nó | Frontend check `isOverlap` trước khi gửi API | `useAvailability.js` |
| Không tìm được slot chung | Reset availability cả 2 bên + notify "Chọn lại!" qua WebSocket | `MatchingEngineService.executeMatching()` |
| User bị penalty (anti-flaker) | Block khỏi discovery feed cho đến `penalizedUntil` | `DiscoveryService.getFeed()` |
| Cancel booking hậu quả | Penalty 48h + reset trạng thái match về WAITING | `DateBookingService.cancelBooking()` |
| Chat khi chưa có date confirmed | Lock chat → chỉ mở 4h trước giờ hẹn, 2h sau giờ hẹn | `DateBookingService.canChat()` |
| Backend trả DTO flat, Frontend đọc nested | Mapping DTO phẳng → object cho 5 files frontend | `BookingCard.jsx`, `FeedbackModal.jsx`, `MatchesList.jsx`, `GlobalMatchPopup.jsx`, `useAvailability.js` |
| React component crash | `ErrorBoundary` component bắt lỗi, hiển thị fallback thay vì blank page | `ErrorBoundary.jsx` |
| Backend exception chưa handle | `GlobalExceptionHandler` xử lý 7 loại exception tập trung | `GlobalExceptionHandler.java` |

### ✅ 8.6. Cải tiến Logic Match

| Cải tiến | So với yêu cầu cơ bản | Chi tiết kỹ thuật |
|---|---|---|
| 🎯 **Curated Feed 7/ngày** | Đề bài: "hiển thị tất cả profile" → Cải tiến: giới hạn 7 profiles/ngày (theo Breeze) | `DiscoveryService.getFeed()` đếm `countInteractionsToday()` |
| 🔀 **Random shuffle** | Đề bài: hiển thị danh sách → Cải tiến: shuffle ngẫu nhiên mỗi ngày để đa dạng | `Collections.shuffle(filteredUsers)` |
| 🎛️ **Filter system** | Đề bài: không yêu cầu → Cải tiến: lọc theo tuổi (min/max), giới tính, sở thích | Query params trên `GET /api/users/feed` |
| ⏭️ **Skip tracking** | Đề bài: chỉ cần "Like" → Cải tiến: lưu cả "Skip" để user đã skip không xuất hiện lại | `LikeService.processSkip()` tạo Like(type=SKIP) |
| ✅ **2-phase Confirmation** | Đề bài: tìm slot → xong → Cải tiến: PROPOSED → cả 2 Confirm → CONFIRMED mới chính thức | `DateBookingService.confirmBooking()` |
| ⏱️ **90-phút minimum** | Đề bài: tìm "slot trùng" → Cải tiến: yêu cầu slot ≥ 90 phút để đảm bảo chất lượng date | `if (minutes >= 90)` trong `findFirstCommonSlot()` |
| 🚫 **Anti-flaker penalty** | Đề bài: không yêu cầu → Cải tiến: hủy date → freeze tài khoản | `User.penalizedUntil` field + `DiscoveryService` check |
| 🌐 **Real-time sync** | Đề bài: không yêu cầu → Cải tiến: WebSocket push notification khi match, booking, chat | Spring WebSocket (STOMP + SockJS) |

---

## �📝 Ghi chú

- **AI đã được sử dụng** để hỗ trợ refactoring code, viết documentation, và debug — đúng như hướng dẫn của đề bài: *"AI là công cụ hỗ trợ bắt buộc trong môi trường làm việc tại Clique"*
- Dự án vượt qua scope yêu cầu cơ bản với các tính năng bổ sung: **real-time WebSocket**, **Google OAuth**, **photo upload**, **post-date feedback**, **chat window**, và **activity center**
- Code được tổ chức theo **Clean Code principles**: separation of concerns, custom hooks, reusable components, centralized constants

---

*Built with ❤️ for the Clique83 Web Developer Intern technical test*
