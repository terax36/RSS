// MARK: - Core Data Generated Implementation
// This file contains auto-generated Core Data types

import Foundation
import CoreData

@objc(Article)
public class Article: NSManagedObject, Identifiable {

}

@objc(ArticleContent)
public class ArticleContent: NSManagedObject {
    
}

@objc(Feed)
public class Feed: NSManagedObject {
    
}

@objc(Folder)
public class Folder: NSManagedObject {
    
}

@objc(FeedFolder)
public class FeedFolder: NSManagedObject {
    
}

@objc(Rule)
public class Rule: NSManagedObject, Identifiable {

}

@objc(Settings)
public class Settings: NSManagedObject {
    
}

// MARK: - Core Data Extensions
extension Article {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Article> {
        return NSFetchRequest<Article>(entityName: "Article")
    }
    
    @NSManaged public var author: String?
    @NSManaged public var contentCached: Bool
    @NSManaged public var feedID: UUID?
    @NSManaged public var guid: String?
    @NSManaged public var id: UUID
    @NSManaged public var isRead: Bool
    @NSManaged public var isStarred: Bool
    @NSManaged public var languageCode: String?
    @NSManaged public var link: String?
    @NSManaged public var publishedAt: Date?
    @NSManaged public var readingProgress: Double
    @NSManaged public var summary: String?
    @NSManaged public var thumbnailURL: String?
    @NSManaged public var title: String?
    @NSManaged public var translatedTitle: String?
    @NSManaged public var translationHash: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var content: ArticleContent?
    @NSManaged public var feed: Feed?
}

extension ArticleContent {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArticleContent> {
        return NSFetchRequest<ArticleContent>(entityName: "ArticleContent")
    }
    
    @NSManaged public var articleID: UUID?
    @NSManaged public var lastRenderedDark: Bool
    @NSManaged public var readabilityHTML: String?
    @NSManaged public var readingTimeSec: Int32
    @NSManaged public var textPlain: String?
    @NSManaged public var wordCount: Int32
    @NSManaged public var article: Article?
}

extension Feed {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Feed> {
        return NSFetchRequest<Feed>(entityName: "Feed")
    }
    
    @NSManaged public var customCSS: String?
    @NSManaged public var etag: String?
    @NSManaged public var faviconURL: String?
    @NSManaged public var feedURL: String?
    @NSManaged public var id: UUID
    @NSManaged public var isMuted: Bool
    @NSManaged public var lastModified: Date?
    @NSManaged public var refreshIntervalMin: Int32
    @NSManaged public var siteURL: String?
    @NSManaged public var title: String?
    @NSManaged public var articles: Set<Article>?
    @NSManaged public var folders: Set<Folder>?
}

extension Folder {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Folder> {
        return NSFetchRequest<Folder>(entityName: "Folder")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var sortOrder: Int32
    @NSManaged public var feeds: Set<Feed>?
}

extension FeedFolder {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FeedFolder> {
        return NSFetchRequest<FeedFolder>(entityName: "FeedFolder")
    }
    
    @NSManaged public var feedID: UUID
    @NSManaged public var folderID: UUID
    @NSManaged public var id: UUID
}

extension Rule {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Rule> {
        return NSFetchRequest<Rule>(entityName: "Rule")
    }
    
    @NSManaged public var actionHide: Bool
    @NSManaged public var appliesToFeeds: String?
    @NSManaged public var id: UUID
    @NSManaged public var isRegex: Bool
    @NSManaged public var pattern: String
}

extension Settings {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Settings> {
        return NSFetchRequest<Settings>(entityName: "Settings")
    }
    
    @NSManaged public var autoTranslateEnglishTitles: Bool
    @NSManaged public var cellularImageBlocking: Bool
    @NSManaged public var id: UUID
    @NSManaged public var markReadOnScrollThreshold: Double
    @NSManaged public var retentionDays: Int32
    @NSManaged public var themeMode: String
}

// MARK: - Relationships are already declared in the base class extensions
// The @NSManaged properties are declared above in each entity's extension
