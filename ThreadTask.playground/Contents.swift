import UIKit

//Working thread
class Work: Thread {
    private var stash: Stash
    private var count: Int
    
    init(stash: Stash, count: Int) {
        self.stash = stash
        self.count = count
    }
    
    override func main() {
        working()
        print("Работающий поток закончен")
    }
    
    private func working() {
        while count != 0 {
            if stash.chipArray.isEmpty == false {
                count += 1
                stash.chipArray.last?.sodering()
                print("Чип припаян.")
                stash.chipArray.removeLast()
                print("Чип удален из стека.")
                print("Остаток: \(stash.getAllChips()).")
            }
        }
    }
}

// Chip Generator thread
class Generator: Thread {
    private var stash: Stash
    private var count: Int
    private var interval: Double
    
    init(stash: Stash, count: Int, interval: Double) {
        self.stash = stash
        self.count = count
        self.interval = interval
    }
    
    override func main() {
        for _ in 1...count {
            let chip = createChip()
            stash.pushChip(chip: chip)
            Thread.sleep(forTimeInterval: interval)
        }
        cancel()
        print("Генерирующий поток закончен")
    }
    
    private func createChip() -> Chip {
        let chip = Chip.make()
        print("Чип типа \(chip.chipType) создан. Остаток: \(stash.getAllChips())")
        return chip
    }
}

//Stash class
class Stash {
    var chipArray: [Chip] = []
    private var queue: DispatchQueue = DispatchQueue(label: "syncQueue", qos: .utility, attributes: .concurrent)
    var count: Int { chipArray.count }
    
    func pushChip(chip: Chip) {
        queue.async(flags: .barrier) { [unowned self] in
            self.chipArray.append(chip)
            print("Чип типа \(chip.chipType) на обработке. Остаток: \(getAllChips())")
        }
    }
    
    func popChip() -> Chip? {
        var chip: Chip?
        queue.sync { [unowned self] in
            guard let poppedChip = self.chipArray.popLast() else { return }
            chip = poppedChip
            print("Чип типа \(poppedChip.chipType) подготовлен. Остаток: \(getAllChips())")
        }
        
        return chip
    }
    
    func getAllChips() -> [UInt32] {
        chipArray.compactMap { $0.chipType.rawValue }
    }
}

let stash = Stash()
let generator = Generator(stash: stash, count: 5, interval: 2.0)
let work = Work(stash: stash, count: 5)

generator.start()
work.start()
