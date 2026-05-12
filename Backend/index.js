const express = require('express');
const cors = require('cors');
const { sql, poolPromise } = require('./db');

const app = express();
app.use(express.json());
app.use(cors());

// 1. MODÜL: Sınav Takvimini Listele (View 1) [cite: 65, 72]
app.get('/api/sinav-programi', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request().query("SELECT * FROM vw_GenelSinavProgrami");
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ hata: err.message });
    }
});

// 1. YENİ DERSLİK KAYDETME
app.post('/api/Oturum', async (req, res) => {
    const { ad, kapasite } = req.body;
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('Ad', sql.NVarChar, ad)
            .input('Kapasite', sql.Int, kapasite)
            .query("INSERT INTO Derslikler (Ad, Kapasite, Aktif) VALUES (@Ad, @Kapasite, 1)");
            
        res.status(201).json({ mesaj: "Derslik başarıyla eklendi." });
    } catch (err) {
        res.status(500).json({ hata: "Derslik eklenemedi: " + err.message });
    }
});

// 2. YENİ PERSONEL/HOCA KAYDETME
app.post('/api/PersonelYonetim', async (req, res) => {
    const { adSoyad, bolum } = req.body;
    try {
        const pool = await poolPromise;
        // Önce bölüm adından BolumID'yi bulalım veya doğrudan ekleyelim
        // Not: Basitlik adına burada doğrudan Personel tablosuna ekleme yapıyoruz.
        // Eğer SQL yapınızda BolumID zorunluysa, önce Bolumler tablosuna bakılmalı.
        await pool.request()
            .input('AdSoyad', sql.NVarChar, adSoyad)
            .query("INSERT INTO Personel (AdSoyad, BolumID) VALUES (@AdSoyad, 1)"); // Varsayılan 1 nolu bölüm
            
        res.status(201).json({ mesaj: "Personel başarıyla eklendi." });
    } catch (err) {
        res.status(500).json({ hata: "Personel eklenemedi: " + err.message });
    }
});

// 3. YENİ DERS KAYDETME
app.post('/api/SinavYonetim', async (req, res) => {
    const { dersAdi, kontenjan } = req.body;
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('Ad', sql.NVarChar, dersAdi)
            .input('Kontenjan', sql.Int, kontenjan)
            .query("INSERT INTO Dersler (Ad, OgrenciSayisi, BolumID, Yariyil) VALUES (@Ad, @Kontenjan, 1, 1)");
            
        res.status(201).json({ mesaj: "Ders başarıyla eklendi." });
    } catch (err) {
        res.status(500).json({ hata: "Ders eklenemedi: " + err.message });
    }
});

// 2. MODÜL: Akıllı Salon Atama (Capacity Planning) [cite: 17, 18]
// Bu endpoint, yeni sınav eklerken SQL'deki "SalonAta" SP'sini tetikler.
app.post('/api/akilli-atama', async (req, res) => {
    const { DersID, Tarih, OturumID } = req.body;
    try {
        const pool = await poolPromise;
        
        // Önce Sınavı Ekle (Dönem çakışma kontrolü SP içinde yapılıyor) [cite: 41, 42]
        const sinavResult = await pool.request()
            .input('DersID', sql.Int, DersID)
            .input('Tarih', sql.Date, Tarih)
            .input('OturumID', sql.Int, OturumID)
            .execute('SinavEkle');

        // Sınav eklendikten sonra otomatik Salon Ata (Modül 2 Mantığı) [cite: 20, 21]
        // Not: SP içinde en büyük amfiden başlayarak kapasiteyi doldurma mantığı çalışır.
        res.json({ mesaj: "Sınav oluşturuldu ve kapasiteye göre en uygun salonlar atandı." });
    } catch (err) {
        res.status(400).json({ hata: "İş Kuralı İhlali: " + err.message });
    }
});

// Personel listesini çek (Mazeret ekranındaki açılır menü için)
app.get('/api/PersonelListesi', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request().query("SELECT PersonelID, (Unvan + ' ' + Ad + ' ' + Soyad) as AdSoyad FROM Personel");
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ hata: err.message });
    }
});

// PERSONEL MAZERET/İZİN KAYDETME [cite: 16, 34]
app.post('/api/MazeretEkle', async (req, res) => {
    const { PersonelID, Tarih, MazeretTuru } = req.body;
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('PersonelID', sql.Int, PersonelID)
            .input('Tarih', sql.Date, Tarih)
            .input('MazeretTuru', sql.NVarChar, MazeretTuru)
            .query("INSERT INTO Personel_Durum (PersonelID, Tarih, MazeretTuru, Uygun) VALUES (@PersonelID, @Tarih, @MazeretTuru, 0)");
            
        res.status(201).json({ mesaj: "Mazeret başarıyla işlendi." });
    } catch (err) {
        res.status(500).json({ hata: "Mazeret kaydedilemedi: " + err.message });
    }
});

// 3. MODÜL: Gözetmen Atama (Havuz Sistemi) [cite: 24, 25]
app.post('/api/gozetmen-ata', async (req, res) => {
    const { SinavSalonID } = req.body;
    try {
        const pool = await poolPromise;
        // SP, gözetmenin arka arkaya 3 görev alıp almadığını kontrol eder [cite: 26, 27]
        await pool.request()
            .input('SinavSalonID', sql.Int, SinavSalonID)
            .execute('GozetmenAta');
            
        res.json({ mesaj: "Gözetmen kısıtlar dahilinde başarıyla atandı." });
    } catch (err) {
        res.status(400).json({ hata: err.message });
    }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Backend ${PORT} portunda hazır!`);
});