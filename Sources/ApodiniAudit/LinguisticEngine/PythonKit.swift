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
    private static var _shared: NLTKInterface? = nil
    static var shared: NLTKInterface {
        print("init!")
        if let sh = _shared {
            return sh
        }
        let sh = NLTKInterface()
        _shared = sh
        return sh
    }
    
    private let wordnet: PythonObject
    private let nltk: PythonObject
    
    private init() {
        let corpus = Python.import("nltk.corpus")
        print("Successfully loaded nltk.corpus")
        self.wordnet = corpus.wordnet
        self.nltk = Python.import("nltk")
        print("Successfully loaded nltk!")
    }
    
    func synsetIntersectionEmpty(_ str1: String, _ str2: String) -> Bool {
        let synsets1 = Set(wordnet.synsets(str1))
        let synsets2 = Set(wordnet.synsets(str2))
        
        return synsets1.isDisjoint(with: synsets2)
    }
    
    func isPluralNoun(_ str: String) -> Bool {
        let tags = nltk.pos_tag([str])
        let firstTagTuple = tags[0]
        let tag = String(firstTagTuple.tuple2.1)
        return tag == "NNPS" || tag == "NNS"
    }
    
    func isSingularNoun(_ str: String) -> Bool {
        let tags = nltk.pos_tag([str])
        let firstTagTuple = tags[0]
        let tag = String(firstTagTuple.tuple2.1)
        return tag == "NNP" || tag == "NN"
    }
}
