//
//  ReceiptScanner.swift
//  AIReceiptScanner
//
//  Created by Alfian Losari on 29/06/24.
//

#if canImport(CoreGraphics)
import CoreGraphics
#endif
import ChatGPTSwift
import Foundation

public struct AIReceiptScanner_ForDigent {
    
    let api: ChatGPTAPI
    let systemText: String
    let promptText: String =
"""
이미지로 된 테이블에 다음과 같은 JSON 형식을 사용하여 응답해주세요.
데이터는 1건부터 시작해서 여러건 일 수 있습니다.
{
    [
    "funcType" : "종류 입니다. 종류에는 추출/비교만 존재합니다. 값이 명확하지 않을 경우 추출이라고 해주세요. 문자열 타입입니다.",
    "gender" : "성별 입니다. 성별에는 men/women만 존재합니다. 남자일 경우 men, 여자일 경우 women으로 값을 지정합니다. 값이 판단이 되지 않을 경우 men를 기본값으로 해주세요. 문자열 타입입니다.",
    "ageRange" : "연령대 입니다. 숫자 타입입니다. 10, 20, 30, 40, 50, 60, 70, 80, 90의 값이 올 수 있습니다. 예를들어 55가 들어 오면 50 23이 들어 오면 20으로 값을 저장합니다.",
    "percent" : "처리율 입니다. 숫자타입입니다. 0~100까지의 값만 존재합니다.",
    "date" : "날짜입니다. yyyy-MM-dd형태로 표기 합니다. yyyy가 없을 경우 올해로 지정해주세요",
    "result" : "처리결과 입니다. boolean 타입입니다.",
    ]
}
"""
    
//"""
//Tell me the detail and items in this image receipt. Don't put discount, subtotal, and total, and tax inside items array.Ignore item with 0 price or quantity. Use this JSON format as the response.
//{
//    "receiptId": "receipt id or no. don't return if not exists. string type",
//    "merchantName": "name of merchant. don't return if not exits. string type",
//    "customerName": "name of customer. don't return if not exits. string type",
//    "date": "date of the receipt. always use this string format as the response yyyy-MM-dd. If no year is provided, just use current year",
//    "tax": "tax of receipt. don't return if not exists. number type",
//    "discount: "savings or discount. don't return if not exists. number type",
//    "total": "total amount paid of receipt. number type",
//    "paymentMethod: "enum of cash, creditCard, debitCard, eMoney. use cash as default value if not exists. string type",
//    "currency": "currency of the receipt, always use 3 digit country code format"
//    "items": [
//        {
//            "name": "name of the item. string type",
//            "price": "price of the transaction. number type",
//            "quantity": "quantity of item purchased . number type"
//            "category": "enum of \(Category.allCases.map {$0.rawValue}.split(separator: ",")). if not sure, use Utilities as fallback value"
//        }
//    ]
//}
//"""
    
    let dateFormatterJSONDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom{ decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            guard let date = dateFormatter.date(from: dateString) else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date") }
            return date
        }
        return jsonDecoder
    }()
    
    public init(apiKey: String, systemText: String = "너는 생체인식 기록의 이미지를 판단하고 분석하는 전문가야.") {
        self.api = .init(apiKey: apiKey)
        self.systemText = systemText
    }
    
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)
    public func scanImage(_ image: ReceiptImage, targetSize: CGSize = .init(width: 512, height: 512), compressionQuality: CGFloat = 0.5, model: ChatGPTModel = .gpt_hyphen_4o, temperature: Double = 1.0) async throws -> [FingerReceipt] {
        let imageData: Data
        #if os(macOS)
        imageData = image.scaleToFit(targetSize: targetSize)!.scaledJPGData(compressionQuality: compressionQuality)!
        #else
        imageData = image.scaleToFit(targetSize: targetSize).scaledJPGData(compressionQuality: compressionQuality)
        #endif
        return try await scanImageData(imageData, model: model, temperature: temperature)
    }
    #endif
    
    public func scanImageData(_ data: Data, model: ChatGPTModel = .gpt_hyphen_4o, temperature: Double = 1.0) async throws -> [FingerReceipt] {
        do {
            let response = try await api.sendMessage(
                text: promptText,
                model: model,
                systemText: systemText,
                temperature: temperature,
                responseFormat: .init(_type: .json_object),
                imageData: data)
            let jsonString = response
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "  ", with: "")
                .replacingOccurrences(of: "    ", with: "")
            guard let data = jsonString.data(using: .utf8) else {
                throw "Invalid Data"
            }
            printDebug(response)
            let receipt = try dateFormatterJSONDecoder.decode(ResponseFingerLogData.self, from: data)
//            print(receipt.data)
            return receipt.data
        } catch {
            printDebug(error.localizedDescription)
            throw error
        }
    }

}
