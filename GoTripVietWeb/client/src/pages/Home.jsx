import React, { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import Container from "react-bootstrap/Container";
import "../styles/home.css";
import { cld } from "../utils/cld.js";
import catalogApi from "../api/catalogApi";
import inventoryApi from "../api/inventoryApi"; // [QUAN TRỌNG] Import API Inventory

// Import hàm xử lý dữ liệu mới
import { mapProductToCard } from "../utils/formatData";

// Components
import UnifiedSearch from "../components/search/UnifiedSearch.jsx";
import Slider from "../components/home/Slider.jsx";
import Event from "../components/Event.jsx";
import SmallCard from "../components/home/SmallCard.jsx";
import BigCard from "../components/home/BigCard.jsx";
import BannerMobile from "../components/BannerMobile.jsx";
import AiChatWidget from "../components/ai/AiChatWidget.jsx";

// Dữ liệu giả (fallback)
import { cities } from "../data/HomeData.jsx";

export default function Home() {
  const navigate = useNavigate();

  // Refs
  const refTours = useRef(null);
  const refLocations = useRef(null);

  // States
  const [realLocations, setRealLocations] = useState([]);
  const [realTours, setRealTours] = useState([]);
  const [categorySections, setCategorySections] = useState([]);
  const [loading, setLoading] = useState(true);

  // Sự kiện
  const [realEvents, setRealEvents] = useState([]);
  const [heroEvent, setHeroEvent] = useState(null);

  // --- 1. HÀM XỬ LÝ TÌM KIẾM ---
  const handleUnifiedSearch = (data) => {
    const params = new URLSearchParams();
    if (data.endPoint) params.append("q", data.endPoint);
    if (data.startPoint && data.startPoint !== "Tất cả")
      params.append("from", data.startPoint);
    if (data.date) params.append("date", data.date);
    if (data.budget) params.append("budget", data.budget);
    if (data.transport) params.append("transport", data.transport);
    if (data.hotelRating)
      params.append("star_rating", data.hotelRating.replace(/\D/g, ""));

    navigate(`/search?${params.toString()}`);
  };

  // --- 2. GỌI API LẤY DỮ LIỆU ---
  useEffect(() => {
    const fetchHomeData = async () => {
      try {
        setLoading(true);
        const now = new Date();
        const curYear = now.getFullYear();
        const curMonth = now.getMonth() + 1;

        // a. Gọi API cơ bản
        const [locationsRes, toursRes, rootCatsRes, eventsRes] =
          await Promise.all([
            catalogApi.getAllLocations(),
            catalogApi.getAll({ product_type: "tour", limit: 8 }),
            catalogApi.getAllCategories({ parent: "null" }),
            inventoryApi.getEventsInMonth(curYear, curMonth),
          ]);

        // b. Xử lý LOCATION
        let locList = Array.isArray(locationsRes?.data || locationsRes)
          ? locationsRes?.data || locationsRes
          : [];

        setRealLocations(
          locList.map((loc) => {
            const img = loc?.images?.[0]?.url;
            return {
              id: loc._id || loc.id,
              title: loc.name,
              subTitle: "Điểm đến hot",
              imageUrl:
                typeof img === "string" && img.startsWith("http")
                  ? img
                  : "https://placehold.co/200x200?text=Location",
            };
          })
        );

        // ===============================================
        // c. [XỬ LÝ QUAN TRỌNG] TOUR + INVENTORY
        // ===============================================
        let tourListRaw = Array.isArray(
          toursRes?.products || toursRes?.data?.products
        )
          ? toursRes?.products || toursRes?.data?.products
          : [];

        // Gọi Inventory cho từng tour để lấy danh sách ngày khởi hành
        const toursWithInventory = await Promise.all(
          tourListRaw.map(async (product) => {
            try {
              const productId = product._id || product.id;

              // Gọi API lấy lịch
              // Lưu ý: Dùng getByProductId hoặc getInventoryByProductId tùy file api của bạn
              const invRes = await inventoryApi.getByProductId(productId);

              const invList = Array.isArray(invRes.data)
                ? invRes.data
                : Array.isArray(invRes)
                ? invRes
                : [];

              // Lọc ngày hợp lệ: Active + Tương lai + Còn chỗ
              const futureDates = invList
                .filter((item) => {
                  const d = new Date(item.tour_details?.date);
                  const avail =
                    (item.tour_details?.total_slots || 0) -
                    (item.tour_details?.booked_slots || 0);
                  return item.is_active && d >= new Date() && avail > 0;
                })
                .map((item) => item.tour_details.date)
                .sort((a, b) => new Date(a) - new Date(b));

              // Gắn vào field mới
              return { ...product, departure_dates: futureDates };
            } catch (err) {
              // Nếu lỗi lấy lịch, trả về mảng rỗng (hiện Liên hệ)
              return { ...product, departure_dates: [] };
            }
          })
        );

        setRealTours(toursWithInventory.map((p) => mapProductToCard(p)));
        // ===============================================

        // d. Xử lý CATEGORY SECTIONS
        const rootCats = Array.isArray(rootCatsRes.data)
          ? rootCatsRes.data
          : Array.isArray(rootCatsRes)
          ? rootCatsRes
          : [];

        const sectionsData = await Promise.all(
          rootCats.map(async (parentCat) => {
            try {
              const childrenRes = await catalogApi.getAllCategories({
                parent: parentCat._id || parentCat.id,
              });
              const childrenList = Array.isArray(childrenRes.data)
                ? childrenRes.data
                : Array.isArray(childrenRes)
                ? childrenRes
                : [];

              if (childrenList.length === 0) return null;

              const formattedChildren = childrenList.map((child) => {
                const raw = child?.image?.url ?? child?.image;
                const base =
                  import.meta.env.VITE_API_URL || "http://localhost:3000";
                const img =
                  typeof raw === "string" && raw
                    ? raw.startsWith("http")
                      ? raw
                      : `${base}${raw.startsWith("/") ? "" : "/"}${raw}`
                    : "";

                return {
                  id: child._id || child.id,
                  title: child.name,
                  subTitle: "Khám phá ngay",
                  imageUrl:
                    img ||
                    `https://placehold.co/300x300/e0f7fa/006064?text=${encodeURIComponent(
                      child.name
                    )}`,
                };
              });

              return {
                parentId: parentCat._id || parentCat.id,
                parentTitle: parentCat.name,
                children: formattedChildren,
              };
            } catch (err) {
              return null;
            }
          })
        );

        // e. Xử lý EVENTS
        const eventsList = Array.isArray(eventsRes?.data) ? eventsRes.data : [];
        const formattedEvents = eventsList.map((ev) => ({
          backgroundUrl:
            ev?.image?.url || "https://placehold.co/1200x450?text=Event",
          alt: ev?.name || "Event",
          href: `/event/${ev?.slug || ev?._id}`,
        }));

        setRealEvents(formattedEvents);
        setHeroEvent(formattedEvents[0] || null);
        setCategorySections(sectionsData.filter((section) => section));
      } catch (error) {
        console.error("Lỗi tải dữ liệu Home:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchHomeData();
  }, []);

  return (
    <>
      {/* --- PHẦN 1: BANNER & TÌM KIẾM --- */}
      <div
        className="py-5 bg-light shadow-sm mb-2"
        style={{
          backgroundImage: "linear-gradient(to bottom, #f8f9fa, #e9ecef)",
        }}
      >
        <Container>
          <div className="text-center mb-4">
            <h2 className="fw-bold mb-2 text-primary">
              Khám phá thế giới cùng GoTripViet
            </h2>
            <p className="text-muted fs-5">
              Tìm tour du lịch trọn gói, giá tốt nhất dành cho bạn
            </p>
          </div>
          <UnifiedSearch
            onSearch={handleUnifiedSearch}
            locations={realLocations}
          />
        </Container>
      </div>

      {/* --- PHẦN 2: SỰ KIỆN --- */}
      <Container className="my-4">
        <Event
          backgroundUrl={
            heroEvent?.backgroundUrl ||
            cld("event_boxingday_iusunh", {
              w: 1200,
              h: 450,
              crop: "fill",
              g: "auto",
            })
          }
          alt={heroEvent?.alt || "Event"}
          href={heroEvent?.href || "/events"}
        />
      </Container>

      <Container className="my-4">
        <Slider
          title="Ưu đãi & Sự kiện"
          items={realEvents}
          itemMinWidth={350}
          renderItem={(e) => <Event {...e} />}
        />
      </Container>

      {/* --- PHẦN 3: ĐIỂM ĐẾN PHỔ BIẾN --- */}
      <Container className="my-5" ref={refLocations}>
        <Slider
          title="Điểm đến yêu thích"
          description="Khám phá các địa danh nổi tiếng"
          items={realLocations.length > 0 ? realLocations : cities}
          itemMinWidth={220}
          renderItem={(c) => (
            <SmallCard
              {...c}
              onClick={() =>
                navigate(
                  `/search?location_id=${c.id}&label=${encodeURIComponent(
                    c.title
                  )}`
                )
              }
            />
          )}
        />
      </Container>

      {/* --- PHẦN 4: DANH MỤC TOUR --- */}
      {categorySections.map((section) => (
        <Container className="my-5" key={section.parentId}>
          <Slider
            title={`Khám phá ${section.parentTitle}`}
            description={`Các tour du lịch hấp dẫn tại ${section.parentTitle}`}
            items={section.children}
            itemMinWidth={220}
            renderItem={(childCat) => (
              <SmallCard
                {...childCat}
                onClick={() =>
                  navigate(
                    `/search?category_id=${
                      childCat.id
                    }&label=${encodeURIComponent(childCat.title)}`
                  )
                }
              />
            )}
          />
        </Container>
      ))}

      {/* --- PHẦN 5: TOUR MỚI NHẤT --- */}
      <Container className="my-5" ref={refTours}>
        <Slider
          title="Tour du lịch mới nhất"
          description="Đừng bỏ lỡ các ưu đãi hấp dẫn đang chờ bạn"
          items={realTours}
          itemMinWidth={300}
          renderItem={(item) => (
            <BigCard
              {...item}
              onClick={() => navigate(`/product/${item.id}`)}
            />
          )}
        />
      </Container>

      {/* --- PHẦN 6: BANNER APP --- */}
      {/* <div className="mt-5">
        <BannerMobile
          backgroundUrl="/assets/app/app_bg.jpg"
          title="Tải ứng dụng ngay"
        />
      </div> */}
      <AiChatWidget />
    </>
  );
}
