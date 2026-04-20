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
