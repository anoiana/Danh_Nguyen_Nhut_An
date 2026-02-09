import React, { useMemo, useRef, useState } from "react";
import Button from "react-bootstrap/Button";
import Overlay from "react-bootstrap/Overlay";
import Popover from "react-bootstrap/Popover";
import Form from "react-bootstrap/Form";
import CloseButton from "react-bootstrap/CloseButton";
// import "../../styles/home.css"; // Bỏ comment nếu bạn cần style riêng

function fmtDate(d) {
  if (!d) return "";
  return d.toLocaleDateString("vi-VN", {
    weekday: "short",
    day: "2-digit",
    month: "2-digit",
  });
}

function fmtDateTime(d) {
  if (!d) return "";
  const dateStr = fmtDate(d);
  const hh = String(d.getHours()).padStart(2, "0");
  const mm = String(d.getMinutes()).padStart(2, "0");
  return `${dateStr}, ${hh}:${mm}`;
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

function CalendarSingle({ value, onPick, onDone }) {
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
        <div className="fw-semibold">Chọn ngày</div>
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

export default function TaxiAirportSearch({ onSearch, className }) {
  const wrapRef = useRef(null);

  const [oneWay, setOneWay] = useState(true);
  const [pickup, setPickup] = useState("");
  const [destination, setDestination] = useState("");

  const [departDate, setDepartDate] = useState(undefined);
  const [departTime, setDepartTime] = useState("12:00");
  const [returnDate, setReturnDate] = useState(undefined);
  const [returnTime, setReturnTime] = useState("12:00");

  const [passengers, setPassengers] = useState(2);

  const pickupRef = useRef(null);
  const destRef = useRef(null);
  const departRef = useRef(null);
  const returnRef = useRef(null);
  const paxRef = useRef(null);

  const [showPickup, setShowPickup] = useState(false);
  const [showDest, setShowDest] = useState(false);
  const [showDepart, setShowDepart] = useState(false);
  const [showReturn, setShowReturn] = useState(false);
  const [showPax, setShowPax] = useState(false);

  const departLabel = useMemo(() => {
    if (!departDate) return "Chọn ngày đi";
    const [h, m] = departTime.split(":");
    const d = new Date(departDate);
    d.setHours(Number(h), Number(m), 0, 0);
    return fmtDateTime(d);
  }, [departDate, departTime]);

  const returnLabel = useMemo(() => {
    if (!returnDate) return "Thêm ngày về";
    const [h, m] = returnTime.split(":");
    const d = new Date(returnDate);
    d.setHours(Number(h), Number(m), 0, 0);
    return fmtDateTime(d);
  }, [returnDate, returnTime]);

  function submit() {
    const depart = departDate
      ? new Date(
          departDate.getFullYear(),
          departDate.getMonth(),
          departDate.getDate(),
          Number(departTime.split(":")[0]),
          Number(departTime.split(":")[1])
        )
      : undefined;

    const ret =
      !oneWay && returnDate
        ? new Date(
            returnDate.getFullYear(),
            returnDate.getMonth(),
            returnDate.getDate(),
            Number(returnTime.split(":")[0]),
            Number(returnTime.split(":")[1])
          )
        : undefined;

    onSearch &&
      onSearch({
        oneWay,
        pickup,
        destination,
        departAt: depart,
        returnAt: ret,
        passengers,
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
      className={`gv-search p-3 rounded-3 bg-light ${className || ""}`}
    >
      {/* Trip type */}
      <div className="mb-2 d-flex gap-3">
        <Form.Check
          type="radio"
          id="taxi-one-way"
          name="taxi-trip-type"
          label="Một chiều"
          checked={oneWay}
          onChange={() => setOneWay(true)}
        />
        <Form.Check
          type="radio"
          id="taxi-return"
          name="taxi-trip-type"
          label="Khứ hồi"
          checked={!oneWay}
          onChange={() => setOneWay(false)}
        />
      </div>

      {/* Main row */}
      <div className="border border-warning rounded-3 bg-white overflow-hidden">
        <div className="d-grid align-items-stretch taxi-search-grid">
          {/* Pick-up */}
          <div className="border-end">
            <div
              ref={pickupRef}
              role="button"
              className="h-100 d-flex align-items-center px-2 py-2"
              onClick={() => {
                setShowPickup(true);
                setShowDest(false);
              }}
            >
              <div className="text-truncate">
                <div className="text-muted small">Nhập điểm đón</div>
                <div className={pickup ? "" : "text-muted"}>
                  {pickup || "Sân bay, Nhà ga..."}
                </div>
              </div>
            </div>
          </div>

          {/* Swap + destination */}
          <div className="border-end">
            <div className="h-100 d-flex">
              <div className="d-flex align-items-center px-2 border-end">
                <i className="bi bi-arrow-left-right" />
              </div>
              <div
                ref={destRef}
                role="button"
                className="flex-grow-1 d-flex align-items-center px-2 py-2"
                onClick={() => {
                  setShowDest(true);
                  setShowPickup(false);
                }}
              >
                <div className="text-truncate">
                  <div className="text-muted small">Nhập điểm đến</div>
                  <div className={destination ? "" : "text-muted"}>
                    {destination || "Khách sạn, Địa chỉ..."}
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Depart */}
          <div className="border-end">
            <div
              ref={departRef}
              role="button"
              className="h-100 d-flex align-items-center px-2 py-2"
              onClick={() => {
                setShowDepart(true);
                setShowReturn(false);
              }}
            >
              <i className="bi bi-calendar3 fs-5 me-2" />
              <div className="text-truncate">
                <div className="text-muted small">Ngày đi</div>
                <div className={departDate ? "" : "text-muted"}>
                  {departLabel}
                </div>
              </div>
            </div>
          </div>

          {/* Return */}
          <div className="border-end">
            <div
              ref={returnRef}
              role="button"
              className="h-100 d-flex align-items-center px-2 py-2"
              onClick={() => {
                setOneWay(false);
                setShowReturn(true);
                setShowDepart(false);
              }}
            >
              <i className="bi bi-calendar3 fs-5 me-2" />
              <div className="text-truncate">
                <div className="text-muted small">
                  {oneWay && !returnDate ? "Thêm ngày về" : "Ngày về"}
                </div>
                <div className={returnDate ? "" : "text-muted"}>
                  {returnLabel}
                </div>
              </div>
            </div>
          </div>

          {/* Passengers */}
          <div className="border-end">
            <div
              ref={paxRef}
              role="button"
              className="h-100 d-flex align-items-center px-2 py-2"
              onClick={() => setShowPax(true)}
            >
              <i className="bi bi-person fs-5 me-2" />
              <div className="me-2">
                <div className="text-muted small">Hành khách</div>
                <div className="text-truncate">{passengers} người</div>
              </div>
              <i className="bi bi-caret-down-fill ms-auto" />
            </div>
          </div>

          {/* Search */}
          <div className="d-flex">
            <Button
              variant="primary"
              className="h-100 w-100 border-0 rounded-0 rounded-end-3 d-flex align-items-center justify-content-center"
              disabled={!pickup || !destination || !departDate}
              onClick={submit}
            >
              Tìm xe
            </Button>
          </div>
        </div>
      </div>

      {/* Overlays (Đã Việt hóa tiêu đề) */}

      {/* pickup */}
      <Overlay
        target={pickupRef.current}
        show={showPickup}
        placement="bottom-start"
        rootClose
        container={wrapRef.current}
        popperConfig={popperConfig}
        onHide={() => setShowPickup(false)}
      >
        {(props) => (
          <Popover
            {...props}
            className={`shadow ${props.className ?? ""}`}
            style={{
              ...(props.style || {}),
              minWidth: "min(420px, 92vw)",
              maxWidth: "none",
            }}
          >
            <Popover.Header className="d-flex align-items-center justify-content-between">
              <div className="fw-semibold">Chọn điểm đón</div>
              <CloseButton onClick={() => setShowPickup(false)} />
            </Popover.Header>
            <Popover.Body>
              <Form.Control
                autoFocus
                placeholder="Nhập sân bay, nhà ga, địa chỉ..."
                value={pickup}
                onChange={(e) => setPickup(e.target.value)}
              />
            </Popover.Body>
          </Popover>
        )}
      </Overlay>

      {/* destination */}
      <Overlay
        target={destRef.current}
        show={showDest}
        placement="bottom-start"
        rootClose
        container={wrapRef.current}
        popperConfig={popperConfig}
        onHide={() => setShowDest(false)}
      >
        {(props) => (
          <Popover
            {...props}
            className={`shadow ${props.className ?? ""}`}
            style={{
              ...(props.style || {}),
              minWidth: "min(420px, 92vw)",
              maxWidth: "none",
            }}
          >
            <Popover.Header className="d-flex align-items-center justify-content-between">
              <div className="fw-semibold">Chọn điểm đến</div>
              <CloseButton onClick={() => setShowDest(false)} />
            </Popover.Header>
            <Popover.Body>
              <Form.Control
                autoFocus
                placeholder="Nhập địa chỉ, khách sạn..."
                value={destination}
                onChange={(e) => setDestination(e.target.value)}
              />
            </Popover.Body>
          </Popover>
        )}
      </Overlay>

      {/* depart date/time */}
      <Overlay
        target={departRef.current}
        show={showDepart}
        placement="bottom-start"
        rootClose
        container={wrapRef.current}
        popperConfig={popperConfig}
        onHide={() => setShowDepart(false)}
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
              <div className="fw-semibold">Ngày & Giờ đi</div>
              <CloseButton onClick={() => setShowDepart(false)} />
            </Popover.Header>
            <Popover.Body>
              <CalendarSingle
                value={departDate}
                onPick={setDepartDate}
                onDone={() => setShowDepart(false)}
              />
              <div className="mt-3 d-flex align-items-center gap-2">
                <span>Thời gian:</span>
                <Form.Control
                  type="time"
                  value={departTime}
                  onChange={(e) => setDepartTime(e.target.value)}
                  style={{ width: 120 }}
                />
              </div>
            </Popover.Body>
          </Popover>
        )}
      </Overlay>

      {/* return date/time */}
      <Overlay
        target={returnRef.current}
        show={showReturn}
        placement="bottom-start"
        rootClose
        container={wrapRef.current}
        popperConfig={popperConfig}
        onHide={() => setShowReturn(false)}
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
              <div className="fw-semibold">Ngày & Giờ về</div>
              <CloseButton onClick={() => setShowReturn(false)} />
            </Popover.Header>
            <Popover.Body>
              <CalendarSingle
                value={returnDate}
                onPick={setReturnDate}
                onDone={() => setShowReturn(false)}
              />
              <div className="mt-3 d-flex align-items-center gap-2">
                <span>Thời gian:</span>
                <Form.Control
                  type="time"
                  value={returnTime}
                  onChange={(e) => setReturnTime(e.target.value)}
                  style={{ width: 120 }}
                />
              </div>
            </Popover.Body>
          </Popover>
        )}
      </Overlay>

      {/* passengers */}
      <Overlay
        target={paxRef.current}
        show={showPax}
        placement="bottom-start"
        rootClose
        container={wrapRef.current}
        popperConfig={popperConfig}
        onHide={() => setShowPax(false)}
      >
        {(props) => (
          <Popover
            {...props}
            className={`shadow ${props.className ?? ""}`}
            style={{
              ...(props.style || {}),
              minWidth: "min(260px, 90vw)",
              maxWidth: "none",
            }}
          >
            <Popover.Header className="d-flex align-items-center justify-content-between">
              <div className="fw-semibold">Số hành khách</div>
              <CloseButton onClick={() => setShowPax(false)} />
            </Popover.Header>
            <Popover.Body>
              <div className="d-flex align-items-center justify-content-between mb-2">
                <div className="fw-semibold">Hành khách</div>
                <div className="d-flex align-items-center gap-2">
                  <Button
                    variant="light"
                    onClick={() => setPassengers(Math.max(1, passengers - 1))}
                    disabled={passengers <= 1}
                  >
                    –
                  </Button>
                  <div className="px-3 py-1 border rounded">{passengers}</div>
                  <Button
                    variant="light"
                    onClick={() => setPassengers(passengers + 1)}
                  >
                    +
                  </Button>
                </div>
              </div>
              <div className="d-grid">
                <Button variant="primary" onClick={() => setShowPax(false)}>
                  Xong
                </Button>
              </div>
            </Popover.Body>
          </Popover>
        )}
      </Overlay>
    </section>
  );
}