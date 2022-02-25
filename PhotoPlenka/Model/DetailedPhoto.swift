//
//  DetailedPhoto.swift
//  PhotoPlenka
//
//  Created by Алексей Шерстнёв on 21.02.2022.
//

import Foundation

struct DetailedPhoto {
    let cid: Int
    let name: String
    let dir: Direction?
    let year: Int
    let year2: Int
    let file: String
    let geo: [Double]

    let description: NSAttributedString?
    let source: PhotoSource?
    let address: String?
    let author: String?

    let username: String

    init(from ndp: NetworkDetailedPhoto) {
        self.cid = ndp.cid
        self.name = ndp.title
        self.year = ndp.year
        self.year2 = ndp.year2
        self.file = ndp.file
        self.geo = ndp.geo
        if let desc = ndp.desc {
            self.description = NSAttributedString(string: desc)
        } else { self.description = nil }
        self.source = PhotoSource(from: ndp.source)
        self.address = ndp.address
        self.author = ndp.author
        self.username = ndp.username
        if let dirString = ndp.dir, let dir = Direction(rawValue: dirString) {
            self.dir = dir
        } else if let dirString = ndp.dir, !dirString.isEmpty {
            assertionFailure("unknown direction: \(dirString)") // если встретим неизвестный direction
            self.dir = nil
        } else {
            self.dir = nil
        }
    }
}
