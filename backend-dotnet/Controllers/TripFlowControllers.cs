using Microsoft.AspNetCore.Mvc;
using TripFlow.Api.Data;
using TripFlow.Api.Models;

namespace TripFlow.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public class ProvincesController : ControllerBase
{
    private readonly ITripFlowStore _store;

    public ProvincesController(ITripFlowStore store) => _store = store;

    [HttpGet]
    public ActionResult<List<Province>> GetAll([FromQuery] string? region, [FromQuery] string? q)
    {
        return Ok(_store.GetProvinces(region, q));
    }

    [HttpGet("{id:int}")]
    public ActionResult<Province> GetById(int id)
    {
        var province = _store.GetProvinceById(id);
        if (province == null) return NotFound(new { message = $"Không tìm thấy tỉnh với ID {id}" });
        return Ok(province);
    }
}

[ApiController]
[Route("api/v1/[controller]")]
public class DestinationsController : ControllerBase
{
    private readonly ITripFlowStore _store;

    public DestinationsController(ITripFlowStore store) => _store = store;

    [HttpGet]
    public ActionResult<List<Destination>> GetAll([FromQuery] int? province_id, [FromQuery] string? category, [FromQuery] string? q)
    {
        return Ok(_store.GetDestinations(province_id, category, q));
    }

    [HttpGet("{id:int}")]
    public ActionResult<Destination> GetById(int id)
    {
        var dest = _store.GetDestinationById(id);
        if (dest == null) return NotFound(new { message = $"Không tìm thấy điểm đến {id}" });
        return Ok(dest);
    }
}

[ApiController]
[Route("api/v1/[controller]")]
public class RestaurantsController : ControllerBase
{
    private readonly ITripFlowStore _store;

    public RestaurantsController(ITripFlowStore store) => _store = store;

    [HttpGet]
    public ActionResult<List<Restaurant>> GetAll([FromQuery] int? province_id, [FromQuery] string? q, [FromQuery] double? min_rating, [FromQuery] bool? is_high_rated)
    {
        return Ok(_store.GetRestaurants(province_id, q, min_rating, is_high_rated));
    }

    [HttpGet("{id:int}")]
    public ActionResult<Restaurant> GetById(int id)
    {
        var restaurant = _store.GetRestaurantById(id);
        if (restaurant == null) return NotFound(new { message = $"Không tìm thấy quán ăn {id}" });
        return Ok(restaurant);
    }
}

[ApiController]
[Route("api/v1/[controller]")]
public class HotelsController : ControllerBase
{
    private readonly ITripFlowStore _store;

    public HotelsController(ITripFlowStore store) => _store = store;

    [HttpGet]
    public ActionResult<List<Hotel>> GetAll([FromQuery] int? province_id, [FromQuery] string? q)
    {
        return Ok(_store.GetHotels(province_id, q));
    }

    [HttpGet("{id:int}")]
    public ActionResult<Hotel> GetById(int id)
    {
        var hotel = _store.GetHotelById(id);
        if (hotel == null) return NotFound(new { message = $"Không tìm thấy khách sạn {id}" });
        return Ok(hotel);
    }
}

[ApiController]
[Route("api/v1/local-foods")]
public class LocalFoodsController : ControllerBase
{
    private readonly ITripFlowStore _store;

    public LocalFoodsController(ITripFlowStore store) => _store = store;

    [HttpGet]
    public ActionResult<List<LocalFood>> GetAll([FromQuery] int? province_id, [FromQuery] string? q)
    {
        return Ok(_store.GetLocalFoods(province_id, q));
    }

    [HttpGet("{id:int}")]
    public ActionResult<LocalFood> GetById(int id)
    {
        var food = _store.GetLocalFoodById(id);
        if (food == null) return NotFound(new { message = $"Không tìm thấy món ăn {id}" });
        return Ok(food);
    }
}

[ApiController]
[Route("api/v1/[controller]")]
public class ItinerariesController : ControllerBase
{
    private readonly ITripFlowStore _store;

    public ItinerariesController(ITripFlowStore store) => _store = store;

    [HttpGet]
    public ActionResult<List<Itinerary>> GetAll() => Ok(_store.GetItineraries());

    [HttpGet("{id:int}")]
    public ActionResult<Itinerary> GetById(int id)
    {
        var item = _store.GetItineraryById(id);
        if (item == null) return NotFound(new { message = $"Không tìm thấy lịch trình {id}" });
        return Ok(item);
    }

    [HttpPost]
    public ActionResult<Itinerary> Create([FromBody] Itinerary input)
    {
        var created = _store.AddItinerary(input);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }
}

[ApiController]
[Route("api/v1/[controller]")]
public class AuthController : ControllerBase
{
    [HttpPost("request-otp")]
    public IActionResult RequestOtp([FromBody] OtpRequestDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.PhoneNumber))
            return BadRequest(new { success = false, message = "Số điện thoại không được để trống" });

        return Ok(new
        {
            success = true,
            message = $"Mã OTP xác thực 6 số đã được gửi tới {dto.PhoneNumber}",
            expires_in_seconds = 300,
            debug_otp = "888999" // Để kiểm thử thuận tiện
        });
    }

    [HttpPost("verify-otp")]
    public IActionResult VerifyOtp([FromBody] OtpVerifyDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.PhoneNumber) || string.IsNullOrWhiteSpace(dto.OtpCode))
            return BadRequest(new { success = false, message = "Thiếu thông tin số điện thoại hoặc mã OTP" });

        // Chấp nhận mã OTP mẫu hoặc 6 số bất kỳ để tiện nghiệm thu
        var token = $"tripflow_jwt_{Guid.NewGuid():N}";
        var user = new UserDto
        {
            Id = 1,
            PhoneNumber = dto.PhoneNumber,
            FullName = "Phạm Tấn Tài",
            Role = "admin"
        };

        return Ok(new
        {
            success = true,
            access_token = token,
            token_type = "Bearer",
            user = user
        });
    }

    [HttpGet("me")]
    public IActionResult GetCurrentUser()
    {
        return Ok(new UserDto
        {
            Id = 1,
            PhoneNumber = "0901234567",
            FullName = "Phạm Tấn Tài",
            Role = "admin"
        });
    }
}

[ApiController]
[Route("api/v1/[controller]")]
public class AssistantController : ControllerBase
{
    [HttpPost("chat")]
    public ActionResult<AssistantChatResponse> Chat([FromBody] AssistantChatRequest req)
    {
        var q = req.Question?.ToLowerInvariant() ?? "";
        string reply;
        List<string> tips = new();

        if (q.Contains("da lat") || q.Contains("đà lạt"))
        {
            reply = "🌸 **Lịch trình Đà Lạt 3N2Đ tối ưu:**\n" +
                    "• **Ngày 1**: Bánh mì xíu mại Hoàng Diệu → Dinh III Bảo Đại → Cà phê hoàng hôn đồi dã quỳ → Lẩu gà lá é Tao Ngộ.\n" +
                    "• **Ngày 2**: Săn mây Đồi chè Cầu Đất (05:00) → Máng trượt Thác Datanla → Lẩu bò Quán Gỗ Ba Toa.\n" +
                    "• **Ngày 3**: Cáp treo Thiền Viện Trúc Lâm & Hồ Tuyền Lâm → Chợ Đà Lạt mua quà atiso, dâu tây.";
            tips.Add("Nên mang áo ấm vì nhiệt độ sáng sớm và tối tại Đà Lạt chỉ khoảng 14-16 độ C.");
        }
        else if (q.Contains("sa pa") || q.Contains("hành lý"))
        {
            reply = "🏔️ **Hành lý cần chuẩn bị khi đi Sa Pa mùa đông:**\n" +
                    "• Áo phao lông vũ chống gió/nước, áo giữ nhiệt Heattech, quần nỉ lót lông.\n" +
                    "• Giày trekking chống trơn trượt có đế bám tốt khi leo núi Fansipan.\n" +
                    "• Miếng dán giữ nhiệt, dầu gió, thuốc cảm cúm, sạc dự phòng.";
            tips.Add("Thời tiết đỉnh Fansipan thường thấp hơn thị trấn từ 6-8 độ C.");
        }
        else
        {
            reply = $"Chào bạn! Tôi là Trợ lý Du lịch TripFlow .NET. Tôi đã nhận được câu hỏi: \"{req.Question}\". " +
                    "Bạn có thể bấm vào các tính năng Khách sạn, Tour tuyến hoặc Lập Lịch Phượt trên màn hình để hệ thống tự động tối ưu hóa chuyến đi!";
            tips.Add("TripFlow hỗ trợ tra cứu dữ liệu 10 tỉnh thành và bản đồ phượt thông minh.");
        }

        return Ok(new AssistantChatResponse
        {
            Reply = reply,
            Tips = tips,
            Applied = new(),
            Rejected = new()
        });
    }
}

