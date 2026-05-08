using System;
using System.Collections.Generic;

namespace AkilliSinavAPI.Models;

public partial class PersonelDurum
{
    public int DurumId { get; set; }

    public int? PersonelId { get; set; }

    public DateOnly? Tarih { get; set; }

    public string? MazeretTuru { get; set; }

    public bool? Uygun { get; set; }

    public virtual Personel? Personel { get; set; }
}
