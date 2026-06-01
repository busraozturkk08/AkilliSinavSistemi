let mazeretSayisi = 0;

document.addEventListener('DOMContentLoaded', async () => {
    if (window.lucide) lucide.createIcons();
    await fetchHocaListesi();
});

// 1. BACKEND'DEN HOCALARI ÇEK VE AÇILIR MENÜYE DOLDUR
async function fetchHocaListesi() {
    const select = document.getElementById('hocaSelect');
    if (!select) return;

    try {
        const response = await fetch(`${BASE_URL}/api/PersonelYonetim`);
        if (!response.ok) throw new Error("Sunucu hatası");
        
        const hocalar = await response.json();
        select.innerHTML = '<option value="">Hoca Seçiniz...</option>';
        
        hocalar.forEach(hoca => {
            // YENİ EKLENEN MANTIK: Unvan, Ad ve Soyad'ı birleştiriyoruz.
            // Eğer unvan boşsa baştaki boşluğu silmek için .trim() kullanıyoruz.
            const tamIsim = `${hoca.unvan ? hoca.unvan : ''} ${hoca.ad} ${hoca.soyad}`.trim();
            select.innerHTML += `<option value="${hoca.personelId}">${tamIsim}</option>`;
        });
    } catch (error) {
        console.error("Hoca listesi çekilemedi:", error);
        select.innerHTML = '<option value="">Hocalar yüklenemedi!</option>';
    }
}

// 2. FORMU BACKEND'E POST ET
async function handleMazeretKayit(event) {
    event.preventDefault(); // Sayfanın yenilenmesini engelle
    
    const hocaSelect = document.getElementById('hocaSelect');
    const hocaId = hocaSelect.value;
    const hocaAdSoyad = hocaSelect.options[hocaSelect.selectedIndex].text; // Ekrana basmak için ismini aldık
    
    const tur = document.getElementById('mazeretTuru').value;
    const tarih = document.getElementById('tarihInput').value;
    
    // Backend'in beklediği JSON paketi
    const payload = {
        PersonelId: parseInt(hocaId),
        MazeretTuru: tur,
        Tarih: tarih,
        Uygun: false // Mazeretli olduğu için müsaitlik durumunu "0" olarak gönderiyoruz
    };

    const btn = document.getElementById('submitBtn');
    const originalText = btn.innerHTML;
    
    try {
        btn.innerHTML = '<i data-lucide="loader-2" class="w-5 h-5 animate-spin mx-auto"></i>';
        btn.disabled = true;

        const response = await fetch(`${BASE_URL}/api/MazeretYonetim`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (response.ok) {
            // Başarılıysa sağdaki listeye ekle
            ekranaMazeretEkle(hocaAdSoyad, tur, tarih);
            document.getElementById('mazeretForm').reset(); // Formu temizle
        } else {
            alert("Kayıt sırasında bir hata oluştu.");
        }
    } catch (error) {
        alert("Sunucuya ulaşılamıyor.");
    } finally {
        btn.innerHTML = originalText;
        btn.disabled = false;
        if (window.lucide) lucide.createIcons();
    }
}

// 3. SAĞ TARAFTAKİ LİSTEYİ DİNAMİK GÜNCELLE
function ekranaMazeretEkle(hocaAd, tur, tarih) {
    const liste = document.getElementById('mazeretListe');
    const emptyMsg = document.getElementById('emptyMsg');
    
    if (emptyMsg) emptyMsg.style.display = 'none';

    // Tarih formatını (YYYY-MM-DD) Türkçeye (DD.MM.YYYY) çeviriyoruz
    const dateObj = new Date(tarih);
    const formatliTarih = dateObj.toLocaleDateString('tr-TR');

    const row = document.createElement('div');
    row.className = "grid grid-cols-4 items-center p-4 bg-indigo-50/40 rounded-2xl border border-indigo-100 hover:bg-indigo-50 transition-colors";
    
    row.innerHTML = `
        <div class="col-span-2 flex items-center gap-3">
            <div class="w-10 h-10 rounded-full bg-indigo-200 text-indigo-700 flex items-center justify-center font-bold text-sm uppercase">
                ${hocaAd.charAt(0)}
            </div>
            <div>
                <p class="font-bold text-slate-800 text-sm">${hocaAd}</p>
                <p class="text-xs text-slate-500 font-medium">${tur}</p>
            </div>
        </div>
        <div class="text-sm font-bold text-slate-600">${formatliTarih}</div>
        <div class="text-right">
            <span class="inline-flex items-center gap-1 bg-emerald-100 text-emerald-700 text-xs font-bold px-2.5 py-1 rounded-lg">
                <i data-lucide="check" class="w-3 h-3"></i> Kaydedildi
            </span>
        </div>
    `;
    
    // Yeni eklenen mazereti listenin en üstüne koyarız
    liste.prepend(row);
    
    // Sayacı güncelle
    mazeretSayisi++;
    document.getElementById('kayitSayaci').innerText = `${mazeretSayisi} KAYIT`;
    
    if (window.lucide) lucide.createIcons();
}