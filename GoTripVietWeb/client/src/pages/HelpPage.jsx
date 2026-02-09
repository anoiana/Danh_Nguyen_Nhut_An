import React, { useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";
import Col from "react-bootstrap/Col";
import Card from "react-bootstrap/Card";
import ListGroup from "react-bootstrap/ListGroup";
import Button from "react-bootstrap/Button";
import Alert from "react-bootstrap/Alert";

export default function HelpPage() {
  const navigate = useNavigate();
  const paragraphStyle = { textIndent: 24, textAlign: "justify" };
  const sections = useMemo(
    () => [
      {
        key: "intro",
        title: "Giới thiệu",
        content: (
          <>
            <p className="text-muted mb-3">
              Trang này giúp bạn hiểu cách tìm tour, đặt tour, thanh toán và xử
              lý các vấn đề thường gặp trên GoTripViet.
            </p>

            <p className="mb-3" style={paragraphStyle}>
              GoTripViet là nền tảng du lịch được xây dựng với mục tiêu giúp
              người dùng tìm tour nhanh - chọn tour đúng - đặt tour gọn - thanh
              toán an toàn chỉ trong vài bước, thay vì phải mở nhiều trang khác
              nhau để so sánh và tự “ghép” thông tin. Điểm nổi bật của
              GoTripViet nằm ở cách hệ thống tổ chức dữ liệu tour theo điểm đến
              và danh mục, kết hợp với cơ chế lọc thông minh để khách hàng có
              thể chủ động thu hẹp lựa chọn theo nhu cầu thật: khởi hành từ đâu,
              đi ngày nào, ngân sách bao nhiêu, phương tiện di chuyển, tiêu
              chuẩn khách sạn… Nhờ đó, trải nghiệm tìm kiếm không còn là “lướt
              cho vui” mà trở thành một quy trình chọn tour có định hướng, rõ
              ràng và tiết kiệm thời gian.
            </p>

            <p className="mb-3" style={paragraphStyle}>
              Bên cạnh đó, GoTripViet được thiết kế để việc đặt tour diễn ra
              mạch lạc, minh bạch và hạn chế tối đa sai sót. Ở mỗi tour, hệ
              thống hiển thị thông tin quan trọng một cách trực quan: lịch khởi
              hành, số ngày đi, điểm nhấn hành trình, các lưu ý/điều khoản,
              chính sách và những hạng mục dịch vụ đi kèm. Khi khách hàng tiến
              hành đặt tour, hệ thống kiểm tra tồn kho chỗ theo lịch để đảm bảo
              đặt thành công là có suất thật, tránh tình trạng “đặt xong mới báo
              hết chỗ”. Sau khi xác nhận, luồng thanh toán được tối ưu để nhanh
              chóng, rõ ràng về chi phí và có thể tích hợp phương thức thanh
              toán trực tuyến phù hợp, giúp khách hàng hoàn tất giao dịch an
              tâm.
            </p>

            <p className="mb-3" style={paragraphStyle}>
              Không chỉ phục vụ khách du lịch, GoTripViet còn là cầu nối hợp tác
              với các đối tác/partner cung cấp tour. Partner có thể đăng ký hợp
              tác, được xét duyệt để đảm bảo chất lượng, sau đó quản lý danh
              sách tour và lịch khởi hành của mình trên hệ thống. Cơ chế này tạo
              ra một “hệ sinh thái tour” đa dạng nhưng vẫn giữ được tính kiểm
              soát, giúp khách hàng tiếp cận nhiều lựa chọn hơn mà vẫn có sự
              nhất quán về trải nghiệm. Về tổng thể, GoTripViet hướng đến một
              nền tảng du lịch hiện đại: giao diện thân thiện, dữ liệu được tổ
              chức khoa học, tìm kiếm linh hoạt, đặt tour chắc chắn và hỗ trợ rõ
              ràng - để mỗi chuyến đi bắt đầu từ một quy trình đặt tour nhẹ
              nhàng, tin cậy và hiệu quả.
            </p>

            <Alert variant="info" className="mb-0">
              Mẹo nhanh: Bạn có thể vào trang <b>Tìm kiếm</b> để lọc tour theo{" "}
              <b>điểm đến</b> hoặc <b>danh mục</b>.
            </Alert>
          </>
        ),
      },
      {
        key: "search",
        title: "Tìm kiếm & lọc tour",
        content: (
          <>
            <h6 className="fw-semibold">Bạn có thể lọc theo:</h6>
            <ul className="mb-3">
              <li>Điểm đến (Location)</li>
              <li>Danh mục (Category)</li>
              <li>Ngày khởi hành</li>
              <li>Ngân sách</li>
              <li>Phương tiện</li>
              <li>Hạng sao khách sạn (nếu có)</li>
            </ul>

            <Button variant="primary" onClick={() => navigate("/search")}>
              Đi tới trang Search
            </Button>
          </>
        ),
      },
      {
        key: "booking",
        title: "Đặt tour",
        content: (
          <>
            <ol className="mb-3">
              <li>Chọn tour phù hợp ở trang Search hoặc trang chủ.</li>
              <li>Vào chi tiết tour để xem lịch khởi hành & thông tin tour.</li>
              <li>Điền thông tin đặt tour và xác nhận.</li>
            </ol>

            <Alert variant="light" className="mb-0">
              Nếu tour hết chỗ, hệ thống sẽ báo không đủ tồn kho (stock) khi bạn
              đặt/giữ chỗ.
            </Alert>
          </>
        ),
      },
      {
        key: "payment",
        title: "Thanh toán",
        content: (
          <>
            <p className="mb-2">
              Bạn có thể thanh toán theo luồng thanh toán của hệ thống (ví dụ:
              VNPay/online payment tùy cấu hình dự án).
            </p>
            <ul className="mb-3">
              <li>Kiểm tra lại tổng tiền trước khi xác nhận.</li>
              <li>Không thoát trang trong lúc đang xử lý thanh toán.</li>
              <li>Sau khi thành công sẽ có trang xác nhận.</li>
            </ul>
            <Button
              variant="outline-primary"
              onClick={() => navigate("/order")}
            >
              Xem trang Order
            </Button>
          </>
        ),
      },
      {
        key: "account",
        title: "Tài khoản & bảo mật",
        content: (
          <>
            <ul className="mb-3">
              <li>Đăng ký/Đăng nhập để theo dõi lịch sử đặt tour.</li>
              <li>Không chia sẻ OTP, mật khẩu.</li>
              <li>Nếu quên mật khẩu: dùng tính năng “Forgot Password”.</li>
            </ul>

            <div className="d-flex gap-2 flex-wrap">
              <Button variant="primary" onClick={() => navigate("/login")}>
                Đăng nhập
              </Button>
              <Button
                variant="outline-primary"
                onClick={() => navigate("/register")}
              >
                Đăng ký
              </Button>
              <Button
                variant="outline-secondary"
                onClick={() => navigate("/forgot-password")}
              >
                Quên mật khẩu
              </Button>
            </div>
          </>
        ),
      },
      {
        key: "partner",
        title: "Dành cho Partner",
        content: (
          <>
            <p className="mb-2">
              Nếu bạn là Partner, bạn có thể đăng ký hợp tác và quản lý tour của
              mình.
            </p>
            <ul className="mb-3">
              <li>Đăng ký Partner</li>
              <li>Tạo & quản lý tour</li>
              <li>Quản lý tồn kho (inventory) theo ngày khởi hành</li>
              <li>Quản lý đơn hàng</li>
            </ul>

            <div className="d-flex gap-2 flex-wrap">
              <Button
                variant="primary"
                onClick={() => navigate("/partner/register")}
              >
                Đăng ký Partner
              </Button>
              <Button
                variant="outline-primary"
                onClick={() => navigate("/partner/dashboard")}
              >
                Partner Dashboard
              </Button>
            </div>
          </>
        ),
      },
      {
        key: "contact",
        title: "Liên hệ hỗ trợ",
        content: (
          <>
            <p className="mb-2">
              Nếu bạn gặp lỗi hoặc cần hỗ trợ, hãy chuẩn bị:
            </p>
            <ul className="mb-3">
              <li>Mã đơn (nếu có)</li>
              <li>Email/SĐT dùng để đặt</li>
              <li>Ảnh chụp màn hình lỗi</li>
              <li>Thời gian xảy ra lỗi</li>
            </ul>

            <Alert variant="warning" className="mb-0">
              (Bạn có thể thay nội dung này bằng hotline/email thật của dự án.)
            </Alert>
          </>
        ),
      },
    ],
    [navigate]
  );

  const [activeKey, setActiveKey] = useState(sections[0].key);
  const current = sections.find((s) => s.key === activeKey) || sections[0];

  return (
    <Container className="my-4">
      <Row className="g-4">
        {/* LEFT NAV */}
        <Col xs={12} md={4} lg={3}>
          <Card className="shadow-sm">
            <Card.Body>
              <div className="d-flex align-items-center justify-content-between mb-3">
                <div>
                  <div className="fw-bold">Trợ giúp</div>
                  <div className="text-muted" style={{ fontSize: 13 }}>
                    Chọn mục để xem nội dung
                  </div>
                </div>

                <Button
                  size="sm"
                  variant="outline-primary"
                  onClick={() => navigate("/")}
                >
                  Home
                </Button>
              </div>

              <ListGroup variant="flush">
                {sections.map((s) => (
                  <ListGroup.Item
                    key={s.key}
                    action
                    active={s.key === activeKey}
                    onClick={() => setActiveKey(s.key)}
                    style={{ cursor: "pointer" }}
                  >
                    {s.title}
                  </ListGroup.Item>
                ))}
              </ListGroup>
            </Card.Body>
          </Card>
        </Col>

        {/* RIGHT CONTENT */}
        <Col xs={12} md={8} lg={9}>
          <Card className="shadow-sm">
            <Card.Body>
              <h3 className="fw-bold mb-3">{current.title}</h3>
              {current.content}

              <hr className="my-4" />

              <div className="d-flex align-items-center justify-content-between flex-wrap gap-2">
                <div className="text-muted" style={{ fontSize: 13 }}>
                  Không tìm thấy câu trả lời? Hãy thử tìm tour theo điểm
                  đến/danh mục.
                </div>
                <Button variant="primary" onClick={() => navigate("/search")}>
                  Mở Search
                </Button>
              </div>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
}
