# Google Address Autocomplete Setup

This guide explains how to enable Google Places Autocomplete for address entry in the Steel Estimation Platform.

## Features

- **Full address autocomplete** - Type-ahead suggestions as users enter addresses
- **Automatic field population** - Street number, street name, suburb, state, and postcode are automatically filled
- **Australian addresses only** - Restricted to Australian addresses for relevance
- **Fallback to manual entry** - Users can still enter addresses manually if needed
- **Uppercase conversion** - All text automatically converts to uppercase

## Setup Instructions

### 1. Get a Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Places API** and **Maps JavaScript API**
4. Create credentials (API Key)
5. Restrict the API key:
   - Application restrictions: HTTP referrers
   - Website restrictions: Add your domain(s)
   - API restrictions: Places API, Maps JavaScript API

### 2. Configure the Application

Add your API key to `appsettings.json`:

```json
"GoogleMaps": {
  "ApiKey": "YOUR_GOOGLE_MAPS_API_KEY_HERE",
  "EnableAutocomplete": true
}
```

For production, store the API key in Azure Key Vault:
- Key name: `GoogleMaps--ApiKey`

### 3. How It Works

When enabled, the address forms will show:
1. A single "Search Address" field at the top
2. As users type, Google suggests matching addresses
3. When an address is selected, all fields are auto-populated
4. Users can still manually edit any field

### 4. Fallback Options

If Google Maps is not configured:
- The system falls back to the local postcode lookup
- Users can search by postcode or suburb name
- Manual entry is always available

## Cost Considerations

Google Maps Platform offers:
- **$200 USD free credit** per month
- **Places Autocomplete**: $2.83 per 1,000 requests
- **Place Details**: $17.00 per 1,000 requests (only charged when user selects)

With the free credit, you get approximately:
- 11,000+ autocomplete sessions per month free
- Monitor usage in Google Cloud Console

## Security

- Never commit API keys to source control
- Use environment-specific configuration
- Restrict API keys by domain and API
- Monitor usage for unusual activity

## Testing

To test without enabling globally:
1. Set `EnableAutocomplete: false` in appsettings.json
2. Pass the API key directly to specific components for testing

## Troubleshooting

If autocomplete isn't working:
1. Check browser console for errors
2. Verify API key is correct
3. Ensure Places API is enabled in Google Cloud Console
4. Check API key restrictions match your domain
5. Verify billing is enabled on Google Cloud account