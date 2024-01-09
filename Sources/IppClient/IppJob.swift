import IppProtocol

public extension IppPrinter {
    /// Implements the ``IppJobObject`` using a ``IppPrinter``.
    struct Job {
        public let jobId: Int32
        public let printer: IppPrinter

        public init(printer: IppPrinter, jobId: Int32) {
            self.jobId = jobId
            self.printer = printer
        }
    }

    func job(_ jobId: Int32) -> Job {
        Job(printer: self, jobId: jobId)
    }
}

extension IppPrinter.Job: IppJobObject {
    public typealias DataFormat = IppPrinter.DataFormat

    public func makeNewRequest(operation: IppOperationId) -> IppRequest {
        IppRequest(
            printerUri: printer.uri,
            jobId: jobId,
            operation: operation,
            requestingUserName: printer.authentication?.requestingUserName,
            attributesNaturalLanguage: printer.language,
            version: printer.version
        )
    }

    public func execute(request: IppRequest, data: DataFormat?) async throws -> IppResponse {
        try await printer.execute(request: request, data: data)
    }
}
