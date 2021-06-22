//
//  AsyncEvaluation.swift
//  
//
//  Created by Max Obermeier on 21.06.21.
//

import Apodini
import OpenCombine


public extension Publisher where Output: Request {
    func evaluate<H: Handler>(on handler: H) -> some Publisher {
        let delegate = IE.standaloneDelegate(handler)
        
        return self.map { (request: Request) -> Result<H.Response, ApodiniError> in
            do {
                return Result<H.Response, ApodiniError>.success(try IE.evaluate(delegate: delegate, using: request))
            } catch {
                return Result<H.Response, ApodiniError>.failure(error.apodiniError)
            }
        }
    }
}

public extension Publisher {
    func closeOnError<R: ResponseTransformable>() -> some Publisher where Output == Result<R, ApodiniError> {
        self.tryMap { (result: Output) throws -> R in
            switch result {
            case let .failure(error):
                throw error
            case let .success(response):
                return response
            }
        }
    }
}
