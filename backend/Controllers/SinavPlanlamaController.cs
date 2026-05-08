using Microsoft.AspNetCore.Mvc;
using AkilliSinavAPI.Models;
using Microsoft.EntityFrameworkCore;

namespace AkilliSinavAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SinavPlanlamaController : ControllerBase
    {
        private readonly AkilliSinavSistemiContext _context;

        public SinavPlanlamaController(AkilliSinavSistemiContext context)
        {
            _context = context;
        }

        // Modül 2: Akıllı Salon Hesaplama (Capacity Planning)
        [HttpGet("Planla/{dersId}")]
        public async Task<IActionResult> SalonPlanla(int dersId)
        {
            // 1. Ders bilgisini getir
            var ders = await _context.Derslers.FindAsync(dersId);
            if (ders == null) return NotFound("Sistemde bu ID'ye sahip bir ders bulunamadı.");

            // HATA ÇÖZÜMÜ: Eğer öğrenci sayısı girilmemişse (null) 0 olarak kabul et
            int kalanOgrenci = ders.OgrenciSayisi ?? 0;
            var atananSalonlar = new List<object>();

            // 2. Müsait salonları çek (Kapasiteye göre büyükten küçüğe)
            var uygunDerslikler = await _context.Dersliklers
                .Where(d => d.Aktif == true)
                .OrderByDescending(d => d.Kapasite)
                .ToListAsync();

            // 3. Akıllı Atama Algoritması
            foreach (var derslik in uygunDerslikler)
            {
                if (kalanOgrenci <= 0) break;

                // HATA ÇÖZÜMÜ: Kapasite null ise 0 kabul et ve int'e dönüştür
                int salonKapasite = derslik.Kapasite ?? 0;

                atananSalonlar.Add(new
                {
                    SalonAdi = derslik.Ad,
                    Kapasite = salonKapasite,
                    Tip = derslik.Tip
                });

                kalanOgrenci -= salonKapasite;
            }

            // 4. Kapasite Kontrolü (İş Kuralı B-2)
            if (kalanOgrenci > 0)
            {
                return BadRequest(new
                {
                    Hata = "Kapasite Yetersiz",
                    Mesaj = $"Mevcut salonlar yetmiyor, {kalanOgrenci} kişilik daha yer lazım."
                });
            }

            return Ok(new
            {
                Mesaj = "Akıllı Planlama Başarılı",
                DersAdi = ders.Ad,
                ToplamKontenjan = ders.OgrenciSayisi,
                AtananSalonlar = atananSalonlar
            });
        }
    }
}