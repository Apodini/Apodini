//
// This source file is part of the Apodini open source project
//
// SPDX-FileCopyrightText: 2019-2021 Paul Schmiedmayer and the Apodini project authors (see CONTRIBUTORS.md) <paul.schmiedmayer@tum.de>
//
// SPDX-License-Identifier: MIT
//

import Foundation
import PythonKit

func getSynsets() {
    let nltk = Python.import("nltk")
    nltk.demo()
    let corpus = Python.import("nltk.corpus")
    //corpus.demo()
    let wn = corpus.wordnet
    //print(wn)
    print(wn.synsets("dog"))
}
