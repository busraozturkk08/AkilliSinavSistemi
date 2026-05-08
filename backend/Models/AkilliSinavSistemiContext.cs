using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace AkilliSinavAPI.Models;

public partial class AkilliSinavSistemiContext : DbContext
{
    public AkilliSinavSistemiContext()
    {
    }

    public AkilliSinavSistemiContext(DbContextOptions<AkilliSinavSistemiContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Bolumler> Bolumlers { get; set; }

    public virtual DbSet<Dersler> Derslers { get; set; }

    public virtual DbSet<Derslikler> Dersliklers { get; set; }

    public virtual DbSet<GozetmenAtamalari> GozetmenAtamalaris { get; set; }

    public virtual DbSet<Oturumlar> Oturumlars { get; set; }

    public virtual DbSet<Personel> Personels { get; set; }

    public virtual DbSet<PersonelDurum> PersonelDurums { get; set; }

    public virtual DbSet<SinavSalonlari> SinavSalonlaris { get; set; }

    public virtual DbSet<Sinavlar> Sinavlars { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        // Burayı boş bıraktık çünkü bağlantıyı Program.cs ve appsettings.json üzerinden yönetiyoruz.
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Bolumler>(entity =>
        {
            entity.HasKey(e => e.BolumId).HasName("PK__Bolumler__7BAD4B5C124FE8F4");

            entity.ToTable("Bolumler");

            entity.Property(e => e.BolumId).HasColumnName("BolumID");
            entity.Property(e => e.BolumAd).HasMaxLength(100);
        });

        modelBuilder.Entity<Dersler>(entity =>
        {
            entity.HasKey(e => e.DersId).HasName("PK__Dersler__E8B3DE7195E7848A");

            entity.ToTable("Dersler");

            entity.HasIndex(e => e.DersKodu, "UQ__Dersler__9DCB30EFECB8E1CA").IsUnique();

            entity.Property(e => e.DersId).HasColumnName("DersID");
            entity.Property(e => e.Ad).HasMaxLength(100);
            entity.Property(e => e.BolumId).HasColumnName("BolumID");
            entity.Property(e => e.DersKodu).HasMaxLength(20);
            entity.Property(e => e.DersTuru).HasMaxLength(50);

            entity.HasOne(d => d.Bolum).WithMany(p => p.Derslers)
                .HasForeignKey(d => d.BolumId)
                .HasConstraintName("FK__Dersler__BolumID__3C69FB99");
        });

        modelBuilder.Entity<Derslikler>(entity =>
        {
            entity.HasKey(e => e.DerslikId).HasName("PK__Derslikl__8E733DCAF9C904F7");

            entity.ToTable("Derslikler");

            entity.Property(e => e.DerslikId).HasColumnName("DerslikID");
            entity.Property(e => e.Ad).HasMaxLength(50);
            entity.Property(e => e.Aktif).HasDefaultValue(true);
            entity.Property(e => e.Tip).HasMaxLength(50);
        });

        modelBuilder.Entity<GozetmenAtamalari>(entity =>
        {
            entity.HasKey(e => e.AtamaId).HasName("PK__Gozetmen__00DE786BBEFCC749");

            entity.ToTable("Gozetmen_Atamalari");

            entity.Property(e => e.AtamaId).HasColumnName("AtamaID");
            entity.Property(e => e.PersonelId).HasColumnName("PersonelID");
            entity.Property(e => e.SinavSalonId).HasColumnName("SinavSalonID");

            entity.HasOne(d => d.Personel).WithMany(p => p.GozetmenAtamalaris)
                .HasForeignKey(d => d.PersonelId)
                .HasConstraintName("FK__Gozetmen___Perso__5441852A");

            entity.HasOne(d => d.SinavSalon).WithMany(p => p.GozetmenAtamalaris)
                .HasForeignKey(d => d.SinavSalonId)
                .HasConstraintName("FK__Gozetmen___Sinav__534D60F1");
        });

        modelBuilder.Entity<Oturumlar>(entity =>
        {
            entity.HasKey(e => e.OturumId).HasName("PK__Oturumla__59AA114DB9101111");

            entity.ToTable("Oturumlar");

            entity.Property(e => e.OturumId).HasColumnName("OturumID");
            entity.Property(e => e.Tanim).HasMaxLength(50);
        });

        modelBuilder.Entity<Personel>(entity =>
        {
            entity.HasKey(e => e.PersonelId).HasName("PK__Personel__0F0C57511DFFA9D7");

            entity.ToTable("Personel");

            entity.Property(e => e.PersonelId).HasColumnName("PersonelID");
            entity.Property(e => e.Ad).HasMaxLength(50);
            entity.Property(e => e.BolumId).HasColumnName("BolumID");
            entity.Property(e => e.Soyad).HasMaxLength(50);
            entity.Property(e => e.Unvan).HasMaxLength(50);

            entity.HasOne(d => d.Bolum).WithMany(p => p.Personels)
                .HasForeignKey(d => d.BolumId)
                .HasConstraintName("FK__Personel__BolumI__440B1D61");
        });

        modelBuilder.Entity<PersonelDurum>(entity =>
        {
            entity.HasKey(e => e.DurumId).HasName("PK__Personel__E6B16D64A10CDE36");

            entity.ToTable("Personel_Durum");

            entity.Property(e => e.DurumId).HasColumnName("DurumID");
            entity.Property(e => e.MazeretTuru).HasMaxLength(100);
            entity.Property(e => e.PersonelId).HasColumnName("PersonelID");

            entity.HasOne(d => d.Personel).WithMany(p => p.PersonelDurums)
                .HasForeignKey(d => d.PersonelId)
                .HasConstraintName("FK__Personel___Perso__46E78A0C");
        });

        modelBuilder.Entity<SinavSalonlari>(entity =>
        {
            entity.HasKey(e => e.AtamaId).HasName("PK__Sinav_Sa__00DE786BD1259B9D");

            entity.ToTable("Sinav_Salonlari");

            entity.Property(e => e.AtamaId).HasColumnName("AtamaID");
            entity.Property(e => e.DerslikId).HasColumnName("DerslikID");
            entity.Property(e => e.SinavId).HasColumnName("SinavID");

            entity.HasOne(d => d.Derslik).WithMany(p => p.SinavSalonlaris)
                .HasForeignKey(d => d.DerslikId)
                .HasConstraintName("FK__Sinav_Sal__Dersl__5070F446");

            entity.HasOne(d => d.Sinav).WithMany(p => p.SinavSalonlaris)
                .HasForeignKey(d => d.SinavId)
                .HasConstraintName("FK__Sinav_Sal__Sinav__4F7CD00D");
        });

        modelBuilder.Entity<Sinavlar>(entity =>
        {
            entity.HasKey(e => e.SinavId).HasName("PK__Sinavlar__E089B78655BB7CDE");

            entity.ToTable("Sinavlar");

            entity.Property(e => e.SinavId).HasColumnName("SinavID");
            entity.Property(e => e.DersId).HasColumnName("DersID");
            entity.Property(e => e.OturumId).HasColumnName("OturumID");

            entity.HasOne(d => d.Ders).WithMany(p => p.Sinavlars)
                .HasForeignKey(d => d.DersId)
                .HasConstraintName("FK__Sinavlar__DersID__4BAC3F29");

            entity.HasOne(d => d.Oturum).WithMany(p => p.Sinavlars)
                .HasForeignKey(d => d.OturumId)
                .HasConstraintName("FK__Sinavlar__Oturum__4CA06362");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
