using System;
using System.Collections.Generic;

namespace AkilliSinavAPI.Models;

public partial class Dersler
{
    public int DersId { get; set; }

    public string? DersKodu { get; set; }

    public string Ad { get; set; } = null!;

    public string? DersTuru { get; set; }

    public int? OgrenciSayisi { get; set; }

    public int? Yariyil { get; set; }

    public int? BolumId { get; set; }

    public virtual Bolumler? Bolum { get; set; }

    public virtual ICollection<Sinavlar> Sinavlars { get; set; } = new List<Sinavlar>();
}
