# GoTripViet - Tài liệu Chi tiết ERD (Entity Relationship Diagram)

## Mục lục
1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Chi tiết các Entity](#2-chi-tiết-các-entity)
3. [Quan hệ giữa các Entity](#3-quan-hệ-giữa-các-entity)
4. [Luồng dữ liệu chính](#4-luồng-dữ-liệu-chính)

---

## 1. Tổng quan kiến trúc

GoTripViet sử dụng kiến trúc **Microservices** với 6 service độc lập, mỗi service quản lý database MongoDB riêng:

| Service | Database | Entities |
|---------|----------|----------|
| **User Service** | user_db | User |
| **Catalog Service** | catalog_db | Product, Category, Location |
| **Inventory Service** | inventory_db | InventoryItem, Event, Promotion |
| **Booking Service** | booking_db | Booking |
| **Payment Service** | payment_db | Payment, Transaction |
| **AI Service** | ai_db | ChatSession |

> **Lưu ý**: Các quan hệ giữa các service là **logical reference** (tham chiếu logic), không phải foreign key constraint thực sự như SQL. MongoDB sử dụng ObjectId để liên kết.

---

## 2. Chi tiết các Entity

### 2.1. USER (User Service)

**Mô tả**: Lưu trữ thông tin người dùng, bao gồm cả Customer, Partner (đối tác) và Admin.

| Thuộc tính | Kiểu | Ràng buộc | Mô tả |
|------------|------|-----------|-------|
| `_id` | ObjectId | PK | ID duy nhất |
| `email` | String | Unique, Required | Email đăng nhập |
| `password_hash` | String | Required | Mật khẩu đã mã hóa (bcrypt) |
| `fullName` | String | - | Họ tên đầy đủ |
| `phone` | String | - | Số điện thoại cá nhân |
| `roles` | String[] | Enum | Vai trò: `user`, `admin`, `partner`, `support_staff` |
| `status` | String | Enum | Trạng thái: `ACTIVE`, `LOCKED`, `BANNED` |
| `wallet_balance` | Number | Min: 0 | Số dư ví (dành cho Partner) |
| `passwordResetToken` | String | - | Token đặt lại mật khẩu |
| `passwordResetExpires` | Date | - | Thời hạn token |

**Embedded Object - preferences** (Sở thích du lịch của User):
| Thuộc tính | Kiểu | Mô tả |
|------------|------|-------|
| `travel_style` | String | Phong cách du lịch |
| `interests` | String[] | Sở thích |
| `companions` | String[] | Đi cùng ai |
| `budget_per_trip_usd` | Number | Ngân sách mỗi chuyến |
| `pace` | String | Nhịp độ du lịch |
| `sustainability_priority` | Boolean | Ưu tiên bền vững |

**Embedded Object - partner_details** (Thông tin Partner):
| Thuộc tính | Kiểu | Mô tả |
|------------|------|-------|
| `company_name` | String | Tên công ty/thương hiệu |
| `business_license` | String | Mã số thuế/Giấy phép KD |
| `contact_phone` | String | Hotline liên hệ |
| `bank_account.bank_name` | String | Tên ngân hàng |
| `bank_account.account_number` | String | Số tài khoản |
| `bank_account.account_holder` | String | Chủ tài khoản |
| `is_approved` | Boolean | Đã được duyệt chưa |
| `approved_at` | Date | Thời điểm duyệt |

---

### 2.2. PRODUCT (Catalog Service)

**Mô tả**: Lưu thông tin sản phẩm tour du lịch do Partner tạo.

| Thuộc tính | Kiểu | Ràng buộc | Mô tả |
|------------|------|-----------|-------|
| `_id` | ObjectId | PK | ID duy nhất |
| `partner_id` | ObjectId | FK → User | Partner sở hữu tour |
| `product_code` | String | Unique | Mã sản phẩm (VD: TOUR001) |
| `product_type` | String | Enum | Loại: `tour` |
| `title` | String | Required | Tiêu đề tour |
| `slug` | String | Unique | URL-friendly slug |
| `description_short` | String | - | Mô tả ngắn |
| `description_long` | String | - | Mô tả chi tiết |
| `images` | Array | - | Danh sách ảnh [{url, public_id}] |
| `tags` | String[] | - | Tags tìm kiếm |
| `base_price` | Number | Required | Giá cơ bản |
| `sustainability_score` | Number | 0-5 | Điểm bền vững |
| `status` | String | Enum | `draft`, `pending`, `active`, `rejected`, `hidden` |
| `rejection_reason` | String | - | Lý do từ chối (nếu có) |
| `location_ids` | ObjectId[] | FK → Location | Các địa điểm trong tour |
| `category_ids` | ObjectId[] | FK → Category | Danh mục tour |

**Embedded Object - tour_details**:
| Thuộc tính | Kiểu | Mô tả |
|------------|------|-------|
| `start_point` | String | Điểm xuất phát |
| `departure_times` | Date[] | Các ngày khởi hành |
| `schedules` | Array | Lịch khởi hành chi tiết |
| `duration_days` | Number | Số ngày tour |
| `transport_type` | String | Phương tiện: Máy bay, Xe du lịch, ... |
| `hotel_rating` | Number | Sao khách sạn |
| `hotel_name` | String | Tên khách sạn |
| `itinerary` | Array | Lịch trình từng ngày |
| `trip_highlights` | Object | Điểm nổi bật |
| `policy_notes` | Array | Chính sách & lưu ý |

---

### 2.3. CATEGORY (Catalog Service)

**Mô tả**: Danh mục phân loại tour (hỗ trợ cấu trúc cây cha-con).

| Thuộc tính | Kiểu | Ràng buộc | Mô tả |
|------------|------|-----------|-------|
| `_id` | ObjectId | PK | ID duy nhất |
| `name` | String | Unique, Required | Tên danh mục |
| `slug` | String | Unique | URL slug |
| `description` | String | - | Mô tả |
| `image` | Object | - | Ảnh đại diện {url, public_id} |
| `status` | String | Enum | Trạng thái |
| `parent` | ObjectId | FK → Category | Danh mục cha (self-reference) |
| `created_by` | ObjectId | FK → User | Admin tạo |

---

### 2.4. LOCATION (Catalog Service)

**Mô tả**: Địa điểm du lịch (có thể gán cho nhiều tour).

| Thuộc tính | Kiểu | Ràng buộc | Mô tả |
|------------|------|-----------|-------|
| `_id` | ObjectId | PK | ID duy nhất |
| `name` | String | Required | Tên địa điểm |
| `slug` | String | Unique | URL slug |
| `country` | String | - | Quốc gia |
| `description` | String | - | Mô tả |
| `images` | Array | - | Danh sách ảnh |
| `tags` | String[] | - | Tags |
| `coordinates` | GeoJSON | - | Tọa độ GPS |
| `status` | String | Enum | Trạng thái |
| `created_by` | ObjectId | FK → User | Admin tạo |

---

### 2.5. INVENTORY_ITEM (Inventory Service)

**Mô tả**: Quản lý kho/slot của từng ngày khởi hành tour.

| Thuộc tính | Kiểu | Ràng buộc | Mô tả |
|------------|------|-----------|-------|
| `_id` | ObjectId | PK | ID duy nhất |
| `product_id` | ObjectId | FK → Product | Sản phẩm liên kết |
| `product_type` | String | Enum | `tour`, `hotel`, `flight` |
| `price` | Number | Required | Giá hiện tại (có thể đã giảm) |
| `original_price` | Number | - | Giá gốc (trước khi áp event) |
| `is_active` | Boolean | - | Còn bán không |

**Embedded Object - applied_event** (Event đang áp dụng):
| Thuộc tính | Kiểu | Mô tả |
|------------|------|-------|
| `event_id` | ObjectId | FK → Event |
| `name` | String | Tên event |
| `discount_type` | String | `percentage` hoặc `fixed_amount` |
| `discount_value` | Number | Giá trị giảm |
| `priority` | Number | Độ ưu tiên |
| `applied_at` | Date | Thời điểm áp dụng |

**Embedded Object - tour_details**:
| Thuộc tính | Kiểu | Mô tả |
|------------|------|-------|
| `date` | Date | Ngày khởi hành |
| `total_slots` | Number | Tổng số chỗ |
| `booked_slots` | Number | Số chỗ đã đặt |
| `transport_schedule.departure_time` | String | Giờ đi |
| `transport_schedule.arrival_time` | String | Giờ đến |
| `transport_schedule.return_time` | String | Giờ về |
| `transport_schedule.return_arrival_time` | String | Giờ về đến nơi |
| `transport_schedule.airline` | String | Hãng bay |
| `transport_schedule.depart_code` | String | Mã chuyến đi |
| `transport_schedule.return_code` | String | Mã chuyến về |
| `transport_schedule.pickup_location` | String | Điểm đón |

---

### 2.6. EVENT (Inventory Service)

**Mô tả**: Sự kiện giảm giá theo mùa/lễ (VD: Tết, Hè, Black Friday).

| Thuộc tính | Kiểu | Ràng buộc | Mô tả |
|------------|------|-----------|-------|
| `_id` | ObjectId | PK | ID duy nhất |
| `name` | String | Required | Tên sự kiện |
| `slug` | String | Unique | URL slug |
| `description` | String | - | Mô tả |
| `image` | Object | - | Ảnh banner |
| `discount_type` | String | Enum | `percentage`, `fixed_amount` |
| `discount_value` | Number | Required | Giá trị giảm |
| `is_yearly` | Boolean | - | Lặp lại hàng năm |
| `start_month`, `start_day` | Number | - | Ngày bắt đầu |
| `end_month`, `end_day` | Number | - | Ngày kết thúc |
| `applies_to_product_type` | String | Enum | Áp dụng cho loại SP |
| `apply_to_all_tours` | Boolean | - | Áp dụng tất cả tour |
| `tour_ids` | String[] | - | Danh sách tour cụ thể |
| `priority` | Number | - | Độ ưu tiên (số lớn = ưu tiên cao) |
| `is_active` | Boolean | - | Đang hoạt động |

---

### 2.7. PROMOTION (Inventory Service)

**Mô tả**: Mã giảm giá (Voucher) do Admin tạo.

| Thuộc tính | Kiểu | Ràng buộc | Mô tả |
|------------|------|-----------|-------|
| `_id` | ObjectId | PK | ID duy nhất |
| `code` | String | Unique | Mã voucher (VD: SALE20) |
| `type` | String | Enum | `percentage`, `fixed_amount` |
| `value` | Number | Required | Giá trị giảm |
| `description` | String | - | Mô tả |
| `total_quantity` | Number | - | Tổng số lượng |
| `used_quantity` | Number | - | Đã sử dụng |
| `is_active` | Boolean | - | Còn hiệu lực |

**Embedded Object - rules**:
| Thuộc tính | Kiểu | Mô tả |
|------------|------|-------|
| `valid_from` | Date | Ngày bắt đầu |
| `valid_to` | Date | Ngày hết hạn |
| `applies_to_product_type` | String | Loại SP áp dụng |
| `min_spend` | Number | Chi tiêu tối thiểu |

---

### 2.8. BOOKING (Booking Service)

**Mô tả**: Đơn đặt tour của khách hàng.

| Thuộc tính | Kiểu | Ràng buộc | Mô tả |
|------------|------|-----------|-------|
| `_id` | ObjectId | PK | ID duy nhất |
| `user_id` | ObjectId | FK → User | Khách hàng đặt |
| `promotion_id` | ObjectId | FK → Promotion | Mã giảm giá (nếu có) |
| `status` | String | Enum | `pending`, `confirmed`, `cancelled`, `failed`, `completed` |
| `payment_status` | String | Enum | `unpaid`, `paid`, `refunded` |
| `start_date` | Date | Required | Ngày bắt đầu tour |
| `end_date` | Date | Required | Ngày kết thúc |

**Embedded Object - pricing**:
| Thuộc tính | Kiểu | Mô tả |
|------------|------|-------|
| `total_price_before_discount` | Number | Tổng giá trước giảm |
| `discount_amount` | Number | Số tiền giảm |
| `final_price` | Number | Giá cuối cùng |

**Embedded Array - passengers**:
| Thuộc tính | Kiểu | Mô tả |
|------------|------|-------|
| `type` | String | `adult`, `child`, `toddler`, `infant` |
| `fullName` | String | Họ tên hành khách |
| `gender` | String | `Nam`, `Nữ`, `Khác` |
| `dateOfBirth` | Date | Ngày sinh |

**Embedded Array - items**:
| Thuộc tính | Kiểu | Mô tả |
|------------|------|-------|
| `product_id` | ObjectId | FK → Product |
| `inventory_id` | ObjectId | FK → InventoryItem |
| `product_type` | String | Loại sản phẩm |
| `quantity` | Number | Số lượng |
| `unit_price` | Number | Đơn giá |
| `snapshot.title` | String | Tên tour (snapshot) |
| `snapshot.description_short` | String | Mô tả ngắn |
| `snapshot.image` | String | Ảnh đại diện |
| `snapshot.details_text` | String | Chi tiết |

**Embedded Array - payments**:
| Thuộc tính | Kiểu | Mô tả |
|------------|------|-------|
| `gateway` | String | Cổng thanh toán: `vnpay`, `stripe`, `momo` |
| `gateway_transaction_id` | String | Mã giao dịch từ gateway |
| `amount` | Number | Số tiền |
| `status` | String | `pending`, `succeeded`, `failed` |
| `timestamp` | Date | Thời điểm |

**Embedded Object - customer_details**:
| Thuộc tính | Kiểu | Mô tả |
|------------|------|-------|
| `fullName` | String | Họ tên người liên hệ |
| `email` | String | Email |
| `phone` | String | Số điện thoại |
| `address` | String | Địa chỉ |
| `note` | String | Ghi chú |

---

### 2.9. PAYMENT (Payment Service)

**Mô tả**: Bản ghi thanh toán chính thức.

| Thuộc tính | Kiểu | Ràng buộc | Mô tả |
|------------|------|-----------|-------|
| `_id` | ObjectId | PK | ID duy nhất |
| `booking_id` | ObjectId | FK → Booking | Đơn hàng liên kết |
| `user_id` | ObjectId | FK → User | Người thanh toán |
| `amount` | Number | Required | Số tiền |
| `currency` | String | Required | Đơn vị tiền tệ (VND) |
| `status` | String | Enum | `pending`, `succeeded`, `failed`, `refunded` |
| `gateway` | String | Enum | `vnpay`, `stripe`, `momo`, `cod` |
| `gateway_transaction_id` | String | - | Mã GD từ gateway |
| `amount_refunded` | Number | - | Số tiền đã hoàn |
| `refunded_at` | Date | - | Thời điểm hoàn |
| `transaction_date` | Date | Required | Ngày giao dịch |

---

### 2.10. TRANSACTION (Payment Service)

**Mô tả**: Giao dịch ví tiền của Partner (thu nhập, rút tiền, hoàn, hoa hồng).

| Thuộc tính | Kiểu | Ràng buộc | Mô tả |
|------------|------|-----------|-------|
| `_id` | ObjectId | PK | ID duy nhất |
| `partner_id` | ObjectId | FK → User | Partner liên quan |
| `booking_id` | ObjectId | FK → Booking | Đơn hàng liên quan |
| `type` | String | Enum | `INCOME`, `WITHDRAWAL`, `REFUND`, `COMMISSION`, `VOUCHER_COST` |
| `amount` | Number | Required | Số tiền |
| `description` | String | - | Mô tả giao dịch |
| `status` | String | Enum | `pending`, `completed`, `failed` |
| `balance_after` | Number | - | Số dư sau giao dịch |

---

### 2.11. CHAT_SESSION (AI Service)

**Mô tả**: Phiên chat với AI Chatbot.

| Thuộc tính | Kiểu | Ràng buộc | Mô tả |
|------------|------|-----------|-------|
| `_id` | ObjectId | PK | ID duy nhất |
| `sessionId` | String | Unique | ID phiên chat |

**Embedded Array - messages**:
| Thuộc tính | Kiểu | Mô tả |
|------------|------|-------|
| `role` | String | `user`, `assistant`, `system` |
| `content` | String | Nội dung tin nhắn |
| `createdAt` | Date | Thời điểm tạo |
| `updatedAt` | Date | Thời điểm cập nhật |

---

## 3. Quan hệ giữa các Entity

### 3.1. Sơ đồ quan hệ tổng quát

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER SERVICE                                    │
│  ┌──────────┐                                                               │
│  │   USER   │◄─────────────────────────────────────────────────────────┐    │
│  └────┬─────┘                                                          │    │
└───────┼────────────────────────────────────────────────────────────────┼────┘
        │                                                                │
        │ partner_id (1:N)                                               │
        ▼                                                                │
┌─────────────────────────────────────────────────────────────────────────────┐
│                            CATALOG SERVICE                                   │
│  ┌──────────┐    category_ids (N:M)    ┌──────────┐                         │
│  │ PRODUCT  │◄────────────────────────►│ CATEGORY │◄──┐ parent (self-ref)   │
│  └────┬─────┘                          └──────────┘───┘                     │
│       │                                                                     │
│       │ location_ids (N:M)                                                  │
│       ▼                                                                     │
│  ┌──────────┐                                                               │
│  │ LOCATION │                                                               │
│  └──────────┘                                                               │
└───────┬─────────────────────────────────────────────────────────────────────┘
        │
        │ product_id (1:N)
        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INVENTORY SERVICE                                  │
│  ┌───────────────┐    applied_event (N:1)    ┌─────────┐                    │
│  │ INVENTORY_ITEM│◄─────────────────────────►│  EVENT  │                    │
│  └───────────────┘                           └─────────┘                    │
│                                                                             │
│  ┌───────────┐                                                              │
│  │ PROMOTION │                                                              │
│  └─────┬─────┘                                                              │
└────────┼────────────────────────────────────────────────────────────────────┘
         │
         │ promotion_id (N:1)
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            BOOKING SERVICE                                   │
│  ┌──────────┐                                                               │
│  │ BOOKING  │◄──────── user_id (N:1) ──────────────────────────────────┘    │
│  └────┬─────┘                                                               │
└───────┼─────────────────────────────────────────────────────────────────────┘
        │
        │ booking_id (1:N)
        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PAYMENT SERVICE                                    │
│  ┌──────────┐          ┌─────────────┐                                      │
│  │ PAYMENT  │          │ TRANSACTION │◄──── partner_id (N:1)                │
│  └──────────┘          └─────────────┘                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2. Chi tiết từng quan hệ

| Quan hệ | Loại | Mô tả chi tiết |
|---------|------|----------------|
| **User → Product** | 1:N | Một Partner có thể tạo nhiều Product (tour) |
| **User → Booking** | 1:N | Một User có thể đặt nhiều Booking |
| **User → Category** | 1:N (optional) | Admin tạo Category |
| **User → Location** | 1:N (optional) | Admin tạo Location |
| **User → Payment** | 1:N | Một User có nhiều Payment |
| **User → Transaction** | 1:N | Partner có nhiều Transaction trong ví |
| **Category → Category** | 1:N (self) | Danh mục cha-con (cây phân cấp) |
| **Product ↔ Category** | N:M | Tour thuộc nhiều danh mục |
| **Product ↔ Location** | N:M | Tour đi qua nhiều địa điểm |
| **Product → InventoryItem** | 1:N | Một Product có nhiều slot ngày khởi hành |
| **InventoryItem → Event** | N:1 | Nhiều slot có thể áp dụng cùng một Event |
| **Booking → Promotion** | N:1 | Nhiều Booking có thể dùng chung một Promotion |
| **Booking → Payment** | 1:N | Một Booking có thể có nhiều lần thanh toán |
| **Booking → Transaction** | 1:N | Một Booking sinh ra nhiều Transaction (thu, hoàn, hoa hồng) |

---

## 4. Luồng dữ liệu chính

### 4.1. Luồng đặt tour (Booking Flow)

```
1. User xem danh sách Product (Catalog Service)
       ↓
2. User chọn Product → Lấy InventoryItem theo ngày (Inventory Service)
       ↓
3. User nhập thông tin, chọn Promotion (nếu có)
       ↓
4. Tạo Booking (Booking Service)
       ↓
5. Chuyển đến cổng thanh toán (VNPAY, Stripe, Momo)
       ↓
6. Callback → Tạo Payment (Payment Service)
       ↓
7. Nếu thanh toán thành công:
   - Cập nhật Booking.status = 'confirmed'
   - Cập nhật InventoryItem.booked_slots += quantity
   - Tạo Transaction cho Partner (INCOME)
```

### 4.2. Luồng duyệt tour (Product Approval)

```
1. Partner tạo Product (status = 'pending')
       ↓
2. Admin xem danh sách Product chờ duyệt
       ↓
3. Admin duyệt → status = 'active'
   Hoặc từ chối → status = 'rejected', rejection_reason = '...'
```

### 4.3. Luồng áp Event giảm giá

```
1. Admin tạo Event với thời gian & điều kiện
       ↓
2. Scheduler (Cron Job) quét InventoryItem theo điều kiện
       ↓
3. Áp dụng discount vào price, lưu original_price
       ↓
4. Khi Event hết hạn → Revert price = original_price
```

---

## Ghi chú

- **Timestamps**: Tất cả các entity đều có `createdAt` và `updatedAt` (tự động bởi Mongoose)
- **Soft Delete**: Các entity quan trọng sử dụng `status` thay vì xóa cứng
- **Snapshot**: Booking lưu snapshot của Product để giữ thông tin tại thời điểm đặt
- **Wallet**: Partner sử dụng `wallet_balance` để quản lý doanh thu, sau đó rút tiền qua Transaction
