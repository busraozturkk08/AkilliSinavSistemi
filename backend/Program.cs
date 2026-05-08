using AkilliSinavAPI.Models;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// 1. CORS Politikasýný Tanýmla
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.SetIsOriginAllowed(_ => true) // Tüm kaynaklara izin ver
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials(); // Eðer cookie veya auth varsa iþe yarar
    });
});

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// 2. DbContext Yapýlandýrmasý (Kritik Düzeltme: Context sýnýfý ismi eklenmeli)
// "SinavDbContext" kýsmýný arkadaþýnýn Models klasöründeki gerçek Context sýnýfý adýyla deðiþtirmesi gerekebilir.
builder.Services.AddDbContext<AkilliSinavAPI.Models.AkilliSinavSistemiContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();

// 3. HTTP Request Pipeline Yapýlandýrmasý
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Güvenlik ve Yönlendirme Middleware'leri
// NOT: Yerel aðda test yaparken HTTPS bazen sorun çýkarabilir. 
// Eðer baðlantý hatasý devam ederse aþaðýdaki satýrý geçici olarak yorum satýrý yapabilirsiniz.
// app.UseHttpsRedirection();

app.UseRouting(); // Yönlendirmeyi açýkça belirtmek iyidir.

// 4. CORS'u Aktif Et (Routing'den sonra, Authorization'dan önce olmalý)
app.UseCors("AllowFrontend");

app.UseAuthorization();

app.MapControllers();

app.Run();