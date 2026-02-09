import React, { useMemo, useRef, useState } from "react";
import Button from "react-bootstrap/Button";
import Overlay from "react-bootstrap/Overlay";
import Popover from "react-bootstrap/Popover";
import Dropdown from "react-bootstrap/Dropdown";
import Form from "react-bootstrap/Form";
import CloseButton from "react-bootstrap/CloseButton";

/** ===== Date helpers ===== */
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
    cells.push({
      date: new Date(last.getFullYear(), last.getMonth(), last.getDate() + 1),
      inMonth: false,
    });
  }
  return cells;
}

/** ===== Calendar (range) ===== */
function CalendarRange({
  value,
  onChange,
  onDone,
  title = "Chọn khoảng ngày",
}) {
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
          Ngày đi: <strong>{fmtDate(value.start) || "--"}</strong>
          &nbsp;–&nbsp; Ngày về: <strong>{fmtDate(value.end) || "--"}</strong>
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

/** ===== Calendar (single-day) ===== */
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
          Ngày đi: <strong>{fmtDate(value) || "--"}</strong>
        </div>
        <div className="d-flex gap-2">
          <Button variant="light" size="sm" onClick={() => onPick(undefined)}>
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

/** ===== Main component ===== */
export default function HotelAndPlaneSearch({ onSearch, className }) {
  const wrapRef = useRef(null);
  const fromRef = useRef(null);
  const toRef = useRef(null);
  const departRef = useRef(null);
  const returnRef = useRef(null);
  const paxRef = useRef(null);
  const roomsRef = useRef(null);

  const [tripType, setTripType] = useState("roundtrip");
  const [cabin, setCabin] = useState("economy");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [depart, setDepart] = useState(undefined);
  const [ret, setRet] = useState(undefined);
  const [adults, setAdults] = useState(1);
  const [children, setChildren] = useState(0);
  const [rooms, setRooms] = useState(1);

  const [anchor, setAnchor] = useState(null);
  const [panel, setPanel] = useState(null);
  const [airportQuery, setAirportQuery] = useState("");

  const departLabel = useMemo(
    () => (depart ? fmtDate(depart) : "Ngày đi"),
    [depart]
  );
  const returnLabel = useMemo(() => (ret ? fmtDate(ret) : "Ngày về"), [ret]);
  const paxLabel = useMemo(
    () => `${adults + children} Hành khách`,
    [adults, children]
  );
  const roomsLabel = useMemo(() => `${rooms} Phòng`, [rooms]);

  function submit() {
    onSearch &&
      onSearch({
        tripType,
        cabin,
        from,
        to,
        depart,
        return: tripType === "oneway" ? undefined : ret,
        adults,
        children,
        rooms,
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
      {/* Top toggles */}
      <div className="d-flex align-items-center gap-2 mb-2">
        <div className="btn-group" role="group" aria-label="trip-type">
          <Button
            variant={tripType === "roundtrip" ? "primary" : "light"}
            onClick={() => setTripType("roundtrip")}
          >
            Khứ hồi
          </Button>
          <Button
            variant={tripType === "oneway" ? "primary" : "light"}
            onClick={() => setTripType("oneway")}
          >
            Một chiều
          </Button>
        </div>
        <Dropdown>
          <Dropdown.Toggle variant="primary">
            {
              {
                economy: "Phổ thông",
                premium_economy: "Phổ thông đặc biệt",
                business: "Thương gia",
                first: "Hạng nhất",
              }[cabin]
            }
          </Dropdown.Toggle>
          <Dropdown.Menu>
            <Dropdown.Item onClick={() => setCabin("economy")}>
              Phổ thông
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
      </div>

      {/* Row 1: From / To / Dates */}
      <div className="row g-2 align-items-stretch">
        {/* from */}
        <div className="col-12 col-lg">
          <div
            ref={fromRef}
            className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
            role="button"
            onClick={() => {
              setAnchor(fromRef.current);
              setPanel("from");
            }}
          >
            <i className="bi bi-airplane fs-5 me-2" />
            <div className="text-truncate">
              <div className="text-muted small">Bay từ</div>
              <div className={from ? "" : "text-muted"}>{from || "Bay từ"}</div>
            </div>
          </div>
        </div>

        {/* to */}
        <div className="col-12 col-lg">
          <div
            ref={toRef}
            className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
            role="button"
            onClick={() => {
              setAnchor(toRef.current);
              setPanel("to");
            }}
          >
            <i className="bi bi-signpost-2 fs-5 me-2" />
            <div className="text-truncate">
              <div className="text-muted small">Bay đến</div>
              <div className={to ? "" : "text-muted"}>{to || "Bay đến"}</div>
            </div>
          </div>
        </div>

        {/* depart */}
        <div className="col-12 col-md-6 col-lg">
          <div
            ref={departRef}
            className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
            role="button"
            onClick={() => {
              setAnchor(departRef.current);
              setPanel("depart");
            }}
          >
            <i className="bi bi-calendar3 fs-5 me-2" />
            <div className="text-truncate">
              <div className="text-muted small">Ngày đi</div>
              <div className={depart ? "" : "text-muted"}>{departLabel}</div>
            </div>
          </div>
        </div>

        {/* return */}
        {tripType === "roundtrip" && (
          <div className="col-12 col-md-6 col-lg">
            <div
              ref={returnRef}
              className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
              role="button"
              onClick={() => {
                setAnchor(returnRef.current);
                setPanel("return");
              }}
            >
              <i className="bi bi-calendar3 fs-5 me-2" />
              <div className="text-truncate">
                <div className="text-muted small">Ngày về</div>
                <div className={ret ? "" : "text-muted"}>{returnLabel}</div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Row 2: pax / rooms / search */}
      <div className="row g-2 align-items-stretch mt-2">
        {/* pax */}
        <div className="col-12 col-md-6 col-lg">
          <div
            ref={paxRef}
            className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
            role="button"
            onClick={() => {
              setAnchor(paxRef.current);
              setPanel("pax");
            }}
          >
            <i className="bi bi-people fs-5 me-2" />
            <div className="text-truncate">
              <div className="text-muted small">Hành khách</div>
              <div>{paxLabel}</div>
            </div>
            <i className="bi bi-caret-down-fill ms-auto" />
          </div>
        </div>

        {/* rooms */}
        <div className="col-12 col-md-6 col-lg">
          <div
            ref={roomsRef}
            className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
            role="button"
            onClick={() => {
              setAnchor(roomsRef.current);
              setPanel("rooms");
            }}
          >
            <i className="bi bi-door-open fs-5 me-2" />
            <div className="text-truncate">
              <div className="text-muted small">Phòng</div>
              <div>{roomsLabel}</div>
            </div>
            <i className="bi bi-caret-down-fill ms-auto" />
          </div>
        </div>

        {/* search button */}
        <div className="col-12 col-lg">
          <Button
            variant="primary"
            className="w-100 h-100 px-4 py-2 rounded-3 d-flex align-items-center justify-content-center"
            onClick={submit}
            disabled={
              !from || !to || !depart || (tripType === "roundtrip" && !ret)
            }
          >
            TÌM CHUYẾN BAY + KHÁCH SẠN
          </Button>
        </div>
      </div>

      {panel && anchor && (
        <Overlay
          target={anchor}
          show
          placement="bottom-start"
          rootClose
          container={wrapRef.current}
          popperConfig={popperConfig}
          onHide={() => {
            setPanel(null);
            setAnchor(null);
          }}
        >
          {(props) => {
            // FROM / TO
            if (panel === "from" || panel === "to") {
              const isTo = panel === "to";

              const SUGGEST = [
                {
                  type: "city",
                  title: "Việt Trì (Phú Thọ), Việt Nam",
                  subtitle: "",
                  right: "Mọi sân bay",
                },
                {
                  type: "city",
                  title: "Hồ Chí Minh, Việt Nam",
                  subtitle: "",
                  right: "Mọi sân bay",
                },
                {
                  type: "airport",
                  title: "Sân bay Quốc tế Tân Sơn Nhất",
                  subtitle: "TP. Hồ Chí Minh, Việt Nam",
                  right: "SGN",
                  code: "SGN",
                },
                {
                  type: "city",
                  title: "Đà Nẵng, Việt Nam",
                  subtitle: "",
                  right: "Mọi sân bay",
                },
                {
                  type: "airport",
                  title: "Sân bay Quốc tế Đà Nẵng",
                  subtitle: "Đà Nẵng, Việt Nam",
                  right: "DAD",
                  code: "DAD",
                },
                {
                  type: "city",
                  title: "Hà Nội, Việt Nam",
                  subtitle: "",
                  right: "Mọi sân bay",
                },
                {
                  type: "airport",
                  title: "Sân bay Quốc tế Nội Bài",
                  subtitle: "Hà Nội, Việt Nam",
                  right: "HAN",
                  code: "HAN",
                },
                {
                  type: "city",
                  title: "Nha Trang, Việt Nam",
                  subtitle: "",
                  right: "Mọi sân bay",
                },
                {
                  type: "airport",
                  title: "Sân bay Quốc tế Cam Ranh",
                  subtitle: "Khánh Hòa, Việt Nam",
                  right: "CXR",
                  code: "CXR",
                },
              ];

              const list = SUGGEST.filter((i) => {
                const q = airportQuery.trim().toLowerCase();
                if (!q) return true;
                return (
                  i.title.toLowerCase().includes(q) ||
                  i.subtitle.toLowerCase().includes(q) ||
                  i.right.toLowerCase().includes(q)
                );
              });

              function pick(item) {
                const text =
                  item.type === "airport"
                    ? `${item.title} (${item.right})`
                    : item.title;
                if (isTo) setTo(text);
                else setFrom(text);
                setAirportQuery("");
                setPanel(null);
                setAnchor(null);
              }

              return (
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
                  <Popover.Body className="p-0">
                    <div className="p-3 pb-2">
                      <Form.Control
                        autoFocus
                        placeholder={
                          isTo
                            ? "Nhập thành phố/sân bay đến"
                            : "Nhập thành phố/sân bay đi"
                        }
                        value={airportQuery}
                        onChange={(e) => setAirportQuery(e.target.value)}
                      />
                    </div>

                    <div className="list-group list-group-flush">
                      {list.map((it, idx) => (
                        <button
                          key={idx}
                          className="list-group-item list-group-item-action d-flex align-items-start gap-3"
                          onClick={() => pick(it)}
                          style={{ paddingTop: 12, paddingBottom: 12 }}
                        >
                          <div className="mt-1">
                            {it.type === "airport" ? (
                              <i className="bi bi-airplane-engines" />
                            ) : (
                              <i className="bi bi-geo-alt" />
                            )}
                          </div>

                          <div className="flex-grow-1 text-start">
                            <div className="fw-semibold">{it.title}</div>
                            {it.subtitle && (
                              <div className="text-muted small">
                                {it.subtitle}
                              </div>
                            )}
                          </div>

                          <div className="text-muted small mt-1">
                            {it.right}
                          </div>
                        </button>
                      ))}
                    </div>
                  </Popover.Body>
                </Popover>
              );
            }

            // DEPART / RETURN
            if (panel === "depart" || panel === "return") {
              const isReturn = panel === "return";
              return (
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
                    <div className="fw-semibold">
                      {isReturn ? "Ngày về" : "Ngày đi"}
                    </div>
                    <CloseButton
                      onClick={() => {
                        setPanel(null);
                        setAnchor(null);
                      }}
                    />
                  </Popover.Header>
                  <Popover.Body>
                    {tripType === "oneway" && !isReturn ? (
                      <CalendarSingle
                        value={depart}
                        onPick={(d) => setDepart(d)}
                        onDone={() => {
                          setPanel(null);
                          setAnchor(null);
                        }}
                        title="Chọn ngày đi"
                      />
                    ) : (
                      <CalendarRange
                        value={{ start: depart, end: ret }}
                        onChange={(v) => {
                          setDepart(v.start);
                          setRet(v.end);
                        }}
                        onDone={() => {
                          setPanel(null);
                          setAnchor(null);
                        }}
                        title="Chọn khoảng ngày"
                      />
                    )}
                  </Popover.Body>
                </Popover>
              );
            }

            // PAX / ROOMS
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
                  <div className="fw-semibold">
                    {panel === "pax" ? "Hành khách" : "Phòng"}
                  </div>
                  <CloseButton
                    onClick={() => {
                      setPanel(null);
                      setAnchor(null);
                    }}
                  />
                </Popover.Header>
                <Popover.Body>
                  {panel === "pax" ? (
                    <>
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
                      ].map((r) => (
                        <div
                          key={r.label}
                          className="d-flex align-items-center justify-content-between mb-2"
                        >
                          <div className="fw-semibold">{r.label}</div>
                          <div className="d-flex align-items-center gap-2">
                            <Button
                              variant="light"
                              onClick={() => r.set(Math.max(r.min, r.val - 1))}
                              disabled={r.val <= r.min}
                            >
                              –
                            </Button>
                            <div className="px-3 py-1 border rounded">
                              {r.val}
                            </div>
                            <Button
                              variant="light"
                              onClick={() => r.set(r.val + 1)}
                            >
                              +
                            </Button>
                          </div>
                        </div>
                      ))}
                      <div className="d-grid">
                        <Button
                          variant="primary"
                          onClick={() => {
                            setPanel(null);
                            setAnchor(null);
                          }}
                        >
                          Xong
                        </Button>
                      </div>
                    </>
                  ) : (
                    <>
                      <div className="d-flex align-items-center justify-content-between mb-2">
                        <div className="fw-semibold">Phòng</div>
                        <div className="d-flex align-items-center gap-2">
                          <Button
                            variant="light"
                            onClick={() => setRooms(Math.max(1, rooms - 1))}
                            disabled={rooms <= 1}
                          >
                            –
                          </Button>
                          <div className="px-3 py-1 border rounded">
                            {rooms}
                          </div>
                          <Button
                            variant="light"
                            onClick={() => setRooms(rooms + 1)}
                          >
                            +
                          </Button>
                        </div>
                      </div>
                      <div className="d-grid">
                        <Button
                          variant="primary"
                          onClick={() => {
                            setPanel(null);
                            setAnchor(null);
                          }}
                        >
                          Xong
                        </Button>
                      </div>
                    </>
                  )}
                </Popover.Body>
              </Popover>
            );
          }}
        </Overlay>
      )}
    </section>
  );
}
