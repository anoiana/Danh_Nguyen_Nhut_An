# 🌊 Mini Dating — Mini Dating App Prototype

> Bài test kỹ thuật — Web Developer Intern @ Clique83.com (2026)

**Live Demo:** [dating-project-delta.vercel.app](https://dating-project-delta.vercel.app)  
**Backend API:** Hosted on [Render](https://render.com)  
**Stack:** React + Vite (Frontend) · Spring Boot + MySQL (Backend)

---

## 📖 Mục lục

1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Lưu trữ dữ liệu & Hạ tầng triển khai](#2-lưu-trữ-dữ-liệu--hạ-tầng-triển-khai)
3. [Logic Match hoạt động thế nào](#3-logic-match-hoạt-động-thế-nào)
4. [Logic tìm slot trùng hoạt động thế nào](#4-logic-tìm-slot-trùng-hoạt-động-thế-nào)
5. [Logic Nghiệp vụ & Product Mindset](#5-logic-nghiệp-vụ--product-mindset-cải-tiến-ngoài-đề-bài)
6. [Nếu có thêm thời gian, em sẽ cải thiện gì?](#6-nếu-có-thêm-thời-gian-em-sẽ-cải-thiện-gì-technical-polish)
7. [Đề xuất tính năng bổ sung](#7-đề-xuất-tính-năng-bổ-sung-strategic-vision)
8. [Các cải tiến và nỗ lực tối ưu thêm](#8-các-cải-tiến-và-nỗ-lực-tối-ưu-thêm)

---

## 1. Tổng quan hệ thống

Dự án được xây dựng dựa trên **yêu cầu bài test kỹ thuật** của Clique83 — bao gồm 3 phần chính: **Tạo Profile**, **Like/Match**, và **Đề xuất lịch hẹn** (tìm slot trùng trong 3 tuần tới). Đây là nền tảng cốt lõi của ứng dụng.

Ngoài các yêu cầu cơ bản, em đã chủ động phát triển thêm các tính mới nhằm mang lại trải nghiệm sát với sản phẩm thực tế:


### ✨ Những cải tiến thêm ngoài đề bài

Để tạo ra một sản phẩm hoàn thiện và có giá trị thực tế, em đã mở rộng bài test với các **tính năng sản phẩm mới**:

*   **🎯 Giới hạn 7 hồ sơ mỗi ngày (Curated Feed):** Thay vì cho phép quẹt vô tận gây loãng, hệ thống chỉ gửi đúng 7 người phù hợp nhất mỗi ngày. Điều này giúp bạn tập trung đọc kỹ bio, trân trọng mỗi lượt Like và tăng tỷ lệ Match "thật" hơn.
*   **📍 Tự động đề xuất địa điểm (Smart Venue):** Sau khi tìm được slot thời gian trùng nhau, hệ thống tự động tìm quán cafe đối tác nằm ở **điểm giữa (midpoint)** vị trí của hai người. Không ai phải đi quá xa, buổi hẹn bắt đầu một cách công bằng và thuận tiện nhất.
*   **💳 Cam kết bằng tài chính (VNPay Commitment):** Để loại bỏ tình trạng "leo cây" (no-show), dự án tích hợp thanh toán thực tế. Việc trả một khoản phí nhỏ là lời cam kết nghiêm túc: *"Tôi trân trọng thời gian của bạn và tôi chắc chắn sẽ đến"*.
*   **💬 Trò chuyện sát giờ G (Timed Chat):** Loại bỏ việc nhắn tin suông không hồi kết (chat fatigue). Cửa sổ chat chỉ mở khóa 4 tiếng trước giờ hẹn để cả hai chào hỏi và xác nhận nhanh trước khi gặp mặt trực tiếp.
*   **💌 Phản hồi & Trao đổi thông tin (Post-date Feedback):** Sau buổi hẹn, bạn sẽ quay lại app để đánh giá. Chỉ khi **CẢ HAI** cùng xác nhận muốn tiến xa hơn thì hệ thống mới tiết lộ Email liên lạc, đảm bảo quyền riêng tư và sự an toàn tuyệt đối.
*   **🚀 Trải nghiệm Onboarding mượt mà:** Quy trình 4 bước chuyên nghiệp giúp thiết lập profile nhanh chóng nhưng vẫn đầy đủ thông tin, đảm bảo chất lượng người dùng ngay từ đầu.
*   **🔔 Trung tâm hoạt động (Activity Center):** Theo dõi mọi biến động từ lúc Match, chọn lịch, cho đến khi thanh toán và nhận vé hẹn hò (E-ticket) một cách trực quan nhất.
*   **🔐 Xác thực bằng Google (OAuth 2.0):** Hỗ trợ đăng nhập nhanh bằng tài khoản Google, giúp rút ngắn quy trình đăng ký và tăng độ tin cậy về danh tính người dùng.

### Kiến trúc: Feature-Sliced N-Tier

Dự án được tổ chức theo **Feature-based Architecture** — mỗi tính năng được đóng gói riêng biệt với đầy đủ các layer, giúp dễ dàng mở rộng và bảo trì.

```
Dating-Project/
│
├── backend/                                    # ⚙️ Spring Boot 3 API Server
│   └── src/main/java/com/example/demo/
│       │
│       ├── features/                           # Tổ chức theo Feature Module
│       │   │
│       │   ├── auth/                           # 🔐 Xác thực
│       │   │   ├── controller/                 #    AuthController (Login, Register, Google OAuth)
│       │   │   └── dto/                        #    LoginRequest, RegisterRequest
│       │   │
│       │   ├── user/                           # 👤 Người dùng
│       │   │   ├── controller/                 #    UserController
│       │   │   ├── entity/                     #    User.java (Profile, GPS, Penalty)
│       │   │   ├── repository/                 #    UserRepository
│       │   │   ├── service/                    #    UserService, DiscoveryService (Feed 7/ngày)
│       │   │   └── dto/                        #    UserDto
│       │   │
│       │   ├── matching/                       # 💘 Ghép đôi
│       │   │   ├── controller/                 #    LikeController, MatchController
│       │   │   ├── entity/                     #    Like.java, Match.java
│       │   │   ├── repository/                 #    LikeRepository, MatchRepository
│       │   │   ├── service/                    #    LikeService, MatchService
│       │   │   └── dto/                        #    LikeRequest, MatchDto
│       │   │
│       │   ├── scheduling/                     # 📅 Lên lịch hẹn
│       │   │   ├── controller/                 #    AvailabilityController, BookingController, VenueController
│       │   │   ├── entity/                     #    Availability, DateBooking, Venue, Activity
│       │   │   ├── repository/                 #    AvailabilityRepo, BookingRepo, VenueRepo, ActivityRepo
│       │   │   ├── service/                    #    MatchingEngineService (Slot Overlap)
│       │   │   │                               #    DateBookingService (Confirm, Cancel, Feedback)
│       │   │   │                               #    VenueService (GPS Haversine Midpoint)
│       │   │   │                               #    ActivityService, NotificationService (WebSocket)
│       │   │   └── dto/                        #    DateBookingDto, SchedulingNotification, ...
│       │   │
│       │   ├── chat/                           # 💬 Chat thời gian thực
│       │   │   ├── controller/                 #    ChatController (WebSocket STOMP)
│       │   │   ├── entity/                     #    ChatMessage.java
│       │   │   ├── repository/                 #    ChatMessageRepository
│       │   │   └── dto/                        #    ChatMessageDto, ChatRequest
│       │   │
│       │   └── payment/                        # 💳 Thanh toán VNPay
│       │       ├── config/                     #    VNPayConfig (TMN Code, Hash Secret)
│       │       ├── controller/                 #    PaymentController (IPN Callback)
│       │       ├── entity/                     #    PaymentTransaction.java
│       │       ├── repository/                 #    PaymentRepository
│       │       ├── service/                    #    PaymentService (Create URL, Process IPN)
│       │       └── dto/                        #    PaymentRequest
│       │
│       └── infra/                              # 🏗️ Hạ tầng xuyên suốt
│           ├── config/                         #    CorsConfig, WebSocketConfig, VenueSeeder
│           ├── security/                       #    WebSecurityConfig, JwtUtils, AuthTokenFilter
│           │                                   #    UserDetailsImpl, UserDetailsServiceImpl
│           └── exception/                      #    GlobalExceptionHandler (7 loại Exception)
│                                               #    BusinessLogicException, BookingConflictException, ...
│
├── frontend/                                   # ⚛️ React 18 + Vite
│   └── src/
│       │
│       ├── features/                           # Tổ chức theo Feature Module
│       │   │
│       │   ├── auth/                           # 🔐 Xác thực & Hồ sơ
│       │   │   ├── api/                        #    authApi.js (Login, Register, Google OAuth)
│       │   │   ├── components/                 #    LoginForm, RegisterForm, OnboardingFlow,
│       │   │   │                               #    ProfileEditor, ProfileModal, AvatarUpload, ...
│       │   │   ├── context/                    #    AuthContext.jsx (JWT Token, User State)
│       │   │   └── hooks/                      #    useAuth.js, useProfileEditor.js
│       │   │
│       │   ├── matching/                       # 💘 Feed, Match & Chat
│       │   │   ├── api/                        #    matchApi.js (Like, Skip, Feed, Chat)
│       │   │   ├── components/                 #    MatchFeed, FeedCard, SkeletonCard,
│       │   │   │                               #    ChatWindow, MatchesList, ActivityCenter,
│       │   │   │                               #    FeedbackModal, ProfileDetailModal, ...
│       │   │   └── hooks/                      #    useFeed.js, useAvailability.js
│       │   │
│       │   ├── scheduling/                     # 📅 Lịch hẹn
│       │   │   ├── api/                        #    schedulingApi.js
│       │   │   ├── components/                 #    BookingCard.jsx (E-Ticket)
│       │   │   └── hooks/                      #    useAvailability.js (Slot validation)
│       │   │
│       │   └── payment/                        # 💳 Thanh toán
│       │       └── api/                        #    paymentApi.js (VNPay redirect)
│       │
│       ├── components/                         # 🧩 UI dùng chung
│       │   ├── common/                         #    LoadingSpinner, EmptyState, ErrorBoundary,
│       │   │                                   #    ConfirmModal, ModalOverlay
│       │   └── layout/                         #    Header, Footer, GlobalMatchPopup
│       │
│       ├── pages/                              # 📄 Trang chính
│       │   ├── HomePage.jsx                    #    Trang chủ (Tab Feed/Matches/Bookings/Activity)
│       │   ├── ProfileDetailsPage.jsx          #    Trang hồ sơ chi tiết
│       │   └── PaymentResult.jsx               #    Xử lý kết quả thanh toán VNPay
│       │
│       ├── hooks/                              #    useWebSocket.js (STOMP Client)
│       ├── context/                            #    LoadingContext, NotificationContext
│       └── lib/                                #    axios.js (Interceptor), constants.js
```

### Tech Stack

| Layer | Công nghệ | Chi tiết |
|-------|-----------|----------|
| **Frontend** | React 18 + Vite | Hook-based, SPA (Single Page Application) |
| **Backend** | Spring Boot 3 + Lombok | Java 17, Dependency Injection, Boilerplate-free |
| **Database** | MySQL 8 | JPA/Hibernate persistence |
| **Styling** | TailwindCSS 3 | Utility-first, **Glassmorphism Design**, Responsive |
| **Auth** | Google OAuth 2.0 + JWT | Đăng nhập một chạm, xác thực Token-based |
| **Messaging** | WebSocket (STOMP) | Real-time Chat & Thông báo tức thời |
| **Storage** | Cloudinary API | Tối ưu hóa & Lưu trữ hình ảnh đám mây |
| **Payment** | VNPay Sandbox | Tích hợp cổng thanh toán thực tế |
| **Testing** | JUnit 5 + Mockito | Viết test cho logic lõi |
| **Deploy** | Vercel + Render | Auto-deploy khi push code lên GitHub |

### Hành trình trải nghiệm người dùng (UX Guide)

Trước khi đi sâu vào logic kỹ thuật, hãy xem cách hoạt động của trang web:

1.  **Thiết lập Profile (Onboarding):** Sau khi đăng nhập bằng Google hoặc Email, bạn cần hoàn tất 4 bước "vỡ lòng": cung cấp thông tin cơ bản, chọn sở thích và **tải lên ít nhất 2 ảnh**. Hệ thống yêu cầu ảnh thật để đảm bảo chất lượng cộng đồng.
2.  **Cho phép truy cập vị trí:** Để hệ thống có thể đề xuất địa điểm hẹn hò "công bằng" nhất (nằm ở giữa hai người), bạn cần nhấn **Cho phép truy cập vị trí** khi trình duyệt yêu cầu. Nếu không, hệ thống sẽ chọn ngẫu nhiên các quán cafe đối tác.
3.  **Khám phá 7 người mỗi ngày (Curated Feed):** Không có việc quẹt vô tận. Mỗi ngày, **Mini Dating** chỉ gửi cho bạn đúng **7 bộ hồ sơ phù hợp nhất**. Bạn dành thời gian đọc kỹ bio của họ và chọn **Like (Thích)** hoặc **Skip (Bỏ qua)**. Nếu dùng hết 7 lượt, bạn cần đợi đến ngày mai.
4.  **Thông báo "It's a Match!":** Khi hai người cùng thích nhau, một popup gradient hiện ra báo hiệu bạn đã tìm thấy một nửa tiềm năng.
5.  **Lên kế hoạch hẹn gặp (Scheduling):** **Mini Dating** không khuyến khích nhắn tin suông. Thay vào đó, cả hai sẽ cùng chọn ra các khoảng thời gian rảnh trong **3 tuần tới** (ít nhất 3 khung giờ).
6.  **Hệ thống tự động sắp xếp:** Khi cả hai đã chọn lịch, **Mini Dating** sẽ tự động tìm slot chung (tối thiểu 90 phút) và tự chọn một **địa điểm (quán cafe/nhà hàng)** nằm ở chính giữa vị trí của cả hai để đảm bảo không ai phải đi quá xa.
7.  **Xác nhận qua VNPay:** Để đảm bảo buổi hẹn diễn ra nghiêm túc, cả hai cần thanh toán một khoản phí nhỏ (100k) qua cổng VNPay. Đây là lời cam kết: *"Tôi chắc chắn sẽ đến!"*.
8.  **Trò chuyện sát giờ G (Chat):** Cửa sổ chat chỉ mở khóa **4 tiếng trước giờ hẹn**. Điều này giúp cả hai có thể trao đổi ngắn gọn trước khi gặp mặt trực tiếp.
9.  **Gặp mặt & Phản hồi (Post-date):** Sau buổi hẹn, bạn quay lại app để xác nhận: *"Hôm nay bạn ấy có đến không?"* và *"Bạn có muốn trao đổi thông tin liên lạc không?"*. Nếu **CẢ HAI** cùng đồng ý, Email sẽ hiện ra để hai bạn tiếp tục hành trình bên ngoài ứng dụng.

---

### Luồng logic dự án (End-to-End Flow)

Toàn bộ hành trình người dùng trải qua **7 giai đoạn chính**, từ lúc đăng ký đến sau buổi hẹn:

```
==========================================================================
                  MINI DATING — LUONG LOGIC DU AN
==========================================================================

 [1] DANG KY / DANG NHAP
  |  Email + Password  --+
  |  Google OAuth 2.0  --+--> JWT Token --> Onboarding (4 buoc)
  |                                          |
  |                          Thong tin > So thich > Upload anh > Hoan tat
  |
  v
 [2] DISCOVERY FEED (7 profiles/ngay)
  |  DiscoveryService: filter + shuffle + quota (7/ngay)
  |  Kiem tra penalty -> Loai tru da tuong tac -> Filter tuoi/gioi/so thich
  |
  v
 [3] LIKE / SKIP -> MATCH
  |  Like --> LikeService.processLike()
  |            |-- Luu Like(A->B) vao DB
  |            |-- Reciprocity Check: B da Like A?
  |            |   |-- CHUA -> Cho (return false)
  |            |   +-- ROI -> MATCH!
  |            |          |-- MatchService.createMatch() (Symmetry Norm.)
  |            |          |-- Activity log cho ca 2
  |            |          +-- WebSocket push -> GlobalMatchPopup
  |  Skip --> Luu Like(type=SKIP) -> Khong xuat hien lai trong feed
  |
  v
 [4] CHON LICH -> TIM SLOT CHUNG & DIA DIEM
  |  Match status: WAITING_FOR_SCHEDULE
  |  User A chon >=3 slots (3 tuan toi) -> Submit Availability
  |  User B chon >=3 slots             -> Submit Availability
  |  Ca 2 da submit -> MatchingEngineService.executeMatching()
  |  |-- findFirstCommonSlot(): O(n*m) tim overlap >= 90 phut
  |  |-- TIM THAY -> TU DONG CHON DIA DIEM (GPS MIDPOINT)
  |  |      |-- Tinh diem giua (lat, lng) cua A va B
  |  |      |-- Dung Haversine tim venue gan nhat
  |  |      +-- Tao DateBooking(PROPOSED) + WebSocket Notify
  |  +-- KHONG TIM THAY -> Reset availability + Notify "Chon lai!"
  |
  v
 [5] XAC NHAN & THANH TOAN (VNPay)
  |  Booking status: PROPOSED -> Ca 2 can thanh toan
  |  PaymentService.createPaymentUrl() -> Redirect VNPay Sandbox
  |  VNPay IPN callback -> processIpn() -> confirmBooking()
  |  |-- User A paid -> requesterConfirmed = true
  |  |-- User B paid -> recipientConfirmed = true
  |  +-- CA 2 paid -> Status=CONFIRMED + Match status=SCHEDULED
  |
  v
 [6] NGAY HEN — CHAT WINDOW
  |  Chat chi mo: startTime - 4h -> startTime + 2h
  |  ChatController: check canChat() truoc moi message
  |  Real-time qua WebSocket (STOMP + SockJS)
  |  Neu user huy (CONFIRMED) -> Penalty 24h freeze tai khoan
  |
  v
 [7] SAU BUOI HEN — FEEDBACK & CONTACT EXCHANGE
     FeedbackModal: "Co den khong?" + "Muon lien lac tiep?"
     submitFeedback() kiem tra mutual interest:
     |-- CA 2 den + CA 2 muon lien lac -> contactExchanged = true
     |     -> Hien thi Email tren Date Ticket
     +-- Khong mutual -> Khong tiet lo (bao ve quyen rieng tu)

==========================================================================
```


---

## 2. Lưu trữ dữ liệu & Hạ tầng triển khai

### 📦 Lưu trữ: TiDB Cloud (MySQL Distributed)

Thay vì dùng Local Storage hay MySQL truyền thống, dự án sử dụng **TiDB Cloud** — một cơ sở dữ liệu phân tán mạnh mẽ, tương thích hoàn toàn với MySQL nhưng có khả năng mở rộng (scalability) và độ sẵn sàng cao vượt trội.

**Các bảng chính trong hệ thống:**

| Bảng | Mục đích | Các cột quan trọng |
| :--- | :--- | :--- |
| `users` | Hồ sơ người dùng | id, name, age, gender, email, password, avatar_url, photos, interests |
| `likes` | Lưu Like/Skip giữa 2 users | id, from_user_id, to_user_id, type (LIKE/SKIP), created_at |
| `matches` | Lưu trạng thái match | id, user1_id, user2_id, status (WAITING/PROPOSED/SCHEDULED) |
| `availabilities` | Thời gian rảnh của user | id, user_id, start_time, end_time |
| `venues` | Danh sách quán cafe đối tác | id, name, address, latitude, longitude, image_url |
| `date_bookings` | Lịch hẹn (đã có slot & venue) | id, requester_id, recipient_id, venue_id, status |
| `payment_transactions` | Lịch sử thanh toán VNPay | id, booking_id, user_id, amount, status (SUCCESS/FAILED) |
| `chat_messages` | Tin nhắn thời gian thực | id, match_id, sender_id, content, timestamp |
| `activities` | Thông báo (Notify center) | id, user_id, content, type (MATCH/PAYMENT), is_read |

### 🚀 Hạ tầng triển khai (Cloud Deployment)

Hệ thống được thiết kế theo kiến trúc hiện đại, sẵn sàng cho người dùng thực tế trải nghiệm:

*   **Backend (Render):** Server Spring Boot được triển khai trên **Render**, tự động deploy khi push code lên GitHub.
*   **Database (TiDB Cloud):** Dữ liệu được lưu trữ an toàn trên nền tảng Cloud của TiDB.
*   **Security:** Toàn bộ thông tin nhạy cảm (JWT Secret, DB Credentials, API Keys) được quản lý qua **Environment Variables** trực tiếp trên Render, không bao giờ lộ code.
*   **Frontend (Vercel):** Ứng dụng React/Vite được tối ưu hóa và deploy trên **Vercel** để đạt tốc độ tải trang nhanh nhất toàn cầu nhờ hệ thống CDN.

---

## 3. Logic Match hoạt động thế nào

**Trả lời yêu cầu đề bài:** Logic Match dựa trên nguyên tắc **Thích lẫn nhau (Mutual Interaction)** và được xử lý real-time thông qua hệ thống WebSocket.

Hệ thống Matching được thiết kế để đảm bảo tính **tức thời** và **không trùng lặp**, mang lại trải nghiệm hào hứng cho người dùng ngay khi có tương tác chéo.

### 🔄 Quy trình (Workflow)

```text
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

### 🛠️ Giải thuật: Mutual Matching Logic

Để đảm bảo hệ thống vận hành trơn tru và chính xác, em đã triển khai 4 cơ chế quan trọng:

#### 1. Kiểm tra đối xứng (Reciprocity Check)
Hệ thống không chỉ lưu hành động "Like" mà ngay lập tức thực hiện một câu truy vấn ngược để kiểm tra xem User B đã có hành động tương tự với User A trước đó chưa. 
*   **Lợi ích:** Phát hiện Match ngay tại thời điểm User cuối cùng nhấn Like, giúp tiết kiệm tài nguyên database.

#### 2. Chuẩn hóa đối xứng (Symmetry Normalization) 🛡️
Đây là kỹ thuật quan trọng nhất để chống trùng lặp dữ liệu. Trong `MatchService`, em luôn so sánh ID của 2 người dùng và lưu ID nhỏ hơn vào cột `user1`, ID lớn hơn vào `user2`.
*   **Lợi ích:** Đảm bảo dù A like B hay B like A, database cũng chỉ tồn tại **duy nhất 1 bản ghi** Match cho cặp đôi đó.

#### 3. Bắt tay thời gian thực (WebSocket Handshaking) ⚡
Ngay khi có match, Backend gửi tín hiệu WebSocket tới cả 2 users.
*   **Lợi ích:** Người dùng nhận được popup **"It's a Match!"** ngay lập tức, tạo hiệu ứng tâm lý hào hứng.

#### 4. Nhật ký hoạt động (Activity Logging)
Mỗi sự kiện Match được tự động ghi lại vào bảng `activities` để người dùng theo dõi trong Trung tâm thông báo.

### 📖 Chi tiết triển khai (Source Code)

Hệ thống sử dụng sự phối hợp giữa `LikeService` và `MatchService` để xử lý logic:

```java
// LikeService.java - Xử lý Like và phát hiện Match
@Transactional
public boolean processLike(Long fromUserId, Long toUserId) {
    User fromUser = userService.findById(fromUserId).orElseThrow(...);
    User toUser = userService.findById(toUserId).orElseThrow(...);

    // 1. Lưu Like record để theo dõi lịch sử
    if (!likeRepository.existsByFromUserAndToUser(fromUser, toUser)) {
        Like like = new Like(fromUser, toUser, Like.Type.LIKE);
        likeRepository.save(like);
    }

    // 2. Kiểm tra tính đối xứng (Reciprocity Check)
    boolean isMutual = likeRepository.existsByFromUserAndToUserAndType(toUser, fromUser, Like.Type.LIKE);

    if (isMutual) {
        // 3. Tạo Match chính thức
        matchService.createMatch(fromUser, toUser);

        // 4. Thông báo Real-time qua WebSocket & Activity Log
        activityService.logActivity(fromUser, "You and " + toUser.getName() + " have matched! 💖", "MATCH");
        notificationService.broadcastMatchUpdate(fromUser.getId(), Map.of("type", "MATCH"));
        
        return true;
    }
    return false;
}

// MatchService.java - Chuẩn hóa ID để chống trùng lặp record
@Transactional
public Match createMatch(User u1, User u2) {
    User user1; User user2;

    // Symmetry Normalization: Luôn lưu ID nhỏ hơn vào 'user1'.
    // Đảm bảo dù A like B hay B like A, DB cũng chỉ có duy nhất 1 hàng dữ liệu.
    if (u1.getId() < u2.getId()) {
        user1 = u1; user2 = u2;
    } else {
        user1 = u2; user2 = u1;
    }

    Match match = new Match();
    match.setUser1(user1);
    match.setUser2(user2);
    return matchRepository.save(match);
}
```

### 📍 Ví dụ minh họa (Concrete Example)

1. **User 10** nhấn Like **User 25**. Hệ thống lưu `Like(10->25)`. Kiểm tra `Like(25->10)` -> Không thấy.
2. **User 25** nhấn Like **User 10**. Hệ thống lưu `Like(25->10)`. Kiểm tra `Like(10->25)` -> **Tìm thấy!**
3. `MatchService` tạo bản ghi: `user1=10, user2=25` (do 10 < 25).
4. Cả hai nhận được thông báo "Matched!" trên màn hình.

### ✅ Các Case đã xử lý (Edge Cases)
- **Self-like Protection:** Chặn tuyệt đối việc user tự like chính mình.
- **Duplicate Prevention:** Không lưu trùng bản ghi Like nếu nhấn nhiều lần.
- **Skip Logic:** Khi đã Skip, hồ sơ đó vĩnh viễn không xuất hiện lại trong feed.

---

## 4. Logic tìm slot trùng hoạt động thế nào

**Trả lời yêu cầu đề bài:** Sử dụng thuật toán **Symmetry Slot Overlap** để tìm khoảng thời gian chung đầu tiên ≥ 90 phút trong 3 tuần tiếp theo.

### 🔄 Quy trình (Workflow)

```text
A & B đã match 
      │
      ▼
Cả 2 cùng gửi Availability (≥ 3 slots rảnh)
      │
      ▼
┌────────────────────────────────────────┐
│      MatchingEngineService             │
│  1. Sắp xếp slots theo thời gian       │
│  2. Duyệt chéo tìm điểm giao (Overlap) │
│  3. Áp dụng quy tắc "Dating >= 90 min" │
│  4. Kiểm tra Anti-Double-Booking       │
│     │                                  │
│     ├─ CÓ SLOT → Tạo Date (PROPOSED)   │
│     │   + Tự động chọn địa điểm GPS    │
│     │                                  │
│     └─ KHÔNG → Reset & "Chọn lại!"     │
└────────────────────────────────────────┘
```

### 🛠️ Giải thuật: Earliest Overlap Discovery

Để tìm kiếm slot hẹn hò tối ưu ngay khi cả hai người dùng trong một Match cùng hoàn tất việc gửi danh sách thời gian rảnh, em đã triển khai các tiêu chí sau:

#### 1. Nguyên lý Overlap (Giao thoa thời gian)
Hệ thống sử dụng công thức toán học để xác định khoảng thời gian chung:
*   `maxStart = max(start_A, start_B)`
*   `minEnd = min(end_A, end_B)`
*   **Điều kiện:** Nếu `maxStart < minEnd`, hai khung giờ có sự giao thoa thực sự.

#### 2. Quy tắc 90 phút (Quality Dating Rule) ⏳
Để đảm bảo chất lượng cho buổi hẹn, thuật toán chỉ chấp nhận các khoảng overlap có độ dài **tối thiểu 90 phút**.

#### 3. Chống trùng lịch (Anti Double-Booking) 🛡️
Hệ thống thực hiện truy vấn ngược vào bảng `date_bookings` để đảm bảo User không bị kẹt một buổi hẹn nào khác trong khung giờ dự kiến.

#### 4. Độ phức tạp và Hiệu năng
Duyệt lồng cặp với độ phức tạp `O(n x m)`. Với số lượng slot dưới 10, thời gian xử lý cực nhanh (vài ms).

### 📖 Chi tiết triển khai (Source Code)

Hệ thống sử dụng `MatchingEngineService` để thực hiện thuật toán so khớp thời gian:

```java
/**
 * Tìm khung giờ chung (overlap) đầu tiên giữa 2 người dùng.
 */
public Availability findFirstCommonSlot(Long user1Id, Long user2Id) {
    List<Availability> list1 = availabilityRepository.findByUser(u1);
    List<Availability> list2 = availabilityRepository.findByUser(u2);

    // Sorting để đảm bảo tìm thấy slot sớm nhất (Earliest)
    list1.sort((a, b) -> a.getStartTime().compareTo(b.getStartTime()));
    list2.sort((a, b) -> a.getStartTime().compareTo(b.getStartTime()));

    for (Availability a : list1) {
        for (Availability b : list2) {
            // Ràng buộc 1: Phải cùng ngày
            if (!a.getStartTime().toLocalDate().equals(b.getStartTime().toLocalDate())) continue;

            // Ràng buộc 2: Tìm điểm giao thoa (Overlap)
            LocalDateTime maxStart = a.getStartTime().isAfter(b.getStartTime()) ? a.getStartTime() : b.getStartTime();
            LocalDateTime minEnd = a.getEndTime().isBefore(b.getEndTime()) ? a.getEndTime() : b.getEndTime();

            if (maxStart.isBefore(minEnd)) {
                long minutes = java.time.Duration.between(maxStart, minEnd).toMinutes();

                // Ràng buộc 3: Quy tắc 90 phút chất lượng
                if (minutes >= 90) {
                    // Ràng buộc 4: Anti Double-Booking (Check trùng lịch cũ)
                    if (dateBookingRepository.findOverlappingBookings(user1Id, maxStart, minEnd).isEmpty() &&
                        dateBookingRepository.findOverlappingBookings(user2Id, maxStart, minEnd).isEmpty()) {
                        
                        return new Availability(maxStart, minEnd); // ✅ FOUND!
                    }
                }
            }
        }
    }
    return null; // ❌ FAILURE
}
```

### 📍 Ví dụ minh họa (Concrete Example)

*   **User A:** 25/02, 09:00 → 17:00
*   **User B:** 25/02, 14:30 → 21:00
*   **Xử lý:** `maxStart = 14:30`, `minEnd = 17:00`. Duration = 150 phút (≥ 90p).
*   **Kết quả:** Chốt lịch hẹn lúc **14:30 ngày 25/02**.

### ✅ Các Case đã xử lý (Edge Cases)
- **Matching Failed:** Nếu không tìm được slot trùng, hệ thống tự động xóa Availability của cả hai và gửi thông báo yêu cầu chọn lại qua WebSocket.
- **Symmetry Priority:** Luôn ưu tiên slot sớm nhất trong danh sách đã được sắp xếp.

---

## 5. Logic Nghiệp vụ & Product Mindset (Cải tiến ngoài đề bài)

Ngoài các yêu cầu kỹ thuật cơ bản, em đã chủ động thiết kế và triển khai 6 cơ chế nghiệp vụ chuyên sâu. Điều này thể hiện tư duy **Product-Oriented** — không chỉ viết code đúng mà còn phải giải quyết bài toán thực tế của một nền tảng hẹn hò chuyên nghiệp.

---

### 🌟 5.1. Scarcity & Curated Feed (Hạn ngạch hồ sơ)

Hệ thống áp dụng mô hình của Breeze — giới hạn số lượng hồ sơ để tăng tính tập trung và giá trị cho mỗi lượt tương tác.

#### 🔄 Quy trình (Workflow)
```text
User yêu cầu Discovery Feed
          │
          ▼
┌────────────────────────────────┐
│   DiscoveryService.getFeed()   │
│ 1. Đếm Like/Skip trong ngày    │
│ 2. quota = Max(0, 7 - count)   │
│ 3. Filter & Shuffle hồ sơ      │
└────────────────────────────────┘
          │
          ▼
   Trả về tối đa 7 profile
```

#### 🛠️ Giải thuật: Daily Quota Logic
Hệ thống không cho phép quẹt vô tận. Bằng cách giới hạn 7 người mỗi ngày, chúng ta buộc người dùng phải đọc kỹ Bio, xem kỹ ảnh, từ đó tăng tỷ lệ Match "chất lượng" thay vì quẹt vô thức (Tinder Burnout).

#### 📖 Chi tiết triển khai (`DiscoveryService.java`)
```java
public List<UserDto> getFeed(Long currentUserId) {
    // 1. Check Penalty (Xem mục 5.2)
    checkPenalty(currentUser);

    // 2. Tính hạn ngạch còn lại trong ngày (Max 7)
    long interactionsToday = likeRepository.countInteractionsToday(currentUserId, LocalDate.now().atStartOfDay());
    int quotaRemaining = (int) Math.max(0, 7 - interactionsToday);

    if (quotaRemaining <= 0) return Collections.emptyList();

    // 3. Filter & Shuffle kết quả
    return allUsers.stream()
            .filter(...) // Chưa từng tương tác, đúng tiêu chí
            .limit(quotaRemaining)
            .collect(Collectors.toList());
}
```

#### 📍 Ví dụ minh họa
- **Sáng:** User đã quẹt 3 người.
- **Chiều:** User vào lại app -> `quotaRemaining = 4`. Hệ thống chỉ hiện thêm 4 hồ sơ mới.
- **Tối:** Đã quẹt hết 7 người -> Feed trống, yêu cầu đợi đến ngày mai.

#### ✅ Các Case đã xử lý
- **Reset Day:** Hạn ngạch tự động reset vào 00:00 mỗi ngày.
- **Empty Pool:** Nếu hết người phù hợp trong hệ thống, trả về danh sách trống kèm thông báo.

---

### ⚠️ 5.2. Anti-Flaker Penalty (Chống bùng hẹn)

Cơ chế trừng phạt nhằm xây dựng văn hóa cam kết và tôn trọng thời gian của đối phương.

#### 🔄 Quy trình (Workflow)
```text
User hủy lịch (CONFIRMED)
          │
          ▼
┌────────────────────────────────┐
│ DateBookingService.cancel()    │
│ 1. Kiểm tra status == CONFIRMED│
│ 2. penalizedUntil = Now + 24h  │
│ 3. Log Activity & Notify       │
└────────────────────────────────┘
          │
          ▼
   Tài khoản bị khóa Feed 24h
```

#### 🛠️ Giải thuật: Penalty Enforcement
Việc hủy một buổi hẹn đã xác nhận (đã trả tiền và chốt lịch) gây ảnh hưởng rất xấu đến trải nghiệm người dùng khác. Hệ thống sẽ "đóng băng" tính năng quẹt (Discovery) của họ trong vòng 24 giờ.

#### 📖 Chi tiết triển khai (`DateBookingService.java`)
```java
@Transactional
public void cancelBooking(Long bookingId, Long cancellingUserId) {
    if ("CONFIRMED".equals(booking.getStatus())) {
        User user = userService.findById(cancellingUserId);
        
        // Phạt: Treo máy 24 giờ kể từ thời điểm hủy
        user.setPenalizedUntil(LocalDateTime.now().plusDays(1));
        userService.save(user);
        
        activityService.logActivity(user, "Bạn bị cấm quẹt 24h do hủy lịch đã xác nhận! ⚠️", "PENALTY");
    }
}
```

#### 📍 Ví dụ minh họa
- User A hủy lịch lúc 10:00 AM Thứ Hai.
- Hệ thống đặt `penalizedUntil` là 10:00 AM Thứ Ba.
- Trong khoảng thời gian này, User A vào trang Feed sẽ nhận thông báo: "Bạn đang bị hạn chế do vi phạm cam kết hẹn hò".

#### ✅ Các Case đã xử lý
- **Hủy sớm:** Nếu lịch chưa CONFIRMED (vẫn đang PROPOSED), việc hủy không bị tính penalty.
- **Hết hạn phạt:** Sau 24h, hệ thống tự động mở lại quyền truy cập Feed.

---

### 💬 5.3. Chat Unlock Logic (Chat sát giờ G)

Loại bỏ việc nhắn tin suông (Chat Fatigue) bằng cách chỉ mở Chat khi buổi hẹn gần diễn ra.

#### 🔄 Quy trình (Workflow)
```text
Sự kiện gửi tin nhắn / Mở Chat
          │
          ▼
┌────────────────────────────────┐
│ DateBookingService.canChat()   │
│ 1. Lấy lịch CONFIRMED gần nhất │
│ 2. Check: Start - 4h < Now     │
│ 3. Check: Now < Start + 2h     │
└────────────────────────────────┘
          │
          ▼
     Cho phép / Chặn Chat
```

#### 🛠️ Giải thuật: Strategic Windowing
Thay vì để người dùng chat hàng tuần trời rồi không gặp mặt, hệ thống chỉ mở chat 4 tiếng trước giờ hẹn. Mục đích là để xác nhận trang phục, vị trí ngồi hoặc thông báo đến muộn.

#### 📖 Chi tiết triển khai (`DateBookingService.java`)
```java
public boolean canChat(Long u1Id, Long u2Id) {
    DateBooking booking = getConfirmedBookingBetweenUsers(u1Id, u2Id);
    if (booking == null || !"CONFIRMED".equals(booking.getStatus())) return false;

    LocalDateTime now = LocalDateTime.now();
    LocalDateTime startTime = booking.getStartTime();
    
    // Window: [Start - 4h] < Now < [Start + 2h]
    return now.isAfter(startTime.minusHours(4)) && now.isBefore(startTime.plusHours(2));
}
```

#### � Ví dụ minh họa
- Buổi hẹn diễn ra lúc **19:00**.
- **15:00:** Cửa sổ chat mở khóa -> "Chào bạn, mình mặc áo màu xanh nhé".
- **21:00:** Buổi hẹn kết thúc 2 tiếng -> Chat tự động khóa để bảo mật sự riêng tư.

#### ✅ Các Case đã xử lý
- **Chưa thanh toán:** Nếu chưa CONFIRMED, nút Chat sẽ bị ẩn hoàn toàn.
- **WebSocket Security:** Backend kiểm tra quyền chat trên từng message, không chỉ ở UI.

---

### 📱 5.4. Mutual Contact Disclosure (Tiết lộ Email đối xứng)

Bảo vệ thông tin cá nhân bằng cơ chế Post-date Feedback.

#### 🔄 Quy trình (Workflow)
```text
Cả hai User gửi Feedback
          │
          ▼
┌────────────────────────────────┐
│  DateBookingService.feedback() │
│ 1. Lưu Feedback từng người     │
│ 2. Check: Cả 2 cùng đi hẹn?    │
│ 3. Check: Cả 2 cùng muốn quen? │
└────────────────────────────────┘
          │
          ▼
   Tiết lộ Email trên E-Ticket
```

#### 🛠️ Giải thuật: Privacy-First Feedback
Hệ thống chỉ hiện thông tin liên hệ (Email) nếu và chỉ nếu:
1. Cả hai cùng xác nhận đã đến buổi hẹn (Attended).
2. Cả hai cùng nhấn "Muốn tiếp tục liên lạc" (Wants Contact).

#### 📖 Chi tiết triển khai (`DateBookingService.java`)
```java
@Transactional
public DateBookingDto submitFeedback(Long bookingId, Long userId, boolean attended, boolean wantsContact) {
    // Lưu feedback cá nhân...
    
    // Kiểm tra tính đối xứng (Reciprocity)
    boolean bothAttended = booking.getRequesterAttended() && booking.getRecipientAttended();
    boolean bothWantContact = booking.getRequesterWantsContact() && booking.getRecipientWantsContact();

    if (bothAttended && bothWantContact) {
        booking.setContactExchanged(true); // TRIGGER: Hiện thông tin liên hệ
    }
}
```

#### 📍 Ví dụ minh họa
- User A nhấn "Thích" sau date. User B nhấn "Không thích".
- **Kết quả:** Không ai thấy Email của ai. User A không bị B làm phiền sau đó.
- Nếu cả hai cùng nhấn "Thích" -> Email của B hiện trên app của A và ngược lại.

#### ✅ Các Case đã xử lý
- **Chưa đi hẹn:** Nếu một bên confirm "Không đến", logic Wants Contact sẽ bị vô hiệu hóa.

---

### 💳 5.5. Payment-First Commitment (Thanh toán xác thực)

Tích hợp VNPay làm bộ lọc cho sự nghiêm túc của người dùng.

#### 🔄 Quy trình (Workflow)
```text
User muốn chốt lịch hẹn
          │
          ▼
┌────────────────────────────────┐
│  PaymentService (VNPay)        │
│ 1. Tạo GD & Link VNPay         │
│ 2. Đợi IPN từ Ngân hàng        │
│ 3. confirmBooking() thành công │
└────────────────────────────────┘
          │
          ▼
    Lịch hẹn trạng thái CONFIRMED
```

#### 🛠️ Giải thuật: Financial Commitment
Dự án sử dụng VNPay Sandbox để mô phỏng quy trình thanh toán thực tế. Buổi hẹn chỉ chuyển từ trạng thái `PROPOSED` sang `CONFIRMED` khi hệ thống nhận được tín hiệu thanh toán thành công từ Gateway.

#### 📖 Chi tiết triển khai (`PaymentService.java`)
```java
@Transactional
public String processIpn(Map<String, String> params) {
    if ("00".equals(params.get("vnp_ResponseCode"))) {
        PaymentTransaction txn = findByRef(params.get("vnp_TxnRef"));
        txn.setStatus("SUCCESS");
        
        // Khi thanh toán thành công, chính thức khóa lịch hẹn
        dateBookingService.confirmBooking(txn.getBooking().getId(), txn.getUser().getId());
    }
}
```

#### 📍 Ví dụ minh họa
- User A chọn 3 slot rảnh. User B chọn 3 slot.
- Hệ thống báo: "Tìm thấy slot chung tại Phúc Long Q4. Vui lòng thanh toán để xác nhận".
- Một người trả nhưng người kia chưa trả -> Status vẫn là `PENDING`. Cả hai cùng trả -> `CONFIRMED`.

#### ✅ Các Case đã xử lý
- **Hủy giao dịch:** Nếu user thoát giữa chừng, transaction vẫn ở trạng thái `PENDING`, nút thanh toán vẫn khả dụng để thử lại.

---

### 📍 5.6. Smart Venue Selection (Địa điểm công bằng)

Tối ưu hóa điểm gặp mặt dựa trên tọa độ GPS thực tế.

#### 🔄 Quy trình (Workflow)
```text
Lịch hẹn tìm được Slot chung
          │
          ▼
┌────────────────────────────────┐
│   VenueService.findBest()      │
│ 1. Tính Midpoint(A, B)         │
│ 2. Tính Haversine Mid-to-Venue │
│ 3. Chọn quán gần Midpoint nhất │
└────────────────────────────────┘
          │
          ▼
    Gán địa điểm vào DateBooking
```

#### 🛠️ Giải thuật: GPS-Based Fairness
Hệ thống tính điểm trung gian giữa hai tọa độ. Sau đó sử dụng công thức **Haversine** (tính khoảng cách trên mặt cầu) để tìm quán Cafe đối tác nằm gần điểm trung gian đó nhất, đảm bảo quãng đường di chuyển của hai người là tương đương.

#### 📖 Chi tiết triển khai (`VenueService.java`)
```java
public Venue findBestVenue(User u1, User u2) {
    // 1. Tính Midpoint
    double midLat = (u1.getLatitude() + u2.getLatitude()) / 2;
    double midLng = (u1.getLongitude() + u2.getLongitude()) / 2;

    // 2. Tìm Venue có khoảng cách Haversine nhỏ nhất tới Midpoint
    return venues.stream()
            .min(Comparator.comparingDouble(v -> 
                haversine(midLat, midLng, v.getLatitude(), v.getLongitude())))
            .orElse(venues.get(0));
}
```

#### 📍 Ví dụ minh họa
- **User A:** Quận 1. **User B:** Quận 7.
- **Midpoint:** Quận 4.
- **Hệ thống:** Tự động chọn Cafe tại Quận 4 thay vì một quán ở Q1 (khiến B đi xa) hoặc Q7 (khiến A đi xa).

#### ✅ Các Case đã xử lý
- **Fallback:** Nếu một trong hai không bật GPS, hệ thống sẽ chọn ngẫu nhiên một địa điểm hot trong danh sách đối tác.

---

## 6. Nếu có thêm thời gian, em sẽ cải thiện gì? (Technical Polish)

Dự án hiện tại đã hoàn thiện về mặt logic, nhưng để đạt chuẩn **Production Ready**, em sẽ tập trung vào các khía cạnh kỹ thuật chuyên sâu sau:

### ⚡ 7.1. Kiến trúc & Hiệu năng (Infrastructure & Scaling)
- **Caching (Redis):** Sử dụng Redis lưu trữ Discovery Feed (7 hồ sơ/ngày) của từng user. Thay vì query DB liên tục, hệ thống lấy từ cache giúp tốc độ phản hồi API đạt dưới 50ms.
- **Message Queue (RabbitMQ/Kafka):** Tách việc gửi Email và Notification ra khỏi luồng xử lý chính để tránh blocking thread, giúp app mượt mà hơn khi scale.
- **Database Indexing:** Tối ưu hóa Index cho các bảng `matches`, `date_bookings` và `availabilities` để xử lý hàng triệu bản ghi mà không bị chậm.

### 🎨 7.2. Trải nghiệm người dùng nâng cao (UX/UI Polish)
- **Mobile Native Feel:** Thêm hiệu ứng Swipe (vuốt trái/phải) mượt mà cho thẻ profile trên mobile thay vì chỉ nhấn nút, tạo ra trải nghiệm "quẹt" tự nhiên.
- **Skeleton Loading:** Áp dụng Skeleton hoàn chỉnh cho toàn bộ trang để giảm cảm giác "chờ đợi" (perceived performance) khi load ảnh từ Cloudinary.
- **Dark Mode:** Hệ thống tự động chuyển theme hoặc có nút toggle để bảo vệ mắt người dùng ban đêm.

### 🔒 7.3. Bảo mật & Tin cậy (Security hardening)
- **Rate Limiting:** Chặn hành vi spam Like (quẹt quá nhanh bằng tool) bằng cách giới hạn số request/phút trên mỗi tài khoản.
- **Input Sanitization:** Kiểm soát chặt chẽ Bio, Interests để chống tấn công XSS hoặc SQL Injection.
- **Advanced Identity Verification:** Tích hợp AI nhận diện khuôn mặt trong ảnh upload, đảm bảo user không sử dụng ảnh giả mạo hoặc ảnh mạng.

### 📱 7.4. Mở rộng đa nền tảng (Cross-platform)
- **Mobile App Version:** Hiện tại dự án đang chạy trên Web (React). Tôi hoàn toàn có thể xây dựng thêm **phiên bản Mobile App hoàn chỉnh** bằng React Native hoặc Flutter để người dùng nhận thông báo đẩy tức thì.

---

## 7. Đề xuất tính năng bổ sung (Strategic Vision)

Để đưa dự án từ một bản Prototype lên tầm vóc một sản phẩm thương mại có khả năng tăng trưởng (Scale-up), em đề xuất 3 nhóm tính năng chiến lược nhằm giải quyết triệt để bài toán **Vận hành**, **Doanh thu** và **Trải nghiệm**:

### 🏢 7.1. Hệ sinh thái Vận hành & Đối tác (B2B Operations)

Mục tiêu là biến ứng dụng thành một nền tảng trung gian kết nối người dùng với các dịch vụ vui chơi, giải trí.

*   **Hệ thống Quản trị thông minh (Admin Business Intelligence):**
    *   **Mô tả:** Xây dựng Dashboard phân tích dữ liệu thực tế: tỷ lệ Match theo khu vực, khung giờ vàng của các buổi hẹn, và phễu chuyển đổi từ *Swiping -> Matching -> Booking*.
    *   **Giá trị:** Giúp người vận hành hiểu rõ hành vi người dùng để điều chỉnh thuật toán gợi ý hồ sơ hiệu quả hơn.
*   **Cổng thông tin đối tác tự động (B2B Venue Portal):**
    *   **Mô tả:** Cung cấp tài khoản riêng cho các quán cafe/nhà hàng đối tác để họ chủ động cập nhật menu, chương trình khuyến mãi riêng và quản lý lượng bàn trống theo thời gian thực (Inventory Management).
    *   **Giá trị:** Giảm bớt gánh nặng quản lý cho team vận hành App và tạo ra sự chủ động cho đối tác.
*   **Hệ thống QR Ticket & Check-in Ecosystem:**
    *   **Mô tả:** Khi cặp đôi đến quán, họ quét mã QR tại bàn. Hệ thống tự động xác nhận buổi hẹn diễn ra thành công (Attended).
    *   **Giá trị:** Giải quyết bài toán "xác thực sự hiện diện" một cách khách quan, làm căn cứ để hoàn tiền cam kết (Deposit refund) hoặc cộng điểm thưởng.

### 🎁 7.2. Cơ chế Gắn kết & Loyalty (Loyalty Engineering)

Sử dụng tâm lý học hành vi (Behavioral Economics) để giữ chân người dùng và tạo ra môi trường hẹn hò văn minh.

*   **Hệ thống tín nhiệm "Dating Reputation Score":**
    *   **Mô tả:** Mỗi người dùng có một điểm uy tín ẩn/hiện. Điểm này tăng khi đi hẹn đúng giờ, được đối phương feedback tốt, và giảm mạnh khi bùng hẹn (Ghosting) sau khi đã CONFIRMED.
    *   **Giá trị:** Xây dựng cộng đồng "High-quality", loại bỏ các tài khoản ảo hoặc thiếu nghiêm túc, tạo niềm tin tuyệt đối cho người dùng mới.
*   **Date Voucher & Reward Marketplace:**
    *   **Mô tả:** Tích hợp một "chợ" Voucher. Người dùng có thể dùng điểm tích lũy từ các buổi hẹn trước để đổi lấy các gói giảm giá 20-50% tại các địa điểm hạng sang.
    *   **Giá trị:** Kích thích người dùng tích cực đi hẹn (Retetion rate) và tạo ra nguồn doanh thu phụ thu (Commission) từ các nhãn hàng F&B.

### 🤖 7.3. Công nghệ AI & Cá nhân hóa (Personalization)

Ứng dụng công nghệ để giải quyết bài toán "Hợp nhau" một cách khoa học thay vì may rủi.

*   **AI Compatibility Scoring (Dựa trên NLP):**
    *   **Mô tả:** Sử dụng xử lý ngôn ngữ tự nhiên (NLP) để phân tích sự tương quan giữa Bio của 2 người, các sở thích ngách (Niche interests) và lịch sử tương tác của họ.
    *   **Giá trị:** Hiển thị chỉ số "Hợp nhau 85%" giúp người dùng có thêm động lực để bắt đầu một mối quan hệ mới.
*   **Smart Scheduling AI (Dự đoán khung giờ rảnh):**
    *   **Mô tả:** Dựa trên lịch sử submit Availability trong quá khứ, AI tự động gợi ý các khung giờ mà cả hai người có khả năng cao là sẽ rảnh.
    *   **Giá trị:** Giảm bớt số bước thao tác tay (friction), giúp việc lên lịch hẹn trở nên nhanh chóng và tự nhiên hơn.


---

## 8. Các cải tiến và nỗ lực tối ưu thêm

Trong quá trình thực hiện bài test, em đã cố gắng tìm hiểu và áp dụng thêm một số kỹ thuật cũng như tính năng bổ sung với mong muốn sản phẩm được hoàn thiện và gần gũi với thực tế hơn.

### ✅ 8.1. Một số tính năng bổ sung nhằm tăng trải nghiệm

Em đã thử tích hợp thêm một vài công nghệ để luồng sử dụng của người dùng được liền mạch và an toàn hơn:

| Tính năng | Kỹ thuật áp dụng | Mục đích |
|---|---|---|
| 💬 **Thông báo thời gian thực** | Spring WebSocket (STOMP) | Giúp người dùng nhận thông báo (Match, Chat) tức thì mà không cần tải lại trang. |
| 📍 **Gợi ý điểm hẹn công bằng** | Công thức Haversine | Tự động đề xuất địa điểm nằm gần vị trí trung gian của hai người để tối ưu quãng đường di chuyển. |
| 💳 **Thanh toán mô phỏng** | VNPay Sandbox | Thử nghiệm quy trình cam kết tài chính để tăng tỷ lệ đi hẹn thực tế. |
| 📸 **Lưu trữ ảnh đám mây** | Cloudinary SDK | Giúp việc tải và hiển thị ảnh profile nhanh và ổn định hơn. |
| 🔐 **Đăng nhập nhanh** | Google OAuth 2.0 | Giảm bớt các bước đăng ký rườm rà, tạo sự thuận tiện cho người dùng. |
| 💌 **Tiết lộ liên hệ đối xứng** | Mutual Reveal Logic | Chỉ hiển thị thông tin khi cả hai cùng xác nhận muốn tiến tới, nhằm bảo vệ quyền riêng tư. |

### ✅ 8.2. Cố gắng xử lý các trường hợp biên (Edge Cases)

Em có chú trọng thêm vào việc kiểm soát các lỗi logic nhỏ để hệ thống vận hành ổn định hơn:
- **Chuẩn hóa bản ghi Match:** Luôn lưu cặp User theo thứ tự ID tăng dần để tránh việc tạo trùng lặp dữ liệu giữa hai người.
- **Cơ chế nhắc nhở (Penalty):** Em đã thêm logic tạm khóa quyền xem profile trong 24h nếu người dùng hủy lịch hẹn đã xác nhận, nhằm khuyến khích sự nghiêm túc.
- **Kiểm soát thời gian:** Tự động kiểm tra để đảm bảo các buổi hẹn có thời lượng tối thiểu 90 phút và không bị chồng chéo lịch trình.

### ✅ 8.3. Về phần trải nghiệm người dùng (UX)

Mặc dù là bản Prototype, em cũng dành thời gian để chau chuốt thêm một chút về giao diện:
- **Skeleton loading:** Hiển thị khung chờ (`SkeletonCard`) khi ảnh đang tải giúp người dùng không cảm thấy bị ngắt quãng.
- **Loading State toàn cục:** Sử dụng `LoadingContext` và component `LoadingSpinner` để hiển thị trạng thái chờ xử lý tại các thao tác quan trọng (submit profile, chọn lịch, thanh toán...), tránh người dùng thao tác trùng lặp.
- **Hiệu ứng thông báo:** Thêm các hiệu ứng chuyển cảnh đơn giản (Match popup) và thông báo Toast để tăng tính tương tác.
- **E-Ticket trực quan:** Thiết kế vé hẹn hò với các thông tin chi tiết giúp người dùng dễ dàng nắm bắt lịch trình.

### ✅ 8.4. Về cách tổ chức mã nguồn (Architecture)

Em cố gắng áp dụng các nguyên tắc Clean Code cơ bản để dự án dễ đọc và dễ bảo trì hơn:
- **Cấu trúc theo feature:** Chia code theo các tính năng (Auth, Chat, Matching...) để quản lý logic tập trung.
- **Xử lý lỗi tập trung:** Sử dụng `GlobalExceptionHandler` để đảm bảo mọi thông báo lỗi trả về cho Frontend đều đồng nhất.
- **Kiểm soát dữ liệu đầu vào:** Áp dụng các ràng buộc (Validation) ở cả hai phía để hạn chế tối đa dữ liệu rác.

---

## 📝 Ghi chú cuối cùng

- Em mong rằng những nỗ lực nhỏ trong việc mở rộng tính năng này sẽ phần nào thể hiện được sự nghiêm túc và tinh thần học hỏi của em đối với dự án.
- **AI Tooling:** Trong quá trình làm, em có sử dụng AI như một công cụ hỗ trợ để tra cứu nhanh các công thức toán học (như Haversine) và rà soát lại các đoạn mã lặp lại, giúp đẩy nhanh tiến độ làm bài.

---

*Hồ Chí Minh, 2026 — Hoàn thành với sự tâm huyết cho bài test kỹ thuật tại Clique83*
