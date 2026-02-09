import React from "react";
import taxiFlowImg from "../assets/taxi/taxi_flow.png";

const STEPS = [
  {
    icon: "bi-car-front-fill",
    title: "Đặt taxi sân bay",
    text: "Xác nhận tức thì. Nếu kế hoạch thay đổi, bạn có thể hủy miễn phí đến 24 giờ trước giờ đón.",
  },
  {
    icon: "bi-person-badge-fill",
    title: "Gặp tài xế",
    text: "Bạn sẽ gặp tài xế ở ga đến và được đưa ra xe. Tài xế sẽ theo dõi chuyến bay và đợi bạn kể cả khi chuyến bay bị trễ.",
  },
  {
    icon: "bi-building",
    title: "Tới điểm đến",
    text: "Tới điểm đến của bạn nhanh và an toàn – không cần xếp hàng chờ taxi hay tìm phương tiện công cộng.",
  },
];

export default function TaxiHowItWorks() {
  return (
    <section>
      <h4 className="fw-bold text-center mb-4">
        Đưa đón sân bay thật tiện lợi
      </h4>

      <div className="row align-items-center g-4">
        {/* Steps */}
        <div className="col-12 col-lg-6">
          {STEPS.map((step) => (
            <div key={step.title} className="d-flex mb-4">
              <div
                className="rounded-circle d-flex align-items-center justify-content-center flex-shrink-0 me-3"
                style={{
                  width: 64,
                  height: 64,
                  backgroundColor: "#dbe7ff",
                }}
              >
                <i className={`bi ${step.icon} fs-3 text-primary`} />
              </div>
              <div>
                <h6 className="fw-semibold mb-1">{step.title}</h6>
                <p className="mb-0 small text-muted">{step.text}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Image */}
        <div className="col-12 col-lg-6">
          <div className="position-relative">
            <div
              className="position-absolute top-0 start-50 translate-middle-x bg-white rounded-3 shadow-sm px-3 py-1 small"
              style={{ zIndex: 1 }}
            >
              Trình tự vận hành ra sao?
            </div>
            <img
              src={taxiFlowImg}
              alt="Trình tự vận hành dịch vụ taxi sân bay"
              className="img-fluid d-block mx-auto"
              style={{ marginTop: "32px" }}
            />
          </div>
        </div>
      </div>
    </section>
  );
}
