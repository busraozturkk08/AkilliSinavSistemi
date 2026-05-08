using Microsoft.AspNetCore.Mvc;
using AkilliSinavAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace AkilliSinavAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OturumController : ControllerBase
    {
        private readonly AkilliSinavSistemiContext _context;

        public OturumController(AkilliSinavSistemiContext context)
        {
            _context = context;
        }

        // Modül 1: Sınav Oturumu (Slot) Tanımlama
        [HttpPost("OturumEkle")]
        public async Task<IActionResult> OturumEkle(string tanim, TimeSpan baslangic, TimeSpan bitis)
        {
            var oturum = new Oturumlar
            {
                Tanim = tanim,
                // TimeSpan tipini TimeOnly tipine çeviriyoruz
                BaslangicSaat = TimeOnly.FromTimeSpan(baslangic),
                BitisSaat = TimeOnly.FromTimeSpan(bitis)
            };

            _context.Oturumlars.Add(oturum);
            await _context.SaveChangesAsync();

            return Ok(new { Mesaj = "Yeni sınav oturumu başarıyla tanımlandı." });
        }

        // Mevcut oturumları listeleme
        [HttpGet("Listele")]
        public async Task<IActionResult> OturumListele()
        {
            return Ok(await _context.Oturumlars.ToListAsync());
        }
    }
}
