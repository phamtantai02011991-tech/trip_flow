using TripFlow.Api.Models;

namespace TripFlow.Api.Data;

public static class TripFlowSeedData
{
    public static List<Province> GetProvinces() => new()
    {
        new Province { Id = 1, Code = "HCM", Name = "TP. Hồ Chí Minh", Region = "Nam Bộ", Description = "Trung tâm kinh tế, văn hóa sôi động với Dinh Độc Lập, Chợ Bến Thành, phố đi bộ Nguyễn Huệ.", HeroImage = "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1280&q=80", CenterLat = 10.7769, CenterLng = 106.7009, DestinationCount = 4, FoodCount = 3, RestaurantCount = 3 },
        new Province { Id = 2, Code = "DN", Name = "Đà Nẵng", Region = "Trung Bộ", Description = "Thành phố đáng sống với Cầu Rồng phun lửa, bãi biển Mỹ Khê và Bà Nà Hills kỳ vĩ.", HeroImage = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1280&q=80", CenterLat = 16.0544, CenterLng = 108.2022, DestinationCount = 3, FoodCount = 3, RestaurantCount = 2 },
        new Province { Id = 3, Code = "HN", Name = "Thủ đô Hà Nội", Region = "Bắc Bộ", Description = "Thủ đô nghìn năm văn hiến với 36 phố phường, Hồ Gươm, Hoàng thành Thăng Long.", HeroImage = "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1280&q=80", CenterLat = 21.0285, CenterLng = 105.8542, DestinationCount = 3, FoodCount = 2, RestaurantCount = 2 },
        new Province { Id = 4, Code = "QN", Name = "Quảng Ninh (Hạ Long)", Region = "Bắc Bộ", Description = "Kỳ quan thiên nhiên thế giới Vịnh Hạ Long, Bảo tàng Quảng Ninh và chả mực trứ danh.", HeroImage = "https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1280&q=80", CenterLat = 20.9599, CenterLng = 107.0425, DestinationCount = 2, FoodCount = 2, RestaurantCount = 2 },
        new Province { Id = 5, Code = "LC", Name = "Lào Cai (Sa Pa)", Region = "Bắc Bộ", Description = "Thị trấn sương mờ với đỉnh Fansipan - Nóc nhà Đông Dương, thung lũng Mường Hoa.", HeroImage = "https://images.unsplash.com/photo-1544085311-11a028465b03?auto=format&fit=crop&w=1280&q=80", CenterLat = 22.3364, CenterLng = 103.8438, DestinationCount = 2, FoodCount = 2, RestaurantCount = 2 },
        new Province { Id = 6, Code = "HUE", Name = "Thừa Thiên Huế", Region = "Trung Bộ", Description = "Cố đô triều Nguyễn với Đại Nội, chùa Thiên Mụ, sông Hương thơ mộng.", HeroImage = "https://images.unsplash.com/photo-1569154941061-e231b4725ef1?auto=format&fit=crop&w=1280&q=80", CenterLat = 16.4637, CenterLng = 107.5909, DestinationCount = 2, FoodCount = 2, RestaurantCount = 2 },
        new Province { Id = 7, Code = "QNA", Name = "Quảng Nam (Hội An)", Region = "Trung Bộ", Description = "Phố cổ Hội An đèn lồng rực rỡ, Chùa Cầu, Rừng dừa Bảy Mẫu, Cao lầu, Cơm gà.", HeroImage = "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=1280&q=80", CenterLat = 15.8801, CenterLng = 108.3380, DestinationCount = 2, FoodCount = 2, RestaurantCount = 2 },
        new Province { Id = 8, Code = "KH", Name = "Khánh Hòa (Nha Trang)", Region = "Trung Bộ", Description = "Thiên đường biển đảo với Vịnh Nha Trang, Tháp Bà Ponagar, hải sản tươi ngon.", HeroImage = "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1280&q=80", CenterLat = 12.2388, CenterLng = 109.1967, DestinationCount = 2, FoodCount = 2, RestaurantCount = 2 },
        new Province { Id = 9, Code = "LD", Name = "Lâm Đồng (Đà Lạt)", Region = "Tây Nguyên", Description = "Thành phố ngàn hoa xứ sở sương mù, Hồ Xuân Hương, đỉnh Langbiang hùng vĩ.", HeroImage = "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1280&q=80", CenterLat = 11.9404, CenterLng = 108.4583, DestinationCount = 2, FoodCount = 2, RestaurantCount = 2 },
        new Province { Id = 10, Code = "KG", Name = "Kiên Giang (Phú Quốc)", Region = "Nam Bộ", Description = "Đảo Ngọc Phú Quốc với Bãi Sao, hoàng hôn Sunset Town, Bún quậy Kiến Xây.", HeroImage = "https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1280&q=80", CenterLat = 10.2289, CenterLng = 103.9572, DestinationCount = 2, FoodCount = 2, RestaurantCount = 2 },
    };

    public static List<Destination> GetDestinations() => new()
    {
        new Destination { Id = 1, Name = "Dinh Độc Lập", ProvinceId = 1, ProvinceName = "TP. Hồ Chí Minh", Category = "Di tích lịch sử", Description = "Biểu tượng lịch sử ghi dấu ngày thống nhất đất nước.", ImageUrl = "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=800&q=80", Latitude = 10.7769, Longitude = 106.6953, Rating = 4.8, ReviewsCount = 28400, Address = "135 Nam Kỳ Khởi Nghĩa, P. Bến Thành, Quận 1", TicketPrice = 65000 },
        new Destination { Id = 2, Name = "Chợ Bến Thành", ProvinceId = 1, ProvinceName = "TP. Hồ Chí Minh", Category = "Chợ & Mua sắm", Description = "Ngôi chợ biểu tượng của Sài Gòn với ẩm thực và quà lưu niệm phong phú.", ImageUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=800&q=80", Latitude = 10.7725, Longitude = 106.6980, Rating = 4.7, ReviewsCount = 35200, Address = "Đường Lê Lợi, P. Bến Thành, Quận 1", TicketPrice = 0 },
        new Destination { Id = 3, Name = "Cầu Vàng Bà Nà Hills", ProvinceId = 2, ProvinceName = "Đà Nẵng", Category = "Kỳ quan kiến trúc", Description = "Cây cầu được nâng đỡ bởi bàn tay khổng lồ giữa lưng chừng mây.", ImageUrl = "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=800&q=80", Latitude = 15.9992, Longitude = 107.9967, Rating = 4.9, ReviewsCount = 42100, Address = "Thôn An Sơn, Xã Hòa Ninh, Hòa Vang", TicketPrice = 850000 },
        new Destination { Id = 4, Name = "Hồ Hoàn Kiếm & Đền Ngọc Sơn", ProvinceId = 3, ProvinceName = "Thủ đô Hà Nội", Category = "Danh lam thắng cảnh", Description = "Trái tim của thủ đô Hà Nội ngàn năm văn hiến.", ImageUrl = "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80", Latitude = 21.0307, Longitude = 105.8524, Rating = 4.8, ReviewsCount = 38900, Address = "Phố Đinh Tiên Hoàng, Hoàn Kiếm", TicketPrice = 30000 },
        new Destination { Id = 5, Name = "Đỉnh Fansipan - Nóc Nhà Đông Dương", ProvinceId = 5, ProvinceName = "Lào Cai (Sa Pa)", Category = "Chinh phục đỉnh cao", Description = "Đỉnh núi cao nhất Việt Nam 3.143m ngắm biển mây tuyệt đẹp.", ImageUrl = "https://images.unsplash.com/photo-1544085311-11a028465b03?auto=format&fit=crop&w=800&q=80", Latitude = 22.3033, Longitude = 103.7753, Rating = 4.9, ReviewsCount = 31200, Address = "Thị xã Sa Pa, Lào Cai", TicketPrice = 850000 },
        new Destination { Id = 6, Name = "Hồ Xuân Hương & Quảng Trường Lâm Viên", ProvinceId = 9, ProvinceName = "Lâm Đồng (Đà Lạt)", Category = "Biểu tượng thành phố", Description = "Hồ nước thơ mộng và biểu tượng bông hoa dã quỳ, nụ atiso khổng lồ.", ImageUrl = "https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80", Latitude = 11.9366, Longitude = 108.4452, Rating = 4.8, ReviewsCount = 29500, Address = "Đường Trần Quốc Toản, P. 1, Đà Lạt", TicketPrice = 0 },
        new Destination { Id = 7, Name = "Bãi Sao Phú Quốc", ProvinceId = 10, ProvinceName = "Kiên Giang (Phú Quốc)", Category = "Biển đảo nghỉ dưỡng", Description = "Bãi cát trắng mịn như kem và làn nước trong xanh màu ngọc bích.", ImageUrl = "https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=800&q=80", Latitude = 10.0528, Longitude = 104.0322, Rating = 4.7, ReviewsCount = 18700, Address = "Ấp Bãi Sao, An Thới, Phú Quốc", TicketPrice = 0 },
    };

    public static List<Restaurant> GetRestaurants() => new()
    {
        new Restaurant
        {
            Id = 1, Name = "Cơm Tấm Ba Ghiền", ProvinceId = 1, ProvinceName = "TP. Hồ Chí Minh", CuisineType = "Ẩm thực Nam Bộ", SpecialtyDishes = "Cơm tấm sườn bì chả cọng to trứ danh", Address = "84 Đặng Văn Ngữ, P. 10, Q. Phú Nhuận", Latitude = 10.7932, Longitude = 106.6698, Rating = 4.6, ReviewsCount = 6800, PriceRange = "85.000đ - 130.000đ", ImageUrl = "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80", IsHighRated = true,
            SampleReviews = new() { new RestaurantReview { Author = "Trần Minh", Rating = 5, Text = "Miếng sườn nướng siêu to khổng lồ, thơm phức vị mật ong." } }
        },
        new Restaurant
        {
            Id = 2, Name = "Phở Gia Truyền Bát Đàn", ProvinceId = 3, ProvinceName = "Thủ đô Hà Nội", CuisineType = "Phở truyền thống", SpecialtyDishes = "Phở bò tái lăn nước dùng trong ngọt thanh", Address = "49 Bát Đàn, Q. Hoàn Kiếm, Hà Nội", Latitude = 21.0335, Longitude = 105.8471, Rating = 4.7, ReviewsCount = 8900, PriceRange = "55.000đ - 75.000đ", ImageUrl = "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?auto=format&fit=crop&w=800&q=80", IsHighRated = true,
            SampleReviews = new() { new RestaurantReview { Author = "Hoàng Long", Rating = 5, Text = "Nước dùng thanh tao, chuẩn vị phở Hà Nội xưa." } }
        },
        new Restaurant
        {
            Id = 3, Name = "Quán Gỗ (Lẩu Bò Ba Toa)", ProvinceId = 9, ProvinceName = "Lâm Đồng (Đà Lạt)", CuisineType = "Lẩu & Nướng phố núi", SpecialtyDishes = "Lẩu bò nhúng rau má, giò bò mềm ngọt", Address = "1/29 Hoàng Diệu, P. 5, TP. Đà Lạt", Latitude = 11.9421, Longitude = 108.4312, Rating = 4.8, ReviewsCount = 9400, PriceRange = "150.000đ - 300.000đ", ImageUrl = "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80", IsHighRated = true,
            SampleReviews = new() { new RestaurantReview { Author = "Mai Lan", Rating = 5, Text = "Trời lạnh ăn nồi lẩu bò sôi sùng sục thì không còn gì bằng!" } }
        },
        new Restaurant
        {
            Id = 4, Name = "Bún Quậy Kiến Xây Phú Quốc", ProvinceId = 10, ProvinceName = "Kiên Giang (Phú Quốc)", CuisineType = "Hải sản & Bún tươi", SpecialtyDishes = "Bún quậy chả tôm mực tươi xay tại chỗ", Address = "28 Bạch Đằng, Dương Đông, Phú Quốc", Latitude = 10.2185, Longitude = 103.9621, Rating = 4.7, ReviewsCount = 7600, PriceRange = "55.000đ - 85.000đ", ImageUrl = "https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80", IsHighRated = true,
            SampleReviews = new() { new RestaurantReview { Author = "Quốc Tuấn", Rating = 5, Text = "Tự pha nước chấm tắc ớt cực vui, chả tôm ngọt lịm." } }
        }
    };

    public static List<Hotel> GetHotels() => new()
    {
        new Hotel { Id = 1, Name = "The Reverie Saigon", ProvinceId = 1, ProvinceName = "TP. Hồ Chí Minh", Address = "22-36 Nguyễn Huệ, Quận 1", StarRating = 5.0, PricePerNight = 4800000, ImageUrl = "https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80", HasWifi = true, HasPool = true, BookingPartner = "Agoda", BookingUrl = "https://www.agoda.com" },
        new Hotel { Id = 2, Name = "Dalat Wonder Resort", ProvinceId = 9, ProvinceName = "Lâm Đồng (Đà Lạt)", Address = "19 Hoa Hồng, Hồ Tuyền Lâm, P. 4", StarRating = 4.5, PricePerNight = 1450000, ImageUrl = "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=800&q=80", HasWifi = true, HasPool = true, BookingPartner = "Booking.com", BookingUrl = "https://www.booking.com" },
        new Hotel { Id = 3, Name = "Salinda Resort Phu Quoc Island", ProvinceId = 10, ProvinceName = "Kiên Giang (Phú Quốc)", Address = "Cửa Lấp, Dương Tơ, Phú Quốc", StarRating = 5.0, PricePerNight = 3200000, ImageUrl = "https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=800&q=80", HasWifi = true, HasPool = true, BookingPartner = "Traveloka", BookingUrl = "https://www.traveloka.com" },
    };

    public static List<LocalFood> GetLocalFoods() => new()
    {
        new LocalFood { Id = 1, Name = "Cơm Tấm Sườn Bì Chả", ProvinceId = 1, ProvinceName = "TP. Hồ Chí Minh", PriceFrom = 45000, PriceTo = 120000, Description = "Đĩa cơm hạt tấm nóng hổi ăn kèm sườn nướng mỡ hành, chả trứng béo ngậy và nước mắm chua ngọt kẹo.", ImageUrl = "https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80", StoryOrigin = "Món ăn bình dân từ gạo tấm của người Nam Bộ xưa nay thành đặc sản trứ danh.", BestPlaceToEat = "Cơm Tấm Ba Ghiền, Cơm Tấm Phúc Lộc Thọ" },
        new LocalFood { Id = 2, Name = "Bánh Mì Sài Gòn", ProvinceId = 1, ProvinceName = "TP. Hồ Chí Minh", PriceFrom = 25000, PriceTo = 65000, Description = "Ổ bánh mì giòn rụm kẹp pate gan thơm lừng, thịt nguội, chả lụa, dưa leo, ngò rí và ớt cay nồng.", ImageUrl = "https://images.unsplash.com/photo-1509722747041-616f39b57569?auto=format&fit=crop&w=800&q=80", StoryOrigin = "Sự giao thoa văn hóa ẩm thực Pháp - Việt được bạn bè quốc tế vinh danh top món kẹp ngon nhất thế giới.", BestPlaceToEat = "Bánh Mì Huỳnh Hoa, Bánh Mì Bảy Hổ" },
        new LocalFood { Id = 3, Name = "Lẩu Gà Lá É", ProvinceId = 9, ProvinceName = "Lâm Đồng (Đà Lạt)", PriceFrom = 200000, PriceTo = 350000, Description = "Vị ngọt thanh từ thịt gà đồi hòa quyện vị chua thanh, thơm cay nồng nàn của lá é tươi.", ImageUrl = "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80", StoryOrigin = "Món ăn ấm áp xua tan cái lạnh sương mù Đà Lạt xuất phát từ Phú Yên.", BestPlaceToEat = "Lẩu Gà Lá É Tao Ngộ (Số 5 đường 3/4)" },
    };

    public static List<Itinerary> GetItineraries() => new()
    {
        new Itinerary
        {
            Id = 1, Title = "Đà Lạt Mộng Mơ 3N2Đ", Description = "Lịch trình săn mây đồi chè, cà phê hoàng hôn và trải nghiệm ẩm thực phố núi.", ProvinceId = 9, ProvinceName = "Lâm Đồng (Đà Lạt)", DaysCount = 3, TotalBudget = 2500000,
            Stops = new()
            {
                new ItineraryStop { Title = "Ăn sáng Bánh mì xíu mại Hoàng Diệu", StopType = "meal", PlannedTime = "07:30", DayNumber = 1 },
                new ItineraryStop { Title = "Check-in Quảng trường Lâm Viên & Hồ Xuân Hương", StopType = "destination", PlannedTime = "09:00", DayNumber = 1 },
                new ItineraryStop { Title = "Trưa: Thưởng thức Lẩu Bò Quán Gỗ Ba Toa", StopType = "meal", PlannedTime = "12:00", DayNumber = 1 },
                new ItineraryStop { Title = "Săn mây Đồi Chè Cầu Đất đón bình minh", StopType = "destination", PlannedTime = "05:30", DayNumber = 2 },
                new ItineraryStop { Title = "Trải nghiệm máng trượt Thác Datanla", StopType = "destination", PlannedTime = "14:00", DayNumber = 2 },
            }
        }
    };
}
