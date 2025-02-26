//
//  NetfilmSubtitles.swift
//  Pods
//
//  Created by BrikerMan on 2017/4/2.
//
//

import Foundation


@MainActor
public class NetfilmSubtitles {
    public var groups: [Group] = []
    /// subtitles delay, positive:fast, negative:forward
    public var delay: TimeInterval = 0
    
    public struct Group: CustomStringConvertible {
        var index: Int
        var start: TimeInterval
        var end  : TimeInterval
        var text : String
        
        init(_ index: Int, _ start: NSString, _ end: NSString, _ text: NSString) {
            self.index = index
            self.start = Group.parseDuration(start as String)
            self.end   = Group.parseDuration(end as String)
            self.text  = text as String
        }
        

        static func parseDuration(_ fromStr: String) -> TimeInterval {
            var h: TimeInterval = 0.0, m: TimeInterval = 0.0, s: TimeInterval = 0.0, c: TimeInterval = 0.0
            let scanner = Scanner(string: fromStr)
            
            let separators = CharacterSet(charactersIn: ":,")
            
            if let hourStr = scanner.scanUpToCharacters(from: separators), let hour = Double(hourStr) {
                h = hour
            }
            _ = scanner.scanUpToCharacters(from: CharacterSet.decimalDigits) // تخطي الفاصل
            
            if let minuteStr = scanner.scanUpToCharacters(from: separators), let minute = Double(minuteStr) {
                m = minute
            }
            _ = scanner.scanUpToCharacters(from: CharacterSet.decimalDigits) // تخطي الفاصل
            
            if let secondStr = scanner.scanUpToCharacters(from: separators), let second = Double(secondStr) {
                s = second
            }
            _ = scanner.scanUpToCharacters(from: CharacterSet.decimalDigits) // تخطي الفاصل
            
            if let centisecondStr = scanner.scanUpToCharacters(from: separators), let centisecond = Double(centisecondStr) {
                c = centisecond
            }

            return (h * 3600.0) + (m * 60.0) + s + (c / 1000.0)
        }



        
        public var description: String {
            return "Subtile Group ==========\nindex : \(index),\nstart : \(start)\nend   :\(end)\ntext  :\(text)"
        }
    }
    

    public init(url: URL, encoding: String.Encoding? = nil) {
        Task { [weak self] in
            do {
                let string: String
                if let encoding = encoding {
                    string = try String(contentsOf: url, encoding: encoding)
                } else {
                    string = try String(contentsOf: url, encoding: .utf8) // تحديد ترميز افتراضي
                }

                // تحديث `self.groups` داخل MainActor بأمان
                await MainActor.run {
                    self?.groups = NetfilmSubtitles.parseSubRip(string) ?? []
                }
            } catch {
                print("| NetfilmPlayer | [Error] failed to load \(url.absoluteString) \(error.localizedDescription)")
            }
        }
    }

    
    /**
     Search for target group for time
     
     - parameter time: target time
     
     - returns: result group or nil
     */
    public func search(for time: TimeInterval) -> Group? {
        let result = groups.first(where: { group -> Bool in
            if group.start - delay <= time && group.end - delay >= time {
                return true
            }
            return false
        })
        return result
    }
    
    /**
     Parse str string into Group Array
     
     - parameter payload: target string
     
     - returns: result group
     */
    fileprivate static func parseSubRip(_ payload: String) -> [Group]? {
        var groups: [Group] = []
        
        // تقسيم النصوص بناءً على الأسطر
        let lines = payload.components(separatedBy: .newlines)
        
        var index: Int?
        var start: String?
        var end: String?
        var textLines: [String] = []
        
        for line in lines {
            if line.isEmpty {
                // تحقق من أن جميع البيانات موجودة قبل إنشاء المجموعة
                if let index = index, let start = start, let end = end {
                    let text = textLines.joined(separator: " ")
                    let group = Group(index, start as NSString, end as NSString, text as NSString)
                    groups.append(group)
                }
                
                // إعادة تعيين القيم لقراءة المجموعة التالية
                index = nil
                start = nil
                end = nil
                textLines = []
            } else if index == nil, let number = Int(line) {
                index = number
            } else if start == nil, line.contains(" --> ") {
                let parts = line.components(separatedBy: " --> ")
                if parts.count == 2 {
                    start = parts[0].trimmingCharacters(in: .whitespaces)
                    end = parts[1].trimmingCharacters(in: .whitespaces)
                }
            } else {
                textLines.append(line.trimmingCharacters(in: .whitespaces))
            }
        }
        
        return groups
    }

}
