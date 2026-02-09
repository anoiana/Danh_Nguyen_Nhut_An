import React, { useMemo, useRef, useState } from "react";
import Button from "react-bootstrap/Button";
import Overlay from "react-bootstrap/Overlay";
import Popover from "react-bootstrap/Popover";
import Dropdown from "react-bootstrap/Dropdown";
import Form from "react-bootstrap/Form";
import CloseButton from "react-bootstrap/CloseButton";

/* ===== Helpers: date ===== */
function fmtDate(d) {
  if (!d) return "";
  return d.toLocaleDateString("vi-VN", {
    weekday: "short",
    day: "2-digit",
    month: "long",
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
  const startIdx = (first.getDay() + 6) % 7; // Mon-first
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const cells = [];
  for (let i = 0; i < startIdx; i++)
    cells.push({
      date: new Date(year, month, 1 - (startIdx - i)),
      inMonth: false,
    });
  for (let d = 1; d <= daysInMonth; d++)
    cells.push({ date: new Date(year, month, d), inMonth: true });
  while (cells.length % 7 !== 0)
    cells.push({
      date: new Date(year, month + 1, cells.length % 7),
      inMonth: false,
    });
  while (cells.length < 42) {
    const last = cells[cells.length - 1].date;
    cells.push(
      new Object({
        date: new Date(last.getFullYear(), last.getMonth(), last.getDate() + 1),
        inMonth: false,
      })
    );
  }
  return cells;
}

function CalendarRange({ value, onChange, onDone, title = "Ngày bay" }) {
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
    if (!start || (start && end)) onChange({ start: date, end: undefined });
    else if (start && !end)
      onChange(
        date >= start ? { start, end: date } : { start: date, end: undefined }
      );
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
                    "small text-center py-2 rounded-2",
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
          Đi: <strong>{fmtDate(value.start) || "--"}</strong>
          {value.end && (
            <>
              {" "}
              &nbsp;–&nbsp; Về: <strong>{fmtDate(value.end)}</strong>
            </>
          )}
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

/* ===== Airports data (mẫu) ===== */
const VIETNAM_AIRPORTS = [
  {
    code: "SGN",
    city: "TP. Hồ Chí Minh",
    name: "Sân bay Quốc tế Tân Sơn Nhất",
    country: "Việt Nam",
    region: "Châu Á",
  },
  {
    code: "HAN",
    city: "Hà Nội",
    name: "Sân bay Quốc tế Nội Bài",
    country: "Việt Nam",
    region: "Châu Á",
  },
  {
    code: "DAD",
    city: "Đà Nẵng",
    name: "Sân bay Quốc tế Đà Nẵng",
    country: "Việt Nam",
    region: "Châu Á",
  },
  {
    code: "PQC",
    city: "Phú Quốc",
    name: "Sân bay Quốc tế Phú Quốc",
    country: "Việt Nam",
    region: "Châu Á",
  },
  {
    code: "HPH",
    city: "Hải Phòng",
    name: "Sân bay Cát Bi",
    country: "Việt Nam",
    region: "Châu Á",
  },
  {
    code: "HUI",
    city: "Huế",
    name: "Sân bay Phú Bài",
    country: "Việt Nam",
    region: "Châu Á",
  },
  {
    code: "DLI",
    city: "Đà Lạt",
    name: "Sân bay Liên Khương",
    country: "Việt Nam",
    region: "Châu Á",
  },
  {
    code: "UIH",
    city: "Quy Nhơn",
    name: "Sân bay Phù Cát",
    country: "Việt Nam",
    region: "Châu Á",
  },
  {
    code: "VDO",
    city: "Quảng Ninh",
    name: "Sân bay Vân Đồn",
    country: "Việt Nam",
    region: "Châu Á",
  },
];

/* ===== Component ===== */
export default function PlaneSearch({ onSearch, className }) {
  const wrapRef = useRef(null);

  // Top options
  const [tripType, setTripType] = useState("roundtrip"); // "roundtrip" | "oneway" | "multicity"
  const [cabin, setCabin] = useState("economy"); // "economy" | ...
  const [directOnly, setDirectOnly] = useState(false);

  // Single/roundtrip
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [range, setRange] = useState({});

  // Multi city
  const [segments, setSegments] = useState([
    { from: "", to: "", date: undefined },
    { from: "", to: "", date: undefined },
  ]);

  // Pax
  const [adults, setAdults] = useState(1);
  const [children, setChildren] = useState(0);

  // Overlay state
  const [anchor, setAnchor] = useState(null);
  const [panel, setPanel] = useState(null); // "from" | "to" | "date" | "pax"
  const [activeIndex, setActiveIndex] = useState(0); // for multicity

  // search box in panels
  const [airportQuery, setAirportQuery] = useState("");

  const dateLabel = useMemo(() => {
    if (!range.start) return "Chọn ngày";
    if (tripType === "oneway") return fmtDate(range.start);
    return `${fmtDate(range.start)} - ${
      range.end ? fmtDate(range.end) : "ngày về?"
    }`;
  }, [range, tripType]);

  const paxLabel = useMemo(
    () => `${adults} người lớn${children ? `, ${children} trẻ em` : ""}`,
    [adults, children]
  );

  function swapSingle() {
    setFrom(to);
    setTo(from);
  }
  function swapSegment(i) {
    setSegments((s) => {
      const next = [...s];
      const seg = { ...next[i] };
      [seg.from, seg.to] = [seg.to, seg.from];
      next[i] = seg;
      return next;
    });
  }

  function addSegment() {
    setSegments((s) => [...s, { from: "", to: "", date: undefined }]);
  }
  function removeSegment(idx) {
    setSegments((s) => (s.length <= 2 ? s : s.filter((_, i) => i !== idx)));
  }

  function submit() {
    if (tripType === "multicity") {
      onSearch &&
        onSearch({
          tripType: "multicity",
          segments,
          paxAdults: adults,
          paxChildren: children,
          cabin,
        });
      return;
    }
    onSearch &&
      onSearch({
        tripType,
        from,
        to,
        depart: range.start,
        return: tripType === "oneway" ? undefined : range.end,
        paxAdults: adults,
        paxChildren: children,
        cabin,
        directOnly,
      });
  }

  function filterAirports(q) {
    const s = q.trim().toLowerCase();
    if (!s) return VIETNAM_AIRPORTS;
    return VIETNAM_AIRPORTS.filter(
      (a) =>
        a.city.toLowerCase().includes(s) ||
        a.name.toLowerCase().includes(s) ||
        a.code.toLowerCase().includes(s) ||
        a.country.toLowerCase().includes(s)
    );
  }

  function renderAirportRow(a, selected, onPick) {
    return (
      <button
        key={a.code}
        className="list-group-item list-group-item-action d-flex align-items-start gap-2"
        onClick={onPick}
      >
        <i className="bi bi-airplane-engines mt-1" />
        <div className="flex-grow-1 text-start">
          <div className="fw-semibold">
            {a.code} <span className="fw-normal">{a.name}</span>
          </div>
          <div className="text-muted small">
            {a.city}, {a.country}
          </div>
        </div>
        <Form.Check
          type="checkbox"
          readOnly
          checked={selected}
          className="ms-2 mt-1"
        />
      </button>
    );
  }

  return (
    <section
      ref={wrapRef}
      className={`gv-search p-2 rounded-3 ${className || ""}`}
    >
      {/* Top row options */}
      <div className="d-flex flex-wrap align-items-center gap-3 px-2 pb-2">
        <div className="d-flex align-items-center gap-3">
          <Form.Check
            inline
            type="radio"
            label="Khứ hồi"
            name="trip"
            checked={tripType === "roundtrip"}
            onChange={() => setTripType("roundtrip")}
          />
          <Form.Check
            inline
            type="radio"
            label="Một chiều"
            name="trip"
            checked={tripType === "oneway"}
            onChange={() => setTripType("oneway")}
          />
          <Form.Check
            inline
            type="radio"
            label="Nhiều chặng"
            name="trip"
            checked={tripType === "multicity"}
            onChange={() => setTripType("multicity")}
          />
        </div>

        <Dropdown>
          <Dropdown.Toggle variant="light" className="border rounded-pill px-3">
            {cabin === "economy" && "Hạng phổ thông"}
            {cabin === "premium_economy" && "Phổ thông đặc biệt"}
            {cabin === "business" && "Thương gia"}
            {cabin === "first" && "Hạng nhất"}
          </Dropdown.Toggle>
          <Dropdown.Menu>
            <Dropdown.Item onClick={() => setCabin("economy")}>
              Hạng phổ thông
            </Dropdown.Item>
            <Dropdown.Item onClick={() => setCabin("premium_economy")}>
              Phổ thông đặc biệt
            </Dropdown.Item>
            <Dropdown.Item onClick={() => setCabin("business")}>
              Thương gia
            </Dropdown.Item>
            <Dropdown.Item onClick={() => setCabin("first")}>
              Hạng nhất
            </Dropdown.Item>
          </Dropdown.Menu>
        </Dropdown>

        {tripType !== "multicity" ? (
          <Form.Check
            type="checkbox"
            label="Chỉ tìm chuyến bay thẳng"
            checked={directOnly}
            onChange={(e) => setDirectOnly(e.currentTarget.checked)}
          />
        ) : (
          <div className="d-flex align-items-center gap-3">
            <div className="d-flex align-items-center gap-2">
              <span className="text-muted small">Người lớn</span>
              <div className="d-inline-flex align-items-center border rounded-3 px-2 py-1">
                <Button
                  variant="light"
                  size="sm"
                  onClick={() => setAdults(Math.max(1, adults - 1))}
                >
                  –
                </Button>
                <div className="px-3">{adults}</div>
                <Button
                  variant="light"
                  size="sm"
                  onClick={() => setAdults(adults + 1)}
                >
                  +
                </Button>
              </div>
            </div>
            <div className="d-flex align-items-center gap-2">
              <span className="text-muted small">Trẻ em</span>
              <div className="d-inline-flex align-items-center border rounded-3 px-2 py-1">
                <Button
                  variant="light"
                  size="sm"
                  onClick={() => setChildren(Math.max(0, children - 1))}
                >
                  –
                </Button>
                <div className="px-3">{children}</div>
                <Button
                  variant="light"
                  size="sm"
                  onClick={() => setChildren(children + 1)}
                >
                  +
                </Button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Main inputs */}
      {tripType !== "multicity" ? (
        <div className="row g-2 align-items-stretch">
          {/* From */}
          <div className="col-12 col-lg">
            <div
              className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
              role="button"
              onClick={(e) => {
                setAnchor(e.currentTarget);
                setPanel("from");
                setActiveIndex(0);
              }}
            >
              <i className="bi bi-airplane fs-5 me-2" />
              <div className="text-truncate">
                <div className="text-muted small">Bay từ</div>
                <div className={from ? "" : "text-muted"}>
                  {from || "Nhập sân bay / thành phố"}
                </div>
              </div>
            </div>
          </div>

          {/* Swap */}
          <div className="col-auto d-flex">
            <Button
              variant="light"
              className="rounded-3 d-flex align-items-center justify-content-center px-3"
              onClick={swapSingle}
              title="Đổi chiều"
            >
              <i className="bi bi-arrow-left-right"></i>
            </Button>
          </div>

          {/* To */}
          <div className="col-12 col-lg">
            <div
              className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
              role="button"
              onClick={(e) => {
                setAnchor(e.currentTarget);
                setPanel("to");
                setActiveIndex(0);
              }}
            >
              <i className="bi bi-signpost-2 fs-5 me-2" />
              <div className="text-truncate">
                <div className="text-muted small">Bay đến</div>
                <div className={to ? "" : "text-muted"}>
                  {to || "Nhập sân bay / thành phố"}
                </div>
              </div>
            </div>
          </div>

          {/* Dates */}
          <div className="col-12 col-md-6 col-lg">
            <div
              className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
              role="button"
              onClick={(e) => {
                setAnchor(e.currentTarget);
                setPanel("date");
                setActiveIndex(0);
              }}
            >
              <i className="bi bi-calendar3 fs-5 me-2" />
              <div className="text-truncate">
                <div className="text-muted small">Ngày bay</div>
                <div className={range.start ? "" : "text-muted"}>
                  {dateLabel}
                </div>
              </div>
            </div>
          </div>

          {/* Pax */}
          <div className="col-12 col-md-6 col-lg">
            <div
              className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
              role="button"
              onClick={(e) => {
                setAnchor(e.currentTarget);
                setPanel("pax");
              }}
            >
              <i className="bi bi-person fs-5 me-2" />
              <div className="text-truncate">
                <div className="text-muted small">Hành khách</div>
                <div>{paxLabel}</div>
              </div>
              <i className="bi bi-caret-down-fill ms-auto" />
            </div>
          </div>

          {/* Search button */}
          <div className="col-12 col-lg-auto">
            <Button
              variant="primary"
              className="w-100 w-lg-auto h-100 px-4 py-2 rounded-3 d-flex align-items-center justify-content-center btn-teal"
              disabled={
                !from ||
                !to ||
                !range.start ||
                (tripType === "roundtrip" && !range.end)
              }
              onClick={submit}
            >
              Khám phá
            </Button>
          </div>
        </div>
      ) : (
        <>
          {/* MULTICITY rows */}
          <div className="d-grid gap-2">
            {segments.map((seg, idx) => (
              <div key={idx} className="row g-2 align-items-stretch">
                {/* From */}
                <div className="col-12 col-lg">
                  <div
                    className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
                    role="button"
                    onClick={(e) => {
                      setAnchor(e.currentTarget);
                      setPanel("from");
                      setActiveIndex(idx);
                    }}
                  >
                    <i className="bi bi-airplane fs-5 me-2" />
                    <div className="text-truncate">
                      <div className="text-muted small">Bay từ</div>
                      <div className={seg.from ? "" : "text-muted"}>
                        {seg.from || "Nhập sân bay / thành phố"}
                      </div>
                    </div>
                  </div>
                </div>

                {/* Swap */}
                <div className="col-auto d-flex">
                  <Button
                    variant="light"
                    className="rounded-3 d-flex align-items-center justify-content-center px-3"
                    onClick={() => swapSegment(idx)}
                    title="Đổi chiều"
                  >
                    <i className="bi bi-arrow-left-right"></i>
                  </Button>
                </div>

                {/* To */}
                <div className="col-12 col-lg">
                  <div
                    className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
                    role="button"
                    onClick={(e) => {
                      setAnchor(e.currentTarget);
                      setPanel("to");
                      setActiveIndex(idx);
                    }}
                  >
                    <i className="bi bi-signpost-2 fs-5 me-2" />
                    <div className="text-truncate">
                      <div className="text-muted small">Bay đến</div>
                      <div className={seg.to ? "" : "text-muted"}>
                        {seg.to || "Nhập sân bay / thành phố"}
                      </div>
                    </div>
                  </div>
                </div>

                {/* Date */}
                <div className="col-12 col-lg">
                  <div
                    className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
                    role="button"
                    onClick={(e) => {
                      setAnchor(e.currentTarget);
                      setPanel("date");
                      setActiveIndex(idx);
                    }}
                  >
                    <i className="bi bi-calendar3 fs-5 me-2" />
                    <div className="text-truncate">
                      <div className="text-muted small">Ngày bay</div>
                      <div className={seg.date ? "" : "text-muted"}>
                        {seg.date ? fmtDate(seg.date) : "Ngày bay"}
                      </div>
                    </div>
                  </div>
                </div>

                {/* remove */}
                <div className="col-auto d-flex">
                  <Button
                    variant="light"
                    className="rounded-3 d-flex align-items-center justify-content-center px-3"
                    onClick={() => removeSegment(idx)}
                    disabled={segments.length <= 2}
                    title="Xoá"
                  >
                    <i className="bi bi-x-lg"></i>
                  </Button>
                </div>
              </div>
            ))}
          </div>

          {/* Add row + Search */}
          <div className="d-flex align-items-center justify-content-between mt-2">
            <Button
              variant="link"
              className="text-decoration-none"
              onClick={addSegment}
            >
              Thêm chuyến bay
            </Button>
            <Button
              variant="primary"
              className="px-4 btn-teal"
              disabled={segments.some((s) => !s.from || !s.to || !s.date)}
              onClick={submit}
            >
              Khám phá
            </Button>
          </div>
        </>
      )}

      {/* POPUPs */}
      {panel && anchor && (
        <Overlay
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
          target={anchor}
          show
          onHide={() => {
            setPanel(null);
            setAnchor(null);
          }}
        >
          {(props) => {
            if (!panel) return <span />;

            // Airport panels (from/to)
            if (panel === "from" || panel === "to") {
              const isTo = panel === "to";
              const countryHeader = (
                <div className="d-flex align-items-center justify-content-between py-1 px-1 text-muted">
                  <div>
                    <i className="bi bi-geo-alt me-2" />
                    Việt Nam <span className="small">— Châu Á</span>
                  </div>
                  <i className="bi bi-chevron-right"></i>
                </div>
              );

              const list = filterAirports(airportQuery);

              return (
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
                    <div className="fw-semibold">
                      Sân bay, thành phố hoặc quốc gia
                    </div>
                    <CloseButton
                      onClick={() => {
                        setPanel(null);
                        setAnchor(null);
                      }}
                    />
                  </Popover.Header>
                  <Popover.Body>
                    <Form.Control
                      placeholder="Việt Nam / SGN / Hồ Chí Minh…"
                      value={airportQuery}
                      onChange={(e) => setAirportQuery(e.target.value)}
                      className="mb-3"
                      autoFocus
                    />
                    {countryHeader}
                    <div className={`list-group ${isTo ? "mb-3" : ""}`}>
                      {list.map((a) =>
                        renderAirportRow(
                          a,
                          tripType !== "multicity"
                            ? (isTo ? to : from).includes(a.code) ||
                                (isTo ? to : from).includes(a.city)
                            : (isTo
                                ? segments[activeIndex]?.to
                                : segments[activeIndex]?.from
                              )?.includes(a.code) ||
                                (isTo
                                  ? segments[activeIndex]?.to
                                  : segments[activeIndex]?.from
                                )?.includes(a.city),
                          () => {
                            if (tripType !== "multicity") {
                              if (isTo) setTo(`${a.city} (${a.code})`);
                              else setFrom(`${a.city} (${a.code})`);
                            } else {
                              setSegments((s) => {
                                const next = [...s];
                                const seg = { ...next[activeIndex] };
                                if (isTo) seg.to = `${a.city} (${a.code})`;
                                else seg.from = `${a.city} (${a.code})`;
                                next[activeIndex] = seg;
                                return next;
                              });
                            }
                            setAirportQuery("");
                            setPanel(null);
                          }
                        )
                      )}
                    </div>

                    {isTo && (
                      <div className="mt-3">
                        <div className="text-muted small mb-2">
                          Khám phá các điểm đến
                        </div>
                        <button
                          className="list-group-item list-group-item-action d-flex align-items-center gap-2"
                          onClick={() => {
                            if (tripType !== "multicity")
                              setTo("Bất cứ nơi đâu");
                            else
                              setSegments((s) => {
                                const next = [...s];
                                next[activeIndex] = {
                                  ...next[activeIndex],
                                  to: "Bất cứ nơi đâu",
                                };
                                return next;
                              });
                            setAirportQuery("");
                            setPanel(null);
                          }}
                        >
                          <i className="bi bi-globe2" />
                          <span>Bất cứ nơi đâu</span>
                          <span className="badge text-bg-success ms-2">
                            Mới
                          </span>
                        </button>
                      </div>
                    )}
                  </Popover.Body>
                </Popover>
              );
            }

            // Date panel
            if (panel === "date") {
              return (
                <Popover
                  {...props}
                  className={`shadow ${props.className ?? ""}`}
                  style={{
                    ...(props.style || {}),
                    maxWidth: "none",
                    width: "min(600px,95vw)",
                  }}
                >
                  <Popover.Header className="d-flex align-items-center justify-content-between">
                    <div className="fw-semibold">Ngày bay</div>
                    <CloseButton
                      onClick={() => {
                        setPanel(null);
                        setAnchor(null);
                      }}
                    />
                  </Popover.Header>
                  <Popover.Body>
                    {tripType !== "multicity" ? (
                      <CalendarRange
                        value={range}
                        onChange={(v) => {
                          if (tripType === "oneway")
                            setRange({ start: v.start, end: undefined });
                          else setRange(v);
                        }}
                        onDone={() => setPanel(null)}
                        title="Chọn ngày"
                      />
                    ) : (
                      <CalendarRange
                        value={{
                          start: segments[activeIndex]?.date,
                          end: segments[activeIndex]?.date,
                        }}
                        onChange={(v) => {
                          const d = v.start;
                          setSegments((s) => {
                            const next = [...s];
                            next[activeIndex] = {
                              ...next[activeIndex],
                              date: d,
                            };
                            return next;
                          });
                        }}
                        onDone={() => setPanel(null)}
                        title="Chọn ngày"
                      />
                    )}
                  </Popover.Body>
                </Popover>
              );
            }

            // Pax (only non-multicity)
            return (
              <Popover
                {...props}
                className={`shadow ${props.className ?? ""}`}
                style={{
                  ...(props.style || {}),
                  minWidth: "min(360px,92vw)",
                  maxWidth: "none",
                }}
              >
                <Popover.Header className="d-flex align-items-center justify-content-between">
                  <div className="fw-semibold">Hành khách</div>
                  <CloseButton
                    onClick={() => {
                      setPanel(null);
                      setAnchor(null);
                    }}
                  />
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
                  ].map((row) => (
                    <div
                      key={row.label}
                      className="d-flex align-items-center justify-content-between mb-2"
                    >
                      <div className="fw-semibold">{row.label}</div>
                      <div className="d-flex align-items-center gap-2">
                        <Button
                          variant="light"
                          onClick={() =>
                            row.set(Math.max(row.min, row.val - 1))
                          }
                          disabled={row.val <= row.min}
                        >
                          –
                        </Button>
                        <div className="px-3 py-1 border rounded">
                          {row.val}
                        </div>
                        <Button
                          variant="light"
                          onClick={() => row.set(row.val + 1)}
                        >
                          +
                        </Button>
                      </div>
                    </div>
                  ))}
                  <div className="d-grid">
                    <Button variant="primary" onClick={() => setPanel(null)}>
                      Xong
                    </Button>
                  </div>
                </Popover.Body>
              </Popover>
            );
          }}
        </Overlay>
      )}
    </section>
  );
}
