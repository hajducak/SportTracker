import Foundation
import Combine

enum SeriesContentState {
    case loading
    case empty
    case content([Series])
}

class BowlingSeriesViewModel: ObservableObject {
    @Published var state: SeriesContentState = .loading
    @Published var series: [Series] = []
    @Published var toast: Toast? = nil

    private let firebaseManager: FirebaseManager
    private var cancellables: Set<AnyCancellable> = []

    init(firebaseManager: FirebaseManager) {
        self.firebaseManager = firebaseManager
        setupSeries()
    }
    
    func setupSeries() {
        state = .loading
        firebaseManager.fetchAllSeries()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                if case .failure(let error) = completion {
                    toast = Toast(type: .error(error))
                }
            } receiveValue: { [weak self] series in
                guard let self else { return }
                self.state = series.isEmpty ? .empty : .content(series)
            }
            .store(in: &cancellables)
    }
    
    func addSeries(name: String) {
        // TODO: navigation for UI to add series, now just mock data
        save(series: Self.mockSeries(name: name))
    }

    func save(series: Series) {
        firebaseManager.saveSeries(series)
            .sink { [weak self] completion in
                guard let self else { return }
                if case .failure(let error) = completion {
                    toast = Toast(type: .error(error))
                }
            } receiveValue: { [weak self] _ in
                guard let self else { return }
                toast = Toast(type: .success("Serie saved"))
                setupSeries()
            }
            .store(in: &cancellables)
    }
    
    func deleteSeries(_ series: Series) {
        guard let seriesId = series.id else { return }
        firebaseManager.deleteSeries(id: seriesId)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }
                switch completion {
                case .failure(let error):
                    toast = Toast(type: .error(error))
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] _ in
                self?.setupSeries()
            })
            .store(in: &cancellables)
    }
}

extension BowlingSeriesViewModel {
    static func mockSeries(name:String) -> Series {
        Series(id: UUID().uuidString, name: name, tag: .league, games: [
            Game(frames: [
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 1),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 2),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 3),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 4),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 5),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 6),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 7),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 8),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 9),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins), Roll.init(knockedDownPins: Roll.tenPins), Roll.init(knockedDownPins: Roll.tenPins)], index: 10)
            ]),
            Game(frames: [
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 1),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 2),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 3),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 4),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 5),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 6),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 7),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 8),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 9),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins), Roll.init(knockedDownPins: Roll.tenPins), Roll.init(knockedDownPins: Roll.tenPins)], index: 10)
            ]),
            Game(frames: [
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 1),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 2),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 3),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 4),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 5),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 6),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 7),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 8),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins)], index: 9),
                Frame(rolls: [Roll.init(knockedDownPins: Roll.tenPins), Roll.init(knockedDownPins: Roll.tenPins), Roll.init(knockedDownPins: Roll.tenPins)], index: 10)
            ])
        ])
    }
}
