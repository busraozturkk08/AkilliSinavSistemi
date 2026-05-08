using System;
using System.Collections.Generic;

namespace AkilliSinavAPI.Models;

public partial class Personel
{
    public int PersonelId { get; set; }

    public string? Unvan { get; set; }

    public string? Ad { get; set; }

    public string? Soyad { get; set; }

    public int? BolumId { get; set; }

    public virtual Bolumler? Bolum { get; set; }

    public virtual ICollection<GozetmenAtamalari> GozetmenAtamalaris { get; set; } = new List<GozetmenAtamalari>();

    public virtual ICollection<PersonelDurum> PersonelDurums { get; set; } = new List<PersonelDurum>();
}
