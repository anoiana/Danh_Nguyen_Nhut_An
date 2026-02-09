import React from "react";

export default function ProgressBar({ steps = [], activeStep = 1 }) {
  return (
    <div className="d-flex align-items-center gap-3 flex-wrap">
      {steps.map((label, i) => {
        const step = i + 1;
        const done = step < activeStep;
        const active = step === activeStep;

        return (
          <React.Fragment key={label}>
            <div className="d-flex align-items-center gap-2">
              <div
                className="d-flex align-items-center justify-content-center fw-bold"
                style={{
                  width: 26,
                  height: 26,
                  borderRadius: 999,
                  border: `2px solid ${active || done ? "#0d6efd" : "#adb5bd"}`,
                  background: active || done ? "#0d6efd" : "transparent",
                  color: active || done ? "#fff" : "#6c757d",
                  fontSize: 13,
                }}
              >
                {step}
              </div>
              <div className={`fw-semibold ${active ? "" : "text-muted"}`}>
                {label}
              </div>
            </div>

            {i < steps.length - 1 ? (
              <div
                style={{
                  width: 80,
                  height: 2,
                  background: done ? "#0d6efd" : "#dee2e6",
                }}
              />
            ) : null}
          </React.Fragment>
        );
      })}
    </div>
  );
}
