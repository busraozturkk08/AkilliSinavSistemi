using System;
using System.Collections.Generic;

namespace AkilliSinavAPI.Models;

public partial class GozetmenAtamalari
{
    public int AtamaId { get; set; }

    public int? SinavSalonId { get; set; }

    public int? PersonelId { get; set; }

    public virtual Personel? Personel { get; set; }

    public virtual SinavSalonlari? SinavSalon { get; set; }
}
