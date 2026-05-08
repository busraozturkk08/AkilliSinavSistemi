using System;
using System.Collections.Generic;

namespace AkilliSinavAPI.Models;

public partial class SinavSalonlari
{
    public int AtamaId { get; set; }

    public int? SinavId { get; set; }

    public int? DerslikId { get; set; }

    public virtual Derslikler? Derslik { get; set; }

    public virtual ICollection<GozetmenAtamalari> GozetmenAtamalaris { get; set; } = new List<GozetmenAtamalari>();

    public virtual Sinavlar? Sinav { get; set; }
}
