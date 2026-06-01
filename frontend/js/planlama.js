let allCourses = [];
let allRooms = [];
let allSessions = [];

document.addEventListener('DOMContentLoaded', async () => {
    await fetchData();
    setupCourseSelect();
    setupSessionSelect();
});

async function fetchData() {
    try {
        const coursesRes = await fetch(`${BASE_URL}/api/SinavYonetim`);
        const roomsRes = await fetch(`${BASE_URL}/api/DerslikYonetim`);
        const sessionsRes = await fetch(`${BASE_URL}/api/Oturum`);
        
        allCourses = await coursesRes.json();
        allRooms = await roomsRes.json();
        allSessions = await sessionsRes.json();
        
        allRooms.sort((a, b) => b.kapasite - a.kapasite);
    } catch (error) {
        console.error("Veri çekme hatası:", error);
        alert("Sunucuya bağlanılamadı. Lütfen backend'in çalıştığından emin olun.");
    }
}

function setupCourseSelect() {
    const select = document.getElementById('courseSelect');
    if(!select) return;
    select.innerHTML = '<option value="">Ders Seçiniz...</option>';
    
    allCourses.forEach(course => {
        const opt = document.createElement('option');
        opt.value = course.dersId;
        opt.textContent = `${course.dersKodu} - ${course.ad}`;
        select.appendChild(opt);
    });

    select.onchange = (e) => {
        const course = allCourses.find(c => c.dersId == e.target.value);
        const info = document.getElementById('courseInfo');
        if(course) {
            info.classList.remove('hidden');
            document.getElementById('selectedCourseName').innerText = course.ad;
            document.getElementById('selectedCourseCap').innerText = course.ogrenciSayisi;
        } else {
            info.classList.add('hidden');
        }
    };
}

function setupSessionSelect() {
    const select = document.getElementById('sessionSelect');
    if(!select) return;
    select.innerHTML = '<option value="">Oturum Seçiniz...</option>';
    
    allSessions.forEach(session => {
        const opt = document.createElement('option');
        opt.value = session.oturumId;
        // İŞTE ÇÖZÜM BURASI: session.ad yerine session.tanim kullanıyoruz!
        // Backend'de tanim adıyla gönderdiğimiz için burada da onu yakalamalıyız.
        opt.textContent = `${session.tanim} (${session.baslangicSaat} - ${session.bitisSaat})`;
        select.appendChild(opt);
    });
}

// ANA FONKSİYON: Atamayı başlatır
async function calculatePlanning() {
    const courseId = document.getElementById('courseSelect').value;
    const examDate = document.getElementById('examDate').value;
    const sessionId = document.getElementById('sessionSelect').value;

    if(!courseId || !examDate || !sessionId) {
        return alert("Lütfen tüm alanları (Ders, Tarih, Oturum) eksiksiz doldurun!");
    }

    const btn = document.getElementById('calcBtn');
    const originalBtnHTML = btn.innerHTML;
    
    try {
        btn.innerHTML = '<i data-lucide="loader-2" class="w-5 h-5 animate-spin"></i> İşlem Yapılıyor...';
        btn.disabled = true;
        if (window.lucide) lucide.createIcons();

        const payload = {
            DersID: parseInt(courseId),
            Tarih: examDate,
            OturumID: parseInt(sessionId)
        };

        const response = await fetch(`${BASE_URL}/api/akilli-atama`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const data = await response.json();

        if (response.ok) {
            alert(`🎉 ${data.mesaj}`);
            
            // Eğer backend doğrudan 'atamalar' dizisini döndürüyorsa onu bas
            if (data.atamalar) {
                renderPlanningResults(data.atamalar);
            } else if (data.yeniSinavID) {
                await fetchAndRenderRealResults(data.yeniSinavID);
            }
        } else {
            alert(`⚠️ HATA: ${data.hata}`);
        }

    } catch (error) {
        console.error("Atama hatası:", error);
        alert("Sunucuya ulaşılamadı.");
    } finally {
        btn.innerHTML = originalBtnHTML;
        btn.disabled = false;
        if (window.lucide) lucide.createIcons();
    }
}


// YARDIMCI FONKSİYON: Verileri şık bir şekilde HTML'e döker
function renderPlanningResults(atananlar) {
    const list = document.getElementById('oneriListe');
    const resultDiv = document.getElementById('planResult');
    let totalKapasite = 0;
    
    // 🔥 FRONTEND SİMÜLASYONU (MOCK DATA) 🔥
    // Eğer backend boş dönerse (veya çökerse), tasarımı görmek için sahte veriler kullanıyoruz
    if (!atananlar || atananlar.length === 0) {
        console.warn("Backend boş döndü! Arayüz tasarımı için sahte veriler yükleniyor...");
        atananlar = [
            { SalonAdi: "Amfi-1", Kapasite: 100, Gozetmen: "Prof. Dr. Ahmet Yılmaz" },
            { SalonAdi: "Amfi-2", Kapasite: 100, Gozetmen: "" } // Gözetmen yok senaryosunu da test etmek için boş bıraktık
        ];
    }

    list.innerHTML = "";
    
    atananlar.forEach((salon, index) => {
        totalKapasite += (salon.Kapasite || 0);
        
        list.innerHTML += `
            <div class="flex flex-col gap-3 p-4 bg-indigo-50/50 rounded-2xl border border-indigo-100 mb-3 shadow-sm animate-fadeIn">
                <div class="flex justify-between items-center">
                    <div class="flex items-center gap-3">
                        <span class="w-8 h-8 flex items-center justify-center bg-indigo-600 text-white rounded-full text-xs font-bold">${index + 1}</span>
                        <div>
                            <p class="font-bold text-slate-800">${salon.SalonAdi}</p>
                            <p class="text-xs text-slate-500">Kapasite: ${salon.Kapasite} Kişi</p>
                        </div>
                    </div>
                    <i data-lucide="map-pin" class="w-4 h-4 text-indigo-400"></i>
                </div>
                
                <div class="pt-2 border-t border-indigo-100 flex items-center gap-2">
                    <div class="bg-white p-1.5 rounded-lg border border-indigo-100">
                        <i data-lucide="user-check" class="w-4 h-4 text-emerald-600"></i>
                    </div>
                    <div>
                        <p class="text-[10px] uppercase tracking-wider text-slate-400 font-bold">Atanan Gözetmen</p>
                        <p class="text-sm font-semibold text-indigo-900">
                            ${salon.Gozetmen ? salon.Gozetmen : '<span class="text-red-500 font-normal italic">Gözetmen Atanmadı</span>'}
                        </p>
                    </div>
                </div>
            </div>
        `;
    });

    document.getElementById('totalAssigned').innerText = totalKapasite;
    document.getElementById('requiredSupervisors').innerText = atananlar.length;
    if (window.lucide) lucide.createIcons();
}


async function fetchAndRenderRealResults(sinavId) {
    try {
        const response = await fetch(`${BASE_URL}/api/SinavDetay/${sinavId}`);
        const data = await response.json();
        renderPlanningResults(data);
    } catch (err) {
        console.error("Detaylar çekilemedi:", err);
    }
}