// Configuración
const API_BASE_URL = 'http://localhost:3000/api';
const REFRESH_INTERVAL = 10000; // 10 segundos

// Estado global
let map;
let markers = {};
let polylines = {};
let trips = [];
let selectedTripId = null;
let refreshTimer;

// Inicializar mapa
function initMap() {
    // Crear mapa centrado en una ubicación por defecto (Colombia)
    map = L.map('map').setView([4.7110, -74.0721], 13);

    // Agregar capa de OpenStreetMap
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 19
    }).addTo(map);

    console.log('Mapa inicializado');
}

// Cargar viajes
async function loadTrips() {
    try {
        const statusFilter = document.querySelector('input[name="status"]:checked').value;

        // Obtener rutas activas
        const response = await fetch(`${API_BASE_URL}/routes/active/all`);

        if (!response.ok) {
            throw new Error('Error al cargar viajes');
        }

        const data = await response.json();
        trips = data;

        // Filtrar según estado seleccionado
        let filteredTrips = trips;
        if (statusFilter !== 'all') {
            filteredTrips = trips.filter(trip => trip.estado === statusFilter);
        }

        displayTrips(filteredTrips);
        displayRoutesOnMap(filteredTrips);
    } catch (error) {
        console.error('Error cargando viajes:', error);
        document.getElementById('tripsList').innerHTML =
            '<p class="loading">Error al cargar viajes. Verifica que el servidor esté corriendo.</p>';
    }
}

// Mostrar viajes en la lista
function displayTrips(trips) {
    const tripsList = document.getElementById('tripsList');

    if (trips.length === 0) {
        tripsList.innerHTML = '<p class="loading">No hay viajes disponibles</p>';
        return;
    }

    tripsList.innerHTML = trips.map(trip => {
        const statusClass = trip.estado === 'DISPONIBLE' ? 'disponible' : 'en-curso';
        const statusText = trip.estado === 'DISPONIBLE' ? 'Disponible' : 'En Curso';

        return `
            <div class="trip-card ${selectedTripId === trip.id_viaje ? 'active' : ''}" 
                 onclick="selectTrip(${trip.id_viaje})">
                <div class="trip-card-header">
                    <strong>${trip.conductor_nombre}</strong>
                    <span class="trip-status ${statusClass}">${statusText}</span>
                </div>
                <div class="trip-route">
                    <strong>Origen:</strong> ${trip.origen}<br>
                    <strong>Destino:</strong> ${trip.destino}
                </div>
                <div class="trip-meta">
                    ${trip.distancia_km ? `<span>📏 ${trip.distancia_km.toFixed(1)} km</span>` : ''}
                    ${trip.duracion_minutos ? `<span>⏱️ ${Math.round(trip.duracion_minutos)} min</span>` : ''}
                </div>
            </div>
        `;
    }).join('');
}

// Mostrar rutas en el mapa
function displayRoutesOnMap(trips) {
    // Limpiar marcadores y polilíneas anteriores
    Object.values(markers).forEach(marker => map.removeLayer(marker));
    Object.values(polylines).forEach(polyline => map.removeLayer(polyline));
    markers = {};
    polylines = {};

    if (trips.length === 0) return;

    const bounds = [];

    trips.forEach(trip => {
        if (trip.coordenadas) {
            const coordinates = JSON.parse(trip.coordenadas);

            // Crear polilínea para la ruta
            const polyline = L.polyline(
                coordinates.map(coord => [coord.lat, coord.lng]),
                {
                    color: trip.estado === 'EN_CURSO' ? '#f59e0b' : '#667eea',
                    weight: 4,
                    opacity: 0.7
                }
            ).addTo(map);

            polylines[trip.id_viaje] = polyline;

            // Agregar marcadores de inicio y fin
            if (coordinates.length > 0) {
                const start = coordinates[0];
                const end = coordinates[coordinates.length - 1];

                // Marcador de inicio (verde)
                const startMarker = L.marker([start.lat, start.lng], {
                    icon: L.divIcon({
                        className: 'custom-marker',
                        html: '🚩',
                        iconSize: [40, 40]
                    })
                }).addTo(map);
                startMarker.bindPopup(`<b>Origen:</b> ${trip.origen}`);

                // Marcador de destino (rojo)
                const endMarker = L.marker([end.lat, end.lng], {
                    icon: L.divIcon({
                        className: 'custom-marker',
                        html: '🎯',
                        iconSize: [40, 40]
                    })
                }).addTo(map);
                endMarker.bindPopup(`<b>Destino:</b> ${trip.destino}`);

                bounds.push([start.lat, start.lng]);
                bounds.push([end.lat, end.lng]);
            }
        }
    });

    // Ajustar vista del mapa para mostrar todas las rutas
    if (bounds.length > 0) {
        map.fitBounds(bounds, { padding: [50, 50] });
    }
}

// Seleccionar viaje
function selectTrip(tripId) {
    selectedTripId = tripId;
    const trip = trips.find(t => t.id_viaje === tripId);

    if (!trip) return;

    // Actualizar lista de viajes
    document.querySelectorAll('.trip-card').forEach(card => {
        card.classList.remove('active');
    });
    event.target.closest('.trip-card').classList.add('active');

    // Mostrar información del viaje
    showTripInfo(trip);

    // Centrar mapa en la ruta
    if (polylines[tripId]) {
        map.fitBounds(polylines[tripId].getBounds(), { padding: [50, 50] });
    }
}

// Mostrar información del viaje
function showTripInfo(trip) {
    const tripInfo = document.getElementById('tripInfo');
    const tripDetails = document.getElementById('tripDetails');

    tripDetails.innerHTML = `
        <div class="info-row">
            <div class="info-label">Conductor</div>
            <div class="info-value">${trip.conductor_nombre}</div>
        </div>
        <div class="info-row">
            <div class="info-label">Origen</div>
            <div class="info-value">${trip.origen}</div>
        </div>
        <div class="info-row">
            <div class="info-label">Destino</div>
            <div class="info-value">${trip.destino}</div>
        </div>
        ${trip.distancia_km ? `
        <div class="info-row">
            <div class="info-label">Distancia</div>
            <div class="info-value">${trip.distancia_km.toFixed(2)} km</div>
        </div>
        ` : ''}
        ${trip.duracion_minutos ? `
        <div class="info-row">
            <div class="info-label">Duración Estimada</div>
            <div class="info-value">${Math.round(trip.duracion_minutos)} minutos</div>
        </div>
        ` : ''}
        <div class="info-row">
            <div class="info-label">Estado</div>
            <div class="info-value">${trip.estado}</div>
        </div>
        <div class="info-row">
            <div class="info-label">Fecha</div>
            <div class="info-value">${new Date(trip.fecha_hora).toLocaleString('es-CO')}</div>
        </div>
    `;

    tripInfo.classList.remove('hidden');
}

// Cerrar información del viaje
function closeTripInfo() {
    document.getElementById('tripInfo').classList.add('hidden');
    selectedTripId = null;

    // Quitar selección de tarjetas
    document.querySelectorAll('.trip-card').forEach(card => {
        card.classList.remove('active');
    });
}

// Iniciar actualización automática
function startAutoRefresh() {
    refreshTimer = setInterval(loadTrips, REFRESH_INTERVAL);
}

// Detener actualización automática
function stopAutoRefresh() {
    if (refreshTimer) {
        clearInterval(refreshTimer);
    }
}

// Event Listeners
document.addEventListener('DOMContentLoaded', () => {
    initMap();
    loadTrips();
    startAutoRefresh();

    // Botón de actualizar
    document.getElementById('refreshBtn').addEventListener('click', loadTrips);

    // Filtros de estado
    document.querySelectorAll('input[name="status"]').forEach(radio => {
        radio.addEventListener('change', loadTrips);
    });
});

// Limpiar al salir
window.addEventListener('beforeunload', () => {
    stopAutoRefresh();
});
