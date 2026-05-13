const express = require('express');
const cors = require('cors');
const { sql, poolPromise } = require('./db');

const app = express();
app.use(express.json());
app.use(cors());

// ==========================================
// 1. ARAYÜZ (FRONTEND) İÇİN GET ENDPOINT'LERİ
// ==========================================

// Akıllı Planlama: Dersleri Listele
app.get('/api/SinavYonetim', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request().query(`
            SELECT DersID as dersId, DersKodu as dersKodu, Ad as ad, OgrenciSayisi as ogrenciSayisi 
            FROM Dersler
        `);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ hata: err.message });
    }
});

// Akıllı Planlama: Aktif Derslikleri Listele (Kapasiteye göre büyükten küçüğe)
app.get('/api/DerslikYonetim', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request().query(`
            SELECT DerslikID as derslikId, Ad as ad, Kapasite as kapasite, Kat as kat 
            FROM Derslikler 
            WHERE Aktif = 1 
            ORDER BY Kapasite DESC
        `);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ hata: err.message });
    }
});

// Mazeret Ekranı: Hocaları Listele
app.get('/api/PersonelYonetim', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request().query(`
            SELECT PersonelID as personelId, (Unvan + ' ' + Ad + ' ' + Soyad) as adSoyad 
            FROM Personel
        `);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ hata: err.message });
    }
});

// Mazeret Ekranı: Oturum Slotlarını Listele
app.get('/api/Oturum', async (req, res) => {
    try {
        const pool = await poolPromise;
        // Baslangic ve Bitis saatlerini string'e çevirip birleştiriyoruz
        const result = await pool.request().query(`
            SELECT 
                OturumID as oturumId, 
                Tanim + ' (' + CONVERT(VARCHAR(5), BaslangicSaat, 108) + '-' + CONVERT(VARCHAR(5), BitisSaat, 108) + ')' as ad 
            FROM Oturumlar
        `);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ hata: err.message });
    }
});

// ==========================================
// 2. VERİ KAYDETME (POST) ENDPOINT'LERİ
// ==========================================
// Tanımlamalar Ekranı: YENİ DERS KAYDETME
app.post('/api/SinavYonetim', async (req, res) => {
    // Frontend'den gelen verileri yakalıyoruz
    // (tanimlamalar.js dosyasındaki isimlendirmene göre burası esnektir)
    const { dersAdi, dersKodu, yariyil, kontenjan } = req.body; 
    
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('DersKodu', sql.NVarChar, dersKodu || 'YOK')
            .input('Ad', sql.NVarChar, dersAdi)
            .input('OgrenciSayisi', sql.Int, kontenjan || 0)
            .input('Yariyil', sql.Int, yariyil || 1)
            // Şimdilik varsayılan olarak BolumID=1 (Yazılım) ve DersTuru='Zorunlu' olarak ekliyoruz
            .query("INSERT INTO Dersler (DersKodu, Ad, OgrenciSayisi, BolumID, Yariyil, DersTuru) VALUES (@DersKodu, @Ad, @OgrenciSayisi, 1, @Yariyil, 'Zorunlu')");
            
        res.status(201).json({ mesaj: "Ders başarıyla eklendi." });
    } catch (err) {
        res.status(500).json({ hata: "Ders eklenemedi: " + err.message });
    }
});

// Tanımlamalar Ekranı: YENİ PERSONEL/HOCA KAYDETME
app.post('/api/PersonelYonetim', async (req, res) => {
    const { adSoyad } = req.body;
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('AdSoyad', sql.NVarChar, adSoyad)
            // SQL tablonuzda Ad ve Soyad ayrı tutuluyorsa arkadaşın burayı bölebilir
            .query("INSERT INTO Personel (Unvan, Ad, Soyad, BolumID) VALUES ('Dr.', @AdSoyad, '', 1)"); 
            
        res.status(201).json({ mesaj: "Personel başarıyla eklendi." });
    } catch (err) {
        res.status(500).json({ hata: "Personel eklenemedi: " + err.message });
    }
});

// Tanımlamalar Ekranı: YENİ DERSLİK KAYDETME
app.post('/api/DerslikYonetim', async (req, res) => {
    const { ad, kapasite } = req.body;
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('Ad', sql.NVarChar, ad)
            .input('Kapasite', sql.Int, kapasite || 0)
            .query("INSERT INTO Derslikler (Ad, Kapasite, Tip, Aktif, Kat) VALUES (@Ad, @Kapasite, 'Sinif', 1, 1)");
            
        res.status(201).json({ mesaj: "Derslik başarıyla eklendi." });
    } catch (err) {
        res.status(500).json({ hata: "Derslik eklenemedi: " + err.message });
    }
});

// Personel Mazeret/İzin Kaydetme
app.post('/api/MazeretYonetim', async (req, res) => {
    const { PersonelId, MazeretTuru, Tarih, Uygun } = req.body;
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('PersonelID', sql.Int, PersonelId)
            .input('Tarih', sql.Date, Tarih)
            .input('MazeretTuru', sql.NVarChar, MazeretTuru)
            .input('Uygun', sql.Bit, Uygun ? 1 : 0)
            .query(`
                INSERT INTO Personel_Durum (PersonelID, Tarih, MazeretTuru, Uygun) 
                VALUES (@PersonelID, @Tarih, @MazeretTuru, @Uygun)
            `);
            
        res.status(201).json({ mesaj: "Mazeret başarıyla işlendi." });
    } catch (err) {
        res.status(500).json({ hata: "Mazeret kaydedilemedi: " + err.message });
    }
});

// Akıllı Salon Atama (Geliştirilmiş Stored Procedure Entegrasyonu)
app.post('/api/akilli-atama', async (req, res) => {
    const { DersID, Tarih, OturumID } = req.body;
    try {
        const pool = await poolPromise;
        
        // 1. Sınavı Ekle (SQL'deki SinavEkle SP'si)
        await pool.request()
            .input('DersID', sql.Int, DersID)
            .input('Tarih', sql.Date, Tarih)
            .input('OturumID', sql.Int, OturumID)
            .execute('SinavEkle');

        // 2. Eklenen Sınavın ID'sini bul
        const sinavResult = await pool.request()
            .input('DersID', sql.Int, DersID)
            .input('Tarih', sql.Date, Tarih)
            .input('OturumID', sql.Int, OturumID)
            .query('SELECT SinavID FROM Sinavlar WHERE DersID = @DersID AND Tarih = @Tarih AND OturumID = @OturumID');
        
        const yeniSinavID = sinavResult.recordset[0].SinavID;

        // 3. Otomatik Salon Ataması Yap (SQL'deki SalonAta SP'si)
        await pool.request()
            .input('SinavID', sql.Int, yeniSinavID)
            .execute('SalonAta');

        res.json({ mesaj: "Sınav oluşturuldu ve kapasiteye göre salonlar otomatik atandı." });
    } catch (err) {
        res.status(400).json({ hata: "İş Kuralı İhlali: " + err.message });
    }
});

// Tanımlamalar Ekranı: YENİ OTURUM KAYDETME

// Tanımlamalar Ekranı: YENİ OTURUM KAYDETME
app.post('/api/Oturum', async (req, res) => {
    const { tanim, baslangicSaat, bitisSaat } = req.body;
    
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('Tanim', sql.NVarChar, tanim)
            // ÇÖZÜM: sql.Time yerine sql.VarChar (Metin) kullanıyoruz!
            // SQL Server bu metni kendi kendine saate (TIME) dönüştürecektir.
            .input('BaslangicSaat', sql.VarChar, baslangicSaat) 
            .input('BitisSaat', sql.VarChar, bitisSaat)
            .query("INSERT INTO Oturumlar (Tanim, BaslangicSaat, BitisSaat) VALUES (@Tanim, @BaslangicSaat, @BitisSaat)");
            
        res.status(201).json({ mesaj: "Oturum başarıyla eklendi." });
    } catch (err) {
        res.status(500).json({ hata: "Oturum eklenemedi: " + err.message });
    }
});

// ==========================================
// 3. TAKVİM (VİTRİN) ENDPOINT'İ - DÜZELTİLDİ
// ==========================================

app.get('/api/SinavTakvimi', async (req, res) => {
    try {
        const pool = await poolPromise;
        
        // View yerine tüm verileri (Gözetmenler dahil) getiren özel sorgu yazıldı
        const result = await pool.request().query(`
            SELECT 
                o.Tanim + ' (' + CONVERT(VARCHAR(5), o.BaslangicSaat, 108) + ' - ' + CONVERT(VARCHAR(5), o.BitisSaat, 108) + ')' AS OturumAdi,
                dl.Ad AS DerslikAdi,
                s.Tarih,
                d.DersKodu + ' - ' + d.Ad AS DersAdi,
                ISNULL(p.Unvan + ' ' + p.Ad + ' ' + p.Soyad, 'Gözetmen Atanmadı') AS GozetmenAdi
            FROM Sinavlar s
            INNER JOIN Dersler d ON s.DersID = d.DersID
            INNER JOIN Oturumlar o ON s.OturumID = o.OturumID
            INNER JOIN Sinav_Salonlari ss ON s.SinavID = ss.SinavID
            INNER JOIN Derslikler dl ON ss.DerslikID = dl.DerslikID
            LEFT JOIN Gozetmen_Atamalari ga ON ss.AtamaID = ga.SinavSalonID
            LEFT JOIN Personel p ON ga.PersonelID = p.PersonelID
        `);
        
        const rawData = result.recordset;
        const groupedData = [];
        const days = ['pazar', 'pazartesi', 'sali', 'carsamba', 'persembe', 'cuma', 'cumartesi'];

        rawData.forEach(row => {
            // 1. Oturum grubunu bul veya oluştur
            let oturumGroup = groupedData.find(g => g.oturum === row.OturumAdi);
            if (!oturumGroup) {
                oturumGroup = { oturum: row.OturumAdi, derslikler: [] };
                groupedData.push(oturumGroup);
            }

            // 2. Derslik grubunu bul veya oluştur
            let derslikGroup = oturumGroup.derslikler.find(d => d.ad === row.DerslikAdi);
            if (!derslikGroup) {
                derslikGroup = {
                    ad: row.DerslikAdi,
                    gunler: { pazartesi: null, sali: null, carsamba: null, persembe: null, cuma: null }
                };
                oturumGroup.derslikler.push(derslikGroup);
            }

            // 3. Tarihi GÜN ismine çevir (Frontend tablosuna uyarlamak için)
            // SQL'den gelen Tarih verisini JS Date objesine çevirip haftanın gününü buluyoruz.
            const dateObj = new Date(row.Tarih);
            const dayIndex = dateObj.getDay(); 
            const gunKey = days[dayIndex];

            // Eğer sınav hafta içiyse tabloya ekle
            if (derslikGroup.gunler[gunKey] !== undefined) {
                derslikGroup.gunler[gunKey] = {
                    ders: row.DersAdi,
                    gozetmen: row.GozetmenAdi
                };
            }
        });

        // Veriyi "Hafta" başlığıyla birlikte yolla (Frontend'deki o statik 1. Hafta yazısını canlandırmak için)
        res.json({
            haftaBasligi: "Haziran 2026 Sınav Programı (1 - 5 Haziran)",
            program: groupedData
        });

    } catch (err) {
        res.status(500).json({ hata: err.message });
    }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Backend ${PORT} portunda hazır!`);
});