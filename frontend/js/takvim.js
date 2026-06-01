document.addEventListener('DOMContentLoaded', () => {
    if (window.lucide) lucide.createIcons();
    fetchTakvim();
});

async function fetchTakvim() {
    const loadingState = document.getElementById('loadingState');
    const tableContainer = document.getElementById('tableContainer');
    const tbody = document.getElementById('takvimGövdesi');
    const baslik = document.getElementById('takvimBaslik');

    // Yükleniyor durumunu göster
    loadingState.classList.remove('hidden');
    tableContainer.classList.add('hidden');
    tbody.innerHTML = '';

    try {
        const response = await fetch(`${BASE_URL}/api/SinavTakvimi`);
        
        if (!response.ok) throw new Error("Sunucu yanıt vermedi");
        
        const data = await response.json();
        
        // Başlığı Güncelle
        baslik.innerText = data.haftaBasligi || "Genel Sınav Programı";

        // Tabloyu Çiz
        renderTable(data.program);

        // Veri geldikten sonra tabloyu göster
        loadingState.classList.add('hidden');
        tableContainer.classList.remove('hidden');

    } catch (error) {
        console.error("Takvim çekilemedi:", error);
        loadingState.innerHTML = `
            <i data-lucide="alert-circle" class="w-12 h-12 text-red-400 mb-3"></i>
            <p class="font-bold text-slate-600">Veriler yüklenirken bir hata oluştu.</p>
            <p class="text-xs text-slate-400 mt-1">Backend'in çalıştığından emin olun.</p>
        `;
        if (window.lucide) lucide.createIcons();
    }
}

function renderTable(programList) {
    const tbody = document.getElementById('takvimGövdesi');
    const gunler = ['pazartesi', 'sali', 'carsamba', 'persembe', 'cuma'];

    if (!programList || programList.length === 0) {
        tbody.innerHTML = `<tr><td colspan="6" class="p-8 text-center text-slate-500 italic">Henüz planlanmış bir sınav bulunmamaktadır.</td></tr>`;
        return;
    }

    // Her bir Oturum (Session) için döngü
    programList.forEach(oturumData => {
        
        // 1. OTURUM BAŞLIK SATIRI
        const oturumRow = document.createElement('tr');
        oturumRow.className = "oturum-baslik sticky top-[40px] z-10 shadow-sm"; 
        oturumRow.innerHTML = `
            <td colspan="6" class="p-2 font-extrabold text-indigo-900 border-b-2 border-indigo-200 text-xs">
                <div class="flex items-center gap-2">
                    <i data-lucide="clock" class="w-3.5 h-3.5 text-indigo-500"></i>
                    ${oturumData.oturum}
                </div>
            </td>
        `;
        tbody.appendChild(oturumRow);

        // 2. O OTURUMDAKİ DERSLİKLER İÇİN DÖNGÜ
        oturumData.derslikler.forEach(derslik => {
            const row = document.createElement('tr');
            row.className = "hover:bg-slate-50 transition-colors";
            
            // DÜZELTME 1: whitespace-nowrap silindi, kelimeler gerekirse alt satıra kaysın diye break-words eklendi
            let rowHTML = `<td class="p-2 font-bold text-slate-800 text-center bg-slate-50 border-r-2 border-slate-200 text-[10px] break-words">${derslik.ad}</td>`;

            // Günleri döngüyle kontrol et (Pzt, Sal, Çarş, Per, Cum)
            gunler.forEach(gun => {
                const sinav = derslik.gunler[gun];
                
                if (sinav) {
                    // DÜZELTME 2: Boşluklar (p-2'ler) p-1 ve p-1.5 seviyesine indirilip hücreler sıkıştırıldı
                    // line-clamp-2 eklendi: Uzun ders isimleri en fazla 2 satır görünür, fazlası ... ile kesilir
                    rowHTML += `
                        <td class="p-1 align-top">
                            <div class="bg-indigo-50/80 border border-indigo-100 p-1.5 rounded-md h-full flex flex-col justify-between gap-1 shadow-sm hover:shadow transition-shadow">
                                <p class="font-bold text-indigo-900 text-[10px] leading-tight line-clamp-2" title="${sinav.ders}">${sinav.ders}</p>
                                <div class="flex items-center gap-1 pt-1.5 border-t border-indigo-100/50 mt-1">
                                    <div class="w-3.5 h-3.5 rounded-full bg-indigo-200 flex items-center justify-center flex-shrink-0">
                                        <i data-lucide="user" class="w-2 h-2 text-indigo-700"></i>
                                    </div>
                                    <span class="text-[9px] font-semibold text-slate-600 truncate" title="${sinav.gozetmen}">${sinav.gozetmen}</span>
                                </div>
                            </div>
                        </td>
                    `;
                } else {
                    // Sınav yoksa boş tire işareti
                    rowHTML += `
                        <td class="p-1 text-center text-slate-300 align-middle">
                            -
                        </td>
                    `;
                }
            });

            row.innerHTML = rowHTML;
            tbody.appendChild(row);
        });
    });

    if (window.lucide) lucide.createIcons();
}