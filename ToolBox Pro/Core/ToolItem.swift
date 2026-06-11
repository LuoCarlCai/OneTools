import SwiftUI

struct ToolItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let symbol: String
    let color: Color
    let searchKeywords: [String]

    static var all: [ToolItem] {
        [
            ToolItem(id: "calculator", title: AppLocalizer.string("Calculator"), subtitle: AppLocalizer.string("Quick math"), description: AppLocalizer.string("Run totals, discounts, and everyday calculations."), symbol: "plus.forwardslash.minus", color: AppColor.primary, searchKeywords: ["math", "discount", "tip", "tax", "total", "折扣", "小费", "税费", "计算"]),
            ToolItem(id: "unit-converter", title: AppLocalizer.string("Unit Converter"), subtitle: AppLocalizer.string("Global units"), description: AppLocalizer.string("Switch between length, weight, area, time, speed, and more."), symbol: "arrow.left.arrow.right", color: AppColor.success, searchKeywords: ["convert", "converter", "length", "weight", "temperature", "speed", "换算", "单位", "长度", "重量", "温度"]),
            ToolItem(id: "qr-toolkit", title: AppLocalizer.string("QR Toolkit"), subtitle: AppLocalizer.string("Scan and create"), description: AppLocalizer.string("Generate codes or scan links, Wi-Fi, phone numbers, and notes."), symbol: "qrcode", color: AppColor.warning, searchKeywords: ["qr", "qrcode", "scan", "wifi", "link", "code", "二维码", "扫码", "生成", "网址"]),
            ToolItem(id: "image-pdf", title: AppLocalizer.string("Image to PDF"), subtitle: AppLocalizer.string("Document export"), description: AppLocalizer.string("Turn photos, receipts, notes, and screenshots into a shareable PDF."), symbol: "doc.richtext", color: Color(hex: 0x2563EB), searchKeywords: ["pdf", "scanner", "scan", "document", "receipt", "photo", "image", "PDF", "扫描", "文档", "收据", "图片转PDF", "照片"]),
            ToolItem(id: "watermark", title: AppLocalizer.string("Watermark"), subtitle: AppLocalizer.string("Brand exports"), description: AppLocalizer.string("Add a text watermark, adjust placement, and save a clean copy."), symbol: "seal", color: Color(hex: 0x8B5CF6), searchKeywords: ["photo", "image", "watermark", "privacy", "id", "document", "图片", "照片", "水印", "证件", "隐私"]),
            ToolItem(id: "compressor", title: AppLocalizer.string("Compressor"), subtitle: AppLocalizer.string("Shrink images"), description: AppLocalizer.string("Reduce image size before sharing, uploading, or sending files."), symbol: "arrow.down.right.and.arrow.up.left", color: Color(hex: 0x0EA5A8), searchKeywords: ["photo", "image", "compress", "reduce", "upload", "size", "图片", "照片", "压缩", "变小", "上传"]),
            ToolItem(id: "speech-to-text", title: AppLocalizer.string("Speech to Text"), subtitle: AppLocalizer.string("Transcribe audio"), description: AppLocalizer.string("Turn voice notes into live text and keep recent transcripts handy."), symbol: "waveform", color: Color(hex: 0xF15B6C), searchKeywords: ["voice", "audio", "record", "transcript", "meeting", "note", "语音", "录音", "转文字", "会议", "笔记"])
        ]
    }
}
