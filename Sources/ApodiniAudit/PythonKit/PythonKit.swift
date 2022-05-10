//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import PythonKit

struct NLTKInterface {
    static let shared = NLTKInterface()
    
    private let wordnet: PythonObject
    private let nltk: PythonObject
    
    private init() {
        let corpus = Python.import("nltk.corpus")
        self.wordnet = corpus.wordnet
        self.nltk = Python.import("nltk")
    }
    
    func synsetIntersectionEmpty(_ str1: String, _ str2: String) -> Bool {
        let synsets1 = Set(wordnet.synsets(str1))
        let synsets2 = Set(wordnet.synsets(str2))
        
        return synsets1.intersection(synsets2).isEmpty
    }
    
    func isPluralNoun(_ str: String) -> Bool {
        let tags = nltk.pos_tag([str])
        let firstTagTuple = tags[0]
        let tag = String(firstTagTuple.tuple2.1)
        return tag == "NNPS" || tag == "NNS"
    }
}
