# Database Foundation - Drift Implementation

This directory contains the Drift database foundation for local movie data
caching in the Movie Star application.

## Overview

The database foundation implements a three-table schema designed to
efficiently cache movie data retrieved from TMDB API, reducing unnecessary
network calls and improving app performance.

## Database Schema

### Tables

1. **`movies`** - Stores individual movie records
   - `id` (Primary Key) - Movie ID from TMDB
   - `title` - Movie title
   - `overview` - Movie description
   - `posterPath` - Relative path to poster image
   - `backdropPath` - Relative path to backdrop image
   - `voteAverage` - Movie rating
   - `releaseDate` - Release date
   - `genreIds` - JSON array of genre IDs
   - `cachedAt` - Timestamp when cached

2. **`movie_categories`** - Maps movies to categories with ordering
   - `id` (Primary Key, Auto-increment)
   - `movieId` (Foreign Key) - References movies.id
   - `category` - Category name (popular, now_playing, top_rated, upcoming)
   - `position` - Order position within category
   - `cachedAt` - Timestamp when cached

3. **`cache_metadata`** - Tracks cache freshness per category
   - `category` (Primary Key) - Category identifier
   - `lastUpdated` - When this category was last refreshed
   - `movieCount` - Number of movies in this category

## Key Features

### Cache Management

- **Category-based caching**:
Each movie category (popular, now_playing, etc.)
is cached separately

- **Position preservation**:
Movies maintain their API order within categories

- **Expiration checking**:
Built-in cache validity checking with configurable
duration

- **Atomic updates**:
All cache operations use database transactions

### Performance Optimisations

- **Conflict resolution**:
`insertOnConflictUpdate` prevents duplicate entries

- **Efficient queries**:
Uses proper JOIN operations for category retrieval

- **Background database**:
Uses `NativeDatabase.createInBackground()` for
performance

### Data Integrity

- **Foreign keys**:
Proper relationships between movies and categories

- **JSON encoding**:
Genre IDs stored as JSON for flexible querying

- **Timestamp tracking**:
Automatic timestamps for cache management

## Usage

### Database Access

```dart
// Using Riverpod provider
final database = ref.read(databaseProvider);

// Cache movies for a category
await database.cacheMoviesForCategory('popular', movieList);

// Retrieve cached movies
final movies = await database.getCachedMoviesForCategory('popular');

// Check cache validity
final isValid = await database.isCacheValid('popular', Duration(hours: 1));
```

### Cache Constants

```dart
// Use predefined category constants
MovieCategories.popular
MovieCategories.nowPlaying
MovieCategories.topRated
MovieCategories.upcoming

// Use predefined cache durations
CacheDuration.defaultDuration  // 1 hour
CacheDuration.shortDuration    // 15 minutes
CacheDuration.longDuration     // 24 hours
```

## Database File Location

The SQLite database file is stored at:

- **Path**:
`{ApplicationDocumentsDirectory}/moviestar.db`

- **Platform-specific**:
Uses `path_provider` for cross-platform compatibility

## Code Generation

This implementation uses Drift's code generation. To regenerate files after
schema changes:

```bash
flutter pub run build_runner build
```

## Integration Points

The database foundation is designed to integrate with:

1. **Movie Service**:
The next ticket will implement cached layer

2. **Riverpod Providers**:
Database provider is ready for dependency injection

3. **Existing Models**:
Works seamlessly with current `Movie` model

## Files

- `app_database.dart` - Main database schema and operations
- `app_database.g.dart` - Generated Drift code (auto-generated)
- `../providers/database_provider.dart` - Riverpod provider
- `../constants/cache_constants.dart` - Cache-related constants

## Next Steps (Future Tickets)

1. **Cached Movie Service** - Implement service layer that uses this database
2. **Cache Statistics** - Add cache hit/miss tracking
3. **Cache Cleanup** - Implement automatic old data cleanup
4. **Performance Monitoring** - Add database performance metrics
