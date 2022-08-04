import UIKit

//Working thread
class Work: Thread {
    private var stash: Stash
    
    init(stash: Stash) {
        self.stash = stash
    }
    
    override func main() {
        while stash.count > 0 || !work.isCancelled {
            working()
        }
        
        cancel()
        print("Работающий поток закончен")
    }
    
    private func working() {
        guard let chip = stash.popChip() else { return }
        soldering(chip: chip)
    }
    
    private func soldering(chip: Chip) {
        chip.sodering()
        print("Чип типа \(chip.chipType) припаян. Остаток: \(stash.getAllChips())")
    }
}

// Chip Generator thread
class Generator: Thread {
    private var stash: Stash
    private var count: Int
    private var interval: Double
    
    init(stash: Stash, count: Int = 5, interval: Double = 2.0) {
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
    private var chipArray: [Chip] = []
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
let generator = Generator(stash: stash, interval: 1.0)
let work = Work(stash: stash)

generator.start()
work.start()

