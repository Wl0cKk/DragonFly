async function scanCameras() {
    const loadingModal = document.getElementById('loadingModal') as HTMLDivElement;
    loadingModal.style.display = 'flex';

    try {
        const response = await fetch('/scan', { method: 'POST' });
        const cameras: string[] = await response.json();
        const cameraList = document.getElementById('cameraList') as HTMLSelectElement;
        cameraList.innerHTML = '';
        cameras.forEach((ip: string) => {
            const option = document.createElement('option');
            option.value = ip;
            option.textContent = ip;
            cameraList.appendChild(option);
        });
        if (cameras.length > 0) {
            (document.getElementById('rtspUrl') as HTMLInputElement).value = `rtsp://${cameras[0]}:554/`;
        }
        cameraList.onchange = () => {
            const selectedIp = cameraList.value;
            (document.getElementById('rtspUrl') as HTMLInputElement).value = selectedIp ? `rtsp://${selectedIp}:554/` : '';
        };
    } catch (error) {
        alert(`Failed to fetch cameras: ${error}`);
    } finally {
        loadingModal.style.display = 'none';
    }
}

async function addCamera() {
    const rtspUrlInput = document.getElementById('rtspUrl') as HTMLInputElement | null;
    const usernameInput = document.getElementById('username') as HTMLInputElement | null;
    const passwordInput = document.getElementById('password') as HTMLInputElement | null;
    if (!rtspUrlInput?.value.trim() || !usernameInput?.value.trim() || !passwordInput?.value.trim()) {
        alert("Please fill in all fields.");
        return;
    }
    const url = rtspUrlInput.value;
    const username = usernameInput.value;
    const password = passwordInput.value;
    const response = await fetch('/add_camera', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url, username, password })
    });
    if (!response.ok) {
        const errorText = await response.text();
        alert(`ERR: ${errorText}`);
    } else {
        alert("Added successfully!");
        rtspUrlInput.value = '';
        usernameInput.value = '';
        passwordInput.value = '';
        await updateCameraList();
        console.log('Camera list updated.');
    }
}

async function updateCameraList() {
    const response = await fetch('/camera_show_list');
    const cameras: { name: string; ip: string }[] = await response.json();
    const cameraContainer = document.getElementById('cameraListContainer');
    
    if (cameraContainer) {
        cameraContainer.innerHTML = '';
        cameras.forEach((cam) => {
            const cameraDiv = document.createElement('div');
            cameraDiv.className = 'camera_list';
            cameraDiv.innerHTML = `
                <h3>${cam.name}</h3>
                <div id="h_menu">
                    <input type="text" value="${cam.ip}" disabled>
                    <button class="singleStream">Stream</button>
                    <button class="editCameraButton">Edit</button>
                    <button class="deleteCameraButton">Delete</button>
                </div>
            `;
            cameraContainer.appendChild(cameraDiv);
        });
    } else {
        console.error('Camera list container not found.');
    }
}

(document.getElementById('scanButton') as HTMLButtonElement).onclick = scanCameras;
(document.getElementById('addCameraButton') as HTMLButtonElement).onclick = addCamera;

document.addEventListener('DOMContentLoaded', updateCameraList);
