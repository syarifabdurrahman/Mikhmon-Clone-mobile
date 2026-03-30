# ΩMMON - Open Mikrotik Monitor - Progress Tracker

> **App Name**: ΩMMON (Open Mikrotik Monitor)
> **Package**: `com.simpurrapps.ommon`
> **Flutter**: SDK ^3.6.0

---

## ✅ Already Implemented

| Feature | Status | Notes |
| --------------------------- | ------ | ----------------------------------------------------- |
| **Login System** | ✅ | RouterOS API (port 8728), demo mode toggle |
| **Dashboard** | ✅ | **Real-time line chart** with CPU/Memory/Disk, auto-scrolls right-to-left |
| **Resource History** | ✅ | **60+ data points** (unlimited history), animated updates, accurate elapsed time labels |
| **Interface Traffic** | ✅ | **Network monitoring** widget showing TX/RX bytes and rates |
| **Local Caching** | ✅ | **Hive database** for offline support & instant load |
| **Seamless Navigation** | ✅ | **Provider keepAlive** for smooth transitions, no hiccups |
| **Seamless Login** | ✅ | **Pre-fetch data** during login, instant dashboard |
| **Initial Load Indicator** | ✅ | **Lazy loading** with "Loading dashboard..." for first-time fetch |
| **Hotspot Users** | ✅ | CRUD (Create, Read, Update, Delete) |
| **User Filtering** | ✅ | Search and status filter |
| **Hotspot Active Users** | ✅ | Real-time monitoring, auto-refresh (5s), force logout |
| **User Profiles** | ✅ | Rate limit, validity, price, shared users, auto logout |
| **Demo Mode** | ✅ | Simulated data with Riverpod state management |
| **User Details Screen** | ✅ | View user statistics and info |
| **Edit User Screen** | ✅ | Update user profiles |
| **Add User Screen** | ✅ | Create new hotspot users |
| **Performance Optimizations** | ✅ | RepaintBoundary, itemExtent, widget extraction |
| **Voucher Generation** | ✅ | Bulk user creation with custom username format |
| **Voucher QR Codes** | ✅ | QR code generation with copy, share, and print |
| **Voucher Preview** | ✅ | Show all generated vouchers with summary and actions |
| **Batch Operations** | ✅ | Delete, enable, disable, move multiple users |
| **Long-press Selection** | ✅ | Select multiple users from list |
| **Convex Bottom Nav** | ✅ | Curved navigation bar with animated center |
| **Revenue Dashboard** | ✅ | Charts, profile breakdown, transaction history |
| **Responsive Design** | ✅ | LayoutBuilder for adaptive UI on all screens |
| **Modern UI Theme** | ✅ | **Poppins font**, Material 3, vibrant colors |
| **Hotspot Hosts** | ✅ | DHCP lease/binding monitoring with search & filters |
| **Concurrent Fetch Protection** | ✅ | **_isFetching flag** prevents race conditions |
| **Data Validation** | ✅ | **_safeString()** helper handles null/empty strings |
| **Graph Time Formatting** | ✅ | **Accurate elapsed time** (30s, 2m, 3m30s, 1h15m, etc.) |
| **Continuous Scrolling** | ✅ | **Unlimited graph scrolling** (removed 60.0 clamp) |
| **Voucher Bulk Delete** | ✅ | Select and delete multiple vouchers at once |
| **Voucher Templates** | ✅ | Full Size, Compact, and Minimal print templates |
| **Sales Report Export** | ✅ | CSV export with date filtering and profile filter |
| **Performance Optimization** | ✅ | Memory leaks fixed, const constructors, reusable filter utilities |
| **DRY Code** | ✅ | FilterUtils for consistent filtering across the app |

---

## 🆕 Recent Updates (March 30, 2026)

### 1. App Localization (i18n) ✅
**Complete localization support for English, Indonesian, and Malay languages**

- **Central Translation File**: Created `lib/l10n/translations.dart` with 100+ translation keys
- **Pattern**: Used `AppStrings.of(context).keyName` for all user-facing strings
- **Languages Supported**:
  - English (en) - Default
  - Indonesian (id)
  - Malay (ms)

- **Localized Screens**:
  - ✅ `settings_screen.dart` - Settings page with controller fix
  - ✅ `onboarding_screen.dart` - Onboarding flow
  - ✅ `setup_screen.dart` - Quick setup wizard
  - ✅ `welcome_screen.dart` - Welcome page
  - ✅ `dashboard_screen.dart` - Main dashboard
  - ✅ `main_shell_screen.dart` - Navigation tabs
  - ✅ `hotspot_users_screen.dart` - User management
  - ✅ `vouchers_list_screen.dart` - Voucher list
  - ✅ `revenue_screen.dart` - Revenue dashboard
  - ✅ `activity_logs_screen.dart` - Activity logs
  - ✅ `login_screen.dart` - Login screen
  - ✅ `voucher_generation_screen.dart` - Voucher generation
  - ✅ `user_profiles_screen.dart` - Profile management
  - ✅ `hotspot_active_users_screen.dart` - Active users
  - ✅ `voucher_preview_screen.dart` - Voucher preview with QR
  - ✅ `voucher_detail_screen.dart` - Voucher details
  - ✅ `hotspot_host_detail_screen.dart` - Host details
  - ✅ `hotspot_user_details_screen.dart` - User details
  - ✅ `add_hotspot_user_screen.dart` - Add user
  - ✅ `edit_hotspot_user_screen.dart` - Edit user
  - ✅ `add_edit_profile_screen.dart` - Add/edit profile
  - ✅ `hotspot_host_details_screen.dart` - Host details
  - ✅ `hotspot_hosts_screen.dart` - Hosts list
  - ✅ `voucher_templates_dialog.dart` - Template dialog
  - ✅ `print_preview_dialog.dart` - Print preview
  - ✅ `voucher_qr_fullscreen.dart` - QR fullscreen
  - ✅ `traffic_monitor_widgets.dart` - Traffic widget
  - ✅ `combined_resource_chart.dart` - Resource chart
  - ✅ `expandable_chart.dart` - Expandable chart
  - ✅ `vouchers_list_screen.dart` - Voucher list

- **Translation Keys Added**:
  - Navigation: `dashboardNav`, `usersNav`, `hostsNav`, `settingsNav`, `settings`
  - Common: `cancel`, `save`, `delete`, `edit`, `refresh`, `retry`, `close`, `ok`, `loading`, `copy`, `share`
  - Onboarding: `onboardingWelcome`, `onboardingSubtitle`, `onboardingDescription`, `skip`, `next`, `back`, `continue_`
  - Features: `whatYouCanDo`, `feature titles and descriptions`
  - Login/Connect: `connect`, `connectionFailed`, `tryDemoData`, `connectionError`
  - User Management: `addUserTitle`, `editUserTitle`, `fullName`, `passwordOptional`, `limitUptime`, `addUserSuccess`, `editUserSuccess`, `userDetails`, `name`, `ipAddress`, `macAddress`, `uptime`, `bytesUsed`, `status`, `deleteUser`, `enable`, `disable`, `generateVoucher`, `backToHome`, `lastSeen`, `connectedSince`, `filterAll`, `filterActive`, `filterInactive`, `selectedCount`, `alreadyDisabled`, `disabled`, `enabled`, `alreadyActive`, `userDeleted`, `noProfilesAvailable`, `loadingProfiles`, `failedToLoadProfiles`, `viewDetails`, `deleteProfile`, `profileDeleted`, `profileDetails`, `editProfile`, `addProfile`, `sharedUsers`, `rateLimit`, `validity`, `price`
  - Voucher: `pleaseSelectProfile`, `notConnectedLoginFirst`, `failedToGenerateVouchers`, `usernamePasswordSeparate`, `usernameEqualPassword`, `characters`, `defaultNoProfilesFound`, `selectProfile`, `showUsers`, `totalVouchers`, `profileLabel`, `failedToShare`, `failedToPrint`, `failedToCreateScreenshot`, `vouchersCopied`, `voucherCopied`, `credentialsCopied`, `voucherDetailsCopied`, `scanVoucher`, `copiedToClipboard`
  - Active Users: `logoutUser`, `failedToLogoutUser`, `details`, `logout`
  - Hosts: `hotspotHosts`, `deviceDetails`, `hostDetails`, `removeHost`, `removeHostConfirmation`, `hostRemovedSuccessfully`, `blockMacAddress`, `blockMacConfirmation`, `macAddressBlocked`, `remove`, `block`
  - User Details: `failedToRefresh`, `deleteUserConfirmation`, `failedToDeleteUser`, `failedToCreateUser`, `failedToUpdateUser`, `failedToSaveProfile`, `noProfilesAvailableCreateProfileFirst`
  - Revenue: `noTransactionsToExport`, `failedToExport`, `allProfiles`, `thisWeek`, `thisMonth`, `thisQuarter`, `thisYear`
  - Print: `previewAndPrint`, `printAll`, `customSettings`, `generate`
  - Dashboard Widgets: `networkTraffic`, `live`, `moreInterfaces`, `tapToCollapse`, `systemResources`

- **Bug Fixes**:
  - Fixed `translations.dart` corruption (stray `}` closing class prematurely)
  - Removed duplicate translation keys (`delete`, `edit`, `uptime`, `selectedCount`, `noProfilesAvailable`, etc.)
  - Fixed "TextEditingController used after being disposed" in settings_screen.dart
  - Fixed duplicate "Open Mikrotik Monitor" text on welcome/onboarding screens
  - Removed `const` from widgets using `AppStrings.of(context)` to avoid const context errors

- **Files Modified**:
  - `lib/l10n/translations.dart` - Central translation file (created & maintained)
  - All screen files listed above - Replaced hardcoded strings with translations

### 2. Voucher Templates ✅
**Customizable print templates for vouchers**

- **Template Options**:
  - Full Size - Complete voucher with all details and cut lines
  - Compact - Smaller voucher with essential info
  - Minimal - Simple design with QR and credentials only
- **Features**:
  - Template selection in Settings > Voucher Templates
  - Persists across app restarts
  - Automatically applied to all voucher printing functions
- **Files**:
  - `lib/services/template_service.dart` - Template service with persistence
  - `lib/providers/app_providers.dart` - voucherTemplateProvider
  - `lib/utils/voucher_printer.dart` - Template-aware HTML generation
  - `lib/screens/settings/settings_screen.dart` - Template selection UI

### 4. Sales Report Export ✅
**CSV export functionality for revenue data**

- **Features**:
  - Export all transactions to CSV format
  - Includes username, profile, price, date, time, and comment
  - Share via any app (email, messaging, cloud storage)
  - Working date range picker for filtering
- **File**: `lib/screens/revenue/revenue_screen.dart`

### 5. Flutter Analyze Issues Fixed ✅
**Fixed all 12 static analysis issues identified by Flutter**

### 1. Flutter Analyze Issues Fixed ✅
**Fixed all 12 static analysis issues identified by Flutter**

- **Unused Element** - Removed unused `_showLogoutDialog()` function from dashboard
- **Curly Braces** - Added curly braces to if statement in combined_resource_chart.dart
- **String Interpolation** - Replaced string concatenation with interpolation (4 places in hotspot_users_screen.dart)
- **Deprecated Radio Widgets** - Updated `RadioListTile` to use new `RadioGroup` widget pattern
- **BuildContext Async Gaps** - Added `context.mounted` checks before using BuildContext after async operations (4 places in voucher_printer.dart)
- **Files**:
  - `lib/screens/dashboard/dashboard_screen.dart` - Removed unused function
  - `lib/screens/dashboard/widgets/combined_resource_chart.dart` - Added curly braces
  - `lib/screens/hotspot_users/hotspot_users_screen.dart` - String interpolation + RadioGroup
  - `lib/utils/voucher_printer.dart` - BuildContext mounted checks

### 2. Voucher Bulk Delete ✅
**Implemented batch delete functionality for voucher list screen**

- **Selection Mode**:
  - Enter via checklist icon in app bar
  - Exit via close button
  - Selection count displayed in title
- **Selection Actions**:
  - Tap vouchers to select/deselect
  - "Select All" button for all visible vouchers
  - Visual feedback with highlighted cards and checkmarks
- **Bulk Operations**:
  - Delete selected vouchers with confirmation dialog
  - Progress dialog during deletion
  - Success/failure count in snackbar feedback
- **UI Features**:
  - Color-coded selection border (primary color when selected)
  - Gradient background change for selected cards
  - Position-fixed checkmark overlay
  - Disabled tap navigation in selection mode
- **Files**:
  - `lib/screens/vouchers/vouchers_list_screen.dart` - Complete implementation

### 6. Performance Optimization & DRY Code ✅
**Optimized app performance and reduced code duplication**

- **Memory Leak Fixes**:
  - `welcome_screen.dart` - Added `passwordController.dispose()` after dialog closes
  - `login_screen.dart` - Added `passwordController.dispose()` after dialog closes

- **Const Constructors**:
  - Added `const` to Icon widgets in AppBar actions (revenue_screen.dart)

- **Reusable FilterUtils (DRY)**:
  - Created `lib/utils/filter_utils.dart` with:
    - `filterBySearch()` - Filter by search query across multiple fields
    - `filterByDateRange()` - Filter by date range
    - `filterByField()` - Filter by exact field value
    - `getUniqueValues()` - Get unique values for filter chips
    - `sortByDate()` - Sort by date (newest/oldest first)
    - `sortAlphabetically()` - Sort alphabetically
    - `formatCurrency()` - Currency formatting
    - `formatRelativeTime()` - Relative time formatting

- **Applied to Screens**:
  - `revenue_screen.dart` - Replaced manual filter logic with FilterUtils
  - `vouchers_list_screen.dart` - Updated to use FilterUtils for search

- **Files**:
  - `lib/screens/welcome/welcome_screen.dart` - Memory leak fix
  - `lib/screens/auth/login_screen.dart` - Memory leak fix
  - `lib/screens/revenue/revenue_screen.dart` - FilterUtils + const
  - `lib/screens/vouchers/vouchers_list_screen.dart` - FilterUtils
  - `lib/utils/filter_utils.dart` - New reusable utility

---

## 🆕 Recent Updates (March 27, 2026)

### 1. RenderFlex Overflow Fixes ✅
**Fixed overflow errors causing UI clipping**

- **Bottom Navigation** - Replaced problematic `ConvexAppBar` with standard `BottomNavigationBar` to eliminate overflow issues
- **Login Screen** - Changed `CrossAxisAlignment.stretch` to `CrossAxisAlignment.center` and reduced vertical padding
- **Welcome Screen** - Added `SafeArea(bottom: false)` and reduced vertical padding
- **Files**:
  - `lib/screens/main/main_shell_screen.dart` - Standard BottomNavigationBar instead of ConvexAppBar
  - `lib/screens/auth/login_screen.dart` - CrossAxisAlignment fix
  - `lib/screens/welcome/welcome_screen.dart` - SafeArea with bottom:false

### 2. Provider Modification During Build Fix ✅
**Fixed "Tried to modify a provider while widget tree was building" error**

- **Issue**: `ref.read(currentTabProvider)` was called synchronously in `didChangeDependencies()` during widget build
- **Fix**: Moved `ref.read()` call inside `Future.microtask()` callback to delay execution until after build phase
- **File**: `lib/screens/main/main_shell_screen.dart`

### 3. Quick Login Optional Password ✅
**Made password optional for quick login from saved connections**

- **Change**: Removed password requirement check in `_quickLogin()` method
- **User Flow**: Users can now connect without entering password if router has no password set
- **File**: `lib/screens/welcome/welcome_screen.dart`

### 4. Login Screen Password Fix ✅
**Fixed password field for saved connections**

- **Issue**: Password was hardcoded to empty string when using saved connection
- **Fix**: Changed to use `_passwordController.text` so users can enter password when connecting via saved connection
- **File**: `lib/screens/auth/login_screen.dart`

---

## 🆕 Recent Updates (March 26, 2026)

### 1. Batch Operations for Hotspot Users ✅
**Implemented bulk actions for managing multiple users at once**

- **Features**:
  - Bulk delete with confirmation dialog
  - Bulk enable/disable users
  - Bulk move users to different profile
  - Progress dialogs with user count
  - Success/failure tracking with detailed feedback
- **UI**:
  - Long-press to enter selection mode
  - Select All button for quick selection
  - Bottom action bar with operation buttons
  - Color-coded actions (Red: Delete, Orange: Disable, Green: Enable, Primary: Move Profile)
- **Files**:
  - `lib/screens/hotspot_users/hotspot_users_screen.dart` - Selection mode and bulk actions
  - `lib/services/routeros_api_client.dart` - Added `setHotspotUserProfile()` method
  - `lib/providers/app_providers.dart` - Enhanced `deleteUser()` and `toggleUserStatus()` with immediate UI updates

### 2. QR Code Voucher Generation ✅
**Complete voucher system with QR codes, copy, share, and print functionality**

- **Features**:
  - QR code generation for each voucher (WiFi-compatible format)
  - Copy individual or all vouchers to clipboard
  - Share vouchers as text via apps
  - Generate printable screenshot with grid layout
  - Voucher preview screen with summary card
  - Expiration date tracking
- **Voucher Model** (`lib/services/models/voucher.dart`):
  - Stores username, password, profile, validity, data limit, comment
  - Provides QR code data in WiFi format
  - Active/expired status checking
- **Preview Screen** (`lib/screens/hotspot_users/voucher_preview_screen.dart`):
  - Summary card (total, active, expired counts)
  - Expandable voucher cards with QR codes
  - Copy, share, and print actions
  - Export as image for printing
- **Packages Added**:
  - `qr_flutter: ^4.1.0` - QR code generation
  - `screenshot: ^3.0.0` - Capture vouchers as image
  - `share_plus: ^10.1.3` - Share functionality
  - `path_provider: ^2.1.5` - File saving
  - `permission_handler: ^11.3.1` - Storage permissions
- **Files**:
  - `lib/services/models/voucher.dart` - Voucher data model
  - `lib/screens/hotspot_users/voucher_preview_screen.dart` - New voucher preview screen
  - `lib/screens/hotspot_users/voucher_generation_screen.dart` - Updated to store and show vouchers

### 3. Convex Bottom Navigation with Animation ✅
**Modern curved bottom bar with animated center circle**

- **Features**:
  - Convex (curved) middle tab for Profiles
  - Pulse animation every 2 seconds when on Profiles tab
  - Bounce animation when center circle is tapped
  - Active icon scales with animation (1.0 → 1.2x)
  - Fixed tabs: Dashboard, Users, Profiles (curved), Hosts, Settings
- **Implementation**:
  - `convex_bottom_bar: ^3.2.0` package
  - ShellRoute navigation with `/main` prefix
  - Custom style hook for icon sizing
  - AnimationController with scale animation
- **Files**:
  - `lib/screens/main/main_shell_screen.dart` - New main shell with convex bar
  - `lib/providers/app_providers.dart` - Restructured router with ShellRoute
  - `pubspec.yaml` - Added convex_bottom_bar package

### 4. Router Restructuring with ShellRoute ✅
**Fixed navigation issues and reorganized routing structure**

- **Changes**:
  - Implemented ShellRoute for nested navigation
  - All main routes now under `/main` prefix
  - Bottom navigation persists across tab changes
  - Fixed route not found errors for `/dashboard`
- **Routes Structure**:
  - `/main/dashboard` - Dashboard
  - `/main/users` - Hotspot Users
  - `/main/users/active` - Active Users
  - `/main/users/add` - Add User
  - `/main/users/generate` - Generate Vouchers
  - `/main/profiles` - User Profiles
  - `/main/hosts` - Hotspot Hosts
  - `/main/settings` - Settings
- **Files**:
  - `lib/providers/app_providers.dart` - Router restructure
  - `lib/screens/auth/login_screen.dart` - Updated navigation paths
  - `lib/screens/welcome/welcome_screen.dart` - Updated navigation paths
  - `lib/screens/hotspot_users/hotspot_active_users_screen.dart` - Updated navigation paths

### 5. Revenue/Income Dashboard ✅
**Comprehensive revenue tracking with charts and transaction history**

- **Features**:
  - Summary cards showing revenue and transaction counts
  - Line chart for revenue trend over time
  - Bar chart for daily breakdown
  - Revenue breakdown by profile with ranking (gold/silver/bronze badges)
  - Filterable transaction history (search, profile, date range)
  - Time period selector (week, month, quarter, year)
  - TabController with 3 tabs: Charts, By Profile, Transactions
- **Implementation**:
  - `fl_chart` for line and bar charts
  - Group transactions by date and profile
  - Transaction cards with detailed information
  - Relative timestamp formatting (Just now, 5m ago, 2h ago, etc.)
- **Files**:
  - `lib/screens/revenue/revenue_screen.dart` - New revenue dashboard
  - `lib/providers/app_providers.dart` - Income provider with transaction tracking
  - `pubspec.yaml` - Added `intl: ^0.19.0` for number formatting

### 6. Android Back Button Fix ✅
**Fixed back button behavior on sub-screens**

- **Issue**: Back button was exiting app instead of returning to dashboard
- **Fix**: Added `PopScope(canPop: true)` to affected screens
- **Screens Fixed**:
  - Manage Hotspot (Hotspot Users)
  - User Profiles
  - Hotspot Hosts
- **Files**:
  - `lib/screens/hotspot_users/hotspot_users_screen.dart`
  - `lib/screens/hotspot_users/user_profiles_screen.dart`
  - `lib/screens/hotspot_users/hotspot_hosts_screen.dart`

---

## 🆕 Previous Updates (March 10, 2026)

### 1. Navigation Hiccups Fix ✅
**Fixed interface traffic "connect/disconnect" flashes and graph hiccups when navigating**

- **Issue**: When navigating between Dashboard → Hotspot Host → Dashboard, the interface showed "connect/disconnect" flashes and the graph hiccuped
- **Root Causes**:
  1. No `ref.keepAlive()` on providers caused disposal/recreation on navigation
  2. Dashboard periodic timer fired immediately on widget creation
  3. Traffic monitor timer also fired immediately
  4. Stale cache check triggered immediate fetch on navigation
- **Fixes**:
  1. Added `ref.keepAlive()` to `InterfaceTrafficNotifier` and `SystemResourcesNotifier` to prevent disposal
  2. Removed `_refreshInBackground()` method (no longer needed)
  3. Removed stale cache check from dashboard - use cached data instantly
  4. Delayed both dashboard and traffic monitor timers by 3 seconds using `Future.delayed`
- **Impact**: Seamless navigation without hiccups or connect/disconnect flashes
- **Files**:
  - `lib/providers/app_providers.dart`
  - `lib/screens/dashboard/dashboard_screen.dart`
  - `lib/screens/dashboard/widgets/traffic_monitor_widgets.dart`

### 2. Platform "Unknown" Issue Fix ✅
**Fixed platform intermittently becoming "unknown" on dashboard**

- **Issue**: Sometimes the platform value became "unknown" on dashboard, which triggered hiccups again
- **Root Causes**:
  1. No protection against concurrent fetches causing race conditions
  2. Empty/incomplete API responses not validated
  3. No string validation in SystemResources.fromJson
- **Fixes**:
  1. Added `_isFetching` flag to prevent concurrent fetches
  2. Added better data validation (check for specific fields like 'platform', 'cpu-load', 'free-memory')
  3. Added `_safeString()` helper to handle null/empty strings
  4. Added comprehensive debug logging
- **Impact**: Platform no longer becomes "unknown", race conditions eliminated
- **Files**:
  - `lib/screens/dashboard/dashboard_screen.dart`
  - `lib/services/models.dart`

### 3. Graph Time Labels Fix ✅
**Fixed time labels resetting to "0s" on reload and added proper elapsed time display**

- **Issue**: Time labels showed "0s" again when data reloaded, not accurate elapsed time
- **Root Cause**: X-coordinates were relative (0, 1, 2, ...) calculated from current window, not actual timestamps
- **Fixes**:
  1. Changed x-coordinates to use actual elapsed time in seconds from reference timestamp
  2. Added `_formatElapsedTime()` for proper time formatting (30s, 2m, 3m30s, 1h15m, etc.)
  3. Removed 60.0 clamp on `maxX` to allow continuous scrolling beyond 3 minutes
  4. Updated chart labels to use x-coordinate (elapsed seconds) directly
- **Impact**: Time labels now show accurate elapsed time that doesn't reset on reload
- **Files**:
  - `lib/screens/dashboard/widgets/combined_resource_chart.dart`

### 4. Initial Load Indicator ✅
**Added lazy loading indicator for first-time dashboard data fetch**

- **Issue**: No visual feedback when fetching data for the first time
- **Fixes**:
  1. Added `_isInitialLoad` flag to track first data load
  2. Set `_isInitialLoad = false` after successful data load from all sources
  3. Updated `_buildBody()` to show "Loading dashboard..." with CircularProgressIndicator when `_isInitialLoad && _isLoading`
  4. Improved chart empty state with loading indicator and "Waiting for first data point" message
- **Impact**: Users see clear loading indicator on first load, seamless updates afterwards
- **Files**:
  - `lib/screens/dashboard/dashboard_screen.dart`
  - `lib/screens/dashboard/widgets/combined_resource_chart.dart`

### 5. Auto-Refresh Timer Fix ✅
**Fixed traffic monitoring auto-refresh to work in real-time mode**

- **Issue**: Traffic rates not updating automatically every 3 seconds in real-time mode (not demo mode)
- **Root Cause**: `_loadInitialData()` called from `initState()` ran before provider data was loaded, so timer never started
- **Fix**:
  - Added `_timerStarted` flag to prevent duplicate timers
  - Moved `_startAutoRefresh()` call to `build()` method which uses `ref.watch()` and triggers when data arrives
  - Timer now starts correctly regardless of data loading timing
- **Impact**: Traffic rates now auto-update every 3 seconds in both demo and real-time modes
- **Files**: `lib/screens/dashboard/widgets/traffic_monitor_widgets.dart`

### 6. Network Permissions Added ✅
**Fixed "Permission denied" error when connecting to RouterOS**

- **Issue**: App couldn't connect to RouterOS in real-time mode, showing "SocketException: Connection failed (OS Error: Permission denied)"
- **Root Cause**: AndroidManifest.xml was missing INTERNET permission required for network sockets
- **Fix**: Added network permissions before `<application>` tag:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
  ```
- **Impact**: App can now successfully connect to RouterOS devices on port 8728
- **File**: `android/app/src/main/AndroidManifest.xml`

### 7. Removed Refresh Button ✅
**Cleaned up UI to match system resources card**

- **Issue**: Traffic monitor had manual refresh button with "Updating..." state, inconsistent with system resources
- **Solution**:
  - Removed `_buildRefreshIndicator()` method entirely
  - Removed `_isRefreshing` state variable
  - Simplified `_silentRefresh()` by removing try/finally blocks
  - Changed header to use `Expanded` widget for text (no spacer/refresh button)
- **Result**: Clean, silent auto-refresh like system resources card - no visible refresh indicators
- **File**: `lib/screens/dashboard/widgets/traffic_monitor_widgets.dart`

### 8. Real-Time Traffic Rate Updates ✅
**Fixed traffic monitoring to show live per-second rates**

- **Issue**: Traffic rates showing "0 B/s" instead of real-time values
- **Root Cause**: Demo mode wasn't calling `_trafficRateService.calculateRates()` in `build()`, `refresh()`, and `silentRefresh()`
- **Fix**: Added rate calculation for demo mode in all three methods
- **Impact**: TX and RX rates now update correctly every 3 seconds
- **Files**: `lib/providers/app_providers.dart`

### 9. Smooth Traffic Text Updates ✅
**Refactored to use ValueNotifier for text-only updates**

- **Issue**: Entire card was rebuilding causing visual flicker
- **Solution**: Used `ValueNotifier` for each traffic value (TX total, RX total, TX rate, RX rate)
- **Implementation**: `ValueListenableBuilder` wraps each text widget for independent updates
- **Result**: Text values update smoothly without rebuilding card structure
- **File**: `lib/screens/dashboard/widgets/traffic_monitor_widgets.dart`

### 10. About Dialog with Developers ✅
**Added developer information to Settings > About**

- **Developers**: Favian Hugo and Syarif Abdurrahman
- **UI**: Two developer cards with icons and names
- **Style**: Matching app theme with purple primary color
- **File**: `lib/screens/settings/settings_screen.dart`

### 11. Responsive Developer Cards ✅
**Fixed overflow issue on smaller screens**

- **Issue**: "Syarif Abdurrahman" text overflowed on small screens
- **Solution**:
  - Used `Expanded` widgets for flexible width
  - Reduced horizontal padding from 16 to 8
  - Added `FittedBox` to prevent text overflow
- **Result**: Cards adapt to all screen sizes without overflow
- **File**: `lib/screens/settings/settings_screen.dart`

### 12. Hotspot Hosts Monitoring ✅
**DHCP lease/binding monitoring with real-time updates**

- **Feature**: Complete hotspot hosts monitoring showing all connected devices
- **Data Model**: `HotspotHost` class with MAC address, IP address, authorization status, bypassed status, user association, uptime, and idle time
- **API Integration**: RouterOS `/ip/hotspot/host/print` command to fetch DHCP hosts
- **State Management**: `HotspotHostsNotifier` with AsyncNotifier, auto-refreshes every 5 seconds
- **UI Features**:
  - Search by IP, MAC address, or username
  - Filter chips (All, Authorized, Unauthorized, Bypassed)
  - Color-coded status badges (Emerald for authorized, Amber for bypassed, Slate for unauthorized)
  - Card-based layout with connection details
  - Demo mode support with 4 sample hosts
- **Navigation**: Added route and dashboard button for easy access
- **Files**:
  - `lib/services/models.dart` - Added `HotspotHost` class
  - `lib/services/routeros_api_client.dart` - Added `getHotspotHosts()` method
  - `lib/providers/app_providers.dart` - Added `HotspotHostsNotifier` and `hotspotHostsProvider`
  - `lib/screens/hotspot_users/hotspot_hosts_screen.dart` - Complete UI implementation
  - `lib/navigation/app_router.dart` - Added route configuration
  - `lib/screens/dashboard/dashboard_screen.dart` - Added navigation button

---

## 🆕 Previous Updates (March 8, 2026)

### 5. App Rebranding ✅
**Mikhmon Clone → ΩMMON (Open Mikrotik Monitor)**

- **App Name**: `ΩMMON` with Omega (Ω) symbol
- **Full Name**: Open Mikrotik Monitor
- **Package**: `com.simpurrapps.ommon`
- **Files Updated**:
  - `pubspec.yaml` - Package name: `ommon`
  - `lib/main.dart` - `OmmonApp` class
  - `lib/screens/welcome/welcome_screen.dart` - "ΩMMON" title
  - `lib/screens/auth/login_screen.dart` - "ΩMMON" in AppBar
  - `lib/screens/settings/settings_screen.dart` - About dialog
  - `test/widget_test.dart` - Updated test expectations
  - `android/app/build.gradle.kts` - Application ID: `com.simpurrapps.ommon`
  - `android/app/src/main/AndroidManifest.xml` - App label: "OMMON"
  - `android/app/src/main/kotlin/com/simpurrapps/ommon/MainActivity.kt` - New package

### 2. Real-Time System Monitor Chart ✅
**Combined line chart with CPU, Memory, and Disk**

- **Single chart** showing all three metrics (replaced individual cards)
- **Right-to-left scrolling** - like Linux Mint system monitor
- **Smooth animations** - 300ms transitions on data updates
- **Auto-scrolling window** - Shows last 30-40 data points
- **Interactive tooltips** - Tap to see exact values
- **Live indicator** - Shows "LIVE" badge with sync icon
- **Color-coded lines**:
  - 🟣 CPU - Purple/Indigo gradient
  - 🟢 RAM - Green/Teal gradient
  - 🟠 Disk - Orange/Amber gradient
- **File**: `lib/screens/dashboard/widgets/combined_resource_chart.dart`

### 3. Resource History Tracking ✅
**Data persistence for real-time charts**

- **`ResourceDataPoint`** class - Stores CPU/Memory/Disk at timestamp
- **`ResourceHistory`** class - Maintains 60 data points (3 min history)
- **`ResourceHistoryNotifier`** - State management with ChangeNotifier
- **Auto-updates** every 3 seconds when resources refresh
- **File**: `lib/services/resource_history.dart`

### 4. RouterOS API Bug Fixes ✅
**Fixed critical issues with multi-record responses**

- **Issue**: Only last profile/item was shown when multiple records existed
- **Root Cause**: `_processWord()` didn't add previous item when `!re` received
- **Fix**: Now adds current item to response before starting new record
- **File**: `lib/services/routeros_api_client.dart`
- **Impact**: All user profiles, hotspot users, and other multi-record data now display correctly

### 5. User Profile Creation Fix ✅
**Fixed circular dependency in Riverpod provider**

- **Issue**: "provider cannot depend on itself" error when creating profiles
- **Root Cause**: `addProfile()`, `updateProfile()`, `deleteProfile()` called `ref.invalidate(userProfileProvider)`
- **Fix**: Changed to direct state updates with `AsyncValue.guard()`
- **File**: `lib/providers/app_providers.dart`

### 6. Modern UI Theme ✅
**Material 3 with Poppins font and vibrant colors**

- **Font**: Google Fonts - **Poppins** (modern, clean typography)
- **Design System**: **Material 3** (Flutter's latest)
- **Primary Color**: **Vibrant Purple** (#7C3AED)
- **Secondary Color**: **Cyan** (#06B6D4)
- **Surface Colors**: Slate tones (900, 800, 700)
- **Features**:
  - Proper shadow colors using `ColorScheme.shadow`
  - Surface tint set to transparent for better control
  - Rounded corners (16-24px)
  - Optimized letter spacing for headlines
  - Better text hierarchy with improved heights
- **File**: `lib/theme/app_theme.dart`

### 7. Dashboard Cleanup ✅
**Removed duplicate UI elements**

- **Removed**: Duplicate User Profiles and Settings cards from income section
- **Removed**: Unused `_buildQuickActionCard` method
- **Added**: Settings button back to AppBar (for easy access)
- **Result**: Cleaner, more focused dashboard layout

### 8. Responsive Design Improvements ✅
**Adaptive UI for all screen sizes**

- **LayoutBuilder** for dynamic sizing
- **Chart height**: 180px (small) vs 240px (large)
- **Adjusted padding** and font sizes based on screen width
- **Wrap widgets** for legend items to prevent overflow
- **Small screen detection**: `< 400px` threshold

### 9. Chart Dependencies ✅
**Added fl_chart and google_fonts libraries**

```yaml
dependencies:
  fl_chart: ^0.70.1
  google_fonts: ^6.2.1
```

### 10. Interface Traffic Monitoring ✅
**Network interface statistics widget with real-time rate calculation**

- **Real-time traffic data** - TX/RX bytes and per-second rates
- **Rate calculation service** - `TrafficRateService` computes rates from cumulative bytes
- **Smooth text updates** - `ValueNotifier` + `ValueListenableBuilder` for flicker-free updates
- **Silent auto-refresh** - Updates every 3 seconds without any UI indicator (like system resources)
- **Smart timer startup** - Timer starts when data becomes available via `ref.watch()` in `build()` method
- **Interface filtering** - Shows only running interfaces, sorted by type
- **Type-based styling** - Color-coded icons for Ethernet (Cyan), Wireless (Violet), Bridge (Emerald)
- **Status badges** - Active/Inactive/Disabled indicators
- **Human-readable formatting** - Auto-converts bytes to B/KB/MB/GB/TB
- **Network permissions** - INTERNET and ACCESS_NETWORK_STATE for RouterOS connections
- **Demo mode support** - Simulated interface data with rate calculation
- **Files**:
  - `lib/services/models.dart` - Added `InterfaceTraffic` class
  - `lib/services/traffic_rate_service.dart` - Real-time rate calculation from cumulative bytes
  - `lib/services/routeros_api_client.dart` - Added `getInterfaceStats()` method
  - `lib/providers/app_providers.dart` - Added `interfaceTrafficProvider` with rate calculation
  - `lib/screens/dashboard/widgets/traffic_monitor_widgets.dart` - New widget with ValueNotifier architecture
  - `lib/screens/dashboard/dashboard_screen.dart` - Added widget to dashboard
  - `android/app/src/main/AndroidManifest.xml` - Added network permissions

---

## 🔄 Complete Data Flow

```
Login → RouterOS API (8728) → Pre-fetch → Hive Cache → Dashboard
                                                    ↓
                                          Timer (every 3s)
                                                    ↓
                                          RouterOS → ResourceHistory → Chart Update
                                                    ↓
                                          Animated Chart (scrolls right→left)
```

---

## Dashboard Architecture

```
┌─────────────────────────────────────┐
│ System Info Card                   │
│ - Router name, version, platform   │
│ - CPU frequency, uptime            │
├─────────────────────────────────────┤
│                                     │
│   Combined Line Chart              │
│   ┌─────────────────────────────┐  │
│   │ 🟣 CPU  🟢 RAM  🟠 Disk    │  │
│   │   LIVE  [scrolling →     ]  │  │
│   └─────────────────────────────┘  │
│                                     │
├─────────────────────────────────────┤
│ Income Cards                        │
│ - Today's income                    │
│ - This month                        │
├─────────────────────────────────────┤
│ Quick Actions                       │
│ - Add Hotspot User                 │
│ - Manage Hotspot                   │
│ - User Profiles                     │
│ - Connection Logs                  │
└─────────────────────────────────────┘
```

---

## ❌ Missing Features

#### 1. Dashboard Enhancements

- ~~**Interface stats**~~ ✅ COMPLETED - Network traffic monitoring (tx/rx bytes)
- **Health monitoring** - Voltage, temperature sensors

#### 2. Hotspot Features

- ~~**Hotspot Hosts**~~ ✅ COMPLETED - DHCP lease/binding monitoring
- ~~**Voucher QR Codes**~~ ✅ COMPLETED - QR code generation for scanning
- ~~**Voucher Preview**~~ ✅ COMPLETED - Show, copy, share, print vouchers
- ~~**Voucher Templates**~~ ✅ COMPLETED - Full Size, Compact, Minimal templates
- **Template Editor** - Custom templates via editor

#### 3. Reports

- ~~**Sales Report**~~ ✅ COMPLETED - CSV export with date filtering
  - ~~Date/time filtering (day, month, year)~~ ✅
  - ~~Filter by username, profile~~ ✅
  - ~~CSV export~~ ✅
- **Income Summary** - Total revenue calculations
  - Today's income ✅ (Already shown)
  - This month's income ✅ (Already shown)
  - Filtered period totals

#### 4. Log System

- **Activity logging** - User actions
- **Transaction history** - All sales
- **Connection logs** - Login/logout events

#### 5. Settings

- ~~**Theme Selection**~~ ✅ COMPLETED - Light/Dark/Blue/Green/Pink themes
- **Template Editor** - Custom templates via editor
- **Router Management** - Multiple router connection support
- **Logo Upload** - Custom branding per session
- **Profile Configuration** - Profile-based pricing
- **Hotspot Server Settings** - Server selection

#### 6. Advanced Features

- **Multi-Session Support** - Switch between multiple RouterOS connections
  - Session dropdown in sidebar
  - Save router configurations
  - Quick session switching
- **Idle Timeout** - Auto-logout timer (10 min)
- **Session Management** - Save/load router sessions
- **About Page** - App information and version ✅ (Already in settings)

---

## Priority Implementation Order

### High Priority (Core Functionality)

1. ~~**Hotspot Active**~~ ✅ COMPLETED
2. ~~**User Profiles**~~ ✅ COMPLETED
3. ~~**Voucher Generation**~~ ✅ COMPLETED
4. ~~**RouterOS API Integration**~~ ✅ COMPLETED
5. ~~**Local Caching (Hive)**~~ ✅ COMPLETED
6. ~~**Real-Time Dashboard Chart**~~ ✅ COMPLETED
7. ~~**Resource History Tracking**~~ ✅ COMPLETED
8. ~~**Responsive Design**~~ ✅ COMPLETED
9. ~~**Dashboard Income Widget**~~ ✅ Already implemented
10. ~~**Modern UI Theme**~~ ✅ COMPLETED
11. ~~**Interface Traffic Monitoring**~~ ✅ COMPLETED
12. ~~**Seamless Navigation**~~ ✅ COMPLETED - Provider keepAlive for smooth transitions
13. ~~**Data Validation & Protection**~~ ✅ COMPLETED - Concurrent fetch protection and string validation
14. ~~**Accurate Time Labels**~~ ✅ COMPLETED - Elapsed time formatting and continuous scrolling

### Medium Priority (User Experience)

12. ~~**Settings screen**~~ ✅ COMPLETED - Theme switcher, template selection, router management
13. ~~**Reports page**~~ ✅ COMPLETED - Sales history with filtering, charts, and CSV export
14. **Log viewer** - Activity tracking
15. ~~**Hotspot Hosts**~~ ✅ COMPLETED - DHCP lease monitoring
16. **Health Monitoring** - Temperature, voltage sensors
17. **User Search Enhancement** - Profile filter, date range, CSV export

### Low Priority (Nice to Have)

17. **Template editor** - Custom voucher printing templates
18. **Multi-session support** - Multiple routers
19. **Real-time clock widget** - Dashboard enhancement

---

## Technical Notes

### Current Architecture

- **State Management**: Riverpod 2.6.1
- **Navigation**: go_router 14.6.2 with ShellRoute
- **Bottom Navigation**: convex_bottom_bar 3.2.0
- **Charts**: fl_chart 0.70.1
- **QR Codes**: qr_flutter 4.1.0
- **Fonts**: google_fonts 6.2.1 (Poppins)
- **Secure Storage**: flutter_secure_storage
- **Local Database**: Hive 2.2.3
- **Screenshot**: screenshot 3.0.0
- **Sharing**: share_plus 10.1.3
- **Number Formatting**: intl 0.19.0
- **Demo Mode**: In-memory cache (module-level variables)

### Theme Configuration

```dart
// Modern Color Palette
Primary: #7C3AED (Vibrant Purple)
Secondary: #06B6D4 (Cyan)
Background: #0F172A (Slate 900)
Surface: #1E293B (Slate 800)
Card: #334155 (Slate 700)

// Typography
Font Family: Poppins (Google Fonts)
Design System: Material 3
```

### RouterOS API Protocol

```
┌─────────────────────────────────────────────────────────┐
│ RouterOS API Protocol (port 8728)                       │
├─────────────────────────────────────────────────────────┤
│ • Encoding: Variable-length (1-5 bytes)                 │
│ • Login: Post-v6.43 plain text in one sentence           │
│   /login                                                  │
│   =name=username                                          │
│   =password=password                                     │
│   '' (empty word terminator)                               │
│ • Termination: Zero-length word for each sentence        │
│ • Responses: !re (data), !done (end), !trap (error)       │
│ • Multi-record: Each !re starts new record              │
└─────────────────────────────────────────────────────────┘
```

### Cache Settings

- **Database**: Hive (NoSQL, encrypted)
- **Stale Duration**: 5 minutes (configurable)
- **Cache Keys**:
  - `system_resources`
  - `hotspot_users`
  - `active_users`
  - `user_profiles`

### Refresh Rates

| Data Type | Refresh Rate |
|-----------|--------------|
| Dashboard resources | Every 3 seconds (real mode), delayed first tick |
| Resource history | Every 3 seconds (adds to history) |
| Active users | Every 5 seconds (real mode) |
| Hotspot hosts | Every 5 seconds (real mode) |
| Interface traffic | Every 3 seconds (real mode), delayed first tick |
| Demo mode cards | 2-5 seconds (random values) |
| Cache validity check | On load |

### Resource History Settings

- **Max data points**: Unlimited (was 60, now removed for continuous scrolling)
- **Visible window**: 30-40 points (scrolling)
- **Animation duration**: 300ms
- **Chart update**: Triggered by ResourceHistoryNotifier
- **Time labels**: Accurate elapsed time (30s, 2m, 3m30s, 1h15m, etc.)
- **X-coordinates**: Based on actual timestamps (not relative positions)

### Files Structure

```
lib/
├── providers/
│   └── app_providers.dart                # Riverpod state management
│                                         # + CacheServiceProvider
│                                         # + AuthState with resources
│                                         # + ResourceHistoryNotifier
│                                         # + UserProfileNotifier (fixed circular dependency)
│                                         # + HotspotHostsNotifier with auto-refresh
├── screens/
│   ├── auth/
│   │   └── login_screen.dart             # Login with demo toggle (port 8728)
│   ├── dashboard/
│   │   ├── dashboard_screen.dart         # Dashboard with real-time chart + Hotspot Hosts button
│   │   │                                  # + Initial load indicator (_isInitialLoad flag)
│   │   │                                  # + Concurrent fetch protection (_isFetching flag)
│   │   └── widgets/
│   │       ├── resource_card_widgets.dart # Income cards (theme updated)
│   │       ├── combined_resource_chart.dart # Real-time line chart
│   │       │                               # + Accurate elapsed time labels
│   │       │                               # + Continuous scrolling (unlimited data points)
│   │       │                               # + Initial load indicator
│   │       └── traffic_monitor_widgets.dart # Interface traffic monitoring
│   │                                       # + Delayed timer start (3s)
│   ├── welcome/
│   │   └── welcome_screen.dart           # Welcome screen (ΩMMON branding)
│   ├── settings/
│   │   └── settings_screen.dart          # Settings with ΩMMON branding
│   └── hotspot_users/
│       ├── hotspot_users_screen.dart     # User list + batch operations + long-press selection
│       ├── hotspot_active_users_screen.dart # Active users (real-time)
│       ├── hotspot_hosts_screen.dart     # DHCP hosts monitoring
│       ├── hotspot_user_details_screen.dart
│       ├── add_hotspot_user_screen.dart
│       ├── edit_hotspot_user_screen.dart
│       ├── user_profiles_screen.dart     # Profile management
│       ├── add_edit_profile_screen.dart  # Add/edit profiles
│       ├── voucher_generation_screen.dart # Voucher generation
│       └── voucher_preview_screen.dart   # NEW - QR codes, copy, share, print
│   ├── revenue/
│   │   └── revenue_screen.dart          # NEW - Revenue dashboard with charts
│   └── main/
│       └── main_shell_screen.dart       # NEW - Shell route with convex bottom bar
├── services/
│   ├── models.dart                       # Data models + HotspotHost + Voucher
│   ├── routeros_api_client.dart          # RouterOS API + setHotspotUserProfile()
│   ├── routeros_service.dart             # Uses RouterOSClient
│   ├── cache_service.dart                # Hive caching service
│   ├── resource_history.dart             # Resource history tracking
│   ├── traffic_rate_service.dart         # Real-time traffic rate calculation
│   └── models/
│       └── voucher.dart                  # NEW - Voucher data model
├── theme/
│   └── app_theme.dart                    # Modern Material 3 theme with Poppins
├── navigation/
│   └── app_router.dart                   # go_router configuration + hosts route
└── utils/
    └── validators.dart                   # Form validators
```

### Android Structure

```
android/
├── app/
│   ├── build.gradle.kts                  # applicationId: com.simpurrapps.ommon
│   └── src/main/
│       ├── AndroidManifest.xml           # android:label="OMMON"
│       └── kotlin/com/simpurrapps/ommon/
│           └── MainActivity.kt           # Package: com.simpurrapps.ommon
```

---

## Next Steps

Choose a feature to implement:

1. ~~**Rebranding to ΩMMON**~~ ✅ DONE
2. ~~**Real-Time Chart**~~ ✅ DONE
3. ~~**Resource History**~~ ✅ DONE
4. ~~**Responsive Design**~~ ✅ DONE
5. ~~**Modern UI Theme**~~ ✅ DONE
6. ~~**User Profile Creation Fix**~~ ✅ DONE
7. ~~**RouterOS API Multi-Record Fix**~~ ✅ DONE
8. ~~**Interface Traffic Monitoring**~~ ✅ DONE
9. ~~**Navigation Hiccups Fix**~~ ✅ DONE - Seamless navigation without hiccups
10. ~~**Platform "Unknown" Issue Fix**~~ ✅ DONE - Race conditions eliminated
11. ~~**Graph Time Labels Fix**~~ ✅ DONE - Accurate elapsed time display
12. ~~**Initial Load Indicator**~~ ✅ DONE - Loading indicator for first-time fetch
13. **Settings Implementation** - Make settings screen functional
14. ~~**Reports Page**~~ ✅ DONE - Sales history with filtering and charts
15. ~~**Hotspot Hosts**~~ ✅ DONE - DHCP lease monitoring
16. ~~**Batch Operations**~~ ✅ DONE - Delete, enable, disable, move multiple users
17. ~~**QR Code Vouchers**~~ ✅ DONE - Generate, copy, share, print vouchers with QR codes
18. ~~**Convex Bottom Nav**~~ ✅ DONE - Modern curved navigation with animation
19. **Log Viewer** - Activity tracking
20. **Health Monitoring** - Temperature, voltage sensors

---

## Bug Fixes Summary

### Fixed Issues (March 10, 2026)

1. **Navigation Hiccups** - Fixed connect/disconnect flashes and graph hiccups
   - Added `ref.keepAlive()` to prevent provider disposal on navigation
   - Delayed dashboard and traffic monitor timers to prevent immediate refresh
   - Removed stale cache check that triggered fetch on navigation
   - Files: `lib/providers/app_providers.dart`, `lib/screens/dashboard/dashboard_screen.dart`, `lib/screens/dashboard/widgets/traffic_monitor_widgets.dart`

2. **Platform Becoming "Unknown"** - Fixed race conditions and data validation
   - Added `_isFetching` flag to prevent concurrent fetches
   - Added better data validation for API responses
   - Added `_safeString()` helper to handle null/empty strings
   - Files: `lib/screens/dashboard/dashboard_screen.dart`, `lib/services/models.dart`

3. **Graph Time Labels Resetting** - Fixed elapsed time calculation
   - Changed x-coordinates to use actual timestamps instead of relative positions
   - Added `_formatElapsedTime()` for proper time formatting
   - Removed 60.0 clamp on `maxX` for continuous scrolling
   - File: `lib/screens/dashboard/widgets/combined_resource_chart.dart`

4. **No Initial Load Indicator** - Added lazy loading for first-time fetch
   - Added `_isInitialLoad` flag to track first data load
   - Show "Loading dashboard..." indicator on initial load
   - Improved chart empty state with loading indicator
   - Files: `lib/screens/dashboard/dashboard_screen.dart`, `lib/screens/dashboard/widgets/combined_resource_chart.dart`

5. **Auto-Refresh Timer Not Firing** - Fixed timer startup timing issue
   - Added `_timerStarted` flag and moved timer start to `build()` method
   - Timer now starts correctly when data becomes available via `ref.watch()`
   - File: `lib/screens/dashboard/widgets/traffic_monitor_widgets.dart`

6. **Network Permission Denied** - Added missing INTERNET permission
   - Added `INTERNET` and `ACCESS_NETWORK_STATE` permissions to AndroidManifest.xml
   - App can now connect to RouterOS devices on port 8728
   - File: `android/app/src/main/AndroidManifest.xml`

7. **Traffic Rates Showing "0 B/s"** - Fixed demo mode rate calculation
   - Added `_trafficRateService.calculateRates()` calls in `build()`, `refresh()`, and `silentRefresh()`
   - File: `lib/providers/app_providers.dart`

8. **Traffic Values Not Updating** - Fixed widget state synchronization
   - Added `_updateTrafficValues()` call in widget's `build()` method
   - File: `lib/screens/dashboard/widgets/traffic_monitor_widgets.dart`

9. **Developer Card Overflow** - Fixed responsive layout on small screens
   - Used `Expanded` widgets and `FittedBox` for text
   - File: `lib/screens/settings/settings_screen.dart`

10. **Hotspot Hosts Implementation Bugs** - Fixed compilation errors
    - Added missing `import 'dart:async';` for Timer support
    - Removed `mounted` property check (AsyncNotifier doesn't have mounted)
    - Removed `super.dispose()` call (AsyncNotifier doesn't have dispose method)
    - Fixed `const _buildLoadingState()` → `_buildLoadingState()`
    - Files: `lib/providers/app_providers.dart`, `lib/screens/hotspot_users/hotspot_hosts_screen.dart`

### Fixed Issues (March 27, 2026)

1. **RenderFlex Overflow on Login Screen** - Fixed overflow by changing CrossAxisAlignment
   - Changed `CrossAxisAlignment.stretch` to `CrossAxisAlignment.center` in login form
   - File: `lib/screens/auth/login_screen.dart`

2. **RenderFlex Overflow on Bottom Navigation** - Fixed 1px overflow on ConvexAppBar
   - Wrapped ConvexAppBar in SafeArea widget
   - File: `lib/screens/main/main_shell_screen.dart`

3. **Welcome Screen Cutout** - Fixed gradient not filling edge-to-edge
   - Added `SafeArea(bottom: false)` to allow gradient to extend to bottom while protecting from top notch
   - File: `lib/screens/welcome/welcome_screen.dart`

4. **Provider Modification During Build** - Fixed error when navigating to tabs
   - Moved `ref.read()` inside `Future.microtask()` to delay until after build phase
   - File: `lib/screens/main/main_shell_screen.dart`

5. **Quick Login Password Required** - Made password optional for quick login
   - Removed password validation check in `_quickLogin()` method
   - File: `lib/screens/welcome/welcome_screen.dart`

6. **Login Screen Password Empty** - Fixed saved connections not accepting password
   - Changed from hardcoded empty string to `_passwordController.text`
   - File: `lib/screens/auth/login_screen.dart`

### Fixed Issues (March 26, 2026)

1. **Android Back Button Behavior** - Fixed back button exiting app instead of returning to dashboard
   - Added `PopScope(canPop: true)` to Hotspot Users, User Profiles, and Hotspot Hosts screens
   - Files: `lib/screens/hotspot_users/hotspot_users_screen.dart`, `user_profiles_screen.dart`, `hotspot_hosts_screen.dart`

2. **Route Not Found Errors** - Fixed navigation issues after implementing ShellRoute
   - Updated all route references to use `/main` prefix
   - Updated login and welcome screens to navigate to `/main/dashboard`
   - Files: `lib/providers/app_providers.dart`, `lib/screens/auth/login_screen.dart`, `lib/screens/welcome/welcome_screen.dart`

3. **Provider Modification During Build** - Fixed "modifying provider while widget tree is building" error
   - Wrapped provider updates in `Future.microtask()` to delay until after build cycle
   - File: `lib/screens/main/main_shell_screen.dart`

### Fixed Issues (March 8, 2026)

1. **User Profile Creation** - Fixed "provider cannot depend on itself" error
   - Changed from `ref.invalidate()` to direct state updates
   - File: `lib/providers/app_providers.dart`

2. **Multiple User Profiles Not Showing** - Fixed RouterOS API response parsing
   - Added item to response when new `!re` is received
   - File: `lib/services/routeros_api_client.dart`

3. **Font Not Found** - Changed from Plus Jakarta Sans to Poppins
   - Updated theme to use available Google Font
   - File: `lib/theme/app_theme.dart`

---

_Last Updated: March 30, 2026_
