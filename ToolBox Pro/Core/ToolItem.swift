import SwiftUI

struct ToolItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let symbol: String
    let color: Color

    static var all: [ToolItem] {
        [
            ToolItem(id: "calculator", title: AppLocalizer.string("Calculator"), subtitle: AppLocalizer.string("Quick math"), description: AppLocalizer.string("Run totals, discounts, and everyday calculations."), symbol: "plus.forwardslash.minus", color: AppColor.primary),
            ToolItem(id: "unit-converter", title: AppLocalizer.string("Unit Converter"), subtitle: AppLocalizer.string("Global units"), description: AppLocalizer.string("Switch between length, weight, area, time, speed, and more."), symbol: "arrow.left.arrow.right", color: AppColor.success),
            ToolItem(id: "qr-toolkit", title: AppLocalizer.string("QR Toolkit"), subtitle: AppLocalizer.string("Scan and create"), description: AppLocalizer.string("Generate codes or scan links, Wi-Fi, phone numbers, and notes."), symbol: "qrcode", color: AppColor.warning),
            ToolItem(id: "watermark", title: AppLocalizer.string("Watermark"), subtitle: AppLocalizer.string("Brand exports"), description: AppLocalizer.string("Add a text watermark, adjust placement, and save a clean copy."), symbol: "seal", color: Color(hex: 0x8B5CF6)),
            ToolItem(id: "compressor", title: AppLocalizer.string("Compressor"), subtitle: AppLocalizer.string("Shrink images"), description: AppLocalizer.string("Reduce image size before sharing, uploading, or sending files."), symbol: "arrow.down.right.and.arrow.up.left", color: Color(hex: 0x0EA5A8)),
            ToolItem(id: "speech-to-text", title: AppLocalizer.string("Speech to Text"), subtitle: AppLocalizer.string("Transcribe audio"), description: AppLocalizer.string("Turn voice notes into live text and keep recent transcripts handy."), symbol: "waveform", color: Color(hex: 0xF15B6C))
        ]
    }
}
