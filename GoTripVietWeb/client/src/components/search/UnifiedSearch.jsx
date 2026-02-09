import React, { useState, useRef } from "react";
import Button from "react-bootstrap/Button";
import Overlay from "react-bootstrap/Overlay";
import Popover from "react-bootstrap/Popover";
import { useNavigate } from "react-router-dom";
import "../../styles/Search.css"; 

// --- CẤU HÌNH BỘ LỌC ---
const BUDGET_OPTIONS = ["Dưới 5 triệu", "5 - 10 triệu", "10 - 20 triệu", "Trên 20 triệu"];
const HOTEL_RATINGS = ["3 sao", "4 sao", "5 sao"]; // [MỚI] Thay cho Dòng Tour
const TRANSPORTS = ["Máy bay", "Xe du lịch", "Tàu hỏa", "Du thuyền"];

export default function UnifiedSearch({ onSearch, locations = [] }) {
  const navigate = useNavigate();

  // --- STATES ---
  const [startPoint, setStartPoint] = useState("Hồ Chí Minh");
  const [endPoint, setEndPoint] = useState("");
  const [date, setDate] = useState("");
  
  // Bộ lọc nâng cao
  const [budget, setBudget] = useState("");
  const [hotelRating, setHotelRating] = useState(""); // [MỚI] Lưu hạng sao
  const [transport, setTransport] = useState("Máy bay");

  // Popover controls
  const [showFilter, setShowFilter] = useState(false);
  const [showStart, setShowStart] = useState(false);
  
  // Refs
  const targetFilter = useRef(null);
  const targetStart = useRef(null);
  const containerRef = useRef(null);
  const dateInputRef = useRef(null);

  const formatDateDisplay = (dateString) => {
    if (!dateString) return "Chọn ngày";
    const d = new Date(dateString);
    return d.toLocaleDateString("vi-VN", { weekday: 'short', day: 'numeric', month: 'short' });
  };

  const handleSearch = () => {
    // Chuẩn bị dữ liệu gửi đi
    const searchData = { 
        startPoint, 
        endPoint, 
        date, 
        budget, 
        hotelRating, // Gửi chuỗi "4 sao"
        transport 
    };

    if (onSearch) onSearch(searchData);
    else {
        const params = new URLSearchParams();
        if(endPoint) params.append("q", endPoint);
        if(startPoint && startPoint !== "Tất cả") params.append("from", startPoint);
        if(date) params.append("date", date);
        if(budget) params.append("budget", budget);
        
        // [MỚI] Gửi transport và rating lên URL
        if(transport) params.append("transport", transport);
        if(hotelRating) params.append("star_rating", hotelRating.replace(" sao", "")); // Chỉ lấy số (4)
        
        navigate(`/search?${params.toString()}`);
    }
  };

  // List địa điểm gợi ý
  const defaultStartPoints = ["Hồ Chí Minh", "Hà Nội", "Đà Nẵng", "Cần Thơ", "Hải Phòng"];
  const startPointList = Array.from(new Set([...defaultStartPoints, ...locations.map(l => l.title)]));

  return (
    <div className="w-100 position-relative" style={{zIndex: 100}}>
      <div ref={containerRef} className="search-bar-container">
        
        {/* 1. ĐIỂM KHỞI HÀNH */}
        <div className="search-item start-point" ref={targetStart} onClick={() => setShowStart(!showStart)}>
           <div className="d-flex align-items-center gap-3">
              <i className="bi bi-geo-alt fs-5 text-secondary"></i>
              <div className="flex-grow-1 overflow-hidden">
                  <div className="search-label">Điểm khởi hành</div>
                  <div className="search-value">{startPoint}</div>
              </div>
              <i className="bi bi-chevron-down small text-muted"></i>
           </div>
        </div>

        <div className="search-divider"></div>

        {/* 2. ĐIỂM ĐẾN */}
        <div className="search-item destination">
            <div className="d-flex align-items-center gap-3 h-100">
                <i className="bi bi-map fs-5 text-primary"></i>
                <div className="w-100">
                    <div className="search-label">Bạn muốn đi đâu?</div>
                    <input 
                        type="text" 
                        className="search-input" 
                        placeholder="Tìm địa điểm, tên tour..."
                        value={endPoint}
                        onChange={(e) => setEndPoint(e.target.value)}
                    />
                </div>
            </div>
        </div>

        <div className="search-divider"></div>

        {/* 3. NGÀY ĐI (Click mở lịch bằng JS) */}
        <div 
            className="search-item date-picker"
            style={{cursor: 'pointer'}}
            onClick={() => {
                if (dateInputRef.current) {
                    dateInputRef.current.showPicker 
                        ? dateInputRef.current.showPicker() 
                        : dateInputRef.current.focus();
                }
            }}
        >
            <input 
                ref={dateInputRef}
                type="date" 
                style={{position: 'absolute', opacity: 0, pointerEvents: 'none', bottom: 0, left: 0}}
                onChange={(e) => setDate(e.target.value)}
            />
            <div className="d-flex align-items-center gap-3">
                <i className="bi bi-calendar4-week fs-5 text-primary"></i>
                <div>
                    <div className="search-label">Ngày đi</div>
                    <div className={`search-value ${!date && 'text-muted fw-normal'}`}>
                        {formatDateDisplay(date)}
                    </div>
                </div>
            </div>
        </div>

        <div className="search-divider"></div>

        {/* 4. TÙY CHỌN (Bộ lọc) */}
        <div className="search-item filter-opt" ref={targetFilter} onClick={() => setShowFilter(!showFilter)}>
            <div className="d-flex align-items-center gap-3">
                <i className="bi bi-sliders fs-5 text-primary"></i>
                <div className="flex-grow-1 overflow-hidden">
                    <div className="search-label">Bộ lọc</div>
                    <div className="search-value text-truncate">
                        {budget || hotelRating || "Tùy chọn"}
                    </div>
                </div>
                <i className="bi bi-chevron-down small text-muted"></i>
            </div>
        </div>

        {/* 5. NÚT TÌM KIẾM */}
        <div className="ps-2">
            <Button className="btn-search-main" onClick={handleSearch}>Tìm kiếm</Button>
        </div>
      </div>

      {/* --- POPOVER ĐIỂM KHỞI HÀNH --- */}
      <Overlay target={targetStart.current} show={showStart} placement="bottom-start" rootClose onHide={() => setShowStart(false)}>
        <Popover className="border-0 shadow-lg rounded-3 mt-2" style={{width: '240px', maxHeight: '300px', overflowY: 'auto'}}>
            <Popover.Body className="p-0 py-2">
                {startPointList.map(city => (
                    <div key={city} className="px-3 py-2 cursor-pointer hover-bg-light d-flex align-items-center gap-2" onClick={() => { setStartPoint(city); setShowStart(false); }}>
                        <i className="bi bi-geo-alt text-muted small"></i> <span className="fw-medium">{city}</span>
                    </div>
                ))}
            </Popover.Body>
        </Popover>
      </Overlay>

      {/* --- POPOVER BỘ LỌC --- */}
      <Overlay target={targetFilter.current} show={showFilter} placement="bottom-end" rootClose onHide={() => setShowFilter(false)}>
        <Popover className="border-0 shadow-lg rounded-4 mt-2" style={{width: '350px'}}>
            <Popover.Header className="bg-white border-0 pt-3">
                <div className="d-flex justify-content-between align-items-center">
                    <span className="fw-bold">Bộ lọc tìm kiếm</span>
                    <span className="text-primary small cursor-pointer" onClick={() => {setBudget(""); setHotelRating(""); setTransport("Máy bay");}}>Xóa lọc</span>
                </div>
            </Popover.Header>
            <Popover.Body>
                {/* Ngân sách */}
                <div className="mb-4">
                    <label className="fw-bold small mb-2 d-block">Ngân sách</label>
                    <div className="d-flex flex-wrap gap-2">
                        {BUDGET_OPTIONS.map(opt => (
                            <Button key={opt} variant={budget === opt ? "primary" : "outline-secondary"} size="sm" className="rounded-pill" onClick={() => setBudget(budget === opt ? "" : opt)}>{opt}</Button>
                        ))}
                    </div>
                </div>
                
                {/* [MỚI] Tiêu chuẩn Khách sạn */}
                <div className="mb-4">
                    <label className="fw-bold small mb-2 d-block">Tiêu chuẩn khách sạn</label>
                    <div className="d-flex flex-wrap gap-2">
                        {HOTEL_RATINGS.map(opt => (
                             <Button key={opt} variant={hotelRating === opt ? "warning" : "outline-secondary"} size="sm" className="rounded-pill" onClick={() => setHotelRating(hotelRating === opt ? "" : opt)}>
                                {opt}
                             </Button>
                        ))}
                    </div>
                </div>

                {/* Phương tiện */}
                 <div className="mb-3">
                    <label className="fw-bold small mb-2 d-block">Phương tiện di chuyển</label>
                    <div className="btn-group w-100">
                        {TRANSPORTS.map(opt => (
                             <Button key={opt} variant={transport === opt ? "info text-white" : "outline-info"} size="sm" onClick={() => setTransport(opt)}>{opt}</Button>
                        ))}
                    </div>
                </div>
                
                <div className="d-grid mt-3">
                    <Button onClick={() => setShowFilter(false)} className="fw-bold">Áp dụng</Button>
                </div>
            </Popover.Body>
        </Popover>
      </Overlay>
    </div>
  );
}