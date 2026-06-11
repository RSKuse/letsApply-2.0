# Let’s Apply master UI blueprint and repair notes

## UI direction
The app now uses the Starbucks structure as the visual foundation, but all Starbucks business terms have been converted into job-platform terms.

| Starbucks component | Let’s Apply equivalent | Purpose |
|---|---|---|
| HomeViewController | HomeViewController | Main dashboard using a table view with sections |
| AdvertContainerView | AdvertContainerView | Horizontal banner carousel for job/app messaging |
| AdvertCell | AdvertCell | Banner card for Let’s Apply messaging |
| FeaturedProductsTableViewCell | FeaturedJobsTableViewCell | Horizontal featured jobs row inside the home table |
| FeaturedProductCollectionCell | FeaturedJobCollectionCell | Featured job card |
| ProductTableViewCell | JobTableViewCell | Vertical picked-for-you job list cell |
| TableSectionHeaderView | TableSectionHeaderView | Section title with See All button |
| ProductsViewController | JobsCollectionViewController | See All screen for featured or picked jobs |
| ProductViewController | JobDetailsViewController | Full job details screen with Apply button |
| Cart/Profile area | ProfileViewController | User profile editing and logout |

## Fixed files
- Models/Job.swift
- Models/UserProfile.swift
- Services/AppDelegate.swift
- Services/FirestoreService.swift
- View/MainTabBarController.swift
- View/Controllers/HomeViewController/HomeViewController.swift
- View/Controllers/HomeViewController/AdvertContainerView/AdvertCell.swift
- View/Controllers/HomeViewController/AdvertContainerView/AdvertContainerView.swift
- View/Controllers/HomeViewController/FeaturedJobsCollectionView/MostAppliedView.swift
- View/Controllers/HomeViewController/FeaturedJobsCollectionView/FeaturedJobCollectionCell.swift
- View/Controllers/HomeViewController/FeaturedJobsCollectionView/FeaturedJobsTableViewCell.swift
- View/Controllers/HomeViewController/TableSectionHeaderView.swift.swift
- View/Controllers/JobsViewController/JobTableViewCell.swift
- View/Controllers/JobListViewController/ViewModel/JobViewModel.swift
- View/Controllers/JobListViewController/CollectionView/JobCollectionViewCell.swift
- View/Controllers/JobListViewController/JobListViewController.swift
- View/Controllers/JobListViewController/CollectionView/JobsCollectionViewController.swift.swift
- View/Controllers/JobDetailsViewController/JobDetailsViewController.swift
- View/Controllers/ProfileViewController/ProfileSetupViewController.swift

## Important cleanup notes
The fixed project is the better base. The original project contains more duplicate classes and half-converted Starbucks code.

Several old files are still present but commented out. They should not block compilation because their active code has been cleaned. If Xcode still reports duplicate stringdata, remove stale duplicate file references from Build Phases or delete duplicate old Swift files that are no longer used.

## Screen blueprint
Home tab:
- Banner carousel at the top.
- Featured section with horizontal scrolling jobs.
- Picked For You section with vertical job rows.
- See All opens a two-column jobs grid.
- Tapping any job opens JobDetailsViewController.

Jobs tab:
- Two-column job grid.
- Fetches Firestore jobs asynchronously.
- Tapping any job opens details.

Job Details:
- Large image/header area.
- Job title, company, location, salary, description, requirements, responsibilities and deadline.
- Apply Now button works and shows confirmation.

Profile tab:
- Scrollable form.
- Prevents freezing when no Firebase user exists.
- Save button writes profile data.
- Logout button works safely.

CV tab:
- Still uses the existing CVBuilderViewController placeholder.

## Firestore fallback
If Firestore has no jobs or a network error occurs, the app now displays sample jobs so the UI is never blank during testing.
