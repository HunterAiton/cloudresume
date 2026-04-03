async function getVisitCount() {
  try {
    const response = await fetch('/api/GetResumeCounter');

    if (!response.ok) {
      throw new Error(`HTTP error: ${response.status}`);
    }

    const data = await response.json();
    const counterEl = document.getElementById('count');

    if (counterEl) {
      counterEl.textContent = data.count;
    }
  } catch (error) {
    console.error('Error fetching visitor count:', error);

    const counterEl = document.getElementById('count');
    if (counterEl) {
      counterEl.textContent = 'Unavailable';
    }
  }
}

getVisitCount();
