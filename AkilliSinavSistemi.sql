-- 1. Veritabanýný Oluþtur
CREATE DATABASE AkilliSinavSistemi;
GO
USE AkilliSinavSistemi;

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
----------------------------------------------------------------------------------------------------------
-- Bölümler
INSERT INTO Bolumler (BolumAd) VALUES ('Yazýlým'), ('Elektrik');

-- Dersler
INSERT INTO Dersler (DersKodu, Ad, OgrenciSayisi, Yariyil, BolumID)
VALUES 
('YZM101', 'Programlama', 80, 1, 1),
('YZM202', 'Veritabaný', 120, 2, 1);

-- Derslikler
INSERT INTO Derslikler (Ad, Kapasite, Tip)
VALUES 
('Amfi-1', 100, 'Amfi'),
('Sinif-1', 50, 'Sinif');

-- Personel
INSERT INTO Personel (Ad, Soyad, BolumID)
VALUES 
('Ahmet', 'Yýlmaz', 1),
('Ayþe', 'Demir', 2);

-- Oturumlar
INSERT INTO Oturumlar (Tanim, BaslangicSaat, BitisSaat)
VALUES 
('Sabah-1', '09:00', '10:30'),
('Ogle-1', '11:00', '12:30');

-- Sýnav
INSERT INTO Sinavlar (DersID, Tarih, OturumID)
VALUES (1, '2026-06-10', 1);

----------------------------------------------------------------------------------------------------------

--1.SP: Sýnav Ekleme
GO
CREATE PROCEDURE SinavEkle
    @DersID INT,
    @Tarih DATE,
    @OturumID INT
AS
BEGIN
    INSERT INTO Sinavlar (DersID, Tarih, OturumID)
    VALUES (@DersID, @Tarih, @OturumID)
END

--2.SP: Salon Atama
GO
CREATE PROCEDURE SalonAta
    @SinavID INT,
    @DerslikID INT
AS
BEGIN
    INSERT INTO Sinav_Salonlari (SinavID, DerslikID)
    VALUES (@SinavID, @DerslikID)
END

--3.SP: Gözetmen Atama
GO
CREATE PROCEDURE GozetmenAta
    @SinavSalonID INT,
    @PersonelID INT
AS
BEGIN
    INSERT INTO Gozetmen_Atamalari (SinavSalonID, PersonelID)
    VALUES (@SinavSalonID, @PersonelID)
END

---------------------------------------------------------------------------------------------------------
INSERT INTO Bolumler (BolumAd) VALUES ('Enerji sistemleri')
SELECT * FROM Bolumler

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

CREATE VIEW vw_PersonelMesguliyetDetay AS
SELECT 
    p.Ad + ' ' + p.Soyad AS Personel,
    'Mazeret' AS Tur,
    pd.Tarih,
    NULL AS Saat,
    pd.MazeretTuru AS Aciklama
FROM Personel_Durum pd
INNER JOIN Personel p ON pd.PersonelID = p.PersonelID
WHERE pd.Uygun = 0

UNION ALL

SELECT 
    p.Ad + ' ' + p.Soyad AS Personel,
    'Sýnav Görevi' AS Tur,
    s.Tarih,
    o.BaslangicSaat AS Saat,
    d.Ad + ' Sýnavý' AS Aciklama
FROM Gozetmen_Atamalari ga
INNER JOIN Personel p ON ga.PersonelID = p.PersonelID
INNER JOIN Sinav_Salonlari ss ON ga.SinavSalonID = ss.AtamaID
INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
INNER JOIN Dersler d ON s.DersID = d.DersID
INNER JOIN Oturumlar o ON s.OturumID = o.OturumID;

-- 1. UDF: Personel Müsaitlik Kontrolü (O gün mazereti veya ayný saatte sýnavý var mý?)
GO
CREATE FUNCTION fn_PersonelMusaitMi
(
    @PersonelID INT,
    @Tarih DATE,
    @OturumID INT
)
RETURNS BIT -- 1: Müsait, 0: Müsait Deðil
AS
BEGIN
    DECLARE @MesgulSayisi INT = 0;

    -- A) Mazeret Kontrolü (Hasta/Ýzinli mi?)
    SELECT @MesgulSayisi = @MesgulSayisi + COUNT(*)
    FROM Personel_Durum
    WHERE PersonelID = @PersonelID AND Tarih = @Tarih AND Uygun = 0;

    -- B) Çakýþma Kontrolü (O gün ve o oturum saatinde baþka sýnýfta görevli mi?)
    SELECT @MesgulSayisi = @MesgulSayisi + COUNT(*)
    FROM Gozetmen_Atamalari ga
    INNER JOIN Sinav_Salonlari ss ON ga.SinavSalonID = ss.AtamaID
    INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
    WHERE ga.PersonelID = @PersonelID AND s.Tarih = @Tarih AND s.OturumID = @OturumID;

    -- Eðer herhangi bir meþguliyeti varsa 0 (Hayýr) döndür
    IF @MesgulSayisi > 0
        RETURN 0;

    RETURN 1; -- Hiçbir engele takýlmadýysa 1 (Evet) döndür
END;

GO
-- 2. UDF: Adaletli Daðýtým Ýçin Görev Sayýsý Hesaplayýcý
CREATE FUNCTION fn_GozetmenGorevSayisi
(
    @PersonelID INT
)
RETURNS INT -- Toplam kaç kere görev aldýðýný sayý olarak döndürür
AS
BEGIN
    DECLARE @ToplamGorev INT;

    SELECT @ToplamGorev = COUNT(*)
    FROM Gozetmen_Atamalari
    WHERE PersonelID = @PersonelID;

    RETURN @ToplamGorev;
END;

GO
-- 3. UDF: Sýnýf Kapasitesi Bu Ders Ýçin Yeterli Mi?
CREATE FUNCTION fn_DerslikKapasiteYeterliMi
(
    @DerslikID INT,
    @DersID INT
)
RETURNS BIT -- 1: Yeterli, 0: Yetersiz
AS
BEGIN
    DECLARE @Kapasite INT;
    DECLARE @OgrenciSayisi INT;

    -- Seçilen salonun kapasitesini öðren
    SELECT @Kapasite = Kapasite FROM Derslikler WHERE DerslikID = @DerslikID;

    -- Seçilen dersin öðrenci sayýsýný öðren
    SELECT @OgrenciSayisi = OgrenciSayisi FROM Dersler WHERE DersID = @DersID;

    -- Kapasite büyük veya eþitse 1 (Evet) döndür
    IF @Kapasite >= @OgrenciSayisi
        RETURN 1;

    RETURN 0; -- Yetmiyorsa 0 (Hayýr) döndür
END;

-- 1. SP: Sýnav Ekleme (Sadece Yarýyýl Çakýþmasý Korumalý)
GO
ALTER PROCEDURE SinavEkle
    @DersID INT,
    @Tarih DATE,
    @OturumID INT
AS
BEGIN
    DECLARE @Yariyil INT;
    DECLARE @CakismaSayisi INT;

    -- Eklenecek dersin hangi yarýyýla (Döneme) ait olduðunu bul
    SELECT @Yariyil = Yariyil FROM Dersler WHERE DersID = @DersID;

    -- KONTROL: Ayný yarýyýlda, ayný gün ve saatte baþka sýnav var mý?
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
        -- Sorun yoksa Sýnavý Ekle
        INSERT INTO Sinavlar (DersID, Tarih, OturumID)
        VALUES (@DersID, @Tarih, @OturumID);
    END
END;

-- 2. SP: Salon Atama (Sadece Kapasite Korumalý)
GO
ALTER PROCEDURE SalonAta
    @SinavID INT,
    @DerslikID INT
AS
BEGIN
    DECLARE @DersID INT;
    SELECT @DersID = DersID FROM Sinavlar WHERE SinavID = @SinavID;

    -- KONTROL: Kapasite yeterli mi?
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

-- 3. SP: Gözetmen Atama (3 Oturum Limiti ve Müsaitlik Korumalý)
GO
ALTER PROCEDURE GozetmenAta
    @SinavSalonID INT,
    @PersonelID INT
AS
BEGIN
    DECLARE @Tarih DATE;
    DECLARE @OturumID INT;
    DECLARE @GunlukGorevSayisi INT;

    -- Sýnav bilgilerini çek
    SELECT @Tarih = s.Tarih, @OturumID = s.OturumID
    FROM Sinav_Salonlari ss
    INNER JOIN Sinavlar s ON ss.SinavID = s.SinavID
    WHERE ss.AtamaID = @SinavSalonID;

    -- KONTROL 1: Gözetmen o gün arka arkaya kaç oturuma girmiþ?
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
        -- KONTROL 2: Hoca Müsait mi?
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

-- 1. TRIGGER: Salon Çakýþma Güvenliði
GO
CREATE TRIGGER trg_SalonCakismaGuvenligi
ON Sinav_Salonlari
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN Sinavlar s1 ON i.SinavID = s1.SinavID
        -- Kendi tablosundaki AtamaID (PK) ile çakýþmalarý engelle
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
        -- Senin tablandaki SinavSalonID (YA), Sinav_Salonlari tablosundaki AtamaID (PK) ile eþleþiyor
        INNER JOIN Sinav_Salonlari ss1 ON i.SinavSalonID = ss1.AtamaID
        INNER JOIN Sinavlar s1 ON ss1.SinavID = s1.SinavID

        -- Gözetmenin kendisi (AtamaID) hariç diðer atamalarýný bul
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