import React, { useMemo, useRef, useState } from "react";
import Button from "react-bootstrap/Button";
import Overlay from "react-bootstrap/Overlay";
import Popover from "react-bootstrap/Popover";
import Form from "react-bootstrap/Form";
import CloseButton from "react-bootstrap/CloseButton";

const DEFAULT_POPULAR = [
  { name: "TP. Hồ Chí Minh", subtitle: "Việt Nam" },
  { name: "Nha Trang", subtitle: "Việt Nam" },
  { name: "Hà Nội", subtitle: "Việt Nam" },
  { name: "Đà Nẵng", subtitle: "Việt Nam" },
  { name: "Vũng Tàu", subtitle: "Việt Nam" },
];

function fmtDate(d) {
  if (!d) return "";
  return d.toLocaleDateString("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
}
function sameDate(a, b) {
  return !!a && !!b && a.toDateString() === b.toDateString();
}
function isBetween(d, start, end) {
  if (!start || !end) return false;
  const x = +new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const s = +new Date(start.getFullYear(), start.getMonth(), start.getDate());
  const e = +new Date(end.getFullYear(), end.getMonth(), end.getDate());
  return x > s && x < e;
}

function buildMonth(year, month) {
  const first = new Date(year, month, 1);
  const startIdx = (first.getDay() + 6) % 7;
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const cells = [];
  for (let i = 0; i < startIdx; i++) {
    const d = new Date(year, month, 1 - (startIdx - i));
    cells.push({ date: d, inMonth: false });
  }
  for (let d = 1; d <= daysInMonth; d++)
    cells.push({ date: new Date(year, month, d), inMonth: true });
  while (cells.length % 7 !== 0)
    cells.push({
      date: new Date(year, month + 1, cells.length % 7),
      inMonth: false,
    });
  while (cells.length < 42) {
    const last = cells[cells.length - 1].date;
    cells.push({
      date: new Date(last.getFullYear(), last.getMonth(), last.getDate() + 1),
      inMonth: false,
    });
  }
  return cells;
}

function CalendarRange({ value, onChange, onDone }) {
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

  function pick(date) {
    const { start, end } = value;
    if (!start || (start && end)) {
      onChange({ start: date, end: undefined });
    } else if (start && !end) {
      if (date >= start) onChange({ start, end: date });
      else onChange({ start: date, end: undefined });
    }
  }

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
        <div className="fw-semibold">Chọn khoảng ngày</div>
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
                  const isStart = sameDate(date, value.start);
                  const isEnd = sameDate(date, value.end);
                  const between = isBetween(date, value.start, value.end);
                  const disabled =
                    !inMonth ||
                    date <
                      new Date(
                        today.getFullYear(),
                        today.getMonth(),
                        today.getDate()
                      );
                  const cls = [
                    "small",
                    "text-center",
                    "py-2",
                    "rounded-2",
                    disabled ? "text-muted" : "cursor-pointer",
                    (isStart || isEnd) && "bg-primary text-white",
                    between && "bg-primary bg-opacity-10",
                  ]
                    .filter(Boolean)
                    .join(" ");

                  return (
                    <div
                      key={i}
                      className={cls}
                      style={{ userSelect: "none" }}
                      onClick={() => !disabled && pick(date)}
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
          Nhận phòng: <strong>{fmtDate(value.start) || "--"}</strong>{" "}
          &nbsp;–&nbsp; Trả phòng: <strong>{fmtDate(value.end) || "--"}</strong>
        </div>
        <div className="d-flex gap-2">
          <Button
            variant="light"
            size="sm"
            onClick={() => onChange({ start: undefined, end: undefined })}
          >
            Xoá
          </Button>
          <Button
            variant="primary"
            size="sm"
            onClick={() => onDone && onDone()}
          >
            Xong
          </Button>
        </div>
      </div>
    </div>
  );
}

export default function HotelSearch({
  onSearch,
  popular = DEFAULT_POPULAR,
  className,
}) {
  const wrapRef = useRef(null);
  const popularList = popular || DEFAULT_POPULAR;
  const [destination, setDestination] = useState("");
  const [recent, setRecent] = useState([]);
  const [range, setRange] = useState({});
  const [adults, setAdults] = useState(2);
  const [children, setChildren] = useState(0);
  const [rooms, setRooms] = useState(1);
  const [pets, setPets] = useState(false);

  const destRef = useRef(null);
  const dateRef = useRef(null);
  const guestsRef = useRef(null);

  const [showDest, setShowDest] = useState(false);
  const [showDates, setShowDates] = useState(false);
  const [showGuests, setShowGuests] = useState(false);

  const guestsLabel = useMemo(
    () => `${adults} người lớn · ${children} trẻ em · ${rooms} phòng`,
    [adults, children, rooms]
  );
  const dateLabel = useMemo(() => {
    if (!range.start || !range.end) return "Ngày nhận phòng — Ngày trả phòng";
    return `${fmtDate(range.start)} — ${fmtDate(range.end)}`;
  }, [range]);

  function submit() {
    onSearch &&
      onSearch({
        destination,
        checkIn: range.start,
        checkOut: range.end,
        adults,
        children,
        rooms,
        pets,
      });
    if (destination) {
      setRecent([
        { name: destination, note: guestsLabel },
        ...recent.slice(0, 4),
      ]);
    }
  }

  return (
    <div ref={wrapRef} className={`gv-search p-2 rounded-3 ${className || ""}`}>
      <div className="row g-2 align-items-stretch">
        {/* Destination */}
        <div className="col-12 col-lg">
          <div
            ref={destRef}
            className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
            role="button"
            onClick={() => {
              setShowDest(true);
              setShowDates(false);
              setShowGuests(false);
            }}
          >
            <i className="bi bi-building fs-5 me-2" />
            <div className="text-truncate">
              <div className="text-muted small">
                Tên thành phố, khách sạn hoặc địa điểm
              </div>
              <div className={destination ? "" : "text-muted"}>
                {destination || "Bạn muốn đến đâu?"}
              </div>
            </div>
          </div>
        </div>

        {/* Dates */}
        <div className="col-12 col-md-6 col-lg">
          <div
            ref={dateRef}
            className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
            role="button"
            onClick={() => {
              setShowDates(true);
              setShowDest(false);
              setShowGuests(false);
            }}
          >
            <i className="bi bi-calendar3 fs-5 me-2" />
            <div className="text-truncate">
              <div className="text-muted small">
                Ngày nhận phòng và trả phòng
              </div>
              <div className={range.start && range.end ? "" : "text-muted"}>
                {dateLabel}
              </div>
            </div>
          </div>
        </div>

        {/* Guests */}
        <div className="col-12 col-md-6 col-lg">
          <div
            ref={guestsRef}
            className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
            role="button"
            onClick={() => {
              setShowGuests(true);
              setShowDest(false);
              setShowDates(false);
            }}
          >
            <i className="bi bi-person fs-5 me-2" />
            <div className="text-truncate">
              <div className="text-muted small">Khách và Phòng</div>
              <div className="d-flex align-items-center gap-1 text-truncate">
                <span>{guestsLabel}</span>
                {pets && (
                  <span aria-label="Có thú cưng" title="Có thú cưng">
                    🐱
                  </span>
                )}
              </div>
            </div>
            <i className="bi bi-caret-down-fill ms-auto" />
          </div>
        </div>

        {/* Search button */}
        <div className="col-12 col-lg-auto">
          <Button
            variant="primary"
            className="w-100 w-lg-auto h-100 px-4 py-2 rounded-3 d-flex align-items-center justify-content-center btn-teal"
            disabled={!destination || !range.start || !range.end}
            onClick={submit}
          >
            Tìm
          </Button>
        </div>
      </div>

      {/* Destination panel */}
      <Overlay
        target={destRef.current}
        show={showDest}
        placement="bottom-start"
        rootClose
        container={wrapRef.current}
        popperConfig={{
          strategy: "absolute",
          modifiers: [
            { name: "offset", options: { offset: [0, 8] } },
            {
              name: "preventOverflow",
              options: { boundary: wrapRef.current || undefined },
            },
          ],
        }}
        onHide={() => setShowDest(false)}
      >
        {(props) => (
          <Popover
            {...props}
            className={`shadow ${props.className ?? ""}`}
            style={{
              ...(props.style || {}),
              minWidth: "min(420px, 92vw)",
              zIndex: 1080,
              maxWidth: "none",
            }}
          >
            <Popover.Header className="d-flex align-items-center justify-content-between">
              <div className="fw-semibold">Tìm kiếm địa điểm</div>
              <CloseButton onClick={() => setShowDest(false)} />
            </Popover.Header>
            <Popover.Body>
              <Form.Control
                autoFocus
                placeholder="Nhập thành phố, khách sạn…"
                value={destination}
                onChange={(e) => setDestination(e.target.value)}
                className="mb-3"
              />

              {!!recent.length && (
                <>
                  <div className="fw-semibold mb-2">
                    Tìm kiếm gần đây của bạn
                  </div>
                  <div className="list-group mb-3">
                    {recent.map((r, i) => (
                      <button
                        key={i}
                        className="list-group-item list-group-item-action d-flex gap-2 align-items-center"
                        onClick={() => {
                          setDestination(r.name);
                          setShowDest(false);
                        }}
                      >
                        <i className="bi bi-clock-history" />
                        <div>
                          <div className="fw-semibold">{r.name}</div>
                          {r.note && (
                            <div className="text-muted small">{r.note}</div>
                          )}
                        </div>
                      </button>
                    ))}
                  </div>
                </>
              )}

              <div className="fw-semibold mb-2">Các điểm đến thịnh hành</div>
              <div className="list-group">
                {popularList.map((p, i) => (
                  <button
                    key={i}
                    className="list-group-item list-group-item-action d-flex gap-2 align-items-center"
                    onClick={() => {
                      setDestination(p.name);
                      setShowDest(false);
                    }}
                  >
                    <i className="bi bi-geo-alt" />
                    <div>
                      <div className="fw-semibold">{p.name}</div>
                      {p.subtitle && (
                        <div className="text-muted small">{p.subtitle}</div>
                      )}
                    </div>
                  </button>
                ))}
              </div>
            </Popover.Body>
          </Popover>
        )}
      </Overlay>

      {/* Dates panel */}
      <Overlay
        target={dateRef.current}
        show={showDates}
        placement="bottom-start"
        rootClose
        container={wrapRef.current}
        popperConfig={{
          strategy: "absolute",
          modifiers: [
            { name: "offset", options: { offset: [0, 8] } },
            {
              name: "preventOverflow",
              options: { boundary: wrapRef.current || undefined },
            },
          ],
        }}
        onHide={() => setShowDates(false)}
      >
        {(props) => (
          <Popover
            {...props}
            className={`shadow ${props.className ?? ""}`}
            id="date-pop"
            style={{
              ...(props.style || {}),
              maxWidth: "none",
              width: "min(600px, 95vw)",
            }}
          >
            <Popover.Header className="d-flex align-items-center justify-content-between">
              <div className="fw-semibold">Ngày ở</div>
              <CloseButton onClick={() => setShowDates(false)} />
            </Popover.Header>
            <Popover.Body>
              <CalendarRange
                value={range}
                onChange={setRange}
                onDone={() => setShowDates(false)}
              />
            </Popover.Body>
          </Popover>
        )}
      </Overlay>

      {/* Guests panel */}
      <Overlay
        target={guestsRef.current}
        show={showGuests}
        placement="bottom"
        rootClose
        container={wrapRef.current}
        popperConfig={{
          strategy: "absolute",
          modifiers: [
            { name: "offset", options: { offset: [0, 8] } },
            {
              name: "preventOverflow",
              options: { boundary: wrapRef.current || undefined },
            },
          ],
        }}
        onHide={() => setShowGuests(false)}
      >
        {(props) => (
          <Popover
            {...props}
            className={`shadow ${props.className ?? ""}`}
            id="guests-pop"
            style={{
              ...(props.style || {}),
              minWidth: "min(360px, 92vw)",
              maxWidth: "none",
            }}
          >
            <Popover.Header className="d-flex align-items-center justify-content-between">
              <div className="fw-semibold">Khách và Phòng</div>
              <CloseButton onClick={() => setShowGuests(false)} />
            </Popover.Header>
            <Popover.Body>
              {[
                {
                  label: "Người lớn",
                  val: adults,
                  set: setAdults,
                  min: 1,
                },
                {
                  label: "Trẻ em",
                  val: children,
                  set: setChildren,
                  min: 0,
                },
                {
                  label: "Phòng",
                  val: rooms,
                  set: setRooms,
                  min: 1,
                },
              ].map((row) => (
                <div
                  key={row.label}
                  className="d-flex align-items-center justify-content-between mb-2"
                >
                  <div className="fw-semibold">{row.label}</div>
                  <div className="d-flex align-items-center gap-2">
                    <Button
                      variant="light"
                      onClick={() => row.set(Math.max(row.min, row.val - 1))}
                      disabled={row.val <= row.min}
                    >
                      –
                    </Button>
                    <div className="px-3 py-1 border rounded">{row.val}</div>
                    <Button
                      variant="light"
                      onClick={() => row.set(row.val + 1)}
                    >
                      +
                    </Button>
                  </div>
                </div>
              ))}

              <div className="d-flex align-items-center justify-content-between my-3">
                <div className="form-check form-switch m-0">
                  <Form.Check
                    type="switch"
                    id="pets"
                    label="Mang thú cưng đi cùng"
                    checked={pets}
                    onChange={(e) => setPets(e.currentTarget.checked)}
                  />
                </div>
              </div>

              <div className="d-grid">
                <Button variant="primary" onClick={() => setShowGuests(false)}>
                  Xong
                </Button>
              </div>
            </Popover.Body>
          </Popover>
        )}
      </Overlay>
    </div>
  );
}
