// --- ORTAK AYARLAR & STATE ---
const BASE_URL = "https://prong-unsterile-flashy.ngrok-free.dev"; 

let sistemVerileri = {
    derslikler: [], 
    hocalar: [],   
    mazeretler: [],
    dersler: []   
};

// --- LOGLAMA SİSTEMİ ---
function addLog(title, detail, type) {
    const list = document.getElementById('recentActivityList');
    if (!list) return;
    const emptyMsg = list.querySelector('p');
    if (emptyMsg) emptyMsg.remove();

    const logItem = document.createElement('div');
    logItem.className = "p-4 rounded-2xl bg-slate-50 border border-slate-100 flex gap-4 animate-fade-in";
    const iconColor = type === 'add' ? 'text-emerald-600' : 'text-amber-600';
    const iconName = type === 'add' ? 'plus-circle' : 'alert-circle';

    logItem.innerHTML = `
        <div class="p-2 bg-white rounded-lg shadow-sm ${iconColor}">
            <i data-lucide="${iconName}" class="w-4 h-4"></i>
        </div>
        <div class="flex-1 text-sm">
            <p class="font-bold text-slate-800">${title}</p>
            <p class="text-slate-500">${detail}</p>
            <p class="text-[10px] text-slate-300 mt-2 font-mono">${new Date().toLocaleTimeString()}</p>
        </div>
    `;
    list.prepend(logItem);
    if (window.lucide) lucide.createIcons();
}

// Sekme geçişleri için (Eğer link yerine eski showTab kullanılıyorsa)
function showTab(tabId, element) {
    document.querySelectorAll('.tab-content').forEach(tab => tab.classList.remove('active'));
    const target = document.getElementById(tabId);
    if (target) target.classList.add('active');
}