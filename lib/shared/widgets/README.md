# Miqra Component Library

Modern, reusable UI components for Miqra app based on **Apple HIG**, **Notion**, and **WhatsApp** design principles.

## Table of Contents

- [Installation](#installation)
- [Components](#components)
  - [MiqraCard](#miqracard)
  - [MiqraLoading](#miqraloading)
  - [MiqraEmptyState](#miqraemptystate)
- [Design Tokens](#design-tokens)
- [Examples](#examples)

---

## Installation

Import the component library:

```dart
import 'package:miqra_flutter/shared/widgets/miqra_components.dart';
```

Or import individual components:

```dart
import 'package:miqra_flutter/shared/widgets/miqra_card.dart';
import 'package:miqra_flutter/shared/widgets/miqra_loading.dart';
```

---

## Components

### MiqraCard

Beautiful, flat card component with subtle borders (no shadows).

#### Variants

**1. Default Card**
```dart
MiqraCard(
  child: Text('Hello World'),
  onTap: () => print('Tapped'),
)
```

**2. Filled Card** (colored background)
```dart
MiqraCard.filled(
  backgroundColor: MiqraColors.primaryLight,
  child: Text('Filled card'),
)
```

**3. Outlined Card** (emphasized border)
```dart
MiqraCard.outlined(
  outlineColor: MiqraColors.primary,
  child: Text('Outlined card'),
)
```

**4. Compact Card** (reduced padding)
```dart
MiqraCard.compact(
  child: Text('Compact card'),
)
```

#### MiqraIconCard

Pre-built card for stats/info display:

```dart
MiqraIconCard(
  icon: Icons.star,
  iconColor: MiqraColors.accent,
  title: 'Hasanat',
  value: '120',
  onTap: () => print('Tapped'),
)
```

#### MiqraListCard

Pre-built card for list items:

```dart
MiqraListCard(
  leading: Icon(Icons.book),
  title: 'Al-Fatihah',
  subtitle: 'The Opening - 7 Ayat',
  trailing: Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () => Navigator.push(...),
)
```

---

### MiqraLoading

Consistent loading indicators across the app.

#### Variants

**1. Default Loading**
```dart
MiqraLoading()
```

**2. Loading with Message**
```dart
MiqraLoading.withMessage(
  message: 'Loading Quran...',
)
```

**3. Inline Loading** (smaller, for inline use)
```dart
MiqraLoading.inline()
```

#### MiqraProgressBar

Linear progress indicator:

```dart
MiqraProgressBar(
  value: 0.7, // 70% complete
  color: MiqraColors.primary,
)
```

#### MiqraSkeleton

Shimmer loading placeholders:

```dart
// Text skeleton
MiqraSkeleton.text(width: 200)

// Circle skeleton (avatar)
MiqraSkeleton.circle(size: 40)

// Card skeleton
MiqraSkeleton.card(height: 120)

// Custom skeleton
MiqraSkeleton(
  width: 150,
  height: 30,
  borderRadius: BorderRadius.circular(8),
)
```

---

### MiqraEmptyState

Beautiful empty states with icons and optional actions.

#### Variants

**1. Full Empty State**
```dart
MiqraEmptyState(
  icon: Icons.book_outlined,
  title: 'No bookmarks yet',
  description: 'Start bookmarking your favorite ayahs',
  actionLabel: 'Browse Quran',
  onAction: () => Navigator.push(...),
)
```

**2. Compact Empty State** (for sections)
```dart
MiqraEmptyStateCompact(
  icon: Icons.calendar_today,
  message: 'No activities today',
)
```

---

## Design Tokens

All components use the Miqra design system:

### Typography
```dart
MiqraTextStyles.display   // 32px, bold
MiqraTextStyles.title1    // 24px, semibold
MiqraTextStyles.title2    // 20px, semibold
MiqraTextStyles.headline  // 16px, semibold
MiqraTextStyles.body      // 15px, regular
MiqraTextStyles.caption   // 13px, regular
MiqraTextStyles.label     // 11px, medium
```

### Spacing
```dart
MiqraSpacing.xxs   // 4px
MiqraSpacing.xs    // 8px
MiqraSpacing.sm    // 12px
MiqraSpacing.md    // 16px (default)
MiqraSpacing.lg    // 24px
MiqraSpacing.xl    // 32px
MiqraSpacing.xxl   // 48px
```

### Colors
```dart
MiqraColors.textPrimary    // Headlines
MiqraColors.textSecondary  // Body text
MiqraColors.textTertiary   // Labels

MiqraColors.bgPrimary      // White
MiqraColors.bgSecondary    // Off-white
MiqraColors.bgTertiary     // Light gray

MiqraColors.primary        // Turquoise
MiqraColors.secondary      // Coral
MiqraColors.accent         // Gold

MiqraColors.borderLight    // Subtle border
```

---

## Examples

### Stat Cards Grid

```dart
Row(
  children: [
    Expanded(
      child: MiqraIconCard(
        icon: Icons.stars,
        iconColor: MiqraColors.accent,
        title: 'Hasanat',
        value: '1,250',
      ),
    ),
    SizedBox(width: MiqraSpacing.sm),
    Expanded(
      child: MiqraIconCard(
        icon: Icons.book,
        iconColor: MiqraColors.primary,
        title: 'Ayat Dibaca',
        value: '45',
      ),
    ),
  ],
)
```

### List with Cards

```dart
ListView.separated(
  padding: MiqraSpacing.screenPadding,
  itemCount: items.length,
  separatorBuilder: (context, index) => MiqraSpacing.gapSM,
  itemBuilder: (context, index) {
    final item = items[index];
    return MiqraListCard(
      leading: Icon(Icons.book),
      title: item.title,
      subtitle: item.subtitle,
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => onTap(item),
    );
  },
)
```

### Async Data Display

```dart
asyncData.when(
  data: (data) => ListView(...),
  loading: () => MiqraLoading.withMessage(
    message: 'Loading data...',
  ),
  error: (_, __) => MiqraEmptyState(
    icon: Icons.error_outline,
    title: 'Failed to load',
    description: 'Please try again',
    actionLabel: 'Retry',
    onAction: () => ref.refresh(provider),
  ),
)
```

### Skeleton Loading

```dart
// While data is loading
Column(
  children: [
    MiqraSkeleton.card(),
    MiqraSpacing.gapSM,
    MiqraSkeleton.text(),
    MiqraSpacing.gapXS,
    MiqraSkeleton.text(width: 150),
  ],
)
```

---

## Design Principles

### ✅ Do

- Use `MiqraCard` instead of `Card` widget
- Use `MiqraLoading` instead of `CircularProgressIndicator`
- Use design tokens (`MiqraSpacing`, `MiqraTextStyles`, `MiqraColors`)
- Provide empty states for all data lists
- Show loading states for async operations

### ❌ Don't

- Don't use inline styles (use `MiqraTextStyles`)
- Don't use random spacing values (use `MiqraSpacing`)
- Don't use `Colors.grey[600]` (use `MiqraColors.textSecondary`)
- Don't use `elevation` (flat design principle)
- Don't leave empty states blank (use `MiqraEmptyState`)

---

## Migration Guide

### Before (Old)
```dart
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text(
      'Hello',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
    ),
  ),
)
```

### After (New)
```dart
MiqraCard(
  child: Text(
    'Hello',
    style: MiqraTextStyles.body.copyWith(
      color: MiqraColors.textSecondary,
    ),
  ),
)
```

**Benefits:**
- ✅ Consistent design (flat, no shadow)
- ✅ Less boilerplate code
- ✅ Automatic theme updates
- ✅ Easier to maintain

---

## Contributing

When creating new components:

1. Use design tokens (`MiqraSpacing`, `MiqraTextStyles`, `MiqraColors`)
2. Follow flat design (no `elevation`)
3. Provide variants (e.g., `.compact`, `.outlined`)
4. Document with examples
5. Test on multiple screen sizes

---

## Support

For questions or issues, contact the Miqra development team.
