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
    CONSTRAINT CK_DerslikTip CHECK (Tip IN ('Büyük', 'Orta', 'Küçük'))
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

CREATE TABLE Donem_Ayarlari (
    AyarID INT PRIMARY KEY DEFAULT 1,
    DonemBaslangicTarihi DATE NOT NULL,
    DonemBitisTarihi DATE NOT NULL,  
    CONSTRAINT CHK_TekSatir CHECK (AyarID = 1) 
);
GO

-- ==========================================================================================
-- ÝNDEKSLER (Performans Optimizasyonu Ýçin)
-- ==========================================================================================
CREATE NONCLUSTERED INDEX IX_Sinavlar_DersID ON Sinavlar(DersID);
CREATE NONCLUSTERED INDEX IX_GozetmenAtamalari_PersonelID ON Gozetmen_Atamalari(PersonelID);
CREATE NONCLUSTERED INDEX IX_PersonelDurum_Tarih ON Personel_Durum(Tarih);
CREATE NONCLUSTERED INDEX IX_SinavSalonlari_SinavID ON Sinav_Salonlari(SinavID);
CREATE NONCLUSTERED INDEX IX_SinavSalonlari_DerslikID ON Sinav_Salonlari(DerslikID);
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
    WHERE ss.SinavID = @SinavID
    AND d.Aktif = 1;
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

--View 5: Adil daðýtýmý gösteren view
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
    DECLARE @DonemBaslangic DATE;
    DECLARE @DonemBitis DATE;

    SELECT @DonemBaslangic = DonemBaslangicTarihi, @DonemBitis = DonemBitisTarihi
    FROM Donem_Ayarlari 
    WHERE AyarID = 1;

    -- Tarih kontrolü
    IF @Tarih < @DonemBaslangic OR @Tarih > @DonemBitis
    BEGIN
        ;THROW 50008, 'HATA: Girilen sýnav tarihi, belirlenen dönem aralýðýnýn dýþýndadýr!', 1;
    END
    DECLARE @Yariyil INT;
    DECLARE @DersTuru NVARCHAR(50);
    DECLARE @BolumID INT;
    DECLARE @CakismaSayisi INT;
    DECLARE @GunlukSinavSayisi INT;
    DECLARE @OturumSirasi INT;
    DECLARE @ArtArdaCakisma INT = 0;

    SELECT @Yariyil = Yariyil, @DersTuru = DersTuru, @BolumID = BolumID
    FROM Dersler WHERE DersID = @DersID;

    IF @Yariyil IS NULL
    THROW 50007, 'HATA: Geçersiz DersID!', 1;

    -- Ayný Bölüm Ve Döneme Ait Art Arda 2 Sýnav Koyma Engelleme 
    -- Atanacak oturumun gün içindeki gerçek sýrasýný bul
    SELECT @OturumSirasi = SiraNo
    FROM (
        SELECT OturumID, ROW_NUMBER() OVER (ORDER BY BaslangicSaat) AS SiraNo
        FROM Oturumlar
    ) t
    WHERE OturumID = @OturumID;

    -- Ayný Bölüm ve AYNI YARIYIL için bir önceki (SiraNo - 1) veya bir sonraki (SiraNo + 1) oturumda sýnav var mý?
    SELECT @ArtArdaCakisma = COUNT(*)
    FROM Sinavlar s
    INNER JOIN Dersler d ON s.DersID = d.DersID
    INNER JOIN (
        SELECT OturumID, ROW_NUMBER() OVER (ORDER BY BaslangicSaat) AS SiraNo
        FROM Oturumlar
    ) o ON s.OturumID = o.OturumID
    WHERE s.Tarih = @Tarih 
      AND d.BolumID = @BolumID 
      AND d.Yariyil = @Yariyil
      AND (o.SiraNo = @OturumSirasi - 1 OR o.SiraNo = @OturumSirasi + 1);

    IF @ArtArdaCakisma > 0
    BEGIN
        ;THROW 50009, 'KURAL HATASI: Öðrencilerin peþ peþe sýnava girmemesi için ayný bölüm ve yarýyýla ait ardýþýk oturumlara sýnav konulamaz!', 1;
    END

    -- Sadece zorunlu dersler için yarýyýl/oturum çakýþma kontrolü
    IF @DersTuru = 'Zorunlu'
    BEGIN
        SELECT @CakismaSayisi = COUNT(*)
        FROM Sinavlar s
        INNER JOIN Dersler d ON s.DersID = d.DersID
        WHERE d.Yariyil = @Yariyil 
          AND d.BolumID = @BolumID
          AND d.DersTuru = 'Zorunlu' 
          AND s.Tarih = @Tarih 
          AND s.OturumID = @OturumID;

        IF @CakismaSayisi > 0
        BEGIN
            ;THROW 50003, 'KURAL HATASI: Ayný yarýyýla ait iki zorunlu dersin sýnavý ayný oturuma konulamaz!', 1;
        END
    END

    -- Günlük 2'den fazla sýnav uyarýsý (zorunlu/seçmeli tüm dersler için)
    SELECT @GunlukSinavSayisi = COUNT(*)
    FROM Sinavlar s
    INNER JOIN Dersler d ON s.DersID = d.DersID
    WHERE d.Yariyil = @Yariyil 
      AND d.BolumID = @BolumID
      AND s.Tarih = @Tarih;

    IF @GunlukSinavSayisi >= 2
    BEGIN
        PRINT 'UYARI: ' + CAST(@Tarih AS VARCHAR(10)) + 
              ' tarihinde ' + CAST(@Yariyil AS VARCHAR(5)) + 
              '. yarýyýl için 2den fazla sýnav planlanýyor!';
    END

    INSERT INTO Sinavlar (DersID, Tarih, OturumID)
    VALUES (@DersID, @Tarih, @OturumID);
END;
GO

-- 2. SP: Salon Atama (Derslik aktiflik denetimi + kapasite kontrolü)
CREATE PROCEDURE SalonAta
    @SinavID INT,
    @DerslikID INT = NULL
AS
BEGIN
    DECLARE @GerekenKapasite INT, @MevcutKapasite INT, @SalonKapasite INT;
    DECLARE @Tarih DATE, @OturumID INT, @HedefKat INT;

    SELECT @Tarih = s.Tarih, @OturumID = s.OturumID, @GerekenKapasite = d.OgrenciSayisi
    FROM Sinavlar s 
    INNER JOIN Dersler d ON s.DersID = d.DersID
    WHERE s.SinavID = @SinavID;

    -- Manuel Mod
    IF @DerslikID IS NOT NULL
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM Derslikler WHERE DerslikID = @DerslikID AND Aktif = 1)
            THROW 50001, 'HATA: Derslik bulunamadý veya aktif deðil!', 1;

        INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (@SinavID, @DerslikID);

        -- Kapasite uyarýsý
        SET @MevcutKapasite = dbo.fn_SinavAtananToplamKapasite(@SinavID);
        IF @MevcutKapasite < @GerekenKapasite
            PRINT 'UYARI: Kapasite hâlâ yetersiz! Gereken: ' + 
                  CAST(@GerekenKapasite AS VARCHAR(10)) + 
                  ', Atanan: ' + CAST(@MevcutKapasite AS VARCHAR(10));
        ELSE
            PRINT 'BÝLGÝ: Kapasite yeterli. Atanan: ' + 
                  CAST(@MevcutKapasite AS VARCHAR(10)) + 
                  ' / Gereken: ' + CAST(@GerekenKapasite AS VARCHAR(10));
    END

    -- Otomatik Mod
    ELSE
    BEGIN
        SET @MevcutKapasite = dbo.fn_SinavAtananToplamKapasite(@SinavID);

        -- Daha önce atanan salon varsa onun katýný hedef kat yap
        SET @HedefKat = NULL;
        SELECT TOP 1 @HedefKat = d.Kat 
        FROM Sinav_Salonlari ss 
        INNER JOIN Derslikler d ON ss.DerslikID = d.DerslikID 
        WHERE ss.SinavID = @SinavID;

        WHILE @MevcutKapasite < @GerekenKapasite
        BEGIN
            SET @DerslikID = NULL;

            SELECT TOP 1 
                @DerslikID = d.DerslikID, 
                @SalonKapasite = d.Kapasite
            FROM Derslikler d
            WHERE d.Aktif = 1
              AND d.DerslikID NOT IN (
                  SELECT DerslikID FROM Sinav_Salonlari 
                  WHERE SinavID = @SinavID
              )
              AND d.DerslikID NOT IN (
                  SELECT ss.DerslikID FROM Sinav_Salonlari ss
                  INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
                  WHERE s.Tarih = @Tarih AND s.OturumID = @OturumID
              )
            ORDER BY 
                CASE WHEN @HedefKat IS NOT NULL AND d.Kat = @HedefKat THEN 0 ELSE 1 END,
                d.Kapasite DESC;

            IF @DerslikID IS NULL
            BEGIN
                PRINT 'UYARI: Müsait salon kalmadý, yeterli kapasite saðlanamadý!';
                BREAK;
            END

            INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (@SinavID, @DerslikID);
            
            -- Ýlk atamadan sonra hedef katý belirle
            IF @HedefKat IS NULL
                SELECT @HedefKat = Kat FROM Derslikler WHERE DerslikID = @DerslikID;

            SET @MevcutKapasite = @MevcutKapasite + @SalonKapasite;
        END

        PRINT 'BÝLGÝ: Otomatik atama tamamlandý. Atanan: ' + 
              CAST(@MevcutKapasite AS VARCHAR(10)) + 
              ' / Gereken: ' + CAST(@GerekenKapasite AS VARCHAR(10));
    END
END;
GO

-- 3. SP: Gözetmen Atama (Günlük Art Arda 3 Görev Sýnýrý,Müsaitlik Korumalý)
CREATE PROCEDURE GozetmenAta
    @SinavSalonID INT,
    @PersonelID INT = NULL
AS
BEGIN
    DECLARE @Tarih DATE;
    DECLARE @OturumID INT;
    DECLARE @DersBolumID INT;
    DECLARE @OturumSirasi INT;

    SELECT 
        @Tarih = s.Tarih, 
        @OturumID = s.OturumID,
        @DersBolumID = d.BolumID
    FROM Sinav_Salonlari ss
    INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
    INNER JOIN Dersler d ON s.DersID = d.DersID
    WHERE ss.AtamaID = @SinavSalonID;

    SELECT @OturumSirasi = SiraNo
    FROM (
        SELECT OturumID, ROW_NUMBER() OVER (ORDER BY BaslangicSaat) AS SiraNo
        FROM Oturumlar
    ) t
    WHERE OturumID = @OturumID;

    IF @PersonelID IS NOT NULL
    BEGIN
        IF dbo.fn_PersonelMusaitMi(@PersonelID, @Tarih, @OturumID) = 0
            THROW 50002, 'HATA: Personel bu tarihte müsait deðil!', 1;

        DECLARE @GeriZincir INT = 0;
        DECLARE @IleriZincir INT = 0;
        DECLARE @Dongu INT;
        DECLARE @KontrolOturumID INT;

        -- Geriye Dönük Kontrol
        SET @Dongu = 1;
        WHILE @Dongu <= 3
        BEGIN
            SET @KontrolOturumID = NULL;

            SELECT @KontrolOturumID = OturumID FROM (
                SELECT OturumID, ROW_NUMBER() OVER (ORDER BY BaslangicSaat) AS SiraNo 
                FROM Oturumlar
            ) t WHERE SiraNo = @OturumSirasi - @Dongu;

            IF @KontrolOturumID IS NOT NULL AND EXISTS (
                SELECT 1 FROM Gozetmen_Atamalari ga
                INNER JOIN Sinav_Salonlari ss ON ga.SinavSalonID = ss.AtamaID
                INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
                WHERE ga.PersonelID = @PersonelID 
                  AND s.Tarih = @Tarih 
                  AND s.OturumID = @KontrolOturumID
            )
                SET @GeriZincir = @GeriZincir + 1;
            ELSE BREAK;

            SET @Dongu = @Dongu + 1;
        END

        -- Ýleriye Dönük Kontrol
        SET @Dongu = 1;
        WHILE @Dongu <= 3
        BEGIN
            SET @KontrolOturumID = NULL;

            SELECT @KontrolOturumID = OturumID FROM (
                SELECT OturumID, ROW_NUMBER() OVER (ORDER BY BaslangicSaat) AS SiraNo 
                FROM Oturumlar
            ) t WHERE SiraNo = @OturumSirasi + @Dongu;

            IF @KontrolOturumID IS NOT NULL AND EXISTS (
                SELECT 1 FROM Gozetmen_Atamalari ga
                INNER JOIN Sinav_Salonlari ss ON ga.SinavSalonID = ss.AtamaID
                INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
                WHERE ga.PersonelID = @PersonelID 
                  AND s.Tarih = @Tarih 
                  AND s.OturumID = @KontrolOturumID
            )
                SET @IleriZincir = @IleriZincir + 1;
            ELSE BREAK;

            SET @Dongu = @Dongu + 1;
        END

        IF (@GeriZincir + @IleriZincir + 1) > 3
            THROW 50004, 'KURAL HATASI: Bu atama yapýlýrsa gözetmen art arda 3ten fazla oturumda görev almýþ olacak!', 1;

        INSERT INTO Gozetmen_Atamalari (SinavSalonID, PersonelID) 
        VALUES (@SinavSalonID, @PersonelID);
        PRINT 'BÝLGÝ: Manuel atama baþarýyla yapýldý.';
    END

    ELSE
    BEGIN
        SELECT TOP 1 @PersonelID = p.PersonelID
        FROM Personel p
        WHERE dbo.fn_PersonelMusaitMi(p.PersonelID, @Tarih, @OturumID) = 1
          AND (
              SELECT COUNT(*)
              FROM Gozetmen_Atamalari ga2
              INNER JOIN Sinav_Salonlari ss2 ON ga2.SinavSalonID = ss2.AtamaID
              INNER JOIN Sinavlar s2 ON ss2.SinavID = s2.SinavID
              INNER JOIN (
                  SELECT OturumID, ROW_NUMBER() OVER (ORDER BY BaslangicSaat) AS SiraNo 
                  FROM Oturumlar
              ) o2 ON s2.OturumID = o2.OturumID
              WHERE ga2.PersonelID = p.PersonelID 
                AND s2.Tarih = @Tarih 
                AND o2.SiraNo >= @OturumSirasi - 2 
                AND o2.SiraNo < @OturumSirasi + 2
          ) < 3
        ORDER BY 
            CASE WHEN p.BolumID = @DersBolumID THEN 0 ELSE 1 END ASC,
            dbo.fn_GozetmenToplamGorev(p.PersonelID) ASC;

        IF @PersonelID IS NULL
        BEGIN
            PRINT 'UYARI: Havuzda uygun gözetmen bulunamadý!';
            RETURN;
        END

        INSERT INTO Gozetmen_Atamalari (SinavSalonID, PersonelID) 
        VALUES (@SinavSalonID, @PersonelID);
        PRINT 'BÝLGÝ: Otomatik atama yapýldý. PersonelID: ' + CAST(@PersonelID AS VARCHAR(10));
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
-- ÖNCE TEST DERSLERÝ 
INSERT INTO Dersler (DersKodu, Ad, DersTuru, OgrenciSayisi, Yariyil, BolumID) VALUES 
    -- Yazýlým Mühendisliði (DersID: 1 - 5)
    ('YZM101', 'Algoritma ve Programlama', 'Zorunlu', 150, 1, 1),
    ('YZM202', 'Veritabaný Yönetimi Sistemleri', 'Zorunlu', 120, 4, 1),
    ('YZM203', 'Veri Yapýlarý', 'Zorunlu', 90, 3, 1),
    ('YZM301', 'Yazýlým Sýnama', 'Seçmeli', 45, 6, 1),
    ('YZM201', 'Nesne Yönelik Programlama', 'Zorunlu', 130, 3, 1),
    
    -- Mekatronik Mühendisliði (DersID: 6 - 10)
    ('MEK101', 'Statik', 'Zorunlu', 135, 2, 2),
    ('MEK201', 'Makine Teorisi', 'Zorunlu', 95, 4, 2),
    ('MEK202', 'Termodinamik ve Isý Transferi', 'Zorunlu', 115, 4, 2),
    ('MEK401', 'Robotik', 'Seçmeli', 40, 7, 2),
    ('MEK301', 'Elektrik Makinalarý', 'Zorunlu', 105, 5, 2),
    
    -- Makine Mühendisliði (DersID: 11 - 15)
    ('MAK201', 'Mukavemet', 'Zorunlu', 160, 3, 3),
    ('MAK202', 'Dinamik', 'Zorunlu', 145, 3, 3),
    ('MAK301', 'Üretim Yöntemleri', 'Zorunlu', 100, 5, 3),
    ('MAK102', 'Ýstatistik', 'Seçmeli', 70, 2, 3),
    ('MAK302', 'Isý Transferi', 'Zorunlu', 120, 6, 3),
    
    -- Enerji Sistemleri Mühendisliði (DersID: 16 - 20)
    ('ENR101', 'Temel Elektronik', 'Zorunlu', 125, 1, 4),
    ('ENR201', 'Statik', 'Zorunlu', 110, 3, 4),
    ('ENR301', 'Rüzgar Enerjisi Teknolojileri', 'Seçmeli', 55, 5, 4),
    ('ENR302', 'Isý Transferleri', 'Zorunlu', 130, 6, 4),
    ('ENR202', 'Makine Elemanlarý', 'Zorunlu', 90, 4, 4),
    
    -- Elektrik Mühendisliði (DersID: 21 - 25)
    ('ELK101', 'Elektronik', 'Zorunlu', 110, 2, 5),
    ('ELK102', 'Elektrik Devreleri', 'Zorunlu', 140, 2, 5),
    ('ELK201', 'Bilgisayar Destekli Çizim', 'Seçmeli', 30, 4, 5),
    ('ELK301', 'Elektromanyetik Alan Teorisi', 'Zorunlu', 85, 5, 5),
    ('ELK302', 'Sensör ve Algýlayýcýlar', 'Seçmeli', 50, 6, 5);


-- SONRA GERÇEK MÜFREDAT GÝRÝÞLERÝ 
INSERT INTO Dersler (DersKodu, Ad, DersTuru, OgrenciSayisi, Yariyil, BolumID) VALUES 
    -- Yazýlým Mühendisliði
    ('YZM-FIZ1301', 'Fizik I', 'Zorunlu', 100, 1, 1),
    ('YZM-MAT1301', 'Matematik I', 'Zorunlu', 100, 1, 1),
    ('YZM-YDI1121', 'Yabancý Dil I', 'Zorunlu', 100, 1, 1),
    ('YZM-TDL1111', 'Türk Dili I', 'Zorunlu', 100, 1, 1),
    ('YZM-AIT1101', 'Atatürk Ýlkeleri ve Ýnkýlap Tarihi I', 'Zorunlu', 100, 1, 1),
    ('YZM1107', 'Temel Bilgisayar Bilimleri', 'Zorunlu', 100, 1, 1),
    ('YZM1111', 'Algoritma ve Programlama I', 'Zorunlu', 100, 1, 1),
    ('YZM1113', 'Yazýlým Mühendisliðinde Kariyer Planlama', 'Zorunlu', 100, 1, 1),
    ('YZM-ADS1202', 'Alan Dýþý Seçmeli Dersler', 'Seçmeli', 50, 2, 1),
    ('YZM-FIZ1302', 'Fizik II', 'Zorunlu', 100, 2, 1),
    ('YZM-MAT1302', 'Matematik II', 'Zorunlu', 100, 2, 1),
    ('YZM-YDI1122', 'Yabancý Dil II', 'Zorunlu', 100, 2, 1),
    ('YZM-TDL1112', 'Türk Dili II', 'Zorunlu', 100, 2, 1),
    ('YZM-AIT1102', 'Atatürk Ýlkeleri ve Ýnkýlap Tarihi II', 'Zorunlu', 100, 2, 1),
    ('YZM1108', 'Yazýlým Mühendisliðine Giriþ', 'Zorunlu', 100, 2, 1),
    ('YZM1112', 'Algoritma ve Programlama II', 'Zorunlu', 100, 2, 1),
    ('YZM-ADS2201', 'Alan Dýþý Seçmeli Ders', 'Seçmeli', 50, 3, 1),
    ('YZM-CBU4403', 'Ýþ Saðlýðý ve Güvenliði I', 'Zorunlu', 100, 3, 1),
    ('YZM2111', 'Ayrýk Yapýlar', 'Zorunlu', 100, 3, 1),
    ('YZM2113', 'Mühendislik Matematiði', 'Zorunlu', 100, 3, 1),
    ('YZM2123', 'Web Programlamaya Giriþ', 'Zorunlu', 100, 3, 1),
    ('YZM2125', 'Nesneye Yönelik Programlama', 'Zorunlu', 100, 3, 1),
    ('YZM2127', 'Yazýlým Gereksinim Analizi', 'Zorunlu', 100, 3, 1),
    ('YZM2200', 'Teknik Seçmeli Ders', 'Seçmeli', 50, 4, 1),
    ('YZM-CBU4404', 'Ýþ Saðlýðý ve Güvenliði II', 'Zorunlu', 100, 4, 1),
    ('YZM2114', 'Olasýlýk ve Ýstatistik', 'Zorunlu', 100, 4, 1),
    ('YZM2122', 'Yazýlým Yapýmý', 'Zorunlu', 100, 4, 1),
    ('YZM2126', 'Veritabaný Sistemlerine Giriþ', 'Zorunlu', 100, 4, 1),
    ('YZM2128', 'Veri Yapýlarý', 'Zorunlu', 100, 4, 1),
    ('YZM2130', 'Yazýlým Mimarisi ve Tasarýmý', 'Zorunlu', 100, 4, 1),
    ('YMS3201', 'Teknik Seçmeli Ders', 'Seçmeli', 50, 5, 1),
    ('YZM3107', 'Veritabaný Yönetim Sistemleri', 'Zorunlu', 100, 5, 1),
    ('YZM3109', 'Bilgisayar Aðlarý', 'Zorunlu', 100, 5, 1),
    ('YZM3111', 'Yazýlým Sýnama', 'Zorunlu', 100, 5, 1),
    ('YMS3202', 'Teknik Seçmeli Ders', 'Seçmeli', 50, 6, 1),
    ('YZM3116', 'Ýþletim Sistemleri', 'Zorunlu', 100, 6, 1),
    ('YZM3118', 'Algoritma Analizi ve Tasarýmý', 'Zorunlu', 100, 6, 1),
    ('YZM3120', 'Yazýlým Projesi Yönetimi', 'Zorunlu', 100, 6, 1),
    ('YZM3122', 'Profesyonel Yazýlým Geliþtirme I', 'Zorunlu', 100, 6, 1),
    ('YZM4300', 'Teknik Seçmeli Ders', 'Seçmeli', 50, 7, 1),
    ('YZM4105', 'Sosyal Sorumluluk', 'Zorunlu', 100, 7, 1),
    ('YZM4109', 'Staj', 'Zorunlu', 100, 7, 1),
    ('YZM4119', 'Profesyonel Yazýlým Geliþtirme II', 'Zorunlu', 100, 7, 1),

    -- Mekatronik Mühendisliði
    ('MKT-FIZ1301', 'Fizik I', 'Zorunlu', 100, 1, 2),
    ('MKT-MAT1301', 'Matematik I', 'Zorunlu', 100, 1, 2),
    ('MKT-YDI1121', 'Yabancý Dil I', 'Zorunlu', 100, 1, 2),
    ('MKT-TDL1111', 'Türk Dili I', 'Zorunlu', 100, 1, 2),
    ('MKT-AIT1101', 'Atatürk Ýlkeleri ve Ýnkýlap Tarihi I', 'Zorunlu', 100, 1, 2),
    ('MKT-KIM1311', 'Kimya', 'Zorunlu', 100, 1, 2),
    ('MKT-YZM1107', 'Temel Bilgisayar Bilimleri', 'Zorunlu', 100, 1, 2),
    ('MKT1105', 'Mekatronik Mühendisliðine Giriþ', 'Zorunlu', 100, 1, 2),
    ('MKT-FIZ1302', 'Fizik II', 'Zorunlu', 100, 2, 2),
    ('MKT-MAT1302', 'Matematik II', 'Zorunlu', 100, 2, 2),
    ('MKT-YDI1122', 'Yabancý Dil II', 'Zorunlu', 100, 2, 2),
    ('MKT-TDL1112', 'Türk Dili II', 'Zorunlu', 100, 2, 2),
    ('MKT-AIT1102', 'Atatürk Ýlkeleri ve Ýnkýlap Tarihi II', 'Zorunlu', 100, 2, 2),
    ('MKT-YZM1304', 'Bilgisayar Programlama', 'Zorunlu', 100, 2, 2),
    ('MKT1110', 'Elektrik Devreleri-I', 'Zorunlu', 100, 2, 2),
    ('MKT1108', 'Bilgisayar Destekli Teknik Resim', 'Zorunlu', 100, 2, 2),
    ('MKT-MKS2201', 'Teknik Olmayan Seçmeli Dersler', 'Seçmeli', 50, 3, 2),
    ('MKT2101', 'Mühendislik Matematiði -I', 'Zorunlu', 100, 3, 2),
    ('MKT2103', 'Elektrik Devreleri -II', 'Zorunlu', 100, 3, 2),
    ('MKT2105', 'Statik', 'Zorunlu', 100, 3, 2),
    ('MKT2107', 'Dinamik', 'Zorunlu', 100, 3, 2),
    ('MKT2109', 'Malzeme Bilimi', 'Zorunlu', 100, 3, 2),
    ('MKT2121', 'Mantýk Devreleri', 'Zorunlu', 100, 3, 2),
    ('MKT-MKS2202', 'Teknik Olmayan Seçmeli Dersler', 'Seçmeli', 50, 4, 2),
    ('MKT2102', 'Mühendislik Matematiði -II', 'Zorunlu', 100, 4, 2),
    ('MKT2104', 'Elektronik Devreler', 'Zorunlu', 100, 4, 2),
    ('MKT2106', 'Mukavemet', 'Zorunlu', 100, 4, 2),
    ('MKT2108', 'Makine Teorisi', 'Zorunlu', 100, 4, 2),
    ('MKT2110', 'Makine Elemanlarý', 'Zorunlu', 100, 4, 2),
    ('MKT2122', 'Elektrik Makinalarý', 'Zorunlu', 100, 4, 2),
    ('MKT3101', 'Otomatik Kontrol -I', 'Zorunlu', 100, 5, 2),
    ('MKT3103', 'Hidrolik ve Pnömatik Sistemleri', 'Zorunlu', 100, 5, 2),
    ('MKT3105', 'Akýþkanlar Mekaniði', 'Zorunlu', 100, 5, 2),
    ('MKT3107', 'Bilgisayar Destekli Tasarým', 'Zorunlu', 100, 5, 2),
    ('MKT3109', 'Mikrokontrolörler', 'Zorunlu', 100, 5, 2),
    ('MKT3111', 'Güç Elektroniði ve Sürücü Sistemleri', 'Zorunlu', 100, 5, 2),
    ('MKT-CBU4403', 'Ýþ Saðlýðý ve Güvenliði I', 'Zorunlu', 100, 5, 2),
    ('MKT3102', 'Otomatik Kontrol -II', 'Zorunlu', 100, 6, 2),
    ('MKT3104', 'Algýlayýcýlar ve Aktüatörler', 'Zorunlu', 100, 6, 2),
    ('MKT3106', 'Termodinamik ve Isý Transferi', 'Zorunlu', 100, 6, 2),
    ('MKT3108', 'Bilgisayar Destekli Üretim', 'Zorunlu', 100, 6, 2),
    ('MKT3110', 'Endüstriyel Otomasyon Sistemleri', 'Zorunlu', 100, 6, 2),
    ('MKT3112', 'Robotik', 'Zorunlu', 100, 6, 2),
    ('MKT-CBU4404', 'Ýþ Saðlýðý ve Güvenliði II', 'Zorunlu', 100, 6, 2),
    ('MKT3120', 'Mekatronik Mühendisliði Projesi', 'Zorunlu', 100, 6, 2),
    ('MTS4201', 'Teknik Seçmeli Dersler', 'Seçmeli', 50, 7, 2),
    ('MKT4105', 'Sosyal Sorumluluk', 'Zorunlu', 100, 7, 2),
    ('MKT4111', 'Mekatronik Mühendisliði Tasarýmý', 'Zorunlu', 100, 7, 2),

    -- Makine Mühendisliði
    ('MAK-FIZ1301', 'Fizik I', 'Zorunlu', 100, 1, 3),
    ('MAK-MAT1301', 'Matematik I', 'Zorunlu', 100, 1, 3),
    ('MAK-YDI1121', 'Yabancý Dil I', 'Zorunlu', 100, 1, 3),
    ('MAK-TDL1111', 'Türk Dili I', 'Zorunlu', 100, 1, 3),
    ('MAK-AIT1101', 'Atatürk Ýlkeleri ve Ýnkýlap Tarihi I', 'Zorunlu', 100, 1, 3),
    ('MAK-KIM1301', 'Kimya', 'Zorunlu', 100, 1, 3),
    ('MAK1101', 'Teknik Resim', 'Zorunlu', 100, 1, 3),
    ('MAK1103', 'Makine Mühendisliðine Giriþ', 'Zorunlu', 100, 1, 3),
    ('MAK-SSD1218', 'Teknik Olmayan Seçmeli Dersler', 'Seçmeli', 50, 2, 3),
    ('MAK-FIZ1302', 'Fizik II', 'Zorunlu', 100, 2, 3),
    ('MAK-MAT1302', 'Matematik II', 'Zorunlu', 100, 2, 3),
    ('MAK-YDI1122', 'Yabancý Dil II', 'Zorunlu', 100, 2, 3),
    ('MAK-TDL1112', 'Türk Dili II', 'Zorunlu', 100, 2, 3),
    ('MAK1102', 'Bilgisayar Destekli Teknik Resim', 'Zorunlu', 100, 2, 3),
    ('MAK1304', 'Bilgisayar Bilimi ve Programlama', 'Zorunlu', 100, 2, 3),
    ('MAK1104', 'Statik', 'Zorunlu', 100, 2, 3),
    ('MAK2101', 'Mühendislik Matematiði-I', 'Zorunlu', 100, 3, 3),
    ('MAK2107', 'Akýþkanlar Mekaniði', 'Zorunlu', 100, 3, 3),
    ('MAK2117', 'Termodinamik -I', 'Zorunlu', 100, 3, 3),
    ('MAK2113', 'Dinamik', 'Zorunlu', 100, 3, 3),
    ('MAK2119', 'Mukavemet I', 'Zorunlu', 100, 3, 3),
    ('MAK2115', 'Malzeme Bilimi', 'Zorunlu', 100, 3, 3),
    ('MAK2121', 'Mühendislikte Deneysel Metotlar I', 'Zorunlu', 100, 3, 3),
    ('MAK-AIT1102', 'Atatürk Ýlkeleri ve Ýnkýlap Tarihi II', 'Zorunlu', 100, 4, 3),
    ('MAK-CBU4403', 'Ýþ Saðlýðý ve Güvenliði I', 'Zorunlu', 100, 4, 3),
    ('MAK2102', 'Mühendislik Matematiði-II', 'Zorunlu', 100, 4, 3),
    ('MAK2106', 'Mühendislik Malzemeleri', 'Zorunlu', 100, 4, 3),
    ('MAK2120', 'Termodinamik II', 'Zorunlu', 100, 4, 3),
    ('MAK2114', 'Mühendislikte Deneysel Metodlar II', 'Zorunlu', 100, 4, 3),
    ('MAK2116', 'Mukavemet II', 'Zorunlu', 100, 4, 3),
    ('MAK2118', 'Ýstatistik', 'Zorunlu', 100, 4, 3),
    ('MAK3201', 'Teknik Seçmeli Dersler', 'Seçmeli', 50, 5, 3),
    ('MAK-CBU4404', 'Ýþ Saðlýðý ve Güvenliði II', 'Zorunlu', 100, 5, 3),
    ('MAK3101', 'Makine Elemanlarý I', 'Zorunlu', 100, 5, 3),
    ('MAK3107', 'Sistem Analizi ve Kontrol', 'Zorunlu', 100, 5, 3),
    ('MAK3109', 'Bilgisayar Destekli Mühendislik', 'Zorunlu', 100, 5, 3),
    ('MAK3111', 'Mekanizma Tekniði', 'Zorunlu', 100, 5, 3),
    ('MAK3113', 'Üretim Yöntemleri I', 'Zorunlu', 100, 5, 3),
    ('MAK3115', 'Kariyer Planlama', 'Zorunlu', 100, 5, 3),
    ('MAK3102', 'Makine Elemanlarý II', 'Zorunlu', 100, 6, 3),
    ('MAK3108', 'Elektronik ve Otomasyon Bilgisi', 'Zorunlu', 100, 6, 3),
    ('MAK3116', 'Makine Dinamiði', 'Zorunlu', 100, 6, 3),
    ('MAK3118', 'Mühendislik Ekonomisi ve Yönetimi', 'Zorunlu', 100, 6, 3),
    ('MAK3114', 'Makine Mühendisliði Tasarýmý', 'Zorunlu', 100, 6, 3),
    ('MAK3122', 'Üretim Yöntemleri II', 'Zorunlu', 100, 6, 3),
    ('MAK3124', 'Isý Transferi', 'Zorunlu', 100, 6, 3),
    ('MAK4201', 'Teknik Seçmeli Dersler', 'Seçmeli', 50, 7, 3),
    ('MAK4105', 'Sosyal Sorumluluk', 'Zorunlu', 100, 7, 3),
    ('MAK4115', 'Makine Mühendisliði Projesi', 'Zorunlu', 100, 7, 3),

    -- Enerji Sistemleri Mühendisliði
    ('ESM-FIZ1301', 'Fizik I', 'Zorunlu', 100, 1, 4),
    ('ESM-MAT1301', 'Matematik I', 'Zorunlu', 100, 1, 4),
    ('ESM-TDL1111', 'Türk Dili I', 'Zorunlu', 100, 1, 4),
    ('ESM-AIT1101', 'Atatürk Ýlkeleri ve Ýnkýlap Tarihi I', 'Zorunlu', 100, 1, 4),
    ('ESM-KIM1311', 'Kimya', 'Zorunlu', 100, 1, 4),
    ('ESM-YDI1123', 'Yabancý Dil I', 'Zorunlu', 100, 1, 4),
    ('ESM1105', 'Enerji Sistemleri Mühendisliðine Giriþ', 'Zorunlu', 100, 1, 4),
    ('ESM1107', 'Temel Bilgisayar Bilimleri', 'Zorunlu', 100, 1, 4),
    ('ESM1109', 'Kariyer Planlama', 'Zorunlu', 100, 1, 4),
    ('ESM-FIZ1302', 'Fizik II', 'Zorunlu', 100, 2, 4),
    ('ESM-MAT1302', 'Matematik II', 'Zorunlu', 100, 2, 4),
    ('ESM-TDL1112', 'Türk Dili II', 'Zorunlu', 100, 2, 4),
    ('ESM-AIT1102', 'Atatürk Ýlkeleri ve Ýnkýlap Tarihi II', 'Zorunlu', 100, 2, 4),
    ('ESM1102', 'Bilgisayar Destekli Teknik Resim', 'Zorunlu', 100, 2, 4),
    ('ESM1104', 'Sosyal Sorumluluk Projesi', 'Zorunlu', 100, 2, 4),
    ('ESM-YDI1124', 'Yabancý Dil II', 'Zorunlu', 100, 2, 4),
    ('ESM1108', 'Algoritma ve Programlamanýn Temelleri', 'Zorunlu', 100, 2, 4),
    ('ESM1106', 'Elektrik Devreleri I', 'Zorunlu', 100, 2, 4),
    ('ESM2201', 'Teknik Seçmeli Ders I', 'Seçmeli', 50, 3, 4),
    ('ESM2105', 'Malzeme Bilimi', 'Zorunlu', 100, 3, 4),
    ('ESM2107', 'Statik', 'Zorunlu', 100, 3, 4),
    ('ESM2115', 'Mühendislik Matematiði', 'Zorunlu', 100, 3, 4),
    ('ESM2117', 'Akýþkanlar Mekaniði I', 'Zorunlu', 100, 3, 4),
    ('ESM2119', 'Termodinamik I', 'Zorunlu', 100, 3, 4),
    ('ESM2121', 'Elektrik Devreleri II', 'Zorunlu', 100, 3, 4),
    ('ESM2123', 'Temel Elektronik', 'Zorunlu', 100, 3, 4),
    ('ESM-ADS2202', 'Alan Dýþý Seçmeli Ders', 'Seçmeli', 50, 4, 4),
    ('ESM2202', 'Teknik Seçmeli Ders II', 'Seçmeli', 50, 4, 4),
    ('ESM2114', 'Dinamik', 'Zorunlu', 100, 4, 4),
    ('ESM2116', 'Endüstriyel Ölçme ve Kontrol', 'Zorunlu', 100, 4, 4),
    ('ESM2118', 'Akýþkanlar Mekaniði II', 'Zorunlu', 100, 4, 4),
    ('ESM2120', 'Termodinamik II', 'Zorunlu', 100, 4, 4),
    ('ESM2122', 'Elektrik Makineleri', 'Zorunlu', 100, 4, 4),
    ('ESM3207', 'Teknik Seçmeli Dersler III', 'Seçmeli', 50, 5, 4),
    ('ESM-ADS3201', 'Alan Dýþý Seçmeli Dersler', 'Seçmeli', 50, 5, 4),
    ('ESM-CBU4403', 'Ýþ Saðlýðý ve Güvenliði I', 'Zorunlu', 100, 5, 4),
    ('ESM3109', 'Enerji Mühendisliði Laboratuvarý I', 'Zorunlu', 100, 5, 4),
    ('ESM3111', 'Güç Elektroniði', 'Zorunlu', 100, 5, 4),
    ('ESM3113', 'Isý Transferi I', 'Zorunlu', 100, 5, 4),
    ('ESM3115', 'Enerji Ýletimi ve Daðýtýmý', 'Zorunlu', 100, 5, 4),
    ('ESM3220', 'Teknik Seçmeli Ders IV', 'Seçmeli', 50, 6, 4),
    ('ESM-CBU4404', 'Ýþ Saðlýðý ve Güvenliði II', 'Zorunlu', 100, 6, 4),
    ('ESM3112', 'Mühendislik Tasarýmý', 'Zorunlu', 100, 6, 4),
    ('ESM3118', 'Enerji Mühendisliði Laboratuvarý II', 'Zorunlu', 100, 6, 4),
    ('ESM3114', 'Isý Transferi II', 'Zorunlu', 100, 6, 4),
    ('ESM3116', 'Mühendislikte Bilgisayar Uygulamalarý', 'Zorunlu', 100, 6, 4),
    ('ESM4237', 'Teknik Seçmeli Ders V', 'Seçmeli', 50, 7, 4),
    ('ESM4273', 'Teknik Olmayan Ders I', 'Seçmeli', 50, 7, 4),
    ('ESM4115', 'Mühendislik Projesi', 'Zorunlu', 100, 7, 4),
    ('ESM4113', 'Enerji Verimliliði ve Yönetimi', 'Zorunlu', 100, 7, 4),

    -- Elektrik Mühendisliði
    ('ELK-FIZ1301', 'Fizik I', 'Zorunlu', 100, 1, 5),
    ('ELK-MAT1301', 'Matematik I', 'Zorunlu', 100, 1, 5),
    ('ELK-TDL1111', 'Türk Dili I', 'Zorunlu', 100, 1, 5),
    ('ELK-AIT1101', 'Atatürk Ýlkeleri ve Ýnkýlap Tarihi I', 'Zorunlu', 100, 1, 5),
    ('ELK-YDI1131', 'Yabancý Dil', 'Zorunlu', 100, 1, 5),
    ('ELK1101', 'Lineer Cebir', 'Zorunlu', 100, 1, 5),
    ('ELK1103', 'Kariyer Planlama', 'Zorunlu', 100, 1, 5),
    ('ELK1105', 'Elektrik Mühendisliðine Giriþ', 'Zorunlu', 100, 1, 5),
    ('ELK1107', 'Bilgisayar Destekli Çizim', 'Zorunlu', 100, 1, 5),
    ('ELK-FIZ1302', 'Fizik II', 'Zorunlu', 100, 2, 5),
    ('ELK-MAT1302', 'Matematik II', 'Zorunlu', 100, 2, 5),
    ('ELK-TDL1112', 'Türk Dili II', 'Zorunlu', 100, 2, 5),
    ('ELK-AIT1102', 'Atatürk Ýlkeleri ve Ýnkýlap Tarihi II', 'Zorunlu', 100, 2, 5),
    ('ELK1102', 'Elektrik Devreleri I', 'Zorunlu', 100, 2, 5),
    ('ELK1104', 'Bilgisayar Programlama', 'Zorunlu', 100, 2, 5),
    ('ELK1106', 'Elektrik Ölçme Teknikleri', 'Zorunlu', 100, 2, 5),
    ('ELK-ADS2201', 'Alan Dýþý Seçmeli Dersler', 'Seçmeli', 50, 3, 5),
    ('ELK2201', 'Teknik Seçmeli Ders I', 'Seçmeli', 50, 3, 5),
    ('ELK-CBU4403', 'Ýþ Saðlýðý ve Güvenliði I', 'Zorunlu', 100, 3, 5),
    ('ELK2101', 'Elektrik Devreleri II', 'Zorunlu', 100, 3, 5),
    ('ELK2103', 'Elektromanyetik Alan Teorisi', 'Zorunlu', 100, 3, 5),
    ('ELK2105', 'Diferansiyel Denklemler', 'Zorunlu', 100, 3, 5),
    ('ELK2107', 'Elektronik', 'Zorunlu', 100, 3, 5),
    ('ELK-ADS2202', 'Alan Dýþý Seçmeli Ders', 'Seçmeli', 50, 4, 5),
    ('ELK2202', 'Teknik Seçmeli Ders II', 'Seçmeli', 50, 4, 5),
    ('ELK-CBU4404', 'Ýþ Saðlýðý ve Güvenliði II', 'Zorunlu', 100, 4, 5),
    ('ELK2102', 'Sayýsal Elektronik', 'Zorunlu', 100, 4, 5),
    ('ELK2104', 'Aydýnlatma Tekniði ve Tesis Projeleri', 'Zorunlu', 100, 4, 5),
    ('ELK2106', 'Enerji Üretimi', 'Zorunlu', 100, 4, 5),
    ('ELK2108', 'Kumanda Teknikleri', 'Zorunlu', 100, 4, 5),
    ('ELK3201', 'Teknik Seçmeli Ders III', 'Seçmeli', 50, 5, 5),
    ('ELK3101', 'Güç Elektroniði', 'Zorunlu', 100, 5, 5),
    ('ELK3103', 'Elektrik Makineleri I', 'Zorunlu', 100, 5, 5),
    ('ELK3105', 'Yüksek Gerilim Tekniði', 'Zorunlu', 100, 5, 5),
    ('ELK3107', 'Enerji Ýletim Sistemleri', 'Zorunlu', 100, 5, 5),
    ('ELK3109', 'Sinyaller ve Sistemler', 'Zorunlu', 100, 5, 5),
    ('ELK3202', 'Teknik Seçmeli Ders IV', 'Seçmeli', 50, 6, 5),
    ('ELK3102', 'Otomatik Kontrol', 'Zorunlu', 100, 6, 5),
    ('ELK3104', 'Elektrik Makineleri II', 'Zorunlu', 100, 6, 5),
    ('ELK3106', 'Enerji Daðýtýmý', 'Zorunlu', 100, 6, 5),
    ('ELK3108', 'Elektrik Mühendisliði Projesi I', 'Zorunlu', 100, 6, 5),
    ('ELK4201', 'Teknik Seçmeli Ders V', 'Seçmeli', 50, 7, 5),
    ('ELK4101', 'Elektrik Mühendisliði Projesi II', 'Zorunlu', 100, 7, 5),
    ('ELK4105', 'Sosyal Sorumluluk', 'Zorunlu', 100, 7, 5);

-- Derslikler Verileri
INSERT INTO Derslikler (Ad, Kapasite, Tip, Aktif, Kat) 
VALUES 
    -- Küçük Sýnýflar (Kapasite: 36)
    ('205', 36, 'Küçük', 1, 2),  
    ('206', 36, 'Küçük', 1, 2),  
    ('207', 36, 'Küçük', 1, 2),  
    ('208', 36, 'Küçük', 1, 2),  
    ('305', 36, 'Küçük', 1, 3),  
    ('306', 36, 'Küçük', 1, 3),  
    ('307', 36, 'Küçük', 1, 3),  
    ('308', 36, 'Küçük', 1, 3),  

    -- Orta Büyüklükteki Sýnýflar
    ('309', 40, 'Orta', 1, 3),  
    ('311', 50, 'Orta', 1, 3),

    -- Büyük Sýnýflar (Kapasite: 60)
    ('209', 60, 'Büyük', 1, 2),
    ('210', 60, 'Büyük', 1, 2),
    ('310', 60, 'Büyük', 1, 3),
    ('409', 60, 'Büyük', 1, 4),
    ('410', 60, 'Büyük', 1, 4);

--Personel (Gözetmen Havuzu) 
 INSERT INTO Personel (Unvan, Ad, Soyad, BolumID) 
VALUES 
    -- Yazýlým Mühendisliði (BolumID: 1)
    ('Arþ. Gör.', 'Süleyman', 'ÇETÝNER', 1),
    ('Arþ. Gör.', 'Elif Nur', 'AYGÜN', 1),
    ('Arþ. Gör.', 'Tuðba', 'ÇELÝKTEN', 1),
    ('Arþ. Gör.', 'Güney', 'KAYA', 1),

    -- Mekatronik Mühendisliði (BolumID: 2)
    ('Arþ. Gör. Dr.', 'Seda', 'VATAN CAN', 2),
    ('Arþ. Gör.', 'Kübra', 'TURAL', 2),

    -- Makine Mühendisliði (BolumID: 3)
    ('Arþ. Gör.', 'Ömer', 'ÝLHAN', 3),
    ('Arþ. Gör.', 'Büþranur', 'KESER', 3),

    -- Enerji Sistemleri Mühendisliði (BolumID: 4)
    ('Arþ. Gör. Dr.', 'Elif Merve', 'BAHAR', 4),
    ('Arþ. Gör.', 'Menal', 'ÝLHAN', 4),
    ('Arþ. Gör. Dr.', 'Mert', 'ÖKTEN', 4),

    -- Elektrik Mühendisliði (BolumID: 5)
    ('Dr. Öðr. Üyesi', 'Yýlmaz Seryar', 'ARIKUÞU', 5),
    ('Dr. Öðr. Üyesi', 'Bayram Melih', 'YILMAZ', 5);           

--OTURUMLAR (Sýnav Slotlarý)
INSERT INTO Oturumlar (Tanim, BaslangicSaat, BitisSaat) VALUES 
('Sabah-1', '09:00:00', '10:00:00'),
('Sabah-2', '10:30:00', '11:30:00'),
('öðle', '12:00:00', '13:00:00'),
('Öðleden Sonra-1', '13:45:00', '14:45:00'),
('Öðleden Sonra-2', '15:15:00', '16:30:00');

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

-- Dönem Baþlangýç ve Bitiþ Tarihlerini Belirleme
INSERT INTO Donem_Ayarlari (AyarID, DonemBaslangicTarihi, DonemBitisTarihi)
VALUES (1, '2026-02-09', '2026-06-26');
GO

-- ==========================================================================================
-- SINAVLARIN SAKLI YORDAMLAR (SP) ÝLE KAYDEDÝLMESÝ
-- ==========================================================================================

-- 1 HAZÝRAN PAZARTESÝ
EXEC SinavEkle @DersID = 1,  @Tarih = '2026-06-01', @OturumID = 1;
EXEC SinavEkle @DersID = 16, @Tarih = '2026-06-01', @OturumID = 1;
EXEC SinavEkle @DersID = 11, @Tarih = '2026-06-01', @OturumID = 2;
EXEC SinavEkle @DersID = 21, @Tarih = '2026-06-01', @OturumID = 2;
EXEC SinavEkle @DersID = 6,  @Tarih = '2026-06-01', @OturumID = 3;

-- 2 HAZÝRAN SALI
EXEC SinavEkle @DersID = 2,  @Tarih = '2026-06-02', @OturumID = 1;
EXEC SinavEkle @DersID = 22, @Tarih = '2026-06-02', @OturumID = 1;
EXEC SinavEkle @DersID = 12, @Tarih = '2026-06-02', @OturumID = 2;
EXEC SinavEkle @DersID = 17, @Tarih = '2026-06-02', @OturumID = 2;
EXEC SinavEkle @DersID = 7,  @Tarih = '2026-06-02', @OturumID = 3;

-- 3 HAZÝRAN ÇARÞAMBA
EXEC SinavEkle @DersID = 3,  @Tarih = '2026-06-03', @OturumID = 1;
EXEC SinavEkle @DersID = 23, @Tarih = '2026-06-03', @OturumID = 1;
EXEC SinavEkle @DersID = 13, @Tarih = '2026-06-03', @OturumID = 2;
EXEC SinavEkle @DersID = 18, @Tarih = '2026-06-03', @OturumID = 2;
EXEC SinavEkle @DersID = 8,  @Tarih = '2026-06-03', @OturumID = 3;

-- 4 HAZÝRAN PERÞEMBE
EXEC SinavEkle @DersID = 5,  @Tarih = '2026-06-04', @OturumID = 1;
EXEC SinavEkle @DersID = 24, @Tarih = '2026-06-04', @OturumID = 1;
EXEC SinavEkle @DersID = 14, @Tarih = '2026-06-04', @OturumID = 2;
EXEC SinavEkle @DersID = 19, @Tarih = '2026-06-04', @OturumID = 2;
EXEC SinavEkle @DersID = 9,  @Tarih = '2026-06-04', @OturumID = 3;

-- 5 HAZÝRAN CUMA
EXEC SinavEkle @DersID = 4,  @Tarih = '2026-06-05', @OturumID = 1;
EXEC SinavEkle @DersID = 25, @Tarih = '2026-06-05', @OturumID = 1;
EXEC SinavEkle @DersID = 15, @Tarih = '2026-06-05', @OturumID = 2;
EXEC SinavEkle @DersID = 20, @Tarih = '2026-06-05', @OturumID = 2;
EXEC SinavEkle @DersID = 10, @Tarih = '2026-06-05', @OturumID = 3;
-- ==========================================================================================
-- SALONLARIN SAKLI YORDAMLAR (SP) ÝLE KAYDEDÝLMESÝ
-- ==========================================================================================

-- 1 HAZÝRAN PAZARTESÝ
EXEC SalonAta 1, 1; 
EXEC SalonAta 1, 4;

EXEC SalonAta 2, 2; 
EXEC SalonAta 2, 3;

EXEC SalonAta 3, 8; 
EXEC SalonAta 3, 7; 
EXEC SalonAta 3, 9;

EXEC SalonAta 4, 5; 
EXEC SalonAta 4, 6; 
EXEC SalonAta 5, 7; 
EXEC SalonAta 5, 8; 
EXEC SalonAta 5, 10;

-- 2 HAZÝRAN SALI
EXEC SalonAta 6, 1; 
EXEC SalonAta 6, 3; 

EXEC SalonAta 7, 4; 
EXEC SalonAta 7, 5; 
EXEC SalonAta 7, 10;

EXEC SalonAta 8, 8; 
EXEC SalonAta 8, 7; 
EXEC SalonAta 8, 9; 

EXEC SalonAta 9, 3; 
EXEC SalonAta 9, 2; 

EXEC SalonAta 10, 6;
EXEC SalonAta 10, 5; 

-- 3 HAZÝRAN ÇARÞAMBA
EXEC SalonAta 11, 7;
EXEC SalonAta 11, 8; 
EXEC SalonAta 12, 9; 
EXEC SalonAta 13, 1; 
EXEC SalonAta 14, 10;
EXEC SalonAta 14, 9; 
EXEC SalonAta 15, 4; 
EXEC SalonAta 15, 5; 

-- 4 HAZÝRAN PERÞEMBE
EXEC SalonAta 16, 1; 
EXEC SalonAta 16, 2; 
EXEC SalonAta 17, 8;
EXEC SalonAta 17, 7; 
EXEC SalonAta 18, 6; 
EXEC SalonAta 18, 5;
EXEC SalonAta 19, 3;
EXEC SalonAta 19, 9;
EXEC SalonAta 19, 1; 
EXEC SalonAta 20, 10;
EXEC SalonAta 20, 6; 

-- 5 HAZÝRAN CUMA
EXEC SalonAta 21, 5; 
EXEC SalonAta 22, 6; 
EXEC SalonAta 23, 1; 
EXEC SalonAta 23, 2; 
EXEC SalonAta 24, 8; 
EXEC SalonAta 24, 7; 
EXEC SalonAta 25, 4;
EXEC SalonAta 25, 5;
GO

-- ==========================================================================================
-- GÖZETMENLERÝN SAKLI YORDAMLAR (SP) ÝLE ATANMASI
-- ==========================================================================================

-- 1 HAZÝRAN PAZARTESÝ
EXEC GozetmenAta 1, 2;
EXEC GozetmenAta 2, 9;
EXEC GozetmenAta 3, 7;
EXEC GozetmenAta 4, 8;
EXEC GozetmenAta 5, 5;
EXEC GozetmenAta 6, 4;
EXEC GozetmenAta 7, 10;
EXEC GozetmenAta 8, 9;
EXEC GozetmenAta 9, 3;
EXEC GozetmenAta 10, 4;
EXEC GozetmenAta 11, 7;
EXEC GozetmenAta 12, 5;

-- 2 HAZÝRAN SALI
EXEC GozetmenAta 13, 1;
EXEC GozetmenAta 14, 2;
EXEC GozetmenAta 15, 9;
EXEC GozetmenAta 16, 5;
EXEC GozetmenAta 17, 6;
EXEC GozetmenAta 18, 5;
EXEC GozetmenAta 19, 6;
EXEC GozetmenAta 20, 1;
EXEC GozetmenAta 21, 7;
EXEC GozetmenAta 22, 8;
EXEC GozetmenAta 23, 4;
EXEC GozetmenAta 24, 2;

-- 3 HAZÝRAN ÇARÞAMBA
EXEC GozetmenAta 25, 1;
EXEC GozetmenAta 26, 3;
EXEC GozetmenAta 27, 9;
EXEC GozetmenAta 28, 5;
EXEC GozetmenAta 29, 7;
EXEC GozetmenAta 30, 8;
EXEC GozetmenAta 31, 3;
EXEC GozetmenAta 32, 10;

-- 4 HAZÝRAN PERÞEMBE
EXEC GozetmenAta 33, 1;
EXEC GozetmenAta 34, 2;
EXEC GozetmenAta 35, 9;
EXEC GozetmenAta 36, 10;
EXEC GozetmenAta 37, 5;
EXEC GozetmenAta 38, 6;
EXEC GozetmenAta 39, 7;
EXEC GozetmenAta 40, 3;
EXEC GozetmenAta 41, 4;
EXEC GozetmenAta 42, 4;
EXEC GozetmenAta 43, 2;

-- 5 HAZÝRAN CUMA
EXEC GozetmenAta 44, 1;
EXEC GozetmenAta 45, 10;
EXEC GozetmenAta 46, 5;
EXEC GozetmenAta 47, 6;
EXEC GozetmenAta 48, 7;
EXEC GozetmenAta 49, 8;
EXEC GozetmenAta 50, 3;
EXEC GozetmenAta 51, 4;