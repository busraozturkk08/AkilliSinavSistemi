document.addEventListener('DOMContentLoaded', () => {
    if (window.lucide) lucide.createIcons();
    setupDynamicLabels();
});

function setupDynamicLabels() {
    const regType = document.getElementById('regType');
    const regTitleLabel = document.querySelector('label[for="regTitle"]');
    const regTitleInput = document.getElementById('regTitle');
    const regValueLabel = document.querySelector('label[for="regValue"]');
    const regValueInput = document.getElementById('regValue');

    if (!regType) return;

    regType.addEventListener('change', (e) => {
        const secim = e.target.value;
        if (secim === 'personel') {
            regTitleLabel.innerText = "Ad Soyad";
            regTitleInput.placeholder = "Örn: Ahmet Yılmaz";
            regValueLabel.innerText = "Bağlı Olduğu Bölüm";
            regValueInput.placeholder = "Örn: Yazılım Mühendisliği";
        } else if (secim === 'derslik') {
            regTitleLabel.innerText = "Derslik Adı";
            regTitleInput.placeholder = "Örn: Amfi-1";
            regValueLabel.innerText = "Kapasite";
            regValueInput.placeholder = "Örn: 70";
        } else if (secim === 'ders') {
            regTitleLabel.innerText = "Ders Adı";
            regTitleInput.placeholder = "Örn: Veritabanı Sistemleri";
            regValueLabel.innerText = "Kontenjan";
            regValueInput.placeholder = "Örn: 132";
        }
    });
}

async function handleRegistration(event) {
    event.preventDefault();
    const type = document.getElementById('regType').value;
    const title = document.getElementById('regTitle').value;
    const value = document.getElementById('regValue').value;

    let endpoint = "";
    let payload = {};

    if (type === 'derslik') {
        endpoint = "/api/Oturum";
        payload = { ad: title, kapasite: parseInt(value) };
    } else if (type === 'personel') {
        endpoint = "/api/PersonelYonetim"; 
        payload = { adSoyad: title, bolum: value };
    } else if (type === 'ders') {
        endpoint = "/api/SinavYonetim"; 
        payload = { dersAdi: title, kontenjan: parseInt(value) };
    }

    try {
        const response = await fetch(`${BASE_URL}${endpoint}`, {
            method: 'POST',
            mode: 'cors',
            headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (response.ok) {
            addLog(`Başarılı: ${title}`, `${type.toUpperCase()} kaydedildi.`, 'add');
            event.target.reset();
        } else {
            addLog("Kayıt Hatası", `Sunucu hatası: ${response.status}`, 'update');
        }
    } catch (error) {
        addLog("Bağlantı Hatası", "Sunucuya ulaşılamıyor.", 'update');
    }
}