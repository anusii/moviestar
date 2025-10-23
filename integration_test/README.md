# ⚠️ Testing Setup Required

Before running the tests, you need to create your own TMDB API key
file:

1. Copy the template:

```bash
cp integration_test/fixtures/tmdb_api_key.json.template integration_test/fixtures/tmdb_api_key.json
```

2. Add your TMDB API key to `integration_test/fixtures/tmdb_api_key.json`:

```json
  {
    "apiKey": "YOUR_ACTUAL_TMDB_API_KEY_HERE"
  }
```

3. Get a free API key from: https://www.themoviedb.org/settings/api


Note: The tmdb_api_key.json file is gitignored and won't be
committed. Each developer needs their own API key.
