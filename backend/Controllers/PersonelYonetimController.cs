using Microsoft.AspNetCore.Mvc;
using AkilliSinavAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace AkilliSinavAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PersonelYonetimController : ControllerBase
    {
        private readonly AkilliSinavSistemiContext _context;

        public PersonelYonetimController(AkilliSinavSistemiContext context)
        {
            _context = context;
        }

        // Modül 1: Personel Mazeret Tanımlama
        [HttpPost("MazeretEkle")]
        public async Task<IActionResult> MazeretEkle(int personelId, DateTime tarih, string mazeret)
        {
            var durum = new PersonelDurum // SQL: Personel_Durum tablosu
            {
                PersonelId = personelId,
                Tarih = DateOnly.FromDateTime(tarih),
                MazeretTuru = mazeret,
                Uygun = false // Mazereti varsa uygun değildir
            };

            _context.PersonelDurums.Add(durum); // EF Core takısı 's' olabilir, hata verirse kontrol et
            await _context.SaveChangesAsync();

            return Ok(new { Mesaj = "Personel mazereti başarıyla kaydedildi." });
        }

        // Modül 1: Tüm Personelleri Listele (Seçim yapabilmek için)
        [HttpGet("Listele")]
        public async Task<IActionResult> PersonelListele()
        {
            return Ok(await _context.Personels.ToListAsync());
        }
    }
}