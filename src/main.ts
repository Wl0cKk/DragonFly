async function scanCameras() {
  const response = await fetch('/scan', { method: 'POST' });
  const cameras = await response.json();
  const cameraList = document.getElementById('cameraList') as HTMLSelectElement;
  cameraList.innerHTML = '';
  cameras.forEach((c: string) => {
    const option = document.createElement('option');
    option.value = c;
    option.textContent = c;
    cameraList.appendChild(option);
  });
}

async function addCamera() {
  const url = (document.getElementById('rtspUrl') as HTMLInputElement).value;
  const username = (document.getElementById('username') as HTMLInputElement).value;
  const password = (document.getElementById('password') as HTMLInputElement).value;
  await fetch('/add_camera', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ url, username, password })
  });
}

(document.getElementById('scanButton') as HTMLButtonElement).onclick = scanCameras;
(document.getElementById('addCameraButton') as HTMLButtonElement).onclick = addCamera;
