import XCTest

final class LifeUnlockedUITests: XCTestCase {
    private func dismissBackfillIfNeeded(_ app: XCUIApplication) {
        let chinese = app.navigationBars["回填人生起点"].buttons["完成"]
        let english = app.navigationBars["Add your life milestones"].buttons["Done"]
        if chinese.waitForExistence(timeout: 2) { chinese.tap() }
        else if english.exists { english.tap() }
    }

    func testFirstLaunchOffersPastExperienceBackfill() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting-reset", "-appLanguage", "zh-Hans"]
        app.launch()

        XCTAssertTrue(app.navigationBars["回填人生起点"].waitForExistence(timeout: 5))
        app.buttons["一次跑步"].tap()
        XCTAssertTrue(app.textFields["公里数，例如 8.5"].waitForExistence(timeout: 5))
    }

    func testLockedBadgeExplainsItsRule() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting-reset", "-appLanguage", "zh-Hans"]
        app.launch()
        dismissBackfillIfNeeded(app)

        app.tabBars.buttons["成就"].tap()
        let badgeShelfScreenshot = XCTAttachment(screenshot: app.screenshot())
        badgeShelfScreenshot.name = "徽章列表"
        badgeShelfScreenshot.lifetime = .keepAlways
        add(badgeShelfScreenshot)
        app.buttons["badge-run-5k"].tap()
        XCTAssertTrue(app.staticTexts["尚未解锁 · 运动"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["单次跑步达到 5 公里"].exists)
        XCTAssertTrue(app.staticTexts["0 / 5 公里"].exists)
        let badgeDetailScreenshot = XCTAttachment(screenshot: app.screenshot())
        badgeDetailScreenshot.name = "徽章条件"
        badgeDetailScreenshot.lifetime = .keepAlways
        add(badgeDetailScreenshot)
        app.buttons["完成"].tap()
    }

    func testHomeCardsOpenTheirModulePagesAndMatchingForms() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting-reset", "-appLanguage", "zh-Hans"]
        app.launch()
        dismissBackfillIfNeeded(app)
        let homeScreenshot = XCTAttachment(screenshot: app.screenshot())
        homeScreenshot.name = "首页模块"
        homeScreenshot.lifetime = .keepAlways
        add(homeScreenshot)

        app.buttons["module-exercise"].tap()
        XCTAssertTrue(app.staticTexts["运动等级"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["累计跑步"].exists)
        XCTAssertTrue(app.staticTexts["人生图鉴"].exists)
        XCTAssertTrue(app.staticTexts["步数"].exists)
        XCTAssertTrue(app.buttons["连接 Apple 健康"].exists)
        app.buttons["新增运动经历"].tap()
        app.buttons["记录跑步"].tap()
        XCTAssertTrue(app.textFields["公里数，例如 8.5"].waitForExistence(timeout: 5))
        let dateLabel = app.buttons["entry-date"].label
        XCTAssertTrue(dateLabel.contains("年") && dateLabel.contains("月") && dateLabel.contains("日"))
        let formScreenshot = XCTAttachment(screenshot: app.screenshot())
        formScreenshot.name = "新增跑步经历"
        formScreenshot.lifetime = .keepAlways
        add(formScreenshot)
        app.buttons["取消"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["module-learning"].tap()
        XCTAssertTrue(app.staticTexts["学习等级"].waitForExistence(timeout: 5))
        app.buttons["新增学习记录"].tap()
        XCTAssertTrue(app.textFields["书名"].waitForExistence(timeout: 5))
        app.buttons["取消"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let travelCard = app.buttons["module-travel"]
        let homeScroll = app.scrollViews.firstMatch
        for _ in 0..<3 { homeScroll.swipeDown() }
        for _ in 0..<6 where !travelCard.isHittable { homeScroll.swipeUp(velocity: .slow) }
        XCTAssertTrue(travelCard.isHittable)
        travelCard.tap()
        XCTAssertTrue(app.staticTexts["旅行等级"].waitForExistence(timeout: 5))
        app.buttons["新增旅行经历"].tap()
        XCTAssertTrue(app.textFields["实际到达的城市"].waitForExistence(timeout: 5))
    }

    func testRecordingARunShowsRewardAndPersistsInTimeline() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting-reset", "-appLanguage", "zh-Hans"]
        app.launch()
        dismissBackfillIfNeeded(app)

        app.buttons["module-exercise"].tap()
        app.buttons["新增运动经历"].tap()
        app.buttons["记录跑步"].tap()
        let distance = app.textFields["公里数，例如 8.5"]
        XCTAssertTrue(distance.waitForExistence(timeout: 5))
        distance.tap()
        distance.typeText("8.5")
        app.buttons["保存"].tap()

        XCTAssertTrue(app.staticTexts["经历已收录"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["+85 XP"].exists)
        XCTAssertTrue(app.staticTexts["跑步里程继续延伸"].exists)
        XCTAssertTrue(app.staticTexts["0 → 85 XP"].exists)
        XCTAssertTrue(app.staticTexts["本次解锁徽章"].exists)
        XCTAssertTrue(app.staticTexts["第一段五公里"].exists)
        XCTAssertTrue(app.staticTexts["下一步"].exists)
        let rewardScreenshot = XCTAttachment(screenshot: app.screenshot())
        rewardScreenshot.name = "经历反馈"
        rewardScreenshot.lifetime = .keepAlways
        add(rewardScreenshot)
        app.buttons["继续探索"].tap()
        XCTAssertTrue(app.staticTexts["运动"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["module-exercise"].exists)
        app.tabBars.buttons["经历"].tap()
        XCTAssertTrue(app.staticTexts["8.5 公里"].waitForExistence(timeout: 5))
        app.tabBars.buttons["首页"].tap()
        app.buttons["module-exercise"].tap()
        XCTAssertTrue(app.staticTexts["已点亮 1"].waitForExistence(timeout: 5))
        let collectionScreenshot = XCTAttachment(screenshot: app.screenshot())
        collectionScreenshot.name = "运动图鉴"
        collectionScreenshot.lifetime = .keepAlways
        add(collectionScreenshot)
        app.tabBars.buttons["成就"].tap()
        let earnedBadgesScreenshot = XCTAttachment(screenshot: app.screenshot())
        earnedBadgesScreenshot.name = "已获徽章"
        earnedBadgesScreenshot.lifetime = .keepAlways
        add(earnedBadgesScreenshot)
        app.buttons["badge-run-5k"].tap()
        XCTAssertTrue(app.staticTexts["解锁记录"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["数据来源：手动填写"].exists)
        let earnedDetailScreenshot = XCTAttachment(screenshot: app.screenshot())
        earnedDetailScreenshot.name = "已获徽章详情"
        earnedDetailScreenshot.lifetime = .keepAlways
        add(earnedDetailScreenshot)
    }

    func testCyclingCanBeAddedFromExerciseModule() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting-reset", "-appLanguage", "zh-Hans"]
        app.launch()
        dismissBackfillIfNeeded(app)

        app.buttons["module-exercise"].tap()
        app.buttons["记录骑行"].tap()
        let distance = app.textFields["公里数，例如 12.5"]
        XCTAssertTrue(distance.waitForExistence(timeout: 5))
        distance.tap()
        distance.typeText("12.5")
        app.buttons["保存"].tap()
        XCTAssertTrue(app.staticTexts["+38 XP"].waitForExistence(timeout: 5))
        app.buttons["继续探索"].tap()
        XCTAssertTrue(app.staticTexts["骑行"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["12.5 公里"].exists)
    }

    func testEnglishLanguageShowsTranslatedNavigationAndDate() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting-reset", "-appLanguage", "en"]
        app.launch()
        dismissBackfillIfNeeded(app)
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        app.buttons["module-exercise"].tap()
        XCTAssertTrue(app.staticTexts["Exercise level"].waitForExistence(timeout: 5))
        app.buttons["Log a ride"].tap()
        XCTAssertTrue(app.textFields["Distance in km, e.g. 12.5"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["entry-date"].label.contains("-"))
    }

    func testLifeProfileOpensForEditingAndSavesEducation() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting-reset", "-appLanguage", "zh-Hans"]
        app.launch()
        dismissBackfillIfNeeded(app)
        app.tabBars.buttons["我的"].tap()
        app.buttons["life-profile"].tap()
        XCTAssertTrue(app.navigationBars["人生档案"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["昵称"].exists)
        XCTAssertTrue(app.switches["记录出生日期"].exists)
        XCTAssertTrue(app.switches["已取得驾照"].exists)

        let education = app.textFields["已取得的学历，例如 本科"]
        education.tap()
        education.typeText("Bachelor")
        app.buttons["保存"].tap()
        XCTAssertTrue(app.staticTexts["Bachelor"].waitForExistence(timeout: 5))
        app.buttons["life-profile"].tap()
        XCTAssertEqual(app.textFields["已取得的学历，例如 本科"].value as? String, "Bachelor")
    }
}
