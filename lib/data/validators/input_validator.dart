class InputValidator {
  // Validate task title
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Title is required';
    }
    if (value.length < 3) {
      return 'Title must be at least 3 characters';
    }
    if (value.length > 100) {
      return 'Title must not exceed 100 characters';
    }
    return null;
  }

  // Validate task description
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    if (value.length < 5) {
      return 'Description must be at least 5 characters';
    }
    if (value.length > 1000) {
      return 'Description must not exceed 1000 characters';
    }
    return null;
  }

  // Validate priority
  static String? validatePriority(int? value) {
    if (value == null || value < 1 || value > 3) {
      return 'Priority must be between 1 and 3';
    }
    return null;
  }

  // Validate category
  static String? validCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Category is required';
    }
    if (value.length > 50) {
      return 'Category must not exceed 50 characters';
    }
    return null;
  }

  // Get priority label
  static String getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Unknown';
    }
  }

  // Get priority color value (for future UI use)
  static int getPriorityColorValue(int priority) {
    switch (priority) {
      case 1:
        return 0xFF4CAF50; // Green
      case 2:
        return 0xFFFFB74D; // Orange
      case 3:
        return 0xFFE74C3C; // Red
      default:
        return 0xFF9E9E9E; // Gray
    }
  }
}
