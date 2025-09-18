#!/bin/bash
# Restore files that were broken by the print cleanup

echo "🔄 Restoring files from backups..."

# Files that were cleaned by the print cleanup script
files_to_restore=(
    "lib/core/services/favorites/movie_list_file_helper.dart"
    "lib/core/services/network/content_search_service.dart"
    "lib/utils/network_client.dart"
    "lib/utils/turtle/turtle_user_profile_serializer.dart"
    "lib/screens/enhanced_search_screen.dart"
    "lib/screens/my_lists_screen.dart"
    "lib/providers/cached_movie_service_provider.dart"
)

for file in "${files_to_restore[@]}"; do
    filename=$(basename "$file")
    backup_file="scripts/backups/${filename}_1758161027.backup"

    if [ -f "$backup_file" ]; then
        echo "Restoring: $file"
        cp "$backup_file" "$file"
    else
        echo "⚠️  Backup not found for: $file"
    fi
done

echo "✅ File restoration completed!"