-- ==========================================================================================
-- AKILLI SINAV SALONU VE PERSONEL HAVUZU YÖNETÝM SÝSTEMÝ
-- ==========================================================================================

-- Veritabanýný Oluþtur
CREATE DATABASE AkilliSinavSistemi;
GO
USE AkilliSinavSistemi;
GO

-- ==========================================================================================
-- TABLOLARIN OLUÞTURULMASI
-- ==========================================================================================

-- Bölümler
CREATE TABLE Bolumler (
    BolumID INT PRIMARY KEY IDENTITY(1,1),
    BolumAd NVARCHAR(100) NOT NULL
);

-- Dersler
CREATE TABLE Dersler (
    DersID INT PRIMARY KEY IDENTITY(1,1),
    DersKodu NVARCHAR(20) UNIQUE,
    Ad NVARCHAR(100) NOT NULL,
    DersTuru NVARCHAR(50),
    OgrenciSayisi INT CHECK (OgrenciSayisi >= 0),
    Yariyil INT CHECK (Yariyil > 0),
    BolumID INT,
    FOREIGN KEY (BolumID) REFERENCES Bolumler(BolumID)
);

-- Derslikler
CREATE TABLE Derslikler (
    DerslikID INT PRIMARY KEY IDENTITY(1,1),
    Ad NVARCHAR(50),
    Kapasite INT CHECK (Kapasite > 0),
    Tip NVARCHAR(50),
    Aktif BIT DEFAULT 1,
    Kat INT,
    CONSTRAINT CK_DerslikTip CHECK (Tip IN ('Amfi', 'Sinif', 'Lab'))
);

-- Personel
CREATE TABLE Personel (
    PersonelID INT PRIMARY KEY IDENTITY(1,1),
    Unvan NVARCHAR(50),
    Ad NVARCHAR(50),
    Soyad NVARCHAR(50),
    BolumID INT,
    FOREIGN KEY (BolumID) REFERENCES Bolumler(BolumID)
);

-- Personel Durum (Mazeret)
CREATE TABLE Personel_Durum (
    DurumID INT PRIMARY KEY IDENTITY(1,1),
    PersonelID INT,
    Tarih DATE,
    MazeretTuru NVARCHAR(100),
    Uygun BIT,
    FOREIGN KEY (PersonelID) REFERENCES Personel(PersonelID)
);

-- Oturumlar
CREATE TABLE Oturumlar (
    OturumID INT PRIMARY KEY IDENTITY(1,1),
    Tanim NVARCHAR(50),
    BaslangicSaat TIME,
    BitisSaat TIME
);

-- Sýnavlar
CREATE TABLE Sinavlar (
    SinavID INT PRIMARY KEY IDENTITY(1,1),
    DersID INT,
    Tarih DATE,
    OturumID INT,
    FOREIGN KEY (DersID) REFERENCES Dersler(DersID),
    FOREIGN KEY (OturumID) REFERENCES Oturumlar(OturumID)
);

-- Sýnav - Salon Ýliþkisi
CREATE TABLE Sinav_Salonlari (
    AtamaID INT PRIMARY KEY IDENTITY(1,1),
    SinavID INT,
    DerslikID INT,
    FOREIGN KEY (SinavID) REFERENCES Sinavlar(SinavID),
    FOREIGN KEY (DerslikID) REFERENCES Derslikler(DerslikID)
);

-- Gözetmen Atamalarý
CREATE TABLE Gozetmen_Atamalari (
    AtamaID INT PRIMARY KEY IDENTITY(1,1),
    SinavSalonID INT,
    PersonelID INT,
    FOREIGN KEY (SinavSalonID) REFERENCES Sinav_Salonlari(AtamaID),
    FOREIGN KEY (PersonelID) REFERENCES Personel(PersonelID)
);
GO

-- ==========================================================================================
-- ÝNDEKSLER (Performans Optimizasyonu Ýçin)
-- ==========================================================================================
CREATE NONCLUSTERED INDEX IX_Sinavlar_DersID ON Sinavlar(DersID);
CREATE NONCLUSTERED INDEX IX_GozetmenAtamalari_PersonelID ON Gozetmen_Atamalari(PersonelID);
CREATE NONCLUSTERED INDEX IX_PersonelDurum_Tarih ON Personel_Durum(Tarih);
GO

-- ==========================================================================================
-- UDF (KULLANICI TANIMLI FONKSÝYONLAR)
-- ==========================================================================================

-- 1. UDF: Personel Müsaitlik Kontrolü
CREATE FUNCTION fn_PersonelMusaitMi
(
    @PersonelID INT,
    @Tarih DATE,
    @OturumID INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @MesgulSayisi INT = 0;

    SELECT @MesgulSayisi = @MesgulSayisi + COUNT(*)
    FROM Personel_Durum
    WHERE PersonelID = @PersonelID AND Tarih = @Tarih AND Uygun = 0;

    SELECT @MesgulSayisi = @MesgulSayisi + COUNT(*)
    FROM Gozetmen_Atamalari ga
    INNER JOIN Sinav_Salonlari ss ON ga.SinavSalonID = ss.AtamaID
    INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
    WHERE ga.PersonelID = @PersonelID AND s.Tarih = @Tarih AND s.OturumID = @OturumID;

    IF @MesgulSayisi > 0
        RETURN 0;

    RETURN 1; 
END;
GO

--2.UDF: Genel toplam (tüm zamanlar)
CREATE FUNCTION fn_GozetmenToplamGorev
(
    @PersonelID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @ToplamGorev INT;

    SELECT @ToplamGorev = COUNT(*)
    FROM Gozetmen_Atamalari
    WHERE PersonelID = @PersonelID;

    RETURN @ToplamGorev;
END;
GO

--3.UDF: Tarihe göre görev sayýsý - adil daðýtým kontrolü için
CREATE FUNCTION fn_GozetmenGorevSayisi
(
    @PersonelID INT,
    @Tarih DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @GunlukGorev INT;

    SELECT @GunlukGorev = COUNT(*)
    FROM Gozetmen_Atamalari ga
    INNER JOIN Sinav_Salonlari ss ON ga.SinavSalonID = ss.AtamaID
    INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
    WHERE ga.PersonelID = @PersonelID
      AND s.Tarih = @Tarih;

    RETURN @GunlukGorev;
END;
GO

-- 4. UDF: Sýnava Atanan Toplam Kapasite Hesaplama 
CREATE FUNCTION fn_SinavAtananToplamKapasite
(
    @SinavID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @ToplamKapasite INT;

    SELECT @ToplamKapasite = ISNULL(SUM(d.Kapasite), 0)
    FROM Sinav_Salonlari ss
    INNER JOIN Derslikler d ON ss.DerslikID = d.DerslikID
    WHERE ss.SinavID = @SinavID;

    RETURN @ToplamKapasite;
END;
GO

-- =========================================================================================
-- VIEWS (GÖRÜNÜMLER)
-- =========================================================================================

--View 1: Genel Sýnav Programý Çýktýsý
CREATE VIEW vw_GenelSinavProgrami AS
SELECT 
    d.DersKodu,
    d.Ad AS DersAdi,
    s.Tarih,
    o.Tanim AS OturumTipi,
    o.BaslangicSaat,
    dl.Ad AS SalonAdi,
    dl.Tip AS SalonTipi
FROM Sinavlar s
INNER JOIN Dersler d ON s.DersID = d.DersID
INNER JOIN Oturumlar o ON s.OturumID = o.OturumID
INNER JOIN Sinav_Salonlari ss ON s.SinavID = ss.SinavID
INNER JOIN Derslikler dl ON ss.DerslikID = dl.DerslikID;
GO

--View 2: Gözetmen Görev Listesi
CREATE VIEW vw_GozetmenGorevListesi AS
SELECT 
    p.Unvan,
    p.Ad + ' ' + p.Soyad AS PersonelAdSoyad,
    d.Ad AS DersAdi,
    s.Tarih,
    CONVERT(VARCHAR(5), o.BaslangicSaat, 108) + ' - ' + CONVERT(VARCHAR(5), o.BitisSaat, 108) AS ZamanAraligi,
    dl.Ad AS SinavSalonu
FROM Gozetmen_Atamalari ga
INNER JOIN Personel p ON ga.PersonelID = p.PersonelID
INNER JOIN Sinav_Salonlari ss ON ga.SinavSalonID = ss.AtamaID
INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
INNER JOIN Dersler d ON s.DersID = d.DersID
INNER JOIN Oturumlar o ON s.OturumID = o.OturumID
INNER JOIN Derslikler dl ON ss.DerslikID = dl.DerslikID;
GO

--View 3: Personel Meþguliyet ve Mazeret Detaylarý
CREATE VIEW vw_PersonelMesguliyetDetay AS
SELECT 
    p.Ad + ' ' + p.Soyad AS Personel,
    'Mazeret' AS Tur,
    pd.Tarih,
    '-' AS Saat, 
    pd.MazeretTuru AS Aciklama
FROM Personel_Durum pd
INNER JOIN Personel p ON pd.PersonelID = p.PersonelID
WHERE pd.Uygun = 0

UNION ALL

SELECT 
    p.Ad + ' ' + p.Soyad AS Personel,
    'Sýnav Görevi' AS Tur,
    s.Tarih,
    CAST(o.BaslangicSaat AS VARCHAR(5)) AS Saat, 
    d.Ad + ' Sýnavý' AS Aciklama
FROM Gozetmen_Atamalari ga
INNER JOIN Personel p ON ga.PersonelID = p.PersonelID
INNER JOIN Sinav_Salonlari ss ON ga.SinavSalonID = ss.AtamaID
INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
INNER JOIN Dersler d ON s.DersID = d.DersID
INNER JOIN Oturumlar o ON s.OturumID = o.OturumID;
GO

-- View 4: Sýnav Kapasite Yeterlilik 
CREATE VIEW vw_SinavKapasiteDurumu AS
SELECT 
    s.SinavID,
    d.DersKodu,
    d.Ad AS DersAdi,
    d.OgrenciSayisi AS GerekenKapasite,
    dbo.fn_SinavAtananToplamKapasite(s.SinavID) AS AtananToplamKapasite,
    CASE 
        WHEN dbo.fn_SinavAtananToplamKapasite(s.SinavID) >= d.OgrenciSayisi THEN 'Yeterli'
        ELSE 'Yetersiz (Ek Salon Atanmalý)'
    END AS Durum
FROM Sinavlar s
INNER JOIN Dersler d ON s.DersID = d.DersID;
GO

--View 5:Adil daðýtýmý gösteren view
CREATE VIEW vw_GozetmenYukDagilimi AS
SELECT 
    p.Ad + ' ' + p.Soyad AS PersonelAdSoyad,
    b.BolumAd,
    s.Tarih,
    dbo.fn_GozetmenGorevSayisi(p.PersonelID, s.Tarih) AS GunlukGorevSayisi,
    dbo.fn_GozetmenToplamGorev(p.PersonelID) AS ToplamGorevSayisi
FROM Personel p
INNER JOIN Bolumler b ON p.BolumID = b.BolumID
CROSS JOIN (SELECT DISTINCT Tarih FROM Sinavlar) s
WHERE dbo.fn_GozetmenGorevSayisi(p.PersonelID, s.Tarih) > 0;
GO

-- ==========================================================================================
-- TRIGGERS (TETÝKLEYÝCÝLER)
-- ==========================================================================================

-- 1. TRIGGER: Salon Çakýþma Güvenliði (Ayný salon, ayný gün ve saatte kilitlenir.)
CREATE TRIGGER trg_SalonCakismaGuvenligi
ON Sinav_Salonlari
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Sinavlar s1 ON i.SinavID = s1.SinavID
        INNER JOIN Sinav_Salonlari ss ON i.DerslikID = ss.DerslikID AND i.AtamaID != ss.AtamaID
        INNER JOIN Sinavlar s2 ON ss.SinavID = s2.SinavID
        WHERE s1.Tarih = s2.Tarih AND s1.OturumID = s2.OturumID
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50005, 'GÜVENLÝK ÝHLALÝ: Bu derslikte ayný gün ve oturumda zaten baþka bir sýnav yapýlýyor!', 1;
    END
END;
GO

-- 2. TRIGGER: Gözetmen Çakýþma Güvenliði(Ayný personel, ayný gün ve saatte salona atanamaz)
CREATE TRIGGER trg_GozetmenCakismaGuvenligi
ON Gozetmen_Atamalari
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Sinav_Salonlari ss1 ON i.SinavSalonID = ss1.AtamaID
        INNER JOIN Sinavlar s1 ON ss1.SinavID = s1.SinavID
        INNER JOIN Gozetmen_Atamalari ga ON i.PersonelID = ga.PersonelID AND i.AtamaID != ga.AtamaID
        INNER JOIN Sinav_Salonlari ss2 ON ga.SinavSalonID = ss2.AtamaID
        INNER JOIN Sinavlar s2 ON ss2.SinavID = s2.SinavID
        WHERE s1.Tarih = s2.Tarih AND s1.OturumID = s2.OturumID
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50006, 'GÜVENLÝK ÝHLALÝ: Bu personel ayný gün ve oturumda zaten baþka bir salonda görevli!', 1;
    END
END;
GO


-- ==========================================================================================
-- STORED PROCEDURES (SAKLI YORDAMLAR - AKILLI ATAMA)
-- ==========================================================================================

-- 1. SP: Sýnav Ekleme (Zorunlu derslerin dönem/yarýyýl çakýþmasýný engeller.)
CREATE PROCEDURE SinavEkle
    @DersID INT,
    @Tarih DATE,
    @OturumID INT
AS
BEGIN
    DECLARE @Yariyil INT;
    DECLARE @DersTuru NVARCHAR(50);
    DECLARE @CakismaSayisi INT;
    DECLARE @GunlukSinavSayisi INT;

    SELECT @Yariyil = Yariyil, @DersTuru = DersTuru 
    FROM Dersler WHERE DersID = @DersID;

    -- Sadece zorunlu dersler için yarýyýl/oturum çakýþma kontrolü
    IF @DersTuru = 'Zorunlu'
    BEGIN
        SELECT @CakismaSayisi = COUNT(*)
        FROM Sinavlar s
        INNER JOIN Dersler d ON s.DersID = d.DersID
        WHERE d.Yariyil = @Yariyil 
          AND d.DersTuru = 'Zorunlu' 
          AND s.Tarih = @Tarih 
          AND s.OturumID = @OturumID;

        IF @CakismaSayisi > 0
        BEGIN
            THROW 50003, 'KURAL HATASI: Ayný yarýyýla ait iki zorunlu dersin sýnavý ayný oturuma konulamaz!', 1;
        END
    END

    -- Günlük 2'den fazla sýnav uyarýsý (zorunlu/seçmeli tüm dersler için)
    SELECT @GunlukSinavSayisi = COUNT(*)
    FROM Sinavlar s
    INNER JOIN Dersler d ON s.DersID = d.DersID
    WHERE d.Yariyil = @Yariyil 
      AND s.Tarih = @Tarih;

    IF @GunlukSinavSayisi >= 2
    BEGIN
        PRINT 'UYARI: ' + CAST(@Tarih AS VARCHAR(10)) + 
              ' tarihinde ' + CAST(@Yariyil AS VARCHAR(5)) + 
              '. yarýyýl için 2den fazla sýnav planlanýyor!';
    END

    -- Sýnavý ekle
    INSERT INTO Sinavlar (DersID, Tarih, OturumID)
    VALUES (@DersID, @Tarih, @OturumID);
END;
GO

-- 2. SP: Salon Atama (Derslik aktiflik denetimi + kapasite kontrolü)
CREATE PROCEDURE SalonAta
    @SinavID INT,
    @DerslikID INT
AS
BEGIN
    DECLARE @AktifMi BIT;
    DECLARE @GerekenKapasite INT;
    DECLARE @MevcutKapasite INT;
    DECLARE @YeniSalonKapasite INT;

    -- Derslik aktif mi kontrolü
    SELECT @AktifMi = Aktif FROM Derslikler WHERE DerslikID = @DerslikID;

    IF @AktifMi IS NULL
    BEGIN
        THROW 50007, 'HATA: Böyle bir derslik bulunamadý!', 1;
    END

    IF @AktifMi = 0
    BEGIN
        THROW 50001, 'HATA: Bu derslik aktif kullanýmda deðil!', 1;
    END

    -- Sýnav için gereken öðrenci kapasitesi
    SELECT @GerekenKapasite = d.OgrenciSayisi
    FROM Sinavlar s
    INNER JOIN Dersler d ON s.DersID = d.DersID
    WHERE s.SinavID = @SinavID;

    -- Þu ana kadar bu sýnava atanmýþ toplam kapasite
    SET @MevcutKapasite = dbo.fn_SinavAtananToplamKapasite(@SinavID);

    -- Eklenecek salonun kapasitesi
    SELECT @YeniSalonKapasite = Kapasite FROM Derslikler WHERE DerslikID = @DerslikID;

    -- Salon atamasýný yap
    INSERT INTO Sinav_Salonlari (SinavID, DerslikID)
    VALUES (@SinavID, @DerslikID);

    -- Ekleme sonrasý kapasite yeterli mi kontrolü (uyarý amaçlý)
    IF (@MevcutKapasite + @YeniSalonKapasite) < @GerekenKapasite
    BEGIN
        PRINT 'UYARI: Atanan toplam kapasite (' + 
              CAST(@MevcutKapasite + @YeniSalonKapasite AS VARCHAR(10)) + 
              ') hâlâ yetersiz! Gereken: ' + 
              CAST(@GerekenKapasite AS VARCHAR(10)) + 
              ' — Ek salon atamasý yapýlmalýdýr.';
    END
    ELSE
    BEGIN
        PRINT 'BILGI: Kapasite yeterli. Toplam atanan: ' + 
              CAST(@MevcutKapasite + @YeniSalonKapasite AS VARCHAR(10)) + 
              ' / Gereken: ' + 
              CAST(@GerekenKapasite AS VARCHAR(10));
    END
END;
GO

-- 3. SP: Gözetmen Atama (Günlük Art Arda 3 Görev Sýnýrý,Müsaitlik Korumalý)
CREATE PROCEDURE GozetmenAta
    @SinavSalonID INT,
    @PersonelID INT
AS
BEGIN
    DECLARE @Tarih DATE;
    DECLARE @OturumID INT;
    DECLARE @OturumSira INT;
    DECLARE @ArtArdaGorevSayisi INT;

    -- Atanacak salonun tarih ve oturum bilgisini al
    SELECT @Tarih = s.Tarih, @OturumID = s.OturumID
    FROM Sinav_Salonlari ss
    INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
    WHERE ss.AtamaID = @SinavSalonID;

    -- Atanacak oturumun sýra numarasýný al
    SELECT @OturumSira = OturumID FROM Oturumlar WHERE OturumID = @OturumID;

    -- Hemen önceki 3 oturuma art arda atanmýþ mý kontrolü
    -- (Atanacak oturum dahil, geriye doðru 3 ardýþýk oturuma bakýyoruz)
    SELECT @ArtArdaGorevSayisi = COUNT(DISTINCT s.OturumID)
    FROM Gozetmen_Atamalari ga
    INNER JOIN Sinav_Salonlari ss ON ga.SinavSalonID = ss.AtamaID
    INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
    WHERE ga.PersonelID = @PersonelID
      AND s.Tarih = @Tarih
      AND s.OturumID IN (
          @OturumSira - 1,
          @OturumSira - 2,
          @OturumSira - 3
      );

    -- Önceki 3 oturum da doluysa bu oturuma atanamaz
    IF @ArtArdaGorevSayisi = 3
    BEGIN
        THROW 50004, 'KURAL HATASI: Gözetmen art arda 3 oturumda görev aldý, bu oturuma atanamaz! Bir sonraki oturuma atanabilir.', 1;
    END

    -- Müsaitlik kontrolü
    IF dbo.fn_PersonelMusaitMi(@PersonelID, @Tarih, @OturumID) = 1
    BEGIN
        INSERT INTO Gozetmen_Atamalari (SinavSalonID, PersonelID)
        VALUES (@SinavSalonID, @PersonelID);
    END
    ELSE
    BEGIN
        THROW 50002, 'HATA: Personel bu tarihte müsait deðil (Mazeretli veya Çakýþma)!', 1;
    END
END;
GO


--=========================================================================================
--VERÝLERÝN GÝRÝLMESÝ
--==========================================================================================
--Bölümler
INSERT INTO Bolumler (BolumAd) VALUES 
('Yazýlým Mühendisliði'),
('Mekatronik Mühendisliði'),
('Makine Mühendisliði'),
('Enerji Sistemleri Mühendisliði'),
('Elektrik Mühendisliði');

-- Dersler Tablosu Veri Giriþi
INSERT INTO Dersler (DersKodu, Ad, DersTuru, OgrenciSayisi, Yariyil, BolumID) 
VALUES 
-- Yazýlým Mühendisliði (BolumID: 1)
('YZM101', 'Algoritma ve Programlama', 'Zorunlu', 150, 1, 1),
('YZM202', 'Veritabaný Yönetimi Sistemleri', 'Zorunlu', 120, 4, 1),
('YZM203', 'Veri Yapýlarý', 'Zorunlu', 90, 3, 1),
('YZM301', 'Yazýlým Sýnama', 'Seçmeli', 45, 6, 1),
('YZM201', 'Nesne Yönelik Programlama', 'Zorunlu', 130, 3, 1),


-- Mekatronik Mühendisliði (BolumID: 2)
('MEK101', 'Statik', 'Zorunlu', 135, 2, 2),
('MEK201', 'Makine Teorisi', 'Zorunlu', 95, 4, 2),
('MEK202', 'Termodinamik ve Isý Transferi', 'Zorunlu', 115, 4, 2),
('MEK401', 'Robotik', 'Seçmeli', 40, 7, 2),
('MEK301', 'Elektrik Makinalarý', 'Zorunlu', 105, 5, 2),

-- Makine Mühendisliði (BolumID: 3)
('MAK201', 'Mukavemet', 'Zorunlu', 160, 3, 3),
('MAK202', 'Dinamik', 'Zorunlu', 145, 3, 3),
('MAK301', 'Üretim Yöntemleri', 'Zorunlu', 100, 5, 3),
('MAK102', 'Ýstatistik', 'Seçmeli', 70, 2, 3),
('MAK302', 'Isý Transferi', 'Zorunlu', 120, 6, 3),

-- Enerji Sistemleri Mühendisliði (BolumID: 4)
('ENR101', 'Temel Elektronik', 'Zorunlu', 125, 1, 4),
('ENR201', 'Statik', 'Zorunlu', 110, 3, 4),
('ENR301', 'Rüzgar Enerjisi Teknolojileri', 'Seçmeli', 55, 5, 4),
('ENR302', 'Isý Transferleri', 'Zorunlu', 130, 6, 4),
('ENR202', 'Makine Elemanlarý', 'Zorunlu', 90, 4, 4),

-- Elektrik Mühendisliði (BolumID: 5) 
('ELK101', 'Elektronik', 'Zorunlu', 110, 2, 5),
('ELK102', 'Elektrik Devreleri', 'Zorunlu', 140, 2, 5),
('ELK201', 'Bilgisayar Destekli Çizim', 'Seçmeli', 30, 4, 5),
('ELK301', 'Elektromanyetik Alan Teorisi', 'Zorunlu', 85, 5, 5),
('ELK302', 'Sensör ve Algýlayýcýlar', 'Seçmeli', 50, 6, 5);

-- Derslikler Verileri
INSERT INTO Derslikler (Ad, Kapasite, Tip, Aktif, Kat) 
VALUES 
('Amfi-1', 100, 'Amfi', 1, 0),  
('Amfi-2', 100, 'Amfi', 1, 0),  
('Z-01', 40, 'Sinif', 1, 0),  
('101', 60, 'Sinif', 1, 1), 
('102', 60, 'Sinif', 1, 1), 
('103', 50, 'Sinif', 1, 1),
('201', 60, 'Sinif', 1, 2), 
('202', 70, 'Sinif', 1, 2), 
('Lab-1', 30, 'Lab', 1, 2),
('Lab-2', 30, 'Lab', 1, 2);

--Personel (Gözetmen Havuzu) - Güncellenmiþ Yaygýn Ýsimler
INSERT INTO Personel (Unvan, Ad, Soyad, BolumID) 
VALUES 
-- Yazýlým Mühendisliði (BolumID: 1)
('Dr. Öðr. Üyesi', 'Ahmet', 'Yýlmaz', 1),
('Arþ. Gör.', 'Canan', 'Kaya', 1),

-- Mekatronik Mühendisliði (BolumID: 2)
('Doç. Dr.', 'Mustafa', 'Öztürk', 2),
('Arþ. Gör.', 'Esra', 'Aydýn', 2),

-- Makine Mühendisliði (BolumID: 3)
('Prof. Dr.', 'Mehmet', 'Demir', 3),
('Arþ. Gör.', 'Buse', 'Yýldýz', 3),

-- Enerji Sistemleri Mühendisliði (BolumID: 4)
('Dr. Öðr. Üyesi', 'Emre', 'Þahin', 4),
('Arþ. Gör.', 'Zeynep', 'Çelik', 4),

-- Elektrik Mühendisliði (BolumID: 5)
('Doç. Dr.', 'Merve', 'Arslan', 5),
('Arþ. Gör.', 'Deniz', 'Erdoðan', 5);            

--OTURUMLAR (Sýnav Slotlarý)
INSERT INTO Oturumlar (Tanim, BaslangicSaat, BitisSaat) VALUES 
('Oturum 1', '09:00:00', '10:30:00'),
('Oturum 2', '11:00:00', '12:30:00'),
('Oturum 3', '13:30:00', '15:00:00'),
('Oturum 4', '15:30:00', '17:00:00');

-- Sadece Mazeretli ve Ýzinli Durumlarýn Girilmesi (Gereksiz "Müsait" satýrlarý temizlendi)
INSERT INTO Personel_Durum (PersonelID, Tarih, MazeretTuru, Uygun)
VALUES 
-- 1 HAZÝRAN PAZARTESÝ
(1, '2026-06-01', 'Farklý Fakültede Sýnav Görevi', 0),
(6, '2026-06-01', 'Saðlýk Raporu', 0),                 

-- 2 HAZÝRAN SALI
(3, '2026-06-02', 'Yýllýk Ýzin', 0),                   
(10, '2026-06-02', 'Þehir Dýþý Görevlendirme', 0),     

-- 3 HAZÝRAN ÇARÞAMBA
(2, '2026-06-03', 'Akademik Ýzin (Seminer)', 0),       

-- 4 HAZÝRAN PERÞEMBE
(8, '2026-06-04', 'Öðrenci Danýþmanlýk Saati', 0),     --

-- 5 HAZÝRAN CUMA
(9, '2026-06-05', 'Mazeret Ýzni', 0);

-- ==========================================================================================
-- SINAVLARIN SAKLI YORDAMLAR (SP) ÝLE KAYDEDÝLMESÝ
-- ==========================================================================================

-- 1 HAZÝRAN PAZARTESÝ
EXEC SinavEkle @DersID = 1,  @Tarih = '2026-06-01', @OturumID = 1; -- YZM101 Algoritma (Yazýlým-1)
EXEC SinavEkle @DersID = 21, @Tarih = '2026-06-01', @OturumID = 1; -- ENR101 Temel Elektronik (Enerji-1)
EXEC SinavEkle @DersID = 11, @Tarih = '2026-06-01', @OturumID = 2; -- MAK201 Mukavemet (Makine-3)
EXEC SinavEkle @DersID = 6,  @Tarih = '2026-06-01', @OturumID = 2; -- ELK101 Elektronik (Elektrik-2)
EXEC SinavEkle @DersID = 16, @Tarih = '2026-06-01', @OturumID = 3; -- MEK101 Statik (Mekatronik-2)

-- 2 HAZÝRAN SALI
EXEC SinavEkle @DersID = 2,  @Tarih = '2026-06-02', @OturumID = 1; -- YZM202 Veritabaný (Yazýlým-4)
EXEC SinavEkle @DersID = 7,  @Tarih = '2026-06-02', @OturumID = 1; -- ELK102 Elektrik Devreleri (Elektrik-2)
EXEC SinavEkle @DersID = 12, @Tarih = '2026-06-02', @OturumID = 2; -- MAK202 Dinamik (Makine-3)
EXEC SinavEkle @DersID = 22, @Tarih = '2026-06-02', @OturumID = 2; -- ENR201 Statik (Enerji-3)
EXEC SinavEkle @DersID = 17, @Tarih = '2026-06-02', @OturumID = 3; -- MEK201 Makine Teorisi (Mekatronik-4)

-- 3 HAZÝRAN ÇARÞAMBA
EXEC SinavEkle @DersID = 3,  @Tarih = '2026-06-03', @OturumID = 1; -- YZM203 Veri Yapýlarý (Yazýlým-3)
EXEC SinavEkle @DersID = 8,  @Tarih = '2026-06-03', @OturumID = 1; -- ELK201 Bilg. Destekli Çizim (Elektrik-4)
EXEC SinavEkle @DersID = 13, @Tarih = '2026-06-03', @OturumID = 2; -- MAK301 Üretim Yöntemleri (Makine-5)
EXEC SinavEkle @DersID = 23, @Tarih = '2026-06-03', @OturumID = 2; -- ENR301 Rüzgar En. (Enerji-5)
EXEC SinavEkle @DersID = 18, @Tarih = '2026-06-03', @OturumID = 3; -- MEK202 Termodinamik (Mekatronik-4)

-- 4 HAZÝRAN PERÞEMBE
EXEC SinavEkle @DersID = 5,  @Tarih = '2026-06-04', @OturumID = 1; -- YZM201 Nesne Yönelik (Yazýlým-3)
EXEC SinavEkle @DersID = 9,  @Tarih = '2026-06-04', @OturumID = 1; -- ELK301 Elektromanyetik (Elektrik-5)
EXEC SinavEkle @DersID = 14, @Tarih = '2026-06-04', @OturumID = 2; -- MAK102 Ýstatistik (Makine-2)
EXEC SinavEkle @DersID = 24, @Tarih = '2026-06-04', @OturumID = 2; -- ENR302 Isý Transferleri (Enerji-6)
EXEC SinavEkle @DersID = 19, @Tarih = '2026-06-04', @OturumID = 3; -- MEK401 Robotik (Mekatronik-7)

-- 5 HAZÝRAN CUMA
EXEC SinavEkle @DersID = 4,  @Tarih = '2026-06-05', @OturumID = 1; -- YZM301 Yazýlým Sýnama (Yazýlým-6)
EXEC SinavEkle @DersID = 10, @Tarih = '2026-06-05', @OturumID = 1; -- ELK302 Sensörler (Elektrik-6)
EXEC SinavEkle @DersID = 15, @Tarih = '2026-06-05', @OturumID = 2; -- MAK302 Isý Transferi (Makine-6)
EXEC SinavEkle @DersID = 25, @Tarih = '2026-06-05', @OturumID = 2; -- ENR202 Makine Elemanlarý (Enerji-4)
EXEC SinavEkle @DersID = 20, @Tarih = '2026-06-05', @OturumID = 3; -- MEK301 Elektrik Makinalarý (Mekatronik-5)

-- ==========================================================================================
-- SALONLARIN SAKLI YORDAMLAR (SP) ÝLE KAYDEDÝLMESÝ
-- ==========================================================================================

-- 1 HAZÝRAN PAZARTESÝ
EXEC SalonAta 1, 1; -- YZM101 -> Amfi-1
EXEC SalonAta 1, 4; -- YZM101 -> 101

EXEC SalonAta 2, 2; -- ENR101 -> Amfi-2
EXEC SalonAta 2, 3; -- ENR101 -> Z-01

EXEC SalonAta 3, 8; -- MAK201 -> 202
EXEC SalonAta 3, 7; -- MAK201 -> 201
EXEC SalonAta 3, 9; -- MAK201 -> Lab-1

EXEC SalonAta 4, 5; -- ELK101 -> 102
EXEC SalonAta 4, 6; -- ELK101 -> 103

EXEC SalonAta 5, 7; -- MEK101 -> 201
EXEC SalonAta 5, 8; -- MEK101 -> 202
EXEC SalonAta 5, 10;-- MEK101 -> Lab-2

-- 2 HAZÝRAN SALI
EXEC SalonAta 6, 1; -- YZM202 -> Amfi-1
EXEC SalonAta 6, 3; -- YZM202 -> Z-01

EXEC SalonAta 7, 4; -- ELK102 -> 101
EXEC SalonAta 7, 5; -- ELK102 -> 102
EXEC SalonAta 7, 10;-- ELK102 -> Lab-2

EXEC SalonAta 8, 8; -- MAK202 -> 202
EXEC SalonAta 8, 7; -- MAK202 -> 201
EXEC SalonAta 8, 9; -- MAK202 -> Lab-1

EXEC SalonAta 9, 3; -- ENR201 -> Z-01
EXEC SalonAta 9, 2; -- ENR201 -> Amfi-2

EXEC SalonAta 10, 6; -- MEK201 -> 103
EXEC SalonAta 10, 5; -- MEK201 -> 102

-- 3 HAZÝRAN ÇARÞAMBA
EXEC SalonAta 11, 7; -- YZM203 -> 201
EXEC SalonAta 11, 8; -- YZM203 -> 202
EXEC SalonAta 12, 9; -- ELK201 -> Lab-1
EXEC SalonAta 13, 1; -- MAK301 -> Amfi-1
EXEC SalonAta 14, 10;-- ENR301 -> Lab-2
EXEC SalonAta 14, 9; -- ENR301 -> Lab-1
EXEC SalonAta 15, 4; -- MEK202 -> 101
EXEC SalonAta 15, 5; -- MEK202 -> 102

-- 4 HAZÝRAN PERÞEMBE
EXEC SalonAta 16, 1; -- YZM201 -> Amfi-1
EXEC SalonAta 16, 2; -- YZM201 -> Amfi-2
EXEC SalonAta 17, 8; -- ELK301 -> 202
EXEC SalonAta 17, 7; -- ELK301 -> 201
EXEC SalonAta 18, 6; -- MAK102 -> 103
EXEC SalonAta 18, 5; -- MAK102 -> 102
EXEC SalonAta 19, 3; -- ENR302 -> Z-01
EXEC SalonAta 19, 9; -- ENR302 -> Lab-1
EXEC SalonAta 19, 1; -- ENR302 -> Amfi-1
EXEC SalonAta 20, 10;-- MEK401 -> Lab-2
EXEC SalonAta 20, 6; -- MEK401 -> 103

-- 5 HAZÝRAN CUMA
EXEC SalonAta 21, 5; -- YZM301 -> 102
EXEC SalonAta 22, 6; -- ELK302 -> 103
EXEC SalonAta 23, 1; -- MAK302 -> Amfi-1
EXEC SalonAta 23, 2; -- MAK302 -> Amfi-2
EXEC SalonAta 24, 8; -- ENR202 -> 202
EXEC SalonAta 24, 7; -- ENR202 -> 201
EXEC SalonAta 25, 4; -- MEK301 -> 101
EXEC SalonAta 25, 5; -- MEK301 -> 102
GO

-- ==========================================================================================
-- GÖZETMENLERÝN SAKLI YORDAMLAR (SP) ÝLE ATANMASI
-- ==========================================================================================

-- 1 HAZÝRAN PAZARTESÝ
-- YZM101 (AtamaID: 1, 2) | ENR101 (AtamaID: 3, 4) | MAK201 (AtamaID: 5, 6, 7) | ELK101 (AtamaID: 8, 9) | MEK101 (AtamaID: 10, 11, 12)
EXEC GozetmenAta 1, 2;   -- Canan Kaya (Yazýlým) [Ahmet Yýlmaz mazeretli]
EXEC GozetmenAta 2, 9;   -- Merve Arslan (Havuz-Elektrik)
EXEC GozetmenAta 3, 7;   -- Emre Þahin (Enerji)
EXEC GozetmenAta 4, 8;   -- Zeynep Çelik (Enerji)
EXEC GozetmenAta 5, 5;   -- Mehmet Demir (Makine) [Buse Yýldýz mazeretli]
EXEC GozetmenAta 6, 4;   -- Esra Aydýn (Havuz-Mekatronik)
EXEC GozetmenAta 7, 10;  -- Deniz Erdoðan (Havuz-Elektrik)
EXEC GozetmenAta 8, 9;   -- Merve Arslan (Elektrik)
EXEC GozetmenAta 9, 3;   -- Mustafa Öztürk (Mekatronik)
EXEC GozetmenAta 10, 4;  -- Esra Aydýn (Mekatronik)
EXEC GozetmenAta 11, 7;  -- Emre Þahin (Havuz-Enerji)
EXEC GozetmenAta 12, 5;  -- Mehmet Demir (Havuz-Makine)

-- 2 HAZÝRAN SALI
-- YZM202 (13, 14) | ELK102 (15, 16, 17) | MAK202 (18, 19, 20) | ENR201 (21, 22) | MEK201 (23, 24)
EXEC GozetmenAta 13, 1;  -- Ahmet Yýlmaz (Yazýlým)
EXEC GozetmenAta 14, 2;  -- Canan Kaya (Yazýlým)
EXEC GozetmenAta 15, 9;  -- Merve Arslan (Elektrik)
EXEC GozetmenAta 16, 5;  -- Mehmet Demir (Havuz-Makine)
EXEC GozetmenAta 17, 6;  -- Buse Yýldýz (Havuz-Makine)
EXEC GozetmenAta 18, 5;  -- Mehmet Demir (Makine)
EXEC GozetmenAta 19, 6;  -- Buse Yýldýz (Makine)
EXEC GozetmenAta 20, 1;  -- Ahmet Yýlmaz (Havuz-Yazýlým)
EXEC GozetmenAta 21, 7;  -- Emre Þahin (Enerji)
EXEC GozetmenAta 22, 8;  -- Zeynep Çelik (Enerji)
EXEC GozetmenAta 23, 4;  -- Esra Aydýn (Mekatronik) [Mustafa Öztürk mazeretli]
EXEC GozetmenAta 24, 2;  -- Canan Kaya (Havuz-Yazýlým)

-- 3 HAZÝRAN ÇARÞAMBA
-- YZM203 (25, 26) | ELK201 (27) | MAK301 (28) | ENR301 (29, 30) | MEK202 (31, 32)
EXEC GozetmenAta 25, 1;  -- Ahmet Yýlmaz (Yazýlým) [Canan Kaya mazeretli]
EXEC GozetmenAta 26, 3;  -- Mustafa Öztürk (Havuz-Mekatronik)
EXEC GozetmenAta 27, 9;  -- Merve Arslan (Elektrik)
EXEC GozetmenAta 28, 5;  -- Mehmet Demir (Makine)
EXEC GozetmenAta 29, 7;  -- Emre Þahin (Enerji)
EXEC GozetmenAta 30, 8;  -- Zeynep Çelik (Enerji)
EXEC GozetmenAta 31, 3;  -- Mustafa Öztürk (Mekatronik)
EXEC GozetmenAta 32, 10; -- Deniz Erdoðan (Havuz-Elektrik)

-- 4 HAZÝRAN PERÞEMBE
-- YZM201 (33, 34) | ELK301 (35, 36) | MAK102 (37, 38) | ENR302 (39, 40, 41) | MEK401 (42, 43)
EXEC GozetmenAta 33, 1;  -- Ahmet Yýlmaz (Yazýlým)
EXEC GozetmenAta 34, 2;  -- Canan Kaya (Yazýlým)
EXEC GozetmenAta 35, 9;  -- Merve Arslan (Elektrik)
EXEC GozetmenAta 36, 10; -- Deniz Erdoðan (Elektrik)
EXEC GozetmenAta 37, 5;  -- Mehmet Demir (Makine)
EXEC GozetmenAta 38, 6;  -- Buse Yýldýz (Makine)
EXEC GozetmenAta 39, 7;  -- Emre Þahin (Enerji) [Zeynep Çelik mazeretli]
EXEC GozetmenAta 40, 3;  -- Mustafa Öztürk (Havuz-Mekatronik)
EXEC GozetmenAta 41, 4;  -- Esra Aydýn (Havuz-Mekatronik)
EXEC GozetmenAta 42, 4;  -- Esra Aydýn (Mekatronik)
EXEC GozetmenAta 43, 2;  -- Canan Kaya (Havuz-Yazýlým)

-- 5 HAZÝRAN CUMA
-- YZM301 (44) | ELK302 (45) | MAK302 (46, 47) | ENR202 (48, 49) | MEK301 (50, 51)
EXEC GozetmenAta 44, 1;  -- Ahmet Yýlmaz (Yazýlým)
EXEC GozetmenAta 45, 10; -- Deniz Erdoðan (Elektrik) [Merve Arslan mazeretli]
EXEC GozetmenAta 46, 5;  -- Mehmet Demir (Makine)
EXEC GozetmenAta 47, 6;  -- Buse Yýldýz (Makine)
EXEC GozetmenAta 48, 7;  -- Emre Þahin (Enerji)
EXEC GozetmenAta 49, 8;  -- Zeynep Çelik (Enerji)
EXEC GozetmenAta 50, 3;  -- Mustafa Öztürk (Mekatronik)
EXEC GozetmenAta 51, 4;  -- Esra Aydýn (Mekatronik)