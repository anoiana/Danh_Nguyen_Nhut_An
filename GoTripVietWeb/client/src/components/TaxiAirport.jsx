import React from "react";

const TAXI_CLASSES = [
  {
    id: "standard-sedan",
    label: "Hạng chuẩn",
    carExample: "Skoda Octavia hoặc tương tự",
    passengers: 3,
    luggage: 2,
    includesMeetAndGreet: true,
    freeCancel: true,
  },
  {
    id: "premium-sedan",
    label: "Hạng sang",
    carExample: "Mercedes-Benz E-Class hoặc tương tự",
    passengers: 3,
    luggage: 2,
    includesMeetAndGreet: true,
    freeCancel: true,
  },
  {
    id: "standard-minivan",
    label: "Minivan chuẩn",
    carExample: "Ford Tourneo hoặc tương tự",
    passengers: 7,
    luggage: 4,
    includesMeetAndGreet: true,
    freeCancel: true,
  },
  {
    id: "premium-minivan",
    label: "Minivan sang trọng",
    carExample: "Mercedes-Benz V-Class hoặc tương tự",
    passengers: 7,
    luggage: 4,
    includesMeetAndGreet: true,
    freeCancel: true,
  },
];

export default function TaxiAirport({ className }) {
  const [activeTab, setActiveTab] = React.useState("1-3"); // "1-3" | "4-7" | "all"

  const tabBtnClass = (value) =>
    `btn btn-sm rounded-pill ${
      activeTab === value ? "btn-dark" : "btn-outline-secondary bg-white"
    }`;

  const filteredClasses = React.useMemo(() => {
    if (activeTab === "all") return TAXI_CLASSES;
    if (activeTab === "1-3") {
      return TAXI_CLASSES.filter((c) => c.passengers <= 3);
    }
    // "4-7"
    return TAXI_CLASSES.filter((c) => c.passengers >= 4 && c.passengers <= 7);
  }, [activeTab]);

  return (
    <section className={className}>
      <h5 className="fw-bold mb-3">Taxi sân bay cho bất kỳ chuyến đi nào</h5>

      <div className="d-inline-flex bg-white border rounded-pill p-1 mb-3">
        <button
          type="button"
          className={tabBtnClass("1-3")}
          onClick={() => setActiveTab("1-3")}
        >
          1 – 3 khách
        </button>
        <button
          type="button"
          className={`${tabBtnClass("4-7")} mx-1`}
          onClick={() => setActiveTab("4-7")}
        >
          4 – 7 khách
        </button>
        <button
          type="button"
          className={tabBtnClass("all")}
          onClick={() => setActiveTab("all")}
        >
          Tất cả các taxi
        </button>
      </div>

      <div className="row g-3">
        {filteredClasses.map((item) => (
          <div key={item.id} className="col-12 col-md-6">
            <div className="border rounded-3 p-3 h-100 bg-white">
              <h6 className="fw-semibold mb-1">{item.label}</h6>
              <div className="text-muted small mb-3">{item.carExample}</div>

              <ul className="list-unstyled mb-0 small">
                <li className="d-flex align-items-center mb-1">
                  <i className="bi bi-person me-2" />
                  <span>{item.passengers} hành khách</span>
                </li>
                <li className="d-flex align-items-center mb-1">
                  <i className="bi bi-suitcase2 me-2" />
                  <span>{item.luggage} hành lý tiêu chuẩn</span>
                </li>
                {item.includesMeetAndGreet && (
                  <li className="d-flex align-items-center mb-1">
                    <i className="bi bi-check-circle me-2 text-primary" />
                    <span className="text-primary">
                      Bao gồm dịch vụ chào đón
                    </span>
                  </li>
                )}
                {item.freeCancel && (
                  <li className="d-flex align-items-center">
                    <i className="bi bi-check-lg me-2 text-success" />
                    <span className="text-success">Miễn phí hủy</span>
                  </li>
                )}
              </ul>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
