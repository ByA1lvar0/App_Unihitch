const axios = require('axios');

/**
 * Servicio para cálculo de rutas usando OpenRouteService
 * Alternativa gratuita a Google Directions API
 */

// Puedes obtener una API key gratuita en https://openrouteservice.org/dev/#/signup
// O usar esta demo key (limitada, recomendado obtener tu propia key)
const ORS_API_KEY = '5b3ce3597851110001cf6248d8c0e0c3f5c14c5fa1e3e3e3e3e3e3e3'; // Demo key

const ORS_BASE_URL = 'https://api.openrouteservice.org/v2/directions/driving-car';

/**
 * Calcula una ruta entre dos puntos
 * @param {Object} origin - {lat, lng}
 * @param {Object} destination - {lat, lng}
 * @returns {Promise<Object>} - {coordinates, distance, duration}
 */
async function calculateRoute(origin, destination) {
    try {
        // OpenRouteService usa [lng, lat] (inverso a Google Maps)
        const coordinates = [
            [origin.lng, origin.lat],
            [destination.lng, destination.lat]
        ];

        const response = await axios.post(
            ORS_BASE_URL,
            {
                coordinates: coordinates,
                instructions: false,
                geometry: true
            },
            {
                headers: {
                    'Authorization': ORS_API_KEY,
                    'Content-Type': 'application/json'
                }
            }
        );

        const route = response.data.routes[0];

        // Convertir coordenadas de [lng, lat] a [lat, lng] para Leaflet
        const routeCoordinates = decodePolyline(route.geometry).map(coord => ({
            lat: coord[0],
            lng: coord[1]
        }));

        return {
            coordinates: routeCoordinates,
            distance: route.summary.distance / 1000, // metros a kilómetros
            duration: route.summary.duration / 60 // segundos a minutos
        };
    } catch (error) {
        console.error('Error calculando ruta con OpenRouteService:', error.message);

        // Fallback: ruta simple en línea recta
        return {
            coordinates: [
                { lat: origin.lat, lng: origin.lng },
                { lat: destination.lat, lng: destination.lng }
            ],
            distance: calculateDistance(origin, destination),
            duration: null // No podemos estimar sin ruta real
        };
    }
}

/**
 * Decodifica una polilínea codificada (formato Google/ORS)
 */
function decodePolyline(encoded) {
    const coords = [];
    let index = 0;
    let lat = 0;
    let lng = 0;

    while (index < encoded.length) {
        let b;
        let shift = 0;
        let result = 0;

        do {
            b = encoded.charCodeAt(index++) - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);

        const dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;

        do {
            b = encoded.charCodeAt(index++) - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);

        const dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        coords.push([lat / 1e5, lng / 1e5]);
    }

    return coords;
}

/**
 * Calcula distancia en línea recta entre dos puntos (fórmula de Haversine)
 */
function calculateDistance(point1, point2) {
    const R = 6371; // Radio de la Tierra en km
    const dLat = toRad(point2.lat - point1.lat);
    const dLon = toRad(point2.lng - point1.lng);

    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(point1.lat)) * Math.cos(toRad(point2.lat)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;

    return distance;
}

function toRad(degrees) {
    return degrees * (Math.PI / 180);
}

module.exports = {
    calculateRoute,
    calculateDistance
};
