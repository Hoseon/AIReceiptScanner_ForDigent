//
//  Created by Alfian Losari on 29/06/24.
//

#if canImport(SwiftUI)
import Foundation
import SwiftUI

public struct ReceiptScanResultView: View {
    
    public let scanResult: SuccessScanResult
    public let applyBottomSheetTrayStyle: Bool
    var showCopyJSONButton: Bool
    @State var isCopied = false
    let utils = Utils.shared
    
    public init(scanResult: SuccessScanResult, applyBottomSheetTrayStyle: Bool = false, showCopyJSONButton: Bool = true) {
        self.scanResult = scanResult
        self.applyBottomSheetTrayStyle = applyBottomSheetTrayStyle
        self.showCopyJSONButton = showCopyJSONButton
    }
    
    public var body: some View {
        containerView(receipts: scanResult.receipt)
            .applyBottomSheetTrayStyle(applyBottomSheetTrayStyle)
    }
    
    private func containerView(receipts: [FingerReceipt]) -> some View {
        VStack {
            if showCopyJSONButton {
                HStack {
                    Spacer()
                    copyJSONButton
                }
                #if !os(macOS)
                .padding()
                #endif
            }
            
            ScrollView {
                VStack {
                            HStack {
                                Text("종류").bold().frame(maxWidth: .infinity)
                                Text("성별").bold().frame(maxWidth: .infinity)
                                Text("연령대").bold().frame(maxWidth: .infinity)
                                Text("처리율").bold().frame(maxWidth: .infinity)
                                Text("일자").bold().frame(maxWidth: .infinity)
                                Text("결과").bold().frame(maxWidth: .infinity)
                            }
//                            .background(Color.yellow)
                            .padding()
                            
                            ForEach(receipts) { receipt in
                                HStack {
                                    Text(receipt.funcType ?? "추출").frame(maxWidth: .infinity)
                                    Text(receipt.gender == "men" ? "남성" : "여성").frame(maxWidth: .infinity)
                                    Text("\(receipt.ageRange ?? 30)대").frame(maxWidth: .infinity)
                                    Text(String(format: "%.1f%%", receipt.percent ?? 80.0)).frame(maxWidth: .infinity)
                                    Text(receipt.dateText).frame(maxWidth: .infinity)
                                    Text(receipt.result ?? true ? "성공" : "실패").frame(maxWidth: .infinity)
                                }
                                .padding()
                                Divider()
//                                .background(Color.white)
//                                .border(Color.black)
                            }
                        }
                .padding()
            }
            .textSelection(.enabled)
//
//            ScrollView {
//
//                LazyVStack(alignment: .leading, spacing: 16) {
//
//                    if let receiptId = receipt.receiptId {
//                        infoLine(label: "ID:", value: receiptId)
//                    }
//
//                    if let merchantName = receipt.merchantName {
//                        infoLine(label: "Merchant:", value: merchantName)
//                    }
//
//                    if let customerName = receipt.customerName {
//                        infoLine(label: "Customer:", value: customerName)
//                    }
//
//                    if let date = receipt.date {
//                        infoLine(label: "Date:", value: utils.currentDateFormatter
//                            .string(from: date))
//                    }
//
//                    if (receipt.items ?? []).count > 0 {
//                        Divider()
//                        HStack {
//                            Text("Qty")
//                                .frame(maxWidth: 30, alignment: .leading)
//                            Spacer()
//                            Text("Item")
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                            Spacer()
//                            Text("Price")
//                                .frame(maxWidth: .infinity, alignment: .trailing)
//                        }
//                    }
//
//                    ForEach(receipt.items ?? []) { item in
//                        HStack {
//                            Text(String(Int(item.quantity)))
//                                .frame(maxWidth: 30, alignment: .leading)
//
//                            Spacer()
//                            Text(item.name)
//                                .multilineTextAlignment(.leading)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                            Spacer()
//                            Text(utils.formatAmount(item.price, currency: receipt.currency))
//                                .frame(maxWidth: .infinity, alignment: .trailing)
//                        }
//                    }
//
//                    if let discount = receipt.discount {
//                        Divider()
//                        infoLine(label: "Discount:", value: utils.formatAmount(discount, currency: receipt.currency))
//                    }
//
//                    if let tax = receipt.tax {
//                        Divider()
//                        infoLine(label: "Tax:", value: utils.formatAmount(tax, currency: receipt.currency))
//                    }
//
//                    if let total = receipt.total {
//                        Divider()
//                        infoLine(label: "Total:", value: utils.formatAmount(total, currency: receipt.currency))
//                    }
//
//
//
//                    if let paymentMethod = receipt.paymentMethod {
//                        Divider()
//                        infoLine(label: "Payment method:", value: paymentMethod)
//                    }
//
//
//
//                }
//                .padding()
//            }
//            .textSelection(.enabled)
        }
    }
    
    func infoLine(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    var copyJSONButton: some View {
        if isCopied {
            HStack {
                Text("Copied")
                    .font(.subheadline.bold())
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.large)
                    .symbolRenderingMode(.multicolor)
            }
            .frame(alignment: .trailing)
        } else {
            Button {
                let receipt = scanResult.receipt
                let jsonEncoder = JSONEncoder()
                jsonEncoder.outputFormatting = .prettyPrinted
                guard let data = try? jsonEncoder.encode(receipt),
                      let jsonString = String(data: data, encoding: .utf8)
                else { return }
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(jsonString, forType: .string)
                #else
                UIPasteboard.general.string = jsonString
                #endif
                
                isCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isCopied = false
                }
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy as JSON")
                }
            }
            .foregroundStyle(Color.accentColor)
        }
    }
}

fileprivate extension View {
    
    @ViewBuilder
    func applyBottomSheetTrayStyle(_ shouldApply: Bool) -> some View {
        if shouldApply {
            self
                .background(.ultraThinMaterial)
                .presentationDetents([.fraction(0.25), .medium, .large])
                .presentationDragIndicator(.visible)
                .onAppear {
                    #if !os(macOS)
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let controller = windowScene.windows.first?.rootViewController?.presentedViewController else {
                        return
                    }
                    controller.view.backgroundColor = .clear
                    #endif
                }
        } else {
            self
        }
    }
    
}


#endif
