using System;
using System.Collections.Generic;

namespace AkilliSinavAPI.Models;

public partial class Bolumler
{
    public int BolumId { get; set; }

    public string BolumAd { get; set; } = null!;

    public virtual ICollection<Dersler> Derslers { get; set; } = new List<Dersler>();

    public virtual ICollection<Personel> Personels { get; set; } = new List<Personel>();
}
