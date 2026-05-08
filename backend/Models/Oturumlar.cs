using System;
using System.Collections.Generic;

namespace AkilliSinavAPI.Models;

public partial class Oturumlar
{
    public int OturumId { get; set; }

    public string? Tanim { get; set; }

    public TimeOnly? BaslangicSaat { get; set; }

    public TimeOnly? BitisSaat { get; set; }

    public virtual ICollection<Sinavlar> Sinavlars { get; set; } = new List<Sinavlar>();
}
