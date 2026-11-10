using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using TripFlow.Api.Models.Entities;

namespace TripFlow.Api.Data;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(TripFlowDbContext db)
    {
        var now = DateTime.UtcNow;

        // 1. Permissions & Roles
        if (!await db.Permissions.AnyAsync())
        {
            var permissionDefs = new (string Code, string Name, string Module, string Desc)[]
            {
                ("destination:read", "Xem địa điểm du lịch", "destination", "Xem danh sách và chi tiết địa điểm"),
                ("destination:write", "Tạo & sửa địa điểm", "destination", "Thêm mới và chỉnh sửa địa điểm du lịch"),
                ("destination:delete", "Xóa địa điểm", "destination", "Xóa địa điểm khỏi hệ thống"),
                ("restaurant:read", "Xem danh sách nhà hàng", "restaurant", "Xem nhà hàng"),
                ("restaurant:write", "Quản lý nhà hàng", "restaurant", "Thêm, sửa, ẩn nhà hàng dọc lộ trình"),
                ("local_food:read", "Xem đặc sản", "local_food", "Xem đặc sản địa phương"),
                ("local_food:write", "Quản lý đặc sản", "local_food", "Thêm, sửa, ẩn đặc sản địa phương"),
                ("itinerary:read", "Xem lịch trình mẫu", "itinerary", "Xem lịch trình mẫu"),
                ("itinerary:write", "Quản lý lịch trình mẫu", "itinerary", "Tạo và chỉnh sửa lịch trình mẫu"),
                ("report:moderate", "Duyệt báo cáo & đánh giá", "report", "Xác minh và xử lý báo sai thông tin"),
                ("partner:manage", "Quản lý đối tác & tài trợ", "partner", "Gắn nhãn tài trợ và nguồn dữ liệu đối tác"),
                ("user:manage", "Quản lý tài khoản & RBAC", "user", "Phân quyền Role/Permission và khóa tài khoản"),
                ("audit:read", "Xem nhật ký Audit Logs", "audit", "Tra cứu lịch sử thao tác quản trị"),
                ("crawler:manage", "Quản lý crawl dữ liệu", "crawler", "Quản lý tiến trình thu thập dữ liệu"),
                ("maps_quota:read", "Xem hạn mức bản đồ", "maps", "Xem hạn mức và quota bản đồ"),
                ("image:upload", "Tải ảnh lên hệ thống", "media", "Tải ảnh lên Cloudinary CDN")
            };

            var permMap = new Dictionary<string, Permission>();
            int pId = 1;
            foreach (var (code, name, module, desc) in permissionDefs)
            {
                var p = new Permission { Id = pId++, Code = code, Name = name, Module = module, Description = desc };
                db.Permissions.Add(p);
                permMap[code] = p;
            }
            await db.SaveChangesAsync();

            var roleDefs = new (int Id, string Code, string Name, string Desc)[]
            {
                (1, "super_admin", "Super Admin", "Toàn quyền hệ thống, quản lý nhân sự, phân quyền Role/Permission."),
                (2, "content_admin", "Content Admin", "Quản lý và duyệt xuất bản nội dung toàn quốc."),
                (3, "province_editor", "Nhân viên Nội dung theo Tỉnh", "Tạo và chỉnh sửa dữ liệu trong phạm vi tỉnh được phân công."),
                (4, "moderator", "Kiểm duyệt viên (Moderator)", "Kiểm duyệt đánh giá, cộng đồng và xử lý báo cáo sai thông tin."),
                (5, "user", "Du khách (User)", "Người dùng ứng dụng di động khám phá du lịch và tạo chuyến đi.")
            };

            foreach (var (rId, rCode, rName, rDesc) in roleDefs)
            {
                var role = new Role { Id = rId, Code = rCode, Name = rName, Description = rDesc };
                db.Roles.Add(role);

                var allowedCodes = rCode == "super_admin" 
                    ? permissionDefs.Select(p => p.Code).ToList()
                    : rCode == "user" 
                        ? new List<string> { "destination:read", "restaurant:read", "local_food:read", "itinerary:read" }
                        : new List<string> { "destination:read", "destination:write", "restaurant:read", "restaurant:write", "local_food:read", "local_food:write", "itinerary:read", "report:moderate" };

                db.AdminRoles.Add(new AdminRole
                {
                    Id = rId,
                    RoleCode = rCode,
                    RoleName = rName,
                    PermissionsJson = JsonSerializer.Serialize(allowedCodes),
                    Description = rDesc
                });

                foreach (var code in allowedCodes)
                {
                    if (permMap.TryGetValue(code, out var perm))
                    {
                        db.RolePermissionLinks.Add(new RolePermissionLink
                        {
                            RoleId = rId,
                            PermissionId = perm.Id
                        });
                    }
                }
            }
            await db.SaveChangesAsync();
        }

        // 2. Categories
        if (!await db.Categories.AnyAsync())
        {
            var categories = new[]
            {
                new Category { Id = 1, Code = "heritage", Name = "Di tích lịch sử", IconName = "account_balance", Description = "Di tích quốc gia đặc biệt và công trình lịch sử" },
                new Category { Id = 2, Code = "architecture", Name = "Kiến trúc & Biểu tượng", IconName = "location_city", Description = "Kiến trúc cổ điển Pháp và công trình biểu tượng đô thị" },
                new Category { Id = 3, Code = "museum", Name = "Bảo tàng & Văn hóa", IconName = "museum", Description = "Bảo tàng lịch sử, mỹ thuật và không gian văn hóa" },
                new Category { Id = 4, Code = "market", Name = "Chợ & Mua sắm", IconName = "storefront", Description = "Chợ truyền thống và trung tâm giao thương sầm uất" },
                new Category { Id = 5, Code = "street_walk", Name = "Không gian đô thị & Bến sông", IconName = "directions_walk", Description = "Phố đi bộ, quảng trường và du thuyền ven sông" }
            };
            db.Categories.AddRange(categories);
            await db.SaveChangesAsync();
        }

        // 3. 10 Provinces
        if (!await db.Provinces.AnyAsync())
        {
            var provinces = new[]
            {
                new Province
                {
                    Id = 1, Code = "HCM", Name = "TP. Hồ Chí Minh", Region = "Nam Bộ",
                    Description = "Đô thị năng động bậc nhất Việt Nam, nơi giao thoa giữa di sản kiến trúc Pháp cổ điển, dấu ấn lịch sử hào hùng, nhịp sống hiện đại sôi động bên sông Sài Gòn và nền ẩm thực đường phố phong phú.",
                    HeroImage = "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1200&q=80",
                    CenterLat = 10.7769, CenterLng = 106.7009, IsActive = true, DataSource = "internal", UpdatedAt = now
                },
                new Province
                {
                    Id = 2, Code = "DN", Name = "TP. Đà Nẵng", Region = "Trung Bộ",
                    Description = "Thành phố biển đáng sống miền Trung với bãi biển Mỹ Khê quyến rũ, danh thắng Ngũ Hành Sơn, bán đảo Sơn Trà xanh mát, những cây cầu biểu tượng bắc qua sông Hàn và ẩm thực miền Trung đậm đà.",
                    HeroImage = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1200&q=80",
                    CenterLat = 16.0544, CenterLng = 108.2022, IsActive = true, DataSource = "internal", UpdatedAt = now
                },
                new Province
                {
                    Id = 3, Code = "HN", Name = "Thủ đô Hà Nội", Region = "Bắc Bộ",
                    Description = "Thủ đô nghìn năm văn hiến với 36 phố phường cổ kính, Hồ Gươm lịch sử, Văn Miếu - Quốc Tử Giám, Hoàng thành Thăng Long và tinh hoa ẩm thực Bắc Bộ thanh tao.",
                    HeroImage = "https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1200&q=80",
                    CenterLat = 21.0285, CenterLng = 105.8542, IsActive = true, DataSource = "internal", UpdatedAt = now
                },
                new Province
                {
                    Id = 4, Code = "QN", Name = "Quảng Ninh (Vịnh Hạ Long)", Region = "Bắc Bộ",
                    Description = "Kỳ quan thiên nhiên thế giới Vịnh Hạ Long với hàng nghìn đảo đá vôi kỳ vĩ trên làn nước ngọc bích, Bảo tàng Quảng Ninh hiện đại và ẩm thực hải sản chả mực giã tay trứ danh.",
                    HeroImage = "https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1200&q=80",
                    CenterLat = 20.9599, CenterLng = 107.0425, IsActive = true, DataSource = "internal", UpdatedAt = now
                },
                new Province
                {
                    Id = 5, Code = "LC", Name = "Lào Cai (Sa Pa)", Region = "Bắc Bộ",
                    Description = "Thị trấn trong sương vùng cao Tây Bắc với đỉnh Fansipan - Nóc nhà Đông Dương hùng vĩ, thung lũng ruộng bậc thang Mường Hoa, bản Cát Cát và ẩm thực thắng cố, lẩu cá hồi đặc sắc.",
                    HeroImage = "https://images.unsplash.com/photo-1540611025311-01df3cef54b5?auto=format&fit=crop&w=1200&q=80",
                    CenterLat = 22.3364, CenterLng = 103.8438, IsActive = true, DataSource = "internal", UpdatedAt = now
                },
                new Province
                {
                    Id = 6, Code = "HUE", Name = "Thừa Thiên Huế (Cố đô Huế)", Region = "Trung Bộ",
                    Description = "Kinh đô xưa của triều đại nhà Nguyễn với Quần thể di tích Cố đô Huế được UNESCO công nhận, chùa Thiên Mụ bên dòng sông Hương thơ mộng và nền ẩm thực cung đình lẫn dân gian tinh tế.",
                    HeroImage = "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1200&q=80",
                    CenterLat = 16.4637, CenterLng = 107.5909, IsActive = true, DataSource = "internal", UpdatedAt = now
                },
                new Province
                {
                    Id = 7, Code = "QNA", Name = "Quảng Nam (Phố cổ Hội An)", Region = "Trung Bộ",
                    Description = "Thương cảng cổ Hội An rực rỡ sắc đèn lồng bên dòng sông Hoài, Chùa Cầu trăm tuổi, Rừng dừa Bảy Mẫu xanh mướt và những món ngon trứ danh Cao lầu, Cơm gà phố Hội.",
                    HeroImage = "https://images.unsplash.com/photo-1555400038-63f5ba517a47?auto=format&fit=crop&w=1200&q=80",
                    CenterLat = 15.8801, CenterLng = 108.3380, IsActive = true, DataSource = "internal", UpdatedAt = now
                },
                new Province
                {
                    Id = 8, Code = "KH", Name = "Khánh Hòa (Nha Trang)", Region = "Trung Bộ",
                    Description = "Thiên đường du lịch biển đảo Nam Trung Bộ với vịnh Nha Trang trong xanh, Tháp Bà Ponagar cổ kính, đảo Hòn Tre sôi động và đặc sản bún chả cá sứa, nem nướng Ninh Hòa.",
                    HeroImage = "https://images.unsplash.com/photo-1536086845232-47c3021fb97c?auto=format&fit=crop&w=1200&q=80",
                    CenterLat = 12.2388, CenterLng = 109.1967, IsActive = true, DataSource = "internal", UpdatedAt = now
                },
                new Province
                {
                    Id = 9, Code = "LD", Name = "Lâm Đồng (Đà Lạt)", Region = "Tây Nguyên",
                    Description = "Thành phố ngàn hoa trên cao nguyên Lâm Viên se lạnh quanh năm với Hồ Xuân Hương, Quảng trường Lâm Viên, đỉnh Langbiang huyền thoại và ẩm thực phố núi ấm áp.",
                    HeroImage = "https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=1200&q=80",
                    CenterLat = 11.9404, CenterLng = 108.4583, IsActive = true, DataSource = "internal", UpdatedAt = now
                },
                new Province
                {
                    Id = 10, Code = "KG", Name = "Kiên Giang (Đảo Ngọc Phú Quốc)", Region = "Nam Bộ",
                    Description = "Đảo Ngọc lớn nhất Việt Nam giữa vịnh Thái Lan với những bãi biển hoàng hôn tuyệt mỹ, Dinh Cậu, Cầu Hôn Sunset Town và đặc sản Bún quậy Kiến Xây, Gỏi cá trích tươi ngon.",
                    HeroImage = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1200&q=80",
                    CenterLat = 10.2899, CenterLng = 103.9840, IsActive = true, DataSource = "internal", UpdatedAt = now
                }
            };
            db.Provinces.AddRange(provinces);
            await db.SaveChangesAsync();
        }

        // 4. Super Admin User
        if (!await db.Users.AnyAsync(u => u.Email == "admin@tripflow.vn"))
        {
            var adminUser = new User
            {
                Id = 1,
                Email = "admin@tripflow.vn",
                Phone = "0909123456",
                FullName = "Super Administrator",
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("Admin@TripFlow2026!"),
                Role = "super_admin",
                RoleId = 1,
                IsActive = true,
                CreatedAt = now
            };
            db.Users.Add(adminUser);

            var demoUser = new User
            {
                Id = 2,
                Email = "user@tripflow.vn",
                Phone = "0901234567",
                FullName = "Phạm Tấn Tài",
                HashedPassword = BCrypt.Net.BCrypt.HashPassword("User@TripFlow2026!"),
                Role = "user",
                RoleId = 5,
                IsActive = true,
                CreatedAt = now
            };
            db.Users.Add(demoUser);

            await db.SaveChangesAsync();
        }

        // 5. Seed Core Seed Destinations & Restaurants (12 Dest & 34 Rest hạt giống)
        if (!await db.Destinations.AnyAsync())
        {
            var coreDests = new[]
            {
                new Destination { Id = 1, ProvinceId = 1, CategoryId = 1, Name = "Dinh Độc Lập", Slug = "dinh-doc-lap", Description = "Biểu tượng lịch sử hào hùng ngày thống nhất đất nước.", Address = "135 Nam Kỳ Khởi Nghĩa, P. Bến Thành, Quận 1", Latitude = 10.7769, Longitude = 106.6953, Rating = 4.8, ReviewCount = 28400, RecommendedDurationMins = 90, ThumbnailUrl = "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=800&q=80", DetailImageUrl = "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1280&q=80", IsFeatured = true, IsVerified = true, LastVerifiedAt = now, UpdatedAt = now },
                new Destination { Id = 2, ProvinceId = 1, CategoryId = 4, Name = "Chợ Bến Thành", Slug = "cho-ben-thanh", Description = "Ngôi chợ biểu tượng của Sài Gòn với ẩm thực và quà lưu niệm phong phú.", Address = "Đường Lê Lợi, P. Bến Thành, Quận 1", Latitude = 10.7725, Longitude = 106.6980, Rating = 4.7, ReviewCount = 35200, RecommendedDurationMins = 60, ThumbnailUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=800&q=80", DetailImageUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1280&q=80", IsFeatured = true, IsVerified = true, LastVerifiedAt = now, UpdatedAt = now },
                new Destination { Id = 3, ProvinceId = 2, CategoryId = 2, Name = "Cầu Vàng Bà Nà Hills", Slug = "cau-vang-ba-na-hills", Description = "Cây cầu được nâng đỡ bởi bàn tay khổng lồ giữa lưng chừng mây.", Address = "Thôn An Sơn, Xã Hòa Ninh, Hòa Vang", Latitude = 15.9992, Longitude = 107.9967, Rating = 4.9, ReviewCount = 42100, RecommendedDurationMins = 120, ThumbnailUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=800&q=80", DetailImageUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1280&q=80", IsFeatured = true, IsVerified = true, LastVerifiedAt = now, UpdatedAt = now },
                new Destination { Id = 4, ProvinceId = 3, CategoryId = 1, Name = "Hồ Hoàn Kiếm & Đền Ngọc Sơn", Slug = "ho-hoan-kiem-den-ngoc-son", Description = "Trái tim của thủ đô Hà Nội ngàn năm văn hiến.", Address = "Phố Đinh Tiên Hoàng, Hoàn Kiếm", Latitude = 21.0307, Longitude = 105.8524, Rating = 4.8, ReviewCount = 38900, RecommendedDurationMins = 60, ThumbnailUrl = "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80", DetailImageUrl = "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1280&q=80", IsFeatured = true, IsVerified = true, LastVerifiedAt = now, UpdatedAt = now },
                new Destination { Id = 5, ProvinceId = 5, CategoryId = 2, Name = "Đỉnh Fansipan - Nóc Nhà Đông Dương", Slug = "dinh-fansipan", Description = "Đỉnh núi cao nhất Việt Nam 3.143m ngắm trọn biển mây tuyệt đẹp.", Address = "Thị xã Sa Pa, Lào Cai", Latitude = 22.3033, Longitude = 103.7753, Rating = 4.9, ReviewCount = 31200, RecommendedDurationMins = 180, ThumbnailUrl = "https://images.unsplash.com/photo-1544085311-11a028465b03?auto=format&fit=crop&w=800&q=80", DetailImageUrl = "https://images.unsplash.com/photo-1544085311-11a028465b03?auto=format&fit=crop&w=1280&q=80", IsFeatured = true, IsVerified = true, LastVerifiedAt = now, UpdatedAt = now },
                new Destination { Id = 6, ProvinceId = 9, CategoryId = 5, Name = "Hồ Xuân Hương & Quảng Trường Lâm Viên", Slug = "ho-xuan-huong", Description = "Hồ nước thơ mộng và biểu tượng bông hoa dã quỳ, nụ atiso khổng lồ.", Address = "Đường Trần Quốc Toản, P. 1, Đà Lạt", Latitude = 11.9366, Longitude = 108.4452, Rating = 4.8, ReviewCount = 29500, RecommendedDurationMins = 90, ThumbnailUrl = "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80", DetailImageUrl = "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1280&q=80", IsFeatured = true, IsVerified = true, LastVerifiedAt = now, UpdatedAt = now },
                new Destination { Id = 7, ProvinceId = 10, CategoryId = 5, Name = "Bãi Sao Phú Quốc", Slug = "bai-sao-phu-quoc", Description = "Bãi cát trắng mịn như kem và làn nước trong xanh màu ngọc bích.", Address = "Ấp Bãi Sao, An Thới, Phú Quốc", Latitude = 10.0528, Longitude = 104.0322, Rating = 4.7, ReviewCount = 18700, RecommendedDurationMins = 120, ThumbnailUrl = "https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=800&q=80", DetailImageUrl = "https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1280&q=80", IsFeatured = true, IsVerified = true, LastVerifiedAt = now, UpdatedAt = now },
                new Destination { Id = 8, ProvinceId = 6, CategoryId = 1, Name = "Đại Nội Huế", Slug = "dai-noi-hue", Description = "Hoàng cung triều Nguyễn với kiến trúc cung đình uy nghiêm.", Address = "Đường 23 Tháng 8, Thuận Hòa, TP. Huế", Latitude = 16.4678, Longitude = 107.5786, Rating = 4.8, ReviewCount = 26500, RecommendedDurationMins = 120, ThumbnailUrl = "https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=800&q=80", DetailImageUrl = "https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=1280&q=80", IsFeatured = true, IsVerified = true, LastVerifiedAt = now, UpdatedAt = now },
                new Destination { Id = 9, ProvinceId = 7, CategoryId = 1, Name = "Phố Cổ Hội An & Chùa Cầu", Slug = "pho-co-hoi-an", Description = "Thương cảng cổ thế kỷ 16 lung linh ánh hoa đăng.", Address = "Phường Minh An, TP. Hội An", Latitude = 15.8778, Longitude = 108.3262, Rating = 4.9, ReviewCount = 52300, RecommendedDurationMins = 150, ThumbnailUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=800&q=80", DetailImageUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=1280&q=80", IsFeatured = true, IsVerified = true, LastVerifiedAt = now, UpdatedAt = now },
                new Destination { Id = 10, ProvinceId = 8, CategoryId = 2, Name = "Tháp Bà Ponagar Nha Trang", Slug = "thap-ba-ponagar", Description = "Quần thể đền tháp Chăm Pa cổ kính trên đồi Cù Lao.", Address = "2 Tháng 4, Vĩnh Phước, Nha Trang", Latitude = 12.2653, Longitude = 109.1958, Rating = 4.7, ReviewCount = 22100, RecommendedDurationMins = 75, ThumbnailUrl = "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80", DetailImageUrl = "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1280&q=80", IsFeatured = true, IsVerified = true, LastVerifiedAt = now, UpdatedAt = now },
                new Destination { Id = 11, ProvinceId = 4, CategoryId = 3, Name = "Bảo tàng Quảng Ninh", Slug = "bao-tang-quang-ninh", Description = "Khối kính đen huyền bí lưu giữ lịch sử văn hóa vùng mỏ.", Address = "Trần Quốc Nghiễn, Tuần Châu, Hạ Long", Latitude = 20.9507, Longitude = 107.0945, Rating = 4.8, ReviewCount = 19800, RecommendedDurationMins = 90, ThumbnailUrl = "https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=800&q=80", DetailImageUrl = "https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1280&q=80", IsFeatured = true, IsVerified = true, LastVerifiedAt = now, UpdatedAt = now },
                new Destination { Id = 12, ProvinceId = 2, CategoryId = 2, Name = "Cầu Rồng Đà Nẵng", Slug = "cau-rong-da-nang", Description = "Cây cầu hình rồng thép vươn ra biển Đông phun lửa và nước cuối tuần.", Address = "Đường Nguyễn Văn Linh, Hải Châu, Đà Nẵng", Latitude = 16.0610, Longitude = 108.2269, Rating = 4.8, ReviewCount = 38000, RecommendedDurationMins = 45, ThumbnailUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=800&q=80", DetailImageUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1280&q=80", IsFeatured = true, IsVerified = true, LastVerifiedAt = now, UpdatedAt = now }
            };
            db.Destinations.AddRange(coreDests);
            await db.SaveChangesAsync();

            foreach (var d in coreDests)
            {
                db.DestinationImages.Add(new DestinationImage
                {
                    DestinationId = d.Id,
                    ImageUrl = d.DetailImageUrl ?? d.ThumbnailUrl ?? "",
                    ThumbnailUrl = d.ThumbnailUrl,
                    Caption = d.Name,
                    SortOrder = 1,
                    LicenseType = "CC BY-SA 4.0",
                    CreditAuthor = "TripFlow Studio"
                });
            }
            await db.SaveChangesAsync();
        }

        if (!await db.Restaurants.AnyAsync())
        {
            var coreRestaurants = new[]
            {
                new Restaurant { Id = 1, ProvinceId = 1, Name = "Cơm Tấm Bụi Sài Gòn - Lê Thánh Tôn", Address = "100 Lê Thánh Tôn, P. Bến Nghé, Quận 1, TP. HCM", Latitude = 10.7785, Longitude = 106.7015, CuisineType = "Cơm tấm & Món Việt", SpecialtyDishes = "Cơm tấm sườn nướng mật ong, bì, chả trứng muối", PriceRange = "55.000đ - 110.000đ", OpeningHours = "06:30 - 22:00", Rating = 4.6, ReviewCount = 940, ReviewsCount = 940, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 2, ProvinceId = 1, Name = "Bánh Mì Huỳnh Hoa - Phạm Ngũ Lão", Address = "26 Lê Thị Riêng, P. Phạm Ngũ Lão, Quận 1, TP. HCM", Latitude = 10.7698, Longitude = 106.6932, CuisineType = "Ẩm thực đường phố", SpecialtyDishes = "Bánh mì đặc ruột pate bơ chả lụa", PriceRange = "65.000đ - 75.000đ", OpeningHours = "06:00 - 22:00", Rating = 4.7, ReviewCount = 2850, ReviewsCount = 2850, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1509722747041-616f39b57569?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1509722747041-616f39b57569?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 3, ProvinceId = 1, Name = "Bếp Mẹ Ỉn - Lê Thánh Tôn", Address = "136/9 Lê Thánh Tôn, P. Bến Thành, Quận 1, TP. HCM", Latitude = 10.7738, Longitude = 106.6975, CuisineType = "Cơm nhà & Đặc sản Nam Bộ", SpecialtyDishes = "Bánh xèo tôm thịt, cơm tấm sườn non", PriceRange = "75.000đ - 180.000đ", OpeningHours = "10:30 - 22:30", Rating = 4.8, ReviewCount = 1780, ReviewsCount = 1780, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 4, ProvinceId = 1, Name = "Nhà hàng Ngon (Quán Ăn Ngon 160 Pasteur)", Address = "160 Pasteur, P. Bến Nghé, Quận 1, TP. HCM", Latitude = 10.7782, Longitude = 106.6968, CuisineType = "Ẩm thực 3 miền & Sài Gòn", SpecialtyDishes = "Bánh khọt Vũng Tàu, Hủ tiếu Nam Vang", PriceRange = "80.000đ - 250.000đ", OpeningHours = "07:00 - 22:30", Rating = 4.6, ReviewCount = 2310, ReviewsCount = 2310, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 5, ProvinceId = 1, Name = "Bánh Xèo 46A Đinh Công Tráng", Address = "46A Đinh Công Tráng, P. Tân Định, Quận 1, TP. HCM", Latitude = 10.7892, Longitude = 106.6905, CuisineType = "Bánh xèo Nam Bộ", SpecialtyDishes = "Bánh xèo chảo gang giòn rụm tôm thịt", PriceRange = "90.000đ - 160.000đ", OpeningHours = "10:00 - 21:00", Rating = 4.5, ReviewCount = 1420, ReviewsCount = 1420, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 6, ProvinceId = 1, Name = "Phở Hòa Pasteur", Address = "260C Pasteur, P. Võ Thị Sáu, Quận 3, TP. HCM", Latitude = 10.7868, Longitude = 106.6884, CuisineType = "Phở Sài Gòn truyền thống", SpecialtyDishes = "Phở bò tái nạm gầu gân sườn quẩy giòn", PriceRange = "75.000đ - 115.000đ", OpeningHours = "05:30 - 22:30", Rating = 4.7, ReviewCount = 2640, ReviewsCount = 2640, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 7, ProvinceId = 1, Name = "Hủ Tiếu Nam Vang Nhân Quán", Address = "A68 Nguyễn Trãi, P. Nguyễn Cư Trinh, Quận 1, TP. HCM", Latitude = 10.7662, Longitude = 106.6820, CuisineType = "Hủ tiếu & Mì Hoa - Việt", SpecialtyDishes = "Hủ tiếu Nam Vang khô và nước tôm thịt", PriceRange = "65.000đ - 95.000đ", OpeningHours = "06:00 - 23:00", Rating = 4.6, ReviewCount = 1180, ReviewsCount = 1180, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 8, ProvinceId = 1, Name = "Cơm Tấm Ba Ghiền - Phú Nhuận", Address = "84 Đặng Văn Ngữ, P. 10, Q. Phú Nhuận, TP. HCM", Latitude = 10.7955, Longitude = 106.6785, CuisineType = "Cơm tấm Sài Gòn", SpecialtyDishes = "Cơm tấm miếng sườn nướng khổng lồ đậm đà", PriceRange = "75.000đ - 145.000đ", OpeningHours = "07:30 - 20:30", Rating = 4.7, ReviewCount = 3190, ReviewsCount = 3190, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 9, ProvinceId = 2, Name = "Mì Quảng Bà Mua - Trần Bình Trọng (Đà Nẵng)", Address = "19-21 Trần Bình Trọng, Q. Hải Châu, TP. Đà Nẵng", Latitude = 16.0642, Longitude = 108.2215, CuisineType = "Đặc sản Xứ Quảng", SpecialtyDishes = "Mì Quảng tôm thịt trứng, cá lóc", PriceRange = "45.000đ - 95.000đ", OpeningHours = "06:30 - 21:30", Rating = 4.7, ReviewCount = 1650, ReviewsCount = 1650, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 10, ProvinceId = 2, Name = "Hải Sản Bé Mặn - Võ Nguyên Giáp", Address = "Lô 8 Võ Nguyên Giáp, Q. Sơn Trà, TP. Đà Nẵng", Latitude = 16.0715, Longitude = 108.2468, CuisineType = "Hải sản tươi sống Đà Nẵng", SpecialtyDishes = "Tôm hùm nướng phô mai, Cua rang me, Mực hấp", PriceRange = "150.000đ - 450.000đ", OpeningHours = "09:00 - 23:30", Rating = 4.6, ReviewCount = 2120, ReviewsCount = 2120, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 11, ProvinceId = 3, Name = "Phở Thìn Bờ Hồ - Đinh Tiên Hoàng", Address = "61 Đinh Tiên Hoàng, Hoàn Kiếm, Hà Nội", Latitude = 21.0294, Longitude = 105.8532, CuisineType = "Phở Bò Hà Nội truyền thống", SpecialtyDishes = "Phở bò tái chín nước dùng ngọt thanh gia truyền", PriceRange = "60.000đ - 100.000đ", OpeningHours = "06:00 - 22:00", Rating = 4.8, ReviewCount = 3210, ReviewsCount = 3210, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 12, ProvinceId = 3, Name = "Bún Chả Hương Liên - Lê Văn Hưu", Address = "24 Lê Văn Hưu, Hai Bà Trưng, Hà Nội", Latitude = 21.0185, Longitude = 105.8528, CuisineType = "Bún chả & Nem cua bể Hà Nội", SpecialtyDishes = "Bún chả than hoa, nem cua bể giòn rụm", PriceRange = "60.000đ - 120.000đ", OpeningHours = "08:00 - 20:30", Rating = 4.7, ReviewCount = 4520, ReviewsCount = 4520, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 13, ProvinceId = 4, Name = "Nhà hàng Hồng Hạnh 3 Hạ Long", Address = "50 Hạ Long, P. Bãi Cháy, TP. Hạ Long, Quảng Ninh", Latitude = 20.9532, Longitude = 107.0585, CuisineType = "Hải sản & Đặc sản Vịnh Hạ Long", SpecialtyDishes = "Chả mực giã tay, tôm hùm bông, bề bề rang muối", PriceRange = "150.000đ - 400.000đ", OpeningHours = "09:00 - 22:30", Rating = 4.8, ReviewCount = 2890, ReviewsCount = 2890, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 14, ProvinceId = 4, Name = "Bún Bề Bề & Chả Mực Làng Chài Hạ Long", Address = "Đường Trần Quốc Nghiễn, P. Hồng Gai, TP. Hạ Long", Latitude = 20.9488, Longitude = 107.0825, CuisineType = "Bún hải sản & Chả mực", SpecialtyDishes = "Bún bề bề tôm nõn, Bánh cuốn chả mực giã tay", PriceRange = "50.000đ - 110.000đ", OpeningHours = "06:00 - 21:00", Rating = 4.7, ReviewCount = 1540, ReviewsCount = 1540, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 15, ProvinceId = 5, Name = "Nhà hàng A Phủ Sa Pa - Fansipan", Address = "15 Fansipan, Thị xã Sa Pa, Lào Cai", Latitude = 22.3325, Longitude = 103.8402, CuisineType = "Đặc sản Dân tộc Tây Bắc", SpecialtyDishes = "Thắng cố ngựa, Lẩu cá hồi vân, Lợn cắp nách", PriceRange = "120.000đ - 320.000đ", OpeningHours = "09:00 - 23:00", Rating = 4.8, ReviewCount = 2410, ReviewsCount = 2410, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 16, ProvinceId = 5, Name = "Lẩu Cá Hồi & Đồ Nướng Bản Mây Sa Pa", Address = "086 Đường Cát Cát, Thị xã Sa Pa, Lào Cai", Latitude = 22.3292, Longitude = 103.8358, CuisineType = "Lẩu Cá Hồi & Nướng Sa Pa", SpecialtyDishes = "Lẩu cá hồi cải mèo, Cá tầm nướng, Cơm lam", PriceRange = "100.000đ - 280.000đ", OpeningHours = "08:00 - 22:30", Rating = 4.7, ReviewCount = 1690, ReviewsCount = 1690, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 17, ProvinceId = 6, Name = "Bún Bò Huế Mệ Kéo - Bạch Đằng", Address = "20 Bạch Đằng, P. Phú Cát, TP. Huế", Latitude = 16.4712, Longitude = 107.5865, CuisineType = "Bún bò Huế gia truyền", SpecialtyDishes = "Bún bò Huế giò heo, chả cua, mắm ruốc sả", PriceRange = "45.000đ - 75.000đ", OpeningHours = "06:00 - 11:00", Rating = 4.8, ReviewCount = 2760, ReviewsCount = 2760, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 18, ProvinceId = 6, Name = "Quán Hạnh - Bánh Bèo Nậm Lọc", Address = "11 Phó Đức Chính, P. Phú Hội, TP. Huế", Latitude = 16.4628, Longitude = 107.5892, CuisineType = "Đặc sản Bánh Huế & Nem lụi", SpecialtyDishes = "Bánh bèo chén tôm chấy, bánh nậm, bánh lọc", PriceRange = "50.000đ - 120.000đ", OpeningHours = "09:00 - 21:30", Rating = 4.7, ReviewCount = 3150, ReviewsCount = 3150, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 19, ProvinceId = 7, Name = "Cơm Gà Bà Buội Phố Cổ Hội An", Address = "22 Phan Chu Trinh, P. Minh An, TP. Hội An", Latitude = 15.8782, Longitude = 108.3295, CuisineType = "Cơm gà Hội An gia truyền", SpecialtyDishes = "Cơm gà xé gỏi hành tây nước lòng gà nghệ", PriceRange = "55.000đ - 95.000đ", OpeningHours = "10:00 - 21:00", Rating = 4.8, ReviewCount = 3420, ReviewsCount = 3420, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 20, ProvinceId = 7, Name = "Cao Lầu Không Gian Xanh Hội An", Address = "687 Hai Bà Trưng, P. Minh An, TP. Hội An", Latitude = 15.8778, Longitude = 108.3272, CuisineType = "Cao lầu & Đặc sản Phố Hội", SpecialtyDishes = "Cao lầu sợi vàng thịt xá xíu tóp mỡ giòn", PriceRange = "45.000đ - 90.000đ", OpeningHours = "08:30 - 21:30", Rating = 4.7, ReviewCount = 2190, ReviewsCount = 2190, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 21, ProvinceId = 8, Name = "Nem Nướng Đặng Văn Quyên Nha Trang", Address = "16A Lãn Ông, P. Xương Huân, TP. Nha Trang", Latitude = 12.2485, Longitude = 109.1932, CuisineType = "Nem nướng Ninh Hòa", SpecialtyDishes = "Nem nướng lụi than hồng nước chấm nếp thịt", PriceRange = "60.000đ - 120.000đ", OpeningHours = "07:30 - 21:30", Rating = 4.7, ReviewCount = 3680, ReviewsCount = 3680, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 22, ProvinceId = 8, Name = "Bún Cá Sứa Năm Beo Chợ Đầm", Address = "B2 Chung cư Phan Bội Châu, TP. Nha Trang", Latitude = 12.2535, Longitude = 109.1925, CuisineType = "Bún chả cá sứa Nha Trang", SpecialtyDishes = "Bún cá dầm, chả cá thu chiên sứa giòn sần sật", PriceRange = "45.000đ - 75.000đ", OpeningHours = "06:00 - 21:00", Rating = 4.8, ReviewCount = 2140, ReviewsCount = 2140, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 23, ProvinceId = 9, Name = "Lẩu Gà Lá É Tao Ngộ Đà Lạt", Address = "05 Đường 3 Tháng 4, P. 3, TP. Đà Lạt", Latitude = 11.9362, Longitude = 108.4485, CuisineType = "Đặc sản Lẩu phố núi Đà Lạt", SpecialtyDishes = "Lẩu gà lá é cay nồng ớt xiêm xanh", PriceRange = "200.000đ - 350.000đ", OpeningHours = "08:00 - 22:00", Rating = 4.7, ReviewCount = 4120, ReviewsCount = 4120, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 24, ProvinceId = 9, Name = "Quán Gỗ (Lẩu Bò Ba Toa Đà Lạt)", Address = "1/29 Hoàng Diệu, P. 5, TP. Đà Lạt", Latitude = 11.9421, Longitude = 108.4312, CuisineType = "Lẩu bò Ba Toa truyền thống", SpecialtyDishes = "Lẩu bò nhúng rau má, giò bò mềm ngọt", PriceRange = "150.000đ - 300.000đ", OpeningHours = "10:00 - 22:00", Rating = 4.8, ReviewCount = 9400, ReviewsCount = 9400, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 25, ProvinceId = 10, Name = "Bún Quậy Kiến Xây Phú Quốc - Bạch Đằng", Address = "28 Bạch Đằng, P. Dương Đông, TP. Phú Quốc", Latitude = 10.2185, Longitude = 103.9621, CuisineType = "Bún quậy hải sản Phú Quốc", SpecialtyDishes = "Bún quậy chả tôm mực tươi xay tại chỗ", PriceRange = "55.000đ - 85.000đ", OpeningHours = "07:00 - 22:00", Rating = 4.8, ReviewCount = 7600, ReviewsCount = 7600, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now },
                new Restaurant { Id = 26, ProvinceId = 10, Name = "Hải Sản Xin Chào Phú Quốc - Trần Hưng Đạo", Address = "66 Trần Hưng Đạo, P. Dương Đông, TP. Phú Quốc", Latitude = 10.2112, Longitude = 103.9585, CuisineType = "Hải sản ngắm hoàng hôn biển Phú Quốc", SpecialtyDishes = "Gỏi cá trích, Nhum biển nướng mỡ hành, Còi biên mai", PriceRange = "150.000đ - 450.000đ", OpeningHours = "11:00 - 23:00", Rating = 4.7, ReviewCount = 3890, ReviewsCount = 3890, IsHighRated = true, ImageUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=900&q=80", ThumbnailUrl = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=400&q=80", IsVerified = true, LastUpdatedAt = now }
            };
            db.Restaurants.AddRange(coreRestaurants);
            await db.SaveChangesAsync();
        }

        // 6. Local Foods & Itineraries
        if (!await db.LocalFoods.AnyAsync())
        {
            var foods = new[]
            {
                new LocalFood { Id = 1, ProvinceId = 1, Name = "Cơm Tấm Sườn Bì Chả", Description = "Đĩa cơm hạt tấm nóng hổi ăn kèm sườn nướng mỡ hành, chả trứng béo ngậy và nước mắm chua ngọt kẹo.", StoryOrigin = "Món ăn bình dân từ gạo tấm của người Nam Bộ xưa nay thành đặc sản trứ danh.", BestSeasonOrTime = "Quanh năm (Sáng hoặc trưa)", AvgPriceRange = "45.000đ - 120.000đ", ImageUrl = "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80", RecommendedRestaurantIdsJson = "[1]" },
                new LocalFood { Id = 2, ProvinceId = 3, Name = "Phở Bò Hà Nội", Description = "Bánh phở mềm dai, nước dùng ninh từ xương bò với quế hồi thanh tao không gắt dầu mỡ.", StoryOrigin = "Nét ẩm thực thanh lịch ngàn năm đất Tràng An.", BestSeasonOrTime = "Mùa thu - đông buổi sáng", AvgPriceRange = "50.000đ - 85.000đ", ImageUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=800&q=80", RecommendedRestaurantIdsJson = "[2]" },
                new LocalFood { Id = 3, ProvinceId = 9, Name = "Lẩu Bò Ba Toa & Bánh Căn", Description = "Nồi lẩu bò nghi ngút khói giữa tiết trời lành lạnh xứ sương mù ăn kèm rau xanh tươi.", StoryOrigin = "Văn hóa ẩm thực đường phố cao nguyên Lâm Viên.", BestSeasonOrTime = "Buổi tối trời lạnh", AvgPriceRange = "150.000đ - 300.000đ", ImageUrl = "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80", RecommendedRestaurantIdsJson = "[3]" }
            };
            db.LocalFoods.AddRange(foods);
            await db.SaveChangesAsync();
        }

        if (!await db.Itineraries.AnyAsync())
        {
            var it = new Itinerary
            {
                Id = 1,
                UserId = 1,
                ProvinceId = 9,
                Title = "Đà Lạt Mộng Mơ 3N2Đ",
                Description = "Lịch trình săn mây đồi chè Cầu Đất, cà phê hoàng hôn và ẩm thực lẩu bò Ba Toa.",
                TotalDays = 3,
                IsTemplate = true,
                Status = "active",
                CreatedAt = now,
                UpdatedAt = now
            };
            db.Itineraries.Add(it);
            await db.SaveChangesAsync();

            db.ItineraryStops.AddRange(new[]
            {
                new ItineraryStop { ItineraryId = it.Id, DayNumber = 1, StopOrder = 1, StopType = "meal", Title = "Ăn sáng Bánh mì xíu mại Hoàng Diệu", PlannedTime = "07:30", DurationMins = 45, Latitude = 11.9421, Longitude = 108.4312 },
                new ItineraryStop { ItineraryId = it.Id, DayNumber = 1, StopOrder = 2, StopType = "destination", Title = "Check-in Quảng trường Lâm Viên & Hồ Xuân Hương", PlannedTime = "09:00", DurationMins = 90, Latitude = 11.9366, Longitude = 108.4452 },
                new ItineraryStop { ItineraryId = it.Id, DayNumber = 1, StopOrder = 3, StopType = "meal", Title = "Trưa: Thưởng thức Lẩu Bò Quán Gỗ Ba Toa", PlannedTime = "12:00", DurationMins = 75, Latitude = 11.9421, Longitude = 108.4312 },
                new ItineraryStop { ItineraryId = it.Id, DayNumber = 2, StopOrder = 1, StopType = "destination", Title = "Săn mây Đồi Chè Cầu Đất đón bình minh", PlannedTime = "05:30", DurationMins = 120, Latitude = 11.8542, Longitude = 108.5412 },
                new ItineraryStop { ItineraryId = it.Id, DayNumber = 2, StopOrder = 2, StopType = "destination", Title = "Trải nghiệm máng trượt Thác Datanla", PlannedTime = "14:00", DurationMins = 90, Latitude = 11.9025, Longitude = 108.4485 }
            });
            await db.SaveChangesAsync();
        }

        // 7. Load catalog_extra.json
        await SeedCatalogExtraAsync(db, now);

        // 8. Load rest_stops_extra.json
        await SeedRestStopsExtraAsync(db, now);

        // 9. Reset PostgreSQL sequences
        await SeederExtensions.ResetPostgresSequencesAsync(db);
    }

    private static string? FindDataFile(string filename)
    {
        var candidates = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Data", filename),
            Path.Combine(AppContext.BaseDirectory, filename),
            Path.Combine(AppContext.BaseDirectory, "data", filename),
            Path.Combine(Directory.GetCurrentDirectory(), "Data", filename),
            Path.Combine(Directory.GetCurrentDirectory(), filename),
            Path.Combine(Directory.GetCurrentDirectory(), "backend", "Data", filename),
            Path.Combine(Directory.GetCurrentDirectory(), "..", "Data", filename),
            Path.Combine(Directory.GetCurrentDirectory(), "..", "backend", "Data", filename),
            Path.Combine("D:\\trip_flow\\backend\\Data", filename)
        };
        return candidates.FirstOrDefault(File.Exists);
    }

    private static double DistanceKm(double lat1, double lng1, double lat2, double lng2)
    {
        double dx = (lng1 - lng2) * Math.Cos(((lat1 + lat2) / 2) * Math.PI / 180.0);
        double dy = lat1 - lat2;
        return Math.Sqrt(dx * dx + dy * dy) * 111.32;
    }

    private static async Task SeedCatalogExtraAsync(TripFlowDbContext db, DateTime now)
    {
        var filePath = FindDataFile("catalog_extra.json");
        if (filePath == null) return;

        try
        {
            var json = await File.ReadAllTextAsync(filePath);
            using var doc = JsonDocument.Parse(json);
            if (!doc.RootElement.TryGetProperty("records", out var recordsElem)) return;

            var provinces = await db.Provinces.ToDictionaryAsync(p => p.Code, p => p);
            var categories = await db.Categories.ToDictionaryAsync(c => c.Code, c => c);
            var defaultCategory = categories.Values.FirstOrDefault();

            var existingDestNames = await db.Destinations.Select(d => new { d.ProvinceId, d.Name, d.Latitude, d.Longitude }).ToListAsync();
            var existingRestNames = await db.Restaurants.Select(r => new { r.ProvinceId, r.Name }).ToListAsync();

            foreach (var item in recordsElem.EnumerateArray())
            {
                var type = item.TryGetProperty("type", out var tProp) ? tProp.GetString() : null;
                var provCode = item.TryGetProperty("province_code", out var pProp) ? pProp.GetString() : null;
                if (string.IsNullOrEmpty(provCode) || !provinces.TryGetValue(provCode, out var province)) continue;

                if (!item.TryGetProperty("lat", out var latProp) || !item.TryGetProperty("lng", out var lngProp)) continue;
                double lat = latProp.GetDouble();
                double lng = lngProp.GetDouble();

                var name = item.TryGetProperty("name", out var nProp) ? nProp.GetString()?.Trim() : null;
                if (string.IsNullOrEmpty(name)) continue;

                var address = item.TryGetProperty("address", out var aProp) ? aProp.GetString() : province.Name;
                var desc = item.TryGetProperty("description", out var descProp) ? descProp.GetString() : name;
                var openingHours = item.TryGetProperty("opening_hours", out var opProp) ? opProp.GetString() : "";
                var priceRange = item.TryGetProperty("price_range", out var prProp) ? prProp.GetString() : "";
                var phone = item.TryGetProperty("phone", out var phProp) ? phProp.GetString() : null;

                string? imgUrl = null;
                string? thumbUrl = null;
                string? license = null;
                string? author = null;
                string? srcUrl = null;

                if (item.TryGetProperty("image", out var imgElem) && imgElem.ValueKind == JsonValueKind.Object)
                {
                    imgUrl = imgElem.TryGetProperty("url", out var u) ? u.GetString() : null;
                    thumbUrl = imgElem.TryGetProperty("thumb_url", out var tu) ? tu.GetString() : null;
                    license = imgElem.TryGetProperty("license", out var l) ? l.GetString() : null;
                    author = imgElem.TryGetProperty("author", out var au) ? au.GetString() : null;
                    srcUrl = imgElem.TryGetProperty("source_url", out var su) ? su.GetString() : null;
                }

                if (type == "destination")
                {
                    bool exists = existingDestNames.Any(d => d.ProvinceId == province.Id && (d.Name == name || DistanceKm(d.Latitude, d.Longitude, lat, lng) <= 0.10));
                    if (exists) continue;

                    var catCode = item.TryGetProperty("category", out var cProp) ? cProp.GetString() ?? "heritage" : "heritage";
                    var category = categories.TryGetValue(catCode, out var c) ? c : defaultCategory;

                    var dest = new Destination
                    {
                        ProvinceId = province.Id,
                        CategoryId = category?.Id ?? 1,
                        Name = name,
                        Slug = item.TryGetProperty("slug", out var sProp) ? sProp.GetString() : null,
                        Description = desc ?? name,
                        Address = address ?? province.Name,
                        Latitude = lat,
                        Longitude = lng,
                        OpeningHours = string.IsNullOrEmpty(openingHours) ? "07:30 - 17:30" : openingHours,
                        TicketPriceInfo = string.IsNullOrEmpty(priceRange) ? "Miễn phí" : priceRange,
                        Rating = 4.7,
                        ReviewCount = 120,
                        RecommendedDurationMins = 90,
                        ThumbnailUrl = thumbUrl ?? imgUrl,
                        DetailImageUrl = imgUrl ?? thumbUrl,
                        IsFeatured = true,
                        IsVerified = true,
                        Source = "wikimedia",
                        SourceUrl = srcUrl ?? "",
                        DataSource = "wikimedia",
                        SourceAttribution = $"Ảnh: {author ?? "Wikimedia Commons"} ({license ?? "CC BY-SA"})",
                        LastVerifiedAt = now,
                        UpdatedAt = now
                    };
                    db.Destinations.Add(dest);
                    await db.SaveChangesAsync();

                    if (!string.IsNullOrEmpty(imgUrl))
                    {
                        db.DestinationImages.Add(new DestinationImage
                        {
                            DestinationId = dest.Id,
                            ImageUrl = imgUrl,
                            ThumbnailUrl = thumbUrl,
                            Caption = name,
                            SortOrder = 1,
                            LicenseType = license ?? "CC BY-SA",
                            CreditAuthor = author ?? "Wikimedia Commons"
                        });
                    }
                    existingDestNames.Add(new { ProvinceId = province.Id, Name = name, Latitude = lat, Longitude = lng });
                }
                else if (type is "restaurant" or "cafe")
                {
                    bool exists = existingRestNames.Any(r => r.ProvinceId == province.Id && r.Name == name);
                    if (exists) continue;

                    var cuisine = item.TryGetProperty("cuisine", out var cuProp) ? cuProp.GetString() : "Đặc sản địa phương";
                    var specialties = item.TryGetProperty("specialties", out var spProp) ? spProp.GetString() : null;

                    var rest = new Restaurant
                    {
                        ProvinceId = province.Id,
                        Name = name,
                        Address = address ?? province.Name,
                        Latitude = lat,
                        Longitude = lng,
                        CuisineType = cuisine ?? "Đặc sản",
                        SpecialtyDishes = specialties,
                        PriceRange = string.IsNullOrEmpty(priceRange) ? "45.000đ - 120.000đ" : priceRange,
                        OpeningHours = string.IsNullOrEmpty(openingHours) ? "07:00 - 22:00" : openingHours,
                        ContactPhone = phone,
                        Rating = 4.6,
                        ReviewCount = 120,
                        ReviewsCount = 120,
                        SampleReviewsJson = "[]",
                        IsHighRated = true,
                        ImageUrl = imgUrl,
                        ThumbnailUrl = thumbUrl,
                        ImageCredit = author,
                        ImageLicense = license,
                        ImageSourceUrl = srcUrl,
                        IsVerified = true,
                        Source = "wikimedia",
                        SourceUrl = srcUrl ?? "",
                        DataSource = "wikimedia",
                        LastUpdatedAt = now
                    };
                    db.Restaurants.Add(rest);
                    existingRestNames.Add(new { ProvinceId = province.Id, Name = name });
                }
            }
            await db.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[SeedCatalogExtraAsync] Warning: {ex.Message}");
        }
    }

    private static async Task SeedRestStopsExtraAsync(TripFlowDbContext db, DateTime now)
    {
        var filePath = FindDataFile("rest_stops_extra.json");
        if (filePath == null) return;

        try
        {
            var json = await File.ReadAllTextAsync(filePath);
            using var doc = JsonDocument.Parse(json);
            if (doc.RootElement.ValueKind != JsonValueKind.Array) return;

            var provinces = await db.Provinces.ToDictionaryAsync(p => p.Code, p => p);
            var existingStops = await db.RestStops.Select(rs => new { rs.ProvinceId, rs.Name, rs.Category }).ToListAsync();

            foreach (var item in doc.RootElement.EnumerateArray())
            {
                var provCode = item.TryGetProperty("province_code", out var pProp) ? pProp.GetString() : null;
                if (string.IsNullOrEmpty(provCode) || !provinces.TryGetValue(provCode, out var province)) continue;

                var name = item.TryGetProperty("name", out var nProp) ? nProp.GetString()?.Trim() : null;
                if (string.IsNullOrEmpty(name)) continue;

                if (!item.TryGetProperty("latitude", out var latProp) || !item.TryGetProperty("longitude", out var lngProp)) continue;
                double lat = latProp.GetDouble();
                double lng = lngProp.GetDouble();

                var category = item.TryGetProperty("category", out var cProp) ? cProp.GetString() ?? "rest" : "rest";
                bool exists = existingStops.Any(s => s.ProvinceId == province.Id && s.Name == name && s.Category == category);
                if (exists) continue;

                var address = item.TryGetProperty("address", out var aProp) ? aProp.GetString() : province.Name;
                var brand = item.TryGetProperty("brand", out var bProp) ? bProp.GetString() : null;
                var phone = item.TryGetProperty("phone", out var phProp) ? phProp.GetString() : null;
                var opHours = item.TryGetProperty("opening_hours", out var opProp) ? opProp.GetString() : "";
                var desc = item.TryGetProperty("description", out var dProp) ? dProp.GetString() : null;
                var srcUrl = item.TryGetProperty("source_url", out var suProp) ? suProp.GetString() : "";

                var stop = new RestStop
                {
                    ProvinceId = province.Id,
                    Category = category,
                    Name = name,
                    Address = address ?? province.Name,
                    Latitude = lat,
                    Longitude = lng,
                    OpeningHours = opHours ?? "24/7",
                    Phone = phone,
                    Description = desc,
                    Brand = brand,
                    Source = "osm",
                    SourceUrl = srcUrl,
                    DataSource = "osm",
                    Status = "published",
                    IsVerified = true,
                    Rating = 4.5,
                    ReviewCount = 45,
                    UpdatedAt = now
                };
                db.RestStops.Add(stop);
                existingStops.Add(new { ProvinceId = province.Id, Name = name, Category = category });
            }
            await db.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[SeedRestStopsExtraAsync] Warning: {ex.Message}");
        }
    }
}
