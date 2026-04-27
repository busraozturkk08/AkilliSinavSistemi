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
--=========================================================================================
--VERÝLERÝN GÝRÝLMESÝ
--==========================================================================================
--bölümler
INSERT INTO Bolumler (BolumAd) VALUES 
('Yazýlým Mühendisliði'),
('Mekatronik Mühendisliði'),
('Makine Mühendisliði'),
('Enerji Sistemleri Mühendisliði'),
('Elektrik Mühendisliði');

-- 3. Dersler Tablosu Veri Giriþi
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
('ELK302', 'Sensör ve Algýlayýcýlar', 'Seçmeli', 50, 6, 5)

-- 4. Derslikler (Mekan Tanýmlarý)
INSERT INTO Derslikler (Ad, Kapasite, Tip, Aktif) 
VALUES 
-- Zemin Kat (Gözetmen odasýna yakýn, büyük sýnavlar için)
('Amfi-1', 100, 'Amfi', 1),  -- Zemin Kat
('Amfi-2', 100, 'Amfi', 1),  -- Zemin Kat
('Z-01', 40, 'Sinif', 1),    -- Zemin Kat

-- 1. Kat (Sýnýf odaklý)
('101', 60, 'Sinif', 1), 
('102', 60, 'Sinif', 1), 
('103', 50, 'Sinif', 1),

-- 2. Kat (Daha büyük sýnýflar ve Lablar)
('201', 60, 'Sinif', 1), 
('202', 70, 'Sinif', 1), 
('Lab-1', 30, 'Lab', 1),
('Lab-2', 30, 'Lab', 1);

-- 5. Personel (Gözetmen Havuzu) - Güncellenmiþ Yaygýn Ýsimler
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

-- 2. OTURUMLAR (Sýnav Slotlarý)
INSERT INTO Oturumlar (Tanim, BaslangicSaat, BitisSaat) VALUES 
('Oturum 1', '09:00:00', '10:30:00'),
('Oturum 2', '11:00:00', '12:30:00'),
('Oturum 3', '13:30:00', '15:00:00'),
('Oturum 4', '15:30:00', '17:00:00');

-- 6. Personel Durum (Mazeret ve Müsaitlik) Tablosu Veri Giriþi
-- Uygun = 0 (Görev Alamaz/Mazeretli), Uygun = 1 (Görev Alabilir/Müsait)

INSERT INTO Personel_Durum (PersonelID, Tarih, MazeretTuru, Uygun)
VALUES 
-- 1. GÜN: 1 Haziran 2026 Pazartesi
(1, '2026-06-01', 'Farklý Fakültede Sýnav Görevi', 0), -- Ahmet Yýlmaz (Meþgul)
(2, '2026-06-01', 'Müsait', 1),                        -- Canan Kaya
(6, '2026-06-01', 'Saðlýk Raporu', 0),                 -- Buse Yýldýz (Meþgul)
(5, '2026-06-01', 'Müsait', 1),                        -- Mehmet Demir

-- 2. GÜN: 2 Haziran 2026 Salý
(3, '2026-06-02', 'Yýllýk Ýzin', 0),                   -- Mustafa Öztürk (Meþgul)
(4, '2026-06-02', 'Müsait', 1),                        -- Esra Aydýn
(10, '2026-06-02', 'Þehir Dýþý Görevlendirme', 0),     -- Deniz Erdoðan (Meþgul)
(9, '2026-06-02', 'Müsait', 1),                        -- Merve Arslan

-- 3. GÜN: 3 Haziran 2026 Çarþamba
(2, '2026-06-03', 'Akademik Ýzin (Seminer)', 0),       -- Canan Kaya (Meþgul)
(1, '2026-06-03', 'Müsait', 1),                        -- Ahmet Yýlmaz
(7, '2026-06-03', 'Müsait', 1),                        -- Emre Þahin
(8, '2026-06-03', 'Müsait', 1),                        -- Zeynep Çelik

-- 4. GÜN: 4 Haziran 2026 Perþembe
(8, '2026-06-04', 'Öðrenci Danýþmanlýk Saati', 0),     -- Zeynep Çelik (Meþgul) [cite: 50]
(7, '2026-06-04', 'Müsait', 1),                        -- Emre Þahin
(5, '2026-06-04', 'Müsait', 1),                        -- Mehmet Demir
(6, '2026-06-04', 'Müsait', 1),                        -- Buse Yýldýz

-- 5. GÜN: 5 Haziran 2026 Cuma
(9, '2026-06-05', 'Mazeret Ýzni', 0),                  -- Merve Arslan (Meþgul)
(10, '2026-06-05', 'Müsait', 1),                       -- Deniz Erdoðan
(3, '2026-06-05', 'Müsait', 1),                        -- Mustafa Öztürk
(4, '2026-06-05', 'Müsait', 1);                       -- Esra Aydýn
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

-- 9. Sinav_Salonlari Tablosu Veri Giriþi (Kapasite ve Kat Kuralýna Uygun)

-- 1 HAZÝRAN PAZARTESÝ
-- YZM101 (150 Kiþi): Zemin kat aðýrlýklý
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (1, 1); -- Amfi-1 (100)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (1, 4); -- 101 (60) [Toplam 160]

-- ENR101 (125 Kiþi): Zemin kat aðýrlýklý
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (2, 2); -- Amfi-2 (100)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (2, 3); -- Z-01 (40) [Toplam 140]

-- MAK201 (160 Kiþi): 2. Kat aðýrlýklý (DERSLÝK EKSÝÐÝ GÝDERÝLDÝ)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (3, 8); -- 202 (70)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (3, 7); -- 201 (60)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (3, 9); -- Lab-1 (30) [Toplam 160]

-- ELK101 (110 Kiþi): 1. Kat aðýrlýklý (DERSLÝK EKSÝÐÝ GÝDERÝLDÝ)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (4, 5); -- 102 (60)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (4, 6); -- 103 (50) [Toplam 110]

-- MEK101 (135 Kiþi): Karma Kat (DERSLÝK EKSÝÐÝ GÝDERÝLDÝ)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (5, 7); -- 201 (60)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (5, 8); -- 202 (70)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (5, 10);-- Lab-2 (30) [Toplam 160]

-- 2 HAZÝRAN SALI
-- YZM202 (120 Kiþi): Amfi odaklý
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (6, 1); -- Amfi-1 (100)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (6, 3); -- Z-01 (40) [Toplam 140]

-- ELK102 (140 Kiþi): 1. Kat odaklý
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (7, 4); -- 101 (60)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (7, 5); -- 102 (60)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (7, 10);-- Lab-2 (30) [Toplam 150]

-- MAK202 (145 Kiþi): 2. Kat odaklý (DERSLÝK EKSÝÐÝ GÝDERÝLDÝ)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (8, 8); -- 202 (70)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (8, 7); -- 201 (60)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (8, 9); -- Lab-1 (30) [Toplam 160]

-- ENR201 (110 Kiþi): Zemin ve 1. Kat (DERSLÝK EKSÝÐÝ GÝDERÝLDÝ)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (9, 3); -- Z-01 (40)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (9, 2); -- Amfi-2 (100) [Toplam 140]

-- MEK201 (95 Kiþi): 1. Kat
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (10, 6); -- 103 (50)
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (10, 5); -- 102 (60) [Toplam 110]

-- 3 HAZÝRAN ÇARÞAMBA
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (11, 7), (11, 8); -- YZM203 (90 Kiþi) [Kapasite: 130]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (12, 9);          -- ELK201 (30 Kiþi) [Kapasite: 30]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (13, 1);          -- MAK301 (100 Kiþi) [Kapasite: 100]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (14, 10);         -- ENR301 (55 Kiþi) [Kapasite: 30 yetmez]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (14, 9);          -- ENR301 için ek Lab-1 (30) [Toplam 60]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (15, 4), (15, 5); -- MEK202 (115 Kiþi) [Toplam 120]

-- 4 HAZÝRAN PERÞEMBE
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (16, 1), (16, 2); -- YZM201 (130 Kiþi) [Toplam 200]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (17, 8), (17, 7); -- ELK301 (85 Kiþi) [Toplam 130]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (18, 6), (18, 5); -- MAK102 (70 Kiþi) [Toplam 110]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (19, 3), (19, 9); -- ENR302 (130 Kiþi) [Toplam 70 yetmez]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (19, 1);          -- ENR302 için ek Amfi-1 [Toplam 170]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (20, 10);         -- MEK401 (40 Kiþi) [Toplam 30 yetmez]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (20, 6);          -- MEK401 için ek 103 [Toplam 80]

-- 5 HAZÝRAN CUMA
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (21, 5);          -- YZM301 (45 Kiþi) [Kapasite: 60]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (22, 6);          -- ELK302 (50 Kiþi) [Kapasite: 50]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (23, 1), (23, 2); -- MAK302 (120 Kiþi) [Toplam 200]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (24, 8), (24, 7); -- ENR202 (90 Kiþi) [Toplam 130]
INSERT INTO Sinav_Salonlari (SinavID, DerslikID) VALUES (25, 4), (25, 5); -- MEK301 (105 Kiþi) [Toplam 120]

-- Gözetmen atamalarý
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

-- =========================================================================================
-- VIEWS (GÖRÜNÜMLER)
-- =========================================================================================

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
-- TRIGGERS (TETÝKLEYÝCÝLER)
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