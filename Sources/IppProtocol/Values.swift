public extension IppAttribute.Name {
    // operation attributes
    static var attributesCharset: Self { .init(rawValue: "attributes-charset") }
    static var attributesNaturalLanguage: Self { .init(rawValue: "attributes-natural-language") }
    static var printerUri: Self { .init(rawValue: "printer-uri") }
    static var jobUri: Self { .init(rawValue: "job-uri") }
    static var documentUri: Self { .init(rawValue: "document-uri") }
    static var requestingUserName: Self { .init(rawValue: "requesting-user-name") }
    static var jobName: Self { .init(rawValue: "job-name") }
    static var jobId: Self { .init(rawValue: "job-id") }
    static var documentName: Self { .init(rawValue: "document-name") }
    static var documentFormat: Self { .init(rawValue: "document-format") }
    static var requestedAttributes: Self { .init(rawValue: "requested-attributes") }
    static var message: Self { .init(rawValue: "message") }
    static var ippAttributeFidelity: Self { .init(rawValue: "ipp-attribute-fidelity") }
    static var compression: Self { .init(rawValue: "compression") }

    // job template attributes
    static var jobPriority: Self { .init(rawValue: "job-priority") }
    static var jobHoldUntil: Self { .init(rawValue: "job-hold-until") }
    static var jobSheets: Self { .init(rawValue: "job-sheets") }
    static var multipleDocumentHandling: Self { .init(rawValue: "multiple-document-handling") }
    static var copies: Self { .init(rawValue: "copies") }
    static var finishings: Self { .init(rawValue: "finishings") }
    static var pageRanges: Self { .init(rawValue: "page-ranges") }
    static var sides: Self { .init(rawValue: "sides") }
    static var numberUp: Self { .init(rawValue: "number-up") }
    static var orientationRequested: Self { .init(rawValue: "orientation-requested") }
    static var media: Self { .init(rawValue: "media") }
    static var printerResolution: Self { .init(rawValue: "printer-resolution") }
    static var printQuality: Self { .init(rawValue: "print-quality") }

    // job description attributes
    static var jobState: Self { .init(rawValue: "job-state") }
    static var jobStateMessage: Self { .init(rawValue: "job-state-message") }
    static var jobStateReasons: Self { .init(rawValue: "job-state-reasons") }

    // printer description attributes
    static var documentFormatSupported: Self { .init(rawValue: "document-format-supported") }
    static var printerName: Self { .init(rawValue: "printer-name") }
    static var printerState: Self { .init(rawValue: "printer-state") }
    static var printerStateMessage: Self { .init(rawValue: "printer-state-message") }
    static var printerStateReasons: Self { .init(rawValue: "printer-state-reasons") }
    static var printerIsAcceptingJobs: Self { .init(rawValue: "printer-is-accepting-jobs") }
    static var queuedJobCount: Self { .init(rawValue: "queued-job-count") }
    static var printerInfo: Self { .init(rawValue: "printer-info") }
    static var printerUriSupported: Self { .init(rawValue: "printer-uri-supported") }
    static var uriSecuritySupported: Self { .init(rawValue: "uri-security-supported") }
    static var uriAuthenticationSupported: Self { .init(rawValue: "uri-authentication-supported") }
    static var printerLocation: Self { .init(rawValue: "printer-location") }
    static var printerMoreInfo: Self { .init(rawValue: "printer-more-info") }
    static var printerMessageFromOperator: Self { .init(rawValue: "printer-message-from-operator") }
    static var colorSupported: Self { .init(rawValue: "color-supported") }
    
    // operation response attributes
    static var statusMessage: Self { .init(rawValue: "status-message") }
    static var detailedStatusMessage: Self { .init(rawValue: "detailed-status-message") }
}

public extension IppOperationId {
    static var printJob: Self { .init(rawValue: 0x0002) }
    static var printUri: Self { .init(rawValue: 0x0003) }
    static var validateJob: Self { .init(rawValue: 0x0004) }
    static var createJob: Self { .init(rawValue: 0x0005) }
    static var sendDocument: Self { .init(rawValue: 0x0006) }
    static var sendUri: Self { .init(rawValue: 0x0007) }
    static var cancelJob: Self { .init(rawValue: 0x0008) }
    static var getJobAttributes: Self { .init(rawValue: 0x0009) }
    static var getJobs: Self { .init(rawValue: 0x000A) }
    static var getPrinterAttributes: Self { .init(rawValue: 0x000B) }
    static var holdJob: Self { .init(rawValue: 0x000C) }
    static var releaseJob: Self { .init(rawValue: 0x000D) }
    static var restartJob: Self { .init(rawValue: 0x000E) }
    static var pausePrinter: Self { .init(rawValue: 0x0010) }
    static var resumePrinter: Self { .init(rawValue: 0x0011) }
    static var purgeJobs: Self { .init(rawValue: 0x0012) }

    // static var setPrinterAttributes: Self { .init(rawValue: 0x0013) }
    // static var setJobAttributes: Self { .init(rawValue: 0x0014) }
    // static var getPrinterSupportedValues: Self { .init(rawValue: 0x0015) }
}

public extension IppStatusCode {
    static var successfulOk: Self { .init(rawValue: 0x0000) }
    static var successfulOkIgnoredOrSubstitutedAttributes: Self { .init(rawValue: 0x0001) }
    static var successfulOkConflictingAttributes: Self { .init(rawValue: 0x0002) }
    static var successfulOkIgnoredSubscriptions: Self { .init(rawValue: 0x0003) }
    static var successfulOkIgnoredNotifications: Self { .init(rawValue: 0x0004) }
    static var successfulOkTooManyEvents: Self { .init(rawValue: 0x0005) }
    static var successfulOkButCancelSubscription: Self { .init(rawValue: 0x0006) }
    static var successfulOkEventsComplete: Self { .init(rawValue: 0x0007) }
    static var clientErrorBadRequest: Self { .init(rawValue: 0x0400) }
    static var clientErrorForbidden: Self { .init(rawValue: 0x0401) }
    static var clientErrorNotAuthenticated: Self { .init(rawValue: 0x0402) }
    static var clientErrorNotAuthorized: Self { .init(rawValue: 0x0403) }
    static var clientErrorNotPossible: Self { .init(rawValue: 0x0404) }
    static var clientErrorTimeout: Self { .init(rawValue: 0x0405) }
    static var clientErrorNotFound: Self { .init(rawValue: 0x0406) }
    static var clientErrorGone: Self { .init(rawValue: 0x0407) }
    static var clientErrorRequestEntityTooLarge: Self { .init(rawValue: 0x0408) }
    static var clientErrorRequestValueTooLong: Self { .init(rawValue: 0x0409) }
    static var clientErrorDocumentFormatNotSupported: Self { .init(rawValue: 0x040A) }
    static var clientErrorAttributesOrValuesNotSupported: Self { .init(rawValue: 0x040B) }
    static var clientErrorUriSchemeNotSupported: Self { .init(rawValue: 0x040C) }
    static var clientErrorCharsetNotSupported: Self { .init(rawValue: 0x040D) }
    static var clientErrorConflictingAttributes: Self { .init(rawValue: 0x040E) }
}

public extension IppStatusCode {
    enum Class: String {
        case successful
        case informational
        case redirection
        case clientError
        case serverError
        case invalid
    }

    /// The class of the status code based on the IPP value ranges.
    var `class`: Class {
        switch rawValue {
        case 0x0000...0x00ff: .successful
        case 0x0100...0x01ff: .informational
        case 0x0300...0x03ff: .redirection
        case 0x0400...0x04ff: .clientError
        case 0x0500...0x05ff: .serverError
        default: .invalid
        }
    }
} 