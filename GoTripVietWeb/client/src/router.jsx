import React, { useEffect, useState } from "react";
import {
  BrowserRouter,
  Routes,
  Route,
  Navigate,
  useNavigate,
  useLocation,
} from "react-router-dom";

// Layout
import UserLayout from "./layouts/UserLayout.jsx";
import AdminLayout from "./layouts/AdminLayout.jsx";
import SearchPage from "./pages/SearchPage.jsx";
import PartnerManageOrders from "./pages/partner/PartnerManageOrders";
// Pages
import OrderDetail from "./pages/OrderDetail.jsx";
import ProductDetail from "./pages/ProductDetail.jsx";
import Home from "./pages/Home.jsx";
import Order from "./pages/Order.jsx";
import ConfirmOrder from "./pages/ConfirmOrder.jsx";
import Login from "./pages/Login.jsx";
import Register from "./pages/Register.jsx";
import OtpVerify from "./pages/OtpVerify.jsx";
import OrderSuccess from "./pages/OrderSuccess.jsx";
import Profile from "./pages/Profile.jsx";
import ForgotPassword from "./pages/ForgotPassword.jsx";
import PaymentPage from "./pages/PaymentPage";
import BookingSuccess from "./pages/BookingSuccess";
import EventDetail from "./pages/EventDetail.jsx";
import RegisterPartner from "./pages/partner/RegisterPartner.jsx";
import ManagePartners from "./pages/admin/ManagePartners";
import PartnerWallet from "./pages/partner/PartnerWallet";
import ProtectedRoute from "./components/ProtectedRoute";
import ManageMyTours from "./pages/partner/PartnerManageTours";
import CreateTour from "./pages/partner/PartnerCreateTour";
import PartnerDashboard from "./pages/partner/PartnerDashboard";
import PartnerInventory from "./pages/partner/PartnerInventory"; // [NEW IMPORT]
import PartnerEditTour from "./pages/partner/PartnerEditTour";
import PartnerOrderDetail from "./pages/partner/PartnerOrderDetail";
import PartnerProfile from "./pages/partner/PartnerProfile";
import HelpPage from "./pages/HelpPage.jsx";

const HomePage = ({ activeCategoryIndex, onCategoryChange }) => {
  const navigate = useNavigate();

  return (
    <UserLayout
      activeCategoryIndex={activeCategoryIndex}
      onCategoryChange={onCategoryChange}
    >
      <Home
        activeCategoryIndex={activeCategoryIndex}
        onNavigateToHotels={(q) => {
          const query = (q || "").trim();
          navigate(
            query ? `/hotels?q=${encodeURIComponent(query)}` : "/hotels"
          );
        }}
        onNavigateToCities={(q) => {
          const query = (q || "").trim();
          navigate(
            query ? `/cities?q=${encodeURIComponent(query)}` : "/cities"
          );
        }}
      />
    </UserLayout>
  );
};

const BookingSuccessPage = ({ activeCategoryIndex, onCategoryChange }) => {
  return (
    <UserLayout
      activeCategoryIndex={activeCategoryIndex}
      onCategoryChange={onCategoryChange}
    >
      <BookingSuccess />
    </UserLayout>
  );
};

const SearchPageWrapper = ({ activeCategoryIndex, onCategoryChange }) => {
  return (
    <UserLayout
      activeCategoryIndex={activeCategoryIndex}
      onCategoryChange={onCategoryChange}
    >
      <SearchPage />
    </UserLayout>
  );
};

const HelpPageWrapper = ({ activeCategoryIndex, onCategoryChange }) => {
  return (
    <UserLayout
      activeCategoryIndex={activeCategoryIndex}
      onCategoryChange={onCategoryChange}
    >
      <HelpPage />
    </UserLayout>
  );
};

const PaymentPageWrapper = ({ activeCategoryIndex, onCategoryChange }) => (
  <UserLayout
    activeCategoryIndex={activeCategoryIndex}
    onCategoryChange={onCategoryChange}
  >
    <PaymentPage />
  </UserLayout>
);

const ForgotPasswordPage = () => {
  return <ForgotPassword />;
};

const ListingCitiesPage = ({ activeCategoryIndex, onCategoryChange }) => {
  const location = useLocation();
  return (
    <UserLayout
      activeCategoryIndex={activeCategoryIndex}
      onCategoryChange={onCategoryChange}
    >
      <ListingCities key={location.search} />
    </UserLayout>
  );
};

const OrderPage = ({ activeCategoryIndex, onCategoryChange }) => {
  return (
    <UserLayout
      activeCategoryIndex={activeCategoryIndex}
      onCategoryChange={onCategoryChange}
    >
      <Order />
    </UserLayout>
  );
};

const ProductDetailPage = ({ activeCategoryIndex, onCategoryChange }) => {
  return (
    <UserLayout
      activeCategoryIndex={activeCategoryIndex}
      onCategoryChange={onCategoryChange}
    >
      <ProductDetail />
    </UserLayout>
  );
};

const ConfirmOrderPage = ({ activeCategoryIndex, onCategoryChange }) => {
  return (
    <UserLayout
      activeCategoryIndex={activeCategoryIndex}
      onCategoryChange={onCategoryChange}
    >
      <ConfirmOrder />
    </UserLayout>
  );
};

const OrderFlightPage = ({ activeCategoryIndex, onCategoryChange }) => {
  return (
    <UserLayout
      activeCategoryIndex={activeCategoryIndex}
      onCategoryChange={onCategoryChange}
    >
      <OrderFlight />
    </UserLayout>
  );
};

const OrderSuccessPage = ({ activeCategoryIndex, onCategoryChange }) => {
  return (
    <UserLayout
      activeCategoryIndex={activeCategoryIndex}
      onCategoryChange={onCategoryChange}
    >
      <OrderSuccess />
    </UserLayout>
  );
};

const ProfilePage = ({ activeCategoryIndex, onCategoryChange }) => {
  return (
    <UserLayout
      activeCategoryIndex={activeCategoryIndex}
      onCategoryChange={onCategoryChange}
    >
      <Profile />
    </UserLayout>
  );
};

const RegisterPage = () => {
  return <Register />;
};

const LoginPage = () => {
  const navigate = useNavigate();

  const handleNext = async (email) => {
    // truyền email qua state để OTP screen đọc lại
    navigate("/otp-verify", { state: { email } });
  };

  return <Login onNext={handleNext} />;
};

const OtpVerifyPage = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const email = location.state?.email || "";

  return (
    <OtpVerify
      email={email}
      onSubmit={() => {
        // sau khi xác minh xong, tạm thời cho về trang chủ
        navigate("/");
      }}
      onResend={() => {
        console.log("Resend OTP");
      }}
      onBackToLogin={() => navigate("/login")}
      resendSeconds={60}
    />
  );
};

const ScrollToTop = () => {
  const { pathname, search } = useLocation();

  useEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: "smooth" });
  }, [pathname, search]);

  return null;
};

const RequireAdmin = ({ children }) => {
  const location = useLocation();

  const token = localStorage.getItem("token");
  const user = JSON.parse(localStorage.getItem("user") || "null");

  const roles = Array.isArray(user?.roles) ? user.roles : [];
  const isAdmin = roles.map((r) => String(r).toLowerCase()).includes("admin");

  if (!token) {
    // chưa login -> đá về login và nhớ URL đang muốn vào
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  if (!isAdmin) {
    // login rồi nhưng không phải admin -> đá về home (hoặc /403)
    return <Navigate to="/" replace />;
  }

  return children;
};

const OrderDetailPage = ({ activeCategoryIndex, onCategoryChange }) => (
  <UserLayout
    activeCategoryIndex={activeCategoryIndex}
    onCategoryChange={onCategoryChange}
  >
    <OrderDetail />
  </UserLayout>
);

const AppRouter = () => {
  const [activeCategoryIndex, setActiveCategoryIndex] = useState(0);

  return (
    <BrowserRouter>
      <ScrollToTop />

      <Routes>
        {/* Trang chủ */}
        <Route
          path="/"
          element={
            <HomePage
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            />
          }
        />

        <Route
          path="/search"
          element={
            <SearchPageWrapper
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            />
          }
        />

        {/* Trang điền thông tin đặt phòng */}
        <Route
          path="/order"
          element={
            <OrderPage
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            />
          }
        />

        {/* Trang xác nhận đặt phòng */}
        <Route
          path="/confirm-order"
          element={
            <ConfirmOrderPage
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            />
          }
        />
        <Route
          path="/payment"
          element={
            <PaymentPageWrapper
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            />
          }
        />

        <Route
          path="/booking-success"
          element={
            <BookingSuccessPage
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            />
          }
        />

        {/* Trang danh sách thành phố */}
        <Route
          path="/cities"
          element={
            <ListingCitiesPage
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            />
          }
        />

        <Route
          path="/order-success"
          element={
            <OrderSuccessPage
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            />
          }
        />

        <Route
          path="/order-detail/:id" // [THÊM] Route mới có tham số id
          element={
            <OrderDetailPage
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            />
          }
        />

        {/* --- ADMIN ROUTES --- */}
        {/* <Route
          path="/admin/manage/partners"
          element={
            <ProtectedRoute roles={["admin"]}>
              <ManagePartners />
            </ProtectedRoute>
          }
        /> */}

        <Route element={<ProtectedRoute roles={["partner"]} />}>
          <Route path="/partner/dashboard" element={<PartnerDashboard />} />
          <Route path="/partner/wallet" element={<PartnerWallet />} />

          {/* Trang danh sách tour của chính họ */}
          <Route path="/partner/tours" element={<ManageMyTours />} />

          {/* Tái sử dụng trang tạo tour, nhưng cần chỉnh sửa logic một chút để phù hợp context */}
          <Route
            path="/partner/tours/create"
            element={<CreateTour mode="partner" />}
          />
          <Route path="/partner/tours/:id" element={<PartnerEditTour />} />
          {/* [NEW] Route quản lý tồn kho (Inventory) */}
          <Route
            path="/partner/tours/:id/inventory"
            element={<PartnerInventory />}
          />
          <Route path="/partner/orders" element={<PartnerManageOrders />} />
          <Route path="/partner/orders/:id" element={<PartnerOrderDetail />} />
          <Route path="/partner/profile" element={<PartnerProfile />} />
        </Route>

        {/* Login – KHÔNG dùng UserLayout */}
        <Route path="/login" element={<LoginPage />} />
        {/* Register – KHÔNG dùng UserLayout */}
        <Route path="/register" element={<RegisterPage />} />
        {/* OTP – KHÔNG dùng UserLayout */}
        <Route path="/otp-verify" element={<OtpVerifyPage />} />
        <Route path="/partner/register" element={<RegisterPartner />} />
        {/* Admin layout */}
        <Route
          path="/admin/*"
          element={
            <RequireAdmin>
              <AdminLayout />
            </RequireAdmin>
          }
        />

        <Route
          path="/help"
          element={
            <HelpPageWrapper
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            />
          }
        />

        {/* Fallback: route lạ -> về trang chủ */}
        <Route path="*" element={<Navigate to="/" replace />} />

        <Route
          path="/profile"
          element={
            <ProfilePage
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            />
          }
        />

        <Route
          path="/product/:id"
          element={
            <ProductDetailPage
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            />
          }
        />

        <Route
          path="/event/:id"
          element={
            <UserLayout
              activeCategoryIndex={activeCategoryIndex}
              onCategoryChange={setActiveCategoryIndex}
            >
              <EventDetail />
            </UserLayout>
          }
        />
      </Routes>
    </BrowserRouter>
  );
};

export default AppRouter;
