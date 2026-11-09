using TripFlow.Api.Data;

var builder = WebApplication.CreateBuilder(args);

// 1. Thêm Controllers & JSON Options
builder.Services.AddControllers();

// 2. Thêm CORS cho phép Web Admin và Mobile App gọi API
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// 3. Đăng ký TripFlow Data Store (In-Memory hoặc PostgreSQL)
builder.Services.AddSingleton<ITripFlowStore, TripFlowStore>();

// 4. Cấu hình Swagger / OpenAPI Documentation
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.OpenApiInfo
    {
        Title = "TripFlow API (.NET ASP.NET Core)",
        Version = "v1",
        Description = "Hệ thống Backend ASP.NET Core Web API cho Nền tảng Du lịch & Phượt TripFlow (eProject Kỳ 3 Aptech)",
        Contact = new Microsoft.OpenApi.OpenApiContact
        {
            Name = "Phạm Tấn Tài",
            Url = new Uri("https://github.com/phamtantai02011991-tech/trip_flow")
        }
    });
});

var app = builder.Build();

// 5. Kích hoạt Swagger UI cho cả Development & Production để tiện nghiệm thu đồ án
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "TripFlow API v1");
    c.RoutePrefix = string.Empty; // Mở http://localhost:8000/ là ra ngay trang Swagger!
});

app.UseCors("AllowAll");

app.UseAuthorization();

app.MapControllers();

app.Run();
