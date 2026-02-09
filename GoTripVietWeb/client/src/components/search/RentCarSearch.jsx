import React, { useMemo, useRef, useState } from "react";
import Button from "react-bootstrap/Button";
import Overlay from "react-bootstrap/Overlay";
import Popover from "react-bootstrap/Popover";
import Form from "react-bootstrap/Form";
import CloseButton from "react-bootstrap/CloseButton";
import "../../styles/home.css";

function fmtDate(d) {
  if (!d) return "";
  return d.toLocaleDateString("vi-VN", {
    weekday: "short",
    day: "2-digit",
    month: "2-digit",
  });
}

function sameDate(a, b) {
  return !!a && !!b && a.toDateString() === b.toDateString();
}

function buildMonth(year, month) {
  const first = new Date(year, month, 1);
  const startIdx = (first.getDay() + 6) % 7;
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const cells = [];
  for (let i = 0; i < startIdx; i++) {
    cells.push({
      date: new Date(year, month, 1 - (startIdx - i)),
      inMonth: false,
    });
  }
  for (let d = 1; d <= daysInMonth; d++) {
    cells.push({ date: new Date(year, month, d), inMonth: true });
  }
  while (cells.length % 7 !== 0) {
    cells.push({
      date: new Date(year, month + 1, cells.length % 7),
      inMonth: false,
    });
  }
  while (cells.length < 42) {
    const last = cells[cells.length - 1].date;
    cells.push({
      date: new Date(last.getFullYear(), last.getMonth(), last.getDate() + 1),
      inMonth: false,
    });
  }
  return cells;
}

function fmtTimeLabel(value) {
  const [hRaw, mRaw] = value.split(":").map(Number);
  if (Number.isNaN(hRaw) || Number.isNaN(mRaw)) return value;
  const am = hRaw < 12;
  let h = hRaw % 12;
  if (h === 0) h = 12;
  const hh = String(h).padStart(2, "0");
  const mm = String(mRaw).padStart(2, "0");
  const suffix = am ? "SA" : "CH";
  return `${hh}:${mm} ${suffix}`;
}

function CalendarSingle({ value, onPick, onDone, title = "Chọn ngày" }) {
  const today = new Date();
  const [base, setBase] = useState(
    new Date(today.getFullYear(), today.getMonth(), 1)
  );
  const months = [
    { y: base.getFullYear(), m: base.getMonth() },
    {
      y: new Date(base.getFullYear(), base.getMonth() + 1, 1).getFullYear(),
      m: new Date(base.getFullYear(), base.getMonth() + 1, 1).getMonth(),
    },
  ];
  const weekdays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

  return (
    <div style={{ width: "min(560px, 95vw)" }}>
      <div className="d-flex justify-content-between align-items-center px-2 mb-2">
        <Button
          variant="light"
          size="sm"
          onClick={() =>
            setBase(new Date(base.getFullYear(), base.getMonth() - 1, 1))
          }
        >
          ‹
        </Button>
        <div className="fw-semibold">{title}</div>
        <Button
          variant="light"
          size="sm"
          onClick={() =>
            setBase(new Date(base.getFullYear(), base.getMonth() + 1, 1))
          }
        >
          ›
        </Button>
      </div>

      <div className="d-flex flex-wrap gap-4 px-2 pb-2">
        {months.map(({ y, m }, idx) => {
          const cells = buildMonth(y, m);
          const monthLabel = new Date(y, m, 1).toLocaleDateString("vi-VN", {
            month: "long",
            year: "numeric",
          });
          return (
            <div key={idx} className="flex-grow-1">
              <div className="fw-semibold text-center mb-2 text-capitalize">
                {monthLabel}
              </div>
              <div
                className="d-grid"
                style={{ gridTemplateColumns: "repeat(7,1fr)", gap: 6 }}
              >
                {weekdays.map((w) => (
                  <div key={w} className="text-center text-muted small">
                    {w}
                  </div>
                ))}
                {cells.map(({ date, inMonth }, i) => {
                  const disabled =
                    !inMonth ||
                    date <
                      new Date(
                        today.getFullYear(),
                        today.getMonth(),
                        today.getDate()
                      );
                  const selected = sameDate(date, value);
                  const cls = [
                    "small",
                    "text-center",
                    "py-2",
                    "rounded-2",
                    disabled ? "text-muted" : "cursor-pointer",
                    selected && "bg-primary text-white",
                  ]
                    .filter(Boolean)
                    .join(" ");
                  return (
                    <div
                      key={i}
                      className={cls}
                      style={{ userSelect: "none" }}
                      onClick={() => !disabled && onPick(date)}
                    >
                      {date.getDate()}
                    </div>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>

      <div className="d-flex justify-content-between align-items-center border-top pt-2 px-2">
        <div className="small text-muted">
          Ngày: <strong>{fmtDate(value) || "--"}</strong>
        </div>
        <div className="d-flex gap-2">
          <Button variant="light" size="sm" onClick={() => onPick(undefined)}>
            Xoá
          </Button>
          <Button variant="primary" size="sm" onClick={onDone}>
            Xong
          </Button>
        </div>
      </div>
    </div>
  );
}

export default function RentCarSearch({ onSearch, className }) {
  const wrapRef = useRef(null);

  const [pickup, setPickup] = useState("");
  const [dropoff, setDropoff] = useState("");
  const [differentLocation, setDifferentLocation] = useState(true);

  const [datePick, setDatePick] = useState(undefined);
  const [dateDrop, setDateDrop] = useState(undefined);

  const [timePick, setTimePick] = useState("10:00");
  const [timeDrop, setTimeDrop] = useState("10:00");

  const [in3065, setIn3065] = useState(false);
  const [driverAge, setDriverAge] = useState(undefined);

  const datePickRef = useRef(null);
  const dateDropRef = useRef(null);
  const timePickRef = useRef(null);
  const timeDropRef = useRef(null);

  const [showPickDate, setShowPickDate] = useState(false);
  const [showDropDate, setShowDropDate] = useState(false);

  const [timePanel, setTimePanel] = useState(null); // "pick" | "drop"
  const [timeAnchor, setTimeAnchor] = useState(null);

  const datePickLabel = useMemo(
    () => (datePick ? fmtDate(datePick) : "Ngày nhận xe"),
    [datePick]
  );
  const dateDropLabel = useMemo(
    () => (dateDrop ? fmtDate(dateDrop) : "Ngày trả xe"),
    [dateDrop]
  );
  const timePickLabel = useMemo(() => fmtTimeLabel(timePick), [timePick]);
  const timeDropLabel = useMemo(() => fmtTimeLabel(timeDrop), [timeDrop]);

  const timeSlots = useMemo(() => {
    const arr = [];
    for (let h = 0; h < 24; h++) {
      for (const m of [0, 30]) {
        const hh = String(h).padStart(2, "0");
        const mm = m === 0 ? "00" : "30";
        const value = `${hh}:${mm}`;
        arr.push({ value, label: fmtTimeLabel(value) });
      }
    }
    return arr;
  }, []);

  const shortGapWarning = useMemo(() => {
    if (!datePick || !dateDrop) return null;

    const [ph, pm] = timePick.split(":").map(Number);
    const [dh, dm] = timeDrop.split(":").map(Number);

    const dtStart = new Date(
      datePick.getFullYear(),
      datePick.getMonth(),
      datePick.getDate(),
      ph,
      pm
    );
    const dtEnd = new Date(
      dateDrop.getFullYear(),
      dateDrop.getMonth(),
      dateDrop.getDate(),
      dh,
      dm
    );

    const diffMin = Math.floor((+dtEnd - +dtStart) / 60000);
    if (diffMin <= 0) return null;

    const DAY_MIN = 24 * 60;
    const fullDays = Math.floor(diffMin / DAY_MIN);
    const remainder = diffMin - fullDays * DAY_MIN;

    if (fullDays < 1 || remainder <= 0 || remainder > 240) return null;

    const h = Math.floor(remainder / 60);
    const m = remainder % 60;

    return { h, m };
  }, [datePick, dateDrop, timePick, timeDrop]);

  function submit() {
    onSearch &&
      onSearch({
        pickup,
        dropoff: differentLocation ? dropoff : pickup,
        differentLocation,
        datePick,
        timePick,
        dateDrop,
        timeDrop,
        driverAge: in3065 ? undefined : driverAge,
      });
  }

  const popperConfig = {
    strategy: "absolute",
    modifiers: [
      { name: "offset", options: { offset: [0, 8] } },
      {
        name: "preventOverflow",
        options: { boundary: wrapRef.current || undefined },
      },
    ],
  };

  return (
    <section
      ref={wrapRef}
      className={`gv-search p-2 rounded-3 ${className || ""}`}
    >
      {/* main row */}
      <div className="d-flex flex-wrap gap-2 align-items-stretch rent-main-row">
        {/* Pickup */}
        <div className="flex-grow-1 rent-main-item" style={{ minWidth: 260 }}>
          <div className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2">
            <i className="bi bi-geo-alt fs-5 me-2" />
            <div className="w-100">
              <div className="text-muted small">Địa điểm nhận xe</div>
              <Form.Control
                size="sm"
                placeholder="Sân bay, thành phố hoặc ga"
                value={pickup}
                onChange={(e) => setPickup(e.target.value)}
                className="border-0 px-0"
                style={{ boxShadow: "none" }}
              />
            </div>
          </div>
        </div>

        {/* Drop-off */}
        {differentLocation && (
          <div className="flex-grow-1 rent-main-item" style={{ minWidth: 260 }}>
            <div className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2">
              <i className="bi bi-geo-alt fs-5 me-2" />
              <div className="w-100">
                <div className="text-muted small">Địa điểm trả xe</div>
                <Form.Control
                  size="sm"
                  placeholder="Sân bay, thành phố hoặc ga"
                  value={dropoff}
                  onChange={(e) => setDropoff(e.target.value)}
                  className="border-0 px-0"
                  style={{ boxShadow: "none" }}
                />
              </div>
            </div>
          </div>
        )}

        {/* Ngày nhận + giờ nhận */}
        <div
          className="d-flex align-items-stretch rent-main-item"
          style={{ minWidth: 220 }}
        >
          <div
            ref={datePickRef}
            className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
            role="button"
            onClick={() => {
              setShowPickDate(true);
              setShowDropDate(false);
            }}
          >
            <i className="bi bi-calendar3 fs-5 me-2" />
            <div className="text-truncate">
              <div className="text-muted small">Ngày nhận xe</div>
              <div className={datePick ? "" : "text-muted"}>
                {datePickLabel}
              </div>
            </div>
          </div>
          <div
            ref={timePickRef}
            className="bg-white rounded-3 border d-flex align-items-center px-2 ms-2 cursor-pointer"
            role="button"
            onClick={() => {
              setTimePanel("pick");
              if (timePickRef.current) setTimeAnchor(timePickRef.current);
            }}
          >
            <i className="bi bi-clock me-2" />
            <div className="text-truncate">
              <div className="text-muted small">Thời gian</div>
              <div>{timePickLabel}</div>
            </div>
          </div>
        </div>

        {/* Ngày trả + giờ trả */}
        <div
          className="d-flex align-items-stretch rent-main-item"
          style={{ minWidth: 220 }}
        >
          <div
            ref={dateDropRef}
            className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
            role="button"
            onClick={() => {
              setShowDropDate(true);
              setShowPickDate(false);
            }}
          >
            <i className="bi bi-calendar3 fs-5 me-2" />
            <div className="text-truncate">
              <div className="text-muted small">Ngày trả xe</div>
              <div className={dateDrop ? "" : "text-muted"}>
                {dateDropLabel}
              </div>
            </div>
          </div>
          <div
            ref={timeDropRef}
            className="bg-white rounded-3 border d-flex align-items-center px-2 ms-2 cursor-pointer"
            role="button"
            onClick={() => {
              setTimePanel("drop");
              if (timeDropRef.current) setTimeAnchor(timeDropRef.current);
            }}
          >
            <i className="bi bi-clock me-2" />
            <div className="text-truncate">
              <div className="text-muted small">Thời gian</div>
              <div>{timeDropLabel}</div>
            </div>
          </div>
        </div>

        {/* Search */}
        <div
          className="flex-grow-0 rent-main-item rent-main-search"
          style={{ minWidth: 140 }}
        >
          <Button
            variant="primary"
            className="w-100 h-100 rounded-3"
            onClick={submit}
            disabled={!pickup || !datePick || !dateDrop}
          >
            Tìm kiếm
          </Button>
        </div>
      </div>

      {/* hàng tùy chọn */}
      <div className="d-flex flex-wrap gap-3 align-items-center pt-2">
        <Form.Check
          type="checkbox"
          id="diff-loc"
          label="Trả xe tại địa điểm khác"
          checked={differentLocation}
          onChange={(e) => setDifferentLocation(e.currentTarget.checked)}
        />
        <Form.Check
          type="checkbox"
          id="age-range"
          label="Người lái xe tuổi từ 30 - 65?"
          checked={in3065}
          onChange={(e) => setIn3065(e.currentTarget.checked)}
        />
        {!in3065 && (
          <div className="d-inline-flex align-items-center gap-2">
            <span>Tuổi người lái xe</span>
            <Form.Control
              type="number"
              min={18}
              max={100}
              style={{ width: 80 }}
              value={driverAge ?? ""}
              onChange={(e) =>
                setDriverAge(
                  e.target.value ? Number(e.target.value) : undefined
                )
              }
            />
          </div>
        )}
      </div>

      {/* cảnh báo */}
      {shortGapWarning && (
        <div
          className="mt-3 p-3 border rounded-3"
          style={{ background: "#fff2ee", borderColor: "#ffcdc2" }}
        >
          <div className="d-flex align-items-center gap-2">
            <i className="bi bi-exclamation-circle" />
            <div className="fw-semibold">Tránh bị tính thêm phí theo ngày</div>
          </div>
          <div className="mt-1">
            Tránh bị tính thêm phí theo ngày. Trả xe trước hạn{" "}
            {shortGapWarning.h > 0 && <strong>{shortGapWarning.h} giờ</strong>}
            {shortGapWarning.m > 0 && (
              <>
                {" "}
                <strong>{shortGapWarning.m} phút</strong>
              </>
            )}{" "}
            để tiết kiệm phí thuê cả ngày
          </div>
        </div>
      )}

      {/* Overlay: chọn ngày nhận */}
      <Overlay
        target={datePickRef.current}
        show={showPickDate}
        placement="bottom-start"
        rootClose
        container={wrapRef.current}
        popperConfig={popperConfig}
        onHide={() => setShowPickDate(false)}
      >
        {(props) => (
          <Popover
            {...props}
            className={`shadow ${props.className ?? ""}`}
            style={{
              ...(props.style || {}),
              width: "min(600px,95vw)",
              maxWidth: "none",
            }}
          >
            <Popover.Header className="d-flex align-items-center justify-content-between">
              <div className="fw-semibold">Chọn ngày nhận</div>
              <CloseButton onClick={() => setShowPickDate(false)} />
            </Popover.Header>
            <Popover.Body>
              <CalendarSingle
                value={datePick}
                onPick={setDatePick}
                onDone={() => setShowPickDate(false)}
              />
            </Popover.Body>
          </Popover>
        )}
      </Overlay>

      {/* Overlay: chọn ngày trả */}
      <Overlay
        target={dateDropRef.current}
        show={showDropDate}
        placement="bottom-start"
        rootClose
        container={wrapRef.current}
        popperConfig={popperConfig}
        onHide={() => setShowDropDate(false)}
      >
        {(props) => (
          <Popover
            {...props}
            className={`shadow ${props.className ?? ""}`}
            style={{
              ...(props.style || {}),
              width: "min(600px,95vw)",
              maxWidth: "none",
            }}
          >
            <Popover.Header className="d-flex align-items-center justify-content-between">
              <div className="fw-semibold">Chọn ngày trả</div>
              <CloseButton onClick={() => setShowDropDate(false)} />
            </Popover.Header>
            <Popover.Body>
              <CalendarSingle
                value={dateDrop}
                onPick={setDateDrop}
                onDone={() => setShowDropDate(false)}
              />
            </Popover.Body>
          </Popover>
        )}
      </Overlay>

      {/* Overlay: chọn giờ */}
      {timePanel && timeAnchor && (
        <Overlay
          target={timeAnchor}
          show
          placement="bottom-start"
          rootClose
          container={wrapRef.current}
          popperConfig={popperConfig}
          onHide={() => {
            setTimePanel(null);
            setTimeAnchor(null);
          }}
        >
          {(props) => (
            <Popover
              {...props}
              className={`shadow ${props.className ?? ""}`}
              style={{
                ...(props.style || {}),
                width: "220px",
                maxWidth: "95vw",
              }}
            >
              <Popover.Header className="d-flex align-items-center justify-content-between">
                <div className="fw-semibold">Chọn thời gian</div>
                <CloseButton
                  onClick={() => {
                    setTimePanel(null);
                    setTimeAnchor(null);
                  }}
                />
              </Popover.Header>
              <Popover.Body className="p-0">
                <div style={{ maxHeight: 260, overflowY: "auto" }}>
                  {timeSlots.map((slot) => {
                    const isActive =
                      (timePanel === "pick" && slot.value === timePick) ||
                      (timePanel === "drop" && slot.value === timeDrop);
                    return (
                      <button
                        key={slot.value}
                        type="button"
                        className={`w-100 text-start btn btn-sm border-0 rounded-0 ${
                          isActive ? "btn-primary text-white" : "btn-light"
                        }`}
                        style={{ borderBottom: "1px solid #eee" }}
                        onClick={() => {
                          if (timePanel === "pick") setTimePick(slot.value);
                          else setTimeDrop(slot.value);
                          setTimePanel(null);
                          setTimeAnchor(null);
                        }}
                      >
                        {slot.label}
                      </button>
                    );
                  })}
                </div>
              </Popover.Body>
            </Popover>
          )}
        </Overlay>
      )}
    </section>
  );
}
