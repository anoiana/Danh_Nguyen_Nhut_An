// =========================================================
//                  KHỞI TẠO TRANG DASHBOARD
// =========================================================
document.addEventListener('DOMContentLoaded', function() {
    const token = localStorage.getItem('jwtToken');
    if (!token) {
        // Chuyển hướng nếu chưa đăng nhập, logic này nên nằm trong main-admin.js
        window.location.href = '../login.html';
        return;
    }
    loadDashboardData();
});

// =========================================================
//            TẢI VÀ HIỂN THỊ DỮ LIỆU DASHBOARD
// =========================================================
async function loadDashboardData() {
    const token = localStorage.getItem('jwtToken');
    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/dashboard/stats`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (!response.ok) {
            throw new Error('Không thể tải dữ liệu dashboard.');
        }

        const data = await response.json();
        
        // Cập nhật các thẻ thống kê
        updateStatCards(data);

        // Cập nhật danh sách đơn hàng gần đây
        updateRecentOrders(data.recentOrders);

        // Vẽ biểu đồ doanh thu
        renderRevenueChart(data.revenueChartData);

    } catch (error) {
        console.error('Lỗi khi tải dashboard:', error);
        document.querySelector('.main-content').innerHTML = `<p class="error">${error.message}</p>`;
    }
}

function updateStatCards(data) {
    const formatter = new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' });

    document.getElementById('revenue-stat').textContent = formatter.format(data.monthlyRevenue || 0);
    document.getElementById('orders-stat').textContent = data.newOrdersToday || 0;
    document.getElementById('customers-stat').textContent = data.newCustomersMonth || 0;
    document.getElementById('low-stock-stat').textContent = data.lowStockProducts || 0;
}

function updateRecentOrders(orders) {
    const listElement = document.getElementById('recent-orders-list');
    listElement.innerHTML = ''; // Xóa nội dung cũ

    if (!orders || orders.length === 0) {
        listElement.innerHTML = '<li>Không có đơn hàng nào gần đây.</li>';
        return;
    }

    orders.forEach(order => {
        const li = document.createElement('li');
        li.innerHTML = `
            <a href="orders.html?search=${order.id}">Đơn #${order.id}</a> - 
            <span>${order.customerName}</span> - 
            <strong>${formatCurrency(order.totalAmount)}</strong>
        `;
        listElement.appendChild(li);
    });
}

function renderRevenueChart(revenueData) {
    const ctx = document.getElementById('revenueChart').getContext('2d');
    
    // Chuẩn bị dữ liệu cho biểu đồ
    const today = new Date();
    const daysInMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate();
    const labels = [];
    for (let i = 1; i <= daysInMonth; i++) {
        labels.push(i); // Chỉ hiển thị ngày
    }

    const dataPoints = new Array(daysInMonth).fill(0);
    for (const [dateString, revenue] of Object.entries(revenueData)) {
        const dayOfMonth = new Date(dateString).getDate(); // Lấy ngày từ chuỗi "YYYY-MM-DD"
        dataPoints[dayOfMonth - 1] = revenue;
    }

    new Chart(ctx, {
        type: 'line', // Loại biểu đồ
        data: {
            labels: labels,
            datasets: [{
                label: 'Doanh thu (VND)',
                data: dataPoints,
                backgroundColor: 'rgba(54, 162, 235, 0.2)',
                borderColor: 'rgba(54, 162, 235, 1)',
                borderWidth: 1,
                tension: 0.1
            }]
        },
        options: {
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value, index, values) {
                            return new Intl.NumberFormat('vi-VN').format(value) + ' ₫';
                        }
                    }
                }
            },
            plugins: {
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            let label = context.dataset.label || '';
                            if (label) {
                                label += ': ';
                            }
                            if (context.parsed.y !== null) {
                                label += formatCurrency(context.parsed.y);
                            }
                            return label;
                        }
                    }
                }
            }
        }
    });
}

// Hàm tiện ích
function formatCurrency(number) {
    if (typeof number !== 'number') return '0 ₫';
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(number);
}