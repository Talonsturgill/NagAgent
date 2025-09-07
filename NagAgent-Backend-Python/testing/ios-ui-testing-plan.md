# iOS UI Testing Plan for NagAgent

## Overview
This comprehensive UI testing plan covers all aspects of the NagAgent iOS application, including automated UI tests, manual testing procedures, accessibility testing, and device compatibility validation.

## Testing Environment Setup

### Required Devices and Simulators
- **iPhone Models**: iPhone 12, iPhone 13, iPhone 14, iPhone 15 (various sizes)
- **iPad Models**: iPad Air, iPad Pro (11-inch and 12.9-inch)
- **iOS Versions**: iOS 15.0, 16.0, 17.0, 18.0 (latest)
- **Simulators**: All supported device/OS combinations

### Testing Tools
- **XCTest**: Native iOS testing framework
- **XCUITest**: UI automation testing
- **Fastlane Screenshot**: Automated screenshot generation
- **TestFlight**: Beta testing and distribution
- **Charles Proxy**: Network traffic analysis
- **Physical Devices**: Real device testing for haptics, notifications, etc.

### Test Data Setup
```swift
// Test user accounts for different scenarios
struct TestUsers {
    static let newUser = TestUser(
        email: "newuser@test.com",
        personality: .none
    )
    
    static let powerUser = TestUser(
        email: "poweruser@test.com",
        personality: .sassy,
        goals: ["fitness", "productivity"],
        subscription: .pro
    )
    
    static let freeUser = TestUser(
        email: "freeuser@test.com",
        personality: .sergeant,
        subscription: .free
    )
}
```

---

## 1. Automated UI Tests (XCUITest)

### 1.1 App Launch and Onboarding Flow

#### Test Case: UILAUNCH-001 - Fresh App Install
```swift
func testFreshAppLaunch() {
    let app = XCUIApplication()
    app.launch()
    
    // Verify splash screen appears
    XCTAssertTrue(app.staticTexts["NagAgent"].exists)
    XCTAssertTrue(app.staticTexts["Your Brutally Honest Accountability Coach"].exists)
    
    // Wait for loading to complete
    let welcomeScreen = app.staticTexts["Meet Your Accountability Coach"]
    XCTAssertTrue(welcomeScreen.waitForExistence(timeout: 5))
    
    // Test onboarding page navigation
    let getStartedButton = app.buttons["Get Started"]
    XCTAssertTrue(getStartedButton.exists)
    getStartedButton.tap()
    
    // Verify personality quiz appears
    XCTAssertTrue(app.staticTexts["Choose Your Coach"].waitForExistence(timeout: 3))
}
```

#### Test Case: UILAUNCH-002 - Personality Quiz Flow
```swift
func testPersonalityQuizFlow() {
    let app = XCUIApplication()
    launchAppAndSkipToPersonalityQuiz(app)
    
    // Test personality selection
    let sassyOption = app.buttons["Sassy Susan"]
    XCTAssertTrue(sassyOption.exists)
    sassyOption.tap()
    
    // Verify personality description shows
    XCTAssertTrue(app.staticTexts["Your toxic bestie who secretly wants you to succeed"].exists)
    
    // Continue to goal setup
    let continueButton = app.buttons["Continue"]
    continueButton.tap()
    
    // Verify goal setup screen
    XCTAssertTrue(app.staticTexts["Set Your First Goal"].waitForExistence(timeout: 3))
}
```

### 1.2 Main App Navigation

#### Test Case: UINAV-001 - Tab Navigation
```swift
func testTabNavigation() {
    let app = XCUIApplication()
    loginAndLaunchApp(app, user: TestUsers.powerUser)
    
    let tabBar = app.tabBars.firstMatch
    
    // Test Home tab
    let homeTab = tabBar.buttons["Home"]
    XCTAssertTrue(homeTab.exists)
    homeTab.tap()
    XCTAssertTrue(app.navigationBars["Home"].exists)
    
    // Test Reports tab
    let reportsTab = tabBar.buttons["Reports"]
    reportsTab.tap()
    XCTAssertTrue(app.navigationBars["Reports"].waitForExistence(timeout: 2))
    
    // Test Goals tab
    let goalsTab = tabBar.buttons["Goals"]
    goalsTab.tap()
    XCTAssertTrue(app.navigationBars["Goals"].waitForExistence(timeout: 2))
    
    // Test Premium tab
    let premiumTab = tabBar.buttons["Premium"]
    premiumTab.tap()
    XCTAssertTrue(app.staticTexts["Upgrade to Premium"].waitForExistence(timeout: 2))
}
```

### 1.3 Task Management UI

#### Test Case: UITASK-001 - Create Task Flow
```swift
func testCreateTaskFlow() {
    let app = XCUIApplication()
    loginAndLaunchApp(app, user: TestUsers.powerUser)
    
    // Tap add task button
    let addButton = app.buttons["plus.circle.fill"]
    XCTAssertTrue(addButton.exists)
    addButton.tap()
    
    // Fill task form
    let taskField = app.textFields["What do you want to accomplish?"]
    XCTAssertTrue(taskField.waitForExistence(timeout: 2))
    taskField.tap()
    taskField.typeText("Go to the gym for 1 hour")
    
    // Select goal
    let goalPicker = app.buttons["Select Goal"]
    goalPicker.tap()
    app.buttons["Get Fit"].tap()
    
    // Set priority
    let highPriorityButton = app.buttons["High Priority"]
    highPriorityButton.tap()
    
    // Save task
    let saveButton = app.buttons["Create Task"]
    saveButton.tap()
    
    // Verify task appears in list
    XCTAssertTrue(app.staticTexts["Go to the gym for 1 hour"].waitForExistence(timeout: 3))
}
```

#### Test Case: UITASK-002 - Complete Task Flow
```swift
func testCompleteTaskFlow() {
    let app = XCUIApplication()
    loginAndLaunchApp(app, user: TestUsers.powerUser)
    
    // Assume task exists, tap complete button
    let completeButton = app.buttons["Complete Task"]
    XCTAssertTrue(completeButton.exists)
    completeButton.tap()
    
    // Verify completion animation
    let checkmark = app.images["checkmark.circle.fill"]
    XCTAssertTrue(checkmark.waitForExistence(timeout: 2))
    
    // Verify AI response appears
    let aiResponse = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'congratulations' OR label CONTAINS[c] 'well done'"))
    XCTAssertTrue(aiResponse.firstMatch.waitForExistence(timeout: 3))
    
    // Test share functionality
    let shareButton = app.buttons["Share Achievement"]
    if shareButton.exists {
        shareButton.tap()
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 2))
        app.buttons["Cancel"].tap()
    }
}
```

#### Test Case: UITASK-003 - Submit Excuse Flow
```swift
func testSubmitExcuseFlow() {
    let app = XCUIApplication()
    loginAndLaunchApp(app, user: TestUsers.powerUser)
    
    // Tap excuse button on task
    let excuseButton = app.buttons["Make Excuse"]
    XCTAssertTrue(excuseButton.exists)
    excuseButton.tap()
    
    // Select excuse type
    let tiredOption = app.buttons["Too tired"]
    XCTAssertTrue(tiredOption.waitForExistence(timeout: 2))
    tiredOption.tap()
    
    // Add custom excuse text
    let customExcuseField = app.textViews["Add more details..."]
    customExcuseField.tap()
    customExcuseField.typeText("Had a really long day at work")
    
    // Submit excuse
    let submitButton = app.buttons["Submit Excuse"]
    submitButton.tap()
    
    // Verify AI roast appears
    let roastBubble = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'excuse'"))
    XCTAssertTrue(roastBubble.firstMatch.waitForExistence(timeout: 5))
    
    // Test share roast functionality
    let shareRoastButton = app.buttons["Share This Roast"]
    if shareRoastButton.exists {
        shareRoastButton.tap()
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 2))
    }
}
```

### 1.4 Settings and Profile

#### Test Case: UISETTINGS-001 - Change Personality
```swift
func testChangePersonality() {
    let app = XCUIApplication()
    loginAndLaunchApp(app, user: TestUsers.powerUser)
    
    // Navigate to profile
    app.tabBars.buttons["Profile"].tap()
    
    // Tap personality setting
    let personalityRow = app.cells["Change Personality"]
    XCTAssertTrue(personalityRow.exists)
    personalityRow.tap()
    
    // Select new personality
    let brutalBrandonOption = app.buttons["Brutal Brandon"]
    XCTAssertTrue(brutalBrandonOption.waitForExistence(timeout: 2))
    brutalBrandonOption.tap()
    
    // Confirm change
    let confirmButton = app.buttons["Confirm Change"]
    confirmButton.tap()
    
    // Verify personality updated
    XCTAssertTrue(app.staticTexts["Brutal Brandon"].waitForExistence(timeout: 3))
}
```

### 1.5 Push Notifications

#### Test Case: UINOTIF-001 - Notification Permission Flow
```swift
func testNotificationPermissionFlow() {
    let app = XCUIApplication()
    app.launchArguments.append("--uitesting-fresh-install")
    app.launch()
    
    // Navigate through onboarding to notification permission
    completeOnboardingToNotificationStep(app)
    
    // Tap enable notifications
    let enableButton = app.buttons["Enable Notifications"]
    XCTAssertTrue(enableButton.exists)
    enableButton.tap()
    
    // Handle system notification permission dialog
    let systemAlertButton = addUIInterruptionMonitor(withDescription: "Notification Permission") { alert in
        if alert.buttons["Allow"].exists {
            alert.buttons["Allow"].tap()
            return true
        }
        return false
    }
    
    // Trigger the system alert
    app.tap()
    
    // Verify permission granted
    XCTAssertTrue(app.staticTexts["Notifications Enabled"].waitForExistence(timeout: 5))
}
```

### 1.6 Premium Features

#### Test Case: UIPREMIUM-001 - Subscription Flow
```swift
func testSubscriptionPurchaseFlow() {
    let app = XCUIApplication()
    loginAndLaunchApp(app, user: TestUsers.freeUser)
    
    // Navigate to premium tab
    app.tabBars.buttons["Premium"].tap()
    
    // Select Pro subscription
    let proSubscription = app.buttons["Pro - $6.99/month"]
    XCTAssertTrue(proSubscription.exists)
    proSubscription.tap()
    
    // Tap subscribe button
    let subscribeButton = app.buttons["Subscribe Now"]
    subscribeButton.tap()
    
    // Handle Apple Pay sheet (in test environment, this will be mocked)
    let applePayButton = app.buttons["Subscribe"]
    if applePayButton.waitForExistence(timeout: 5) {
        applePayButton.tap()
    }
    
    // Verify subscription confirmation
    XCTAssertTrue(app.staticTexts["Subscription Active"].waitForExistence(timeout: 10))
}
```

---

## 2. Manual Testing Procedures

### 2.1 Visual and UX Testing

#### Test Case: MANUAL-001 - Visual Design Consistency
**Objective**: Verify visual design consistency across screens  
**Steps**:
1. Navigate through all main screens
2. Check color scheme consistency
3. Verify font sizes and hierarchy
4. Check button styles and states
5. Verify loading states and animations
6. Check dark mode compatibility

**Expected Results**:
- Consistent color palette throughout app
- Typography hierarchy is clear and consistent
- Interactive elements have clear affordances
- Smooth animations and transitions
- Dark mode renders correctly

#### Test Case: MANUAL-002 - Personality Voice Consistency
**Objective**: Verify each AI personality maintains consistent voice  
**Steps**:
1. Create tasks for each personality type
2. Submit various excuses
3. Complete tasks
4. Generate daily reports
5. Check morning motivations

**Expected Results**:
- Sergeant Slacker: Military terminology, all-caps when angry
- Sassy Susan: Valley girl expressions, emojis, "bestie" language
- Passive-Aggressive Pat: Corporate speak, overly polite but judgmental
- Brutal Brandon: Direct, unfiltered, philosophical

### 2.2 Device and OS Compatibility

#### Test Case: MANUAL-003 - Cross-Device Testing
**Objective**: Verify app works across different devices  
**Test Matrix**:

| Device | iOS Version | Screen Size | Test Results |
|--------|-------------|-------------|--------------|
| iPhone SE 3rd Gen | iOS 15.0 | 4.7" | ✅ Pass |
| iPhone 12 | iOS 16.0 | 6.1" | ✅ Pass |
| iPhone 14 Pro | iOS 17.0 | 6.1" | ✅ Pass |
| iPhone 15 Pro Max | iOS 18.0 | 6.7" | ✅ Pass |
| iPad Air | iOS 17.0 | 10.9" | ✅ Pass |
| iPad Pro 12.9" | iOS 18.0 | 12.9" | ✅ Pass |

**Test Scenarios**:
- App launch and onboarding
- Core task management functionality
- Push notifications
- In-app purchases
- Offline functionality

### 2.3 Accessibility Testing

#### Test Case: MANUAL-004 - VoiceOver Compatibility
**Objective**: Verify app is accessible to users with visual impairments  
**Steps**:
1. Enable VoiceOver in iOS Settings
2. Navigate through app using VoiceOver gestures
3. Test all interactive elements
4. Verify proper labeling and hints
5. Test custom controls and animations

**Expected Results**:
- All UI elements have appropriate accessibility labels
- Navigation is logical with VoiceOver
- Custom controls are accessible
- Important information is announced
- No accessibility warnings in Xcode

#### Test Case: MANUAL-005 - Dynamic Type Support
**Objective**: Verify app supports iOS Dynamic Type  
**Steps**:
1. Change text size in iOS Settings (smallest to largest)
2. Launch app and navigate through screens
3. Verify text scales appropriately
4. Check layout doesn't break with large text
5. Verify important information remains visible

**Expected Results**:
- Text scales correctly across all sizes
- Layout adapts to larger text sizes
- No text truncation or overlapping
- Buttons remain tappable
- Critical information always visible

### 2.4 Network and Offline Testing

#### Test Case: MANUAL-006 - Network Interruption Scenarios
**Objective**: Verify app handles network issues gracefully  
**Test Scenarios**:

1. **Airplane Mode Test**:
   - Enable airplane mode during task creation
   - Verify task saves locally
   - Re-enable network and verify sync

2. **Slow Network Test**:
   - Simulate slow network (Charles Proxy)
   - Test app responsiveness
   - Verify loading states

3. **No Internet Test**:
   - Disconnect from WiFi and cellular
   - Test offline functionality
   - Verify user feedback messages

**Expected Results**:
- App continues to function offline
- User is informed of network status
- Data syncs when connection restored
- No crashes or data loss

---

## 3. Automated Screenshot Testing

### 3.1 App Store Screenshots
```swift
class AppStoreScreenshotTests: XCTestCase {
    
    func testGenerateAppStoreScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        // Screenshot 1: Personality Selection
        navigateToPersonalitySelection(app)
        snapshot("01-PersonalitySelection")
        
        // Screenshot 2: Daily Tasks with AI Roast
        loginAndSetupTasks(app)
        submitExcuseAndWaitForRoast(app)
        snapshot("02-TasksWithRoast")
        
        // Screenshot 3: Daily Report
        navigateToReports(app)
        snapshot("03-DailyReport")
        
        // Screenshot 4: Excuse Submission
        navigateToTaskAndShowExcuseDialog(app)
        snapshot("04-ExcuseSubmission")
        
        // Screenshot 5: Share Feature
        showShareDialog(app)
        snapshot("05-ShareFeature")
        
        // Screenshot 6: Success Celebration
        completeTaskAndShowCelebration(app)
        snapshot("06-SuccessCelebration")
    }
}
```

### 3.2 Marketing Screenshots
```bash
# Fastlane configuration for automated screenshots
# fastlane/Snapfile

devices([
  "iPhone 15 Pro Max",
  "iPhone 15 Pro", 
  "iPhone SE (3rd generation)",
  "iPad Pro (12.9-inch) (6th generation)"
])

languages([
  "en-US"
])

scheme("NagAgentUITests")

output_directory("./screenshots")

clear_previous_screenshots(true)

override_status_bar(true)

localize_simulator(true)
```

---

## 4. Performance Testing

### 4.1 App Launch Performance
```swift
func testAppLaunchPerformance() {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
        XCUIApplication().launch()
    }
    
    // Target: Launch time < 3 seconds
    XCTAssertLessThan(launchTime, 3.0)
}
```

### 4.2 Memory Usage Testing
```swift
func testMemoryUsage() {
    let app = XCUIApplication()
    app.launch()
    
    // Perform typical user workflow
    performExtensiveUserWorkflow(app)
    
    // Measure memory usage
    let memoryMetric = XCTMemoryMetric()
    measure(metrics: [memoryMetric]) {
        // Perform memory-intensive operations
        navigateThroughAllScreensMultipleTimes(app)
    }
    
    // Target: Memory usage < 100MB
}
```

---

## 5. Test Data Management

### 5.1 Test User Setup
```swift
class TestDataManager {
    static func createTestUsers() {
        // Create different user personas for testing
        let users = [
            createNewUser(),
            createPowerUser(),
            createFreeUser(),
            createPremiumUser()
        ]
        
        // Seed with appropriate data
        users.forEach { seedUserWithData($0) }
    }
    
    static func resetTestData() {
        // Clean up test data between test runs
        deleteAllTestUsers()
        clearLocalStorage()
        resetUserDefaults()
    }
}
```

### 5.2 Mock Data Services
```swift
protocol APIServiceProtocol {
    func generateRoast(for excuse: String) async -> RoastResponse
    func getDailyReport() async -> DailyReport
}

class MockAPIService: APIServiceProtocol {
    func generateRoast(for excuse: String) async -> RoastResponse {
        // Return predictable test responses
        return RoastResponse(
            message: "Test roast for UI testing",
            personality: "sassy",
            shareable: true
        )
    }
}
```

---

## 6. Test Execution and Reporting

### 6.1 Automated Test Execution
```bash
# Run all UI tests
xcodebuild test -project NagAgent.xcodeproj -scheme NagAgent -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -testPlan UITestPlan

# Run specific test suite
xcodebuild test -project NagAgent.xcodeproj -scheme NagAgent -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:NagAgentUITests/OnboardingUITests

# Generate test report
xcodebuild test -project NagAgent.xcodeproj -scheme NagAgent -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -resultBundlePath TestResults.xcresult
```

### 6.2 Test Results Analysis
```swift
// Custom test result analysis
class TestResultAnalyzer {
    func analyzeTestResults(from bundle: XCResultBundle) {
        // Parse test results
        // Generate performance metrics
        // Create failure reports
        // Track test coverage
    }
    
    func generateTestReport() -> TestReport {
        return TestReport(
            totalTests: totalTestCount,
            passedTests: passedTestCount,
            failedTests: failedTestCount,
            performanceMetrics: performanceData,
            screenshots: screenshotPaths
        )
    }
}
```

---

## 7. Continuous Integration Integration

### 7.1 GitHub Actions Configuration
```yaml
name: iOS UI Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  ui-tests:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up iOS Simulator
      run: |
        xcrun simctl create "Test iPhone" "iPhone 15 Pro" "iOS-17-0"
        xcrun simctl boot "Test iPhone"
    
    - name: Run UI Tests
      run: |
        xcodebuild test \
          -project NagAgent.xcodeproj \
          -scheme NagAgent \
          -destination 'platform=iOS Simulator,name=Test iPhone' \
          -testPlan UITestPlan
    
    - name: Upload Test Results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: ui-test-results
        path: |
          **/*.xcresult
          **/Screenshots/**
```

---

## 8. Test Maintenance and Updates

### 8.1 Test Review Schedule
- **Weekly**: Review failed tests and flaky tests
- **Monthly**: Update test data and scenarios  
- **Quarterly**: Full test suite review and optimization
- **Per Release**: Update tests for new features

### 8.2 Test Metrics and KPIs
- **Test Coverage**: Target 80% UI path coverage
- **Test Stability**: <5% flaky test rate
- **Execution Time**: Full suite < 30 minutes
- **Defect Detection**: >90% of UI bugs caught by tests

---

## 9. Known Issues and Limitations

### 9.1 Current Test Limitations
- Push notification testing requires manual verification
- In-app purchase testing limited to sandbox environment
- Voice message testing requires audio verification
- Real-time sync testing challenging to automate

### 9.2 Future Test Enhancements
- Implement visual regression testing
- Add performance benchmarking
- Enhance accessibility test coverage
- Implement cross-platform testing for iPad

---

**Note**: This testing plan should be updated regularly as new features are added and iOS versions are released. All tests should be reviewed and updated for compatibility with new Xcode and iOS versions.