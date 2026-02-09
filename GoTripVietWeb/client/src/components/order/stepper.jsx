import React from "react";
const BookingStepper = ({ currentStep = 1 }) => {
  const steps = ["Lựa chọn của bạn", "Thông tin của bạn", "Hoàn tất đặt phòng"];

  const getCircleClass = (index) => {
    const step = index + 1;
    if (step < currentStep)
      return "bg-primary text-white border border-primary";
    if (step === currentStep)
      return "bg-primary bg-opacity-10 text-primary border border-primary";
    return "bg-light text-muted border";
  };

  const getLabelClass = (index) => {
    const step = index + 1;
    if (step === currentStep) return "text-primary fw-semibold";
    return "text-muted";
  };

  return (
    <div className="border-bottom bg-white">
      <div className="container py-3 d-flex align-items-center justify-content-between">
        <nav
          aria-label="Bước đặt phòng"
          className="d-flex align-items-center flex-wrap"
        >
          {steps.map((label, index) => (
            <React.Fragment key={label}>
              <div className="d-flex align-items-center">
                <span
                  className={`rounded-circle d-inline-flex align-items-center justify-content-center me-2 ${getCircleClass(
                    index
                  )}`}
                  style={{
                    width: 28,
                    height: 28,
                    fontSize: 12,
                    fontWeight: 700,
                  }}
                  aria-hidden="true"
                >
                  {index + 1}
                </span>
                <span className={`small ${getLabelClass(index)}`}>{label}</span>
              </div>

              {index < steps.length - 1 && (
                <div
                  className="d-flex align-items-center mx-2 mx-sm-3"
                  aria-hidden="true"
                >
                  <div
                    className={
                      index + 1 < currentStep
                        ? "bg-primary"
                        : "bg-secondary bg-opacity-25"
                    }
                    style={{ width: 36, height: 2, borderRadius: 999 }}
                  />
                </div>
              )}
            </React.Fragment>
          ))}
        </nav>
      </div>
    </div>
  );
};
export default BookingStepper;
