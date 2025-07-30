// Google Address Autocomplete JavaScript module
let autocompleteInstances = {};
let googleMapsLoaded = false;
let loadingPromise = null;

export function initializeGoogleAddressAutocomplete(inputId, dotNetRef, apiKey) {
    // Load Google Maps script if not already loaded
    if (!googleMapsLoaded && !loadingPromise) {
        loadingPromise = loadGoogleMapsScript(apiKey);
    }
    
    // Wait for Google Maps to load, then initialize
    const promise = loadingPromise || Promise.resolve();
    promise.then(() => {
        setupAutocomplete(inputId, dotNetRef);
    }).catch(error => {
        console.error('Failed to load Google Maps:', error);
    });
}

function loadGoogleMapsScript(apiKey) {
    return new Promise((resolve, reject) => {
        // Check if already loaded
        if (window.google && window.google.maps && window.google.maps.places) {
            googleMapsLoaded = true;
            resolve();
            return;
        }

        // Create script element
        const script = document.createElement('script');
        script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&libraries=places&callback=initGoogleMaps`;
        script.async = true;
        script.defer = true;

        // Define callback
        window.initGoogleMaps = () => {
            googleMapsLoaded = true;
            resolve();
        };

        script.onerror = () => {
            reject(new Error('Failed to load Google Maps script'));
        };

        document.head.appendChild(script);
    });
}

function setupAutocomplete(inputId, dotNetRef) {
    const input = document.getElementById(inputId);
    if (!input) {
        console.error('Input element not found:', inputId);
        return;
    }

    // Create autocomplete instance with Australian bias
    const autocomplete = new google.maps.places.Autocomplete(input, {
        types: ['address'],
        componentRestrictions: { country: 'au' },
        fields: ['address_components', 'formatted_address', 'geometry']
    });

    // Store instance for cleanup
    autocompleteInstances[inputId] = autocomplete;

    // Listen for place selection
    autocomplete.addListener('place_changed', () => {
        const place = autocomplete.getPlace();
        
        if (!place.address_components) {
            return;
        }

        // Parse address components
        let streetNumber = '';
        let streetName = '';
        let suburb = '';
        let state = '';
        let postcode = '';
        let country = '';

        for (const component of place.address_components) {
            const types = component.types;
            
            if (types.includes('street_number')) {
                streetNumber = component.long_name;
            } else if (types.includes('route')) {
                streetName = component.long_name;
            } else if (types.includes('locality')) {
                suburb = component.long_name;
            } else if (types.includes('administrative_area_level_1')) {
                state = component.short_name;
            } else if (types.includes('postal_code')) {
                postcode = component.long_name;
            } else if (types.includes('country')) {
                country = component.long_name;
            }
        }

        // Invoke .NET method with parsed address
        dotNetRef.invokeMethodAsync('OnAddressSelected',
            streetNumber,
            streetName,
            suburb,
            state,
            postcode,
            country,
            place.formatted_address || ''
        ).catch(error => {
            console.error('Error invoking .NET method:', error);
        });
    });

    // Prevent form submission on Enter
    input.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
            e.preventDefault();
        }
    });
}

export function cleanup(inputId) {
    // Remove autocomplete instance
    if (autocompleteInstances[inputId]) {
        // Google Maps doesn't provide a destroy method, so we just remove the reference
        delete autocompleteInstances[inputId];
    }

    // Remove event listeners
    const input = document.getElementById(inputId);
    if (input) {
        // Clone node to remove all event listeners
        const newInput = input.cloneNode(true);
        input.parentNode.replaceChild(newInput, input);
    }
}