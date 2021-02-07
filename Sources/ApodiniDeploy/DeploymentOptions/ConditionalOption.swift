//
//  File.swift
//  
//
//  Created by Lukas Kollmer on 2021-02-06.
//

import Foundation
import Apodini
import ApodiniDeployBuildSupport



extension AnyOption {
    func resolve<H: Handler>(against handler: H) -> ResolvedOption<OuterNS>? {
        if let resolvedOption = self as? ResolvedOption {
            return resolvedOption
        } else if let conditionalOption = self as? ConditionalOption {
            return conditionalOption.resolve_imp(against: handler)?.resolve(against: handler)
        } else {
            fatalError()
        }
    }
}



final class ConditionalOption<OuterNS: OuterNamespace>: AnyOption<OuterNS> {
    let condition: AnyHandlerCondition
    // we internally store this option's value as a resolved option object,
    // this means we don't have to re-create the whole en/decoding logic in here
    private let underlyingOption: AnyOption<OuterNS>
    
    init<InnerNS, Value>(
        key: OptionKey<OuterNS, InnerNS, Value>,
        value: Value,
        condition: AnyHandlerCondition
    ) {
        self.condition = condition
        self.underlyingOption = ResolvedOption(key: key, value: value)
        super.init(key: key)
    }
    
    
    init(underlyingOption: AnyOption<OuterNS>, condition: AnyHandlerCondition) {
        self.underlyingOption = underlyingOption
        self.condition = condition
        super.init(key: underlyingOption.key)
    }
    
    
    required init(from decoder: Decoder) throws {
        // TODO explain that these cant be decoded (which isnt much of an issue since they cant be encoded either)
        fatalError("init(from:) has not been implemented")
    }
    
    public override func encode(to encoder: Encoder) throws {
        fatalError("Cannot encode unresolved conditional deployment option")
    }
    
    
    // the _imp is needed to work around a selector ambiguity when calling this function from the AnyOption.resolve extension
    fileprivate func resolve_imp<H: Handler>(against handler: H) -> AnyOption<OuterNS>? {
        condition.test(on: handler) ? underlyingOption : nil
    }
}

