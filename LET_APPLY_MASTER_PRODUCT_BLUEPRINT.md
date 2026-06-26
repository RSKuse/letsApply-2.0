Or this project \# LET'S APPLY

## Master Product Blueprint

Version: 1.0 Roadmap
Date: June 24, 2026

---

## 1. Product Vision

### Mission

Become the leading African career platform that helps graduates, professionals, researchers, academics, public servants, and skilled workers discover opportunities, apply efficiently, build professional profiles, and manage their careers in one place.

### Core Problem

Current job platforms are fragmented or difficult to use:

- Indeed is cluttered.
- LinkedIn is a social network first.
- Careers24 feels outdated.
- Government vacancy sites are difficult to navigate.
- Company career pages are scattered across the web.

Let's Apply should bring these workflows into one modern mobile experience:

- Job discovery
- Smart applications
- CV management
- Application tracking
- Career growth

### Product Promise

The user should be able to open the app, discover relevant opportunities, understand the role quickly, apply with confidence, and track what happens next.

### Long-Term Product Vision

Let's Apply should become a career operating system for job seekers.

The target experience is:

"I don't need five different apps anymore. I only need Let's Apply."

The platform should combine the best parts of job discovery, CV building, AI writing, ATS optimization, application tracking, and career coaching into one ecosystem built for graduates, professionals, government job seekers, researchers, international applicants, remote workers, and executive applicants.

The long-term competitive reference is:

- LinkedIn
- Indeed
- Canva
- ChatGPT
- ATS optimizers
- Career coaches

but redesigned as one focused mobile career platform.

---

## 2. Design Philosophy

### Inspiration

The design direction is Starbucks-inspired in experience, not in coffee branding.

This means:

- Clean
- Premium
- Minimal
- Smooth
- Card based
- Friendly
- Spacious
- Easy to scan

### Reference Feel

- Starbucks app structure and polish
- LinkedIn Jobs clarity
- Apple Human Interface Guidelines

### Design Rules

- Use large touch targets.
- Use cards for job and profile content.
- Keep typography readable and calm.
- Make primary actions obvious.
- Avoid cluttered screens.
- Prioritize spacing, hierarchy, and motion.
- Make the app feel trustworthy enough for real career decisions.

---

## 3. Current Architecture

### Current Tabs

- Home
- Jobs
- Profile

### Current Status

The base application is working.

Implemented foundations:

- Firebase setup
- Firestore
- Authentication service
- Profile service
- Job service
- Navigation controllers
- Tab bar
- Home screen
- Jobs screen
- Profile screen
- Firestore loading

---

## 4. Product Phases

## Phase 0: Foundation

### Goal

Get the project compiling, connected, and able to load real data.

### Status

Complete.

### Completed

- Firebase configured
- Firestore connected
- Authentication service created
- Profile service created
- Job service created
- Navigation controllers created
- Tab bar created
- Home screen created
- Jobs screen created
- Profile screen created
- Firestore job loading implemented

---

## Phase 1: UI Stabilization and MVP

### Goal

Make the existing app feel professional, polished, and ready for real users.

### Status

Current phase.

### Home

Current:

- Loads jobs.

Needs:

- Better banner
- Better spacing
- Better cards
- Dynamic content
- Stronger first screen hierarchy

### Featured Jobs

Current:

- Works.

Needs:

- Company logos
- Salary
- Location
- Premium card styling
- Consistent empty and loading states

### Picked For You

Current:

- Works.

Needs:

- Better visual hierarchy
- Better typography
- Clearer role, company, salary, and location display

### Jobs

Current:

- Works as a jobs browsing screen.

Needs:

- Search
- Filters
- Better cards
- Loading state
- Empty state
- Error state

### Job Details

Current:

- Needs full product review.

Needs:

- Salary
- Description
- Responsibilities
- Requirements
- Company details
- Deadline
- Save job action
- Apply button

### Profile

Current:

- Functional only.

Needs:

- Profile picture
- User statistics
- Saved jobs
- Applications
- CV section
- Better layout and visual hierarchy

### Phase 1 Deliverables

- Beautiful Home
- Beautiful Jobs
- Beautiful Profile
- Job Details
- Apply Flow

### Target

Complete Phase 1 during the week of June 24, 2026.

### Phase 1 Definition of Done

- App compiles cleanly.
- Home, Jobs, Profile, and Job Details are visually consistent.
- Every major screen has loading, empty, and error states where relevant.
- Job cards show the essential decision-making information.
- Apply button exists and leads into a basic application flow.

---

## Phase 2: Real Applications

### Goal

Allow users to apply for jobs from inside the app.

### Core Flow

1. User taps Apply.
2. User uploads or selects a CV.
3. User confirms application details.
4. User submits.
5. Application is saved and tracked.

### Auto Apply Assistant Principle

The Auto Apply Assistant should prepare applications, not blindly send them.

The app may:

- Match the user's CV/profile to suitable jobs.
- Generate a tailored CV version.
- Generate a job-specific cover letter.
- Draft an email to the recruiter or employer.
- Prepare attachments.
- Present the package for approval.
- Track the application after submission.

The app must not submit or email anything without user approval.

This protects users from sending incorrect documents, applying to unsuitable roles, or breaching job-platform rules.

Product phrasing:

"Build an Auto Apply Assistant that can automatically prepare job applications by matching the user profile/CV to jobs, generating tailored CVs, cover letters and email messages, then presenting the completed application package for user approval before submission or email sending."
4. User submits application.
5. App stores application in Firestore.
6. User can view application status later.

### Firestore Collection

Collection: `applications`

Example document:

```json
{
  "userId": "123",
  "jobId": "456",
  "status": "submitted",
  "appliedDate": "2026-06-24T00:00:00Z"
}
```

### Application Statuses

- Draft
- Submitted
- Viewed
- Shortlisted
- Interview
- Rejected
- Accepted

### Phase 2 Deliverables

- Application model
- Application service
- Apply confirmation screen
- CV upload or CV selection
- Application submission to Firestore
- My Applications section in Profile
- Withdraw application action
- View Applications screen or Profile section

### Features

- Apply
- Withdraw
- View applications

### Status

Not started.

### Phase 2 Definition of Done

- A signed-in user can apply for a job.
- Duplicate applications are prevented or clearly handled.
- Applications are saved under the correct user.
- Profile shows submitted applications.
- The app handles submit loading, success, and failure states.

---

## Phase 3: Saved Jobs

### Goal

Create personal job collections so users can return to opportunities later.

### Features

- Save job
- Remove job
- Saved jobs

### Firestore Collection

Collection: `savedJobs`

### Status

Not started.

### Phase 3 Definition of Done

- User can save a job from Job Details.
- User can remove a saved job.
- User can view saved jobs from Profile or a dedicated Saved Jobs screen.

---

## Phase 4: CV Builder

### Goal

Let users create, manage, export, and reuse a professional CV inside the app.

### Major Feature

Users create:

- Personal details
- Education
- Experience
- Skills

The app generates:

- PDF CV

The user can export:

- PDF
- Email

### Status

Partially started. Needs redesign.

### Phase 4 Definition of Done

- User can enter CV information.
- User can preview a clean CV layout.
- User can generate a PDF CV.
- User can attach or select this CV during the Apply Flow.

---

## Phase 5: Search and Filters

### Goal

Create a professional job search experience.

### Filters

- Province
- City
- Salary
- Remote
- Category
- Company

### Search

- Keyword
- Company
- Skill

### Status

Not started.

### Phase 5 Definition of Done

- User can search jobs by keyword.
- User can filter jobs by common career criteria.
- Search and filters work together without confusing the user.

---

## Phase 6: Notifications

### Goal

Keep users informed about new opportunities and application updates.

### Features

- New jobs
- Application updates
- Interview invites
- Firebase push notifications

### Status

Not started.

### Phase 6 Definition of Done

- User can receive useful job and application notifications.
- Notifications are relevant and not noisy.
- Users can understand why they received a notification.

---

## Phase 7: Recruiter Portal

### Goal

Create a separate user type for recruiters and employers.

### Recruiters Can

- Post jobs
- Edit jobs
- View applicants
- Download CVs

### Firestore Collections

- `recruiters`
- `jobs`
- `applications`

### Status

Not started.

### Phase 7 Definition of Done

- Recruiters have a separate account type or role.
- Recruiters can manage job posts.
- Recruiters can review applicants and download CVs.

---

## Phase 8: AI Career Assistant

### Goal

Add a unique selling point by bringing AI career support into Let's Apply.

### CV Review

Flow:

1. User uploads CV.
2. AI reviews CV.
3. AI returns recommendations.

### Cover Letter Generator

User enters:

- Job title
- Company

AI generates:

- A tailored cover letter

### Interview Preparation

AI asks:

- Behavioural questions
- Technical questions

### Status

Future.

### Phase 8 Definition of Done

- User can run a basic CV review.
- User can generate a cover letter from a job.
- User can practice interview questions.
- AI output is presented as guidance, not as a guaranteed result.

---

## Phase 9: Premium Membership

### Goal

Create a subscription model for advanced career tools.

### Subscription

Monthly.

### Benefits

- AI CV review
- Unlimited CVs
- Premium jobs
- Priority applications

### Status

Future.

### Phase 9 Definition of Done

- Subscription value is clear.
- Free users can still use the core job search and application features.
- Premium features are meaningful enough to justify payment.

---

## Phase 10: Launch Version

### Goal

Prepare the app for App Store submission.

### Minimum Launch Checklist

User:

- Register
- Login
- Profile
- Upload CV
- Save jobs
- Apply

Jobs:

- Search
- Filter
- Categories

Admin:

- Post jobs
- Manage jobs

AI:

- Basic CV review

### Target

App Store submission.

### Status

Not started.

### Phase 10 Definition of Done

- The app compiles and passes release testing.
- Core flows are stable.
- Firebase rules are production-ready.
- App Store assets and metadata are prepared.
- Privacy and data usage are clearly documented.

---

## 5. MVP Scope

The first public-ready MVP should include:

- Authentication
- Home discovery
- Jobs browsing
- Job details
- Apply flow
- Profile basics
- CV upload or CV selection
- Saved jobs
- Application tracking

The MVP should not try to solve everything at once. The first win is making the user feel that applying for jobs is easier, cleaner, and more organized than the old way.

---

## 6. Core Data Model

### Job

Minimum fields:

- `id`
- `title`
- `company`
- `location`
- `salary`
- `description`
- `responsibilities`
- `requirements`
- `deadline`
- `imageURL`
- `companyLogoURL`
- `category`
- `employmentType`
- `createdAt`

### User Profile

Minimum fields:

- `userId`
- `fullName`
- `email`
- `phone`
- `location`
- `headline`
- `bio`
- `profileImageURL`
- `skills`
- `education`
- `experience`
- `cvURL`
- `createdAt`
- `updatedAt`

### Application

Minimum fields:

- `id`
- `userId`
- `jobId`
- `cvURL`
- `status`
- `appliedDate`
- `updatedAt`

### Saved Job

Minimum fields:

- `id`
- `userId`
- `jobId`
- `savedDate`

### Recruiter

Minimum fields:

- `id`
- `companyName`
- `contactName`
- `email`
- `role`
- `createdAt`

---

## 7. Immediate Build Order

### Step 1: Stabilize the Current UI

- Home banner
- Featured job cards
- Picked For You cards
- Jobs tab cards
- Profile layout

### Step 2: Finish Job Details

- Present complete job information.
- Add save action.
- Add apply action.
- Make the screen feel like the decision point before applying.

### Step 3: Build Apply Flow

- Apply button
- CV selection or upload
- Confirmation screen
- Firestore write to `applications`
- Success screen or toast

### Step 4: Add Application Tracking

- Add applications list to Profile.
- Display status.
- Link back to job details.

### Step 5: Improve Discovery

- Search
- Filters
- Categories
- Recommendations

---

## 8. Screen Blueprint

### Home

Purpose:

- Give the user a polished starting point and surface useful opportunities quickly.

Must include:

- Banner carousel
- Featured Jobs
- Picked For You
- Recently Added
- See All navigation

### Jobs

Purpose:

- Let the user browse, search, and filter opportunities.

Must include:

- Job list or grid
- Search bar
- Filter controls
- Job cards
- Empty state

### Job Details

Purpose:

- Help the user decide whether to apply.

Must include:

- Job title
- Company
- Location
- Salary
- Deadline
- Description
- Responsibilities
- Requirements
- Company details
- Save button
- Apply button

### Apply

Purpose:

- Let the user apply with confidence.

Must include:

- Selected job summary
- CV selection
- User details confirmation
- Submit button
- Loading state
- Success state
- Error state

### Profile

Purpose:

- Let the user manage their career identity and job search activity.

Must include:

- Profile picture
- User details
- Career headline
- CV section
- Saved jobs
- Applications
- Profile completion indicator

### CV Builder

Purpose:

- Let the user create and export a professional CV.

Must include:

- Personal details
- Education
- Experience
- Skills
- Preview
- PDF export

### Recruiter Portal

Purpose:

- Let recruiters post jobs and review applicants.

Must include:

- Recruiter profile
- Job posting form
- Posted jobs
- Applicant list
- CV download action

---

## 9. Product Principles

- The app should reduce stress, not add more steps.
- The user should always know what to do next.
- Career information must feel private, serious, and secure.
- Every screen should make the user more confident.
- Build the job seeker experience first, then employer tools.
- Keep the UI premium but practical.

---

## 10. Where We Are Today

Current progress:

- Phase 0: 100% complete
- Phase 1: 40% complete
- Phase 2: 0% complete
- Phase 3: 0% complete
- Phase 4: 15% complete
- Phase 5: 0% complete
- Phase 6: 0% complete
- Phase 7: 0% complete
- Phase 8: 0% complete
- Phase 9: 0% complete
- Phase 10: 0% complete

Current phase:

- Phase 1: UI Stabilization and MVP

Immediate next task:

- Job Details

Reason:

- Everything in the platform leads to this flow: Find Job -> Open Job -> Apply.
- Job Details is the heart of the product.
- Once Job Details and Apply Flow are complete, Let's Apply starts becoming a real job platform rather than a prototype.

---

## 11. Long-Term Vision

Version 3 should turn Let's Apply into a Career OS, not just a job board.

The full ecosystem can include:

- Jobs
- CVs
- Applications
- Recruiters
- AI coaching
- Interview preparation
- Learning courses
- Career tracking
- Salary insights
- Networking

---

## 12. Open Decisions

- Should CV upload use Firebase Storage immediately, or start with local placeholder state?
- Should the first MVP support only job seeker accounts, or include employer/admin roles now?
- Should applications be editable after submission?
- Should saved jobs appear in Profile or get their own tab later?
- Should the app include a fourth tab for Applications or CV once the feature set grows?
- Should AI be introduced in MVP or held for a later version?
- Should the recruiter portal live in the same app or in a separate web/admin experience?

---

## 13. Next Sprint

Recommended sprint focus:

1. Finish premium UI pass for Home and Jobs.
2. Complete Job Details screen.
3. Implement basic Apply Flow.
4. Add `applications` Firestore service methods.
5. Show submitted applications in Profile.

This keeps the work focused on the core product promise: discover a job, understand it, apply, and track it.
