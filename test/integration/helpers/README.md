# Integration Test Helpers

This directory contains reusable infrastructure for writing integration and workflow tests in the MovieStar application.

## Overview

The test helpers eliminate code duplication, provide consistent test data, and make it easier to write comprehensive integration tests. These utilities were created as part of issue #270.

## Files

### 1. `test_data_factory.dart`
Factory for creating consistent test data across all tests.

**Key Features:**
- Sensible defaults for all test objects
- Configurable via named parameters
- Consistent, realistic test data

**Usage Examples:**

```dart
import 'helpers/test_data_factory.dart';

// Create a basic test movie
final movie = TestDataFactory.createMovie();

// Create a custom movie
final customMovie = TestDataFactory.createMovie(
  id: 999,
  title: 'Inception',
  voteAverage: 8.8,
);

// Create a TV show
final tvShow = TestDataFactory.createTVShow();

// Create a custom list
final list = TestDataFactory.createCustomList(
  name: 'My Favorites',
  movieIds: [1, 2, 3],
);

// Create multiple movies
final movies = TestDataFactory.createMovieList(count: 10);

// Create popular movies
final popularMovies = TestDataFactory.createPopularMovies();
```

### 2. `mock_services.dart`
Mock service implementations for testing without external dependencies.

**Available Mocks:**
- `MockFavoritesService` - Mocks the favorites/list management service
- `MockMovieService` - Mocks the TMDB API service

**Usage Examples:**

```dart
import 'helpers/mock_services.dart';
import 'helpers/test_data_factory.dart';

// Create and configure MockFavoritesService
final mockFavorites = MockFavoritesService();

// Add movies to lists
final movie = TestDataFactory.createMovie();
await mockFavorites.addToWatch(movie);
expect(await mockFavorites.isInToWatch(movie), isTrue);

// Set ratings
await mockFavorites.setPersonalRating(movie, 8.5);
expect(await mockFavorites.getPersonalRating(movie), equals(8.5));

// Configure for error testing
mockFavorites.configureFailure(fail: true, message: 'Network error');

// Reset state between tests
mockFavorites.reset();

// Pre-populate with test data
mockFavorites.seedData(
  toWatch: [movie1, movie2],
  watched: [movie3],
  ratings: {1: 8.5, 2: 9.0},
);
```

**MockMovieService:**

```dart
final mockMovieService = MockMovieService();

// Configure search results
mockMovieService.mockSearchResults = [movie1, movie2];
final results = await mockMovieService.searchMovies('inception');

// Configure movie details
mockMovieService.mockMovieDetails = movie;
final details = await mockMovieService.getMovieDetails(123);

// Test error scenarios
mockMovieService.configureFailure(fail: true);
```

### 3. `test_app_builder.dart`
Utilities for building test apps with proper provider setup.

**Usage Examples:**

```dart
import 'helpers/test_app_builder.dart';
import 'helpers/mock_services.dart';

// Basic test app
await tester.pumpWidget(
  buildTestApp(
    home: MyTestScreen(),
  ),
);

// Test app with mock services
final mockFavorites = MockFavoritesService();
await tester.pumpWidget(
  buildTestApp(
    home: MyTestScreen(),
    favoritesService: mockFavorites,
  ),
);

// Test app with Scaffold (for snackbars)
await tester.pumpWidget(
  buildTestAppWithScaffold(
    body: MyTestWidget(),
    appBar: AppBar(title: Text('Test')),
  ),
);

// Initialize mock SharedPreferences in setUp
setUp(() async {
  await initMockSharedPreferences();
});

// Create a real FavoritesService with mock storage
final service = await createTestFavoritesService();
```

**Navigation tracking:**

```dart
final observer = NavigationTestObserver();
await tester.pumpWidget(
  buildTestAppWithNavigationObserver(
    home: MyScreen(),
    observer: observer,
  ),
);

// Later: verify navigation
expect(observer.pushedRoutes.length, equals(2));
expect(observer.routeCount, equals(1));
```

### 4. `navigation_helpers.dart`
Helper functions for common navigation actions and assertions.

**Finder Helpers:**

```dart
import 'helpers/navigation_helpers.dart';

// Find screens
expect(findHomeScreen(), findsOneWidget);
expect(findSearchScreen(), findsOneWidget);

// Find UI elements
final movieCard = findMovieCard('Inception');
final button = findButtonByIcon(Icons.search);
```

**Navigation Actions:**

```dart
// Navigate to screens
await navigateToSearch(tester);
await navigateBack(tester);

// Interact with movies
await tapMovieCard(tester, 'Inception');
await enterSearchQuery(tester, 'action movies');
```

**Movie Actions:**

```dart
// Manage lists
await addToWatchList(tester);
await markAsWatched(tester);
await setMovieRating(tester, 8.5);
await addToCustomList(tester, 'My Favorites');
```

**Assertions:**

```dart
// Verify UI state
expectOnScreen(MovieDetailsScreen);
expectTextOnScreen('Inception');
expectIconOnScreen(Icons.bookmark);
expectWidgetExists(find.byType(Slider));
expectWidgetNotFound(find.text('Error'));
```

**Dialog Helpers:**

```dart
await waitForDialog(tester, 'Confirm');
await confirmDialog(tester);
await cancelDialog(tester);
await closeDialog(tester);
```

**Wait Helpers:**

```dart
// Wait for widgets
await waitForWidget(tester, find.text('Loaded'));
await waitForWidgetToDisappear(tester, find.byType(CircularProgressIndicator));
```

## Refactored Tests

The following tests have been refactored to use this infrastructure:

1. **`test/widgets/quick_actions_dialog_test.dart`**
   - Removed 150+ lines of inline MockFavoritesService
   - Now uses shared mock from `mock_services.dart`
   - Uses `TestDataFactory` for movie creation

2. **`test/integration/navigation_test.dart`**
   - Uses `TestDataFactory.createMovie()` instead of inline factory
   - Demonstrates the pattern for other tests

## Writing New Integration Tests

### Basic Workflow Test Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'helpers/test_app_builder.dart';
import 'helpers/test_data_factory.dart';
import 'helpers/mock_services.dart';
import 'helpers/navigation_helpers.dart';

void main() {
  group('Movie Workflow Tests', () {
    late MockFavoritesService mockFavorites;
    late MockMovieService mockMovieService;

    setUp(() {
      mockFavorites = MockFavoritesService();
      mockMovieService = MockMovieService();
    });

    testWidgets('Complete workflow: Search -> View -> Add to List',
      (WidgetTester tester) async {
        // Setup
        final movie = TestDataFactory.createMovie(title: 'Inception');
        mockMovieService.mockSearchResults = [movie];

        // Build app
        await tester.pumpWidget(
          buildTestApp(
            home: HomeScreen(),
            favoritesService: mockFavorites,
            movieService: mockMovieService,
          ),
        );

        // Navigate to search
        await navigateToSearch(tester);
        expectOnScreen(EnhancedSearchScreen);

        // Search for movie
        await enterSearchQuery(tester, 'Inception');
        expectTextOnScreen('Inception');

        // View movie details
        await tapMovieCard(tester, 'Inception');
        expectOnScreen(MovieDetailsScreen);

        // Add to watch list
        await addToWatchList(tester);

        // Verify
        expect(
          await mockFavorites.isInToWatch(movie),
          isTrue,
        );
      },
    );
  });
}
```

## Best Practices

1. **Always use TestDataFactory** for creating test objects - don't create them inline
2. **Reset mock services** between tests using `.reset()`
3. **Use navigation helpers** instead of raw `tester.tap()` for consistency
4. **Seed mock data** at the test level, not in setUp(), for clarity
5. **Use assertion helpers** for clearer test intent
6. **Document complex workflows** with comments explaining each step

## Benefits

✅ **Reduced Duplication**: Share mock services and test data across all tests
✅ **Consistency**: All tests use the same patterns and utilities
✅ **Faster Development**: Write tests 5-10x faster with helpers
✅ **Better Maintainability**: Changes to test infrastructure in one place
✅ **Clearer Tests**: Less boilerplate, focus on test logic

## Next Steps

This infrastructure enables:
- Issue #262: Core movie workflow integration tests
- Issue #260: Broader E2E user journey tests
- Future workflow and feature tests

Add new helpers to this directory as patterns emerge from writing more tests.
