function calculatePlanning() {
    const oneriListe = document.getElementById('oneriListe');
    const planResult = document.getElementById('planResult');
    
    // Not: Sayfalar ayrı olduğu için sistemVerileri dizisi 
    // yerel bellekte boş görünebilir. Gerçek projede veriler 
    // buradan bir fetch (GET) isteği ile backend'den çekilmelidir.
    
    if (sistemVerileri.derslikler.length === 0) {
        return alert("Sistemde kayıtlı derslik bulunamadı.");
    }

    const hedefKontenjan = 132; 
    let kalanOgrenci = hedefKontenjan;
    let secilenSalonlar = [];

    const siraliDerslikler = [...sistemVerileri.derslikler].sort((a, b) => b.kapasite - a.kapasite);

    for (let salon of siraliDerslikler) {
        if (kalanOgrenci <= 0) break;
        secilenSalonlar.push(salon);
        kalanOgrenci -= salon.kapasite;
    }

    oneriListe.innerHTML = '';
    secilenSalonlar.forEach((s, index) => {
        const item = document.createElement('div');
        item.className = "flex justify-between items-center p-4 bg-slate-50 border border-slate-200 rounded-xl";
        item.innerHTML = `<span>Adım ${index + 1}: <strong>${s.ad}</strong></span> <span class="text-indigo-600 font-bold">${s.kapasite} Kişi</span>`;
        oneriListe.appendChild(item);
    });

    planResult.classList.remove('hidden');
    addLog("Planlama Çalıştı", "Kapasite analizi yapıldı.", 'update');
}