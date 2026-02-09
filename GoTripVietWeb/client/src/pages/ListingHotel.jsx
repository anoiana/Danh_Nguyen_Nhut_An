import React, { useMemo, useState } from "react";
import SearchingBar from "../components/listing/SearchingBar.jsx";
import BestChoiceSearch from "../components/listing/BestChoiceSearch.jsx";
import Slider from "../components/listing/Slider.jsx";
import ListingCard from "../components/listing/HotelCard.jsx";
import { useLocation } from "react-router-dom";

import { LISTING_HOTELS, SIMILAR_STAYS } from "../data/HotelData.jsx";

const ListingHotel = ({
  destinationName = "Cát Tiên",
  totalStays = 12,
  hotels = LISTING_HOTELS,
  similarStays = SIMILAR_STAYS,
  onNavigateToHotelDetail,
}) => {
  const [sortValue, setSortValue] = useState();
  const location = useLocation();

  const qFromUrl = useMemo(() => {
    const q = new URLSearchParams(location.search).get("q");
    return (q || "").trim();
  }, [location.search]);

  const effectivePlace = qFromUrl || destinationName;
  const mainHotel = hotels[0];
  const otherHotels = hotels.slice(1);

  return (
    <div className="container my-4">
      <div className="row">
        {/* Cột trái: thanh lọc */}
        <div className="col-12 col-lg-3 mb-3 mb-lg-0">
          <SearchingBar mapQuery={effectivePlace} />
        </div>

        {/* Cột phải: kết quả listing */}
        <div className="col-12 col-lg-9">
          {/* Header trên cùng */}
          <div className="d-flex flex-wrap justify-content-between align-items-center mb-3 gap-2">
            <div>
              <h4 className="fw-bold mb-1">
                {effectivePlace}: tìm thấy {totalStays} chỗ nghỉ
              </h4>
            </div>
            <BestChoiceSearch
              className="ms-auto"
              value={sortValue}
              onChange={(v) => setSortValue(v)}
            />
          </div>

          {/* Hotel đầu tiên nổi bật */}
          {mainHotel && (
            <ListingCard
              {...mainHotel}
              onViewAvailability={() =>
                onNavigateToHotelDetail && onNavigateToHotelDetail(mainHotel)
              }
            />
          )}

          {/* Slider những chỗ nghỉ khác bạn có thể thích */}
          {similarStays.length > 0 && (
            <div className="mt-3 mb-3">
              <Slider
                title="Những chỗ nghỉ khác bạn có thể thích"
                description={`Những chỗ nghỉ tương tự với ${
                  mainHotel?.title ?? ""
                }`}
                items={similarStays}
              />
            </div>
          )}

          {/* Các chỗ nghỉ khác */}
          <div className="mt-3">
            {otherHotels.map((hotel) => (
              <ListingCard
                key={hotel.title}
                {...hotel}
                onViewAvailability={() =>
                  onNavigateToHotelDetail && onNavigateToHotelDetail(hotel)
                }
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ListingHotel;
