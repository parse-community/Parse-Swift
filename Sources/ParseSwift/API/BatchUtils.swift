//
//  RESTBatchCommand.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-08-19.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation

typealias ParseObjectBatchCommand<T> = BatchCommand<T, T> where T: ParseObject
typealias ParseObjectBatchResponse<T> = [(Result<T, ParseError>)]
// swiftlint:disable line_length
typealias RESTBatchCommandType<T> = API.Command<ParseObjectBatchCommand<T>, ParseObjectBatchResponse<T>> where T: ParseObject

typealias ParseObjectBatchCommandNoBody<T> = BatchCommandNoBody<NoBody, ParseError?>
typealias ParseObjectBatchResponseNoBody<NoBody> = [ParseError?]
typealias RESTBatchCommandNoBodyType<T> = API.NonParseBodyCommand<ParseObjectBatchCommandNoBody<T>, ParseObjectBatchResponseNoBody<T>> where T: Encodable
/*
typealias ParseObjectBatchCommandEncodable<T> = BatchCommand<T, PointerType> where T: ParseType
typealias ParseObjectBatchResponseEncodable<U> = [(Result<PointerType, ParseError>)]
// swiftlint:disable line_length
typealias RESTBatchCommandTypeEncodable<T> = API.Command<ParseObjectBatchCommandEncodable<T>, ParseObjectBatchResponseEncodable<PointerType>> where T: ParseType
 // swiftlint:enable line_length
*/
internal struct BatchCommand<T, U>: ParseType where T: ParseType {
    let requests: [API.Command<T, U>]
}

internal struct BatchCommandNoBody<T, U>: Encodable where T: Encodable {
    let requests: [API.NonParseBodyCommand<T, U>]
}
