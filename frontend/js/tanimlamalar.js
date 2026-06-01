document.addEventListener('DOMContentLoaded', () => {
    if (window.lucide) lucide.createIcons();
    
    const regType = document.getElementById('regType');
    if (regType) {
        regType.addEventListener('change', () => {
            updateFormFields();
            fetchAndList();
        });
    }

    updateFormFields();
    fetchAndList();
    loadLogs(); // SAYFA AÇILDIĞINDA: Eski logları tarayıcıdan geri yükle
});

// --- LOG YÖNETİMİ (LOCALSTORAGE) ---

// Logları tarayıcı hafızasına kaydeder
function saveLogToLocal(title, desc, type) {
    let logs = JSON.parse(localStorage.getItem('islemGecmisi')) || [];
    // En yeni işlemi listenin başına ekle
    logs.unshift({ title, desc, type, timestamp: new Date().getTime() });
    // Listeyi son 10 işlemle sınırla (Panelin şişmemesi için)
    logs = logs.slice(0, 10);
    localStorage.setItem('islemGecmisi', JSON.stringify(logs));
}

// Tarayıcı hafızasındaki logları ekrana basar
function loadLogs() {
    const list = document.getElementById('recentActivityList');
    if (!list) return;
    
    const logs = JSON.parse(localStorage.getItem('islemGecmisi')) || [];
    if (logs.length > 0) {
        list.innerHTML = ""; // "Henüz işlem yapılmadı" yazısını temizle
        logs.forEach(log => {
            renderLogUI(log.title, log.desc, log.type, false); // false: Kaydetme, sadece göster
        });
    }
}

// Log ekleme giriş noktası
function addLog(title, desc, type) {
    renderLogUI(title, desc, type, true); // true: Hem göster hem kaydet
}

// Görselleştirme ve Kayıt Mantığı
function renderLogUI(title, desc, type, shouldSave = true) {
    const list = document.getElementById('recentActivityList');
    if (!list) return;
    
    if (list.querySelector('p.italic')) list.innerHTML = "";

    // İkon ve Renk Haritası (Silme işlemi için 'delete' eklendi)
    const iconMap = { add: 'plus-circle', update: 'refresh-cw', error: 'alert-circle', delete: 'trash-2' };
    const colorMap = { 
        add: 'text-emerald-500 bg-emerald-50', 
        update: 'text-indigo-500 bg-indigo-50', 
        error: 'text-red-500 bg-red-50',
        delete: 'text-orange-500 bg-orange-50'
    };

    const item = document.createElement('div');
    item.className = "flex gap-3 p-3 rounded-2xl border border-slate-100 animate-fadeIn mb-3";
    item.innerHTML = `
        <div class="w-10 h-10 rounded-xl ${colorMap[type] || colorMap.update} flex items-center justify-center flex-shrink-0">
            <i data-lucide="${iconMap[type] || iconMap.update}" class="w-5 h-5"></i>
        </div>
        <div class="overflow-hidden">
            <p class="text-sm font-bold text-slate-700 truncate">${title}</p>
            <p class="text-[11px] text-slate-500 leading-tight">${desc}</p>
        </div>
    `;
    
    list.prepend(item);
    if (window.lucide) lucide.createIcons();

    // Eğer yeni bir işlemse (sayfa yüklemesi değilse) tarayıcıya kaydet
    if(shouldSave) saveLogToLocal(title, desc, type);
}

// --- MEVCUT CRUD FONKSİYONLARI (GÜNCELLENDİ) ---

function updateFormFields() {
    const type = document.getElementById('regType').value;
    const courseFields = document.getElementById('courseFields');
    const timeFields = document.getElementById('timeFields');
    const floorField = document.getElementById('floorField');
    const valueField = document.getElementById('valueField');
    const labelTitle = document.getElementById('labelTitle');
    const labelValue = document.getElementById('labelValue');

    if(courseFields) courseFields.classList.add('hidden');
    if(timeFields) timeFields.classList.add('hidden');
    if(floorField) floorField.classList.add('hidden');
    if(valueField) valueField.classList.remove('hidden');

    switch (type) {
        case 'ders':
            labelTitle.innerText = "Ders Adı";
            labelValue.innerText = "Öğrenci Sayısı";
            if (courseFields) courseFields.classList.remove('hidden');
            break;
        case 'derslik':
            labelTitle.innerText = "Derslik / Salon Adı";
            labelValue.innerText = "Kapasite";
            if (floorField) floorField.classList.remove('hidden');
            break;
        case 'personel':
    labelTitle.innerText = "Ad, Soyad ve Unvan";
    labelValue.innerText = "Bölüm Adı (Örn: Yazılım Mühendisliği)"; // Başlık güncellendi
    break;
        case 'oturum':
            labelTitle.innerText = "Oturum Adı (Örn: Oturum 1)";
            if (valueField) valueField.classList.add('hidden');
            if (timeFields) timeFields.classList.remove('hidden');
            break;
    }
}

async function fetchAndList() {
    const type = document.getElementById('regType').value;
    const tbody = document.getElementById('dataListBody');
    const thead = document.getElementById('tableHead');
    const badge = document.getElementById('listBadge');
    
    let endpoint = getEndpoint(type);
    
    try {
        const response = await fetch(`${BASE_URL}${endpoint}`);
        const data = await response.json();
        badge.innerText = `${data.length} KAYIT BULUNDU`;

        renderTableHeader(type, thead);
        
        tbody.innerHTML = "";
        data.forEach(item => {
            const row = renderTableRow(type, item);
            tbody.appendChild(row);
        });
        if (window.lucide) lucide.createIcons();
    } catch (error) {
        console.error("Listeleme hatası:", error);
        tbody.innerHTML = '<tr><td colspan="5" class="p-4 text-center text-red-400 text-xs">Veriler çekilemedi.</td></tr>';
    }
}

async function handleRegistration(event) {
    event.preventDefault();
    
    const recordId = document.getElementById('recordId').value;
    const type = document.getElementById('regType').value;
    const title = document.getElementById('regTitle').value;
    const isEdit = recordId !== "";

    let endpoint = getEndpoint(type);
    let payload = preparePayload(type, title);

    try {
        const url = isEdit ? `${BASE_URL}${endpoint}/${recordId}` : `${BASE_URL}${endpoint}`;
        const method = isEdit ? 'PUT' : 'POST';

        const response = await fetch(url, {
            method: method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (response.ok) {
            addLog(isEdit ? "Güncellendi" : "Kaydedildi", `${title} işlemi tamamlandı.`, isEdit ? 'update' : 'add');
            resetForm();
            fetchAndList();
        } else {
            addLog("Hata", "Sunucu işlemi reddetti.", "error");
        }
    } catch (error) {
        addLog("Bağlantı Hatası", "Sunucuya ulaşılamıyor.", "error");
    }
}

async function deleteRecord(id) {
    if (!confirm("Bu kaydı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.")) return;
    
    const type = document.getElementById('regType').value;
    let endpoint = getEndpoint(type);

    try {
        const response = await fetch(`${BASE_URL}${endpoint}/${id}`, { method: 'DELETE' });
        if (response.ok) {
            addLog("Silindi", "Kayıt veritabanından kaldırıldı.", "delete"); // 'delete' tipi eklendi
            fetchAndList();
        }
    } catch (error) {
        alert("Silme işlemi sırasında hata oluştu.");
    }
}

function editRecord(item) {
    const type = document.getElementById('regType').value;
    document.getElementById('recordId').value = item.dersId || item.derslikId || item.personelId || item.oturumId;

let titleValue = "";
if (type === 'personel') {
    titleValue = `${item.unvan || ''} ${item.ad || ''} ${item.soyad || ''}`.trim();
} else {
    titleValue = item.ad || item.tanim || "";
}
document.getElementById('regTitle').value = titleValue;

    if (type === 'ders') {
        document.getElementById('regCode').value = item.dersKodu;
        document.getElementById('regSemester').value = item.yariyil;
        document.getElementById('regValue').value = item.ogrenciSayisi;
    } else if (type === 'derslik') {
        document.getElementById('regValue').value = item.kapasite;
        document.getElementById('regFloor').value = item.kat;
    } else if (type === 'oturum') {
        document.getElementById('startTime').value = item.baslangicSaat;
        document.getElementById('endTime').value = item.bitisSaat;
    } else if (type === 'personel') {
        document.getElementById('regValue').value = item.bolumId;
    }

    document.getElementById('formTitle').innerText = "Kaydı Düzenle";
    document.getElementById('submitBtnText').innerText = "Değişiklikleri Güncelle";
    document.getElementById('cancelEditBtn').classList.remove('hidden');
    document.getElementById('formContainer').classList.add('ring-2', 'ring-indigo-500');
    window.scrollTo({ top: 0, behavior: 'smooth' });
}

function resetForm() {
    document.getElementById('definitionForm').reset();
    document.getElementById('recordId').value = "";
    document.getElementById('formTitle').innerText = "Yeni Kayıt Oluştur";
    document.getElementById('submitBtnText').innerText = "Sisteme Kaydet";
    document.getElementById('cancelEditBtn').classList.add('hidden');
    document.getElementById('formContainer').classList.remove('ring-2', 'ring-indigo-500');
    updateFormFields();
}

function getEndpoint(type) {
    const map = { 'ders': '/api/SinavYonetim', 'derslik': '/api/DerslikYonetim', 'personel': '/api/PersonelYonetim', 'oturum': '/api/Oturum' };
    return map[type];
}

function preparePayload(type, title) {
    const value = document.getElementById('regValue')?.value || "0";
    if (type === 'derslik') return { ad: title, kapasite: parseInt(value), kat: parseInt(document.getElementById('regFloor').value) || 0 };
   if (type === 'personel') {
    let unvan = "";
    let ad = "";
    let soyad = "";
    let islemMetni = title.trim();

    // 1. Önce bilinen unvanları kontrol edip ayırıyoruz
    const bilinenUnvanlar = ["Arş. Gör. Dr.", "Arş. Gör.", "Dr. Öğr. Üyesi", "Prof. Dr.", "Doç. Dr.", "Öğr. Gör."];
    for (let u of bilinenUnvanlar) {
        if (islemMetni.startsWith(u)) {
            unvan = u;
            // Unvanı metinden çıkartıp kalan kısmı alıyoruz
            islemMetni = islemMetni.substring(u.length).trim(); 
            break;
        }
    }

    // 2. Kalan metin (Örn: "Elif Nur AYGÜN")
    const isimParcalari = islemMetni.split(' ');
    
    if (isimParcalari.length > 1) {
        soyad = isimParcalari.pop(); // Son kelime her zaman soyadı olsun
        ad = isimParcalari.join(' '); // Geriye kalan her şey ad olsun (İki isimli olanlar için)
    } else {
        ad = islemMetni; // Sadece tek bir isim girilmişse
    }

    return { unvan: unvan, ad: ad, soyad: soyad, bolumAd: value };
}
    // Ders satırını şu şekilde güncelle:
if (type === 'ders') return { 
    dersAdi: title, 
    dersKodu: document.getElementById('regCode').value, 
    kontenjan: parseInt(value), 
    yariyil: parseInt(document.getElementById('regSemester').value) || 1,
    dersTuru: document.getElementById('regCourseType').value // YENİ EKLENEN SATIR
};
if (type === 'oturum') return { tanim: title, baslangicSaat: document.getElementById('startTime').value, bitisSaat: document.getElementById('endTime').value };
}

function renderTableHeader(type, head) {
    const common = '<th class="p-4">ID</th><th class="p-4">AD / TANIM</th>';
    const end = '<th class="p-4 text-right">İŞLEMLER</th>';
    if (type === 'ders') head.innerHTML = `${common}<th class="p-4">KOD</th><th class="p-4">KONTENJAN</th>${end}`;
    else if (type === 'derslik') head.innerHTML = `${common}<th class="p-4">KAPASİTE</th><th class="p-4">KAT</th>${end}`;
   else if (type === 'personel') head.innerHTML = `${common}<th class="p-4">BÖLÜM ADI</th>${end}`;
   else if (type === 'oturum') head.innerHTML = `${common}<th class="p-4">BAŞLANGIÇ</th><th class="p-4">BİTİŞ</th>${end}`;
}

function renderTableRow(type, item) {
    const tr = document.createElement('tr');
    tr.className = "hover:bg-slate-50 transition-colors group";
    
   const id = item.dersId || item.derslikId || item.personelId || item.oturumId;

let name = "İsimsiz";
if (type === 'personel') {
    // Personelse hepsini birleştir (boş olanlar 'undefined' yazmasın diye || '' ekledik)
    name = `${item.unvan || ''} ${item.ad || ''} ${item.soyad || ''}`.trim();
} else {
    // Diğerleri için ad veya tanım kullan
    name = item.ad || item.tanim || "İsimsiz";
}

    let extraCols = "";
    if (type === 'ders') extraCols = `<td class="p-4 font-mono text-xs text-indigo-600">${item.dersKodu}</td><td class="p-4">${item.ogrenciSayisi}</td>`;
    else if (type === 'derslik') extraCols = `<td class="p-4 font-semibold">${item.kapasite}</td><td class="p-4">Kat: ${item.kat}</td>`;
    else if (type === 'personel') extraCols = `<td class="p-4 font-medium text-slate-600">${item.bolumAd || '' + item.bolumId}</td>`;
    else if (type === 'oturum') extraCols = `<td class="p-4">${item.baslangicSaat}</td><td class="p-4">${item.bitisSaat}</td>`;

    tr.innerHTML = `
        <td class="p-4 text-slate-400 font-medium">#${id}</td>
        <td class="p-4 font-bold text-slate-700">${name}</td>
        ${extraCols}
        <td class="p-4 text-right">
            <div class="flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                <button onclick='editRecord(${JSON.stringify(item)})' class="p-2 hover:bg-indigo-50 text-indigo-600 rounded-lg transition-colors" title="Düzenle">
                    <i data-lucide="edit-3" class="w-4 h-4"></i>
                </button>
                <button onclick="deleteRecord(${id})" class="p-2 hover:bg-red-50 text-red-600 rounded-lg transition-colors" title="Sil">
                    <i data-lucide="trash-2" class="w-4 h-4"></i>
                </button>
            </div>
        </td>
    `;
    return tr;
}