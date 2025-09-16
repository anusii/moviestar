# Directory Reorganization Plan

## Current Issues
1. Services directory has 30+ files with mixed responsibilities
2. Some core files are in lib/ root
3. Widgets aren't grouped by functionality
4. Multiple versions of same service scattered

## New Structure Design

### Core Infrastructure
- `lib/core/services/` - Core business logic services
  - `api/` - TMDB API and external services
  - `cache/` - Caching and persistence
  - `network/` - Network and connectivity
  - `pod/` - Solid POD operations
  - `favorites/` - User favorites management
- `lib/core/providers/` - Riverpod providers
- `lib/core/mixins/` - Shared mixins

### Feature-Based Organization
- `lib/features/movies/` - Movie browsing and details
  - `presentation/` - Screens and widgets for movies
  - `domain/` - Movie-specific business logic
- `lib/features/lists/` - Custom lists functionality
  - `presentation/` - List management UI
  - `domain/` - List operations
- `lib/features/sharing/` - Movie sharing features
  - `presentation/` - Sharing UI components
  - `domain/` - Sharing logic
- `lib/features/settings/` - Application settings
  - `presentation/` - Settings UI
  - `domain/` - Settings logic

### Shared Resources
- `lib/shared/widgets/` - Reusable UI components
- `lib/shared/utils/` - Helper functions and utilities
- `lib/shared/constants/` - App-wide constants
- `lib/shared/models/` - Data models

### Legacy Compatibility
- Keep old structure temporarily during migration
- Update imports progressively
- Ensure tests still pass

## Migration Strategy

### Phase 2.1: Service Layer Reorganization
1. Move API-related services to `core/services/api/`
2. Move cache services to `core/services/cache/`
3. Move POD services to `core/services/pod/`
4. Move favorites services to `core/services/favorites/`
5. Update imports in dependent files

### Phase 2.2: Feature Extraction
1. Extract movie-related functionality to `features/movies/`
2. Extract list functionality to `features/lists/`
3. Extract sharing functionality to `features/sharing/`
4. Extract settings functionality to `features/settings/`

### Phase 2.3: Shared Resource Organization
1. Move reusable widgets to `shared/widgets/`
2. Move utilities to `shared/utils/`
3. Move constants to `shared/constants/`
4. Move models to `shared/models/`

### Phase 2.4: Cleanup
1. Remove duplicate/unused files
2. Update all import paths
3. Verify tests still pass
4. Remove old directory structure

## File Mapping

### Services to Reorganize
- API Services → `core/services/api/`
  - api_key_service.dart (and variants)
  - movie_service.dart
  - content_service.dart
  - api_key_validation_service.dart

- Cache Services → `core/services/cache/`
  - cached_movie_service.dart
  - hive_movie_cache_service.dart
  - cache_settings_service.dart

- POD Services → `core/services/pod/`
  - pod_*.dart files (15+ files)
  - base_pod_service.dart

- Favorites Services → `core/services/favorites/`
  - favorites_service*.dart files
  - movie_list_*.dart files

- Network Services → `core/services/network/`
  - network_connectivity_service.dart
  - content_search_service.dart

### Features to Extract
- Movies Feature → `features/movies/`
  - movie_details_screen.dart
  - movie_category_screen.dart
  - movie_card.dart
  - movie_display_utils.dart

- Lists Feature → `features/lists/`
  - custom_list_detail_screen.dart
  - add_movies_to_list_screen.dart
  - my_lists_screen.dart
  - to_watch_screen.dart
  - watched_screen.dart

- Sharing Feature → `features/sharing/`
  - shared_movies_screen.dart
  - sharing/ widget directory
  - sharing_models.dart

- Settings Feature → `features/settings/`
  - settings_screen.dart
  - (will be decomposed in Phase 3)

## Benefits
1. **Clearer separation of concerns**
2. **Easier to find related code**
3. **Better maintainability**
4. **Follows feature-based architecture**
5. **Reduces large directories**
6. **Eliminates duplicate services**