# NagAgent Comprehensive Test Cases

## Overview
This document outlines comprehensive test cases for NagAgent, covering backend API, iOS application, integration testing, and user acceptance testing.

## Test Categories
1. **Unit Tests** - Individual functions and methods
2. **Integration Tests** - Component interactions
3. **API Tests** - REST endpoint functionality
4. **UI Tests** - iOS application interface
5. **User Acceptance Tests** - End-to-end workflows
6. **Performance Tests** - Load and stress testing
7. **Security Tests** - Authentication and authorization

---

## 1. Backend API Test Cases

### 1.1 Authentication Tests

#### Test Case: AUTH-001 - User Registration
**Objective**: Verify user can register successfully  
**Prerequisites**: Clean database state  
**Test Steps**:
1. Send POST to `/api/v1/auth/register`
2. Provide valid email, password, personality selection
3. Verify 201 response with user data
4. Verify user exists in database
5. Verify password is hashed

**Expected Results**:
- HTTP 201 Created
- Response includes user ID, email, personality
- Password is not returned in response
- Database contains new user record

**Test Data**:
```json
{
  "email": "test@nagagent.ai",
  "password": "SecurePass123!",
  "personality_type": "sassy"
}
```

#### Test Case: AUTH-002 - User Registration Validation
**Objective**: Verify registration validates input correctly  
**Test Steps**:
1. Test with invalid email formats
2. Test with weak passwords
3. Test with duplicate emails
4. Test with invalid personality types

**Expected Results**:
- HTTP 400 for invalid inputs
- Clear error messages
- No database records created

#### Test Case: AUTH-003 - User Login
**Objective**: Verify user can login with valid credentials  
**Test Steps**:
1. Register a test user
2. Send POST to `/api/v1/auth/login`
3. Provide valid credentials
4. Verify JWT tokens returned

**Expected Results**:
- HTTP 200 OK
- Access token and refresh token returned
- Token contains user claims

#### Test Case: AUTH-004 - Invalid Login
**Objective**: Verify login fails with invalid credentials  
**Test Steps**:
1. Send login request with wrong password
2. Send login request with non-existent email
3. Verify appropriate error responses

**Expected Results**:
- HTTP 401 Unauthorized
- No tokens returned
- Generic error message for security

#### Test Case: AUTH-005 - JWT Token Validation
**Objective**: Verify JWT tokens work for protected endpoints  
**Test Steps**:
1. Login to get valid token
2. Access protected endpoint with token
3. Test with expired token
4. Test with invalid token

**Expected Results**:
- Valid token allows access
- Invalid/expired tokens return 401

### 1.2 Task Management Tests

#### Test Case: TASK-001 - Create Daily Task
**Objective**: Verify user can create daily tasks  
**Prerequisites**: Authenticated user  
**Test Steps**:
1. Send POST to `/api/v1/tasks`
2. Provide task description and goal_id
3. Verify task created successfully
4. Check task appears in user's task list

**Test Data**:
```json
{
  "description": "Go to the gym for 1 hour",
  "goal_id": 1,
  "priority": "high",
  "estimated_duration": 60
}
```

**Expected Results**:
- HTTP 201 Created
- Task ID returned
- Task status is "pending"
- Created timestamp is current

#### Test Case: TASK-002 - Complete Task
**Objective**: Verify user can mark task as complete  
**Test Steps**:
1. Create a task
2. Send PUT to `/api/v1/tasks/{id}/complete`
3. Verify task status updated
4. Check completion timestamp

**Expected Results**:
- HTTP 200 OK
- Task status becomes "completed"
- Completed_at timestamp is set
- User gets completion response from AI

#### Test Case: TASK-003 - Submit Task Excuse
**Objective**: Verify excuse submission and AI response  
**Test Steps**:
1. Create a task
2. Send POST to `/api/v1/tasks/{id}/excuse`
3. Provide excuse text
4. Verify AI generates appropriate roast

**Test Data**:
```json
{
  "excuse": "I was too tired after work",
  "task_id": 1
}
```

**Expected Results**:
- HTTP 200 OK
- AI-generated roast response
- Excuse stored in database
- Task remains incomplete

#### Test Case: TASK-004 - List User Tasks
**Objective**: Verify user can retrieve their tasks  
**Test Steps**:
1. Create multiple tasks for user
2. Send GET to `/api/v1/tasks`
3. Test filtering by status
4. Test date range filtering

**Expected Results**:
- Only user's tasks returned
- Proper filtering applied
- Pagination works correctly
- Results sorted by creation date

### 1.3 AI Personality Tests

#### Test Case: AI-001 - Personality Response Generation
**Objective**: Verify AI generates personality-appropriate responses  
**Test Steps**:
1. Create tasks for different personality types
2. Submit various excuses
3. Complete tasks
4. Verify response tone matches personality

**Test Personalities**:
- Sergeant Slacker: Military, all-caps when angry
- Sassy Susan: Valley girl, uses emojis
- Passive-Aggressive Pat: Corporate, polite but judgmental
- Brutal Brandon: Direct, no filter

**Expected Results**:
- Each personality has distinct tone
- Responses are contextually appropriate
- No inappropriate or harmful content

#### Test Case: AI-002 - Morning Motivation
**Objective**: Verify morning check-in messages  
**Test Steps**:
1. Set user's timezone
2. Trigger morning check-in
3. Verify personality-appropriate message
4. Test with different task completion histories

**Expected Results**:
- Message tone reflects past performance
- Timezone-appropriate timing
- Encouraging but personality-consistent

#### Test Case: AI-003 - Daily Report Generation
**Objective**: Verify daily accountability reports  
**Test Steps**:
1. Complete various tasks throughout day
2. Submit multiple excuses
3. Generate daily report
4. Verify statistics and AI commentary

**Expected Results**:
- Accurate statistics calculated
- AI commentary reflects performance
- Report includes actionable insights

### 1.4 Goal Management Tests

#### Test Case: GOAL-001 - Create Goal
**Objective**: Verify user can create goals  
**Test Steps**:
1. Send POST to `/api/v1/goals`
2. Provide goal details
3. Verify goal created with proper defaults

**Test Data**:
```json
{
  "title": "Get Fit",
  "description": "Exercise regularly and eat healthy",
  "category": "health",
  "target_frequency": "daily",
  "start_date": "2024-01-01",
  "end_date": "2024-12-31"
}
```

#### Test Case: GOAL-002 - Goal Progress Tracking
**Objective**: Verify goal progress is calculated correctly  
**Test Steps**:
1. Create goal with tasks
2. Complete some tasks
3. Check goal progress percentage
4. Verify progress history

**Expected Results**:
- Progress percentage is accurate
- History tracks changes over time
- Streak counters work correctly

### 1.5 Report Generation Tests

#### Test Case: REPORT-001 - Daily Report
**Objective**: Verify daily reports generate correctly  
**Test Steps**:
1. Create tasks for current day
2. Complete some, excuse others
3. Generate daily report
4. Verify all metrics included

**Expected Metrics**:
- Tasks completed vs. total
- Completion percentage
- Most common excuses
- Streak status
- AI personality commentary

#### Test Case: REPORT-002 - Weekly Report
**Objective**: Verify weekly summary reports  
**Test Steps**:
1. Create data for full week
2. Generate weekly report
3. Verify trends and insights
4. Check comparative analysis

**Expected Results**:
- Weekly trends shown
- Best and worst days identified
- Recommendations provided

---

## 2. iOS Application Test Cases

### 2.1 User Interface Tests

#### Test Case: UI-001 - App Launch and Onboarding
**Objective**: Verify app launches and onboarding works  
**Test Steps**:
1. Install fresh app
2. Launch application
3. Complete onboarding flow
4. Verify personality quiz
5. Complete goal setup

**Expected Results**:
- App launches without crashes
- Onboarding is intuitive
- Personality quiz works correctly
- User can set initial goals

#### Test Case: UI-002 - Task Creation Interface
**Objective**: Verify task creation UI works properly  
**Test Steps**:
1. Navigate to task creation screen
2. Enter task details
3. Select goal association
4. Save task
5. Verify task appears in list

**Expected Results**:
- Form validation works
- Task saves successfully
- UI updates immediately
- Loading states are shown

#### Test Case: UI-003 - Push Notification Handling
**Objective**: Verify push notifications display and navigate correctly  
**Test Steps**:
1. Enable push notifications
2. Trigger scheduled notification
3. Tap notification
4. Verify app opens to correct screen

**Expected Results**:
- Notifications appear on time
- Tapping navigates correctly
- Badge count updates
- Notification content is personality-appropriate

### 2.2 Offline Functionality Tests

#### Test Case: OFFLINE-001 - Offline Task Creation
**Objective**: Verify app works without internet connection  
**Test Steps**:
1. Disable internet connection
2. Create tasks offline
3. Mark tasks as complete
4. Re-enable internet
5. Verify data syncs

**Expected Results**:
- Tasks can be created offline
- Local storage maintains data
- Sync occurs when online
- No data loss

#### Test Case: OFFLINE-002 - Conflict Resolution
**Objective**: Verify offline changes merge correctly  
**Test Steps**:
1. Create task online
2. Go offline, modify task
3. Online, modify same task
4. Come back online
5. Verify conflict resolution

**Expected Results**:
- Conflicts are detected
- User can choose resolution
- Data integrity maintained

### 2.3 Subscription and Payment Tests

#### Test Case: SUB-001 - Subscription Purchase
**Objective**: Verify in-app purchase flow  
**Test Steps**:
1. Navigate to premium features
2. Select subscription tier
3. Complete Apple Pay flow
4. Verify premium features unlock

**Expected Results**:
- Payment flow works smoothly
- Receipt validation succeeds
- Premium features immediately available
- Subscription status updates

#### Test Case: SUB-002 - Subscription Management
**Objective**: Verify subscription can be managed  
**Test Steps**:
1. Cancel subscription in iOS Settings
2. Verify app reflects cancellation
3. Test grace period handling
4. Verify feature lockdown

**Expected Results**:
- Cancellation detected
- Grace period respected
- Features locked at expiration
- User notified appropriately

---

## 3. Integration Test Cases

### 3.1 API Integration Tests

#### Test Case: INT-001 - End-to-End User Journey
**Objective**: Verify complete user workflow  
**Test Steps**:
1. Register new user
2. Complete onboarding
3. Create goals and tasks
4. Submit excuses and completions
5. Generate reports
6. Upgrade to premium

**Expected Results**:
- All steps complete successfully
- Data flows correctly between components
- AI responses are consistent
- Premium features work

#### Test Case: INT-002 - Real-time Synchronization
**Objective**: Verify real-time data sync  
**Test Steps**:
1. Login on multiple devices
2. Create task on device A
3. Verify task appears on device B
4. Complete task on device B
5. Verify update on device A

**Expected Results**:
- Changes sync in near real-time
- No data conflicts
- Both devices show consistent state

### 3.2 Third-Party Service Integration

#### Test Case: EXT-001 - OpenAI API Integration
**Objective**: Verify OpenAI service integration  
**Test Steps**:
1. Submit various excuse types
2. Test with different personalities
3. Verify response quality
4. Test error handling

**Expected Results**:
- AI responses are relevant
- Personality styles are distinct
- Error handling for API failures
- Rate limiting respected

#### Test Case: EXT-002 - Push Notification Service
**Objective**: Verify APNs integration  
**Test Steps**:
1. Schedule various notification types
2. Test with different timezones
3. Verify delivery and tracking
4. Test notification preferences

**Expected Results**:
- Notifications deliver reliably
- Timezone handling is correct
- User preferences respected
- Delivery tracking works

---

## 4. Performance Test Cases

### 4.1 Load Testing

#### Test Case: PERF-001 - API Load Test
**Objective**: Verify API handles expected load  
**Test Configuration**:
- 100 concurrent users
- 1000 requests per minute
- Mix of endpoints

**Test Steps**:
1. Ramp up users gradually
2. Maintain load for 15 minutes
3. Monitor response times
4. Check error rates

**Expected Results**:
- Response time < 500ms for 95% of requests
- Error rate < 1%
- No memory leaks
- Database connections stable

#### Test Case: PERF-002 - Database Performance
**Objective**: Verify database performance under load  
**Test Steps**:
1. Create large dataset (10k users, 100k tasks)
2. Run concurrent queries
3. Monitor database metrics
4. Test complex report queries

**Expected Results**:
- Query response times acceptable
- No table locks
- Index utilization optimal
- Memory usage stable

### 4.2 Mobile Performance

#### Test Case: PERF-003 - iOS App Performance
**Objective**: Verify app performance on devices  
**Test Steps**:
1. Test on various iOS devices
2. Monitor memory usage
3. Check battery impact
4. Test with large datasets

**Expected Results**:
- Smooth scrolling and animations
- Memory usage < 100MB
- Minimal battery drain
- Fast startup time

---

## 5. Security Test Cases

### 5.1 Authentication Security

#### Test Case: SEC-001 - Password Security
**Objective**: Verify password handling is secure  
**Test Steps**:
1. Create user with password
2. Verify password is hashed
3. Test against common attacks
4. Verify password policies

**Expected Results**:
- Passwords never stored in plain text
- Strong hashing algorithm used
- Brute force protection active
- Password policies enforced

#### Test Case: SEC-002 - JWT Security
**Objective**: Verify JWT implementation is secure  
**Test Steps**:
1. Analyze JWT token structure
2. Test token expiration
3. Verify signature validation
4. Test token refresh flow

**Expected Results**:
- Tokens are properly signed
- Expiration times enforced
- Refresh tokens work correctly
- No sensitive data in payload

### 5.2 Data Protection

#### Test Case: SEC-003 - Data Encryption
**Objective**: Verify sensitive data is encrypted  
**Test Steps**:
1. Check database encryption
2. Verify API traffic encryption
3. Test local storage security
4. Verify backup encryption

**Expected Results**:
- Database uses encryption at rest
- All API traffic uses HTTPS/TLS
- Local storage is encrypted
- Backups are encrypted

#### Test Case: SEC-004 - Access Control
**Objective**: Verify users can only access their data  
**Test Steps**:
1. Create multiple users
2. Try to access other users' data
3. Test authorization on all endpoints
4. Verify admin access controls

**Expected Results**:
- Users can only see their data
- Unauthorized access returns 403
- Admin controls work properly
- No data leakage between users

---

## 6. User Acceptance Test Cases

### 6.1 Core User Journeys

#### Test Case: UAT-001 - New User Experience
**Objective**: Verify complete new user experience  
**Scenario**: New user discovers NagAgent and starts using it  
**Test Steps**:
1. Download app from App Store
2. Complete registration and onboarding
3. Set up first goal and tasks
4. Receive first AI interaction
5. Complete first task
6. Receive daily report

**Success Criteria**:
- User understands app purpose
- Onboarding is engaging
- First AI interaction is delightful
- User wants to continue using app

#### Test Case: UAT-002 - Power User Workflow
**Objective**: Verify advanced user features work  
**Scenario**: Experienced user managing multiple goals  
**Test Steps**:
1. Create multiple goals with tasks
2. Use different personalities
3. Generate detailed reports
4. Share achievements socially
5. Upgrade to premium features

**Success Criteria**:
- Multiple goals managed easily
- Premium features provide value
- Sharing functionality works
- User remains engaged long-term

### 6.2 Error Recovery

#### Test Case: UAT-003 - Network Interruption Recovery
**Objective**: Verify user experience during network issues  
**Test Steps**:
1. Start using app normally
2. Simulate network interruption
3. Continue using app offline
4. Restore network connection
5. Verify data recovery

**Success Criteria**:
- User can continue working offline
- No data is lost
- Recovery is seamless
- User is informed of status

---

## 7. Regression Test Suite

### 7.1 Automated Regression Tests

#### Critical Path Tests
- User registration and login
- Task creation and completion
- AI response generation
- Report generation
- Push notifications
- Subscription management

#### API Endpoint Tests
- All REST endpoints
- Authentication flows
- Error handling
- Rate limiting
- Data validation

#### UI Regression Tests
- Key user flows
- Navigation
- Form submissions
- Notification handling
- Subscription screens

### 7.2 Manual Regression Tests

#### Visual and UX Tests
- App appearance on different devices
- Accessibility features
- Animation smoothness
- Loading states
- Error messages

#### Integration Tests
- Third-party service connections
- Real device testing
- Different iOS versions
- Various network conditions

---

## Test Data Management

### Test User Accounts
```json
{
  "test_users": [
    {
      "email": "sergeant@test.nagagent.ai",
      "personality": "sergeant",
      "goals": ["fitness", "productivity"],
      "subscription": "free"
    },
    {
      "email": "sassy@test.nagagent.ai", 
      "personality": "sassy",
      "goals": ["health", "career"],
      "subscription": "pro"
    }
  ]
}
```

### Test Goals and Tasks
```json
{
  "test_goals": [
    {
      "title": "Get Fit",
      "category": "health",
      "tasks": [
        "Go to gym",
        "Run 3 miles",
        "Eat healthy lunch"
      ]
    }
  ]
}
```

## Test Environment Requirements

### Backend Testing Environment
- PostgreSQL test database
- Redis test instance
- OpenAI API test key
- Test Twilio account
- Isolated test data

### iOS Testing Environment
- Physical devices (iPhone, iPad)
- iOS Simulator
- TestFlight for beta testing
- Test Apple ID accounts
- Mock push notification setup

## Test Execution Schedule

### Pre-Release Testing
1. **Unit Tests** - Run on every commit
2. **Integration Tests** - Run on every PR
3. **UI Tests** - Run nightly
4. **Performance Tests** - Run weekly
5. **Security Tests** - Run monthly
6. **UAT** - Run before each release

### Release Testing
1. Full regression suite
2. Manual testing on target devices
3. Performance validation
4. Security audit
5. User acceptance sign-off

## Success Metrics

### Test Coverage Targets
- Unit Test Coverage: > 90%
- API Test Coverage: 100% of endpoints
- UI Test Coverage: > 80% of critical paths
- Integration Test Coverage: All major workflows

### Performance Targets
- API Response Time: < 200ms (95th percentile)
- App Launch Time: < 3 seconds
- Battery Usage: < 5% per hour of active use
- Memory Usage: < 100MB on iPhone

### Quality Gates
- All critical tests must pass
- No high-severity security issues
- Performance targets must be met
- User acceptance criteria satisfied

---

**Note**: This test plan should be updated regularly as features are added and modified. All test cases should be reviewed and approved by the development team and stakeholders before implementation.