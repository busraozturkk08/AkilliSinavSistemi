using Microsoft.AspNetCore.Mvc;
using AkilliSinavAPI.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient; // Parametreler için gerekli

namespace AkilliSinavAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SinavYonetimController : ControllerBase
    {
        private readonly AkilliSinavSistemiContext _context;

        public SinavYonetimController(AkilliSinavSistemiContext context)
        {
            _context = context;
        }

        // 1. SP: SinavEkle Çağırma
        [HttpPost("SinavEkleSP")]
        public async Task<IActionResult> SinavEkleSP(int dersId, DateTime tarih, int oturumId)
        {
            // SQL'deki DATE tipine uyum sağlamak için
            string formatliTarih = tarih.ToString("yyyy-MM-dd");

            // ExecuteSqlInterpolatedAsync ile Procedure tetikleme
            await _context.Database.ExecuteSqlInterpolatedAsync(
                $"EXEC SinavEkle @DersID={dersId}, @Tarih={formatliTarih}, @OturumID={oturumId}"
            );

            return Ok(new { Mesaj = "Sınav, Stored Procedure (SinavEkle) kullanılarak başarıyla eklendi." });
        }

        // 2. SP: SalonAta Çağırma
        [HttpPost("SalonAtaSP")]
        public async Task<IActionResult> SalonAtaSP(int sinavId, int derslikId)
        {
            await _context.Database.ExecuteSqlInterpolatedAsync(
                $"EXEC SalonAta @SinavID={sinavId}, @DerslikID={derslikId}"
            );

            return Ok(new { Mesaj = "Salon ataması Stored Procedure (SalonAta) ile yapıldı." });
        }

        // 3. SP: GozetmenAta Çağırma
        [HttpPost("GozetmenAtaSP")]
        public async Task<IActionResult> GozetmenAtaSP(int sinavSalonId, int personelId)
        {
            await _context.Database.ExecuteSqlInterpolatedAsync(
                $"EXEC GozetmenAta @SinavSalonID={sinavSalonId}, @PersonelID={personelId}"
            );

            return Ok(new { Mesaj = "Gözetmen, Stored Procedure (GozetmenAta) ile başarıyla atandı." });
        }
    }
}