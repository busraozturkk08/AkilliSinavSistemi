using System;
using System.Collections.Generic;

namespace AkilliSinavAPI.Models;

public partial class Derslikler
{
    public int DerslikId { get; set; }

    public string? Ad { get; set; }

    public int? Kapasite { get; set; }

    public string? Tip { get; set; }

    public bool? Aktif { get; set; }

    public virtual ICollection<SinavSalonlari> SinavSalonlaris { get; set; } = new List<SinavSalonlari>();
}
