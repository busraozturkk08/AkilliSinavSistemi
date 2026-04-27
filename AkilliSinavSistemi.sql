-- ==========================================================================================
-- AKILLI SINAV SALONU VE PERSONEL HAVUZU YÖNETÝM SÝSTEMÝ (TAM DOSYA)
-- ==========================================================================================

-- 1. Veritabanýný Oluþtur
CREATE DATABASE AkilliSinavSistemi;
GO
USE AkilliSinavSistemi;
GO

-- ==========================================================================================
-- TABLOLARIN OLUÞTURULMASI
-- ==========================================================================================

-- 2. Bölümler
CREATE TABLE Bolumler (
    BolumID INT PRIMARY KEY IDENTITY(1,1),
    BolumAd NVARCHAR(100) NOT NULL
);

-- 3. Dersler
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

-- 4. Derslikler
CREATE TABLE Derslikler (
    DerslikID INT PRIMARY KEY IDENTITY(1,1),
    Ad NVARCHAR(50),
    Kapasite INT CHECK (Kapasite > 0),
    Tip NVARCHAR(50),
    Aktif BIT DEFAULT 1,
    CONSTRAINT CK_DerslikTip CHECK (Tip IN ('Amfi', 'Sinif', 'Lab'))
);

-- 5. Personel
CREATE TABLE Personel (
    PersonelID INT PRIMARY KEY IDENTITY(1,1),
    Unvan NVARCHAR(50),
    Ad NVARCHAR(50),
    Soyad NVARCHAR(50),
    BolumID INT,
    FOREIGN KEY (BolumID) REFERENCES Bolumler(BolumID)
);

-- 6. Personel Durum (Mazeret)
CREATE TABLE Personel_Durum (
    DurumID INT PRIMARY KEY IDENTITY(1,1),
    PersonelID INT,
    Tarih DATE,
    MazeretTuru NVARCHAR(100),
    Uygun BIT,
    FOREIGN KEY (PersonelID) REFERENCES Personel(PersonelID)
);

-- 7. Oturumlar
CREATE TABLE Oturumlar (
    OturumID INT PRIMARY KEY IDENTITY(1,1),
    Tanim NVARCHAR(50),
    BaslangicSaat TIME,
    BitisSaat TIME
);

-- 8. Sýnavlar
CREATE TABLE Sinavlar (
    SinavID INT PRIMARY KEY IDENTITY(1,1),
    DersID INT,
    Tarih DATE,
    OturumID INT,
    FOREIGN KEY (DersID) REFERENCES Dersler(DersID),
    FOREIGN KEY (OturumID) REFERENCES Oturumlar(OturumID)
);

-- 9. Sýnav - Salon Ýliþkisi
CREATE TABLE Sinav_Salonlari (
    AtamaID INT PRIMARY KEY IDENTITY(1,1),
    SinavID INT,
    DerslikID INT,
    FOREIGN KEY (SinavID) REFERENCES Sinavlar(SinavID),
    FOREIGN KEY (DerslikID) REFERENCES Derslikler(DerslikID)
);

-- 10. Gözetmen Atamalarý
CREATE TABLE Gozetmen_Atamalari (
    AtamaID INT PRIMARY KEY IDENTITY(1,1),
    SinavSalonID INT,
    PersonelID INT,
    FOREIGN KEY (SinavSalonID) REFERENCES Sinav_Salonlari(AtamaID),
    FOREIGN KEY (PersonelID) REFERENCES Personel(PersonelID)
);
GO

-- ==========================================================================================
-- VIEWS (GÖRÜNÜMLER)
-- ==========================================================================================

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

CREATE VIEW vw_GozetmenGorevListesi AS
SELECT 
    p.Unvan,
    p.Ad + ' ' + p.Soyad AS PersonelAdSoyad,
    d.Ad AS DersAdi,
    s.Tarih,
    CAST(o.BaslangicSaat AS VARCHAR(5)) + ' - ' + CAST(o.BitisSaat AS VARCHAR(5)) AS ZamanAraligi,
    dl.Ad AS SinavSalonu
FROM Gozetmen_Atamalari ga
INNER JOIN Personel p ON ga.PersonelID = p.PersonelID
INNER JOIN Sinav_Salonlari ss ON ga.SinavSalonID = ss.AtamaID
INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
INNER JOIN Dersler d ON s.DersID = d.DersID
INNER JOIN Oturumlar o ON s.OturumID = o.OturumID
INNER JOIN Derslikler dl ON ss.DerslikID = dl.DerslikID;
GO

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

-- 2. UDF: Gözetmen Görev Sayýsý
CREATE FUNCTION fn_GozetmenGorevSayisi
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

-- 3. UDF: Sýnýf Kapasitesi Yeterli Mi?
CREATE FUNCTION fn_DerslikKapasiteYeterliMi
(
    @DerslikID INT,
    @DersID INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Kapasite INT;
    DECLARE @OgrenciSayisi INT;

    SELECT @Kapasite = Kapasite FROM Derslikler WHERE DerslikID = @DerslikID;
    SELECT @OgrenciSayisi = OgrenciSayisi FROM Dersler WHERE DersID = @DersID;

    IF @Kapasite >= @OgrenciSayisi
        RETURN 1;

    RETURN 0; 
END;
GO

-- ==========================================================================================
-- STORED PROCEDURES (SAKLI YORDAMLAR - AKILLI ATAMA)
-- ==========================================================================================

-- 1. SP: Sýnav Ekleme (Yarýyýl Çakýþmasý Korumalý)
CREATE PROCEDURE SinavEkle
    @DersID INT,
    @Tarih DATE,
    @OturumID INT
AS
BEGIN
    DECLARE @Yariyil INT;
    DECLARE @CakismaSayisi INT;

    SELECT @Yariyil = Yariyil FROM Dersler WHERE DersID = @DersID;

    SELECT @CakismaSayisi = COUNT(*)
    FROM Sinavlar s
    INNER JOIN Dersler d ON s.DersID = d.DersID
    WHERE d.Yariyil = @Yariyil AND s.Tarih = @Tarih AND s.OturumID = @OturumID;

    IF @CakismaSayisi > 0
    BEGIN
        THROW 50003, 'KURAL HATASI: Ayný yarýyýla ait iki sýnav ayný oturuma konulamaz!', 1;
    END
    ELSE
    BEGIN
        INSERT INTO Sinavlar (DersID, Tarih, OturumID)
        VALUES (@DersID, @Tarih, @OturumID);
    END
END;
GO

-- 2. SP: Salon Atama (Kapasite Korumalý)
CREATE PROCEDURE SalonAta
    @SinavID INT,
    @DerslikID INT
AS
BEGIN
    DECLARE @DersID INT;
    SELECT @DersID = DersID FROM Sinavlar WHERE SinavID = @SinavID;

    IF dbo.fn_DerslikKapasiteYeterliMi(@DerslikID, @DersID) = 1
    BEGIN
        INSERT INTO Sinav_Salonlari (SinavID, DerslikID)
        VALUES (@SinavID, @DerslikID);
    END
    ELSE
    BEGIN
        THROW 50001, 'HATA: Bu sýnýfýn kapasitesi, dersin öðrenci sayýsý için yetersiz!', 1;
    END
END;
GO

-- 3. SP: Gözetmen Atama (3 Oturum Limiti ve Müsaitlik Korumalý)
CREATE PROCEDURE GozetmenAta
    @SinavSalonID INT,
    @PersonelID INT
AS
BEGIN
    DECLARE @Tarih DATE;
    DECLARE @OturumID INT;
    DECLARE @GunlukGorevSayisi INT;

    SELECT @Tarih = s.Tarih, @OturumID = s.OturumID
    FROM Sinav_Salonlari ss
    INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
    WHERE ss.AtamaID = @SinavSalonID;

    SELECT @GunlukGorevSayisi = COUNT(*)
    FROM Gozetmen_Atamalari ga
    INNER JOIN Sinav_Salonlari ss ON ga.SinavSalonID = ss.AtamaID
    INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
    WHERE ga.PersonelID = @PersonelID AND s.Tarih = @Tarih;

    IF @GunlukGorevSayisi >= 3
    BEGIN
        THROW 50004, 'KURAL HATASI: Bir gözetmen ayný gün en fazla 3 oturumda görev alabilir!', 1;
    END
    ELSE
    BEGIN
        IF dbo.fn_PersonelMusaitMi(@PersonelID, @Tarih, @OturumID) = 1
        BEGIN
            INSERT INTO Gozetmen_Atamalari (SinavSalonID, PersonelID)
            VALUES (@SinavSalonID, @PersonelID);
        END
        ELSE
        BEGIN
            THROW 50002, 'HATA: Personel bu tarihte müsait deðil (Mazeretli veya Çakýþma)!', 1;
        END
    END
END;
GO

-- ==========================================================================================
-- TRIGGERS (TETÝKLEYÝCÝLER - GÜVENLÝK DUVARI)
-- ==========================================================================================

-- 1. TRIGGER: Salon Çakýþma Güvenliði
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

-- 2. TRIGGER: Gözetmen Çakýþma Güvenliði
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