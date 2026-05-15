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
            SELECT DersID as dersId, DersKodu as dersKodu, Ad as ad, OgrenciSayisi as ogrenciSayisi, Yariyil as yariyil 
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
            SELECT PersonelID as personelId, Unvan as unvan, Ad as ad, Soyad as soyad, BolumID as bolumId 
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
        const result = await pool.request().query(`
            SELECT OturumID as oturumId, Tanim as tanim, 
            CONVERT(VARCHAR(5), BaslangicSaat, 108) as baslangicSaat, 
            CONVERT(VARCHAR(5), BitisSaat, 108) as bitisSaat 
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

// Tanımlamalar Ekranı: YENİ DERSLİK KAYDETME
app.post('/api/DerslikYonetim', async (req, res) => {
    const { ad, kapasite, kat } = req.body;
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('Ad', sql.NVarChar, ad)
            .input('Kapasite', sql.Int, kapasite || 0)
            .input('Kat', sql.Int, kat || 0)
            .query("INSERT INTO Derslikler (Ad, Kapasite, Tip, Aktif, Kat) VALUES (@Ad, @Kapasite, 'Sinif', 1, @Kat)");
        res.status(201).json({ mesaj: "Derslik başarıyla eklendi." });
    } catch (err) { res.status(500).json({ hata: "Hata: " + err.message }); }
});

// Tanımlamalar Ekranı: YENİ PERSONEL/HOCA KAYDETME
app.post('/api/PersonelYonetim', async (req, res) => {
    const { adSoyad, bolumId } = req.body;
    // Backend'de isimi güvenli ayıklama (Örn: "Prof. Dr. Ahmet Yılmaz" -> Ad: "Prof. Dr. Ahmet", Soyad: "Yılmaz")
    const nameParts = (adSoyad || "").trim().split(' ');
    const soyad = nameParts.length > 1 ? nameParts.pop() : ""; 
    const adUnvan = nameParts.join(' ');

    try {
        const pool = await poolPromise;
        await pool.request()
            .input('Ad', sql.NVarChar, adUnvan)
            .input('Soyad', sql.NVarChar, soyad)
            .input('BolumID', sql.Int, bolumId || 1)
            .query("INSERT INTO Personel (Unvan, Ad, Soyad, BolumID) VALUES ('', @Ad, @Soyad, @BolumID)"); 
        res.status(201).json({ mesaj: "Personel başarıyla eklendi." });
    } catch (err) { res.status(500).json({ hata: "Hata: " + err.message }); }
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

// Sınav Ekleme Ekranı: Dönem Ayarlarını Takvim İçin Çekme
app.get('/api/donem-ayarlari', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .query('SELECT DonemBaslangicTarihi, DonemBitisTarihi FROM Donem_Ayarlari WHERE AyarID = 1');

        if (result.recordset.length > 0) {
            res.json({
                baslangic: result.recordset[0].DonemBaslangicTarihi,
                bitis: result.recordset[0].DonemBitisTarihi
            });
        } else {
            res.status(404).json({ hata: "Dönem ayarları veritabanında bulunamadı." });
        }
    } catch (err) { 
        res.status(500).json({ hata: err.message }); 
    }
});

// ==========================================================================
// 3. PUT (GÜNCELLEME) ENDPOINT'LERİ - Frontend Düzenleme İşlemleri İçin
// ==========================================================================

app.put('/api/SinavYonetim/:id', async (req, res) => {
    const { dersAdi, dersKodu, yariyil, kontenjan } = req.body;
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('ID', sql.Int, req.params.id)
            .input('Kodu', sql.NVarChar, dersKodu)
            .input('Ad', sql.NVarChar, dersAdi)
            .input('OgrenciSayisi', sql.Int, kontenjan)
            .input('Yariyil', sql.Int, yariyil)
            .query("UPDATE Dersler SET DersKodu=@Kodu, Ad=@Ad, OgrenciSayisi=@OgrenciSayisi, Yariyil=@Yariyil WHERE DersID=@ID");
        res.json({ mesaj: "Güncellendi" });
    } catch (err) { res.status(500).json({ hata: err.message }); }
});

app.put('/api/DerslikYonetim/:id', async (req, res) => {
    const { ad, kapasite, kat } = req.body;
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('ID', sql.Int, req.params.id)
            .input('Ad', sql.NVarChar, ad)
            .input('Kapasite', sql.Int, kapasite)
            .input('Kat', sql.Int, kat)
            .query("UPDATE Derslikler SET Ad=@Ad, Kapasite=@Kapasite, Kat=@Kat WHERE DerslikID=@ID");
        res.json({ mesaj: "Güncellendi" });
    } catch (err) { res.status(500).json({ hata: err.message }); }
});

app.put('/api/PersonelYonetim/:id', async (req, res) => {
    const { adSoyad, bolumId } = req.body;
    const nameParts = (adSoyad || "").trim().split(' ');
    const soyad = nameParts.length > 1 ? nameParts.pop() : ""; 
    const adUnvan = nameParts.join(' ');

    try {
        const pool = await poolPromise;
        await pool.request()
            .input('ID', sql.Int, req.params.id)
            .input('Ad', sql.NVarChar, adUnvan)
            .input('Soyad', sql.NVarChar, soyad)
            .input('BolumID', sql.Int, bolumId)
            .query("UPDATE Personel SET Ad=@Ad, Soyad=@Soyad, BolumID=@BolumID WHERE PersonelID=@ID");
        res.json({ mesaj: "Güncellendi" });
    } catch (err) { res.status(500).json({ hata: err.message }); }
});

app.put('/api/Oturum/:id', async (req, res) => {
    const { tanim, baslangicSaat, bitisSaat } = req.body;
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('ID', sql.Int, req.params.id)
            .input('Tanim', sql.NVarChar, tanim)
            .input('Baslangic', sql.VarChar, baslangicSaat)
            .input('Bitis', sql.VarChar, bitisSaat)
            .query("UPDATE Oturumlar SET Tanim=@Tanim, BaslangicSaat=@Baslangic, BitisSaat=@Bitis WHERE OturumID=@ID");
        res.json({ mesaj: "Güncellendi" });
    } catch (err) { res.status(500).json({ hata: err.message }); }
});

// ==========================================================================
// 4. DELETE (SİLME) ENDPOINT'LERİ
// ==========================================================================

app.delete('/api/SinavYonetim/:id', async (req, res) => {
    try {
        const pool = await poolPromise;
        await pool.request().input('ID', sql.Int, req.params.id).query("DELETE FROM Dersler WHERE DersID=@ID");
        res.json({ mesaj: "Silindi" });
    } catch (err) { res.status(500).json({ hata: err.message }); }
});

app.delete('/api/DerslikYonetim/:id', async (req, res) => {
    try {
        const pool = await poolPromise;
        await pool.request().input('ID', sql.Int, req.params.id).query("DELETE FROM Derslikler WHERE DerslikID=@ID");
        res.json({ mesaj: "Silindi" });
    } catch (err) { res.status(500).json({ hata: err.message }); }
});

app.delete('/api/PersonelYonetim/:id', async (req, res) => {
    try {
        const pool = await poolPromise;
        await pool.request().input('ID', sql.Int, req.params.id).query("DELETE FROM Personel WHERE PersonelID=@ID");
        res.json({ mesaj: "Silindi" });
    } catch (err) { res.status(500).json({ hata: err.message }); }
});

app.delete('/api/Oturum/:id', async (req, res) => {
    try {
        const pool = await poolPromise;
        await pool.request().input('ID', sql.Int, req.params.id).query("DELETE FROM Oturumlar WHERE OturumID=@ID");
        res.json({ mesaj: "Silindi" });
    } catch (err) { res.status(500).json({ hata: err.message }); }
});

// ==========================================
// 5. AKILLI ATAMA (SP) VE TAKVİM (VİTRİN)
// ==========================================
app.post('/api/akilli-atama', async (req, res) => {
    const { DersID, Tarih, OturumID } = req.body;
    try {
        const pool = await poolPromise;
        await pool.request()
            .input('DersID', sql.Int, DersID)
            .input('Tarih', sql.Date, Tarih)
            .input('OturumID', sql.Int, OturumID)
            .execute('SinavEkle');

        const sinavResult = await pool.request()
            .input('DersID', sql.Int, DersID)
            .input('Tarih', sql.Date, Tarih)
            .input('OturumID', sql.Int, OturumID)
            .query('SELECT TOP 1 SinavID FROM Sinavlar WHERE DersID = @DersID AND Tarih = @Tarih AND OturumID = @OturumID ORDER BY SinavID DESC');
        
        if (sinavResult.recordset.length > 0) {
            await pool.request()
                .input('SinavID', sql.Int, sinavResult.recordset[0].SinavID)
                .execute('SalonAta');
            res.json({ mesaj: "Sınav oluşturuldu ve kapasiteye göre salonlar otomatik atandı." });
        } else {
            res.status(400).json({ hata: "Sınav ID'si alınamadı." });
        }
    } catch (err) { res.status(400).json({ hata: err.message }); }
});

app.get('/api/SinavTakvimi', async (req, res) => {
    try {
        const pool = await poolPromise;
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
            let oturumGroup = groupedData.find(g => g.oturum === row.OturumAdi);
            if (!oturumGroup) {
                oturumGroup = { oturum: row.OturumAdi, derslikler: [] };
                groupedData.push(oturumGroup);
            }

            let derslikGroup = oturumGroup.derslikler.find(d => d.ad === row.DerslikAdi);
            if (!derslikGroup) {
                derslikGroup = { ad: row.DerslikAdi, gunler: { pazartesi: null, sali: null, carsamba: null, persembe: null, cuma: null } };
                oturumGroup.derslikler.push(derslikGroup);
            }

            const dateObj = new Date(row.Tarih);
            const dayIndex = dateObj.getUTCDay(); // UTC kullanımı ile gün kaymaları önlendi
            const gunKey = days[dayIndex];

            if (gunKey && derslikGroup.gunler[gunKey] !== undefined) {
                derslikGroup.gunler[gunKey] = { ders: row.DersAdi, gozetmen: row.GozetmenAdi };
            }
        });

        res.json({ haftaBasligi: "Haziran 2026 Sınav Programı (1 - 5 Haziran)", program: groupedData });
    } catch (err) { res.status(500).json({ hata: err.message }); }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Backend ${PORT} portunda başarıyla çalışıyor!`);
});