using System;
using System.Collections.Generic;

namespace AkilliSinavAPI.Models;

public partial class Sinavlar
{
    public int SinavId { get; set; }

    public int? DersId { get; set; }

    public DateOnly? Tarih { get; set; }

    public int? OturumId { get; set; }

    public virtual Dersler? Ders { get; set; }

    public virtual Oturumlar? Oturum { get; set; }

    public virtual ICollection<SinavSalonlari> SinavSalonlaris { get; set; } = new List<SinavSalonlari>();
}
