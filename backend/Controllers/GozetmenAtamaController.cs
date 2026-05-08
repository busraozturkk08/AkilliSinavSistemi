using Microsoft.AspNetCore.Mvc;
using AkilliSinavAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace AkilliSinavAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class GozetmenAtamaController : ControllerBase
    {
        private readonly AkilliSinavSistemiContext _context;

        public GozetmenAtamaController(AkilliSinavSistemiContext context)
        {
            _context = context;
        }

        [HttpPost("AkilliGozetmenAta")]
        public async Task<IActionResult> GozetmenAta(int sinavSalonId, int bolumId, DateTime tarih)
        {
            // 1. Önce mazereti olmayan tüm hocaları listele
            var uygunHocalar = await _context.Personels
                .Where(p => !_context.PersonelDurums.Any(pd => pd.PersonelId == p.PersonelId && pd.Tarih == DateOnly.FromDateTime(tarih) && pd.Uygun == false))
                .ToListAsync();

            // 2. Havuz Mantığı: Önce kendi bölümündeki hocaları, sonra diğerlerini sırala
            var oncelikliHocalar = uygunHocalar
                .OrderByDescending(p => p.BolumId == bolumId) // Kendi bölümü ise en başa al
                .ToList();

            foreach (var hoca in oncelikliHocalar)
            {
                // 3. Günlük 3 oturum sınırı kontrolü
                int gunlukGorev = await _context.GozetmenAtamalaris
                    .CountAsync(ga => ga.PersonelId == hoca.PersonelId);

                if (gunlukGorev < 3)
                {
                    var atama = new GozetmenAtamalari
                    {
                        SinavSalonId = sinavSalonId,
                        PersonelId = hoca.PersonelId
                    };

                    _context.GozetmenAtamalaris.Add(atama);
                    await _context.SaveChangesAsync();

                    string havuzBilgisi = hoca.BolumId == bolumId ? "Kendi Bölümünden" : "Ortak Havuzdan";

                    return Ok(new
                    {
                        Mesaj = $"Gözetmen {havuzBilgisi} atandı.",
                        Hoca = hoca.Ad + " " + hoca.Soyad,
                        GorevSirasi = gunlukGorev + 1
                    });
                }
            }

            return BadRequest("Uygun gözetmen kalmadı (Mazeret veya 3 oturum sınırı nedeniyle).");
        }
    }
}