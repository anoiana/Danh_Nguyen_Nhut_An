import React, { useMemo, useRef, useState } from "react";
import Button from "react-bootstrap/Button";
import Overlay from "react-bootstrap/Overlay";
import Popover from "react-bootstrap/Popover";
import Form from "react-bootstrap/Form";
import CloseButton from "react-bootstrap/CloseButton";

const DEFAULT_POPULAR = [
  { name: "TP. Hồ Chí Minh", subtitle: "Việt Nam" },
  { name: "Đà Nẵng", subtitle: "Việt Nam" },
  { name: "Hà Nội", subtitle: "Việt Nam" },
  { name: "Nha Trang", subtitle: "Việt Nam" },
  { name: "Đà Lạt", subtitle: "Việt Nam" },
];

function fmtDate(d) {
  if (!d) return "";
  return d.toLocaleDateString("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
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

function CalendarSingle({ value, onChange, onDone }) {
  const today = new Date();
  const [base, setBase] = useState(
    new Date(today.getFullYear(), today.getMonth(), 1)
  );
  const weekdays = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
  const cells = buildMonth(base.getFullYear(), base.getMonth());
  const monthLabel = new Date(
    base.getFullYear(),
    base.getMonth(),
    1
  ).toLocaleDateString("vi-VN", {
    month: "long",
    year: "numeric",
  });

  return (
    <div style={{ width: "min(360px, 95vw)" }}>
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
        <div className="fw-semibold text-capitalize">{monthLabel}</div>
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

      <div
        className="d-grid px-2"
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
              new Date(today.getFullYear(), today.getMonth(), today.getDate());
          const isSelected =
            value && date.toDateString() === value.toDateString();
          const cls = [
            "small",
            "text-center",
            "py-2",
            "rounded-2",
            disabled ? "text-muted" : "cursor-pointer",
            isSelected && "bg-primary text-white",
          ]
            .filter(Boolean)
            .join(" ");

          return (
            <div
              key={i}
              className={cls}
              style={{ userSelect: "none" }}
              onClick={() => !disabled && onChange(date)}
            >
              {date.getDate()}
            </div>
          );
        })}
      </div>

      <div className="d-flex justify-content-between align-items-center border-top pt-2 px-2 mt-2">
        <div className="small text-muted">
          Ngày đã chọn: <strong>{fmtDate(value) || "--"}</strong>
        </div>
        <div className="d-flex gap-2">
          <Button variant="light" size="sm" onClick={() => onChange(undefined)}>
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

export default function ActivitiesSearch({
  onSearch,
  popular = DEFAULT_POPULAR,
  className,
}) {
  const wrapRef = useRef(null);

  const [destination, setDestination] = useState("");
  const [recent, setRecent] = useState([]);
  const [date, setDate] = useState(undefined);

  const destRef = useRef(null);
  const dateRef = useRef(null);

  const [showDest, setShowDest] = useState(false);
  const [showDate, setShowDate] = useState(false);

  const dateLabel = useMemo(() => (date ? fmtDate(date) : "Chọn ngày"), [date]);

  function submit() {
    onSearch && onSearch({ destination, date });
    if (destination) {
      setRecent([{ name: destination }, ...recent.slice(0, 4)]);
    }
  }

  return (
    <div ref={wrapRef} className={`gv-search p-2 rounded-3 ${className || ""}`}>
      <div className="row g-2 align-items-stretch">
        {/* Điểm đến */}
        <div className="col-12 col-lg">
          <div
            ref={destRef}
            className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
            role="button"
            onClick={() => {
              setShowDest(true);
              setShowDate(false);
            }}
          >
            <i className="bi bi-search fs-5 me-2" />
            <div className="text-truncate">
              <div className="text-muted small">Điểm đến</div>
              <div className={destination ? "" : "text-muted"}>
                {destination || "Bạn muốn đi đâu?"}
              </div>
            </div>
          </div>
        </div>

        {/* Ngày */}
        <div className="col-12 col-lg">
          <div
            ref={dateRef}
            className="h-100 bg-white rounded-3 border d-flex align-items-center px-3 py-2"
            role="button"
            onClick={() => {
              setShowDate(true);
              setShowDest(false);
            }}
          >
            <i className="bi bi-calendar3 fs-5 me-2" />
            <div className="text-truncate">
              <div className="text-muted small">Ngày</div>
              <div className={date ? "" : "text-muted"}>{dateLabel}</div>
            </div>
          </div>
        </div>

        {/* Tìm */}
        <div className="col-12 col-lg-auto">
          <Button
            variant="primary"
            className="w-100 h-100 px-4 py-2 rounded-3 d-flex align-items-center justify-content-center btn-teal"
            disabled={!destination}
            onClick={submit}
          >
            Tìm
          </Button>
        </div>
      </div>

      {/* Popover: Điểm đến */}
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
              <div className="fw-semibold">Tìm điểm đến</div>
              <CloseButton onClick={() => setShowDest(false)} />
            </Popover.Header>
            <Popover.Body>
              <Form.Control
                autoFocus
                placeholder="Nhập tên thành phố, địa điểm…"
                value={destination}
                onChange={(e) => setDestination(e.target.value)}
                className="mb-3"
              />

              {!!recent.length && (
                <>
                  <div className="fw-semibold mb-2">Tìm kiếm gần đây</div>
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
                        <div className="fw-semibold">{r.name}</div>
                      </button>
                    ))}
                  </div>
                </>
              )}

              <div className="fw-semibold mb-2">Các điểm đến thịnh hành</div>
              <div className="list-group">
                {(popular || DEFAULT_POPULAR).map((p, i) => (
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

      {/* Popover: Ngày */}
      <Overlay
        target={dateRef.current}
        show={showDate}
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
        onHide={() => setShowDate(false)}
      >
        {(props) => (
          <Popover
            {...props}
            className={`shadow ${props.className ?? ""}`}
            id="date-pop-activity"
            style={{ ...(props.style || {}), maxWidth: "none" }}
          >
            <Popover.Header className="d-flex align-items-center justify-content-between">
              <div className="fw-semibold">Chọn ngày</div>
              <CloseButton onClick={() => setShowDate(false)} />
            </Popover.Header>
            <Popover.Body>
              <CalendarSingle
                value={date}
                onChange={setDate}
                onDone={() => setShowDate(false)}
              />
            </Popover.Body>
          </Popover>
        )}
      </Overlay>
    </div>
  );
}
