import XCTest
import SwiftData
import Combine
@testable import SportTracker

class PerformanceListViewModelTests: XCTestCase {
    var viewModel: PerformanceListViewModel!
    var mockStorageManager: MockStorageManager!
    var mockFirebaseManager: MockFirebaseManager!
    var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        let expectation = self.expectation(description: "Waiting for setup to complete")
        Task {
            do {
                mockStorageManager = await MockStorageManager(modelContainer: try ModelContainer(for: SportPerformance.self))
                mockFirebaseManager = MockFirebaseManager()

                viewModel = PerformanceListViewModel(
                    storageManager: mockStorageManager,
                    firebaseManager: mockFirebaseManager
                )
                expectation.fulfill()
            } catch {
                XCTFail("Error initializing model container: \(error)")
            }
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    override func tearDown() {
        viewModel = nil
        mockStorageManager = nil
        mockFirebaseManager = nil
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Test Fetch All Performances
    @MainActor func testFetchPerformancesAll() {
        let expectation = self.expectation(description: "Fetch all performances completed")
        
        viewModel.$performances
            .dropFirst()
            .sink { performances in
                if performances.count == 4 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        mockStorageManager.performances = [
            SportPerformance(name: "Running", location: "Park", duration: 30, storageType: StorageType.local.rawValue),
            SportPerformance(name: "Cycling", location: "Road", duration: 45, storageType: StorageType.local.rawValue)
        ]
        mockFirebaseManager.performancesToReturn = [
            SportPerformance(name: "Swimming", location: "Pool", duration: 60, storageType: StorageType.remote.rawValue),
            SportPerformance(name: "Tennis", location: "Court", duration: 90, storageType: StorageType.remote.rawValue)
        ]

        viewModel.fetchPerformances(filter: nil)
        
        waitForExpectations(timeout: 2, handler: nil)
    }

    // MARK: - Test Fetch Local Performances
    @MainActor func testFetchPerformancesLocal() {
        let expectation = self.expectation(description: "Fetch local performances completed")
        
        viewModel.$performances
            .dropFirst()
            .sink { performances in
                if performances.count == 1, performances.first?.name == "Running" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        mockStorageManager.performances = [
            SportPerformance(name: "Running", location: "Park", duration: 30, storageType: StorageType.local.rawValue),
            SportPerformance(name: "Swimming", location: "Pool", duration: 60, storageType: StorageType.remote.rawValue)
        ]

        viewModel.fetchPerformances(filter: .local)

        waitForExpectations(timeout: 2, handler: nil)
    }

    // MARK: - Test Fetch Remote Performances
    @MainActor func testFetchPerformancesRemote() {
        let expectation = self.expectation(description: "Fetch remote performances completed")

        viewModel.$performances
            .dropFirst()
            .sink { performances in
                if performances.count == 1, performances.first?.name == "Swimming" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        mockFirebaseManager.performancesToReturn = [
            SportPerformance(name: "Swimming", location: "Pool", duration: 60, storageType: StorageType.remote.rawValue)
        ]

        viewModel.fetchPerformances(filter: .remote)

        waitForExpectations(timeout: 2, handler: nil)
    }

    // MARK: - Test Loading Indicator
    @MainActor func testLoadingIndicatorIsShown() {
        let expectation = self.expectation(description: "Loading indicator shows during fetch")
        var isLoadingChanged = false
        viewModel.$isLoading
            .dropFirst()
            .sink { isLoading in
                if isLoading {
                    isLoadingChanged = true
                }
            }
            .store(in: &cancellables)

        mockStorageManager.performances = [
            SportPerformance(name: "Running", location: "Park", duration: 30, storageType: StorageType.local.rawValue)
        ]
        mockFirebaseManager.performancesToReturn = [
            SportPerformance(name: "Swimming", location: "Pool", duration: 60, storageType: StorageType.remote.rawValue)
        ]

        viewModel.fetchPerformances(filter: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertTrue(isLoadingChanged, "Expected isLoading to be true during fetch")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)
    }

    // MARK: - Test Toast Message on Error
    @MainActor func testToastMessageOnError() {
        let expectation = self.expectation(description: "Toast message shows on error")

        viewModel.$toastMessage
            .sink { message in
                if let message = message, message.contains("Error fetching") {
                    XCTAssertTrue(message.contains("Error fetching"))
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        mockFirebaseManager.shouldReturnError = true
        viewModel.fetchPerformances(filter: .remote)

        waitForExpectations(timeout: 2, handler: nil)
    }
}
