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

async function deleteCamera(cameraId: string) {
    const response = await fetch(`/delete_camera/${cameraId}`, { method: 'DELETE' });
    if (!response.ok) {
        alert(`Failed to delete camera: ${cameraId}`);
    } else {
        await updateCameraList();
        alert(`Camera ${cameraId} deleted successfully.`);
    }
}

async function applyChanges(cameraId: string) {
    const urlInput = document.getElementById(`url-${cameraId}`) as HTMLInputElement;
    const usernameInput = document.getElementById(`username-${cameraId}`) as HTMLInputElement;
    const passwordInput = document.getElementById(`password-${cameraId}`) as HTMLInputElement;
    const data = {
        url: urlInput.value,
        username: usernameInput.value,
        password: passwordInput.value
    };
    const response = await fetch(`/update_camera/${cameraId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
    if (!response.ok) {
        const errorText = await response.text();
        alert(`Failed to update camera: ${errorText}`);
    } else {
        alert(`Updated camera ${cameraId} successfully.`);
        await updateCameraList();
    }
}

async function updateCameraList() {
    const response = await fetch('/camera_show_list');
    const cameras: { name: string; ip: string; username: string; password: string; url: string; }[] = await response.json();
    const cameraContainer = document.getElementById('cameraListContainer');
    if (!cameraContainer) {
    	console.error('Camera list container not found.');
    } else {
        cameraContainer.innerHTML = '';
        cameras.forEach((cam) => {
            const cameraDiv = document.createElement('div');
            cameraDiv.className = 'camera-section';
            cameraDiv.innerHTML = `
                <div class="camera-header" onclick="toggleDetails('${cam.name}')">
                    <h3>${cam.name}</h3>
                    <div class="toggle-arrow" id="arrow-${cam.name}"></div>
                </div>
                <div class="camera-details" id="details-${cam.name}" style="display: none;">
                    <div id="h_menu">
                        <input type="text" id="url-${cam.name}" value="${cam.url}" placeholder="RTSP URL"/>
                        <button class="streamButton">Stream</button>
                        <button class="deleteButton" onclick="deleteCamera('${cam.name}')">Delete</button>
                    </div>
                    <div id="auth_menu">
                        <input type="text" id="username-${cam.name}" value="${cam.username}" placeholder="Username"/>
                        <input type="password" id="password-${cam.name}" value="${cam.password}" placeholder="Password"/>
                        <button class="applyButton" id="apply-${cam.name}" style="display: none;" onclick="applyChanges('${cam.name}')">Apply</button>
                    </div>
                </div>
            `;
            cameraContainer.appendChild(cameraDiv);
            const urlInput = document.getElementById(`url-${cam.name}`) as HTMLInputElement;
            const usernameInput = document.getElementById(`username-${cam.name}`) as HTMLInputElement;
            const passwordInput = document.getElementById(`password-${cam.name}`) as HTMLInputElement;
            [urlInput, usernameInput, passwordInput].forEach(input => {
                input.addEventListener('input', function() {
                    const applyButton = document.getElementById(`apply-${cam.name}`) as HTMLButtonElement;
                    applyButton.style.display = "inline-block";
                    const deleteButton = document.querySelector(`.deleteButton[onclick*="${cam.name}"]`) as HTMLButtonElement;
                    deleteButton.style.display = "none";
                });
            });
        });
    }
}

function toggleDetails(cameraId: string) {
    const details = document.getElementById(`details-${cameraId}`) as HTMLDivElement;
    const arrow = document.getElementById(`arrow-${cameraId}`) as HTMLDivElement;
    if (details.style.display === "none") {
        details.style.display = "block";
        arrow.style.transform = "rotate(180deg)";
    } else {
        details.style.display = "none";
        arrow.style.transform = "rotate(270deg)";
    }
}

(document.getElementById('scanButton') as HTMLButtonElement).onclick = scanCameras;
(document.getElementById('addCameraButton') as HTMLButtonElement).onclick = addCamera;

document.addEventListener('DOMContentLoaded', updateCameraList);
