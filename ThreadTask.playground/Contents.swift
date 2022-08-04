import UIKit

var stash = Stash()

class Generator: Thread {
    var count: Int = 0
    
    override func main() {
        while count != 20 {
            getChip()
            print("Чип сгенерирован и добавлен на склад")
            count += 2
            Thread.sleep(forTimeInterval: 2)
        }
    }
    
    func getChip() {
        stash.pushChip(chip: Chip.make())
    }
}

class Work: Thread {
    override func main() {
        while !stash.isEmpty() {
            guard let chip = stash.popChip() else { return }
            print("Чип типа \(chip.chipType) запаян.")
            chip.sodering()
        }
    }
}

class Stash {
    var chipArray: [Chip] = []
    var queue: DispatchQueue = DispatchQueue(label: "syncQueue", attributes: .concurrent)
    
    func pushChip(chip: Chip) {
        self.queue.async(flags: .barrier) {
            self.chipArray.append(chip)
        }
    }
    
    func popChip() -> Chip? {
        var chip: Chip?
        self.queue.async(flags: .barrier) {
            chip = self.chipArray.removeFirst()
        }
        
        return chip
    }
    
    func isEmpty() -> Bool {
        self.queue.sync {
            return self.chipArray.isEmpty
        }
    }
}

if true {
    //let generator = Generator()
    //generator.start()
    
    let work = Work()
    work.start()
}
